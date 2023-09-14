use std::cell::Ref;
use std::collections::HashMap;
use std::fmt::{Display, Formatter, Result};
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::TemplateCode;
use crate::bucket_interpreter::BucketInterpreter;
use crate::bucket_interpreter::value::Value;
use super::{Env, LibraryAccess};

/// This Env is used to process functions created when extracting loop bodies into
/// `LOOP_BODY_FN_PREFIX` functions.
#[derive(Clone)]
pub struct ExtractedFuncEnvData<'a> {
    base: Box<Env<'a>>,
}

impl Display for ExtractedFuncEnvData<'_> {
    fn fmt(&self, f: &mut Formatter<'_>) -> Result {
        self.base.fmt(f)
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

impl<'a> ExtractedFuncEnvData<'a> {
    pub fn new(inner: Env<'a>) -> Self {
        ExtractedFuncEnvData { base: Box::new(inner) }
    }

    pub fn get_var(&self, idx: usize) -> Value {
        println!("get_var({}) = {}", idx, self.base.get_var(idx));
        self.base.get_var(idx)
    }

    pub fn get_signal(&self, idx: usize) -> Value {
        println!("get_signal({}) = {}", idx, self.base.get_signal(idx));
        self.base.get_signal(idx)
    }

    pub fn get_subcmp_signal(&self, subcmp_idx: usize, signal_idx: usize) -> Value {
        //NOTE: `signal_idx` will always be 0 for the fixed* parameters
        assert_eq!(signal_idx, 0);
        println!("TODO: must handle args here in addition to subcomps");
        // self.base.get_subcmp_signal(subcmp_idx, signal_idx)
        Value::Unknown
    }

    pub fn get_subcmp_name(&self, subcmp_idx: usize) -> &String {
        todo!();
        self.base.get_subcmp_name(subcmp_idx)
    }

    pub fn get_subcmp_template_id(&self, subcmp_idx: usize) -> usize {
        todo!();
        self.base.get_subcmp_template_id(subcmp_idx)
    }

    pub fn subcmp_counter_is_zero(&self, subcmp_idx: usize) -> bool {
        todo!();
        self.base.subcmp_counter_is_zero(subcmp_idx)
    }

    pub fn subcmp_counter_equal_to(&self, subcmp_idx: usize, value: usize) -> bool {
        todo!();
        self.base.subcmp_counter_equal_to(subcmp_idx, value)
    }

    pub fn get_vars_clone(&self) -> HashMap<usize, Value> {
        todo!();
        self.base.get_vars_clone()
    }

    pub fn set_var(self, idx: usize, value: Value) -> Self {
        println!("set_var({}, {}), old = {}", idx, value, self.base.get_var(idx));
        ExtractedFuncEnvData { base: Box::new(self.base.set_var(idx, value)) }
    }

    pub fn set_signal(self, idx: usize, value: Value) -> Self {
        println!("set_signal({}, {}), old = {}", idx, value, self.base.get_signal(idx));
        ExtractedFuncEnvData { base: Box::new(self.base.set_signal(idx, value)) }
    }

    pub fn set_all_to_unk(self) -> Self {
        todo!();
        ExtractedFuncEnvData { base: Box::new(self.base.set_all_to_unk()) }
    }

    pub fn set_subcmp_to_unk(self, subcmp_idx: usize) -> Self {
        todo!();
        ExtractedFuncEnvData { base: Box::new(self.base.set_subcmp_to_unk(subcmp_idx)) }
    }

    pub fn set_subcmp_signal(self, subcmp_idx: usize, signal_idx: usize, value: Value) -> Self {
        todo!();
        ExtractedFuncEnvData {
            base: Box::new(self.base.set_subcmp_signal(subcmp_idx, signal_idx, value)),
        }
    }

    pub fn decrease_subcmp_counter(self, subcmp_idx: usize) -> Self {
        todo!();
        ExtractedFuncEnvData { base: Box::new(self.base.decrease_subcmp_counter(subcmp_idx)) }
    }

    pub fn run_subcmp(
        self,
        subcmp_idx: usize,
        name: &String,
        interpreter: &BucketInterpreter,
        observe: bool,
    ) -> Self {
        todo!();
        ExtractedFuncEnvData {
            base: Box::new(self.base.run_subcmp(subcmp_idx, name, interpreter, observe)),
        }
    }

    pub fn create_subcmp(
        self,
        name: &'a String,
        base_index: usize,
        count: usize,
        template_id: usize,
    ) -> Self {
        todo!();
        ExtractedFuncEnvData {
            base: Box::new(self.base.create_subcmp(name, base_index, count, template_id)),
        }
    }
}
