(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2011 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 *)

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
