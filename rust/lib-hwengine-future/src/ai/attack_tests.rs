use crate::ai::ammo::AmmoType;
use crate::ai::collision::test_coll;
use crate::ai::Target;
use crate::GameField;
use glam::Vec2;
use integral_geometry::Point;

#[derive(Debug, Clone)]
pub struct AttackTestResult {
    pub(crate) score: i32,
    pub(crate) angle: i32,
    pub(crate) power: u32,
    pub(crate) timer: u32,
    starting_point: Point,
    landing_point: Point,
}

pub struct AttackParameters {
    pub(crate) position: Point,
    pub(crate) weapon: AmmoType,
    pub(crate) parameters: AttackTestResult,
}

fn attack_angle(dx: f32, dy: f32) -> i32 {
    (dx.atan2(dy) * (2048.0 / std::f32::consts::PI)) as i32
}

pub fn rate_explosion(targets: &[Target], ex: f32, ey: f32, r: i32, me_x: f32, me_y: f32) -> i32 {
    let mut rate = 0;
    let kill_score = 200;
    let friendly_factor = 300; // 3x penalty

    // Add our own virtual position as a friendly target
    let mut all_targets = targets.to_vec();
    all_targets.push(Target {
        point: Point::new(me_x.round() as i32, me_y.round() as i32),
        health: -100, // friendly
        radius: 9,
        density: 1.0,
    });

    for target in &all_targets {
        let radius = target.radius as i32;
        let dmg_base = r + radius / 2;
        let dist_x = (target.point.x - ex.round() as i32).abs();
        let dist_y = (target.point.y - ey.round() as i32).abs();
        if dist_x + dist_y < dmg_base {
            let actual_dist = (((target.point.x as f32 - ex).powi(2)
                + (target.point.y as f32 - ey).powi(2))
            .sqrt()) as i32;
            let dmg = 0.5 * ((dmg_base - actual_dist) / 2).min(r) as f32;
            let dmg = dmg as i32;

            if dmg > 0 {
                let score = target.health;
                if score > 0 {
                    // Enemy hedgehog
                    if dmg >= score {
                        rate += kill_score * 1024 + dmg;
                    } else {
                        rate += dmg * 1024;
                    }
                } else {
                    // Friendly hedgehog
                    if dmg >= score.abs() {
                        rate -= kill_score * friendly_factor / 100 * 1024;
                    } else {
                        rate -= dmg * friendly_factor / 100 * 1024;
                    }
                }
            }
        }
    }
    rate
}

pub fn analyze_bazooka(
    game_field: &GameField,
    targets: &[Target],
    my_x: f32,
    my_y: f32,
) -> Option<AttackTestResult> {
    let mut best_result: Option<AttackTestResult> = None;
    for target in targets {
        let tx = target.point.x as f32;
        let ty = target.point.y as f32;

        let mut r_time = 100;
        while r_time <= 4650 {
            let start_velocity = Vec2::new(
                (tx - my_x) / r_time as f32,
                (ty + 1.0 - my_y) / r_time as f32 - 0.0005 * r_time as f32 * 0.5,
            );
            let squared_power = start_velocity.length_squared();
            if squared_power <= 1.0 {
                let mut velocity = start_velocity;
                let mut position = Vec2::new(my_x, my_y);
                let acceleration = Vec2::new(0.0, 0.0005);
                let mut hit = false;

                for _ in 0..r_time + 300 {
                    position += velocity;
                    velocity += acceleration;

                    if test_coll(game_field, position.x as i32, position.y as i32, 5) {
                        hit = true;
                        break;
                    }
                }

                if hit {
                    let score = rate_explosion(targets, position.x, position.y, 100, my_x, my_y);
                    let angle = attack_angle(start_velocity.x, -start_velocity.y);
                    let power = (squared_power.sqrt() * 1500.0) as u32;

                    if best_result.as_ref().is_none_or(|b| score > b.score) {
                        best_result = Some(AttackTestResult {
                            score,
                            angle,
                            power,
                            timer: 0,
                            starting_point: Point::new(my_x.round() as i32, my_y.round() as i32),
                            landing_point: Point::new(
                                position.x.round() as i32,
                                position.y.round() as i32,
                            ),
                        });
                    }
                }
            }
            r_time = r_time + 150 + r_time / 4;
        }
    }
    best_result
}

impl AmmoType {
    pub(crate) fn analyze_attacks(
        &self,
        game_field: &GameField,
        targets: &[Target],
        my_x: f32,
        my_y: f32,
    ) -> Option<AttackTestResult> {
        match self {
            AmmoType::Bazooka => analyze_bazooka(game_field, targets, my_x, my_y),
            //            AmmoType::Grenade => analyze_grenade(game_field, targets, my_x, my_y),
            _ => None,
        }
    }
}
