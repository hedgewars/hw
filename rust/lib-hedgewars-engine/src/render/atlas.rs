use integral_geometry::{Rect, Size};
use std::cmp::{max, min, Ordering};

pub struct Atlas {
    size: Size,
    free_rects: Vec<Rect>,
    used_rects: Vec<Rect>,
}

#[derive(PartialEq, Eq, PartialOrd, Ord)]
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

impl Atlas {
    pub fn new(size: Size) -> Self {
        Self {
            size,
            free_rects: vec![Rect::at_origin(size)],
            used_rects: vec![],
        }
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

    pub fn insert_adaptive(&mut self, size: Size) -> Option<Rect> {
        let (rect, fit) = self.find_position(size)?;

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
        unimplemented!()
    }

    pub fn reset(&mut self) {
        self.free_rects.clear();
        self.used_rects.clear();
        self.free_rects.push(Rect::at_origin(self.size));
    }
}

#[cfg(test)]
mod tests {
    use super::Atlas;
    use integral_geometry::{Rect, Size};

    #[test]
    fn insert() {
        let atlas_size = Size::square(16);
        let mut atlas = Atlas::new(atlas_size);

        assert_eq!(None, atlas.insert_adaptive(Size::square(20)));

        let rect_size = Size::new(11, 3);
        let rect = atlas.insert_adaptive(rect_size).unwrap();
        assert_eq!(rect, Rect::at_origin(rect_size));
        assert_eq!(2, atlas.free_rects.len());
    }
}
