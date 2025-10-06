use crate::ai::action::Direction::{Left, Right};
use crate::shortstring::ShortString;
use crate::HedgehogState;

#[derive(Clone)]
pub enum Direction {
    Left,
    Right,
}
#[derive(Clone)]
pub enum Action {
    Walk(Direction),
    Look(Direction),
    CheckPosition { x: i32, y: i32, angle: i32 },
    StopAt{direction: Direction, x: i32, y: i32},
    LongJump,
    HighJump(usize),
}

impl Action {
    pub fn to_engine_command(self) -> String {
        use Action::*;
        use Direction::*;
        match self {
            Walk(Left) | Look(Left) => {"/+left".to_string()},
            Walk(Right) | Look(Right) => {"/+right".to_string()},
            StopAt{direction: Left, ..} => {"/-left".to_string()},
            StopAt{direction: Right, ..} => {"/-right".to_string()},
            LongJump => {"/ljump".to_string()},
            HighJump(_) => {"/hjump".to_string()},
            _ => {"".to_string()}
        }
    }
}

pub struct Actions {
    actions: Vec<Action>,
    current_action: Option<Action>,
}

impl Actions {
    pub fn new() -> Self {
        Self {
            actions: vec![],
            current_action: None,
        }
    }

    pub fn push(&mut self, action: Action) {
        self.actions.push(action)
    }

    pub fn get_new_action(&mut self, current_hedgehog_state: &HedgehogState) -> Option<Action> {
        if self.current_action.is_none() {
            self.current_action = self.actions.pop();
        }

        let Some(action) = &mut self.current_action  else {
            return None;
        };
        
        match action {
            Action::Walk(_) => {}
            Action::Look(_) => {}
            Action::StopAt { .. } => {}
            Action::CheckPosition { .. } => {}
            Action::LongJump => {}
            Action::HighJump(_) => {}
        }

        None
    }
}
