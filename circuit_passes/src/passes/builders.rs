use std::vec;
use code_producers::llvm_elements::fr::*;
use compiler::intermediate_representation::{InstructionPointer, new_id};
use compiler::intermediate_representation::ir_interface::*;
use super::loop_unroll::body_extractor::AddressOffset;

pub fn build_u32_value(bucket: &dyn ObtainMeta, val: usize) -> InstructionPointer {
    ValueBucket {
        id: new_id(),
        source_file_id: bucket.get_source_file_id().clone(),
        line: bucket.get_line(),
        message_id: bucket.get_message_id(),
        parse_as: ValueType::U32,
        op_aux_no: 0,
        value: val,
    }
    .allocate()
}

pub fn build_call(
    meta: &dyn ObtainMeta,
    name: impl Into<String>,
    args: Vec<InstructionPointer>,
) -> InstructionPointer {
    CallBucket {
        id: new_id(),
        source_file_id: meta.get_source_file_id().clone(),
        line: meta.get_line(),
        message_id: meta.get_message_id(),
        symbol: name.into(),
        return_info: ReturnType::Intermediate { op_aux_no: 0 },
        arena_size: 0, // size 0 indicates arguments should not be placed into an arena
        argument_types: vec![], // LLVM IR generation doesn't use this field
        arguments: args,
    }
    .allocate()
}

pub fn build_custom_fn_load_bucket(
    bucket: &dyn ObtainMeta,
    load_fun: &str,
    addr_type: AddressType,
    location: InstructionPointer,
) -> InstructionPointer {
    LoadBucket {
        id: new_id(),
        source_file_id: bucket.get_source_file_id().clone(),
        line: bucket.get_line(),
        message_id: bucket.get_message_id(),
        address_type: addr_type,
        src: LocationRule::Indexed { location, template_header: None },
        bounded_fn: Some(String::from(load_fun)),
    }
    .allocate()
}

pub fn build_storage_ptr_ref(
    bucket: &dyn ObtainMeta,
    addr_type: AddressType,
) -> InstructionPointer {
    //NOTE: The only way to produce a pointer value in the circom bucket structure is to represent
    //  it as a function call, either CallBucket directly or LoadBucket with a 'bounded_fn' given.
    //NOTE: The 'FR_IDENTITY_ARR_PTR' function has only one parameter so the offset "location"
    //  parameter will be ignored by the LLVM IR producer. Using 'usize::MAX' here to make it more
    //  obvious if a bug creeps in due to future changes.
    build_custom_fn_load_bucket(
        bucket,
        FR_IDENTITY_ARR_PTR,
        addr_type,
        build_u32_value(bucket, usize::MAX),
    )
}

pub fn build_indexed_storage_ptr_ref(
    bucket: &dyn ObtainMeta,
    addr_type: AddressType,
    index: AddressOffset,
) -> InstructionPointer {
    //NOTE: The only way to produce a pointer value in the circom bucket structure is to represent
    //  it as a function call, either CallBucket directly or LoadBucket with a `bounded_fn` given.
    build_custom_fn_load_bucket(bucket, FR_INDEX_ARR_PTR, addr_type, build_u32_value(bucket, index))
}

pub fn build_subcmp_counter_storage_ptr_ref(
    bucket: &dyn ObtainMeta,
    sub_cmp_id: InstructionPointer,
) -> InstructionPointer {
    //NOTE: The 'FR_PTR_CAST_I32_I256' function has only one parameter so the offset "location"
    //  parameter will be ignored by the LLVM IR producer. Using 'usize::MAX' here to make it more
    //  obvious if a bug creeps in due to future changes.
    build_custom_fn_load_bucket(
        bucket,
        FR_PTR_CAST_I32_I256,
        AddressType::SubcmpSignal {
            cmp_address: sub_cmp_id,
            uniform_parallel_value: Option::None,
            is_output: false,
            input_information: InputInformation::NoInput,
            counter_override: true,
        },
        build_u32_value(bucket, usize::MAX),
    )
}

pub fn build_null_ptr(bucket: &dyn ObtainMeta, null_fun: &str) -> InstructionPointer {
    build_call(bucket, null_fun, vec![])
}
