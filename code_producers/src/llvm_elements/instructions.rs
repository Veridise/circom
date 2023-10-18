use inkwell::basic_block::BasicBlock;
use inkwell::IntPredicate::{EQ, NE, SLT, SGT, SLE, SGE};
use inkwell::types::{AnyTypeEnum, PointerType, IntType};
use inkwell::values::{
    AnyValue, AnyValueEnum, BasicMetadataValueEnum, BasicValue, BasicValueEnum, FunctionValue,
    InstructionOpcode, InstructionValue, IntMathValue, IntValue, PhiValue, PointerValue,
};
use crate::llvm_elements::{LLVMIRProducer};
use crate::llvm_elements::fr::{FR_MUL_FN_NAME, FR_LT_FN_NAME};
use crate::llvm_elements::functions::create_bb;
use crate::llvm_elements::types::{bigint_type, i32_type};
use crate::llvm_elements::values::zero;

use super::types::bool_type;

// bigint abv;
// if (rhs < 0)
//   abv = -rhs;
// else
//   abv = rhs;
// int res = 1;
// for(int i = 0; i < abv; i++)
//   res *= lhs;
// if (rhs < 0)
//   res = 1/res;
pub fn create_pow_with_name<'a, T: IntMathValue<'a> + Copy>(
    producer: &dyn LLVMIRProducer<'a>,
    in_func: FunctionValue<'a>,
    lhs: T,
    rhs: T,
    _name: &str,
) -> AnyValueEnum<'a> {
    let bldr = &producer.llvm().builder;
    let ty = bigint_type(producer);

    //// Generate absolute value if-then-else
    let res_is_neg = create_call(
        producer,
        FR_LT_FN_NAME,
        &[rhs.as_basic_value_enum().into(), ty.const_int(0, false).into()],
    )
    .into_int_value();
    let ptr_abv = bldr.build_alloca(ty, "abv");
    {
        let bb_if_then = create_bb(producer, in_func, "if.then.pow.abs");
        let bb_if_else = create_bb(producer, in_func, "if.else.pow.abs");
        let bb_if_merge = create_bb(producer, in_func, "if.merge.pow.abs");

        // Check the condition
        create_conditional_branch(producer, res_is_neg, bb_if_then, bb_if_else);
        // Then branch
        producer.set_current_bb(bb_if_then);
        bldr.build_store(ptr_abv, create_neg(producer, rhs).into_int_value());
        bldr.build_unconditional_branch(bb_if_merge);
        // Else branch
        producer.set_current_bb(bb_if_else);
        bldr.build_store(ptr_abv, rhs);
        bldr.build_unconditional_branch(bb_if_merge);
        // Merge/tail block
        producer.set_current_bb(bb_if_merge);
    }

    let ptr_res = bldr.build_alloca(ty, "res");
    bldr.build_store(ptr_res, ty.const_int(1, false));
    //// Generate loop to perform multiplications
    {
        let bb_lp_cond = create_bb(producer, in_func, "loop.cond.pow");
        let bb_lp_body = create_bb(producer, in_func, "loop.body.pow");
        let bb_lp_end = create_bb(producer, in_func, "loop.end.pow");

        //// Pre-loop initialization
        let ptr_lp_var = bldr.build_alloca(ty, "i");
        bldr.build_store(ptr_lp_var, ty.const_int(0, false));
        create_br(producer, bb_lp_cond);

        //// Loop condition block
        // [TH] I believe the loop variable does not require finite field
        //  arithmetic, thus the standard LLVM less-than operator is used.
        producer.set_current_bb(bb_lp_cond);
        let res_cond = create_lt(
            producer,
            bldr.build_load(ptr_lp_var, "").into_int_value(),
            bldr.build_load(ptr_abv, "").into_int_value(),
        );
        // XXX: Assumption: If the value is 0 the we go to the end block
        let _cond =
            create_conditional_branch(producer, res_cond.into_int_value(), bb_lp_body, bb_lp_end);

        //// Loop body block
        producer.set_current_bb(bb_lp_body);
        //   store( res, fn_mul( load(res) , lhs )) -- use method for finite field operation
        let res_mul = create_call(
            producer,
            FR_MUL_FN_NAME,
            &[bldr.build_load(ptr_res, "").into(), lhs.as_basic_value_enum().into()],
        );
        bldr.build_store(ptr_res, res_mul.into_int_value());
        //   store( i, addi( load(i) , const(1) )) -- use normal LLVM operation (like loop condition)
        let res_add = create_add(
            producer,
            bldr.build_load(ptr_lp_var, "").into_int_value(),
            ty.const_int(1, false),
        );
        bldr.build_store(ptr_lp_var, res_add.into_int_value());
        create_br(producer, bb_lp_cond);

        producer.set_current_bb(bb_lp_end);
    }

    //// Generate if-then to invert result when exponent is negative
    {
        let bb_if_then = create_bb(producer, in_func, "if.then.pow.inv");
        let bb_if_merge = create_bb(producer, in_func, "if.merge.pow.inv");

        // Check the condition
        create_conditional_branch(producer, res_is_neg, bb_if_then, bb_if_merge);
        // Then branch
        producer.set_current_bb(bb_if_then);
        bldr.build_store(
            ptr_res,
            create_inv(producer, bldr.build_load(ptr_res, "").into_int_value()).into_int_value(),
        );
        bldr.build_unconditional_branch(bb_if_merge);
        // Merge/tail block
        producer.set_current_bb(bb_if_merge);
    }

    // Return the value holding the result of the power operation
    bldr.build_load(ptr_res, "").as_any_value_enum()
}

pub fn create_pow<'a, T: IntMathValue<'a> + Copy>(
    producer: &dyn LLVMIRProducer<'a>,
    in_func: FunctionValue<'a>,
    lhs: T,
    rhs: T,
) -> AnyValueEnum<'a> {
    create_pow_with_name(producer, in_func, lhs, rhs, "")
}

// for(int i = 0; i < len; i++)
//   dst[i] = src[i]
pub fn create_array_copy_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    in_func: FunctionValue<'a>,
    src: PointerValue<'a>,
    dst: PointerValue<'a>,
    len: T,
    _name: &str,
) {
    let bldr = &producer.llvm().builder;
    let int_ty = len.as_any_value_enum().get_type().into_int_type();

    //// Loop blocks
    let bb_lp_cond = create_bb(producer, in_func, "loop.cond.copy");
    let bb_lp_body = create_bb(producer, in_func, "loop.body.copy");
    let bb_lp_end = create_bb(producer, in_func, "loop.end.copy");

    //// Pre-loop initialization
    let ptr_lp_var = bldr.build_alloca(int_ty, "i");
    bldr.build_store(ptr_lp_var, int_ty.const_int(0, false));
    create_br(producer, bb_lp_cond);

    //// Loop condition block
    // if (i < len)
    producer.set_current_bb(bb_lp_cond);
    let res_cond = create_lt_with_name(
        producer,
        create_load_with_name(producer, ptr_lp_var, "idx_val_for_loop_cond").into_int_value(),
        len.as_any_value_enum().into_int_value(),
        "idx_is_less_than_array_len"
    );
    // then go to loop, else exit
    create_conditional_branch(producer, res_cond.into_int_value(), bb_lp_body, bb_lp_end);

    //// Loop body block
    producer.set_current_bb(bb_lp_body);
    // i
    let cur_idx = create_load_with_name(producer, ptr_lp_var, "current_idx").into_int_value();
    // src[i]
    let src_ptr = create_gep_with_name(producer, src, &[cur_idx], "src_ptr_at_idx").into_pointer_value();
    let src_val = create_load_with_name(producer, src_ptr, "src_val_at_idx");
    // dst[i]
    let dst_ptr = create_gep_with_name(producer, dst, &[cur_idx], "dst_ptr_at_idx").into_pointer_value();
    // dst[i] = src[i]
    create_store(producer, dst_ptr, src_val);

    // i = i + 1
    let res_add = create_add_with_name(
        producer,
        cur_idx,
        int_ty.const_int(1, false),
        "next_idx"
    );
    bldr.build_store(ptr_lp_var, res_add.into_int_value());
    create_br(producer, bb_lp_cond);

    producer.set_current_bb(bb_lp_end);
}

pub fn create_array_copy<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    in_func: FunctionValue<'a>,
    src: PointerValue<'a>,
    dst: PointerValue<'a>,
    len: T,
) {
    create_array_copy_with_name(producer, in_func, src, dst, len, "")
}

pub fn create_add_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> AnyValueEnum<'a> {
    producer.llvm().builder.build_int_add(lhs, rhs, name).as_any_value_enum()
}

pub fn create_add<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> AnyValueEnum<'a> {
    create_add_with_name(producer, lhs, rhs, "")
}

pub fn create_sub_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> AnyValueEnum<'a> {
    producer.llvm().builder.build_int_sub(lhs, rhs, name).as_any_value_enum()
}

pub fn create_sub<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> AnyValueEnum<'a> {
    create_sub_with_name(producer, lhs, rhs, "")
}

pub fn create_mul_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> AnyValueEnum<'a> {
    producer.llvm().builder.build_int_mul(lhs, rhs, name).as_any_value_enum()
}

pub fn create_mul<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> AnyValueEnum<'a> {
    create_mul_with_name(producer, lhs, rhs, "")
}

pub fn create_div_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> AnyValueEnum<'a> {
    producer.llvm().builder.build_int_signed_div(lhs, rhs, name).as_any_value_enum()
}

pub fn create_div<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> AnyValueEnum<'a> {
    create_div_with_name(producer, lhs, rhs, "")
}

pub fn create_inv_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    val: T,
    name: &str,
) -> AnyValueEnum<'a> {
    let lhs = bigint_type(producer).const_int(1, false);
    let rhs = val.as_basic_value_enum().into_int_value();
    producer.llvm().builder.build_int_signed_div(lhs, rhs, name).as_any_value_enum()
}

pub fn create_inv<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    val: T,
) -> AnyValueEnum<'a> {
    create_inv_with_name(producer, val, "")
}

pub fn create_mod_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> AnyValueEnum<'a> {
    producer.llvm().builder.build_int_signed_rem(lhs, rhs, name).as_any_value_enum()
}

pub fn create_mod<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> AnyValueEnum<'a> {
    create_mod_with_name(producer, lhs, rhs, "")
}

pub fn create_eq_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> AnyValueEnum<'a> {
    producer.llvm().builder.build_int_compare(EQ, lhs, rhs, name).as_any_value_enum()
}

pub fn create_eq<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> AnyValueEnum<'a> {
    create_eq_with_name(producer, lhs, rhs, "")
}

pub fn create_neq_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> AnyValueEnum<'a> {
    producer.llvm().builder.build_int_compare(NE, lhs, rhs, name).as_any_value_enum()
}

pub fn create_neq<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> AnyValueEnum<'a> {
    create_neq_with_name(producer, lhs, rhs, "")
}

pub fn create_lt_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> AnyValueEnum<'a> {
    producer.llvm().builder.build_int_compare(SLT, lhs, rhs, name).as_any_value_enum()
}

pub fn create_lt<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> AnyValueEnum<'a> {
    create_lt_with_name(producer, lhs, rhs, "")
}

pub fn create_gt_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> AnyValueEnum<'a> {
    producer.llvm().builder.build_int_compare(SGT, lhs, rhs, name).as_any_value_enum()
}

pub fn create_gt<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> AnyValueEnum<'a> {
    create_gt_with_name(producer, lhs, rhs, "")
}

pub fn create_le_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> AnyValueEnum<'a> {
    producer.llvm().builder.build_int_compare(SLE, lhs, rhs, name).as_any_value_enum()
}

pub fn create_le<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> AnyValueEnum<'a> {
    create_le_with_name(producer, lhs, rhs, "")
}

pub fn create_ge_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> AnyValueEnum<'a> {
    producer.llvm().builder.build_int_compare(SGE, lhs, rhs, name).as_any_value_enum()
}

pub fn create_ge<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> AnyValueEnum<'a> {
    create_ge_with_name(producer, lhs, rhs, "")
}

pub fn create_neg_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    v: T,
    name: &str,
) -> AnyValueEnum<'a> {
    producer.llvm().builder.build_int_neg(v, name).as_any_value_enum()
}

pub fn create_neg<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    v: T,
) -> AnyValueEnum<'a> {
    create_neg_with_name(producer, v, "")
}

pub fn create_shl_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> AnyValueEnum<'a> {
    producer.llvm().builder.build_left_shift(lhs, rhs, name).as_any_value_enum()
}

pub fn create_shl<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> AnyValueEnum<'a> {
    create_shl_with_name(producer, lhs, rhs, "")
}

pub fn create_shr_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> AnyValueEnum<'a> {
    // Use sign_extend=true because values are signed.
    producer.llvm().builder.build_right_shift(lhs, rhs, true, name).as_any_value_enum()
}

pub fn create_shr<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> AnyValueEnum<'a> {
    create_shr_with_name(producer, lhs, rhs, "")
}

pub fn create_bit_and_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> AnyValueEnum<'a> {
    producer.llvm().builder.build_and(lhs, rhs, name).as_any_value_enum()
}

pub fn create_bit_and<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> AnyValueEnum<'a> {
    create_bit_and_with_name(producer, lhs, rhs, "")
}

pub fn create_bit_or_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> AnyValueEnum<'a> {
    producer.llvm().builder.build_or(lhs, rhs, name).as_any_value_enum()
}

pub fn create_bit_or<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> AnyValueEnum<'a> {
    create_bit_or_with_name(producer, lhs, rhs, "")
}

pub fn create_bit_xor_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> AnyValueEnum<'a> {
    producer.llvm().builder.build_xor(lhs, rhs, name).as_any_value_enum()
}

pub fn create_bit_xor<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> AnyValueEnum<'a> {
    create_bit_xor_with_name(producer, lhs, rhs, "")
}

pub fn ensure_bool_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    val: T,
    name: &str,
) -> AnyValueEnum<'a> {
    let int_val = val.as_basic_value_enum().into_int_value();
    if int_val.get_type() != bool_type(producer) {
        create_neq_with_name(producer, int_val, bigint_type(producer).const_zero(), name)
    } else {
        val.as_any_value_enum()
    }
}

pub fn ensure_bool<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    val: T,
) -> AnyValueEnum<'a> {
    ensure_bool_with_name(producer, val, "")
}

pub fn ensure_int_type_match<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    val: IntValue<'a>,
    ty: IntType<'a>,
) -> IntValue<'a> {
    if val.get_type() == ty {
        // No conversion needed
        val
    } else if val.get_type() == bool_type(producer) {
        // Zero extend
        producer.llvm().builder.build_int_z_extend(val, ty, "")
    } else if ty == bool_type(producer) {
        // Convert to bool
        ensure_bool(producer, val).into_int_value()
    } else {
        panic!(
            "Unhandled int conversion of value '{:?}': {:?} to {:?} not supported!",
            val,
            val.get_type(),
            ty
        )
    }
}

pub fn create_logic_and_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> AnyValueEnum<'a> {
    producer.llvm().builder.build_and(lhs, rhs, name).as_any_value_enum()
}

pub fn create_logic_and<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> AnyValueEnum<'a> {
    create_logic_and_with_name(producer, lhs, rhs, "")
}

pub fn create_logic_or_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> AnyValueEnum<'a> {
    producer.llvm().builder.build_or(lhs, rhs, name).as_any_value_enum()
}

pub fn create_logic_or<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> AnyValueEnum<'a> {
    create_logic_or_with_name(producer, lhs, rhs, "")
}

pub fn create_logic_not_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    val: T,
    name: &str,
) -> AnyValueEnum<'a> {
    producer.llvm().builder.build_not(val, name).as_any_value_enum()
}

pub fn create_logic_not<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    val: T,
) -> AnyValueEnum<'a> {
    create_logic_not_with_name(producer, val, "")
}

pub fn create_store<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    ptr: PointerValue<'a>,
    value: AnyValueEnum<'a>,
) -> AnyValueEnum<'a> {
    match value {
        AnyValueEnum::ArrayValue(v) => producer.llvm().builder.build_store(ptr, v),
        AnyValueEnum::IntValue(v) => {
            let store_ty = ptr.get_type().get_element_type().into_int_type();
            producer.llvm().builder.build_store(ptr, ensure_int_type_match(producer, v, store_ty))
        }
        AnyValueEnum::FloatValue(v) => producer.llvm().builder.build_store(ptr, v),
        AnyValueEnum::PointerValue(v) => producer.llvm().builder.build_store(ptr, v),
        AnyValueEnum::StructValue(v) => producer.llvm().builder.build_store(ptr, v),
        AnyValueEnum::VectorValue(v) => producer.llvm().builder.build_store(ptr, v),
        _ => panic!("We cannot create a store from a non basic value! There is a bug somewhere."),
    }
    .as_any_value_enum()
}

pub fn create_return_void<'a>(producer: &dyn LLVMIRProducer<'a>) -> AnyValueEnum<'a> {
    producer.llvm().builder.build_return(None).as_any_value_enum()
}

pub fn create_return<'a, V: BasicValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    val: V,
) -> AnyValueEnum<'a> {
    let f = producer
        .llvm()
        .builder
        .get_insert_block()
        .expect("no current block!")
        .get_parent()
        .expect("no current function!");
    let ret_ty =
        f.get_type().get_return_type().expect("non-void function should have a return type!");
    let ret_val = if ret_ty.is_int_type() {
        ensure_int_type_match(
            producer,
            val.as_basic_value_enum().into_int_value(),
            ret_ty.into_int_type(),
        )
        .as_basic_value_enum()
    } else {
        val.as_basic_value_enum()
    };
    producer.llvm().builder.build_return(Some(&ret_val)).as_any_value_enum()
}

pub fn create_br<'a>(producer: &dyn LLVMIRProducer<'a>, bb: BasicBlock<'a>) -> AnyValueEnum<'a> {
    producer.llvm().builder.build_unconditional_branch(bb).as_any_value_enum()
}

pub fn find_function<'a>(producer: &dyn LLVMIRProducer<'a>, name: &str) -> FunctionValue<'a> {
    producer
        .llvm()
        .module
        .get_function(name)
        .expect(format!("Cannot find function {}", name).as_str())
}

pub fn create_call<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    name: &str,
    arguments: &[BasicMetadataValueEnum<'a>],
) -> AnyValueEnum<'a> {
    let f = find_function(producer, name);
    let params = f.get_params();
    let checked_arguments: Vec<BasicMetadataValueEnum<'a>> = arguments
        .into_iter()
        .zip(params.into_iter())
        .map(|(arg, param)| {
            if arg.is_int_value() && param.is_int_value() {
                ensure_int_type_match(
                    producer,
                    arg.into_int_value(),
                    param.get_type().into_int_type(),
                )
                .into()
            } else {
                arg.clone()
            }
        })
        .collect();
    producer
        .llvm()
        .builder
        .build_call(f, &checked_arguments, format!("call.{}", name).as_str())
        .as_any_value_enum()
}

pub fn create_conditional_branch<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    comparison: IntValue<'a>,
    then_block: BasicBlock<'a>,
    else_block: BasicBlock<'a>,
) -> AnyValueEnum<'a> {
    let bool_comparison = ensure_bool(producer, comparison).into_int_value();
    producer
        .llvm()
        .builder
        .build_conditional_branch(bool_comparison, then_block, else_block)
        .as_any_value_enum()
}

pub fn create_return_from_any_value<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    val: AnyValueEnum<'a>,
) -> AnyValueEnum<'a> {
    match val {
        AnyValueEnum::ArrayValue(x) => create_return(producer, x),
        AnyValueEnum::IntValue(x) => create_return(producer, x),
        AnyValueEnum::FloatValue(x) => create_return(producer, x),
        AnyValueEnum::PointerValue(x) => create_return(producer, x),
        AnyValueEnum::StructValue(x) => create_return(producer, x),
        AnyValueEnum::VectorValue(x) => create_return(producer, x),
        _ => panic!("Cannot create a return from a non basic value!"),
    }
}

pub fn create_alloca<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    ty: AnyTypeEnum<'a>,
    name: &str,
) -> AnyValueEnum<'a> {
    match ty {
        AnyTypeEnum::ArrayType(ty) => producer.llvm().builder.build_alloca(ty, name),
        AnyTypeEnum::FloatType(ty) => producer.llvm().builder.build_alloca(ty, name),
        AnyTypeEnum::IntType(ty) => producer.llvm().builder.build_alloca(ty, name),
        AnyTypeEnum::PointerType(ty) => producer.llvm().builder.build_alloca(ty, name),
        AnyTypeEnum::StructType(ty) => producer.llvm().builder.build_alloca(ty, name),
        AnyTypeEnum::VectorType(ty) => producer.llvm().builder.build_alloca(ty, name),
        AnyTypeEnum::FunctionType(_) => panic!("We cannot allocate a function type!"),
        AnyTypeEnum::VoidType(_) => panic!("We cannot allocate a void type!"),
    }
    .as_any_value_enum()
}

pub fn create_phi<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    ty: AnyTypeEnum<'a>,
    name: &str,
) -> PhiValue<'a> {
    match ty {
        AnyTypeEnum::ArrayType(ty) => producer.builder().build_phi(ty, name),
        AnyTypeEnum::FloatType(ty) => producer.builder().build_phi(ty, name),
        AnyTypeEnum::IntType(ty) => producer.builder().build_phi(ty, name),
        AnyTypeEnum::PointerType(ty) => producer.builder().build_phi(ty, name),
        AnyTypeEnum::StructType(ty) => producer.builder().build_phi(ty, name),
        AnyTypeEnum::VectorType(ty) => producer.builder().build_phi(ty, name),
        _ => panic!("Cannot create a phi node with anything other than a basic type! {}", ty),
    }
}

pub fn create_phi_with_incoming<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    ty: AnyTypeEnum<'a>,
    incoming: &[(BasicValueEnum<'a>, BasicBlock<'a>)],
    name: &str,
) -> PhiValue<'a> {
    let phi = create_phi(producer, ty, name);
    // Hack to add the incoming to the phi value
    phi.add_incoming_as_enum(incoming);
    phi
}

pub fn create_load_with_name<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    ptr: PointerValue<'a>,
    name: &str,
) -> AnyValueEnum<'a> {
    producer.builder().build_load(ptr, name).as_any_value_enum()
}

pub fn create_load<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    ptr: PointerValue<'a>,
) -> AnyValueEnum<'a> {
    create_load_with_name(producer, ptr, "")
}

pub fn create_gep_with_name<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    ptr: PointerValue<'a>,
    indices: &[IntValue<'a>],
    name: &str,
) -> AnyValueEnum<'a> {
    unsafe { producer.llvm().builder.build_gep(ptr, indices, name) }
        .as_instruction()
        .unwrap()
        .as_any_value_enum()
}

pub fn create_gep<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    ptr: PointerValue<'a>,
    indices: &[IntValue<'a>],
) -> AnyValueEnum<'a> {
    create_gep_with_name(producer, ptr, indices, "")
}

pub fn get_instruction_arg(inst: InstructionValue, idx: u32) -> AnyValueEnum {
    let r = inst.get_operand(idx).unwrap();
    if r.is_left() {
        r.unwrap_left().as_any_value_enum()
    } else {
        r.unwrap_right().get_last_instruction().unwrap().as_any_value_enum()
    }
}

pub fn create_cast_to_addr_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    val: T,
    name: &str,
) -> AnyValueEnum<'a> {
    producer
        .llvm()
        .builder
        .build_cast(InstructionOpcode::Trunc, val, i32_type(producer), name)
        .as_any_value_enum()
}

pub fn create_cast_to_addr<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    val: T,
) -> AnyValueEnum<'a> {
    create_cast_to_addr_with_name(producer, val, "")
}

pub fn pointer_cast_with_name<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    from: PointerValue<'a>,
    to: PointerType<'a>,
    name: &str,
) -> PointerValue<'a> {
    producer.builder().build_pointer_cast(from, to, name)
}

pub fn pointer_cast<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    from: PointerValue<'a>,
    to: PointerType<'a>,
) -> PointerValue<'a> {
    producer.builder().build_pointer_cast(from, to, "")
}

pub fn create_switch<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    value: IntValue<'a>,
    else_block: BasicBlock<'a>,
    cases: &[(IntValue<'a>, BasicBlock<'a>)],
) -> InstructionValue<'a> {
    producer.builder().build_switch(value, else_block, cases)
}

/// Extracts the pointer and the second index of a gep instruction
/// getelementptr %ptr, 0, %idx ---> (%ptr, %idx)
pub fn get_data_from_gep<'a>(producer: &dyn LLVMIRProducer<'a>, gep: PointerValue<'a>) -> (PointerValue<'a>, usize) {
    let inst = gep.as_instruction().expect("GEP has to be an instruction!");
    debug_assert!(inst.get_opcode() == InstructionOpcode::GetElementPtr);
    let ptr = inst.get_operand(0)
        .expect("Pointer is missing in GEP")
        .expect_left("Pointer value must be a basic value!")
        .into_pointer_value();
    let fst_idx = inst.get_operand(1)
        .expect("First index is missing in GEP")
        .expect_left("First index must be a basic value!");
    debug_assert!(fst_idx == zero(producer));
    let op = inst.get_operand(2);
    let idx = op
        .expect("Second index is missing in GEP that is meant to be a signal")
        .expect_left("Second index must be a basic value!");
    let n = match idx {
        BasicValueEnum::IntValue(v) => v.get_sign_extended_constant(),
        _ => panic!("Second index must be an integer value!")
    };
    (ptr, n.expect("Could not load the integer value of the IntValue!") as usize)
}
