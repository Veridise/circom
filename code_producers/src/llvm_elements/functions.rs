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
    // NOTE: The 'lvars' [0 x i256]* parameter must always be present (at position 0).
    //  The 'signals' [0 x i256]* parameter (at position 1) is optional (to allow
    //  this to handle the generated array index load functions for the unroller).
    args: Vec<PointerValue<'a>>,
}

impl<'a> ExtractedFunctionCtx<'a> {
    fn new(current_function: FunctionValue<'a>) -> Self {
        ExtractedFunctionCtx {
            current_function,
            args: current_function
                .get_param_iter()
                .map(|x| x.into_pointer_value())
                .collect::<Vec<_>>(),
        }
    }

    fn get_lvars_ptr(&self) -> PointerValue<'a> {
        *self.args.get(0).expect("Function must have at least 1 argument for lvar array!")
    }

    fn get_signals_ptr(&self) -> PointerValue<'a> {
        *self.args.get(1).expect(
            format!("No signals argument for {:?}", self.current_function.get_name()).as_str(),
        )
    }

    fn get_arg_ptr(&self, id: AnyValueEnum<'a>) -> PointerValue<'a> {
        let num = id
            .into_int_value()
            .get_zero_extended_constant()
            .expect("must reference a constant argument index");
        *self.args.get(num as usize).expect("must reference a valid argument index")
    }
}

impl<'a> BodyCtx<'a> for ExtractedFunctionCtx<'a> {
    fn get_variable(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        index: IntValue<'a>,
    ) -> AnyValueEnum<'a> {
        //'gep' must read through the pointer with 0 and then index the array
        create_gep(producer, self.get_lvars_ptr(), &[zero(producer), index])
    }

    fn get_variable_array(&self, _producer: &dyn LLVMIRProducer<'a>) -> AnyValueEnum<'a> {
        self.get_lvars_ptr().into()
    }
}

impl<'a> TemplateCtx<'a> for ExtractedFunctionCtx<'a> {
    fn load_subcmp(
        &self,
        _producer: &dyn LLVMIRProducer<'a>,
        _id: AnyValueEnum<'a>,
    ) -> PointerValue<'a> {
        unreachable!()
    }

    fn load_subcmp_addr(
        &self,
        _producer: &dyn LLVMIRProducer<'a>,
        id: AnyValueEnum<'a>,
    ) -> PointerValue<'a> {
        self.get_arg_ptr(id)
    }

    fn load_subcmp_counter(
        &self,
        _producer: &dyn LLVMIRProducer<'a>,
        id: AnyValueEnum<'a>,
        implicit: bool,
    ) -> Option<PointerValue<'a>> {
        if implicit {
            // Use None for the implicit case from StoreBucket::produce_llvm_ir so it will
            //  skip the counter decrement when using this ExtractedFunctionCtx because the
            //  counter decrement is generated explicitly inside the extracted functions.
            None
        } else {
            Some(self.get_arg_ptr(id))
        }
    }

    fn get_subcmp_signal(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        subcmp_id: AnyValueEnum<'a>,
        index: IntValue<'a>,
    ) -> AnyValueEnum<'a> {
        assert_eq!(zero(producer), index);
        create_gep(producer, self.load_subcmp_addr(producer, subcmp_id), &[index])
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
