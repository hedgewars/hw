use std::cmp;

pub struct LinePoints {
    e_x: i32,
    e_y: i32,
    d_x: i32,
    d_y: i32,
    s_x: i32,
    s_y: i32,
    x: i32,
    y: i32,
    d: i32,
    i: i32,
}

impl LinePoints {
    pub fn new(x1: i32, y1: i32, x2: i32, y2: i32) -> Self {
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

        Self {
            e_x: 0,
            e_y: 0,
            d_x,
            d_y,
            s_x,
            s_y,
            x: x1,
            y: y1,
            d: cmp::max(d_x, d_y),
            i: 0,
        }
    }
}

impl Iterator for LinePoints {
    type Item = (i32, i32);

    fn next(&mut self) -> Option<Self::Item> {
        if self.i <= self.d {
            self.e_x += self.d_x;
            self.e_y += self.d_y;

            if self.e_x > self.d {
                self.e_x -= self.d;
                self.x += self.s_x;
            }
            if self.e_y > self.d {
                self.e_y -= self.d;
                self.y += self.s_y;
            }

            self.i += 1;

            Some((self.x, self.y))
        } else {
            None
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn basic() {
        let v = vec![(0, 0), (1, 1), (2, 2), (3, 3), (123, 456)];

        for (&a, b) in v.iter().zip(LinePoints::new(0, 0, 3, 3)) {
            assert_eq!(a, b);
        }
    }
}
