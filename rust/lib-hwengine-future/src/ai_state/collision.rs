use crate::ai_state::action::{Action, Direction};
use crate::game_field::GameField;
use glam::Vec2;

fn test_collision_x(
    game_field: &GameField,
    center_x: i32,
    center_y: i32,
    radius: i32,
    direction: i32,
    mask: u16,
) -> u16 {
    let x = if direction < 0 {
        center_x - radius
    } else {
        center_x + radius
    };

    for val in game_field.collision.iter_range(center_y - radius + 1..=center_y + radius - 1, x..=x) {
        if val & mask != 0 {
            return val & mask;
        }
    }

    0
}

fn test_collision_y(
    game_field: &GameField,
    center_x: i32,
    center_y: i32,
    radius: i32,
    direction: i32,
    mask: u16,
) -> u16 {
    let y = if direction < 0 {
        center_y - radius
    } else {
        center_y + radius
    };

    for val in game_field.collision.iter_range(y..=y, center_x - radius + 1..=center_x + radius - 1) {
        if val & mask != 0 {
            return val & mask;
        }
    }

    0
}

pub(crate) fn test_coll(game_field: &GameField, x: i32, y: i32, r: i32) -> bool {
    let lf_not_cur_hog_crate = 0xFF7F;
    let coords = [
        (y - r, x - r),
        (y + r, x - r),
        (y - r, x + r),
        (y + r, x + r),
    ];
    for (cy, cx) in coords {
        if !game_field.collision.is_valid_coordinate(cx, cy) {
            return false;
        }
        if game_field.collision.get(cy, cx) & lf_not_cur_hog_crate != 0 {
            return true;
        }
    }
    false
}

pub(crate) fn simulate_step(
    game_field: &GameField,
    start_x: f32,
    start_y: f32,
    dir: Direction,
) -> Option<(f32, f32, usize)> {
    let radius = 9;
    let mask = 0xFF7F;

    let mut x = start_x;
    let mut y = start_y;

    let dir = match dir {
        Direction::Left => -1,
        Direction::Right => 1,
    };

    // 1. Try to step up up to 6 times if there is a collision horizontally.
    if test_collision_x(
        game_field,
        x.round() as i32,
        y.round() as i32,
        radius,
        dir,
        mask,
    ) != 0
    {
        let mut resolved = false;
        for _ in 1..=6 {
            if test_collision_y(
                game_field,
                x.round() as i32,
                y.round() as i32,
                radius,
                -1,
                mask,
            ) == 0
            {
                y -= 1.0;
                if test_collision_x(
                    game_field,
                    x.round() as i32,
                    y.round() as i32,
                    radius,
                    dir,
                    mask,
                ) == 0
                {
                    resolved = true;
                    break;
                }
            } else {
                break;
            }
        }
        if !resolved {
            y = start_y;
        }
    }

    // 2. If there is no horizontal collision now, move horizontally.
    if test_collision_x(
        game_field,
        x.round() as i32,
        y.round() as i32,
        radius,
        dir,
        mask,
    ) == 0
    {
        x += dir as f32;

        // 3. Check for ground below. Step down up to 6 times.
        let mut landed = false;
        for _ in 1..=6 {
            if test_collision_y(
                game_field,
                x.round() as i32,
                y.round() as i32,
                radius,
                1,
                mask,
            ) == 0
            {
                y += 1.0;
            } else {
                landed = true;
                break;
            }
        }

        if !landed {
            y -= 6.0;
            // Falling!
            let mut dy = 0.0;
            let mut fall_ticks = 0;
            loop {
                fall_ticks += 1;
                dy += 0.0005; // gravity
                if dy > 0.4 {
                    return None; // too fast, fall damage
                }
                y += dy;
                if y.round() as i32 + radius >= game_field.collision.height() as i32 {
                    return None; // drowned
                }
                if test_collision_y(
                    game_field,
                    x.round() as i32,
                    y.round() as i32,
                    radius,
                    1,
                    mask,
                ) != 0
                {
                    // Landed!
                    return Some((x, y, fall_ticks + 410));
                }
            }
        } else {
            // Walked successfully
            return Some((x, y, 29));
        }
    }
    None
}

pub(crate) fn simulate_long_jump(
    game_field: &GameField,
    start_x: f32,
    start_y: f32,
    dir: Direction,
) -> Option<(f32, f32, usize)> {
    let radius = 9;
    let mask = 0xFF7F;
    let start = Vec2::new(start_x, start_y);
    let mut position = start;
    let mut ticks = 0;

    let dir = match dir {
        Direction::Left => -1,
        Direction::Right => 1,
    };

    // fix start position
    if test_collision_y(
        game_field,
        position.x.round() as i32,
        position.y.round() as i32,
        radius,
        -1,
        mask,
    ) != 0
    {
        if test_collision_x(
            game_field,
            position.x.round() as i32,
            position.y.round() as i32 - 2,
            radius,
            dir,
            mask,
        ) == 0
        {
            position.y -= 2.0;
        } else if test_collision_x(
            game_field,
            position.x.round() as i32,
            position.y.round() as i32 - 1,
            radius,
            dir,
            mask,
        ) == 0
        {
            position.y -= 1.0;
        }
    }

    // check if we can jump
    if test_collision_x(
        game_field,
        position.x.round() as i32,
        position.y.round() as i32,
        radius,
        dir,
        mask,
    ) != 0
        || test_collision_y(
            game_field,
            position.x.round() as i32,
            position.y.round() as i32,
            radius,
            -1,
            mask,
        ) != 0
    {
        return None;
    }

    let mut velocity = Vec2::new(dir as f32 * 0.15, -0.15);

    loop {
        // Check water
        if position.y.round() as i32 + radius >= game_field.collision.height() as i32 {
            return None; // drowned
        }

        if test_collision_x(
            game_field,
            position.x.round() as i32,
            position.y.round() as i32,
            radius,
            dir,
            mask,
        ) != 0
        {
            velocity.x = dir as f32 * 0.0002; // stopped by wall
        }

        position.x += velocity.x;
        velocity.y += 0.0005; // gravity
        ticks += 1;

        if velocity.y > 0.4 {
            return None; // too fast, fall damage
        }

        if velocity.y < 0.0
            && test_collision_y(
                game_field,
                position.x.round() as i32,
                position.y.round() as i32,
                radius,
                -1,
                mask,
            ) != 0
        {
            velocity.y = 0.0;
        }

        position.y += velocity.y;

        if velocity.y >= 0.0
            && test_collision_y(
                game_field,
                position.x.round() as i32,
                position.y.round() as i32,
                radius,
                1,
                mask,
            ) != 0
        {
            // Landed!
            let success = (start_x - position.x).abs().round() > 30.0;
            if success {
                return Some((position.x, position.y, ticks + 600)); // 300 before, 300 after jump
            } else {
                return None;
            }
        }
    }
}
