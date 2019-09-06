use super::common::GearId;
use std::{
    any::TypeId,
    fmt::{Debug, Error, Formatter},
    marker::PhantomData,
    mem::{size_of, MaybeUninit},
    num::NonZeroU16,
    ptr::{copy_nonoverlapping, null_mut, NonNull},
    slice,
};

pub trait TypeTuple: Sized {
    fn get_types(types: &mut Vec<TypeId>);
}

impl TypeTuple for () {
    fn get_types(_types: &mut Vec<TypeId>) {}
}

impl<T: 'static> TypeTuple for &T {
    fn get_types(types: &mut Vec<TypeId>) {
        types.push(TypeId::of::<T>());
    }
}

pub trait TypeIter: TypeTuple {
    unsafe fn iter<F: FnMut(GearId, Self)>(slices: &[*mut u8], count: usize, f: F);
}

macro_rules! type_tuple_impl {
    ($($n: literal: $t: ident),+) => {
        impl<$($t: 'static),+> TypeTuple for ($(&$t),+,) {
            fn get_types(types: &mut Vec<TypeId>) {
                $(types.push(TypeId::of::<$t>()));+
            }
        }

        impl<$($t: 'static),+> TypeIter for ($(&$t),+,) {
            unsafe fn iter<F: FnMut(GearId, Self)>(slices: &[*mut u8], count: usize, mut f: F) {
                for i in 0..count {
                    f(*(*slices.get_unchecked(0) as *const GearId).add(i),
                      ($(&*(*slices.get_unchecked($n + 1) as *mut $t).add(i)),+,));
                }
            }
        }

        impl<$($t: 'static),+> TypeTuple for ($(&mut $t),+,) {
            fn get_types(types: &mut Vec<TypeId>) {
                $(types.push(TypeId::of::<$t>()));+
            }
        }

        impl<$($t: 'static),+> TypeIter for ($(&mut $t),+,) {
            unsafe fn iter<F: FnMut(GearId, Self)>(slices: &[*mut u8], count: usize, mut f: F) {
                for i in 0..count {
                    f(*(*slices.get_unchecked(0) as *const GearId).add(i),
                      ($(&mut *(*slices.get_unchecked($n + 1) as *mut $t).add(i)),+,));
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
    element_sizes: Box<[u16]>,
}

impl Unpin for DataBlock {}

impl Debug for DataBlock {
    fn fmt(&self, f: &mut Formatter) -> Result<(), Error> {
        write!(
            f,
            "Block ({}/{}) {{\n",
            self.elements_count, self.max_elements
        )?;
        write!(f, "\tIDs: [")?;
        let id_slice = unsafe {
            slice::from_raw_parts(
                self.data.as_ptr() as *const GearId,
                self.elements_count as usize,
            )
        };
        for gear_id in id_slice {
            write!(f, "{}, ", gear_id)?;
        }
        write!(f, "]\n")?;
        for type_index in 0..self.element_sizes.len() {
            if let Some(ptr) = self.component_blocks[type_index] {
                write!(f, "\tC{}: [", type_index)?;
                let slice = unsafe {
                    slice::from_raw_parts(
                        ptr.as_ptr(),
                        (self.elements_count * self.element_sizes[type_index]) as usize,
                    )
                };
                for byte in slice {
                    write!(f, "{}, ", byte)?;
                }
                write!(f, "]\n")?;
            }
        }
        write!(f, "}}\n")
    }
}

impl DataBlock {
    fn new(mask: u64, element_sizes: &[u16]) -> Self {
        let total_size: u16 = element_sizes
            .iter()
            .enumerate()
            .filter(|(i, _)| mask & (1 << *i as u64) != 0)
            .map(|(_, size)| *size)
            .sum();
        let max_elements = (BLOCK_SIZE / (total_size as usize + size_of::<GearId>())) as u16;

        let mut data: Box<[u8; BLOCK_SIZE]> =
            Box::new(unsafe { MaybeUninit::uninit().assume_init() });
        let mut blocks = [None; 64];
        let mut offset = size_of::<GearId>() * max_elements as usize;

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
            element_sizes: Box::from(element_sizes),
        }
    }

    fn gear_ids(&self) -> &[GearId] {
        unsafe {
            slice::from_raw_parts(
                self.data.as_ptr() as *const GearId,
                self.max_elements as usize,
            )
        }
    }

    fn gear_ids_mut(&mut self) -> &mut [GearId] {
        unsafe {
            slice::from_raw_parts_mut(
                self.data.as_mut_ptr() as *mut GearId,
                self.max_elements as usize,
            )
        }
    }

    fn is_full(&self) -> bool {
        self.elements_count == self.max_elements
    }
}

#[derive(Clone, Copy, Debug, Default)]
struct LookupEntry {
    index: Option<NonZeroU16>,
    block_index: u16,
}

impl LookupEntry {
    fn new(block_index: u16, index: u16) -> Self {
        Self {
            index: unsafe { Some(NonZeroU16::new_unchecked(index + 1)) },
            block_index,
        }
    }
}

#[derive(Copy, Clone, Eq, PartialEq, Debug)]
struct BlockMask {
    type_mask: u64,
    tag_mask: u64,
}

impl BlockMask {
    #[inline]
    fn new(type_mask: u64, tag_mask: u64) -> Self {
        Self {
            type_mask,
            tag_mask,
        }
    }

    #[inline]
    fn with_type(&self, type_bit: u64) -> Self {
        Self::new(self.type_mask | type_bit, self.tag_mask)
    }

    #[inline]
    fn with_tag(&self, tag_bit: u64) -> Self {
        Self::new(self.type_mask, self.tag_mask | tag_bit)
    }
}

pub struct GearDataManager {
    types: Vec<TypeId>,
    tags: Vec<TypeId>,
    blocks: Vec<DataBlock>,
    block_masks: Vec<BlockMask>,
    element_sizes: Box<[u16; 64]>,
    lookup: Box<[LookupEntry]>,
}

impl GearDataManager {
    pub fn new() -> Self {
        Self {
            types: Vec::with_capacity(64),
            tags: Vec::with_capacity(64),
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

    #[inline]
    fn get_tag_index<T: 'static>(&self) -> Option<usize> {
        let type_id = TypeId::of::<T>();
        self.tags.iter().position(|id| *id == type_id)
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
        debug_assert!(src_mask.type_mask & dest_mask.type_mask == src_mask.type_mask);

        let src_block = &self.blocks[src_block_index as usize];
        let dest_block = &self.blocks[dest_block_index as usize];
        debug_assert!(src_index < src_block.elements_count);
        debug_assert!(!dest_block.is_full());

        let dest_index = dest_block.elements_count;
        for i in 0..self.types.len() {
            if src_mask.type_mask & (1 << i as u64) != 0 {
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

        let src_block = &mut self.blocks[src_block_index as usize];
        let gear_id = src_block.gear_ids()[src_index as usize];

        if src_index < src_block.elements_count - 1 {
            let relocated_index = src_block.elements_count as usize - 1;
            let gear_ids = src_block.gear_ids_mut();
            let relocated_id = gear_ids[relocated_index];

            gear_ids[src_index as usize] = relocated_id;
            self.lookup[relocated_id.get() as usize - 1] =
                LookupEntry::new(src_block_index, src_index);
        }
        src_block.elements_count -= 1;

        let dest_block = &mut self.blocks[dest_block_index as usize];
        let dest_index = dest_block.elements_count;

        dest_block.gear_ids_mut()[dest_index as usize] = gear_id;
        self.lookup[gear_id.get() as usize - 1] = LookupEntry::new(dest_block_index, dest_index);
        dest_block.elements_count += 1;
        dest_block.elements_count - 1
    }

    fn add_to_block<T: Clone>(&mut self, gear_id: GearId, block_index: u16, value: &T) {
        debug_assert!(
            self.block_masks[block_index as usize]
                .type_mask
                .count_ones()
                == 1
        );

        let block = &mut self.blocks[block_index as usize];
        debug_assert!(block.elements_count < block.max_elements);

        unsafe {
            *(block.component_blocks[0].unwrap().as_ptr() as *mut T)
                .add(block.elements_count as usize) = value.clone();
        };

        let index = block.elements_count;
        self.lookup[gear_id.get() as usize - 1] = LookupEntry::new(block_index, index);
        block.gear_ids_mut()[index as usize] = gear_id;
        block.elements_count += 1;
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

        self.lookup[block.gear_ids()[index as usize].get() as usize - 1] = LookupEntry::default();
        if index < block.elements_count - 1 {
            let relocated_index = block.elements_count as usize - 1;
            let gear_ids = block.gear_ids_mut();

            gear_ids[index as usize] = gear_ids[relocated_index];
            self.lookup[gear_ids[relocated_index].get() as usize - 1] =
                LookupEntry::new(block_index, index);
        }
        block.elements_count -= 1;
    }

    fn write_component<T: Clone>(
        &mut self,
        block_index: u16,
        index: u16,
        type_index: usize,
        value: &T,
    ) {
        debug_assert!(type_index < self.types.len());
        let block = &mut self.blocks[block_index as usize];
        debug_assert!(index < block.elements_count);

        unsafe {
            *(block.component_blocks[type_index].unwrap().as_ptr() as *mut T).add(index as usize) =
                value.clone();
        };
    }

    #[inline]
    fn ensure_block(&mut self, mask: BlockMask) -> u16 {
        if let Some(index) = self
            .block_masks
            .iter()
            .enumerate()
            .position(|(i, m)| *m == mask && !self.blocks[i].is_full())
        {
            index as u16
        } else {
            self.blocks.push(DataBlock::new(
                mask.type_mask,
                &self.element_sizes[0..self.types.len()],
            ));
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
                let new_mask = mask.with_type(type_bit);

                if new_mask != mask {
                    let dest_block_index = self.ensure_block(new_mask);
                    let dest_index = self.move_between_blocks(
                        entry.block_index,
                        index.get() - 1,
                        dest_block_index,
                    );
                    self.write_component(dest_block_index, dest_index, type_index, value);
                }
            } else {
                let dest_block_index = self.ensure_block(BlockMask::new(type_bit, 0));
                self.add_to_block(gear_id, dest_block_index, value);
            }
        } else {
            panic!("Unregistered type")
        }
    }

    pub fn add_tag<T: 'static>(&mut self, gear_id: GearId) {
        if let Some(tag_index) = self.get_tag_index::<T>() {
            let tag_bit = 1 << tag_index as u64;
            let entry = self.lookup[gear_id.get() as usize - 1];

            if let Some(index) = entry.index {
                let mask = self.block_masks[entry.block_index as usize];
                let new_mask = mask.with_tag(tag_bit);

                if new_mask != mask {
                    let dest_block_index = self.ensure_block(new_mask);
                    self.move_between_blocks(entry.block_index, index.get() - 1, dest_block_index);
                }
            } else {
                panic!("Cannot tag a gear with no data")
            }
        } else {
            panic!("Unregistered tag")
        }
    }

    pub fn remove<T: 'static>(&mut self, gear_id: GearId) {
        if let Some(type_index) = self.get_type_index::<T>() {
            let entry = self.lookup[gear_id.get() as usize - 1];
            if let Some(index) = entry.index {
                let mut dest_mask = self.block_masks[entry.block_index as usize];
                dest_mask.type_mask &= !(1 << type_index as u64);

                if dest_mask.type_mask == 0 {
                    self.remove_from_block(entry.block_index, index.get() - 1);
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
    }

    pub fn register<T: 'static>(&mut self) {
        debug_assert!(!std::mem::needs_drop::<T>());
        debug_assert!(size_of::<T>() <= u16::max_value() as usize);

        let id = TypeId::of::<T>();
        if size_of::<T>() == 0 {
            if !self.tags.contains(&id) {
                debug_assert!(self.tags.len() <= 64);
                self.tags.push(id)
            }
        } else {
            if !self.types.contains(&id) {
                debug_assert!(self.types.len() <= 64);
                self.element_sizes[self.types.len()] = size_of::<T>() as u16;
                self.types.push(id);
            }
        }
    }

    fn run_impl<T: TypeIter + 'static, F: FnMut(GearId, T)>(
        &mut self,
        type_selector: u64,
        included_tags: u64,
        type_indices: &[i8],
        mut f: F,
    ) {
        let mut slices = vec![null_mut(); type_indices.len() + 1];

        for (block_index, mask) in self.block_masks.iter().enumerate() {
            if mask.type_mask & type_selector == type_selector
                && mask.tag_mask & included_tags == included_tags
            {
                let block = &mut self.blocks[block_index];
                slices[0] = block.data.as_mut_ptr();

                for (arg_index, type_index) in type_indices.iter().cloned().enumerate() {
                    slices[arg_index as usize + 1] = block.component_blocks[type_index as usize]
                        .unwrap()
                        .as_ptr()
                }

                unsafe {
                    T::iter(&slices[..], block.elements_count as usize, |id, x| f(id, x));
                }
            }
        }
    }

    pub fn iter<T: TypeIter + 'static>(&mut self) -> DataIterator<T> {
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
        DataIterator::new(self, selector, type_indices)
    }
}

pub struct DataIterator<'a, T> {
    data: &'a mut GearDataManager,
    types: u64,
    type_indices: Vec<i8>,
    tags: u64,
    phantom_types: PhantomData<T>,
}

impl<'a, T: TypeIter + 'static> DataIterator<'a, T> {
    fn new(
        data: &'a mut GearDataManager,
        types: u64,
        type_indices: Vec<i8>,
    ) -> DataIterator<'a, T> {
        Self {
            data,
            types,
            type_indices,
            tags: 0,
            phantom_types: PhantomData,
        }
    }

    pub fn with_tags<U: TypeTuple + 'static>(self) -> Self {
        let mut tag_types = Vec::with_capacity(64);
        U::get_types(&mut tag_types);
        let mut tags = 0;

        for (i, tag) in self.data.tags.iter().enumerate() {
            if tag_types.contains(tag) {
                tags |= 1 << i as u64;
            }
        }
        Self { tags, ..self }
    }

    #[inline]
    pub fn run<F: FnMut(T)>(&mut self, mut f: F) {
        self.run_id(|_, x| f(x))
    }

    #[inline]
    pub fn run_id<F: FnMut(GearId, T)>(&mut self, f: F) {
        self.data
            .run_impl(self.types, self.tags, &self.type_indices, f);
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
    struct Tag;

    #[test]
    fn single_component_iteration() {
        let mut manager = GearDataManager::new();
        manager.register::<Datum>();
        for i in 1..=5 {
            manager.add(GearId::new(i as u16).unwrap(), &Datum { value: i });
        }

        let mut sum = 0;
        manager.iter().run(|(d,): (&Datum,)| sum += d.value);
        assert_eq!(sum, 15);

        manager.iter().run(|(d,): (&mut Datum,)| d.value += 1);
        manager.iter().run(|(d,): (&Datum,)| sum += d.value);
        assert_eq!(sum, 35);
    }

    #[test]
    fn tagged_component_iteration() {
        let mut manager = GearDataManager::new();
        manager.register::<Datum>();
        manager.register::<Tag>();
        for i in 1..=10 {
            let gear_id = GearId::new(i as u16).unwrap();
            manager.add(gear_id, &Datum { value: i });
        }

        for i in 1..=10 {
            let gear_id = GearId::new(i as u16).unwrap();
            if i & 1 == 0 {
                manager.add_tag::<Tag>(gear_id);
            }
        }

        let mut sum = 0;
        manager.iter().run(|(d,): (&Datum,)| sum += d.value);
        assert_eq!(sum, 55);

        let mut tag_sum = 0;
        manager
            .iter()
            .with_tags::<&Tag>()
            .run(|(d,): (&Datum,)| tag_sum += d.value);
        assert_eq!(tag_sum, 30);
    }
}
