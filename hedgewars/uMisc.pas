(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2008 Andrey Korotaev <unC0Rr@gmail.com>
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
var
	isCursorVisible : boolean = false;
	isTerminated    : boolean = false;
	isInLag         : boolean = false;
	isPaused        : boolean = false;
	isSoundEnabled  : boolean = true;
	isMusicEnabled  : boolean = false;
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
	cScreenWidth     : LongInt = 1024;
	cScreenHeight    : LongInt = 768;
	cInitWidth       : LongInt = 1024;
	cInitHeight      : LongInt = 768;
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
	cWhiteColor   : Longword = $FFFFFFFF;
	cColorNearBlack       : Longword = $FF000010;
	cExplosionBorderColor : LongWord = $808080;

	cShowFPS      : boolean = true;
	cCaseFactor   : Longword = 5;  {0..9}
	cLandAdditions: Longword = 4;
	cFullScreen   : boolean = true;
	cLocaleFName  : shortstring = 'en.txt';
	cSeed         : shortstring = '';
	cInitVolume   : LongInt = 128;
	cVolumeDelta  : LongInt = 0;
	cTimerInterval   : Longword = 5;
	cHasFocus     : boolean = true;
	cInactDelay   : Longword = 1250;

	bBetweenTurns: boolean = false;
	cHealthDecrease: LongWord = 0;
	bWaterRising   : Boolean = false;

{$WARNINGS OFF}
	cAirPlaneSpeed: hwFloat = (isNegative: false; QWordValue:   3006477107); // 1.4
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
procedure OutError(Msg: String; isFatalError: boolean);
procedure TryDo(Assert: boolean; Msg: string; isFatal: boolean);
procedure SDLTry(Assert: boolean; isFatal: boolean);
function IntToStr(n: LongInt): shortstring;
function FloatToStr(n: hwFloat): shortstring;
function DxDy2Angle(const _dY, _dX: hwFloat): GLfloat;
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
function NewTexture(width, height: Longword; buf: Pointer): PTexture;
function  Surface2Tex(surf: PSDL_Surface): PTexture;
procedure FreeTexture(tex: PTexture);
function  toPowerOf2(i: Longword): Longword;
function DecodeBase64(s: shortstring): shortstring;
procedure MakeScreenshot(s: shortstring);

var CursorPoint: TPoint;
    TargetPoint: TPoint = (X: NoPointX; Y: 0);

implementation
uses uConsole, uStore, uIO, Math, uRandom, GLU;
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

function DxDy2Angle(const _dY, _dX: hwFloat): GLfloat;
var dY, dX: Extended;
begin
dY:= _dY.QWordValue / $100000000;
if _dY.isNegative then dY:= - dY;
dX:= _dX.QWordValue / $100000000;
if _dX.isNegative then dX:= - dX;
DxDy2Angle:= arctan2(dY, dX) * 180 / pi
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
const stc: array [TStatInfoType] of char = 'rDkK';
begin
SendIPC('i' + stc[sit] + s)
end;

function Str2PChar(const s: shortstring): PChar;
const CharArray: array[byte] of Char = '';
begin
CharArray:= s;
CharArray[Length(s)]:= #0;
Str2PChar:= @CharArray
end;

function isPowerOf2(i: Longword): boolean;
begin
if i = 0 then exit(true);
while (i and 1) = 0 do i:= i shr 1;
isPowerOf2:= (i = 1)
end;

function toPowerOf2(i: Longword): Longword;
begin
toPowerOf2:= 1;
while (toPowerOf2 < i) do toPowerOf2:= toPowerOf2 shl 1
end;

function NewTexture(width, height: Longword; buf: Pointer): PTexture;
begin
new(NewTexture);
NewTexture^.w:= width;
NewTexture^.h:= height;

glGenTextures(1, @NewTexture^.id);

glBindTexture(GL_TEXTURE_2D, NewTexture^.id);

glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, buf);

glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
end;

function Surface2Tex(surf: PSDL_Surface): PTexture;
var mode: LongInt;
    tw, th: Longword;
    tmpp: pointer;
begin
new(Surface2Tex);
Surface2Tex^.w:= surf^.w;
Surface2Tex^.h:= surf^.h;

if (surf^.format^.BytesPerPixel = 3) then mode:= GL_RGB else
if (surf^.format^.BytesPerPixel = 4) then mode:= GL_RGBA else
   begin
   TryDo(false, 'Surface2Tex: BytesPerPixel not in [3, 4]', true);
   Surface2Tex^.id:= 0;
   exit
   end;

glGenTextures(1, @Surface2Tex^.id);

glBindTexture(GL_TEXTURE_2D, Surface2Tex^.id);

if SDL_MustLock(surf) then
   SDLTry(SDL_LockSurface(surf) >= 0, true);

if not (isPowerOf2(Surf^.w) and isPowerOf2(Surf^.h)) then
   begin
   tw:= toPowerOf2(Surf^.w);
   th:= toPowerOf2(Surf^.h);

   GetMem(tmpp, tw * th * surf^.format^.BytesPerPixel);

   gluScaleImage(mode, Surf^.w, Surf^.h, GL_UNSIGNED_BYTE,
        Surf^.pixels, tw, th, GL_UNSIGNED_BYTE,
        tmpp);

   glTexImage2D(GL_TEXTURE_2D, 0, mode, tw, th, 0, mode, GL_UNSIGNED_BYTE, tmpp);

   FreeMem(tmpp, tw * th * surf^.format^.BytesPerPixel)
   end else
   glTexImage2D(GL_TEXTURE_2D, 0, mode, surf^.w, surf^.h, 0, mode, GL_UNSIGNED_BYTE, surf^.pixels);

if SDL_MustLock(surf) then
   SDL_UnlockSurface(surf);

glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
end;

procedure FreeTexture(tex: PTexture);
begin
glDeleteTextures(1, @tex^.id);
dispose(tex)
end;

function DecodeBase64(s: shortstring): shortstring;
const table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
var i, t, c: Longword;
begin
c:= 0;
for i:= 1 to Length(s) do
	begin
	t:= Pos(s[i], table);
	if s[i] = '=' then inc(c);
	if t > 0 then byte(s[i]):= t - 1 else byte(s[i]):= 0
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

if c < 3 then t:= t - c;

byte(DecodeBase64[0]):= t - 1
end;

const GL_BGR = $80E0; // some opengl headers don't have that const (?)
procedure MakeScreenshot(s: shortstring);
const head: array[0..8] of Word = (0, 2, 0, 0, 0, 0, 0, 0, 24);
var p: Pointer;
	size: Longword;
	f: file;
begin
head[6]:= cScreenWidth;
head[7]:= cScreenHeight;

size:= cScreenWidth * cScreenHeight * 3;
p:= GetMem(size);

glReadBuffer(GL_FRONT);
glReadPixels(0, 0, cScreenWidth, cScreenHeight, GL_BGR, GL_UNSIGNED_BYTE, p);

{$I-}
Assign(f, s);
Rewrite(f, 1);
if IOResult = 0 then
	begin
	BlockWrite(f, head, sizeof(head));
	BlockWrite(f, p^, size);
	Close(f);
	end;
{$I+}

FreeMem(p)
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
//uRandom.DumpBuffer;
writeln(f, '-= halt at ',GameTicks,' ticks =-');
Flush(f);
close(f)
{$ENDIF}

end.
