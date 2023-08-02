use std::fmt::Debug;
use std::str::FromStr;
use crate::intermediate_representation::Instruction;
use crate::intermediate_representation::ir_interface::*;
use crate::translating_traits::*;
use code_producers::coda_elements::*;
use program_structure::program_archive::ProgramArchive;
use super::circuit::Circuit;

const __DEBUG: bool = true;

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

        Instruction::Call(call) => {
            format!("Call({}, [{}])", call.symbol, call.arguments.iter().map(|arg| pretty_print_instruction(arg)).collect::<Vec<String>>().join(", "))
        },

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
        let coda_template_interfaces: &mut Vec<CodaTemplateInterface> = &mut Vec::new();
        for (template_id, _template) in self.templates.iter().enumerate() {
            let template_summary = summary.components[template_id].clone();
            let template_name = template_summary.name.clone();
            let _template_data = program_archive.get_template_data(&template_name);
            let template_code_info = circuit.get_template(template_id);

            println!("template_summary.signals: {:?}", template_summary.signals);

            let signals = template_summary
                .signals
                .iter()
                .map(|signal| CodaTemplateSignal {
                    name: signal.name.clone(),
                    visibility: CodaVisibility::from_str(&signal.visibility).unwrap(),
                })
                .collect();

            let variables = {
                // TODO: figure out how to get the actual variable names, rather than just using indices
                let mut variables = Vec::new();
                for i in 0..template_code_info.var_stack_depth {
                    variables.push(format!("var_{}", i));
                }
                variables
            };

            coda_template_interfaces.push(CodaTemplateInterface {
                template_id,
                template_name,
                signals,
                variables,
            });
        }

        // accumulate coda_program.templates
        for (template_id, template) in self.templates.iter().enumerate() {
            let template_summary = &summary.components[template_id];
            let template_name = &template_summary.name;
            let _template_data = program_archive.get_template_data(template_name);
            let _template_code_info = circuit.get_template(template_id);
            let interface = coda_template_interfaces[template_id].clone();

            if __DEBUG {
                // debug print this template

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

            let body = compile_coda_stmt(&CompileCodaContext::new(
                circuit,
                program_archive,
                template_summary,
                coda_template_interfaces.clone(),
                &interface,
                Vec::new(),
                template.body.clone(),
            ));

            coda_program.templates.push(CodaTemplate { interface: interface.clone(), body })
        }

        println!(
            "BEGIN Debug Circom Circuit\n\n{}\n\nEND Debug Circom Circuit",
            coda_program.coda_print()
        );

        coda_program
    }
}

#[derive(Clone, Debug)]
struct CompileCodaContextSubcomponent {
    index: usize,
    coda_template_subcomponent: CodaTemplateSubcomponent,
}

#[derive(Clone)]
struct CompileCodaContext<'a> {
    circuit: &'a Circuit,
    program_archive: &'a ProgramArchive,
    template_summary: &'a TemplateSummary,
    template_interface: &'a CodaTemplateInterface,
    template_interfaces: Vec<CodaTemplateInterface>,
    subcomponents: Vec<CompileCodaContextSubcomponent>,
    instructions: Vec<Box<Instruction>>,
    instruction_i: usize,
}

impl<'a> CompileCodaContext<'a> {
    fn new(
        circuit: &'a Circuit,
        program_archive: &'a ProgramArchive,
        template_summary: &'a TemplateSummary,
        template_interfaces: Vec<CodaTemplateInterface>,
        template_interface: &'a CodaTemplateInterface,
        subcomponents: Vec<CompileCodaContextSubcomponent>,
        instructions: Vec<Box<Instruction>>,
    ) -> Self {
        Self {
            circuit,
            program_archive,
            template_summary,
            template_interfaces,
            template_interface,
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
                &self.instructions[..self.instruction_i + 1],
                &instructions[..],
                &self.instructions[self.instruction_i + 1..],
            ]
            .concat(),
            ..self.clone()
        }
    }

    // why does the field_tracking not have all the constants that are referred to later? perhaps there is a bug in generating hte field_trackign vector, cuz im definitely using it right;
    // TODO: send a message to Daniel
    pub fn get_constant(&self, i: usize) -> String {
        if i < self.circuit.coda_data.field_tracking.len() {
            self.circuit.coda_data.field_tracking[i].clone()
        } else {
            // format!("(bad constant index: {})", i)
            format!(
                "(* ERROR: bad constant index: {} in {:?} *) 0",
                i, self.circuit.coda_data.field_tracking
            )
        }
    }

    pub fn get_signal(&self, i: usize) -> &CodaTemplateSignal {
        &self.template_interface.signals[i]
    }

    pub fn get_variable_name(&self, i: usize) -> &String {
        &self.template_interface.variables[i]
    }

    pub fn get_subcomponent(&self, subcomponent_i: usize) -> &CompileCodaContextSubcomponent {
        println!("get_subcomponent: subcomponent_i = {}", subcomponent_i);
        println!("get_subcomponent: self.subcomponents:");
        for subcmp in &self.subcomponents {
            println!(" - {:?}", subcmp);
        }
        self.subcomponents.iter().find(|subcmp| subcmp.index == subcomponent_i).unwrap()
    }

    pub fn get_subcomponent_signal(
        &self,
        subcomponent_i: usize,
        signal_i: usize,
    ) -> CodaTemplateSignal {
        self.subcomponents
            .iter()
            .find(|subcmp| subcmp.index == subcomponent_i)
            .unwrap()
            .coda_template_subcomponent
            .interface
            .signals[signal_i]
            .clone()
    }

    pub fn set_instructions(&self, instructions: &Vec<Box<Instruction>>) -> Self {
        Self { instructions: instructions.clone(), instruction_i: 0, ..self.clone() }
    }

    pub fn set_instruction(&self, instruction: &Box<Instruction>) -> Self {
        self.set_instructions(&vec![instruction.clone()])
    }

    pub fn insert_subcomponent(
        &self,
        subcomponent_i: usize,
        coda_template_subcomponent: CodaTemplateSubcomponent,
    ) -> Self {
        Self {
            subcomponents: [
                self.subcomponents.clone(),
                vec![CompileCodaContextSubcomponent {
                    index: subcomponent_i,
                    coda_template_subcomponent,
                }],
            ]
            .concat(),
            ..self.clone()
        }
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

fn compile_coda_var(
    ctx: &CompileCodaContext,
    location_rule: &LocationRule,
    address_type: &AddressType,
) -> CodaVar {
    let (i, _template_header) = match &location_rule {
        LocationRule::Indexed { location, template_header } => {
            // All locations referenced in constraints must be constant
            // after the IR transformation passes.
            (from_constant_instruction(location), template_header)
        }
        LocationRule::Mapped { signal_code: _, indexes: _ } => panic!(),
    };

    match &address_type {
        AddressType::Variable => CodaVar::Variable(ctx.get_variable_name(i).clone()),
        AddressType::Signal => CodaVar::Signal(ctx.get_signal(i).name.clone()),
        AddressType::SubcmpSignal {
            cmp_address,
            uniform_parallel_value: _,
            is_output: _,
            input_information: _,
        } => {
            let subcmp_i = from_constant_instruction(cmp_address);
            let subcmp = &ctx.get_subcomponent(subcmp_i);
            let subcmp_signal = &subcmp.coda_template_subcomponent.interface.signals[i];
            CodaVar::SubcomponentSignal(
                subcmp.coda_template_subcomponent.component_name.clone(),
                subcmp_signal.name.clone(),
            )
        }
    }
}

fn compile_coda_stmt(ctx: &CompileCodaContext) -> CodaStmt {
    match ctx.current_instruction() {
        None => CodaStmt::Output,
        Some(instruction) => {
            println!("compile_coda_stmt: {}", pretty_print_instruction(instruction));

            match instruction.as_ref() {
                Instruction::Constraint(constraint) => match constraint {
                    ConstraintBucket::Substitution(next_instruction) => compile_coda_stmt(
                        &ctx.insert_instructions(&vec![next_instruction.clone()])
                            .next_instruction(),
                    ),
                    ConstraintBucket::Equality(next_instruction) => compile_coda_stmt(
                        &ctx.insert_instructions(&vec![next_instruction.clone()])
                            .next_instruction(),
                    ),
                },
                Instruction::Block(block) => {
                    compile_coda_stmt(&ctx.insert_instructions(&block.body).next_instruction())
                }
                Instruction::Store(store) => {
                    let var = compile_coda_var(&ctx, &store.dest, &store.dest_address_type);
                    let val = Box::new(compile_coda_expr(&ctx.set_instruction(&store.src)));
                    let body = Box::new(compile_coda_stmt(&ctx.next_instruction()));

                    match &store.dest_address_type {
                        AddressType::Variable => CodaStmt::Let { var, val, body },
                        AddressType::Signal => CodaStmt::Let { var, val, body },
                        AddressType::SubcmpSignal {
                            cmp_address,
                            uniform_parallel_value: _,
                            is_output: _,
                            input_information,
                        } => match &input_information {
                            InputInformation::NoInput => CodaStmt::Let { var, val, body },
                            InputInformation::Input { status } => match &status {
                                StatusInput::Unknown => {
                                    panic!("Should not be Unknown at this point, after IR transformation passes.")
                                }
                                StatusInput::NoLast => CodaStmt::Let { var, val, body },
                                StatusInput::Last => {
                                    let cmp_i = from_constant_instruction(cmp_address.as_ref());
                                    let subcomponent = ctx
                                        .get_subcomponent(cmp_i)
                                        .coda_template_subcomponent
                                        .clone();

                                    CodaStmt::Let {
                                        var,
                                        val,
                                        body: Box::new(CodaStmt::CreateCmp { subcomponent, body }),
                                    }
                                }
                            },
                        },
                    }
                }
                Instruction::Branch(branch) => CodaStmt::Branch {
                    condition: Box::new(compile_coda_expr(
                        &ctx.set_instructions(&vec![branch.cond.clone()]),
                    )),
                    then_: Box::new(compile_coda_stmt(
                        &ctx.insert_instructions(&branch.if_branch).next_instruction(),
                    )),
                    else_: Box::new(compile_coda_stmt(
                        &ctx.insert_instructions(&branch.else_branch).next_instruction(),
                    )),
                },
                Instruction::CreateCmp(create_cmp) => {
                    let cmp_i = from_constant_instruction(create_cmp.sub_cmp_id.as_ref());
                    let template_id = create_cmp.template_id;
                    let template_interface = &ctx.template_interfaces[template_id];
                    compile_coda_stmt(
                        &ctx.insert_subcomponent(
                            cmp_i,
                            CodaTemplateSubcomponent {
                                interface: template_interface.clone(),
                                component_name: CodaComponentName::new(
                                    create_cmp.name_subcomponent.clone(),
                                ),
                            },
                        )
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

// fn compile_coda_stmt(ctx: &CompileCodaContext) -> Vec<Box<CodaStmt>> {
//     let mut stmts: Vec<Box<CodaStmt>> = Vec::new();

//     for instruction in &ctx.instructions {
//         stmts.push(compile_coda_stmt(ctx, &instruction));
//     }

//     stmts
// }

fn compile_coda_op(op: &OperatorType) -> CodaOp {
    match &op {
        OperatorType::Mul => CodaOp::Mul,
        OperatorType::Div => CodaOp::Div,
        OperatorType::Add => CodaOp::Add,
        OperatorType::Sub => CodaOp::Sub,
        OperatorType::Pow => CodaOp::Pow,
        OperatorType::IntDiv => panic!(),
        OperatorType::Mod => CodaOp::Mod,
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

fn compile_coda_expr(ctx: &CompileCodaContext) -> CodaExpr {
    match ctx.current_instruction() {
        None => panic!(),
        Some(instruction) => match instruction.as_ref() {
            Instruction::Load(load) => {
                let var = compile_coda_var(ctx, &load.src, &load.address_type);
                CodaExpr::Var(var)
            }
            Instruction::Value(value) => {
                let value_string = ctx.get_constant(value.value);
                CodaExpr::Val(CodaVal::new(value_string.clone()))
            }
            Instruction::Compute(compute) => CodaExpr::Op {
                op: compile_coda_op(&compute.op),
                arg1: Box::new(compile_coda_expr(&ctx.set_instruction(&compute.stack[0]))),
                arg2: Box::new(compile_coda_expr(&ctx.set_instruction(&compute.stack[1]))),
            },
            Instruction::Call(_call) => todo!(),

            Instruction::Constraint(_) => {
                panic!("This case should not appear as a expression: {:?}", instruction)
            }
            Instruction::Block(_) => {
                panic!("This case should not appear as a expression: {:?}", instruction)
            }
            Instruction::Store(_) => {
                panic!("This case should not appear as a expression: {:?}", instruction)
            }
            Instruction::Branch(_) => {
                panic!("This case should not appear as a expression: {:?}", instruction)
            }
            Instruction::CreateCmp(_) => {
                panic!("This case should not appear as a expression: {:?}", instruction)
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
        },
    }
}

// fn at<A: Debug>(i: usize, xs: &Vec<(usize, A)>) -> &A {
//     println!("at: i={}, xs={:?}", i, xs);
//     xs.iter().find_map(|x| if x.0 == i { Some(&x.1) } else { None }).unwrap()
// }
