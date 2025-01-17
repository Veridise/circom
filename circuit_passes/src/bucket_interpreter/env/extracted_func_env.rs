use std::cell::Ref;
use std::collections::{BTreeMap, HashSet};
use std::fmt::{Display, Formatter};
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::TemplateCode;
use compiler::intermediate_representation::{BucketId, Instruction, InstructionPointer};
use compiler::intermediate_representation::ir_interface::{AddressType, ValueBucket, ValueType};
use crate::bucket_interpreter::write_collector::Writes;
use crate::bucket_interpreter::BucketInterpreter;
use crate::bucket_interpreter::error::BadInterp;
use crate::bucket_interpreter::value::Value;
use crate::passes::loop_unroll::{ToOriginalLocation, FuncArgIdx};
use super::{CallStack, CallStackFrame, Env, EnvContextKind, LibraryAccess};

/// This Env is used to process functions created by extracting loop bodies
/// into 'LOOP_BODY_FN_PREFIX' functions. It has to interpret the references
/// produced by ExtractedFunctionLocationUpdater (i.e. some loads and stores
/// are converted to AddressType::SubcmpSignal that indicate which function
/// parameter holds the necessary data).
#[derive(Clone)]
pub struct ExtractedFuncEnvData<'a> {
    base: Box<Env<'a>>,
    caller_stack: Vec<BucketId>,
    remap: ToOriginalLocation,
    arenas: HashSet<FuncArgIdx>,
}

macro_rules! with_updated_base {
    ($self: expr, $base: expr) => {{
        ExtractedFuncEnvData::copy($base, $self.caller_stack, $self.remap, $self.arenas)
    }};
}

impl Display for ExtractedFuncEnvData<'_> {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "ExtractedFuncEnv{{\n  caller_stack = {:?}\n  remap = {:?}\n  arenas = {:?}\n  base = {:?}\n}}",
            self.caller_stack, self.remap, self.arenas, self.base,
        )
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
        base: Env<'a>,
        caller: &BucketId,
        remap: ToOriginalLocation,
        arenas: HashSet<FuncArgIdx>,
    ) -> Self {
        let mut caller_stack = base.get_caller_stack().to_vec();
        caller_stack.push(*caller);
        ExtractedFuncEnvData { base: Box::new(base), caller_stack, remap, arenas }
    }

    fn copy(
        base: Env<'a>,
        caller_stack: Vec<BucketId>,
        remap: ToOriginalLocation,
        arenas: HashSet<FuncArgIdx>,
    ) -> Self {
        ExtractedFuncEnvData { base: Box::new(base), caller_stack, remap, arenas }
    }

    #[inline]
    fn unwrap_subcmp_idx(cmp_address: &InstructionPointer) -> usize {
        match **cmp_address {
            Instruction::Value(ValueBucket { parse_as: ValueType::U32, value, .. }) => value,
            _ => unreachable!(), //ASSERT: 'cmp_address' was formed by 'loop_unroll::new_u32_value'
        }
    }

    #[inline]
    fn convert_subcmp_idx_default(
        idx: usize,
        counter_override: &bool,
        cmp_address: &InstructionPointer,
    ) -> usize {
        if *counter_override {
            unreachable!();
        } else {
            //ASSERT: ExtractedFunctionLocationUpdater will always assign 0 in
            //  the LocationRule that 'idx' is computed from.
            assert_eq!(idx, 0);
            Self::unwrap_subcmp_idx(cmp_address)
        }
    }

    pub fn get_base(self) -> Env<'a> {
        *self.base
    }

    pub fn get_context_kind(&self) -> EnvContextKind {
        EnvContextKind::ExtractedFunction
    }

    pub fn append_stack_if_safe_to_interpret(
        &self,
        new_frame: CallStackFrame,
    ) -> Option<CallStack> {
        self.base.append_stack_if_safe_to_interpret(new_frame)
    }

    pub fn get_caller_stack(&self) -> &[BucketId] {
        &self.caller_stack
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
                //ASSERT: All parameters besides ArgIndex::SubCmp 'arena' parameters are in 'self.remap'.
                assert!(
                    self.arenas.contains(&subcmp_idx),
                    "Index not remapped and not an arena parameter: {}",
                    subcmp_idx
                );
                unreachable!();
            }
            Some((loc, idx)) => {
                let idx = signal_idx + idx;
                match loc {
                    AddressType::Variable => self.base.get_var(idx),
                    AddressType::Signal => self.base.get_signal(idx),
                    AddressType::SubcmpSignal { counter_override, cmp_address, .. } => {
                        let subcmp_idx = Self::unwrap_subcmp_idx(cmp_address);
                        if *counter_override {
                            // ASSERT: always 0 from 'get_reverse_passing_refs_for_itr' in 'body_extractor.rs'
                            assert_eq!(idx, 0);
                            self.base.get_subcmp_counter(subcmp_idx)
                        } else {
                            self.base.get_subcmp_signal(subcmp_idx, idx)
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
                //ASSERT: All parameters besides ArgIndex::SubCmp 'arena' parameters are in 'self.remap'.
                assert!(
                    self.arenas.contains(&subcmp_idx),
                    "Index not remapped and not an arena parameter: {}",
                    subcmp_idx
                );
                unreachable!();
            }
            Some((loc, idx)) => {
                let idx = match loc {
                    AddressType::Variable => *idx,
                    AddressType::Signal => *idx,
                    AddressType::SubcmpSignal { counter_override, cmp_address, .. } => {
                        Self::convert_subcmp_idx_default(*idx, counter_override, cmp_address)
                    }
                };
                self.base.get_subcmp_name(idx)
            }
        }
    }

    pub fn get_subcmp_template_id(&self, subcmp_idx: usize) -> usize {
        match self.remap.get(&subcmp_idx) {
            None => {
                //ASSERT: All parameters besides ArgIndex::SubCmp 'arena' parameters are in 'self.remap'.
                assert!(
                    self.arenas.contains(&subcmp_idx),
                    "Index not remapped and not an arena parameter: {}",
                    subcmp_idx
                );
                unreachable!();
            }
            Some((loc, idx)) => {
                let idx = match loc {
                    AddressType::Variable => *idx,
                    AddressType::Signal => *idx,
                    AddressType::SubcmpSignal { counter_override, cmp_address, .. } => {
                        Self::convert_subcmp_idx_default(*idx, counter_override, cmp_address)
                    }
                };
                self.base.get_subcmp_template_id(idx)
            }
        }
    }

    pub fn get_subcmp_counter(&self, _subcmp_idx: usize) -> Value {
        todo!()
    }

    pub fn subcmp_counter_is_zero(&self, subcmp_idx: usize) -> bool {
        match self.remap.get(&subcmp_idx) {
            None => {
                //ASSERT: All parameters besides ArgIndex::SubCmp 'arena' parameters are in 'self.remap'.
                assert!(
                    self.arenas.contains(&subcmp_idx),
                    "Index not remapped and not an arena parameter: {}",
                    subcmp_idx
                );
                // This will be reached for the StoreBucket that generates a call to the "_run" function.
                return true; // True to execute the run_subcmp function
            }
            Some((loc, _)) => {
                match loc {
                    AddressType::SubcmpSignal { counter_override, cmp_address, .. } => {
                        self.base.subcmp_counter_is_zero(Self::convert_subcmp_idx_default(
                            0,
                            counter_override,
                            cmp_address,
                        ))
                    }
                    _ => false, // no counter for Variable/Signal types
                }
            }
        }
    }

    pub fn subcmp_counter_equal_to(&self, subcmp_idx: usize, value: usize) -> bool {
        let res = match self.remap.get(&subcmp_idx) {
            None => {
                //ASSERT: All parameters besides ArgIndex::SubCmp 'arena' parameters are in 'self.remap'.
                assert!(
                    self.arenas.contains(&subcmp_idx),
                    "Index not remapped and not an arena parameter: {}",
                    subcmp_idx
                );
                unreachable!();
            }
            Some((loc, _)) => {
                match loc {
                    AddressType::SubcmpSignal { counter_override, cmp_address, .. } => {
                        self.base.subcmp_counter_equal_to(
                            Self::convert_subcmp_idx_default(0, counter_override, cmp_address),
                            value,
                        )
                    }
                    _ => false, // no counter for Variable/Signal types
                }
            }
        };
        res
    }

    pub fn get_vars_sort(&self) -> BTreeMap<usize, Value> {
        self.base.get_vars_sort()
    }

    pub fn collect_write(
        &self,
        dest_address_type: &AddressType,
        idx: usize,
        collector: &mut Writes,
    ) {
        match dest_address_type {
            AddressType::Variable => {
                collector.vars.as_mut().map(|s| s.insert(idx));
            }
            AddressType::Signal => {
                collector.signals.as_mut().map(|s| s.insert(idx));
            }
            AddressType::SubcmpSignal { counter_override, cmp_address, .. } => {
                // Within an extracted function body, these are actually parameter references
                //  with the index stored in the 'cmp_address' instead of 'idx'.
                let subcmp_idx =
                    Self::convert_subcmp_idx_default(idx, counter_override, cmp_address);
                match self.remap.get(&subcmp_idx) {
                    None => {
                        //ASSERT: All parameters besides ArgIndex::SubCmp 'arena' parameters are in 'self.remap'.
                        assert!(
                            self.arenas.contains(&subcmp_idx),
                            "Index not remapped and not an arena parameter: {}",
                            subcmp_idx
                        );
                        unreachable!()
                    }
                    Some((loc, idx)) => {
                        self.base.collect_write(loc, *idx, collector);
                    }
                }
            }
        }
    }

    pub fn set_var(self, idx: usize, value: Value) -> Self {
        // Local variables are referenced in the normal way
        with_updated_base!(self, self.base.set_var(idx, value))
    }

    pub fn set_signal(self, idx: usize, value: Value) -> Self {
        // Signals are referenced in the normal way
        with_updated_base!(self, self.base.set_signal(idx, value))
    }

    pub fn set_vars_to_unknown<T: IntoIterator<Item = usize>>(self, idxs: Option<T>) -> Self {
        // Local variables are referenced in the normal way
        with_updated_base!(self, self.base.set_vars_to_unknown(idxs))
    }

    pub fn set_signals_to_unknown<T: IntoIterator<Item = usize>>(self, idxs: Option<T>) -> Self {
        // Signals are referenced in the normal way
        with_updated_base!(self, self.base.set_signals_to_unknown(idxs))
    }

    pub fn set_subcmps_to_unknown<T: IntoIterator<Item = usize>>(
        self,
        subcmp_idxs: Option<T>,
    ) -> Result<Self, BadInterp> {
        // The indexes passed in here are already converted within 'write_collector.rs' via
        //  interpreting the LocationRule and performing the PassMemory lookup on the
        //  unchanged scope (per comment in BucketInterpreter::_execute_function_extracted).
        Ok(with_updated_base!(self, self.base.set_subcmps_to_unknown(subcmp_idxs)?))
    }

    pub fn set_subcmp_signal(
        self,
        subcmp_idx: usize,
        signal_idx: usize,
        new_value: Value,
    ) -> Result<Self, BadInterp> {
        //NOTE: This is only called by BucketInterpreter::store_value_at_address().
        //Use the map from loop unrolling to convert the SubcmpSignal reference back
        //  into the proper reference (reversing ExtractedFunctionLocationUpdater).
        let new_env = match self.remap.get(&subcmp_idx) {
            None => {
                //ASSERT: All parameters besides ArgIndex::SubCmp 'arena' parameters are in 'self.remap'.
                assert!(
                    self.arenas.contains(&subcmp_idx),
                    "Index not remapped and not an arena parameter: {}",
                    subcmp_idx
                );
                // This will be reached for the StoreBucket that generates a call to the "_run" function.
                return Ok(self); // Nothing needs to be done.
            }
            Some((loc, idx)) => {
                let idx = signal_idx + idx;
                match loc {
                    AddressType::Variable => self.base.set_var(idx, new_value),
                    AddressType::Signal => self.base.set_signal(idx, new_value),
                    AddressType::SubcmpSignal { counter_override, cmp_address, .. } => {
                        let subcmp = Self::unwrap_subcmp_idx(cmp_address);
                        if *counter_override {
                            // ASSERT: always 0 from 'get_reverse_passing_refs_for_itr' in 'body_extractor.rs'
                            assert_eq!(idx, 0);
                            // NOTE: If unwrapping to u32 directly causes a panic, then need to allow Value as the parameter.
                            self.base.set_subcmp_counter(subcmp, new_value.as_u32()?)?
                        } else {
                            self.base.set_subcmp_signal(subcmp, idx, new_value)?
                        }
                    }
                }
            }
        };
        Ok(with_updated_base!(self, new_env))
    }

    pub fn set_subcmp_counter(
        self,
        _subcmp_idx: usize,
        _new_val: usize,
    ) -> Result<Self, BadInterp> {
        todo!()
    }

    pub fn decrease_subcmp_counter(self, _subcmp_idx: usize) -> Result<Self, BadInterp> {
        //Do nothing because subcmp counter is managed explicitly in extracted functions
        Ok(self)
    }

    pub fn run_subcmp(self, _: usize, _: &String, _: &BucketInterpreter) -> Self {
        //Return self just like the FunctionEnvData
        self
    }

    pub fn create_subcmp(
        self,
        _name: &String,
        _base_index: usize,
        _count: usize,
        _template_id: usize,
    ) -> Self {
        unreachable!()
    }
}
