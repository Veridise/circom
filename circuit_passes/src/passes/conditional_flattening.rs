use std::cell::RefCell;
use std::collections::BTreeMap;
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::TemplateCode;
use compiler::compiler_interface::Circuit;
use compiler::intermediate_representation::{new_id, BucketId, InstructionPointer};
use compiler::intermediate_representation::ir_interface::*;
use indexmap::{IndexMap, IndexSet};
use crate::bucket_interpreter::env::{Env, LibraryAccess};
use crate::bucket_interpreter::error::BadInterp;
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::observer::Observer;
use crate::{default__name, default__run_template, default__get_mem};
use super::{CircuitTransformationPass, GlobalPassData};

// Uses BTreeMap instead of HashMap because this type must implement the Hash trait.
type BranchValues = BTreeMap<BucketId, Option<bool>>;

pub struct ConditionalFlatteningPass<'d> {
    global_data: &'d RefCell<GlobalPassData>,
    memory: PassMemory,
    // Wrapped in a RefCell because the reference to the static analysis is immutable but we need mutability
    /// NOTE: IndexMap/IndexSet are used to preserve insertion order to stabilize lit test output.
    //
    /// Maps the ID of the CallBucket that is currently on the interpreter's stack (or None
    /// if the interpreter is currently analyzing code that is not within a function) to a
    /// list of (ID, evaluated condition) pairs for the BranchBuckets in the current context.
    evaluated_conditions: RefCell<IndexMap<Option<BucketId>, BranchValues>>,
    /// Track the order that the branches appear in the traversal to stabilize output for lit tests.
    branch_bucket_order: RefCell<IndexSet<BucketId>>,
    /// Maps CallBucket symbol (i.e. target function name) to BranchBucket value mapping to the
    /// new function that has branches simplified according to that mapping.
    /// Uses IndexMap to ensure consistent ordering of functions in the output (for lit tests).
    new_functions: RefCell<IndexMap<String, IndexMap<BranchValues, FunctionCode>>>,
    /// Within the CircuitTransformationPass impl below, this holds the BranchBucket condition for
    /// when the function is called by the current CallBucket. The None key in this map is for the
    /// cases that are NOT inside a function. When traversal enters a function, this will change to
    /// the BranchValues for that CallBucket.
    caller_context: RefCell<Option<BranchValues>>,
}

impl<'d> ConditionalFlatteningPass<'d> {
    pub fn new(prime: String, global_data: &'d RefCell<GlobalPassData>) -> Self {
        ConditionalFlatteningPass {
            global_data,
            memory: PassMemory::new(prime),
            evaluated_conditions: Default::default(),
            branch_bucket_order: Default::default(),
            new_functions: Default::default(),
            caller_context: RefCell::new(None),
        }
    }

    fn get_known_condition_in_context(&self, branch_bucket_id: &BucketId) -> Option<bool> {
        // Get from the current 'caller_context' or lookup via None key in 'evaluated_conditions'
        let ec = self.evaluated_conditions.borrow();
        if let Some(bv) = self.caller_context.borrow().as_ref().or_else(|| ec.get(&None)) {
            if let Some(Some(side)) = bv.get(branch_bucket_id) {
                return Some(*side);
            }
        }
        None
    }
}

impl Observer<Env<'_>> for ConditionalFlatteningPass<'_> {
    fn on_branch_bucket(&self, bucket: &BranchBucket, env: &Env) -> Result<bool, BadInterp> {
        let interpreter = self.memory.build_interpreter(self.global_data, self);
        let cond_result = interpreter.compute_condition(&bucket.cond, env, false)?;
        // Store the result for the current bucket in the list for the current caller.
        // NOTE: Store 'cond_result' even when it is None (meaning the BranchBucket
        //  condition could not be determined) so that it will fully differentiate the
        //  branching behavior of functions called at multiple sites.
        let caller_id = env.function_caller().cloned();
        // NOTE: 'caller_id' is None when the current branch is NOT located within a function.
        self.evaluated_conditions
            .borrow_mut()
            .entry(caller_id)
            .or_default()
            .entry(bucket.id)
            // If an existing entry is not equal to the new computed value, use None for unknown
            .and_modify(|e| {
                if *e != cond_result {
                    *e = None
                }
            })
            // If there was no entry, insert the computed value
            .or_insert(cond_result);
        //
        self.branch_bucket_order.borrow_mut().insert(bucket.id);
        Ok(true)
    }

    fn ignore_function_calls(&self) -> bool {
        false
    }

    fn ignore_extracted_function_calls(&self) -> bool {
        false
    }
}

impl CircuitTransformationPass for ConditionalFlatteningPass<'_> {
    default__name!("ConditionalFlattening");
    default__get_mem!();
    default__run_template!();

    fn post_hook_circuit(&self, cir: &mut Circuit) -> Result<(), BadInterp> {
        // Add the duplicated versions of functions created by transform_call_bucket()
        for (_, ev) in self.new_functions.borrow_mut().drain(..) {
            for f in ev.into_values() {
                cir.functions.push(f);
            }
        }
        //ASSERT: All call buckets were visited and updated (only the None key may remain)
        assert!(self.evaluated_conditions.borrow().iter().all(|(k, _)| k.is_none()));
        Ok(())
    }

    fn transform_call_bucket(&self, bucket: &CallBucket) -> Result<InstructionPointer, BadInterp> {
        let call_bucket_id = Some(bucket.id);
        // The Some keys in the 'evaluated_conditions' map are for the cases that are
        //  inside a function when executed from the CallBucket.id used as the key.
        // NOTE: This borrow is inside brackets to prevent runtime double borrow error.
        let ec = { self.evaluated_conditions.borrow_mut().shift_remove(&call_bucket_id) };
        if let Some(cond_vals) = ec {
            // If there are any conditions that evaluated to a known value, replace the
            //  CallBucket target function with a simplified version of that function.
            if cond_vals.values().any(|e| e.is_some()) {
                let old_name = &bucket.symbol;
                // Check if the needed function exists, else create it.
                let cached_name = {
                    // NOTE: This borrow is inside brackets to prevent runtime double borrow error.
                    let nf = self.new_functions.borrow();
                    nf.get(old_name).and_then(|m| m.get(&cond_vals)).map(|e| e.header.clone())
                };
                let new_target = match cached_name {
                    Some(n) => n,
                    None => {
                        // Set the caller context and then use self.transform_function(..) on the existing
                        //  function to create a new FunctionCode by running this transformer on the existing one.
                        let old_ctx = self.caller_context.replace(Some(cond_vals.clone()));
                        let mut res =
                            self.transform_function(&self.memory.get_function(old_name))?;
                        self.caller_context.replace(old_ctx);
                        // Build the new function name according to the condition values but sorted by 'branch_bucket_order'
                        let new_name = self
                            .branch_bucket_order
                            .borrow()
                            .iter()
                            .filter_map(|id| cond_vals.get(id))
                            .fold(old_name.clone(), |acc, e| match e {
                                Some(true) => format!("{}.T", acc),
                                Some(false) => format!("{}.F", acc),
                                None => format!("{}.N", acc),
                            });
                        res.header = new_name.clone();
                        // Store the new function
                        self.new_functions
                            .borrow_mut()
                            .entry(old_name.clone())
                            .or_default()
                            .insert(cond_vals, res);
                        new_name
                    }
                };
                return Ok(CallBucket {
                    id: new_id(),
                    source_file_id: bucket.source_file_id,
                    line: bucket.line,
                    message_id: bucket.message_id,
                    symbol: new_target,
                    argument_types: bucket.argument_types.clone(),
                    arguments: self.transform_instructions_fixed_len(&bucket.arguments)?,
                    arena_size: bucket.arena_size,
                    return_info: self.transform_return_type(&bucket.id, &bucket.return_info)?,
                }
                .allocate());
            }
        }
        self.transform_call_bucket_default(bucket)
    }

    fn transform_branch_bucket(
        &self,
        bucket: &BranchBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        if let Some(side) = self.get_known_condition_in_context(&bucket.id) {
            let code = if side { &bucket.if_branch } else { &bucket.else_branch };
            let block = BlockBucket {
                id: new_id(),
                source_file_id: bucket.source_file_id,
                line: bucket.line,
                message_id: bucket.message_id,
                body: code.clone(),
                n_iters: 1,
                label: format!("fold_{}", side),
            };
            return self.transform_block_bucket(&block);
        }
        self.transform_branch_bucket_default(bucket)
    }
}
