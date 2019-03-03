use std::io::{ Error, ErrorKind };
use super::PhysFSContext;

pub fn physfs_error_as_io_error() -> Error {
    Error::new(ErrorKind::Other,
               &format!("PhysicsFS Error: `{}`", PhysFSContext::get_last_error())[..])
}
