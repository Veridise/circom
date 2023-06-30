use std::collections::HashMap;
use std::fs::File;
use std::io::Write;
use serde::{Serialize, Deserialize};

// This is intended to match the `SummaryRoot` and associated structs in the
// `summary` package. I couldn't directly import because of cyclic dependencies.
// But this is clearly the right place to know about (some of) the summary
// metadata, so I'm not sure what else I should have done.
#[derive(Clone, Eq, PartialEq, Debug, Serialize, Deserialize)]
pub struct SummaryRoot {
    version: String,
    compiler: String,
    framework: Option<String>,
    // meta: Meta,
    // components: Vec<TemplateSummary>,
    // functions: Vec<FunctionSummary>,
}

// #[derive(Clone, Eq, PartialEq, Debug)]
// pub struct CodaProducer {
//     summary_root: Option<SummaryRoot>,
//     vars: Vec<String>,
// }

// impl CodaProducer {
//     // HENRY:TODO: functions to build up a coda program

//     pub fn load_summary(&mut self, summary_file: &str) -> Result<(), ()> {
//         let rdr = File::open(summary_file).unwrap();
//         let summary_root: SummaryRoot = serde_json::from_reader(rdr).expect(
//             "Could not find summary file. Please run the compiler with the --summary flag.",
//         );
//         self.summary_root = Some(summary_root);
//         println!("Load summary file: {}", summary_file);
//         println!("Loaded summary root: {:?}", self.summary_root);
//         Ok(())
//     }

//     fn program(&self) -> CodaProgram {
//         CodaProgram::CodaProgram
//     }

//     pub fn write<W: Write>(&self, writer: &mut W) -> Result<(), ()> {
//         if self.summary_root.is_none() {
//             println!("[ERROR] In CodaProducer.write: expected a summary root to be loaded via `load_summary` before writing.");
//             return Err(());
//         }
//         println!("[coda_elements::CodaProducer::write]");
//         let program = self.program();
//         // HENRY: actually write the program using the writer
//         Ok(())
//     }
// }

// HENRY:TODO: decide on repr of Coda in rust
#[derive(Clone, Eq, PartialEq, Debug)]
pub enum CodaProgram {
    CodaProgram,
}

pub fn empty_coda_program() -> CodaProgram {
    CodaProgram::CodaProgram
}

// impl Default for CodaProducer {
//     fn default() -> Self {
//         // HENRY: what should the producer do?
//         CodaProducer { summary_root: None, vars: vec![] }
//     }
// }
