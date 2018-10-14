use std::iter;
use std::ops::{Index, IndexMut};

struct Vec2D<T> {
    data: Vec<T>,
    width: usize,
    height: usize,
}

impl<T> Index<usize> for Vec2D<T> {
    type Output = [T];

    #[inline]
    fn index(&self, row: usize) -> &[T] {
        debug_assert!(row < self.height);

        let pos = row * self.width;

        &self.data[pos..pos + self.width]
    }
}

impl<T> IndexMut<usize> for Vec2D<T> {
    #[inline]
    fn index_mut(&mut self, row: usize) -> &mut [T] {
        debug_assert!(row < self.height);

        let pos = row * self.width;

        &mut self.data[pos..pos + self.width]
    }
}

impl<T: Copy> Vec2D<T> {
    pub fn new(width: usize, height: usize, value: T) -> Self {
        let mut vec = Self {
            data: Vec::new(),
            width,
            height,
        };

        vec.data.extend(iter::repeat(value).take(width * height));

        vec
    }

    #[inline]
    pub fn width(&self) -> usize {
        self.width
    }

    #[inline]
    pub fn height(&self) -> usize {
        self.height
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn basics() {
        let mut v: Vec2D<u8> = Vec2D::new(2, 3, 0xff);

        assert_eq!(v.width, 2);
        assert_eq!(v.height, 3);

        assert_eq!(v[0][0], 0xff);
        assert_eq!(v[2][1], 0xff);

        v[2][1] = 0;

        assert_eq!(v[2][0], 0xff);
        assert_eq!(v[2][1], 0);
    }
}
