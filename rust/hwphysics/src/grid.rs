use crate::{
    collision::{CircleBounds, DetectedCollisions},
    common::GearId,
};

use fpnum::FPPoint;
use integral_geometry::{GridIndex, Point, PotSize};

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
    space_size: PotSize,
    bins_count: PotSize,
    index: GridIndex,
}

impl Grid {
    pub fn new(size: PotSize) -> Self {
        let bins_count =
            PotSize::new(size.width() / GRID_BIN_SIZE, size.height() / GRID_BIN_SIZE).unwrap();

        Self {
            bins: (0..bins_count.area()).map(|_| GridBin::new()).collect(),
            space_size: size,
            bins_count,
            index: PotSize::square(GRID_BIN_SIZE).unwrap().to_grid_index(),
        }
    }

    fn linear_bin_index(&self, index: Point) -> usize {
        self.bins_count
            .linear_index(index.x as usize, index.y as usize)
    }

    fn bin_index(&self, position: &FPPoint) -> Point {
        self.index.map(Point::from_fppoint(position))
    }

    fn get_bin(&mut self, index: Point) -> &mut GridBin {
        let index = self.linear_bin_index(index);
        &mut self.bins[index]
    }

    fn try_get_bin(&mut self, index: Point) -> Option<&mut GridBin> {
        let index = self.linear_bin_index(index);
        self.bins.get_mut(index)
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
            for (index, bounds) in bin.entries.iter().enumerate() {}
        }
    }
}
