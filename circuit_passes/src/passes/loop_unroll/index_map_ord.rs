use std::cmp::Ordering;
use std::fmt::Debug;
use std::hash::Hash;
use std::ops::{Index, IndexMut};
use indexmap::{Equivalent, IndexMap};

use super::map_like_trait::MapLike;

pub struct IndexMapOrd<K, V>(IndexMap<K, V>);

impl<K, V> IndexMapOrd<K, V> {
    #[inline]
    pub fn len(&self) -> usize {
        self.0.len()
    }

    #[inline]
    pub fn is_empty(&self) -> bool {
        self.0.is_empty()
    }

    #[inline]
    pub fn iter(&self) -> indexmap::map::Iter<'_, K, V> {
        self.0.iter()
    }

    #[inline]
    pub fn iter_mut(&mut self) -> indexmap::map::IterMut<'_, K, V> {
        self.0.iter_mut()
    }

    #[inline]
    pub fn keys(&self) -> indexmap::map::Keys<'_, K, V> {
        self.0.keys()
    }

    #[inline]
    pub fn into_keys(self) -> indexmap::map::IntoKeys<K, V> {
        self.0.into_keys()
    }

    #[inline]
    pub fn values(&self) -> indexmap::map::Values<'_, K, V> {
        self.0.values()
    }

    #[inline]
    pub fn values_mut(&mut self) -> indexmap::map::ValuesMut<'_, K, V> {
        self.0.values_mut()
    }

    #[inline]
    pub fn into_values(self) -> indexmap::map::IntoValues<K, V> {
        self.0.into_values()
    }

    #[inline]
    pub fn clear(&mut self) {
        self.0.clear()
    }

    #[inline]
    pub fn retain<F: FnMut(&K, &mut V) -> bool>(&mut self, keep: F) {
        self.0.retain(keep)
    }
}

impl<K, V> IndexMapOrd<K, V> {
    #[inline]
    pub fn contains_key<Q: ?Sized + Hash + Equivalent<K>>(&self, key: &Q) -> bool {
        self.0.contains_key(key)
    }

    #[inline]
    pub fn get<Q: ?Sized + Hash + Equivalent<K>>(&self, key: &Q) -> Option<&V> {
        self.0.get(key)
    }

    #[inline]
    pub fn shift_remove<Q: ?Sized + Hash + Equivalent<K>>(&mut self, key: &Q) -> Option<V> {
        self.0.shift_remove(key)
    }
}

impl<K: Eq + Hash, V> IndexMapOrd<K, V> {
    #[inline]
    pub fn insert(&mut self, key: K, value: V) -> Option<V> {
        self.0.insert(key, value)
    }

    #[inline]
    pub fn entry(&mut self, key: K) -> indexmap::map::Entry<'_, K, V> {
        self.0.entry(key)
    }
}

impl<K, V> Default for IndexMapOrd<K, V> {
    fn default() -> Self {
        Self(IndexMap::default())
    }
}

impl<K: Clone, V: Clone> Clone for IndexMapOrd<K, V> {
    fn clone(&self) -> Self {
        Self(self.0.clone())
    }
}

impl<K: Debug, V: Debug> Debug for IndexMapOrd<K, V> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        self.0.fmt(f)
    }
}

impl<K: Eq + Hash, V: PartialEq> PartialEq for IndexMapOrd<K, V> {
    #[inline]
    fn eq(&self, other: &Self) -> bool {
        self.len() == other.len() && self.iter().as_slice() == other.iter().as_slice()
    }
}

impl<K: Eq + Hash, V: Eq> Eq for IndexMapOrd<K, V> {}

impl<K: PartialOrd + Eq + Hash, V: PartialOrd> PartialOrd for IndexMapOrd<K, V> {
    #[inline]
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        self.iter().partial_cmp(other.iter())
    }
}

impl<K: Ord + Eq + Hash, V: Ord> Ord for IndexMapOrd<K, V> {
    #[inline]
    fn cmp(&self, other: &Self) -> Ordering {
        self.iter().cmp(other.iter())
    }
}

impl<K, V, Q: Hash + Equivalent<K> + ?Sized> Index<&Q> for IndexMapOrd<K, V> {
    type Output = V;

    #[inline]
    fn index(&self, key: &Q) -> &V {
        self.0.index(key)
    }
}

impl<K, V, Q: Hash + Equivalent<K> + ?Sized> IndexMut<&Q> for IndexMapOrd<K, V> {
    #[inline]
    fn index_mut(&mut self, key: &Q) -> &mut V {
        self.0.index_mut(key)
    }
}

impl<K, V> Index<usize> for IndexMapOrd<K, V> {
    type Output = V;

    #[inline]
    fn index(&self, index: usize) -> &V {
        self.0.index(index)
    }
}

impl<K, V> IndexMut<usize> for IndexMapOrd<K, V> {
    #[inline]
    fn index_mut(&mut self, index: usize) -> &mut V {
        self.0.index_mut(index)
    }
}

impl<'a, K, V> IntoIterator for &'a IndexMapOrd<K, V> {
    type Item = (&'a K, &'a V);
    type IntoIter = indexmap::map::Iter<'a, K, V>;

    #[inline]
    fn into_iter(self) -> Self::IntoIter {
        self.0.iter()
    }
}

impl<'a, K, V> IntoIterator for &'a mut IndexMapOrd<K, V> {
    type Item = (&'a K, &'a mut V);
    type IntoIter = indexmap::map::IterMut<'a, K, V>;

    #[inline]
    fn into_iter(self) -> Self::IntoIter {
        self.0.iter_mut()
    }
}

impl<K, V> IntoIterator for IndexMapOrd<K, V> {
    type Item = (K, V);
    type IntoIter = indexmap::map::IntoIter<K, V>;

    #[inline]
    fn into_iter(self) -> Self::IntoIter {
        self.0.into_iter()
    }
}

impl<K: Eq + Hash, V> FromIterator<(K, V)> for IndexMapOrd<K, V> {
    #[inline]
    fn from_iter<I: IntoIterator<Item = (K, V)>>(iterable: I) -> Self {
        Self(IndexMap::from_iter(iterable))
    }
}

impl<K: Eq + Hash, V> MapLike<K, V> for IndexMapOrd<K, V> {
    type It<'a> = indexmap::map::Iter<'a, K, V> where K: 'a, V: 'a;

    #[inline]
    fn get(&self, k: &K) -> Option<&V> {
        self.0.get(k)
    }

    #[inline]
    fn insert(&mut self, k: K, v: V) {
        self.0.insert(k, v);
    }

    #[inline]
    fn contains_key(&self, k: &K) -> bool {
        self.0.contains_key(k)
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
