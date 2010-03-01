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

{$INCLUDE "options.inc"}

unit uStore;
interface
uses sysutils, uConsts, uTeams, SDLh, uFloat,
{$IFDEF GLES11}
	gles11;
{$ELSE}
	GL, GLext;
{$ENDIF}


var PixelFormat: PSDL_PixelFormat;
    SDLPrimSurface: PSDL_Surface;
    PauseTexture,
    SyncTexture,
    ConfirmTexture: PTexture;
    cScaleFactor: GLfloat;
    SupportNPOTT: Boolean;
    Step: LongInt;
    squaresize : LongInt;
    numsquares : LongInt;
    ProgrTex: PTexture;
    MissionIcons: PSDL_Surface;
    ropeIconTex: PTexture;

procedure init_uStore;
procedure free_uStore;

procedure StoreLoad;
procedure StoreRelease;
procedure DrawSpriteFromRect(Sprite: TSprite; r: TSDL_Rect; X, Y, Height, Position: LongInt);
procedure DrawSprite (Sprite: TSprite; X, Y, Frame: LongInt);
procedure DrawSprite2(Sprite: TSprite; X, Y, FrameX, FrameY: LongInt);
procedure DrawSpriteClipped(Sprite: TSprite; X, Y, TopY, RightX, BottomY, LeftX: LongInt);
procedure DrawTexture(X, Y: LongInt; Texture: PTexture);
procedure DrawTextureF(Texture: PTexture; Scale: GLfloat; X, Y, Frame, Dir, w, h: LongInt);
procedure DrawRotatedTextureF(Texture: PTexture; Scale, OffsetX, OffsetY: GLfloat; X, Y, Frame, Dir, w, h: LongInt; Angle: real);
procedure DrawRotated(Sprite: TSprite; X, Y, Dir: LongInt; Angle: real);
procedure DrawRotatedF(Sprite: TSprite; X, Y, Frame, Dir: LongInt; Angle: real);
procedure DrawRotatedTex(Tex: PTexture; hw, hh, X, Y, Dir: LongInt; Angle: real);
procedure DrawCentered(X, Top: LongInt; Source: PTexture);
procedure DrawFromRect(X, Y: LongInt; r: PSDL_Rect; SourceTexture: PTexture);
procedure DrawHedgehog(X, Y: LongInt; Dir: LongInt; Pos, Step: LongWord; Angle: real);
procedure DrawFillRect(r: TSDL_Rect);
procedure DrawRoundRect(rect: PSDL_Rect; BorderColor, FillColor: Longword; Surface: PSDL_Surface; Clear: boolean);
function  CheckCJKFont(s: ansistring; font: THWFont): THWFont;
function  RenderStringTex(s: ansistring; Color: Longword; font: THWFont): PTexture;
function  RenderSpeechBubbleTex(s: ansistring; SpeechType: Longword; font: THWFont): PTexture;
procedure flipSurface(Surface: PSDL_Surface; Vertical: Boolean);
//procedure rotateSurface(Surface: PSDL_Surface);
procedure copyRotatedSurface(src, dest: PSDL_Surface); // this is necessary since width/height are read only in SDL
procedure copyToXY(src, dest: PSDL_Surface; destX, destY: Integer);
procedure RenderHealth(var Hedgehog: THedgehog);
procedure AddProgress;
procedure FinishProgress;
function  LoadImage(const filename: shortstring; imageFlags: LongInt): PSDL_Surface;
procedure SetupOpenGL;
procedure SetScale(f: GLfloat);
function RenderHelpWindow(caption, subcaption, description, extra: ansistring; extracolor: LongInt; iconsurf: PSDL_Surface; iconrect: PSDL_Rect): PTexture;
procedure RenderWeaponTooltip(atype: TAmmoType);
procedure ShowWeaponTooltip(x, y: LongInt);
procedure FreeWeaponTooltip;

implementation
uses uMisc, uConsole, uLand, uLocale, uWorld{$IFDEF IPHONEOS}, PascalExports{$ENDIF};

type TGPUVendor = (gvUnknown, gvNVIDIA, gvATI, gvIntel, gvApple);

var HHTexture: PTexture;
    MaxTextureSize: Integer;
    cGPUVendor: TGPUVendor;

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

function WriteInRoundRect(Surface: PSDL_Surface; X, Y: LongInt; Color: LongWord; Font: THWFont; s: ansistring): TSDL_Rect;
var w, h: LongInt;
    tmpsurf: PSDL_Surface;
    clr: TSDL_Color;
    finalRect: TSDL_Rect;
begin
TTF_SizeUTF8(Fontz[Font].Handle, Str2PChar(s), w, h);
finalRect.x:= X;
finalRect.y:= Y;
finalRect.w:= w + FontBorder * 2 + 4;
finalRect.h:= h + FontBorder * 2;
DrawRoundRect(@finalRect, cWhiteColor, endian(cNearBlackColorChannels.value), Surface, true);
clr.r:= (Color shr 16) and $FF;
clr.g:= (Color shr 8) and $FF;
clr.b:= Color and $FF;
tmpsurf:= TTF_RenderUTF8_Blended(Fontz[Font].Handle, Str2PChar(s), clr);
finalRect.x:= X + FontBorder + 2;
finalRect.y:= Y + FontBorder;
SDLTry(tmpsurf <> nil, true);
SDL_UpperBlit(tmpsurf, nil, Surface, @finalRect);
SDL_FreeSurface(tmpsurf);
finalRect.x:= X;
finalRect.y:= Y;
finalRect.w:= w + FontBorder * 2 + 4;
finalRect.h:= h + FontBorder * 2;
WriteInRoundRect:= finalRect;
end;

function WriteInRect(Surface: PSDL_Surface; X, Y: LongInt; Color: LongWord; Font: THWFont; s: ansistring): TSDL_Rect;
var w, h: LongInt;
    tmpsurf: PSDL_Surface;
    clr: TSDL_Color;
    finalRect: TSDL_Rect;
begin
TTF_SizeUTF8(Fontz[Font].Handle, Str2PChar(s), w, h);
finalRect.x:= X + FontBorder + 2;
finalRect.y:= Y + FontBorder;
finalRect.w:= w + FontBorder * 2 + 4;
finalRect.h:= h + FontBorder * 2;
clr.r:= Color shr 16;
clr.g:= (Color shr 8) and $FF;
clr.b:= Color and $FF;
tmpsurf:= TTF_RenderUTF8_Blended(Fontz[Font].Handle, Str2PChar(s), clr);
tmpsurf:= doSurfaceConversion(tmpsurf);
SDLTry(tmpsurf <> nil, true);
SDL_UpperBlit(tmpsurf, nil, Surface, @finalRect);
SDL_FreeSurface(tmpsurf);
finalRect.x:= X;
finalRect.y:= Y;
finalRect.w:= w + FontBorder * 2 + 4;
finalRect.h:= h + FontBorder * 2;
WriteInRect:= finalRect
end;

procedure StoreLoad;
var s: shortstring;

	procedure WriteNames(Font: THWFont);
	var t: LongInt;
		i: LongInt;
		r, rr: TSDL_Rect;
		drY: LongInt;
		texsurf, flagsurf, iconsurf: PSDL_Surface;
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

		DrawRoundRect(@r, cWhiteColor, cNearBlackColorChannels.value, texsurf, true);
		rr:= r;
		inc(rr.x, 2); dec(rr.w, 4); inc(rr.y, 2); dec(rr.h, 4);
		DrawRoundRect(@rr, Clan^.Color, Clan^.Color, texsurf, false);
		HealthTex:= Surface2Tex(texsurf, false);
		SDL_FreeSurface(texsurf);

		r.x:= 0;
		r.y:= 0;
		r.w:= 32;
		r.h:= 32;
		texsurf:= SDL_CreateRGBSurface(SDL_SWSURFACE, r.w, r.h, 32, RMask, GMask, BMask, AMask);
		TryDo(texsurf <> nil, errmsgCreateSurface, true);
		TryDo(SDL_SetColorKey(texsurf, SDL_SRCCOLORKEY, 0) = 0, errmsgTransparentSet, true);

		r.w:= 26;
		r.h:= 19;

		DrawRoundRect(@r, cWhiteColor, cNearBlackColor, texsurf, true);

		// overwrite flag for cpu teams and keep players from using it
		if (Hedgehogs[0].Gear <> nil) and (Hedgehogs[0].BotLevel > 0) then
			Flag:= 'cpu'
		else if Flag = 'cpu' then
			Flag:= 'hedgewars';
		
		flagsurf:= LoadImage(Pathz[ptFlags] + '/' + Flag, ifNone);
		if flagsurf = nil then
			flagsurf:= LoadImage(Pathz[ptFlags] + '/hedgewars', ifNone);
		TryDo(flagsurf <> nil, 'Failed to load flag "' + Flag + '" as well as the default flag', true);
		copyToXY(flagsurf, texsurf, 2, 2);
		SDL_FreeSurface(flagsurf);
		
		// restore black border pixels inside the flag
		PLongwordArray(texsurf^.pixels)^[32 * 2 +  2]:= cNearBlackColor;
		PLongwordArray(texsurf^.pixels)^[32 * 2 + 23]:= cNearBlackColor;
		PLongwordArray(texsurf^.pixels)^[32 * 16 +  2]:= cNearBlackColor;
		PLongwordArray(texsurf^.pixels)^[32 * 16 + 23]:= cNearBlackColor;

		FlagTex:= Surface2Tex(texsurf, false);
		
		dec(drY, r.h + 2);
		DrawHealthY:= drY;
		for i:= 0 to 7 do
			with Hedgehogs[i] do
				if Gear <> nil then
					begin
					NameTagTex:= RenderStringTex(Name, Clan^.Color, CheckCJKFont(Name,fnt16));
					if Hat <> 'NoHat' then
						begin
                        texsurf:= nil;
                        if (Length(Hat) > 39) and (Copy(Hat,1,8) = 'Reserved') and (Copy(Hat,9,32) = PlayerHash) then
						   texsurf:= LoadImage(Pathz[ptHats] + '/Reserved/' + Copy(Hat,9,Length(s)-8), ifNone)
                        else
						   texsurf:= LoadImage(Pathz[ptHats] + '/' + Hat, ifNone);
						if texsurf <> nil then
							begin
							HatTex:= Surface2Tex(texsurf, true);
							SDL_FreeSurface(texsurf)
							end
						end
					end;
		end;
	MissionIcons:= LoadImage(Pathz[ptGraphics] + '/missions', ifCritical);
	iconsurf:= SDL_CreateRGBSurface(SDL_SWSURFACE, 28, 28, 32, RMask, GMask, BMask, AMask);
	if iconsurf <> nil then
		begin
		r.x:= 0;
		r.y:= 0;
		r.w:= 28;
		r.h:= 28;
		DrawRoundRect(@r, cWhiteColor, cNearBlackColor, iconsurf, true);
		ropeIconTex:= Surface2Tex(iconsurf, false);
		SDL_FreeSurface(iconsurf)
		end;
	end;

	procedure MakeCrossHairs;
	var t: LongInt;
		tmpsurf, texsurf: PSDL_Surface;
		Color, i: Longword;
	begin
	s:= Pathz[ptGraphics] + '/' + cCHFileName;
	tmpsurf:= LoadImage(s, ifAlpha or ifCritical);

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
			if PLongwordArray(texsurf^.pixels)^[i] = AMask then PLongwordArray(texsurf^.pixels)^[i]:= 0;

		if SDL_MustLock(texsurf) then
			SDL_UnlockSurface(texsurf);

		CrosshairTex:= Surface2Tex(texsurf, false);
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
			texsurf:= LoadImage(Pathz[ptGraves] + '/' + GraveName, ifCritical or ifTransparent);
			GraveTex:= Surface2Tex(texsurf, false);
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

WriteNames(fnt16);
MakeCrossHairs;
LoadGraves;

AddProgress;
for ii:= Low(TSprite) to High(TSprite) do
	with SpritesData[ii] do
        // FIXME - add a sprite attribute
        if (not cReducedQuality) or (not (ii in [sprSky, sprSkyL, sprSkyR, sprHorizont, sprHorizontL, sprHorizontR, sprFlake])) then // FIXME: hack
		begin
			if AltPath = ptNone then
				if ii in [sprHorizontL, sprHorizontR, sprSkyL, sprSkyR] then // FIXME: hack
					tmpsurf:= LoadImage(Pathz[Path] + '/' + FileName, ifAlpha or ifTransparent or ifLowRes)
				else
					tmpsurf:= LoadImage(Pathz[Path] + '/' + FileName, ifAlpha or ifTransparent or ifCritical or ifLowRes)
			else begin
				tmpsurf:= LoadImage(Pathz[Path] + '/' + FileName, ifAlpha or ifTransparent);
				if tmpsurf = nil then
					tmpsurf:= LoadImage(Pathz[AltPath] + '/' + FileName, ifAlpha or ifCritical or ifTransparent);
				end;

			if tmpsurf <> nil then
			begin
				if imageWidth = 0 then imageWidth:= tmpsurf^.w;
				if imageHeight = 0 then imageHeight:= tmpsurf^.h;
				if Width = 0 then Width:= tmpsurf^.w;
				if Height = 0 then Height:= tmpsurf^.h;
				if (ii in [sprSky, sprSkyL, sprSkyR, sprHorizont, sprHorizontL, sprHorizontR]) then
					Texture:= Surface2Tex(tmpsurf, true)
				else
					begin
					Texture:= Surface2Tex(tmpsurf, false);
					if (ii = sprWater) and not cReducedQuality then // HACK: We should include some sprite attribute to define the texture wrap directions
					begin
						glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
					end;
				end;
				if saveSurf then Surface:= tmpsurf else SDL_FreeSurface(tmpsurf)
				end
			else
				Surface:= nil
		end;

AddProgress;

tmpsurf:= LoadImage(Pathz[ptGraphics] + '/' + cHHFileName, ifAlpha or ifCritical or ifTransparent);
HHTexture:= Surface2Tex(tmpsurf, false);
SDL_FreeSurface(tmpsurf);

InitHealth;

PauseTexture:= RenderStringTex(trmsg[sidPaused], cYellowColor, fntBig);
ConfirmTexture:= RenderStringTex(trmsg[sidConfirm], cYellowColor, fntBig);
SyncTexture:= RenderStringTex(trmsg[sidSync], cYellowColor, fntBig);

AddProgress;

// name of weapons in ammo menu
for ai:= Low(TAmmoType) to High(TAmmoType) do
	with Ammoz[ai] do
		begin
		tmpsurf:= TTF_RenderUTF8_Blended(Fontz[CheckCJKFont(trAmmo[NameId],fnt16)].Handle, Str2PChar(trAmmo[NameId]), cWhiteColorChannels);
		tmpsurf:= doSurfaceConversion(tmpsurf);
		NameTex:= Surface2Tex(tmpsurf, false);
		SDL_FreeSurface(tmpsurf)
		end;

// number of weapons in ammo menu
for i:= Low(CountTexz) to High(CountTexz) do
	begin
	tmpsurf:= TTF_RenderUTF8_Blended(Fontz[fnt16].Handle, Str2PChar(IntToStr(i) + 'x'), cWhiteColorChannels);
	tmpsurf:= doSurfaceConversion(tmpsurf);
	CountTexz[i]:= Surface2Tex(tmpsurf, false);
	SDL_FreeSurface(tmpsurf)
	end;

{$IFDEF DUMP}
//not working anymore, where are LandSurface and StoreSurface defined?
//SDL_SaveBMP_RW(LandSurface, SDL_RWFromFile('LandSurface.bmp', 'wb'), 1);
//SDL_SaveBMP_RW(StoreSurface, SDL_RWFromFile('StoreSurface.bmp', 'wb'), 1);
{$ENDIF}
AddProgress;

{$IFDEF SDL_IMAGE_NEWER}
IMG_Quit();
{$ENDIF}
end;

procedure DrawFromRect(X, Y: LongInt; r: PSDL_Rect; SourceTexture: PTexture);
var rr: TSDL_Rect;
    _l, _r, _t, _b: real;
    VertexBuffer, TextureBuffer: array [0..3] of TVertex2f;
begin
if (SourceTexture^.h = 0) or (SourceTexture^.w = 0) then exit;
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

procedure DrawTextureF(Texture: PTexture; Scale: GLfloat; X, Y, Frame, Dir, w, h: LongInt);
begin
	DrawRotatedTextureF(Texture, Scale, 0, 0, X, Y, Frame, Dir, w, h, 0)
end;

procedure DrawRotatedTextureF(Texture: PTexture; Scale, OffsetX, OffsetY: GLfloat; X, Y, Frame, Dir, w, h: LongInt; Angle: real);
var ft, fb, fl, fr: GLfloat;
    hw, nx, ny: LongInt;
    VertexBuffer, TextureBuffer: array [0..3] of TVertex2f;
begin
glPushMatrix;
glTranslatef(X, Y, 0);

if Dir < 0 then
   glRotatef(Angle, 0, 0, -1)
else
   glRotatef(Angle, 0, 0,  1);

glTranslatef(Dir*OffsetX, OffsetY, 0);
glScalef(Scale, Scale, 1);

glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

if Dir < 0 then
	hw:= w div -2
else
	hw:= w div 2;

nx:= round(Texture^.w * Texture^.rx / w);
ny:= round(Texture^.h * Texture^.ry / h);

ft:= ((Frame mod ny) / ny);
fb:= (((Frame mod ny) + 1) / ny);
fl:= ((Frame div ny) / nx) * Texture^.rx;
fr:= (((Frame div ny) + 1) / nx);

glBindTexture(GL_TEXTURE_2D, Texture^.id);

VertexBuffer[0].X:= -hw;
VertexBuffer[0].Y:= w / -2;
VertexBuffer[1].X:= hw;
VertexBuffer[1].Y:= w / -2;
VertexBuffer[2].X:= hw;
VertexBuffer[2].Y:= w / 2;
VertexBuffer[3].X:= -hw;
VertexBuffer[3].Y:= w / 2;

TextureBuffer[0].X:= fl;
TextureBuffer[0].Y:= ft;
TextureBuffer[1].X:= fr;
TextureBuffer[1].Y:= ft;
TextureBuffer[2].X:= fr;
TextureBuffer[2].Y:= fb;
TextureBuffer[3].X:= fl;
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

if Dir < 0 then
   glRotatef(Angle, 0, 0, -1)
else
   glRotatef(Angle, 0, 0,  1);
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
var row, col, numFramesFirstCol: LongInt;
begin
numFramesFirstCol:= SpritesData[Sprite].imageHeight div SpritesData[Sprite].Height;
row:= Frame mod numFramesFirstCol;
col:= Frame div numFramesFirstCol;
DrawSprite2 (Sprite, X, Y, col, row);
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

procedure DrawCentered(X, Top: LongInt; Source: PTexture);
begin
DrawTexture(X - Source^.w shr 1, Top, Source)
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
SDL_FreeSurface(MissionIcons);
FreeTexture(ropeIconTex);
FreeTexture(HHTexture)
end;


function CheckCJKFont(s: ansistring; font: THWFont): THWFont;
var l, i : LongInt;
    u: WideChar;
    tmpstr: array[0..256] of WideChar;
begin
if (font >= CJKfnt16) or (length(s) = 0)  then exit(font);

l:= Utf8ToUnicode(@tmpstr, Str2PChar(s), length(s))-1;
i:= 0;
while i < l do
    begin
    u:= tmpstr[i];
    if (#$2E80  <= u) and  (
                           (u <= #$2FDF )  or // CJK Radicals Supplement / Kangxi Radicals
       ((#$2FF0  <= u) and (u <= #$303F))  or // Ideographic Description Characters / CJK Radicals Supplement
       ((#$31C0  <= u) and (u <= #$31EF))  or // CJK Strokes
       ((#$3200  <= u) and (u <= #$4DBF))  or // Enclosed CJK Letters and Months / CJK Compatibility / CJK Unified Ideographs Extension A
       ((#$4E00  <= u) and (u <= #$9FFF))  or // CJK Unified Ideographs
       ((#$F900  <= u) and (u <= #$FAFF))  or // CJK Compatibility Ideographs
       ((#$FE30  <= u) and (u <= #$FE4F)))    // CJK Compatibility Forms
       then exit(THWFont( ord(font) + ((ord(High(THWFont))+1) div 2) ));
    inc(i)
    end;
exit(font);
(* two more to check. pascal WideChar is only 16 bit though
       ((#$20000 <= u) and (u >= #$2A6DF)) or // CJK Unified Ideographs Extension B
       ((#$2F800 <= u) and (u >= #$2FA1F)))   // CJK Compatibility Ideographs Supplement *)
end;

function  RenderStringTex(s: ansistring; Color: Longword; font: THWFont): PTexture;
var w, h : LongInt;
    finalSurface: PSDL_Surface;
begin
if length(s) = 0 then s:= ' ';
font:= CheckCJKFont(s, font);
TTF_SizeUTF8(Fontz[font].Handle, Str2PChar(s), w, h);

finalSurface:= SDL_CreateRGBSurface(SDL_SWSURFACE, w + FontBorder * 2 + 4, h + FontBorder * 2,
         32, RMask, GMask, BMask, AMask);

TryDo(finalSurface <> nil, 'RenderString: fail to create surface', true);

WriteInRoundRect(finalSurface, 0, 0, Color, font, s);

TryDo(SDL_SetColorKey(finalSurface, SDL_SRCCOLORKEY, 0) = 0, errmsgTransparentSet, true);

RenderStringTex:= Surface2Tex(finalSurface, false);

SDL_FreeSurface(finalSurface);
end;

function RenderSpeechBubbleTex(s: ansistring; SpeechType: Longword; font: THWFont): PTexture;
var textWidth, textHeight, x, y, w, h, i, j, pos, prevpos, line, numLines, edgeWidth, edgeHeight, cornerWidth, cornerHeight: LongInt;
    finalSurface, tmpsurf, rotatedEdge: PSDL_Surface;
    rect: TSDL_Rect;
    chars: TSysCharSet = [#9,' ','.',';',':','?','!',','];
    substr: shortstring;
    edge, corner, tail: TSPrite;
begin

case SpeechType of
    1: begin;
       edge:= sprSpeechEdge;
       corner:= sprSpeechCorner;
       tail:= sprSpeechTail;
       end;
    2: begin;
       edge:= sprThoughtEdge;
       corner:= sprThoughtCorner;
       tail:= sprThoughtTail;
       end;
    3: begin;
       edge:= sprShoutEdge;
       corner:= sprShoutCorner;
       tail:= sprShoutTail;
       end;
    end;
edgeHeight:= SpritesData[edge].Height;
edgeWidth:= SpritesData[edge].Width;
cornerWidth:= SpritesData[corner].Width;
cornerHeight:= SpritesData[corner].Height;
// This one screws up WrapText
//s:= 'This is the song that never ends.  ''cause it goes on and on my friends. Some people, started singing it not knowing what it was. And they''ll just go on singing it forever just because... This is the song that never ends...';
// This one does not
//s:= 'This is the song that never ends.  cause it goes on and on my friends. Some people, started singing it not knowing what it was. And they will go on singing it forever just because... This is the song that never ends... ';

numLines:= 0;

if length(s) = 0 then s:= '...';
font:= CheckCJKFont(s, font);
TTF_SizeUTF8(Fontz[font].Handle, Str2PChar(s), w, h);
if w<8 then w:= 8;
j:= 0;
if (length(s) > 20) then
    begin
    w:= 0;
    i:= round(Sqrt(length(s)) * 2);
    s:= WrapText(s, #1, chars, i);
    pos:= 1; prevpos:= 0; line:= 0;
// Find the longest line for the purposes of centring the text.  Font dependant.
    while pos <= length(s) do
        begin
        if (s[pos] = #1) or (pos = length(s)) then
            begin
            inc(numlines);
            if s[pos] <> #1 then inc(pos);
            while s[prevpos+1] = ' ' do inc(prevpos);
            substr:= copy(s, prevpos+1, pos-prevpos-1);
            i:= 0; j:= 0;
            TTF_SizeUTF8(Fontz[font].Handle, Str2PChar(substr), i, j);
            if i > w then w:= i;
            prevpos:= pos;
            end;
        inc(pos);
        end;
    end
else numLines := 1;

textWidth:=((w-(cornerWidth-edgeWidth)*2) div edgeWidth)*edgeWidth+edgeWidth;
textHeight:=(((numlines * h + 2)-((cornerHeight-edgeWidth)*2)) div edgeWidth)*edgeWidth;

textHeight:=max(textHeight,edgeWidth);
//textWidth:=max(textWidth,SpritesData[tail].Width);
rect.x:= 0;
rect.y:= 0;
rect.w:= textWidth + (cornerWidth * 2);
rect.h:= textHeight + cornerHeight*2 - edgeHeight + SpritesData[tail].Height;
//s:= inttostr(w) + ' ' + inttostr(numlines) + ' ' + inttostr(rect.x) + ' '+inttostr(rect.y) + ' ' + inttostr(rect.w) + ' ' + inttostr(rect.h);

finalSurface:= SDL_CreateRGBSurface(SDL_SWSURFACE, rect.w, rect.h, 32, RMask, GMask, BMask, AMask);

TryDo(finalSurface <> nil, 'RenderString: fail to create surface', true);

//////////////////////////////// CORNERS ///////////////////////////////
copyToXY(SpritesData[corner].Surface, finalSurface, 0, 0); /////////////////// NW

flipSurface(SpritesData[corner].Surface, true); // store all 4 versions in memory to avoid repeated flips?
x:= 0;
y:= textHeight + cornerHeight -1;
copyToXY(SpritesData[corner].Surface, finalSurface, x, y); /////////////////// SW

flipSurface(SpritesData[corner].Surface, false);
x:= rect.w-cornerWidth-1;
y:= textHeight + cornerHeight -1;
copyToXY(SpritesData[corner].Surface, finalSurface, x, y); /////////////////// SE

flipSurface(SpritesData[corner].Surface, true);
x:= rect.w-cornerWidth-1;
y:= 0;
copyToXY(SpritesData[corner].Surface, finalSurface, x, y); /////////////////// NE
flipSurface(SpritesData[corner].Surface, false); // restore original position
//////////////////////////////// END CORNERS ///////////////////////////////

//////////////////////////////// EDGES //////////////////////////////////////
x:= cornerWidth;
y:= 0;
while x < rect.w-cornerWidth-1 do
    begin
    copyToXY(SpritesData[edge].Surface, finalSurface, x, y); ///////////////// top edge
    inc(x,edgeWidth);
    end;
flipSurface(SpritesData[edge].Surface, true);
x:= cornerWidth;
y:= textHeight + cornerHeight*2 - edgeHeight-1;
while x < rect.w-cornerWidth-1 do
    begin
    copyToXY(SpritesData[edge].Surface, finalSurface, x, y); ///////////////// bottom edge
    inc(x,edgeWidth);
    end;
flipSurface(SpritesData[edge].Surface, true); // restore original position

rotatedEdge:= SDL_CreateRGBSurface(SDL_SWSURFACE, edgeHeight, edgeWidth, 32, RMask, GMask, BMask, AMask);
x:= rect.w - edgeHeight - 1;
y:= cornerHeight;
//// initially was going to rotate in place, but the SDL spec claims width/height are read only
copyRotatedSurface(SpritesData[edge].Surface,rotatedEdge);
while y < textHeight + cornerHeight do
    begin
    copyToXY(rotatedEdge, finalSurface, x, y);
    inc(y,edgeWidth);
    end;
flipSurface(rotatedEdge, false); // restore original position
x:= 0;
y:= cornerHeight;
while y < textHeight + cornerHeight do
    begin
    copyToXY(rotatedEdge, finalSurface, x, y);
    inc(y,edgeWidth);
    end;
//////////////////////////////// END EDGES //////////////////////////////////////

x:= cornerWidth;
y:= textHeight + cornerHeight * 2 - edgeHeight - 1;
copyToXY(SpritesData[tail].Surface, finalSurface, x, y);

rect.x:= edgeHeight;
rect.y:= edgeHeight;
rect.w:= rect.w - edgeHeight * 2;
rect.h:= textHeight + cornerHeight * 2 - edgeHeight * 2;
i:= rect.w;
j:= rect.h;
SDL_FillRect(finalSurface, @rect, cWhiteColor);

pos:= 1; prevpos:= 0; line:= 0;
while pos <= length(s) do
    begin
    if (s[pos] = #1) or (pos = length(s)) then
        begin
        if s[pos] <> #1 then inc(pos);
        while s[prevpos+1] = ' 'do inc(prevpos);
        substr:= copy(s, prevpos+1, pos-prevpos-1);
        if Length(substr) <> 0 then
           begin
           tmpsurf:= TTF_RenderUTF8_Blended(Fontz[Font].Handle, Str2PChar(substr), cNearBlackColorChannels);
           rect.x:= edgeHeight + 1 + ((i - w) div 2);
           // trying to more evenly position the text, vertically
           rect.y:= edgeHeight + ((j-(numLines*h)) div 2) + line * h;
           SDLTry(tmpsurf <> nil, true);
           SDL_UpperBlit(tmpsurf, nil, finalSurface, @rect);
           SDL_FreeSurface(tmpsurf);
           inc(line);
           prevpos:= pos;
           end;
        end;
    inc(pos);
    end;

//TryDo(SDL_SetColorKey(finalSurface, SDL_SRCCOLORKEY, 0) = 0, errmsgTransparentSet, true);
RenderSpeechBubbleTex:= Surface2Tex(finalSurface, true);

SDL_FreeSurface(rotatedEdge);
SDL_FreeSurface(finalSurface);
end;

procedure RenderHealth(var Hedgehog: THedgehog);
var s: shortstring;
begin
	str(Hedgehog.Gear^.Health, s);
	if Hedgehog.HealthTagTex <> nil then
		FreeTexture(Hedgehog.HealthTagTex);
	Hedgehog.HealthTagTex:= RenderStringTex(s, Hedgehog.Team^.Clan^.Color, fnt16)
end;

function  LoadImage(const filename: shortstring; imageFlags: LongInt): PSDL_Surface;
var tmpsurf: PSDL_Surface;
    s: shortstring;
begin
	WriteToConsole(msgLoading + filename + ' [flags: ' + inttostr(imageFlags) + ']... ');

	s:= filename + '.png';
	tmpsurf:= IMG_Load(Str2PChar(s));

	if (imageFlags and ifLowRes) <> 0 then
	begin
		s:= filename + '-lowres.png';
		if (tmpsurf <> nil) then
		begin
			if ((tmpsurf^.w > MaxTextureSize) or (tmpsurf^.h > MaxTextureSize)) then
			begin
				SDL_FreeSurface(tmpsurf);
				{$IFDEF DEBUGFILE}
				AddFileLog('...image too big, trying to load lowres version: ' + s + '...');
				{$ENDIF}
				tmpsurf:= IMG_Load(Str2PChar(s))
			end;
		end
		else
		begin
			{$IFDEF DEBUGFILE}
			AddFileLog('...image not found, trying to load lowres version: ' + s + '...');
			{$ENDIF}
			tmpsurf:= IMG_Load(Str2PChar(s))
		end;
	end;

	if tmpsurf = nil then
	begin
		OutError(msgFailed, (imageFlags and ifCritical) <> 0);
		exit(nil)
	end;

	if ((imageFlags and ifIgnoreCaps) = 0) and ((tmpsurf^.w > MaxTextureSize) or (tmpsurf^.h > MaxTextureSize)) then
	begin
		SDL_FreeSurface(tmpsurf);
		OutError(msgFailedSize, (imageFlags and ifCritical) <> 0);
		// dummy surface to replace non-critical textures that failed to load due to their size
		exit(SDL_CreateRGBSurface(SDL_SWSURFACE, 32, 32, 32, RMask, GMask, BMask, AMask));
	end;

	tmpsurf:= doSurfaceConversion(tmpsurf);

	if (imageFlags and ifTransparent) <> 0 then
		TryDo(SDL_SetColorKey(tmpsurf, SDL_SRCCOLORKEY, 0) = 0, errmsgTransparentSet, true);

	WriteLnToConsole('(' + inttostr(tmpsurf^.w) + ',' + inttostr(tmpsurf^.h) + ') ');
	WriteLnToConsole(msgOK);

	LoadImage:= tmpsurf //Result
end;

function glLoadExtension(extension : shortstring) : boolean;
begin
{$IFDEF IPHONEOS}
	glLoadExtension:= false;
{$ELSE}
	glLoadExtension:= glext_LoadExtension(extension);
{$ENDIF}
{$IFDEF DEBUGFILE}
	if not glLoadExtension then
		AddFileLog('OpenGL - "' + extension + '" failed to load')
	else
		AddFileLog('OpenGL - "' + extension + '" loaded');
{$ENDIF}
end;

procedure SetupOpenGL;
var vendor: shortstring;
begin
{$IFDEF IPHONEOS}
//these are good performance savers, perhaps we could enable them by default
	SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 0);
	SDL_GL_SetAttribute(SDL_GL_RETAINED_BACKING, 1);
	SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 0);
	SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 5);
	SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 6);
	SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 5);
	SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE, 0);
	SDL_GL_SetAttribute(SDL_GL_ACCELERATED_VISUAL, 1);
	//SDL_GL_SetAttribute(SDL_GL_BUFFER_SIZE, 32);
{$ELSE}
	SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
{$ENDIF}

{$IFNDEF SDL13}
// this attribute is default in 1.3 and must be enabled in MacOSX
{$IFNDEF DARWIN}
	if cVSyncInUse then
{$ENDIF}
		SDL_GL_SetAttribute(SDL_GL_SWAP_CONTROL, 1);
{$ENDIF}

	glGetIntegerv(GL_MAX_TEXTURE_SIZE, @MaxTextureSize);

	vendor:= LowerCase(shortstring(pchar(glGetString(GL_VENDOR))));
{$IFDEF DEBUGFILE}
	AddFileLog('OpenGL-- Renderer: ' + shortstring(pchar(glGetString(GL_RENDERER))));
	AddFileLog('  |----- Vendor: ' + vendor);
	AddFileLog('  |----- Version: ' + shortstring(pchar(glGetString(GL_VERSION))));
	AddFileLog('  \----- GL_MAX_TEXTURE_SIZE: ' + inttostr(MaxTextureSize));
{$ENDIF}

	if MaxTextureSize <= 0 then
	begin
		MaxTextureSize:= 1024;
{$IFDEF DEBUGFILE}
		AddFileLog('OpenGL Warning - driver didn''t provide any valid max texture size; assuming 1024');
{$ENDIF}
	end;

{$IFNDEF IPHONEOS}
	if StrPos(Str2PChar(vendor), Str2PChar('nvidia')) <> nil then
		cGPUVendor:= gvNVIDIA
	else if StrPos(Str2PChar(vendor), Str2PChar('intel')) <> nil then
		cGPUVendor:= gvATI
	else if StrPos(Str2PChar(vendor), Str2PChar('ati')) <> nil then
		cGPUVendor:= gvIntel;
//SupportNPOTT:= glLoadExtension('GL_ARB_texture_non_power_of_two');
{$ELSE}
	cGPUVendor:= gvApple;
{$ENDIF}

{$IFDEF DEBUGFILE}
	if cGPUVendor = gvUnknown then
		AddFileLog('OpenGL Warning - unknown hardware vendor; please report');
{$ELSE}
	// just avoid 'never used' compiler warning for now
	if cGPUVendor = gvUnknown then cGPUVendor:= gvUnknown;
{$ENDIF}

	// set view port to whole window
{$IFDEF IPHONEOS}
	glViewport(0, 0, cScreenHeight, cScreenWidth);
{$ELSE}
	glViewport(0, 0, cScreenWidth, cScreenHeight);
{$ENDIF}

	glMatrixMode(GL_MODELVIEW);
	// prepare default translation/scaling
	glLoadIdentity();
{$IFDEF IPHONEOS}
	glRotatef(-90, 0, 0, 1);
{$ENDIF}
	glScalef(2.0 / cScreenWidth, -2.0 / cScreenHeight, 1.0);
	glTranslatef(0, -cScreenHeight / 2, 0);

	// enable alpha blending
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
end;

procedure SetScale(f: GLfloat);
var
{$IFDEF IPHONEOS}
scale: GLfloat = 1.5;
{$ELSE}
scale: GLfloat = 2.0;
{$ENDIF}
begin
	// leave immediately if scale factor did not change
	if f = cScaleFactor then exit;

	if f = scale then glPopMatrix	// "return" to default scaling
	else				// other scaling
	begin
		glPushMatrix;		// save default scaling
		glLoadIdentity;
{$IFDEF IPHONEOS}
		glRotatef(-90, 0, 0, 1);
{$ENDIF}
		glScalef(f / cScreenWidth, -f / cScreenHeight, 1.0);
		glTranslatef(0, -cScreenHeight / 2, 0);
	end;

	cScaleFactor:= f;
end;

////////////////////////////////////////////////////////////////////////////////
procedure AddProgress;
var r: TSDL_Rect;
    texsurf: PSDL_Surface;
begin
	if Step = 0 then
	begin
{$IFDEF SDL_IMAGE_NEWER}
		WriteToConsole('Init SDL_image... ');
		SDLTry(IMG_Init(IMG_INIT_PNG) <> 0, true);
		WriteLnToConsole(msgOK);
{$ENDIF}
	
		WriteToConsole(msgLoading + 'progress sprite: ');
		texsurf:= LoadImage(Pathz[ptGraphics] + '/Progress', ifCritical or ifTransparent);

		ProgrTex:= Surface2Tex(texsurf, false);
		
		squaresize:= texsurf^.w shr 1;
		numsquares:= texsurf^.h div squaresize;
		SDL_FreeSurface(texsurf);
	end;

	TryDo(ProgrTex <> nil, 'Error - Progress Texure is nil!', true);

	glClear(GL_COLOR_BUFFER_BIT);
	glEnable(GL_TEXTURE_2D);
	if Step < numsquares then r.x:= 0
	else r.x:= squaresize;
	
	r.y:= (Step mod numsquares) * squaresize;
	r.w:= squaresize;
	r.h:= squaresize;
	
	DrawFromRect( -squaresize div 2, (cScreenHeight - squaresize) shr 1, @r, ProgrTex);

	glDisable(GL_TEXTURE_2D);
	SDL_GL_SwapBuffers();
{$IFDEF SDL13}
	SDL_RenderPresent();
{$ENDIF}
	inc(Step);

end;


procedure FinishProgress;
begin
	WriteLnToConsole('Freeing progress surface... ');
	FreeTexture(ProgrTex);

{$IFDEF IPHONEOS}
	// show overlay buttons
	IPH_showControls;
{$ENDIF}
end;

procedure flipSurface(Surface: PSDL_Surface; Vertical: Boolean);
var y, x, i, j: LongInt;
    tmpPixel: Longword;
    pixels: PLongWordArray;
begin
TryDo(Surface^.format^.BytesPerPixel = 4, 'flipSurface failed, expecting 32 bit surface', true);
pixels:= Surface^.pixels;
if Vertical then
   for y := 0 to (Surface^.h div 2) - 1 do
       for x := 0 to Surface^.w - 1 do
           begin
           i:= y * Surface^.w + x;
           j:= (Surface^.h - y - 1) * Surface^.w + x;
           tmpPixel:= pixels^[i];
           pixels^[i]:= pixels^[j];
           pixels^[j]:= tmpPixel;
           end
else
   for x := 0 to (Surface^.w div 2) - 1 do
       for y := 0 to Surface^.h -1 do
           begin
           i:= y*Surface^.w + x;
           j:= y*Surface^.w + (Surface^.w - x - 1);
           tmpPixel:= pixels^[i];
           pixels^[i]:= pixels^[j];
           pixels^[j]:= tmpPixel;
           end;
end;

procedure copyToXY(src, dest: PSDL_Surface; destX, destY: Integer);
var srcX, srcY, i, j, maxDest: LongInt;
    srcPixels, destPixels: PLongWordArray;
begin
maxDest:= (dest^.pitch div 4) * dest^.h;
srcPixels:= src^.pixels;
destPixels:= dest^.pixels;

for srcX:= 0 to src^.w - 1 do
   for srcY:= 0 to src^.h - 1 do
      begin
      i:= (destY + srcY) * (dest^.pitch div 4) + destX + srcX;
      j:= srcY * (src^.pitch div 4) + srcX;
      // basic skip of transparent pixels - cleverness would be to do true alpha
      if (i < maxDest) and (AMask and srcPixels^[j] <> 0) then destPixels^[i]:= srcPixels^[j];
      end;
end;

procedure copyRotatedSurface(src, dest: PSDL_Surface); // this is necessary since width/height are read only in SDL, apparently
var y, x, i, j: LongInt;
    srcPixels, destPixels: PLongWordArray;
begin
TryDo(src^.format^.BytesPerPixel = 4, 'rotateSurface failed, expecting 32 bit surface', true);
TryDo(dest^.format^.BytesPerPixel = 4, 'rotateSurface failed, expecting 32 bit surface', true);

srcPixels:= src^.pixels;
destPixels:= dest^.pixels;

j:= 0;
for x := 0 to src^.w - 1 do
    for y := 0 to src^.h - 1 do
        begin
        i:= (src^.h - 1 - y) * (src^.pitch div 4) + x;
        destPixels^[j]:= srcPixels^[i];
        inc(j)
        end;
end;

function RenderHelpWindow(caption, subcaption, description, extra: ansistring; extracolor: LongInt; iconsurf: PSDL_Surface; iconrect: PSDL_Rect): PTexture;
var tmpsurf: PSDL_SURFACE;
	w, h, i, j: LongInt;
	font: THWFont;
	r, r2: TSDL_Rect;
	wa, ha: LongInt;
	tmpline, tmpline2, tmpdesc: ansistring;
begin
// make sure there is a caption as well as a sub caption - description is optional
if caption = '' then caption:= '???';
if subcaption = '' then subcaption:= ' ';

font:= CheckCJKFont(caption,fnt16);
font:= CheckCJKFont(subcaption,font);
font:= CheckCJKFont(description,font);
font:= CheckCJKFont(extra,font);

w:= 0;
h:= 0;
wa:= FontBorder * 2 + 4;
ha:= FontBorder * 2;

// TODO: Recheck height/position calculation

// get caption's dimensions
TTF_SizeUTF8(Fontz[font].Handle, Str2PChar(caption), i, j);
// width adds 36 px (image + space)
w:= i + 36 + wa;
h:= j + ha;

// get sub caption's dimensions
TTF_SizeUTF8(Fontz[font].Handle, Str2PChar(subcaption), i, j);
// width adds 36 px (image + space)
if w < (i + 36 + wa) then w:= i + 36 + wa;
inc(h, j + ha);

// get description's dimensions
tmpdesc:= description;
while tmpdesc <> '' do
	begin
	tmpline:= tmpdesc;
	SplitByChar(tmpline, tmpdesc, '|');
	if tmpline <> '' then
		begin
		TTF_SizeUTF8(Fontz[font].Handle, Str2PChar(tmpline), i, j);
		if w < (i + wa) then w:= i + wa;
		inc(h, j + ha)
		end
	end;

if extra <> '' then
	begin
	// get extra label's dimensions
	TTF_SizeUTF8(Fontz[font].Handle, Str2PChar(extra), i, j);
	if w < (i + wa) then w:= i + wa;
	inc(h, j + ha);
	end;
	
// add borders space
inc(w, wa);
inc(h, ha + 8);

tmpsurf:= SDL_CreateRGBSurface(SDL_SWSURFACE, w, h, 32, RMask, GMask, BMask, AMask);
TryDo(tmpsurf <> nil, 'RenderHelpWindow: fail to create surface', true);

// render border and background
r.x:= 0;
r.y:= 0;
r.w:= w;
r.h:= h;
DrawRoundRect(@r, cWhiteColor, cNearBlackColor, tmpsurf, true);

// render caption
r:= WriteInRect(tmpsurf, 36 + FontBorder + 2, ha, $ffffffff, font, caption);
// render sub caption
r:= WriteInRect(tmpsurf, 36 + FontBorder + 2, r.y + r.h, $ffc7c7c7, font, subcaption);

// render all description lines
tmpdesc:= description;
while tmpdesc <> '' do
	begin
	tmpline:= tmpdesc;
	SplitByChar(tmpline, tmpdesc, '|');
	r2:= r;
	if tmpline <> '' then
		begin
		r:= WriteInRect(tmpsurf, FontBorder + 2, r.y + r.h, $ff707070, font, tmpline);
		
		// render highlighted caption (if there's a ':')
		SplitByChar(tmpline, tmpline2, ':');
		if tmpline2 <> '' then
			WriteInRect(tmpsurf, FontBorder + 2, r2.y + r2.h, $ffc7c7c7, font, tmpline + ':');
		end
	end;

if extra <> '' then
	r:= WriteInRect(tmpsurf, FontBorder + 2, r.y + r.h, extracolor, font, extra);

r.x:= FontBorder + 6;
r.y:= FontBorder + 4;
r.w:= 32;
r.h:= 32;
SDL_FillRect(tmpsurf, @r, $ffffffff);
SDL_UpperBlit(iconsurf, iconrect, tmpsurf, @r);
	
RenderHelpWindow:=  Surface2Tex(tmpsurf, true);
SDL_FreeSurface(tmpsurf)
end;

procedure RenderWeaponTooltip(atype: TAmmoType);
{$IFNDEF IPHONEOS}
var r: TSDL_Rect;
	i: LongInt;
	extra: ansistring;
	extracolor: LongInt;
begin
// don't do anything if the window shouldn't be shown
if not cWeaponTooltips then
	begin
	WeaponTooltipTex:= nil;
	exit
	end;

// free old texture
FreeWeaponTooltip;

// image region
i:= LongInt(atype) - 1;
r.x:= (i shr 5) * 32;
r.y:= (i mod 32) * 32;
r.w:= 32;
r.h:= 32;

// default (no extra text)
extra:= '';
extracolor:= 0;

if (CurrentTeam <> nil) and (Ammoz[atype].SkipTurns >= CurrentTeam^.Clan^.TurnNumber) then // weapon or utility is not yet available
	begin
	extra:= trmsg[sidNotYetAvailable];
	extracolor:= LongInt($ffc77070);
	end
else if (Ammoz[atype].Ammo.Propz and ammoprop_NoRoundEndHint) <> 0 then // weapon or utility won't end your turn
	begin
	extra:= trmsg[sidNoEndTurn];
	extracolor:= LongInt($ff70c770);
	end
else 
	begin
	extra:= '';
	extracolor:= 0;
	end;

// render window and return the texture
WeaponTooltipTex:= RenderHelpWindow(trammo[Ammoz[atype].NameId], trammoc[Ammoz[atype].NameId], trammod[Ammoz[atype].NameId], extra, extracolor, SpritesData[sprAMAmmos].Surface, @r)
end;
{$ELSE}
begin end;
{$ENDIF}

procedure ShowWeaponTooltip(x, y: LongInt);
begin
{$IFNDEF IPHONEOS}
// draw the texture if it exists
if WeaponTooltipTex <> nil then
	DrawTexture(x, y, WeaponTooltipTex)
{$ENDIF}
end;

procedure FreeWeaponTooltip;
begin
{$IFNDEF IPHONEOS}
// free the existing texture (if there's any)
if WeaponTooltipTex = nil then
	exit;
FreeTexture(WeaponTooltipTex);
WeaponTooltipTex:= nil
{$ENDIF}
end;

procedure init_uStore;
begin
PixelFormat:= nil;
SDLPrimSurface:= nil;
{$IFNDEF IPHONEOS}cGPUVendor:= gvUnknown;{$ENDIF}

cScaleFactor:= 2.0;
SupportNPOTT:= false;
Step:= 0;
ProgrTex:= nil;
end;

procedure free_uStore;
begin
end;

end.
