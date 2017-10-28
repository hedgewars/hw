unit uCursor;

interface

procedure init;
procedure resetPosition;
procedure updatePosition;
procedure handlePositionUpdate(x, y: LongInt);
procedure setSystemCursor(enabled: boolean);

implementation

uses SDLh, uVariables;

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
begin
    SDL_GetRelativeMouseState(@x, @y);

    if(x <> 0) or (y <> 0) then
        handlePositionUpdate(x, y);
end;

procedure handlePositionUpdate(x, y: LongInt);
begin
    CursorPoint.X:= CursorPoint.X + x;
    CursorPoint.Y:= CursorPoint.Y - y;
end;

procedure setSystemCursor(enabled: boolean);
begin
    if enabled then
        begin
        SDL_SetRelativeMouseMode(false);
        if cHasFocus then
            resetPosition();
        SDL_ShowCursor(1);
        end
    else
        begin
        SDL_ShowCursor(0);
        SDL_GetRelativeMouseState(nil, nil);
        SDL_SetRelativeMouseMode(true);
        end;
end;

end.
