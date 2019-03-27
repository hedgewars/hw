use super::atlas::AtlasCollection;
use integral_geometry::Size;

struct GearRenderer {
    atlas: AtlasCollection,
}

const ATLAS_SIZE: Size = Size::square(2048);

impl GearRenderer {
    pub fn new() -> Self {
        let atlas = AtlasCollection::new(ATLAS_SIZE);
        Self { atlas }
    }
}
