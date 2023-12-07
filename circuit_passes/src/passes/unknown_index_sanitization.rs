use std::cell::RefCell;
use std::collections::{BTreeMap, HashSet};
use std::ops::Range;
use compiler::circuit_design::template::TemplateCode;
use compiler::compiler_interface::Circuit;
use compiler::intermediate_representation::{Instruction, InstructionPointer, new_id};
use compiler::intermediate_representation::ir_interface::*;
use compiler::num_bigint::BigInt;
use code_producers::llvm_elements::array_switch::{get_array_load_name, get_array_store_name};
use program_structure::constants::UsefulConstants;
use crate::bucket_interpreter::env::Env;
use crate::bucket_interpreter::error::BadInterp;
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::observer::Observer;
use crate::bucket_interpreter::operations::compute_operation;
use crate::bucket_interpreter::{R, to_bigint, add_loc_if_err, into_result};
use crate::bucket_interpreter::value::Value::{KnownU32, KnownBigInt};
use crate::{
    default__get_updated_field_constants, default__name, default__pre_hook_template,
    default__pre_hook_circuit,
};
use super::{CircuitTransformationPass, GlobalPassData};

struct ZeroingInterpreter<'a> {
    pub constant_fields: &'a Vec<String>,
    p: BigInt,
}

impl<'a> ZeroingInterpreter<'a> {
    pub fn init(prime: &'a String, constant_fields: &'a Vec<String>) -> Self {
        ZeroingInterpreter { constant_fields, p: UsefulConstants::new(prime).get_p().clone() }
    }

    pub fn execute_value_bucket<'env>(&self, bucket: &ValueBucket, env: Env<'env>) -> R<'env> {
        Ok((
            Some(match bucket.parse_as {
                ValueType::U32 => KnownU32(bucket.value),
                ValueType::BigInt => {
                    let constant = &self.constant_fields[bucket.value];
                    KnownBigInt(add_loc_if_err(to_bigint(constant), bucket)?)
                }
            }),
            env,
        ))
    }

    pub fn execute_load_bucket<'env>(&self, _bucket: &'env LoadBucket, env: Env<'env>) -> R<'env> {
        Ok((Some(KnownU32(0)), env))
    }

    pub fn execute_compute_bucket<'env>(
        &self,
        bucket: &'env ComputeBucket,
        env: Env<'env>,
    ) -> R<'env> {
        let mut stack = vec![];
        let mut env = env;
        for i in &bucket.stack {
            let (value, new_env) = self.execute_instruction(i, env)?;
            env = new_env;
            stack.push(into_result(value, "operand")?);
        }
        // If any value of the stack is unknown we just return 0
        if stack.iter().any(|v| v.is_unknown()) {
            return Ok((Some(KnownU32(0)), env));
        }
        compute_operation(bucket, &stack, &self.p).map(|v| (v, env))
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

pub struct UnknownIndexSanitizationPass<'d> {
    global_data: &'d RefCell<GlobalPassData>,
    // Wrapped in a RefCell because the reference to the static analysis is immutable but we need mutability
    memory: PassMemory,
    load_replacements: RefCell<BTreeMap<LoadBucket, Range<usize>>>,
    store_replacements: RefCell<BTreeMap<StoreBucket, Range<usize>>>,
    scheduled_bounded_loads: RefCell<HashSet<Range<usize>>>,
    scheduled_bounded_stores: RefCell<HashSet<Range<usize>>>,
}

/**
 * The goal of this pass is to
 */
impl<'d> UnknownIndexSanitizationPass<'d> {
    pub fn new(prime: String, global_data: &'d RefCell<GlobalPassData>) -> Self {
        UnknownIndexSanitizationPass {
            global_data,
            memory: PassMemory::new(prime, "".to_string(), Default::default()),
            load_replacements: Default::default(),
            store_replacements: Default::default(),
            scheduled_bounded_loads: Default::default(),
            scheduled_bounded_stores: Default::default(),
        }
    }

    fn find_bounds(
        &self,
        address: &AddressType,
        location: &LocationRule,
        env: &Env,
    ) -> Result<Range<usize>, BadInterp> {
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
                let (res, _) = interpreter.execute_instruction(location, env.clone())?;

                let offset = match res {
                    Some(KnownU32(base)) => base,
                    _ => unreachable!(),
                };
                Ok(match address {
                    AddressType::Variable => mem.get_current_scope_variables_index_mapping(&offset),
                    AddressType::Signal => mem.get_current_scope_signal_index_mapping(&offset),
                    AddressType::SubcmpSignal { .. } => {
                        mem.get_current_scope_component_addr_index_mapping(&offset)
                    }
                })
            }
        }
    }

    fn is_location_unknown(
        &self,
        _address: &AddressType,
        location: &LocationRule,
        env: &Env,
    ) -> Result<bool, BadInterp> {
        let resolved_addr = match location {
            LocationRule::Indexed { location, .. } => {
                let mem = &self.memory;
                let interpreter = mem.build_interpreter(self.global_data, self);
                let (r, _) = interpreter.execute_instruction(location, env.clone(), false)?;
                into_result(r, "indexed location")?
            }
            LocationRule::Mapped { .. } => unreachable!(),
        };
        Ok(resolved_addr.is_unknown())
    }
}

/**
 * The goal is to replace:
 * - loads with a function call that returns the loaded value
 * - stores with a function call that performs the store
 */
impl Observer<Env<'_>> for UnknownIndexSanitizationPass<'_> {
    fn on_load_bucket(&self, bucket: &LoadBucket, env: &Env) -> Result<bool, BadInterp> {
        let address = &bucket.address_type;
        let location = &bucket.src;
        if self.is_location_unknown(address, location, env)? {
            let index_range = self.find_bounds(address, location, env)?;
            self.load_replacements.borrow_mut().insert(bucket.clone(), index_range.clone());
            self.scheduled_bounded_loads.borrow_mut().insert(index_range);
        }
        Ok(true)
    }

    fn on_store_bucket(&self, bucket: &StoreBucket, env: &Env) -> Result<bool, BadInterp> {
        let address = &bucket.dest_address_type;
        let location = &bucket.dest;
        if self.is_location_unknown(address, location, env)? {
            let index_range = self.find_bounds(address, location, env)?;
            self.store_replacements.borrow_mut().insert(bucket.clone(), index_range.clone());
            self.scheduled_bounded_stores.borrow_mut().insert(index_range);
        }
        Ok(true)
    }

    fn ignore_function_calls(&self) -> bool {
        false
    }

    fn ignore_subcmp_calls(&self) -> bool {
        false
    }

    fn ignore_extracted_function_calls(&self) -> bool {
        true
    }
}

fn do_array_union(a: &HashSet<Range<usize>>, b: &HashSet<Range<usize>>) -> HashSet<Range<usize>> {
    a.union(b).cloned().collect()
}

impl CircuitTransformationPass for UnknownIndexSanitizationPass<'_> {
    default__name!("UnknownIndexSanitizationPass");
    default__get_updated_field_constants!();
    default__pre_hook_circuit!();
    default__pre_hook_template!();

    fn get_updated_bounded_array_loads(
        &self,
        old_array_loads: &HashSet<Range<usize>>,
    ) -> HashSet<Range<usize>> {
        do_array_union(old_array_loads, &self.scheduled_bounded_loads.borrow())
    }

    fn get_updated_bounded_array_stores(
        &self,
        old_array_stores: &HashSet<Range<usize>>,
    ) -> HashSet<Range<usize>> {
        do_array_union(old_array_stores, &self.scheduled_bounded_stores.borrow())
    }

    fn transform_load_bucket(&self, bucket: &LoadBucket) -> Result<InstructionPointer, BadInterp> {
        let bounded_fn_symbol = match self.load_replacements.borrow().get(bucket) {
            Some(index_range) => Some(get_array_load_name(index_range)),
            None => bucket.bounded_fn.clone(),
        };
        Ok(LoadBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id.clone(),
            line: bucket.line,
            message_id: bucket.message_id,
            address_type: self.transform_address_type(&bucket.address_type)?,
            src: self.transform_location_rule(&bucket.id, &bucket.src)?,
            bounded_fn: bounded_fn_symbol,
        }
        .allocate())
    }

    fn transform_store_bucket(
        &self,
        bucket: &StoreBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        let bounded_fn_symbol = match self.store_replacements.borrow().get(bucket) {
            Some(index_range) => Some(get_array_store_name(index_range)),
            None => bucket.bounded_fn.clone(),
        };
        Ok(StoreBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id.clone(),
            line: bucket.line,
            message_id: bucket.message_id,
            context: bucket.context.clone(),
            dest_is_output: bucket.dest_is_output,
            dest_address_type: self.transform_address_type(&bucket.dest_address_type)?,
            dest: self.transform_location_rule(&bucket.id, &bucket.dest)?,
            src: self.transform_instruction(&bucket.src)?,
            bounded_fn: bounded_fn_symbol,
        }
        .allocate())
    }
}
