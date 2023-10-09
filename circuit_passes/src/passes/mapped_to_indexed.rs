use std::cell::RefCell;
use std::collections::BTreeMap;
use compiler::circuit_design::template::TemplateCode;
use compiler::compiler_interface::Circuit;
use compiler::intermediate_representation::{ir_interface::*, BucketId};
use compiler::intermediate_representation::{InstructionPointer, UpdateId};
use crate::bucket_interpreter::env::Env;
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::observer::InterpreterObserver;
use crate::bucket_interpreter::operations::compute_offset;
use crate::bucket_interpreter::value::Value::KnownU32;
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
            memory: PassMemory::new(prime, "".to_string(), Default::default()),
            replacements: Default::default(),
        }
    }

    fn transform_mapped_loc_to_indexed_loc(
        &self,
        cmp_address: &InstructionPointer,
        indexes: &Vec<InstructionPointer>,
        signal_code: usize,
        env: &Env,
    ) -> LocationRule {
        let interpreter = self.memory.build_interpreter(self.global_data, self);

        let (resolved_addr, acc_env) =
            interpreter.execute_instruction(cmp_address, env.clone(), false);

        let resolved_addr = resolved_addr
            .expect("cmp_address instruction in SubcmpSignal must produce a value!")
            .get_u32();

        let name = acc_env.get_subcmp_name(resolved_addr).clone();
        let io_def =
            self.memory.get_iodef(&acc_env.get_subcmp_template_id(resolved_addr), &signal_code);
        let offset = if indexes.len() > 0 {
            let mut acc_env = acc_env;
            let mut indexes_values = vec![];
            for i in indexes {
                let (val, new_env) = interpreter.execute_instruction(i, acc_env, false);
                indexes_values.push(val.expect("Mapped location must produce a value!").get_u32());
                acc_env = new_env;
            }
            io_def.offset + compute_offset(&indexes_values, &io_def.lengths)
        } else {
            io_def.offset
        };
        LocationRule::Indexed {
            location: KnownU32(offset).to_value_bucket(&self.memory).allocate(),
            template_header: Some(name),
        }
    }

    fn maybe_transform_location(
        &self,
        bucket_id: &BucketId,
        address: &AddressType,
        location: &LocationRule,
        env: &Env,
    ) {
        match location {
            LocationRule::Mapped { indexes, signal_code } => match address {
                AddressType::Variable | AddressType::Signal => unreachable!(), // cannot use mapped
                AddressType::SubcmpSignal { cmp_address, .. } => {
                    let indexed_rule = self.transform_mapped_loc_to_indexed_loc(
                        cmp_address,
                        indexes,
                        *signal_code,
                        env,
                    );
                    let old = self.replacements.borrow_mut().insert(*bucket_id, indexed_rule);
                    assert!(old.is_none()); // ensure nothing is unexpectedly overwritten
                }
            },
            LocationRule::Indexed { .. } => return, // do nothing for indexed
        }
    }
}

impl InterpreterObserver for MappedToIndexedPass<'_> {
    fn on_value_bucket(&self, _bucket: &ValueBucket, _env: &Env) -> bool {
        true
    }

    fn on_load_bucket(&self, bucket: &LoadBucket, env: &Env) -> bool {
        self.maybe_transform_location(&bucket.id, &bucket.address_type, &bucket.src, env);
        true
    }

    fn on_store_bucket(&self, bucket: &StoreBucket, env: &Env) -> bool {
        self.maybe_transform_location(&bucket.id, &bucket.dest_address_type, &bucket.dest, env);
        true
    }

    fn on_compute_bucket(&self, _bucket: &ComputeBucket, _env: &Env) -> bool {
        true
    }

    fn on_assert_bucket(&self, _bucket: &AssertBucket, _env: &Env) -> bool {
        true
    }

    fn on_loop_bucket(&self, _bucket: &LoopBucket, _env: &Env) -> bool {
        true
    }

    fn on_create_cmp_bucket(&self, _bucket: &CreateCmpBucket, _env: &Env) -> bool {
        true
    }

    fn on_constraint_bucket(&self, _bucket: &ConstraintBucket, _env: &Env) -> bool {
        true
    }

    fn on_block_bucket(&self, _bucket: &BlockBucket, _env: &Env) -> bool {
        true
    }

    fn on_nop_bucket(&self, _bucket: &NopBucket, _env: &Env) -> bool {
        true
    }

    fn on_location_rule(&self, _location_rule: &LocationRule, _env: &Env) -> bool {
        true
    }

    fn on_call_bucket(&self, bucket: &CallBucket, env: &Env) -> bool {
        if let ReturnType::Final(fd) = &bucket.return_info {
            self.maybe_transform_location(&bucket.id, &fd.dest_address_type, &fd.dest, env);
        }
        true
    }

    fn on_branch_bucket(&self, _bucket: &BranchBucket, _env: &Env) -> bool {
        true
    }

    fn on_return_bucket(&self, _bucket: &ReturnBucket, _env: &Env) -> bool {
        true
    }

    fn on_log_bucket(&self, _bucket: &LogBucket, _env: &Env) -> bool {
        true
    }

    fn ignore_function_calls(&self) -> bool {
        true
    }

    fn ignore_subcmp_calls(&self) -> bool {
        true
    }

    fn ignore_loopbody_function_calls(&self) -> bool {
        false
    }
}

impl CircuitTransformationPass for MappedToIndexedPass<'_> {
    fn name(&self) -> &str {
        "MappedToIndexedPass"
    }

    fn get_updated_field_constants(&self) -> Vec<String> {
        self.memory.get_field_constants_clone()
    }

    /*
        iangneal: Let the interpreter run to see if we can find any replacements.
        If so, yield the replacement. Else, just give the default transformation
    */
    fn transform_location_rule(
        &self,
        bucket_id: &BucketId,
        location_rule: &LocationRule,
    ) -> LocationRule {
        if let Some(indexed_rule) = self.replacements.borrow().get(bucket_id) {
            let mut clone = indexed_rule.clone();
            clone.update_id(); //generate a new unique ID for the clone to avoid assertion in checks.rs
            return clone;
        }
        match location_rule {
            LocationRule::Indexed { location, template_header } => LocationRule::Indexed {
                location: self.transform_instruction(location),
                template_header: template_header.clone(),
            },
            LocationRule::Mapped { .. } => unreachable!(), // all Mapped locations were replaced above
        }
    }

    fn pre_hook_circuit(&self, circuit: &Circuit) {
        self.memory.fill_from_circuit(circuit);
    }

    fn pre_hook_template(&self, template: &TemplateCode) {
        self.memory.set_scope(template);
        self.memory.run_template(self.global_data, self, template);
    }
}
