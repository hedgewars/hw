use integral_geometry::{Rect, Size};

use std::{ffi, ffi::CString, mem, num::NonZeroU32, ptr, slice};

#[derive(Default)]
pub struct PipelineState {
    blending: bool,
}

impl PipelineState {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_blend(mut self) -> Self {
        unsafe {
            gl::Enable(gl::BLEND);
            gl::BlendFunc(gl::SRC_ALPHA, gl::ONE_MINUS_SRC_ALPHA);
        }
        self.blending = true;
        self
    }
}

impl Drop for PipelineState {
    fn drop(&mut self) {
        if self.blending {
            unsafe { gl::Disable(gl::BLEND) }
        }
    }
}

#[derive(Debug)]
pub struct Texture2D {
    handle: Option<NonZeroU32>,
    size: Size,
}

impl Drop for Texture2D {
    fn drop(&mut self) {
        if let Some(handle) = self.handle {
            unsafe {
                gl::DeleteTextures(1, &handle.get());
            }
        }
    }
}

fn new_texture() -> Option<NonZeroU32> {
    let mut handle = 0;
    unsafe {
        gl::GenTextures(1, &mut handle);
    }
    NonZeroU32::new(handle)
}

fn tex_params(filter: TextureFilter) {
    unsafe {
        gl::TexParameteri(gl::TEXTURE_2D, gl::TEXTURE_WRAP_S, gl::CLAMP_TO_EDGE as i32);
        gl::TexParameteri(gl::TEXTURE_2D, gl::TEXTURE_WRAP_T, gl::CLAMP_TO_EDGE as i32);
        gl::TexParameteri(gl::TEXTURE_2D, gl::TEXTURE_MIN_FILTER, filter as i32);
        gl::TexParameteri(gl::TEXTURE_2D, gl::TEXTURE_MAG_FILTER, filter as i32);
    }
}

#[derive(Clone, Copy, Debug)]
pub enum TextureFormat {
    Rgba = gl::RGBA as isize,
}

#[derive(Clone, Copy, Debug)]
pub enum TextureInternalFormat {
    Rgba8 = gl::RGBA as isize,
}

#[derive(Clone, Copy, Debug)]
pub enum TextureDataType {
    UnsignedByte = gl::UNSIGNED_BYTE as isize,
}

#[derive(Clone, Copy, Debug)]
pub enum TextureFilter {
    Nearest = gl::NEAREST as isize,
    Linear = gl::LINEAR as isize,
}

#[inline]
fn get_u32(value: Option<NonZeroU32>) -> u32 {
    value.map_or(0, |v| v.get())
}

fn is_out_of_bounds(data: &[u8], data_stride: Option<NonZeroU32>, texture_size: Size) -> bool {
    let data_stride = get_u32(data_stride);
    data_stride == 0 && texture_size.area() * 4 > data.len()
        || data_stride != 0
            && texture_size.width > data_stride as usize
            && (texture_size.height * data_stride as usize) * 4 > data.len()
}

impl Texture2D {
    pub fn new(size: Size, internal_format: TextureInternalFormat, filter: TextureFilter) -> Self {
        if let Some(handle) = new_texture() {
            unsafe {
                gl::BindTexture(gl::TEXTURE_2D, handle.get());
                gl::TexImage2D(
                    gl::TEXTURE_2D,
                    0,
                    internal_format as i32,
                    size.width as i32,
                    size.height as i32,
                    0,
                    TextureFormat::Rgba as u32,
                    TextureDataType::UnsignedByte as u32,
                    std::ptr::null(),
                )
            }

            tex_params(filter);
            Self {
                handle: Some(handle),
                size,
            }
        } else {
            Self { handle: None, size }
        }
    }

    pub fn with_data(
        data: &[u8],
        data_stride: Option<NonZeroU32>,
        size: Size,
        internal_format: TextureInternalFormat,
        format: TextureFormat,
        data_type: TextureDataType,
        filter: TextureFilter,
    ) -> Self {
        if is_out_of_bounds(data, data_stride, size) {
            return Self { handle: None, size };
        }

        if let Some(handle) = new_texture() {
            unsafe {
                gl::BindTexture(gl::TEXTURE_2D, handle.get());
                gl::PixelStorei(gl::UNPACK_ROW_LENGTH, get_u32(data_stride) as i32);
                gl::TexImage2D(
                    gl::TEXTURE_2D,
                    0,
                    internal_format as i32,
                    size.width as i32,
                    size.height as i32,
                    0,
                    format as u32,
                    data_type as u32,
                    data.as_ptr() as *const _,
                )
            }

            tex_params(filter);
            Self {
                handle: Some(handle),
                size,
            }
        } else {
            Self { handle: None, size }
        }
    }

    pub fn update(
        &self,
        region: Rect,
        data: &[u8],
        data_stride: Option<NonZeroU32>,
        format: TextureFormat,
        data_type: TextureDataType,
    ) {
        if is_out_of_bounds(data, data_stride, self.size) {
            return;
        }

        if let Some(handle) = self.handle {
            unsafe {
                gl::BindTexture(gl::TEXTURE_2D, handle.get());
                gl::PixelStorei(gl::UNPACK_ROW_LENGTH, get_u32(data_stride) as i32);
                gl::TexSubImage2D(
                    gl::TEXTURE_2D,
                    0,
                    region.left(),
                    region.top(),
                    region.width() as i32,
                    region.height() as i32,
                    format as u32,
                    data_type as u32,
                    data.as_ptr() as *const _,
                );
            }
        }
    }

    pub fn retrieve(&self, data: &mut [u8]) {
        if self.size.area() * 4 > data.len() {
            return;
        }

        if let Some(handle) = self.handle {
            unsafe {
                gl::BindTexture(gl::TEXTURE_2D, handle.get());
                gl::GetTexImage(
                    gl::TEXTURE_2D,
                    0,
                    TextureFormat::Rgba as u32,
                    TextureDataType::UnsignedByte as u32,
                    data.as_mut_ptr() as *mut _,
                );
            }
        }
    }
}

#[derive(Clone, Copy, Debug)]
#[repr(u32)]
pub enum BufferType {
    Array = gl::ARRAY_BUFFER,
    ElementArray = gl::ELEMENT_ARRAY_BUFFER,
}

#[derive(Clone, Copy, Debug)]
#[repr(u32)]
pub enum BufferUsage {
    DynamicDraw = gl::DYNAMIC_DRAW,
}

#[derive(Debug)]
pub struct Buffer {
    pub handle: Option<NonZeroU32>,
    pub buffer_type: BufferType,
    pub usage: BufferUsage,
}

impl Buffer {
    pub fn empty(buffer_type: BufferType, usage: BufferUsage) -> Buffer {
        let mut buffer = 0;

        unsafe {
            gl::GenBuffers(1, &mut buffer);
        }

        Buffer {
            handle: NonZeroU32::new(buffer),
            buffer_type: buffer_type,
            usage,
        }
    }

    fn with_data(buffer_type: BufferType, usage: BufferUsage, data: &[u8]) -> Buffer {
        let mut buffer = 0;

        unsafe {
            gl::GenBuffers(1, &mut buffer);
            if buffer != 0 {
                gl::BindBuffer(buffer_type as u32, buffer);
                gl::BufferData(
                    buffer_type as u32,
                    data.len() as isize,
                    data.as_ptr() as _,
                    usage as u32,
                );
            }
        }

        Buffer {
            handle: NonZeroU32::new(buffer),
            buffer_type,
            usage,
        }
    }

    pub fn ty(&self) -> BufferType {
        self.buffer_type
    }

    pub fn handle(&self) -> Option<NonZeroU32> {
        self.handle
    }

    pub fn write_typed<T>(&self, data: &[T]) {
        if let Some(handle) = self.handle {
            unsafe {
                gl::BindBuffer(self.buffer_type as u32, handle.get());
                gl::BufferData(
                    self.buffer_type as u32,
                    (data.len() * mem::size_of::<T>()) as isize,
                    data.as_ptr() as *const _,
                    self.usage as u32,
                );
            }
        }
    }

    pub fn write(&self, data: &[u8]) {
        if let Some(handle) = self.handle {
            unsafe {
                gl::BindBuffer(self.buffer_type as u32, handle.get());
                gl::BufferData(
                    self.buffer_type as u32,
                    data.len() as isize,
                    data.as_ptr() as *const _,
                    self.usage as u32,
                );
            }
        }
    }
}

impl Drop for Buffer {
    fn drop(&mut self) {
        if let Some(handle) = self.handle {
            let handle = handle.get();
            unsafe {
                gl::DeleteBuffers(1, &handle);
            }
        }
    }
}

#[derive(Debug)]
pub enum VariableBinding<'a> {
    Attribute(&'a str, u32),
    Uniform(&'a str, u32),
    UniformBlock(&'a str, u32),
    Sampler(&'a str, u32),
}

#[derive(Debug)]
pub struct Shader {
    pub program: u32,
}

impl Drop for Shader {
    fn drop(&mut self) {
        unsafe {
            gl::DeleteProgram(self.program);
        }
    }
}

impl Shader {
    pub fn new<'a>(
        vs: &str,
        ps: Option<&str>,
        bindings: &[VariableBinding<'a>],
    ) -> Result<Self, String> {
        unsafe fn compile_shader(shader_type: u32, shader_code: &str) -> Result<u32, String> {
            let shader = gl::CreateShader(shader_type);
            let len = shader_code.len() as i32;
            let code_strings = shader_code.as_ptr() as *const i8;
            gl::ShaderSource(shader, 1, &code_strings, &len);
            gl::CompileShader(shader);

            let mut success = 0i32;
            gl::GetShaderiv(shader, gl::COMPILE_STATUS, &mut success as _);

            if success == gl::FALSE as i32 {
                let mut log_size = 0i32;
                gl::GetShaderiv(shader, gl::INFO_LOG_LENGTH, &mut log_size as _);

                let mut log = vec![0u8; log_size as usize];
                gl::GetShaderInfoLog(shader, log_size, ptr::null_mut(), log.as_mut_ptr() as _);

                gl::DeleteShader(shader);
                Err(String::from_utf8_unchecked(log))
            } else {
                Ok(shader)
            }
        }

        let vs = unsafe { compile_shader(gl::VERTEX_SHADER, vs)? };
        let ps = if let Some(ps) = ps {
            Some(unsafe { compile_shader(gl::FRAGMENT_SHADER, ps)? })
        } else {
            None
        };

        unsafe {
            let program = gl::CreateProgram();

            gl::AttachShader(program, vs);
            if let Some(ps) = ps {
                gl::AttachShader(program, ps);
            }

            for bind in bindings {
                match bind {
                    &VariableBinding::Attribute(ref name, id) => {
                        let c_str = CString::new(name.as_bytes()).unwrap();
                        gl::BindAttribLocation(
                            program,
                            id,
                            c_str.to_bytes_with_nul().as_ptr() as *const _,
                        );
                    }
                    _ => {}
                }
            }

            gl::LinkProgram(program);

            let mut success = 0i32;
            gl::GetProgramiv(program, gl::LINK_STATUS, &mut success);
            if success == gl::FALSE as i32 {
                let mut log_size = 0i32;
                gl::GetProgramiv(program, gl::INFO_LOG_LENGTH, &mut log_size as _);

                let mut log = vec![0u8; log_size as usize];
                gl::GetProgramInfoLog(program, log_size, ptr::null_mut(), log.as_mut_ptr() as _);

                gl::DeleteProgram(program);
                return Err(String::from_utf8_unchecked(log));
            }

            //gl::DetachShader(program, vs);
            if let Some(ps) = ps {
                //gl::DetachShader(program, ps);
            }

            gl::UseProgram(program);

            // after linking we setup sampler bindings as specified in the shader
            for bind in bindings {
                match bind {
                    VariableBinding::Uniform(name, id) => {
                        let c_str = CString::new(name.as_bytes()).unwrap();
                        let index = gl::GetUniformLocation(
                            program,
                            c_str.to_bytes_with_nul().as_ptr() as *const _,
                        );

                        // TODO: impl for block?
                    }
                    VariableBinding::UniformBlock(name, id) => {
                        let c_str = CString::new(name.as_bytes()).unwrap();
                        let index = gl::GetUniformBlockIndex(
                            program,
                            c_str.to_bytes_with_nul().as_ptr() as *const _,
                        );

                        gl::UniformBlockBinding(program, index, *id);
                    }
                    VariableBinding::Sampler(name, id) => {
                        let c_str = CString::new(name.as_bytes()).unwrap();
                        let index = gl::GetUniformLocation(
                            program,
                            c_str.to_bytes_with_nul().as_ptr() as *const _,
                        );

                        gl::Uniform1i(index, *id as i32);
                    }
                    _ => {}
                }
            }

            Ok(Shader { program })
        }
    }

    pub fn bind(&self) {
        unsafe {
            gl::UseProgram(self.program);
        }
    }

    pub fn set_matrix(&self, name: &str, matrix: *const f32) {
        unsafe {
            let c_str = CString::new(name).unwrap();
            let index = gl::GetUniformLocation(
                self.program,
                c_str.to_bytes_with_nul().as_ptr() as *const _,
            );

            gl::UniformMatrix4fv(index, 1, gl::FALSE, matrix);
        }
    }

    pub fn bind_texture_2d(&self, index: u32, texture: &Texture2D) {
        self.bind();

        if let Some(handle) = texture.handle {
            unsafe {
                gl::ActiveTexture(gl::TEXTURE0 + index);
                gl::BindTexture(gl::TEXTURE_2D, handle.get());
            }
        }
    }
}

pub enum InputFormat {
    Float(u32, bool),
    Integer(u32),
}

pub struct InputElement {
    pub shader_slot: u32,
    pub buffer_slot: u32,
    pub format: InputFormat,
    pub components: u32,
    pub stride: u32,
    pub offset: u32,
}

// TODO:
pub struct InputLayout {
    pub elements: Vec<InputElement>,
}

pub struct LayoutGuard {
    vao: u32,
}

impl Drop for LayoutGuard {
    fn drop(&mut self) {
        unsafe {
            gl::DeleteVertexArrays(1, [self.vao].as_ptr());
            gl::BindVertexArray(0);
        }
    }
}

impl InputLayout {
    pub fn new(elements: Vec<InputElement>) -> Self {
        InputLayout { elements }
    }

    pub fn bind(
        &mut self,
        buffers: &[(u32, &Buffer)],
        index_buffer: Option<&Buffer>,
    ) -> LayoutGuard {
        let mut vao = 0;

        unsafe {
            gl::GenVertexArrays(1, &mut vao);
            gl::BindVertexArray(vao);
        }

        for &(slot, ref buffer) in buffers {
            if let Some(handle) = buffer.handle() {
                unsafe {
                    gl::BindBuffer(buffer.ty() as u32, handle.get());
                }
            }

            for attr in self.elements.iter().filter(|a| a.buffer_slot == slot) {
                unsafe {
                    gl::EnableVertexAttribArray(attr.shader_slot);
                    match attr.format {
                        InputFormat::Float(fmt, normalized) => {
                            gl::VertexAttribPointer(
                                attr.shader_slot,
                                attr.components as i32,
                                fmt,
                                if normalized { gl::TRUE } else { gl::FALSE },
                                attr.stride as i32,
                                attr.offset as *const _,
                            );
                        }
                        InputFormat::Integer(fmt) => {
                            gl::VertexAttribIPointer(
                                attr.shader_slot,
                                attr.components as i32,
                                fmt,
                                attr.stride as i32,
                                attr.offset as *const _,
                            );
                        }
                    }
                }
            }
        }

        if let Some(buf) = index_buffer {
            if let Some(handle) = buf.handle() {
                unsafe {
                    gl::BindBuffer(gl::ELEMENT_ARRAY_BUFFER, handle.get());
                }
            }
        }

        LayoutGuard { vao }
    }
}
