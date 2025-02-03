use integral_geometry::Size;
use std::{
    ops::{Index, IndexMut},
    slice::{ChunksExact, ChunksExactMut, SliceIndex},
};

#[derive(Debug, Clone)]
pub struct Vec2D<T> {
    data: Vec<T>,
    size: Size,
}

impl<T> Index<usize> for Vec2D<T> {
    type Output = [T];

    #[inline]
    fn index(&self, row: usize) -> &[T] {
        debug_assert!(row < self.height());

        let pos = row * self.width();

        &self.data[pos..pos + self.width()]
    }
}

impl<T> IndexMut<usize> for Vec2D<T> {
    #[inline]
    fn index_mut(&mut self, row: usize) -> &mut [T] {
        debug_assert!(row < self.height());

        let pos = row * self.width();

        &mut self.data[pos..pos + self.size.width as usize]
    }
}

impl<T> Vec2D<T> {
    #[inline]
    pub fn width(&self) -> usize {
        self.size.width as usize
    }

    #[inline]
    pub fn height(&self) -> usize {
        self.size.height as usize
    }

    #[inline]
    pub fn size(&self) -> Size {
        self.size
    }
}

impl<T: Copy> Vec2D<T> {
    pub fn new(size: &Size, value: T) -> Self {
        Self {
            size: *size,
            data: vec![value; size.area() as usize],
        }
    }

    #[inline]
    pub fn as_slice(&self) -> &[T] {
        self.data.as_slice()
    }

    #[inline]
    pub fn as_mut_slice(&mut self) -> &mut [T] {
        self.data.as_mut_slice()
    }

    #[inline]
    pub fn get(&self, row: usize, column: usize) -> Option<&<usize as SliceIndex<[T]>>::Output> {
        if row < self.height() && column < self.width() {
            Some(unsafe { self.data.get_unchecked(row * self.width() + column) })
        } else {
            None
        }
    }

    #[inline]
    pub fn get_mut(
        &mut self,
        row: usize,
        column: usize,
    ) -> Option<&mut <usize as SliceIndex<[T]>>::Output> {
        if row < self.height() && column < self.width() {
            Some(unsafe {
                self.data
                    .get_unchecked_mut(row * self.size.width as usize + column)
            })
        } else {
            None
        }
    }

    #[inline]
    pub unsafe fn get_unchecked(
        &self,
        row: usize,
        column: usize,
    ) -> &<usize as SliceIndex<[T]>>::Output {
        self.data.get_unchecked(row * self.width() + column)
    }

    #[inline]
    pub unsafe fn get_unchecked_mut(
        &mut self,
        row: usize,
        column: usize,
    ) -> &mut <usize as SliceIndex<[T]>>::Output {
        self.data
            .get_unchecked_mut(row * self.size.width as usize + column)
    }

    #[inline]
    pub fn rows(&self) -> ChunksExact<'_, T> {
        self.data.chunks_exact(self.width())
    }

    #[inline]
    pub fn rows_mut(&mut self) -> ChunksExactMut<'_, T> {
        let width = self.width();
        self.data.chunks_exact_mut(width)
    }

    #[inline]
    pub unsafe fn as_bytes(&self) -> &[u8] {
        use std::{mem, slice};

        slice::from_raw_parts(
            self.data.as_ptr() as *const u8,
            self.data.len() * mem::size_of::<T>(),
        )
    }
}

impl<T: Copy> AsRef<[T]> for Vec2D<T> {
    fn as_ref(&self) -> &[T] {
        self.as_slice()
    }
}

impl<T: Copy> AsMut<[T]> for Vec2D<T> {
    fn as_mut(&mut self) -> &mut [T] {
        self.as_mut_slice()
    }
}

impl<T: Clone> Vec2D<T> {
    pub fn from_iter<I: IntoIterator<Item = T>>(iter: I, size: &Size) -> Option<Vec2D<T>> {
        let data: Vec<T> = iter.into_iter().collect();
        if size.width as usize * size.height as usize == data.len() {
            Some(Vec2D { data, size: *size })
        } else {
            None
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn basics() {
        let mut v: Vec2D<u8> = Vec2D::new(&Size::new(2, 3), 0xff);

        assert_eq!(v.width(), 2);
        assert_eq!(v.height(), 3);

        assert_eq!(v[0][0], 0xff);
        assert_eq!(v[2][1], 0xff);

        v[2][1] = 0;

        assert_eq!(v[2][0], 0xff);
        assert_eq!(v[2][1], 0);

        v.get_mut(2, 1).into_iter().for_each(|v| *v = 1);
        assert_eq!(v[2][1], 1);

        assert_eq!(v.get_mut(2, 2), None);
    }
}
