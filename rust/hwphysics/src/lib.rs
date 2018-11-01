use fpnum::*;
use integral_geometry::{
    Point, Size, GridIndex
};

type Index = u16;

#[derive(PartialEq, Eq, Clone, Copy, Debug)]
struct PhysicsData {
    position: FPPoint,
    velocity: FPPoint,
}

#[derive(PartialEq, Eq, Clone, Copy, Debug)]
struct CollisionData {
    bounds: CircleBounds
}

#[derive(PartialEq, Eq, Clone, Copy, Debug)]
struct ContactData {
    elasticity: FPNum,
    friction: FPNum
}

pub struct PhysicsCollection {
    positions: Vec<FPPoint>,
    velocities: Vec<FPPoint>
}

impl PhysicsCollection {
    fn push(&mut self, data: PhysicsData) {
        self.positions.push(data.position);
        self.velocities.push(data.velocity);
    }

    fn iter_mut_pos(&mut self) -> impl Iterator<Item = (&mut FPPoint, &FPPoint)> {
        self.positions.iter_mut().zip(self.velocities.iter())
    }
}

pub struct JoinedData {
    physics: PhysicsData,
    collision: CollisionData,
    contact: ContactData
}

pub struct World {
    enabled_physics: PhysicsCollection,
    disabled_physics: Vec<PhysicsData>,

    collision: Vec<CollisionData>,
    grid: Grid,

    physics_cleanup: Vec<PhysicsData>,
    collision_output: Vec<(Index, Index)>
}

#[derive(PartialEq, Eq, Clone, Copy, Debug)]
struct CircleBounds {
    center: FPPoint,
    radius: FPNum
}

impl CircleBounds {
    fn intersects(&self, other: &CircleBounds) -> bool {
        (other.center - self.center).is_in_range(self.radius + other.radius)
    }
}

fn fppoint_round(point: &FPPoint) -> Point {
    Point::new(point.x().round() as i32, point.y().round() as i32)
}

struct GridBin {
    refs: Vec<Index>,
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

const GRID_BIN_SIZE: usize = 256;

struct Grid {
    bins: Vec<GridBin>,
    space_size: Size,
    bins_count: Size,
    index: GridIndex
}

impl Grid {
    fn new(size: Size) -> Self {
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

    fn insert_static(&mut self, index: Index, position: &FPPoint, bounds: &CircleBounds) {
        self.lookup_bin(position).static_entries.push(*bounds)
    }

    fn insert_dynamic(&mut self, index: Index, position: &FPPoint, bounds: &CircleBounds) {
        self.lookup_bin(position).dynamic_entries.push(*bounds)
    }

    fn check_collisions(&self, collisions: &mut Vec<(Index, Index)>) {
        for bin in &self.bins {
            for bounds in &bin.dynamic_entries {
                for other in &bin.dynamic_entries {
                    if bounds.intersects(other) && bounds != other {
                        collisions.push((0, 0))
                    }
                }

                for other in &bin.static_entries {
                    if bounds.intersects(other) {
                        collisions.push((0, 0))
                    }
                }
            }
        }
    }
}

impl World {
    pub fn step(&mut self, time_step: FPNum) {
        for (pos, vel) in self.enabled_physics.iter_mut_pos() {
            *pos += *vel
        }

        self.grid.check_collisions(&mut self.collision_output);
    }

    pub fn add_gear(&mut self, data: JoinedData) {
        if data.physics.velocity == FPPoint::zero() {
            self.disabled_physics.push(data.physics);
            self.grid.insert_static(0, &data.physics.position, &data.collision.bounds);
        } else {
            self.enabled_physics.push(data.physics);
            self.grid.insert_dynamic(0, &data.physics.position, &data.collision.bounds);
        }
    }
}

#[cfg(test)]
mod tests {

}
