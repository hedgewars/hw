#[derive(Debug, PartialEq, Clone, Copy)]
pub enum SymmetryTransform {
    Id,
    Flip,
    Mirror,
    FlipMirror,
}

#[derive(Debug, PartialEq, Clone, Copy)]
pub enum RotationTransform {
    Rotate0(SymmetryTransform),
    Rotate90(SymmetryTransform),
    Rotate180(SymmetryTransform),
    Rotate270(SymmetryTransform),
}

impl Default for RotationTransform {
    fn default() -> Self {
        RotationTransform::Rotate0(SymmetryTransform::Id)
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
}

impl RotationTransform {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn mirror(self) -> RotationTransform {
        match self {
            RotationTransform::Rotate0(s) => RotationTransform::Rotate0(s.mirror()),
            RotationTransform::Rotate90(s) => RotationTransform::Rotate270(s.mirror()).simplified(),
            RotationTransform::Rotate180(s) => {
                RotationTransform::Rotate180(s.mirror()).simplified()
            }
            RotationTransform::Rotate270(s) => RotationTransform::Rotate90(s.mirror()),
        }
    }

    pub fn flip(self) -> RotationTransform {
        match self {
            RotationTransform::Rotate0(s) => RotationTransform::Rotate0(s.flip()),
            RotationTransform::Rotate90(s) => RotationTransform::Rotate90(s.flip()),
            RotationTransform::Rotate180(s) => RotationTransform::Rotate180(s.flip()).simplified(),
            RotationTransform::Rotate270(s) => RotationTransform::Rotate270(s.flip()).simplified(),
        }
    }

    pub fn rotate90(self) -> RotationTransform {
        match self {
            RotationTransform::Rotate0(s) => RotationTransform::Rotate90(s),
            RotationTransform::Rotate90(s) => RotationTransform::Rotate180(s).simplified(),
            RotationTransform::Rotate180(s) => RotationTransform::Rotate270(s).simplified(),
            RotationTransform::Rotate270(s) => RotationTransform::Rotate0(s),
        }
    }

    pub fn rotate180(self) -> RotationTransform {
        match self {
            RotationTransform::Rotate0(s) => RotationTransform::Rotate180(s).simplified(),
            RotationTransform::Rotate90(s) => RotationTransform::Rotate270(s).simplified(),
            RotationTransform::Rotate180(s) => RotationTransform::Rotate0(s),
            RotationTransform::Rotate270(s) => RotationTransform::Rotate90(s),
        }
    }

    pub fn rotate270(self) -> RotationTransform {
        match self {
            RotationTransform::Rotate0(s) => RotationTransform::Rotate270(s).simplified(),
            RotationTransform::Rotate90(s) => RotationTransform::Rotate0(s),
            RotationTransform::Rotate180(s) => RotationTransform::Rotate90(s),
            RotationTransform::Rotate270(s) => RotationTransform::Rotate180(s).simplified(),
        }
    }

    fn simplified(self) -> Self {
        match self {
            RotationTransform::Rotate0(s) => RotationTransform::Rotate0(s),
            RotationTransform::Rotate90(s) => RotationTransform::Rotate90(s),
            RotationTransform::Rotate180(s) => RotationTransform::Rotate0(s.flip().mirror()),
            RotationTransform::Rotate270(s) => RotationTransform::Rotate90(s.flip().mirror()),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::{RotationTransform::*, SymmetryTransform::*, *};

    // I totally wrote all of this myself and didn't use ChatGPT
    #[test]
    fn test_default() {
        let rt = RotationTransform::new();
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
        let rt = Rotate180(Mirror);
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
        let rt = Rotate180(Flip);
        let rotated = rt.rotate270();
        assert_eq!(rotated, Rotate90(Flip));
    }

    #[test]
    fn test_simplified() {
        let rt = Rotate180(Id);
        let simplified = rt.simplified();
        assert_eq!(simplified, Rotate0(FlipMirror));
    }

    #[test]
    fn test_rotation_chain() {
        assert_eq!(
            RotationTransform::default(),
            RotationTransform::default()
                .rotate90()
                .rotate90()
                .rotate90()
                .rotate90()
        );
        assert_eq!(
            RotationTransform::default().rotate90(),
            RotationTransform::default()
                .rotate180()
                .rotate90()
                .rotate180()
        );
        assert_eq!(
            RotationTransform::default().rotate180(),
            RotationTransform::default()
                .rotate180()
                .rotate270()
                .rotate90()
        );
    }

    #[test]
    fn test_combinations_chain() {
        assert_eq!(
            RotationTransform::default(),
            RotationTransform::default()
                .flip()
                .rotate180()
                .flip()
                .rotate180()
        );
        assert_eq!(
            RotationTransform::default(),
            RotationTransform::default()
                .mirror()
                .rotate180()
                .mirror()
                .rotate180()
        );
        assert_eq!(
            RotationTransform::default(),
            RotationTransform::default()
                .rotate90()
                .flip()
                .rotate90()
                .mirror()
        );
    }
}
