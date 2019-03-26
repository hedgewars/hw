use integral_geometry::{Rect, Size};
use std::cmp::{max, min, Ordering};

#[derive(PartialEq, Eq, PartialOrd, Ord, Clone)]
struct Fit {
    short_size: u32,
    long_size: u32,
}

impl Fit {
    fn new() -> Self {
        Self {
            short_size: u32::max_value(),
            long_size: u32::max_value(),
        }
    }

    fn measure(container: Size, size: Size) -> Option<Self> {
        if container.contains(size) {
            let x_leftover = container.width - size.width;
            let y_leftover = container.height - size.height;
            Some(Self {
                short_size: min(x_leftover, y_leftover) as u32,
                long_size: max(x_leftover, y_leftover) as u32,
            })
        } else {
            None
        }
    }
}

pub struct Atlas {
    size: Size,
    free_rects: Vec<Rect>,
    used_rects: Vec<Rect>,
}

impl Atlas {
    pub fn new(size: Size) -> Self {
        Self {
            size,
            free_rects: vec![Rect::at_origin(size)],
            used_rects: vec![],
        }
    }

    pub fn size(&self) -> Size {
        self.size
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

    fn prune(&mut self) {
        self.free_rects = self
            .free_rects
            .iter()
            .filter(|inner| {
                self.free_rects
                    .iter()
                    .all(|outer| outer == *inner || !outer.contains_rect(inner))
            })
            .cloned()
            .collect();
    }

    pub fn insert(&mut self, size: Size) -> Option<Rect> {
        let (rect, _) = self.find_position(size)?;

        let mut rects_to_process = self.free_rects.len();
        let mut i = 0;

        while i < rects_to_process {
            let rects = split_rect(self.free_rects[i], rect);
            if !rects.is_empty() {
                self.free_rects.remove(i);
                self.free_rects.extend(rects);
                rects_to_process -= 1
            } else {
                i += 1;
            }
        }

        self.used_rects.push(rect);
        self.prune();
        Some(rect)
    }

    pub fn insert_set<Iter>(&mut self, sizes: Iter) -> Vec<Rect>
    where
        Iter: Iterator<Item = Size>,
    {
        let mut sizes: Vec<_> = sizes.collect();
        let mut result = vec![];

        while let Some((index, (rect, _))) = sizes
            .iter()
            .enumerate()
            .filter_map(|(i, s)| self.find_position(*s).map(|res| (i, res)))
            .min_by_key(|(_, (_, fit))| fit.clone())
        {
            result.push(rect);
            sizes.swap_remove(index);
        }
        if sizes.is_empty() {
            self.used_rects.extend_from_slice(&result);
            result
        } else {
            vec![]
        }
    }

    pub fn reset(&mut self) {
        self.free_rects.clear();
        self.used_rects.clear();
        self.free_rects.push(Rect::at_origin(self.size));
    }
}

pub struct AtlasCollection {
    texture_size: Size,
    atlases: Vec<Atlas>,
}

impl AtlasCollection {
    pub fn new(texture_size: Size) -> Self {
        Self {
            texture_size,
            atlases: vec![],
        }
    }

    fn repack(&mut self, size: Size) -> bool {
        for atlas in &mut self.atlases {
            let mut temp_atlas = Atlas::new(atlas.size());
            let sizes = atlas
                .used_rects
                .iter()
                .map(|r| r.size())
                .chain(std::iter::once(size));
            if !temp_atlas.insert_set(sizes).is_empty() {
                std::mem::swap(atlas, &mut temp_atlas);
                return true;
            }
        }
        false
    }

    pub fn insert_sprite(&mut self, size: Size) -> bool {
        if !self.texture_size.contains(size) {
            false
        } else {
            if let Some(rect) = self.atlases.iter_mut().find_map(|a| a.insert(size)) {

            } else if !self.repack(size) {
                let mut atlas = Atlas::new(self.texture_size);
                atlas.insert(size);
                self.atlases.push(atlas);
            }
            true
        }
    }
}

fn split_rect(free_rect: Rect, rect: Rect) -> Vec<Rect> {
    let mut result = vec![];
    if free_rect.intersects(&rect) {
        if rect.left() > free_rect.left() {
            let trim = free_rect.right() - rect.left() + 1;
            result.push(free_rect.with_margins(0, -trim, 0, 0))
        }
        if rect.right() < free_rect.right() {
            let trim = rect.right() - free_rect.left() + 1;
            result.push(free_rect.with_margins(-trim, 0, 0, 0))
        }
        if rect.top() > free_rect.top() {
            let trim = free_rect.bottom() - rect.top() + 1;
            result.push(free_rect.with_margins(0, 0, 0, -trim));
        }
        if rect.bottom() < free_rect.bottom() {
            let trim = rect.bottom() - free_rect.top() + 1;
            result.push(free_rect.with_margins(0, 0, -trim, 0));
        }
    }
    result
}

#[cfg(test)]
mod tests {
    use super::Atlas;
    use integral_geometry::{Rect, Size};
    use proptest::prelude::*;

    #[test]
    fn insert() {
        let atlas_size = Size::square(16);
        let mut atlas = Atlas::new(atlas_size);

        assert_eq!(None, atlas.insert(Size::square(20)));

        let rect_size = Size::new(11, 3);
        let rect = atlas.insert(rect_size).unwrap();
        
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

    fn sum_area<S: HasSize>(items: &[S]) -> usize {
        items.iter().map(|s| s.size().area()).sum()
    }

    proptest! {
        #[test]
        fn prop_insert(rects in Vec::<TestRect>::arbitrary()) {
            let mut atlas = Atlas::new(Size::square(2048));
            let inserted: Vec<_> = rects.iter().take_while(|TestRect(size)| atlas.insert(*size).is_some()).cloned().collect();

            assert_eq!(inserted.len(), atlas.used_rects.len());
            assert_eq!(sum_area(&inserted), sum_area(&atlas.used_rects));
        }
    }
}
