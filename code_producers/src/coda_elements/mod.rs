use std::str::FromStr;
use serde::Serialize;
use serde::Deserialize;

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaCircuitData {
    pub field_tracking: Vec<String>,
}

impl Default for CodaCircuitData {
    fn default() -> Self {
        CodaCircuitData { field_tracking: Vec::new() }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Meta {
    pub is_ir_ssa: bool,
    pub prime: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct SignalSummary {
    pub name: String,
    pub visibility: String,
    pub idx: usize,
    pub public: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct SubcmpSummary {
    pub name: String,
    pub idx: usize,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct TemplateSummary {
    pub name: String,
    pub main: bool,
    pub signals: Vec<SignalSummary>,
    pub subcmps: Vec<SubcmpSummary>,
    pub logic_fn_name: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct FunctionSummary {
    pub name: String,
    pub params: Vec<String>,
    pub logic_fn_name: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct SummaryRoot {
    pub version: String,
    pub compiler: String,
    pub framework: Option<String>,
    pub meta: Meta,
    pub components: Vec<TemplateSummary>,
    pub functions: Vec<FunctionSummary>,
}

pub trait CodaPrint {
    fn coda_print(&self) -> String;
}

pub struct CodaProgram {
    pub templates: Vec<CodaTemplate>,
    // pub main: ,
}

impl CodaPrint for CodaProgram {
    fn coda_print(&self) -> String {
        let mut str = String::new();

        // TODO: imports

        str.push_str(&format!("let bodies: (expr list -> expr) list ref = ref [];;"));

        for _template in &self.templates {
            // str.push_str(&format!("{}\n", &template.coda_print()))
            // str.push_str(&format!("bodies := List.cons () bodies"));
            todo!()
        }

        // // TODO: imports
        // for template in &self.templates {
        //     str.push_str(&format!("{}\n", &template.coda_print()))
        // }

        str
    }
}

impl Default for CodaProgram {
    fn default() -> Self {
        CodaProgram { templates: Vec::new() }
    }
}

#[derive(Debug, Clone)]
pub struct CodaTemplateInterface {
    pub template_id: usize,
    pub template_name: String,
    pub signals: Vec<CodaTemplateSignal>,
}

#[derive(Debug, Clone)]
pub struct CodaTemplateSignal {
    pub name: String,
    pub visibility: CodaVisibility,
}

pub struct CodaTemplate {
    pub interface: CodaTemplateInterface,
    pub body: CodaExpr,
}

pub struct CodaTemplateSubcomponent {
    pub interface: CodaTemplateInterface,
    pub name: String,
    pub header_name: String,
}

impl CodaTemplate {
    pub fn get_inputs(&self) -> Vec<String> {
        self.interface
            .signals
            .iter()
            .filter_map(|signal| match signal.visibility {
                CodaVisibility::Input => Some(signal.name.clone()),
                _ => None,
            })
            .collect()
    }

    pub fn get_outputs(&self) -> Vec<String> {
        self.interface
            .signals
            .iter()
            .filter_map(|signal| match signal.visibility {
                CodaVisibility::Output => Some(signal.name.clone()),
                _ => None,
            })
            .collect()
    }
}

impl CodaPrint for CodaTemplate {
    fn coda_print(&self) -> String {
        let mut str = String::new();

        // TODO: don't need to do this stuff with leading definitions -- all reference indices will be constant by the time of this translation

        str.push_str(&format!(
            "let signal_names = [{}] in ",
            self.interface
                .signals
                .iter()
                .enumerate()
                .map(|(signal_i, signal)| format!("({}, \"{}\")", signal_i, signal.name))
                .collect::<Vec<String>>()
                .join("; ")
        ));
        str.push_str(&format!(
            "let signal_values = [{}] in ",
            self.interface
                .signals
                .iter()
                .enumerate()
                .map(|(signal_i, signal)| match signal.visibility {
                    CodaVisibility::Input => format!("List.nth {} inputs", signal_i),
                    CodaVisibility::Output => CodaExpr::Var(CodaVar::Signal(signal_i)).coda_print(),
                    CodaVisibility::Intermediate =>
                        CodaExpr::Var(CodaVar::Signal(signal_i)).coda_print(),
                })
                .collect::<Vec<String>>()
                .join("; ")
        ));

        // TODO: remove subcomponent stuff

        // str.push_str(&format!(
        //     "let subcomponent_template_names = [{}] in ",
        //     self.subcomponents
        //         .iter()
        //         .enumerate()
        //         .map(|(cmp_i, subcmp)| format!(
        //             "({}, \"{}\")",
        //             cmp_i, subcmp.interface.template_name
        //         ))
        //         .collect::<Vec<String>>()
        //         .join("; ")
        // ));
        // str.push_str(&format!(
        //     "let subcomponent_instance_names = [{}] in ",
        //     self.subcomponents
        //         .iter()
        //         .enumerate()
        //         .map(|(cmp_i, subcmp)| format!(
        //             "({}, \"{}\")",
        //             cmp_i, subcmp.interface.template_name
        //         ))
        //         .collect::<Vec<String>>()
        //         .join("; ")
        // ));
        // str.push_str(&format!(
        //     "let subcomponent_signal_names = [{}] in ",
        //     self.subcomponents
        //         .iter()
        //         .enumerate()
        //         .map(|(cmp_i, subcmp)| format!(
        //             "({}, [{}])",
        //             cmp_i,
        //             subcmp
        //                 .interface
        //                 .signals
        //                 .iter()
        //                 .enumerate()
        //                 .map(|(sig_i, sig)| format!("({}, \"{}\")", sig_i, sig.name))
        //                 .collect::<Vec<String>>()
        //                 .join("; ")
        //         ))
        //         .collect::<Vec<String>>()
        //         .join("; ")
        // ));

        // str.push_str(&format!(
        //     "let subcomponent_signal_values = [{}] in ",
        //     self.subcomponents
        //         .iter()
        //         .enumerate()
        //         .map(|(cmp_i, cmp)| format!(
        //             "({}, [{}])",
        //             cmp_i,
        //             cmp.interface
        //                 .signals
        //                 .iter()
        //                 .enumerate()
        //                 .map(|(sig_i, _sig)| format!(
        //                     "({}, \"{}\")",
        //                     sig_i,
        //                     CodaExpr::Var(CodaVar::SubSignal {
        //                         subcomponent_index: cmp_i,
        //                         signal_index: sig_i
        //                     })
        //                     .coda_print()
        //                 ))
        //                 .collect::<Vec<String>>()
        //                 .join("; ")
        //         ))
        //         .collect::<Vec<String>>()
        //         .join("; ")
        // ));

        // str.push_str(&format!(
        //     "let subcomponent_instances = [{}] in ",
        //     self.subcomponents
        //         .iter()
        //         .enumerate()
        //         .map(|(cmp_i, cmp)| format!(
        //             "({}, List.nth component_bodies {} [{}])",
        //             cmp_i,
        //             cmp_i,
        //             cmp.interface
        //                 .signals
        //                 .iter()
        //                 .enumerate()
        //                 .filter_map(|(sig_i, sig)| match sig.visibility {
        //                     CodaVisibility::Input => Some(
        //                         CodaExpr::Var(CodaVar::SubSignal {
        //                             subcomponent_index: cmp_i,
        //                             signal_index: sig_i
        //                         })
        //                         .coda_print()
        //                     ),
        //                     CodaVisibility::Output => None,
        //                     CodaVisibility::Intermediate => None,
        //                 })
        //                 .collect::<Vec<String>>()
        //                 .join("; ")
        //         ))
        //         .collect::<Vec<String>>()
        //         .join("; ")
        // ));

        // utility functions
        str.push_str(&format!("let get_signal_name i = List.assoc i signal_names in "));
        str.push_str(&format!("let get_signal_value i = List.assoc i signal_values in "));
        str.push_str(&format!(
            "let get_subcomponent_template_name i = List.assoc i subcomponent_template_names in "
        ));
        str.push_str(&format!(
            "let get_subcomponent_instance_name i = List.assoc i subcomponent_instance_names in "
        ));
        str.push_str(&format!("let get_subcomponent_signal_name component_i signal_i = List.assoc signal_i (List.assoc component_i subcomponent_signal_names) in "));
        str.push_str(&self.body.coda_print());
        str

        /*
        // define `circuit_<name>` (which uses `body_<name>`)
        {
            let circuit_name = format!("circuit_{}", self.interface.name);
            let args_strings: Vec<String> = self
                .get_inputs()
                .iter()
                .enumerate()
                .map(|(sig_i, sig_name)| {
                    format!(
                        "(* {} *) {}",
                        sig_name,
                        CodaExpr::Var(CodaVar::Signal(sig_i)).coda_print()
                    )
                })
                .collect();

            let inputs_strings: Vec<String> =
                self.get_inputs().iter().map(|input| format!("Presignal \"{}\"", input)).collect();

            let outputs_strings: Vec<String> = self
                .get_outputs()
                .iter()
                .map(|output| format!("Presignal \"{}\"", output))
                .collect();

            let circuit_constr = format!(
                "Hoare_circuit {{ name= \"{}\"; inputs= [{}]; outputs= [{}]; preconditions= []; postconditions= []; body= {} {} }}",
                self.interface.name,
                inputs_strings.join(" "),
                outputs_strings.join(", "),
                body_name,
                args_strings.join(" ")
            );
            str.push_str(&format!("let {} = {}\n\n", circuit_name, circuit_constr));

        }
        */
    }
}

#[derive(Clone, Debug)]
pub enum CodaExpr {
    Let { var: CodaVar, val: Box<CodaExpr>, body: Box<CodaExpr> },
    Op { op: CodaOp, arg1: Box<CodaExpr>, arg2: Box<CodaExpr> },
    Var(CodaVar),
    Val(CodaVal),
    Branch { condition: Box<CodaExpr>, then_: Box<CodaExpr>, else_: Box<CodaExpr> },
    Tuple(Vec<Box<CodaExpr>>),
}

impl CodaPrint for CodaExpr {
    fn coda_print(&self) -> String {
        match &self {
            CodaExpr::Let { var, val, body } => {
                format!("elet {} {} {}", var.coda_print(), val.coda_print(), body.coda_print())
            }
            CodaExpr::Op { op, arg1, arg2 } => {
                format!("({} {} {})", arg1.coda_print(), op.coda_print(), arg2.coda_print())
            }
            CodaExpr::Var(var) => format!("(var {})", var.coda_print()),
            CodaExpr::Val(val) => val.coda_print(),
            CodaExpr::Branch { condition, then_, else_ } => format!(
                "(if {} then {} else {})",
                condition.coda_print(),
                then_.coda_print(),
                else_.coda_print()
            ),
            CodaExpr::Tuple(es) => {
                format!(
                    "({})",
                    es.iter().map(|e| e.coda_print()).collect::<Vec<String>>().join(", ")
                )
            }
        }
    }
}

#[derive(Clone, Debug)]
pub enum CodaOp {
    Add,
    Sub,
    Mul,
    Div,
    Mod,
    Pow,
}

impl CodaPrint for CodaOp {
    fn coda_print(&self) -> String {
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

#[derive(Clone, Debug)]
pub struct CodaVal {
    value: String,
}

impl CodaVal {
    pub fn new(x: String) -> CodaVal {
        CodaVal { value: x }
    }

    pub fn from_usize(i: usize) -> CodaVal {
        CodaVal { value: format!("{}", i) }
    }
}

impl CodaPrint for CodaVal {
    fn coda_print(&self) -> String {
        self.value.clone()
    }
}

#[derive(Debug, Clone)]
pub enum CodaVisibility {
    Input,
    Output,
    Intermediate,
}

impl FromStr for CodaVisibility {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        if s == "input" {
            Ok(Self::Input)
        } else if s == "output" {
            Ok(Self::Output)
        } else if s == "intermediate" {
            Ok(Self::Intermediate)
        } else {
            panic!("Unrecognized visibility: {}", s)
        }
    }
}

#[derive(Clone, Debug)]
pub enum CodaVar {
    Signal(usize),
    Var(usize),
    SubSignal { subcomponent_index: usize, signal_index: usize },
}

impl CodaPrint for CodaVar {
    fn coda_print(&self) -> String {
        match self {
            CodaVar::Signal(sig_i) => format!("(get_signal_name {})", sig_i),
            CodaVar::Var(var_i) => format!("(get_var_name {})", var_i),
            CodaVar::SubSignal { subcomponent_index, signal_index } => {
                format!("(get_subsignal_name {} {})", subcomponent_index, signal_index)
            }
        }
    }
}

// #[derive(Clone, Debug)]
// pub struct CodaComponentInfo {
//     pub template_id: usize,
//     pub template_name: String,
//     pub component_name: String,
//     pub header_name: String,
//     pub inputs: Vec<String>,
//     pub outputs: Vec<String>,
// }
