use std::cell::RefCell;
use std::collections::{HashMap, BTreeMap};
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::TemplateCode;
use compiler::compiler_interface::Circuit;
use compiler::intermediate_representation::{InstructionPointer, new_id, BucketId};
use compiler::intermediate_representation::ir_interface::*;
use indexmap::{IndexMap, IndexSet};
use crate::bucket_interpreter::env::{Env, LibraryAccess};
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::observer::InterpreterObserver;
use super::{CircuitTransformationPass, GlobalPassData};

type BranchValues = BTreeMap<BucketId, Option<bool>>;

pub struct ConditionalFlatteningPass<'d> {
    global_data: &'d RefCell<GlobalPassData>,
    memory: PassMemory,
    // Wrapped in a RefCell because the reference to the static analysis is immutable but we need mutability
    //
    /// Maps the ID of the CallBucket that is currently on the interpreter's stack (or None if the
    /// interpreter is currently analyzing code that is not in one of the generated loopbody functions)
    /// to a list of (ID, evaluated condition) pairs for the BranchBuckets in the current context.
    evaluated_conditions: RefCell<HashMap<Option<BucketId>, BranchValues>>,
    /// Track the order that the branches appear in the traversal to stabilize output for lit tests.
    branch_bucket_order: RefCell<IndexSet<BucketId>>,
    /// Maps CallBucket symbol (i.e. target function name) to BranchBucket value mapping to the
    /// new function that has brances simplified according to that mapping.
    /// NOTE: Uses IndexMap to preserve insertion order to stabilize lit test output.
    new_functions: RefCell<IndexMap<String, BTreeMap<BranchValues, FunctionCode>>>,
    /// Within the CircuitTransformationPass impl below, this holds the BranchBucket
    /// condition for when the function is called by the current CallBucket.
    caller_context: RefCell<Option<BranchValues>>,
}

impl<'d> ConditionalFlatteningPass<'d> {
    pub fn new(prime: String, global_data: &'d RefCell<GlobalPassData>) -> Self {
        ConditionalFlatteningPass {
            global_data,
            memory: PassMemory::new(prime, "".to_string(), Default::default()),
            evaluated_conditions: Default::default(),
            branch_bucket_order: Default::default(),
            new_functions: Default::default(),
            //The None key in this map is for the cases that are NOT inside the loopbody functions. When
            // traversal enters a loopbody function, this will change to the BranchValues of that CallBucket.
            caller_context: RefCell::new(None),
        }
    }
}

impl InterpreterObserver for ConditionalFlatteningPass<'_> {
    fn on_value_bucket(&self, _bucket: &ValueBucket, _env: &Env) -> bool {
        true
    }

    fn on_load_bucket(&self, _bucket: &LoadBucket, _env: &Env) -> bool {
        true
    }

    fn on_store_bucket(&self, _bucket: &StoreBucket, _env: &Env) -> bool {
        true
    }

    fn on_compute_bucket(&self, _bucket: &ComputeBucket, _env: &Env) -> bool {
        true
    }

    fn on_assert_bucket(&self, _bucket: &AssertBucket, _env: &Env) -> bool {
        true
    }

    fn on_loop_bucket(&self, _bucket: &LoopBucket, _env: &Env) -> bool {
        true
    }

    fn on_create_cmp_bucket(&self, _bucket: &CreateCmpBucket, _env: &Env) -> bool {
        true
    }

    fn on_constraint_bucket(&self, _bucket: &ConstraintBucket, _env: &Env) -> bool {
        true
    }

    fn on_block_bucket(&self, _bucket: &BlockBucket, _env: &Env) -> bool {
        true
    }

    fn on_nop_bucket(&self, _bucket: &NopBucket, _env: &Env) -> bool {
        true
    }

    fn on_location_rule(&self, _location_rule: &LocationRule, _env: &Env) -> bool {
        true
    }

    fn on_call_bucket(&self, _bucket: &CallBucket, _env: &Env) -> bool {
        true
    }

    fn on_branch_bucket(&self, bucket: &BranchBucket, env: &Env) -> bool {
        println!("conditional_flattening::on_branch_bucket = {:?}", bucket.id);
        let interpreter = self.memory.build_interpreter(self.global_data, self);
        let (_, cond_result, _) = interpreter.execute_conditional_bucket(
            &bucket.cond,
            &bucket.if_branch,
            &bucket.else_branch,
            env.clone(),
            false,
        );
        // Store the result for the current bucket in the list for the current caller.
        // NOTE: Store 'cond_result' even when it is None (meaning the BranchBucket
        //  condition could not be determined) so that it will fully differentiate the
        //  branching behavior of functions called at multiple sites.
        let in_func = env.extracted_func_caller().map(|n| n.clone());
        // NOTE: 'in_func' is None when the current branch is NOT located within a function
        //  that was generated during loop unrolling to hold the body of a loop.
        self.evaluated_conditions
            .borrow_mut()
            .entry(in_func)
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
        true
    }

    fn on_return_bucket(&self, _bucket: &ReturnBucket, _env: &Env) -> bool {
        true
    }

    fn on_log_bucket(&self, _bucket: &LogBucket, _env: &Env) -> bool {
        true
    }

    fn ignore_function_calls(&self) -> bool {
        true
    }

    fn ignore_subcmp_calls(&self) -> bool {
        true
    }

    fn ignore_loopbody_function_calls(&self) -> bool {
        false
    }
}

impl CircuitTransformationPass for ConditionalFlatteningPass<'_> {
    fn name(&self) -> &str {
        "ConditionalFlattening"
    }

    fn pre_hook_circuit(&self, circuit: &Circuit) {
        self.memory.fill_from_circuit(circuit);
    }

    fn post_hook_circuit(&self, cir: &mut Circuit) {
        // Add the new functions
        for (_, ev) in self.new_functions.borrow_mut().drain(..) {
            for f in ev.into_values() {
                cir.functions.push(f);
            }
        }
    }

    fn pre_hook_template(&self, template: &TemplateCode) {
        self.memory.set_scope(template);
        self.memory.run_template(self.global_data, self, template);
    }

    fn get_updated_field_constants(&self) -> Vec<String> {
        self.memory.get_field_constants_clone()
    }

    fn transform_call_bucket(&self, bucket: &CallBucket) -> InstructionPointer {
        let call_bucket_id = Some(bucket.id);
        // The Some keys in the 'evaluated_conditions' map are for the cases that are inside
        //  the loopbody functions when executed from the CallBucket.id used as the key.
        // NOTE: This borrow is inside brackets to prevent runtime double borrow error.
        let ec = { self.evaluated_conditions.borrow_mut().remove(&call_bucket_id) };
        if let Some(ev) = ec {
            // If there are any conditions that evaluated to a known value, replace the
            //  CallBucket target function with a simplified version of that function.
            if ev.values().any(|e| e.is_some()) {
                let mut nf = self.new_functions.borrow_mut();
                // Check if the needed function exists, else create it.
                let old_name = &bucket.symbol;
                // Build the new function name according to the values in 'ev' but sorted by 'branch_bucket_order'
                let new_name =
                    self.branch_bucket_order.borrow().iter().filter_map(|id| ev.get(id)).fold(
                        old_name.clone(),
                        |acc, e| match e {
                            Some(true) => format!("{}.T", acc),
                            Some(false) => format!("{}.F", acc),
                            None => format!("{}.N", acc),
                        },
                    );
                let new_target = nf
                    .entry(bucket.symbol.clone())
                    .or_default()
                    .entry(ev)
                    .or_insert_with_key(|k| {
                        //Set the 'within_call' context and then use self.transform_function(..)
                        //  on the existing extracted loopbody function to create a new
                        //  FunctionCode by running this transformer on the existing one.
                        let old = self.caller_context.replace(Some(k.clone()));
                        let mut res = self.transform_function(&self.memory.get_function(old_name));
                        self.caller_context.replace(old);
                        res.header = new_name;
                        res
                    })
                    .header
                    .clone();
                return CallBucket {
                    id: new_id(),
                    source_file_id: bucket.source_file_id,
                    line: bucket.line,
                    message_id: bucket.message_id,
                    symbol: new_target,
                    argument_types: bucket.argument_types.clone(),
                    arguments: self.transform_instructions(&bucket.arguments),
                    arena_size: bucket.arena_size,
                    return_info: self.transform_return_type(&bucket.return_info),
                }
                .allocate();
            }
        }
        // Default case: no change
        CallBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            symbol: bucket.symbol.to_string(),
            argument_types: bucket.argument_types.clone(),
            arguments: self.transform_instructions(&bucket.arguments),
            arena_size: bucket.arena_size,
            return_info: self.transform_return_type(&bucket.return_info),
        }
        .allocate()
    }

    fn transform_branch_bucket(&self, bucket: &BranchBucket) -> InstructionPointer {
        if let Some(bv) = self.caller_context.borrow().as_ref() {
            if let Some(Some(side)) = bv.get(&bucket.id) {
                let code = if *side { &bucket.if_branch } else { &bucket.else_branch };
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
        }
        // Default case: no change
        BranchBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            cond: self.transform_instruction(&bucket.cond),
            if_branch: self.transform_instructions(&bucket.if_branch),
            else_branch: self.transform_instructions(&bucket.else_branch),
        }
        .allocate()
    }
}
