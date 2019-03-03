use sdl2::{
    keyboard::Scancode,
    event::EventType,
    surface::Surface,
    pixels::{
        PixelFormatEnum, Color
    }
};

use integral_geometry::{Point, Size, Rect, Line};

use rand::{
    thread_rng, RngCore, Rng,
    distributions::uniform::SampleUniform
};

use landgen::{
    template_based::TemplatedLandGenerator,
    outline_template::OutlineTemplate,
    LandGenerator,
    LandGenerationParameters
};
use land2d::Land2D;
use lfprng::LaggedFibonacciPRNG;

struct LandSource<T> {
    rnd: LaggedFibonacciPRNG,
    generator: T
}

impl <T: LandGenerator> LandSource<T> {
    fn new(generator: T) -> Self {
        let mut init = [0u8; 64];
        thread_rng().fill_bytes(&mut init);
        LandSource {
            rnd: LaggedFibonacciPRNG::new(&init),
            generator
        }
    }

    fn next(&mut self, parameters: LandGenerationParameters<u32>) -> Land2D<u32> {
        self.generator.generate_land(&parameters, &mut self.rnd)
    }
}

fn fill_pixels(pixels: &mut [u8], land: &Land2D<u32>) {
    for (surf_row, land_row) in pixels.chunks_mut(land.width() * 4).zip(land.rows()) {
        for (surf_pixel, land_pixel) in surf_row.chunks_mut(4).zip(land_row) {
            if let [b, g, r, a] = surf_pixel {
                *a = 255; *r = *land_pixel as u8;
            }
        }
    }
}

fn fill_texture(surface: &mut Surface, land: &Land2D<u32>) {
    if surface.must_lock() {
        surface.with_lock_mut(|data| fill_pixels(data, land));
    } else {
        surface.without_lock_mut().map(|data| fill_pixels(data, land));
    }
}

fn rnd<T: Default + SampleUniform + Ord>(max: T) -> T {
    thread_rng().gen_range(T::default(), max)
}

const WINDOW_WIDTH: u32 = 800;
const WINDOW_HEIGHT: u32 = 600;
const WINDOW_SIZE: Size = Size {width: WINDOW_WIDTH as usize, height: WINDOW_HEIGHT as usize};

const PLAY_WIDTH: u32 = 3072;
const PLAY_HEIGHT: u32 = 1424;
const PLAY_SIZE: Size = Size {width: PLAY_WIDTH as usize, height: PLAY_HEIGHT as usize};

const LAND_WIDTH: u32 = 4096;
const LAND_HEIGHT: u32 = 2048;
const LAND_SIZE: Size = Size {width: LAND_WIDTH as usize, height: LAND_HEIGHT as usize};

fn point() -> Point {
    Point::new(rnd(LAND_WIDTH as i32), rnd(LAND_HEIGHT as i32))
}
fn rect() -> Rect {
    Rect::new(rnd(LAND_WIDTH as i32), rnd(LAND_HEIGHT as i32), rnd(120) + 8, rnd(120) + 8)
}

fn land_rect() -> Rect {
    Rect::at_origin(PLAY_SIZE)
}

fn basic_template() -> OutlineTemplate {
    OutlineTemplate::new(PLAY_SIZE)
        .with_fill_points(vec![land_rect().center()])
        .add_island(&land_rect().split_at(land_rect().center()))
}

macro_rules! pseudo_yaml {
    [$({x: $x: tt, y: $y: tt, w: $w: tt, h: $h: tt}),*] => {
        [$(Rect::new($x, $y, $w, $h)),*]
    }
}

fn test_template() -> OutlineTemplate {
    let island = pseudo_yaml![
        {x: 810, y: 1424, w: 1, h: 1},
        {x: 560, y: 1160, w: 130, h: 170},
        {x: 742, y: 1106, w: 316, h: 150},
        {x: 638, y: 786, w: 270, h: 180},
        {x: 646, y: 576, w: 242, h: 156},
        {x: 952, y: 528, w: 610, h: 300},
        {x: 1150, y: 868, w: 352, h: 324},
        {x: 1050, y: 1424, w: 500, h: 1},
        {x: 1650, y: 1500, w: 1, h: 1},
        {x: 1890, y: 1424, w: 1, h: 1},
        {x: 1852, y: 1304, w: 74, h: 12},
        {x: 1648, y: 975, w: 68, h: 425},
        {x: 1826, y: 992, w: 140, h: 142},
        {x: 1710, y: 592, w: 150, h: 350},
        {x: 1988, y: 594, w: 148, h: 242},
        {x: 2018, y: 872, w: 276, h: 314},
        {x: 2110, y: 1250, w: 130, h: 86},
        {x: 2134, y: 1424, w: 1, h: 1}
    ];

    OutlineTemplate::new(PLAY_SIZE)
        .add_island(&island)
        .add_fill_points(&[Point::new(1023, 0)])
}

fn init_source() -> LandSource<TemplatedLandGenerator> {
    let template = test_template();
    let generator = TemplatedLandGenerator::new(template);
    LandSource::new(generator)
}

fn draw_center_mark(land: &mut Land2D<u32>) {
    for i in 0..32 {
        land.draw_thick_line(Line::new(Point::new(LAND_WIDTH as i32 / 2, 0),
                                       Point::new(LAND_WIDTH as i32 / 2, LAND_HEIGHT as i32)), 10, 128);
        land.draw_thick_line(Line::new(Point::new(0, LAND_HEIGHT as i32 / 2),
                                       Point::new(LAND_WIDTH as i32, LAND_HEIGHT as i32 / 2)), 10, 128);
        land.fill_circle(Point::new(LAND_WIDTH as i32, LAND_HEIGHT as i32) / 2, 60, 128);
    }
}

fn draw_random_lines(land: &mut Land2D<u32>) {
    for i in 0..32 {
        land.draw_thick_line(Line::new(point(), point()), rnd(5), 128);

        land.fill_circle(point(), rnd(60), 128);
    }
}

fn main() {
    let sdl = sdl2::init().unwrap();
    let _image = sdl2::image::init(sdl2::image::INIT_PNG).unwrap();
    let events = sdl.event().unwrap();

    let mut pump = sdl.event_pump().unwrap();
    let video = sdl.video().unwrap();
    let window = video.window("Theme Editor", WINDOW_WIDTH, WINDOW_HEIGHT)
        .position_centered()
        .build().unwrap();

    let mut source = init_source();
    let mut land = source.next(
        LandGenerationParameters::new(0, u32::max_value(), 1, false, false));
    draw_center_mark(&mut land);

    let mut land_surf = Surface::new(LAND_WIDTH, LAND_HEIGHT, PixelFormatEnum::ARGB8888).unwrap();

    fill_texture(&mut land_surf, &land);

    let mut win_surf = window.surface(&pump).unwrap();
    let dest_rect = win_surf.rect();
    land_surf.blit_scaled(land_surf.rect(), &mut win_surf, dest_rect).unwrap();
    win_surf.update_window();

    'pool: loop {
        use sdl2::event::Event::*;
        pump.pump_events();

        while let Some(event) = pump.poll_event() {
            match event {
                Quit{ .. } => break 'pool,
                _ => ()
            }
        }
    }
}