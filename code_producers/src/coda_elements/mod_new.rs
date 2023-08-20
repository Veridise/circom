// CodaCircuitData

use super::ocaml::*;

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
        let stmts = self.templates.iter().map(|template| template.coda_compile()).collect();
        OcamlMod { stmts }
    }
}

// CodaTemplate

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaTemplate {
    pub interface: CodaTemplateInterface,
    pub body: CodaStmt,
}

impl CodaTemplate {
    pub fn coda_compile(&self) -> OcamlStmt {
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

        OcamlStmt::Define(
            self.interface.name.coda_compile_name(),
            OcamlExpr::coda_circuit(
                OcamlExpr::var(OcamlName::new("Circuit")),
                inputs,
                outputs,
                self.body.coda_compile(),
            ),
        )
    }
}

// CodaTemplateInterface

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaTemplateInterface {
    pub id: usize,
    pub name: CodaTemplateName,
    pub signals: Vec<CodaTemplateSignal>,
    pub variables: Vec<CodaVariable>,
    pub is_abstract: bool,
}

// CodaTemplateSignal

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaTemplateSignal {
    pub string: String,
    pub visibility: CodaVisibility,
}

impl CodaTemplateSignal {
    pub fn coda_compile_string(&self) -> OcamlExpr {
        OcamlExpr::string(&self.string)
    }
}

// CodaVisibility

#[derive(Debug, PartialEq, Eq, Clone)]
pub enum CodaVisibility {
    Input,
    Output,
    Intermediate,
}

impl CodaVisibility {
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
    CreateSubcomponent(CodaSubcomponent, Box<CodaStmt>),
    AssertEqual(u32, CodaExpr, CodaExpr, Box<CodaStmt>),
}

impl CodaStmt {
    fn coda_compile(&self) -> OcamlExpr {
        match self {
            CodaStmt::Define(n, e, s) => {
                OcamlExpr::coda_let(n.coda_compile(), e.coda_compile(), s.coda_compile())
            }
            CodaStmt::CreateSubcomponent(cmp, s) => {
                let es: Vec<_> = cmp
                    .interface
                    .signals
                    .iter()
                    .map(|signal| OcamlExpr::coda_var(OcamlExpr::string(&signal.string)))
                    .collect();
                OcamlExpr::def(
                    OcamlName::coda_result(),
                    OcamlExpr::app(cmp.name.coda_compile(), es),
                    s.coda_compile(),
                )
            }
            CodaStmt::AssertEqual(i, e1, e2, s) => OcamlExpr::coda_let(
                OcamlExpr::coda_fresh_string(i),
                OcamlExpr::coda_assert_eq(e1.coda_compile(), e2.coda_compile()),
                s.coda_compile(),
            ),
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
    Star,
}

impl CodaExpr {
    pub fn coda_compile(&self) -> OcamlExpr {
        match &self {
            CodaExpr::Named(n) => n.coda_compile(),
            CodaExpr::Value(v) => v.coda_compile(),
            CodaExpr::Op(op, es) => {
                OcamlExpr::op(op.coda_compile(), es.iter().map(|e| e.coda_compile()).collect())
            }
            CodaExpr::Tuple(es) => {
                OcamlExpr::coda_tuple(es.iter().map(|e| e.coda_compile()).collect())
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
    fn coda_compile(&self) -> OcamlExpr {
        match &self {
            CodaNamed::Signal(s) => s.coda_compile(),
            CodaNamed::SubcomponentSignal(s) => s.coda_compile(),
            CodaNamed::Variable(x) => x.coda_compile(),
        }
    }
}

// CodaSignal

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaSignal {
    pub string: String,
}

impl CodaSignal {
    fn coda_compile(&self) -> OcamlExpr {
        OcamlExpr::var(OcamlName::new(&self.string))
    }
}

// CodaSubcomponentSignal

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaSubcomponentSignal {
    pub subcomponent: CodaSubcomponent,
    pub string: String,
}

impl CodaSubcomponentSignal {
    fn coda_compile(&self) -> OcamlExpr {
        let mut str = String::new();
        str.push_str(&self.subcomponent.name.string);
        str.push_str("__");
        str.push_str(&self.string);
        OcamlExpr::coda_var(OcamlExpr::string(&str))
    }
}

// CodaVariable

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaVariable {
    pub string: String,
}
impl CodaVariable {
    fn coda_compile(&self) -> OcamlExpr {
        OcamlExpr::coda_var(OcamlExpr::string(&self.string))
    }
}

// CodaValue

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaValue {
    pub string: String,
}
impl CodaValue {
    fn coda_compile(&self) -> OcamlExpr {
        OcamlExpr::coda_var(OcamlExpr::number(&self.string))
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
    Eq,
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
            CodaOp::Eq => OcamlOp::new(None, "=="),
        }
    }
}

// CodaTemplateName

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaTemplateName {
    pub string: String,
}

impl CodaTemplateName {
    fn coda_compile_name(&self) -> OcamlName {
        OcamlName::new(&self.string)
    }

    fn coda_compile_string(&self) -> OcamlExpr {
        OcamlExpr::string(&self.string)
    }
}

// CodaComponentName

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaComponentName {
    pub string: String,
}

impl CodaComponentName {
    pub fn coda_compile(&self) -> OcamlName {
        OcamlName { string: self.string.clone() }
    }
}

// OcamlExpr

impl OcamlExpr {
    pub fn coda_field() -> OcamlExpr {
        OcamlExpr::var(OcamlName::new("field"))
    }

    pub fn coda_var(e: OcamlExpr) -> OcamlExpr {
        OcamlExpr::app(OcamlName::coda_var(), vec![e])
    }

    pub fn coda_star() -> OcamlExpr {
        OcamlExpr::var(OcamlName::coda_star())
    }

    pub fn coda_tuple(es: Vec<OcamlExpr>) -> OcamlExpr {
        OcamlExpr::app(OcamlName::coda_tuple(), es)
    }

    pub fn coda_let(x: OcamlExpr, e1: OcamlExpr, e2: OcamlExpr) -> OcamlExpr {
        OcamlExpr::app(OcamlName::coda_let(), vec![x, e1, e2])
    }

    pub fn coda_assert_eq(e1: OcamlExpr, e2: OcamlExpr) -> OcamlExpr {
        OcamlExpr::app(OcamlName::coda_assert_eq(), vec![e1, e2])
    }

    pub fn coda_fresh_string(i: &u32) -> OcamlExpr {
        let mut str = String::new();
        str.push_str("fresh_");
        str.push_str(&i.to_string());
        OcamlExpr::string(&str)
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
}

// OcamlName

impl OcamlName {
    pub fn coda_module_field() -> OcamlName {
        OcamlName::new("F")
    }

    pub fn coda_module_expr() -> OcamlName {
        OcamlName::new("Expr")
    }

    pub fn coda_result() -> OcamlName {
        OcamlName::new("result")
    }

    pub fn coda_tuple() -> OcamlName {
        OcamlName::coda_module_expr().sub(&OcamlName::new("tuple"))
    }

    pub fn coda_var() -> OcamlName {
        OcamlName::new("var")
    }

    pub fn coda_let() -> OcamlName {
        OcamlName::new("elet")
    }

    pub fn coda_assert_eq() -> OcamlName {
        OcamlName::new("assert_eq")
    }

    pub fn coda_star() -> OcamlName {
        OcamlName::new("star")
    }
}
