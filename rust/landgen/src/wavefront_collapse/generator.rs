use super::tile_image::{Edge, TileImage};
use super::wavefront_collapse::{CollapseRule, Tile, WavefrontCollapse};
use crate::{LandGenerationParameters, LandGenerator};
use integral_geometry::Size;
use png::Decoder;
use std::collections::HashSet;
use std::fs::File;
use std::io::{BufReader, Result};
use std::path::Path;

#[derive(Clone)]
pub struct EdgeDescription {
    pub name: String,
    pub reversed: Option<bool>,
    pub symmetrical: Option<bool>,
}

#[derive(Clone)]
pub struct EdgesDescription {
    pub top: EdgeDescription,
    pub right: EdgeDescription,
    pub bottom: EdgeDescription,
    pub left: EdgeDescription,
}

#[derive(Clone)]
pub struct TileDescription {
    pub name: String,
    pub edges: EdgesDescription,
    pub is_negative: Option<bool>,
    pub can_flip: Option<bool>,
    pub can_mirror: Option<bool>,
    pub can_rotate90: Option<bool>,
    pub can_rotate180: Option<bool>,
    pub can_rotate270: Option<bool>,
}

#[derive(Clone)]
pub struct TemplateDescription {
    pub size: Size,
    pub tiles: Vec<TileDescription>,
    pub wrap: bool,
}

pub struct WavefrontCollapseLandGenerator {
    pub template: TemplateDescription,
}

impl WavefrontCollapseLandGenerator {
    pub fn new(template: TemplateDescription) -> Self {
        Self { template }
    }

    fn load_image_tiles<T: Copy + PartialEq + Default>(
        parameters: &LandGenerationParameters<T>,
        tile_description: &TileDescription,
    ) -> Result<Vec<TileImage<T, String>>> {
        let mut result = Vec::new();

        let file = File::open(
            Path::new("../share/hedgewars/Data/Tiles")
                .join(&tile_description.name)
                .as_path(),
        )?;
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

        let mut tiles_image_pixels = tiles_image.as_mut_slice().iter_mut();

        let (zero, basic) = if tile_description.is_negative.unwrap_or_default() {
            (parameters.basic(), parameters.zero())
        } else {
            (parameters.zero(), parameters.basic())
        };

        match info.color_type.samples() {
            1 => {
                for line in bytes.chunks_exact(info.line_size) {
                    for value in line.iter() {
                        *tiles_image_pixels
                            .next()
                            .expect("vec2d size matching image dimensions") =
                            if *value == 0 { zero } else { basic };
                    }
                }
            }
            a => {
                for line in bytes.chunks_exact(info.line_size) {
                    for value in line.chunks_exact(a) {
                        print!("{:?},", value);
                        *tiles_image_pixels
                            .next()
                            .expect("vec2d size matching image dimensions") =
                            if value[0] == 0u8 { zero } else { basic };
                    }
                }
            }
        }

        let edges: Vec<Edge<String>> = [
            &tile_description.edges.top,
            &tile_description.edges.right,
            &tile_description.edges.bottom,
            &tile_description.edges.left,
        ]
        .iter()
        .map(|descr| {
            let edge = Edge::new(descr.name.clone(), descr.symmetrical.unwrap_or_default());

            if descr.reversed.unwrap_or_default() {
                edge.reversed()
            } else {
                edge
            }
        })
        .collect();

        let [top_edge, right_edge, bottom_edge, left_edge] = edges.as_slice() else {
            unreachable!()
        };

        let tile = TileImage::<T, String>::new(
            tiles_image,
            top_edge.clone(),
            right_edge.clone(),
            bottom_edge.clone(),
            left_edge.clone(),
        );

        result.push(tile.clone());

        if tile_description.can_flip.unwrap_or_default() {
            result.push(tile.flipped());
        }
        if tile_description.can_mirror.unwrap_or_default() {
            result.push(tile.mirrored());
        }
        if tile_description.can_flip.unwrap_or_default()
            && tile_description.can_mirror.unwrap_or_default()
        {
            result.push(tile.mirrored().flipped());
        }

        if tile_description.can_rotate90.unwrap_or_default() {
            result.push(tile.rotated90());
        }
        if tile_description.can_rotate180.unwrap_or_default() {
            result.push(tile.rotated180());
        }
        if tile_description.can_rotate270.unwrap_or_default() {
            result.push(tile.rotated270());
        }

        Ok(result)
    }

    pub fn load_template<T: Copy + PartialEq + Default>(
        &self,
        parameters: &LandGenerationParameters<T>,
    ) -> Vec<TileImage<T, String>> {
        let mut result = Vec::new();

        for tile_description in self.template.tiles.iter() {
            if let Ok(mut tiles) = Self::load_image_tiles(parameters, tile_description) {
                result.append(&mut tiles);
            }
        }

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

        let mut wfc = WavefrontCollapse::new(self.template.wrap);
        wfc.set_rules(rules);

        let wfc_size = if let Some(first_tile) = tiles.first() {
            let tile_size = first_tile.size();

            Size::new(
                self.template.size.width / tile_size.width,
                self.template.size.height / tile_size.height,
            )
        } else {
            Size::new(1, 1)
        };

        wfc.generate_map(&wfc_size, |_| {}, random_numbers);

        let mut result = land2d::Land2D::new(&self.template.size, parameters.zero);
        let offset_y = result.height() - result.play_height();
        let offset_x = (result.width() - result.play_width()) / 2;

        for row in 0..wfc_size.height {
            for column in 0..wfc_size.width {
                if let Some(Tile::Numbered(tile_index)) = wfc.grid().get(row, column) {
                    let tile = &tiles[*tile_index];

                    for tile_row in 0..tile.size().height {
                        for tile_column in 0..tile.size().width {
                            result.map(
                                (row * tile.size().height + tile_row + offset_y) as i32,
                                (column * tile.size().width + tile_column + offset_x) as i32,
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
