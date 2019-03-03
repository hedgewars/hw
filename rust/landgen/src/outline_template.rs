use integral_geometry::{Point, Rect, Size};

#[derive(Clone, Debug)]
pub struct OutlineTemplate {
    pub islands: Vec<Vec<Rect>>,
    pub fill_points: Vec<Point>,
    pub size: Size,
    pub can_flip: bool,
    pub can_invert: bool,
    pub can_mirror: bool,
    pub is_negative: bool,
}

impl OutlineTemplate {
    pub fn new(size: Size) -> Self {
        OutlineTemplate {
            size,
            islands: Vec::new(),
            fill_points: Vec::new(),
            can_flip: false,
            can_invert: false,
            can_mirror: false,
            is_negative: false,
        }
    }

    pub fn flippable(self) -> Self {
        Self {
            can_flip: true,
            ..self
        }
    }

    pub fn mirrorable(self) -> Self {
        Self {
            can_mirror: true,
            ..self
        }
    }

    pub fn invertable(self) -> Self {
        Self {
            can_invert: true,
            ..self
        }
    }

    pub fn negative(self) -> Self {
        Self {
            is_negative: true,
            ..self
        }
    }

    pub fn with_fill_points(self, fill_points: Vec<Point>) -> Self {
        Self {
            fill_points,
            ..self
        }
    }

    pub fn with_islands(self, islands: Vec<Vec<Rect>>) -> Self {
        Self { islands, ..self }
    }

    pub fn add_fill_points(mut self, points: &[Point]) -> Self {
        self.fill_points.extend_from_slice(points);
        self
    }

    pub fn add_island(mut self, island: &[Rect]) -> Self {
        self.islands.push(island.into());
        self
    }
}
