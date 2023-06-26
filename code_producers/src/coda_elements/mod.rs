use inkwell::values::*; // {AnyValueEnum, IntValue};

pub trait CodaProducer<'a> {
  // TODO: look at LLVMIRProducer
}

// TODO: decide on repr of Coda in rust
pub type CodaProgram<'a> = bool;

pub fn empty_coda_program<'a>() -> CodaProgram<'a> {
  true
}