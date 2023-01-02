use integral_geometry::{Point, Size};
use land2d;

#[repr(C)]
pub struct GameField {
    collision: land2d::Land2D<u16>,
    pixels: land2d::Land2D<u32>,
}

#[no_mangle]
pub extern "C" fn create_game_field(width: u32, height: u32) -> *mut GameField {
    let game_field = Box::new(GameField {
        collision: land2d::Land2D::new(Size::new(width as usize, height as usize), 0),
        pixels: land2d::Land2D::new(Size::new(width as usize, height as usize), 0),
    });

    Box::leak(game_field)
}

#[no_mangle]
pub extern "C" fn land_get(game_field: &mut GameField, x: i32, y: i32) -> u16 {
    game_field.collision.map(y, x, |p| *p)
}

#[no_mangle]
pub extern "C" fn land_fill(
    game_field: &mut GameField,
    x: i32,
    y: i32,
    border_value: u16,
    fill_value: u16,
) {
    game_field
        .collision
        .fill(Point::new(x, y), border_value, fill_value)
}

#[no_mangle]
pub extern "C" fn land_set(game_field: &mut GameField, x: i32, y: i32, value: u16) {
    game_field.collision.map(y, x, |p| *p = value);
}

#[no_mangle]
pub extern "C" fn land_pixel_get(game_field: &mut GameField, x: i32, y: i32) -> u32 {
    game_field.pixels.map(y, x, |p| *p)
}

#[no_mangle]
pub extern "C" fn land_pixel_set(game_field: &mut GameField, x: i32, y: i32, value: u32) {
    game_field.pixels.map(y, x, |p| *p = value);
}

#[no_mangle]
pub extern "C" fn dispose_game_field(game_field: *mut GameField) {
    unsafe { drop(Box::from_raw(game_field)) };
}
