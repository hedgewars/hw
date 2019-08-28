use fpnum::FPNum;
use std::{collections::BinaryHeap, num::NonZeroU16, ops::Add};

pub type GearId = NonZeroU16;

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
