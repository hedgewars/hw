//! PhysFS bindings for Rust

#![deny(missing_docs)]

extern crate libc;

pub use physfs::file::*;
pub use physfs::*;

/// PhysFS bindings
mod physfs;
/// Definitions for the PhysFS primitives
mod primitives;
