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
uses uMisc, uStore, uConsts;

const MaxStrIndex = 7;

type TStr = record
		Time: Longword;
		Tex: PTexture;
		end;

var Strs: array[0 .. MaxStrIndex] of TStr;
	lastStr: Longword = 0;

procedure AddChatString(s: shortstring);
begin
lastStr:= (lastStr + 1) mod (MaxStrIndex + 1);

Strs[lastStr].Time:= RealTicks + 7500;
Strs[lastStr].Tex:= RenderStringTex(s, $FFFFFF, fnt16)
end;

procedure DrawChat;
begin
if Strs[lastStr].Tex <> nil then DrawTexture(10, 10, Strs[lastStr].Tex)
end;

end.
