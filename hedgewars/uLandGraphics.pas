(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2005-2008 Andrey Korotaev <unC0Rr@gmail.com>
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

procedure SweepDirty;
function Despeckle(X, Y: LongInt): boolean;
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
if ((y + dy) and LAND_HEIGHT_MASK) = 0 then
    for i:= max(x - dx, 0) to min(x + dx, LAND_WIDTH - 1) do 
        if Land[y + dy, i] <> COLOR_INDESTRUCTIBLE then
            Land[y + dy, i]:= Value;
if ((y - dy) and LAND_HEIGHT_MASK) = 0 then
   for i:= max(x - dx, 0) to min(x + dx, LAND_WIDTH - 1) do 
        if Land[y - dy, i] <> COLOR_INDESTRUCTIBLE then
            Land[y - dy, i]:= Value;
if ((y + dx) and LAND_HEIGHT_MASK) = 0 then
    for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do 
        if Land[y + dx, i] <> COLOR_INDESTRUCTIBLE then
            Land[y + dx, i]:= Value;
if ((y - dx) and LAND_HEIGHT_MASK) = 0 then
    for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do 
        if Land[y - dx, i] <> COLOR_INDESTRUCTIBLE then
            Land[y - dx, i]:= Value;
end;

procedure ChangeCircleLines(x, y, dx, dy: LongInt; doSet: boolean);
var i: LongInt;
begin
if not doSet then
   begin
   if ((y + dy) and LAND_HEIGHT_MASK) = 0 then
      for i:= max(x - dx, 0) to min(x + dx, LAND_WIDTH - 1) do
          if (Land[y + dy, i] > 0) then dec(Land[y + dy, i]); // check > 0 because explosion can erase collision data
   if ((y - dy) and LAND_HEIGHT_MASK) = 0 then
      for i:= max(x - dx, 0) to min(x + dx, LAND_WIDTH - 1) do
          if (Land[y - dy, i] > 0) then dec(Land[y - dy, i]);
   if ((y + dx) and LAND_HEIGHT_MASK) = 0 then
      for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do
          if (Land[y + dx, i] > 0) then dec(Land[y + dx, i]);
   if ((y - dx) and LAND_HEIGHT_MASK) = 0 then
      for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do
          if (Land[y - dx, i] > 0) then dec(Land[y - dx, i]);
   end else
   begin
   if ((y + dy) and LAND_HEIGHT_MASK) = 0 then
      for i:= max(x - dx, 0) to min(x + dx, LAND_WIDTH - 1) do inc(Land[y + dy, i]);
   if ((y - dy) and LAND_HEIGHT_MASK) = 0 then
      for i:= max(x - dx, 0) to min(x + dx, LAND_WIDTH - 1) do inc(Land[y - dy, i]);
   if ((y + dx) and LAND_HEIGHT_MASK) = 0 then
      for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do inc(Land[y + dx, i]);
   if ((y - dx) and LAND_HEIGHT_MASK) = 0 then
      for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do inc(Land[y - dx, i]);
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
        if Land[y + dy, i] <> COLOR_INDESTRUCTIBLE then
            LandPixels[y + dy, i]:= 0;
if ((y - dy) and LAND_HEIGHT_MASK) = 0 then
    for i:= max(x - dx, 0) to min(x + dx, LAND_WIDTH - 1) do 
        if Land[y - dy, i] <> COLOR_INDESTRUCTIBLE then
             LandPixels[y - dy, i]:= 0;
if ((y + dx) and LAND_HEIGHT_MASK) = 0 then
    for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do 
        if Land[y + dx, i] <> COLOR_INDESTRUCTIBLE then
            LandPixels[y + dx, i]:= 0;
if ((y - dx) and LAND_HEIGHT_MASK) = 0 then
    for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do 
        if Land[y - dx, i] <> COLOR_INDESTRUCTIBLE then
             LandPixels[y - dx, i]:= 0;
end;

procedure FillLandCircleLinesEBC(x, y, dx, dy: LongInt);
var i: LongInt;
begin
if ((y + dy) and LAND_HEIGHT_MASK) = 0 then
   for i:= max(x - dx, 0) to min(x + dx, LAND_WIDTH - 1) do
       if Land[y + dy, i] = COLOR_LAND then 
          begin
          LandPixels[y + dy, i]:= cExplosionBorderColor;
//          Despeckle(y + dy, i);
          LandDirty[(y + dy) div 32, i div 32]:= 1;
          end;
if ((y - dy) and LAND_HEIGHT_MASK) = 0 then
   for i:= max(x - dx, 0) to min(x + dx, LAND_WIDTH - 1) do
       if Land[y - dy, i] = COLOR_LAND then
          begin
          LandPixels[y - dy, i]:= cExplosionBorderColor;
//          Despeckle(y - dy, i);
          LandDirty[(y - dy) div 32, i div 32]:= 1;
          end;
if ((y + dx) and LAND_HEIGHT_MASK) = 0 then
   for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do
       if Land[y + dx, i] = COLOR_LAND then
           begin
           LandPixels[y + dx, i]:= cExplosionBorderColor;
//           Despeckle(y + dx, i);
           LandDirty[(y + dx) div 32, i div 32]:= 1;
           end;
if ((y - dx) and LAND_HEIGHT_MASK) = 0 then
   for i:= max(x - dy, 0) to min(x + dy, LAND_WIDTH - 1) do
       if Land[y - dx, i] = COLOR_LAND then
          begin
          LandPixels[y - dx, i]:= cExplosionBorderColor;
//          Despeckle(y - dx, i);
          LandDirty[(y - dx) div 32, i div 32]:= 1;
          end;
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

d:= max(Y - Radius - 1, 0);
dy:= min(Y + Radius + 1, LAND_HEIGHT) - d;
UpdateLandTexture(d, dy)
end;

procedure DrawHLinesExplosions(ar: PRangeArray; Radius: LongInt; y, dY: LongInt; Count: Byte);
var tx, ty, i: LongInt;
begin
for i:= 0 to Pred(Count) do
    begin
    for ty:= max(y - Radius, 0) to min(y + Radius, LAND_HEIGHT) do
        for tx:= max(0, ar^[i].Left - Radius) to min(LAND_WIDTH, ar^[i].Right + Radius) do
            if Land[ty, tx] <> COLOR_INDESTRUCTIBLE then
                LandPixels[ty, tx]:= 0;
    inc(y, dY)
    end;

inc(Radius, 4);
dec(y, Count * dY);

for i:= 0 to Pred(Count) do
    begin
    for ty:= max(y - Radius, 0) to min(y + Radius, LAND_HEIGHT) do
        for tx:= max(0, ar^[i].Left - Radius) to min(LAND_WIDTH, ar^[i].Right + Radius) do
            if Land[ty, tx] = COLOR_LAND then
                begin
                LandPixels[ty, tx]:= cExplosionBorderColor;
                LandDirty[trunc((y + dy)/32), trunc(i/32)]:= 1;
                end;
    inc(y, dY)
    end;


UpdateLandTexture(0, LAND_HEIGHT)
end;

//
//  - (dX, dY) - direction, vector of length = 0.5
//
procedure DrawTunnel(X, Y, dX, dY: hwFloat; ticks, HalfWidth: LongInt);
var nx, ny, dX8, dY8: hwFloat;
    i, t, tx, ty, stY: Longint;
begin  // (-dY, dX) is (dX, dY) rotated by PI/2
stY:= hwRound(Y);

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
        if ((ty and LAND_HEIGHT_MASK) = 0) and ((tx and LAND_WIDTH_MASK) = 0) then
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

t:= max(stY - HalfWidth * 2 - 4 - abs(hwRound(dY * ticks)), 0);
ty:= min(stY + HalfWidth * 2 + 4 + abs(hwRound(dY * ticks)), 2047) - t;
UpdateLandTexture(t, ty)
end;

function TryPlaceOnLand(cpX, cpY: LongInt; Obj: TSprite; Frame: LongInt; doPlace: boolean): boolean;
var X, Y, bpp, h, w: LongInt;
    p: PByteArray;
    Image: PSDL_Surface;
begin
TryDo(SpritesData[Obj].Surface <> nil, 'Assert SpritesData[Obj].Surface failed', true);
Image:= SpritesData[Obj].Surface;
w:= SpritesData[Obj].Width;
h:= SpritesData[Obj].Height;

if SDL_MustLock(Image) then
   SDLTry(SDL_LockSurface(Image) >= 0, true);

bpp:= Image^.format^.BytesPerPixel;
TryDo(bpp = 4, 'It should be 32 bpp sprite', true);
// Check that sprite fits free space
p:= @(PByteArray(Image^.pixels)^[Image^.pitch * Frame * h]);
case bpp of
     4: for y:= 0 to Pred(h) do
            begin
            for x:= 0 to Pred(w) do
                if PLongword(@(p^[x * 4]))^ <> 0 then
                   if (((cpY + y) and LAND_HEIGHT_MASK) <> 0) or
                      (((cpX + x) and LAND_WIDTH_MASK) <> 0) or
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
p:= @(PByteArray(Image^.pixels)^[Image^.pitch * Frame * h]);
case bpp of
     4: for y:= 0 to Pred(h) do
            begin
            for x:= 0 to Pred(w) do
                if PLongword(@(p^[x * 4]))^ <> 0 then
                   begin
                   Land[cpY + y, cpX + x]:= COLOR_LAND;
                   LandPixels[cpY + y, cpX + x]:= PLongword(@(p^[x * 4]))^
                   end;
            p:= @(p^[Image^.pitch]);
            end;
     end;
if SDL_MustLock(Image) then
   SDL_UnlockSurface(Image);

y:= max(cpY, 0);
h:= min(cpY + Image^.h, LAND_HEIGHT) - y;
UpdateLandTexture(y, h)
end;

// was experimenting with applying as damage occurred.
function Despeckle(X, Y: LongInt): boolean;
var nx, ny, i, j, c: LongInt;
begin
if (Land[Y, X] <> 0) and (Land[Y, X] <> COLOR_INDESTRUCTIBLE) then // check neighbours
	begin
	c:= 0;
	for i:= -1 to 1 do
		for j:= -1 to 1 do
			if (i <> 0) or (j <> 0) then
				begin
				ny:= Y + i;
				nx:= X + j;
				if ((ny and LAND_HEIGHT_MASK) = 0) and ((nx and LAND_WIDTH_MASK) = 0) then
					if Land[ny, nx] <> 0 then
						inc(c);
				end;

	if c < 4 then // 0-3 neighbours
		begin
		LandPixels[Y, X]:= 0;
		Land[Y, X]:= 0;
		exit(true);
		end;
	end;
Despeckle:= false
end;

procedure SweepDirty;
var x, y, xx, yy: LongInt;
    updatedRow, updatedCell: boolean;
begin
for y:= 0 to 63 do
	begin
	updatedRow:= false;
	
	for x:= 0 to 127 do
		begin
			repeat
			updatedCell:= false;
			if LandDirty[y, x] <> 0 then
				begin
				updatedRow:= true;
				// testing. should make black squares
				for yy:= y * 32 to y * 32 + 31 do
					for xx:= x * 32 to x * 32 + 31 do
						if Despeckle(xx, yy) then updatedCell:= true;
				end;
			if updatedCell then updatedRow:= true
			until not updatedCell;
		LandDirty[y, x]:= 0;
		end;
	
	if updatedRow then
		UpdateLandTexture(y * 32, 32);
	end;
end;

end.
