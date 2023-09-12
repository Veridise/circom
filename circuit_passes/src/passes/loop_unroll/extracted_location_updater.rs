use std::collections::BTreeMap;
use compiler::intermediate_representation::{BucketId, InstructionPointer};
use compiler::intermediate_representation::ir_interface::*;
use super::new_u32_value;

pub struct ExtractedFunctionLocationUpdater {}

impl ExtractedFunctionLocationUpdater {
    fn check_load_bucket(
        bucket: &mut LoadBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        if let Some(x) = bucket_arg_order.remove(&bucket.id) {
            // Update the destination information to reference the argument
            //NOTE: This can't use AddressType::Variable or AddressType::Signal
            //  because ExtractedFunctionLLVMIRProducer references the first two
            //  parameters with those. So this has to use SubcmpSignal (it should
            //  work fine because subcomps will also just be additional params).
            bucket.address_type = AddressType::SubcmpSignal {
                cmp_address: new_u32_value(bucket, x),
                uniform_parallel_value: None,
                is_output: false,
                input_information: InputInformation::NoInput,
            };
            bucket.src = LocationRule::Indexed {
                location: new_u32_value(bucket, 0), //use index 0 to ref the entire storage array
                template_header: None,
            };
        } else {
            // If not replacing, check deeper in the AddressType and LocationRule
            Self::check_address_type(&mut bucket.address_type, bucket_arg_order);
            Self::check_location_rule(&mut bucket.src, bucket_arg_order);
        }
    }

    fn check_store_bucket(
        bucket: &mut StoreBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        // Check the source/RHS of the store in either case
        Self::check_instruction(&mut bucket.src, bucket_arg_order);
        //
        if let Some(x) = bucket_arg_order.remove(&bucket.id) {
            // Update the destination information to reference the argument
            bucket.dest_address_type = AddressType::SubcmpSignal {
                cmp_address: new_u32_value(bucket, x),
                uniform_parallel_value: None,
                is_output: false,
                input_information: InputInformation::NoInput,
            };
            bucket.dest = LocationRule::Indexed {
                location: new_u32_value(bucket, 0), //use index 0 to ref the entire storage array
                template_header: None,
            };
        } else {
            // If not replacing, check deeper in the AddressType and LocationRule
            Self::check_address_type(&mut bucket.dest_address_type, bucket_arg_order);
            Self::check_location_rule(&mut bucket.dest, bucket_arg_order);
        }
    }

    fn check_location_rule(
        location_rule: &mut LocationRule,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        match location_rule {
            LocationRule::Indexed { location, .. } => {
                Self::check_instruction(location, bucket_arg_order);
            }
            LocationRule::Mapped { .. } => unreachable!(),
        }
    }

    fn check_address_type(
        addr_type: &mut AddressType,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        if let AddressType::SubcmpSignal { cmp_address, .. } = addr_type {
            Self::check_instruction(cmp_address, bucket_arg_order);
        }
    }

    fn check_compute_bucket(
        bucket: &mut ComputeBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        for i in &mut bucket.stack {
            Self::check_instruction(i, bucket_arg_order);
        }
    }

    fn check_assert_bucket(
        bucket: &mut AssertBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        Self::check_instruction(&mut bucket.evaluate, bucket_arg_order);
    }

    fn check_loop_bucket(
        bucket: &mut LoopBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        todo!()
    }

    fn check_create_cmp_bucket(
        bucket: &mut CreateCmpBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        todo!()
    }

    fn check_constraint_bucket(
        bucket: &mut ConstraintBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        Self::check_instruction(
            match bucket {
                ConstraintBucket::Substitution(i) => i,
                ConstraintBucket::Equality(i) => i,
            },
            bucket_arg_order,
        );
    }

    fn check_block_bucket(
        bucket: &mut BlockBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        todo!()
    }

    fn check_call_bucket(
        bucket: &mut CallBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        todo!()
    }

    fn check_branch_bucket(
        bucket: &mut BranchBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        todo!()
    }

    fn check_return_bucket(
        bucket: &mut ReturnBucket,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        Self::check_instruction(&mut bucket.value, bucket_arg_order);
    }

    fn check_log_bucket(bucket: &mut LogBucket, bucket_arg_order: &mut BTreeMap<BucketId, usize>) {
        for arg in &mut bucket.argsprint {
            if let LogBucketArg::LogExp(i) = arg {
                Self::check_instruction(i, bucket_arg_order);
            }
        }
    }

    //Nothing to do
    fn check_value_bucket(_: &mut ValueBucket, _: &mut BTreeMap<BucketId, usize>) {}
    fn check_nop_bucket(_: &mut NopBucket, _: &mut BTreeMap<BucketId, usize>) {}

    pub fn check_instruction(
        inst: &mut InstructionPointer,
        bucket_arg_order: &mut BTreeMap<BucketId, usize>,
    ) {
        match inst.as_mut() {
            Instruction::Value(ref mut b) => Self::check_value_bucket(b, bucket_arg_order),
            Instruction::Load(ref mut b) => Self::check_load_bucket(b, bucket_arg_order),
            Instruction::Store(ref mut b) => Self::check_store_bucket(b, bucket_arg_order),
            Instruction::Compute(ref mut b) => Self::check_compute_bucket(b, bucket_arg_order),
            Instruction::Call(ref mut b) => Self::check_call_bucket(b, bucket_arg_order),
            Instruction::Branch(ref mut b) => Self::check_branch_bucket(b, bucket_arg_order),
            Instruction::Return(ref mut b) => Self::check_return_bucket(b, bucket_arg_order),
            Instruction::Assert(ref mut b) => Self::check_assert_bucket(b, bucket_arg_order),
            Instruction::Log(ref mut b) => Self::check_log_bucket(b, bucket_arg_order),
            Instruction::Loop(ref mut b) => Self::check_loop_bucket(b, bucket_arg_order),
            Instruction::CreateCmp(ref mut b) => Self::check_create_cmp_bucket(b, bucket_arg_order),
            Instruction::Constraint(ref mut b) => {
                Self::check_constraint_bucket(b, bucket_arg_order)
            }
            Instruction::Block(ref mut b) => Self::check_block_bucket(b, bucket_arg_order),
            Instruction::Nop(ref mut b) => Self::check_nop_bucket(b, bucket_arg_order),
        }
    }
}
