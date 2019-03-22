use integral_geometry::{Point, Rect, Size};

#[derive(Debug)]
pub struct Camera {
    pub position: Point,
    pub zoom: f32,
    size: Size,
}

impl Camera {
    pub fn new() -> Self {
        Self::with_size(Size::new(1024, 768))
    }

    pub fn with_size(size: Size) -> Self {
        Self {
            position: Point::ZERO,
            zoom: 0.0,
            size,
        }
    }

    pub fn viewport(&self) -> Rect {
        Rect::from_size(self.position, self.size)
    }
}
