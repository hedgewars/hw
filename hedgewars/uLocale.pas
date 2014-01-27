(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2014 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uLocale;
interface
uses uTypes;

const MAX_EVENT_STRINGS = 100;

procedure LoadLocale(FileName: shortstring);
function  Format(fmt: shortstring; var arg: shortstring): shortstring;
function  FormatA(fmt: PChar; arg: ansistring): ansistring;
function  GetEventString(e: TEventId): PChar;
procedure initModule;
procedure freeModule;

{$IFDEF HWLIBRARY}
procedure LoadLocaleWrapper(str: pchar); cdecl; export;
{$ENDIF}

implementation
uses uRandom, uVariables, uDebug, uPhysFSLayer, sysutils;

var trevt: array[TEventId] of array [0..Pred(MAX_EVENT_STRINGS)] of PChar;
    trevt_n: array[TEventId] of integer;

procedure LoadLocale(FileName: shortstring);
var s: PChar = nil;
    sc: PChar;
    f: pfsFile;
    a, b, c: LongInt;
    first: array[TEventId] of boolean;
    e: TEventId;
begin
for e:= Low(TEventId) to High(TEventId) do
    first[e]:= true;

f:= pfsOpenRead(FileName);
TryDo(f <> nil, 'Cannot load locale "' + FileName + '"', false);

if f <> nil then
    begin
    while not pfsEof(f) do
        begin
        pfsReadLnA(f, s);
        if (StrLength(s) > 0) and (s[0] >= '0') and (s[0] <= '9') then
            begin
            TryDo(StrLength(s) > 6, 'Load locale: empty string', true);
            val(s[0]+s[1], a, c);
            TryDo(c = 0, 'Load locale: numbers should be two-digit: ' + s, true);
            TryDo(s[2] = ':', 'Load locale: ":" expected', true);
            val(s[3]+s[4], b, c);
            TryDo(c = 0, 'Load locale: numbers should be two-digit' + s, true);
            TryDo(s[5] = '=', 'Load locale: "=" expected', true);
            sc:= StrAlloc(StrLength(s) - 5);
            StrCopy(sc, @s[6]);
            case a of
                0: if (b >=0) and (b <= ord(High(TAmmoStrId))) then
                    trammo[TAmmoStrId(b)]:= sc;
                1: if (b >=0) and (b <= ord(High(TMsgStrId))) then
                    trmsg[TMsgStrId(b)]:= sc;
                2: if (b >=0) and (b <= ord(High(TEventId))) then
                    begin
                    TryDo(trevt_n[TEventId(b)] < MAX_EVENT_STRINGS, 'Too many event strings in ' + IntToStr(a) + ':' + IntToStr(b), false);
                    if first[TEventId(b)] then
                        begin
                        trevt_n[TEventId(b)]:= 0;
                        first[TEventId(b)]:= false;
                        end;
                    trevt[TEventId(b)][trevt_n[TEventId(b)]]:= sc;
                    inc(trevt_n[TEventId(b)]);
                    end;
                3: if (b >=0) and (b <= ord(High(TAmmoStrId))) then
                    trammoc[TAmmoStrId(b)]:= sc;
                4: if (b >=0) and (b <= ord(High(TAmmoStrId))) then
                    trammod[TAmmoStrId(b)]:= sc;
                5: if (b >=0) and (b <= ord(High(TGoalStrId))) then
                    trgoal[TGoalStrId(b)]:= sc;
            end;
            end;
        StrDispose(s);
        end;
   pfsClose(f);
   end;
end;

function GetEventString(e: TEventId): PChar;
begin
    if trevt_n[e] = 0 then // no messages for this event type?
        GetEventString:= '*missing translation*'
    else
        GetEventString:= trevt[e][GetRandom(trevt_n[e])]; // Pick a random message and return it
end;

function Format(fmt: shortstring; var arg: shortstring): shortstring;
var i: LongInt;
begin
i:= Pos('%1', fmt);
if i = 0 then
    Format:= fmt
else
    Format:= copy(fmt, 1, i - 1) + arg + Format(copy(fmt, i + 2, Length(fmt) - i - 1), arg)
end;

function FormatA(fmt: PChar; arg: ansistring): ansistring;
var i: LongInt;
    s: ansistring;
begin
s:= fmt;

i:= Pos('%1', s);
if i = 0 then
    FormatA:= s
else
    FormatA:= copy(s, 1, i - 1) + arg + FormatA(PChar(copy(s, i + 2, Length(s) - i - 1)), arg)
end;

{$IFDEF HWLIBRARY}
procedure LoadLocaleWrapper(str: pchar); cdecl; export;
begin
    LoadLocale(Strpas(str));
end;
{$ENDIF}

procedure initModule;
var e: TEventId;
    i: LongInt;
begin
    for e:= Low(TEventId) to High(TEventId) do
        for i:= 0 to Pred(MAX_EVENT_STRINGS) do
            trevt[e][i]:= nil;
end;

procedure freeModule;
var e: TEventId;
    i: LongInt;
begin
    for e:= Low(TEventId) to High(TEventId) do
        for i:= 0 to Pred(trevt_n[e]) do
            StrDispose(trevt[e][i]);
end;

end.
