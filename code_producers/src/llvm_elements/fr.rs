use inkwell::attributes::{Attribute, AttributeLoc};
use inkwell::values::FunctionValue;
use super::LLVMIRProducer;
use super::functions::{create_bb, create_function};
use super::instructions::*;
use super::types::{bigint_type, bool_type, i32_type};
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
pub const FR_INDEX_ARR_PTR: &str = "index_arr_ptr";
pub const FR_IDENTITY_ARR_PTR: &str = "identity_arr_ptr";
pub const FR_PTR_CAST_I32_I256: &str = "cast_ptr_i32_i256";
pub const FR_PTR_CAST_I256_I32: &str = "cast_ptr_i256_i32";
pub const FR_NULL_I256_ARR_PTR: &str = "null_i256_arr_ptr";
pub const FR_NULL_I256_PTR: &str = "null_i256_ptr";

thread_local!(
    /// Contains all "built-in" functions that can be generated in
    /// the Circom IR prior to the stage where LLVM IR is generated.
    static BUILT_IN_NAMES: std::collections::HashSet<&'static str> = {
      let mut result =  std::collections::HashSet::default();
      result.insert(FR_INDEX_ARR_PTR);
      result.insert(FR_IDENTITY_ARR_PTR);
      result.insert(FR_PTR_CAST_I32_I256);
      result.insert(FR_PTR_CAST_I256_I32);
      result.insert(FR_NULL_I256_ARR_PTR);
      result.insert(FR_NULL_I256_PTR);
      result
    }
);

pub fn is_builtin_function(name: &str) -> bool {
    BUILT_IN_NAMES.with(|s| s.contains(name))
}

macro_rules! fr_nullary_op {
    ($name: expr, $producer: expr, $retTy: expr) => {{
        let func = create_function($producer, &None, 0, "", $name, $retTy.fn_type(&[], false));
        let main = create_bb($producer, func, $name);
        $producer.llvm().set_current_bb(main);
        func
    }};
}

macro_rules! fr_unary_op_base {
    ($name: expr, $producer: expr, $argTy: expr, $retTy: expr) => {{
        let args = &[$argTy.into()];
        let func = create_function($producer, &None, 0, "", $name, $retTy.fn_type(args, false));
        let main = create_bb($producer, func, $name);
        $producer.llvm().set_current_bb(main);

        let lhs = func.get_nth_param(0).unwrap();
        (lhs, func)
    }};
}

macro_rules! fr_unary_op {
    ($name: expr, $producer: expr, $valTy: expr) => {{
        fr_unary_op_base!($name, $producer, $valTy, $valTy).0
    }};
}

macro_rules! fr_binary_op_base {
    ($name: expr, $producer: expr, $argTy: expr, $retTy: expr) => {{
        let args = &[$argTy.into(), $argTy.into()];
        let func = create_function($producer, &None, 0, "", $name, $retTy.fn_type(args, false));
        let main = create_bb($producer, func, $name);
        $producer.llvm().set_current_bb(main);

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

fn add_inline_attribute(producer: &dyn LLVMIRProducer, func: FunctionValue) {
    func.add_attribute(
        AttributeLoc::Function,
        producer
            .llvm()
            .context()
            .create_enum_attribute(Attribute::get_named_enum_kind_id("alwaysinline"), 1),
    );
}

fn add_fn(producer: &dyn LLVMIRProducer) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_ADD_FN_NAME, producer);
    let add = create_add(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, add.into_int_value());
}

fn sub_fn(producer: &dyn LLVMIRProducer) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_SUB_FN_NAME, producer);
    let add = create_sub(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, add.into_int_value());
}

fn mul_fn(producer: &dyn LLVMIRProducer) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_MUL_FN_NAME, producer);
    let add = create_mul(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, add.into_int_value());
}

// Multiplication by the inverse
fn div_fn(producer: &dyn LLVMIRProducer) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_DIV_FN_NAME, producer);
    let inv = create_inv(producer, rhs.into_int_value());
    let res = create_mul(producer, lhs.into_int_value(), inv.into_int_value());
    create_return(producer, res.into_int_value());
}

// Quotient of the integer division
fn intdiv_fn(producer: &dyn LLVMIRProducer) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_INTDIV_FN_NAME, producer);
    let res = create_div(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

// Remainder of the integer division
fn mod_fn(producer: &dyn LLVMIRProducer) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_MOD_FN_NAME, producer);
    let div = create_mod(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, div.into_int_value());
}

fn pow_fn(producer: &dyn LLVMIRProducer) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_POW_FN_NAME, producer);
    let f = producer
        .llvm()
        .module
        .get_function(FR_POW_FN_NAME)
        .unwrap_or_else(|| panic!("Cannot find function {}", FR_POW_FN_NAME));
    let res = create_pow(producer, f, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn eq_fn(producer: &dyn LLVMIRProducer) {
    let (lhs, rhs) = fr_binary_op_bigint_to_bool!(FR_EQ_FN_NAME, producer);
    let eq = create_eq(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, eq.into_int_value());
}

fn neq_fn(producer: &dyn LLVMIRProducer) {
    let (lhs, rhs) = fr_binary_op_bigint_to_bool!(FR_NEQ_FN_NAME, producer);
    let neq = create_neq(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, neq.into_int_value());
}

fn lt_fn(producer: &dyn LLVMIRProducer) {
    let (lhs, rhs) = fr_binary_op_bigint_to_bool!(FR_LT_FN_NAME, producer);
    let res = create_lt(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn gt_fn(producer: &dyn LLVMIRProducer) {
    let (lhs, rhs) = fr_binary_op_bigint_to_bool!(FR_GT_FN_NAME, producer);
    let res = create_gt(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn le_fn(producer: &dyn LLVMIRProducer) {
    let (lhs, rhs) = fr_binary_op_bigint_to_bool!(FR_LE_FN_NAME, producer);
    let res = create_le(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn ge_fn(producer: &dyn LLVMIRProducer) {
    let (lhs, rhs) = fr_binary_op_bigint_to_bool!(FR_GE_FN_NAME, producer);
    let res = create_ge(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn neg_fn(producer: &dyn LLVMIRProducer) {
    let arg = fr_unary_op!(FR_NEG_FN_NAME, producer, bigint_type(producer));
    let neg = create_neg(producer, arg.into_int_value());
    create_return(producer, neg.into_int_value());
}

fn shl_fn(producer: &dyn LLVMIRProducer) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_SHL_FN_NAME, producer);
    let res = create_shl(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn shr_fn(producer: &dyn LLVMIRProducer) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_SHR_FN_NAME, producer);
    let res = create_shr(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn bit_and_fn(producer: &dyn LLVMIRProducer) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_BITAND_FN_NAME, producer);
    let res = create_bit_and(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn bit_or_fn(producer: &dyn LLVMIRProducer) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_BITOR_FN_NAME, producer);
    let res = create_bit_or(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn bit_xor_fn(producer: &dyn LLVMIRProducer) {
    let (lhs, rhs) = fr_binary_op_bigint!(FR_BITXOR_FN_NAME, producer);
    let res = create_bit_xor(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn bit_flip_fn(producer: &dyn LLVMIRProducer) {
    let ty = bigint_type(producer);
    let arg = fr_unary_op!(FR_BITFLIP_FN_NAME, producer, ty);
    // ~x <=> xor(x, 0xFF...)
    let res = create_bit_xor(producer, arg.into_int_value(), ty.const_all_ones());
    create_return(producer, res.into_int_value());
}

fn logic_and_fn(producer: &dyn LLVMIRProducer) {
    let (lhs, rhs) = fr_binary_op_bool!(FR_LAND_FN_NAME, producer);
    let res = create_logic_and(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn logic_or_fn(producer: &dyn LLVMIRProducer) {
    let (lhs, rhs) = fr_binary_op_bool!(FR_LOR_FN_NAME, producer);
    let res = create_logic_or(producer, lhs.into_int_value(), rhs.into_int_value());
    create_return(producer, res.into_int_value());
}

fn logic_not_fn(producer: &dyn LLVMIRProducer) {
    let arg = fr_unary_op!(FR_LNOT_FN_NAME, producer, bool_type(producer));
    let res = create_logic_not(producer, arg.into_int_value());
    create_return(producer, res.into_int_value());
}

fn addr_cast_fn(producer: &dyn LLVMIRProducer) {
    let (arg, _) = fr_unary_op_base!(
        FR_ADDR_CAST_FN_NAME,
        producer,
        bigint_type(producer),
        i32_type(producer)
    );
    let res = create_cast_to_addr(producer, arg.into_int_value());
    create_return(producer, res.into_int_value());
}

fn index_arr_ptr_fn(producer: &dyn LLVMIRProducer) {
    let bigint_ty = bigint_type(producer);
    let ret_ty = bigint_ty.ptr_type(Default::default());
    let val_ty = bigint_ty.array_type(0).ptr_type(Default::default());
    let func = create_function(
        producer,
        &None,
        0,
        "",
        FR_INDEX_ARR_PTR,
        ret_ty.fn_type(&[val_ty.into(), bigint_ty.into()], false),
    );
    add_inline_attribute(producer, func);

    let arr = func.get_nth_param(0).unwrap();
    let idx = func.get_nth_param(1).unwrap();
    arr.set_name("arr");
    idx.set_name("idx");

    let main = create_bb(producer, func, FR_INDEX_ARR_PTR);
    producer.llvm().set_current_bb(main);
    create_return(
        producer,
        create_gep(producer, arr.into_pointer_value(), &[zero(producer), idx.into_int_value()]),
    );
}

fn identity_arr_ptr_fn(producer: &dyn LLVMIRProducer) {
    let ty = bigint_type(producer).array_type(0).ptr_type(Default::default());
    let (res, func) = fr_unary_op_base!(FR_IDENTITY_ARR_PTR, producer, ty, ty);
    add_inline_attribute(producer, func);
    // Just return the parameter
    create_return(producer, res);
}

fn ptr_cast_i32_i256_fn(producer: &dyn LLVMIRProducer) {
    let ty_32 = i32_type(producer).ptr_type(Default::default());
    let ty_256 = bigint_type(producer).ptr_type(Default::default());
    let (res, func) = fr_unary_op_base!(FR_PTR_CAST_I32_I256, producer, ty_32, ty_256);
    add_inline_attribute(producer, func);
    // Cast the i32* to i256* and return
    create_return(producer, create_pointer_cast(producer, res.into_pointer_value(), ty_256));
}

fn ptr_cast_i256_i32_fn(producer: &dyn LLVMIRProducer) {
    let ty_32 = i32_type(producer).ptr_type(Default::default());
    let ty_256 = bigint_type(producer).ptr_type(Default::default());
    let (res, func) = fr_unary_op_base!(FR_PTR_CAST_I256_I32, producer, ty_256, ty_32);
    add_inline_attribute(producer, func);
    // Cast the i256* to i32* and return
    create_return(producer, create_pointer_cast(producer, res.into_pointer_value(), ty_32));
}

fn null_i256_arr_ptr_fn(producer: &dyn LLVMIRProducer) {
    let base_ty = bigint_type(producer).array_type(0).ptr_type(Default::default());
    let func = fr_nullary_op!(FR_NULL_I256_ARR_PTR, producer, base_ty);
    add_inline_attribute(producer, func);
    // Just return null value for the proper pointer type
    create_return(producer, base_ty.const_null());
}

fn null_i256_ptr_fn(producer: &dyn LLVMIRProducer) {
    let base_ty = bigint_type(producer).ptr_type(Default::default());
    let func = fr_nullary_op!(FR_NULL_I256_PTR, producer, base_ty);
    add_inline_attribute(producer, func);
    // Just return null value for the proper pointer type
    create_return(producer, base_ty.const_null());
}

pub fn load_fr(producer: &dyn LLVMIRProducer) {
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
    index_arr_ptr_fn(producer);
    identity_arr_ptr_fn(producer);
    ptr_cast_i32_i256_fn(producer);
    ptr_cast_i256_i32_fn(producer);
    null_i256_arr_ptr_fn(producer);
    null_i256_ptr_fn(producer);
    pow_fn(producer); //uses functions generated by mul_fn & lt_fn
}
