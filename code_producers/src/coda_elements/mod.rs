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

pub fn load_summary(summary_file: &str) -> Result<SummaryRoot, serde_json::Error> {
    let rdr = File::open(summary_file).unwrap();
    serde_json::from_reader(rdr)
}

// HENRY:TODO: decide on repr of Coda in rust
#[derive(Clone, Eq, PartialEq, Debug)]
pub struct CodaProgram {}

impl Default for CodaProgram {
    fn default() -> Self {
        CodaProgram {}
    }
}
