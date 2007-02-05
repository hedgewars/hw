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

unit uLandObjects;
interface
uses SDLh;
{$include options.inc}

procedure AddObjects(InSurface, Surface: PSDL_Surface);
procedure BlitImageAndGenerateCollisionInfo(cpX, cpY: Longword; Image, Surface: PSDL_Surface);

implementation
uses uLand, uStore, uConsts, uMisc, uConsole, uRandom;
const MaxRects = 256;
      MAXOBJECTRECTS = 16;
      MAXTHEMEOBJECTS = 32;

type PRectArray = ^TRectsArray;
     TRectsArray = array[0..MaxRects] of TSDL_Rect;
     TThemeObject = record
                    Surf: PSDL_Surface;
                    inland: TSDL_Rect;
                    outland: array[0..Pred(MAXOBJECTRECTS)] of TSDL_Rect;
                    rectcnt: Longword;
                    Width, Height: Longword;
                    Maxcnt: Longword;
                    end;
     TThemeObjects = record
                     Count: LongInt;
                     objs: array[0..Pred(MAXTHEMEOBJECTS)] of TThemeObject;
                     end;
     TSprayObject = record
                    Surf: PSDL_Surface;
                    Width, Height: Longword;
                    Maxcnt: Longword;
                    end;
     TSprayObjects = record
                     Count: LongInt;
                     objs: array[0..Pred(MAXTHEMEOBJECTS)] of TSprayObject
                     end;

var Rects: PRectArray;
    RectCount: Longword;

procedure BlitImageAndGenerateCollisionInfo(cpX, cpY: Longword; Image, Surface: PSDL_Surface);
var p: PByteArray;
    x, y: Longword;
    bpp: LongInt;
    r: TSDL_Rect;
begin
r.x:= cpX;
r.y:= cpY;
SDL_UpperBlit(Image, nil, Surface, @r);
WriteToConsole('Generating collision info... ');

if SDL_MustLock(Image) then
   SDLTry(SDL_LockSurface(Image) >= 0, true);

bpp:= Image^.format^.BytesPerPixel;
WriteToConsole('('+inttostr(bpp)+') ');
p:= Image^.pixels;
case bpp of
     1: OutError('We don''t work with 8 bit surfaces', true);
     2: for y:= 0 to Pred(Image^.h) do
            begin
            for x:= 0 to Pred(Image^.w) do
                if PWord(@(p^[x * 2]))^ <> 0 then Land[cpY + y, cpX + x]:= COLOR_LAND;
            p:= @(p^[Image^.pitch]);
            end;
     3: for y:= 0 to Pred(Image^.h) do
            begin
            for x:= 0 to Pred(Image^.w) do
                if  (p^[x * 3 + 0] <> 0)
                 or (p^[x * 3 + 1] <> 0)
                 or (p^[x * 3 + 2] <> 0) then Land[cpY + y, cpX + x]:= COLOR_LAND;
            p:= @(p^[Image^.pitch]);
            end;
     4: for y:= 0 to Pred(Image^.h) do
            begin
            for x:= 0 to Pred(Image^.w) do
                if PLongword(@(p^[x * 4]))^ <> 0 then Land[cpY + y, cpX + x]:= COLOR_LAND;
            p:= @(p^[Image^.pitch]);
            end;
     end;
if SDL_MustLock(Image) then
   SDL_UnlockSurface(Image);
WriteLnToConsole(msgOK)
end;

procedure AddRect(x1, y1, w1, h1: LongInt);
begin
with Rects^[RectCount] do
     begin
     x:= x1;
     y:= y1;
     w:= w1;
     h:= h1
     end;
inc(RectCount);
TryDo(RectCount < MaxRects, 'AddRect: overflow', true)
end;

procedure InitRects;
begin
RectCount:= 0;
New(Rects)
end;

procedure FreeRects;
begin
Dispose(rects)
end;

function CheckIntersect(x1, y1, w1, h1: LongInt): boolean;
var i: Longword;
    Result: boolean;
begin
Result:= false;
i:= 0;
if RectCount > 0 then
   repeat
   with Rects^[i] do
        Result:= (x < x1 + w1) and (x1 < x + w) and
                 (y < y1 + h1) and (y1 < y + h);
   inc(i)
   until (i = RectCount) or (Result);
CheckIntersect:= Result
end;

function AddGirder(gX: LongInt; Surface: PSDL_Surface): boolean;
var tmpsurf: PSDL_Surface;
    x1, x2, y, k, i: LongInt;
    r, rr: TSDL_Rect;
    Result: boolean;

    function CountNonZeroz(x, y: LongInt): Longword;
    var i: LongInt;
        Result: Longword;
    begin
    Result:= 0;
    for i:= y to y + 15 do
        if Land[i, x] <> 0 then inc(Result);
    CountNonZeroz:= Result
    end;

begin
y:= 150;
repeat
  inc(y, 24);
  x1:= gX;
  x2:= gX;
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
     if (x2 < 1900) and (k = 16) and (x2 - x1 > 250)
        and not CheckIntersect(x1 - 32, y - 64, x2 - x1 + 64, 144) then break;
     end;
x1:= 0;
until y > 900;
if x1 > 0 then
   begin
   Result:= true;
   tmpsurf:= LoadImage(Pathz[ptGraphics] + '/Girder', false, true, true);
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
   AddRect(x1 - 8, y - 32, x2 - x1 + 16, 80);
   for k:= y to y + 15 do
       for i:= x1 to x2 do Land[k, i]:= $FFFFFF
   end else Result:= false;
AddGirder:= Result
end;

function CheckLand(rect: TSDL_Rect; dX, dY, Color: Longword): boolean;
var i: Longword;
    Result: boolean;
begin
Result:= true;
inc(rect.x, dX);
inc(rect.y, dY);
i:= 0;
{$WARNINGS OFF}
while (i <= rect.w) and Result do
      begin
      Result:= (Land[rect.y, rect.x + i] = Color) and (Land[rect.y + rect.h, rect.x + i] = Color);
      inc(i)
      end;
i:= 0;
while (i <= rect.h) and Result do
      begin
      Result:= (Land[rect.y + i, rect.x] = Color) and (Land[rect.y + i, rect.x + rect.w] = Color);
      inc(i)
      end;
{$WARNINGS ON}
CheckLand:= Result
end;

function CheckCanPlace(x, y: Longword; var Obj: TThemeObject): boolean;
var i: Longword;
    Result: boolean;
begin
with Obj do
     if CheckLand(inland, x, y, $FFFFFF) then
        begin
        Result:= true;
        i:= 1;
        while Result and (i <= rectcnt) do
              begin
              Result:= CheckLand(outland[i], x, y, 0);
              inc(i)
              end;
        if Result then
           Result:= not CheckIntersect(x, y, Width, Height)
        end else
        Result:= false;
CheckCanPlace:= Result
end;

function TryPut(var Obj: TThemeObject; Surface: PSDL_Surface): boolean; overload;
const MaxPointsIndex = 2047;
var x, y: Longword;
    ar: array[0..MaxPointsIndex] of TPoint;
    cnt, i: Longword;
    Result: boolean;
begin
cnt:= 0;
with Obj do
     begin
     if Maxcnt = 0 then
        exit(false);
     x:= 0;
     repeat
         y:= 0;
         repeat
             if CheckCanPlace(x, y, Obj) then
                begin
                ar[cnt].x:= x;
                ar[cnt].y:= y;
                inc(cnt);
                if cnt > MaxPointsIndex then // buffer is full, do not check the rest land
                   begin
                   y:= 5000;
                   x:= 5000;
                   end
                end;
             inc(y, 3);
         until y > 1023 - Height;
         inc(x, getrandom(6) + 3)
     until x > 2047 - Width;
     Result:= cnt <> 0;
     if Result then
        begin
        i:= getrandom(cnt);
        BlitImageAndGenerateCollisionInfo(ar[i].x, ar[i].y, Obj.Surf, Surface);
        AddRect(ar[i].x, ar[i].y, Width, Height);
        dec(Maxcnt)
        end else Maxcnt:= 0
     end;
TryPut:= Result
end;

function TryPut(var Obj: TSprayObject; Surface: PSDL_Surface): boolean; overload;
const MaxPointsIndex = 8095;
var x, y: Longword;
    ar: array[0..MaxPointsIndex] of TPoint;
    cnt, i: Longword;
    r: TSDL_Rect;
    Result: boolean;
begin
cnt:= 0;
with Obj do
     begin
     if Maxcnt = 0 then
        exit(false);
     x:= 0;
     r.x:= 0;
     r.y:= 0;
     r.w:= Width;
     r.h:= Height + 16;
     repeat
         y:= 8;
         repeat
             if CheckLand(r, x, y - 8, $FFFFFF)
                and not CheckIntersect(x, y, Width, Height) then
                begin
                ar[cnt].x:= x;
                ar[cnt].y:= y;
                inc(cnt);
                if cnt > MaxPointsIndex then // buffer is full, do not check the rest land
                   begin
                   y:= 5000;
                   x:= 5000;
                   end
                end;
             inc(y, 12);
         until y > 1023 - Height - 8;
         inc(x, getrandom(12) + 12)
     until x > 2047 - Width;
     Result:= cnt <> 0;
     if Result then
        begin
        i:= getrandom(cnt);
        r.x:= ar[i].X;
        r.y:= ar[i].Y;
        r.w:= Width;
        r.h:= Height;
        SDL_UpperBlit(Obj.Surf, nil, Surface, @r);
        AddRect(ar[i].x - 32, ar[i].y - 32, Width + 64, Height + 64);
        dec(Maxcnt)
        end else Maxcnt:= 0
     end;
TryPut:= Result
end;

procedure ReadThemeInfo(var ThemeObjects: TThemeObjects; var SprayObjects: TSprayObjects);
var s: string;
    f: textfile;
    i, ii: LongInt;
begin
s:= Pathz[ptCurrTheme] + '/' + cThemeCFGFilename;
WriteLnToConsole('Reading objects info...');
Assign(f, s);
{$I-}
Reset(f);
Readln(f, s); // skip color
Readln(f, ThemeObjects.Count);
for i:= 0 to Pred(ThemeObjects.Count) do
    begin
    Readln(f, s); // filename
    with ThemeObjects.objs[i] do
         begin
         Surf:= LoadImage(Pathz[ptCurrTheme] + '/' + s, false, true, true);
         Width:= Surf^.w;
         Height:= Surf^.h;
         with inland do Read(f, x, y, w, h);
         Read(f, rectcnt);
         for ii:= 1 to rectcnt do
             with outland[ii] do Read(f, x, y, w, h);
         Maxcnt:= 3;
         ReadLn(f)
         end;
    end;

Readln(f, SprayObjects.Count);
for i:= 0 to Pred(SprayObjects.Count) do
    begin
    Readln(f, s); // filename
    with SprayObjects.objs[i] do
         begin
         Surf:= LoadImage(Pathz[ptCurrTheme] + '/' + s, false, true, true);
         Width:= Surf^.w;
         Height:= Surf^.h;
         ReadLn(f, Maxcnt)
         end;
    end;
Close(f);
{$I+}
TryDo(IOResult = 0, 'Bad data or cannot access file ' + cThemeCFGFilename, true)
end;

procedure AddThemeObjects(Surface: PSDL_Surface; var ThemeObjects: TThemeObjects; MaxCount: LongInt);
var i, ii, t: LongInt;
    b: boolean;
begin
if ThemeObjects.Count = 0 then exit;
WriteLnToConsole('Adding theme objects...');
i:= 1;
repeat
    t:= getrandom(ThemeObjects.Count);
    ii:= t;
    repeat
      inc(ii);
      if ii = ThemeObjects.Count then ii:= 0;
      b:= TryPut(ThemeObjects.objs[ii], Surface)
    until b or (ii = t);
    inc(i)
until (i > MaxCount) or not b;
end;

procedure AddSprayObjects(Surface: PSDL_Surface; var SprayObjects: TSprayObjects; MaxCount: Longword);
var i: Longword;
    ii, t: LongInt;
    b: boolean;
begin
if SprayObjects.Count = 0 then exit;
WriteLnToConsole('Adding spray objects...');
i:= 1;
repeat
    t:= getrandom(SprayObjects.Count);
    ii:= t;
    repeat
      inc(ii);
      if ii = SprayObjects.Count then ii:= 0;
      b:= TryPut(SprayObjects.objs[ii], Surface)
    until b or (ii = t);
    inc(i)
until (i > MaxCount) or not b;
end;

procedure AddObjects(InSurface, Surface: PSDL_Surface);
var ThemeObjects: TThemeObjects;
    SprayObjects: TSprayObjects;
begin
InitRects;
AddGirder(256, Surface);
AddGirder(512, Surface);
AddGirder(768, Surface);
AddGirder(1024, Surface);
AddGirder(1280, Surface);
AddGirder(1536, Surface);
AddGirder(1792, Surface);
ReadThemeInfo(ThemeObjects, SprayObjects);
AddThemeObjects(Surface, ThemeObjects, 8);
AddProgress;
SDL_UpperBlit(InSurface, nil, Surface, nil);
AddSprayObjects(Surface, SprayObjects, 10);
FreeRects
end;

end.
