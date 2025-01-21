use integral_geometry::Size;

use landgen::wavefront_collapse::generator::*;
use serde_derive::Deserialize;

use std::collections::hash_map::HashMap;

#[derive(Debug, Deserialize)]
#[serde(remote = "EdgeDescription")]
pub struct EdgeDesc {
    pub name: String,
    pub reversed: Option<bool>,
    pub symmetrical: Option<bool>,
}

#[derive(Debug, Deserialize)]
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

#[derive(Debug, Deserialize)]
#[serde(remote = "TileDescription")]
pub struct TileDesc {
    pub name: String,
    #[serde(with = "EdgesDesc")]
    pub edges: EdgesDescription,
    pub is_negative: Option<bool>,
    pub can_flip: Option<bool>,
    pub can_mirror: Option<bool>,
    pub can_rotate90: Option<bool>,
    pub can_rotate180: Option<bool>,
    pub can_rotate270: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct TileDescriptionHelper(#[serde(with = "TileDesc")] TileDescription);
#[derive(Debug, Deserialize)]
pub struct EdgeDescriptionHelper(#[serde(with = "EdgeDesc")] EdgeDescription);

#[derive(Debug, Deserialize)]
pub struct ComplexEdgeDesc {
    pub begin: Option<EdgeDescriptionHelper>,
    pub fill: Option<EdgeDescriptionHelper>,
    pub end: Option<EdgeDescriptionHelper>,
}
#[derive(Debug, Deserialize)]
pub struct NonStrictComplexEdgesDesc {
    pub top: Option<ComplexEdgeDesc>,
    pub right: Option<ComplexEdgeDesc>,
    pub bottom: Option<ComplexEdgeDesc>,
    pub left: Option<ComplexEdgeDesc>,
}

#[derive(Debug, Deserialize)]
pub struct TemplateDesc {
    pub width: usize,
    pub height: usize,
    pub can_invert: bool,
    pub is_negative: bool,
    pub put_girders: bool,
    pub max_hedgehogs: u8,
    pub wrap: bool,
    pub edges: Option<NonStrictComplexEdgesDesc>,
    pub tiles: Vec<TileDescriptionHelper>,
}

#[derive(Debug, Deserialize)]
pub struct TemplateCollectionDesc {
    pub templates: Vec<TemplateDesc>,
    pub template_types: HashMap<String, Vec<usize>>,
}

impl From<&TemplateDesc> for TemplateDescription {
    fn from(desc: &TemplateDesc) -> Self {
        let [top, right, bottom, left]:[Option<ComplexEdgeDescription>; 4] = if let Some(edges) = &desc.edges {
            [
                &edges.top,
                &edges.right,
                &edges.bottom,
                &edges.left,
            ]
            .map(|e| e.as_ref().map(Into::into))
        } else {
            [None, None, None, None]
        };

        Self {
            size: Size::new(desc.width, desc.height),
            tiles: desc
                .tiles
                .iter()
                .map(|TileDescriptionHelper(t)| t.clone())
                .collect(),
            wrap: desc.wrap,
            edges: NonStrictComplexEdgesDescription {
                top,
                right,
                bottom,
                left,
            },
        }
    }
}

impl From<&ComplexEdgeDesc> for ComplexEdgeDescription {
    fn from(value: &ComplexEdgeDesc) -> Self {
        Self {
            begin: value.begin.as_ref().map(|EdgeDescriptionHelper(e)| e.clone()),
            fill: value.fill.as_ref().map(|EdgeDescriptionHelper(e)| e.clone()),
            end: value.end.as_ref().map(|EdgeDescriptionHelper(e)| e.clone()),
        }
    }
}
