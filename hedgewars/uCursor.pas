unit uCursor;

interface

procedure init;
procedure resetPosition;
procedure updatePosition;

implementation

uses SDLh, uVariables;

{$IFDEF WEBGL}
var offsetx, offsety : Integer;
{$ENDIF}

procedure init;
begin
    resetPosition();
end;

procedure resetPosition;
begin
    SDL_WarpMouse(cScreenWidth div 2, cScreenHeight div 2);
end;

procedure updatePosition;
var x, y: LongInt;
{$IFDEF WEBGL}
    tx, ty : LongInt;
{$ENDIF}
begin
    SDL_GetMouseState(@x, @y);

{$IFDEF WEBGL}
    tx := x;
    ty := y;
    x := x + offsetx;
    y := y + offsety;
{$ENDIF}

    if(x <> cScreenWidth div 2) or (y <> cScreenHeight div 2) then
        begin
        CursorPoint.X:= CursorPoint.X + x - cScreenWidth div 2;
        CursorPoint.Y:= CursorPoint.Y - y + cScreenHeight div 2;

        if cHasFocus then
            begin
            {$IFNDEF WEBGL}
            SDL_WarpMouse(cScreenWidth div 2, cScreenHeight div 2);
            {$ELSE}
            offsetx := cScreenWidth div 2 - tx;
            offsety := cScreenHeight div 2 - ty;
            {$ENDIF}
            end;
        end
end;

end.
