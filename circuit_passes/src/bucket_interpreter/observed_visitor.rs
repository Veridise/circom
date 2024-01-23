use std::cell::RefCell;
use std::collections::HashSet;
use code_producers::llvm_elements::fr;
use compiler::intermediate_representation::BucketId;
use compiler::intermediate_representation::InstructionPointer;
use compiler::intermediate_representation::ir_interface::*;
use super::env::LibraryAccess;
use super::error::BadInterp;
use super::observer::Observer;

pub struct ObservedVisitor<'a, S> {
    observer: &'a dyn Observer<S>,
    libs: Option<&'a dyn LibraryAccess>,
    // Wrapped in a RefCell because the reference to the static analysis is immutable but we need mutability
    /// Keep track of those already visited to prevent stack overflow.
    visited_funcs: RefCell<HashSet<String>>,
}

impl<'a, S> ObservedVisitor<'a, S> {
    pub fn new(observer: &'a dyn Observer<S>, libs: Option<&'a dyn LibraryAccess>) -> Self {
        ObservedVisitor { observer, libs, visited_funcs: Default::default() }
    }

    pub fn visit_address_type(
        &self,
        addr_type: &AddressType,
        state: &S,
        observe: bool,
    ) -> Result<(), BadInterp> {
        if let AddressType::SubcmpSignal { cmp_address, .. } = addr_type {
            self.visit_instruction(cmp_address, state, observe)?;
        }
        Ok(())
    }

    pub fn visit_location_rule(
        &self,
        location: &LocationRule,
        location_owner: &BucketId,
        state: &S,
        observe: bool,
    ) -> Result<(), BadInterp> {
        let keep_observing =
            observe!(self, on_location_rule, location, state, observe, location_owner);
        match location {
            LocationRule::Indexed { location, .. } => {
                self.visit_instruction(location, state, keep_observing)?;
            }
            LocationRule::Mapped { indexes, .. } => {
                self.visit_instructions(indexes, state, keep_observing)?;
            }
        }
        Ok(())
    }

    pub fn visit_load_bucket(
        &self,
        bucket: &LoadBucket,
        state: &S,
        observe: bool,
    ) -> Result<(), BadInterp> {
        self.visit_address_type(&bucket.address_type, state, observe)?;
        self.visit_location_rule(&bucket.src, &bucket.id, state, observe)?;
        Ok(())
    }

    pub fn visit_store_bucket(
        &self,
        bucket: &StoreBucket,
        state: &S,
        observe: bool,
    ) -> Result<(), BadInterp> {
        self.visit_instruction(&bucket.src, state, observe)?;
        self.visit_address_type(&bucket.dest_address_type, state, observe)?;
        self.visit_location_rule(&bucket.dest, &bucket.id, state, observe)?;
        Ok(())
    }

    pub fn visit_call_bucket(
        &self,
        bucket: &CallBucket,
        state: &S,
        observe: bool,
    ) -> Result<(), BadInterp> {
        self.visit_instructions(&bucket.arguments, state, observe)?;
        if let ReturnType::Final(fd) = &bucket.return_info {
            self.visit_address_type(&fd.dest_address_type, state, observe)?;
            self.visit_location_rule(&fd.dest, &bucket.id, state, observe)?;
        }
        // Visit the callee function body if it was not visited before and if given LibraryAccess
        if let Some(libs) = self.libs {
            let name = &bucket.symbol;
            if self.visited_funcs.borrow_mut().insert(name.clone()) {
                // Skip those that cannot be visited (i.e. not yet in Circuit.functions)
                if !fr::is_builtin_function(name) {
                    self.visit_instructions(
                        &libs.get_function(name).body,
                        state,
                        observe && !self.observer.ignore_call(name),
                    )?;
                }
            }
        }
        Ok(())
    }

    pub fn visit_compute_bucket(
        &self,
        bucket: &ComputeBucket,
        state: &S,
        observe: bool,
    ) -> Result<(), BadInterp> {
        self.visit_instructions(&bucket.stack, state, observe)?;
        Ok(())
    }

    pub fn visit_assert_bucket(
        &self,
        bucket: &AssertBucket,
        state: &S,
        observe: bool,
    ) -> Result<(), BadInterp> {
        self.visit_instruction(&bucket.evaluate, state, observe)?;
        Ok(())
    }

    pub fn visit_loop_bucket(
        &self,
        bucket: &LoopBucket,
        state: &S,
        observe: bool,
    ) -> Result<(), BadInterp> {
        self.visit_instruction(&bucket.continue_condition, state, observe)?;
        self.visit_instructions(&bucket.body, state, observe)?;
        Ok(())
    }

    pub fn visit_create_cmp_bucket(
        &self,
        bucket: &CreateCmpBucket,
        state: &S,
        observe: bool,
    ) -> Result<(), BadInterp> {
        self.visit_instruction(&bucket.sub_cmp_id, state, observe)?;
        Ok(())
    }

    pub fn visit_constraint_bucket(
        &self,
        bucket: &ConstraintBucket,
        state: &S,
        observe: bool,
    ) -> Result<(), BadInterp> {
        self.visit_instruction(bucket.unwrap(), state, observe)?;
        Ok(())
    }

    pub fn visit_block_bucket(
        &self,
        bucket: &BlockBucket,
        state: &S,
        observe: bool,
    ) -> Result<(), BadInterp> {
        self.visit_instructions(&bucket.body, state, observe)?;
        Ok(())
    }

    pub fn visit_branch_bucket(
        &self,
        bucket: &BranchBucket,
        state: &S,
        observe: bool,
    ) -> Result<(), BadInterp> {
        self.visit_instruction(&bucket.cond, state, observe)?;
        self.visit_instructions(&bucket.if_branch, state, observe)?;
        self.visit_instructions(&bucket.else_branch, state, observe)?;
        Ok(())
    }

    pub fn visit_return_bucket(
        &self,
        bucket: &ReturnBucket,
        state: &S,
        observe: bool,
    ) -> Result<(), BadInterp> {
        self.visit_instruction(&bucket.value, state, observe)?;
        Ok(())
    }

    pub fn visit_log_bucket(
        &self,
        bucket: &LogBucket,
        state: &S,
        observe: bool,
    ) -> Result<(), BadInterp> {
        for arg in &bucket.argsprint {
            if let LogBucketArg::LogExp(i) = arg {
                self.visit_instruction(i, state, observe)?;
            }
        }
        Ok(())
    }

    pub fn visit_value_bucket(
        &self,
        _bucket: &ValueBucket,
        _state: &S,
        _observe: bool,
    ) -> Result<(), BadInterp> {
        Ok(())
    }

    pub fn visit_nop_bucket(
        &self,
        _bucket: &NopBucket,
        _state: &S,
        _observe: bool,
    ) -> Result<(), BadInterp> {
        Ok(())
    }

    pub fn visit_instructions(
        &self,
        insts: &Vec<InstructionPointer>,
        state: &S,
        observe: bool,
    ) -> Result<(), BadInterp> {
        for i in insts {
            self.visit_instruction(i, state, observe)?;
        }
        Ok(())
    }

    pub fn visit_instruction(
        &self,
        inst: &InstructionPointer,
        state: &S,
        observe: bool,
    ) -> Result<(), BadInterp> {
        let keep_observing = observe!(self, on_instruction, inst, state, observe);
        match inst.as_ref() {
            Instruction::Value(b) => self.visit_value_bucket(b, state, keep_observing),
            Instruction::Load(b) => self.visit_load_bucket(b, state, keep_observing),
            Instruction::Store(b) => self.visit_store_bucket(b, state, keep_observing),
            Instruction::Compute(b) => self.visit_compute_bucket(b, state, keep_observing),
            Instruction::Call(b) => self.visit_call_bucket(b, state, keep_observing),
            Instruction::Branch(b) => self.visit_branch_bucket(b, state, keep_observing),
            Instruction::Return(b) => self.visit_return_bucket(b, state, keep_observing),
            Instruction::Assert(b) => self.visit_assert_bucket(b, state, keep_observing),
            Instruction::Log(b) => self.visit_log_bucket(b, state, keep_observing),
            Instruction::Loop(b) => self.visit_loop_bucket(b, state, keep_observing),
            Instruction::CreateCmp(b) => self.visit_create_cmp_bucket(b, state, keep_observing),
            Instruction::Constraint(b) => self.visit_constraint_bucket(b, state, keep_observing),
            Instruction::Block(b) => self.visit_block_bucket(b, state, keep_observing),
            Instruction::Nop(b) => self.visit_nop_bucket(b, state, keep_observing),
        }
    }
}
