mod call_unroll_tree;
mod index_map_ord;
mod loop_env_recorder;
mod extracted_location_updater;
mod map_like_trait;
mod observer;
pub mod body_extractor;

use std::cell::{Ref, RefCell, RefMut};
use std::collections::{BTreeMap, HashMap};
use call_unroll_tree::{Node, NodeRef};
use code_producers::llvm_elements::fr;
use code_producers::llvm_elements::stdlib::GENERATED_FN_PREFIX;
use compiler::circuit_design::function::FunctionCode;
use compiler::circuit_design::template::{TemplateCode, TemplateCodeInfo};
use compiler::compiler_interface::Circuit;
use compiler::intermediate_representation::{ir_interface::*, new_id, BucketId};
use index_map_ord::IndexMapOrd;
use indexmap::IndexMap;
use observer::{LoopUnrollObserver, LoopUnrollObserverResult};
use crate::bucket_interpreter::env::LibraryAccess;
use crate::bucket_interpreter::error::BadInterp;
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::value::Value;
use crate::{checked_insert, default__get_mem, default__name};
use super::{CircuitTransformationPass, GlobalPassData};
use self::body_extractor::LoopBodyExtractor;

const EXTRACT_LOOP_BODY_TO_NEW_FUNC: bool = true;
const UNROLLED_BUCKET_LABEL: &str = "unrolled_loop";

const DEBUG_LOOP_UNROLL: bool = false;

pub const LOOP_BODY_FN_PREFIX: &str = const_format::concatcp!(GENERATED_FN_PREFIX, "loop.body.");

pub(crate) type FuncArgIdx = usize;
pub(crate) type AddressOffset = usize;
pub(crate) type UnrolledIterLvars = BTreeMap<usize, Value>;
pub(crate) type CompiledMemLocation = (AddressType, AddressOffset);
pub(crate) type ToOriginalLocation = HashMap<FuncArgIdx, CompiledMemLocation>;

type CallBucketId = BucketId;
type LoopBucketId = BucketId;
type BlockBucketId = BucketId;
/// Table structure indexed first by load/store/call BucketId, then by iteration number
/// (i.e. the Vec index), containing the compiled memory locations to use as arguments
/// when calling the extracted body function.
// NOTE: This collection and several intermediate collections that are used to build it
// must use IndexMap/IndexSet to preserve insertion order to stabilize lit test output.
type MemLocsPerIter = IndexMapOrd<BucketId, Vec<Option<CompiledMemLocation>>>;
/// Extracted function name + compiled memory location mappings for the args.
type ExtractedNameAndMemLocs = (String, MemLocsPerIter);

// Some fields wrapped in a RefCell because the reference to the static analysis is immutable but we need mutability
pub struct LoopUnrollPass<'d> {
    global_data: &'d RefCell<GlobalPassData>,
    memory: PassMemory,
    /// Observer creates extracted functions then transformer references and stores them.
    extractor: LoopBodyExtractor,
    ///
    observer_result: RefCell<Option<LoopUnrollObserverResult>>,
    /// Maps CallBucket symbol (i.e. target function name) plus a mapping of LoopBucket IDs to
    /// iteration counts to the new function that has loops unrolled according to that mapping.
    /// Uses IndexMap to ensure consistent ordering of functions in the output (for lit tests).
    transformed_functions: RefCell<IndexMap<String, IndexMap<NodeRef, FunctionCode>>>,
    /// The chain of CallBucket that compose the current calling context for the transformer.
    current_ctx_chain: RefCell<Vec<CallBucketId>>,
    /// Track pending calls to cached_transform_function() to prevent stack overflow.
    /// The key is original function name plus the context subtree and value is new name.
    pending_transform_function: RefCell<HashMap<(String, NodeRef), String>>,
}

impl<'d> LoopUnrollPass<'d> {
    pub fn new(prime: String, global_data: &'d RefCell<GlobalPassData>) -> Self {
        LoopUnrollPass {
            global_data,
            memory: PassMemory::new(prime),
            extractor: Default::default(),
            observer_result: Default::default(),
            transformed_functions: Default::default(),
            current_ctx_chain: Default::default(),
            pending_transform_function: Default::default(),
        }
    }
}

impl LoopUnrollPass<'_> {
    #[inline]
    fn borrow_observer_result(&self) -> Ref<LoopUnrollObserverResult> {
        Ref::map(self.observer_result.borrow(), |o| {
            o.as_ref().expect("must have result from running template")
        })
    }

    #[inline]
    fn get_function(&self, name: &String) -> Ref<FunctionCode> {
        if name.starts_with(LOOP_BODY_FN_PREFIX) {
            self.extractor.search_new_functions(name)
        } else {
            self.memory.get_function(name)
        }
    }

    fn cached_transform_function(
        &self,
        target: &String,
        key: NodeRef,
    ) -> Result<String, BadInterp> {
        // No transformation of built-in functions.
        if fr::is_builtin_function(target) {
            return Ok(target.clone());
        }
        if DEBUG_LOOP_UNROLL {
            println!("[UNROLL][cached_transform_function] {} + {:?}", target, key);
        }

        // Although it seems logical to just borrow the map once here and hold until
        // the end where a new entry may be cached, that could result in BorrowMutError
        // because transform_function() below can recurse back to here. So just check
        // for an existing entry and get its name without holding a Ref.
        let cached_new_target = self
            .transformed_functions
            .borrow()
            .get(target)
            .and_then(|m| m.get(&key))
            .map(|f| f.header.clone());

        // Check if cached replacement function exists and return it.
        if let Some(new_target) = cached_new_target {
            return Ok(new_target);
        }

        // Check if processing the given target+key is already on the Rust stack
        //  (i.e. detect recursion without progress) and return the expected name.
        {
            // NOTE: This borrow is inside brackets to prevent runtime double borrow error.
            let mut bor = self.pending_transform_function.borrow_mut();
            // If it's already in the stack, just return the expected name.
            let pending_key = (target.clone(), key.clone());
            if let Some(name) = bor.get(&pending_key) {
                return Ok(name.clone());
            }
            // Otherwise, generate the new name and push it to the stack.
            let new_name = format!("{}.{}", target, new_id());
            bor.insert(pending_key, new_name.clone());
        }

        // Use self.transform_function(..) on the original function to create a
        //  new FunctionCode by running this transformer on the existing one.
        let mut res = self.transform_function(&self.get_function(target))?;
        // Pop from pending transformation set
        let new_name = self
            .pending_transform_function
            .borrow_mut()
            .remove(&(target.clone(), key.clone()))
            .expect("pending_transform_function structure is corrupted");

        // Rename and store the transformed function
        res.header = new_name.clone();
        if DEBUG_LOOP_UNROLL {
            println!("[UNROLL][cached_transform_function] created function {:?}", res);
        }
        checked_insert!(
            RefMut::map(self.transformed_functions.borrow_mut(), |m| {
                m.entry(target.clone()).or_default()
            }),
            key,
            res
        );

        Ok(new_name)
    }

    fn transform_call_bucket_impl(
        &self,
        bucket: &CallBucket,
    ) -> Result<InstructionPointer, BadInterp> {
        let ctx_node: Option<NodeRef> = {
            // NOTE: This borrow is inside brackets to prevent runtime double borrow error.
            let ctx_chain = self.current_ctx_chain.borrow();
            if DEBUG_LOOP_UNROLL {
                println!("[UNROLL][transform_call_bucket] ctx_chain = {:?}", ctx_chain);
            }
            Node::get_node(&self.borrow_observer_result().replacement_context, ctx_chain.as_slice())
        };
        if DEBUG_LOOP_UNROLL {
            println!("[UNROLL][transform_call_bucket] unroll tree = {:?}", ctx_node);
        }

        let tgt = self.cached_transform_function(&bucket.symbol, ctx_node.unwrap_or_default())?;
        let ret = Ok(CallBucket {
            id: new_id(),
            source_file_id: bucket.source_file_id,
            line: bucket.line,
            message_id: bucket.message_id,
            symbol: tgt,
            argument_types: bucket.argument_types.clone(),
            arguments: self.transform_instructions_fixed_len(&bucket.arguments)?,
            arena_size: bucket.arena_size,
            return_info: self.transform_return_type(&bucket.id, &bucket.return_info)?,
        }
        .allocate());
        if DEBUG_LOOP_UNROLL {
            println!("[UNROLL][transform_call_bucket] replaced with call {:?}", ret);
        }

        ret
    }
}

impl<'d> CircuitTransformationPass for LoopUnrollPass<'d> {
    default__name!("LoopUnrollPass");
    default__get_mem!();

    // Custom implementation because this transformer does not transform functions independently,
    //  but instead only within the specific calling context reachable from a template.
    fn transform_circuit(&self, circuit: Circuit) -> Result<Circuit, BadInterp> {
        self.pre_hook_circuit(&circuit)?;

        // Setup the PassMemory from the Circuit
        let mut llvm_data = circuit.llvm_data;
        let mem = self.get_mem();
        mem.fill(circuit.templates, circuit.functions, llvm_data.mem_layout);

        // Transform templates
        let templates = mem
            .get_templates()
            .into_iter()
            .map(|t| self.transform_template(&t))
            .collect::<Result<_, _>>()?;

        // Update the LLVMCircuitData for the transformed Circuit
        llvm_data.mem_layout = mem.clear();
        self.update_bounded_arrays(&mut llvm_data.bounded_arrays);

        // Generate the list of transformed functions
        let functions = self
            .transformed_functions
            .take()
            .into_values()
            .flat_map(IndexMap::into_values)
            .collect();

        // Create and return the transformed Circuit
        Ok(Circuit {
            wasm_producer: circuit.wasm_producer,
            c_producer: circuit.c_producer,
            summary_producer: circuit.summary_producer,
            llvm_data,
            templates,
            functions,
        })
    }

    fn run_template(&self, template: &TemplateCode) -> Result<(), BadInterp> {
        // Create a new LoopUnrollObserver to use while interpreting the current template
        let obs = LoopUnrollObserver::new(self.global_data, &self.memory, &self.extractor);
        let res = self.get_mem().run_template(self.global_data, &obs, template);
        // Store the result from the observer
        self.observer_result.borrow_mut().replace(obs.take_result());
        res
    }

    fn post_hook_template(&self, _: &mut TemplateCodeInfo) -> Result<(), BadInterp> {
        // Clear the observer result
        let obs_res = self.observer_result.take();
        debug_assert!(obs_res.is_some());
        Ok(())
    }

    fn transform_call_bucket(&self, bucket: &CallBucket) -> Result<InstructionPointer, BadInterp> {
        if DEBUG_LOOP_UNROLL {
            println!("[UNROLL][transform_call_bucket] {:?}", bucket);
        }

        // Push the current CallBucket to the context
        {
            // NOTE: This borrow is inside brackets to prevent runtime double borrow error.
            self.current_ctx_chain.borrow_mut().push(bucket.id);
        }

        let result = Self::transform_call_bucket_impl(&self, bucket);

        // Pop the current CallBucket from the context
        {
            let popped = self.current_ctx_chain.borrow_mut().pop();
            assert!(popped.is_some_and(|x| x == bucket.id)); // context was not corrupted
        }

        result
    }

    fn transform_loop_bucket(&self, bucket: &LoopBucket) -> Result<InstructionPointer, BadInterp> {
        if DEBUG_LOOP_UNROLL {
            println!("[UNROLL][transform_loop_bucket] {:?}", bucket);
        }
        let node = {
            // NOTE: This borrow is inside brackets to prevent runtime double borrow error.
            let ctx_ref = self.current_ctx_chain.borrow();
            Node::get_node(&self.borrow_observer_result().replacement_context, ctx_ref.as_slice())
        };
        if let Some(n) = node {
            if let Some(bb_id) = Node::get_replacement(&n, &bucket.id) {
                let bor = self.borrow_observer_result();
                let bb = bor
                    .unrolled_block_owner
                    .get(&bb_id)
                    .expect("owning storage out of sync with replacement context tree!");
                return self.transform_block_bucket(bb);
            }
        }
        self.transform_loop_bucket_default(bucket)
    }
}

#[cfg(test)]
mod tests {
    use std::cell::RefCell;
    use compiler::circuit_design::template::TemplateCodeInfo;
    use compiler::compiler_interface::Circuit;
    use compiler::intermediate_representation::{Instruction, new_id};
    use compiler::intermediate_representation::ir_interface::{
        AddressType, Allocate, InstrContext, LoadBucket, LocationRule, LoopBucket, ObtainMetaImpl,
        OperatorType, StoreBucket,
    };
    use crate::passes::builders::{build_compute, build_u32_value};
    use crate::passes::{CircuitTransformationPass, GlobalPassData};
    use crate::passes::loop_unroll::{LoopUnrollPass, LOOP_BODY_FN_PREFIX};

    #[test]
    fn test_loop_unrolling() {
        let prime = "goldilocks".to_string();
        let global_data = RefCell::new(GlobalPassData::new());
        let pass = LoopUnrollPass::new(prime, &global_data);
        let circuit = example_program();
        let new_circuit =
            pass.transform_circuit(circuit.clone()).map_err(|e| e.get_message().clone()).unwrap();
        if cfg!(debug_assertions) {
            println!("{}", new_circuit.templates[0].body.last().unwrap().to_string());
        }
        assert_ne!(circuit, new_circuit);
        match new_circuit.templates[0].body.last().unwrap().as_ref() {
            Instruction::Block(b) => {
                // 5 iterations unrolled into 5 call statements targeting extracted loop body functions
                assert_eq!(b.body.len(), 5);
                assert!(b.body.iter().all(|s| if let Instruction::Call(c) = s.as_ref() {
                    c.symbol.starts_with(LOOP_BODY_FN_PREFIX)
                } else {
                    false
                }));
            }
            _ => assert!(false),
        }
    }

    fn example_program() -> Circuit {
        Circuit {
            templates: vec![Box::new(TemplateCodeInfo {
                id: 0,
                source_file_id: None,
                line: 0,
                header: "test_0".to_string(),
                name: "test".to_string(),
                is_parallel: false,
                is_parallel_component: false,
                is_not_parallel_component: false,
                has_parallel_sub_cmp: false,
                number_of_inputs: 0,
                number_of_outputs: 0,
                number_of_intermediates: 0,
                body: vec![
                    // (store 0 0)
                    StoreBucket {
                        id: new_id(),
                        source_file_id: None,
                        line: 0,
                        message_id: 0,
                        context: InstrContext { size: 0 },
                        dest_is_output: false,
                        dest_address_type: AddressType::Variable,
                        dest: LocationRule::Indexed {
                            location: build_u32_value(&ObtainMetaImpl::default(), 0),
                            template_header: None,
                        },
                        src: build_u32_value(&ObtainMetaImpl::default(), 0),
                        bounded_fn: None,
                    }
                    .allocate(),
                    // (store 1 0)
                    StoreBucket {
                        id: new_id(),
                        source_file_id: None,
                        line: 0,
                        message_id: 0,
                        context: InstrContext { size: 0 },
                        dest_is_output: false,
                        dest_address_type: AddressType::Variable,
                        dest: LocationRule::Indexed {
                            location: build_u32_value(&ObtainMetaImpl::default(), 1),
                            template_header: None,
                        },
                        src: build_u32_value(&ObtainMetaImpl::default(), 0),
                        bounded_fn: None,
                    }
                    .allocate(),
                    // (loop (compute le (load 1) 5) (
                    LoopBucket {
                        id: new_id(),
                        source_file_id: None,
                        line: 0,
                        message_id: 0,
                        continue_condition: build_compute(
                            &ObtainMetaImpl::default(),
                            OperatorType::Lesser,
                            0,
                            vec![
                                LoadBucket {
                                    id: new_id(),
                                    source_file_id: None,
                                    line: 0,
                                    message_id: 0,
                                    address_type: AddressType::Variable,
                                    src: LocationRule::Indexed {
                                        location: build_u32_value(&ObtainMetaImpl::default(), 1),
                                        template_header: None,
                                    },
                                    context: InstrContext { size: 0 },
                                    bounded_fn: None,
                                }
                                .allocate(),
                                build_u32_value(&ObtainMetaImpl::default(), 5),
                            ],
                        ),
                        body: vec![
                            //   (store 0 (compute add (load 0) 2))
                            StoreBucket {
                                id: new_id(),
                                source_file_id: None,
                                line: 0,
                                message_id: 0,
                                context: InstrContext { size: 0 },
                                dest_is_output: false,
                                dest_address_type: AddressType::Variable,
                                dest: LocationRule::Indexed {
                                    location: build_u32_value(&ObtainMetaImpl::default(), 0),
                                    template_header: None,
                                },
                                src: build_compute(
                                    &ObtainMetaImpl::default(),
                                    OperatorType::Add,
                                    0,
                                    vec![
                                        LoadBucket {
                                            id: new_id(),
                                            source_file_id: None,
                                            line: 0,
                                            message_id: 0,
                                            address_type: AddressType::Variable,
                                            src: LocationRule::Indexed {
                                                location: build_u32_value(
                                                    &ObtainMetaImpl::default(),
                                                    0,
                                                ),
                                                template_header: None,
                                            },
                                            context: InstrContext { size: 0 },
                                            bounded_fn: None,
                                        }
                                        .allocate(),
                                        build_u32_value(&ObtainMetaImpl::default(), 2),
                                    ],
                                ),
                                bounded_fn: None,
                            }
                            .allocate(),
                            //   (store 1 (compute add (load 1) 1))
                            StoreBucket {
                                id: new_id(),
                                source_file_id: None,
                                line: 0,
                                message_id: 0,
                                context: InstrContext { size: 0 },
                                dest_is_output: false,
                                dest_address_type: AddressType::Variable,
                                dest: LocationRule::Indexed {
                                    location: build_u32_value(&ObtainMetaImpl::default(), 1),
                                    template_header: None,
                                },
                                src: build_compute(
                                    &ObtainMetaImpl::default(),
                                    OperatorType::Add,
                                    0,
                                    vec![
                                        LoadBucket {
                                            id: new_id(),
                                            source_file_id: None,
                                            line: 0,
                                            message_id: 0,
                                            address_type: AddressType::Variable,
                                            src: LocationRule::Indexed {
                                                location: build_u32_value(
                                                    &ObtainMetaImpl::default(),
                                                    1,
                                                ),
                                                template_header: None,
                                            },
                                            context: InstrContext { size: 0 },
                                            bounded_fn: None,
                                        }
                                        .allocate(),
                                        build_u32_value(&ObtainMetaImpl::default(), 1),
                                    ],
                                ),
                                bounded_fn: None,
                            }
                            .allocate(),
                        ],
                    }
                    .allocate(), // ))
                ],
                var_stack_depth: 0,
                expression_stack_depth: 0,
                signal_stack_depth: 0,
                number_of_components: 0,
            })],
            functions: vec![],
            ..Default::default()
        }
    }
}
