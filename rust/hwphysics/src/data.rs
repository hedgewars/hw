use std::any::{Any, TypeId};

const BLOCK_SIZE: usize = 8192;

pub trait TypeTuple {
    type Storage: Default;

    fn len() -> usize;
    fn get_types(dest: &mut Vec<TypeId>);
}

//TODO macroise this template for tuples up to sufficient size
impl<T: 'static> TypeTuple for (T,) {
    type Storage = (Vec<T>,);

    #[inline]
    fn len() -> usize {
        1
    }

    #[inline]
    fn get_types(dest: &mut Vec<TypeId>) {
        dest.push(TypeId::of::<T>());
    }
}

pub struct GearDataCollection<T: TypeTuple> {
    len: usize,
    blocks: T::Storage,
}

impl<T: TypeTuple> GearDataCollection<T> {
    fn new() -> Self {
        Self {
            len: 0,
            blocks: T::Storage::default(),
        }
    }

    fn iter<F: Fn(T)>(&self, f: F) {}
}

pub struct GearDataGroup {
    group_selector: u64,
    data: Box<dyn Any + 'static>,
}

impl GearDataGroup {
    fn iter() {}
}

pub struct GearDataManager {
    types: Vec<TypeId>,
    groups: Vec<GearDataGroup>,
}

impl GearDataManager {
    pub fn new() -> Self {
        Self {
            types: vec![],
            groups: vec![],
        }
    }

    pub fn register<T: 'static>(&mut self) {
        assert!(self.types.len() <= 64);
        let id = TypeId::of::<T>();
        if !self.types.contains(&id) {
            self.types.push(id);
        }
    }

    fn create_selector(&self, types: &[TypeId]) -> u64 {
        let mut selector = 0u64;
        for (i, typ) in self.types.iter().enumerate() {
            if types.contains(&typ) {
                selector |= 1 << (i as u64)
            }
        }
        selector
    }

    pub fn iter<T: TypeTuple + 'static, F: Fn(T) + Copy>(&self, f: F) {
        let mut types = vec![];
        T::get_types(&mut types);
        let selector = self.create_selector(&types);
        for group in &self.groups {
            if group.group_selector & selector == selector {
                group
                    .data
                    .downcast_ref::<GearDataCollection<T>>()
                    .unwrap()
                    .iter(f);
            }
        }
    }
}
