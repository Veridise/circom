use std::cell::RefCell;
use std::collections::BTreeMap;
use std::vec;
use code_producers::llvm_elements::stdlib::GENERATED_FN_PREFIX;
use code_producers::llvm_elements::fr::FR_IDENTITY_ARR_0_PTR;
use compiler::circuit_design::function::{FunctionCodeInfo, FunctionCode};
use compiler::circuit_design::template::TemplateCode;
use compiler::compiler_interface::Circuit;
use compiler::hir::very_concrete_program::Param;
use compiler::intermediate_representation::{
    BucketId, InstructionList, InstructionPointer, new_id, UpdateId,
};
use compiler::intermediate_representation::ir_interface::*;
use crate::bucket_interpreter::env::Env;
use crate::bucket_interpreter::observer::InterpreterObserver;
use crate::passes::CircuitTransformationPass;
use crate::passes::memory::PassMemory;

pub struct LoopUnrollPass {
    // Wrapped in a RefCell because the reference to the static analysis is immutable but we need mutability
    memory: PassMemory,
    replacements: RefCell<BTreeMap<BucketId, InstructionPointer>>,
    new_functions: RefCell<Vec<FunctionCode>>,
}

impl LoopUnrollPass {
    pub fn new(prime: &String) -> Self {
        LoopUnrollPass {
            memory: PassMemory::new(prime, String::from(""), Default::default()),
            replacements: Default::default(),
            new_functions: Default::default(),
        }
    }

    fn extract_body(&self, bucket: &LoopBucket) -> String {
        // Copy loop body and add a "return void" at the end
        let mut new_body = vec![];
        for s in &bucket.body {
            let mut copy = s.clone();
            copy.update_id();
            new_body.push(copy);
        }
        new_body.push(
            ReturnBucket {
                id: new_id(),
                source_file_id: bucket.source_file_id,
                line: bucket.line,
                message_id: bucket.message_id,
                with_size: usize::MAX, // size > 1 will produce "return void" LLVM instruction
                value: NopBucket { id: new_id() }.allocate(),
            }
            .allocate(),
        );
        // Create new function to hold the copied body
        let name = format!("{}loop.body.{}", GENERATED_FN_PREFIX, new_id());
        let new_func = Box::new(FunctionCodeInfo {
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            name: name.clone(),
            header: name.clone(),
            body: new_body,
            params: vec![
                Param { name: String::from("signals"), length: vec![0] },
                Param { name: String::from("lvars"), length: vec![0] },
            ],
            returns: vec![0], // this will produce void return type on the function
            ..FunctionCodeInfo::default()
        });
        self.memory.add_function(&new_func);
        self.new_functions.borrow_mut().push(new_func);
        //
        name
    }

    fn try_unroll_loop(&self, bucket: &LoopBucket, env: &Env) -> (Option<InstructionList>, usize) {
        // Compute loop iteration count. If unknown, return immediately.
        let loop_count;
        {
            let mut iters = 0;
            let interpreter = self.memory.build_interpreter(self);
            let mut inner_env = env.clone();
            loop {
                let (_, cond, new_env) =
                    interpreter.execute_loop_bucket_once(bucket, inner_env, false);
                match cond {
                    // If the conditional becomes unknown just give up.
                    None => return (None, 0),
                    // When conditional becomes `false`, iteration count is complete.
                    Some(false) => break,
                    // Otherwise, continue counting.
                    Some(true) => iters += 1,
                }
                inner_env = new_env;
            }
            loop_count = iters;
        }

        // If the loop body contains more than one instruction, extract it into a
        // new function and generate 'loop_count' number of calls to that function.
        // Otherwise, just duplicate the body 'loop_count' number of times.
        let mut block_body = vec![];
        match &bucket.body[..] {
            [a] => {
                for _ in 0..loop_count {
                    let mut copy = a.clone();
                    copy.update_id();
                    block_body.push(copy);
                }
            }
            b => {
                assert!(b.len() > 1);
                //
                //TODO: If any subcmps are used inside the loop body, add an additional '[0 x i256]*' parameter on
                //  the new function for each one that is used and pass the arena of each into the function call.
                //
                //TODO: Any value indexed by a variable that changes from one loop iteration to another needs to
                //  be indexed outside of the function and then have just that pointer passed into the function.
                //
                let name = self.extract_body(bucket);
                for _ in 0..loop_count {
                    block_body.push(
                        // NOTE: CallBucket arguments must use a LoadBucket to reference the necessary pointers
                        //  within the current body. However, it doesn't actually need to generate a load
                        //  instruction to use these pointers as parameters to the function so we must use the
                        //  `bounded_fn` field of the LoadBucket to specify the identity function to perform
                        //  the "loading" (but really it just returns the pointer that was passed in).
                        CallBucket {
                            id: new_id(),
                            source_file_id: bucket.source_file_id,
                            line: bucket.line,
                            message_id: bucket.message_id,
                            symbol: name.clone(),
                            return_info: ReturnType::Intermediate { op_aux_no: 0 },
                            arena_size: 0, // size 0 indicates arguments should not be placed into an arena
                            argument_types: vec![], // LLVM IR generation doesn't use this field
                            arguments: vec![
                                // Parameter for signals/arena
                                LoadBucket {
                                    id: new_id(),
                                    source_file_id: bucket.source_file_id,
                                    line: bucket.line,
                                    message_id: bucket.message_id,
                                    address_type: AddressType::Signal,
                                    src: LocationRule::Indexed {
                                        location: ValueBucket {
                                            id: new_id(),
                                            source_file_id: bucket.source_file_id,
                                            line: bucket.line,
                                            message_id: bucket.message_id,
                                            parse_as: ValueType::U32,
                                            op_aux_no: 0,
                                            value: 0,
                                        }
                                        .allocate(),
                                        template_header: None,
                                    },
                                    bounded_fn: Some(String::from(FR_IDENTITY_ARR_0_PTR)),
                                }
                                .allocate(),
                                // Parameter for local vars
                                LoadBucket {
                                    id: new_id(),
                                    source_file_id: bucket.source_file_id,
                                    line: bucket.line,
                                    message_id: bucket.message_id,
                                    address_type: AddressType::Variable,
                                    src: LocationRule::Indexed {
                                        location: ValueBucket {
                                            id: new_id(),
                                            source_file_id: bucket.source_file_id,
                                            line: bucket.line,
                                            message_id: bucket.message_id,
                                            parse_as: ValueType::U32,
                                            op_aux_no: 0,
                                            value: 0,
                                        }
                                        .allocate(),
                                        template_header: None,
                                    },
                                    bounded_fn: Some(String::from(FR_IDENTITY_ARR_0_PTR)),
                                }
                                .allocate(),
                            ],
                        }
                        .allocate(),
                    );
                }
            }
        }
        (Some(block_body), loop_count)
    }

    // Will take the unrolled loop and interpretate it
    // checking if new loop buckets appear
    fn continue_inside(&self, bucket: &BlockBucket, env: &Env) {
        let interpreter = self.memory.build_interpreter(self);
        interpreter.execute_block_bucket(bucket, env.clone(), true);
    }
}

impl InterpreterObserver for LoopUnrollPass {
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

    fn on_loop_bucket(&self, bucket: &LoopBucket, env: &Env) -> bool {
        if let (Some(block_body), n_iters) = self.try_unroll_loop(bucket, env) {
            let block = BlockBucket {
                id: new_id(),
                source_file_id: bucket.source_file_id,
                line: bucket.line,
                message_id: bucket.message_id,
                body: block_body,
                n_iters,
            };
            self.continue_inside(&block, env);
            self.replacements.borrow_mut().insert(bucket.id, block.allocate());
        }
        false
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

    fn on_branch_bucket(&self, _bucket: &BranchBucket, _env: &Env) -> bool {
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
}

impl CircuitTransformationPass for LoopUnrollPass {
    fn name(&self) -> &str {
        "LoopUnrollPass"
    }

    fn pre_hook_circuit(&self, circuit: &Circuit) {
        self.memory.fill_from_circuit(circuit);
    }

    fn post_hook_circuit(&self, cir: &mut Circuit) {
        for f in self.new_functions.borrow().iter() {
            cir.functions.push(self.transform_function(&f));
        }
    }

    fn pre_hook_template(&self, template: &TemplateCode) {
        self.memory.set_scope(template);
        self.memory.run_template(self, template);
    }

    fn get_updated_field_constants(&self) -> Vec<String> {
        self.memory.get_field_constants_clone()
    }

    fn transform_loop_bucket(&self, bucket: &LoopBucket) -> InstructionPointer {
        if let Some(unrolled_loop) = self.replacements.borrow().get(&bucket.id) {
            return self.transform_instruction(unrolled_loop);
        }
        LoopBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            continue_condition: self.transform_instruction(&bucket.continue_condition),
            body: self.transform_instructions(&bucket.body),
        }
        .allocate()
    }
}

#[cfg(test)]
mod test {
    use std::collections::HashMap;
    use compiler::circuit_design::template::TemplateCodeInfo;
    use compiler::compiler_interface::Circuit;
    use compiler::intermediate_representation::{Instruction, new_id};
    use compiler::intermediate_representation::ir_interface::{
        AddressType, Allocate, ComputeBucket, InstrContext, LoadBucket, LocationRule, LoopBucket,
        OperatorType, StoreBucket, ValueBucket, ValueType,
    };
    use crate::passes::CircuitTransformationPass;
    use crate::passes::loop_unroll::LoopUnrollPass;

    #[test]
    fn test_loop_unrolling() {
        let prime = "goldilocks".to_string();
        let pass = LoopUnrollPass::new(&prime);
        let mut circuit = example_program();
        circuit.llvm_data.variable_index_mapping.insert("test_0".to_string(), HashMap::new());
        circuit.llvm_data.signal_index_mapping.insert("test_0".to_string(), HashMap::new());
        circuit.llvm_data.component_index_mapping.insert("test_0".to_string(), HashMap::new());
        let new_circuit = pass.transform_circuit(&circuit);
        if cfg!(debug_assertions) {
            println!("{}", new_circuit.templates[0].body.last().unwrap().to_string());
        }
        assert_ne!(circuit, new_circuit);
        match new_circuit.templates[0].body.last().unwrap().as_ref() {
            Instruction::Block(b) => assert_eq!(b.body.len(), 10), // 5 iterations unrolled times 2 statements in the loop body
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
