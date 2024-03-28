mod address_type;
mod assert_bucket;
mod branch_bucket;
mod call_bucket;
mod compute_bucket;
mod create_component_bucket;
mod load_bucket;
mod location_rule;
mod log_bucket;
mod loop_bucket;
mod return_bucket;
mod store_bucket;
mod types;
mod value_bucket;
mod constraint_bucket;
mod block_bucket;
mod nop_bucket;
pub mod ir_interface;
pub mod translate;

use code_producers::llvm_elements::{IntValue, LLVMIRProducer, PointerValue};
use pretty::{Doc, RcDoc};
use rand::Rng;
use self::address_type::AddressType;
use crate::translating_traits::WriteLLVMIR;
pub use ir_interface::{Instruction, InstructionList, InstructionPointer};

pub type BucketId = u128;

pub fn new_id() -> BucketId {
    let mut rng = rand::thread_rng();
    rng.gen()
}

pub trait UpdateId {
    /// Will change its internal ID to a new one
    fn update_id(&mut self);
}

pub fn make_ref<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    address_type: &AddressType,
    index: IntValue<'a>,
    enable_counter_case: bool,
) -> PointerValue<'a> {
    match &address_type {
        AddressType::Variable => producer.body_ctx().get_lvar_ref(producer, index),
        AddressType::Signal => producer.template_ctx().get_signal_ref(producer, index),
        AddressType::SubcmpSignal { cmp_address, counter_override, .. } => {
            let addr = cmp_address
                .produce_llvm_ir(producer)
                .expect("The address of a subcomponent must yield a value!");
            if enable_counter_case && *counter_override {
                producer
                    .template_ctx()
                    .load_subcmp_counter(producer, addr, false)
                    .expect("could not find counter!")
            } else {
                producer.template_ctx().get_subcmp_signal(producer, addr, index)
            }
        }
    }
}

pub enum SExp {
    Atom(String),
    List(Vec<SExp>),
}

impl SExp {
    /// Return a pretty printed format of self.
    pub fn to_doc(&self) -> RcDoc<()> {
        match *self {
            SExp::Atom(ref x) => RcDoc::as_string(x),
            SExp::List(ref xs) => RcDoc::text("(")
                .append(
                    RcDoc::intersperse(xs.into_iter().map(|x| x.to_doc()), Doc::line())
                        .nest(1)
                        .group(),
                )
                .append(RcDoc::text(")")),
        }
    }

    pub fn to_pretty(&self, width: usize) -> String {
        let mut w = Vec::new();
        self.to_doc().render(width, &mut w).unwrap();
        String::from_utf8(w).unwrap()
    }
}

pub trait ToSExp {
    fn to_sexp(&self) -> SExp;
}
