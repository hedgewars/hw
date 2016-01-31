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

unit uLandTexture;
interface
uses SDLh;

procedure initModule;
procedure freeModule;
procedure UpdateLandTexture(X, Width, Y, Height: LongInt; landAdded: boolean);
procedure DrawLand(dX, dY: LongInt);
procedure ResetLand;
procedure SetLandTexture;

implementation
uses uConsts, GLunit, uTypes, uVariables, uTextures, uDebug, uRender, uUtils;

const TEXSIZE = 128;
      // in avoid tile borders stretch the blurry texture by 1 pixel more
      BLURRYLANDOVERLAP: real = 1 / TEXSIZE / 2.0; // 1 pixel divided by texsize and blurry land scale factor

type TLandRecord = record
            shouldUpdate, landAdded: boolean;
            tex: PTexture;
            end;

var LandTextures: array of array of TLandRecord;
    tmpPixels: array [0..TEXSIZE - 1, 0..TEXSIZE - 1] of LongWord;
    LANDTEXARW: LongWord;
    LANDTEXARH: LongWord;

function Pixels(x, y: Longword): Pointer;
var ty: Longword;
begin
for ty:= 0 to TEXSIZE - 1 do
    Move(LandPixels[y * TEXSIZE + ty, x * TEXSIZE], tmpPixels[ty, 0], sizeof(Longword) * TEXSIZE);

Pixels:= @tmpPixels
end;

function Pixels2(x, y: Longword): Pointer;
var tx, ty: Longword;
begin
for ty:= 0 to TEXSIZE - 1 do
    for tx:= 0 to TEXSIZE - 1 do
        tmpPixels[ty, tx]:= Land[y * TEXSIZE + ty, x * TEXSIZE + tx] or AMask;

Pixels2:= @tmpPixels
end;

procedure UpdateLandTexture(X, Width, Y, Height: LongInt; landAdded: boolean);
var tx, ty: Longword;
    tSize : LongInt;
begin
    if cOnlyStats then exit;
    if (Width <= 0) or (Height <= 0) then
        exit;
    checkFails((X >= 0) and (X < LAND_WIDTH), 'UpdateLandTexture: wrong X parameter', true);
    checkFails(X + Width <= LAND_WIDTH, 'UpdateLandTexture: wrong Width parameter', true);
    checkFails((Y >= 0) and (Y < LAND_HEIGHT), 'UpdateLandTexture: wrong Y parameter', true);
    checkFails(Y + Height <= LAND_HEIGHT, 'UpdateLandTexture: wrong Height parameter', true);
    if not allOK then exit;

    tSize:= TEXSIZE;

    // land textures have half the size/resolution in blurry mode
    if (cReducedQuality and rqBlurryLand) <> 0 then
        tSize:= tSize * 2;

    for ty:= Y div tSize to (Y + Height - 1) div tSize do
        for tx:= X div tSize to (X + Width - 1) div tSize do
            begin
            if not LandTextures[tx, ty].shouldUpdate then
                begin
                LandTextures[tx, ty].shouldUpdate:= true;
                inc(dirtyLandTexCount);
                end;
            LandTextures[tx, ty].landAdded:= landAdded
            end;
end;

procedure RealLandTexUpdate(x1, x2, y1, y2: LongInt);
var x, y, ty, tx, lx, ly : LongWord;
    isEmpty: boolean;
begin
    if cOnlyStats then exit;
(*
if LandTextures[0, 0].tex = nil then
    for x:= 0 to LANDTEXARW -1 do
        for y:= 0 to LANDTEXARH - 1 do
            with LandTextures[x, y] do
                begin
                tex:= NewTexture(TEXSIZE, TEXSIZE, Pixels(x, y));
                glBindTexture(GL_TEXTURE_2D, tex^.id);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_PRIORITY, tpHigh);
                end
else
*)
    for x:= x1 to x2 do
        for y:= y1 to y2 do
            with LandTextures[x, y] do
                if shouldUpdate then
                    begin
                    shouldUpdate:= false;
                    dec(dirtyLandTexCount);
                    isEmpty:= not landAdded;
                    landAdded:= false;
                    ty:= 0;
                    tx:= 1;
                    ly:= y * TEXSIZE;
                    lx:= x * TEXSIZE;
                    // first check edges
                    while isEmpty and (ty < TEXSIZE) do
                        begin
                        isEmpty:= LandPixels[ly + ty, lx] and AMask = 0;
                        if isEmpty then isEmpty:= LandPixels[ly + ty, Pred(lx + TEXSIZE)] and AMask = 0;
                        inc(ty)
                        end;
                    while isEmpty and (tx < TEXSIZE-1) do
                        begin
                        isEmpty:= LandPixels[ly, lx + tx] and AMask = 0;
                        if isEmpty then isEmpty:= LandPixels[Pred(ly + TEXSIZE), lx + tx] and AMask = 0;
                        inc(tx)
                        end;
                    // then search every other remaining. does this sort of stuff defeat compiler opts?
                    ty:= 2;
                    while isEmpty and (ty < TEXSIZE-1) do
                        begin
                        tx:= 2;
                        while isEmpty and (tx < TEXSIZE-1) do
                            begin
                            isEmpty:= LandPixels[ly + ty, lx + tx] and AMask = 0;
                            inc(tx,2)
                            end;
                        inc(ty,2);
                        end;
                    // and repeat
                    ty:= 1;
                    while isEmpty and (ty < TEXSIZE-1) do
                        begin
                        tx:= 1;
                        while isEmpty and (tx < TEXSIZE-1) do
                            begin
                            isEmpty:= LandPixels[ly + ty, lx + tx] and AMask = 0;
                            inc(tx,2)
                            end;
                        inc(ty,2);
                        end;
                    if not isEmpty then
                        begin
                        if tex = nil then tex:= NewTexture(TEXSIZE, TEXSIZE, Pixels(x, y));
                        glBindTexture(GL_TEXTURE_2D, tex^.id);
                        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, TEXSIZE, TEXSIZE, 0, GL_RGBA, GL_UNSIGNED_BYTE, Pixels(x,y));
                        end
                    else if tex <> nil then
                        FreeAndNilTexture(tex);

                    // nothing else to do
                    if dirtyLandTexCount < 1 then
                        exit;
                    end
end;

procedure DrawLand(dX, dY: LongInt);
var x, y, tX, ty, tSize, fx, lx, fy, ly: LongInt;
    tScale: GLfloat;
    overlap: boolean;
begin
// init values based on quality settings
if (cReducedQuality and rqBlurryLand) <> 0 then
    begin
    tSize:= TEXSIZE * 2;
    tScale:= 2.0;
    overlap:= (cReducedQuality and rqClampLess) <> 0;
    end
else
    begin
    tSize:= TEXSIZE;
    tScale:= 1.0;
    overlap:= false;
    end;

// figure out visible area
// first column
tx:= ViewLeftX - dx;
fx:= tx div tSize;
if tx < 0 then dec(fx);
fx:= max(0, fx);

// last column
tx:= ViewRightX - dx;
lx:= tx div tSize;
if tx < 0 then dec(lx);
lx:= min(LANDTEXARW -1, lx);

// all offscreen
if (fx > lx) then
    exit;

// first row
ty:= ViewTopY - dy;
fy:= ty div tSize;
if ty < 0 then dec(fy);
fy:= max(0, fy);

// last row
ty:= ViewBottomY - dy;
ly:= ty div tSize;
if ty < 0 then dec(ly);
ly:= min(LANDTEXARH -1, ly);

// all offscreen
if (fy > ly) then
    exit;

// update visible areas of landtex before drawing
if dirtyLandTexCount > 0 then
    RealLandTexUpdate(fx, lx, fy, ly);

tX:= dX + tsize * fx;

// loop through columns
for x:= fx to lx do
    begin
    // loop through textures in this column
    for y:= fy to ly do
        with LandTextures[x, y] do
            if tex <> nil then
                begin
                ty:= dY + y * tSize;
                if overlap then
                    DrawTexture2(tX, ty, tex, tScale, BLURRYLANDOVERLAP)
                else
                    DrawTexture(tX, ty, tex, tScale);
                end;

    // increment tX
    inc(tX, tSize);
    end;
end;

procedure SetLandTexture;
begin
    if (cReducedQuality and rqBlurryLand) = 0 then
        begin
        LANDTEXARW:= LAND_WIDTH div TEXSIZE;
        LANDTEXARH:= LAND_HEIGHT div TEXSIZE;
        end
    else
        begin
        LANDTEXARW:= (LAND_WIDTH div TEXSIZE) div 2;
        LANDTEXARH:= (LAND_HEIGHT div TEXSIZE) div 2;
        end;

    SetLength(LandTextures, LANDTEXARW, LANDTEXARH);
end;

procedure initModule;
begin
end;

procedure ResetLand;
var x, y: LongInt;
begin
    for x:= 0 to LANDTEXARW - 1 do
        for y:= 0 to LANDTEXARH - 1 do
            with LandTextures[x, y] do
                FreeAndNilTexture(tex);
end;

procedure freeModule;
begin
    ResetLand;
    if LandBackSurface <> nil then
        SDL_FreeSurface(LandBackSurface);
    LandBackSurface:= nil;
    SetLength(LandTextures, 0, 0);
end;
end.
