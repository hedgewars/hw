use itertools::Itertools;
use std::cmp::min;

use integral_geometry::{Line, Point, Rect, Size};
use land2d::Land2D;

use outline_template::OutlineTemplate;

pub struct OutlinePoints {
    pub islands: Vec<Vec<Point>>,
    pub fill_points: Vec<Point>,
    pub size: Size,
    pub play_box: Rect,
}

impl OutlinePoints {
    pub fn from_outline_template<I: Iterator<Item = u32>>(
        outline_template: &OutlineTemplate,
        play_box: Rect,
        size: Size,
        random_numbers: &mut I,
    ) -> Self {
        Self {
            play_box,
            size,
            islands: outline_template
                .islands
                .iter()
                .map(|i| {
                    i.iter()
                        .zip(random_numbers.tuples())
                        .map(|(rect, (rnd_a, rnd_b))| {
                            rect.top_left()
                                + Point::new(
                                    (rnd_a % rect.width) as i32,
                                    (rnd_b % rect.height) as i32,
                                )
                                + play_box.top_left()
                        }).collect()
                }).collect(),
            fill_points: outline_template.fill_points.clone(),
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
        let min_distance = 40;
        // new point should fall inside this box
        let map_box = self.play_box.with_margin(min_distance);

        let p = Point::new(
            segment.end.y - segment.start.y,
            segment.start.x - segment.start.y,
        );
        let mid_point = segment.center();

        if (p.integral_norm() < min_distance as u32 * 3) || !map_box.contains_inside(p) {
            return None;
        }

        let full_box = Rect::from_size(Point::zero(), self.size).with_margin(min_distance);

        let mut dist_left = (self.size.width + self.size.height) as u32;
        let mut dist_right = dist_left;

        // find distances to map borders
        if p.x != 0 {
            // check against left border
            let iyl = (map_box.left() - mid_point.x) * p.y / p.x + mid_point.y;
            let dl = Point::new(mid_point.x - map_box.left(), mid_point.y - iyl).integral_norm();
            let t = p.x * (mid_point.x - full_box.left()) + p.y * (mid_point.y - iyl);

            if t > 0 {
                dist_left = dl;
            } else {
                dist_right = dl;
            }

            // right border
            let iyr = (map_box.right() - mid_point.x) * p.y / p.x + mid_point.y;
            let dr = Point::new(mid_point.x - full_box.right(), mid_point.y - iyr).integral_norm();

            if t > 0 {
                dist_right = dr;
            } else {
                dist_left = dr;
            }
        }

        if p.y != 0 {
            // top border
            let ixl = (map_box.top() - mid_point.y) * p.x / p.y + mid_point.x;
            let dl = Point::new(mid_point.y - map_box.top(), mid_point.x - ixl).integral_norm();
            let t = p.y * (mid_point.y - full_box.top()) + p.x * (mid_point.x - ixl);

            if t > 0 {
                dist_left = min(dist_left, dl);
            } else {
                dist_right = min(dist_right, dl);
            }

            // bottom border
            let ixr = (map_box.bottom() - mid_point.y) * p.x / p.y + mid_point.x;
            let dr = Point::new(mid_point.y - full_box.bottom(), mid_point.x - ixr).integral_norm();

            if t > 0 {
                dist_right = min(dist_right, dr);
            } else {
                dist_left = min(dist_left, dr);
            }
        }

        // now go through all other segments

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

            if self.total_len() == old_len {
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

    pub fn mirror(&mut self) {
        self.iter_mut()
            .for_each(|p| p.x = self.size.width() - 1 - p.x);
    }

    pub fn flip(&mut self) {
        points
            .iter_mut()
            .for_each(|p| p.y = self.size.height() - 1 - p.y);
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
            if self.index + 1 < self.outline.islands[self.island].len() {
                let result = Some(Line::new(
                    self.outline.islands[self.island][self.index],
                    self.outline.islands[self.island][self.index + 1],
                ));

                self.index += 1;

                result
            } else if self.index + 1 == self.outline.islands[self.island].len() {
                let result = Some(Line::new(
                    self.outline.islands[self.island][self.index],
                    self.outline.islands[self.island][0],
                ));

                self.island += 1;
                self.index = 0;

                result
            } else {
                self.island += 1;
                self.index = 0;
                self.next()
            }
        } else {
            None
        }
    }
}

#[test()]
fn points_test() {
    let mut points = OutlinePoints {
        islands: vec![
            vec![Point::new(0, 0), Point::new(20, 0), Point::new(30, 30)],
            vec![Point::new(10, 15), Point::new(15, 20), Point::new(20, 15)],
        ],
        fill_points: vec![Point::new(1, 1)],
        play_box: Rect::from_box(0, 100, 0, 100).with_margin(10),
        size: Size::square(100),
    };

    let segments: Vec<Line> = points.segments_iter().collect();
    assert_eq!(
        segments.first(),
        Some(&Line::new(Point::new(0, 0), Point::new(20, 0)))
    );
    assert_eq!(
        segments.last(),
        Some(&Line::new(Point::new(20, 15), Point::new(10, 15)))
    );

    points.iter_mut().for_each(|p| p.x = 2);
    assert_eq!(points.fill_points[0].x, 2);
    assert_eq!(points.islands[0][0].x, 2);
}
