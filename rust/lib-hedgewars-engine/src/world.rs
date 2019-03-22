use fpnum::{fp, FPNum, FPPoint};
use hwphysics::{self as hwp, common::GearId};
use integral_geometry::{Point, Rect, Size};
use land2d::Land2D;
use landgen::{
    outline_template::OutlineTemplate, template_based::TemplatedLandGenerator,
    LandGenerationParameters, LandGenerator,
};
use lfprng::LaggedFibonacciPRNG;

use crate::render::{camera::Camera, MapRenderer};

struct GameState {
    land: Land2D<u32>,
    physics: hwp::World,
}

impl GameState {
    fn new(land: Land2D<u32>, physics: hwp::World) -> Self {
        Self { land, physics }
    }
}

pub struct World {
    random_numbers_gen: LaggedFibonacciPRNG,
    preview: Option<Land2D<u8>>,
    game_state: Option<GameState>,
    renderer: Option<MapRenderer>,
    camera: Camera,
    last_gear_id: GearId,
}

impl World {
    pub fn new() -> Self {
        Self {
            random_numbers_gen: LaggedFibonacciPRNG::new(&[]),
            preview: None,
            game_state: None,
            renderer: None,
            camera: Camera::new(),
            last_gear_id: GearId::default(),
        }
    }

    pub fn create_renderer(&mut self, width: u16, height: u16) {
        let land_tile_size = Size::square(512);
        self.renderer = Some(MapRenderer::new(land_tile_size));
        self.camera = Camera::with_size(Size::new(width as usize, height as usize));

        use mapgen::{theme::Theme, MapGenerator};
        use std::path::Path;

        if let Some(ref state) = self.game_state {
            self.camera.position = state.land.play_box().center();

            let theme =
                Theme::load(Path::new("../../share/hedgewars/Data/Themes/Cheese/")).unwrap();
            let texture = MapGenerator::new().make_texture(&state.land, &theme);
            if let Some(ref mut renderer) = self.renderer {
                renderer.init(&texture);
            }
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

    pub fn move_camera(&mut self, position_shift: Point, zoom_shift: f32) {
        self.camera.zoom += zoom_shift;
        self.camera.position += Point::new(
            (position_shift.x as f32 / self.camera.zoom) as i32,
            (position_shift.y as f32 / self.camera.zoom) as i32,
        );
    }

    pub fn render(&mut self) {
        if let Some(ref mut renderer) = self.renderer {
            unsafe {
                gl::ClearColor(0.4f32, 0f32, 0.2f32, 1f32);
                gl::Clear(gl::COLOR_BUFFER_BIT);
            }

            renderer.render(self.camera.viewport());
        }
    }

    fn get_unused_gear_id(&mut self) -> GearId {
        let id = self.last_gear_id;
        self.last_gear_id += 1;
        id
    }

    fn create_gear(&mut self, position: Point) {
        let id = self.get_unused_gear_id();
        if let Some(ref mut state) = self.game_state {
            let fp_position = FPPoint::new(position.x.into(), position.y.into());
            state.physics.add_gear_data(
                id,
                hwp::physics::PhysicsData::new(fp_position, FPPoint::zero()),
            )
        }
    }

    pub fn step(&mut self) {
        if let Some(ref mut state) = self.game_state {
            let next = self.random_numbers_gen.next().unwrap();
            if next % 32 == 0 {
                let position = Point::new(
                    (self.random_numbers_gen.next().unwrap() % state.land.width() as u32) as i32,
                    0,
                );
                self.create_gear(position);
            }
        }

        if let Some(ref mut state) = self.game_state {
            state.physics.step(fp!(1), &state.land);
        }
    }
}
