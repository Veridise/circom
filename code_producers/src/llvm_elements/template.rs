use std::default::Default;
use inkwell::basic_block::BasicBlock;
use inkwell::builder::Builder;
use inkwell::context::ContextRef;
use inkwell::types::{AnyType, BasicType, PointerType};
use inkwell::values::{AnyValueEnum, ArrayValue, FunctionValue, IntValue, PointerValue};
use crate::llvm_elements::{BodyCtx, LLVM, LLVMIRProducer, TemplateCtx};
use crate::llvm_elements::instructions::{create_alloca, create_gep, create_load};
use crate::llvm_elements::types::{bigint_type, i32_type};
use crate::llvm_elements::values::{create_literal_u32, zero};

pub fn create_template_struct<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    n_signals: usize,
) -> PointerType<'a> {
    bigint_type(producer).array_type(n_signals as u32).ptr_type(Default::default())
}

struct StdTemplateCtx<'a> {
    stack: PointerValue<'a>,
    subcmps: PointerValue<'a>,
    current_function: FunctionValue<'a>,
    template_type: PointerType<'a>,
    signals_arg_offset: usize,
}

#[inline]
fn setup_subcmps<'a>(producer: &dyn LLVMIRProducer<'a>, number_subcmps: usize) -> PointerValue<'a> {
    // [ number_subcmps x { [ 0 x i256 ]*, int} ]
    let signals_ptr = bigint_type(producer).array_type(0).ptr_type(Default::default());
    let counter_ty = i32_type(producer);
    let subcmp_ty = producer
        .context()
        .struct_type(&[signals_ptr.as_basic_type_enum(), counter_ty.as_basic_type_enum()], false);
    let subcmps_ty = subcmp_ty.array_type(number_subcmps as u32);
    create_alloca(producer, subcmps_ty.as_any_type_enum(), "subcmps").into_pointer_value()
}

#[inline]
fn setup_stack<'a>(producer: &dyn LLVMIRProducer<'a>, stack_depth: usize) -> PointerValue<'a> {
    let bigint_ty = bigint_type(producer);
    create_alloca(producer, bigint_ty.array_type(stack_depth as u32).into(), "lvars")
        .into_pointer_value()
}

impl<'a> StdTemplateCtx<'a> {
    fn new(
        producer: &dyn LLVMIRProducer<'a>,
        stack_depth: usize,
        number_subcmps: usize,
        current_function: FunctionValue<'a>,
        template_type: PointerType<'a>,
        signals_arg_offset: usize,
    ) -> Self {
        StdTemplateCtx {
            stack: setup_stack(producer, stack_depth),
            subcmps: setup_subcmps(producer, number_subcmps),
            current_function,
            template_type,
            signals_arg_offset,
        }
    }
}

impl<'a> TemplateCtx<'a> for StdTemplateCtx<'a> {
    fn load_subcmp(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        id: AnyValueEnum<'a>,
    ) -> PointerValue<'a> {
        create_gep(producer, self.subcmps, &[zero(producer), id.into_int_value()])
            .into_pointer_value()
    }

    fn load_subcmp_addr(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        id: AnyValueEnum<'a>,
    ) -> PointerValue<'a> {
        let signals = create_gep(
            producer,
            self.subcmps,
            &[zero(producer), id.into_int_value(), zero(producer)],
        )
        .into_pointer_value();
        create_load(producer, signals).into_pointer_value()
    }

    fn load_subcmp_counter(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        id: AnyValueEnum<'a>,
        _implicit: bool,
    ) -> Option<PointerValue<'a>> {
        Some(
            create_gep(
                producer,
                self.subcmps,
                &[zero(producer), id.into_int_value(), create_literal_u32(producer, 1)],
            )
            .into_pointer_value(),
        )
    }

    fn get_subcmp_signal(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        subcmp_id: AnyValueEnum<'a>,
        index: IntValue<'a>,
    ) -> AnyValueEnum<'a> {
        create_gep(producer, self.load_subcmp_addr(producer, subcmp_id), &[zero(producer), index])
    }

    fn get_signal(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        index: IntValue<'a>,
    ) -> AnyValueEnum<'a> {
        let signals = self.current_function.get_nth_param(self.signals_arg_offset as u32).unwrap();
        create_gep(producer, signals.into_pointer_value(), &[zero(producer), index])
    }

    fn get_signal_array(&self, _producer: &dyn LLVMIRProducer<'a>) -> AnyValueEnum<'a> {
        let signals = self.current_function.get_nth_param(self.signals_arg_offset as u32).unwrap();
        signals.into_pointer_value().into()
    }
}

impl<'a> BodyCtx<'a> for StdTemplateCtx<'a> {
    /// Returns a reference to the local variable associated to the index
    fn get_variable(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        index: IntValue<'a>,
    ) -> AnyValueEnum<'a> {
        create_gep(producer, self.stack, &[zero(producer), index])
    }

    fn get_variable_array(&self, _producer: &dyn LLVMIRProducer<'a>) -> AnyValueEnum<'a> {
        self.stack.into()
    }
}

pub struct TemplateLLVMIRProducer<'ctx: 'prod, 'prod> {
    parent: &'prod dyn LLVMIRProducer<'ctx>,
    ctx: StdTemplateCtx<'ctx>,
}

impl<'a, 'b> LLVMIRProducer<'a> for TemplateLLVMIRProducer<'a, 'b> {
    fn llvm(&self) -> &LLVM<'a> {
        self.parent.llvm()
    }

    fn context(&self) -> ContextRef<'a> {
        self.parent.context()
    }

    fn set_current_bb(&self, bb: BasicBlock<'a>) {
        self.parent.set_current_bb(bb)
    }

    fn template_ctx(&self) -> &dyn TemplateCtx<'a> {
        &self.ctx
    }

    fn body_ctx(&self) -> &dyn BodyCtx<'a> {
        &self.ctx
    }

    fn current_function(&self) -> FunctionValue<'a> {
        self.ctx.current_function
    }

    fn builder(&self) -> &Builder<'a> {
        self.parent.builder()
    }

    fn constant_fields(&self) -> &Vec<String> {
        self.parent.constant_fields()
    }

    fn get_template_mem_arg(&self, run_fn: FunctionValue<'a>) -> ArrayValue<'a> {
        run_fn.get_nth_param(self.ctx.signals_arg_offset as u32).unwrap().into_array_value()
    }

    fn get_main_template_header(&self) -> &String {
        self.parent.get_main_template_header()
    }
}

impl<'a, 'b> TemplateLLVMIRProducer<'a, 'b> {
    pub fn new(
        parent: &'b dyn LLVMIRProducer<'a>,
        stack_depth: usize,
        number_subcmps: usize,
        current_function: FunctionValue<'a>,
        template_type: PointerType<'a>,
        signals_arg_offset: usize,
    ) -> Self {
        TemplateLLVMIRProducer {
            parent,
            ctx: StdTemplateCtx::new(
                parent,
                stack_depth,
                number_subcmps,
                current_function,
                template_type,
                signals_arg_offset,
            ),
        }
    }
}
