use std::cell::Ref;
use std::collections::{HashMap, BTreeMap, HashSet};
use std::fmt::{Display, Formatter};
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::TemplateCode;
use compiler::intermediate_representation::BucketId;
use function_env::FunctionEnvData;
use indexmap::IndexSet;
use crate::passes::loop_unroll::body_extractor::{LoopBodyExtractor, ToOriginalLocation, FuncArgIdx};
use self::extracted_func_env::ExtractedFuncEnvData;
use self::template_env::TemplateEnvData;
use self::unrolled_block_env::UnrolledBlockEnvData;
use super::BucketInterpreter;
use super::error::BadInterp;
use super::value::Value;

mod template_env;
mod function_env;
mod unrolled_block_env;
mod extracted_func_env;

const PRINT_ENV_SORTED: bool = true;

#[inline]
pub fn sort<'a, V1, V2, T: IntoIterator<Item = (&'a usize, V1)>>(
    map: T,
    func: fn(V1) -> V2,
) -> BTreeMap<usize, V2> {
    map.into_iter().fold(BTreeMap::new(), |mut acc, (k, v)| {
        acc.insert(*k, func(v));
        acc
    })
}

pub trait LibraryAccess {
    fn get_function(&self, name: &String) -> Ref<FunctionCode>;
    fn get_template(&self, name: &String) -> Ref<TemplateCode>;
}

#[derive(Clone, Eq, PartialEq)]
pub struct SubcmpEnv {
    signals: HashMap<usize, Value>,
    counter: usize,
    template_id: usize,
}

impl std::fmt::Debug for SubcmpEnv {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        if PRINT_ENV_SORTED {
            write!(
                f,
                "SubcmpEnv{{ template_id = {:?}, counter = {:?}, signals = {:?} }}",
                self.template_id,
                self.counter,
                sort(&self.signals, std::convert::identity)
            )
        } else {
            write!(
                f,
                "SubcmpEnv{{ template_id = {:?}, counter = {:?}, signals = {:?} }}",
                self.template_id, self.counter, self.signals
            )
        }
    }
}

impl SubcmpEnv {
    pub fn new(inputs: usize, template_id: usize) -> Self {
        SubcmpEnv { signals: Default::default(), counter: inputs, template_id }
    }

    pub fn reset(&mut self) {
        self.signals.clear();
    }

    pub fn get_signal(&self, index: usize) -> Value {
        self.signals.get(&index).unwrap_or_default().clone()
    }

    pub fn set_signal(&mut self, idx: usize, value: Value) {
        self.signals.insert(idx, value);
    }

    pub fn get_counter(&self) -> usize {
        self.counter
    }

    pub fn set_counter(&mut self, new_val: usize) {
        self.counter = new_val;
    }

    pub fn counter_is_zero(&self) -> bool {
        self.counter == 0
    }

    pub fn decrease_counter(&mut self) {
        self.counter -= 1;
    }

    pub fn counter_equal_to(&self, value: usize) -> bool {
        self.counter == value
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Ord, PartialOrd, Hash)]
pub enum EnvContextKind {
    Template,
    SourceFunction,
    ExtractedFunction,
}

#[derive(Clone, Debug, Default, Eq, PartialEq, Ord, PartialOrd, Hash)]
pub struct CallStackFrame {
    name: String,
    args: Vec<Value>,
}

impl CallStackFrame {
    pub fn new(name: String, args: Vec<Value>) -> CallStackFrame {
        CallStackFrame { name, args }
    }
}

#[derive(Clone, Debug)]
pub struct CallStack {
    // Uses IndexSet to preserve stack ordering but with fast contains() check
    frames: IndexSet<CallStackFrame>,
}

impl CallStack {
    pub fn new(f: CallStackFrame) -> CallStack {
        let mut frames = IndexSet::default();
        frames.insert(f);
        CallStack { frames }
    }

    pub fn contains(&self, f: &CallStackFrame) -> bool {
        self.frames.contains(f)
    }

    pub fn depth(&self) -> usize {
        self.frames.len()
    }

    pub fn push(self, f: CallStackFrame) -> CallStack {
        let mut ret = self;
        let unique = ret.frames.insert(f);
        debug_assert!(unique, "called push() without first checking contains()");
        ret
    }
}

// An immutable environment whose modification methods return a new object
#[derive(Clone)]
pub enum Env<'a> {
    Template(TemplateEnvData<'a>),
    Function(FunctionEnvData<'a>),
    UnrolledBlock(UnrolledBlockEnvData<'a>),
    ExtractedFunction(ExtractedFuncEnvData<'a>),
}

macro_rules! switch_impl_read {
    ($self: ident, $func: ident $(, $args:tt)*) => {
        match $self {
            Env::Template(d) => d.$func($($args),*),
            Env::Function(d) => d.$func($($args),*),
            Env::UnrolledBlock(d) => d.$func($($args),*),
            Env::ExtractedFunction(d) => d.$func($($args),*),
        }
    };
}

macro_rules! switch_impl_write {
    ($self: ident, $func: ident $(, $args:tt)*) => {
        match $self {
            Env::Template(d) => Env::Template(d.$func($($args),*)),
            Env::Function(d) => Env::Function(d.$func($($args),*)),
            Env::UnrolledBlock(d) => Env::UnrolledBlock(d.$func($($args),*)),
            Env::ExtractedFunction(d) => Env::ExtractedFunction(d.$func($($args),*)),
        }
    };
    // This one is for inner functions that return a Result
    ($self: ident, try $func: ident $(, $args:tt)*) => {
        Ok(match $self {
            Env::Template(d) => Env::Template(d.$func($($args),*)?),
            Env::Function(d) => Env::Function(d.$func($($args),*)?),
            Env::UnrolledBlock(d) => Env::UnrolledBlock(d.$func($($args),*)?),
            Env::ExtractedFunction(d) => Env::ExtractedFunction(d.$func($($args),*)?),
        })
    };
}

impl Display for Env<'_> {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        switch_impl_read!(self, fmt, f)
    }
}

impl std::fmt::Debug for Env<'_> {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        switch_impl_read!(self, fmt, f)
    }
}

impl LibraryAccess for Env<'_> {
    fn get_function(&self, name: &String) -> Ref<FunctionCode> {
        switch_impl_read!(self, get_function, name)
    }

    fn get_template(&self, name: &String) -> Ref<TemplateCode> {
        switch_impl_read!(self, get_template, name)
    }
}

impl<'a> Env<'a> {
    pub fn new_template_env(libs: &'a dyn LibraryAccess) -> Self {
        Env::Template(TemplateEnvData::new(libs))
    }

    pub fn new_source_func_env(
        base: Env<'a>,
        caller: &BucketId,
        call_stack: CallStack,
        libs: &'a dyn LibraryAccess,
    ) -> Self {
        Env::Function(FunctionEnvData::new(base, caller, call_stack, libs))
    }

    pub fn new_extracted_func_env(
        base: Env<'a>,
        caller: &BucketId,
        remap: ToOriginalLocation,
        arenas: HashSet<FuncArgIdx>,
    ) -> Self {
        Env::ExtractedFunction(ExtractedFuncEnvData::new(base, caller, remap, arenas))
    }

    pub fn new_unroll_block_env(base: Env<'a>, extractor: &'a LoopBodyExtractor) -> Self {
        Env::UnrolledBlock(UnrolledBlockEnvData::new(base, extractor))
    }

    // READ OPERATIONS
    pub fn peel_extracted_func(self) -> Self {
        match self {
            Env::ExtractedFunction(d) => d.get_base(),
            _ => self,
        }
    }

    pub fn function_caller(&self) -> Option<&BucketId> {
        switch_impl_read!(self, function_caller)
    }

    pub fn get_context_kind(&self) -> EnvContextKind {
        switch_impl_read!(self, get_context_kind)
    }

    /// This should be used to prevent the interpreter from getting stuck due
    /// to recursive calls or an excessively large call stack in circom source.
    /// Returns None when the interpreter should not continue any further.
    pub fn safe_to_interpret(&self, new_frame: CallStackFrame) -> Option<CallStack> {
        switch_impl_read!(self, safe_to_interpret, new_frame)
    }

    pub fn get_var(&self, idx: usize) -> Value {
        switch_impl_read!(self, get_var, idx)
    }

    pub fn get_signal(&self, idx: usize) -> Value {
        switch_impl_read!(self, get_signal, idx)
    }

    pub fn get_subcmp_signal(&self, subcmp_idx: usize, signal_idx: usize) -> Value {
        switch_impl_read!(self, get_subcmp_signal, subcmp_idx, signal_idx)
    }

    pub fn get_subcmp_name(&self, subcmp_idx: usize) -> &String {
        switch_impl_read!(self, get_subcmp_name, subcmp_idx)
    }

    pub fn get_subcmp_template_id(&self, subcmp_idx: usize) -> usize {
        switch_impl_read!(self, get_subcmp_template_id, subcmp_idx)
    }

    pub fn get_subcmp_counter(&self, subcmp_idx: usize) -> Value {
        switch_impl_read!(self, get_subcmp_counter, subcmp_idx)
    }

    pub fn subcmp_counter_is_zero(&self, subcmp_idx: usize) -> bool {
        switch_impl_read!(self, subcmp_counter_is_zero, subcmp_idx)
    }

    pub fn subcmp_counter_equal_to(&self, subcmp_idx: usize, value: usize) -> bool {
        switch_impl_read!(self, subcmp_counter_equal_to, subcmp_idx, value)
    }

    pub fn get_vars_sort(&self) -> BTreeMap<usize, Value> {
        switch_impl_read!(self, get_vars_sort)
    }

    // WRITE OPERATIONS
    pub fn set_var(self, idx: usize, value: Value) -> Self {
        switch_impl_write!(self, set_var, idx, value)
    }

    pub fn set_signal(self, idx: usize, value: Value) -> Self {
        switch_impl_write!(self, set_signal, idx, value)
    }

    /// Sets the given variables to Value::Unknown, for all signals if None.
    pub fn set_vars_to_unk<T: IntoIterator<Item = usize>>(self, idxs: Option<T>) -> Self {
        switch_impl_write!(self, set_vars_to_unk, idxs)
    }

    /// Sets the given signals to Value::Unknown, for all signals if None.
    pub fn set_signals_to_unk<T: IntoIterator<Item = usize>>(self, idxs: Option<T>) -> Self {
        switch_impl_write!(self, set_signals_to_unk, idxs)
    }

    /// Sets all the signals of the given subcomponent(s) to Value::Unknown, for all subcomponents if None.
    pub fn set_subcmps_to_unk<T: IntoIterator<Item = usize>>(
        self,
        subcmp_idxs: Option<T>,
    ) -> Result<Self, BadInterp> {
        switch_impl_write!(self, try set_subcmps_to_unk, subcmp_idxs)
    }

    pub fn set_subcmp_signal(
        self,
        subcmp_idx: usize,
        signal_idx: usize,
        value: Value,
    ) -> Result<Self, BadInterp> {
        switch_impl_write!(self, try set_subcmp_signal, subcmp_idx, signal_idx, value)
    }

    pub fn set_subcmp_counter(self, subcmp_idx: usize, new_val: usize) -> Result<Self, BadInterp> {
        switch_impl_write!(self, try set_subcmp_counter, subcmp_idx, new_val)
    }

    pub fn decrease_subcmp_counter(self, subcmp_idx: usize) -> Result<Self, BadInterp> {
        switch_impl_write!(self, try decrease_subcmp_counter, subcmp_idx)
    }

    pub fn run_subcmp(
        self,
        subcmp_idx: usize,
        name: &String,
        interpreter: &BucketInterpreter,
    ) -> Self {
        switch_impl_write!(self, run_subcmp, subcmp_idx, name, interpreter)
    }

    pub fn create_subcmp(
        self,
        name: &String,
        base_index: usize,
        count: usize,
        template_id: usize,
    ) -> Self {
        switch_impl_write!(self, create_subcmp, name, base_index, count, template_id)
    }
}
