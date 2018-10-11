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

procedure LoadLocale(FileName: shortstring);
function  GetEventString(e: TEventId): ansistring;

function Format(fmt: shortstring; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9: shortstring; argCount: Byte): shortstring;
function Format(fmt: shortstring; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9: shortstring): shortstring;
function Format(fmt: shortstring; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8: shortstring): shortstring;
function Format(fmt: shortstring; arg1, arg2, arg3, arg4, arg5, arg6, arg7: shortstring): shortstring;
function Format(fmt: shortstring; arg1, arg2, arg3, arg4, arg5, arg6: shortstring): shortstring;
function Format(fmt: shortstring; arg1, arg2, arg3, arg4, arg5: shortstring): shortstring;
function Format(fmt: shortstring; arg1, arg2, arg3, arg4: shortstring): shortstring;
function Format(fmt: shortstring; arg1, arg2, arg3: shortstring): shortstring;
function Format(fmt: shortstring; arg1, arg2: shortstring): shortstring;
function Format(fmt: shortstring; arg1: shortstring): shortstring;
function FormatA(fmt: ansistring; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9: ansistring; argCount: Byte): ansistring;
function FormatA(fmt: ansistring; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9: ansistring): ansistring;
function FormatA(fmt: ansistring; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8: ansistring): ansistring;
function FormatA(fmt: ansistring; arg1, arg2, arg3, arg4, arg5, arg6, arg7: ansistring): ansistring;
function FormatA(fmt: ansistring; arg1, arg2, arg3, arg4, arg5, arg6: ansistring): ansistring;
function FormatA(fmt: ansistring; arg1, arg2, arg3, arg4, arg5: ansistring): ansistring;
function FormatA(fmt: ansistring; arg1, arg2, arg3, arg4: ansistring): ansistring;
function FormatA(fmt: ansistring; arg1, arg2, arg3: ansistring): ansistring;
function FormatA(fmt: ansistring; arg1, arg2: ansistring): ansistring;
function FormatA(fmt: ansistring; arg1: ansistring): ansistring;

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
            6: if (b >=0) and (b <= ord(High(TCmdHelpStrId))) then
                trcmd[TCmdHelpStrId(b)]:= s;
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
// Take a shortstring with placeholders %1, %2, %3, ... %9. and replace
// them with the corresponding elements of an array with up to
// argCount. ArgCount must not be larger than 9.
// Each placeholder must be used exactly once and numbers MUST NOT be
// skipped (e.g. using %1 and %3 but not %2.
function Format(fmt: shortstring; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9: shortstring; argCount: Byte): shortstring;
var i, p: LongInt;
tempstr, curArg: shortstring;
begin
tempstr:= fmt;
for i:=0 to argCount - 1 do
    begin
        case i of
            0: curArg:= arg1;
            1: curArg:= arg2;
            2: curArg:= arg3;
            3: curArg:= arg4;
            4: curArg:= arg5;
            5: curArg:= arg6;
            6: curArg:= arg7;
            7: curArg:= arg8;
            8: curArg:= arg9;
        end;

        p:= Pos('%'+IntToStr(i+1), tempstr);
        if (p = 0) then
            break
        else
            begin
            delete(tempstr, p, 2);
            insert(curArg, tempstr, p);
            end;
    end;
Format:= tempstr;
end;

// Same as Format, but for ansistring
function FormatA(fmt: ansistring; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9: ansistring; argCount: Byte): ansistring;
var i, p: LongInt;
tempstr, curArg: ansistring;
begin
tempstr:= fmt;
for i:=0 to argCount - 1 do
    begin
        case i of
            0: curArg:= arg1;
            1: curArg:= arg2;
            2: curArg:= arg3;
            3: curArg:= arg4;
            4: curArg:= arg5;
            5: curArg:= arg6;
            6: curArg:= arg7;
            7: curArg:= arg8;
            8: curArg:= arg9;
        end;

        p:= Pos('%'+IntToStr(i+1), tempstr);
        if (p = 0) then
            break
        else
            begin
            delete(tempstr, p, 2);
            insert(curArg, tempstr, p);
            end;
    end;
FormatA:= tempstr;
end;

// The following functions are just shortcuts of Format/FormatA, with fewer argument counts
function Format(fmt: shortstring; arg1: shortstring): shortstring;
begin
    Format:= Format(fmt, arg1, '', '', '', '', '', '', '', '', 1);
end;
function Format(fmt: shortstring; arg1, arg2: shortstring): shortstring;
begin
    Format:= Format(fmt, arg1, arg2, '', '', '', '', '', '', '', 2);
end;
function Format(fmt: shortstring; arg1, arg2, arg3: shortstring): shortstring;
begin
    Format:= Format(fmt, arg1, arg2, arg3, '', '', '', '', '', '', 3);
end;
function Format(fmt: shortstring; arg1, arg2, arg3, arg4: shortstring): shortstring;
begin
    Format:= Format(fmt, arg1, arg2, arg3, arg4, '', '', '', '', '', 4);
end;
function Format(fmt: shortstring; arg1, arg2, arg3, arg4, arg5: shortstring): shortstring;
begin
    Format:= Format(fmt, arg1, arg2, arg3, arg4, arg5, '', '', '', '', 5);
end;
function Format(fmt: shortstring; arg1, arg2, arg3, arg4, arg5, arg6: shortstring): shortstring;
begin
    Format:= Format(fmt, arg1, arg2, arg3, arg4, arg5, arg6, '', '', '', 6);
end;
function Format(fmt: shortstring; arg1, arg2, arg3, arg4, arg5, arg6, arg7: shortstring): shortstring;
begin
    Format:= Format(fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7, '', '', 7);
end;
function Format(fmt: shortstring; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8: shortstring): shortstring;
begin
    Format:= Format(fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, '', 8);
end;
function Format(fmt: shortstring; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9: shortstring): shortstring;
begin
    Format:= Format(fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, 9);
end;

function FormatA(fmt: ansistring; arg1: ansistring): ansistring;
begin
    FormatA:= FormatA(fmt, arg1, ansistring(''), ansistring(''), ansistring(''), ansistring(''), ansistring(''), ansistring(''), ansistring(''), ansistring(''), 1);
end;
function FormatA(fmt: ansistring; arg1, arg2: ansistring): ansistring;
begin
    FormatA:= FormatA(fmt, arg1, arg2, ansistring(''), ansistring(''), ansistring(''), ansistring(''), ansistring(''), ansistring(''), ansistring(''), 2);
end;
function FormatA(fmt: ansistring; arg1, arg2, arg3: ansistring): ansistring;
begin
    FormatA:= FormatA(fmt, arg1, arg2, arg3, ansistring(''), ansistring(''), ansistring(''), ansistring(''), ansistring(''), ansistring(''), 3);
end;
function FormatA(fmt: ansistring; arg1, arg2, arg3, arg4: ansistring): ansistring;
begin
    FormatA:= FormatA(fmt, arg1, arg2, arg3, arg4, ansistring(''), ansistring(''), ansistring(''), ansistring(''), ansistring(''), 4);
end;
function FormatA(fmt: ansistring; arg1, arg2, arg3, arg4, arg5: ansistring): ansistring;
begin
    FormatA:= FormatA(fmt, arg1, arg2, arg3, arg4, arg5, ansistring(''), ansistring(''), ansistring(''), ansistring(''), 5);
end;
function FormatA(fmt: ansistring; arg1, arg2, arg3, arg4, arg5, arg6: ansistring): ansistring;
begin
    FormatA:= FormatA(fmt, arg1, arg2, arg3, arg4, arg5, arg6, ansistring(''), ansistring(''), ansistring(''), 6);
end;
function FormatA(fmt: ansistring; arg1, arg2, arg3, arg4, arg5, arg6, arg7: ansistring): ansistring;
begin
    FormatA:= FormatA(fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7, ansistring(''), ansistring(''), 7);
end;
function FormatA(fmt: ansistring; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8: ansistring): ansistring;
begin
    FormatA:= FormatA(fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, ansistring(''), 8);
end;
function FormatA(fmt: ansistring; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9: ansistring): ansistring;
begin
    FormatA:= FormatA(fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, 9);
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
