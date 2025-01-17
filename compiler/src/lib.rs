#[allow(dead_code)]
pub mod circuit_design;
pub mod intermediate_representation;
mod ir_processing;
pub extern crate num_bigint_dig as num_bigint;
pub extern crate num_traits;
extern crate core;

pub mod compiler_interface;
pub mod hir;
mod translating_traits;
pub mod summary;
