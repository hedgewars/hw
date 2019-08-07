pub mod collision;
pub mod common;
mod data;
mod grid;
pub mod physics;
pub mod time;

use integral_geometry::Size;
use land2d::Land2D;

use crate::{
    collision::{CollisionData, CollisionProcessor, ContactData},
    common::{GearAllocator, GearData, GearDataAggregator, GearDataProcessor, GearId, Millis},
    physics::{PhysicsData, PhysicsProcessor},
    time::TimeProcessor,
};

pub struct JoinedData {
    gear_id: GearId,
    physics: PhysicsData,
    collision: CollisionData,
    contact: ContactData,
}

pub struct World {
    allocator: GearAllocator,
    physics: PhysicsProcessor,
    collision: CollisionProcessor,
    time: TimeProcessor,
}

macro_rules! processor_map {
    ( $data_type: ident => $field: ident ) => {
        impl GearDataAggregator<$data_type> for World {
            fn find_processor(&mut self) -> &mut GearDataProcessor<$data_type> {
                &mut self.$field
            }
        }
    };
}

processor_map!(PhysicsData => physics);
processor_map!(CollisionData => collision);

impl World {
    pub fn new(world_size: Size) -> Self {
        Self {
            allocator: GearAllocator::new(),
            physics: PhysicsProcessor::new(),
            collision: CollisionProcessor::new(world_size),
            time: TimeProcessor::new(),
        }
    }

    #[inline]
    pub fn new_gear(&mut self) -> Option<GearId> {
        self.allocator.alloc()
    }

    #[inline]
    pub fn delete_gear(&mut self, gear_id: GearId) {
        self.physics.remove(gear_id);
        self.collision.remove(gear_id);
        self.time.cancel(gear_id);
        self.allocator.free(gear_id)
    }

    pub fn step(&mut self, time_step: Millis, land: &Land2D<u32>) {
        let updates = self.physics.process(time_step);
        let collision = self.collision.process(land, &updates);
        let events = self.time.process(time_step);
    }

    pub fn add_gear_data<T>(&mut self, gear_id: GearId, data: T)
    where
        T: GearData,
        Self: GearDataAggregator<T>,
    {
        self.find_processor().add(gear_id, data);
    }
}

#[cfg(test)]
mod tests {
    use crate::{
        collision::{CircleBounds, CollisionData},
        physics::PhysicsData,
        World,
    };
    use fpnum::{fp, FPNum, FPPoint};
    use integral_geometry::Size;
    use land2d::Land2D;

    #[test]
    fn data_flow() {
        let world_size = Size::new(2048, 2048);

        let mut world = World::new(world_size);
        let gear_id = 46631;

        world.add_gear_data(
            gear_id,
            PhysicsData {
                position: FPPoint::zero(),
                velocity: FPPoint::unit_y(),
            },
        );

        world.add_gear_data(
            gear_id,
            CollisionData {
                bounds: CircleBounds {
                    center: FPPoint::zero(),
                    radius: fp!(10),
                },
            },
        );

        let land = Land2D::new(Size::new(world_size.width - 2, world_size.height - 2), 0);

        world.step(fp!(1), &land);
    }
}
