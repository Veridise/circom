use std::cell::RefCell;

use std::convert::TryFrom;
use std::rc::Rc;
use ansi_term::Colour;
use inkwell::attributes::AttributeLoc;

use inkwell::basic_block::BasicBlock;
use inkwell::builder::Builder;
use inkwell::context::{Context, ContextRef};
use inkwell::module::Module;
use inkwell::passes::PassManager;
use inkwell::types::{AnyTypeEnum, BasicType, BasicTypeEnum, IntType};
use inkwell::values::{AnyValueEnum, ArrayValue, BasicMetadataValueEnum, BasicValue, BasicValueEnum, IntValue};
use inkwell::values::FunctionValue;

use template::TemplateCtx;

use crate::llvm_elements::types::bool_type;
pub use inkwell::types::AnyType;
pub use inkwell::values::AnyValue;
use inkwell::values::InstructionOpcode::GetElementPtr;
use crate::llvm_elements::instructions::create_alloca;

pub mod stdlib;
pub mod template;
pub mod types;
pub mod functions;
pub mod instructions;
pub mod fr;
pub mod values;

pub type LLVMInstruction<'a> = AnyValueEnum<'a>;

pub trait BodyCtx<'a> {
    fn get_variable(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        index: IntValue<'a>,
    ) -> AnyValueEnum<'a>;
}

pub trait LLVMIRProducer<'a> {
    fn llvm(&self) -> &LLVM<'a>;
    fn context(&self) -> ContextRef<'a>;
    fn set_current_bb(&self, bb: BasicBlock<'a>);
    fn template_ctx(&self) -> &TemplateCtx<'a>;
    fn body_ctx(&self) -> &dyn BodyCtx<'a>;
    fn current_function(&self) -> FunctionValue<'a>;
    fn builder(&self) -> &Builder<'a>;
    fn constant_fields(&self) -> &Vec<String>;
    fn get_template_mem_arg(&self, run_fn: FunctionValue<'a>) -> ArrayValue<'a>;
}

#[derive(Default)]
pub struct LLVMCircuitData {
    pub field_tracking: Vec<String>,
}

pub struct TopLevelLLVMIRProducer<'a> {
    pub context: &'a Context,
    current_module: LLVM<'a>,
    pub field_tracking: Vec<String>,
}

impl<'a> LLVMIRProducer<'a> for TopLevelLLVMIRProducer<'a> {
    fn llvm(&self) -> &LLVM<'a> {
        &self.current_module
    }

    fn context(&self) -> ContextRef<'a> {
        self.current_module.module.get_context()
    }

    fn set_current_bb(&self, bb: BasicBlock<'a>) {
        self.llvm().builder.position_at_end(bb);
    }

    fn template_ctx(&self) -> &TemplateCtx<'a> {
        panic!("The top level llvm producer does not hold a template context!");
    }

    fn body_ctx(&self) -> &dyn BodyCtx<'a> {
        panic!("The top level llvm producer does not hold a body context!");
    }

    fn current_function(&self) -> FunctionValue<'a> {
        panic!("The top level llvm producer does not have a current function");
    }

    fn builder(&self) -> &Builder<'a> {
        &self.llvm().builder
    }

    fn constant_fields(&self) -> &Vec<String> {
        &self.field_tracking
    }

    fn get_template_mem_arg(&self, _run_fn: FunctionValue<'a>) -> ArrayValue<'a> {
        panic!("The top level llvm producer can't extract the template argument of a run function!");
    }
}

impl<'a> TopLevelLLVMIRProducer<'a> {
    pub fn write_to_file(&self, path: &str) -> Result<(), ()> {
        self.current_module.verify(false)?;
        self.current_module.run_optimization_passes();
        self.current_module.verify(true)?;
        self.current_module.write_to_file(path)
    }
}

pub fn create_context() -> Context {
    Context::create()
}

impl<'a> TopLevelLLVMIRProducer<'a> {
    pub fn new(context: &'a Context, name: &str, field_tracking: Vec<String>) -> Self {
        TopLevelLLVMIRProducer {
            context,
            current_module: LLVM::from_context(context, name),
            field_tracking,
        }
    }
}

pub type LLVMAdapter<'a> = &'a Rc<RefCell<LLVM<'a>>>;
pub type BigIntType<'a> = IntType<'a>; // i256



pub fn new_constraint<'a>(producer: &dyn LLVMIRProducer<'a>) -> AnyValueEnum<'a> {
    let alloca = create_alloca(producer, bool_type(producer).into(), "constraint");
    let s = producer.context().metadata_string("constraint");
    let kind = producer.context().get_kind_id("constraint");
    let node = producer.context().metadata_node(&[s.into()]);
    alloca.into_pointer_value().as_instruction().unwrap().set_metadata(node, kind).expect("Could not setup metadata marker for constraint value");
    alloca
}

#[inline]
pub fn any_value_wraps_basic_value(v: AnyValueEnum) -> bool {
    match BasicValueEnum::try_from(v) {
        Ok(_) => true,
        Err(_) => false,
    }
}

#[inline]
pub fn any_value_to_basic(v: AnyValueEnum) -> BasicValueEnum {
    BasicValueEnum::try_from(v).expect("Attempted to convert a non basic value!")
}

#[inline]
pub fn to_enum<'a, T: AnyValue<'a>>(v: T) -> AnyValueEnum<'a> {
    v.as_any_value_enum()
}

#[inline]
pub fn to_basic_enum<'a, T: AnyValue<'a>>(v: T) -> BasicValueEnum<'a> {
    any_value_to_basic(to_enum(v))
}

#[inline]
pub fn to_basic_metadata_enum(value: AnyValueEnum) -> BasicMetadataValueEnum {
    match BasicMetadataValueEnum::try_from(value) {
        Ok(v) => v,
        Err(_) => {
            panic!("Attempted to convert a value that does not support BasicMetadataValueEnum")
        }
    }
}

#[inline]
pub fn to_type_enum<'a, T: AnyType<'a>>(ty: T) -> AnyTypeEnum<'a> {
    ty.as_any_type_enum()
}

#[inline]
pub fn to_basic_type_enum<'a, T: BasicType<'a>>(ty: T) -> BasicTypeEnum<'a> {
    ty.as_basic_type_enum()
}

pub struct LLVM<'a> {
    module: Module<'a>,
    builder: Builder<'a>,
}

impl<'a> LLVM<'a> {
    pub fn from_context(context: &'a Context, name: &str) -> Self {
        LLVM {
            module: context.create_module(name),
            builder: context.create_builder(),
        }
    }

    fn unroll_loops(&self, func: FunctionValue) {
        let fpm = PassManager::create(&self.module);
        // The goal of this optimizations is to convert non-deterministic indexing
        // of signals to constant indexing. Due to how circom is designed the loops
        // must be bound and therefore we should be able to unroll them.
        // The following optimizations must be carefully selected along with their ordering
        // to achieve this effect. DO NOT TOUCH IF YOU DONT KNOW WHAT YOU ARE DOING
        // HERE. BE. DRAGONS.

        // FUNCTION LEVEL PASSES
        // Breakup alloca operations to separate local variables
        // Convert local allocations to ssa variables if possible
        fpm.add_promote_memory_to_register_pass();
        // In order to detect the inductive variable of the loop we need to separate them
        fpm.add_scalar_repl_aggregates_pass_ssa();
        // Combine operations
        fpm.add_instruction_combining_pass();
        // Re-associate values to help with detecting the loop inductive variable
        fpm.add_reassociate_pass();
        // Simplify the CFG to remove unnecessary basic blocks
        fpm.add_cfg_simplification_pass();
        // Run Global-Value-Numering to remove redundant instructions
        fpm.add_new_gvn_pass();
        // Run Sparse-Conditional-Constant-Propagation
        fpm.add_sccp_pass();
        // Rotate loops to helps with the next loop operations
        fpm.add_loop_rotate_pass();
        // Simplifies the loop induction variable to a sequence from 0 to N
        // This helps the unrolling pass better detect the induction
        fpm.add_ind_var_simplify_pass();
        // Simplify the body of each loop taking invariants out.
        // This is important to avoid duplicate code when unrolling the loops
        // fpm.add_licm_pass();
        // Run Global-Value-Numering to remove redundant instructions
        fpm.add_new_gvn_pass();
        // Combine instructions
        fpm.add_instruction_combining_pass();
        // Unroll the loops to achieve constant indexing
        fpm.add_loop_unroll_pass();
        // Simplify again the CFG after we unrolled the loops to remove unnecessary blocks
        // fpm.add_cfg_simplification_pass();

        fpm.initialize();

        // Will set changed to false if any pass did not modify the code
        // Ww assume that is because we reached a fix point
        fpm.run_on(&func);
    }

    pub fn run_optimization_passes(&self) {
        let mpm = PassManager::create(());

        // MODULE LEVEL PASSES
        // Inline functions to give hints to the function passes of how the operations work.
        mpm.add_function_inlining_pass();

        mpm.run_on(&self.module);
        for function in self.module.get_functions() {
            // Unroll any loops in the code
            self.unroll_loops(function);
        }
    }

    fn ensure_constant_indexing_of_subcmp_signals_in_function(&self, function: FunctionValue) -> Result<(), String> {
        //  todo!()
        Ok(())
    }

    fn ensure_constant_indexing_of_signals_in_function(&self, function: FunctionValue) -> Result<(), String> {
        match function.get_nth_param(0) {
            None => Err("Run function does not have a 1st parameter!".to_string()),
            Some(param) => {
                let mut users = param.get_first_use();
                while users.is_some() {
                    let user = users.unwrap().get_user();
                    if user.is_pointer_value() {
                        let user = user.into_pointer_value();
                        if let Some(inst) = user.as_instruction() {
                            if inst.get_opcode() != GetElementPtr {
                                continue;
                            }
                            // All parameters must be constant integers except the first one that should be a pointer to %0
                            for i in 1..inst.get_num_operands() {
                                let op = inst.get_operand(i).unwrap();
                                let op = op.expect_left("Can't have a BB in a GEP!");
                                if !(op.is_int_value() && op.into_int_value().is_const()) {
                                    return Err(format!("Non-deterministic indexing while accessing a component signal: {}", inst.to_string().to_string()));
                                }
                            }
                        }
                    }
                    users = users.unwrap().get_next_use();
                }
                Ok(())
            }
        }
    }

    /// Checks any access to signals both component and subcomponents
    /// and checks if the indexing value is a constant integer
    /// If not fail the validation to avoid compiling programs with
    /// non-deterministic indexing
    pub fn check_abi_consistency(&self) -> Result<(), String> {
        for function in self.module.get_functions() {
            if function.get_string_attribute(AttributeLoc::Function, "run_component").is_some() {
                self.ensure_constant_indexing_of_signals_in_function(function)?;
                self.ensure_constant_indexing_of_subcmp_signals_in_function(function)?;
            }
        }
        Ok(())
    }

    pub fn verify(&self, check_abi: bool) -> Result<(), ()> {
        // Run module verification
        self.module.verify().map_err(|llvm_err| {
            eprintln!("{}: {}", Colour::Red.paint("LLVM Module verification failed"), llvm_err.to_string());
            eprintln!("Generated LLVM:");
            self.module.print_to_stderr();
        })?;
        if check_abi {
            self.check_abi_consistency().map_err(|s| {
                eprintln!("{}: {}", Colour::Red.paint("Circom ABI consistency check failed"), s);
                eprintln!("Generated LLVM:");
                self.module.print_to_stderr();
            })?;
        }
        // Verify that bitcode can be written, parsed, and re-verified
        {
            let buff = self.module.write_bitcode_to_memory();
            let context = Context::create();
            let new_module =
                Module::parse_bitcode_from_buffer(&buff, &context).map_err(|llvm_err| {
                    eprintln!(
                        "{}: {}",
                        Colour::Red.paint("Parsing LLVM bitcode from verification buffer failed"),
                        llvm_err.to_string()
                    );
                })?;
            new_module.verify().map_err(|llvm_err| {
                eprintln!(
                    "{}: {}",
                    Colour::Red.paint("LLVM bitcode verification failed"),
                    llvm_err.to_string()
                );
            })?;
        }
        Ok(())
    }

    pub fn write_to_file(&self, path: &str) -> Result<(), ()> {

        // Write the output to file
        self.module.print_to_file(path).map_err(|llvm_err| {
            eprintln!("{}: {}", Colour::Red.paint("Writing LLVM Module failed"), llvm_err.to_string());
        })
    }
}

pub fn run_fn_name(name: String) -> String {
    format!("{}_run", name)
}

pub fn build_fn_name(name: String) -> String {
    format!("{}_build", name)
}
