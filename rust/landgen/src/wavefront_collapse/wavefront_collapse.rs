use integral_geometry::Size;
use rand::distr::{weighted::WeightedIndex, Distribution};
use rand::prelude::IndexedRandom;
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

        let mut backtracks = 0usize;
        while let Some(b) = self.collapse_step(random_numbers) {
            backtracks += b;

            if backtracks >= 1000 {
                println!("[WFC] Too much backtracking, stopping generation!");
                break;
            }
        }

        if backtracks > 0 {
            println!("[WFC] Had to backtrack {} times...", backtracks);
        }
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

    fn collapse_step(&mut self, random_numbers: &mut impl Rng) -> Option<usize> {
        let mut tiles_to_collapse = (usize::MAX, Vec::new());

        // Iterate through the tiles in the land
        for x in 0..self.grid.width() {
            for y in 0..self.grid.height() {
                let current_tile = self.get_tile(y, x);

                if let Tile::Empty = current_tile {
                    let neighbors = [
                        (y, x.wrapping_add(1)),
                        (y.wrapping_add(1), x),
                        (y, x.wrapping_sub(1)),
                        (y.wrapping_sub(1), x),
                    ];

                    // calc entropy
                    let [right_tile, bottom_tile, left_tile, top_tile] =
                        neighbors.map(|(y, x)| self.get_tile(y, x));

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
                            let weights = possibilities.iter().map(|(weight, _)| weight.pow(2));
                            let distribution = WeightedIndex::new(weights).unwrap();

                            let entry =
                                (y, x, possibilities[distribution.sample(random_numbers)].1);

                            if entropy < tiles_to_collapse.0 {
                                tiles_to_collapse = (entropy, vec![entry])
                            } else {
                                tiles_to_collapse.1.push(entry)
                            }
                        }
                    } else {
                        /*
                        println!("We're here: {}, {}", x, y);
                        println!(
                            "Neighbour tiles are: {:?} {:?} {:?} {:?}",
                            right_tile, bottom_tile, left_tile, top_tile
                        );
                        println!("Rules are: {:?}", self.rules);
                        */

                        let entries = neighbors
                            .iter()
                            .filter(|(y, x)| self.grid.get(*y, *x).is_some())
                            .map(|(y, x)| (*y, *x, Tile::Empty))
                            .collect::<Vec<_>>();

                        if entropy < tiles_to_collapse.0 {
                            tiles_to_collapse = (entropy, entries);
                        } else {
                            tiles_to_collapse.1.extend(entries);
                        }

                        //todo!("no collapse possible - what to do?")
                    }
                }
            }
        }

        if tiles_to_collapse.0 == 0 {
            // cannot collapse, we're clearing some tiles

            for (y, x, tile) in tiles_to_collapse.1 {
                *self
                    .grid
                    .get_mut(y, x)
                    .expect("correct iteration over grid") = tile;
            }

            Some(1)
        } else {
            if let Some(&(y, x, tile)) = tiles_to_collapse.1.as_slice().choose(random_numbers) {
                *self
                    .grid
                    .get_mut(y, x)
                    .expect("correct iteration over grid") = tile;

                Some(0)
            } else {
                None
            }
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
