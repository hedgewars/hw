use integral_geometry::{Point, Rect, Size};
use land2d::Land2D;
use landgen::{
    outline_template::OutlineTemplate, template_based::TemplatedLandGenerator,
    LandGenerationParameters, LandGenerator,
};
use lfprng::LaggedFibonacciPRNG;

pub struct World {
    random_numbers_gen: LaggedFibonacciPRNG,
    preview: Land2D<u8>,
}

impl World {
    pub fn new() -> Self {
        Self {
            random_numbers_gen: LaggedFibonacciPRNG::new(&[]),
            preview: Land2D::new(Size::new(0, 0), 0),
        }
    }

    pub fn preview(&self) -> &Land2D<u8> {
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

        let params = LandGenerationParameters::new(0 as u8, 255, 5, false, false);
        let landgen = TemplatedLandGenerator::new(template());
        self.preview = landgen.generate_land(&params, &mut self.random_numbers_gen);
    }
}
