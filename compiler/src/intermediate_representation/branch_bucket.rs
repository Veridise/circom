use super::ir_interface::*;
use crate::translating_traits::*;
use crate::intermediate_representation::{BucketId, new_id, SExp, ToSExp, UpdateId};
use code_producers::c_elements::*;
use code_producers::llvm_elements::{LLVMIRProducer, LLVMValue};
use code_producers::llvm_elements::functions::create_bb;
use code_producers::llvm_elements::instructions::{
    create_br_with_checks, create_conditional_branch, create_unreachable,
};
use code_producers::wasm_elements::*;

#[derive(Clone, Debug, Eq, PartialEq, Ord, PartialOrd)]
pub struct BranchBucket {
    pub id: BucketId,
    pub source_file_id: Option<usize>,
    pub line: usize,
    pub message_id: usize,
    pub cond: InstructionPointer,
    pub if_branch: InstructionList,
    pub else_branch: InstructionList,
}

impl IntoInstruction for BranchBucket {
    fn into_instruction(self) -> Instruction {
        Instruction::Branch(self)
    }
}

impl ObtainMeta for BranchBucket {
    fn get_source_file_id(&self) -> &Option<usize> {
        &self.source_file_id
    }
    fn get_line(&self) -> usize {
        self.line
    }
    fn get_message_id(&self) -> usize {
        self.message_id
    }
}

impl ToString for BranchBucket {
    fn to_string(&self) -> String {
        let line = self.line.to_string();
        let template_id = self.message_id.to_string();
        let cond = self.cond.to_string();
        let mut if_body = "".to_string();
        for i in &self.if_branch {
            if_body = format!("{}{};", if_body, i.to_string());
        }
        let mut else_body = "".to_string();
        for i in &self.else_branch {
            else_body = format!("{}{};", else_body, i.to_string());
        }
        format!(
            "IF(line:{},template_id:{},cond:{},if:{},else{})",
            line, template_id, cond, if_body, else_body
        )
    }
}

impl ToSExp for BranchBucket {
    fn to_sexp(&self) -> SExp {
        SExp::list([
            SExp::atom("IF"),
            SExp::key_val("line", SExp::atom(self.line)),
            SExp::key_val("cond", self.cond.to_sexp()),
            SExp::key_val("if_branch", self.if_branch.to_sexp()),
            SExp::key_val("el_branch", self.else_branch.to_sexp()),
        ])
    }
}

impl UpdateId for BranchBucket {
    fn update_id(&mut self) {
        self.id = new_id();
        self.cond.update_id();
        for inst in &mut self.if_branch {
            inst.update_id();
        }
        for inst in &mut self.else_branch {
            inst.update_id();
        }
    }
}

impl WriteLLVMIR for BranchBucket {
    fn produce_llvm_ir<'a>(&self, producer: &dyn LLVMIRProducer<'a>) -> Option<LLVMValue<'a>> {
        Self::manage_debug_loc_from_curr(producer, self);

        // Necessary basic blocks
        let current_function = producer.current_function();
        let then_bb = create_bb(producer, current_function, "if.then");
        let else_bb = create_bb(producer, current_function, "if.else");
        let merge_bb = create_bb(producer, current_function, "if.merge");

        // Generate check of the condition and the conditional jump in the current block
        let cond_code =
            self.cond.produce_llvm_ir(producer).expect("Cond instruction must produce a value!");
        create_conditional_branch(producer, cond_code.into_int_value(), then_bb, else_bb);

        // Define helper to process the body of the given branch of the if-statement.
        // If needed, it will produce an unconditional jump to the "merge" basic block.
        // Returns the unconditional jump if one was produced, otherwise None.
        let process_body = |branch_body: &InstructionList| {
            for inst in branch_body {
                inst.produce_llvm_ir(producer);
            }
            create_br_with_checks(producer, merge_bb)
        };

        // Then branch
        producer.llvm().set_current_bb(then_bb);
        let jump_from_if = process_body(&self.if_branch);
        // Else branch
        producer.llvm().set_current_bb(else_bb);
        let jump_from_else = process_body(&self.else_branch);
        // Merge block (where the function body continues)
        producer.llvm().set_current_bb(merge_bb);

        //If there are no jumps to the merge block, it is unreachable.
        if jump_from_if.is_none() && jump_from_else.is_none() {
            create_unreachable(producer);
        }

        None
    }
}

impl WriteWasm for BranchBucket {
    fn produce_wasm(&self, producer: &WASMProducer) -> Vec<String> {
        use code_producers::wasm_elements::wasm_code_generator::*;
        let mut instructions = vec![];
        if producer.needs_comments() {
            instructions.push(";; branch bucket".to_string());
	}
        if self.if_branch.len() > 0 {
            let mut instructions_cond = self.cond.produce_wasm(producer);
            instructions.append(&mut instructions_cond);
            instructions.push(call("$Fr_isTrue"));
            instructions.push(add_if());
            for ins in &self.if_branch {
                let mut instructions_if = ins.produce_wasm(producer);
                instructions.append(&mut instructions_if);
            }
            if self.else_branch.len() > 0 {
                instructions.push(add_else());
                for ins in &self.else_branch {
                    let mut instructions_else = ins.produce_wasm(producer);
                    instructions.append(&mut instructions_else);
                }
            }
	    instructions.push(add_end());
        } else {
            if self.else_branch.len() > 0 {
                let mut instructions_cond = self.cond.produce_wasm(producer);
                instructions.append(&mut instructions_cond);
                instructions.push(call("$Fr_isTrue"));
                instructions.push(eqz32());
                instructions.push(add_if());
                for ins in &self.else_branch {
                    let mut instructions_else = ins.produce_wasm(producer);
                    instructions.append(&mut instructions_else);
                }
		instructions.push(add_end());
            }
        }
        if producer.needs_comments() {
            instructions.push(";; end of branch bucket".to_string());
	}
        instructions
    }
}

impl WriteC for BranchBucket {
    fn produce_c(&self, producer: &CProducer, parallel: Option<bool>) -> (Vec<String>, String) {
        use c_code_generator::merge_code;
        let (condition_code, condition_result) = self.cond.produce_c(producer, parallel);
        let condition_result = format!("Fr_isTrue({})", condition_result);
        let mut if_body = Vec::new();
        for instr in &self.if_branch {
            let (mut instr_code, _) = instr.produce_c(producer, parallel);
            if_body.append(&mut instr_code);
        }
        let mut else_body = Vec::new();
        for instr in &self.else_branch {
            let (mut instr_code, _) = instr.produce_c(producer, parallel);
            else_body.append(&mut instr_code);
        }
        let mut conditional = format!("if({}){{\n{}}}", condition_result, merge_code(if_body));
        if !else_body.is_empty() {
            conditional.push_str(&format!("else{{\n{}}}", merge_code(else_body)));
        }
        let mut c_branch = condition_code;
        c_branch.push(conditional);
        (c_branch, "".to_string())
    }
}
