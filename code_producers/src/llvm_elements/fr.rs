use inkwell::attributes::{Attribute, AttributeLoc};
use inkwell::values::FunctionValue;

use crate::llvm_elements::LLVMIRProducer;
use crate::llvm_elements::functions::{create_bb, create_function};
use crate::llvm_elements::instructions::{
    create_add, create_sub, create_mul, create_div, create_mod, create_pow, create_eq, create_neq,
    create_lt, create_gt, create_le, create_ge, create_gep, create_neg, create_shl, create_shr,
    create_bit_and, create_bit_or, create_bit_xor, create_logic_and, create_logic_or,
    create_logic_not, create_return, create_cast_to_addr,
};
use crate::llvm_elements::types::{bigint_type, bool_type, i32_type, void_type};

use super::instructions::create_array_copy;
use super::instructions::{create_inv, create_return_void};
use super::values::zero;

pub const FR_ADD_FN_NAME: &str = "fr_add";
pub const FR_SUB_FN_NAME: &str = "fr_sub";
pub const FR_MUL_FN_NAME: &str = "fr_mul";
pub const FR_DIV_FN_NAME: &str = "fr_div";
pub const FR_INTDIV_FN_NAME: &str = "fr_intdiv";
pub const FR_MOD_FN_NAME: &str = "fr_mod";
pub const FR_POW_FN_NAME: &str = "fr_pow";
pub const FR_EQ_FN_NAME: &str = "fr_eq";
pub const FR_NEQ_FN_NAME: &str = "fr_neq";
pub const FR_LT_FN_NAME: &str = "fr_lt";
pub const FR_GT_FN_NAME: &str = "fr_gt";
pub const FR_LE_FN_NAME: &str = "fr_le";
pub const FR_GE_FN_NAME: &str = "fr_ge";
pub const FR_NEG_FN_NAME: &str = "fr_neg";
pub const FR_SHL_FN_NAME: &str = "fr_shl";
pub const FR_SHR_FN_NAME: &str = "fr_shr";
pub const FR_BITAND_FN_NAME: &str = "fr_bit_and";
pub const FR_BITOR_FN_NAME: &str = "fr_bit_or";
pub const FR_BITXOR_FN_NAME: &str = "fr_bit_xor";
pub const FR_BITFLIP_FN_NAME: &str = "fr_bit_flip";
pub const FR_LAND_FN_NAME: &str = "fr_logic_and";
pub const FR_LOR_FN_NAME: &str = "fr_logic_or";
pub const FR_LNOT_FN_NAME: &str = "fr_logic_not";
pub const FR_ADDR_CAST_FN_NAME: &str = "fr_cast_to_addr";
pub const FR_ARRAY_COPY_FN_NAME: &str = "fr_copy_n";
pub const FR_IDENTITY_ARR_PTR: &str = "identity_arr_ptr";
pub const FR_INDEX_ARR_PTR: &str = "index_arr_ptr";

macro_rules! fr_unary_op_base {
    ($name: expr, $producer: expr, $argTy: expr, $retTy: expr) => {{
        let args = &[$argTy.into()];
        let func = create_function($producer, &None, 0, "", $name, $retTy.fn_type(args, false));
        let main = create_bb($producer, func, $name);
        $producer.set_current_bb(main);

        let lhs = func.get_nth_param(0).unwrap();
        lhs
    }};
}

macro_rules! fr_unary_op {
    ($name: expr, $producer: expr, $valTy: expr) => {{
        fr_unary_op_base!($name, $producer, $valTy, $valTy)
    }};
}

macro_rules! fr_binary_op_base {
    ($name: expr, $producer: expr, $argTy: expr, $retTy: expr) => {{
        let args = &[$argTy.into(), $argTy.into()];
        let func = create_function($producer, &None, 0, "", $name, $retTy.fn_type(args, false));
        let main = create_bb($producer, func, $name);
        $producer.set_current_bb(main);

        let lhs = func.get_nth_param(0).unwrap();
        let rhs = func.get_nth_param(1).unwrap();
        (lhs, rhs)
    }};
}

macro_rules! fr_binary_op_bigint {
    ($name: expr, $producer: expr) => {{
        let ty = bigint_type($producer);
        fr_binary_op_base!($name, $producer, ty, ty)
    }};
}

macro_rules! fr_binary_op_bool {
    ($name: expr, $producer: expr) => {{
        let ty = bool_type($producer);
        fr_binary_op_base!($name, $producer, ty, ty)
    }};
}

macro_rules! fr_binary_op_bigint_to_bool {
    ($name: expr, $producer: expr) => {{
        fr_binary_op_base!($name, $producer, bigint_type($producer), bool_type($producer))
    }};
}

fn add_inline_attribute<'a>(producer: &dyn LLVMIRProducer<'a>, func: FunctionValue) {
    func.add_attribute(
        AttributeLoc::Function,
        producer
            .context()
            .create_enum_attribute(Attribute::get_named_enum_kind_id("alwaysinline"), 1),
    );
}

fn add_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_ADD_FN_NAME, producer);
    let add = create_add(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, add.into_int_value());
}

fn sub_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_SUB_FN_NAME, producer);
    let add = create_sub(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, add.into_int_value());
}

fn mul_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_MUL_FN_NAME, producer);
    let add = create_mul(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, add.into_int_value());
}

// Multiplication by the inverse
fn div_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_DIV_FN_NAME, producer);
    let inv = create_inv(producer, rhs.into_int_value());
    let res = create_mul(producer, lhs.into_int_value(), inv.into_int_value());
    create_return(producer, res.into_int_value());
}

// Quotient of the integer division
fn intdiv_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_INTDIV_FN_NAME, producer);
    let res = create_div(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

// Remainder of the integer division
fn mod_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_MOD_FN_NAME, producer);
    let div = create_mod(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, div.into_int_value());
}

fn pow_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_POW_FN_NAME, producer);
    let f = producer
        .llvm()
        .module
        .get_function(FR_POW_FN_NAME)
        .expect(format!("Cannot find function {}", FR_POW_FN_NAME).as_str());
    let res = create_pow(producer, f, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn eq_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let (lhs, rhs) = fr_binary_op_bigint_to_bool!(FR_EQ_FN_NAME, producer);
    let eq = create_eq(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, eq.into_int_value());
}

fn neq_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let (lhs, rhs) = fr_binary_op_bigint_to_bool!(FR_NEQ_FN_NAME, producer);
    let neq = create_neq(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, neq.into_int_value());
}

fn lt_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let (lhs, rhs) = fr_binary_op_bigint_to_bool!(FR_LT_FN_NAME, producer);
    let res = create_lt(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn gt_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let (lhs, rhs) = fr_binary_op_bigint_to_bool!(FR_GT_FN_NAME, producer);
    let res = create_gt(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn le_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let (lhs, rhs) = fr_binary_op_bigint_to_bool!(FR_LE_FN_NAME, producer);
    let res = create_le(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn ge_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let (lhs, rhs) = fr_binary_op_bigint_to_bool!(FR_GE_FN_NAME, producer);
    let res = create_ge(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn neg_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let arg = fr_unary_op!(FR_NEG_FN_NAME, producer, bigint_type(producer));
    let neg = create_neg(producer, arg.into_int_value());
    create_return(producer, neg.into_int_value());
}

fn shl_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_SHL_FN_NAME, producer);
    let res = create_shl(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn shr_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_SHR_FN_NAME, producer);
    let res = create_shr(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn bit_and_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_BITAND_FN_NAME, producer);
    let res = create_bit_and(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn bit_or_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_BITOR_FN_NAME, producer);
    let res = create_bit_or(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn bit_xor_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_BITXOR_FN_NAME, producer);
    let res = create_bit_xor(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn bit_flip_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let ty = bigint_type(producer);
    let arg = fr_unary_op!(FR_BITFLIP_FN_NAME, producer, ty);
    // ~x <=> xor(x, 0xFF...)
    let res = create_bit_xor(producer, arg.into_int_value(), ty.const_all_ones());
    create_return(producer, res.into_int_value());
}

fn logic_and_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let (lhs, rhs) = fr_binary_op_bool!(FR_LAND_FN_NAME, producer);
    let res = create_logic_and(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn logic_or_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let (lhs, rhs) = fr_binary_op_bool!(FR_LOR_FN_NAME, producer);
    let res = create_logic_or(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn logic_not_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let arg = fr_unary_op!(FR_LNOT_FN_NAME, producer, bool_type(producer));
    let res = create_logic_not(producer, arg.into_int_value());
    create_return(producer, res.into_int_value());
}

fn addr_cast_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let arg = fr_unary_op_base!(
        FR_ADDR_CAST_FN_NAME,
        producer,
        bigint_type(producer),
        i32_type(producer)
    );
    let res = create_cast_to_addr(producer, arg.into_int_value());
    create_return(producer, res.into_int_value());
}

fn array_copy_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let ptr_ty = bigint_type(producer).ptr_type(Default::default());
    let args = &[ptr_ty.into(), ptr_ty.into(), i32_type(producer).into()];
    let func = create_function(
        producer,
        &None,
        0,
        "",
        FR_ARRAY_COPY_FN_NAME,
        void_type(producer).fn_type(args, false),
    );
    let main = create_bb(producer, func, FR_ARRAY_COPY_FN_NAME);
    producer.set_current_bb(main);

    let src = func.get_nth_param(0).unwrap();
    let dst = func.get_nth_param(1).unwrap();
    let len = func.get_nth_param(2).unwrap();
    create_array_copy(producer, func, src.into_pointer_value(), dst.into_pointer_value(), len.into_int_value());

    create_return_void(producer);
}

fn identity_arr_ptr_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let val_type = bigint_type(producer).array_type(0).ptr_type(Default::default());
    let func = create_function(
        producer,
        &None,
        0,
        "",
        FR_IDENTITY_ARR_PTR,
        val_type.fn_type(&[val_type.into()], false),
    );
    add_inline_attribute(producer, func);

    let main = create_bb(producer, func, FR_IDENTITY_ARR_PTR);
    producer.set_current_bb(main);
    // Just return the parameter
    create_return(producer, func.get_nth_param(0).unwrap());
}

fn index_arr_ptr_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
    let bigint_ty = bigint_type(producer);
    let val_ty = bigint_ty.array_type(0).ptr_type(Default::default());
    let func = create_function(
        producer,
        &None,
        0,
        "",
        FR_INDEX_ARR_PTR,
        val_ty.fn_type(&[val_ty.into(), bigint_ty.into()], false),
    );
    add_inline_attribute(producer, func);

    let arr = func.get_nth_param(0).unwrap();
    let idx = func.get_nth_param(1).unwrap();
    arr.set_name("arr");
    idx.set_name("idx");

    let main = create_bb(producer, func, FR_INDEX_ARR_PTR);
    producer.set_current_bb(main);
    let gep =
        create_gep(producer, arr.into_pointer_value(), &[zero(producer), idx.into_int_value()]);
    let cast = producer.llvm().builder.build_bitcast(gep.into_pointer_value(), val_ty, "");
    create_return(producer, cast.into_pointer_value());
}

pub fn load_fr<'a>(producer: &dyn LLVMIRProducer<'a>) {
    add_fn(producer);
    sub_fn(producer);
    mul_fn(producer);
    div_fn(producer);
    intdiv_fn(producer);
    mod_fn(producer);
    eq_fn(producer);
    neq_fn(producer);
    lt_fn(producer);
    gt_fn(producer);
    le_fn(producer);
    ge_fn(producer);
    neg_fn(producer);
    shl_fn(producer);
    shr_fn(producer);
    bit_and_fn(producer);
    bit_or_fn(producer);
    bit_xor_fn(producer);
    bit_flip_fn(producer);
    logic_and_fn(producer);
    logic_or_fn(producer);
    logic_not_fn(producer);
    addr_cast_fn(producer);
    array_copy_fn(producer);
    identity_arr_ptr_fn(producer);
    index_arr_ptr_fn(producer);
    pow_fn(producer); //uses functions generated by mul_fn & lt_fn
}
