use fpnum::{FPNum, fp};
use integral_geometry::{Point, Rect, Size};
use land2d::Land2D;
use landgen::{
    outline_template::OutlineTemplate,
    template_based::TemplatedLandGenerator,
    LandGenerationParameters,
    LandGenerator,
};
use lfprng::LaggedFibonacciPRNG;
use hwphysics as hwp;

struct GameState {
    land: Land2D<u32>,
    physics: hwp::World,
}

impl GameState {
    fn new(land: Land2D<u32>, physics: hwp::World) -> Self {
        Self {
            land,
            physics,
        }
    }
}

pub struct World {
    random_numbers_gen: LaggedFibonacciPRNG,
    preview: Option<Land2D<u8>>,
    game_state: Option<GameState>,
}

impl World {
    pub fn new() -> Self {
        Self {
            random_numbers_gen: LaggedFibonacciPRNG::new(&[]),
            preview: None,
            game_state: None,
        }
    }

    pub fn set_seed(&mut self, seed: &[u8]) {
        self.random_numbers_gen = LaggedFibonacciPRNG::new(seed);
    }

    pub fn preview(&self) -> &Option<Land2D<u8>> {
        &self.preview
    }

    pub fn generate_preview(&mut self) {
        fn template() -> OutlineTemplate {
            let mut template = OutlineTemplate::new(Size::new(4096, 2048));
            template.islands = vec![vec![
                Rect::from_size_coords(100, 2050, 1, 1),
                Rect::from_size_coords(100, 500, 400, 1200),
                Rect::from_size_coords(3600, 500, 400, 1200),
                Rect::from_size_coords(3900, 2050, 1, 1),
            ]];
            template.fill_points = vec![Point::new(1, 0)];

            template
        }

        let params = LandGenerationParameters::new(0u8, u8::max_value(), 5, false, false);
        let landgen = TemplatedLandGenerator::new(template());
        self.preview = Some(landgen.generate_land(&params, &mut self.random_numbers_gen));
    }

    pub fn dispose_preview(&mut self) {
        self.preview = None
    }

    pub fn init(&mut self, template: OutlineTemplate) {
        let physics = hwp::World::new(template.size);

        let params = LandGenerationParameters::new(0u32, u32::max_value(), 5, false, false);
        let landgen = TemplatedLandGenerator::new(template);
        let land = landgen.generate_land(&params, &mut self.random_numbers_gen);

        self.game_state = Some(GameState::new(land, physics));
    }

    pub fn step(&mut self) {
        if let Some(ref mut state) = self.game_state {
            state.physics.step(fp!(1), &state.land);
        }
    }
}
