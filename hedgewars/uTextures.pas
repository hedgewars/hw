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

unit uTextures;
interface
uses SDLh, uTypes;

function  NewTexture(width, height: Longword; buf: Pointer): PTexture;
procedure Surface2GrayScale(surf: PSDL_Surface);
function  Surface2Tex(surf: PSDL_Surface; enableClamp: boolean): PTexture;
procedure PrettifySurfaceAlpha(surf: PSDL_Surface; pixels: PLongwordArray);
procedure PrettifyAlpha2D(pixels: TLandArray; height, width: LongWord);
procedure FreeAndNilTexture(var tex: PTexture);

procedure initModule;
procedure freeModule;

implementation
uses GLunit, uUtils, uVariables, uConsts, uDebug, uConsole;

var TextureList: PTexture;


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

procedure Surface2GrayScale(surf: PSDL_Surface);
var tw, x, y: Longword;
    fromP4: PLongWordArray;
begin
fromP4:= Surf^.pixels;
for y:= 0 to Pred(Surf^.h) do
    begin
    for x:= 0 to Pred(Surf^.w) do
        begin
        tw:= fromP4^[x];
        tw:= round((tw shr RShift and $FF) * RGB_LUMINANCE_RED +
              (tw shr GShift and $FF) * RGB_LUMINANCE_GREEN +
              (tw shr BShift and $FF) * RGB_LUMINANCE_BLUE);
        if tw > 255 then tw:= 255;
        tw:= (tw and $FF shl RShift) or (tw and $FF shl BShift) or (tw and $FF shl GShift) or (fromP4^[x] and AMask);
        fromP4^[x]:= tw;
        end;
    fromP4:= PLongWordArray(@(fromP4^[Surf^.pitch div 4]))
    end;
end;

{ this will make invisible pixels that have a visible neighbor have the
  same color as their visible neighbor, so that bilinear filtering won't
  display a "wrongly" colored border when zoomed in }
procedure PrettifyAlpha(row1, row2: PLongwordArray; firsti, lasti, ioffset: LongWord);
var
    i: Longword;
    lpi, cpi, bpi: boolean; // was last/current/bottom neighbor pixel invisible?
begin
    // suppress incorrect warning
    lpi:= true;
    for i:=firsti to lasti do
        begin
        // use first pixel in row1 as starting point
        if i = firsti then
            cpi:= ((row1^[i] and AMask) = 0)
        else
            begin
            cpi:= ((row1^[i] and AMask) = 0);
            if cpi <> lpi then
                begin
                // invisible pixels get colors from visible neighbors
                if cpi then
                    begin
                    row1^[i]:= row1^[i-1] and (not AMask);
                    // as this pixel is invisible and already colored correctly now, no point in further comparing it
                    lpi:= cpi;
                    continue;
                    end
                else
                    row1^[i-1]:= row1^[i] and (not AMask);
                end;
            end;
        lpi:= cpi;
        // also check bottom neighbor
        if row2 <> nil then
            begin
            bpi:= ((row2^[i+ioffset] and AMask) = 0);
            if cpi <> bpi then
                begin
                if cpi then
                    row1^[i]:= row2^[i+ioffset] and (not AMask)
                else
                    row2^[i+ioffset]:= row1^[i] and (not AMask);
                end;
            end;
        end;
end;

procedure PrettifySurfaceAlpha(surf: PSDL_Surface; pixels: PLongwordArray);
var
    // current row index, second last row index of array, width and first/last i of row
    r, slr, w, si, li: LongWord;
begin
    w:= surf^.w;
    // just a single pixel, nothing to do here
    if (w < 2) and (surf^.h < 2) then
        exit;
    slr:= surf^.h - 2;
    si:= 0;
    li:= w - 1;
    for r:= 0 to slr do
        begin
        PrettifyAlpha(pixels, pixels, si, li, w);
        // move indices to next row
        si:= si + w;
        li:= li + w;
        end;
    // don't forget last row
    PrettifyAlpha(pixels, nil, si, li, w);
end;

procedure PrettifyAlpha2D(pixels: TLandArray; height, width: LongWord);
var
    // current y; last x, second last y of array;
    y, lx, sly: LongWord;
begin
    sly:= height - 2;
    lx:= width - 1;
    for y:= 0 to sly do
        begin
        PrettifyAlpha(PLongWordArray(pixels[y]), PLongWordArray(pixels[y+1]), 0, lx, 0);
        end;
    // don't forget last row
    PrettifyAlpha(PLongWordArray(pixels[sly+1]), nil, 0, lx, 0);
end;

function Surface2Tex(surf: PSDL_Surface; enableClamp: boolean): PTexture;
var tw, th, x, y: Longword;
    tmpp: pointer;
    fromP4, toP4: PLongWordArray;
begin
if cOnlyStats then exit(nil);
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
    checkFails(false, 'Surface2Tex failed, expecting 32 bit surface', true);
    Surface2Tex^.id:= 0;
    exit
    end;

glGenTextures(1, @Surface2Tex^.id);

glBindTexture(GL_TEXTURE_2D, Surface2Tex^.id);

if SDL_MustLock(surf) then
    if SDLCheck(SDL_LockSurface(surf) >= 0, 'Lock surface', true) then
        exit(nil);

fromP4:= Surf^.pixels;

if GrayScale then
    Surface2GrayScale(Surf);

PrettifySurfaceAlpha(surf, fromP4);

if (not SupportNPOTT) and (not (isPowerOf2(Surf^.w) and isPowerOf2(Surf^.h))) then
    begin
    tw:= toPowerOf2(Surf^.w);
    th:= toPowerOf2(Surf^.h);

    Surface2Tex^.rx:= Surf^.w / tw;
    Surface2Tex^.ry:= Surf^.h / th;

    tmpp:= GetMem(tw * th * surf^.format^.BytesPerPixel);

    fromP4:= Surf^.pixels;
    toP4:= tmpp;

    for y:= 0 to Pred(Surf^.h) do
        begin
        for x:= 0 to Pred(Surf^.w) do
            toP4^[x]:= fromP4^[x];
        for x:= Surf^.w to Pred(tw) do
            toP4^[x]:= fromP4^[0];
        toP4:= PLongWordArray(@(toP4^[tw]));
        fromP4:= PLongWordArray(@(fromP4^[Surf^.pitch div 4]))
        end;

    for y:= Surf^.h to Pred(th) do
        begin
        for x:= 0 to Pred(tw) do
            toP4^[x]:= 0;
        toP4:= PLongWordArray(@(toP4^[tw]))
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

// deletes texture and frees the memory allocated for it.
// if nil is passed nothing is done
procedure FreeAndNilTexture(var tex: PTexture);
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
        tex:= nil;
        end;
end;

procedure initModule;
begin
TextureList:= nil;
end;

procedure freeModule;
var tex: PTexture;
begin
if TextureList <> nil then
    WriteToConsole('FIXME FIXME FIXME. App shutdown without full cleanup of texture list; read game0.log and please report this problem');
    while TextureList <> nil do
        begin
        tex:= TextureList;
        AddFileLog('Texture not freed: width='+inttostr(LongInt(tex^.w))+' height='+inttostr(LongInt(tex^.h))+' priority='+inttostr(round(tex^.priority*1000)));
        FreeAndNilTexture(tex);
        end
end;

end.
