use super::types::*;
use crate::hir::very_concrete_program::Param;
use crate::intermediate_representation::{InstructionList, SExp, ToSExp};
use crate::intermediate_representation::ir_interface::ObtainMeta;
use crate::translating_traits::*;
use code_producers::c_elements::*;
use code_producers::llvm_elements::{LLVMIRProducer, LLVMValue};
use code_producers::llvm_elements::functions::create_bb;
use code_producers::llvm_elements::instructions::{create_br, create_unreachable, get_insert_block};
use code_producers::wasm_elements::*;

pub type FunctionCode = Box<FunctionCodeInfo>;
#[derive(Default, Clone, Eq, PartialEq, Debug)]
pub struct FunctionCodeInfo {
    pub source_file_id: Option<usize>,
    pub line: usize,
    pub header: String,
    pub name: String,
    pub params: Vec<Param>,
    pub returns: Vec<Dimension>,
    pub body: InstructionList,
    pub max_number_of_vars: usize,
    pub max_number_of_ops_in_expression: usize,
}

impl ObtainMeta for FunctionCodeInfo {
    fn get_source_file_id(&self) -> &Option<usize> {
        &self.source_file_id
    }
    fn get_line(&self) -> usize {
        self.line
    }
    fn get_message_id(&self) -> usize {
        0
    }
}

impl ToString for FunctionCodeInfo {
    fn to_string(&self) -> String {
        let mut body = "".to_string();
        for i in &self.body {
            body = format!("{}{}\n", body, i.to_string());
        }
        format!("FUNCTION({})(\n{})", self.header, body)
    }
}

impl ToSExp for FunctionCodeInfo {
    fn to_sexp(&self) -> SExp {
        SExp::list([
            SExp::atom("FUNCTION"),
            SExp::key_val("line", SExp::atom(self.line)),
            SExp::key_val("header", SExp::atom(&self.header)),
            SExp::key_val("name", SExp::atom(&self.name)),
            SExp::key_val("params", SExp::atom(format!("{:?}", self.params))),
            SExp::key_val("returns", SExp::atom(format!("{:?}", self.returns))),
            SExp::key_val("body", self.body.to_sexp()),
        ])
    }
}

impl WriteLLVMIR for FunctionCodeInfo {
    fn produce_llvm_ir<'ctx>(
        &self,
        producer: &dyn LLVMIRProducer<'ctx>,
    ) -> Option<LLVMValue<'ctx>> {
        if cfg!(debug_assertions) {
            println!("Generating code for {}", self.header);
        }
        Self::manage_debug_loc_from_curr(producer, self);
        let function = producer.current_function();
        let main = create_bb(producer, function, self.header.as_str());
        producer.llvm().set_current_bb(main);

        for t in &self.body {
            let bb = create_bb(producer, function, t.label_name(function.count_basic_blocks()).as_str());
            create_br(producer, bb);
            producer.llvm().set_current_bb(bb);
            t.produce_llvm_ir(producer);
        }

        // If the final block is empty, add unreachable statement.
        // Use get_insert_block() because the final block may not have
        //  been created by one of the calls to create_bb() above but
        //  could be craeted within the last call to produce_llvm_ir().
        if let None = get_insert_block(producer).get_last_instruction() {
            create_unreachable(producer);
        }

        None // We don't return a Value from a function definition
    }
}

impl WriteWasm for FunctionCodeInfo {
    fn produce_wasm(&self, producer: &WASMProducer) -> Vec<String> {
        use code_producers::wasm_elements::wasm_code_generator::*;
        //to be revised
        let mut instructions = vec![];
        let funcdef = format!("(func ${} (type $_t_i32i32ri32)", self.header);
        instructions.push(funcdef);
        instructions.push(format!("(param {} i32)", producer.get_result_address_tag()));
        instructions.push(format!("(param {} i32)", producer.get_result_size_tag()));
	instructions.push("(result i32)".to_string()); //state 0 = OK; > 0 error
        instructions.push(format!("(local {} i32)", producer.get_cstack_tag()));
        instructions.push(format!("(local {} i32)", producer.get_lvar_tag()));
        instructions.push(format!("(local {} i32)", producer.get_expaux_tag()));
        instructions.push(format!("(local {} i32)", producer.get_temp_tag()));
        instructions.push(format!("(local {} i32)", producer.get_aux_0_tag()));
        instructions.push(format!("(local {} i32)", producer.get_aux_1_tag()));
        instructions.push(format!("(local {} i32)", producer.get_aux_2_tag()));
        instructions.push(format!("(local {} i32)", producer.get_counter_tag()));
        instructions.push(format!("(local {} i32)", producer.get_store_aux_1_tag()));
        instructions.push(format!("(local {} i32)", producer.get_store_aux_2_tag()));
        instructions.push(format!("(local {} i32)", producer.get_copy_counter_tag()));
        instructions.push(format!("(local {} i32)", producer.get_call_lvar_tag()));
        instructions.push(format!(" (local {} i32)", producer.get_merror_tag()));
        let local_info_size_u32 = producer.get_local_info_size_u32();
        //set lvar (start of auxiliar memory for vars)
        instructions.push(set_constant("0"));
        instructions.push(load32(None)); // current stack size
        let var_start = local_info_size_u32 * 4; // starts after local info
        if local_info_size_u32 != 0 {
            instructions.push(set_constant(&var_start.to_string()));
            instructions.push(add32());
        }
        instructions.push(set_local(producer.get_lvar_tag()));
        //set expaux (start of auxiliar memory for expressions)
        instructions.push(get_local(producer.get_lvar_tag()));
        let var_stack_size = self.max_number_of_vars * 4 * (producer.get_size_32_bits_in_memory()); // starts after vars
        instructions.push(set_constant(&var_stack_size.to_string()));
        instructions.push(add32());
        instructions.push(set_local(producer.get_expaux_tag()));
        //reserve stack and sets cstack (starts of local var memory)
        let needed_stack_bytes = var_start
            + var_stack_size
            + self.max_number_of_ops_in_expression * 4 * (producer.get_size_32_bits_in_memory());
        let mut reserve_stack_fr_code = reserve_stack_fr(producer, needed_stack_bytes);
        instructions.append(&mut reserve_stack_fr_code); //gives value to $cstack
        if producer.needs_comments() {
            instructions.push(";; start of the function code".to_string());
	}
        //generate code

        for t in &self.body {
            let mut instructions_body = t.produce_wasm(producer);
            instructions.append(&mut instructions_body);
        }
        instructions.push(set_constant("0"));	
        instructions.push(")".to_string());
        instructions
    }
}

impl WriteC for FunctionCodeInfo {
    fn produce_c(&self, producer: &CProducer, _parallel: Option<bool>) -> (Vec<String>, String) {
        use c_code_generator::*;
        let header = format!("void {}", self.header);
        let params = vec![
            declare_circom_calc_wit(),
            declare_lvar_pointer(),
            declare_component_father(),
            declare_dest_pointer(),
            declare_dest_size(),
        ];
        let mut body = vec![];
        body.push(format!("{};", declare_circuit_constants()));
        body.push(format!("{};", declare_expaux(self.max_number_of_ops_in_expression)));
        body.push(format!("{};", declare_my_template_name_function(&self.name)));
        body.push(format!("u64 {} = {};", my_id(), component_father()));
        for t in &self.body {
            let (mut instructions_body, _) = t.produce_c(producer, Some(false));
            body.append(&mut instructions_body);
        }
        let callable = build_callable(header, params, body);
        (vec![callable], "".to_string())
    }
}

impl FunctionCodeInfo {
    pub fn wrap(self) -> FunctionCode {
        FunctionCode::new(self)
    }
    pub fn is_linked(&self, name: &str, params: &Vec<Param>) -> bool {
        self.name.eq(name) && self.params.eq(params)
    }
}
