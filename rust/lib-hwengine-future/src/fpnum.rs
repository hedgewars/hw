use fpnum::{FPNum, FPPoint};
use std::mem::transmute;
use crate::shortstring::ShortString;

#[repr(C)]
pub struct HWFloat {
    _bytes: [u8; 16],
}

impl From<FPNum> for HWFloat {
    fn from(value: FPNum) -> Self {
        unsafe { transmute(value) }
    }
}

impl From<HWFloat> for FPNum {
    fn from(value: HWFloat) -> Self {
        unsafe { transmute(value) }
    }
}

#[no_mangle]
pub extern "C" fn hwf_new(numerator: i32, denominator: u32) -> HWFloat {
    FPNum::new(numerator, denominator).into()
}

#[no_mangle]
pub extern "C" fn hwf_raw(is_negative: bool, value: u64) -> HWFloat {
    FPNum::from_raw(value >> (32 - FPNum::FRAC_BITS))
        .with_sign(is_negative)
        .into()
}

#[no_mangle]
pub extern "C" fn hwf_to_f64(value: HWFloat) -> f64 {
    f64::from(FPNum::from(value))
}

#[no_mangle]
pub extern "C" fn hwf_op_plus(n1: HWFloat, n2: HWFloat) -> HWFloat {
    (FPNum::from(n1) + FPNum::from(n2)).into()
}

#[no_mangle]
pub extern "C" fn hwf_op_minus(n1: HWFloat, n2: HWFloat) -> HWFloat {
    (FPNum::from(n1) - FPNum::from(n2)).into()
}

#[no_mangle]
pub extern "C" fn hwf_op_mul(n1: HWFloat, n2: HWFloat) -> HWFloat {
    (FPNum::from(n1) * FPNum::from(n2)).into()
}

#[no_mangle]
pub extern "C" fn hwf_op_div(n1: HWFloat, n2: HWFloat) -> HWFloat {
    (FPNum::from(n1) / FPNum::from(n2)).into()
}

#[no_mangle]
pub extern "C" fn hwf_op_eq(n1: HWFloat, n2: HWFloat) -> bool {
    FPNum::from(n1) == FPNum::from(n2)
}

#[no_mangle]
pub extern "C" fn hwf_op_lt(n1: HWFloat, n2: HWFloat) -> bool {
    FPNum::from(n1) < FPNum::from(n2)
}

#[no_mangle]
pub extern "C" fn hwf_op_gt(n1: HWFloat, n2: HWFloat) -> bool {
    FPNum::from(n1) > FPNum::from(n2)
}

#[no_mangle]
pub extern "C" fn hwf_is_zero(value: HWFloat) -> bool {
    FPNum::from(value).is_zero()
}

#[no_mangle]
pub extern "C" fn hwf_is_negative(value: HWFloat) -> bool {
    FPNum::from(value).is_negative()
}

#[no_mangle]
pub extern "C" fn hwf_op_neg(value: HWFloat) -> HWFloat {
    (-FPNum::from(value)).into()
}

#[no_mangle]
pub extern "C" fn hwf_op_mul_int(n1: HWFloat, n2: i32) -> HWFloat {
    (FPNum::from(n1) * n2).into()
}

#[no_mangle]
pub extern "C" fn hwf_op_div_int(n1: HWFloat, n2: i32) -> HWFloat {
    (FPNum::from(n1) / n2).into()
}

#[no_mangle]
pub extern "C" fn hwf_to_str(value: HWFloat) -> ShortString {
    ShortString::try_from(f64::from(FPNum::from(value)).to_string().as_str()).unwrap_or_default()
}

#[no_mangle]
pub extern "C" fn hwf_round(value: HWFloat) -> i64 {
    FPNum::from(value).round()
}

#[no_mangle]
pub extern "C" fn hwf_abs(value: HWFloat) -> HWFloat {
    FPNum::from(value).abs().into()
}

#[no_mangle]
pub extern "C" fn hwf_sqr(value: HWFloat) -> HWFloat {
    FPNum::from(value).sqr().into()
}

#[no_mangle]
pub extern "C" fn hwf_sqrt(value: HWFloat) -> HWFloat {
    FPNum::from(value).sqrt().into()
}

#[no_mangle]
pub extern "C" fn hwf_distance(x: HWFloat, y: HWFloat) -> HWFloat {
    FPPoint::new(x.into(), y.into()).distance().into()
}

#[no_mangle]
pub extern "C" fn hwf_sqr_distance(x: HWFloat, y: HWFloat) -> HWFloat {
    FPPoint::new(x.into(), y.into()).sqr_distance().into()
}

#[no_mangle]
pub extern "C" fn hwf_sign_as(num: HWFloat, signum: HWFloat) -> HWFloat {
    FPNum::from(num).with_sign_as(signum.into()).into()
}

#[no_mangle]
pub extern "C" fn hwf_with_sign(num: HWFloat, is_negative: bool) -> HWFloat {
    FPNum::from(num).with_sign(is_negative).into()
}

#[no_mangle]
pub extern "C" fn hwf_signum(r: HWFloat) -> i32 {
    FPNum::from(r).signum().into()
}

#[no_mangle]
pub extern "C" fn hwf_min_positive() -> HWFloat {
    FPNum::from_raw(1).into()
}
