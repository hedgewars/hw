mod common;
mod physics;
mod grid;
mod collision;

use fpnum::FPNum;
use land2d::Land2D;

use crate::{
    common::GearId,
    physics::{
        PhysicsProcessor,
        PhysicsData
    },
    collision::{
        CollisionProcessor,
        CollisionData,
        ContactData
    }
};

pub struct JoinedData {
    gear_id: GearId,
    physics: PhysicsData,
    collision: CollisionData,
    contact: ContactData
}

pub struct World {
    physics: PhysicsProcessor,
    collision: CollisionProcessor,
}

impl World {
    pub fn step(&mut self, time_step: FPNum, land: &Land2D<u32>) {
        let updates = self.physics.process(time_step);
        self.collision.process(land, &updates);
    }

    pub fn add_gear(&mut self, data: JoinedData) {
        self.physics.push(data.gear_id, data.physics);
        self.collision.push(data.gear_id, data.physics, data.collision);
    }
}

#[cfg(test)]
mod tests {

}
