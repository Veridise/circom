use std::str::FromStr;
use crate::intermediate_representation::Instruction;
use crate::intermediate_representation::ir_interface::*;
use crate::translating_traits::*;
use code_producers::coda_elements::*;
use code_producers::coda_elements::summary::SummaryRoot;
// use code_producers::coda_elements::summary::TemplateSummary;
use program_structure::program_archive::ProgramArchive;
use super::circuit::Circuit;

const UNINTERPRETED_CIRCUIT_NAMES: [&str; 8] =
    ["AbstractCircuit", "PoseidonEx", "MultiMux1", "Ark", "Mix", "MixS", "MixLast", "MultiMux1"];

const DUMMY_CIRCUIT_NAMES: [&str; 10] = [
    "Poseidon",
    "Num2Bits",
    "Bits2Num",
    "LessThan",
    "IsEqual",
    "GreaterEqThan",
    "GreaterThan",
    "IsZero",
    "Or",
    "ExtractBits",
];

// const __DEBUG: bool = true;
const __DEBUG: bool = false;

impl CompileCoda for Circuit {
    fn compile_coda(
        &self,
        _circuit: &Circuit,
        program_archive: &ProgramArchive,
        summary: &SummaryRoot,
    ) -> code_producers::coda_elements::CodaProgram {
        let mut coda_program = CodaProgram::default();

        {
            println!("====[ templates ]====");
            for template in &self.templates {
                println!("template:");
                println!("  - name: {}", template.name);
                println!("  - header: {}", template.header);
                println!("  - number_of_components: {}", template.number_of_components);
            }
            println!();

            println!("====[ components ]====");
            let component_index_mapping: &std::collections::HashMap<
                String,
                std::collections::HashMap<usize, std::ops::Range<usize>>,
            > = &self.llvm_data.component_index_mapping;

            for (name, map) in component_index_mapping.iter() {
                println!("BEGIN component: {}:", name);
                for (i, r) in map.iter() {
                    println!("- (i, r) = ({i}, {r:?})");
                }
                println!("END component: {}:", name);
                println!();
            }

            // panic!("[breakpoint]");
        }

        // accumulate coda_template_interfaces
        let coda_template_interfaces: &mut Vec<CodaTemplateInterface> = &mut Vec::new();
        for (template_id, template_code_info) in self.templates.iter().enumerate() {
            let template_summary = summary.components[template_id].clone();
            let template_name = template_summary.name.clone();
            // let template_header = template_code_info.header.clone();
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

            let variant: CodaTemplateVariant =
                if UNINTERPRETED_CIRCUIT_NAMES.contains(&template_name.as_str()) {
                    CodaTemplateVariant::Uninterpreted
                } else if DUMMY_CIRCUIT_NAMES.contains(&template_name.as_str()) {
                    CodaTemplateVariant::NonDet
                } else {
                    CodaTemplateVariant::Normal
                };

            // let name = CodaTemplateName::new(template_name.clone());
            // let name = CodaTemplateName::new(template_header.clone());

            // Only use `_instN` suffix in name if there are multiple instances of this template.
            let name = {
                let mut instance_count = 0;
                for cti in coda_template_interfaces.iter_mut() {
                    if cti.name.eq_base(&template_name) {
                        instance_count += 1;
                        cti.name.init_zero_instance_number()
                    }
                }

                // let instance_count = coda_template_interfaces
                //     .iter()
                //     .filter(|cti| cti.name.eq_base(&template_name))
                //     .count();

                // if instance_count == 0 {
                //     CodaTemplateName::new(template_name, 0)
                // } else {
                //     CodaTemplateName::new(format!("{}_inst{}", template_name, instance_count))
                // }

                CodaTemplateName::new(
                    template_name,
                    if instance_count > 0 { Some(instance_count) } else { None },
                )
            };

            coda_template_interfaces.push(CodaTemplateInterface {
                id: template_id,
                name,
                signals,
                variable_names: variables,
                variant,
            });
        }

        // accumulate coda_program.templates
        println!("Accumulate coda_program.templates");
        for (template_id, template_code_info) in self.templates.iter().enumerate() {
            let template_summary = &summary.components[template_id];
            let template_name = &template_summary.name;
            let template_header = &template_code_info.header;
            let _template_data = program_archive.get_template_data(template_name);

            println!("Accumulate: {template_header} (template_id = {template_id})");

            // let _template_code_info = circuit.get_template(template_id);

            // let interface =
            //     coda_template_interfaces.iter().find(|cti| cti.id == template_id).unwrap();

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

            let body = match interface.variant {
                CodaTemplateVariant::Normal => {
                    println!();
                    println!("template {:?}: compiling body...", interface.name);
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

                    let instruction_zipper: InstructionZipper = InstructionZipper {
                        instructions: template_code_info.body.clone(),
                        index: 0,
                    };
                    Some(coda_compile_stmt(&ctx, instruction_zipper))
                }
                CodaTemplateVariant::Uninterpreted => {
                    println!("template '{:?}': uninterpreted", interface.name);
                    None
                }
                CodaTemplateVariant::NonDet => {
                    println!("template '{:?}': NonDet", interface.name);
                    // A tuple with the appropriate number of outputs in the output tuple.
                    let es: Vec<CodaExpr> = interface
                        .signals
                        .iter()
                        .filter(|signal| signal.visibility.is_output())
                        .map(|_| CodaExpr::Star)
                        .collect();
                    Some(CodaStmt::Output(CodaExpr::coda_tuple_or_single(es)))
                }
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
    if __DEBUG {
        println!(
            "coda_compile_next_stmt({})",
            pretty_print_instruction(instruction_zipper.current_instruction().as_ref()),
        );
    }
    match instruction_zipper.next() {
        Some(new_instruction_zipper) => {
            if __DEBUG {
                println!("coda_compile_next_stmt: SOME(new_instruction_zipper)");
            }
            coda_compile_stmt(ctx, new_instruction_zipper)
        }
        None => {
            if __DEBUG {
                println!("coda_compile_next_stmt: NONE");
            }
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
    if __DEBUG {
        println!(
            "coda_compile_stmt({})",
            pretty_print_instruction(instruction_zipper.current_instruction().as_ref())
        );
    }
    match instruction_zipper.current_instruction().as_ref() {
        Instruction::Assert(ass) => match ass.evaluate.as_ref() {
            Instruction::Compute(ComputeBucket { op: OperatorType::Eq(_), stack, .. }) => {
                let e0 = coda_compile_expr(ctx, stack[0].as_ref());
                let e1 = coda_compile_expr(ctx, stack[1].as_ref());
                let s = coda_compile_next_stmt(ctx, instruction_zipper);
                CodaStmt::AssertEqual(0, e0, e1, Box::new(s))
            }
            // `assert(e)` is the same as `assert(e == 1)`
            instruction => {
                let e0 = coda_compile_expr(ctx, &instruction);
                let e1 = CodaExpr::Value(CodaValue::new("1"));
                let s = coda_compile_next_stmt(ctx, instruction_zipper);
                CodaStmt::AssertEqual(0, e0, e1, Box::new(s))
            }
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
            println!("Instruction::CreateCmp:");
            println!("  - cmp_unique_id: {}", create_cmp.cmp_unique_id);
            println!("  - component_offset: {}", create_cmp.component_offset);
            println!("  - component_offset_jump: {}", create_cmp.component_offset_jump);

            let mut subcomponents = ctx.subcomponents.clone();
            let index = from_constant_instruction(create_cmp.sub_cmp_id.as_ref());
            println!("  - index: {}", index);
            let template_id = create_cmp.template_id;
            println!("  - template_id: {}", template_id);
            let interface = ctx.get_coda_template_interface(template_id).clone();
            let number_of_cmp = create_cmp.number_of_cmp;
            println!("  - number_of_cmp: {}", number_of_cmp);

            for i in 0..number_of_cmp {
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
    if __DEBUG {
        println!("coda_compile_expr({})", pretty_print_instruction(instruction));
    }
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
                OperatorType::PrefixSub => panic!(), // TODO: used in hydra-s1
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
        Instruction::Compute(compute) => {
			if compute.stack.len() == 1 {
				format!(
					"Compute(op={}, arg0={}, arg1={})",
					compute.op.to_string(),
					pretty_print_instruction(&compute.stack[0]),
					"NO SECOND ARG!"
				)
			} else if compute.stack.len() == 2 {
				format!(
					"Compute(op={}, arg0={}, arg1={})",
					compute.op.to_string(),
					pretty_print_instruction(&compute.stack[0]),
					pretty_print_instruction(&compute.stack[1])
				)
			} else {
				format!("a compute instruction has more than 2 args???: {:?}", compute)
			}
        },
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
