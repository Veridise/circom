use code_producers::llvm_elements::{LLVMInstruction, LLVMIRProducer};
use crate::intermediate_representation::{SExp, ToSExp, UpdateId};
use crate::translating_traits::WriteLLVMIR;
use super::ir_interface::*;

#[derive(Clone, Debug, Eq, PartialEq, Ord, PartialOrd)]
pub enum LocationRule {
    Indexed { location: InstructionPointer, template_header: Option<String> },
    Mapped { signal_code: usize, indexes: Vec<InstructionPointer> },
}

impl ToString for LocationRule {
    fn to_string(&self) -> String {
        use LocationRule::*;
        match self {
            Indexed { location, template_header } => {
                let location_msg = location.to_string();
                let header_msg = template_header.as_ref().map_or("NONE".to_string(), |v| v.clone());
                format!("INDEXED: ({}, {})", location_msg, header_msg)
            }
            Mapped { signal_code, indexes } => {
                let code_msg = signal_code.to_string();
                let index_mgs: Vec<String> = indexes.iter().map(|i| i.to_string()).collect();
                format!("MAPPED: ({}, {:?})", code_msg, index_mgs)
            }
        }
    }
}

impl ToSExp for LocationRule {
    fn to_sexp(&self) -> SExp {
        use LocationRule::*;
        match self {
            Indexed { location, template_header } => SExp::List(vec![
                SExp::Atom("INDEXED".to_string()),
                location.to_sexp(),
                SExp::Atom(
                    template_header.as_ref().map_or("NONE".to_string(), |v| v.clone())
                )
            ]),
            Mapped { signal_code, indexes } => SExp::List(vec![
                SExp::Atom("MAPPED".to_string()),
                SExp::Atom(signal_code.to_string()),
                SExp::List(indexes.iter().map(|i| i.to_sexp()).collect())
            ])
        }
    }
}

impl UpdateId for LocationRule {
    fn update_id(&mut self) {
        use LocationRule::*;
        match self {
            Indexed { location, .. } => location.update_id(),
            Mapped { indexes, .. } => {
                for i in indexes {
                    i.update_id();
                }
            }
        }
    }
}

impl WriteLLVMIR for LocationRule {
    fn produce_llvm_ir<'a, 'b>(&self, producer: &'b dyn LLVMIRProducer<'a>) -> Option<LLVMInstruction<'a>> {
        match self {
            LocationRule::Indexed { location, .. } => location.produce_llvm_ir(producer),
            LocationRule::Mapped { .. } => unreachable!("LocationRule::Mapped should have been replaced"),
        }
    }
}
