use fpnum::FPNum;
use std::{
    collections::BinaryHeap,
    num::NonZeroU16,
    ops::{Add, Index, IndexMut},
};

pub type GearId = NonZeroU16;
pub trait GearData {}

#[derive(PartialEq, Eq, PartialOrd, Ord, Clone, Copy, Debug)]
#[repr(transparent)]
pub struct Millis(u32);

impl Millis {
    #[inline]
    pub fn new(value: u32) -> Self {
        Self(value)
    }

    #[inline]
    pub fn get(self) -> u32 {
        self.0
    }

    #[inline]
    pub fn to_fixed(self) -> FPNum {
        FPNum::new(self.0 as i32, 1000)
    }
}

impl Add for Millis {
    type Output = Self;

    fn add(self, rhs: Self) -> Self::Output {
        Self(self.0 + rhs.0)
    }
}

pub trait GearDataProcessor<T: GearData> {
    fn add(&mut self, gear_id: GearId, gear_data: T);
    fn remove(&mut self, gear_id: GearId);
    fn get(&mut self, gear_id: GearId) -> Option<T>;
}

pub trait GearDataAggregator<T: GearData> {
    fn find_processor(&mut self) -> &mut GearDataProcessor<T>;
}

pub struct GearAllocator {
    max_id: u16,
    free_ids: BinaryHeap<GearId>,
}

impl GearAllocator {
    pub fn new() -> Self {
        Self {
            max_id: 0,
            free_ids: BinaryHeap::with_capacity(1024),
        }
    }

    pub fn alloc(&mut self) -> Option<GearId> {
        self.free_ids.pop().or_else(|| {
            self.max_id.checked_add(1).and_then(|new_max_id| {
                self.max_id = new_max_id;
                NonZeroU16::new(new_max_id)
            })
        })
    }

    pub fn free(&mut self, gear_id: GearId) {
        self.free_ids.push(gear_id)
    }
}

#[derive(Clone, Copy, Default)]
pub struct LookupEntry<T> {
    index: Option<NonZeroU16>,
    value: T,
}

impl<T> LookupEntry<T> {
    #[inline]
    pub fn index(&self) -> u16 {
        self.index.map(|i| i.get()).unwrap_or(0) - 1
    }

    #[inline]
    pub fn set_index(&mut self, index: u16) {
        self.index = unsafe { Some(NonZeroU16::new_unchecked(index.saturating_add(1))) };
    }

    #[inline]
    pub fn value(&self) -> &T {
        &self.value
    }

    #[inline]
    pub fn value_mut(&mut self) -> &mut T {
        &mut self.value
    }

    #[inline]
    pub fn set_value(&mut self, value: T) {
        self.value = value;
    }
}

pub struct GearDataLookup<T> {
    lookup: [LookupEntry<T>; u16::max_value() as usize],
}

impl<T: Default + Copy> GearDataLookup<T> {
    pub fn new() -> Self {
        Self {
            lookup: [LookupEntry::<T>::default(); u16::max_value() as usize],
        }
    }
}

impl<T> GearDataLookup<T> {
    pub fn add(&mut self, gear_id: GearId, index: u16, value: T) {
        // All possible Gear IDs are valid indices
        let entry = unsafe { self.lookup.get_unchecked_mut(gear_id.get() as usize - 1) };
        entry.set_index(index);
        entry.set_value(value);
    }

    pub fn get(&self, gear_id: GearId) -> Option<&LookupEntry<T>> {
        // All possible Gear IDs are valid indices
        let entry = unsafe { self.lookup.get_unchecked(gear_id.get() as usize - 1) };
        if let Some(index) = entry.index {
            Some(entry)
        } else {
            None
        }
    }

    pub fn get_mut(&mut self, gear_id: GearId) -> Option<&mut LookupEntry<T>> {
        // All possible Gear IDs are valid indices
        let entry = unsafe { self.lookup.get_unchecked_mut(gear_id.get() as usize - 1) };
        if let Some(index) = entry.index {
            Some(entry)
        } else {
            None
        }
    }
}

impl<T> Index<GearId> for GearDataLookup<T> {
    type Output = LookupEntry<T>;

    fn index(&self, index: GearId) -> &Self::Output {
        self.get(index).unwrap()
    }
}

impl<T> IndexMut<GearId> for GearDataLookup<T> {
    fn index_mut(&mut self, index: GearId) -> &mut Self::Output {
        self.get_mut(index).unwrap()
    }
}
