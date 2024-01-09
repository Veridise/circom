use std::cell::RefCell;
use std::collections::HashMap;
use compiler::circuit_design::template::TemplateCode;
use compiler::intermediate_representation::{InstructionPointer, new_id, BucketId};
use compiler::intermediate_representation::ir_interface::*;
use crate::bucket_interpreter::env::Env;
use crate::bucket_interpreter::error::BadInterp;
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::observer::Observer;
use crate::bucket_interpreter::value::Value;
use crate::{default__name, default__get_mem, default__run_template};
use super::{CircuitTransformationPass, GlobalPassData};

pub struct SimplificationPass<'d> {
    // Wrapped in a RefCell because the reference to the static analysis is immutable but we need mutability
    global_data: &'d RefCell<GlobalPassData>,
    memory: PassMemory,
    compute_replacements: RefCell<HashMap<BucketId, Value>>,
    call_replacements: RefCell<HashMap<BucketId, Value>>,
}

impl<'d> SimplificationPass<'d> {
    pub fn new(prime: String, global_data: &'d RefCell<GlobalPassData>) -> Self {
        SimplificationPass {
            global_data,
            memory: PassMemory::new(prime, Default::default()),
            compute_replacements: Default::default(),
            call_replacements: Default::default(),
        }
    }
}

impl Observer<Env<'_>> for SimplificationPass<'_> {
    fn on_compute_bucket(&self, bucket: &ComputeBucket, env: &Env) -> Result<bool, BadInterp> {
        let interpreter = self.memory.build_interpreter(self.global_data, self);
        let eval = interpreter.compute_compute_bucket(bucket, env, false)?;
        let eval = eval.expect("Compute bucket must produce a value!");
        if !eval.is_unknown() {
            self.compute_replacements.borrow_mut().insert(bucket.id, eval);
            Ok(false)
        } else {
            Ok(true)
        }
    }

    fn on_call_bucket(&self, bucket: &CallBucket, env: &Env) -> Result<bool, BadInterp> {
        let interpreter = self.memory.build_interpreter(self.global_data, self);
        if let Some(eval) = interpreter.compute_call_bucket(bucket, env, false)? {
            // Call buckets may not return a value directly
            if !eval.is_unknown() {
                self.call_replacements.borrow_mut().insert(bucket.id, eval);
                return Ok(false);
            }
        }
        Ok(true)
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
    default__name!("SimplificationPass");
    default__get_mem!();
    default__run_template!();

    fn transform_compute_bucket(
        &self,
        bucket: &ComputeBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        if let Some(value) = self.compute_replacements.borrow().get(&bucket.id) {
            return Ok(value.to_value_bucket(&self.memory)?.allocate());
        }
        Ok(ComputeBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            op: bucket.op,
            op_aux_no: bucket.op_aux_no,
            stack: self.transform_instructions(&bucket.stack)?,
        }
        .allocate())
    }

    fn transform_call_bucket(&self, bucket: &CallBucket) -> Result<InstructionPointer, BadInterp> {
        if let Some(value) = self.call_replacements.borrow().get(&bucket.id) {
            return Ok(value.to_value_bucket(&self.memory)?.allocate());
        }
        Ok(CallBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            symbol: bucket.symbol.to_string(),
            argument_types: bucket.argument_types.clone(),
            arguments: self.transform_instructions(&bucket.arguments)?,
            arena_size: bucket.arena_size,
            return_info: self.transform_return_type(&bucket.id, &bucket.return_info)?,
        }
        .allocate())
    }
}
