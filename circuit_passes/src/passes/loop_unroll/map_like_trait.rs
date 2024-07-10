use std::collections::{BTreeMap, HashMap};
use std::hash::Hash;
use std::ops::Index;
use indexmap::IndexMap;

#[allow(dead_code)]
pub trait MapLike<K, V>: for<'a> Index<&'a K, Output = V> {
    type It<'a>: Iterator<Item = (&'a K, &'a V)>
    where
        K: 'a,
        V: 'a,
        Self: 'a;

    fn get(&self, k: &K) -> Option<&V>;
    fn insert(&mut self, k: K, v: V);
    fn contains_key(&self, k: &K) -> bool;

    fn iter<'a>(&'a self) -> Self::It<'a>
    where
        K: 'a,
        V: 'a;
}

impl<K: Eq + Hash, V> MapLike<K, V> for HashMap<K, V> {
    type It<'a> = std::collections::hash_map::Iter<'a, K, V> where K: 'a, V: 'a;

    #[inline]
    fn get(&self, k: &K) -> Option<&V> {
        self.get(k)
    }

    #[inline]
    fn insert(&mut self, k: K, v: V) {
        self.insert(k, v);
    }

    #[inline]
    fn contains_key(&self, k: &K) -> bool {
        self.contains_key(k)
    }

    #[inline]
    fn iter<'a>(&'a self) -> Self::It<'a>
    where
        K: 'a,
        V: 'a,
    {
        self.iter()
    }
}

impl<K: Eq + Ord, V> MapLike<K, V> for BTreeMap<K, V> {
    type It<'a> = std::collections::btree_map::Iter<'a, K, V> where K: 'a, V: 'a;

    #[inline]
    fn get(&self, k: &K) -> Option<&V> {
        self.get(k)
    }

    #[inline]
    fn insert(&mut self, k: K, v: V) {
        self.insert(k, v);
    }

    #[inline]
    fn contains_key(&self, k: &K) -> bool {
        self.contains_key(k)
    }

    #[inline]
    fn iter<'a>(&'a self) -> Self::It<'a>
    where
        K: 'a,
        V: 'a,
    {
        self.iter()
    }
}

impl<K: Eq + Hash, V> MapLike<K, V> for IndexMap<K, V> {
    type It<'a> = indexmap::map::Iter<'a, K, V> where K: 'a, V: 'a;

    #[inline]
    fn get(&self, k: &K) -> Option<&V> {
        self.get(k)
    }

    #[inline]
    fn insert(&mut self, k: K, v: V) {
        self.insert(k, v);
    }

    #[inline]
    fn contains_key(&self, k: &K) -> bool {
        self.contains_key(k)
    }

    #[inline]
    fn iter<'a>(&'a self) -> Self::It<'a>
    where
        K: 'a,
        V: 'a,
    {
        self.iter()
    }
}
