use std::collections::{HashMap, HashSet};
use std::fs::File;
use std::io::Write;
use super::function::{FunctionCode, FunctionCodeInfo};
use super::template::{TemplateCode, TemplateCodeInfo};
use super::types::*;
use crate::hir::very_concrete_program::VCP;
use crate::intermediate_representation::{InstructionList, Instruction};
use crate::intermediate_representation::ir_interface::{ObtainMeta, AddressType, LocationRule, OperatorType, ConstraintBucket};
use crate::translating_traits::*;
use code_producers::c_elements::*;
use code_producers::coda_elements::*;
use code_producers::llvm_elements::array_switch::load_array_switch;
use code_producers::wasm_elements::*;
use code_producers::llvm_elements::*;
use code_producers::llvm_elements::fr::load_fr;
use code_producers::llvm_elements::functions::{create_function, FunctionLLVMIRProducer};
use code_producers::llvm_elements::stdlib::load_stdlib;
use code_producers::llvm_elements::types::{bigint_type, void_type};
use program_structure::program_archive::{ProgramArchive, self};

pub struct CompilationFlags {
    pub main_inputs_log: bool,
    pub wat_flag: bool,
}

#[derive(Eq, PartialEq, Debug)]
pub struct Circuit {
    pub wasm_producer: WASMProducer,
    pub c_producer: CProducer,
    pub llvm_data: LLVMCircuitData,
    pub coda_data: CodaCircuitData,
    pub templates: Vec<TemplateCode>,
    pub functions: Vec<FunctionCode>,
}

impl Default for Circuit {
    fn default() -> Self {
        Circuit {
            c_producer: CProducer::default(),
            wasm_producer: WASMProducer::default(),
            llvm_data: LLVMCircuitData::default(),
            coda_data: CodaCircuitData::default(),
            templates: Vec::new(),
            functions: Vec::new(),
        }
    }
}

impl WriteLLVMIR for Circuit {
    fn produce_llvm_ir<'a, 'b>(
        &self,
        producer: &'b dyn LLVMIRProducer<'a>,
    ) -> Option<LLVMInstruction<'a>> {
        // Code for prelude

        // Code for standard library?
        load_fr(producer);
        load_stdlib(producer);

        // Generate all the switch functions
        let mut ranges = HashSet::new();
        let mappings = [
            &self.llvm_data.signal_index_mapping,
            &self.llvm_data.variable_index_mapping,
            &self.llvm_data.component_index_mapping,
        ];

        for mapping in mappings {
            for range_mapping in mapping.values() {
                for range in range_mapping.values() {
                    ranges.insert(range);
                }
            }
        }

        for range in ranges {
            load_array_switch(producer, range);
        }

        // Declare all the functions
        let mut funcs = HashMap::new();
        for f in &self.functions {
            let name = f.header.as_str();
            let arena_ty = bigint_type(producer).ptr_type(Default::default());
            let function = create_function(
                producer,
                f.get_source_file_id(),
                f.get_line(),
                f.name.as_str(),
                name,
                if f.returns.is_empty() || (f.returns.len() == 1 && *f.returns.get(0).unwrap() == 1)
                {
                    bigint_type(producer).fn_type(&[arena_ty.into()], false)
                } else {
                    void_type(producer).fn_type(&[arena_ty.into()], false)
                },
            );
            funcs.insert(name, function);
        }

        // Code for the functions
        for f in &self.functions {
            let function_producer = FunctionLLVMIRProducer::new(producer, funcs[f.header.as_str()]);
            Self::manage_debug_loc_from_curr(&function_producer, f.as_ref());
            f.produce_llvm_ir(&function_producer);
        }

        // Code for the templates
        for t in &self.templates {
            println!("Generating code for {}", t.header);
            // code.append(&mut t.produce_llvm_ir(producer));
            t.produce_llvm_ir(producer);
        }

        // Code for prologue

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
        let function_headers: Vec<_> = self.functions.iter().map(|f| f.header.clone()).collect();
        let mut function_headers = collect_function_headers(function_headers);
        code.append(&mut template_headers);
        code.append(&mut function_headers);
        std::mem::drop(template_headers);
        std::mem::drop(function_headers);

        let (func_list_no_parallel, func_list_parallel) =
            generate_function_list(producer, producer.get_template_instance_list());

        code.push(format!(
            "Circom_TemplateFunction {}[{}] = {{ {} }};",
            function_table(),
            producer.get_number_of_template_instances(),
            func_list_no_parallel,
        ));

        code.push(format!(
            "Circom_TemplateFunction {}[{}] = {{ {} }};",
            function_table_parallel(),
            producer.get_number_of_template_instances(),
            func_list_parallel,
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
        let main_template_create = if producer.main_is_parallel {
            producer.main_header.clone() + "_create_parallel"
        } else {
            producer.main_header.clone() + "_create"
        };
        // We use 0 to indicate that the main component has no father
        let create_args = vec![
            "1".to_string(),
            "0".to_string(),
            CIRCOM_CALC_WIT.to_string(),
            "\"main\"".to_string(),
            "0".to_string(),
        ];
        let create_call = build_call(main_template_create, create_args);
        // let ctx_index = format!("{} = {};", declare_ctx_index(), create_call);
        let ctx_index = format!("{};", create_call);
        // let start_msg = "printf(\"Starting...\\n\");".to_string();
        // let end_msg = "printf(\"End\\n\");".to_string();

        let main_template_run = if producer.main_is_parallel {
            producer.main_header.clone() + "_run_parallel"
        } else {
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
    pub fn produce_c<W: Write>(
        &self,
        c_folder: &str,
        run_name: &str,
        c_circuit: &mut W,
        c_dat: &mut W,
    ) -> Result<(), ()> {
        use std::path::Path;
        let c_folder_path = Path::new(c_folder.clone()).to_path_buf();
        c_code_generator::generate_main_cpp_file(&c_folder_path).map_err(|_err| {})?;
        c_code_generator::generate_circom_hpp_file(&c_folder_path).map_err(|_err| {})?;
        c_code_generator::generate_fr_hpp_file(&c_folder_path, &self.c_producer.prime_str)
            .map_err(|_err| {})?;
        c_code_generator::generate_calcwit_hpp_file(&c_folder_path).map_err(|_err| {})?;
        c_code_generator::generate_fr_cpp_file(&c_folder_path, &self.c_producer.prime_str)
            .map_err(|_err| {})?;
        c_code_generator::generate_calcwit_cpp_file(&c_folder_path).map_err(|_err| {})?;
        c_code_generator::generate_fr_asm_file(&c_folder_path, &self.c_producer.prime_str)
            .map_err(|_err| {})?;
        c_code_generator::generate_make_file(&c_folder_path, run_name, &self.c_producer)
            .map_err(|_err| {})?;
        c_code_generator::generate_dat_file(c_dat, &self.c_producer).map_err(|_err| {})?;
        self.write_c(c_circuit, &self.c_producer)
    }
    pub fn produce_wasm<W: Write>(
        &self,
        js_folder: &str,
        _wasm_name: &str,
        writer: &mut W,
    ) -> Result<(), ()> {
        use std::path::Path;
        let js_folder_path = Path::new(js_folder.clone()).to_path_buf();
        wasm_code_generator::generate_generate_witness_js_file(&js_folder_path)
            .map_err(|_err| {})?;
        wasm_code_generator::generate_witness_calculator_js_file(&js_folder_path)
            .map_err(|_err| {})?;
        self.write_wasm(writer, &self.wasm_producer)
    }
    pub fn produce_llvm_ir(
        &mut self,
        program_archive: &ProgramArchive,
        out_path: &str,
    ) -> Result<(), ()> {
        self.write_llvm_ir(program_archive, out_path, &self.llvm_data)
    }
    pub fn produce_coda(
        &self,
        program_archive: &ProgramArchive,
        summary: &SummaryRoot,
        out_file: &mut File,
    ) -> Result<(), ()> {
        let str = self.print_coda(self, program_archive, summary);
        out_file
            .write_all(str.as_bytes())
            .map_err(|err| eprintln!("Error writing to the Coda file: {}", err))
    }
}

impl CompileCoda for Circuit {
    fn compile_coda(
        &self,
        circuit: &Circuit,
        program_archive: &ProgramArchive,
        summary: &SummaryRoot,
    ) -> code_producers::coda_elements::CodaProgram {
        let mut coda_program = CodaProgram::default();

        for template in &self.templates {
            println!("template.name: {:?}", template.name);
            println!(" - template.number_of_inputs: {:?}", template.number_of_inputs);
            println!(" - template.number_of_intermediates: {:?}", template.number_of_intermediates);
            println!(" - template.number_of_outputs: {:?}", template.number_of_outputs);
            println!(" - template.number_of_components: {:?}", template.number_of_components);
            println!(" - body:");

            // HENRY: can I not just use template.id as the index in summary.components? I'm guessing it couldn't be that easy... right?
            let template_summary = summary.components.iter().find(|t| t.name == template.name).unwrap();

            let name = template.name.clone();

            let mut inputs: Vec<CodaVar> = Vec::new();
            let mut intermediates: Vec<CodaVar> = Vec::new();
            let mut outputs: Vec<CodaVar> = Vec::new();

            for signal in &template_summary.signals {
                if signal.visibility == "input" {
                    inputs.push(CodaVar::make_signal(signal.name.clone()));
                } else if signal.visibility == "output" {
                    outputs.push(CodaVar::make_signal(signal.name.clone()));
                } else if signal.visibility == "intermediate" {
                    intermediates.push(CodaVar::make_signal(signal.name.clone()))
                } else {
                    panic!("Unrecognized signal visibility: {}", signal.visibility)
                }
            }

            let body = compile_coda_stmt(circuit, program_archive, summary, template, &template_summary,&template.body, 0);

            let coda_template = CodaTemplate {
                name,
                inputs,
                intermediates, 
                outputs,
                body
            };

            coda_program.templates.push(coda_template);
        }


        println!("BEGIN CODA PROGRAM\n\n{}\n\nEND CODA PROGRAM", coda_program.print());

        coda_program
    }
}

fn compile_coda_stmt(
    circuit: &Circuit,
    program_archive: &ProgramArchive,
    summary: &SummaryRoot, 
    template: &Box<TemplateCodeInfo>,
    template_summary: &TemplateSummary,
    instructions: &Vec<Box<Instruction>>,
    instruction_i: usize
) -> CodaExpr {

    // end of instructions
    if instruction_i >= instructions.len() {
        
        // tuple of all the outputs
        // let mut outs: Vec<Box<CodaExpr>> = Vec::new();

        let outs: Vec<CodaVar> = template_summary.signals.iter()
            .filter_map(|signal| 
                if signal.visibility == "output" {
                    Some(CodaVar::make_signal(signal.name.clone()))
                } else {
                    None
                })
            .collect();

        CodaExpr::Tuple(outs.iter().map(|x| Box::new(CodaExpr::Var(x.clone()))).collect())

    } else {

        let instruction = instructions[instruction_i].clone();

        match instruction.as_ref() {
            Instruction::Constraint(constraint) => {
                match &constraint {
                    ConstraintBucket::Substitution(next_instruction) => {
                        let mut new_instructions = instructions.clone();
                        new_instructions.insert(instruction_i + 1, next_instruction.clone());
                        compile_coda_stmt(circuit, program_archive, summary, template, &template_summary, &new_instructions, instruction_i + 1)
                    },
                    ConstraintBucket::Equality(next_instruction) => {
                        let mut new_instructions = instructions.clone();
                        new_instructions.insert(instruction_i + 1, next_instruction.clone());
                        compile_coda_stmt(circuit, program_archive, summary, template, &template_summary,&new_instructions, instruction_i + 1)
                    },
                }
            },
            Instruction::Block(block) => {
                let mut next_instructions = instructions.clone();
                next_instructions.splice(instruction_i..instruction_i, block.body.iter().cloned());
                compile_coda_stmt(circuit, program_archive, summary, template, &template_summary, &next_instructions, instruction_i)
            },
            Instruction::Store(store) => {
                let name = match &store.dest {
                    LocationRule::Indexed { location, template_header } => {
                        let signal_i = from_instruction_to_value(location);
                        match &store.dest_address_type {
                            // AddressType::Variable => todo!("Store Variable: {:?}", store),
                            AddressType::Variable => {
                                CodaVar::make_variable(signal_i)
                            }
                            AddressType::Signal => {
                                let signal = template_summary.signals.iter().find(|signal| signal.idx == signal_i).unwrap();
                                CodaVar::make_signal(signal.name.clone())
                            },
                            AddressType::SubcmpSignal { cmp_address, uniform_parallel_value, is_output, input_information } => {
                                let cmp_i = from_instruction_to_value(cmp_address);
                                let cmp = &summary.components[cmp_i];
                                let signal = cmp.signals.iter().find(|signal| signal.idx == signal_i).unwrap();
                                CodaVar::make_subcomponent_signal(cmp.name.clone(), signal.name.clone())
                            },
                        }
                    },
                    LocationRule::Mapped { signal_code, indexes } => panic!(),
                };

                // TODO:HENRY: check if this assignment was of the final input
                // to a subcomponent. if so, then need to define the
                // subcomponent as well

                
                CodaExpr::Let(
                    name, 
                    Box::new(compile_coda_expr(circuit, program_archive, summary, template, &template_summary, store.src.clone())), 
                    Box::new(compile_coda_stmt(circuit, program_archive, summary, template, &template_summary, instructions, instruction_i + 1))
                )
            },
            Instruction::Branch(branch) => {
                let mut then_instructions = instructions.clone();
                then_instructions.splice(instruction_i..instruction_i, branch.if_branch.iter().cloned());

                let mut else_instructions = instructions.clone();
                else_instructions.splice(instruction_i..instruction_i, branch.else_branch.iter().cloned());

                CodaExpr::Branch { 
                    condition: Box::new(compile_coda_expr(circuit, program_archive, summary, template, &template_summary, branch.cond.clone())),
                    then_: Box::new(compile_coda_stmt(circuit, program_archive, summary, template, &template_summary, &then_instructions, instruction_i + 1 )),
                    else_: Box::new(compile_coda_stmt(circuit, program_archive, summary, template, &template_summary, &else_instructions, instruction_i + 1)),
                }
            },
            Instruction::CreateCmp(create_cmp) => {
                /*
                    create_cmp.template_id: usize
                    create_cmp.cmp_unique_id: usize
                    create_cmp.sub_cmp_id: InstructionPointer
                    create_cmp.name_subcomponent: String
                    create_cmp.number_of_cmp: usize
                */

                // let sub_cmp_id = from_instruction_to_value(&create_cmp.sub_cmp_id);
                let sub_template_id = create_cmp.template_id;
                let sub_template_summary = &summary.components[sub_template_id];
                let sub_template_data = &program_archive.templates[&sub_template_summary.name];
                let sub_template_name = &sub_template_summary.name;
                let sub_template_name_alt = sub_template_data.get_name();
                let sub_component_name = &create_cmp.name_subcomponent;

                // HENRY: this should hold if I'm understanding how subcomponent
                // data is stored
                assert!(sub_template_name == sub_template_name_alt);

                if false {
                    println!("create component:");
                    println!(" - template_id: {:?}", sub_template_id);
                    println!(" - template_name: {:?}", sub_template_name);
                    println!(" - component_name: {:?}", sub_component_name);
                    println!(" - name_subcomponent: {:?}", create_cmp.name_subcomponent);
                }

                let inputs: Vec<CodaVar> = template_summary.signals.iter()
                    .filter_map(|signal| if signal.visibility == "input" {
                        Some(CodaVar::make_signal(signal.name.clone()))
                    } else {
                        None
                    })
                    .collect();
                let outputs: Vec<CodaVar> = template_summary.signals.iter()
                    .filter_map(|signal| if signal.visibility == "output" {
                        Some(CodaVar::make_signal(signal.name.clone()))
                    } else {
                        None
                    })
                    .collect();

                CodaExpr::Inst(
                    CodaComponentInfo::new(
                        sub_template_name.clone(),
                        sub_component_name.to_string(), 
                        inputs,
                        outputs
                    ),
                    Box::new(compile_coda_stmt(circuit, program_archive, summary, template, &template_summary, instructions, instruction_i + 1))
                )
            },
    
            Instruction::Load(_) => panic!("This case should not appear as a statement."),
            Instruction::Value(_) => panic!("This case should not appear as a statement."),
            Instruction::Compute(_) => panic!("This case should not appear as a statement."),
            Instruction::Call(_) => panic!("This case should not appear as a statement."),
    
            Instruction::Return(_) => panic!("This case is not handled by Circom->Coda"),
            Instruction::Assert(_) => panic!("This case is not handled by Circom->Coda"),
            Instruction::Log(_) => panic!("This case is not handled by Circom->Coda"),
            Instruction::Loop(_) => panic!("This case is not handled by Circom->Coda"),
            
            Instruction::Nop(_) => todo!() // compile_coda_stmt(circuit, program_archive, summary, template, next_instructions),
        }

    }

}

fn compile_coda_expr(
    circuit: &Circuit,
    program_archive: &ProgramArchive, 
    summary: &SummaryRoot,
    template: &Box<TemplateCodeInfo>, 
    template_summary: &TemplateSummary,
    instruction: Box<Instruction>
) -> CodaExpr {
    match instruction.as_ref() {
        Instruction::Value(value) => {
            let x = circuit.coda_data.field_tracking[value.value].clone();
            CodaExpr::Val(CodaVal::new(x))
        },

        Instruction::Load(load) => {
            match &load.address_type {
                AddressType::Variable => panic!(),
                AddressType::Signal => {
                    match &load.src {
                        LocationRule::Indexed { location, template_header } => {
                            let signal_i = from_instruction_to_value(location);
                            match &load.address_type {
                                AddressType::Variable => todo!(),
                                AddressType::Signal => {
                                    let signal = template_summary.signals.iter().find(|signal| signal.idx == signal_i).unwrap();
                                    CodaExpr::Var(CodaVar::make_signal(signal.name.clone()))
                                },
                                AddressType::SubcmpSignal { cmp_address, uniform_parallel_value, is_output, input_information } => {
                                    let cmp_i = from_instruction_to_value(cmp_address);
                                    let cmp = &summary.components[cmp_i];
                                    let signal = cmp.signals.iter().find(|signal| signal.idx == signal_i).unwrap();
                                    CodaExpr::Var(CodaVar::make_subcomponent_signal(cmp.name.clone(), signal.name.clone()))
                                }
                            }
                        },
                        LocationRule::Mapped { signal_code, indexes } => panic!(),
                    }
                },
                AddressType::SubcmpSignal { cmp_address, uniform_parallel_value, is_output, input_information } => {
                    match &load.src {
                        LocationRule::Indexed { location, template_header } => match location.as_ref() {
                            Instruction::Value(value) => {
                                let cmp_i = from_instruction_to_value(cmp_address);
                                let cmp = &summary.components[cmp_i];
                                let signal_i = from_instruction_to_value(location);
                                let signal = cmp.signals.iter().find(|signal| signal.idx == signal_i).unwrap();
                                CodaExpr::Var(CodaVar::make_subcomponent_signal(cmp.name.clone(), signal.name.clone()))
                            },
                            _ => panic!(),
                        },
                        LocationRule::Mapped { signal_code, indexes } => panic!(),
                    }
                },
            }
        },

        Instruction::Compute(compute) => {
            assert!(compute.stack.len() == 2);
            let coda_op = compile_coda_op(compute.op);
            let coda_expr1 = compile_coda_expr(circuit, program_archive, summary, template, &template_summary, compute.stack[0].clone());
            let coda_expr2 = compile_coda_expr(circuit, program_archive, summary, template, &template_summary, compute.stack[1].clone());
            CodaExpr::Op(coda_op, Box::new(coda_expr1), Box::new(coda_expr2))
        }

        Instruction::Branch(branch) => {
            assert!(branch.if_branch.len() == 1);
            let if_branch = branch.if_branch[0].clone();
            
            assert!(branch.if_branch.len() == 1);
            let else_branch = branch.else_branch[0].clone();

            CodaExpr::Branch { 
                condition: Box::new(compile_coda_expr(circuit, program_archive, summary, template, &template_summary, branch.cond.clone())),
                then_: Box::new(compile_coda_expr(circuit, program_archive, summary, template, &template_summary, if_branch)), 
                else_: Box::new(compile_coda_expr(circuit, program_archive, summary, template, &template_summary, else_branch))
            }
        },

        Instruction::Block(block) => {
            assert!(block.body.len() == 1);
            let body = block.body[0].clone();
            compile_coda_expr(circuit, program_archive, summary, template, &template_summary, body)
        },
        
        // panic!("This case cannot appear as an expression.")
        Instruction::Constraint(_) => panic!("This case cannot appear as an expression."),
        Instruction::CreateCmp(_) => panic!("This case cannot appear as an expression."),
        Instruction::Store(_) => panic!("This case cannot appear as an expression."),
        
        
        // panic!("This case is not handled by Circom->Coda")
        Instruction::Loop(_) => panic!("This case is not handled by Circom->Coda"),
        Instruction::Call(_) => panic!("This case is not handled by Circom->Coda"),
        Instruction::Return(_) => panic!("This case is not handled by Circom->Coda"),
        Instruction::Assert(_) => panic!("This case is not handled by Circom->Coda"),
        Instruction::Log(_) => panic!("This case is not handled by Circom->Coda"),
        Instruction::Nop(_) => panic!("This case is not handled by Circom->Coda"),
    }
}

fn compile_coda_op(op: OperatorType) -> CodaOp {
    match op {
        OperatorType::Mul => CodaOp::Mul,
        OperatorType::Div => CodaOp::Div,
        OperatorType::Add => CodaOp::Add,
        OperatorType::Sub => CodaOp::Sub,
        OperatorType::Pow => CodaOp::Pow,
        OperatorType::Mod => CodaOp::Mod,
        OperatorType::IntDiv => todo!(),
        OperatorType::ShiftL => todo!(),
        OperatorType::ShiftR => todo!(),
        OperatorType::LesserEq => todo!(),
        OperatorType::GreaterEq => todo!(),
        OperatorType::Lesser => todo!(),
        OperatorType::Greater => todo!(),
        OperatorType::Eq(_) => todo!(),
        OperatorType::NotEq => todo!(),
        OperatorType::BoolOr => todo!(),
        OperatorType::BoolAnd => todo!(),
        OperatorType::BitOr => todo!(),
        OperatorType::BitAnd => todo!(),
        OperatorType::BitXor => todo!(),
        OperatorType::PrefixSub => todo!(),
        OperatorType::BoolNot => todo!(),
        OperatorType::Complement => todo!(),
        OperatorType::ToAddress => todo!(),
        OperatorType::MulAddress => todo!(),
        OperatorType::AddAddress => todo!(),
    }
}

fn from_instruction_to_value(instruction: &Box<Instruction>) -> usize {
    match instruction.as_ref() {
        Instruction::Value(value) => value.value,
        _ => panic!("Expected `{:?}` to be of the form `Value(_)`", instruction)
    }
}