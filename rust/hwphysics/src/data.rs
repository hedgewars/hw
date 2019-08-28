use super::common::GearId;
use std::{
    any::TypeId,
    mem::{size_of, MaybeUninit},
    num::NonZeroU16,
    ptr::{copy_nonoverlapping, null_mut, NonNull},
    slice,
};

pub trait TypeTuple: Sized {
    fn len() -> usize;
    fn get_types(types: &mut Vec<TypeId>);
    unsafe fn iter<F: FnMut(Self)>(slices: &[*mut u8], count: usize, mut f: F);
}

macro_rules! type_tuple_impl {
    ($($n: literal: $t: ident),+) => {
        impl<$($t: 'static),+> TypeTuple for ($(&$t),+,) {
            fn len() -> usize {
                [$({TypeId::of::<$t>(); 1}),+].iter().sum()
            }

            fn get_types(types: &mut Vec<TypeId>) {
                $(types.push(TypeId::of::<$t>()));+
            }

            unsafe fn iter<F: FnMut(Self)>(slices: &[*mut u8], count: usize, mut f: F) {
                for i in 0..count {
                    unsafe {
                        f(($(&*(*slices.get_unchecked($n) as *mut $t).add(i)),+,));
                    }
                }
            }
        }

        impl<$($t: 'static),+> TypeTuple for ($(&mut $t),+,) {
            fn len() -> usize {
                [$({TypeId::of::<$t>(); 1}),+].iter().sum()
            }

            fn get_types(types: &mut Vec<TypeId>) {
                $(types.push(TypeId::of::<$t>()));+
            }

            unsafe fn iter<F: FnMut(Self)>(slices: &[*mut u8], count: usize, mut f: F) {
                for i in 0..count {
                    unsafe {
                        f(($(&mut *(*slices.get_unchecked($n) as *mut $t).add(i)),+,));
                    }
                }
            }
        }
    }
}

type_tuple_impl!(0: A);
type_tuple_impl!(0: A, 1: B);
type_tuple_impl!(0: A, 1: B, 2: C);
type_tuple_impl!(0: A, 1: B, 2: C, 3: D);
type_tuple_impl!(0: A, 1: B, 2: C, 3: D, 4: E);

const BLOCK_SIZE: usize = 32768;

struct DataBlock {
    max_elements: u16,
    elements_count: u16,
    data: Box<[u8; BLOCK_SIZE]>,
    component_blocks: [Option<NonNull<u8>>; 64],
}

impl Unpin for DataBlock {}

impl DataBlock {
    fn new(mask: u64, element_sizes: &[u16; 64]) -> Self {
        let total_size: u16 = element_sizes
            .iter()
            .enumerate()
            .filter(|(i, _)| mask & (1 << *i as u64) != 0)
            .map(|(_, size)| *size)
            .sum();
        let max_elements = (BLOCK_SIZE / total_size as usize) as u16;

        let mut data: Box<[u8; BLOCK_SIZE]> =
            Box::new(unsafe { MaybeUninit::uninit().assume_init() });
        let mut blocks = [None; 64];
        let mut offset = 0;

        for i in 0..element_sizes.len() {
            if mask & (1 << i as u64) != 0 {
                blocks[i] = Some(NonNull::new(data[offset..].as_mut_ptr()).unwrap());
                offset += element_sizes[i] as usize * max_elements as usize;
            }
        }
        Self {
            elements_count: 0,
            max_elements,
            data,
            component_blocks: blocks,
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

    fn move_between_blocks(
        &mut self,
        src_block_index: u16,
        src_index: u16,
        dest_block_index: u16,
    ) -> u16 {
        debug_assert!(src_block_index != dest_block_index);
        let src_mask = self.block_masks[src_block_index as usize];
        let dest_mask = self.block_masks[dest_block_index as usize];
        debug_assert!(src_mask & dest_mask == src_mask);

        let src_block = &self.blocks[src_block_index as usize];
        let dest_block = &self.blocks[dest_block_index as usize];
        debug_assert!(src_index < src_block.elements_count);
        debug_assert!(!dest_block.is_full());

        let dest_index = dest_block.elements_count;
        for i in 0..self.types.len() {
            if src_mask & (1 << i as u64) != 0 {
                let size = self.element_sizes[i];
                let src_ptr = src_block.component_blocks[i].unwrap().as_ptr();
                let dest_ptr = dest_block.component_blocks[i].unwrap().as_ptr();
                unsafe {
                    copy_nonoverlapping(
                        src_ptr.add((src_index * size) as usize),
                        dest_ptr.add((dest_index * size) as usize),
                        size as usize,
                    );
                    if src_index < src_block.elements_count - 1 {
                        copy_nonoverlapping(
                            src_ptr.add((size * (src_block.elements_count - 1)) as usize),
                            src_ptr.add((size * src_index) as usize),
                            size as usize,
                        );
                    }
                }
            }
        }
        self.blocks[src_block_index as usize].elements_count -= 1;
        let dest_block = &mut self.blocks[dest_block_index as usize];
        dest_block.elements_count += 1;
        dest_block.elements_count - 1
    }

    fn add_to_block<T: Clone>(&mut self, block_index: u16, value: &T) -> u16 {
        debug_assert!(self.block_masks[block_index as usize].count_ones() == 1);

        let block = &mut self.blocks[block_index as usize];
        debug_assert!(block.elements_count < block.max_elements);

        unsafe {
            let slice = slice::from_raw_parts_mut(
                block.data.as_mut_ptr() as *mut T,
                block.max_elements as usize,
            );
            *slice.get_unchecked_mut(block.elements_count as usize) = value.clone();
        };
        block.elements_count += 1;
        block.elements_count - 1
    }

    fn remove_from_block(&mut self, block_index: u16, index: u16) {
        let block = &mut self.blocks[block_index as usize];
        debug_assert!(index < block.elements_count);

        for (i, size) in self.element_sizes.iter().cloned().enumerate() {
            if index < block.elements_count - 1 {
                if let Some(ptr) = block.component_blocks[i] {
                    unsafe {
                        copy_nonoverlapping(
                            ptr.as_ptr()
                                .add((size * (block.elements_count - 1)) as usize),
                            ptr.as_ptr().add((size * index) as usize),
                            size as usize,
                        );
                    }
                }
            }
        }
        block.elements_count -= 1;
    }

    #[inline]
    fn ensure_block(&mut self, mask: u64) -> u16 {
        if let Some(index) = self
            .block_masks
            .iter()
            .enumerate()
            .position(|(i, m)| *m == mask && !self.blocks[i].is_full())
        {
            index as u16
        } else {
            self.blocks.push(DataBlock::new(mask, &self.element_sizes));
            self.block_masks.push(mask);
            (self.blocks.len() - 1) as u16
        }
    }

    pub fn add<T: Clone + 'static>(&mut self, gear_id: GearId, value: &T) {
        if let Some(type_index) = self.get_type_index::<T>() {
            let type_bit = 1 << type_index as u64;
            let entry = self.lookup[gear_id.get() as usize - 1];

            if let Some(index) = entry.index {
                let mask = self.block_masks[entry.block_index as usize];
                let new_mask = mask | type_bit;

                if new_mask != mask {
                    let dest_block_index = self.ensure_block(new_mask);
                    let dest_index = self.move_between_blocks(
                        entry.block_index,
                        index.get() - 1,
                        dest_block_index,
                    );
                    self.lookup[gear_id.get() as usize - 1] = LookupEntry {
                        index: unsafe {
                            Some(NonZeroU16::new_unchecked(dest_index.saturating_add(1)))
                        },
                        block_index: dest_block_index,
                    }
                }
            } else {
                let dest_block_index = self.ensure_block(type_bit);
                let index = self.add_to_block(dest_block_index, value);
                self.lookup[gear_id.get() as usize - 1] = LookupEntry {
                    index: unsafe { Some(NonZeroU16::new_unchecked(index.saturating_add(1))) },
                    block_index: dest_block_index,
                }
            }
        } else {
            panic!("Unregistered type")
        }
    }

    pub fn remove<T: 'static>(&mut self, gear_id: GearId) {
        if let Some(type_index) = self.get_type_index::<T>() {
            let entry = self.lookup[gear_id.get() as usize - 1];
            if let Some(index) = entry.index {
                let dest_mask =
                    self.block_masks[entry.block_index as usize] & !(1 << type_index as u64);

                if dest_mask == 0 {
                    self.remove_all(gear_id)
                } else {
                    let dest_block_index = self.ensure_block(dest_mask);
                    self.move_between_blocks(entry.block_index, index.get() - 1, dest_block_index);
                }
            }
        } else {
            panic!("Unregistered type")
        }
    }

    pub fn remove_all(&mut self, gear_id: GearId) {
        let entry = self.lookup[gear_id.get() as usize - 1];
        if let Some(index) = entry.index {
            self.remove_from_block(entry.block_index, index.get() - 1);
        }
        self.lookup[gear_id.get() as usize - 1] = LookupEntry {
            index: None,
            block_index: 0,
        }
    }

    pub fn register<T: 'static>(&mut self) {
        debug_assert!(!std::mem::needs_drop::<T>());
        debug_assert!(self.types.len() <= 64);
        debug_assert!(size_of::<T>() <= u16::max_value() as usize);

        let id = TypeId::of::<T>();
        if !self.types.contains(&id) {
            self.element_sizes[self.types.len()] = size_of::<T>() as u16;
            self.types.push(id);
        }
    }

    pub fn iter<T: TypeTuple + 'static, F: FnMut(T)>(&self, mut f: F) {
        let mut arg_types = Vec::with_capacity(64);
        T::get_types(&mut arg_types);

        let mut type_indices = vec![-1i8; arg_types.len()];
        let mut selector = 0u64;

        for (arg_index, type_id) in arg_types.iter().enumerate() {
            match self.types.iter().position(|t| t == type_id) {
                Some(i) if selector & (1 << i as u64) != 0 => panic!("Duplicate type"),
                Some(i) => {
                    type_indices[arg_index] = i as i8;
                    selector |= 1 << i as u64;
                }
                None => panic!("Unregistered type"),
            }
        }
        let mut slices = vec![null_mut(); arg_types.len()];

        for (block_index, mask) in self.block_masks.iter().enumerate() {
            if mask & selector == selector {
                let block = &self.blocks[block_index];
                block.elements_count;
                for (arg_index, type_index) in type_indices.iter().cloned().enumerate() {
                    slices[arg_index as usize] = block.component_blocks[type_index as usize]
                        .unwrap()
                        .as_ptr()
                }

                unsafe {
                    T::iter(&slices[..], block.elements_count as usize, |x| f(x));
                }
            }
        }
    }
}

#[cfg(test)]
mod test {
    use super::{super::common::GearId, GearDataManager};

    #[derive(Clone)]
    struct Datum {
        value: u32,
    }

    #[derive(Clone)]
    struct Tag {
        nothing: u8,
    }

    #[test]
    fn single_component_iteration() {
        let mut manager = GearDataManager::new();
        manager.register::<Datum>();
        for i in 1..=5 {
            manager.add(GearId::new(i as u16).unwrap(), &Datum { value: i });
        }

        let mut sum = 0;
        manager.iter(|(d,): (&Datum,)| sum += d.value);
        assert_eq!(sum, 15);

        manager.iter(|(d,): (&mut Datum,)| d.value += 1);
        manager.iter(|(d,): (&Datum,)| sum += d.value);
        assert_eq!(sum, 35);
    }

    #[test]
    fn multiple_component_iteration() {
        let mut manager = GearDataManager::new();
        manager.register::<Datum>();
        manager.register::<Tag>();
        for i in 1..=10 {
            let gear_id = GearId::new(i as u16).unwrap();
            manager.add(gear_id, &Datum { value: i });
            if i & 1 == 0 {
                manager.add(gear_id, &Tag { nothing: 0 });
            }
        }

        let mut sum1 = 0;
        let mut sum2 = 0;
        manager.iter(|(d, _): (&Datum, &Tag)| sum1 += d.value);
        manager.iter(|(_, d): (&Tag, &Datum)| sum2 += d.value);
        assert_eq!(sum1, 30);
        assert_eq!(sum2, sum1);
    }
}
