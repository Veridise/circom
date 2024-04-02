use std::io::Write;
use code_producers::c_elements::*;
use code_producers::llvm_elements::*;
use code_producers::wasm_elements::*;
use program_structure::program_archive::ProgramArchive;
use crate::intermediate_representation::ir_interface::ObtainMeta;

pub trait WriteC {
    /*
        returns (x, y) where:
            x: c instructions produced.
            y: if the instructions in x compute some value, that value is stored in y.
    */
    fn produce_c(&self, producer: &CProducer, is_parallel: Option<bool>) -> (Vec<String>, String);
    fn write_c<T: Write>(&self, writer: &mut T, producer: &CProducer) -> Result<(), ()> {
        use code_producers::wasm_elements::wasm_code_generator::merge_code;
        let (c_instructions, _) = self.produce_c(producer, None);
        let code = merge_code(c_instructions);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})
    }
}

pub trait WriteWasm {
    fn produce_wasm(&self, producer: &WASMProducer) -> Vec<String>;
    fn write_wasm<T: Write>(&self, writer: &mut T, producer: &WASMProducer) -> Result<(), ()> {
        let wasm_instructions = self.produce_wasm(producer);
        let code = wasm_code_generator::merge_code(wasm_instructions);
        writer.write_all(code.as_bytes()).map_err(|_| {})?;
        writer.flush().map_err(|_| {})
    }
}

pub trait WriteLLVMIR {
    /// This must always return the final statement in the current BasicBlock or None if empty.
    fn produce_llvm_ir<'a>(&self, producer: &dyn LLVMIRProducer<'a>)
        -> Option<LLVMInstruction<'a>>;

    fn write_llvm_ir(
        &self,
        program_archive: &ProgramArchive,
        out_path: &str,
        data: &LLVMCircuitData,
    ) -> Result<(), ()> {
        let context = create_context();
        let top_level = TopLevelLLVMIRProducer::new(
            &context,
            program_archive,
            out_path,
            data.field_tracking.clone(),
            data.main_header.clone(),
        );
        self.produce_llvm_ir(&top_level);
        top_level.write_to_file(out_path)
    }

    fn manage_debug_loc_from_curr<'a, 'b>(
        producer: &'b (impl LLVMIRProducer<'a> + ?Sized),
        obj: &dyn ObtainMeta,
    ) {
        Self::manage_debug_loc(producer, obj, || producer.current_function())
    }

    fn manage_debug_loc<'a, 'b>(
        producer: &'b (impl LLVMIRProducer<'a> + ?Sized),
        obj: &dyn ObtainMeta,
        get_current: impl Fn() -> FunctionValue<'a>,
    ) {
        match obj.get_source_file_id().and_then(|i| producer.llvm().get_debug_info(&i).ok()) {
            // Set active debug location based on the ObtainMeta location information
            Some((dib, _)) => producer.llvm().builder.set_current_debug_location(
                dib.create_debug_location(
                    producer.llvm().context(),
                    obj.get_line() as u32,
                    0,
                    get_current()
                        .get_subprogram()
                        .expect("Couldn't find debug info for containing method!")
                        .as_debug_info_scope(),
                    None,
                ),
            ),
            // Clear active debug location if no associated file or no DebugInfo for that file
            None => producer.llvm().builder.unset_current_debug_location(),
        };
    }
}
