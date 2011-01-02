(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2008 Andrey Korotaev <unC0Rr@gmail.com>
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
function  Format(fmt: ansistring; var arg: ansistring): ansistring;
function  GetEventString(e: TEventId): ansistring;

implementation
uses uRandom, uUtils, uVariables, uDebug;

var trevt: array[TEventId] of array [0..Pred(MAX_EVENT_STRINGS)] of ansistring;
    trevt_n: array[TEventId] of integer;

procedure LoadLocale(FileName: shortstring);
var s: ansistring;
    f: textfile;
    a, b, c: LongInt;
    first: array[TEventId] of boolean;
    e: TEventId;
    loaded: boolean;
begin
loaded:= false;
for e:= Low(TEventId) to High(TEventId) do first[e]:= true;

{$I-} // iochecks off
Assign(f, FileName);
filemode:= 0; // readonly
Reset(f);
if IOResult = 0 then loaded:= true;
TryDo(loaded, 'Cannot load locale "' + FileName + '"', false);
if loaded then
   begin
   while not eof(f) do
       begin
       readln(f, s);
       if Length(s) = 0 then continue;
       if not (s[1] in ['0'..'9']) then continue;
       TryDo(Length(s) > 6, 'Load locale: empty string', true);
       val(s[1]+s[2], a, c);
       TryDo(c = 0, 'Load locale: numbers should be two-digit: ' + s, true);
       TryDo(s[3] = ':', 'Load locale: ":" expected', true);
       val(s[4]+s[5], b, c);
       TryDo(c = 0, 'Load locale: numbers should be two-digit' + s, true);
       TryDo(s[6] = '=', 'Load locale: "=" expected', true);
       Delete(s, 1, 6);
       case a of
           0: if (b >=0) and (b <= ord(High(TAmmoStrId))) then trammo[TAmmoStrId(b)]:= s;
           1: if (b >=0) and (b <= ord(High(TMsgStrId))) then trmsg[TMsgStrId(b)]:= s;
           2: if (b >=0) and (b <= ord(High(TEventId))) then begin
               TryDo(trevt_n[TEventId(b)] < MAX_EVENT_STRINGS, 'Too many event strings in ' + IntToStr(a) + ':' + IntToStr(b), false);
               if first[TEventId(b)] then
                   begin
                   trevt_n[TEventId(b)]:= 0;
                   first[TEventId(b)]:= false;
                   end;
               trevt[TEventId(b)][trevt_n[TEventId(b)]]:= s;
               inc(trevt_n[TEventId(b)]);
               end;
           3: if (b >=0) and (b <= ord(High(TAmmoStrId))) then trammoc[TAmmoStrId(b)]:= s;
           4: if (b >=0) and (b <= ord(High(TAmmoStrId))) then trammod[TAmmoStrId(b)]:= s;
           5: if (b >=0) and (b <= ord(High(TGoalStrId))) then trgoal[TGoalStrId(b)]:= s;
           end;
       end;
   Close(f)
   end;
{$I+}
end;

function GetEventString(e: TEventId): ansistring;
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
if i = 0 then Format:= fmt
         else Format:= copy(fmt, 1, i - 1) + arg + Format(copy(fmt, i + 2, Length(fmt) - i - 1), arg)
end;

function Format(fmt: ansistring; var arg: ansistring): ansistring;
var i: LongInt;
begin
i:= Pos('%1', fmt);
if i = 0 then Format:= fmt
         else Format:= copy(fmt, 1, i - 1) + arg + Format(copy(fmt, i + 2, Length(fmt) - i - 1), arg)
end;

procedure LoadLocaleWrapper(str: pchar); cdecl; export;
begin
    LoadLocale(Strpas(str));
end;

end.
