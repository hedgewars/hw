use sdl2::{
    keyboard::Scancode,
    event::EventType
};

use rand::{
    thread_rng, RngCore
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

fn main() {
    let sdl = sdl2::init().unwrap();
    let _image = sdl2::image::init(sdl2::image::INIT_PNG).unwrap();
    let events = sdl.event().unwrap();

    let mut pump = sdl.event_pump().unwrap();
    let video = sdl.video().unwrap();
    let _window = video.window("Theme Editor", 640, 480)
        .position_centered()
        .build().unwrap();

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


