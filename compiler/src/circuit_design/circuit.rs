use std::collections::HashMap;
use std::io::Write;
use super::function::{FunctionCode, FunctionCodeInfo};
use super::template::{TemplateCode, TemplateCodeInfo};
use super::types::*;
use crate::hir::very_concrete_program::VCP;
use crate::intermediate_representation::ir_interface::ObtainMeta;
use crate::translating_traits::*;
use code_producers::c_elements::*;
use code_producers::llvm_elements::array_switch::{load_array_stores_fns, load_array_load_fns};
use code_producers::llvm_elements::*;
use code_producers::llvm_elements::fr::load_fr;
use code_producers::llvm_elements::functions::{add_attribute, create_bb, create_function, ExtractedFunctionLLVMIRProducer, FunctionLLVMIRProducer};
use code_producers::llvm_elements::instructions::{create_alloca, create_call, create_gep, create_load, create_return_void};
use code_producers::llvm_elements::stdlib::{load_stdlib, GENERATED_FN_PREFIX};
use code_producers::llvm_elements::types::{bigint_type, i32_type, void_type};
use code_producers::llvm_elements::values::zero;
use code_producers::wasm_elements::*;
use program_structure::program_archive::ProgramArchive;

pub struct CompilationFlags {
    pub main_inputs_log: bool,
    pub wat_flag:bool,
}

#[derive(Eq, PartialEq, Debug)]
pub struct Circuit {
    pub wasm_producer: WASMProducer,
    pub c_producer: CProducer,
    pub llvm_data: LLVMCircuitData,
    pub templates: Vec<TemplateCode>,
    pub functions: Vec<FunctionCode>,
}

impl Default for Circuit {
    fn default() -> Self {
        Circuit {
            c_producer: CProducer::default(),
            wasm_producer: WASMProducer::default(),
            llvm_data: LLVMCircuitData::default(),
            templates: Vec::new(),
            functions: Vec::new(),
        }
    }
}

impl WriteLLVMIR for Circuit {
    fn produce_llvm_ir<'a>(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
    ) -> Option<LLVMInstruction<'a>> {
        // Code for prelude

        // Code for standard library?
        load_fr(producer);
        load_stdlib(producer);

        // Code for bounded array switch functions
        load_array_load_fns(producer, &self.llvm_data.bounded_array_loads);
        load_array_stores_fns(producer, &self.llvm_data.bounded_array_stores);

        // Declare all the functions
        let mut funcs = HashMap::new();
        for f in &self.functions {
            let name = f.header.as_str();
            let param_types = if name.starts_with(GENERATED_FN_PREFIX) {
                // Use the FunctionCodeInfo instance to generate the vector of parameter types.
                let mut types = vec![];
                for p in &f.params {
                    // This section is a little more complicated than desired because IntType and ArrayType do
                    //  not have a common Trait that defines the `array_type` and `ptr_type` member functions.
                    let ty = match &p.length[..] {
                        // [] -> i256*
                        [] => bigint_type(producer).ptr_type(Default::default()),
                        // [A] -> [A x i256]*
                        [a] => {
                            bigint_type(producer).array_type(*a as u32).ptr_type(Default::default())
                        }
                        // [A,B,C,...] -> [C x [B x [A x i256]*]*]*
                        [a, rest @ ..] => {
                            let mut temp = bigint_type(producer).array_type(*a as u32);
                            for size in rest {
                                temp = temp.array_type(*size as u32);
                            }
                            temp.ptr_type(Default::default())
                        }
                    };
                    types.push(ty.into());
                }
                types
            } else {
                vec![bigint_type(producer).ptr_type(Default::default()).into()]
            };
            let function = create_function(
                producer,
                f.get_source_file_id(),
                f.get_line(),
                f.name.as_str(),
                name,
                if f.returns.len() == 1 {
                    let single_size = *f.returns.first().unwrap();
                    if single_size == 0 {
                        //single dimension of size 0 indicates [0 x i256]* should be used
                        bigint_type(producer)
                            .array_type(0)
                            .ptr_type(Default::default())
                            .fn_type(&param_types, false)
                    } else if single_size == 1 {
                        // single dimension of size 1 is a scalar
                        bigint_type(producer).fn_type(&param_types, false)
                    } else {
                        // single dimension size>1 must return via pointer argument
                        void_type(producer).fn_type(&param_types, false)
                    }
                } else {
                    // multiple dimensions must return via pointer argument
                    //  and zero dimensions indicates void return
                    void_type(producer).fn_type(&param_types, false)
                },
            );
            function.set_section(Some(&f.name));

            if name.starts_with(GENERATED_FN_PREFIX) {
                // Preserve names (only for generated b/c source functions use only 1 argument)
                for (i, p) in f.params.iter().enumerate() {
                    function.get_nth_param(i as u32).unwrap().set_name(&p.name);
                }
                // Add source location attribute so functions generated from different source
                //  locations will not be merged.
                add_attribute(
                    producer,
                    function,
                    "src-loc",
                    &format!("{:?}:{:?}", f.get_source_file_id(), f.get_line()),
                );
            }

            funcs.insert(name, function);
        }

        // Code for the functions (except for generated functions)
        let mut generated_functions = vec![];
        for f in &self.functions {
            if f.header.starts_with(GENERATED_FN_PREFIX) {
                // Hold for later because the body could reference templates
                //  and the LLVM functions for templates were not pre-defined.
                generated_functions.push(f);
            } else {
                let current_function = funcs[f.header.as_str()];
                f.produce_llvm_ir(&FunctionLLVMIRProducer::new(producer, current_function));
            }
        }

        // Code for the templates
        for t in &self.templates {
            t.produce_llvm_ir(producer);
        }

        // Code for generated functions
        for f in generated_functions {
            assert!(f.header.starts_with(GENERATED_FN_PREFIX));
            let current_function = funcs[f.header.as_str()];
            f.produce_llvm_ir(&ExtractedFunctionLLVMIRProducer::new(producer, current_function));
        }

        // Code for prologue

        // Main function
        {
            let main_fn = create_function(producer,
                                          &None,
                                          0,
                                          "",
                                          "main",
                                          void_type(producer).fn_type(&[], false));
            main_fn.set_linkage(Linkage::External);
            let main = create_bb(producer, main_fn, "main");
            producer.set_current_bb(main);

            let bigint_ptr = bigint_type(producer).array_type(0);
            // Set the type of the component memory: signals array + signals counter
            let component_memory = producer.context().struct_type(&[
                to_basic_type_enum(bigint_ptr.ptr_type(Default::default())),
                to_basic_type_enum(i32_type(producer))
            ], false);
            let alloca = create_alloca(producer, component_memory.as_any_type_enum(), "");
            create_call(producer,
                                build_fn_name(producer.get_main_template_header().clone()).as_str(),
                                &[alloca.into()]);
            let signals_ptr = create_gep(producer, alloca, &[zero(producer), zero(producer)]);
            let signals = create_load(producer, signals_ptr).into_pointer_value();
            create_call(producer,
            run_fn_name(producer.get_main_template_header().clone()).as_str(),
                                &[signals.into()]);
            create_return_void(producer);
        }
        None // No need to return at this level
    }
}

impl WriteWasm for Circuit {
    fn produce_wasm(&self, producer: &WASMProducer) -> Vec<String> {
        use code_producers::wasm_elements::wasm_code_generator::*;
        let mut code = vec![];
        code.push("(module".to_string());
        let mut code_aux = generate_imports_list();
        code.append(&mut code_aux);
        code_aux = generate_memory_def_list(&producer);
        code.append(&mut code_aux);

        code_aux = fr_types(&producer.prime_str);
        code.append(&mut code_aux);

        code_aux = generate_types_list();
        code.append(&mut code_aux);
        code_aux = generate_exports_list();
        code.append(&mut code_aux);

        code_aux = fr_code(&producer.prime_str);
        code.append(&mut code_aux);

        code_aux = desp_io_subcomponent_generator(&producer);
        code.append(&mut code_aux);

        code_aux = get_version_generator(&producer);
        code.append(&mut code_aux);

        code_aux = get_shared_rw_memory_start_generator(&producer);
        code.append(&mut code_aux);

        code_aux = read_shared_rw_memory_generator(&producer);
        code.append(&mut code_aux);

        code_aux = write_shared_rw_memory_generator(&producer);
        code.append(&mut code_aux);

        code_aux = reserve_stack_fr_function_generator();
        code.append(&mut code_aux);

        code_aux = init_generator(&producer);
        code.append(&mut code_aux);

        code_aux = set_input_signal_generator(&producer);
        code.append(&mut code_aux);

        code_aux = get_input_signal_size_generator(&producer);
        code.append(&mut code_aux);

        code_aux = get_raw_prime_generator(&producer);
        code.append(&mut code_aux);

        code_aux = get_field_num_len32_generator(&producer);
        code.append(&mut code_aux);

        code_aux = get_input_size_generator(&producer);
        code.append(&mut code_aux);

        code_aux = get_witness_size_generator(&producer);
        code.append(&mut code_aux);

        code_aux = get_witness_generator(&producer);
        code.append(&mut code_aux);

        code_aux = copy_32_in_shared_rw_memory_generator(&producer);
        code.append(&mut code_aux);

        code_aux = copy_fr_in_shared_rw_memory_generator(&producer);
        code.append(&mut code_aux);

        code_aux = get_message_char_generator(&producer);
        code.append(&mut code_aux);

        code_aux = build_buffer_message_generator(&producer);
        code.append(&mut code_aux);

        code_aux = build_log_message_generator(&producer);
        code.append(&mut code_aux);

        // Actual code from the program

        for f in &self.functions {
            code.append(&mut f.produce_wasm(producer));
        }

        for t in &self.templates {
            code.append(&mut t.produce_wasm(producer));
        }

        code_aux = generate_table_of_template_runs(&producer);
        code.append(&mut code_aux);

        code_aux = fr_data(&producer.prime_str);
        code.append(&mut code_aux);

        code_aux = generate_data_list(&producer);
        code.append(&mut code_aux);

        code.push(")".to_string());
        code
    }
    fn write_wasm<T: Write>(&self, writer: &mut T, producer: &WASMProducer) -> Result<(), ()> {
        use code_producers::wasm_elements::wasm_code_generator::*;

        writer.write_all("(module".as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        let mut code_aux = generate_imports_list();
        let mut code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = generate_memory_def_list(&producer);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = fr_types(&producer.prime_str);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = generate_types_list();
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = generate_exports_list();
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = fr_code(&producer.prime_str);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = desp_io_subcomponent_generator(&producer);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = get_version_generator(&producer);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = get_shared_rw_memory_start_generator(&producer);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = read_shared_rw_memory_generator(&producer);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = write_shared_rw_memory_generator(&producer);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = reserve_stack_fr_function_generator();
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = init_generator(&producer);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = set_input_signal_generator(&producer);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = get_input_signal_size_generator(&producer);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = get_raw_prime_generator(&producer);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = get_field_num_len32_generator(&producer);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = get_input_size_generator(&producer);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = get_witness_size_generator(&producer);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = get_witness_generator(&producer);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = copy_32_in_shared_rw_memory_generator(&producer);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = copy_fr_in_shared_rw_memory_generator(&producer);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = get_message_char_generator(&producer);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = build_buffer_message_generator(&producer);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = build_log_message_generator(&producer);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        // Actual code from the program

        for f in &self.functions {
            f.write_wasm(writer, producer)?;
            writer.flush().map_err(|_| {})?;
        }

        for t in &self.templates {
            t.write_wasm(writer, producer)?;
            writer.flush().map_err(|_| {})?;
        }

        code_aux = generate_table_of_template_runs(&producer);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = fr_data(&producer.prime_str);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        code_aux = generate_data_list(&producer);
        code = merge_code(code_aux);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})?;

        writer.write_all(")".as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})
    }
}

impl WriteC for Circuit {
    fn produce_c(&self, producer: &CProducer, _parallel: Option<bool>) -> (Vec<String>, String) {
        use c_code_generator::*;
        let mut code = vec![];
        // Prologue
        code.push("#include <stdio.h>".to_string());
        code.push("#include <iostream>".to_string());
        code.push("#include <assert.h>".to_string());
        code.push("#include \"circom.hpp\"".to_string());
        code.push("#include \"calcwit.hpp\"".to_string());

        let mut template_headers = collect_template_headers(producer.get_template_instance_list());
        let function_headers: Vec<_> = self.functions
            .iter()
            .map(|f| f.header.clone())
            .collect();
        let mut function_headers = collect_function_headers(function_headers);
        code.append(&mut template_headers);
        code.append(&mut function_headers);
        std::mem::drop(template_headers);
        std::mem::drop(function_headers);

        let (func_list_no_parallel, func_list_parallel) = generate_function_list(
            producer,
            producer.get_template_instance_list()
        );

        code.push(format!("Circom_TemplateFunction {}[{}] = {{ {} }};",
            function_table(), producer.get_number_of_template_instances(), func_list_no_parallel,
        ));

        code.push(format!("Circom_TemplateFunction {}[{}] = {{ {} }};",
        function_table_parallel(), producer.get_number_of_template_instances(), func_list_parallel,
    ));

        code.push(format!(
            "uint get_main_input_signal_start() {{return {};}}\n",
            producer.get_number_of_main_outputs()
        ));

        code.push(format!(
            "uint get_main_input_signal_no() {{return {};}}\n",
            producer.get_number_of_main_inputs()
        ));
        code.push(format!(
            "uint get_total_signal_no() {{return {};}}\n",
            producer.get_total_number_of_signals()
        ));
        code.push(format!(
            "uint get_number_of_components() {{return {};}}\n",
            producer.get_number_of_components()
        ));
        code.push(format!("uint get_size_of_input_hashmap() {{return {};}}\n", SIZE_INPUT_HASHMAP));
        code.push(format!(
            "uint get_size_of_witness() {{return {};}}\n",
            producer.get_witness_to_signal_list().len()
        ));
        code.push(format!(
            "uint get_size_of_constants() {{return {};}}\n",
            producer.get_field_constant_list().len()
        ));
        code.push(format!(
            "uint get_size_of_io_map() {{return {};}}\n",
            producer.get_io_map().len()
        ));
        //code.append(&mut generate_message_list_def(producer, producer.get_message_list()));

        // Functions to release the memory
        let mut release_component_code = generate_function_release_memory_component();
        code.append(&mut release_component_code);

        // Actual code of the circuit
        code.push("// function declarations".to_string());
        for f in &self.functions {
            let (mut f_code, _) = f.produce_c(producer, None);
            code.append(&mut f_code);
        }
        code.push("// template declarations".to_string());
        for t in &self.templates {
            let (mut t_code, _) = t.produce_c(producer, None);
            code.append(&mut t_code);
        }


        // Epilogue
        let run_circuit = "void run".to_string();
        let run_circuit_args = vec![declare_circom_calc_wit()];
        let main_template_create = if producer.main_is_parallel{
            producer.main_header.clone() + "_create_parallel"
        } else{
            producer.main_header.clone() + "_create"
        };
        // We use 0 to indicate that the main component has no father
        let create_args = vec!["1".to_string(), "0".to_string(), CIRCOM_CALC_WIT.to_string(), "\"main\"".to_string(), "0".to_string()];
        let create_call = build_call(main_template_create, create_args);
        // let ctx_index = format!("{} = {};", declare_ctx_index(), create_call);
        let ctx_index = format!("{};", create_call);
        // let start_msg = "printf(\"Starting...\\n\");".to_string();
        // let end_msg = "printf(\"End\\n\");".to_string();

        let main_template_run = if producer.main_is_parallel{
            producer.main_header.clone() + "_run_parallel"
        } else{
            producer.main_header.clone() + "_run"
        };
        let mut run_args = vec![];
        // run_args.push(CTX_INDEX.to_string());
	run_args.push("0".to_string());
        run_args.push(CIRCOM_CALC_WIT.to_string());
        let run_call = format!("{};", build_call(main_template_run, run_args.clone()));

        let main_run_body = vec![ctx_index, run_call];
        code.push(build_callable(run_circuit, run_circuit_args, main_run_body));
        (code, "".to_string())
    }

}

impl Circuit {
    pub fn build(vcp: VCP, flags: CompilationFlags, version: &str) -> Self {
        use super::build::build_circuit;
        build_circuit(vcp, flags, version)
    }
    pub fn add_template_code(&mut self, template_info: TemplateCodeInfo) -> ID {
        let id = self.templates.len();
        let code = template_info.wrap();
        self.templates.push(code);
        id
    }
    pub fn add_function_code(&mut self, function_info: FunctionCodeInfo) -> ID {
        let id = self.functions.len();
        let code = function_info.wrap();
        self.functions.push(code);
        id
    }
    pub fn get_function(&self, id: ID) -> &FunctionCodeInfo {
        self.functions[id].as_ref()
    }
    pub fn get_template(&self, id: ID) -> &TemplateCodeInfo {
        self.templates[id].as_ref()
    }
    pub fn produce_ir_string_for_template(&self, id: ID) -> String {
        self.templates[id].to_string()
    }
    pub fn produce_ir_string_for_function(&self, id: ID) -> String {
        self.functions[id].to_string()
    }
    pub fn produce_c<W: Write>(&self, c_folder: &str, run_name: &str, c_circuit: &mut W, c_dat: &mut W) -> Result<(), ()> {
	use std::path::Path;
	let c_folder_path = Path::new(c_folder).to_path_buf();
        c_code_generator::generate_main_cpp_file(&c_folder_path).map_err(|_err| {})?;
        c_code_generator::generate_circom_hpp_file(&c_folder_path).map_err(|_err| {})?;
        c_code_generator::generate_fr_hpp_file(&c_folder_path, &self.c_producer.prime_str).map_err(|_err| {})?;
        c_code_generator::generate_calcwit_hpp_file(&c_folder_path).map_err(|_err| {})?;
        c_code_generator::generate_fr_cpp_file(&c_folder_path, &self.c_producer.prime_str).map_err(|_err| {})?;
        c_code_generator::generate_calcwit_cpp_file(&c_folder_path).map_err(|_err| {})?;
        c_code_generator::generate_fr_asm_file(&c_folder_path, &self.c_producer.prime_str).map_err(|_err| {})?;
        c_code_generator::generate_make_file(&c_folder_path,run_name,&self.c_producer).map_err(|_err| {})?;
        c_code_generator::generate_dat_file(c_dat, &self.c_producer).map_err(|_err| {})?;
        self.write_c(c_circuit, &self.c_producer)
    }
    pub fn produce_wasm<W: Write>(&self, js_folder: &str, _wasm_name: &str, writer: &mut W) -> Result<(), ()> {
	use std::path::Path;
	let js_folder_path = Path::new(js_folder).to_path_buf();
        wasm_code_generator::generate_generate_witness_js_file(&js_folder_path).map_err(|_err| {})?;
        wasm_code_generator::generate_witness_calculator_js_file(&js_folder_path).map_err(|_err| {})?;
        self.write_wasm(writer, &self.wasm_producer)
    }
    pub fn produce_llvm_ir(&self, program_archive: &ProgramArchive, out_path: &str) -> Result<(), ()> {
        self.write_llvm_ir(program_archive, out_path, &self.llvm_data)
    }
}
