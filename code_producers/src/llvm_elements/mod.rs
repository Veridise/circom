use std::cell::RefCell;
use std::collections::{BTreeMap, HashMap, HashSet};
use std::convert::TryFrom;
use std::ops::Range;
use std::rc::Rc;

use ansi_term::Colour;

use inkwell::basic_block::BasicBlock;
use inkwell::builder::Builder;
use inkwell::context::{Context, ContextRef};
use inkwell::debug_info::{DebugInfoBuilder, DICompileUnit};
use inkwell::module::Module;
use inkwell::passes::PassManager;
use inkwell::types::{AnyTypeEnum, BasicType, BasicTypeEnum, IntType};
use inkwell::values::{ArrayValue, BasicMetadataValueEnum, BasicValueEnum};
pub use inkwell::types::AnyType;
pub use inkwell::values::{
    AnyValue, AnyValueEnum, FunctionValue, InstructionOpcode, IntValue, PointerValue,
};
pub use inkwell::debug_info::AsDIScope;
pub use inkwell::module::Linkage;

use program_structure::program_archive::ProgramArchive;

use crate::components::TemplateInstanceIOMap;

pub mod stdlib;
pub mod template;
pub mod types;
pub mod functions;
pub mod instructions;
pub mod fr;
pub mod values;
pub mod array_switch;

pub type LLVMInstruction<'a> = AnyValueEnum<'a>;
pub type LLVMValue<'a> = BasicMetadataValueEnum<'a>;
pub type DebugCtx<'a> = (DebugInfoBuilder<'a>, DICompileUnit<'a>);

#[derive(Copy, Clone, Eq, PartialEq, Ord, PartialOrd, Hash, Debug)]
pub enum ConstraintKind {
    Substitution,
    Equality,
}

pub trait BodyCtx<'a> {
    fn get_lvar_ref(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        index: IntValue<'a>,
    ) -> PointerValue<'a>;

    fn get_variable_array(&self, producer: &dyn LLVMIRProducer<'a>) -> PointerValue<'a>;

    fn get_wrapping_constraint(&self) -> Option<ConstraintKind>;
    fn set_wrapping_constraint(&self, value: Option<ConstraintKind>);
}

struct BaseBodyCtx<'a> {
    current_function: FunctionValue<'a>,

    // Flags below are wrapped in RefCell because the reference to
    // the context is immutable but we need mutability.
    inside_constraint: RefCell<Option<ConstraintKind>>,
}

impl<'a> BaseBodyCtx<'a> {
    fn new(current_function: FunctionValue<'a>) -> Self {
        BaseBodyCtx { current_function, inside_constraint: Default::default() }
    }

    fn get_wrapping_constraint(&self) -> Option<ConstraintKind> {
        *self.inside_constraint.borrow()
    }

    fn set_wrapping_constraint(&self, value: Option<ConstraintKind>) {
        self.inside_constraint.replace(value);
    }
}

pub trait TemplateCtx<'a>: BodyCtx<'a> {
    /// Returns the memory address of the subcomponent
    fn load_subcmp(&self, producer: &dyn LLVMIRProducer<'a>, id: LLVMValue<'a>)
        -> PointerValue<'a>;

    /// Creates the necessary code to load a subcomponent given the expression used as id
    fn load_subcmp_addr(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        id: LLVMValue<'a>,
    ) -> PointerValue<'a>;

    /// Creates the necessary code to load a subcomponent counter given the expression used as id
    fn load_subcmp_counter(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        id: LLVMValue<'a>,
        implicit: bool,
    ) -> Option<PointerValue<'a>>;

    /// Returns a pointer to the signal associated to given subcomponent id and index
    fn get_subcmp_signal(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        subcmp_id: LLVMValue<'a>,
        index: IntValue<'a>,
    ) -> PointerValue<'a>;

    /// Returns a pointer to the signal associated to the index
    fn get_signal_ref(
        &self,
        producer: &dyn LLVMIRProducer<'a>,
        index: IntValue<'a>,
    ) -> PointerValue<'a>;

    /// Returns a pointer to the signal array
    fn get_signal_array(&self, producer: &dyn LLVMIRProducer<'a>) -> PointerValue<'a>;
}

pub trait LLVMIRProducer<'a> {
    fn llvm(&self) -> &LLVM<'a>;
    fn set_current_bb(&self, bb: BasicBlock<'a>);
    fn template_ctx(&self) -> &dyn TemplateCtx<'a>;
    fn body_ctx(&self) -> &dyn BodyCtx<'a>;
    fn current_function(&self) -> FunctionValue<'a>;
    fn get_ff_constants(&self) -> &Vec<String>;
    fn get_template_mem_arg(&self, run_fn: FunctionValue<'a>) -> ArrayValue<'a>;
    fn get_main_template_header(&self) -> &String;
}

// Uses BTreeMap so the maximum key (i.e. local index) can be obtained easily
pub type IndexMapping = BTreeMap<usize, Range<usize>>;

#[derive(Default, Eq, PartialEq, Debug)]
pub struct LLVMCircuitData {
    pub main_header: String,
    pub ff_constants: Vec<String>,
    pub io_map: TemplateInstanceIOMap,
    pub signal_index_mapping: HashMap<String, IndexMapping>,
    pub variable_index_mapping: HashMap<String, IndexMapping>,
    pub component_index_mapping: HashMap<String, IndexMapping>,
    pub bounded_array_loads: HashSet<Range<usize>>,
    pub bounded_array_stores: HashSet<Range<usize>>,
}

impl LLVMCircuitData {
    pub fn clone_with_updates(
        &self,
        ff_constants: Vec<String>,
        variable_index_mapping: HashMap<String, IndexMapping>,
        array_loads: HashSet<Range<usize>>,
        array_stores: HashSet<Range<usize>>,
    ) -> Self {
        LLVMCircuitData {
            main_header: self.main_header.clone(),
            ff_constants,
            io_map: self.io_map.clone(),
            signal_index_mapping: self.signal_index_mapping.clone(),
            variable_index_mapping,
            component_index_mapping: self.component_index_mapping.clone(),
            bounded_array_loads: array_loads,
            bounded_array_stores: array_stores,
        }
    }
}

pub struct TopLevelLLVMIRProducer<'a> {
    current_module: LLVM<'a>,
    ff_constants: Vec<String>,
    main_template_header: String,
}

impl<'a> LLVMIRProducer<'a> for TopLevelLLVMIRProducer<'a> {
    fn llvm(&self) -> &LLVM<'a> {
        &self.current_module
    }

    fn set_current_bb(&self, bb: BasicBlock<'a>) {
        self.llvm().builder.position_at_end(bb);
    }

    fn template_ctx(&self) -> &dyn TemplateCtx<'a> {
        panic!("The top level llvm producer does not hold a template context!");
    }

    fn body_ctx(&self) -> &dyn BodyCtx<'a> {
        panic!("The top level llvm producer does not hold a body context!");
    }

    fn current_function(&self) -> FunctionValue<'a> {
        panic!("The top level llvm producer does not have a current function");
    }

    fn get_ff_constants(&self) -> &Vec<String> {
        &self.ff_constants
    }

    fn get_template_mem_arg(&self, _run_fn: FunctionValue<'a>) -> ArrayValue<'a> {
        panic!(
            "The top level llvm producer can't extract the template argument of a run function!"
        );
    }

    fn get_main_template_header(&self) -> &String {
        &self.main_template_header
    }
}

impl<'a> TopLevelLLVMIRProducer<'a> {
    pub fn write_to_file(&self, path: &str) -> Result<(), ()> {
        self.current_module.write_to_file(path)
    }
}

#[inline]
pub fn create_context() -> Context {
    Context::create()
}

impl<'a> TopLevelLLVMIRProducer<'a> {
    pub fn new(
        context: &'a Context,
        program_archive: &ProgramArchive,
        llvm_path: &str,
        ff_constants: Vec<String>,
        main_template_header: String,
    ) -> Self {
        TopLevelLLVMIRProducer {
            current_module: LLVM::from_context(context, program_archive, llvm_path),
            ff_constants,
            main_template_header,
        }
    }
}

pub type LLVMAdapter<'a> = &'a Rc<RefCell<LLVM<'a>>>;
pub type BigIntType<'a> = IntType<'a>; // i256

#[inline]
#[must_use]
pub fn any_value_wraps_basic_value(v: AnyValueEnum) -> bool {
    BasicValueEnum::try_from(v).is_ok()
}

#[inline]
#[must_use]
pub fn any_value_to_basic(v: AnyValueEnum) -> BasicValueEnum {
    BasicValueEnum::try_from(v).expect("Attempted to convert a non basic value!")
}

#[inline]
#[must_use]
pub fn to_enum<'a, T: AnyValue<'a>>(v: T) -> AnyValueEnum<'a> {
    v.as_any_value_enum()
}

#[inline]
#[must_use]
pub fn to_basic_enum<'a, T: AnyValue<'a>>(v: T) -> BasicValueEnum<'a> {
    any_value_to_basic(to_enum(v))
}

#[inline]
#[must_use]
pub fn to_basic_metadata_enum(value: AnyValueEnum) -> BasicMetadataValueEnum {
    BasicMetadataValueEnum::try_from(value)
        .expect("Attempted to convert a value that is not basic or metadata")
}

#[inline]
#[must_use]
pub fn to_basic_metadata_enum_opt(value: AnyValueEnum) -> Option<BasicMetadataValueEnum> {
    BasicMetadataValueEnum::try_from(value).ok()
}

#[inline]
#[must_use]
pub fn to_type_enum<'a, T: AnyType<'a>>(ty: T) -> AnyTypeEnum<'a> {
    ty.as_any_type_enum()
}

#[inline]
#[must_use]
pub fn to_basic_type_enum<'a, T: BasicType<'a>>(ty: T) -> BasicTypeEnum<'a> {
    ty.as_basic_type_enum()
}

pub struct LLVM<'a> {
    module: Module<'a>,
    pub builder: Builder<'a>,
    debug: HashMap<usize, DebugCtx<'a>>, //indexed by file_id
}

impl<'a> LLVM<'a> {
    pub fn from_context(
        context: &'a Context,
        program_archive: &ProgramArchive,
        out_path: &str,
    ) -> Self {
        let m = context.create_module(out_path);
        m.add_basic_value_flag(
            "Debug Info Version",
            inkwell::module::FlagBehavior::Warning,
            context.i32_type().const_int(3, false),
        );
        //Pre-populate debug map
        let files = &program_archive.file_library;
        let mut map_id_to_name = HashMap::new();
        for f in &program_archive.functions {
            let id = f.1.get_file_id();
            let name = files.get_filename_or_default(&id);
            let old = map_id_to_name.insert(id, name);
            //ASSERT: possible existing value must be the same as was inserted
            assert!(old.is_none() || old.unwrap() == files.get_filename_or_default(&id));
        }
        for t in &program_archive.templates {
            let id = t.1.get_file_id();
            let name = files.get_filename_or_default(&id);
            let old = map_id_to_name.insert(id, name);
            //ASSERT: possible existing value must be the same as was inserted
            assert!(old.is_none() || old.unwrap() == files.get_filename_or_default(&id));
        }
        let mut debug_info = HashMap::new();
        for pair in map_id_to_name {
            let path = pair.1;
            //Split the file path into directory and file name. If there is no path
            //  separator, the entire thing is used as the file name and dir is empty.
            let (dir, name) =
                path.split_at(path.rfind(std::path::MAIN_SEPARATOR).map_or(0, |x| x + 1));
            //Create and store the new DebugCtx
            let res = m.create_debug_info_builder(
                true,
                inkwell::debug_info::DWARFSourceLanguage::C11,
                name,
                dir,
                "circom-to-llvm frontend",
                false,
                "",
                0,
                "",
                inkwell::debug_info::DWARFEmissionKind::LineTablesOnly,
                0,
                true,
                false,
                "",
                "llvm13-0",
            );
            debug_info.insert(pair.0, res);
        }
        LLVM { module: m, builder: context.create_builder(), debug: debug_info }
    }

    pub fn context(&self) -> ContextRef<'a> {
        self.module.get_context()
    }

    pub fn get_debug_info(&self, file_id: &usize) -> Result<&DebugCtx, String> {
        self.debug
            .get(file_id)
            .ok_or_else(|| format!("Could not find debug info for file with ID={}", file_id))
    }

    pub fn write_to_file(&self, path: &str) -> Result<(), ()> {
        // Run LLVM IR inliner for the FR_IDENTITY_* and FR_INDEX_ARR_PTR functions
        let pm = PassManager::create(());
        pm.add_always_inliner_pass();
        pm.add_merge_functions_pass();
        pm.add_global_dce_pass();
        pm.run_on(&self.module);

        // Must finalize all debug info before running the verifier
        for dbg in self.debug.values() {
            dbg.0.finalize();
        }
        // Run module verification
        self.module.verify().map_err(|llvm_err| {
            self.dump_module_to_stderr();
            eprintln!(
                "{}: {}",
                Colour::Red.paint("LLVM Module verification failed"),
                llvm_err.to_string()
            );
        })?;
        // Verify that bitcode can be written, parsed, and re-verified
        {
            let buff = self.module.write_bitcode_to_memory();
            let context = create_context();
            let new_module =
                Module::parse_bitcode_from_buffer(&buff, &context).map_err(|llvm_err| {
                    eprintln!(
                        "{}: {}",
                        Colour::Red.paint("Parsing LLVM bitcode from verification buffer failed"),
                        llvm_err.to_string()
                    );
                })?;
            new_module.verify().map_err(|llvm_err| {
                eprintln!(
                    "{}: {}",
                    Colour::Red.paint("LLVM bitcode verification failed"),
                    llvm_err.to_string()
                );
            })?;
        }
        // Write the output to file
        self.module.print_to_file(path).map_err(|llvm_err| {
            eprintln!(
                "{}: {}",
                Colour::Red.paint("Writing LLVM Module failed"),
                llvm_err.to_string()
            );
        })
    }

    pub fn dump_module_to_stderr(&self) {
        eprintln!("Generated LLVM:");
        self.module.print_to_stderr();
    }
}

#[inline]
pub fn run_fn_name(name: String) -> String {
    format!("{}_run", name)
}

#[inline]
pub fn build_fn_name(name: String) -> String {
    format!("{}_build", name)
}
