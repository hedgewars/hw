use integral_geometry::Size;

use landgen::wavefront_collapse::generator::*;
use serde_derive::Deserialize;

use std::collections::hash_map::HashMap;

#[derive(Debug, Deserialize)]
pub struct TileDesc {
    pub name: String,
    pub edges: [String; 4],
    pub is_negative: Option<bool>,
    pub can_flip: Option<bool>,
    pub can_mirror: Option<bool>,
    pub can_rotate90: Option<bool>,
    pub can_rotate180: Option<bool>,
    pub can_rotate270: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct ComplexEdgeDesc {
    pub begin: Option<String>,
    pub fill: Option<String>,
    pub end: Option<String>,
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
    pub can_invert: Option<bool>,
    pub is_negative: Option<bool>,
    pub put_girders: Option<bool>,
    pub max_hedgehogs: u8,
    pub wrap: Option<bool>,
    pub edges: Option<String>,
    pub tiles: Vec<String>,
}

#[derive(Debug, Deserialize)]
pub struct TemplateCollectionDesc {
    pub templates: Vec<TemplateDesc>,
    pub tiles: HashMap<String, Vec<TileDesc>>,
    pub edges: HashMap<String, NonStrictComplexEdgesDesc>,
    pub template_types: HashMap<String, Vec<usize>>,
}

impl TemplateDesc {
    pub fn to_template(&self, tiles: &HashMap<String, Vec<TileDesc>>, edges: &HashMap<String, NonStrictComplexEdgesDesc>) -> TemplateDescription {
        let [top, right, bottom, left]: [Option<ComplexEdgeDescription>; 4] =
            if let Some(edges_name) = &self.edges {
                let edges = edges.get(edges_name).expect("missing template edges");
                [&edges.top, &edges.right, &edges.bottom, &edges.left]
                    .map(|e| e.as_ref().map(Into::into))
            } else {
                [None, None, None, None]
            };

        let tiles = self.tiles.iter().flat_map(|t| tiles.get(t).expect("missing template tiles")).collect::<Vec<_>>();

        TemplateDescription {
            size: Size::new(self.width, self.height),
            tiles: tiles.into_iter().map(|t| t.into()).collect(),
            wrap: self.wrap.unwrap_or(false),
            can_invert: self.can_invert.unwrap_or(false),
            is_negative: self.is_negative.unwrap_or(false),
            edges: NonStrictComplexEdgesDescription {
                top,
                right,
                bottom,
                left,
            },
        }
    }
}

impl From<&TileDesc> for TileDescription {
    fn from(desc: &TileDesc) -> Self {
        let [top, right, bottom, left]: [EdgeDescription; 4] = desc.edges.clone().map(|e| e.into());

        Self {
            name: desc.name.clone(),
            edges: EdgesDescription {
                top,
                right,
                bottom,
                left,
            },
            is_negative: desc.is_negative,
            can_flip: desc.can_flip,
            can_mirror: desc.can_mirror,
            can_rotate90: desc.can_rotate90,
            can_rotate180: desc.can_rotate180,
            can_rotate270: desc.can_rotate270,
        }
    }
}

impl From<&ComplexEdgeDesc> for ComplexEdgeDescription {
    fn from(value: &ComplexEdgeDesc) -> Self {
        Self {
            begin: value.begin.as_ref().map(|e| e.into()),
            fill: value.fill.as_ref().map(|e| e.into()),
            end: value.end.as_ref().map(|e| e.into()),
        }
    }
}
