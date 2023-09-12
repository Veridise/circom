use std::cell::Ref;
use std::collections::HashMap;
use std::fmt::{Display, Formatter};
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::TemplateCode;
use crate::bucket_interpreter::BucketInterpreter;
use crate::bucket_interpreter::value::Value;

pub trait ContextSwitcher {
    fn switch<'a>(
        &'a self,
        interpreter: &'a BucketInterpreter<'a>,
        scope: &'a String,
    ) -> BucketInterpreter<'a>;
}

pub trait LibraryAccess {
    fn get_function(&self, name: &String) -> Ref<FunctionCode>;
    fn get_template(&self, name: &String) -> Ref<TemplateCode>;
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct SubcmpEnv<'a> {
    pub signals: HashMap<usize, Value>,
    counter: usize,
    name: &'a String,
    template_id: usize,
}

impl<'a> SubcmpEnv<'a> {
    pub fn new(inputs: usize, name: &'a String, template_id: usize) -> Self {
        SubcmpEnv { signals: Default::default(), counter: inputs, name, template_id }
    }

    pub fn reset(self) -> Self {
        let mut copy = self;
        copy.signals.clear();
        copy
    }

    pub fn get_signal(&self, index: usize) -> Value {
        self.signals.get(&index).unwrap_or_default().clone()
    }

    pub fn set_signal(self, idx: usize, value: Value) -> SubcmpEnv<'a> {
        let mut copy = self;
        copy.signals.insert(idx, value);
        copy
    }

    pub fn counter_is_zero(&self) -> bool {
        self.counter == 0
    }

    pub fn decrease_counter(self) -> SubcmpEnv<'a> {
        let mut copy = self;
        copy.counter -= 1;
        copy
    }

    pub fn counter_equal_to(&self, value: usize) -> bool {
        self.counter == value
    }
}

// An immutable env that returns a new copy when modified
#[derive(Clone)]
pub struct Env<'a> {
    vars: HashMap<usize, Value>,
    signals: HashMap<usize, Value>,
    subcmps: HashMap<usize, SubcmpEnv<'a>>,
    libs: &'a dyn LibraryAccess,
    context_switcher: &'a dyn ContextSwitcher,
}

impl Display for Env<'_> {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "\n  vars = {:?}\n  signals = {:?}\n  subcmps = {:?}",
            self.vars, self.signals, self.subcmps
        )
    }
}

impl<'a> Env<'a> {
    pub fn new(libs: &'a dyn LibraryAccess, context_switcher: &'a dyn ContextSwitcher) -> Self {
        Env {
            vars: Default::default(),
            signals: Default::default(),
            subcmps: Default::default(),
            libs,
            context_switcher,
        }
    }

    // READ OPERATIONS
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
        self.subcmps[&subcmp_idx].name
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
        //let subcmp = &self.subcmps[&subcmp_idx];
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
        name: &'a String,
        base_index: usize,
        count: usize,
        template_id: usize,
    ) -> Self {
        let number_of_inputs = self.libs.get_template(name).number_of_inputs;
        let mut copy = self;
        for i in base_index..(base_index + count) {
            copy.subcmps.insert(i, SubcmpEnv::new(number_of_inputs, name, template_id));
        }
        copy
    }

    pub fn run_function(
        &self,
        name: &String,
        interpreter: &BucketInterpreter,
        args: Vec<Value>,
        observe: bool,
    ) -> Value {
        if cfg!(debug_assertions) {
            println!("Running function {}", name);
        }
        let code = &self.libs.get_function(name).body;
        let mut function_env = Env::new(self.libs, self.context_switcher);
        for (id, arg) in args.iter().enumerate() {
            function_env = function_env.set_var(id, arg.clone());
        }
        let interpreter = self.context_switcher.switch(interpreter, name);
        let r = interpreter.execute_instructions(
            code,
            function_env,
            !interpreter.observer.ignore_function_calls() && observe,
        );
        r.0.expect("Function must return a value!")
    }
}
