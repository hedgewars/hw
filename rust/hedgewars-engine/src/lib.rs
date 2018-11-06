#[repr(C)]
pub struct Preview {
    width: u32,
    height: u32,
    hedgehogs_number: u8,
    land: *const u8,
}


#[no_mangle]
pub extern "C" fn protocol_version() -> u32 {
    56
}

#[no_mangle]
pub extern "C" fn generate_preview () -> Preview  {
    unimplemented!()
}
