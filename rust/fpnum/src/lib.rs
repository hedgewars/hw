use std::{cmp, ops};
use std::marker::PhantomData;
use saturate::SaturatingInto;

const POSITIVE_MASK: u64 = 0x0000_0000_0000_0000;
const NEGATIVE_MASK: u64 = 0xFFFF_FFFF_FFFF_FFFF;

#[inline]
fn bool_mask(is_negative: bool) -> u64 {
    if is_negative {
        NEGATIVE_MASK
    } else {
        POSITIVE_MASK
    }
}

struct FracBits<const N: u8>;
#[derive(Clone, Debug, Copy)]
pub struct FixedPoint<const FRAC_BITS: u8> {
    sign_mask: u64,
    value: u64,
    _marker: PhantomData<FracBits<FRAC_BITS>>,
}

pub type FPNum = FixedPoint<20>;

impl<const FRAC_BITS: u8> FixedPoint<FRAC_BITS> {
    #[inline]
    pub fn new(numerator: i32, denominator: u32) -> Self {
        Self::from(numerator) / denominator
    }

    #[inline]
    pub fn signum(&self) -> i8 {
        (1u64 ^ self.sign_mask).wrapping_sub(self.sign_mask) as i8
    }

    #[inline]
    pub const fn is_negative(&self) -> bool {
        self.sign_mask != POSITIVE_MASK
    }

    #[inline]
    pub const fn is_positive(&self) -> bool {
        self.sign_mask == POSITIVE_MASK
    }

    #[inline]
    pub const fn is_zero(&self) -> bool {
        self.value == 0
    }

    #[inline]
    pub const fn abs(&self) -> Self {
        Self {
            sign_mask: POSITIVE_MASK,
            value: self.value,
            _marker: self._marker,
        }
    }

    #[inline]
    pub fn round(&self) -> i64 {
        ((self.value >> FRAC_BITS) as i64 ^ self.sign_mask as i64).wrapping_sub(self.sign_mask as i64)
    }

    #[inline]
    pub const fn abs_round(&self) -> u64 {
        self.value >> FRAC_BITS
    }

    #[inline]
    pub fn sqr(&self) -> Self {
        Self {
            sign_mask: 0,
            value: ((self.value as u128).pow(2) >> FRAC_BITS).saturating_into(),
            _marker: self._marker
        }
    }

    #[inline]
    pub fn sqrt(&self) -> Self {
        debug_assert!(self.is_positive());

        Self {
            sign_mask: POSITIVE_MASK,
            value: integral_sqrt(self.value) << (FRAC_BITS / 2),
            _marker: self._marker
        }
    }

    #[inline]
    pub fn with_sign(&self, is_negative: bool) -> Self {
        Self {
            sign_mask: bool_mask(is_negative),
            ..*self
        }
    }

    #[inline]
    pub const fn with_sign_as(self, other: Self) -> Self {
        Self {
            sign_mask: other.sign_mask,
            ..self
        }
    }
/*
    #[inline]
    pub const fn point(self) -> FPPoint {
        FPPoint::new(self, self)
    }
*/
    #[inline]
    const fn temp_i128(self) -> i128 {
        ((self.value ^ self.sign_mask) as i128).wrapping_sub(self.sign_mask as i128)
    }
}

impl<const FRAC_BITS: u8> From<i32> for FixedPoint<FRAC_BITS> {
    #[inline]
    fn from(n: i32) -> Self {
        Self {
            sign_mask: bool_mask(n < 0),
            value: (n.abs() as u64) << FRAC_BITS,
            _marker: PhantomData,
        }
    }
}

impl<const FRAC_BITS: u8> From<u32> for FixedPoint<FRAC_BITS> {
    #[inline]
    fn from(n: u32) -> Self {
        Self {
            sign_mask: POSITIVE_MASK,
            value: (n as u64) << FRAC_BITS,
            _marker: PhantomData,
        }
    }
}

impl<const FRAC_BITS: u8> From<FixedPoint<FRAC_BITS>> for f64 {
    #[inline]
    fn from(n: FixedPoint<FRAC_BITS>) -> Self {
        if n.is_negative() {
            n.value as f64 / -(1i64 << FRAC_BITS) as f64
        } else {
            n.value as f64 / (1i64 << FRAC_BITS) as f64
        }
    }
}

impl<const FRAC_BITS: u8> PartialEq for FixedPoint<FRAC_BITS> {
    #[inline]
    fn eq(&self, other: &Self) -> bool {
        self.value == other.value && (self.sign_mask == other.sign_mask || self.value == 0)
    }
}

impl<const FRAC_BITS: u8> Eq for FixedPoint<FRAC_BITS> {}

impl<const FRAC_BITS: u8> PartialOrd for FixedPoint<FRAC_BITS> {
    #[inline]
    fn partial_cmp(&self, rhs: &Self) -> Option<cmp::Ordering> {
        Some(self.cmp(rhs))
    }
}

impl<const FRAC_BITS: u8> Ord for FixedPoint<FRAC_BITS> {
    #[inline]
    fn cmp(&self, rhs: &Self) -> cmp::Ordering {
        self.temp_i128().cmp(&(rhs.temp_i128()))
    }
}

impl<const FRAC_BITS: u8> ops::Add for FixedPoint<FRAC_BITS> {
    type Output = Self;

    #[inline]
    fn add(self, rhs: Self) -> Self {
        let tmp = self.temp_i128() + rhs.temp_i128();
        let mask = bool_mask(tmp < 0);
        Self {
            sign_mask: mask,
            value: ((tmp as u64) ^ mask).wrapping_sub(mask),
            _marker: PhantomData,
        }
    }
}

impl<const FRAC_BITS: u8> ops::Sub for FixedPoint<FRAC_BITS> {
    type Output = Self;

    #[inline]
    fn sub(self, mut rhs: Self) -> Self {
        rhs.sign_mask = !rhs.sign_mask;
        self + rhs
    }
}

impl<const FRAC_BITS: u8> ops::Neg for FixedPoint<FRAC_BITS> {
    type Output = Self;

    #[inline]
    fn neg(self) -> Self {
        Self {
            sign_mask: !self.sign_mask,
            value: self.value,
            _marker: PhantomData,
        }
    }
}

impl<const FRAC_BITS: u8> ops::Mul for FixedPoint<FRAC_BITS> {
    type Output = Self;

    #[inline]
    fn mul(self, rhs: Self) -> Self {
        Self {
            sign_mask: self.sign_mask ^ rhs.sign_mask,
            value: ((self.value as u128 * rhs.value as u128) >> FRAC_BITS).saturating_into(),
            _marker: PhantomData,
        }
    }
}

impl<const FRAC_BITS: u8> ops::Mul<i32> for FixedPoint<FRAC_BITS> {
    type Output = Self;

    #[inline]
    fn mul(self, rhs: i32) -> Self {
        Self {
            sign_mask: self.sign_mask ^ bool_mask(rhs < 0),
            value: (self.value as u128 * rhs.abs() as u128).saturating_into(),
            _marker: PhantomData,
        }
    }
}

impl<const FRAC_BITS: u8> ops::Div for FixedPoint<FRAC_BITS> {
    type Output = Self;

    #[inline]
    fn div(self, rhs: Self) -> Self {
        Self {
            sign_mask: self.sign_mask ^ rhs.sign_mask,
            value: (((self.value as u128) << FRAC_BITS) / rhs.value as u128).saturating_into(),
            _marker: PhantomData,
        }
    }
}

impl<const FRAC_BITS: u8> ops::Div<i32> for FixedPoint<FRAC_BITS> {
    type Output = Self;

    #[inline]
    fn div(self, rhs: i32) -> Self {
        Self {
            sign_mask: self.sign_mask ^ bool_mask(rhs < 0),
            value: self.value / rhs.abs() as u64,
            _marker: PhantomData,
        }
    }
}

impl<const FRAC_BITS: u8> ops::Div<u32> for FixedPoint<FRAC_BITS> {
    type Output = Self;

    #[inline]
    fn div(self, rhs: u32) -> Self {
        Self {
            sign_mask: self.sign_mask,
            value: self.value / rhs as u64,
            _marker: PhantomData,
        }
    }
}

#[macro_export]
macro_rules! fp {
    ($n: literal / $d: tt) => {
        FPNum::new($n, $d)
    };
    ($n: literal) => {
        FPNum::from($n)
    };
}

const LINEARIZE_TRESHOLD: u64 = 0x1_0000;

#[derive(Clone, Copy, Debug)]
pub struct FPPoint {
    x_sign_mask: u32,
    y_sign_mask: u32,
    x_value: u64,
    y_value: u64,
}

impl FPPoint {
    #[inline]
    pub const fn new(x: FPNum, y: FPNum) -> Self {
        Self {
            x_sign_mask: x.sign_mask as u32,
            y_sign_mask: y.sign_mask as u32,
            x_value: x.value,
            y_value: y.value,
        }
    }

    #[inline]
    pub fn zero() -> FPPoint {
        FPPoint::new(fp!(0), fp!(0))
    }

    #[inline]
    pub fn unit_x() -> FPPoint {
        FPPoint::new(fp!(1), fp!(0))
    }

    #[inline]
    pub fn unit_y() -> FPPoint {
        FPPoint::new(fp!(0), fp!(1))
    }

    #[inline]
    pub const fn x(&self) -> FPNum {
        FPNum {
            sign_mask: self.x_sign_mask as i32 as u64,
            value: self.x_value,
            _marker: PhantomData,
        }
    }

    #[inline]
    pub const fn y(&self) -> FPNum {
        FPNum {
            sign_mask: self.y_sign_mask as i32 as u64,
            value: self.y_value,
            _marker: PhantomData,
        }
    }

    #[inline]
    pub fn is_zero(&self) -> bool {
        self.x().is_zero() && self.y().is_zero()
    }

    #[inline]
    pub fn max_norm(&self) -> FPNum {
        cmp::max(self.x().abs(), self.y().abs())
    }

    #[inline]
    pub fn sqr_distance(&self) -> FPNum {
        self.x().sqr() + self.y().sqr()
    }

    #[inline]
    pub fn distance(&self) -> FPNum {
        let r = self.x_value | self.y_value;
        if r < LINEARIZE_TRESHOLD {
            FPNum::from(r as u32)
        } else {
            let sqr: u128 = (self.x_value as u128).pow(2) + (self.y_value as u128).pow(2);

            FPNum {
                sign_mask: POSITIVE_MASK,
                value: integral_sqrt_ext(sqr),
                _marker: PhantomData,
            }
        }
    }

    #[inline]
    pub fn is_in_range(&self, radius: FPNum) -> bool {
        self.max_norm() < radius && self.sqr_distance() < radius.sqr()
    }

    #[inline]
    pub fn dot(&self, other: &FPPoint) -> FPNum {
        self.x() * other.x() + self.y() * other.y()
    }
}

impl PartialEq for FPPoint {
    #[inline]
    fn eq(&self, other: &Self) -> bool {
        self.x() == other.x() && self.y() == other.y()
    }
}

impl Eq for FPPoint {}

impl ops::Neg for FPPoint {
    type Output = Self;

    #[inline]
    fn neg(self) -> Self {
        Self::new(-self.x(), -self.y())
    }
}

macro_rules! bin_op_impl {
    ($op: ty, $name: tt) => {
        impl $op for FPPoint {
            type Output = Self;

            #[inline]
            fn $name(self, rhs: Self) -> Self {
                Self::new(self.x().$name(rhs.x()), self.y().$name(rhs.y()))
            }
        }
    };
}

macro_rules! right_scalar_bin_op_impl {
    ($($op: tt)::+, $name: tt) => {
        impl $($op)::+<FPNum> for FPPoint {
            type Output = Self;

            #[inline]
            fn $name(self, rhs: FPNum) -> Self {
                Self::new(self.x().$name(rhs),
                          self.y().$name(rhs))
            }
        }
    };
    ($($op: tt)::+<$arg: tt>, $name: tt) => {
        impl $($op)::+<$arg> for FPPoint {
            type Output = Self;

            #[inline]
            fn $name(self, rhs: $arg) -> Self {
                Self::new(self.x().$name(rhs),
                          self.y().$name(rhs))
            }
        }
    }
}

macro_rules! left_scalar_bin_op_impl {
    ($($op: tt)::+, $name: tt) => {
        impl $($op)::+<FPPoint> for FPNum {
            type Output = FPPoint;

            #[inline]
            fn $name(self, rhs: FPPoint) -> Self::Output {
                Self::Output::new(self.$name(rhs.x()),
                                  self.$name(rhs.y()))
            }
        }
    }
}

bin_op_impl!(ops::Add, add);
bin_op_impl!(ops::Sub, sub);
bin_op_impl!(ops::Mul, mul);
bin_op_impl!(ops::Div, div);
right_scalar_bin_op_impl!(ops::Add, add);
right_scalar_bin_op_impl!(ops::Mul, mul);
right_scalar_bin_op_impl!(ops::Sub, sub);
right_scalar_bin_op_impl!(ops::Div, div);
right_scalar_bin_op_impl!(ops::Div<u32>, div);
left_scalar_bin_op_impl!(ops::Mul, mul);

macro_rules! bin_assign_op_impl {
    ($typ: tt, $($op: tt)::+, $name: tt, $delegate: tt) => {
        bin_assign_op_impl!($typ, $($op)::+<$typ>, $name, $delegate);
    };
    ($typ: tt, $($op: tt)::+<$arg: tt>, $name: tt, $delegate: tt) => {
        impl $($op)::+<$arg> for $typ {
            #[inline]
            fn $name(&mut self, rhs: $arg) {
                *self = *self $delegate rhs;
            }
        }
    }
}

bin_assign_op_impl!(FPNum, ops::AddAssign, add_assign, +);
bin_assign_op_impl!(FPNum, ops::SubAssign, sub_assign, -);
bin_assign_op_impl!(FPNum, ops::MulAssign, mul_assign, *);
bin_assign_op_impl!(FPNum, ops::DivAssign, div_assign, /);
bin_assign_op_impl!(FPNum, ops::MulAssign<i32>, mul_assign, *);
bin_assign_op_impl!(FPNum, ops::DivAssign<i32>, div_assign, /);
bin_assign_op_impl!(FPNum, ops::DivAssign<u32>, div_assign, /);

bin_assign_op_impl!(FPPoint, ops::AddAssign, add_assign, +);
bin_assign_op_impl!(FPPoint, ops::SubAssign, sub_assign, -);
bin_assign_op_impl!(FPPoint, ops::MulAssign, mul_assign, *);
bin_assign_op_impl!(FPPoint, ops::DivAssign, div_assign, /);
bin_assign_op_impl!(FPPoint, ops::AddAssign<FPNum>, add_assign, +);
bin_assign_op_impl!(FPPoint, ops::SubAssign<FPNum>, sub_assign, -);
bin_assign_op_impl!(FPPoint, ops::MulAssign<FPNum>, mul_assign, *);
bin_assign_op_impl!(FPPoint, ops::DivAssign<FPNum>, div_assign, /);

pub fn integral_sqrt(value: u64) -> u64 {
    let mut digits = (64u32 - 1).saturating_sub(value.leading_zeros()) & 0xFE;
    let mut result = if value == 0 { 0u64 } else { 1u64 };

    while digits != 0 {
        result <<= 1;
        if (result + 1).pow(2) <= value >> (digits - 2) {
            result += 1;
        }
        digits -= 2;
    }

    result
}

pub fn integral_sqrt_ext(value: u128) -> u64 {
    let mut digits = (128u32 - 1).saturating_sub(value.leading_zeros()) & 0xFE;
    let mut result = if value == 0 { 0u64 } else { 1u64 };

    while digits != 0 {
        result <<= 1;
        if ((result + 1) as u128).pow(2) <= value >> (digits - 2) {
            result += 1;
        }
        digits -= 2;
    }

    result
}

#[inline]
pub fn distance<T, const FRAC_BITS: u8>(x: T, y: T) -> FixedPoint<FRAC_BITS>
where
    T: Into<i128> + std::fmt::Debug,
{
    let [x_squared, y_squared] = [x, y].map(|i| (i.into().pow(2) as u128).saturating_mul(1 << FRAC_BITS << FRAC_BITS));
    let sqr: u128 = x_squared.saturating_add(y_squared);

    FixedPoint {
        sign_mask: POSITIVE_MASK,
        value: integral_sqrt_ext(sqr),
        _marker: PhantomData,
    }
}

/* TODO:
 AngleSin
 AngleCos
*/

#[test]
fn basics() {
    let n = fp!(15 / 2);
    assert!(n.is_positive());
    assert!(!n.is_negative());

    assert!(!(-n).is_positive());
    assert!((-n).is_negative());

    assert_eq!(-(-n), n);
    assert_eq!((-n).abs(), n);
    assert_eq!(-n, fp!(-15 / 2));

    assert_eq!(n.round(), 7);
    assert_eq!((-n).round(), -7);

    assert_eq!(f64::from(fp!(5/2)), 2.5f64);

    assert_eq!(integral_sqrt_ext(0xFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF), 0xFFFF_FFFF_FFFF_FFFF);
}

#[test]
fn zero() {
    let z = fp!(0);
    let n = fp!(15 / 2);

    assert!(z.is_zero());
    assert!(z.is_positive());
    assert!((-z).is_negative());
    assert_eq!(n - n, z);
    assert_eq!(-n + n, z);
    assert_eq!(n.with_sign_as(-n), -n);
}

#[test]
fn ord() {
    let z = fp!(0);
    let n1_5 = fp!(3 / 2);
    let n2_25 = fp!(9 / 4);

    assert!(!(z > z));
    assert!(!(z < z));
    assert!(n2_25 > n1_5);
    assert!(-n2_25 < n1_5);
    assert!(-n2_25 < -n1_5);

    assert_eq!(n1_5.signum(), 1);
    assert_eq!((-n1_5).signum(), -1);
}

#[test]
fn arith() {
    let n1_5 = fp!(3 / 2);
    let n2_25 = fp!(9 / 4);
    let n_0_15 = fp!(-15 / 100);

    assert_eq!(n1_5 + n1_5, fp!(3));
    assert_eq!(-n1_5 - n1_5, fp!(-3));
    assert_eq!(n1_5 - n1_5, fp!(0));

    assert_eq!(n1_5 * n1_5, n2_25);
    assert_eq!(-n1_5 * -n1_5, n2_25);
    assert_eq!(n1_5 * -n1_5, -n2_25);
    assert_eq!(-n1_5 * n1_5, -n2_25);

    assert_eq!(-n2_25 / -n1_5, n1_5);
    assert_eq!(n1_5 / -10, n_0_15);

    assert_eq!(n1_5.sqr(), n2_25);
    assert_eq!((-n1_5).sqr(), n2_25);

    assert_eq!(n2_25.sqrt(), n1_5);

    assert_eq!((n1_5 * n1_5 * n1_5.sqr()).sqrt(), n2_25);

    let mut m = fp!(1);
    m += n1_5;
    assert_eq!(m, fp!(5 / 2));
}

#[test]
fn test_distance_high_values() {
    assert_eq!(distance(1_000_000i32, 0), fp!(1_000_000));
    assert_eq!(
        FPPoint::new(fp!(1_000_000), fp!(0)).distance(),
        fp!(1_000_000)
    );
}

#[test]
fn point() {
    let z = FPPoint::zero();
    let n = fp!(16 / 9);
    let p = FPPoint::new(fp!(1), fp!(-2));

    assert_eq!(p.sqr_distance(), fp!(5));
    assert_eq!(p + -p, FPPoint::zero());
    assert_eq!(p * z, z);
    assert_eq!(p.dot(&z), fp!(0));
    assert_eq!(n * p, p * n);
    assert_eq!(distance(4, 3), fp!(5));
    assert_eq!(p * fp!(-3), FPPoint::new(fp!(-3), fp!(6)));
    assert_eq!(p.max_norm(), fp!(2));
}
