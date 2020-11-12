use crate::render::{
    atlas::{AtlasCollection, SpriteIndex, SpriteLocation},
    camera::Camera,
    gl::{Texture2D, TextureDataType, TextureFilter, TextureFormat, TextureInternalFormat},
};

use integral_geometry::{Rect, Size};

use png::{ColorType, Decoder, DecodingError};

use std::{
    collections::HashMap,
    ffi::OsString,
    fs::{read_dir, File},
    io,
    io::BufReader,
    path::{Path, PathBuf},
};

#[derive(PartialEq, Debug, Clone, Copy)]
pub enum SpriteId {
    Mine = 0,
    Grenade,

    MaxSprite,
}

const SPRITE_LOAD_LIST: &[(SpriteId, &str)] = &[
    (
        SpriteId::Mine,
        "../../share/hedgewars/Data/Graphics/MineOn.png",
    ),
    (
        SpriteId::Grenade,
        "../../share/hedgewars/Data/Graphics/Bomb.png",
    ),
];

const MAX_SPRITES: usize = SpriteId::MaxSprite as usize + 1;

pub struct GearRenderer {
    atlas: AtlasCollection,
    allocation: Box<[SpriteLocation; MAX_SPRITES]>,
}

struct SpriteData {
    size: Size,
    filename: PathBuf,
}

const ATLAS_SIZE: Size = Size::square(2048);

impl GearRenderer {
    pub fn new() -> Self {
        let mut atlas = AtlasCollection::new(ATLAS_SIZE);

        let texture = Texture2D::new(
            ATLAS_SIZE,
            TextureInternalFormat::Rgba8,
            TextureFilter::Linear,
        );

        let mut allocation = Box::new([(0, Rect::at_origin(Size::EMPTY)); MAX_SPRITES]);

        for (sprite, file) in SPRITE_LOAD_LIST {
            let path = Path::new(file);
            let size = load_sprite_size(path).expect(&format!("Unable to open {}", file));
            let index = atlas
                .insert_sprite(size)
                .expect(&format!("Could not store sprite {:?}", sprite));
            let (texture_index, rect) = atlas.get_rect(index).unwrap();

            let mut pixels = vec![0; size.area()].into_boxed_slice();
            load_sprite_pixels(path, mapgen::theme::slice_u32_to_u8_mut(&mut pixels[..]))
                .expect("Unable to load Graphics");

            texture.update(
                rect,
                mapgen::theme::slice_u32_to_u8_mut(&mut pixels[..]),
                None,
                TextureFormat::Rgba,
                TextureDataType::UnsignedByte,
            );

            allocation[*sprite as usize] = (texture_index, rect);
        }

        Self { atlas, allocation }
    }

    pub fn render(&mut self, camera: &Camera) {
        let projection = camera.projection();
    }
}

fn load_sprite_pixels(path: &Path, buffer: &mut [u8]) -> io::Result<Size> {
    let decoder = Decoder::new(BufReader::new(File::open(path)?));
    let (info, mut reader) = decoder.read_info()?;

    let size = Size::new(info.width as usize, info.height as usize);
    reader.next_frame(buffer)?;
    Ok(size)
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
