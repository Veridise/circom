use std::path::Path;
use ansi_term::Colour;
use circuit_passes::passes::PassManager;
use compiler::compiler_interface::{self, Circuit, Config, VCP};
use program_structure::error_definition::Report;
use program_structure::error_code::ReportCode;
use program_structure::file_definition::FileLibrary;
use program_structure::program_archive::ProgramArchive;
use crate::VERSION;

pub struct CompilerConfig {
    pub js_folder: String,
    pub wasm_name: String,
    pub wat_file: String,
    pub wasm_file: String,
    pub c_folder: String,
    pub c_run_name: String,
    pub c_file: String,
    pub llvm_file: String,
    pub llvm_folder: String,
    pub summary_file: String,
    pub summary_flag: bool,
    pub dat_file: String,
    pub wat_flag: bool,
    pub wasm_flag: bool,
    pub c_flag: bool,
    pub llvm_flag: bool,
    pub debug_output: bool,
    pub produce_input_log: bool,
    pub vcp: VCP,
}

pub fn compile(config: CompilerConfig, program_archive: ProgramArchive, prime: &String) -> Result<(), ()> {
    let circuit = compiler_interface::run_compiler(
        config.vcp,
        Config {
            debug_output: config.debug_output,
            produce_input_log: config.produce_input_log,
            wat_flag: config.wat_flag,
            summary_flag: config.summary_flag,
        },
        VERSION,
    )?;

    if config.c_flag {
        compiler_interface::write_c(&circuit, &config.c_folder, &config.c_run_name, &config.c_file, &config.dat_file)?;
        println!(
            "{} {} and {}",
            Colour::Green.paint("Written successfully:"),
            config.c_file,
            config.dat_file
        );
        println!(
            "{} {}/{}, {}, {}, {}, {}, {}, {} and {}",
            Colour::Green.paint("Written successfully:"),
            &config.c_folder,
            "main.cpp".to_string(),
            "circom.hpp".to_string(),
            "calcwit.hpp".to_string(),
            "calcwit.cpp".to_string(),
            "fr.hpp".to_string(),
            "fr.cpp".to_string(),
            "fr.asm".to_string(),
            "Makefile".to_string()
        );
    }

    match (config.wat_flag, config.wasm_flag) {
        (true, true) => {
            compiler_interface::write_wasm(&circuit, &config.js_folder, &config.wasm_name, &config.wat_file)?;
            println!("{} {}", Colour::Green.paint("Written successfully:"), config.wat_file);
            let result = wat_to_wasm(&config.wat_file, &config.wasm_file);
            match result {
                Result::Err(report) => {
                    Report::print_reports(&[report], &FileLibrary::new());
                    return Err(());
                }
                Result::Ok(()) => {
                    println!("{} {}", Colour::Green.paint("Written successfully:"), config.wasm_file);
                }
            }
        }
        (false, true) => {
            compiler_interface::write_wasm(&circuit,  &config.js_folder, &config.wasm_name, &config.wat_file)?;
            let result = wat_to_wasm(&config.wat_file, &config.wasm_file);
            std::fs::remove_file(&config.wat_file).unwrap();
            match result {
                Result::Err(report) => {
                    Report::print_reports(&[report], &FileLibrary::new());
                    return Err(());
                }
                Result::Ok(()) => {
                    println!("{} {}", Colour::Green.paint("Written successfully:"), config.wasm_file);
                }
            }
        }
        (true, false) => {
            compiler_interface::write_wasm(&circuit,  &config.js_folder, &config.wasm_name, &config.wat_file)?;
            println!("{} {}", Colour::Green.paint("Written successfully:"), config.wat_file);
        }
        (false, false) => {}
    }

    if config.summary_flag {
        generate_summary(config.summary_file.as_str(), config.llvm_folder.as_str(), &circuit, prime)?;
    }

    if config.llvm_flag {
        // Only run the passes if we are going to generate LLVM code
        let pm = PassManager::new();
        let result = pm
            .schedule_const_arg_deduplication_pass()
            .schedule_loop_unroll_pass()
            .schedule_conditional_flattening_pass()
            .schedule_unused_function_removal_pass() //previous 2 passes create the dead functions
            .schedule_mapped_to_indexed_pass()
            .schedule_unknown_index_sanitization_pass()
            .schedule_simplification_pass()
            .schedule_deterministic_subcmp_invoke_pass()
            .transform_circuit(circuit, prime);
        match result {
            Result::Err(e) => {
                let report = e.to_report(&program_archive.file_library);
                Report::print_reports(&[report], &program_archive.file_library);
                return Err(());
            }
            Result::Ok(circuit) => {
                compiler_interface::write_llvm_ir(
                    &circuit,
                    &program_archive,
                    &config.llvm_folder,
                    &config.llvm_file,
                    !config.summary_flag, // If we generate the summary then the llvm folder is prepared at that step
                )?;
                println!("{} {}", Colour::Green.paint("Written successfully:"), config.llvm_file);
            }
        }
    }

    Ok(())
}

fn generate_summary(summary_file: &str, llvm_folder: &str, circuit: &Circuit, prime: &String) -> Result<(), ()> {
    if Path::new(llvm_folder).is_dir() {
        std::fs::remove_dir_all(llvm_folder).map_err(|err| {
            eprintln!("{} {}", Colour::Red.paint("Could not write the output in the given path:"), err);
            ()
        })?;
    }
    std::fs::create_dir(llvm_folder).map_err(|err| {
        eprintln!("{} {}", Colour::Red.paint("Could not write the output in the given path:"), err);
        ()
    })?;
    match circuit.summary_producer.write_to_file(summary_file, prime) {
        Err(err) => {
            eprintln!("{} {}", Colour::Red.paint("Could not write the output in the given path:"), err);
            Err(())
        }
        Ok(()) => {
            println!("{} {}", Colour::Green.paint("Written summary successfully:"), summary_file);
            Ok(())
        }
    }
}

fn wat_to_wasm(wat_file: &str, wasm_file: &str) -> Result<(), Report> {
    use std::fs::read_to_string;
    use std::fs::File;
    use std::io::BufWriter;
    use std::io::Write;
    use wast::Wat;
    use wast::parser::{self, ParseBuffer};

    let wat_contents = read_to_string(wat_file).unwrap();
    let buf = ParseBuffer::new(&wat_contents).unwrap();
    let result_wasm_contents = parser::parse::<Wat>(&buf);
    match result_wasm_contents {
        Result::Err(error) => {
            Result::Err(Report::error(
                format!("Error translating the circuit from wat to wasm.\n\nException encountered when parsing WAT: {}", error),
                ReportCode::ErrorWat2Wasm,
            ))
        }
        Result::Ok(mut wat) => {
            let wasm_contents = wat.module.encode();
            match wasm_contents {
                Result::Err(error) => {
                    Result::Err(Report::error(
                        format!("Error translating the circuit from wat to wasm.\n\nException encountered when encoding WASM: {}", error),
                        ReportCode::ErrorWat2Wasm,
                    ))
                }
                Result::Ok(wasm_contents) => {
                    let file = File::create(wasm_file).unwrap();
                    let mut writer = BufWriter::new(file);
                    writer.write_all(&wasm_contents).map_err(|_err| Report::error(
                        format!("Error writing the circuit. Exception generated: {}", _err),
                        ReportCode::ErrorWat2Wasm,
                    ))?;
                    writer.flush().map_err(|_err| Report::error(
                        format!("Error writing the circuit. Exception generated: {}", _err),
                        ReportCode::ErrorWat2Wasm,
                    ))?;
                    Ok(())
                }
            }
        }
    }
}
