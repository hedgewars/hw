pub struct Point {
    x: i32,
    y: i32,
}

pub struct Outline {
    points: Vec<Point>,
}

fn check_intersect(v1: &Point, v2: &Point, v3: &Point, v4: &Point) -> bool {
    let dm: i32 = (v4.y - v3.y) * (v2.x - v1.x) - (v4.x - v3.x) * (v2.y - v1.y);

    if dm == 0 {
        return false;
    }

    let c1: i32 = (v4.x - v3.x) * (v1.y - v3.y) - (v4.y - v3.y) * (v1.x - v3.x);

    if dm > 0 {
        if (c1 < 0) || (c1 > dm) {
            return false;
        }
    } else {
        if (c1 > 0) || (c1 < dm) {
            return false;
        }
    }

    let c2: i32 = (v2.x - v3.x) * (v1.y - v3.y) - (v2.y - v3.y) * (v1.x - v3.x);

    if dm > 0 {
        if (c2 < 0) || (c2 > dm) {
            return false;
        }
    } else {
        if (c2 > 0) || (c2 < dm) {
            return false;
        }
    }

    true
}

impl Outline {
    fn check_intersects_self_at_index(&self, index: usize) -> bool {
        if index <= 0 || index > self.points.len() {
            return false;
        }

        for i in 1..=self.points.len() - 3 {
            if i <= index - 1 || i >= index + 2 {
                if i != index - 1 && check_intersect(
                    &self.points[index],
                    &self.points[index - 1],
                    &self.points[i],
                    &self.points[i - 1],
                ) {
                    return true;
                }
                if i != index + 2 && check_intersect(
                    &self.points[index],
                    &self.points[index + 1],
                    &self.points[i],
                    &self.points[i - 1],
                ) {
                    return true;
                }
            }
        }

        false
    }
}

#[cfg(test)]
#[test]
fn intersection() {
    let p1 = Point{x: 0, y: 0};
    let p2 = Point{x: 0, y: 10};
    let p3 = Point{x: -5, y: 5};
    let p4 = Point{x: 5, y: 5};
    let p5 = Point{x: 5, y: 16};

    assert!(check_intersect(&p1, &p2, &p3, &p4));
    assert!(!check_intersect(&p1, &p2, &p3, &p5));
}
