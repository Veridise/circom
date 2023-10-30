use code_producers::llvm_elements::stdlib::GENERATED_FN_PREFIX;
use compiler::intermediate_representation::{Instruction, InstructionPointer};
use compiler::intermediate_representation::ir_interface::{
    AssertBucket, BranchBucket, CallBucket, ComputeBucket, ConstraintBucket, CreateCmpBucket,
    LoadBucket, LocationRule, LogBucket, LoopBucket, NopBucket, ReturnBucket, StoreBucket,
    BlockBucket, ValueBucket,
};

/// Will get called everytime some visitor is about to visit a bucket,
/// with access to the state data prior to the execution of the bucket.
pub trait Observer<S> {
    fn on_value_bucket(&self, bucket: &ValueBucket, state: &S) -> bool;
    fn on_load_bucket(&self, bucket: &LoadBucket, state: &S) -> bool;
    fn on_store_bucket(&self, bucket: &StoreBucket, state: &S) -> bool;
    fn on_compute_bucket(&self, bucket: &ComputeBucket, state: &S) -> bool;
    fn on_assert_bucket(&self, bucket: &AssertBucket, state: &S) -> bool;
    fn on_loop_bucket(&self, bucket: &LoopBucket, state: &S) -> bool;
    fn on_create_cmp_bucket(&self, bucket: &CreateCmpBucket, state: &S) -> bool;
    fn on_constraint_bucket(&self, bucket: &ConstraintBucket, state: &S) -> bool;
    fn on_block_bucket(&self, bucket: &BlockBucket, state: &S) -> bool;
    fn on_nop_bucket(&self, bucket: &NopBucket, state: &S) -> bool;
    fn on_location_rule(&self, location_rule: &LocationRule, state: &S) -> bool;
    fn on_call_bucket(&self, bucket: &CallBucket, state: &S) -> bool;
    fn on_branch_bucket(&self, bucket: &BranchBucket, state: &S) -> bool;
    fn on_return_bucket(&self, bucket: &ReturnBucket, state: &S) -> bool;
    fn on_log_bucket(&self, bucket: &LogBucket, state: &S) -> bool;

    fn on_instruction(&self, inst: &InstructionPointer, state: &S) -> bool {
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

    fn ignore_subcmp_calls(&self) -> bool;
    fn ignore_function_calls(&self) -> bool;
    fn ignore_extracted_function_calls(&self) -> bool;

    fn ignore_call(&self, callee: &String) -> bool {
        if callee.starts_with(GENERATED_FN_PREFIX) {
            self.ignore_extracted_function_calls()
        } else {
            self.ignore_function_calls()
        }
    }
}
