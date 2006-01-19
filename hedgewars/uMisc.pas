(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004, 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * Distributed under the terms of the BSD-modified licence:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * with the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *)

unit uMisc;
interface
uses uConsts, SDLh;
{$INCLUDE options.inc}
var isCursorVisible : boolean = false;
    isTerminated    : boolean = false;
    isInLag         : boolean = false;
    isSoundEnabled  : boolean = true;
    isInMultiShoot  : boolean = false;

    GameState     : TGameState = Low(TGameState);
    GameType      : TGameType = gmtLocal;
    GameFlags     : Longword = 0;
    TurnTimeLeft  : Longword = 0;
    cHedgehogTurnTime: Longword = 30000;

    cLandYShift      : integer = 888;
    cCloudsNumber    : integer = 9;
    cConsoleHeight   : integer = 320;
    cConsoleYAdd     : integer = 0; 
    cTimerInterval   : Cardinal = 5;
    cScreenWidth     : integer = 1024;
    cScreenHeight    : integer = 768;
    cBits            : integer = 16;
    cWaterLine       : integer = 1024;
    cVisibleWater    : integer = 64;
    cScreenEdgesDist : integer = 240;
    cTeamHealthWidth : integer = 128;

    GameTicks     : LongWord = 0;

    cSkyColor     : Cardinal = 0;
    cWaterColor   : Cardinal = $32397A;
    cMapBackColor : Cardinal = $FFFFFF;
    cWhiteColor   : Cardinal = $FFFFFF;
    cConsoleSplitterColor : Cardinal = $FF0000;
    cColorNearBlack       : Cardinal = 16;
    cExplosionBorderColor : LongWord = $808080;

    cDrownSpeed   : Real = 0.06;
    cMaxWindSpeed : Real = 0.0005;
    cWindSpeed    : Real = 0.0001;
    cGravity      : Real = 0.0005;

    cShowFPS      : boolean = true;
    cFullScreen   : boolean = true;

const
    cMaxPower     = 1500;
    cMaxAngle     = 2048;
    cPowerDivisor = 1500;

var
    cSendEmptyPacketTime : LongWord = 2000;
    cSendCursorPosTime   : LongWord = 50;
    ShowCrosshair  : boolean;

    flagMakeCapture: boolean = false;

    AttackBar     : integer = 0; // 0 - отсутствует, 1 - внизу, 2 - как в wwp

function Sign(r: real): integer;
function Min(a, b: integer): integer;
function Max(a, b: integer): integer;
procedure OutError(Msg: String; const isFatalError: boolean=false);
procedure TryDo(Assert: boolean; Msg: string; isFatal: boolean);
procedure SDLTry(Assert: boolean; isFatal: boolean);
function IntToStr(n: integer): shortstring;
function FloatToStr(n: real): shortstring;
function arctan(const Y, X: real): real;
function DxDy2Angle32(const _dY, _dX: Extended): integer;
procedure AdjustColor(var Color: Longword);
{$IFDEF DEBUGFILE}
procedure AddFileLog(s: shortstring);
function RectToStr(Rect: TSDL_Rect): shortstring;
{$ENDIF}

var CursorPoint: TPoint;
    TargetPoint: TPoint = (X: NoPointX; Y: 0);

implementation
uses uConsole, uStore, uIO;
{$IFDEF DEBUGFILE}
var f: textfile;
{$ENDIF}


function Sign(r: real): integer;
begin
if r < 0 then Result:= -1 else Result:= 1
end;

function Min(a, b: integer): integer;
begin
if a < b then Result:= a else Result:= b
end;

function Max(a, b: integer): integer;
begin
if a > b then Result:= a else Result:= b
end;

procedure OutError(Msg: String; const isFatalError: boolean=false);
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
if not Assert then OutError(msg, isFatal)
end;

procedure SDLTry(Assert: boolean; isFatal: boolean);
begin
if not Assert then OutError(SDL_GetError, isFatal)
end;

procedure AdjustColor(var Color: Cardinal);
begin
Color:= SDL_MapRGB(PixelFormat, (Color shr 16) and $FF, (Color shr 8) and $FF, Color and $FF)
end;

function IntToStr(n: integer): shortstring;
begin
str(n, Result)
end;

function FloatToStr(n: real): shortstring;
begin
str(n:5:5, Result)
end;

function arctan(const Y, X: real): real;
asm
        fld     Y
        fld     X
        fpatan
        fwait
end;

function DxDy2Angle32(const _dY, _dX: Extended): integer;
const piDIV32: Extended = pi/32;
asm
        fld     _dY
        fld     _dX
        fpatan
        fld     piDIV32
        fdiv
        sub     esp, 4
        fistp   dword ptr [esp]
        pop     eax
        shr     eax, 1
        and     eax, $1F
end;


{$IFDEF DEBUGFILE}
procedure AddFileLog(s: shortstring);
begin
writeln(f, GameTicks: 6, ': ', s);
flush(f)
end;

function RectToStr(Rect: TSDL_Rect): shortstring;
begin
Result:= '(x: ' + inttostr(rect.x) + '; y: ' + inttostr(rect.y) + '; w: ' + inttostr(rect.w) + '; h: ' + inttostr(rect.h) + ')'
end;

initialization
assignfile(f, 'debug.txt');
rewrite(f);

finalization
writeln(f, '-= halt at ',GameTicks,' ticks =-');
Flush(f);
closefile(f)
{$ENDIF}

end.
