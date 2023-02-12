#[derive(Debug, PartialEq, Clone, Copy)]
pub enum SymmetryTransform {
    Id,
    Flip,
    Mirror,
    FlipMirror,
}

#[derive(Debug, PartialEq, Clone, Copy)]
pub enum Transform {
    Rotate0(SymmetryTransform),
    Rotate90(SymmetryTransform),
}

impl Default for Transform {
    fn default() -> Self {
        Transform::Rotate0(SymmetryTransform::Id)
    }
}

impl SymmetryTransform {
    pub fn mirror(&self) -> Self {
        use SymmetryTransform::*;
        match self {
            Id => Mirror,
            Flip => FlipMirror,
            Mirror => Id,
            FlipMirror => Flip,
        }
    }

    pub fn flip(&self) -> Self {
        use SymmetryTransform::*;
        match self {
            Id => Flip,
            Flip => Id,
            Mirror => FlipMirror,
            FlipMirror => Mirror,
        }
    }

    pub fn is_mirrored(&self) -> bool {
        match self {
            Id => false,
            Flip => false,
            Mirror => true,
            FlipMirror => true,
        }
    }

    pub fn is_flipped(&self) -> bool {
        match self {
            Id => false,
            Flip => true,
            Mirror => false,
            FlipMirror => true,
        }
    }
}

impl Transform {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn mirror(self) -> Transform {
        match self {
            Transform::Rotate0(s) => Transform::Rotate0(s.mirror()),
            Transform::Rotate90(s) => Transform::Rotate90(s.flip()),
        }
    }

    pub fn flip(self) -> Transform {
        match self {
            Transform::Rotate0(s) => Transform::Rotate0(s.flip()),
            Transform::Rotate90(s) => Transform::Rotate90(s.mirror()),
        }
    }

    pub fn rotate90(self) -> Transform {
        match self {
            Transform::Rotate0(s) => Transform::Rotate90(s),
            Transform::Rotate90(s) => Transform::Rotate0(s.flip().mirror()),
        }
    }

    pub fn rotate180(self) -> Transform {
        match self {
            Transform::Rotate0(s) => Transform::Rotate0(s.flip().mirror()),
            Transform::Rotate90(s) => Transform::Rotate90(s.flip().mirror()),
        }
    }

    pub fn rotate270(self) -> Transform {
        match self {
            Transform::Rotate0(s) => Transform::Rotate90(s.flip().mirror()),
            Transform::Rotate90(s) => Transform::Rotate0(s),
        }
    }

    pub fn is_mirrored(&self) -> bool {
        match self {
            Transform::Rotate0(s) => s.is_mirrored(),
            Transform::Rotate90(s) => s.is_mirrored(),
        }
    }

    pub fn is_flipped(&self) -> bool {
        match self {
            Transform::Rotate0(s) => s.is_flipped(),
            Transform::Rotate90(s) => s.is_flipped(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::{SymmetryTransform::*, Transform::*, *};

    // I totally wrote all of this myself and didn't use ChatGPT
    #[test]
    fn test_default() {
        let rt = Transform::new();
        assert_eq!(rt, Rotate0(Id));
    }

    #[test]
    fn test_mirror() {
        let rt = Rotate90(Flip);
        let mirrored = rt.mirror();
        assert_eq!(mirrored, Rotate90(Id));
    }

    #[test]
    fn test_flip() {
        let rt = Transform::new().rotate180().mirror();
        let flipped = rt.flip();
        assert_eq!(flipped, Rotate0(Id));
    }

    #[test]
    fn test_rotate90() {
        let rt = Rotate0(Id);
        let rotated = rt.rotate90();
        assert_eq!(rotated, Rotate90(Id));
    }

    #[test]
    fn test_rotate180() {
        let rt = Rotate90(Mirror);
        let rotated = rt.rotate180();
        assert_eq!(rotated, Rotate90(Flip));
    }

    #[test]
    fn test_rotate270() {
        let rt = Transform::new().rotate180().flip();
        let rotated = rt.rotate270();
        assert_eq!(rotated, Rotate90(Flip));
    }

    #[test]
    fn test_rotate180_2() {
        let rt = Transform::new().rotate180();
        assert_eq!(rt, Rotate0(FlipMirror));
    }

    #[test]
    fn test_rotation_chain() {
        assert_eq!(
            Transform::default(),
            Transform::default()
                .rotate90()
                .rotate90()
                .rotate90()
                .rotate90()
        );
        assert_eq!(
            Transform::default().rotate90(),
            Transform::default().rotate180().rotate90().rotate180()
        );
        assert_eq!(
            Transform::default().rotate180(),
            Transform::default().rotate180().rotate270().rotate90()
        );
    }

    #[test]
    fn test_combinations_chain() {
        assert_eq!(
            Transform::default(),
            Transform::default().flip().rotate180().flip().rotate180()
        );
        assert_eq!(
            Transform::default(),
            Transform::default()
                .mirror()
                .rotate180()
                .mirror()
                .rotate180()
        );
        assert_eq!(
            Transform::default(),
            Transform::default().rotate90().flip().rotate90().mirror().rotate180()
        );
    }
}
