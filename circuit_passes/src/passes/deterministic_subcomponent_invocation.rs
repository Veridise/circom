use std::cell::RefCell;
use std::collections::BTreeMap;
use compiler::circuit_design::template::TemplateCode;
use compiler::compiler_interface::Circuit;
use compiler::intermediate_representation::ir_interface::*;
use compiler::intermediate_representation::ir_interface::StatusInput::{Last, NoLast};
use crate::bucket_interpreter::env::Env;
use crate::bucket_interpreter::error::BadInterp;
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::observer::Observer;
use crate::{
    default__get_updated_field_constants, default__name, default__pre_hook_template,
    default__pre_hook_circuit,
};
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
            memory: PassMemory::new(prime, "".to_string(), Default::default()),
            replacements: Default::default(),
        }
    }

    pub fn try_resolve_input_status(
        &self,
        address_type: &AddressType,
        env: &Env,
    ) -> Result<(), BadInterp> {
        // If the address of the subcomponent input information is unknown, then
        // If executing this instruction would result in calling the subcomponent we replace it with Last
        //    Will result in calling if the counter is at one because after the execution it will be 0
        // If not replace with NoLast
        if let AddressType::SubcmpSignal {
            input_information: InputInformation::Input { status: StatusInput::Unknown },
            cmp_address,
            ..
        } = address_type
        {
            let env = env.clone();
            let interpreter = self.memory.build_interpreter(self.global_data, self);
            let (addr, env) = interpreter.execute_instruction(cmp_address, env, false)?;
            let addr = addr
                .expect("cmp_address instruction in SubcmpSignal must produce a value!")
                .get_u32()?;
            let new_status = if env.subcmp_counter_equal_to(addr, 1) { Last } else { NoLast };
            self.replacements.borrow_mut().insert(address_type.clone(), new_status);
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
        true
    }

    fn ignore_subcmp_calls(&self) -> bool {
        true
    }

    fn ignore_extracted_function_calls(&self) -> bool {
        false
    }
}

impl CircuitTransformationPass for DeterministicSubCmpInvokePass<'_> {
    default__name!("DeterministicSubCmpInvokePass");
    default__get_updated_field_constants!();
    default__pre_hook_circuit!();
    default__pre_hook_template!();

    fn transform_address_type(&self, address: &AddressType) -> Result<AddressType, BadInterp> {
        let replacements = self.replacements.borrow();
        match address {
            AddressType::SubcmpSignal {
                cmp_address,
                uniform_parallel_value,
                is_output,
                input_information,
                counter_override,
            } => Ok(AddressType::SubcmpSignal {
                cmp_address: self.transform_instruction(&cmp_address)?,
                uniform_parallel_value: uniform_parallel_value.clone(),
                is_output: *is_output,
                input_information: if replacements.contains_key(&address) {
                    InputInformation::Input { status: replacements[&address].clone() }
                } else {
                    input_information.clone()
                },
                counter_override: *counter_override,
            }),
            x => Ok(x.clone()),
        }
    }
}
