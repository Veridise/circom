mod loop_env_recorder;
mod extracted_location_updater;
pub mod body_extractor;

use std::cell::RefCell;
use std::collections::HashMap;
use std::vec;
use code_producers::llvm_elements::stdlib::GENERATED_FN_PREFIX;
use compiler::circuit_design::template::TemplateCode;
use compiler::compiler_interface::Circuit;
use compiler::intermediate_representation::{
    new_id, BucketId, InstructionList, InstructionPointer, ToSExp, UpdateId,
};
use compiler::intermediate_representation::ir_interface::*;
use crate::bucket_interpreter::env::Env;
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

pub struct LoopUnrollPass<'d> {
    global_data: &'d RefCell<GlobalPassData>,
    memory: PassMemory,
    extractor: LoopBodyExtractor,
    // Wrapped in a RefCell because the reference to the static analysis is immutable but we need mutability
    replacements: RefCell<HashMap<BucketId, BlockBucket>>,
}

impl<'d> LoopUnrollPass<'d> {
    pub fn new(prime: String, global_data: &'d RefCell<GlobalPassData>) -> Self {
        LoopUnrollPass {
            global_data,
            memory: PassMemory::new(prime),
            replacements: Default::default(),
            extractor: Default::default(),
        }
    }

    fn try_unroll_loop(
        &self,
        bucket: &LoopBucket,
        env: &Env,
    ) -> Result<(Option<InstructionList>, usize), BadInterp> {
        if DEBUG_LOOP_UNROLL {
            println!("\nTry unrolling loop {}:", bucket.id);
            for (i, s) in bucket.body.iter().enumerate() {
                println!("[{}/{}]{}", i + 1, bucket.body.len(), s.to_sexp().to_pretty(100));
            }
            for (i, s) in bucket.body.iter().enumerate() {
                println!("[{}/{}]{:?}", i + 1, bucket.body.len(), s);
            }
            println!("LOOP ENTRY env {}", env);
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
            println!("recorder = {:?}", recorder);
        }

        let num_iter = recorder.get_iter();
        let mut block_body = vec![];
        if EXTRACT_LOOP_BODY_TO_NEW_FUNC && recorder.is_safe_to_move() && num_iter > 0 {
            // If the loop body contains more than one instruction, extract it into a
            // new function and generate 'num_iter' number of calls to that function.
            // Otherwise, just duplicate the body 'num_iter' number of times.
            match &bucket.body[..] {
                [a] => {
                    for _ in 0..num_iter {
                        let mut copy = a.clone();
                        copy.update_id();
                        block_body.push(copy);
                    }
                }
                _ => {
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

    // Will take the unrolled loop and interpretate it
    // checking if new loop buckets appear
    fn continue_inside(&self, bucket: &BlockBucket, env: &Env) -> Result<(), BadInterp> {
        let interpreter = self.memory.build_interpreter(self.global_data, self);
        let env = Env::new_unroll_block_env(env.clone(), &self.extractor);
        interpreter.execute_block_bucket(bucket, env, true)?;
        Ok(())
    }
}

impl Observer<Env<'_>> for LoopUnrollPass<'_> {
    fn on_loop_bucket(&self, bucket: &LoopBucket, env: &Env) -> Result<bool, BadInterp> {
        if let (Some(block_body), n_iters) = self.try_unroll_loop(bucket, env)? {
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
            self.replacements.borrow_mut().insert(bucket.id, block);
        }
        Ok(false)
    }

    fn ignore_function_calls(&self) -> bool {
        false
    }

    fn ignore_subcmp_calls(&self) -> bool {
        true
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
        // Transform and add the new body functions
        let new_funcs = self.extractor.get_new_functions();
        cir.functions.reserve_exact(new_funcs.len());
        for f in new_funcs.iter() {
            cir.functions.insert(0, self.transform_function(&f)?);
        }
        //ASSERT: All unrolled replacements were applied
        assert!(self.replacements.borrow().is_empty());
        Ok(())
    }

    fn transform_loop_bucket(&self, bucket: &LoopBucket) -> Result<InstructionPointer, BadInterp> {
        //NOTE: The bracket and assignment are needed here so the mutable borrow goes out of scope before the
        // transform* function is called within the match expression to avoid "already borrowed: BorrowMutError"
        let rep = { self.replacements.borrow_mut().remove(&bucket.id) };
        match rep {
            Some(unrolled_loop) => self.transform_block_bucket(&unrolled_loop),
            None => self.transform_loop_bucket_default(bucket),
        }
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
