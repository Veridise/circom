use indexmap::IndexMap;
use code_producers::llvm_elements::stdlib::LLVM_DONOTHING_FN_NAME;
use compiler::intermediate_representation::{BucketId, InstructionPointer, new_id};
use compiler::intermediate_representation::ir_interface::*;
use crate::passes::builders::build_u32_value;

use super::body_extractor::ArgIndex;

pub struct ExtractedFunctionLocationUpdater<'a> {
    bucket_arg_order: &'a mut IndexMap<BucketId, ArgIndex>,
}

/// Used within extracted loopbody functions to replace all storage references
/// (i.e. AddressType + LocationRule) to instead reference the proper parameter
/// of the extracted function. These replacements cannot use AddressType::Variable
/// or AddressType::Signal because ExtractedFunctionLLVMIRProducer references the
/// first two parameters of the extracted function via those. Therefore, it must
/// use SubcmpSignal which will work seamlessly with existing subcmps because they
/// will also just be passed as additional parameters to the function.
impl ExtractedFunctionLocationUpdater<'_> {
    pub fn new(
        bucket_arg_order: &mut IndexMap<BucketId, ArgIndex>,
    ) -> ExtractedFunctionLocationUpdater {
        ExtractedFunctionLocationUpdater { bucket_arg_order }
    }

    fn handle_any_store(
        &mut self,
        ai: &ArgIndex,
        dest: &LocationRule,
        bucket_meta: &dyn ObtainMeta,
        to_insert_after: &mut InstructionList,
    ) -> (AddressType, LocationRule) {
        // If the current argument involves an actual subcomponent, then generate additional code in the
        // 'insert_after' list that will decrement the subcomponent counter and call the proper "_run"
        //  function for the template when the counter reaches 0.
        // NOTE: This must happen before the modification step so it can use existing values from the bucket.
        if let ArgIndex::SubCmp { counter, arena, .. } = ai {
            let counter_address = AddressType::SubcmpSignal {
                cmp_address: build_u32_value(bucket_meta, *counter),
                uniform_parallel_value: None,
                counter_override: true,
                is_output: false,
                input_information: InputInformation::NoInput,
            };
            // Generate counter LoadBucket+ComputeBucket+StoreBucket in the "insert_after" list
            //  (based on what StoreBucket::produce_llvm_ir would normally generate for this).
            to_insert_after.push(
                StoreBucket {
                    id: new_id(),
                    source_file_id: bucket_meta.get_source_file_id().clone(),
                    line: bucket_meta.get_line(),
                    message_id: bucket_meta.get_message_id(),
                    context: InstrContext { size: 1 },
                    dest_is_output: false,
                    dest_address_type: counter_address.clone(),
                    dest: LocationRule::Indexed {
                        location: build_u32_value(bucket_meta, 0),
                        template_header: None,
                    },
                    bounded_fn: None,
                    src: ComputeBucket {
                        id: new_id(),
                        source_file_id: bucket_meta.get_source_file_id().clone(),
                        line: bucket_meta.get_line(),
                        message_id: bucket_meta.get_message_id(),
                        op: OperatorType::Sub,
                        op_aux_no: 0,
                        stack: vec![
                            LoadBucket {
                                id: new_id(),
                                source_file_id: bucket_meta.get_source_file_id().clone(),
                                line: bucket_meta.get_line(),
                                message_id: bucket_meta.get_message_id(),
                                address_type: counter_address.clone(),
                                src: LocationRule::Indexed {
                                    location: build_u32_value(bucket_meta, 0),
                                    template_header: None,
                                },
                                bounded_fn: None,
                            }
                            .allocate(),
                            ValueBucket {
                                id: new_id(),
                                source_file_id: bucket_meta.get_source_file_id().clone(),
                                line: bucket_meta.get_line(),
                                message_id: bucket_meta.get_message_id(),
                                parse_as: ValueType::U32,
                                op_aux_no: 0,
                                value: 1,
                            }
                            .allocate(),
                        ],
                    }
                    .allocate(),
                }
                .allocate(),
            );

            // Generate code to call the "run" function if the counter reaches 0
            to_insert_after.push(
                BranchBucket {
                    id: new_id(),
                    source_file_id: bucket_meta.get_source_file_id().clone(),
                    line: bucket_meta.get_line(),
                    message_id: bucket_meta.get_message_id(),
                    cond: ComputeBucket {
                        id: new_id(),
                        source_file_id: bucket_meta.get_source_file_id().clone(),
                        line: bucket_meta.get_line(),
                        message_id: bucket_meta.get_message_id(),
                        op: OperatorType::Eq(1),
                        op_aux_no: 0,
                        stack: vec![
                            LoadBucket {
                                id: new_id(),
                                source_file_id: bucket_meta.get_source_file_id().clone(),
                                line: bucket_meta.get_line(),
                                message_id: bucket_meta.get_message_id(),
                                address_type: counter_address,
                                src: LocationRule::Indexed {
                                    location: build_u32_value(bucket_meta, 0),
                                    template_header: None,
                                },
                                bounded_fn: None,
                            }
                            .allocate(),
                            ValueBucket {
                                id: new_id(),
                                source_file_id: bucket_meta.get_source_file_id().clone(),
                                line: bucket_meta.get_line(),
                                message_id: bucket_meta.get_message_id(),
                                parse_as: ValueType::U32,
                                op_aux_no: 0,
                                value: 0,
                            }
                            .allocate(),
                        ],
                    }
                    .allocate(),
                    if_branch: vec![StoreBucket {
                        id: new_id(),
                        source_file_id: bucket_meta.get_source_file_id().clone(),
                        line: bucket_meta.get_line(),
                        message_id: bucket_meta.get_message_id(),
                        context: InstrContext { size: 1 },
                        dest_is_output: false,
                        dest_address_type: AddressType::SubcmpSignal {
                            cmp_address: build_u32_value(bucket_meta, *arena),
                            uniform_parallel_value: None,
                            counter_override: false,
                            is_output: false,
                            input_information: InputInformation::Input {
                                status: StatusInput::Last, // This is the key to generating call to "run" function
                            },
                        },
                        dest: LocationRule::Indexed {
                            location: build_u32_value(bucket_meta, 0), //the value here is ignored by the 'bounded_fn' below
                            template_header: match dest {
                                LocationRule::Indexed { template_header, .. } => {
                                    template_header.clone()
                                }
                                LocationRule::Mapped { .. } => todo!(),
                            },
                        },
                        src: build_u32_value(bucket_meta, 0), //the value here is ignored at runtime
                        bounded_fn: Some(String::from(LLVM_DONOTHING_FN_NAME)), // actual result ignored, only need effect of 'StatusInput::Last'
                    }
                    .allocate()],
                    else_branch: vec![],
                }
                .allocate(),
            );
        }
        //Transform this bucket into the normal fixed-index signal reference
        (
            AddressType::SubcmpSignal {
                cmp_address: build_u32_value(bucket_meta, ai.get_signal_idx()),
                uniform_parallel_value: None,
                counter_override: false,
                is_output: false,
                input_information: InputInformation::NoInput,
            },
            LocationRule::Indexed {
                location: build_u32_value(bucket_meta, 0), //use index 0 to ref the entire storage array
                template_header: None,
            },
        )
    }

    fn _check_store_bucket(
        &mut self,
        bucket: &mut StoreBucket,
        to_insert_after: &mut InstructionList,
    ) {
        // Check the source/RHS of the store in either case
        self._check_instruction(&mut bucket.src, to_insert_after);
        //
        if let Some(ai) = self.bucket_arg_order.remove(&bucket.id) {
            let (at, lr) = self.handle_any_store(&ai, &bucket.dest, bucket, to_insert_after);
            bucket.dest_address_type = at;
            bucket.dest = lr;
        } else {
            // If not replacing, check deeper in the AddressType and LocationRule
            self._check_address_type(&mut bucket.dest_address_type, to_insert_after);
            self._check_location_rule(&mut bucket.dest, to_insert_after);
        }
    }

    fn _check_load_bucket(
        &mut self,
        bucket: &mut LoadBucket,
        to_insert_after: &mut InstructionList,
    ) {
        if let Some(ai) = self.bucket_arg_order.remove(&bucket.id) {
            // Update the location information to reference the argument
            bucket.address_type = AddressType::SubcmpSignal {
                cmp_address: build_u32_value(bucket, ai.get_signal_idx()),
                uniform_parallel_value: None,
                counter_override: false,
                is_output: false,
                input_information: InputInformation::NoInput,
            };
            bucket.src = LocationRule::Indexed {
                location: build_u32_value(bucket, 0), //use index 0 to ref the entire storage array
                template_header: None,
            };
        } else {
            // If not replacing, check deeper in the AddressType and LocationRule
            self._check_address_type(&mut bucket.address_type, to_insert_after);
            self._check_location_rule(&mut bucket.src, to_insert_after);
        }
    }

    fn _check_call_bucket(
        &mut self,
        bucket: &mut CallBucket,
        to_insert_after: &mut InstructionList,
    ) {
        // Check the call parameters
        self._check_instructions(&mut bucket.arguments, Some(to_insert_after));
        // A store can be implicit within a CallBucket 'return_info'
        let bucket_meta = ObtainMetaImpl::from(bucket); //avoid borrow issues
        if let ReturnType::Final(fd) = &mut bucket.return_info {
            if let Some(ai) = self.bucket_arg_order.remove(&bucket.id) {
                let (at, lr) = self.handle_any_store(&ai, &fd.dest, &bucket_meta, to_insert_after);
                fd.dest_address_type = at;
                fd.dest = lr;
            } else {
                // If not replacing, check deeper in the AddressType and LocationRule
                self._check_address_type(&mut fd.dest_address_type, to_insert_after);
                self._check_location_rule(&mut fd.dest, to_insert_after);
            }
        }
    }

    fn _check_location_rule(
        &mut self,
        location_rule: &mut LocationRule,
        to_insert_after: &mut InstructionList,
    ) {
        match location_rule {
            LocationRule::Indexed { location, .. } => {
                self._check_instruction(location, to_insert_after);
            }
            LocationRule::Mapped { .. } => unreachable!(),
        }
    }

    fn _check_address_type(
        &mut self,
        addr_type: &mut AddressType,
        to_insert_after: &mut InstructionList,
    ) {
        if let AddressType::SubcmpSignal { cmp_address, .. } = addr_type {
            self._check_instruction(cmp_address, to_insert_after);
        }
    }

    fn _check_compute_bucket(
        &mut self,
        bucket: &mut ComputeBucket,
        to_insert_after: &mut InstructionList,
    ) {
        self._check_instructions(&mut bucket.stack, Some(to_insert_after));
    }

    fn _check_assert_bucket(
        &mut self,
        bucket: &mut AssertBucket,
        to_insert_after: &mut InstructionList,
    ) {
        self._check_instruction(&mut bucket.evaluate, to_insert_after);
    }

    fn _check_loop_bucket(
        &mut self,
        bucket: &mut LoopBucket,
        to_insert_after: &mut InstructionList,
    ) {
        self._check_instruction(&mut bucket.continue_condition, to_insert_after);
        self._check_instructions(&mut bucket.body, None);
    }

    fn _check_create_cmp_bucket(
        &mut self,
        bucket: &mut CreateCmpBucket,
        to_insert_after: &mut InstructionList,
    ) {
        self._check_instruction(&mut bucket.sub_cmp_id, to_insert_after);
    }

    fn _check_constraint_bucket(
        &mut self,
        bucket: &mut ConstraintBucket,
        to_insert_after: &mut InstructionList,
    ) {
        self._check_instruction(
            match bucket {
                ConstraintBucket::Substitution(i) => i,
                ConstraintBucket::Equality(i) => i,
            },
            to_insert_after,
        );
    }

    fn _check_block_bucket(
        &mut self,
        bucket: &mut BlockBucket,
        _to_insert_after: &mut InstructionList,
    ) {
        self._check_instructions(&mut bucket.body, None);
    }

    fn _check_branch_bucket(
        &mut self,
        bucket: &mut BranchBucket,
        to_insert_after: &mut InstructionList,
    ) {
        self._check_instruction(&mut bucket.cond, to_insert_after);
        self._check_instructions(&mut bucket.if_branch, None);
        self._check_instructions(&mut bucket.else_branch, None);
    }

    fn _check_return_bucket(
        &mut self,
        bucket: &mut ReturnBucket,
        to_insert_after: &mut InstructionList,
    ) {
        self._check_instruction(&mut bucket.value, to_insert_after);
    }

    fn _check_log_bucket(&mut self, bucket: &mut LogBucket, to_insert_after: &mut InstructionList) {
        for arg in &mut bucket.argsprint {
            if let LogBucketArg::LogExp(i) = arg {
                self._check_instruction(i, to_insert_after);
            }
        }
    }

    //Nothing to do
    fn _check_value_bucket(&mut self, _: &mut ValueBucket, _: &mut InstructionList) {}
    fn _check_nop_bucket(&mut self, _: &mut NopBucket, _: &mut InstructionList) {}

    fn _check_instruction(
        &mut self,
        inst: &mut InstructionPointer,
        to_insert_after: &mut InstructionList,
    ) {
        match inst.as_mut() {
            Instruction::Value(ref mut b) => self._check_value_bucket(b, to_insert_after),
            Instruction::Load(ref mut b) => self._check_load_bucket(b, to_insert_after),
            Instruction::Store(ref mut b) => self._check_store_bucket(b, to_insert_after),
            Instruction::Compute(ref mut b) => self._check_compute_bucket(b, to_insert_after),
            Instruction::Call(ref mut b) => self._check_call_bucket(b, to_insert_after),
            Instruction::Branch(ref mut b) => self._check_branch_bucket(b, to_insert_after),
            Instruction::Return(ref mut b) => self._check_return_bucket(b, to_insert_after),
            Instruction::Assert(ref mut b) => self._check_assert_bucket(b, to_insert_after),
            Instruction::Log(ref mut b) => self._check_log_bucket(b, to_insert_after),
            Instruction::Loop(ref mut b) => self._check_loop_bucket(b, to_insert_after),
            Instruction::CreateCmp(ref mut b) => self._check_create_cmp_bucket(b, to_insert_after),
            Instruction::Constraint(ref mut b) => self._check_constraint_bucket(b, to_insert_after),
            Instruction::Block(ref mut b) => self._check_block_bucket(b, to_insert_after),
            Instruction::Nop(ref mut b) => self._check_nop_bucket(b, to_insert_after),
        }
    }

    //If 'can_insert' is true, then insert contents immediately after processing each instruction.
    //Otherwise, it needs be be passed back up to the highest level where things can be inserted.
    //That means I probably need a separate Vec here for the call vs the parameter and then only
    //  move stuff over if necessary.
    fn _check_instructions(
        &mut self,
        insts: &mut InstructionList,
        to_insert_after: Option<&mut InstructionList>,
    ) {
        // NOTE: Needs a fresh mutable copy to make borrow checker happy
        let mut to_insert_after_borrow = to_insert_after;
        // Manually track index of the input instruction list and check the updated
        //  length for each iteration of the loop since things may be added.
        let mut i: usize = 0;
        while i < insts.len() {
            let mut to_insert_between = Default::default();
            self._check_instruction(&mut insts[i], &mut to_insert_between);
            match to_insert_after_borrow.as_mut() {
                None => {
                    // None indicates that it is safe to insert directly to 'insts'.
                    for s in to_insert_between.drain(..) {
                        i += 1; //increment to the next insertion point
                        insts.insert(i, s);
                    }
                }
                Some(x) => {
                    // When it's not safe to insert to 'insts' another vector is
                    //  given where any new instructions should be inserted.
                    for s in to_insert_between.drain(..) {
                        x.push(s);
                    }
                }
            }
            // Manually increment input pointer to the next input statement
            i += 1;
        }
    }

    pub fn check_instructions(&mut self, insts: &mut InstructionList) {
        self._check_instructions(insts, None);
    }
}
