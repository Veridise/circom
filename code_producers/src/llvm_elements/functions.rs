use inkwell::attributes::AttributeLoc;
use inkwell::basic_block::BasicBlock;
use inkwell::debug_info::AsDIScope;
use inkwell::types::FunctionType;
use inkwell::values::{AnyValueEnum, ArrayValue, FunctionValue, IntValue, PointerValue};
use super::{BaseBodyCtx, BodyCtx, ConstraintKind, LLVM, LLVMIRProducer, TemplateCtx};
use super::instructions::{create_gep, is_terminator};
use super::values::zero;

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
    f.set_linkage(inkwell::module::Linkage::Internal); //default to Internal, allows removal if unused
    if let Some(file_id) = source_file_id {
        match llvm.get_debug_info(file_id) {
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

/// Remove any instructions that appear after a terminator because the LLVM verifier will flag it.
pub fn cleanup_function(func: FunctionValue) {
    for bb in func.get_basic_blocks() {
        let mut found_terminator = false;
        let mut next = bb.get_first_instruction();
        while let Some(i) = next {
            next = i.get_next_instruction();
            if found_terminator {
                i.erase_from_basic_block();
            } else {
                found_terminator = is_terminator(i);
            }
        }
    }
}

pub fn add_attribute(producer: &dyn LLVMIRProducer, func: FunctionValue, key: &str, val: &str) {
    func.add_attribute(
        AttributeLoc::Function,
        producer.llvm().context().create_string_attribute(key, val),
    );
}

pub fn create_bb<'a>(
    producer: &dyn LLVMIRProducer<'a>,
    func: FunctionValue<'a>,
    name: &str,
) -> BasicBlock<'a> {
    producer.llvm().context().append_basic_block(func, name)
}

struct StdFunctionCtx<'a> {
    base: BaseBodyCtx<'a>,
    arena: PointerValue<'a>,
}

impl<'a> StdFunctionCtx<'a> {
    fn new(current_function: FunctionValue<'a>) -> Self {
        StdFunctionCtx {
            base: BaseBodyCtx::new(current_function),
            arena: current_function
                .get_nth_param(0)
                .expect("Function needs at least one argument for the arena!")
                .into_pointer_value(),
        }
    }
}

impl<'a> BodyCtx<'a> for StdFunctionCtx<'a> {
    fn get_lvar_ref(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        index: IntValue<'a>,
    ) -> PointerValue<'a> {
        create_gep(producer, self.arena, &[index])
    }

    fn get_variable_array(&self, _producer: &dyn LLVMIRProducer<'a>) -> PointerValue<'a> {
        self.arena
    }

    fn get_wrapping_constraint(&self) -> Option<ConstraintKind> {
        self.base.get_wrapping_constraint()
    }

    fn set_wrapping_constraint(&self, value: Option<ConstraintKind>) {
        self.base.set_wrapping_constraint(value)
    }
}

pub struct FunctionLLVMIRProducer<'ctx: 'prod, 'prod> {
    parent: &'prod dyn LLVMIRProducer<'ctx>,
    ctx: StdFunctionCtx<'ctx>,
}

impl<'ctx, 'prod> FunctionLLVMIRProducer<'ctx, 'prod> {
    pub fn new(
        producer: &'prod dyn LLVMIRProducer<'ctx>,
        current_function: FunctionValue<'ctx>,
    ) -> Self {
        FunctionLLVMIRProducer { parent: producer, ctx: StdFunctionCtx::new(current_function) }
    }
}

impl<'ctx, 'prod> LLVMIRProducer<'ctx> for FunctionLLVMIRProducer<'ctx, 'prod> {
    fn llvm(&self) -> &LLVM<'ctx> {
        self.parent.llvm()
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
        self.ctx.base.current_function
    }

    fn get_ff_constants(&self) -> &Vec<String> {
        self.parent.get_ff_constants()
    }

    fn get_template_mem_arg(&self, _run_fn: FunctionValue<'ctx>) -> ArrayValue<'ctx> {
        panic!("The function llvm producer can't extract the template argument of a run function!");
    }

    fn get_main_template_header(&self) -> &String {
        self.parent.get_main_template_header()
    }
}

struct ExtractedFunctionCtx<'a> {
    base: BaseBodyCtx<'a>,
    // NOTE: The 'lvars' [0 x i256]* parameter must always be present (at position 0).
    //  The 'signals' [0 x i256]* parameter (at position 1) is optional (to allow
    //  this to handle the generated array index load functions for the unroller).
    args: Vec<PointerValue<'a>>,
}

impl<'a> ExtractedFunctionCtx<'a> {
    fn new(current_function: FunctionValue<'a>) -> Self {
        ExtractedFunctionCtx {
            base: BaseBodyCtx::new(current_function),
            args: current_function
                .get_param_iter()
                .map(|x| x.into_pointer_value())
                .collect::<Vec<_>>(),
        }
    }

    #[allow(clippy::get_first)]
    fn get_lvars_ptr(&self) -> PointerValue<'a> {
        *self
            .args
            .get(0)
            .unwrap_or_else(|| panic!("Function must have at least 1 argument for lvar array!"))
    }

    fn get_signals_ptr(&self) -> PointerValue<'a> {
        *self.args.get(1).unwrap_or_else(|| {
            panic!("No signals argument for {:?}!", self.base.current_function.get_name())
        })
    }

    fn get_arg_ptr(&self, id: AnyValueEnum<'a>) -> PointerValue<'a> {
        let num = id
            .into_int_value()
            .get_zero_extended_constant()
            .expect("must reference a constant argument index");
        *self
            .args
            .get(num as usize)
            .unwrap_or_else(|| panic!("must reference a valid argument index"))
    }
}

impl<'a> BodyCtx<'a> for ExtractedFunctionCtx<'a> {
    fn get_lvar_ref(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        index: IntValue<'a>,
    ) -> PointerValue<'a> {
        //'gep' must read through the pointer with 0 and then index the array
        create_gep(producer, self.get_lvars_ptr(), &[zero(producer), index])
    }

    fn get_variable_array(&self, _producer: &dyn LLVMIRProducer<'a>) -> PointerValue<'a> {
        self.get_lvars_ptr()
    }

    fn get_wrapping_constraint(&self) -> Option<ConstraintKind> {
        self.base.get_wrapping_constraint()
    }

    fn set_wrapping_constraint(&self, value: Option<ConstraintKind>) {
        self.base.set_wrapping_constraint(value)
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
    ) -> PointerValue<'a> {
        assert_eq!(zero(producer), index);
        create_gep(producer, self.load_subcmp_addr(producer, subcmp_id), &[index])
    }

    fn get_signal_ref(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        index: IntValue<'a>,
    ) -> PointerValue<'a> {
        //'gep' must read through the pointer with 0 and then index the array
        create_gep(producer, self.get_signals_ptr(), &[zero(producer), index])
    }

    fn get_signal_array(&self, _producer: &dyn LLVMIRProducer<'a>) -> PointerValue<'a> {
        self.get_signals_ptr()
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
        self.ctx.base.current_function
    }

    fn get_ff_constants(&self) -> &Vec<String> {
        self.parent.get_ff_constants()
    }

    fn get_template_mem_arg(&self, _run_fn: FunctionValue<'ctx>) -> ArrayValue<'ctx> {
        panic!("The function llvm producer can't extract the template argument of a run function!");
    }

    fn get_main_template_header(&self) -> &String {
        self.parent.get_main_template_header()
    }
}
