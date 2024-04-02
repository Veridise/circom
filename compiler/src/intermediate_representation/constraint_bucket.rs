use code_producers::c_elements::CProducer;
use code_producers::llvm_elements::{ConstraintKind, LLVMIRProducer, LLVMInstruction};
use code_producers::wasm_elements::WASMProducer;
use super::{BucketId, Instruction, InstructionPointer, SExp, ToSExp, UpdateId};
use super::ir_interface::{Allocate, IntoInstruction, ObtainMeta};
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

    pub fn get_id(&self) -> BucketId {
        self.unwrap().get_id()
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

impl From<&ConstraintBucket> for ConstraintKind {
    fn from(b: &ConstraintBucket) -> Self {
        match b {
            ConstraintBucket::Substitution(_) => ConstraintKind::Substitution,
            ConstraintBucket::Equality(_) => ConstraintKind::Equality,
        }
    }
}

impl WriteLLVMIR for ConstraintBucket {
    fn produce_llvm_ir<'a>(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
    ) -> Option<LLVMInstruction<'a>> {
        Self::manage_debug_loc_from_curr(producer, self);
        producer.body_ctx().set_wrapping_constraint(Some(self.into()));
        let inner = self.unwrap().produce_llvm_ir(producer);
        producer.body_ctx().set_wrapping_constraint(None);
        inner
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
