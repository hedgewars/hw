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
uses uConsts, uTeams, SDLh, uFloat, GL;
{$INCLUDE options.inc}

procedure StoreInit;
procedure StoreLoad;
procedure StoreRelease;
procedure DrawSpriteFromRect(Sprite: TSprite; r: TSDL_Rect; X, Y, Height, Position: LongInt; Surface: PSDL_Surface);
procedure DrawSprite (Sprite: TSprite; X, Y, Frame: LongInt; Surface: PSDL_Surface);
procedure DrawSprite2(Sprite: TSprite; X, Y, FrameX, FrameY: LongInt; Surface: PSDL_Surface);
procedure DrawSurfSprite(X, Y, Height, Frame: LongInt; Source: PTexture; Surface: PSDL_Surface);
procedure DrawLand (X, Y: LongInt);
procedure DrawTexture(X, Y: LongInt; Texture: PTexture);
procedure DrawRotated(Sprite: TSprite; X, Y: LongInt; Angle: real);
procedure DrawRotatedF(Sprite: TSprite; X, Y, Frame: LongInt; Angle: real);
procedure DrawRotatedTex(Tex: PTexture; hw, hh, X, Y: LongInt; Angle: real);
procedure DXOutText(X, Y: LongInt; Font: THWFont; s: string; Surface: PSDL_Surface);
procedure DrawCentered(X, Top: LongInt; Source: PTexture);
procedure DrawFromRect(X, Y: LongInt; r: PSDL_Rect; SourceTexture: PTexture; DestSurface: PSDL_Surface);
procedure DrawHedgehog(X, Y: LongInt; Dir: LongInt; Pos, Step: LongWord; Surface: PSDL_Surface);
function  RenderStringTex(s: string; Color: Longword; font: THWFont): PTexture;
procedure RenderHealth(var Hedgehog: THedgehog);
procedure AddProgress;
procedure FinishProgress;
function  LoadImage(const filename: string; hasAlpha, critical, setTransparent: boolean): PSDL_Surface;
procedure SetupOpenGL;

var PixelFormat: PSDL_PixelFormat;
 SDLPrimSurface: PSDL_Surface;
   PauseTexture: PTexture;

implementation
uses uMisc, uConsole, uLand, uLocale, GLU;

var
    HHTexture: PTexture;

procedure StoreInit;
begin

end;

procedure DrawRoundRect(rect: PSDL_Rect; BorderColor, FillColor: Longword; Surface: PSDL_Surface; Clear: boolean);
var r: TSDL_Rect;
begin
r:= rect^;
if Clear then SDL_FillRect(Surface, @r, 0);

BorderColor:= SDL_MapRGB(Surface^.format, BorderColor shr 16, BorderColor shr 8, BorderColor and $FF);
FillColor:= SDL_MapRGB(Surface^.format, FillColor shr 16, FillColor shr 8, FillColor and $FF);

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
        texsurf: PSDL_Surface;
    begin
    r.x:= 0;
    r.y:= 0;
    drY:= cScreenHeight - 4;
    for t:= 0 to Pred(TeamsCount) do
     with TeamsArray[t]^ do
      begin
      NameTagTex:= RenderStringTex(TeamName, Clan^.Color, Font);

      r.w:= cTeamHealthWidth + 5;
      r.h:= NameTagTex^.h;

      texsurf:= SDL_CreateRGBSurface(SDL_SWSURFACE, r.w, r.h, 32, RMask, GMask, BMask, AMask);
      TryDo(texsurf <> nil, errmsgCreateSurface, true);
      TryDo(SDL_SetColorKey(texsurf, SDL_SRCCOLORKEY, 0) = 0, errmsgTransparentSet, true);

      DrawRoundRect(@r, cWhiteColor, cColorNearBlack, texsurf, true);
      rr:= r;
      inc(rr.x, 2); dec(rr.w, 4); inc(rr.y, 2); dec(rr.h, 4);
      DrawRoundRect(@rr, Clan^.Color, Clan^.Color, texsurf, false);
      HealthTex:= Surface2Tex(texsurf);
      SDL_FreeSurface(texsurf);

      dec(drY, r.h + 2);
      DrawHealthY:= drY;
      for i:= 0 to 7 do
          with Hedgehogs[i] do
               if Gear <> nil then
                  NameTagTex:= RenderStringTex(Name, Clan^.Color, fnt16);
      end;
    end;

    procedure MakeCrossHairs;
    var t: LongInt;
        tmpsurf, texsurf: PSDL_Surface;
        s: string;
        Color, i: Longword;
    begin
    s:= Pathz[ptGraphics] + '/' + cCHFileName;
    tmpsurf:= LoadImage(s, true, true, false);

    for t:= 0 to Pred(TeamsCount) do
      with TeamsArray[t]^ do
      begin
      texsurf:= SDL_CreateRGBSurface(SDL_SWSURFACE, tmpsurf^.w, tmpsurf^.h, 32, RMask, GMask, BMask, AMask);
      TryDo(texsurf <> nil, errmsgCreateSurface, true);

      Color:= Clan^.Color;
      Color:= SDL_MapRGB(texsurf^.format, Color shr 16, Color shr 8, Color and $FF);
      SDL_FillRect(texsurf, nil, Color);

      SDL_UpperBlit(tmpsurf, nil, texsurf, nil);

      TryDo(tmpsurf^.format^.BytesPerPixel = 4, 'Ooops', true);

      if SDL_MustLock(texsurf) then
         SDLTry(SDL_LockSurface(texsurf) >= 0, true);

      // make black pixel be alpha-transparent
      for i:= 0 to texsurf^.w * texsurf^.h - 1 do
          if PLongwordArray(texsurf^.pixels)^[i] = $FF000000 then PLongwordArray(texsurf^.pixels)^[i]:= 0;

      if SDL_MustLock(texsurf) then
         SDL_UnlockSurface(texsurf);

      CrosshairTex:= Surface2Tex(texsurf);
      SDL_FreeSurface(texsurf)
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
        texsurf: PSDL_Surface;
    begin
    for t:= 0 to Pred(TeamsCount) do
     if TeamsArray[t] <> nil then
      with TeamsArray[t]^ do
          begin
          if GraveName = '' then GraveName:= 'Simple';
          texsurf:= LoadImage(Pathz[ptGraves] + '/' + GraveName, false, true, true);
          GraveTex:= Surface2Tex(texsurf);
          SDL_FreeSurface(texsurf)
          end
    end;

    procedure GetExplosionBorderColor;
    var f: textfile;
        s1, s2: shortstring;
        c1, c2: TSDL_Color;
    begin
    s:= Pathz[ptCurrTheme] + '/' + cThemeCFGFilename;
    WriteToConsole(msgLoading + s + ' ');
    Assign(f, s);
    {$I-}
    Reset(f);
    Readln(f, c1.r, c1.g, c1. b);
    Readln(f, c2.r, c2.g, c2. b);
    Close(f);
    {$I+}
    TryDo(IOResult = 0, msgFailed, true);
    WriteLnToConsole(msgOK);

    glClearColor(c1.r / 255, c1.g / 255, c1.b / 255, 0.99); // sky color
    cExplosionBorderColor:= c2.value or
                            $FF000000
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
            tmpsurf:= LoadImage(Pathz[Path] + '/' + FileName, true, true, true)
         else begin
            tmpsurf:= LoadImage(Pathz[Path] + '/' + FileName, true, false, true);
            if tmpsurf = nil then
               tmpsurf:= LoadImage(Pathz[AltPath] + '/' + FileName, true, true, true)
            end;
         if Width = 0 then Width:= tmpsurf^.w;
         if Height = 0 then Height:= tmpsurf^.h;
         Texture:= Surface2Tex(tmpsurf);
         if saveSurf then Surface:= tmpsurf else SDL_FreeSurface(tmpsurf)
         end;

AddProgress;

tmpsurf:= LoadImage(Pathz[ptGraphics] + '/' + cHHFileName, true, true, true);
HHTexture:= Surface2Tex(tmpsurf);
SDL_FreeSurface(tmpsurf);

InitHealth;

PauseTexture:= RenderStringTex(trmsg[sidPaused], $FFFF00, fntBig);

{$IFDEF DUMP}
SDL_SaveBMP_RW(LandSurface, SDL_RWFromFile('LandSurface.bmp', 'wb'), 1);
SDL_SaveBMP_RW(StoreSurface, SDL_RWFromFile('StoreSurface.bmp', 'wb'), 1);
{$ENDIF}
end;

procedure DrawFromRect(X, Y: LongInt; r: PSDL_Rect; SourceTexture: PTexture; DestSurface: PSDL_Surface);
var rr: TSDL_Rect;
    _l, _r, _t, _b: real;
begin
if SourceTexture^.h = 0 then exit;
rr.x:= X;
rr.y:= Y;
rr.w:= r^.w;
rr.h:= r^.h;

_l:= r^.x / SourceTexture^.w;
_r:= (r^.x + r^.w) / SourceTexture^.w;
_t:= r^.y / SourceTexture^.h;
_b:= (r^.y + r^.h) / SourceTexture^.h;

glBindTexture(GL_TEXTURE_2D, SourceTexture^.id);

glBegin(GL_QUADS);

glTexCoord2f(_l, _t);
glVertex2i(X, Y);

glTexCoord2f(_r, _t);
glVertex2i(rr.w + X, Y);

glTexCoord2f(_r, _b);
glVertex2i(rr.w + X, rr.h + Y);

glTexCoord2f(_l, _b);
glVertex2i(X, rr.h + Y);

glEnd()
end;

procedure DrawTexture(X, Y: LongInt; Texture: PTexture);
begin
glBindTexture(GL_TEXTURE_2D, Texture^.id);

glBegin(GL_QUADS);

glTexCoord2f(0, 0);
glVertex2i(X, Y);

glTexCoord2f(1, 0);
glVertex2i(Texture^.w + X, Y);

glTexCoord2f(1, 1);
glVertex2i(Texture^.w + X, Texture^.h + Y);

glTexCoord2f(0, 1);
glVertex2i(X, Texture^.h + Y);

glEnd()
end;

procedure DrawRotated(Sprite: TSprite; X, Y: LongInt; Angle: real);
begin
DrawRotatedTex(SpritesData[Sprite].Texture,
               SpritesData[Sprite].Width,
               SpritesData[Sprite].Height,
               X, Y, Angle)
end;

procedure DrawRotatedF(Sprite: TSprite; X, Y, Frame: LongInt; Angle: real);
begin
glPushMatrix;
glTranslatef(X - SpritesData[Sprite].Width div 2, Y - SpritesData[Sprite].Width div 2, 0);
glRotatef(Angle, 0, 0, 1);

DrawSprite(Sprite, 0, 0, Frame, nil);

glPopMatrix
end;

procedure DrawRotatedTex(Tex: PTexture; hw, hh, X, Y: LongInt; Angle: real);
begin
glPushMatrix;
glTranslatef(X, Y, 0);
glRotatef(Angle, 0, 0, 1);

glBindTexture(GL_TEXTURE_2D, Tex^.id);

glBegin(GL_QUADS);

glTexCoord2f(0, 0);
glVertex2i(-hw, -hh);

glTexCoord2f(1, 0);
glVertex2i(hw, -hh);

glTexCoord2f(1, 1);
glVertex2i(hw, hh);

glTexCoord2f(0, 1);
glVertex2i(-hw, hh);

glEnd();

glPopMatrix
end;

procedure DrawSpriteFromRect(Sprite: TSprite; r: TSDL_Rect; X, Y, Height, Position: LongInt; Surface: PSDL_Surface);
begin
r.y:= r.y + Height * Position;
r.h:= Height;
DrawFromRect(X, Y, @r, SpritesData[Sprite].Texture, Surface)
end;

procedure DrawSprite (Sprite: TSprite; X, Y, Frame: LongInt; Surface: PSDL_Surface);
var r: TSDL_Rect;
begin
r.x:= 0;
r.w:= SpritesData[Sprite].Width;
r.y:= Frame * SpritesData[Sprite].Height;
r.h:= SpritesData[Sprite].Height;
DrawFromRect(X, Y, @r, SpritesData[Sprite].Texture, Surface)
end;

procedure DrawSprite2(Sprite: TSprite; X, Y, FrameX, FrameY: LongInt; Surface: PSDL_Surface);
var r: TSDL_Rect;
begin
r.x:= FrameX * SpritesData[Sprite].Width;
r.w:= SpritesData[Sprite].Width;
r.y:= FrameY * SpritesData[Sprite].Height;
r.h:= SpritesData[Sprite].Height;
DrawFromRect(X, Y, @r, SpritesData[Sprite].Texture, Surface)
end;

procedure DrawSurfSprite(X, Y, Height, Frame: LongInt; Source: PTexture; Surface: PSDL_Surface);
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

procedure DrawLand(X, Y: LongInt);
begin
DrawTexture(X, Y, LandTexture)
end;

procedure DrawCentered(X, Top: LongInt; Source: PTexture);
begin
DrawTexture(X - Source^.w div 2, Top, Source)
end;

procedure DrawHedgehog(X, Y: LongInt; Dir: LongInt; Pos, Step: LongWord; Surface: PSDL_Surface);
var l, r, t, b: real;
begin

t:= Pos * 32 / HHTexture^.h;
b:= (Pos + 1) * 32 / HHTexture^.h;

if Dir = -1 then
   begin
   l:= (Step + 1) * 32 / HHTexture^.w;
   r:= Step * 32 / HHTexture^.w
   end else
   begin
   l:= Step * 32 / HHTexture^.w;
   r:= (Step + 1) * 32 / HHTexture^.w
   end;

glBindTexture(GL_TEXTURE_2D, HHTexture^.id);

glBegin(GL_QUADS);

glTexCoord2f(l, t);
glVertex2i(X, Y);

glTexCoord2f(r, t);
glVertex2i(32 + X, Y);

glTexCoord2f(r, b);
glVertex2i(32 + X, 32 + Y);

glTexCoord2f(l, b);
glVertex2i(X, 32 + Y);

glEnd()
end;

procedure StoreRelease;
var ii: TSprite;
begin
for ii:= Low(TSprite) to High(TSprite) do
    begin
    FreeTexture(SpritesData[ii].Texture);
    if SpritesData[ii].Surface <> nil then SDL_FreeSurface(SpritesData[ii].Surface)
    end;

FreeTexture(HHTexture);
FreeTexture(LandTexture);

SDL_FreeSurface(LandSurface)
end;

function  RenderStringTex(s: string; Color: Longword; font: THWFont): PTexture;
var w, h: LongInt;
    Result: PSDL_Surface;
begin
TTF_SizeUTF8(Fontz[font].Handle, Str2PChar(s), w, h);

Result:= SDL_CreateRGBSurface(SDL_SWSURFACE, w + FontBorder * 2 + 4, h + FontBorder * 2,
         32, RMask, GMask, BMask, AMask);

TryDo(Result <> nil, 'RenderString: fail to create surface', true);

WriteInRoundRect(Result, 0, 0, Color, font, s);

TryDo(SDL_SetColorKey(Result, SDL_SRCCOLORKEY, 0) = 0, errmsgTransparentSet, true);

RenderStringTex:= Surface2Tex(Result);

SDL_FreeSurface(Result)
end;

procedure RenderHealth(var Hedgehog: THedgehog);
var s: shortstring;
begin
str(Hedgehog.Gear^.Health, s);
if Hedgehog.HealthTagTex <> nil then FreeTexture(Hedgehog.HealthTagTex);
Hedgehog.HealthTagTex:= RenderStringTex(s, Hedgehog.Team^.Clan^.Color, fnt16)
end;

function  LoadImage(const filename: string; hasAlpha: boolean; critical, setTransparent: boolean): PSDL_Surface;
var tmpsurf: PSDL_Surface;
    //Result: PSDL_Surface;
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

if setTransparent then TryDo(SDL_SetColorKey(tmpsurf, SDL_SRCCOLORKEY, 0) = 0, errmsgTransparentSet, true);
//if hasAlpha then Result:= SDL_DisplayFormatAlpha(tmpsurf)
//            else Result:= SDL_DisplayFormat(tmpsurf);
{$IFDEF DEBUGFILE}WriteLnToConsole('(' + inttostr(tmpsurf^.w) + ',' + inttostr(tmpsurf^.h) + ') ');{$ENDIF}
WriteLnToConsole(msgOK);
LoadImage:= tmpsurf//Result
end;

procedure SetupOpenGL;
begin
glLoadIdentity;
glViewport(0, 0, cScreenWidth, cScreenHeight);
glScalef(2.0 / cScreenWidth, -2.0 / cScreenHeight, 1.0);
glTranslatef(-cScreenWidth / 2, -cScreenHeight / 2, 0);
glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
glMatrixMode(GL_MODELVIEW)
end;

////////////////////////////////////////////////////////////////////////////////
var ProgrTex: PTexture = nil;
    Step: integer = 0;

procedure AddProgress;
var r: TSDL_Rect;
    texsurf: PSDL_Surface;
begin
if Step = 0 then
   begin
   WriteToConsole(msgLoading + 'progress sprite: ');
   texsurf:= LoadImage(Pathz[ptGraphics] + '/Progress', false, true, true);
   ProgrTex:= Surface2Tex(texsurf);
   SDL_FreeSurface(texsurf)
   end;
glClear(GL_COLOR_BUFFER_BIT);
glEnable(GL_TEXTURE_2D);
r.x:= 0;
r.w:= ProgrTex^.w;
r.h:= ProgrTex^.w;
r.y:= (Step mod (ProgrTex^.h div ProgrTex^.w)) * ProgrTex^.w;
DrawFromRect((cScreenWidth - ProgrTex^.w) div 2,
             (cScreenHeight - ProgrTex^.w) div 2, @r, ProgrTex, SDLPrimSurface);
glDisable(GL_TEXTURE_2D);
SDL_GL_SwapBuffers();
inc(Step);
end;

procedure FinishProgress;
begin
WriteLnToConsole('Freeing progress surface... ');
FreeTexture(ProgrTex)
end;

end.
