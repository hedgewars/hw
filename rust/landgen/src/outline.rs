use itertools::Itertools;

use integral_geometry::{Line, Point, Size};
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
        segment: Line,
        random_numbers: &mut I,
    ) -> Option<Point> {

        None
    }

    fn divide_edges<I: Iterator<Item = u32>>(&mut self, random_numbers: &mut I) {
        for is in 0..self.islands.len() {
            let mut i = 0;
            let mut segment;

            loop {
                {
                    let island = &self.islands[is];
                    let mut end_point;
                    if i < island.len() {
                        end_point = if i + 1 < island.len() {
                            island[i + 1]
                        } else {
                            island[0]
                        };
                    } else {
                        break;
                    }

                    segment = Line::new(island[i], end_point);
                }

                if let Some(new_point) = self.divide_edge(segment, random_numbers) {
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
        for segment in self.segments_iter() {
            land.draw_line(segment, value);
        }
    }

    fn segments_iter(&self) -> OutlineSegmentsIterator {
        OutlineSegmentsIterator {
            outline: self,
            island: 0,
            index: 0,
        }
    }
}

struct OutlineSegmentsIterator<'a> {
    outline: &'a OutlinePoints,
    island: usize,
    index: usize,
}

impl<'a> Iterator for OutlineSegmentsIterator<'a> {
    type Item = Line;

    fn next(&mut self) -> Option<Self::Item> {
        if self.island < self.outline.islands.len() {
            if self.index + 1 < self.outline.islands[self.index].len() {
                Some(Line::new(
                    self.outline.islands[self.index][self.index],
                    self.outline.islands[self.index][self.index + 1],
                ))
            } else if self.index + 1 == self.outline.islands[self.index].len() {
                Some(Line::new(
                    self.outline.islands[self.index][self.index],
                    self.outline.islands[self.index][0],
                ))
            } else {
                self.island += 1;
                self.next()
            }
        } else {
            None
        }
    }
}
