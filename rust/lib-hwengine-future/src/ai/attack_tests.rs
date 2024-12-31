use crate::ai::ammo::AmmoType;
use crate::ai::Target;
use crate::GameField;

fn analyze_grenade(game_field: &GameField, targets: &[Target], my_x: f32, my_y: f32) {}

impl AmmoType {
    pub(crate) fn analyze_attacks(
        &self,
        game_field: &GameField,
        targets: &[Target],
        my_x: f32,
        my_y: f32,
    ) {
        match self {
            AmmoType::Grenade => analyze_grenade(game_field, targets, my_x, my_y),
            _ => {}
        }
    }
}
