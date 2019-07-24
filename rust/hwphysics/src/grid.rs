use crate::{
    collision::{fppoint_round, CircleBounds, DetectedCollisions},
    common::GearId,
};

use fpnum::FPPoint;
use integral_geometry::{GridIndex, Point, Size};

struct GridBin {
    static_refs: Vec<GearId>,
    static_entries: Vec<CircleBounds>,

    dynamic_refs: Vec<GearId>,
    dynamic_entries: Vec<CircleBounds>,
}

impl GridBin {
    fn new() -> Self {
        Self {
            static_refs: vec![],
            static_entries: vec![],
            dynamic_refs: vec![],
            dynamic_entries: vec![],
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
        &mut self.bins[index.x as usize * self.bins_count.width + index.y as usize]
    }

    fn lookup_bin(&mut self, position: &FPPoint) -> &mut GridBin {
        self.get_bin(self.bin_index(position))
    }

    pub fn insert_static(&mut self, gear_id: GearId, bounds: &CircleBounds) {
        let bin = self.lookup_bin(&bounds.center);
        bin.static_refs.push(gear_id);
        bin.static_entries.push(*bounds)
    }

    pub fn insert_dynamic(&mut self, gear_id: GearId, bounds: &CircleBounds) {
        let bin = self.lookup_bin(&bounds.center);
        bin.dynamic_refs.push(gear_id);
        bin.dynamic_entries.push(*bounds);
    }

    pub fn update_position(
        &mut self,
        gear_id: GearId,
        old_position: &FPPoint,
        new_position: &FPPoint,
    ) {
        let old_bin_index = self.bin_index(old_position);
        let new_bin_index = self.bin_index(new_position);

        let old_bin = self.lookup_bin(old_position);
        if let Some(index) = old_bin.dynamic_refs.iter().position(|id| *id == gear_id) {
            if old_bin_index == new_bin_index {
                old_bin.dynamic_entries[index].center = *new_position
            } else {
                let bounds = old_bin.dynamic_entries.swap_remove(index);
                let new_bin = self.get_bin(new_bin_index);

                new_bin.dynamic_refs.push(gear_id);
                new_bin.dynamic_entries.push(CircleBounds {
                    center: *new_position,
                    ..bounds
                });
            }
        } else if let Some(index) = old_bin.static_refs.iter().position(|id| *id == gear_id) {
            let bounds = old_bin.static_entries.swap_remove(index);
            old_bin.static_refs.swap_remove(index);

            let new_bin = if old_bin_index == new_bin_index {
                old_bin
            } else {
                self.get_bin(new_bin_index)
            };

            new_bin.dynamic_refs.push(gear_id);
            new_bin.dynamic_entries.push(CircleBounds {
                center: *new_position,
                ..bounds
            });
        }
    }

    pub fn check_collisions(&self, collisions: &mut DetectedCollisions) {
        for bin in &self.bins {
            for (index, bounds) in bin.dynamic_entries.iter().enumerate() {
                for (other_index, other) in bin.dynamic_entries.iter().enumerate().skip(index + 1) {
                    if bounds.intersects(other) && bounds != other {
                        collisions.push(
                            bin.dynamic_refs[index],
                            Some(bin.dynamic_refs[other_index]),
                            &bounds.center,
                        )
                    }
                }

                for (other_index, other) in bin.static_entries.iter().enumerate() {
                    if bounds.intersects(other) {
                        collisions.push(
                            bin.dynamic_refs[index],
                            Some(bin.static_refs[other_index]),
                            &bounds.center,
                        )
                    }
                }
            }
        }
    }
}
