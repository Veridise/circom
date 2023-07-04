use std::collections::HashMap;
use std::fs::File;
use std::io::Write;
use serde::{Serialize, Deserialize, de::value};

// This is intended to match the `SummaryRoot` and associated structs in the
// `summary` package. I couldn't directly import because of cyclic dependencies.
// But this is clearly the right place to know about (some of) the summary
// metadata, so I'm not sure what else I should have done.
#[derive(Deserialize, Debug)]
pub struct SummaryRoot {
    pub version: String,
    pub compiler: String,
    pub framework: Option<String>,
    pub components: Vec<TemplateSummary>,
}

#[derive(Deserialize, Debug)]
pub struct TemplateSummary {
    pub name: String,
    pub main: bool,
    pub signals: Vec<SignalSummary>,
    pub subcmps: Vec<SubcmpSummary>,
    pub logic_fn_name: String,
}

#[derive(Deserialize, Debug)]
pub struct SignalSummary {
    pub name: String,
    pub visibility: String,
    pub idx: usize,
    pub public: bool,
}

#[derive(Deserialize, Debug)]
pub struct SubcmpSummary {
    pub name: String,
    pub idx: usize,
}

pub fn load_summary(summary_file: &str) -> Result<SummaryRoot, serde_json::Error> {
    let rdr = File::open(summary_file).unwrap();
    serde_json::from_reader(rdr)
}

#[derive(Clone, Debug)]
pub struct CodaProgram {
    pub coda_circuits: Vec<CodaCircuit>,
}

#[derive(Clone, Debug)]
pub struct CodaCircuit {
    pub name: String,
    pub signals: Vec<CodaSignal>,
    pub preconditions: Vec<CodaExpr>,
    pub postconditions: Vec<CodaExpr>,
    pub definitions: Vec<(String, CodaExpr)>,
    // A body for each output, in order of outputs
    pub bodies: HashMap<String, CodaExpr>,
}

impl CodaCircuit {
    pub fn new(name: String) -> Self {
        CodaCircuit {
            name,
            signals: Vec::new(),
            preconditions: Vec::new(),
            postconditions: Vec::new(),
            definitions: Vec::new(),
            bodies: HashMap::new(),
        }
    }

    pub fn add_input(&mut self, name: String, type_: CodaType) {
        println!("[CODA] add_input {}", name);
        self.signals.push(CodaSignal { name, type_, visibility: CodaSignalVisibility::Input });
    }

    pub fn add_output(&mut self, name: String, type_: CodaType) {
        println!("[CODA] add_output {}", name);
        self.signals.push(CodaSignal { name, type_, visibility: CodaSignalVisibility::Output });
    }

    pub fn define_output(&mut self, i: usize, term: CodaExpr) {
        let name = self.get_signal(i).name.clone();
        println!("[CODA] define_output {} := {:?}", name, term);
        self.bodies.insert(name, term);
        ()
    }

    pub fn get_signal(&self, i: usize) -> &CodaSignal {
        &self.signals[i]
    }

    pub fn index_signal(&self, name: &str) -> Option<usize> {
        self.signals.iter().position(|s| s.name == name)
    }

    pub fn add_definition(&mut self, name: String, term: CodaExpr) {
        self.definitions.push((name, term));
    }
}

#[derive(Clone, Debug)]
pub struct CodaSignal {
    pub name: String,
    pub type_: CodaType,
    pub visibility: CodaSignalVisibility,
}

#[derive(Clone, Debug)]
pub enum CodaSignalVisibility {
    Input,
    Output,
}

impl Default for CodaProgram {
    fn default() -> Self {
        CodaProgram { coda_circuits: Vec::new() }
    }
}

#[derive(Clone, Debug)]
pub enum CodaExpr {
    Signal(String),
    Literal(String, LiteralType),
    Binop(CodaBinopType, CodaBinop, Box<CodaExpr>, Box<CodaExpr>),
}

#[derive(Clone, Debug)]
pub enum LiteralType {
    BigInt,
    U32
}

#[derive(Clone, Debug)]
pub enum CodaBinopType {
    N,
    Z,
    F,
}

#[derive(Clone, Debug)]
pub enum CodaBinop {
    Add,
    Sub,
    Mul,
    Pow,
    Mod,
    Div,
}

#[derive(Clone, Debug)]
pub enum CodaType {
    Field,
}

pub trait CompileString {
    fn compile_string(&self) -> String;
}

impl CompileString for CodaProgram {
    fn compile_string(&self) -> String {
        let mut s = String::new();
        for circuit in &self.coda_circuits {
            s.push_str(&circuit.compile_string());
        }
        s       
    }
}

impl CompileString for CodaCircuit {
    fn compile_string(&self) -> String {
        let mut s = String::new();
        s.push_str(&format!("circuit {} {{\n", self.name));
        for signal in &self.signals {
            s.push_str(&format!("    signal {} {};\n", signal.visibility.compile_string(), signal.name));
        }
        for (name, term) in &self.definitions {
            s.push_str(&format!("    {} <== {};\n", name, term.compile_string()));
        }
        for (name, term) in &self.bodies {
            s.push_str(&format!("    {} <== {};\n", name, term.compile_string()));
        }
        s.push_str("}\n");
        s
    }
}

impl CompileString for CodaSignalVisibility {
    fn compile_string(&self) -> String {
        match self {
            CodaSignalVisibility::Input => "input".to_string(),
            CodaSignalVisibility::Output => "output".to_string(),
        }
    }
}

impl CompileString for CodaExpr {
    fn compile_string(&self) -> String {
        match self {
            CodaExpr::Signal(name) => name.clone(),
            CodaExpr::Literal(value, type_) => {
                match type_ {
                    LiteralType::BigInt => format!("{}", value),
                    LiteralType::U32 => format!("{}", value),
                }
            },
            CodaExpr::Binop(type_, op, e1, e2) => {
                let op = match op {
                    CodaBinop::Add => "+",
                    CodaBinop::Sub => "-",
                    CodaBinop::Mul => "*",
                    CodaBinop::Pow => "**",
                    CodaBinop::Mod => "%",
                    CodaBinop::Div => "/",
                };
                format!("({} {} {})", e1.compile_string(), op, e2.compile_string())
            },
        }
    }
}