mod outline;
pub mod outline_template;
pub mod template_based;

pub struct LandGenerationParameters<T> {
    zero: T,
    basic: T,
    distance_divisor: u32,
    skip_distort: bool,
    skip_bezier: bool,
}

impl<T: Copy + PartialEq> LandGenerationParameters<T> {
    pub fn new(zero: T, basic: T, distance_divisor: u32, skip_distort: bool, skip_bezier: bool) -> Self {
        Self {
            zero,
            basic,
            distance_divisor,
            skip_distort,
            skip_bezier,
        }
    }
}

pub trait LandGenerator {
    fn generate_land<T: Copy + PartialEq, I: Iterator<Item = u32>>(
        &self,
        parameters: &LandGenerationParameters<T>,
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
