use std::{
    collections::hash_map::HashMap,
    borrow::Borrow,
    mem::replace
};
use serde::{Deserialize};
use serde_derive::{Deserialize};
use serde_yaml;
use integral_geometry::{Point, Size, Rect};
use landgen::{
    outline_template::OutlineTemplate
};
use rand::{thread_rng, Rng};

#[derive(Deserialize)]
struct PointDesc {
    x: u32,
    y: u32
}

#[derive(Deserialize)]
struct RectDesc {
    x: u32,
    y: u32,
    w: u32,
    h: u32
}

#[derive(Deserialize)]
struct TemplateDesc {
    width: usize,
    height: usize,
    can_flip: bool,
    can_invert: bool,
    can_mirror: bool,
    is_negative: bool,
    put_girders: bool,
    max_hedgehogs: u8,
    outline_points: Vec<Vec<RectDesc>>,
    fill_points: Vec<PointDesc>
}

#[derive(Deserialize)]
struct TemplateCollectionDesc {
    templates: Vec<TemplateDesc>,
    template_types: HashMap<String, Vec<usize>>
}

impl From<&TemplateDesc> for OutlineTemplate {
    fn from(desc: &TemplateDesc) -> Self {
        OutlineTemplate {
            islands: desc.outline_points.iter()
                .map(|v| v.iter()
                    .map(|r| Rect::from_size(
                        Point::new(r.x as i32, r.y as i32),
                        Size::new(r.w as usize, r.h as usize)))
                    .collect())
                .collect(),
            fill_points: desc.fill_points.iter()
                .map(|p| Point::new(p.x as i32, p.y as i32))
                .collect(),
            size: Size::new(desc.width, desc.height),
            can_flip: desc.can_flip,
            can_invert: desc.can_invert,
            can_mirror: desc.can_mirror,
            is_negative: desc.is_negative
        }
    }
}

#[derive(PartialEq, Eq, Hash, Clone, Debug)]
struct TemplateType(String);

impl Borrow<str> for TemplateType {
    fn borrow(&self) -> &str {
        self.0.as_str()
    }
}

#[derive(Debug)]
pub struct MapGenerator {
    pub(crate) templates: HashMap<TemplateType, Vec<OutlineTemplate>>
}

impl MapGenerator {
    pub fn new() -> Self {
        Self { templates: HashMap::new() }
    }

    pub fn import_yaml_templates(&mut self, text: &str) {
        let mut desc: TemplateCollectionDesc = serde_yaml::from_str(text).unwrap();
        let templates = replace(&mut desc.templates, vec![]);
        self.templates = desc.template_types.into_iter()
            .map(|(size, indices)|
                (TemplateType(size), indices.iter()
                    .map(|i| (&templates[*i]).into())
                    .collect()))
            .collect();
    }

    pub fn get_template(&self, template_type: &str) -> Option<&OutlineTemplate> {
        self.templates.get(template_type).and_then(|t| thread_rng().choose(t))
    }
}

#[cfg(test)]
mod tests {
    use crate::{
        MapGenerator,
        TemplateType
    };

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
    test: [0]
"#;

        let mut generator = MapGenerator::new();
        generator.import_yaml_templates(&text);

        assert!(generator.templates.contains_key(&TemplateType("test".to_string())));

        let template = generator.get_template("test").unwrap();

        assert_eq!(template.islands[0].len(), 7);
    }
}
