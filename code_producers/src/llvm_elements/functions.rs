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
    lvars: PointerValue<'a>,
    signals: Option<PointerValue<'a>>,
    other: Vec<PointerValue<'a>>,
}

impl<'a> ExtractedFunctionCtx<'a> {
    fn new(current_function: FunctionValue<'a>) -> Self {
        // NOTE: The 'lvars' [0 x i256]* parameter must always be present.
        //  The 'signals' [0 x i256]* parameter is optional (to allow this to
        //  handle the generated array index load functions for the unroller).
        ExtractedFunctionCtx {
            current_function,
            lvars: current_function
                .get_nth_param(0)
                .expect("Function must have at least 1 argument for lvar array!")
                .into_pointer_value(),
            signals: current_function.get_nth_param(1).map(|x| x.into_pointer_value()),
            other: current_function
                .get_param_iter()
                .skip(2)
                .map(|x| x.into_pointer_value())
                .collect::<Vec<_>>(),
        }
    }

    fn get_signals_ptr(&self) -> PointerValue<'a> {
        self.signals.expect(
            format!("No signals argument for {:?}", self.current_function.get_name()).as_str(),
        )
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
        _producer: &dyn LLVMIRProducer<'a>,
        _id: AnyValueEnum<'a>,
    ) -> PointerValue<'a> {
        //NOTE: only used by CreateCmpBucket::produce_llvm_ir
        //TODO: I think instead of ID defining an array index in the gep, it will need to define a static index
        //  in an array of subcomponents in this context (i.e. self.subcmps[id] with offsets [0,0]).
        todo!("load_subcmp {} from {:?}", _id, self.other);
        //create_gep(producer, self.subcmps, &[zero(producer), id.into_int_value()]).into_pointer_value()
    }

    fn load_subcmp_addr(
        &self,
        _producer: &dyn LLVMIRProducer<'a>,
        id: AnyValueEnum<'a>,
    ) -> PointerValue<'a> {
        let num = id
            .into_int_value()
            .get_zero_extended_constant()
            .expect("must reference a constant argument index");
        *self.other.get(num as usize).expect("must reference a known argument index")
    }

    fn load_subcmp_counter(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        _id: AnyValueEnum<'a>,
    ) -> PointerValue<'a> {
        // Use null pointer to force StoreBucket::produce_llvm_ir to skip counter increment
        producer.context().i32_type().ptr_type(Default::default()).const_null()
    }

    fn get_signal(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        index: IntValue<'a>,
    ) -> AnyValueEnum<'a> {
        //'gep' must read through the pointer with 0 and then index the array
        create_gep(producer, self.get_signals_ptr(), &[zero(producer), index])
    }

    fn get_signal_array(&self, _producer: &dyn LLVMIRProducer<'a>) -> AnyValueEnum<'a> {
        self.get_signals_ptr().into()
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
