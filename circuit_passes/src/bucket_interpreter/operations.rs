use circom_algebra::num_bigint::BigInt;
use compiler::intermediate_representation::ir_interface::{ComputeBucket, OperatorType};
use crate::bucket_interpreter::value;
use crate::bucket_interpreter::value::{resolve_operation, Value};
use crate::bucket_interpreter::value::Value::KnownU32;

pub fn compute_operation(bucket: &ComputeBucket, stack: &Vec<Value>, p: &BigInt) -> Option<Value> {
    let computed_value = Some(match bucket.op {
        OperatorType::Mul => resolve_operation(value::mul_value, p, &stack),
        OperatorType::Div => resolve_operation(value::div_value, p, &stack),
        OperatorType::Add => resolve_operation(value::add_value, p, &stack),
        OperatorType::Sub => resolve_operation(value::sub_value, p, &stack),
        OperatorType::Pow => resolve_operation(value::pow_value, p, &stack),
        OperatorType::IntDiv => resolve_operation(value::int_div_value, p, &stack),
        OperatorType::Mod => resolve_operation(value::mod_value, p, &stack),
        OperatorType::ShiftL => resolve_operation(value::shift_l_value, p, &stack),
        OperatorType::ShiftR => resolve_operation(value::shift_r_value, p, &stack),
        OperatorType::LesserEq => value::lesser_eq(&stack[0], &stack[1], p),
        OperatorType::GreaterEq => value::greater_eq(&stack[0], &stack[1], p),
        OperatorType::Lesser => value::lesser(&stack[0], &stack[1], p),
        OperatorType::Greater => value::greater(&stack[0], &stack[1], p),
        OperatorType::Eq(1) => value::eq1(&stack[0], &stack[1], p),
        OperatorType::Eq(_) => todo!(),
        OperatorType::NotEq => value::not_eq(&stack[0], &stack[1], p),
        OperatorType::BoolOr => resolve_operation(value::bool_or_value, p, &stack),
        OperatorType::BoolAnd => resolve_operation(value::bool_and_value, p, &stack),
        OperatorType::BitOr => resolve_operation(value::bit_or_value, p, &stack),
        OperatorType::BitAnd => resolve_operation(value::bit_and_value, p, &stack),
        OperatorType::BitXor => resolve_operation(value::bit_xor_value, p, &stack),
        OperatorType::PrefixSub => {
            value::prefix_sub(&stack[0], p)
        }
        OperatorType::BoolNot => KnownU32((!stack[0].to_bool(p)).into()),
        OperatorType::Complement => {
            value::complement(&stack[0], p)
        }
        OperatorType::ToAddress => value::to_address(&stack[0]),
        OperatorType::MulAddress => stack.iter().fold(KnownU32(1), value::mul_address),
        OperatorType::AddAddress => stack.iter().fold(KnownU32(0), value::add_address),
    });
    computed_value
}
