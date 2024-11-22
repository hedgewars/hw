mod action;

use std::collections::HashMap;
use integral_geometry::Point;
use crate::GameField;
use action::*;

pub struct Target {
    point: Point,
    health: i32,
    radius: u32,
    density: f32,

}

pub struct Hedgehog {
    pub(crate) x: f32,
    pub(crate) y: f32,
}

pub struct AI<'a> {
    game_field: &'a GameField,
    targets: Vec<Target>,
    team: Vec<Hedgehog>,
    planned_actions: Option<Actions>,
}

#[derive(Clone)]
struct Waypoint {
    x: f32,
    y: f32,
    ticks: usize,
    damage: usize,
    previous_point: Option<(usize, Action)>,
}

#[derive(Default)]
pub struct Waypoints {
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

impl<'a> AI<'a> {
    pub fn new(game_field: &'a GameField) -> AI<'a> {
        Self {
            game_field,
            targets: vec![],
            team: vec![],
            planned_actions: None,
        }
    }

    pub fn get_team_mut(&mut self) -> &mut Vec<Hedgehog> {
        &mut self.team
    }

    pub fn walk(hedgehog: &Hedgehog) {
        let mut stack = Vec::<usize>::new();
        let mut waypoints = Waypoints::default();

        waypoints.add_keypoint(Waypoint{
            x: hedgehog.x,
            y: hedgehog.y,
            ticks: 0,
            damage: 0,
            previous_point: None,
        });

        while let Some(wp) = stack.pop() {

        }
    }

    pub fn have_plan(&self) -> bool {
        self.planned_actions.is_some()
    }
}
