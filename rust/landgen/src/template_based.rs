use itertools::Itertools;

use integral_geometry::{Point, Rect, Size};
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
            size: outline_template.size,
        }
    }

    fn total_len(&self) -> usize {
        self.islands.iter().map(|i| i.len()).sum::<usize>() + self.fill_points.len()
    }

    fn iter_mut(&mut self) -> impl Iterator<Item = &mut Point> {
        self.islands
            .iter_mut()
            .flat_map(|i| i.iter_mut())
            .chain(self.fill_points.iter_mut())
    }

    fn divide_edge<I: Iterator<Item = u32>>(
        &self,
        start_point: Point,
        end_point: Point,
        random_numbers: &mut I,
    ) -> Option<Point> {
        None
    }

    fn divide_edges<I: Iterator<Item = u32>>(&mut self, random_numbers: &mut I) {
        for is in 0..self.islands.len() {
            let island = &mut self.islands[is];
            let mut i = 0;

            while i < island.len() {
                let start_point = island[i];
                let end_point = if i + 1 < island.len() {
                    island[i + 1]
                } else {
                    island[0]
                };

                if let Some(new_point) = self.divide_edge(start_point, end_point, random_numbers) {
                    (*island).insert(i + 1, new_point);
                    i += 2;
                } else {
                    i += 1;
                }
            }
        }
    }

    fn bezierize(&mut self) {
        unimplemented!()
    }

    fn distort<I: Iterator<Item = u32>>(&mut self, random_numbers: &mut I) {
        loop {
            let old_len = self.total_len();
            self.divide_edges(random_numbers);

            if self.total_len() != old_len {
                break;
            }
        }

        self.bezierize();
    }

    fn draw<T: Copy + PartialEq>(&self, land: &mut Land2D<T>, value: T) {
        for island in &self.islands {
            if island.len() > 1 {
                for i in 0..island.len() - 1 {
                    land.draw_line(island[i], island[i + 1], value);
                }
                land.draw_line(island[island.len() - 1], island[0], value);
            }
        }
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
            is_negative: false,
        }
    }

    pub fn flippable(self) -> Self {
        Self {
            can_flip: true,
            ..self
        }
    }

    pub fn mirrorable(self) -> Self {
        Self {
            can_mirror: true,
            ..self
        }
    }

    pub fn invertable(self) -> Self {
        Self {
            can_invert: true,
            ..self
        }
    }

    pub fn negative(self) -> Self {
        Self {
            is_negative: true,
            ..self
        }
    }

    pub fn with_fill_points(self, fill_points: Vec<Point>) -> Self {
        Self {
            fill_points,
            ..self
        }
    }

    pub fn with_islands(self, islands: Vec<Vec<Rect>>) -> Self {
        Self { islands, ..self }
    }

    pub fn add_fill_points(mut self, points: &[Point]) -> Self {
        self.fill_points.extend_from_slice(points);
        self
    }

    pub fn add_island(mut self, island: &[Rect]) -> Self {
        self.islands.push(island.into());
        self
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
