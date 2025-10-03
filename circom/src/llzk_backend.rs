use std::{
    fs::{self, File},
    io::Write,
    os::raw::c_void,
    path::Path,
};
use ansi_term::Color;
use melior::{
    self,
    dialect::DialectRegistry,
    ir::{operation::OperationLike, Location, Module},
    Context,
};
use program_structure::program_archive::ProgramArchive;

pub fn generate_llzk(program_archive: &ProgramArchive, filename: &str) -> Result<(), ()> {
    let registry = DialectRegistry::new();
    llzk::register_all_llzk_dialects(&registry);
    let context = Context::new();

    let main_file_name = program_archive
        .get_file_library()
        .get_filename_or_default(program_archive.get_file_id_main());
    let main_file_location = Location::new(&context, &main_file_name, 0, 0);
    let root_module: Module = llzk::dialect::module::llzk_module(main_file_location);

    //TODO: build the LLZK module from the ProgramArchive

    // Verify the module and write it to file
    assert!(root_module.as_operation().verify());
    write_module_to_file(root_module, filename).expect("Failed to write LLZK code");

    return Result::Ok(());
}

fn write_module_to_file(module: Module, filename: &str) -> Result<(), ()> {
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
            module.as_operation().to_raw(),
            Some(callback),
            &mut file as *mut File as *mut c_void,
        );
    }
    println!("{} {}", Color::Green.paint("Written successfully:"), filename);
    Result::Ok(())
}
