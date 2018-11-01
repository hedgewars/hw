use itertools::Itertools;

use integral_geometry::{Point, Size, Rect};
use land2d::Land2D;
use LandGenerationParameters;
use LandGenerator;

struct OutlinePoints {
    islands: Vec<Vec<Point>>,
    fill_points: Vec<Point>,
    size: Size,
}

impl OutlinePoints {
    fn from_outline_template<I: Iterator<Item = u32>>(
        outline_template: &OutlineTemplate,
        random_numbers: &mut I,
    ) -> Self {
        Self {
            islands: outline_template
                .islands
                .iter()
                .map(|i| {
                    i.iter()
                        .zip(random_numbers.tuples())
                        .map(|(rect, (rnd_a, rnd_b))| {
                            Point::new(
                                rect.x + (rnd_a % rect.width) as i32,
                                rect.y + (rnd_b % rect.height) as i32,
                            )
                        }).collect()
                }).collect(),
            fill_points: outline_template.fill_points.clone(),
            size: outline_template.size
        }
    }

    fn iter_mut(&mut self) -> impl Iterator<Item = &mut Point> {
        self.islands.iter_mut()
            .flat_map(|i| i.iter_mut())
            .chain(self.fill_points.iter_mut())
    }

    fn distort<I: Iterator<Item = u32>>(&mut self, random_numbers: &mut I) {
        unimplemented!()
    }
}

pub struct OutlineTemplate {
    islands: Vec<Vec<Rect>>,
    fill_points: Vec<Point>,
    size: Size,
    can_flip: bool,
    can_invert: bool,
    can_mirror: bool,
    is_negative: bool,
}

impl OutlineTemplate {
    pub fn new(size: Size) -> Self {
        OutlineTemplate {
            size,
            islands: Vec::new(),
            fill_points: Vec::new(),
            can_flip: false,
            can_invert: false,
            can_mirror: false,
            is_negative: false
        }
    }

    pub fn flippable(self) -> Self {
        Self { can_flip: true, ..self }
    }

    pub fn mirrorable(self) -> Self {
        Self { can_mirror: true, ..self }
    }

    pub fn invertable(self) -> Self {
        Self { can_invert: true, ..self }
    }

    pub fn negative(self) -> Self {
        Self { is_negative: true, ..self }
    }

    pub fn with_fill_points(self, fill_points: Vec<Point>) -> Self
    {
        Self { fill_points, ..self }
    }

    pub fn with_islands(mut self, islands: Vec<Vec<Rect>>) -> Self {
        Self { islands, ..self }
    }

    pub fn add_fill_points(mut self, points: &[Point]) -> Self {
        self.fill_points.extend_from_slice(points); self
    }

    pub fn add_island(mut self, island: &[Rect]) -> Self {
        self.islands.push(island.into()); self
    }
}

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
                    points.iter_mut().for_each(|p| p.x = land.width() as i32 - 1 - p.x);
                }
            }
        }

        // flip
        if self.outline_template.can_flip {
            if let Some(b) = random_numbers.next() {
                if b & 1 != 0 {
                    points.iter_mut().for_each(|p|
                        p.y = land.height() as i32 - 1 - p.y);
                }
            }
        }

        points.distort(random_numbers);

        // draw_edge(points, land, parameters.zero)

        for p in points.fill_points {
            land.fill(p, parameters.zero, parameters.zero)
        }

        // draw_edge(points, land, parameters.basic)

        land
    }
}

#[test()]
fn points_test() {
    let mut points = OutlinePoints {
        islands: vec![vec![]],
        fill_points: vec![Point::new(1, 1)],
        size: Size::square(100)
    };

    points.iter_mut().for_each(|p| p.x = 2);
    assert_eq!(points.fill_points[0].x, 2);
}
