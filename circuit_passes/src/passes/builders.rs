use std::vec;
use code_producers::llvm_elements::fr::*;
use compiler::intermediate_representation::{InstructionPointer, new_id};
use compiler::intermediate_representation::ir_interface::*;
use crate::bucket_interpreter::memory::PassMemory;
use super::loop_unroll::body_extractor::AddressOffset;

pub fn build_u32_value_bucket(meta: &dyn ObtainMeta, val: usize) -> ValueBucket {
    ValueBucket {
        id: new_id(),
        source_file_id: meta.get_source_file_id().clone(),
        line: meta.get_line(),
        message_id: meta.get_message_id(),
        parse_as: ValueType::U32,
        op_aux_no: 0,
        value: val,
    }
}

pub fn build_u32_value(meta: &dyn ObtainMeta, val: usize) -> InstructionPointer {
    build_u32_value_bucket(meta, val).allocate()
}

pub fn build_bigint_value_bucket(
    meta: &dyn ObtainMeta,
    mem: &PassMemory,
    val: &dyn ToString,
) -> ValueBucket {
    ValueBucket {
        id: new_id(),
        source_file_id: meta.get_source_file_id().clone(),
        line: meta.get_line(),
        message_id: meta.get_message_id(),
        parse_as: ValueType::BigInt,
        op_aux_no: 0,
        value: mem.add_field_constant(val.to_string()),
    }
}

pub fn build_bigint_value(
    bucket: &dyn ObtainMeta,
    mem: &PassMemory,
    val: &dyn ToString,
) -> InstructionPointer {
    build_bigint_value_bucket(bucket, mem, val).allocate()
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
    meta: &dyn ObtainMeta,
    load_fun: &str,
    addr_type: AddressType,
    location: InstructionPointer,
) -> InstructionPointer {
    LoadBucket {
        id: new_id(),
        source_file_id: meta.get_source_file_id().clone(),
        line: meta.get_line(),
        message_id: meta.get_message_id(),
        address_type: addr_type,
        src: LocationRule::Indexed { location, template_header: None },
        bounded_fn: Some(String::from(load_fun)),
        context: InstrContext { size: 0 },
    }
    .allocate()
}

pub fn build_storage_ptr_ref(meta: &dyn ObtainMeta, addr_type: AddressType) -> InstructionPointer {
    //NOTE: The only way to produce a pointer value in the circom bucket structure is to represent
    //  it as a function call, either CallBucket directly or LoadBucket with a 'bounded_fn' given.
    //NOTE: The 'FR_IDENTITY_ARR_PTR' function has only one parameter so the offset "location"
    //  parameter will be ignored by the LLVM IR producer. Using 'usize::MAX' here to make it more
    //  obvious if a bug creeps in due to future changes.
    build_custom_fn_load_bucket(
        meta,
        FR_IDENTITY_ARR_PTR,
        addr_type,
        build_u32_value(meta, usize::MAX),
    )
}

pub fn build_indexed_storage_ptr_ref(
    meta: &dyn ObtainMeta,
    addr_type: AddressType,
    index: AddressOffset,
) -> InstructionPointer {
    //NOTE: The only way to produce a pointer value in the circom bucket structure is to represent
    //  it as a function call, either CallBucket directly or LoadBucket with a `bounded_fn` given.
    build_custom_fn_load_bucket(meta, FR_INDEX_ARR_PTR, addr_type, build_u32_value(meta, index))
}

pub fn build_subcmp_counter_storage_ptr_ref(
    meta: &dyn ObtainMeta,
    sub_cmp_id: InstructionPointer,
) -> InstructionPointer {
    //NOTE: The 'FR_PTR_CAST_I32_I256' function has only one parameter so the offset "location"
    //  parameter will be ignored by the LLVM IR producer. Using 'usize::MAX' here to make it more
    //  obvious if a bug creeps in due to future changes.
    build_custom_fn_load_bucket(
        meta,
        FR_PTR_CAST_I32_I256,
        AddressType::SubcmpSignal {
            cmp_address: sub_cmp_id,
            uniform_parallel_value: Option::None,
            is_output: false,
            input_information: InputInformation::NoInput,
            counter_override: true,
        },
        build_u32_value(meta, usize::MAX),
    )
}

pub fn build_null_ptr(meta: &dyn ObtainMeta, null_fun: &str) -> InstructionPointer {
    build_call(meta, null_fun, vec![])
}

pub fn build_void_return(meta: &dyn ObtainMeta) -> InstructionPointer {
    ReturnBucket {
        id: new_id(),
        source_file_id: meta.get_source_file_id().clone(),
        line: meta.get_line(),
        message_id: meta.get_message_id(),
        with_size: 0, // size 0 will produce "return void" LLVM instruction
        value: NopBucket { id: new_id() }.allocate(),
    }
    .allocate()
}
