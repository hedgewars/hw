(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uConsole;
interface

procedure initModule;
procedure freeModule;
procedure WriteToConsole(s: shortstring);
procedure WriteLnToConsole(s: shortstring);
function  GetLastConsoleLine: shortstring;
function  ShortStringAsPChar(s: shortstring): PChar;

implementation
uses Types, uVariables, uUtils {$IFDEF ANDROID}, log in 'log.pas'{$ENDIF};

const cLinesCount = 8;
var   cLineWidth: LongInt;

type
    TTextLine = record
        s: shortstring
        end;

var   ConsoleLines: array[byte] of TTextLine;
      CurrLine: LongInt;

procedure SetLine(var tl: TTextLine; str: shortstring);
begin
with tl do
    s:= str;
end;

procedure WriteToConsole(s: shortstring);
{$IFNDEF NOCONSOLE}
var Len: LongInt;
    done: boolean;
{$ENDIF}
begin
{$IFNDEF NOCONSOLE}
AddFileLog('[Con] ' + s);
{$IFDEF ANDROID}
    Log.__android_log_write(Log.Android_LOG_DEBUG, 'HW_Engine', ShortStringAsPChar('[Con]' + s));
{$ELSE}
Write(stderr, s);
done:= false;

while not done do
    begin
    Len:= cLineWidth - Length(ConsoleLines[CurrLine].s);
    SetLine(ConsoleLines[CurrLine], ConsoleLines[CurrLine].s + copy(s, 1, Len));
    Delete(s, 1, Len);
    if byte(ConsoleLines[CurrLine].s[0]) = cLineWidth then
        begin
        inc(CurrLine);
        if CurrLine = cLinesCount then
            CurrLine:= 0;
        PByte(@ConsoleLines[CurrLine].s)^:= 0
        end;
    done:= (Length(s) = 0);
    end;
{$ENDIF}
{$ENDIF}
end;

procedure WriteLnToConsole(s: shortstring);
begin
{$IFNDEF NOCONSOLE}
WriteToConsole(s);
{$IFNDEF ANDROID}
WriteLn(stderr);
inc(CurrLine);
if CurrLine = cLinesCount then
    CurrLine:= 0;
PByte(@ConsoleLines[CurrLine].s)^:= 0
{$ENDIF}
{$ENDIF}
end;

function ShortStringAsPChar(s: shortstring) : PChar;
begin
    if Length(s) = High(s) then
        Dec(s[0]);
    s[Ord(Length(s))+1] := #0;
    ShortStringAsPChar:= @s[1];
end;

function GetLastConsoleLine: shortstring;
var valueStr: shortstring;
    i: LongWord;
begin
i:= (CurrLine + cLinesCount - 2) mod cLinesCount;
valueStr:= ConsoleLines[i].s;

valueStr:= valueStr + #10;

i:= (CurrLine + cLinesCount - 1) mod cLinesCount;
valueStr:= valueStr + ConsoleLines[i].s;

GetLastConsoleLine:= valueStr;
end;

procedure initModule;
var i: LongInt;
begin
    CurrLine:= 0;

    // initConsole
    cLineWidth:= cScreenWidth div 10;
    if cLineWidth > 255 then
        cLineWidth:= 255;
    for i:= 0 to Pred(cLinesCount) do
        PByte(@ConsoleLines[i])^:= 0;
end;

procedure freeModule;
begin

end;

end.
