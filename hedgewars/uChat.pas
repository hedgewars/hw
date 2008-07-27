(*
 * Hedgewars, a free turn based strategy game
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
	showAll: boolean = false;

implementation
uses uMisc, uStore, uConsts, SDLh, uConsole, uKeys, uTeams;

const MaxStrIndex = 27;

type TChatLine = record
		s: shortstring;
		Time: Longword;
		Texb, Texf: PTexture;
		end;

var Strs: array[0 .. MaxStrIndex] of TChatLine;
	lastStr: Longword = 0;
	visibleCount: Longword = 0;
	
	InputStr: TChatLine;
	InputStrL: array[0..260] of char; // for full str + 4-byte utf-8 char

procedure SetLine(var cl: TChatLine; str: shortstring; isInput: boolean);
var surf: PSDL_Surface;
begin
if cl.Texb <> nil then
	begin
	FreeTexture(cl.Texb);
	FreeTexture(cl.Texf)
	end;

cl.s:= str;

if isInput then str:= UserNick + '> ' + str + '_';

cl.Time:= RealTicks + 12500;

TryDo(str <> '', 'Error: null chat string', true);

surf:= TTF_RenderUTF8_Solid(Fontz[fnt16].Handle, Str2PChar(str), $202020);
surf:= SDL_DisplayFormatAlpha(surf);
TryDo(surf <> nil, 'Chat: fail to render string', true);
cl.Texb:= Surface2Tex(surf);
SDL_FreeSurface(surf);

surf:= TTF_RenderUTF8_Solid(Fontz[fnt16].Handle, Str2PChar(str), $FFFFFF);
surf:= SDL_DisplayFormatAlpha(surf);
TryDo(surf <> nil, 'Chat: fail to render string', true);
cl.Texf:= Surface2Tex(surf);
SDL_FreeSurface(surf)
end;

procedure AddChatString(s: shortstring);
begin
lastStr:= (lastStr + 1) mod (MaxStrIndex + 1);

SetLine(Strs[lastStr], s, false);

inc(visibleCount)
end;

procedure DrawChat;
const shift = 2;
var i, t, cnt: Longword;
begin
cnt:= 0;
t:= 0;
i:= lastStr;
while
	(
			((t < 7) and (Strs[i].Time > RealTicks))
		or
			((t < MaxStrIndex) and showAll)
	)
	and
		(Strs[i].Texb <> nil) do
	begin
	DrawTexture(8 + shift, (visibleCount - t) * 16 - 6 + shift, Strs[i].Texb);
	DrawTexture(8, (visibleCount - t) * 16 - 6, Strs[i].Texf);
	if i = 0 then i:= MaxStrIndex else dec(i);
	inc(cnt);
	inc(t)
	end;

visibleCount:= cnt;

if (GameState = gsChat)
	and (InputStr.Texb <> nil) then
	begin
	DrawTexture(8 + shift, visibleCount * 16 + 10 + shift, InputStr.Texb);
	DrawTexture(8, visibleCount * 16 + 10, InputStr.Texf)
	end
end;

procedure AcceptChatString(s: shortstring);
var i: TWave;
begin
if s[1] = '/' then
	begin
	if CurrentTeam^.ExtDriven then exit;
	
	for i:= Low(TWave) to High(TWave) do
		if (s = Wavez[i].cmd) then
			begin
			ParseCommand('/taunt ' + char(i), true);
			exit
			end;
	end
	else
		ParseCommand('/say ' + s, true);
end;

procedure KeyPressChat(Key: Longword);
const firstByteMark: array[1..4] of byte = (0, $C0, $E0, $F0);
var i, btw: integer;
    utf8: shortstring;
begin
if Key <> 0 then
	case Key of
		8: if Length(InputStr.s) > 0 then
				begin
				InputStr.s[0]:= InputStrL[byte(InputStr.s[0])];
				SetLine(InputStr, InputStr.s, true)
				end;
		27: SetLine(InputStr, '', true);
		13, 271: begin
			if Length(InputStr.s) > 0 then
				begin
				AcceptChatString(InputStr.s);
				SetLine(InputStr, '', true)
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
	SetLine(InputStr, InputStr.s + utf8, true)
	end
end;


end.
