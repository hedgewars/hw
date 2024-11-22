#[derive(Clone)]
pub enum Direction {
    Left,
    Right
}
#[derive(Clone)]
pub enum Action {
    Walk(Direction),
    LongJump,
    HighJump(usize)
}

pub struct Actions {
    actions: Vec<Action>
}

impl Actions {
    pub fn new() -> Self {
        Self {
            actions: vec![],
        }
    }

    pub fn push(&mut self, action: Action) {
        self.actions.push(action)
    }

    pub fn pop(&mut self) -> Option<Action> {
        self.actions.pop()
    }
}