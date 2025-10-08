use std::{
    fs::{self, File},
    io::Write,
    os::raw::c_void,
    path::Path,
};
use ansi_term::Color;
use anyhow::Result;
use program_structure::{
    file_definition::{FileID, FileLibrary, FileLocation},
    program_archive::ProgramArchive,
};
use melior::{
    self,
    ir::{operation::OperationLike as _, Location, Module, ValueLike},
};
use llzk::prelude::LlzkContext;

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
    fn produce_llzk_ir<'b, 'a: 'b>(
        &'a self,
        codegen: &LlzkCodegen<'a, 'a>,
    ) -> Result<Box<dyn ValueLike<'a> + 'b>>;
}

impl ProduceLLZK for ProgramArchive {
    fn produce_llzk_ir<'b, 'a: 'b>(
        &'a self,
        codegen: &LlzkCodegen<'a, 'a>,
    ) -> Result<Box<dyn ValueLike<'a> + 'b>> {
        todo!("Not yet implemented")
    }
}

pub fn generate_llzk(program_archive: &ProgramArchive, filename: &str) -> Result<(), ()> {
    let ctx = LlzkContext::new();
    let codegen = LlzkCodegen::new(&ctx, program_archive);

    // TODO: uncomment when implemented
    // program_archive.produce_llzk_ir(&codegen).expect("Failed to generate LLZK IR");

    // Verify the module and write it to file
    assert!(codegen.verify());
    codegen.write_to_file(filename).expect("Failed to write LLZK code");

    return Result::Ok(());
}
