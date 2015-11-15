(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *)

{$INCLUDE "options.inc"}

unit uDebug;

interface

procedure OutError(Msg: shortstring; isFatalError: boolean);
procedure TryDo(Assert: boolean; Msg: shortstring; isFatal: boolean); inline;
procedure SDLTry(Assert: boolean; Msg: shortstring; isFatal: boolean);

implementation
uses SDLh, uConsole, uCommands, uConsts;

procedure OutError(Msg: shortstring; isFatalError: boolean);
begin
WriteLnToConsole(Msg);
if isFatalError then
    begin
    ParseCommand('fatal ' + lastConsoleline, true);
    // hint for the 'coverity' source analyzer
    // this halt is never actually reached because ParseCommands will halt first
    halt(HaltFatalError);
    end;
end;

procedure TryDo(Assert: boolean; Msg: shortstring; isFatal: boolean);
begin
if not Assert then
    OutError(Msg, isFatal)
end;

procedure SDLTry(Assert: boolean; Msg: shortstring; isFatal: boolean);
var s: shortstring;
begin
if not Assert then
    begin
    s:= SDL_GetError();
    OutError(Msg + ': ' + s, isFatal)
    end
end;

end.
