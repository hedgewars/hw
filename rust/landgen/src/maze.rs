use crate::outline_template_based::outline::OutlinePoints;
use crate::{LandGenerationParameters, LandGenerator};
use integral_geometry::{Point, Polygon, Rect, Size};
use land2d::Land2D;

pub struct MazeTemplate {
    pub width: usize,
    pub height: usize,
    pub cell_size: usize,
    pub inverted: bool,
    pub distortion_limiting_factor: u32,
    pub braidness: usize,
}

pub struct MazeLandGenerator {
    maze_template: MazeTemplate,
}

fn prev_odd(num: usize) -> usize {
    if num & 1 == 0 {
        num - 1
    } else {
        num
    }
}

impl MazeLandGenerator {
    pub fn new(maze_template: MazeTemplate) -> Self {
        Self { maze_template }
    }

    fn generate_outline<I: Iterator<Item = u32>>(
        &self,
        size: &Size,
        play_box: Rect,
        intersections_box: Rect,
        random_numbers: &mut I,
    ) -> OutlinePoints {
        let num_cells = Size::new(
            prev_odd(size.width / self.maze_template.cell_size),
            prev_odd(size.height / self.maze_template.cell_size),
        );

        let num_edges = Size::new(num_cells.width - 1, num_cells.height - 1);
        let seen_cells = Size::new(num_cells.width / 2, num_cells.height / 2);

        let num_steps = if self.maze_template.inverted { 3 } else { 1 };
        let mut step_done = vec![false; num_steps];
        let mut last_cell = vec![Point::diag(0); num_steps];
        let mut came_from_pos = vec![0; num_steps];
        let mut came_from = vec![vec![Point::diag(0); num_steps]; num_cells.area()];

        let mut done = false;
        let mut seen_list = vec![vec![None as Option<usize>; seen_cells.width]; seen_cells.height];
        let mut x_walls = vec![vec![true; seen_cells.width]; seen_cells.height - 1];
        let mut y_walls = vec![vec![true; seen_cells.width - 1]; seen_cells.height];
        let mut x_edge_list = vec![vec![false; num_edges.width]; num_cells.height];
        let mut y_edge_list = vec![vec![false; num_cells.width]; num_edges.height];

        let mut maze = vec![vec![false; num_cells.width]; num_cells.height];

        let off_y = 0;

        for current_step in 0..num_steps {
            let x = random_numbers.next().unwrap_or_default() as usize % (seen_cells.width - 1)
                / num_steps;
            last_cell[current_step] = Point::new(
                (x + current_step * seen_cells.width / num_steps) as i32,
                random_numbers.next().unwrap_or_default() as i32 % seen_cells.height as i32,
            );
        }

        let see_cell = |current_step: usize, start_dir: Point, seen_list: &mut Vec<Vec<Option<usize>>>, x_walls: &mut Vec<Vec<bool>>, y_walls: &mut Vec<Vec<bool>>,
                        last_cell: &mut Vec<Point>, came_from: &mut Vec<Vec<Point>>, came_from_pos: &mut Vec<i32>| {
            let mut dir = start_dir;
            loop {
                let p = dbg!(last_cell[current_step]);
                seen_list[p.y as usize][p.x as usize] = Some(dbg!(current_step));

                let next_dir_clockwise = true;//random_numbers.next().unwrap_or_default() % 2 == 0;

                for _ in 0..5 {
                    let sp = dbg!(p) + dbg!(dir);
                    let when_seen =
                        if sp.x < 0
                            || sp.x >= seen_cells.width as i32
                            || sp.y < 0
                            || sp.y >= seen_cells.height as i32
                        {
                            None
                        } else {
                            Some(seen_list[sp.y as usize][sp.x as usize])
                        }
                    ;

                    match when_seen {
                        None => {
                            // try another direction
                            if dir.x == -1 && p.x > 0 {
                                y_walls[p.y as usize][p.x as usize - 1] = false;
                            }
                            if dir.x == 1 && p.x < seen_cells.width as i32 - 1 {
                                y_walls[p.y as usize][p.x as usize] = false;
                            }
                            if dir.y == -1 && p.y > 0 {
                                x_walls[p.y as usize][p.x as usize] = false;
                            }
                            if dir.y == 1 && p.y < seen_cells.height as i32 - 1 {
                                x_walls[p.y as usize][p.x as usize] = false;
                            }

                            if next_dir_clockwise {
                                dir = dir.rotate90();
                            } else {
                                dir = dir.rotate270();
                            }
                        }
                        Some(None) => {
                            // cell was not seen yet, go there
                            if dir.y == -1 {
                                x_walls[p.y as usize - 1][p.x as usize] = false;
                            }
                            if dir.y == 1 {
                                x_walls[p.y as usize][p.x as usize] = false;
                            }
                            if dir.x == -1 {
                                y_walls[p.y as usize][p.x as usize - 1] = false;
                            }
                            if dir.x == 1 {
                                y_walls[p.y as usize][p.x as usize] = false;
                            }
                            last_cell[current_step] = dbg!(sp);
                            came_from_pos[current_step] += 1;
                            came_from[came_from_pos[current_step] as usize][current_step] = p;
                            return true;
                        }
                        _ => {
                            return true;
                        }
                    }
                }

                last_cell[current_step] = came_from[came_from_pos[current_step] as usize][current_step];
                came_from_pos[current_step] -= 1;

                return came_from_pos[current_step] < 0;
            }
        };

        let mut islands: Vec<Polygon> = vec![];
        let mut polygon: Vec<Point> = vec![];
        let add_vertex = |p: Point, polygon: &mut Vec<Point>| {
            let cell_size = self.maze_template.cell_size as i32;
            let [x, y] = [p.x, p.y].map(|i| {
                if self.maze_template.inverted || i & 1 == 0 {
                    cell_size
                } else {
                    cell_size * 2 / 3
                }
            });
            let new_point =
                Point::new((p.x - 1) * cell_size + x, (p.y - 1) * cell_size + y + off_y);

            let nv = polygon.len();
            if nv > 2 {
                if polygon[nv - 2].x == polygon[nv - 1].x && polygon[nv - 1].x == new_point.x
                    || polygon[nv - 2].y == polygon[nv - 1].y && polygon[nv - 1].y == new_point.y
                {
                    polygon.pop();
                }
            }

            polygon.push(new_point);
        };

        let add_edge = |p: Point, dir: Point, polygon: &mut Vec<Point>, x_edge_list: &mut Vec<Vec<bool>>, y_edge_list: &mut Vec<Vec<bool>>| {
            let mut dir = dir.rotate270();
            let mut next_p = Some(p);

            while let Some(p) = next_p {
                next_p = None;

                for _ in 0..4 {
                    dir = dir.rotate90();
                    let cdir = Point::new(
                        if dir.x < 0 { 0 } else { dir.x },
                        if dir.y < 0 { 0 } else { dir.y },
                    );

                    let np = p + cdir;
                    let edge_list = if dir.x == 0 {
                        &mut *x_edge_list
                    } else {
                        &mut *y_edge_list
                    };
                    if np.x >= 0
                        && np.y > 0
                        && np.x < num_cells.width as i32
                        && np.y < num_cells.height as i32
                        && edge_list[np.y as usize][np.x as usize]
                    {
                        (*edge_list)[np.y as usize][np.x as usize] = false;
                        add_vertex(p + dir + Point::new(1, 1), polygon);
                        next_p = Some(p + dir);
                        break;
                    }
                }
            }
        };

        while !done {
            done = true;

            for current_step in 0..num_steps {
                if !step_done[current_step] {
                    let dir = match random_numbers.next().unwrap_or_default() % 4 {
                        0 => Point::new(0, -1),
                        1 => Point::new(1, 0),
                        2 => Point::new(0, 1),
                        3 => Point::new(-1, 0),
                        _ => panic!(),
                    };
                    step_done[current_step] =
                        see_cell(current_step, dir, &mut seen_list, &mut x_walls, &mut y_walls, &mut last_cell, &mut came_from, &mut came_from_pos);
                    done = false;
                }
            }
        }

        for x in 0..seen_cells.width {
            for y in 0..seen_cells.height {
                if seen_list[y][x].is_some() {
                    maze[y * 2 + 1][x * 2 + 1] = true;
                }
            }

            for y in 0..seen_cells.height - 1 {
                if !x_walls[y][x] {
                    maze[y * 2 + 2][x * 2 + 1] = true;
                }
            }
        }

        for x in 0..seen_cells.width - 1 {
            for y in 0..seen_cells.height {
                if !y_walls[y][x] {
                    maze[y * 2 + 1][x * 2 + 2] = true;
                }
            }
        }

        for x in 0..num_edges.width {
            for y in 0..num_cells.height {
                x_edge_list[y][x] = maze[y][x] != maze[y][x + 1];
            }
        }

        for x in 0..num_cells.width {
            for y in 0..num_edges.height {
                y_edge_list[y][x] = maze[y][x] != maze[y + 1][x];
            }
        }

        for x in 0..num_edges.width {
            for y in 0..num_cells.height {
                if x_edge_list[y][x] {
                    x_edge_list[y][x] = false;
                    add_vertex(Point::new(x as i32 + 1, y as i32 + 1), &mut polygon);
                    add_vertex(Point::new(x as i32 + 1, y as i32), &mut polygon);
                    add_edge(Point::new(x as i32, y as i32 - 1), Point::new(0, -1), &mut polygon, &mut x_edge_list, &mut y_edge_list);

                    islands.push(Polygon::new(&polygon));
                    polygon.clear();
                }
            }
        }

        OutlinePoints {
            islands,
            fill_points: vec![Point::new(1, 1 + off_y)],
            size: *size,
            play_box,
            intersections_box,
        }
    }
}

impl LandGenerator for MazeLandGenerator {
    fn generate_land<T: Copy + PartialEq + Default, I: Iterator<Item = u32>>(
        &self,
        parameters: &LandGenerationParameters<T>,
        random_numbers: &mut I,
    ) -> Land2D<T> {
        let do_invert = false;
        let (basic, zero) = if do_invert {
            (parameters.zero, parameters.basic)
        } else {
            (parameters.basic, parameters.zero)
        };

        let land_size = Size::new(self.maze_template.width, self.maze_template.height);
        let mut land = Land2D::new(&land_size, basic);

        let mut points = self.generate_outline(
            &land.size().size(),
            Rect::at_origin(land_size).with_margin(land_size.to_square().width as i32 * -2),
            land.play_box(),
            random_numbers,
        );

        if !parameters.skip_distort {
            points.distort(parameters.distance_divisor, random_numbers);
        }

        if !parameters.skip_bezier {
            points.bezierize(5);
        }

        points.draw(&mut land, zero);

        for p in &points.fill_points {
            land.fill(*p, zero, zero)
        }

        points.draw(&mut land, basic);

        land
    }
}
