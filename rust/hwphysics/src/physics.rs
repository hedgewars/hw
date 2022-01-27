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

pub struct AffectedByWind;

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

pub struct PhysicsProcessor {
    gravity: FPNum,
    wind: FPNum,
    position_updates: PositionUpdates,
}

impl PhysicsProcessor {
    pub fn register_components(data: &mut GearDataManager) {
        data.register::<PositionData>();
        data.register::<VelocityData>();
        data.register::<AffectedByWind>();
    }

    pub fn new() -> Self {
        Self {
            gravity: fp!(1 / 10),
            wind: fp!(0),
            position_updates: PositionUpdates::new(64),
        }
    }

    pub fn process(&mut self, data: &mut GearDataManager, time_step: Millis) -> &PositionUpdates {
        if time_step == Millis::new(1) {
            self.process_impl::<true>(data, time_step)
        } else {
            self.process_impl::<false>(data, time_step)
        }
    }

    fn process_impl<const SINGLE_TICK: bool>(
        &mut self,
        data: &mut GearDataManager,
        time_step: Millis,
    ) -> &PositionUpdates {
        let fp_step = if SINGLE_TICK {
            fp!(1)
        } else {
            time_step.to_fixed()
        };
        let gravity = FPPoint::unit_y() * (self.gravity * fp_step);
        let wind = FPPoint::unit_x() * (self.wind * fp_step);

        self.position_updates.clear();

        data.iter()
            .with_tags::<&AffectedByWind>()
            .run(|(vel,): (&mut VelocityData,)| {
                vel.0 += wind;
            });

        data.iter().run_id(
            |gear_id, (pos, vel): (&mut PositionData, &mut VelocityData)| {
                let old_pos = pos.0;
                vel.0 += gravity;
                pos.0 += if SINGLE_TICK { vel.0 } else { vel.0 * fp_step };
                self.position_updates.push(gear_id, &old_pos, &pos.0)
            },
        );

        &self.position_updates
    }
}
