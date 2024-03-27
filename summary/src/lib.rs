use std::collections::HashMap;
use std::fs::File;
use compiler::hir::very_concrete_program::{TemplateInstance, VCF, VCP};
use compiler::intermediate_representation::translate::{initialize_signals, SignalInfo, State};
use code_producers::llvm_elements::{build_fn_name, run_fn_name};
use constant_tracking::ConstantTracker;
use program_structure::ast::SignalType;
use program_structure::file_definition::FileLibrary;
use serde::Serialize;

#[derive(Serialize)]
struct TypeDesc(String);

impl From<&Vec<usize>> for TypeDesc {
    fn from(lengths: &Vec<usize>) -> Self {
        TypeDesc(format!("{:?}", lengths))
    }
}

#[derive(Serialize)]
struct Meta {
    is_ir_ssa: bool,
    prime: String,
}

#[derive(Serialize)]
struct SignalSummary {
    name: String,
    visibility: String,
    idx: usize,
    public: bool,
}

#[derive(Serialize)]
struct SubcmpSummary {
    name: String,
    idx: usize,
}

#[derive(Serialize)]
struct TemplateSummary {
    name: String,
    id: usize,
    main: bool,
    signals: Vec<SignalSummary>,
    subcmps: Vec<SubcmpSummary>,
    logic_fn_name: String,
    constructor_fn_name: String,
}

#[derive(Serialize)]
struct FunctionSummary {
    name: String,
    logic_fn_name: String,
    params: Vec<(String, TypeDesc)>,
    ret_ty: TypeDesc,
}

#[derive(Serialize)]
pub struct SummaryRoot {
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

fn unroll_signal(name: &String, info: &SignalInfo, idx: usize) -> Vec<SignalSummary> {
    if info.lengths.is_empty() {
        return vec![SignalSummary {
            name: name.to_string(),
            visibility: match info.signal_type {
                SignalType::Output => "output",
                SignalType::Input => "input",
                SignalType::Intermediate => "intermediate",
            }
            .to_string(),
            public: false,
            idx,
        }];
    }
    let mut signals = vec![];

    for (offset, indices) in index_names(&info.lengths).iter().enumerate() {
        signals.push(SignalSummary {
            name: format!("{name}{indices}"),
            visibility: match info.signal_type {
                SignalType::Output => "output",
                SignalType::Input => "input",
                SignalType::Intermediate => "intermediate",
            }
            .to_string(),
            idx: idx + offset,
            public: false,
        })
    }

    signals
}

fn unroll_subcmp(name: &String, lengths: &[usize], idx: usize) -> Vec<SubcmpSummary> {
    if lengths.is_empty() {
        return vec![SubcmpSummary { name: name.to_string(), idx }];
    }

    let mut subcmps = vec![];

    for (offset, indices) in index_names(lengths).iter().enumerate() {
        subcmps.push(SubcmpSummary { name: format!("{name}{indices}"), idx: idx + offset })
    }

    subcmps
}

impl SummaryRoot {
    fn create_state(template: &TemplateInstance) -> State {
        State::new(
            template.template_id,
            0,
            ConstantTracker::new(),
            HashMap::with_capacity(0),
            template.signals_to_tags.clone(),
        )
    }

    fn process_signals(instance: &TemplateInstance, file_lib: &FileLibrary) -> Vec<SignalSummary> {
        let mut signals = vec![];
        let mut state = Self::create_state(instance);
        initialize_signals(&mut state, file_lib, instance.signals.clone(), &instance.code);
        for signal in &instance.signals {
            let info = SignalInfo { signal_type: signal.xtype, lengths: signal.lengths.clone() };
            let idx = state.ssa.get_signal(&signal.name).unwrap().0;
            for signal_summary in unroll_signal(&signal.name, &info, idx) {
                signals.push(signal_summary);
            }
        }
        signals
    }

    fn process_template(template: &TemplateInstance, vcp: &VCP) -> TemplateSummary {
        let mut signals = Self::process_signals(template, &vcp.file_library);

        let mut subcmps = vec![];
        for subcmp in &template.components {
            for subcmp_summary in unroll_subcmp(&subcmp.name, &subcmp.lengths, subcmps.len()) {
                subcmps.push(subcmp_summary);
            }
        }

        let is_main = template.template_id == vcp.main_id;
        if is_main {
            for signal in &mut signals {
                signal.public = template.public_inputs.contains(&signal.name);
            }
        }

        TemplateSummary {
            name: template.template_name.clone(),
            main: is_main,
            id: template.template_id,
            subcmps,
            signals,
            logic_fn_name: run_fn_name(template.template_header.clone()),
            constructor_fn_name: build_fn_name(template.template_header.clone()),
        }
    }

    fn process_function(function: &VCF) -> FunctionSummary {
        FunctionSummary {
            name: function.name.clone(),
            logic_fn_name: function.header.clone(),
            params: function
                .params_types
                .iter()
                .map(|t| (t.name.clone(), TypeDesc::from(&t.length)))
                .collect(),
            ret_ty: TypeDesc::from(&function.return_type),
        }
    }

    pub fn new(vcp: &VCP) -> SummaryRoot {
        SummaryRoot {
            version: env!("CARGO_PKG_VERSION").to_string(),
            compiler: "circom".to_string(),
            framework: None,
            meta: Meta { is_ir_ssa: false, prime: vcp.prime.clone() },
            components: vcp.templates.iter().map(|t| Self::process_template(t, vcp)).collect(),
            functions: vcp.functions.iter().map(Self::process_function).collect(),
        }
    }

    pub fn write_to_file(self, summary_file: &str) -> Result<(), serde_json::Error> {
        let writer = File::create(summary_file).unwrap();
        serde_json::to_writer(&writer, &self)
    }
}
