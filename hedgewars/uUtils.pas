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

unit uUtils;

interface
uses uTypes, uFloat, GLunit;

procedure SplitBySpace(var a, b: shortstring);
procedure SplitByChar(var a, b: shortstring; c: char);
procedure SplitByChar(var a, b: ansistring; c: char);

{$IFNDEF PAS2C}
function  EnumToStr(const en : TGearType) : shortstring; overload;
function  EnumToStr(const en : TVisualGearType) : shortstring; overload;
function  EnumToStr(const en : TSound) : shortstring; overload;
function  EnumToStr(const en : TAmmoType) : shortstring; overload;
function  EnumToStr(const en : THogEffect) : shortstring; overload;
function  EnumToStr(const en : TCapGroup) : shortstring; overload;
{$ENDIF}

function  Min(a, b: LongInt): LongInt; inline;
function  Max(a, b: LongInt): LongInt; inline;

function  IntToStr(n: LongInt): shortstring;
function  StrToInt(s: shortstring): LongInt;
function  FloatToStr(n: hwFloat): shortstring;

function  DxDy2Angle(const _dY, _dX: hwFloat): GLfloat;
function  DxDy2Angle32(const _dY, _dX: hwFloat): LongInt;
function  DxDy2AttackAngle(const _dY, _dX: hwFloat): LongInt;
function  DxDy2AttackAnglef(const _dY, _dX: extended): LongInt;

procedure SetLittle(var r: hwFloat);

function  Str2PChar(const s: shortstring): PChar;
function  DecodeBase64(s: shortstring): shortstring;

function  isPowerOf2(i: Longword): boolean;
function  toPowerOf2(i: Longword): Longword; inline;

function  endian(independent: LongWord): LongWord; inline;

function  CheckCJKFont(s: ansistring; font: THWFont): THWFont;

procedure AddFileLog(s: shortstring);

function  CheckNoTeamOrHH: boolean; inline;

function  GetLaunchX(at: TAmmoType; dir: LongInt; angle: LongInt): LongInt;
function  GetLaunchY(at: TAmmoType; angle: LongInt): LongInt;

{$IFNDEF PAS2C}
procedure Write(var f: textfile; s: shortstring);
procedure WriteLn(var f: textfile; s: shortstring);
{$ENDIF}

procedure initModule(isGame: boolean);
procedure freeModule;


implementation
uses {$IFNDEF PAS2C}typinfo, {$ENDIF}Math, uConsts, uVariables, SysUtils;

{$IFDEF DEBUGFILE}
var f: textfile;
{$ENDIF}
var CharArray: array[byte] of Char;

procedure SplitBySpace(var a,b: shortstring);
begin
SplitByChar(a,b,' ');
end;

// should this include "strtolower()" for the split string?
procedure SplitByChar(var a, b: shortstring; c : char);
var i, t: LongInt;
begin
i:= Pos(c, a);
if i > 0 then
    begin
    for t:= 1 to Pred(i) do
        if (a[t] >= 'A')and(a[t] <= 'Z') then
            Inc(a[t], 32);
    b:= copy(a, i + 1, Length(a) - i);
    a[0]:= char(Pred(i))
    end
else
    b:= '';
end;

procedure SplitByChar(var a, b: ansistring; c: char);
var i: LongInt;
begin
i:= Pos(c, a);
if i > 0 then
    begin
    b:= copy(a, i + 1, Length(a) - i);
    setlength(a, Pred(i));
    end else b:= '';
end;

{$IFNDEF PAS2C}
function EnumToStr(const en : TGearType) : shortstring; overload;
begin
EnumToStr:= GetEnumName(TypeInfo(TGearType), ord(en))
end;
function EnumToStr(const en : TVisualGearType) : shortstring; overload;
begin
EnumToStr:= GetEnumName(TypeInfo(TVisualGearType), ord(en))
end;

function EnumToStr(const en : TSound) : shortstring; overload;
begin
EnumToStr:= GetEnumName(TypeInfo(TSound), ord(en))
end;

function EnumToStr(const en : TAmmoType) : shortstring; overload;
begin
EnumToStr:= GetEnumName(TypeInfo(TAmmoType), ord(en))
end;

function EnumToStr(const en: THogEffect) : shortstring; overload;
begin
EnumToStr := GetEnumName(TypeInfo(THogEffect), ord(en))
end;

function EnumToStr(const en: TCapGroup) : shortstring; overload;
begin
EnumToStr := GetEnumName(TypeInfo(TCapGroup), ord(en))
end;
{$ENDIF}

function Min(a, b: LongInt): LongInt;
begin
if a < b then
    Min:= a
else
    Min:= b
end;

function Max(a, b: LongInt): LongInt;
begin
if a > b then
    Max:= a
else
    Max:= b
end;


function IntToStr(n: LongInt): shortstring;
begin
str(n, IntToStr)
end;

function  StrToInt(s: shortstring): LongInt;
var c: LongInt;
begin
val(s, StrToInt, c)
end;

function FloatToStr(n: hwFloat): shortstring;
begin
FloatToStr:= cstr(n) + '_' + inttostr(Lo(n.QWordValue))
end;


function DxDy2Angle(const _dY, _dX: hwFloat): GLfloat;
var dY, dX: Extended;
begin
dY:= _dY.QWordValue / $100000000;
if _dY.isNegative then
    dY:= - dY;
dX:= _dX.QWordValue / $100000000;
if _dX.isNegative then
    dX:= - dX;
DxDy2Angle:= arctan2(dY, dX) * 180 / pi
end;

function DxDy2Angle32(const _dY, _dX: hwFloat): LongInt;
const _16divPI: Extended = 16/pi;
var dY, dX: Extended;
begin
dY:= _dY.QWordValue / $100000000;
if _dY.isNegative then
    dY:= - dY;
dX:= _dX.QWordValue / $100000000;
if _dX.isNegative then
    dX:= - dX;
DxDy2Angle32:= trunc(arctan2(dY, dX) * _16divPI) and $1f
end;

function DxDy2AttackAngle(const _dY, _dX: hwFloat): LongInt;
const MaxAngleDivPI: Extended = cMaxAngle/pi;
var dY, dX: Extended;
begin
dY:= _dY.QWordValue / $100000000;
if _dY.isNegative then
    dY:= - dY;
dX:= _dX.QWordValue / $100000000;
if _dX.isNegative then
    dX:= - dX;
DxDy2AttackAngle:= trunc(arctan2(dY, dX) * MaxAngleDivPI)
end;

function DxDy2AttackAnglef(const _dY, _dX: extended): LongInt; inline;
begin
DxDy2AttackAnglef:= trunc(arctan2(_dY, _dX) * (cMaxAngle/pi))
end;


procedure SetLittle(var r: hwFloat);
begin
r:= SignAs(cLittle, r)
end;


function isPowerOf2(i: Longword): boolean;
begin
isPowerOf2:= (i and (i - 1)) = 0
end;

function toPowerOf2(i: Longword): Longword;
begin
toPowerOf2:= 1;
while (toPowerOf2 < i) do toPowerOf2:= toPowerOf2 shl 1
end;


function DecodeBase64(s: shortstring): shortstring;
const table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
var i, t, c: Longword;
begin
c:= 0;
for i:= 1 to Length(s) do
    begin
    t:= Pos(s[i], table);
    if s[i] = '=' then
        inc(c);
    if t > 0 then
        s[i]:= char(t - 1)
    else
        s[i]:= #0
    end;

i:= 1;
t:= 1;
while i <= length(s) do
    begin
    DecodeBase64[t    ]:= char((byte(s[i    ]) shl 2) or (byte(s[i + 1]) shr 4));
    DecodeBase64[t + 1]:= char((byte(s[i + 1]) shl 4) or (byte(s[i + 2]) shr 2));
    DecodeBase64[t + 2]:= char((byte(s[i + 2]) shl 6) or (byte(s[i + 3])      ));
    inc(t, 3);
    inc(i, 4)
    end;

if c < 3 then
    t:= t - c;

DecodeBase64[0]:= char(t - 1)
end;


function Str2PChar(const s: shortstring): PChar;
begin
CharArray:= s;
CharArray[Length(s)]:= #0;
Str2PChar:= @CharArray
end;


function endian(independent: LongWord): LongWord; inline;
begin
{$IFDEF ENDIAN_LITTLE}
endian:= independent;
{$ELSE}
endian:= (((independent and $FF000000) shr 24) or
          ((independent and $00FF0000) shr 8) or
          ((independent and $0000FF00) shl 8) or
          ((independent and $000000FF) shl 24))
{$ENDIF}
end;


procedure AddFileLog(s: shortstring);
begin
s:= s;
{$IFDEF DEBUGFILE}
writeln(f, inttostr(GameTicks)  + ': ' + s);
flush(f)
{$ENDIF}
end;


function CheckCJKFont(s: ansistring; font: THWFont): THWFont;
var l, i : LongInt;
    u: WideChar;
    tmpstr: array[0..256] of WideChar;
begin
CheckCJKFont:= font;

{$IFNDEF MOBILE}
// remove chinese fonts for now
if (font >= CJKfnt16) or (length(s) = 0) then
{$ENDIF}
    exit;

l:= Utf8ToUnicode(@tmpstr, Str2PChar(s), length(s))-1;
i:= 0;

while i < l do
    begin
    u:= tmpstr[i];
    if (#$1100  <= u) and  (
                           (u <= #$11FF )  or // Hangul Jamo
       ((#$2E80  <= u) and (u <= #$2FDF))  or // CJK Radicals Supplement / Kangxi Radicals
       ((#$2FF0  <= u) and (u <= #$303F))  or // Ideographic Description Characters / CJK Radicals Supplement
       ((#$3130  <= u) and (u <= #$318F))  or // Hangul Compatibility Jamo
       ((#$31C0  <= u) and (u <= #$31EF))  or // CJK Strokes
       ((#$3200  <= u) and (u <= #$4DBF))  or // Enclosed CJK Letters and Months / CJK Compatibility / CJK Unified Ideographs Extension A
       ((#$4E00  <= u) and (u <= #$9FFF))  or // CJK Unified Ideographs
       ((#$AC00  <= u) and (u <= #$D7AF))  or // Hangul Syllables
       ((#$F900  <= u) and (u <= #$FAFF))  or // CJK Compatibility Ideographs
       ((#$FE30  <= u) and (u <= #$FE4F)))    // CJK Compatibility Forms
       then 
        begin
            CheckCJKFont:=  THWFont( ord(font) + ((ord(High(THWFont))+1) div 2) );
            exit;
        end;
    inc(i)
    end;
(* two more to check. pascal WideChar is only 16 bit though
       ((#$20000 <= u) and (u >= #$2A6DF)) or // CJK Unified Ideographs Extension B
       ((#$2F800 <= u) and (u >= #$2FA1F)))   // CJK Compatibility Ideographs Supplement *)
end;


function GetLaunchX(at: TAmmoType; dir: LongInt; angle: LongInt): LongInt;
begin
GetLaunchX:= 0
(*
    if (Ammoz[at].ejectX <> 0) or (Ammoz[at].ejectY <> 0) then
        GetLaunchX:= sign(dir) * (8 + hwRound(AngleSin(angle) * Ammoz[at].ejectX) + hwRound(AngleCos(angle) * Ammoz[at].ejectY))
    else
        GetLaunchX:= 0 *)
end;

function GetLaunchY(at: TAmmoType; angle: LongInt): LongInt;
begin
GetLaunchY:= 0
(*
    if (Ammoz[at].ejectX <> 0) or (Ammoz[at].ejectY <> 0) then
        GetLaunchY:= hwRound(AngleSin(angle) * Ammoz[at].ejectY) - hwRound(AngleCos(angle) * Ammoz[at].ejectX) - 2
    else
        GetLaunchY:= 0*)
end;

function CheckNoTeamOrHH: boolean;
begin
CheckNoTeamOrHH:= (CurrentTeam = nil) or (CurrentHedgehog^.Gear = nil);
end;

{$IFNDEF PAS2C}
procedure Write(var f: textfile; s: shortstring);
begin
system.write(f, s)
end;

procedure WriteLn(var f: textfile; s: shortstring);
begin
system.writeln(f, s)
end;
{$ENDIF}

procedure initModule(isGame: boolean);
{$IFDEF DEBUGFILE}
var logfileBase: shortstring;
{$IFNDEF MOBILE}var i: LongInt;{$ENDIF}
{$ENDIF}
begin
{$IFDEF DEBUGFILE}
    if isGame then
        logfileBase:= 'game'
    else
        logfileBase:= 'preview';
{$I-}
{$IFDEF MOBILE}
    {$IFDEF IPHONEOS} Assign(f,'../Documents/hw-' + logfileBase + '.log'); {$ENDIF}
    {$IFDEF ANDROID} Assign(f,pathPrefix + '/' + logfileBase + '.log'); {$ENDIF}
    Rewrite(f);
{$ELSE}
    if (UserPathPrefix <> '') then
        begin
            i:= 0;
            while(i < 7) do
            begin
                assign(f, UserPathPrefix + '/Logs/' + logfileBase + inttostr(i) + '.log');
                rewrite(f);
                if IOResult = 0 then
                    break;
                inc(i)
            end;
            if i = 7 then
                f:= stderr; // if everything fails, write to stderr
        end
    else
        f:= stderr;
{$ENDIF}
{$I+}
{$ENDIF}

end;

procedure freeModule;
begin
recordFileName:= '';

{$IFDEF DEBUGFILE}
    writeln(f, 'halt at ' + inttostr(GameTicks) + ' ticks. TurnTimeLeft = ' + inttostr(TurnTimeLeft));
    flush(f);
    close(f);
{$ENDIF}
end;

end.
