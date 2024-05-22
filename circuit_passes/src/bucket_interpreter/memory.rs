use std::cell::{RefCell, Ref};
use std::collections::HashMap;
use std::ops::{Deref, Range};
use code_producers::components::IODef;
use code_producers::llvm_elements::{IndexMapping, MemoryLayout};
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::TemplateCode;
use compiler::num_bigint::BigInt;
use indexmap::IndexMap;
use program_structure::constants::UsefulConstants;
use crate::passes::GlobalPassData;
use super::{BucketInterpreter, InterpreterFlags};
use super::env::{Env, EnvContextKind, LibraryAccess};
use super::error::BadInterp;
use super::observer::Observer;

#[derive(Debug, Default)]
pub struct Scope {
    /// Circom source name from which the template/function was generated
    pub name: String,
    ///  Unique name of the generated template/function (i.e. 'name' with unique suffix)
    pub header: String,
}

impl From<&TemplateCode> for Scope {
    fn from(t: &TemplateCode) -> Self {
        Scope { name: t.name.clone(), header: t.header.clone() }
    }
}

impl From<&FunctionCode> for Scope {
    fn from(f: &FunctionCode) -> Self {
        Scope { name: f.name.clone(), header: f.header.clone() }
    }
}

pub struct PassMemory {
    // Wrapped in a RefCell because the reference to the static analysis is immutable but we need
    //  mutability. In some cases, very fine-grained mutability which is why everything here is
    //  wrapped separately and the template/function library values themselves are wrapped separately.
    //
    // The IndexMap is used because the order of insertion must be preserved or else the use of
    //  a template may be encountered before its definition causing a panic in code generation.
    templates_library: RefCell<IndexMap<String, TemplateCode>>,
    functions_library: RefCell<IndexMap<String, FunctionCode>>,
    /// References [LLVMCircuitData](code_producers::llvm_elements::LLVMCircuitData)
    mem_layout: RefCell<MemoryLayout>,
    /// Identifies the current template/function scope of the [CircuitTransformationPass](crate::passes::CircuitTransformationPass)
    current_scope: RefCell<Scope>,
    /// The prime of the finite field
    prime: BigInt,
}

impl PassMemory {
    pub fn new(prime: String) -> Self {
        PassMemory {
            prime: UsefulConstants::new(&prime).get_p().clone(),
            mem_layout: Default::default(),
            current_scope: Default::default(),
            templates_library: Default::default(),
            functions_library: Default::default(),
        }
    }

    pub fn build_interpreter<'a, 'd: 'a>(
        &'a self,
        global_data: &'d RefCell<GlobalPassData>,
        observer: &'a dyn for<'e> Observer<Env<'e>>,
    ) -> BucketInterpreter {
        self.build_interpreter_with_scope(
            global_data,
            observer,
            InterpreterFlags::default(),
            self.get_current_scope_header().clone(),
        )
    }
    pub fn build_interpreter_with_flags<'a, 'd: 'a>(
        &'a self,
        global_data: &'d RefCell<GlobalPassData>,
        observer: &'a dyn for<'e> Observer<Env<'e>>,
        flags: InterpreterFlags,
    ) -> BucketInterpreter {
        self.build_interpreter_with_scope(
            global_data,
            observer,
            flags,
            self.get_current_scope_header().clone(),
        )
    }

    pub fn build_interpreter_with_scope<'a, 'd: 'a>(
        &'a self,
        global_data: &'d RefCell<GlobalPassData>,
        observer: &'a dyn for<'e> Observer<Env<'e>>,
        flags: InterpreterFlags,
        scope: String,
    ) -> BucketInterpreter {
        BucketInterpreter::init(global_data, observer, flags, self, scope)
    }

    pub fn run_template_with_flags<'d>(
        &self,
        global_data: &'d RefCell<GlobalPassData>,
        observer: &dyn for<'e> Observer<Env<'e>>,
        template: &TemplateCode,
        flags: InterpreterFlags,
    ) -> Result<(), BadInterp> {
        assert!(!self.get_current_scope_header().is_empty());
        if cfg!(debug_assertions) {
            println!("Running template {}", self.get_current_scope_header());
        }
        let interpreter = self.build_interpreter_with_flags(global_data, observer, flags);
        let env = Env::new_standard_env(EnvContextKind::Template, self);
        interpreter.execute_instructions(&template.body, env, true)?;
        Ok(())
    }

    pub fn run_template<'d>(
        &self,
        global_data: &'d RefCell<GlobalPassData>,
        observer: &dyn for<'e> Observer<Env<'e>>,
        template: &TemplateCode,
    ) -> Result<(), BadInterp> {
        self.run_template_with_flags(global_data, observer, template, InterpreterFlags::default())
    }

    pub fn get_templates(&self) -> Vec<Ref<TemplateCode>> {
        let borrow = self.templates_library.borrow();
        let mut result = Vec::with_capacity(borrow.len());
        for k in borrow.deref().keys() {
            result.push(Ref::map(Ref::clone(&borrow), |m| &m[k]));
        }
        result
    }

    pub fn get_functions(&self) -> Vec<Ref<FunctionCode>> {
        let borrow = self.functions_library.borrow();
        let mut result = Vec::with_capacity(borrow.len());
        for k in borrow.deref().keys() {
            result.push(Ref::map(Ref::clone(&borrow), |m| &m[k]));
        }
        result
    }

    fn add_template(&self, template: TemplateCode) {
        self.templates_library.borrow_mut().insert(template.header.clone(), template);
    }

    fn add_function(&self, function: FunctionCode) {
        self.functions_library.borrow_mut().insert(function.header.clone(), function);
    }

    pub fn fill(
        &self,
        templates: Vec<TemplateCode>,
        functions: Vec<FunctionCode>,
        layout: MemoryLayout,
    ) {
        for template in templates {
            self.add_template(template);
        }
        for function in functions {
            self.add_function(function);
        }
        self.mem_layout.replace(layout);
    }

    pub fn clear(&self) -> MemoryLayout {
        self.templates_library.take();
        self.functions_library.take();
        self.mem_layout.take()
    }

    pub fn set_scope(&self, s: Scope) {
        self.current_scope.replace(s);
    }

    pub fn get_current_scope_name(&self) -> Ref<String> {
        Ref::map(self.current_scope.borrow(), |s| &s.name)
    }

    pub fn get_current_scope_header(&self) -> Ref<String> {
        Ref::map(self.current_scope.borrow(), |s| &s.header)
    }

    pub fn get_prime(&self) -> &BigInt {
        &self.prime
    }

    pub fn get_ff_constant(&self, index: usize) -> String {
        self.mem_layout.borrow().ff_constants[index].clone()
    }

    pub fn get_ff_constants_clone(&self) -> Vec<String> {
        self.mem_layout.borrow().ff_constants.clone()
    }

    /// Stores a new constant and returns its index
    pub fn add_field_constant(&self, new_value: String) -> usize {
        let temp = &mut self.mem_layout.borrow_mut().ff_constants;
        let idx = temp.len();
        temp.push(new_value);
        idx
    }

    pub fn new_variable_index_mapping(&self, scope: &String, size: usize) -> usize {
        let base = &mut self.mem_layout.borrow_mut().variable_index_mapping;
        let scope_map = base.entry(scope.clone()).or_default();
        let new_idx = match scope_map.last_key_value() {
            Some((k, _)) => *k + 1,
            None => 0,
        };
        let range = (new_idx)..(new_idx + size);
        for i in range.clone() {
            scope_map.insert(i, range.clone());
        }
        new_idx
    }

    pub fn new_current_scope_variable_index_mapping(&self, size: usize) -> usize {
        self.new_variable_index_mapping(&self.get_current_scope_header(), size)
    }

    #[cfg(test)]
    pub fn new_signal_index_mapping(&self, scope: &String, size: usize) -> usize {
        let base = &mut self.mem_layout.borrow_mut().signal_index_mapping;
        let scope_map = base.entry(scope.clone()).or_default();
        let new_idx = match scope_map.last_key_value() {
            Some((k, _)) => *k + 1,
            None => 0,
        };
        let range = (new_idx)..(new_idx + size);
        for i in range.clone() {
            scope_map.insert(i, range.clone());
        }
        new_idx
    }

    #[cfg(test)]
    pub fn new_current_scope_signal_index_mapping(&self, size: usize) -> usize {
        self.new_signal_index_mapping(&self.get_current_scope_header(), size)
    }

    pub fn get_iodef(&self, template_id: &usize, signal_code: &usize) -> IODef {
        self.mem_layout.borrow().io_map[template_id][*signal_code].clone()
    }

    pub fn get_signal_index_mapping(&self, scope: &String, index: &usize) -> Range<usize> {
        self.mem_layout.borrow().signal_index_mapping[scope][index].clone()
    }

    pub fn get_current_scope_signal_index_mapping(&self, index: &usize) -> Range<usize> {
        self.get_signal_index_mapping(&self.get_current_scope_header(), index)
    }

    pub fn get_variable_index_mapping(&self, scope: &String, index: &usize) -> Range<usize> {
        self.mem_layout.borrow().variable_index_mapping[scope][index].clone()
    }

    pub fn get_current_scope_variable_index_mapping(&self, index: &usize) -> Range<usize> {
        self.get_variable_index_mapping(&self.get_current_scope_header(), index)
    }

    pub fn get_variable_index_mapping_clone(&self) -> HashMap<String, IndexMapping> {
        self.mem_layout.borrow().variable_index_mapping.clone()
    }

    pub fn get_component_addr_index_mapping(&self, scope: &String, index: &usize) -> Range<usize> {
        self.mem_layout.borrow().component_index_mapping[scope][index].clone()
    }

    pub fn get_current_scope_component_addr_index_mapping(&self, index: &usize) -> Range<usize> {
        self.get_component_addr_index_mapping(&self.get_current_scope_header(), index)
    }
}

impl LibraryAccess for PassMemory {
    fn get_function(&self, name: &String) -> Ref<FunctionCode> {
        Ref::map(self.functions_library.borrow(), |map| {
            map.get(name).unwrap_or_else(|| panic!("No function with name '{name}'"))
        })
    }

    fn get_template(&self, name: &String) -> Ref<TemplateCode> {
        Ref::map(self.templates_library.borrow(), |map| {
            map.get(name).unwrap_or_else(|| panic!("No template with name '{name}'"))
        })
    }
}
