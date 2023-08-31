use std::str::FromStr;

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaCircuitData {
    pub field_tracking: Vec<String>,
}

impl Default for CodaCircuitData {
    fn default() -> Self {
        CodaCircuitData { field_tracking: Vec::new() }
    }
}

pub struct CodaProgram {
    pub templates: Vec<CodaTemplate>,
}

enum CodaCircuitMode {
    Normal,
    Hoare,
}

static CODA_CIRCUIT_MODE: CodaCircuitMode = CodaCircuitMode::Normal;

impl CodaProgram {
    pub fn coda_print(&self) -> String {
        let mut str = String::new();

        let imports: Vec<&str> = match CODA_CIRCUIT_MODE {
            CodaCircuitMode::Normal => {
                vec!["Ast", "Dsl", "Nice_dsl", "Expr", "Qual", "Typ", "TypRef"]
            }
            CodaCircuitMode::Hoare => {
                vec!["Ast", "Dsl", "Nice_dsl", "Expr", "Qual", "Typ", "TypRef", "Hoare_circuit"]
            }
        };

        for import_str in imports {
            str.push_str(&format!("open {}\n", import_str));
        }

        str.push_str("\n");

        for template in &self.templates {
            str.push_str(&format!("{}\n", &template.coda_print()))
        }

        str
    }
}

impl Default for CodaProgram {
    fn default() -> Self {
        CodaProgram { templates: Vec::new() }
    }
}

#[derive(Debug, Clone)]
pub struct CodaTemplateName {
    pub name: String,
}

impl CodaTemplateName {
    pub fn print(&self) -> &String {
        &self.name
    }

    pub fn coda_print(&self) -> String {
        format!("circuit_{}", self.name)
    }
}

#[derive(Debug, Clone)]
pub struct CodaTemplateInterface {
    pub template_id: usize,
    pub template_name: String,
    pub signals: Vec<CodaTemplateSignal>,
    pub variables: Vec<String>,
}

impl CodaTemplateInterface {
    pub fn coda_print_abstract_function_name(&self) -> String {
        self.template_name.clone()
    }

    pub fn coda_print_template_name(&self) -> String {
        format!("circuit_{}", self.template_name)
    }

    pub fn coda_print_body_name(&self) -> String {
        format!("body_{}", self.template_name)
    }

    pub fn get_input_signals(&self) -> Vec<CodaTemplateSignal> {
        self.signals.iter().filter(|signal| signal.visibility.is_input()).cloned().collect()
    }

    pub fn get_output_signals(&self) -> Vec<CodaTemplateSignal> {
        self.signals.iter().filter(|signal| signal.visibility.is_output()).cloned().collect()
    }
}

#[derive(Debug, Clone)]
pub struct CodaTemplateSignal {
    pub name: String,
    pub visibility: CodaVisibility,
}

impl CodaTemplateSignal {
    pub fn to_var(&self) -> CodaVar {
        CodaVar::Signal(self.clone())
    }

    pub fn to_subcomponent_signal(
        &self,
        subcomponent_name: &CodaComponentName,
        subcomponent_index: usize,
    ) -> CodaVar {
        CodaVar::SubcomponentSignal(
            subcomponent_name.clone(),
            subcomponent_index,
            self.name.clone(),
        )
    }

    pub fn print_name_value(&self) -> String {
        string_to_ocaml_name(&self.name)
    }

    pub fn print_name_string(&self) -> String {
        string_to_ocaml_name(&self.name)
    }
}

const OCAML_NAME_RESERVEDS: [&'static str; 2] = [&"in", &"let"];

fn string_to_ocaml_name(s: &str) -> String {
    let s = s.replace("[", "_").replace("]", "");
    if OCAML_NAME_RESERVEDS.contains(&s.as_str()) {
        format!("{}_", s)
    } else {
        s
    }
}

#[derive(Debug, Clone)]
pub struct CodaTemplate {
    pub interface: CodaTemplateInterface,
    pub body: CodaStmt,
    pub is_abstract: bool,
}

#[derive(Debug, Clone)]
pub struct CodaTemplateSubcomponent {
    pub interface: CodaTemplateInterface,
    pub component_name: CodaComponentName,
    pub component_index: usize,
}

impl CodaTemplate {
    pub fn get_input_signals(&self) -> Vec<CodaTemplateSignal> {
        self.interface.get_input_signals()
    }
    pub fn get_output_signals(&self) -> Vec<CodaTemplateSignal> {
        self.interface.get_output_signals()
    }

    pub fn coda_print(&self) -> String {
        let mut str = String::new();

        // body

        if !self.is_abstract {
            str.push_str(&format!(
                "let {} prefix ({}) output =\n  {}\n\n",
                self.interface.coda_print_body_name(),
                self.interface
                    .signals
                    .iter()
                    .filter(|signal| signal.visibility.isnt_intermediate())
                    .map(|signal| signal.print_name_value())
                    .collect::<Vec<String>>()
                    .join(", "),
                self.body.coda_print()
            ))
        } else {
            let inputs = self
                .interface
                .signals
                .iter()
                .filter(|signal| signal.visibility.is_input())
                .collect::<Vec<_>>();

            let outputs = self
                .interface
                .signals
                .iter()
                .filter(|signal| signal.visibility.is_output())
                .collect::<Vec<_>>();

            if outputs.len() == 1 {
                let output = outputs[0];
                let output_var = output.to_var();
                str.push_str(&format!(
                    "let {} prefix ({}) output =\n  elet {} (call \"{}\" [{}]) @@\n  output\n\n",
                    self.interface.coda_print_body_name(),
                    self.interface
                        .signals
                        .iter()
                        .filter(|signal| signal.visibility.isnt_intermediate())
                        .map(|signal| signal.print_name_value())
                        .collect::<Vec<_>>()
                        .join(", "),
                    output_var.print_value(),
                    self.interface.coda_print_abstract_function_name(),
                    inputs
                        .iter()
                        .map(|signal| CodaExpr::Var(signal.to_var()).coda_print())
                        .collect::<Vec<_>>()
                        .join("; "),
                ));
            } else {
                let tuple_var = CodaVar::Variable(CodaVariable {
                    name: format!("__tuple__{}", self.interface.template_name),
                    fresh_index: 0,
                });

                let mut binds_str: String = String::new();
                // let mut results_strs: Vec<String> = Vec::new();

                for (output_i, output) in outputs.iter().enumerate() {
                    let component_var = output.to_var();
                    binds_str.push_str(&format!(
                        "elet {} (project {} {}) @@\n  ",
                        component_var.print_value(),
                        CodaExpr::Var(tuple_var.clone()).coda_print(),
                        output_i
                    ));
                    // results_strs.push(CodaExpr::Var(component_var).coda_print());
                }

                // let result_str = format!("(tuple [{}])", results_strs.join("; "));

                str.push_str(&format!(
                    "let {} prefix ({}) output =\n  elet {} (call \"{}\" [{}]) @@\n  {}{}\n\n",
                    self.interface.coda_print_body_name(),
                    self.interface
                        .signals
                        .iter()
                        .filter(|signal| signal.visibility.isnt_intermediate())
                        .map(|signal| signal.print_name_value())
                        .collect::<Vec<_>>()
                        .join(", "),
                    tuple_var.print_name_string(),
                    self.interface.coda_print_abstract_function_name(),
                    inputs
                        .iter()
                        .map(|signal| CodaExpr::Var(signal.to_var()).coda_print())
                        .collect::<Vec<_>>()
                        .join("; "),
                    binds_str,
                    "output"
                ));
            }
        }

        // circuit

        match CODA_CIRCUIT_MODE {
            CodaCircuitMode::Normal => {
                str.push_str(&format!(
                    "let {} =\n  Circuit\n    {{ name= \"{}\"\n    ; inputs= [{}]\n    ; outputs= [{}]\n    ; dep=None\n    ; body= let prefix = {} in {} prefix ({}) (Expr.tuple [{}]) }}\n\n",
                    // ocaml name
                    self.interface.coda_print_template_name(),
                    // template name
                    self.interface.template_name,
                    // input and output signals, where each signals is a tuple of its name (string) and type (must be a `field`, but can be refined manually)
                    // inputs
                    self.interface.get_input_signals().iter().map(|signal| format!("(\"{}\", field)", signal.print_name_string())).collect::<Vec<String>>().join("; "),
                    // outputs
                    self.interface.get_output_signals().iter().map(|signal| format!("(\"{}\", field)", signal.print_name_string())).collect::<Vec<String>>().join("; "),
                    // body prefix
                    "\"main_\"",
                    // body name
                    self.interface.coda_print_body_name(),
                    // inputs signals' names
                    self.interface
                        .signals
                        .iter()
                        .filter(|signal| signal.visibility.isnt_intermediate())
                        .map(|signal| format!("\"{}\"", signal.print_name_string()))
                        .collect::<Vec<String>>()
                        .join(", "),
                    // tuple of the output signals (as expressions)
                    self.interface.signals.iter().filter_map(|signal| match signal.visibility {
                        // CodaVisibility::Output => Some(CodaExpr::Var(CodaVar::Variable(CodaVariable{ name: signal.print_name_string(), fresh_index: 0})).coda_print()),
                        // CodaVisibility::Output => Some(CodaVar::Signal(signal.print_name_string()).print_name_string()),
                        CodaVisibility::Output => Some(signal.print_name_string()),
                        _ => None
                    })
                    .collect::<Vec<String>>()
                    .join("; ")
                ))
            }
            CodaCircuitMode::Hoare => {
                // str.push_str(&format!(
                //     "let {} = Hoare_circuit.to_circuit @@\n  Hoare_circuit {{\n  name= \"{}\";\n  inputs= [{}];\n  outputs= [{}];\n  preconditions= [];\n  postconditions= [];\n  body=\n  {} ({}) (Expr.tuple [{}]) }}\n\n",
                //     // ocaml name
                //     self.interface.coda_print_template_name(),
                //     // template name
                //     self.interface.template_name,
                //     // inputs
                //     self.interface.get_input_signals().iter().map(|signal| format!("Presignal \"{}\"", signal.print_name_string())).collect::<Vec<String>>().join("; "),
                //     // outputs
                //     self.interface.get_output_signals().iter().map(|signal| format!("Presignal \"{}\"", signal.print_name_string())).collect::<Vec<String>>().join("; "),
                //     // apply body to ...
                //     self.interface.coda_print_body_name(),
                //     // inputs signals' names
                //     self.interface
                //         .signals
                //         .iter()
                //         .map(|signal| format!("\"{}\"", signal.print_name_string()))
                //         .collect::<Vec<String>>()
                //         .join(", "),
                //     // tuple of the output signals (as expressions)
                //     self.interface.signals.iter().filter_map(|signal| match signal.visibility {
                //         CodaVisibility::Output => Some(CodaExpr::Var(CodaVar::Variable(CodaVariable {name: signal.print_name_string(), fresh_index: 0})).coda_print()),
                //         _ => None
                //     })
                //     .collect::<Vec<String>>()
                //     .join("; ")
                // ));
                todo!("temporarily disabled Hoare mode")
            }
        };

        str
    }
}

#[derive(Clone, Debug)]
pub enum CodaStmt {
    Let { var: CodaVar, val: Box<CodaExpr>, body: Box<CodaStmt> },
    CreateCmp { subcomponent: CodaTemplateSubcomponent, body: Box<CodaStmt> },
    Branch { condition: Box<CodaExpr>, then_: Box<CodaStmt>, else_: Box<CodaStmt> },
    Assert { i: usize, condition: Box<CodaExpr>, body: Box<CodaStmt> },
    AssertEq { i: usize, lhs: Box<CodaExpr>, rhs: Box<CodaExpr>, body: Box<CodaStmt> },
    Output,
}

impl CodaStmt {
    pub fn coda_print(&self) -> String {
        match self {
            CodaStmt::Let { var, val, body } => {
                format!(
                    "elet {} {} @@\n  {}",
                    var.print_value(),
                    val.coda_print(),
                    body.coda_print()
                )
            }
            CodaStmt::CreateCmp { subcomponent, body } => format!(
                "{} Base.(prefix ^ \"sc{}_\") ({}) @@\n  {}",
                subcomponent.interface.coda_print_body_name(),
                subcomponent.component_index,
                subcomponent
                    .interface
                    .signals
                    .iter()
                    .filter(|signal| signal.visibility.isnt_intermediate())
                    .map(|signal| signal
                        .to_subcomponent_signal(
                            &subcomponent.component_name,
                            subcomponent.component_index,
                        )
                        .print_value())
                    .collect::<Vec<String>>()
                    .join(", "),
                body.coda_print()
            ),
            CodaStmt::Branch { condition, then_, else_ } => format!(
                "(if {} then {} else {})",
                condition.coda_print(),
                then_.coda_print(),
                else_.coda_print()
            ),
            CodaStmt::Assert { i, condition, body } => format!(
                "assert_in \"_assertion_{}\" {} @@\n  {}",
                i,
                condition.coda_print(),
                body.coda_print()
            ),
            CodaStmt::AssertEq { i, lhs, rhs, body } => format!(
                "assert_eq_in \"_assertion_{}\" {} {} @@\n  {}",
                i,
                lhs.coda_print(),
                rhs.coda_print(),
                body.coda_print()
            ),

            CodaStmt::Output => format!("output"),
        }
    }
}

#[derive(Clone, Debug)]
pub enum CodaNumType {
    Nat,
    Field,
    Int,
}

impl CodaNumType {
    pub fn coda_print_module_name(&self) -> &str {
        match self {
            CodaNumType::Nat => "N",
            CodaNumType::Field => "F",
            CodaNumType::Int => "Z",
        }
    }
}

#[derive(Clone, Debug)]
pub enum CodaExpr {
    Op { op: CodaOp, arg1: Box<CodaExpr>, arg2: Box<CodaExpr> },
    Var(CodaVar),
    Val(CodaVal),
    Tuple(Vec<Box<CodaExpr>>),
    Star,
}

impl CodaExpr {
    pub fn coda_print(&self) -> String {
        match &self {
            CodaExpr::Op { op, arg1, arg2 } => {
                op.coda_print(&arg1.coda_print(), &arg2.coda_print())
            }
            CodaExpr::Var(var) => format!("(var {})", var.print_value()),
            CodaExpr::Val(val) => val.coda_print(),
            CodaExpr::Tuple(es) => {
                format!(
                    "({})",
                    es.iter().map(|e| e.coda_print()).collect::<Vec<String>>().join(", ")
                )
            }
            CodaExpr::Star => format!("star"),
        }
    }
}

#[derive(Clone, Debug)]
pub enum CodaOp {
    Add(CodaNumType),
    Sub(CodaNumType),
    Mul(CodaNumType),
    Pow(CodaNumType),
    Div,
    Mod,
    Eq,
}

impl CodaOp {
    pub fn coda_print_without_prefix(op_str: &str, x: &str, y: &str) -> String {
        format!("({} {} {})", x, op_str, y)
    }
    pub fn coda_print_with_prefix(pre: &str, op_str: &str, x: &str, y: &str) -> String {
        format!("{}.({} {} {})", pre, x, op_str, y)
    }

    pub fn coda_print(&self, x: &str, y: &str) -> String {
        match self {
            CodaOp::Add(nt) => {
                CodaOp::coda_print_with_prefix(nt.coda_print_module_name(), "+", x, y)
            }
            CodaOp::Sub(nt) => {
                CodaOp::coda_print_with_prefix(nt.coda_print_module_name(), "-", x, y)
            }
            CodaOp::Mul(nt) => {
                CodaOp::coda_print_with_prefix(nt.coda_print_module_name(), "*", x, y)
            }
            CodaOp::Pow(nt) => {
                CodaOp::coda_print_with_prefix(nt.coda_print_module_name(), "^", x, y)
            }
            CodaOp::Div => CodaOp::coda_print_without_prefix("/", x, y),
            CodaOp::Mod => CodaOp::coda_print_without_prefix("%", x, y),
            CodaOp::Eq => CodaOp::coda_print_without_prefix("==", x, y),
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

    pub fn coda_print(&self) -> String {
        // TODO: need to reason about what type the constant _should_ be in order to satisfy typing
        format!("(F.const {})", self.value)
    }
}

#[derive(Debug, Clone)]
pub enum CodaVisibility {
    Input,
    Output,
    Intermediate,
}

impl CodaVisibility {
    pub fn isnt_intermediate(&self) -> bool {
        match self {
            CodaVisibility::Input => true,
            CodaVisibility::Output => true,
            CodaVisibility::Intermediate => false,
        }
    }

    /// Returns `true` if the coda visibility is [`Input`].
    ///
    /// [`Input`]: CodaVisibility::Input
    #[must_use]
    pub fn is_input(&self) -> bool {
        matches!(self, Self::Input)
    }

    /// Returns `true` if the coda visibility is [`Output`].
    ///
    /// [`Output`]: CodaVisibility::Output
    #[must_use]
    pub fn is_output(&self) -> bool {
        matches!(self, Self::Output)
    }

    /// Returns `true` if the coda visibility is [`Intermediate`].
    ///
    /// [`Intermediate`]: CodaVisibility::Intermediate
    #[must_use]
    pub fn is_intermediate(&self) -> bool {
        matches!(self, Self::Intermediate)
    }
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

// #[derive(Clone, Debug)]
// pub struct CodaVar {
//     pub name: String,
//     pub is_subcomponent_signal: bool,
// }

#[derive(Clone, Debug)]
pub enum CodaVar {
    Signal(CodaTemplateSignal),
    Variable(CodaVariable),
    SubcomponentSignal(CodaComponentName, usize, String),
}

#[derive(Clone, Debug)]
pub struct CodaVariable {
    pub name: String,
    pub fresh_index: usize,
}

impl CodaVar {
    pub fn print_name_string(&self) -> String {
        match self {
            CodaVar::Signal(signal) => format!("\"{}\"", string_to_ocaml_name(&signal.name)),
            CodaVar::Variable(CodaVariable { name, fresh_index }) => {
                if *fresh_index == 0 {
                    format!("Base.(prefix ^ \"{}\")", string_to_ocaml_name(name))
                } else {
                    format!("Base.(prefix ^ \"{}_{}\")", string_to_ocaml_name(name), fresh_index)
                }
            }
            CodaVar::SubcomponentSignal(subcomponent_name, subcomponent_index, name) => {
                format!(
                    "\"{}_{}_{}\"",
                    subcomponent_name.print(),
                    subcomponent_index,
                    string_to_ocaml_name(name)
                )
            }
        }
    }

    pub fn print_value(&self) -> String {
        // Example: xs[0][1] ~~> x_0_1
        match self {
            // CodaVar::Signal(signal) => string_to_ocaml_name(&signal.name),
            CodaVar::Signal(signal) => {
                if signal.visibility.isnt_intermediate() {
                    string_to_ocaml_name(&signal.name)
                } else {
                    format!("Base.(prefix ^ \"{}\")", string_to_ocaml_name(&signal.name))
                }
            }
            CodaVar::Variable(CodaVariable { name, fresh_index }) => {
                if *fresh_index == 0 {
                    format!("Base.(prefix ^ \"{}\")", string_to_ocaml_name(name))
                } else {
                    format!("Base.(prefix ^ \"{}_{}\")", string_to_ocaml_name(name), fresh_index)
                }
            }
            CodaVar::SubcomponentSignal(subcomponent_name, subcomponent_index, name) => {
                format!(
                    "\"{}_{}_{}\"",
                    subcomponent_name.print(),
                    subcomponent_index,
                    string_to_ocaml_name(name)
                )
            }
        }
    }
}

#[derive(Debug, Clone)]
pub struct CodaComponentName {
    pub name: String,
}

impl CodaComponentName {
    pub fn new(name: String) -> Self {
        Self { name }
    }

    pub fn print(&self) -> &String {
        &self.name
    }

    pub fn coda_print(&self) -> String {
        format!("body_{}", self.print())
    }
}

/*
fn commas(xs: Iter<'_, String>) -> String {
    xs.map(|x| x.clone()).collect::<Vec<String>>().join(", ")
}

fn spaces(xs: Iter<'_, String>) -> String {
    xs.map(|x| x.clone()).collect::<Vec<String>>().join(" ")
}

fn semis(xs: Iter<'_, String>) -> String {
    xs.map(|x| x.clone()).collect::<Vec<String>>().join("; ")
}
*/