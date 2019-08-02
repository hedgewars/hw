use super::{atlas::AtlasCollection, gl::Texture2D};
use crate::render::camera::Camera;

use integral_geometry::{Rect, Size};

use crate::render::atlas::SpriteIndex;
use png::{ColorType, Decoder, DecodingError};
use std::path::PathBuf;
use std::{
    collections::HashMap,
    ffi::OsString,
    fs::{read_dir, File},
    io,
    io::BufReader,
    path::Path,
};

pub struct GearRenderer {
    atlas: AtlasCollection,
}

struct SpriteData {
    size: Size,
    filename: PathBuf,
}

const ATLAS_SIZE: Size = Size::square(2024);

impl GearRenderer {
    pub fn new() -> Self {
        let mut lookup = Vec::with_capacity(2048);

        let mut atlas = AtlasCollection::new(ATLAS_SIZE);
        let mut sprites = load_sprites(Path::new("../../share/hedgewars/Data/Graphics/"))
            .expect("Unable to load Graphics");
        let max_size = sprites
            .iter()
            .fold(Size::EMPTY, |size, sprite| size.join(sprite.size));
        for sprite in sprites.drain(..) {
            lookup.push((sprite.filename, atlas.insert_sprite(sprite.size).unwrap()));
        }

        println!(
            "Filled atlas with {} sprites:\n{}",
            sprites.len(),
            atlas.used_space()
        );

        let texture = Texture2D::new(max_size, gl::RGBA8, gl::LINEAR);

        let mut pixels = Vec::with_capacity(max_size.area()).into_boxed_slice();
        for (path, sprite_index) in lookup.drain(..) {
            if let Some((atlas_index, rect)) = atlas.get_rect(sprite_index) {
                load_sprite_pixels(&path, &mut pixels[..]).expect("Unable to load Graphics");
                texture.update(rect, &pixels, 0, gl::RGBA, gl::UNSIGNED_BYTE);
            }
        }

        Self { atlas }
    }

    pub fn render(&mut self, camera: &Camera) {
        let projection = camera.projection();
    }
}

fn load_sprite_pixels(path: &Path, buffer: &mut [u8]) -> io::Result<()> {
    let decoder = Decoder::new(BufReader::new(File::open(path)?));
    let (info, mut reader) = decoder.read_info()?;

    let size = Size::new(info.width as usize, info.height as usize);
    reader.next_frame(buffer)?;
    Ok(())
}

fn load_sprite_size(path: &Path) -> io::Result<Size> {
    let decoder = Decoder::new(BufReader::new(File::open(path)?));
    let (info, mut reader) = decoder.read_info()?;

    let size = Size::new(info.width as usize, info.height as usize);
    Ok(size)
}

fn load_sprites(path: &Path) -> io::Result<Vec<SpriteData>> {
    let mut result = vec![];
    for file in read_dir(path)? {
        let file = file?;
        if let Some(extension) = file.path().extension() {
            if extension == "png" {
                let path = file.path();
                let sprite = load_sprite_size(&path)?;
                result.push(SpriteData {
                    size: sprite,
                    filename: path,
                });
            }
        }
    }
    Ok(result)
}
