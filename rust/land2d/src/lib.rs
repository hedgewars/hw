extern crate vec2d;

use std::cmp;

pub struct Land2D<T> {
    pixels: vec2d::Vec2D<T>,
    width_mask: usize,
    height_mask: usize,
}

impl<T: Default + Copy> Land2D<T> {
    pub fn new(width: usize, height: usize) -> Self {
        assert!(width.is_power_of_two());
        assert!(height.is_power_of_two());

        Self {
            pixels: vec2d::Vec2D::new(width, height, T::default()),
            width_mask: !(width - 1),
            height_mask: !(height - 1),
        }
    }

    #[inline]
    fn is_valid_coordinate(&self, x: i32, y: i32) -> bool {
        (x as usize & self.width_mask) == 0 && (y as usize & self.height_mask) == 0
    }

    #[inline]
    pub fn map<U, F: FnOnce(&mut T) -> U>(&mut self, y: i32, x: i32, f: F) {
        if self.is_valid_coordinate(x, y) {
            self.pixels.get_mut(y as usize, x as usize).map(f);
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
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn basics() {
        let  l:Land2D<u8> = Land2D::new(32, 64);

        assert!(l.is_valid_coordinate(0, 0));
        assert!(!l.is_valid_coordinate(-1, -1));

        assert!(l.is_valid_coordinate(31, 63));
        assert!(!l.is_valid_coordinate(32, 63));
        assert!(!l.is_valid_coordinate(31, 64));
    }

}
