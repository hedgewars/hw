use crate::{
    common::GearId,
    collision::{
        fppoint_round,
        CircleBounds,
        DetectedCollisions
    }
};

use integral_geometry::{
    Point,
    Size,
    GridIndex
};
use fpnum::FPPoint;

struct GridBin {
    refs: Vec<GearId>,
    static_entries: Vec<CircleBounds>,
    dynamic_entries: Vec<CircleBounds>
}

impl GridBin {
    fn new() -> Self {
        Self {
            refs: vec![],
            static_entries: vec![],
            dynamic_entries: vec![]
        }
    }
}

const GRID_BIN_SIZE: usize = 128;

pub struct Grid {
    bins: Vec<GridBin>,
    space_size: Size,
    bins_count: Size,
    index: GridIndex
}

impl Grid {
    pub fn new(size: Size) -> Self {
        assert!(size.is_power_of_two());
        let bins_count =
            Size::new(size.width / GRID_BIN_SIZE,
                      size.height / GRID_BIN_SIZE);

        Self {
            bins: (0..bins_count.area()).map(|_| GridBin::new()).collect(),
            space_size: size,
            bins_count,
            index: Size::square(GRID_BIN_SIZE).to_grid_index()
        }
    }

    fn bin_index(&self, position: &FPPoint) -> Point {
        self.index.map(fppoint_round(position))
    }

    fn lookup_bin(&mut self, position: &FPPoint) -> &mut GridBin {
        let index = self.bin_index(position);
        &mut self.bins[index.x as usize * self.bins_count.width + index.y as usize]
    }

    pub fn insert_static(&mut self, gear_id: GearId, bounds: &CircleBounds) {
        self.lookup_bin(&bounds.center).static_entries.push(*bounds)
    }

    pub fn insert_dynamic(&mut self, gear_id: GearId, bounds: &CircleBounds) {
        self.lookup_bin(&bounds.center).dynamic_entries.push(*bounds)
    }

    pub fn check_collisions(&self, collisions: &mut DetectedCollisions) {
        for bin in &self.bins {
            for bounds in &bin.dynamic_entries {
                for other in &bin.dynamic_entries {
                    if bounds.intersects(other) && bounds != other {
                        collisions.push(0, 0, &bounds.center)
                    }
                }

                for other in &bin.static_entries {
                    if bounds.intersects(other) {
                        collisions.push(0, 0, &bounds.center)
                    }
                }
            }
        }
    }
}