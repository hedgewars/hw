(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2008 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uChat;

interface

procedure AddChatString(s: shortstring);
procedure DrawChat;

implementation
uses uMisc, uStore, uConsts, SDLh;

const MaxStrIndex = 7;

type TStr = record
		Time: Longword;
		Tex: PTexture;
		end;

var Strs: array[0 .. MaxStrIndex] of TStr;
	lastStr: Longword = 0;
	visibleCount: Longword = 0;

procedure AddChatString(s: shortstring);
var strSurface, resSurface: PSDL_Surface;
    r: TSDL_Rect;
    w, h: LongInt;
begin
lastStr:= (lastStr + 1) mod (MaxStrIndex + 1);

TTF_SizeUTF8(Fontz[fnt16].Handle, Str2PChar(s), w, h);

resSurface:= SDL_CreateRGBSurface(0,
		toPowerOf2(w + 2),
		toPowerOf2(h + 2),
		32,
		RMask, GMask, BMask, AMask);

strSurface:= TTF_RenderUTF8_Solid(Fontz[fnt16].Handle, Str2PChar(s), $202020);
r.x:= 1;
r.y:= 1;
SDL_UpperBlit(strSurface, nil, resSurface, @r);

strSurface:= TTF_RenderUTF8_Solid(Fontz[fnt16].Handle, Str2PChar(s), $FFFFFF);
SDL_UpperBlit(strSurface, nil, resSurface, nil);

SDL_FreeSurface(strSurface);


Strs[lastStr].Time:= RealTicks + 7500;
Strs[lastStr].Tex:= Surface2Tex(resSurface);
SDL_FreeSurface(resSurface);

inc(visibleCount)
end;

procedure DrawChat;
var i, t, cnt: Longword;
begin
cnt:= 0;
t:= 0;
i:= lastStr;
while (t <= MaxStrIndex)
	and (Strs[i].Tex <> nil)
	and (Strs[i].Time > RealTicks) do
	begin
	DrawTexture(8, (visibleCount - t) * 16 - 8, Strs[i].Tex);
	if i = 0 then i:= MaxStrIndex else dec(i);
	inc(cnt);
	inc(t)
	end;

visibleCount:= cnt
end;

end.
