use crate::{
    common::{GearId, Millis},
    data::GearDataManager,
};
use fpnum::*;

#[derive(PartialEq, Eq, Clone, Copy, Debug)]
#[repr(transparent)]
pub struct PositionData(pub FPPoint);

#[derive(PartialEq, Eq, Clone, Copy, Debug)]
#[repr(transparent)]
pub struct VelocityData(pub FPPoint);

pub struct PhysicsProcessor {
    position_updates: PositionUpdates,
}

pub struct PositionUpdates {
    pub gear_ids: Vec<GearId>,
    pub shifts: Vec<(FPPoint, FPPoint)>,
}

impl PositionUpdates {
    pub fn new(capacity: usize) -> Self {
        Self {
            gear_ids: Vec::with_capacity(capacity),
            shifts: Vec::with_capacity(capacity),
        }
    }

    pub fn push(&mut self, gear_id: GearId, old_position: &FPPoint, new_position: &FPPoint) {
        self.gear_ids.push(gear_id);
        self.shifts.push((*old_position, *new_position));
    }

    pub fn iter(&self) -> impl Iterator<Item = (GearId, &FPPoint, &FPPoint)> {
        self.gear_ids
            .iter()
            .cloned()
            .zip(self.shifts.iter())
            .map(|(id, (from, to))| (id, from, to))
    }

    pub fn clear(&mut self) {
        self.gear_ids.clear();
        self.shifts.clear();
    }
}

impl PhysicsProcessor {
    pub fn register_components(data: &mut GearDataManager) {
        data.register::<PositionData>();
        data.register::<VelocityData>();
    }

    pub fn new() -> Self {
        Self {
            position_updates: PositionUpdates::new(64),
        }
    }

    pub fn process(&mut self, data: &mut GearDataManager, time_step: Millis) -> &PositionUpdates {
        let fp_step = time_step.to_fixed();
        self.position_updates.clear();

        data.iter_id(
            |gear_id, (pos, vel): (&mut PositionData, &mut VelocityData)| {
                if !vel.0.is_zero() {
                    let old_pos = pos.0;
                    pos.0 += vel.0 * fp_step;
                    self.position_updates.push(gear_id, &old_pos, &pos.0)
                }
            },
        );

        &self.position_updates
    }
}
