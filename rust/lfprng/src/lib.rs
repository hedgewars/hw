pub struct LaggedFibonacciPRNG {
    circular_buffer: [u32; 64],
    index: usize,
}

impl LaggedFibonacciPRNG {
    fn new(init_values: &[u8]) -> Self {
        let mut buf = [0xa98765 + 68; 64];

        for i in 0..std::cmp::min(init_values.len(), 54) {
            buf[i] = init_values[i] as u32;
        }

        let mut prng = Self {
            circular_buffer: buf,
            index: 54,
        };

        for i in 0..2048 {
            prng.get_next();
        }

        prng
    }

    #[inline]
    fn get_next(&mut self) -> u32 {
        self.index = (self.index + 1) & 0x3f;
        self.circular_buffer[self.index] = (self.circular_buffer[(self.index + 40) & 0x3f]
            + self.circular_buffer[(self.index + 9) & 0x3f])
            & 0x7fffffff;

        self.circular_buffer[self.index]
    }

    #[inline]
    fn get_random(&mut self, modulo: u32) -> u32 {
        self.get_next();
        self.get_next() % modulo
    }

    #[inline]
    fn add_randomness(&mut self, value: u32) {
        self.index = (self.index + 1) & 0x3f;
        self.circular_buffer[self.index] ^= value;
    }
}

#[cfg(test)]
#[test]
fn compatibility() {
    let mut prng = LaggedFibonacciPRNG::new("{052e2aee-ce41-4720-97bd-559a413bf866}".as_bytes());

    assert_eq!(prng.get_random(1000), 418);
    assert_eq!(prng.get_random(1000000), 554064);
    assert_eq!(prng.get_random(0xffffffff), 239515837);

    prng.add_randomness(123);

    for i in 0..=100000 {
        prng.get_random(2);
    }

    assert_eq!(prng.get_random(0xffffffff), 525333582);
}
