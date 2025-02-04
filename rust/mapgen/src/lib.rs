mod template;
pub mod theme;

use self::theme::Theme;
use crate::template::maze::TemplateCollectionDesc as MazeTemplateCollectionDesc;
use crate::template::outline::TemplateCollectionDesc as OutlineTemplateCollectionDesc;
use crate::template::wavefront_collapse::TemplateCollectionDesc as WfcTemplateCollectionDesc;

use std::path::{Path, PathBuf};

use land2d::Land2D;
use landgen::{
    maze::{MazeLandGenerator, MazeTemplate},
    outline_template_based::{
        outline_template::OutlineTemplate, template_based::TemplatedLandGenerator,
    },
    wavefront_collapse::generator::{
        TemplateDescription as WfcTemplate, WavefrontCollapseLandGenerator,
    },
    LandGenerationParameters, LandGenerator,
};
use rand::Rng;

use rand::prelude::IndexedRandom;
use std::{borrow::Borrow, collections::hash_map::HashMap};
use std::fmt::Debug;
use vec2d::Vec2D;

#[derive(PartialEq, Eq, Hash, Clone, Debug)]
struct TemplateType(String);

impl Borrow<str> for TemplateType {
    fn borrow(&self) -> &str {
        self.0.as_str()
    }
}

#[derive(Debug)]
pub struct MapGenerator<T> {
    pub(crate) templates: HashMap<TemplateType, Vec<T>>,
    data_path: PathBuf,
}

impl<T> MapGenerator<T> {
    pub fn new(data_path: &Path) -> Self {
        Self {
            templates: HashMap::new(),
            data_path: data_path.to_owned(),
        }
    }

    pub fn get_template<R: Rng>(&self, template_type: &str, rng: &mut R) -> Option<&T> {
        self.templates
            .get(template_type)
            .and_then(|t| t.as_slice().choose(rng))
    }

    pub fn make_texture<LandT>(
        &self,
        land: &Land2D<LandT>,
        parameters: &LandGenerationParameters<LandT>,
        theme: &Theme,
    ) -> Vec2D<u32>
    where
        LandT: Copy + Default + PartialEq,
    {
        let mut texture = Vec2D::new(&land.size().size(), 0);

        if let Some(land_sprite) = theme.land_texture() {
            for (sprite_row, (land_row, tex_row)) in land_sprite
                .rows()
                .cycle()
                .zip(land.rows().zip(texture.rows_mut()))
            {
                let mut x_offset = 0;
                while sprite_row.len() < land.width() - x_offset {
                    let copy_range = x_offset..x_offset + sprite_row.len();
                    tex_row_copy(
                        parameters.basic(),
                        &land_row[copy_range.clone()],
                        &mut tex_row[copy_range],
                        sprite_row,
                    );

                    x_offset += land_sprite.width() as usize
                }

                if x_offset < land.width() {
                    let final_range = x_offset..land.width();
                    tex_row_copy(
                        parameters.basic(),
                        &land_row[final_range.clone()],
                        &mut tex_row[final_range],
                        &sprite_row[..land.width() - x_offset],
                    );
                }
            }
        } else {
            eprintln!("No land texture, expect empty land");
        }

        if true {
           shoppa_border(parameters.basic(), &land, &mut texture, 8);
        } else {
            if let Some(border_sprite) = theme.border_texture() {
                assert!(border_sprite.height() <= 512);
                let border_width = (border_sprite.height() / 2) as u8;
                let border_sprite = border_sprite.to_tiled();

                let mut offsets = vec![255u8; land.width()];

                land_border_pass(
                    parameters.basic(),
                    land.rows().rev().zip(texture.rows_mut().rev()),
                    &mut offsets,
                    border_width,
                    |x, y| {
                        border_sprite.get_pixel(
                            x % border_sprite.width() as usize,
                            border_sprite.height() as usize - 1 - y,
                        )
                    },
                );

                offsets.iter_mut().for_each(|v| *v = 255);

                land_border_pass(
                    parameters.basic(),
                    land.rows().zip(texture.rows_mut()),
                    &mut offsets,
                    border_width,
                    |x, y| border_sprite.get_pixel(x % border_sprite.width() as usize, y),
                );
            }
        }
        texture
    }
}

impl MapGenerator<OutlineTemplate> {
    pub fn import_yaml_templates(&mut self, text: &str) {
        let mut desc: OutlineTemplateCollectionDesc = serde_yaml::from_str(text).unwrap();
        let templates = std::mem::take(&mut desc.templates);
        self.templates = desc
            .template_types
            .into_iter()
            .map(|(size, indices)| {
                (
                    TemplateType(size),
                    indices
                        .indices
                        .iter()
                        .map(|i| Into::<OutlineTemplate>::into(templates[*i].clone()))
                        .map(|o| {
                            if indices.force_invert == Some(true) {
                                o.cavern()
                            } else {
                                o
                            }
                        })
                        .collect(),
                )
            })
            .collect();
    }

    pub fn build_generator(&self, template: OutlineTemplate) -> impl LandGenerator {
        TemplatedLandGenerator::new(template)
    }
}

impl MapGenerator<WfcTemplate> {
    pub fn import_yaml_templates(&mut self, text: &str) {
        let mut desc: WfcTemplateCollectionDesc = toml::from_str(text).unwrap();
        let templates = std::mem::take(&mut desc.templates);
        self.templates = desc
            .template_types
            .into_iter()
            .map(|(size, indices)| {
                (
                    TemplateType(size),
                    indices
                        .iter()
                        .map(|i| templates[*i].to_template(&desc.tiles, &desc.edges))
                        .collect(),
                )
            })
            .collect();
    }

    pub fn build_generator(&self, template: WfcTemplate) -> impl LandGenerator {
        WavefrontCollapseLandGenerator::new(template, &self.data_path)
    }
}

impl MapGenerator<MazeTemplate> {
    pub fn import_yaml_templates(&mut self, text: &str) {
        let mut desc: MazeTemplateCollectionDesc = serde_yaml::from_str(text).unwrap();
        let templates = std::mem::take(&mut desc.templates);
        self.templates = desc
            .template_types
            .into_iter()
            .map(|(size, indices)| {
                (
                    TemplateType(size),
                    indices.iter().map(|i| (&templates[*i]).into()).collect(),
                )
            })
            .collect();
    }

    pub fn build_generator(&self, template: MazeTemplate) -> impl LandGenerator {
        MazeLandGenerator::new(template)
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct Color(u32);

impl Color {
    #[inline]
    fn red(self) -> u8 {
        (self.0 & 0xFF) as u8
    }

    #[inline]
    fn green(self) -> u8 {
        (self.0 >> 8 & 0xFF) as u8
    }

    #[inline]
    fn blue(self) -> u8 {
        (self.0 >> 16 & 0xFF) as u8
    }

    #[inline]
    fn alpha(self) -> u8 {
        (self.0 >> 24 & 0xFF) as u8
    }
}

#[inline]
fn lerp(from: u8, to: u8, coef: u8) -> u8 {
    ((from as u16 * (256 - coef as u16) + to as u16 * coef as u16) / 256) as u8
}

#[inline]
fn blend(source: u32, target: u32) -> u32 {
    let source = Color(source);
    let target = Color(target);
    let alpha = lerp(target.alpha(), 255, source.alpha());
    let red = lerp(target.red(), source.red(), source.alpha());
    let green = lerp(target.green(), source.green(), source.alpha());
    let blue = lerp(target.blue(), source.blue(), source.alpha());
    (red as u32) | (green as u32) << 8 | (blue as u32) << 16 | (alpha as u32) << 24
}

fn land_border_pass<'a, LandT, T, F>(
    basic_value: LandT,
    rows: T,
    offsets: &mut [u8],
    border_width: u8,
    pixel_getter: F,
) where
    LandT: Default + PartialEq + 'a,
    T: Iterator<Item = (&'a [LandT], &'a mut [u32])>,
    F: (Fn(usize, usize) -> u32),
{
    for (land_row, tex_row) in rows {
        for (x, ((land_v, tex_v), offset_v)) in land_row
            .iter()
            .zip(tex_row.iter_mut())
            .zip(offsets.iter_mut())
            .enumerate()
        {
            *offset_v = if *land_v == basic_value {
                if *offset_v < border_width {
                    *tex_v = blend(pixel_getter(x, *offset_v as usize), *tex_v)
                }
                offset_v.saturating_add(1)
            } else {
                0
            }
        }
    }
}

fn shoppa_border<LandT>(
    basic_value: LandT,
    land: &Land2D<LandT>,
    texture: &mut Vec2D<u32>,
    depth: u8,
) where
    LandT: Copy + Default + PartialEq,
{
    //land.rows().rev().zip(texture.rows_mut().rev()),
    let mut depth_field = Vec2D::new(&land.size().size(), 0u8);

    for (d, l) in depth_field
        .as_mut_slice()
        .iter_mut()
        .zip(land.raw_pixels().iter())
    {
        *d = if *l == basic_value { depth } else { 0 };
    }

    let chunk_size = depth_field.width();
    for i in 1..depth_field.height() {
        let split_index = i * chunk_size;
        let (left, right) = depth_field.as_mut_slice().split_at_mut(split_index);

        let prev_chunk = &left[(i - 1) * chunk_size..i * chunk_size];
        let cur_chunk = &mut right[..chunk_size];
        process_shoppa_row_pair(prev_chunk, cur_chunk);
    }

    for i in (1..depth_field.height()).rev() {
        let split_index = i * chunk_size;
        let (left, right) = depth_field.as_mut_slice().split_at_mut(split_index);

        let cur_chunk = &mut left[(i - 1) * chunk_size..i * chunk_size];
        let prev_chunk = &right[..chunk_size];
        process_shoppa_row_pair(prev_chunk, cur_chunk);
    }
    
    for r in depth_field.rows_mut() {
        let mut it = r.iter_mut();
        let mut p = *it.next().unwrap();
        for c in it {
            if p < *c {
                *c = p + 1;
            }
            
            p = *c
        }
        
        let mut it = r.iter_mut().rev();
        let mut p = *it.next().unwrap();
        for c in it {
            if p < *c {
                *c = p + 1;
            }

            p = *c
        }
    }

    for (row_index, (tex_row, depth_row)) in texture.rows_mut().zip(depth_field.rows()).enumerate()
    {
        for (column_index, (tex, &d)) in tex_row.iter_mut().zip(depth_row.iter()).enumerate() {
            if d > 0 && d < depth {
                *tex = if ((row_index + column_index) / 8) & 1 != 0 {
                    0xff00ffff
                } else {
                    0xff000000
                };
            }
        }
    }
}

fn process_shoppa_row_pair(prev_chunk: &[u8], cur_chunk: &mut [u8]) {
    for (&p, c) in prev_chunk.iter().zip(cur_chunk.iter_mut()) {
        if p < *c {
            *c = p + 1;
        }
    }
}

fn tex_row_copy<LandT>(
    basic_value: LandT,
    land_row: &[LandT],
    tex_row: &mut [u32],
    sprite_row: &[u32],
) where
    LandT: Default + PartialEq,
{
    for ((land_v, tex_v), sprite_v) in land_row.iter().zip(tex_row.iter_mut()).zip(sprite_row) {
        *tex_v = if *land_v == basic_value { *sprite_v } else { 0 }
    }
}

#[cfg(test)]
mod tests {
    use crate::{MapGenerator, OutlineTemplate, TemplateType};
    use rand::thread_rng;
    use std::path::Path;

    #[test]
    fn simple_load() {
        let text = r#"
# comment

templates:
  -
    width: 3072
    height: 1424
    can_flip: false
    can_invert: false
    can_mirror: true
    is_negative: false
    put_girders: true
    max_hedgehogs: 18
    outline_points:
      -
        - {x: 748, y: 1424, w: 1, h: 1}
        - {x: 636, y: 1252, w: 208, h: 72}
        - {x: 898, y: 1110, w: 308, h: 60}
        - {x: 1128, y: 1252, w: 434, h: 40}
        - {x: 1574, y: 1112, w: 332, h: 40}
        - {x: 1802, y: 1238, w: 226, h: 36}
        - {x: 1930, y: 1424, w: 1, h: 1}
    fill_points:
      - {x: 1023, y: 0}
      - {x: 1023, y: 0}

template_types:
    test:
      indices: [0]
"#;

        let mut generator = MapGenerator::<OutlineTemplate>::new(Path::new(""));
        generator.import_yaml_templates(&text);

        assert!(generator
            .templates
            .contains_key(&TemplateType("test".to_string())));

        let template = generator.get_template("test", &mut thread_rng()).unwrap();

        assert_eq!(template.islands[0].len(), 7);
    }
}
