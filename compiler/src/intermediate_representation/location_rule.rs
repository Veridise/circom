use code_producers::llvm_elements::{LLVMIRProducer, LLVMValue};
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
        match self {
            LocationRule::Indexed { location, template_header } => SExp::list([
                SExp::atom("INDEXED"),
                location.to_sexp(),
                template_header.as_ref().map_or(SExp::atom("NONE"), |v| SExp::atom(v)),
            ]),
            LocationRule::Mapped { signal_code, indexes } => {
                SExp::list([SExp::atom("MAPPED"), SExp::atom(signal_code), indexes.to_sexp()])
            }
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
    fn produce_llvm_ir<'a>(&self, producer: &dyn LLVMIRProducer<'a>) -> Option<LLVMValue<'a>> {
        match self {
            LocationRule::Indexed { location, .. } => location.produce_llvm_ir(producer),
            LocationRule::Mapped { .. } => unreachable!("LocationRule::Mapped should have been replaced"),
        }
    }
}
