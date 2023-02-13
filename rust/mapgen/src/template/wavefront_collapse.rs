use integral_geometry::{Point, Rect, Size};
use land2d::Land2D;
use landgen::{wavefront_collapse::generator::*, LandGenerationParameters};
use serde_derive::Deserialize;
use serde_yaml;
use std::{borrow::Borrow, collections::hash_map::HashMap, mem::replace};

#[derive(Deserialize)]
#[serde(remote = "EdgeDescription")]
pub struct EdgeDesc {
    pub name: String,
    pub reversed: Option<bool>,
    pub symmetrical: Option<bool>,
}

#[derive(Deserialize)]
#[serde(remote = "EdgesDescription")]
pub struct EdgesDesc {
    #[serde(with = "EdgeDesc")]
    pub top: EdgeDescription,
    #[serde(with = "EdgeDesc")]
    pub right: EdgeDescription,
    #[serde(with = "EdgeDesc")]
    pub bottom: EdgeDescription,
    #[serde(with = "EdgeDesc")]
    pub left: EdgeDescription,
}

#[derive(Deserialize)]
#[serde(remote = "TileDescription")]
pub struct TileDesc {
    pub name: String,
    #[serde(with = "EdgesDesc")]
    pub edges: EdgesDescription,
    pub can_flip: bool,
    pub can_mirror: bool,
    pub can_rotate90: bool,
    pub can_rotate180: bool,
    pub can_rotate270: bool,
}

#[derive(Deserialize)]
pub struct TileDescriptionHelper(#[serde(with = "TileDesc")] TileDescription);

#[derive(Deserialize)]
pub struct TemplateDesc {
    pub width: usize,
    pub height: usize,
    pub can_flip: bool,
    pub is_negative: bool,
    pub put_girders: bool,
    pub max_hedgehogs: u8,
    pub tiles: Vec<TileDescriptionHelper>,
}

#[derive(Deserialize)]
pub struct TemplateCollectionDesc {
    pub templates: Vec<TemplateDesc>,
    pub template_types: HashMap<String, Vec<usize>>,
}

impl From<&TemplateDesc> for TemplateDescription {
    fn from(desc: &TemplateDesc) -> Self {
        Self {
            size: Size::new(desc.width, desc.height),
            tiles: desc
                .tiles
                .iter()
                .map(|TileDescriptionHelper(t)| t.clone())
                .collect(),
        }
    }
}
