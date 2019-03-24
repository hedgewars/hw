use integral_geometry::{GridIndex, Point, Rect, Size};
use land2d::Land2D;
use vec2d::Vec2D;

use super::{
    camera::Camera,
    gl::{
        Buffer, InputElement, InputFormat, InputLayout, Shader, Texture2D, VariableBinding,
    }
};

// TODO: temp
const VERTEX_SHADER: &'static str = r#"
#version 150

in vec2 Position;
in vec3 Uv;

out vec3 a_Uv;

//uniform Common {
uniform mat4 Projection;
//};

void main()
{
	a_Uv = Uv;
	gl_Position = Projection * vec4(Position, 0.0, 1.0);
}
"#;

const PIXEL_SHADER: &'static str = r#"
#version 150

in vec3 a_Uv;

uniform sampler2D Texture;

out vec4 Target;

void main()
{
	 Target = texture2D(Texture, a_Uv.xy);
}
"#;

pub struct MapTile {
    // either index into GL texture array or emulated [Texture; N]
    texture_index: u32,

    width: u32,
    height: u32,
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct TileVertex {
    pos: [f32; 2],
    // doesn't hurt to include another float, just in case..
    uv: [f32; 3],
}

pub struct DrawTile {
    texture_index: u32,
    index_len: u32,
}

pub struct MapRenderer {
    tiles: Vec<MapTile>,
    textures: Vec<Texture2D>,

    tile_vertex_buffer: Buffer,
    tile_index_buffer: Buffer,
    tile_vertices: Vec<TileVertex>,
    tile_indices: Vec<u16>,
    tile_draw_calls: Vec<DrawTile>,
    index_offset: u16,
    tile_shader: Shader,
    tile_layout: InputLayout,

    tile_size: Size,
    num_tile_x: usize,
}

impl MapRenderer {
    pub fn new(tile_size: Size) -> Self {
        debug_assert!(tile_size.is_power_of_two());

        let tile_shader = Shader::new(
            VERTEX_SHADER,
            Some(PIXEL_SHADER),
            &[
                VariableBinding::Attribute("Position", 0),
                VariableBinding::Attribute("Uv", 1),
                VariableBinding::Sampler("Texture", 0),
            ],
        )
        .unwrap();

        let vertex_size = std::mem::size_of::<TileVertex>() as u32;
        let tile_layout = InputLayout::new(vec![
            // position
            InputElement {
                shader_slot: 0,
                buffer_slot: 0,
                format: InputFormat::Float(gl::FLOAT, false),
                components: 2,
                stride: vertex_size,
                offset: 0,
            },
            // uv
            InputElement {
                shader_slot: 1,
                buffer_slot: 0,
                format: InputFormat::Float(gl::FLOAT, false),
                components: 3,
                stride: vertex_size,
                offset: 8,
            },
        ]);

        MapRenderer {
            tiles: Vec::new(),
            textures: Vec::new(),

            tile_vertex_buffer: Buffer::empty(gl::ARRAY_BUFFER, gl::DYNAMIC_DRAW),
            tile_index_buffer: Buffer::empty(gl::ELEMENT_ARRAY_BUFFER, gl::DYNAMIC_DRAW),
            tile_vertices: Vec::new(),
            tile_indices: Vec::new(),
            index_offset: 0,

            tile_draw_calls: Vec::new(),
            tile_shader,
            tile_layout,

            tile_size,
            num_tile_x: 0,
        }
    }

    pub fn init(&mut self, land: &Vec2D<u32>) {
        // clear tiles, but keep our textures for potential re-use
        self.tiles.clear();

        let tw = self.tile_size.width;
        let th = self.tile_size.height;
        let lw = land.width();
        let lh = land.height();
        let num_tile_x = lw / tw;
        let num_tile_y = lh / th;

        self.num_tile_x = num_tile_x;

        for y in 0..num_tile_y {
            for x in 0..num_tile_x {
                let idx = x + y * num_tile_x;

                let (data, stride) = {
                    let bpp = 4;

                    let offset = x * tw * bpp + y * th * lw * bpp;

                    let data = unsafe { &land.as_bytes()[offset..] };
                    let stride = land.width();

                    (data, stride as u32)
                };

                let texture_index = if idx >= self.textures.len() {
                    let texture = Texture2D::with_data(
                        data,
                        stride,
                        self.tile_size.width as u32,
                        self.tile_size.height as u32,
                        gl::RGBA8,
                        gl::RGBA,
                        gl::UNSIGNED_BYTE,
                        gl::NEAREST,
                    );

                    let texture_index = self.textures.len();
                    self.textures.push(texture);

                    texture_index
                } else {
                    let texture_region = Rect::at_origin(self.tile_size);

                    self.textures[idx].update(
                        texture_region,
                        data,
                        stride,
                        gl::RGBA,
                        gl::UNSIGNED_BYTE,
                    );
                    idx
                };

                let tile = MapTile {
                    texture_index: texture_index as u32,

                    // TODO: are there ever non-power of two textures?
                    width: self.tile_size.width as u32,
                    height: self.tile_size.height as u32,
                };
                self.tiles.push(tile);
            }
        }
    }

    pub fn update(&mut self, land: &Land2D<u32>, region: Rect) {}

    pub fn render(&mut self, camera: &Camera) {
        let viewport = camera.viewport();
        self.tile_vertices.clear();
        self.tile_indices.clear();
        self.tile_draw_calls.clear();
        self.index_offset = 0;

        for (idx, tile) in self.tiles.iter().enumerate() {
            let tile_x = idx % self.num_tile_x;
            let tile_y = idx / self.num_tile_x;
            let tile_w = self.tile_size.width;
            let tile_h = self.tile_size.width;

            let origin = Point::new((tile_x * tile_w) as i32, (tile_y * tile_h) as i32);
            let tile_rect = Rect::from_size(origin, self.tile_size);

            if viewport.intersects(&tile_rect) {
                // lazy
                //dbg!(origin);
                let tile_x = origin.x as f32;
                let tile_y = origin.y as f32;
                let tile_w = tile_x + tile_w as f32;
                let tile_h = tile_y + tile_h as f32;
                let uv_depth = tile.texture_index as f32;

                //dbg!(tile_x);
                let tl = TileVertex {
                    pos: [tile_x, tile_y],
                    uv: [0f32, 0f32, uv_depth],
                };
                let bl = TileVertex {
                    pos: [tile_x, tile_h],
                    uv: [0f32, 1f32, uv_depth],
                };
                let br = TileVertex {
                    pos: [tile_w, tile_h],
                    uv: [1f32, 1f32, uv_depth],
                };
                let tr = TileVertex {
                    pos: [tile_w, tile_y],
                    uv: [1f32, 0f32, uv_depth],
                };

                self.tile_vertices.extend(&[tl, bl, br, tr]);

                let i = self.index_offset;
                self.tile_indices
                    .extend(&[i + 0, i + 1, i + 2, i + 2, i + 3, i + 0]);
                self.index_offset += 4;

                self.tile_draw_calls.push(DrawTile {
                    texture_index: tile.texture_index,
                    index_len: 6,
                });
            }
        }

        self.tile_vertex_buffer.write_typed(&self.tile_vertices);
        self.tile_index_buffer.write_typed(&self.tile_indices);

        let _g = self.tile_layout.bind(
            &[(0, &self.tile_vertex_buffer)],
            Some(&self.tile_index_buffer),
        );

        let projection = camera.projection();

        self.tile_shader.bind();
        self.tile_shader.set_matrix("Projection", projection.as_ptr());

        let mut draw_offset = 0;
        for draw_call in &self.tile_draw_calls {
            unsafe {
                self.tile_shader
                    .bind_texture_2d(0, &self.textures[draw_call.texture_index as usize]);

                gl::DrawElements(
                    gl::TRIANGLES,
                    draw_call.index_len as i32,
                    gl::UNSIGNED_SHORT,
                    draw_offset as *const _,
                );
            }

            draw_offset += draw_call.index_len * 2;
        }
    }
}
