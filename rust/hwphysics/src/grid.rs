use crate::{
    collision::{fppoint_round, CircleBounds, DetectedCollisions},
    common::GearId,
};

use fpnum::FPPoint;
use integral_geometry::{GridIndex, Point, Size};

struct GridBin {
    refs: Vec<GearId>,
    entries: Vec<CircleBounds>,
}

impl GridBin {
    fn new() -> Self {
        Self {
            refs: vec![],
            entries: vec![],
        }
    }

    fn add(&mut self, gear_id: GearId, bounds: &CircleBounds) {
        self.refs.push(gear_id);
        self.entries.push(*bounds);
    }

    fn remove(&mut self, gear_id: GearId) -> bool {
        if let Some(pos) = self.refs.iter().position(|id| *id == gear_id) {
            self.refs.swap_remove(pos);
            self.entries.swap_remove(pos);
            true
        } else {
            false
        }
    }
}

const GRID_BIN_SIZE: usize = 128;

pub struct Grid {
    bins: Vec<GridBin>,
    space_size: Size,
    bins_count: Size,
    index: GridIndex,
}

impl Grid {
    pub fn new(size: Size) -> Self {
        assert!(size.is_power_of_two());
        let bins_count = Size::new(size.width / GRID_BIN_SIZE, size.height / GRID_BIN_SIZE);

        Self {
            bins: (0..bins_count.area()).map(|_| GridBin::new()).collect(),
            space_size: size,
            bins_count,
            index: Size::square(GRID_BIN_SIZE).to_grid_index(),
        }
    }

    fn bin_index(&self, position: &FPPoint) -> Point {
        self.index.map(fppoint_round(position))
    }

    fn get_bin(&mut self, index: Point) -> &mut GridBin {
        &mut self.bins[index.y as usize * self.bins_count.width + index.x as usize]
    }

    fn try_get_bin(&mut self, index: Point) -> Option<&mut GridBin> {
        self.bins
            .get_mut(index.y as usize * self.bins_count.width + index.x as usize)
    }

    fn lookup_bin(&mut self, position: &FPPoint) -> &mut GridBin {
        self.get_bin(self.bin_index(position))
    }

    pub fn insert(&mut self, gear_id: GearId, bounds: &CircleBounds) {
        self.lookup_bin(&bounds.center).add(gear_id, bounds);
    }

    fn remove_all(&mut self, gear_id: GearId) {
        for bin in &mut self.bins {
            if bin.remove(gear_id) {
                break;
            }
        }
    }

    pub fn remove(&mut self, gear_id: GearId, bounds: Option<&CircleBounds>) {
        if let Some(bounds) = bounds {
            if !self.lookup_bin(&bounds.center).remove(gear_id) {
                self.remove_all(gear_id);
            }
        } else {
            self.remove_all(gear_id);
        }

    }

    pub fn check_collisions(&self, collisions: &mut DetectedCollisions) {
        for bin in &self.bins {
            for (index, bounds) in bin.entries.iter().enumerate() {

            }
        }
    }
}
