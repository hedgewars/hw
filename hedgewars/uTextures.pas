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

unit uTextures;
interface
uses SDLh, uTypes;

function  NewTexture(width, height: Longword; buf: Pointer): PTexture;
procedure Surface2GrayScale(surf: PSDL_Surface);
function  Surface2Tex(surf: PSDL_Surface; enableClamp: boolean): PTexture;
procedure FreeTexture(tex: PTexture);

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
    fromP4:= @(fromP4^[Surf^.pitch div 4])
    end;
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

fromP4:= Surf^.pixels;

if cGrayScale then
    Surface2GrayScale(Surf);

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
        for x:= 0 to Pred(Surf^.w) do
            toP4^[x]:= fromP4^[x];
        for x:= Surf^.w to Pred(tw) do
            toP4^[x]:= 0;
        toP4:= @(toP4^[tw]);
        fromP4:= @(fromP4^[Surf^.pitch div 4])
        end;

    for y:= Surf^.h to Pred(th) do
        begin
        for x:= 0 to Pred(tw) do
            toP4^[x]:= 0;
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

// deletes texture and frees the memory allocated for it.
// if nil is passed nothing is done
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

procedure initModule;
begin
TextureList:= nil;
end;

procedure freeModule;
begin
if TextureList <> nil then
    WriteToConsole('FIXME FIXME FIXME. App shutdown without full cleanup of texture list; read game0.log and please report this problem');
    while TextureList <> nil do 
        begin
        AddFileLog('Texture not freed: width='+inttostr(LongInt(TextureList^.w))+' height='+inttostr(LongInt(TextureList^.h))+' priority='+inttostr(round(TextureList^.priority*1000)));
        FreeTexture(TextureList);
        end
end;

end.
