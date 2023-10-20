use std::cell::RefCell;
use std::collections::HashMap;
use compiler::circuit_design::template::TemplateCode;
use compiler::compiler_interface::Circuit;
use compiler::intermediate_representation::{InstructionPointer, new_id, BucketId};
use compiler::intermediate_representation::ir_interface::*;
use crate::bucket_interpreter::env::Env;
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::observer::InterpreterObserver;
use crate::bucket_interpreter::value::Value;
use super::{CircuitTransformationPass, GlobalPassData};

pub struct SimplificationPass<'d> {
    global_data: &'d RefCell<GlobalPassData>,
    // Wrapped in a RefCell because the reference to the static analysis is immutable but we need mutability
    memory: PassMemory,
    compute_replacements: RefCell<HashMap<BucketId, Value>>,
    call_replacements: RefCell<HashMap<BucketId, Value>>,
}

impl<'d> SimplificationPass<'d> {
    pub fn new(prime: String, global_data: &'d RefCell<GlobalPassData>) -> Self {
        SimplificationPass {
            global_data,
            memory: PassMemory::new(prime, "".to_string(), Default::default()),
            compute_replacements: Default::default(),
            call_replacements: Default::default(),
        }
    }
}

impl InterpreterObserver for SimplificationPass<'_> {
    fn on_value_bucket(&self, _bucket: &ValueBucket, _env: &Env) -> bool {
        true
    }

    fn on_load_bucket(&self, _bucket: &LoadBucket, _env: &Env) -> bool {
        true
    }

    fn on_store_bucket(&self, _bucket: &StoreBucket, _env: &Env) -> bool {
        true
    }

    fn on_compute_bucket(&self, bucket: &ComputeBucket, env: &Env) -> bool {
        let env = env.clone();
        let interpreter = self.memory.build_interpreter(self.global_data, self);
        let (eval, _) = interpreter.execute_compute_bucket(bucket, env, false);
        let eval = eval.expect("Compute bucket must produce a value!");
        if !eval.is_unknown() {
            self.compute_replacements.borrow_mut().insert(bucket.id, eval);
            return false;
        }
        true
    }

    fn on_assert_bucket(&self, _bucket: &AssertBucket, _env: &Env) -> bool {
        true
    }

    fn on_loop_bucket(&self, _bucket: &LoopBucket, _env: &Env) -> bool {
        true
    }

    fn on_create_cmp_bucket(&self, _bucket: &CreateCmpBucket, _env: &Env) -> bool {
        true
    }

    fn on_constraint_bucket(&self, _bucket: &ConstraintBucket, _env: &Env) -> bool {
        true
    }

    fn on_block_bucket(&self, _bucket: &BlockBucket, _env: &Env) -> bool {
        true
    }

    fn on_nop_bucket(&self, _bucket: &NopBucket, _env: &Env) -> bool {
        true
    }

    fn on_location_rule(&self, _location_rule: &LocationRule, _env: &Env) -> bool {
        true
    }

    fn on_call_bucket(&self, bucket: &CallBucket, env: &Env) -> bool {
        let env = env.clone();
        let interpreter = self.memory.build_interpreter(self.global_data, self);
        let (eval, _) = interpreter.execute_call_bucket(bucket, env, false);
        if let Some(eval) = eval {
            // Call buckets may not return a value directly
            if !eval.is_unknown() {
                self.call_replacements.borrow_mut().insert(bucket.id, eval);
                return false;
            }
        }
        true
    }

    fn on_branch_bucket(&self, _bucket: &BranchBucket, _env: &Env) -> bool {
        true
    }

    fn on_return_bucket(&self, _bucket: &ReturnBucket, _env: &Env) -> bool {
        true
    }

    fn on_log_bucket(&self, _bucket: &LogBucket, _env: &Env) -> bool {
        true
    }

    fn ignore_function_calls(&self) -> bool {
        true
    }

    fn ignore_subcmp_calls(&self) -> bool {
        true
    }

    fn ignore_extracted_function_calls(&self) -> bool {
        true
    }
}

impl CircuitTransformationPass for SimplificationPass<'_> {
    fn name(&self) -> &str {
        "SimplificationPass"
    }

    fn get_updated_field_constants(&self) -> Vec<String> {
        self.memory.get_field_constants_clone()
    }

    fn transform_compute_bucket(&self, bucket: &ComputeBucket) -> InstructionPointer {
        if let Some(value) = self.compute_replacements.borrow().get(&bucket.id) {
            return value.to_value_bucket(&self.memory).allocate();
        }
        ComputeBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            op: bucket.op,
            op_aux_no: bucket.op_aux_no,
            stack: self.transform_instructions(&bucket.stack),
        }
        .allocate()
    }

    fn transform_call_bucket(&self, bucket: &CallBucket) -> InstructionPointer {
        if let Some(value) = self.call_replacements.borrow().get(&bucket.id) {
            return value.to_value_bucket(&self.memory).allocate();
        }
        CallBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            symbol: bucket.symbol.to_string(),
            argument_types: bucket.argument_types.clone(),
            arguments: self.transform_instructions(&bucket.arguments),
            arena_size: bucket.arena_size,
            return_info: self.transform_return_type(&bucket.id, &bucket.return_info),
        }
        .allocate()
    }

    fn pre_hook_circuit(&self, circuit: &Circuit) {
        self.memory.fill_from_circuit(circuit);
    }

    fn pre_hook_template(&self, template: &TemplateCode) {
        self.memory.set_scope(template);
        self.memory.run_template(self.global_data, self, template);
    }
}
