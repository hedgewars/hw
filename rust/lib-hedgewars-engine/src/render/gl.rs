
use integral_geometry::Rect;

use std::{ffi, ffi::CString, mem, ptr, slice};

#[derive(Debug)]
pub struct Texture2D {
    pub handle: u32,
}

impl Drop for Texture2D {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe {
                gl::DeleteTextures(1, &self.handle);
            }
        }
    }
}

impl Texture2D {
    pub fn with_data(
        data: &[u8],
        data_stride: u32,
        width: u32,
        height: u32,
        internal_format: u32,
        format: u32,
        ty: u32,
        filter: u32,
    ) -> Self {
        let mut handle = 0;

        unsafe {
            gl::GenTextures(1, &mut handle);

            gl::BindTexture(gl::TEXTURE_2D, handle);
            gl::PixelStorei(gl::UNPACK_ROW_LENGTH, data_stride as i32);
            gl::TexImage2D(
                gl::TEXTURE_2D,
                0,
                internal_format as i32,
                width as i32,
                height as i32,
                0,
                format as u32,
                ty,
                data.as_ptr() as *const _,
            );

            gl::TexParameteri(gl::TEXTURE_2D, gl::TEXTURE_WRAP_S, gl::CLAMP_TO_EDGE as i32);
            gl::TexParameteri(gl::TEXTURE_2D, gl::TEXTURE_WRAP_T, gl::CLAMP_TO_EDGE as i32);
            gl::TexParameteri(gl::TEXTURE_2D, gl::TEXTURE_MIN_FILTER, filter as i32);
            gl::TexParameteri(gl::TEXTURE_2D, gl::TEXTURE_MAG_FILTER, filter as i32);
        }

        Texture2D { handle }
    }

    pub fn update(&self, region: Rect, data: &[u8], data_stride: u32, format: u32, ty: u32) {
        unsafe {
            gl::BindTexture(gl::TEXTURE_2D, self.handle);
            gl::PixelStorei(gl::UNPACK_ROW_LENGTH, data_stride as i32);
            gl::TexSubImage2D(
                gl::TEXTURE_2D,
                0,             // texture level
                region.left(), // texture region
                region.top(),
                region.width() as i32 - 1,
                region.height() as i32 - 1,
                format,                    // data format
                ty,                        // data type
                data.as_ptr() as *const _, // data ptr
            );
        }
    }
}

#[derive(Debug)]
pub struct Buffer {
    pub handle: u32,
    pub ty: u32,
    pub usage: u32,
}

impl Buffer {
    pub fn empty(
        ty: u32,
        usage: u32,
        //size: isize
    ) -> Buffer {
        let mut buffer = 0;

        unsafe {
            gl::GenBuffers(1, &mut buffer);
            gl::BindBuffer(ty, buffer);
            //gl::BufferData(ty, size, ptr::null_mut(), usage);
        }

        Buffer {
            handle: buffer,
            ty,
            usage,
        }
    }

    fn with_data(ty: u32, usage: u32, data: &[u8]) -> Buffer {
        let mut buffer = 0;

        unsafe {
            gl::GenBuffers(1, &mut buffer);
            gl::BindBuffer(ty, buffer);
            gl::BufferData(ty, data.len() as isize, data.as_ptr() as _, usage);
        }

        Buffer {
            handle: buffer,
            ty,
            usage,
        }
    }

    pub fn ty(&self) -> u32 {
        self.ty
    }

    pub fn handle(&self) -> u32 {
        self.handle
    }

    pub fn write_typed<T>(&self, data: &[T]) {
        unsafe {
            let data =
                slice::from_raw_parts(data.as_ptr() as *const u8, data.len() * mem::size_of::<T>());

            gl::BindBuffer(self.ty, self.handle);
            gl::BufferData(
                self.ty,
                data.len() as isize,
                data.as_ptr() as *const _ as *const _,
                self.usage,
            );
        }
    }

    pub fn write(&self, data: &[u8]) {
        unsafe {
            gl::BindBuffer(self.ty, self.handle);
            gl::BufferData(
                self.ty,
                data.len() as isize,
                data.as_ptr() as *const _ as *const _,
                self.usage,
            );
        }
    }
}

impl Drop for Buffer {
    fn drop(&mut self) {
        unsafe {
            gl::DeleteBuffers(1, &self.handle);
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
        unsafe fn compile_shader(ty: u32, shdr: &str) -> Result<u32, String> {
            let shader = gl::CreateShader(ty);
            let len = shdr.len() as i32;
            let shdr = shdr.as_ptr() as *const i8;
            gl::ShaderSource(shader, 1, &shdr, &len);
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

        unsafe {
            gl::ActiveTexture(gl::TEXTURE0 + index);
            gl::BindTexture(gl::TEXTURE_2D, texture.handle);
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
            unsafe {
                gl::BindBuffer(buffer.ty(), buffer.handle());
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
            unsafe {
                gl::BindBuffer(gl::ELEMENT_ARRAY_BUFFER, buf.handle());
            }
        }

        LayoutGuard { vao }
    }
}
