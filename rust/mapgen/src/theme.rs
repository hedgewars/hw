use integral_geometry::{Point, Rect};
use png::{ColorType, Decoder, DecodingError};
use std::{
    fs::{read_dir, File},
    io,
    io::BufReader,
    path::Path,
    slice::{from_raw_parts, from_raw_parts_mut},
};
use std::slice::ChunksExact;
use integral_geometry::Size;
use vec2d::Vec2D;

pub struct ThemeSprite {
    pixels: Vec2D<u32>,
}

impl ThemeSprite {
    #[inline]
    pub fn size(&self) -> Size {
        self.pixels.size()
    }

    #[inline]
    pub fn width(&self) -> u32 {
        self.size().width
    }

    #[inline]
    pub fn height(&self) -> u32 {
        self.size().height
    }

    #[inline]
    pub fn rows(&self) -> ChunksExact<u32> {
        self.pixels.rows()
    }

    #[inline]
    pub fn get_row(&self, index: usize) -> &[u32] {
        &self.pixels[index]
    }

    #[inline]
    pub fn get_pixel(&self, x: usize, y: usize) -> u32 {
        self.pixels[y][x]
    }

    pub fn to_transposed(&self) -> ThemeSprite {
        let size = self.size().transpose();
        let mut pixels = Vec2D::new(&size, 0u32);
        for (y, row) in self.pixels.rows().enumerate() {
            for (x, v) in row.iter().enumerate() {
                pixels[x][y] = *v;
            }
        }
        ThemeSprite { pixels }
    }

    pub fn to_tiled(&self) -> TiledSprite {
        let size = self.size();
        assert!(size.is_power_of_two());
        let tile_width_shift = size.width.trailing_zeros() as usize + 2;
        let mut pixels = vec![0u32; size.area() as usize];

        for (y, row) in self.pixels.rows().enumerate() {
            for (x, v) in row.iter().enumerate() {
                pixels[get_tiled_index(x, y, tile_width_shift)] = *v;
            }
        }

        TiledSprite {
            tile_width_shift,
            size,
            pixels,
        }
    }
}

#[inline]
fn get_tiled_index(x: usize, y: usize, tile_width_shift: usize) -> usize {
    (((y >> 2) << tile_width_shift) + ((x >> 2) << 4)) + ((y & 0b11) << 2) + (x & 0b11)
}

pub struct TiledSprite {
    tile_width_shift: usize,
    size: Size,
    pixels: Vec<u32>,
}

impl TiledSprite {
    #[inline]
    pub fn size(&self) -> Size {
        self.size
    }

    #[inline]
    pub fn width(&self) -> u32 {
        self.size().width
    }

    #[inline]
    pub fn height(&self) -> u32 {
        self.size().height
    }

    #[inline]
    pub fn get_pixel(&self, x: usize, y: usize) -> u32 {
        self.pixels[get_tiled_index(x, y, self.tile_width_shift)]
    }
}

#[derive(Default)]
struct Color(u8, u8, u8, u8);

pub struct LandObjectOverlay {
    texture: ThemeSprite,
    offset: Point,
}

pub struct LandObject {
    texture: ThemeSprite,
    inland_rects: Vec<Rect>,
    outland_rects: Vec<Rect>,
    anchors: Vec<Rect>,
    overlays: Vec<LandObjectOverlay>,
}

pub struct LandSpray {
    texture: ThemeSprite,
    count: u16,
}

#[derive(Default)]
pub struct ThemeColors {
    border: Color,
}

pub struct Flakes {
    texture: ThemeSprite,
    frames_count: u16,
    frame_ticks: u16,
    velocity: u16,
    fall_speed: u16,
}

#[derive(Default)]
pub struct Water {
    top_color: Color,
    bottom_color: Color,
    opacity: u8,
}

#[derive(Default)]
pub struct ThemeParts {
    water: Water,
    flakes: Option<Flakes>,
    music: String,
    sky: Color,
    tint: Color,
}

#[derive(Default)]
pub struct Theme {
    border_color: Color,
    clouds_count: u16,
    flatten_flakes: bool,
    land_texture: Option<ThemeSprite>,
    border_texture: Option<ThemeSprite>,
    land_objects: Vec<LandObject>,
    spays: Vec<LandSpray>,
    use_ice: bool,
    use_snow: bool,
    music: String,
    normal_parts: ThemeParts,
    sd_parts: ThemeParts,
}

impl Theme {
    pub fn land_texture(&self) -> Option<&ThemeSprite> {
        self.land_texture.as_ref()
    }

    pub fn border_texture(&self) -> Option<&ThemeSprite> {
        self.border_texture.as_ref()
    }
}

#[derive(Debug)]
pub enum ThemeLoadError {
    File(io::Error),
    Decoding(DecodingError),
    Format(String),
}

impl From<io::Error> for ThemeLoadError {
    fn from(e: io::Error) -> Self {
        ThemeLoadError::File(e)
    }
}

impl From<DecodingError> for ThemeLoadError {
    fn from(e: DecodingError) -> Self {
        ThemeLoadError::Decoding(e)
    }
}

impl Theme {
    pub fn new() -> Self {
        Default::default()
    }

    pub fn load(path: &Path) -> Result<Theme, ThemeLoadError> {
        let mut theme = Self::new();

        for entry in read_dir(path)? {
            let file = entry?;
            if file.file_name() == "LandTex.png" {
                theme.land_texture = Some(load_sprite(&file.path())?)
            } else if file.file_name() == "Border.png" {
                theme.border_texture = Some(load_sprite(&file.path())?)
            }
        }

        Ok(theme)
    }
}

fn load_sprite(path: &Path) -> Result<ThemeSprite, ThemeLoadError> {
    let decoder = Decoder::new(BufReader::new(File::open(path)?));
    let mut reader = decoder.read_info()?;
    let info = reader.info();

    if info.color_type != ColorType::Rgba {
        return Err(ThemeLoadError::Format(format!(
            "Unexpected format: {:?}",
            info.color_type
        )));
    }
    let size = Size::new(info.width, info.height);

    let mut pixels: Vec2D<u32> = Vec2D::new(&size, 0);
    reader.next_frame(slice_u32_to_u8_mut(pixels.as_mut_slice()))?;

    Ok(ThemeSprite { pixels })
}

pub fn slice_u32_to_u8(slice_u32: &[u32]) -> &[u8] {
    unsafe { from_raw_parts::<u8>(slice_u32.as_ptr() as *const u8, slice_u32.len() * 4) }
}

pub fn slice_u32_to_u8_mut(slice_u32: &mut [u32]) -> &mut [u8] {
    unsafe { from_raw_parts_mut::<u8>(slice_u32.as_mut_ptr() as *mut u8, slice_u32.len() * 4) }
}
