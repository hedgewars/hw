use crate::ai_state::collision::*;
use crate::game_field::GameField;
use bitflags::bitflags;
use fpnum::{fp, FPNum};
use std::ffi::c_void;
use std::ptr::NonNull;

#[repr(transparent)]
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub(crate) struct StateFlags(u32);

bitflags! {
    impl StateFlags: u32 {
const Drowning       = 0x00000001;
const HHDriven       = 0x00000002;
const Moving         = 0x00000004;
const Attacked       = 0x00000008;
const Attacking      = 0x00000010;
const Collision      = 0x00000020;
const ChooseTarget   = 0x00000040;
const HHJumping      = 0x00000100;
const tmpFlag        = 0x00000200;
const HHThinking     = 0x00000800;
const NoDamage       = 0x00001000;
const HHHJump        = 0x00002000;
const Animation      = 0x00004000;
const HHDeath        = 0x00008000;
const Winner         = 0x00010000;
const Wait           = 0x00020000;
const NotKickable    = 0x00040000;
const Loser          = 0x00080000;
const HHGone         = 0x00100000;
const Invisible      = 0x00200000;
const Submersible    = 0x00400000;
const Frozen         = 0x00800000;
const NoGravity      = 0x01000000;
const InBounceEdge   = 0x02000000;
    }
}

#[repr(C)]
#[derive(Debug, Clone)]
pub struct TGear {
    next: Option<NonNull<TGear>>,
    prev: Option<NonNull<TGear>>,
    pub(crate) x: FPNum,
    pub(crate) y: FPNum,
    pub(crate) d_x: FPNum,
    pub(crate) d_y: FPNum,
    pub(crate) state: StateFlags,
    pub(crate) radius: i32,
    pub(crate) collision_mask: u16,
    pub(crate) angle: u32,
    pub(crate) power: u32,
}

impl TGear {
    fn test_horizontal_collision(&self, game_field: &GameField, direction: i8) -> u16 {
        test_collision_x(
            game_field,
            self.x.round() as i32,
            self.y.round() as i32,
            self.radius,
            direction,
            self.collision_mask,
        )
    }

    fn test_vertical_collision(&self, game_field: &GameField, direction: i8) -> u16 {
        test_collision_y(
            game_field,
            self.x.round() as i32,
            self.y.round() as i32,
            self.radius,
            direction,
            self.collision_mask,
        )
    }

    fn hedgehog_step(&mut self, game_field: &GameField) -> bool {
        let dir = self.d_x.signum();
        let revert_y = self.y;
        let mut gap_found = false;
        let mut hit_ceiling = false;

        for _ in 0..6 {
            if self.test_horizontal_collision(game_field, dir) != 0 {
                if self.test_vertical_collision(game_field, -1) == 0 {
                    self.y -= fp!(1);
                } else {
                    hit_ceiling = true;
                    break;
                }
            } else {
                gap_found = true;
                break;
            }
        }

        if !hit_ceiling {
            gap_found = self.test_horizontal_collision(game_field, dir) == 0;
        }

        if gap_found {
            self.x += fp!(1).with_sign_as(self.d_x);
        } else {
            self.y = revert_y;
        }

        let mut hit_floor = false;
        let revert_y = self.y;
        for _ in 0..6 {
            if self.test_vertical_collision(game_field, 1) == 0 {
                self.y += fp!(1);
            } else {
                hit_floor = true;
                break;
            }
        }

        if !hit_floor {
            self.y = revert_y;
            self.d_y = fp!(0);
            self.state.insert(StateFlags::Moving);
        }

        gap_found
    }
}

#[no_mangle]
pub extern "C" fn hedgehog_step(game_field: & GameField, gear: &mut TGear) -> bool {
    gear.hedgehog_step(game_field)
}

#[no_mangle]
pub extern "C" fn gear_checksum(gear: &TGear) -> u32 {
    [gear.x, gear.y, gear.d_x, gear.d_y].iter().enumerate().map(|(i, n)| {
        (n.raw_value() as u32) << i
    }).fold(0, |acc, n| acc ^ n)
}
