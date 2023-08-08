/*
Example:

```circom
template Foo {
    signal input x;
    signal input y;
    signal output z;
    signal output w;

    ...
}

template Bar {
    signal input a;
    signal output b;
    signal output c;

    component foo = Foo();

    foo.x <== a;
    foo.y <== 7;

    b <== foo.z;
    c <== foo.w;
}
```

```coda
let body_Foo (x, y, z, w) body = ...

let circuit_Foo = Hoare_circuit {..., body= body_Foo ("x", "y", "z", "w") (tuple (var "z", var "w"))}

let body_Bar (a, b, c) body =
    body_Foo ("foo.x", "foo.y", "foo.z", "foo.w") @@
    elet "foo.x" (var a) @@
    elet "foo.y" (lit 7) @@
    elet "b" (var "foo.z") @@
    elet "c" (var "foo.w") @@
    body

let circuit_Bar = Hoare_circuit {..., body= body_Bar ("a", "b", "c") (tuple (var "b", var "c"))}
```

*/

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

pub struct CodaProgram {
    pub templates: Vec<CodaTemplate>,
}

impl CodaProgram {
    pub fn coda_print(&self) -> String {
        let mut str = String::new();

        // TODO: imports

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
    pub fn coda_print_template_name(&self) -> String {
        format!("circuit_{}", self.template_name)
    }

    pub fn coda_print_body_name(&self) -> String {
        format!("body_{}", self.template_name)
    }

    pub fn get_input_signals(&self) -> Vec<CodaTemplateSignal> {
        self.signals
            .iter()
            .filter_map(|signal| match signal.visibility {
                CodaVisibility::Input => Some(signal.clone()),
                _ => None,
            })
            .collect()
    }

    pub fn get_output_signals(&self) -> Vec<CodaTemplateSignal> {
        self.signals
            .iter()
            .filter_map(|signal| match signal.visibility {
                CodaVisibility::Output => Some(signal.clone()),
                _ => None,
            })
            .collect()
    }
}

#[derive(Debug, Clone)]
pub struct CodaTemplateSignal {
    pub name: String,
    pub visibility: CodaVisibility,
}

impl CodaTemplateSignal {
    pub fn to_signal(&self) -> CodaVar {
        CodaVar::Signal(self.name.clone())
    }

    pub fn to_subcomponent_signal(&self, subcomponent_name: &CodaComponentName) -> CodaVar {
        CodaVar::SubcomponentSignal(subcomponent_name.clone(), self.name.clone())
    }

    pub fn print_name_value(&self) -> String {
        self.name.replace("[", "_").replace("]", "")
    }

    pub fn print_name_string(&self) -> String {
        self.name.replace("[", "_").replace("]", "")
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

        str.push_str(&format!(
            "let {} ({}) body = {}\n\n",
            self.interface.coda_print_body_name(),
            self.interface
                .signals
                .iter()
                .map(|signal| signal.print_name_value())
                .collect::<Vec<String>>()
                .join(", "),
            self.body.coda_print()
        ));

        // circuit

        if !self.is_abstract {
            str.push_str(&format!(
                "let {} = Hoare_circuit {{name= \"{}\", inputs= [{}], outputs= [{}], preconditions= [], postconditions= [], dep= None, body= {} ({})}}\n\n",
                self.interface.coda_print_template_name(),
                self.interface.template_name,
                self.interface.get_input_signals().iter().map(|signal| format!("Presignal \"{}\"", signal.print_name_string())).collect::<Vec<String>>().join("; "),
                self.interface.get_output_signals().iter().map(|signal| format!("Presignal \"{}\"", signal.print_name_string())).collect::<Vec<String>>().join("; "),
                self.interface.coda_print_body_name(),
                self.interface
                    .signals
                    .iter()
                    .map(|signal| format!("\"{}\"", signal.print_name_string()))
                    .collect::<Vec<String>>()
                    .join(", ")
            ));
        }
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
                format!("elet {} {} @@ {}", var.print_value(), val.coda_print(), body.coda_print())
            }
            CodaStmt::CreateCmp { subcomponent, body } => format!(
                "{} ({}) @@ {}",
                subcomponent.interface.coda_print_body_name(),
                subcomponent
                    .interface
                    .signals
                    .iter()
                    .map(|signal| signal
                        .to_subcomponent_signal(&subcomponent.component_name)
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
                "assert_in \"_assertion_{}\" {} @@ {}",
                i,
                condition.coda_print(),
                body.coda_print()
            ),
            CodaStmt::AssertEq { i, lhs, rhs, body } => format!(
                "assert_eq_in \"_assertion_{}\" {} {} @@ {}",
                i,
                lhs.coda_print(),
                rhs.coda_print(),
                body.coda_print()
            ),

            CodaStmt::Output => format!("body"),
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
                format!("({} {} {})", arg1.coda_print(), op.coda_print(), arg2.coda_print())
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
    Add,
    Sub,
    Mul,
    Div,
    Mod,
    Pow,
    Eq,
}

impl CodaOp {
    pub fn coda_print(&self) -> String {
        match &self {
            CodaOp::Add => "+".to_string(),
            CodaOp::Sub => "-".to_string(),
            CodaOp::Mul => "*".to_string(),
            CodaOp::Div => "/".to_string(),
            CodaOp::Mod => "%".to_string(),
            CodaOp::Pow => "^".to_string(),
            CodaOp::Eq => "=.".to_string(),
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
        // For reference:
        //      type const = CNil | CUnit | CInt of big_int | CF of big_int | CBool of bool
        format!("(F.const {})", self.value)
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

// #[derive(Clone, Debug)]
// pub struct CodaVar {
//     pub name: String,
//     pub is_subcomponent_signal: bool,
// }

#[derive(Clone, Debug)]
pub enum CodaVar {
    Signal(String),
    Variable(String),
    SubcomponentSignal(CodaComponentName, String),
}

impl CodaVar {
    // pub fn make_signal(name: &String) -> Self {
    //     println!("make_signal({})", name);
    //     Self { name: name.clone(), is_subcomponent_signal: false }
    // }
    // pub fn make_variable(name: &String) -> Self {
    //     println!("make_variable({})", name);
    //     Self { name: name.clone(), is_subcomponent_signal: false }
    // }
    // pub fn make_subcomponent_signal(
    //     subcomponent_name: &CodaComponentName,
    //     signal_name: &str,
    // ) -> Self {
    //     println!("make_subcomponent_signal({:?}, {})", subcomponent_name, signal_name);
    //     Self {
    //         name: format!("{}_{}", subcomponent_name.print(), signal_name),
    //         is_subcomponent_signal: true,
    //     }
    // }

    pub fn print_value(&self) -> String {
        // Example: xs[0][1] ~~> x_0_1
        match self {
            CodaVar::Signal(name) => name.replace("[", "_").replace("]", ""),
            CodaVar::Variable(name) => format!("\"{}\"", name.replace("[", "_").replace("]", "")),
            CodaVar::SubcomponentSignal(subcomponent_name, name) => {
                format!(
                    "\"{}_{}\"",
                    subcomponent_name.print(),
                    name.replace("[", "_").replace("]", "")
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
