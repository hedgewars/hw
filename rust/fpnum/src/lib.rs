use std::{cmp, ops, ops::Shl};

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

#[derive(Clone, Debug, Copy)]
pub struct FPNum {
    sign_mask: u64,
    value: u64,
}

impl FPNum {
    #[inline]
    pub fn new(numerator: i32, denominator: u32) -> Self {
        FPNum::from(numerator) / denominator
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
        }
    }

    #[inline]
    pub fn round(&self) -> i32 {
        ((self.value >> 32) as i32 ^ self.sign_mask as i32).wrapping_sub(self.sign_mask as i32)
    }

    #[inline]
    pub const fn abs_round(&self) -> u32 {
        (self.value >> 32) as u32
    }

    #[inline]
    pub fn sqr(&self) -> Self {
        Self {
            sign_mask: 0,
            value: ((self.value as u128).pow(2) >> 32) as u64,
        }
    }

    pub fn sqrt(&self) -> Self {
        debug_assert!(self.is_positive());

        Self {
            sign_mask: POSITIVE_MASK,
            value: integral_sqrt(self.value) << 16,
        }
    }

    #[inline]
    pub fn with_sign(&self, is_negative: bool) -> FPNum {
        FPNum {
            sign_mask: bool_mask(is_negative),
            ..*self
        }
    }

    #[inline]
    pub const fn with_sign_as(self, other: FPNum) -> FPNum {
        FPNum {
            sign_mask: other.sign_mask,
            ..self
        }
    }

    #[inline]
    pub const fn point(self) -> FPPoint {
        FPPoint::new(self, self)
    }

    #[inline]
    const fn temp_i128(self) -> i128 {
        ((self.value ^ self.sign_mask) as i128).wrapping_sub(self.sign_mask as i128)
    }
}

impl From<i32> for FPNum {
    #[inline]
    fn from(n: i32) -> Self {
        FPNum {
            sign_mask: bool_mask(n < 0),
            value: (n.abs() as u64) << 32,
        }
    }
}

impl From<u32> for FPNum {
    #[inline]
    fn from(n: u32) -> Self {
        Self {
            sign_mask: POSITIVE_MASK,
            value: (n as u64) << 32,
        }
    }
}

impl From<FPNum> for f64 {
    #[inline]
    fn from(n: FPNum) -> Self {
        if n.is_negative() {
            n.value as f64 / (-0x10000000 as f64)
        } else {
            n.value as f64 / 0x10000000 as f64
        }
    }
}

impl PartialEq for FPNum {
    #[inline]
    fn eq(&self, other: &Self) -> bool {
        self.value == other.value && (self.sign_mask == other.sign_mask || self.value == 0)
    }
}

impl Eq for FPNum {}

impl PartialOrd for FPNum {
    #[inline]
    fn partial_cmp(&self, rhs: &Self) -> std::option::Option<std::cmp::Ordering> {
        Some(self.cmp(rhs))
    }
}

impl Ord for FPNum {
    #[inline]
    fn cmp(&self, rhs: &Self) -> cmp::Ordering {
        self.temp_i128().cmp(&(rhs.temp_i128()))
    }
}

impl ops::Add for FPNum {
    type Output = Self;

    #[inline]
    fn add(self, rhs: Self) -> Self {
        let tmp = self.temp_i128() + rhs.temp_i128();
        let mask = bool_mask(tmp < 0);
        Self {
            sign_mask: mask,
            value: ((tmp as u64) ^ mask).wrapping_sub(mask),
        }
    }
}

impl ops::Sub for FPNum {
    type Output = Self;

    #[inline]
    fn sub(self, mut rhs: Self) -> Self {
        rhs.sign_mask = !rhs.sign_mask;
        self + rhs
    }
}

impl ops::Neg for FPNum {
    type Output = Self;

    #[inline]
    fn neg(self) -> Self {
        Self {
            sign_mask: !self.sign_mask,
            value: self.value,
        }
    }
}

impl ops::Mul for FPNum {
    type Output = Self;

    #[inline]
    fn mul(self, rhs: Self) -> Self {
        Self {
            sign_mask: self.sign_mask ^ rhs.sign_mask,
            value: ((self.value as u128 * rhs.value as u128) >> 32) as u64,
        }
    }
}

impl ops::Mul<i32> for FPNum {
    type Output = Self;

    #[inline]
    fn mul(self, rhs: i32) -> Self {
        Self {
            sign_mask: self.sign_mask ^ bool_mask(rhs < 0),
            value: self.value * rhs.abs() as u64,
        }
    }
}

impl ops::Div for FPNum {
    type Output = Self;

    #[inline]
    fn div(self, rhs: Self) -> Self {
        Self {
            sign_mask: self.sign_mask ^ rhs.sign_mask,
            value: (((self.value as u128) << 32) / rhs.value as u128) as u64,
        }
    }
}

impl ops::Div<i32> for FPNum {
    type Output = Self;

    #[inline]
    fn div(self, rhs: i32) -> Self {
        Self {
            sign_mask: self.sign_mask ^ bool_mask(rhs < 0),
            value: self.value / rhs.abs() as u64,
        }
    }
}

impl ops::Div<u32> for FPNum {
    type Output = Self;

    #[inline]
    fn div(self, rhs: u32) -> Self {
        Self {
            sign_mask: self.sign_mask,
            value: self.value / rhs as u64,
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
        }
    }

    #[inline]
    pub const fn y(&self) -> FPNum {
        FPNum {
            sign_mask: self.y_sign_mask as i32 as u64,
            value: self.y_value,
        }
    }

    #[inline]
    pub fn is_zero(&self) -> bool {
        self.x().is_zero() && self.y().is_zero()
    }

    #[inline]
    pub fn max_norm(&self) -> FPNum {
        std::cmp::max(self.x().abs(), self.y().abs())
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
                value: integral_sqrt_ext(sqr) as u64,
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

pub fn integral_sqrt(mut value: u64) -> u64 {
    let mut digit_sqr = 0x4000_0000_0000_0000u64.wrapping_shr(value.leading_zeros() & 0xFFFF_FFFE);
    let mut result = 0;

    while digit_sqr != 0 {
        let approx = digit_sqr + result;
        result >>= 1;

        if approx <= value {
            value -= approx;
            result += digit_sqr;
        }
        digit_sqr >>= 2;
    }
    result
}

pub fn integral_sqrt_ext(mut value: u128) -> u128 {
    let mut digit_sqr =
        0x40000000_00000000_00000000_00000000u128.wrapping_shr(value.leading_zeros() & 0xFFFF_FFFE);
    let mut result = 0u128;

    while digit_sqr != 0 {
        let approx = result + digit_sqr;
        result >>= 1;

        if approx <= value {
            value -= approx;
            result += digit_sqr;
        }
        digit_sqr >>= 2;
    }
    result
}

pub fn distance<T>(x: T, y: T) -> FPNum
where
    T: Into<i64> + std::fmt::Debug,
{
    let sqr: u128 = (x.into().pow(2) as u128).shl(64) + (y.into().pow(2) as u128).shl(64);

    FPNum {
        sign_mask: POSITIVE_MASK,
        value: integral_sqrt_ext(sqr) as u64,
    }
}

/* TODO:
 AngleSin
 AngleCos
*/

#[cfg(test)]
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
