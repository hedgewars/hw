unit uCursor;

interface

procedure init;
procedure resetPosition;
procedure updatePosition;
procedure handlePositionUpdate(x, y: LongInt);

implementation

uses SDLh, uVariables;

procedure init;
begin
    resetPosition();
end;

procedure resetPosition;
begin
    // Move curser by 1px in case it's already centered.
    // Due to switch to SDL2, the game camera in the Alpha for 0.9.23
    // screwed up if the game started with the mouse already being
    // centered.
    // No big deal since this function is (so far) only called once.
    // This fixes it, but we might have overlooked an SDL2-related
    // bug somewhere else.
    SDL_WarpMouse((cScreenWidth div 2) + 1, cScreenHeight div 2);
    SDL_WarpMouse(cScreenWidth div 2, cScreenHeight div 2);
end;

procedure updatePosition;
var x, y: LongInt;
begin
    SDL_GetMouseState(@x, @y);

    if(x <> cScreenWidth div 2) or (y <> cScreenHeight div 2) then
    begin
        handlePositionUpdate(x - cScreenWidth div 2, y - cScreenHeight div 2);

        if cHasFocus then
            SDL_WarpMouse(cScreenWidth div 2, cScreenHeight div 2);
    end
end;

procedure handlePositionUpdate(x, y: LongInt);
begin
    CursorPoint.X:= CursorPoint.X + x;
    CursorPoint.Y:= CursorPoint.Y - y;
end;

end.
