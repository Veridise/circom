use std::cell::Ref;
use std::collections::{HashMap, BTreeMap, HashSet};
use std::fmt::{Display, Formatter, Result};
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::TemplateCode;
use compiler::intermediate_representation::{Instruction, BucketId};
use compiler::intermediate_representation::ir_interface::{AddressType, ValueBucket, ValueType};
use crate::bucket_interpreter::BucketInterpreter;
use crate::bucket_interpreter::value::Value;
use crate::passes::loop_unroll::body_extractor::{ToOriginalLocation, FuncArgIdx};
use super::{Env, LibraryAccess};

/// This Env is used to process functions created by extracting loop bodies
/// into 'LOOP_BODY_FN_PREFIX' functions. It has to interpret the references
/// produced by ExtractedFunctionLocationUpdater (i.e. some loads and stores
/// are converted to AddressType::SubcmpSignal that indicate which function
/// parameter holds the necessary data).
#[derive(Clone)]
pub struct ExtractedFuncEnvData<'a> {
    base: Box<Env<'a>>,
    caller: BucketId,
    remap: ToOriginalLocation,
    arenas: HashSet<FuncArgIdx>,
}

macro_rules! update_inner {
    ($self: expr, $inner: expr) => {{
        ExtractedFuncEnvData::new($inner, &$self.caller, $self.remap, $self.arenas)
    }};
}

impl Display for ExtractedFuncEnvData<'_> {
    fn fmt(&self, f: &mut Formatter<'_>) -> Result {
        write!(f, "ExtractedFuncEnv{{")?;
        self.base.fmt(f)?;
        write!(f, "}}")
    }
}

impl LibraryAccess for ExtractedFuncEnvData<'_> {
    fn get_function(&self, name: &String) -> Ref<FunctionCode> {
        self.base.get_function(name)
    }

    fn get_template(&self, name: &String) -> Ref<TemplateCode> {
        self.base.get_template(name)
    }
}

// All subcomponent lookups need to use the map from loop unrolling to convert the
//  AddressType::SubcmpSignal references created by ExtractedFunctionLocationUpdater
//  back into the proper reference to access the correct Env entry.
impl<'a> ExtractedFuncEnvData<'a> {
    pub fn new(
        inner: Env<'a>,
        caller: &BucketId,
        remap: ToOriginalLocation,
        arenas: HashSet<FuncArgIdx>,
    ) -> Self {
        ExtractedFuncEnvData { base: Box::new(inner), caller: caller.clone(), remap, arenas }
    }

    pub fn extracted_func_caller(&self) -> Option<&BucketId> {
        Some(&self.caller)
    }

    pub fn get_base(self) -> Env<'a> {
        *self.base
    }

    pub fn get_var(&self, idx: usize) -> Value {
        // Local variables are referenced in the normal way
        self.base.get_var(idx)
    }

    pub fn get_signal(&self, idx: usize) -> Value {
        // Signals are referenced in the normal way
        self.base.get_signal(idx)
    }

    pub fn get_subcmp_signal(&self, subcmp_idx: usize, signal_idx: usize) -> Value {
        let res = match self.remap.get(&subcmp_idx) {
            None => {
                //ASSERT: ArgIndex::SubCmp 'arena' parameters are not in 'remap' but all others are.
                assert!(self.arenas.contains(&subcmp_idx));
                unreachable!();
            }
            Some((loc, idx)) => {
                //ASSERT: ExtractedFunctionLocationUpdater will always assign 0 in
                //  the LocationRule that 'signal_idx' is computed from.
                assert_eq!(signal_idx, 0);
                match loc {
                    AddressType::Variable => self.base.get_var(*idx),
                    AddressType::Signal => self.base.get_signal(*idx),
                    AddressType::SubcmpSignal { counter_override, cmp_address, .. } => {
                        let subcmp = match **cmp_address {
                            Instruction::Value(ValueBucket {
                                parse_as: ValueType::U32,
                                value,
                                ..
                            }) => value,
                            _ => unreachable!(), //ASSERT: 'cmp_address' was formed by 'loop_unroll::new_u32_value'
                        };
                        if *counter_override {
                            // ASSERT: always 0 from 'get_reverse_passing_refs_for_itr' in 'body_extractor.rs'
                            assert_eq!(*idx, 0);
                            self.base.get_subcmp_counter(subcmp)
                        } else {
                            self.base.get_subcmp_signal(subcmp, *idx)
                        }
                    }
                }
            }
        };
        res
    }

    pub fn get_subcmp_name(&self, subcmp_idx: usize) -> &String {
        match self.remap.get(&subcmp_idx) {
            None => {
                //ASSERT: ArgIndex::SubCmp 'arena' parameters are not in 'remap' but all others are.
                assert!(self.arenas.contains(&subcmp_idx));
                unreachable!();
            }
            Some((loc, idx)) => {
                match loc {
                    AddressType::Variable => self.base.get_subcmp_name(*idx),
                    AddressType::Signal => self.base.get_subcmp_name(*idx),
                    AddressType::SubcmpSignal { counter_override, cmp_address, .. } => {
                        let subcmp = match **cmp_address {
                            Instruction::Value(ValueBucket {
                                parse_as: ValueType::U32,
                                value,
                                ..
                            }) => value,
                            _ => unreachable!(), //ASSERT: 'cmp_address' was formed by 'loop_unroll::new_u32_value'
                        };
                        if *counter_override {
                            unreachable!();
                        } else {
                            //ASSERT: ExtractedFunctionLocationUpdater will always assign 0 in
                            //  the LocationRule that 'idx' is computed from.
                            assert_eq!(*idx, 0);
                            self.base.get_subcmp_name(subcmp)
                        }
                    }
                }
            }
        }
    }

    pub fn get_subcmp_template_id(&self, subcmp_idx: usize) -> usize {
        match self.remap.get(&subcmp_idx) {
            None => {
                //ASSERT: ArgIndex::SubCmp 'arena' parameters are not in 'remap' but all others are.
                assert!(self.arenas.contains(&subcmp_idx));
                unreachable!();
            }
            Some((loc, idx)) => {
                match loc {
                    AddressType::Variable => self.base.get_subcmp_template_id(*idx),
                    AddressType::Signal => self.base.get_subcmp_template_id(*idx),
                    AddressType::SubcmpSignal { counter_override, cmp_address, .. } => {
                        let subcmp = match **cmp_address {
                            Instruction::Value(ValueBucket {
                                parse_as: ValueType::U32,
                                value,
                                ..
                            }) => value,
                            _ => unreachable!(), //ASSERT: 'cmp_address' was formed by 'loop_unroll::new_u32_value'
                        };
                        if *counter_override {
                            unreachable!();
                        } else {
                            //ASSERT: ExtractedFunctionLocationUpdater will always assign 0 in
                            //  the LocationRule that 'signal_idx' is computed from.
                            assert_eq!(*idx, 0);
                            self.base.get_subcmp_template_id(subcmp)
                        }
                    }
                }
            }
        }
    }

    pub fn get_subcmp_counter(&self, _subcmp_idx: usize) -> Value {
        todo!()
    }

    pub fn subcmp_counter_is_zero(&self, subcmp_idx: usize) -> bool {
        let res = match self.remap.get(&subcmp_idx).cloned() {
            None => {
                //ASSERT: ArgIndex::SubCmp 'arena' parameters are not in 'remap' but all others are.
                assert!(self.arenas.contains(&subcmp_idx));
                // This will be reached for the StoreBucket that generates a call to the "_run" function.
                return true; // True to execute the run_subcmp function
            }
            Some((loc, _)) => {
                match loc {
                    AddressType::SubcmpSignal { counter_override, cmp_address, .. } => {
                        let subcmp = match *cmp_address {
                            Instruction::Value(ValueBucket {
                                parse_as: ValueType::U32,
                                value,
                                ..
                            }) => value,
                            _ => unreachable!(), //ASSERT: 'cmp_address' was formed by 'loop_unroll::new_u32_value'
                        };
                        if counter_override {
                            unreachable!() // there is no counter for a counter reference
                        } else {
                            self.base.subcmp_counter_is_zero(subcmp)
                        }
                    }
                    _ => false, // no counter for Variable/Signal types
                }
            }
        };
        res
    }

    pub fn subcmp_counter_equal_to(&self, subcmp_idx: usize, value: usize) -> bool {
        let res = match self.remap.get(&subcmp_idx).cloned() {
            None => {
                //ASSERT: ArgIndex::SubCmp 'arena' parameters are not in 'remap' but all others are.
                assert!(self.arenas.contains(&subcmp_idx));
                unreachable!();
            }
            Some((loc, _)) => {
                match loc {
                    AddressType::SubcmpSignal { counter_override, cmp_address, .. } => {
                        let subcmp = match *cmp_address {
                            Instruction::Value(ValueBucket {
                                parse_as: ValueType::U32,
                                value,
                                ..
                            }) => value,
                            _ => unreachable!(), //ASSERT: 'cmp_address' was formed by 'loop_unroll::new_u32_value'
                        };
                        if counter_override {
                            unreachable!() // there is no counter for a counter reference
                        } else {
                            self.base.subcmp_counter_equal_to(subcmp, value)
                        }
                    }
                    _ => false, // no counter for Variable/Signal types
                }
            }
        };
        res
    }

    pub fn get_vars_clone(&self) -> HashMap<usize, Value> {
        self.base.get_vars_clone()
    }

    pub fn get_vars_sort(&self) -> BTreeMap<usize, Value> {
        self.base.get_vars_sort()
    }

    pub fn set_var(self, idx: usize, value: Value) -> Self {
        // Local variables are referenced in the normal way
        update_inner!(self, self.base.set_var(idx, value))
    }

    pub fn set_signal(self, idx: usize, value: Value) -> Self {
        // Signals are referenced in the normal way
        update_inner!(self, self.base.set_signal(idx, value))
    }

    pub fn set_all_to_unk(self) -> Self {
        update_inner!(self, self.base.set_all_to_unk())
    }

    pub fn set_subcmp_to_unk(self, subcmp_idx: usize) -> Self {
        // The index here is already converted within BucketInterpreter::get_write_operations_in_store_bucket
        //  via interpreting the LocationRule and performing the PassMemory lookup on the unchanged scope
        //  (per comment in BucketInterpreter::run_function_loopbody).
        update_inner!(self, self.base.set_subcmp_to_unk(subcmp_idx))
    }

    pub fn set_subcmp_signal(self, subcmp_idx: usize, signal_idx: usize, new_value: Value) -> Self {
        //NOTE: This is only called by BucketInterpreter::store_value_in_address.
        //Use the map from loop unrolling to convert the SubcmpSignal reference back
        //  into the proper reference (reversing ExtractedFunctionLocationUpdater).
        let new_env = match self.remap.get(&subcmp_idx).cloned() {
            None => {
                //ASSERT: ArgIndex::SubCmp 'arena' parameters are not in 'remap' but all others are.
                assert!(self.arenas.contains(&subcmp_idx));
                // This will be reached for the StoreBucket that generates a call to the "_run" function.
                return self; // Nothing needs to be done.
            }
            Some((loc, idx)) => {
                //ASSERT: ExtractedFunctionLocationUpdater will always assign 0 in
                //  the LocationRule that 'signal_idx' is computed from.
                assert_eq!(signal_idx, 0);
                match loc {
                    AddressType::Variable => self.base.set_var(idx, new_value),
                    AddressType::Signal => self.base.set_signal(idx, new_value),
                    AddressType::SubcmpSignal { counter_override, cmp_address, .. } => {
                        let subcmp = match *cmp_address {
                            Instruction::Value(ValueBucket {
                                parse_as: ValueType::U32,
                                value,
                                ..
                            }) => value,
                            _ => unreachable!(), //ASSERT: 'cmp_address' was formed by 'loop_unroll::new_u32_value'
                        };
                        if counter_override {
                            // ASSERT: always 0 from 'get_reverse_passing_refs_for_itr' in 'body_extractor.rs'
                            assert_eq!(idx, 0);
                            // NOTE: If unwrapping to u32 directly causes a panic, then need to allow Value as the parameter.
                            self.base.set_subcmp_counter(subcmp, new_value.get_u32())
                        } else {
                            self.base.set_subcmp_signal(subcmp, idx, new_value)
                        }
                    }
                }
            }
        };
        update_inner!(self, new_env)
    }

    pub fn set_subcmp_counter(self, _subcmp_idx: usize, _new_val: usize) -> Self {
        todo!()
    }

    pub fn decrease_subcmp_counter(self, _subcmp_idx: usize) -> Self {
        //Do nothing because subcmp counter is managed explicitly in extracted functions
        self
    }

    pub fn run_subcmp(self, _: usize, _: &String, _: &BucketInterpreter, _: bool) -> Self {
        //Return self just like the StandardEnvData
        self
    }

    pub fn create_subcmp(
        self,
        _name: &'a String,
        _base_index: usize,
        _count: usize,
        _template_id: usize,
    ) -> Self {
        unreachable!()
    }
}
