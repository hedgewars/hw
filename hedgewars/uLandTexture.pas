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

unit uLandTexture;
interface
uses SDLh;

procedure initModule;
procedure freeModule;
procedure UpdateLandTexture(X, Width, Y, Height: LongInt; landAdded: boolean);
procedure DrawLand(dX, dY: LongInt);
procedure ResetLand;

implementation
uses uConsts, GLunit, uTypes, uVariables, uTextures, uDebug, uRender;

const TEXSIZE = 128;

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
begin
    if (Width <= 0) or (Height <= 0) then
        exit;
    TryDo((X >= 0) and (X < LAND_WIDTH), 'UpdateLandTexture: wrong X parameter', true);
    TryDo(X + Width <= LAND_WIDTH, 'UpdateLandTexture: wrong Width parameter', true);
    TryDo((Y >= 0) and (Y < LAND_HEIGHT), 'UpdateLandTexture: wrong Y parameter', true);
    TryDo(Y + Height <= LAND_HEIGHT, 'UpdateLandTexture: wrong Height parameter', true);

    if (cReducedQuality and rqBlurryLand) = 0 then
        for ty:= Y div TEXSIZE to (Y + Height - 1) div TEXSIZE do
            for tx:= X div TEXSIZE to (X + Width - 1) div TEXSIZE do
                begin
                LandTextures[tx, ty].shouldUpdate:= true;
                LandTextures[tx, ty].landAdded:= landAdded
                end
    else
        for ty:= (Y div TEXSIZE) div 2 to ((Y + Height - 1) div TEXSIZE) div 2 do
            for tx:= (X div TEXSIZE) div 2 to ((X + Width - 1) div TEXSIZE) div 2 do
                begin
                LandTextures[tx, ty].shouldUpdate:= true;
                LandTextures[tx, ty].landAdded:= landAdded
                end
end;

procedure RealLandTexUpdate;
var x, y, ty, tx, lx, ly : LongWord;
    isEmpty: boolean;
begin
(*
if LandTextures[0, 0].tex = nil then
    for x:= 0 to LANDTEXARW -1 do
        for y:= 0 to LANDTEXARH - 1 do
            with LandTextures[x, y] do
                begin
                tex:= NewTexture(TEXSIZE, TEXSIZE, Pixels(x, y));
                glBindTexture(GL_TEXTURE_2D, tex^.atlas^.id);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_PRIORITY, tpHigh);
                end
else
*)
    for x:= 0 to LANDTEXARW -1 do
        for y:= 0 to LANDTEXARH - 1 do
            with LandTextures[x, y] do
                if shouldUpdate then
                    begin
                    shouldUpdate:= false;
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
                        if isEmpty then isEmpty:= LandPixels[ly + ty, lx + TEXSIZE-1] and AMask = 0;
                        inc(ty)
                        end;
                    while isEmpty and (tx < TEXSIZE-1) do
                        begin
                        isEmpty:= LandPixels[ly, lx + tx] and AMask = 0;
                        if isEmpty then isEmpty:= LandPixels[ly + TEXSIZE-1, lx + tx] and AMask = 0;
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
                        glBindTexture(GL_TEXTURE_2D, tex^.atlas^.id);
                        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, TEXSIZE, TEXSIZE, 0, GL_RGBA, GL_UNSIGNED_BYTE, Pixels(x,y));
                        end
                    else if tex <> nil then
                        begin
                        FreeTexture(tex);
                        tex:= nil
                        end;
                    end
end;

procedure DrawLand(dX, dY: LongInt);
var x, y: LongInt;
begin
RealLandTexUpdate;

for x:= 0 to LANDTEXARW -1 do
    for y:= 0 to LANDTEXARH - 1 do
        with LandTextures[x, y] do
            if tex <> nil then
                if (cReducedQuality and rqBlurryLand) = 0 then
                    DrawTexture(dX + x * TEXSIZE, dY + y * TEXSIZE, tex)
                else
                    DrawTexture(dX + x * TEXSIZE * 2, dY + y * TEXSIZE * 2, tex, 2.0)

end;

procedure initModule;
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

procedure ResetLand;
var x, y: LongInt;
begin
    for x:= 0 to LANDTEXARW - 1 do
        for y:= 0 to LANDTEXARH - 1 do
            with LandTextures[x, y] do
                begin
                if tex <> nil then
                    begin
                    FreeTexture(tex);
                    tex:= nil
                    end
                end;
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
