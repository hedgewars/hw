use crate::ai_state::ammo::AmmoType;
use crate::ai_state::{Hedgehog, AI};
use crate::game_field::GameField;
use crate::shortstring::ShortString;
use std::ptr::slice_from_raw_parts;
use strum::EnumCount;
use crate::gear::TGear;

#[no_mangle]
pub extern "C" fn create_ai(game_field: &GameField) -> *mut AI<'_> {
    Box::into_raw(Box::new(AI::new(game_field)))
}

#[no_mangle]
pub extern "C" fn ai_clear_targets(ai: &mut AI) {
    ai.clear_targets();
}

#[no_mangle]
pub extern "C" fn ai_add_target(
    ai: &mut AI,
    x: i32,
    y: i32,
    health: i32,
    radius: u32,
    density: f32,
) {
    ai.add_target(x, y, health, radius, density);
}

#[no_mangle]
pub extern "C" fn ai_clear_team(ai: &mut AI) {
    *ai.get_team_mut() = vec![];
}

#[no_mangle]
pub unsafe extern "C" fn ai_add_team_hedgehog(
    ai: &mut AI,
    gear: &TGear,
    ammo_counts: *const u32,
) {
    let ammo_counts = &*slice_from_raw_parts(ammo_counts, AmmoType::COUNT);
    let ammo_counts = std::array::from_fn(|i| ammo_counts[i].clone());

    ai.get_team_mut().push(Hedgehog {
        gear: gear.clone(),
        ammo: ammo_counts,
    });
}

#[no_mangle]
pub extern "C" fn ai_think(ai: &mut AI) {
    ai.plan()
}

#[no_mangle]
pub extern "C" fn ai_have_plan(ai: &AI) -> bool {
    ai.have_plan()
}

#[no_mangle]
pub extern "C" fn ai_get_action(
    ai: &mut AI,
    gear: &TGear,
    action: &mut ShortString,
) {
    *action = ai
        .get_action(gear)
        .as_str()
        .try_into()
        .unwrap_or_default();
}

#[no_mangle]
pub unsafe extern "C" fn dispose_ai(ai: *mut AI) {
    drop(Box::from_raw(ai));
}
