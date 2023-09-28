use std::cell::{RefCell, Ref};
use std::collections::{BTreeMap, HashMap};
use std::vec;
use indexmap::{IndexMap, IndexSet};
use code_producers::llvm_elements::fr::*;
use compiler::circuit_design::function::{FunctionCodeInfo, FunctionCode};
use compiler::hir::very_concrete_program::Param;
use compiler::intermediate_representation::{
    BucketId, InstructionList, InstructionPointer, new_id, UpdateId,
};
use compiler::intermediate_representation::ir_interface::*;
use crate::bucket_interpreter::value::Value;
use crate::passes::loop_unroll::LOOP_BODY_FN_PREFIX;
use crate::passes::loop_unroll::extracted_location_updater::ExtractedFunctionLocationUpdater;
use crate::passes::loop_unroll::loop_env_recorder::EnvRecorder;
use crate::passes::{builders, checks};

pub type FuncArgIdx = usize;
pub type AddressOffset = usize;
pub type UnrolledIterLvars = BTreeMap<usize, Value>;
pub type ToOriginalLocation = HashMap<FuncArgIdx, (AddressType, AddressOffset)>;

#[derive(Clone, Copy, Debug, Eq, PartialEq, Ord, PartialOrd)]
pub enum ArgIndex {
    Signal(FuncArgIdx),
    SubCmp { signal: FuncArgIdx, arena: FuncArgIdx, counter: FuncArgIdx },
}

impl ArgIndex {
    pub fn get_signal_idx(&self) -> FuncArgIdx {
        match *self {
            ArgIndex::Signal(signal) => signal,
            ArgIndex::SubCmp { signal, .. } => signal,
        }
    }
}

/// Need this structure to skip id/metadata fields in ValueBucket when using as map key.
/// Also, the input/output stuff doesn't matter since the extra arguments that are added
/// based on this are only used to trigger generation of the run function after all of
/// the inputs have been assigned.
#[derive(Clone, Debug, Eq, PartialEq, Ord, PartialOrd)]
struct SubcmpSignalHashFix {
    cmp_address_parse_as: ValueType,
    cmp_address_op_aux_no: usize,
    cmp_address_value: usize,
    uniform_parallel_value: Option<bool>,
    counter_override: bool,
}

impl SubcmpSignalHashFix {
    fn convert(addr: &AddressType) -> SubcmpSignalHashFix {
        if let AddressType::SubcmpSignal {
            cmp_address,
            uniform_parallel_value,
            counter_override,
            ..
        } = addr
        {
            if let Instruction::Value(ValueBucket { parse_as, op_aux_no, value, .. }) =
                **cmp_address
            {
                return SubcmpSignalHashFix {
                    cmp_address_parse_as: parse_as,
                    cmp_address_op_aux_no: op_aux_no,
                    cmp_address_value: value,
                    uniform_parallel_value: uniform_parallel_value.clone(),
                    counter_override: counter_override.clone(),
                };
            }
        }
        panic!("improper AddressType given")
    }
}

struct ExtraArgsResult {
    bucket_to_itr_to_ref: HashMap<BucketId, Vec<Option<(AddressType, AddressOffset)>>>,
    bucket_to_args: IndexMap<BucketId, ArgIndex>,
    num_args: usize,
}

impl ExtraArgsResult {
    fn get_passing_refs_for_itr(
        &self,
        iter_num: usize,
    ) -> Vec<(&Option<(AddressType, AddressOffset)>, ArgIndex)> {
        self.bucket_to_itr_to_ref
            .iter()
            .map(|(k, v)| (&v[iter_num], self.bucket_to_args[k]))
            .collect()
    }

    fn get_reverse_passing_refs_for_itr(&self, iter_num: usize) -> ToOriginalLocation {
        self.bucket_to_itr_to_ref.iter().fold(ToOriginalLocation::new(), |mut acc, (k, v)| {
            if let Some((addr_ty, addr_offset)) = v[iter_num].as_ref() {
                acc.insert(
                    self.bucket_to_args[k].get_signal_idx(),
                    (addr_ty.clone(), *addr_offset),
                );
            }
            acc
        })
    }
}

#[derive(Clone, Debug, Eq, PartialEq, Default)]
pub struct LoopBodyExtractor {
    new_body_functions: RefCell<Vec<FunctionCode>>,
}

impl LoopBodyExtractor {
    fn new_filled_vec<T: Clone>(new_len: usize, value: T) -> Vec<T> {
        let mut result = Vec::with_capacity(new_len);
        result.resize(new_len, value);
        result
    }

    pub fn get_new_functions(&self) -> Ref<Vec<FunctionCode>> {
        self.new_body_functions.borrow()
    }

    pub fn extract<'a>(
        &self,
        bucket: &LoopBucket,
        recorder: &'a EnvRecorder<'a, '_>,
        unrolled: &mut InstructionList,
    ) {
        assert!(bucket.body.len() > 1);
        let extra_arg_info = Self::compute_extra_args(&recorder);
        let name = self.build_new_body(
            bucket,
            extra_arg_info.bucket_to_args.clone(),
            extra_arg_info.num_args,
        );
        for iter_num in 0..recorder.get_iter() {
            // NOTE: CallBucket arguments must use a LoadBucket to reference the necessary pointers
            //  within the current body. However, it doesn't actually need to generate a load
            //  instruction to use these pointers as parameters to the function so we must use the
            //  `bounded_fn` field of the LoadBucket to specify the identity function to perform
            //  the "loading" (but really it just returns the pointer that was passed in).
            let mut args = Self::new_filled_vec(
                extra_arg_info.num_args,
                NopBucket { id: 0 }.allocate(), // garbage fill
            );
            // Parameter for local vars
            args[0] = builders::build_storage_ptr_ref(bucket, AddressType::Variable);
            // Parameter for signals/arena
            args[1] = builders::build_storage_ptr_ref(bucket, AddressType::Signal);
            // Additional parameters for subcmps and variant array indexing within the loop
            for (loc, ai) in extra_arg_info.get_passing_refs_for_itr(iter_num) {
                match loc {
                    None => match ai {
                        ArgIndex::Signal(signal) => {
                            args[signal] = builders::build_null_ptr(bucket, FR_NULL_I256_PTR);
                        }
                        ArgIndex::SubCmp { signal, arena, counter } => {
                            args[signal] = builders::build_null_ptr(bucket, FR_NULL_I256_PTR);
                            args[arena] = builders::build_null_ptr(bucket, FR_NULL_I256_ARR_PTR);
                            args[counter] = builders::build_null_ptr(bucket, FR_NULL_I256_PTR);
                        }
                    },
                    Some((at, val)) => match ai {
                        ArgIndex::Signal(signal) => {
                            args[signal] =
                                builders::build_indexed_storage_ptr_ref(bucket, at.clone(), *val)
                        }
                        ArgIndex::SubCmp { signal, arena, counter } => {
                            // Pass specific signal referenced
                            args[signal] =
                                builders::build_indexed_storage_ptr_ref(bucket, at.clone(), *val);
                            // Pass entire subcomponent arena for calling the 'template_run' function
                            args[arena] = builders::build_storage_ptr_ref(bucket, at.clone());
                            // Pass subcomponent counter reference
                            if let AddressType::SubcmpSignal { cmp_address, .. } = &at {
                                //TODO: may only need to add this when is_output=true but have to skip adding the Param too in that case.
                                args[counter] = builders::build_subcmp_counter_storage_ptr_ref(
                                    bucket,
                                    cmp_address.clone(),
                                );
                            } else {
                                unreachable!()
                            }
                        }
                    },
                }
            }
            unrolled.push(builders::build_call(bucket, &name, args));

            recorder.record_reverse_arg_mapping(
                name.clone(),
                recorder.get_vals_per_iter().get(&iter_num).unwrap().env_at_header.get_vars_sort(),
                extra_arg_info.get_reverse_passing_refs_for_itr(iter_num),
            );
        }
    }

    fn build_new_body(
        &self,
        bucket: &LoopBucket,
        mut bucket_to_args: IndexMap<BucketId, ArgIndex>,
        num_args: usize,
    ) -> String {
        // NOTE: must create parameter list before 'bucket_to_args' is modified
        // Since the ArgIndex instances could have indices in any random order,
        //  create the vector of required size and then set elements by index.
        let mut params = Self::new_filled_vec(
            num_args,
            Param { name: String::from("EMPTY"), length: vec![usize::MAX] },
        );
        params[0] = Param { name: String::from("lvars"), length: vec![0] };
        params[1] = Param { name: String::from("signals"), length: vec![0] };
        for (i, arg_index) in bucket_to_args.values().enumerate() {
            match arg_index {
                ArgIndex::Signal(signal) => {
                    //Single signal uses scalar pointer
                    params[*signal] = Param { name: format!("fix_{}", i), length: vec![] };
                }
                ArgIndex::SubCmp { signal, arena, counter } => {
                    //Subcomponent arena requires array pointer but the others are scalar
                    params[*arena] = Param { name: format!("sub_{}", i), length: vec![0] };
                    params[*signal] = Param { name: format!("subfix_{}", i), length: vec![] };
                    params[*counter] = Param { name: format!("subc_{}", i), length: vec![] };
                }
            }
        }

        // Copy loop body and add a "return void" at the end
        let mut new_body = vec![];
        for s in &bucket.body {
            let mut copy: InstructionPointer = s.clone();
            //Traverse each cloned statement before calling `update_id()` and replace the
            //  old location reference with reference to the proper argument. Mappings are
            //  removed as they are processed so no change is needed once the map is empty.
            let suffix = if !bucket_to_args.is_empty() {
                let mut upd = ExtractedFunctionLocationUpdater::new();
                upd.check_instruction(&mut copy, &mut bucket_to_args);
                upd.insert_after
            } else {
                InstructionList::default()
            };
            copy.update_id();
            new_body.push(copy);
            for s in suffix {
                new_body.push(s);
            }
        }
        assert!(bucket_to_args.is_empty());
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
        // NOTE: This name must start with `GENERATED_FN_PREFIX` (which is the prefix
        //  of `LOOP_BODY_FN_PREFIX`) so that `ExtractedFunctionCtx` will be used.
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

    /// The ideal scenario for extracting the loop body into a new function is to only
    /// need 2 function arguments, lvars and signals. However, we want to avoid variable
    /// indexing within the extracted function so we include extra pointer arguments
    /// that allow the indexing to happen in the original body where the loop will be
    /// unrolled and the indexing will become known constant values. This computes the
    /// extra arguments that will be needed.
    fn compute_extra_args<'a>(recorder: &'a EnvRecorder<'a, '_>) -> ExtraArgsResult {
        // Table structure indexed first by load/store BucketId, then by iteration number.
        //  View the first (BucketId) as columns and the second (iteration number) as rows.
        //  The data reference is wrapped in Option to allow for some iterations that don't
        //  execute a specific bucket due to conditional branches within the loop body.
        //  When comparing values across iterations, ignore those cases where there is no
        //  value for a certain iteration and only check among those iterations that have a
        //  value because it doesn't matter what parameter is passed in for those iterations
        //  that do not execute that specific bucket. This is the reason it was important to
        //  store Unknown values in the `loadstore_to_index` index as well, so they are not
        //  confused with values that simply don't exist.
        let mut bucket_to_itr_to_ref: HashMap<BucketId, Vec<Option<(AddressType, AddressOffset)>>> =
            HashMap::new();
        //
        let mut bucket_to_args: IndexMap<BucketId, ArgIndex> = IndexMap::new();
        let vpi = recorder.get_vals_per_iter();
        // NOTE: starts at 2 because the current component's signal arena and lvars are first.
        let mut next_idx: FuncArgIdx = 2;
        // First step is to collect all location references into the 'bucket_to_itr_to_ref' table.
        // NOTE: Uses IndexSet to preserve insertion order to stabilize lit test output.
        let all_loadstore_bucket_ids: IndexSet<&BucketId> =
            vpi.values().flat_map(|x| x.loadstore_to_index.keys()).collect();
        for id in all_loadstore_bucket_ids {
            let column = bucket_to_itr_to_ref.entry(*id).or_default();
            for iter_num in 0..recorder.get_iter() {
                let temp = vpi[&iter_num].loadstore_to_index.get(id);
                // ASSERT: index values are known in every (available) iteration
                assert!(temp.is_none() || !temp.unwrap().1.is_unknown());
                column.push(temp.map(|(a, v)| (a.clone(), v.get_u32())));
            }
            // ASSERT: same AddressType kind for this bucket in every (available) iteration
            assert!(checks::all_same(
                column.iter().filter_map(|x| x.as_ref()).map(|x| std::mem::discriminant(&x.0))
            ));

            // Check if the computed index value for this bucket is the same across all iterations (where it is
            //  not None, see earlier comment). If it is not, then an extra function argument is needed for it.
            //  Actually, check not only the computed index Value but the AddressType as well to capture when
            //  it's a SubcmpSignal referencing a different subcomponent (the AddressType::cmp_address field
            //  was also interpreted within the EnvRecorder so this comparison will be accurate).
            if !checks::all_same(column.iter().filter_map(|x| x.as_ref())) {
                bucket_to_args.insert(*id, ArgIndex::Signal(next_idx));
                next_idx += 1;
            }
        }
        //ASSERT: All columns have the same length (i.e. the number of iterations)
        assert!(bucket_to_itr_to_ref.values().all(|x| x.len() == recorder.get_iter()));

        // Also, if it's a subcomponent reference, then extra arguments are needed for it's
        //  signal arena and counter (because subcomponents are not included by default like
        //  the current component's signal arena and lvars are).
        // Find groups of BucketId that use the same SubcmpSignal (to reduce number of arguments).
        //  A group must have this same property in all iterations in order to be safe to combine.
        let mut safe_groups: BTreeMap<SubcmpSignalHashFix, IndexSet<BucketId>> = Default::default();
        for iter_num in 0..recorder.get_iter() {
            let grps: BTreeMap<SubcmpSignalHashFix, IndexSet<BucketId>> = bucket_to_itr_to_ref
                .iter()
                .map(|(k, col)| (k, &col[iter_num]))
                .fold(BTreeMap::new(), |mut r, (b, a)| {
                    if let Some((at, _)) = a {
                        if let AddressType::SubcmpSignal { .. } = at {
                            r.entry(SubcmpSignalHashFix::convert(&at)).or_default().insert(*b);
                        }
                    }
                    r
                });
            // Assume all groups are safe until proven otherwise. So if it's empty at any point, just quit.
            if iter_num == 0 {
                safe_groups = grps;
            } else {
                safe_groups.retain(|_, v| grps.values().any(|x| x == v));
            }
            if safe_groups.is_empty() {
                break;
            }
        }
        for (_, buckets) in safe_groups.iter() {
            let arena_idx: FuncArgIdx = next_idx;
            let counter_idx: FuncArgIdx = next_idx + 1;
            next_idx += 2;
            for b in buckets {
                if let Some(ArgIndex::Signal(sig)) = bucket_to_args.get(b) {
                    bucket_to_args.insert(
                        *b,
                        ArgIndex::SubCmp { signal: *sig, arena: arena_idx, counter: counter_idx },
                    );
                } else {
                    //TODO: What to do when the signal index w/in the subcomp was not variant?
                    //  Should I just add a parameter anyway? It doesn't hurt to do that so
                    //  I guess that's the approach to take for now.
                    bucket_to_args.insert(
                        *b,
                        ArgIndex::SubCmp {
                            signal: next_idx,
                            arena: arena_idx,
                            counter: counter_idx,
                        },
                    );
                    next_idx += 1;
                }
            }
        }

        //Keep only the table columns where extra parameters are necessary
        bucket_to_itr_to_ref.retain(|k, _| bucket_to_args.contains_key(k));
        ExtraArgsResult { bucket_to_itr_to_ref, bucket_to_args, num_args: next_idx }
    }
}
