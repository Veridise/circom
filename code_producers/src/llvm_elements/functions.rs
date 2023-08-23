use inkwell::basic_block::BasicBlock;
use inkwell::builder::Builder;
use inkwell::context::ContextRef;
use inkwell::debug_info::AsDIScope;
use inkwell::types::FunctionType;
use inkwell::values::{AnyValueEnum, ArrayValue, FunctionValue, IntValue, PointerValue};

use crate::llvm_elements::{BodyCtx, LLVM, LLVMIRProducer, TemplateCtx};
use crate::llvm_elements::instructions::create_gep;
use crate::llvm_elements::values::zero;

pub fn create_function<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    source_file_id: &Option<usize>,
    source_line: usize,
    source_fun_name: &str,
    name: &str,
    ty: FunctionType<'a>,
) -> FunctionValue<'a> {
    let llvm = producer.llvm();
    let f = llvm.module.add_function(name, ty, None);
    if let Some(file_id) = source_file_id {
        match llvm.get_debug_info(&file_id) {
            Err(msg) => panic!("{}", msg),
            Ok((dib, dcu)) => {
                f.set_subprogram(dib.create_function(
                    /* DIScope */ dcu.as_debug_info_scope(),
                    /* func_name */ source_fun_name,
                    /* linkage_name */ Some(name),
                    /* DIFile */ dcu.get_file(),
                    /* line_no */ source_line as u32,
                    dib.create_subroutine_type(dcu.get_file(), None, &[], 0),
                    /* is_local_to_unit */ false,
                    /* is_definition */ true,
                    /* scope_line */ 0,
                    /* DIFlags */ 0,
                    /* is_optimized */ false,
                ));
            }
        }
    };
    f
}

pub fn create_bb<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    func: FunctionValue<'a>,
    name: &str,
) -> BasicBlock<'a> {
    producer.context().append_basic_block(func, name)
}

struct FunctionCtx<'a> {
    current_function: FunctionValue<'a>,
    arena: PointerValue<'a>,
}

impl<'a> FunctionCtx<'a> {
    fn new(current_function: FunctionValue<'a>) -> Self {
        FunctionCtx {
            current_function,
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

    fn get_variable_array(&self, _producer: &dyn LLVMIRProducer<'a>) -> AnyValueEnum<'a> {
        self.arena.into()
    }
}

pub struct FunctionLLVMIRProducer<'ctx: 'prod, 'prod> {
    parent: &'prod dyn LLVMIRProducer<'ctx>,
    ctx: FunctionCtx<'ctx>,
}

impl<'ctx, 'prod> FunctionLLVMIRProducer<'ctx, 'prod> {
    pub fn new(
        producer: &'prod dyn LLVMIRProducer<'ctx>,
        current_function: FunctionValue<'ctx>,
    ) -> Self {
        FunctionLLVMIRProducer { parent: producer, ctx: FunctionCtx::new(current_function) }
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

    fn template_ctx(&self) -> &dyn TemplateCtx<'ctx> {
        self.parent.template_ctx()
    }

    fn body_ctx(&self) -> &dyn BodyCtx<'ctx> {
        &self.ctx
    }

    fn current_function(&self) -> FunctionValue<'ctx> {
        self.ctx.current_function
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

struct ExtractedFunctionCtx<'a> {
    current_function: FunctionValue<'a>,
    //TODO: will have at least the signals-arena [0 x i256]* and lvars [0 x i256]* from the template and possible subcmps
    signals: PointerValue<'a>,
    lvars: PointerValue<'a>,
}

impl<'a> ExtractedFunctionCtx<'a> {
    fn new(current_function: FunctionValue<'a>) -> Self {
        ExtractedFunctionCtx {
            current_function,
            signals: current_function
                .get_nth_param(0)
                .expect("Function must have at least 1 argument for signal array!")
                .into_pointer_value(),
            lvars: current_function
                .get_nth_param(1)
                .expect("Function must have at least 2 arguments for signal and lvar arrays!")
                .into_pointer_value(),
        }
    }
}

impl<'a> BodyCtx<'a> for ExtractedFunctionCtx<'a> {
    fn get_variable(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        index: IntValue<'a>,
    ) -> AnyValueEnum<'a> {
        //'gep' must read through the pointer with 0 and then index the array
        create_gep(producer, self.lvars, &[zero(producer), index])
    }

    fn get_variable_array(&self, _producer: &dyn LLVMIRProducer<'a>) -> AnyValueEnum<'a> {
        self.lvars.into()
    }
}

impl<'a> TemplateCtx<'a> for ExtractedFunctionCtx<'a> {
    fn load_subcmp(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        id: AnyValueEnum<'a>,
    ) -> PointerValue<'a> {
        todo!();
        //create_gep(producer, self.subcmps, &[zero(producer), id.into_int_value()]).into_pointer_value()
    }

    fn load_subcmp_addr(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        id: AnyValueEnum<'a>,
    ) -> PointerValue<'a> {
        todo!();
        // let signals = create_gep(
        //     producer,
        //     self.subcmps,
        //     &[zero(producer), id.into_int_value(), zero(producer)],
        // )
        // .into_pointer_value();
        // create_load(producer, signals).into_pointer_value()
    }

    fn load_subcmp_counter(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        id: AnyValueEnum<'a>,
    ) -> PointerValue<'a> {
        todo!();
        // create_gep(
        //     producer,
        //     self.subcmps,
        //     &[zero(producer), id.into_int_value(), create_literal_u32(producer, 1)],
        // )
        // .into_pointer_value()
    }

    fn get_signal(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        index: IntValue<'a>,
    ) -> AnyValueEnum<'a> {
        //'gep' must read through the pointer with 0 and then index the array
        create_gep(producer, self.signals, &[zero(producer), index])
    }

    fn get_signal_array(&self, _producer: &dyn LLVMIRProducer<'a>) -> AnyValueEnum<'a> {
        self.signals.into()
    }
}

pub struct ExtractedFunctionLLVMIRProducer<'ctx: 'prod, 'prod> {
    parent: &'prod dyn LLVMIRProducer<'ctx>,
    ctx: ExtractedFunctionCtx<'ctx>,
}

impl<'ctx, 'prod> ExtractedFunctionLLVMIRProducer<'ctx, 'prod> {
    pub fn new(
        producer: &'prod dyn LLVMIRProducer<'ctx>,
        current_function: FunctionValue<'ctx>,
    ) -> Self {
        ExtractedFunctionLLVMIRProducer {
            parent: producer,
            ctx: ExtractedFunctionCtx::new(current_function),
        }
    }
}

impl<'ctx, 'prod> LLVMIRProducer<'ctx> for ExtractedFunctionLLVMIRProducer<'ctx, 'prod> {
    fn llvm(&self) -> &LLVM<'ctx> {
        self.parent.llvm()
    }

    fn context(&self) -> ContextRef<'ctx> {
        self.parent.context()
    }

    fn set_current_bb(&self, bb: BasicBlock<'ctx>) {
        self.parent.set_current_bb(bb)
    }

    fn template_ctx(&self) -> &dyn TemplateCtx<'ctx> {
        &self.ctx
    }

    fn body_ctx(&self) -> &dyn BodyCtx<'ctx> {
        &self.ctx
    }

    fn current_function(&self) -> FunctionValue<'ctx> {
        self.ctx.current_function
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
