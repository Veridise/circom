use std::fs::File;
use serde::Deserialize;

// -----------------------------------------------------------------------------
// Summaries
// -----------------------------------------------------------------------------

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

// -----------------------------------------------------------------------------
// CodaProgram
// -----------------------------------------------------------------------------
//
// A __CodaCircuit__ for a corresponding Circom Template is the Coda encoding of the circuit.
//
// A __CodaGenerator__ for a corresponding CodaCircuit is an OCaml function that inputs the input signals of the circuit and outputs the tuple of output signals of that circuit. It is used to define subcomponents within other CodaCircuits.
//

#[derive(Clone, Debug)]
pub struct CodaProgram {
    pub coda_circuits: Vec<CodaCircuit>,
}

impl Default for CodaProgram {
    fn default() -> CodaProgram {
        CodaProgram { coda_circuits: Vec::new() }
    }
}

#[derive(Clone, Debug)]
pub struct CodaCircuit {
    pub name: String,
    pub signals: Vec<CodaSignal>,
    pub body: CodaStatement,
}

#[derive(Clone, Debug)]
pub struct CodaSignal {
    pub name: CodaSignalName,
    pub visibility: CodaSignalVisibility,
}

#[derive(Clone, Debug)]
pub enum CodaSignalVisibility {
    Input,
    Output,
    Intermediate,
}

impl CodaSignalVisibility {
    pub fn parse(s: &str) -> CodaSignalVisibility {
        use CodaSignalVisibility::*;
        if s == "input" {
            Input
        } else if s == "output" {
            Output
        } else if s == "inter" {
            Input
        } else {
            panic!("Failed to parse CodaSignalVisibility: \"{}\"", s)
        }
    }
}

#[derive(Clone, Debug)]
pub enum CodaStatement {
    // Assign target to source.
    Assignment { target: CodaAssignmentTarget, value: CodaExpr, next: Box<CodaStatement> },
    // Instantiate a template as a subcomponent.
    Instantiate { instance: CodaSubcomponentInstance, next: Box<CodaStatement> },
    // Branch on a condition.
    Branch { condition: CodaExpr, then_: Box<CodaStatement>, else_: Box<CodaStatement> },
    End { output_names: Vec<CodaSignalName> },
}

#[derive(Clone, Debug)]
pub struct CodaSubcomponentName {
    pub value: String,
}

#[derive(Clone, Debug)]
pub struct CodaSubcomponentInstance {
    pub name: CodaSubcomponentName,
    pub template_name: CodaTemplateName,
    pub signals: Vec<CodaSignal>,
    pub args: Vec<String>, // must be literals
}

#[derive(Clone, Debug)]
pub struct CodaGeneratorName {
    pub value: String,
}

#[derive(Clone, Debug)]
pub struct CodaTemplateName {
    pub value: String,
}

#[derive(Clone, Debug)]
pub struct CodaSignalName {
    pub value: String,
}

#[derive(Clone, Debug)]
pub enum CodaAssignmentTarget {
    Signal { signal_name: CodaSignalName },
    SubcomponentSignal { subcomponent_name: CodaSubcomponentName, signal_name: CodaSignalName },
}

#[derive(Clone, Debug)]
pub enum CodaExpr {
    Signal { signal_name: CodaSignalName },
    SubcomponentSignal { subcomponent_name: CodaSubcomponentName, signal_name: CodaSignalName },
    Constant(String),
    Binop(CodaBinop, Box<CodaExpr>, Box<CodaExpr>),
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

// -----------------------------------------------------------------------------
// CodaCompile
// -----------------------------------------------------------------------------

pub fn coda_compile_program(program: &CodaProgram) -> String {
    program.coda_compile(false)
}

trait CodaCompile {
    fn coda_compile(&self, is_generator: bool) -> String;
}

impl CodaCompile for CodaProgram {
    fn coda_compile(&self, is_generator: bool) -> String {
        assert!(is_generator == false);
        let mut s: String = String::new();
        self.coda_circuits.iter().for_each(|circuit| {
            s.push_str(&format!("{}\n\n", circuit.coda_compile(false)));
            s.push_str(&format!("{}\n\n", circuit.coda_compile(true)));
        });
        s
    }
}

impl CodaCompile for CodaSignal {
    fn coda_compile(&self, is_generator: bool) -> String {
        format!("(\"{}\", {})", self.name.coda_compile(is_generator), "field")
    }
}

impl CodaCompile for CodaGeneratorName {
    fn coda_compile(&self, _is_generator: bool) -> String {
        format!("generator___{}", self.value.clone())
    }
}

impl CodaCompile for CodaCircuit {
    fn coda_compile(&self, is_generator: bool) -> String {
        if !is_generator {
            let template_name_string =
                CodaTemplateName { value: self.name.clone() }.coda_compile(is_generator);
            let mut inputs_strings: Vec<String> = Vec::new();
            let mut outputs_strings: Vec<String> = Vec::new();
            self.signals.iter().for_each(|signal| match signal.visibility {
                CodaSignalVisibility::Input => {
                    inputs_strings.push(signal.coda_compile(is_generator))
                }
                CodaSignalVisibility::Output => {
                    outputs_strings.push(signal.coda_compile(is_generator))
                }
                // Intermediate values are not reflected in the Coda interface, they will appear as local definitions within the body.
                CodaSignalVisibility::Intermediate => (),
            });
            let inputs_string = inputs_strings.join("; ");
            let outputs_string = outputs_strings.join("; ");
            let body_string = self.body.coda_compile(is_generator);
            format!("let {} = Hoare_circuit {{ name= \"{}\"; inputs= [{}]; outputs= [{}]; preconditions= []; postcondition= []; body= {} }}", template_name_string, &self.name, &inputs_string, &outputs_string, &body_string)
        } else {
            let generator_name_string =
                CodaGeneratorName { value: self.name.clone() }.coda_compile(is_generator);
            let mut input_name_strings: Vec<String> = Vec::new();
            self.signals.iter().for_each(|signal| match signal.visibility {
                CodaSignalVisibility::Input => {
                    input_name_strings.push(signal.name.coda_compile(is_generator))
                }
                CodaSignalVisibility::Output => (),
                CodaSignalVisibility::Intermediate => (),
            });
            let inputs_string = input_name_strings.join(" ");
            let body_string = self.body.coda_compile(is_generator);
            format!("let {} {} = {}", generator_name_string, inputs_string, body_string)
        }
    }
}

impl CodaCompile for CodaSignalName {
    fn coda_compile(&self, _is_generator: bool) -> String {
        self.value.clone()
    }
}

impl CodaCompile for CodaAssignmentTarget {
    fn coda_compile(&self, is_generator: bool) -> String {
        match self {
            CodaAssignmentTarget::Signal { signal_name } => signal_name.coda_compile(is_generator),
            CodaAssignmentTarget::SubcomponentSignal { subcomponent_name, signal_name } => format!(
                "{}___{}",
                subcomponent_name.coda_compile(is_generator),
                signal_name.coda_compile(is_generator)
            ),
        }
    }
}

impl CodaCompile for CodaTemplateName {
    fn coda_compile(&self, _is_generator: bool) -> String {
        format!("template___{}", self.value)
    }
}

impl CodaCompile for CodaSubcomponentName {
    fn coda_compile(&self, _is_generator: bool) -> String {
        format!("subcomponent___{}", self.value)
    }
}

impl CodaCompile for CodaStatement {
    fn coda_compile(&self, is_generator: bool) -> String {
        match self {
            CodaStatement::Assignment { target, value, next } => {
                format!(
                    "let {} = ({}) in ({})",
                    target.coda_compile(is_generator),
                    value.coda_compile(is_generator),
                    next.coda_compile(is_generator)
                )
            }
            CodaStatement::Instantiate { instance, next } => {
                let output_string = instance
                    .signals
                    .iter()
                    .filter_map(|signal| match signal.visibility {
                        CodaSignalVisibility::Output => Some(
                            CodaAssignmentTarget::SubcomponentSignal {
                                subcomponent_name: instance.name.clone(),
                                signal_name: signal.name.clone(),
                            }
                            .coda_compile(is_generator),
                        ),
                        _ => None,
                    })
                    .collect::<Vec<String>>()
                    .join(", ");
                format!(
                    "let ({}) = {} {} in {}",
                    output_string,
                    instance.template_name.coda_compile(is_generator),
                    instance.args.join(" "),
                    next.coda_compile(is_generator)
                )
            }
            CodaStatement::Branch { condition, then_, else_ } => format!(
                "if ({}) then ({}) else ({})",
                condition.coda_compile(is_generator),
                then_.coda_compile(is_generator),
                else_.coda_compile(is_generator)
            ),
            CodaStatement::End { output_names } => {
                let names: Vec<String> = output_names
                    .iter()
                    .map(|signal_name| signal_name.coda_compile(is_generator))
                    .collect();
                format!("({})", names.join(", "))
            }
        }
    }
}

impl CodaCompile for CodaExpr {
    fn coda_compile(&self, is_generator: bool) -> String {
        match self {
            CodaExpr::Signal { signal_name } => {
                if !is_generator {
                    // Coda-abstracted signal
                    format!("(var \"{}\")", signal_name.coda_compile(is_generator))
                } else {
                    // Generator input
                    signal_name.coda_compile(is_generator)
                }
            }
            CodaExpr::SubcomponentSignal { subcomponent_name, signal_name } => {
                CodaAssignmentTarget::SubcomponentSignal {
                    subcomponent_name: subcomponent_name.clone(),
                    signal_name: signal_name.clone(),
                }
                .coda_compile(is_generator)
            }
            CodaExpr::Constant(string) => string.clone(),
            CodaExpr::Binop(op, e1, e2) => format!(
                "({} {} {})",
                e1.coda_compile(is_generator),
                op.coda_compile(is_generator),
                e2.coda_compile(is_generator)
            ),
        }
    }
}

impl CodaCompile for CodaBinop {
    fn coda_compile(&self, _is_generator: bool) -> String {
        match self {
            CodaBinop::Add => "+",
            CodaBinop::Sub => "-",
            CodaBinop::Mul => "*",
            CodaBinop::Pow => "^",
            CodaBinop::Mod => "%",
            CodaBinop::Div => "/",
        }
        .to_string()
    }
}
