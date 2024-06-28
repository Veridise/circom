mod loop_env_recorder;
mod extracted_location_updater;
pub mod body_extractor;

use std::cell::RefCell;
use std::collections::{BTreeMap, HashMap};
use std::vec;
use code_producers::llvm_elements::stdlib::GENERATED_FN_PREFIX;
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::TemplateCode;
use compiler::compiler_interface::Circuit;
use compiler::intermediate_representation::{
    new_id, BucketId, InstructionList, InstructionPointer, ToSExp, UpdateId,
};
use compiler::intermediate_representation::ir_interface::*;
use indexmap::{IndexMap, IndexSet};
use crate::bucket_interpreter::env::{Env, LibraryAccess};
use crate::bucket_interpreter::error::{self, BadInterp};
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::observer::Observer;
use crate::bucket_interpreter::LOOP_LIMIT;
use crate::{default__name, default__get_mem, default__run_template};
use super::{CircuitTransformationPass, GlobalPassData};
use self::{body_extractor::LoopBodyExtractor, loop_env_recorder::EnvRecorder};

const EXTRACT_LOOP_BODY_TO_NEW_FUNC: bool = true;

const DEBUG_LOOP_UNROLL: bool = false;

pub const LOOP_BODY_FN_PREFIX: &str = const_format::concatcp!(GENERATED_FN_PREFIX, "loop.body.");

/// Maps LoopBucket id to the unrolled version.
// Uses BTreeMap instead of HashMap because this type must implement the Hash trait.
type UnrolledLoops = BTreeMap<BucketId, BlockBucket>;
type UnrolledLoopCounts = BTreeMap<BucketId, usize>;

pub struct LoopUnrollPass<'d> {
    global_data: &'d RefCell<GlobalPassData>,
    memory: PassMemory,
    extractor: LoopBodyExtractor,
    // Wrapped in a RefCell because the reference to the static analysis is immutable but we need mutability
    //
    /// Track the order that the loops appear during the traversal to stabilize the order
    /// they appear in the new function names.
    loop_bucket_order: RefCell<IndexSet<BucketId>>,
    /// Maps the ID of the CallBucket that is currently on the interpreter's stack (or None
    /// if the interpreter is currently analyzing code that is not within a function) to a
    /// mapping of LoopBucket id to its unrolled replacement body.
    replacements: RefCell<HashMap<Option<BucketId>, UnrolledLoops>>,
    /// Maps CallBucket symbol (i.e. target function name) plus a mapping of LoopBucket IDs to
    /// iteration counts to the new function that has loops unrolled according to that mapping.
    /// Uses IndexMap to ensure consistent ordering of functions in the output (for lit tests).
    new_functions: RefCell<IndexMap<String, IndexMap<UnrolledLoopCounts, FunctionCode>>>,
    /// Within the CircuitTransformationPass impl below, this holds the unrolled loop bodies for
    /// when the function is called by the current CallBucket. The None key in this map is for the
    /// cases that are NOT inside a function. When traversal enters a function, this will change to
    /// the UnrolledLoops for that CallBucket.
    caller_context: RefCell<Option<UnrolledLoops>>,
}

impl<'d> LoopUnrollPass<'d> {
    pub fn new(prime: String, global_data: &'d RefCell<GlobalPassData>) -> Self {
        LoopUnrollPass {
            global_data,
            memory: PassMemory::new(prime),
            extractor: Default::default(),
            loop_bucket_order: Default::default(),
            replacements: Default::default(),
            new_functions: Default::default(),
            caller_context: Default::default(),
        }
    }

    fn try_unroll_loop(
        &self,
        bucket: &LoopBucket,
        env: &Env,
    ) -> Result<(Option<InstructionList>, usize), BadInterp> {
        if DEBUG_LOOP_UNROLL {
            println!("\n[UNROLL] Try unrolling loop {}:", bucket.id);
            for (i, s) in bucket.body.iter().enumerate() {
                println!("[{}/{}]{}", i + 1, bucket.body.len(), s.to_sexp().to_pretty(100));
            }
            for (i, s) in bucket.body.iter().enumerate() {
                println!("[{}/{}]{:?}", i + 1, bucket.body.len(), s);
            }
            println!("[UNROLL] LOOP ENTRY env {}", env);
        }
        // Compute loop iteration count. If unknown, return immediately.
        let recorder = EnvRecorder::new(self.global_data, &self.memory);
        {
            let interpreter = self.memory.build_interpreter(self.global_data, &recorder);
            let mut inner_env = env.clone();
            let mut n_iters = 0;
            loop {
                n_iters += 1;
                if n_iters >= LOOP_LIMIT {
                    return Result::Err(error::new_compute_err(format!(
                        "Could not determine loop count within {LOOP_LIMIT} iterations"
                    )));
                }
                recorder.record_header_env(&inner_env);
                let (cond, new_env) =
                    interpreter.execute_loop_bucket_once(bucket, inner_env, true)?;
                if DEBUG_LOOP_UNROLL {
                    println!(
                        "[UNROLL][try_unroll_loop] execute_loop_bucket_once() -> cond={:?}, env={:?}",
                        cond, new_env
                    );
                }
                match cond {
                    // If the conditional becomes unknown just give up.
                    None => return Ok((None, 0)),
                    // When conditional becomes `false`, iteration count is complete.
                    Some(false) => break,
                    // Otherwise, continue counting.
                    Some(true) => recorder.increment_iter(),
                };
                inner_env = new_env;
            }
            recorder.drop_header_env(); //free Env from the final iteration
        }
        if DEBUG_LOOP_UNROLL {
            println!("[UNROLL] recorder = {:?}", recorder);
        }

        let num_iter = recorder.get_iter();
        let mut block_body = vec![];
        if EXTRACT_LOOP_BODY_TO_NEW_FUNC && recorder.is_safe_to_move() && num_iter > 0 {
            // If the loop body contains more than one instruction, extract it into a
            // new function and generate 'num_iter' number of calls to that function.
            // Otherwise, just duplicate the body 'num_iter' number of times.
            match &bucket.body[..] {
                [a] => {
                    if DEBUG_LOOP_UNROLL {
                        println!(
                            "[UNROLL][try_unroll_loop] OUTCOME: safe to move, single statement, in-place"
                        );
                    }
                    for _ in 0..num_iter {
                        let mut copy = a.clone();
                        copy.update_id();
                        block_body.push(copy);
                    }
                }
                _ => {
                    if DEBUG_LOOP_UNROLL {
                        println!("[UNROLL][try_unroll_loop] OUTCOME: safe to move, extracting");
                    }
                    self.extractor.extract(
                        bucket,
                        recorder,
                        env.get_context_kind(),
                        &mut block_body,
                    )?;
                }
            }
        } else {
            //If the loop body is not safe to move into a new function, just unroll in-place.
            if DEBUG_LOOP_UNROLL {
                println!("[UNROLL][try_unroll_loop] OUTCOME: not safe to move, unrolling in-place");
            }
            for _ in 0..num_iter {
                for s in &bucket.body {
                    let mut copy = s.clone();
                    copy.update_id();
                    block_body.push(copy);
                }
            }
        }
        Ok((Some(block_body), num_iter))
    }

    // Will interpret the unrolled loop to check for additional loops inside
    fn continue_inside(&self, bucket: &BlockBucket, env: &Env) -> Result<(), BadInterp> {
        if DEBUG_LOOP_UNROLL {
            println!("[UNROLL][continue_inside] with {}", env);
        }
        let interpreter = self.memory.build_interpreter(self.global_data, self);
        let env = Env::new_unroll_block_env(env.clone(), &self.extractor);
        interpreter.execute_block_bucket(bucket, env, true)?;
        Ok(())
    }
}

impl Observer<Env<'_>> for LoopUnrollPass<'_> {
    fn on_loop_bucket(&self, bucket: &LoopBucket, env: &Env) -> Result<bool, BadInterp> {
        let result = self.try_unroll_loop(bucket, env);
        if DEBUG_LOOP_UNROLL {
            println!("[UNROLL][try_unroll_loop] result = {:?}", result);
        }
        // Add the loop bucket to the ordering for the before visiting within via continue_inside()
        //  so that outer loop iteration counts appear first in the new function name
        self.loop_bucket_order.borrow_mut().insert(bucket.id);
        //
        if let (Some(block_body), n_iters) = result? {
            let block = BlockBucket {
                id: new_id(),
                source_file_id: bucket.source_file_id,
                line: bucket.line,
                message_id: bucket.message_id,
                body: block_body,
                n_iters,
                label: String::from("unrolled_loop"),
            };
            self.continue_inside(&block, env)?;

            let caller_id = env.function_caller().cloned();
            if DEBUG_LOOP_UNROLL {
                println!(
                    "[UNROLL][on_loop_bucket] storing replacement for {} from caller {:?} :: {:?}",
                    bucket.id, caller_id, block
                );
            }
            // NOTE: 'caller_id' is None when the current loop is NOT located within a function.
            let previously_added = self
                .replacements
                .borrow_mut()
                .entry(caller_id)
                .or_default()
                .insert(bucket.id, block);
            assert!(previously_added.is_none(), "Overwriting {:?}", previously_added);
        }
        // Do not continue observing within this loop bucket because continue_inside()
        //  runs a new interpreter inside the unrolled body that is observed instead.
        Ok(false)
    }

    fn ignore_function_calls(&self) -> bool {
        false
    }

    fn ignore_extracted_function_calls(&self) -> bool {
        true
    }
}

impl CircuitTransformationPass for LoopUnrollPass<'_> {
    default__name!("LoopUnrollPass");
    default__get_mem!();
    default__run_template!();

    fn post_hook_circuit(&self, cir: &mut Circuit) -> Result<(), BadInterp> {
        // Transform and add the new body functions from the extractor
        let new_funcs = self.extractor.get_new_functions();
        cir.functions.reserve_exact(new_funcs.len());
        for f in new_funcs.iter() {
            cir.functions.insert(0, self.transform_function(&f)?);
        }
        // Add the duplicated versions of functions created by transform_call_bucket()
        for (_, ev) in self.new_functions.borrow_mut().drain(..) {
            for f in ev.into_values() {
                cir.functions.push(f);
            }
        }
        //ASSERT: All call buckets were visited and updated (only the None key may remain)
        assert!(self.replacements.borrow().iter().all(|(k, _)| k.is_none()));
        Ok(())
    }

    fn transform_call_bucket(&self, bucket: &CallBucket) -> Result<InstructionPointer, BadInterp> {
        if DEBUG_LOOP_UNROLL {
            println!("[UNROLL][transform_call_bucket] {:?}", bucket);
        }
        let call_bucket_id = Some(bucket.id);
        // The Some keys in the 'replacements' map are for the cases that are
        //  inside a function when executed from the CallBucket.id used as the key.
        // NOTE: This borrow is inside brackets to prevent runtime double borrow error.
        let reps = { self.replacements.borrow_mut().remove(&call_bucket_id) };
        if let Some(loop_replacements) = reps {
            assert!(!loop_replacements.is_empty());

            // Check if the needed function exists, else create it.
            let new_target = {
                let old_target = &bucket.symbol;
                let versions_key: UnrolledLoopCounts =
                    loop_replacements.iter().map(|(k, v)| (*k, v.n_iters)).collect();
                // Must not use a mutable borrow on `self.new_functions` here because the `transform_function`
                //  call below can recurse back to here and result in BorrowMutError.
                let cached_new_target = self
                    .new_functions
                    .borrow()
                    .get(old_target)
                    .and_then(|m| m.get(&versions_key))
                    .map(|f| f.header.clone());
                if let Some(new_target) = cached_new_target {
                    new_target
                } else {
                    // Set the caller context and then use self.transform_function(..) on the existing
                    //  function to create a new FunctionCode by running this transformer on the existing one.
                    let old_ctx = self.caller_context.replace(Some(loop_replacements));
                    if DEBUG_LOOP_UNROLL {
                        println!(
                            "[UNROLL][transform_call_bucket] set caller_context = {:?}",
                            self.caller_context.borrow()
                        );
                    }
                    let mut res = self.transform_function(&self.memory.get_function(old_target))?;
                    self.caller_context.replace(old_ctx);
                    if DEBUG_LOOP_UNROLL {
                        println!(
                            "[UNROLL][transform_call_bucket] restored caller_context = {:?}",
                            self.caller_context.borrow()
                        );
                    }
                    // Build the new function name according to the condition values but sorted by 'loop_bucket_order'
                    let new_name = self
                        .loop_bucket_order
                        .borrow()
                        .iter()
                        .filter_map(|id| versions_key.get(id))
                        .fold(old_target.clone(), |acc, c| format!("{}.{}", acc, c));
                    res.header = new_name.clone();
                    if DEBUG_LOOP_UNROLL {
                        println!("[UNROLL][transform_call_bucket] created function {:?}", res);
                    }
                    // Store the new function
                    let previously_added = self
                        .new_functions
                        .borrow_mut()
                        .entry(old_target.clone())
                        .or_default()
                        .insert(versions_key, res);
                    assert!(previously_added.is_none(), "Overwriting {:?}", previously_added);
                    new_name
                }
            };
            if DEBUG_LOOP_UNROLL {
                println!(
                    "[UNROLL][transform_call_bucket] replace call to {} with {}",
                    bucket.symbol, new_target
                );
            }
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
        self.transform_call_bucket_default(bucket)
    }

    fn transform_loop_bucket(&self, bucket: &LoopBucket) -> Result<InstructionPointer, BadInterp> {
        if DEBUG_LOOP_UNROLL {
            println!("[UNROLL][transform_loop_bucket] {:?}", bucket);
        }
        // Get from the current 'caller_context' or lookup via None key in 'evaluated_conditions'
        let reps = self.replacements.borrow();
        if let Some(m) = self.caller_context.borrow().as_ref().or_else(|| reps.get(&None)) {
            if let Some(unrolled) = m.get(&bucket.id) {
                return self.transform_block_bucket(unrolled);
            }
        }
        self.transform_loop_bucket_default(bucket)
    }
}

#[cfg(test)]
mod tests {
    use std::cell::RefCell;
    use compiler::circuit_design::template::TemplateCodeInfo;
    use compiler::compiler_interface::Circuit;
    use compiler::intermediate_representation::{Instruction, new_id};
    use compiler::intermediate_representation::ir_interface::{
        AddressType, Allocate, InstrContext, LoadBucket, LocationRule, LoopBucket, ObtainMetaImpl,
        OperatorType, StoreBucket,
    };
    use crate::passes::builders::{build_compute, build_u32_value};
    use crate::passes::{CircuitTransformationPass, GlobalPassData};
    use crate::passes::loop_unroll::{LoopUnrollPass, LOOP_BODY_FN_PREFIX};

    #[test]
    fn test_loop_unrolling() {
        let prime = "goldilocks".to_string();
        let global_data = RefCell::new(GlobalPassData::new());
        let pass = LoopUnrollPass::new(prime, &global_data);
        let circuit = example_program();
        let new_circuit =
            pass.transform_circuit(circuit.clone()).map_err(|e| e.get_message().clone()).unwrap();
        if cfg!(debug_assertions) {
            println!("{}", new_circuit.templates[0].body.last().unwrap().to_string());
        }
        assert_ne!(circuit, new_circuit);
        match new_circuit.templates[0].body.last().unwrap().as_ref() {
            Instruction::Block(b) => {
                // 5 iterations unrolled into 5 call statements targeting extracted loop body functions
                assert_eq!(b.body.len(), 5);
                assert!(b.body.iter().all(|s| if let Instruction::Call(c) = s.as_ref() {
                    c.symbol.starts_with(LOOP_BODY_FN_PREFIX)
                } else {
                    false
                }));
            }
            _ => assert!(false),
        }
    }

    fn example_program() -> Circuit {
        Circuit {
            templates: vec![Box::new(TemplateCodeInfo {
                id: 0,
                source_file_id: None,
                line: 0,
                header: "test_0".to_string(),
                name: "test".to_string(),
                is_parallel: false,
                is_parallel_component: false,
                is_not_parallel_component: false,
                has_parallel_sub_cmp: false,
                number_of_inputs: 0,
                number_of_outputs: 0,
                number_of_intermediates: 0,
                body: vec![
                    // (store 0 0)
                    StoreBucket {
                        id: new_id(),
                        source_file_id: None,
                        line: 0,
                        message_id: 0,
                        context: InstrContext { size: 0 },
                        dest_is_output: false,
                        dest_address_type: AddressType::Variable,
                        dest: LocationRule::Indexed {
                            location: build_u32_value(&ObtainMetaImpl::default(), 0),
                            template_header: None,
                        },
                        src: build_u32_value(&ObtainMetaImpl::default(), 0),
                        bounded_fn: None,
                    }
                    .allocate(),
                    // (store 1 0)
                    StoreBucket {
                        id: new_id(),
                        source_file_id: None,
                        line: 0,
                        message_id: 0,
                        context: InstrContext { size: 0 },
                        dest_is_output: false,
                        dest_address_type: AddressType::Variable,
                        dest: LocationRule::Indexed {
                            location: build_u32_value(&ObtainMetaImpl::default(), 1),
                            template_header: None,
                        },
                        src: build_u32_value(&ObtainMetaImpl::default(), 0),
                        bounded_fn: None,
                    }
                    .allocate(),
                    // (loop (compute le (load 1) 5) (
                    LoopBucket {
                        id: new_id(),
                        source_file_id: None,
                        line: 0,
                        message_id: 0,
                        continue_condition: build_compute(
                            &ObtainMetaImpl::default(),
                            OperatorType::Lesser,
                            0,
                            vec![
                                LoadBucket {
                                    id: new_id(),
                                    source_file_id: None,
                                    line: 0,
                                    message_id: 0,
                                    address_type: AddressType::Variable,
                                    src: LocationRule::Indexed {
                                        location: build_u32_value(&ObtainMetaImpl::default(), 1),
                                        template_header: None,
                                    },
                                    context: InstrContext { size: 0 },
                                    bounded_fn: None,
                                }
                                .allocate(),
                                build_u32_value(&ObtainMetaImpl::default(), 5),
                            ],
                        ),
                        body: vec![
                            //   (store 0 (compute add (load 0) 2))
                            StoreBucket {
                                id: new_id(),
                                source_file_id: None,
                                line: 0,
                                message_id: 0,
                                context: InstrContext { size: 0 },
                                dest_is_output: false,
                                dest_address_type: AddressType::Variable,
                                dest: LocationRule::Indexed {
                                    location: build_u32_value(&ObtainMetaImpl::default(), 0),
                                    template_header: None,
                                },
                                src: build_compute(
                                    &ObtainMetaImpl::default(),
                                    OperatorType::Add,
                                    0,
                                    vec![
                                        LoadBucket {
                                            id: new_id(),
                                            source_file_id: None,
                                            line: 0,
                                            message_id: 0,
                                            address_type: AddressType::Variable,
                                            src: LocationRule::Indexed {
                                                location: build_u32_value(
                                                    &ObtainMetaImpl::default(),
                                                    0,
                                                ),
                                                template_header: None,
                                            },
                                            context: InstrContext { size: 0 },
                                            bounded_fn: None,
                                        }
                                        .allocate(),
                                        build_u32_value(&ObtainMetaImpl::default(), 2),
                                    ],
                                ),
                                bounded_fn: None,
                            }
                            .allocate(),
                            //   (store 1 (compute add (load 1) 1))
                            StoreBucket {
                                id: new_id(),
                                source_file_id: None,
                                line: 0,
                                message_id: 0,
                                context: InstrContext { size: 0 },
                                dest_is_output: false,
                                dest_address_type: AddressType::Variable,
                                dest: LocationRule::Indexed {
                                    location: build_u32_value(&ObtainMetaImpl::default(), 1),
                                    template_header: None,
                                },
                                src: build_compute(
                                    &ObtainMetaImpl::default(),
                                    OperatorType::Add,
                                    0,
                                    vec![
                                        LoadBucket {
                                            id: new_id(),
                                            source_file_id: None,
                                            line: 0,
                                            message_id: 0,
                                            address_type: AddressType::Variable,
                                            src: LocationRule::Indexed {
                                                location: build_u32_value(
                                                    &ObtainMetaImpl::default(),
                                                    1,
                                                ),
                                                template_header: None,
                                            },
                                            context: InstrContext { size: 0 },
                                            bounded_fn: None,
                                        }
                                        .allocate(),
                                        build_u32_value(&ObtainMetaImpl::default(), 1),
                                    ],
                                ),
                                bounded_fn: None,
                            }
                            .allocate(),
                        ],
                    }
                    .allocate(), // ))
                ],
                var_stack_depth: 0,
                expression_stack_depth: 0,
                signal_stack_depth: 0,
                number_of_components: 0,
            })],
            functions: vec![],
            ..Default::default()
        }
    }
}
