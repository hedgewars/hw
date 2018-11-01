use std::cmp;
use std::ops::{Add, AddAssign, Div, DivAssign, Mul, MulAssign, Sub, SubAssign};

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
    pub fn transform(self, matrix: &[i32; 4]) -> Self {
        Point::new(matrix[0] * self.x + matrix[1] * self.y,
                   matrix[2] * self.x + matrix[3] * self.y)
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
        Size { width: size, height: size }
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
            height: self.height.next_power_of_two()
        }
    }

    #[inline]
    pub fn to_mask(&self) -> SizeMask {
        SizeMask::new(*self)
    }

    pub fn to_grid_index(&self) -> GridIndex {
        GridIndex::new(*self)
    }
}

pub struct SizeMask{ size: Size }

impl SizeMask {
    #[inline]
    pub fn new(size: Size) -> Self {
        assert!(size.is_power_of_two());
        let size = Size {
            width: !(size.width - 1),
            height: !(size.height - 1)
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

pub struct GridIndex{ shift: Point }

impl GridIndex {
    pub fn new(size: Size) -> Self {
        assert!(size.is_power_of_two());
        let shift = Point::new(size.width.trailing_zeros() as i32,
                               size.height.trailing_zeros() as i32);
        Self { shift }
    }

    pub fn map(&self, position: Point) -> Point {
        Point::new(position.x >> self.shift.x,
                   position.y >> self.shift.y)
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
        Self { x, y, width, height }
    }

    #[inline]
    pub fn size(&self) -> Size {
        Size::new(self.width as usize, self.height as usize)
    }

    #[inline]
    pub fn area(&self) -> usize {
        self.size().area()
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
    pub fn new(from: Point, to: Point) -> Self {
        let dir = to - from;

        Self {
            accumulator: Point::zero(),
            direction: dir.abs(),
            sign: dir.signum(),
            current: from,
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
        let line = LinePoints::new(Point::new(0, 0), Point::new(3, 3));
        let v = get_points(&[(0, 0), (1, 1), (2, 2), (3, 3), (123, 456)]);

        for (&a, b) in v.iter().zip(line) {
            assert_eq!(a, b);
        }
    }

    #[test]
    fn line_skewed() {
        let line = LinePoints::new(Point::new(0, 0), Point::new(5, -7));
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

        for (&a, b) in v.iter().zip(line) {
            assert_eq!(a, b);
        }
    }

    #[test]
    fn equidistant_full() {
        let n = EquidistantPoints::new(Point::new(1, 3));
        let v = get_points(&[
            (-1, -3),
            (1, -3),
            (-1, 3),
            (1, 3),
            (-3, -1),
            (3, -1),
            (-3, 1),
            (3, 1),
            (123, 456),
        ]);

        for (&a, b) in v.iter().zip(n) {
            assert_eq!(a, b);
        }
    }

    #[test]
    fn equidistant_half() {
        let n = EquidistantPoints::new(Point::new(2, 2));
        let v = get_points(&[(-2, -2), (2, -2), (-2, 2), (2, 2), (123, 456)]);

        for (&a, b) in v.iter().zip(n) {
            assert_eq!(a, b);
        }
    }
}
