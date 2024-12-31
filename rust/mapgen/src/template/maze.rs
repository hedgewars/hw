use landgen::maze::MazeTemplate;
use serde_derive::Deserialize;

use std::collections::hash_map::HashMap;
#[derive(Deserialize)]
pub struct TemplateDesc {
    width: usize,
    height: usize,
    max_hedgehogs: u8,
    cell_size: usize,
    distortion_limiting_factor: u32,
    braidness: u32,
    invert: bool,
}

#[derive(Deserialize)]
pub struct TemplateCollectionDesc {
    pub templates: Vec<TemplateDesc>,
    pub template_types: HashMap<String, Vec<usize>>,
}

impl From<&TemplateDesc> for MazeTemplate {
    fn from(desc: &TemplateDesc) -> Self {
        MazeTemplate {
            width: desc.width,
            height: desc.height,
            cell_size: desc.cell_size,
            inverted: desc.invert,
            distortion_limiting_factor: desc.distortion_limiting_factor,
            braidness: desc.braidness,
        }
    }
}
