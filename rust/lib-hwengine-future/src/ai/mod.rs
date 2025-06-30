mod action;
pub mod ammo;
mod attack_tests;

use crate::{GameField, HedgehogState};
use action::*;
use integral_geometry::Point;
use std::collections::HashMap;

pub struct Target {
    point: Point,
    health: i32,
    radius: u32,
    density: f32,
}

pub struct Hedgehog {
    pub(crate) x: f32,
    pub(crate) y: f32,
    pub(crate) ammo: [u32; ammo::AmmoType::Count as usize],
}

pub struct AI<'a> {
    game_field: &'a GameField,
    ammo: [u32; ammo::AmmoType::Count as usize],
    targets: Vec<Target>,
    team: Vec<Hedgehog>,
    actions: Option<Actions>,
}

#[derive(Clone)]
pub(crate) struct Waypoint {
    x: f32,
    y: f32,
    ticks: usize,
    damage: usize,
    previous_point: Option<(usize, Action)>,
}

#[derive(Default)]
pub(crate) struct Waypoints {
    key_points: Vec<Waypoint>,
    points: HashMap<Point, Waypoint>,
}

impl Waypoints {
    fn add_keypoint(&mut self, waypoint: Waypoint) {
        let [x, y] = [waypoint.x, waypoint.y].map(|i| i as i32);
        let point = Point::new(x, y);
        self.key_points.push(waypoint.clone());
        self.points.insert(point, waypoint);
    }
}

impl IntoIterator for Waypoints {
    type Item = Waypoint;
    type IntoIter = std::collections::hash_map::IntoValues<Point, Waypoint>;

    fn into_iter(self) -> Self::IntoIter {
        self.points.into_values()
    }
}

impl<'a> AI<'a> {
    pub fn new(game_field: &'a GameField) -> AI<'a> {
        Self {
            game_field,
            ammo: [0; ammo::AmmoType::Count as usize],
            targets: vec![],
            team: vec![],
            actions: None,
        }
    }

    pub fn set_available_ammo(&mut self, ammo: [u32; ammo::AmmoType::Count as usize]) {
        self.ammo = ammo;
    }

    pub fn get_team_mut(&mut self) -> &mut Vec<Hedgehog> {
        &mut self.team
    }

    pub fn walk(&self, hedgehog: &Hedgehog) {
        let mut stack = Vec::<usize>::new();
        let mut waypoints = Waypoints::default();

        waypoints.add_keypoint(Waypoint {
            x: hedgehog.x,
            y: hedgehog.y,
            ticks: 0,
            damage: 0,
            previous_point: None,
        });
        stack.push(0);

        while let Some(waypoint) = stack.pop() {
            // go left
            // go right
        }

        for Waypoint { x, y, .. } in waypoints {
            self.analyze_position_attacks(x, y);
        }
    }

    fn analyze_position_attacks(&self, x: f32, y: f32) {
        self.ammo
            .iter()
            .enumerate()
            .filter(|&(_, &count)| count > 0u32)
            .for_each(|(a, &count)| {
                let a = ammo::AmmoType::try_from(a).expect("What are you iterating over?");

                a.analyze_attacks(self.game_field, &self.targets, x, y)
            });
    }

    pub fn have_plan(&self) -> bool {
        self.actions.is_some()
    }

    pub fn plan(&mut self) {
        // this is just a test:
        let mut actions = Actions::new();
        actions.push(Action::Walk(Direction::Left));
        actions.push(Action::StopAt { x: 0, y: 0 });
        self.actions = Some(actions);
    }

    pub fn get_action(&mut self, current_hedgehog_state: &HedgehogState) -> String {
        let Some(actions) = &mut self.actions else {
            return String::new();
        };
        actions
            .get_new_action(current_hedgehog_state)
            .map(Action::to_engine_command)
            .unwrap_or_default()
    }
}
