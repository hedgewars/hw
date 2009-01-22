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

unit uLand;
interface
uses SDLh, uLandTemplates, uFloat, GL, uConsts;
{$include options.inc}
type TLandArray = packed array[0..1023, 0..2047] of LongWord;
     TPreview = packed array[0..127, 0..31] of byte;
     TDirtyTag = packed array[0..31, 0..63] of byte;

var  Land: TLandArray;
     LandPixels: TLandArray;
     LandTexture: PTexture = nil;
     LandDirty: TDirtyTag;

procedure GenMap;
function  GenPreview: TPreview;
procedure CheckLandDigest(s: shortstring);
procedure UpdateLandTexture(Y, Height: LongInt);

implementation
uses uConsole, uStore, uMisc, uRandom, uTeams, uLandObjects, uSHA, uIO;

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
s:='M{'+inttostr(dig[0])+':'
       +inttostr(dig[1])+':'
       +inttostr(dig[2])+':'
       +inttostr(dig[3])+':'
       +inttostr(dig[4])+'}';
CheckLandDigest(s);
SendIPCRaw(@s[0], Length(s) + 1)
end;

procedure CheckLandDigest(s: shortstring);
const digest: shortstring = '';
begin
{$IFDEF DEBUGFILE}
AddFileLog('CheckLandDigest: ' + s);
{$ENDIF}
if digest = '' then
   digest:= s
else
   TryDo(s = digest, 'Different maps generated, sorry', true)
end;

procedure DrawLine(X1, Y1, X2, Y2: LongInt; Color: Longword);
var
  eX, eY, dX, dY: LongInt;
  i, sX, sY, x, y, d: LongInt;
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

procedure DrawEdge(var pa: TPixAr; Color: Longword);
var i: LongInt;
begin
i:= 0;
with pa do
while i < LongInt(Count) - 1 do
    if (ar[i + 1].X = NTPX) then inc(i, 2)
       else begin
       DrawLine(ar[i].x, ar[i].y, ar[i + 1].x, ar[i + 1].y, Color);
       inc(i)
       end
end;

procedure Vector(p1, p2, p3: TPoint; var Vx, Vy: hwFloat);
var d1, d2, d: hwFloat;
begin
Vx:= int2hwFloat(p1.X - p3.X);
Vy:= int2hwFloat(p1.Y - p3.Y);
d:= DistanceI(p2.X - p1.X, p2.Y - p1.Y);
d1:= DistanceI(p2.X - p3.X, p2.Y - p3.Y);
d2:= Distance(Vx, Vy);
if d1 < d then d:= d1;
if d2 < d then d:= d2;
d:= d * _1div3;
if d2.QWordValue = 0 then
   begin
   Vx:= _0;
   Vy:= _0
   end else
   begin
   d2:= _1 / d2;
   Vx:= Vx * d2;
   Vy:= Vy * d2;

   Vx:= Vx * d;
   Vy:= Vy * d
   end
end;

procedure AddLoopPoints(var pa, opa: TPixAr; StartI, EndI: LongInt; Delta: hwFloat);
var i, pi, ni: LongInt;
    NVx, NVy, PVx, PVy: hwFloat;
    x1, x2, y1, y2: LongInt;
    tsq, tcb, t, r1, r2, r3, cx1, cx2, cy1, cy2: hwFloat;
    X, Y: LongInt;
begin
pi:= EndI;
i:= StartI;
ni:= Succ(StartI);
Vector(opa.ar[pi], opa.ar[i], opa.ar[ni], NVx, NVy);
repeat
    inc(pi);
    if pi > EndI then pi:= StartI;
    inc(i);
    if i > EndI then i:= StartI;
    inc(ni);
    if ni > EndI then ni:= StartI;
    PVx:= NVx;
    PVy:= NVy;
    Vector(opa.ar[pi], opa.ar[i], opa.ar[ni], NVx, NVy);

    x1:= opa.ar[pi].x;
    y1:= opa.ar[pi].y;
    x2:= opa.ar[i].x;
    y2:= opa.ar[i].y;
    cx1:= int2hwFloat(x1) - PVx;
    cy1:= int2hwFloat(y1) - PVy;
    cx2:= int2hwFloat(x2) + NVx;
    cy2:= int2hwFloat(y2) + NVy;
    t:= _0;
    while t.Round = 0 do
          begin
          tsq:= t * t;
          tcb:= tsq * t;
          r1:= (_1 - t*3 + tsq*3 - tcb);
          r2:= (     t*3 - tsq*6 + tcb*3);
          r3:= (           tsq*3 - tcb*3);
          X:= hwRound(r1 * x1 + r2 * cx1 + r3 * cx2 + tcb * x2);
          Y:= hwRound(r1 * y1 + r2 * cy1 + r3 * cy2 + tcb * y2);
          t:= t + Delta;
          pa.ar[pa.Count].x:= X;
          pa.ar[pa.Count].y:= Y;
          inc(pa.Count);
          TryDo(pa.Count <= cMaxEdgePoints, 'Edge points overflow', true)
          end;
until i = StartI;
pa.ar[pa.Count].x:= opa.ar[StartI].X;
pa.ar[pa.Count].y:= opa.ar[StartI].Y;
inc(pa.Count)
end;

procedure BezierizeEdge(var pa: TPixAr; Delta: hwFloat);
var i, StartLoop: LongInt;
    opa: TPixAr;
begin
opa:= pa;
pa.Count:= 0;
i:= 0;
StartLoop:= 0;
while i < LongInt(opa.Count) do
    if (opa.ar[i + 1].X = NTPX) then
       begin
       AddLoopPoints(pa, opa, StartLoop, i, Delta);
       inc(i, 2);
       StartLoop:= i;
       pa.ar[pa.Count].X:= NTPX;
       inc(pa.Count);
       end else inc(i)
end;

procedure FillLand(x, y: LongInt);
var Stack: record
           Count: Longword;
           points: array[0..8192] of record
                                     xl, xr, y, dir: LongInt;
                                     end
           end;

    procedure Push(_xl, _xr, _y, _dir: LongInt);
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

    procedure Pop(var _xl, _xr, _y, _dir: LongInt);
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

var xl, xr, dir: LongInt;
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
    r, rr: TSDL_Rect;
    x, yd, yu: LongInt;
begin
tmpsurf:= LoadImage(Pathz[ptCurrTheme] + '/LandTex', false, true, false);
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
var i: LongInt;
begin
with Template do
     begin
     pa.Count:= BasePointsCount;
     for i:= 0 to pred(pa.Count) do
         begin
         pa.ar[i].x:= BasePoints^[i].x + LongInt(GetRandom(BasePoints^[i].w));
         pa.ar[i].y:= BasePoints^[i].y + LongInt(GetRandom(BasePoints^[i].h))
         end;

     if canMirror then
        if getrandom(2) = 0 then
           begin
           for i:= 0 to pred(BasePointsCount) do
             if pa.ar[i].x <> NTPX then
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

function CheckIntersect(V1, V2, V3, V4: TPoint): boolean;
var c1, c2, dm: LongInt;
begin
dm:= (V4.y - V3.y) * (V2.x - V1.x) - (V4.x - V3.x) * (V2.y - V1.y);
c1:= (V4.x - V3.x) * (V1.y - V3.y) - (V4.y - V3.y) * (V1.x - V3.x);
if dm = 0 then exit(false);

c2:= (V2.x - V3.x) * (V1.y - V3.y) - (V2.y - V3.y) * (V1.x - V3.x);
if dm > 0 then
   begin
   if (c1 < 0) or (c1 > dm) then exit(false);
   if (c2 < 0) or (c2 > dm) then exit(false)
   end else
   begin
   if (c1 > 0) or (c1 < dm) then exit(false);
   if (c2 > 0) or (c2 < dm) then exit(false)
   end;

//AddFileLog('1  (' + inttostr(V1.x) + ',' + inttostr(V1.y) + ')x(' + inttostr(V2.x) + ',' + inttostr(V2.y) + ')');
//AddFileLog('2  (' + inttostr(V3.x) + ',' + inttostr(V3.y) + ')x(' + inttostr(V4.x) + ',' + inttostr(V4.y) + ')');
CheckIntersect:= true
end;

function CheckSelfIntersect(var pa: TPixAr; ind: Longword): boolean;
var i: Longword;
begin
if (ind <= 0) or (ind >= Pred(pa.Count)) then exit(false);
for i:= 1 to pa.Count - 3 do
    if (i <= ind - 1) or (i >= ind + 2) then
      begin
      if (i <> ind - 1) and
         CheckIntersect(pa.ar[ind], pa.ar[ind - 1], pa.ar[i], pa.ar[i - 1]) then exit(true);
      if (i <> ind + 2) and
         CheckIntersect(pa.ar[ind], pa.ar[ind + 1], pa.ar[i], pa.ar[i - 1]) then exit(true);
      end;
CheckSelfIntersect:= false
end;

procedure RandomizePoints(var pa: TPixAr);
const cEdge = 55;
      cMinDist = 8;
var radz: array[0..Pred(cMaxEdgePoints)] of LongInt;
    i, k, dist, px, py: LongInt;
begin
radz[0]:= 0;
for i:= 0 to Pred(pa.Count) do
  with pa.ar[i] do
    if x <> NTPX then
      begin
      radz[i]:= Min(Max(x - cEdge, 0), Max(2048 - cEdge - x, 0));
      radz[i]:= Min(radz[i], Min(Max(y - cEdge, 0), Max(1024 - cEdge - y, 0)));
      if radz[i] > 0 then
        for k:= 0 to Pred(i) do
          begin
          dist:= Max(abs(x - pa.ar[k].x), abs(y - pa.ar[k].y));
          radz[k]:= Max(0, Min((dist - cMinDist) div 2, radz[k]));
          radz[i]:= Max(0, Min(dist - radz[k] - cMinDist, radz[i]))
        end
      end;

for i:= 0 to Pred(pa.Count) do
  with pa.ar[i] do
    if ((x and $FFFFF800) = 0) and ((y and $FFFFFC00) = 0) then
      begin
      px:= x;
      py:= y;
      x:= x + LongInt(GetRandom(7) - 3) * (radz[i] * 5 div 7) div 3;
      y:= y + LongInt(GetRandom(7) - 3) * (radz[i] * 5 div 7) div 3;
      if CheckSelfIntersect(pa, i) then
         begin
         x:= px;
         y:= py
         end;
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
for i:= 1 to Template.BezierizeCount do
    begin
    BezierizeEdge(pa, _0_5);
    RandomizePoints(pa);
    RandomizePoints(pa)
    end;
for i:= 1 to Template.RandPassesCount do RandomizePoints(pa);
BezierizeEdge(pa, _0_1);

DrawEdge(pa, 0);

with Template do
     for i:= 0 to pred(FillPointsCount) do
         with FillPoints^[i] do
              FillLand(x, y);

DrawEdge(pa, COLOR_LAND)
end;

function SelectTemplate: LongInt;
begin
SelectTemplate:= getrandom(Succ(High(EdgeTemplates)))
end;

procedure LandSurface2LandPixels(Surface: PSDL_Surface);
var x, y: LongInt;
	p: PLongwordArray;
begin
TryDo(Surface <> nil, 'Assert (LandSurface <> nil) failed', true);

if SDL_MustLock(Surface) then
	SDLTry(SDL_LockSurface(Surface) >= 0, true);

p:= Surface^.pixels;
for y:= 0 to 1023 do
	begin
	for x:= 0 to 2047 do
		if Land[y, x] <> 0 then LandPixels[y, x]:= p^[x] or $FF000000;
	p:= @(p^[Surface^.pitch div 4]);
	end;

if SDL_MustLock(Surface) then
	SDL_UnlockSurface(Surface)
end;

procedure GenLandSurface;
var tmpsurf: PSDL_Surface;
begin
WriteLnToConsole('Generating land...');

GenBlank(EdgeTemplates[SelectTemplate]);

AddProgress;

tmpsurf:= SDL_CreateRGBSurface(SDL_SWSURFACE, 2048, 1024, 32, RMask, GMask, BMask, 0);

TryDo(tmpsurf <> nil, 'Error creating pre-land surface', true);
ColorizeLand(tmpsurf);
AddOnLandObjects(tmpsurf);

LandSurface2LandPixels(tmpsurf);
SDL_FreeSurface(tmpsurf);

AddProgress;

AddObjects;

UpdateLandTexture(0, 1023);
AddProgress
end;

procedure MakeFortsMap;
var tmpsurf: PSDL_Surface;
begin
WriteLnToConsole('Generating forts land...');

tmpsurf:= LoadImage(Pathz[ptForts] + '/' + ClansArray[0]^.Teams[0]^.FortName + 'L', true, true, true);
BlitImageAndGenerateCollisionInfo(0, 0, 1024, tmpsurf);
SDL_FreeSurface(tmpsurf);

tmpsurf:= LoadImage(Pathz[ptForts] + '/' + ClansArray[1]^.Teams[0]^.FortName + 'R', true, true, true);
BlitImageAndGenerateCollisionInfo(1024, 0, 1024, tmpsurf);
SDL_FreeSurface(tmpsurf);

UpdateLandTexture(0, 1023)
end;

procedure LoadMap;
var tmpsurf: PSDL_Surface;
begin
WriteLnToConsole('Loading land from file...');
AddProgress;
tmpsurf:= LoadImage(Pathz[ptMapCurrent] + '/map', true, true, true);
TryDo((tmpsurf^.w = 2048) and (tmpsurf^.h = 1024), 'Map dimensions should be 2048x1024!', true);

TryDo(tmpsurf^.format^.BytesPerPixel = 4, 'Map should be 32bit', true);

BlitImageAndGenerateCollisionInfo(0, 0, 2048, tmpsurf);
SDL_FreeSurface(tmpsurf);

UpdateLandTexture(0, 1023)
end;

procedure GenMap;
begin
LoadThemeConfig;

if (GameFlags and gfForts) = 0 then
   if Pathz[ptMapCurrent] <> '' then LoadMap
                                else GenLandSurface
                               else MakeFortsMap;
AddProgress;
{$IFDEF DEBUGFILE}LogLandDigest{$ENDIF}
end;

function GenPreview: TPreview;
var x, y, xx, yy, t, bit: LongInt;
    Preview: TPreview;
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
        end;
GenPreview:= Preview
end;

procedure UpdateLandTexture(Y, Height: LongInt);
begin
if (Height <= 0) then exit;
TryDo((Y >= 0) and (Y < 1024), 'UpdateLandTexture: wrong Y parameter', true);
TryDo(Y + Height < 1024, 'UpdateLandTexture: wrong Height parameter', true);

if LandTexture = nil then
	LandTexture:= NewTexture(2048, 1024, @LandPixels)
else
	begin
	glBindTexture(GL_TEXTURE_2D, LandTexture^.id);
	glTexSubImage2D(GL_TEXTURE_2D, 0, 0, Y, 2048, Height, GL_RGBA, GL_UNSIGNED_BYTE, @LandPixels[Y, 0]);
	end
end;

initialization

end.
