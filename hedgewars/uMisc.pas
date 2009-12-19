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

{$INCLUDE "options.inc"}

unit uMisc;
interface

uses uConsts, SDLh,
{$IFDEF GLES11}
	gles11,
{$ELSE}
	GL,
{$ENDIF}
	uFloat;
var
	isCursorVisible : boolean = false;
	isTerminated    : boolean = false;
	isInLag         : boolean = false;
	isPaused        : boolean = false;
	isSoundEnabled  : boolean = true;
	isSoundHardware : boolean = false;
	isMusicEnabled  : boolean = false;
	isSEBackup      : boolean = true;
	isInMultiShoot  : boolean = false;
	isSpeed         : boolean = false;

	fastUntilLag    : boolean = false;

	GameState     : TGameState = Low(TGameState);
	GameType      : TGameType = gmtLocal;
	GameFlags     : Longword = 0;
	TrainingFlags : Longword = 0;
	TurnTimeLeft  : Longword = 0;
	cSuddenDTurns : LongInt = 15;
	cDamagePercent  : LongInt = 100;
	cTemplateFilter : LongInt = 0;

	cHedgehogTurnTime: Longword = 45000;
	cMinesTime       : LongInt = 3000;
	cMaxAIThinkTime  : Longword = 9000;

	cCloudsNumber    : LongInt = 9;
	cScreenWidth     : LongInt = 1024;
	cScreenHeight    : LongInt = 768;
	cInitWidth       : LongInt = 1024;
	cInitHeight      : LongInt = 768;
	cBits            : LongInt = 32;
	cBitsStr         : string[2] = '32';
	cTagsMaskIndex   : byte = Low(cTagsMasks);
	zoom             : GLfloat = 2.0;
	ZoomValue        : GLfloat = 2.0;

	cWaterLine       : LongInt = LAND_HEIGHT;
	cVisibleWater    : LongInt = 128;
	cGearScrEdgesDist: LongInt = 240;
	cCursorEdgesDist : LongInt = 100;
	cTeamHealthWidth : LongInt = 128;
	cAltDamage       : boolean = true;

	GameTicks      : LongWord = 0;
	TrainingTimeInc: Longword = 10000;
	TrainingTimeInD: Longword = 500;
	TrainingTimeInM: Longword = 5000;
	TrainingTimeMax: Longword = 60000;

	TimeTrialStartTime: Longword = 0;
	TimeTrialStopTime : Longword = 0;
	
	cWhiteColorChannels	: TSDL_Color = (r:$FF; g:$FF; b:$FF; unused:$FF);
	cNearBlackColorChannels	: TSDL_Color = (r:$00; g:$00; b:$10; unused:$FF);

	cWhiteColor		: Longword = $FFFFFFFF;
	cYellowColor		: Longword = $FFFFFF00;
	cExplosionBorderColor	: LongWord = $FF808080;

	cShowFPS      : boolean = false;
	cCaseFactor   : Longword = 5;  {0..9}
	cLandAdditions: Longword = 4;
	cFullScreen   : boolean = false;
	cReducedQuality : boolean = false;
	cLocaleFName  : shortstring = 'en.txt';
	cSeed         : shortstring = '';
	cInitVolume   : LongInt = 50;
	cVolumeDelta  : LongInt = 0;
	cTimerInterval: Longword = 8;
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
	cSendCursorPosTime   : LongWord = 50;
	ShowCrosshair : boolean;
	CursorMovementX : Integer = 0;
	CursorMovementY : Integer = 0;
	cDrownSpeed,
	cMaxWindSpeed,
	cWindSpeed,
	cGravity: hwFloat;
	cDamageModifier: hwFloat;
	cLaserSighting: boolean;
	cVampiric: boolean;
	cArtillery: boolean;

	flagMakeCapture: boolean = false;

	InitStepsFlags: Longword = 0;

	RealTicks: Longword = 0;

	AttackBar: LongInt = 0; // 0 - none, 1 - just bar at the right-down corner, 2 - like in WWP

	i: LongInt;

type HwColor4f = record
	r, g, b, a: byte
	end;

var cWaterOpacity: byte = $80;

var WaterColorArray: array[0..3] of HwColor4f;

procedure movecursor(dx, dy: Integer);
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
function  Surface2Tex(surf: PSDL_Surface; enableClamp: boolean): PTexture;
procedure FreeTexture(tex: PTexture);
function  toPowerOf2(i: Longword): Longword;
function DecodeBase64(s: shortstring): shortstring;
function doSurfaceConversion(tmpsurf: PSDL_Surface): PSDL_Surface;
{$IFNDEF IPHONEOS}
procedure MakeScreenshot(s: shortstring);
{$ENDIF}

function modifyDamage(dmg: Longword): Longword;

var CursorPoint: TPoint;
    TargetPoint: TPoint = (X: NoPointX; Y: 0);

implementation
uses uConsole, uStore, uIO, Math, uRandom, uSound;
var KBnum: Longword = 0;
{$IFDEF DEBUGFILE}
var f: textfile;
{$ENDIF}

procedure movecursor(dx, dy: Integer);
var x, y: LongInt;
begin
if (dx = 0) and (dy = 0) then exit;
{$IFDEF SDL13}
SDL_GetMouseState(0, @x, @y);
{$ELSE}
SDL_GetMouseState(@x, @y);
{$ENDIF}
Inc(x, dx);
Inc(y, dy);
SDL_WarpMouse(x, y);
end;

function hwSign(r: hwFloat): LongInt;
begin
// yes, we have negative zero for a reason
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
FloatToStr:= cstr(n) + '_' + inttostr(Lo(n.QWordValue))
end;

procedure SetTextureParameters(enableClamp: Boolean);
begin
if enableClamp and not cReducedQuality then
    begin
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
    end;
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
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
const stc: array [TStatInfoType] of char = 'rDkKH';
var buf: shortstring;
begin
buf:= 'i' + stc[sit] + s;
SendIPCRaw(@buf[0], length(buf) + 1)
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

procedure ResetVertexArrays(texture: PTexture);
begin
with texture^ do
	begin
	vb[0].X:= 0;
	vb[0].Y:= 0;
	vb[1].X:= w;
	vb[1].Y:= 0;
	vb[2].X:= w;
	vb[2].Y:= h;
	vb[3].X:= 0;
	vb[3].Y:= h;

	tb[0].X:= 0;
	tb[0].Y:= 0;
	tb[1].X:= rx;
	tb[1].Y:= 0;
	tb[2].X:= rx;
	tb[2].Y:= ry;
	tb[3].X:= 0;
	tb[3].Y:= ry
	end;
end;

function NewTexture(width, height: Longword; buf: Pointer): PTexture;
begin
new(NewTexture);
NewTexture^.w:= width;
NewTexture^.h:= height;
NewTexture^.rx:= 1.0;
NewTexture^.ry:= 1.0;

ResetVertexArrays(NewTexture);

glGenTextures(1, @NewTexture^.id);

glBindTexture(GL_TEXTURE_2D, NewTexture^.id);
glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, buf);

SetTextureParameters(true);
end;

function Surface2Tex(surf: PSDL_Surface; enableClamp: boolean): PTexture;
var tw, th, x, y: Longword;
    tmpp: pointer;
    fromP4, toP4: PLongWordArray;
begin
new(Surface2Tex);
Surface2Tex^.w:= surf^.w;
Surface2Tex^.h:= surf^.h;

if (surf^.format^.BytesPerPixel <> 4) then
begin
	TryDo(false, 'Surface2Tex failed, expecting 32 bit surface', true);
	Surface2Tex^.id:= 0;
	exit
end;


glGenTextures(1, @Surface2Tex^.id);

glBindTexture(GL_TEXTURE_2D, Surface2Tex^.id);

if SDL_MustLock(surf) then
	SDLTry(SDL_LockSurface(surf) >= 0, true);

if (not SupportNPOTT) and (not (isPowerOf2(Surf^.w) and isPowerOf2(Surf^.h))) then
begin
	tw:= toPowerOf2(Surf^.w);
	th:= toPowerOf2(Surf^.h);

	Surface2Tex^.rx:= Surf^.w / tw;
	Surface2Tex^.ry:= Surf^.h / th;

	GetMem(tmpp, tw * th * surf^.format^.BytesPerPixel);

		fromP4:= Surf^.pixels;
		toP4:= tmpp;

		for y:= 0 to Pred(Surf^.h) do
		begin
			for x:= 0 to Pred(Surf^.w) do toP4^[x]:= fromP4^[x];
			for x:= Surf^.w to Pred(tw) do toP4^[x]:= 0;
			toP4:= @(toP4^[tw]);
			fromP4:= @(fromP4^[Surf^.pitch div 4]);
		end;

		for y:= Surf^.h to Pred(th) do
		begin
			for x:= 0 to Pred(tw) do toP4^[x]:= 0;
			toP4:= @(toP4^[tw]);
		end;

	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, tw, th, 0, GL_RGBA, GL_UNSIGNED_BYTE, tmpp);

	FreeMem(tmpp, tw * th * surf^.format^.BytesPerPixel)
end
else
begin
	Surface2Tex^.rx:= 1.0;
	Surface2Tex^.ry:= 1.0;
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, surf^.w, surf^.h, 0, GL_RGBA, GL_UNSIGNED_BYTE, surf^.pixels);
end;

ResetVertexArrays(Surface2Tex);

if SDL_MustLock(surf) then
	SDL_UnlockSurface(surf);

SetTextureParameters(enableClamp);
end;

procedure FreeTexture(tex: PTexture);
begin
if tex <> nil then
	begin
	glDeleteTextures(1, @tex^.id);
	dispose(tex)
	end
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

{$IFNDEF IPHONEOS}
procedure MakeScreenshot(s: shortstring);
const head: array[0..8] of Word = (0, 2, 0, 0, 0, 0, 0, 0, 24);
var p: Pointer;
	size: Longword;
	f: file;
begin
playSound(sndShutter, false, nil);
head[6]:= cScreenWidth;
head[7]:= cScreenHeight;

size:= cScreenWidth * cScreenHeight * 3;
p:= GetMem(size);


//remember that opengles operates on a single surface, so GL_FRONT *should* be implied
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
{$ENDIF}

function modifyDamage(dmg: Longword): Longword;
begin
ModifyDamage:= hwRound(_0_01 * cDamageModifier * dmg * cDamagePercent)
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
{$ENDIF}

function doSurfaceConversion(tmpsurf: PSDL_Surface): PSDL_Surface;
{* for more information http://www.idevgames.com/forum/showpost.php?p=85864&postcount=7 *}
var convertedSurf: PSDL_Surface = nil;
begin
	if (tmpsurf^.format^.bitsperpixel = 24) or ((tmpsurf^.format^.bitsperpixel = 32) and (tmpsurf^.format^.rshift > tmpsurf^.format^.bshift)) then
	begin
		convertedSurf:= SDL_ConvertSurface(tmpsurf, @conversionFormat, SDL_SWSURFACE);
		SDL_FreeSurface(tmpsurf);
		doSurfaceConversion:= convertedSurf
	end
	else doSurfaceConversion:= tmpsurf;
end;


initialization
cDrownSpeed.QWordValue:= 257698038;// 0.06
cMaxWindSpeed.QWordValue:= 2147484;// 0.0005
cWindSpeed.QWordValue:= 429496;// 0.0001
cGravity:= cMaxWindSpeed;
cDamageModifier:= _1;
cLaserSighting:= false;
cVampiric:= false;
cArtillery:= false;

{$IFDEF DEBUGFILE}
{$I-}
for i:= 0 to 7 do
begin
	assign(f, 
{$IFDEF IPHONEOS}
	string(get_documents_path())
{$ELSE}
	ParamStr(1)
{$ENDIF}
	+ '/debug' + inttostr(i) + '.txt');
	rewrite(f);
	if IOResult = 5 then
	begin
		// prevent writing on a directory you do not have permissions on
		// should be safe to assume the current directory is writable
		assign(f, './debug' + inttostr(i) + '.txt');
		rewrite(f);
	end;
	if IOResult = 0 then break
end;
{$I+}

finalization
//uRandom.DumpBuffer;

writeln(f, 'halt at ', GameTicks, ' ticks. TurnTimeLeft = ', TurnTimeLeft);
flush(f);
close(f)

{$ENDIF}

end.
