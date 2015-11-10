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

unit uConsole;
interface


procedure WriteToConsole(s: shortstring);
procedure WriteLnToConsole(s: shortstring);

var lastConsoleline : shortstring;

implementation
uses Types, uUtils {$IFDEF ANDROID}, log in 'log.pas'{$ENDIF};


procedure WriteToConsole(s: shortstring);
begin
{$IFNDEF NOCONSOLE}
    AddFileLog('[Con] ' + s);
{$IFDEF ANDROID}
    //TODO integrate this function in the uMobile record
    Log.__android_log_write(Log.Android_LOG_DEBUG, 'HW_Engine', ShortStringAsPChar('[Con]' + s));
{$ELSE}
    Write(stderr, s);
{$ENDIF}
{$ENDIF}
end;

procedure WriteLnToConsole(s: shortstring);
begin
{$IFNDEF NOCONSOLE}
    WriteToConsole(s);
{$IFNDEF ANDROID}
    WriteLn(stderr, '');
{$ENDIF}
{$ENDIF}
    lastConsoleline:= s;
end;
{$IFDEF ANDROID}
function ShortStringAsPChar(s: shortstring) : PChar;
begin
    if Length(s) = High(s) then
        Dec(s[0]);
    s[Ord(Length(s))+1] := #0;
    // returning pointer to stack, rly?
    ShortStringAsPChar:= @s[1];
end;
{$ENDIF}

end.
