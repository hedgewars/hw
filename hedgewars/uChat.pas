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
procedure KeyPressChat(Key: Longword);

var UserNick: shortstring = '';

implementation
uses uMisc, uStore, uConsts, SDLh, uConsole, uKeys;

const MaxStrIndex = 7;

type TChatLine = record
		s: shortstring;
		Time: Longword;
		Tex: PTexture;
		end;

var Strs: array[0 .. MaxStrIndex] of TChatLine;
	lastStr: Longword = 0;
	visibleCount: Longword = 0;
	
	InputStr: TChatLine;
	InputStrL: array[0..260] of char; // for full str + 4-byte utf-8 char

procedure SetLine(var cl: TChatLine; str: shortstring);
var strSurface, resSurface: PSDL_Surface;
    r: TSDL_Rect;
    w, h: LongInt;
begin
if cl.Tex <> nil then
	FreeTexture(cl.Tex);

TTF_SizeUTF8(Fontz[fnt16].Handle, Str2PChar(str), w, h);

resSurface:= SDL_CreateRGBSurface(0,
		toPowerOf2(w + 2),
		toPowerOf2(h + 2),
		32,
		RMask, GMask, BMask, AMask);

strSurface:= TTF_RenderUTF8_Solid(Fontz[fnt16].Handle, Str2PChar(str), $202020);
r.x:= 1;
r.y:= 1;
SDL_UpperBlit(strSurface, nil, resSurface, @r);

strSurface:= TTF_RenderUTF8_Solid(Fontz[fnt16].Handle, Str2PChar(str), $FFFFFF);
SDL_UpperBlit(strSurface, nil, resSurface, nil);

SDL_FreeSurface(strSurface);

cl.s:= str;
cl.Time:= RealTicks + 7500;
cl.Tex:= Surface2Tex(resSurface);
SDL_FreeSurface(resSurface)
end;

procedure AddChatString(s: shortstring);
begin
lastStr:= (lastStr + 1) mod (MaxStrIndex + 1);

SetLine(Strs[lastStr], s);

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
	DrawTexture(8, (visibleCount - t) * 16 - 6 + cConsoleYAdd, Strs[i].Tex);
	if i = 0 then i:= MaxStrIndex else dec(i);
	inc(cnt);
	inc(t)
	end;

visibleCount:= cnt;

if (GameState = gsChat)
	and (InputStr.Tex <> nil) then
	DrawTexture(11, visibleCount * 16 + 10 + cConsoleYAdd, InputStr.Tex);
end;

procedure KeyPressChat(Key: Longword);
const firstByteMark: array[1..4] of byte = (0, $C0, $E0, $F0);
var i, btw: integer;
    utf8, s: shortstring;
begin
if Key <> 0 then
	case Key of
		8: if Length(InputStr.s) > 0 then
				begin
				InputStr.s[0]:= InputStrL[byte(InputStr.s[0])];
				SetLine(InputStr, InputStr.s)
				end;
		13, 271: begin
			if Length(InputStr.s) > 0 then
				begin
				ParseCommand('/say ' + InputStr.s, true);
				SetLine(InputStr, '')
				end;
			FreezeEnterKey;
			GameState:= gsGame
			end
	else
	if (Key < $80) then btw:= 1
	else if (Key < $800) then btw:= 2
	else if (Key < $10000) then btw:= 3
	else btw:= 4;
	
	utf8:= '';

	for i:= btw downto 2 do
		begin
		utf8:= char((Key or $80) and $BF) + utf8;
		Key:= Key shr 6
		end;
	
	utf8:= char(Key or firstByteMark[btw]) + utf8;

	InputStrL[byte(InputStr.s[0]) + btw]:= InputStr.s[0];
	SetLine(InputStr, InputStr.s + utf8)
	end
end;


end.
