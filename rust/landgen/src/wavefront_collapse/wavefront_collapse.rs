use integral_geometry::Size;
use rand::distributions::Distribution;
use rand::distributions::WeightedIndex;
use rand::Rng;
use std::collections::HashSet;
use vec2d::Vec2D;

#[derive(PartialEq, Eq, Hash, Clone, Copy, Debug)]
pub enum Tile {
    Empty,
    OutsideBegin,
    OutsideFill,
    OutsideEnd,
    Numbered(usize),
}

#[derive(Debug)]
pub struct CollapseRule {
    pub weight: u32,
    pub tile: Tile,
    pub right: HashSet<Tile>,
    pub bottom: HashSet<Tile>,
    pub left: HashSet<Tile>,
    pub top: HashSet<Tile>,
}

pub struct WavefrontCollapse {
    rules: Vec<CollapseRule>,
    grid: Vec2D<Tile>,
    wrap: bool,
}

impl Default for WavefrontCollapse {
    fn default() -> Self {
        Self {
            rules: Vec::new(),
            grid: Vec2D::new(&Size::new(1, 1), Tile::Empty),
            wrap: false,
        }
    }
}

impl WavefrontCollapse {
    pub fn new(wrap: bool) -> Self {
        Self {
            rules: Vec::new(),
            grid: Vec2D::new(&Size::new(1, 1), Tile::Empty),
            wrap,
        }
    }

    pub fn generate_map<F: FnOnce(&mut Vec2D<Tile>)>(
        &mut self,
        map_size: &Size,
        seed_fn: F,
        random_numbers: &mut impl Rng,
    ) {
        self.grid = Vec2D::new(map_size, Tile::Empty);

        seed_fn(&mut self.grid);

        while self.collapse_step(random_numbers) {}
    }

    pub fn set_rules(&mut self, rules: Vec<CollapseRule>) {
        self.rules = rules;
    }

    fn get_tile(&self, y: usize, x: usize) -> Tile {
        let x = if self.wrap {
            if x == usize::MAX {
                self.grid.width() - 1
            } else if x == self.grid.width() {
                0
            } else {
                x
            }
        } else {
            x
        };

        self.grid.get(y, x).copied().unwrap_or_else(|| {
            let x_out = x >= self.grid.width();

            if x_out {
                let y_at_begin = y == 0;
                let y_at_end = y.wrapping_add(1) == self.grid.height();
                if y_at_begin {
                    Tile::OutsideBegin
                } else if y_at_end {
                    Tile::OutsideEnd
                } else {
                    Tile::OutsideFill
                }
            } else {
                // if not x, then it is y

                let x_at_begin = x == 0;
                let x_at_end = x.wrapping_add(1) == self.grid.width();

                if x_at_begin {
                    Tile::OutsideBegin
                } else if x_at_end {
                    Tile::OutsideEnd
                } else {
                    Tile::OutsideFill
                }
            }
        })
    }

    fn collapse_step(&mut self, random_numbers: &mut impl Rng) -> bool {
        let mut tiles_to_collapse = (usize::MAX, Vec::new());

        // Iterate through the tiles in the land
        for x in 0..self.grid.width() {
            for y in 0..self.grid.height() {
                let current_tile = self.get_tile(y, x);

                if let Tile::Empty = current_tile {
                    // calc entropy
                    let right_tile = self.get_tile(y, x.wrapping_add(1));
                    let bottom_tile = self.get_tile(y.wrapping_add(1), x);
                    let left_tile = self.get_tile(y, x.wrapping_sub(1));
                    let top_tile = self.get_tile(y.wrapping_sub(1), x);

                    let possibilities: Vec<(u32, Tile)> = self
                        .rules
                        .iter()
                        .filter_map(|rule| {
                            if rule.right.contains(&right_tile)
                                && rule.bottom.contains(&bottom_tile)
                                && rule.left.contains(&left_tile)
                                && rule.top.contains(&top_tile)
                            {
                                Some((rule.weight, rule.tile))
                            } else {
                                None
                            }
                        })
                        .collect();

                    let entropy = possibilities.len();
                    if entropy > 0 {
                        if entropy <= tiles_to_collapse.0 {
                            let weights = possibilities.iter().map(|(weight, _)| *weight);
                            let distribution = WeightedIndex::new(weights).unwrap();

                            let entry = (y, x, possibilities[distribution.sample(random_numbers)]);

                            if entropy < tiles_to_collapse.0 {
                                tiles_to_collapse = (entropy, vec![entry])
                            } else {
                                tiles_to_collapse.1.push(entry)
                            }
                        }
                    } else {
                        /*println!("We're here: {}, {}", x, y);
                        println!(
                            "Neighbour tiles are: {:?} {:?} {:?} {:?}",
                            right_tile, bottom_tile, left_tile, top_tile
                        );
                        println!("Rules are: {:?}", self.rules);*/

                        //todo!("no collapse possible - what to do?")
                    }
                }
            }
        }

        let tiles_to_collapse = tiles_to_collapse.1;
        let possibilities_number = tiles_to_collapse.len();

        if possibilities_number > 0 {
            let weights = tiles_to_collapse.iter().map(|(_, _, (weight, _))| *weight);
            let distribution = WeightedIndex::new(weights).unwrap();

            let (y, x, (_, tile)) = tiles_to_collapse[distribution.sample(random_numbers)];

            *self
                .grid
                .get_mut(y, x)
                .expect("correct iteration over grid") = tile;

            true
        } else {
            false
        }
    }

    pub fn grid(&self) -> &Vec2D<Tile> {
        &self.grid
    }
}

#[cfg(test)]
mod tests {
    use super::{Tile, WavefrontCollapse};
    use integral_geometry::Size;
    use vec2d::Vec2D;

    #[test]
    fn test_wavefront_collapse() {
        let size = Size::new(4, 4);
        let mut rnd = [0u32; 64].into_iter().cycle();
        let mut wfc = WavefrontCollapse::default();

        wfc.generate_map(&size, |_| {}, &mut rnd);

        let empty_land = Vec2D::new(&size, Tile::Empty);

        assert_eq!(empty_land.as_slice(), wfc.grid().as_slice());
    }
}
