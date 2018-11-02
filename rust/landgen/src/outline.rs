use itertools::Itertools;

use integral_geometry::{Point, Size};
use land2d::Land2D;

use outline_template::OutlineTemplate;

pub struct OutlinePoints {
    pub islands: Vec<Vec<Point>>,
    pub fill_points: Vec<Point>,
    pub size: Size,
}

impl OutlinePoints {
    pub fn from_outline_template<I: Iterator<Item = u32>>(
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

    pub fn total_len(&self) -> usize {
        self.islands.iter().map(|i| i.len()).sum::<usize>() + self.fill_points.len()
    }

    pub fn iter_mut(&mut self) -> impl Iterator<Item = &mut Point> {
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
            let mut i = 0;
            let mut start_point = Point::zero();
            let mut end_point = Point::zero();

            loop {
                {
                    let island = &self.islands[is];
                    if i < island.len() {
                        start_point = island[i];
                        end_point = if i + 1 < island.len() {
                            island[i + 1]
                        } else {
                            island[0]
                        };
                    } else {
                        break
                    }
                }

                if let Some(new_point) = self.divide_edge(start_point, end_point, random_numbers) {
                    self.islands[is].insert(i + 1, new_point);
                    i += 2;
                } else {
                    i += 1;
                }
            }
        }
    }

    pub fn bezierize(&mut self) {
        unimplemented!()
    }

    pub fn distort<I: Iterator<Item = u32>>(&mut self, random_numbers: &mut I) {
        loop {
            let old_len = self.total_len();
            self.divide_edges(random_numbers);

            if self.total_len() != old_len {
                break;
            }
        }

        self.bezierize();
    }

    pub fn draw<T: Copy + PartialEq>(&self, land: &mut Land2D<T>, value: T) {
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
