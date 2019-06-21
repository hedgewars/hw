use super::atlas::AtlasCollection;
use crate::render::camera::Camera;

use integral_geometry::Size;

use png::{ColorType, Decoder, DecodingError};
use std::{
    fs::{read_dir, File},
    io,
    io::BufReader,
    path::Path,
};

pub struct GearRenderer {
    atlas: AtlasCollection,
}

const ATLAS_SIZE: Size = Size::square(1024);

impl GearRenderer {
    pub fn new() -> Self {
        let mut atlas = AtlasCollection::new(ATLAS_SIZE);
        let sprites = load_sprites(Path::new("../../share/hedgewars/Data/Graphics/"))
            .expect("Unable to load Graphics");
        for sprite in &sprites {
            atlas.insert_sprite(*sprite);
        }
        println!(
            "Filled atlas with {} sprites:\n{}",
            sprites.len(),
            atlas.used_space()
        );
        Self { atlas }
    }

    pub fn render(&mut self, camera: &Camera) {
        let projection = camera.projection();
    }
}

fn load_sprite(path: &Path) -> io::Result<Size> {
    let decoder = Decoder::new(BufReader::new(File::open(path)?));
    let (info, mut reader) = decoder.read_info()?;

    let size = Size::new(info.width as usize, info.height as usize);
    Ok(size)
}

fn load_sprites(path: &Path) -> io::Result<Vec<Size>> {
    let mut result = vec![];
    for file in read_dir(path)? {
        let file = file?;
        if let Some(extension) = file.path().extension() {
            if extension == "png" {
                let sprite = load_sprite(&file.path())?;
                result.push(sprite);
            }
        }
    }
    Ok(result)
}
