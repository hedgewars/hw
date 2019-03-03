extern crate physfs;

use physfs::PhysFSContext;

mod directory;

// from project_root
const PATH_TO_HERE: &'static str = "tests/";

//#[test]
fn test_create_physfs_context() {
    let _c = PhysFSContext::new().unwrap();
    assert!(PhysFSContext::is_init());
}

