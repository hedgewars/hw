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

unit uLocale;
interface
uses uTypes;

const MAX_EVENT_STRINGS = 255;
const MAX_FORMAT_STRING_SYMBOLS = 9;

procedure LoadLocale(FileName: shortstring);
function  Format(fmt: shortstring; args: array of shortstring): shortstring;
function  FormatA(fmt: ansistring; args: array of ansistring): ansistring;
function  Format(fmt: shortstring; arg: shortstring): shortstring;
function  FormatA(fmt: ansistring; arg: ansistring): ansistring;
function  GetEventString(e: TEventId): ansistring;

{$IFDEF HWLIBRARY}
procedure LoadLocaleWrapper(path: pchar; userpath: pchar; filename: pchar); cdecl; export;
{$ENDIF}

implementation
uses uRandom, uUtils, uVariables, uDebug, uPhysFSLayer;

var trevt: array[TEventId] of array [0..Pred(MAX_EVENT_STRINGS)] of ansistring;
    trevt_n: array[TEventId] of integer;

procedure LoadLocale(FileName: shortstring);
var s: ansistring;
    f: pfsFile;
    a, b, c: LongInt;
    first: array[TEventId] of boolean;
    e: TEventId;
begin
for e:= Low(TEventId) to High(TEventId) do
    first[e]:= true;

f:= pfsOpenRead(FileName);
checkFails(f <> nil, 'Cannot load locale "' + FileName + '"', false);

s:= '';

if f <> nil then
    begin
    while not pfsEof(f) do
        begin
        pfsReadLnA(f, s);
        if Length(s) = 0 then
            continue;
        if (s[1] < '0') or (s[1] > '9') then
            continue;
        checkFails(Length(s) > 6, 'Load locale: empty string', true);
        {$IFNDEF PAS2C}
        val(s[1]+s[2], a, c);
        checkFails(c = 0, ansistring('Load locale: numbers should be two-digit: ') + s, true);
        val(s[4]+s[5], b, c);
        checkFails(c = 0, ansistring('Load locale: numbers should be two-digit: ') + s, true);
        {$ELSE}
        val(s[1]+s[2], a);
        val(s[4]+s[5], b);
        {$ENDIF}
        checkFails(s[3] = ':', 'Load locale: ":" expected', true);
        checkFails(s[6] = '=', 'Load locale: "=" expected', true);
        if not allOK then exit;
        Delete(s, 1, 6);
        case a of
            0: if (b >=0) and (b <= ord(High(TAmmoStrId))) then
                trammo[TAmmoStrId(b)]:= s;
            1: if (b >=0) and (b <= ord(High(TMsgStrId))) then
                trmsg[TMsgStrId(b)]:= s;
            2: if (b >=0) and (b <= ord(High(TEventId))) then
                begin
                checkFails(trevt_n[TEventId(b)] < MAX_EVENT_STRINGS, 'Too many event strings in ' + IntToStr(a) + ':' + IntToStr(b), false);
                if first[TEventId(b)] then
                    begin
                    trevt_n[TEventId(b)]:= 0;
                    first[TEventId(b)]:= false;
                    end;
                trevt[TEventId(b)][trevt_n[TEventId(b)]]:= s;
                inc(trevt_n[TEventId(b)]);
                end;
            3: if (b >=0) and (b <= ord(High(TAmmoStrId))) then
                trammoc[TAmmoStrId(b)]:= s;
            4: if (b >=0) and (b <= ord(High(TAmmoStrId))) then
                trammod[TAmmoStrId(b)]:= s;
            5: if (b >=0) and (b <= ord(High(TGoalStrId))) then
                trgoal[TGoalStrId(b)]:= s;
           end;
       end;
   pfsClose(f);
   end;
end;

function GetEventString(e: TEventId): ansistring;
begin
    if trevt_n[e] = 0 then // no messages for this event type?
        GetEventString:= '*missing translation*'
    else
        GetEventString:= trevt[e][GetRandom(trevt_n[e])]; // Pick a random message and return it
end;

// Format the string fmt.
// Take a shortstring with placeholders %1, %2, %3, etc. and replace
// them with the corresponding elements of an array with up to
// MAX_FORMAT_STRING_SYMBOLS. Important! Each placeholder can only be
// used exactly once and numbers MUST NOT be skipped (e.g. using %1 and %3
// but not %2.
function Format(fmt: shortstring; args: array of shortstring): shortstring;
var i, p: LongInt;
tempstr: shortstring;
begin
tempstr:= fmt;
for i:=0 to MAX_FORMAT_STRING_SYMBOLS - 1 do
    begin
        p:= Pos('%'+IntToStr(i+1), tempstr);
        if (p = 0) or (i >= Length(args)) then
            break
        else
            begin
            delete(tempstr, p, 2);
            insert(args[i], tempstr, p);
            end;
    end;
Format:= tempstr;
end;

// Same as Format, but for ansistring
function FormatA(fmt: ansistring; args: array of ansistring): ansistring;
var i, p: LongInt;
tempstr: ansistring;
begin
tempstr:= fmt;
for i:=0 to MAX_FORMAT_STRING_SYMBOLS - 1 do
    begin
        p:= Pos('%'+IntToStr(i+1), tempstr);
        if (p = 0) or (i >= Length(args)) then
            break
        else
            begin
            delete(tempstr, p, 2);
            insert(args[i], tempstr, p);
            end;
    end;
FormatA:= tempstr;
end;

// Same as Format above, but with only one placeholder %1, replaced by arg.
function Format(fmt: shortstring; arg: shortstring): shortstring;
begin
    Format:= Format(fmt, [arg]);
end;

// Same as above, but for ansistring
function FormatA(fmt: ansistring; arg: ansistring): ansistring;
begin
    FormatA:= FormatA(fmt, [arg]);
end;

{$IFDEF HWLIBRARY}
procedure LoadLocaleWrapper(path: pchar; userpath: pchar; filename: pchar); cdecl; export;
begin
    PathPrefix := Strpas(path);
    UserPathPrefix := Strpas(userpath);
 
    //normally this var set in preInit of engine
    allOK := true;
    
    uVariables.initModule;
 
    PathPrefix:= PathPrefix + #0;
    UserPathPrefix:= UserPathPrefix + #0;
    uPhysFSLayer.initModule(@PathPrefix[1], @UserPathPrefix[1]);
    PathPrefix:= copy(PathPrefix, 1, length(PathPrefix) - 1);
    UserPathPrefix:= copy(UserPathPrefix, 1, length(UserPathPrefix) - 1);
 
    LoadLocale(Strpas(filename));
 
    uPhysFSLayer.freeModule;
    uVariables.freeModule;
end;
{$ENDIF}

end.
