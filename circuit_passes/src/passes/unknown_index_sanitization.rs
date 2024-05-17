use std::cell::RefCell;
use std::collections::{BTreeMap, HashSet};
use std::ops::Range;
use compiler::circuit_design::template::TemplateCode;
use compiler::intermediate_representation::{Instruction, InstructionPointer, BucketId};
use compiler::intermediate_representation::ir_interface::*;
use code_producers::llvm_elements::array_switch::{get_array_load_name, get_array_store_name};
use crate::bucket_interpreter::env::Env;
use crate::bucket_interpreter::error::{BadInterp, add_loc_if_err};
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::observer::Observer;
use crate::bucket_interpreter::operations;
use crate::bucket_interpreter::{RC, to_bigint, into_result};
use crate::bucket_interpreter::value::Value::{KnownU32, KnownBigInt};
use crate::{default__name, default__get_mem, default__run_template};
use super::{CircuitTransformationPass, GlobalPassData};

struct ZeroingInterpreter<'a> {
    pub ff_constants: &'a Vec<String>,
    mem: &'a PassMemory,
}

impl<'a> ZeroingInterpreter<'a> {
    pub fn init(mem: &'a PassMemory, ff_constants: &'a Vec<String>) -> Self {
        ZeroingInterpreter { ff_constants, mem }
    }

    pub fn compute_value_bucket(&self, bucket: &ValueBucket, _env: &Env) -> RC {
        Ok(Some(match bucket.parse_as {
            ValueType::U32 => KnownU32(bucket.value),
            ValueType::BigInt => {
                let constant = &self.ff_constants[bucket.value];
                KnownBigInt(add_loc_if_err(to_bigint(constant), bucket)?)
            }
        }))
    }

    pub fn compute_load_bucket(&self, _bucket: &LoadBucket, _env: &Env) -> RC {
        Ok(Some(KnownU32(0)))
    }

    pub fn compute_compute_bucket(&self, bucket: &ComputeBucket, env: &Env) -> RC {
        let mut stack = vec![];
        for i in &bucket.stack {
            let value = self.compute_instruction(i, env)?;
            stack.push(into_result(value, "operand")?);
        }
        // If any value of the stack is unknown we just return 0
        if stack.iter().any(|v| v.is_unknown()) {
            return Ok(Some(KnownU32(0)));
        }
        operations::compute_operation(bucket, &stack, self.mem.get_prime())
    }

    pub fn compute_instruction(&self, inst: &InstructionPointer, env: &Env) -> RC {
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
            memory: PassMemory::new(prime, Default::default()),
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
                let ff_constants = mem.get_ff_constants_clone();
                let interpreter = ZeroingInterpreter::init(mem, &ff_constants);
                let res = interpreter.compute_instruction(location, env)?;

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
    default__get_mem!();
    default__run_template!();

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

    fn transform_bounded_fn(
        &self,
        bucket_id: &BucketId,
        bounded_fn: &Option<String>,
    ) -> Option<String> {
        if let Some(n) = self.bounded_fn_replacements.borrow_mut().remove(bucket_id) {
            return Some(n);
        }
        self.transform_bounded_fn_default(bucket_id, bounded_fn)
    }
}
