pub mod collision;
pub mod common;
mod data;
mod grid;
pub mod physics;

use integral_geometry::PotSize;
use land2d::Land2D;

use crate::{
    collision::CollisionProcessor,
    common::{GearAllocator, GearId, Millis},
    data::{DataIterator, GearDataManager, TypeIter},
    physics::PhysicsProcessor,
};

pub struct World {
    allocator: GearAllocator,
    data: GearDataManager,
    physics: PhysicsProcessor,
    collision: CollisionProcessor,
}

impl World {
    pub fn new(world_size: PotSize) -> Self {
        let mut data = GearDataManager::new();
        PhysicsProcessor::register_components(&mut data);
        CollisionProcessor::register_components(&mut data);

        Self {
            data,
            allocator: GearAllocator::new(),
            physics: PhysicsProcessor::new(),
            collision: CollisionProcessor::new(world_size),
        }
    }

    #[inline]
    pub fn new_gear(&mut self) -> Option<GearId> {
        self.allocator.alloc()
    }

    #[inline]
    pub fn delete_gear(&mut self, gear_id: GearId) {
        self.data.remove_all(gear_id);
        self.collision.remove(gear_id);
        self.allocator.free(gear_id)
    }

    pub fn step(&mut self, time_step: Millis, land: &Land2D<u32>) {
        let updates = self.physics.process(&mut self.data, time_step);
        let collisions = self.collision.process(land, &updates);
    }

    #[inline]
    pub fn add_gear_data<T: Clone + 'static>(&mut self, gear_id: GearId, data: &T) {
        self.data.add(gear_id, data);
    }

    #[inline]
    pub fn iter_data<T: TypeIter + 'static>(&mut self) -> DataIterator<T> {
        self.data.iter()
    }
}

#[cfg(test)]
mod tests {
    use crate::{
        collision::{CircleBounds, CollisionData},
        common::Millis,
        physics::{PositionData, VelocityData},
        World,
    };
    use fpnum::{fp, FPNum, FPPoint};
    use integral_geometry::PotSize;
    use land2d::Land2D;

    #[test]
    fn data_flow() {
        let world_size = PotSize::new(2048, 2048).unwrap;

        let mut world = World::new(world_size);
        let gear_id = world.new_gear().unwrap();

        world.add_gear_data(gear_id, &PositionData(FPPoint::zero()));
        world.add_gear_data(gear_id, &VelocityData(FPPoint::unit_y()));

        world.add_gear_data(
            gear_id,
            &CollisionData {
                bounds: CircleBounds {
                    center: FPPoint::zero(),
                    radius: fp!(10),
                },
            },
        );

        let land = Land2D::new(Size::new(world_size.width - 2, world_size.height - 2), 0);

        world.step(Millis::new(1), &land);
    }
}
