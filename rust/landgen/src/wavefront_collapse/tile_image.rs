use super::transform::Transform;
use integral_geometry::Size;
use std::rc::Rc;
use vec2d::Vec2D;

#[derive(PartialEq, Clone, Debug)]
pub struct Edge<I: PartialEq + Clone> {
    id: I,
    symmetrical: bool,
    reverse: bool,
}

impl<I: PartialEq + Clone> Edge<I> {
    pub fn new(id: I, symmetrical: bool) -> Self {
        Self {
            id,
            symmetrical,
            reverse: false,
        }
    }

    pub fn reversed(&self) -> Self {
        Self {
            id: self.id.clone(),
            symmetrical: self.symmetrical,
            reverse: !self.symmetrical && !self.reverse,
        }
    }

    pub fn is_compatible(&self, other: &Self) -> bool {
        self.id == other.id && ((self.reverse != other.reverse) || self.symmetrical)
    }
}

#[derive(Clone)]
pub struct TileImage<T, I: PartialEq + Clone> {
    image: Rc<Vec2D<T>>,
    pub transform: Transform,
    top: Edge<I>,
    right: Edge<I>,
    bottom: Edge<I>,
    left: Edge<I>,
}

impl<T: Copy, I: PartialEq + Clone> TileImage<T, I> {
    pub fn new(
        image: Vec2D<T>,
        top: Edge<I>,
        right: Edge<I>,
        bottom: Edge<I>,
        left: Edge<I>,
    ) -> Self {
        Self {
            image: Rc::new(image),
            transform: Transform::default(),
            top,
            right,
            bottom,
            left,
        }
    }

    pub fn mirrored(&self) -> Self {
        Self {
            image: self.image.clone(),
            transform: self.transform.mirror(),
            top: self.top.reversed(),
            right: self.left.reversed(),
            bottom: self.bottom.reversed(),
            left: self.right.reversed(),
        }
    }

    pub fn flipped(&self) -> Self {
        Self {
            image: self.image.clone(),
            transform: self.transform.flip(),
            top: self.bottom.reversed(),
            right: self.right.reversed(),
            bottom: self.top.reversed(),
            left: self.left.reversed(),
        }
    }

    pub fn rotated90(&self) -> Self {
        Self {
            image: self.image.clone(),
            transform: self.transform.rotate90(),
            top: self.left.clone(),
            right: self.top.clone(),
            bottom: self.right.clone(),
            left: self.bottom.clone(),
        }
    }

    pub fn rotated180(&self) -> Self {
        Self {
            image: self.image.clone(),
            transform: self.transform.rotate180(),
            top: self.bottom.clone(),
            right: self.left.clone(),
            bottom: self.top.clone(),
            left: self.right.clone(),
        }
    }

    pub fn rotated270(&self) -> Self {
        Self {
            image: self.image.clone(),
            transform: self.transform.rotate270(),
            top: self.right.clone(),
            right: self.bottom.clone(),
            bottom: self.left.clone(),
            left: self.top.clone(),
        }
    }

    pub fn right_edge(&self) -> &Edge<I> {
        &self.right
    }

    pub fn bottom_edge(&self) -> &Edge<I> {
        &self.bottom
    }

    pub fn left_edge(&self) -> &Edge<I> {
        &self.left
    }

    pub fn top_edge(&self) -> &Edge<I> {
        &self.top
    }

    pub fn size(&self) -> Size {
        match self.transform {
            Transform::Rotate0(_) => self.image.size(),
            Transform::Rotate90(_) => Size::new(self.image.size().height, self.image.size().width),
        }
    }

    pub fn get(&self, row: usize, column: usize) -> Option<&T> {
        match self.transform {
            Transform::Rotate0(_) => {
                let image_row = if self.transform.is_flipped() {
                    self.image.height().wrapping_sub(1).wrapping_sub(row)
                } else {
                    row
                };

                let image_column = if self.transform.is_mirrored() {
                    self.image.width().wrapping_sub(1).wrapping_sub(column)
                } else {
                    column
                };

                self.image.get(image_row, image_column)
            }
            Transform::Rotate90(_) => {
                let image_row = if self.transform.is_mirrored() {
                    column
                } else {
                    self.image.height().wrapping_sub(1).wrapping_sub(column)
                };

                let image_column = if self.transform.is_flipped() {
                    self.image.width().wrapping_sub(1).wrapping_sub(row)
                } else {
                    row
                };

                self.image.get(image_row, image_column)
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_edge_new() {
        let edge = Edge::new(1, true);
        assert_eq!(edge.id, 1);
        assert_eq!(edge.symmetrical, true);
        assert_eq!(edge.reverse, false);
    }

    #[test]
    fn test_edge_reversed() {
        let edge = Edge::new(1, true);
        let reversed = edge.reversed();
        assert_eq!(reversed.id, edge.id);
        assert_eq!(reversed.symmetrical, edge.symmetrical);
        assert_eq!(reversed.reverse, false);

        let edge = Edge::new(1, false);
        let reversed = edge.reversed();
        assert_eq!(reversed.id, edge.id);
        assert_eq!(reversed.symmetrical, edge.symmetrical);
        assert_eq!(reversed.reverse, true);
    }

    #[test]
    fn test_edge_equality() {
        let edge1 = Edge::new(1, true);
        let edge2 = Edge::new(1, true);
        assert_eq!(edge1, edge2);

        let edge1 = Edge::new(1, false);
        let edge2 = Edge::new(1, false);
        assert_eq!(edge1, edge2);

        let edge1 = Edge::new(1, false);
        let edge2 = Edge::new(2, false);
        assert_ne!(edge1, edge2);
    }

    #[test]
    fn test_edge_equality_with_reverse() {
        let edge1 = Edge::new(1, true);
        let edge2 = edge1.reversed();
        assert_eq!(edge1, edge2);

        let edge1 = Edge::new(1, false);
        let edge2 = edge1.reversed();
        assert_ne!(edge1, edge2);

        let edge1 = Edge::new(1, true);
        let edge2 = edge1.reversed().reversed();
        assert_eq!(edge1, edge2);
    }
}
