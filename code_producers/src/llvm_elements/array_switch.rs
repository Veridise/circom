use std::{ops::Range, collections::HashSet};
use inkwell::types::PointerType;
use crate::llvm_elements::LLVMIRProducer;
use super::types::bigint_type;

mod array_switch_private {
    use std::convert::TryInto;
    use std::ops::Range;
    use lazy_regex::regex_captures;
    use crate::llvm_elements::functions::{create_bb, create_function};
    use crate::llvm_elements::instructions::{
        create_call, create_return_void, create_store, create_gep, create_load, create_return,
        create_switch,
    };
    use crate::llvm_elements::stdlib::ASSERT_FN_NAME;
    use crate::llvm_elements::LLVMIRProducer;
    use crate::llvm_elements::types::{bigint_type, bool_type, i32_type, void_type};
    use crate::llvm_elements::values::zero;

    pub fn get_load_symbol(index_range: &Range<usize>) -> String {
        format!("__array_load__{}_to_{}", index_range.start, index_range.end)
    }

    pub fn get_store_symbol(index_range: &Range<usize>) -> String {
        format!("__array_store__{}_to_{}", index_range.start, index_range.end)
    }

    pub fn get_array_switch_range(name: &str) -> Option<Range<usize>> {
        regex_captures!(r"__array_(load|store)__(\d+)_to_(\d+)", name).map(|(_, _, start, end)| {
            let start = start.parse::<usize>().unwrap();
            let end = end.parse::<usize>().unwrap();
            start..end
        })
    }

    pub fn create_array_load_fn(producer: &dyn LLVMIRProducer, index_range: &Range<usize>) {
        // args: array, index
        // return: bigint loaded from array
        let bool_ty = bool_type(producer);
        let bigint_ty = bigint_type(producer);
        let i32_ty = i32_type(producer);
        let args = &[bigint_ty.array_type(0).ptr_type(Default::default()).into(), i32_ty.into()];

        let func = create_function(
            producer,
            &None,
            0,
            "",
            &get_load_symbol(index_range),
            bigint_ty.fn_type(args, false),
        );
        let main = create_bb(producer, func, "main");

        let arr = func.get_nth_param(0).unwrap().into_pointer_value();
        let arr_idx = func.get_nth_param(1).unwrap().into_int_value();

        // build the switch cases
        let mut cases = vec![];
        for idx in index_range.clone() {
            let case_val = i32_ty.const_int(idx.try_into().unwrap(), false);
            let case_bb = create_bb(producer, func, format!("case_{}", idx).as_str());
            producer.set_current_bb(case_bb);

            let ptr = create_gep(producer, arr, &[zero(producer), case_val]);
            let val = create_load(producer, ptr).into_int_value();
            create_return(producer, val);

            cases.push((case_val, case_bb));
        }
        // -- else case
        let else_bb = create_bb(producer, func, "else");
        producer.set_current_bb(else_bb);
        create_call(producer, ASSERT_FN_NAME, &[bool_ty.const_zero().into()]);
        create_return(producer, bigint_ty.const_zero());

        producer.set_current_bb(main);

        create_switch(producer, arr_idx, else_bb, &cases);
    }

    pub fn create_array_store_fn(producer: &dyn LLVMIRProducer, index_range: &Range<usize>) {
        // args: array, index, value
        // return: void
        let bool_ty = bool_type(producer);
        let bigint_ty = bigint_type(producer);
        let i32_ty = i32_type(producer);
        let void_ty = void_type(producer);
        let args = &[
            bigint_ty.array_type(0).ptr_type(Default::default()).into(),
            i32_ty.into(),
            bigint_ty.into(),
        ];
        let func = create_function(
            producer,
            &None,
            0,
            "",
            &get_store_symbol(index_range),
            void_ty.fn_type(args, false),
        );
        let main = create_bb(producer, func, "main");

        let arr = func.get_nth_param(0).unwrap().into_pointer_value();
        let arr_idx = func.get_nth_param(1).unwrap().into_int_value();
        let val = func.get_nth_param(2).unwrap();

        // build the switch cases
        let mut cases = vec![];
        for idx in index_range.clone() {
            let case_val = i32_ty.const_int(idx.try_into().unwrap(), false);
            let case_bb = create_bb(producer, func, format!("case_{}", idx).as_str());
            producer.set_current_bb(case_bb);

            let ptr = create_gep(producer, arr, &[zero(producer), case_val]);
            create_store(producer, ptr, val.into());
            create_return_void(producer);

            cases.push((case_val, case_bb));
        }
        // -- else case
        let else_bb = create_bb(producer, func, "else");
        producer.set_current_bb(else_bb);
        create_call(producer, ASSERT_FN_NAME, &[bool_ty.const_zero().into()]);
        create_return_void(producer);

        producer.set_current_bb(main);

        create_switch(producer, arr_idx, else_bb, &cases);
    }
}

pub fn array_ptr_ty<'a>(producer: &dyn LLVMIRProducer<'a>) -> PointerType<'a> {
    let bigint_ty = bigint_type(producer);
    bigint_ty.array_type(0).ptr_type(Default::default())
}

pub fn load_array_load_fns(
    producer: &dyn LLVMIRProducer,
    scheduled_array_loads: &HashSet<Range<usize>>,
) {
    for range in scheduled_array_loads {
        array_switch_private::create_array_load_fn(producer, range);
    }
}

pub fn load_array_stores_fns(
    producer: &dyn LLVMIRProducer,
    scheduled_array_stores: &HashSet<Range<usize>>,
) {
    for range in scheduled_array_stores {
        array_switch_private::create_array_store_fn(producer, range);
    }
}

pub fn get_array_load_name(index_range: &Range<usize>) -> String {
    array_switch_private::get_load_symbol(index_range)
}

pub fn get_array_store_name(index_range: &Range<usize>) -> String {
    array_switch_private::get_store_symbol(index_range)
}

pub fn get_array_switch_range(name: &str) -> Option<Range<usize>> {
    array_switch_private::get_array_switch_range(name)
}
