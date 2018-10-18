use std::cmp;
use std::ops::{Add, Sub, Mul, Div, AddAssign, SubAssign, MulAssign, DivAssign};

#[derive(PartialEq, Eq, Clone, Copy, Debug)]
pub struct Point {
    pub x: i32,
    pub y: i32,
}

impl Point {
    #[inline]
    pub fn new(x: i32, y: i32) -> Self {
        Self {x, y}
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
}

macro_rules! bin_op_impl {
    ($op: ty, $name: tt) => {
        impl $op for Point {
            type Output = Self;

            #[inline]
            fn $name(self, rhs: Self) -> Self::Output {
                Self::new(self.x.$name(rhs.x),
                          self.y.$name(rhs.y))
            }
        }
    }
}

macro_rules! bin_assign_op_impl {
    ($op: ty, $name: tt) => {
        impl $op for Point {
            #[inline]
            fn $name(&mut self, rhs: Self){
                self.x.$name(rhs.x);
                self.y.$name(rhs.y);
            }
        }
    }
}

bin_op_impl!(Add, add);
bin_op_impl!(Sub, sub);
bin_op_impl!(Mul, mul);
bin_op_impl!(Div, div);
bin_assign_op_impl!(AddAssign, add_assign);
bin_assign_op_impl!(SubAssign, sub_assign);
bin_assign_op_impl!(MulAssign, mul_assign);
bin_assign_op_impl!(DivAssign, div_assign);

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

#[cfg(test)]
mod tests {
    use super::*;

    fn get_points(coords: &[(i32, i32)]) -> Vec<Point> {
        coords.iter().map(|(x, y)| Point::new(*x, *y)).collect()
    }

    #[test]
    fn basic() {
        let line = LinePoints::new(Point::new(0, 0), Point::new(3, 3));
        let v = get_points(&[(0, 0), (1, 1), (2, 2), (3, 3), (123, 456)]);

        for (&a, b) in v.iter().zip(line) {
            assert_eq!(a, b);
        }
    }

    #[test]
    fn skewed() {
        let line = LinePoints::new(Point::new(0, 0), Point::new(5, -7));
        let v = get_points(&[(0, 0), (1, -1), (2, -2), (2, -3), (3, -4), (4, -5), (4, -6), (5, -7)]);

        for (&a, b) in v.iter().zip(line) {
            assert_eq!(a, b);
        }
    }
}
