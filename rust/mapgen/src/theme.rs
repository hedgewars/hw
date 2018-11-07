use std::{
    slice::from_raw_parts_mut,
    io,
    io::BufReader,
    fs::{File, read_dir},
    path::Path
};
use png::{
    BitDepth,
    ColorType,
    Decoder,
    DecodingError
};

use integral_geometry::{
    Rect, Size
};

pub struct ThemeSprite {
    bounds: Size,
    pixels: Vec<u32>
}

pub struct Theme {
    land_texture: Option<ThemeSprite>
}

pub enum ThemeLoadError {
    File(io::Error),
    Decoding(DecodingError),
    Format(String)
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
        Theme {
            land_texture: None
        }
    }

    pub fn load(path: &Path) -> Result<Theme, ThemeLoadError> {
        let mut theme = Self::new();

        for entry in read_dir(path)? {
            let file = entry?;
            if file.file_name() == "LandTex.png" {
                let buffer = BufReader::new(File::create(file.path())?);
                let decoder = Decoder::new(buffer);
                let (info, mut reader) = decoder.read_info()?;

                if info.color_type != ColorType::RGBA {
                    return Err(ThemeLoadError::Format(
                        format!("Unexpected format: {:?}", info.color_type)));
                }
                let size = Size::new(info.width as usize, info.height as usize);

                let mut buffer: Vec<u32> = Vec::with_capacity(size.area());
                let mut slice_u32 = buffer.as_mut_slice();
                let mut slice_u8 = unsafe {
                    from_raw_parts_mut::<u8>(
                        slice_u32.as_mut_ptr() as *mut u8,
                        slice_u32.len() / 4
                    )
                };
                reader.next_frame(slice_u8);

                let land_tex = ThemeSprite {
                    bounds: size,
                    pixels: buffer
                };
                theme.land_texture = Some(land_tex)
            }
        }

        Ok(theme)
    }
}


