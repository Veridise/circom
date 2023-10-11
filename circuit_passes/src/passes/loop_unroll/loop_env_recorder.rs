use std::cell::{RefCell, Ref};
use std::collections::BTreeMap;
use std::fmt::{Debug, Formatter};
use indexmap::IndexMap;
use compiler::intermediate_representation::BucketId;
use compiler::intermediate_representation::ir_interface::*;
use crate::bucket_interpreter::env::Env;
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::observer::InterpreterObserver;
use crate::bucket_interpreter::value::Value;
use crate::passes::GlobalPassData;
use super::body_extractor::{UnrolledIterLvars, ToOriginalLocation};

/// Holds values of index variables at array loads/stores within a loop
pub struct VariableValues<'a> {
    pub env_at_header: Env<'a>,
    /// The key is the ID of the load/store bucket where the reference is located.
    /// NOTE: uses IndexMap to preserve insertion order to stabilize test output.
    pub loadstore_to_index: IndexMap<BucketId, (AddressType, Value)>,
}

impl<'a> VariableValues<'a> {
    pub fn new(env_at_header: Env<'a>) -> Self {
        VariableValues { env_at_header, loadstore_to_index: Default::default() }
    }
}

impl Debug for VariableValues<'_> {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        let print_header_env = false;
        if print_header_env {
            write!(
                f,
                "\n{{\n env_at_header = {}\n loadstore_to_index = {:?}\n}}",
                self.env_at_header, self.loadstore_to_index
            )
        } else {
            write!(f, "\n  loadstore_to_index = {:?}\n", self.loadstore_to_index)
        }
    }
}

pub struct EnvRecorder<'a, 'd> {
    global_data: &'d RefCell<GlobalPassData>,
    mem: &'a PassMemory,
    // NOTE: RefCell is needed here because the instance of this struct is borrowed by
    //  the main interpreter while we also need to mutate these internal structures.
    current_iter_num: RefCell<usize>,
    safe_to_move: RefCell<bool>,
    //NOTE: use BTreeMap instead of HashMap for consistent ordering of args in test cases
    vals_per_iteration: RefCell<BTreeMap<usize, VariableValues<'a>>>, // key is iteration number
}

impl Debug for EnvRecorder<'_, '_> {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "\n current_iter_num = {}\n safe_to_move = {:?}\n vals_per_iteration = {:?}",
            self.current_iter_num.borrow(),
            self.safe_to_move.borrow(),
            self.vals_per_iteration.borrow(),
        )
    }
}

impl<'a, 'd> EnvRecorder<'a, 'd> {
    pub fn new(global_data: &'d RefCell<GlobalPassData>, mem: &'a PassMemory) -> Self {
        EnvRecorder {
            global_data,
            mem,
            vals_per_iteration: Default::default(),
            current_iter_num: RefCell::new(0),
            safe_to_move: RefCell::new(true),
        }
    }

    pub fn get_vals_per_iter(&self) -> Ref<BTreeMap<usize, VariableValues<'a>>> {
        self.vals_per_iteration.borrow()
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

    pub fn record_env_at_header(&self, env: Env<'a>) {
        let iter = self.get_iter();
        assert!(!self.vals_per_iteration.borrow().contains_key(&iter));
        self.vals_per_iteration.borrow_mut().insert(iter, VariableValues::new(env));
    }

    pub fn get_header_env_clone(&self) -> Env {
        let iter = self.get_iter();
        assert!(self.vals_per_iteration.borrow().contains_key(&iter));
        self.vals_per_iteration.borrow().get(&iter).unwrap().env_at_header.clone()
    }

    pub fn record_reverse_arg_mapping(
        &self,
        extract_func: String,
        iter_env: UnrolledIterLvars,
        value: ToOriginalLocation,
    ) {
        self.global_data
            .borrow_mut()
            .extract_func_orig_loc
            .entry(extract_func)
            .or_default()
            .insert(iter_env, value);
    }

    fn record_memloc_at_bucket(&self, bucket_id: &BucketId, addr_ty: AddressType, val: Value) {
        let iter = self.get_iter();
        assert!(self.vals_per_iteration.borrow().contains_key(&iter));
        self.vals_per_iteration
            .borrow_mut()
            .get_mut(&iter)
            .unwrap()
            .loadstore_to_index
            .insert(*bucket_id, (addr_ty, val));
    }

    fn compute_index_from_inst(&self, env: &Env, location: &InstructionPointer) -> Value {
        // Evaluate the index using the current environment and using the environment from the
        //  loop header. If either is Unknown or they do not give the same value, then it is
        //  not safe to move the loop body to another function because the index computation may
        //  not give the same result when done at the call site, outside of the new function.
        let interp = self.mem.build_interpreter(self.global_data, self);
        let (idx_loc, _) = interp.execute_instruction(location, env.clone(), false);
        if let Some(idx_loc) = idx_loc {
            let (idx_header, _) =
                interp.execute_instruction(location, self.get_header_env_clone(), false);
            if let Some(idx_header) = idx_header {
                if Value::eq(&idx_header, &idx_loc) {
                    return idx_loc;
                }
            }
        }
        Value::Unknown
    }

    fn compute_index_from_rule(&self, env: &Env, loc: &LocationRule) -> Value {
        match loc {
            LocationRule::Mapped { .. } => todo!(), //not sure if/how to handle that
            LocationRule::Indexed { location, .. } => self.compute_index_from_inst(env, location),
        }
    }

    fn visit(&self, bucket_id: &BucketId, addr_ty: &AddressType, loc: &LocationRule, env: &Env) {
        let loc_result = self.compute_index_from_rule(env, loc);
        if loc_result == Value::Unknown {
            self.safe_to_move.replace(false);
        }
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
            let addr_result = self.compute_index_from_inst(env, cmp_address);
            self.record_memloc_at_bucket(
                bucket_id,
                AddressType::SubcmpSignal {
                    cmp_address: {
                        if addr_result == Value::Unknown {
                            self.safe_to_move.replace(false);
                            NopBucket { id: 0 }.allocate()
                        } else {
                            addr_result.to_value_bucket(self.mem).allocate()
                        }
                    },
                    uniform_parallel_value: uniform_parallel_value.clone(),
                    is_output: *is_output,
                    input_information: input_information.clone(),
                    counter_override: *counter_override,
                },
                loc_result,
            );
        } else {
            self.record_memloc_at_bucket(bucket_id, addr_ty.clone(), loc_result);
        }
    }
}

impl InterpreterObserver for EnvRecorder<'_, '_> {
    fn on_load_bucket(&self, bucket: &LoadBucket, env: &Env) -> bool {
        if let Some(_) = bucket.bounded_fn {
            todo!(); //not sure if/how to handle that
        }
        self.visit(&bucket.id, &bucket.address_type, &bucket.src, env);
        true
    }

    fn on_store_bucket(&self, bucket: &StoreBucket, env: &Env) -> bool {
        if let Some(_) = bucket.bounded_fn {
            todo!(); //not sure if/how to handle that
        }
        self.visit(&bucket.id, &bucket.dest_address_type, &bucket.dest, env);
        true
    }

    fn on_value_bucket(&self, _bucket: &ValueBucket, _env: &Env) -> bool {
        self.is_safe_to_move() //continue observing unless something unsafe has been found
    }

    fn on_compute_bucket(&self, _bucket: &ComputeBucket, _env: &Env) -> bool {
        self.is_safe_to_move() //continue observing unless something unsafe has been found
    }

    fn on_assert_bucket(&self, _bucket: &AssertBucket, _env: &Env) -> bool {
        self.is_safe_to_move() //continue observing unless something unsafe has been found
    }

    fn on_loop_bucket(&self, _bucket: &LoopBucket, _env: &Env) -> bool {
        self.is_safe_to_move() //continue observing unless something unsafe has been found
    }

    fn on_create_cmp_bucket(&self, _bucket: &CreateCmpBucket, _env: &Env) -> bool {
        self.is_safe_to_move() //continue observing unless something unsafe has been found
    }

    fn on_constraint_bucket(&self, _bucket: &ConstraintBucket, _env: &Env) -> bool {
        self.is_safe_to_move() //continue observing unless something unsafe has been found
    }

    fn on_block_bucket(&self, _bucket: &BlockBucket, _env: &Env) -> bool {
        self.is_safe_to_move() //continue observing unless something unsafe has been found
    }

    fn on_nop_bucket(&self, _bucket: &NopBucket, _env: &Env) -> bool {
        self.is_safe_to_move() //continue observing unless something unsafe has been found
    }

    fn on_location_rule(&self, _location_rule: &LocationRule, _env: &Env) -> bool {
        self.is_safe_to_move() //continue observing unless something unsafe has been found
    }

    fn on_call_bucket(&self, _bucket: &CallBucket, _env: &Env) -> bool {
        self.is_safe_to_move() //continue observing unless something unsafe has been found
    }

    fn on_branch_bucket(&self, _bucket: &BranchBucket, _env: &Env) -> bool {
        self.is_safe_to_move() //continue observing unless something unsafe has been found
    }

    fn on_return_bucket(&self, _bucket: &ReturnBucket, _env: &Env) -> bool {
        self.is_safe_to_move() //continue observing unless something unsafe has been found
    }

    fn on_log_bucket(&self, _bucket: &LogBucket, _env: &Env) -> bool {
        self.is_safe_to_move() //continue observing unless something unsafe has been found
    }

    fn ignore_function_calls(&self) -> bool {
        true
    }

    fn ignore_subcmp_calls(&self) -> bool {
        true
    }
}
