use std::{
    iter,
    ops::{Index, IndexMut},
};

pub struct IndexSlab<T> {
    data: Vec<Option<T>>,
}

impl<T> IndexSlab<T> {
    pub fn new() -> Self {
        Self { data: Vec::new() }
    }

    pub fn with_capacity(capacity: usize) -> Self {
        Self {
            data: Vec::with_capacity(capacity),
        }
    }

    pub fn insert(&mut self, index: usize, value: T) {
        if index >= self.data.len() {
            self.data.reserve(index - self.data.len() + 1);
            self.data.extend((self.data.len()..index).map(|_| None));
            self.data.push(Some(value))
        } else {
            self.data[index] = Some(value);
        }
    }

    pub fn contains(&self, index: usize) -> bool {
        self.data.get(index).and_then(|x| x.as_ref()).is_some()
    }

    pub fn remove(&mut self, index: usize) {
        if let Some(x) = self.data.get_mut(index) {
            *x = None
        }
    }

    pub fn iter(&self) -> impl Iterator<Item = (usize, &T)> {
        self.data
            .iter()
            .enumerate()
            .filter_map(|(index, opt)| opt.as_ref().and_then(|x| Some((index, x))))
    }

    pub fn iter_mut(&mut self) -> impl Iterator<Item = (usize, &mut T)> {
        self.data
            .iter_mut()
            .enumerate()
            .filter_map(|(index, opt)| opt.as_mut().and_then(|x| Some((index, x))))
    }
}

impl<T> Index<usize> for IndexSlab<T> {
    type Output = T;

    fn index(&self, index: usize) -> &Self::Output {
        self.data[index].as_ref().unwrap()
    }
}

impl<T> IndexMut<usize> for IndexSlab<T> {
    fn index_mut(&mut self, index: usize) -> &mut Self::Output {
        self.data[index].as_mut().unwrap()
    }
}
