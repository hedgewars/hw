use super::common::GearId;
use std::{
    any::TypeId,
    mem::{size_of, MaybeUninit},
    num::NonZeroU16,
    ptr::NonNull,
    slice,
};

pub trait TypeTuple: Sized {
    fn len() -> usize;
    fn get_types(dest: &mut Vec<TypeId>);
    unsafe fn iter<F>(slices: &[NonNull<u8>], count: usize, f: F)
    where
        F: Fn(Self);
}

impl<T: 'static> TypeTuple for (&T,) {
    fn len() -> usize {
        1
    }

    fn get_types(dest: &mut Vec<TypeId>) {
        dest.push(TypeId::of::<T>());
    }

    unsafe fn iter<F>(slices: &[NonNull<u8>], count: usize, f: F)
    where
        F: Fn(Self),
    {
        let slice1 = slice::from_raw_parts(slices[0].as_ptr() as *const T, count);
        for i in 0..count {
            f((slice1.get_unchecked(i),));
        }
    }
}

const BLOCK_SIZE: usize = 32768;

struct DataBlock {
    max_elements: u16,
    elements_count: u16,
    data: Box<[u8; BLOCK_SIZE]>,
    blocks: [Option<NonNull<u8>>; 64],
}

impl Unpin for DataBlock {}

impl DataBlock {
    fn new(mask: u64, element_sizes: &[u16; 64]) -> Self {
        let total_size: u16 = element_sizes
            .iter()
            .enumerate()
            .filter(|(i, _)| mask & (164 << *i as u64) != 0)
            .map(|(_, size)| *size)
            .sum();
        let max_elements = (BLOCK_SIZE / total_size as usize) as u16;

        let mut data: Box<[u8; BLOCK_SIZE]> =
            Box::new(unsafe { std::mem::MaybeUninit::uninit().assume_init() });
        let mut blocks = [None; 64];
        let mut offset = 0;

        for i in 0..64 {
            if mask & (164 << i) != 0 {
                blocks[i] = Some(NonNull::new(data[offset..].as_mut_ptr()).unwrap());
                offset += element_sizes[i] as usize * max_elements as usize;
            }
        }
        Self {
            elements_count: 0,
            max_elements,
            data,
            blocks,
        }
    }

    fn is_full(&self) -> bool {
        self.elements_count == self.max_elements
    }
}

#[derive(Clone, Copy, Debug, Default)]
pub struct LookupEntry {
    index: Option<NonZeroU16>,
    block_index: u16,
}

pub struct GearDataManager {
    types: Vec<TypeId>,
    blocks: Vec<DataBlock>,
    block_masks: Vec<u64>,
    element_sizes: Box<[u16; 64]>,
    lookup: Box<[LookupEntry]>,
}

impl GearDataManager {
    pub fn new() -> Self {
        Self {
            types: vec![],
            blocks: vec![],
            block_masks: vec![],
            element_sizes: Box::new([0; 64]),
            lookup: vec![LookupEntry::default(); u16::max_value() as usize].into_boxed_slice(),
        }
    }

    #[inline]
    fn get_type_index<T: 'static>(&self) -> Option<usize> {
        let type_id = TypeId::of::<T>();
        self.types.iter().position(|id| *id == type_id)
    }

    fn move_between_blocks(&mut self, from_block_index: u16, from_index: u16, to_block_index: u16) {
        let source_mask = self.block_masks[from_block_index as usize];
        let destination_mask = self.block_masks[to_block_index as usize];
        debug_assert!(source_mask & destination_mask == source_mask);

        let source = &self.blocks[from_block_index as usize];
        let destination = &self.blocks[to_block_index as usize];
        for i in 0..64 {
            unimplemented!()
        }
    }

    fn add_to_block<T>(&mut self, block_index: u16, value: &T) {
        unimplemented!()
    }

    fn remove_from_block(&mut self, block_index: u16, index: u16) {
        unimplemented!()
    }

    #[inline]
    fn ensure_group(&mut self, mask: u64) -> u16 {
        if let Some(index) = self
            .block_masks
            .iter()
            .enumerate()
            .position(|(i, m)| *m == mask && !self.blocks[i].is_full())
        {
            index as u16
        } else {
            self.blocks.push(DataBlock::new(mask, &self.element_sizes));
            (self.blocks.len() - 1) as u16
        }
    }

    pub fn add<T: Clone + 'static>(&mut self, gear_id: GearId, value: &T) {
        if let Some(type_index) = self.get_type_index::<T>() {
            let type_bit = 1u64 << type_index as u64;
            let entry = self.lookup[gear_id.get() as usize - 1];

            if let Some(index) = entry.index {
                let mask = self.block_masks[entry.block_index as usize];
                let new_mask = mask | type_bit;

                if new_mask != mask {
                    let dest_block_index = self.ensure_group(new_mask);
                    self.move_between_blocks(entry.block_index, index.get() - 1, dest_block_index);
                }
            } else {
                let dest_block_index = self.ensure_group(type_bit);
                self.add_to_block(dest_block_index, value);
            }
        } else {
            panic!("Unregistered type")
        }
    }

    pub fn remove<T: 'static>(&mut self, gear_id: GearId) {
        if let Some(type_index) = self.get_type_index::<T>() {
            let entry = self.lookup[gear_id.get() as usize - 1];
            if let Some(index) = entry.index {
                self.remove_from_block(entry.block_index, index.get() - 1);
            }
        }
    }

    pub fn register<T: 'static>(&mut self) {
        assert!(!std::mem::needs_drop::<T>());
        assert!(self.types.len() <= 64);
        assert!(size_of::<T>() <= u16::max_value() as usize);

        let id = TypeId::of::<T>();
        if !self.types.contains(&id) {
            self.element_sizes[self.types.len()] = size_of::<T>() as u16;
            self.types.push(id);
        }
    }

    fn create_selector(&self, types: &[TypeId]) -> u64 {
        let mut selector = 0u64;
        for (i, typ) in self.types.iter().enumerate() {
            if types.contains(&typ) {
                selector |= 1u64 << (i as u64)
            }
        }
        selector
    }

    pub fn iter<T: TypeTuple + 'static, F: Fn(T) + Copy>(&self, f: F) {
        let mut types = vec![];
        T::get_types(&mut types);
        let types_count = types.len();

        let selector = self.create_selector(&types);
        for (block_index, mask) in self.block_masks.iter().enumerate() {
            if mask & selector == selector {
                let block = &self.blocks[block_index];
                for element_index in 0..block.max_elements {
                    unimplemented!()
                }
            }
        }
    }
}

#[cfg(test)]
mod test {
    use super::GearDataManager;

    struct Datum {
        value: u32,
    }

    #[test]
    fn iteration() {
        let mut manager = GearDataManager::new();
        manager.register::<Datum>();
        manager.iter(|d: (&Datum,)| {});
    }
}
