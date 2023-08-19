use serde::Serialize;
use serde::Deserialize;

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
