(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004, 2005 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uStore;
interface
uses uConsts, uTeams, SDLh;
{$INCLUDE options.inc}

type PRangeArray = ^TRangeArray;
     TRangeArray = array[byte] of record
                                  Left, Right: integer;
                                  end;

procedure StoreInit;
procedure StoreLoad;
procedure StoreRelease;
procedure DrawGear(Stuff : TStuff; X, Y: integer; Surface: PSDL_Surface);
procedure DrawSpriteFromRect(r: TSDL_Rect; X, Y, Height, Position: integer; Surface: PSDL_Surface);
procedure DrawSprite (Sprite: TSprite; X, Y, Position: integer; Surface: PSDL_Surface);
procedure DrawLand (X, Y: integer; Surface: PSDL_Surface);
procedure DXOutText(X, Y: Integer; Font: THWFont; s: string; Surface: PSDL_Surface);
procedure DrawCaption(X, Y: integer; Rect: TSDL_Rect; Surface: PSDL_Surface; const fromTempSurf: boolean = false);
procedure DrawHedgehog(X, Y: integer; Dir: integer; Pos, Step: LongWord; Surface: PSDL_Surface);
procedure DrawExplosion(X, Y, Radius: integer);
procedure DrawLineExplosions(ar: PRangeArray; Radius: Longword; y, dY: integer; Count: Byte);
procedure RenderHealth(var Hedgehog: THedgehog);
function  RenderString(var s: shortstring; Color, Pos: integer): TSDL_Rect;
procedure AddProgress;
function  LoadImage(filename: string; hasAlpha: boolean): PSDL_Surface;

var PixelFormat: PSDL_PixelFormat;
 SDLPrimSurface: PSDL_Surface;

implementation
uses uMisc, uIO, uConsole, uLand;

var StoreSurface,
     TempSurface,
       HHSurface: PSDL_Surface;

procedure DrawExplosion(X, Y, Radius: integer);
var ty, tx: integer;
    p: integer;
begin
for ty:= max(-Radius, -y) to min(radius, 1023 - y) do
    for tx:= max(0, round(x-radius*sqrt(1-sqr(ty/radius)))) to min(2047, round(x+radius*sqrt(1-sqr(ty/radius)))) do
        Land[ty + y, tx]:= 0;

if SDL_MustLock(LandSurface) then
   SDLTry(SDL_LockSurface(LandSurface) >= 0, true);

p:= Longword(LandSurface.pixels);
case LandSurface.format.BytesPerPixel of
     1: ;// not supported
     2: for ty:= max(-Radius, -y) to min(Radius, 1023 - y) do
            for tx:= max(0, round(x-radius*sqrt(1-sqr(ty/radius)))) to min(2047, round(x+radius*sqrt(1-sqr(ty/radius)))) do
                PWord(p + LandSurface.pitch*(y + ty) + tx * 2)^:= 0;
     3: for ty:= max(-Radius, -y) to min(Radius, 1023 - y) do
            for tx:= max(0, round(x-radius*sqrt(1-sqr(ty/radius)))) to min(2047, round(x+radius*sqrt(1-sqr(ty/radius)))) do
                begin
                PByte(p + LandSurface.pitch*(y + ty) + tx * 3 + 0)^:= 0;
                PByte(p + LandSurface.pitch*(y + ty) + tx * 3 + 1)^:= 0;
                PByte(p + LandSurface.pitch*(y + ty) + tx * 3 + 2)^:= 0;
                end;
     4: for ty:= max(-Radius, -y) to min(Radius, 1023 - y) do
            for tx:= max(0, round(x-radius*sqrt(1-sqr(ty/radius)))) to min(2047, round(x+radius*sqrt(1-sqr(ty/radius)))) do
                PLongword(p + LandSurface.pitch*(y + ty) + tx * 4)^:= 0;
     end;

inc(Radius, 4);

case LandSurface.format.BytesPerPixel of
     1: ;// not supported
     2: for ty:= max(-Radius, -y) to min(Radius, 1023 - y) do
            for tx:= max(0, round(x-radius*sqrt(1-sqr(ty/radius)))) to min(2047, round(x+radius*sqrt(1-sqr(ty/radius)))) do
               if PWord(p + LandSurface.pitch*(y + ty) + tx * 2)^ <> 0 then
                  PWord(p + LandSurface.pitch*(y + ty) + tx * 2)^:= cExplosionBorderColor;
     3: for ty:= max(-Radius, -y) to min(Radius, 1023 - y) do
            for tx:= max(0, round(x-radius*sqrt(1-sqr(ty/radius)))) to min(2047, round(x+radius*sqrt(1-sqr(ty/radius)))) do
                if (PByte(p + LandSurface.pitch*(y + ty) + tx * 3 + 0)^ <> 0)
                or (PByte(p + LandSurface.pitch*(y + ty) + tx * 3 + 1)^ <> 0)
                or (PByte(p + LandSurface.pitch*(y + ty) + tx * 3 + 2)^ <> 0)
                then begin
                PByte(p + LandSurface.pitch*(y + ty) + tx * 3 + 0)^:= cExplosionBorderColor and $FF;
                PByte(p + LandSurface.pitch*(y + ty) + tx * 3 + 1)^:= (cExplosionBorderColor shr 8) and $FF;
                PByte(p + LandSurface.pitch*(y + ty) + tx * 3 + 2)^:= (cExplosionBorderColor shr 16);
                end;
     4: for ty:= max(-Radius, -y) to min(Radius, 1023 - y) do
            for tx:= max(0, round(x-radius*sqrt(1-sqr(ty/radius)))) to min(2047, round(x+radius*sqrt(1-sqr(ty/radius)))) do
                if PLongword(p + LandSurface.pitch*(y + ty) + tx * 4)^ <> 0 then
                   PLongword(p + LandSurface.pitch*(y + ty) + tx * 4)^:= cExplosionBorderColor;
     end;

if SDL_MustLock(LandSurface) then
   SDL_UnlockSurface(LandSurface);

SDL_UpdateRect(LandSurface, X - Radius, Y - Radius, Radius * 2, Radius * 2)
end;

procedure DrawLineExplosions(ar: PRangeArray; Radius: Longword; y, dY: integer; Count: Byte);
var tx, ty, i, p: integer;
begin
if SDL_MustLock(LandSurface) then
   SDL_LockSurface(LandSurface);

p:= Longword(LandSurface.pixels);
for i:= 0 to Pred(Count) do
    begin
    case LandSurface.format.BytesPerPixel of
     1: ;
     2: for ty:= max(-Radius, -y) to min(Radius, 1023 - y) do
            for tx:= max(0, round(ar[i].Left - radius*sqrt(1-sqr(ty/radius)))) to min(2047, round(ar[i].Right + radius*sqrt(1-sqr(ty/radius)))) do
                PWord(p + LandSurface.pitch*(y + ty) + tx * 2)^:= 0;
     3: for ty:= max(-Radius, -y) to min(Radius, 1023 - y) do
            for tx:= max(0, round(ar[i].Left - radius*sqrt(1-sqr(ty/radius)))) to min(2047, round(ar[i].Right + radius*sqrt(1-sqr(ty/radius)))) do
                begin
                PByte(p + LandSurface.pitch*(y + ty) + tx * 3 + 0)^:= 0;
                PByte(p + LandSurface.pitch*(y + ty) + tx * 3 + 1)^:= 0;
                PByte(p + LandSurface.pitch*(y + ty) + tx * 3 + 2)^:= 0;
                end;
     4: for ty:= max(-Radius, -y) to min(Radius, 1023 - y) do
            for tx:= max(0, round(ar[i].Left - radius*sqrt(1-sqr(ty/radius)))) to min(2047, round(ar[i].Right + radius*sqrt(1-sqr(ty/radius)))) do
                PLongword(p + LandSurface.pitch*(y + ty) + tx * 4)^:= 0;
     end;
    inc(y, dY)
    end;

inc(Radius, 4);
dec(y, Count*dY);

for i:= 0 to Pred(Count) do
    begin
    case LandSurface.format.BytesPerPixel of
     1: ;
     2: for ty:= max(-Radius, -y) to min(Radius, 1023 - y) do
            for tx:= max(0, round(ar[i].Left - radius*sqrt(1-sqr(ty/radius)))) to min(2047, round(ar[i].Right + radius*sqrt(1-sqr(ty/radius)))) do
               if PWord(p + LandSurface.pitch*(y + ty) + tx * 2)^ <> 0 then
                  PWord(p + LandSurface.pitch*(y + ty) + tx * 2)^:= cExplosionBorderColor;
     3: for ty:= max(-Radius, -y) to min(Radius, 1023 - y) do
            for tx:= max(0, round(ar[i].Left - radius*sqrt(1-sqr(ty/radius)))) to min(2047, round(ar[i].Right + radius*sqrt(1-sqr(ty/radius)))) do
                if (PByte(p + LandSurface.pitch*(y + ty) + tx * 3 + 0)^ <> 0)
                or (PByte(p + LandSurface.pitch*(y + ty) + tx * 3 + 1)^ <> 0)
                or (PByte(p + LandSurface.pitch*(y + ty) + tx * 3 + 2)^ <> 0)
                then begin
                PByte(p + LandSurface.pitch*(y + ty) + tx * 3 + 0)^:= cExplosionBorderColor and $FF;
                PByte(p + LandSurface.pitch*(y + ty) + tx * 3 + 1)^:= (cExplosionBorderColor shr 8) and $FF;
                PByte(p + LandSurface.pitch*(y + ty) + tx * 3 + 2)^:= (cExplosionBorderColor shr 16);
                end;
     4: for ty:= max(-Radius, -y) to min(Radius, 1023 - y) do
            for tx:= max(0, round(ar[i].Left - radius*sqrt(1-sqr(ty/radius)))) to min(2047, round(ar[i].Right + radius*sqrt(1-sqr(ty/radius)))) do
                if PLongword(p + LandSurface.pitch*(y + ty) + tx * 4)^ <> 0 then
                   PLongword(p + LandSurface.pitch*(y + ty) + tx * 4)^:= cExplosionBorderColor;
     end;
    inc(y, dY)
    end;

if SDL_MustLock(LandSurface) then
   SDL_UnlockSurface(LandSurface);
end;

procedure StoreInit;
var r: TSDL_Rect;
begin
StoreSurface  := SDL_CreateRGBSurface(SDL_HWSURFACE, 576, 1024, cBits, PixelFormat.RMask, PixelFormat.GMask, PixelFormat.BMask, 0);
TryDo( StoreSurface <> nil, errmsgCreateSurface + ': store' , true);
r.x:= 0;
r.y:= 0;
r.w:= 576;
r.h:= 1024;
SDL_FillRect(StoreSurface, @r, 0);

TempSurface   := SDL_CreateRGBSurface(SDL_HWSURFACE, 724, 320, cBits, PixelFormat.RMask, PixelFormat.GMask, PixelFormat.BMask, 0);
TryDo(  TempSurface <> nil, errmsgCreateSurface + ': temp'  , true);

TryDo(SDL_SetColorKey( StoreSurface, SDL_SRCCOLORKEY or SDL_RLEACCEL, 0) = 0, errmsgTransparentSet, true);
//TryDo(SDL_SetColorKey(SpriteSurface, SDL_SRCCOLORKEY or SDL_RLEACCEL, 0) = 0, errmsgTransparentSet, true);
TryDo(SDL_SetColorKey(  TempSurface, SDL_SRCCOLORKEY or SDL_RLEACCEL, 0) = 0, errmsgTransparentSet, true);
end;

procedure LoadToSurface(Filename: String; Surface: PSDL_Surface; X, Y: integer);
var tmpsurf: PSDL_Surface;
    rr: TSDL_Rect;
begin
  tmpsurf:= LoadImage(Filename, false);
  rr.x:= X;
  rr.y:= Y;
  SDL_UpperBlit(tmpsurf, nil, Surface, @rr);
  SDL_FreeSurface(tmpsurf);
end;

function WriteInRoundRect(Surface: PSDL_Surface; X, Y: integer; Color: LongWord; Font: THWFont; s: string): TSDL_Rect;
var w, h: integer;
    tmpsurf: PSDL_Surface;
    clr: TSDL_Color;
begin
TTF_SizeText(Fontz[Font].Handle, PChar(s), w, h);
Result.x:= X;
Result.y:= Y;
Result.w:= w + 6;
Result.h:= h + 6;
SDL_FillRect(Surface, @Result, 0);
Result.w:= 1;
Result.y:= Y + 1;
Result.h:= h + 4;
SDL_FillRect(Surface, @Result, cWhiteColor);
Result.x:= X + w + 5;
SDL_FillRect(Surface, @Result, cWhiteColor);
Result.x:= X + 1;
Result.w:= w + 4;
Result.y:= Y;
Result.h:= 1;
SDL_FillRect(Surface, @Result, cWhiteColor);
Result.y:= Y + h + 5;
SDL_FillRect(Surface, @Result, cWhiteColor);
Result.x:= X + 1;
Result.y:= Y + 1;
Result.h:= h + 4;
SDL_FillRect(Surface, @Result, cColorNearBlack);
SDL_GetRGB(Color, Surface.format, @clr.r, @clr.g, @clr.b);
tmpsurf:= TTF_RenderText_Blended(Fontz[Font].Handle, PChar(s), clr);
Result.x:= X + 3;
Result.y:= Y + 3;
SDL_UpperBlit(tmpsurf, nil, Surface, @Result);
SDL_FreeSurface(tmpsurf);
Result.x:= X;
Result.y:= Y;
Result.w:= w + 6;
Result.h:= h + 6
end;

procedure StoreLoad;
var i: TStuff;
    ii: TSprite;
    fi: THWFont;
    s: string;
    tmpsurf: PSDL_Surface;

    procedure WriteNames(Font: THWFont);
    var Team: PTeam;
        i: integer;
        r: TSDL_Rect;
    begin
    r.x:= 0;
    r.y:= 272;
    Team:= TeamsList;
    while Team<>nil do
      begin
      r.w:= 1968;
      r:= WriteInRoundRect(StoreSurface, r.x, r.y, Team.Color, Font, Team.TeamName);
      Team.NameRect:= r;
      inc(r.y, r.h);
      for i:= 0 to 7 do
          if Team.Hedgehogs[i].Gear<>nil then
             begin
             r:= WriteInRoundRect(StoreSurface, r.x, r.y, Team.Color, Font, Team.Hedgehogs[i].Name);
             Team.Hedgehogs[i].NameRect:= r;
             inc(r.y, r.h)
             end;
      Team:= Team.Next
      end;
    end;

    procedure MakeCrossHairs;
    var Team: PTeam;
        r: TSDL_Rect;
        tmpsurf: PSDL_Surface;
        s: string;
        TransColor: Longword;
    begin
    r.x:= 0;
    r.y:= 256;
    r.w:= 16;
    r.h:= 16;
    s:= Pathz[ptGraphics] + cCHFileName;
    WriteToConsole(msgLoading + s + ' ');
    tmpsurf:= IMG_Load(PChar(s));
    TryDo(tmpsurf <> nil, msgFailed, true);
    WriteLnToConsole(msgOK);
    TransColor:= SDL_MapRGB(tmpsurf.format, $FF, $FF, $FF);
    TryDo(SDL_SetColorKey(tmpsurf, SDL_SRCCOLORKEY, TransColor) = 0, errmsgTransparentSet, true);

    Team:= TeamsList;
    while Team<>nil do
      begin
      SDL_FillRect(StoreSurface, @r, Team.Color);
      SDL_UpperBlit(tmpsurf, nil, StoreSurface, @r);
      Team.CrossHairRect:= r;
      inc(r.x, 16);
      Team:= Team.Next
      end;
      
    SDL_FreeSurface(tmpsurf)
    end;

    procedure InitHealth;
    var p: PTeam;
        i, t: integer;
    begin
    p:= TeamsList;
    t:= 0;
    while p <> nil do
          begin
          for i:= 0 to cMaxHHIndex do
              if p.Hedgehogs[i].Gear <> nil then
                 begin
                 p.Hedgehogs[i].HealthRect.y:= t;
                 RenderHealth(p.Hedgehogs[i]);
                 inc(t, p.Hedgehogs[i].HealthRect.h)
                 end;
          p:= p.Next
          end
    end;

    procedure LoadGraves;
    var p: PTeam;
        l: integer;
    begin
    p:= TeamsList;
    l:= 512;
    while p <> nil do
          begin
          dec(l, 32);
          if p.GraveName = '' then p.GraveName:= 'Simple';
          LoadToSurface(Pathz[ptGraves] + p.GraveName + '.png', StoreSurface, l, 512);
          p.GraveRect.x:= l;
          p.GraveRect.y:= 512;
          p.GraveRect.w:= 32;
          p.GraveRect.h:= 256;
          p:= p.Next
          end
    end;

    procedure GetSkyColor;
    var p: Longword;
    begin
    if SDL_MustLock(StoreSurface) then
       SDLTry(SDL_LockSurface(StoreSurface) >= 0, true);
    p:= Longword(StoreSurface.pixels) + Word(StuffPoz[sSky].x) * StoreSurface.format.BytesPerPixel;
    case StoreSurface.format.BytesPerPixel of
         1: cSkyColor:= PByte(p)^;
         2: cSkyColor:= PWord(p)^;
         3: cSkyColor:= (PByte(p)^) or (PByte(p + 1)^ shl 8) or (PByte(p + 2)^ shl 16);
         4: cSkyColor:= PLongword(p)^;
         end;
    if SDL_MustLock(StoreSurface) then
       SDL_UnlockSurface(StoreSurface)
    end;

    procedure GetExplosionBorderColor;
    var f: textfile;
        c: integer;
    begin
    s:= Pathz[ptThemeCurrent] + cThemeCFGFilename;
    WriteToConsole(msgLoading + s + ' ');
    AssignFile(f, s);
    {$I-}
    Reset(f);
    Readln(f, s);
    Closefile(f);
    {$I+}
    TryDo(IOResult = 0, msgFailed, true);
    WriteLnToConsole(msgOK);
    val(s, cExplosionBorderColor, c);
    if cFullScreen then
    cExplosionBorderColor:= SDL_MapRGB(PixelFormat, (cExplosionBorderColor shr 16) and $FF,
                                                    (cExplosionBorderColor shr 8) and $FF,
                                                     cExplosionBorderColor and $FF)
    else
    cExplosionBorderColor:= SDL_MapRGB(LandSurface.format, (cExplosionBorderColor shr 16) and $FF,
                                                           (cExplosionBorderColor shr 8) and $FF,
                                                            cExplosionBorderColor and $FF)
    end;

begin
for fi:= Low(THWFont) to High(THWFont) do
    with Fontz[fi] do
         begin
         s:= Pathz[ptFonts] + Name;
         WriteToConsole(msgLoading + s + ' ');
         Handle:= TTF_OpenFont(PChar(s), Height);
         TryDo(Handle <> nil, msgFailed, true);
         WriteLnToConsole(msgOK)
         end;
AddProgress;
//s:= Pathz[ptMapCurrent] + cLandFileName;
//WriteToConsole(msgLoading + s + ' ');         
//tmpsurf:= IMG_Load(PChar(s));
tmpsurf:= LandSurface;
TryDo(tmpsurf <> nil, msgFailed, true);
if cFullScreen then
   begin
   LandSurface:= SDL_DisplayFormat(tmpsurf);
   SDL_FreeSurface(tmpsurf);
   end else LandSurface:= tmpsurf;
TryDo(SDL_SetColorKey(LandSurface, SDL_SRCCOLORKEY, 0) = 0, errmsgTransparentSet, true);
WriteLnToConsole(msgOK);

GetExplosionBorderColor;

AddProgress;
for i:= Low(TStuff) to High(TStuff) do
    LoadToSurface(Pathz[StuffLoadData[i].Path] + StuffLoadData[i].FileName, StoreSurface, StuffPoz[i].x, StuffPoz[i].y);

AddProgress;
WriteNames(fnt16);
MakeCrosshairs;
LoadGraves;

GetSkyColor;

AddProgress;
for ii:= Low(TSprite) to High(TSprite) do
    with SpritesData[ii] do
         Surface:= LoadImage(Pathz[Path] + FileName, hasAlpha);

AddProgress;
tmpsurf:= LoadImage(Pathz[ptGraphics] + cHHFileName, false);
TryDo(SDL_SetColorKey(tmpsurf, SDL_SRCCOLORKEY or SDL_RLEACCEL, 0) = 0, errmsgTransparentSet, true);
HHSurface:= SDL_DisplayFormat(tmpsurf);
SDL_FreeSurface(tmpsurf);

InitHealth;

{$IFDEF DUMP}
SDL_SaveBMP_RW(LandSurface, SDL_RWFromFile('LandSurface.bmp', 'wb'), 1);
SDL_SaveBMP_RW(StoreSurface, SDL_RWFromFile('StoreSurface.bmp', 'wb'), 1);
SDL_SaveBMP_RW(TempSurface, SDL_RWFromFile('TempSurface.bmp', 'wb'), 1);
{$ENDIF}
end;

procedure DrawFromRect(X, Y: integer; r: PSDL_Rect; SourceSurface, DestSurface: PSDL_Surface);
var rr: TSDL_Rect;
begin
rr.x:= X;
rr.y:= Y;
rr.w:= r.w;
rr.h:= r.h;
if SDL_UpperBlit(SourceSurface, r, DestSurface, @rr) < 0 then
   begin
   Writeln('Blit: ', SDL_GetError);
   exit
   end;
end;

procedure DrawGear(Stuff: TStuff; X, Y: integer; Surface: PSDL_Surface);
begin
DrawFromRect(X, Y, @StuffPoz[Stuff], StoreSurface, Surface)
end;

procedure DrawSpriteFromRect(r: TSDL_Rect; X, Y, Height, Position: integer; Surface: PSDL_Surface);
begin
r.y:= r.y + Height * Position;
r.h:= Height;
DrawFromRect(X, Y, @r, StoreSurface, Surface)
end;

procedure DrawSprite(Sprite: TSprite; X, Y, Position: integer; Surface: PSDL_Surface);
var r: TSDL_Rect;
begin
r.x:= 0;
r.w:= SpritesData[Sprite].Width;
r.y:= Position * SpritesData[Sprite].Height;
r.h:= SpritesData[Sprite].Height;
DrawFromRect(X, Y, @r, SpritesData[Sprite].Surface, Surface)
end;

procedure DXOutText(X, Y: Integer; Font: THWFont; s: string; Surface: PSDL_Surface);
var clr: TSDL_Color;
    tmpsurf: PSDL_Surface;
    r: TSDL_Rect;
begin
r.x:= X;
r.y:= Y;
SDL_GetRGB(cWhiteColor, PixelFormat, @clr.r, @clr.g, @clr.b);
tmpsurf:= TTF_RenderText_Solid(Fontz[Font].Handle, PChar(s), clr);
SDL_UpperBlit(tmpsurf, nil, Surface, @r);
SDL_FreeSurface(tmpsurf)
end;

procedure DrawLand(X, Y: integer; Surface: PSDL_Surface);
const r: TSDL_Rect = (x: 0; y: 0; w: 2048; h: 1024);
begin
DrawFromRect(X, Y, @r, LandSurface, Surface)
end;

procedure DrawCaption(X, Y: integer; Rect: TSDL_Rect; Surface: PSDL_Surface; const fromTempSurf: boolean = false);
begin
if fromTempSurf then DrawFromRect(X - (Rect.w) div 2, Y, @Rect, TempSurface,  Surface)
                else DrawFromRect(X - (Rect.w) div 2, Y, @Rect, StoreSurface, Surface)
end;

procedure DrawHedgehog(X, Y: integer; Dir: integer; Pos, Step: LongWord; Surface: PSDL_Surface);
var r: TSDL_Rect;
begin
r.x:= Step * 32;
r.y:= Pos * 32;
if Dir = -1 then r.x:= cHHSurfaceWidth - 32 - r.x;
r.w:= 32;
r.h:= 32;
DrawFromRect(X, Y, @r, HHSurface, Surface)
end;

procedure StoreRelease;
var ii: TSprite;
begin
for ii:= Low(TSprite) to High(TSprite) do
    SDL_FreeSurface(SpritesData[ii].Surface);
SDL_FreeSurface(  HHSurface  );
SDL_FreeSurface(TempSurface  );
SDL_FreeSurface(LandSurface  );
SDL_FreeSurface(StoreSurface )
end;

procedure RenderHealth(var Hedgehog: THedgehog);
var s: string[15];
begin
str(Hedgehog.Gear.Health, s);
Hedgehog.HealthRect:= WriteInRoundRect(TempSurface, Hedgehog.HealthRect.x, Hedgehog.HealthRect.y, Hedgehog.Team.Color, fnt16, s);
if Hedgehog.Gear.Damage > 0 then
   begin
   str(Hedgehog.Gear.Damage, s);
   Hedgehog.HealthTagRect:= WriteInRoundRect(TempSurface, Hedgehog.HealthRect.x + Hedgehog.HealthRect.w, Hedgehog.HealthRect.y, Hedgehog.Team.Color, fnt16, s)
   end;
end;

function RenderString(var s: shortstring; Color, Pos: integer): TSDL_Rect;
begin
Result:= WriteInRoundRect(TempSurface, 64, Pos * Fontz[fntBig].Height, Color, fntBig, s);
end;

procedure AddProgress;
const Step: Longword = 0;
      ProgrSurf: PSDL_Surface = nil;
      MaxCalls = 10; // MaxCalls should be the count of calls to AddProgress to prevent memory leakage
var r: TSDL_Rect;
begin
if Step = 0 then
   begin
   WriteToConsole(msgLoading + 'progress sprite... ');
   ProgrSurf:= IMG_Load(PChar(string('Data/Graphics/BigDigits.png')));
   SDLTry(ProgrSurf <> nil, true);
   WriteLnToConsole(msgOK)
   end;
SDL_FillRect(SDLPrimSurface, nil, 0);
r.x:= 0;
r.w:= 32;
r.h:= 32;
r.y:= Step * 32;
DrawFromRect(cScreenWidth div 2 - 16, cScreenHeight div 2 - 16, @r, ProgrSurf, SDLPrimSurface);
SDL_Flip(SDLPrimSurface);
inc(Step);
if Step = MaxCalls then
   begin
   WriteLnToConsole('Freeing progress surface... ');
   SDL_FreeSurface(ProgrSurf)
   end;
end;

function  LoadImage(filename: string; hasAlpha: boolean): PSDL_Surface;
var tmpsurf: PSDL_Surface;
begin
WriteToConsole(msgLoading + filename + '... ');
tmpsurf:= IMG_Load(PChar(filename));
TryDo(tmpsurf <> nil, msgFailed, true);
TryDo(SDL_SetColorKey(tmpsurf, SDL_SRCCOLORKEY or SDL_RLEACCEL, 0) = 0, errmsgTransparentSet, true);
if cFullScreen then
   begin
   if hasAlpha then Result:= SDL_DisplayFormatAlpha(tmpsurf)
               else Result:= SDL_DisplayFormat(tmpsurf);
   SDL_FreeSurface(tmpsurf);
   end else Result:= tmpsurf;
WriteLnToConsole(msgOK)
end;

end.
