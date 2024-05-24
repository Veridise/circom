use inkwell::types::StringRadix;
use inkwell::values::IntValue;
use super::{LLVMIRProducer, LLVMValue, types::bigint_type};

pub fn create_literal_u32<'a>(producer: &dyn LLVMIRProducer<'a>, val: u64) -> IntValue<'a> {
    producer.llvm().context().i32_type().const_int(val, false)
}

pub fn zero<'a>(producer: &dyn LLVMIRProducer<'a>) -> IntValue<'a> {
    producer.llvm().context().i32_type().const_zero()
}

pub fn get_const<'a>(producer: &dyn LLVMIRProducer<'a>, value: usize) -> LLVMValue<'a> {
    let f = &producer.get_ff_constants()[value];
    bigint_type(producer).const_int_from_string(f, StringRadix::Decimal).unwrap().into()
}
