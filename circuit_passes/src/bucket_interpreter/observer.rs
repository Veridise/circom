use code_producers::llvm_elements::stdlib::GENERATED_FN_PREFIX;
use compiler::intermediate_representation::{BucketId, Instruction, InstructionPointer};
use compiler::intermediate_representation::ir_interface::{
    AssertBucket, BranchBucket, CallBucket, ComputeBucket, ConstraintBucket, CreateCmpBucket,
    LoadBucket, LocationRule, LogBucket, LoopBucket, NopBucket, ReturnBucket, StoreBucket,
    BlockBucket, ValueBucket,
};
use super::error::BadInterp;

#[macro_export]
macro_rules! observe {
    ($self:ident, $on_inst_fn: ident, $inst:expr, $env:ident, $observe:ident $(, $bucket_id:expr)?) => {
        if $observe {
            $self.observer.$on_inst_fn($inst, &$env, $($bucket_id)?)?
        } else {
            false
        }
    };
}

/// Will get called everytime some visitor is about to visit a bucket,
/// with access to the state data prior to the execution of the bucket.
pub trait Observer<S> {
    fn on_value_bucket(&self, _bucket: &ValueBucket, _state: &S) -> Result<bool, BadInterp> {
        Ok(true)
    }

    fn on_load_bucket(&self, _bucket: &LoadBucket, _state: &S) -> Result<bool, BadInterp> {
        Ok(true)
    }

    fn on_store_bucket(&self, _bucket: &StoreBucket, _state: &S) -> Result<bool, BadInterp> {
        Ok(true)
    }

    fn on_compute_bucket(&self, _bucket: &ComputeBucket, _state: &S) -> Result<bool, BadInterp> {
        Ok(true)
    }

    fn on_assert_bucket(&self, _bucket: &AssertBucket, _state: &S) -> Result<bool, BadInterp> {
        Ok(true)
    }

    fn on_loop_bucket(&self, _bucket: &LoopBucket, _state: &S) -> Result<bool, BadInterp> {
        Ok(true)
    }

    fn on_create_cmp_bucket(
        &self,
        _bucket: &CreateCmpBucket,
        _state: &S,
    ) -> Result<bool, BadInterp> {
        Ok(true)
    }

    fn on_constraint_bucket(
        &self,
        _bucket: &ConstraintBucket,
        _state: &S,
    ) -> Result<bool, BadInterp> {
        Ok(true)
    }

    fn on_block_bucket(&self, _bucket: &BlockBucket, _state: &S) -> Result<bool, BadInterp> {
        Ok(true)
    }

    fn on_nop_bucket(&self, _bucket: &NopBucket, _state: &S) -> Result<bool, BadInterp> {
        Ok(true)
    }

    // Implementation note: the return value here determines if the Instruction instance
    //  nested within the LocationRule is observed which means this must be called before
    //  the inner Instruction is visited and its return value passed in for the observe flag.
    fn on_location_rule(
        &self,
        _location: &LocationRule,
        _state: &S,
        _owner: &BucketId,
    ) -> Result<bool, BadInterp> {
        Ok(true)
    }

    fn on_call_bucket(&self, _bucket: &CallBucket, _state: &S) -> Result<bool, BadInterp> {
        Ok(true)
    }

    fn on_branch_bucket(&self, _bucket: &BranchBucket, _state: &S) -> Result<bool, BadInterp> {
        Ok(true)
    }

    fn on_return_bucket(&self, _bucket: &ReturnBucket, _state: &S) -> Result<bool, BadInterp> {
        Ok(true)
    }

    fn on_log_bucket(&self, _bucket: &LogBucket, _state: &S) -> Result<bool, BadInterp> {
        Ok(true)
    }

    fn on_instruction(&self, inst: &InstructionPointer, state: &S) -> Result<bool, BadInterp> {
        match inst.as_ref() {
            Instruction::Value(bucket) => self.on_value_bucket(bucket, state),
            Instruction::Load(bucket) => self.on_load_bucket(bucket, state),
            Instruction::Store(bucket) => self.on_store_bucket(bucket, state),
            Instruction::Compute(bucket) => self.on_compute_bucket(bucket, state),
            Instruction::Call(bucket) => self.on_call_bucket(bucket, state),
            Instruction::Branch(bucket) => self.on_branch_bucket(bucket, state),
            Instruction::Return(bucket) => self.on_return_bucket(bucket, state),
            Instruction::Assert(bucket) => self.on_assert_bucket(bucket, state),
            Instruction::Log(bucket) => self.on_log_bucket(bucket, state),
            Instruction::Loop(bucket) => self.on_loop_bucket(bucket, state),
            Instruction::CreateCmp(bucket) => self.on_create_cmp_bucket(bucket, state),
            Instruction::Constraint(bucket) => self.on_constraint_bucket(bucket, state),
            Instruction::Block(bucket) => self.on_block_bucket(bucket, state),
            Instruction::Nop(bucket) => self.on_nop_bucket(bucket, state),
        }
    }

    fn ignore_call(&self, callee: &String) -> bool {
        if callee.starts_with(GENERATED_FN_PREFIX) {
            self.ignore_extracted_function_calls()
        } else {
            self.ignore_function_calls()
        }
    }

    fn ignore_subcmp_calls(&self) -> bool;
    fn ignore_function_calls(&self) -> bool;
    fn ignore_extracted_function_calls(&self) -> bool;
}
