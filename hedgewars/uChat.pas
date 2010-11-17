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

{$INCLUDE "options.inc"}

unit uChat;

interface

procedure initModule;
procedure freeModule;

procedure AddChatString(s: shortstring);
procedure DrawChat;
procedure KeyPressChat(Key: Longword);

var UserNick: shortstring = '';
    ChatReady: boolean;
    showAll: boolean;

implementation
uses uMisc, uStore, uConsts, SDLh, uConsole, uKeys, uTeams, uTypes, uVariables;

const MaxStrIndex = 27;

type TChatLine = record
        Tex: PTexture;
        Time: Longword;
        Width: LongInt;
        s: shortstring;
        end;

var Strs: array[0 .. MaxStrIndex] of TChatLine;
    MStrs: array[0 .. MaxStrIndex] of shortstring;
    missedCount: LongWord;
    lastStr: LongWord;
    visibleCount: LongWord;
    InputStr: TChatLine;
    InputStrL: array[0..260] of char; // for full str + 4-byte utf-8 char

const colors: array[#1..#5] of TSDL_Color = (
    (r:$FF; g:$FF; b:$FF; unused:$FF), // chat message [White]
    (r:$FF; g:$00; b:$FF; unused:$FF), // action message [Purple]
    (r:$90; g:$FF; b:$90; unused:$FF), // join/leave message [Lime]
    (r:$FF; g:$FF; b:$A0; unused:$FF), // team message [Light Yellow]
    (r:$FF; g:$00; b:$00; unused:$ff)  // error messages [Red]
    );

procedure SetLine(var cl: TChatLine; str: shortstring; isInput: boolean);
var strSurface, resSurface: PSDL_Surface;
    w, h: LongInt;
    color: TSDL_Color;
    font: THWFont;
begin
if cl.Tex <> nil then
    FreeTexture(cl.Tex);


cl.s:= str;

if isInput then
begin
    // [Light Blue]
    color.r:= $00;
    color.g:= $FF;
    color.b:= $FF;
    color.unused:= $FF;
    str:= UserNick + '> ' + str + '_'
end
else
begin
    color:= colors[str[1]];
    delete(str, 1, 1)
end;

font:= CheckCJKFont(str, fnt16);
w:= 0; h:= 0; // avoid compiler hints
TTF_SizeUTF8(Fontz[font].Handle, Str2PChar(str), w, h);

resSurface:= SDL_CreateRGBSurface(0, toPowerOf2(w), toPowerOf2(h), 32, RMask, GMask, BMask, AMask);

strSurface:= TTF_RenderUTF8_Solid(Fontz[font].Handle, Str2PChar(str), color);
cl.Width:= w + 4;
SDL_UpperBlit(strSurface, nil, resSurface, nil);
SDL_FreeSurface(strSurface);

cl.Time:= RealTicks + 12500;
cl.Tex:= Surface2Tex(resSurface, false);

SDL_FreeSurface(resSurface)
end;

procedure AddChatString(s: shortstring);
begin
if not ChatReady then
    begin
    if MissedCount < MaxStrIndex - 1 then
        MStrs[MissedCount]:= s
    else if MissedCount < MaxStrIndex then
        MStrs[MissedCount]:= #5 + '[...]';
    inc(MissedCount);
    exit
    end;

lastStr:= (lastStr + 1) mod (MaxStrIndex + 1);

SetLine(Strs[lastStr], s, false);

inc(visibleCount)
end;

procedure DrawChat;
var i, t, cnt: Longword;
    r: TSDL_Rect;
begin
ChatReady:= true; // maybe move to somewhere else?
if MissedCount <> 0 then // there are chat strings we missed, so print them now
    begin
    for i:= 0 to MissedCount - 1 do
        AddChatString(MStrs[i]);
    MissedCount:= 0;
    end;
cnt:= 0;
t:= 0;
i:= lastStr;

r.x:= 6 - cScreenWidth div 2;
r.y:= (visibleCount - t) * 16 + 10;
r.h:= 16;

if (GameState = gsChat)
    and (InputStr.Tex <> nil) then
    begin
    r.w:= InputStr.Width;
    DrawFillRect(r);
    Tint($00, $00, $00, $80);
    DrawTexture(9 - cScreenWidth div 2, visibleCount * 16 + 11, InputStr.Tex);
    Tint($FF, $FF, $FF, $FF);
    DrawTexture(8 - cScreenWidth div 2, visibleCount * 16 + 10, InputStr.Tex);
    end;

dec(r.y, 16);

while
    (
            ((t < 7) and (Strs[i].Time > RealTicks))
        or
            ((t < MaxStrIndex) and showAll)
    )
    and
        (Strs[i].Tex <> nil) do
    begin
    r.w:= Strs[i].Width;
    DrawFillRect(r);
    Tint($00, $00, $00, $80);
    DrawTexture(9 - cScreenWidth div 2, (visibleCount - t) * 16 - 5, Strs[i].Tex);
    Tint($FF, $FF, $FF, $FF);
    DrawTexture(8 - cScreenWidth div 2, (visibleCount - t) * 16 - 6, Strs[i].Tex);
    dec(r.y, 16);

    if i = 0 then i:= MaxStrIndex else dec(i);
    inc(cnt);
    inc(t)
    end;

visibleCount:= cnt;
end;

procedure AcceptChatString(s: shortstring);
var i: TWave;

begin
// "Make hedgehog say something"
if (s[1] = '"') and (s[Length(s)] = '"') then
    begin
    if CurrentTeam^.ExtDriven then
        ParseCommand('/say ' + copy(s, 2, Length(s)-2), true)
    else
        ParseCommand('/hogsay '#1 + copy(s, 2, Length(s)-2), true);
    exit
    end;
// 'Make hedgehog think something'
if (s[1] = '''') and (s[Length(s)] = '''') then
    begin
    if CurrentTeam^.ExtDriven then
        ParseCommand('/say ' + copy(s, 2, Length(s)-2), true)
    else
        ParseCommand('/hogsay '#2 + copy(s, 2, Length(s)-2), true);
    exit
    end;
// -Make hedgehog yell something-
if (s[1] = '-') and (s[Length(s)] = '-') then
    begin
    if CurrentTeam^.ExtDriven then
        ParseCommand('/say ' + copy(s, 2, Length(s)-2), true)
    else
        ParseCommand('/hogsay '#3 + copy(s, 2, Length(s)-2), true);
    exit
    end;
// These 3 are same as above, only are to make the hedgehog say it on next attack
if (s[1] = '/') and (copy(s, 1, 5) = '/hsa ') then
    begin
    if CurrentTeam^.ExtDriven then
        ParseCommand('/say ' + copy(s, 6, Length(s)-5), true)
    else
        ParseCommand('/hogsay '#4 + copy(s, 6, Length(s)-5), true);
    exit
    end;
if (s[1] = '/') and (copy(s, 1, 5) = '/hta ') then
    begin
    if CurrentTeam^.ExtDriven then
        ParseCommand('/say ' + copy(s, 6, Length(s)-5), true)
    else
        ParseCommand('/hogsay '#5 + copy(s, 6, Length(s)-5), true);
    exit
    end;
if (s[1] = '/') and (copy(s, 1, 5) = '/hya ') then
    begin
    if CurrentTeam^.ExtDriven then
        ParseCommand('/say ' + copy(s, 6, Length(s)-5), true)
    else
        ParseCommand('/hogsay '#6 + copy(s, 6, Length(s)-5), true);
    exit
    end;

if (copy(s, 1, 6) = '/team ') and (length(s) > 6) then
    begin
    ParseCommand(s, true);
    exit
    end;
if (s[1] = '/') and (copy(s, 1, 4) <> '/me ') then
    begin
    if CurrentTeam^.ExtDriven or (CurrentTeam^.Hedgehogs[0].BotLevel <> 0) then
        exit;

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
        {Backspace}
        8, 127: if Length(InputStr.s) > 0 then
                begin
                InputStr.s[0]:= InputStrL[byte(InputStr.s[0])];
                SetLine(InputStr, InputStr.s, true)
                end;
        {Esc}
        27: SetLine(InputStr, '', true);
        {Return}
        3, 13, 271: begin
            if Length(InputStr.s) > 0 then
                begin
                AcceptChatString(InputStr.s);
                SetLine(InputStr, '', false)
                end;
            FreezeEnterKey;
            GameState:= gsGame
            end;
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

    if byte(InputStr.s[0]) + btw > 240 then exit;

    InputStrL[byte(InputStr.s[0]) + btw]:= InputStr.s[0];
    SetLine(InputStr, InputStr.s + utf8, true)
    end
end;

procedure initModule;
begin
    lastStr:= 0;
    visibleCount:= 0;
    showAll:= false;
    ChatReady:= false;
    missedCount:= 0;
end;

procedure freeModule;
begin
    UserNick:= '';
end;

end.
