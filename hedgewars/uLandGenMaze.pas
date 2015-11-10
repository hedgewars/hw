{$INCLUDE "options.inc"}

unit uLandGenMaze;

interface

procedure GenMaze;

implementation

uses uRandom, uLandOutline, uLandTemplates, uVariables, uFloat, uConsts, uLandGenTemplateBased, uUtils;

type direction = record x, y: LongInt; end;
const DIR_N: direction = (x: 0; y: -1);
    DIR_E: direction = (x: 1; y: 0);
    DIR_S: direction = (x: 0; y: 1);
    DIR_W: direction = (x: -1; y: 0);

operator = (const a, b: direction) c: Boolean;
begin
    c := (a.x = b.x) and (a.y = b.y);
end;

const small_cell_size = 128;
    medium_cell_size = 192;
    large_cell_size = 256;
    braidness = 10;

type
   cell_t = record x,y         : LongInt
        end;

var x, y               : LongInt;
    cellsize               : LongInt; //selected by the user in the gui
    seen_cells_x, seen_cells_y : LongInt; //number of cells that can be visited by the generator, that is every second cell in x and y direction. the cells between there are walls that will be removed when we move from one cell to another
    num_edges_x, num_edges_y   : LongInt; //number of resulting edges that need to be vertexificated
    num_cells_x, num_cells_y   : LongInt; //actual number of cells, depending on cell size


    seen_list              : array of array of LongInt;
    xwalls             : array of array of Boolean;
    ywalls             : array of array of Boolean;
    x_edge_list            : array of array of Boolean;
    y_edge_list            : array of array of Boolean;
    maze               : array of array of Boolean;

    pa                 : TPixAr;
    num_vertices           : LongInt;
    off_y              : LongInt;
    num_steps              : LongInt;
    current_step           : LongInt;

    step_done              : array of Boolean;

    done               : Boolean;

{   last_cell              : array 0..3 of record x, y :LongInt ; end;
    came_from              : array of array of record x, y: LongInt; end;
    came_from_pos          : array of LongInt;
}
    last_cell : array of cell_t;
    came_from : array of array of cell_t;
    came_from_pos: array of LongInt;

    maze_inverted                      : Boolean;

function when_seen(x: LongInt; y: LongInt): LongInt;
begin
if (x < 0) or (x >= seen_cells_x) or (y < 0) or (y >= seen_cells_y) then
    when_seen := current_step
else
    when_seen := seen_list[x, y];
end;

function is_x_edge(x, y: LongInt): Boolean;
begin
if (x < 0) or (x > num_edges_x) or (y < 0) or (y > num_cells_y) then
    is_x_edge := false
else
    is_x_edge := x_edge_list[x, y];
end;

function is_y_edge(x, y: LongInt): Boolean;
begin
if (x < 0) or (x > num_cells_x) or (y < 0) or (y > num_edges_y) then
    is_y_edge := false
else
    is_y_edge := y_edge_list[x, y];
end;

procedure see_cell;
var dir: direction;
    tries: LongInt;
    x, y: LongInt;
    found_cell: Boolean;
    next_dir_clockwise: Boolean;

begin
x := last_cell[current_step].x;
y := last_cell[current_step].y;
seen_list[x, y] := current_step;
case GetRandom(4) of
    0: dir := DIR_N;
    1: dir := DIR_E;
    2: dir := DIR_S;
    3: dir := DIR_W;
end;
tries := 0;
found_cell := false;
if getrandom(2) = 1 then
    next_dir_clockwise := true
else
    next_dir_clockwise := false;

while (tries < 5) and (not found_cell) do
begin
    if when_seen(x + dir.x, y + dir.y) = current_step then //we are seeing ourselves, try another direction
    begin
        //we have already seen the target cell, decide if we should remove the wall anyway
        //(or put a wall there if maze_inverted, but we are not doing that right now)
        if (not maze_inverted) and (GetRandom(braidness) = 0) then
        //or just warn that inverted+braid+indestructible terrain != good idea
        begin
            case dir.x of

                -1:
                if x > 0 then
                    ywalls[x-1, y] := false;
                1:
                if x < seen_cells_x - 1 then
                    ywalls[x, y] := false;
            end;
            case dir.y of
                -1:
                if y > 0 then
                    xwalls[x, y-1] := false;
                1:
                if y < seen_cells_y - 1 then
                    xwalls[x, y] := false;
            end;
        end;
        if next_dir_clockwise then
        begin
            if dir = DIR_N then
                dir := DIR_E
            else if dir = DIR_E then
                dir := DIR_S
            else if dir = DIR_S then
                dir := DIR_W
            else
                dir := DIR_N;
        end
        else
        begin
            if dir = DIR_N then
                dir := DIR_W
            else if dir = DIR_E then
                dir := DIR_N
            else if dir = DIR_S then
                dir := DIR_E
            else
                dir := DIR_S;
        end
    end
    else if when_seen(x + dir.x, y + dir.y) = -1 then //cell was not seen yet, go there
        begin
        case dir.y of
            -1: xwalls[x, y-1] := false;
            1: xwalls[x, y] := false;
        end;
        case dir.x of
            -1: ywalls[x-1, y] := false;
            1: ywalls[x, y] := false;
        end;
        last_cell[current_step].x := x+dir.x;
        last_cell[current_step].y := y+dir.y;
        came_from_pos[current_step] := came_from_pos[current_step] + 1;
        came_from[current_step, came_from_pos[current_step]].x := x;
        came_from[current_step, came_from_pos[current_step]].y := y;
        found_cell := true;
        end
    else //we are seeing someone else, quit
        begin
        step_done[current_step] := true;
        found_cell := true;
        end;

    tries := tries + 1;
end;
if not found_cell then
    begin
    last_cell[current_step].x := came_from[current_step, came_from_pos[current_step]].x;
    last_cell[current_step].y := came_from[current_step, came_from_pos[current_step]].y;
    came_from_pos[current_step] := came_from_pos[current_step] - 1;

    if came_from_pos[current_step] >= 0 then
        see_cell()

    else
        step_done[current_step] := true;
    end;
end;

procedure add_vertex(x, y: LongInt);
var tmp_x, tmp_y, nx, ny: LongInt;
begin
    if x = NTPX then
    begin
        if pa.ar[num_vertices - 6].x = NTPX then
        begin
            num_vertices := num_vertices - 6;
        end
        else
        begin
            pa.ar[num_vertices].x := NTPX;
            pa.ar[num_vertices].y := 0;
        end
    end
    else
    begin
        if maze_inverted or (x mod 2 = 0) then
            tmp_x := cellsize
        else
            tmp_x := cellsize * 2 div 3;

        if maze_inverted or (y mod 2 = 0) then
            tmp_y := cellsize
        else
            tmp_y := cellsize * 2 div 3;

        nx:= (x-1)*cellsize + tmp_x;
        ny:= (y-1)*cellsize + tmp_y + off_y;

        if num_vertices > 2 then
            if ((pa.ar[num_vertices - 2].x = pa.ar[num_vertices - 1].x) and (pa.ar[num_vertices - 1].x = nx))
                or ((pa.ar[num_vertices - 2].y = pa.ar[num_vertices - 1].y) and (pa.ar[num_vertices - 1].y = ny))
                then
                dec(num_vertices);

        pa.ar[num_vertices].x := nx;
        pa.ar[num_vertices].y := ny;
    end;

    num_vertices := num_vertices + 1;
end;

procedure add_edge(x, y: LongInt; dir: direction);
var i: LongInt;
begin
if dir = DIR_N then
    begin
    dir := DIR_W
    end
else if dir = DIR_E then
    begin
    dir := DIR_N
    end
else if dir = DIR_S then
    begin
    dir := DIR_E
    end
else
    begin
    dir := DIR_S;
    end;

for i := 0 to 3 do
    begin
    if dir = DIR_N then
        dir := DIR_E
    else if dir = DIR_E then
        dir := DIR_S
    else if dir = DIR_S then
        dir := DIR_W
    else
        dir := DIR_N;

    if (dir = DIR_N) and is_x_edge(x, y) then
        begin
            x_edge_list[x, y] := false;
            add_vertex(x+1, y);
            add_edge(x, y-1, DIR_N);
            break;
        end;

    if (dir = DIR_E) and is_y_edge(x+1, y) then
        begin
            y_edge_list[x+1, y] := false;
            add_vertex(x+2, y+1);
            add_edge(x+1, y, DIR_E);
            break;
        end;

    if (dir = DIR_S) and is_x_edge(x, y+1) then
        begin
            x_edge_list[x, y+1] := false;
            add_vertex(x+1, y+2);
            add_edge(x, y+1, DIR_S);
            break;
        end;

    if (dir = DIR_W) and is_y_edge(x, y) then
        begin
            y_edge_list[x, y] := false;
            add_vertex(x, y+1);
            add_edge(x-1, y, DIR_W);
            break;
        end;
    end;

end;

procedure GenMaze;
var i: Longword;
begin
case cTemplateFilter of
    0: begin
       cellsize := small_cell_size;
       maze_inverted := false;
       minDistance:= max(cFeatureSize*8,32);
       dabDiv:= 150;
       end;
    1: begin
       cellsize := medium_cell_size;
       minDistance:= max(cFeatureSize*6,20);
       maze_inverted := false;
       dabDiv:= 100;
       end;
    2: begin
       cellsize := large_cell_size;
       minDistance:= max(cFeatureSize*5,12);
       maze_inverted := false;
       dabDiv:= 90;
       end;
    3: begin
       cellsize := small_cell_size;
       minDistance:= max(cFeatureSize*8,32);
       maze_inverted := true;
       dabDiv:= 130;
       end;
    4: begin
       cellsize := medium_cell_size;
       minDistance:= max(cFeatureSize*6,20);
       maze_inverted := true;
       dabDiv:= 100;
       end;
    5: begin
       cellsize := large_cell_size;
       minDistance:= max(cFeatureSize*5,12);
       maze_inverted := true;
       dabDiv:= 85;
       end;
    end;

num_cells_x := LAND_WIDTH div cellsize;
if not odd(num_cells_x) then
    num_cells_x := num_cells_x - 1; //needs to be odd

num_cells_y := LAND_HEIGHT div cellsize;
if not odd(num_cells_y) then
    num_cells_y := num_cells_y - 1;

num_edges_x := num_cells_x - 1;
num_edges_y := num_cells_y - 1;

seen_cells_x := num_cells_x div 2;
seen_cells_y := num_cells_y div 2;

if maze_inverted then
    num_steps := 3 //TODO randomize, between 3 and 5?
else
    num_steps := 1;

SetLength(step_done, num_steps);
SetLength(last_cell, num_steps);
SetLength(came_from_pos, num_steps);
SetLength(came_from, num_steps, num_cells_x*num_cells_y);

done := false;

for current_step := 0 to num_steps - 1 do
    begin
    step_done[current_step] := false;
    came_from_pos[current_step] := 0;
    end;

current_step := 0;


SetLength(seen_list, seen_cells_x, seen_cells_y);
SetLength(xwalls, seen_cells_x, seen_cells_y - 1);
SetLength(ywalls, seen_cells_x - 1, seen_cells_y);
SetLength(x_edge_list, num_edges_x, num_cells_y);
SetLength(y_edge_list, num_cells_x, num_edges_y);
SetLength(maze, num_cells_x, num_cells_y);


num_vertices := 0;

playHeight := num_cells_y * cellsize;
playWidth := num_cells_x * cellsize;
off_y := LAND_HEIGHT - playHeight;

for x := 0 to playWidth do
    for y := 0 to off_y - 1 do
        Land[y, x] := 0;

for x := 0 to playWidth do
    for y := off_y to LAND_HEIGHT - 1 do
        Land[y, x] := lfBasic;

for y := 0 to num_cells_y - 1 do
    for x := 0 to num_cells_x - 1 do
        maze[x, y] := false;

for x := 0 to seen_cells_x - 1 do
    for y := 0 to seen_cells_y - 2 do
        xwalls[x, y] := true;

for x := 0 to seen_cells_x - 2 do
    for y := 0 to seen_cells_y - 1 do
        ywalls[x, y] := true;

for x := 0 to seen_cells_x - 1 do
    for y := 0 to seen_cells_y - 1 do
        seen_list[x, y] := -1;

for x := 0 to num_edges_x - 1 do
    for y := 0 to num_cells_y - 1 do
        x_edge_list[x, y] := false;

for x := 0 to num_cells_x - 1 do
    for y := 0 to num_edges_y - 1 do
        y_edge_list[x, y] := false;

for current_step := 0 to num_steps-1 do
    begin
    x := GetRandom(seen_cells_x - 1) div LongWord(num_steps);
    last_cell[current_step].x := x + current_step * seen_cells_x div num_steps;
    last_cell[current_step].y := GetRandom(seen_cells_y);
end;

while not done do
    begin
    done := true;
    for current_step := 0 to num_steps-1 do
        begin
        if not step_done[current_step] then
            begin
            see_cell;
            done := false;
            end;
        end;
    end;

for x := 0 to seen_cells_x - 1 do
    for y := 0 to seen_cells_y - 1 do
        if seen_list[x, y] > -1 then
            maze[(x+1)*2-1, (y+1)*2-1] := true;

for x := 0 to seen_cells_x - 1 do
    for y := 0 to seen_cells_y - 2 do
        if not xwalls[x, y] then
            maze[x*2 + 1, y*2 + 2] := true;


for x := 0 to seen_cells_x - 2 do
     for y := 0 to seen_cells_y - 1 do
        if not ywalls[x, y] then
            maze[x*2 + 2, y*2 + 1] := true;

for x := 0 to num_edges_x - 1 do
    for y := 0 to num_cells_y - 1 do
        if maze[x, y] xor maze[x+1, y] then
            x_edge_list[x, y] := true
        else
            x_edge_list[x, y] := false;

for x := 0 to num_cells_x - 1 do
    for y := 0 to num_edges_y - 1 do
        if maze[x, y] xor maze[x, y+1] then
            y_edge_list[x, y] := true
        else
            y_edge_list[x, y] := false;

for x := 0 to num_edges_x - 1 do
    for y := 0 to num_cells_y - 1 do
        if x_edge_list[x, y] then
            begin
            x_edge_list[x, y] := false;
            add_vertex(x+1, y+1);
            add_vertex(x+1, y);
            add_edge(x, y-1, DIR_N);
            add_vertex(NTPX, 0);
            end;

pa.count := num_vertices;

leftX:= 0;
rightX:= playWidth;
topY:= off_y;

// fill point
pa.ar[pa.Count].x:= 1;
pa.ar[pa.Count].y:= 1 + off_y;

{
for i:= 0 to pa.Count - 1 do
    begin
        system.writeln(pa.ar[i].x, ', ', pa.ar[i].y);
    end;
}

// divide while it divides
repeat
    i:= pa.Count;
    DivideEdges(1, pa)
until i = pa.Count;

// make it smooth
BezierizeEdge(pa, _0_2);

DrawEdge(pa, 0);

if maze_inverted then
    FillLand(1, 1 + off_y, 0, 0)
else
    begin
    x := 0;
    while Land[cellsize div 2 + cellsize + off_y, x] = lfBasic do
        x := x + 1;
    while Land[cellsize div 2 + cellsize + off_y, x] = 0 do
        x := x + 1;
    FillLand(x+1, cellsize div 2 + cellsize + off_y, 0, 0);
    end;

MaxHedgehogs:= 32;
if (GameFlags and gfDisableGirders) <> 0 then
    hasGirders:= false
else
    hasGirders := true;

hasBorder := false;
end;

end.
