(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2008 Andrey Korotaev <unC0Rr@gmail.com>
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
uses uConsts, uTeams, SDLh,
{$IFDEF IPHONE}
	gles11,
{$ELSE}
	GL,
{$ENDIF}
uFloat;
{$INCLUDE options.inc}

procedure StoreInit;
procedure StoreLoad;
procedure StoreRelease;
procedure DrawSpriteFromRect(Sprite: TSprite; r: TSDL_Rect; X, Y, Height, Position: LongInt);
procedure DrawSprite (Sprite: TSprite; X, Y, Frame: LongInt);
procedure DrawSprite2(Sprite: TSprite; X, Y, FrameX, FrameY: LongInt);
procedure DrawSpriteClipped(Sprite: TSprite; X, Y, TopY, RightX, BottomY, LeftX: LongInt);
procedure DrawSurfSprite(X, Y, Height, Frame: LongInt; Source: PTexture);
procedure DrawTexture(X, Y: LongInt; Texture: PTexture);
procedure DrawTextureF(Texture: PTexture; Scale: GLfloat; X, Y, Frame, Dir, Frames: LongInt);
procedure DrawRotated(Sprite: TSprite; X, Y, Dir: LongInt; Angle: real);
procedure DrawRotatedF(Sprite: TSprite; X, Y, Frame, Dir: LongInt; Angle: real);
procedure DrawRotatedTex(Tex: PTexture; hw, hh, X, Y, Dir: LongInt; Angle: real);
procedure DrawCentered(X, Top: LongInt; Source: PTexture);
procedure DrawFromRect(X, Y: LongInt; r: PSDL_Rect; SourceTexture: PTexture);
procedure DrawHedgehog(X, Y: LongInt; Dir: LongInt; Pos, Step: LongWord; Angle: real);
procedure DrawFillRect(r: TSDL_Rect);
function  RenderStringTex(s: string; Color: Longword; font: THWFont): PTexture;
procedure RenderHealth(var Hedgehog: THedgehog);
procedure AddProgress;
procedure FinishProgress;
function  LoadImage(const filename: string; hasAlpha, critical, setTransparent: boolean): PSDL_Surface;
procedure SetupOpenGL;

var PixelFormat: PSDL_PixelFormat = nil;
 SDLPrimSurface: PSDL_Surface = nil;
   PauseTexture,
   ConfirmTexture: PTexture;

implementation
uses uMisc, uConsole, uLand, uLocale;

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
var s: string;

	procedure WriteNames(Font: THWFont);
	var t: LongInt;
		i: LongInt;
		r, rr: TSDL_Rect;
		drY: LongInt;
		texsurf: PSDL_Surface;
	begin
	r.x:= 0;
	r.y:= 0;
	drY:= - 4;
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
					begin
					NameTagTex:= RenderStringTex(Name, Clan^.Color, fnt16);
					if Hat <> 'NoHat' then
						begin
						texsurf:= LoadImage(Pathz[ptHats] + '/' + Hat, false, false, false);
						if texsurf <> nil then
							begin
							HatTex:= Surface2Tex(texsurf);
							SDL_FreeSurface(texsurf)
							end
						end
					end;
		end;
	end;

	procedure MakeCrossHairs;
	var t: LongInt;
		tmpsurf, texsurf: PSDL_Surface;
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

var ii: TSprite;
    fi: THWFont;
    ai: TAmmoType;
    tmpsurf: PSDL_Surface;
    i: LongInt;
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

WriteNames(fnt16);
MakeCrossHairs;
LoadGraves;

AddProgress;
for ii:= Low(TSprite) to High(TSprite) do
	with SpritesData[ii] do
        if (not cReducedQuality) or 
           ((ii <> sprSky) and (ii <> sprHorizont) and (ii <> sprFlake)) then
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
ConfirmTexture:= RenderStringTex(trmsg[sidConfirm], $FFFF00, fntBig);

for ai:= Low(TAmmoType) to High(TAmmoType) do
	with Ammoz[ai] do
		begin
		tmpsurf:= TTF_RenderUTF8_Blended(Fontz[fnt16].Handle, Str2PChar(trAmmo[NameId]), $FFFFFF);
		NameTex:= Surface2Tex(tmpsurf);
		SDL_FreeSurface(tmpsurf)
		end;

for i:= Low(CountTexz) to High(CountTexz) do
	begin
	tmpsurf:= TTF_RenderUTF8_Blended(Fontz[fnt16].Handle, Str2PChar(IntToStr(i) + 'x'), $FFFFFF);
	CountTexz[i]:= Surface2Tex(tmpsurf);
	SDL_FreeSurface(tmpsurf)
	end;

{$IFDEF DUMP}
SDL_SaveBMP_RW(LandSurface, SDL_RWFromFile('LandSurface.bmp', 'wb'), 1);
SDL_SaveBMP_RW(StoreSurface, SDL_RWFromFile('StoreSurface.bmp', 'wb'), 1);
{$ENDIF}
end;

procedure DrawFromRect(X, Y: LongInt; r: PSDL_Rect; SourceTexture: PTexture);
var rr: TSDL_Rect;
    _l, _r, _t, _b: real;
    VertexBuffer, TextureBuffer: array [0..3] of TVertex2f;
begin
if SourceTexture^.h = 0 then exit;
rr.x:= X;
rr.y:= Y;
rr.w:= r^.w;
rr.h:= r^.h;

_l:= r^.x / SourceTexture^.w * SourceTexture^.rx;
_r:= (r^.x + r^.w) / SourceTexture^.w * SourceTexture^.rx;
_t:= r^.y / SourceTexture^.h * SourceTexture^.ry;
_b:= (r^.y + r^.h) / SourceTexture^.h * SourceTexture^.ry;

glBindTexture(GL_TEXTURE_2D, SourceTexture^.id);

VertexBuffer[0].X:= X;
VertexBuffer[0].Y:= Y;
VertexBuffer[1].X:= rr.w + X;
VertexBuffer[1].Y:= Y;
VertexBuffer[2].X:= rr.w + X;
VertexBuffer[2].Y:= rr.h + Y;
VertexBuffer[3].X:= X;
VertexBuffer[3].Y:= rr.h + Y;

TextureBuffer[0].X:= _l;
TextureBuffer[0].Y:= _t;
TextureBuffer[1].X:= _r;
TextureBuffer[1].Y:= _t;
TextureBuffer[2].X:= _r;
TextureBuffer[2].Y:= _b;
TextureBuffer[3].X:= _l;
TextureBuffer[3].Y:= _b;

glEnableClientState(GL_VERTEX_ARRAY);
glEnableClientState(GL_TEXTURE_COORD_ARRAY);

glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);
glTexCoordPointer(2, GL_FLOAT, 0, @TextureBuffer[0]);
glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

glDisableClientState(GL_TEXTURE_COORD_ARRAY);
glDisableClientState(GL_VERTEX_ARRAY)
end;

procedure DrawTexture(X, Y: LongInt; Texture: PTexture);
begin
glPushMatrix;
glTranslatef(X, Y, 0);

glBindTexture(GL_TEXTURE_2D, Texture^.id);

glEnableClientState(GL_VERTEX_ARRAY);
glEnableClientState(GL_TEXTURE_COORD_ARRAY);

glVertexPointer(2, GL_FLOAT, 0, @Texture^.vb);
glTexCoordPointer(2, GL_FLOAT, 0, @Texture^.tb);
glDrawArrays(GL_TRIANGLE_FAN, 0, Length(Texture^.vb));

glDisableClientState(GL_TEXTURE_COORD_ARRAY);
glDisableClientState(GL_VERTEX_ARRAY);

glPopMatrix
end;

procedure DrawTextureF(Texture: PTexture; Scale: GLfloat; X, Y, Frame, Dir, Frames: LongInt);
var ft, fb: GLfloat;
	hw: LongInt;
    VertexBuffer, TextureBuffer: array [0..3] of TVertex2f;
begin
glPushMatrix;
glTranslatef(X, Y, 0);
glScalef(Scale, Scale, 1.0);

if Dir < 0 then
	hw:= - 16
else
	hw:= 16;

ft:= Frame / Frames * Texture^.ry;
fb:= (Frame + 1) / Frames * Texture^.ry;

glBindTexture(GL_TEXTURE_2D, Texture^.id);

VertexBuffer[0].X:= -hw;
VertexBuffer[0].Y:= -16;
VertexBuffer[1].X:= hw;
VertexBuffer[1].Y:= -16;
VertexBuffer[2].X:= hw;
VertexBuffer[2].Y:= 16;
VertexBuffer[3].X:= -hw;
VertexBuffer[3].Y:= 16;

TextureBuffer[0].X:= 0;
TextureBuffer[0].Y:= ft;
TextureBuffer[1].X:= Texture^.rx;
TextureBuffer[1].Y:= ft;
TextureBuffer[2].X:= Texture^.rx;
TextureBuffer[2].Y:= fb;
TextureBuffer[3].X:= 0;
TextureBuffer[3].Y:= fb;

glEnableClientState(GL_VERTEX_ARRAY);
glEnableClientState(GL_TEXTURE_COORD_ARRAY);

glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);
glTexCoordPointer(2, GL_FLOAT, 0, @TextureBuffer[0]);
glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

glDisableClientState(GL_TEXTURE_COORD_ARRAY);
glDisableClientState(GL_VERTEX_ARRAY);


glPopMatrix
end;

procedure DrawRotated(Sprite: TSprite; X, Y, Dir: LongInt; Angle: real);
begin
DrawRotatedTex(SpritesData[Sprite].Texture,
		SpritesData[Sprite].Width,
		SpritesData[Sprite].Height,
		X, Y, Dir, Angle)
end;

procedure DrawRotatedF(Sprite: TSprite; X, Y, Frame, Dir: LongInt; Angle: real);
begin
glPushMatrix;
glTranslatef(X, Y, 0);
glRotatef(Angle, 0, 0, 1);

if Dir < 0 then glScalef(-1.0, 1.0, 1.0);

DrawSprite(Sprite, -SpritesData[Sprite].Width div 2, -SpritesData[Sprite].Height div 2, Frame);

glPopMatrix
end;

procedure DrawRotatedTex(Tex: PTexture; hw, hh, X, Y, Dir: LongInt; Angle: real);
var VertexBuffer: array [0..3] of TVertex2f;
begin
glPushMatrix;
glTranslatef(X, Y, 0);

if Dir < 0 then
   begin
   hw:= - hw;
   glRotatef(Angle, 0, 0, -1);
   end else
   glRotatef(Angle, 0, 0,  1);


glBindTexture(GL_TEXTURE_2D, Tex^.id);

VertexBuffer[0].X:= -hw;
VertexBuffer[0].Y:= -hh;
VertexBuffer[1].X:= hw;
VertexBuffer[1].Y:= -hh;
VertexBuffer[2].X:= hw;
VertexBuffer[2].Y:= hh;
VertexBuffer[3].X:= -hw;
VertexBuffer[3].Y:= hh;

glEnableClientState(GL_VERTEX_ARRAY);
glEnableClientState(GL_TEXTURE_COORD_ARRAY);

glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);
glTexCoordPointer(2, GL_FLOAT, 0, @Tex^.tb);
glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

glDisableClientState(GL_TEXTURE_COORD_ARRAY);
glDisableClientState(GL_VERTEX_ARRAY);

glPopMatrix
end;

procedure DrawSpriteFromRect(Sprite: TSprite; r: TSDL_Rect; X, Y, Height, Position: LongInt);
begin
r.y:= r.y + Height * Position;
r.h:= Height;
DrawFromRect(X, Y, @r, SpritesData[Sprite].Texture)
end;

procedure DrawSprite (Sprite: TSprite; X, Y, Frame: LongInt);
var r: TSDL_Rect;
begin
r.x:= 0;
r.w:= SpritesData[Sprite].Width;
r.y:= Frame * SpritesData[Sprite].Height;
r.h:= SpritesData[Sprite].Height;
DrawFromRect(X, Y, @r, SpritesData[Sprite].Texture)
end;

procedure DrawSpriteClipped(Sprite: TSprite; X, Y, TopY, RightX, BottomY, LeftX: LongInt);
var r: TSDL_Rect;
begin
r.x:= 0;
r.y:= 0;
r.w:= SpritesData[Sprite].Width;
r.h:= SpritesData[Sprite].Height;

if (X < LeftX) then
    r.x:= LeftX - X;
if (Y < TopY) then
    r.y:= TopY - Y;

if (Y + SpritesData[Sprite].Height > BottomY) then
    r.h:= BottomY - Y + 1;
if (X + SpritesData[Sprite].Width > RightX) then
    r.w:= RightX - X + 1;

dec(r.h, r.y);
dec(r.w, r.x);

DrawFromRect(X + r.x, Y + r.y, @r, SpritesData[Sprite].Texture)
end;

procedure DrawSprite2(Sprite: TSprite; X, Y, FrameX, FrameY: LongInt);
var r: TSDL_Rect;
begin
r.x:= FrameX * SpritesData[Sprite].Width;
r.w:= SpritesData[Sprite].Width;
r.y:= FrameY * SpritesData[Sprite].Height;
r.h:= SpritesData[Sprite].Height;
DrawFromRect(X, Y, @r, SpritesData[Sprite].Texture)
end;

procedure DrawSurfSprite(X, Y, Height, Frame: LongInt; Source: PTexture);
var r: TSDL_Rect;
begin
r.x:= 0;
r.w:= Source^.w;
r.y:= Frame * Height;
r.h:= Height;
DrawFromRect(X, Y, @r, Source)
end;

procedure DrawCentered(X, Top: LongInt; Source: PTexture);
begin
DrawTexture(X - Source^.w div 2, Top, Source)
end;

procedure DrawHedgehog(X, Y: LongInt; Dir: LongInt; Pos, Step: LongWord; Angle: real);
const VertexBuffer: array [0..3] of TVertex2f = (
		(x: -16; y: -16),
		(x:  16; y: -16),
		(x:  16; y:  16),
		(x: -16; y:  16));
var l, r, t, b: real;
    TextureBuffer: array [0..3] of TVertex2f;
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


glPushMatrix();
glTranslatef(X, Y, 0);
glRotatef(Angle, 0, 0, 1);

glBindTexture(GL_TEXTURE_2D, HHTexture^.id);

TextureBuffer[0].X:= l;
TextureBuffer[0].Y:= t;
TextureBuffer[1].X:= r;
TextureBuffer[1].Y:= t;
TextureBuffer[2].X:= r;
TextureBuffer[2].Y:= b;
TextureBuffer[3].X:= l;
TextureBuffer[3].Y:= b;

glEnableClientState(GL_VERTEX_ARRAY);
glEnableClientState(GL_TEXTURE_COORD_ARRAY);

glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);
glTexCoordPointer(2, GL_FLOAT, 0, @TextureBuffer[0]);
glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

glDisableClientState(GL_TEXTURE_COORD_ARRAY);
glDisableClientState(GL_VERTEX_ARRAY);


glColor4f(1,1,1,1);

glPopMatrix
end;

procedure DrawFillRect(r: TSDL_Rect);
var VertexBuffer: array [0..3] of TVertex2f;
begin
glDisable(GL_TEXTURE_2D);

glColor4ub(0, 0, 0, 127);

VertexBuffer[0].X:= r.x;
VertexBuffer[0].Y:= r.y;
VertexBuffer[1].X:= r.x + r.w;
VertexBuffer[1].Y:= r.y;
VertexBuffer[2].X:= r.x + r.w;
VertexBuffer[2].Y:= r.y + r.h;
VertexBuffer[3].X:= r.x;
VertexBuffer[3].Y:= r.y + r.h;

glEnableClientState(GL_VERTEX_ARRAY);
glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);
glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));
glDisableClientState(GL_VERTEX_ARRAY);

glColor4f(1, 1, 1, 1);
glEnable(GL_TEXTURE_2D)
end;

procedure StoreRelease;
var ii: TSprite;
begin
for ii:= Low(TSprite) to High(TSprite) do
    begin
    FreeTexture(SpritesData[ii].Texture);
    if SpritesData[ii].Surface <> nil then SDL_FreeSurface(SpritesData[ii].Surface)
    end;

FreeTexture(HHTexture)
end;

function  RenderStringTex(s: string; Color: Longword; font: THWFont): PTexture;
var w, h: LongInt;
    Result: PSDL_Surface;
begin
if length(s) = 0 then s:= ' ';
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
             (cScreenHeight - ProgrTex^.w) div 2, @r, ProgrTex);
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
