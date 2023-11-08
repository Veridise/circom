use std::cell::{RefCell, Ref};
use std::collections::{BTreeMap, HashMap, HashSet, BTreeSet};
use std::vec;
use indexmap::{IndexMap, IndexSet};
use code_producers::llvm_elements::fr::*;
use compiler::circuit_design::function::{FunctionCodeInfo, FunctionCode};
use compiler::hir::very_concrete_program::Param;
use compiler::intermediate_representation::{BucketId, InstructionList, new_id, UpdateId};
use compiler::intermediate_representation::ir_interface::*;
use crate::bucket_interpreter::value::Value;
use crate::passes::loop_unroll::{DEBUG_LOOP_UNROLL, LOOP_BODY_FN_PREFIX};
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
struct SubcmpSignalCompare {
    cmp_address_parse_as: ValueType,
    cmp_address_op_aux_no: usize,
    cmp_address_value: usize,
    uniform_parallel_value: Option<bool>,
    counter_override: bool,
}

impl SubcmpSignalCompare {
    fn convert(addr: &AddressType) -> SubcmpSignalCompare {
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
                return SubcmpSignalCompare {
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
    // NOTE: This collection and several intermediate collections that are used to build this
    // one must use IndexMap/IndexSet to preserve insertion order to stabilize lit test output.
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

    fn get_reverse_passing_refs_for_itr(
        &self,
        iter_num: usize,
    ) -> (ToOriginalLocation, HashSet<FuncArgIdx>) {
        self.bucket_to_itr_to_ref.iter().fold(
            (ToOriginalLocation::new(), HashSet::new()),
            |mut acc, (k, v)| {
                if let Some((addr_ty, addr_offset)) = v[iter_num].as_ref() {
                    let ai = self.bucket_to_args[k];
                    acc.0.insert(ai.get_signal_idx(), (addr_ty.clone(), *addr_offset));
                    // If applicable, insert the subcmp counter reference as well
                    if let ArgIndex::SubCmp { counter, arena, .. } = ai {
                        match addr_ty {
                            AddressType::SubcmpSignal { counter_override, cmp_address, .. } => {
                                assert_eq!(*counter_override, false); //there's no counter for a counter
                                let counter_addr_ty = AddressType::SubcmpSignal {
                                    cmp_address: cmp_address.clone(),
                                    uniform_parallel_value: None,
                                    is_output: false,
                                    input_information: InputInformation::NoInput,
                                    counter_override: true,
                                };
                                // NOTE: when there's a true subcomponent (indicated by the ArgIndex::SubCmp check above),
                                //  the 'addr_offset' indicates which signal inside the subcomponent is accessed. That
                                //  value is not relevant here because subcomponents have a single counter variable.
                                acc.0.insert(counter, (counter_addr_ty, 0));
                                //
                                acc.1.insert(arena);
                            }
                            _ => unreachable!(), // SubcmpSignal was created for all of these refs
                        }
                    }
                }
                acc
            },
        )
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
            let mut passing_refs = extra_arg_info.get_passing_refs_for_itr(iter_num);
            // Sort by the Option to ensure None comes first so that the value for a Some entry that uses the same
            //  'arena' and 'counter' as a None entry will be preserved, replacing the 'null' for the None entry.
            passing_refs.sort_by(|(a, _), (b, _)| a.cmp(b));
            for (loc, ai) in passing_refs {
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
            let mut copy = vec![s.clone()];
            //Traverse each cloned statement before calling `update_id()` and replace the
            //  old location reference with reference to the proper argument. Mappings are
            //  removed as they are processed so no change is needed once the map is empty.
            //  Also retrieve the list of statements that were generated to be inserted
            //  after the current statement and insert them after the updated statement.
            //NOTE: nothing will be updated or added if 'bucket_to_args' is empty so skip.
            if !bucket_to_args.is_empty() {
                let mut upd = ExtractedFunctionLocationUpdater::new();
                upd.check_instructions(&mut copy, &mut bucket_to_args, true);
            }
            for mut s in copy.drain(..) {
                s.update_id();
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

    /// Create an Iterator containing the results of applying the given
    /// function to only the `Some` entries in the given vector.
    fn filter_map<'a, A, B, C>(
        column: &'a Vec<Option<(A, B)>>,
        f: impl FnMut(&(A, B)) -> C + 'a,
    ) -> impl Iterator<Item = C> + '_ {
        column.iter().filter_map(|x| x.as_ref()).map(f)
    }

    /// Create an Iterator containing the results of applying the given
    /// function to only the `Some` entries in the given vector.
    fn filter_map_any<A, B>(column: &Vec<Option<(A, B)>>, f: impl FnMut(&(A, B)) -> bool) -> bool {
        column.iter().filter_map(|x| x.as_ref()).any(f)
    }

    fn average(
        member: &BucketId,
        set: &BTreeSet<BucketId>,
        exact_match_counts: &HashMap<BucketId, HashMap<BucketId, usize>>,
    ) -> usize {
        let counts_for_member = &exact_match_counts[member];
        if DEBUG_LOOP_UNROLL {
            println!("average({:?}, {:?}, {:?}) ", member, set, counts_for_member);
        }
        if set.contains(member) {
            set.iter()
                .filter_map(|e| if e == member { None } else { Some(counts_for_member[e]) })
                .sum::<usize>()
                / (set.len() - 1)
        } else {
            set.iter().map(|e| counts_for_member[e]).sum::<usize>() / set.len()
        }
    }

    /// Test for true equality when both parameters are Some, otherwise return true when either is None.
    /// The first value in the tuple is the result and the second is `true` for a "fuzzy" None equality.
    fn fuzzy_equals<T: PartialEq>(a: &Option<T>, b: &Option<T>) -> (bool, bool) {
        match (a, b) {
            (Some(x), Some(y)) => (x == y, false),
            _ => (true, true),
        }
    }

    fn group_equal_lists<T: PartialEq + core::fmt::Debug>(
        lists: &[(BucketId, Vec<Option<T>>)],
    ) -> Vec<Vec<BucketId>> {
        if DEBUG_LOOP_UNROLL {
            println!("[group_equal_lists] input = {:?}", lists);
        }
        // Compare each pair of lists and group those with the same list of matches.
        // Also keep track of the number of exact matches for each pair of BucketId
        //  in order to combine keys that are subsets of each other.
        let mut grouped: IndexMap<BTreeSet<BucketId>, Vec<BucketId>> = Default::default();
        let mut exact_match_counts: HashMap<BucketId, HashMap<BucketId, usize>> =
            Default::default();
        for (i_1, list_1) in lists.iter() {
            let curr_counts = exact_match_counts.entry(*i_1).or_default();
            let key = lists
                .iter()
                .filter_map(|(i_2, list_2)| {
                    assert_eq!(list_1.len(), list_2.len());
                    let (is_equal, num_exact) =
                        list_1.iter().zip(list_2.iter()).fold((true, 0), |(t, c), (a, b)| {
                            let (res, fuzzy) = Self::fuzzy_equals(a, b);
                            (t && res, if fuzzy { c } else { c + 1 })
                        });
                    curr_counts.insert(*i_2, num_exact);
                    if is_equal {
                        Some(*i_2)
                    } else {
                        None
                    }
                })
                .collect();
            grouped.entry(key).or_default().push(*i_1);
            curr_counts.remove(i_1); //remove self mapping
        }
        if DEBUG_LOOP_UNROLL {
            println!("[group_equal_lists] grouped = {:?}", grouped);
            println!("[group_equal_lists] exact_match_counts = {:?}", exact_match_counts);
        }

        // Now, if there are any groups A and B, where the key for A is a subset of the key for B,
        //  it is safe to merge B into A (i.e. just because the load/store locations for B happen
        //  to match the locations of some additional bucket(s) that A does not match because of
        //  wildcard/None matches, it is still correct to use the parameters generated for A since
        //  they include all of the same load/store locations neede by B). If there is more than
        //  one such A, then the match counts should be used to merge into the one with the highest
        //  average match count.
        let mut sorted_keys: Vec<_> = grouped.keys().cloned().collect();
        sorted_keys.sort_by(|a, b| b.len().cmp(&a.len())); //long to short
        for (idx, key1) in sorted_keys.iter().enumerate() {
            let mut subsets = vec![];
            for key2 in sorted_keys[idx + 1..].iter() {
                if key1.len() != key2.len() {
                    debug_assert!(key1.len() > key2.len());
                    if checks::contains_all(key1.iter(), key2.iter()) {
                        subsets.push(key2);
                    }
                }
            }
            if DEBUG_LOOP_UNROLL {
                println!("[group_equal_lists] key1 = {:?}", key1);
                println!("[group_equal_lists] value1 = {:?}", grouped[key1]);
                println!("[group_equal_lists] subsets = {:?}", subsets);
            }
            let move_to_subset = match subsets[..] {
                [] => None, //do nothing
                [s] => Some(s),
                _ => {
                    // Compute the sum over all members of the average count for the subsets for each member
                    let mut exact_matches_per_subset = vec![0; subsets.len()];
                    for member in &grouped[key1] {
                        // Compute average count for each subset for the current member
                        let avg_count_per_subset =
                            subsets.iter().map(|s| Self::average(member, s, &exact_match_counts));
                        // Sum into running total
                        exact_matches_per_subset = exact_matches_per_subset
                            .iter()
                            .zip(avg_count_per_subset)
                            .map(|(x, y)| x + y)
                            .collect();
                    }
                    if DEBUG_LOOP_UNROLL {
                        println!(
                            "[group_equal_lists] exact_matches_per_subset = {:?}",
                            exact_matches_per_subset
                        );
                    }
                    assert_eq!(exact_matches_per_subset.len(), subsets.len());
                    exact_matches_per_subset
                        .iter()
                        .zip(subsets.iter())
                        .max_by_key(|(c, _)| **c)
                        .map(|(_, x)| *x)
                }
            };
            if DEBUG_LOOP_UNROLL {
                println!("[group_equal_lists] move_to_subset = {:?}", move_to_subset);
            }
            if let Some(s) = move_to_subset {
                assert_ne!(s, key1);
                // Remove 'key1' from 'grouped' and add it's value(s) to 'grouped[key2]' (i.e. 's')
                let temp = grouped.remove(key1).unwrap();
                grouped.get_mut(s).unwrap().extend(temp);
            }
        }
        if DEBUG_LOOP_UNROLL {
            println!("[group_equal_lists] grouped (with subset merges) = {:?}", grouped);
        }

        grouped.values().cloned().collect()
    }

    /// The ideal scenario for extracting the loop body into a new function is to only
    /// need 2 function arguments, lvars and signals. However, we want to avoid variable
    /// indexing within the extracted function so we include extra pointer arguments
    /// that allow the indexing to happen in the original body where the loop will be
    /// unrolled and the indexing will become known constant values. This computes the
    /// extra arguments that will be needed.
    fn compute_extra_args<'a>(recorder: &'a EnvRecorder<'a, '_>) -> ExtraArgsResult {
        // Table structure indexed first by load/store/call BucketId, then by iteration number.
        //  View the first (BucketId) as columns and the second (iteration number) as rows.
        //  The data reference is wrapped in Option to allow for some iterations that don't
        //  execute a specific bucket due to conditional branches within the loop body.
        //  When comparing values across iterations, ignore those cases where there is no
        //  value for a certain iteration and only check among those iterations that have a
        //  value because it doesn't matter what parameter is passed in for those iterations
        //  that do not execute that specific bucket. This is the reason it was important to
        //  store Unknown values in the `loadstore_to_index` index as well, so they are not
        //  confused with values that simply don't exist.
        let mut bucket_to_itr_to_ref: IndexMap<
            BucketId,
            Vec<Option<(AddressType, AddressOffset)>>,
        > = Default::default();
        //
        let mut bucket_to_args: IndexMap<BucketId, ArgIndex> = Default::default();
        let vpi = recorder.get_vals_per_iter();
        // NOTE: starts at 2 because the current component's signal arena and lvars are first.
        let mut next_idx: FuncArgIdx = 2;
        // First step is to collect all location references into the 'bucket_to_itr_to_ref' table.
        let all_loadstore_buckets: IndexSet<BucketId> =
            vpi.values().flat_map(|x| x.loadstore_to_index.keys().cloned()).collect();
        for id in all_loadstore_buckets.iter() {
            let column = bucket_to_itr_to_ref.entry(*id).or_default();
            for iter_num in 0..recorder.get_iter() {
                let temp = vpi[&iter_num].loadstore_to_index.get(id);
                // ASSERT: index values are known in every (available) iteration
                assert!(temp.is_none() || !temp.unwrap().1.is_unknown());
                column.push(temp.map(|(a, v)| (a.clone(), v.get_u32())));
            }
            if DEBUG_LOOP_UNROLL {
                println!("bucket {} refs by iteration: {:?}", id, column);
            }
            // ASSERT: same AddressType kind for this bucket in every (available) iteration
            assert!(checks::all_same(Self::filter_map(column, |(x, _)| std::mem::discriminant(x))));

            // If the computed index value for this bucket is NOT the same across all available
            //  iterations (i.e. where it is not None, see earlier comment) or if the AddressType
            //  is SubcmpSignal, then an extra function argument is needed for it.
            if Self::filter_map_any(column, |(x, _)| matches!(x, AddressType::SubcmpSignal { .. }))
                || !checks::all_same(Self::filter_map(column, |(_, y)| *y))
            {
                bucket_to_args.insert(*id, ArgIndex::Signal(next_idx));
                next_idx += 1;
            }
        }
        if DEBUG_LOOP_UNROLL {
            println!("bucket_to_args = {:?}", bucket_to_args);
            println!("bucket_to_itr_to_ref = {:?}", bucket_to_itr_to_ref);
            println!("all_loadstore_bucket_ids = {:?}", all_loadstore_buckets);
        }
        //ASSERT: All columns have the same length (i.e. the number of iterations)
        assert!(bucket_to_itr_to_ref.values().all(|c| c.len() == recorder.get_iter()));
        //ASSERT: 'bucket_to_itr_to_ref.keys' is equal to 'all_loadstore_bucket_ids'
        assert!(checks::contains_same(&all_loadstore_buckets, bucket_to_itr_to_ref.keys()));
        //ASSERT: 'bucket_to_args.keys' is a subset of 'all_loadstore_bucket_ids'
        assert!(checks::contains_all(&all_loadstore_buckets, bucket_to_args.keys()));

        // Also, if it's a subcomponent reference, then extra arguments are needed for it's
        //  signal arena and counter (because the entire subcomponent storage pointer is not
        //  included by default like the current component's signal arena and lvars are).
        //  To reduce the number of arguments, group together buckets that use the same
        //  SubcmpSignal so a single function argument can serve all of them. A group of
        //  buckets must be found in every iteration of the loop or else it is not able to
        //  share the same funtion argument. The one exception to that rule is buckets that
        //  are unused in some iteration(s) (indicated by None), they can be included in a
        //  group if they are part of that same group in all iterations where present.
        let x: Vec<(BucketId, Vec<Option<SubcmpSignalCompare>>)> = bucket_to_itr_to_ref
            .iter()
            .filter_map(|(b, col)| {
                //if the iteration does not contain any Some(SubCmp), then we return None
                //otherwise, return a new Some(Vec<Option<SubcmpSignalCompare>>)
                let conv: Vec<Option<SubcmpSignalCompare>> = col
                    .iter()
                    .map(|o| match o {
                        // Ignore the offset here since the parameters pass the
                        //  counter and the entire array for the subcomponent.
                        Some((at, _)) => match at {
                            AddressType::SubcmpSignal { .. } => {
                                Some(SubcmpSignalCompare::convert(&at))
                            }
                            _ => None,
                        },
                        None => None,
                    })
                    .collect();
                //If the converted column is all None, return None, otherwise return some
                if conv.iter().all(Option::is_none) {
                    None
                } else {
                    Some((*b, conv))
                }
            })
            .collect();
        let subcmp_arg_groups = Self::group_equal_lists(&x[..]);
        if DEBUG_LOOP_UNROLL {
            println!("subcmp_arg_groups = {:?}", subcmp_arg_groups);
        }
        //ASSERT: Every bucket mapped to a Some(SubcmpSignal) in any iteration is present in exactly one group.
        assert!(bucket_to_itr_to_ref
            .iter()
            .filter_map(|(k, v)| {
                if v.iter().any(|e| matches!(e, Some((AddressType::SubcmpSignal { .. }, _)))) {
                    Some(k)
                } else {
                    None
                }
            })
            .all(|b| subcmp_arg_groups.iter().filter(|s| s.contains(b)).count() == 1));

        // Finally, add the extra argument numbers for the subcomponents
        for buckets in subcmp_arg_groups.iter() {
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
                    // All buckets had ArgIndex::Signal added earlier
                    //  and no bucket appears in more than one group.
                    unreachable!()
                }
            }
        }
        //Keep only the table columns where extra parameters are necessary
        bucket_to_itr_to_ref.retain(|k, _| bucket_to_args.contains_key(k));
        ExtraArgsResult {
            bucket_to_itr_to_ref: bucket_to_itr_to_ref.into_iter().collect(),
            bucket_to_args,
            num_args: next_idx,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn test_1() {
        // '555' has 1 exact match with [666] and the same with [222,333]
        // Since they are the same, it could merge with either but 'max_by_key'
        //  will returns the latest max element which is [666] in this case
        //  because we sorted the subsets by longest to shortest.
        let input = vec![
            (666, vec![Some(4), Some(5), None, Some(6)]),
            (222, vec![None, Some(2), Some(4), None]),
            (333, vec![Some(1), Some(2), Some(4), None]),
            (555, vec![None, None, Some(4), Some(6)]),
        ];
        let res = LoopBodyExtractor::group_equal_lists(&input);
        assert_eq!(2, res.len());
        assert!(res.contains(&vec![222, 333]));
        assert!(res.contains(&vec![666, 555]));
    }

    #[test]
    fn test_2() {
        // '555' has 1 exact match with [222,333] and 0 with [666]
        let input = vec![
            (666, vec![Some(4), Some(5), None]),
            (222, vec![None, Some(2), Some(4)]),
            (333, vec![Some(1), Some(2), Some(4)]),
            (555, vec![None, None, Some(4)]),
        ];
        let res = LoopBodyExtractor::group_equal_lists(&input);
        assert_eq!(2, res.len());
        assert!(res.contains(&vec![222, 333, 555]));
        assert!(res.contains(&vec![666]));
    }
}
