use crate::common::{GearData, GearDataLookup, GearDataProcessor, GearId, Millis};
use fpnum::*;

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

    fn push(&mut self, gear_id: GearId, physics: PhysicsData) -> u16 {
        self.gear_ids.push(gear_id);
        self.positions.push(physics.position);
        self.velocities.push(physics.velocity);

        (self.gear_ids.len() - 1) as u16
    }

    fn remove(&mut self, index: usize) -> Option<GearId> {
        self.gear_ids.swap_remove(index);
        self.positions.swap_remove(index);
        self.velocities.swap_remove(index);

        self.gear_ids.get(index).cloned()
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

    fn push(&mut self, gear_id: GearId, physics: PhysicsData) -> u16 {
        self.gear_ids.push(gear_id);
        self.positions.push(physics.position);

        (self.gear_ids.len() - 1) as u16
    }

    fn remove(&mut self, index: usize) -> Option<GearId> {
        self.gear_ids.swap_remove(index);
        self.positions.swap_remove(index);

        self.gear_ids.get(index).cloned()
    }
}

pub struct PhysicsProcessor {
    gear_lookup: GearDataLookup<bool>,
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
        Self {
            gear_lookup: GearDataLookup::new(),
            dynamic_physics: DynamicPhysicsCollection::new(),
            static_physics: StaticPhysicsCollection::new(),
            physics_cleanup: Vec::new(),
            position_updates: PositionUpdates::new(0),
        }
    }

    pub fn process(&mut self, time_step: Millis) -> &PositionUpdates {
        let fp_step = time_step.to_fixed();
        self.position_updates.clear();
        for (gear_id, (pos, vel)) in self.dynamic_physics.iter_pos_update() {
            let old_pos = *pos;
            *pos += *vel * fp_step;
            if !vel.is_zero() {
                self.position_updates.push(gear_id, &old_pos, pos)
            } else {
                self.physics_cleanup.push(gear_id)
            }
        }
        &self.position_updates
    }
}

impl GearDataProcessor<PhysicsData> for PhysicsProcessor {
    fn add(&mut self, gear_id: GearId, gear_data: PhysicsData) {
        let is_dynamic = !gear_data.velocity.is_zero();
        let index = if is_dynamic {
            self.dynamic_physics.push(gear_id, gear_data)
        } else {
            self.static_physics.push(gear_id, gear_data)
        };

        self.gear_lookup.add(gear_id, index, is_dynamic);
    }

    fn remove(&mut self, gear_id: GearId) {
        if let Some(entry) = self.gear_lookup.get(gear_id) {
            let relocated_gear_id = if *entry.value() {
                self.dynamic_physics.remove(entry.index() as usize)
            } else {
                self.static_physics.remove(entry.index() as usize)
            };

            if let Some(id) = relocated_gear_id {
                let index = entry.index();
                self.gear_lookup[id].set_index(index);
            }
        }
    }

    fn get(&mut self, gear_id: GearId) -> Option<PhysicsData> {
        if let Some(entry) = self.gear_lookup.get(gear_id) {
            let data = if *entry.value() {
                PhysicsData {
                    position: self.dynamic_physics.positions[entry.index() as usize],
                    velocity: self.dynamic_physics.velocities[entry.index() as usize],
                }
            } else {
                PhysicsData {
                    position: self.static_physics.positions[entry.index() as usize],
                    velocity: FPPoint::zero(),
                }
            };
            Some(data)
        } else {
            None
        }
    }
}
