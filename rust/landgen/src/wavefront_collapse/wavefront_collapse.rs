use integral_geometry::Size;
use vec2d::Vec2D;
use std::collections::HashMap;

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

struct CollapseRule {
    to_tile: Tile,
    condition: fn([Tile; 4]) -> bool,
}

#[derive(Default)]
pub struct WavefrontCollapse {
    rules: HashMap<Tile, Vec<CollapseRule>>,
}

impl WavefrontCollapse {
    pub fn generate_map<I: Iterator<Item = u32>, F: FnOnce(&mut Vec2D<Tile>)>(
        &mut self,
        map_size: &Size,
        seed_fn: F,
        random_numbers: &mut I,
        ) -> Vec2D<Tile> {
        let mut land = Vec2D::new(&map_size, Tile::Empty);

        seed_fn(&mut land);

        while self.collapse_step(&mut land, random_numbers) {}

        land
    }

    fn add_rule(&mut self, from_tile: Tile, to_tile: Tile, condition: fn([Tile; 4]) -> bool) {
        let rule = CollapseRule { to_tile, condition };
        self.rules
            .entry(from_tile)
            .or_insert_with(Vec::new)
            .push(rule);
    }

    fn collapse_step<I: Iterator<Item = u32>>(
        &self,
        land: &mut Vec2D<Tile>,
        random_numbers: &mut I,
    ) -> bool {
        let mut collapse_occurred = false;
        for x in 0..land.width() {
            for y in 0..land.height() {
                let current_tile = land.get(y, x).expect("valid iteration range");

                if let Some(rules) = self.rules.get(&current_tile) {
                    for rule in rules
                        .iter()
                        .cycle()
                        .skip(
                            random_numbers.next().unwrap_or_default() as usize % (rules.len() + 1),
                        )
                        .take(rules.len())
                    {
                        let neighbors = self.get_neighbors(&land, x, y);
                        let have_neighbors = neighbors.iter().any(|t| !t.is_empty());
                        if have_neighbors && (rule.condition)(neighbors) {
                            *land.get_mut(y, x).expect("valid iteration range") = rule.to_tile;
                            collapse_occurred = true;
                            break;
                        }
                    }
                }
            }
        }

        collapse_occurred
    }

    fn get_neighbors(&self, land: &Vec2D<Tile>, x: usize, y: usize) -> [Tile; 4] {
        [
            land.get(y, x + 1).map(|p| *p).unwrap_or_default(),
            land.get(y + 1, x).map(|p| *p).unwrap_or_default(),
            land.get(y, x.wrapping_sub(1)).map(|p| *p).unwrap_or_default(),
            land.get(y.wrapping_sub(1), x).map(|p| *p).unwrap_or_default(),
        ]
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
        let no_rules_land = wfc.generate_map(&size, |_| {}, &mut rnd);

        assert_eq!(empty_land.as_slice(), no_rules_land.as_slice());

        wfc.add_rule(Tile::Empty, Tile::Numbered(0), |neighbors| {
            neighbors.iter().filter(|&n| *n == Tile::Empty).count() >= 2
        });
        let ruled_map = wfc.generate_map(&size, |_| {}, &mut rnd);

        assert_eq!(ruled_map.as_slice(), empty_land.as_slice());
    }
}
