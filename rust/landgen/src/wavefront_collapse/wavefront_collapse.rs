use integral_geometry::Size;
use rand::distributions::{Distribution, WeightedIndex};
use rand::prelude::SliceRandom;
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

impl Default for Tile {
    fn default() -> Self {
        Self::Empty
    }
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

#[derive(Default, Clone)]
pub struct Cell {
    pub tile: Tile,
    cache: Option<Vec<(u32, Tile)>>,
}

impl From<Tile> for Cell {
    fn from(tile: Tile) -> Self {
        Self { tile, cache: None }
    }
}

pub struct WavefrontCollapse {
    rules: Vec<CollapseRule>,
    grid: Vec2D<Cell>,
    wrap: bool,
}

impl Default for WavefrontCollapse {
    fn default() -> Self {
        Self {
            rules: Vec::new(),
            grid: Vec2D::new(&Size::new(1, 1), Cell::default()),
            wrap: false,
        }
    }
}

impl WavefrontCollapse {
    pub fn new(wrap: bool) -> Self {
        Self {
            rules: Vec::new(),
            grid: Vec2D::new(&Size::new(1, 1), Cell::default()),
            wrap,
        }
    }

    pub fn generate_map<F: FnOnce(&mut Vec2D<Cell>)>(
        &mut self,
        map_size: &Size,
        seed_fn: F,
        random_numbers: &mut impl Rng,
    ) {
        self.grid = Vec2D::new(map_size, Cell::default());

        seed_fn(&mut self.grid);

        let mut backtracks = 0usize;
        loop {
            let (entropy, tiles) = self.collapse_step(backtracks > 128, random_numbers);

            if entropy == 0 {
                self.apply_all(tiles);

                backtracks += 1;
            } else {
                if tiles.is_empty() {
                    // Reached maximum fill level
                    break;
                }

                self.apply_one(tiles, random_numbers)
            }
        }

        if backtracks > 0 {
            println!("[WFC] Had to backtrack {} times...", backtracks);
        }
    }

    pub fn set_rules(&mut self, rules: Vec<CollapseRule>) {
        self.rules = rules;
    }

    fn get_cell(&self, y: usize, x: usize) -> Cell {
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

        self.grid.get(y, x).cloned().unwrap_or_else(|| {
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
            .into()
        })
    }

    fn collapse_step(
        &mut self,
        ignore_unsolvable_tiles: bool,
        random_numbers: &mut impl Rng,
    ) -> (usize, Vec<(usize, usize, Tile)>) {
        let mut tiles_to_collapse = (usize::MAX, Vec::new());

        // Iterate through the tiles in the land
        for y in 0..self.grid.height() {
            for x in 0..self.grid.width() {
                let mut current_cell = self.get_cell(y, x);
                let neighbors = [
                    (y, x.wrapping_add(1)),
                    (y.wrapping_add(1), x),
                    (y, x.wrapping_sub(1)),
                    (y.wrapping_sub(1), x),
                ];

                if let Cell {
                    tile: Tile::Empty,
                    cache: None,
                } = current_cell
                {
                    // calc entropy
                    let [right_tile, bottom_tile, left_tile, top_tile] =
                        neighbors.map(|(y, x)| self.get_cell(y, x).tile);

                    let possibilities: Vec<(u32, Tile)> = self
                        .rules
                        .iter()
                        .filter_map(|rule| {
                            if rule.right.contains(&right_tile)
                                && rule.bottom.contains(&bottom_tile)
                                && rule.left.contains(&left_tile)
                                && rule.top.contains(&top_tile)
                            {
                                // NOTE: quadratic weight
                                Some((rule.weight.pow(2), rule.tile.clone()))
                            } else {
                                None
                            }
                        })
                        .collect();

                    current_cell.cache = possibilities.into();
                    self.grid
                        .get_mut(y, x)
                        .expect("correct iteration over grid")
                        .cache = current_cell.cache.clone();
                }

                if let Cell {
                    tile: Tile::Empty,
                    cache: Some(possibilities),
                } = current_cell
                {
                    let entropy = possibilities.len();
                    if entropy > 0 {
                        if entropy <= tiles_to_collapse.0 {
                            let weights = possibilities.iter().map(|(weight, _)| weight);

                            let tile = if weights.clone().sum::<u32>() == 0 {
                                possibilities
                                    .as_slice()
                                    .choose(random_numbers)
                                    .expect("non-empty slice")
                                    .1
                                    .clone()
                            } else {
                                let distribution = WeightedIndex::new(weights).unwrap();
                                possibilities[distribution.sample(random_numbers)].1.clone()
                            };

                            let entry = (y, x, tile);

                            if entropy < tiles_to_collapse.0 {
                                tiles_to_collapse = (entropy, vec![entry])
                            } else {
                                tiles_to_collapse.1.push(entry)
                            }
                        }
                    } else if !ignore_unsolvable_tiles {
                        let entries = neighbors
                            .iter()
                            .filter(|(y, x)| self.grid.get(*y, *x).is_some())
                            .map(|(y, x)| (*y, *x, Tile::Empty))
                            .collect::<Vec<_>>();

                        // NOTE: entropy is zero at this point
                        if entropy < tiles_to_collapse.0 {
                            tiles_to_collapse = (entropy, entries);
                        } else {
                            tiles_to_collapse.1.extend(entries);
                        }
                    }
                }
            }
        }

        tiles_to_collapse
    }

    fn apply_all(&mut self, tiles: Vec<(usize, usize, Tile)>) {
        for (y, x, tile) in tiles {
            self.invalidate_neighbours_cache(x, y);
            *self
                .grid
                .get_mut(y, x)
                .expect("correct iteration over grid") = tile.into();
        }
    }

    fn apply_one(&mut self, tiles: Vec<(usize, usize, Tile)>, random_numbers: &mut impl Rng) {
        if let Some(&(y, x, ref tile)) = tiles.as_slice().choose(random_numbers) {
            self.invalidate_neighbours_cache(x, y);
            *self
                .grid
                .get_mut(y, x)
                .expect("correct iteration over grid") = (*tile).into();
        }
    }

    fn invalidate_neighbours_cache(&mut self, x: usize, y: usize) {
        let neighbors = [
            (y, x.wrapping_add(1)),
            (y.wrapping_add(1), x),
            (y, x.wrapping_sub(1)),
            (y.wrapping_sub(1), x),
        ];

        for (y, x) in neighbors {
            if let Some(cell) = self.grid.get_mut(y, x) {
                cell.cache = None;
            }
        }
    }

    pub fn grid(&self) -> &Vec2D<Cell> {
        &self.grid
    }
}
