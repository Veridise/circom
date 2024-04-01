use std::cell::{RefCell, Ref};
use std::collections::{HashSet, HashMap};
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::TemplateCode;
use compiler::compiler_interface::Circuit;
use compiler::intermediate_representation::ir_interface::*;
use crate::bucket_interpreter::error::BadInterp;
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::{observer::Observer, env::LibraryAccess};
use crate::bucket_interpreter::observed_visitor::ObservedVisitor;
use crate::default__name;
use super::{CircuitTransformationPass, GlobalPassData};

/// The goal of this pass is to remove unreachable functions from the Circuit
pub struct UnusedFuncRemovalPass<'d> {
    _global_data: &'d RefCell<GlobalPassData>,
    // Wrapped in a RefCell because the reference to the static analysis is immutable but we need mutability
    used_functions: RefCell<HashSet<String>>,
}

impl<'d> UnusedFuncRemovalPass<'d> {
    pub fn new(_prime: String, _global_data: &'d RefCell<GlobalPassData>) -> Self {
        UnusedFuncRemovalPass { _global_data, used_functions: Default::default() }
    }
}

impl Observer<()> for UnusedFuncRemovalPass<'_> {
    fn on_call_bucket(&self, bucket: &CallBucket, _: &()) -> Result<bool, BadInterp> {
        self.used_functions.borrow_mut().insert(bucket.symbol.clone());
        Ok(true)
    }

    fn ignore_function_calls(&self) -> bool {
        false
    }

    fn ignore_subcmp_calls(&self) -> bool {
        false
    }

    fn ignore_extracted_function_calls(&self) -> bool {
        false
    }
}

impl CircuitTransformationPass for UnusedFuncRemovalPass<'_> {
    default__name!("UnusedFuncRemovalPass");

    fn get_mem(&self) -> &PassMemory {
        unreachable!()
    }

    fn run_template(&self, _: &TemplateCode) -> Result<(), BadInterp> {
        unreachable!()
    }

    fn get_updated_field_constants(&self) -> Vec<String> {
        unreachable!()
    }

    fn transform_circuit(&self, circuit: &Circuit) -> Result<Circuit, BadInterp> {
        //Build a structure to implement LibraryAccess
        struct LibsImpl {
            functions: HashMap<String, RefCell<FunctionCode>>,
        }
        impl LibraryAccess for LibsImpl {
            fn get_function(&self, name: &String) -> Ref<FunctionCode> {
                self.functions[name].borrow()
            }

            fn get_template(&self, _name: &String) -> Ref<TemplateCode> {
                unreachable!()
            }
        }
        let libs = LibsImpl {
            functions: {
                let mut functions = HashMap::new();
                for f in &circuit.functions {
                    functions.insert(f.header.clone(), RefCell::new((*f).clone()));
                }
                functions
            },
        };

        // Search each template for CallBucket and cache the names, returning a list of cloned templates
        let visitor = ObservedVisitor::new(self, Some(&libs));
        let templates = circuit
            .templates
            .iter()
            .map(|t| visitor.visit_instructions(&t.body, &(), true).map(|_| t.clone()))
            .collect::<Result<_, _>>()?;

        // Filter out functions that are never used
        let functions = circuit
            .functions
            .iter()
            .filter_map(|f| {
                if self.used_functions.borrow().contains(&f.header) {
                    Some(f.clone())
                } else {
                    None
                }
            })
            .collect();

        // Return new circuit with reduced function list (and cloned templates)
        Ok(Circuit {
            wasm_producer: circuit.wasm_producer.clone(),
            c_producer: circuit.c_producer.clone(),
            summary_producer: circuit.summary_producer.clone(),
            llvm_data: circuit.llvm_data.clone_with_updates(
                circuit.llvm_data.field_tracking.clone(),
                self.get_updated_bounded_array_loads(&circuit.llvm_data.bounded_array_loads),
                self.get_updated_bounded_array_stores(&circuit.llvm_data.bounded_array_stores),
            ),
            templates,
            functions,
        })
    }
}
