use integral_geometry::Size;
use std::collections::{HashMap, HashSet};
use vec2d::Vec2D;

#[derive(PartialEq, Eq, Hash, Clone, Copy, Debug)]
pub enum Tile {
    Empty,
    Outside,
    Numbered(u32),
}

impl Tile {
    fn is(&self, i: u32) -> bool {
        *self == Tile::Numbered(i)
    }

    fn is_empty(&self) -> bool {
        match self {
            Tile::Empty => true,
            Tile::Outside => true,
            _ => false,
        }
    }

    fn is_empty_or(&self, i: u32) -> bool {
        match self {
            Tile::Numbered(n) => *n == i,
            Tile::Empty => true,
            _ => false,
        }
    }

    fn is_void_or(&self, i: u32) -> bool {
        match self {
            Tile::Numbered(n) => *n == i,
            _ => true,
        }
    }
}

impl Default for Tile {
    fn default() -> Self {
        Tile::Outside
    }
}

pub struct CollapseRule {
    tile: Tile,
    right: HashSet<Tile>,
    bottom: HashSet<Tile>,
    left: HashSet<Tile>,
    top: HashSet<Tile>,
}

pub struct WavefrontCollapse {
    rules: Vec<CollapseRule>,
    grid: Vec2D<Tile>,
}

impl Default for WavefrontCollapse {
    fn default() -> Self {
        Self {
            rules: Vec::new(),
            grid: Vec2D::new(&Size::new(1, 1), Tile::Empty),
        }
    }
}

impl WavefrontCollapse {
    pub fn generate_map<I: Iterator<Item = u32>, F: FnOnce(&mut Vec2D<Tile>)>(
        &mut self,
        map_size: &Size,
        seed_fn: F,
        random_numbers: &mut I,
    ) {
        self.grid = Vec2D::new(&map_size, Tile::Empty);

        seed_fn(&mut self.grid);

        while self.collapse_step(random_numbers) {}
    }

    fn add_rule(&mut self, rule: CollapseRule) {
        self.rules.push(rule);
    }

    fn get_tile(&self, y: usize, x: usize) -> Tile {
        self.grid.get(y, x).map(|p| *p).unwrap_or_default()
    }

    fn collapse_step<I: Iterator<Item = u32>>(&mut self, random_numbers: &mut I) -> bool {
        let mut tiles_to_collapse = (usize::max_value(), Vec::new());

        // Iterate through the tiles in the land
        for x in 0..self.grid.width() {
            for y in 0..self.grid.height() {
                let current_tile = self.get_tile(y, x);

                if let Tile::Empty = current_tile {
                    // calc entropy
                    let right_tile = self.get_tile(y, x + 1);
                    let bottom_tile = self.get_tile(y + 1, x);
                    let left_tile = self.get_tile(y, x.wrapping_sub(1));
                    let top_tile = self.get_tile(y.wrapping_sub(1), x);

                    let possibilities: Vec<Tile> = self
                        .rules
                        .iter()
                        .filter_map(|rule| {
                            if rule.right.contains(&right_tile)
                                && rule.bottom.contains(&bottom_tile)
                                && rule.left.contains(&left_tile)
                                && rule.top.contains(&top_tile)
                            {
                                Some(rule.tile)
                            } else {
                                None
                            }
                        })
                        .collect();

                    let entropy = possibilities.len();
                    if entropy > 0 && entropy <= tiles_to_collapse.0 {
                        let entry = (
                            y,
                            x,
                            possibilities
                                [random_numbers.next().unwrap_or_default() as usize % entropy],
                        );

                        if entropy < tiles_to_collapse.0 {
                            tiles_to_collapse = (entropy, vec![entry])
                        } else {
                            tiles_to_collapse.1.push(entry)
                        }
                    } else {
                        todo!("no collapse possible")
                    }
                }
            }
        }

        let tiles_to_collapse = tiles_to_collapse.1;
        let possibilities_number = tiles_to_collapse.len();

        if possibilities_number > 0 {
            let (y, x, tile) = tiles_to_collapse
                [random_numbers.next().unwrap_or_default() as usize % possibilities_number];

            *self
                .grid
                .get_mut(y, x)
                .expect("correct iteration over grid") = tile;

            true
        } else {
            false
        }
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
        let mut rnd = [0u32; 64].into_iter();
        let mut wfc = WavefrontCollapse::default();

        let empty_land = Vec2D::new(&size, Tile::Empty);

        assert_eq!(empty_land.as_slice(), wfc.grid.as_slice());
    }
}
