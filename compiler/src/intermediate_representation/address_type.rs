use crate::intermediate_representation::{SExp, ToSExp, UpdateId};
use super::ir_interface::*;

#[derive(Clone, Debug, Eq, PartialEq, Ord, PartialOrd)]
pub enum StatusInput {
    Last,
    NoLast,
    Unknown,
}

#[derive(Clone, Debug, Eq, PartialEq, Ord, PartialOrd)]
pub enum InputInformation {
    NoInput,
    Input {status: StatusInput},
}

#[derive(Clone, Debug, Eq, PartialEq, Ord, PartialOrd)]
pub enum AddressType {
    Variable,
    Signal,
    SubcmpSignal { cmp_address: InstructionPointer, uniform_parallel_value: Option<bool>, is_output: bool, input_information: InputInformation },
}

impl ToString for AddressType {
    fn to_string(&self) -> String {
        use AddressType::*;
        match self {
            Variable => "VARIABLE".to_string(),
            Signal => "SIGNAL".to_string(),
            SubcmpSignal { cmp_address, .. } => format!("SUBCOMPONENT:{}", cmp_address.to_string()),
        }
    }
}

impl ToSExp for AddressType {
    fn to_sexp(&self) -> SExp {
        use AddressType::*;
        match self {
            Variable => SExp::Atom("VARIABLE".to_string()),
            Signal => SExp::Atom("SIGNAL".to_string()),
            SubcmpSignal { cmp_address, .. } => SExp::List(vec![
                SExp::Atom("SUBCOMPONENT".to_string()),
                cmp_address.to_sexp()
            ])
        }
    }
}

impl UpdateId for AddressType {
    fn update_id(&mut self) {
        use AddressType::*;
        match self {
            SubcmpSignal { cmp_address, ..} => cmp_address.update_id(),
            _ => {}
        }
    }
}