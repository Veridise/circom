use std::collections::HashMap;
use std::fs::File;
use std::io::Write;
use serde::{Serialize, Deserialize};

// This is intended to match the `SummaryRoot` and associated structs in the
// `summary` package. I couldn't directly import because of cyclic dependencies.
// But this is clearly the right place to know about (some of) the summary
// metadata, so I'm not sure what else I should have done.
#[derive(Deserialize, Debug)]
pub struct SummaryRoot {
    pub version: String,
    pub compiler: String,
    pub framework: Option<String>,
    // pub meta: Meta,
    pub components: Vec<TemplateSummary>,
    // pub functions: Vec<FunctionSummary>,
}

#[derive(Deserialize, Debug)]
pub struct TemplateSummary {
    pub name: String,
    pub main: bool,
    pub signals: Vec<SignalSummary>,
    pub subcmps: Vec<SubcmpSummary>,
    pub logic_fn_name: String   
}

#[derive(Deserialize, Debug)]
pub struct SignalSummary {
    pub name: String,
    pub visibility: String,
    pub idx: usize,
    pub public: bool
}

#[derive(Deserialize, Debug)]
pub struct SubcmpSummary {
    pub name: String,
    pub idx: usize
}

pub fn load_summary(summary_file: &str) -> Result<SummaryRoot, serde_json::Error> {
    let rdr = File::open(summary_file).unwrap();
    serde_json::from_reader(rdr)
}

#[derive(Clone, Eq, PartialEq, Debug)]
pub struct CodaProgram {
    pub circuits: Vec<CodaCircuit>,
}

#[derive(Clone, Eq, PartialEq, Debug)]
pub struct CodaCircuit {
    pub name: String,
    pub inputs: Vec<CodaSignal>,
    pub outputs: Vec<CodaSignal>,
    pub preconditions: Vec<CodaTerm>,
    pub postconditions: Vec<CodaTerm>,
    pub body: CodaTerm,
}

#[derive(Clone, Eq, PartialEq, Debug)]
pub struct CodaSignal {
    pub name: String,
    pub type_: CodaType,
}

#[derive(Clone, Eq, PartialEq, Debug)]
pub enum CodaTerm {
    Nop,
}

#[derive(Clone, Eq, PartialEq, Debug)]
pub enum CodaType {}

impl Default for CodaTerm {
    fn default() -> Self {
        CodaTerm::Nop
    }
}

impl Default for CodaProgram {
    fn default() -> Self {
        CodaProgram { circuits: Vec::new() }
    }
}

pub fn empty_coda_circuit(name: String) -> CodaCircuit {
    CodaCircuit {
        name,
        inputs: Vec::new(),
        outputs: Vec::new(),
        preconditions: Vec::new(),
        postconditions: Vec::new(),
        body: CodaTerm::default(),
    }
}
