(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2013 Andrey Korotaev <unC0Rr@gmail.com>
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
uses SDLh;

procedure initModule;
procedure freeModule;
procedure ReloadLines;
procedure CleanupInput;
procedure AddChatString(s: shortstring);
procedure DrawChat;
procedure SendHogSpeech(s: shortstring);

procedure KeyPressChat(Sym: Longword);
procedure TextInput(var event: TSDL_TextInputEvent);

implementation
uses uInputHandler, uTypes, uVariables, uCommands, uUtils, uTextures, uRender, uIO;

const MaxStrIndex = 27;

type TChatLine = record
    Tex: PTexture;
    Time: Longword;
    Width: LongInt;
    s: shortstring;
    end;
    TChatCmd = (quit, pause, finish, showhistory, fullscreen);

var Strs: array[0 .. MaxStrIndex] of TChatLine;
    MStrs: array[0 .. MaxStrIndex] of shortstring;
    LocalStrs: array[0 .. MaxStrIndex] of shortstring;
    missedCount: LongWord;
    lastStr: LongWord;
    localLastStr: LongInt;
    history: LongInt;
    visibleCount: LongWord;
    InputStr: TChatLine;
    InputStrL: array[0..260] of char; // for full str + 4-byte utf-8 char
    ChatReady: boolean;
    showAll: boolean;

const
    colors: array[#0..#6] of TSDL_Color = (
            (r:$FF; g:$FF; b:$FF; a:$FF), // unused, feel free to take it for anything
            (r:$FF; g:$FF; b:$FF; a:$FF), // chat message [White]
            (r:$FF; g:$00; b:$FF; a:$FF), // action message [Purple]
            (r:$90; g:$FF; b:$90; a:$FF), // join/leave message [Lime]
            (r:$FF; g:$FF; b:$A0; a:$FF), // team message [Light Yellow]
            (r:$FF; g:$00; b:$00; a:$FF), // error messages [Red]
            (r:$00; g:$FF; b:$FF; a:$FF)  // input line [Light Blue]
            );
    ChatCommandz: array [TChatCmd] of record
            ChatCmd: string[31];
            ProcedureCallChatCmd: string[31];
            end = (
            (ChatCmd: '/quit'; ProcedureCallChatCmd: 'halt'),
            (ChatCmd: '/pause'; ProcedureCallChatCmd: 'pause'),
            (ChatCmd: '/finish'; ProcedureCallChatCmd: 'finish'),
            (ChatCmd: '/history'; ProcedureCallChatCmd: 'history'),
            (ChatCmd: '/fullscreen'; ProcedureCallChatCmd: 'fullscr')
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
    color:= colors[#6];
    str:= UserNick + '> ' + str + '_'
    end
else
    begin
    color:= colors[str[1]];
    delete(str, 1, 1)
    end;

font:= CheckCJKFont(str, fnt16);
w:= 0; h:= 0; // avoid compiler hints
TTF_SizeUTF8(Fontz[font].Handle, Str2PChar(str), @w, @h);

resSurface:= SDL_CreateRGBSurface(0, toPowerOf2(w), toPowerOf2(h), 32, RMask, GMask, BMask, AMask);

strSurface:= TTF_RenderUTF8_Solid(Fontz[font].Handle, Str2PChar(str), color);
cl.Width:= w + 4;
SDL_UpperBlit(strSurface, nil, resSurface, nil);
SDL_FreeSurface(strSurface);

cl.Time:= RealTicks + 12500;
cl.Tex:= Surface2Tex(resSurface, false);

SDL_FreeSurface(resSurface)
end;

// For uStore texture recreation
procedure ReloadLines;
var i, t: LongWord;
begin
    if InputStr.s <> '' then
        SetLine(InputStr, InputStr.s, true);
    for i:= 0 to MaxStrIndex do
        if Strs[i].s <> '' then
            begin
            t:= Strs[i].Time;
            SetLine(Strs[i], Strs[i].s, false);
            Strs[i].Time:= t
            end;
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

if (GameState = gsChat) and (InputStr.Tex <> nil) then
    begin
    r.w:= InputStr.Width;
    DrawFillRect(r);
    Tint($00, $00, $00, $80);
    DrawTexture(9 - cScreenWidth div 2, visibleCount * 16 + 11, InputStr.Tex);
    untint;
    DrawTexture(8 - cScreenWidth div 2, visibleCount * 16 + 10, InputStr.Tex);
    end;

dec(r.y, 16);

while (((t < 7) and (Strs[i].Time > RealTicks)) or ((t < MaxStrIndex) and showAll))
and (Strs[i].Tex <> nil) do
    begin
    r.w:= Strs[i].Width;
    DrawFillRect(r);
    Tint($00, $00, $00, $80);
    DrawTexture(9 - cScreenWidth div 2, (visibleCount - t) * 16 - 5, Strs[i].Tex);
    untint;
    DrawTexture(8 - cScreenWidth div 2, (visibleCount - t) * 16 - 6, Strs[i].Tex);
    dec(r.y, 16);

    if i = 0 then
        i:= MaxStrIndex
    else
        dec(i);

    inc(cnt);
    inc(t)
    end;

visibleCount:= cnt;
end;

procedure SendHogSpeech(s: shortstring);
begin
SendIPC('h' + s);
ParseCommand('/hogsay '+s, true)
end;

procedure AcceptChatString(s: shortstring);
var i: TWave;
    j: TChatCmd;
    c, t: LongInt;
    x: byte;
begin
t:= LocalTeam;
x:= 0;
if (s[1] = '"') and (s[Length(s)] = '"')
    then x:= 1

else if (s[1] = '''') and (s[Length(s)] = '''') then
    x:= 2

else if (s[1] = '-') and (s[Length(s)] = '-') then
    x:= 3;

if not CurrentTeam^.ExtDriven and (x <> 0) then
    for c:= 0 to Pred(TeamsCount) do
        if (TeamsArray[c] = CurrentTeam) then
            t:= c;

if x <> 0 then
    begin
    if t = -1 then
        ParseCommand('/say ' + copy(s, 2, Length(s)-2), true)
    else
        SendHogSpeech(char(x) + char(t) + copy(s, 2, Length(s)-2));
    exit
    end;

if (s[1] = '/') then
    begin
    // These 3 are same as above, only are to make the hedgehog say it on next attack
    if (copy(s, 1, 5) = '/hsa ') then
        begin
        if CurrentTeam^.ExtDriven then
            ParseCommand('/say ' + copy(s, 6, Length(s)-5), true)
        else
            SendHogSpeech(#4 + copy(s, 6, Length(s)-5));
        exit
        end;

    if (copy(s, 1, 5) = '/hta ') then
        begin
        if CurrentTeam^.ExtDriven then
            ParseCommand('/say ' + copy(s, 6, Length(s)-5), true)
        else
            SendHogSpeech(#5 + copy(s, 6, Length(s)-5));
        exit
        end;

    if (copy(s, 1, 5) = '/hya ') then
        begin
        if CurrentTeam^.ExtDriven then
            ParseCommand('/say ' + copy(s, 6, Length(s)-5), true)
        else
            SendHogSpeech(#6 + copy(s, 6, Length(s)-5));
        exit
        end;

    if (copy(s, 1, 6) = '/team ') and (length(s) > 6) then
        begin
        ParseCommand(s, true);
        exit
        end;

    if (copy(s, 1, 4) = '/me ') then
        begin
        ParseCommand('/say ' + s, true);
        exit
        end;

    if (not CurrentTeam^.ExtDriven) and (CurrentTeam^.Hedgehogs[0].BotLevel = 0) then
        begin
        for i:= Low(TWave) to High(TWave) do
            if (s = Wavez[i].cmd) then
                begin
                ParseCommand('/taunt ' + char(i), true);
                exit
                end;

        for j:= Low(TChatCmd) to High(TChatCmd) do
            if (s = ChatCommandz[j].ChatCmd) then
                begin
                ParseCommand(ChatCommandz[j].ProcedureCallChatCmd, true);
                exit
                end;
        end
    end
    else
        ParseCommand('/say ' + s, true);
end;

procedure CleanupInput;
begin
    FreezeEnterKey;
    history:= 0;
    SDL_StopTextInput();
    GameState:= gsGame;
    ResetKbd;
end;

procedure TextInput(var event: TSDL_TextInputEvent);
var s: shortstring;
    l: byte;
begin
    l:= 0;
    while event.text[l] <> #0 do
        begin
        s[l + 1]:= event.text[l];
        inc(l)
        end;
    s[0]:= char(l);

    if byte(InputStr.s[0]) + l > 240 then exit;

    InputStrL[byte(InputStr.s[0]) + l]:= InputStr.s[0];
    SetLine(InputStr, InputStr.s + s, true)
end;

procedure KeyPressChat(Sym: Longword);
const firstByteMark: array[0..3] of byte = (0, $C0, $E0, $F0);
var i, btw, index: integer;
    utf8: shortstring;
    action: boolean;
begin
    action:= true;
    case Sym of
        SDLK_BACKSPACE:
            begin
            if Length(InputStr.s) > 0 then
                begin
                InputStr.s[0]:= InputStrL[byte(InputStr.s[0])];
                SetLine(InputStr, InputStr.s, true)
                end
            end;
        SDLK_ESCAPE:
            begin
            if Length(InputStr.s) > 0 then
                SetLine(InputStr, '', true)
            else CleanupInput
            end;
        SDLK_RETURN, SDLK_KP_ENTER:
            begin
            if Length(InputStr.s) > 0 then
                begin
                AcceptChatString(InputStr.s);
                SetLine(InputStr, '', false)
                end;
            CleanupInput
            end;
        SDLK_UP, SDLK_DOWN:
            begin
            if (Sym = SDLK_UP) and (history < localLastStr) then inc(history);
            if (Sym = SDLK_DOWN) and (history > 0) then dec(history);
            index:= localLastStr - history + 1;
            if (index > localLastStr) then
                 SetLine(InputStr, '', true)
            else SetLine(InputStr, LocalStrs[index], true)
            end;
        SDLK_RIGHT, SDLK_LEFT, SDLK_DELETE,
        SDLK_HOME, SDLK_END,
        SDLK_PAGEUP, SDLK_PAGEDOWN:
            begin
            // ignore me!!!
            end;
        else
            action:= false;
        end;

end;

procedure chChatMessage(var s: shortstring);
begin
    AddChatString(s)
end;

procedure chSay(var s: shortstring);
begin
    SendIPC('s' + s);

    if copy(s, 1, 4) = '/me ' then
        s:= #2 + '* ' + UserNick + ' ' + copy(s, 5, Length(s) - 4)
    else
        begin
        localLastStr:= (localLastStr + 1) mod MaxStrIndex;
        LocalStrs[localLastStr]:= s;
        s:= #1 + UserNick + ': ' + s;
        end;

    AddChatString(s)
end;

procedure chTeamSay(var s: shortstring);
begin
    SendIPC('b' + s);

    s:= #4 + '[Team] ' + UserNick + ': ' + s;

    AddChatString(s)
end;

procedure chHistory(var s: shortstring);
begin
    s:= s; // avoid compiler hint
    showAll:= not showAll
end;

procedure chChat(var s: shortstring);
begin
    s:= s; // avoid compiler hint
    GameState:= gsChat;
    SDL_StartTextInput();
    if length(s) = 0 then
        SetLine(InputStr, '', true)
    else
        SetLine(InputStr, '/team ', true)
end;

procedure initModule;
var i: ShortInt;
begin
    RegisterVariable('chatmsg', @chChatMessage, true);
    RegisterVariable('say', @chSay, true);
    RegisterVariable('team', @chTeamSay, true);
    RegisterVariable('history', @chHistory, true );
    RegisterVariable('chat', @chChat, true );

    lastStr:= 0;
    localLastStr:= 0;
    history:= 0;
    visibleCount:= 0;
    showAll:= false;
    ChatReady:= false;
    missedCount:= 0;

    inputStr.Tex := nil;
    for i:= 0 to MaxStrIndex do
        Strs[i].Tex := nil;
end;

procedure freeModule;
var i: ShortInt;
begin
    FreeTexture(InputStr.Tex);
    for i:= 0 to MaxStrIndex do
        FreeTexture(Strs[i].Tex);
end;

end.
