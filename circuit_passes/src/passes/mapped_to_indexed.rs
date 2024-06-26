use std::cell::RefCell;
use std::collections::BTreeMap;
use compiler::circuit_design::template::TemplateCode;
use compiler::intermediate_representation::{ir_interface::*, BucketId};
use compiler::intermediate_representation::{InstructionPointer, UpdateId};
use crate::bucket_interpreter::env::Env;
use crate::bucket_interpreter::error::BadInterp;
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::observer::Observer;
use crate::bucket_interpreter::operations::compute_offset;
use crate::bucket_interpreter::result_types::opt_as_result_u32;
use crate::bucket_interpreter::value::Value::KnownU32;
use crate::{default__get_mem, default__name, default__run_template};
use super::{CircuitTransformationPass, GlobalPassData};

pub struct MappedToIndexedPass<'d> {
    global_data: &'d RefCell<GlobalPassData>,
    memory: PassMemory,
    /// Key is the BucketId of the bucket that holds the original LocationRule instance that needs to be
    /// replaced and the mapped value is the new Indexed LocationRule. The BucketId must be used as key
    /// instead of using the old LocationRule itself because the same Mapped LocationRule paired with a
    /// different AddressType can result in a different Indexed LocationRule.
    // Wrapped in a RefCell because the reference to the static analysis is immutable but we need mutability
    replacements: RefCell<BTreeMap<BucketId, LocationRule>>,
}

impl<'d> MappedToIndexedPass<'d> {
    pub fn new(prime: String, global_data: &'d RefCell<GlobalPassData>) -> Self {
        MappedToIndexedPass {
            global_data,
            memory: PassMemory::new(prime),
            replacements: Default::default(),
        }
    }

    fn transform_mapped_loc_to_indexed_loc(
        &self,
        cmp_address: &InstructionPointer,
        indexes: &Vec<InstructionPointer>,
        signal_code: usize,
        env: &Env,
    ) -> Result<LocationRule, BadInterp> {
        let interpreter = self.memory.build_interpreter(self.global_data, self);
        let resolved_addr = interpreter
            .compute_instruction(cmp_address, env, false)
            .and_then(|v| opt_as_result_u32(v, "subcomponent address"))?;
        let name = env.get_subcmp_name(resolved_addr).clone();
        let io_def =
            self.memory.get_iodef(&env.get_subcmp_template_id(resolved_addr), &signal_code);
        let offset = if indexes.len() > 0 {
            let mut indexes_values = Vec::with_capacity(indexes.len());
            for i in indexes {
                let val = interpreter
                    .compute_instruction(i, env, false)
                    .and_then(|v| opt_as_result_u32(v, "subcomponent mapped signal"))?;
                indexes_values.push(val);
            }
            io_def.offset + compute_offset(&indexes_values, &io_def.lengths)?
        } else {
            io_def.offset
        };
        Ok(LocationRule::Indexed {
            location: KnownU32(offset).to_value_bucket(&self.memory)?.allocate(),
            template_header: Some(name),
        })
    }

    fn maybe_transform_location(
        &self,
        bucket_id: &BucketId,
        address: &AddressType,
        location: &LocationRule,
        env: &Env,
    ) -> Result<(), BadInterp> {
        match location {
            LocationRule::Mapped { indexes, signal_code } => match address {
                AddressType::Variable | AddressType::Signal => unreachable!(), // cannot use mapped
                AddressType::SubcmpSignal { cmp_address, .. } => {
                    let indexed_rule = self.transform_mapped_loc_to_indexed_loc(
                        cmp_address,
                        indexes,
                        *signal_code,
                        env,
                    )?;
                    let old = self.replacements.borrow_mut().insert(*bucket_id, indexed_rule);
                    assert!(old.is_none()); // ensure nothing is unexpectedly overwritten
                }
            },
            LocationRule::Indexed { .. } => {} // do nothing for indexed
        }
        Ok(())
    }
}

impl Observer<Env<'_>> for MappedToIndexedPass<'_> {
    fn on_load_bucket(&self, bucket: &LoadBucket, env: &Env) -> Result<bool, BadInterp> {
        self.maybe_transform_location(&bucket.id, &bucket.address_type, &bucket.src, env)?;
        Ok(true)
    }

    fn on_store_bucket(&self, bucket: &StoreBucket, env: &Env) -> Result<bool, BadInterp> {
        self.maybe_transform_location(&bucket.id, &bucket.dest_address_type, &bucket.dest, env)?;
        Ok(true)
    }

    fn on_call_bucket(&self, bucket: &CallBucket, env: &Env) -> Result<bool, BadInterp> {
        if let ReturnType::Final(fd) = &bucket.return_info {
            self.maybe_transform_location(&bucket.id, &fd.dest_address_type, &fd.dest, env)?;
        }
        Ok(true)
    }

    fn ignore_function_calls(&self) -> bool {
        true
    }

    fn ignore_extracted_function_calls(&self) -> bool {
        false
    }
}

impl CircuitTransformationPass for MappedToIndexedPass<'_> {
    default__name!("MappedToIndexedPass");
    default__get_mem!();
    default__run_template!();

    /*
        iangneal: Let the interpreter run to see if we can find any replacements.
        If so, yield the replacement. Else, just give the default transformation
    */
    fn transform_location_rule(
        &self,
        bucket_id: &BucketId,
        location_rule: &LocationRule,
    ) -> Result<LocationRule, BadInterp> {
        if let Some(indexed_rule) = self.replacements.borrow().get(bucket_id) {
            let mut clone = indexed_rule.clone();
            clone.update_id(); //generate a new unique ID for the clone to avoid assertion in checks.rs
            return Ok(clone);
        }
        match location_rule {
            LocationRule::Indexed { location, template_header } => Ok(LocationRule::Indexed {
                location: self.transform_instruction(location)?,
                template_header: template_header.clone(),
            }),
            LocationRule::Mapped { .. } => unreachable!(), // all Mapped locations were replaced above
        }
    }
}
