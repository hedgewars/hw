(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2009 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uLandTexture;
interface
uses SDLh, uLandTemplates, uFloat, GL, uConsts;

procedure UpdateLandTexture(Y, Height: LongInt);
procedure DrawLand (X, Y: LongInt);

implementation
uses uMisc, uLand, uStore;

var LandTexture: PTexture = nil;
    updTopY: LongInt = LAND_HEIGHT;
    updBottomY: LongInt = 0;


procedure UpdateLandTexture(Y, Height: LongInt);
begin
if (Height <= 0) then exit;

TryDo((Y >= 0) and (Y < LAND_HEIGHT), 'UpdateLandTexture: wrong Y parameter', true);
TryDo(Y + Height <= LAND_HEIGHT, 'UpdateLandTexture: wrong Height parameter', true);

if Y < updTopY then updTopY:= Y;
if Y + Height > updBottomY then updBottomY:= Y + Height
end;

procedure RealLandTexUpdate;
begin
if updBottomY = 0 then exit;

if LandTexture = nil then
	LandTexture:= NewTexture(LAND_WIDTH, LAND_HEIGHT, @LandPixels)
else
	begin
	glBindTexture(GL_TEXTURE_2D, LandTexture^.id);
	glTexSubImage2D(GL_TEXTURE_2D, 0, 0, updTopY, LAND_WIDTH, updBottomY - updTopY, GL_RGBA, GL_UNSIGNED_BYTE, @LandPixels[updTopY, 0]);
	end;

updTopY:= LAND_HEIGHT + 1;
updBottomY:= 0
end;

procedure DrawLand(X, Y: LongInt);
begin
RealLandTexUpdate;
DrawTexture(X, Y, LandTexture)
end;

end.
