pub mod value;
pub mod env;
pub mod error;
pub mod memory;
pub mod observer;
pub mod observed_visitor;
pub(crate) mod operations;

use std::cell::RefCell;
use std::vec;
use code_producers::llvm_elements::fr::{FR_IDENTITY_ARR_PTR, FR_INDEX_ARR_PTR};
use code_producers::llvm_elements::stdlib::GENERATED_FN_PREFIX;
use compiler::intermediate_representation::{Instruction, InstructionList, InstructionPointer};
use compiler::intermediate_representation::ir_interface::*;
use compiler::num_bigint::BigInt;
use observer::Observer;
use program_structure::constants::UsefulConstants;
use program_structure::error_code::ReportCode;
use crate::passes::loop_unroll::LOOP_BODY_FN_PREFIX;
use crate::passes::GlobalPassData;
use self::env::{Env, LibraryAccess};
use self::error::{BadInterp, new_compute_err, add_loc_if_err, new_compute_err_result};
use self::memory::PassMemory;
use self::operations::compute_offset;
use self::value::Value::{self, KnownBigInt, KnownU32, Unknown};

pub struct BucketInterpreter<'a, 'd> {
    global_data: &'d RefCell<GlobalPassData>,
    observer: &'a dyn for<'e> Observer<Env<'e>>,
    mem: &'a PassMemory,
    scope: String,
    p: BigInt,
}

pub type RE<'e> = Result<(Option<Value>, Env<'e>), BadInterp>;
pub type RC = Result<Option<Value>, BadInterp>;

#[inline]
pub fn into_result<D, S: std::fmt::Display>(v: Option<D>, label: S) -> Result<D, BadInterp> {
    v.ok_or_else(|| new_compute_err(format!("Could not compute {}!", label)))
}

#[inline]
pub fn to_bigint(constant: &String) -> Result<BigInt, BadInterp> {
    BigInt::parse_bytes(constant.as_bytes(), 10)
        .ok_or_else(|| new_compute_err(format!("Cannot parse constant: {}", constant)))
}

impl<'a: 'd, 'd> BucketInterpreter<'a, 'd> {
    /****************************************************************************************************
     * Public interface
     * The public "execute*bucket" functions ensure that the source location information is added
     * to the error report whenever the return value is the Err kind.
     ****************************************************************************************************/
    pub fn init(
        global_data: &'d RefCell<GlobalPassData>,
        observer: &'a dyn for<'e> Observer<Env<'e>>,
        mem: &'a PassMemory,
        scope: String,
    ) -> Self {
        BucketInterpreter {
            global_data,
            observer,
            mem,
            scope,
            p: UsefulConstants::new(mem.get_prime()).get_p().clone(),
        }
    }

    pub fn execute_value_bucket<'env>(
        &self,
        bucket: &ValueBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        add_loc_if_err(self._execute_value_bucket(bucket, env, observe), bucket)
    }

    pub fn execute_load_bucket<'env>(
        &self,
        bucket: &'env LoadBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        add_loc_if_err(self._execute_load_bucket(bucket, env, observe), bucket)
    }

    pub fn execute_store_bucket<'env>(
        &self,
        bucket: &'env StoreBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        add_loc_if_err(self._execute_store_bucket(bucket, env, observe), bucket)
    }

    pub fn execute_compute_bucket<'env>(
        &self,
        bucket: &'env ComputeBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        add_loc_if_err(self._execute_compute_bucket(bucket, env, observe), bucket)
    }

    pub fn execute_call_bucket<'env>(
        &self,
        bucket: &'env CallBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        add_loc_if_err(self._execute_call_bucket(bucket, env, observe), bucket)
    }

    pub fn execute_branch_bucket<'env>(
        &self,
        bucket: &'env BranchBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        add_loc_if_err(self._execute_branch_bucket(bucket, env, observe), bucket)
    }

    pub fn execute_return_bucket<'env>(
        &self,
        bucket: &'env ReturnBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        add_loc_if_err(self._execute_return_bucket(bucket, env, observe), bucket)
    }

    pub fn execute_assert_bucket<'env>(
        &self,
        bucket: &'env AssertBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        add_loc_if_err(self._execute_assert_bucket(bucket, env, observe), bucket)
    }

    pub fn execute_log_bucket<'env>(
        &self,
        bucket: &'env LogBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        add_loc_if_err(self._execute_log_bucket(bucket, env, observe), bucket)
    }

    pub fn execute_loop_bucket_once<'env>(
        &self,
        bucket: &'env LoopBucket,
        env: Env<'env>,
        observe: bool,
    ) -> Result<(Option<Value>, Option<bool>, Env<'env>), BadInterp> {
        add_loc_if_err(
            self._execute_conditional_bucket(
                &bucket.continue_condition,
                &bucket.body,
                &[],
                env,
                observe,
            ),
            bucket,
        )
    }

    /// Executes the loop many times. If the result of the loop condition is unknown
    /// the interpreter assumes that the result of the loop is `Unknown`.
    /// In the case the condition evaluates to `Unknown` all the memory addresses
    /// potentially written into in the loop's body are set to `Unknown` to represent
    /// that we don't know the values after the execution of that loop.
    pub fn execute_loop_bucket<'env>(
        &self,
        bucket: &'env LoopBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        add_loc_if_err(self._execute_loop_bucket(bucket, env, observe), bucket)
    }

    pub fn execute_create_cmp_bucket<'env>(
        &self,
        bucket: &'env CreateCmpBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        add_loc_if_err(self._execute_create_cmp_bucket(bucket, env, observe), bucket)
    }

    pub fn execute_constraint_bucket<'env>(
        &self,
        bucket: &'env ConstraintBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        add_loc_if_err(self._execute_constraint_bucket(bucket, env, observe), bucket)
    }

    pub fn execute_block_bucket<'env>(
        &self,
        bucket: &'env BlockBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        add_loc_if_err(self._execute_block_bucket(bucket, env, observe), bucket)
    }

    pub fn execute_nop_bucket<'env>(
        &self,
        bucket: &NopBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        add_loc_if_err(self._execute_nop_bucket(bucket, env, observe), bucket)
    }

    pub fn execute_instruction<'env>(
        &self,
        inst: &'env InstructionPointer,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        add_loc_if_err(self._execute_instruction(inst, env, observe), inst.as_ref())
    }

    pub fn execute_instructions<'env>(
        &self,
        instructions: &'env [InstructionPointer],
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        let mut last = (None, env);
        for inst in instructions {
            last = self.execute_instruction(inst, last.1, observe)?;
        }
        Ok(last)
    }

    pub fn compute_compute_bucket(&self, bucket: &ComputeBucket, env: &Env, observe: bool) -> RC {
        add_loc_if_err(self._compute_compute_bucket(bucket, env, observe), bucket)
    }

    pub fn compute_condition(
        &self,
        cond: &InstructionPointer,
        env: &Env,
        observe: bool,
    ) -> Result<Option<bool>, BadInterp> {
        add_loc_if_err(self._compute_condition(cond, env, observe), cond.as_ref())
    }

    pub fn compute_instruction(&self, inst: &InstructionPointer, env: &Env, observe: bool) -> RC {
        add_loc_if_err(self._compute_instruction(inst, env, observe), inst.as_ref())
    }

    /****************************************************************************************************
     * Private implemenation
     * Allows any number of calls to the internal "_execute*bucket" functions without adding source
     * location information to the possible error report returned.
     ****************************************************************************************************/

    fn get_index_from_location(
        &self,
        location: &LocationRule,
        env: &Env,
    ) -> Result<usize, BadInterp> {
        match location {
            LocationRule::Indexed { location, .. } => {
                let idx = self.compute_instruction(location, env, false)?;
                Value::into_u32_result(idx, "index of location")
            }
            LocationRule::Mapped { .. } => unreachable!(),
        }
    }

    fn get_write_operations_in_store_bucket(
        &self,
        bucket: &StoreBucket,
        vars: &mut Vec<usize>,
        signals: &mut Vec<usize>,
        subcmps: &mut Vec<usize>,
        env: &Env,
    ) -> Result<(), BadInterp> {
        let idx = add_loc_if_err(self.get_index_from_location(&bucket.dest, env), bucket)?;
        match bucket.dest_address_type {
            AddressType::Variable => {
                for index in self.mem.get_variables_index_mapping(&self.scope, &idx) {
                    vars.push(index);
                }
            }
            AddressType::Signal => {
                for index in self.mem.get_signal_index_mapping(&self.scope, &idx) {
                    signals.push(index);
                }
            }
            AddressType::SubcmpSignal { .. } => {
                for index in self.mem.get_component_addr_index_mapping(&self.scope, &idx) {
                    subcmps.push(index);
                }
            }
        };
        Ok(())
    }

    fn get_write_operations_in_inst_rec(
        &self,
        inst: &Instruction,
        vars: &mut Vec<usize>,
        signals: &mut Vec<usize>,
        subcmps: &mut Vec<usize>,
        env: &Env,
    ) -> Result<(), BadInterp> {
        match inst {
            Instruction::Value(_) => {} // Cannot write
            Instruction::Load(_) => {}  // Should not have a StoreBucket inside
            Instruction::Store(bucket) => {
                self.get_write_operations_in_store_bucket(bucket, vars, signals, subcmps, env)?
            }
            Instruction::Compute(_) => {} // Should not have a StoreBucket inside
            Instruction::Call(_) => {}    // Should not have a StoreBucket as argument
            Instruction::Branch(bucket) => {
                self.get_write_operations_in_body_rec(
                    &bucket.if_branch,
                    vars,
                    signals,
                    subcmps,
                    env,
                )?;
                self.get_write_operations_in_body_rec(
                    &bucket.else_branch,
                    vars,
                    signals,
                    subcmps,
                    env,
                )?;
            }
            Instruction::Return(_) => {} // Should not have a StoreBucket in the return expression
            Instruction::Assert(_) => {} // Should not have a StoreBucket inside
            Instruction::Log(_) => {}    // Should not have a StoreBucket inside
            Instruction::Loop(bucket) => {
                self.get_write_operations_in_body_rec(&bucket.body, vars, signals, subcmps, env)?
            }
            Instruction::CreateCmp(_) => {} // Should not have a StoreBucket inside
            Instruction::Constraint(bucket) => self.get_write_operations_in_inst_rec(
                match bucket {
                    ConstraintBucket::Substitution(i) => i,
                    ConstraintBucket::Equality(i) => i,
                },
                vars,
                signals,
                subcmps,
                env,
            )?,
            Instruction::Block(bucket) => {
                self.get_write_operations_in_body_rec(&bucket.body, vars, signals, subcmps, env)?
            }
            Instruction::Nop(_) => {} // Should not have a StoreBucket inside
        };
        Ok(())
    }

    fn get_write_operations_in_body_rec(
        &self,
        body: &InstructionList,
        vars: &mut Vec<usize>,
        signals: &mut Vec<usize>,
        subcmps: &mut Vec<usize>,
        env: &Env,
    ) -> Result<(), BadInterp> {
        for inst in body {
            self.get_write_operations_in_inst_rec(inst, vars, signals, subcmps, env)?;
        }
        Ok(())
    }

    /// Returns a triple with a list of indices for each
    /// 0: Indices of variables
    /// 1: Indices of signals
    /// 2: Indices of subcmps
    fn get_write_operations_in_body(
        &self,
        body: &InstructionList,
        env: &Env,
    ) -> Result<(Vec<usize>, Vec<usize>, Vec<usize>), BadInterp> {
        let mut vars = vec![];
        let mut signals = vec![];
        let mut subcmps = vec![];

        self.get_write_operations_in_body_rec(body, &mut vars, &mut signals, &mut subcmps, env)?;

        Ok((vars, signals, subcmps))
    }

    fn _compute_value_bucket(&self, bucket: &ValueBucket, _: &Env, _: bool) -> RC {
        Ok(Some(match bucket.parse_as {
            ValueType::U32 => KnownU32(bucket.value),
            ValueType::BigInt => {
                let constant = &self.mem.get_field_constant(bucket.value);
                KnownBigInt(add_loc_if_err(to_bigint(constant), bucket)?)
            }
        }))
    }

    fn _execute_value_bucket<'env>(
        &self,
        bucket: &ValueBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        self._compute_value_bucket(bucket, &env, observe).map(|r| (r, env))
    }

    fn _compute_load_bucket(&self, bucket: &LoadBucket, env: &Env, observe: bool) -> RC {
        match &bucket.address_type {
            AddressType::Variable => {
                let continue_observing =
                    if observe { self.observer.on_location_rule(&bucket.src, env)? } else { false };
                let idx = match &bucket.src {
                    LocationRule::Indexed { location, .. } => {
                        self._compute_instruction(location, env, continue_observing)?
                    }
                    LocationRule::Mapped { .. } => unreachable!(),
                };
                let idx = into_result(idx, "load source variable")?;
                if idx.is_unknown() {
                    Ok(Some(Unknown))
                } else {
                    Ok(Some(env.get_var(idx.get_u32()?)))
                }
            }
            AddressType::Signal => {
                let continue_observing = if observe {
                    self.observer.on_location_rule(&bucket.src, &env)?
                } else {
                    false
                };
                let idx = match &bucket.src {
                    LocationRule::Indexed { location, .. } => {
                        self._compute_instruction(location, env, continue_observing)?
                    }
                    LocationRule::Mapped { .. } => unreachable!(),
                };
                let idx = into_result(idx, "load source signal")?;
                if idx.is_unknown() {
                    Ok(Some(Unknown))
                } else {
                    Ok(Some(env.get_signal(idx.get_u32()?)))
                }
            }
            AddressType::SubcmpSignal { cmp_address, .. } => {
                let addr = self._compute_instruction(cmp_address, env, observe)?;
                let addr = Value::into_u32_result(addr, "load source subcomponent")?;
                let continue_observing = if observe {
                    self.observer.on_location_rule(&bucket.src, &env)?
                } else {
                    false
                };
                let idx = match &bucket.src {
                    LocationRule::Indexed { location, .. } => {
                        let i = self._compute_instruction(location, env, continue_observing)?;
                        Value::into_u32_result(i, "load source subcomponent indexed signal")?
                    }
                    LocationRule::Mapped { signal_code, indexes } => {
                        let io_def =
                            self.mem.get_iodef(&env.get_subcmp_template_id(addr), signal_code);
                        if indexes.len() > 0 {
                            let mut indexes_values = vec![];
                            for i in indexes {
                                let val = self._compute_instruction(i, env, continue_observing)?;
                                indexes_values.push(Value::into_u32_result(
                                    val,
                                    "load source subcomponent mapped signal",
                                )?);
                            }
                            io_def.offset + compute_offset(&indexes_values, &io_def.lengths)?
                        } else {
                            io_def.offset
                        }
                    }
                };
                Ok(Some(env.get_subcmp_signal(addr, idx)))
            }
        }
    }

    fn _execute_load_bucket<'env>(
        &self,
        bucket: &LoadBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        self._compute_load_bucket(bucket, &env, observe).map(|r| (r, env))
    }

    fn store_value_in_address<'env>(
        &self,
        address: &'env AddressType,
        location: &'env LocationRule,
        value: Value,
        env: Env<'env>,
        observe: bool,
    ) -> Result<Env<'env>, BadInterp> {
        match address {
            AddressType::Variable => {
                let continue_observing =
                    if observe { self.observer.on_location_rule(location, &env)? } else { false };
                let (idx, env) = match location {
                    LocationRule::Indexed { location, .. } => {
                        self._execute_instruction(location, env, continue_observing)?
                    }
                    LocationRule::Mapped { .. } => unreachable!(),
                };
                let idx = into_result(idx, "store destination variable")?;
                if idx.is_unknown() {
                    Ok(env)
                } else {
                    Ok(env.set_var(idx.get_u32()?, value))
                }
            }
            AddressType::Signal => {
                let continue_observing =
                    if observe { self.observer.on_location_rule(location, &env)? } else { false };
                let (idx, env) = match location {
                    LocationRule::Indexed { location, .. } => {
                        self._execute_instruction(location, env, continue_observing)?
                    }
                    LocationRule::Mapped { .. } => unreachable!(),
                };
                let idx = into_result(idx, "store destination signal")?;
                if idx.is_unknown() {
                    Ok(env)
                } else {
                    Ok(env.set_signal(idx.get_u32()?, value))
                }
            }
            AddressType::SubcmpSignal { cmp_address, input_information, .. } => {
                let (addr, env) = self._execute_instruction(cmp_address, env, observe)?;
                let addr = Value::into_u32_result(addr, "store destination subcomponent")?;
                let continue_observing =
                    if observe { self.observer.on_location_rule(location, &env)? } else { false };
                let (idx, env, sub_cmp_name) = match location {
                    LocationRule::Indexed { location, template_header } => {
                        let (i, e) =
                            self._execute_instruction(location, env, continue_observing)?;
                        (
                            Value::into_u32_result(
                                i,
                                "store destination subcomponent indexed signal",
                            )?,
                            e,
                            template_header.clone(),
                        )
                    }
                    LocationRule::Mapped { signal_code, indexes } => {
                        let mut acc_env = env;
                        let name = Some(acc_env.get_subcmp_name(addr).clone());
                        let io_def =
                            self.mem.get_iodef(&acc_env.get_subcmp_template_id(addr), signal_code);
                        let map_access = io_def.offset;
                        if indexes.len() > 0 {
                            let mut indexes_values = vec![];
                            for i in indexes {
                                let (val, new_env) =
                                    self._execute_instruction(i, acc_env, continue_observing)?;
                                indexes_values.push(Value::into_u32_result(
                                    val,
                                    "store destination subcomponent mapped signal",
                                )?);
                                acc_env = new_env;
                            }
                            let offset = compute_offset(&indexes_values, &io_def.lengths)?;
                            (map_access + offset, acc_env, name)
                        } else {
                            (map_access, acc_env, name)
                        }
                    }
                };

                let env = env.set_subcmp_signal(addr, idx, value)?.decrease_subcmp_counter(addr)?;
                if let InputInformation::Input { status } = input_information {
                    match status {
                        StatusInput::Last => {
                            return Ok(env.run_subcmp(addr, &sub_cmp_name.unwrap(), self, observe));
                        }
                        StatusInput::Unknown => {
                            if env.subcmp_counter_is_zero(addr) {
                                return Ok(env.run_subcmp(
                                    addr,
                                    &sub_cmp_name.unwrap(),
                                    self,
                                    observe,
                                ));
                            }
                        }
                        _ => {}
                    }
                }
                Ok(env)
            }
        }
    }

    fn _execute_store_bucket<'env>(
        &self,
        bucket: &'env StoreBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        let (src, env) = self._execute_instruction(&bucket.src, env, observe)?;
        let src = into_result(src, "store source value")?;
        let env = self.store_value_in_address(
            &bucket.dest_address_type,
            &bucket.dest,
            src,
            env,
            observe,
        )?;
        Ok((None, env))
    }

    fn _compute_compute_bucket(&self, bucket: &ComputeBucket, env: &Env, observe: bool) -> RC {
        let mut stack = vec![];
        for i in &bucket.stack {
            let value = self._compute_instruction(i, env, observe)?;
            stack.push(into_result(value, format!("{:?} operand", bucket.op))?);
        }
        // If any value of the stack is unknown we just return unknown
        if stack.iter().any(|v| v.is_unknown()) {
            return Ok(Some(Unknown));
        }
        operations::compute_operation(bucket, &stack, &self.p)
    }

    fn _execute_compute_bucket<'env>(
        &self,
        bucket: &'env ComputeBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        self._compute_compute_bucket(bucket, &env, observe).map(|r| (r, env))
    }

    fn run_function_extracted<'env>(
        &self,
        bucket: &'env CallBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        let name = &bucket.symbol;
        if cfg!(debug_assertions) {
            println!("Running function {}", name);
        };
        //NOTE: Clone the vector of instructions prior to the Env::new_extracted_func_env(..)
        //  calls below (that give ownership of the 'env' object into the new Env instance)
        //  to avoid copying the entire 'env' instance (which is likely more expensive).
        let instructions = env.get_function(name).body.clone();
        let mut res = (None, {
            if name.starts_with(LOOP_BODY_FN_PREFIX) {
                let gdat = self.global_data.borrow();
                let fdat = &gdat.get_data_for_func(name)[&env.get_vars_sort()];
                Env::new_extracted_func_env(env, &bucket.id, fdat.0.clone(), fdat.1.clone())
            } else {
                Env::new_extracted_func_env(env, &bucket.id, Default::default(), Default::default())
            }
        });
        //NOTE: Do not change scope for the new interpreter because the mem lookups within
        //  `get_write_operations_in_store_bucket` need to use the original function context.
        let interp = self.mem.build_interpreter(self.global_data, self.observer);
        let observe = observe && !interp.observer.ignore_extracted_function_calls();
        unsafe {
            let ptr = instructions.as_ptr();
            for i in 0..instructions.len() {
                let inst = ptr.add(i).as_ref().unwrap();
                res = interp._execute_instruction(inst, res.1, observe)?;
            }
        }
        //Remove the Env::ExtractedFunction wrapper
        Ok((res.0, res.1.peel_extracted_func()))
    }

    fn run_function_basic<'env>(
        &self,
        name: &String,
        args: Vec<Value>,
        observe: bool,
    ) -> Result<Value, BadInterp> {
        if cfg!(debug_assertions) {
            println!("Running function {}", name);
        }
        let mut new_env = Env::new_standard_env(self.mem);
        for (id, arg) in args.iter().enumerate() {
            new_env = new_env.set_var(id, arg.clone());
        }
        let interp =
            self.mem.build_interpreter_with_scope(self.global_data, self.observer, name.clone());
        let (v, _) = interp.execute_instructions(
            &self.mem.get_function(name).body,
            new_env,
            observe && !interp.observer.ignore_function_calls(),
        )?;
        //ASSERT: all Circom source functions must return a value
        into_result(v, "value returned from function")
    }

    fn _execute_call_bucket<'env>(
        &self,
        bucket: &'env CallBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        let mut env = env;
        let res = if bucket.symbol.eq(FR_IDENTITY_ARR_PTR) || bucket.symbol.eq(FR_INDEX_ARR_PTR) {
            (Some(Unknown), env)
        } else if bucket.symbol.starts_with(GENERATED_FN_PREFIX) {
            // The extracted loop body and array parameter functions can change any values in
            //  the environment via the parameters passed to it. So interpret the function and
            //  keep the resulting Env (as if the function had executed inline).
            self.run_function_extracted(&bucket, env, observe)?
        } else {
            let mut args = vec![];
            for i in &bucket.arguments {
                let (value, new_env) = self._execute_instruction(i, env, observe)?;
                env = new_env;
                args.push(into_result(value, "function argument")?);
            }
            let v = if args.iter().any(|v| v.is_unknown()) {
                Unknown
            } else {
                self.run_function_basic(&bucket.symbol, args, observe)?
            };
            (Some(v), env)
        };

        // Write the result in the destination according to the ReturnType
        match &bucket.return_info {
            ReturnType::Intermediate { .. } => Ok(res),
            ReturnType::Final(final_data) => self
                .store_value_in_address(
                    &final_data.dest_address_type,
                    &final_data.dest,
                    into_result(res.0, "function return value")?,
                    res.1,
                    observe,
                )
                .map(|x| (None, x)),
        }
    }

    fn _execute_branch_bucket<'env>(
        &self,
        bucket: &'env BranchBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        let (value, cond, mut env) = self._execute_conditional_bucket(
            &bucket.cond,
            &bucket.if_branch,
            &bucket.else_branch,
            env,
            observe,
        )?;
        if cond.is_some() {
            return Ok((value, env));
        }

        // If cond is None means that the condition instruction evaluates to Unknown
        // Thus we don't know what branch to take
        // We take all writes in both branches and set all writes in them as Unknown
        let (mut vars, mut signals, mut subcmps) =
            self.get_write_operations_in_body(&bucket.if_branch, &env)?;
        self.get_write_operations_in_body_rec(
            &bucket.else_branch,
            &mut vars,
            &mut signals,
            &mut subcmps,
            &env,
        )?;

        for var in vars {
            env = env.set_var(var, Unknown);
        }
        for signal in signals {
            env = env.set_signal(signal, Unknown);
        }
        for subcmp_id in subcmps {
            env = env.set_subcmp_to_unk(subcmp_id)?;
        }
        Ok((value, env))
    }

    fn _compute_return_bucket(&self, bucket: &ReturnBucket, env: &Env, observe: bool) -> RC {
        self._compute_instruction(&bucket.value, env, observe)
    }

    fn _execute_return_bucket<'env>(
        &self,
        bucket: &'env ReturnBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        self._compute_return_bucket(bucket, &env, observe).map(|r| (r, env))
    }

    fn _compute_assert_bucket(&self, bucket: &AssertBucket, env: &Env, observe: bool) -> RC {
        let cond = self._compute_instruction(&bucket.evaluate, env, observe)?;
        let cond = into_result(cond, "assert condition")?;
        if !cond.is_unknown() && !cond.to_bool(&self.p)? {
            // Based on 'constraint_generation::execute::treat_result_with_execution_error'
            Err(BadInterp::error("False assert reached".to_string(), ReportCode::RuntimeError))
        } else {
            Ok(None)
        }
    }
    fn _execute_assert_bucket<'env>(
        &self,
        bucket: &'env AssertBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        self._compute_assert_bucket(bucket, &env, observe).map(|r| (r, env))
    }
    fn _compute_log_bucket(&self, bucket: &LogBucket, env: &Env, observe: bool) -> RC {
        for arg in &bucket.argsprint {
            if let LogBucketArg::LogExp(i) = arg {
                self._compute_instruction(i, env, observe)?;
            }
        }
        Ok(None)
    }

    fn _execute_log_bucket<'env>(
        &self,
        bucket: &'env LogBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        self._compute_log_bucket(bucket, &env, observe).map(|r| (r, env))
    }

    fn _compute_condition(
        &self,
        cond: &InstructionPointer,
        env: &Env,
        observe: bool,
    ) -> Result<Option<bool>, BadInterp> {
        let executed_cond = self._compute_instruction(cond, env, observe)?;
        let executed_cond = into_result(executed_cond, "branch condition")?;
        //NOTE: `to_bool` returns an Err if the condition is Unknown.
        // Here we must instead treat that error case as Option::None.
        Ok(executed_cond.to_bool(&self.p).ok())
    }

    fn _execute_conditional_bucket<'env>(
        &self,
        cond: &'env InstructionPointer,
        true_branch: &'env [InstructionPointer],
        false_branch: &'env [InstructionPointer],
        env: Env<'env>,
        observe: bool,
    ) -> Result<(Option<Value>, Option<bool>, Env<'env>), BadInterp> {
        match self._compute_condition(cond, &env, observe)? {
            None => Ok((None, None, env)),
            Some(true) => {
                let (ret, env) = self.execute_instructions(&true_branch, env, observe)?;
                Ok((ret, Some(true), env))
            }
            Some(false) => {
                let (ret, env) = self.execute_instructions(&false_branch, env, observe)?;
                Ok((ret, Some(false), env))
            }
        }
    }

    fn _execute_loop_bucket<'env>(
        &self,
        bucket: &'env LoopBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        let mut last_value = Some(Unknown);
        let mut loop_env = env;
        let mut n_iters = 0;
        let limit = 1_000_000;
        loop {
            n_iters += 1;
            if n_iters >= limit {
                return new_compute_err_result(format!(
                    "Could not compute value of loop within {limit} iterations"
                ));
            }

            let (value, cond, new_env) = self._execute_conditional_bucket(
                &bucket.continue_condition,
                &bucket.body,
                &[],
                loop_env,
                observe,
            )?;
            loop_env = new_env;
            match cond {
                None => {
                    let (vars, signals, subcmps) =
                        self.get_write_operations_in_body(&bucket.body, &loop_env)?;

                    for var in vars {
                        loop_env = loop_env.set_var(var, Unknown);
                    }
                    for signal in signals {
                        loop_env = loop_env.set_signal(signal, Unknown);
                    }
                    for subcmp_id in subcmps {
                        loop_env = loop_env.set_subcmp_to_unk(subcmp_id)?;
                    }
                    break Ok((value, loop_env));
                }
                Some(false) => {
                    break Ok((last_value, loop_env));
                }
                Some(true) => {
                    last_value = value;
                }
            }
        }
    }

    fn _execute_create_cmp_bucket<'env>(
        &self,
        bucket: &'env CreateCmpBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        let (cmp_id, env) = self._execute_instruction(&bucket.sub_cmp_id, env, observe)?;
        let cmp_id = Value::into_u32_result(cmp_id, "ID of subcomponent!")?;
        let mut env =
            env.create_subcmp(&bucket.symbol, cmp_id, bucket.number_of_cmp, bucket.template_id);
        // Run the subcomponents with 0 inputs directly
        for i in cmp_id..(cmp_id + bucket.number_of_cmp) {
            if env.subcmp_counter_is_zero(i) {
                env = env.run_subcmp(i, &bucket.symbol, self, observe);
            }
        }
        Ok((None, env))
    }

    fn _execute_constraint_bucket<'env>(
        &self,
        bucket: &'env ConstraintBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        self._execute_instruction(
            match bucket {
                ConstraintBucket::Substitution(i) => i,
                ConstraintBucket::Equality(i) => i,
            },
            env,
            observe,
        )
    }

    fn _execute_block_bucket<'env>(
        &self,
        bucket: &'env BlockBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        self.execute_instructions(&bucket.body, env, observe)
    }

    fn _compute_nop_bucket(&self, _bucket: &NopBucket, _env: &Env, _observe: bool) -> RC {
        Ok(None)
    }

    fn _execute_nop_bucket<'env>(
        &self,
        bucket: &NopBucket,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        self._compute_nop_bucket(bucket, &env, observe).map(|r| (r, env))
    }

    fn _compute_instruction(&self, inst: &InstructionPointer, env: &Env, observe: bool) -> RC {
        let continue_observing =
            if observe { self.observer.on_instruction(inst, env)? } else { observe };
        match inst.as_ref() {
            Instruction::Value(b) => self._compute_value_bucket(b, env, continue_observing),
            Instruction::Load(b) => self._compute_load_bucket(b, env, continue_observing),
            Instruction::Store(_) => unreachable!("must use '_execute_instruction'"),
            Instruction::Compute(b) => self._compute_compute_bucket(b, env, continue_observing),
            Instruction::Call(_) => unreachable!("must use '_execute_instruction'"),
            Instruction::Branch(_) => unreachable!("must use '_execute_instruction'"),
            Instruction::Return(b) => self._compute_return_bucket(b, env, continue_observing),
            Instruction::Assert(b) => self._compute_assert_bucket(b, env, continue_observing),
            Instruction::Log(b) => self._compute_log_bucket(b, env, continue_observing),
            Instruction::Loop(_) => unreachable!("must use '_execute_instruction'"),
            Instruction::CreateCmp(_) => unreachable!("must use '_execute_instruction'"),
            Instruction::Constraint(_) => unreachable!("must use '_execute_instruction'"),
            Instruction::Block(_) => unreachable!("must use '_execute_instruction'"),
            Instruction::Nop(b) => self._compute_nop_bucket(b, env, continue_observing),
        }
    }

    fn _execute_instruction<'env>(
        &self,
        inst: &'env InstructionPointer,
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        let continue_observing =
            if observe { self.observer.on_instruction(inst, &env)? } else { observe };
        match inst.as_ref() {
            Instruction::Value(b) => self._execute_value_bucket(b, env, continue_observing),
            Instruction::Load(b) => self._execute_load_bucket(b, env, continue_observing),
            Instruction::Store(b) => self._execute_store_bucket(b, env, continue_observing),
            Instruction::Compute(b) => self._execute_compute_bucket(b, env, continue_observing),
            Instruction::Call(b) => self._execute_call_bucket(b, env, continue_observing),
            Instruction::Branch(b) => self._execute_branch_bucket(b, env, continue_observing),
            Instruction::Return(b) => self._execute_return_bucket(b, env, continue_observing),
            Instruction::Assert(b) => self._execute_assert_bucket(b, env, continue_observing),
            Instruction::Log(b) => self._execute_log_bucket(b, env, continue_observing),
            Instruction::Loop(b) => self._execute_loop_bucket(b, env, continue_observing),
            Instruction::CreateCmp(b) => {
                self._execute_create_cmp_bucket(b, env, continue_observing)
            }
            Instruction::Constraint(b) => {
                self._execute_constraint_bucket(b, env, continue_observing)
            }
            Instruction::Block(b) => self._execute_block_bucket(b, env, continue_observing),
            Instruction::Nop(b) => self._execute_nop_bucket(b, env, continue_observing),
        }
    }
}
