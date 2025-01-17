pub use either::Either;
use super::{ir_interface::*, make_ref};
use crate::translating_traits::*;
use crate::intermediate_representation::{BucketId, new_id, SExp, ToSExp, UpdateId};
use code_producers::c_elements::*;
use code_producers::llvm_elements::{
    run_fn_name, to_enum, ConstraintKind, LLVMIRProducer, LLVMInstruction, LLVMValue,
};
use code_producers::llvm_elements::array_switch::unsized_array_ptr_ty;
use code_producers::llvm_elements::instructions::{
    create_array_copy, create_call, create_constraint_values_call, create_gep,
    create_load_with_name, create_pointer_cast, create_store, create_sub_with_name,
};
use code_producers::llvm_elements::stdlib::LLVM_DONOTHING_FN_NAME;
use code_producers::llvm_elements::values::{create_literal_u32, zero};
use code_producers::wasm_elements::*;

#[derive(Clone, Debug, Eq, PartialEq, Ord, PartialOrd)]
pub struct StoreBucket {
    pub id: BucketId,
    pub source_file_id: Option<usize>,
    pub line: usize,
    pub message_id: usize,
    pub context: InstrContext,
    pub dest_is_output: bool,
    pub dest_address_type: AddressType,
    pub dest: LocationRule,
    pub src: InstructionPointer,
    pub bounded_fn: Option<String>,
}

impl IntoInstruction for StoreBucket {
    fn into_instruction(self) -> Instruction {
        Instruction::Store(self)
    }
}

impl ObtainMeta for StoreBucket {
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

impl ToString for StoreBucket {
    fn to_string(&self) -> String {
        let line = self.line.to_string();
        let template_id = self.message_id.to_string();
        let dest_type = self.dest_address_type.to_string();
        let dest = self.dest.to_string();
        let src = self.src.to_string();
        format!(
            "STORE(line:{},template_id:{},dest_type:{},dest:{},src:{})",
            line, template_id, dest_type, dest, src
        )
    }
}

impl ToSExp for StoreBucket {
    fn to_sexp(&self) -> SExp {
        SExp::list([
            SExp::atom("STORE"),
            SExp::key_val("id", SExp::atom(self.id)),
            SExp::key_val("line", SExp::atom(self.line)),
            SExp::key_val("context", SExp::atom(self.context)),
            SExp::key_val("dest_is_output", SExp::atom(self.dest_is_output)),
            SExp::key_val("bounded_fn", SExp::atom(format!("{:?}", self.bounded_fn))),
            SExp::key_val("ctx", SExp::atom(self.context.size)),
            SExp::key_val("dest_type", self.dest_address_type.to_sexp()),
            SExp::key_val("dest", self.dest.to_sexp()),
            SExp::key_val("src", self.src.to_sexp()),
        ])
    }
}

impl UpdateId for StoreBucket {
    fn update_id(&mut self) {
        self.id = new_id();
        self.src.update_id();
        self.dest.update_id();
        self.dest_address_type.update_id();
    }
}

impl StoreBucket {
    /// The caller must manage the debug location information before calling this function.
    pub fn produce_llvm_ir<'a>(
        producer: &dyn LLVMIRProducer<'a>,
        src: Either<LLVMInstruction<'a>, &InstructionPointer>,
        dest: &LocationRule,
        dest_address_type: &AddressType,
        context: InstrContext,
        bounded_fn: &Option<String>,
    ) -> Option<LLVMValue<'a>> {
        let dest_index =
            dest.produce_llvm_ir(producer).expect("Must produce some kind of instruction!");

        // Use a closure here to avoid creating dead code if this value is not used.
        //  The closure also delays code generation so that the value being stored
        //  is always generated after the destination pointer for the store.
        let mut source: Box<dyn Fn() -> LLVMInstruction<'a>> = Box::new(|| match src {
            Either::Left(s) => s,
            Either::Right(s) => to_enum(s.produce_llvm_ir(producer).unwrap()),
        });

        // If we have bounds for an unknown index, we will get the base address and let the function check the bounds
        match &bounded_fn {
            Some(name) => {
                assert!(producer.body_ctx().get_wrapping_constraint().is_none());
                assert_eq!(1, context.size, "unhandled array store");
                if name != LLVM_DONOTHING_FN_NAME {
                    let arr_ptr = match &dest_address_type {
                        AddressType::Variable => producer.body_ctx().get_variable_array(producer),
                        AddressType::Signal => producer.template_ctx().get_signal_array(producer),
                        AddressType::SubcmpSignal { cmp_address, .. } => {
                            let addr = cmp_address
                                .produce_llvm_ir(producer)
                                .expect("The address of a subcomponent must yield a value!");
                            let subcmp = producer.template_ctx().load_subcmp_addr(producer, addr);
                            create_gep(producer, subcmp, &[zero(producer)])
                        }
                    };
                    let arr_ptr =
                        create_pointer_cast(producer, arr_ptr, unsized_array_ptr_ty(producer));
                    create_call(
                        producer,
                        name.as_str(),
                        &[arr_ptr.into(), dest_index, source().into_int_value().into()],
                    );
                }
            }
            None => {
                let dest_gep =
                    make_ref(producer, &dest_address_type, dest_index.into_int_value(), false);
                if context.size > 1 {
                    // In the non-scalar case, produce an array copy. If the stored source
                    //  is a LoadBucket, first convert it into an address.
                    if let Either::Right(r) = src {
                        if let Instruction::Load(v) = &**r {
                            source = Box::new(move || {
                                let src_index = v
                                    .src
                                    .produce_llvm_ir(producer)
                                    .expect("Must produce some kind of instruction!")
                                    .into_int_value();
                                make_ref(producer, &v.address_type, src_index, false).into()
                            });
                        }
                    }
                    let gen_constraints = producer.body_ctx().get_wrapping_constraint().is_some();
                    if gen_constraints {
                        assert_eq!(
                            producer.body_ctx().get_wrapping_constraint().unwrap(),
                            ConstraintKind::Substitution
                        );
                    }
                    create_array_copy(
                        producer,
                        source().into_pointer_value(),
                        dest_gep,
                        context.size,
                        gen_constraints,
                    );
                } else {
                    // In the scalar case, just produce a store from the source value that was given
                    let value = source();
                    create_store(producer, dest_gep, value);
                    if producer.body_ctx().get_wrapping_constraint().is_some() {
                        assert_eq!(
                            producer.body_ctx().get_wrapping_constraint().unwrap(),
                            ConstraintKind::Substitution
                        );
                        create_constraint_values_call(producer, value, dest_gep);
                    }
                }
            }
        };

        // If we have a subcomponent storage decrement the counter by the size of the store (i.e., context.size)
        if let AddressType::SubcmpSignal { cmp_address, .. } = &dest_address_type {
            let addr = cmp_address
                .produce_llvm_ir(producer)
                .expect("The address of a subcomponent must yield a value!");
            let counter = producer.template_ctx().load_subcmp_counter(producer, addr, true);
            if let Some(counter) = counter {
                let value = create_load_with_name(producer, counter, "load.subcmp.counter");
                let new_value = create_sub_with_name(
                    producer,
                    value.into_int_value(),
                    create_literal_u32(producer, context.size as u64),
                    "decrement.counter",
                );
                create_store(producer, counter, new_value);
            }
        }

        // If the input information is unknown, add a check for the counter to call
        // the subcomponent if its zero. If its last just call run directly.
        if let AddressType::SubcmpSignal {
            input_information: InputInformation::Input { status },
            cmp_address,
            ..
        } = &dest_address_type
        {
            let sub_cmp_name = match dest {
                LocationRule::Indexed { template_header, .. } => {
                    template_header.as_ref().expect("Could not get the name of the subcomponent")
                }
                LocationRule::Mapped { .. } => {
                    unreachable!("LocationRule::Mapped should have been replaced")
                }
            };
            match status {
                StatusInput::Last => {
                    // If we reach this point gep is the address of the subcomponent so we can just reuse it
                    let addr = cmp_address
                        .produce_llvm_ir(producer)
                        .expect("The address of a subcomponent must yield a value!");
                    let subcmp = producer.template_ctx().load_subcmp_addr(producer, addr);
                    create_call(producer, run_fn_name(sub_cmp_name).as_str(), &[subcmp.into()]);
                }
                StatusInput::Unknown => {
                    unreachable!("There should not be Unknown input status");
                }
                _ => {}
            }
        }

        None // We don't return a Value from this bucket
    }
}

impl WriteLLVMIR for StoreBucket {
    fn produce_llvm_ir<'a>(&self, producer: &dyn LLVMIRProducer<'a>) -> Option<LLVMValue<'a>> {
        Self::manage_debug_loc_from_curr(producer, self);
        // A store instruction has a source that states the origin of the value that is going to be stored
        Self::produce_llvm_ir(
            producer,
            Either::Right(&self.src),
            &self.dest,
            &self.dest_address_type,
            self.context,
            &self.bounded_fn,
        )
    }
}

impl WriteWasm for StoreBucket {
    fn produce_wasm(&self, producer: &WASMProducer) -> Vec<String> {
        use code_producers::wasm_elements::wasm_code_generator::*;
        let mut instructions = vec![];
        if self.context.size == 0 {
            return vec![];
        }
        if producer.needs_comments() {
	    instructions.push(format!(";; store bucket. Line {}", self.line)); //.to_string()
	}
        let mut my_template_header = Option::<String>::None;
        if producer.needs_comments() {
            instructions.push(";; getting dest".to_string());
	}
        match &self.dest {
            LocationRule::Indexed { location, template_header } => {
                let mut instructions_dest = location.produce_wasm(producer);
                instructions.append(&mut instructions_dest);
                let size = producer.get_size_32_bits_in_memory() * 4;
                instructions.push(set_constant(&size.to_string()));
                instructions.push(mul32());
                match &self.dest_address_type {
                    AddressType::Variable => {
                        instructions.push(get_local(producer.get_lvar_tag()));
                    }
                    AddressType::Signal => {
                        instructions.push(get_local(producer.get_signal_start_tag()));
                    }
                    AddressType::SubcmpSignal { cmp_address, .. } => {
                        my_template_header = template_header.clone();
                        instructions.push(get_local(producer.get_offset_tag()));
                        instructions.push(set_constant(
                            &producer.get_sub_component_start_in_component().to_string(),
                        ));
                        instructions.push(add32());
                        let mut instructions_sci = cmp_address.produce_wasm(producer);
                        instructions.append(&mut instructions_sci);
                        instructions.push(set_constant("4")); //size in byte of i32
                        instructions.push(mul32());
                        instructions.push(add32());
                        instructions.push(load32(None)); //subcomponent block
                        instructions.push(set_local(producer.get_sub_cmp_tag()));
                        instructions.push(get_local(producer.get_sub_cmp_tag()));
                        instructions.push(set_constant(
                            &producer.get_signal_start_address_in_component().to_string(),
                        ));
                        instructions.push(add32());
                        instructions.push(load32(None)); //subcomponent start_of_signals
                    }
                }
                instructions.push(add32());
            }
            LocationRule::Mapped { signal_code, indexes } => {
                match &self.dest_address_type {
                    AddressType::SubcmpSignal { cmp_address, .. } => {
			if producer.needs_comments() {
                            instructions.push(";; is subcomponent".to_string());
			}
                        instructions.push(get_local(producer.get_offset_tag()));
                        instructions.push(set_constant(
                            &producer.get_sub_component_start_in_component().to_string(),
                        ));
                        instructions.push(add32());
                        let mut instructions_sci = cmp_address.produce_wasm(producer);
                        instructions.append(&mut instructions_sci);
                        instructions.push(set_constant("4")); //size in byte of i32
                        instructions.push(mul32());
                        instructions.push(add32());
                        instructions.push(load32(None)); //subcomponent block
                        instructions.push(set_local(producer.get_sub_cmp_tag()));
                        instructions.push(get_local(producer.get_sub_cmp_tag()));
                        instructions.push(load32(None)); // get template id                     A
                        instructions.push(set_constant("4")); //size in byte of i32
                        instructions.push(mul32());
                        instructions.push(load32(Some(
                            &producer.get_template_instance_to_io_signal_start().to_string(),
                        ))); // get position in component io signal to info list
                        let signal_code_in_bytes = signal_code * 4; //position in the list of the signal code
                        instructions.push(load32(Some(&signal_code_in_bytes.to_string()))); // get where the info of this signal is
                        //now we have first the offset, and then the all size dimensions but the last one
                        if indexes.len() <= 1 {
                            instructions.push(load32(None)); // get signal offset (it is already the actual one in memory);
                            if indexes.len() == 1 {
                                let mut instructions_idx0 = indexes[0].produce_wasm(producer);
                                instructions.append(&mut instructions_idx0);
                                let size = producer.get_size_32_bits_in_memory() * 4;
                                instructions.push(set_constant(&size.to_string()));
                                instructions.push(mul32());
                                instructions.push(add32());
                            }
                        } else {
                            instructions.push(set_local(producer.get_io_info_tag()));
                            instructions.push(get_local(producer.get_io_info_tag()));
                            instructions.push(load32(None)); // get signal offset (it is already the actual one in memory);
                                                             // compute de move with 2 or more dimensions
                            let mut instructions_idx0 = indexes[0].produce_wasm(producer);
                            instructions.append(&mut instructions_idx0); // start with dimension 0
                            for i in 1..indexes.len() {
                                instructions.push(get_local(producer.get_io_info_tag()));
                                let offsetdim = 4 * i;
                                instructions.push(load32(Some(&offsetdim.to_string()))); // get size of ith dimension
                                instructions.push(mul32()); // multiply the current move by size of the ith dimension
                                let mut instructions_idxi = indexes[i].produce_wasm(producer);
                                instructions.append(&mut instructions_idxi);
                                instructions.push(add32()); // add move upto dimension i
                            }
                            //we have the total move; and is multiplied by the size of memory Fr in bytes
                            let size = producer.get_size_32_bits_in_memory() * 4;
                            instructions.push(set_constant(&size.to_string()));
                            instructions.push(mul32()); // We have the total move in bytes
                            instructions.push(add32()); // add to the offset of the signal
                        }
                        instructions.push(get_local(producer.get_sub_cmp_tag()));
                        instructions.push(set_constant(
                            &producer.get_signal_start_address_in_component().to_string(),
                        ));
                        instructions.push(add32());
                        instructions.push(load32(None)); //subcomponent start_of_signals
                        instructions.push(add32()); // we get the position of the signal (with indexes) in memory
                    }
                    _ => {
                        assert!(false);
                    }
                }
            }
        }
        if producer.needs_comments() {
            instructions.push(";; getting src".to_string());
	}
        if self.context.size > 1 {
            instructions.push(set_local(producer.get_store_aux_1_tag()));
        }
        let mut instructions_src = self.src.produce_wasm(producer);
        instructions.append(&mut instructions_src);
        if self.context.size == 1 {
            instructions.push(call("$Fr_copy"));
        } else {
            instructions.push(set_local(producer.get_store_aux_2_tag()));
            instructions.push(set_constant(&self.context.size.to_string()));
            instructions.push(set_local(producer.get_copy_counter_tag()));
            instructions.push(add_block());
            instructions.push(add_loop());
            instructions.push(get_local(producer.get_copy_counter_tag()));
            instructions.push(eqz32());
            instructions.push(br_if("1"));
            instructions.push(get_local(producer.get_store_aux_1_tag()));
            instructions.push(get_local(producer.get_store_aux_2_tag()));
            instructions.push(call("$Fr_copy"));
            instructions.push(get_local(producer.get_copy_counter_tag()));
            instructions.push(set_constant("1"));
            instructions.push(sub32());
            instructions.push(set_local(producer.get_copy_counter_tag()));
            instructions.push(get_local(producer.get_store_aux_1_tag()));
            let s = producer.get_size_32_bits_in_memory() * 4;
            instructions.push(set_constant(&s.to_string()));
            instructions.push(add32());
            instructions.push(set_local(producer.get_store_aux_1_tag()));
            instructions.push(get_local(producer.get_store_aux_2_tag()));
            instructions.push(set_constant(&s.to_string()));
            instructions.push(add32());
            instructions.push(set_local(producer.get_store_aux_2_tag()));
            instructions.push(br("0"));
            instructions.push(add_end());
            instructions.push(add_end());
        }
        match &self.dest_address_type {
            AddressType::SubcmpSignal { .. } => {
                // if subcomponent input check if run needed
		if producer.needs_comments() {
                    instructions.push(";; decrease counter".to_string()); // by self.context.size
		}
                instructions.push(get_local(producer.get_sub_cmp_tag())); // to update input signal counter
                instructions.push(get_local(producer.get_sub_cmp_tag())); // to read input signal counter
                instructions.push(load32(Some(
                    &producer.get_input_counter_address_in_component().to_string(),
                ))); //remaining inputs to be set
                instructions.push(set_constant(&self.context.size.to_string()));
                instructions.push(sub32());
                instructions.push(store32(Some(
                    &producer.get_input_counter_address_in_component().to_string(),
                ))); // update remaining inputs to be set
		if producer.needs_comments() {
                    instructions.push(";; check if run is needed".to_string());
		}
                instructions.push(get_local(producer.get_sub_cmp_tag()));
                instructions.push(load32(Some(
                    &producer.get_input_counter_address_in_component().to_string(),
                )));
                instructions.push(eqz32());
                instructions.push(add_if());
		if producer.needs_comments() {
                    instructions.push(";; run sub component".to_string());
		}
                instructions.push(get_local(producer.get_sub_cmp_tag()));
                match &self.dest {
                    LocationRule::Indexed { .. } => {
                        if let Some(name) = &my_template_header {
                            instructions.push(call(&format!("${}_run", name)));
                            instructions.push(tee_local(producer.get_merror_tag()));
                            instructions.push(add_if());
                            instructions.push(set_constant(&self.message_id.to_string()));
                            instructions.push(set_constant(&self.line.to_string()));
                            instructions.push(call("$buildBufferMessage"));
                            instructions.push(call("$printErrorMessage"));
                            instructions.push(get_local(producer.get_merror_tag()));    
                            instructions.push(add_return());
                            instructions.push(add_end());
                        } else {
                            assert!(false);
                        }
                    }
                    LocationRule::Mapped { .. } => {
                        instructions.push(get_local(producer.get_sub_cmp_tag()));
                        instructions.push(load32(None)); // get template id
                        instructions.push(call_indirect(
                            &"$runsmap".to_string(),
                            &"(type $_t_i32ri32)".to_string(),
                        ));
                        instructions.push(tee_local(producer.get_merror_tag()));
                        instructions.push(add_if());
                        instructions.push(set_constant(&self.message_id.to_string()));
                        instructions.push(set_constant(&self.line.to_string()));
                        instructions.push(call("$buildBufferMessage"));
                        instructions.push(call("$printErrorMessage"));
                        instructions.push(get_local(producer.get_merror_tag()));    
                        instructions.push(add_return());
                        instructions.push(add_end());
                    }
                }
		if producer.needs_comments() {
                    instructions.push(";; end run sub component".to_string());
		}
                instructions.push(add_end());
            }
            _ => (),
        }
        if producer.needs_comments() {
            instructions.push(";; end of store bucket".to_string());
	}
        instructions
    }
}

impl WriteC for StoreBucket {
    fn produce_c(&self, producer: &CProducer, parallel: Option<bool>) -> (Vec<String>, String) {
        use c_code_generator::*;
        let mut prologue = vec![];
	let cmp_index_ref = "cmp_index_ref".to_string();
	let aux_dest_index = "aux_dest_index".to_string();
        if let AddressType::SubcmpSignal { cmp_address, .. } = &self.dest_address_type {
            let (mut cmp_prologue, cmp_index) = cmp_address.produce_c(producer, parallel);
            prologue.append(&mut cmp_prologue);
	    prologue.push(format!("{{"));
	    prologue.push(format!("uint {} = {};",  cmp_index_ref, cmp_index));
	}
        let ((mut dest_prologue, dest_index), my_template_header) =
            if let LocationRule::Indexed { location, template_header } = &self.dest {
                (location.produce_c(producer, parallel), template_header.clone())
            } else if let LocationRule::Mapped { signal_code, indexes } = &self.dest {
		//if Mapped must be SubcmpSignal
		let mut map_prologue = vec![];
		let sub_component_pos_in_memory = format!("{}[{}]",MY_SUBCOMPONENTS,cmp_index_ref.clone());
		let mut map_access = format!("{}->{}[{}].defs[{}].offset",
					     circom_calc_wit(), template_ins_2_io_info(),
					     template_id_in_component(sub_component_pos_in_memory.clone()),
					     signal_code.to_string());
		if indexes.len()>0 {
		    map_prologue.push(format!("{{"));
		    map_prologue.push(format!("uint map_index_aux[{}];",indexes.len().to_string()));		    
		    let (mut index_code_0, mut map_index) = indexes[0].produce_c(producer, parallel);
		    map_prologue.append(&mut index_code_0);
		    map_prologue.push(format!("map_index_aux[0]={};",map_index));
		    map_index = format!("map_index_aux[0]");
		    for i in 1..indexes.len() {
			let (mut index_code, index_exp) = indexes[i].produce_c(producer, parallel);
			map_prologue.append(&mut index_code);
			map_prologue.push(format!("map_index_aux[{}]={};",i.to_string(),index_exp));
			map_index = format!("({})*{}->{}[{}].defs[{}].lengths[{}]+map_index_aux[{}]",
					    map_index, circom_calc_wit(), template_ins_2_io_info(),
					    template_id_in_component(sub_component_pos_in_memory.clone()),
					    signal_code.to_string(),(i-1).to_string(),i.to_string());
		    }
		    map_access = format!("{}+{}",map_access,map_index);
		}
                ((map_prologue, map_access),Some(template_id_in_component(sub_component_pos_in_memory.clone())))
	    } else {
		assert!(false);
                ((vec![], "".to_string()),Option::<String>::None)
	    };
	prologue.append(&mut dest_prologue);
        // Build dest
        let dest = match &self.dest_address_type {
            AddressType::Variable => {
                format!("&{}", lvar(dest_index.clone()))
            }
            AddressType::Signal => {
                format!("&{}", signal_values(dest_index.clone()))
            }
            AddressType::SubcmpSignal { .. } => {
                let sub_cmp_start = format!(
                    "{}->componentMemory[{}[{}]].signalStart",
                    CIRCOM_CALC_WIT, MY_SUBCOMPONENTS, cmp_index_ref
                );
                format!("&{}->signalValues[{} + {}]", CIRCOM_CALC_WIT, sub_cmp_start, dest_index.clone())
            }
        };
	//keep dest_index in an auxiliar if parallel and out put
	if let AddressType::Signal = &self.dest_address_type {
	    if parallel.unwrap() && self.dest_is_output {
        prologue.push(format!("{{"));
		prologue.push(format!("uint {} = {};",  aux_dest_index, dest_index.clone()));
	    }
	}
        // store src in dest
	prologue.push(format!("{{"));
	let aux_dest = "aux_dest".to_string();
	prologue.push(format!("{} {} = {};", T_P_FR_ELEMENT, aux_dest, dest));
        // Load src
	prologue.push(format!("// load src"));
    let (mut src_prologue, src) = self.src.produce_c(producer, parallel);
    prologue.append(&mut src_prologue);
	prologue.push(format!("// end load src"));	
        std::mem::drop(src_prologue);
        if self.context.size > 1 {
            let copy_arguments = vec![aux_dest, src, self.context.size.to_string()];
            prologue.push(format!("{};", build_call("Fr_copyn".to_string(), copy_arguments)));
	    if let AddressType::Signal = &self.dest_address_type {
        if parallel.unwrap() && self.dest_is_output {
		    prologue.push(format!("{{"));
		    prologue.push(format!("for (int i = 0; i < {}; i++) {{",self.context.size));
		    prologue.push(format!("{}->componentMemory[{}].mutexes[{}+i].lock();",CIRCOM_CALC_WIT,CTX_INDEX,aux_dest_index.clone()));
		    prologue.push(format!("{}->componentMemory[{}].outputIsSet[{}+i]=true;",CIRCOM_CALC_WIT,CTX_INDEX,aux_dest_index.clone()));
		    prologue.push(format!("{}->componentMemory[{}].mutexes[{}+i].unlock();",CIRCOM_CALC_WIT,CTX_INDEX,aux_dest_index.clone()));
		    prologue.push(format!("{}->componentMemory[{}].cvs[{}+i].notify_all();",CIRCOM_CALC_WIT,CTX_INDEX,aux_dest_index.clone()));
		    prologue.push(format!("}}"));
		    prologue.push(format!("}}"));
		    prologue.push(format!("}}"));
		}
	    }
        } else {
            let copy_arguments = vec![aux_dest, src];
            prologue.push(format!("{};", build_call("Fr_copy".to_string(), copy_arguments)));
	    if let AddressType::Signal = &self.dest_address_type {
		if parallel.unwrap() && self.dest_is_output {
		    prologue.push(format!("{}->componentMemory[{}].mutexes[{}].lock();",CIRCOM_CALC_WIT,CTX_INDEX,aux_dest_index.clone()));
		    prologue.push(format!("{}->componentMemory[{}].outputIsSet[{}]=true;",CIRCOM_CALC_WIT,CTX_INDEX,aux_dest_index.clone()));
		    prologue.push(format!("{}->componentMemory[{}].mutexes[{}].unlock();",CIRCOM_CALC_WIT,CTX_INDEX,aux_dest_index.clone()));
		    prologue.push(format!("{}->componentMemory[{}].cvs[{}].notify_all();",CIRCOM_CALC_WIT,CTX_INDEX,aux_dest_index.clone()));
		    prologue.push(format!("}}"));
		}
	    }
        }
	prologue.push(format!("}}"));
        match &self.dest_address_type {
            AddressType::SubcmpSignal{ uniform_parallel_value, input_information, .. } => {
                // if subcomponent input check if run needed
                let sub_cmp_counter = format!(
                    "{}->componentMemory[{}[{}]].inputCounter",
                    CIRCOM_CALC_WIT, MY_SUBCOMPONENTS, cmp_index_ref
                );
                let sub_cmp_counter_decrease = format!(
                    "{} -= {}",
                    sub_cmp_counter, self.context.size
                );
		if let InputInformation::Input{status} = input_information {
		    if let StatusInput::NoLast = status {
			// no need to run subcomponent
			prologue.push("// no need to run sub component".to_string());
			prologue.push(format!("{};", sub_cmp_counter_decrease));
			prologue.push(format!("assert({} > 0);", sub_cmp_counter));
		    } else {
			let sub_cmp_pos = format!("{}[{}]", MY_SUBCOMPONENTS, cmp_index_ref);
			let sub_cmp_call_arguments =
			    vec![sub_cmp_pos, CIRCOM_CALC_WIT.to_string()];
            // to create the call instruction we need to consider the cases of parallel/not parallel/ known only at execution
            if uniform_parallel_value.is_some(){
                // Case parallel
                let mut call_instructions = if uniform_parallel_value.unwrap(){
                    let sub_cmp_call_name = if let LocationRule::Indexed { .. } = &self.dest {
                        format!("{}_run_parallel", my_template_header.unwrap())
                    } else {
                        format!("(*{}[{}])", function_table_parallel(), my_template_header.unwrap())
                    };
                    let mut thread_call_instr = vec![];
                        
                        // parallelism
                        thread_call_instr.push(format!("{}->componentMemory[{}].sbct[{}] = std::thread({},{});",CIRCOM_CALC_WIT,CTX_INDEX,cmp_index_ref, sub_cmp_call_name, argument_list(sub_cmp_call_arguments)));
                        thread_call_instr.push(format!("std::unique_lock<std::mutex> lkt({}->numThreadMutex);",CIRCOM_CALC_WIT));
                        thread_call_instr.push(format!("{}->ntcvs.wait(lkt, [{}]() {{return {}->numThread <  {}->maxThread; }});",CIRCOM_CALC_WIT,CIRCOM_CALC_WIT,CIRCOM_CALC_WIT,CIRCOM_CALC_WIT));
                        thread_call_instr.push(format!("ctx->numThread++;"));
                    thread_call_instr

                }
                // Case not parallel
                else{
                    let sub_cmp_call_name = if let LocationRule::Indexed { .. } = &self.dest {
                        format!("{}_run", my_template_header.unwrap())
                    } else {
                        format!("(*{}[{}])", function_table(), my_template_header.unwrap())
                    };
                    vec![format!(
                        "{};",
                        build_call(sub_cmp_call_name, sub_cmp_call_arguments)
                    )]
                };
                if let StatusInput::Unknown = status {
                    let sub_cmp_counter_decrease_andcheck = format!("!({})",sub_cmp_counter_decrease);
                    let if_condition = vec![sub_cmp_counter_decrease_andcheck];
                    prologue.push("// run sub component if needed".to_string());
                    let else_instructions = vec![];
                    prologue.push(build_conditional(if_condition,call_instructions,else_instructions));
                } else {
                    prologue.push("// need to run sub component".to_string());
                    prologue.push(format!("{};", sub_cmp_counter_decrease));
                    prologue.push(format!("assert(!({}));", sub_cmp_counter));
                    prologue.append(&mut call_instructions);
                }
            }
            // Case we only know if it is parallel at execution
            else{
                prologue.push(format!(
                    "if ({}[{}]){{",
                    MY_SUBCOMPONENTS_PARALLEL, 
                    cmp_index_ref
                ));

                // case parallel
                let sub_cmp_call_name = if let LocationRule::Indexed { .. } = &self.dest {
                    format!("{}_run_parallel", my_template_header.clone().unwrap())
                } else {
                    format!("(*{}[{}])", function_table_parallel(), my_template_header.clone().unwrap())
                };
                let mut call_instructions = vec![];  
                    // parallelism
                    call_instructions.push(format!("{}->componentMemory[{}].sbct[{}] = std::thread({},{});",CIRCOM_CALC_WIT,CTX_INDEX,cmp_index_ref, sub_cmp_call_name, argument_list(sub_cmp_call_arguments.clone())));
                    call_instructions.push(format!("std::unique_lock<std::mutex> lkt({}->numThreadMutex);",CIRCOM_CALC_WIT));
                    call_instructions.push(format!("{}->ntcvs.wait(lkt, [{}]() {{return {}->numThread <  {}->maxThread; }});",CIRCOM_CALC_WIT,CIRCOM_CALC_WIT,CIRCOM_CALC_WIT,CIRCOM_CALC_WIT));
                    call_instructions.push(format!("ctx->numThread++;"));

                if let StatusInput::Unknown = status {
                    let sub_cmp_counter_decrease_andcheck = format!("!({})",sub_cmp_counter_decrease);
                    let if_condition = vec![sub_cmp_counter_decrease_andcheck];
                    prologue.push("// run sub component if needed".to_string());
                    let else_instructions = vec![];
                    prologue.push(build_conditional(if_condition,call_instructions,else_instructions));
                } else {
                    prologue.push("// need to run sub component".to_string());
                    prologue.push(format!("{};", sub_cmp_counter_decrease));
                    prologue.push(format!("assert(!({}));", sub_cmp_counter));
                    prologue.append(&mut call_instructions);
                }
                // end of case parallel

                prologue.push(format!("}} else {{"));
                
                // case not parallel
                let sub_cmp_call_name = if let LocationRule::Indexed { .. } = &self.dest {
                    format!("{}_run", my_template_header.unwrap())
                } else {
                    format!("(*{}[{}])", function_table(), my_template_header.unwrap())
                };
                let mut call_instructions = vec![format!(
                    "{};",
                    build_call(sub_cmp_call_name, sub_cmp_call_arguments)
                )];                   
                if let StatusInput::Unknown = status {
                    let sub_cmp_counter_decrease_andcheck = format!("!({})",sub_cmp_counter_decrease);
                    let if_condition = vec![sub_cmp_counter_decrease_andcheck];
                    prologue.push("// run sub component if needed".to_string());
                    let else_instructions = vec![];
                    prologue.push(build_conditional(if_condition,call_instructions,else_instructions));
                } else {
                    prologue.push("// need to run sub component".to_string());
                    prologue.push(format!("{};", sub_cmp_counter_decrease));
                    prologue.push(format!("assert(!({}));", sub_cmp_counter));
                    prologue.append(&mut call_instructions);
                }
                // end of not parallel case
                prologue.push(format!("}}"));
            }
        }
        } else {
		    assert!(false);
		}
            }
            _ => (),
        }
	if let AddressType::SubcmpSignal { .. } = &self.dest_address_type {
	    prologue.push(format!("}}"));
	}
	if let LocationRule::Mapped { indexes, .. } = &self.dest {
	    if indexes.len() > 0 {
    		prologue.push(format!("}}"));
	    }
	}

        (prologue, "".to_string())
    }
}
