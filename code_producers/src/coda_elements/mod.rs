use std::{collections::HashMap, fmt::format};
use std::fs::File;
use std::io::Write;
use inkwell::GlobalVisibility;
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

impl SummaryRoot {
    pub fn get_component(&self, name: &str) -> &TemplateSummary {
        self.components.iter().find(|c| c.name == name).unwrap()
    }
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

// A subcomponent instance is translated into a function definition that preceeds the main Coda circuit. The function inputs the subcomponent's input signals, and outputs the subcomponent's output signals as a tuple.
#[derive(Clone, Debug)]
pub struct CodaSubcomponentInstance {
    pub name: String,
    pub signals: Vec<CodaSignal>,
    pub output_definitions: HashMap<String, CodaExpr>,
}

impl CodaSubcomponentInstance {
    pub fn new(name: String, signals: Vec<CodaSignal>) -> Self {
        Self { name, signals, output_definitions: HashMap::new() }
    }
}

#[derive(Clone, Debug)]
pub struct CodaCircuit {
    pub name: String,
    pub signals: Vec<CodaSignal>,
    // pub preconditions: Vec<CodaExpr>,
    // pub postconditions: Vec<CodaExpr>,
    pub subcomponents: Vec<CodaSubcomponentInstance>,
    pub subcomponents_map: HashMap<String, CodaSubcomponentInstance>,
    pub subcomponent_inputs: HashMap<String, HashMap<String, CodaExpr>>,
    pub intermediate_definitions: HashMap<String, CodaExpr>,
    pub output_definitions: HashMap<String, CodaExpr>,
}

impl CodaCircuit {
    pub fn new(name: String) -> Self {
        CodaCircuit {
            name,
            signals: Vec::new(),
            // preconditions: Vec::new(),
            // postconditions: Vec::new(),
            subcomponents: Vec::new(),
            subcomponents_map: HashMap::new(),
            subcomponent_inputs: HashMap::new(),
            intermediate_definitions: HashMap::new(),
            output_definitions: HashMap::new(),
        }
    }

    pub fn add_subcomponent(&mut self, subcomponent: CodaSubcomponentInstance) {
        self.subcomponents.push(subcomponent.clone());
        self.subcomponent_inputs.insert(subcomponent.name, HashMap::new());
    }

    pub fn add_input(&mut self, name: String, type_: CodaType) {
        // println!("[CE] add_input {}", name);
        self.signals.push(CodaSignal { name, type_, visibility: CodaSignalVisibility::Input });
    }

    pub fn add_intermediate(&mut self, name: String, type_: CodaType) {
        // println!("[CE] add_inter {}", name);
        self.signals.push(CodaSignal {
            name,
            type_,
            visibility: CodaSignalVisibility::Intermediate,
        });
    }

    pub fn add_output(&mut self, name: String, type_: CodaType) {
        // println!("[CE] add_output {}", name);
        self.signals.push(CodaSignal { name, type_, visibility: CodaSignalVisibility::Output });
    }

    pub fn define_output(&mut self, name: String, expr: CodaExpr) {
        // println!("[CE] define_output {} := {:?}", name, expr);
        self.output_definitions.insert(name, expr);
        ()
    }

    pub fn define_subcomponent_input(&mut self, cmp_name: String, name: String, expr: CodaExpr) {
        let inputs = self.subcomponent_inputs.get_mut(cmp_name.as_str()).unwrap();
        inputs.insert(name, expr);
    }

    pub fn define_intermediate(&mut self, name: String, expr: CodaExpr) {
        // println!("[CE] define_intermediate {} := {:?}", name, expr);
        self.intermediate_definitions.insert(name, expr);
    }

    pub fn get_subcomponent_signal(&self, cmp_i: usize, i: usize) -> &CodaSignal {
        // let cmp = self.subcomponents[cmp_i];
        // &cmp.signals[i]
        todo!()
    }

    pub fn get_signal(&self, i: usize) -> &CodaSignal {
        &self.signals[i]
    }

    pub fn index_signal(&self, name: &str) -> usize {
        self.signals.iter().position(|s| s.name == name).unwrap()
    }
}

#[derive(Clone, Debug)]
pub struct CodaSignal {
    pub name: String,
    pub type_: CodaType,
    pub visibility: CodaSignalVisibility,
}

#[derive(Clone, Debug, PartialEq)]
pub enum CodaSignalVisibility {
    Input,
    Output,
    Intermediate,
}

impl CodaSignalVisibility {
    pub fn parse(str: &str) -> CodaSignalVisibility {
        if str == "input" {
            CodaSignalVisibility::Input
        } else if str == "output" {
            CodaSignalVisibility::Output
        } else if str == "inter" {
            CodaSignalVisibility::Intermediate
        } else {
            panic!("Unrecognized CodaSignalVisibility string: {}", str)
        }
    }
}

impl Default for CodaProgram {
    fn default() -> Self {
        CodaProgram { coda_circuits: Vec::new() }
    }
}

#[derive(Clone, Debug)]
pub enum CodaExpr {
    Signal(String),
    SubcomponentSignal(String, String),
    Literal(String, LiteralType),
    Binop(CodaBinopType, CodaBinop, Box<CodaExpr>, Box<CodaExpr>),
}

#[derive(Clone, Debug)]
pub enum LiteralType {
    BigInt,
    U32,
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
            s.push_str("\n\n");
        }
        s
    }
}

impl CompileString for CodaCircuit {
    fn compile_string(&self) -> String {
        let mut s = String::new();
        s.push_str("let open Hoare_circuit in to_circuit @@ Hoare_circuit {");

        s.push_str(&format!(" name= \"{}\"", self.name));

        let input_signals: Vec<&CodaSignal> = self
            .signals
            .iter()
            .filter(|&signal| signal.visibility == CodaSignalVisibility::Input)
            .collect();

        s.push_str("; inputs= BaseTyp.[");
        for signal in input_signals {
            s.push_str(&format!("(\"{}\", {})", signal.name, signal.type_.compile_string()))
        }
        s.push_str("]");

        let output_signals: Vec<&CodaSignal> = self
            .signals
            .iter()
            .filter(|&signal| signal.visibility == CodaSignalVisibility::Output)
            .collect();

        s.push_str("; outputs= BaseTyp.[");
        for signal in output_signals {
            s.push_str(&format!("(\"{}\", {})", signal.name, signal.type_.compile_string()))
        }
        s.push_str("]");

        s.push_str("; preconditions= []");
        s.push_str("; postconditions= []");

        s.push_str("; body= ");

        // let-define each intermediate
        for (name, expr) in &self.intermediate_definitions {
            s.push_str(&format!("let {} = {} in ", name, expr.compile_string()));
        }

        if self.output_definitions.len() == 0 {
            panic!("There are no output_definitions in circuit {}", self.name)
        } else if self.output_definitions.len() == 1 {
            let expr = self.output_definitions.values().next().unwrap();
            s.push_str(&format!("{}", expr.compile_string()))
        } else {
            todo!("handle multiple output_definitions")
        }

        s.push_str(" }");
        s
    }
}

impl CompileString for CodaType {
    fn compile_string(&self) -> String {
        match self {
            CodaType::Field => "field".to_string(),
        }
    }
}

impl CompileString for CodaExpr {
    fn compile_string(&self) -> String {
        match self {
            CodaExpr::Signal(name) => name.clone(),
            CodaExpr::SubcomponentSignal(subcmp_name, name) => format!("{}__{}", subcmp_name, name),
            CodaExpr::Literal(value, type_) => match type_ {
                LiteralType::BigInt => format!("{}", value),
                LiteralType::U32 => format!("{}", value),
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
            }
        }
    }
}
