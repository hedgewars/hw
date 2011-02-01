{$INCLUDE "options.inc"}

unit uDebug;

interface

procedure OutError(Msg: shortstring; isFatalError: boolean);
procedure TryDo(Assert: boolean; Msg: shortstring; isFatal: boolean); inline;
procedure SDLTry(Assert: boolean; isFatal: boolean);

implementation
uses SDLh, uConsole, uCommands;

procedure OutError(Msg: shortstring; isFatalError: boolean);
begin
WriteLnToConsole(Msg);
if isFatalError then
    begin
    ParseCommand('fatal ' + GetLastConsoleLine, true);
    SDL_Quit;
    halt(1)
    end
end;

procedure TryDo(Assert: boolean; Msg: shortstring; isFatal: boolean);
begin
if not Assert then OutError(Msg, isFatal)
end;

procedure SDLTry(Assert: boolean; isFatal: boolean);
begin
if not Assert then OutError(SDL_GetError, isFatal)
end;

end.
