use std::cell::{RefCell, Ref};
use std::collections::HashMap;
use std::ops::Range;
use code_producers::components::{TemplateInstanceIOMap, IODef};
use code_producers::llvm_elements::IndexMapping;
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::TemplateCode;
use compiler::compiler_interface::Circuit;
use crate::bucket_interpreter::BucketInterpreter;
use crate::bucket_interpreter::env::{Env, LibraryAccess};
use crate::bucket_interpreter::observer::Observer;
use crate::passes::GlobalPassData;

pub struct PassMemory {
    // Wrapped in a RefCell because the reference to the static analysis is immutable but we need
    //  mutability. In some cases, very fine-grained mutability which is why everything here is
    //  wrapped separately and the template/function library values themselves are wrapped separately.
    templates_library: RefCell<HashMap<String, TemplateCode>>,
    functions_library: RefCell<HashMap<String, FunctionCode>>,
    constant_fields: RefCell<Vec<String>>,
    current_scope: RefCell<String>,
    io_map: RefCell<TemplateInstanceIOMap>,
    signal_index_mapping: RefCell<HashMap<String, IndexMapping>>,
    variables_index_mapping: RefCell<HashMap<String, IndexMapping>>,
    component_addr_index_mapping: RefCell<HashMap<String, IndexMapping>>,
    prime: String,
}

impl PassMemory {
    pub fn new(prime: String, current_scope: String, io_map: TemplateInstanceIOMap) -> Self {
        PassMemory {
            prime,
            current_scope: RefCell::new(current_scope),
            io_map: RefCell::new(io_map),
            constant_fields: Default::default(),
            templates_library: Default::default(),
            functions_library: Default::default(),
            signal_index_mapping: Default::default(),
            variables_index_mapping: Default::default(),
            component_addr_index_mapping: Default::default(),
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
            self.current_scope.borrow().to_string(),
        )
    }

    pub fn build_interpreter_with_scope<'a, 'd: 'a>(
        &'a self,
        global_data: &'d RefCell<GlobalPassData>,
        observer: &'a dyn for<'e> Observer<Env<'e>>,
        scope: String,
    ) -> BucketInterpreter {
        BucketInterpreter::init(global_data, observer, self, scope)
    }

    pub fn set_scope(&self, template: &TemplateCode) {
        self.current_scope.replace(template.header.clone());
    }

    pub fn run_template<'d>(
        &self,
        global_data: &'d RefCell<GlobalPassData>,
        observer: &dyn for<'e> Observer<Env<'e>>,
        template: &TemplateCode,
    ) {
        assert!(!self.current_scope.borrow().is_empty());
        if cfg!(debug_assertions) {
            println!("Running template {}", self.current_scope.borrow());
        }
        let interpreter = self.build_interpreter(global_data, observer);
        let env = Env::new_standard_env(self);
        interpreter.execute_instructions(&template.body, env, true);
    }

    pub fn add_template(&self, template: &TemplateCode) {
        self.templates_library.borrow_mut().insert(template.header.clone(), (*template).clone());
    }

    pub fn add_function(&self, function: &FunctionCode) {
        self.functions_library.borrow_mut().insert(function.header.clone(), (*function).clone());
    }

    pub fn fill_from_circuit(&self, circuit: &Circuit) {
        for template in &circuit.templates {
            self.add_template(template);
        }
        for function in &circuit.functions {
            self.add_function(function);
        }
        self.constant_fields.replace(circuit.llvm_data.field_tracking.clone());
        self.io_map.replace(circuit.llvm_data.io_map.clone());
        self.variables_index_mapping.replace(circuit.llvm_data.variable_index_mapping.clone());
        self.signal_index_mapping.replace(circuit.llvm_data.signal_index_mapping.clone());
        self.component_addr_index_mapping
            .replace(circuit.llvm_data.component_index_mapping.clone());
    }

    pub fn get_prime(&self) -> &String {
        &self.prime
    }

    pub fn get_field_constant(&self, index: usize) -> String {
        self.constant_fields.borrow()[index].clone()
    }

    pub fn get_field_constants_clone(&self) -> Vec<String> {
        self.constant_fields.borrow().clone()
    }

    /// Stores a new constant and returns its index
    pub fn add_field_constant(&self, new_value: String) -> usize {
        let mut temp = self.constant_fields.borrow_mut();
        let idx = temp.len();
        temp.push(new_value);
        idx
    }

    pub fn get_iodef(&self, template_id: &usize, signal_code: &usize) -> IODef {
        self.io_map.borrow()[template_id][*signal_code].clone()
    }

    pub fn get_signal_index_mapping(&self, scope: &String, index: &usize) -> Range<usize> {
        self.signal_index_mapping.borrow()[scope][index].clone()
    }

    pub fn get_current_scope_signal_index_mapping(&self, index: &usize) -> Range<usize> {
        self.get_signal_index_mapping(&self.current_scope.borrow(), index)
    }

    pub fn get_variables_index_mapping(&self, scope: &String, index: &usize) -> Range<usize> {
        self.variables_index_mapping.borrow()[scope][index].clone()
    }

    pub fn get_current_scope_variables_index_mapping(&self, index: &usize) -> Range<usize> {
        self.get_variables_index_mapping(&self.current_scope.borrow(), index)
    }

    pub fn get_component_addr_index_mapping(&self, scope: &String, index: &usize) -> Range<usize> {
        self.component_addr_index_mapping.borrow()[scope][index].clone()
    }

    pub fn get_current_scope_component_addr_index_mapping(&self, index: &usize) -> Range<usize> {
        self.get_component_addr_index_mapping(&self.current_scope.borrow(), index)
    }
}

impl LibraryAccess for PassMemory {
    fn get_function(&self, name: &String) -> Ref<FunctionCode> {
        Ref::map(self.functions_library.borrow(), |map| &map[name])
    }

    fn get_template(&self, name: &String) -> Ref<TemplateCode> {
        Ref::map(self.templates_library.borrow(), |map| &map[name])
    }
}
