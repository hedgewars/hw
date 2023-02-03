use super::transform::RotationTransform;
use std::rc::Rc;
use vec2d::Vec2D;

#[derive(PartialEq, Clone)]
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
}

#[derive(Clone)]
pub struct TileImage<T, I: PartialEq + Clone> {
    image: Rc<Vec2D<T>>,
    transform: RotationTransform,
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
            transform: RotationTransform::default(),
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
            transform: self.transform.rotate90(),
            top: self.bottom.clone(),
            right: self.left.clone(),
            bottom: self.top.clone(),
            left: self.right.clone(),
        }
    }

    pub fn rotated270(&self) -> Self {
        Self {
            image: self.image.clone(),
            transform: self.transform.rotate90(),
            top: self.left.clone(),
            right: self.top.clone(),
            bottom: self.right.clone(),
            left: self.bottom.clone(),
        }
    }
}

#[cfg(test)]
mod tests {}
