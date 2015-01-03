(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2014 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *)

{$INCLUDE "options.inc"}

unit uChat;

interface

procedure initModule;
procedure freeModule;
procedure ReloadLines;
procedure CleanupInput;
procedure AddChatString(s: shortstring);
procedure DrawChat;
procedure KeyPressChat(Key, Sym: Longword);
procedure SendHogSpeech(s: shortstring);

implementation
uses SDLh, uInputHandler, uTypes, uVariables, uCommands, uUtils, uTextures, uRender, uIO, uScript, uRenderUtils;

const MaxStrIndex = 27;

type TChatLine = record
    Tex: PTexture;
    Time: Longword;
    Width: LongInt;
    s: shortstring;
    Color: TSDL_Color;
    end;
    TChatCmd = (ccQuit, ccPause, ccFinish, ccShowHistory, ccFullScreen);

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
    liveLua: boolean;
    ChatHidden: boolean;

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


const Padding  = 2;
      ClHeight = 2 * Padding + 16; // font height

procedure RenderChatLineTex(var cl: TChatLine; var str: shortstring);
var strSurface,
    resSurface: PSDL_Surface;
    dstrect   : TSDL_Rect; // destination rectangle for blitting
    font      : THWFont;
const
    shadowint  = $80 shl AShift;
begin

font:= CheckCJKFont(ansistring(str), fnt16);

// get render size of text
TTF_SizeUTF8(Fontz[font].Handle, Str2PChar(str), @cl.Width, nil);

// calculate and save size
cl.Width := cl.Width  + 2 * Padding;

// create surface to draw on
resSurface:= SDL_CreateRGBSurface(
                0, toPowerOf2(cl.Width), toPowerOf2(ClHeight),
                32, RMask, GMask, BMask, AMask);

// define area we want to draw in
dstrect.x:= 0;
dstrect.y:= 0;
dstrect.w:= cl.Width;
dstrect.h:= ClHeight;

// draw background
SDL_FillRect(resSurface, @dstrect, shadowint);

// create and blit text
strSurface:= TTF_RenderUTF8_Blended(Fontz[font].Handle, Str2PChar(str), cl.color);
//SDL_UpperBlit(strSurface, nil, resSurface, @dstrect);
if strSurface <> nil then copyTOXY(strSurface, resSurface, Padding, Padding);
SDL_FreeSurface(strSurface);

cl.Tex:= Surface2Tex(resSurface, false);

SDL_FreeSurface(resSurface)
end;

const ClDisplayDuration = 12500;

procedure SetLine(var cl: TChatLine; str: shortstring; isInput: boolean);
var color  : TSDL_Color;
begin
if cl.Tex <> nil then
    FreeAndNilTexture(cl.Tex);

if isInput then
    begin
    cl.s:= str;
    color:= colors[#6];
    str:= UserNick + '> ' + str + '_'
    end
else
    begin
    color:= colors[str[1]];
    delete(str, 1, 1);
    cl.s:= str;
    end;

cl.color:= color;

// set texture, note: variables cl.s and str will be different here if isInput
RenderChatLineTex(cl, str);

cl.Time:= RealTicks + ClDisplayDuration;
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
var i, t, left, top, cnt: LongInt;
begin
ChatReady:= true; // maybe move to somewhere else?

if ChatHidden and (not showAll) then
    visibleCount:= 0;

// draw chat lines with some distance from screen border
left:= 4 - cScreenWidth div 2;
top := 10 + visibleCount * ClHeight; // we start with input line (if any)

// draw chat input line first and under all other lines
if (GameState = gsChat) and (InputStr.Tex <> nil) then
    DrawTexture(left, top, InputStr.Tex);

if ((not ChatHidden) or showAll) and (UIDisplay <> uiNone) then
    begin
    if MissedCount <> 0 then // there are chat strings we missed, so print them now
        begin
        for i:= 0 to MissedCount - 1 do
            AddChatString(MStrs[i]);
        MissedCount:= 0;
        end;
    i:= lastStr;

    cnt:= 0; // count of lines displayed
    t  := 1; // # of current line processed

    // draw lines in reverse order
    while (((t < 7) and (Strs[i].Time > RealTicks)) or ((t <= MaxStrIndex + 1) and showAll))
    and (Strs[i].Tex <> nil) do
        begin
        top:= top - ClHeight;
        // draw chatline only if not offscreen
        if top > 0 then
            DrawTexture(left, top, Strs[i].Tex);

        if i = 0 then
            i:= MaxStrIndex
        else
            dec(i);

        inc(cnt);
        inc(t)
        end;

    visibleCount:= cnt;
    end;
end;

procedure SendHogSpeech(s: shortstring);
begin
SendIPC('h' + s);
ParseCommand('/hogsay '+s, true)
end;

procedure SendConsoleCommand(s: shortstring);
begin
    Delete(s, 1, 1);
    SendIPC('~' + s)
end;

procedure AcceptChatString(s: shortstring);
var i: TWave;
    j: TChatCmd;
    c, t: LongInt;
    x: byte;
begin
if s <> LocalStrs[localLastStr] then
    begin
    // put in input history
    localLastStr:= (localLastStr + 1) mod MaxStrIndex;
    LocalStrs[localLastStr]:= s;
    end;

t:= LocalTeam;
x:= 0;
if (s[1] = '"') and (s[Length(s)] = '"')
    then x:= 1

else if (s[1] = '''') and (s[Length(s)] = '''') then
    x:= 2

else if (s[1] = '-') and (s[Length(s)] = '-') then
    x:= 3;

if (not CurrentTeam^.ExtDriven) and (x <> 0) then
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
    if (copy(s, 2, 4) = 'hsa ') then
        begin
        if CurrentTeam^.ExtDriven then
            ParseCommand('/say ' + copy(s, 6, Length(s)-5), true)
        else
            SendHogSpeech(#4 + copy(s, 6, Length(s)-5));
        exit
        end;

    if (copy(s, 2, 4) = 'hta ') then
        begin
        if CurrentTeam^.ExtDriven then
            ParseCommand('/say ' + copy(s, 6, Length(s)-5), true)
        else
            SendHogSpeech(#5 + copy(s, 6, Length(s)-5));
        exit
        end;

    if (copy(s, 2, 4) = 'hya ') then
        begin
        if CurrentTeam^.ExtDriven then
            ParseCommand('/say ' + copy(s, 6, Length(s)-5), true)
        else
            SendHogSpeech(#6 + copy(s, 6, Length(s)-5));
        exit
        end;

    if (copy(s, 2, 5) = 'team ') and (length(s) > 6) then
        begin
        ParseCommand(s, true);
        exit
        end;

    if (copy(s, 2, 3) = 'me ') then
        begin
        ParseCommand('/say ' + s, true);
        exit
        end;

    if (copy(s, 2, 10) = 'togglechat') then
        begin
        ChatHidden:= (not ChatHidden);
        if ChatHidden then
           showAll:= false;
        exit
        end;

    // debugging commands
    if (copy(s, 2, 7) = 'debugvl') then
        begin
        cViewLimitsDebug:= (not cViewLimitsDebug);
        UpdateViewLimits();
        exit
        end;

    if (copy(s, 2, 3) = 'lua') then
        begin
        AddFileLog('/lua issued');
        if gameType <> gmtNet then
            begin
            liveLua:= (not liveLua);
            if liveLua then
                begin
                AddFileLog('[Lua] chat input string parsing enabled');
                AddChatString(#3 + 'Lua parsing: ON');
                end
            else
                begin
                AddFileLog('[Lua] chat input string parsing disabled');
                AddChatString(#3 + 'Lua parsing: OFF');
                end;
            end;
        exit
        end;

    // hedghog animations/taunts and engine commands
    if (not CurrentTeam^.ExtDriven) and (CurrentTeam^.Hedgehogs[0].BotLevel = 0) then
        begin
        for i:= Low(TWave) to High(TWave) do
            if (s = Wavez[i].cmd) then
                begin
                ParseCommand('/taunt ' + char(i), true);
                exit
                end;
        end;

    for j:= Low(TChatCmd) to High(TChatCmd) do
        if (s = ChatCommandz[j].ChatCmd) then
            begin
            ParseCommand(ChatCommandz[j].ProcedureCallChatCmd, true);
            exit
            end;

    if (gameType = gmtNet) then
        SendConsoleCommand(s)
    end
else
    begin
    if liveLua then
        LuaParseString(s)
    else
        ParseCommand('/say ' + s, true);
    end;
end;

procedure CleanupInput;
begin
    FreezeEnterKey;
    history:= 0;
{$IFNDEF SDL2}
    SDL_EnableKeyRepeat(0,0);
{$ENDIF}
    GameState:= gsGame;
    ResetKbd;
end;

procedure KeyPressChat(Key, Sym: Longword);
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
    if not action and (Key <> 0) then
        begin
        if (Key < $80) then
            btw:= 1
        else if (Key < $800) then
            btw:= 2
        else if (Key < $10000) then
            btw:= 3
        else
            btw:= 4;

        utf8:= '';

        for i:= btw downto 2 do
            begin
            utf8:= char((Key or $80) and $BF) + utf8;
            Key:= Key shr 6
            end;

        utf8:= char(Key or firstByteMark[Pred(btw)]) + utf8;

        if byte(InputStr.s[0]) + btw > 240 then
            exit;

        InputStrL[byte(InputStr.s[0]) + btw]:= InputStr.s[0];
        SetLine(InputStr, InputStr.s + utf8, true)
        end
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
        s:= #1 + UserNick + ': ' + s;

    AddChatString(s)
end;

procedure chTeamSay(var s: shortstring);
begin
    SendIPC('b' + s);

    s:= #4 + '[Team] ' + UserNick + ': ' + s;

    AddChatString(s)
end;

procedure chHistory(var s: shortstring);
var i: LongInt;
begin
    s:= s; // avoid compiler hint
    showAll:= not showAll;
    // immediatly recount
    visibleCount:= 0;
    if showAll or (not ChatHidden) then
        for i:= 0 to MaxStrIndex do
            begin
            if (Strs[i].Tex <> nil) and (showAll or (Strs[i].Time > RealTicks)) then
                inc(visibleCount);
            end;
end;

procedure chChat(var s: shortstring);
begin
    s:= s; // avoid compiler hint
    GameState:= gsChat;
{$IFNDEF SDL2}
    SDL_EnableKeyRepeat(200,45);
{$ENDIF}
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
    liveLua:= false;
    ChatHidden:= false;

    inputStr.Tex := nil;
    for i:= 0 to MaxStrIndex do
        Strs[i].Tex := nil;
end;

procedure freeModule;
var i: ShortInt;
begin
    FreeAndNilTexture(InputStr.Tex);
    for i:= 0 to MaxStrIndex do
        FreeAndNilTexture(Strs[i].Tex);
end;

end.
