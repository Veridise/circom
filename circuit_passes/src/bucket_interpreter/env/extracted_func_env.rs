use std::cell::Ref;
use std::collections::{HashMap, BTreeMap};
use std::fmt::{Display, Formatter, Result};
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::TemplateCode;
use compiler::intermediate_representation::Instruction;
use compiler::intermediate_representation::ir_interface::{AddressType, ValueBucket, ValueType};
use crate::bucket_interpreter::BucketInterpreter;
use crate::bucket_interpreter::value::Value;
use crate::passes::loop_unroll::body_extractor::ToOriginalLocation;
use super::{Env, LibraryAccess};

/// This Env is used to process functions created by extracting loop bodies
/// into 'LOOP_BODY_FN_PREFIX' functions. It has to interpret the references
/// produced by ExtractedFunctionLocationUpdater (i.e. some loads and stores
/// are converted to AddressType::SubcmpSignal that indicate which function
/// parameter holds the necessary data).
#[derive(Clone)]
pub struct ExtractedFuncEnvData<'a> {
    base: Box<Env<'a>>,
    remap: ToOriginalLocation,
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
    pub fn new(inner: Env<'a>, remap: ToOriginalLocation) -> Self {
        ExtractedFuncEnvData { base: Box::new(inner), remap }
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
            None => todo!(), // from ArgIndex::SubCmp 'arena' and 'counter' parameters
            Some((loc, idx)) => {
                //ASSERT: ExtractedFunctionLocationUpdater will always assign 0 in
                //  the LocationRule that 'signal_idx' is computed from.
                assert_eq!(signal_idx, 0);
                match loc {
                    AddressType::Variable => self.base.get_var(*idx),
                    AddressType::Signal => self.base.get_signal(*idx),
                    AddressType::SubcmpSignal { cmp_address, .. } => {
                        let subcmp = match **cmp_address {
                            Instruction::Value(ValueBucket {
                                parse_as: ValueType::U32,
                                value,
                                ..
                            }) => value,
                            _ => unreachable!(), //ASSERT: 'cmp_address' was formed by 'loop_unroll::new_u32_value'
                        };
                        self.base.get_subcmp_signal(subcmp, *idx)
                    }
                }
            }
        };
        res
    }

    pub fn get_subcmp_name(&self, subcmp_idx: usize) -> &String {
        match self.remap.get(&subcmp_idx) {
            None => todo!(), // from ArgIndex::SubCmp 'arena' and 'counter' parameters
            Some((loc, idx)) => {
                match loc {
                    AddressType::Variable => self.base.get_subcmp_name(*idx),
                    AddressType::Signal => self.base.get_subcmp_name(*idx),
                    AddressType::SubcmpSignal { cmp_address, .. } => {
                        let subcmp = match **cmp_address {
                            Instruction::Value(ValueBucket {
                                parse_as: ValueType::U32,
                                value,
                                ..
                            }) => value,
                            _ => unreachable!(), //ASSERT: 'cmp_address' was formed by 'loop_unroll::new_u32_value'
                        };
                        //ASSERT: ExtractedFunctionLocationUpdater will always assign 0 in
                        //  the LocationRule that 'signal_idx' is computed from.
                        assert_eq!(*idx, 0);
                        self.base.get_subcmp_name(subcmp)
                    }
                }
            }
        }
    }

    pub fn get_subcmp_template_id(&self, subcmp_idx: usize) -> usize {
        match self.remap.get(&subcmp_idx) {
            None => todo!(), // from ArgIndex::SubCmp 'arena' and 'counter' parameters
            Some((loc, idx)) => {
                match loc {
                    AddressType::Variable => self.base.get_subcmp_template_id(*idx),
                    AddressType::Signal => self.base.get_subcmp_template_id(*idx),
                    AddressType::SubcmpSignal { cmp_address, .. } => {
                        let subcmp = match **cmp_address {
                            Instruction::Value(ValueBucket {
                                parse_as: ValueType::U32,
                                value,
                                ..
                            }) => value,
                            _ => unreachable!(), //ASSERT: 'cmp_address' was formed by 'loop_unroll::new_u32_value'
                        };
                        //ASSERT: ExtractedFunctionLocationUpdater will always assign 0 in
                        //  the LocationRule that 'signal_idx' is computed from.
                        assert_eq!(*idx, 0);
                        self.base.get_subcmp_template_id(subcmp)
                    }
                }
            }
        }
    }

    pub fn subcmp_counter_is_zero(&self, subcmp_idx: usize) -> bool {
        let res = match self.remap.get(&subcmp_idx).cloned() {
            //TODO: Is this None case being hit by a pre-existing subcmp at index 0 reference? I think so. Can I verify?
            //  All subcmp refs in extracted body should have been replaced with refs to a subfix parameter... right?
            //OBS: It happens because there will be Unknown counter when certain loop bodies are extracted to a function.
            //  That means I do need to add the code to decrement counters inside the loop and let StoreBucket generate
            //  the counter checks that will determine when to execute the "run" function at runtime.
            None => todo!(), //false, // from ArgIndex::SubCmp 'arena' and 'counter' parameters
            Some((loc, _)) => {
                match loc {
                    AddressType::SubcmpSignal { cmp_address, .. } => {
                        let subcmp = match *cmp_address {
                            Instruction::Value(ValueBucket {
                                parse_as: ValueType::U32,
                                value,
                                ..
                            }) => value,
                            _ => unreachable!(), //ASSERT: 'cmp_address' was formed by 'loop_unroll::new_u32_value'
                        };
                        self.base.subcmp_counter_is_zero(subcmp)
                    }
                    _ => false, // no counter for Variable/Signal types
                }
            }
        };
        res
    }

    pub fn subcmp_counter_equal_to(&self, subcmp_idx: usize, value: usize) -> bool {
        let res = match self.remap.get(&subcmp_idx).cloned() {
            None => todo!(), //false, // from ArgIndex::SubCmp 'arena' and 'counter' parameters
            Some((loc, _)) => {
                match loc {
                    AddressType::SubcmpSignal { cmp_address, .. } => {
                        let subcmp = match *cmp_address {
                            Instruction::Value(ValueBucket {
                                parse_as: ValueType::U32,
                                value,
                                ..
                            }) => value,
                            _ => unreachable!(), //ASSERT: 'cmp_address' was formed by 'loop_unroll::new_u32_value'
                        };
                        self.base.subcmp_counter_equal_to(subcmp, value)
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
        ExtractedFuncEnvData { base: Box::new(self.base.set_var(idx, value)), remap: self.remap }
    }

    pub fn set_signal(self, idx: usize, value: Value) -> Self {
        // Signals are referenced in the normal way
        ExtractedFuncEnvData { base: Box::new(self.base.set_signal(idx, value)), remap: self.remap }
    }

    pub fn set_all_to_unk(self) -> Self {
        // Local variables are referenced in the normal way
        ExtractedFuncEnvData { base: Box::new(self.base.set_all_to_unk()), remap: self.remap }
    }

    pub fn set_subcmp_to_unk(self, _subcmp_idx: usize) -> Self {
        unreachable!()
    }

    pub fn set_subcmp_signal(self, subcmp_idx: usize, signal_idx: usize, value: Value) -> Self {
        //NOTE: This is only called by BucketInterpreter::store_value_in_address.
        //Use the map from loop unrolling to convert the SubcmpSignal reference back
        //  into the proper reference (reversing ExtractedFunctionLocationUpdater).
        let new_env = match self.remap.get(&subcmp_idx).cloned() {
            //NOTE: The ArgIndex::SubCmp 'arena' and 'counter' parameters were not added
            //  to the 'remap' (producing None result here) because those parameters are
            //  not actually used to access signals, just to call _run and update counter.
            None => *self.base,
            Some((loc, idx)) => {
                //ASSERT: ExtractedFunctionLocationUpdater will always assign 0 in
                //  the LocationRule that 'signal_idx' is computed from.
                assert_eq!(signal_idx, 0);
                match loc {
                    AddressType::Variable => self.base.set_var(idx, value),
                    AddressType::Signal => self.base.set_signal(idx, value),
                    AddressType::SubcmpSignal { cmp_address, .. } => {
                        let subcmp = match *cmp_address {
                            Instruction::Value(ValueBucket {
                                parse_as: ValueType::U32,
                                value,
                                ..
                            }) => value,
                            _ => unreachable!(), //ASSERT: 'cmp_address' was formed by 'loop_unroll::new_u32_value'
                        };
                        self.base.set_subcmp_signal(subcmp, idx, value)
                    }
                }
            }
        };
        ExtractedFuncEnvData { base: Box::new(new_env), remap: self.remap }
    }

    pub fn decrease_subcmp_counter(self, subcmp_idx: usize) -> Self {
        let new_env = match self.remap.get(&subcmp_idx).cloned() {
            //NOTE: The ArgIndex::SubCmp 'arena' and 'counter' parameters were not added
            //  to the 'remap' (producing None result here) because those parameters are
            //  not actually used to access signals, just to call _run and update counter.
            //  No counter update needed when SubcmpSignal is used for these special cases.
            None => *self.base,
            Some((loc, _)) => {
                match loc {
                    AddressType::SubcmpSignal { cmp_address, .. } => {
                        let subcmp = match *cmp_address {
                            Instruction::Value(ValueBucket {
                                parse_as: ValueType::U32,
                                value,
                                ..
                            }) => value,
                            _ => unreachable!(), //ASSERT: 'cmp_address' was formed by 'loop_unroll::new_u32_value'
                        };
                        self.base.decrease_subcmp_counter(subcmp)
                    }
                    _ => *self.base, // no counter for Variable/Signal types
                }
            }
        };
        ExtractedFuncEnvData { base: Box::new(new_env), remap: self.remap }
    }

    pub fn run_subcmp(
        self,
        _subcmp_idx: usize,
        _name: &String,
        _interpreter: &BucketInterpreter,
        _observe: bool,
    ) -> Self {
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
