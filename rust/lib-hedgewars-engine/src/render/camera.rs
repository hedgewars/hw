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
            zoom: 1.0,
            size,
        }
    }

    pub fn viewport(&self) -> Rect {
        #[inline]
        fn scale(value: usize, zoom: f32) -> i32 {
            (value as f32 / zoom / 2.0) as i32
        }
        let half_width = scale(self.size.width, self.zoom);
        let half_height = scale(self.size.height, self.zoom);
        Rect::from_box(
            self.position.x - half_width,
            self.position.x + half_width,
            self.position.y - half_height,
            self.position.y + half_height,
        )
    }
}
