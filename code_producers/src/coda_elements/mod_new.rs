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
        let name = self.interface.name.coda_compile();
        let body = self.body.coda_compile();
        OcamlStmt::Define(name, body)
    }
}

// CodaTemplateInterface

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaTemplateInterface {
    pub id: usize,
    pub name: CodaTemplateName,
    pub signals: Vec<CodaTemplateSignal>,
    pub variables: Vec<CodaTemplateVariable>,
    pub is_abstract: bool,
}

// CodaTemplateSignal

#[derive(Debug, PartialEq, Eq, Clone)]

pub struct CodaTemplateSignal {}

// CodaTemplateVariable

#[derive(Debug, PartialEq, Eq, Clone)]

pub struct CodaTemplateVariable {}

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
    Let(CodaNamed, CodaExpr, Box<CodaStmt>),
    CreateSubcomponent(CodaSubcomponent, Box<CodaStmt>),
    Branch(CodaExpr, Box<CodaStmt>, Box<CodaStmt>),
    Assert(CodaExpr, CodaExpr, Box<CodaStmt>),
    Output,
}

impl CodaStmt {
    fn coda_compile(&self) -> OcamlExpr {
        match &self {
            CodaStmt::Let(_, _, _) => todo!(),
            CodaStmt::CreateSubcomponent(_, _) => todo!(),
            CodaStmt::Branch(_, _, _) => todo!(),
            CodaStmt::Assert(_, _, _) => todo!(),
            CodaStmt::Output => todo!(),
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
        let qual_field = Some(OcamlName::new("F"));
        match &self {
            CodaOp::Add => OcamlOp::new(qual_field, "+"),
            CodaOp::Sub => OcamlOp::new(qual_field, "-"),
            CodaOp::Mul => OcamlOp::new(qual_field, "*"),
            CodaOp::Pow => OcamlOp::new(qual_field, "^"),
            CodaOp::Div => OcamlOp::new(qual_field, "/"),
            CodaOp::Mod => OcamlOp::new(qual_field, "%"),
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
    fn coda_compile(&self) -> OcamlName {
        todo!()
    }
}

// CodaComponentName

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct CodaComponentName {
    pub string: String,
}

// OcamlExpr

impl OcamlExpr {
    pub fn coda_var(e: OcamlExpr) -> OcamlExpr {
        OcamlExpr::app(OcamlName::new("var"), vec![e])
    }

    pub fn coda_star() -> OcamlExpr {
        OcamlExpr::var(OcamlName::new("star"))
    }

    pub fn coda_tuple(es: Vec<OcamlExpr>) -> OcamlExpr {
        OcamlExpr::app(OcamlName::new("Expr.tuple"), es)
    }

    pub fn coda_let(x: OcamlExpr, e1: OcamlExpr, e2: OcamlExpr) -> OcamlExpr {
        OcamlExpr::app(OcamlName::new("elet"), vec![x, e1, e2])
    }
}
