use std::fmt::{Debug, Display, Formatter};
use compiler::intermediate_representation::ir_interface::{ValueBucket, ValueType};
use compiler::num_bigint::BigInt;
use compiler::num_traits::ToPrimitive;
use compiler::intermediate_representation::new_id;
use circom_algebra::modular_arithmetic;
use program_structure::error_code::ReportCode;
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::value::Value::{KnownBigInt, KnownU32, Unknown};
use super::error::{BadInterp, self};
use super::into_result;

/// Poor man's lattice that gives up the moment values are not equal
/// It's a join semi lattice with a top (Unknown)
/// Not a complete lattice because there is no bottom
#[derive(Clone, Eq, PartialEq, Ord, PartialOrd)]
pub enum Value {
    Unknown,
    KnownU32(usize),
    KnownBigInt(BigInt),
}

impl Display for Value {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            Unknown => write!(f, "Unknown"),
            KnownU32(n) => write!(f, "{}", n),
            KnownBigInt(n) => write!(f, "{}", n),
        }
    }
}

impl Debug for Value {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            Unknown => write!(f, "Unknown"),
            KnownU32(n) => write!(f, "{}", n),
            KnownBigInt(n) => write!(f, "BigInt({})", n),
        }
    }
}

impl Value {
    pub fn get_u32(&self) -> Result<usize, BadInterp> {
        match self {
            KnownU32(i) => Ok(*i),
            _ => error::new_compute_err_result(format!("Value is not a KnownU32! {}", self)),
        }
    }

    pub fn get_bigint_as_string(&self) -> Result<String, BadInterp> {
        match self {
            KnownBigInt(b) => Ok(b.to_string()),
            _ => error::new_compute_err_result(format!("Value is not a KnownBigInt! {}", self)),
        }
    }

    pub fn is_unknown(&self) -> bool {
        match self {
            Unknown => true,
            _ => false,
        }
    }

    pub fn is_known(&self) -> bool {
        !self.is_unknown()
    }

    pub fn is_u32(&self) -> bool {
        match self {
            KnownU32(_) => true,
            _ => false,
        }
    }

    pub fn is_bigint(&self) -> bool {
        match self {
            KnownBigInt(_) => true,
            _ => false,
        }
    }

    pub fn to_bool(&self, field: &BigInt) -> Result<bool, BadInterp> {
        match self {
            KnownU32(0) => Ok(false),
            KnownU32(1) => Ok(true),
            KnownBigInt(n) => Ok(modular_arithmetic::as_bool(n, field)),
            _ => error::new_compute_err_result(format!("Can't convert {} into a boolean!", self)),
        }
    }

    pub fn to_value_bucket(&self, mem: &PassMemory) -> Result<ValueBucket, BadInterp> {
        match self {
            Unknown => {
                error::new_compute_err_result("Can't create a ValueBucket from an Unknown value!")
            }
            KnownU32(n) => Ok(ValueBucket {
                id: new_id(),
                source_file_id: None,
                line: 0,
                message_id: 0,
                parse_as: ValueType::U32,
                op_aux_no: 0,
                value: *n,
            }),
            KnownBigInt(n) => Ok(ValueBucket {
                id: new_id(),
                source_file_id: None,
                line: 0,
                message_id: 0,
                parse_as: ValueType::BigInt,
                op_aux_no: 0,
                value: mem.add_field_constant(n.to_string()),
            }),
        }
    }

    #[inline]
    pub fn into_u32_result<S: std::fmt::Display>(
        v: Option<Value>,
        label: S,
    ) -> Result<usize, BadInterp> {
        into_result(v, label)?.get_u32()
    }
}

#[inline]
fn wrap_op(
    lhs: &Value,
    rhs: &Value,
    field: &BigInt,
    u32_op: impl Fn(&usize, &usize) -> usize,
    bigint_op: impl Fn(&BigInt, &BigInt, &BigInt) -> BigInt,
) -> Result<Value, BadInterp> {
    match (lhs, rhs) {
        (Unknown, _) => Ok(Unknown),
        (_, Unknown) => Ok(Unknown),
        (KnownU32(lhs), KnownU32(rhs)) => Ok(KnownU32(u32_op(lhs, rhs))),
        (KnownU32(lhs), KnownBigInt(rhs)) => {
            Ok(KnownBigInt(bigint_op(&BigInt::from(*lhs), rhs, field)))
        }
        (KnownBigInt(lhs), KnownBigInt(rhs)) => Ok(KnownBigInt(bigint_op(lhs, rhs, field))),
        (KnownBigInt(lhs), KnownU32(rhs)) => {
            Ok(KnownBigInt(bigint_op(lhs, &BigInt::from(*rhs), field)))
        }
    }
}

// Based on 'constraint_generation::execute::treat_result_with_arithmetic_error'
fn to_interp_err(err: modular_arithmetic::ArithmeticError) -> BadInterp {
    match err {
        modular_arithmetic::ArithmeticError::DivisionByZero => {
            BadInterp::error("Division by zero".to_string(), ReportCode::RuntimeError)
        }
        modular_arithmetic::ArithmeticError::BitOverFlowInShift => {
            BadInterp::error("Shifting caused bit overflow".to_string(), ReportCode::RuntimeError)
        }
    }
}

#[inline]
fn wrap_op_result(
    lhs: &Value,
    rhs: &Value,
    field: &BigInt,
    u32_op: impl Fn(&usize, &usize) -> usize,
    bigint_op: impl Fn(&BigInt, &BigInt, &BigInt) -> Result<BigInt, modular_arithmetic::ArithmeticError>,
) -> Result<Value, BadInterp> {
    match (lhs, rhs) {
        (Unknown, _) => Ok(Unknown),
        (_, Unknown) => Ok(Unknown),
        (KnownU32(lhs), KnownU32(rhs)) => Ok(KnownU32(u32_op(lhs, rhs))),
        (KnownU32(lhs), KnownBigInt(rhs)) => {
            Ok(KnownBigInt(bigint_op(&BigInt::from(*lhs), rhs, field).map_err(to_interp_err)?))
        }
        (KnownBigInt(lhs), KnownBigInt(rhs)) => {
            Ok(KnownBigInt(bigint_op(lhs, rhs, field).map_err(to_interp_err)?))
        }
        (KnownBigInt(lhs), KnownU32(rhs)) => {
            Ok(KnownBigInt(bigint_op(lhs, &BigInt::from(*rhs), field).map_err(to_interp_err)?))
        }
    }
}

pub fn add_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| x + y, modular_arithmetic::add)
}

pub fn sub_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| x - y, modular_arithmetic::sub)
}

pub fn mul_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| x * y, modular_arithmetic::mul)
}

pub fn div_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op_result(lhs, rhs, field, |x, y| x / y, modular_arithmetic::div)
}

pub fn pow_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| x.pow(*y as u32), modular_arithmetic::pow)
}

pub fn int_div_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op_result(lhs, rhs, field, |x, y| x / y, modular_arithmetic::idiv)
}

pub fn mod_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op_result(lhs, rhs, field, |x, y| x % y, modular_arithmetic::mod_op)
}

pub fn shift_l_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op_result(lhs, rhs, field, |x, y| x << y, modular_arithmetic::shift_l)
}

pub fn shift_r_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op_result(lhs, rhs, field, |x, y| x >> y, modular_arithmetic::shift_r)
}

pub fn lesser_eq(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| (x <= y).into(), modular_arithmetic::lesser_eq)
}

pub fn greater_eq(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| (x >= y).into(), modular_arithmetic::greater_eq)
}

pub fn lesser(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| (x < y).into(), modular_arithmetic::lesser)
}

pub fn greater(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| (x > y).into(), modular_arithmetic::greater)
}

pub fn eq1(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| (x == y).into(), modular_arithmetic::eq)
}

pub fn not_eq(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| (x != y).into(), modular_arithmetic::not_eq)
}

pub fn bool_or_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| (*x != 0 || *y != 0).into(), modular_arithmetic::bool_or)
}

pub fn bool_and_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| (*x != 0 && *y != 0).into(), modular_arithmetic::bool_and)
}

pub fn bit_or_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| x | y, modular_arithmetic::bit_or)
}

pub fn bit_and_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| x & y, modular_arithmetic::bit_and)
}

pub fn bit_xor_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| x ^ y, modular_arithmetic::bit_xor)
}

pub fn prefix_sub(v: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    match v {
        Unknown => Ok(Unknown),
        KnownU32(_n) => {
            error::new_compute_err_result("Can't do negation given an unsigned integer!")
        }
        KnownBigInt(n) => Ok(KnownBigInt(modular_arithmetic::prefix_sub(n, field))),
    }
}

pub fn complement(v: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    match v {
        Unknown => Ok(Unknown),
        KnownU32(n) => Ok(KnownU32(!(*n))),
        KnownBigInt(n) => Ok(KnownBigInt(modular_arithmetic::complement_256(n, field))),
    }
}

pub fn to_address(v: &Value) -> Result<Value, BadInterp> {
    match v {
        Unknown => error::new_compute_err_result("Can't convert an unknown value into an address!"),
        KnownU32(size) => Ok(KnownU32(*size)),
        KnownBigInt(b) => match b.to_u64() {
            Some(x) => Ok(KnownU32(usize::try_from(x).map_err(|_| {
                error::new_compute_err(format!("Can't convert {} to a usize type!", b))
            })?)),
            None => error::new_compute_err_result(format!("Can't convert {} to a usize type!", b)),
        },
    }
}

pub fn mul_address(lhs: Value, rhs: &Value) -> Result<Value, BadInterp> {
    match (lhs, rhs) {
        (KnownU32(lhs), KnownU32(rhs)) => Ok(KnownU32(lhs * rhs)),
        _ => error::new_compute_err_result(
            "Can't do address multiplication given unknown values or big integers!",
        ),
    }
}

pub fn add_address(lhs: Value, rhs: &Value) -> Result<Value, BadInterp> {
    match (lhs, rhs) {
        (KnownU32(lhs), KnownU32(rhs)) => Ok(KnownU32(lhs + rhs)),
        _ => error::new_compute_err_result(
            "Can't do address addition given unknown values or big integers!",
        ),
    }
}

impl Default for Value {
    fn default() -> Self {
        Unknown
    }
}

impl Default for &Value {
    fn default() -> Self {
        &Unknown
    }
}

pub fn resolve_operation(
    op: fn(&Value, &Value, &BigInt) -> Result<Value, BadInterp>,
    p: &BigInt,
    stack: &[Value],
) -> Result<Value, BadInterp> {
    assert!(stack.len() > 0);
    let mut acc = stack[0].clone();
    for i in &stack[1..] {
        acc = op(&acc, i, p)?;
    }
    Ok(acc)
}
