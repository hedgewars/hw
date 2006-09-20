(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
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
uses SDLh, uGears, uLandTemplates;
{$include options.inc}
type TLandArray = packed array[0..1023, 0..2047] of LongWord;
     TPreview = packed array[0..127, 0..31] of byte;

var  Land: TLandArray;
     LandSurface: PSDL_Surface;
     Preview: TPreview;

procedure GenMap;
procedure GenPreview;


implementation
uses uConsole, uStore, uMisc, uConsts, uRandom, uTeams, uIO, uLandObjects;

type TPixAr = record
              Count: Longword;
              ar: array[0..Pred(cMaxEdgePoints)] of TPoint;
              end;

procedure LogLandDigest;
//var ctx: TSHA1Context;
//    dig: TSHA1Digest;
begin
//SHA1Init(ctx);
//SHA1Update(ctx, @Land, sizeof(Land));
//dig:= SHA1Final(ctx);
{$IFDEF DEBUGFILE}
//AddFileLog('SHA1 Land digest: {'+inttostr(dig.LongWords[0])+':'
//           +inttostr(dig.LongWords[1])+':'+inttostr(dig.LongWords[2])+':'
//           +inttostr(dig.LongWords[3])+':'+inttostr(dig.LongWords[4])+'}');
{$ENDIF}
end;

procedure DrawBezierEdge(var pa: TPixAr; Color: Longword);
var x, y, i: integer;
    tx, ty, vx, vy, vlen, t: Double;
    r1, r2, r3, r4: Double;
    x1, y1, x2, y2, cx1, cy1, cx2, cy2, tsq, tcb: Double;
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
                Land[y, x]:= Color;
          end;
    end;
end;

procedure BezierizeEdge(var pa: TPixAr; Delta: Double);
var x, y, i: integer;
    tx, ty, vx, vy, vlen, t: Double;
    r1, r2, r3, r4: Double;
    x1, y1, x2, y2, cx1, cy1, cx2, cy2, tsq, tcb: Double;
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
    TryDo(Stack.Count <= 8192, 'FillLand: stack overflow', true);
    _y:= _y + _dir;
    if (_y < 0) or (_y > 1023) then exit;
    with Stack.points[Stack.Count] do
         begin
         xl:= _xl;
         xr:= _xr;
         y:= _y;
         dir:= _dir
         end;
    inc(Stack.Count)
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
Push(xl, xr, y, -1);
Push(xl, xr, y,  1);
while Stack.Count > 0 do
      begin
      Pop(xl, xr, y, dir);
      while (xl > 0) and (Land[y, xl] <> 0) do dec(xl);
      while (xr < 2047) and (Land[y, xr] <> 0) do inc(xr);
      while (xl < xr) do
            begin
            while (xl <= xr) and (Land[y, xl] = 0) do inc(xl);
            x:= xl;
            while (xl <= xr) and (Land[y, xl] <> 0) do
                  begin
                  Land[y, xl]:= 0;
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
tmpsurf:= LoadImage(Pathz[ptCurrTheme] + '/LandTex', false);
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
tmpsurf:= LoadImage(Pathz[ptCurrTheme] + '/Border', false);
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

procedure PointWave(var Template: TEdgeTemplate; var pa: TPixAr);
const MAXPASSES = 32;
var ar: array[0..MAXPASSES, 0..5] of Double;
    i, k: integer;
    rx, ry, oy: Double;
    PassesNum: Longword;
begin
with Template do
     begin
     PassesNum:= PassMin + getrandom(PassDelta);
     TryDo(PassesNum < MAXPASSES, 'Passes number too big', true);
     ar[0, 1]:= WaveFreqMin;
     ar[0, 4]:= WaveFreqMin;
     for i:= 1 to PassesNum do  // initialize random parameters
         begin
         ar[i, 0]:= WaveAmplMin + getrandom * WaveAmplDelta;
         ar[i, 1]:= ar[i - 1, 1] + (getrandom * 0.7 + 0.3) * WaveFreqDelta;
         ar[i, 2]:= getrandom * pi * 2;
         ar[i, 3]:= WaveAmplMin + getrandom * WaveAmplDelta;
         ar[i, 4]:= ar[i - 1, 4] + (getrandom * 0.7 + 0.3) * WaveFreqDelta;
         ar[i, 5]:= getrandom * pi * 2;
         {$IFDEF DEBUGFILE}
         AddFileLog('Wave params ¹' + inttostr(i) + ':');
         AddFileLog('X: ampl = ' + floattostr(ar[i, 0]) + '; freq = ' + floattostr(ar[i, 1]) + '; shift = ' + floattostr(ar[i, 2]));
         AddFileLog('Y: ampl = ' + floattostr(ar[i, 3]) + '; freq = ' + floattostr(ar[i, 4]) + '; shift = ' + floattostr(ar[i, 5]));
         {$ENDIF}
         end;
     end;

for k:= 0 to Pred(pa.Count) do  // apply transformation
    begin
    rx:= pa.ar[k].x;
    ry:= pa.ar[k].y;
    for i:= 1 to PassesNum do
        begin
        oy:= ry;
        ry:= ry + ar[i, 0] * sin(ar[i, 1] * rx + ar[i, 2]);
        rx:= rx + ar[i, 3] * sin(ar[i, 4] * oy + ar[i, 5]);
        end;
    pa.ar[k].x:= round(rx);
    pa.ar[k].y:= round(ry);
    end;
end;

procedure NormalizePoints(var pa: TPixAr);
const brd = 32;
var isUP: boolean;  // HACK: transform for Y should be exact as one for X  
    Left, Right, Top, Bottom,
    OWidth, Width, OHeight, Height,
    OLeft: integer;
    i: integer;
begin
TryDo((pa.ar[0].y < 0) or (pa.ar[0].y > 1023), 'Bad land generated', true);
isUP:= pa.ar[0].y > 0;
Left:= 1023;
Right:= Left;
Top:= pa.ar[0].y;
Bottom:= Top;

for i:= 1 to Pred(pa.Count) do
    with pa.ar[i] do
         begin
         if (y and $FFFFFC00) = 0 then
            if x < Left then Left:= x else
            if x > Right then Right:= x;
         if y < Top then Top:= y else
         if y > Bottom then Bottom:= y
         end;

if (Left < brd) or (Right > 2047 - brd) then
   begin
   OLeft:= Left;
   OWidth:= Right - OLeft;
   if Left < brd then Left:= brd;
   if Right > 2047 - brd then Right:= 2047 - brd;
   Width:= Right - Left;
   for i:= 0 to Pred(pa.Count) do
       with pa.ar[i] do
            x:= round((x - OLeft) * Width div OWidth + Left)
   end;

if isUp then // FIXME: remove hack
   if Top < brd then
      begin
      OHeight:= 1023 - Top;
      Height:= 1023 - brd;
      for i:= 0 to Pred(pa.Count) do
          with pa.ar[i] do
               y:= round((y - 1023) * Height div OHeight + 1023)
   end;
end;

procedure GenBlank(var Template: TEdgeTemplate);
var pa: TPixAr;
    i: Longword;
    y, x: Longword;
begin
for y:= 0 to 1023 do
    for x:= 0 to 2047 do
        Land[y, x]:= COLOR_LAND;

with Template do
     begin
     if canMirror then
        if getrandom(16) < 8 then
           begin
           for i:= 0 to pred(BasePointsCount) do
               BasePoints^[i].x:= 2047 - BasePoints^[i].x;
           for i:= 0 to pred(FillPointsCount) do
               FillPoints^[i].x:= 2047 - FillPoints^[i].x;
           end;

     if canFlip then
        if getrandom(16) < 8 then
           begin
           for i:= 0 to pred(BasePointsCount) do
               BasePoints^[i].y:= 1023 - BasePoints^[i].y;
           for i:= 0 to pred(FillPointsCount) do
               FillPoints^[i].y:= 1023 - FillPoints^[i].y;
           end;

     pa.Count:= BasePointsCount;
     for i:= 0 to pred(pa.Count) do
         pa.ar[i]:= BasePoints^[i];

     for i:= 1 to BezPassCnt do
         BezierizeEdge(pa, 0.33333334);

     PointWave(Template, pa);
     NormalizePoints(pa);
     DrawBezierEdge(pa, 0);

     for i:= 0 to pred(FillPointsCount) do
         with FillPoints^[i] do
              FillLand(x, y);

     DrawBezierEdge(pa, COLOR_LAND);
     end;
end;

procedure GenLandSurface;
var tmpsurf: PSDL_Surface;
begin
WriteLnToConsole('Generating land...');

GenBlank(EdgeTemplates[getrandom(Succ(High(EdgeTemplates)))]);

AddProgress;
with PixelFormat^ do
     tmpsurf:= SDL_CreateRGBSurface(SDL_HWSURFACE, 2048, 1024, BitsPerPixel, RMask, GMask, BMask, 0);
TryDo(tmpsurf <> nil, 'Error creating pre-land surface', true);
ColorizeLand(tmpsurf);
AddProgress;
AddBorder(tmpsurf);
with PixelFormat^ do
     LandSurface:= SDL_CreateRGBSurface(SDL_HWSURFACE, 2048, 1024, BitsPerPixel, RMask, GMask, BMask, 0);
TryDo(LandSurface <> nil, 'Error creating land surface', true);
SDL_FillRect(LandSurface, nil, 0);
AddProgress;

SDL_SetColorKey(tmpsurf, SDL_SRCCOLORKEY, 0);
AddObjects(tmpsurf, LandSurface);
SDL_FreeSurface(tmpsurf);

AddProgress
end;

procedure MakeFortsMap;
var p: PTeam;
    tmpsurf: PSDL_Surface;
begin
WriteLnToConsole('Generating forts land...');
p:= TeamsList;
TryDo(p <> nil, 'No teams on map!', true);
with PixelFormat^ do
     LandSurface:= SDL_CreateRGBSurface(SDL_HWSURFACE, 2048, 1024, BitsPerPixel, RMask, GMask, BMask, 0);
SDL_FillRect(LandSurface, nil, 0);
tmpsurf:= LoadImage(Pathz[ptForts] + '/' + p.FortName + 'L', false);
BlitImageAndGenerateCollisionInfo(0, 0, tmpsurf, LandSurface);
SDL_FreeSurface(tmpsurf);
p:= p.Next;
TryDo(p <> nil, 'Only one team on map!', true);
tmpsurf:= LoadImage(Pathz[ptForts] + '/' + p.FortName + 'R', false);
BlitImageAndGenerateCollisionInfo(1024, 0, tmpsurf, LandSurface);
SDL_FreeSurface(tmpsurf);
p:= p.Next;
TryDo(p = nil, 'More than 2 teams on map in forts mode!', true);
end;

procedure LoadMap;
var x, y: Longword;
    p: PByteArray;
begin
WriteLnToConsole('Loading land from file...');
AddProgress;
LandSurface:= LoadImage(Pathz[ptMapCurrent] + '/map', false);
TryDo((LandSurface.w = 2048) and (LandSurface.h = 1024), 'Map dimensions should be 2048x1024!', true);

if SDL_MustLock(LandSurface) then
   SDLTry(SDL_LockSurface(LandSurface) >= 0, true);

p:= LandSurface.pixels;
case LandSurface.format.BytesPerPixel of
     1: OutError('We don''t work with 8 bit surfaces', true);
     2: for y:= 0 to 1023 do
            begin
            for x:= 0 to 2047 do
                if PWord(@p[x * 2])^ <> 0 then Land[y, x]:= COLOR_LAND;
            p:= @p[LandSurface.pitch];
            end;
     3: for y:= 0 to 1023 do
            begin
            for x:= 0 to 2047 do
                if  (p[x * 3 + 0] <> 0)
                 or (p[x * 3 + 1] <> 0)
                 or (p[x * 3 + 2] <> 0) then Land[y, x]:= COLOR_LAND;
            p:= @p[LandSurface.pitch];
            end;
     4: for y:= 0 to 1023 do
            begin
            for x:= 0 to 2047 do
                if PLongword(@p[x * 4])^ <> 0 then Land[y, x]:= COLOR_LAND;
            p:= @p[LandSurface.pitch];
            end;
     end;
if SDL_MustLock(LandSurface) then
   SDL_UnlockSurface(LandSurface);
end;

procedure GenMap;
begin
if (GameFlags and gfForts) = 0 then
   if Pathz[ptMapCurrent] <> '' then LoadMap
                                else GenLandSurface
                               else MakeFortsMap;
AddProgress;
{$IFDEF DEBUGFILE}LogLandDigest{$ENDIF}
end;

procedure GenPreview;
var x, y, xx, yy, t, bit: integer;
begin
GenBlank(EdgeTemplates[getrandom(Succ(High(EdgeTemplates)))]);

for y:= 0 to 127 do
    for x:= 0 to 31 do
        begin
        Preview[y, x]:= 0;
        for bit:= 0 to 7 do
            begin
            t:= 0;
            for yy:= y * 8 to y * 8 + 7 do
                for xx:= x * 64 + bit * 8 to x * 64 + bit * 8 + 7 do
                    if Land[yy, xx] <> 0 then inc(t);
            if t > 31 then Preview[y, x]:= Preview[y, x] or ($80 shr bit) 
            end
        end
end;

initialization

end.
