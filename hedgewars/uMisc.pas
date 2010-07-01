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
{$INLINE ON}

unit uMisc;
interface

uses    SDLh, uConsts, uFloat, GLunit, Math;

var
    isCursorVisible : boolean;
    isTerminated    : boolean;
    isInLag         : boolean;
    isPaused        : boolean;
    isSoundEnabled  : boolean;
    isMusicEnabled  : boolean;
    isSEBackup      : boolean;
    isInMultiShoot  : boolean;
    isSpeed         : boolean;
    isFirstFrame    : boolean;

    fastUntilLag    : boolean;

    GameState   : TGameState;
    GameType    : TGameType;
    GameFlags   : Longword;
    TrainingFlags   : Longword;
    TurnTimeLeft    : Longword;
    cSuddenDTurns   : LongInt;
    cDamagePercent  : LongInt;
    cMineDudPercent : LongWord;
    cTemplateFilter : LongInt;
    cMapGen         : LongInt;
    cMazeSize       : LongInt;

    cHedgehogTurnTime: Longword;
    cMinesTime       : LongInt;
    cMaxAIThinkTime  : Longword;

    cCloudsNumber    : LongInt;
    cScreenWidth     : LongInt;
    cScreenHeight    : LongInt;
    cInitWidth       : LongInt;
    cInitHeight      : LongInt;
    cVSyncInUse      : boolean;
    cBits            : LongInt;
    cBitsStr         : string[2];
    cTagsMask        : byte;
    zoom             : GLfloat;
    ZoomValue        : GLfloat;

    cWaterLine       : LongInt;
    cGearScrEdgesDist: LongInt;
    cAltDamage       : boolean;

    GameTicks   : LongWord;
    TrainingTimeInc : Longword;
    TrainingTimeInD : Longword;
    TrainingTimeInM : Longword;
    TrainingTimeMax : Longword;

    TimeTrialStartTime: Longword;
    TimeTrialStopTime : Longword;
    
    recordFileName  : shortstring;
    cShowFPS    : boolean;
    cCaseFactor : Longword;
    cLandAdditions  : Longword;
    cExplosives : Longword;
    cFullScreen : boolean;
    cReducedQuality : LongInt;
    cLocaleFName    : shortstring;
    cSeed       : shortstring;
    cInitVolume : LongInt;
    cVolumeDelta    : LongInt;
    cTimerInterval  : Longword;
    cHasFocus   : boolean;
    cInactDelay : Longword;

    bBetweenTurns   : boolean;
    cHealthDecrease : LongWord;
    bWaterRising    : Boolean;

    ShowCrosshair   : boolean;
    CursorMovementX : LongInt;
    CursorMovementY : LongInt;
    cDrownSpeed : hwFloat;
    cDrownSpeedf : float;
    cMaxWindSpeed   : hwFloat;
    cWindSpeed  : hwFloat;
    cWindSpeedf  : float;
    cGravity    : hwFloat;
    cGravityf    : float;
    cDamageModifier : hwFloat;
    cLaserSighting  : boolean;
    cVampiric   : boolean;
    cArtillery  : boolean;
    WeaponTooltipTex : PTexture;
    cWeaponTooltips: boolean;

    flagMakeCapture : boolean;

    InitStepsFlags  : Longword;
    RealTicks   : Longword;
    AttackBar   : LongInt;

    WaterColorArray : array[0..3] of HwColor4f;

    CursorPoint : TPoint;
    TargetPoint : TPoint;

    TextureList : PTexture;

    ScreenFade : TScreenFade;
    ScreenFadeValue : LongInt;
    ScreenFadeSpeed : LongInt;

{$IFDEF SDL13}
    SDLwindow: PSDL_Window;
{$ENDIF}

procedure initModule;
procedure freeModule;
procedure SplitBySpace(var a, b: shortstring);
procedure SplitByChar(var a, b: ansistring; c: char);
function EnumToStr(const en : TGearType) : shortstring; overload;
function EnumToStr(const en : TSound) : shortstring; overload;
function EnumToStr(const en : TAmmoType) : shortstring; overload;
procedure movecursor(dx, dy: LongInt);
function  hwSign(r: hwFloat): LongInt;
function  Min(a, b: LongInt): LongInt;
function  Max(a, b: LongInt): LongInt;
procedure OutError(Msg: shortstring; isFatalError: boolean);
procedure TryDo(Assert: boolean; Msg: shortstring; isFatal: boolean); inline;
procedure SDLTry(Assert: boolean; isFatal: boolean);
function  IntToStr(n: LongInt): shortstring;
function  FloatToStr(n: hwFloat): shortstring;
function  DxDy2Angle(const _dY, _dX: hwFloat): GLfloat;
function  DxDy2Angle32(const _dY, _dX: hwFloat): LongInt;
function  DxDy2AttackAngle(const _dY, _dX: hwFloat): LongInt;
procedure AdjustColor(var Color: Longword);
procedure SetKB(n: Longword);
procedure SendKB;
procedure SetLittle(var r: hwFloat);
procedure SendStat(sit: TStatInfoType; s: shortstring);
function  Str2PChar(const s: shortstring): PChar;
function  NewTexture(width, height: Longword; buf: Pointer): PTexture;
function  Surface2Tex(surf: PSDL_Surface; enableClamp: boolean): PTexture;
procedure FreeTexture(tex: PTexture);
function  toPowerOf2(i: Longword): Longword; inline;
function  DecodeBase64(s: shortstring): shortstring;
function  doSurfaceConversion(tmpsurf: PSDL_Surface): PSDL_Surface;
function  endian(independent: LongWord): LongWord;
{$IFDEF DEBUGFILE}
procedure AddFileLog(s: shortstring);
function  RectToStr(Rect: TSDL_Rect): shortstring;
{$ENDIF}
{$IFNDEF IPHONEOS}
procedure MakeScreenshot(filename: shortstring);
{$ENDIF}

implementation
uses uConsole, uStore, uIO, uSound, typinfo, sysutils;

var KBnum: Longword;
{$IFDEF DEBUGFILE}
    f: textfile;
{$ENDIF}

// should this include "strtolower()" for the split string?
procedure SplitBySpace(var a, b: shortstring);
var i, t: LongInt;
begin
i:= Pos(' ', a);
if i > 0 then
    begin
    for t:= 1 to Pred(i) do
        if (a[t] >= 'A')and(a[t] <= 'Z') then Inc(a[t], 32);
    b:= copy(a, i + 1, Length(a) - i);
    byte(a[0]):= Pred(i)
    end else b:= '';
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

function EnumToStr(const en : TGearType) : shortstring; overload;
begin
EnumToStr:= GetEnumName(TypeInfo(TGearType), ord(en))
end;

function EnumToStr(const en : TSound) : shortstring; overload;
begin
EnumToStr:= GetEnumName(TypeInfo(TSound), ord(en))
end;

function EnumToStr(const en : TAmmoType) : shortstring; overload;
begin
EnumToStr:= GetEnumName(TypeInfo(TAmmoType), ord(en))
end;

procedure movecursor(dx, dy: LongInt);
var x, y: LongInt;
begin
if (dx = 0) and (dy = 0) then exit;

SDL_GetMouseState(@x, @y);
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

procedure OutError(Msg: shortstring; isFatalError: boolean);
begin
// obsolete? written in WriteLnToConsole() anyway
// {$IFDEF DEBUGFILE}AddFileLog(Msg);{$ENDIF}
WriteLnToConsole(Msg);
if isFatalError then
    begin
    SendIPC('E' + GetLastConsoleLine);
    SDL_Quit;
    halt(1)
    end
end;

procedure TryDo(Assert: boolean; Msg: shortstring; isFatal: boolean);
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
    //if enableClamp and not cReducedQuality then
    if enableClamp and ((cReducedQuality and rqNoBackground) = 0) then
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
const stc: array [TStatInfoType] of char = 'rDkKHT';
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
NewTexture^.PrevTexture:= nil;
NewTexture^.NextTexture:= nil;
NewTexture^.Scale:= 1;
if TextureList <> nil then
    begin
    TextureList^.PrevTexture:= NewTexture;
    NewTexture^.NextTexture:= TextureList
    end;
TextureList:= NewTexture;

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
Surface2Tex^.PrevTexture:= nil;
Surface2Tex^.NextTexture:= nil;
if TextureList <> nil then
    begin
    TextureList^.PrevTexture:= Surface2Tex;
    Surface2Tex^.NextTexture:= TextureList
    end;
TextureList:= Surface2Tex;

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
        if tex^.NextTexture <> nil then 
            tex^.NextTexture^.PrevTexture:= tex^.PrevTexture;
        if tex^.PrevTexture <> nil then 
            tex^.PrevTexture^.NextTexture:= tex^.NextTexture
        else 
            TextureList:= tex^.NextTexture;
        glDeleteTextures(1, @tex^.id);
        Dispose(tex);
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
procedure MakeScreenshot(filename: shortstring);
var p: Pointer;
    size: Longword;
    f: file;
{$IFNDEF WIN32}
    // TGA Header
    head: array[0..8] of Word = (0, 2, 0, 0, 0, 0, 0, 0, 24);
{$ELSE}
    // Windows Bitmap Header
    head: array[0..53] of Byte = (
    $42, $4D, // identifier ("BM")
    0, 0, 0, 0, // file size
    0, 0, 0, 0, // reserved
    54, 0, 0, 0, // starting offset
    40, 0, 0, 0, // header size
    0, 0, 0, 0, // width
    0, 0, 0, 0, // height
    1, 0, // color planes
    24, 0, // bit depth
    0, 0, 0, 0, // compression method (uncompressed)
    0, 0, 0, 0, // image size
    96, 0, 0, 0, // horizontal resolution
    96, 0, 0, 0, // vertical resolution
    0, 0, 0, 0, // number of colors (all)
    0, 0, 0, 0 // number of important colors
    );
{$ENDIF}
begin
playSound(sndShutter);

// flash
ScreenFade:= sfFromWhite;
ScreenFadeValue:= sfMax;
ScreenFadeSpeed:= 5;

size:= cScreenWidth * cScreenHeight * 3;
p:= GetMem(size);

// update header information and file name
{$IFNDEF WIN32}
filename:= ParamStr(1) + '/Screenshots/' + filename + '.tga';

head[6]:= cScreenWidth;
head[7]:= cScreenHeight;
{$ELSE}
filename:= ParamStr(1) + '/Screenshots/' + filename + '.bmp';

head[$02]:= (size + 54) and $ff;
head[$03]:= ((size + 54) shr 8) and $ff;
head[$04]:= ((size + 54) shr 16) and $ff;
head[$05]:= ((size + 54) shr 24) and $ff;
head[$12]:= cScreenWidth and $ff;
head[$13]:= (cScreenWidth shr 8) and $ff;
head[$14]:= (cScreenWidth shr 16) and $ff;
head[$15]:= (cScreenWidth shr 24) and $ff;
head[$16]:= cScreenHeight and $ff;
head[$17]:= (cScreenHeight shr 8) and $ff;
head[$18]:= (cScreenHeight shr 16) and $ff;
head[$19]:= (cScreenHeight shr 24) and $ff;
head[$22]:= size and $ff;
head[$23]:= (size shr 8) and $ff;
head[$24]:= (size shr 16) and $ff;
head[$25]:= (size shr 24) and $ff;
{$ENDIF}

//remember that opengles operates on a single surface, so GL_FRONT *should* be implied
glReadBuffer(GL_FRONT);
glReadPixels(0, 0, cScreenWidth, cScreenHeight, GL_BGR, GL_UNSIGNED_BYTE, p);

{$I-}
Assign(f, filename);
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
        exit(convertedSurf);
    end;

    exit(tmpsurf);
end;

function endian(independent: LongWord): LongWord;
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


procedure initModule;
{$IFDEF DEBUGFILE}{$IFNDEF IPHONEOS}var i: LongInt;{$ENDIF}{$ENDIF}
begin
    cDrownSpeed.QWordValue  := 257698038;       // 0.06
    cDrownSpeedf            := 0.06;
    cMaxWindSpeed.QWordValue:= 1073742;     // 0.00025
    cWindSpeed.QWordValue   := 429496;      // 0.0001
    cWindSpeedf             := 0.0001;
    cGravity                := cMaxWindSpeed * 2;
    cGravityf               := 0.00025 * 2;
    cDamageModifier         := _1;
    TargetPoint             := cTargetPointRef;
    TextureList             := nil;
    
    // int, longint longword and byte
    CursorMovementX     := 0;
    CursorMovementY     := 0;
    GameTicks           := 0;
    TrainingTimeInc     := 10000;
    TrainingTimeInD     := 500;
    TrainingTimeInM     := 5000;
    TrainingTimeMax     := 60000;
    TimeTrialStartTime  := 0;
    TimeTrialStopTime   := 0;
    cWaterLine          := LAND_HEIGHT;
    cGearScrEdgesDist   := 240;
    cHealthDecrease     := 0;

    GameFlags           := 0;
    TrainingFlags       := 0;
    TurnTimeLeft        := 0;
    cSuddenDTurns       := 15;
    cDamagePercent      := 100;
    cMineDudPercent     := 0;
    cTemplateFilter     := 0;
    cMapGen             := 0;//MAPGEN_REGULAR
    cMazeSize           := 0;

    cHedgehogTurnTime   := 45000;
    cMinesTime          := 3000;
    cMaxAIThinkTime     := 9000;

    cCloudsNumber       := 9;
    cScreenWidth        := 1024;
    cScreenHeight       := 768;
    cInitWidth      := cScreenWidth;
    cInitHeight     := cScreenHeight;
    cBits           := 32;
    cTagsMask       := 0;
    KBnum           := 0;
    InitStepsFlags  := 0;
    RealTicks       := 0;
    AttackBar       := 0; // 0 - none, 1 - just bar at the right-down corner, 2 - like in WWP
    
    // tgametype and glfloat and string
    GameState       := Low(TGameState);
    GameType        := gmtLocal;
    zoom            := 2.0;
    ZoomValue       := 2.0;
    cBitsStr        := '32';
    WeaponTooltipTex:= nil;

    // booleans
    cLaserSighting  := false;
    cVampiric       := false;
    cArtillery      := false;
    flagMakeCapture := false;
    bBetweenTurns   := false;
    bWaterRising    := false;
    isCursorVisible := false;
    isTerminated    := false;
    isInLag         := false;
    isPaused        := false;
    isMusicEnabled  := false;
    isInMultiShoot  := false;
    isSpeed         := false;
    fastUntilLag    := false;
    isFirstFrame    := true;
    cVSyncInUse     := true;    
    isSoundEnabled  := true;
    isSEBackup      := true;
    
    // init flags
    recordFileName  := '';
    cShowFPS        := false;
    cCaseFactor     := 5;  {0..9}
    cLandAdditions  := 4;
    cExplosives     := 2;
    cFullScreen     := false;
    cReducedQuality := 0;
    cLocaleFName    := 'en.txt';
    cSeed           := '';
    cInitVolume     := 50;
    cVolumeDelta    := 0;
    cTimerInterval  := 8;
    cHasFocus       := true;
    cInactDelay     := 1250;
    cAltDamage      := true;

    ScreenFade      := sfNone;
    
{$IFDEF SDL13}
    SDLwindow       := nil;
{$ENDIF}    
{$IFDEF DEBUGFILE}
{$I-}
{$IFDEF IPHONEOS}
    Assign(f,'../Documents/debug.txt');
    Rewrite(f);
{$ELSE}
    if (ParamStr(1) <> '') and (ParamStr(2) <> '') then
        if (ParamCount <> 3) and (ParamCount <> 18) then
        begin
            for i:= 0 to 7 do
            begin
                assign(f, ExtractFileDir(ParamStr(2)) + '/debug' + inttostr(i) + '.txt');
                rewrite(f);
                if IOResult = 0 then break;
            end;
            if IOResult <> 0 then f:= stderr; // if everything fails, write to stderr
        end
        else
        begin
            for i:= 0 to 7 do
            begin
                assign(f, ParamStr(1) + '/debug' + inttostr(i) + '.txt');
                rewrite(f);
                if IOResult = 0 then break;
            end;
            if IOResult <> 0 then f:= stderr; // if everything fails, write to stderr
        end
    else
        f:= stderr;
{$ENDIF}
{$I+}
{$ENDIF}

end;

procedure freeModule;
begin
    //uRandom.DumpBuffer;
    while TextureList <> nil do FreeTexture(TextureList);

{$IFDEF DEBUGFILE}
    writeln(f, 'halt at ', GameTicks, ' ticks. TurnTimeLeft = ', TurnTimeLeft);
    flush(f);
    close(f);
{$ENDIF}
end;

end.
