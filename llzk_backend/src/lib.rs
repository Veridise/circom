//! Provides functionality to generate LLZK code from the Circom AST.

#![deny(missing_debug_implementations)]
#![deny(missing_docs)]
#![deny(clippy::missing_docs_in_private_items)]
#![deny(rustdoc::broken_intra_doc_links)]
#![warn(redundant_imports)]

/// The LLZK code generation module.
mod codegen;

pub use codegen::generate_llzk;
