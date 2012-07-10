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
function SurfaceSheet2Atlas(surf: PSDL_Surface; spriteWidth: Integer; spriteHeight: Integer): PTexture;
function  Surface2Atlas(surf: PSDL_Surface; enableClamp: boolean): PTexture;
procedure FreeTexture(tex: PTexture);
procedure ComputeTexcoords(texture: PTexture; r: PSDL_Rect; tb: PVertexRect);

procedure initModule;
procedure freeModule;

implementation
uses GLunit, uUtils, uVariables, uConsts, uDebug, uConsole, uAtlas, SysUtils;

var
  logFile: TextFile;

function CropSurface(source: PSDL_Surface; rect: PSDL_Rect): PSDL_Surface;
var
    fmt: PSDL_PixelFormat;
    srcP, dstP: PByte;
    copySize: Integer;
    i: Integer;
const
    pixelSize = 4;
begin
    //writeln(stdout, 'Cropping from ' + IntToStr(source^.w) + 'x' + IntToStr(source^.h) + ' -> ' + IntToStr(rect^.w) + 'x' + IntToStr(rect^.h));

    fmt:= source^.format;

    CropSurface:= SDL_CreateRGBSurface(source^.flags, rect^.w, rect^.h, 
        fmt^.BitsPerPixel, fmt^.Rmask, fmt^.Gmask, fmt^.Bmask, fmt^.Amask);

    if SDL_MustLock(source) then
        SDLTry(SDL_LockSurface(source) >= 0, true);
    if SDL_MustLock(CropSurface) then
        SDLTry(SDL_LockSurface(CropSurface) >= 0, true);

    srcP:= source^.pixels;
    dstP:= CropSurface^.pixels;

    inc(srcP, pixelSize * rect^.x);
    inc(srcP, source^.pitch * rect^.y);
    copySize:= rect^.w * pixelSize;
    for i:= 0 to Pred(rect^.h) do
    begin
        Move(srcP^, dstP^, copySize);
        inc(srcP, source^.pitch);
        inc(dstP, CropSurface^.pitch);
    end;

    if SDL_MustLock(source) then
        SDL_UnlockSurface(source);
    if SDL_MustLock(CropSurface) then
        SDL_UnlockSurface(CropSurface);
end;

function TransparentLine(p: PByte; stride: Integer; length: Integer): boolean;
var
    i: Integer;
begin
    TransparentLine:= false;
    for i:=0 to pred(length) do
    begin
        if p^ <> 0 then
            exit;
        inc(p, stride);
    end;
    TransparentLine:= true;
end;

function AutoCrop(source: PSDL_Surface; var cropinfo: TCropInformation): PSDL_Surface;
var
    l,r,t,b, i: Integer;
    pixels, p: PByte;
    scanlineSize: Integer;
    rect: TSDL_Rect;
const
    pixelSize = 4;
begin
    l:= source^.w; 
    r:= 0; 
    t:= source^.h;
    b:= 0;

    if SDL_MustLock(source) then
        SDLTry(SDL_LockSurface(source) >= 0, true);

    pixels:= source^.pixels;
    scanlineSize:= source^.pitch;

    inc(pixels, 3); // advance to alpha value

    // check top
    p:= pixels;
    for i:= 0 to Pred(source^.h) do
    begin
        if not TransparentLine(p, pixelSize, source^.w) then
        begin
            t:= i;
            break;
        end;
        inc(p, scanlineSize);
    end;


    // check bottom
    p:= pixels;
    inc(p, scanlineSize * source^.h);
    for i:= 0 to Pred(source^.h - t) do
    begin
        dec(p, scanlineSize);
        if not TransparentLine(p, pixelSize, source^.w) then
        begin
            b:= i;
            break;
        end;
    end;

    // check left
    p:= pixels;
    for i:= 0 to Pred(source^.w) do
    begin
        if not TransparentLine(p, scanlineSize, source^.h) then
        begin
            l:= i;
            break;
        end;
        inc(p, pixelSize);
    end;

    // check right
    p:= pixels;
    inc(p, scanlineSize);
    for i:= 0 to Pred(source^.w - l) do
    begin
        dec(p, pixelSize);
        if not TransparentLine(p, scanlineSize, source^.h) then
        begin
            r:= i;
            break;
        end;
    end;

    if SDL_MustLock(source) then
        SDL_UnlockSurface(source);

    rect.x:= l;
    rect.y:= t;

    rect.w:= source^.w - r - l;    
    rect.h:= source^.h - b - t;

    cropInfo.l:= l;
    cropInfo.r:= r;
    cropInfo.t:= t;
    cropInfo.b:= b;
    cropInfo.x:= Trunc(source^.w / 2 - l + r);
    cropInfo.y:= Trunc(source^.h / 2 - t + b);

    if (l = source^.w) or (t = source^.h) then
    begin
        result:= nil;
        exit;
    end;

    if (l <> 0) or (r <> 0) or (t <> 0) or (b <> 0) then
        result:= CropSurface(source, @rect)
    else result:= source;
end;

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
var 
    x0, y0, x1, y1, tmp: Real;
    w, h, aw, ah: LongInt;
    p: PChar;
const 
    texelOffsetPos = 0.5;
    texelOffsetNeg = 0.0;
begin
    aw:=texture^.atlas^.w;
    ah:=texture^.atlas^.h;

    if texture^.isRotated then
    begin
        w:=r^.h;
        h:=r^.w;
    end else
    begin
        w:=r^.w;
        h:=r^.h;        
    end;

    x0:= (texture^.x + {r^.x} +     texelOffsetPos)/aw;
    x1:= (texture^.x + {r^.x} + w + texelOffsetNeg)/aw;
    y0:= (texture^.y + {r^.y} +     texelOffsetPos)/ah;
    y1:= (texture^.y + {r^.y} + h + texelOffsetNeg)/ah;

    if (texture^.isRotated) then
    begin
        tb^[0].X:= x0;
        tb^[0].Y:= y0;
        tb^[3].X:= x1;
        tb^[3].Y:= y0;
        tb^[2].X:= x1;
        tb^[2].Y:= y1;
        tb^[1].X:= x0;
        tb^[1].Y:= y1
    end else
    begin
        tb^[0].X:= x0;
        tb^[0].Y:= y0;
        tb^[1].X:= x1;
        tb^[1].Y:= y0;
        tb^[2].X:= x1;
        tb^[2].Y:= y1;
        tb^[3].X:= x0;
        tb^[3].Y:= y1;
    end;
end;

procedure ResetVertexArrays(texture: PTexture);
var 
    rect: TSDL_Rect;
    l, t, r, b: Real;
const
    halfTexelOffsetPos = 1.0;
    halfTexelOffsetNeg = -0.0;
begin
    l:= texture^.cropInfo.l + halfTexelOffsetPos;
    r:= texture^.cropInfo.l + texture^.w + halfTexelOffsetNeg;
    t:= texture^.cropInfo.t + halfTexelOffsetPos;
    b:= texture^.cropInfo.t + texture^.h + halfTexelOffsetNeg;

    with texture^ do
    begin
        vb[0].X:= l;
        vb[0].Y:= t;
        vb[1].X:= r;
        vb[1].Y:= t;
        vb[2].X:= r;
        vb[2].Y:= b;
        vb[3].X:= l;
        vb[3].Y:= b;
    end;

    rect.x:= 0;
    rect.y:= 0;
    rect.w:= texture^.w;
    rect.h:= texture^.h;
    ComputeTexcoords(texture, @rect, @texture^.tb);
end;

function NewTexture(width, height: Longword; buf: Pointer): PTexture;
begin
new(NewTexture);
NewTexture^.Scale:= 1;

// Atlas allocation happens here later on. For now we just allocate one exclusive atlas per sprite
new(NewTexture^.atlas);
NewTexture^.atlas^.w:=width;
NewTexture^.atlas^.h:=height;
NewTexture^.x:=0;
NewTexture^.y:=0;
NewTexture^.w:=width;
NewTexture^.h:=height;
NewTexture^.isRotated:=false;
NewTexture^.shared:=false;
NewTexture^.surface:=nil;
NewTexture^.nextFrame:=nil;
NewTexture^.cropInfo.l:= 0;
NewTexture^.cropInfo.r:= 0;
NewTexture^.cropInfo.t:= 0;
NewTexture^.cropInfo.b:= 0;
NewTexture^.cropInfo.x:= width div 2;
NewTexture^.cropInfo.y:= height div 2;


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


function SurfaceSheet2Atlas(surf: PSDL_Surface; spriteWidth: Integer; spriteHeight: Integer): PTexture;
var
    subSurface: PSDL_Surface;
    framesX, framesY: Integer;
    last, current: PTexture;
    r: TSDL_Rect;
    x, y: Integer;
begin
    SurfaceSheet2Atlas:= nil;
    r.x:= 0;
    r.y:= 0;
    r.w:= spriteWidth;
    r.h:= spriteHeight;
    last:= nil;

    framesX:= surf^.w div spriteWidth;
    framesY:= surf^.h div spriteHeight;

    for x:=0 to Pred(framesX) do
    begin
        r.y:= 0;
        for y:=0 to Pred(framesY) do
        begin
            subSurface:= CropSurface(surf, @r);
            current:= Surface2Atlas(subSurface, false);

            if last = nil then
            begin
                SurfaceSheet2Atlas:= current;
                last:= current;
            end else
            begin
                last^.nextFrame:= current;
                last:= current;
            end;
            inc(r.y, spriteHeight);
        end;
        inc(r.x, spriteWidth);
    end;

    SDL_FreeSurface(surf);
end;

function Surface2Atlas(surf: PSDL_Surface; enableClamp: boolean): PTexture;
var tw, th, x, y: Longword;
    tmpp: pointer;
    cropped: PSDL_Surface;
    fromP4, toP4: PLongWordArray;
    cropInfo: TCropInformation;
begin
    cropped:= AutoCrop(surf, cropInfo);
    if cropped <> surf then
    begin
        SDL_FreeSurface(surf);
        surf:= cropped;
    end;

    if surf = nil then
    begin
        new(Surface2Atlas);
        Surface2Atlas^.w:= 0;
        Surface2Atlas^.h:= 0;
        Surface2Atlas^.x:=0 ;
        Surface2Atlas^.y:=0 ;
        Surface2Atlas^.isRotated:= false;
        Surface2Atlas^.surface:= nil;
        Surface2Atlas^.shared:= false;
        Surface2Atlas^.nextFrame:= nil;
        Surface2Atlas^.cropInfo:= cropInfo;
        exit;
    end;

    //if (surf^.w <= 512) and (surf^.h <= 512) then
    // nothing should use the old codepath anymore once we are done!
    begin
        Surface2Atlas:= Surface2Tex_(surf, enableClamp); // run the atlas side by side for debugging
        Surface2Atlas^.cropInfo:= cropInfo;
        ResetVertexArrays(Surface2Atlas);
        exit;
    end;
new(Surface2Atlas);

// Atlas allocation happens here later on. For now we just allocate one exclusive atlas per sprite
new(Surface2Atlas^.atlas);

Surface2Atlas^.w:= surf^.w;
Surface2Atlas^.h:= surf^.h;
Surface2Atlas^.x:=0;
Surface2Atlas^.y:=0;
Surface2Atlas^.isRotated:=false;
Surface2Atlas^.surface:= surf;
Surface2Atlas^.shared:= false;
Surface2Atlas^.nextFrame:= nil;
Surface2Atlas^.cropInfo:= cropInfo;


if (surf^.format^.BytesPerPixel <> 4) then
    begin
    TryDo(false, 'Surface2Tex failed, expecting 32 bit surface', true);
    Surface2Atlas^.atlas^.id:= 0;
    exit;
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
end;

// deletes texture and frees the memory allocated for it.
// if nil is passed nothing is done
procedure FreeTexture(tex: PTexture);
begin
    if tex <> nil then
    begin
        FreeTexture(tex^.nextFrame); // free all frames linked to this animation

        if tex^.surface = nil then
        begin
            Dispose(tex);
            exit;
        end;

        if tex^.shared then
        begin
            SDL_FreeSurface(tex^.surface);
            FreeTexture_(tex); // run atlas side by side for debugging
            exit;
        end;

    // Atlas cleanup happens here later on. For now we just free as each sprite has one atlas
    glDeleteTextures(1, @tex^.atlas^.id);
    Dispose(tex^.atlas);

    if (tex^.surface <> nil) then
        SDL_FreeSurface(tex^.surface);
    Dispose(tex);
    end
end;

procedure initModule;
begin
assign(logFile, 'out.log');
rewrite(logFile);
uAtlas.initModule;
end;

procedure freeModule;
begin
close(logFile);
end;

end.
