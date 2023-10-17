use code_producers::c_elements::CProducer;
use code_producers::llvm_elements::types::bigint_type;
use code_producers::llvm_elements::values::create_literal_u32;
use code_producers::llvm_elements::{
    LLVMInstruction, new_constraint, to_basic_metadata_enum, LLVMIRProducer, AnyType, new_constraint_with_name,
};
use code_producers::llvm_elements::instructions::{create_call, create_load, get_instruction_arg, get_index_from_gep};
use code_producers::llvm_elements::stdlib::{CONSTRAINT_VALUE_FN_NAME, CONSTRAINT_VALUES_FN_NAME};
use code_producers::wasm_elements::WASMProducer;
use crate::intermediate_representation::{Instruction, InstructionPointer, SExp, ToSExp, UpdateId};
use crate::intermediate_representation::ir_interface::{Allocate, IntoInstruction, ObtainMeta};
use crate::translating_traits::{WriteC, WriteLLVMIR, WriteWasm};

#[derive(Clone, Debug, Eq, PartialEq, Ord, PartialOrd)]
pub enum ConstraintBucket {
    Substitution(InstructionPointer),
    Equality(InstructionPointer),
}

impl ConstraintBucket {
    pub fn unwrap(&self) -> &InstructionPointer {
        match self {
            ConstraintBucket::Substitution(i) => i,
            ConstraintBucket::Equality(i) => i,
        }
    }

    pub fn unwrap_mut(&mut self) -> &mut InstructionPointer {
        match self {
            ConstraintBucket::Substitution(i) => i,
            ConstraintBucket::Equality(i) => i,
        }
    }
}

impl IntoInstruction for ConstraintBucket {
    fn into_instruction(self) -> Instruction {
        Instruction::Constraint(self)
    }
}

impl Allocate for ConstraintBucket {
    fn allocate(self) -> InstructionPointer {
        InstructionPointer::new(self.into_instruction())
    }
}

impl ObtainMeta for ConstraintBucket {
    fn get_source_file_id(&self) -> &Option<usize> {
        match self {
            ConstraintBucket::Substitution(i) => i,
            ConstraintBucket::Equality(i) => i,
        }
        .get_source_file_id()
    }
    fn get_line(&self) -> usize {
        match self {
            ConstraintBucket::Substitution(i) => i,
            ConstraintBucket::Equality(i) => i,
        }
        .get_line()
    }
    fn get_message_id(&self) -> usize {
        match self {
            ConstraintBucket::Substitution(i) => i,
            ConstraintBucket::Equality(i) => i,
        }
        .get_message_id()
    }
}

impl ToString for ConstraintBucket {
    fn to_string(&self) -> String {
        format!(
            "CONSTRAINT:{}",
            match self {
                ConstraintBucket::Substitution(i) => i,
                ConstraintBucket::Equality(i) => i,
            }
            .to_string()
        )
    }
}

impl ToSExp for ConstraintBucket {
    fn to_sexp(&self) -> SExp {
        SExp::List(vec![SExp::Atom("CONSTRAINT".to_string()), self.unwrap().to_sexp()])
    }
}

impl UpdateId for ConstraintBucket {
    fn update_id(&mut self) {
        self.unwrap_mut().update_id();
    }
}

impl WriteLLVMIR for ConstraintBucket {
    fn produce_llvm_ir<'a, 'b>(
        &self,
        producer: &'b dyn LLVMIRProducer<'a>,
    ) -> Option<LLVMInstruction<'a>> {
        Self::manage_debug_loc_from_curr(producer, self);

        // TODO: Create the constraint call
        let prev = match self {
            ConstraintBucket::Substitution(i) => i,
            ConstraintBucket::Equality(i) => i,
        }
        .produce_llvm_ir(producer)
        .expect("A constrained instruction MUST produce a value!");

        const STORE_SRC_IDX: u32 = 1;
        const STORE_DST_IDX: u32 = 0;
        const ASSERT_IDX: u32 = 0;

        match self {
            ConstraintBucket::Substitution(i) => {
                let size = match i.as_ref() {
                    Instruction::Store(b) => b.context.size,
                    Instruction::Call(b) => {
                        for arg_ty in &b.argument_types {
                            if arg_ty.size > 1 {
                                todo!("not yet handling call arg array logic");
                            }
                            assert_ne!(0, arg_ty.size, "size should be non-zero");
                        }
                        1
                    },
                    _ => unreachable!("Instruction {:#?} should not be used for constraint substitution", i),
                };
                assert_ne!(0, size, "must have non-zero size");
                if size == 1 {
                    let lhs = get_instruction_arg(prev.into_instruction_value(), STORE_DST_IDX);
                    assert_eq!(bigint_type(producer).as_any_type_enum(), lhs.get_type(), "wrong type");
                    let rhs_ptr = get_instruction_arg(prev.into_instruction_value(), STORE_SRC_IDX);
                    let rhs = create_load(producer, rhs_ptr.into_pointer_value());
                    let constr = new_constraint(producer);
                    let call = create_call(
                        producer,
                        CONSTRAINT_VALUES_FN_NAME,
                        &[
                            to_basic_metadata_enum(lhs),
                            to_basic_metadata_enum(rhs),
                            to_basic_metadata_enum(constr),
                        ],
                    );
                    Some(call)
                } else {
                    let lhs_ptr = get_instruction_arg(prev.into_instruction_value(), STORE_DST_IDX).into_pointer_value();
                    assert_eq!(bigint_type(producer).ptr_type(Default::default()), lhs_ptr.get_type(), "wrong type");
                    let rhs_ptr = get_instruction_arg(prev.into_instruction_value(), STORE_SRC_IDX).into_pointer_value();
                    let mut last_call = None;
                    let lhs_base_off = get_index_from_gep(lhs_ptr);
                    let rhs_base_off = get_index_from_gep(rhs_ptr);
                    for i in 0..size {
                        let lhs_gep = producer.template_ctx().get_signal(producer, create_literal_u32(producer, (lhs_base_off + i) as u64));
                        let rhs_gep = producer.template_ctx().get_signal(producer, create_literal_u32(producer, (rhs_base_off + i) as u64));
                        let lhs = create_load(producer, lhs_gep.into_pointer_value());
                        let rhs = create_load(producer, rhs_gep.into_pointer_value());
                        let constr = new_constraint_with_name(producer, format!("constraint_{}", i).as_str());
                        last_call = Some(create_call(
                            producer,
                            CONSTRAINT_VALUES_FN_NAME,
                            &[
                                to_basic_metadata_enum(lhs),
                                to_basic_metadata_enum(rhs),
                                to_basic_metadata_enum(constr),
                            ],
                        ));
                    }

                    last_call
                }

            }
            ConstraintBucket::Equality(_) => {
                let bool = get_instruction_arg(prev.into_instruction_value(), ASSERT_IDX);
                let constr = new_constraint(producer);
                let call = create_call(
                    producer,
                    CONSTRAINT_VALUE_FN_NAME,
                    &[to_basic_metadata_enum(bool), to_basic_metadata_enum(constr)],
                );
                Some(call)
            }
        }
    }
}

impl WriteWasm for ConstraintBucket {
    fn produce_wasm(&self, producer: &WASMProducer) -> Vec<String> {
        match self {
            ConstraintBucket::Substitution(i) => i,
            ConstraintBucket::Equality(i) => i,
        }
        .produce_wasm(producer)
    }
}

impl WriteC for ConstraintBucket {
    fn produce_c(&self, producer: &CProducer, is_parallel: Option<bool>) -> (Vec<String>, String) {
        match self {
            ConstraintBucket::Substitution(i) => i,
            ConstraintBucket::Equality(i) => i,
        }
        .produce_c(producer, is_parallel)
    }
}
