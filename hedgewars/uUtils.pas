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

unit uUtils;

interface
uses uTypes, uFloat;

procedure SplitBySpace(var a, b: shortstring);
procedure SplitByChar(var a, b: shortstring; c: char);
procedure SplitByCharA(var a, b: ansistring; c: char);

function  EnumToStr(const en : TGearType) : shortstring; overload;
function  EnumToStr(const en : TVisualGearType) : shortstring; overload;
function  EnumToStr(const en : TSound) : shortstring; overload;
function  EnumToStr(const en : TAmmoType) : shortstring; overload;
function  EnumToStr(const en : TStatInfoType) : shortstring; overload;
function  EnumToStr(const en : THogEffect) : shortstring; overload;
function  EnumToStr(const en : TCapGroup) : shortstring; overload;
function  EnumToStr(const en : TSprite) : shortstring; overload;
function  EnumToStr(const en : TMapGen) : shortstring; overload;

function  Min(a, b: LongInt): LongInt; inline;
function  MinD(a, b: double) : double; inline;
function  Max(a, b: LongInt): LongInt; inline;

function  IntToStr(n: LongInt): shortstring;
function  StrToInt(s: shortstring): LongInt;
function  FloatToStr(n: hwFloat): shortstring;

function  DxDy2Angle(const _dY, _dX: hwFloat): real; inline;
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
procedure AddFileLogRaw(s: pchar); cdecl;

function  CheckNoTeamOrHH: boolean; inline;

function  GetLaunchX(at: TAmmoType; dir: LongInt; angle: LongInt): LongInt;
function  GetLaunchY(at: TAmmoType; angle: LongInt): LongInt;

{$IFNDEF PAS2C}
procedure Write(var f: textfile; s: shortstring);
procedure WriteLn(var f: textfile; s: shortstring);
function StrLength(s: PChar): Longword;
procedure SetLengthA(var s: ansistring; len: Longword);
{$ENDIF}

function  isPhone: Boolean; inline;

{$IFDEF IPHONEOS}
procedure startLoadingIndicator; cdecl; external;
procedure stopLoadingIndicator; cdecl; external;
procedure saveFinishedSynching; cdecl; external;
function  isApplePhone: Boolean; cdecl; external;
procedure AudioServicesPlaySystemSound(num: LongInt); cdecl; external;
{$ENDIF}

function  sanitizeForLog(s: shortstring): shortstring;
function  sanitizeCharForLog(c: char): shortstring;

procedure initModule(isNotPreview: boolean);
procedure freeModule;


implementation
uses {$IFNDEF PAS2C}typinfo, {$ENDIF}Math, uConsts, uVariables, SysUtils, uPhysFSLayer;

{$IFDEF DEBUGFILE}
var logFile: PFSFile;
{$IFDEF USE_VIDEO_RECORDING}
    logMutex: TRTLCriticalSection; // mutex for debug file
{$ENDIF}
{$ENDIF}
var CharArray: array[0..255] of Char;

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
    {$IFDEF PAS2C}
       a[i] := 0;
    {$ENDIF}
    end
else
    b:= '';
end;

{$IFNDEF PAS2C}
procedure SetLengthA(var s: ansistring; len: Longword);
begin
    SetLength(s, len)
end;
{$ENDIF}

procedure SplitByCharA(var a, b: ansistring; c: char);
var i: LongInt;
begin
i:= Pos(c, a);
if i > 0 then
    begin
    b:= copy(a, i + 1, Length(a) - i);
    SetLengthA(a, Pred(i));
    end else b:= '';
end; { SplitByCharA }

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

function EnumToStr(const en : TStatInfoType) : shortstring; overload;
begin
EnumToStr:= GetEnumName(TypeInfo(TStatInfoType), ord(en))
end;

function EnumToStr(const en: THogEffect) : shortstring; overload;
begin
EnumToStr := GetEnumName(TypeInfo(THogEffect), ord(en))
end;

function EnumToStr(const en: TCapGroup) : shortstring; overload;
begin
EnumToStr := GetEnumName(TypeInfo(TCapGroup), ord(en))
end;

function EnumToStr(const en: TSprite) : shortstring; overload;
begin
EnumToStr := GetEnumName(TypeInfo(TSprite), ord(en))
end;

function EnumToStr(const en: TMapGen) : shortstring; overload;
begin
EnumToStr := GetEnumName(TypeInfo(TMapGen), ord(en))
end;


function Min(a, b: LongInt): LongInt;
begin
if a < b then
    Min:= a
else
    Min:= b
end;

function MinD(a, b: double): double;
begin
if a < b then
    MinD:= a
else
    MinD:= b
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

function StrToInt(s: shortstring): LongInt;
begin
val(s, StrToInt);
end;

function FloatToStr(n: hwFloat): shortstring;
begin
FloatToStr:= cstr(n) + '_' + inttostr(Lo(n.QWordValue))
end;


function DxDy2Angle(const _dY, _dX: hwFloat): real; inline;
var dY, dX: Extended;
begin
dY:= hwFloat2Float(_dY);
dX:= hwFloat2Float(_dX);
DxDy2Angle:= arctan2(dY, dX) * 180 / pi
end;

function DxDy2Angle32(const _dY, _dX: hwFloat): LongInt;
const _16divPI: Extended = 16/pi;
var dY, dX: Extended;
begin
dY:= hwFloat2Float(_dY);
dX:= hwFloat2Float(_dX);
DxDy2Angle32:= trunc(arctan2(dY, dX) * _16divPI) and $1f
end;

function DxDy2AttackAngle(const _dY, _dX: hwFloat): LongInt;
const MaxAngleDivPI: Extended = cMaxAngle/pi;
var dY, dX: Extended;
begin
dY:= hwFloat2Float(_dY);
dX:= hwFloat2Float(_dX);
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
var i, t, c: LongInt;
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
var i: Integer;
begin
   for i:= 1 to Length(s) do
      begin
      CharArray[i - 1] := s[i];
      end;
   CharArray[Length(s)]:= #0;
   Str2PChar:= @(CharArray[0]);
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
// s:= s;
{$IFDEF DEBUGFILE}

{$IFDEF USE_VIDEO_RECORDING}
EnterCriticalSection(logMutex);
{$ENDIF}
pfsWriteLn(logFile, inttostr(GameTicks)  + ': ' + s);

{$IFDEF USE_VIDEO_RECORDING}
LeaveCriticalSection(logMutex);
{$ENDIF}

{$ENDIF}
end;

procedure AddFileLogRaw(s: pchar); cdecl;
begin
s:= s;
{$IFNDEF PAS2C}
{$IFDEF DEBUGFILE}
{$IFDEF USE_VIDEO_RECORDING}
EnterCriticalSection(logMutex);
{$ENDIF}
// TODO: uncomment next two lines
// write(logFile, s);
// flush(logFile);
{$IFDEF USE_VIDEO_RECORDING}
LeaveCriticalSection(logMutex);
{$ENDIF}
{$ENDIF}
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

l:= Utf8ToUnicode(PWideChar(@tmpstr), PChar(s), min(length(tmpstr), length(s)))-1;
i:= 0;

while i < l do
    begin
    u:= tmpstr[i];
    if (#$1100  <= u) and  (
                           (u <= #$11FF )  or // Hangul Jamo
       ((#$2E80  <= u) and (u <= #$2FDF))  or // CJK Radicals Supplement / Kangxi Radicals
       ((#$2FF0  <= u) and (u <= #$31FF))  or // Ideographic Description Characters / CJK Radicals Supplement / Hiragana / Hangul Compatibility Jamo / Katakana
       ((#$31C0  <= u) and (u <= #$31EF))  or // CJK Strokes
       ((#$3200  <= u) and (u <= #$4DBF))  or // Enclosed CJK Letters and Months / CJK Compatibility / CJK Unified Ideographs Extension A / Circled Katakana
       ((#$4E00  <= u) and (u <= #$9FFF))  or // CJK Unified Ideographs
       ((#$AC00  <= u) and (u <= #$D7AF))  or // Hangul Syllables
       ((#$F900  <= u) and (u <= #$FAFF))  or // CJK Compatibility Ideographs
       ((#$FE30  <= u) and (u <= #$FE4F))  or // CJK Compatibility Forms
       ((#$FF66  <= u) and (u <= #$FF9D)))    // halfwidth katakana
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

function StrLength(s: PChar): Longword;
begin
    StrLength:= length(s)
end;
{$ENDIF}

// this function is just to determine whether we are running on a limited screen device
function isPhone: Boolean; inline;
begin
    isPhone:= false;
{$IFDEF IPHONEOS}
    isPhone:= isApplePhone();
{$ENDIF}
{$IFDEF ANDROID}
    //nasty nasty hack. TODO: implement callback to java to have a unified way of determining if it is a tablet
    if (cScreenWidth < 1000) and (cScreenHeight < 500) then
        isPhone:= true;
{$ENDIF}
end;


function  sanitizeForLog(s: shortstring): shortstring;
var i: byte;
    r: shortstring;
begin
    r[0]:= s[0];
    for i:= 1 to length(s) do
        if (s[i] < #32) or (s[i] > #127) then
            r[i]:= '?'
            else
            r[i]:= s[i];

    sanitizeForLog:= r
end;

function  sanitizeCharForLog(c: char): shortstring;
var r: shortstring;
begin
    if (c < #32) or (c > #127) then
        r:= '#' + inttostr(byte(c))
        else
        begin
        // some magic for pas2c
        r[0]:= #1;
        r[1]:= c;
        end;

    sanitizeCharForLog:= r
end;

procedure initModule(isNotPreview: boolean);
{$IFDEF DEBUGFILE}
var logfileBase: shortstring;
    i: LongInt;
{$ENDIF}
begin
{$IFDEF DEBUGFILE}
    if isNotPreview then
    begin
        if GameType = gmtRecord then
            logfileBase:= 'rec'
        else
        {$IFDEF PAS2C}
        logfileBase:= 'game_pas2c';
        {$ELSE}
        logfileBase:= 'game';
        {$ENDIF}
    end
    else
        {$IFDEF PAS2C}
        logfileBase:= 'preview_pas2c';
        {$ELSE}
        logfileBase:= 'preview';
        {$ENDIF}
{$IFDEF USE_VIDEO_RECORDING}
    InitCriticalSection(logMutex);
{$ENDIF}
    // if log is locked, write to the next one
    i:= 0;
    while(i < 7) do
    begin
        logFile:= pfsOpenWrite('/Logs/' + logfileBase + inttostr(i) + '.log');
        if logFile <> nil then
            break;
        inc(i)
    end;
{$ENDIF}

    //mobile stuff
{$IFDEF IPHONEOS}
    mobileRecord.PerformRumble:= @AudioServicesPlaySystemSound;
    mobileRecord.GameLoading:= @startLoadingIndicator;
    mobileRecord.GameLoaded:= @stopLoadingIndicator;
    mobileRecord.SaveLoadingEnded:= @saveFinishedSynching;
{$ELSE}
    mobileRecord.PerformRumble:= nil;
    mobileRecord.GameLoading:= nil;
    mobileRecord.GameLoaded:= nil;
    mobileRecord.SaveLoadingEnded:= nil;
{$ENDIF}

end;

procedure freeModule;
begin
{$IFDEF DEBUGFILE}
    pfsWriteLn(logFile, 'halt at ' + inttostr(GameTicks) + ' ticks. TurnTimeLeft = ' + inttostr(TurnTimeLeft));
    pfsFlush(logFile);
    pfsClose(logFile);
{$IFDEF USE_VIDEO_RECORDING}
    DoneCriticalSection(logMutex);
{$ENDIF}
{$ENDIF}
end;

end.
