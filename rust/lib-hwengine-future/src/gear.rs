use crate::ai_state::collision::*;
use crate::game_field::GameField;
use bitflags::bitflags;
use fpnum::{fp, FPNum};
use std::ptr::NonNull;

pub const HH_RADIUS: i32 = 9;
pub const STEP_TICKS: usize = 29;
pub const JUMP_TICKS_PAUSE: usize = 600;

#[inline]
pub fn gravity() -> FPNum {
    fp!(1 / 2000)
}

#[inline]
pub fn little() -> FPNum {
    FPNum::from_raw(1)
}

#[inline]
pub fn max_fall_dy() -> FPNum {
    fp!(4 / 10)
}

#[repr(transparent)]
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct StateFlags(u32);

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
    pub x: FPNum,
    pub y: FPNum,
    pub d_x: FPNum,
    pub d_y: FPNum,
    pub state: StateFlags,
    pub radius: i32,
    pub collision_mask: u16,
    pub angle: u32,
    pub power: u32,
}

impl TGear {
    pub fn new(x: FPNum, y: FPNum) -> Self {
        Self {
            next: None,
            prev: None,
            x,
            y,
            d_x: little(),
            d_y: fp!(0),
            state: StateFlags::empty(),
            radius: HH_RADIUS,
            collision_mask: 0xFF7F,
            angle: 0,
            power: 0,
        }
    }

    #[inline]
    pub fn direction(&self) -> i8 {
        self.d_x.signum()
    }

    #[inline]
    pub fn set_direction(&mut self, dir: i8) {
        if dir < 0 {
            if self.d_x.is_positive() {
                self.d_x = -self.d_x;
            }
        } else if dir > 0 {
            if self.d_x.is_negative() {
                self.d_x = -self.d_x;
            }
        }
    }

    #[inline]
    pub fn set_little_dx(&mut self) {
        self.d_x = little().with_sign_as(self.d_x);
    }

    #[inline]
    pub fn test_horizontal_collision(&self, game_field: &GameField, direction: i8) -> u16 {
        test_collision_x(
            game_field,
            self.x.round() as i32,
            self.y.round() as i32,
            self.radius,
            direction,
            self.collision_mask,
        )
    }

    #[inline]
    pub fn test_vertical_collision(&self, game_field: &GameField, direction: i8) -> u16 {
        test_collision_y(
            game_field,
            self.x.round() as i32,
            self.y.round() as i32,
            self.radius,
            direction,
            self.collision_mask,
        )
    }

    #[inline]
    pub fn test_horizontal_collision_with_offset(
        &self,
        game_field: &GameField,
        offset_x: FPNum,
        offset_y: i32,
        direction: i8,
    ) -> u16 {
        test_collision_x(
            game_field,
            (self.x + offset_x).round() as i32,
            self.y.round() as i32 + offset_y,
            self.radius,
            direction,
            self.collision_mask,
        )
    }

    #[inline]
    pub fn test_vertical_collision_with_offset(
        &self,
        game_field: &GameField,
        offset_x: i32,
        offset_y: i32,
        direction: i8,
    ) -> u16 {
        test_collision_y(
            game_field,
            self.x.round() as i32 + offset_x,
            self.y.round() as i32 + offset_y,
            self.radius,
            direction,
            self.collision_mask,
        )
    }

    pub fn step(&mut self, game_field: &GameField) -> bool {
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

    #[inline]
    pub fn hedgehog_step(&mut self, game_field: &GameField) -> bool {
        self.step(game_field)
    }

    pub fn start_high_jump(&mut self, game_field: &GameField) -> bool {
        if self.test_vertical_collision(game_field, -1) == 0 {
            self.d_y = -fp!(1 / 5);
            self.set_little_dx();
            self.state
                .insert(StateFlags::Moving | StateFlags::HHJumping);
            self.state.remove(StateFlags::HHHJump);
            true
        } else {
            false
        }
    }

    pub fn start_long_jump(&mut self, game_field: &GameField) -> bool {
        let dir = self.d_x.signum();
        let revert_y = self.y;

        if self.test_vertical_collision(game_field, -1) == 0 {
            if self.test_horizontal_collision_with_offset(game_field, fp!(0), -2, dir) == 0 {
                self.y -= fp!(2);
            } else if self.test_horizontal_collision_with_offset(game_field, fp!(0), -1, dir) == 0 {
                self.y -= fp!(1);
            }
        }

        println!("[ljump start] ({}, {})", self.x, self.y);

        if self.test_horizontal_collision(game_field, dir) == 0
            && self.test_vertical_collision(game_field, -1) == 0
        {
            self.d_y = -fp!(15 / 100);
            self.d_x = fp!(15 / 100).with_sign_as(self.d_x);
            self.state
                .insert(StateFlags::Moving | StateFlags::HHJumping);
            self.state.remove(StateFlags::HHHJump);
            true
        } else {
            self.y = revert_y;
            false
        }
    }

    pub fn can_back_jump(&self) -> bool {
        self.state.contains(StateFlags::HHJumping)
            && !self.state.contains(StateFlags::HHHJump)
            && self.d_x.abs() <= little()
            && self.d_y < fp!(5 / 100)
    }

    pub fn start_back_jump(&mut self) -> bool {
        if self.can_back_jump() {
            self.state.insert(StateFlags::HHHJump);
            self.d_y = -fp!(1 / 4);
            self.d_x = -fp!(2 / 100).with_sign_as(self.d_x);
            true
        } else {
            false
        }
    }

    pub fn stop_jump(&mut self, game_field: &GameField) {
        if self.state.contains(StateFlags::HHHJump) && self.d_x.abs() <= fp!(2 / 100) {
            self.d_x = -self.d_x;
        }
        self.state
            .remove(StateFlags::Moving | StateFlags::HHJumping | StateFlags::HHHJump);
        self.d_y = fp!(0);
        self.set_little_dx();

        for _ in 0..6 {
            if self.test_vertical_collision(game_field, 1) == 0 {
                self.y += fp!(1);
            } else {
                break;
            }
        }

        println!("[ljump stop] ({}, {})", self.x, self.y);
    }

    pub fn jump_step(&mut self, game_field: &GameField) -> bool {
        if self.state.contains(StateFlags::HHJumping) {
            let dir = self.d_x.signum();
            if self.test_horizontal_collision(game_field, dir) != 0 {
                self.set_little_dx();
            }
        }

        self.x += self.d_x;
        self.d_y += gravity();

        if self.d_y.is_negative() && self.test_vertical_collision(game_field, -1) != 0 {
            self.d_y = fp!(0);
        }

        self.y += self.d_y;

        if !self.d_y.is_negative() && self.test_vertical_collision(game_field, 1) != 0 {
            self.stop_jump(game_field);
            return false;
        }

        true
    }

    #[inline]
    pub fn moving_step(&mut self, game_field: &GameField) -> bool {
        self.jump_step(game_field)
    }
}

#[no_mangle]
pub extern "C" fn hedgehog_step(game_field: &GameField, gear: &mut TGear) -> bool {
    gear.step(game_field)
}

#[no_mangle]
pub extern "C" fn hedgehog_start_high_jump(game_field: &GameField, gear: &mut TGear) -> bool {
    gear.start_high_jump(game_field)
}

#[no_mangle]
pub extern "C" fn hedgehog_start_long_jump(game_field: &GameField, gear: &mut TGear) -> bool {
    gear.start_long_jump(game_field)
}

#[no_mangle]
pub extern "C" fn hedgehog_can_back_jump(gear: &TGear) -> bool {
    gear.can_back_jump()
}

#[no_mangle]
pub extern "C" fn hedgehog_start_back_jump(gear: &mut TGear) -> bool {
    gear.start_back_jump()
}

#[no_mangle]
pub extern "C" fn hedgehog_stop_jump(game_field: &GameField, gear: &mut TGear) {
    gear.stop_jump(game_field);
}

#[no_mangle]
pub extern "C" fn hedgehog_jump_step(game_field: &GameField, gear: &mut TGear) -> bool {
    gear.jump_step(game_field)
}

#[no_mangle]
pub extern "C" fn hedgehog_moving_step(game_field: &GameField, gear: &mut TGear) -> bool {
    gear.moving_step(game_field)
}

#[no_mangle]
pub extern "C" fn gear_checksum(gear: &TGear) -> u32 {
    [gear.x, gear.y, gear.d_x, gear.d_y]
        .iter()
        .enumerate()
        .map(|(i, n)| (n.raw_value() as u32) << i)
        .fold(0, |acc, n| acc ^ n)
}

#[cfg(test)]
mod tests {
    use super::*;
    use integral_geometry::Size;

    fn create_test_field(width: u32, height: u32) -> GameField {
        GameField {
            collision: land2d::Land2D::new(&Size::new(width, height), 0),
            pixels: land2d::Land2D::new(&Size::new(width, height), 0),
            landgen_parameters: None,
        }
    }

    fn set_floor(field: &mut GameField, y: i32, from_x: i32, to_x: i32) {
        for x in from_x..=to_x {
            field.collision.map(y, x, |p| *p = 0xFFFF);
        }
    }

    fn set_wall(field: &mut GameField, x: i32, from_y: i32, to_y: i32) {
        for y in from_y..=to_y {
            field.collision.map(y, x, |p| *p = 0xFFFF);
        }
    }

    #[test]
    fn test_step_flat() {
        let mut field = create_test_field(100, 100);
        // Floor at y = 50 for x in 0..100
        set_floor(&mut field, 50, 0, 99);

        // Hedgehog radius is 9. Resting center_y on floor at y=50 is 50 - 9 = 41.
        let mut gear = TGear::new(fp!(20), fp!(41));
        gear.set_direction(1);

        assert!(gear.step(&field));
        assert_eq!(gear.x.round(), 21);
        assert_eq!(gear.y.round(), 41);
        assert!(!gear.state.contains(StateFlags::Moving));
    }

    #[test]
    fn test_step_climb_slope() {
        let mut field = create_test_field(100, 100);
        set_floor(&mut field, 50, 0, 39);
        // 3-pixel step up at x = 40 (floor at y = 47)
        set_floor(&mut field, 47, 40, 90);
        set_wall(&mut field, 40, 48, 50);

        let mut gear = TGear::new(fp!(20), fp!(41));
        gear.set_direction(1);

        // Walk towards the step: from x = 20 to x = 31 (at x = 31, front edge is 31 + 9 = 40)
        for _ in 20..31 {
            assert!(gear.step(&field));
        }
        assert_eq!(gear.x.round(), 31);
        assert_eq!(gear.y.round(), 41);

        // Step at x = 31: front edge checks x = 40, hits step, climbs 3px up to y = 38, moves to x = 32
        assert!(gear.step(&field));
        assert_eq!(gear.x.round(), 32);
        assert_eq!(gear.y.round(), 38); // 47 - 9 = 38
    }

    #[test]
    fn test_step_high_wall_blocked() {
        let mut field = create_test_field(100, 100);
        set_floor(&mut field, 50, 0, 50);
        // 10-pixel high wall at x = 30 (cannot climb > 6)
        set_wall(&mut field, 30, 35, 50);

        let mut gear = TGear::new(fp!(15), fp!(41));
        gear.set_direction(1);

        // Walk to x = 21 (front edge reaches 21 + 9 = 30)
        for _ in 15..21 {
            assert!(gear.step(&field));
        }
        assert_eq!(gear.x.round(), 21);

        // Next step at x = 21 checks wall at 30, cannot climb > 6px, blocked!
        let stepped = gear.step(&field);
        assert!(!stepped);
        assert_eq!(gear.x.round(), 21);
    }

    #[test]
    fn test_step_off_cliff() {
        let mut field = create_test_field(100, 100);
        // Floor only up to x = 25
        set_floor(&mut field, 50, 0, 25);

        let mut gear = TGear::new(fp!(20), fp!(41));
        gear.set_direction(1);

        // Walk until rear edge (x - 8) clears x = 25 (at x = 34)
        for _ in 20..33 {
            assert!(gear.step(&field));
            assert!(!gear.state.contains(StateFlags::Moving));
        }
        assert_eq!(gear.x.round(), 33);

        // Step to x = 34: rear edge is 34 - 8 = 26 > 25, no floor below, transitions to Moving (falling)
        assert!(gear.step(&field));
        assert_eq!(gear.x.round(), 34);
        assert!(gear.state.contains(StateFlags::Moving));
    }

    #[test]
    fn test_high_jump() {
        let mut field = create_test_field(100, 100);
        set_floor(&mut field, 50, 0, 99);

        let mut gear = TGear::new(fp!(20), fp!(41));
        gear.set_direction(1);

        assert!(gear.start_high_jump(&field));
        assert!(gear
            .state
            .contains(StateFlags::Moving | StateFlags::HHJumping));
        assert_eq!(gear.d_y, -fp!(1 / 5));

        // Simulate jump ticks until landing
        let mut ticks = 0;
        while gear.jump_step(&field) {
            ticks += 1;
            assert!(ticks < 1000);
        }

        assert!(!gear
            .state
            .contains(StateFlags::Moving | StateFlags::HHJumping));
        assert_eq!(gear.y.round(), 41);
        assert!(ticks > 0);
    }

    #[test]
    fn test_long_jump() {
        let mut field = create_test_field(200, 100);
        set_floor(&mut field, 50, 0, 199);

        let mut gear = TGear::new(fp!(20), fp!(41));
        gear.set_direction(1);

        let start_x = gear.x;
        assert!(gear.start_long_jump(&field));
        assert!(gear
            .state
            .contains(StateFlags::Moving | StateFlags::HHJumping));
        assert_eq!(gear.d_y, -fp!(15 / 100));

        let mut ticks = 0;
        while gear.jump_step(&field) {
            ticks += 1;
            assert!(ticks < 1000);
        }

        assert!(!gear
            .state
            .contains(StateFlags::Moving | StateFlags::HHJumping));
        assert_eq!(gear.y.round(), 41);
        // Long jump moves significant distance horizontally (> 30px)
        assert!((gear.x - start_x).round() > 30);
    }

    #[test]
    fn test_back_jump() {
        let mut field = create_test_field(100, 100);
        set_floor(&mut field, 50, 0, 99);

        let mut gear = TGear::new(fp!(50), fp!(41));
        gear.set_direction(1); // facing right

        assert!(gear.start_high_jump(&field));
        assert!(gear.can_back_jump());
        assert!(gear.start_back_jump());
        assert!(gear.state.contains(StateFlags::HHHJump));
        assert_eq!(gear.d_y, -fp!(1 / 4));
        assert_eq!(gear.d_x, -fp!(2 / 100)); // moving left

        while gear.jump_step(&field) {}

        // Landing restores facing direction (right)
        assert!(gear.d_x.is_positive());
        assert!(!gear.state.contains(StateFlags::HHHJump));
        assert_eq!(gear.y.round(), 41);
    }
}
