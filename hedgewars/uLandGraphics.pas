unit uLandGraphics;
interface
uses uFloat;
{$INCLUDE options.inc}

type PRangeArray = ^TRangeArray;
     TRangeArray = array[0..31] of record
                                   Left, Right: LongInt;
                                   end;

procedure DrawExplosion(X, Y, Radius: LongInt);
procedure DrawHLinesExplosions(ar: PRangeArray; Radius: LongInt; y, dY: LongInt; Count: Byte);
procedure DrawTunnel(X, Y, dX, dY: hwFloat; ticks, HalfWidth: LongInt);
procedure FillRoundInLand(X, Y, Radius: LongInt; Value: Longword);

implementation
uses SDLh, uMisc, uLand, uConsts;

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

procedure ClearLandPixel(y, x: LongInt);
var p: PByteArray;
begin
p:= @PByteArray(LandSurface^.pixels)^[LandSurface^.pitch * y];
case LandSurface^.format^.BytesPerPixel of
     1: ;// not supported
     2: PWord(@(p^[x * 2]))^:= 0;
     3: begin
        p^[x * 3 + 0]:= 0;
        p^[x * 3 + 1]:= 0;
        p^[x * 3 + 2]:= 0;
        end;
     4: PLongword(@(p^[x * 4]))^:= 0;
     end
end;

procedure SetLandPixel(y, x: LongInt);
var p: PByteArray;
begin
p:= @PByteArray(LandSurface^.pixels)^[LandSurface^.pitch * y];
case LandSurface^.format^.BytesPerPixel of
     1: ;// not supported
     2: PWord(@(p^[x * 2]))^:= cExplosionBorderColor;
     3: begin
        p^[x * 3 + 0]:= cExplosionBorderColor and $FF;
        p^[x * 3 + 1]:= (cExplosionBorderColor shr 8) and $FF;
        p^[x * 3 + 2]:= cExplosionBorderColor shr 16;
        end;
     4: PLongword(@(p^[x * 4]))^:= cExplosionBorderColor;
     end
end;

procedure FillLandCircleLines0(x, y, dx, dy: LongInt);
var i: LongInt;
begin
if ((y + dy) and $FFFFFC00) = 0 then
   for i:= max(x - dx, 0) to min(x + dx, 2047) do ClearLandPixel(y + dy, i);
if ((y - dy) and $FFFFFC00) = 0 then
   for i:= max(x - dx, 0) to min(x + dx, 2047) do ClearLandPixel(y - dy, i);
if ((y + dx) and $FFFFFC00) = 0 then
   for i:= max(x - dy, 0) to min(x + dy, 2047) do ClearLandPixel(y + dx, i);
if ((y - dx) and $FFFFFC00) = 0 then
   for i:= max(x - dy, 0) to min(x + dy, 2047) do ClearLandPixel(y - dx, i);
end;

procedure FillLandCircleLinesEBC(x, y, dx, dy: LongInt);
var i: LongInt;
begin
if ((y + dy) and $FFFFFC00) = 0 then
   for i:= max(x - dx, 0) to min(x + dx, 2047) do
       if Land[y + dy, i] = COLOR_LAND then SetLandPixel(y + dy, i);
if ((y - dy) and $FFFFFC00) = 0 then
   for i:= max(x - dx, 0) to min(x + dx, 2047) do
       if Land[y - dy, i] = COLOR_LAND then SetLandPixel(y - dy, i);
if ((y + dx) and $FFFFFC00) = 0 then
   for i:= max(x - dy, 0) to min(x + dy, 2047) do
       if Land[y + dx, i] = COLOR_LAND then SetLandPixel(y + dx, i);
if ((y - dx) and $FFFFFC00) = 0 then
   for i:= max(x - dy, 0) to min(x + dy, 2047) do
       if Land[y - dx, i] = COLOR_LAND then SetLandPixel(y - dx, i);
end;

procedure DrawExplosion(X, Y, Radius: LongInt);
var dx, dy, d: LongInt;
begin
FillRoundInLand(X, Y, Radius, 0);

if SDL_MustLock(LandSurface) then
   SDLTry(SDL_LockSurface(LandSurface) >= 0, true);

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

if SDL_MustLock(LandSurface) then
   SDL_UnlockSurface(LandSurface);
end;

procedure DrawHLinesExplosions(ar: PRangeArray; Radius: LongInt; y, dY: LongInt; Count: Byte);
var tx, ty, i: LongInt;
begin
if SDL_MustLock(LandSurface) then
   SDL_LockSurface(LandSurface);

for i:= 0 to Pred(Count) do
    begin
    for ty:= max(y - Radius, 0) to min(y + Radius, 1023) do
        for tx:= max(0, ar^[i].Left - Radius) to min(2047, ar^[i].Right + Radius) do
            ClearLandPixel(ty, tx);
    inc(y, dY)
    end;

inc(Radius, 4);
dec(y, Count * dY);

for i:= 0 to Pred(Count) do
    begin
    for ty:= max(y - Radius, 0) to min(y + Radius, 1023) do
        for tx:= max(0, ar^[i].Left - Radius) to min(2047, ar^[i].Right + Radius) do
            if Land[ty, tx] = $FFFFFF then
                  SetLandPixel(ty, tx);
    inc(y, dY)
    end;

if SDL_MustLock(LandSurface) then
   SDL_UnlockSurface(LandSurface);
end;

//
//  - (dX, dY) - direction, vector of length = 0.5
//
procedure DrawTunnel(X, Y, dX, dY: hwFloat; ticks, HalfWidth: LongInt);
var nx, ny, dX8, dY8: hwFloat;
    i, t, tx, ty: Longint;
begin  // (-dY, dX) is (dX, dY) rotated by PI/2
if SDL_MustLock(LandSurface) then
   SDL_LockSurface(LandSurface);

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
           begin
           Land[ty, tx]:= 0;
           ClearLandPixel(ty, tx);
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

if SDL_MustLock(LandSurface) then
   SDL_UnlockSurface(LandSurface)
end;


end.
