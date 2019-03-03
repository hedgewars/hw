unit uCursor;

interface

procedure init;
procedure resetPosition;
procedure updatePosition;
procedure handlePositionUpdate(x, y: LongInt);

implementation

uses SDLh, uVariables, uTypes;

procedure init;
begin
    resetPosition();
end;

procedure resetPosition;
begin
    if GameType = gmtRecord then
        exit;
    // Move curser by 1px in case it's already centered.
    // The game camera in the Alpha for 0.9.23 screwed up if
    // the game started with the mouse already being centered.
    // This fixes it, but we might have overlooked a related
    // bug somewhere else.
    // No big deal since this function is (so far) only called once.
    SDL_WarpMouse((cScreenWidth div 2) + 1, cScreenHeight div 2);
    SDL_WarpMouse(cScreenWidth div 2, cScreenHeight div 2);
end;

procedure updatePosition;
var x, y: LongInt;
begin
	x:= cScreenWidth div 2;
	y:= cScreenHeight div 2;
    if GameType <> gmtRecord then
        SDL_GetMouseState(@x, @y);

    if(x <> cScreenWidth div 2) or (y <> cScreenHeight div 2) then
    begin
        handlePositionUpdate(x - cScreenWidth div 2, y - cScreenHeight div 2);

        if cHasFocus and (GameType <> gmtRecord) then
            SDL_WarpMouse(cScreenWidth div 2, cScreenHeight div 2);
    end
end;

procedure handlePositionUpdate(x, y: LongInt);
begin
    CursorPoint.X:= CursorPoint.X + x;
    CursorPoint.Y:= CursorPoint.Y - y;
end;

end.
