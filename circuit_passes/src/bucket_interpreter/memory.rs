use std::cell::{RefCell, Ref};
use std::collections::HashMap;
use std::ops::Range;
use code_producers::components::{TemplateInstanceIOMap, IODef};
use code_producers::llvm_elements::IndexMapping;
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::TemplateCode;
use compiler::compiler_interface::Circuit;
use compiler::num_bigint::BigInt;
use program_structure::constants::UsefulConstants;
use crate::bucket_interpreter::BucketInterpreter;
use crate::bucket_interpreter::env::{Env, LibraryAccess};
use crate::bucket_interpreter::observer::Observer;
use crate::passes::GlobalPassData;
use super::InterpreterFlags;
use super::error::BadInterp;

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
    templates_library: RefCell<HashMap<String, TemplateCode>>,
    functions_library: RefCell<HashMap<String, FunctionCode>>,
    /// Mirrors `LLVMCircuitData::ff_constants`.
    /// When ValueBucket is parsed as a bigint, its value is the index into this map.
    ff_constants: RefCell<Vec<String>>,
    /// Identifies the current template/function scope of the [CircuitTransformationPass](crate::passes::CircuitTransformationPass)
    current_scope: RefCell<Scope>,
    ///
    io_map: RefCell<TemplateInstanceIOMap>,
    ///
    signal_index_mapping: RefCell<HashMap<String, IndexMapping>>,
    ///
    variable_index_mapping: RefCell<HashMap<String, IndexMapping>>,
    ///
    component_addr_index_mapping: RefCell<HashMap<String, IndexMapping>>,
    ///
    prime: BigInt,
}

impl PassMemory {
    pub fn new(prime: String, io_map: TemplateInstanceIOMap) -> Self {
        PassMemory {
            prime: UsefulConstants::new(&prime).get_p().clone(),
            io_map: RefCell::new(io_map),
            current_scope: Default::default(),
            ff_constants: Default::default(),
            templates_library: Default::default(),
            functions_library: Default::default(),
            signal_index_mapping: Default::default(),
            variable_index_mapping: Default::default(),
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

    pub fn run_template<'d>(
        &self,
        global_data: &'d RefCell<GlobalPassData>,
        observer: &dyn for<'e> Observer<Env<'e>>,
        template: &TemplateCode,
    ) -> Result<(), BadInterp> {
        assert!(!self.get_current_scope_header().is_empty());
        if cfg!(debug_assertions) {
            println!("Running template {}", self.get_current_scope_header());
        }
        let interpreter = self.build_interpreter(global_data, observer);
        let env = Env::new_standard_env(false, self);
        interpreter.execute_instructions(&template.body, env, true)?;
        Ok(())
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
        self.ff_constants.replace(circuit.llvm_data.ff_constants.clone());
        self.io_map.replace(circuit.llvm_data.io_map.clone());
        self.variable_index_mapping.replace(circuit.llvm_data.variable_index_mapping.clone());
        self.signal_index_mapping.replace(circuit.llvm_data.signal_index_mapping.clone());
        self.component_addr_index_mapping
            .replace(circuit.llvm_data.component_index_mapping.clone());
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
        self.ff_constants.borrow()[index].clone()
    }

    pub fn get_ff_constants_clone(&self) -> Vec<String> {
        self.ff_constants.borrow().clone()
    }

    /// Stores a new constant and returns its index
    pub fn add_field_constant(&self, new_value: String) -> usize {
        let mut temp = self.ff_constants.borrow_mut();
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
        self.get_signal_index_mapping(&self.get_current_scope_header(), index)
    }

    pub fn get_variables_index_mapping(&self, scope: &String, index: &usize) -> Range<usize> {
        self.variable_index_mapping.borrow()[scope][index].clone()
    }

    pub fn get_current_scope_variables_index_mapping(&self, index: &usize) -> Range<usize> {
        self.get_variables_index_mapping(&self.get_current_scope_header(), index)
    }

    pub fn new_variable_index_mapping(&self, scope: &String, size: &usize) -> usize {
        let mut base = self.variable_index_mapping.borrow_mut();
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

    pub fn new_current_scope_variable_index_mapping(&self, size: &usize) -> usize {
        self.new_variable_index_mapping(&self.get_current_scope_header(), size)
    }

    pub fn get_variable_index_mapping_clone(&self) -> HashMap<String, IndexMapping> {
        self.variable_index_mapping.borrow().clone()
    }

    pub fn get_component_addr_index_mapping(&self, scope: &String, index: &usize) -> Range<usize> {
        self.component_addr_index_mapping.borrow()[scope][index].clone()
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
