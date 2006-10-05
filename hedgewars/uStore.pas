(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004, 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uStore;
interface
uses uConsts, uTeams, SDLh;
{$INCLUDE options.inc}

procedure StoreInit;
procedure StoreLoad;
procedure StoreRelease;
procedure DrawGear(Stuff : TStuff; X, Y: integer; Surface: PSDL_Surface);
procedure DrawSpriteFromRect(r: TSDL_Rect; X, Y, Height, Position: integer; Surface: PSDL_Surface);
procedure DrawSprite (Sprite: TSprite; X, Y, Frame: integer; Surface: PSDL_Surface);
procedure DrawSprite2(Sprite: TSprite; X, Y, FrameX, FrameY: integer; Surface: PSDL_Surface);
procedure DrawLand (X, Y: integer; Surface: PSDL_Surface);
procedure DXOutText(X, Y: Integer; Font: THWFont; s: string; Surface: PSDL_Surface);
procedure DrawCaption(X, Y: integer; Rect: TSDL_Rect; Surface: PSDL_Surface);
procedure DrawCentered(X, Top: integer; Source, Surface: PSDL_Surface);
procedure DrawFromStoreRect(X, Y: integer; Rect: PSDL_Rect; Surface: PSDL_Surface);
procedure DrawHedgehog(X, Y: integer; Dir: integer; Pos, Step: LongWord; Surface: PSDL_Surface);
function  RenderString(s: string; Color: integer; font: THWFont): PSDL_Surface;
procedure RenderHealth(var Hedgehog: THedgehog);
procedure AddProgress;
function  LoadImage(filename: string; hasAlpha: boolean; const critical: boolean = true): PSDL_Surface;

var PixelFormat: PSDL_PixelFormat;
 SDLPrimSurface: PSDL_Surface;

implementation
uses uMisc, uIO, uConsole, uLand, uCollisions;

var StoreSurface,
       HHSurface: PSDL_Surface;

procedure StoreInit;
begin
StoreSurface:= SDL_CreateRGBSurface(SDL_HWSURFACE, 576, 1024, cBits, PixelFormat.RMask, PixelFormat.GMask, PixelFormat.BMask, 0);
TryDo( StoreSurface <> nil, errmsgCreateSurface + ': store' , true);
SDL_FillRect(StoreSurface, nil, 0);

TryDo(SDL_SetColorKey( StoreSurface, SDL_SRCCOLORKEY or SDL_RLEACCEL, 0) = 0, errmsgTransparentSet, true);
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

procedure DrawRoundRect(rect: PSDL_Rect; BorderColor, FillColor: Longword; Surface: PSDL_Surface; const Clear: boolean = true);
var r: TSDL_Rect;
begin
r:= rect^;
if Clear then SDL_FillRect(Surface, @r, 0);
r.y:= rect.y + 1;
r.h:= rect.h - 2;
SDL_FillRect(Surface, @r, BorderColor);
r.x:= rect.x + 1;
r.w:= rect.w - 2;
r.y:= rect.y;
r.h:= rect.h;
SDL_FillRect(Surface, @r, BorderColor);
r.x:= rect.x + 2;
r.y:= rect.y + 1;
r.w:= rect.w - 4;
r.h:= rect.h - 2;
SDL_FillRect(Surface, @r, FillColor);
r.x:= rect.x + 1;
r.y:= rect.y + 2;
r.w:= rect.w - 2;
r.h:= rect.h - 4;
SDL_FillRect(Surface, @r, FillColor)
end;

function WriteInRoundRect(Surface: PSDL_Surface; X, Y: integer; Color: LongWord; Font: THWFont; s: string): TSDL_Rect;
var w, h: integer;
    tmpsurf: PSDL_Surface;
    clr: TSDL_Color;
begin
TTF_SizeUTF8(Fontz[Font].Handle, PChar(s), w, h);
Result.x:= X;
Result.y:= Y;
Result.w:= w + 6;
Result.h:= h + 2;
DrawRoundRect(@Result, cWhiteColor, cColorNearBlack, Surface);
SDL_GetRGB(Color, Surface.format, @clr.r, @clr.g, @clr.b);
tmpsurf:= TTF_RenderUTF8_Blended(Fontz[Font].Handle, PChar(s), clr);
Result.x:= X + 3;
Result.y:= Y + 1;
SDL_UpperBlit(tmpsurf, nil, Surface, @Result);
SDL_FreeSurface(tmpsurf);
Result.x:= X;
Result.y:= Y;
Result.w:= w + 6;
Result.h:= h + 2
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
        r, rr: TSDL_Rect;
        drY: integer;
    begin
    r.x:= 0;
    r.y:= 272;
    drY:= cScreenHeight - 4;
    Team:= TeamsList;
    while Team<>nil do
      begin
      r.w:= 104;
      Team.NameTag:= RenderString(Team.TeamName, Team.Color, Font);
      r.w:= cTeamHealthWidth + 5;
      r.h:= Team.NameTag.h;
      DrawRoundRect(@r, cWhiteColor, cColorNearBlack, StoreSurface);
      Team.HealthRect:= r;
      rr:= r;
      inc(rr.x, 2); dec(rr.w, 4); inc(rr.y, 2); dec(rr.h, 4);
      DrawRoundRect(@rr, Team.Color, Team.Color, StoreSurface, false);
      inc(r.y, r.h);
      dec(drY, r.h + 2);
      Team.DrawHealthY:= drY;
      for i:= 0 to 7 do
          with Team.Hedgehogs[i] do
               if Gear <> nil then
                  NameTag:= RenderString(Name, Team.Color, fnt16);
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
    s:= Pathz[ptGraphics] + '/' + cCHFileName;
    tmpsurf:= LoadImage(PChar(s), false);
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
        i: integer;
    begin
    p:= TeamsList;
    while p <> nil do
          begin
          for i:= 0 to cMaxHHIndex do
              if p.Hedgehogs[i].Gear <> nil then
                 RenderHealth(p.Hedgehogs[i]);
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
          LoadToSurface(Pathz[ptGraves] + '/' + p.GraveName, StoreSurface, l, 512);
          p.GraveRect.x:= l;
          p.GraveRect.y:= 512;
          p.GraveRect.w:= 32;
          p.GraveRect.h:= 256;
          p:= p.Next
          end
    end;

    procedure GetSkyColor;
    var p: PByteArray;
    begin
    if SDL_MustLock(SpritesData[sprSky].Surface) then
       SDLTry(SDL_LockSurface(SpritesData[sprSky].Surface) >= 0, true);
    p:= SpritesData[sprSky].Surface.pixels;
    case SpritesData[sprSky].Surface.format.BytesPerPixel of
         1: cSkyColor:= PByte(p)^;
         2: cSkyColor:= PWord(p)^;
         3: cSkyColor:= (p^[0]) or (p^[1] shl 8) or (p^[2] shl 16);
         4: cSkyColor:= PLongword(p)^;
         end;
    if SDL_MustLock(SpritesData[sprSky].Surface) then
       SDL_UnlockSurface(SpritesData[sprSky].Surface)
    end;

    procedure GetExplosionBorderColor;
    var f: textfile;
        c: integer;
    begin
    s:= Pathz[ptCurrTheme] + '/' + cThemeCFGFilename;
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
         s:= Pathz[ptFonts] + '/' + Name;
         WriteToConsole(msgLoading + s + ' ');
         Handle:= TTF_OpenFont(PChar(s), Height);
         TryDo(Handle <> nil, msgFailed, true);
         WriteLnToConsole(msgOK)
         end;
AddProgress;

WriteToConsole('LandSurface tuning... ');
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
    LoadToSurface(Pathz[StuffLoadData[i].Path] + '/' + StuffLoadData[i].FileName, StoreSurface, StuffPoz[i].x, StuffPoz[i].y);

AddProgress;
WriteNames(fnt16);
MakeCrossHairs;
LoadGraves;

AddProgress;
for ii:= Low(TSprite) to High(TSprite) do
    with SpritesData[ii] do
         begin
         if AltPath = ptNone then
            Surface:= LoadImage(Pathz[Path] + '/' + FileName, hasAlpha)
         else begin
            Surface:= LoadImage(Pathz[Path] + '/' + FileName, hasAlpha, false);
            if Surface = nil then
               Surface:= LoadImage(Pathz[AltPath] + '/' + FileName, hasAlpha)
            end;
         if Width = 0 then Width:= Surface.w;
         if Height = 0 then Height:= Surface.h
         end;

GetSkyColor;

AddProgress;
tmpsurf:= LoadImage(Pathz[ptGraphics] + '/' + cHHFileName, false);
TryDo(SDL_SetColorKey(tmpsurf, SDL_SRCCOLORKEY or SDL_RLEACCEL, 0) = 0, errmsgTransparentSet, true);
HHSurface:= SDL_DisplayFormat(tmpsurf);
SDL_FreeSurface(tmpsurf);

InitHealth;

{$IFDEF DUMP}
SDL_SaveBMP_RW(LandSurface, SDL_RWFromFile('LandSurface.bmp', 'wb'), 1);
SDL_SaveBMP_RW(StoreSurface, SDL_RWFromFile('StoreSurface.bmp', 'wb'), 1);
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
   OutError('Blit: ' + SDL_GetError, true);
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

procedure DrawSprite (Sprite: TSprite; X, Y, Frame: integer; Surface: PSDL_Surface);
var r: TSDL_Rect;
begin
r.x:= 0;
r.w:= SpritesData[Sprite].Width;
r.y:= Frame * SpritesData[Sprite].Height;
r.h:= SpritesData[Sprite].Height;
DrawFromRect(X, Y, @r, SpritesData[Sprite].Surface, Surface)
end;

procedure DrawSprite2(Sprite: TSprite; X, Y, FrameX, FrameY: integer; Surface: PSDL_Surface);
var r: TSDL_Rect;
begin
r.x:= FrameX * SpritesData[Sprite].Width;
r.w:= SpritesData[Sprite].Width;
r.y:= FrameY * SpritesData[Sprite].Height;
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
tmpsurf:= TTF_RenderUTF8_Solid(Fontz[Font].Handle, PChar(s), clr);
SDL_UpperBlit(tmpsurf, nil, Surface, @r);
SDL_FreeSurface(tmpsurf)
end;

procedure DrawLand(X, Y: integer; Surface: PSDL_Surface);
const r: TSDL_Rect = (x: 0; y: 0; w: 2048; h: 1024);
begin
DrawFromRect(X, Y, @r, LandSurface, Surface)
end;

procedure DrawFromStoreRect(X, Y: integer; Rect: PSDL_Rect; Surface: PSDL_Surface);
begin
DrawFromRect(X, Y, Rect, StoreSurface, Surface)
end;

procedure DrawCaption(X, Y: integer; Rect: TSDL_Rect; Surface: PSDL_Surface);
begin
DrawFromRect(X - (Rect.w) div 2, Y, @Rect, StoreSurface, Surface)
end;

procedure DrawCentered(X, Top: integer; Source, Surface: PSDL_Surface);
var r: TSDL_Rect;
begin
r.x:= X - Source.w div 2;
r.y:= Top;
r.w:= Source.w;
r.h:= Source.h;
SDL_UpperBlit(Source, nil, Surface, @r)
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
SDL_FreeSurface(LandSurface  );
SDL_FreeSurface(StoreSurface )
end;

function  RenderString(s: string; Color: integer; font: THWFont): PSDL_Surface;
var w, h: integer;
begin
TTF_SizeUTF8(Fontz[font].Handle, PChar(s), w, h);
Result:= SDL_CreateRGBSurface(SDL_HWSURFACE, w + 6, h + 2, cBits, PixelFormat.RMask, PixelFormat.GMask, PixelFormat.BMask, 0);
TryDo(Result <> nil, 'RenderString: fail to create surface', true);
WriteInRoundRect(Result, 0, 0, Color, font, s);
TryDo(SDL_SetColorKey(Result, SDL_SRCCOLORKEY or SDL_RLEACCEL, 0) = 0, errmsgTransparentSet, true)
end;

procedure RenderHealth(var Hedgehog: THedgehog);
var s: shortstring;
begin
str(Hedgehog.Gear.Health, s);
if Hedgehog.HealthTag <> nil then SDL_FreeSurface(Hedgehog.HealthTag);
Hedgehog.HealthTag:= RenderString(s, Hedgehog.Team^.Color, fnt16)
end;

procedure AddProgress;
const Step: Longword = 0;
      ProgrSurf: PSDL_Surface = nil;
      MaxCalls = 11; // MaxCalls should be the count of calls to AddProgress to prevent memory leakage
var r: TSDL_Rect;
begin
if Step = 0 then
   begin
   WriteToConsole(msgLoading + 'progress sprite: ');
   ProgrSurf:= LoadImage(Pathz[ptGraphics] + '/BigDigits', false);
   end;
SDL_FillRect(SDLPrimSurface, nil, 0);
r.x:= 0;
r.w:= 32;
r.h:= 32;
r.y:= (Step mod 10) * 32;
DrawFromRect(cScreenWidth div 2 - 16, cScreenHeight div 2 - 16, @r, ProgrSurf, SDLPrimSurface);
SDL_Flip(SDLPrimSurface);
inc(Step);
if Step = MaxCalls then
   begin
   WriteLnToConsole('Freeing progress surface... ');
   SDL_FreeSurface(ProgrSurf)
   end;
end;

function  LoadImage(filename: string; hasAlpha: boolean; const critical: boolean = true): PSDL_Surface;
var tmpsurf: PSDL_Surface;
begin
WriteToConsole(msgLoading + filename + '... ');
tmpsurf:= IMG_Load(PChar(filename + '.' + cBitsStr + '.png'));
if tmpsurf = nil then
   tmpsurf:= IMG_Load(PChar(filename + '.png'));

if tmpsurf = nil then
   if critical then OutError(msgFailed, true)
      else begin
      WriteLnToConsole(msgFailed);
      Result:= nil;
      exit
      end;
      
TryDo(SDL_SetColorKey(tmpsurf, SDL_SRCCOLORKEY or SDL_RLEACCEL, 0) = 0, errmsgTransparentSet, true);
if hasAlpha then Result:= SDL_DisplayFormatAlpha(tmpsurf)
            else Result:= SDL_DisplayFormat(tmpsurf);
WriteLnToConsole(msgOK)
end;

end.
