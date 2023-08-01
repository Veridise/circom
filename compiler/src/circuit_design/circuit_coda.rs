use std::collections::HashMap;
use std::str::FromStr;
use crate::intermediate_representation::Instruction;
use crate::intermediate_representation::ir_interface::*;
use crate::translating_traits::*;
use code_producers::coda_elements::*;
use program_structure::program_archive::ProgramArchive;
use super::circuit::Circuit;

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
        Instruction::Value(value) => format!("Value({})", value.value),
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

        Instruction::Call(_) => todo!(),

        Instruction::Return(_) => panic!(),
        Instruction::Assert(_) => panic!(),
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
        let mut coda_template_interfaces: Vec<CodaTemplateInterface> = Vec::new();
        for (template_id, _template) in self.templates.iter().enumerate() {
            let template_summary = summary.components[template_id].clone();
            let template_name = template_summary.name.clone();
            let _template_data = program_archive.get_template_data(&template_name);
            let _template_code_info = circuit.get_template(template_id);

            let signals = template_summary
                .signals
                .iter()
                .map(|signal| CodaTemplateSignal {
                    name: signal.name.clone(),
                    visibility: CodaVisibility::from_str(&signal.visibility).unwrap(),
                })
                .collect();

            coda_template_interfaces.push(CodaTemplateInterface {
                template_id,
                template_name,
                signals,
            });
        }

        // accumulate coda_program.templates
        for (template_id, template) in self.templates.iter().enumerate() {
            let template_summary = &summary.components[template_id];
            let template_name = &template_summary.name;
            let _template_data = program_archive.get_template_data(template_name);
            let _template_code_info = circuit.get_template(template_id);
            let coda_template_interface = coda_template_interfaces[template_id].clone();

            if false {
                let mut template_string = String::new();
                template_string.push_str(&format!("name: {}\n", template.name));
                template_string
                    .push_str(&format!("number_of_inputs: {}\n", template.number_of_inputs));
                template_string.push_str(&format!(
                    "number_of_intermediates: {}\n",
                    template.number_of_intermediates
                ));
                template_string
                    .push_str(&format!("number_of_outputs: {}\n", template.number_of_outputs));
                template_string.push_str(&format!(
                    "number_of_components: {}\n",
                    template.number_of_components
                ));
                for signal in &template_summary.signals {
                    template_string
                        .push_str(&format!("signal {} {}\n", signal.visibility, signal.name));
                }
                template_string.push_str(&pretty_print_instructions(&template.body));
                println!(
                    "\n==================== BEGIN template ====================\n{}================ END template ====================",
                    template_string
                );
            }

            let body = compile_coda_stmts(CompileCodaContext::new(
                circuit,
                program_archive,
                template_summary,
                &HashMap::default(),
                template.body.clone(),
            ));

            coda_program.templates.push(CodaTemplate { interface: coda_template_interface, body })
        }

        println!(
            "BEGIN Debug Circom Circuit\n\n{}\n\nEND Debug Circom Circuit",
            coda_program.coda_print()
        );

        coda_program
    }
}

#[derive(Clone)]
struct CompileCodaContext<'a> {
    circuit: &'a Circuit,
    program_archive: &'a ProgramArchive,
    template_summary: &'a TemplateSummary,
    subcomponents: &'a HashMap<usize, CodaTemplateSubcomponent>,
    instructions: Vec<Box<Instruction>>,
    instruction_i: usize,
}

impl<'a> CompileCodaContext<'a> {
    fn new(
        circuit: &'a Circuit,
        program_archive: &'a ProgramArchive,
        template_summary: &'a TemplateSummary,
        subcomponents: &'a HashMap<usize, CodaTemplateSubcomponent>,
        instructions: Vec<Box<Instruction>>,
    ) -> Self {
        Self {
            circuit,
            program_archive,
            template_summary,
            subcomponents,
            instructions,
            instruction_i: 0,
        }
    }

    pub fn current_instruction(&self) -> Option<&Box<Instruction>> {
        if self.instruction_i < self.instructions.len() {
            Some(&self.instructions[self.instruction_i])
        } else {
            None
        }
    }

    pub fn next_instruction(&self) -> Self {
        CompileCodaContext { instruction_i: self.instruction_i + 1, ..self.clone() }
    }

    pub fn insert_instructions(&self, instructions: &Vec<Box<Instruction>>) -> Self {
        CompileCodaContext {
            instructions: [
                &self.instructions[..self.instruction_i],
                &instructions[..],
                &self.instructions[self.instruction_i..],
            ]
            .concat(),
            ..self.clone()
        }
    }

    pub fn get_signal(i: usize) -> CodaTemplateSignal {
        todo!()
    }

    pub fn get_subcomponent_name(subcomponent_i: usize) -> CodaTemplateSubcomponent {
        todo!()
    }

    pub fn get_subcomponent_signal(subcomponent_i: usize, signal_i: usize) -> CodaTemplateSignal {
        todo!()
    }

    pub fn set_instructions(&self, instructions: &Vec<Box<Instruction>>) -> Self {
        // TODO: set instructions, reset instruction_i
        todo!()
    }

    pub fn insert_subcomponent(&self, subcomponent: CodaTemplateSubcomponent) -> Self {
        // TODO: insert into hashmap
        todo!()
    }

    pub fn get_subcomponent(&self, cmp_i: usize) -> &CodaTemplateSubcomponent {
        self.subcomponents.get(&cmp_i).unwrap()
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

fn make_coda_var(location_rule: &LocationRule, address_type: &AddressType) -> CodaVar {
    todo!()
}

fn compile_coda_stmts(ctx: CompileCodaContext) -> CodaExpr {
    match ctx.current_instruction() {
        None => todo!(),
        Some(instruction) => {
            println!("compile_coda_stmt: {}", pretty_print_instruction(instruction));

            match instruction.as_ref() {
                Instruction::Constraint(constraint) => match constraint {
                    ConstraintBucket::Substitution(next_instruction) => compile_coda_stmts(
                        ctx.insert_instructions(&vec![next_instruction.clone()]).next_instruction(),
                    ),
                    ConstraintBucket::Equality(next_instruction) => compile_coda_stmts(
                        ctx.insert_instructions(&vec![next_instruction.clone()]).next_instruction(),
                    ),
                },
                Instruction::Block(block) => {
                    compile_coda_stmts(ctx.insert_instructions(&block.body).next_instruction())
                }
                Instruction::Store(store) => {
                    let var = make_coda_var(&store.dest, &store.dest_address_type);
                    let val =
                        Box::new(compile_coda_expr(ctx.set_instructions(&vec![store.src.clone()])));
                    let body = Box::new(compile_coda_stmts(ctx.next_instruction()));
                    CodaExpr::Let { var, val, body }
                }
                Instruction::Branch(branch) => CodaExpr::Branch {
                    condition: Box::new(compile_coda_expr(
                        ctx.set_instructions(&vec![branch.cond.clone()]),
                    )),
                    then_: Box::new(compile_coda_stmts(
                        ctx.insert_instructions(&branch.if_branch).next_instruction(),
                    )),
                    else_: Box::new(compile_coda_stmts(
                        ctx.insert_instructions(&branch.else_branch).next_instruction(),
                    )),
                },
                Instruction::CreateCmp(create_cmp) => {
                    let cmp_i = create_cmp.cmp_unique_id;
                    let cmp = ctx.get_subcomponent(cmp_i);
                    compile_coda_stmts(
                        ctx.insert_subcomponent(CodaTemplateSubcomponent {
                            interface: cmp.interface.clone(),
                            name: cmp.name.clone(),
                        })
                        .next_instruction(),
                    )
                }
                Instruction::Load(_load) => {
                    panic!("This case should not appear as a statement: {:?}", instruction)
                }
                Instruction::Value(_) => {
                    panic!("This case should not appear as a statement: {:?}", instruction)
                }
                Instruction::Compute(_) => {
                    panic!("This case should not appear as a statement: {:?}", instruction)
                }
                Instruction::Call(_) => {
                    panic!("This case should not appear as a statement: {:?}", instruction)
                }

                Instruction::Return(_) => {
                    panic!("This case is not handled by Circom->Coda: {:?}", instruction)
                }
                Instruction::Assert(_) => {
                    panic!("This case is not handled by Circom->Coda: {:?}", instruction)
                }
                Instruction::Log(_) => {
                    panic!("This case is not handled by Circom->Coda: {:?}", instruction)
                }
                Instruction::Loop(_) => {
                    panic!("This case is not handled by Circom->Coda: {:?}", instruction)
                }

                Instruction::Nop(_) => {
                    panic!("This case is not handled by Circom->Coda: {:?}", instruction)
                }
            }
        }
    }
}

fn compile_coda_expr(_ctx: CompileCodaContext) -> CodaExpr {
    todo!()
}
