extern crate fpnum;

use fpnum::distance;
use std::cmp::max;
use std::ops::{Add, AddAssign, Div, DivAssign, Mul, MulAssign, RangeInclusive, Sub, SubAssign};

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
    pub fn fit(self, rect: &Rect) -> Point {
        let x = if self.x > rect.right() {
            rect.right()
        } else if self.x < rect.left() {
            rect.left()
        } else {
            self.x
        };
        let y = if self.y > rect.bottom() {
            rect.bottom()
        } else if self.y < rect.top() {
            rect.top()
        } else {
            self.y
        };

        Point::new(x, y)
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
    pub x: i32,
    pub y: i32,
    pub width: u32,
    pub height: u32,
}

impl Rect {
    #[inline]
    pub fn new(x: i32, y: i32, width: u32, height: u32) -> Self {
        Self {
            x,
            y,
            width,
            height,
        }
    }

    pub fn from_box(left: i32, right: i32, top: i32, bottom: i32) -> Self {
        assert!(left <= right);
        assert!(top <= bottom);

        Rect::new(left, top, (right - left) as u32, (bottom - top) as u32)
    }

    pub fn from_size(top_left: Point, size: Size) -> Self {
        Rect::new(
            top_left.x,
            top_left.y,
            size.width as u32,
            size.height as u32,
        )
    }

    pub fn at_origin(size: Size) -> Self {
        Rect::from_size(Point::zero(), size)
    }

    #[inline]
    pub fn size(&self) -> Size {
        Size::new(self.width as usize, self.height as usize)
    }

    #[inline]
    pub fn area(&self) -> usize {
        self.size().area()
    }

    #[inline]
    pub fn left(&self) -> i32 {
        self.x
    }

    #[inline]
    pub fn top(&self) -> i32 {
        self.y
    }

    #[inline]
    pub fn right(&self) -> i32 {
        self.x + self.width as i32
    }

    #[inline]
    pub fn bottom(&self) -> i32 {
        self.y + self.height as i32
    }

    #[inline]
    pub fn top_left(&self) -> Point {
        Point::new(self.x, self.y)
    }

    #[inline]
    pub fn bottom_right(&self) -> Point {
        Point::new(self.right(), self.bottom())
    }

    #[inline]
    pub fn center(&self) -> Point {
        (self.top_left() + self.bottom_right()) / 2
    }

    #[inline]
    pub fn with_margin(&self, margin: i32) -> Self {
        Rect::from_box(
            self.left() + margin,
            self.right() - margin,
            self.top() + margin,
            self.bottom() - margin,
        )
    }

    #[inline]
    pub fn x_range(&self) -> RangeInclusive<i32> {
        self.x..=self.x + self.width as i32
    }

    #[inline]
    pub fn y_range(&self) -> RangeInclusive<i32> {
        self.y..=self.y + self.height as i32
    }

    /* requires #[feature(range_contains)]
    #[inline]
    pub fn contains(&self, point: Point) -> bool {
        x_range().contains(point.x) && y_range.contains(point.y)
    }*/

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
            Rect::from_box(self.left(), point.x, self.top(), point.y),
            Rect::from_box(point.x, self.right(), self.top(), point.y),
            Rect::from_box(point.x, self.right(), point.y, self.bottom()),
            Rect::from_box(self.left(), point.x, point.y, self.bottom()),
        ]
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
        (&mut self.vertices[..edges_count]).iter_mut()
    }

    pub fn iter_edges<'a>(&'a self) -> impl Iterator<Item = Line> + 'a {
        (&self.vertices[0..self.edges_count()])
            .iter()
            .zip(&self.vertices[1..])
            .map(|(s, e)| Line::new(*s, *e))
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
    pub fn scaled_normal(&self) -> Point {
        (self.end - self.start).rotate90()
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

        assert_eq!(Point::new(0, -10).fit(&r), Point::new(10, 0));
        assert_eq!(Point::new(1000, 1000).fit(&r), Point::new(100, 70));
    }
}
