(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uLand;
interface
uses SDLh, uLandTemplates, uFloat;
{$include options.inc}
type TLandArray = packed array[0..1023, 0..2047] of LongWord;
     TPreview = packed array[0..127, 0..31] of byte;

var  Land: TLandArray;
     LandSurface: PSDL_Surface;
     Preview: TPreview;

procedure GenMap;
procedure GenPreview;


implementation
uses uConsole, uStore, uMisc, uConsts, uRandom, uTeams, uLandObjects, uSHA, uIO;

type TPixAr = record
              Count: Longword;
              ar: array[0..Pred(cMaxEdgePoints)] of TPoint;
              end;

procedure LogLandDigest;
var ctx: TSHA1Context;
    dig: TSHA1Digest;
    s: shortstring;
begin
SHA1Init(ctx);
SHA1Update(ctx, @Land, sizeof(Land));
dig:= SHA1Final(ctx);
s:= '{'+inttostr(dig[0])+':'
       +inttostr(dig[1])+':'
       +inttostr(dig[2])+':'
       +inttostr(dig[3])+':'
       +inttostr(dig[4])+'}';
SendIPC('M' + s)
end;

procedure DrawLine(X1, Y1, X2, Y2: integer; Color: Longword);
var
  eX, eY, dX, dY: integer;
  i, sX, sY, x, y, d: integer;
begin
eX:= 0;
eY:= 0;
dX:= X2 - X1;
dY:= Y2 - Y1;

if (dX > 0) then sX:= 1
else
  if (dX < 0) then
     begin
     sX:= -1;
     dX:= -dX
     end else sX:= dX;

if (dY > 0) then sY:= 1
  else
  if (dY < 0) then
     begin
     sY:= -1;
     dY:= -dY
     end else sY:= dY;

if (dX > dY) then d:= dX
             else d:= dY;

x:= X1;
y:= Y1;
 
for i:= 0 to d do
    begin
    inc(eX, dX);
    inc(eY, dY);
    if (eX > d) then
       begin
       dec(eX, d);
       inc(x, sX);
       end;
    if (eY > d) then
       begin
       dec(eY, d);
       inc(y, sY);
       end;

    if ((x and $FFFFF800) = 0) and ((y and $FFFFFC00) = 0) then
       Land[y, x]:= Color;
    end
end;

procedure DrawBezierEdge(var pa: TPixAr; Color: Longword);
const dT: hwFloat = (isNegative: false; QWordValue: 85899346);
var x, y, i, px, py: integer;
    tx, ty, vx, vy, vlen, t: hwFloat;
    r1, r2, r3, r4: hwFloat;
    x1, y1, x2, y2, cx1, cy1, cx2, cy2, tsq, tcb: hwFloat;
begin
vx:= 0;
vy:= 0;
with pa do
for i:= 0 to Count-2 do
    begin
    vlen:= Distance(ar[i + 1].x - ar[i].X, ar[i + 1].y - ar[i].y);
    t:=    Distance(ar[i + 1].x - ar[i + 2].X,ar[i + 1].y - ar[i + 2].y);
    if t<vlen then vlen:= t;
    vlen:= vlen * _1div3;
    tx:= ar[i+2].X - ar[i].X;
    ty:= ar[i+2].y - ar[i].y;
    t:= Distance(tx, ty);
    if t.QWordValue = 0 then
       begin
       tx:= -tx * 10000;
       ty:= -ty * 10000;
       end else
       begin
       t:= 1/t;
       tx:= -tx * t;
       ty:= -ty * t;
       end;
    t:= vlen;
    tx:= tx * t;
    ty:= ty * t;
    x1:= ar[i].x;
    y1:= ar[i].y;
    x2:= ar[i + 1].x;
    y2:= ar[i + 1].y;
    cx1:= ar[i].X   + hwRound(vx);
    cy1:= ar[i].y   + hwRound(vy);
    cx2:= ar[i+1].X + hwRound(tx);
    cy2:= ar[i+1].y + hwRound(ty);
    vx:= -tx;
    vy:= -ty;
    px:= hwRound(x1);
    py:= hwRound(y1);
    t:= dT;
    while t.Round = 0 do
          begin
          tsq:= t * t;
          tcb:= tsq * t;
          r1:= (1 - 3*t + 3*tsq -   tcb) * x1;
          r2:= (    3*t - 6*tsq + 3*tcb) * cx1;
          r3:= (          3*tsq - 3*tcb) * cx2;
          r4:= (                    tcb) * x2;
          X:= hwRound(r1 + r2 + r3 + r4);
          r1:= (1 - 3*t + 3*tsq -   tcb) * y1;
          r2:= (    3*t - 6*tsq + 3*tcb) * cy1;
          r3:= (          3*tsq - 3*tcb) * cy2;
          r4:= (                    tcb) * y2;
          Y:= hwRound(r1 + r2 + r3 + r4);
          t:= t + dT;
          DrawLine(px, py, x, y, Color);
          px:= x;
          py:= y
          end;
    DrawLine(px, py, hwRound(x2), hwRound(y2), Color)
    end;
end;

procedure BezierizeEdge(var pa: TPixAr; Delta: hwFloat);
var x, y, i: integer;
    tx, ty, vx, vy, vlen, t: hwFloat;
    r1, r2, r3, r4: hwFloat;
    x1, y1, x2, y2, cx1, cy1, cx2, cy2, tsq, tcb: hwFloat;
    opa: TPixAr;
begin
opa:= pa;
pa.Count:= 0;
vx:= 0;
vy:= 0;
with opa do
for i:= 0 to Count-2 do
    begin
    vlen:= Distance(ar[i + 1].x - ar[i].X, ar[i + 1].y - ar[i].y);
    t:=    Distance(ar[i + 1].x - ar[i + 2].X,ar[i + 1].y - ar[i + 2].y);
    if t<vlen then vlen:= t;
    vlen:= vlen * _1div3;
    tx:= ar[i+2].X - ar[i].X;
    ty:= ar[i+2].y - ar[i].y;
    t:= Distance(tx, ty);
    if t.QWordValue = 0 then
       begin
       tx:= -tx * 100000;
       ty:= -ty * 100000;
       end else
       begin
       t:= 1/t;
       tx:= -tx * t;
       ty:= -ty * t;
       end;
    t:= vlen;
    tx:= tx*t;
    ty:= ty*t;
    x1:= ar[i].x;
    y1:= ar[i].y;
    x2:= ar[i + 1].x;
    y2:= ar[i + 1].y;
    cx1:= ar[i].X   + hwRound(vx);
    cy1:= ar[i].y   + hwRound(vy);
    cx2:= ar[i+1].X + hwRound(tx);
    cy2:= ar[i+1].y + hwRound(ty);
    vx:= -tx;
    vy:= -ty;
    t:= 0;
    while t.Round = 0 do
          begin
          tsq:= t * t;
          tcb:= tsq * t;
          r1:= (1 - 3*t + 3*tsq -   tcb) * x1;
          r2:= (    3*t - 6*tsq + 3*tcb) * cx1;
          r3:= (          3*tsq - 3*tcb) * cx2;
          r4:= (                    tcb) * x2;
          X:= hwRound(r1 + r2 + r3 + r4);
          r1:= (1 - 3*t + 3*tsq -   tcb) * y1;
          r2:= (    3*t - 6*tsq + 3*tcb) * cy1;
          r3:= (          3*tsq - 3*tcb) * cy2;
          r4:= (                    tcb) * y2;
          Y:= hwRound(r1 + r2 + r3 + r4);
          t:= t + Delta;
          pa.ar[pa.Count].x:= X;
          pa.ar[pa.Count].y:= Y;
          inc(pa.Count);
          TryDo(pa.Count <= cMaxEdgePoints, 'Edge points overflow', true)
          end;
    end;
pa.ar[pa.Count].x:= opa.ar[Pred(opa.Count)].X;
pa.ar[pa.Count].y:= opa.ar[Pred(opa.Count)].Y;
inc(pa.Count)
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

    procedure Pop(var _xl, _xr, _y, _dir: integer);
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
tmpsurf:= LoadImage(Pathz[ptCurrTheme] + '/LandTex', false, true, true);
r.y:= 0;
while r.y < 1024 do
      begin
      r.x:= 0;
      while r.x < 2048 do
            begin
            SDL_UpperBlit(tmpsurf, nil, Surface, @r);
            inc(r.x, tmpsurf^.w)
            end;
      inc(r.y, tmpsurf^.h)
      end;
SDL_FreeSurface(tmpsurf);

tmpsurf:= SDL_CreateRGBSurfaceFrom(@Land, 2048, 1024, 32, 2048*4, $FF0000, $FF00, $FF, 0);
SDLTry(tmpsurf <> nil, true);
SDL_SetColorKey(tmpsurf, SDL_SRCCOLORKEY, SDL_MapRGB(tmpsurf^.format, $FF, $FF, $FF));
SDL_UpperBlit(tmpsurf, nil, Surface, nil);
SDL_FreeSurface(tmpsurf)
end;

procedure AddBorder(Surface: PSDL_Surface);
var tmpsurf: PSDL_Surface;
    r, rr: TSDL_Rect;
    x, yd, yu: integer;
begin
tmpsurf:= LoadImage(Pathz[ptCurrTheme] + '/Border', false, true, true);
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
         r.x:= x mod tmpsurf^.w;
         r.y:= 16;
         r.w:= 1;
         r.h:= 16;
         SDL_UpperBlit(tmpsurf, @r, Surface, @rr);
         end;
      if (yu > 0) then
         begin
         rr.x:= x;
         rr.y:= yu;
         r.x:= x mod tmpsurf^.w;
         r.y:= 0;
         r.w:= 1;
         r.h:= min(16, yd - yu + 1);
         SDL_UpperBlit(tmpsurf, @r, Surface, @rr);
         end;
      yd:= yu - 1;
    until yd < 0;
    end;
end;

procedure SetPoints(var Template: TEdgeTemplate; var pa: TPixAr);
var i: integer;
begin
with Template do
     begin
     pa.Count:= BasePointsCount;
     for i:= 0 to pred(pa.Count) do
         begin
         pa.ar[i].x:= BasePoints^[i].x + integer(GetRandom(BasePoints^[i].w));
         pa.ar[i].y:= BasePoints^[i].y + integer(GetRandom(BasePoints^[i].h))
         end;
         
     if canMirror then
        if getrandom(2) = 0 then
           begin
           for i:= 0 to pred(BasePointsCount) do
               pa.ar[i].x:= 2047 - pa.ar[i].x;
           for i:= 0 to pred(FillPointsCount) do
               FillPoints^[i].x:= 2047 - FillPoints^[i].x;
           end;

     if canFlip then
        if getrandom(2) = 0 then
           begin
           for i:= 0 to pred(BasePointsCount) do
               pa.ar[i].y:= 1023 - pa.ar[i].y;
           for i:= 0 to pred(FillPointsCount) do
               FillPoints^[i].y:= 1023 - FillPoints^[i].y;
           end;
     end
end;
(*
procedure NormalizePoints(var pa: TPixAr);
const brd = 32;
var isUP: boolean;  // HACK: transform for Y should be exact as one for X
    Left, Right, Top, Bottom,
    OWidth, Width, OHeight, Height,
    OLeft: integer;
    i: integer;
begin
TryDo((pa.ar[0].y < 0) or (pa.ar[0].y > 1023), 'Bad land generated', true);
TryDo((pa.ar[Pred(pa.Count)].y < 0) or (pa.ar[Pred(pa.Count)].y > 1023), 'Bad land generated', true);
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
end;*)

procedure RandomizePoints(var pa: TPixAr);
const cEdge = 55;
      cMinDist = 14;
var radz: array[0..Pred(cMaxEdgePoints)] of integer;
    i, k, dist: integer;
begin
radz[0]:= 0;
for i:= 0 to Pred(pa.Count) do
  with pa.ar[i] do
    begin
    radz[i]:= Min(Max(x - cEdge, 0), Max(2048 - cEdge - x, 0));
    radz[i]:= Min(radz[i], Min(Max(y - cEdge, 0), Max(1024 - cEdge - y, 0)));
    if radz[i] > 0 then
      for k:= 0 to Pred(i) do
        begin
        dist:= Min(Max(abs(x - pa.ar[k].x), abs(y - pa.ar[k].y)), 50);
        if radz[k] >= dist then
          begin
          radz[k]:= Max(0, dist - cMinDist * 2);
          radz[i]:= Min(dist - radz[k], radz[i])
          end;
        radz[i]:= Min(radz[i], dist)
      end
    end;

for i:= 0 to Pred(pa.Count) do
  with pa.ar[i] do
    if ((x and $FFFFF800) = 0) and ((y and $FFFFFC00) = 0) then
      begin
      x:= x + integer(GetRandom(radz[i] * 2 + 1)) - radz[i];
      y:= y + integer(GetRandom(radz[i] * 2 + 1)) - radz[i]
      end
end;


procedure GenBlank(var Template: TEdgeTemplate);
var pa: TPixAr;
    i: Longword;
    y, x: Longword;
begin
for y:= 0 to 1023 do
    for x:= 0 to 2047 do
        Land[y, x]:= COLOR_LAND;

SetPoints(Template, pa);
BezierizeEdge(pa, _1div3);
for i:= 0 to Pred(Template.RandPassesCount) do RandomizePoints(pa);
//NormalizePoints(pa);

DrawBezierEdge(pa, 0);

with Template do
     for i:= 0 to pred(FillPointsCount) do
         with FillPoints^[i] do
              FillLand(x, y);

DrawBezierEdge(pa, COLOR_LAND)
end;

function SelectTemplate: integer;
begin
SelectTemplate:= getrandom(Succ(High(EdgeTemplates)))
end;

procedure GenLandSurface;
var tmpsurf: PSDL_Surface;
begin
WriteLnToConsole('Generating land...');

GenBlank(EdgeTemplates[SelectTemplate]);

AddProgress;
with PixelFormat^ do
     tmpsurf:= SDL_CreateRGBSurface(SDL_HWSURFACE, 2048, 1024, BitsPerPixel, RMask, GMask, BMask, AMask);
TryDo(tmpsurf <> nil, 'Error creating pre-land surface', true);
ColorizeLand(tmpsurf);
AddProgress;
AddBorder(tmpsurf);
with PixelFormat^ do
     LandSurface:= SDL_CreateRGBSurface(SDL_HWSURFACE, 2048, 1024, BitsPerPixel, RMask, GMask, BMask, AMask);
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
     LandSurface:= SDL_CreateRGBSurface(SDL_HWSURFACE, 2048, 1024, BitsPerPixel, RMask, GMask, BMask, AMask);
SDL_FillRect(LandSurface, nil, 0);
tmpsurf:= LoadImage(Pathz[ptForts] + '/' + p^.FortName + 'L', false, true, true);
BlitImageAndGenerateCollisionInfo(0, 0, tmpsurf, LandSurface);
SDL_FreeSurface(tmpsurf);
p:= p^.Next;
TryDo(p <> nil, 'Only one team on map!', true);
tmpsurf:= LoadImage(Pathz[ptForts] + '/' + p^.FortName + 'R', false, true, true);
BlitImageAndGenerateCollisionInfo(1024, 0, tmpsurf, LandSurface);
SDL_FreeSurface(tmpsurf);
p:= p^.Next;
TryDo(p = nil, 'More than 2 teams on map in forts mode!', true);
end;

procedure LoadMap;
var x, y: Longword;
    p: PByteArray;
begin
WriteLnToConsole('Loading land from file...');
AddProgress;
LandSurface:= LoadImage(Pathz[ptMapCurrent] + '/map', false, true, true);
TryDo((LandSurface^.w = 2048) and (LandSurface^.h = 1024), 'Map dimensions should be 2048x1024!', true);

if SDL_MustLock(LandSurface) then
   SDLTry(SDL_LockSurface(LandSurface) >= 0, true);

p:= LandSurface^.pixels;
case LandSurface^.format^.BytesPerPixel of
     1: OutError('We don''t work with 8 bit surfaces', true);
     2: for y:= 0 to 1023 do
            begin
            for x:= 0 to 2047 do
                if PWord(@(p^[x * 2]))^ <> 0 then Land[y, x]:= COLOR_LAND;
            p:= @(p^[LandSurface^.pitch]);
            end;
     3: for y:= 0 to 1023 do
            begin
            for x:= 0 to 2047 do
                if  (p^[x * 3 + 0] <> 0)
                 or (p^[x * 3 + 1] <> 0)
                 or (p^[x * 3 + 2] <> 0) then Land[y, x]:= COLOR_LAND;
            p:= @(p^[LandSurface^.pitch]);
            end;
     4: for y:= 0 to 1023 do
            begin
            for x:= 0 to 2047 do
                if PLongword(@(p^[x * 4]))^ <> 0 then Land[y, x]:= COLOR_LAND;
            p:= @(p^[LandSurface^.pitch]);
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
WriteLnToConsole('Generating preview...');
GenBlank(EdgeTemplates[SelectTemplate]);

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
            if t > 8 then Preview[y, x]:= Preview[y, x] or ($80 shr bit)
            end
        end
end;

initialization

end.
