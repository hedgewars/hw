use itertools::Itertools;
use std::cmp::min;

use integral_geometry::{Line, Ray, Point, Polygon, Rect, Size};
use land2d::Land2D;

use outline_template::OutlineTemplate;

pub struct OutlinePoints {
    pub islands: Vec<Polygon>,
    pub fill_points: Vec<Point>,
    pub size: Size,
    pub play_box: Rect,
    intersections_box: Rect,
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
                            play_box.top_left() + rect.quotient(rnd_a as usize, rnd_b as usize)
                        })
                        .collect::<Vec<_>>()
                        .into()
                })
                .collect(),
            fill_points: outline_template.fill_points.clone(),
            intersections_box: Rect::at_origin(size)
                .with_margin(size.to_square().width as i32 * -2),
        }
    }

    pub fn total_len(&self) -> usize {
        self.islands.iter().map(|i| i.edges_count()).sum::<usize>() + self.fill_points.len()
    }

    pub fn iter(&self) -> impl Iterator<Item = &Point> {
        self.islands
            .iter()
            .flat_map(|p| p.iter())
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
        fn intersects(ray: &Ray, edge: &Line) -> bool {
            ray.orientation(edge.start) != ray.orientation(edge.end)
        }

        #[inline]
        fn solve_intersection(
            intersections_box: &Rect,
            ray: &Ray,
            edge: &Line
        ) -> Option<(i32, u32)>
        {
            let edge_dir = edge.scaled_direction();
            let aqpb = ray.direction.cross(edge_dir) as i64;

            if aqpb != 0 {
                let mut iy =
                    ((((edge.start.x - ray.start.x) as i64 * ray.direction.y as i64
                        + ray.start.y as i64 * ray.direction.x as i64)
                    * edge_dir.y as i64
                    - edge.start.y as i64 * edge_dir.x as i64 * ray.direction.y as i64)
                    / aqpb) as i32;

                // is there better way to do it?
                if iy < intersections_box.top() {
                    iy = intersections_box.top();
                } else if iy > intersections_box.bottom() {
                    iy = intersections_box.bottom();
                }

                let ix = if ray.direction.y.abs() > edge_dir.y.abs() {
                    ray.start.x + ray.direction.cotangent_mul(iy - ray.start.y)
                } else {
                    edge.start.x + edge_dir.cotangent_mul(iy - edge.start.y)
                };

                let intersection_point = Point::new(ix, iy).clamp(intersections_box);
                let diff_point = ray.start - intersection_point;
                let t = ray.direction.dot(diff_point);

                if diff_point.max_norm() >= std::i16::MAX as i32 {
                    Some((t, std::i32::MAX as u32))
                } else {
                    let d = diff_point.integral_norm();

                    Some((t, d))
                }
            } else {
                None
            }
        }

        let min_distance = 40;
        // new point should fall inside this box
        let map_box = self.play_box.with_margin(min_distance);

        let normal = segment.scaled_normal();
        let normal_len = normal.integral_norm();
        let mid_point = segment.center();

        if (normal_len < min_distance as u32 * 3) || !map_box.contains_inside(mid_point) {
            return None;
        }

        let normal_ray = Ray::new(mid_point, normal);
        let mut dist_left = (self.size.width + self.size.height) as u32;
        let mut dist_right = dist_left;

        // find distances to map borders
        if normal.x != 0 {
            // where the normal line intersects the left map border
            let left_intersection = Point::new(
                map_box.left(),
                mid_point.y + normal.tangent_mul(map_box.left() - mid_point.x),
            );
            dist_left = (mid_point - left_intersection).integral_norm();

            // same for the right border
            let right_intersection = Point::new(
                map_box.right(),
                mid_point.y + normal.tangent_mul(map_box.right() - mid_point.x)  ,
            );
            dist_right = (mid_point - right_intersection).integral_norm();

            if normal.x > 0 {
                std::mem::swap(&mut dist_left, &mut dist_right);
            }
        }

        if normal.y != 0 {
            // where the normal line intersects the top map border
            let top_intersection = Point::new(
                mid_point.x + normal.cotangent_mul(map_box.top() - mid_point.y),
                map_box.top(),
            );
            let dl = (mid_point - top_intersection).integral_norm();

            // same for the bottom border
            let bottom_intersection = Point::new(
                mid_point.x + normal.cotangent_mul(map_box.bottom() - mid_point.y),
                map_box.bottom(),
            );
            let dr = (mid_point - bottom_intersection).integral_norm();

            if normal.y < 0 {
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
                if intersects(&normal_ray, &s) {
                    if let Some((t, d)) =
                        solve_intersection(&self.intersections_box, &normal_ray, &s)
                    {
                        if t > 0 {
                            dist_right = min(dist_right, d);
                        } else {
                            dist_left = min(dist_left, d);
                        }
                    }
                }
            }
        }

        // go through all points, including fill points
        for pi in self.iter().cloned() {
            if pi != segment.start && pi != segment.end {
                if intersects(&pi.ray_with_dir(normal), &segment) {
                    // ray from segment.start
                    if let Some((t, d)) = solve_intersection(
                        &self.intersections_box, &normal_ray, &segment.start.line_to(pi),
                    ) {
                        if t > 0 {
                            dist_right = min(dist_right, d);
                        } else {
                            dist_left = min(dist_left, d);
                        }
                    }

                    // ray from segment.end
                    if let Some((t, d)) = solve_intersection(
                        &self.intersections_box, &normal_ray, &segment.end.line_to(pi)
                    ) {
                        if t > 0 {
                            dist_right = min(dist_right, d);
                        } else {
                            dist_left = min(dist_left, d);
                        }
                    }
                }
            }
        }

        let max_dist = normal_len * 100 / distance_divisor;
        dist_left = min(dist_left, max_dist);
        dist_right = min(dist_right, max_dist);

        if dist_right + dist_left < min_distance as u32 * 2 + 10 {
            // limits are too narrow, just divide
            Some(mid_point)
        } else {
            // select distance within [-dist_right; dist_left], keeping min_distance in mind
            let d = -(dist_right as i32)
                + min_distance
                + random_numbers.next().unwrap() as i32
                    % (dist_right as i32 + dist_left as i32 - min_distance * 2);

            Some(mid_point + normal * d / normal_len as i32)
        }
    }

    fn divide_edges<I: Iterator<Item = u32>>(
        &mut self,
        distance_divisor: u32,
        random_numbers: &mut I,
    ) {
        for is in 0..self.islands.len() {
            let mut i = 0;
            while i < self.islands[is].edges_count() {
                let segment = self.islands[is].get_edge(i);
                if let Some(new_point) = self.divide_edge(segment, distance_divisor, random_numbers)
                {
                    self.islands[is].split_edge(i, new_point);
                    i += 2;
                } else {
                    i += 1;
                }
            }
        }
    }

    pub fn bezierize(&mut self, segments_number: u32) {
        for island in &mut self.islands {
            island.bezierize(segments_number);
        }
    }

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
    }

    pub fn draw<T: Copy + PartialEq>(&self, land: &mut Land2D<T>, value: T) {
        for segment in self.segments_iter() {
            land.draw_line(segment, value);
        }
    }

    fn segments_iter<'a>(&'a self) -> impl Iterator<Item = Line> + 'a {
        self.islands.iter().flat_map(|p| p.iter_edges())
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

#[test()]
fn points_test() {
    let size = Size::square(100);
    let mut points = OutlinePoints {
        islands: vec![
            Polygon::new(&[Point::new(0, 0), Point::new(20, 0), Point::new(30, 30)]),
            Polygon::new(&[Point::new(10, 15), Point::new(15, 20), Point::new(20, 15)]),
        ],
        fill_points: vec![Point::new(1, 1)],
        play_box: Rect::at_origin(size).with_margin(10),
        size: Size::square(100),
        intersections_box: Rect::at_origin(size),
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
    assert_eq!(points.islands[0].get_edge(0).start.x, 2);
}
