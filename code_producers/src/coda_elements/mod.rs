mod mod_old;
pub mod config;
pub mod summary;
pub mod ocaml;

use std::str::FromStr;

use self::ocaml::*;

// CodaCircuitData

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaCircuitData {
    pub field_tracking: Vec<String>,
}

impl Default for CodaCircuitData {
    fn default() -> Self {
        CodaCircuitData { field_tracking: Vec::new() }
    }
}

// CodaProgram

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaProgram {
    pub templates: Vec<CodaTemplate>,
}

impl CodaProgram {
    pub fn coda_compile(&self) -> OcamlMod {
        println!("CodaProgram::coda_compile");
        let stmts = self.templates.iter().map(|template| template.coda_compile()).collect();
        OcamlMod { stmts }
    }
}

impl Default for CodaProgram {
    fn default() -> Self {
        CodaProgram { templates: Vec::new() }
    }
}

// CodaTemplate

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaTemplate {
    pub interface: CodaTemplateInterface,
    pub body: Option<CodaStmt>,
}

impl CodaTemplate {
    pub fn coda_compile(&self) -> OcamlStmt {
        println!("CodaTemplate::coda_compile: name = {}", self.interface.name.string);

        let inputs = self
            .interface
            .signals
            .iter()
            .filter(|signal| signal.visibility.is_input())
            .map(|signal| {
                OcamlExpr::tuple(vec![
                    signal.coda_compile_string(),
                    // start by assuming all signals have type `field`
                    OcamlExpr::coda_field(),
                ])
            })
            .collect();

        println!("CodaTemplate::coda_compile: inputs = {:?}", inputs);

        let outputs = self
            .interface
            .signals
            .iter()
            .filter(|signal| signal.visibility.is_output())
            .map(|signal| {
                OcamlExpr::tuple(vec![
                    signal.coda_compile_string(),
                    // start by assuming all signals have type `field`
                    OcamlExpr::coda_field(),
                ])
            })
            .collect();

        println!("CodaTemplate::coda_compile: outputs = {:?}", outputs);

        match &self.body {
            Some(body) => OcamlStmt::Define(
                self.interface.name.coda_compile_name(),
                OcamlExpr::coda_circuit(
                    self.interface.name.coda_compile_circuit_name(),
                    inputs,
                    outputs,
                    body.coda_compile(),
                ),
            ),
            None => OcamlStmt::Comment(format!(
                "The circuit \"{}\" is uninterpreted",
                self.interface.name.string
            )),
        }
    }
}

// CodaTemplateInterface

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaTemplateInterface {
    pub id: usize,
    pub name: CodaTemplateName,
    pub signals: Vec<CodaSignal>,
    pub variable_names: Vec<String>,
    pub is_uninterpreted: bool,
}

// CodaTemplateSignal

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaSignal {
    pub string: String,
    pub visibility: CodaTemplateSignalVisibility,
}

impl CodaSignal {
    pub fn coda_compile_string(&self) -> OcamlExpr {
        OcamlExpr::coda_name_string(&self.string)
    }

    pub fn to_coda_subcomponent_signal(
        &self,
        subcomponent: &CodaSubcomponent,
    ) -> CodaSubcomponentSignal {
        CodaSubcomponentSignal { subcomponent: subcomponent.clone(), signal: self.clone() }
    }

    pub fn to_coda_expr(&self) -> CodaExpr {
        CodaExpr::Named(CodaNamed::Signal(self.clone()))
    }

    fn coda_compile_expr(&self) -> OcamlExpr {
        OcamlExpr::coda_var(self.coda_compile_string())
    }
}

// CodaVisibility

#[derive(Debug, PartialEq, Eq, Clone)]
pub enum CodaTemplateSignalVisibility {
    Input,
    Output,
    Intermediate,
}

impl CodaTemplateSignalVisibility {
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

    /// Returns `false` if the coda visibility is [`Intermediate`].
    ///
    /// [`Intermediate`]: CodaVisibility::Intermediate
    #[must_use]
    pub fn isnt_intermediate(&self) -> bool {
        !matches!(self, Self::Intermediate)
    }
}

impl FromStr for CodaTemplateSignalVisibility {
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

// CodaSubcomponent

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaSubcomponent {
    pub interface: CodaTemplateInterface,
    pub name: CodaComponentName,
    pub index: usize,
}

// CodaStmt

#[derive(Debug, PartialEq, Eq, Clone)]
pub enum CodaStmt {
    Define(CodaNamed, CodaExpr, Box<CodaStmt>),
    CallSubcomponent(CodaSubcomponent, Box<CodaStmt>),
    AssertEqual(u32, CodaExpr, CodaExpr, Box<CodaStmt>),
    Output(CodaExpr),
}

impl CodaStmt {
    fn coda_compile(&self) -> OcamlExpr {
        println!("CodaStmt::coda_compile: self = {:?}", self);
        match self {
            CodaStmt::Define(n, e, s) => {
                OcamlExpr::coda_let(n.coda_compile_string(), e.coda_compile(), s.coda_compile())
            }
            CodaStmt::CallSubcomponent(cmp, s) => {
                let inputs: Vec<_> = cmp
                    .interface
                    .signals
                    .iter()
                    .filter(|signal| signal.visibility.is_input())
                    .map(|signal| signal.to_coda_subcomponent_signal(cmp).coda_compile())
                    .collect();

                let result_string = format!("{}_result", cmp.name.string);

                let mut body = s.coda_compile();

                let outputs: Vec<_> = cmp
                    .interface
                    .signals
                    .iter()
                    .filter(|signal| signal.visibility.is_output())
                    .collect();

                if outputs.len() == 1 {
                    let output = &outputs[0];
                    body = OcamlExpr::coda_let(
                        output.to_coda_subcomponent_signal(cmp).coda_compile_string(),
                        OcamlExpr::coda_var(OcamlExpr::coda_name_string(&result_string)),
                        body,
                    );
                } else {
                    // reverse order, since we are wrapping the body in-to-out
                    for (output_i, output) in outputs.iter().rev().enumerate() {
                        body = OcamlExpr::coda_let(
                            output.to_coda_subcomponent_signal(cmp).coda_compile_string(),
                            OcamlExpr::coda_project(
                                OcamlExpr::coda_var(OcamlExpr::coda_name_string(&result_string)),
                                OcamlExpr::number(&output_i.to_string()),
                            ),
                            body,
                        );
                    }
                }

                OcamlExpr::coda_let(
                    OcamlExpr::coda_name_string(&result_string),
                    OcamlExpr::coda_call(&cmp.interface.name.string, inputs),
                    body,
                )
            }
            CodaStmt::AssertEqual(i, e1, e2, s) => OcamlExpr::coda_let(
                OcamlExpr::coda_fresh_string(i),
                OcamlExpr::coda_assert_eq(e1.coda_compile(), e2.coda_compile()),
                s.coda_compile(),
            ),
            CodaStmt::Output(e) => e.coda_compile(),
        }
    }
}

// CodaExpr

#[derive(Debug, PartialEq, Eq, Clone)]
pub enum CodaExpr {
    Named(CodaNamed),
    Value(CodaValue),
    Op(CodaOp, Vec<Box<CodaExpr>>),
    Tuple(Vec<Box<CodaExpr>>),
    Call(String, Vec<Box<CodaExpr>>),
    Star,
}

impl CodaExpr {
    pub fn coda_tuple_or_single(es: Vec<CodaExpr>) -> CodaExpr {
        if es.len() == 1 {
            es[0].clone()
        } else {
            let mut es_new = Vec::new();
            for e in es {
                es_new.push(Box::new(e))
            }
            CodaExpr::Tuple(es_new)
        }
    }

    pub fn coda_compile(&self) -> OcamlExpr {
        println!("CodaExpr::coda_compile: self = {:?}", self);
        match self {
            CodaExpr::Named(n) => n.coda_compile_expr(),
            CodaExpr::Value(v) => v.coda_compile(),
            CodaExpr::Op(op, es) => {
                OcamlExpr::op(op.coda_compile(), es.iter().map(|e| e.coda_compile()).collect())
            }
            CodaExpr::Tuple(es) => {
                OcamlExpr::coda_tuple(es.iter().map(|e| e.coda_compile()).collect())
            }
            CodaExpr::Call(f, es) => {
                let mut es_new = Vec::new();
                for e in es {
                    es_new.push(e.coda_compile())
                }
                OcamlExpr::coda_call(f, es_new)
            }
            CodaExpr::Star => OcamlExpr::coda_star(),
        }
    }
}

// CodaName

#[derive(Debug, PartialEq, Eq, Clone)]
pub enum CodaNamed {
    Signal(CodaSignal),
    SubcomponentSignal(CodaSubcomponentSignal),
    Variable(CodaVariable),
}

impl CodaNamed {
    fn coda_compile_expr(&self) -> OcamlExpr {
        println!("CodaNamed::coda_compile: self = {:?}", self);
        match &self {
            CodaNamed::Signal(s) => s.coda_compile_expr(),
            CodaNamed::SubcomponentSignal(s) => s.coda_compile(),
            CodaNamed::Variable(x) => x.coda_compile(),
        }
    }

    fn coda_compile_string(&self) -> OcamlExpr {
        match &self {
            CodaNamed::Signal(s) => s.coda_compile_string(),
            CodaNamed::SubcomponentSignal(s) => s.coda_compile_string(),
            CodaNamed::Variable(x) => x.coda_compile_string(),
        }
    }
}

// CodaSubcomponentSignal

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaSubcomponentSignal {
    pub subcomponent: CodaSubcomponent,
    pub signal: CodaSignal,
}

impl CodaSubcomponentSignal {
    fn to_string(&self) -> String {
        format!("{}_dot_{}", self.subcomponent.name.string, self.signal.string)
    }

    fn coda_compile(&self) -> OcamlExpr {
        OcamlExpr::coda_var(OcamlExpr::coda_name_string(&self.to_string()))
    }

    fn coda_compile_string(&self) -> OcamlExpr {
        OcamlExpr::coda_name_string(&self.to_string())
    }
}

// CodaVariable

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaVariable {
    pub fresh_index: usize,
    pub string: String,
}

impl CodaVariable {
    fn coda_compile(&self) -> OcamlExpr {
        OcamlExpr::coda_var(OcamlExpr::coda_name_string(&self.to_string()))
    }

    fn coda_compile_string(&self) -> OcamlExpr {
        OcamlExpr::coda_name_string(&self.to_string())
    }

    fn to_string(&self) -> String {
        if self.fresh_index > 0 {
            format!("{}_v{}", self.string, self.fresh_index)
        } else {
            format!("{}", self.string)
        }
    }
}

// CodaValue

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaValue {
    pub string: String,
}

impl CodaValue {
    pub fn new(str: &str) -> CodaValue {
        for c in str.chars() {
            assert!(c.is_digit(10))
        }
        CodaValue { string: str.to_string() }
    }

    fn coda_compile(&self) -> OcamlExpr {
        OcamlExpr::coda_val(&self.string)
    }
}

// CodaOp

#[derive(Debug, PartialEq, Eq, Clone)]
pub enum CodaOp {
    Add,
    Sub,
    Mul,
    Pow,
    Div,
    Mod,
}

impl CodaOp {
    pub fn coda_compile(&self) -> OcamlOp {
        match &self {
            CodaOp::Add => OcamlOp::new(Some(OcamlName::coda_module_field()), "+"),
            CodaOp::Sub => OcamlOp::new(Some(OcamlName::coda_module_field()), "-"),
            CodaOp::Mul => OcamlOp::new(Some(OcamlName::coda_module_field()), "*"),
            CodaOp::Pow => OcamlOp::new(Some(OcamlName::coda_module_field()), "^"),
            CodaOp::Div => OcamlOp::new(Some(OcamlName::coda_module_field()), "/"),
            CodaOp::Mod => OcamlOp::new(Some(OcamlName::coda_module_field()), "%"),
        }
    }
}

// CodaTemplateName

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaTemplateName {
    pub string: String,
}

impl CodaTemplateName {
    pub fn new(string: String) -> Self {
        Self { string }
    }

    fn coda_compile_circuit_name(&self) -> OcamlExpr {
        OcamlExpr::string(&self.string)
    }

    fn coda_compile_name(&self) -> OcamlName {
        OcamlName::new(&format!("circuit_{}", self.string))
    }
}

// CodaComponentName

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaComponentName {
    pub string: String,
}

impl CodaComponentName {
    pub fn new(string: String) -> Self {
        Self { string }
    }

    pub fn coda_compile(&self) -> OcamlName {
        OcamlName { string: self.string.clone() }
    }
}

// OcamlExpr

impl OcamlExpr {
    pub fn coda_val(str: &str) -> OcamlExpr {
        OcamlExpr::app(
            OcamlName::coda_module_field().sub(&OcamlName::new("const")),
            vec![OcamlExpr::number(str)],
        )
    }

    pub fn coda_name_string(str: &str) -> OcamlExpr {
        OcamlExpr::string(&str.replace("[", "_i").replace("]", ""))
    }

    pub fn coda_project(tuple: OcamlExpr, index: OcamlExpr) -> OcamlExpr {
        OcamlExpr::app(OcamlName::new("project"), vec![tuple, index])
    }

    pub fn coda_field() -> OcamlExpr {
        OcamlExpr::var(OcamlName::new("field"))
    }

    pub fn coda_var(e: OcamlExpr) -> OcamlExpr {
        OcamlExpr::app(OcamlName::new("var"), vec![e])
    }

    pub fn coda_star() -> OcamlExpr {
        OcamlExpr::var(OcamlName::new("star"))
    }

    pub fn coda_tuple(es: Vec<OcamlExpr>) -> OcamlExpr {
        OcamlExpr::app(
            OcamlName::coda_module_expr().sub(&OcamlName::new("tuple")),
            vec![OcamlExpr::list(es)],
        )
    }

    pub fn coda_let(x: OcamlExpr, e1: OcamlExpr, e2: OcamlExpr) -> OcamlExpr {
        OcamlExpr::app(OcamlName::new("elet"), vec![x, e1, e2])
    }

    pub fn coda_assert_eq(e1: OcamlExpr, e2: OcamlExpr) -> OcamlExpr {
        OcamlExpr::app(OcamlName::new("assert_eq"), vec![e1, e2])
    }

    pub fn coda_fresh_string(i: &u32) -> OcamlExpr {
        let mut str = String::new();
        str.push_str("fresh_");
        str.push_str(&i.to_string());
        OcamlExpr::coda_name_string(&str)
    }

    pub fn coda_circuit(
        name: OcamlExpr,
        inputs: Vec<OcamlExpr>,
        outputs: Vec<OcamlExpr>,
        body: OcamlExpr,
    ) -> OcamlExpr {
        OcamlExpr::record(
            OcamlName::new("Circuit"),
            vec![
                (OcamlName::new("name"), name),
                (OcamlName::new("inputs"), OcamlExpr::list(inputs)),
                (OcamlName::new("outputs"), OcamlExpr::list(outputs)),
                (OcamlName::new("dep"), OcamlExpr::none()),
                (OcamlName::new("body"), body),
            ],
        )
    }

    pub fn coda_call(f: &str, es: Vec<OcamlExpr>) -> OcamlExpr {
        OcamlExpr::app(
            OcamlName::new("call"),
            vec![OcamlExpr::coda_name_string(f), OcamlExpr::list(es)],
        )
    }
}

// OcamlName

impl OcamlName {
    pub fn coda_module_field() -> OcamlName {
        OcamlName::new("F")
    }

    pub fn coda_module_expr() -> OcamlName {
        OcamlName::new("Expr")
    }
}
