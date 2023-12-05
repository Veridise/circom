use circom_algebra::num_bigint::BigInt;
use compiler::intermediate_representation::ir_interface::{ComputeBucket, OperatorType};
use crate::bucket_interpreter::{value, new_inconsistency_err};
use crate::bucket_interpreter::value::{resolve_operation, Value};
use crate::bucket_interpreter::value::Value::KnownU32;
use super::error::BadInterp;

pub fn compute_operation(
    bucket: &ComputeBucket,
    stack: &Vec<Value>,
    p: &BigInt,
) -> Result<Option<Value>, BadInterp> {
    match bucket.op {
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
        OperatorType::PrefixSub => value::prefix_sub(&stack[0], p),
        OperatorType::BoolNot => stack[0].to_bool(p).map(|b| KnownU32((!b).into())),
        OperatorType::Complement => value::complement(&stack[0], p),
        OperatorType::ToAddress => value::to_address(&stack[0]),
        OperatorType::MulAddress => stack.iter().try_fold(KnownU32(1), value::mul_address),
        OperatorType::AddAddress => stack.iter().try_fold(KnownU32(0), value::add_address),
    }
    .map(|x| Some(x))
}

pub fn compute_offset(indexes: &Vec<usize>, lengths: &Vec<usize>) -> Result<usize, BadInterp> {
    // Lengths are in order, i.e. arr[x][y] => [x, y], same with indices
    // arr[x][y] is x arrays of length y, laid out sequentially
    assert_eq!(indexes.len(), lengths.len(), "Number of indexes and array lengths must match!");
    let mut total_offset =
        indexes.last().copied().ok_or_else(|| new_inconsistency_err("Missing array indexes!"))?;
    let mut size_multiplier =
        lengths.last().copied().ok_or_else(|| new_inconsistency_err("Missing array lengths!"))?;
    for i in (0..lengths.len() - 1).rev() {
        total_offset += indexes[i] * size_multiplier;
        size_multiplier *= lengths[i];
    }
    Ok(total_offset)
}

#[cfg(test)]
mod test {
    use super::compute_offset;

    fn test_expected_offset_helper(indexes: &Vec<usize>, lengths: &Vec<usize>) -> usize {
        compute_offset(indexes, lengths).map_err(|e| e.get_message().clone()).unwrap()
    }

    #[test]
    fn test_expected_offset() {
        let offset = test_expected_offset_helper(&vec![1, 1], &vec![5, 3]);
        assert_eq!(4, offset);
    }

    #[test]
    fn test_offsets() {
        let lengths = vec![5, 3, 7];
        for i in 0..lengths[0] {
            for j in 0..lengths[1] {
                for k in 0..lengths[2] {
                    let offset = test_expected_offset_helper(&vec![i, j, k], &lengths);
                    assert_eq!((i * 21) + (j * 7) + k, offset, "i={}, j={}, k={}", i, j, k);
                }
            }
        }
    }

    #[test]
    fn test_increments() {
        let lengths = vec![5, 7];
        for i in 0..lengths[0] {
            for j in 0..lengths[1] - 1 {
                let offset = test_expected_offset_helper(&vec![i, j], &lengths);
                let next_offset = test_expected_offset_helper(&vec![i, j + 1], &lengths);
                assert_eq!(offset + 1, next_offset);
            }
        }
    }
}
