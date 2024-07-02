use std::cell::Ref;
use std::collections::BTreeMap;
use std::fmt::{Display, Formatter};
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::TemplateCode;
use compiler::intermediate_representation::BucketId;
use crate::bucket_interpreter::BucketInterpreter;
use crate::bucket_interpreter::error::BadInterp;
use crate::bucket_interpreter::value::Value;
use crate::passes::loop_unroll::LOOP_BODY_FN_PREFIX;
use crate::passes::loop_unroll::body_extractor::LoopBodyExtractor;
use super::{CallStack, Env, EnvContextKind, LibraryAccess};

/// This Env is used by the loop unroller to process the BlockBucket containing a
/// unrolled loop specifically handling the case where the LibraryAccess does not
/// contain the functions generated to hold the extracted loop bodies. It instead
/// uses the temporary list in the LoopBodyExtractor to get those function bodies.
#[derive(Clone)]
pub struct UnrolledBlockEnvData<'a> {
    base: Box<Env<'a>>,
    extractor: &'a LoopBodyExtractor,
}

impl Display for UnrolledBlockEnvData<'_> {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        write!(f, "UnrolledBlockEnv{{")?;
        self.base.fmt(f)?;
        write!(f, "}}")
    }
}

impl LibraryAccess for UnrolledBlockEnvData<'_> {
    fn get_function(&self, name: &String) -> Ref<FunctionCode> {
        if name.starts_with(LOOP_BODY_FN_PREFIX) {
            self.extractor.search_new_functions(name)
        } else {
            self.base.get_function(name)
        }
    }

    fn get_template(&self, name: &String) -> Ref<TemplateCode> {
        self.base.get_template(name)
    }
}

macro_rules! new_env {
    ($base:expr, $extractor:expr) => {
        UnrolledBlockEnvData { base: Box::new($base), extractor: $extractor }
    };
}

impl<'a> UnrolledBlockEnvData<'a> {
    pub fn new(base: Env<'a>, extractor: &'a LoopBodyExtractor) -> Self {
        new_env!(base, extractor)
    }

    pub fn function_caller(&self) -> Option<&BucketId> {
        self.base.function_caller()
    }

    pub fn get_context_kind(&self) -> EnvContextKind {
        self.base.get_context_kind()
    }

    pub fn get_call_stack(&self) -> CallStack {
        self.base.get_call_stack()
    }

    pub fn get_var(&self, idx: usize) -> Value {
        self.base.get_var(idx)
    }

    pub fn get_signal(&self, idx: usize) -> Value {
        self.base.get_signal(idx)
    }

    pub fn get_subcmp_signal(&self, subcmp_idx: usize, signal_idx: usize) -> Value {
        self.base.get_subcmp_signal(subcmp_idx, signal_idx)
    }

    pub fn get_subcmp_name(&self, subcmp_idx: usize) -> &String {
        self.base.get_subcmp_name(subcmp_idx)
    }

    pub fn get_subcmp_template_id(&self, subcmp_idx: usize) -> usize {
        self.base.get_subcmp_template_id(subcmp_idx)
    }

    pub fn get_subcmp_counter(&self, subcmp_idx: usize) -> Value {
        self.base.get_subcmp_counter(subcmp_idx)
    }

    pub fn subcmp_counter_is_zero(&self, subcmp_idx: usize) -> bool {
        self.base.subcmp_counter_is_zero(subcmp_idx)
    }

    pub fn subcmp_counter_equal_to(&self, subcmp_idx: usize, value: usize) -> bool {
        self.base.subcmp_counter_equal_to(subcmp_idx, value)
    }

    pub fn get_vars_sort(&self) -> BTreeMap<usize, Value> {
        self.base.get_vars_sort()
    }

    pub fn set_var(self, idx: usize, value: Value) -> Self {
        new_env!(self.base.set_var(idx, value), self.extractor)
    }

    pub fn set_signal(self, idx: usize, value: Value) -> Self {
        new_env!(self.base.set_signal(idx, value), self.extractor)
    }

    pub fn set_vars_to_unk<T: IntoIterator<Item = usize>>(self, idxs: Option<T>) -> Self {
        new_env!(self.base.set_vars_to_unk(idxs), self.extractor)
    }

    pub fn set_signals_to_unk<T: IntoIterator<Item = usize>>(self, idxs: Option<T>) -> Self {
        new_env!(self.base.set_signals_to_unk(idxs), self.extractor)
    }

    pub fn set_subcmps_to_unk<T: IntoIterator<Item = usize>>(
        self,
        subcmp_idxs: Option<T>,
    ) -> Result<Self, BadInterp> {
        Ok(new_env!(self.base.set_subcmps_to_unk(subcmp_idxs)?, self.extractor))
    }

    pub fn set_subcmp_signal(
        self,
        subcmp_idx: usize,
        signal_idx: usize,
        value: Value,
    ) -> Result<Self, BadInterp> {
        Ok(new_env!(self.base.set_subcmp_signal(subcmp_idx, signal_idx, value)?, self.extractor))
    }

    pub fn set_subcmp_counter(self, subcmp_idx: usize, new_val: usize) -> Result<Self, BadInterp> {
        Ok(new_env!(self.base.set_subcmp_counter(subcmp_idx, new_val)?, self.extractor))
    }

    pub fn decrease_subcmp_counter(self, subcmp_idx: usize) -> Result<Self, BadInterp> {
        Ok(new_env!(self.base.decrease_subcmp_counter(subcmp_idx)?, self.extractor))
    }

    pub fn run_subcmp(
        self,
        subcmp_idx: usize,
        name: &String,
        interpreter: &BucketInterpreter,
    ) -> Self {
        new_env!(self.base.run_subcmp(subcmp_idx, name, interpreter), self.extractor)
    }

    pub fn create_subcmp(
        self,
        name: &String,
        base_index: usize,
        count: usize,
        template_id: usize,
    ) -> Self {
        new_env!(self.base.create_subcmp(name, base_index, count, template_id), self.extractor)
    }
}
