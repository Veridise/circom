use std::cell::RefCell;
use std::collections::BTreeMap;
use compiler::circuit_design::template::TemplateCode;
use compiler::intermediate_representation::ir_interface::*;
use compiler::intermediate_representation::ir_interface::StatusInput::{Last, NoLast};
use crate::bucket_interpreter::env::Env;
use crate::bucket_interpreter::error::BadInterp;
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::observer::Observer;
use crate::bucket_interpreter::result_types;
use crate::{checked_insert, default__get_mem, default__name, default__run_template};
use super::{CircuitTransformationPass, GlobalPassData};

pub struct DeterministicSubCmpInvokePass<'d> {
    global_data: &'d RefCell<GlobalPassData>,
    // Wrapped in a RefCell because the reference to the static analysis is immutable but we need mutability
    memory: PassMemory,
    replacements: RefCell<BTreeMap<AddressType, StatusInput>>,
}

impl<'d> DeterministicSubCmpInvokePass<'d> {
    pub fn new(prime: String, global_data: &'d RefCell<GlobalPassData>) -> Self {
        DeterministicSubCmpInvokePass {
            global_data,
            memory: PassMemory::new(prime),
            replacements: Default::default(),
        }
    }

    pub fn try_resolve_input_status(
        &self,
        address_type: &AddressType,
        env: &Env,
    ) -> Result<(), BadInterp> {
        // Resolve "Unknown" input status. If this store/call instruction initializes the last input signal
        //  within a subcomponent (indicated by counter value of 1 because it will become 0 after execution
        //  of this statement), then replace the input status with Last. Otherwise, with NoLast.
        if let AddressType::SubcmpSignal {
            input_information: InputInformation::Input { status: StatusInput::Unknown },
            cmp_address,
            ..
        } = address_type
        {
            let interpreter = self.memory.build_interpreter(self.global_data, self);
            let addr = interpreter.compute_instruction(cmp_address, env, false)?;
            let addr = result_types::into_single_result_u32(addr, "address of subcomponent")?;
            let new_status = if env.subcmp_counter_equal_to(addr, 1) { Last } else { NoLast };
            checked_insert!(self.replacements.borrow_mut(), address_type.clone(), new_status);
        }
        Ok(())
    }
}

impl Observer<Env<'_>> for DeterministicSubCmpInvokePass<'_> {
    fn on_store_bucket(&self, bucket: &StoreBucket, env: &Env) -> Result<bool, BadInterp> {
        self.try_resolve_input_status(&bucket.dest_address_type, env)?;
        Ok(true)
    }

    fn on_call_bucket(&self, bucket: &CallBucket, env: &Env) -> Result<bool, BadInterp> {
        match &bucket.return_info {
            ReturnType::Intermediate { .. } => {}
            ReturnType::Final(data) => {
                self.try_resolve_input_status(&data.dest_address_type, env)?;
            }
        }
        Ok(true)
    }

    fn ignore_function_calls(&self) -> bool {
        // A Circom source function cannot contain components so
        // AddressType::SubcmpSignal cannot appear within the body.
        true
    }

    fn ignore_extracted_function_calls(&self) -> bool {
        false
    }
}

impl CircuitTransformationPass for DeterministicSubCmpInvokePass<'_> {
    default__name!("DeterministicSubCmpInvokePass");
    default__get_mem!();
    default__run_template!();

    fn transform_subcmp_input_information(
        &self,
        subcmp_address: &AddressType,
        inp_info: &InputInformation,
    ) -> InputInformation {
        if let Some(s) = self.replacements.borrow().get(subcmp_address) {
            return InputInformation::Input { status: s.clone() };
        }
        self.transform_subcmp_input_information_default(subcmp_address, inp_info)
    }
}
