pub mod value;
pub mod env;
pub mod memory;
pub mod observer;
pub(crate) mod operations;

use std::cell::RefCell;
use std::vec;
use circom_algebra::modular_arithmetic;
use code_producers::llvm_elements::fr::{FR_IDENTITY_ARR_PTR, FR_INDEX_ARR_PTR};
use compiler::intermediate_representation::{Instruction, InstructionList, InstructionPointer};
use compiler::intermediate_representation::ir_interface::*;
use compiler::num_bigint::BigInt;
use observer::InterpreterObserver;
use program_structure::constants::UsefulConstants;
use crate::bucket_interpreter::env::Env;
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::operations::compute_offset;
use crate::bucket_interpreter::value::Value::{self, KnownBigInt, KnownU32, Unknown};
use crate::passes::{LOOP_BODY_FN_PREFIX, GlobalPassData};
use self::env::LibraryAccess;

pub struct BucketInterpreter<'a, 'd> {
    global_data: &'d RefCell<GlobalPassData>,
    observer: &'a dyn InterpreterObserver,
    mem: &'a PassMemory,
    scope: String,
    p: BigInt,
}

pub type R<'a> = (Option<Value>, Env<'a>);

impl<'a: 'd, 'd> BucketInterpreter<'a, 'd> {
    pub fn init(
        global_data: &'d RefCell<GlobalPassData>,
        observer: &'a dyn InterpreterObserver,
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

    pub fn get_index_from_location(&self, location: &LocationRule, env: &Env) -> usize {
        match location {
            LocationRule::Indexed { location, .. } => {
                let (idx, _) = self.execute_instruction(location, env.clone(), false);
                idx.expect("LocationRule must produce a value!").get_u32()
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
    ) {
        match bucket.dest_address_type {
            AddressType::Variable => {
                let idx = self.get_index_from_location(&bucket.dest, env);
                for index in self.mem.get_variables_index_mapping(&self.scope, &idx) {
                    vars.push(index);
                }
            }
            AddressType::Signal => {
                let idx = self.get_index_from_location(&bucket.dest, env);
                for index in self.mem.get_signal_index_mapping(&self.scope, &idx) {
                    signals.push(index);
                }
            }
            AddressType::SubcmpSignal { .. } => {
                let idx = self.get_index_from_location(&bucket.dest, env);
                for index in self.mem.get_component_addr_index_mapping(&self.scope, &idx) {
                    subcmps.push(index);
                }
            }
        };
    }

    fn get_write_operations_in_inst_rec(
        &self,
        inst: &Instruction,
        vars: &mut Vec<usize>,
        signals: &mut Vec<usize>,
        subcmps: &mut Vec<usize>,
        env: &Env,
    ) {
        match inst {
            Instruction::Value(_) => {} // Cannot write
            Instruction::Load(_) => {}  // Should not have a StoreBucket inside
            Instruction::Store(bucket) => {
                self.get_write_operations_in_store_bucket(bucket, vars, signals, subcmps, env)
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
                );
                self.get_write_operations_in_body_rec(
                    &bucket.else_branch,
                    vars,
                    signals,
                    subcmps,
                    env,
                );
            }
            Instruction::Return(_) => {} // Should not have a StoreBucket in the return expression
            Instruction::Assert(_) => {} // Should not have a StoreBucket inside
            Instruction::Log(_) => {}    // Should not have a StoreBucket inside
            Instruction::Loop(bucket) => {
                self.get_write_operations_in_body_rec(&bucket.body, vars, signals, subcmps, env)
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
            ),
            Instruction::Block(bucket) => {
                self.get_write_operations_in_body_rec(&bucket.body, vars, signals, subcmps, env)
            }
            Instruction::Nop(_) => {} // Should not have a StoreBucket inside
        }
    }

    fn get_write_operations_in_body_rec(
        &self,
        body: &InstructionList,
        vars: &mut Vec<usize>,
        signals: &mut Vec<usize>,
        subcmps: &mut Vec<usize>,
        env: &Env,
    ) {
        for inst in body {
            self.get_write_operations_in_inst_rec(inst, vars, signals, subcmps, env);
        }
    }

    /// Returns a triple with a list of indices for each
    /// 0: Indices of variables
    /// 1: Indices of signals
    /// 2: Indices of subcmps
    fn get_write_operations_in_body(
        &self,
        body: &InstructionList,
        env: &Env,
    ) -> (Vec<usize>, Vec<usize>, Vec<usize>) {
        let mut vars = vec![];
        let mut signals = vec![];
        let mut subcmps = vec![];

        self.get_write_operations_in_body_rec(body, &mut vars, &mut signals, &mut subcmps, env);

        return (vars, signals, subcmps);
    }

    pub fn execute_value_bucket<'env>(
        &self,
        bucket: &ValueBucket,
        env: Env<'env>,
        _observe: bool,
    ) -> R<'env> {
        (
            Some(match bucket.parse_as {
                ValueType::U32 => KnownU32(bucket.value),
                ValueType::BigInt => {
                    let constant = self.mem.get_field_constant(bucket.value);
                    KnownBigInt(
                        BigInt::parse_bytes(constant.as_bytes(), 10)
                            .expect(format!("Cannot parse constant {}", constant).as_str()),
                    )
                }
            }),
            env,
        )
    }

    pub fn execute_load_bucket<'env>(
        &self,
        bucket: &'env LoadBucket,
        env: Env<'env>,
        observe: bool,
    ) -> R<'env> {
        match &bucket.address_type {
            AddressType::Variable => {
                let continue_observing =
                    if observe { self.observer.on_location_rule(&bucket.src, &env) } else { false };
                let (idx, env) = match &bucket.src {
                    LocationRule::Indexed { location, .. } => {
                        self.execute_instruction(location, env, continue_observing)
                    }
                    LocationRule::Mapped { .. } => unreachable!(),
                };
                let idx = idx.expect("Indexed location must produce a value!");
                if idx.is_unknown() {
                    (Some(Unknown), env)
                } else {
                    (Some(env.get_var(idx.get_u32())), env)
                }
            }
            AddressType::Signal => {
                let continue_observing =
                    if observe { self.observer.on_location_rule(&bucket.src, &env) } else { false };
                let (idx, env) = match &bucket.src {
                    LocationRule::Indexed { location, .. } => {
                        self.execute_instruction(location, env, continue_observing)
                    }
                    LocationRule::Mapped { .. } => unreachable!(),
                };
                let idx = idx.expect("Indexed location must produce a value!");
                if idx.is_unknown() {
                    (Some(Unknown), env)
                } else {
                    (Some(env.get_signal(idx.get_u32())), env)
                }
            }
            AddressType::SubcmpSignal { cmp_address, .. } => {
                let (addr, env) = self.execute_instruction(cmp_address, env, observe);
                let addr =
                    addr.expect("cmp_address in SubcmpSignal must produce a value!").get_u32();
                let continue_observing =
                    if observe { self.observer.on_location_rule(&bucket.src, &env) } else { false };
                let (idx, env) = match &bucket.src {
                    LocationRule::Indexed { location, .. } => {
                        let (idx, env) =
                            self.execute_instruction(location, env, continue_observing);
                        (idx.expect("Indexed location must produce a value!").get_u32(), env)
                    }
                    LocationRule::Mapped { signal_code, indexes } => {
                        let mut acc_env = env;
                        let io_def =
                            self.mem.get_iodef(&acc_env.get_subcmp_template_id(addr), signal_code);
                        let map_access = io_def.offset;
                        if indexes.len() > 0 {
                            let mut indexes_values = vec![];
                            for i in indexes {
                                let (val, new_env) =
                                    self.execute_instruction(i, acc_env, continue_observing);
                                indexes_values.push(
                                    val.expect("Mapped location must produce a value!").get_u32(),
                                );
                                acc_env = new_env;
                            }
                            let offset = compute_offset(&indexes_values, &io_def.lengths);
                            (map_access + offset, acc_env)
                        } else {
                            (map_access, acc_env)
                        }
                    }
                };
                (Some(env.get_subcmp_signal(addr, idx)), env)
            }
        }
    }

    pub fn store_value_in_address<'env>(
        &self,
        address: &'env AddressType,
        location: &'env LocationRule,
        value: Value,
        env: Env<'env>,
        observe: bool,
    ) -> Env<'env> {
        match address {
            AddressType::Variable => {
                let continue_observing =
                    if observe { self.observer.on_location_rule(location, &env) } else { false };
                let (idx, env) = match location {
                    LocationRule::Indexed { location, .. } => {
                        self.execute_instruction(location, env, continue_observing)
                    }
                    LocationRule::Mapped { .. } => unreachable!(),
                };

                let idx_value = idx.expect("Indexed location must produce a value!");
                if !idx_value.is_unknown() {
                    let idx = idx_value.get_u32();
                    env.set_var(idx, value)
                } else {
                    env
                }
            }
            AddressType::Signal => {
                let continue_observing =
                    if observe { self.observer.on_location_rule(location, &env) } else { false };
                let (idx, env) = match location {
                    LocationRule::Indexed { location, .. } => {
                        self.execute_instruction(location, env, continue_observing)
                    }
                    LocationRule::Mapped { .. } => unreachable!(),
                };

                let idx_value = idx.expect("Indexed location must produce a value!");
                if !idx_value.is_unknown() {
                    let idx = idx_value.get_u32();
                    env.set_signal(idx, value)
                } else {
                    env
                }
            }
            AddressType::SubcmpSignal { cmp_address, input_information, .. } => {
                // println!(
                //     "cmp_address = {:?}, input_information = {:?}",
                //     cmp_address, input_information
                // );
                let (addr, env) = self.execute_instruction(cmp_address, env, observe);
                let addr = addr
                    .expect(
                        "cmp_address instruction in StoreBucket SubcmpSignal must produce a value!",
                    )
                    .get_u32();
                let continue_observing =
                    if observe { self.observer.on_location_rule(location, &env) } else { false };
                let (idx, env, sub_cmp_name) = match location {
                    LocationRule::Indexed { location, template_header } => {
                        let (idx, env) =
                            self.execute_instruction(location, env, continue_observing);
                        (
                            idx.expect("Indexed location must produce a value!").get_u32(),
                            env,
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
                                    self.execute_instruction(i, acc_env, continue_observing);
                                indexes_values.push(
                                    val.expect("Mapped location must produce a value!").get_u32(),
                                );
                                acc_env = new_env;
                            }
                            let offset = compute_offset(&indexes_values, &io_def.lengths);
                            (map_access + offset, acc_env, name)
                        } else {
                            (map_access, acc_env, name)
                        }
                    }
                };

                let env = env.set_subcmp_signal(addr, idx, value).decrease_subcmp_counter(addr);

                if let InputInformation::Input { status } = input_information {
                    match status {
                        StatusInput::Last => {
                            return env.run_subcmp(addr, &sub_cmp_name.unwrap(), self, observe);
                        }
                        StatusInput::Unknown => {
                            if env.subcmp_counter_is_zero(addr) {
                                return env.run_subcmp(addr, &sub_cmp_name.unwrap(), self, observe);
                            }
                        }
                        _ => {}
                    }
                }
                env
            }
        }
    }

    pub fn execute_store_bucket<'env>(
        &self,
        bucket: &'env StoreBucket,
        env: Env<'env>,
        observe: bool,
    ) -> R<'env> {
        let (src, env) = self.execute_instruction(&bucket.src, env, observe);
        let src = src.expect("src instruction in StoreBucket must produce a value!");
        let env =
            self.store_value_in_address(&bucket.dest_address_type, &bucket.dest, src, env, observe);
        (None, env)
    }

    pub fn execute_compute_bucket<'env>(
        &self,
        bucket: &'env ComputeBucket,
        env: Env<'env>,
        observe: bool,
    ) -> R<'env> {
        let mut stack = vec![];
        let mut env = env;
        for i in &bucket.stack {
            let (value, new_env) = self.execute_instruction(i, env, observe);
            env = new_env;
            stack.push(value.expect("Stack value in ComputeBucket must yield a value!"));
        }
        // If any value of the stack is unknown we just return unknown
        if stack.iter().any(|v| v.is_unknown()) {
            return (Some(Unknown), env);
        }
        let p = &self.p;
        let computed_value = operations::compute_operation(bucket, &stack, p);
        (computed_value, env)
    }

    fn run_function_loopbody<'env>(&self, name: &String, env: Env<'env>, observe: bool) -> R<'env> {
        if cfg!(debug_assertions) {
            println!("Running function {}", name);
        };
        let mut res: R<'env> = (
            None,
            Env::new_extracted_func_env(
                env.clone(),
                self.global_data.borrow().extract_func_orig_loc[name][&env.get_vars_sort()].clone(),
            ),
        );
        //NOTE: Do not change scope for the new interpreter because the mem lookups within
        //  `get_write_operations_in_store_bucket` need to use the original function context.
        let interp = self.mem.build_interpreter(self.global_data, self.observer);
        let observe = observe && !interp.observer.ignore_function_calls();
        let instructions = &env.get_function(name).body;
        unsafe {
            let ptr = instructions.as_ptr();
            for i in 0..instructions.len() {
                let inst = ptr.add(i).as_ref().unwrap();
                res = interp.execute_instruction(inst, res.1, observe);
            }
        }
        //Remove the Env::ExtractedFunction wrapper
        (res.0, res.1.peel_extracted_func())
    }

    fn run_function_basic<'env>(&self, name: &String, args: Vec<Value>, observe: bool) -> Value {
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
        );
        v.expect("Function must produce a value!")
    }

    pub fn execute_call_bucket<'env>(
        &self,
        bucket: &'env CallBucket,
        env: Env<'env>,
        observe: bool,
    ) -> R<'env> {
        let mut env = env;
        let res = if bucket.symbol.eq(FR_IDENTITY_ARR_PTR) || bucket.symbol.eq(FR_INDEX_ARR_PTR) {
            (Some(Unknown), env)
        } else if bucket.symbol.starts_with(LOOP_BODY_FN_PREFIX) {
            // The extracted loop body functions can change any values in the environment
            //  via the parameters passed to it. So interpret the function and keep the
            //  resulting Env (as if the function had executed inline).
            self.run_function_loopbody(&bucket.symbol, env, observe)
        } else {
            let mut args = vec![];
            for i in &bucket.arguments {
                let (value, new_env) = self.execute_instruction(i, env, observe);
                env = new_env;
                args.push(value.expect("Function argument must produce a value!"));
            }
            let v = if args.iter().any(|v| v.is_unknown()) {
                Unknown
            } else {
                self.run_function_basic(&bucket.symbol, args, observe)
            };
            (Some(v), env)
        };
        // println!("[execute_call_bucket] {:?}", bucket);
        // println!(" -> value = {:?}", res.0);
        // println!(" -> new env = {}", res.1);

        // Write the result in the destination according to the ReturnType
        match &bucket.return_info {
            ReturnType::Intermediate { .. } => res,
            ReturnType::Final(final_data) => (
                None,
                self.store_value_in_address(
                    &final_data.dest_address_type,
                    &final_data.dest,
                    res.0.expect("Function must return a value!"),
                    res.1,
                    observe,
                ),
            ),
        }
    }

    pub fn execute_branch_bucket<'env>(
        &self,
        bucket: &'env BranchBucket,
        env: Env<'env>,
        observe: bool,
    ) -> R<'env> {
        let (value, cond, mut env) = self.execute_conditional_bucket(
            &bucket.cond,
            &bucket.if_branch,
            &bucket.else_branch,
            env,
            observe,
        );
        if cond.is_some() {
            return (value, env);
        }

        // If cond is None means that the condition instruction evaluates to Unknown
        // Thus we don't know what branch to take
        // We take all writes in both branches and set all writes in them as Unknown
        let (mut vars, mut signals, mut subcmps) =
            self.get_write_operations_in_body(&bucket.if_branch, &env);
        self.get_write_operations_in_body_rec(
            &bucket.else_branch,
            &mut vars,
            &mut signals,
            &mut subcmps,
            &env,
        );

        for var in vars {
            env = env.set_var(var, Unknown);
        }
        for signal in signals {
            env = env.set_signal(signal, Unknown);
        }
        for subcmp_id in subcmps {
            env = env.set_subcmp_to_unk(subcmp_id);
        }
        (value, env)
    }

    pub fn execute_return_bucket<'env>(
        &self,
        bucket: &'env ReturnBucket,
        env: Env<'env>,
        observe: bool,
    ) -> R<'env> {
        self.execute_instruction(&bucket.value, env, observe)
    }

    pub fn execute_assert_bucket<'env>(
        &self,
        bucket: &'env AssertBucket,
        env: Env<'env>,
        observe: bool,
    ) -> R<'env> {
        //self.observer.on_assert_bucket(bucket, &env);

        let (cond, env) = self.execute_instruction(&bucket.evaluate, env, observe);
        let cond = cond.expect("cond in AssertBucket must produce a value!");
        if !cond.is_unknown() {
            assert!(cond.to_bool(&self.p));
        }
        (None, env)
    }

    pub fn execute_log_bucket<'env>(
        &self,
        bucket: &'env LogBucket,
        env: Env<'env>,
        observe: bool,
    ) -> R<'env> {
        let mut env = env;
        for arg in &bucket.argsprint {
            if let LogBucketArg::LogExp(i) = arg {
                let (_, new_env) = self.execute_instruction(i, env, observe);
                env = new_env
            }
        }
        (None, env)
    }

    // TODO: Needs more work!
    pub fn execute_conditional_bucket<'env>(
        &self,
        cond: &'env InstructionPointer,
        true_branch: &'env [InstructionPointer],
        false_branch: &'env [InstructionPointer],
        env: Env<'env>,
        observe: bool,
    ) -> (Option<Value>, Option<bool>, Env<'env>) {
        let (executed_cond, env) = self.execute_instruction(cond, env, observe);
        let executed_cond = executed_cond.expect("executed_cond must produce a value!");
        let cond_bool_result = self.value_to_bool(&executed_cond);

        return match cond_bool_result {
            None => (None, None, env),
            Some(true) => {
                // if cfg!(debug_assertions) {
                //     println!("Running then branch");
                // }
                let (ret, env) = self.execute_instructions(&true_branch, env, observe);
                (ret, Some(true), env)
            }
            Some(false) => {
                // if cfg!(debug_assertions) {
                //     println!("Running else branch");
                // }
                let (ret, env) = self.execute_instructions(&false_branch, env, observe);
                (ret, Some(false), env)
            }
        };
    }

    pub fn execute_loop_bucket_once<'env>(
        &self,
        bucket: &'env LoopBucket,
        env: Env<'env>,
        observe: bool,
    ) -> (Option<Value>, Option<bool>, Env<'env>) {
        self.execute_conditional_bucket(&bucket.continue_condition, &bucket.body, &[], env, observe)
    }

    fn value_to_bool(&self, value: &Value) -> Option<bool> {
        match value {
            Unknown => None,
            KnownU32(x) => Some(*x != 0),
            KnownBigInt(b) => Some(modular_arithmetic::as_bool(b, &self.p)),
        }
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
    ) -> R<'env> {
        //self.observer.on_loop_bucket(bucket, &env);
        let mut last_value = Some(Unknown);
        let mut loop_env = env;
        let mut n_iters = 0;
        let limit = 1_000_000;
        loop {
            n_iters += 1;
            if n_iters >= limit {
                panic!("We have been running the same loop for {limit} iterations!! Is there an infinite loop?");
            }

            let (value, cond, new_env) = self.execute_conditional_bucket(
                &bucket.continue_condition,
                &bucket.body,
                &[],
                loop_env,
                observe,
            );
            loop_env = new_env;
            match cond {
                None => {
                    let (vars, signals, subcmps) =
                        self.get_write_operations_in_body(&bucket.body, &loop_env);

                    for var in vars {
                        loop_env = loop_env.set_var(var, Unknown);
                    }
                    for signal in signals {
                        loop_env = loop_env.set_signal(signal, Unknown);
                    }
                    for subcmp_id in subcmps {
                        loop_env = loop_env.set_subcmp_to_unk(subcmp_id);
                    }
                    break (value, loop_env);
                }
                Some(false) => {
                    break (last_value, loop_env);
                }
                Some(true) => {
                    last_value = value;
                }
            }
        }
    }

    pub fn execute_create_cmp_bucket<'env>(
        &self,
        bucket: &'env CreateCmpBucket,
        env: Env<'env>,
        observe: bool,
    ) -> R<'env> {
        //self.observer.on_create_cmp_bucket(bucket, &env);

        let (cmp_id, env) = self.execute_instruction(&bucket.sub_cmp_id, env, observe);
        let cmp_id = cmp_id.expect("sub_cmp_id subexpression must yield a value!").get_u32();
        let mut env =
            env.create_subcmp(&bucket.symbol, cmp_id, bucket.number_of_cmp, bucket.template_id);
        // Run the subcomponents with 0 inputs directly
        for i in cmp_id..(cmp_id + bucket.number_of_cmp) {
            if env.subcmp_counter_is_zero(i) {
                env = env.run_subcmp(i, &bucket.symbol, self, observe);
            }
        }
        (None, env)
    }

    pub fn execute_constraint_bucket<'env>(
        &self,
        bucket: &'env ConstraintBucket,
        env: Env<'env>,
        observe: bool,
    ) -> R<'env> {
        //self.observer.on_constraint_bucket(bucket, &env);

        self.execute_instruction(
            match bucket {
                ConstraintBucket::Substitution(i) => i,
                ConstraintBucket::Equality(i) => i,
            },
            env,
            observe,
        )
    }

    pub fn execute_instructions<'env>(
        &self,
        instructions: &'env [InstructionPointer],
        env: Env<'env>,
        observe: bool,
    ) -> R<'env> {
        let mut last = (None, env);
        for inst in instructions {
            last = self.execute_instruction(inst, last.1, observe);
        }
        last
    }

    pub fn execute_block_bucket<'env>(
        &self,
        bucket: &'env BlockBucket,
        env: Env<'env>,
        observe: bool,
    ) -> R<'env> {
        self.execute_instructions(&bucket.body, env, observe)
    }

    pub fn execute_nop_bucket<'env>(
        &self,
        _bucket: &NopBucket,
        env: Env<'env>,
        _observe: bool,
    ) -> R<'env> {
        (None, env)
    }

    pub fn execute_instruction<'env>(
        &self,
        inst: &'env InstructionPointer,
        env: Env<'env>,
        observe: bool,
    ) -> R<'env> {
        let continue_observing =
            if observe { self.observer.on_instruction(inst, &env) } else { observe };
        match inst.as_ref() {
            Instruction::Value(b) => self.execute_value_bucket(b, env, continue_observing),
            Instruction::Load(b) => self.execute_load_bucket(b, env, continue_observing),
            Instruction::Store(b) => self.execute_store_bucket(b, env, continue_observing),
            Instruction::Compute(b) => self.execute_compute_bucket(b, env, continue_observing),
            Instruction::Call(b) => self.execute_call_bucket(b, env, continue_observing),
            Instruction::Branch(b) => self.execute_branch_bucket(b, env, continue_observing),
            Instruction::Return(b) => self.execute_return_bucket(b, env, continue_observing),
            Instruction::Assert(b) => self.execute_assert_bucket(b, env, continue_observing),
            Instruction::Log(b) => self.execute_log_bucket(b, env, continue_observing),
            Instruction::Loop(b) => self.execute_loop_bucket(b, env, continue_observing),
            Instruction::CreateCmp(b) => self.execute_create_cmp_bucket(b, env, continue_observing),
            Instruction::Constraint(b) => {
                self.execute_constraint_bucket(b, env, continue_observing)
            }
            Instruction::Block(b) => self.execute_block_bucket(b, env, continue_observing),
            Instruction::Nop(b) => self.execute_nop_bucket(b, env, continue_observing),
        }
    }
}
