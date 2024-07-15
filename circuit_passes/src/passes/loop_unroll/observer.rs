use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
use compiler::intermediate_representation::{ToSExp, UpdateId};
use compiler::intermediate_representation::ir_interface::*;
use crate::bucket_interpreter::env::Env;
use crate::bucket_interpreter::error::{self, BadInterp};
use crate::bucket_interpreter::memory::PassMemory;
use crate::bucket_interpreter::observer::Observer;
use crate::bucket_interpreter::{InterpreterFlags, LOOP_LIMIT};
use crate::checked_insert;
use crate::passes::{builders, GlobalPassData};
use super::body_extractor::LoopBodyExtractor;
use super::call_unroll_tree::Node;
use super::loop_env_recorder::EnvRecorder;
use super::map_like_trait::MapLike;
use super::{
    BlockBucketId, LoopBucketId, DEBUG_LOOP_UNROLL, EXTRACT_LOOP_BODY_TO_NEW_FUNC,
    UNROLLED_BUCKET_LABEL,
};

#[derive(Debug, Default)]
pub(super) struct LoopUnrollObserverResult {
    /// Structure that owns all BlockBucket created by unrolling a loop. Keyed by the ID of
    /// the BlockBucket so the other structures that organize and cache them can find them.
    /// Note: uses Rc internally or else recursively processing loops inside the BlockBucket
    /// via continue_inside() would cause double borrow or require cloning.
    pub unrolled_block_owner: HashMap<BlockBucketId, Rc<BlockBucket>>,
    /// Unrolled loop IDs organized by the context where they should be used.
    pub replacement_context: super::call_unroll_tree::NodeRef,
}

impl LoopUnrollObserverResult {
    /// Lookup BlockBucket for the given `key` in the given `cache` or else
    /// call the `builder` function to create a new BlockBucket and store
    /// it into `this` and the `cache` and return reference to it.
    pub(crate) fn get_or_create_unrolled<K, F: FnOnce(&K) -> BlockBucket>(
        this: &RefCell<LoopUnrollObserverResult>,
        cache: &RefCell<impl MapLike<K, BlockBucketId>>,
        key: K,
        builder: F,
    ) -> Rc<BlockBucket>
    where
        K: std::fmt::Debug,
    {
        let id = {
            // NOTE: This borrow is inside brackets to prevent runtime double borrow error.
            cache.borrow().get(&key).cloned()
        };
        let id = match id {
            Some(id) => id,
            None => {
                // Necessary BlockBucket does not exist so create it and store to storage and cache.
                let new_bucket = builder(&key);
                let id = new_bucket.id;
                checked_insert!(
                    &mut this.borrow_mut().unrolled_block_owner,
                    id,
                    Rc::new(new_bucket)
                );
                checked_insert!(cache.borrow_mut(), key, id);
                id
            }
        };
        Rc::clone(
            this.borrow()
                .unrolled_block_owner
                .get(&id)
                .expect("owning storage out of sync with cache!"),
        )
    }
}

pub(super) struct LoopUnrollObserver<'d> {
    global_data: &'d RefCell<GlobalPassData>,
    memory: &'d PassMemory,
    extractor: &'d LoopBodyExtractor,
    result: RefCell<LoopUnrollObserverResult>,
    /// Unrolled block cache keyed on loop + iteration count, for in-place unrolling only.
    inplace_replace_cache: RefCell<HashMap<(LoopBucketId, usize), BlockBucketId>>,
}

impl<'d> LoopUnrollObserver<'d> {
    #[inline]
    pub fn new(
        global_data: &'d RefCell<GlobalPassData>,
        memory: &'d PassMemory,
        extractor: &'d LoopBodyExtractor,
    ) -> Self {
        LoopUnrollObserver {
            global_data,
            memory,
            extractor,
            result: Default::default(),
            inplace_replace_cache: Default::default(),
        }
    }

    #[inline]
    pub fn take_result(&self) -> LoopUnrollObserverResult {
        self.result.take()
    }
}

impl Observer<Env<'_>> for LoopUnrollObserver<'_> {
    fn on_loop_bucket(&self, bucket: &LoopBucket, env: &Env) -> Result<bool, BadInterp> {
        if DEBUG_LOOP_UNROLL {
            println!("\n[UNROLL][try_unroll_loop] loop {}:", bucket.id);
            for (i, s) in bucket.body.iter().enumerate() {
                println!("[{}/{}]{}", i + 1, bucket.body.len(), s.to_sexp().to_pretty(100));
            }
            for (i, s) in bucket.body.iter().enumerate() {
                println!("[{}/{}]{:?}", i + 1, bucket.body.len(), s);
            }
            println!("\n[UNROLL][try_unroll_loop] ENTRY env = {}", env);
        }

        let result = self.try_unroll_loop(bucket, env);
        if DEBUG_LOOP_UNROLL {
            println!("[UNROLL][try_unroll_loop] result for loop {}: {:?}\n", bucket.id, result);
        }
        if let Some(block) = result? {
            self.continue_inside(&block, env)?;

            let caller_stack = env.get_caller_stack();
            if DEBUG_LOOP_UNROLL {
                println!(
                    "[UNROLL][on_loop_bucket] storing replacement for loop {} with call stack {:?} :: {:?}",
                    bucket.id, caller_stack, block
                );
            }
            // Insert to the replacements tree at the proper position based on 'caller_stack'
            Node::insert(
                &self.result.borrow_mut().replacement_context,
                caller_stack,
                &bucket.id,
                block.id,
            );
        }

        // Do not continue observing within this loop bucket because continue_inside()
        //  runs a new interpreter inside the unrolled body that is observed instead.
        Ok(false)
    }

    fn ignore_function_calls(&self) -> bool {
        false
    }

    fn ignore_extracted_function_calls(&self) -> bool {
        false
    }
}

impl LoopUnrollObserver<'_> {
    fn try_unroll_loop(
        &self,
        bucket: &LoopBucket,
        env: &Env,
    ) -> Result<Option<Rc<BlockBucket>>, BadInterp> {
        // Compute loop iteration count. If unknown, return immediately.
        let recorder = EnvRecorder::new(self.global_data, &self.memory, env.get_context_kind());
        {
            let interpreter = self.memory.build_interpreter_with_flags(
                self.global_data,
                &recorder,
                InterpreterFlags { visit_unknown_condition_branches: true, ..Default::default() },
            );
            let mut inner_env = env.clone();
            let mut n_iters = 0;
            loop {
                n_iters += 1;
                if n_iters >= LOOP_LIMIT {
                    return Result::Err(error::new_compute_err(format!(
                        "Could not determine loop count within {LOOP_LIMIT} iterations"
                    )));
                }
                recorder.record_header_env(&inner_env);
                let (cond, new_env) =
                    interpreter.execute_loop_bucket_once(bucket, inner_env, true)?;
                if DEBUG_LOOP_UNROLL {
                    println!(
                        "[UNROLL][try_unroll_loop] execute_loop_bucket_once() -> cond={:?}, env={:?}",
                        cond, new_env
                    );
                }
                match cond {
                    // If the conditional becomes unknown just give up.
                    None => return Ok(None),
                    // When conditional becomes `false`, iteration count is complete.
                    Some(false) => break,
                    // Otherwise, continue counting.
                    Some(true) => recorder.increment_iter(),
                };
                inner_env = new_env;
            }
            recorder.drop_header_env(); //free Env from the final iteration
        }
        if DEBUG_LOOP_UNROLL {
            println!("[UNROLL] recorder = {:?}", recorder);
        }

        let num_iter = recorder.get_iter();
        // Generate the unrolled loop body, either an in-place unrolling or
        //  a series of calls the extracted body function.
        if EXTRACT_LOOP_BODY_TO_NEW_FUNC && num_iter > 1 && recorder.is_safe_to_move() {
            // If the loop body contains more than one instruction, extract it into a
            // new function and generate 'num_iter' number of calls to that function.
            // Otherwise, just duplicate the body 'num_iter' number of times.
            match &bucket.body[..] {
                [a] => {
                    if DEBUG_LOOP_UNROLL {
                        println!(
                            "[UNROLL][try_unroll_loop] OUTCOME: safe to move, single statement, in-place"
                        );
                    }
                    let bb = self.inplace_replace_cache_lookup(bucket.id, num_iter, |_| {
                        let mut block_body = Vec::with_capacity(num_iter);
                        for _ in 0..num_iter {
                            let mut copy = a.clone();
                            copy.update_id();
                            block_body.push(copy);
                        }
                        builders::build_block_bucket(
                            bucket,
                            block_body,
                            num_iter,
                            String::from(UNROLLED_BUCKET_LABEL),
                        )
                    });
                    Ok(Some(bb))
                }
                _ => {
                    if DEBUG_LOOP_UNROLL {
                        println!("[UNROLL][try_unroll_loop] OUTCOME: safe to move, extracting");
                    }
                    self.extractor.extract(bucket, recorder, &self.result).map(Option::Some)
                }
            }
        } else {
            //If the loop body is not safe to move into a new function, just unroll in-place.
            if DEBUG_LOOP_UNROLL {
                println!("[UNROLL][try_unroll_loop] OUTCOME: not safe to move, unrolling in-place");
            }
            let bb = self.inplace_replace_cache_lookup(bucket.id, num_iter, |_| {
                let mut block_body = Vec::with_capacity(num_iter * bucket.body.len());
                for _ in 0..num_iter {
                    for s in &bucket.body {
                        let mut copy = s.clone();
                        copy.update_id();
                        block_body.push(copy);
                    }
                }
                builders::build_block_bucket(
                    bucket,
                    block_body,
                    num_iter,
                    String::from(UNROLLED_BUCKET_LABEL),
                )
            });
            Ok(Some(bb))
        }
    }

    // Will interpret the unrolled loop to check for additional loops inside
    fn continue_inside(&self, bucket: &BlockBucket, env: &Env) -> Result<(), BadInterp> {
        if DEBUG_LOOP_UNROLL {
            println!("[UNROLL][continue_inside] with {}", env);
        }
        let interpreter = self.memory.build_interpreter(self.global_data, self);
        let env = Env::new_unroll_block_env(env.clone(), &self.extractor);
        interpreter.execute_block_bucket(bucket, env, true)?;
        Ok(())
    }

    #[inline]
    fn inplace_replace_cache_lookup<F: FnOnce(&(LoopBucketId, usize)) -> BlockBucket>(
        &self,
        loop_id: LoopBucketId,
        num_iter: usize,
        builder: F,
    ) -> Rc<BlockBucket> {
        LoopUnrollObserverResult::get_or_create_unrolled(
            &self.result,
            &self.inplace_replace_cache,
            (loop_id, num_iter),
            builder,
        )
    }
}
