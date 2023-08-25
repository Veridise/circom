/*
#[derive(Clone)]
struct CompileCodaContext<'a> {
    circuit: &'a Circuit,
    program_archive: &'a ProgramArchive,
    template_summary: &'a TemplateSummary,
    template_interface: &'a CodaTemplateInterface,
    template_interfaces: Vec<CodaTemplateInterface>,
    subcomponents: Vec<CodaSubcomponent>,
    assertion_counter: usize,
    // a variable name will be added to this vector every time it is updated (via a `Store` instruction)
    variable_updates: Vec<CodaVariable>,

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
        subcomponents: Vec<CodaSubcomponent>,
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
            assertion_counter: 0,
            variable_updates: Vec::new(),
        }
    }

    pub fn incrememnt_counter(&self) -> Self {
        CompileCodaContext { assertion_counter: self.assertion_counter + 1, ..self.clone() }
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

    pub fn get_constant(&self, i: usize) -> String {
        if i < self.circuit.coda_data.field_tracking.len() {
            self.circuit.coda_data.field_tracking[i].clone()
        } else {
            // format!(
            //     // "(* ERROR: bad constant index: {} in {:?} *) 0",
            //     i, self.circuit.coda_data.field_tracking
            // )
            format!("666")
        }
    }

    pub fn get_signal(&self, i: usize) -> &CodaTemplateSignal {
        &self.template_interface.signals[i]
    }

    // pub fn get_variable_fresh_index(&self, x: String) -> u32 {
    //     self.variable_updates
    //         .iter()
    //         .filter(|y| *x.as_str() == *y.name.as_str())
    //         .collect::<Vec<&CodaVariable>>()
    //         .len()
    // }

    // pub fn get_variable_name(&self, i: usize) -> &String {
    //     &self.template_interface.variables[i]
    // }

    // pub fn get_variable_name_as_coda_variable(&self, i: usize) -> CodaVariable {
    //     let name = self.get_variable_name(i);
    //     let fresh_index = self.get_variable_fresh_index(name.clone()).clone();
    //     CodaVariable { name: name.clone(), fresh_index }
    // }

    pub fn get_subcomponent(&self, subcomponent_i: usize) -> &CodaSubcomponent {
        // println!("get_subcomponent: subcomponent_i = {}", subcomponent_i);
        // println!("get_subcomponent: self.subcomponents:");
        // for subcmp in &self.subcomponents {
        //     println!(" - {:?}", subcmp);
        // }
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
        subcomponent: CodaSubcomponent,
    ) -> Self {
        Self {
            subcomponents: [self.subcomponents.clone(), vec![subcomponent]].concat(),
            ..self.clone()
        }
    }

    pub fn log_variable_update(&self, x: CodaVariable) -> Self {
        Self { variable_updates: [vec![x], self.variable_updates.clone()].concat(), ..self.clone() }
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

// fn compile_coda_var(
//     ctx: &CompileCodaContext,
//     location_rule: &LocationRule,
//     address_type: &AddressType,
// ) -> CodaVar {
//     let (i, _template_header) = match &location_rule {
//         LocationRule::Indexed { location, template_header } => {
//             // All locations referenced in constraints must be constant
//             // after the IR transformation passes.
//             (from_constant_instruction(location), template_header)
//         }
//         LocationRule::Mapped { signal_code: _, indexes: _ } => panic!(),
//     };

//     match &address_type {
//         AddressType::Variable => CodaVar::Variable(ctx.get_variable_name_as_coda_variable(i)),
//         AddressType::Signal => CodaVar::Signal(ctx.get_signal(i).clone()),
//         AddressType::SubcmpSignal {
//             cmp_address,
//             uniform_parallel_value: _,
//             is_output: _,
//             input_information: _,
//         } => {
//             let subcmp_i = from_constant_instruction(cmp_address);
//             let subcmp = &ctx.get_subcomponent(subcmp_i);
//             let subcmp_signal = &subcmp.subcomponent.interface.signals[i];
//             CodaVar::SubcomponentSignal(
//                 subcmp.subcomponent.component_name.clone(),
//                 subcmp.subcomponent.component_index,
//                 subcmp_signal.name.clone(),
//             )
//         }
//     }
// }

// fn compile_coda_stmt_abstract(ctx: &CompileCodaContext) -> CodaStmt {
//     // Defines all outputs to be Coda's `star` i.e. `NonDet`
//     let mut stmt = CodaStmt::Output;
//     for signal in ctx.template_interface.signals.iter().rev() {
//         stmt = CodaStmt::Let {
//             var: signal.to_var(),
//             val: Box::new(CodaExpr::Star),
//             body: Box::new(stmt),
//         }
//     }
//     stmt
// }

fn compile_coda_stmt(ctx: &CompileCodaContext) -> CodaStmt {
    match ctx.current_instruction() {
        None => CodaStmt::Output,
        Some(instruction) => {
            if __DEBUG {
                println!("compile_coda_stmt: {}", pretty_print_instruction(instruction))
            };

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
                    let val = Box::new(compile_coda_expr(&ctx.set_instruction(&store.src)));

                    match &store.dest_address_type {
                        AddressType::Variable => {
                            let var: CodaVariable =
                                match compile_coda_var(&ctx, &store.dest, &store.dest_address_type)
                                    .clone()
                                {
                                    // it must be a Variable, since dest_address_type = Variable
                                    CodaVar::Variable(CodaVariable { name, fresh_index }) => {
                                        CodaVariable { name, fresh_index: fresh_index + 1 }
                                    }
                                    _ => panic!(),
                                };

                            let body = Box::new(compile_coda_stmt(
                                &ctx.log_variable_update(var.clone()).next_instruction(),
                            ));
                            CodaStmt::Let { var: CodaVar::Variable(var.clone()), val, body }
                        }
                        AddressType::Signal => {
                            let var = compile_coda_var(&ctx, &store.dest, &store.dest_address_type);
                            let body = Box::new(compile_coda_stmt(&ctx.next_instruction()));
                            CodaStmt::Let { var, val, body }
                        }
                        AddressType::SubcmpSignal {
                            cmp_address,
                            uniform_parallel_value: _,
                            is_output: _,
                            input_information,
                        } => {
                            let var = compile_coda_var(&ctx, &store.dest, &store.dest_address_type);
                            let body = Box::new(compile_coda_stmt(&ctx.next_instruction()));
                            match &input_information {
                                InputInformation::NoInput => CodaStmt::Let { var, val, body },
                                InputInformation::Input { status } => match &status {
                                    StatusInput::Unknown => {
                                        panic!("Should not be Unknown at this point, after IR transformation passes.")
                                    }
                                    StatusInput::NoLast => CodaStmt::Let { var, val, body },
                                    StatusInput::Last => {
                                        let cmp_i = from_constant_instruction(cmp_address.as_ref());
                                        let subcomponent =
                                            ctx.get_subcomponent(cmp_i).subcomponent.clone();

                                        CodaStmt::Let {
                                            var,
                                            val,
                                            body: Box::new(CodaStmt::CreateCmp {
                                                subcomponent,
                                                body,
                                            }),
                                        }
                                    }
                                },
                            }
                        }
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
                    let template_interface = ctx
                        .template_interfaces
                        .iter()
                        .find(|ti| ti.template_id == template_id)
                        .unwrap();

                    let mut new_ctx = ctx.clone();

                    // Repeated `CreateCmp` of the same template are grouped together, with a number of copies indicated by copies indicated by `create_cmp.number_of_cmp`.
                    for cmp_di in 0..create_cmp.number_of_cmp {
                        new_ctx = new_ctx.insert_subcomponent(
                            cmp_i + cmp_di,
                            CodaTemplateSubcomponent {
                                interface: template_interface.clone(),
                                component_index: cmp_di,
                                component_name: CodaComponentName::new(
                                    create_cmp.name_subcomponent.clone(),
                                ),
                            },
                        );
                    }

                    compile_coda_stmt(&new_ctx.next_instruction())
                }

                Instruction::Assert(ass) => {
                    let new_ctx = &ctx.incrememnt_counter();
                    match ass.evaluate.as_ref() {
                        Instruction::Compute(comp) => match comp.op {
                            OperatorType::Eq(_) => {
                                let lhs = Box::new(compile_coda_expr(
                                    &new_ctx.set_instruction(&comp.stack[0]),
                                ));
                                let rhs = Box::new(compile_coda_expr(
                                    &new_ctx.set_instruction(&comp.stack[1]),
                                ));
                                CodaStmt::AssertEq {
                                    i: new_ctx.assertion_counter,
                                    lhs,
                                    rhs,
                                    body: Box::new(compile_coda_stmt(&new_ctx.next_instruction())),
                                }
                            }
                            // _ => CodaStmt::Assert {
                            //     i: new_ctx.fresh_counter,
                            //     condition: Box::new(compile_coda_expr(
                            //         &new_ctx.set_instruction(&ass.evaluate),
                            //     )),
                            //     body: Box::new(compile_coda_stmt(&new_ctx.next_instruction())),
                            // },
                            _ => panic!(),
                        },
                        _ => panic!(),
                    }
                }

                /*
                Call(CallBucket { id: 136697760737723432672427078134442152209, source_file_id: Some(3), line: 79, message_id: 69, symbol: "POSEIDON_C_0", argument_types: [InstrContext { size: 1 }], arguments: [Value(ValueBucket { id: 326783913472980550211208520729987932540, source_file_id: Some(3), line: 79, message_id: 69, parse_as: BigInt, op_aux_no: 1, value: 82 })], arena_size: 205, return_info: Final(FinalData { context: InstrContext { size: 81 }, dest_is_output: false, dest_address_type: Variable, dest: Indexed { location: Value(ValueBucket { id: 237904140605526989290660355093185167777, source_file_id: Some(3), line: 79, message_id: 69, parse_as: U32, op_aux_no: 0, value: 21 }), template_header: None } }) })'
                */
                Instruction::Call(_) => {
                    panic!("This case should not appear as a statement: {:?}", instruction)
                }

                // Invalid statements
                Instruction::Load(_load) => {
                    panic!("This case should not appear as a statement: {:?}", instruction)
                }
                Instruction::Value(_) => {
                    panic!("This case should not appear as a statement: {:?}", instruction)
                }
                Instruction::Compute(_) => {
                    panic!("This case should not appear as a statement: {:?}", instruction)
                }

                // Ignored by Coda
                Instruction::Log(_) => compile_coda_stmt(&ctx.next_instruction()),

                // Not handled by Coda
                Instruction::Return(_) => {
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

fn compile_coda_op(op: &OperatorType, num_type: Option<CodaNumType>) -> CodaOp {
    match &op {
        OperatorType::Mul => CodaOp::Mul(num_type.unwrap()),
        OperatorType::Div => CodaOp::Div,
        OperatorType::Add => CodaOp::Add(num_type.unwrap()),
        OperatorType::Sub => CodaOp::Sub(num_type.unwrap()),
        OperatorType::Pow => CodaOp::Pow(num_type.unwrap()),
        OperatorType::IntDiv => panic!(),
        OperatorType::Mod => CodaOp::Mod,
        OperatorType::ShiftL => panic!(),
        OperatorType::ShiftR => panic!(),
        OperatorType::LesserEq => panic!(),
        OperatorType::GreaterEq => panic!(),
        OperatorType::Lesser => panic!(),
        OperatorType::Greater => panic!(),
        OperatorType::Eq(_eq) => CodaOp::Eq,
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
                match value.parse_as {
                    // index into field_tracking
                    ValueType::BigInt => {
                        let value_string = ctx.get_constant(value.value);
                        CodaExpr::Val(CodaVal::new(
                            ["(* index *)".to_string(), value_string.clone()].join(" "),
                        ))
                    }
                    // literal value
                    ValueType::U32 => CodaExpr::Val(CodaVal::new(
                        ["(* literal *)".to_string(), value.value.to_string()].join(" "),
                    )),
                }
            }
            // TODO: calculate correct CodaNumType
            Instruction::Compute(compute) => CodaExpr::Op {
                op: compile_coda_op(&compute.op, Some(CodaNumType::Field)),
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

*/

use std::str::FromStr;
use crate::intermediate_representation::Instruction;
use crate::intermediate_representation::ir_interface::*;
use crate::translating_traits::*;
use code_producers::coda_elements::*;
use code_producers::coda_elements::summary::SummaryRoot;
// use code_producers::coda_elements::summary::TemplateSummary;
use program_structure::program_archive::ProgramArchive;
use super::circuit::Circuit;

const UNINTERPRETED_CIRCUIT_NAMES: [&str; 8] = [
    "Poseidon",
    "PoseidonEx",
    "MultiMux1",
    "Ark",
    "Mix",
    "MixS",
    "MixLast",
    // "CalculateSecret",
    // "CalculateIdentityCommitment",
    // "MerkleTreeInclusionProof",
    // "CalculateNullifierHash",
    "AbstractCircuit",
];

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
        _circuit: &Circuit,
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

            let signals = template_summary
                .signals
                .iter()
                .map(|signal| CodaSignal {
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

            let is_uninterpreted = UNINTERPRETED_CIRCUIT_NAMES.contains(&template_name.as_str());

            coda_template_interfaces.push(CodaTemplateInterface {
                id: template_id,
                name: CodaTemplateName::new(template_name.clone()),
                signals,
                variable_names: variables,
                is_uninterpreted,
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

            let body = if !interface.is_uninterpreted {
                println!("compiling coda body for template '{}'...", interface.name.string);
                // let mut variables: Vec<CodaVariable> = Vec::new();
                // for x in interface.variable_names.iter().cloned() {
                //     let fresh_index = variables.iter().filter(|y| y.string == x).count();
                //     variables.push(CodaVariable { fresh_index, string: x })
                // }
                let variables: Vec<_> = interface
                    .variable_names
                    .iter()
                    .map(|string| CodaVariable { string: string.clone(), fresh_index: 0 })
                    .collect();

                let mut values = Vec::new();
                for x in &_circuit.coda_data.field_tracking {
                    values.push(CodaValue::new(&x))
                }

                let ctx = CodaCompileContext {
                    template_interfaces: coda_template_interfaces.clone(),
                    variables,
                    variable_updates: Vec::new(),
                    signals: interface.signals.clone(),
                    subcomponents: Vec::new(),
                    values,
                    // indexed value out of bounds
                    default_value: CodaValue::new("666"),
                };
                let instruction_zipper: InstructionZipper =
                    InstructionZipper { instructions: template_code_info.body.clone(), index: 0 };
                Some(coda_compile_stmt(&ctx, instruction_zipper))
            } else {
                None
            };

            println!("finished compiling coda body");
            coda_program.templates.push(CodaTemplate { interface: interface.clone(), body })
        }

        {
            println!("coda_compile");
            let ocaml = coda_program.coda_compile();
            println!("ocaml_compile");
            let string = ocaml.ocaml_compile();

            println!("BEGIN Debug Circom Circuit\n\n{}\n\nEND Debug Circom Circuit", string);
        }

        println!("finished compiling coda program");

        coda_program
    }
}

#[derive(Clone)]
struct CodaCompileContext {
    pub template_interfaces: Vec<CodaTemplateInterface>,
    pub variables: Vec<CodaVariable>,
    // Whenever a variable is updated, its added to here. Then subsequent uses of that variable need to be freshened.
    pub variable_updates: Vec<CodaVariable>,
    pub signals: Vec<CodaSignal>,
    pub subcomponents: Vec<CodaSubcomponent>,
    pub values: Vec<CodaValue>,
    pub default_value: CodaValue,
}

impl CodaCompileContext {
    pub fn get_coda_variable(&self, i: usize) -> &CodaVariable {
        &self.variables[i]
    }

    pub fn get_coda_signal(&self, i: usize) -> &CodaSignal {
        &self.signals[i]
    }

    fn get_coda_subcomponent(&self, i: usize) -> &CodaSubcomponent {
        &self.subcomponents[i]
    }

    fn get_coda_value(&self, i: usize) -> &CodaValue {
        if i < self.values.len() {
            &self.values[i]
        } else {
            &self.default_value
        }
    }

    fn get_coda_output_signals(&self) -> Vec<CodaSignal> {
        let mut outputs = Vec::new();
        for signal in &self.signals {
            if signal.visibility.is_output() {
                outputs.push(signal.clone())
            }
        }
        outputs
    }

    fn get_coda_template_interface(&self, template_id: usize) -> &CodaTemplateInterface {
        self.template_interfaces.iter().find(|interface| interface.id == template_id).unwrap()
    }

    pub fn register_variable_update(&mut self, var_i: usize) -> () {
        // freshen the variable at that index
        let mut var = self.get_coda_variable(var_i).clone();
        var.fresh_index += 1;
        self.variables[var_i] = var;
    }
}

#[derive(Clone, Debug)]
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
        self.instructions[self.index].clone()
    }

    pub fn next(&self) -> Option<Self> {
        let next_index = self.index + 1;
        if next_index < self.instructions.len() {
            Some(Self { instructions: self.instructions.clone(), index: next_index })
        } else {
            None
        }
    }

    pub fn insert_next_instructions(&mut self, instructions: Vec<Box<Instruction>>) -> () {
        for instruction in instructions.iter().rev() {
            self.instructions.insert(self.index + 1, instruction.clone())
        }
    }
}

fn coda_compile_named(
    ctx: &CodaCompileContext,
    location_rule: &LocationRule,
    address_type: &AddressType,
) -> CodaNamed {
    let loc_i = match location_rule {
        LocationRule::Indexed { location, template_header: _ } => {
            from_constant_instruction(location.as_ref())
        }
        LocationRule::Mapped { signal_code: _, indexes: _ } => panic!(),
    };
    match address_type {
        AddressType::Variable => CodaNamed::Variable(ctx.get_coda_variable(loc_i).clone()),
        AddressType::Signal => {
            let sig = ctx.get_coda_signal(loc_i).clone();
            CodaNamed::Signal(sig)
        }
        AddressType::SubcmpSignal {
            cmp_address,
            uniform_parallel_value: _,
            is_output: _,
            input_information: _,
        } => {
            let subcmp_i = from_constant_instruction(cmp_address);
            let subcmp: &CodaSubcomponent = ctx.get_coda_subcomponent(subcmp_i);
            let subcmp_sig = subcmp.interface.signals[loc_i].to_coda_subcomponent_signal(subcmp);
            CodaNamed::SubcomponentSignal(subcmp_sig)
        }
    }
}

fn coda_compile_next_stmt(
    ctx: &CodaCompileContext,
    instruction_zipper: InstructionZipper,
) -> CodaStmt {
    println!(
        "coda_compile_next_stmt({})",
        pretty_print_instruction(instruction_zipper.current_instruction().as_ref())
    );
    match instruction_zipper.next() {
        Some(new_instruction_zipper) => {
            println!("coda_compile_next_stmt: SOME(new_instruction_zipper)");
            coda_compile_stmt(ctx, new_instruction_zipper)
        }
        None => {
            println!("coda_compile_next_stmt: NONE");
            // There are no next instructions, so end with the resulting output as a
            // tuple of the processing template's output signals.
            let output_signals: Vec<CodaSignal> = ctx.get_coda_output_signals();
            let output_exprs: Vec<_> =
                output_signals.iter().map(|signal| signal.to_coda_expr()).collect();
            CodaStmt::Output(CodaExpr::coda_tuple_or_single(output_exprs))
        }
    }
}

fn coda_compile_stmt(ctx: &CodaCompileContext, instruction_zipper: InstructionZipper) -> CodaStmt {
    println!(
        "coda_compile_stmt({})",
        pretty_print_instruction(instruction_zipper.current_instruction().as_ref())
    );
    match instruction_zipper.current_instruction().as_ref() {
        Instruction::Assert(ass) => match ass.evaluate.as_ref() {
            Instruction::Compute(ComputeBucket { op: OperatorType::Eq(_), stack, .. }) => {
                let e0 = coda_compile_expr(ctx, stack[0].as_ref());
                let e1 = coda_compile_expr(ctx, stack[1].as_ref());
                let s = coda_compile_next_stmt(ctx, instruction_zipper);
                CodaStmt::AssertEqual(0, e0, e1, Box::new(s))
            }
            _ => panic!(),
        },

        Instruction::Constraint(cstr) => {
            let next_instruction = match cstr {
                ConstraintBucket::Substitution(next_instruction) => next_instruction,
                ConstraintBucket::Equality(next_instruction) => next_instruction,
            };

            let mut next_instruction_zipper = instruction_zipper.clone();
            next_instruction_zipper.insert_next_instructions(vec![next_instruction.clone()]);
            next_instruction_zipper = next_instruction_zipper.next().unwrap();

            coda_compile_stmt(ctx, next_instruction_zipper)
        }

        Instruction::Block(block) => {
            let mut next_instruction_zipper = instruction_zipper.clone();
            next_instruction_zipper.insert_next_instructions(block.body.iter().cloned().collect());
            next_instruction_zipper = next_instruction_zipper.next().unwrap();
            coda_compile_stmt(ctx, next_instruction_zipper)
        }

        Instruction::Store(store) => {
            let val = coda_compile_expr(ctx, store.src.as_ref());

            match &store.dest_address_type {
                // If this store is to the last input to subcomponent, then actually "call" subcomponent here.
                AddressType::SubcmpSignal {
                    cmp_address,
                    uniform_parallel_value: _,
                    is_output: _,
                    input_information: InputInformation::Input { status: StatusInput::Last },
                } => {
                    let named = coda_compile_named(ctx, &store.dest, &store.dest_address_type);
                    let subcmp_i = from_constant_instruction(cmp_address);
                    let subcmp: &CodaSubcomponent = ctx.get_coda_subcomponent(subcmp_i);
                    let body = coda_compile_next_stmt(ctx, instruction_zipper);
                    CodaStmt::Define(
                        named,
                        val,
                        Box::new(CodaStmt::CallSubcomponent(subcmp.clone(), Box::new(body))),
                    )
                }
                AddressType::Variable => {
                    match &store.dest {
                        LocationRule::Indexed { location, template_header: _ } => {
                            // register variable update in the new context
                            let var_i = from_constant_instruction(location.as_ref());
                            let mut new_ctx = ctx.clone();
                            new_ctx.register_variable_update(var_i);

                            // the variable's value uses the new context
                            let named =
                                coda_compile_named(&new_ctx, &store.dest, &store.dest_address_type);

                            // the body uses the new context
                            let body = coda_compile_next_stmt(&new_ctx, instruction_zipper);

                            // the value was already computed using the old context
                            CodaStmt::Define(named, val, Box::new(body))
                        }
                        LocationRule::Mapped { signal_code: _, indexes: _ } => panic!(),
                    }
                }
                // Otherwise, just a normal define
                _ => {
                    let named = coda_compile_named(ctx, &store.dest, &store.dest_address_type);
                    let body = coda_compile_next_stmt(ctx, instruction_zipper);
                    CodaStmt::Define(named, val, Box::new(body))
                }
            }
        }

        // Adds subcomponent to context, but doesn't actually "use" it right here,
        // since need to instantiate inputs first.
        Instruction::CreateCmp(create_cmp) => {
            let mut subcomponents = ctx.subcomponents.clone();
            let index = from_constant_instruction(create_cmp.sub_cmp_id.as_ref());
            let template_id = create_cmp.template_id;
            let interface = ctx.get_coda_template_interface(template_id).clone();

            for i in 0..create_cmp.number_of_cmp {
                let index = index + i;
                let name = if i == 0 {
                    CodaComponentName::new(format!("{}", create_cmp.name_subcomponent))
                } else {
                    CodaComponentName::new(format!("{}_c{}", create_cmp.name_subcomponent, i))
                };
                subcomponents.push(CodaSubcomponent { interface: interface.clone(), name, index });
            }

            let ctx_new: CodaCompileContext = CodaCompileContext { subcomponents, ..ctx.clone() };
            coda_compile_next_stmt(&ctx_new, instruction_zipper)
        }

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
    println!("coda_compile_expr({})", pretty_print_instruction(instruction));
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
            for arg in &call.arguments {
                es.push(Box::new(coda_compile_expr(ctx, arg.as_ref())))
            }
            CodaExpr::Call(call.symbol.clone(), es)
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
