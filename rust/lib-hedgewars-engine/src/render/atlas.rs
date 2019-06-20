use integral_geometry::{Rect, Size};
use itertools::Itertools;
use std::{
    cmp::{max, min, Ordering},
    ops::Index,
};

#[derive(PartialEq, Eq, PartialOrd, Ord, Clone)]
struct Fit {
    short_side: u32,
    long_side: u32,
}

impl Fit {
    fn new() -> Self {
        Self {
            short_side: u32::max_value(),
            long_side: u32::max_value(),
        }
    }

    fn measure(container: Size, size: Size) -> Option<Self> {
        if container.contains(size) {
            let x_leftover = container.width - size.width;
            let y_leftover = container.height - size.height;
            Some(Self {
                short_side: min(x_leftover, y_leftover) as u32,
                long_side: max(x_leftover, y_leftover) as u32,
            })
        } else {
            None
        }
    }
}

#[derive(PartialEq, Eq)]
pub struct UsedSpace {
    used_area: usize,
    total_area: usize,
}

impl UsedSpace {
    const fn new(used_area: usize, total_area: usize) -> Self {
        Self {
            used_area,
            total_area,
        }
    }

    const fn used(&self) -> usize {
        self.used_area
    }

    const fn total(&self) -> usize {
        self.total_area
    }

    const fn free(&self) -> usize {
        self.total_area - self.used_area
    }
}

impl std::fmt::Debug for UsedSpace {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> Result<(), std::fmt::Error> {
        write!(
            f,
            "{:.2}%",
            self.used() as f32 / self.total() as f32 / 100.0
        )?;
        Ok(())
    }
}

pub struct Atlas<T> {
    size: Size,
    free_rects: Vec<Rect>,
    used_rects: Vec<(Rect, T)>,
    splits: Vec<Rect>,
}

impl<T: Copy> Atlas<T> {
    pub fn new(size: Size) -> Self {
        Self {
            size,
            free_rects: vec![Rect::at_origin(size)],
            used_rects: vec![],
            splits: vec![],
        }
    }

    pub fn size(&self) -> Size {
        self.size
    }

    pub fn used_space(&self) -> UsedSpace {
        let used = self.used_rects.iter().map(|(r, _)| r.size().area()).sum();
        UsedSpace::new(used, self.size.area())
    }

    fn find_position(&self, size: Size) -> Option<(Rect, Fit)> {
        let mut best_rect = Rect::EMPTY;
        let mut best_fit = Fit::new();

        for rect in &self.free_rects {
            if let Some(fit) = Fit::measure(rect.size(), size) {
                if fit < best_fit {
                    best_fit = fit;
                    best_rect = Rect::from_size(rect.top_left(), size);
                }
            }

            if let Some(fit) = Fit::measure(rect.size(), size.transpose()) {
                if fit < best_fit {
                    best_fit = fit;
                    best_rect = Rect::from_size(rect.top_left(), size.transpose());
                }
            }
        }

        if best_rect == Rect::EMPTY {
            None
        } else {
            Some((best_rect, best_fit))
        }
    }

    fn split_insert(&mut self, rect: Rect, value: T) {
        let mut splits = std::mem::replace(&mut self.splits, vec![]);
        let mut buffer = [Rect::EMPTY; 4];

        for i in (0..self.free_rects.len()).rev() {
            if let Some(count) = split_rect(self.free_rects[i], rect, &mut splits, &mut buffer) {
                self.free_rects.swap_remove(i as usize);
                splits.extend_from_slice(&buffer[0..count]);
            }
        }

        filter_swap_remove(&mut splits, |s| {
            self.free_rects.iter().any(|r| r.contains_rect(s))
        });
        self.free_rects.extend(splits.drain(..));
        std::mem::replace(&mut self.splits, splits);

        self.used_rects.push((rect, value));
    }

    pub fn insert(&mut self, size: Size, value: T) -> Option<Rect> {
        let (rect, _) = self.find_position(size)?;
        self.split_insert(rect, value);
        Some(rect)
    }

    pub fn insert_set<Iter>(&mut self, sizes: Iter) -> Vec<(Rect, T)>
    where
        Iter: Iterator<Item = (Size, T)>,
    {
        let mut sizes: Vec<_> = sizes.collect();
        let mut result = Vec::with_capacity(sizes.len());

        while let Some((index, (rect, _), value)) = sizes
            .iter()
            .enumerate()
            .filter_map(|(i, (s, v))| self.find_position(*s).map(|res| (i, res, v)))
            .min_by_key(|(_, (_, fit), _)| fit.clone())
        {
            self.split_insert(rect, *value);

            result.push((rect, *value));
            sizes.swap_remove(index);
        }
        result
    }

    pub fn reset(&mut self) {
        self.free_rects.clear();
        self.used_rects.clear();
        self.free_rects.push(Rect::at_origin(self.size));
    }
}

pub type SpriteIndex = u32;
pub type SpriteLocation = (u32, Rect);

pub struct AtlasCollection {
    next_index: SpriteIndex,
    texture_size: Size,
    atlases: Vec<Atlas<SpriteIndex>>,
    rects: Vec<SpriteLocation>,
}

impl AtlasCollection {
    pub fn new(texture_size: Size) -> Self {
        Self {
            next_index: 0,
            texture_size,
            atlases: vec![],
            rects: vec![],
        }
    }

    fn repack(&mut self, size: Size) -> bool {
        for (atlas_index, atlas) in self.atlases.iter_mut().enumerate() {
            if atlas.used_space().free() >= size.area() {
                let mut temp_atlas = Atlas::new(atlas.size());
                let sizes = atlas
                    .used_rects
                    .iter()
                    .map(|(r, v)| (r.size(), *v))
                    .chain(std::iter::once((size, self.next_index)));
                let inserts = temp_atlas.insert_set(sizes);
                if inserts.len() > atlas.used_rects.len() {
                    self.rects.push((0, Rect::EMPTY));
                    for (rect, index) in inserts {
                        self.rects[index as usize] = (atlas_index as u32, rect);
                    }
                    std::mem::swap(atlas, &mut temp_atlas);
                    return true;
                }
            }
        }
        false
    }

    #[inline]
    fn consume_index(&mut self) -> Option<SpriteIndex> {
        let result = Some(self.next_index);
        self.next_index += 1;
        result
    }

    pub fn insert_sprite(&mut self, size: Size) -> Option<SpriteIndex> {
        if !self.texture_size.contains(size) {
            None
        } else {
            let index = self.next_index;
            if let Some(index_rect) = self
                .atlases
                .iter_mut()
                .enumerate()
                .find_map(|(i, a)| a.insert(size, index).map(|r| (i as u32, r)))
            {
                self.rects.push(index_rect);
            } else if !self.repack(size) {
                let mut atlas = Atlas::new(self.texture_size);
                let rect = atlas.insert(size, index)?;
                self.atlases.push(atlas);
                self.rects.push(((self.atlases.len() - 1) as u32, rect))
            }
            self.consume_index()
        }
    }
}

impl Index<SpriteIndex> for AtlasCollection {
    type Output = SpriteLocation;

    #[inline]
    fn index(&self, index: SpriteIndex) -> &Self::Output {
        &self.rects[index as usize]
    }
}

#[inline]
fn filter_swap_remove<T, F>(vec: &mut Vec<T>, predicate: F)
where
    F: Fn(&T) -> bool,
{
    let mut i = 0;
    while i < vec.len() {
        if predicate(&vec[i]) {
            vec.swap_remove(i);
        } else {
            i += 1;
        }
    }
}

#[inline]
fn prune_push(
    previous_splits: &mut Vec<Rect>,
    buffer: &mut [Rect; 4],
    buffer_size: &mut usize,
    rect: Rect,
) {
    if !previous_splits.iter().any(|r| r.contains_rect(&rect)) {
        filter_swap_remove(previous_splits, |s| rect.contains_rect(s));
        buffer[*buffer_size] = rect;
        *buffer_size += 1;
    }
}

fn split_rect(
    free_rect: Rect,
    rect: Rect,
    previous_splits: &mut Vec<Rect>,
    buffer: &mut [Rect; 4],
) -> Option<usize> {
    let mut buffer_size = 0usize;
    let split = free_rect.intersects(&rect);
    if split {
        if rect.left() > free_rect.left() {
            let trim = free_rect.right() - rect.left() + 1;
            prune_push(
                previous_splits,
                buffer,
                &mut buffer_size,
                free_rect.with_margins(0, -trim, 0, 0),
            );
        }
        if rect.right() < free_rect.right() {
            let trim = rect.right() - free_rect.left() + 1;
            prune_push(
                previous_splits,
                buffer,
                &mut buffer_size,
                free_rect.with_margins(-trim, 0, 0, 0),
            );
        }
        if rect.top() > free_rect.top() {
            let trim = free_rect.bottom() - rect.top() + 1;
            prune_push(
                previous_splits,
                buffer,
                &mut buffer_size,
                free_rect.with_margins(0, 0, 0, -trim),
            );;
        }
        if rect.bottom() < free_rect.bottom() {
            let trim = rect.bottom() - free_rect.top() + 1;
            prune_push(
                previous_splits,
                buffer,
                &mut buffer_size,
                free_rect.with_margins(0, 0, -trim, 0),
            );;
        }
    }
    if split {
        Some(buffer_size)
    } else {
        None
    }
}

#[cfg(test)]
mod tests {
    use super::Atlas;
    use integral_geometry::{Rect, Size};
    use itertools::Itertools as _;
    use proptest::prelude::*;

    #[test]
    fn insert() {
        let atlas_size = Size::square(16);
        let mut atlas = Atlas::new(atlas_size);

        assert_eq!(None, atlas.insert(Size::square(20), ()));

        let rect_size = Size::new(11, 3);
        let rect = atlas.insert(rect_size, ()).unwrap();

        assert_eq!(rect, Rect::at_origin(rect_size));
        assert_eq!(2, atlas.free_rects.len());
    }

    #[derive(Debug, Clone)]
    struct TestRect(Size);
    struct TestRectParameters(Size);

    impl Default for TestRectParameters {
        fn default() -> Self {
            Self(Size::square(64))
        }
    }

    impl Arbitrary for TestRect {
        type Parameters = TestRectParameters;

        fn arbitrary_with(args: Self::Parameters) -> Self::Strategy {
            (1..=args.0.width, 1..=args.0.height)
                .prop_map(|(w, h)| TestRect(Size::new(w, h)))
                .boxed()
        }

        type Strategy = BoxedStrategy<TestRect>;
    }

    trait HasSize {
        fn size(&self) -> Size;
    }

    impl HasSize for TestRect {
        fn size(&self) -> Size {
            self.0
        }
    }

    impl HasSize for Rect {
        fn size(&self) -> Size {
            self.size()
        }
    }

    impl HasSize for (Rect, ()) {
        fn size(&self) -> Size {
            self.0.size()
        }
    }

    fn sum_area<S: HasSize>(items: &[S]) -> usize {
        items.iter().map(|s| s.size().area()).sum()
    }

    proptest! {
        #[test]
        fn prop_insert(rects in Vec::<TestRect>::arbitrary()) {
            let container = Rect::at_origin(Size::square(2048));
            let mut atlas = Atlas::new(container.size());
            let inserted: Vec<_> = rects.iter().filter_map(|TestRect(size)| atlas.insert(*size, ())).collect();

            let mut inserted_pairs = inserted.iter().cartesian_product(inserted.iter());

            assert!(inserted.iter().all(|r| container.contains_rect(r)));
            assert!(inserted_pairs.all(|(r1, r2)| r1 == r2 || r1 != r2 && !r1.intersects(r2)));

            assert_eq!(inserted.len(), rects.len());
            assert_eq!(sum_area(&inserted), sum_area(&rects));
        }
    }

    proptest! {
        #[test]
        fn prop_insert_set(rects in Vec::<TestRect>::arbitrary()) {
            let container = Rect::at_origin(Size::square(2048));
            let mut atlas = Atlas::new(container.size());
            let mut set_atlas = Atlas::new(container.size());

            let inserted: Vec<_> = rects.iter().filter_map(|TestRect(size)| atlas.insert(*size, ())).collect();
            let set_inserted: Vec<_> = set_atlas.insert_set(rects.iter().map(|TestRect(size)| (*size, ())));

            let mut set_inserted_pairs = set_inserted.iter().cartesian_product(set_inserted.iter());

            assert!(set_inserted_pairs.all(|((r1, _), (r2, _))| r1 == r2 || r1 != r2 && !r1.intersects(r2)));
            assert!(set_atlas.used_space().used() <= atlas.used_space().used());

            assert_eq!(sum_area(&set_inserted), sum_area(&inserted));
        }
    }
}
