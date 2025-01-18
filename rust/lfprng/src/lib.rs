use rand::{Error, RngCore, SeedableRng};

pub struct LaggedFibonacciPRNG {
    circular_buffer: [u32; 64],
    index: usize,
}

impl LaggedFibonacciPRNG {
    pub fn new(init_values: &[u8]) -> Self {
        let mut buf = [0xa98765; 64];

        for i in 0..std::cmp::min(init_values.len(), 54) {
            buf[i] = init_values[i] as u32;
        }

        let mut prng = Self {
            circular_buffer: buf,
            index: 0,
        };

        prng.discard(2048);

        prng
    }

    #[inline]
    pub fn discard(&mut self, count: usize) {
        for _i in 0..count {
            self.get_next();
        }
    }

    #[inline]
    fn get_next(&mut self) -> u32 {
        self.index = (self.index + 1) & 0x3f;
        let next_value = self.circular_buffer[(self.index + 40) & 0x3f]
            .wrapping_add(self.circular_buffer[(self.index + 9) & 0x3f]);

        self.circular_buffer[self.index] = next_value;

        next_value
    }

    #[inline]
    pub fn get_random(&mut self, modulo: u32) -> u32 {
        self.get_next();
        self.get_next() % modulo
    }

    #[inline]
    pub fn add_randomness(&mut self, value: u32) {
        self.index = (self.index + 1) & 0x3f;
        self.circular_buffer[self.index] ^= value;
    }
}

impl Iterator for LaggedFibonacciPRNG {
    type Item = u32;

    fn next(&mut self) -> Option<Self::Item> {
        self.get_next();
        Some(self.get_next())
    }
}

impl RngCore for LaggedFibonacciPRNG {
    fn next_u32(&mut self) -> u32 {
        self.get_next().wrapping_add(self.get_next())
    }

    fn next_u64(&mut self) -> u64 {
        ((self.next_u32() as u64) << 32) | self.next_u32() as u64
    }

    fn fill_bytes(&mut self, dest: &mut [u8]) {
        dest.iter_mut().for_each(|x| *x = self.next_u32() as u8);
    }

    fn try_fill_bytes(&mut self, dest: &mut [u8]) -> Result<(), Error> {
        Ok(self.fill_bytes(dest))
    }
}

impl SeedableRng for LaggedFibonacciPRNG {
    type Seed = [u8; 32];

    fn from_seed(seed: Self::Seed) -> Self {
        LaggedFibonacciPRNG::new(&seed)
    }
}

#[cfg(test)]
#[test]
fn compatibility() {
    let mut prng = LaggedFibonacciPRNG::new("{052e2aee-ce41-4720-97bd-559a413bf866}".as_bytes());

    assert_eq!(prng.get_random(1000), 145);
    assert_eq!(prng.get_random(1000000), 385411);
    assert_eq!(prng.get_random(0xffffffff), 3099784309);

    prng.add_randomness(123);

    for _ in 0..=100000 {
        prng.get_random(2);
    }

    assert_eq!(prng.get_random(0xffffffff), 633923935);
}
