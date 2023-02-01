use super::wavefront_collapse::WavefrontCollapse;
use super::tile_image::TileImage;
use crate::{LandGenerationParameters, LandGenerator};

pub struct WavefrontCollapseLandGenerator {
    wfc: WavefrontCollapse,
    tiles: Vec<TileImage>,
}

impl WavefrontCollapseLandGenerator {
    pub fn new() -> Self {
        Self {
            wfc: WavefrontCollapse::default(),
            tiles: Vec::new()
        }
    }

    pub fn load_template() {

    }
}

impl LandGenerator for WavefrontCollapseLandGenerator {
    fn generate_land<T: Copy + PartialEq + Default, I: Iterator<Item = u32>>(
        &self,
        parameters: &LandGenerationParameters<T>,
        random_numbers: &mut I,
    ) -> land2d::Land2D<T> {
        todo!()
    }
}
