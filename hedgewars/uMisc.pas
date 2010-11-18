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

uses    SDLh, uConsts, GLunit, uTypes;


procedure movecursor(dx, dy: LongInt);
(*
procedure AdjustColor(var Color: Longword);
procedure SetKB(n: Longword);
*)
procedure SendKB;
procedure SendStat(sit: TStatInfoType; s: shortstring);
function  NewTexture(width, height: Longword; buf: Pointer): PTexture;
function  Surface2Tex(surf: PSDL_Surface; enableClamp: boolean): PTexture;
procedure FreeTexture(tex: PTexture);
function  doSurfaceConversion(tmpsurf: PSDL_Surface): PSDL_Surface;
procedure OutError(Msg: shortstring; isFatalError: boolean);
procedure TryDo(Assert: boolean; Msg: shortstring; isFatal: boolean); inline;
procedure SDLTry(Assert: boolean; isFatal: boolean);
procedure MakeScreenshot(filename: shortstring);

procedure initModule;
procedure freeModule;

implementation
uses uConsole, uIO, typinfo, sysutils, uVariables, uUtils;

var KBnum: Longword;


procedure movecursor(dx, dy: LongInt);
var x, y: LongInt;
begin
if (dx = 0) and (dy = 0) then exit;

SDL_GetMouseState(@x, @y);
Inc(x, dx);
Inc(y, dy);
SDL_WarpMouse(x, y);
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

(*
procedure AdjustColor(var Color: Longword);
begin
Color:= SDL_MapRGB(PixelFormat, (Color shr 16) and $FF, (Color shr 8) and $FF, Color and $FF)
end;

procedure SetKB(n: Longword);
begin
KBnum:= n
end;
*)


procedure SetTextureParameters(enableClamp: Boolean);
begin
    if enableClamp and ((cReducedQuality and rqClampLess) = 0) then
    begin
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
    end;
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
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

procedure SendStat(sit: TStatInfoType; s: shortstring);
const stc: array [TStatInfoType] of char = 'rDkKHTPsSB';
var buf: shortstring;
begin
buf:= 'i' + stc[sit] + s;
SendIPCRaw(@buf[0], length(buf) + 1)
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
        fromP4:= @(fromP4^[Surf^.pitch div 4])
        end;

    for y:= Surf^.h to Pred(th) do
        begin
        for x:= 0 to Pred(tw) do toP4^[x]:= 0;
        toP4:= @(toP4^[tw])
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


procedure MakeScreenshot(filename: shortstring);
var p: Pointer;
    size: Longword;
    f: file;
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
begin
// flash
ScreenFade:= sfFromWhite;
ScreenFadeValue:= sfMax;
ScreenFadeSpeed:= 5;

size:= cScreenWidth * cScreenHeight * 3;
p:= GetMem(size);

// update header information and file name

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

//remember that opengles operates on a single surface, so GL_FRONT *should* be implied
//glReadBuffer(GL_FRONT);
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


procedure initModule;
begin
    KBnum           := 0;
end;

procedure freeModule;
begin
    recordFileName:= '';
    while TextureList <> nil do FreeTexture(TextureList);
end;

end.
