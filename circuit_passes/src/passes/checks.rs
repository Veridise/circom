use std::collections::{HashMap, HashSet};
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::TemplateCode;
use compiler::compiler_interface::Circuit;
use compiler::intermediate_representation::{
    BucketId, Instruction, InstructionList, InstructionPointer,
};
use compiler::intermediate_representation::ir_interface::{
    AddressType, LocationRule, LogBucketArg, ReturnType,
};

type Ids<'a, 'b> = &'a mut HashMap<BucketId, &'b InstructionPointer>;

fn assert_unique_ids_in_location_rule<'a, 'b: 'a>(location: &'b LocationRule, ids: Ids<'a, 'b>) {
    match location {
        LocationRule::Indexed { location, .. } => assert_unique_ids_in_instruction(location, ids),
        LocationRule::Mapped { indexes, .. } => assert_unique_ids_in_instruction_list(indexes, ids),
    }
}

fn assert_unique_ids_in_address_type<'a, 'b: 'a>(address: &'b AddressType, ids: Ids<'a, 'b>) {
    match address {
        AddressType::Variable => {}
        AddressType::Signal => {}
        AddressType::SubcmpSignal { cmp_address, .. } => {
            assert_unique_ids_in_instruction(cmp_address, ids)
        }
    }
}

fn assert_unique_ids_in_return_type<'a, 'b: 'a>(return_type: &'b ReturnType, ids: Ids<'a, 'b>) {
    if let ReturnType::Final(data) = return_type {
        assert_unique_ids_in_location_rule(&data.dest, ids);
        assert_unique_ids_in_address_type(&data.dest_address_type, ids);
    }
}

fn assert_unique_ids_in_log_args<'a, 'b: 'a>(log_args: &'b LogBucketArg, ids: Ids<'a, 'b>) {
    if let LogBucketArg::LogExp(e) = log_args {
        assert_unique_ids_in_instruction(e, ids);
    }
}

macro_rules! check_and_handle_ids {
    ($inst: expr, $bucket: expr, $ids: expr) => {{
        assert!(
            !$ids.contains_key(&$bucket.id),
            "Same ID for [{0:p}]{0:?} and [{1:p}]{1:?}",
            *$inst,
            **$ids.get(&$bucket.id).unwrap()
        );
        $ids.insert($bucket.id, $inst);
    }};
}

fn assert_unique_ids_in_instruction<'a, 'b: 'a>(inst: &'b InstructionPointer, ids: Ids<'a, 'b>) {
    match inst.as_ref() {
        Instruction::Value(b) => {
            check_and_handle_ids!(inst, b, ids);
        }
        Instruction::Load(b) => {
            check_and_handle_ids!(inst, b, ids);
            assert_unique_ids_in_location_rule(&b.src, ids);
            assert_unique_ids_in_address_type(&b.address_type, ids);
        }
        Instruction::Store(b) => {
            check_and_handle_ids!(inst, b, ids);
            assert_unique_ids_in_address_type(&b.dest_address_type, ids);
            assert_unique_ids_in_location_rule(&b.dest, ids);
            assert_unique_ids_in_instruction(&b.src, ids);
        }
        Instruction::Compute(b) => {
            check_and_handle_ids!(inst, b, ids);
            assert_unique_ids_in_instruction_list(&b.stack, ids);
        }
        Instruction::Call(b) => {
            check_and_handle_ids!(inst, b, ids);
            assert_unique_ids_in_return_type(&b.return_info, ids)
        }
        Instruction::Branch(b) => {
            check_and_handle_ids!(inst, b, ids);
            assert_unique_ids_in_instruction(&b.cond, ids);
            assert_unique_ids_in_instruction_list(&b.if_branch, ids);
            assert_unique_ids_in_instruction_list(&b.else_branch, ids);
        }
        Instruction::Return(b) => {
            check_and_handle_ids!(inst, b, ids);
            assert_unique_ids_in_instruction(&b.value, ids);
        }
        Instruction::Assert(b) => {
            check_and_handle_ids!(inst, b, ids);
            assert_unique_ids_in_instruction(&b.evaluate, ids);
        }
        Instruction::Log(b) => {
            check_and_handle_ids!(inst, b, ids);
            for arg in &b.argsprint {
                assert_unique_ids_in_log_args(arg, ids);
            }
        }
        Instruction::Loop(b) => {
            check_and_handle_ids!(inst, b, ids);
            assert_unique_ids_in_instruction(&b.continue_condition, ids);
            assert_unique_ids_in_instruction_list(&b.body, ids);
        }
        Instruction::CreateCmp(b) => {
            check_and_handle_ids!(inst, b, ids);
            assert_unique_ids_in_instruction(&b.sub_cmp_id, ids);
        }
        Instruction::Constraint(b) => {
            assert_unique_ids_in_instruction(b.unwrap(), ids);
        }
        Instruction::Block(b) => {
            check_and_handle_ids!(inst, b, ids);
            assert_unique_ids_in_instruction_list(&b.body, ids);
        }
        Instruction::Nop(b) => {
            check_and_handle_ids!(inst, b, ids);
        }
    }
}

fn assert_unique_ids_in_instruction_list<'a, 'b: 'a>(
    instructions: &'b InstructionList,
    ids: Ids<'a, 'b>,
) {
    for inst in instructions {
        assert_unique_ids_in_instruction(inst, ids);
    }
}

fn assert_unique_ids_in_template<'a, 'b: 'a>(template: &'b TemplateCode, ids: Ids<'a, 'b>) {
    assert_unique_ids_in_instruction_list(&template.body, ids);
}

fn assert_unique_ids_in_function<'a, 'b: 'a>(function: &'b FunctionCode, ids: Ids<'a, 'b>) {
    assert_unique_ids_in_instruction_list(&function.body, ids);
}

/// Ensures that the ids of the buckets in a circuit are all unique
/// Panics if not as duplicate ids are usually indicative of a bug in a pass
pub fn assert_unique_ids_in_circuit(circuit: &Circuit) {
    let mut visited: HashMap<BucketId, &InstructionPointer> = HashMap::new();
    for template in &circuit.templates {
        assert_unique_ids_in_template(template, &mut visited);
    }
    for function in &circuit.functions {
        assert_unique_ids_in_function(function, &mut visited);
    }
}

/// Return true iff all elements returned by the given Iterator are equal.
pub fn all_same<T>(data: T) -> bool
where
    T: Iterator,
    T::Item: PartialEq,
{
    data.fold((true, None), {
        |acc, elem| {
            if acc.1.is_some() {
                (acc.0 && (acc.1.unwrap() == elem), Some(elem))
            } else {
                (true, Some(elem))
            }
        }
    })
    .0
}

/// Return true iff the first argument contains all elements in the second argument.
pub fn contains_all<T, U>(collection: T, to_find: U) -> bool
where
    T: IntoIterator,
    T::Item: Eq + std::hash::Hash,
    U: IntoIterator<Item = T::Item>,
{
    let to_find_set: HashSet<_> = to_find.into_iter().collect();
    to_find_set.is_subset(&collection.into_iter().collect())
}

/// Return true iff the two arguments contain exactly the same elements.
pub fn contains_same<T, U>(lhs: T, rhs: U) -> bool
where
    T: IntoIterator,
    T::Item: Eq + std::hash::Hash,
    U: IntoIterator<Item = T::Item>,
{
    let lhs_set: HashSet<_> = lhs.into_iter().collect();
    let rhs_set: HashSet<_> = rhs.into_iter().collect();
    lhs_set == rhs_set
}
