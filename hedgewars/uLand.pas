(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * Distributed under the terms of the BSD-modified licence:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * with the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *)

unit uLand;
interface
uses SDLh;
{$include options.inc}
type TLandArray = packed array[0..1023, 0..2047] of LongWord;

var  Land: TLandArray;
     LandSurface: PSDL_Surface;

procedure GenLandSurface;
procedure MakeFortsMap;
procedure AddHHPoint(_x, _y: integer);
procedure GetHHPoint(out _x, _y: integer);
procedure RandomizeHHPoints;

implementation
uses uConsole, uStore, uMisc, uConsts, uRandom, uTeams, uIO;

type TPixAr = record
              Count: Longword;
              ar: array[0..Pred(cMaxEdgePoints)] of TPoint;
              end;

var HHPoints: record
              First, Last: word;
              ar: array[1..Pred(cMaxSpawnPoints)] of TPoint
              end = (First: 1);

procedure BlitImageAndGenerateCollisionInfo(cpX, cpY: Longword; Image, Surface: PSDL_Surface);
var i, p: LongWord;
    x, y: Longword;
    bpp: integer;
    r: TSDL_Rect;
begin
r.x:= cpX;
r.y:= cpY;
SDL_UpperBlit(Image, nil, Surface, @r);
WriteToConsole('Generating collision info... ');

if SDL_MustLock(Image) then
   SDLTry(SDL_LockSurface(Image) >= 0, true);

bpp:= Image.format.BytesPerPixel;
WriteToConsole('('+inttostr(bpp)+') ');
p:= LongWord(Image.pixels);
case bpp of
     1: OutError('We don''t work with 8 bit surfaces', true);
     2: for y:= 0 to Pred(Image.h) do
            begin
            i:= Longword(@Land[cpY + y, cpX]);
            for x:= 0 to Pred(Image.w) do
                if PWord(p + x * 2)^ = 0 then PLongWord(i + x * 4)^:= 0
                                         else PLongWord(i + x * 4)^:= 1;
            inc(p, Image.pitch);
            end;
     3: for y:= 0 to Pred(Image.h) do
            begin
            i:= Longword(@Land[cpY + y, cpX]);
            for x:= 0 to Pred(Image.w) do
                if  (PByte(p + x * 3 + 0)^ = 0)
                and (PByte(p + x * 3 + 1)^ = 0)
                and (PByte(p + x * 3 + 2)^ = 0) then PLongWord(i + x * 4)^:= 0
                                                else PLongWord(i + x * 4)^:= 1;
            inc(p, Image.pitch);
            end;
     4: for y:= 0 to Pred(Image.h) do
            begin
            i:= Longword(@Land[cpY + y, cpX]);
            for x:= 0 to Pred(Image.w) do
                if PLongword(p + x * 4)^ = 0 then PLongWord(i + x * 4)^:= 0
                                             else PLongWord(i + x * 4)^:= 1;
            inc(p, Image.pitch);
            end;
     end;
if SDL_MustLock(Image) then
   SDL_UnlockSurface(Image);
WriteLnToConsole(msgOK)
end;

procedure GenEdge(TemplateType: Longword; out pa: TPixAr);
const Template0: array[0..4] of TPoint = (
                                         (x:  500; y: 1500),
                                         (x:  350; y:  400),
                                         (x: 1023; y:  800),
                                         (x: 1700; y:  400),
                                         (x: 1550; y: 1500)
                                         );
var i: integer;
begin
pa.Count:= Succ(High(Template0));
for i:= 0 to High(Template0) do
    pa.ar[i]:= Template0[i]
end;

procedure DrawBezierEdge(var pa: TPixAr);
var x, y, i: integer;
    tx, ty, vx, vy, vlen, t: real;
    r1, r2, r3, r4: real;
    x1, y1, x2, y2, cx1, cy1, cx2, cy2, tsq, tcb: real;
begin
vx:= 0;
vy:= 0;
with pa do
for i:= 0 to Count-2 do
    begin
    vlen:= sqrt(sqr(ar[i + 1].x - ar[i    ].X) + sqr(ar[i + 1].y - ar[i    ].y));
    t:=    sqrt(sqr(ar[i + 1].x - ar[i + 2].X) + sqr(ar[i + 1].y - ar[i + 2].y));
    if t<vlen then vlen:= t;
    vlen:= vlen/3;
    tx:= ar[i+2].X - ar[i].X;
    ty:= ar[i+2].y - ar[i].y;
    t:= sqrt(sqr(tx)+sqr(ty));
    if t = 0 then
       begin
       tx:= -tx * 100000;
       ty:= -ty * 100000;
       end else
       begin
       tx:= -tx/t;
       ty:= -ty/t;
       end;
    t:= 1.0*vlen;
    tx:= tx*t;
    ty:= ty*t;
    x1:= ar[i].x;
    y1:= ar[i].y;
    x2:= ar[i + 1].x;
    y2:= ar[i + 1].y;
    cx1:= ar[i].X   + trunc(vx);
    cy1:= ar[i].y   + trunc(vy);
    cx2:= ar[i+1].X + trunc(tx);
    cy2:= ar[i+1].y + trunc(ty);
    vx:= -tx;
    vy:= -ty;
    t:= 0;
    while t <= 1.0 do
          begin
          tsq:= sqr(t);
          tcb:= tsq * t;
          r1:= (1 - 3*t + 3*tsq -   tcb) * x1;
          r2:= (    3*t - 6*tsq + 3*tcb) * cx1;
          r3:= (          3*tsq - 3*tcb) * cx2;
          r4:= (                    tcb) * x2;
          X:= round(r1 + r2 + r3 + r4);
          r1:= (1 - 3*t + 3*tsq -   tcb) * y1;
          r2:= (    3*t - 6*tsq + 3*tcb) * cy1;
          r3:= (          3*tsq - 3*tcb) * cy2;
          r4:= (                    tcb) * y2;
          Y:= round(r1 + r2 + r3 + r4);
          t:= t + 0.001;
          if ((x and $FFFFF800) = 0) and ((y and $FFFFFC00) = 0) then
                Land[y, x]:= $FFFFFF;
          end;
    end;
end;

procedure BezierizeEdge(var pa: TPixAr; Delta: real);
var x, y, i: integer;
    tx, ty, vx, vy, vlen, t: real;
    r1, r2, r3, r4: real;
    x1, y1, x2, y2, cx1, cy1, cx2, cy2, tsq, tcb: real;
    opa: TPixAr;
begin
opa:= pa;
pa.Count:= 0;
vx:= 0;
vy:= 0;
with opa do
for i:= 0 to Count-2 do
    begin
    vlen:= sqrt(sqr(ar[i + 1].x - ar[i    ].X) + sqr(ar[i + 1].y - ar[i    ].y));
    t:=    sqrt(sqr(ar[i + 1].x - ar[i + 2].X) + sqr(ar[i + 1].y - ar[i + 2].y));
    if t<vlen then vlen:= t;
    vlen:= vlen/3;
    tx:= ar[i+2].X - ar[i].X;
    ty:= ar[i+2].y - ar[i].y;
    t:= sqrt(sqr(tx)+sqr(ty));
    if t = 0 then
       begin
       tx:= -tx * 100000;
       ty:= -ty * 100000;
       end else
       begin
       tx:= -tx/t;
       ty:= -ty/t;
       end;
    t:= 1.0*vlen;
    tx:= tx*t;
    ty:= ty*t;
    x1:= ar[i].x;
    y1:= ar[i].y;
    x2:= ar[i + 1].x;
    y2:= ar[i + 1].y;
    cx1:= ar[i].X   + trunc(vx);
    cy1:= ar[i].y   + trunc(vy);
    cx2:= ar[i+1].X + trunc(tx);
    cy2:= ar[i+1].y + trunc(ty);
    vx:= -tx;
    vy:= -ty;
    t:= 0;
    while t <= 1.0 do
          begin
          tsq:= sqr(t);
          tcb:= tsq * t;
          r1:= (1 - 3*t + 3*tsq -   tcb) * x1;
          r2:= (    3*t - 6*tsq + 3*tcb) * cx1;
          r3:= (          3*tsq - 3*tcb) * cx2;
          r4:= (                    tcb) * x2;
          X:= round(r1 + r2 + r3 + r4);
          r1:= (1 - 3*t + 3*tsq -   tcb) * y1;
          r2:= (    3*t - 6*tsq + 3*tcb) * cy1;
          r3:= (          3*tsq - 3*tcb) * cy2;
          r4:= (                    tcb) * y2;
          Y:= round(r1 + r2 + r3 + r4);
          t:= t + Delta;
          pa.ar[pa.Count].x:= X;
          pa.ar[pa.Count].y:= Y;
          inc(pa.Count);
          TryDo(pa.Count < cMaxEdgePoints, 'Edge points overflow', true)
          end;
    end;
end;

procedure FillLand(x, y: integer);
var Stack: record
           Count: Longword;
           points: array[0..8192] of record
                                     xl, xr, y, dir: integer;
                                     end
           end;

    procedure Push(_xl, _xr, _y, _dir: integer);
    begin
    _y:= _y + _dir;
    if (_y < 0) or (_y > 1023) then exit;
    with Stack.points[Stack.Count] do
         begin
         xl:= _xl;
         xr:= _xr;
         y:= _y;
         dir:= _dir
         end;
    inc(Stack.Count);
    TryDo(Stack.Count < 8192, 'stack overflow', true)
    end;

    procedure Pop(out _xl, _xr, _y, _dir: integer);
    begin
    dec(Stack.Count);
    with Stack.points[Stack.Count] do
         begin
         _xl:= xl;
         _xr:= xr;
         _y:= y;
         _dir:= dir
         end
    end;

var xl, xr, dir: integer;
begin
Stack.Count:= 0;
xl:= x - 1;
xr:= x;
Push(xl, xr, 1024, -1);
while Stack.Count > 0 do
      begin
      Pop(xl, xr, y, dir);
      while (xl > 0) and (Land[y, xl] = 0) do dec(xl);
      while (xr < 2047) and (Land[y, xr] = 0) do inc(xr);
      while (xl < xr) do
            begin
            while (xl <= xr) and (Land[y, xl] <> 0) do inc(xl);
            x:= xl;
            while (xl <= xr) and (Land[y, xl] = 0) do
                  begin
                  Land[y, xl]:= $FFFFFF;
                  inc(xl)
                  end;
            if x < xl then
               begin
               Push(x, Pred(xl), y, dir);
               Push(x, Pred(xl), y,-dir);
               end;
            end;
      end;
end;

procedure ColorizeLand(Surface: PSDL_Surface);
var tmpsurf: PSDL_Surface;
    r: TSDL_Rect;
begin
tmpsurf:= LoadImage(Pathz[ptThemeCurrent] + 'LandTex.png');
r.y:= 0;
while r.y < 1024 do
      begin
      r.x:= 0;
      while r.x < 2048 do
            begin
            SDL_UpperBlit(tmpsurf, nil, Surface, @r);
            inc(r.x, tmpsurf.w)
            end;
      inc(r.y, tmpsurf.h)
      end;
SDL_FreeSurface(tmpsurf);

tmpsurf:= SDL_CreateRGBSurfaceFrom(@Land, 2048, 1024, 32, 2048*4, $FF0000, $FF00, $FF, 0);
SDLTry(tmpsurf <> nil, true);
SDL_SetColorKey(tmpsurf, SDL_SRCCOLORKEY, SDL_MapRGB(tmpsurf.format, $FF, $FF, $FF));
SDL_UpperBlit(tmpsurf, nil, Surface, nil);
SDL_FreeSurface(tmpsurf)
end;

procedure AddBorder(Surface: PSDL_Surface);
var tmpsurf: PSDL_Surface;
    r, rr: TSDL_Rect;
    x, yd, yu: integer;
begin
tmpsurf:= LoadImage(Pathz[ptThemeCurrent] + 'Border.png');
for x:= 0 to 2047 do
    begin
    yd:= 1023;
    repeat
      while (yd > 0   ) and (Land[yd, x] =  0) do dec(yd);
      if (yd < 0) then yd:= 0;
      while (yd < 1024) and (Land[yd, x] <> 0) do inc(yd);
      dec(yd);
      yu:= yd;
      while (yu > 0  ) and (Land[yu, x] <> 0) do dec(yu);
      while (yu < yd ) and (Land[yu, x] =  0) do inc(yu);
      if (yd < 1023) and ((yd - yu) >= 16) then
         begin
         rr.x:= x;
         rr.y:= yd - 15;
         r.x:= x mod tmpsurf.w;
         r.y:= 16;
         r.w:= 1;
         r.h:= 16;
         SDL_UpperBlit(tmpsurf, @r, Surface, @rr);
         end;
      if (yu > 0) then
         begin
         rr.x:= x;
         rr.y:= yu;
         r.x:= x mod tmpsurf.w;
         r.y:= 0;
         r.w:= 1;
         r.h:= min(16, yd - yu + 1);
         SDL_UpperBlit(tmpsurf, @r, Surface, @rr);
         end;
      yd:= yu - 1;
    until yd < 0;
    end;
end;

procedure AddGirders(Surface: PSDL_Surface);
var tmpsurf: PSDL_Surface;
    x1, x2, y, k, i: integer;
    r, rr: TSDL_Rect;

    function CountNonZeroz(x, y: integer): Longword;
    var i: integer;
    begin
    Result:= 0;
    for i:= y to y + 15 do
        if Land[i, x] <> 0 then inc(Result)
    end;

begin
y:= 256;
repeat
  inc(y, 24);
  x1:= 1024;
  x2:= 1024;
  while (x1 > 100) and (CountNonZeroz(x1, y) = 0) do dec(x1, 2);
  i:= x1 - 12;
  repeat
    k:= CountNonZeroz(x1, y);
    dec(x1, 2)
  until (x1 < 100) or (k = 0) or (k = 16) or (x1 < i);
  inc(x1, 2);
  if k = 16 then
     begin
     while (x2 < 1900) and (CountNonZeroz(x2, y) = 0) do inc(x2, 2);
     i:= x2 + 12;
     repeat
       k:= CountNonZeroz(x2, y);
       inc(x2, 2)
     until (x2 > 1900) or (k = 0) or (k = 16) or (x2 > i);
     if (x2 < 1900) and (k = 16) and (x2 - x1 > 250) then break;
     end;
x1:= 0;
until y > 900;
if x1 > 0 then
   begin
   tmpsurf:= LoadImage(Pathz[ptGraphics] + 'Girder.png');
   rr.x:= x1;
   rr.y:= y;
   while rr.x + 100 < x2 do
         begin
         SDL_UpperBlit(tmpsurf, nil, Surface, @rr);
         inc(rr.x, 100);
         end;
   r.x:= 0;
   r.y:= 0;
   r.w:= x2 - rr.x;
   r.h:= 16;
   SDL_UpperBlit(tmpsurf, @r, Surface, @rr);
   SDL_FreeSurface(tmpsurf);
   for k:= y to y + 15 do
       for i:= x1 to x2 do Land[k, i]:= $FFFFFF
   end
end;

procedure AddHHPoints;
var x, y, t: integer;

    function CountNonZeroz(x, y: integer): integer;
    var i: integer;
    begin
    Result:= 0;
    if (y and $FFFFFC00) <> 0 then exit;
    for i:= max(x - 6, 0) to min(x + 6, 2043) do
        if Land[y, i] <> 0 then inc(Result)
    end;

begin
x:= 40;
while x < 2010 do
    begin
    y:= -24;
    while y < 1023 do
          begin
          repeat
          inc(y, 2);
          until (y > 1023) or (CountNonZeroz(x, y) = 0);
          t:= 0;
          repeat
          inc(y, 2);
          inc(t, 2)
          until (y > 1023) or (CountNonZeroz(x, y) <> 0);
          if (t > 22) and (y < 1023) then AddHHPoint(x, y - 12);
          inc(y, 100)
          end;
    inc(x, 120)
    end;

if HHPoints.Last < cMaxHHs then
   begin
   AddHHPoint(300, 800);
   AddHHPoint(400, 800);
   AddHHPoint(500, 800);
   AddHHPoint(600, 800);
   AddHHPoint(700, 800);
   AddHHPoint(800, 800);
   AddHHPoint(900, 800);
   AddHHPoint(1000, 800);
   AddHHPoint(1100, 800);
   AddHHPoint(1200, 800);
   AddHHPoint(1300, 800);
   AddHHPoint(1400, 800);
   end;
end;

procedure PointWave(var pa: TPixAr; PassesNum: Longword);
const MAXPASSES = 8;
var ar: array[0..Pred(MAXPASSES) - 1, 0..5] of real;
    i, k: integer;
    rx, ry, oy: real;
begin
TryDo(PassesNum < MAXPASSES, 'Passes number too big', true);
for i:= 0 to Pred(PassesNum) do  // initialize random parameters
    begin
    ar[i, 0]:= 20 + getrandom(45);
    ar[i, 1]:= 0.005 + getrandom * 0.015;
    ar[i, 2]:= getrandom * pi * 2;
    ar[i, 3]:= 20 + getrandom(45);
    ar[i, 4]:= 0.005 + getrandom * 0.015;
    ar[i, 5]:= getrandom * pi * 2;
    end;

for k:= 0 to Pred(pa.Count) do  // apply transformation
    begin
    rx:= pa.ar[k].x;
    ry:= pa.ar[k].y;
    for i:= 0 to Pred(PassesNum) do
        begin
        oy:= ry;
        ry:= ry + ar[i, 0] * sin(ar[i, 1] * rx + ar[i, 2]);
        rx:= rx + ar[i, 3] * sin(ar[i, 4] * oy + ar[i, 5]);
        end;
        pa.ar[k].x:= round(rx);
        pa.ar[k].y:= round(ry);
        end;
end;

procedure GenLandSurface;
var pa: TPixAr;
    tmpsurf: PSDL_Surface;
begin
GenEdge(0, pa);
BezierizeEdge(pa, 0.33334);
BezierizeEdge(pa, 0.33334);
BezierizeEdge(pa, 0.33334); 
PointWave(pa, 3);
DrawBezierEdge(pa);
FillLand(1023, 1023);

AddProgress;
with PixelFormat^ do
     tmpsurf:= SDL_CreateRGBSurface(SDL_HWSURFACE, 2048, 1024, BitsPerPixel, RMask, GMask, BMask, 0);
ColorizeLand(tmpsurf);
AddProgress;
AddBorder(tmpsurf);
with PixelFormat^ do
     LandSurface:= SDL_CreateRGBSurface(SDL_HWSURFACE, 2048, 1024, BitsPerPixel, RMask, GMask, BMask, 0);
SDL_FillRect(LandSurface, nil, 0);
AddGirders(LandSurface);
SDL_SetColorKey(tmpsurf, SDL_SRCCOLORKEY, 0);
SDL_UpperBlit(tmpsurf, nil, LandSurface, nil);
SDL_FreeSurface(tmpsurf);
AddProgress;
AddHHPoints;
RandomizeHHPoints;
end;

procedure MakeFortsMap;
var p: PTeam;
    tmpsurf: PSDL_Surface;
begin
p:= TeamsList;
TryDo(p <> nil, 'No teams on map!', true);
with PixelFormat^ do
     LandSurface:= SDL_CreateRGBSurface(SDL_HWSURFACE, 2048, 1024, BitsPerPixel, RMask, GMask, BMask, 0);
tmpsurf:= LoadImage(Pathz[ptForts] + p.FortName + 'L.png');
BlitImageAndGenerateCollisionInfo(0, 0, tmpsurf, LandSurface);
SDL_FreeSurface(tmpsurf);
LoadFortPoints(p.FortName, false, TeamSize(p));
p:= p.Next;
TryDo(p <> nil, 'Only one team on map!', true);
tmpsurf:= LoadImage(Pathz[ptForts] + p.FortName + 'R.png');
BlitImageAndGenerateCollisionInfo(1024, 0, tmpsurf, LandSurface);
SDL_FreeSurface(tmpsurf);
LoadFortPoints(p.FortName, true, TeamSize(p));
p:= p.Next;
TryDo(p = nil, 'More than 2 teams on map in forts mode!', true);
end;

procedure AddHHPoint(_x, _y: integer);
begin
with HHPoints do
     begin
     inc(Last);
     TryDo(Last < cMaxSpawnPoints, 'HHs coords queue overflow', true);
     with ar[Last] do
          begin
          x:= _x;
          y:= _y
          end
     end
end;

procedure GetHHPoint(out _x, _y: integer);
begin
with HHPoints do
     begin
     TryDo(First <= Last, 'HHs coords queue underflow ' + inttostr(First), true);
     with ar[First] do
          begin
          _x:= x;
          _y:= y
          end;
     inc(First)
     end
end;

procedure RandomizeHHPoints;
var i, t: integer;
    p: TPoint;
begin
with HHPoints do
     begin
     for i:= First to Last do
         begin
         t:= GetRandom(Last - First + 1) + First;
         if i <> t then
            begin
            p:= ar[i];
            ar[i]:= ar[t];
            ar[t]:= p
            end
         end
     end
end;

end.
