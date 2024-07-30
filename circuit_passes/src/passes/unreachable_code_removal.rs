use std::cell::RefCell;
use std::collections::HashSet;
use paste::paste;
use compiler::circuit_design::template::TemplateCode;
use compiler::intermediate_representation::{new_id, BucketId};
use compiler::intermediate_representation::ir_interface::*;
use crate::bucket_interpreter::env::Env;
use crate::bucket_interpreter::error::BadInterp;
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::observer::Observer;
use crate::bucket_interpreter::InterpreterFlags;
use crate::{default__get_mem, default__name};
use super::{CircuitTransformationPass, GlobalPassData};

pub struct UnreachableRemovalPass<'d> {
    // Wrapped in a RefCell because the reference to the static analysis is immutable but we need mutability
    global_data: &'d RefCell<GlobalPassData>,
    memory: PassMemory,
    visited: RefCell<HashSet<BucketId>>,
}

impl<'d> UnreachableRemovalPass<'d> {
    pub fn new(prime: String, global_data: &'d RefCell<GlobalPassData>) -> Self {
        UnreachableRemovalPass {
            global_data,
            memory: PassMemory::new(prime),
            visited: Default::default(),
        }
    }
}

macro_rules! gen_observer {
    ($(#[$($attrss:meta)*])* $bucket_ty: ty) => {
        paste! {
            $(#[$($attrss)*])*
            fn [<on_ $bucket_ty:snake>](
                &self,
                bucket: &$bucket_ty,
                _env: &Env
            ) -> Result<bool, BadInterp> {
                self.visited.borrow_mut().insert(bucket.id);
                Ok(true)
            }
        }
    };
}

macro_rules! gen_transformer {
    ($(#[$($attrss:meta)*])* $bucket_ty: ty) => {
        paste! {
            $(#[$($attrss)*])*
            fn [<transform_ $bucket_ty:snake>](
                &self,
                bucket: &$bucket_ty,
            ) -> Result<InstructionPointer, BadInterp> {
                if self.visited.borrow_mut().remove(&bucket.id) {
                    self.[<transform_ $bucket_ty:snake _default>](bucket)
                } else {
                    Ok(NopBucket { id: new_id() }.allocate())
                }
            }
        }
    };
}

impl Observer<Env<'_>> for UnreachableRemovalPass<'_> {
    gen_observer!(ValueBucket);
    gen_observer!(LoadBucket);
    gen_observer!(StoreBucket);
    gen_observer!(ComputeBucket);
    gen_observer!(AssertBucket);
    gen_observer!(LoopBucket);
    gen_observer!(CreateCmpBucket);
    gen_observer!(BlockBucket);
    gen_observer!(NopBucket);
    gen_observer!(CallBucket);
    gen_observer!(BranchBucket);
    gen_observer!(ReturnBucket);
    gen_observer!(LogBucket);

    fn on_constraint_bucket(
        &self,
        bucket: &ConstraintBucket,
        env: &Env,
    ) -> Result<bool, BadInterp> {
        self.on_instruction(bucket.unwrap(), env)
    }

    fn ignore_function_calls(&self) -> bool {
        false // Observe within all functions
    }

    fn ignore_extracted_function_calls(&self) -> bool {
        false // Observe within all functions
    }
}

impl CircuitTransformationPass for UnreachableRemovalPass<'_> {
    default__name!("UnreachableRemovalPass");
    default__get_mem!();

    fn run_template(&self, template: &TemplateCode) -> Result<(), BadInterp> {
        // Set the `visit_unknown_condition_branches` flag so the BucketInterpreter will visit both branches
        //  of a BranchBucket when the condition is Unknown. The default behavior is to visit neither branch
        //  in that case and which results in all of those statements being considered unreachable.
        self.get_mem().run_template_with_flags(
            self.global_data,
            self,
            template,
            InterpreterFlags {
                visit_unknown_condition_branches: true,
                // Set `propagate_only_known_returns` so the BucketInterpreter will visit
                //  all code that ~might~ be reachable and only skip that which occurs after
                //  a return statement that is ~guaranteed~ to be reached during execution.
                propagate_only_known_returns: true,
                ..Default::default()
            },
        )
    }

    gen_transformer!(ValueBucket);
    gen_transformer!(LoadBucket);
    gen_transformer!(StoreBucket);
    gen_transformer!(ComputeBucket);
    gen_transformer!(AssertBucket);
    gen_transformer!(LoopBucket);
    gen_transformer!(CreateCmpBucket);
    gen_transformer!(BlockBucket);
    gen_transformer!(NopBucket);
    gen_transformer!(BranchBucket);
    gen_transformer!(ReturnBucket);
    gen_transformer!(LogBucket);

    fn transform_call_bucket(&self, bucket: &CallBucket) -> Result<InstructionPointer, BadInterp> {
        if self.visited.borrow_mut().remove(&bucket.id) {
            // BucketInterpreter::_execute_call_bucket() will never visit arguments within
            //  generated functions and will only visit the scalar arguments of all other
            //  functions so we need a special case to prevent the arguments from being
            //  removed unless the CallBucket is removed entirely.
            Ok(CallBucket {
                id: new_id(),
                source_file_id: bucket.source_file_id,
                line: bucket.line,
                message_id: bucket.message_id,
                symbol: bucket.symbol.to_string(),
                argument_types: bucket.argument_types.clone(),
                arguments: bucket.arguments.clone(),
                arena_size: bucket.arena_size,
                return_info: self.transform_return_type(&bucket.id, &bucket.return_info)?,
            }
            .allocate())
        } else {
            Ok(NopBucket { id: new_id() }.allocate())
        }
    }

    fn transform_constraint_bucket(
        &self,
        bucket: &ConstraintBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        match bucket {
            ConstraintBucket::Substitution(i) => {
                let inner = self.transform_substitution_constraint(i)?;
                match *inner {
                    Instruction::Nop(_) => Ok(inner),
                    _ => Ok(ConstraintBucket::Substitution(inner).allocate()),
                }
            }
            ConstraintBucket::Equality(i) => {
                let inner = self.transform_equality_constraint(i)?;
                match *inner {
                    Instruction::Nop(_) => Ok(inner),
                    _ => Ok(ConstraintBucket::Equality(inner).allocate()),
                }
            }
        }
    }

    fn transform_instructions_unfixed_len(
        &self,
        i: &InstructionList,
    ) -> Result<InstructionList, BadInterp> {
        let mut res = self.transform_instructions_default(i);
        if let Ok(body) = &mut res {
            body.retain(|i| !matches!(**i, Instruction::Nop(_)));
        }
        res
    }
}
