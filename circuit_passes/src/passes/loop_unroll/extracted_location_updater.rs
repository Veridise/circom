use std::collections::HashMap;
use code_producers::llvm_elements::fr::FR_IDENTITY_ARR_PTR;
use compiler::intermediate_representation::{BucketId, InstructionPointer, new_id};
use compiler::intermediate_representation::ir_interface::*;
use super::body_extractor::ArgIndex;
use super::new_u32_value;

pub struct ExtractedFunctionLocationUpdater {
    pub insert_after: InstructionList,
}

impl ExtractedFunctionLocationUpdater {
    pub fn new() -> ExtractedFunctionLocationUpdater {
        ExtractedFunctionLocationUpdater { insert_after: Default::default() }
    }

    fn check_load_bucket(
        &mut self,
        bucket: &mut LoadBucket,
        bucket_arg_order: &mut HashMap<BucketId, ArgIndex>,
    ) {
        if let Some(ai) = bucket_arg_order.remove(&bucket.id) {
            // Update the location information to reference the argument
            //NOTE: This can't use AddressType::Variable or AddressType::Signal
            //  because ExtractedFunctionLLVMIRProducer references the first two
            //  parameters with those. So this has to use SubcmpSignal (it should
            //  work fine because subcomps will also just be additional params).
            bucket.address_type = AddressType::SubcmpSignal {
                cmp_address: new_u32_value(bucket, ai.get_signal_idx()),
                uniform_parallel_value: None,
                counter_override: false,
                is_output: false,
                input_information: InputInformation::NoInput,
            };
            bucket.src = LocationRule::Indexed {
                location: new_u32_value(bucket, 0), //use index 0 to ref the entire storage array
                template_header: None,
            };
        } else {
            // If not replacing, check deeper in the AddressType and LocationRule
            self.check_address_type(&mut bucket.address_type, bucket_arg_order);
            self.check_location_rule(&mut bucket.src, bucket_arg_order);
        }
    }

    fn check_store_bucket(
        &mut self,
        bucket: &mut StoreBucket,
        bucket_arg_order: &mut HashMap<BucketId, ArgIndex>,
    ) {
        // Check the source/RHS of the store in either case
        self.check_instruction(&mut bucket.src, bucket_arg_order);
        //
        if let Some(ai) = bucket_arg_order.remove(&bucket.id) {
            // If needed, add a StoreBucket to 'insert_after' that will call the template_run function.
            // NOTE: This must happen before the modification step so it can use existing values from the bucket.
            if let ArgIndex::SubCmp { arena, .. } = ai {
                self.insert_after.push(
                    StoreBucket {
                        id: new_id(),
                        source_file_id: bucket.source_file_id.clone(),
                        line: bucket.line,
                        message_id: bucket.message_id,
                        context: bucket.context.clone(),
                        dest_is_output: bucket.dest_is_output,
                        dest_address_type: AddressType::SubcmpSignal {
                            cmp_address: new_u32_value(bucket, arena),
                            uniform_parallel_value: None,
                            counter_override: false,
                            is_output: false,
                            //TODO: Not sure what to put here. If I put Unknown (assuming the later pass
                            //  would correct) it crashes somewhere. What I really need is Last in the
                            //  proper place to make it generate the *_run function at the right time
                            //  but NoLast in locations prior to that (I think). Why isn't Unknown handled
                            //  by the later pass deterministic subcomp pass or something? Always using
                            //  Last here could result in the run function being called too soon.
                            //SEE: circom/tests/subcmps/subcmps0C.circom
                            input_information: InputInformation::Input {
                                status: StatusInput::Last,
                            },
                        },
                        dest: LocationRule::Indexed {
                            location: new_u32_value(bucket, 0), //the value here is ignored by the 'bounded_fn' below
                            template_header: match &bucket.dest {
                                LocationRule::Indexed { template_header, .. } => {
                                    template_header.clone()
                                }
                                LocationRule::Mapped { .. } => todo!(),
                            },
                        },
                        src: new_u32_value(bucket, 0), //the value here is ignored at runtime
                        bounded_fn: Some(String::from(FR_IDENTITY_ARR_PTR)), //NOTE: doesn't have enough arguments but it works out
                    }
                    .allocate(),
                );
                // NOTE: Not adding counter for now because it shouldn't be needed anyway and it's more work to add.
                //  The best approach would probably be to generate Load+Compute+Store (based on what StoreBucket
                //  would normally generate for it) in an "insert_before" list just like the "insert_after" list.
            }

            //Transform this bucket into the normal fixed-index signal reference
            bucket.dest_address_type = AddressType::SubcmpSignal {
                cmp_address: new_u32_value(bucket, ai.get_signal_idx()),
                uniform_parallel_value: None,
                counter_override: false,
                is_output: false,
                input_information: InputInformation::NoInput,
            };
            bucket.dest = LocationRule::Indexed {
                location: new_u32_value(bucket, 0), //use index 0 to ref the entire storage array
                template_header: None,
            };
        } else {
            // If not replacing, check deeper in the AddressType and LocationRule
            self.check_address_type(&mut bucket.dest_address_type, bucket_arg_order);
            self.check_location_rule(&mut bucket.dest, bucket_arg_order);
        }
    }

    fn check_location_rule(
        &mut self,
        location_rule: &mut LocationRule,
        bucket_arg_order: &mut HashMap<BucketId, ArgIndex>,
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
        bucket_arg_order: &mut HashMap<BucketId, ArgIndex>,
    ) {
        if let AddressType::SubcmpSignal { cmp_address, .. } = addr_type {
            self.check_instruction(cmp_address, bucket_arg_order);
        }
    }

    fn check_compute_bucket(
        &mut self,
        bucket: &mut ComputeBucket,
        bucket_arg_order: &mut HashMap<BucketId, ArgIndex>,
    ) {
        self.check_instructions(&mut bucket.stack, bucket_arg_order);
    }

    fn check_assert_bucket(
        &mut self,
        bucket: &mut AssertBucket,
        bucket_arg_order: &mut HashMap<BucketId, ArgIndex>,
    ) {
        self.check_instruction(&mut bucket.evaluate, bucket_arg_order);
    }

    fn check_loop_bucket(
        &mut self,
        bucket: &mut LoopBucket,
        bucket_arg_order: &mut HashMap<BucketId, ArgIndex>,
    ) {
        self.check_instruction(&mut bucket.continue_condition, bucket_arg_order);
        self.check_instructions(&mut bucket.body, bucket_arg_order);
    }

    fn check_create_cmp_bucket(
        &mut self,
        bucket: &mut CreateCmpBucket,
        bucket_arg_order: &mut HashMap<BucketId, ArgIndex>,
    ) {
        self.check_instruction(&mut bucket.sub_cmp_id, bucket_arg_order);
    }

    fn check_constraint_bucket(
        &mut self,
        bucket: &mut ConstraintBucket,
        bucket_arg_order: &mut HashMap<BucketId, ArgIndex>,
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
        bucket_arg_order: &mut HashMap<BucketId, ArgIndex>,
    ) {
        self.check_instructions(&mut bucket.body, bucket_arg_order);
    }

    fn check_call_bucket(
        &mut self,
        bucket: &mut CallBucket,
        bucket_arg_order: &mut HashMap<BucketId, ArgIndex>,
    ) {
        self.check_instructions(&mut bucket.arguments, bucket_arg_order);
    }

    fn check_branch_bucket(
        &mut self,
        bucket: &mut BranchBucket,
        bucket_arg_order: &mut HashMap<BucketId, ArgIndex>,
    ) {
        self.check_instruction(&mut bucket.cond, bucket_arg_order);
        self.check_instructions(&mut bucket.if_branch, bucket_arg_order);
        self.check_instructions(&mut bucket.else_branch, bucket_arg_order);
    }

    fn check_return_bucket(
        &mut self,
        bucket: &mut ReturnBucket,
        bucket_arg_order: &mut HashMap<BucketId, ArgIndex>,
    ) {
        self.check_instruction(&mut bucket.value, bucket_arg_order);
    }

    fn check_log_bucket(
        &mut self,
        bucket: &mut LogBucket,
        bucket_arg_order: &mut HashMap<BucketId, ArgIndex>,
    ) {
        for arg in &mut bucket.argsprint {
            if let LogBucketArg::LogExp(i) = arg {
                self.check_instruction(i, bucket_arg_order);
            }
        }
    }

    //Nothing to do
    fn check_value_bucket(&mut self, _: &mut ValueBucket, _: &mut HashMap<BucketId, ArgIndex>) {}
    fn check_nop_bucket(&mut self, _: &mut NopBucket, _: &mut HashMap<BucketId, ArgIndex>) {}

    fn check_instructions(
        &mut self,
        insts: &mut Vec<InstructionPointer>,
        bucket_arg_order: &mut HashMap<BucketId, ArgIndex>,
    ) {
        for i in insts {
            self.check_instruction(i, bucket_arg_order);
        }
    }

    pub fn check_instruction(
        &mut self,
        inst: &mut InstructionPointer,
        bucket_arg_order: &mut HashMap<BucketId, ArgIndex>,
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
}
