use integral_geometry::{Point, Rect, Size};

use landgen::outline_template_based::outline_template::OutlineTemplate;
use serde_derive::Deserialize;

use std::collections::hash_map::HashMap;

#[derive(Deserialize)]
pub struct PointDesc {
    x: u32,
    y: u32,
}

#[derive(Deserialize)]
pub struct RectDesc {
    x: u32,
    y: u32,
    w: u32,
    h: u32,
}

#[derive(Deserialize)]
pub struct TemplateDesc {
    width: usize,
    height: usize,
    can_flip: bool,
    can_invert: bool,
    can_mirror: bool,
    is_negative: bool,
    put_girders: bool,
    max_hedgehogs: u8,
    outline_points: Vec<Vec<RectDesc>>,
    fill_points: Vec<PointDesc>,
}

#[derive(Deserialize)]
pub struct TemplateTypeDesc {
    pub indices: Vec<usize>,
    pub force_invert: Option<bool>,
}

#[derive(Deserialize)]
pub struct TemplateCollectionDesc {
    pub templates: Vec<TemplateDesc>,
    pub template_types: HashMap<String, TemplateTypeDesc>,
}

impl From<&TemplateDesc> for OutlineTemplate {
    fn from(desc: &TemplateDesc) -> Self {
        OutlineTemplate {
            islands: desc
                .outline_points
                .iter()
                .map(|v| {
                    v.iter()
                        .map(|r| {
                            Rect::from_size(
                                Point::new(r.x as i32, r.y as i32),
                                Size::new(r.w as usize, r.h as usize),
                            )
                        })
                        .collect()
                })
                .collect(),
            fill_points: desc
                .fill_points
                .iter()
                .map(|p| Point::new(p.x as i32, p.y as i32))
                .collect(),
            size: Size::new(desc.width, desc.height),
            can_flip: desc.can_flip,
            can_invert: desc.can_invert,
            can_mirror: desc.can_mirror,
            is_negative: desc.is_negative,
        }
    }
}
