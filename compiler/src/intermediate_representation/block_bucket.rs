use code_producers::llvm_elements::{LLVMInstruction, LLVMIRProducer};
use crate::intermediate_representation::{
    BucketId, Instruction, InstructionList, new_id, SExp, ToSExp, UpdateId,
};
use crate::intermediate_representation::ir_interface::{IntoInstruction, ObtainMeta};
use crate::translating_traits::WriteLLVMIR;

#[derive(Clone, Debug, Eq, PartialEq, Ord, PartialOrd)]
pub struct BlockBucket {
    pub id: BucketId,
    pub source_file_id: Option<usize>,
    pub line: usize,
    pub message_id: usize,
    pub body: InstructionList,
    pub n_iters: usize,
    pub label: String,
}

impl IntoInstruction for BlockBucket {
    fn into_instruction(self) -> Instruction {
        Instruction::Block(self)
    }
}

impl ObtainMeta for BlockBucket {
    fn get_source_file_id(&self) -> &Option<usize> {
        &self.source_file_id
    }
    fn get_line(&self) -> usize {
        self.line
    }
    fn get_message_id(&self) -> usize {
        self.message_id
    }
}

impl ToString for BlockBucket {
    fn to_string(&self) -> String {
        let line = self.line.to_string();
        let template_id = self.message_id.to_string();
        let mut body = "[\n".to_string();
        for i in &self.body {
            body = format!("{} - {};\n", body, i.to_string());
        }
        body = format!("{}]", body);
        format!(
            "BLOCK(line:{},template_id:{},n_iterations:{},body:{})",
            line, template_id, self.n_iters, body
        )
    }
}

impl ToSExp for BlockBucket {
    fn to_sexp(&self) -> SExp {
        SExp::list([
            SExp::atom("BLOCK"),
            SExp::key_val("line", SExp::atom(self.line)),
            SExp::key_val("n_iters", SExp::atom(self.n_iters)),
            SExp::key_val("body", self.body.to_sexp()),
        ])
    }
}

impl UpdateId for BlockBucket {
    fn update_id(&mut self) {
        self.id = new_id();
        for inst in &mut self.body {
            inst.update_id();
        }
    }
}

impl WriteLLVMIR for BlockBucket {
    fn produce_llvm_ir<'a>(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
    ) -> Option<LLVMInstruction<'a>> {
        Self::manage_debug_loc_from_curr(producer, self);

        let mut last = None;
        for inst in &self.body {
            last = inst.produce_llvm_ir(producer);
        }
        last
    }
}
