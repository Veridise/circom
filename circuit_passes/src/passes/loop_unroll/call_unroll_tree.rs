use std::cell::{Ref, RefCell};
use std::collections::{BTreeMap, HashMap};
use std::rc::Rc;
use crate::checked_insert;
use super::{BlockBucketId, CallBucketId, LoopBucketId};

/// Tree that holds the unrolled versions of loops per the calling context where the
/// loop is executed. The context is represented as the path of CallBucketId from the
/// root node to the current node via the 'children' mapping.
#[derive(Debug, Default, PartialEq, Eq)]
pub struct NodeRef(Rc<RefCell<Node>>);

impl std::hash::Hash for NodeRef {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.0.borrow().hash(state);
    }
}

impl Clone for NodeRef {
    fn clone(&self) -> Self {
        Self(Rc::clone(&self.0))
    }
}

#[derive(Debug, Default, PartialEq, Eq)]
pub struct Node {
    /// Maps ID of LoopBucket in the current function's body to unrolled version.
    /// There should be an entry for each loop in the body. Note, loops in the
    /// original Circom body that appear within another loop (i.e. nested loops)
    /// would have been visited first and unrolled so only one loop from a "nest"
    /// of loops would appear here. If that unrolling uses extracted body functions,
    /// this tree node has a child for each call to the extracted body function.
    unrolling: BTreeMap<LoopBucketId, BlockBucketId>,
    /// The tree node has a child for each CallBucket appearing in its body, keyed
    /// by the ID of the CallBucket.
    children: HashMap<CallBucketId, NodeRef>,
}

impl std::hash::Hash for Node {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.unrolling.hash(state);
        state.write_usize(self.children.len());
        for (call, child) in &self.children {
            call.hash(state);
            child.hash(state);
        }
    }
}

impl Node {
    /// Find the node for the 'caller_stack' path in the tree, creating as necessary.
    pub fn get_or_create_node<'a>(root: &'a NodeRef, caller_stack: &[CallBucketId]) -> NodeRef {
        let mut search = root.clone();
        for caller in caller_stack {
            let nxt = search;
            search = nxt.0.borrow_mut().children.entry(*caller).or_default().clone();
        }
        search
    }

    /// Find the node for the 'caller_stack' path in the tree, if present.
    pub fn get_node<'a>(root: &'a NodeRef, caller_stack: &[CallBucketId]) -> Option<NodeRef> {
        let mut search = root.clone();
        for caller in caller_stack {
            let nxt = search;
            match nxt.0.borrow().children.get(caller) {
                Some(n) => search = n.clone(),
                None => return None,
            };
        }
        Some(search)
    }

    /// Find the node for the 'caller_stack' path in the tree, creating as necessary
    /// and insert the mapping 'loop_id -> unrolled' in that node.
    pub fn insert(
        root: &NodeRef,
        caller_stack: &[CallBucketId],
        loop_id: &LoopBucketId,
        unrolled_block_id: BlockBucketId,
    ) {
        let search = Self::get_or_create_node(root, caller_stack);
        checked_insert!(&mut search.0.borrow_mut().unrolling, *loop_id, unrolled_block_id);
    }

    /// Get the ID of the BlockBucket that was generated containing
    /// the unrolling of LoopBucket with the given ID.
    pub fn get_replacement<'a>(
        node: &'a NodeRef,
        loop_bucket_id: &LoopBucketId,
    ) -> Option<Ref<'a, BlockBucketId>> {
        Ref::filter_map(node.0.borrow(), |b| b.unrolling.get(loop_bucket_id)).ok()
    }
}
