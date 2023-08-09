use std::collections::HashSet;
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::TemplateCode;
use compiler::compiler_interface::Circuit;
use compiler::intermediate_representation::{BucketId, Instruction, InstructionList, InstructionPointer};
use compiler::intermediate_representation::ir_interface::{AddressType, LocationRule, LogBucketArg, ReturnType};

type Ids<'a> = &'a mut HashSet<BucketId>;

fn assert_unique_ids_in_location_rule(location: &LocationRule, ids: Ids) {
    match location {
        LocationRule::Indexed { location, .. } => assert_unique_ids_in_instruction(location, ids),
        LocationRule::Mapped { indexes, .. } => assert_unique_ids_in_instruction_list(indexes, ids)
    }
}

fn assert_unique_ids_in_address_type(address: &AddressType, ids: Ids) {
    match address {
        AddressType::Variable => {}
        AddressType::Signal => {}
        AddressType::SubcmpSignal { cmp_address, .. } => assert_unique_ids_in_instruction(cmp_address, ids)
    }
}

fn assert_unique_ids_in_return_type(return_type: &ReturnType, ids: Ids) {
    if let ReturnType::Final(data) = return_type {
        assert_unique_ids_in_location_rule(&data.dest, ids);
        assert_unique_ids_in_address_type(&data.dest_address_type, ids);
    }
}

fn assert_unique_ids_in_log_args(log_args: &LogBucketArg, ids: Ids) {
    if let LogBucketArg::LogExp(e) = log_args {
        assert_unique_ids_in_instruction(e, ids);
    }
}

fn assert_unique_ids_in_instruction(inst: &InstructionPointer, ids: Ids) {
    match inst.as_ref() {
        Instruction::Value(b) => {
            assert!(!ids.contains(&b.id));
            ids.insert(b.id);
        }
        Instruction::Load(b) => {
            assert!(!ids.contains(&b.id));
            ids.insert(b.id);
            assert_unique_ids_in_location_rule(&b.src, ids);
            assert_unique_ids_in_address_type(&b.address_type, ids);
        }
        Instruction::Store(b) => {
            assert!(!ids.contains(&b.id));
            ids.insert(b.id);
            assert_unique_ids_in_address_type(&b.dest_address_type, ids);
            assert_unique_ids_in_location_rule(&b.dest, ids);
            assert_unique_ids_in_instruction(&b.src, ids);
        }
        Instruction::Compute(b) => {
            assert!(!ids.contains(&b.id));
            ids.insert(b.id);
            assert_unique_ids_in_instruction_list(&b.stack, ids);
        }
        Instruction::Call(b) => {
            assert!(!ids.contains(&b.id));
            ids.insert(b.id);
            assert_unique_ids_in_return_type(&b.return_info, ids)
        }
        Instruction::Branch(b) => {
            assert!(!ids.contains(&b.id));
            ids.insert(b.id);
            assert_unique_ids_in_instruction(&b.cond, ids);
            assert_unique_ids_in_instruction_list(&b.if_branch, ids);
            assert_unique_ids_in_instruction_list(&b.else_branch, ids);
        }
        Instruction::Return(b) => {
            assert!(!ids.contains(&b.id));
            ids.insert(b.id);
            assert_unique_ids_in_instruction(&b.value, ids);
        }
        Instruction::Assert(b) => {
            assert!(!ids.contains(&b.id));
            ids.insert(b.id);
            assert_unique_ids_in_instruction(&b.evaluate, ids);
        }
        Instruction::Log(b) => {
            assert!(!ids.contains(&b.id));
            ids.insert(b.id);
            for arg in &b.argsprint {
                assert_unique_ids_in_log_args(arg, ids);
            }
        }
        Instruction::Loop(b) => {
            assert!(!ids.contains(&b.id));
            ids.insert(b.id);
            assert_unique_ids_in_instruction(&b.continue_condition, ids);
            assert_unique_ids_in_instruction_list(&b.body, ids);
        }
        Instruction::CreateCmp(b) => {
            assert!(!ids.contains(&b.id));
            ids.insert(b.id);
            assert_unique_ids_in_instruction(&b.sub_cmp_id, ids);
        }
        Instruction::Constraint(b) => {
            assert_unique_ids_in_instruction(b.unwrap(), ids);
        }
        Instruction::Block(b) => {
            assert!(!ids.contains(&b.id));
            ids.insert(b.id);
            assert_unique_ids_in_instruction_list(&b.body, ids);
        }
        Instruction::Nop(b) => {
            assert!(!ids.contains(&b.id));
            ids.insert(b.id);
        }
    }
}

fn assert_unique_ids_in_instruction_list(instructions: &InstructionList, ids: Ids) {
    for inst in instructions {
        assert_unique_ids_in_instruction(inst, ids);
    }
}

fn assert_unique_ids_in_template(template: &TemplateCode, ids: Ids) {
    assert_unique_ids_in_instruction_list(&template.body, ids);
}

fn assert_unique_ids_in_function(function: &FunctionCode, ids: Ids) {
    assert_unique_ids_in_instruction_list(&function.body, ids);

}

/// Ensures that the ids of the buckets in a circuit are all unique
/// Panics if not as duplicate ids are usually indicative of a bug in a pass
pub fn assert_unique_ids_in_circuit(circuit: &Circuit) {
    let mut visited: HashSet<BucketId> = Default::default();
    for template in &circuit.templates {
        assert_unique_ids_in_template(template, &mut visited);
    }
    for function in &circuit.functions {
        assert_unique_ids_in_function(function, &mut visited);
    }
}