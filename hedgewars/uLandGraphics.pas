(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2005-2010 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uLandGraphics;
interface
uses uFloat, uConsts;

type PRangeArray = ^TRangeArray;
     TRangeArray = array[0..31] of record
                                   Left, Right: LongInt;
                                   end;

function  SweepDirty: boolean;
function  Despeckle(X, Y: LongInt): boolean;
function  CheckLandValue(X, Y: LongInt; LandFlag: Word): boolean;
procedure DrawExplosion(X, Y, Radius: LongInt);
procedure DrawHLinesExplosions(ar: PRangeArray; Radius: LongInt; y, dY: LongInt; Count: Byte);
procedure DrawTunnel(X, Y, dX, dY: hwFloat; ticks, HalfWidth: LongInt);
procedure FillRoundInLand(X, Y, Radius: LongInt; Value: Longword);
procedure ChangeRoundInLand(X, Y, Radius: LongInt; doSet: boolean);

function TryPlaceOnLand(cpX, cpY: LongInt; Obj: TSprite; Frame: LongInt; doPlace: boolean): boolean;

implementation
uses SDLh, uMisc, uLand, uLandTexture;

procedure FillCircleLines(x, y, dx, dy: LongInt; Value: Longword);
var i: LongInt;
begin
if ((y + dy) and LAND_HEIGHT_MASK) = 0 then
    for i:= max(x - dx, 0) to min(x + dx, LAND_WIDTH - 1) do
        if (Land[y + dy, i] and LAND_INDESTRUCTIBLE) = 0 then
            Land[y + dy, i]:= Value;
if ((y - dy) and LAND_HEIGHT_MASK) = 0 then
   for i:= max(x - dx, 0) to min(x + dx, LAND_WIDTH - 1) do
        if (Land[y - dy, i] and LAND_INDESTRUCTIBLE) = 0 then
            Land[y - dy, i]:= Value;
if ((y + dx) and LAND_HEIGHT_MASK) = 0 then
    for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do
        if (Land[y + dx, i] and LAND_INDESTRUCTIBLE) = 0 then
            Land[y + dx, i]:= Value;
if ((y - dx) and LAND_HEIGHT_MASK) = 0 then
    for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do
        if (Land[y - dx, i] and LAND_INDESTRUCTIBLE) = 0 then
            Land[y - dx, i]:= Value;
end;

procedure ChangeCircleLines(x, y, dx, dy: LongInt; doSet: boolean);
var i: LongInt;
begin
if not doSet then
   begin
   if ((y + dy) and LAND_HEIGHT_MASK) = 0 then
      for i:= max(x - dx, 0) to min(x + dx, LAND_WIDTH - 1) do
          if (Land[y + dy, i] > 0) and (Land[y + dy, i] < 256) then dec(Land[y + dy, i]); // check > 0 because explosion can erase collision data
   if ((y - dy) and LAND_HEIGHT_MASK) = 0 then
      for i:= max(x - dx, 0) to min(x + dx, LAND_WIDTH - 1) do
          if (Land[y - dy, i] > 0) and (Land[y - dy, i] < 256) then dec(Land[y - dy, i]);
   if ((y + dx) and LAND_HEIGHT_MASK) = 0 then
      for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do
          if (Land[y + dx, i] > 0) and (Land[y + dx, i] < 256) then dec(Land[y + dx, i]);
   if ((y - dx) and LAND_HEIGHT_MASK) = 0 then
      for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do
          if (Land[y - dx, i] > 0) and (Land[y - dx, i] < 256) then dec(Land[y - dx, i]);
   end else
   begin
   if ((y + dy) and LAND_HEIGHT_MASK) = 0 then
      for i:= max(x - dx, 0) to min(x + dx, LAND_WIDTH - 1) do
          if (Land[y + dy, i] < 256) then
              inc(Land[y + dy, i]);
   if ((y - dy) and LAND_HEIGHT_MASK) = 0 then
      for i:= max(x - dx, 0) to min(x + dx, LAND_WIDTH - 1) do
          if (Land[y - dy, i] < 256) then
              inc(Land[y - dy, i]);
   if ((y + dx) and LAND_HEIGHT_MASK) = 0 then
      for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do
          if (Land[y + dx, i] < 256) then
              inc(Land[y + dx, i]);
   if ((y - dx) and LAND_HEIGHT_MASK) = 0 then
      for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do
          if (Land[y - dx, i] < 256) then
              inc(Land[y - dx, i]);
   end
end;

procedure FillRoundInLand(X, Y, Radius: LongInt; Value: Longword);
var dx, dy, d: LongInt;
begin
  dx:= 0;
  dy:= Radius;
  d:= 3 - 2 * Radius;
  while (dx < dy) do
     begin
     FillCircleLines(x, y, dx, dy, Value);
     if (d < 0)
     then d:= d + 4 * dx + 6
     else begin
          d:= d + 4 * (dx - dy) + 10;
          dec(dy)
          end;
     inc(dx)
     end;
  if (dx = dy) then FillCircleLines(x, y, dx, dy, Value);
end;

procedure ChangeRoundInLand(X, Y, Radius: LongInt; doSet: boolean);
var dx, dy, d: LongInt;
begin
  dx:= 0;
  dy:= Radius;
  d:= 3 - 2 * Radius;
  while (dx < dy) do
     begin
     ChangeCircleLines(x, y, dx, dy, doSet);
     if (d < 0)
     then d:= d + 4 * dx + 6
     else begin
          d:= d + 4 * (dx - dy) + 10;
          dec(dy)
          end;
     inc(dx)
     end;
  if (dx = dy) then ChangeCircleLines(x, y, dx, dy, doSet)
end;

procedure FillLandCircleLines0(x, y, dx, dy: LongInt);
var i: LongInt;
begin
if ((y + dy) and LAND_HEIGHT_MASK) = 0 then
    for i:= max(x - dx, 0) to min(x + dx, LAND_WIDTH - 1) do
        if (not isMap and ((Land[y + dy, i] and LAND_INDESTRUCTIBLE) = 0)) or ((Land[y + dy, i] and LAND_BASIC) <> 0) then
{$IFDEF DOWNSCALE}
            LandPixels[(y + dy) div 2, i div 2]:= 0;
{$ELSE}
            LandPixels[y + dy, i]:= 0;
{$ENDIF}
if ((y - dy) and LAND_HEIGHT_MASK) = 0 then
    for i:= max(x - dx, 0) to min(x + dx, LAND_WIDTH - 1) do
        if (not isMap and ((Land[y - dy, i] and LAND_INDESTRUCTIBLE) = 0)) or ((Land[y - dy, i] and LAND_BASIC) <> 0) then
{$IFDEF DOWNSCALE}
             LandPixels[(y - dy) div 2, i div 2]:= 0;
{$ELSE}
             LandPixels[y - dy, i]:= 0;
{$ENDIF}
if ((y + dx) and LAND_HEIGHT_MASK) = 0 then
    for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do
        if (not isMap and ((Land[y + dx, i] and LAND_INDESTRUCTIBLE) = 0)) or ((Land[y + dx, i] and LAND_BASIC) <> 0) then
{$IFDEF DOWNSCALE}
            LandPixels[(y + dx) div 2, i div 2]:= 0;
{$ELSE}
            LandPixels[y + dx, i]:= 0;
{$ENDIF}
if ((y - dx) and LAND_HEIGHT_MASK) = 0 then
    for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do
        if (not isMap and ((Land[y - dx, i] and LAND_INDESTRUCTIBLE) = 0)) or ((Land[y - dx, i] and LAND_BASIC) <> 0) then
{$IFDEF DOWNSCALE}
             LandPixels[(y - dx) div 2, i div 2]:= 0;
{$ELSE}
             LandPixels[y - dx, i]:= 0;
{$ENDIF}
end;

procedure FillLandCircleLinesBG(x, y, dx, dy: LongInt);
var i: LongInt;
begin
if ((y + dy) and LAND_HEIGHT_MASK) = 0 then
   for i:= max(x - dx, 0) to min(x + dx, LAND_WIDTH - 1) do
       if ((Land[y + dy, i] and LAND_BASIC) <> 0) then
{$IFDEF DOWNSCALE}
          LandPixels[(y + dy) div 2, i div 2]:= LandBackPixel(i, y + dy)
{$ELSE}
          LandPixels[y + dy, i]:= LandBackPixel(i, y + dy)
{$ENDIF}
       else
{$IFDEF DOWNSCALE}
          if (Land[y + dy, i] = LAND_OBJECT) then LandPixels[(y + dy) div 2, i div 2]:= 0;
{$ELSE}
          if (Land[y + dy, i] = LAND_OBJECT) then LandPixels[y + dy, i]:= 0;
{$ENDIF}
if ((y - dy) and LAND_HEIGHT_MASK) = 0 then
   for i:= max(x - dx, 0) to min(x + dx, LAND_WIDTH - 1) do
       if ((Land[y - dy, i] and LAND_BASIC) <> 0) then
{$IFDEF DOWNSCALE}
          LandPixels[(y - dy) div 2, i div 2]:= LandBackPixel(i, y - dy)
{$ELSE}
          LandPixels[y - dy, i]:= LandBackPixel(i, y - dy)
{$ENDIF}
       else
{$IFDEF DOWNSCALE}
          if (Land[y - dy, i] = LAND_OBJECT) then LandPixels[(y - dy) div 2, i div 2]:= 0;
{$ELSE}
          if (Land[y - dy, i] = LAND_OBJECT) then LandPixels[y - dy, i]:= 0;
{$ENDIF}
if ((y + dx) and LAND_HEIGHT_MASK) = 0 then
   for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do
       if ((Land[y + dx, i] and LAND_BASIC) <> 0) then
{$IFDEF DOWNSCALE}
           LandPixels[(y + dx) div 2, i div 2]:= LandBackPixel(i, y + dx)
{$ELSE}
           LandPixels[y + dx, i]:= LandBackPixel(i, y + dx)
{$ENDIF}
       else
{$IFDEF DOWNSCALE}
          if (Land[y + dx, i] = LAND_OBJECT) then LandPixels[(y + dx) div 2, i div 2]:= 0;
{$ELSE}
          if (Land[y + dx, i] = LAND_OBJECT) then LandPixels[y + dx, i]:= 0;
{$ENDIF}
if ((y - dx) and LAND_HEIGHT_MASK) = 0 then
   for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do
       if ((Land[y - dx, i] and LAND_BASIC) <> 0) then
{$IFDEF DOWNSCALE}
          LandPixels[(y - dx) div 2, i div 2]:= LandBackPixel(i, y - dx)
{$ELSE}
          LandPixels[y - dx, i]:= LandBackPixel(i, y - dx)
{$ENDIF}
       else
{$IFDEF DOWNSCALE}
          if (Land[y - dx, i] = LAND_OBJECT) then LandPixels[(y - dx) div 2, i div 2]:= 0;
{$ELSE}
          if (Land[y - dx, i] = LAND_OBJECT) then LandPixels[y - dx, i]:= 0;
{$ENDIF}
end;

procedure FillLandCircleLinesEBC(x, y, dx, dy: LongInt);
var i: LongInt;
begin
if ((y + dy) and LAND_HEIGHT_MASK) = 0 then
   for i:= max(x - dx, 0) to min(x + dx, LAND_WIDTH - 1) do
       if ((Land[y + dy, i] and LAND_BASIC) <> 0) or (Land[y + dy, i] = LAND_OBJECT) then
          begin
{$IFDEF DOWNSCALE}
          LandPixels[(y + dy) div 2, i div 2]:= cExplosionBorderColor;
{$ELSE}
          LandPixels[y + dy, i]:= cExplosionBorderColor;
{$ENDIF}
          Land[y + dy, i]:= Land[y + dy, i] or LAND_DAMAGED;
          Despeckle(i, y + dy);
          LandDirty[(y + dy) div 32, i div 32]:= 1;
          end;
if ((y - dy) and LAND_HEIGHT_MASK) = 0 then
   for i:= max(x - dx, 0) to min(x + dx, LAND_WIDTH - 1) do
       if ((Land[y - dy, i] and LAND_BASIC) <> 0) or (Land[y - dy, i] = LAND_OBJECT) then
          begin
{$IFDEF DOWNSCALE}
          LandPixels[(y - dy) div 2, i div 2]:= cExplosionBorderColor;
{$ELSE}
          LandPixels[y - dy, i]:= cExplosionBorderColor;
{$ENDIF}
          Land[y - dy, i]:= Land[y - dy, i] or LAND_DAMAGED;
          Despeckle(i, y - dy);
          LandDirty[(y - dy) div 32, i div 32]:= 1;
          end;
if ((y + dx) and LAND_HEIGHT_MASK) = 0 then
   for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do
       if ((Land[y + dx, i] and LAND_BASIC) <> 0) or (Land[y + dx, i] = LAND_OBJECT) then
           begin
{$IFDEF DOWNSCALE}
           LandPixels[(y + dx) div 2, i div 2]:= cExplosionBorderColor;
{$ELSE}
           LandPixels[y + dx, i]:= cExplosionBorderColor;
{$ENDIF}
           Land[y + dx, i]:= Land[y + dx, i] or LAND_DAMAGED;
           Despeckle(i, y + dx);
           LandDirty[(y + dx) div 32, i div 32]:= 1;
           end;
if ((y - dx) and LAND_HEIGHT_MASK) = 0 then
   for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do
       if ((Land[y - dx, i] and LAND_BASIC) <> 0) or (Land[y - dx, i] = LAND_OBJECT) then
          begin
{$IFDEF DOWNSCALE}
          LandPixels[(y - dx) div 2, i div 2]:= cExplosionBorderColor;
{$ELSE}
          LandPixels[y - dx, i]:= cExplosionBorderColor;
{$ENDIF}
          Land[y - dx, i]:= Land[y - dx, i] or LAND_DAMAGED;
          Despeckle(i, y - dy);
          LandDirty[(y - dx) div 32, i div 32]:= 1;
          end;
end;

procedure DrawExplosion(X, Y, Radius: LongInt);
var dx, dy, ty, tx, d: LongInt;
begin

// draw background land texture
    begin
    dx:= 0;
    dy:= Radius;
    d:= 3 - 2 * Radius;

    while (dx < dy) do
        begin
        FillLandCircleLinesBG(x, y, dx, dy);
        if (d < 0)
        then d:= d + 4 * dx + 6
        else begin
            d:= d + 4 * (dx - dy) + 10;
            dec(dy)
            end;
        inc(dx)
        end;
    if (dx = dy) then FillLandCircleLinesBG(x, y, dx, dy);
    end;

// draw a hole in land
if Radius > 20 then
    begin
    dx:= 0;
    dy:= Radius - 15;
    d:= 3 - 2 * dy;

    while (dx < dy) do
        begin
        FillLandCircleLines0(x, y, dx, dy);
        if (d < 0)
        then d:= d + 4 * dx + 6
        else begin
            d:= d + 4 * (dx - dy) + 10;
            dec(dy)
            end;
        inc(dx)
        end;
    if (dx = dy) then FillLandCircleLines0(x, y, dx, dy);
    end;

  // FillRoundInLand after erasing land pixels to allow Land 0 check for mask.png to function
    FillRoundInLand(X, Y, Radius, 0);

// draw explosion border
    begin
    inc(Radius, 4);
    dx:= 0;
    dy:= Radius;
    d:= 3 - 2 * Radius;
    while (dx < dy) do
        begin
        FillLandCircleLinesEBC(x, y, dx, dy);
        if (d < 0)
        then d:= d + 4 * dx + 6
        else begin
            d:= d + 4 * (dx - dy) + 10;
            dec(dy)
            end;
        inc(dx)
        end;
    if (dx = dy) then FillLandCircleLinesEBC(x, y, dx, dy);
    end;

tx:= max(X - Radius - 1, 0);
dx:= min(X + Radius + 1, LAND_WIDTH) - tx;
ty:= max(Y - Radius - 1, 0);
dy:= min(Y + Radius + 1, LAND_HEIGHT) - ty;
UpdateLandTexture(tx, dx, ty, dy)
end;

procedure DrawHLinesExplosions(ar: PRangeArray; Radius: LongInt; y, dY: LongInt; Count: Byte);
var tx, ty, i: LongInt;
begin
for i:= 0 to Pred(Count) do
    begin
    for ty:= max(y - Radius, 0) to min(y + Radius, LAND_HEIGHT) do
        for tx:= max(0, ar^[i].Left - Radius) to min(LAND_WIDTH, ar^[i].Right + Radius) do
            if (Land[ty, tx] and LAND_BASIC) <> 0 then
{$IFDEF DOWNSCALE}
                LandPixels[ty div 2, tx div 2]:= LandBackPixel(tx, ty)
{$ELSE}
                LandPixels[ty, tx]:= LandBackPixel(tx, ty)
{$ENDIF}
            else if Land[ty, tx] = LAND_OBJECT then
{$IFDEF DOWNSCALE}
                LandPixels[ty div 2, tx div 2]:= 0;
{$ELSE}
                LandPixels[ty, tx]:= 0;
{$ENDIF}
    inc(y, dY)
    end;

inc(Radius, 4);
dec(y, Count * dY);

for i:= 0 to Pred(Count) do
    begin
    for ty:= max(y - Radius, 0) to min(y + Radius, LAND_HEIGHT) do
        for tx:= max(0, ar^[i].Left - Radius) to min(LAND_WIDTH, ar^[i].Right + Radius) do
            if ((Land[ty, tx] and LAND_BASIC) <> 0) or (Land[ty, tx] = LAND_OBJECT) then
                begin
{$IFDEF DOWNSCALE}
                LandPixels[ty div 2, tx div 2]:= cExplosionBorderColor;
{$ELSE}
                LandPixels[ty, tx]:= cExplosionBorderColor;
{$ENDIF}
                Land[ty, tx]:= Land[ty, tx] or LAND_DAMAGED;
                LandDirty[(y + dy) shr 5, i shr 5]:= 1;
                end;
    inc(y, dY)
    end;


UpdateLandTexture(0, LAND_WIDTH, 0, LAND_HEIGHT)
end;

//
//  - (dX, dY) - direction, vector of length = 0.5
//
procedure DrawTunnel(X, Y, dX, dY: hwFloat; ticks, HalfWidth: LongInt);
var nx, ny, dX8, dY8: hwFloat;
    i, t, tx, ty, stX, stY, ddy, ddx: Longint;
begin  // (-dY, dX) is (dX, dY) rotated by PI/2
stY:= hwRound(Y);
stX:= hwRound(X);

nx:= X + dY * (HalfWidth + 8);
ny:= Y - dX * (HalfWidth + 8);

dX8:= dX * 8;
dY8:= dY * 8;
for i:= 0 to 7 do
    begin
    X:= nx - dX8;
    Y:= ny - dY8;
    for t:= -8 to ticks + 8 do
    begin
    X:= X + dX;
    Y:= Y + dY;
    tx:= hwRound(X);
    ty:= hwRound(Y);
    if ((ty and LAND_HEIGHT_MASK) = 0) and
       ((tx and LAND_WIDTH_MASK) = 0) and
       (((Land[ty, tx] and LAND_BASIC) <> 0) or 
       (Land[ty, tx] = LAND_OBJECT)) then
        begin
        Land[ty, tx]:= Land[ty, tx] or LAND_DAMAGED;
{$IFDEF DOWNSCALE}
        LandPixels[ty div 2, tx div 2]:= cExplosionBorderColor
{$ELSE}
        LandPixels[ty, tx]:= cExplosionBorderColor
{$ENDIF}
        end
    end;
    nx:= nx - dY;
    ny:= ny + dX;
    end;

for i:= -HalfWidth to HalfWidth do
    begin
    X:= nx - dX8;
    Y:= ny - dY8;
    for t:= 0 to 7 do
    begin
    X:= X + dX;
    Y:= Y + dY;
    tx:= hwRound(X);
    ty:= hwRound(Y);
    if ((ty and LAND_HEIGHT_MASK) = 0) and
       ((tx and LAND_WIDTH_MASK) = 0) and
       (((Land[ty, tx] and LAND_BASIC) <> 0) or 
       (Land[ty, tx] = LAND_OBJECT)) then
        begin
        Land[ty, tx]:= Land[ty, tx] or LAND_DAMAGED;
{$IFDEF DOWNSCALE}
        LandPixels[ty div 2, tx div 2]:= cExplosionBorderColor
{$ELSE}
        LandPixels[ty, tx]:= cExplosionBorderColor
{$ENDIF}
        end
    end;
    X:= nx;
    Y:= ny;
    for t:= 0 to ticks do
        begin
        X:= X + dX;
        Y:= Y + dY;
        tx:= hwRound(X);
        ty:= hwRound(Y);
        if ((ty and LAND_HEIGHT_MASK) = 0) and ((tx and LAND_WIDTH_MASK) = 0) and ((Land[ty, tx] and LAND_INDESTRUCTIBLE) = 0) then
            begin
            if (Land[ty, tx] and LAND_BASIC) <> 0 then
{$IFDEF DOWNSCALE}
                LandPixels[ty div 2, tx div 2]:= LandBackPixel(tx, ty)
{$ELSE}
                LandPixels[ty, tx]:= LandBackPixel(tx, ty)
{$ENDIF}
            else if Land[ty, tx] = LAND_OBJECT then
{$IFDEF DOWNSCALE}
                LandPixels[ty div 2, tx div 2]:= 0;
{$ELSE}
                LandPixels[ty, tx]:= 0;
{$ENDIF}
            Land[ty, tx]:= 0;
            end
        end;
    for t:= 0 to 7 do
    begin
    X:= X + dX;
    Y:= Y + dY;
    tx:= hwRound(X);
    ty:= hwRound(Y);
    if ((ty and LAND_HEIGHT_MASK) = 0) and
       ((tx and LAND_WIDTH_MASK) = 0) and
       (((Land[ty, tx] and LAND_BASIC) <> 0) or 
       (Land[ty, tx] = LAND_OBJECT)) then
        begin
        Land[ty, tx]:= Land[ty, tx] or LAND_DAMAGED;
{$IFDEF DOWNSCALE}
        LandPixels[ty div 2, tx div 2]:= cExplosionBorderColor
{$ELSE}
        LandPixels[ty, tx]:= cExplosionBorderColor
{$ENDIF}
        end
    end;
    nx:= nx - dY;
    ny:= ny + dX;
    end;

for i:= 0 to 7 do
    begin
    X:= nx - dX8;
    Y:= ny - dY8;
    for t:= -8 to ticks + 8 do
    begin
    X:= X + dX;
    Y:= Y + dY;
    tx:= hwRound(X);
    ty:= hwRound(Y);
    if ((ty and LAND_HEIGHT_MASK) = 0) and
       ((tx and LAND_WIDTH_MASK) = 0) and
       (((Land[ty, tx] and LAND_BASIC) <> 0) or 
       (Land[ty, tx] = LAND_OBJECT)) then
        begin
        Land[ty, tx]:= Land[ty, tx] or LAND_DAMAGED;
{$IFDEF DOWNSCALE}
        LandPixels[ty div 2, tx div 2]:= cExplosionBorderColor
{$ELSE}
        LandPixels[ty, tx]:= cExplosionBorderColor
{$ENDIF}
        end
    end;
    nx:= nx - dY;
    ny:= ny + dX;
    end;

tx:= max(stX - HalfWidth * 2 - 4 - abs(hwRound(dX * ticks)), 0);
ty:= max(stY - HalfWidth * 2 - 4 - abs(hwRound(dY * ticks)), 0);
ddx:= min(stX + HalfWidth * 2 + 4 + abs(hwRound(dX * ticks)), LAND_WIDTH) - tx;
ddy:= min(stY + HalfWidth * 2 + 4 + abs(hwRound(dY * ticks)), LAND_HEIGHT) - ty;

UpdateLandTexture(tx, ddx, ty, ddy)
end;

function TryPlaceOnLand(cpX, cpY: LongInt; Obj: TSprite; Frame: LongInt; doPlace: boolean): boolean;
var X, Y, bpp, h, w, row, col, numFramesFirstCol: LongInt;
    p: PByteArray;
    Image: PSDL_Surface;
begin
numFramesFirstCol:= SpritesData[Obj].imageHeight div SpritesData[Obj].Height;

TryDo(SpritesData[Obj].Surface <> nil, 'Assert SpritesData[Obj].Surface failed', true);
Image:= SpritesData[Obj].Surface;
w:= SpritesData[Obj].Width;
h:= SpritesData[Obj].Height;
row:= Frame mod numFramesFirstCol;
col:= Frame div numFramesFirstCol;

if SDL_MustLock(Image) then
   SDLTry(SDL_LockSurface(Image) >= 0, true);

bpp:= Image^.format^.BytesPerPixel;
TryDo(bpp = 4, 'It should be 32 bpp sprite', true);
// Check that sprite fits free space
p:= @(PByteArray(Image^.pixels)^[ Image^.pitch * row * h + col * w * 4 ]);
case bpp of
     4: for y:= 0 to Pred(h) do
            begin
            for x:= 0 to Pred(w) do
                if PLongword(@(p^[x * 4]))^ <> 0 then
                   if ((cpY + y) < Longint(topY)) or
                      ((cpY + y) > LAND_HEIGHT) or
                      ((cpX + x) < Longint(leftX)) or
                      ((cpX + x) > Longint(rightX)) or
                      (Land[cpY + y, cpX + x] <> 0) then
                      begin
                      if SDL_MustLock(Image) then
                         SDL_UnlockSurface(Image);
                      exit(false)
                      end;
            p:= @(p^[Image^.pitch]);
            end;
     end;

TryPlaceOnLand:= true;
if not doPlace then
   begin
   if SDL_MustLock(Image) then
      SDL_UnlockSurface(Image);
   exit
   end;

// Checked, now place
p:= @(PByteArray(Image^.pixels)^[ Image^.pitch * row * h + col * w * 4 ]);
case bpp of
     4: for y:= 0 to Pred(h) do
            begin
            for x:= 0 to Pred(w) do
                if PLongword(@(p^[x * 4]))^ <> 0 then
                   begin
                   Land[cpY + y, cpX + x]:= LAND_OBJECT;
{$IFDEF DOWNSCALE}
                   LandPixels[(cpY + y) div 2, (cpX + x) div 2]:= PLongword(@(p^[x * 4]))^
{$ELSE}
                   LandPixels[cpY + y, cpX + x]:= PLongword(@(p^[x * 4]))^
{$ENDIF}
                   end;
            p:= @(p^[Image^.pitch]);
            end;
     end;
if SDL_MustLock(Image) then
   SDL_UnlockSurface(Image);

x:= max(cpX, leftX);
w:= min(cpX + Image^.w, LAND_WIDTH) - x;
y:= max(cpY, topY);
h:= min(cpY + Image^.h, LAND_HEIGHT) - y;
UpdateLandTexture(x, w, y, h)
end;

// was experimenting with applying as damage occurred.
function Despeckle(X, Y: LongInt): boolean;
var nx, ny, i, j, c: LongInt;
begin
if (Land[Y, X] > 255) and ((Land[Y, X] and LAND_INDESTRUCTIBLE) = 0) and ((Land[Y, X] and LAND_DAMAGED) <> 0)then // check neighbours
    begin
    c:= 0;
    for i:= -1 to 1 do
        for j:= -1 to 1 do
            if (i <> 0) or (j <> 0) then
                begin
                ny:= Y + i;
                nx:= X + j;
                if ((ny and LAND_HEIGHT_MASK) = 0) and ((nx and LAND_WIDTH_MASK) = 0) then
                    if Land[ny, nx] > 255 then
                        inc(c);
                end;

    if c < 4 then // 0-3 neighbours
        begin
{$IFDEF DOWNSCALE}
        if (Land[Y, X] and LAND_BASIC) <> 0 then LandPixels[Y div 2, X div 2]:= LandBackPixel(X, Y) else LandPixels[Y div 2, X div 2]:= 0;
{$ELSE}
        if (Land[Y, X] and LAND_BASIC) <> 0 then LandPixels[Y, X]:= LandBackPixel(X, Y) else LandPixels[Y, X]:= 0;
{$ENDIF}
        Land[Y, X]:= 0;
        exit(true);
        end;
    end;
Despeckle:= false
end;

function SweepDirty: boolean;
var x, y, xx, yy: LongInt;
    bRes, updateBlock, resweep: boolean;
begin
bRes:= false;

for y:= 0 to LAND_HEIGHT div 32 - 1 do
    begin

    for x:= 0 to LAND_WIDTH div 32 - 1 do
        begin
        if LandDirty[y, x] <> 0 then
            begin
            updateBlock:= false;
            resweep:= true;
            while(resweep) do
                begin
                resweep:= false;
                for yy:= y * 32 to y * 32 + 31 do
                    for xx:= x * 32 to x * 32 + 31 do
                        if Despeckle(xx, yy) then
                            begin
                            bRes:= true;
                            updateBlock:= true;
                            resweep:= true;
                            end;
                end;
            if updateBlock then UpdateLandTexture(x * 32, 32, y * 32, 32);
            LandDirty[y, x]:= 0;
            end;
        end;
    end;

SweepDirty:= bRes;
end;

// Return true if outside of land or not the value tested, used right now for some X/Y movement that does not use normal hedgehog movement in GSHandlers.inc
function CheckLandValue(X, Y: LongInt; LandFlag: Word): boolean;
begin
     CheckLandValue:= ((X and LAND_WIDTH_MASK <> 0) or (Y and LAND_HEIGHT_MASK <> 0)) or ((Land[Y, X] and LandFlag) = 0)
end;
end.
