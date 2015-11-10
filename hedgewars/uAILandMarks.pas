unit uAILandMarks;

interface
const
    markWalkedHere = $01;
    markHJumped    = $02;
    markLJumped    = $04;

procedure addMark(X, Y: LongInt; mark: byte);
function  checkMark(X, Y: LongInt; mark: byte) : boolean;
procedure clearAllMarks;
procedure clearMarks(mark: byte);
procedure setAILandMarks;

procedure initModule;
procedure freeModule;

implementation
uses uVariables;

const gr = 2;

var marks: array of array of byte;
    WIDTH, HEIGHT: Longword;

procedure addMark(X, Y: LongInt; mark: byte);
begin
    if((X and LAND_WIDTH_MASK) = 0) and ((Y and LAND_HEIGHT_MASK) = 0) then
        begin
        X:= X shr gr;
        Y:= Y shr gr;
        marks[Y, X]:= marks[Y, X] or mark
        end
end;

function  checkMark(X, Y: LongInt; mark: byte) : boolean;
begin
    checkMark:= ((X and LAND_WIDTH_MASK) = 0)
        and ((Y and LAND_HEIGHT_MASK) = 0)
        and ((marks[Y shr gr, X shr gr] and mark) <> 0)
end;

procedure clearAllMarks;
var
    Y, X: Longword;
begin
    for Y:= 0 to Pred(HEIGHT) do
        for X:= 0 to Pred(WIDTH) do
            marks[Y, X]:= 0
end;

procedure clearMarks(mark: byte);
var
    Y, X: Longword;
begin
    for Y:= 0 to Pred(HEIGHT) do
        for X:= 0 to Pred(WIDTH) do
            marks[Y, X]:= marks[Y, X] and (not mark)
end;

procedure setAILandMarks;
begin
    WIDTH:= LAND_WIDTH shr gr;
    HEIGHT:= LAND_HEIGHT shr gr;

    SetLength(marks, HEIGHT, WIDTH);
end;

procedure initModule;
begin
end;

procedure freeModule;
begin
    SetLength(marks, 0, 0);
end;

end.
