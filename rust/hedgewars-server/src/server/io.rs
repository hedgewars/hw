use std::{
    fs::{File, OpenOptions},
    io::{Error, ErrorKind, Read, Result, Write},
};

pub trait HWServerIO {
    fn write_file(&mut self, name: &str, content: &str) -> Result<()>;
    fn read_file(&mut self, name: &str) -> Result<String>;
}

pub struct EmptyServerIO {}

impl EmptyServerIO {
    pub fn new() -> Self {
        Self {}
    }
}

impl HWServerIO for EmptyServerIO {
    fn write_file(&mut self, _name: &str, _content: &str) -> Result<()> {
        Ok(())
    }

    fn read_file(&mut self, _name: &str) -> Result<String> {
        Ok("".to_string())
    }
}

pub struct FileServerIO {}

impl FileServerIO {
    pub fn new() -> Self {
        Self {}
    }
}

impl HWServerIO for FileServerIO {
    fn write_file(&mut self, name: &str, content: &str) -> Result<()> {
        let mut writer = OpenOptions::new().create(true).write(true).open(name)?;
        writer.write_all(content.as_bytes())
    }

    fn read_file(&mut self, name: &str) -> Result<String> {
        let mut reader = File::open(name)?;
        let mut result = String::new();
        reader.read_to_string(&mut result)?;
        Ok(result)
    }
}
