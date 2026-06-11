use crate::game_field::GameField;

pub(crate) fn test_collision_x(
    game_field: &GameField,
    center_x: i32,
    center_y: i32,
    radius: i32,
    direction: i8,
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

pub(crate) fn test_collision_y(
    game_field: &GameField,
    center_x: i32,
    center_y: i32,
    radius: i32,
    direction: i8,
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
