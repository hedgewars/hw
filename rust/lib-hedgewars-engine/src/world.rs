use fpnum::{fp, FPNum, FPPoint};
use hwphysics::{
    self as hwp,
    common::{GearId, Millis},
    physics::{PositionData, VelocityData},
};
use integral_geometry::{Point, Rect, Size};
use land2d::Land2D;
use landgen::{
    outline_template::OutlineTemplate, template_based::TemplatedLandGenerator,
    LandGenerationParameters, LandGenerator,
};
use lfprng::LaggedFibonacciPRNG;
use std::path::{Path, PathBuf};

use crate::render::{camera::Camera, GearEntry, GearRenderer, MapRenderer};

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
    feature_size: u8,
    preview: Option<Land2D<u8>>,
    game_state: Option<GameState>,
    map_renderer: Option<MapRenderer>,
    gear_renderer: Option<GearRenderer>,
    camera: Camera,
    gear_entries: Vec<GearEntry>,
    data_path: PathBuf,
}

impl World {
    pub fn new(data_path: &Path) -> Self {
        Self {
            random_numbers_gen: LaggedFibonacciPRNG::new(&[]),
            feature_size: 5,
            preview: None,
            game_state: None,
            map_renderer: None,
            gear_renderer: None,
            camera: Camera::new(),
            gear_entries: vec![],
            data_path: data_path.to_owned(),
        }
    }

    pub fn create_renderer(&mut self, width: u16, height: u16) {
        let land_tile_size = Size::square(512);
        self.map_renderer = Some(MapRenderer::new(land_tile_size));
        self.gear_renderer = Some(GearRenderer::new(&self.data_path.as_path()));
        self.camera = Camera::with_size(Size::new(width as usize, height as usize));

        use mapgen::{theme::Theme, MapGenerator};

        if let Some(ref state) = self.game_state {
            self.camera.position = state.land.play_box().center();

            let theme =
                Theme::load(self.data_path.join(Path::new("Themes/Cheese/")).as_path()).unwrap();
            let texture = MapGenerator::new().make_texture(&state.land, &theme);
            if let Some(ref mut renderer) = self.map_renderer {
                renderer.init(&texture);
            }
        }
    }

    pub fn set_seed(&mut self, seed: &[u8]) {
        self.random_numbers_gen = LaggedFibonacciPRNG::new(seed);
    }

    pub fn set_feature_size(&mut self, feature_size: u8) {
        self.feature_size = feature_size;
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

        // based on old engine min_distance... dunno if this is the correct place tho
        let distance_divisor = (self.feature_size as u32).pow(2) / 8 + 10;

        let params = LandGenerationParameters::new(0u8, u8::MAX, distance_divisor, false, false);
        let landgen = TemplatedLandGenerator::new(template());
        self.preview = Some(landgen.generate_land(&params, &mut self.random_numbers_gen));
    }

    pub fn dispose_preview(&mut self) {
        self.preview = None
    }

    pub fn init(&mut self, template: OutlineTemplate) {
        let params = LandGenerationParameters::new(0u32, u32::MAX, 5, false, false);
        let landgen = TemplatedLandGenerator::new(template);
        let land = landgen.generate_land(&params, &mut self.random_numbers_gen);

        let physics = hwp::World::new(land.size());

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
        if let Some(ref mut renderer) = self.map_renderer {
            unsafe {
                gl::ClearColor(0.4f32, 0f32, 0.2f32, 1f32);
                gl::Clear(gl::COLOR_BUFFER_BIT);
            }

            renderer.render(&self.camera);
        }

        self.gear_entries.clear();
        let mut gear_entries = std::mem::take(&mut self.gear_entries);

        if let Some(ref mut renderer) = self.gear_renderer {
            if let Some(ref mut state) = self.game_state {
                state
                    .physics
                    .iter_data()
                    .run(|(pos,): (&mut PositionData,)| {
                        gear_entries.push(GearEntry::new(
                            f64::from(pos.0.x()) as f32,
                            f64::from(pos.0.y()) as f32,
                            Size::square(256),
                        ))
                    });
            }
            renderer.render(&self.camera, &gear_entries);
        }
        self.gear_entries = gear_entries;
    }

    fn create_gear(&mut self, position: Point) {
        if let Some(ref mut state) = self.game_state {
            let id = state.physics.new_gear().unwrap();
            let fp_position = FPPoint::new(position.x.into(), position.y.into());
            state.physics.add_gear_data(id, &PositionData(fp_position));
            state
                .physics
                .add_gear_data(id, &VelocityData(FPPoint::zero()))
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
            state.physics.step(Millis::new(1), &state.land);
        }
    }
}
