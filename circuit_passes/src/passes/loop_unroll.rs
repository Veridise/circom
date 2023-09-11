use std::cell::RefCell;
use std::collections::{BTreeMap, HashMap, HashSet};
use std::fmt::{Debug, Formatter};
use std::vec;
use code_producers::llvm_elements::fr::{FR_IDENTITY_ARR_PTR, FR_INDEX_ARR_PTR};
use compiler::circuit_design::function::{FunctionCodeInfo, FunctionCode};
use compiler::circuit_design::template::TemplateCode;
use compiler::compiler_interface::Circuit;
use compiler::hir::very_concrete_program::Param;
use compiler::intermediate_representation::{
    BucketId, InstructionList, InstructionPointer, new_id, UpdateId,
};
use compiler::intermediate_representation::ir_interface::*;
use crate::bucket_interpreter::env::Env;
use crate::bucket_interpreter::observer::InterpreterObserver;
use crate::bucket_interpreter::value::Value;
use crate::passes::{CircuitTransformationPass, LOOP_BODY_FN_PREFIX};
use crate::passes::memory::PassMemory;

const EXTRACT_LOOP_BODY_TO_NEW_FUNC: bool = true;
struct VariableValues<'a> {
    pub env_at_header: Env<'a>,
    pub loadstore_to_index: HashMap<BucketId, (AddressType, Value)>, // key is load/store bucket ID
}

impl<'a> VariableValues<'a> {
    pub fn new(env_at_header: Env<'a>) -> Self {
        VariableValues { env_at_header, loadstore_to_index: Default::default() }
    }
}

impl Debug for VariableValues<'_> {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        // write!(
        //     f,
        //     "\n{{\n env_at_header = {}\n loadstore_to_index = {:?}\n}}",
        //     self.env_at_header, self.loadstore_to_index
        // )
        write!(f, "\n  loadstore_to_index = {:?}\n", self.loadstore_to_index)
    }
}

struct EnvRecorder<'a> {
    mem: &'a PassMemory,
    // NOTE: RefCell is needed here because the instance of this struct is borrowed by
    //  the main interpreter while we also need to mutate these internal structures.
    vals_per_iteration: RefCell<HashMap<usize, VariableValues<'a>>>, // key is iteration number
    current_iter_num: RefCell<usize>,
    safe_to_move: RefCell<bool>,
}

impl Debug for EnvRecorder<'_> {
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

impl<'a> EnvRecorder<'a> {
    pub fn new(mem: &'a PassMemory) -> Self {
        EnvRecorder {
            mem,
            vals_per_iteration: Default::default(),
            current_iter_num: RefCell::new(0),
            safe_to_move: RefCell::new(true),
        }
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

    fn compute_index(&self, loc: &LocationRule, env: &Env) -> Value {
        match loc {
            LocationRule::Mapped { .. } => {
                todo!(); //not sure if/how to handle that
            }
            LocationRule::Indexed { location, .. } => {
                // Evaluate the index using the current environment and using the environment from the
                //  loop header. If either is Unknown or they do not give the same value, then it is
                //  not safe to move the loop body to another function because the index computation may
                //  not give the same result when done at the call site, outside of the new function.
                let interp = self.mem.build_interpreter(self);
                let (idx_loc, _) = interp.execute_instruction(location, env.clone(), false);
                // println!("--   LOC: var/sig[{:?}]", idx_loc); //TODO: TEMP
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
        }
    }

    fn check(&self, bucket_id: &BucketId, addr_ty: &AddressType, loc: &LocationRule, env: &Env) {
        let val_result = self.compute_index(loc, env);
        if val_result == Value::Unknown {
            self.safe_to_move.replace(false);
        }
        //NOTE: must record even when Unknown to ensure that Unknown
        //  value is not confused with missing values for an iteration
        //  that can be caused by conditionals within the loop.
        self.record_memloc_at_bucket(bucket_id, addr_ty.clone(), val_result);
    }
}

impl InterpreterObserver for EnvRecorder<'_> {
    fn on_load_bucket(&self, bucket: &LoadBucket, env: &Env) -> bool {
        if let Some(_) = bucket.bounded_fn {
            todo!(); //not sure if/how to handle that
        }
        self.check(&bucket.id, &bucket.address_type, &bucket.src, env);
        true
    }

    fn on_store_bucket(&self, bucket: &StoreBucket, env: &Env) -> bool {
        if let Some(_) = bucket.bounded_fn {
            todo!(); //not sure if/how to handle that
        }
        self.check(&bucket.id, &bucket.dest_address_type, &bucket.dest, env);
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

pub struct LoopUnrollPass {
    // Wrapped in a RefCell because the reference to the static analysis is immutable but we need mutability
    memory: PassMemory,
    replacements: RefCell<BTreeMap<BucketId, InstructionPointer>>,
    new_body_functions: RefCell<Vec<FunctionCode>>,
}

impl LoopUnrollPass {
    pub fn new(prime: &String) -> Self {
        LoopUnrollPass {
            memory: PassMemory::new(prime, String::from(""), Default::default()),
            replacements: Default::default(),
            new_body_functions: Default::default(),
        }
    }

    fn check_load_bucket(
        &self,
        bucket: &mut LoadBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        if let Some(x) = bucket_arg_order.remove(&bucket.id) {
            // Update the destination information to reference the argument
            //NOTE: This can't use AddressType::Variable or AddressType::Signal
            //  because ExtractedFunctionLLVMIRProducer references the first two
            //  parameters with those. So this has to use SubcmpSignal (it should
            //  work fine because subcomps will also just be additional params).
            bucket.address_type = AddressType::SubcmpSignal {
                cmp_address: Self::new_u32_value(bucket, x),
                uniform_parallel_value: None,
                is_output: false,
                input_information: InputInformation::NoInput,
            };
            bucket.src = LocationRule::Indexed {
                location: Self::new_u32_value(bucket, 0), //use index 0 to ref the entire storage array
                template_header: None,
            };
        } else {
            // If not replacing, check deeper in the AddressType and LocationRule
            self.check_address_type(&mut bucket.address_type, bucket_arg_order);
            self.check_location_rule(&mut bucket.src, bucket_arg_order);
        }
    }

    fn check_store_bucket(
        &self,
        bucket: &mut StoreBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        // Check the source/RHS of the store in either case
        self.check_instruction(&mut bucket.src, bucket_arg_order);
        //
        if let Some(x) = bucket_arg_order.remove(&bucket.id) {
            // Update the destination information to reference the argument
            bucket.dest_address_type = AddressType::SubcmpSignal {
                cmp_address: Self::new_u32_value(bucket, x),
                uniform_parallel_value: None,
                is_output: false,
                input_information: InputInformation::NoInput,
            };
            bucket.dest = LocationRule::Indexed {
                location: Self::new_u32_value(bucket, 0), //use index 0 to ref the entire storage array
                template_header: None,
            };
        } else {
            // If not replacing, check deeper in the AddressType and LocationRule
            self.check_address_type(&mut bucket.dest_address_type, bucket_arg_order);
            self.check_location_rule(&mut bucket.dest, bucket_arg_order);
        }
    }

    fn check_location_rule(
        &self,
        location_rule: &mut LocationRule,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        match location_rule {
            LocationRule::Indexed { location, .. } => {
                self.check_instruction(location, bucket_arg_order);
            }
            LocationRule::Mapped { .. } => unreachable!(),
        }
    }

    fn check_address_type(
        &self,
        addr_type: &mut AddressType,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        if let AddressType::SubcmpSignal { cmp_address, .. } = addr_type {
            self.check_instruction(cmp_address, bucket_arg_order);
        }
    }

    fn check_compute_bucket(
        &self,
        bucket: &mut ComputeBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        for i in &mut bucket.stack {
            self.check_instruction(i, bucket_arg_order);
        }
    }

    fn check_assert_bucket(
        &self,
        bucket: &mut AssertBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        self.check_instruction(&mut bucket.evaluate, bucket_arg_order);
    }

    fn check_loop_bucket(
        &self,
        bucket: &mut LoopBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        todo!()
    }

    fn check_create_cmp_bucket(
        &self,
        bucket: &mut CreateCmpBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        todo!()
    }

    fn check_constraint_bucket(
        &self,
        bucket: &mut ConstraintBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        self.check_instruction(
            match bucket {
                ConstraintBucket::Substitution(i) => i,
                ConstraintBucket::Equality(i) => i,
            },
            bucket_arg_order,
        );
    }

    fn check_block_bucket(
        &self,
        bucket: &mut BlockBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        todo!()
    }

    fn check_call_bucket(
        &self,
        bucket: &mut CallBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        todo!()
    }

    fn check_branch_bucket(
        &self,
        bucket: &mut BranchBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        todo!()
    }

    fn check_return_bucket(
        &self,
        bucket: &mut ReturnBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        self.check_instruction(&mut bucket.value, bucket_arg_order);
    }

    fn check_log_bucket(
        &self,
        bucket: &mut LogBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        for arg in &mut bucket.argsprint {
            if let LogBucketArg::LogExp(i) = arg {
                self.check_instruction(i, bucket_arg_order);
            }
        }
    }

    //Nothing to do
    fn check_value_bucket(&self, _: &mut ValueBucket, _: &mut BTreeMap<BucketId, usize>) {}
    fn check_nop_bucket(&self, _: &mut NopBucket, _: &mut BTreeMap<BucketId, usize>) {}

    fn check_instruction(
        &self,
        inst: &mut InstructionPointer,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        match inst.as_mut() {
            Instruction::Value(ref mut b) => self.check_value_bucket(b, bucket_arg_order),
            Instruction::Load(ref mut b) => self.check_load_bucket(b, bucket_arg_order),
            Instruction::Store(ref mut b) => self.check_store_bucket(b, bucket_arg_order),
            Instruction::Compute(ref mut b) => self.check_compute_bucket(b, bucket_arg_order),
            Instruction::Call(ref mut b) => self.check_call_bucket(b, bucket_arg_order),
            Instruction::Branch(ref mut b) => self.check_branch_bucket(b, bucket_arg_order),
            Instruction::Return(ref mut b) => self.check_return_bucket(b, bucket_arg_order),
            Instruction::Assert(ref mut b) => self.check_assert_bucket(b, bucket_arg_order),
            Instruction::Log(ref mut b) => self.check_log_bucket(b, bucket_arg_order),
            Instruction::Loop(ref mut b) => self.check_loop_bucket(b, bucket_arg_order),
            Instruction::CreateCmp(ref mut b) => self.check_create_cmp_bucket(b, bucket_arg_order),
            Instruction::Constraint(ref mut b) => self.check_constraint_bucket(b, bucket_arg_order),
            Instruction::Block(ref mut b) => self.check_block_bucket(b, bucket_arg_order),
            Instruction::Nop(ref mut b) => self.check_nop_bucket(b, bucket_arg_order),
        }
    }

    fn extract_body(
        &self,
        bucket: &LoopBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) -> String {
        // NOTE: must create parameter list before 'bucket_arg_order' is modified
        let mut params = vec![
            Param { name: String::from("lvars"), length: vec![0] },
            Param { name: String::from("signals"), length: vec![0] },
        ];
        for i in 0..bucket_arg_order.len() {
            params.push(Param { name: format!("fixed_{}", i), length: vec![0] });
        }

        // Copy loop body and add a "return void" at the end
        let mut new_body = vec![];
        for s in &bucket.body {
            let mut copy: InstructionPointer = s.clone();
            if !bucket_arg_order.is_empty() {
                //Traverse each cloned statement before calling `update_id()` and replace the
                //  old location reference with reference to the proper argument. Mappings are
                //  removed as they are processed so no change is needed once the map is empty.
                self.check_instruction(&mut copy, bucket_arg_order);
            }
            copy.update_id();
            new_body.push(copy);
        }
        assert!(bucket_arg_order.is_empty());
        new_body.push(
            ReturnBucket {
                id: new_id(),
                source_file_id: bucket.source_file_id,
                line: bucket.line,
                message_id: bucket.message_id,
                with_size: usize::MAX, // size > 1 will produce "return void" LLVM instruction
                value: NopBucket { id: new_id() }.allocate(),
            }
            .allocate(),
        );
        // Create new function to hold the copied body
        // NOTE: Must start with `GENERATED_FN_PREFIX` to use `ExtractedFunctionCtx`
        let func_name = format!("{}{}", LOOP_BODY_FN_PREFIX, new_id());
        let new_func = Box::new(FunctionCodeInfo {
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            name: func_name.clone(),
            header: func_name.clone(),
            body: new_body,
            params,
            returns: vec![], // void return type on the function
            ..FunctionCodeInfo::default()
        });
        // Store the function to be transformed and added to circuit later
        self.new_body_functions.borrow_mut().push(new_func);
        func_name
    }

    fn new_u32_value(bucket: &dyn ObtainMeta, val: usize) -> InstructionPointer {
        ValueBucket {
            id: new_id(),
            source_file_id: bucket.get_source_file_id().clone(),
            line: bucket.get_line(),
            message_id: bucket.get_message_id(),
            parse_as: ValueType::U32,
            op_aux_no: 0,
            value: val,
        }
        .allocate()
    }
    fn new_custom_fn_load_bucket(
        bucket: &dyn ObtainMeta,
        load_fun: &str,
        addr_type: AddressType,
        location: InstructionPointer,
    ) -> InstructionPointer {
        LoadBucket {
            id: new_id(),
            source_file_id: bucket.get_source_file_id().clone(),
            line: bucket.get_line(),
            message_id: bucket.get_message_id(),
            address_type: addr_type,
            src: LocationRule::Indexed { location, template_header: None },
            bounded_fn: Some(String::from(load_fun)),
        }
        .allocate()
    }

    fn new_storage_ptr_ref(bucket: &dyn ObtainMeta, addr_type: AddressType) -> InstructionPointer {
        Self::new_custom_fn_load_bucket(
            bucket,
            FR_IDENTITY_ARR_PTR,
            addr_type,
            Self::new_u32_value(bucket, 0), //use index 0 to ref the entire storage array
        )
    }

    //NOTE: When the 'bounded_fn' for LoadBucket is Some(_), the index parameter
    //  is ignored so we must instead use `FR_INDEX_ARR_PTR` to apply the index.
    //  Uses of that function can be inlined later.
    // NOTE: Must start with `GENERATED_FN_PREFIX` to use `ExtractedFunctionCtx`
    fn new_indexed_storage_ptr_ref(
        bucket: &dyn ObtainMeta,
        addr_type: AddressType,
        index: usize,
    ) -> InstructionPointer {
        CallBucket {
            id: new_id(),
            source_file_id: bucket.get_source_file_id().clone(),
            line: bucket.get_line(),
            message_id: bucket.get_message_id(),
            symbol: String::from(FR_INDEX_ARR_PTR),
            return_info: ReturnType::Intermediate { op_aux_no: 0 },
            arena_size: 0, // size 0 indicates arguments should not be placed into an arena
            argument_types: vec![], // LLVM IR generation doesn't use this field
            arguments: vec![
                Self::new_storage_ptr_ref(bucket, addr_type),
                Self::new_u32_value(bucket, index),
            ],
        }
        .allocate()
    }

    fn is_all_same(data: &[usize]) -> bool {
        data.iter()
            .fold((true, None), {
                |acc, elem| {
                    if acc.1.is_some() {
                        (acc.0 && (acc.1.unwrap() == elem), Some(elem))
                    } else {
                        (true, Some(elem))
                    }
                }
            })
            .0
    }

    //return value key is iteration number
    fn compute_extra_args(
        recorder: &EnvRecorder,
    ) -> (HashMap<usize, Vec<(AddressType, Value)>>, BTreeMap<BucketId, usize>) {
        let mut iter_to_loc: HashMap<usize, Vec<(AddressType, Value)>> = HashMap::default();
        let mut bucket_arg_order = BTreeMap::new();
        let vpi = recorder.vals_per_iteration.borrow();
        let all_loadstore_bucket_ids: HashSet<&BucketId> =
            vpi.values().flat_map(|x| x.loadstore_to_index.keys()).collect();
        // println!("all_loadstore_bucket_ids = {:?}", all_loadstore_bucket_ids);
        for id in all_loadstore_bucket_ids {
            // Check if the computed index value is the same across all iterations for this BucketId.
            //  If it is not the same in all iterations, then it needs to be passed as a separate
            //  parameter to the new function.
            // NOTE: Some iterations of the loop may have no mapping for certain BucketIds because
            //  conditional branches can make certain buckets unused in some iterations. Just ignore
            //  those cases where there is no value for a certain iteration and check among those
            //  iterations that have a value. This is the reason it was important to store Unknown
            //  values in the `loadstore_to_index` index as well, so they are not confused with
            //  missing values.
            let mut next_iter_to_store = 0;
            let mut prev_val = None;
            for curr_iter in 0..recorder.get_iter() {
                let curr_val = vpi[&curr_iter].loadstore_to_index.get(id);
                if curr_val.is_some() {
                    if prev_val.is_none() {
                        //initial state
                        prev_val = curr_val;
                    } else {
                        assert!(prev_val.is_some() && curr_val.is_some());
                        let prev_val_pair = prev_val.unwrap();
                        let curr_val_pair = curr_val.unwrap();
                        assert_eq!(prev_val_pair.0, curr_val_pair.0); //AddressType always matches
                        if !Value::eq(&prev_val_pair.1, &curr_val_pair.1) {
                            assert!(!prev_val_pair.1.is_unknown() && !curr_val_pair.1.is_unknown());
                            // Store current Value for current iteration
                            iter_to_loc.entry(curr_iter).or_default().push(curr_val_pair.clone());
                            // Store previous Value for all iterations that did have the same
                            //  value (or None) and have not yet been stored.
                            for j in next_iter_to_store..curr_iter {
                                iter_to_loc.entry(j).or_default().push(prev_val_pair.clone());
                            }
                            // Update for next iteration
                            next_iter_to_store = curr_iter + 1;
                            prev_val = curr_val;
                        }
                    }
                }
            }
            //ASSERT: All vectors have the same length at the end of each iteration
            assert!(Self::is_all_same(&iter_to_loc.values().map(|x| x.len()).collect::<Vec<_>>()));
            //ASSERT: Value was added for every iteration or for no iterations
            assert!(next_iter_to_store == 0 || next_iter_to_store == recorder.get_iter());
            //
            if next_iter_to_store != 0 {
                bucket_arg_order.insert(id.clone(), bucket_arg_order.len());
            }
        }
        (iter_to_loc, bucket_arg_order)
    }

    fn try_unroll_loop(&self, bucket: &LoopBucket, env: &Env) -> (Option<InstructionList>, usize) {
        // {
        //     println!("\nTry unrolling loop {}:", bucket.id); //TODO: TEMP
        //     for (i, s) in bucket.body.iter().enumerate() {
        //         println!("[{}/{}]{}", i + 1, bucket.body.len(), s.to_sexp().to_pretty(100));
        //     }
        //     for (i, s) in bucket.body.iter().enumerate() {
        //         println!("[{}/{}]{:?}", i + 1, bucket.body.len(), s);
        //     }
        //     println!("LOOP ENTRY env {}", env); //TODO: TEMP
        // }
        // Compute loop iteration count. If unknown, return immediately.
        let recorder = EnvRecorder::new(&self.memory);
        {
            //TODO: This has the wrong scope if an inner function w/ fixed params will be processed! Need test case for it.
            //  Can't make it crash. Maybe it's not activating in current setup, it was only when I tried to process the other functions?
            let interpreter = self.memory.build_interpreter(&recorder);
            let mut inner_env = env.clone();
            loop {
                recorder.record_env_at_header(inner_env.clone());
                let (_, cond, new_env) =
                    interpreter.execute_loop_bucket_once(bucket, inner_env, true);
                match cond {
                    // If the conditional becomes unknown just give up.
                    None => return (None, 0),
                    // When conditional becomes `false`, iteration count is complete.
                    Some(false) => break,
                    // Otherwise, continue counting.
                    Some(true) => recorder.increment_iter(),
                };
                inner_env = new_env;
            }
        }
        // println!("recorder = {:?}", recorder); //TODO: TEMP

        let mut block_body = vec![];
        if EXTRACT_LOOP_BODY_TO_NEW_FUNC && recorder.is_safe_to_move() {
            // If the loop body contains more than one instruction, extract it into a new
            // function and generate 'recorder.get_iter()' number of calls to that function.
            // Otherwise, just duplicate the body 'recorder.get_iter()' number of times.
            match &bucket.body[..] {
                [a] => {
                    for _ in 0..recorder.get_iter() {
                        let mut copy = a.clone();
                        copy.update_id();
                        block_body.push(copy);
                    }
                }
                b => {
                    assert!(b.len() > 1);
                    let (iter_to_loc, mut bucket_arg_order) = Self::compute_extra_args(&recorder);
                    let name = self.extract_body(bucket, &mut bucket_arg_order);
                    for iter_num in 0..recorder.get_iter() {
                        // NOTE: CallBucket arguments must use a LoadBucket to reference the necessary pointers
                        //  within the current body. However, it doesn't actually need to generate a load
                        //  instruction to use these pointers as parameters to the function so we must use the
                        //  `bounded_fn` field of the LoadBucket to specify the identity function to perform
                        //  the "loading" (but really it just returns the pointer that was passed in).
                        let mut args = InstructionList::default();
                        // Parameter for local vars
                        args.push(Self::new_storage_ptr_ref(bucket, AddressType::Variable));
                        // Parameter for signals/arena
                        args.push(Self::new_storage_ptr_ref(bucket, AddressType::Signal));
                        // Additional parameters for variant vector/array access within the loop
                        if !iter_to_loc.is_empty() {
                            for a in &iter_to_loc[&iter_num] {
                                args.push(Self::new_indexed_storage_ptr_ref(
                                    bucket,
                                    a.0.clone(),
                                    a.1.get_u32(),
                                ));
                            }
                        }
                        block_body.push(
                            CallBucket {
                                id: new_id(),
                                source_file_id: bucket.source_file_id,
                                line: bucket.line,
                                message_id: bucket.message_id,
                                symbol: name.clone(),
                                return_info: ReturnType::Intermediate { op_aux_no: 0 },
                                arena_size: 0, // size 0 indicates arguments should not be placed into an arena
                                argument_types: vec![], // LLVM IR generation doesn't use this field
                                arguments: args,
                            }
                            .allocate(),
                        );
                    }
                }
            }
        } else {
            //If the loop body is not safe to move into a new function, just unroll.
            for _ in 0..recorder.get_iter() {
                for s in &bucket.body {
                    let mut copy = s.clone();
                    copy.update_id();
                    block_body.push(copy);
                }
            }
        }
        (Some(block_body), recorder.get_iter())
    }

    // Will take the unrolled loop and interpretate it
    // checking if new loop buckets appear
    fn continue_inside(&self, bucket: &BlockBucket, env: &Env) {
        let interpreter = self.memory.build_interpreter(self);
        interpreter.execute_block_bucket(bucket, env.clone(), true);
    }
}

impl InterpreterObserver for LoopUnrollPass {
    fn on_value_bucket(&self, _bucket: &ValueBucket, _env: &Env) -> bool {
        true
    }

    fn on_load_bucket(&self, _bucket: &LoadBucket, _env: &Env) -> bool {
        true
    }

    fn on_store_bucket(&self, _bucket: &StoreBucket, _env: &Env) -> bool {
        true
    }

    fn on_compute_bucket(&self, _bucket: &ComputeBucket, _env: &Env) -> bool {
        true
    }

    fn on_assert_bucket(&self, _bucket: &AssertBucket, _env: &Env) -> bool {
        true
    }

    fn on_loop_bucket(&self, bucket: &LoopBucket, env: &Env) -> bool {
        if let (Some(block_body), n_iters) = self.try_unroll_loop(bucket, env) {
            let block = BlockBucket {
                id: new_id(),
                source_file_id: bucket.source_file_id,
                line: bucket.line,
                message_id: bucket.message_id,
                body: block_body,
                n_iters,
            };
            self.continue_inside(&block, env);
            self.replacements.borrow_mut().insert(bucket.id, block.allocate());
        }
        false
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

impl CircuitTransformationPass for LoopUnrollPass {
    fn name(&self) -> &str {
        "LoopUnrollPass"
    }

    fn pre_hook_circuit(&self, circuit: &Circuit) {
        self.memory.fill_from_circuit(circuit);
    }

    fn post_hook_circuit(&self, cir: &mut Circuit) {
        // Normalize return type on source functions for "WriteLLVMIR for Circuit"
        //  which treats a 1-D vector of size 1 as a scalar return and an empty
        //  vector as "void" return type (the initial Circuit builder uses empty
        //  for scalar returns because it doesn't consider "void" return possible).
        for f in &mut cir.functions {
            if f.returns.is_empty() {
                f.returns = vec![1];
            }
        }
        // Transform and add the new body functions
        for f in self.new_body_functions.borrow().iter() {
            cir.functions.push(self.transform_function(&f));
        }
    }

    fn pre_hook_template(&self, template: &TemplateCode) {
        self.memory.set_scope(template);
        self.memory.run_template(self, template);
    }

    fn get_updated_field_constants(&self) -> Vec<String> {
        self.memory.get_field_constants_clone()
    }

    fn transform_loop_bucket(&self, bucket: &LoopBucket) -> InstructionPointer {
        if let Some(unrolled_loop) = self.replacements.borrow().get(&bucket.id) {
            return self.transform_instruction(unrolled_loop);
        }
        LoopBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            continue_condition: self.transform_instruction(&bucket.continue_condition),
            body: self.transform_instructions(&bucket.body),
        }
        .allocate()
    }
}

#[cfg(test)]
mod test {
    use std::collections::HashMap;
    use compiler::circuit_design::template::TemplateCodeInfo;
    use compiler::compiler_interface::Circuit;
    use compiler::intermediate_representation::{Instruction, new_id};
    use compiler::intermediate_representation::ir_interface::{
        AddressType, Allocate, ComputeBucket, InstrContext, LoadBucket, LocationRule, LoopBucket,
        OperatorType, StoreBucket, ValueBucket, ValueType,
    };
    use crate::passes::{CircuitTransformationPass, LOOP_BODY_FN_PREFIX};
    use crate::passes::loop_unroll::LoopUnrollPass;

    #[test]
    fn test_loop_unrolling() {
        let prime = "goldilocks".to_string();
        let pass = LoopUnrollPass::new(&prime);
        let mut circuit = example_program();
        circuit.llvm_data.variable_index_mapping.insert("test_0".to_string(), HashMap::new());
        circuit.llvm_data.signal_index_mapping.insert("test_0".to_string(), HashMap::new());
        circuit.llvm_data.component_index_mapping.insert("test_0".to_string(), HashMap::new());
        let new_circuit = pass.transform_circuit(&circuit);
        if cfg!(debug_assertions) {
            println!("{}", new_circuit.templates[0].body.last().unwrap().to_string());
        }
        assert_ne!(circuit, new_circuit);
        match new_circuit.templates[0].body.last().unwrap().as_ref() {
            Instruction::Block(b) => {
                // 5 iterations unrolled into 5 call statements targeting extracted loop body functions
                assert_eq!(b.body.len(), 5);
                assert!(b.body.iter().all(|s| if let Instruction::Call(c) = s.as_ref() {
                    c.symbol.starts_with(LOOP_BODY_FN_PREFIX)
                } else {
                    false
                }));
            }
            _ => assert!(false),
        }
    }

    fn example_program() -> Circuit {
        Circuit {
            wasm_producer: Default::default(),
            c_producer: Default::default(),
            llvm_data: Default::default(),
            templates: vec![Box::new(TemplateCodeInfo {
                id: 0,
                source_file_id: None,
                line: 0,
                header: "test_0".to_string(),
                name: "test".to_string(),
                is_parallel: false,
                is_parallel_component: false,
                is_not_parallel_component: false,
                has_parallel_sub_cmp: false,
                number_of_inputs: 0,
                number_of_outputs: 0,
                number_of_intermediates: 0,
                body: vec![
                    // (store 0 0)
                    StoreBucket {
                        id: new_id(),
                        source_file_id: None,
                        line: 0,
                        message_id: 0,
                        context: InstrContext { size: 0 },
                        dest_is_output: false,
                        dest_address_type: AddressType::Variable,
                        dest: LocationRule::Indexed {
                            location: ValueBucket {
                                id: new_id(),
                                source_file_id: None,
                                line: 0,
                                message_id: 0,
                                parse_as: ValueType::U32,
                                op_aux_no: 0,
                                value: 0,
                            }
                            .allocate(),
                            template_header: Some("test_0".to_string()),
                        },
                        src: ValueBucket {
                            id: new_id(),
                            source_file_id: None,
                            line: 0,
                            message_id: 0,
                            parse_as: ValueType::U32,
                            op_aux_no: 0,
                            value: 0,
                        }
                        .allocate(),
                        bounded_fn: None,
                    }
                    .allocate(),
                    // (store 1 0)
                    StoreBucket {
                        id: new_id(),
                        source_file_id: None,
                        line: 0,
                        message_id: 0,
                        context: InstrContext { size: 0 },
                        dest_is_output: false,
                        dest_address_type: AddressType::Variable,
                        dest: LocationRule::Indexed {
                            location: ValueBucket {
                                id: new_id(),
                                source_file_id: None,
                                line: 0,
                                message_id: 0,
                                parse_as: ValueType::U32,
                                op_aux_no: 0,
                                value: 1,
                            }
                            .allocate(),
                            template_header: Some("test_0".to_string()),
                        },
                        src: ValueBucket {
                            id: new_id(),
                            source_file_id: None,
                            line: 0,
                            message_id: 0,
                            parse_as: ValueType::U32,
                            op_aux_no: 0,
                            value: 0,
                        }
                        .allocate(),
                        bounded_fn: None,
                    }
                    .allocate(),
                    // (loop (compute le (load 1) 5) (
                    LoopBucket {
                        id: new_id(),
                        source_file_id: None,
                        line: 0,
                        message_id: 0,
                        continue_condition: ComputeBucket {
                            id: new_id(),
                            source_file_id: None,
                            line: 0,
                            message_id: 0,
                            op: OperatorType::Lesser,
                            op_aux_no: 0,
                            stack: vec![
                                LoadBucket {
                                    id: new_id(),
                                    source_file_id: None,
                                    line: 0,
                                    message_id: 0,
                                    address_type: AddressType::Variable,
                                    src: LocationRule::Indexed {
                                        location: ValueBucket {
                                            id: new_id(),
                                            source_file_id: None,
                                            line: 0,
                                            message_id: 0,
                                            parse_as: ValueType::U32,
                                            op_aux_no: 0,
                                            value: 1,
                                        }
                                        .allocate(),
                                        template_header: Some("test_0".to_string()),
                                    },
                                    bounded_fn: None,
                                }
                                .allocate(),
                                ValueBucket {
                                    id: new_id(),
                                    source_file_id: None,
                                    line: 0,
                                    message_id: 0,
                                    parse_as: ValueType::U32,
                                    op_aux_no: 0,
                                    value: 5,
                                }
                                .allocate(),
                            ],
                        }
                        .allocate(),
                        body: vec![
                            //   (store 0 (compute add (load 0) 2))
                            StoreBucket {
                                id: new_id(),
                                source_file_id: None,
                                line: 0,
                                message_id: 0,
                                context: InstrContext { size: 0 },
                                dest_is_output: false,
                                dest_address_type: AddressType::Variable,
                                dest: LocationRule::Indexed {
                                    location: ValueBucket {
                                        id: new_id(),
                                        source_file_id: None,
                                        line: 0,
                                        message_id: 0,
                                        parse_as: ValueType::U32,
                                        op_aux_no: 0,
                                        value: 0,
                                    }
                                    .allocate(),
                                    template_header: None,
                                },
                                src: ComputeBucket {
                                    id: new_id(),
                                    source_file_id: None,
                                    line: 0,
                                    message_id: 0,
                                    op: OperatorType::Add,
                                    op_aux_no: 0,
                                    stack: vec![
                                        LoadBucket {
                                            id: new_id(),
                                            source_file_id: None,
                                            line: 0,
                                            message_id: 0,
                                            address_type: AddressType::Variable,
                                            src: LocationRule::Indexed {
                                                location: ValueBucket {
                                                    id: new_id(),
                                                    source_file_id: None,
                                                    line: 0,
                                                    message_id: 0,
                                                    parse_as: ValueType::U32,
                                                    op_aux_no: 0,
                                                    value: 0,
                                                }
                                                .allocate(),
                                                template_header: Some("test_0".to_string()),
                                            },
                                            bounded_fn: None,
                                        }
                                        .allocate(),
                                        ValueBucket {
                                            id: new_id(),
                                            source_file_id: None,
                                            line: 0,
                                            message_id: 0,
                                            parse_as: ValueType::U32,
                                            op_aux_no: 0,
                                            value: 2,
                                        }
                                        .allocate(),
                                    ],
                                }
                                .allocate(),
                                bounded_fn: None,
                            }
                            .allocate(),
                            //   (store 1 (compute add (load 1) 1))
                            StoreBucket {
                                id: new_id(),
                                source_file_id: None,
                                line: 0,
                                message_id: 0,
                                context: InstrContext { size: 0 },
                                dest_is_output: false,
                                dest_address_type: AddressType::Variable,
                                dest: LocationRule::Indexed {
                                    location: ValueBucket {
                                        id: new_id(),
                                        source_file_id: None,
                                        line: 0,
                                        message_id: 0,
                                        parse_as: ValueType::U32,
                                        op_aux_no: 0,
                                        value: 1,
                                    }
                                    .allocate(),
                                    template_header: None,
                                },
                                src: ComputeBucket {
                                    id: new_id(),
                                    source_file_id: None,
                                    line: 0,
                                    message_id: 0,
                                    op: OperatorType::Add,
                                    op_aux_no: 0,
                                    stack: vec![
                                        LoadBucket {
                                            id: new_id(),
                                            source_file_id: None,
                                            line: 0,
                                            message_id: 0,
                                            address_type: AddressType::Variable,
                                            src: LocationRule::Indexed {
                                                location: ValueBucket {
                                                    id: new_id(),
                                                    source_file_id: None,
                                                    line: 0,
                                                    message_id: 0,
                                                    parse_as: ValueType::U32,
                                                    op_aux_no: 0,
                                                    value: 1,
                                                }
                                                .allocate(),
                                                template_header: Some("test_0".to_string()),
                                            },
                                            bounded_fn: None,
                                        }
                                        .allocate(),
                                        ValueBucket {
                                            id: new_id(),
                                            source_file_id: None,
                                            line: 0,
                                            message_id: 0,
                                            parse_as: ValueType::U32,
                                            op_aux_no: 0,
                                            value: 1,
                                        }
                                        .allocate(),
                                    ],
                                }
                                .allocate(),
                                bounded_fn: None,
                            }
                            .allocate(),
                        ],
                    }
                    .allocate(), // ))
                ],
                var_stack_depth: 0,
                expression_stack_depth: 0,
                signal_stack_depth: 0,
                number_of_components: 0,
            })],
            functions: vec![],
        }
    }
}
