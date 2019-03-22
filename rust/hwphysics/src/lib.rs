pub mod collision;
pub mod common;
mod grid;
pub mod physics;

use fpnum::FPNum;
use integral_geometry::Size;
use land2d::Land2D;

use crate::{
    collision::{CollisionData, CollisionProcessor, ContactData},
    common::{GearData, GearDataAggregator, GearDataProcessor, GearId},
    physics::{PhysicsData, PhysicsProcessor},
};

pub struct JoinedData {
    gear_id: GearId,
    physics: PhysicsData,
    collision: CollisionData,
    contact: ContactData,
}

pub struct World {
    physics: PhysicsProcessor,
    collision: CollisionProcessor,
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
            physics: PhysicsProcessor::new(),
            collision: CollisionProcessor::new(world_size),
        }
    }

    pub fn step(&mut self, time_step: FPNum, land: &Land2D<u32>) {
        let updates = self.physics.process(time_step);
        self.collision.process(land, &updates);
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
