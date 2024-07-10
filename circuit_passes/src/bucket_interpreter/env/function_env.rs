use std::cell::Ref;
use std::collections::{BTreeMap, HashMap, hash_map::Entry};
use std::fmt::{Display, Formatter};
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::TemplateCode;
use compiler::intermediate_representation::BucketId;
use crate::bucket_interpreter::error::{new_inconsistency_err, BadInterp};
use crate::bucket_interpreter::{BucketInterpreter, CALL_STACK_LIMIT};
use crate::bucket_interpreter::value::Value;
use super::{
    sort, CallStack, CallStackFrame, Env, EnvContextKind, LibraryAccess, SubcmpEnv,
    PRINT_ENV_SORTED,
};

#[derive(Clone)]
pub struct FunctionEnvData<'a> {
    caller_stack: Vec<BucketId>,
    // Store a snapshot of the CallStack in each Env rather than having each Env store
    //  only its relevant CallStackFrame and having safe_to_interpret() recursively check
    //  the base Env because that lookup would further increase the Rust stack height
    //  while doing the check that is intended to prevent Rust stack exhaustion.
    call_stack: CallStack,
    vars: HashMap<usize, Value>,
    signals: HashMap<usize, Value>,
    subcmps: HashMap<usize, SubcmpEnv>,
    subcmp_names: HashMap<usize, String>,
    libs: &'a dyn LibraryAccess,
}

impl Display for FunctionEnvData<'_> {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        if PRINT_ENV_SORTED {
            write!(
                f,
                "FunctionEnv{{\n  ctx = {:?}\n  vars = {:?}\n  signals = {:?}\n  names = {:?}\n  subcmps = {:?}\n}}",
                self.caller_stack,
                sort(&self.vars, std::convert::identity),
                sort(&self.signals, std::convert::identity),
                sort(&self.subcmp_names, std::convert::identity),
                sort(&self.subcmps, std::convert::identity)
            )
        } else {
            write!(
                f,
                "FunctionEnv{{\n  ctx = {:?}\n  vars = {:?}\n  signals = {:?}\n  names = {:?}\n  subcmps = {:?}\n}}",
                self.caller_stack, self.vars, self.signals, self.subcmp_names, self.subcmps
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
        FunctionEnvData {
            caller_stack,
            call_stack,
            vars: Default::default(),
            signals: Default::default(),
            subcmps: Default::default(),
            subcmp_names: Default::default(),
            libs,
        }
    }

    // READ OPERATIONS
    pub fn get_context_kind(&self) -> EnvContextKind {
        EnvContextKind::SourceFunction
    }

    pub fn safe_to_interpret(&self, new_frame: CallStackFrame) -> Option<CallStack> {
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

    pub fn get_signal(&self, idx: usize) -> Value {
        self.signals.get(&idx).unwrap_or_default().clone()
    }

    pub fn get_subcmp_signal(&self, subcmp_idx: usize, signal_idx: usize) -> Value {
        self.subcmps[&subcmp_idx].get_signal(signal_idx)
    }

    pub fn get_subcmp_name(&self, subcmp_idx: usize) -> &String {
        &self.subcmp_names[&self.subcmps[&subcmp_idx].template_id]
    }

    pub fn get_subcmp_template_id(&self, subcmp_idx: usize) -> usize {
        self.subcmps[&subcmp_idx].template_id
    }

    pub fn get_subcmp_counter(&self, subcmp_idx: usize) -> Value {
        Value::KnownU32(self.subcmps.get(&subcmp_idx).unwrap().get_counter())
    }

    pub fn subcmp_counter_is_zero(&self, subcmp_idx: usize) -> bool {
        self.subcmps.get(&subcmp_idx).unwrap().counter_is_zero()
    }

    pub fn subcmp_counter_equal_to(&self, subcmp_idx: usize, value: usize) -> bool {
        self.subcmps.get(&subcmp_idx).unwrap().counter_equal_to(value)
    }

    pub fn get_vars_sort(&self) -> BTreeMap<usize, Value> {
        sort(&self.vars, Clone::clone)
    }

    // WRITE OPERATIONS
    pub fn set_var(self, idx: usize, value: Value) -> Self {
        let mut copy = self;
        copy.vars.insert(idx, value);
        copy
    }

    pub fn set_signal(self, idx: usize, value: Value) -> Self {
        let mut copy = self;
        copy.signals.insert(idx, value);
        copy
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

    pub fn set_signals_to_unk<T: IntoIterator<Item = usize>>(self, idxs: Option<T>) -> Self {
        let mut copy = self;
        if let Some(idxs) = idxs {
            for idx in idxs {
                copy.signals.insert(idx, Value::Unknown);
            }
        } else {
            for (_, v) in copy.signals.iter_mut() {
                *v = Value::Unknown;
            }
        }
        copy
    }

    pub fn set_subcmps_to_unk<T: IntoIterator<Item = usize>>(
        self,
        subcmp_idxs: Option<T>,
    ) -> Result<Self, BadInterp> {
        let mut copy = self;
        if let Some(idxs) = subcmp_idxs {
            for idx in idxs {
                copy = copy.update_subcmp(idx, SubcmpEnv::reset)?;
            }
        } else {
            for (_, v) in copy.subcmps.iter_mut() {
                v.signals.clear();
            }
        }
        Ok(copy)
    }

    pub fn set_subcmp_signal(
        self,
        subcmp_idx: usize,
        signal_idx: usize,
        value: Value,
    ) -> Result<Self, BadInterp> {
        self.update_subcmp(subcmp_idx, |e| e.set_signal(signal_idx, value))
    }

    pub fn set_subcmp_counter(self, subcmp_idx: usize, new_val: usize) -> Result<Self, BadInterp> {
        self.update_subcmp(subcmp_idx, |e| e.set_counter(new_val))
    }

    pub fn decrease_subcmp_counter(self, subcmp_idx: usize) -> Result<Self, BadInterp> {
        self.update_subcmp(subcmp_idx, SubcmpEnv::decrease_counter)
    }

    fn update_subcmp(
        self,
        subcmp_idx: usize,
        f: impl FnOnce(&mut SubcmpEnv),
    ) -> Result<Self, BadInterp> {
        let mut copy = self;
        match copy.subcmps.entry(subcmp_idx) {
            Entry::Occupied(mut entry) => {
                f(entry.get_mut());
                Ok(copy)
            }
            Entry::Vacant(_) => Result::Err(new_inconsistency_err(format!(
                "Can't find subcomponent {}",
                subcmp_idx
            ))),
        }
    }

    pub fn run_subcmp(
        self,
        _subcmp_idx: usize,
        _name: &String,
        _interpreter: &BucketInterpreter,
    ) -> Self {
        // The env returns Unknown by default to any index that does not have a value
        // So we can fake executing a subcomponent and any read to the output
        // of a subcomponent will return Unknown which is the only value that signals can have.
        self
    }

    pub fn create_subcmp(
        self,
        name: &String,
        base_index: usize,
        count: usize,
        template_id: usize,
    ) -> Self {
        let mut copy = self;

        match copy.subcmp_names.get(&template_id) {
            None => {
                copy.subcmp_names.insert(template_id, name.clone());
            }
            Some(old) => {
                assert_eq!(old, name);
            }
        }

        let number_of_inputs = copy.get_template(name).number_of_inputs;
        for i in base_index..(base_index + count) {
            let old = copy.subcmps.insert(i, SubcmpEnv::new(number_of_inputs, template_id));
            assert!(old.is_none()); //no keys are overwritten
        }
        copy
    }
}