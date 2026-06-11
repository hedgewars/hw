mod action;
pub mod ammo;
mod attack_tests;
pub(crate) mod collision;
mod waypoint;

use crate::ai_state::ammo::AmmoType;
use crate::ai_state::attack_tests::AttackParameters;
use crate::ai_state::waypoint::{Waypoint, Waypoints};
use crate::game_field::GameField;
use action::*;
use integral_geometry::Point;
use std::collections::BinaryHeap;
use strum::{EnumCount, IntoEnumIterator};
use crate::gear::TGear;

#[derive(Clone, Debug)]
pub struct Target {
    pub point: Point,
    pub health: i32,
    pub radius: u32,
    pub density: f32,
}

#[derive(Clone, Debug)]
pub struct Hedgehog {
    pub(crate) gear: TGear,
    pub(crate) ammo: [u32; AmmoType::COUNT],
}

pub struct AI<'a> {
    pub(crate) game_field: &'a GameField,
    pub(crate) targets: Vec<Target>,
    pub(crate) team: Vec<Hedgehog>,
    pub(crate) actions: Option<Actions>,
}

impl<'a> AI<'a> {
    pub fn new(game_field: &'a GameField) -> AI<'a> {
        Self {
            game_field,
            targets: vec![],
            team: vec![],
            actions: None,
        }
    }

    pub fn get_team_mut(&mut self) -> &mut Vec<Hedgehog> {
        &mut self.team
    }

    pub fn clear_targets(&mut self) {
        self.targets.clear();
    }

    pub fn add_target(&mut self, x: i32, y: i32, health: i32, radius: u32, density: f32) {
        self.targets.push(Target {
            point: Point::new(x, y),
            health,
            radius,
            density,
        });
    }

    pub(crate) fn walk(&mut self, hedgehog: &TGear) -> Waypoints {
        self.actions = None;

        let mut waypoints = Waypoints::default();
        let mut heap = BinaryHeap::<Waypoint>::new();

        let start_waypoint = Waypoint {
            x: hedgehog.x,
            y: hedgehog.y,
            ticks: 0,
            previous_point: None,
        };

        waypoints.add_point(&start_waypoint);
        heap.push(start_waypoint);

        let max_ticks = 40000;

        while let Some(start_waypoint) = heap.pop() {
            //let start_position = (&start_waypoint).into();

            for dir in [Direction::Left, Direction::Right] {
                let mut waypoint = start_waypoint.clone();

                /*
                // jumping
                if let Some((x, y, ticks)) =
                    collision::simulate_long_jump(self.game_field, waypoint.x, waypoint.y, dir)
                {
                    waypoint.ticks += ticks;
                    waypoint.x = x;
                    waypoint.y = y;
                    waypoint.previous_point = Some((start_position, Action::LongJump(dir)));

                    if waypoints.add_point(&waypoint) && waypoint.ticks < max_ticks {
                        heap.push(waypoint.clone());
                    }
                }*/

                /*
                // walking
                let mut waypoint = start_waypoint.clone();
                let mut steps_counter = 0;

                while let Some((x, y, ticks)) =
                    collision::simulate_step(self.game_field, waypoint.x, waypoint.y, dir)
                {
                    waypoint.ticks += ticks;
                    waypoint.x = x;
                    waypoint.y = y;
                    waypoint.previous_point = Some((start_position, Action::Walk(dir)));

                    if !waypoints.add_point(&waypoint) || waypoint.ticks >= max_ticks {
                        break;
                    }

                    steps_counter += 1;
                }
                if steps_counter > 1 {
                    heap.push(waypoint);
                }
*/
            }
        }

        waypoints
    }

    fn calculate_final_score(waypoint: &Waypoint, attack_score: i32) -> i32 {
        attack_score + waypoint.ticks as i32 / 10
    }

    fn calculate_attack(&mut self, hedgehog: &Hedgehog, waypoints: &Waypoints) {
        let mut best_attack: Option<AttackParameters> = None;

        for (point, waypoint) in waypoints.iter() {
            let px = waypoint.x;
            let py = waypoint.y;

            for ammo_type in AmmoType::iter() {
                if hedgehog.ammo[ammo_type as usize] > 0 {
                    if let Some(res) =
                        ammo_type.analyze_attacks(self.game_field, &self.targets, f64::from(px) as f32, f64::from(py) as f32)
                    {
                        let final_score = Self::calculate_final_score(&waypoint, res.score);

                        if best_attack
                            .as_ref()
                            .is_none_or(|a| final_score > a.parameters.score)
                        {
                            let mut res = res;
                            res.score = final_score;
                            best_attack = Some(AttackParameters {
                                position: *point,
                                weapon: ammo_type,
                                parameters: res,
                            });
                        }
                    }
                }
            }
        }

        if let Some(AttackParameters {
            position,
            weapon,
            parameters,
        }) = best_attack
        {
            if dbg!(&parameters).score >= 0 {
                let mut path_actions = Vec::<Action>::new();
                let mut wp = waypoints.get_waypoint(&position);
                while let Some((previous_point, action)) = &wp.previous_point {
                    path_actions.push(Action::CheckPosition {
                        x: wp.x.round() as i32,
                        y: wp.y.round() as i32,
                        angle: 0,
                    });
                    match action {
                        Action::Walk(dir) => {
                            path_actions.push(Action::StopAt {
                                direction: dir.clone(),
                                x: wp.x.round() as i32,
                                y: wp.y.round() as i32,
                            });
                            path_actions.push(Action::Walk(*dir));
                        }
                        Action::LongJump(dir) => {
                            path_actions.push(Action::LongJump(*dir));
                            path_actions.push(Action::Look(*dir));
                        }
                        _ => {}
                    }
                    wp = waypoints.get_waypoint(previous_point);
                }

                let mut actions = Actions::new();
                actions.push(Action::Fire {
                    power: parameters.power,
                    timer: parameters.timer,
                });
                actions.push(Action::CheckPosition {
                    x: wp.x.round() as i32,
                    y: wp.y.round() as i32,
                    angle: parameters.angle,
                });
                actions.push(Action::Aim {
                    angle: parameters.angle.abs(),
                });

                if parameters.angle > 0 {
                    actions.push(Action::Look(Direction::Right));
                } else {
                    actions.push(Action::Look(Direction::Left));
                }

                actions.push(Action::SelectWeapon(weapon));
                actions.actions.extend(path_actions);

                self.actions = Some(actions);
            }
        }
    }

    pub fn have_plan(&self) -> bool {
        self.actions.is_some()
    }

    pub fn plan(&mut self) {
        self.actions = None;

        if let Some(hedgehog) = self.team.first().cloned() {
            let positions = self.walk(&hedgehog.gear);
            println!("Found {} positions", positions.len());
            self.calculate_attack(&hedgehog, &positions)
        }
    }
}
