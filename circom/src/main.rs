mod compilation_user;
mod execution_user;
mod input_user;
mod parser_user;
mod type_analysis_user;

const VERSION: &'static str = env!("CARGO_PKG_VERSION");

use std::fs::File;
use std::io::Write;
use std::os::raw::c_void;
use llzk;
use melior;
use mlir_sys;

use ansi_term::Colour;
use input_user::Input;
fn main() {
    let result = start();
    if result.is_err() {
        eprintln!("{}", Colour::Red.paint("previous errors were found"));
        std::process::exit(1);
    } else {
        println!("{}", Colour::Green.paint("Everything went okay"));
        //std::process::exit(0);
    }
}

fn start() -> Result<(), ()> {
    use compilation_user::CompilerConfig;
    use execution_user::ExecutionConfig;
    let user_input = Input::new()?;
    let mut program_archive = parser_user::parse_project(&user_input)?;
    type_analysis_user::analyse_project(&mut program_archive)?;

    {
        //TODO: if LLZK output flag, do this block (and probably return w/o doing below)
        println!("{:#?}", program_archive); //TODO:TEMP

        let registry = melior::dialect::DialectRegistry::new();
        llzk::register_all_llzk_dialects(&registry);
        let context = melior::Context::new();
        let location = melior::ir::Location::unknown(&context);
        let module = llzk::dialect::module::llzk_module(location);

        let mut file = File::create("bytecode.llzk").unwrap();
        unsafe extern "C" fn callback(string_ref: mlir_sys::MlirStringRef, user_data: *mut c_void) {
            let file = &mut *(user_data as *mut File);
            let slice = std::slice::from_raw_parts(string_ref.data as *const u8, string_ref.length);
            let _ = file.write_all(slice); // TODO: handle error
        }

        unsafe {
            // mlir_sys::mlirOperationWriteBytecode(
            mlir_sys::mlirOperationPrint(
                module.as_operation().to_raw(),
                Some(callback),
                &mut file as *mut File as *mut c_void,
            );
        }
    }

    let config = ExecutionConfig {
        no_rounds: user_input.no_rounds(),
        flag_p: user_input.parallel_simplification_flag(),
        flag_s: user_input.reduced_simplification_flag(),
        flag_f: user_input.unsimplified_flag(),
        flag_old_heuristics: user_input.flag_old_heuristics(),
        flag_verbose: user_input.flag_verbose(),
        inspect_constraints_flag: user_input.inspect_constraints_flag(),
        r1cs_flag: user_input.r1cs_flag(),
        json_constraint_flag: user_input.json_constraints_flag(),
        json_substitution_flag: user_input.json_substitutions_flag(),
        sym_flag: user_input.sym_flag(),
        sym: user_input.sym_file().to_string(),
        r1cs: user_input.r1cs_file().to_string(),
        json_constraints: user_input.json_constraints_file().to_string(),
        json_substitutions: user_input.json_substitutions_file().to_string(),
        prime: user_input.prime(),        
    };
    let circuit = execution_user::execute_project(program_archive, config)?;
    let compilation_config = CompilerConfig {
        vcp: circuit,
        debug_output: user_input.print_ir_flag(),
        c_flag: user_input.c_flag(),
        wasm_flag: user_input.wasm_flag(),
        wat_flag: user_input.wat_flag(),
	    js_folder: user_input.js_folder().to_string(),
	    wasm_name: user_input.wasm_name().to_string(),
	    c_folder: user_input.c_folder().to_string(),
	    c_run_name: user_input.c_run_name().to_string(),
        c_file: user_input.c_file().to_string(),
        dat_file: user_input.dat_file().to_string(),
        wat_file: user_input.wat_file().to_string(),
        wasm_file: user_input.wasm_file().to_string(),
        produce_input_log: user_input.main_inputs_flag(),

        no_asm_flag: user_input.no_asm_flag(),
        constraint_assert_disabled_flag: user_input.constraint_assert_disabled_flag(),
        prime: user_input.prime(),        
    };
    compilation_user::compile(compilation_config)?;
    Result::Ok(())
}
