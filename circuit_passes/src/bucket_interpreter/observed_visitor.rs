use code_producers::llvm_elements::fr::BUILT_IN_NAMES;
use compiler::intermediate_representation::InstructionPointer;
use compiler::intermediate_representation::ir_interface::*;
use super::env::LibraryAccess;
use super::observer::Observer;

pub struct ObservedVisitor<'a, S> {
    observer: &'a dyn Observer<S>,
    libs: Option<&'a dyn LibraryAccess>,
}

impl<'a, S> ObservedVisitor<'a, S> {
    pub fn new(observer: &'a dyn Observer<S>, libs: Option<&'a dyn LibraryAccess>) -> Self {
        ObservedVisitor { observer, libs }
    }

    pub fn visit_address_type(&self, addr_type: &AddressType, state: &S, observe: bool) {
        if let AddressType::SubcmpSignal { cmp_address, .. } = addr_type {
            self.visit_instruction(cmp_address, state, observe);
        }
    }

    pub fn visit_location_rule(&self, location_rule: &LocationRule, state: &S, observe: bool) {
        match location_rule {
            LocationRule::Indexed { location, .. } => {
                self.visit_instruction(location, state, observe);
            }
            LocationRule::Mapped { indexes, .. } => {
                self.visit_instructions(indexes, state, observe)
            }
        }
    }

    pub fn visit_load_bucket(&self, bucket: &LoadBucket, state: &S, observe: bool) {
        self.visit_address_type(&bucket.address_type, state, observe);
        self.visit_location_rule(&bucket.src, state, observe);
    }

    pub fn visit_store_bucket(&self, bucket: &StoreBucket, state: &S, observe: bool) {
        self.visit_instruction(&bucket.src, state, observe);
        self.visit_address_type(&bucket.dest_address_type, state, observe);
        self.visit_location_rule(&bucket.dest, state, observe);
    }

    pub fn visit_call_bucket(&self, bucket: &CallBucket, state: &S, observe: bool) {
        self.visit_instructions(&bucket.arguments, state, observe);
        if let ReturnType::Final(fd) = &bucket.return_info {
            self.visit_address_type(&fd.dest_address_type, state, observe);
            self.visit_location_rule(&fd.dest, state, observe);
        }
        // Visit the callee function body if LibraryAccess was provided
        if let Some(libs) = self.libs {
            let name = &bucket.symbol;
            // Skip those that cannot be visited (i.e. not yet in Circuit.functions)
            if !BUILT_IN_NAMES.with(|f| f.contains(name.as_str())) {
                self.visit_instructions(
                    &libs.get_function(name).body,
                    state,
                    observe && !self.observer.ignore_call(name),
                );
            }
        }
    }

    pub fn visit_compute_bucket(&self, bucket: &ComputeBucket, state: &S, observe: bool) {
        self.visit_instructions(&bucket.stack, state, observe);
    }

    pub fn visit_assert_bucket(&self, bucket: &AssertBucket, state: &S, observe: bool) {
        self.visit_instruction(&bucket.evaluate, state, observe);
    }

    pub fn visit_loop_bucket(&self, bucket: &LoopBucket, state: &S, observe: bool) {
        self.visit_instruction(&bucket.continue_condition, state, observe);
        self.visit_instructions(&bucket.body, state, observe);
    }

    pub fn visit_create_cmp_bucket(&self, bucket: &CreateCmpBucket, state: &S, observe: bool) {
        self.visit_instruction(&bucket.sub_cmp_id, state, observe);
    }

    pub fn visit_constraint_bucket(&self, bucket: &ConstraintBucket, state: &S, observe: bool) {
        self.visit_instruction(
            match bucket {
                ConstraintBucket::Substitution(i) => i,
                ConstraintBucket::Equality(i) => i,
            },
            state,
            observe,
        );
    }

    pub fn visit_block_bucket(&self, bucket: &BlockBucket, state: &S, observe: bool) {
        self.visit_instructions(&bucket.body, state, observe);
    }

    pub fn visit_branch_bucket(&self, bucket: &BranchBucket, state: &S, observe: bool) {
        self.visit_instruction(&bucket.cond, state, observe);
        self.visit_instructions(&bucket.if_branch, state, observe);
        self.visit_instructions(&bucket.else_branch, state, observe);
    }

    pub fn visit_return_bucket(&self, bucket: &ReturnBucket, state: &S, observe: bool) {
        self.visit_instruction(&bucket.value, state, observe);
    }

    pub fn visit_log_bucket(&self, bucket: &LogBucket, state: &S, observe: bool) {
        for arg in &bucket.argsprint {
            if let LogBucketArg::LogExp(i) = arg {
                self.visit_instruction(i, state, observe);
            }
        }
    }

    pub fn visit_value_bucket(&self, _bucket: &ValueBucket, _state: &S, _observe: bool) {}

    pub fn visit_nop_bucket(&self, _bucket: &NopBucket, _state: &S, _observe: bool) {}

    pub fn visit_instructions(&self, insts: &Vec<InstructionPointer>, state: &S, observe: bool) {
        for i in insts {
            self.visit_instruction(i, state, observe);
        }
    }

    pub fn visit_instruction(&self, inst: &InstructionPointer, state: &S, observe: bool) {
        let keep_observing =
            if observe { self.observer.on_instruction(inst, state) } else { observe };
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
