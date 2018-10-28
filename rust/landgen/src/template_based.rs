use integral_geometry::Point;
use land2d::Land2D;
use LandGenerationParameters;
use LandGenerator;

struct OutlineTemplate {
    islands: Vec<Vec<Point>>,
    fill_points: Vec<Point>,
    width: usize,
    height: usize,
    can_flip: bool,
    can_invert: bool,
    can_mirror: bool,
    is_negative: bool,
}

struct TemplatedLandGenerator {
    outline_template: OutlineTemplate,
}

impl OutlineTemplate {}

impl TemplatedLandGenerator {
    fn new(outline_template: OutlineTemplate) -> Self {
        Self { outline_template }
    }
}

impl LandGenerator for TemplatedLandGenerator {
    fn generate_land<T: Copy + PartialEq, I: Iterator<Item = u32>>(
        &self,
        parameters: LandGenerationParameters<T>,
        random_numbers: &mut I,
    ) -> Land2D<T> {
        let mut pa = Vec::new();

        for island in &self.outline_template.islands {
            let mut island_points = Vec::new();

            for p in island {
                island_points.push(p);
            }

            pa.push(island_points);
        }

        let mut land = Land2D::new(
            self.outline_template.width,
            self.outline_template.height,
            parameters.basic,
        );

        land
    }
}
