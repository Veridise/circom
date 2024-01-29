use super::ir_interface::*;
use crate::translating_traits::*;
use code_producers::c_elements::*;
use code_producers::llvm_elements::array_switch::array_ptr_ty;
use code_producers::llvm_elements::{LLVMInstruction, LLVMIRProducer};
use code_producers::llvm_elements::instructions::{create_gep, create_load, create_call, pointer_cast};
use code_producers::llvm_elements::values::zero;
use code_producers::wasm_elements::*;
use crate::intermediate_representation::{BucketId, new_id, SExp, ToSExp, UpdateId};


#[derive(Clone, Debug, Eq, PartialEq, Ord, PartialOrd)]
pub struct LoadBucket {
    pub id: BucketId,
    pub source_file_id: Option<usize>,
    pub line: usize,
    pub message_id: usize,
    pub address_type: AddressType,
    pub src: LocationRule,
    pub bounded_fn: Option<String>,
}

impl IntoInstruction for LoadBucket {
    fn into_instruction(self) -> Instruction {
        Instruction::Load(self)
    }
}

impl Allocate for LoadBucket {
    fn allocate(self) -> InstructionPointer {
        InstructionPointer::new(self.into_instruction())
    }
}

impl ObtainMeta for LoadBucket {
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

impl ToString for LoadBucket {
    fn to_string(&self) -> String {
        let line = self.line.to_string();
        let template_id = self.message_id.to_string();
        let address = self.address_type.to_string();
        let src = self.src.to_string();
        format!(
            "LOAD(line:{},template_id:{},address_type:{},src:{})",
            line, template_id, address, src
        )
    }
}

impl ToSExp for LoadBucket {
    fn to_sexp(&self) -> SExp {
        SExp::List(vec![
            SExp::Atom("LOAD".to_string()),
            SExp::Atom(format!("line:{}", self.line)),
            SExp::Atom(format!("template_id:{}", self.message_id)),
            self.address_type.to_sexp(),
            self.src.to_sexp()
        ])
    }
}

impl UpdateId for LoadBucket {
    fn update_id(&mut self) {
        self.id = new_id();
        self.address_type.update_id();
        self.src.update_id();
    }
}

impl WriteLLVMIR for LoadBucket {
    fn produce_llvm_ir<'a>(&self, producer: &dyn LLVMIRProducer<'a>) -> Option<LLVMInstruction<'a>> {
        // NOTE: do not change debug location for a load because it is not a top-level source statement

        // Generate the code of the location and use the last value as the reference
        let index = self.src.produce_llvm_ir(producer).expect("We need to produce some kind of instruction!").into_int_value();

        // If we have bounds for an unknown index, we will get the base address and let the function check the bounds
        let load = match &self.bounded_fn {
            Some(name) => {
                let get_ptr = || {
                    let arr_ptr = match &self.address_type {
                        AddressType::Variable => producer.body_ctx().get_variable_array(producer),
                        AddressType::Signal => producer.template_ctx().get_signal_array(producer),
                        AddressType::SubcmpSignal { cmp_address, counter_override, .. } => {
                            let addr = cmp_address.produce_llvm_ir(producer)
                                .expect("The address of a subcomponent must yield a value!");
                            if *counter_override {
                                return producer.template_ctx().load_subcmp_counter(producer, addr, false).expect("could not find counter!")
                            } else {
                                let subcmp = producer.template_ctx().load_subcmp_addr(producer, addr);
                                create_gep(producer, subcmp, &[zero(producer)])
                            }
                        }
                    };
                    pointer_cast(producer, arr_ptr.into_pointer_value(), array_ptr_ty(producer))
                };
                create_call(producer, name.as_str(), &[get_ptr().into(), index.into()])
            },
            None => {
                let gep = match &self.address_type {
                    AddressType::Variable => producer.body_ctx().get_variable(producer, index).into_pointer_value(),
                    AddressType::Signal => producer.template_ctx().get_signal(producer, index).into_pointer_value(),
                    AddressType::SubcmpSignal { cmp_address, counter_override, ..  } => {
                        let addr = cmp_address.produce_llvm_ir(producer).expect("The address of a subcomponent must yield a value!");
                        if *counter_override {
                            producer.template_ctx().load_subcmp_counter(producer, addr, false).expect("could not find counter!")
                        } else {
                            producer.template_ctx().get_subcmp_signal(producer, addr, index).into_pointer_value()
                        }
                    }
                };
                create_load(producer, gep)
            },
        };
        Some(load)
    }
}

impl WriteWasm for LoadBucket {
    fn produce_wasm(&self, producer: &WASMProducer) -> Vec<String> {
        use code_producers::wasm_elements::wasm_code_generator::*;
        let mut instructions = vec![];
        if producer.needs_comments() {
            instructions.push(";; load bucket".to_string());
	}
        match &self.src {
            LocationRule::Indexed { location, .. } => {
                let mut instructions_src = location.produce_wasm(producer);
                instructions.append(&mut instructions_src);
                let size = producer.get_size_32_bits_in_memory() * 4;
                instructions.push(set_constant(&size.to_string()));
                instructions.push(mul32());
                match &self.address_type {
                    AddressType::Variable => {
                        instructions.push(get_local(producer.get_lvar_tag()).to_string());
                    }
                    AddressType::Signal => {
                        instructions.push(get_local(producer.get_signal_start_tag()).to_string());
                    }
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
                        instructions.push(set_constant(
                            &producer.get_signal_start_address_in_component().to_string(),
                        ));
                        instructions.push(add32());
                        instructions.push(load32(None)); //subcomponent start_of_signals
                    }
                }
                instructions.push(add32());
		if producer.needs_comments() {
                    instructions.push(";; end of load bucket".to_string());
		}
            }
            LocationRule::Mapped { signal_code, indexes } => {
                match &self.address_type {
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
                        instructions.push(set_local(producer.get_sub_cmp_load_tag()));
                        instructions.push(get_local(producer.get_sub_cmp_load_tag()));
                        instructions.push(load32(None)); // get template id                     A
                        instructions.push(set_constant("4")); //size in byte of i32
                        instructions.push(mul32());
                        instructions.push(load32(Some(
                            &producer.get_template_instance_to_io_signal_start().to_string(),
                        ))); // get position in component io signal to info list
                        let signal_code_in_bytes = signal_code * 4; //position in the list of the signal code
                        instructions.push(load32(Some(&signal_code_in_bytes.to_string()))); // get where the info of this signal is
                                                                                            //now we have first the offset and then the all size dimensions but the last one
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
                        instructions.push(get_local(producer.get_sub_cmp_load_tag()));
                        instructions.push(set_constant(
                            &producer.get_signal_start_address_in_component().to_string(),
                        ));
                        instructions.push(add32());
                        instructions.push(load32(None)); //subcomponent start_of_signals
                        instructions.push(add32()); // we get the position of the signal (with indexes) in memory
			if producer.needs_comments() {
                            instructions.push(";; end of load bucket".to_string());
			}
                    }
                    _ => {
                        assert!(false);
                    }
                }
            }
        }
        instructions
    }
}

impl WriteC for LoadBucket {
    fn produce_c(&self, producer: &CProducer, parallel: Option<bool>) -> (Vec<String>, String) {
        use c_code_generator::*;
        let mut prologue = vec![];
	//prologue.push(format!("// start of load line {} bucket {}",self.line.to_string(),self.to_string()));
	let cmp_index_ref;
        if let AddressType::SubcmpSignal { cmp_address, .. } = &self.address_type {
            let (mut cmp_prologue, cmp_index) = cmp_address.produce_c(producer, parallel);
            prologue.append(&mut cmp_prologue);
	    cmp_index_ref = cmp_index;
	} else {
            cmp_index_ref = "".to_string();
	}

        let (mut src_prologue, src_index) =
            if let LocationRule::Indexed { location, .. } = &self.src {
                location.produce_c(producer, parallel)
            } else if let LocationRule::Mapped { signal_code, indexes } = &self.src {
		let mut map_prologue = vec![];
		let sub_component_pos_in_memory = format!("{}[{}]",MY_SUBCOMPONENTS,cmp_index_ref.clone());
		let mut map_access = format!("{}->{}[{}].defs[{}].offset",
					     circom_calc_wit(), template_ins_2_io_info(),
					     template_id_in_component(sub_component_pos_in_memory.clone()),
					     signal_code.to_string());
		if indexes.len()>0 {
		    let (mut index_code_0, mut map_index) = indexes[0].produce_c(producer, parallel);
		    map_prologue.append(&mut index_code_0);
		    for i in 1..indexes.len() {
			let (mut index_code, index_exp) = indexes[i].produce_c(producer, parallel);
			map_prologue.append(&mut index_code);
			map_index = format!("({})*{}->{}[{}].defs[{}].lengths[{}]+{}",
					    map_index, circom_calc_wit(), template_ins_2_io_info(),
					    template_id_in_component(sub_component_pos_in_memory.clone()),
					    signal_code.to_string(), (i-1).to_string(),index_exp);
		    }
		    map_access = format!("{}+{}",map_access,map_index);
		}
                (map_prologue, map_access)
	    } else {
		assert!(false);
                (vec![], "".to_string())
	    };
        prologue.append(&mut src_prologue);
        let access = match &self.address_type {
            AddressType::Variable => {
                format!("&{}", lvar(src_index))
            }
            AddressType::Signal => {
                format!("&{}", signal_values(src_index))
            }
            AddressType::SubcmpSignal { uniform_parallel_value, is_output, .. } => {
		if *is_output {
            if uniform_parallel_value.is_some(){
                if uniform_parallel_value.unwrap(){
                    prologue.push(format!("{{"));
		            prologue.push(format!("int aux1 = {};",cmp_index_ref.clone()));
		            prologue.push(format!("int aux2 = {};",src_index.clone()));
		            prologue.push(format!(
                        "std::unique_lock<std::mutex> lk({}->componentMemory[{}[aux1]].mutexes[aux2]);",
                        CIRCOM_CALC_WIT, MY_SUBCOMPONENTS)
                    );
		            prologue.push(format!(
                        "{}->componentMemory[{}[aux1]].cvs[aux2].wait(lk, [{},{},aux1,aux2]() {{return {}->componentMemory[{}[aux1]].outputIsSet[aux2];}});",
			            CIRCOM_CALC_WIT, MY_SUBCOMPONENTS, CIRCOM_CALC_WIT,
			            MY_SUBCOMPONENTS, CIRCOM_CALC_WIT, MY_SUBCOMPONENTS)
                    );
		            prologue.push(format!("}}"));
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
                prologue.push(format!("{{"));
		        prologue.push(format!("int aux1 = {};",cmp_index_ref.clone()));
		        prologue.push(format!("int aux2 = {};",src_index.clone()));
		        prologue.push(format!(
                    "std::unique_lock<std::mutex> lk({}->componentMemory[{}[aux1]].mutexes[aux2]);",
                    CIRCOM_CALC_WIT, MY_SUBCOMPONENTS)
                );
	            prologue.push(format!(
                    "{}->componentMemory[{}[aux1]].cvs[aux2].wait(lk, [{},{},aux1,aux2]() {{return {}->componentMemory[{}[aux1]].outputIsSet[aux2];}});",
		            CIRCOM_CALC_WIT, MY_SUBCOMPONENTS, CIRCOM_CALC_WIT,
		            MY_SUBCOMPONENTS, CIRCOM_CALC_WIT, MY_SUBCOMPONENTS)
                );
		        prologue.push(format!("}}"));
                
                // end of case parallel, in case no parallel we do nothing

                prologue.push(format!("}}"));
            }
        }
                let sub_cmp_start = format!(
                    "{}->componentMemory[{}[{}]].signalStart",
                    CIRCOM_CALC_WIT, MY_SUBCOMPONENTS, cmp_index_ref
                );
		
                format!("&{}->signalValues[{} + {}]", CIRCOM_CALC_WIT, sub_cmp_start, src_index)
            }
        };
	//prologue.push(format!("// end of load line {} with access {}",self.line.to_string(),access));
        (prologue, access)
    }
}
