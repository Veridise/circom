use inkwell::attributes::{Attribute, AttributeLoc};
use inkwell::basic_block::BasicBlock;
use inkwell::builder::Builder;
use inkwell::context::ContextRef;
use inkwell::types::FunctionType;
use inkwell::values::{AnyValueEnum, ArrayValue, FunctionValue, IntValue, PointerValue};

use crate::llvm_elements::{BodyCtx, LLVM, LLVMIRProducer};
use crate::llvm_elements::instructions::create_gep;
use crate::llvm_elements::template::TemplateCtx;

pub fn create_function<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    name: &str,
    ty: FunctionType<'a>,
) -> FunctionValue<'a> {
    producer.llvm().module.add_function(name, ty, None)
}

pub fn create_bb<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    func: FunctionValue<'a>,
    name: &str,
) -> BasicBlock<'a> {
    producer.context().append_basic_block(func, name)
}

pub struct FunctionLLVMIRProducer<'ctx: 'prod, 'prod> {
    parent: &'prod dyn LLVMIRProducer<'ctx>,
    function_ctx: FunctionCtx<'ctx>,
    current_function: FunctionValue<'ctx>,
}

impl<'ctx, 'prod> FunctionLLVMIRProducer<'ctx, 'prod> {
    pub fn new(
        producer: &'prod dyn LLVMIRProducer<'ctx>,
        current_function: FunctionValue<'ctx>,
    ) -> Self {
        FunctionLLVMIRProducer {
            parent: producer,
            function_ctx: FunctionCtx::new(current_function),
            current_function,
        }
    }
}

impl<'ctx, 'prod> LLVMIRProducer<'ctx> for FunctionLLVMIRProducer<'ctx, 'prod> {
    fn llvm(&self) -> &LLVM<'ctx> {
        self.parent.llvm()
    }

    fn context(&self) -> ContextRef<'ctx> {
        self.parent.context()
    }

    fn set_current_bb(&self, bb: BasicBlock<'ctx>) {
        self.parent.set_current_bb(bb)
    }

    fn template_ctx(&self) -> &TemplateCtx<'ctx> {
        self.parent.template_ctx()
    }

    fn body_ctx(&self) -> &dyn BodyCtx<'ctx> {
        &self.function_ctx
    }

    fn current_function(&self) -> FunctionValue<'ctx> {
        self.current_function
    }

    fn builder(&self) -> &Builder<'ctx> {
        self.parent.builder()
    }

    fn constant_fields(&self) -> &Vec<String> {
        self.parent.constant_fields()
    }

    fn get_template_mem_arg(&self, _run_fn: FunctionValue<'ctx>) -> ArrayValue<'ctx> {
        panic!("The function llvm producer can't extract the template argument of a run function!");
    }
}

pub struct FunctionCtx<'a> {
    arena: PointerValue<'a>,
}

impl<'a> FunctionCtx<'a> {
    pub fn new(current_function: FunctionValue<'a>) -> Self {
        FunctionCtx {
            arena: current_function
                .get_nth_param(0)
                .expect("Function needs at least one argument for the arena!")
                .into_pointer_value(),
        }
    }
}

impl<'a> BodyCtx<'a> for FunctionCtx<'a> {
    fn get_variable(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        index: IntValue<'a>,
    ) -> AnyValueEnum<'a> {
        create_gep(producer, self.arena, &[index])
    }
}

pub fn mark_as_noinline(producer: &dyn LLVMIRProducer, func: FunctionValue) {
    let attr_id = Attribute::get_named_enum_kind_id("noinline");
    let attr = producer.context().create_enum_attribute(attr_id, 1);
    func.add_attribute(AttributeLoc::Function, attr);
}

pub fn mark_as_component_run_function(producer: &dyn LLVMIRProducer, func: FunctionValue, component_name: &str) {
    let attr = producer.context().create_string_attribute("run_component", component_name);
    func.add_attribute(AttributeLoc::Function, attr);
}
