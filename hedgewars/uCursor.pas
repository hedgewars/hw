unit uCursor;

interface

procedure init;
procedure resetPosition;
procedure handlePositionUpdate(x, y: LongInt);

function updateMousePosition(cx, cy, x, y: LongInt): boolean; cdecl; export;

implementation

uses SDLh, uVariables, uTypes;

procedure init;
begin
    //resetPosition();
end;

procedure resetPosition;
begin
    // Move curser by 1px in case it's already centered.
    // The game camera in the Alpha for 0.9.23 screwed up if
    // the game started with the mouse already being centered.
    // This fixes it, but we might have overlooked a related
    // bug somewhere else.
    // No big deal since this function is (so far) only called once.
    //SDL_WarpMouse((cScreenWidth div 2) + 1, cScreenHeight div 2);
    //SDL_WarpMouse(cScreenWidth div 2, cScreenHeight div 2);
end;

function updateMousePosition(cx, cy, x, y: LongInt): boolean; cdecl; export;
begin
    if (GameState <> gsConfirm)
            and (GameState <> gsSuspend)
            and (GameState <> gsExit)
            and (GameState <> gsLandgen)
            and (GameState <> gsStart)
            and cHasFocus
            and (not (CurrentTeam^.ExtDriven and isCursorVisible and (not bShowAmmoMenu) and autoCameraOn)) 
            and ((x <> cx) or (y <> cy)) then
    begin
        handlePositionUpdate(x - cx, y - cy);

        updateMousePosition:= true
    end else
        updateMousePosition:= false
end;

procedure handlePositionUpdate(x, y: LongInt);
begin
    CursorPoint.X:= CursorPoint.X + x;
    CursorPoint.Y:= CursorPoint.Y - y;
end;

end.
