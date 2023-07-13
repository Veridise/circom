use std::fmt::{Display, Formatter};
use compiler::intermediate_representation::ir_interface::{ValueBucket, ValueType};
use compiler::num_bigint::BigInt;
use compiler::num_traits::{One, ToPrimitive, Zero};
use circom_algebra::modular_arithmetic;
use circom_algebra::modular_arithmetic::ArithmeticError;
use compiler::intermediate_representation::new_id;
use crate::bucket_interpreter::value::Value::{KnownBigInt, KnownU32, Unknown};

pub trait JoinSemiLattice {
    fn join(&self, other: &Self) -> Self;
}

/// Poor man's lattice that gives up the moment values are not equal
/// It's a join semi lattice with a top (Unknown)
/// Not a complete lattice because there is no bottom
#[derive(Clone, Debug, Eq, PartialEq)]
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
            KnownBigInt(n) => write!(f, "BigInt({})", n),
        }
    }
}

impl JoinSemiLattice for Value {
    /// a ⊔ b = a    iff a = b
    /// a ⊔ b = UNK  otherwise
    fn join(&self, other: &Self) -> Self {
        if self == other { self.clone() } else { Unknown }
    }
}

impl Value {
    pub fn get_u32(&self) -> usize {
        match self {
            KnownU32(i) => *i,
            _ => panic!("Can't unwrap a u32 from a non KnownU32 value! {:?}", self),
        }
    }

    pub fn get_bigint_as_string(&self) -> String {
        match self {
            KnownBigInt(b) => b.to_string(),
            _ => panic!("Can't extract a string representation of a non big int"),
        }
    }

    pub fn is_unknown(&self) -> bool {
        match self {
            Unknown => true,
            _ => false,
        }
    }

    pub fn is_bigint(&self) -> bool {
        match self {
            KnownBigInt(_) => true,
            _ => false,
        }
    }

    pub fn to_bool(&self, field: &BigInt) -> bool {
        match self {
            KnownU32(0) => false,
            KnownU32(1) => true,
            KnownBigInt(n) => {
                modular_arithmetic::as_bool(n, field)
            }
            _ => panic!(
                "Attempted to convert a value that cannot be converted to boolean! {:?}",
                self
            ),
        }
    }

    pub fn to_value_bucket(&self, constant_fields: &mut Vec<String>) -> ValueBucket {
        match self {
            Unknown => panic!("Can't create a value bucket from an unknown value!"),
            KnownU32(n) => ValueBucket {
                id: new_id(),
                source_file_id: None,
                line: 0,
                message_id: 0,
                parse_as: ValueType::U32,
                op_aux_no: 0,
                value: *n,
            },
            KnownBigInt(n) => {
                let str_repr = n.to_string();
                let idx = constant_fields.len();
                constant_fields.push(str_repr);
                ValueBucket {
                    id: new_id(),
                    source_file_id: None,
                    line: 0,
                    message_id: 0,
                    parse_as: ValueType::BigInt,
                    op_aux_no: 0,
                    value: idx,
                }
            }
        }
    }
}

#[inline]
fn wrap_op(
    lhs: &Value,
    rhs: &Value,
    field: &BigInt,
    u32_op: impl Fn(&usize, &usize) -> usize,
    bigint_op: impl Fn(&BigInt, &BigInt, &BigInt) -> BigInt
) -> Value {
    match (lhs, rhs) {
        (Unknown, _) => Unknown,
        (_, Unknown) => Unknown,
        (KnownU32(lhs), KnownU32(rhs)) => KnownU32(u32_op(lhs, rhs)),
        (KnownU32(lhs), KnownBigInt(rhs)) => KnownBigInt(bigint_op(&BigInt::from(*lhs), rhs, field)),
        (KnownBigInt(lhs), KnownBigInt(rhs)) => KnownBigInt(bigint_op(lhs, rhs, field)),
        (KnownBigInt(lhs), KnownU32(rhs)) => KnownBigInt(bigint_op(lhs, &BigInt::from(*rhs), field)),
    }
}

#[inline]
fn wrap_op_result(
    lhs: &Value,
    rhs: &Value,
    field: &BigInt,
    u32_op: impl Fn(&usize, &usize) -> usize,
    bigint_op: impl Fn(&BigInt, &BigInt, &BigInt) -> Result<BigInt, ArithmeticError>
) -> Value {
    match (lhs, rhs) {
        (Unknown, _) => Unknown,
        (_, Unknown) => Unknown,
        (KnownU32(lhs), KnownU32(rhs)) => KnownU32(u32_op(lhs, rhs)),
        (KnownU32(lhs), KnownBigInt(rhs)) => KnownBigInt(bigint_op(&BigInt::from(*lhs), rhs, field).ok().unwrap()),
        (KnownBigInt(lhs), KnownBigInt(rhs)) => KnownBigInt(bigint_op(lhs, rhs, field).ok().unwrap()),
        (KnownBigInt(lhs), KnownU32(rhs)) => KnownBigInt(bigint_op(lhs, &BigInt::from(*rhs), field).ok().unwrap()),
    }
}

pub fn add_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Value {
    wrap_op(lhs, rhs, field, |x, y| x + y, modular_arithmetic::add)
}

pub fn sub_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Value {
    wrap_op(lhs, rhs, field, |x, y| x - y, modular_arithmetic::sub)
}

pub fn mul_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Value {
    wrap_op(lhs, rhs, field, |x, y| x * y, modular_arithmetic::mul)

}

pub fn div_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Value {
    wrap_op_result(lhs, rhs, field, |x, y| x / y, modular_arithmetic::div)
}

fn fr_pow(lhs: &BigInt, rhs: &BigInt) -> BigInt {
    let abv: BigInt = if rhs < &BigInt::from(0) { -rhs.clone() } else { rhs.clone() };
    let mut res = BigInt::from(1);
    let mut i = BigInt::from(0);
    while i < abv {
        res *= lhs;
        i += 1
    }
    if rhs < &BigInt::from(0) {
        res = 1 / res;
    }
    res
}

pub fn pow_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Value {
    wrap_op(lhs, rhs, field, |x, y| x.pow(*y as u32), modular_arithmetic::pow)
}

pub fn int_div_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Value {
    wrap_op_result(lhs, rhs, field, |x, y| x / y, modular_arithmetic::idiv)
}

pub fn mod_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Value {
    wrap_op_result(lhs, rhs, field, |x, y| x % y, modular_arithmetic::mod_op)
}

pub fn shift_l_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Value {
    wrap_op_result(lhs, rhs, field, |x, y| x << y, modular_arithmetic::shift_l)
}

pub fn shift_r_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Value {
    wrap_op_result(lhs, rhs, field, |x, y| x >> y, modular_arithmetic::shift_r)
}

pub fn lesser_eq(lhs: &Value, rhs: &Value, field: &BigInt) -> Value {
    wrap_op(lhs, rhs, field, |x, y| (x <= y).into(), modular_arithmetic::lesser_eq)
}

pub fn greater_eq(lhs: &Value, rhs: &Value, field: &BigInt) -> Value {
    wrap_op(lhs, rhs, field, |x, y| (x >= y).into(), modular_arithmetic::greater_eq)
}

pub fn lesser(lhs: &Value, rhs: &Value, field: &BigInt) -> Value {
    wrap_op(lhs, rhs, field, |x, y| (x < y).into(), modular_arithmetic::lesser)
}

pub fn greater(lhs: &Value, rhs: &Value, field: &BigInt) -> Value {
    wrap_op(lhs, rhs, field, |x, y| (x > y).into(), modular_arithmetic::greater)
}

pub fn eq1(lhs: &Value, rhs: &Value, field: &BigInt) -> Value {
    wrap_op(lhs, rhs, field, |x, y| (x == y).into(), modular_arithmetic::eq)
}

pub fn not_eq(lhs: &Value, rhs: &Value, field: &BigInt) -> Value {
    wrap_op(lhs, rhs, field, |x, y| (x != y).into(), modular_arithmetic::not_eq)
}

pub fn bool_or_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Value {
    wrap_op(lhs, rhs, field, |x, y| (*x != 0 || *y != 0).into(), modular_arithmetic::bool_or)
}

pub fn bool_and_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Value {
    wrap_op(lhs, rhs, field, |x, y| (*x != 0 && *y != 0).into(), modular_arithmetic::bool_and)
}

pub fn bit_or_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Value {
    wrap_op(lhs, rhs, field, |x, y| x | y, modular_arithmetic::bit_or)
}

pub fn bit_and_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Value {
    wrap_op(lhs, rhs, field, |x, y| x & y, modular_arithmetic::bit_and)
}

pub fn bit_xor_value(lhs: &Value, rhs: &Value, field: &BigInt) -> Value {
    wrap_op(lhs, rhs, field, |x, y| x ^ y, modular_arithmetic::bit_xor)
}

pub fn prefix_sub(v: &Value, field: &BigInt) -> Value {
    match v {
        Unknown => Unknown,
        KnownU32(_n) => panic!("We cannot get the negative of an unsigned integer!"),
        KnownBigInt(n) => KnownBigInt(modular_arithmetic::prefix_sub(n, field))
    }
}

pub fn complement(v: &Value, field: &BigInt) -> Value {
    match v {
        Unknown => Unknown,
        KnownU32(n) => KnownU32(!(*n)),
        KnownBigInt(n) => KnownBigInt(modular_arithmetic::complement_256(n, field)),
    }
}

pub fn to_address(v: &Value) -> Value {
    match v {
        Unknown => panic!("Cant convert into an address an unknown value!"),
        KnownBigInt(b) => KnownU32(b.to_u64().expect(format!(
            "Can't convert {} to a usize type", b
        ).as_str()) as usize),
        x => x.clone(),
    }
}

pub fn mul_address(lhs: Value, rhs: &Value) -> Value {
    match (lhs, rhs) {
        (KnownU32(lhs), KnownU32(rhs)) => KnownU32(lhs * rhs),
        _ => panic!("Can't do address multiplication over unknown values or big integers!"),
    }
}

pub fn add_address(lhs: Value, rhs: &Value) -> Value {
    match (lhs, rhs) {
        (KnownU32(lhs), KnownU32(rhs)) => KnownU32(lhs + rhs),
        _ => panic!("Can't do address addition over unknown values or big integers!"),
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

pub fn resolve_operation(op: fn(&Value, &Value, &BigInt) -> Value, p: &BigInt, stack: &[Value]) -> Value {
    assert!(stack.len() > 0);
    let mut acc = stack[0].clone();
    for i in &stack[1..] {
        let result = op(&acc, i, p);
        acc = result.clone();
    }
    acc.clone()
}
