use std::{
    convert::TryInto as _,
    fs::{self, File},
    io::Write,
    os::raw::c_void,
    path::Path,
};
use ansi_term::Color;
use anyhow::{Result, anyhow};
use program_structure::{
    file_definition::{FileID, FileLibrary, FileLocation},
    function_data::FunctionData,
    program_archive::ProgramArchive,
    template_data::TemplateData,
};
use melior::{
    self,
    ir::{operation::OperationLike as _, Block, BlockLike, Location, Module, RegionLike as _},
};
use llzk::{
    dialect::r#struct,
    prelude::{
        r#struct::helpers::{compute_fn, constrain_fn},
        LlzkContext, StructDefOp, StructDefOpLike as _, StructDefOpRef, StructDefOpRefMut,
    },
};

pub struct LlzkCodegen<'c, 'a> {
    files: &'a FileLibrary,
    context: &'c LlzkContext,
    module: Module<'c>,
}

impl<'c, 'a> LlzkCodegen<'c, 'a> {
    pub fn new(context: &'c LlzkContext, program_archive: &'a ProgramArchive) -> Self {
        let files = &program_archive.file_library;
        let filename = files.get_filename_or_default(program_archive.get_file_id_main());
        let main_file_location = Location::new(&context, &filename, 0, 0);
        let module = llzk::dialect::module::llzk_module(main_file_location);
        Self { files, context, module }
    }

    pub fn get_location(&self, file_id: FileID, file_location: FileLocation) -> Location<'c> {
        let filename = self.files.get_filename_or_default(&file_id);
        let line = self.files.get_line(file_location.start, file_id).unwrap_or(0);
        let column = self.files.get_column(file_location.start, file_id).unwrap_or(0);
        Location::new(&self.context, &filename, line, column)
    }

    pub fn add_struct(&self, s: StructDefOp<'c>) -> Result<StructDefOpRefMut<'c, 'c>> {
        let s: StructDefOpRef = self.module.body().append_operation(s.into()).try_into()?;
        Ok(unsafe { StructDefOpRefMut::from_raw(s.to_raw()) })
    }

    pub fn verify(&self) -> bool {
        self.module.as_operation().verify()
    }

    pub fn write_to_file(&self, filename: &str) -> Result<(), ()> {
        let out_path = Path::new(filename);
        // Ensure parent directories exist
        if let Some(parent) = out_path.parent() {
            fs::create_dir_all(parent).map_err(|_err| {})?;
        }
        let mut file = File::create(out_path).map_err(|_err| {})?;

        unsafe extern "C" fn callback(string_ref: mlir_sys::MlirStringRef, user_data: *mut c_void) {
            let file = &mut *(user_data as *mut File);
            let slice = std::slice::from_raw_parts(string_ref.data as *const u8, string_ref.length);
            let _ = file.write_all(slice).unwrap();
        }

        unsafe {
            // TODO: may need to switch to bytecode at some point. Or add an option for it.
            // mlir_sys::mlirOperationWriteBytecode(
            mlir_sys::mlirOperationPrint(
                self.module.as_operation().to_raw(),
                Some(callback),
                &mut file as *mut File as *mut c_void,
            );
        }
        println!("{} {}", Color::Green.paint("Written successfully:"), filename);
        Result::Ok(())
    }
}

pub trait ProduceLLZK {
    /// This should return the value produced or None for instruction-like nodes that produce no value
    fn produce_llzk_ir(&self, codegen: &LlzkCodegen) -> Result<bool>;
}

impl ProduceLLZK for ProgramArchive {
    fn produce_llzk_ir(&self, codegen: &LlzkCodegen) -> Result<bool> {
        for (_, data) in &self.functions {
            data.produce_llzk_ir(codegen)?;
        }
        for (_, data) in &self.templates {
            data.produce_llzk_ir(codegen)?;
        }
        Result::Ok(true)
    }
}

impl ProduceLLZK for FunctionData {
    fn produce_llzk_ir(&self, codegen: &LlzkCodegen) -> Result<bool> {
        println!("Processing function: {:#?}", self);
        todo!()
    }
}

impl ProduceLLZK for TemplateData {
    fn produce_llzk_ir(&self, codegen: &LlzkCodegen) -> Result<bool> {
        let loc = codegen.get_location(self.get_file_id(), self.get_param_location());
        let new_struct =
            codegen.add_struct(r#struct::def(loc, self.get_name(), &["A", "B"], [])?)?;

        let new_struct_type = new_struct.r#type();

        let compute_fn = compute_fn(loc, new_struct_type, &[], None)?;
        let constrain_fn = constrain_fn(loc, new_struct_type, &[], None)?;

        let block = new_struct.region(0)?.first_block().expect("missing struct body Block");
        block.append_operation(compute_fn.into());
        block.append_operation(constrain_fn.into());

        return Result::Ok(true); //TODO:not sure what needs to be returned yet. Was a Value in LLVM backend.
    }
}

// Example usage:
// let index_type = Type::index(&context);
// module.body().append_operation(func::func(
//     &context,
//     StringAttribute::new(&context, "add"),
//     TypeAttribute::new(
//         FunctionType::new(&context, &[index_type, index_type], &[index_type]).into(),
//     ),
//     {
//         let block = Block::new(&[(index_type, location), (index_type, location)]);
//
//         let sum = block
//             .append_operation(arith::addi(
//                 block.argument(0).unwrap().into(),
//                 block.argument(1).unwrap().into(),
//                 location,
//             ))
//             .result(0)
//             .unwrap();
//
//         block.append_operation(func::r#return(&[sum.into()], location));
//
//         let region = Region::new();
//         region.append_block(block);
//         region
//     },
//     &[],
//     location,
// ));
pub fn generate_llzk(program_archive: &ProgramArchive, filename: &str) -> Result<(), ()> {
    //General outline of the ProgramArchive structure:
    //  .functions: maps function name to FunctionData
    //    - function name, param names, location, and body Statement
    //  .templates: maps template name to TemplateData
    //    - function name, param names, location, input/output WireInfo, and body Statement
    //      - WireInfo maps wire name to WireData
    //        - WireData has type (Signal or Bus), dimension, and TagInfo
    //  .initial_template_call: the entry point (i.e. callee of Main)

    let ctx = LlzkContext::new();
    let codegen = LlzkCodegen::new(&ctx, program_archive);

    program_archive.produce_llzk_ir(&codegen).expect("Failed to generate LLZK IR");

    // Verify the module and write it to file
    assert!(codegen.verify());
    codegen.write_to_file(filename).expect("Failed to write LLZK code");

    return Result::Ok(());
}
