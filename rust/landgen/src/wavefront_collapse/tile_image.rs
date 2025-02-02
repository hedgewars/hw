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
    #[inline]
    pub fn new(id: I, symmetrical: bool) -> Self {
        Self {
            id,
            symmetrical,
            reverse: false,
        }
    }

    #[inline]
    pub fn reversed(&self) -> Self {
        Self {
            id: self.id.clone(),
            symmetrical: self.symmetrical,
            reverse: !self.symmetrical && !self.reverse,
        }
    }

    #[inline]
    pub fn is_compatible(&self, other: &Self) -> bool {
        self.id == other.id && ((self.reverse != other.reverse) || self.symmetrical)
    }
}

impl Edge<String> {
    pub fn name(&self) -> String {
        if self.reverse {
            self.id.chars().rev().collect()
        } else {
            self.id.clone()
        }
    }
}

#[derive(PartialEq, Clone, Debug)]
pub struct EdgeSet<I: PartialEq + Clone>([Edge<I>; 4]);

impl<I: PartialEq + Clone> EdgeSet<I> {
    pub fn new(edge_set: [Edge<I>; 4]) -> Self {
        Self(edge_set)
    }

    pub fn top(&self) -> &Edge<I> {
        &self.0[0]
    }

    pub fn right(&self) -> &Edge<I> {
        &self.0[1]
    }

    pub fn bottom(&self) -> &Edge<I> {
        &self.0[2]
    }

    pub fn left(&self) -> &Edge<I> {
        &self.0[3]
    }

    pub fn mirrored(&self) -> Self {
        Self([
            self.0[0].reversed(),
            self.0[3].reversed(),
            self.0[2].reversed(),
            self.0[1].reversed(),
        ])
    }

    pub fn flipped(&self) -> Self {
        Self([
            self.0[2].reversed(),
            self.0[1].reversed(),
            self.0[0].reversed(),
            self.0[3].reversed(),
        ])
    }

    pub fn rotated90(&self) -> Self {
        Self([
            self.0[3].clone(),
            self.0[0].clone(),
            self.0[1].clone(),
            self.0[2].clone(),
        ])
    }

    pub fn rotated180(&self) -> Self {
        Self([
            self.0[2].clone(),
            self.0[3].clone(),
            self.0[0].clone(),
            self.0[1].clone(),
        ])
    }

    pub fn rotated270(&self) -> Self {
        Self([
            self.0[1].clone(),
            self.0[2].clone(),
            self.0[3].clone(),
            self.0[0].clone(),
        ])
    }
}

#[derive(PartialEq, Clone, Debug)]
pub enum MatchSide {
    OnTop,
    OnRight,
    OnBottom,
    OnLeft,
}
#[derive(Clone)]
pub struct TileImage<T, I: PartialEq + Clone> {
    image: Rc<Vec2D<T>>,
    pub weight: u8,
    pub transform: Transform,
    edges: EdgeSet<I>,
    anti_match: [u64; 4],
}

impl<T: Copy, I: PartialEq + Clone> TileImage<T, I> {
    pub fn new(image: Vec2D<T>, weight: u8, edges: EdgeSet<I>, anti_match: [u64; 4]) -> Self {
        Self {
            image: Rc::new(image),
            weight,
            transform: Transform::default(),
            edges,
            anti_match,
        }
    }

    pub fn is_compatible(&self, other: &Self, direction: MatchSide) -> bool {
        match direction {
            MatchSide::OnTop => {
                self.anti_match[0] & other.anti_match[2] == 0
                    && self
                        .edge_set()
                        .top()
                        .is_compatible(other.edge_set().bottom())
            }
            MatchSide::OnRight => {
                self.anti_match[1] & other.anti_match[3] == 0
                    && self
                        .edge_set()
                        .right()
                        .is_compatible(other.edge_set().left())
            }
            MatchSide::OnBottom => {
                self.anti_match[2] & other.anti_match[0] == 0
                    && self
                        .edge_set()
                        .bottom()
                        .is_compatible(other.edge_set().top())
            }
            MatchSide::OnLeft => {
                self.anti_match[3] & other.anti_match[1] == 0
                    && self
                        .edge_set()
                        .left()
                        .is_compatible(other.edge_set().right())
            }
        }
    }

    pub fn mirrored(&self) -> Self {
        Self {
            image: self.image.clone(),
            weight: self.weight,
            transform: self.transform.mirror(),
            edges: self.edges.mirrored(),
            anti_match: [
                self.anti_match[0],
                self.anti_match[3],
                self.anti_match[2],
                self.anti_match[1],
            ],
        }
    }

    pub fn flipped(&self) -> Self {
        Self {
            image: self.image.clone(),
            weight: self.weight,
            transform: self.transform.flip(),
            edges: self.edges.flipped(),
            anti_match: [
                self.anti_match[2],
                self.anti_match[1],
                self.anti_match[0],
                self.anti_match[3],
            ],
        }
    }

    pub fn rotated90(&self) -> Self {
        Self {
            image: self.image.clone(),
            weight: self.weight,
            transform: self.transform.rotate90(),
            edges: self.edges.rotated90(),
            anti_match: [
                self.anti_match[3],
                self.anti_match[0],
                self.anti_match[1],
                self.anti_match[2],
            ],
        }
    }

    pub fn rotated180(&self) -> Self {
        Self {
            image: self.image.clone(),
            weight: self.weight,
            transform: self.transform.rotate180(),
            edges: self.edges.rotated180(),
            anti_match: [
                self.anti_match[2],
                self.anti_match[3],
                self.anti_match[0],
                self.anti_match[1],
            ],
        }
    }

    pub fn rotated270(&self) -> Self {
        Self {
            image: self.image.clone(),
            weight: self.weight,
            transform: self.transform.rotate270(),
            edges: self.edges.rotated270(),
            anti_match: [
                self.anti_match[1],
                self.anti_match[2],
                self.anti_match[3],
                self.anti_match[0],
            ],
        }
    }

    #[inline]
    pub fn edge_set(&self) -> &EdgeSet<I> {
        &self.edges
    }

    #[inline]
    pub fn size(&self) -> Size {
        match self.transform {
            Transform::Rotate0(_) => self.image.size(),
            Transform::Rotate90(_) => Size::new(self.image.size().height, self.image.size().width),
        }
    }

    #[inline]
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
