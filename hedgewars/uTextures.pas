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
function  Surface2Atlas(surf: PSDL_Surface; enableClamp: boolean): PTexture;
procedure FreeTexture(tex: PTexture);
procedure ComputeTexcoords(texture: PTexture; r: PSDL_Rect; tb: PVertexRect);

procedure initModule;
procedure freeModule;

implementation
uses GLunit, uUtils, uVariables, uConsts, uDebug, uConsole, uAtlas;

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

procedure ComputeTexcoords(texture: PTexture; r: PSDL_Rect; tb: PVertexRect);
var x0, y0, x1, y1: Real;
    w, h, aw, ah: LongInt;
const texelOffset = 0.0;
begin
aw:=texture^.atlas^.w;
ah:=texture^.atlas^.h;
if texture^.isRotated then
    begin
    w:=r^.h;
    h:=r^.w;
    end 
else
    begin
    w:=r^.w;
    h:=r^.h;        
    end;

x0:= (r^.x +     texelOffset)/aw;
x1:= (r^.x + w - texelOffset)/aw;
y0:= (r^.y +     texelOffset)/ah;
y1:= (r^.y + h - texelOffset)/ah;

tb^[0].X:= x0;
tb^[0].Y:= y0;
tb^[1].X:= x1;
tb^[1].Y:= y0;
tb^[2].X:= x1;
tb^[2].Y:= y1;
tb^[3].X:= x0;
tb^[3].Y:= y1
end;

procedure ResetVertexArrays(texture: PTexture);
var r: TSDL_Rect;
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
end;

r.x:= 0;
r.y:= 0;
r.w:= texture^.w;
r.h:= texture^.h;
ComputeTexcoords(texture, @r, @texture^.tb);
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


// Atlas allocation happens here later on. For now we just allocate one exclusive atlas per sprite
new(NewTexture^.atlas);
NewTexture^.atlas^.w:=width;
NewTexture^.atlas^.h:=height;
NewTexture^.x:=0;
NewTexture^.y:=0;
NewTexture^.w:=width;
NewTexture^.h:=height;
NewTexture^.isRotated:=false;

ResetVertexArrays(NewTexture);

glGenTextures(1, @NewTexture^.atlas^.id);

glBindTexture(GL_TEXTURE_2D, NewTexture^.atlas^.id);
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


function Surface2Atlas(surf: PSDL_Surface; enableClamp: boolean): PTexture;
var tw, th, x, y: Longword;
    tmpp: pointer;
    fromP4, toP4: PLongWordArray;
begin
    if (surf^.w <= 128) and (surf^.h <= 128) then
        Surface2Tex_(surf, enableClamp); // run the atlas side by side for debugging
new(Surface2Atlas);
Surface2Atlas^.PrevTexture:= nil;
Surface2Atlas^.NextTexture:= nil;
if TextureList <> nil then
    begin
    TextureList^.PrevTexture:= Surface2Atlas;
    Surface2Atlas^.NextTexture:= TextureList
    end;
TextureList:= Surface2Atlas;

// Atlas allocation happens here later on. For now we just allocate one exclusive atlas per sprite
new(Surface2Atlas^.atlas);

Surface2Atlas^.w:= surf^.w;
Surface2Atlas^.h:= surf^.h;
Surface2Atlas^.x:=0;
Surface2Atlas^.y:=0;
Surface2Atlas^.isRotated:=false;
Surface2Atlas^.surface:= surf;


if (surf^.format^.BytesPerPixel <> 4) then
    begin
    TryDo(false, 'Surface2Tex failed, expecting 32 bit surface', true);
    Surface2Atlas^.atlas^.id:= 0;
    exit
    end;


glGenTextures(1, @Surface2Atlas^.atlas^.id);

glBindTexture(GL_TEXTURE_2D, Surface2Atlas^.atlas^.id);

if SDL_MustLock(surf) then
    SDLTry(SDL_LockSurface(surf) >= 0, true);

fromP4:= Surf^.pixels;

if GrayScale then
    Surface2GrayScale(Surf);

if (not SupportNPOTT) and (not (isPowerOf2(Surf^.w) and isPowerOf2(Surf^.h))) then
    begin
    tw:= toPowerOf2(Surf^.w);
    th:= toPowerOf2(Surf^.h);

    Surface2Atlas^.atlas^.w:=tw;
    Surface2Atlas^.atlas^.h:=th;

    tmpp:= GetMem(tw * th * surf^.format^.BytesPerPixel);

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
    Surface2Atlas^.atlas^.w:=Surf^.w;
    Surface2Atlas^.atlas^.h:=Surf^.h;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, surf^.w, surf^.h, 0, GL_RGBA, GL_UNSIGNED_BYTE, surf^.pixels);
    end;

ResetVertexArrays(Surface2Atlas);

if SDL_MustLock(surf) then
    SDL_UnlockSurface(surf);

SetTextureParameters(enableClamp);

    {$IFNDEF RETAIN_SURFACES}
    SDL_FreeSurface(surf);
    {$ENDIF}
end;

// deletes texture and frees the memory allocated for it.
// if nil is passed nothing is done
procedure FreeTexture(tex: PTexture);
begin
    FreeTexture_(tex); // run atlas side by side for debugging
if tex <> nil then
    begin
    // Atlas cleanup happens here later on. For now we just free as each sprite has one atlas
    Dispose(tex^.atlas);

    if tex^.NextTexture <> nil then
        tex^.NextTexture^.PrevTexture:= tex^.PrevTexture;
    if tex^.PrevTexture <> nil then
        tex^.PrevTexture^.NextTexture:= tex^.NextTexture
    else
        TextureList:= tex^.NextTexture;
    glDeleteTextures(1, @tex^.atlas^.id);

    {$IFDEF RETAIN_SURFACES}
    SDL_FreeSurface(tex^.surface);
    {$ENDIF}

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
        AddFileLog('Sprite not freed: width='+inttostr(LongInt(TextureList^.w))+' height='+inttostr(LongInt(TextureList^.h))+' priority='+inttostr(round(TextureList^.atlas^.priority*1000)));
        FreeTexture(TextureList);
        end
end;

end.
