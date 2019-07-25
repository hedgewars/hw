use std::{collections::BinaryHeap, num::NonZeroU16};

pub type GearId = NonZeroU16;
pub trait GearData {}

pub trait GearDataProcessor<T: GearData> {
    fn add(&mut self, gear_id: GearId, gear_data: T);
    fn remove(&mut self, gear_id: GearId);
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
