pub mod template_based;
pub mod outline_template;
mod outline;

extern crate integral_geometry;
extern crate land2d;
extern crate itertools;

pub struct LandGenerationParameters<T> {
    zero: T,
    basic: T,
}

impl <T: Copy + PartialEq> LandGenerationParameters<T> {
    pub fn new(zero: T, basic: T) -> Self {
        Self { zero, basic }
    }
}

pub trait LandGenerator {
    fn generate_land<T: Copy + PartialEq, I: Iterator<Item = u32>>(
        &self,
        parameters: LandGenerationParameters<T>,
        random_numbers: &mut I,
    ) -> land2d::Land2D<T>;
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
