unit uCursor;

interface

procedure init;
procedure resetPosition;
procedure resetPositionDelta();
procedure updatePositionDelta(xrel, yrel: LongInt);
procedure updatePosition();
procedure handlePositionUpdate(x, y: LongInt);

implementation

uses SDLh, uVariables, uTypes;

procedure init;
begin
    SDL_ShowCursor(SDL_DISABLE);
    resetPosition();
    SDL_SetRelativeMouseMode(SDL_TRUE);
end;

procedure resetPosition;
begin
    if GameType = gmtRecord then
        exit;
    SDL_WarpMouse(cScreenWidth div 2, cScreenHeight div 2);
    resetPositionDelta();
end;

procedure resetPositionDelta();
begin
    CursorPointDelta.X:= 0;
    CursorPointDelta.Y:= 0;
end;

procedure updatePositionDelta(xrel, yrel: LongInt);
begin
    CursorPointDelta.X:= CursorPointDelta.X + xrel;
    CursorPointDelta.Y:= CursorPointDelta.Y + yrel;
end;

procedure updatePosition();
begin
    handlePositionUpdate(CursorPointDelta.X, CursorPointDelta.Y);
    resetPositionDelta();
end;

procedure handlePositionUpdate(x, y: LongInt);
begin
    CursorPoint.X:= CursorPoint.X + x;
    CursorPoint.Y:= CursorPoint.Y - y;
end;

end.
