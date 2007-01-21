(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004, 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
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
uses uConsts, SDLh, uFloat;
{$INCLUDE options.inc}
var isCursorVisible : boolean = false;
    isTerminated    : boolean = false;
    isInLag         : boolean = false;
    isPaused        : boolean = false;
    isSoundEnabled  : boolean = true;
    isSEBackup      : boolean = true;
    isInMultiShoot  : boolean = false;

    GameState     : TGameState = Low(TGameState);
    GameType      : TGameType = gmtLocal;
    GameFlags     : Longword = 0;
    TurnTimeLeft  : Longword = 0;
    cHedgehogTurnTime: Longword = 45000;
    cMaxAIThinkTime  : Longword = 5000;

    cCloudsNumber    : integer = 9;
    cConsoleHeight   : integer = 320;
    cConsoleYAdd     : integer = 0;
    cScreenWidth     : integer = 1024;
    cScreenHeight    : integer = 768;
    cBits            : integer = 16;
    cBitsStr         : string[2] = '16';

    cWaterLine       : integer = 1024;
    cVisibleWater    : integer = 128;
    cGearScrEdgesDist: integer = 240;
    cCursorEdgesDist : integer = 40;
    cTeamHealthWidth : integer = 128;

    GameTicks     : LongWord = 0;

    cSkyColor     : Longword = 0;
    cWaterColor   : Longword = $005ACE;
    cWhiteColor   : Longword = $FFFFFF;
    cConsoleSplitterColor : Longword = $FF0000;
    cColorNearBlack       : Longword = 16;
    cExplosionBorderColor : LongWord = $808080;

    cShowFPS      : boolean = true;
    cCaseFactor   : Longword = 3;  {1..10}
    cFullScreen   : boolean = true;
    cLocaleFName  : shortstring = 'en.txt';
    cSeed         : shortstring = '';
    cInitVolume   : integer = 128;
    cVolumeDelta  : integer = 0;
    cTimerInterval   : Longword = 5;
    cHasFocus     : boolean = true;

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

    AttackBar: integer = 0; // 0 - none, 1 - just bar at the right-down corner, 2 - like in WWP

function hwSign(r: hwFloat): integer;
function Min(a, b: integer): integer;
function Max(a, b: integer): integer;
function rndSign(num: hwFloat): hwFloat;
procedure OutError(Msg: String; isFatalError: boolean);
procedure TryDo(Assert: boolean; Msg: string; isFatal: boolean);
procedure SDLTry(Assert: boolean; isFatal: boolean);
function IntToStr(n: LongInt): shortstring;
function FloatToStr(n: hwFloat): shortstring;
function DxDy2Angle32(const _dY, _dX: Extended): integer;
function DxDy2AttackAngle(const _dY, _dX: Extended): integer;
procedure AdjustColor(var Color: Longword);
{$IFDEF DEBUGFILE}
procedure AddFileLog(s: shortstring);
function RectToStr(Rect: TSDL_Rect): shortstring;
{$ENDIF}
procedure SetKB(n: Longword);
procedure SendKB;
procedure SetLittle(var r: hwFloat);
procedure SendStat(sit: TStatInfoType; s: shortstring);
function Str2PChar(var s: shortstring): PChar;

var CursorPoint: TPoint;
    TargetPoint: TPoint = (X: NoPointX; Y: 0);

implementation
uses uConsole, uStore, uIO, Math, uRandom;
var KBnum: Longword = 0;
{$IFDEF DEBUGFILE}
var f: textfile;
{$ENDIF}

function hwSign(r: hwFloat): integer;
begin
if r.isNegative then hwSign:= -1 else hwSign:= 1
end;

function Min(a, b: integer): integer;
begin
if a < b then Min:= a else Min:= b
end;

function Max(a, b: integer): integer;
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

{$IFNDEF FPC}
function arctan2(const Y, X: hwFloat): hwFloat;
asm
        fld     Y
        fld     X
        fpatan
        fwait
end;
{$ENDIF}

function DxDy2Angle32(const _dY, _dX: Extended): integer;
const _16divPI: Extended = 16/pi;
begin
DxDy2Angle32:= trunc(arctan2(_dY, _dX) * _16divPI) and $1f
end;

function DxDy2AttackAngle(const _dY, _dX: Extended): integer;
const MaxAngleDivPI: Extended = cMaxAngle/pi;
begin
DxDy2AttackAngle:= trunc(arctan2(_dY, _dX) * MaxAngleDivPI) mod cMaxAngle
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
if not r.isNegative then r:= cLittle else r:= - cLittle
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

function Str2PChar(var s: shortstring): PChar;
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


var i: integer;

initialization
cDrownSpeed.QWordValue:= 257698038;// 0.06
cMaxWindSpeed.QWordValue:=   2147484;// 0.0005
cWindSpeed.QWordValue:=    429496;// 0.0001
cGravity:= cMaxWindSpeed;


{$I-}
for i:= 0 to 7 do
    begin
    Assign(f, 'debug' + inttostr(i) + '.txt');
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
