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
        parameters: LandGenerationParameters<T>,
        random_numbers: &mut I,
    ) -> Land2D<T> {
        let mut points =
            OutlinePoints::from_outline_template(&self.outline_template, random_numbers);

        let mut land = Land2D::new(points.size, parameters.basic);

        let top_left = Point::new(
            (land.width() - land.play_width() / 2) as i32,
            (land.height() - land.play_height()) as i32,
        );

        points.size = land.size();

        points.iter_mut().for_each(|p| *p += top_left);

        // mirror
        if self.outline_template.can_mirror {
            if let Some(b) = random_numbers.next() {
                if b & 1 != 0 {
                    points
                        .iter_mut()
                        .for_each(|p| p.x = land.width() as i32 - 1 - p.x);
                }
            }
        }

        // flip
        if self.outline_template.can_flip {
            if let Some(b) = random_numbers.next() {
                if b & 1 != 0 {
                    points
                        .iter_mut()
                        .for_each(|p| p.y = land.height() as i32 - 1 - p.y);
                }
            }
        }

        points.distort(random_numbers);

        points.draw(&mut land, parameters.zero);

        for p in &points.fill_points {
            land.fill(*p, parameters.zero, parameters.zero)
        }

        points.draw(&mut land, parameters.basic);

        land
    }
}

#[test()]
fn points_test() {
    let mut points = OutlinePoints {
        islands: vec![vec![]],
        fill_points: vec![Point::new(1, 1)],
        size: Size::square(100),
    };

    points.iter_mut().for_each(|p| p.x = 2);
    assert_eq!(points.fill_points[0].x, 2);
}
