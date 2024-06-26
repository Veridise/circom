use std::cell::{RefCell, Ref};
use std::collections::{BTreeMap, HashSet, HashMap};
use std::fmt::{Debug, Formatter};
use indexmap::IndexMap;
use compiler::intermediate_representation::BucketId;
use compiler::intermediate_representation::ir_interface::*;
use crate::bucket_interpreter::env::Env;
use crate::bucket_interpreter::error::BadInterp;
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::observer::Observer;
use crate::bucket_interpreter::value::Value;
use crate::passes::GlobalPassData;
use super::DEBUG_LOOP_UNROLL;
use super::body_extractor::{UnrolledIterLvars, ToOriginalLocation, FuncArgIdx};

pub struct EnvRecorder<'a, 'd> {
    global_data: &'d RefCell<GlobalPassData>,
    mem: &'a PassMemory,
    // NOTE: RefCell is needed here because the instance of this struct is borrowed by
    //  the main interpreter while we also need to mutate these internal structures.
    current_iter_num: RefCell<usize>,
    safe_to_move: RefCell<bool>,
    /// Holds values of index variables at array loads/stores within a loop. Primary
    /// key is the iteration number, secondary key is the ID of the load/store/call
    /// bucket where the reference is located.
    // NOTE: The BTreeMap ensures consistent ordering of arguments and the IndexMap preserved
    // insertion order (i.e. order of the statements in the body). These are used instead of
    // HashMap to stabilize outputs for lit test FileCheck directives; not for correctness.
    loadstore_to_index_per_iter: RefCell<BTreeMap<usize, IndexMap<BucketId, (AddressType, Value)>>>,
    /// Holds the computed Value of the variable slots at the loop header. Primary
    /// key is the iteration number, secondary key is the variable slot number.
    // NOTE: The BTreeMap is used because the value must be sorted by slot number.
    vals_at_header_per_iter: RefCell<HashMap<usize, BTreeMap<usize, Value>>>,
    // Reference to the Env at the loop header
    env_at_header: RefCell<Option<Env<'a>>>,
}

impl Debug for EnvRecorder<'_, '_> {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "\n {} = {}\n {} = {}\n {} = {:?}\n {} = {:?}\n {} = {:?}",
            "current_iter_num",
            self.current_iter_num.borrow(),
            "safe_to_move",
            self.safe_to_move.borrow(),
            "loadstore_to_index_per_iter",
            self.loadstore_to_index_per_iter.borrow(),
            "vals_at_header_per_iter",
            self.vals_at_header_per_iter.borrow().iter().collect::<BTreeMap<_, _>>(),
            "env_at_header",
            self.env_at_header.borrow(),
        )
    }
}

impl<'a, 'd> EnvRecorder<'a, 'd> {
    pub fn new(global_data: &'d RefCell<GlobalPassData>, mem: &'a PassMemory) -> Self {
        EnvRecorder {
            global_data,
            mem,
            current_iter_num: RefCell::new(0),
            safe_to_move: RefCell::new(true),
            loadstore_to_index_per_iter: Default::default(),
            vals_at_header_per_iter: Default::default(),
            env_at_header: RefCell::new(None),
        }
    }

    pub fn take_header_vars_for_iter(&self, iter: &usize) -> BTreeMap<usize, Value> {
        // 'record_env_at_header' should have been called for each iteration and this
        //  should only be called once per iteration so the unwrap should never fail.
        self.vals_at_header_per_iter.borrow_mut().remove(iter).unwrap_or_else(|| {
            panic!("Cannot find cached values at header for iteration {}!", iter)
        })
    }

    pub fn get_current_scope_name(&self) -> Ref<String> {
        self.mem.get_current_scope_name()
    }

    pub fn take_loadstore_to_index_map(
        &self,
    ) -> BTreeMap<usize, IndexMap<BucketId, (AddressType, Value)>> {
        self.loadstore_to_index_per_iter.take()
    }

    pub fn is_safe_to_move(&self) -> bool {
        *self.safe_to_move.borrow()
    }

    pub fn increment_iter(&self) {
        *self.current_iter_num.borrow_mut() += 1;
    }

    pub fn get_iter(&self) -> usize {
        *self.current_iter_num.borrow()
    }

    pub fn record_header_env(&self, env: &Env<'a>) {
        // Store sorted clone of only the variable values at the header
        let iter = self.get_iter();
        assert!(!self.vals_at_header_per_iter.borrow().contains_key(&iter));
        self.vals_at_header_per_iter.borrow_mut().insert(iter, env.get_vars_sort());
        // Store reference to the Env at loop header for the interpreter
        self.env_at_header.replace(Some(env.clone()));
    }

    pub fn drop_header_env(&self) {
        self.env_at_header.replace(None);
    }

    pub fn record_reverse_arg_mapping(
        &self,
        extract_func: String,
        iter_env: UnrolledIterLvars,
        value: (ToOriginalLocation, HashSet<FuncArgIdx>),
    ) {
        if DEBUG_LOOP_UNROLL {
            println!("[EnvRecorder] stored data {:?} -> {:?}", iter_env, value);
        }
        self.global_data
            .borrow_mut()
            .extract_func_orig_loc
            .entry(extract_func)
            .or_default()
            .insert(iter_env, value);
    }

    #[inline]
    fn default_return(&self) -> Result<bool, BadInterp> {
        Ok(self.is_safe_to_move()) //continue observing unless something unsafe has been found
    }

    fn record_memloc_at_bucket(
        &self,
        bucket_id: &BucketId,
        addr_ty: AddressType,
        val: Value,
    ) -> Result<(), BadInterp> {
        self.loadstore_to_index_per_iter
            .borrow_mut()
            .entry(self.get_iter())
            .or_default()
            .insert(*bucket_id, (addr_ty, val));
        Ok(())
    }

    fn compute_index_from_inst(
        &self,
        env: &Env,
        location: &InstructionPointer,
    ) -> Result<Value, BadInterp> {
        // Evaluate the index using the current environment and using the environment from the
        //  loop header. If either is Unknown or they do not give the same value, then it is
        //  not safe to move the loop body to another function because the index computation may
        //  not give the same result when done at the call site, outside of the new function.
        let interp = self.mem.build_interpreter(self.global_data, self);
        if let Some(idx_loc) = interp.compute_instruction(location, env, false)? {
            // NOTE: It's possible for the interpreter to run into problems evaluating the location
            //  using the header Env. For example, a value may not have been defined yet so address
            //  computations on that value could give out of range results for the 'usize' type.
            //  Thus, these errors should be ignored and fall through into the Ok(Unknown) case.
            let env_ref = self.env_at_header.borrow();
            let header_res = interp.compute_instruction(location, env_ref.as_ref().unwrap(), false);
            if let Ok(Some(idx_header)) = header_res {
                if Value::eq(&idx_header, &idx_loc) {
                    return Ok(idx_loc);
                }
            }
        }
        Ok(Value::Unknown)
    }

    fn compute_index_from_rule(&self, env: &Env, loc: &LocationRule) -> Result<Value, BadInterp> {
        match loc {
            LocationRule::Mapped { .. } => {
                //TODO: It's not an array index in this case, at least not immediately but I think it can
                //  ultimately be converted to one because the subcmp storage is an array of values. Is
                //  that value known now? Do I also need the AddressType to compute the correct index?
                //SEE: https://veridise.atlassian.net/browse/VAN-704
                Ok(Value::Unknown)
            }
            LocationRule::Indexed { location, .. } => self.compute_index_from_inst(env, location),
        }
    }

    fn check_location_rule(&self, env: &Env, loc: &LocationRule) -> Result<Value, BadInterp> {
        let res = self.compute_index_from_rule(env, loc);
        if let Ok(Value::Unknown) = res {
            if DEBUG_LOOP_UNROLL {
                println!(
                    "loop body is not safe to move because index is unknown from loc: {:?}",
                    loc
                );
            }
            self.safe_to_move.replace(false);
        }
        res
    }

    fn check_address(
        &self,
        bucket_id: &BucketId,
        addr_ty: &AddressType,
        loc: &LocationRule,
        env: &Env,
    ) -> Result<(), BadInterp> {
        //NOTE: must record even when Unknown to ensure that Unknown value is not confused with
        //  missing values for an iteration that can be caused by conditionals within the loop.
        if let AddressType::SubcmpSignal {
            cmp_address,
            uniform_parallel_value,
            is_output,
            input_information,
            counter_override,
        } = addr_ty
        {
            let loc_result = self.check_location_rule(env, loc)?;
            let addr_result = self.compute_index_from_inst(env, cmp_address)?;
            self.record_memloc_at_bucket(
                bucket_id,
                AddressType::SubcmpSignal {
                    cmp_address: {
                        if addr_result == Value::Unknown {
                            if DEBUG_LOOP_UNROLL {
                                println!("loop body is not safe to move because index is unknown from addr: {:?}", cmp_address);
                            }
                            self.safe_to_move.replace(false);
                            NopBucket { id: 0 }.allocate()
                        } else {
                            addr_result.to_value_bucket(self.mem)?.allocate()
                        }
                    },
                    uniform_parallel_value: uniform_parallel_value.clone(),
                    is_output: *is_output,
                    input_information: input_information.clone(),
                    counter_override: *counter_override,
                },
                loc_result,
            )
        } else {
            let loc_result = self.check_location_rule(env, loc)?;
            self.record_memloc_at_bucket(bucket_id, addr_ty.clone(), loc_result)
        }
    }
}

impl Observer<Env<'_>> for EnvRecorder<'_, '_> {
    fn on_load_bucket(&self, bucket: &LoadBucket, env: &Env) -> Result<bool, BadInterp> {
        if let Some(_) = bucket.bounded_fn {
            todo!(); //not sure if/how to handle that
        }
        self.check_address(&bucket.id, &bucket.address_type, &bucket.src, env)?;
        self.default_return()
    }

    fn on_store_bucket(&self, bucket: &StoreBucket, env: &Env) -> Result<bool, BadInterp> {
        if let Some(_) = bucket.bounded_fn {
            todo!(); //not sure if/how to handle that
        }
        self.check_address(&bucket.id, &bucket.dest_address_type, &bucket.dest, env)?;
        self.default_return()
    }

    fn on_call_bucket(&self, bucket: &CallBucket, env: &Env) -> Result<bool, BadInterp> {
        if let ReturnType::Final(fd) = &bucket.return_info {
            self.check_address(&bucket.id, &fd.dest_address_type, &fd.dest, env)?;
        }
        self.default_return()
    }

    fn on_location_rule(
        &self,
        _: &LocationRule,
        _: &Env,
        location_owner: &BucketId,
    ) -> Result<bool, BadInterp> {
        if let Some(m) = self.loadstore_to_index_per_iter.borrow().get(&self.get_iter()) {
            if m.contains_key(location_owner) {
                // A substitution exists for the owner so don't continue within the LocationRule
                return Ok(false);
            }
        }
        self.default_return()
    }

    fn on_value_bucket(&self, _: &ValueBucket, _: &Env) -> Result<bool, BadInterp> {
        self.default_return()
    }

    fn on_compute_bucket(&self, _: &ComputeBucket, _: &Env) -> Result<bool, BadInterp> {
        self.default_return()
    }

    fn on_assert_bucket(&self, _: &AssertBucket, _: &Env) -> Result<bool, BadInterp> {
        self.default_return()
    }

    fn on_loop_bucket(&self, _: &LoopBucket, _: &Env) -> Result<bool, BadInterp> {
        self.default_return()
    }

    fn on_create_cmp_bucket(&self, _: &CreateCmpBucket, _: &Env) -> Result<bool, BadInterp> {
        self.default_return()
    }

    fn on_constraint_bucket(&self, _: &ConstraintBucket, _: &Env) -> Result<bool, BadInterp> {
        self.default_return()
    }

    fn on_block_bucket(&self, _: &BlockBucket, _: &Env) -> Result<bool, BadInterp> {
        self.default_return()
    }

    fn on_nop_bucket(&self, _: &NopBucket, _: &Env) -> Result<bool, BadInterp> {
        self.default_return()
    }

    fn on_branch_bucket(&self, _: &BranchBucket, _: &Env) -> Result<bool, BadInterp> {
        self.default_return()
    }

    fn on_return_bucket(&self, _: &ReturnBucket, _: &Env) -> Result<bool, BadInterp> {
        self.default_return()
    }

    fn on_log_bucket(&self, _: &LogBucket, _: &Env) -> Result<bool, BadInterp> {
        self.default_return()
    }

    fn ignore_function_calls(&self) -> bool {
        true
    }

    fn ignore_extracted_function_calls(&self) -> bool {
        true
    }
}
