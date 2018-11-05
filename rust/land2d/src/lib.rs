extern crate integral_geometry;
extern crate vec2d;

use std::cmp;

use integral_geometry::{ArcPoints, EquidistantPoints, Line, Point, Rect, Size, SizeMask};

pub struct Land2D<T> {
    pixels: vec2d::Vec2D<T>,
    play_box: Rect,
    mask: SizeMask,
}

impl<T: Copy + PartialEq> Land2D<T> {
    pub fn new(play_size: Size, fill_value: T) -> Self {
        let real_size = play_size.next_power_of_two();
        let top_left = Point::new(
            ((real_size.width - play_size.width) / 2) as i32,
            (real_size.height - play_size.height) as i32,
        );
        let play_box = Rect::from_size(top_left, play_size);
        Self {
            play_box,
            pixels: vec2d::Vec2D::new(real_size, fill_value),
            mask: real_size.to_mask(),
        }
    }

    pub fn raw_pixels(&self) -> &[T] {
        &self.pixels.raw_data()
    }

    #[inline]
    pub fn width(&self) -> usize {
        self.pixels.width()
    }

    #[inline]
    pub fn height(&self) -> usize {
        self.pixels.height()
    }

    #[inline]
    pub fn size(&self) -> Size {
        self.pixels.size()
    }

    #[inline]
    pub fn play_width(&self) -> usize {
        self.play_box.width()
    }

    #[inline]
    pub fn play_height(&self) -> usize {
        self.play_box.height()
    }

    #[inline]
    pub fn play_size(&self) -> Size {
        self.play_box.size()
    }

    #[inline]
    pub fn play_box(&self) -> Rect {
        self.play_box
    }

    #[inline]
    pub fn is_valid_x(&self, x: i32) -> bool {
        self.mask.contains_x(x as usize)
    }

    #[inline]
    pub fn is_valid_y(&self, y: i32) -> bool {
        self.mask.contains_y(y as usize)
    }

    #[inline]
    pub fn is_valid_coordinate(&self, x: i32, y: i32) -> bool {
        self.is_valid_x(x) && self.is_valid_y(y)
    }

    #[inline]
    pub fn rows(&self) -> impl Iterator<Item = &[T]> {
        self.pixels.rows()
    }

    #[inline]
    pub fn map<U: Default, F: FnOnce(&mut T) -> U>(&mut self, y: i32, x: i32, f: F) -> U {
        if self.is_valid_coordinate(x, y) {
            unsafe {
                // hey, I just checked that coordinates are valid!
                f(self.pixels.get_unchecked_mut(y as usize, x as usize))
            }
        } else {
            U::default()
        }
    }

    #[inline]
    pub fn map_point<U: Default, F: FnOnce(&mut T) -> U>(&mut self, point: Point, f: F) -> U {
        self.map(point.y, point.x, f)
    }

    pub fn fill_from_iter<I>(&mut self, i: I, value: T) -> usize
    where
        I: std::iter::Iterator<Item = Point>,
    {
        i.map(|p| {
            self.map(p.y, p.x, |v| {
                *v = value;
                1
            })
        }).count()
    }

    pub fn draw_line(&mut self, line: Line, value: T) -> usize {
        self.fill_from_iter(line.into_iter(), value)
    }

    pub fn fill(&mut self, start_point: Point, border_value: T, fill_value: T) {
        debug_assert!(self.is_valid_coordinate(start_point.x - 1, start_point.y));
        debug_assert!(self.is_valid_coordinate(start_point.x, start_point.y));

        let mut stack: Vec<(usize, usize, usize, isize)> = Vec::new();
        fn push<T: Copy + PartialEq>(
            land: &Land2D<T>,
            stack: &mut Vec<(usize, usize, usize, isize)>,
            xl: usize,
            xr: usize,
            y: usize,
            dir: isize,
        ) {
            let yd = y as isize + dir;

            if land.is_valid_y(yd as i32) {
                stack.push((xl, xr, yd as usize, dir));
            }
        };

        let start_x_l = (start_point.x - 1) as usize;
        let start_x_r = start_point.x as usize;
        push(
            self,
            &mut stack,
            start_x_l,
            start_x_r,
            start_point.y as usize,
            -1,
        );
        push(
            self,
            &mut stack,
            start_x_l,
            start_x_r,
            start_point.y as usize,
            1,
        );

        while let Some(a) = stack.pop() {
            let (mut xl, mut xr, y, mut dir) = a;

            while xl > 0 && self
                .pixels
                .get(y, xl)
                .map_or(false, |v| *v != border_value && *v != fill_value)
            {
                xl -= 1;
            }

            while xr < self.width() - 1 && self
                .pixels
                .get(y, xr)
                .map_or(false, |v| *v != border_value && *v != fill_value)
            {
                xr += 1;
            }

            while xl < xr {
                while xl <= xr
                    && (self.pixels[y][xl] == border_value || self.pixels[y][xl] == fill_value)
                {
                    xl += 1;
                }

                let mut x = xl;

                while xl <= xr
                    && (self.pixels[y][xl] != border_value && self.pixels[y][xl] != fill_value)
                {
                    self.pixels[y][xl] = fill_value;

                    xl += 1;
                }

                if x < xl {
                    push(self, &mut stack, x, xl - 1, y, dir);
                    push(self, &mut stack, x, xl - 1, y, -dir);
                }
            }
        }
    }

    #[inline]
    fn fill_circle_line<F: Fn(&mut T) -> usize>(
        &mut self,
        y: i32,
        x_from: i32,
        x_to: i32,
        f: &F,
    ) -> usize {
        let mut result = 0;

        if self.is_valid_y(y) {
            for i in cmp::min(x_from, 0) as usize..cmp::max(x_to as usize, self.width() - 1) {
                unsafe {
                    // coordinates are valid at this point
                    result += f(self.pixels.get_unchecked_mut(y as usize, i));
                }
            }
        }

        result
    }

    #[inline]
    fn fill_circle_lines<F: Fn(&mut T) -> usize>(
        &mut self,
        x: i32,
        y: i32,
        dx: i32,
        dy: i32,
        f: &F,
    ) -> usize {
        self.fill_circle_line(y + dy, x - dx, x + dx, f)
            + self.fill_circle_line(y - dy, x - dx, x + dx, f)
            + self.fill_circle_line(y + dx, x - dy, x + dy, f)
            + self.fill_circle_line(y - dx, x - dy, x + dy, f)
    }

    pub fn change_round<F: Fn(&mut T) -> usize>(
        &mut self,
        x: i32,
        y: i32,
        radius: i32,
        f: F,
    ) -> usize {
        ArcPoints::new(radius)
            .map(&mut |p: Point| self.fill_circle_lines(x, y, p.x, p.y, &f))
            .sum()
    }

    fn fill_row(&mut self, center: Point, offset: Point, value: T) -> usize {
        let row_index = center.y + offset.y;
        if self.is_valid_y(row_index) {
            let from_x = cmp::max(0, center.x - offset.x) as usize;
            let to_x = cmp::min(self.width() - 1, (center.x + offset.x) as usize);
            self.pixels[row_index as usize][from_x..=to_x]
                .iter_mut()
                .for_each(|v| *v = value);
            to_x - from_x + 1
        } else {
            0
        }
    }

    pub fn fill_circle(&mut self, center: Point, radius: i32, value: T) -> usize {
        let transforms = [[0, 1, 1, 0], [0, 1, -1, 0], [1, 0, 0, 1], [1, 0, 0, -1]];
        ArcPoints::new(radius)
            .map(|vector| {
                transforms
                    .iter()
                    .map(|m| self.fill_row(center, vector.transform(m), value))
                    .sum::<usize>()
            }).sum()
    }

    pub fn draw_thick_line(&mut self, line: Line, radius: i32, value: T) -> usize {
        let mut result = 0;

        for vector in ArcPoints::new(radius) {
            for delta in EquidistantPoints::new(vector) {
                for point in line.into_iter() {
                    self.map_point(point + delta, |p| {
                        if *p != value {
                            *p = value;
                            result += 1;
                        }
                    })
                }
            }
        }

        result
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn basics() {
        let l: Land2D<u8> = Land2D::new(Size::new(30, 50), 0);

        assert_eq!(l.play_width(), 30);
        assert_eq!(l.play_height(), 50);
        assert_eq!(l.width(), 32);
        assert_eq!(l.height(), 64);

        assert!(l.is_valid_coordinate(0, 0));
        assert!(!l.is_valid_coordinate(-1, -1));

        assert!(l.is_valid_coordinate(31, 63));
        assert!(!l.is_valid_coordinate(32, 63));
        assert!(!l.is_valid_coordinate(31, 64));
    }

    #[test]
    fn fill() {
        let mut l: Land2D<u8> = Land2D::new(Size::square(128), 0);

        l.draw_line(Line::new(Point::new(0, 0), Point::new(32, 96)), 1);
        l.draw_line(Line::new(Point::new(32, 96), Point::new(64, 32)), 1);
        l.draw_line(Line::new(Point::new(64, 32), Point::new(96, 80)), 1);
        l.draw_line(Line::new(Point::new(96, 80), Point::new(128, 0)), 1);

        l.draw_line(Line::new(Point::new(0, 128), Point::new(64, 96)), 1);
        l.draw_line(Line::new(Point::new(128, 128), Point::new(64, 96)), 1);

        l.fill(Point::new(32, 32), 1, 2);
        l.fill(Point::new(16, 96), 1, 3);
        l.fill(Point::new(60, 100), 1, 4);

        assert_eq!(l.pixels[0][0], 1);
        assert_eq!(l.pixels[96][64], 1);

        assert_eq!(l.pixels[40][32], 2);
        assert_eq!(l.pixels[40][96], 2);
        assert_eq!(l.pixels[5][0], 3);
        assert_eq!(l.pixels[120][0], 3);
        assert_eq!(l.pixels[5][127], 3);
        assert_eq!(l.pixels[120][127], 3);
        assert_eq!(l.pixels[35][64], 3);
        assert_eq!(l.pixels[120][20], 4);
        assert_eq!(l.pixels[120][100], 4);
        assert_eq!(l.pixels[100][64], 4);
    }
}
