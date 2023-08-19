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

pub struct CodaProgram {
    pub templates: Vec<CodaTemplate>,
}

// CodaTemplate

pub struct CodaTemplate {
    pub interface: CodaTemplateInterface,
    pub body: CodaStmt,
}

// CodaTemplateInterface

pub struct CodaTemplateInterface {
    pub id: usize,
    pub name: CodaTemplateName,
    pub signals: Vec<CodaTemplateSignal>,
    pub variables: Vec<CodaTemplateVariable>,
    pub is_abstract: bool,
}

// CodaTemplateSignal

pub struct CodaTemplateSignal {}

// CodaTemplateVariable

pub struct CodaTemplateVariable {}

// CodaSubcomponent

pub struct CodaSubcomponent {
    pub interface: CodaTemplateInterface,
    pub name: CodaComponentName,
    pub index: usize,
}

// CodaStmt

pub enum CodaStmt {
    Let,
    CreateSubcomponent,
    Branch,
    Assert,
    Output,
}

// CodaExpr

pub enum CodaExpr {
    Op,
    Var,
    Val,
    Tuple,
    Star,
}

// CodaTemplateName

pub struct CodaTemplateName {
    pub string: String,
}

// CodaComponentName

pub struct CodaComponentName {}
