use super::{outline::OutlinePoints, outline_template::OutlineTemplate};
use crate::{LandGenerationParameters, LandGenerator};
use land2d::Land2D;
use rand::Rng;

pub struct TemplatedLandGenerator {
    outline_template: OutlineTemplate,
}

impl TemplatedLandGenerator {
    pub fn new(outline_template: OutlineTemplate) -> Self {
        Self { outline_template }
    }
}

impl LandGenerator for TemplatedLandGenerator {
    fn generate_land<T: Copy + PartialEq + Default>(
        &self,
        parameters: &LandGenerationParameters<T>,
        random_numbers: &mut impl Rng,
    ) -> Land2D<T> {
        let do_invert = self.outline_template.is_negative
            && (!self.outline_template.can_invert || random_numbers.random());
        let (basic, zero) = if do_invert {
            (parameters.zero, parameters.basic)
        } else {
            (parameters.basic, parameters.zero)
        };

        let mut land = Land2D::new(&self.outline_template.size, basic);

        let mut points = OutlinePoints::from_outline_template(
            &self.outline_template,
            land.play_box(),
            land.size().size(),
            random_numbers,
        );

        // mirror
        if self.outline_template.can_mirror && random_numbers.random() {
            points.mirror();
        }

        // flip
        if self.outline_template.can_flip && random_numbers.random() {
            points.flip();
        }

        if !parameters.skip_distort {
            let distortion_limiting_factor = 100 + random_numbers.random_range(0..8) * 10;

            points.distort(
                parameters.distance_divisor,
                distortion_limiting_factor,
                random_numbers,
            );
        }

        if !parameters.skip_bezier {
            points.bezierize(5);
        }

        points.draw(&mut land, zero);

        for p in &points.fill_points {
            land.fill(*p, zero, zero)
        }

        points.draw(&mut land, basic);

        land
    }
}
