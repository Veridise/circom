pub struct CodaProgram {
    pub templates: Vec<CodaTemplate>,
    // pub main: ,
}

impl CodaProgram {
    pub fn print(&self) -> String {
        let mut str = String::new();
        // TODO: imports
        for template in &self.templates {
            str.push_str(&format!("\n\n{}\n\n", &template.print()))
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
    pub inputs: Vec<String>,
    pub intermediates: Vec<String>,
    pub outputs: Vec<String>,
    pub body: CodaExpr,
}

impl CodaTemplate {
    pub fn print(&self) -> String {
        todo!()
    }
}

#[derive(Clone)]
pub enum CodaExpr {
    Let(String, Box<CodaExpr>, Box<CodaExpr>),
    Op(CodaOp, Box<CodaExpr>, Box<CodaExpr>),
    Var(String),
    Val(String),
    Branch { condition: Box<CodaExpr>, then_: Box<CodaExpr>, else_: Box<CodaExpr> },
    Tuple(Vec<Box<CodaExpr>>),
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

pub fn from_usize_to_val_string(x: usize) -> String {
    format!("Val({})", x)
}

pub fn from_usize_to_var_string(x: usize) -> String {
    format!("Var({})", x)
}
