(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005-2007 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uLandGraphics;
interface
uses uFloat, uConsts;
{$INCLUDE options.inc}

type PRangeArray = ^TRangeArray;
     TRangeArray = array[0..31] of record
                                   Left, Right: LongInt;
                                   end;

procedure DrawExplosion(X, Y, Radius: LongInt);
procedure DrawHLinesExplosions(ar: PRangeArray; Radius: LongInt; y, dY: LongInt; Count: Byte);
procedure DrawTunnel(X, Y, dX, dY: hwFloat; ticks, HalfWidth: LongInt);
procedure FillRoundInLand(X, Y, Radius: LongInt; Value: Longword);
procedure ChangeRoundInLand(X, Y, Radius: LongInt; doSet: boolean);

function TryPlaceOnLand(cpX, cpY: LongInt; Obj: TSprite; Frame: LongInt; doPlace: boolean): boolean;

implementation
uses SDLh, uMisc, uLand;

procedure FillCircleLines(x, y, dx, dy: LongInt; Value: Longword);
var i: LongInt;
begin
if ((y + dy) and $FFFFFC00) = 0 then
   for i:= max(x - dx, 0) to min(x + dx, 2047) do Land[y + dy, i]:= Value;
if ((y - dy) and $FFFFFC00) = 0 then
   for i:= max(x - dx, 0) to min(x + dx, 2047) do Land[y - dy, i]:= Value;
if ((y + dx) and $FFFFFC00) = 0 then
   for i:= max(x - dy, 0) to min(x + dy, 2047) do Land[y + dx, i]:= Value;
if ((y - dx) and $FFFFFC00) = 0 then
   for i:= max(x - dy, 0) to min(x + dy, 2047) do Land[y - dx, i]:= Value;
end;

procedure ChangeCircleLines(x, y, dx, dy: LongInt; doSet: boolean);
var i: LongInt;
begin
if not doSet then
   begin
   if ((y + dy) and $FFFFFC00) = 0 then
      for i:= max(x - dx, 0) to min(x + dx, 2047) do
          if (Land[y + dy, i] > 0) then dec(Land[y + dy, i]);
   if ((y - dy) and $FFFFFC00) = 0 then
      for i:= max(x - dx, 0) to min(x + dx, 2047) do
          if (Land[y - dy, i] > 0) then dec(Land[y - dy, i]);
   if ((y + dx) and $FFFFFC00) = 0 then
      for i:= max(x - dy, 0) to min(x + dy, 2047) do
          if (Land[y + dx, i] > 0) then dec(Land[y + dx, i]);
   if ((y - dx) and $FFFFFC00) = 0 then
      for i:= max(x - dy, 0) to min(x + dy, 2047) do
          if (Land[y - dx, i] > 0) then dec(Land[y - dx, i]);
   end else
   begin
   if ((y + dy) and $FFFFFC00) = 0 then
      for i:= max(x - dx, 0) to min(x + dx, 2047) do inc(Land[y + dy, i]);
   if ((y - dy) and $FFFFFC00) = 0 then
      for i:= max(x - dx, 0) to min(x + dx, 2047) do inc(Land[y - dy, i]);
   if ((y + dx) and $FFFFFC00) = 0 then
      for i:= max(x - dy, 0) to min(x + dy, 2047) do inc(Land[y + dx, i]);
   if ((y - dx) and $FFFFFC00) = 0 then
      for i:= max(x - dy, 0) to min(x + dy, 2047) do inc(Land[y - dx, i]);
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
if ((y + dy) and $FFFFFC00) = 0 then
   for i:= max(x - dx, 0) to min(x + dx, 2047) do LandPixels[y + dy, i]:= 0;
if ((y - dy) and $FFFFFC00) = 0 then
   for i:= max(x - dx, 0) to min(x + dx, 2047) do LandPixels[y - dy, i]:= 0;
if ((y + dx) and $FFFFFC00) = 0 then
   for i:= max(x - dy, 0) to min(x + dy, 2047) do LandPixels[y + dx, i]:= 0;
if ((y - dx) and $FFFFFC00) = 0 then
   for i:= max(x - dy, 0) to min(x + dy, 2047) do LandPixels[y - dx, i]:= 0;
end;

procedure FillLandCircleLinesEBC(x, y, dx, dy: LongInt);
var i: LongInt;
begin
if ((y + dy) and $FFFFFC00) = 0 then
   for i:= max(x - dx, 0) to min(x + dx, 2047) do
       if Land[y + dy, i] = COLOR_LAND then LandPixels[y + dy, i]:= cExplosionBorderColor;
if ((y - dy) and $FFFFFC00) = 0 then
   for i:= max(x - dx, 0) to min(x + dx, 2047) do
       if Land[y - dy, i] = COLOR_LAND then LandPixels[y - dy, i]:= cExplosionBorderColor;
if ((y + dx) and $FFFFFC00) = 0 then
   for i:= max(x - dy, 0) to min(x + dy, 2047) do
       if Land[y + dx, i] = COLOR_LAND then LandPixels[y + dx, i]:= cExplosionBorderColor;
if ((y - dx) and $FFFFFC00) = 0 then
   for i:= max(x - dy, 0) to min(x + dy, 2047) do
       if Land[y - dx, i] = COLOR_LAND then LandPixels[y - dx, i]:= cExplosionBorderColor;
end;

procedure DrawExplosion(X, Y, Radius: LongInt);
var dx, dy, d: LongInt;
begin
FillRoundInLand(X, Y, Radius, 0);

  dx:= 0;
  dy:= Radius;
  d:= 3 - 2 * Radius;
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

d:= max(Y - Radius, 0);
dy:= min(Y + Radius, 1023) - d;
UpdateLandTexture(d, dy)
end;

procedure DrawHLinesExplosions(ar: PRangeArray; Radius: LongInt; y, dY: LongInt; Count: Byte);
var tx, ty, i: LongInt;
begin
for i:= 0 to Pred(Count) do
    begin
    for ty:= max(y - Radius, 0) to min(y + Radius, 1023) do
        for tx:= max(0, ar^[i].Left - Radius) to min(2047, ar^[i].Right + Radius) do
            LandPixels[ty, tx]:= 0;
    inc(y, dY)
    end;

inc(Radius, 4);
dec(y, Count * dY);

for i:= 0 to Pred(Count) do
    begin
    for ty:= max(y - Radius, 0) to min(y + Radius, 1023) do
        for tx:= max(0, ar^[i].Left - Radius) to min(2047, ar^[i].Right + Radius) do
            if Land[ty, tx] = $FFFFFF then
                  LandPixels[ty, tx]:= cExplosionBorderColor;
    inc(y, dY)
    end;

UpdateLandTexture(0, 1024)
end;

//
//  - (dX, dY) - direction, vector of length = 0.5
//
procedure DrawTunnel(X, Y, dX, dY: hwFloat; ticks, HalfWidth: LongInt);
var nx, ny, dX8, dY8: hwFloat;
    i, t, tx, ty: Longint;
begin  // (-dY, dX) is (dX, dY) rotated by PI/2
nx:= X + dY * (HalfWidth + 8);
ny:= Y - dX * (HalfWidth + 8);

dX8:= dX * 8;
dY8:= dY * 8;
for i:= 0 to 7 do
    begin
    X:= nx - dX8;
    Y:= ny - dY8;
    for t:= -8 to ticks + 8 do
        {$include tunsetborder.inc}
    nx:= nx - dY;
    ny:= ny + dX;
    end;

for i:= -HalfWidth to HalfWidth do
    begin
    X:= nx - dX8;
    Y:= ny - dY8;
    for t:= 0 to 7 do
        {$include tunsetborder.inc}
    X:= nx;
    Y:= ny;
    for t:= 0 to ticks do
        begin
        X:= X + dX;
        Y:= Y + dY;
        tx:= hwRound(X);
        ty:= hwRound(Y);
        if ((ty and $FFFFFC00) = 0) and ((tx and $FFFFF800) = 0) then
         if Land[ty, tx] = COLOR_LAND then
           begin
           Land[ty, tx]:= 0;
           LandPixels[ty, tx]:= 0;
           end
        end;
    for t:= 0 to 7 do
        {$include tunsetborder.inc}
    nx:= nx - dY;
    ny:= ny + dX;
    end;

for i:= 0 to 7 do
    begin
    X:= nx - dX8;
    Y:= ny - dY8;
    for t:= -8 to ticks + 8 do
        {$include tunsetborder.inc}
    nx:= nx - dY;
    ny:= ny + dX;
    end;

UpdateLandTexture(0, 1024)
end;

function TryPlaceOnLand(cpX, cpY: LongInt; Obj: TSprite; Frame: LongInt; doPlace: boolean): boolean;
(*var X, Y, bpp, h, w: LongInt;
    p: PByteArray;
    r, rr: TSDL_Rect;
    Image: PSDL_Surface;*)
begin
(*Image:= SpritesData[Obj].Surface;
w:= SpritesData[Obj].Width;
h:= SpritesData[Obj].Height; 

if SDL_MustLock(Image) then
   SDLTry(SDL_LockSurface(Image) >= 0, true);

bpp:= Image^.format^.BytesPerPixel;
TryDo(bpp <> 1, 'We don''t work with 8 bit surfaces', true);
// Check that sprites fits free space
p:= @(PByteArray(Image^.pixels)^[Image^.pitch * Frame * h]);
case bpp of
     2: for y:= 0 to Pred(h) do
            begin
            for x:= 0 to Pred(w) do
                if PWord(@(p^[x * 2]))^ <> 0 then
                   if (((cpY + y) and $FFFFFC00) <> 0) or
                      (((cpX + x) and $FFFFF800) <> 0) or
                      (Land[cpY + y, cpX + x] <> 0) then
                      begin
                      if SDL_MustLock(Image) then
                         SDL_UnlockSurface(Image);
                      exit(false)
                      end;
            p:= @(p^[Image^.pitch]);
            end;
     3: for y:= 0 to Pred(h) do
            begin
            for x:= 0 to Pred(w) do
                if  (p^[x * 3 + 0] <> 0)
                 or (p^[x * 3 + 1] <> 0)
                 or (p^[x * 3 + 2] <> 0) then
                   if (((cpY + y) and $FFFFFC00) <> 0) or
                      (((cpX + x) and $FFFFF800) <> 0) or
                      (Land[cpY + y, cpX + x] <> 0) then
                      begin
                      if SDL_MustLock(Image) then
                         SDL_UnlockSurface(Image);
                      exit(false)
                      end;
            p:= @(p^[Image^.pitch]);
            end;
     4: for y:= 0 to Pred(h) do
            begin
            for x:= 0 to Pred(w) do
                if PLongword(@(p^[x * 4]))^ <> 0 then
                   if (((cpY + y) and $FFFFFC00) <> 0) or
                      (((cpX + x) and $FFFFF800) <> 0) or
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
if not doPlace then exit;

// Checked, now place
p:= @(PByteArray(Image^.pixels)^[Image^.pitch * Frame * h]);
case bpp of
     2: for y:= 0 to Pred(h) do
            begin
            for x:= 0 to Pred(w) do
                if PWord(@(p^[x * 2]))^ <> 0 then Land[cpY + y, cpX + x]:= COLOR_LAND;
            p:= @(p^[Image^.pitch]);
            end;
     3: for y:= 0 to Pred(h) do
            begin
            for x:= 0 to Pred(w) do
                if  (p^[x * 3 + 0] <> 0)
                 or (p^[x * 3 + 1] <> 0)
                 or (p^[x * 3 + 2] <> 0) then Land[cpY + y, cpX + x]:= COLOR_LAND;
            p:= @(p^[Image^.pitch]);
            end;
     4: for y:= 0 to Pred(h) do
            begin
            for x:= 0 to Pred(w) do
                if PLongword(@(p^[x * 4]))^ <> 0 then Land[cpY + y, cpX + x]:= COLOR_LAND;
            p:= @(p^[Image^.pitch]);
            end;
     end;
if SDL_MustLock(Image) then
   SDL_UnlockSurface(Image);

// Draw sprite on Land surface
r.x:= 0;
r.y:= SpritesData[Obj].Height * Frame;
r.w:= SpritesData[Obj].Width;
r.h:= SpritesData[Obj].Height;
rr.x:= cpX;
rr.y:= cpY;
SDL_UpperBlit(Image, @r, LandSurface, @rr)*)
end;


end.
