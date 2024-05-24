use std::cell::Ref;
use std::collections::{HashMap, BTreeMap, HashSet};
use std::fmt::{Display, Formatter};
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::TemplateCode;
use compiler::intermediate_representation::BucketId;
use crate::bucket_interpreter::BucketInterpreter;
use crate::bucket_interpreter::value::Value;
use crate::passes::loop_unroll::body_extractor::{LoopBodyExtractor, ToOriginalLocation, FuncArgIdx};
use self::extracted_func_env::ExtractedFuncEnvData;
use self::standard_env::StandardEnvData;
use self::unrolled_block_env::UnrolledBlockEnvData;
use super::error::BadInterp;

mod standard_env;
mod unrolled_block_env;
mod extracted_func_env;

const PRINT_ENV_SORTED: bool = true;

#[inline]
pub fn sort<'a, V1, V2, T: IntoIterator<Item = (&'a usize, V1)>>(
    map: T,
    func: fn(V1) -> V2,
) -> BTreeMap<usize, V2> {
    map.into_iter().fold(BTreeMap::new(), |mut acc, e| {
        acc.insert(*e.0, func(e.1));
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

// An immutable environment whose modification methods return a new object
#[derive(Clone)]
pub enum Env<'a> {
    Standard(StandardEnvData<'a>),
    UnrolledBlock(UnrolledBlockEnvData<'a>),
    ExtractedFunction(ExtractedFuncEnvData<'a>),
}

impl Display for Env<'_> {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            Env::Standard(d) => d.fmt(f),
            Env::UnrolledBlock(d) => d.fmt(f),
            Env::ExtractedFunction(d) => d.fmt(f),
        }
    }
}

impl std::fmt::Debug for Env<'_> {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            Env::Standard(d) => d.fmt(f),
            Env::UnrolledBlock(d) => d.fmt(f),
            Env::ExtractedFunction(d) => d.fmt(f),
        }
    }
}

impl LibraryAccess for Env<'_> {
    fn get_function(&self, name: &String) -> Ref<FunctionCode> {
        match self {
            Env::Standard(d) => d.get_function(name),
            Env::UnrolledBlock(d) => d.get_function(name),
            Env::ExtractedFunction(d) => d.get_function(name),
        }
    }

    fn get_template(&self, name: &String) -> Ref<TemplateCode> {
        match self {
            Env::Standard(d) => d.get_template(name),
            Env::UnrolledBlock(d) => d.get_template(name),
            Env::ExtractedFunction(d) => d.get_template(name),
        }
    }
}

impl<'a> Env<'a> {
    pub fn new_standard_env(context_kind: EnvContextKind, libs: &'a dyn LibraryAccess) -> Self {
        Env::Standard(StandardEnvData::new(context_kind, libs))
    }

    pub fn new_unroll_block_env(inner: Env<'a>, extractor: &'a LoopBodyExtractor) -> Self {
        Env::UnrolledBlock(UnrolledBlockEnvData::new(inner, extractor))
    }

    pub fn new_extracted_func_env(
        inner: Env<'a>,
        caller: &BucketId,
        remap: ToOriginalLocation,
        arenas: HashSet<FuncArgIdx>,
    ) -> Self {
        Env::ExtractedFunction(ExtractedFuncEnvData::new(inner, caller, remap, arenas))
    }

    // READ OPERATIONS
    pub fn peel_extracted_func(self) -> Self {
        match self {
            Env::ExtractedFunction(d) => d.get_base(),
            _ => self,
        }
    }

    pub fn extracted_func_caller(&self) -> Option<&BucketId> {
        match self {
            Env::Standard(e) => e.extracted_func_caller(),
            Env::UnrolledBlock(e) => e.extracted_func_caller(),
            Env::ExtractedFunction(e) => e.extracted_func_caller(),
        }
    }

    pub fn get_context_kind(&self) -> EnvContextKind {
        match self {
            Env::Standard(d) => d.get_context_kind(),
            Env::UnrolledBlock(d) => d.get_context_kind(),
            Env::ExtractedFunction(d) => d.get_context_kind(),
        }
    }

    pub fn get_var(&self, idx: usize) -> Value {
        match self {
            Env::Standard(d) => d.get_var(idx),
            Env::UnrolledBlock(d) => d.get_var(idx),
            Env::ExtractedFunction(d) => d.get_var(idx),
        }
    }

    pub fn get_signal(&self, idx: usize) -> Value {
        match self {
            Env::Standard(d) => d.get_signal(idx),
            Env::UnrolledBlock(d) => d.get_signal(idx),
            Env::ExtractedFunction(d) => d.get_signal(idx),
        }
    }

    pub fn get_subcmp_signal(&self, subcmp_idx: usize, signal_idx: usize) -> Value {
        match self {
            Env::Standard(d) => d.get_subcmp_signal(subcmp_idx, signal_idx),
            Env::UnrolledBlock(d) => d.get_subcmp_signal(subcmp_idx, signal_idx),
            Env::ExtractedFunction(d) => d.get_subcmp_signal(subcmp_idx, signal_idx),
        }
    }

    pub fn get_subcmp_name(&self, subcmp_idx: usize) -> &String {
        match self {
            Env::Standard(d) => d.get_subcmp_name(subcmp_idx),
            Env::UnrolledBlock(d) => d.get_subcmp_name(subcmp_idx),
            Env::ExtractedFunction(d) => d.get_subcmp_name(subcmp_idx),
        }
    }

    pub fn get_subcmp_template_id(&self, subcmp_idx: usize) -> usize {
        match self {
            Env::Standard(d) => d.get_subcmp_template_id(subcmp_idx),
            Env::UnrolledBlock(d) => d.get_subcmp_template_id(subcmp_idx),
            Env::ExtractedFunction(d) => d.get_subcmp_template_id(subcmp_idx),
        }
    }

    pub fn get_subcmp_counter(&self, subcmp_idx: usize) -> Value {
        match self {
            Env::Standard(d) => d.get_subcmp_counter(subcmp_idx),
            Env::UnrolledBlock(d) => d.get_subcmp_counter(subcmp_idx),
            Env::ExtractedFunction(d) => d.get_subcmp_counter(subcmp_idx),
        }
    }

    pub fn subcmp_counter_is_zero(&self, subcmp_idx: usize) -> bool {
        match self {
            Env::Standard(d) => d.subcmp_counter_is_zero(subcmp_idx),
            Env::UnrolledBlock(d) => d.subcmp_counter_is_zero(subcmp_idx),
            Env::ExtractedFunction(d) => d.subcmp_counter_is_zero(subcmp_idx),
        }
    }

    pub fn subcmp_counter_equal_to(&self, subcmp_idx: usize, value: usize) -> bool {
        match self {
            Env::Standard(d) => d.subcmp_counter_equal_to(subcmp_idx, value),
            Env::UnrolledBlock(d) => d.subcmp_counter_equal_to(subcmp_idx, value),
            Env::ExtractedFunction(d) => d.subcmp_counter_equal_to(subcmp_idx, value),
        }
    }

    pub fn get_vars_sort(&self) -> BTreeMap<usize, Value> {
        match self {
            Env::Standard(d) => d.get_vars_sort(),
            Env::UnrolledBlock(d) => d.get_vars_sort(),
            Env::ExtractedFunction(d) => d.get_vars_sort(),
        }
    }

    // WRITE OPERATIONS
    pub fn set_var(self, idx: usize, value: Value) -> Self {
        match self {
            Env::Standard(d) => Env::Standard(d.set_var(idx, value)),
            Env::UnrolledBlock(d) => Env::UnrolledBlock(d.set_var(idx, value)),
            Env::ExtractedFunction(d) => Env::ExtractedFunction(d.set_var(idx, value)),
        }
    }

    pub fn set_signal(self, idx: usize, value: Value) -> Self {
        match self {
            Env::Standard(d) => Env::Standard(d.set_signal(idx, value)),
            Env::UnrolledBlock(d) => Env::UnrolledBlock(d.set_signal(idx, value)),
            Env::ExtractedFunction(d) => Env::ExtractedFunction(d.set_signal(idx, value)),
        }
    }

    /// Sets the given variables to Value::Unknown, for all signals if None.
    pub fn set_vars_to_unk<T: IntoIterator<Item = usize>>(self, idxs: Option<T>) -> Self {
        match self {
            Env::Standard(d) => Env::Standard(d.set_vars_to_unk(idxs)),
            Env::UnrolledBlock(d) => Env::UnrolledBlock(d.set_vars_to_unk(idxs)),
            Env::ExtractedFunction(d) => Env::ExtractedFunction(d.set_vars_to_unk(idxs)),
        }
    }

    /// Sets the given signals to Value::Unknown, for all signals if None.
    pub fn set_signals_to_unk<T: IntoIterator<Item = usize>>(self, idxs: Option<T>) -> Self {
        match self {
            Env::Standard(d) => Env::Standard(d.set_signals_to_unk(idxs)),
            Env::UnrolledBlock(d) => Env::UnrolledBlock(d.set_signals_to_unk(idxs)),
            Env::ExtractedFunction(d) => Env::ExtractedFunction(d.set_signals_to_unk(idxs)),
        }
    }

    /// Sets all the signals of the given subcomponent(s) to Value::Unknown, for all subcomponents if None.
    pub fn set_subcmps_to_unk<T: IntoIterator<Item = usize>>(
        self,
        subcmp_idxs: Option<T>,
    ) -> Result<Self, BadInterp> {
        Ok(match self {
            Env::Standard(d) => Env::Standard(d.set_subcmps_to_unk(subcmp_idxs)?),
            Env::UnrolledBlock(d) => Env::UnrolledBlock(d.set_subcmps_to_unk(subcmp_idxs)?),
            Env::ExtractedFunction(d) => Env::ExtractedFunction(d.set_subcmps_to_unk(subcmp_idxs)?),
        })
    }

    pub fn set_subcmp_signal(
        self,
        subcmp_idx: usize,
        signal_idx: usize,
        value: Value,
    ) -> Result<Self, BadInterp> {
        Ok(match self {
            Env::Standard(d) => Env::Standard(d.set_subcmp_signal(subcmp_idx, signal_idx, value)?),
            Env::UnrolledBlock(d) => {
                Env::UnrolledBlock(d.set_subcmp_signal(subcmp_idx, signal_idx, value)?)
            }
            Env::ExtractedFunction(d) => {
                Env::ExtractedFunction(d.set_subcmp_signal(subcmp_idx, signal_idx, value)?)
            }
        })
    }

    pub fn set_subcmp_counter(self, subcmp_idx: usize, new_val: usize) -> Result<Self, BadInterp> {
        Ok(match self {
            Env::Standard(d) => Env::Standard(d.set_subcmp_counter(subcmp_idx, new_val)?),
            Env::UnrolledBlock(d) => Env::UnrolledBlock(d.set_subcmp_counter(subcmp_idx, new_val)?),
            Env::ExtractedFunction(d) => {
                Env::ExtractedFunction(d.set_subcmp_counter(subcmp_idx, new_val)?)
            }
        })
    }

    pub fn decrease_subcmp_counter(self, subcmp_idx: usize) -> Result<Self, BadInterp> {
        Ok(match self {
            Env::Standard(d) => Env::Standard(d.decrease_subcmp_counter(subcmp_idx)?),
            Env::UnrolledBlock(d) => Env::UnrolledBlock(d.decrease_subcmp_counter(subcmp_idx)?),
            Env::ExtractedFunction(d) => {
                Env::ExtractedFunction(d.decrease_subcmp_counter(subcmp_idx)?)
            }
        })
    }

    pub fn run_subcmp(
        self,
        subcmp_idx: usize,
        name: &String,
        interpreter: &BucketInterpreter,
    ) -> Self {
        match self {
            Env::Standard(d) => Env::Standard(d.run_subcmp(subcmp_idx, name, interpreter)),
            Env::UnrolledBlock(d) => {
                Env::UnrolledBlock(d.run_subcmp(subcmp_idx, name, interpreter))
            }
            Env::ExtractedFunction(d) => {
                Env::ExtractedFunction(d.run_subcmp(subcmp_idx, name, interpreter))
            }
        }
    }

    pub fn create_subcmp(
        self,
        name: &String,
        base_index: usize,
        count: usize,
        template_id: usize,
    ) -> Self {
        match self {
            Env::Standard(d) => {
                Env::Standard(d.create_subcmp(name, base_index, count, template_id))
            }
            Env::UnrolledBlock(d) => {
                Env::UnrolledBlock(d.create_subcmp(name, base_index, count, template_id))
            }
            Env::ExtractedFunction(d) => {
                Env::ExtractedFunction(d.create_subcmp(name, base_index, count, template_id))
            }
        }
    }
}
