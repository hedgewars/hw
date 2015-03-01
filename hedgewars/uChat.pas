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
procedure KeyPressChat(Key, Sym: Longword; Modifier: Word);
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

type TInputStrL = array[0..260] of byte;

var Strs: array[0 .. MaxStrIndex] of TChatLine;
    MStrs: array[0 .. MaxStrIndex] of shortstring;
    LocalStrs: array[0 .. MaxStrIndex] of shortstring;
    LocalStrsL: array[0 .. MaxStrIndex] of TInputStrL;
    missedCount: LongWord;
    lastStr: LongWord;
    localLastStr: LongInt;
    history: LongInt;
    visibleCount: LongWord;
    InputStr: TChatLine;
    InputStrL: TInputStrL; // for full str + 4-byte utf-8 char
    ChatReady: boolean;
    showAll: boolean;
    liveLua: boolean;
    ChatHidden: boolean;
    firstDraw: boolean;
    InputLinePrefix: shortstring;
    // cursor
    cursorPos, cursorX, selectedPos, selectionDx: LongInt;
    LastKeyPressTick: LongWord;

const
    InputStrLNoPred: byte = 255;

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

procedure ResetSelection();
begin
    selectedPos:= -1;
end;

procedure UpdateCursorCoords();
var font: THWFont;
    str : shortstring;
    coff, soff: LongInt;
begin
    if cursorPos = selectedPos then
        ResetSelection();

    // calculate cursor offset

    str:= InputLinePrefix + InputStr.s;
    font:= CheckCJKFont(ansistring(str), fnt16);

    // get only substring before cursor to determine length
    // SetLength(str, Length(InputLinePrefix) + cursorPos); // makes pas2c unhappy
    str[0]:= char(Length(InputLinePrefix) + cursorPos);
    // get render size of text
    TTF_SizeUTF8(Fontz[font].Handle, Str2PChar(str), @coff, nil);

    cursorX:= 2 + coff;

    // calculate selection width on screen
    if selectedPos >= 0 then
        begin
        if selectedPos > cursorPos then
            str:= InputLinePrefix + InputStr.s;
        // SetLength(str, Length(InputLinePrefix) + selectedPos); // makes pas2c unhappy
        str[0]:= char(Length(InputLinePrefix) + selectedPos);
        TTF_SizeUTF8(Fontz[font].Handle, Str2PChar(str), @soff, nil);
        selectionDx:= soff - coff;
        end
    else
        selectionDx:= 0;
end;


procedure ResetCursor();
begin
    ResetSelection();
    cursorPos:= 0;
    UpdateCursorCoords();
end;

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
    str:= InputLinePrefix + str + ' ';
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
    selRect: TSDL_Rect;
begin
ChatReady:= true; // maybe move to somewhere else?

if ChatHidden and (not showAll) then
    visibleCount:= 0;

// draw chat lines with some distance from screen border
left:= 4 - cScreenWidth div 2;
top := 10 + visibleCount * ClHeight; // we start with input line (if any)

// draw chat input line first and under all other lines
if (GameState = gsChat) and (InputStr.Tex <> nil) then
    begin
    if firstDraw then
        begin
        UpdateCursorCoords();
        firstDraw:= false;
        end;

    DrawTexture(left, top, InputStr.Tex);
    if selectedPos < 0 then
        begin
        // draw cursor
        if ((RealTicks - LastKeyPressTick) and 512) < 256 then
            DrawLineOnScreen(left + cursorX, top + 2, left + cursorX, top + ClHeight - 2, 2.0, $00, $FF, $FF, $FF);
        end
    else // draw selection
        begin
        selRect.y:= top + 2;
        selRect.h:= clHeight - 4;
        if selectionDx < 0 then
            begin
            selRect.x:= left + cursorX + selectionDx;
            selRect.w:= -selectionDx;
            end
        else
            begin
            selRect.x:= left + cursorX;
            selRect.w:= selectionDx;
            end;

        DrawRect(selRect, $FF, $FF, $FF, $40, true);
        end;
    end;


// draw chat lines
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
    LocalStrsL[localLastStr]:= InputStrL;
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

procedure DelBytesFromInputStrBack(endIdx: integer; count: byte);
var i, startIdx: integer;
begin
    // nothing to do if count is 0
    if count = 0 then
        exit;

    // first byte to delete
    startIdx:= endIdx - (count - 1);

    // delete bytes from string
    Delete(InputStr.s, startIdx, count);

    // wipe utf8 info for deleted char
    InputStrL[endIdx]:= InputStrLNoPred;

    // shift utf8 char info to reflect new string
    for i:= endIdx + 1 to Length(InputStr.s) + count do
        begin
        if InputStrL[i] <> InputStrLNoPred then
            begin
            InputStrL[i-count]:= InputStrL[i] - count;
            InputStrL[i]:= InputStrLNoPred;
            end;
        end;

    SetLine(InputStr, InputStr.s, true);
end;

// returns count of removed bytes
function DelCharFromInputStr(idx: integer): integer;
var btw: byte;
begin
    // note: idx is always at last byte of utf8 chars. cuz relevant for InputStrL

    if (Length(InputStr.s) < 1) or (idx < 1) or (idx > Length(InputStr.s)) then
        exit(0);

    btw:= byte(idx) - InputStrL[idx];

    DelCharFromInputStr:= btw;

    DelBytesFromInputStrBack(idx, btw);
end;

// unchecked
procedure DoCursorStepForward();
begin
    // go to end of next utf8-char
    repeat
        inc(cursorPos);
    until InputStrL[cursorPos] <> InputStrLNoPred;
end;

procedure DeleteSelected();
begin
    if (selectedPos >= 0) and (cursorPos <> selectedPos) then
        begin
        DelBytesFromInputStrBack(max(cursorPos, selectedPos), abs(selectedPos-cursorPos));
        cursorPos:= min(cursorPos, selectedPos);
        ResetSelection();
        end;
end;

procedure HandleSelection(enabled: boolean);
begin
if enabled then
    begin
    if selectedPos < 0 then
        selectedPos:= cursorPos;
    end
else
    ResetSelection();
end;

type TCharSkip = ( none, wspace, numalpha, special );

function GetInputCharSkipClass(index: LongInt): TCharSkip;
var  c: char;
begin
    // multi-byte chars counts as letter
    if (index > 1) and (InputStrL[index] <> index - 1) then
        exit(numalpha);

    c:= InputStr.s[index];

    // non-ascii counts as letter
    if c > #127 then
        exit(numalpha);

    // low-ascii whitespaces and DEL
    if (c < #33) or (c = #127) then
        exit(wspace);

    // low-ascii special chars
    if c < #48 then
        exit(special);

    // digits
    if c < #58 then
        exit(numalpha);

    // make c upper-case
    if c > #96 then
        c:= char(byte(c) - 32);

    // letters
    if (c > #64) and (c < #90) then
        exit(numalpha);

    // remaining ascii are special chars
    exit(special);
end;

// skip from word to word, similar to Qt
procedure SkipInputChars(skip: TCharSkip; backwards: boolean);
begin
if backwards then
    begin
    // skip trailing whitespace, similar to Qt
    while (skip = wspace) and (cursorPos > 0) do
        begin
        skip:= GetInputCharSkipClass(cursorPos);
        if skip = wspace then
            cursorPos:= InputStrL[cursorPos];
        end;
    // skip same-type chars
    while (cursorPos > 0) and (GetInputCharSkipClass(cursorPos) = skip) do
        cursorPos:= InputStrL[cursorPos];
    end
else
    begin
    // skip same-type chars
    while cursorPos < Length(InputStr.s) do
        begin
        DoCursorStepForward();
        if (GetInputCharSkipClass(cursorPos) <> skip) then
            begin
            // go back 1 char
            cursorPos:= InputStrL[cursorPos];
            break;
            end;
        end;
    // skip trailing whitespace, similar to Qt
    while cursorPos < Length(InputStr.s) do
        begin
        DoCursorStepForward();
        if (GetInputCharSkipClass(cursorPos) <> wspace) then
            begin
            // go back 1 char
            cursorPos:= InputStrL[cursorPos];
            break;
            end;
        end;
    end;
end;

procedure KeyPressChat(Key, Sym: Longword; Modifier: Word);
const firstByteMark: array[0..3] of byte = (0, $C0, $E0, $F0);
var i, btw, index: integer;
    utf8: shortstring;
    action, selMode, ctrl: boolean;
    skip: TCharSkip;
begin
    LastKeyPressTick:= RealTicks;
    action:= true;

    selMode:= (modifier and (KMOD_LSHIFT or KMOD_RSHIFT)) <> 0;
    ctrl:= (modifier and (KMOD_LCTRL or KMOD_RCTRL)) <> 0;
    skip:= none;

    case Sym of
        SDLK_BACKSPACE:
            begin
            if selectedPos < 0 then
                begin
                if ctrl then
                    skip:= GetInputCharSkipClass(cursorPos);

                // remove char before cursor
                dec(cursorPos, DelCharFromInputStr(cursorPos));

                // delete more if ctrl is held
                if ctrl and (selectedPos < 0) then
                    begin
                    HandleSelection(true);
                    SkipInputChars(skip, true);
                    DeleteSelected();
                    end;
                end
            else
                DeleteSelected();
            UpdateCursorCoords();
            end;
        SDLK_DELETE:
            begin
            if selectedPos < 0 then
                begin
                // remove char after cursor
                if cursorPos < Length(InputStr.s) then
                    begin
                    DoCursorStepForward();
                    if ctrl then
                        skip:= GetInputCharSkipClass(cursorPos);

                    // delete char
                    dec(cursorPos, DelCharFromInputStr(cursorPos));

                    // delete more if ctrl is held
                    if ctrl and (cursorPos < Length(InputStr.s)) then
                        begin
                        HandleSelection(true);
                        SkipInputChars(skip, false);
                        DeleteSelected();
                        end;
                    end;
                end
            else
                DeleteSelected();

            UpdateCursorCoords();
            end;
        SDLK_ESCAPE:
            begin
            if Length(InputStr.s) > 0 then
                begin
                SetLine(InputStr, '', true);
                FillChar(InputStrL, sizeof(InputStrL), InputStrLNoPred);
                ResetCursor();
                end
            else CleanupInput
            end;
        SDLK_RETURN, SDLK_KP_ENTER:
            begin
            if Length(InputStr.s) > 0 then
                begin
                AcceptChatString(InputStr.s);
                SetLine(InputStr, '', false);
                FillChar(InputStrL, sizeof(InputStrL), InputStrLNoPred);
                ResetCursor();
                end;
            CleanupInput
            end;
        SDLK_UP, SDLK_DOWN:
            begin
            if (Sym = SDLK_UP) and (history < localLastStr) then inc(history);
            if (Sym = SDLK_DOWN) and (history > 0) then dec(history);
            index:= localLastStr - history + 1;
            if (index > localLastStr) then
                begin
                SetLine(InputStr, '', true);
                FillChar(InputStrL, sizeof(InputStrL), InputStrLNoPred);
                end
            else
                begin
                SetLine(InputStr, LocalStrs[index], true);
                InputStrL:= LocalStrsL[index];
                end;
            cursorPos:= Length(InputStr.s);
            ResetSelection();
            UpdateCursorCoords();
            end;
        SDLK_HOME:
            begin
            if cursorPos > 0 then
                begin
                HandleSelection(selMode);
                cursorPos:= 0;
                end
            else if (not selMode) then
                ResetSelection();

            UpdateCursorCoords();
            end;
        SDLK_END:
            begin
            i:= Length(InputStr.s);
            if cursorPos < i then
                begin
                HandleSelection(selMode);
                cursorPos:= i;
                end
            else if (not selMode) then
                ResetSelection();

            UpdateCursorCoords();
            end;
        SDLK_LEFT:
            begin
            if cursorPos > 0 then
                begin

                if ctrl then
                    skip:= GetInputCharSkipClass(cursorPos);

                if selMode or (selectedPos < 0) then
                    begin
                    HandleSelection(selMode);
                    // go to end of previous utf8-char
                    cursorPos:= InputStrL[cursorPos];
                    end
                else // if we're leaving selection mode, jump to its left end
                    begin
                    cursorPos:= min(cursorPos, selectedPos);
                    ResetSelection();
                    end;

                if ctrl then
                    SkipInputChars(skip, true);

                end
            else if (not selMode) then
                ResetSelection();

            UpdateCursorCoords();
            end;
        SDLK_RIGHT:
            begin
            if cursorPos < Length(InputStr.s) then
                begin

                if selMode or (selectedPos < 0) then
                    begin
                    HandleSelection(selMode);
                    DoCursorStepForward();
                    end
                else // if we're leaving selection mode, jump to its right end
                    begin
                    cursorPos:= max(cursorPos, selectedPos);
                    ResetSelection();
                    end;

                if ctrl then
                    SkipInputChars(GetInputCharSkipClass(cursorPos), false);

                end
            else if (not selMode) then
                ResetSelection();

            UpdateCursorCoords();
            end;
        SDLK_PAGEUP, SDLK_PAGEDOWN:
            begin
            // ignore me!!!
            end;
        SDLK_a:
            begin
            // select all
            if ctrl then
                begin
                ResetSelection();
                cursorPos:= 0;
                HandleSelection(true);
                cursorPos:= Length(InputStr.s);
                UpdateCursorCoords();
                end
            else
                action:= false;
            end;
        else
            action:= false;
        end;
    if not action and (Key <> 0) then
        begin
        DeleteSelected();

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

        if Length(InputStr.s) + btw > 240 then
            exit;

        // if we insert rather than append, shift info in InputStrL accordingly
        if cursorPos < Length(InputStr.s) then
            begin
            for i:= Length(InputStr.s) downto cursorPos + 1 do
                begin
                if InputStrL[i] <> InputStrLNoPred then
                    begin
                    InputStrL[i+btw]:= InputStrL[i] + btw;
                    InputStrL[i]:= InputStrLNoPred;
                    end;
                end;
            end;

        InputStrL[cursorPos + btw]:= cursorPos;
        Insert(utf8, InputStr.s, cursorPos + 1);
        SetLine(InputStr, InputStr.s, true);

        cursorPos:= cursorPos + btw;
        UpdateCursorCoords();
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
        begin
        SetLine(InputStr, '/team ', true);
        // update InputStrL and cursor accordingly
        // this allows cursor-jumping over '/team ' as if it was a single char
        InputStrL[6]:= 0;
        cursorPos:= 6;
        UpdateCursorCoords();
        end;
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
    firstDraw:= true;

    InputLinePrefix:= UserNick + '> ';
    inputStr.s:= '';
    inputStr.Tex := nil;
    for i:= 0 to MaxStrIndex do
        Strs[i].Tex := nil;

    FillChar(InputStrL, sizeof(InputStrL), InputStrLNoPred);

    LastKeyPressTick:= 0;
    ResetCursor();
end;

procedure freeModule;
var i: ShortInt;
begin
    FreeAndNilTexture(InputStr.Tex);
    for i:= 0 to MaxStrIndex do
        FreeAndNilTexture(Strs[i].Tex);
end;

end.
