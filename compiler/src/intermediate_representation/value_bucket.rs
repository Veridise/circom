use super::ir_interface::*;
use crate::translating_traits::*;
use crate::intermediate_representation::{BucketId, new_id, SExp, ToSExp, UpdateId};
use code_producers::c_elements::*;
use code_producers::llvm_elements::{LLVMIRProducer, LLVMValue};
use code_producers::llvm_elements::values::{create_literal_u32, get_const};
use code_producers::wasm_elements::*;

#[derive(Clone, Debug, Eq, PartialEq, Ord, PartialOrd)]
pub struct ValueBucket {
    pub id: BucketId,
    pub source_file_id: Option<usize>,
    pub line: usize,
    pub message_id: usize,
    pub parse_as: ValueType,
    pub op_aux_no: usize,
    pub value: usize,
}

impl IntoInstruction for ValueBucket {
    fn into_instruction(self) -> Instruction {
        Instruction::Value(self)
    }
}

impl ObtainMeta for ValueBucket {
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

impl ToString for ValueBucket {
    fn to_string(&self) -> String {
        let line = self.line.to_string();
        let template_id = self.message_id.to_string();
        let parse_as = self.parse_as.to_string();
        let op_aux_number = self.op_aux_no.to_string();
        let value = self.value;
        format!(
            "VALUE(line:{},template_id:{},as:{},op_number:{},value:{})",
            line, template_id, parse_as, op_aux_number, value
        )
    }
}

impl ToSExp for ValueBucket {
    fn to_sexp(&self) -> SExp {
        SExp::list([
            SExp::atom("VALUE"),
            SExp::key_val("id", SExp::atom(self.id)),
            SExp::key_val("line", SExp::atom(self.line)),
            SExp::key_val("op_aux_no", SExp::atom(self.op_aux_no)),
            SExp::key_val(self.parse_as, SExp::atom(self.value)),
        ])
    }
}

impl UpdateId for ValueBucket {
    fn update_id(&mut self) {
        self.id = new_id();
    }
}

impl WriteLLVMIR for ValueBucket {
    fn produce_llvm_ir<'a>(&self, producer: &dyn LLVMIRProducer<'a>) -> Option<LLVMValue<'a>> {
        // NOTE: do not change debug location for a value because it is not a top-level source statement

        // Represents a literal value
        match self.parse_as {
            ValueType::BigInt => Some(get_const(producer, self.value)),
            ValueType::U32 => Some(create_literal_u32(producer, self.value as u64).into()),
        }
    }
}

impl WriteWasm for ValueBucket {
    fn produce_wasm(&self, producer: &WASMProducer) -> Vec<String> {
        use code_producers::wasm_elements::wasm_code_generator::*;
        let mut instructions = vec![];
        if producer.needs_comments() {
            instructions.push(";; value bucket".to_string());
        }
        match &self.parse_as {
            ValueType::U32 => {
                instructions.push(set_constant(&self.value.to_string()));
            }
            ValueType::BigInt => {
                let mut const_pos = self.value;
                const_pos *= (producer.get_size_32_bit() + 2) * 4;
                const_pos += producer.get_constant_numbers_start();
                instructions.push(set_constant(&const_pos.to_string()));
            }
        }
        if producer.needs_comments() {
            instructions.push(";; end of value bucket".to_string());
	}
        instructions
    }
}

impl WriteC for ValueBucket {
    fn produce_c(&self, _producer: &CProducer, _parallel: Option<bool>) -> (Vec<String>, String) {
        use c_code_generator::*;
        let index = self.value.to_string();
        match self.parse_as {
            ValueType::U32 => (vec![], index),
            ValueType::BigInt => {
                let access = format!("&{}", circuit_constants(index));
                (vec![], access)
            }
        }
    }
}
