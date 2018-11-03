use integral_geometry::{Point, Size};
use land2d::Land2D;
use LandGenerationParameters;
use LandGenerator;

use outline::OutlinePoints;
use outline_template::OutlineTemplate;

pub struct TemplatedLandGenerator {
    outline_template: OutlineTemplate,
}

impl TemplatedLandGenerator {
    pub fn new(outline_template: OutlineTemplate) -> Self {
        Self { outline_template }
    }
}

impl LandGenerator for TemplatedLandGenerator {
    fn generate_land<T: Copy + PartialEq, I: Iterator<Item = u32>>(
        &self,
        parameters: &LandGenerationParameters<T>,
        random_numbers: &mut I,
    ) -> Land2D<T> {
        let mut land = Land2D::new(self.outline_template.size, parameters.basic);

        let mut points = OutlinePoints::from_outline_template(
            &self.outline_template,
            land.play_box(),
            land.size(),
            random_numbers,
        );

        // mirror
        if self.outline_template.can_mirror {
            if let Some(b) = random_numbers.next() {
                if b & 1 != 0 {
                    points.mirror();
                }
            }
        }

        // flip
        if self.outline_template.can_flip {
            if let Some(b) = random_numbers.next() {
                if b & 1 != 0 {
                    points.flip();
                }
            }
        }

        if !parameters.skip_distort {
            points.distort(parameters.distance_divisor, random_numbers);
        }

        if !parameters.skip_bezier {
            points.bezierize();
        }

        points.draw(&mut land, parameters.zero);

        for p in &points.fill_points {
            land.fill(*p, parameters.zero, parameters.zero)
        }

        points.draw(&mut land, parameters.basic);

        land
    }
}
