use crate::render::{
    atlas::{AtlasCollection, SpriteIndex, SpriteLocation},
    camera::Camera,
    gl::{
        Buffer, BufferType, BufferUsage, InputElement, InputFormat, InputLayout, PipelineState,
        Shader, Texture2D, TextureDataType, TextureFilter, TextureFormat, TextureInternalFormat,
        VariableBinding,
    },
};

use integral_geometry::{Rect, Size};

use png::{ColorType, Decoder, DecodingError};

use std::{
    collections::HashMap,
    ffi::OsString,
    fs::{read_dir, File},
    io,
    io::BufReader,
    mem::size_of,
    path::{Path, PathBuf},
};

const VERTEX_SHADER: &'static str = r#"
#version 330 core

uniform mat4 projection;

layout(location = 0) in vec2 position;
layout(location = 1) in vec2 texCoords;

out vec2 varTexCoords;

void main() {
    varTexCoords = texCoords;
	gl_Position = projection * vec4(position, 0.0, 1.0);
}
"#;

const PIXEL_SHADER: &'static str = r#"
#version 330 core

uniform sampler2D texture;

in vec2 varTexCoords;

out vec4 outColor;

void main() {
	 outColor = texture2D(texture, varTexCoords);
}
"#;

#[repr(C)]
#[derive(Copy, Clone)]
struct Vertex {
    position: [f32; 2],
    tex_coords: [f32; 2],
}

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

pub struct GearEntry {
    position: [f32; 2],
    size: Size,
}

impl GearEntry {
    pub fn new(x: f32, y: f32, size: Size) -> Self {
        Self {
            position: [x, y],
            size,
        }
    }
}

pub struct GearRenderer {
    atlas: AtlasCollection,
    texture: Texture2D,
    allocation: Box<[SpriteLocation; MAX_SPRITES]>,
    shader: Shader,
    layout: InputLayout,
    vertex_buffer: Buffer,
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

            let mut pixels = vec![255u8; size.area() * 4].into_boxed_slice();
            load_sprite_pixels(path, &mut pixels).expect("Unable to load Graphics");

            texture.update(
                rect,
                &pixels,
                None,
                TextureFormat::Rgba,
                TextureDataType::UnsignedByte,
            );

            allocation[*sprite as usize] = (texture_index, rect);
        }

        let shader = Shader::new(
            VERTEX_SHADER,
            Some(PIXEL_SHADER),
            &[VariableBinding::Sampler("texture", 0)],
        )
        .unwrap();

        let layout = InputLayout::new(vec![
            InputElement {
                shader_slot: 0,
                buffer_slot: 0,
                format: InputFormat::Float(gl::FLOAT, false),
                components: 2,
                stride: size_of::<Vertex>() as u32,
                offset: 0,
            },
            InputElement {
                shader_slot: 1,
                buffer_slot: 0,
                format: InputFormat::Float(gl::FLOAT, false),
                components: 2,
                stride: size_of::<Vertex>() as u32,
                offset: size_of::<[f32; 2]>() as u32,
            },
        ]);

        let vertex_buffer = Buffer::empty(BufferType::Array, BufferUsage::DynamicDraw);

        Self {
            atlas,
            texture,
            allocation,
            shader,
            layout,
            vertex_buffer,
        }
    }

    pub fn render(&mut self, camera: &Camera, entries: &[GearEntry]) {
        let mut data = Vec::with_capacity(entries.len() * 6);

        for entry in entries {
            let v = [
                Vertex {
                    position: [
                        entry.position[0] - entry.size.width as f32 / 2.0,
                        entry.position[1] + entry.size.height as f32 / 2.0,
                    ],
                    tex_coords: [0.0, 0.015625],
                },
                Vertex {
                    position: [
                        entry.position[0] + entry.size.width as f32 / 2.0,
                        entry.position[1] + entry.size.height as f32 / 2.0,
                    ],
                    tex_coords: [0.015625, 0.015625],
                },
                Vertex {
                    position: [
                        entry.position[0] - entry.size.width as f32 / 2.0,
                        entry.position[1] - entry.size.height as f32 / 2.0,
                    ],
                    tex_coords: [0.0, 0.0],
                },
                Vertex {
                    position: [
                        entry.position[0] + entry.size.width as f32 / 2.0,
                        entry.position[1] - entry.size.height as f32 / 2.0,
                    ],
                    tex_coords: [0.015625, 0.0],
                },
            ];

            data.extend_from_slice(&[v[0], v[1], v[2], v[1], v[3], v[2]]);
        }

        let projection = camera.projection();
        self.shader.bind();
        self.shader.set_matrix("projection", projection.as_ptr());
        self.shader.bind_texture_2d(0, &self.texture);

        self.vertex_buffer.write_typed(&data);
        let _buffer_bind = self.layout.bind(&[(0, &self.vertex_buffer)], None);

        let _state = PipelineState::new().with_blend();

        unsafe {
            gl::DrawArrays(gl::TRIANGLES, 0, entries.len() as i32 * 6);
        }
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
