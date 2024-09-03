use integral_geometry::{Point, Size};

use landgen::{
    outline_template_based::outline_template::OutlineTemplate,
    wavefront_collapse::generator::TemplateDescription as WfcTemplate, LandGenerationParameters,
    LandGenerator,
};
use lfprng::LaggedFibonacciPRNG;
use mapgen::{theme::Theme, MapGenerator};
use std::fs;
use std::{ffi::CStr, path::Path};

#[repr(C)]
pub struct GameField {
    collision: land2d::Land2D<u16>,
    pixels: land2d::Land2D<u32>,
    landgen_parameters: Option<LandGenerationParameters<u16>>,
}

#[no_mangle]
pub extern "C" fn get_game_field_parameters(
    game_field: &GameField,
    width: *mut i32,
    height: *mut i32,
    play_width: *mut i32,
    play_height: *mut i32,
) {
    unsafe {
        *width = game_field.collision.width() as i32;
        *height = game_field.collision.height() as i32;

        *play_width = game_field.collision.play_width() as i32;
        *play_height = game_field.collision.play_height() as i32;
    }
}

#[no_mangle]
pub extern "C" fn create_empty_game_field(width: u32, height: u32) -> *mut GameField {
    let game_field = Box::new(GameField {
        collision: land2d::Land2D::new(&Size::new(width as usize, height as usize), 0),
        pixels: land2d::Land2D::new(&Size::new(width as usize, height as usize), 0),
        landgen_parameters: None,
    });

    Box::leak(game_field)
}

#[no_mangle]
pub extern "C" fn generate_outline_templated_game_field(
    feature_size: u32,
    seed: *const i8,
    template_type: *const i8,
    data_path: *const i8,
) -> *mut GameField {
    let data_path: &str = unsafe { CStr::from_ptr(data_path) }.to_str().unwrap();
    let data_path = Path::new(&data_path);

    let seed: &str = unsafe { CStr::from_ptr(seed) }.to_str().unwrap();
    let template_type: &str = unsafe { CStr::from_ptr(template_type) }.to_str().unwrap();

    let mut random_numbers_gen = LaggedFibonacciPRNG::new(seed.as_bytes());

    let yaml_templates =
        fs::read_to_string(data_path.join(Path::new("map_templates.yaml")).as_path())
            .expect("Error reading map templates file");
    let mut map_gen = MapGenerator::<OutlineTemplate>::new(data_path);
    map_gen.import_yaml_templates(&yaml_templates);

    let distance_divisor = feature_size.pow(2) / 8 + 10;
    let params = LandGenerationParameters::new(0u16, 0x8000u16, distance_divisor, false, false);
    let template = map_gen
        .get_template(template_type, &mut random_numbers_gen)
        .expect("Error reading outline templates file")
        .clone();
    let landgen = map_gen.build_generator(template);
    let collision = landgen.generate_land(&params, &mut random_numbers_gen);
    let size = collision.size().size();

    let game_field = Box::new(GameField {
        collision,
        pixels: land2d::Land2D::new(&size, 0),
        landgen_parameters: Some(params),
    });

    Box::leak(game_field)
}

#[no_mangle]
pub extern "C" fn generate_wfc_templated_game_field(
    feature_size: u32,
    seed: *const i8,
    template_type: *const i8,
    data_path: *const i8,
) -> *mut GameField {
    let data_path: &str = unsafe { CStr::from_ptr(data_path) }.to_str().unwrap();
    let data_path = Path::new(&data_path);

    let seed: &str = unsafe { CStr::from_ptr(seed) }.to_str().unwrap();
    let template_type: &str = unsafe { CStr::from_ptr(template_type) }.to_str().unwrap();

    let mut random_numbers_gen = LaggedFibonacciPRNG::new(seed.as_bytes());

    let yaml_templates =
        fs::read_to_string(data_path.join(Path::new("wfc_templates.yaml")).as_path())
            .expect("Error reading map templates file");
    let mut map_gen = MapGenerator::<WfcTemplate>::new(data_path);
    map_gen.import_yaml_templates(&yaml_templates);

    let distance_divisor = feature_size.pow(2) / 8 + 10;
    let params = LandGenerationParameters::new(0u16, 0x8000u16, distance_divisor, false, false);
    let template = map_gen
        .get_template(template_type, &mut random_numbers_gen)
        .expect("Error reading wfc templates file")
        .clone();
    let landgen = map_gen.build_generator(template);
    let collision = landgen.generate_land(&params, &mut random_numbers_gen);
    let size = collision.size().size();

    let game_field = Box::new(GameField {
        collision,
        pixels: land2d::Land2D::new(&size, 0),
        landgen_parameters: Some(params),
    });

    Box::leak(game_field)
}

#[no_mangle]
pub extern "C" fn apply_theme(
    game_field: &mut GameField,
    data_path: *const i8,
    theme_name: *const i8,
) {
    let data_path: &str = unsafe { CStr::from_ptr(data_path) }.to_str().unwrap();
    let data_path = Path::new(&data_path);

    let theme_name: &str = unsafe { CStr::from_ptr(theme_name) }.to_str().unwrap();
    let map_gen = MapGenerator::<()>::new(data_path);

    let theme = Theme::load(
        data_path
            .join(Path::new("Themes"))
            .join(Path::new(theme_name))
            .as_path(),
    )
    .unwrap();

    let params = game_field
        .landgen_parameters
        .expect("Land generator parameters specified");
    let pixels = map_gen.make_texture(&game_field.collision, &params, &theme);

    game_field.pixels = pixels.into();
}

#[no_mangle]
pub extern "C" fn land_get(game_field: &GameField, x: i32, y: i32) -> u16 {
    game_field.collision.get(y, x)
}

#[no_mangle]
pub extern "C" fn land_set(game_field: &mut GameField, x: i32, y: i32, value: u16) {
    game_field.collision.map(y, x, |p| *p = value);
}

#[no_mangle]
pub extern "C" fn land_row(game_field: &mut GameField, row: i32) -> *mut u16 {
    game_field.collision[row as usize].as_mut_ptr()
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
pub extern "C" fn land_pixel_get(game_field: &GameField, x: i32, y: i32) -> u32 {
    game_field.pixels.get(y, x)
}

#[no_mangle]
pub extern "C" fn land_pixel_set(game_field: &mut GameField, x: i32, y: i32, value: u32) {
    game_field.pixels.map(y, x, |p| *p = value);
}

#[no_mangle]
pub extern "C" fn land_pixel_row(game_field: &mut GameField, row: i32) -> *mut u32 {
    game_field.pixels[row as usize].as_mut_ptr()
}

#[no_mangle]
pub extern "C" fn dispose_game_field(game_field: *mut GameField) {
    unsafe { drop(Box::from_raw(game_field)) };
}
