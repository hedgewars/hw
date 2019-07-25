use crate::common::{GearData, GearDataProcessor, GearId};
use fpnum::*;
use integral_geometry::{GridIndex, Point, Size};

#[derive(PartialEq, Eq, Clone, Copy, Debug)]
pub struct PhysicsData {
    pub position: FPPoint,
    pub velocity: FPPoint,
}

impl GearData for PhysicsData {}

impl PhysicsData {
    pub fn new(position: FPPoint, velocity: FPPoint) -> Self {
        Self { position, velocity }
    }
}

pub struct DynamicPhysicsCollection {
    gear_ids: Vec<GearId>,
    positions: Vec<FPPoint>,
    velocities: Vec<FPPoint>,
}

impl DynamicPhysicsCollection {
    fn new() -> Self {
        Self {
            gear_ids: Vec::new(),
            positions: Vec::new(),
            velocities: Vec::new(),
        }
    }

    fn len(&self) -> usize {
        self.gear_ids.len()
    }

    fn push(&mut self, id: GearId, physics: PhysicsData) {
        self.gear_ids.push(id);
        self.positions.push(physics.position);
        self.velocities.push(physics.velocity);
    }

    fn iter_pos_update(&mut self) -> impl Iterator<Item = (GearId, (&mut FPPoint, &FPPoint))> {
        self.gear_ids
            .iter()
            .cloned()
            .zip(self.positions.iter_mut().zip(self.velocities.iter()))
    }
}

pub struct StaticPhysicsCollection {
    gear_ids: Vec<GearId>,
    positions: Vec<FPPoint>,
}

impl StaticPhysicsCollection {
    fn new() -> Self {
        Self {
            gear_ids: Vec::new(),
            positions: Vec::new(),
        }
    }

    fn push(&mut self, gear_id: GearId, physics: PhysicsData) {
        self.gear_ids.push(gear_id);
        self.positions.push(physics.position);
    }
}

pub struct PhysicsProcessor {
    dynamic_physics: DynamicPhysicsCollection,
    static_physics: StaticPhysicsCollection,

    physics_cleanup: Vec<GearId>,
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
    pub fn new() -> Self {
        PhysicsProcessor {
            dynamic_physics: DynamicPhysicsCollection::new(),
            static_physics: StaticPhysicsCollection::new(),
            physics_cleanup: Vec::new(),
            position_updates: PositionUpdates::new(0),
        }
    }

    pub fn process(&mut self, time_step: FPNum) -> &PositionUpdates {
        self.position_updates.clear();
        for (gear_id, (pos, vel)) in self.dynamic_physics.iter_pos_update() {
            let old_pos = *pos;
            *pos += *vel * time_step;
            if !vel.is_zero() {
                self.position_updates.push(gear_id, &old_pos, pos)
            } else {
                self.physics_cleanup.push(gear_id)
            }
        }
        &self.position_updates
    }

    pub fn push(&mut self, gear_id: GearId, physics_data: PhysicsData) {
        if physics_data.velocity.is_zero() {
            self.static_physics.push(gear_id, physics_data);
        } else {
            self.dynamic_physics.push(gear_id, physics_data);
        }
    }
}

impl GearDataProcessor<PhysicsData> for PhysicsProcessor {
    fn add(&mut self, gear_id: GearId, gear_data: PhysicsData) {
        if gear_data.velocity.is_zero() {
            self.static_physics.push(gear_id, gear_data);
        } else {
            self.dynamic_physics.push(gear_id, gear_data);
        }
    }
}
