// TODO: Rename this module to something more appropriate

use crate::llvm_elements::LLVMIRProducer;

//NOTE: LLVM identifiers can use "." and circom cannot which makes checking for this prefix unambiguous.
pub const GENERATED_FN_PREFIX: &str = "..generated..";
pub const CONSTRAINT_VALUES_FN_NAME: &str = "__constraint_values";
pub const CONSTRAINT_VALUE_FN_NAME: &str = "__constraint_value";
pub const ASSERT_FN_NAME: &str = "__assert";
pub const LLVM_DONOTHING_FN_NAME: &str = "llvm.donothing";

mod stdlib {
    use inkwell::intrinsics::Intrinsic;
    use inkwell::values::AnyValue;

    use crate::llvm_elements::functions::{create_bb, create_function};
    use crate::llvm_elements::instructions::{
        create_br, create_call, create_conditional_branch, create_eq, create_return_void,
        create_store,
    };
    use crate::llvm_elements::LLVMIRProducer;
    use crate::llvm_elements::types::{bigint_type, bool_type, void_type};
    use super::{
        ASSERT_FN_NAME, CONSTRAINT_VALUE_FN_NAME, CONSTRAINT_VALUES_FN_NAME, LLVM_DONOTHING_FN_NAME,
    };

    pub fn llvm_donothing_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
        Intrinsic::find(LLVM_DONOTHING_FN_NAME)
            .unwrap()
            .get_declaration(&producer.llvm().module, &[])
            .unwrap();
    }

    pub fn constraint_values_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
        let bigint_ty = bigint_type(producer);
        let args = &[
            bigint_ty.into(),
            bigint_ty.into(),
            bool_type(producer).ptr_type(Default::default()).into(),
        ];
        let void_ty = void_type(producer);
        let func = create_function(
            producer,
            &None,
            0,
            "",
            CONSTRAINT_VALUES_FN_NAME,
            void_ty.fn_type(args, false),
        );
        let main = create_bb(producer, func, "main");
        producer.set_current_bb(main);

        let lhs = func.get_nth_param(0).unwrap();
        let rhs = func.get_nth_param(1).unwrap();
        let constr = func.get_nth_param(2).unwrap();

        let cmp = create_eq(producer, lhs.into_int_value(), rhs.into_int_value());
        create_store(producer, constr.into_pointer_value(), cmp);
        create_return_void(producer);
    }

    pub fn constraint_value_fn<'a, 'b>(producer: &dyn LLVMIRProducer<'a>) {
        let args =
            &[bool_type(producer).into(), bool_type(producer).ptr_type(Default::default()).into()];
        let void_ty = void_type(producer);
        let func = create_function(
            producer,
            &None,
            0,
            "",
            CONSTRAINT_VALUE_FN_NAME,
            void_ty.fn_type(args, false),
        );
        let main = create_bb(producer, func, "main");
        producer.set_current_bb(main);

        let bool = func.get_nth_param(0).unwrap();
        let constr = func.get_nth_param(1).unwrap();

        create_store(producer, constr.into_pointer_value(), bool.as_any_value_enum());
        create_return_void(producer);
    }

    pub fn assert_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
        let func = create_function(
            producer,
            &None,
            0,
            "",
            ASSERT_FN_NAME,
            void_type(producer).fn_type(&[bool_type(producer).into()], false),
        );
        let main = create_bb(producer, func, "main");
        let if_false = create_bb(producer, func, "if.assert.fails");
        let end = create_bb(producer, func, "end");
        let bool = func.get_nth_param(0).unwrap();
        producer.set_current_bb(main);
        create_conditional_branch(producer, bool.into_int_value(), end, if_false);
        producer.set_current_bb(if_false);
        create_call(producer, "__abort", &[]);
        create_br(producer, end);
        producer.set_current_bb(end);
        create_return_void(producer);
    }

    pub fn abort_declared_fn<'a>(producer: &dyn LLVMIRProducer<'a>) {
        let f = create_function(
            producer,
            &None,
            0,
            "",
            "__abort",
            void_type(producer).fn_type(&[], false),
        );
        f.set_linkage(inkwell::module::Linkage::External);
    }
}

pub fn load_stdlib<'a>(producer: &dyn LLVMIRProducer<'a>) {
    stdlib::llvm_donothing_fn(producer);
    stdlib::constraint_values_fn(producer);
    stdlib::constraint_value_fn(producer);
    stdlib::abort_declared_fn(producer);
    stdlib::assert_fn(producer);
}
