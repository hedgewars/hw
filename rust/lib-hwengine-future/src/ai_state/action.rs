use super::{HedgehogState, AI};
use crate::ai_state::ammo::AmmoType;

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum Direction {
    Left,
    Right,
}

#[derive(Clone, Debug, PartialEq)]
pub enum Action {
    Walk(Direction),
    Look(Direction),
    CheckPosition {
        x: i32,
        y: i32,
        angle: i32,
    },
    StopAt {
        direction: Direction,
        x: i32,
        y: i32,
    },
    LongJump(Direction),
    HighJump(Direction, usize),
    SelectWeapon(AmmoType),
    Aim {
        angle: i32,
    },
    Fire {
        power: u32,
        timer: u32,
    },
}

#[derive(Debug)]
pub struct Actions {
    pub(crate) actions: Vec<Action>,
    pub(crate) current_action: Option<Action>,
    pub(crate) action_ticks: u32,
}

impl Actions {
    pub fn new() -> Self {
        Self {
            actions: vec![],
            current_action: None,
            action_ticks: 0,
        }
    }

    pub fn push(&mut self, action: Action) {
        self.actions.push(action)
    }
}

impl<'a> AI<'a> {
    pub fn get_action(&mut self, state: &HedgehogState) -> String {
        let Some(actions) = &mut self.actions else {
            return String::new();
        };

        if actions.current_action.is_none() {
            if actions.actions.is_empty() {
                self.actions = None;
                return String::new();
            }
            actions.current_action = actions.actions.pop();
            actions.action_ticks = 0;
        } else {
            actions.action_ticks += 1;
        }

        let Some(action) = actions.current_action.clone() else {
            return String::new();
        };

        match action {
            Action::Walk(dir) => {
                actions.current_action = None;
                match dir {
                    Direction::Left => "/+left".to_string(),
                    Direction::Right => "/+right".to_string(),
                }
            }
            Action::Look(dir) => {
                if state.looking_to_the_right == (dir == Direction::Right) {
                    actions.current_action = None;
                    match dir {
                        Direction::Left => "/-left".to_string(),
                        Direction::Right => "/-right".to_string(),
                    }
                } else {
                    match dir {
                        Direction::Left => "/+left".to_string(),
                        Direction::Right => "/+right".to_string(),
                    }
                }
            }
            Action::LongJump(_) => {
                if actions.action_ticks == 0 {
                    "/ljump".to_string()
                } else if state.is_moving || actions.action_ticks < 1000 {
                    String::new()
                } else {
                    actions.current_action = None;
                    String::new()
                }
            }
            Action::HighJump(_, _) => {
                actions.current_action = None;
                "/hjump".to_string()
            }
            Action::StopAt {
                direction,
                x,
                y: _y,
            } => {
                let reached = match direction {
                    Direction::Left => state.x.round() as i32 <= x,
                    Direction::Right => state.x.round() as i32 >= x,
                };
                if reached {
                    actions.current_action = None;
                    match direction {
                        Direction::Left => "/-left".to_string(),
                        Direction::Right => "/-right".to_string(),
                    }
                } else {
                    String::new()
                }
            }
            Action::SelectWeapon(weapon_id) => {
                actions.current_action = None;
                format!("/setweap {}", weapon_id as u8 as char)
            }
            Action::Aim { angle } => {
                if angle == state.angle as i32 {
                    actions.current_action = None;
                    "/-up\n/-down".to_string()
                } else if actions.action_ticks == 0 {
                    if angle < state.angle as i32 {
                        "/+up".to_string()
                    } else {
                        "/+down".to_string()
                    }
                } else {
                    String::new()
                }
            }
            Action::Fire { power, timer } => {
                if actions.action_ticks == 0 {
                    if timer > 0 {
                        let t_num = timer / 1000;
                        format!("/timer {}\n/+attack", t_num)
                    } else {
                        "/+attack".to_string()
                    }
                } else {
                    if actions.action_ticks >= power {
                        actions.current_action = None;
                        self.actions = None; // attack complete, clear all actions!
                        "/-attack".to_string()
                    } else {
                        String::new()
                    }
                }
            }
            Action::CheckPosition { x, y, angle } => {
                actions.current_action = None;

                let state_angle = if state.looking_to_the_right {
                    state.angle as i32
                } else {
                    -(state.angle as i32)
                };
                println!(
                    "{:?} {:?} ?? {:?} {:?}",
                    (x, y),
                    angle,
                    (state.x.round() as i32, state.y.round() as i32),
                    state_angle
                );

                if x != state.x.round() as i32
                    || y != state.y.round() as i32
                    || (angle != state_angle && angle != 0)
                {
                    self.actions = None
                }

                String::new()
            }
        }
    }
}
