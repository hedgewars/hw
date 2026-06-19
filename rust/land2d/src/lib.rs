use integral_geometry::{ArcPoints, EquidistantPoints, Line, Point, PotSize, Rect, Size, SizeMask};
use std::{cmp, ops::Index, ops::IndexMut, ops::RangeInclusive};
use vec2d::Vec2D;

#[derive(Debug)]
pub struct Land2D<T> {
    pixels: vec2d::Vec2D<T>,
    play_box: Rect,
    mask: SizeMask,
}

impl<T: Copy + PartialEq + Default> Land2D<T> {
    pub fn new(play_size: &Size, fill_value: T) -> Self {
        let real_size = play_size.next_power_of_two();
        let top_left = Point::new(
            ((real_size.width() - play_size.width) / 2) as i32,
            (real_size.height() - play_size.height) as i32,
        );
        let play_box = Rect::from_size(top_left, *play_size);
        Self {
            play_box,
            pixels: vec2d::Vec2D::new(&real_size.size(), fill_value),
            mask: real_size.to_mask(),
        }
    }

    pub fn raw_pixels(&self) -> &[T] {
        &self.pixels.as_slice()
    }

    pub fn raw_pixel_bytes(&self) -> &[u8] {
        unsafe { self.pixels.as_bytes() }
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
    pub fn size(&self) -> PotSize {
        self.mask.to_size()
    }

    #[inline]
    pub fn play_width(&self) -> u32 {
        self.play_box.width()
    }

    #[inline]
    pub fn play_height(&self) -> u32 {
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
        self.mask.contains_x(x as u32)
    }

    #[inline]
    pub fn is_valid_y(&self, y: i32) -> bool {
        self.mask.contains_y(y as u32)
    }

    #[inline]
    pub fn is_valid_coordinate(&self, x: i32, y: i32) -> bool {
        self.is_valid_x(x) && self.is_valid_y(y)
    }

    #[inline]
    pub fn rows(&self) -> impl DoubleEndedIterator<Item = &[T]> {
        self.pixels.rows()
    }

    #[inline]
    pub fn iter_range(
        &self,
        row_range: RangeInclusive<i32>,
        col_range: RangeInclusive<i32>,
    ) -> LandRangeIter<'_, T> {
        let start_y = cmp::max(0, *row_range.start());
        let mut end_y = cmp::min(self.height() as i32 - 1, *row_range.end());
        let start_x = cmp::max(0, *col_range.start());
        let end_x = cmp::min(self.width() as i32 - 1, *col_range.end());

        if end_x < start_x {
            // invalidate row range if column range is invalid to save on checks later
            end_y = start_y - 1;
        }

        LandRangeIter {
            land: self,
            curr_y: start_y,
            curr_x: start_x,
            end_y,
            start_x,
            end_x,
        }
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
    pub fn get(&self, y: i32, x: i32) -> T {
        if self.is_valid_coordinate(x, y) {
            unsafe {
                // hey, I just checked that coordinates are valid!
                *self.pixels.get_unchecked(y as usize, x as usize)
            }
        } else {
            T::default()
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
        })
        .count()
    }

    pub fn draw_line(&mut self, line: Line, value: T) -> usize {
        self.fill_from_iter(line.into_iter(), value)
    }

    pub fn fill(&mut self, start_point: Point, border_value: T, fill_value: T) {
        assert!(self.is_valid_coordinate(start_point.x - 1, start_point.y));
        assert!(self.is_valid_coordinate(start_point.x, start_point.y));

        let mask = self.mask;
        let width = self.width();

        let mut stack: Vec<(usize, usize, usize, isize)> = Vec::new();
        fn push(
            mask: SizeMask,
            stack: &mut Vec<(usize, usize, usize, isize)>,
            xl: usize,
            xr: usize,
            y: usize,
            dir: isize,
        ) {
            let yd = y as isize + dir;
            if mask.contains_y(yd as u32) {
                stack.push((xl, xr, yd as usize, dir));
            }
        }

        let start_x_l = (start_point.x - 1) as usize;
        let start_x_r = start_point.x as usize;
        for dir in [-1, 1].iter().cloned() {
            push(
                mask,
                &mut stack,
                start_x_l,
                start_x_r,
                start_point.y as usize,
                dir,
            );
        }

        while let Some((mut xl, mut xr, y, dir)) = stack.pop() {
            let row = &mut self.pixels[y][..];
            while xl > 0 && row[xl] != border_value && row[xl] != fill_value {
                xl -= 1;
            }

            while xr < width - 1 && row[xr] != border_value && row[xr] != fill_value {
                xr += 1;
            }

            while xl < xr {
                while xl <= xr && (row[xl] == border_value || row[xl] == fill_value) {
                    xl += 1;
                }

                let x = xl;

                while xl <= xr && row[xl] != border_value && row[xl] != fill_value {
                    row[xl] = fill_value;
                    xl += 1;
                }

                if x < xl {
                    push(mask, &mut stack, x, xl - 1, y, dir);
                    push(mask, &mut stack, x, xl - 1, y, -dir);
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
            })
            .sum()
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

impl<T> Index<usize> for Land2D<T> {
    type Output = [T];
    #[inline]
    fn index(&self, row: usize) -> &[T] {
        &self.pixels[row]
    }
}

impl<T> IndexMut<usize> for Land2D<T> {
    #[inline]
    fn index_mut(&mut self, row: usize) -> &mut [T] {
        &mut self.pixels[row]
    }
}

impl<T> From<Vec2D<T>> for Land2D<T> {
    fn from(vec: Vec2D<T>) -> Self {
        let actual_size = vec.size();
        let pot_size = actual_size.next_power_of_two();

        assert_eq!(actual_size, pot_size.size());

        let top_left = Point::new(0, 0);
        let play_box = Rect::from_size(top_left, actual_size);
        Self {
            play_box,
            pixels: vec,
            mask: pot_size.to_mask(),
        }
    }
}

#[derive(Debug, Clone)]
pub struct LandRangeIter<'a, T> {
    land: &'a Land2D<T>,
    curr_y: i32,
    curr_x: i32,
    end_y: i32,
    start_x: i32,
    end_x: i32,
}

impl<'a, T: Copy + PartialEq + Default> Iterator for LandRangeIter<'a, T> {
    type Item = &'a T;

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        if self.curr_y > self.end_y {
            return None;
        }

        let val = unsafe {
            self.land
                .pixels
                .get_unchecked(self.curr_y as usize, self.curr_x as usize)
        };

        if self.curr_x < self.end_x {
            self.curr_x += 1;
        } else {
            self.curr_x = self.start_x;
            self.curr_y += 1;
        }

        Some(val)
    }

    #[inline]
    fn size_hint(&self) -> (usize, Option<usize>) {
        if self.curr_y > self.end_y || self.start_x > self.end_x {
            (0, Some(0))
        } else {
            let remaining_rows = (self.end_y - self.curr_y) as usize;
            let remaining_in_curr_row = (self.end_x - self.curr_x + 1) as usize;
            let cols = (self.end_x - self.start_x + 1) as usize;
            let size = remaining_rows * cols + remaining_in_curr_row;
            (size, Some(size))
        }
    }
}

impl<'a, T: Copy + PartialEq + Default> ExactSizeIterator for LandRangeIter<'a, T> {}
impl<'a, T: Copy + PartialEq + Default> std::iter::FusedIterator for LandRangeIter<'a, T> {}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn basics() {
        let l: Land2D<u8> = Land2D::new(&Size::new(30, 50), 0);

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
        let mut l: Land2D<u8> = Land2D::new(&Size::square(128), 0);

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

    #[test]
    fn test_iter_range() {
        let mut l: Land2D<u8> = Land2D::new(&Size::square(4), 0);
        assert_eq!(l.width(), 4);
        assert_eq!(l.height(), 4);

        for y in 0..4 {
            for x in 0..4 {
                l.map(y, x, |v| *v = (y * 10 + x) as u8);
            }
        }

        // Test normal range inside bounds
        let elements: Vec<u8> = l.iter_range(1..=2, 1..=3).copied().collect();
        assert_eq!(elements, vec![11, 12, 13, 21, 22, 23]);

        // Test out of bounds range that gets clamped
        let elements_clamped: Vec<u8> = l.iter_range(-1..=5, 2..=10).copied().collect();
        assert_eq!(elements_clamped, vec![2, 3, 12, 13, 22, 23, 32, 33]);

        // Test empty range
        let elements_empty: Vec<u8> = l.iter_range(2..=1, 0..=3).copied().collect();
        assert!(elements_empty.is_empty());

        let elements_empty_col: Vec<u8> = l.iter_range(0..=3, 2..=1).copied().collect();
        assert!(elements_empty_col.is_empty());
    }
}
