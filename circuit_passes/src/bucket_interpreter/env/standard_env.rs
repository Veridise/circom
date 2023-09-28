use std::cell::Ref;
use std::collections::{HashMap, BTreeMap};
use std::fmt::{Display, Formatter, Result};
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::TemplateCode;
use compiler::intermediate_representation::BucketId;
use crate::bucket_interpreter::BucketInterpreter;
use crate::bucket_interpreter::value::Value;
use super::{SubcmpEnv, LibraryAccess};

#[derive(Clone)]
pub struct StandardEnvData<'a> {
    vars: HashMap<usize, Value>,
    signals: HashMap<usize, Value>,
    subcmps: HashMap<usize, SubcmpEnv>,
    libs: &'a dyn LibraryAccess,
}

impl Display for StandardEnvData<'_> {
    fn fmt(&self, f: &mut Formatter<'_>) -> Result {
        write!(
            f,
            "StandardEnv{{\n  vars = {:?}\n  signals = {:?}\n  subcmps = {:?}}}",
            self.vars, self.signals, self.subcmps
        )
    }
}

impl LibraryAccess for StandardEnvData<'_> {
    fn get_function(&self, name: &String) -> Ref<FunctionCode> {
        self.libs.get_function(name)
    }

    fn get_template(&self, name: &String) -> Ref<TemplateCode> {
        self.libs.get_template(name)
    }
}

impl<'a> StandardEnvData<'a> {
    pub fn new(libs: &'a dyn LibraryAccess) -> Self {
        StandardEnvData {
            vars: Default::default(),
            signals: Default::default(),
            subcmps: Default::default(),
            libs,
        }
    }

    // READ OPERATIONS
    pub fn extracted_func_caller(&self) -> Option<&BucketId> {
        None
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
        &self.subcmps[&subcmp_idx].name
    }

    pub fn get_subcmp_template_id(&self, subcmp_idx: usize) -> usize {
        self.subcmps[&subcmp_idx].template_id
    }

    pub fn subcmp_counter_is_zero(&self, subcmp_idx: usize) -> bool {
        self.subcmps.get(&subcmp_idx).unwrap().counter_is_zero()
    }

    pub fn subcmp_counter_equal_to(&self, subcmp_idx: usize, value: usize) -> bool {
        self.subcmps.get(&subcmp_idx).unwrap().counter_equal_to(value)
    }

    pub fn get_vars_clone(&self) -> HashMap<usize, Value> {
        self.vars.clone()
    }

    pub fn get_vars_sort(&self) -> BTreeMap<usize, Value> {
        self.vars.iter().fold(BTreeMap::new(), |mut acc, e| {
            acc.insert(*e.0, e.1.clone());
            acc
        })
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

    pub fn set_all_to_unk(self) -> Self {
        let mut copy = self;
        for (_, v) in copy.vars.iter_mut() {
            *v = Value::Unknown;
        }
        for (_, v) in copy.signals.iter_mut() {
            *v = Value::Unknown;
        }
        for (_, v) in copy.subcmps.iter_mut() {
            v.signals.clear();
        }
        copy
    }

    /// Sets all the signals of the subcmp to UNK
    pub fn set_subcmp_to_unk(self, subcmp_idx: usize) -> Self {
        let mut copy = self;
        let subcmp_env = copy
            .subcmps
            .remove(&subcmp_idx)
            .expect(format!("Can't set a signal of subcomponent {}", subcmp_idx).as_str());
        copy.subcmps.insert(subcmp_idx, subcmp_env.reset());
        copy
    }

    pub fn set_subcmp_signal(self, subcmp_idx: usize, signal_idx: usize, value: Value) -> Self {
        let mut copy = self;
        let subcmp_env = copy
            .subcmps
            .remove(&subcmp_idx)
            .expect(format!("Can't set a signal of subcomponent {}", subcmp_idx).as_str());
        copy.subcmps.insert(subcmp_idx, subcmp_env.set_signal(signal_idx, value));
        copy
    }

    pub fn decrease_subcmp_counter(self, subcmp_idx: usize) -> Self {
        let mut copy = self;
        let subcmp_env = copy
            .subcmps
            .remove(&subcmp_idx)
            .expect(format!("Can't decrease counter of subcomponent {}", subcmp_idx).as_str());
        copy.subcmps.insert(subcmp_idx, subcmp_env.decrease_counter());
        copy
    }

    pub fn run_subcmp(
        self,
        _subcmp_idx: usize,
        _name: &String,
        _interpreter: &BucketInterpreter,
        _observe: bool,
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
        let number_of_inputs = self.get_template(name).number_of_inputs;
        let mut copy = self;
        for i in base_index..(base_index + count) {
            copy.subcmps.insert(i, SubcmpEnv::new(number_of_inputs, name, template_id));
        }
        copy
    }
}
