use code_producers::llvm_elements::{LLVMIRProducer, LLVMValue};
use crate::intermediate_representation::{BucketId, Instruction, new_id, SExp, ToSExp, UpdateId};
use crate::intermediate_representation::ir_interface::{IntoInstruction, ObtainMeta};
use crate::translating_traits::WriteLLVMIR;

#[derive(Clone, Debug, Eq, PartialEq, Ord, PartialOrd)]
pub struct NopBucket {
    pub id: BucketId,
}

impl IntoInstruction for NopBucket {
    fn into_instruction(self) -> Instruction {
        Instruction::Nop(self)
    }
}

impl ObtainMeta for NopBucket {
    fn get_source_file_id(&self) -> &Option<usize> {
        &None
    }
    fn get_line(&self) -> usize {
        0
    }
    fn get_message_id(&self) -> usize {
        0
    }
}

impl ToString for NopBucket {
    fn to_string(&self) -> String {
        "NOP".to_string()
    }
}

impl ToSExp for NopBucket {
    fn to_sexp(&self) -> SExp {
        SExp::list([SExp::atom("NOP"), SExp::key_val("id", SExp::atom(self.id))])
    }
}

impl UpdateId for NopBucket {
    fn update_id(&mut self) {
        self.id = new_id();
    }
}

impl WriteLLVMIR for NopBucket {
    fn produce_llvm_ir<'a>(&self, _: &dyn LLVMIRProducer<'a>) -> Option<LLVMValue<'a>> {
        None // We don't return a Value from this bucket
    }
}
