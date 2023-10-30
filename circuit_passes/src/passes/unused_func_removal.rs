use std::cell::{RefCell, Ref};
use std::collections::{HashSet, HashMap};
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::TemplateCode;
use compiler::compiler_interface::Circuit;
use compiler::intermediate_representation::ir_interface::*;
use crate::bucket_interpreter::{observer::Observer, env::LibraryAccess};
use crate::bucket_interpreter::observed_visitor::ObservedVisitor;
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
    fn on_value_bucket(&self, _bucket: &ValueBucket, _: &()) -> bool {
        true
    }

    fn on_load_bucket(&self, _bucket: &LoadBucket, _: &()) -> bool {
        true
    }

    fn on_store_bucket(&self, _bucket: &StoreBucket, _: &()) -> bool {
        true
    }

    fn on_compute_bucket(&self, _bucket: &ComputeBucket, _: &()) -> bool {
        true
    }

    fn on_assert_bucket(&self, _bucket: &AssertBucket, _: &()) -> bool {
        true
    }

    fn on_loop_bucket(&self, _bucket: &LoopBucket, _: &()) -> bool {
        true
    }

    fn on_create_cmp_bucket(&self, _bucket: &CreateCmpBucket, _: &()) -> bool {
        true
    }

    fn on_constraint_bucket(&self, _bucket: &ConstraintBucket, _: &()) -> bool {
        true
    }

    fn on_block_bucket(&self, _bucket: &BlockBucket, _: &()) -> bool {
        true
    }

    fn on_nop_bucket(&self, _bucket: &NopBucket, _: &()) -> bool {
        true
    }

    fn on_location_rule(&self, _location_rule: &LocationRule, _: &()) -> bool {
        true
    }

    fn on_call_bucket(&self, bucket: &CallBucket, _: &()) -> bool {
        self.used_functions.borrow_mut().insert(bucket.symbol.clone());
        true
    }

    fn on_branch_bucket(&self, _bucket: &BranchBucket, _: &()) -> bool {
        true
    }

    fn on_return_bucket(&self, _bucket: &ReturnBucket, _: &()) -> bool {
        true
    }

    fn on_log_bucket(&self, _bucket: &LogBucket, _: &()) -> bool {
        true
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
    fn name(&self) -> &str {
        "UnusedFuncRemovalPass"
    }

    fn get_updated_field_constants(&self) -> Vec<String> {
        unreachable!()
    }

    fn transform_circuit(&self, circuit: &Circuit) -> Circuit {
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

        // Search each template for CallBucket and cache the names
        let visitor = ObservedVisitor::new(self, Some(&libs));
        let templates = circuit
            .templates
            .iter()
            .map(|t| {
                visitor.visit_instructions(&t.body, &(), true);
                t.clone()
            })
            .collect();

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
        Circuit {
            wasm_producer: circuit.wasm_producer.clone(),
            c_producer: circuit.c_producer.clone(),
            llvm_data: circuit.llvm_data.clone_with_updates(
                circuit.llvm_data.field_tracking.clone(),
                self.get_updated_bounded_array_loads(&circuit.llvm_data.bounded_array_loads),
                self.get_updated_bounded_array_stores(&circuit.llvm_data.bounded_array_stores),
            ),
            templates,
            functions,
        }
    }
}
