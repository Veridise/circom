use summary::SummaryRoot;
use std::io::Write;

#[derive(Clone, Eq, PartialEq, Debug)]
pub struct CodaProducer {
    summaryRoot: SummaryRoot,
    vars: Vec<String>,
}

impl CodaProducer {
    // HENRY: functions to build up a coda program

    fn program(&self) -> CodaProgram {
        CodaProgram::CodaProgram
    }

    pub fn write<W: Write>(&self, writer: &mut W) -> Result<(), ()> {
        println!("[coda_elements::CodaProducer::write]");
        let program = self.program();
        // HENRY: actually write the program with the writer
        Ok(())
    }
}

// HENRY: decide on repr of Coda in rust
#[derive(Clone, Eq, PartialEq, Debug)]
pub enum CodaProgram {
    CodaProgram,
}

pub fn empty_coda_program() -> CodaProgram {
    CodaProgram::CodaProgram
}

// impl Sized for CodaProducer {
// }

impl Default for CodaProducer {
    fn default() -> Self {
        // HENRY: what should the producer do?
        CodaProducer { vars: vec![] }
    }
}
