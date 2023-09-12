use std::cell::RefCell;
use std::collections::BTreeMap;
use std::ops::Range;
use compiler::circuit_design::template::TemplateCode;
use compiler::compiler_interface::Circuit;
use compiler::intermediate_representation::{Instruction, InstructionPointer, new_id};
use compiler::intermediate_representation::ir_interface::*;
use compiler::num_bigint::BigInt;
use code_producers::llvm_elements::array_switch::{get_array_load_symbol, get_array_store_symbol};
use program_structure::constants::UsefulConstants;
use crate::bucket_interpreter::env::Env;
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::observer::InterpreterObserver;
use crate::bucket_interpreter::operations::compute_operation;
use crate::bucket_interpreter::R;
use crate::bucket_interpreter::value::Value::{KnownU32, KnownBigInt};
use crate::passes::CircuitTransformationPass;

struct ZeroingInterpreter<'a> {
    pub constant_fields: &'a Vec<String>,
    p: BigInt,
}

impl<'a> ZeroingInterpreter<'a> {
    pub fn init(prime: &'a String, constant_fields: &'a Vec<String>) -> Self {
        ZeroingInterpreter { constant_fields, p: UsefulConstants::new(prime).get_p().clone() }
    }

    pub fn execute_value_bucket<'env>(&self, bucket: &ValueBucket, env: Env<'env>) -> R<'env> {
        (
            Some(match bucket.parse_as {
                ValueType::BigInt => {
                    let constant = &self.constant_fields[bucket.value];
                    KnownBigInt(
                        BigInt::parse_bytes(constant.as_bytes(), 10)
                            .expect(format!("Cannot parse constant {}", constant).as_str()),
                    )
                }
                ValueType::U32 => KnownU32(bucket.value),
            }),
            env,
        )
    }

    pub fn execute_load_bucket<'env>(&self, _bucket: &'env LoadBucket, env: Env<'env>) -> R<'env> {
        (Some(KnownU32(0)), env)
    }

    pub fn execute_compute_bucket<'env>(
        &self,
        bucket: &'env ComputeBucket,
        env: Env<'env>,
    ) -> R<'env> {
        let mut stack = vec![];
        let mut env = env;
        for i in &bucket.stack {
            let (value, new_env) = self.execute_instruction(i, env);
            env = new_env;
            stack.push(value.expect("Stack value in ComputeBucket must yield a value!"));
        }
        // If any value of the stack is unknown we just return 0
        if stack.iter().any(|v| v.is_unknown()) {
            return (Some(KnownU32(0)), env);
        }
        let p = &self.p;
        let computed_value = compute_operation(bucket, &stack, p);
        (computed_value, env)
    }

    pub fn execute_instruction<'env>(
        &self,
        inst: &'env InstructionPointer,
        env: Env<'env>,
    ) -> R<'env> {
        match inst.as_ref() {
            Instruction::Value(b) => self.execute_value_bucket(b, env),
            Instruction::Load(b) => self.execute_load_bucket(b, env),
            Instruction::Compute(b) => self.execute_compute_bucket(b, env),
            _ => unreachable!(),
        }
    }
}

pub struct UnknownIndexSanitizationPass {
    // Wrapped in a RefCell because the reference to the static analysis is immutable but we need mutability
    memory: PassMemory,
    load_replacements: RefCell<BTreeMap<LoadBucket, Range<usize>>>,
    store_replacements: RefCell<BTreeMap<StoreBucket, Range<usize>>>,
}

/**
 * The goal of this pass is to
 */
impl UnknownIndexSanitizationPass {
    pub fn new(prime: &String) -> Self {
        UnknownIndexSanitizationPass {
            memory: PassMemory::new(prime, "".to_string(), Default::default()),
            load_replacements: Default::default(),
            store_replacements: Default::default(),
        }
    }

    fn find_bounds(
        &self,
        address: &AddressType,
        location: &LocationRule,
        env: &Env,
    ) -> Range<usize> {
        /*
         * We assume locations are of the form:
         *      (base_offset + (mul_offset * UNKNOWN))
         * So, if we set the unknown value to 0, we will compute the base offset,
         * which will let us look up the range of the underlying array.
         *
         * The expression above is for 1-D arrays, multidimensional arrays follow
         * a similar pattern that is also handled here.
         */
        match location {
            LocationRule::Mapped { .. } => unreachable!(),
            LocationRule::Indexed { location, .. } => {
                let mem = &self.memory;
                let constant_fields = mem.get_field_constants_clone();
                let interpreter = ZeroingInterpreter::init(mem.get_prime(), &constant_fields);
                let (res, _) = interpreter.execute_instruction(location, env.clone());

                let offset = match res {
                    Some(KnownU32(base)) => base,
                    _ => unreachable!(),
                };
                match address {
                    AddressType::Variable => mem.get_current_scope_variables_index_mapping(&offset),
                    AddressType::Signal => mem.get_current_scope_signal_index_mapping(&offset),
                    AddressType::SubcmpSignal { .. } => {
                        mem.get_current_scope_component_addr_index_mapping(&offset)
                    }
                }
            }
        }
    }

    fn is_location_unknown(
        &self,
        _address: &AddressType,
        location: &LocationRule,
        env: &Env,
    ) -> bool {
        let mem = &self.memory;
        let interpreter = mem.build_interpreter(self);

        let resolved_addr = match location {
            LocationRule::Indexed { location, .. } => {
                let (r, _) = interpreter.execute_instruction(location, env.clone(), false);
                r.expect("location must produce a value!")
            }
            LocationRule::Mapped { .. } => unreachable!(),
        };

        resolved_addr.is_unknown()
    }
}

/**
 * The goal is to replace:
 * - loads with a function call that returns the loaded value
 * - stores with a function call that performs the store
 */
impl InterpreterObserver for UnknownIndexSanitizationPass {
    fn on_value_bucket(&self, _bucket: &ValueBucket, _env: &Env) -> bool {
        true
    }

    fn on_load_bucket(&self, bucket: &LoadBucket, env: &Env) -> bool {
        let address = &bucket.address_type;
        let location = &bucket.src;
        if self.is_location_unknown(address, location, env) {
            let index_range = self.find_bounds(address, location, env);
            self.load_replacements.borrow_mut().insert(bucket.clone(), index_range);
        }
        true
    }

    fn on_store_bucket(&self, bucket: &StoreBucket, env: &Env) -> bool {
        let address = &bucket.dest_address_type;
        let location = &bucket.dest;
        if self.is_location_unknown(address, location, env) {
            let index_range = self.find_bounds(address, location, env);
            self.store_replacements.borrow_mut().insert(bucket.clone(), index_range);
        }
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
        false
    }

    fn ignore_subcmp_calls(&self) -> bool {
        false
    }
}

impl CircuitTransformationPass for UnknownIndexSanitizationPass {
    fn name(&self) -> &str {
        "UnknownIndexSanitizationPass"
    }

    fn transform_load_bucket(&self, bucket: &LoadBucket) -> InstructionPointer {
        let bounded_fn_symbol = match self.load_replacements.borrow().get(bucket) {
            Some(index_range) => Some(get_array_load_symbol(index_range)),
            None => bucket.bounded_fn.clone(),
        };
        LoadBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id.clone(),
            line: bucket.line,
            message_id: bucket.message_id,
            address_type: self.transform_address_type(&bucket.address_type),
            src: self.transform_location_rule(&bucket.src),
            bounded_fn: bounded_fn_symbol,
        }
        .allocate()
    }

    fn transform_store_bucket(&self, bucket: &StoreBucket) -> InstructionPointer {
        let bounded_fn_symbol = match self.store_replacements.borrow().get(bucket) {
            Some(index_range) => Some(get_array_store_symbol(index_range)),
            None => bucket.bounded_fn.clone(),
        };
        StoreBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id.clone(),
            line: bucket.line,
            message_id: bucket.message_id,
            context: bucket.context.clone(),
            dest_is_output: bucket.dest_is_output,
            dest_address_type: self.transform_address_type(&bucket.dest_address_type),
            dest: self.transform_location_rule(&bucket.dest),
            src: self.transform_instruction(&bucket.src),
            bounded_fn: bounded_fn_symbol,
        }
        .allocate()
    }

    fn get_updated_field_constants(&self) -> Vec<String> {
        self.memory.get_field_constants_clone()
    }

    fn pre_hook_circuit(&self, circuit: &Circuit) {
        self.memory.fill_from_circuit(circuit);
    }

    fn pre_hook_template(&self, template: &TemplateCode) {
        self.memory.set_scope(template);
        self.memory.run_template(self, template);
    }
}
