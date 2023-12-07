mod loop_env_recorder;
mod extracted_location_updater;
pub mod body_extractor;

use std::cell::RefCell;
use std::collections::BTreeMap;
use std::vec;
use code_producers::llvm_elements::stdlib::GENERATED_FN_PREFIX;
use compiler::circuit_design::template::TemplateCode;
use compiler::compiler_interface::Circuit;
use compiler::intermediate_representation::{
    BucketId, InstructionList, InstructionPointer, new_id, UpdateId,
};
use compiler::intermediate_representation::ir_interface::*;
use crate::bucket_interpreter::env::Env;
use crate::bucket_interpreter::error::BadInterp;
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::observer::Observer;
use crate::{
    default__name, default__get_updated_field_constants, default__pre_hook_circuit,
    default__pre_hook_template,
};
use crate::passes::loop_unroll::loop_env_recorder::EnvRecorder;
use super::{CircuitTransformationPass, GlobalPassData};
use self::body_extractor::LoopBodyExtractor;

const EXTRACT_LOOP_BODY_TO_NEW_FUNC: bool = true;

const DEBUG_LOOP_UNROLL: bool = false;

pub const LOOP_BODY_FN_PREFIX: &str = const_format::concatcp!(GENERATED_FN_PREFIX, "loop.body.");

pub struct LoopUnrollPass<'d> {
    global_data: &'d RefCell<GlobalPassData>,
    memory: PassMemory,
    extractor: LoopBodyExtractor,
    // Wrapped in a RefCell because the reference to the static analysis is immutable but we need mutability
    replacements: RefCell<BTreeMap<BucketId, InstructionPointer>>,
}

impl<'d> LoopUnrollPass<'d> {
    pub fn new(prime: String, global_data: &'d RefCell<GlobalPassData>) -> Self {
        LoopUnrollPass {
            global_data,
            memory: PassMemory::new(prime, String::from(""), Default::default()),
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
            println!("\nTry unrolling loop {}:", bucket.id); //TODO: TEMP
            for (i, s) in bucket.body.iter().enumerate() {
                println!(
                    "[{}/{}]{}",
                    i + 1,
                    bucket.body.len(),
                    compiler::intermediate_representation::ToSExp::to_sexp(&**s).to_pretty(100)
                );
            }
            for (i, s) in bucket.body.iter().enumerate() {
                println!("[{}/{}]{:?}", i + 1, bucket.body.len(), s);
            }
            println!("LOOP ENTRY env {}", env); //TODO: TEMP
        }
        // Compute loop iteration count. If unknown, return immediately.
        let recorder = EnvRecorder::new(self.global_data, &self.memory);
        {
            let interpreter = self.memory.build_interpreter(self.global_data, &recorder);
            let mut inner_env = env.clone();
            loop {
                recorder.record_env_at_header(inner_env.clone());
                let (_, cond, new_env) =
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
        }
        if DEBUG_LOOP_UNROLL {
            println!("recorder = {:?}", recorder);
        }

        let mut block_body = vec![];
        if EXTRACT_LOOP_BODY_TO_NEW_FUNC && recorder.is_safe_to_move() && recorder.get_iter() > 0 {
            // If the loop body contains more than one instruction, extract it into a new
            // function and generate 'recorder.get_iter()' number of calls to that function.
            // Otherwise, just duplicate the body 'recorder.get_iter()' number of times.
            match &bucket.body[..] {
                [a] => {
                    for _ in 0..recorder.get_iter() {
                        let mut copy = a.clone();
                        copy.update_id();
                        block_body.push(copy);
                    }
                }
                _ => {
                    self.extractor.extract(bucket, &recorder, &mut block_body)?;
                }
            }
        } else {
            //If the loop body is not safe to move into a new function, just unroll in-place.
            for _ in 0..recorder.get_iter() {
                for s in &bucket.body {
                    let mut copy: Box<Instruction> = s.clone();
                    copy.update_id();
                    block_body.push(copy);
                }
            }
        }
        Ok((Some(block_body), recorder.get_iter()))
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
            self.replacements.borrow_mut().insert(bucket.id, block.allocate());
        }
        Ok(false)
    }

    fn ignore_function_calls(&self) -> bool {
        true
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
    default__get_updated_field_constants!();
    default__pre_hook_circuit!();
    default__pre_hook_template!();

    fn post_hook_circuit(&self, cir: &mut Circuit) -> Result<(), BadInterp> {
        // Transform and add the new body functions
        for f in self.extractor.get_new_functions().iter() {
            cir.functions.push(self.transform_function(&f)?);
        }
        Ok(())
    }

    fn transform_loop_bucket(&self, bucket: &LoopBucket) -> Result<InstructionPointer, BadInterp> {
        if let Some(unrolled_loop) = self.replacements.borrow().get(&bucket.id) {
            return self.transform_instruction(unrolled_loop);
        }
        Ok(LoopBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            continue_condition: self.transform_instruction(&bucket.continue_condition)?,
            body: self.transform_instructions(&bucket.body)?,
        }
        .allocate())
    }
}

#[cfg(test)]
mod test {
    use std::cell::RefCell;
    use std::collections::HashMap;
    use compiler::circuit_design::template::TemplateCodeInfo;
    use compiler::compiler_interface::Circuit;
    use compiler::intermediate_representation::{Instruction, new_id};
    use compiler::intermediate_representation::ir_interface::{
        AddressType, Allocate, ComputeBucket, InstrContext, LoadBucket, LocationRule, LoopBucket,
        OperatorType, StoreBucket, ValueBucket, ValueType,
    };
    use crate::passes::{CircuitTransformationPass, GlobalPassData};
    use crate::passes::loop_unroll::{LoopUnrollPass, LOOP_BODY_FN_PREFIX};

    #[test]
    fn test_loop_unrolling() {
        let prime = "goldilocks".to_string();
        let global_data = RefCell::new(GlobalPassData::new());
        let pass = LoopUnrollPass::new(prime, &global_data);
        let mut circuit = example_program();
        circuit.llvm_data.variable_index_mapping.insert("test_0".to_string(), HashMap::new());
        circuit.llvm_data.signal_index_mapping.insert("test_0".to_string(), HashMap::new());
        circuit.llvm_data.component_index_mapping.insert("test_0".to_string(), HashMap::new());
        let new_circuit =
            pass.transform_circuit(&circuit).map_err(|e| e.get_message().clone()).unwrap();
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
            wasm_producer: Default::default(),
            c_producer: Default::default(),
            llvm_data: Default::default(),
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
                            location: ValueBucket {
                                id: new_id(),
                                source_file_id: None,
                                line: 0,
                                message_id: 0,
                                parse_as: ValueType::U32,
                                op_aux_no: 0,
                                value: 0,
                            }
                            .allocate(),
                            template_header: Some("test_0".to_string()),
                        },
                        src: ValueBucket {
                            id: new_id(),
                            source_file_id: None,
                            line: 0,
                            message_id: 0,
                            parse_as: ValueType::U32,
                            op_aux_no: 0,
                            value: 0,
                        }
                        .allocate(),
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
                            location: ValueBucket {
                                id: new_id(),
                                source_file_id: None,
                                line: 0,
                                message_id: 0,
                                parse_as: ValueType::U32,
                                op_aux_no: 0,
                                value: 1,
                            }
                            .allocate(),
                            template_header: Some("test_0".to_string()),
                        },
                        src: ValueBucket {
                            id: new_id(),
                            source_file_id: None,
                            line: 0,
                            message_id: 0,
                            parse_as: ValueType::U32,
                            op_aux_no: 0,
                            value: 0,
                        }
                        .allocate(),
                        bounded_fn: None,
                    }
                    .allocate(),
                    // (loop (compute le (load 1) 5) (
                    LoopBucket {
                        id: new_id(),
                        source_file_id: None,
                        line: 0,
                        message_id: 0,
                        continue_condition: ComputeBucket {
                            id: new_id(),
                            source_file_id: None,
                            line: 0,
                            message_id: 0,
                            op: OperatorType::Lesser,
                            op_aux_no: 0,
                            stack: vec![
                                LoadBucket {
                                    id: new_id(),
                                    source_file_id: None,
                                    line: 0,
                                    message_id: 0,
                                    address_type: AddressType::Variable,
                                    src: LocationRule::Indexed {
                                        location: ValueBucket {
                                            id: new_id(),
                                            source_file_id: None,
                                            line: 0,
                                            message_id: 0,
                                            parse_as: ValueType::U32,
                                            op_aux_no: 0,
                                            value: 1,
                                        }
                                        .allocate(),
                                        template_header: Some("test_0".to_string()),
                                    },
                                    bounded_fn: None,
                                }
                                .allocate(),
                                ValueBucket {
                                    id: new_id(),
                                    source_file_id: None,
                                    line: 0,
                                    message_id: 0,
                                    parse_as: ValueType::U32,
                                    op_aux_no: 0,
                                    value: 5,
                                }
                                .allocate(),
                            ],
                        }
                        .allocate(),
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
                                    location: ValueBucket {
                                        id: new_id(),
                                        source_file_id: None,
                                        line: 0,
                                        message_id: 0,
                                        parse_as: ValueType::U32,
                                        op_aux_no: 0,
                                        value: 0,
                                    }
                                    .allocate(),
                                    template_header: None,
                                },
                                src: ComputeBucket {
                                    id: new_id(),
                                    source_file_id: None,
                                    line: 0,
                                    message_id: 0,
                                    op: OperatorType::Add,
                                    op_aux_no: 0,
                                    stack: vec![
                                        LoadBucket {
                                            id: new_id(),
                                            source_file_id: None,
                                            line: 0,
                                            message_id: 0,
                                            address_type: AddressType::Variable,
                                            src: LocationRule::Indexed {
                                                location: ValueBucket {
                                                    id: new_id(),
                                                    source_file_id: None,
                                                    line: 0,
                                                    message_id: 0,
                                                    parse_as: ValueType::U32,
                                                    op_aux_no: 0,
                                                    value: 0,
                                                }
                                                .allocate(),
                                                template_header: Some("test_0".to_string()),
                                            },
                                            bounded_fn: None,
                                        }
                                        .allocate(),
                                        ValueBucket {
                                            id: new_id(),
                                            source_file_id: None,
                                            line: 0,
                                            message_id: 0,
                                            parse_as: ValueType::U32,
                                            op_aux_no: 0,
                                            value: 2,
                                        }
                                        .allocate(),
                                    ],
                                }
                                .allocate(),
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
                                    location: ValueBucket {
                                        id: new_id(),
                                        source_file_id: None,
                                        line: 0,
                                        message_id: 0,
                                        parse_as: ValueType::U32,
                                        op_aux_no: 0,
                                        value: 1,
                                    }
                                    .allocate(),
                                    template_header: None,
                                },
                                src: ComputeBucket {
                                    id: new_id(),
                                    source_file_id: None,
                                    line: 0,
                                    message_id: 0,
                                    op: OperatorType::Add,
                                    op_aux_no: 0,
                                    stack: vec![
                                        LoadBucket {
                                            id: new_id(),
                                            source_file_id: None,
                                            line: 0,
                                            message_id: 0,
                                            address_type: AddressType::Variable,
                                            src: LocationRule::Indexed {
                                                location: ValueBucket {
                                                    id: new_id(),
                                                    source_file_id: None,
                                                    line: 0,
                                                    message_id: 0,
                                                    parse_as: ValueType::U32,
                                                    op_aux_no: 0,
                                                    value: 1,
                                                }
                                                .allocate(),
                                                template_header: Some("test_0".to_string()),
                                            },
                                            bounded_fn: None,
                                        }
                                        .allocate(),
                                        ValueBucket {
                                            id: new_id(),
                                            source_file_id: None,
                                            line: 0,
                                            message_id: 0,
                                            parse_as: ValueType::U32,
                                            op_aux_no: 0,
                                            value: 1,
                                        }
                                        .allocate(),
                                    ],
                                }
                                .allocate(),
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
        }
    }
}
