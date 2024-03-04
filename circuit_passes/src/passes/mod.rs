use std::cell::RefCell;
use std::collections::{BTreeMap, HashMap, HashSet};
use std::ops::Range;
use compiler::circuit_design::function::{FunctionCode, FunctionCodeInfo};
use compiler::circuit_design::template::{TemplateCode, TemplateCodeInfo};
use compiler::compiler_interface::Circuit;
use compiler::intermediate_representation::{
    Instruction, InstructionList, InstructionPointer, new_id, BucketId,
};
use compiler::intermediate_representation::ir_interface::*;
use crate::bucket_interpreter::error::BadInterp;
use crate::bucket_interpreter::memory::PassMemory;
use crate::passes::{
    checks::assert_unique_ids_in_circuit, conditional_flattening::ConditionalFlatteningPass,
    const_arg_deduplication::ConstArgDeduplicationPass,
    deterministic_subcomponent_invocation::DeterministicSubCmpInvokePass,
    loop_unroll::LoopUnrollPass, mapped_to_indexed::MappedToIndexedPass,
    simplification::SimplificationPass, unknown_index_sanitization::UnknownIndexSanitizationPass,
    unused_func_removal::UnusedFuncRemovalPass,
};

use self::loop_unroll::body_extractor::{UnrolledIterLvars, ToOriginalLocation, FuncArgIdx};

mod const_arg_deduplication;
mod conditional_flattening;
mod simplification;
mod deterministic_subcomponent_invocation;
mod unused_func_removal;
mod mapped_to_indexed;
mod unknown_index_sanitization;
mod checks;
pub mod loop_unroll;
pub mod builders;

macro_rules! pre_hook {
    ($name: ident, $bucket_ty: ty) => {
        fn $name(&self, _bucket: &$bucket_ty) {}
    };
}

#[macro_export]
macro_rules! default__name {
    ($name: literal) => {
        fn name(&self) -> &str {
            $name
        }
    };
}

#[macro_export]
macro_rules! default__get_mem {
    () => {
        fn get_mem(&self) -> &PassMemory {
            &self.memory
        }
    };
}

#[macro_export]
macro_rules! default__run_template {
    () => {
        fn run_template(&self, template: &TemplateCode) -> Result<(), BadInterp> {
            self.get_mem().run_template(self.global_data, self, template)
        }
    };
}

pub trait CircuitTransformationPass {
    fn name(&self) -> &str;
    fn get_mem(&self) -> &PassMemory;
    fn run_template(&self, template: &TemplateCode) -> Result<(), BadInterp>;

    fn get_updated_field_constants(&self) -> Vec<String> {
        self.get_mem().get_field_constants_clone()
    }

    fn get_updated_bounded_array_loads(
        &self,
        old_array_loads: &HashSet<Range<usize>>,
    ) -> HashSet<Range<usize>> {
        old_array_loads.clone()
    }

    fn get_updated_bounded_array_stores(
        &self,
        old_array_stores: &HashSet<Range<usize>>,
    ) -> HashSet<Range<usize>> {
        old_array_stores.clone()
    }

    fn transform_circuit(&self, circuit: &Circuit) -> Result<Circuit, BadInterp> {
        self.pre_hook_circuit(&circuit)?;
        let templates = circuit
            .templates
            .iter()
            .map(|t| self.transform_template(t))
            .collect::<Result<_, _>>()?;
        let functions = circuit
            .functions
            .iter()
            .map(|f| self.transform_function(f))
            .collect::<Result<_, _>>()?;
        let field_tracking = self.get_updated_field_constants();
        let array_loads =
            self.get_updated_bounded_array_loads(&circuit.llvm_data.bounded_array_loads);
        let array_stores =
            self.get_updated_bounded_array_stores(&circuit.llvm_data.bounded_array_stores);
        let mut new_circuit = Circuit {
            wasm_producer: circuit.wasm_producer.clone(),
            c_producer: circuit.c_producer.clone(),
            llvm_data: circuit.llvm_data.clone_with_updates(
                field_tracking,
                array_loads,
                array_stores,
            ),
            templates,
            functions,
        };
        self.post_hook_circuit(&mut new_circuit)?;
        Ok(new_circuit)
    }

    fn transform_template(&self, template: &TemplateCode) -> Result<TemplateCode, BadInterp> {
        self.pre_hook_template(template)?;
        Ok(Box::new(TemplateCodeInfo {
            id: template.id,
            source_file_id: template.source_file_id,
            line: template.line.clone(),
            header: template.header.clone(),
            name: template.name.clone(),
            is_parallel: template.is_parallel,
            is_parallel_component: template.is_parallel_component,
            is_not_parallel_component: template.is_not_parallel_component,
            has_parallel_sub_cmp: template.has_parallel_sub_cmp,
            number_of_inputs: template.number_of_inputs,
            number_of_outputs: template.number_of_outputs,
            number_of_intermediates: template.number_of_intermediates,
            body: self.transform_body(&template.header, &template.body)?,
            var_stack_depth: template.var_stack_depth,
            expression_stack_depth: template.expression_stack_depth,
            signal_stack_depth: template.signal_stack_depth,
            number_of_components: template.number_of_components,
        }))
    }

    fn transform_function(&self, function: &FunctionCode) -> Result<FunctionCode, BadInterp> {
        self.pre_hook_function(function)?;
        Ok(Box::new(FunctionCodeInfo {
            source_file_id: function.source_file_id,
            line: function.line.clone(),
            header: function.header.clone(),
            name: function.name.clone(),
            params: function.params.clone(),
            returns: function.returns.clone(),
            body: self.transform_body(&function.header, &function.body)?,
            max_number_of_vars: function.max_number_of_vars,
            max_number_of_ops_in_expression: function.max_number_of_ops_in_expression,
        }))
    }

    fn transform_body(
        &self,
        header: &String,
        body: &InstructionList,
    ) -> Result<InstructionList, BadInterp> {
        self.transform_body_default(header, body)
    }

    fn transform_body_default(
        &self,
        _header: &String,
        body: &InstructionList,
    ) -> Result<InstructionList, BadInterp> {
        self.transform_instructions(body)
    }

    fn transform_instructions(&self, i: &InstructionList) -> Result<InstructionList, BadInterp> {
        i.iter().map(|i| self.transform_instruction(i)).collect()
    }

    fn transform_instruction(&self, i: &Instruction) -> Result<InstructionPointer, BadInterp> {
        self.pre_hook_instruction(i);
        use compiler::intermediate_representation::Instruction::*;
        match i {
            Value(b) => self.transform_value_bucket(b),
            Load(b) => self.transform_load_bucket(b),
            Store(b) => self.transform_store_bucket(b),
            Compute(b) => self.transform_compute_bucket(b),
            Call(b) => self.transform_call_bucket(b),
            Branch(b) => self.transform_branch_bucket(b),
            Return(b) => self.transform_return_bucket(b),
            Assert(b) => self.transform_assert_bucket(b),
            Log(b) => self.transform_log_bucket(b),
            Loop(b) => self.transform_loop_bucket(b),
            CreateCmp(b) => self.transform_create_cmp_bucket(b),
            Constraint(b) => self.transform_constraint_bucket(b),
            Block(b) => self.transform_block_bucket(b),
            Nop(b) => self.transform_nop_bucket(b),
        }
    }

    fn transform_value_bucket(
        &self,
        bucket: &ValueBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        self.transform_value_bucket_default(bucket)
    }

    fn transform_value_bucket_default(
        &self,
        bucket: &ValueBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        Ok(ValueBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            parse_as: bucket.parse_as,
            op_aux_no: bucket.op_aux_no,
            value: bucket.value,
        }
        .allocate())
    }

    fn transform_subcmp_input_information(
        &self,
        subcmp_address: &AddressType,
        inp_info: &InputInformation,
    ) -> InputInformation {
        self.transform_subcmp_input_information_default(subcmp_address, inp_info)
    }

    fn transform_subcmp_input_information_default(
        &self,
        _subcmp_address: &AddressType,
        inp_info: &InputInformation,
    ) -> InputInformation {
        inp_info.clone()
    }

    fn transform_address_type(&self, address: &AddressType) -> Result<AddressType, BadInterp> {
        self.transform_address_type_default(address)
    }

    fn transform_address_type_default(
        &self,
        address: &AddressType,
    ) -> Result<AddressType, BadInterp> {
        Ok(match address {
            AddressType::SubcmpSignal {
                cmp_address,
                uniform_parallel_value,
                is_output,
                input_information,
                counter_override,
            } => AddressType::SubcmpSignal {
                cmp_address: self.transform_instruction(cmp_address)?,
                uniform_parallel_value: uniform_parallel_value.clone(),
                is_output: *is_output,
                input_information: self
                    .transform_subcmp_input_information(address, input_information),
                counter_override: *counter_override,
            },
            x => x.clone(),
        })
    }

    fn transform_location_rule(
        &self,
        bucket_id: &BucketId,
        location_rule: &LocationRule,
    ) -> Result<LocationRule, BadInterp> {
        self.transform_location_rule_default(bucket_id, location_rule)
    }

    fn transform_location_rule_default(
        &self,
        _bucket_id: &BucketId,
        location_rule: &LocationRule,
    ) -> Result<LocationRule, BadInterp> {
        Ok(match location_rule {
            LocationRule::Indexed { location, template_header } => LocationRule::Indexed {
                location: self.transform_instruction(location)?,
                template_header: template_header.clone(),
            },
            LocationRule::Mapped { signal_code, indexes } => LocationRule::Mapped {
                signal_code: *signal_code,
                indexes: self.transform_instructions(indexes)?,
            },
        })
    }

    fn transform_bounded_fn(
        &self,
        bucket_id: &BucketId,
        bounded_fn: &Option<String>,
    ) -> Option<String> {
        self.transform_bounded_fn_default(bucket_id, bounded_fn)
    }

    fn transform_bounded_fn_default(
        &self,
        _bucket_id: &BucketId,
        bounded_fn: &Option<String>,
    ) -> Option<String> {
        bounded_fn.clone()
    }

    fn transform_load_bucket(&self, bucket: &LoadBucket) -> Result<InstructionPointer, BadInterp> {
        self.transform_load_bucket_default(bucket)
    }

    fn transform_load_bucket_default(
        &self,
        bucket: &LoadBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        Ok(LoadBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            address_type: self.transform_address_type(&bucket.address_type)?,
            src: self.transform_location_rule(&bucket.id, &bucket.src)?,
            bounded_fn: self.transform_bounded_fn(&bucket.id, &bucket.bounded_fn),
        }
        .allocate())
    }

    fn transform_store_bucket(
        &self,
        bucket: &StoreBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        self.transform_store_bucket_default(bucket)
    }

    fn transform_store_bucket_default(
        &self,
        bucket: &StoreBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        Ok(StoreBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            context: bucket.context.clone(),
            dest_is_output: bucket.dest_is_output,
            dest_address_type: self.transform_address_type(&bucket.dest_address_type)?,
            dest: self.transform_location_rule(&bucket.id, &bucket.dest)?,
            src: self.transform_instruction(&bucket.src)?,
            bounded_fn: self.transform_bounded_fn(&bucket.id, &bucket.bounded_fn),
        }
        .allocate())
    }

    fn transform_compute_bucket(
        &self,
        bucket: &ComputeBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        self.transform_compute_bucket_default(bucket)
    }

    fn transform_compute_bucket_default(
        &self,
        bucket: &ComputeBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        Ok(ComputeBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            op: bucket.op,
            op_aux_no: bucket.op_aux_no,
            stack: self.transform_instructions(&bucket.stack)?,
        }
        .allocate())
    }

    fn transform_final_data(
        &self,
        bucket_id: &BucketId,
        final_data: &FinalData,
    ) -> Result<FinalData, BadInterp> {
        self.transform_final_data_default(bucket_id, final_data)
    }

    fn transform_final_data_default(
        &self,
        bucket_id: &BucketId,
        final_data: &FinalData,
    ) -> Result<FinalData, BadInterp> {
        Ok(FinalData {
            context: final_data.context,
            dest_is_output: final_data.dest_is_output,
            dest_address_type: self.transform_address_type(&final_data.dest_address_type)?,
            dest: self.transform_location_rule(bucket_id, &final_data.dest)?,
        })
    }

    fn transform_return_type(
        &self,
        bucket_id: &BucketId,
        return_type: &ReturnType,
    ) -> Result<ReturnType, BadInterp> {
        self.transform_return_type_default(bucket_id, return_type)
    }

    fn transform_return_type_default(
        &self,
        bucket_id: &BucketId,
        return_type: &ReturnType,
    ) -> Result<ReturnType, BadInterp> {
        Ok(match return_type {
            ReturnType::Final(f) => ReturnType::Final(self.transform_final_data(bucket_id, f)?),
            x => x.clone(),
        })
    }

    fn transform_call_bucket(&self, bucket: &CallBucket) -> Result<InstructionPointer, BadInterp> {
        self.transform_call_bucket_default(bucket)
    }

    fn transform_call_bucket_default(
        &self,
        bucket: &CallBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        Ok(CallBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            symbol: bucket.symbol.to_string(),
            argument_types: bucket.argument_types.clone(),
            arguments: self.transform_instructions(&bucket.arguments)?,
            arena_size: bucket.arena_size,
            return_info: self.transform_return_type(&bucket.id, &bucket.return_info)?,
        }
        .allocate())
    }

    fn transform_branch_bucket(
        &self,
        bucket: &BranchBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        self.transform_branch_bucket_default(bucket)
    }

    fn transform_branch_bucket_default(
        &self,
        bucket: &BranchBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        Ok(BranchBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            cond: self.transform_instruction(&bucket.cond)?,
            if_branch: self.transform_instructions(&bucket.if_branch)?,
            else_branch: self.transform_instructions(&bucket.else_branch)?,
        }
        .allocate())
    }

    fn transform_return_bucket(
        &self,
        bucket: &ReturnBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        self.transform_return_bucket_default(bucket)
    }

    fn transform_return_bucket_default(
        &self,
        bucket: &ReturnBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        Ok(ReturnBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            with_size: bucket.with_size,
            value: self.transform_instruction(&bucket.value)?,
        }
        .allocate())
    }

    fn transform_assert_bucket(
        &self,
        bucket: &AssertBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        self.transform_assert_bucket_default(bucket)
    }

    fn transform_assert_bucket_default(
        &self,
        bucket: &AssertBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        Ok(AssertBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            evaluate: self.transform_instruction(&bucket.evaluate)?,
        }
        .allocate())
    }

    fn transform_log_bucket_args(
        &self,
        args: &Vec<LogBucketArg>,
    ) -> Result<Vec<LogBucketArg>, BadInterp> {
        self.transform_log_bucket_args_default(args)
    }

    fn transform_log_bucket_args_default(
        &self,
        args: &Vec<LogBucketArg>,
    ) -> Result<Vec<LogBucketArg>, BadInterp> {
        args.iter()
            .map(|arg| {
                Ok(match arg {
                    LogBucketArg::LogExp(e) => LogBucketArg::LogExp(self.transform_instruction(e)?),
                    x => x.clone(),
                })
            })
            .collect()
    }

    fn transform_log_bucket(&self, bucket: &LogBucket) -> Result<InstructionPointer, BadInterp> {
        self.transform_log_bucket_default(bucket)
    }

    fn transform_log_bucket_default(
        &self,
        bucket: &LogBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        Ok(LogBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            argsprint: self.transform_log_bucket_args(&bucket.argsprint)?,
        }
        .allocate())
    }

    fn transform_loop_bucket(&self, bucket: &LoopBucket) -> Result<InstructionPointer, BadInterp> {
        self.transform_loop_bucket_default(bucket)
    }

    fn transform_loop_bucket_default(
        &self,
        bucket: &LoopBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        Ok(LoopBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            continue_condition: self.transform_instruction(&bucket.continue_condition)?,
            body: self.transform_instructions(&bucket.body)?,
        }
        .allocate())
    }

    fn transform_create_cmp_bucket(
        &self,
        bucket: &CreateCmpBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        self.transform_create_cmp_bucket_default(bucket)
    }

    fn transform_create_cmp_bucket_default(
        &self,
        bucket: &CreateCmpBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        Ok(CreateCmpBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            template_id: bucket.template_id,
            cmp_unique_id: bucket.cmp_unique_id,
            symbol: bucket.symbol.clone(),
            sub_cmp_id: self.transform_instruction(&bucket.sub_cmp_id)?,
            name_subcomponent: bucket.name_subcomponent.to_string(),
            defined_positions: bucket.defined_positions.clone(),
            is_part_mixed_array_not_uniform_parallel: bucket
                .is_part_mixed_array_not_uniform_parallel,
            uniform_parallel: bucket.uniform_parallel,
            dimensions: bucket.dimensions.clone(),
            signal_offset: bucket.signal_offset,
            signal_offset_jump: bucket.signal_offset_jump,
            component_offset: bucket.component_offset,
            component_offset_jump: bucket.component_offset_jump,
            number_of_cmp: bucket.number_of_cmp,
            has_inputs: bucket.has_inputs,
        }
        .allocate())
    }

    fn transform_substitution_constraint(
        &self,
        i: &InstructionPointer,
    ) -> Result<InstructionPointer, BadInterp> {
        self.transform_substitution_constraint_default(i)
    }

    fn transform_substitution_constraint_default(
        &self,
        i: &InstructionPointer,
    ) -> Result<InstructionPointer, BadInterp> {
        self.transform_instruction(i)
    }

    fn transform_equality_constraint(
        &self,
        i: &InstructionPointer,
    ) -> Result<InstructionPointer, BadInterp> {
        self.transform_equality_constraint_default(i)
    }

    fn transform_equality_constraint_default(
        &self,
        i: &InstructionPointer,
    ) -> Result<InstructionPointer, BadInterp> {
        self.transform_instruction(i)
    }

    fn transform_constraint_bucket(
        &self,
        bucket: &ConstraintBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        self.transform_constraint_bucket_default(bucket)
    }

    fn transform_constraint_bucket_default(
        &self,
        bucket: &ConstraintBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        Ok(match bucket {
            ConstraintBucket::Substitution(i) => {
                ConstraintBucket::Substitution(self.transform_substitution_constraint(i)?)
            }
            ConstraintBucket::Equality(i) => {
                ConstraintBucket::Equality(self.transform_equality_constraint(i)?)
            }
        }
        .allocate())
    }

    fn transform_block_bucket(
        &self,
        bucket: &BlockBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        self.transform_block_bucket_default(bucket)
    }

    fn transform_block_bucket_default(
        &self,
        bucket: &BlockBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        Ok(BlockBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            body: self.transform_instructions(&bucket.body)?,
            n_iters: bucket.n_iters,
            label: bucket.label.clone(),
        }
        .allocate())
    }

    fn transform_nop_bucket(&self, bucket: &NopBucket) -> Result<InstructionPointer, BadInterp> {
        self.transform_nop_bucket_default(bucket)
    }

    fn transform_nop_bucket_default(
        &self,
        _bucket: &NopBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        Ok(NopBucket { id: new_id() }.allocate())
    }

    fn pre_hook_circuit(&self, circuit: &Circuit) -> Result<(), BadInterp> {
        self.get_mem().fill_from_circuit(circuit);
        Ok(())
    }

    fn post_hook_circuit(&self, _: &mut Circuit) -> Result<(), BadInterp> {
        Ok(())
    }

    fn pre_hook_template(&self, template: &TemplateCode) -> Result<(), BadInterp> {
        self.get_mem().set_scope(template);
        self.get_mem().set_source_name(&template.name);
        self.run_template(template)
    }

    fn pre_hook_function(&self, function: &FunctionCode) -> Result<(), BadInterp> {
        self.get_mem().set_source_name(&function.name);
        Ok(())
    }

    fn pre_hook_instruction(&self, i: &Instruction) {
        use compiler::intermediate_representation::Instruction::*;
        match i {
            Value(b) => self.pre_hook_value_bucket(b),
            Load(b) => self.pre_hook_load_bucket(b),
            Store(b) => self.pre_hook_store_bucket(b),
            Compute(b) => self.pre_hook_compute_bucket(b),
            Call(b) => self.pre_hook_call_bucket(b),
            Branch(b) => self.pre_hook_branch_bucket(b),
            Return(b) => self.pre_hook_return_bucket(b),
            Assert(b) => self.pre_hook_assert_bucket(b),
            Log(b) => self.pre_hook_log_bucket(b),
            Loop(b) => self.pre_hook_loop_bucket(b),
            CreateCmp(b) => self.pre_hook_create_cmp_bucket(b),
            Constraint(b) => self.pre_hook_constraint_bucket(b),
            Block(b) => self.pre_hook_unrolled_loop_bucket(b),
            Nop(b) => self.pre_hook_nop_bucket(b),
        }
    }

    pre_hook!(pre_hook_value_bucket, ValueBucket);
    pre_hook!(pre_hook_load_bucket, LoadBucket);
    pre_hook!(pre_hook_store_bucket, StoreBucket);
    pre_hook!(pre_hook_compute_bucket, ComputeBucket);
    pre_hook!(pre_hook_call_bucket, CallBucket);
    pre_hook!(pre_hook_branch_bucket, BranchBucket);
    pre_hook!(pre_hook_return_bucket, ReturnBucket);
    pre_hook!(pre_hook_assert_bucket, AssertBucket);
    pre_hook!(pre_hook_log_bucket, LogBucket);
    pre_hook!(pre_hook_loop_bucket, LoopBucket);
    pre_hook!(pre_hook_create_cmp_bucket, CreateCmpBucket);
    pre_hook!(pre_hook_constraint_bucket, ConstraintBucket);
    pre_hook!(pre_hook_unrolled_loop_bucket, BlockBucket);
    pre_hook!(pre_hook_nop_bucket, NopBucket);
}

pub enum PassKind {
    ConstArgDeduplication,
    LoopUnroll,
    Simplification,
    ConditionalFlattening,
    UnusedFunctionRemoval,
    DeterministicSubCmpInvoke,
    MappedToIndexed,
    UnknownIndexSanitization,
}

pub struct GlobalPassData {
    /// Created during loop unrolling, maps generated function name + UnrolledIterLvars
    /// (from Env::get_vars_sort) to location reference in the original function. Used
    /// by ExtractedFuncEnvData to access the original function's Env via the extracted
    /// function's parameter references.
    extract_func_orig_loc:
        HashMap<String, BTreeMap<UnrolledIterLvars, (ToOriginalLocation, HashSet<FuncArgIdx>)>>,
}

impl GlobalPassData {
    pub fn new() -> GlobalPassData {
        GlobalPassData { extract_func_orig_loc: Default::default() }
    }

    pub fn get_data_for_func(
        &self,
        name: &String,
    ) -> &BTreeMap<UnrolledIterLvars, (ToOriginalLocation, HashSet<FuncArgIdx>)> {
        match self.extract_func_orig_loc.get(name) {
            Some(x) => x,
            None => {
                // Allow for the suffix(es) added by ConditionalFlatteningPass
                let name = name.trim_end_matches(&['.', 'T', 'F', 'N']);
                self.extract_func_orig_loc.get(name).unwrap()
            }
        }
    }
}

pub struct PassManager {
    passes: RefCell<Vec<PassKind>>,
}

impl PassManager {
    pub fn new() -> Self {
        PassManager { passes: Default::default() }
    }

    /// NOTE: This must be the first pass to occur because it relies
    /// on the original ids for buckets created by `translate.rs`
    /// because of its use of the ARRAY_PARAM_STORES.
    pub fn schedule_const_arg_deduplication_pass(&self) -> &Self {
        self.passes.borrow_mut().push(PassKind::ConstArgDeduplication);
        self
    }

    pub fn schedule_loop_unroll_pass(&self) -> &Self {
        self.passes.borrow_mut().push(PassKind::LoopUnroll);
        self
    }

    pub fn schedule_simplification_pass(&self) -> &Self {
        self.passes.borrow_mut().push(PassKind::Simplification);
        self
    }

    pub fn schedule_conditional_flattening_pass(&self) -> &Self {
        self.passes.borrow_mut().push(PassKind::ConditionalFlattening);
        self
    }

    pub fn schedule_deterministic_subcmp_invoke_pass(&self) -> &Self {
        self.passes.borrow_mut().push(PassKind::DeterministicSubCmpInvoke);
        self
    }

    pub fn schedule_unused_function_removal_pass(&self) -> &Self {
        self.passes.borrow_mut().push(PassKind::UnusedFunctionRemoval);
        self
    }

    pub fn schedule_mapped_to_indexed_pass(&self) -> &Self {
        self.passes.borrow_mut().push(PassKind::MappedToIndexed);
        self
    }

    pub fn schedule_unknown_index_sanitization_pass(&self) -> &Self {
        self.passes.borrow_mut().push(PassKind::UnknownIndexSanitization);
        self
    }

    fn build_pass<'d>(
        kind: PassKind,
        prime: &String,
        global_data: &'d RefCell<GlobalPassData>,
    ) -> Box<dyn CircuitTransformationPass + 'd> {
        match kind {
            PassKind::ConstArgDeduplication => {
                Box::new(ConstArgDeduplicationPass::new(prime.clone(), global_data))
            }
            PassKind::LoopUnroll => Box::new(LoopUnrollPass::new(prime.clone(), global_data)),
            PassKind::Simplification => {
                Box::new(SimplificationPass::new(prime.clone(), global_data))
            }
            PassKind::ConditionalFlattening => {
                Box::new(ConditionalFlatteningPass::new(prime.clone(), global_data))
            }
            PassKind::DeterministicSubCmpInvoke => {
                Box::new(DeterministicSubCmpInvokePass::new(prime.clone(), global_data))
            }
            PassKind::UnusedFunctionRemoval => {
                Box::new(UnusedFuncRemovalPass::new(prime.clone(), global_data))
            }
            PassKind::MappedToIndexed => {
                Box::new(MappedToIndexedPass::new(prime.clone(), global_data))
            }
            PassKind::UnknownIndexSanitization => {
                Box::new(UnknownIndexSanitizationPass::new(prime.clone(), global_data))
            }
        }
    }

    pub fn transform_circuit(
        &self,
        circuit: Circuit,
        prime: &String,
    ) -> Result<Circuit, BadInterp> {
        // NOTE: Used RefCell rather than a mutable reference because storing
        //  the mutable reference in EnvRecorder was causing rustc errors.
        let global_data = RefCell::new(GlobalPassData::new());
        let mut transformed_circuit = circuit;
        for kind in self.passes.borrow_mut().drain(..) {
            let pass = Self::build_pass(kind, prime, &global_data);
            if cfg!(debug_assertions) {
                println!("Do {}...", pass.name());
            }
            transformed_circuit = pass.transform_circuit(&transformed_circuit)?;
            assert_unique_ids_in_circuit(&transformed_circuit);
        }
        Ok(transformed_circuit)
    }
}
