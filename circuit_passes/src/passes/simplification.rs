use std::cell::RefCell;
use std::collections::HashMap;
use compiler::circuit_design::template::TemplateCode;
use compiler::intermediate_representation::{new_id, BucketId, InstructionPointer};
use compiler::intermediate_representation::ir_interface::*;
use crate::bucket_interpreter::{operations, result_types, BucketInterpreter, InterpreterFlags};
use crate::bucket_interpreter::env::Env;
use crate::bucket_interpreter::error::BadInterp;
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::observer::Observer;
use crate::bucket_interpreter::value::Value;
use crate::passes::builders::build_compute;
use crate::{default__get_mem, default__name, default__run_template};
use super::{CircuitTransformationPass, GlobalPassData};

pub struct SimplificationPass<'d> {
    // Wrapped in a RefCell because the reference to the static analysis is immutable but we need mutability
    global_data: &'d RefCell<GlobalPassData>,
    memory: PassMemory,
    within_constraint: RefCell<bool>,
    compute_replacements: RefCell<HashMap<BucketId, Option<Value>>>,
    call_replacements: RefCell<HashMap<BucketId, Option<Value>>>,
    constraint_eq_replacements: RefCell<HashMap<BucketId, Option<Vec<Value>>>>,
    constraint_sub_replacements: RefCell<HashMap<BucketId, Option<(Value, Value, Value)>>>,
}

impl<'d> SimplificationPass<'d> {
    pub fn new(prime: String, global_data: &'d RefCell<GlobalPassData>) -> Self {
        SimplificationPass {
            global_data,
            memory: PassMemory::new(prime),
            within_constraint: Default::default(),
            compute_replacements: Default::default(),
            call_replacements: Default::default(),
            constraint_eq_replacements: Default::default(),
            constraint_sub_replacements: Default::default(),
        }
    }

    fn build_interpreter(&self) -> BucketInterpreter {
        self.memory.build_interpreter_with_flags(
            self.global_data,
            self,
            InterpreterFlags {
                all_signals_unknown: self.within_constraint.borrow().to_owned(),
                ..Default::default()
            },
        )
    }

    #[inline]
    fn compute_known(&self, bucket: &ComputeBucket, stack: &Vec<Value>) -> Option<Value> {
        if let Ok(Some(v)) = operations::compute_operation(bucket, stack, self.memory.get_prime()) {
            if v.is_known() {
                return Some(v);
            }
        }
        None
    }

    #[inline]
    fn insert<V: PartialEq>(
        map: &RefCell<HashMap<BucketId, Option<V>>>,
        bucket_id: BucketId,
        new_val: Option<V>,
    ) {
        map.borrow_mut()
            .entry(bucket_id)
            // If the entry exists and it's not the same as the new value,
            //  or the new value itself is None, then set to result to None
            //  to indicate that no replacement should be made.
            .and_modify(|old| {
                if let Some(old_val) = old {
                    match &new_val {
                        None => *old = None,
                        Some(x) => {
                            if *x != *old_val {
                                *old = None
                            }
                        }
                    }
                }
            })
            // If no entry exists, store the new value.
            .or_insert(new_val);
    }

    fn store_computed_value(
        map: &RefCell<HashMap<BucketId, Option<Value>>>,
        bucket_id: BucketId,
        computed_value: Value,
    ) -> Result<bool, BadInterp> {
        if computed_value.is_unknown() {
            // When the bucket's value is Unknown from any execution, add None to the map so
            //  the bucket will not be replaced (even if known at an execution found later),
            //  return 'true' so buckets nested within this bucket will be observed.
            Self::insert(map, bucket_id, None);
            Ok(true)
        } else {
            // Add known value to the map, return 'false' so observation will not continue within.
            Self::insert(map, bucket_id, Some(computed_value));
            Ok(false)
        }
    }
}

impl Observer<Env<'_>> for SimplificationPass<'_> {
    fn on_compute_bucket(&self, bucket: &ComputeBucket, env: &Env) -> Result<bool, BadInterp> {
        let interp = self.build_interpreter();
        let v = interp.compute_compute_bucket(bucket, env, false)?;
        let v = result_types::into_single_result(v, "ComputeBucket")?;
        Self::store_computed_value(&self.compute_replacements, bucket.id, v)
    }

    fn on_call_bucket(&self, bucket: &CallBucket, env: &Env) -> Result<bool, BadInterp> {
        let interp = self.build_interpreter();
        let v = interp.compute_call_bucket(bucket, env, false)?;
        // CallBucket may not return a value directly so use 'into_single_option()'
        //  rather than 'into_single_result()' and return 'true' in the None case
        //  so buckets nested within this bucket will be observed.
        if let Some(v) = result_types::into_single_option(v) {
            Self::store_computed_value(&self.call_replacements, bucket.id, v)
        } else {
            Ok(true)
        }
    }

    fn on_constraint_bucket(
        &self,
        bucket: &ConstraintBucket,
        env: &Env,
    ) -> Result<bool, BadInterp> {
        self.within_constraint.replace(true);
        // Match the expected structure of ConstraintBucket instances
        //  but don't fail if there's something different.
        match bucket {
            ConstraintBucket::Equality(e) => {
                if let Instruction::Assert(AssertBucket { evaluate, .. }) = e.as_ref() {
                    if let Instruction::Compute(ComputeBucket { stack, .. }) = evaluate.as_ref() {
                        // Compute Value for each instruction on the stack and store it
                        let mut values = Vec::with_capacity(stack.len());
                        let interp = self.build_interpreter();
                        for inst in stack {
                            // Leave this Observer enabled so that ComputeBucket w/in the RHS expression
                            //  could be simplified even if the entire expression will not be simplified.
                            let v = interp.compute_instruction(inst, env, true)?;
                            let v = result_types::into_single_result(v, "operand of compute")?;
                            values.push(v);
                        }
                        // If at least one is a known value, then we can (likely) simplify
                        if values.iter().any(Value::is_known) {
                            Self::insert(
                                &self.constraint_eq_replacements,
                                e.get_id(),
                                Some(values),
                            );
                        }
                    }
                }
            }
            ConstraintBucket::Substitution(e) => {
                if let Instruction::Store(bucket) = e.as_ref() {
                    // Check the context size to only simplify scalar stores.
                    if bucket.context.size <= 1 {
                        // Interpret the RHS expression, treating all signals as unknown to ensure they are preserved.
                        let src = {
                            let interp = self.build_interpreter();
                            // Leave this Observer enabled so that ComputeBucket w/in the RHS expression
                            //  could be simplified even if the entire expression will not be simplified.
                            let v = interp.compute_instruction(&bucket.src, env, true)?;
                            result_types::into_single_result(v, "source of store")?
                        };

                        // Interpret the LHS memory reference
                        let interp = self.build_interpreter();
                        let dest = interp.compute_location_index(
                            &bucket.dest,
                            &bucket.id,
                            env,
                            false,
                            "store source value",
                        )?;
                        let dest_address_type =
                            if let AddressType::SubcmpSignal { cmp_address, .. } =
                                &bucket.dest_address_type
                            {
                                let v = interp.compute_instruction(cmp_address, env, false)?;
                                result_types::into_single_result(v, "source of store")?
                            } else {
                                Value::Unknown
                            };

                        // If at least one is a known value, then we can (likely) simplify
                        if src.is_known() || dest.is_known() || dest_address_type.is_known() {
                            Self::insert(
                                &self.constraint_sub_replacements,
                                e.get_id(),
                                Some((src, dest, dest_address_type)),
                            );
                        }
                    }
                }
            }
        }
        self.within_constraint.replace(false);
        Ok(false) // always return false because nothing else within needs to be checked
    }

    fn ignore_function_calls(&self) -> bool {
        false
    }

    fn ignore_extracted_function_calls(&self) -> bool {
        false
    }
}

impl CircuitTransformationPass for SimplificationPass<'_> {
    default__name!("SimplificationPass");
    default__get_mem!();
    default__run_template!();

    fn transform_compute_bucket(
        &self,
        bucket: &ComputeBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        if let Some(Some(value)) = self.compute_replacements.borrow().get(&bucket.id) {
            return value.to_value_bucket(&self.memory).map(Allocate::allocate);
        }
        self.transform_compute_bucket_default(bucket)
    }

    fn transform_call_bucket(&self, bucket: &CallBucket) -> Result<InstructionPointer, BadInterp> {
        if let Some(Some(value)) = self.call_replacements.borrow().get(&bucket.id) {
            return value.to_value_bucket(&self.memory).map(Allocate::allocate);
        }
        self.transform_call_bucket_default(bucket)
    }

    fn transform_substitution_constraint(
        &self,
        i: &InstructionPointer,
    ) -> Result<InstructionPointer, BadInterp> {
        if let Some(Some((s, d, cmp))) = self.constraint_sub_replacements.borrow().get(&i.get_id())
        {
            if let Instruction::Store(store_bucket) = i.as_ref() {
                let dest_address_type = if cmp.is_unknown() {
                    //implementation from 'transform_store_bucket_default'
                    self.transform_address_type(&store_bucket.dest_address_type)?
                } else {
                    let address = &store_bucket.dest_address_type;
                    match address {
                        AddressType::SubcmpSignal {
                            uniform_parallel_value,
                            is_output,
                            input_information,
                            counter_override,
                            ..
                        } => AddressType::SubcmpSignal {
                            cmp_address: cmp.to_value_bucket(&self.memory)?.allocate(),
                            uniform_parallel_value: uniform_parallel_value.clone(),
                            is_output: *is_output,
                            input_information: self
                                .transform_subcmp_input_information(address, input_information),
                            counter_override: *counter_override,
                        },
                        _ => unreachable!(),
                    }
                };
                let dest = if d.is_unknown() {
                    //implementation from 'transform_store_bucket_default'
                    self.transform_location_rule(&store_bucket.id, &store_bucket.dest)?
                } else {
                    LocationRule::Indexed {
                        location: d.to_value_bucket(&self.memory)?.allocate(),
                        template_header: match &store_bucket.dest {
                            LocationRule::Indexed { template_header, .. } => {
                                template_header.clone()
                            }
                            LocationRule::Mapped { .. } => None,
                        },
                    }
                };
                let src = if s.is_unknown() {
                    //implementation from 'transform_store_bucket_default'
                    self.transform_instruction(&store_bucket.src)?
                } else {
                    s.to_value_bucket(&self.memory)?.allocate()
                };
                return Ok(StoreBucket {
                    id: new_id(),
                    source_file_id: store_bucket.source_file_id,
                    line: store_bucket.line,
                    message_id: store_bucket.message_id,
                    context: store_bucket.context.clone(),
                    dest_is_output: store_bucket.dest_is_output,
                    dest_address_type,
                    dest,
                    src,
                    bounded_fn: self
                        .transform_bounded_fn(&store_bucket.id, &store_bucket.bounded_fn),
                }
                .allocate());
            } else {
                unreachable!()
            }
        }
        self.transform_substitution_constraint_default(i)
    }

    fn transform_equality_constraint(
        &self,
        i: &InstructionPointer,
    ) -> Result<InstructionPointer, BadInterp> {
        if let Some(Some(ops)) = self.constraint_eq_replacements.borrow().get(&i.get_id()) {
            if let Instruction::Assert(assert_bucket) = i.as_ref() {
                if let Instruction::Compute(compute_bucket) = assert_bucket.evaluate.as_ref() {
                    // If the compute operator with the stack of Values computes to a single
                    //  Value, then use that value inside the assert bucket. Otherwise, create
                    //  a new compute bucket with the operands simplified when possible.
                    let evaluate = if let Some(val) = self.compute_known(compute_bucket, ops) {
                        val.to_value_bucket(&self.memory)?.allocate()
                    } else {
                        assert_eq!(ops.len(), compute_bucket.stack.len());
                        let mut stack = Vec::with_capacity(ops.len());
                        for (eval, orig) in ops.iter().zip(compute_bucket.stack.iter()) {
                            let expr = if eval.is_unknown() {
                                //implementation from 'transform_compute_bucket_default'
                                self.transform_instruction(orig)?
                            } else {
                                eval.to_value_bucket(&self.memory)?.allocate()
                            };
                            stack.push(expr);
                        }
                        build_compute(
                            compute_bucket,
                            compute_bucket.op,
                            compute_bucket.op_aux_no,
                            stack,
                        )
                    };
                    return Ok(AssertBucket {
                        id: new_id(),
                        source_file_id: assert_bucket.source_file_id,
                        line: assert_bucket.line,
                        message_id: assert_bucket.message_id,
                        evaluate,
                    }
                    .allocate());
                }
            }
            unreachable!()
        }
        self.transform_equality_constraint_default(i)
    }
}
