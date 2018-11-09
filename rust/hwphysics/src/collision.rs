use std::{
    ops::RangeInclusive
};

use crate::{
    common::{GearId, GearData, GearDataProcessor},
    physics::PhysicsData,
    grid::Grid
};

use fpnum::*;
use integral_geometry::{
    Point, Size, GridIndex
};
use land2d::Land2D;

pub fn fppoint_round(point: &FPPoint) -> Point {
    Point::new(point.x().round() as i32, point.y().round() as i32)
}

#[derive(PartialEq, Eq, Clone, Copy, Debug)]
pub struct CircleBounds {
    pub center: FPPoint,
    pub radius: FPNum
}

impl CircleBounds {
    pub fn intersects(&self, other: &CircleBounds) -> bool {
        (other.center - self.center).is_in_range(self.radius + other.radius)
    }

    pub fn rows(&self) -> impl Iterator<Item = (usize, RangeInclusive<usize>)> {
        let radius = self.radius.abs_round() as usize;
        let center = Point::from_fppoint(&self.center);
        (center.y as usize - radius..=center.y as usize + radius)
            .map(move |row| (row, center.x as usize - radius..=center.x as usize + radius))
    }
}

#[derive(PartialEq, Eq, Clone, Copy, Debug)]
pub struct CollisionData {
    pub bounds: CircleBounds
}

impl GearData for CollisionData {}

#[derive(PartialEq, Eq, Clone, Copy, Debug)]
pub struct ContactData {
    pub elasticity: FPNum,
    pub friction: FPNum
}

impl GearData for ContactData {}

struct EnabledCollisionsCollection {
    gear_ids: Vec<GearId>,
    collisions: Vec<CollisionData>
}

impl EnabledCollisionsCollection {
    fn new() -> Self {
        Self {
            gear_ids: Vec::new(),
            collisions: Vec::new()
        }
    }

    fn push(&mut self, gear_id: GearId, collision: CollisionData) {
        self.gear_ids.push(gear_id);
        self.collisions.push(collision);
    }

    fn iter(&self) -> impl Iterator<Item = (GearId, &CollisionData)> {
        self.gear_ids.iter().cloned().zip(self.collisions.iter())
    }
}

pub struct CollisionProcessor {
    grid: Grid,
    enabled_collisions: EnabledCollisionsCollection,

    detected_collisions: DetectedCollisions,
}

pub struct DetectedCollisions {
    pub pairs: Vec<(GearId, GearId)>,
    pub positions: Vec<Point>
}

impl DetectedCollisions {
    pub fn new(capacity: usize) -> Self {
        Self {
            pairs: Vec::with_capacity(capacity),
            positions: Vec::with_capacity(capacity),
        }
    }

    pub fn push(&mut self, contact_gear_id1: GearId, contact_gear_id2: GearId, position: &FPPoint) {
        self.pairs.push((contact_gear_id1, contact_gear_id2));
        self.positions.push(fppoint_round(&position));
    }
}

impl CollisionProcessor {
    pub fn new(size: Size) -> Self {
        Self {
            grid: Grid::new(size),
            enabled_collisions: EnabledCollisionsCollection::new(),
            detected_collisions: DetectedCollisions::new(0)
        }
    }

    pub fn process(&mut self, land: &Land2D<u32>, updates: &crate::physics::PositionUpdates) {
        self.grid.check_collisions(&mut self.detected_collisions);

        for (gear_id, collision) in self.enabled_collisions.iter() {
            if collision.bounds.rows().any(|(y, r)| (&land[y][r]).iter().any(|v| *v != 0)) {
                self.detected_collisions.push(gear_id, 0, &collision.bounds.center)
            }
        }
    }
}

impl GearDataProcessor<CollisionData> for CollisionProcessor {
    fn add(&mut self, gear_id: GearId, gear_data: CollisionData) {
        self.grid.insert_static(gear_id, &gear_data.bounds);
    }
}