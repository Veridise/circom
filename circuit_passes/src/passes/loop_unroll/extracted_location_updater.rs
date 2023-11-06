use indexmap::IndexMap;
use code_producers::llvm_elements::stdlib::LLVM_DONOTHING_FN_NAME;
use compiler::intermediate_representation::{BucketId, InstructionPointer, new_id};
use compiler::intermediate_representation::ir_interface::*;
use crate::passes::builders::build_u32_value;

use super::body_extractor::ArgIndex;

pub struct ExtractedFunctionLocationUpdater {
    insert_after: InstructionList,
}

/// Used within extracted loopbody functions to replace all storage references
/// (i.e. AddressType + LocationRule) to instead reference the proper parameter
/// of the extracted function. These replacements cannot use AddressType::Variable
/// or AddressType::Signal because ExtractedFunctionLLVMIRProducer references the
/// first two parameters of the extracted function via those. Therefore, it must
/// use SubcmpSignal which will work seamlessly with existing subcmps because they
/// will also just be passed as additional parameters to the function.
impl ExtractedFunctionLocationUpdater {
    pub fn new() -> ExtractedFunctionLocationUpdater {
        ExtractedFunctionLocationUpdater { insert_after: Default::default() }
    }

    fn check_load_bucket(
        &mut self,
        bucket: &mut LoadBucket,
        bucket_arg_order: &mut IndexMap<BucketId, ArgIndex>,
    ) {
        if let Some(ai) = bucket_arg_order.remove(&bucket.id) {
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
            self.check_address_type(&mut bucket.address_type, bucket_arg_order);
            self.check_location_rule(&mut bucket.src, bucket_arg_order);
        }
    }

    fn handle_any_store(
        &mut self,
        ai: &ArgIndex,
        dest: &LocationRule,
        bucket_meta: &dyn ObtainMeta,
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
            self.insert_after.push(
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
            self.insert_after.push(
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

    fn check_store_bucket(
        &mut self,
        bucket: &mut StoreBucket,
        bucket_arg_order: &mut IndexMap<BucketId, ArgIndex>,
    ) {
        // Check the source/RHS of the store in either case
        self.check_instruction(&mut bucket.src, bucket_arg_order);
        //
        if let Some(ai) = bucket_arg_order.remove(&bucket.id) {
            let (at, lr) = self.handle_any_store(&ai, &bucket.dest, bucket);
            bucket.dest_address_type = at;
            bucket.dest = lr;
        } else {
            // If not replacing, check deeper in the AddressType and LocationRule
            self.check_address_type(&mut bucket.dest_address_type, bucket_arg_order);
            self.check_location_rule(&mut bucket.dest, bucket_arg_order);
        }
    }

    fn check_call_bucket(
        &mut self,
        bucket: &mut CallBucket,
        bucket_arg_order: &mut IndexMap<BucketId, ArgIndex>,
    ) {
        // Check the call parameters
        self.check_instructions(&mut bucket.arguments, bucket_arg_order, false);
        // A store can be implicit within a CallBucket 'return_info'
        let bucket_meta = ObtainMetaImpl::from(bucket); //avoid borrow issues
        if let ReturnType::Final(fd) = &mut bucket.return_info {
            if let Some(ai) = bucket_arg_order.remove(&bucket.id) {
                let (at, lr) = self.handle_any_store(&ai, &fd.dest, &bucket_meta);
                fd.dest_address_type = at;
                fd.dest = lr;
            } else {
                // If not replacing, check deeper in the AddressType and LocationRule
                self.check_address_type(&mut fd.dest_address_type, bucket_arg_order);
                self.check_location_rule(&mut fd.dest, bucket_arg_order);
            }
        }
    }

    fn check_location_rule(
        &mut self,
        location_rule: &mut LocationRule,
        bucket_arg_order: &mut IndexMap<BucketId, ArgIndex>,
    ) {
        match location_rule {
            LocationRule::Indexed { location, .. } => {
                self.check_instruction(location, bucket_arg_order);
            }
            LocationRule::Mapped { .. } => unreachable!(),
        }
    }

    fn check_address_type(
        &mut self,
        addr_type: &mut AddressType,
        bucket_arg_order: &mut IndexMap<BucketId, ArgIndex>,
    ) {
        if let AddressType::SubcmpSignal { cmp_address, .. } = addr_type {
            self.check_instruction(cmp_address, bucket_arg_order);
        }
    }

    fn check_compute_bucket(
        &mut self,
        bucket: &mut ComputeBucket,
        bucket_arg_order: &mut IndexMap<BucketId, ArgIndex>,
    ) {
        self.check_instructions(&mut bucket.stack, bucket_arg_order, false);
    }

    fn check_assert_bucket(
        &mut self,
        bucket: &mut AssertBucket,
        bucket_arg_order: &mut IndexMap<BucketId, ArgIndex>,
    ) {
        self.check_instruction(&mut bucket.evaluate, bucket_arg_order);
    }

    fn check_loop_bucket(
        &mut self,
        bucket: &mut LoopBucket,
        bucket_arg_order: &mut IndexMap<BucketId, ArgIndex>,
    ) {
        self.check_instruction(&mut bucket.continue_condition, bucket_arg_order);
        self.check_instructions(&mut bucket.body, bucket_arg_order, true);
    }

    fn check_create_cmp_bucket(
        &mut self,
        bucket: &mut CreateCmpBucket,
        bucket_arg_order: &mut IndexMap<BucketId, ArgIndex>,
    ) {
        self.check_instruction(&mut bucket.sub_cmp_id, bucket_arg_order);
    }

    fn check_constraint_bucket(
        &mut self,
        bucket: &mut ConstraintBucket,
        bucket_arg_order: &mut IndexMap<BucketId, ArgIndex>,
    ) {
        self.check_instruction(
            match bucket {
                ConstraintBucket::Substitution(i) => i,
                ConstraintBucket::Equality(i) => i,
            },
            bucket_arg_order,
        );
    }

    fn check_block_bucket(
        &mut self,
        bucket: &mut BlockBucket,
        bucket_arg_order: &mut IndexMap<BucketId, ArgIndex>,
    ) {
        self.check_instructions(&mut bucket.body, bucket_arg_order, true);
    }

    fn check_branch_bucket(
        &mut self,
        bucket: &mut BranchBucket,
        bucket_arg_order: &mut IndexMap<BucketId, ArgIndex>,
    ) {
        self.check_instruction(&mut bucket.cond, bucket_arg_order);
        self.check_instructions(&mut bucket.if_branch, bucket_arg_order, true);
        self.check_instructions(&mut bucket.else_branch, bucket_arg_order, true);
    }

    fn check_return_bucket(
        &mut self,
        bucket: &mut ReturnBucket,
        bucket_arg_order: &mut IndexMap<BucketId, ArgIndex>,
    ) {
        self.check_instruction(&mut bucket.value, bucket_arg_order);
    }

    fn check_log_bucket(
        &mut self,
        bucket: &mut LogBucket,
        bucket_arg_order: &mut IndexMap<BucketId, ArgIndex>,
    ) {
        for arg in &mut bucket.argsprint {
            if let LogBucketArg::LogExp(i) = arg {
                self.check_instruction(i, bucket_arg_order);
            }
        }
    }

    //Nothing to do
    fn check_value_bucket(&mut self, _: &mut ValueBucket, _: &mut IndexMap<BucketId, ArgIndex>) {}
    fn check_nop_bucket(&mut self, _: &mut NopBucket, _: &mut IndexMap<BucketId, ArgIndex>) {}

    fn check_instruction(
        &mut self,
        inst: &mut InstructionPointer,
        bucket_arg_order: &mut IndexMap<BucketId, ArgIndex>,
    ) {
        match inst.as_mut() {
            Instruction::Value(ref mut b) => self.check_value_bucket(b, bucket_arg_order),
            Instruction::Load(ref mut b) => self.check_load_bucket(b, bucket_arg_order),
            Instruction::Store(ref mut b) => self.check_store_bucket(b, bucket_arg_order),
            Instruction::Compute(ref mut b) => self.check_compute_bucket(b, bucket_arg_order),
            Instruction::Call(ref mut b) => self.check_call_bucket(b, bucket_arg_order),
            Instruction::Branch(ref mut b) => self.check_branch_bucket(b, bucket_arg_order),
            Instruction::Return(ref mut b) => self.check_return_bucket(b, bucket_arg_order),
            Instruction::Assert(ref mut b) => self.check_assert_bucket(b, bucket_arg_order),
            Instruction::Log(ref mut b) => self.check_log_bucket(b, bucket_arg_order),
            Instruction::Loop(ref mut b) => self.check_loop_bucket(b, bucket_arg_order),
            Instruction::CreateCmp(ref mut b) => self.check_create_cmp_bucket(b, bucket_arg_order),
            Instruction::Constraint(ref mut b) => self.check_constraint_bucket(b, bucket_arg_order),
            Instruction::Block(ref mut b) => self.check_block_bucket(b, bucket_arg_order),
            Instruction::Nop(ref mut b) => self.check_nop_bucket(b, bucket_arg_order),
        }
    }

    pub fn check_instructions(
        &mut self,
        insts: &mut Vec<InstructionPointer>,
        bucket_arg_order: &mut IndexMap<BucketId, ArgIndex>,
        can_insert: bool,
    ) {
        assert!(self.insert_after.is_empty());
        for i in &mut *insts {
            self.check_instruction(i, bucket_arg_order);
        }
        if can_insert {
            for s in self.insert_after.drain(..) {
                insts.push(s);
            }
        } else {
            assert!(self.insert_after.is_empty());
        }
    }
}
