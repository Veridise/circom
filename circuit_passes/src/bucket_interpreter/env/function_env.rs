use std::cell::Ref;
use std::collections::{BTreeMap, HashMap};
use std::fmt::{Display, Formatter};
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::TemplateCode;
use compiler::intermediate_representation::ir_interface::AddressType;
use compiler::intermediate_representation::BucketId;
use crate::bucket_interpreter::error::BadInterp;
use crate::bucket_interpreter::write_collector::Writes;
use crate::bucket_interpreter::{BucketInterpreter, CALL_STACK_LIMIT};
use crate::bucket_interpreter::value::Value;
use super::{sort, CallStack, CallStackFrame, Env, EnvContextKind, LibraryAccess, PRINT_ENV_SORTED};

/// This Env is used for Circom source functions.
#[derive(Clone)]
pub struct FunctionEnvData<'a> {
    caller_stack: Vec<BucketId>,
    vars: HashMap<usize, Value>,
    libs: &'a dyn LibraryAccess,
    /// This call stack is used to prevent the Rust stack from overflowing due to recursive
    /// calls in the Circom source where termination cannot be determined by the intepreter.
    //  Implementation note: Store a snapshot of the CallStack in each Env rather than having
    //  each store only its relevant CallStackFrame and having append_stack_if_safe_to_interpret() recursively
    //  check the base Env because that lookup would further increase the Rust stack height
    //  while doing the check that is intended to prevent Rust stack exhaustion.
    call_stack: CallStack,
}

impl Display for FunctionEnvData<'_> {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        if PRINT_ENV_SORTED {
            write!(
                f,
                "FunctionEnv{{\n  ctx = {:?}\n  vars = {:?}\n}}",
                self.caller_stack,
                sort(&self.vars, std::convert::identity),
            )
        } else {
            write!(
                f,
                "FunctionEnv{{\n  ctx = {:?}\n  vars = {:?}\n}}",
                self.caller_stack, self.vars,
            )
        }
    }
}

impl LibraryAccess for FunctionEnvData<'_> {
    fn get_function(&self, name: &String) -> Ref<FunctionCode> {
        self.libs.get_function(name)
    }

    fn get_template(&self, name: &String) -> Ref<TemplateCode> {
        self.libs.get_template(name)
    }
}

impl<'a> FunctionEnvData<'a> {
    pub fn new(
        base: Env<'a>,
        caller: &BucketId,
        call_stack: CallStack,
        libs: &'a dyn LibraryAccess,
    ) -> Self {
        let mut caller_stack = base.get_caller_stack().to_vec();
        caller_stack.push(*caller);
        FunctionEnvData { caller_stack, call_stack, vars: Default::default(), libs }
    }

    // READ OPERATIONS
    pub fn get_context_kind(&self) -> EnvContextKind {
        EnvContextKind::SourceFunction
    }

    pub fn append_stack_if_safe_to_interpret(
        &self,
        new_frame: CallStackFrame,
    ) -> Option<CallStack> {
        if !self.call_stack.contains(&new_frame) && self.call_stack.depth() <= CALL_STACK_LIMIT {
            Some(self.call_stack.clone().push(new_frame))
        } else {
            None
        }
    }

    pub fn get_caller_stack(&self) -> &[BucketId] {
        &self.caller_stack
    }

    pub fn get_var(&self, idx: usize) -> Value {
        self.vars.get(&idx).unwrap_or_default().clone()
    }

    pub fn get_signal(&self, _idx: usize) -> Value {
        // There are no signals in source functions.
        unreachable!()
    }

    pub fn get_subcmp_signal(&self, _subcmp_idx: usize, _signal_idx: usize) -> Value {
        // There are no components in source functions.
        unreachable!()
    }

    pub fn get_subcmp_name(&self, _subcmp_idx: usize) -> &String {
        // There are no components in source functions.
        unreachable!()
    }

    pub fn get_subcmp_template_id(&self, _subcmp_idx: usize) -> usize {
        // There are no components in source functions.
        unreachable!()
    }

    pub fn get_subcmp_counter(&self, _subcmp_idx: usize) -> Value {
        // There are no components in source functions.
        unreachable!()
    }

    pub fn subcmp_counter_is_zero(&self, _subcmp_idx: usize) -> bool {
        // There are no components in source functions.
        unreachable!()
    }

    pub fn subcmp_counter_equal_to(&self, _subcmp_idx: usize, _value: usize) -> bool {
        // There are no components in source functions.
        unreachable!()
    }

    pub fn get_vars_sort(&self) -> BTreeMap<usize, Value> {
        sort(&self.vars, Clone::clone)
    }

    pub fn collect_write(
        &self,
        dest_address_type: &AddressType,
        idx: usize,
        collector: &mut Writes,
    ) {
        match dest_address_type {
            AddressType::Variable => collector.vars.as_mut().map(|s| s.insert(idx)),
            AddressType::Signal => collector.signals.as_mut().map(|s| s.insert(idx)),
            AddressType::SubcmpSignal { .. } => unreachable!("Source function cannot have subcmp"),
        };
    }

    // WRITE OPERATIONS
    pub fn set_var(self, idx: usize, value: Value) -> Self {
        let mut copy = self;
        copy.vars.insert(idx, value);
        copy
    }

    pub fn set_signal(self, _idx: usize, _value: Value) -> Self {
        // There are no signals in source functions.
        unreachable!()
    }

    pub fn set_vars_to_unk<T: IntoIterator<Item = usize>>(self, idxs: Option<T>) -> Self {
        let mut copy = self;
        if let Some(idxs) = idxs {
            for idx in idxs {
                copy.vars.insert(idx, Value::Unknown);
            }
        } else {
            for (_, v) in copy.vars.iter_mut() {
                *v = Value::Unknown;
            }
        }
        copy
    }

    pub fn set_signals_to_unknown<T: IntoIterator<Item = usize>>(self, idxs: Option<T>) -> Self {
        // There are no signals in source functions.
        // This function is not unreachable because it may be called without actually
        //  encountering any signal references, thus the input must be None or empty.
        assert!(idxs.is_none() || idxs.is_some_and(|e| e.into_iter().next().is_none()));
        self
    }

    pub fn set_subcmps_to_unk<T: IntoIterator<Item = usize>>(
        self,
        idxs: Option<T>,
    ) -> Result<Self, BadInterp> {
        // There are no components in source functions.
        // This function is not unreachable because it may be called without actually
        //  encountering any signal references, thus the input must be None or empty.
        assert!(idxs.is_none() || idxs.is_some_and(|e| e.into_iter().next().is_none()));
        Ok(self)
    }

    pub fn set_subcmp_signal(
        self,
        _subcmp_idx: usize,
        _signal_idx: usize,
        _value: Value,
    ) -> Result<Self, BadInterp> {
        // There are no components in source functions.
        unreachable!()
    }

    pub fn set_subcmp_counter(
        self,
        _subcmp_idx: usize,
        _new_val: usize,
    ) -> Result<Self, BadInterp> {
        // There are no components in source functions.
        unreachable!()
    }

    pub fn decrease_subcmp_counter(self, _subcmp_idx: usize) -> Result<Self, BadInterp> {
        // There are no components in source functions.
        unreachable!()
    }

    pub fn run_subcmp(
        self,
        _subcmp_idx: usize,
        _name: &String,
        _interpreter: &BucketInterpreter,
    ) -> Self {
        // There are no components in source functions.
        unreachable!()
    }

    pub fn create_subcmp(
        self,
        _name: &String,
        _base_index: usize,
        _count: usize,
        _template_id: usize,
    ) -> Self {
        // There are no components in source functions.
        unreachable!()
    }
}
