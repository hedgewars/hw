use land2d::Land2D;
use std::rc::Rc;

pub struct TileImage {
    image: Rc<Land2D<u8>>,
    flip: bool,
    mirror: bool,
}

impl TileImage {
    pub fn new(flip: bool, mirror: bool) -> Self {
        Self {
            image: todo!(),
            flip,
            mirror,
        }
    }

    pub fn mirrored(&self) -> Self {
        Self {
            image: self.image.clone(),
            flip: self.flip,
            mirror: !self.mirror
        }
    }

    pub fn flipped(&self) -> Self {
        Self {
            image: self.image.clone(),
            flip: !self.flip,
            mirror: self.mirror
        }
    }
}
