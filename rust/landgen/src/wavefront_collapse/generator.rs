use super::tile_image::{Edge, TileImage};
use super::wavefront_collapse::{CollapseRule, Tile, WavefrontCollapse};
use crate::{LandGenerationParameters, LandGenerator};
use integral_geometry::Size;
use png::Decoder;
use std::collections::HashSet;
use std::fs::File;
use std::io::BufReader;

pub struct WavefrontCollapseLandGenerator {}

impl WavefrontCollapseLandGenerator {
    pub fn new() -> Self {
        Self {}
    }

    pub fn load_template<T: Copy + PartialEq + Default>(
        &self,
        parameters: &LandGenerationParameters<T>,
    ) -> Vec<TileImage<T, String>> {
        let mut result = Vec::new();

        let file = File::open("sample.png").expect("file exists");
        let decoder = Decoder::new(BufReader::new(file));
        let mut reader = decoder.read_info().unwrap();

        let info = reader.info();
        let mut tiles_image = vec2d::Vec2D::new(
            &Size::new(info.width as usize, info.height as usize),
            parameters.zero,
        );

        let mut buf = vec![0; reader.output_buffer_size()];
        let info = reader.next_frame(&mut buf).unwrap();
        let bytes = &buf[..info.buffer_size()];

        let mut tiles_image_pixels = tiles_image.as_mut_slice().into_iter();

        for line in bytes.chunks_exact(info.line_size) {
            for value in line.chunks_exact(info.color_type.samples()) {
                *tiles_image_pixels
                    .next()
                    .expect("vec2d size matching image dimensions") =
                    if value.into_iter().all(|p| *p == 0) {
                        parameters.zero
                    } else {
                        parameters.basic
                    };
            }
        }

        let top_edge = Edge::new("edge".to_owned(), false);
        let right_edge = Edge::new("edge".to_owned(), false);
        let bottom_edge = Edge::new("edge".to_owned(), false);
        let left_edge = Edge::new("edge".to_owned(), false);

        let tile =
            TileImage::<T, String>::new(tiles_image, top_edge, right_edge, bottom_edge, left_edge);

        result.push(tile.clone());
        result.push(tile.mirrored());

        result
    }
}

impl LandGenerator for WavefrontCollapseLandGenerator {
    fn generate_land<T: Copy + PartialEq + Default, I: Iterator<Item = u32>>(
        &self,
        parameters: &LandGenerationParameters<T>,
        random_numbers: &mut I,
    ) -> land2d::Land2D<T> {
        let tiles = self.load_template(parameters);

        let mut rules = Vec::<CollapseRule>::new();

        let default_connection = HashSet::from_iter(vec![Tile::Outside, Tile::Empty].into_iter());
        for (i, tile) in tiles.iter().enumerate() {
            let mut right = default_connection.clone();
            let mut bottom = default_connection.clone();
            let mut left = default_connection.clone();
            let mut top = default_connection.clone();

            for p in 0..i {
                if tiles[p].left_edge() == tile.right_edge() {
                    rules[p].left.insert(Tile::Numbered(i));
                    right.insert(Tile::Numbered(p));
                }

                if tiles[p].right_edge() == tile.left_edge() {
                    rules[p].right.insert(Tile::Numbered(i));
                    left.insert(Tile::Numbered(p));
                }

                if tiles[p].top_edge() == tile.bottom_edge() {
                    rules[p].top.insert(Tile::Numbered(i));
                    bottom.insert(Tile::Numbered(p));
                }

                if tiles[p].bottom_edge() == tile.top_edge() {
                    rules[p].bottom.insert(Tile::Numbered(i));
                    top.insert(Tile::Numbered(p));
                }
            }

            rules.push(CollapseRule {
                tile: Tile::Numbered(i),
                top,
                right,
                bottom,
                left,
            });
        }

        let mut wfc = WavefrontCollapse::default();
        wfc.set_rules(rules);

        wfc.generate_map(&Size::new(40, 20), |_| {}, random_numbers);

        let grid = wfc.grid();

        for r in 0..grid.height() {
            for c in 0..grid.width() {
                print!("{:?}", grid.get(r, c));
            }

            println!();
        }

        todo!("build result")
    }
}

#[cfg(test)]
mod tests {
    use super::WavefrontCollapseLandGenerator;
    use crate::{LandGenerationParameters, LandGenerator};
    use integral_geometry::Size;
    use vec2d::Vec2D;

    #[test]
    fn test_generation() {
        let wfc_gen = WavefrontCollapseLandGenerator::new();
        let landgen_params = LandGenerationParameters::new(0u8, 255u8, 0, true, true);
        wfc_gen.generate_land(&landgen_params, &mut std::iter::repeat(1u32));
    }
}
