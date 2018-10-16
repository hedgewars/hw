extern crate vec2d;

use std::cmp;

pub struct Land2D<T> {
    pixels: vec2d::Vec2D<T>,
    width_mask: usize,
    height_mask: usize,
}

impl<T: Copy + PartialEq> Land2D<T> {
    pub fn new(width: usize, height: usize, fill_value: T) -> Self {
        assert!(width.is_power_of_two());
        assert!(height.is_power_of_two());

        Self {
            pixels: vec2d::Vec2D::new(width, height, fill_value),
            width_mask: !(width - 1),
            height_mask: !(height - 1),
        }
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
    pub fn is_valid_x(&self, x: i32) -> bool {
        (x as usize & self.width_mask) == 0
    }

    #[inline]
    pub fn is_valid_y(&self, y: i32) -> bool {
        (y as usize & self.height_mask) == 0
    }

    #[inline]
    pub fn is_valid_coordinate(&self, x: i32, y: i32) -> bool {
        self.is_valid_x(x) && self.is_valid_y(y)
    }

    #[inline]
    pub fn map<U, F: FnOnce(&mut T) -> U>(&mut self, y: i32, x: i32, f: F) {
        if self.is_valid_coordinate(x, y) {
            unsafe { // hey, I just checked that coordinates are valid!
                f(self.pixels.get_unchecked_mut(y as usize, x as usize));
            }
        }
    }

    pub fn draw_line(&mut self, x1: i32, y1: i32, x2: i32, y2: i32, value: T) {
        let mut e_x: i32 = 0;
        let mut e_y: i32 = 0;
        let mut d_x: i32 = x2 - x1;
        let mut d_y: i32 = y2 - y1;

        let s_x: i32;
        let s_y: i32;

        if d_x > 0 {
            s_x = 1;
        } else if d_x < 0 {
            s_x = -1;
            d_x = -d_x;
        } else {
            s_x = d_x;
        }

        if d_y > 0 {
            s_y = 1;
        } else if d_y < 0 {
            s_y = -1;
            d_y = -d_y;
        } else {
            s_y = d_y;
        }

        let d = cmp::max(d_x, d_y);

        let mut x = x1;
        let mut y = y1;

        for _i in 0..=d {
            e_x += d_x;
            e_y += d_y;

            if e_x > d {
                e_x -= d;
                x += s_x;
            }
            if e_y > d {
                e_y -= d;
                y += s_y;
            }

            self.map(y, x, |p| *p = value);
        }
    }

    pub fn fill(&mut self, start_x: i32, start_y: i32, border_value: T, fill_value: T) {
        debug_assert!(self.is_valid_coordinate(start_x - 1, start_y));
        debug_assert!(self.is_valid_coordinate(start_x, start_y));

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

            if land.is_valid_coordinate(0, yd as i32) {
                stack.push((xl, xr, yd as usize, dir));
            }
        };

        let start_x_l = (start_x - 1) as usize;
        let start_x_r = start_x as usize;
        push(self, &mut stack, start_x_l, start_x_r, start_y as usize, -1);
        push(self, &mut stack, start_x_l, start_x_r, start_y as usize, 1);

        loop {
            let a = stack.pop();
            match a {
                None => return,
                Some(a) => {
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
                            && (self.pixels[y][xl] == border_value
                                || self.pixels[y][xl] == fill_value)
                        {
                            xl += 1;
                        }

                        let mut x = xl;

                        while xl <= xr
                            && (self.pixels[y][xl] != border_value
                                && self.pixels[y][xl] != fill_value)
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
                unsafe { // coordinates are valid at this point
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
        let mut dx: i32 = 0;
        let mut dy: i32 = radius;
        let mut d = 3 - 2 * radius;
        let mut result = 0;

        while dx < dy {
            result += self.fill_circle_lines(x, y, dx, dy, &f);

            if d < 0 {
                d += 4 * dx + 6;
            } else {
                d += 4 * (dx - dy) + 10;
                dy -= 1;
            }

            dx += 1;
        }

        if dx == dy {
            result += self.fill_circle_lines(x, y, dx, dy, &f);
        }

        result
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn basics() {
        let l: Land2D<u8> = Land2D::new(32, 64, 0);

        assert!(l.is_valid_coordinate(0, 0));
        assert!(!l.is_valid_coordinate(-1, -1));

        assert!(l.is_valid_coordinate(31, 63));
        assert!(!l.is_valid_coordinate(32, 63));
        assert!(!l.is_valid_coordinate(31, 64));
    }

    #[test]
    fn fill() {
        let mut l: Land2D<u8> = Land2D::new(128, 128, 0);

        l.draw_line(0, 0, 32, 96, 1);
        l.draw_line(32, 96, 64, 32, 1);
        l.draw_line(64, 32, 96, 80, 1);
        l.draw_line(96, 80, 128, 0, 1);

        l.draw_line(0, 128, 64, 96, 1);
        l.draw_line(128, 128, 64, 96, 1);

        l.fill(32, 32, 1, 2);
        l.fill(16, 96, 1, 3);
        l.fill(60, 100, 1, 4);

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
