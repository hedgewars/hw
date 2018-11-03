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

    pub fn iter(&self) -> impl Iterator<Item = &Point> {
        self.islands
            .iter()
            .flat_map(|i| i.iter())
            .chain(self.fill_points.iter())
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
        distance_divisor: u32,
        random_numbers: &mut I,
    ) -> Option<Point> {
        #[inline]
        fn intersect(p: &Point, m: &Point, p1: &Point, p2: &Point) -> bool {
            let t1 = (*m - *p1).cross(*p);
            let t2 = (*m - *p2).cross(*p);

            (t1 > 0) != (t2 > 0)
        }

        #[inline]
        fn solve_intersection(p: &Point, m: &Point, s: &Point, e: &Point) -> Option<(i32, u32)> {
            let f = *e - *s;
            let aqpb = p.cross(f) as i64;

            if aqpb != 0 {
                let iy = ((((s.x - m.x) as i64 * p.y as i64 + m.y as i64 * p.x as i64)
                    * f.y as i64
                    - s.y as i64 * f.x as i64 * p.y as i64)
                    / aqpb) as i32;
                let ix = if p.y.abs() > f.y.abs() {
                    (iy - m.y) * p.x / p.y + m.x
                } else {
                    (iy - s.y) * f.x / f.y + s.x
                };

                let intersection_point = Point::new(ix, iy);
                let diff_point = *m - intersection_point;
                let d = diff_point.integral_norm();
                let t = p.dot(diff_point);

                Some((t, d))
            } else {
                None
            }
        }

        let min_distance = 40;
        // new point should fall inside this box
        let map_box = self.play_box.with_margin(min_distance);

        let p = segment.scaled_normal();
        let mid_point = segment.center();

        if (p.integral_norm() < min_distance as u32 * 3) || !map_box.contains_inside(mid_point) {
            return None;
        }

        let mut dist_left = (self.size.width + self.size.height) as u32;
        let mut dist_right = dist_left;

        // find distances to map borders
        if p.x != 0 {
            // where the normal line intersects the left map border
            let left_intersection = Point::new(
                map_box.left(),
                (map_box.left() - mid_point.x) * p.y / p.x + mid_point.y);
            dist_left = (mid_point - left_intersection).integral_norm();

            // same for the right border
            let right_intersection = Point::new(
                map_box.right(),
                (map_box.right() - mid_point.x) * p.y / p.x + mid_point.y);
            dist_right = (mid_point - right_intersection).integral_norm();

            if p.x > 0 {
                std::mem::swap(&mut dist_left, &mut dist_right);
            }
        }

        if p.y != 0 {
            // where the normal line intersects the top map border
            let top_intersection = Point::new(
                (map_box.top() - mid_point.y) * p.x / p.y + mid_point.x,
                map_box.top());
            let dl = (mid_point - top_intersection).integral_norm();

            // same for the bottom border
            let bottom_intersection = Point::new(
                (map_box.bottom() - mid_point.y) * p.x / p.y + mid_point.x,
                map_box.bottom());
            let dr = (mid_point - bottom_intersection).integral_norm();

            if p.y < 0 {
                dist_left = min(dist_left, dl);
                dist_right = min(dist_right, dr);
            } else {
                dist_left = min(dist_left, dr);
                dist_right = min(dist_right, dl);
            }
        }

        // now go through all other segments
        for s in self.segments_iter() {
            if s != segment {
                if intersect(&p, &mid_point, &s.start, &s.end) {
                    if let Some((t, d)) = solve_intersection(&p, &mid_point, &s.start, &s.end) {
                        if t > 0 {
                            dist_left = min(d, dist_left);
                        } else {
                            dist_right = min(d, dist_right);
                        }
                    }
                }
            }
        }

        // go through all points, including fill points
        for pi in self.iter() {
            if *pi != segment.start && *pi != segment.end {
                if intersect(&p, &pi, &segment.start, &segment.end) {
                    // ray from segment.start
                    if let Some((t, d)) = solve_intersection(&p, &mid_point, &segment.start, &pi) {
                        if t > 0 {
                            dist_left = min(d, dist_left);
                        } else {
                            dist_right = min(d, dist_right);
                        }
                    }

                    // ray from segment.end
                    if let Some((t, d)) = solve_intersection(&p, &mid_point, &segment.end, &pi) {
                        if t > 0 {
                            dist_left = min(d, dist_left);
                        } else {
                            dist_right = min(d, dist_right);
                        }
                    }
                }
            }
        }

        let max_dist = p.integral_norm() * 100 / distance_divisor;
        dist_left = min(dist_left, max_dist);
        dist_right = min(dist_right, max_dist);

        if dist_right + dist_left < min_distance as u32 * 2 + 10 {
            // limits are too narrow, just divide
            Some(mid_point)
        } else {
            // select distance within [-dist_left; dist_right], keeping min_distance in mind
            let d = -(dist_left as i32)
                + min_distance
                + random_numbers.next().unwrap() as i32
                    % (dist_right as i32 + dist_left as i32 - min_distance * 2);

            Some(Point::new(
                mid_point.x + p.x * d / distance_divisor as i32,
                mid_point.y + p.y * d / distance_divisor as i32,
            ))
        }
    }

    fn divide_edges<I: Iterator<Item = u32>>(
        &mut self,
        distance_divisor: u32,
        random_numbers: &mut I,
    ) {
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

                if let Some(new_point) = self.divide_edge(segment, distance_divisor, random_numbers)
                {
                    self.islands[is].insert(i + 1, new_point);
                    i += 2;
                } else {
                    i += 1;
                }
            }
        }
    }

    pub fn bezierize(&mut self) {}

    pub fn distort<I: Iterator<Item = u32>>(
        &mut self,
        distance_divisor: u32,
        random_numbers: &mut I,
    ) {
        loop {
            let old_len = self.total_len();
            self.divide_edges(distance_divisor, random_numbers);

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
        let r = self.size.width as i32 - 1;

        self.iter_mut().for_each(|p| p.x = r - p.x);
    }

    pub fn flip(&mut self) {
        let t = self.size.height as i32 - 1;

        self.iter_mut().for_each(|p| p.y = t - p.y);
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
