#[macro_use]
extern crate fpnum;

use fpnum::{distance, FPNum, FPPoint};
use std::{
    cmp::{max, min},
    ops::{Add, AddAssign, Div, DivAssign, Mul, MulAssign, Range, RangeInclusive, Sub, SubAssign},
};

#[derive(PartialEq, Eq, Clone, Copy, Debug)]
pub struct Point {
    pub x: i32,
    pub y: i32,
}

impl Point {
    #[inline]
    pub fn new(x: i32, y: i32) -> Self {
        Self { x, y }
    }

    #[inline]
    pub fn diag(v: i32) -> Self {
        Self::new(v, v)
    }

    #[inline]
    pub fn zero() -> Self {
        Self::new(0, 0)
    }

    #[inline]
    pub fn signum(self) -> Self {
        Self::new(self.x.signum(), self.y.signum())
    }

    #[inline]
    pub fn abs(self) -> Self {
        Self::new(self.x.abs(), self.y.abs())
    }

    #[inline]
    pub fn dot(self, other: Point) -> i32 {
        self.x * other.x + self.y * other.y
    }

    #[inline]
    pub fn max_norm(self) -> i32 {
        std::cmp::max(self.x.abs(), self.y.abs())
    }

    #[inline]
    pub fn integral_norm(self) -> u32 {
        distance(self.x, self.y).abs_round()
    }

    #[inline]
    pub fn transform(self, matrix: &[i32; 4]) -> Self {
        Point::new(
            matrix[0] * self.x + matrix[1] * self.y,
            matrix[2] * self.x + matrix[3] * self.y,
        )
    }

    #[inline]
    pub fn rotate90(self) -> Self {
        Point::new(self.y, -self.x)
    }

    #[inline]
    pub fn cross(self, other: Point) -> i32 {
        self.dot(other.rotate90())
    }

    #[inline]
    pub fn clamp(self, rect: &Rect) -> Point {
        Point::new(rect.x_range().clamp(self.x), rect.y_range().clamp(self.y))
    }

    #[inline]
    pub fn line_to(self, end: Point) -> Line {
        Line::new(self, end)
    }

    #[inline]
    pub fn ray_to(self, end: Point) -> Ray {
        self.line_to(end).to_ray()
    }

    #[inline]
    pub fn tangent(self) -> i32 {
        self.y / self.x
    }

    #[inline]
    pub fn cotangent(self) -> i32 {
        self.x / self.y
    }

    #[inline]
    pub fn to_fppoint(&self) -> FPPoint {
        FPPoint::new(self.x.into(), self.y.into())
    }
}

#[derive(PartialEq, Eq, Clone, Copy, Debug)]
pub struct Size {
    pub width: usize,
    pub height: usize,
}

impl Size {
    #[inline]
    pub fn new(width: usize, height: usize) -> Self {
        Size { width, height }
    }

    #[inline]
    pub fn square(size: usize) -> Self {
        Size {
            width: size,
            height: size,
        }
    }

    #[inline]
    pub fn area(&self) -> usize {
        self.width * self.height
    }

    #[inline]
    pub fn linear_index(&self, x: usize, y: usize) -> usize {
        y * self.width + x
    }

    #[inline]
    pub fn is_power_of_two(&self) -> bool {
        self.width.is_power_of_two() && self.height.is_power_of_two()
    }

    #[inline]
    pub fn next_power_of_two(&self) -> Self {
        Self {
            width: self.width.next_power_of_two(),
            height: self.height.next_power_of_two(),
        }
    }

    #[inline]
    pub fn to_mask(&self) -> SizeMask {
        SizeMask::new(*self)
    }

    #[inline]
    pub fn to_square(&self) -> Size {
        Size::square(max(self.width, self.height))
    }

    pub fn to_grid_index(&self) -> GridIndex {
        GridIndex::new(*self)
    }
}

pub struct SizeMask {
    size: Size,
}

impl SizeMask {
    #[inline]
    pub fn new(size: Size) -> Self {
        assert!(size.is_power_of_two());
        let size = Size {
            width: !(size.width - 1),
            height: !(size.height - 1),
        };
        Self { size }
    }

    #[inline]
    pub fn contains_x<T: Into<usize>>(&self, x: T) -> bool {
        (self.size.width & x.into()) == 0
    }

    #[inline]
    pub fn contains_y<T: Into<usize>>(&self, y: T) -> bool {
        (self.size.height & y.into()) == 0
    }

    #[inline]
    pub fn contains(&self, point: Point) -> bool {
        self.contains_x(point.x as usize) && self.contains_y(point.y as usize)
    }
}

pub struct GridIndex {
    shift: Point,
}

impl GridIndex {
    pub fn new(size: Size) -> Self {
        assert!(size.is_power_of_two());
        let shift = Point::new(
            size.width.trailing_zeros() as i32,
            size.height.trailing_zeros() as i32,
        );
        Self { shift }
    }

    pub fn map(&self, position: Point) -> Point {
        Point::new(position.x >> self.shift.x, position.y >> self.shift.y)
    }
}

macro_rules! bin_op_impl {
    ($op: ty, $name: tt) => {
        impl $op for Point {
            type Output = Self;

            #[inline]
            fn $name(self, rhs: Self) -> Self::Output {
                Self::new(self.x.$name(rhs.x), self.y.$name(rhs.y))
            }
        }
    };
}

macro_rules! scalar_bin_op_impl {
    ($($op: tt)::+, $name: tt) => {
        impl $($op)::+<i32> for Point {
            type Output = Self;

            #[inline]
            fn $name(self, rhs: i32) -> Self::Output {
                Self::new(self.x.$name(rhs), self.y.$name(rhs))
            }
        }
    };
}

macro_rules! bin_assign_op_impl {
    ($op: ty, $name: tt) => {
        impl $op for Point {
            #[inline]
            fn $name(&mut self, rhs: Self) {
                self.x.$name(rhs.x);
                self.y.$name(rhs.y);
            }
        }
    };
}

bin_op_impl!(Add, add);
bin_op_impl!(Sub, sub);
bin_op_impl!(Mul, mul);
bin_op_impl!(Div, div);
scalar_bin_op_impl!(Mul, mul);
scalar_bin_op_impl!(Div, div);
bin_assign_op_impl!(AddAssign, add_assign);
bin_assign_op_impl!(SubAssign, sub_assign);
bin_assign_op_impl!(MulAssign, mul_assign);
bin_assign_op_impl!(DivAssign, div_assign);

#[derive(PartialEq, Eq, Clone, Copy, Debug)]
pub struct Rect {
    top_left: Point,
    bottom_right: Point,
}

impl Rect {
    #[inline]
    pub fn new(top_left: Point, bottom_right: Point) -> Self {
        assert!(top_left.x <= bottom_right.x + 1);
        assert!(top_left.y <= bottom_right.y + 1);
        Self {
            top_left,
            bottom_right,
        }
    }

    pub fn from_box(left: i32, right: i32, top: i32, bottom: i32) -> Self {
        Self::new(Point::new(left, top), Point::new(right, bottom))
    }

    pub fn from_size(top_left: Point, size: Size) -> Self {
        Self::new(
            top_left,
            top_left + Point::new(size.width as i32 - 1, size.height as i32 - 1),
        )
    }

    pub fn from_size_coords(x: i32, y: i32, width: usize, height: usize) -> Self {
        Self::from_size(Point::new(x, y), Size::new(width, height))
    }

    pub fn at_origin(size: Size) -> Self {
        Self::from_size(Point::zero(), size)
    }

    #[inline]
    pub fn width(&self) -> usize {
        (self.right() - self.left() + 1) as usize
    }

    #[inline]
    pub fn height(&self) -> usize {
        (self.right() - self.left() + 1) as usize
    }

    #[inline]
    pub fn size(&self) -> Size {
        Size::new(self.width(), self.height())
    }

    #[inline]
    pub fn area(&self) -> usize {
        self.size().area()
    }

    #[inline]
    pub fn left(&self) -> i32 {
        self.top_left().x
    }

    #[inline]
    pub fn top(&self) -> i32 {
        self.top_left().y
    }

    #[inline]
    pub fn right(&self) -> i32 {
        self.bottom_right().x
    }

    #[inline]
    pub fn bottom(&self) -> i32 {
        self.bottom_right().y
    }

    #[inline]
    pub fn top_left(&self) -> Point {
        self.top_left
    }

    #[inline]
    pub fn bottom_right(&self) -> Point {
        self.bottom_right
    }

    #[inline]
    pub fn center(&self) -> Point {
        (self.top_left() + self.bottom_right()) / 2
    }

    #[inline]
    pub fn with_margin(&self, margin: i32) -> Self {
        let offset = Point::diag(margin);
        Self::new(self.top_left() + offset, self.bottom_right() - offset)
    }

    #[inline]
    pub fn x_range(&self) -> RangeInclusive<i32> {
        self.left()..=self.right()
    }

    #[inline]
    pub fn y_range(&self) -> RangeInclusive<i32> {
        self.top()..=self.bottom()
    }

    #[inline]
    pub fn contains(&self, point: Point) -> bool {
        self.x_range().contains(point.x) && self.y_range().contains(point.y)
    }

    #[inline]
    pub fn contains_inside(&self, point: Point) -> bool {
        point.x > self.left()
            && point.x < self.right()
            && point.y > self.top()
            && point.y < self.bottom()
    }

    #[inline]
    pub fn intersects(&self, other: &Rect) -> bool {
        self.left() <= self.right()
            && self.right() >= other.left()
            && self.top() <= other.bottom()
            && self.bottom() >= other.top()
    }

    #[inline]
    pub fn split_at(&self, point: Point) -> [Rect; 4] {
        assert!(self.contains_inside(point));
        [
            Self::from_box(self.left(), point.x, self.top(), point.y),
            Self::from_box(point.x, self.right(), self.top(), point.y),
            Self::from_box(point.x, self.right(), point.y, self.bottom()),
            Self::from_box(self.left(), point.x, point.y, self.bottom()),
        ]
    }

    #[inline]
    pub fn quotient(self, x: usize, y: usize) -> Point {
        self.top_left() + Point::new((x % self.width()) as i32, (y % self.height()) as i32)
    }
}

trait RangeContains<T> {
    fn contains(&self, value: T) -> bool;
}

impl<T: Ord> RangeContains<T> for Range<T> {
    fn contains(&self, value: T) -> bool {
        value >= self.start && value < self.end
    }
}

impl<T: Ord> RangeContains<T> for RangeInclusive<T> {
    fn contains(&self, value: T) -> bool {
        value >= *self.start() && value <= *self.end()
    }
}

trait RangeClamp<T> {
    fn clamp(&self, value: T) -> T;
}

impl<T: Ord + Copy> RangeClamp<T> for RangeInclusive<T> {
    fn clamp(&self, value: T) -> T {
        if value < *self.start() {
            *self.start()
        } else if value > *self.end() {
            *self.end()
        } else {
            value
        }
    }
}

pub struct Polygon {
    vertices: Vec<Point>,
}

impl Polygon {
    pub fn new(vertices: &[Point]) -> Self {
        let mut v = Vec::with_capacity(vertices.len() + 1);
        v.extend_from_slice(vertices);
        if !v.is_empty() {
            let start = v[0];
            v.push(start);
        }
        Self { vertices: v }
    }

    pub fn edges_count(&self) -> usize {
        self.vertices.len() - 1
    }

    pub fn get_edge(&self, index: usize) -> Line {
        Line::new(self.vertices[index], self.vertices[index + 1])
    }

    pub fn split_edge(&mut self, edge_index: usize, vertex: Point) {
        self.vertices.insert(edge_index + 1, vertex);
    }

    pub fn iter<'a>(&'a self) -> impl Iterator<Item = &Point> + 'a {
        (&self.vertices[..self.edges_count()]).iter()
    }

    pub fn iter_mut<'a>(&'a mut self) -> impl Iterator<Item = &mut Point> + 'a {
        let edges_count = self.edges_count();
        let start = self.vertices.as_mut_ptr();
        let end = unsafe { start.add(self.vertices.len()) };
        PolygonPointsIteratorMut {
            source: self,
            start,
            end,
        }
    }

    fn force_close(&mut self) {
        if !self.vertices.is_empty() {
            self.vertices[0] = self.vertices[self.vertices.len() - 1];
        }
    }

    pub fn iter_edges<'a>(&'a self) -> impl Iterator<Item = Line> + 'a {
        (&self.vertices[0..self.edges_count()])
            .iter()
            .zip(&self.vertices[1..])
            .map(|(s, e)| Line::new(*s, *e))
    }

    pub fn bezierize(&mut self, segments_number: u32) {
        fn calc_point(p1: Point, p2: Point, p3: Point) -> FPPoint {
            let diff13 = (p1 - p3).to_fppoint();
            let diff13_norm = diff13.distance();

            if diff13_norm.is_zero() {
                diff13
            } else {
                let diff12_norm = (p1 - p2).to_fppoint().distance();
                let diff23_norm = (p2 - p3).to_fppoint().distance();
                let min_distance = min(diff13_norm, min(diff12_norm, diff23_norm));

                diff13 * min_distance / diff13_norm / 3
            }
        }

        if self.vertices.len() < 4 {
            return;
        }

        let delta = fp!(1 / segments_number);
        let mut bezierized_vertices = Vec::new();
        let mut pi = 0;
        let mut i = 1;
        let mut ni = 2;
        let mut right_point = calc_point(self.vertices[pi], self.vertices[i], self.vertices[ni]);
        let mut left_point;

        pi += 1;
        while pi != 0 {
            pi = i;
            i = ni;
            ni += 1;
            if ni >= self.vertices.len() {
                ni = 0;
            }

            left_point = right_point;
            right_point = calc_point(self.vertices[pi], self.vertices[i], self.vertices[ni]);

            bezierized_vertices.extend(BezierCurveSegments::new(
                Line::new(self.vertices[pi], self.vertices[i]),
                left_point,
                -right_point,
                delta,
            ));
        }

        self.vertices = bezierized_vertices;
    }
}

struct PolygonPointsIteratorMut<'a> {
    source: &'a mut Polygon,
    start: *mut Point,
    end: *mut Point,
}

impl<'a> Iterator for PolygonPointsIteratorMut<'a> {
    type Item = &'a mut Point;

    fn next(&mut self) -> Option<<Self as Iterator>::Item> {
        if self.start == self.end {
            None
        } else {
            unsafe {
                let result = &mut *self.start;
                self.start = self.start.add(1);
                Some(result)
            }
        }
    }
}

impl<'a> Drop for PolygonPointsIteratorMut<'a> {
    fn drop(&mut self) {
        self.source.force_close();
    }
}

impl From<Vec<Point>> for Polygon {
    fn from(mut v: Vec<Point>) -> Self {
        if !v.is_empty() && v[0] != v[v.len() - 1] {
            let start = v[0];
            v.push(start)
        }
        Self { vertices: v }
    }
}

#[derive(PartialEq, Eq, Clone, Copy, Debug)]
pub struct Ray {
    pub start: Point,
    pub direction: Point,
}

impl Ray {
    #[inline]
    pub fn new(start: Point, direction: Point) -> Ray {
        Self { start, direction }
    }

    #[inline]
    pub fn tangent(&self) -> i32 {
        self.direction.tangent()
    }

    #[inline]
    pub fn cotangent(&self) -> i32 {
        self.direction.cotangent()
    }

    #[inline]
    pub fn orientation(&self, point: Point) -> i32 {
        (point - self.start).cross(self.direction).signum()
    }
}

#[derive(PartialEq, Eq, Clone, Copy, Debug)]
pub struct Line {
    pub start: Point,
    pub end: Point,
}

impl Line {
    #[inline]
    pub fn new(start: Point, end: Point) -> Self {
        Self { start, end }
    }

    #[inline]
    pub fn zero() -> Self {
        Self::new(Point::zero(), Point::zero())
    }

    #[inline]
    pub fn center(&self) -> Point {
        (self.start + self.end) / 2
    }

    #[inline]
    pub fn scaled_direction(&self) -> Point {
        self.end - self.start
    }

    #[inline]
    pub fn scaled_normal(&self) -> Point {
        self.scaled_direction().rotate90()
    }

    #[inline]
    pub fn to_ray(&self) -> Ray {
        Ray::new(self.start, self.scaled_direction())
    }
}

impl IntoIterator for Line {
    type Item = Point;
    type IntoIter = LinePoints;

    fn into_iter(self) -> Self::IntoIter {
        LinePoints::new(self)
    }
}

pub struct LinePoints {
    accumulator: Point,
    direction: Point,
    sign: Point,
    current: Point,
    total_steps: i32,
    step: i32,
}

impl LinePoints {
    pub fn new(line: Line) -> Self {
        let dir = line.end - line.start;

        Self {
            accumulator: Point::zero(),
            direction: dir.abs(),
            sign: dir.signum(),
            current: line.start,
            total_steps: dir.max_norm(),
            step: 0,
        }
    }
}

impl Iterator for LinePoints {
    type Item = Point;

    fn next(&mut self) -> Option<Self::Item> {
        if self.step <= self.total_steps {
            self.accumulator += self.direction;

            if self.accumulator.x > self.total_steps {
                self.accumulator.x -= self.total_steps;
                self.current.x += self.sign.x;
            }
            if self.accumulator.y > self.total_steps {
                self.accumulator.y -= self.total_steps;
                self.current.y += self.sign.y;
            }

            self.step += 1;

            Some(self.current)
        } else {
            None
        }
    }
}

pub struct ArcPoints {
    point: Point,
    step: i32,
}

impl ArcPoints {
    pub fn new(radius: i32) -> Self {
        Self {
            point: Point::new(0, radius),
            step: 3 - 2 * radius,
        }
    }
}

impl Iterator for ArcPoints {
    type Item = Point;

    fn next(&mut self) -> Option<Self::Item> {
        if self.point.x < self.point.y {
            let result = self.point;

            if self.step < 0 {
                self.step += self.point.x * 4 + 6;
            } else {
                self.step += (self.point.x - self.point.y) * 4 + 10;
                self.point.y -= 1;
            }

            self.point.x += 1;

            Some(result)
        } else if self.point.x == self.point.y {
            self.point.x += 1;

            Some(self.point)
        } else {
            None
        }
    }
}

pub struct EquidistantPoints {
    vector: Point,
    iteration: u8,
}

impl EquidistantPoints {
    pub fn new(vector: Point) -> Self {
        Self {
            vector,
            iteration: if vector.x == vector.y { 4 } else { 8 },
        }
    }
}

impl Iterator for EquidistantPoints {
    type Item = Point;

    fn next(&mut self) -> Option<Self::Item> {
        if self.iteration > 0 {
            self.vector.x = -self.vector.x;
            if self.iteration & 1 == 0 {
                self.vector.y = -self.vector.y;
            }

            if self.iteration == 4 {
                std::mem::swap(&mut self.vector.x, &mut self.vector.y);
            }

            self.iteration -= 1;

            Some(self.vector)
        } else {
            None
        }
    }
}

pub struct BezierCurveSegments {
    segment: Line,
    c1: FPPoint,
    c2: FPPoint,
    offset: FPNum,
    max_offset: FPNum,
    delta: FPNum,
    have_finished: bool,
}

impl BezierCurveSegments {
    pub fn new(segment: Line, p1: FPPoint, p2: FPPoint, delta: FPNum) -> Self {
        Self {
            segment,
            c1: segment.start.to_fppoint() - p1,
            c2: segment.end.to_fppoint() - p2,
            offset: fp!(0),
            max_offset: fp!(4095 / 4096),
            delta,
            have_finished: false,
        }
    }
}

impl Iterator for BezierCurveSegments {
    type Item = Point;

    fn next(&mut self) -> Option<Self::Item> {
        if self.offset < self.max_offset {
            let offset_sq = self.offset * self.offset;
            let offset_cub = offset_sq * self.offset;

            let r1 = fp!(1) - self.offset * 3 + offset_sq * 3 - offset_cub;
            let r2 = self.offset * 3 - offset_sq * 6 + offset_cub * 3;
            let r3 = offset_sq * 3 - offset_cub * 3;

            let x = r1 * self.segment.start.x
                + r2 * self.c1.x()
                + r3 * self.c2.x()
                + offset_cub * self.segment.end.x;
            let y = r1 * self.segment.start.y
                + r2 * self.c1.y()
                + r3 * self.c2.y()
                + offset_cub * self.segment.end.y;

            self.offset += self.delta;

            Some(Point::new(x.round(), y.round()))
        } else if !self.have_finished {
            self.have_finished = true;

            Some(self.segment.end)
        } else {
            None
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn get_points(coords: &[(i32, i32)]) -> Vec<Point> {
        coords.iter().map(|(x, y)| Point::new(*x, *y)).collect()
    }

    #[test]
    fn line_basic() {
        let line: Vec<Point> = Line::new(Point::new(0, 0), Point::new(3, 3))
            .into_iter()
            .collect();
        let v = get_points(&[(0, 0), (1, 1), (2, 2), (3, 3)]);

        assert_eq!(line, v);
    }

    #[test]
    fn line_skewed() {
        let line: Vec<Point> = Line::new(Point::new(0, 0), Point::new(5, -7))
            .into_iter()
            .collect();
        let v = get_points(&[
            (0, 0),
            (1, -1),
            (2, -2),
            (2, -3),
            (3, -4),
            (4, -5),
            (4, -6),
            (5, -7),
        ]);

        assert_eq!(line, v);
    }

    #[test]
    fn equidistant_full() {
        let n: Vec<Point> = EquidistantPoints::new(Point::new(1, 3)).collect();
        let v = get_points(&[
            (-1, -3),
            (1, -3),
            (-1, 3),
            (1, 3),
            (-3, -1),
            (3, -1),
            (-3, 1),
            (3, 1),
        ]);

        assert_eq!(n, v);
    }

    #[test]
    fn equidistant_half() {
        let n: Vec<Point> = EquidistantPoints::new(Point::new(2, 2)).collect();
        let v = get_points(&[(-2, -2), (2, -2), (-2, 2), (2, 2)]);

        assert_eq!(n, v);
    }

    #[test]
    fn line() {
        let l = Line::new(Point::new(1, 1), Point::new(5, 6));

        assert_eq!(l.center(), Point::new(3, 3));
    }

    #[test]
    fn rect() {
        let r = Rect::from_box(10, 100, 0, 70);

        assert!(r.contains_inside(Point::new(99, 69)));
        assert!(!r.contains_inside(Point::new(100, 70)));

        assert_eq!(r.top_left(), Point::new(10, 0));
        assert_eq!(r.with_margin(12), Rect::from_box(22, 88, 12, 58));
    }

    #[test]
    fn fit() {
        let r = Rect::from_box(10, 100, 0, 70);

        assert_eq!(Point::new(0, -10).clamp(&r), Point::new(10, 0));
        assert_eq!(Point::new(1000, 1000).clamp(&r), Point::new(100, 70));
    }
}
