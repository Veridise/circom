use compiler::intermediate_representation::InstructionList;
use super::{env::Env, error::BadInterp, BucketInterpreter};

pub(crate) fn set_writes_to_unknown<'e>(
    interp: &BucketInterpreter,
    body: &InstructionList,
    env: Env<'e>,
) -> Result<Env<'e>, BadInterp> {
    let mut checker = write_checker::Writes::default();
    Result::from(checker.collect_writes(interp, body, env.clone())).map_or_else(
        |b| Result::Err(b),
        // For the Ok case, ignore the Env computed within the body
        //  and just set Unknown to all writes that were found.
        |_| checker.set_unknowns(env),
    )
}

mod write_checker {
    use std::collections::HashSet;

    use compiler::intermediate_representation::{
        ir_interface::{
            AddressType, FinalData, LocationRule, LogBucketArg, ReturnType, StoreBucket,
        },
        Instruction, InstructionList, InstructionPointer,
    };

    use crate::bucket_interpreter::{
        env::Env, error::BadInterp, value::Value, BucketInterpreter, InterpRes,
    };

    #[derive(Debug, PartialEq, Eq)]
    pub(super) struct Writes {
        vars: Option<HashSet<usize>>,
        signals: Option<HashSet<usize>>,
        subcmps: Option<HashSet<usize>>,
    }

    impl Default for Writes {
        fn default() -> Self {
            Self {
                vars: Some(Default::default()),
                signals: Some(Default::default()),
                subcmps: Some(Default::default()),
            }
        }
    }

    impl Writes {
        pub(super) fn set_unknowns<'e>(self, env: Env<'e>) -> Result<Env<'e>, BadInterp> {
            env.set_vars_to_unk(self.vars)
                .set_signals_to_unk(self.signals)
                .set_subcmps_to_unk(self.subcmps)
        }

        pub(super) fn collect_writes<'e>(
            &mut self,
            interp: &BucketInterpreter,
            body: &InstructionList,
            env: Env<'e>,
        ) -> InterpRes<Env<'e>> {
            let mut env = env;
            for inst in body {
                env = check_res!(self.check_inst(interp, inst, env));
            }
            InterpRes::Continue(env)
        }

        fn check_inst<'e>(
            &mut self,
            interp: &BucketInterpreter,
            inst: &Instruction,
            env: Env<'e>,
        ) -> InterpRes<Env<'e>> {
            match inst {
                Instruction::Store(b) => self.check_store_bucket(interp, b, env),
                Instruction::Constraint(b) => self.check_inst(interp, b.unwrap(), env),
                Instruction::Block(b) => self.collect_writes(interp, &b.body, env),
                Instruction::Branch(b) => {
                    self.check_branch(interp, &b.cond, &b.if_branch, &b.else_branch, env)
                }
                Instruction::Loop(b) => {
                    self.check_branch(interp, &b.continue_condition, &b.body, &vec![], env)
                }
                i => {
                    debug_assert!(!ContainsStore::contains_store(i));
                    InterpRes::Continue(env)
                }
            }
        }

        fn check_branch<'e>(
            &mut self,
            interp: &BucketInterpreter,
            cond: &InstructionPointer,
            true_branch: &InstructionList,
            false_branch: &InstructionList,
            env: Env<'e>,
        ) -> InterpRes<Env<'e>> {
            match interp.compute_condition(cond, &env, false) {
                Err(e) => return InterpRes::Err(e),
                Ok(None) => {
                    // If the condition is unknown, collect all writes from both branches (even if
                    //  there is a return in either, hence an InterpRes::Return result is ignored
                    //  in both cases) and produce InterpRes::Continue with the original Env.
                    if let InterpRes::Err(e) = self.collect_writes(interp, true_branch, env.clone())
                    {
                        return InterpRes::Err(e);
                    }
                    if let InterpRes::Err(e) =
                        self.collect_writes(interp, false_branch, env.clone())
                    {
                        return InterpRes::Err(e);
                    }
                    InterpRes::Continue(env)
                }
                Ok(Some(true)) => {
                    // If the condition is true, collect all writes from the false branch
                    //  (ignoring an InterpRes::Return result as above) and then analyze
                    //  and return the result from the true branch.
                    if let InterpRes::Err(e) =
                        self.collect_writes(interp, false_branch, env.clone())
                    {
                        return InterpRes::Err(e);
                    }
                    self.collect_writes(interp, true_branch, env)
                }
                Ok(Some(false)) => {
                    // Reverse of the true case.
                    if let InterpRes::Err(e) = self.collect_writes(interp, true_branch, env.clone())
                    {
                        return InterpRes::Err(e);
                    }
                    self.collect_writes(interp, false_branch, env)
                }
            }
        }

        fn check_store_bucket<'e>(
            &mut self,
            interp: &BucketInterpreter,
            bucket: &StoreBucket,
            env: Env<'e>,
        ) -> InterpRes<Env<'e>> {
            let idx = interp.compute_location_index(
                &bucket.dest,
                &bucket.id,
                &env,
                false,
                "store destination index",
            );
            let idx = check_std_res!(idx);
            if let Value::Unknown = idx {
                // For an unknown index, all memory of the specified type must be marked as Unknown
                // TODO: FUTURE: Setting the entire area of the specific memory type as Unknown is
                //  pretty aggressive and could be relaxed some if information about the base local
                //  used in the store can be determined and then PassMemory::get_*_index_mapping()
                //  can be used to get only the memory range pertaining to that specific base local.
                match bucket.dest_address_type {
                    AddressType::Variable => self.vars = None,
                    AddressType::Signal => self.signals = None,
                    AddressType::SubcmpSignal { .. } => self.subcmps = None,
                };
            } else {
                // For a known index, just add the specific index to the Unknown set
                let idx = check_std_res!(idx.as_u32());
                match bucket.dest_address_type {
                    AddressType::Variable => self.vars.as_mut(),
                    AddressType::Signal => self.signals.as_mut(),
                    AddressType::SubcmpSignal { .. } => self.subcmps.as_mut(),
                }
                .map(|s| s.insert(idx));
            }

            //Reflect the store into the Env
            InterpRes::try_continue(interp.execute_store_bucket(bucket, env, false).map(|(_, e)| e))
        }

        #[cfg(test)]
        pub(super) fn init<T>(vars: Option<T>, signals: Option<T>, subcmps: Option<T>) -> Writes
        where
            T: IntoIterator<Item = usize>,
        {
            Writes {
                vars: vars.map(|x| HashSet::from_iter(x.into_iter())),
                signals: signals.map(|x| HashSet::from_iter(x.into_iter())),
                subcmps: subcmps.map(|x| HashSet::from_iter(x.into_iter())),
            }
        }
    }

    trait ContainsStore {
        fn contains_store(&self) -> bool;
    }

    impl ContainsStore for Instruction {
        fn contains_store(&self) -> bool {
            match self {
                Instruction::Nop(_) => false,
                Instruction::Value(_) => false,
                Instruction::Store(_) => true,
                Instruction::Load(b) => b.address_type.contains_store() || b.src.contains_store(),
                Instruction::Compute(b) => b.stack.contains_store(),
                Instruction::Call(b) => {
                    //TODO: what about extracted body functions? They should be treated as the
                    // same function so shouldn't I check within the callee body?
                    //  I need to write a test to properly exercise this case.
                    b.arguments.contains_store() || b.return_info.contains_store()
                }
                Instruction::Branch(b) => {
                    b.cond.contains_store()
                        || b.if_branch.contains_store()
                        || b.else_branch.contains_store()
                }
                Instruction::Return(b) => b.value.contains_store(),
                Instruction::Assert(b) => b.evaluate.contains_store(),
                Instruction::Log(b) => b.argsprint.contains_store(),
                Instruction::Loop(b) => {
                    b.continue_condition.contains_store() || b.body.contains_store()
                }
                Instruction::CreateCmp(b) => b.sub_cmp_id.contains_store(),
                Instruction::Constraint(b) => b.unwrap().contains_store(),
                Instruction::Block(b) => b.body.contains_store(),
            }
        }
    }

    impl ContainsStore for InstructionPointer {
        fn contains_store(&self) -> bool {
            self.as_ref().contains_store()
        }
    }

    impl<T: ContainsStore> ContainsStore for Vec<T> {
        fn contains_store(&self) -> bool {
            self.iter().any(ContainsStore::contains_store)
        }
    }

    impl ContainsStore for LocationRule {
        fn contains_store(&self) -> bool {
            match self {
                LocationRule::Indexed { location, .. } => location.contains_store(),
                LocationRule::Mapped { indexes, .. } => indexes.contains_store(),
            }
        }
    }

    impl ContainsStore for AddressType {
        fn contains_store(&self) -> bool {
            match self {
                AddressType::Variable => false,
                AddressType::Signal => false,
                AddressType::SubcmpSignal { cmp_address, .. } => cmp_address.contains_store(),
            }
        }
    }

    impl ContainsStore for LogBucketArg {
        fn contains_store(&self) -> bool {
            match self {
                LogBucketArg::LogStr(_) => false,
                LogBucketArg::LogExp(i) => i.contains_store(),
            }
        }
    }

    impl ContainsStore for ReturnType {
        fn contains_store(&self) -> bool {
            match self {
                ReturnType::Intermediate { .. } => false,
                ReturnType::Final(FinalData { dest_address_type, dest, .. }) => {
                    dest_address_type.contains_store() || dest.contains_store()
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use std::cell::RefCell;
    use compiler::intermediate_representation::{ir_interface::*, new_id};
    use crate::{
        bucket_interpreter::{
            env::{Env, EnvContextKind},
            memory::PassMemory,
            observer::Observer,
            write_collector::write_checker::Writes,
            BucketInterpreter, InterpRes,
        },
        passes::{
            builders::{build_bigint_value, build_u32_value},
            GlobalPassData,
        },
    };

    struct TestSetup {
        global_data: RefCell<GlobalPassData>,
        memory: PassMemory,
    }

    impl TestSetup {
        fn new() -> Self {
            Self {
                global_data: RefCell::new(GlobalPassData::new()),
                memory: PassMemory::new(String::from("goldilocks"), Default::default()),
            }
        }

        fn make_interp(&self) -> BucketInterpreter {
            self.memory.build_interpreter(&self.global_data, self)
        }

        fn make_env(&self) -> Env {
            Env::new_standard_env(EnvContextKind::Template, &self.memory)
        }
    }

    impl<'e> Observer<Env<'e>> for TestSetup {
        fn ignore_function_calls(&self) -> bool {
            false
        }
        fn ignore_subcmp_calls(&self) -> bool {
            false
        }
        fn ignore_extracted_function_calls(&self) -> bool {
            false
        }
    }

    #[test]
    fn test_1() {
        let setup = TestSetup::new();
        let interp = setup.make_interp();
        let env = setup.make_env();

        // Setup a dummy body
        let var_a = setup.memory.new_current_scope_variable_index_mapping(1); // scalar
        let var_b = setup.memory.new_current_scope_variable_index_mapping(3); // vector
        let var_c = setup.memory.new_current_scope_variable_index_mapping(1); // scalar
        let body = vec![
            // (store 99 var_a)
            StoreBucket {
                id: new_id(),
                source_file_id: None,
                line: 0,
                message_id: 0,
                context: InstrContext { size: 1 },
                dest_is_output: false,
                dest_address_type: AddressType::Variable,
                dest: LocationRule::Indexed {
                    location: build_u32_value(&ObtainMetaImpl::default(), var_a),
                    template_header: None,
                },
                src: build_u32_value(&ObtainMetaImpl::default(), 99),
                bounded_fn: None,
            }
            .allocate(),
            // (store 88 var_b)
            StoreBucket {
                id: new_id(),
                source_file_id: None,
                line: 0,
                message_id: 0,
                context: InstrContext { size: 1 },
                dest_is_output: false,
                dest_address_type: AddressType::Variable,
                dest: LocationRule::Indexed {
                    location: build_u32_value(&ObtainMetaImpl::default(), var_b),
                    template_header: None,
                },
                src: build_u32_value(&ObtainMetaImpl::default(), 88),
                bounded_fn: None,
            }
            .allocate(),
            // (store 77 var_c)
            StoreBucket {
                id: new_id(),
                source_file_id: None,
                line: 0,
                message_id: 0,
                context: InstrContext { size: 1 },
                dest_is_output: false,
                dest_address_type: AddressType::Variable,
                dest: LocationRule::Indexed {
                    location: build_u32_value(&ObtainMetaImpl::default(), var_c),
                    template_header: None,
                },
                src: build_u32_value(&ObtainMetaImpl::default(), 77),
                bounded_fn: None,
            }
            .allocate(),
        ];

        let mut checker = Writes::default();
        let collect_res = checker.collect_writes(&interp, &body, env);
        assert!(!matches!(collect_res, InterpRes::Err(_)));
        // EXPECT:
        //  - variables A, B (only index 0 in the vector), and C are written
        //  - no signals are written
        //  - no subcomponents are written
        assert_eq!(
            checker,
            Writes::init(Some(vec![var_a, var_b, var_c]), Some(vec![]), Some(vec![]))
        );
    }

    #[test]
    fn test_2() {
        let setup = TestSetup::new();
        let interp = setup.make_interp();
        let env = setup.make_env();

        // Setup a dummy body
        let sig_a = setup.memory.new_current_scope_signal_index_mapping(1); // scalar
        let body = vec![
            // (store 99 sig_a)
            StoreBucket {
                id: new_id(),
                source_file_id: None,
                line: 0,
                message_id: 0,
                context: InstrContext { size: 1 },
                dest_is_output: true,
                dest_address_type: AddressType::Signal,
                dest: LocationRule::Indexed {
                    location: ComputeBucket {
                        id: new_id(),
                        source_file_id: None,
                        line: 0,
                        message_id: 0,
                        op: OperatorType::ToAddress,
                        op_aux_no: 0,
                        stack: vec![LoadBucket {
                            id: new_id(),
                            source_file_id: None,
                            line: 0,
                            message_id: 0,
                            address_type: AddressType::Signal,
                            src: LocationRule::Indexed {
                                location: ValueBucket {
                                    id: new_id(),
                                    source_file_id: None,
                                    line: 0,
                                    message_id: 0,
                                    parse_as: ValueType::U32,
                                    op_aux_no: 0,
                                    value: sig_a,
                                }
                                .allocate(),
                                template_header: None,
                            },
                            context: InstrContext { size: 1 },
                            bounded_fn: None,
                        }
                        .allocate()],
                    }
                    .allocate(),
                    template_header: None,
                },
                src: build_bigint_value(&ObtainMetaImpl::default(), &setup.memory, &"987654321"),
                bounded_fn: None,
            }
            .allocate(),
        ];

        let mut checker = Writes::default();
        let collect_res = checker.collect_writes(&interp, &body, env);
        assert!(!matches!(collect_res, InterpRes::Err(_)));
        // EXPECT:
        //  - no variables are written
        //  - an unknown signal is written so all are cleared
        //  - no subcomponents are written
        assert_eq!(checker, Writes::init(Some(vec![]), None, Some(vec![])));
    }
}

