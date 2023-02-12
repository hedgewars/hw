use super::tile_image::{Edge, TileImage};
use super::wavefront_collapse::{CollapseRule, Tile, WavefrontCollapse};
use crate::{LandGenerationParameters, LandGenerator};
use integral_geometry::Size;
use png::Decoder;
use std::collections::HashSet;
use std::fs::File;
use std::io::BufReader;

pub struct WavefrontCollapseLandGenerator {
    pub size: Size,
}

impl WavefrontCollapseLandGenerator {
    pub fn new(size: &Size) -> Self {
        Self { size: *size }
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

        let top_edge = Edge::new("ef".to_owned(), false);
        let right_edge = top_edge.reversed();
        let bottom_edge = Edge::new("ee".to_owned(), true);
        let left_edge = bottom_edge.clone();

        let tile =
            TileImage::<T, String>::new(tiles_image, top_edge, right_edge, bottom_edge, left_edge);

        result.push(tile.clone());
        result.push(tile.rotated90());
        result.push(tile.rotated180());
        result.push(tile.rotated270());

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
                if tiles[p].left_edge().is_compatible(tile.right_edge()) {
                    rules[p].left.insert(Tile::Numbered(i));
                    right.insert(Tile::Numbered(p));
                }

                if tiles[p].right_edge().is_compatible(tile.left_edge()) {
                    rules[p].right.insert(Tile::Numbered(i));
                    left.insert(Tile::Numbered(p));
                }

                if tiles[p].top_edge().is_compatible(tile.bottom_edge()) {
                    rules[p].top.insert(Tile::Numbered(i));
                    bottom.insert(Tile::Numbered(p));
                }

                if tiles[p].bottom_edge().is_compatible(tile.top_edge()) {
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

        let wfc_size = if let Some(first_tile) = tiles.first() {
            let tile_size = first_tile.size();

            Size::new(
                self.size.width / tile_size.width,
                self.size.height / tile_size.height,
            )
        } else {
            Size::new(1, 1)
        };

        wfc.generate_map(&wfc_size, |_| {}, random_numbers);

        let grid = wfc.grid();

        for r in 0..grid.height() {
            for c in 0..grid.width() {
                print!("{:?} ", grid.get(r, c));
            }

            println!();
        }

        let mut result = land2d::Land2D::new(&self.size, parameters.zero);

        for row in 0..wfc_size.height {
            for column in 0..wfc_size.width {
                if let Some(Tile::Numbered(tile_index)) = wfc.grid().get(row, column) {
                    let tile = &tiles[*tile_index];

                    for tile_row in 0..tile.size().height {
                        for tile_column in 0..tile.size().width {
                            result.map(
                                (row * tile.size().height + tile_row) as i32,
                                (column * tile.size().width + tile_column) as i32,
                                |p| {
                                    *p =
                                        *tile.get(tile_row, tile_column).unwrap_or(&parameters.zero)
                                },
                            );
                        }
                    }
                }
            }
        }

        result
    }
}

#[cfg(test)]
mod tests {
    use super::WavefrontCollapseLandGenerator;
    use crate::{LandGenerationParameters, LandGenerator};
    use integral_geometry::Size;
    use std::fs::File;
    use std::io::BufWriter;
    use std::path::Path;
    use vec2d::Vec2D;

    #[test]
    fn test_generation() {
        let wfc_gen = WavefrontCollapseLandGenerator::new(&Size::new(2048, 1024));
        let landgen_params = LandGenerationParameters::new(0u32, 0xff000000u32, 0, true, true);
        let land = wfc_gen.generate_land(&landgen_params, &mut [0u32, 1u32, 3u32, 5u32, 7u32, 11u32].into_iter().cycle());

        let path = Path::new(r"output.png");
        let file = File::create(path).unwrap();
        let ref mut w = BufWriter::new(file);

        let mut encoder = png::Encoder::new(w, land.width() as u32, land.height() as u32); // Width is 2 pixels and height is 1.
        encoder.set_color(png::ColorType::Rgba);
        encoder.set_depth(png::BitDepth::Eight);
        encoder.set_source_gamma(png::ScaledFloat::from_scaled(45455)); // 1.0 / 2.2, scaled by 100000
        encoder.set_source_gamma(png::ScaledFloat::new(1.0 / 2.2)); // 1.0 / 2.2, unscaled, but rounded
        let source_chromaticities = png::SourceChromaticities::new(
            // Using unscaled instantiation here
            (0.31270, 0.32900),
            (0.64000, 0.33000),
            (0.30000, 0.60000),
            (0.15000, 0.06000),
        );
        encoder.set_source_chromaticities(source_chromaticities);
        let mut writer = encoder.write_header().unwrap();

        writer.write_image_data(land.raw_pixel_bytes()).unwrap(); // Save
    }
}
