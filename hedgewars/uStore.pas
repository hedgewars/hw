(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004-2007 Andrey Korotaev <unC0Rr@gmail.com>
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
uses uConsts, uTeams, SDLh, uFloat;
{$INCLUDE options.inc}

procedure StoreInit;
procedure StoreLoad;
procedure StoreRelease;
procedure DrawSpriteFromRect(Sprite: TSprite; r: TSDL_Rect; X, Y, Height, Position: LongInt; Surface: PSDL_Surface);
procedure DrawSprite (Sprite: TSprite; X, Y, Frame: LongInt; Surface: PSDL_Surface);
procedure DrawSprite2(Sprite: TSprite; X, Y, FrameX, FrameY: LongInt; Surface: PSDL_Surface);
procedure DrawSurfSprite(X, Y, Height, Frame: LongInt; Source, Surface: PSDL_Surface);
procedure DrawLand (X, Y: LongInt; Surface: PSDL_Surface);
procedure DXOutText(X, Y: LongInt; Font: THWFont; s: string; Surface: PSDL_Surface);
procedure DrawCentered(X, Top: LongInt; Source, Surface: PSDL_Surface);
procedure DrawFromRect(X, Y: LongInt; r: PSDL_Rect; SourceSurface, DestSurface: PSDL_Surface);
procedure DrawHedgehog(X, Y: LongInt; Dir: LongInt; Pos, Step: LongWord; Surface: PSDL_Surface);
function  RenderString(s: string; Color: Longword; font: THWFont): PSDL_Surface;
procedure RenderHealth(var Hedgehog: THedgehog);
procedure AddProgress;
procedure FinishProgress;
function  LoadImage(const filename: string; hasAlpha, critical, setTransparent: boolean): PSDL_Surface;

var PixelFormat: PSDL_PixelFormat;
 SDLPrimSurface: PSDL_Surface;
   PauseSurface: PSDL_Surface;

implementation
uses uMisc, uConsole, uLand, uLocale;

var
    HHSurface: PSDL_Surface;

procedure StoreInit;
begin

end;

procedure DrawRoundRect(rect: PSDL_Rect; BorderColor, FillColor: Longword; Surface: PSDL_Surface; Clear: boolean);
var r: TSDL_Rect;
begin
r:= rect^;
if Clear then SDL_FillRect(Surface, @r, 0);
r.y:= rect^.y + 1;
r.h:= rect^.h - 2;
SDL_FillRect(Surface, @r, BorderColor);
r.x:= rect^.x + 1;
r.w:= rect^.w - 2;
r.y:= rect^.y;
r.h:= rect^.h;
SDL_FillRect(Surface, @r, BorderColor);
r.x:= rect^.x + 2;
r.y:= rect^.y + 1;
r.w:= rect^.w - 4;
r.h:= rect^.h - 2;
SDL_FillRect(Surface, @r, FillColor);
r.x:= rect^.x + 1;
r.y:= rect^.y + 2;
r.w:= rect^.w - 2;
r.h:= rect^.h - 4;
SDL_FillRect(Surface, @r, FillColor)
end;

function WriteInRoundRect(Surface: PSDL_Surface; X, Y: LongInt; Color: LongWord; Font: THWFont; s: string): TSDL_Rect;
var w, h: LongInt;
    tmpsurf: PSDL_Surface;
    clr: TSDL_Color;
    Result: TSDL_Rect;
begin
TTF_SizeUTF8(Fontz[Font].Handle, Str2PChar(s), w, h);
Result.x:= X;
Result.y:= Y;
Result.w:= w + FontBorder * 2 + 4;
Result.h:= h + FontBorder * 2;
DrawRoundRect(@Result, cWhiteColor, cColorNearBlack, Surface, true);
clr.r:= Color shr 16;
clr.g:= (Color shr 8) and $FF;
clr.b:= Color and $FF;
tmpsurf:= TTF_RenderUTF8_Blended(Fontz[Font].Handle, Str2PChar(s), clr.value);
Result.x:= X + FontBorder + 2;
Result.y:= Y + FontBorder;
SDLTry(tmpsurf <> nil, true);
SDL_UpperBlit(tmpsurf, nil, Surface, @Result);
SDL_FreeSurface(tmpsurf);
Result.x:= X;
Result.y:= Y;
Result.w:= w + FontBorder * 2 + 4;
Result.h:= h + FontBorder * 2;
WriteInRoundRect:= Result
end;

procedure StoreLoad;
var ii: TSprite;
    fi: THWFont;
    s: string;
    tmpsurf: PSDL_Surface;

    procedure WriteNames(Font: THWFont);
    var t: LongInt;
        i: LongInt;
        r, rr: TSDL_Rect;
        drY: LongInt;
    begin
    r.x:= 0;
    r.y:= 0;
    drY:= cScreenHeight - 4;
    for t:= 0 to Pred(TeamsCount) do
     with TeamsArray[t]^ do
      begin
      NameTag:= RenderString(TeamName, Clan^.Color, Font);

      r.w:= cTeamHealthWidth + 5;
      r.h:= NameTag^.h;

      HealthSurf:= SDL_CreateRGBSurface(SDL_HWSURFACE, r.w, r.h, cBits, PixelFormat^.RMask, PixelFormat^.GMask, PixelFormat^.BMask, PixelFormat^.AMask);
      TryDo(HealthSurf <> nil, errmsgCreateSurface, true);

      DrawRoundRect(@r, cWhiteColor, cColorNearBlack, HealthSurf, true);
      rr:= r;
      inc(rr.x, 2); dec(rr.w, 4); inc(rr.y, 2); dec(rr.h, 4);
      DrawRoundRect(@rr, Clan^.AdjColor, Clan^.AdjColor, HealthSurf, false);

      dec(drY, r.h + 2);
      DrawHealthY:= drY;
      for i:= 0 to 7 do
          with Hedgehogs[i] do
               if Gear <> nil then
                  NameTag:= RenderString(Name, Clan^.Color, fnt16);
      end;
    end;

    procedure MakeCrossHairs;
    var t: LongInt;
        tmpsurf: PSDL_Surface;
        s: string;
    begin
    s:= Pathz[ptGraphics] + '/' + cCHFileName;
    tmpsurf:= LoadImage(s, true, true, false);

    for t:= 0 to Pred(TeamsCount) do
      with TeamsArray[t]^ do
      begin
      CrosshairSurf:= SDL_CreateRGBSurface(SDL_HWSURFACE, tmpsurf^.w, tmpsurf^.h, cBits, PixelFormat^.RMask, PixelFormat^.GMask, PixelFormat^.BMask, PixelFormat^.AMask);
      TryDo(CrosshairSurf <> nil, errmsgCreateSurface, true);
      SDL_FillRect(CrosshairSurf, nil, Clan^.AdjColor);
      SDL_UpperBlit(tmpsurf, nil, CrosshairSurf, nil);
      TryDo(SDL_SetColorKey(CrosshairSurf, SDL_SRCCOLORKEY or SDL_RLEACCEL, 0) = 0, errmsgTransparentSet, true);
      end;

    SDL_FreeSurface(tmpsurf)
    end;

    procedure InitHealth;
    var i, t: LongInt;
    begin
    for t:= 0 to Pred(TeamsCount) do
     if TeamsArray[t] <> nil then
      with TeamsArray[t]^ do
          begin
          for i:= 0 to cMaxHHIndex do
              if Hedgehogs[i].Gear <> nil then
                 RenderHealth(Hedgehogs[i]);
          end
    end;

    procedure LoadGraves;
    var t: LongInt;
    begin
    for t:= 0 to Pred(TeamsCount) do
     if TeamsArray[t] <> nil then
      with TeamsArray[t]^ do
          begin
          if GraveName = '' then GraveName:= 'Simple';
          GraveSurf:= LoadImage(Pathz[ptGraves] + '/' + GraveName, false, true, true);
          end
    end;

    procedure GetSkyColor;
    var p: PByteArray;
    begin
    if SDL_MustLock(SpritesData[sprSky].Surface) then
       SDLTry(SDL_LockSurface(SpritesData[sprSky].Surface) >= 0, true);
    p:= SpritesData[sprSky].Surface^.pixels;
    case SpritesData[sprSky].Surface^.format^.BytesPerPixel of
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
        c: LongInt;
    begin
    s:= Pathz[ptCurrTheme] + '/' + cThemeCFGFilename;
    WriteToConsole(msgLoading + s + ' ');
    Assign(f, s);
    {$I-}
    Reset(f);
    Readln(f, s);
    Close(f);
    {$I+}
    TryDo(IOResult = 0, msgFailed, true);
    WriteLnToConsole(msgOK);
    val(s, cExplosionBorderColor, c);
    TryDo(c = 0, 'Theme data corrupted', true);
    AdjustColor(cExplosionBorderColor);
    end;

begin
for fi:= Low(THWFont) to High(THWFont) do
    with Fontz[fi] do
         begin
         s:= Pathz[ptFonts] + '/' + Name;
         WriteToConsole(msgLoading + s + '... ');
         Handle:= TTF_OpenFont(Str2PChar(s), Height);
         SDLTry(Handle <> nil, true);
         TTF_SetFontStyle(Handle, style);
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
WriteNames(fnt16);
MakeCrossHairs;
LoadGraves;

AddProgress;
for ii:= Low(TSprite) to High(TSprite) do
    with SpritesData[ii] do
         begin
         if AltPath = ptNone then
            Surface:= LoadImage(Pathz[Path] + '/' + FileName, hasAlpha, true, true)
         else begin
            Surface:= LoadImage(Pathz[Path] + '/' + FileName, hasAlpha, false, true);
            if Surface = nil then
               Surface:= LoadImage(Pathz[AltPath] + '/' + FileName, hasAlpha, true, true)
            end;
         if Width = 0 then Width:= Surface^.w;
         if Height = 0 then Height:= Surface^.h
         end;

GetSkyColor;

AddProgress;

HHSurface:= LoadImage(Pathz[ptGraphics] + '/' + cHHFileName, true, true, true);

InitHealth;

PauseSurface:= RenderString(trmsg[sidPaused], $FFFF00, fntBig);

{$IFDEF DUMP}
SDL_SaveBMP_RW(LandSurface, SDL_RWFromFile('LandSurface.bmp', 'wb'), 1);
SDL_SaveBMP_RW(StoreSurface, SDL_RWFromFile('StoreSurface.bmp', 'wb'), 1);
{$ENDIF}
end;

procedure DrawFromRect(X, Y: LongInt; r: PSDL_Rect; SourceSurface, DestSurface: PSDL_Surface);
var rr: TSDL_Rect;
begin
rr.x:= X;
rr.y:= Y;
rr.w:= r^.w;
rr.h:= r^.h;
if SDL_UpperBlit(SourceSurface, r, DestSurface, @rr) < 0 then
   begin
   OutError('Blit: ' + SDL_GetError, true);
   exit
   end;
end;

procedure DrawSpriteFromRect(Sprite: TSprite; r: TSDL_Rect; X, Y, Height, Position: LongInt; Surface: PSDL_Surface);
begin
r.y:= r.y + Height * Position;
r.h:= Height;
DrawFromRect(X, Y, @r, SpritesData[Sprite].Surface, Surface)
end;

procedure DrawSprite (Sprite: TSprite; X, Y, Frame: LongInt; Surface: PSDL_Surface);
begin
DrawSurfSprite(X, Y, SpritesData[Sprite].Height, Frame, SpritesData[Sprite].Surface, Surface)
end;

procedure DrawSprite2(Sprite: TSprite; X, Y, FrameX, FrameY: LongInt; Surface: PSDL_Surface);
var r: TSDL_Rect;
begin
r.x:= FrameX * SpritesData[Sprite].Width;
r.w:= SpritesData[Sprite].Width;
r.y:= FrameY * SpritesData[Sprite].Height;
r.h:= SpritesData[Sprite].Height;
DrawFromRect(X, Y, @r, SpritesData[Sprite].Surface, Surface)
end;

procedure DrawSurfSprite(X, Y, Height, Frame: LongInt; Source, Surface: PSDL_Surface);
var r: TSDL_Rect;
begin
r.x:= 0;
r.w:= Source^.w;
r.y:= Frame * Height;
r.h:= Height;
DrawFromRect(X, Y, @r, Source, Surface)
end;

procedure DXOutText(X, Y: LongInt; Font: THWFont; s: string; Surface: PSDL_Surface);
var clr: TSDL_Color;
    tmpsurf: PSDL_Surface;
    r: TSDL_Rect;
begin
r.x:= X;
r.y:= Y;
clr.r:= $FF;
clr.g:= $FF;
clr.b:= $FF;
tmpsurf:= TTF_RenderUTF8_Solid(Fontz[Font].Handle, Str2PChar(s), clr.value);
if tmpsurf = nil then
   begin
   SetKB(1);
   exit
   end;
SDL_UpperBlit(tmpsurf, nil, Surface, @r);
SDL_FreeSurface(tmpsurf)
end;

procedure DrawLand(X, Y: LongInt; Surface: PSDL_Surface);
const r: TSDL_Rect = (x: 0; y: 0; w: 2048; h: 1024);
begin
DrawFromRect(X, Y, @r, LandSurface, Surface)
end;

procedure DrawCentered(X, Top: LongInt; Source, Surface: PSDL_Surface);
var r: TSDL_Rect;
begin
r.x:= X - Source^.w div 2;
r.y:= Top;
r.w:= Source^.w;
r.h:= Source^.h;
SDL_UpperBlit(Source, nil, Surface, @r)
end;

procedure DrawHedgehog(X, Y: LongInt; Dir: LongInt; Pos, Step: LongWord; Surface: PSDL_Surface);
var r: TSDL_Rect;
begin
r.x:= Step * 32;
r.y:= Pos * 32;
if Dir = -1 then r.x:= HHSurface^.w - 32 - r.x;
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
SDL_FreeSurface(LandSurface  )
end;

function  RenderString(s: string; Color: Longword; font: THWFont): PSDL_Surface;
var w, h: LongInt;
    Result: PSDL_Surface;
begin
TTF_SizeUTF8(Fontz[font].Handle, Str2PChar(s), w, h);
Result:= SDL_CreateRGBSurface(SDL_HWSURFACE, w + FontBorder * 2 + 4, h + FontBorder * 2,
         cBits, PixelFormat^.RMask, PixelFormat^.GMask, PixelFormat^.BMask, PixelFormat^.AMask);
TryDo(Result <> nil, 'RenderString: fail to create surface', true);
WriteInRoundRect(Result, 0, 0, Color, font, s);
TryDo(SDL_SetColorKey(Result, SDL_SRCCOLORKEY or SDL_RLEACCEL, 0) = 0, errmsgTransparentSet, true);
RenderString:= Result
end;

procedure RenderHealth(var Hedgehog: THedgehog);
var s: shortstring;
begin
str(Hedgehog.Gear^.Health, s);
if Hedgehog.HealthTag <> nil then SDL_FreeSurface(Hedgehog.HealthTag);
Hedgehog.HealthTag:= RenderString(s, Hedgehog.Team^.Clan^.Color, fnt16)
end;

function  LoadImage(const filename: string; hasAlpha: boolean; critical, setTransparent: boolean): PSDL_Surface;
var tmpsurf: PSDL_Surface;
    Result: PSDL_Surface;
    s: shortstring;
begin
WriteToConsole(msgLoading + filename + '... ');
s:= filename + '.' + cBitsStr + '.png';
tmpsurf:= IMG_Load(Str2PChar(s));

if tmpsurf = nil then
   begin
   s:= filename + '.png';
   tmpsurf:= IMG_Load(Str2PChar(s));
   end;

if tmpsurf = nil then
   if critical then OutError(msgFailed, true)
      else begin
      WriteLnToConsole(msgFailed);
      exit(nil)
      end;

if setTransparent then TryDo(SDL_SetColorKey(tmpsurf, SDL_SRCCOLORKEY or SDL_RLEACCEL, 0) = 0, errmsgTransparentSet, true);
if hasAlpha then Result:= SDL_DisplayFormatAlpha(tmpsurf)
            else Result:= SDL_DisplayFormat(tmpsurf);
{$IFDEF DEBUGFILE}WriteLnToConsole('(' + inttostr(tmpsurf^.w) + ',' + inttostr(tmpsurf^.h) + ') ');{$ENDIF}
WriteLnToConsole(msgOK);
LoadImage:= Result
end;

////////////////////////////////////////////////////////////////////////////////
var ProgrSurf: PSDL_Surface = nil;
    Step: integer = 0;

procedure AddProgress;
var r: TSDL_Rect;
begin
if Step = 0 then
   begin
   WriteToConsole(msgLoading + 'progress sprite: ');
   ProgrSurf:= LoadImage(Pathz[ptGraphics] + '/Progress', false, true, true);
   end;
SDL_FillRect(SDLPrimSurface, nil, 0);
r.x:= 0;
r.w:= ProgrSurf^.w;
r.h:= ProgrSurf^.w;
r.y:= (Step mod (ProgrSurf^.h div ProgrSurf^.w)) * ProgrSurf^.w;
DrawFromRect((cScreenWidth - ProgrSurf^.w) div 2,
             (cScreenHeight - ProgrSurf^.w) div 2, @r, ProgrSurf, SDLPrimSurface);
SDL_Flip(SDLPrimSurface);
inc(Step);
end;

procedure FinishProgress;
begin
WriteLnToConsole('Freeing progress surface... ');
SDL_FreeSurface(ProgrSurf)
end;

end.
