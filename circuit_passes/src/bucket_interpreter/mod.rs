pub(crate) mod value;
pub(crate) mod env;
pub(crate) mod error;
pub(crate) mod memory;
#[macro_use]
pub(crate) mod observer;
pub(crate) mod observed_visitor;
pub(crate) mod operations;
#[macro_use]
pub(crate) mod result_types;
pub mod write_collector;

use std::cell::RefCell;
use std::ops::Range;
use compiler::num_traits::Zero;
use paste::paste;
use code_producers::llvm_elements::{array_switch, fr};
use code_producers::llvm_elements::stdlib::{GENERATED_FN_PREFIX, LLVM_DONOTHING_FN_NAME};
use compiler::intermediate_representation::{
    new_id, BucketId, Instruction, InstructionList, InstructionPointer,
};
use compiler::intermediate_representation::ir_interface::*;
use compiler::num_bigint::BigInt;
use observer::Observer;
use program_structure::error_code::ReportCode;
use crate::passes::builders::{build_compute, build_u32_value};
use crate::passes::GlobalPassData;
use self::env::{CallStackFrame, Env, LibraryAccess};
use self::error::BadInterp;
use self::memory::PassMemory;
use self::operations::compute_offset;
use self::result_types::*;
use self::value::Value::{self, KnownBigInt, KnownU32, Unknown};

pub const LOOP_LIMIT: usize = 1_000_000;
pub const CALL_STACK_LIMIT: usize = 400;

#[derive(Default, Debug, Clone)]
pub struct InterpreterFlags {
    /// If 'true', the interpreter will consider the value of all
    /// signals to always be Unknown.
    pub all_signals_unknown: bool,
    /// If 'true', the interpreter will visit both branches of a
    /// conditional bucket when the condition computes to Unknown.
    /// Otherwise, neither branch will be visited in that case.
    pub visit_unknown_condition_branches: bool,
    /// Only applies if 'visit_unknown_condition_branches == true'.
    /// Conditional buckets that contain a ReturnBucket in either
    /// branch and whose condition computes to Unknown will produce
    /// an InterpRes::Continue result if this is 'true' and only
    /// produce an InterpRes::Return result if this is 'false'.
    pub propagate_only_known_returns: bool,
}

impl InterpreterFlags {
    #[inline]
    fn allow_nondetermined_return(&self) -> bool {
        self.visit_unknown_condition_branches && !self.propagate_only_known_returns
    }
}

pub struct BucketInterpreter<'a, 'd> {
    global_data: &'d RefCell<GlobalPassData>,
    observer: &'a dyn for<'e> Observer<Env<'e>>,
    flags: InterpreterFlags,
    mem: &'a PassMemory,
    #[allow(dead_code)]
    scope: String,
}

// NOTE: These result types wrap the Value in Option because statement-like
//  buckets do not return a value, only expression-like buckets do.
//
/// Result of the interpreter "execute" functions
type RE<'e> = Result<(Vec<Value>, Env<'e>), BadInterp>;
/// Result of the interpreter "compute" functions
type RC = Result<Vec<Value>, BadInterp>;
/// Like 'RE' but with a fully generic environment type
type RG<E> = Result<(Vec<Value>, E), BadInterp>;
/// Result of the interpreter 'execute_loop_bucket_once()' function
type REB<'e> = Result<(Option<bool>, Env<'e>), BadInterp>;
/// Result of the interpreter 'compute_condition()' function
type RCB = Result<Option<bool>, BadInterp>;

#[inline]
#[must_use]
pub fn to_bigint(constant: &String) -> InterpRes<BigInt> {
    match BigInt::parse_bytes(constant.as_bytes(), 10) {
        Some(v) => InterpRes::Continue(v),
        None => error::new_compute_err_result(format!("Cannot parse constant: {}", constant)),
    }
}

/// Attempt to "compute" result to avoid cloning environment but if an environment
///  modifying instruction is found, then create the clone and use "execute" instead.
macro_rules! compute_or_execute {
    ($self:ident, $bucket:ident, $env:ident, $observe:ident, $compute: ident, $execute: ident) => {
        compute_or_execute_part_2!(
            $self,
            $bucket,
            $env,
            $observe,
            $execute,
            compute_or_execute_part_1!($self, $bucket, $env, $observe, $compute)
        )
    };
}
macro_rules! compute_or_execute_part_1 {
    ($self:ident, $bucket:ident, $env:ident, $observe:ident, $compute: ident) => {
        $self.$compute($bucket, $env, $observe)
    };
}
macro_rules! compute_or_execute_part_2 {
    ($self:ident, $bucket:ident, $env:ident, $observe:ident, $execute: ident, $res: expr) => {
        if error::is_modifies_env_err_result(&$res) {
            $self.$execute($bucket, $env.clone(), $observe).map(|(v, _)| v)
        } else {
            $res
        }
    };
}

/// Generate private `execute_with_loc_*` function for the given bucket type
/// and public `execute_*` wrapper that simply converts the return to Result.
macro_rules! gen_execute_wrapers {
    ($(#[$($attrss:meta)*])* $bucket_ty: ty) => {
        paste! {
            $(#[$($attrss)*])*
            pub fn [<execute_ $bucket_ty:snake>]<'env>(
                &self,
                bucket: &$bucket_ty,
                env: Env<'env>,
                observe: bool,
            ) -> RE<'env> {
                Result::from(self.[<execute_with_loc_ $bucket_ty:snake>](bucket, env, observe))
            }
            fn [<execute_with_loc_ $bucket_ty:snake>]<'env>(
                &self,
                bucket: &$bucket_ty,
                env: Env<'env>,
                observe: bool,
            ) -> REI<'env> {
                self.[<_execute_ $bucket_ty:snake>](bucket, env, observe).add_loc_if_err(bucket)
            }
        }
    };
}

/// Generate private `compute_with_loc_*` function for the given bucket type
/// and public `compute_*` wrapper that simply converts the return to Result.
macro_rules! gen_compute_wrapers {
    ($(#[$($attrss:meta)*])* $bucket_ty: ty) => {
        paste! {
            $(#[$($attrss)*])*
            pub fn [<compute_ $bucket_ty:snake>](
                &self,
                bucket: &$bucket_ty,
                env: &Env,
                observe: bool,
            ) -> RC {
                Result::from(self.[<compute_with_loc_ $bucket_ty:snake>](bucket, env, observe))
            }
            fn [<compute_with_loc_ $bucket_ty:snake>](
                &self,
                bucket: &$bucket_ty,
                env: &Env,
                observe: bool,
            ) -> RCI {
                let res = compute_or_execute!(
                    self,
                    bucket,
                    env,
                    observe,
                    [<_compute_ $bucket_ty:snake>],
                    [<_execute_ $bucket_ty:snake>]
                );
                res.add_loc_if_err(bucket)
            }
        }
    };
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
        flags: InterpreterFlags,
        mem: &'a PassMemory,
        scope: String,
    ) -> Self {
        BucketInterpreter { global_data, observer, flags, mem, scope }
    }
}

impl BucketInterpreter<'_, '_> {
    gen_execute_wrapers!(ValueBucket);
    gen_execute_wrapers!(LoadBucket);
    gen_execute_wrapers!(StoreBucket);
    gen_execute_wrapers!(ComputeBucket);
    gen_execute_wrapers!(CallBucket);
    gen_execute_wrapers!(BranchBucket);
    gen_execute_wrapers!(ReturnBucket);
    gen_execute_wrapers!(AssertBucket);
    gen_execute_wrapers!(LogBucket);
    gen_execute_wrapers!(CreateCmpBucket);
    gen_execute_wrapers!(ConstraintBucket);
    gen_execute_wrapers!(BlockBucket);
    gen_execute_wrapers!(NopBucket);
    gen_execute_wrapers!(
        /// Executes the loop many times. If the result of the loop condition is unknown
        /// the interpreter assumes that the result of the loop is `Unknown`.
        /// In the case the condition evaluates to `Unknown` all the memory addresses
        /// potentially written into in the loop's body are set to `Unknown` to represent
        /// that we don't know the values after the execution of that loop.
        LoopBucket
    );

    pub fn execute_loop_bucket_once<'env>(
        &self,
        bucket: &LoopBucket,
        env: Env<'env>,
        observe: bool,
    ) -> REB<'env> {
        let res = self
            ._execute_conditional_bucket(
                &bucket.continue_condition,
                &bucket.body,
                &[],
                env,
                observe,
            )
            .add_loc_if_err(bucket);
        match res {
            InterpRes::Err(err) => Result::Err(err),
            InterpRes::Continue((_, cond, e)) => Result::Ok((cond, e)),
            // If there is an early return within the loop body, it cannot be unrolled because
            //  that return would be moved to a generated loop body function and those always
            //  have void return type. Although this could be changed in the future if needed.
            InterpRes::Return((_, _, e)) => Result::Ok((None, e)),
        }
    }

    pub fn execute_instructions<'env>(
        &self,
        instructions: &[InstructionPointer],
        env: Env<'env>,
        observe: bool,
    ) -> RE<'env> {
        // NOTE: line information is already added at the instruction that causes an Err, if applicable
        self._execute_instructions(instructions, env, observe).into()
    }

    gen_compute_wrapers!(LoadBucket);
    gen_compute_wrapers!(ComputeBucket);
    gen_compute_wrapers!(CallBucket);

    pub fn compute_condition(&self, cond: &InstructionPointer, env: &Env, observe: bool) -> RCB {
        compute_or_execute!(self, cond, env, observe, _compute_condition, _execute_condition)
            .add_loc_if_err(&**cond)
            .into()
    }

    pub fn compute_instruction(&self, inst: &InstructionPointer, env: &Env, observe: bool) -> RC {
        compute_or_execute!(self, inst, env, observe, _compute_instruction, _execute_instruction)
            .add_loc_if_err(&**inst)
            .into()
    }

    /// Computes the index Value from a LocationRule
    // NOTE: There cannot be a ReturnBucket inside the LocationRule so there is no
    // need to have an additional function returning InterpRes for internal use.
    pub fn compute_location_index<S: std::fmt::Display + Copy>(
        &self,
        location: &LocationRule,
        location_owner: &BucketId,
        env: &Env,
        observe: bool,
        label: S,
    ) -> Result<Value, BadInterp> {
        let continue_observing =
            observe!(self, on_location_rule, location, env, observe, location_owner)?;
        match location {
            LocationRule::Indexed { location, .. } => {
                let res = self._compute_instruction(location, env, continue_observing);
                assert!(
                    !error::is_modifies_env_err_result(&res),
                    "index instruction never modifies environment"
                );
                assert!(
                    !matches!(res, InterpRes::Return(_)),
                    "index instruction never contains return statement"
                );
                //Since this is a public function, make sure all BadInterp cases add location
                //  information and also peel off the Option, converting None into Err.
                res.map(|v| into_single_result(v, label))
                    .flatten()
                    .add_loc_if_err(location.as_ref())
                    .into()
            }
            LocationRule::Mapped { .. } => unreachable!(),
        }
    }

    /****************************************************************************************************
     * Private implementation
     * Allows any number of calls to the internal "_execute*bucket" functions without adding source
     * location information to the possible error report returned.
     * The '_compute*' functions can be used successfully for instructions that do not modify the Env.
     * However, if the instruction does contain a nested instruction that modifies the Env, the function
     * must return a InterpRes::Err(error::modifies_env_err()).
     * The '_execute*' functions allows instructions that modify the Env. They must never makes calls
     * to '_compute*' functions that could potentially return a InterpRes::Err(error::modifies_env_err()).
     ****************************************************************************************************/

    //Converts a "_compute*" function to match the signature of an "_execute*" function
    #[inline]
    fn _wrap<I, B, E: Copy, R>(
        process: impl Fn(&I, B, E, bool) -> InterpRes<R>,
    ) -> impl Fn(&I, B, E, bool) -> InterpRes<(R, E)> {
        move |s, i, e, o| process(s, i, e, o).map(|v| (v, e))
    }

    #[inline]
    fn new_vec_from<T>(count: usize, f: impl Fn(usize) -> T) -> Vec<T> {
        (0..count).map(f).collect()
    }

    fn build_indexed_with_offset(
        meta: &dyn ObtainMeta,
        location: InstructionPointer,
        template_header: Option<String>,
        i: usize,
    ) -> LocationRule {
        LocationRule::Indexed {
            location: build_compute(
                meta,
                OperatorType::Add,
                0,
                vec![location.clone(), build_u32_value(meta, i)],
            ),
            template_header: template_header.clone(),
        }
    }

    fn _compute_value_bucket(&self, bucket: &ValueBucket, _: &Env, _: bool) -> RCI {
        match bucket.parse_as {
            ValueType::U32 => InterpRes::Continue(vec![KnownU32(bucket.value)]),
            ValueType::BigInt => {
                let constant = &self.mem.get_ff_constant(bucket.value);
                to_bigint(constant).add_loc_if_err(bucket).map(|x| vec![KnownBigInt(x)])
            }
        }
    }

    fn _execute_value_bucket<'env>(
        &self,
        bucket: &ValueBucket,
        env: Env<'env>,
        observe: bool,
    ) -> REI<'env> {
        //ASSUME: A ValueBucket never contains anything that can update the Env so "compute" is sufficient.
        self._compute_value_bucket(bucket, &env, observe).map(|r| (r, env))
    }

    fn _compute_load_bucket(&self, bucket: &LoadBucket, env: &Env, observe: bool) -> RCI {
        if let Some(_) = &bucket.bounded_fn {
            // LoadBucket with 'bounded_fn' cannot be interpreted in the normal way. It
            //  must be specific to the function. Currently, there are none that give
            //  a known value so take the conservative approach to always return Unknown.
            return InterpRes::Continue(vec![Unknown]);
        }
        assert!(bucket.context.size > 0);
        match &bucket.address_type {
            AddressType::Variable => {
                let idx = check_std_res!(self.compute_location_index(
                    &bucket.src,
                    &bucket.id,
                    env,
                    observe,
                    "load source variable",
                ));
                if idx.is_unknown() {
                    return InterpRes::Continue(vec![Unknown; bucket.context.size]);
                } else {
                    let idx = check_std_res!(idx.as_u32());
                    return InterpRes::Continue(Self::new_vec_from(bucket.context.size, |i| {
                        env.get_var(idx + i)
                    }));
                }
            }
            AddressType::Signal => {
                let idx = check_std_res!(self.compute_location_index(
                    &bucket.src,
                    &bucket.id,
                    env,
                    observe,
                    "load source signal",
                ));
                // NOTE: The 'all_signals_unknown' flag must be checked at the very
                //  end so that the remainder of the expression is still visited.
                if self.flags.all_signals_unknown || idx.is_unknown() {
                    return InterpRes::Continue(vec![Unknown; bucket.context.size]);
                } else {
                    let idx = check_std_res!(idx.as_u32());
                    return InterpRes::Continue(Self::new_vec_from(bucket.context.size, |i| {
                        env.get_signal(idx + i)
                    }));
                }
            }
            AddressType::SubcmpSignal { cmp_address, .. } => {
                let addr = check_res!(self._compute_instruction(cmp_address, env, observe));
                let addr = check_std_res!(into_single_result_u32(addr, "load source subcomponent"));
                //NOTE: The 'continue_observing' flag only applies to what is inside the LocationRule.
                let continue_observing = check_std_res!(observe!(
                    self,
                    on_location_rule,
                    &bucket.src,
                    env,
                    observe,
                    &bucket.id
                ));
                let idx = match &bucket.src {
                    LocationRule::Indexed { location, .. } => {
                        let i = check_res!(self._compute_instruction(
                            location,
                            env,
                            continue_observing
                        ));
                        check_std_res!(into_single_result_u32(
                            i,
                            "load source subcomponent indexed signal"
                        ))
                    }
                    LocationRule::Mapped { signal_code, indexes } => {
                        let io_def =
                            self.mem.get_iodef(&env.get_subcmp_template_id(addr), signal_code);
                        if indexes.len() > 0 {
                            let mut indexes_values = Vec::with_capacity(indexes.len());
                            for i in indexes {
                                let val = check_res!(self._compute_instruction(
                                    i,
                                    env,
                                    continue_observing
                                ));
                                let val = check_std_res!(into_single_result_u32(
                                    val,
                                    "load source subcomponent mapped signal",
                                ));
                                indexes_values.push(val);
                            }
                            let offset =
                                check_std_res!(compute_offset(&indexes_values, &io_def.lengths));
                            io_def.offset + offset
                        } else {
                            io_def.offset
                        }
                    }
                };
                // NOTE: The 'all_signals_unknown' flag must be checked at the very
                //  end so that the remainder of the expression is still visited.
                if self.flags.all_signals_unknown {
                    return InterpRes::Continue(vec![Unknown; bucket.context.size]);
                } else {
                    return InterpRes::Continue(Self::new_vec_from(bucket.context.size, |i| {
                        env.get_subcmp_signal(addr, idx + i)
                    }));
                }
            }
        };
    }

    fn _execute_load_bucket<'env>(
        &self,
        bucket: &LoadBucket,
        env: Env<'env>,
        observe: bool,
    ) -> REI<'env> {
        //ASSUME: A LoadBucket never contains anything that can update the Env so "compute" is sufficient.
        self._compute_load_bucket(bucket, &env, observe).map(|r| (r, env))
    }

    fn _store_value_at_address<'env>(
        &self,
        env: Env<'env>,
        observe: bool,
        address: &AddressType,
        location_base: &LocationRule,
        location_offset: usize,
        location_owner: &BucketId,
        possible_range: Option<Range<usize>>, // use None if no bounds are known
        value: Value,
    ) -> InterpRes<Env<'env>> {
        match address {
            AddressType::Variable => {
                let idx = check_std_res!(self.compute_location_index(
                    location_base,
                    location_owner,
                    &env,
                    observe,
                    "store destination variable",
                ));
                if idx.is_unknown() {
                    // All variables in the range must be marked as unknown if the index is unknown
                    return InterpRes::Continue(env.set_vars_to_unknown(possible_range));
                } else {
                    let idx = location_offset + check_std_res!(idx.as_u32());
                    assert!(possible_range.is_none() || possible_range.unwrap().contains(&idx));
                    return InterpRes::Continue(env.set_var(idx, value));
                }
            }
            AddressType::Signal => {
                let idx = check_std_res!(self.compute_location_index(
                    location_base,
                    location_owner,
                    &env,
                    observe,
                    "store destination signal",
                ));
                if idx.is_unknown() {
                    // All signals in the range must be marked as unknown if the index is unknown
                    return InterpRes::Continue(env.set_signals_to_unknown(possible_range));
                } else {
                    let idx = location_offset + check_std_res!(idx.as_u32());
                    assert!(possible_range.is_none() || possible_range.unwrap().contains(&idx));
                    return InterpRes::Continue(env.set_signal(idx, value));
                }
            }
            AddressType::SubcmpSignal { cmp_address, input_information, .. } => {
                let (addr, env) =
                    check_res!(self._execute_instruction(cmp_address, env, observe), |(_, e)| e);
                let addr =
                    check_std_res!(into_single_result_u32(addr, "store destination subcomponent"));
                //NOTE: The 'continue_observing' flag only applies to what is inside the LocationRule.
                let continue_observing = check_std_res!(observe!(
                    self,
                    on_location_rule,
                    location_base,
                    env,
                    observe,
                    location_owner
                ));
                let (idx, env, sub_cmp_name) = match location_base {
                    LocationRule::Indexed { location, template_header } => {
                        let (i, e) = check_res!(
                            self._execute_instruction(location, env, continue_observing),
                            |(_, e)| e
                        );
                        let i = check_std_res!(into_single_result_u32(
                            i,
                            "store destination subcomponent indexed signal",
                        ));
                        (i, e, template_header.clone())
                    }
                    LocationRule::Mapped { signal_code, indexes } => {
                        let mut acc_env = env;
                        let name = Some(acc_env.get_subcmp_name(addr).clone());
                        let io_def =
                            self.mem.get_iodef(&acc_env.get_subcmp_template_id(addr), signal_code);
                        let map_access = io_def.offset;
                        if indexes.len() > 0 {
                            let mut indexes_values = Vec::with_capacity(indexes.len());
                            for i in indexes {
                                let (val, new_env) = check_res!(
                                    self._execute_instruction(i, acc_env, continue_observing),
                                    |(_, e)| e
                                );
                                let val = check_std_res!(into_single_result_u32(
                                    val,
                                    "store destination subcomponent mapped signal",
                                ));
                                indexes_values.push(val);
                                acc_env = new_env;
                            }
                            let offset =
                                check_std_res!(compute_offset(&indexes_values, &io_def.lengths));
                            (map_access + offset, acc_env, name)
                        } else {
                            (map_access, acc_env, name)
                        }
                    }
                };
                let idx = location_offset + idx;
                let env = check_std_res!(env.set_subcmp_signal(addr, idx, value));
                let env = check_std_res!(env.decrease_subcmp_counter(addr));
                if let InputInformation::Input { status } = input_information {
                    if matches!(status, StatusInput::Unknown if env.subcmp_counter_is_zero(addr))
                        || matches!(status, StatusInput::Last)
                    {
                        return InterpRes::Continue(env.run_subcmp(
                            addr,
                            &sub_cmp_name.unwrap(),
                            self,
                        ));
                    }
                }
                return InterpRes::Continue(env);
            }
        };
    }

    fn _store_values_at_address<'env>(
        &self,
        address: &AddressType,
        base_location: &LocationRule,
        location_owner: &BucketId,
        values: Vec<Value>,
        env: Env<'env>,
        observe: bool,
    ) -> REI<'env> {
        let mut new_env = env;
        for (i, r) in values.into_iter().enumerate() {
            new_env = check_res!(
                self._store_value_at_address(
                    new_env,
                    observe,
                    address,
                    base_location,
                    i,
                    location_owner,
                    None,
                    r,
                ),
                |e| (vec![], e)
            )
        }
        InterpRes::Continue((vec![], new_env))
    }

    fn _compute_store_bucket(&self, bucket: &StoreBucket, _: &Env, _: bool) -> RCI {
        // A StoreBucket that uses the "llvm.donothing" function to
        //  represent a no-op instruction will not update the Env.
        if let Some(f) = &bucket.bounded_fn {
            if f.eq(LLVM_DONOTHING_FN_NAME) {
                return InterpRes::Continue(vec![]);
            }
        }
        // Other StoreBucket will update the Env so "compute" is NOT sufficient.
        error::new_modifies_env_err_result()
    }

    fn _execute_store_bucket<'env>(
        &self,
        bucket: &StoreBucket,
        env: Env<'env>,
        observe: bool,
    ) -> REI<'env> {
        if let Some(f) = &bucket.bounded_fn {
            if f.eq(LLVM_DONOTHING_FN_NAME) {
                // A StoreBucket that uses the "llvm.donothing" function to
                //  represent a no-op instruction will not update the Env.
                return InterpRes::Continue((vec![], env));
            } else if let Some(r) = array_switch::get_array_switch_range(f) {
                // Here the index is unknown so, regardless of the value,
                //  all values in the range must be set to Unknown.
                return self
                    ._store_value_at_address(
                        env,
                        observe,
                        &bucket.dest_address_type,
                        &bucket.dest,
                        0,
                        &bucket.id,
                        Some(r),
                        Unknown,
                    )
                    .map(|e| (vec![], e));
            } else {
                todo!("Unexpected bounded_fn: {}", f);
            }
        } else {
            let (src, env) = check_res!(self._execute_instruction(&bucket.src, env, observe));
            // Assert expected number of results was produced
            assert_eq!(bucket.context.size, src.len());
            self._store_values_at_address(
                &bucket.dest_address_type,
                &bucket.dest,
                &bucket.id,
                src,
                env,
                observe,
            )
        }
    }

    fn _impl_compute_bucket<'s, 'i, E>(
        &'s self,
        bucket: &'i ComputeBucket,
        env: E,
        observe: bool,
        process: impl Fn(&'s Self, &'i InstructionPointer, E, bool) -> RGI<E>,
    ) -> RGI<E> {
        let mut stack = Vec::with_capacity(bucket.stack.len());
        let mut env = env;
        for i in &bucket.stack {
            let (val, new_env) = check_res!(process(&self, i, env, observe));
            let val = check_std_res!(into_single_result(val, format!("{:?} operand", bucket.op)));
            stack.push(val);
            env = new_env;
        }
        // If any value of the stack is unknown we just return Unknown
        if stack.iter().any(Value::is_unknown) {
            InterpRes::Continue((vec![Unknown], env))
        } else {
            InterpRes::try_continue(
                operations::compute_operation(bucket, &stack, self.mem.get_prime())
                    .map(into_singleton_vec)
                    .map(|v| (v, env)),
            )
        }
    }

    fn _compute_compute_bucket(&self, bucket: &ComputeBucket, env: &Env, observe: bool) -> RCI {
        self._impl_compute_bucket(bucket, env, observe, Self::_wrap(Self::_compute_instruction))
            .map(|(v, _)| v)
    }

    fn _execute_compute_bucket<'env>(
        &self,
        bucket: &ComputeBucket,
        env: Env<'env>,
        observe: bool,
    ) -> REI<'env> {
        self._impl_compute_bucket(bucket, env, observe, Self::_execute_instruction)
    }

    // NOTE: An early return result (i.e. InterpRes::Return) is valid within a function but not
    //  across the function call boundary so use a standard Result type for a clear separation.
    fn _execute_function_extracted<'env>(
        &self,
        bucket: &CallBucket,
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
        let mut res =
            (vec![], Env::new_extracted_func_env(env, &bucket.id, name, self.global_data.borrow()));
        //NOTE: Do not change scope for the new interpreter because the mem lookups
        //  within 'write_collector.rs' need to use the original function context.
        let interp = self.mem.build_interpreter_with_flags(
            self.global_data,
            self.observer,
            self.flags.clone(),
        );
        let observe = observe && !interp.observer.ignore_extracted_function_calls();
        unsafe {
            let ptr = instructions.as_ptr();
            for i in 0..instructions.len() {
                let inst = ptr.add(i).as_ref().unwrap();
                res = Result::from(interp._execute_instruction(inst, res.1, observe))?;
            }
        }
        // ASSERT: All generated functions have void return type, thus produce no value(s)
        assert!(res.0.is_empty());
        // Remove the Env::ExtractedFunction wrapper
        Result::Ok((res.0, res.1.peel_extracted_func()))
    }

    fn _execute_function_basic<'env>(
        &self,
        bucket: &CallBucket,
        env: Env<'env>,
        args: Vec<Value>,
        observe: bool,
    ) -> RE<'env> {
        if let Some(new_call_stack) = env.append_stack_if_safe_to_interpret(CallStackFrame::new(
            bucket.symbol.clone(),
            args.clone(),
        )) {
            if cfg!(debug_assertions) {
                println!("Running function {}", bucket.symbol);
            }
            let callee = self.mem.get_function(&bucket.symbol);
            // Set PassMemory scope based on the function being executed
            let parent_scope = self.mem.set_scope(callee.as_ref().into());

            // Create inner Env for the function with the function arg values set from the call
            let mut new_env =
                Env::new_source_func_env(env.clone(), &bucket.id, new_call_stack, self.mem);
            let mut args_mut = args;
            for (id, arg) in args_mut.drain(..).enumerate() {
                new_env = new_env.set_var(id, arg);
            }
            // Interpret all instructions in the body of the callee function
            let interp = self.mem.build_interpreter_with_scope(
                self.global_data,
                self.observer,
                self.flags.clone(),
                bucket.symbol.clone(),
            );
            let (body_val, _) = Result::from(interp._execute_instructions(
                &callee.body,
                new_env,
                observe && !interp.observer.ignore_function_calls(),
            ))?;
            // Restore the parent scope
            self.mem.set_scope(parent_scope);

            // CHECK: All Circom source functions must return the correct number
            //  of values, equal to the product of the return type dimensions,
            //  unless self.flags.allow_nondetermined_return() == false because
            //  that case could result in no return statements being observed.
            let func_val = if body_val.is_empty() && !self.flags.allow_nondetermined_return() {
                Result::Ok(vec![Value::Unknown; callee.returns.iter().product::<usize>()])
            } else {
                let vals = into_result(body_val, "value returned from function");
                assert!(
                    vals.is_err()
                        || vals
                            .as_ref()
                            .is_ok_and(|v| v.len() == callee.returns.iter().product::<usize>())
                );
                vals
            };
            // Return the original Env, not the new one that is internal to the function.
            func_val.map(|v| (v, env))
        } else {
            // Produce the correct number of return values
            let callee = self.mem.get_function(&bucket.symbol);
            let return_size = callee.returns.iter().product::<usize>();
            Ok((vec![Value::Unknown; return_size], env))
        }
    }

    fn _compute_call_bucket(&self, _bucket: &CallBucket, _env: &Env, _observe: bool) -> RCI {
        //TODO: perhaps there are cases where compute would suffice?
        error::new_modifies_env_err_result()
    }

    fn _execute_call_bucket<'env>(
        &self,
        bucket: &CallBucket,
        env: Env<'env>,
        observe: bool,
    ) -> REI<'env> {
        let res = if bucket.symbol.starts_with(GENERATED_FN_PREFIX) {
            // ASSUME: The arguments to a generated function will always be LoadBucket with 'bounded_fn'
            //  that are intended to generate pointers or a call to some built-in function that returns
            //  a pointer so there is no need to compute/execute their values here because a pointer
            //  is not an actual value and thus must return Value::Unknown anyway.
            assert!(bucket.arguments.iter().all(|a| match a.as_ref() {
                Instruction::Load(LoadBucket { bounded_fn: Some(symbol), .. }) =>
                    fr::is_builtin_function(symbol),
                Instruction::Call(CallBucket { symbol, .. }) => fr::is_builtin_function(symbol),
                x => {
                    println!("Did not expect {:?}", x);
                    false
                }
            }));
            // The extracted loop body and array parameter functions can change any values in
            //  the environment via the parameters passed to it. So interpret the function and
            //  keep the resulting Env (as if the function had executed inline).
            check_res!(InterpRes::try_continue(
                self._execute_function_extracted(&bucket, env, observe)
            ))
        } else {
            let mut args = vec![];
            for a in &bucket.arguments {
                // Case: vector load
                if let Instruction::Load(load) = &**a {
                    let load_size = load.context.size;
                    if load_size > 1 {
                        assert!(load.bounded_fn.is_none());
                        match &load.src {
                            LocationRule::Mapped { .. } => todo!("Can this happen?"),
                            LocationRule::Indexed { location, template_header } => {
                                for i in 0..load_size {
                                    let scalar_load = LoadBucket {
                                        id: new_id(),
                                        source_file_id: load.source_file_id,
                                        line: load.line,
                                        message_id: load.message_id,
                                        address_type: load.address_type.clone(),
                                        src: Self::build_indexed_with_offset(
                                            load,
                                            location.clone(),
                                            template_header.clone(),
                                            i,
                                        ),
                                        context: InstrContext { size: 1 },
                                        bounded_fn: None,
                                    }
                                    .allocate();
                                    let val = check_res!(
                                        self._compute_instruction(&scalar_load, &env, observe),
                                        |v| (v, env)
                                    );
                                    args.push(check_std_res!(into_single_result(
                                        val,
                                        "function argument"
                                    )));
                                }
                            }
                        }
                        continue;
                    }
                }
                // Case: anything else
                let val = check_res!(self._compute_instruction(a, &env, observe), |v| (v, env));
                args.push(check_std_res!(into_single_result(val, "function argument")));
            }
            check_res!(InterpRes::try_continue(
                self._execute_function_basic(&bucket, env, args, observe)
            ))
        };

        // Write the result in the destination according to the ReturnType
        match &bucket.return_info {
            ReturnType::Intermediate { .. } => InterpRes::Continue(res),
            ReturnType::Final(final_data) => {
                // If a vector is returned that is smaller than the return type, the circom frontend
                // gives the warning "Mismatched dimensions, assigning to an array an expression of
                //  smaller length, the remaining positions are assigned to 0."
                assert!(res.0.len() <= final_data.context.size);
                let mut new_env = res.1;
                if res.0.len() < final_data.context.size {
                    for i in res.0.len()..final_data.context.size {
                        new_env = check_res!(
                            self._store_value_at_address(
                                new_env,
                                observe,
                                &final_data.dest_address_type,
                                &final_data.dest,
                                i,
                                &bucket.id,
                                None,
                                Value::KnownBigInt(BigInt::zero()),
                            ),
                            |e| (vec![], e)
                        )
                    }
                }
                self._store_values_at_address(
                    &final_data.dest_address_type,
                    &final_data.dest,
                    &bucket.id,
                    res.0,
                    new_env,
                    observe,
                )
            }
        }
    }

    fn _compute_branch_bucket(&self, bucket: &BranchBucket, env: &Env, observe: bool) -> RCI {
        let res = self._compute_conditional_bucket(
            &bucket.cond,
            &bucket.if_branch,
            &bucket.else_branch,
            env,
            observe,
        );
        match res {
            // Directly return errors
            InterpRes::Err(e) => InterpRes::Err(e),
            // If the condition is None, return an error
            InterpRes::Continue((_, None)) => error::new_modifies_env_err_result(),
            InterpRes::Return((_, None)) => error::new_modifies_env_err_result(),
            // Otherwise, return the value of the condition
            InterpRes::Continue((v, _)) => InterpRes::Continue(v),
            InterpRes::Return((v, _)) => InterpRes::Return(v),
        }
    }

    fn _execute_branch_bucket<'env>(
        &self,
        bucket: &BranchBucket,
        env: Env<'env>,
        observe: bool,
    ) -> REI<'env> {
        // Define helper function for use below. If the branch condition is None, it means
        //  that the condition instruction evaluates to Unknown so we don't know what
        //  branch to take so find all writes in both branches and set them as Unknown.
        let set_all_unknown = |v, e| {
            let e = write_collector::set_writes_to_unknown(self, &bucket.if_branch, e)?;
            let e = write_collector::set_writes_to_unknown(self, &bucket.else_branch, e)?;
            Result::Ok((v, e))
        };

        let res = self._execute_conditional_bucket(
            &bucket.cond,
            &bucket.if_branch,
            &bucket.else_branch,
            env,
            observe,
        );
        match res {
            // Directly return errors
            InterpRes::Err(e) => InterpRes::Err(e),
            // If the condition is None, set all stores inside both branches to Unknown
            InterpRes::Continue((v, None, e)) => InterpRes::try_continue(set_all_unknown(v, e)),
            InterpRes::Return((v, None, e)) => InterpRes::try_return(set_all_unknown(v, e)),
            // Otherwise, return the value of the condition
            InterpRes::Continue((v, _, e)) => InterpRes::Continue((v, e)),
            InterpRes::Return((v, _, e)) => InterpRes::Return((v, e)),
        }
    }

    fn _compute_return_bucket(&self, bucket: &ReturnBucket, env: &Env, observe: bool) -> RCI {
        // ReturnBucket should always produce InterpRes::Return
        match self._compute_instruction(&bucket.value, env, observe) {
            InterpRes::Continue(t) => InterpRes::Return(t),
            r => r,
        }
    }

    fn _execute_return_bucket<'env>(
        &self,
        bucket: &ReturnBucket,
        env: Env<'env>,
        observe: bool,
    ) -> REI<'env> {
        //ASSUME: A ReturnBucket never contains anything that can update the Env so "compute" is sufficient.
        self._compute_return_bucket(bucket, &env, observe).map(|r| (r, env))
    }

    fn _impl_assert_bucket<'s, 'i, E>(
        &'s self,
        bucket: &'i AssertBucket,
        env: E,
        observe: bool,
        process: impl Fn(&'s Self, &'i InstructionPointer, E, bool) -> RGI<E>,
    ) -> RGI<E> {
        let (cond, env) = check_res!(process(&self, &bucket.evaluate, env, observe));
        let cond = check_std_res!(into_single_result(cond, "assert condition"));
        if !cond.is_unknown() && !check_std_res!(cond.to_bool(self.mem.get_prime())) {
            // Based on 'constraint_generation::execute::treat_result_with_execution_error'
            InterpRes::Err(BadInterp::error(
                "False assert reached".to_string(),
                ReportCode::RuntimeError,
            ))
        } else {
            InterpRes::Continue((vec![], env))
        }
    }

    fn _compute_assert_bucket(&self, bucket: &AssertBucket, env: &Env, observe: bool) -> RCI {
        self._impl_assert_bucket(bucket, env, observe, Self::_wrap(Self::_compute_instruction))
            .map(|(v, _)| v)
    }

    fn _execute_assert_bucket<'env>(
        &self,
        bucket: &AssertBucket,
        env: Env<'env>,
        observe: bool,
    ) -> REI<'env> {
        self._impl_assert_bucket(bucket, env, observe, Self::_execute_instruction)
    }

    fn _compute_log_bucket(&self, bucket: &LogBucket, env: &Env, observe: bool) -> RCI {
        for arg in &bucket.argsprint {
            if let LogBucketArg::LogExp(i) = arg {
                check_res!(self._compute_instruction(i, env, observe));
            }
        }
        InterpRes::Continue(vec![])
    }

    fn _execute_log_bucket<'env>(
        &self,
        bucket: &LogBucket,
        env: Env<'env>,
        observe: bool,
    ) -> REI<'env> {
        //ASSUME: A LogBucket never contains anything that can update the Env so "compute" is sufficient.
        self._compute_log_bucket(bucket, &env, observe).map(|r| (r, env))
    }

    fn _compute_condition(
        &self,
        cond: &InstructionPointer,
        env: &Env,
        observe: bool,
    ) -> InterpRes<Option<bool>> {
        self._compute_instruction(cond, env, observe)
            .expect_single("branch condition")
            //NOTE: `to_bool` returns an Err if the condition is Unknown.
            // Here we must instead treat that error case as Option::None.
            .map(|v| v.to_bool(self.mem.get_prime()).ok())
    }

    fn _execute_condition<'env>(
        &self,
        cond: &InstructionPointer,
        env: Env<'env>,
        observe: bool,
    ) -> InterpRes<(Option<bool>, Env<'env>)> {
        //ASSUME: The branch condition itself never contains anything that can update the Env so "compute" is sufficient.
        self._compute_condition(cond, &env, observe).map(|r| (r, env))
    }

    fn _impl_conditional_bucket<'s, 'i, E: Clone + std::fmt::Debug>(
        &'s self,
        cond: &'i InstructionPointer,
        true_branch: &'i [InstructionPointer],
        false_branch: &'i [InstructionPointer],
        env: E,
        observe: bool,
        process_cond: impl Fn(&'s Self, &'i InstructionPointer, E, bool) -> InterpRes<(Option<bool>, E)>,
        process_body: impl Fn(&'s Self, &'i [InstructionPointer], E, bool) -> RGI<E>,
    ) -> RBI<E> {
        let (cond_val, env) = check_res!(
            process_cond(&self, cond, env, observe),
            |_| unreachable!() // Cannot contain InterpRes::Return
        );
        match cond_val {
            Some(c) => {
                let active_branch = if c { true_branch } else { false_branch };
                process_body(&self, active_branch, env, observe).map(|(r, e)| (r, Some(c), e))
            }
            None => {
                // Must visit both branch bodies, ignore the result but if either
                //   had an early return the result must reflect that, if requested.
                let observe_inside = observe & self.flags.visit_unknown_condition_branches;
                let tb_res = process_body(&self, &true_branch, env.clone(), observe_inside);
                let fb_res = process_body(&self, &false_branch, env.clone(), observe_inside);
                // Circom semantics do NOT allow a conditional statement to produce a value like this:
                //  var x = if (a < 7) { 0 } else { 1 }
                // Thus, only an `InterpRes::Return` result can contain non-empty Vec<Value> and that
                //  case can occur when there is a return statement within the body of the branch.
                //
                // ASSERT: `InterpRes::Continue` must have an empty value vector
                assert_eq!(
                    false,
                    matches!(&tb_res, InterpRes::Continue((x, _)) if !x.is_empty()),
                    "Unexpected: value(s) produced without a RETURN: {:?}",
                    tb_res
                );
                assert_eq!(
                    false,
                    matches!(&fb_res, InterpRes::Continue((x, _)) if !x.is_empty()),
                    "Unexpected: value(s) produced without a RETURN: {:?}",
                    fb_res
                );
                // ASSERT: If both branches return, they must produce the same number of values
                assert!(match (&tb_res, &fb_res) {
                    (InterpRes::Return((a, _)), InterpRes::Return((b, _))) => a.len() == b.len(),
                    _ => true,
                });

                if self.flags.allow_nondetermined_return() {
                    // When the condition is Unknown, the proper number of
                    //  Unknown values must be returned with the original Env.
                    if let InterpRes::Return((a, _)) = tb_res {
                        return InterpRes::Return((vec![Value::Unknown; a.len()], None, env));
                    }
                    if let InterpRes::Return((a, _)) = fb_res {
                        return InterpRes::Return((vec![Value::Unknown; a.len()], None, env));
                    }
                }
                // As stated above, Continue must not return any values.
                InterpRes::Continue((vec![], None, env))
            }
        }
    }

    fn _compute_conditional_bucket(
        &self,
        cond: &InstructionPointer,
        true_branch: &[InstructionPointer],
        false_branch: &[InstructionPointer],
        env: &Env,
        observe: bool,
    ) -> InterpRes<(Vec<Value>, Option<bool>)> {
        self._impl_conditional_bucket(
            cond,
            true_branch,
            false_branch,
            env,
            observe,
            Self::_wrap(Self::_compute_condition),
            Self::_wrap(Self::_compute_instructions),
        )
        .map(|(v, b, _)| (v, b))
    }

    fn _execute_conditional_bucket<'env>(
        &self,
        cond: &InstructionPointer,
        true_branch: &[InstructionPointer],
        false_branch: &[InstructionPointer],
        env: Env<'env>,
        observe: bool,
    ) -> RBI<Env<'env>> {
        self._impl_conditional_bucket(
            cond,
            true_branch,
            false_branch,
            env,
            observe,
            Self::_execute_condition,
            Self::_execute_instructions,
        )
    }

    fn _impl_loop_bucket<E: std::fmt::Debug>(
        &self,
        bucket: &LoopBucket,
        env: E,
        observe: bool,
        process: impl Fn(
            &Self,
            &InstructionPointer,
            &[InstructionPointer],
            &[InstructionPointer],
            E,
            bool,
        ) -> RBI<E>,
        handle_unknown: impl Fn(&Self, &InstructionList, E, Vec<Value>) -> RG<E>,
    ) -> RGI<E> {
        let mut last_value = vec![Unknown];
        let mut loop_env = env;
        let mut n_iters = 0;
        loop {
            n_iters += 1;
            if n_iters > LOOP_LIMIT {
                return error::new_compute_err_result(format!(
                    "Could not compute value of loop within {LOOP_LIMIT} iterations"
                ));
            }

            let (value, cond, new_env) = check_res!(
                process(&self, &bucket.continue_condition, &bucket.body, &[], loop_env, observe),
                |(v, _, e)| (v, e)
            );
            loop_env = new_env;
            match cond {
                None => {
                    return InterpRes::try_continue(handle_unknown(
                        self,
                        &bucket.body,
                        loop_env,
                        value,
                    ));
                }
                Some(false) => {
                    return InterpRes::Continue((last_value, loop_env));
                }
                Some(true) => {
                    last_value = value;
                }
            }
        }
    }

    fn _compute_loop_bucket(&self, bucket: &LoopBucket, env: &Env, observe: bool) -> RCI {
        self._impl_loop_bucket(
            bucket,
            env,
            observe,
            |s, c, t, f, e, o| {
                Self::_compute_conditional_bucket(s, c, t, f, e, o).map(|(v, b)| (v, b, e))
            },
            |_, _, _, _| Result::Err(error::new_modifies_env_err()), // Unknown condition requires Env update
        )
        .map(|(v, _)| v)
    }

    fn _execute_loop_bucket<'env>(
        &self,
        bucket: &LoopBucket,
        env: Env<'env>,
        observe: bool,
    ) -> REI<'env> {
        self._impl_loop_bucket(
            bucket,
            env,
            observe,
            Self::_execute_conditional_bucket,
            |s, b, e, v| write_collector::set_writes_to_unknown(s, b, e).map(|ne| (v, ne)),
        )
    }

    fn _compute_create_cmp_bucket(&self, _: &CreateCmpBucket, _: &Env, _: bool) -> RCI {
        //ASSUME: A CreateCmpBucket always updates the Env so "compute" is NOT sufficient.
        error::new_modifies_env_err_result()
    }

    fn _execute_create_cmp_bucket<'env>(
        &self,
        bucket: &CreateCmpBucket,
        env: Env<'env>,
        observe: bool,
    ) -> REI<'env> {
        let (cmp_id, env) = check_res!(self._execute_instruction(&bucket.sub_cmp_id, env, observe));
        let cmp_id = check_std_res!(into_single_result_u32(cmp_id, "ID of subcomponent!"));
        let mut env =
            env.create_subcmp(&bucket.symbol, cmp_id, bucket.number_of_cmp, bucket.template_id);
        // Run the subcomponents with 0 inputs directly
        for i in cmp_id..(cmp_id + bucket.number_of_cmp) {
            if env.subcmp_counter_is_zero(i) {
                env = env.run_subcmp(i, &bucket.symbol, self);
            }
        }
        InterpRes::Continue((vec![], env))
    }

    fn _compute_constraint_bucket(
        &self,
        bucket: &ConstraintBucket,
        env: &Env,
        observe: bool,
    ) -> RCI {
        self._compute_instruction(bucket.unwrap(), env, observe)
    }

    fn _execute_constraint_bucket<'env>(
        &self,
        bucket: &ConstraintBucket,
        env: Env<'env>,
        observe: bool,
    ) -> REI<'env> {
        self._execute_instruction(bucket.unwrap(), env, observe)
    }

    fn _compute_block_bucket(&self, bucket: &BlockBucket, env: &Env, observe: bool) -> RCI {
        self._compute_instructions(&bucket.body, env, observe)
    }

    fn _execute_block_bucket<'env>(
        &self,
        bucket: &BlockBucket,
        env: Env<'env>,
        observe: bool,
    ) -> REI<'env> {
        self._execute_instructions(&bucket.body, env, observe)
    }

    fn _compute_nop_bucket(&self, _bucket: &NopBucket, _env: &Env, _observe: bool) -> RCI {
        InterpRes::Continue(vec![])
    }

    fn _execute_nop_bucket<'env>(
        &self,
        bucket: &NopBucket,
        env: Env<'env>,
        observe: bool,
    ) -> REI<'env> {
        //ASSUME: A NopBucket never contains anything that can update the Env so "compute" is sufficient.
        self._compute_nop_bucket(bucket, &env, observe).map(|r| (r, env))
    }

    fn _compute_instruction(&self, inst: &InstructionPointer, env: &Env, observe: bool) -> RCI {
        let continue_observing = check_std_res!(observe!(self, on_instruction, inst, env, observe));
        match inst.as_ref() {
            Instruction::Value(b) => self._compute_value_bucket(b, env, continue_observing),
            Instruction::Load(b) => self._compute_load_bucket(b, env, continue_observing),
            Instruction::Store(b) => self._compute_store_bucket(b, env, continue_observing),
            Instruction::Compute(b) => self._compute_compute_bucket(b, env, continue_observing),
            Instruction::Call(b) => self._compute_call_bucket(b, env, continue_observing),
            Instruction::Branch(b) => self._compute_branch_bucket(b, env, continue_observing),
            Instruction::Return(b) => self._compute_return_bucket(b, env, continue_observing),
            Instruction::Assert(b) => self._compute_assert_bucket(b, env, continue_observing),
            Instruction::Log(b) => self._compute_log_bucket(b, env, continue_observing),
            Instruction::Loop(b) => self._compute_loop_bucket(b, env, continue_observing),
            Instruction::CreateCmp(b) => {
                self._compute_create_cmp_bucket(b, env, continue_observing)
            }
            Instruction::Constraint(b) => {
                self._compute_constraint_bucket(b, env, continue_observing)
            }
            Instruction::Block(b) => self._compute_block_bucket(b, env, continue_observing),
            Instruction::Nop(b) => self._compute_nop_bucket(b, env, continue_observing),
        }
    }

    fn _compute_instructions(
        &self,
        instructions: &[InstructionPointer],
        env: &Env,
        observe: bool,
    ) -> RCI {
        let mut last = vec![];
        for i in instructions {
            // Append location if Err to give more specific line information
            // Use "check" so any Err or Return case returns without processing the rest.
            last = check_res!(self._compute_instruction(i, env, observe).add_loc_if_err(&**i));
        }
        InterpRes::Continue(last)
    }

    fn _execute_instruction<'env>(
        &self,
        inst: &InstructionPointer,
        env: Env<'env>,
        observe: bool,
    ) -> REI<'env> {
        let continue_observing = check_std_res!(observe!(self, on_instruction, inst, env, observe));
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

    fn _execute_instructions<'env>(
        &self,
        instructions: &[InstructionPointer],
        env: Env<'env>,
        observe: bool,
    ) -> REI<'env> {
        let mut last = (vec![], env);
        for i in instructions {
            // Append location if Err to give more specific line information.
            // Use "check" so any Err or Return case returns without processing the rest.
            last = check_res!(self._execute_instruction(i, last.1, observe).add_loc_if_err(&**i));
        }
        InterpRes::Continue(last)
    }
}
