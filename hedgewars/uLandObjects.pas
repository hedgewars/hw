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

unit uLandObjects;
interface
uses SDLh;
{$INCLUDE "options.inc"}

procedure AddObjects();
procedure LoadThemeConfig;
procedure BlitImageAndGenerateCollisionInfo(cpX, cpY, Width: Longword; Image: PSDL_Surface);
procedure AddOnLandObjects(Surface: PSDL_Surface);

implementation
uses uLand, uStore, uConsts, uMisc, uConsole, uRandom, uVisualGears, uFloat,
{$IFDEF GLES11}
	gles11,
{$ELSE}
	GL,
{$ENDIF}
	uSound, uWorld;
const MaxRects = 512;
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
    ThemeObjects: TThemeObjects;
    SprayObjects: TSprayObjects;


procedure BlitImageAndGenerateCollisionInfo(cpX, cpY, Width: Longword; Image: PSDL_Surface);
var p: PLongwordArray;
    x, y: Longword;
    bpp: LongInt;
begin
WriteToConsole('Generating collision info... ');

if SDL_MustLock(Image) then
   SDLTry(SDL_LockSurface(Image) >= 0, true);

bpp:= Image^.format^.BytesPerPixel;
TryDo(bpp = 4, 'Land object should be 32bit', true);

if Width = 0 then Width:= Image^.w;

p:= Image^.pixels;
for y:= 0 to Pred(Image^.h) do
	begin
	for x:= 0 to Pred(Width) do
		if LandPixels[cpY + y, cpX + x] = 0 then
			begin
			LandPixels[cpY + y, cpX + x]:= p^[x];
			if (p^[x] and AMask) <> 0 then Land[cpY + y, cpX + x]:= COLOR_OBJECT;
			end;
	p:= @(p^[Image^.pitch shr 2]);
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

function AddGirder(gX: LongInt): boolean;
var tmpsurf: PSDL_Surface;
    x1, x2, y, k, i: LongInt;
    rr: TSDL_Rect;
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
y:= topY+150;
repeat
	inc(y, 24);
	x1:= gX;
	x2:= gX;

	while (x1 > Longint(leftX)+150) and (CountNonZeroz(x1, y) = 0) do dec(x1, 2);

	i:= x1 - 12;
	repeat
		dec(x1, 2);
		k:= CountNonZeroz(x1, y)
	until (x1 < Longint(leftX)+150) or (k = 0) or (k = 16) or (x1 < i);

	inc(x1, 2);
	if k = 16 then
		begin
		while (x2 < (rightX-150)) and (CountNonZeroz(x2, y) = 0) do inc(x2, 2);
		i:= x2 + 12;
		repeat
		inc(x2, 2);
		k:= CountNonZeroz(x2, y)
		until (x2 >= (rightX-150)) or (k = 0) or (k = 16) or (x2 > i) or (x2 - x1 >= 768);
		if (x2 < (rightX - 150)) and (k = 16) and (x2 - x1 > 250) and (x2 - x1 < 768)
			and not CheckIntersect(x1 - 32, y - 64, x2 - x1 + 64, 144) then break;
		end;
x1:= 0;
until y > (LAND_HEIGHT-125);

if x1 > 0 then
	begin
	Result:= true;
	tmpsurf:= LoadImage(Pathz[ptCurrTheme] + '/Girder', ifTransparent or ifIgnoreCaps);
	if tmpsurf = nil then tmpsurf:= LoadImage(Pathz[ptGraphics] + '/Girder', ifCritical or ifTransparent or ifIgnoreCaps);

	rr.x:= x1;
	while rr.x < x2 do
		begin
		BlitImageAndGenerateCollisionInfo(rr.x, y, min(x2 - rr.x, tmpsurf^.w), tmpsurf);
		inc(rr.x, tmpsurf^.w);
		end;
	SDL_FreeSurface(tmpsurf);

	AddRect(x1 - 8, y - 32, x2 - x1 + 16, 80);
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
     if CheckLand(inland, x, y, COLOR_LAND) then
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

function TryPut(var Obj: TThemeObject): boolean; overload;
const MaxPointsIndex = 2047;
var x, y: Longword;
    ar: array[0..MaxPointsIndex] of TPoint;
    cnt, i: Longword;
    Result: boolean;
begin
cnt:= 0;
Obj.Maxcnt:= (Obj.Maxcnt * MaxHedgehogs) div 18;
with Obj do
     begin
     if Maxcnt = 0 then
        exit(false);
     x:= 0;
     repeat
         y:= topY+32; // leave room for a hedgie to teleport in
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
         until y > LAND_HEIGHT - 1 - Height;
         inc(x, getrandom(6) + 3)
     until x > LAND_WIDTH - 1 - Width;
     Result:= cnt <> 0;
     if Result then
        begin
        i:= getrandom(cnt);
        BlitImageAndGenerateCollisionInfo(ar[i].x, ar[i].y, 0, Obj.Surf);
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
Obj.Maxcnt:= (Obj.Maxcnt * MaxHedgehogs) div 18;
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
			if CheckLand(r, x, y - 8, COLOR_LAND)
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
        until y > LAND_HEIGHT - 1 - Height - 8;
		inc(x, getrandom(12) + 12)
    until x > LAND_WIDTH - 1 - Width;
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
    vobcount: Longword;
    c1, c2: TSDL_Color;

	procedure CheckRect(Width, Height, x, y, w, h: LongWord);
	begin
	if (x + w > Width) then OutError('Object''s rectangle exceeds image: x + w (' + inttostr(x) + ' + ' + inttostr(w) + ') > Width (' + inttostr(Width) + ')', true);
	if (y + h > Height) then OutError('Object''s rectangle exceeds image: y + h (' + inttostr(y) + ' + ' + inttostr(h) + ') > Height (' + inttostr(Height) + ')', true);
	end;

begin
s:= Pathz[ptCurrTheme] + '/' + cThemeCFGFilename;
WriteLnToConsole('Reading objects info...');
Assign(f, s);
{$I-}
Reset(f);

// read sky and explosion border colors
Readln(f, c1.r, c1.g, c1. b);
Readln(f, c2.r, c2.g, c2. b);
// read water gradient colors
Readln(f, WaterColorArray[0].r, WaterColorArray[0].g, WaterColorArray[0].b);
Readln(f, WaterColorArray[2].r, WaterColorArray[2].g, WaterColorArray[2].b, cWaterOpacity);
WaterColorArray[0].a := 255;
WaterColorArray[2].a := 255;
WaterColorArray[1]:= WaterColorArray[0];
WaterColorArray[3]:= WaterColorArray[2];

glClearColor(c1.r / 255, c1.g / 255, c1.b / 255, 0.99); // sky color
cExplosionBorderColor:= c2.value or AMask;

ReadLn(f, s);
if MusicFN = '' then MusicFN:= s;

ReadLn(f, cCloudsNumber);

// TODO - adjust all the theme cloud numbers. This should not be a permanent fix
cCloudsNumber:= cCloudsNumber * (LAND_WIDTH div 2048);

Readln(f, ThemeObjects.Count);
for i:= 0 to Pred(ThemeObjects.Count) do
	begin
	Readln(f, s); // filename
	with ThemeObjects.objs[i] do
			begin
			Surf:= LoadImage(Pathz[ptCurrTheme] + '/' + s, ifCritical or ifTransparent or ifIgnoreCaps);
			Width:= Surf^.w;
			Height:= Surf^.h;
			with inland do
				begin
				Read(f, x, y, w, h);
				CheckRect(Width, Height, x, y, w, h)
				end;
			Read(f, rectcnt);
			for ii:= 1 to rectcnt do
				with outland[ii] do
					begin
					Read(f, x, y, w, h);
					CheckRect(Width, Height, x, y, w, h)
					end;
			Maxcnt:= 3;
			ReadLn(f)
			end;
	end;

// sprays
Readln(f, SprayObjects.Count);
for i:= 0 to Pred(SprayObjects.Count) do
    begin
    Readln(f, s); // filename
    with SprayObjects.objs[i] do
         begin
         Surf:= LoadImage(Pathz[ptCurrTheme] + '/' + s, ifCritical or ifTransparent or ifIgnoreCaps);
         Width:= Surf^.w;
         Height:= Surf^.h;
         ReadLn(f, Maxcnt)
         end;
    end;

// snowflakes
Readln(f, vobCount);
if vobCount > 0 then
   Readln(f, vobFramesCount, vobFrameTicks, vobVelocity, vobFallSpeed);

for i:= 0 to Pred(vobCount) do
    AddVisualGear( -cScreenWidth + random(cScreenWidth * 2 + LAND_WIDTH), random(1024+200) - 100 + LAND_HEIGHT, vgtFlake);

Close(f);
{$I+}
TryDo(IOResult = 0, 'Bad data or cannot access file ' + cThemeCFGFilename, true)
end;

procedure AddThemeObjects(var ThemeObjects: TThemeObjects; MaxCount: LongInt);
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
      b:= TryPut(ThemeObjects.objs[ii])
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

procedure AddObjects();
var i, int: Longword;
begin
InitRects;
if hasGirders then
    begin
    int:= max(playWidth div 8, 256);
    i:=leftX+int;
    repeat
        AddGirder(i);
        i:=i+int;
    until (i>rightX-int);
    end;
AddThemeObjects(ThemeObjects, (8 * MaxHedgehogs) div 18); // MaxHedgehogs should roughly correspond to available surface area.  Was also thinking maybe using playHeight * playWidth div constant   :)
AddProgress;
FreeRects
end;

procedure AddOnLandObjects(Surface: PSDL_Surface);
begin
InitRects;
//AddSprayObjects(Surface, SprayObjects, 12);
AddSprayObjects(Surface, SprayObjects, (2 * MaxHedgehogs) div 3);
FreeRects
end;

procedure LoadThemeConfig;
begin
ReadThemeInfo(ThemeObjects, SprayObjects)
end;

end.
