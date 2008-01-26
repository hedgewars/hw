(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004-2007 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uMisc;
interface
uses uConsts, SDLh, uFloat, GL;
{$INCLUDE options.inc}
var isCursorVisible : boolean = false;
    isTerminated    : boolean = false;
    isInLag         : boolean = false;
    isPaused        : boolean = false;
    isSoundEnabled  : boolean = true;
    isSEBackup      : boolean = true;
    isInMultiShoot  : boolean = false;
    isSpeed         : boolean = false;

    GameState     : TGameState = Low(TGameState);
    GameType      : TGameType = gmtLocal;
    GameFlags     : Longword = 0;
    TurnTimeLeft  : Longword = 0;
    cHedgehogTurnTime: Longword = 45000;
    cMaxAIThinkTime  : Longword = 9000;

    cCloudsNumber    : LongInt = 9;
    cConsoleHeight   : LongInt = 320;
    cConsoleYAdd     : LongInt = 0;
    cScreenWidth     : LongInt = 1024;
    cScreenHeight    : LongInt = 768;
    cBits            : LongInt = 16;
    cBitsStr         : string[2] = '16';
    cTagsMask        : byte = 7;

    cWaterLine       : LongInt = 1024;
    cVisibleWater    : LongInt = 128;
    cGearScrEdgesDist: LongInt = 240;
    cCursorEdgesDist : LongInt = 40;
    cTeamHealthWidth : LongInt = 128;
    cAltDamage       : boolean = true;

    GameTicks     : LongWord = 0;

    cSkyColor     : Longword = 0;
    cWaterColor   : Longword = $005ACE;
    cWhiteColor   : Longword = $FFFFFF;
    cConsoleSplitterColor : Longword = $FF0000;
    cColorNearBlack       : Longword = 16;
    cExplosionBorderColor : LongWord = $808080;

    cShowFPS      : boolean = true;
    cCaseFactor   : Longword = 6;  {0..9}
    cLandAdditions: Longword = 4;
    cFullScreen   : boolean = true;
    cLocaleFName  : shortstring = 'en.txt';
    cSeed         : shortstring = '';
    cInitVolume   : LongInt = 128;
    cVolumeDelta  : LongInt = 0;
    cTimerInterval   : Longword = 5;
    cHasFocus     : boolean = true;
    cInactDelay   : Longword = 1500;

{$WARNINGS OFF}
    cAirPlaneSpeed: hwFloat = (isNegative: false; QWordValue:   6012954214); // 1.4
    cBombsSpeed   : hwFloat = (isNegative: false; QWordValue:    429496729);
{$WARNINGS ON}

var
    cSendEmptyPacketTime : LongWord = 2000;
    cSendCursorPosTime   : LongWord = 50;
    ShowCrosshair  : boolean;
    cDrownSpeed,
    cMaxWindSpeed,
    cWindSpeed,
    cGravity: hwFloat;

    flagMakeCapture: boolean = false;

    InitStepsFlags: Longword = 0;

    RealTicks: Longword = 0;
    
    AttackBar: LongInt = 0; // 0 - none, 1 - just bar at the right-down corner, 2 - like in WWP

function hwSign(r: hwFloat): LongInt;
function Min(a, b: LongInt): LongInt; 
function Max(a, b: LongInt): LongInt;
function rndSign(num: hwFloat): hwFloat;
procedure OutError(Msg: String; isFatalError: boolean);
procedure TryDo(Assert: boolean; Msg: string; isFatal: boolean);
procedure SDLTry(Assert: boolean; isFatal: boolean);
function IntToStr(n: LongInt): shortstring;
function FloatToStr(n: hwFloat): shortstring;
function DxDy2Angle32(const _dY, _dX: hwFloat): LongInt;
function DxDy2AttackAngle(const _dY, _dX: hwFloat): LongInt;
procedure AdjustColor(var Color: Longword);
{$IFDEF DEBUGFILE}
procedure AddFileLog(s: shortstring);
function RectToStr(Rect: TSDL_Rect): shortstring;
{$ENDIF}
procedure SetKB(n: Longword);
procedure SendKB;
procedure SetLittle(var r: hwFloat);
procedure SendStat(sit: TStatInfoType; s: shortstring);
function  Str2PChar(const s: shortstring): PChar;
function  Surface2Tex(surf: PSDL_Surface): PTexture;
procedure FreeTexture(tex: PTexture);

var CursorPoint: TPoint;
    TargetPoint: TPoint = (X: NoPointX; Y: 0);

implementation
uses uConsole, uStore, uIO, Math, uRandom;
var KBnum: Longword = 0;
{$IFDEF DEBUGFILE}
var f: textfile;
{$ENDIF}

function hwSign(r: hwFloat): LongInt;
begin
if r.isNegative then hwSign:= -1 else hwSign:= 1
end;

function Min(a, b: LongInt): LongInt;
begin
if a < b then Min:= a else Min:= b
end;

function Max(a, b: LongInt): LongInt;
begin
if a > b then Max:= a else Max:= b
end;

procedure OutError(Msg: String; isFatalError: boolean);
begin
{$IFDEF DEBUGFILE}AddFileLog(Msg);{$ENDIF}
WriteLnToConsole(Msg);
if isFatalError then
   begin
   SendIPC('E' + GetLastConsoleLine);
   SDL_Quit;
   halt(1)
   end
end;

procedure TryDo(Assert: boolean; Msg: string; isFatal: boolean);
begin
if not Assert then OutError(Msg, isFatal)
end;

procedure SDLTry(Assert: boolean; isFatal: boolean);
begin
if not Assert then OutError(SDL_GetError, isFatal)
end;

procedure AdjustColor(var Color: Longword);
begin
Color:= SDL_MapRGB(PixelFormat, (Color shr 16) and $FF, (Color shr 8) and $FF, Color and $FF)
end;

function IntToStr(n: LongInt): shortstring;
begin
str(n, IntToStr)
end;

function FloatToStr(n: hwFloat): shortstring;
begin
FloatToStr:= cstr(n)
end;

function DxDy2Angle32(const _dY, _dX: hwFloat): LongInt;
const _16divPI: Extended = 16/pi;
var dY, dX: Extended;
begin
dY:= _dY.QWordValue / $100000000;
if _dY.isNegative then dY:= - dY;
dX:= _dX.QWordValue / $100000000;
if _dX.isNegative then dX:= - dX;
DxDy2Angle32:= trunc(arctan2(dY, dX) * _16divPI) and $1f
end;

function DxDy2AttackAngle(const _dY, _dX: hwFloat): LongInt;
const MaxAngleDivPI: Extended = cMaxAngle/pi;
var dY, dX: Extended;
begin
dY:= _dY.QWordValue / $100000000;
if _dY.isNegative then dY:= - dY;
dX:= _dX.QWordValue / $100000000;
if _dX.isNegative then dX:= - dX;
DxDy2AttackAngle:= trunc(arctan2(dY, dX) * MaxAngleDivPI)
end;

procedure SetKB(n: Longword);
begin
KBnum:= n
end;

procedure SendKB;
var s: shortstring;
begin
if KBnum <> 0 then
   begin
   s:= 'K' + inttostr(KBnum);
   SendIPCRaw(@s, Length(s) + 1)
   end
end;

procedure SetLittle(var r: hwFloat);
begin
r:= SignAs(cLittle, r)
end;

procedure SendStat(sit: TStatInfoType; s: shortstring);
const stc: array [TStatInfoType] of char = 'rDK';
begin
SendIPC('i' + stc[sit] + s)
end;

function rndSign(num: hwFloat): hwFloat;
begin
num.isNegative:= getrandom(2) = 0;
rndSign:= num
end;

function Str2PChar(const s: shortstring): PChar;
const CharArray: array[byte] of Char = '';
begin
CharArray:= s;
CharArray[Length(s)]:= #0;
Str2PChar:= @CharArray
end;

{$IFDEF DEBUGFILE}
procedure AddFileLog(s: shortstring);
begin
writeln(f, GameTicks: 6, ': ', s);
flush(f)
end;

function RectToStr(Rect: TSDL_Rect): shortstring;
begin
RectToStr:= '(x: ' + inttostr(rect.x) + '; y: ' + inttostr(rect.y) + '; w: ' + inttostr(rect.w) + '; h: ' + inttostr(rect.h) + ')'
end;

function Surface2Tex(surf: PSDL_Surface): PTexture;
var mode: LongInt;
    texId: GLuint;
begin
if SDL_MustLock(surf) then
   SDLTry(SDL_LockSurface(surf) >= 0, true);

new(Surface2Tex);
Surface2Tex^.w:= surf^.w;
Surface2Tex^.h:= surf^.h;

if (surf^.format^.BytesPerPixel = 3) then mode:= GL_RGB else
if (surf^.format^.BytesPerPixel = 4) then mode:= GL_RGBA else
   begin
   TryDo(false, 'Surface2Tex: BytePerPixel not in [3, 4]', false);
   Surface2Tex^.id:= 0;
   exit
   end;

glGenTextures(1, @Surface2Tex^.id);

glBindTexture(GL_TEXTURE_2D, Surface2Tex^.id);

glTexImage2D(GL_TEXTURE_2D, 0, mode, surf^.w, surf^.h, 0, mode, GL_UNSIGNED_BYTE, surf^.pixels);

if SDL_MustLock(surf) then
   SDL_UnlockSurface(surf);

glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)
end;

procedure FreeTexture(tex: PTexture);
begin
glDeleteTextures(1, @tex^.id);
dispose(tex)
end;

var i: LongInt;
{$ENDIF}

initialization
cDrownSpeed.QWordValue:= 257698038;// 0.06
cMaxWindSpeed.QWordValue:= 2147484;// 0.0005
cWindSpeed.QWordValue:=     429496;// 0.0001
cGravity:= cMaxWindSpeed;

{$IFDEF DEBUGFILE}
{$I-}
if ParamCount > 0 then
  for i:= 0 to 7 do
    begin
    Assign(f, ParamStr(1) + '/debug' + inttostr(i) + '.txt');
    rewrite(f);
    if IOResult = 0 then break
    end;
{$I+}

finalization
writeln(f, '-= halt at ',GameTicks,' ticks =-');
Flush(f);
close(f)
{$ENDIF}

end.
