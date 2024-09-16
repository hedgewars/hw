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
    pub braidness: u32,
}

struct Maze {
    inverted: bool,
    braidness: u32,
    off_y: i32,
    num_cells: Size,
    num_edges: Size,
    seen_cells: Size,
    cell_size: usize,
    seen_list: Vec<Vec<Option<usize>>>,
    walls: Vec<Vec<Vec<bool>>>,
    edge_list: Vec<Vec<Vec<bool>>>,
    last_cell: Vec<Point>,
    came_from: Vec<Vec<Point>>,
    came_from_pos: Vec<i32>,
}

fn in_line(p1: &Point, p2: &Point, p3: &Point) -> bool {
    p1.x == p2.x && p2.x == p3.x || p1.y == p2.y && p2.y == p3.y
}

#[derive(Clone, Copy)]
struct Direction(Point);

impl Direction {
    #[inline]
    pub fn new(direction: usize) -> Self {
        match direction % 4 {
            0 => Self(Point::new(0, -1)),
            1 => Self(Point::new(1, 0)),
            2 => Self(Point::new(0, 1)),
            3 => Self(Point::new(-1, 0)),
            _ => panic!("Impossible"),
        }
    }

    #[inline]
    pub fn rotate_right(self) -> Self {
        Self(self.0.rotate90())
    }

    #[inline]
    pub fn rotate_left(self) -> Self {
        Self(self.0.rotate270())
    }

    #[inline]
    pub fn to_edge(self) -> Self {
        Self(Point::new(
            if self.0.x < 0 { 0 } else { self.0.x },
            if self.0.y < 0 { 0 } else { self.0.y },
        ))
    }

    #[inline]
    pub fn orientation(&self) -> usize {
        if self.0.x == 0 {
            0
        } else {
            1
        }
    }
}

impl Maze {
    pub fn new<I: Iterator<Item = u32>>(
        size: &Size,
        cell_size: usize,
        num_steps: usize,
        inverted: bool,
        braidness: u32,
        random_numbers: &mut I,
    ) -> Self {
        let num_cells = Size::new(
            prev_odd(size.width / cell_size),
            prev_odd(size.height / cell_size),
        );

        let num_edges = Size::new(num_cells.width - 1, num_cells.height - 1);
        let seen_cells = Size::new(num_cells.width / 2, num_cells.height / 2);

        let mut last_cell = vec![Point::diag(0); num_steps];
        let came_from_pos = vec![0; num_steps];
        let came_from = vec![vec![Point::diag(0); num_steps]; num_cells.area()];

        let seen_list = vec![vec![None as Option<usize>; seen_cells.width]; seen_cells.height];
        let walls = vec![vec![vec![true; seen_cells.width]; seen_cells.height]; 2];
        let edge_list = vec![vec![vec![false; num_cells.width]; num_cells.height]; 2];

        for current_step in 0..num_steps {
            let x = random_numbers.next().unwrap_or_default() as usize % (seen_cells.width - 1)
                / num_steps;
            last_cell[current_step] = Point::new(
                (x + current_step * seen_cells.width / num_steps) as i32,
                random_numbers.next().unwrap_or_default() as i32 % seen_cells.height as i32,
            );
        }

        Self {
            inverted,
            braidness,
            off_y: ((size.height - num_cells.height * cell_size) / 2) as i32,
            num_cells,
            num_edges,
            seen_cells,
            cell_size,
            seen_list,
            walls,
            edge_list,
            last_cell,
            came_from,
            came_from_pos,
        }
    }

    fn see_cell<I: Iterator<Item = u32>>(
        &mut self,
        current_step: usize,
        start_dir: Direction,
        random_numbers: &mut I,
    ) -> bool {
        let mut dir = start_dir;
        loop {
            let p = self.last_cell[current_step];
            self.seen_list[p.y as usize][p.x as usize] = Some(current_step);

            let next_dir_clockwise = random_numbers.next().unwrap_or_default() % 2 == 0;

            for _ in 0..5 {
                let sp = p + dir.0;
                let when_seen = if sp.x < 0
                    || sp.x >= self.seen_cells.width as i32
                    || sp.y < 0
                    || sp.y >= self.seen_cells.height as i32
                {
                    Some(current_step)
                } else {
                    self.seen_list[sp.y as usize][sp.x as usize]
                };

                match when_seen {
                    Some(a) if a == current_step => {
                        // try another direction
                        if !self.inverted
                            && random_numbers.next().unwrap_or_default() % self.braidness == 0
                        {
                            if dir.0.x == -1 && p.x > 0 {
                                self.walls[dir.orientation()][p.y as usize][p.x as usize - 1] =
                                    false;
                            }
                            if dir.0.x == 1 && p.x < self.seen_cells.width as i32 - 1 {
                                self.walls[dir.orientation()][p.y as usize][p.x as usize] = false;
                            }
                            if dir.0.y == -1 && p.y > 0 {
                                self.walls[dir.orientation()][p.y as usize - 1][p.x as usize] =
                                    false;
                            }
                            if dir.0.y == 1 && p.y < self.seen_cells.height as i32 - 1 {
                                self.walls[dir.orientation()][p.y as usize][p.x as usize] = false;
                            }
                        }

                        if next_dir_clockwise {
                            dir = dir.rotate_right();
                        } else {
                            dir = dir.rotate_left();
                        }
                    }
                    None => {
                        // cell was not seen yet, go there
                        let o_dir = dir.rotate_right().rotate_right();
                        let op = p - o_dir.to_edge().0;
                        self.walls[o_dir.orientation()][op.y as usize][op.x as usize] = false;
                        self.last_cell[current_step] = sp;
                        self.came_from_pos[current_step] += 1;
                        self.came_from[self.came_from_pos[current_step] as usize][current_step] = p;
                        return false;
                    }
                    _ => {
                        return true;
                    }
                }
            }

            self.last_cell[current_step] =
                self.came_from[self.came_from_pos[current_step] as usize][current_step];
            self.came_from_pos[current_step] -= 1;

            if self.came_from_pos[current_step] < 0 {
                return true;
            }
        }
    }

    fn add_vertex(&mut self, p: Point, polygon: &mut Vec<Point>) {
        let [x, y] = [p.x, p.y].map(|i| {
            if self.inverted || i & 1 == 0 {
                self.cell_size
            } else {
                self.cell_size * 2 / 3
            }
        });
        let new_point = Point::new(
            (p.x - 1) * self.cell_size as i32 + x as i32,
            (p.y - 1) * self.cell_size as i32 + y as i32 + self.off_y,
        );

        let nv = polygon.len();
        if nv > 2 {
            if in_line(&polygon[nv - 2], &polygon[nv - 1], &new_point) {
                polygon.pop();
            }
        }

        polygon.push(new_point);
    }

    fn add_edge(&mut self, p: Point, mut dir: Direction, polygon: &mut Vec<Point>) {
        let mut next_p = Some(p);

        while let Some(p) = next_p {
            next_p = None;

            for _ in 0..4 {
                let cdir = dir.to_edge();

                let np = p + cdir.0;

                if np.x >= 0
                    && np.y >= 0
                    && np.x < self.num_cells.width as i32
                    && np.y < self.num_cells.height as i32
                    && self.edge_list[dir.orientation()][np.y as usize][np.x as usize]
                {
                    self.edge_list[dir.orientation()][np.y as usize][np.x as usize] = false;
                    self.add_vertex(p + dir.0 + Point::new(1, 1), polygon);
                    next_p = Some(p + dir.0);
                    break;
                }

                dir = dir.rotate_right();
            }
        }
    }

    pub fn to_islands(mut self) -> (Vec<Polygon>, Vec<Point>) {
        let mut islands: Vec<Polygon> = vec![];
        let mut polygon: Vec<Point> = vec![];
        let mut maze = vec![vec![false; self.num_cells.width]; self.num_cells.height];

        for x in 0..self.seen_cells.width {
            for y in 0..self.seen_cells.height {
                if self.seen_list[y][x].is_some() {
                    maze[y * 2 + 1][x * 2 + 1] = true;
                }
            }

            for y in 0..self.seen_cells.height - 1 {
                if !self.walls[0][y][x] {
                    maze[y * 2 + 2][x * 2 + 1] = true;
                }
            }
        }

        for x in 0..self.seen_cells.width - 1 {
            for y in 0..self.seen_cells.height {
                if !self.walls[1][y][x] {
                    maze[y * 2 + 1][x * 2 + 2] = true;
                }
            }
        }

        for x in 0..self.num_edges.width {
            for y in 0..self.num_cells.height {
                self.edge_list[0][y][x] = maze[y][x] != maze[y][x + 1];
            }
        }

        for x in 0..self.num_cells.width {
            for y in 0..self.num_edges.height {
                self.edge_list[1][y][x] = maze[y][x] != maze[y + 1][x];
            }
        }

        let mut fill_points = vec![];

        for y in 0..self.num_cells.height {
            for x in 0..self.num_cells.width {
                if maze[y][x] {
                    let half_cell = self.cell_size / 2;
                    let fill_point = Point::new(
                        (x * self.cell_size + half_cell) as i32,
                        (y * self.cell_size + half_cell) as i32 + self.off_y,
                    );
                    islands.push(Polygon::new(&[fill_point]));
                    fill_points.push(fill_point);
                }
            }
        }

        for x in 0..self.num_edges.width {
            for y in 0..self.num_cells.height {
                if self.edge_list[0][y][x] {
                    self.edge_list[0][y][x] = false;
                    self.add_vertex(Point::new(x as i32 + 1, y as i32 + 1), &mut polygon);
                    self.add_vertex(Point::new(x as i32 + 1, y as i32), &mut polygon);
                    self.add_edge(
                        Point::new(x as i32, y as i32 - 1),
                        Direction::new(0),
                        &mut polygon,
                    );

                    if polygon.len() > 4 {
                        if in_line(polygon.last().unwrap(), &polygon[0], &polygon[1]) {
                            polygon.pop();
                        }

                        /*
                                                for p in &polygon {
                                                    println!("{} {}", p.x, p.y);
                                                }
                                                println!("\ne\n");
                        */

                        islands.push(Polygon::new(&polygon));
                    }
                    polygon.clear();
                }
            }
        }

        (islands, fill_points)
    }
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
        let num_steps = if self.maze_template.inverted { 3 } else { 1 };
        let mut step_done = vec![false; num_steps];
        let mut done = false;

        let mut maze = Maze::new(
            &size,
            self.maze_template.cell_size,
            num_steps,
            self.maze_template.inverted,
            self.maze_template.braidness,
            random_numbers,
        );

        while !done {
            done = true;

            for current_step in 0..num_steps {
                if !step_done[current_step] {
                    let dir = Direction::new(random_numbers.next().unwrap_or_default() as usize);
                    step_done[current_step] = maze.see_cell(current_step, dir, random_numbers);
                    done = false;
                }
            }
        }

        let (islands, fill_points) = maze.to_islands();

        OutlinePoints {
            islands,
            fill_points,
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
        let do_invert = self.maze_template.inverted;
        let (basic, zero) = if do_invert {
            (parameters.zero, parameters.basic)
        } else {
            (parameters.basic, parameters.zero)
        };

        let land_size = Size::new(self.maze_template.width, self.maze_template.height);
        let mut land = Land2D::new(&land_size, basic);

        let mut points = self.generate_outline(
            &land.size().size(),
            land.play_box(), //??? Rect::at_origin(land_size).with_margin(land_size.to_square().width as i32 * -2),
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

        land
    }
}
