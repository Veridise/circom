use std::convert::TryFrom;
use code_producers::c_elements::CProducer;
use code_producers::llvm_elements::types::bigint_type;
use code_producers::llvm_elements::values::{create_literal_u32, zero};
use code_producers::llvm_elements::{
    AnyType, AnyValueEnum, InstructionOpcode, LLVMInstruction, LLVMIRProducer, PointerValue,
    new_constraint, to_basic_metadata_enum, new_constraint_with_name,
};
use code_producers::llvm_elements::instructions::{
    create_call, create_load, get_instruction_arg, get_data_from_gep, create_gep,
};
use code_producers::llvm_elements::stdlib::{CONSTRAINT_VALUE_FN_NAME, CONSTRAINT_VALUES_FN_NAME};
use code_producers::wasm_elements::WASMProducer;
use crate::intermediate_representation::{Instruction, InstructionPointer, SExp, ToSExp, UpdateId};
use crate::intermediate_representation::ir_interface::{Allocate, IntoInstruction, ObtainMeta};
use crate::translating_traits::{WriteC, WriteLLVMIR, WriteWasm};
use super::BucketId;

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

    pub fn get_id(&self) -> BucketId {
        self.unwrap().get_id()
    }

    fn new_offset_gep<'a>(
        producer: &dyn LLVMIRProducer<'a>,
        base_ptr: PointerValue<'a>,
        idxs: &Vec<u64>,
        offset: u64,
    ) -> AnyValueEnum<'a> {
        let indices = match idxs[..] {
            // If there was no 0 index in the original GEP, don't create one for this GEP
            [i] => vec![create_literal_u32(producer, i + offset)],
            // Add initial index 0 if the original GEP had it
            [0, i] => vec![zero(producer), create_literal_u32(producer, i + offset)],
            // No other case should happen
            _ => panic!("Unexpected indexing {:?} on {}", idxs, base_ptr),
        };
        create_load(producer, create_gep(producer, base_ptr, &indices).into_pointer_value())
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
        self.unwrap().get_source_file_id()
    }
    fn get_line(&self) -> usize {
        self.unwrap().get_line()
    }
    fn get_message_id(&self) -> usize {
        self.unwrap().get_message_id()
    }
}

impl ToString for ConstraintBucket {
    fn to_string(&self) -> String {
        format!("CONSTRAINT:{}", self.unwrap().to_string())
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

macro_rules! debug_assert_bigint_type {
    ($producer:ident, $type:expr) => {
        debug_assert_eq!(
            bigint_type($producer).as_any_type_enum(),
            $type,
            "expected bigint value type"
        );
    };
}

impl WriteLLVMIR for ConstraintBucket {
    fn produce_llvm_ir<'a, 'b>(
        &self,
        producer: &'b dyn LLVMIRProducer<'a>,
    ) -> Option<LLVMInstruction<'a>> {
        Self::manage_debug_loc_from_curr(producer, self);

        // Create the constraint call
        let inner = self
            .unwrap()
            .produce_llvm_ir(producer)
            .expect("A constrained instruction MUST produce a value!");
        let inner = inner.into_instruction_value();

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
                    }
                    _ => unreachable!(
                        "Instruction {:#?} should not be used for constraint substitution",
                        i
                    ),
                };
                assert_ne!(0, size, "must have non-zero size");
                if size == 1 {
                    //ASSERT: It's a STORE like: store i256 %1, i256* %2, align 4
                    assert_eq!(inner.get_opcode(), InstructionOpcode::Store);
                    const STORE_VAL_IDX: u32 = 0;
                    const STORE_PTR_IDX: u32 = 1;

                    let stored_val = get_instruction_arg(inner, STORE_VAL_IDX);
                    debug_assert_bigint_type!(producer, stored_val.get_type());
                    let loaded_val = create_load(
                        producer,
                        get_instruction_arg(inner, STORE_PTR_IDX).into_pointer_value(),
                    );
                    debug_assert_bigint_type!(producer, loaded_val.get_type());
                    let constr = new_constraint(producer);
                    let call = create_call(
                        producer,
                        CONSTRAINT_VALUES_FN_NAME,
                        &[
                            to_basic_metadata_enum(stored_val),
                            to_basic_metadata_enum(loaded_val),
                            to_basic_metadata_enum(constr),
                        ],
                    );
                    Some(call)
                } else {
                    //ASSERT: It's a CALL like: @fr_copy_n(i256* %3, i256* %2, i32 2)
                    assert_eq!(inner.get_opcode(), InstructionOpcode::Call);
                    const COPY_SRC_IDX: u32 = 0;
                    const COPY_DST_IDX: u32 = 1;

                    let src_ptr = get_instruction_arg(inner, COPY_SRC_IDX).into_pointer_value();
                    debug_assert_bigint_type!(producer, src_ptr.get_type().get_element_type());
                    let dst_ptr = get_instruction_arg(inner, COPY_DST_IDX).into_pointer_value();
                    debug_assert_bigint_type!(producer, dst_ptr.get_type().get_element_type());
                    //NOTE: These pointers will normally be something like:
                    //      getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
                    //  but within an extracted loop body function they could have only a single index:
                    //      getelementptr i256, i256* %subfix_0, i32 0
                    let (src_ptr, src_idxs) = get_data_from_gep(src_ptr);
                    let (dst_ptr, dst_idxs) = get_data_from_gep(dst_ptr);

                    let mut last_call = None;
                    for i in 0..size {
                        let idx = u64::try_from(i)
                            .expect(format!("failed to convert to u64: {}", i).as_str());
                        let src = Self::new_offset_gep(producer, src_ptr, &src_idxs, idx);
                        let dst = Self::new_offset_gep(producer, dst_ptr, &dst_idxs, idx);
                        let constr = new_constraint_with_name(
                            producer,
                            format!("constraint_{}", i).as_str(),
                        );
                        last_call = Some(create_call(
                            producer,
                            CONSTRAINT_VALUES_FN_NAME,
                            &[
                                to_basic_metadata_enum(src),
                                to_basic_metadata_enum(dst),
                                to_basic_metadata_enum(constr),
                            ],
                        ));
                    }
                    last_call
                }
            }
            ConstraintBucket::Equality(_) => {
                const ASSERT_IDX: u32 = 0;
                let assert = to_basic_metadata_enum(get_instruction_arg(inner, ASSERT_IDX));
                let constr = to_basic_metadata_enum(new_constraint(producer));
                Some(create_call(producer, CONSTRAINT_VALUE_FN_NAME, &[assert, constr]))
            }
        }
    }
}

impl WriteWasm for ConstraintBucket {
    fn produce_wasm(&self, producer: &WASMProducer) -> Vec<String> {
        self.unwrap().produce_wasm(producer)
    }
}

impl WriteC for ConstraintBucket {
    fn produce_c(&self, producer: &CProducer, is_parallel: Option<bool>) -> (Vec<String>, String) {
        self.unwrap().produce_c(producer, is_parallel)
    }
}
