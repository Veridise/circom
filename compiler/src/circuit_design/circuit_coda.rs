use std::str::FromStr;
use crate::intermediate_representation::Instruction;
use crate::intermediate_representation::ir_interface::*;
use crate::translating_traits::*;
use code_producers::coda_elements::*;
use code_producers::coda_elements::summary::SummaryRoot;
// use code_producers::coda_elements::summary::TemplateSummary;
use program_structure::program_archive::ProgramArchive;
use super::circuit::Circuit;

const __DEBUG: bool = true;
// const __DEBUG: bool = false;

fn pretty_print_input_information(input_information: &InputInformation) -> String {
    match &input_information {
        InputInformation::NoInput => format!("NoInput"),
        InputInformation::Input { status } => match status {
            StatusInput::Last => format!("Last"),
            StatusInput::NoLast => format!("NoLast"),
            StatusInput::Unknown => format!("Unknown"),
        },
    }
}

fn pretty_print_address_type(address_type: &AddressType) -> String {
    match &address_type {
        AddressType::Variable => format!("Variable"),
        AddressType::Signal => format!("Signal"),
        AddressType::SubcmpSignal {
            cmp_address,
            uniform_parallel_value: _,
            is_output: _,
            input_information,
        } => format!(
            "SubcmpSignal({}, {})",
            pretty_print_instruction(&cmp_address),
            pretty_print_input_information(&input_information)
        ),
    }
}

fn pretty_print_location_rule(location_rule: &LocationRule) -> String {
    match &location_rule {
        LocationRule::Indexed { location, template_header } => {
            format!("Ix(loc={}, header={:?})", pretty_print_instruction(location), template_header)
        }
        LocationRule::Mapped { signal_code: _, indexes: _ } => panic!(),
    }
}

fn pretty_print_instruction(instruction: &Instruction) -> String {
    match instruction {
        Instruction::Value(value) => format!("Value(value={}, parse_as={})", value.value, value.parse_as.to_string()),
        Instruction::Load(load) => format!(
            "Load(type={}, src={})",
            pretty_print_address_type(&load.address_type),
            pretty_print_location_rule(&load.src)
        ),
        Instruction::Store(store) => format!(
            "Store(dest_type={}, dest={}, src={})",
            pretty_print_address_type(&store.dest_address_type),
            pretty_print_location_rule(&store.dest),
            pretty_print_instruction(&store.src)
        ),
        Instruction::Compute(compute) => format!(
            "Compute(op={}, arg0={}, arg1={})",
            compute.op.to_string(),
            pretty_print_instruction(&compute.stack[0]),
            pretty_print_instruction(&compute.stack[1])
        ),
        Instruction::Branch(branch) => format!(
            "Branch(cond={}, then={}, else={})",
            pretty_print_instruction(branch.cond.as_ref()),
            pretty_print_instructions(&branch.if_branch),
            pretty_print_instructions(&branch.else_branch)
        ),
        Instruction::CreateCmp(create_cmp) => format!(
            "CreateCmp(template_id={:?}, cmp_unique_id={:?}, symbol={:?}, sub_cmp_id={:?}, name_subcomponent={:?}, number_of_cmp={:?})",
            create_cmp.template_id,
            create_cmp.cmp_unique_id,
            create_cmp.symbol,
            pretty_print_instruction(create_cmp.sub_cmp_id.as_ref()),
            create_cmp.name_subcomponent,
            create_cmp.number_of_cmp
        ),
        Instruction::Constraint(constraint) => match &constraint {
            ConstraintBucket::Substitution(sub) => {
                format!("Sub({})", pretty_print_instruction(sub.as_ref()))
            }
            ConstraintBucket::Equality(eq) => {
                format!("Eq({})", pretty_print_instruction(eq.as_ref()))
            }
        },
        Instruction::Block(block) => format!("{{\n{}}}", pretty_print_instructions(&block.body).split("\n").map(|s| format!("  {}", s)).collect::<Vec<String>>().join("\n")),

        Instruction::Call(call) => {
            format!("Call({}, [{}])", call.symbol, call.arguments.iter().map(|arg| pretty_print_instruction(arg)).collect::<Vec<String>>().join(", "))
        },
        Instruction::Assert(ass) => format!("Assert({})", pretty_print_instruction(ass.evaluate.as_ref())),

        Instruction::Return(_) => panic!(),
        Instruction::Log(_) => panic!(),
        Instruction::Loop(_) => panic!(),
        Instruction::Nop(_) => panic!(),
    }
}

fn pretty_print_instructions(instructions: &Vec<Box<Instruction>>) -> String {
    let mut str = String::new();
    for instruction in instructions {
        str.push_str(&format!("{}\n", pretty_print_instruction(instruction.as_ref())));
    }
    str
}

impl CompileCoda for Circuit {
    fn compile_coda(
        &self,
        circuit: &Circuit,
        program_archive: &ProgramArchive,
        summary: &SummaryRoot,
    ) -> code_producers::coda_elements::CodaProgram {
        let mut coda_program = CodaProgram::default();

        // accumulate coda_template_interfaces
        let coda_template_interfaces: &mut Vec<CodaTemplateInterface> = &mut Vec::new();
        for (template_id, template_code_info) in self.templates.iter().enumerate() {
            let template_summary = summary.components[template_id].clone();
            let template_name = template_summary.name.clone();
            let _template_data = program_archive.get_template_data(&template_name);
            // let template_code_info = circuit.get_template(template_id);

            // println!("template_summary.signals: {:?}", template_summary.signals);

            let signals = template_summary
                .signals
                .iter()
                .map(|signal| CodaTemplateSignal {
                    string: signal.name.clone(),
                    visibility: CodaTemplateSignalVisibility::from_str(&signal.visibility).unwrap(),
                })
                .collect();

            let variables = {
                // TODO: figure out how to get the actual variable names, rather than just using indices
                let mut variables = Vec::new();
                for i in 0..template_code_info.var_stack_depth {
                    variables.push(format!("var{}", i));
                }
                variables
            };

            let abstract_circuit_names = [
                "Poseidon",
                "PoseidonEx",
                "MultiMux1",
                "Ark",
                "Mix",
                "MixS",
                "MixLast",
                "CalculateSecret",
                "CalculateIdentityCommitment",
                "MerkleTreeInclusionProof",
                "CalculateNullifierHash",
                "AbstractCircuit",
            ];

            let is_abstract = abstract_circuit_names.contains(&template_name.as_str());

            coda_template_interfaces.push(CodaTemplateInterface {
                id: template_id,
                name: CodaTemplateName { string: template_name.clone() },
                signals,
                variable_names: variables,
                is_uninterpreted: is_abstract,
            });
        }

        // accumulate coda_program.templates
        let mut done_template_names: Vec<String> = Vec::new();
        for (template_id, template_code_info) in self.templates.iter().enumerate() {
            if done_template_names
                .iter()
                .find(|template_name| *template_name.as_str() == *template_code_info.name.as_str())
                .is_some()
            {
                continue;
            }
            done_template_names.push(template_code_info.name.clone());

            let template_summary = &summary.components[template_id];
            let template_name = &template_summary.name;
            let _template_data = program_archive.get_template_data(template_name);
            // let _template_code_info = circuit.get_template(template_id);
            let interface =
                coda_template_interfaces.iter().find(|cti| cti.id == template_id).unwrap();

            if __DEBUG {
                // debug print this template

                let mut template_string = String::new();
                template_string.push_str(&format!("name: {}\n", template_code_info.name));
                template_string.push_str(&format!(
                    "number_of_inputs: {}\n",
                    template_code_info.number_of_inputs
                ));
                template_string.push_str(&format!(
                    "number_of_intermediates: {}\n",
                    template_code_info.number_of_intermediates
                ));
                template_string.push_str(&format!(
                    "number_of_outputs: {}\n",
                    template_code_info.number_of_outputs
                ));
                template_string.push_str(&format!(
                    "number_of_components: {}\n",
                    template_code_info.number_of_components
                ));
                for signal in &template_summary.signals {
                    template_string
                        .push_str(&format!("signal {} {}\n", signal.visibility, signal.name));
                }
                template_string.push_str(&pretty_print_instructions(&template_code_info.body));
                println!(
                    "\n==================== BEGIN template ====================\n{}================ END template ====================",
                    template_string
                );
            }

            // Some circuits are compiled to abstract Coda bodies

            // println!("template_name: {}", template_name);
            // panic!();

            // TODO: dont compile body of abstract template, but also need to put something into `coda_program.templates` to keep indexing accurate right?

            // if interface.is_uninterpreted {
            //     let body = compile_coda_stmt_abstract(&CompileCodaContext::new(
            //         circuit,
            //         program_archive,
            //         template_summary,
            //         coda_template_interfaces.clone(),
            //         &interface,
            //         Vec::new(),
            //         template_code_info.body.clone(),
            //     ));
            //     coda_program.templates.push(CodaTemplate { interface: interface.clone(), body })
            // } else {
            //     let body = compile_coda_stmt(&CompileCodaContext::new(
            //         circuit,
            //         program_archive,
            //         template_summary,
            //         coda_template_interfaces.clone(),
            //         &interface,
            //         Vec::new(),
            //         template_code_info.body.clone(),
            //     ));
            //     coda_program.templates.push(CodaTemplate { interface: interface.clone(), body })
            // }
        }

        println!(
            "BEGIN Debug Circom Circuit\n\n{}\n\nEND Debug Circom Circuit",
            coda_program.coda_compile().ocaml_compile()
        );

        coda_program
    }
}

struct CodaCompileContext {
    pub variables: Vec<CodaVariable>,
    pub signals: Vec<CodaTemplateSignal>,
    pub subcomponents: Vec<CodaSubcomponent>,
    pub values: Vec<CodaValue>,
}

impl CodaCompileContext {
    pub fn get_coda_variable(&self, i: usize) -> &CodaVariable {
        &self.variables[i]
    }

    pub fn get_coda_signal(&self, i: usize) -> &CodaTemplateSignal {
        &self.signals[i]
    }

    fn get_coda_subcomponent(&self, i: usize) -> &CodaSubcomponent {
        &self.subcomponents[i]
    }

    fn get_coda_value(&self, i: usize) -> &CodaValue {
        &self.values[i]
    }

    fn get_coda_output_signals(&self) -> Vec<CodaTemplateSignal> {
        let mut outputs = Vec::new();
        for signal in self.signals {
            if signal.visibility.is_output() {
                outputs.push(signal)
            }
        }
        outputs
    }
}

#[derive(Clone)]
struct InstructionZipper {
    pub instructions: Vec<Box<Instruction>>,
    pub index: usize,
}

impl InstructionZipper {
    fn new(instructions: Vec<Instruction>) -> Self {
        let mut new_instructions = Vec::new();
        for instruction in instructions {
            new_instructions.push(Box::new(instruction));
        }

        Self { instructions: new_instructions, index: 0 }
    }

    pub fn current_instruction(&self) -> Box<Instruction> {
        self.instructions[self.index]
    }

    pub fn next(&self) -> Option<Self> {
        let next_index = self.index + 1;
        if next_index < self.instructions.len() {
            Some(Self { instructions: self.instructions.clone(), index: next_index })
        } else {
            None
        }
    }

    pub fn insert_instructions(&self, instructions: Vec<Box<Instruction>>) -> Self {
        let mut z = self.clone();
        for (i, instruction) in instructions.iter().enumerate() {
            z.instructions.insert(self.index + i + 1, instruction.clone())
        }
        z
    }
}

fn coda_compile_next_stmt(
    ctx: &CodaCompileContext,
    instruction_zipper: InstructionZipper,
) -> CodaStmt {
    match instruction_zipper.next() {
        Some(new_instruction_zipper) => coda_compile_stmt(ctx, new_instruction_zipper),
        None => {
            // There are no next instructions, so end with the resulting output as a
            // tuple of the processing template's output signals.
            let output_signals: Vec<CodaTemplateSignal> = ctx.get_coda_output_signals();
            let output_exprs: Vec<Box<CodaExpr>> =
                output_signals.iter().map(|signal| Box::new(signal.to_coda_expr())).collect();
            CodaStmt::Output(CodaExpr::Tuple(output_exprs))
        }
    }
}

fn coda_compile_named(
    ctx: &CodaCompileContext,
    location_rule: &LocationRule,
    address_type: &AddressType,
) -> CodaNamed {
    let loc_i = match location_rule {
        LocationRule::Indexed { location, template_header } => {
            from_constant_instruction(location.as_ref())
        }
        LocationRule::Mapped { signal_code, indexes } => panic!(),
    };
    match address_type {
        AddressType::Variable => CodaNamed::Variable(ctx.get_coda_variable(loc_i).clone()),
        AddressType::Signal => {
            let sig = ctx.get_coda_signal(loc_i).clone();
            CodaNamed::Signal(sig)
        }
        AddressType::SubcmpSignal {
            cmp_address,
            uniform_parallel_value,
            is_output,
            input_information,
        } => {
            let subcmp_i = from_constant_instruction(cmp_address);
            let subcmp: &CodaSubcomponent = ctx.get_coda_subcomponent(subcmp_i);
            let subcmp_sig = subcmp.interface.signals[loc_i].to_coda_subcomponent_signal(subcmp);
            assert!(subcmp_sig.signal.visibility.is_input(), "A Store instruction should only try to store into an _input_ signal of a subcomponent.");
            CodaNamed::SubcomponentSignal(subcmp_sig)
        }
    }
}

fn coda_compile_stmt(ctx: &CodaCompileContext, instruction_zipper: InstructionZipper) -> CodaStmt {
    match instruction_zipper.current_instruction().as_ref() {
        Instruction::Assert(ass) => match ass.evaluate.as_ref() {
            Instruction::Compute(comp) => match comp.op {
                OperatorType::Eq(_) => {
                    let e0 = coda_compile_expr(ctx, comp.stack[0].as_ref());
                    let e1 = coda_compile_expr(ctx, comp.stack[1].as_ref());
                    let s = coda_compile_next_stmt(ctx, instruction_zipper);
                    CodaStmt::AssertEqual(0, e0, e1, Box::new(s))
                }
                _ => panic!(),
            },
            _ => panic!(),
        },

        Instruction::Constraint(cstr) => {
            let next_instruction = match cstr {
                ConstraintBucket::Substitution(next_instruction) => next_instruction,
                ConstraintBucket::Equality(next_instruction) => next_instruction,
            };
            coda_compile_stmt(
                ctx,
                instruction_zipper
                    .insert_instructions(vec![next_instruction.clone()])
                    .next()
                    .unwrap(),
            )
        }

        Instruction::Block(block) => {
            coda_compile_stmt(ctx, instruction_zipper.insert_instructions(block.body))
        }

        Instruction::Store(store) => {
            let named = coda_compile_named(ctx, &store.dest, &store.dest_address_type);
            let val = coda_compile_expr(ctx, store.src.as_ref());
            let body = coda_compile_next_stmt(ctx, instruction_zipper);
            CodaStmt::Define(named, val, Box::new(body))
        }

        // Adds subcomponent to context, but doesn't actually "use" it right here,
        // since need to instantiate inputs first.
        Instruction::CreateCmp(create_cmp) => panic!(),

        // ----------------------------------------------------
        Instruction::Branch(_) => panic!(),
        Instruction::Value(_) => panic!(),
        Instruction::Load(_) => panic!(),
        Instruction::Compute(_) => panic!(),
        Instruction::Call(_) => panic!(),
        Instruction::Return(_) => panic!(),
        Instruction::Log(_) => panic!(),
        Instruction::Loop(_) => panic!(),
        Instruction::Nop(_) => panic!(),
    }
}

fn coda_compile_expr(ctx: &CodaCompileContext, instruction: &Instruction) -> CodaExpr {
    match &instruction {
        Instruction::Load(load) => {
            CodaExpr::Named(coda_compile_named(ctx, &load.src, &load.address_type))
        }

        Instruction::Value(value) => match value.parse_as {
            // index into field_tracking
            ValueType::BigInt => CodaExpr::Value(ctx.get_coda_value(value.value).clone()),
            // literal value
            ValueType::U32 => CodaExpr::Value(CodaValue::new(&value.value.to_string())),
        },
        Instruction::Compute(compute) => {
            let es =
                compute.stack.iter().map(|instr| Box::new(coda_compile_expr(ctx, instr))).collect();
            match &compute.op {
                OperatorType::Mul => CodaExpr::Op(CodaOp::Mul, es),
                OperatorType::Div => CodaExpr::Op(CodaOp::Div, es),
                OperatorType::Add => CodaExpr::Op(CodaOp::Add, es),
                OperatorType::Sub => CodaExpr::Op(CodaOp::Sub, es),
                OperatorType::Pow => CodaExpr::Op(CodaOp::Pow, es),
                OperatorType::Mod => CodaExpr::Op(CodaOp::Mod, es),
                OperatorType::IntDiv => panic!(),
                OperatorType::ShiftL => panic!(),
                OperatorType::ShiftR => panic!(),
                OperatorType::LesserEq => panic!(),
                OperatorType::GreaterEq => panic!(),
                OperatorType::Lesser => panic!(),
                OperatorType::Greater => panic!(),
                OperatorType::Eq(_) => panic!(),
                OperatorType::NotEq => panic!(),
                OperatorType::BoolOr => panic!(),
                OperatorType::BoolAnd => panic!(),
                OperatorType::BitOr => panic!(),
                OperatorType::BitAnd => panic!(),
                OperatorType::BitXor => panic!(),
                OperatorType::PrefixSub => panic!(),
                OperatorType::BoolNot => panic!(),
                OperatorType::Complement => panic!(),
                OperatorType::ToAddress => panic!(),
                OperatorType::MulAddress => panic!(),
                OperatorType::AddAddress => panic!(),
            }
        }
        Instruction::Call(call) => {
            let mut es = Vec::new();
            for arg in call.arguments {
                es.push(Box::new(coda_compile_expr(ctx, arg.as_ref())))
            }
            CodaExpr::Call(call.symbol, es)
        }

        // ----------------------------------------------------
        Instruction::Store(_) => panic!(),
        Instruction::Branch(_) => panic!(),
        Instruction::Return(_) => panic!(),
        Instruction::Assert(_) => panic!(),
        Instruction::Log(_) => panic!(),
        Instruction::Loop(_) => panic!(),
        Instruction::CreateCmp(_) => panic!(),
        Instruction::Constraint(_) => panic!(),
        Instruction::Block(_) => panic!(),
        Instruction::Nop(_) => panic!(),
    }
}

fn from_constant_instruction(instruction: &Instruction) -> usize {
    match instruction {
        Instruction::Value(value) => value.value,
        _ => panic!(
            "Expected this instruction to correspond to a constant expression: {:?}",
            instruction
        ),
    }
}
