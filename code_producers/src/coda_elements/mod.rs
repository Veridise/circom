use std::collections::HashMap;
use std::fs::File;
use program_structure::ast::SignalType;
use crate::llvm_elements::run_fn_name;
use serde::Serialize;
use serde::Deserialize;
use program_structure::file_definition::FileLibrary;

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaCircuitData {
    pub field_tracking: Vec<String>
}

impl Default for CodaCircuitData {
    fn default() -> Self {
        CodaCircuitData { field_tracking: Vec::new() }
    }
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Meta {
    pub is_ir_ssa: bool,
    pub prime: String
}

#[derive(Serialize, Deserialize, Debug)]
pub struct SignalSummary {
    pub name: String,
    pub visibility: String,
    pub idx: usize,
    pub public: bool
}

#[derive(Serialize, Deserialize, Debug)]
pub struct SubcmpSummary {
    pub name: String,
    pub idx: usize
}

#[derive(Serialize, Deserialize, Debug)]
pub struct TemplateSummary {
    pub name: String,
    pub main: bool,
    pub signals: Vec<SignalSummary>,
    pub subcmps: Vec<SubcmpSummary>,
    pub logic_fn_name: String
}

#[derive(Serialize, Deserialize, Debug)]
pub struct FunctionSummary {
    pub name: String,
    pub params: Vec<String>,
    pub logic_fn_name: String,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct SummaryRoot {
    pub version: String,
    pub compiler: String,
    pub framework: Option<String>,
    pub meta: Meta,
    pub components: Vec<TemplateSummary>,
    pub functions: Vec<FunctionSummary>
}

pub struct CodaProgram {
    pub templates: Vec<CodaTemplate>,
    // pub main: ,
}

impl CodaProgram {
    pub fn print(&self) -> String {
        let mut str = String::new();
        // TODO: imports
        for template in &self.templates {
            str.push_str(&format!("{}\n", &template.print()))
        }
        str
    }
}

impl Default for CodaProgram {
    fn default() -> Self {
        CodaProgram { templates: Vec::new() }
    }
}

pub struct CodaTemplate {
    pub name: String,
    pub inputs: Vec<CodaVar>,
    pub intermediates: Vec<CodaVar>,
    pub outputs: Vec<CodaVar>,
    pub body: CodaExpr,
}

impl CodaTemplate {
    pub fn print(&self) -> String {
        let mut str = String::new();

        let body_name = format!("body_{}", self.name);
        {
            let params =
                self.inputs.iter().map(|x| x.value.clone()).collect::<Vec<String>>().join(" ");
            let body = self.body.print();
            str.push_str(&format!("let {} {} = {}\n\n", body_name, params, body));
        }

        {
            let circuit_name = format!("circuit_{}", self.name);
            let args_strings: Vec<String> = self
                .inputs
                .iter()
                .map(|x| format!("(var \"{}\")", x.value))
                .collect();

            let inputs_strings: Vec<String> = self.inputs.iter().map(|input| format!("Presignal \"{}\"", input.print())).collect();
            let outputs_strings: Vec<String> = self.outputs.iter().map(|output| format!("Presignal \"{}\"", output.print())).collect();
            let circuit_constr = format!(
                "Hoare_circuit {{ name= \"{}\"; inputs= [{}]; outputs= [{}]; preconditions= []; postconditions= []; body= {} {} }}",
                self.name,
                inputs_strings.join(" "),
                outputs_strings.join(" "),
                body_name,
                args_strings.join(" ")
            );
            str.push_str(&format!("let {} = {}\n\n", circuit_name, circuit_constr));
        }

        str
    }
}

#[derive(Clone)]
pub enum CodaExpr {
    Let(CodaVar, Box<CodaExpr>, Box<CodaExpr>),
    Op(CodaOp, Box<CodaExpr>, Box<CodaExpr>),
    Var(CodaVar),
    Val(CodaVal),
    Branch { condition: Box<CodaExpr>, then_: Box<CodaExpr>, else_: Box<CodaExpr> },
    Tuple(Vec<Box<CodaExpr>>),
    Inst(CodaComponentInfo, Box<CodaExpr>),
}

impl CodaExpr {
    pub fn print(&self) -> String {
        match &self {
            CodaExpr::Let(x, e1, e2) => {
                format!("let {} = {} in {}", x.print(), e1.print(), e2.print())
            }
            CodaExpr::Op(o, e1, e2) => {
                format!("({} {} {})", e1.print(), o.print(), e2.print())
            }
            CodaExpr::Var(var) => var.print(),
            CodaExpr::Val(val) => val.print(),
            CodaExpr::Branch { condition, then_, else_ } => todo!(),
            CodaExpr::Tuple(es) => {
                let s = es.iter().map(|e| e.print()).collect::<Vec<String>>().join(", ");
                format!("({})", s)
            }
            CodaExpr::Inst(cmp_info, e) => {
                let args_strings: Vec<String> = cmp_info.inputs.iter().map(|arg| arg.print()).collect();
                let outs_strings: Vec<String> = cmp_info.outputs.iter().map(|out| out.print()).collect();
                format!("let ({}) = body_{} {} in {}", outs_strings.join(", "), cmp_info.template_name, args_strings.join(" "), e.print())
            }
        }
    }
}

#[derive(Clone)]
pub enum CodaOp {
    Add,
    Sub,
    Mul,
    Div,
    Mod,
    Pow,
}

impl CodaOp {
    pub fn print(&self) -> String {
        match &self {
            CodaOp::Add => "+".to_string(),
            CodaOp::Sub => "-".to_string(),
            CodaOp::Mul => "*".to_string(),
            CodaOp::Div => "/".to_string(),
            CodaOp::Mod => "%".to_string(),
            CodaOp::Pow => "^".to_string(),
        }
    }
}

#[derive(Clone)]
pub struct CodaVal {
    value: String,
}

impl CodaVal {
    pub fn new(x: String) -> CodaVal {
        CodaVal { value: x }
    }

    pub fn print(&self) -> String {
        self.value.clone()
    }
}

#[derive(Clone)]
pub struct CodaVar {
    value: String,
}

impl CodaVar {
    pub fn print(&self) -> String {
        self.value.clone()
    }
}

impl CodaVar {
    pub fn make_signal(name: String) -> CodaVar {
        CodaVar { value: format!("signal_{}", name) }
    }

    pub fn make_subcomponent_signal(cmp_name: String, name: String) -> CodaVar {
        CodaVar { value: format!("signal_{}_{}", cmp_name, name) }
    }

    pub fn make_variable(i: usize) -> CodaVar {
        CodaVar { value: format!("var_{}", i) }
    }
}

#[derive(Clone)]
pub struct CodaComponentInfo {
    template_name: String,
    component_name: String,
    inputs: Vec<CodaVar>,
    outputs: Vec<CodaVar>,
}

impl CodaComponentInfo {
    pub fn new(template_name: String, component_name: String, inputs: Vec<CodaVar>, outputs: Vec<CodaVar>) -> Self { Self { template_name, component_name, inputs, outputs } }
}
