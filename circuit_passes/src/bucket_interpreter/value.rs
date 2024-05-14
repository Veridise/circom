use std::fmt::{Debug, Display, Formatter};
use compiler::intermediate_representation::ir_interface::{ObtainMetaImpl, ValueBucket};
use compiler::num_bigint::BigInt;
use compiler::num_traits::ToPrimitive;
use circom_algebra::modular_arithmetic;
use program_structure::error_code::ReportCode;
use crate::passes::builders::{build_bigint_value_bucket, build_u32_value_bucket};
use super::error::{new_compute_err, new_compute_err_result, BadInterp};
use super::memory::PassMemory;
use super::value::Value::{KnownBigInt, KnownU32, Unknown};

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

impl Value {
    #[inline]
    #[must_use]
    pub fn is_unknown(&self) -> bool {
        matches!(self, Unknown)
    }

    #[inline]
    #[must_use]
    pub fn is_known(&self) -> bool {
        !self.is_unknown()
    }

    #[inline]
    #[must_use]
    pub fn is_u32(&self) -> bool {
        matches!(self, KnownU32(_))
    }

    #[inline]
    #[must_use]
    pub fn is_bigint(&self) -> bool {
        matches!(self, KnownBigInt(_))
    }

    #[must_use]
    pub fn to_u32(&self) -> Result<usize, BadInterp> {
        match self {
            KnownU32(i) => Ok(*i),
            _ => new_compute_err_result(format!("Value is not a KnownU32! {}", self)),
        }
    }

    #[inline]
    #[must_use]
    pub fn as_u32(self) -> Result<usize, BadInterp> {
        self.to_u32()
    }

    #[must_use]
    pub fn to_bigint_string(&self) -> Result<String, BadInterp> {
        match self {
            KnownBigInt(b) => Ok(b.to_string()),
            _ => new_compute_err_result(format!("Value is not a KnownBigInt! {}", self)),
        }
    }

    #[inline]
    #[must_use]
    pub fn as_bigint_string(self) -> Result<String, BadInterp> {
        self.to_bigint_string()
    }

    #[must_use]
    pub fn to_bool(&self, field: &BigInt) -> Result<bool, BadInterp> {
        match self {
            KnownU32(0) => Ok(false),
            KnownU32(1) => Ok(true),
            KnownBigInt(n) => Ok(modular_arithmetic::as_bool(n, field)),
            _ => new_compute_err_result(format!("Can't convert {} into a boolean!", self)),
        }
    }

    #[must_use]
    pub fn to_value_bucket(&self, mem: &PassMemory) -> Result<ValueBucket, BadInterp> {
        match self {
            Unknown => new_compute_err_result("Can't create a ValueBucket from an Unknown value!"),
            KnownU32(n) => Ok(build_u32_value_bucket(&ObtainMetaImpl::default(), *n)),
            KnownBigInt(n) => Ok(build_bigint_value_bucket(&ObtainMetaImpl::default(), mem, n)),
        }
    }

    #[inline]
    #[must_use]
    pub fn into_u32_result<S: std::fmt::Display>(
        v: Option<Value>,
        label: S,
    ) -> Result<usize, BadInterp> {
        super::into_result(v, label)?.as_u32()
    }
}

#[must_use]
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

#[must_use]
// Based on 'constraint_generation::execute::treat_result_with_arithmetic_error'
fn to_interp_err(err: modular_arithmetic::ArithmeticError) -> BadInterp {
    let error_message = match err {
        modular_arithmetic::ArithmeticError::DivisionByZero => "Division by zero",
        modular_arithmetic::ArithmeticError::BitOverFlowInShift => "Shifting caused bit overflow",
    };
    BadInterp::error(error_message.to_string(), ReportCode::RuntimeError)
}

#[must_use]
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

#[inline]
#[must_use]
pub fn add_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| x + y, modular_arithmetic::add)
}

#[inline]
#[must_use]
pub fn sub_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| x - y, modular_arithmetic::sub)
}

#[inline]
#[must_use]
pub fn mul_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| x * y, modular_arithmetic::mul)
}

#[inline]
#[must_use]
pub fn div_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op_result(lhs, rhs, field, |x, y| x / y, modular_arithmetic::div)
}

#[inline]
#[must_use]
pub fn pow_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| x.pow(*y as u32), modular_arithmetic::pow)
}

#[inline]
#[must_use]
pub fn int_div_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op_result(lhs, rhs, field, |x, y| x / y, modular_arithmetic::idiv)
}

#[inline]
#[must_use]
pub fn mod_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op_result(lhs, rhs, field, |x, y| x % y, modular_arithmetic::mod_op)
}

#[inline]
#[must_use]
pub fn shift_l_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op_result(lhs, rhs, field, |x, y| x << y, modular_arithmetic::shift_l)
}

#[inline]
#[must_use]
pub fn shift_r_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op_result(lhs, rhs, field, |x, y| x >> y, modular_arithmetic::shift_r)
}

#[inline]
#[must_use]
pub fn lesser_eq(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| (x <= y).into(), modular_arithmetic::lesser_eq)
}

#[inline]
#[must_use]
pub fn greater_eq(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| (x >= y).into(), modular_arithmetic::greater_eq)
}

#[inline]
#[must_use]
pub fn lesser(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| (x < y).into(), modular_arithmetic::lesser)
}

#[inline]
#[must_use]
pub fn greater(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| (x > y).into(), modular_arithmetic::greater)
}

#[inline]
#[must_use]
pub fn eq1(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| (x == y).into(), modular_arithmetic::eq)
}

#[inline]
#[must_use]
pub fn not_eq(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| (x != y).into(), modular_arithmetic::not_eq)
}

#[inline]
#[must_use]
pub fn bool_or_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| (*x != 0 || *y != 0).into(), modular_arithmetic::bool_or)
}

#[inline]
#[must_use]
pub fn bool_and_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| (*x != 0 && *y != 0).into(), modular_arithmetic::bool_and)
}

#[inline]
#[must_use]
pub fn bit_or_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| x | y, modular_arithmetic::bit_or)
}

#[inline]
#[must_use]
pub fn bit_and_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| x & y, modular_arithmetic::bit_and)
}

#[inline]
#[must_use]
pub fn bit_xor_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    wrap_op(lhs, rhs, field, |x, y| x ^ y, modular_arithmetic::bit_xor)
}

#[must_use]
pub fn prefix_sub(v: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    match v {
        Unknown => Ok(Unknown),
        KnownU32(_n) => new_compute_err_result("Can't do negation given an unsigned integer!"),
        KnownBigInt(n) => Ok(KnownBigInt(modular_arithmetic::prefix_sub(n, field))),
    }
}

#[must_use]
pub fn complement(v: &Value, field: &BigInt) -> Result<Value, BadInterp> {
    match v {
        Unknown => Ok(Unknown),
        KnownU32(n) => Ok(KnownU32(!(*n))),
        KnownBigInt(n) => Ok(KnownBigInt(modular_arithmetic::complement_256(n, field))),
    }
}

#[must_use]
pub fn to_address(v: &Value) -> Result<Value, BadInterp> {
    match v {
        Unknown => new_compute_err_result("Can't convert an unknown value into an address!"),
        KnownU32(size) => Ok(KnownU32(*size)),
        KnownBigInt(b) => {
            match b.to_u64() {
                Some(x) => Ok(KnownU32(usize::try_from(x).map_err(|_| {
                    new_compute_err(format!("Can't convert {} to a usize type!", b))
                })?)),
                None => new_compute_err_result(format!("Can't convert {} to a usize type!", b)),
            }
        }
    }
}

#[must_use]
pub fn mul_address(lhs: Value, rhs: &Value) -> Result<Value, BadInterp> {
    match (lhs, rhs) {
        (KnownU32(lhs), KnownU32(rhs)) => Ok(KnownU32(lhs * rhs)),
        _ => new_compute_err_result(
            "Can't do address multiplication given unknown values or big integers!",
        ),
    }
}

#[must_use]
pub fn add_address(lhs: Value, rhs: &Value) -> Result<Value, BadInterp> {
    match (lhs, rhs) {
        (KnownU32(lhs), KnownU32(rhs)) => Ok(KnownU32(lhs + rhs)),
        _ => new_compute_err_result(
            "Can't do address addition given unknown values or big integers!",
        ),
    }
}

#[must_use]
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
