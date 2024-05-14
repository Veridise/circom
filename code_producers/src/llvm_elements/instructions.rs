use inkwell::basic_block::BasicBlock;
use inkwell::IntPredicate::{EQ, NE, SLT, SGT, SLE, SGE};
use inkwell::types::{AnyType, AnyTypeEnum, PointerType, IntType};
use inkwell::values::{
    AnyValue, AnyValueEnum, BasicMetadataValueEnum, BasicValue, FunctionValue, InstructionOpcode,
    InstructionValue, IntMathValue, IntValue, PointerValue,
};
use super::{to_basic_metadata_enum, LLVMIRProducer, LLVMInstruction};
use super::fr::{FR_MUL_FN_NAME, FR_LT_FN_NAME};
use super::functions::create_bb;
use super::stdlib::{CONSTRAINT_VALUES_FN_NAME, CONSTRAINT_VALUE_FN_NAME};
use super::types::{bigint_type, bool_type, i32_type};
use super::values::create_literal_u32;

macro_rules! debug_assert_expected_type {
    ($producer:ident, $expect:ident, $type:expr) => {
        debug_assert_eq!($expect($producer).as_any_type_enum(), $type, "expected left type");
    };
}

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
) -> LLVMInstruction<'a> {
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
) -> LLVMInstruction<'a> {
    create_pow_with_name(producer, in_func, lhs, rhs, "")
}

pub fn create_array_copy_with_name<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    src: PointerValue<'a>,
    dst: PointerValue<'a>,
    len: usize,
    gen_constraints: bool,
    name: &str,
) {
    for i in 0..len {
        let idx = create_literal_u32(producer, i as u64);
        // src[idx]
        let var_name = &format!("{}_src_{}", name, i);
        let src_ptr = create_gep_with_name(producer, src, &[idx], var_name);
        // dst[idx]
        let var_name = &format!("{}_dst_{}", name, i);
        let dst_ptr = create_gep_with_name(producer, dst, &[idx], var_name);
        // dst[idx] = src[idx]
        let var_name = &format!("{}_val_{}", name, i);
        create_store(producer, dst_ptr, create_load_with_name(producer, src_ptr, var_name));
        if gen_constraints {
            let value = create_load_with_name(producer, src_ptr, var_name);
            create_constraint_values_call(producer, value, dst_ptr);
        }
    }
}

pub fn create_array_copy<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    src: PointerValue<'a>,
    dst: PointerValue<'a>,
    len: usize,
    gen_constraints: bool,
) {
    create_array_copy_with_name(producer, src, dst, len, gen_constraints, "copy")
}

pub fn create_add_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_int_add(lhs, rhs, name).as_any_value_enum()
}

pub fn create_add<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> LLVMInstruction<'a> {
    create_add_with_name(producer, lhs, rhs, "")
}

pub fn create_sub_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_int_sub(lhs, rhs, name).as_any_value_enum()
}

pub fn create_sub<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> LLVMInstruction<'a> {
    create_sub_with_name(producer, lhs, rhs, "")
}

pub fn create_mul_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_int_mul(lhs, rhs, name).as_any_value_enum()
}

pub fn create_mul<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> LLVMInstruction<'a> {
    create_mul_with_name(producer, lhs, rhs, "")
}

pub fn create_div_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_int_signed_div(lhs, rhs, name).as_any_value_enum()
}

pub fn create_div<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> LLVMInstruction<'a> {
    create_div_with_name(producer, lhs, rhs, "")
}

pub fn create_inv_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    val: T,
    name: &str,
) -> LLVMInstruction<'a> {
    let lhs = bigint_type(producer).const_int(1, false);
    let rhs = val.as_basic_value_enum().into_int_value();
    producer.llvm().builder.build_int_signed_div(lhs, rhs, name).as_any_value_enum()
}

pub fn create_inv<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    val: T,
) -> LLVMInstruction<'a> {
    create_inv_with_name(producer, val, "")
}

pub fn create_mod_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_int_signed_rem(lhs, rhs, name).as_any_value_enum()
}

pub fn create_mod<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> LLVMInstruction<'a> {
    create_mod_with_name(producer, lhs, rhs, "")
}

pub fn create_eq_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_int_compare(EQ, lhs, rhs, name).as_any_value_enum()
}

pub fn create_eq<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> LLVMInstruction<'a> {
    create_eq_with_name(producer, lhs, rhs, "")
}

pub fn create_neq_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_int_compare(NE, lhs, rhs, name).as_any_value_enum()
}

pub fn create_neq<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> LLVMInstruction<'a> {
    create_neq_with_name(producer, lhs, rhs, "")
}

pub fn create_lt_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_int_compare(SLT, lhs, rhs, name).as_any_value_enum()
}

pub fn create_lt<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> LLVMInstruction<'a> {
    create_lt_with_name(producer, lhs, rhs, "")
}

pub fn create_gt_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_int_compare(SGT, lhs, rhs, name).as_any_value_enum()
}

pub fn create_gt<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> LLVMInstruction<'a> {
    create_gt_with_name(producer, lhs, rhs, "")
}

pub fn create_le_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_int_compare(SLE, lhs, rhs, name).as_any_value_enum()
}

pub fn create_le<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> LLVMInstruction<'a> {
    create_le_with_name(producer, lhs, rhs, "")
}

pub fn create_ge_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_int_compare(SGE, lhs, rhs, name).as_any_value_enum()
}

pub fn create_ge<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> LLVMInstruction<'a> {
    create_ge_with_name(producer, lhs, rhs, "")
}

pub fn create_neg_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    v: T,
    name: &str,
) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_int_neg(v, name).as_any_value_enum()
}

pub fn create_neg<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    v: T,
) -> LLVMInstruction<'a> {
    create_neg_with_name(producer, v, "")
}

pub fn create_shl_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_left_shift(lhs, rhs, name).as_any_value_enum()
}

pub fn create_shl<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> LLVMInstruction<'a> {
    create_shl_with_name(producer, lhs, rhs, "")
}

pub fn create_shr_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> LLVMInstruction<'a> {
    // Use sign_extend=true because values are signed.
    producer.llvm().builder.build_right_shift(lhs, rhs, true, name).as_any_value_enum()
}

pub fn create_shr<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> LLVMInstruction<'a> {
    create_shr_with_name(producer, lhs, rhs, "")
}

pub fn create_bit_and_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_and(lhs, rhs, name).as_any_value_enum()
}

pub fn create_bit_and<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> LLVMInstruction<'a> {
    create_bit_and_with_name(producer, lhs, rhs, "")
}

pub fn create_bit_or_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_or(lhs, rhs, name).as_any_value_enum()
}

pub fn create_bit_or<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> LLVMInstruction<'a> {
    create_bit_or_with_name(producer, lhs, rhs, "")
}

pub fn create_bit_xor_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_xor(lhs, rhs, name).as_any_value_enum()
}

pub fn create_bit_xor<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> LLVMInstruction<'a> {
    create_bit_xor_with_name(producer, lhs, rhs, "")
}

pub fn ensure_bool_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    val: T,
    name: &str,
) -> LLVMInstruction<'a> {
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
) -> LLVMInstruction<'a> {
    ensure_bool_with_name(producer, val, "")
}

pub fn ensure_int_type_match<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    val: IntValue<'a>,
    ty: IntType<'a>,
) -> IntValue<'a> {
    let val_ty = val.get_type();
    if val_ty == ty {
        // No conversion needed
        val
    } else if val_ty == bool_type(producer) {
        // Zero extend
        producer.llvm().builder.build_int_z_extend(val, ty, "")
    } else if ty == bool_type(producer) {
        // Convert to bool
        ensure_bool(producer, val).into_int_value()
    } else if val_ty.get_bit_width() < ty.get_bit_width() {
        producer.llvm().builder.build_int_s_extend(val, ty, "")
    } else {
        panic!(
            "Unhandled int conversion of value '{:?}': {:?} to {:?} not supported!",
            val, val_ty, ty
        )
    }
}

pub fn create_logic_and_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_and(lhs, rhs, name).as_any_value_enum()
}

pub fn create_logic_and<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> LLVMInstruction<'a> {
    create_logic_and_with_name(producer, lhs, rhs, "")
}

pub fn create_logic_or_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
    name: &str,
) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_or(lhs, rhs, name).as_any_value_enum()
}

pub fn create_logic_or<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    lhs: T,
    rhs: T,
) -> LLVMInstruction<'a> {
    create_logic_or_with_name(producer, lhs, rhs, "")
}

pub fn create_logic_not_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    val: T,
    name: &str,
) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_not(val, name).as_any_value_enum()
}

pub fn create_logic_not<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    val: T,
) -> LLVMInstruction<'a> {
    create_logic_not_with_name(producer, val, "")
}

pub fn create_store<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    ptr: PointerValue<'a>,
    value: AnyValueEnum<'a>,
) -> LLVMInstruction<'a> {
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

pub fn create_return_void<'a>(producer: &dyn LLVMIRProducer<'a>) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_return(None).as_any_value_enum()
}

pub fn create_return<'a, V: BasicValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    val: V,
) -> LLVMInstruction<'a> {
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

pub fn create_br<'a>(producer: &dyn LLVMIRProducer<'a>, bb: BasicBlock<'a>) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_unconditional_branch(bb).as_any_value_enum()
}

pub fn find_function<'a>(producer: &dyn LLVMIRProducer<'a>, name: &str) -> FunctionValue<'a> {
    producer
        .llvm()
        .module
        .get_function(name)
        .unwrap_or_else(|| panic!("Cannot find function {}", name))
}

pub fn create_call<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    name: &str,
    arguments: &[BasicMetadataValueEnum<'a>],
) -> LLVMInstruction<'a> {
    let f = find_function(producer, name);
    let params = f.get_params();
    let checked_arguments: Vec<BasicMetadataValueEnum<'a>> = arguments
        .iter()
        .zip(params.iter())
        .map(|(arg, param)| {
            if arg.is_int_value() && param.is_int_value() {
                ensure_int_type_match(
                    producer,
                    arg.into_int_value(),
                    param.get_type().into_int_type(),
                )
                .into()
            } else {
                *arg
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
) -> LLVMInstruction<'a> {
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
) -> LLVMInstruction<'a> {
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
) -> PointerValue<'a> {
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
}

pub fn create_load_with_name<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    ptr: PointerValue<'a>,
    name: &str,
) -> LLVMInstruction<'a> {
    producer.llvm().builder.build_load(ptr, name).as_any_value_enum()
}

pub fn create_load<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    ptr: PointerValue<'a>,
) -> LLVMInstruction<'a> {
    create_load_with_name(producer, ptr, "")
}

pub fn create_gep_with_name<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    ptr: PointerValue<'a>,
    indices: &[IntValue<'a>],
    name: &str,
) -> PointerValue<'a> {
    unsafe { producer.llvm().builder.build_gep(ptr, indices, name) }
}

pub fn create_gep<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    ptr: PointerValue<'a>,
    indices: &[IntValue<'a>],
) -> PointerValue<'a> {
    create_gep_with_name(producer, ptr, indices, "")
}

pub fn create_cast_to_addr_with_name<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    val: T,
    name: &str,
) -> LLVMInstruction<'a> {
    producer
        .llvm()
        .builder
        .build_cast(InstructionOpcode::Trunc, val, i32_type(producer), name)
        .as_any_value_enum()
}

pub fn create_cast_to_addr<'a, T: IntMathValue<'a>>(
    producer: &dyn LLVMIRProducer<'a>,
    val: T,
) -> LLVMInstruction<'a> {
    create_cast_to_addr_with_name(producer, val, "")
}

pub fn create_pointer_cast_with_name<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    from: PointerValue<'a>,
    to: PointerType<'a>,
    name: &str,
) -> PointerValue<'a> {
    producer.llvm().builder.build_pointer_cast(from, to, name)
}

pub fn create_pointer_cast<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    from: PointerValue<'a>,
    to: PointerType<'a>,
) -> PointerValue<'a> {
    producer.llvm().builder.build_pointer_cast(from, to, "")
}

pub fn create_switch<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    value: IntValue<'a>,
    else_block: BasicBlock<'a>,
    cases: &[(IntValue<'a>, BasicBlock<'a>)],
) -> InstructionValue<'a> {
    producer.llvm().builder.build_switch(value, else_block, cases)
}

pub fn create_constraint_alloc_with_name<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    name: &str,
) -> PointerValue<'a> {
    let ctx = producer.llvm().context();
    let alloca = create_alloca(producer, bool_type(producer).into(), name);
    let s = ctx.metadata_string("constraint");
    let kind = ctx.get_kind_id("constraint");
    let node = ctx.metadata_node(&[s.into()]);
    alloca
        .as_instruction()
        .unwrap()
        .set_metadata(node, kind)
        .expect("Could not setup metadata marker for constraint value");
    alloca
}

pub fn create_constraint_value_call_with_name<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    value: LLVMInstruction<'a>,
    name: &str,
) -> LLVMInstruction<'a> {
    debug_assert_expected_type!(producer, bool_type, value.get_type());
    let alloc = create_constraint_alloc_with_name(producer, name);
    create_call(
        producer,
        CONSTRAINT_VALUE_FN_NAME,
        &[to_basic_metadata_enum(value), to_basic_metadata_enum(alloc.into())],
    )
}

pub fn create_constraint_value_call<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    value: LLVMInstruction<'a>,
) -> LLVMInstruction<'a> {
    create_constraint_value_call_with_name(producer, value, "constraint")
}

pub fn create_constraint_values_call_with_name<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    value: LLVMInstruction<'a>,
    pointer: PointerValue<'a>,
    name: &str,
) -> LLVMInstruction<'a> {
    debug_assert_expected_type!(producer, bigint_type, value.get_type());
    let loaded = create_load(producer, pointer);
    debug_assert_expected_type!(producer, bigint_type, loaded.get_type());
    let alloc = create_constraint_alloc_with_name(producer, name);
    create_call(
        producer,
        CONSTRAINT_VALUES_FN_NAME,
        &[
            to_basic_metadata_enum(value),
            to_basic_metadata_enum(loaded),
            to_basic_metadata_enum(alloc.into()),
        ],
    )
}

pub fn create_constraint_values_call<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    value: LLVMInstruction<'a>,
    pointer: PointerValue<'a>,
) -> LLVMInstruction<'a> {
    create_constraint_values_call_with_name(producer, value, pointer, "constraint")
}
