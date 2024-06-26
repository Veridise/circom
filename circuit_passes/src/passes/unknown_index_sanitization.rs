use std::cell::RefCell;
use std::collections::{BTreeMap, HashSet};
use std::ops::Range;
use compiler::circuit_design::template::TemplateCode;
use compiler::intermediate_representation::{Instruction, InstructionPointer, BucketId};
use compiler::intermediate_representation::ir_interface::*;
use code_producers::llvm_elements::array_switch::{get_array_load_name, get_array_store_name};
use code_producers::llvm_elements::BoundedArrays;
use crate::bucket_interpreter::{to_bigint, operations};
use crate::bucket_interpreter::env::Env;
use crate::bucket_interpreter::error::BadInterp;
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::observer::Observer;
use crate::bucket_interpreter::result_types::{InterpRes, RCI};
use crate::bucket_interpreter::value::Value::{self, KnownBigInt, KnownU32};
use crate::{check_res, default__get_mem, default__name, default__run_template};
use super::{CircuitTransformationPass, GlobalPassData};

struct ZeroingInterpreter<'a> {
    mem: &'a PassMemory,
}

impl<'a> ZeroingInterpreter<'a> {
    pub fn init(mem: &'a PassMemory) -> Self {
        ZeroingInterpreter { mem }
    }

    pub fn compute_value_bucket(&self, bucket: &ValueBucket, _env: &Env) -> RCI {
        match bucket.parse_as {
            ValueType::U32 => InterpRes::Continue(Some(KnownU32(bucket.value))),
            ValueType::BigInt => {
                let constant = &self.mem.get_ff_constant(bucket.value);
                to_bigint(constant).add_loc_if_err(bucket).map(|r| Some(KnownBigInt(r)))
            }
        }
    }

    pub fn compute_load_bucket(&self, _bucket: &LoadBucket, _env: &Env) -> RCI {
        InterpRes::Continue(Some(KnownU32(0)))
    }

    pub fn compute_compute_bucket(&self, bucket: &ComputeBucket, env: &Env) -> RCI {
        let mut stack: Vec<Value> = Vec::with_capacity(bucket.stack.len());
        for i in &bucket.stack {
            let value = check_res!(self.compute_instruction(i, env).expect_some("operand"));
            stack.push(value.unwrap());
        }
        // If any value of the stack is unknown we just return 0
        if stack.iter().any(|v| v.is_unknown()) {
            InterpRes::Continue(Some(KnownU32(0)))
        } else {
            InterpRes::try_continue(operations::compute_operation(
                bucket,
                &stack,
                self.mem.get_prime(),
            ))
        }
    }

    pub fn compute_instruction(&self, inst: &InstructionPointer, env: &Env) -> RCI {
        match inst.as_ref() {
            Instruction::Value(b) => self.compute_value_bucket(b, env),
            Instruction::Load(b) => self.compute_load_bucket(b, env),
            Instruction::Compute(b) => self.compute_compute_bucket(b, env),
            _ => unreachable!(),
        }
    }
}

pub struct UnknownIndexSanitizationPass<'d> {
    // Wrapped in a RefCell because the reference to the static analysis is immutable but we need mutability
    global_data: &'d RefCell<GlobalPassData>,
    memory: PassMemory,
    bounded_fn_replacements: RefCell<BTreeMap<BucketId, String>>,
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
            memory: PassMemory::new(prime),
            bounded_fn_replacements: Default::default(),
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
                let interpreter = ZeroingInterpreter::init(mem);
                let res = Result::from(interpreter.compute_instruction(location, env))?;
                let offset = match res {
                    Some(KnownU32(base)) => base,
                    _ => unreachable!(),
                };
                Ok(match address {
                    AddressType::Variable => mem.get_current_scope_variable_index_mapping(&offset),
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
        location: &LocationRule,
        location_owner: &BucketId,
        env: &Env,
    ) -> Result<bool, BadInterp> {
        let interpreter = self.memory.build_interpreter(self.global_data, self);
        interpreter
            .compute_location_index(location, location_owner, env, false, "indexed location")
            .map(|v| v.is_unknown())
    }
}

/**
 * The goal is to replace:
 * - loads with a function call that returns the loaded value
 * - stores with a function call that performs the store
 */
impl Observer<Env<'_>> for UnknownIndexSanitizationPass<'_> {
    fn on_load_bucket(&self, bucket: &LoadBucket, env: &Env) -> Result<bool, BadInterp> {
        let location = &bucket.src;
        if self.is_location_unknown(location, &bucket.id, env)? {
            let address = &bucket.address_type;
            let index_range = self.find_bounds(address, location, env)?;
            self.bounded_fn_replacements
                .borrow_mut()
                .insert(bucket.id, get_array_load_name(&index_range));
            self.scheduled_bounded_loads.borrow_mut().insert(index_range);
        }
        Ok(true)
    }

    fn on_store_bucket(&self, bucket: &StoreBucket, env: &Env) -> Result<bool, BadInterp> {
        let location = &bucket.dest;
        if self.is_location_unknown(location, &bucket.id, env)? {
            let address = &bucket.dest_address_type;
            let index_range = self.find_bounds(address, location, env)?;
            self.bounded_fn_replacements
                .borrow_mut()
                .insert(bucket.id, get_array_store_name(&index_range));
            self.scheduled_bounded_stores.borrow_mut().insert(index_range);
        }
        Ok(true)
    }

    fn ignore_function_calls(&self) -> bool {
        false
    }

    fn ignore_extracted_function_calls(&self) -> bool {
        true
    }
}

impl CircuitTransformationPass for UnknownIndexSanitizationPass<'_> {
    default__name!("UnknownIndexSanitizationPass");
    default__get_mem!();
    default__run_template!();

    fn update_bounded_arrays(&self, bounded_arrays: &mut BoundedArrays) {
        bounded_arrays.loads.extend(self.scheduled_bounded_loads.take().into_iter());
        bounded_arrays.stores.extend(self.scheduled_bounded_stores.take().into_iter());
    }

    fn transform_bounded_fn(
        &self,
        bucket_id: &BucketId,
        bounded_fn: &Option<String>,
    ) -> Option<String> {
        match self.bounded_fn_replacements.borrow_mut().remove(bucket_id) {
            None => self.transform_bounded_fn_default(bucket_id, bounded_fn),
            s => s,
        }
    }
}
