use std::ffi::CString;
use std::io::{ Read, Write, Seek, SeekFrom, Result };
use std::mem;
use libc::{ c_int, c_char, c_void };
use primitives::*;
use super::{ PhysFSContext };
use super::util::physfs_error_as_io_error;

#[link(name = "physfs")]
extern {
    // valid filehandle on success, NULL on failure
    fn PHYSFS_openAppend(filename: *const c_char) -> *const RawFile;
    fn PHYSFS_openRead(filename: *const c_char) -> *const RawFile;
    fn PHYSFS_openWrite(filename: *const c_char) -> *const RawFile;

    // nonzero on success, 0 on failure (and the handle stays open)
    // The docs make it sound like failure is rare.
    fn PHYSFS_close(file: *const RawFile) -> c_int;

    // Number of bytes read on success, -1 on failure.
    fn PHYSFS_read(file: *const RawFile, buffer: *mut c_void,
                   obj_size: PHYSFS_uint32, obj_count: PHYSFS_uint32) -> PHYSFS_sint64;

    // Number of bytes written on success, -1 on failure.
    fn PHYSFS_write(file: *const RawFile, buffer: *const c_void,
                    obj_size: PHYSFS_uint32, obj_count: PHYSFS_uint32) -> PHYSFS_sint64;

    // Flush buffered file; no-op for unbuffered files.
    fn PHYSFS_flush(file: *const RawFile) -> c_int;

    // Seek to position in file; nonzero on succss, zero on error.
    fn PHYSFS_seek(file: *const RawFile, pos: PHYSFS_uint64) -> c_int;

    // Current position in file, -1 on failure.
    fn PHYSFS_tell(file: *const RawFile) -> PHYSFS_sint64;

    // nonzero if EOF, zero if not.
    fn PHYSFS_eof(file: *const RawFile) -> c_int;

    // Determine file size; returns -1 if impossible
    fn PHYSFS_fileLength(file: *const RawFile) -> PHYSFS_sint64;
}

/// Possible ways to open a file.
#[derive(Copy, Clone)]
pub enum Mode {
    /// Append to the end of the file.
    Append,
    /// Read from the file.
    Read,
    /// Write to the file, overwriting previous data.
    Write,
}

/// A wrapper for the PHYSFS_File type.
#[repr(C)]
struct RawFile {
    opaque: *const c_void,
}

/// A file handle.
#[allow(dead_code)]
pub struct File<'f> {
    raw: *const RawFile,
    mode: Mode,
    context: &'f PhysFSContext,
}

impl<'f> File<'f> {
    /// Opens a file with a specific mode.
    pub fn open<'g>(context: &'g PhysFSContext, filename: String, mode: Mode) -> Result<File<'g>> {
        let c_filename = try!(CString::new(filename));
        let raw = unsafe { match mode {
            Mode::Append => PHYSFS_openAppend(c_filename.as_ptr()),
            Mode::Read => PHYSFS_openRead(c_filename.as_ptr()),
            Mode::Write => PHYSFS_openWrite(c_filename.as_ptr())
        }};

        if raw.is_null() {
            Err(physfs_error_as_io_error())
        }
        else {
            Ok(File{raw: raw, mode: mode, context: context})
        }
    }

    /// Closes a file handle.
    fn close(&self) -> Result<()> {
        match unsafe {
            PHYSFS_close(self.raw)
        } {
            0 => Err(physfs_error_as_io_error()),
            _ => Ok(())
        }
    }

    /// Checks whether eof is reached or not.
    pub fn eof(&self) -> bool {
        let ret = unsafe {
            PHYSFS_eof(self.raw)
        };

        ret != 0
    }

    /// Determine length of file, if possible
    pub fn len(&self) -> Result<u64> {
        let len = unsafe { PHYSFS_fileLength(self.raw) };

        if len >= 0 {
            Ok(len as u64)
        } else {
            Err(physfs_error_as_io_error())
        }
    }

    /// Determines current position within a file
    pub fn tell(&self) -> Result<u64> {
        let ret = unsafe {
            PHYSFS_tell(self.raw)
        };

        match ret {
            -1 => Err(physfs_error_as_io_error()),
            _ => Ok(ret as u64)
        }
    }
}

impl<'f> Read for File<'f> {
    /// Reads from a file
    fn read(&mut self, buf: &mut [u8]) -> Result<usize> {
        let ret = unsafe {
            PHYSFS_read(
                self.raw,
                buf.as_ptr() as *mut c_void,
                mem::size_of::<u8>() as PHYSFS_uint32,
                buf.len() as PHYSFS_uint32
            )
        };

        match ret {
            -1 => Err(physfs_error_as_io_error()),
            _ => Ok(ret as usize)
        }
    }
}

impl<'f> Write for File<'f> {
    /// Writes to a file.
    /// This code performs no safety checks to ensure
    /// that the buffer is the correct length.
    fn write(&mut self, buf: &[u8]) -> Result<usize> {
        let ret = unsafe {
            PHYSFS_write(
                self.raw,
                buf.as_ptr() as *const c_void,
                mem::size_of::<u8>() as PHYSFS_uint32,
                buf.len() as PHYSFS_uint32
            )
        };

        match ret {
            -1 => Err(physfs_error_as_io_error()),
            _ => Ok(ret as usize)
        }
    }

    /// Flushes a file if buffered; no-op if unbuffered.
    fn flush(&mut self) -> Result<()> {
        let ret = unsafe {
            PHYSFS_flush(self.raw)
        };

        match ret {
            0 => Err(physfs_error_as_io_error()),
            _ => Ok(())
        }
    }
}

impl<'f> Seek for File<'f> {
    /// Seek to a new position within a file
    fn seek(&mut self, pos: SeekFrom) -> Result<u64> {
        let seek_pos = match pos {
            SeekFrom::Start(n) => n as i64,
            SeekFrom::End(n) => {
                let len = try!(self.len());
                n + len as i64
            }
            SeekFrom::Current(n) => {
                let curr_pos = try!(self.tell());
                n + curr_pos as i64
            }
        };

        let result = unsafe {
            PHYSFS_seek(
                self.raw,
                seek_pos as PHYSFS_uint64
            )
        };

        if result == -1 {
            return Err(physfs_error_as_io_error());
        }

        self.tell()
    }
}

impl<'f> Drop for File<'f> {
    fn drop(&mut self) {
        let _ = self.close();
    }
}
