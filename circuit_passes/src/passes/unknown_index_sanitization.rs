use std::borrow::Borrow;
use std::cell::RefCell;
use std::collections::BTreeMap;

use compiler::circuit_design::template::TemplateCode;
use compiler::compiler_interface::Circuit;
use compiler::intermediate_representation::{Instruction, InstructionPointer};
use compiler::intermediate_representation::ir_interface::{AddressType, Allocate, AssertBucket, BlockBucket, BranchBucket, CallBucket, ComputeBucket, ConstraintBucket, CreateCmpBucket, LoadBucket, LocationRule, LogBucket, LoopBucket, NopBucket, ReturnBucket, StoreBucket, ValueBucket, OperatorType, ValueType};
use compiler::num_bigint::BigInt;
use compiler::num_traits::{int, Zero};
use std::ops::Range;
use program_structure::constants::UsefulConstants;

use crate::bucket_interpreter::env::Env;
use crate::bucket_interpreter::{BucketInterpreter, value, R};
use crate::bucket_interpreter::observer::InterpreterObserver;
use crate::bucket_interpreter::value::{mod_value, resolve_operation, Value, Value::KnownU32, Value::KnownBigInt};
use crate::passes::CircuitTransformationPass;
use crate::passes::memory::PassMemory;


struct ZeroingInterpreter<'a> {
    prime: &'a String,
    pub constant_fields: &'a Vec<String>,
    p: Value
}

impl<'a> ZeroingInterpreter<'a> {

    pub fn init(
        prime: &'a String,
        constant_fields: &'a Vec<String>,
    ) -> Self {
        ZeroingInterpreter {
            prime,
            constant_fields,
            p: KnownBigInt(UsefulConstants::new(prime).get_p().clone()),
        }
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
            env
        )
    }

    pub fn execute_load_bucket<'env>(&self, bucket: &'env LoadBucket, env: Env<'env>) -> R<'env> {
        (Some(KnownU32(0)), env)
    }

    pub fn execute_compute_bucket<'env>(&self, bucket: &'env ComputeBucket, env: Env<'env>) -> R<'env> {
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
        let computed_value = Some(match bucket.op {
            OperatorType::Mul => resolve_operation(value::mul_value, p, &stack),
            OperatorType::Div => resolve_operation(value::div_value, p, &stack),
            OperatorType::Add => resolve_operation(value::add_value, p, &stack),
            OperatorType::Sub => resolve_operation(value::sub_value, p, &stack),
            OperatorType::Pow => resolve_operation(value::pow_value, p, &stack),
            OperatorType::IntDiv => resolve_operation(value::int_div_value, p, &stack),
            OperatorType::Mod => resolve_operation(value::mod_value, p, &stack),
            OperatorType::ShiftL => resolve_operation(value::shift_l_value, p, &stack),
            OperatorType::ShiftR => resolve_operation(value::shift_r_value, p, &stack),
            OperatorType::LesserEq => value::lesser_eq(&stack[0], &stack[1]),
            OperatorType::GreaterEq => value::greater_eq(&stack[0], &stack[1]),
            OperatorType::Lesser => value::lesser(&stack[0], &stack[1]),
            OperatorType::Greater => value::greater(&stack[0], &stack[1]),
            OperatorType::Eq(1) => value::eq1(&stack[0], &stack[1]),
            OperatorType::Eq(_) => todo!(),
            OperatorType::NotEq => value::not_eq(&stack[0], &stack[1]),
            OperatorType::BoolOr => stack.iter().fold(KnownU32(0), value::bool_or_value),
            OperatorType::BoolAnd => stack.iter().fold(KnownU32(1), value::bool_and_value),
            OperatorType::BitOr => resolve_operation(value::bit_or_value, p, &stack),
            OperatorType::BitAnd => resolve_operation(value::bit_and_value, p, &stack),
            OperatorType::BitXor => resolve_operation(value::bit_xor_value, p, &stack),
            OperatorType::PrefixSub => {
                mod_value(&value::prefix_sub(&stack[0]), p)
            }
            OperatorType::BoolNot => KnownU32((!stack[0].to_bool()).into()),
            OperatorType::Complement => {
                mod_value(&value::complement(&stack[0]), p)
            }
            OperatorType::ToAddress => value::to_address(&stack[0]),
            OperatorType::MulAddress => stack.iter().fold(KnownU32(1), value::mul_address),
            OperatorType::AddAddress => stack.iter().fold(KnownU32(0), value::add_address),
        });
        (computed_value, env)
    }

    pub fn execute_instruction<'env>(&self, inst: &'env InstructionPointer, env: Env<'env>) -> R<'env> {
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
    memory: RefCell<PassMemory>,
    replacements: RefCell<BTreeMap<LocationRule, LocationRule>>,
}


/**
 * The goal of this pass is to
 */
impl UnknownIndexSanitizationPass {
    pub fn new(prime: &String) -> Self {
        UnknownIndexSanitizationPass { memory: PassMemory::new_cell(prime, "".to_string(), Default::default()), replacements: Default::default() }
    }

    fn find_bounds(&self, address: &AddressType, location: &LocationRule, env: &Env) -> Range<usize> {
        let mem = self.memory.borrow();
        let interpreter = ZeroingInterpreter::init(&mem.prime, &mem.constant_fields);
        let current_scope = &mem.current_scope;

        let mapping = match address {
            AddressType::Variable => &mem.variables_index_mapping[current_scope],
            AddressType::Signal => &mem.signal_index_mapping[current_scope],
            AddressType::SubcmpSignal { cmp_address, .. } => &mem.component_addr_index_mapping[current_scope],
        };

        /*
         * We assume locations are of the form:
         *      (base_offset + (mul_offset * UNKNOWN))
         * So, if we set the unknown value to 0, we will compute the base offset,
         * which will let us look up the range of the underlying array.
         */

        match location {
            LocationRule::Indexed { location, .. } => {

                let (res, _) = interpreter.execute_instruction(location, env.clone());

                let offset = match res {
                    Some(KnownU32(base)) => base,
                    _ => unreachable!(),
                };

                mapping[&offset].clone()
            },
            LocationRule::Mapped { .. } => unreachable!(),
        }
    }

    fn is_location_unknown(&self, address: &AddressType, location: &LocationRule, env: &Env) -> bool {
        let mem = self.memory.borrow();
        let interpreter = mem.build_interpreter(self);

        let resolved_addr = match location {
            LocationRule::Indexed { location, .. } => {
                let (r, acc_env) = interpreter.execute_instruction(location, env.clone(), false);
                r.expect("location must produce a value!")
            },
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

    /**
     * We will replace the previous address of the LoadBucket with the address computed from a function that also checks the bounds.
     *
     */
    fn on_load_bucket(&self, bucket: &LoadBucket, env: &Env) -> bool {
        // println!("load bucket: {:?}", bucket);
        let address = &bucket.address_type;
        let location = &bucket.src;
        if !self.is_location_unknown(address, location, env) {
            true
        } else {
            let index_range = self.find_bounds(address, location, env);
            todo!();
            true
        }
    }

    /**
     * We will replace the previous address of the StoreBucket with the address computed from a function that also checks the bounds.
     */
    fn on_store_bucket(&self, bucket: &StoreBucket, env: &Env) -> bool {
        // println!("store bucket: {:?}", bucket);
        let address = &bucket.dest_address_type;
        let location = &bucket.dest;
        if !self.is_location_unknown(address, location, env) {
            true
        } else {
            let index_range = self.find_bounds(address, location, env);
            todo!();
            true
        }
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
        true
    }

    fn ignore_subcmp_calls(&self) -> bool {
        true
    }
}

impl CircuitTransformationPass for UnknownIndexSanitizationPass {
    fn get_updated_field_constants(&self) -> Vec<String> {
        self.memory.borrow().constant_fields.clone()
    }

    /*
        iangneal: Let the interpreter run to see if we can find any replacements.
        If so, yield the replacement. Else, just give the default transformation
    */
    fn transform_location_rule(&self, location_rule: &LocationRule) -> LocationRule {
        // If the interpreter found a viable transformation, do that.
        if let Some(indexed_rule) = self.replacements.borrow().get(&location_rule) {
            return indexed_rule.clone();
        }
        match location_rule {
            LocationRule::Indexed { location, template_header } => LocationRule::Indexed {
                location: self.transform_instruction(location),
                template_header: template_header.clone(),
            },
            LocationRule::Mapped { .. } => unreachable!()
        }
    }

    fn pre_hook_circuit(&self, circuit: &Circuit) {
        self.memory.borrow_mut().fill_from_circuit(circuit);
    }

    fn pre_hook_template(&self, template: &TemplateCode) {
        self.memory.borrow_mut().set_scope(template);
        self.memory.borrow().run_template(self, template);
    }
}
