use std::cell::RefCell;
use std::collections::HashMap;
use code_producers::llvm_elements::stdlib::GENERATED_FN_PREFIX;
use compiler::circuit_design::function::{FunctionCode, FunctionCodeInfo};
use compiler::circuit_design::template::TemplateCode;
use compiler::compiler_interface::Circuit;
use compiler::hir::very_concrete_program::Param;
use compiler::intermediate_representation::{new_id, BucketId, InstructionPointer, UpdateId};
use compiler::intermediate_representation::ir_interface::*;
use compiler::intermediate_representation::translate::ARRAY_PARAM_STORES;
use crate::bucket_interpreter::error::BadInterp;
use crate::bucket_interpreter::memory::PassMemory;
use crate::{default__name, default__get_mem};
use super::{CircuitTransformationPass, GlobalPassData, builders};

/// Extracts the constant argument initialization section of a template into
/// *.array.param.* functions and replaces the original section with a call to
/// the function. This reduces the overall size of the LLVM IR by allowing
/// templates with the same constant arguments to reuse the same function.
/// NOTE: See `post_hook_circuit` below because it defines another transformation
/// that happens in this pass that is unrelated to constant argument deduplication.
pub struct ConstArgDeduplicationPass<'d> {
    _global_data: &'d RefCell<GlobalPassData>,
    memory: PassMemory,
    new_body_functions: RefCell<HashMap<Vec<(usize, usize)>, FunctionCode>>,
}

impl<'d> ConstArgDeduplicationPass<'d> {
    pub fn new(prime: String, _global_data: &'d RefCell<GlobalPassData>) -> Self {
        ConstArgDeduplicationPass {
            _global_data,
            memory: PassMemory::new(prime),
            new_body_functions: Default::default(),
        }
    }

    fn get_lvar_src_pair(&self, expect_id: BucketId, i: &InstructionPointer) -> (usize, usize) {
        // Matches and asserts below are based on StoreBucket construction in translate.rs::initialize_constants
        if let Instruction::Store(StoreBucket {
            id,
            message_id: 0,
            context: InstrContext { size: 1 },
            dest_is_output: false,
            bounded_fn: None,
            dest_address_type: AddressType::Variable,
            dest: LocationRule::Indexed { location, template_header: None },
            src,
            ..
        }) = &**i
        {
            assert_eq!(expect_id, *id); // assert the correct bucket was found
            if let Instruction::Value(ValueBucket {
                parse_as: ValueType::BigInt,
                op_aux_no: 0,
                value: src_value,
                ..
            }) = &**src
            {
                if let Instruction::Value(ValueBucket {
                    parse_as: ValueType::U32,
                    op_aux_no: 0,
                    value: lvar_index,
                    ..
                }) = &**location
                {
                    return (*lvar_index, *src_value);
                }
            }
        }
        unreachable!()
    }

    fn get_or_create_function_for(
        &self,
        idx_val_pairs: Vec<(usize, usize)>,
        meta: &dyn ObtainMeta,
        name: &String,
        const_stores: Vec<&InstructionPointer>,
    ) -> String {
        // NOTE: no need to store to 'global_data' because all references are 'lvars'
        self.new_body_functions
            .borrow_mut()
            .entry(idx_val_pairs)
            .or_insert_with(|| self.create_function_for(meta, name, const_stores))
            .header
            .clone()
    }

    fn create_function_for(
        &self,
        meta: &dyn ObtainMeta,
        name: &String,
        const_stores: Vec<&InstructionPointer>,
    ) -> FunctionCode {
        // Copy the list of stores and add a "return void" at the end
        let mut new_body = Vec::with_capacity(const_stores.len());
        for s in const_stores {
            let mut copy: InstructionPointer = s.clone();
            copy.update_id();
            new_body.push(copy);
        }
        new_body.push(builders::build_void_return(meta));
        // Create new function to hold the copied body
        // NOTE: This name must start with `GENERATED_FN_PREFIX` so that `ExtractedFunctionCtx` will be used.
        let func_name = format!("{}array.param.{}", GENERATED_FN_PREFIX, new_id());
        Box::new(FunctionCodeInfo {
            source_file_id: meta.get_source_file_id().clone(),
            line: meta.get_line(),
            name: name.clone(),
            header: func_name,
            body: new_body,
            params: vec![Param { name: String::from("lvars"), length: vec![0] }],
            returns: vec![], // void return type on the function
            ..FunctionCodeInfo::default()
        })
    }
}

impl CircuitTransformationPass for ConstArgDeduplicationPass<'_> {
    default__name!("ConstArgDeduplicationPass");
    default__get_mem!();

    fn run_template(&self, _: &TemplateCode) -> Result<(), BadInterp> {
        // No need to actually run templates
        Ok(())
    }

    fn post_hook_circuit(&self, cir: &mut Circuit) -> Result<(), BadInterp> {
        // Normalize return type on source functions for "WriteLLVMIR for Circuit"
        //  which treats a 1-D vector of size 1 as a scalar return and an empty
        //  vector as "void" return type (the initial Circuit builder uses empty
        //  for scalar returns because it doesn't consider "void" return possible).
        // NOTE: This must happen in/before the first pass that adds functions and
        //  since the current pass must be the first one to occur, do it now.
        for f in &mut cir.functions {
            if f.returns.is_empty() {
                f.returns = vec![1];
            }
        }
        // Transform and add the new body functions
        for f in self.new_body_functions.borrow().values() {
            cir.functions.push(self.transform_function(&f)?);
        }
        Ok(())
    }

    fn transform_body(
        &self,
        header: &String,
        body: &InstructionList,
    ) -> Result<InstructionList, BadInterp> {
        if let Some(ps) = ARRAY_PARAM_STORES.with(|map| map.borrow_mut().remove(header)) {
            let mut new_body = InstructionList::default();
            let mut body_iter = body.iter();
            for param_chunk in ps {
                match param_chunk.len() {
                    0 => {
                        // do nothing
                    }
                    1 => {
                        // scalar parameters don't need to be extracted
                        let i = body_iter.next().expect("Expected more statements");
                        new_body.push(self.transform_instruction(i)?);
                    }
                    _ => {
                        let mut idx_val_pairs = Vec::with_capacity(param_chunk.len());
                        let mut const_stores = Vec::with_capacity(param_chunk.len());
                        for bucket_id in param_chunk {
                            let i = body_iter.next().expect("Expected more statements");
                            idx_val_pairs.push(self.get_lvar_src_pair(bucket_id, i));
                            const_stores.push(i);
                        }

                        // Generate a call to the extracted function
                        let meta_info: &dyn ObtainMeta = &**const_stores[0];
                        new_body.push(builders::build_call(
                            meta_info,
                            self.get_or_create_function_for(
                                idx_val_pairs,
                                meta_info,
                                &self.memory.get_current_scope_name(),
                                const_stores,
                            ),
                            vec![builders::build_storage_ptr_ref(meta_info, AddressType::Variable)],
                        ));
                    }
                }
            }
            // Transform the remainder of the body and push to the new body
            for i in body_iter {
                new_body.push(self.transform_instruction(i)?)
            }
            return Ok(new_body);
        }
        self.transform_body_default(header, body)
    }
}
