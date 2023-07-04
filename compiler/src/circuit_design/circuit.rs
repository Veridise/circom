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

struct CodaStatementContext<'a> {
    circuit: &'a Circuit,
    summary_root: &'a SummaryRoot,
    template_summary: &'a TemplateSummary,
    coda_circuit: &'a mut CodaCircuit,
    coda_data: &'a CodaCircuitData
}

struct CodaExprContext<'a> {
    pub circuit: &'a Circuit,
    pub summary_root: &'a SummaryRoot,
    pub coda_circuit: &'a CodaCircuit,
    coda_data: &'a CodaCircuitData
}

// fn coda_binop(circuit: &Circuit, summary_root: &SummaryRoot, coda_circuit: &CodaCircuit, compute: &ComputeBucket) -> CodaExpr {
fn coda_binop(op: CodaBinop, context: &CodaExprContext, compute: &ComputeBucket) -> CodaExpr {
    let e1 = coda_expr(&context, &compute.stack[0]);
    let e2 = coda_expr(&context, &compute.stack[1]);
    CodaExpr::Binop(CodaBinopType::F, op, Box::new(e1), Box::new(e2))
}

// Compile an instruction as a CodaExpr.
fn coda_expr(context: &CodaExprContext, instruction: &Box<Instruction>) -> CodaExpr {
    use Instruction::*;
    match instruction.as_ref() {
        Value(value) => {
            // HENRY: also look at `values.rs`
            println!("Value: {:?}", value);
            match value.parse_as {
                ValueType::BigInt => CodaExpr::Literal(context.coda_data.get_constant(value.value), LiteralType::BigInt),
                ValueType::U32 => CodaExpr::Literal(context.coda_data.get_constant(value.value), LiteralType::U32),
            }
        }
        Load(load) => {
            match &load.address_type {
                AddressType::Variable => todo!(),
                AddressType::Signal => {
                    match &load.src {
                        LocationRule::Indexed { location, template_header } => {
                            match location.as_ref() {
                                Value(value) => {
                                    let signal = context.coda_circuit.get_signal(value.value);
                                    CodaExpr::Signal(signal.name.clone())
                                }
                                _ => todo!(),
                            }
                            // CodaExpr::Signal(())
                        }
                        LocationRule::Mapped { signal_code, indexes } => todo!(),
                    }
                }
                AddressType::SubcmpSignal {
                    cmp_address,
                    uniform_parallel_value,
                    is_output,
                    input_information,
                } => todo!(),
            }
        }
        Store(store) => {
            todo!()
        }
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
        Return(return_) => {
            todo!()
        }
        Assert(assert) => {
            todo!()
        }
        Log(log) => {
            todo!()
        }
        Loop(loop_) => {
            todo!()
        }
        CreateCmp(createCmp) => {
            todo!()
        }
        Constraint(constraint) => {
            todo!()
        }
        Block(block) => {
            todo!()
        }
        Nop(nop) => {
            todo!()
        }
    }
}

fn coda_type(context: &CodaExprContext, instruction: &Box<Instruction>) -> CodaType {
    panic!("coda_type")
}

impl<'a> CodaStatementContext<'a> {
    pub fn to_coda_expr_context(&'a self) -> CodaExprContext<'a> {
        CodaExprContext {
            circuit: &self.circuit,
            summary_root: &self.summary_root,
            coda_circuit: &self.coda_circuit,
            coda_data: &self.coda_data
        }
    }
}

// Compile an instruction for as a "coda statement", which isn't actually
// encoded, but corresponds to a component of the `Circuit` struct in Coda.
fn coda_statement(
    // circuit: &Circuit,
    // summary_root: &SummaryRoot,
    // template_summary: &TemplateSummary,
    context: CodaStatementContext,
    // coda_circuit: &mut CodaCircuit,
    instruction: &Box<Instruction>,
) -> () {
    use Instruction::*;
    // println!("[CODA] instruction: {:?}", instruction);
    match instruction.as_ref() {
        Value(value) => {
            todo!()
        }
        Load(load) => {
            todo!()
        }
        Store(store) => {
            if store.dest_is_output && store.dest_address_type == AddressType::Signal {
                match &store.dest {
                    LocationRule::Indexed { location, template_header } => {
                        match location.as_ref() {
                            Value(value) => {
                                let signal_i = value.value;
                                let signal = context.coda_circuit.get_signal(signal_i);
                                let term = coda_expr(&context.to_coda_expr_context(), &store.src);
                                context.coda_circuit.define_output(signal_i, term)
                            }
                            _ => todo!(),
                        }
                    }
                    _ => todo!(),
                }
            } else {
                todo!()
            }
        }
        Compute(compute) => {
            todo!()
        }
        Call(call) => {
            todo!()
        }
        Branch(branch) => {
            todo!()
        }
        Return(return_) => {
            todo!()
        }
        Assert(assert) => {
            todo!()
        }
        Log(log) => {
            todo!()
        }
        Loop(loop_) => {
            todo!()
        }
        CreateCmp(createCmp) => {
            todo!()
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
            todo!()
        }
        Nop(nop) => {
            todo!()
        }
    }
}

impl WriteCoda for Circuit {
    fn produce_coda_program(&self, summary_root: SummaryRoot) -> CodaProgram {
        println!("[CODA] BEGIN");
        // HENRY: this is the main place to build the coda program

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

            let template_summary = summary_root.components.get(template_i).unwrap();
            let mut coda_circuit = CodaCircuit::new(template.name.clone());

            for signal in &template_summary.signals {
                println!("[CODA] signal: {:?}", signal);
                if signal.visibility == "input" {
                    coda_circuit.add_input(signal.name.clone(), CodaType::Field)
                } else if signal.visibility == "output" {
                    coda_circuit.add_output(signal.name.clone(), CodaType::Field)
                } else {
                    panic!("Unknown visibility: {}", signal.visibility)
                }
            }

            for instruction in &template.body {
                let context = CodaStatementContext {
                    circuit: self,
                    summary_root: &summary_root,
                    template_summary: &template_summary,
                    coda_circuit: &mut coda_circuit,
                    coda_data: &self.coda_data
                };
                coda_statement(context, instruction)
            }

            println!("[CODA] coda_circuit: {:?}", coda_circuit);
            coda_program.coda_circuits.push(coda_circuit)
        }
        println!("[CODA] END");
        coda_program
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

// -----------------------------------------------------------------------------
// END Coda stuff
// -----------------------------------------------------------------------------
