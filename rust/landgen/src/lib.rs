mod template_based;

extern crate integral_geometry;
extern crate land2d;
extern crate itertools;

pub struct LandGenerationParameters<T> {
    zero: T,
    basic: T,
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
