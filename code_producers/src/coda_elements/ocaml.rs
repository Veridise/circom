// OcamlMod

pub struct OcamlMod {
    pub stmts: Vec<OcamlStmt>,
}

impl OcamlMod {
    pub fn ocaml_compile(&self) -> String {
        let mut result = String::new();
        for stmt in &self.stmts {
            result.push_str(&stmt.ocaml_compile());
            result.push_str("\n\n")
        }
        result
    }
}

// OcamlStmt

pub enum OcamlStmt {
    Open(OcamlName),
    Define(OcamlName, OcamlExpr),
}

impl OcamlStmt {
    pub fn ocaml_compile(&self) -> String {
        match &self {
            OcamlStmt::Open(m) => format!("open {}", m.ocaml_compile()),
            OcamlStmt::Define(x, e) => {
                format!("let {} = {}", x.ocaml_compile(), e.ocaml_compile())
            }
        }
    }
}

// OcamlExpr

pub enum OcamlExpr {
    Def(OcamlName, Box<OcamlExpr>, Box<OcamlExpr>),
    App(OcamlName, Vec<Box<OcamlExpr>>),
    Op(OcamlOp, Vec<Box<OcamlExpr>>),
    String(String),
    Number(String),
}

impl OcamlExpr {
    pub fn string(str: &str) -> OcamlExpr {
        OcamlExpr::String(str.to_string())
    }

    pub fn number(str: &str) -> OcamlExpr {
        OcamlExpr::Number(str.to_string())
    }

    pub fn var(name: OcamlName) -> OcamlExpr {
        OcamlExpr::App(name, vec![])
    }

    pub fn app(name: OcamlName, args: Vec<OcamlExpr>) -> OcamlExpr {
        let mut args_new = Vec::new();
        for arg in args {
            args_new.push(Box::new(arg))
        }
        OcamlExpr::App(name, args_new)
    }

    pub fn def(name: OcamlName, imp: OcamlExpr, body: OcamlExpr) -> OcamlExpr {
        OcamlExpr::Def(name, Box::new(imp), Box::new(body))
    }

    pub fn op(op: OcamlOp, args: Vec<OcamlExpr>) -> OcamlExpr {
        let mut args_new = Vec::new();
        for arg in args {
            args_new.push(Box::new(arg))
        }
        OcamlExpr::Op(op, args_new)
    }

    pub fn ocaml_compile(&self) -> String {
        match &self {
            OcamlExpr::Def(x, e1, e2) => format!(
                "let {} = {} in @@\n  {}",
                x.ocaml_compile(),
                e1.ocaml_compile(),
                e2.ocaml_compile()
            ),
            OcamlExpr::App(x, es) => {
                if es.len() == 0 {
                    format!("{}", x.ocaml_compile())
                } else {
                    format!(
                        "({} {})",
                        x.ocaml_compile(),
                        es.iter().map(|e| e.ocaml_compile()).collect::<Vec<String>>().join(" ")
                    )
                }
            }
            OcamlExpr::Op(o, es) => o.ocaml_compile(es.iter().map(|e| e.ocaml_compile()).collect()),
            OcamlExpr::String(str) => format!("\"{}\"", str),
            OcamlExpr::Number(str) => str.to_string(),
        }
    }
}

// OcamlName

pub struct OcamlName {
    pub string: String,
}

impl OcamlName {
    pub fn new(str: &str) -> Self {
        let str = str.replace("[", "_").replace("]", "_");
        for (i, c) in str.chars().enumerate() {
            if !c.is_ascii() {
                panic!("Invalid OCaml name (cannot have non-ASCII character): {}", str)
            }
            if i == 0 {
                if c.is_numeric() {
                    panic!("Invalid OCaml name (cannot start with numeric character): {}", str)
                }
            }
        }
        Self { string: str.to_string() }
    }

    pub fn ocaml_compile(&self) -> String {
        format!("{}", self.string)
    }
}

// OcamlOp

pub struct OcamlOp {
    pub qualifier: Option<OcamlName>,
    pub string: String,
}

const OCAML_OP_VALID_CHARS: [char; 15] =
    ['!', '@', '#', '$', '%', '^', '&', '*', '-', '+', '=', '<', '>', '?', '/'];

impl OcamlOp {
    pub fn new(qualifier: Option<OcamlName>, str: &str) -> Self {
        for c in str.chars() {
            if !OCAML_OP_VALID_CHARS.contains(&c) {
                panic!("Invalid OCaml operator: {}", str)
            }
        }
        Self { qualifier, string: str.to_string() }
    }

    pub fn ocaml_compile(&self, strs: Vec<String>) -> String {
        if strs.len() == 0 {
            panic!("An infixed operation must have at least one argument")
        } else if strs.len() == 1 {
            let str0 = &strs[0];
            let str1 = &strs[1];
            match &self.qualifier {
                Some(q) => {
                    format!("{}.({} {} {})", q.ocaml_compile(), str0, self.string, str1)
                }
                None => {
                    format!("({} {} {})", str0, self.string, str1)
                }
            }
        } else {
            let str = strs.join(&format!(" {} ", self.string));

            match &self.qualifier {
                Some(q) => {
                    format!("{}.({})", q.ocaml_compile(), str)
                }
                None => {
                    format!("({})", str)
                }
            }
        }
    }
}
