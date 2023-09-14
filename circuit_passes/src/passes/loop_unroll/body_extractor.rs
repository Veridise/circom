use std::cell::{RefCell, Ref};
use std::collections::{BTreeMap, HashMap, HashSet};
use std::vec;
use code_producers::llvm_elements::fr::{FR_IDENTITY_ARR_PTR, FR_INDEX_ARR_PTR};
use compiler::circuit_design::function::{FunctionCodeInfo, FunctionCode};
use compiler::hir::very_concrete_program::Param;
use compiler::intermediate_representation::{
    BucketId, InstructionList, InstructionPointer, new_id, UpdateId,
};
use compiler::intermediate_representation::ir_interface::*;
use crate::bucket_interpreter::value::Value;
use crate::passes::loop_unroll::extracted_location_updater::ExtractedFunctionLocationUpdater;
use crate::passes::LOOP_BODY_FN_PREFIX;
use crate::passes::loop_unroll::loop_env_recorder::EnvRecorder;

use super::new_u32_value;

#[derive(Clone, Debug, Eq, PartialEq, Default)]
pub struct LoopBodyExtractor {
    new_body_functions: RefCell<Vec<FunctionCode>>,
}

impl LoopBodyExtractor {
    pub fn get_new_functions(&self) -> Ref<Vec<FunctionCode>> {
        self.new_body_functions.borrow()
    }

    pub fn extract(
        &self,
        bucket: &LoopBucket,
        recorder: &EnvRecorder,
        unrolled: &mut InstructionList,
    ) {
        assert!(bucket.body.len() > 1);
        let (iter_to_loc, mut bucket_arg_order) = Self::compute_extra_args(&recorder);
        let name = self.build_new_body(bucket, &mut bucket_arg_order);
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
            unrolled.push(
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

    fn build_new_body(
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
            // Use empty vector for the length to denote scalar (non-array) arguments
            params.push(Param { name: format!("fixed_{}", i), length: vec![] });
        }

        // Copy loop body and add a "return void" at the end
        let mut new_body = vec![];
        for s in &bucket.body {
            let mut copy: InstructionPointer = s.clone();
            if !bucket_arg_order.is_empty() {
                //Traverse each cloned statement before calling `update_id()` and replace the
                //  old location reference with reference to the proper argument. Mappings are
                //  removed as they are processed so no change is needed once the map is empty.
                ExtractedFunctionLocationUpdater::check_instruction(&mut copy, bucket_arg_order);
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
            new_u32_value(bucket, 0), //use index 0 to ref the entire storage array
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
                new_u32_value(bucket, index),
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

    // Key for the returned map is iteration number.
    // The BTreeMap that is returned maps bucket to fixed* argument index.
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
}
