use crate::ai_state::action::Action;
use integral_geometry::Point;
use std::cmp::Ordering;
use std::collections::hash_map::Iter;
use std::collections::HashMap;

#[derive(Clone)]
pub(crate) struct Waypoint {
    pub x: f32,
    pub y: f32,
    pub ticks: usize,
    pub previous_point: Option<(Point, Action)>,
}

impl PartialEq for Waypoint {
    fn eq(&self, other: &Self) -> bool {
        self.ticks == other.ticks
    }
}

impl Eq for Waypoint {}

impl Ord for Waypoint {
    fn cmp(&self, other: &Self) -> Ordering {
        other.ticks.cmp(&self.ticks)
    }
}

impl PartialOrd for Waypoint {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl From<&Waypoint> for Point {
    fn from(waypoint: &Waypoint) -> Self {
        let [x, y] = [waypoint.x, waypoint.y].map(|i| i as i32);
        Point::new(x, y)
    }
}

#[derive(Default)]
pub(crate) struct Waypoints {
    points: HashMap<Point, Waypoint>,
}

impl Waypoints {
    pub(crate) fn add_point(&mut self, waypoint: &Waypoint) -> bool {
        let key = waypoint.into();

        if let Some(w) = self.points.get_mut(&key) {
            if waypoint.ticks < w.ticks {
                *w = waypoint.clone();
                true
            } else {
                false
            }
        } else {
            self.points.insert(key, waypoint.clone());
            true
        }
    }

    pub(crate) fn get_waypoint(&self, point: &Point) -> Waypoint {
        self.points
            .get(point)
            .expect("All points registered")
            .clone()
    }

    pub(crate) fn iter(&self) -> Iter<'_, Point, Waypoint> {
        self.points.iter()
    }

    pub(crate) fn len(&self) -> usize {
        self.points.len()
    }
}

impl IntoIterator for Waypoints {
    type Item = Waypoint;
    type IntoIter = std::collections::hash_map::IntoValues<Point, Waypoint>;

    fn into_iter(self) -> Self::IntoIter {
        self.points.into_values()
    }
}
