use sdl2::{
    keyboard::Scancode,
    event::EventType,
    surface::Surface,
    pixels::{
        PixelFormatEnum, Color
    }
};

use integral_geometry::{Point, Size};

use rand::{
    thread_rng, RngCore, Rng,
    distributions::uniform::SampleUniform
};

use landgen::{
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
        self.generator.generate_land(parameters, &mut self.rnd)
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

const WIDTH: u32 = 512;
const HEIGHT: u32 = 512;
const SIZE: Size = Size {width: 512, height: 512};

fn main() {
    let sdl = sdl2::init().unwrap();
    let _image = sdl2::image::init(sdl2::image::INIT_PNG).unwrap();
    let events = sdl.event().unwrap();

    let mut pump = sdl.event_pump().unwrap();
    let video = sdl.video().unwrap();
    let window = video.window("Theme Editor", WIDTH, HEIGHT)
        .position_centered()
        .build().unwrap();

    let mut land_surf = Surface::new(WIDTH, HEIGHT, PixelFormatEnum::ARGB8888).unwrap();

    fn point() -> Point {
        Point::new(rnd(WIDTH as i32), rnd(HEIGHT as i32))
    }

    let mut land = Land2D::new(SIZE, 0);
    for i in 0..32 {
        land.draw_thick_line(point(), point(), rnd(5), u32::max_value());

        land.fill_circle(point(), rnd(60), u32::max_value());
    }

    fill_texture(&mut land_surf, &land);

    let mut win_surf = window.surface(&pump).unwrap();
    let win_rect = win_surf.rect();
    land_surf.blit(land_surf.rect(), &mut win_surf, win_rect).unwrap();
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