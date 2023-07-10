use core::panic;
use std::collections::HashMap;
use super::function::{FunctionCode, FunctionCodeInfo};
use super::template::{TemplateCode, TemplateCodeInfo};
use super::types::*;
use crate::hir::very_concrete_program::VCP;
use crate::intermediate_representation::Instruction;
use crate::intermediate_representation::ir_interface::*;
use crate::translating_traits::*;
use code_producers::c_elements::*;
use code_producers::wasm_elements::*;
use code_producers::llvm_elements::*;
use std::io::Write;
use code_producers::llvm_elements::fr::load_fr;
use code_producers::llvm_elements::functions::{create_function, FunctionLLVMIRProducer};
use code_producers::llvm_elements::stdlib::load_stdlib;
use code_producers::llvm_elements::types::{bigint_type};
use code_producers::coda_elements::*;

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

#[derive(Eq, PartialEq, Debug)]
pub struct CodaCircuitData {
    pub field_tracking: Vec<String>,
}

impl CodaCircuitData {
    pub fn get_constant(&self, i: usize) -> String {
        self.field_tracking[i].clone()
    }
}

impl Default for CodaCircuitData {
    fn default() -> Self {
        CodaCircuitData { field_tracking: Vec::new() }
    }
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

        // Declare all the functions
        let mut funcs = HashMap::new();
        for f in &self.functions {
            let name = f.header.as_str();
            let arena_ty = bigint_type(producer).ptr_type(Default::default());
            let function = create_function(
                producer,
                name,
                bigint_type(producer).fn_type(&[arena_ty.into()], false),
            );
            funcs.insert(name, function);
        }

        // Code for the functions
        for f in &self.functions {
            let function_producer = FunctionLLVMIRProducer::new(producer, funcs[f.header.as_str()]);
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

// -----------------------------------------------------------------------------
// BEGIN Coda stuff
// -----------------------------------------------------------------------------

struct CodaContext<'a> {
    pub circuit: &'a Circuit,
    pub summary_root: &'a SummaryRoot,
    pub template_summary: &'a TemplateSummary,
    pub coda_signals: &'a Vec<CodaSignal>,
    pub coda_subcomponent_instances: Vec<CodaSubcomponentInstance>,
    pub coda_data: &'a CodaCircuitData,
}

/*
// Compile an instruction as a CodaExpr.
fn coda_expr(context: &CodaContext, instruction: &Box<Instruction>) -> CodaExpr {
    use Instruction::*;
    match instruction.as_ref() {
        Value(value) => {
            // HENRY: also look at `values.rs`
            println!("Value: {:?}", value);
            match value.parse_as {
                ValueType::BigInt => CodaExpr::Literal(
                    context.coda_data.get_constant(value.value),
                    LiteralType::BigInt,
                ),
                ValueType::U32 => {
                    CodaExpr::Literal(context.coda_data.get_constant(value.value), LiteralType::U32)
                }
            }
        }
        Load(load) => match &load.address_type {
            AddressType::Variable => todo!(),
            AddressType::Signal => match &load.src {
                LocationRule::Indexed { location, template_header } => match location.as_ref() {
                    Value(value) => {
                        let signal = context.coda_circuit.get_signal(value.value);
                        CodaExpr::Signal(signal.name.clone())
                    }
                    _ => todo!(),
                },
                LocationRule::Mapped { signal_code, indexes } => todo!(),
            },
            AddressType::SubcmpSignal {
                cmp_address,
                uniform_parallel_value,
                is_output,
                input_information,
            } => todo!(),
        },
        Compute(compute) => match &compute.op {
            OperatorType::Mul => coda_binop(CodaBinop::Mul, context, compute),
            OperatorType::Div => coda_binop(CodaBinop::Div, context, compute),
            OperatorType::Add => coda_binop(CodaBinop::Add, context, compute),
            OperatorType::Sub => coda_binop(CodaBinop::Sub, context, compute),
            OperatorType::Pow => coda_binop(CodaBinop::Pow, context, compute),
            OperatorType::Mod => coda_binop(CodaBinop::Mod, context, compute),
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
        },
        Call(call) => {
            todo!()
        }
        Branch(branch) => {
            todo!()
        }
        Block(block) => {
            todo!()
        }
        Store(_) => {
            panic!("shouldn't appear in expression")
        }
        Return(_) => {
            panic!("shouldn't appear in expression")
        }
        Assert(_) => {
            panic!("shouldn't appear in expression")
        }
        Log(_) => {
            panic!("shouldn't appear in expression")
        }
        Loop(_) => {
            panic!("all loops should be unrolled")
        }
        CreateCmp(_) => {
            panic!("shouldn't appear in expression")
        }
        Constraint(_) => {
            panic!("shouldn't appear in expression")
        }
        Nop(_) => {
            panic!("shouldn't appear in expression")
        }
    }
}

// Compile an instruction for as a "coda statement", which isn't actually
// encoded, but corresponds to a component of the `Circuit` struct in Coda.
fn coda_statement(
    // circuit: &Circuit,
    // summary_root: &SummaryRoot,
    // template_summary: &TemplateSummary,
    context: &mut CodaContext,
    // coda_circuit: &mut CodaCircuit,
    instruction: &Box<Instruction>,
) -> () {
    use Instruction::*;
    // println!("[CODA] instruction: {:?}", instruction);
    match instruction.as_ref() {
        Store(store) => {
            match &store.dest_address_type {
                AddressType::Variable => todo!("where does this come from? does circom allow local definitions?"),
                AddressType::Signal => {
                    match &store.dest {
                        LocationRule::Indexed { location, template_header } => {
                            match location.as_ref() {
                                Value(value) => {
                                    let signal_i = value.value;
                                    // let signal = context.coda_circuit.get_signal(signal_i);
                                    let term = coda_expr(&context, &store.src);
                                    if store.dest_is_output {
                                        context.coda_circuit.define_output(signal_i, term)
                                    } else {
                                        context.coda_circuit.define_intermediate(signal_i, term)
                                    }
                                }
                                _ => todo!(),
                            }
                        }
                        _ => todo!(),
                    }
                },
                AddressType::SubcmpSignal { cmp_address, uniform_parallel_value, is_output, input_information } => {
                    println!("{:?}", instruction);
                    todo!()
                    // CodaExpr::SubcomponentSignal((), ())
                },
            }
        }
        Branch(branch) => {
            todo!()
        }
        Return(return_) => {
            () // ignore, only appears in witness generator
        }
        Assert(assert) => {
            () // ignore
        }
        Log(log) => {
            () // ignore
        }
        Loop(loop_) => {
            panic!("all loops should be unrolled")
        }
        CreateCmp(createCmp) => {
            let name: String = createCmp.name_subcomponent.to_string();
            context.coda_circuit.add_subcomponent(name.clone(), CodaSubcomponentInstance { name  })
        }
        Constraint(constraint) => {
            match constraint {
                ConstraintBucket::Substitution(nextInstruction) => {
                    coda_statement(context, nextInstruction)
                }
                ConstraintBucket::Equality(nextInstruction) => {
                    // coda_statement(context, nextInstruction)
                    todo!()
                }
            }
        }
        Block(block) => {
            for instruction in &block.body {
                coda_statement(context, instruction)
            }
        }
        Nop(_) => {
            ()
        }
        Value(_) => {
            panic!("shouldn't appear in statement")
        }
        Load(_) => {
            panic!("shouldn't appear in statement")
        }
        Compute(_) => {
            panic!("shouldn't appear in statement")
        }
        Call(_) => {
            panic!("shouldn't appear in statement")
        }
    }
}
*/

fn coda_location_string(_context: &CodaContext, location_rule: &LocationRule) -> String {
    use Instruction::*;
    use LocationRule::*;
    match &location_rule {
        Indexed { location, template_header } => {
            match location.as_ref() {
                Value(value) => format!("Location/Value({}, template_header: {:?})", value.value, template_header),
                _ => panic!("If `location_rule` = `Indexed{{location}}`, then `location` should be a `Value`: {:?}", location_rule)
            }
        },
        Mapped { signal_code, indexes } => {
            let mut indexes_strings: Vec<String> = Vec::new();
            for index in indexes {
                indexes_strings.push(index.to_string())
            }
            format!("Location/Mapped(signal_coda: {}, location.indexes: {})", signal_code, indexes_strings.join("."))
        }
    }
}

fn coda_address_type_string(context: &CodaContext, address_type: &AddressType) -> String {
    match &address_type {
        AddressType::Variable => format!("Variable"),
        AddressType::Signal => format!("Signal"),
        AddressType::SubcmpSignal { cmp_address, .. } => {
            format!("SubcmpSignal({})", coda_expr_string(context, cmp_address))
        }
    }
}

fn coda_expr_string(context: &CodaContext, instruction: &Box<Instruction>) -> String {
    use Instruction::*;
    match instruction.as_ref() {
        Value(value) => {
            format!("Value(parse_as: {}, value: {})", value.parse_as.to_string(), value.value)
        }
        Load(load) => format!("Load({})", coda_location_string(context, &load.src)),
        Compute(compute) => {
            let mut op_string = "<unhandled op>";
            match compute.op {
                OperatorType::Mul => op_string = "*",
                OperatorType::Div => op_string = "/",
                OperatorType::Add => op_string = "+",
                OperatorType::Sub => op_string = "-",
                OperatorType::Pow => op_string = "^",
                OperatorType::Mod => op_string = "%",
                _ => (),
            }
            format!(
                "({} {} {})",
                coda_expr_string(&context, compute.stack.get(0).unwrap()),
                op_string,
                coda_expr_string(&context, compute.stack.get(1).unwrap())
            )
        }
        Call(_call) => todo!(),
        Branch(_branch) => todo!(),
        Block(_block) => todo!(),
        _ => panic!("should not appear in expression: {:?}", instruction),
    }
}

fn coda_statement_print(context: &CodaContext, instruction: &Box<Instruction>) -> () {
    use Instruction::*;
    match instruction.as_ref() {
        Store(store) => {
            println!("Store:");
            println!(
                "  • dest_address_type: {}",
                coda_address_type_string(&context, &store.dest_address_type)
            );
            println!(
                "  • dest: {}",
                coda_location_string(&context, &store.dest)
            );
            println!("  • src: {}", coda_expr_string(&context, &store.src));
        }
        Constraint(_constraint) =>
            // match constraint {
            // println!("BEGIN Constraint");
            // ConstraintBucket::Substitution(next_instruction) => {
            //     coda_statement_print(context, next_instruction);
            // }
            // ConstraintBucket::Equality(next_instruction) => {
            //     coda_statement_print(context, next_instruction);
            // println!("END Constraint");
            // }
            (),
        CreateCmp(create_cmp) => {
            println!("CreateCmp:");
            println!("   • name: {}", create_cmp.name_subcomponent);
        }
        Branch(_) => todo!(),
        Block(block) => {
            println!("Begin Block");
            for next_instruction in &block.body {
                coda_statement_print(context, &next_instruction)
            }
            println!("End Block");
        },
        Nop(_) => (),

        Value(_) => panic!("Should not appear in statement: {:?}", instruction),
        Load(_) => panic!("Should not appear in statement: {:?}", instruction),
        Compute(_) => panic!("Should not appear in statement: {:?}", instruction),
        Call(_) => panic!("Should not appear in statement: {:?}", instruction),

        Loop(_) => panic!("Coda doesn't handle this because all loops should be unrolled"),
        Log(_) => panic!("Coda ignores this"),
        Assert(_) => panic!("Coda ignores this"),
        Return(_) => panic!("Coda ignores this because it should only appear in witness generator"),
    }
}

fn coda_expr(context: &CodaContext, instruction: &Box<Instruction>) -> CodaExpr {
    use Instruction::*;
    match instruction.as_ref() {
        // Value(value) => CodaExpr::Literal(
        //     context.coda_data.get_constant(value.value),
        //     match &value.parse_as {
        //         BigInt => LiteralType::BigInt,
        //         U32 => LiteralType::U32,
        //     },
        // ),
        Value(value) => {
            let str = context.coda_data.get_constant(value.value);
            CodaExpr::Constant(str)
        }
        Load(load) => {
            use AddressType::*;
            match &load.address_type {
                Variable => {
                    let variable_name =
                        CodaVariableName { value: get_location_rule_signal_index(&load.src) };
                    CodaExpr::Variable { variable_name }
                }
                Signal => {
                    let i = get_location_rule_signal_index(&load.src);
                    let signal_name = context.coda_signals[i].name.clone();
                    CodaExpr::Signal { signal_name }
                }
                SubcmpSignal { cmp_address, .. } => {
                    let cmp_i = match cmp_address.as_ref() {
                        Instruction::Value(value) => value.value,
                        _ => todo!(),
                    };

                    let cmp = &context.coda_subcomponent_instances[cmp_i];
                    let i = get_location_rule_signal_index(&load.src);
                    let signal = &cmp.signals[i];
                    CodaExpr::SubcomponentSignal {
                        subcomponent_name: cmp.name.clone(),
                        signal_name: signal.name.clone(),
                    }
                }
            }
        }
        Compute(compute) => {
            use OperatorType::*;
            let e0 = Box::new(coda_expr(context, &compute.stack[0]));
            let e1 = Box::new(coda_expr(context, &compute.stack[1]));
            match compute.op {
                Mul => CodaExpr::Binop(CodaBinop::Mul, e0, e1),
                Div => CodaExpr::Binop(CodaBinop::Div, e0, e1),
                Add => CodaExpr::Binop(CodaBinop::Add, e0, e1),
                Sub => CodaExpr::Binop(CodaBinop::Sub, e0, e1),
                Pow => CodaExpr::Binop(CodaBinop::Pow, e0, e1),
                Mod => CodaExpr::Binop(CodaBinop::Mod, e0, e1),
                op => panic!("Operator not handled by Coda: {:?}", op),
            }
        }
        Call(_call) => todo!(),
        Branch(_branch) => panic!(),
        Block(_block) => panic!(),
        _ => panic!("should not appear in expression: {:?}", instruction),
    }
}

fn get_location_rule_signal_index(location_rule: &LocationRule) -> usize {
    match &location_rule {
        LocationRule::Indexed { location, .. } => match location.as_ref() {
            Instruction::Value(value) => value.value,
            loc => panic!("Expected LocationRule's value to be a Value: {:?}", loc),
        },
        LocationRule::Mapped { .. } => todo!(),
    }
}

/*
fn coda_statement(context: &mut CodaContext, instruction: &Box<Instruction>) -> CodaStatement {
    use Instruction::*;
    coda_statement_print(context, instruction);
    match instruction.as_ref() {
        Constraint(constraint) => match constraint {
            // Just skip over this wrapper
            ConstraintBucket::Substitution(instruction) => coda_statement(context, instruction),
            ConstraintBucket::Equality(instruction) => coda_statement(context, instruction),
        },
        Store(store) => match &store.dest_address_type {
            AddressType::Variable => todo!("store into a local variable"),
            AddressType::Signal => {
                let i = get_location_rule_signal_index(&store.dest);
                let name = context.coda_circuit.signals[i].name.clone();
                let expr = coda_expr(&context, &store.src);
                if store.dest_is_output {
                    // context.coda_circuit.define_output(name, expr)
                    context.coda_circuit.body
                } else {
                    context.coda_circuit.define_intermediate(name, expr)
                }
            }
            AddressType::SubcmpSignal {
                cmp_address,
                uniform_parallel_value,
                is_output,
                input_information,
            } => {
                let cmp_i = match cmp_address.as_ref() {
                    Instruction::Value(value) => value.value,
                    _ => panic!("The `cmp_address` of an `AddressType::SubcmpSignal` should be a Value: {:?}", cmp_address),
                };
                let cmp = &context.coda_circuit.subcomponents[cmp_i];
                let cmp_name = cmp.name.clone();
                let i = get_location_rule_signal_index(&store.dest);
                let signal = &cmp.signals[i];
                let name = signal.name.clone();
                let expr = coda_expr(&context, &store.src);
                context.coda_circuit.define_subcomponent_input(cmp_name, name, expr)
            }
        },
        CreateCmp(create_cmp) => {
            let cmp_i = create_cmp.template_id;
            let template_summary = &context.summary_root.components[cmp_i];
            let name: String = template_summary.name.clone();
            let mut signals: Vec<CodaSignal> = Vec::new();
            for signal in &template_summary.signals {
                signals.push(CodaSignal {
                    name: CodaSignalName { value: signal.name.clone() },
                    visibility: CodaSignalVisibility::parse(&signal.visibility),
                });
            }
            let subcomponent = CodaSubcomponentInstance::new(name, signals);
            println!("subcomponent: {:?}", subcomponent);
            context.coda_circuit.add_subcomponent(subcomponent)
        }
        Branch(_) => todo!("I will need to modify how CodaCircuit is represented, since currently is doesn't allow for branching assignment to signals"),
        Block(_) => todo!("what exaclty is the significance of blocks? do they only exist for the sake of scoping, so I can ignore them for compiling to Coda?"),
        Nop(_) => (),
        // These cases are not handled by Coda
        Loop(_) => panic!("Coda doesn't handle this because all loops should be unrolled"),
        Log(_) => panic!("Coda ignores this"),
        Assert(_) => panic!("Coda ignores this"),
        Return(_) => panic!("Coda ignores this because it should only appear in witness generator"),
        // These cases should not appear in a circuit-level statement.
        Value(_) => panic!("Should not appear in statement: {:?}", instruction),
        Load(_) => panic!("Should not appear in statement: {:?}", instruction),
        Compute(_) => panic!("Should not appear in statement: {:?}", instruction),
        Call(_) => panic!("Should not appear in statement: {:?}", instruction),
    }
}
*/

fn coda_statement(context: &CodaContext, instructions: &[Box<Instruction>]) -> CodaStatement {
    if instructions.len() == 0 {
        CodaStatement::End {
            output_names: context
                .coda_signals
                .iter()
                .filter_map(|signal| match signal.visibility {
                    CodaSignalVisibility::Input => {
                        println!("not output signal: {:?}", signal);
                        None
                    }
                    CodaSignalVisibility::Output => Some(signal.name.clone()),
                    CodaSignalVisibility::Intermediate => None,
                })
                .collect(),
        }
    } else {
        use Instruction::*;
        let instruction = &instructions[0];
        let next_instructions = &instructions[1..];
        coda_statement_print(context, instruction);
        match instruction.as_ref() {
            Constraint(constraint) => match constraint {
                // Just skip over this wrapper
                ConstraintBucket::Substitution(instruction) => coda_statement(context, [std::slice::from_ref(instruction), next_instructions].concat().as_slice()),
                ConstraintBucket::Equality(instruction) => coda_statement(context, [std::slice::from_ref(instruction), next_instructions].concat().as_slice()),
            },
            Store(store) => match &store.dest_address_type {
                AddressType::Variable => {
                    // println!("Store(store) where &store.dest_address_type == AddressType::Variable: {:?}", &store);
                    let variable_name = CodaVariableName { value: get_location_rule_signal_index(&store.dest)};
                    let expr = coda_expr(&context, &store.src);
                    let next = coda_statement(context, next_instructions);
                    CodaStatement::Assignment { target:  CodaAssignmentTarget::Variable { variable_name }, value: expr, next: Box::new(next) }
                },
                AddressType::Signal => {
                    let i = get_location_rule_signal_index(&store.dest);
                    let signal_name = context.coda_signals[i].name.clone();
                    let expr = coda_expr(&context, &store.src);
                    let next = coda_statement(context, next_instructions);
                    CodaStatement::Assignment { target:  CodaAssignmentTarget::Signal { signal_name }, value: expr, next: Box::new(next) }
                }
                AddressType::SubcmpSignal {
                    cmp_address, input_information, ..
                } => {

                    let cmp_i = match cmp_address.as_ref() {
                        Instruction::Value(value) => value.value,
                        _ => panic!("The `cmp_address` of an `AddressType::SubcmpSignal` should be a Value: {:?}", cmp_address),
                    };
                    let instance = &context.coda_subcomponent_instances[cmp_i];
                    let signal_i = get_location_rule_signal_index(&store.dest);
                    let signal = &instance.signals[signal_i];
                    let name = signal.name.clone();
                    let expr = coda_expr(&context, &store.src);
                    let next = coda_statement(context, next_instructions);
                    match input_information {
                        InputInformation::Input { status } if *status == StatusInput::Last => CodaStatement::Assignment { target: CodaAssignmentTarget::SubcomponentSignal { subcomponent_name: instance.name.clone(), signal_name: name }, value: expr, next: Box::new(CodaStatement::Instantiate { instance: instance.clone(), next: Box::new(next) }) },
                        _  => CodaStatement::Assignment { target: CodaAssignmentTarget::SubcomponentSignal { subcomponent_name: instance.name.clone(), signal_name: name }, value: expr, next: Box::new(next) },
                    }
                }
            },
            CreateCmp(create_cmp) => {
                // println!("create_cmp: {:?}", create_cmp);
                // println!("components: {:?}", &context.summary_root.components.iter().map(|cmp| &cmp.name).collect::<Vec<&String>>());

                // HENRY: this is a temporary hack, since I can't figure out why the order of the components in the summary_root is in a random order.
                let template_summary = &context.summary_root.components.iter().find(|cmp| create_cmp.symbol.starts_with::<&String>(&cmp.name)).unwrap();

                let template_name = CodaTemplateName { value : template_summary.name.clone() };
                let instance_name = CodaSubcomponentName{ value: create_cmp.name_subcomponent.clone() };
                let mut signals: Vec<CodaSignal> = Vec::new();
                for signal in &template_summary.signals {
                    signals.push(CodaSignal {
                        name: CodaSignalName { value: signal.name.clone() },
                        visibility: CodaSignalVisibility::parse(&signal.visibility),
                    });
                }

                let instance = CodaSubcomponentInstance {name: instance_name, template_name, signals };

                let next_context = &CodaContext { coda_subcomponent_instances: [context.coda_subcomponent_instances.clone(), vec![instance.clone()]].concat(), ..*context.clone() };

                let next = coda_statement(next_context, next_instructions);

                // CodaStatement::Instantiate { instance, next: Box::new(next) }
                next
            }

            Branch(_) => todo!("I will need to modify how CodaCircuit is represented, since currently is doesn't allow for branching assignment to signals"),
            // Block(_) => todo!("what exaclty is the significance of blocks? do they only exist for the sake of scoping, so I can ignore them for compiling to Coda?"),
            Block(block) => coda_statement(context, vec![block.body.clone(), next_instructions.to_vec()].concat().as_slice()),
            Nop(_) => coda_statement(context, next_instructions),
            // These cases are not handled by Coda
            Loop(_) => panic!("Coda doesn't handle this because all loops should be unrolled"),
            Log(_) => panic!("Coda ignores this"),
            Assert(_) => panic!("Coda ignores this"),
            Return(_) => panic!("Coda ignores this because it should only appear in witness generator"),
            // These cases should not appear in a circuit-level statement.
            Value(_) => panic!("Should not appear in statement: {:?}", instruction),
            Load(_) => panic!("Should not appear in statement: {:?}", instruction),
            Compute(_) => panic!("Should not appear in statement: {:?}", instruction),
            Call(_) => panic!("Should not appear in statement: {:?}", instruction),
        }
    }
}

impl WriteCoda for Circuit {
    fn produce_coda_program(&self, summary_root: SummaryRoot) -> CodaProgram {
        println!("[CODA] BEGIN");
        // println!("self.templates {:?}", self.templates);
        // println!("self.functions {:?}", self.functions);
        println!("[CODA] summary_root");
        println!("[CODA]   - version: {}", summary_root.version);
        println!("[CODA]   - compiler: {}", summary_root.compiler);
        println!("[CODA]   - framework: {:?}", summary_root.framework);

        let mut coda_program = CodaProgram::default();

        for (template_i, template) in self.templates.iter().enumerate() {
            println!("[CODA] template.header: {:?}", template.header);
            println!("[CODA]   - number_of_inputs: {}", template.number_of_inputs);
            println!("[CODA]   - number_of_outputs: {}", template.number_of_outputs);

            println!("[CODA] BEGIN Printing Template");
            println!("========================================================");

            let template_summary = summary_root.components.get(template_i).unwrap();

            let mut coda_signals: Vec<CodaSignal> = Vec::new();

            for signal in &template_summary.signals {
                let visibility = CodaSignalVisibility::parse(&signal.visibility);
                coda_signals.push(CodaSignal {
                    name: CodaSignalName { value: signal.name.clone() },
                    visibility,
                });
                // println!("Signal {} {}", signal.visibility, signal.name);
            }

            let context = CodaContext {
                circuit: self,
                summary_root: &summary_root,
                template_summary: &template_summary,
                coda_subcomponent_instances: Vec::new(),
                coda_signals: &coda_signals,
                coda_data: &self.coda_data,
            };
            // let instructions: LinkedList<&Box<Instruction>> = template.body.iter().collect();
            let coda_body = CodaBody {
                name: CodaBodyName { value: template.name.clone() },
                params: Vec::new(),
                signals: coda_signals.clone(),
                statement: coda_statement(&context, &template.body),
            };

            println!("========================================================");
            println!("[CODA] END Printing Template");

            let coda_circuit = CodaCircuit {
                name: template.name.clone(),
                signals: coda_signals.clone(),
                body: coda_body,
            };

            println!("[CODA] coda_circuit: {:?}", coda_circuit);
            coda_program.coda_circuits.push(coda_circuit)
        }
        println!("[CODA] END");
        coda_program
    }
}

// -----------------------------------------------------------------------------
// END Coda stuff
// -----------------------------------------------------------------------------

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
    pub fn produce_llvm_ir(&mut self, _llvm_folder: &str, llvm_path: &str) -> Result<(), ()> {
        self.write_llvm_ir(llvm_path, &self.llvm_data)
    }
    pub fn produce_coda<W: Write>(
        &mut self,
        summary_root: SummaryRoot,
        writer: &mut W,
    ) -> Result<(), ()> {
        println!("[Circuit.produce_coda]");
        let program = self.produce_coda_program(summary_root);
        self.write_coda_program(writer, program)
    }
}
