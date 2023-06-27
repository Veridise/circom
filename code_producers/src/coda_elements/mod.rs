#[derive(Clone, Eq, PartialEq, Debug)]
pub struct CodaProducer {
    // HENRY: look at LLVMIRProducer
}

// HENRY: decide on repr of Coda in rust
pub type CodaProgram<'a> = String;

pub fn empty_coda_program<'a>() -> CodaProgram<'a> {
    "<empty Coda program>".to_string()
}

pub fn generate_coda_program<'a, 'b>(producer: &'b CodaProducer) -> CodaProgram<'a> {
    println!("[coda_elements::generate_coda_program]");
    // HENRY: produce actual Coda program
    empty_coda_program()
}

// impl Sized for CodaProducer {
// }

impl Default for CodaProducer {
    fn default() -> Self {
        // HENRY: what should the producer do?
        CodaProducer {}
    }
}
