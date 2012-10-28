unit uCursor;

interface

procedure init;
procedure updatePosition;

implementation

uses SDLh, uVariables;

procedure init;
begin
    SDL_WarpMouse(cScreenWidth div 2, cScreenHeight div 2);
end;

procedure updatePosition;
var x, y: LongInt;
begin
    SDL_GetMouseState(@x, @y);

    if(x <> cScreenWidth div 2) or (y <> cScreenHeight div 2) then
        begin
        CursorPoint.X:= CursorPoint.X + x - cScreenWidth div 2;
        CursorPoint.Y:= CursorPoint.Y - y + cScreenHeight div 2;

        if cHasFocus then
            SDL_WarpMouse(cScreenWidth div 2, cScreenHeight div 2);
        end
end;

end.
