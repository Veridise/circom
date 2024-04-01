use std::fs::File;

use code_producers::llvm_elements::{build_fn_name, run_fn_name};
use program_structure::ast::SignalType;
use serde::Serialize;
use crate::hir::very_concrete_program::{TemplateInstance, VCF};

#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
struct TypeDesc(String);

impl From<&Vec<usize>> for TypeDesc {
    fn from(lengths: &Vec<usize>) -> Self {
        TypeDesc(format!("{:?}", lengths))
    }
}

#[derive(Clone, Debug, Default, Eq, PartialEq, Serialize)]
struct Meta {
    is_ir_ssa: bool,
    prime: String,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
struct SignalSummary {
    name: String,
    visibility: String,
    idx: usize,
    public: bool,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
struct SubcmpSummary {
    name: String,
    idx: usize,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
pub struct TemplateSummary {
    name: String,
    id: usize,
    main: bool,
    signals: Vec<SignalSummary>,
    subcmps: Vec<SubcmpSummary>,
    logic_fn_name: String,
    constructor_fn_name: String,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
pub struct FunctionSummary {
    name: String,
    logic_fn_name: String,
    params: Vec<(String, TypeDesc)>,
    ret_ty: TypeDesc,
    arena_size: usize,
}

impl FunctionSummary {
    pub fn set_arena_size(&mut self, arena_size: usize) {
        self.arena_size = arena_size;
    }
}

#[derive(Clone, Debug, Default, Eq, PartialEq, Serialize)]
struct SummaryRoot {
    version: String,
    compiler: String,
    framework: Option<String>,
    meta: Meta,
    components: Vec<TemplateSummary>,
    functions: Vec<FunctionSummary>,
}

fn index_names(lengths: &[usize]) -> Vec<String> {
    if lengths.is_empty() {
        return vec!["".to_string()];
    }
    let hd = lengths[0];
    let tl = &lengths[1..lengths.len()];
    let mut res = vec![];

    for i in 0..hd {
        for acc in index_names(tl) {
            res.push(format!("[{i}]{acc}"));
        }
    }

    res
}

#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct SummaryProducer {
    main_id: usize,
    summary: Option<SummaryRoot>, // None if summary flag is false
}

impl SummaryProducer {
    pub fn init(&mut self, main_id: usize, prime: &String) {
        self.main_id = main_id;
        self.summary = Some(SummaryRoot {
            version: env!("CARGO_PKG_VERSION").to_string(),
            compiler: "circom".to_string(),
            framework: None,
            meta: Meta { is_ir_ssa: false, prime: prime.clone() },
            components: vec![],
            functions: vec![],
        });
    }

    pub fn add_function(&mut self, function: &VCF) -> Option<&mut FunctionSummary> {
        if let Some(summary) = &mut self.summary {
            summary.functions.push(FunctionSummary {
                name: function.name.clone(),
                logic_fn_name: function.header.clone(),
                params: function
                    .params_types
                    .iter()
                    .map(|t| (t.name.clone(), TypeDesc::from(&t.length)))
                    .collect(),
                ret_ty: TypeDesc::from(&function.return_type),
                arena_size: 0,
            });
            summary.functions.last_mut()
        } else {
            None
        }
    }

    pub fn add_template(&mut self, template: &TemplateInstance) -> Option<&mut TemplateSummary> {
        if let Some(summary) = &mut self.summary {
            let is_main = template.template_id == self.main_id;
            let mut signals: Vec<SignalSummary> = vec![];
            for signal in &template.signals {
                let signal_names = if signal.lengths.is_empty() {
                    vec![signal.name.clone()]
                } else {
                    index_names(&signal.lengths)
                        .iter()
                        .map(|indices| format!("{}{indices}", signal.name))
                        .collect()
                };
                let vis = match &signal.xtype {
                    SignalType::Output => "output",
                    SignalType::Input => "input",
                    SignalType::Intermediate => "intermediate",
                };
                for name in signal_names {
                    signals.push(SignalSummary {
                        public: is_main && template.public_inputs.contains(&name),
                        visibility: vis.to_string(),
                        idx: signals.len(),
                        name,
                    });
                }
            }

            let mut subcmps: Vec<SubcmpSummary> = vec![];
            for subcmp in &template.components {
                let subcmp_names = if subcmp.lengths.is_empty() {
                    vec![subcmp.name.clone()]
                } else {
                    index_names(&subcmp.lengths)
                        .iter()
                        .map(|indices| format!("{}{indices}", subcmp.name))
                        .collect()
                };
                for name in subcmp_names {
                    subcmps.push(SubcmpSummary { idx: subcmps.len(), name })
                }
            }

            summary.components.push(TemplateSummary {
                name: template.template_name.clone(),
                main: is_main,
                id: template.template_id,
                subcmps,
                signals,
                logic_fn_name: run_fn_name(template.template_header.clone()),
                constructor_fn_name: build_fn_name(template.template_header.clone()),
            });
            summary.components.last_mut()
        } else {
            None
        }
    }

    pub fn write_to_file(&self, summary_file: &str) -> Result<(), serde_json::Error> {
        if let Some(summary) = &self.summary {
            let writer = File::create(summary_file).unwrap();
            serde_json::to_writer(&writer, summary)
        } else {
            Ok(())
        }
    }
}
