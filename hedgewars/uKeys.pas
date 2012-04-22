(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uKeys;
interface
uses SDLh, uTypes;

procedure initModule;
procedure freeModule;

function  KeyNameToCode(name: shortstring): word;
procedure ProcessKbd;
procedure ResetKbd;
procedure FreezeEnterKey;
procedure InitKbdKeyTable;

procedure SetBinds(var binds: TBinds);
procedure SetDefaultBinds;

procedure ControllerInit;
procedure ControllerClose;
procedure ControllerAxisEvent(joy, axis: Byte; value: Integer);
procedure ControllerHatEvent(joy, hat, value: Byte);
procedure ControllerButtonEvent(joy, button: Byte; pressed: Boolean);

{$IFDEF MOBILE}
procedure setTouchWidgetStates;
{$ENDIF}

implementation
uses uConsole, uCommands, uMisc, uVariables, uConsts, uUtils, uDebug;

var tkbd, tkbdn: TKeyboardState;
    KeyNames: array [0..cKeyMaxIndex] of string[15];

function KeyNameToCode(name: shortstring): word;
var code: Word;
begin
    code:= cKeyMaxIndex;
    while (code > 0) and (KeyNames[code] <> name) do dec(code);
    KeyNameToCode:= code;
end;


procedure ProcessKbd;
var  i, j, k: LongInt;
     s: shortstring;
     Trusted: boolean;
     pkbd: PByteArray;
begin
hideAmmoMenu:= false;
Trusted:= (CurrentTeam <> nil)
          and (not CurrentTeam^.ExtDriven)
          and (CurrentHedgehog^.BotLevel = 0);

// move cursor/camera
// TODO: Scale on screen dimensions and/or axis value (game controller)?
movecursor(5 * CursorMovementX, 5 * CursorMovementY);

pkbd:= SDL_GetKeyState(@j);
for i:= 1 to pred(j) do 
    tkbdn[i]:= pkbd^[i];

k:= SDL_GetMouseState(nil, nil);
// mouse buttons
{$IFDEF DARWIN}
tkbdn[SDL_SCANCODE_MOUSEL]:= ((k and 1) and not (tkbdn[306] or tkbdn[305]));
tkbdn[SDL_SCANCODE_MOUSER]:= ((k and 1) and (tkbdn[306] or tkbdn[305])) or (k and 4);
{$ELSE}
tkbdn[SDL_SCANCODE_MOUSEL]:= (k and 1);
tkbdn[SDL_SCANCODE_MOUSER]:= ((k shr 2) and 1);
{$ENDIF}
tkbdn[SDL_SCANCODE_MOUSEM]:= ((k shr 1) and 1);

// mouse wheels
tkbdn[SDL_SCANCODE_WHEELDOWN]:= ord(wheelDown);
tkbdn[SDL_SCANCODE_WHEELUP]:= ord(wheelUp);
wheelUp:= false;
wheelDown:= false;

{$IFDEF MOBILE}
setTouchWidgetStates();
{$ENDIF}

{$IFNDEF MOBILE}
// Controller(s)
k:= SDL_SCANCODE_CONTROLLER; // should we test k for hitting the limit? sounds rather unlikely to ever reach it
for j:= 0 to Pred(ControllerNumControllers) do
    begin
    for i:= 0 to Pred(ControllerNumAxes[j]) do
        begin
        if ControllerAxes[j][i] > 20000 then
            tkbdn[k + 0]:= 1
        else
            tkbdn[k + 0]:= 0;
        if ControllerAxes[j][i] < -20000 then
            tkbdn[k + 1]:= 1
        else
            tkbdn[k + 1]:= 0;
        inc(k, 2);
        end;
    for i:= 0 to Pred(ControllerNumHats[j]) do
        begin
        tkbdn[k + 0]:= ControllerHats[j][i] and SDL_HAT_UP;
        tkbdn[k + 1]:= ControllerHats[j][i] and SDL_HAT_RIGHT;
        tkbdn[k + 2]:= ControllerHats[j][i] and SDL_HAT_DOWN;
        tkbdn[k + 3]:= ControllerHats[j][i] and SDL_HAT_LEFT;
        inc(k, 4);
        end;
    for i:= 0 to Pred(ControllerNumButtons[j]) do
        begin
        tkbdn[k]:= ControllerButtons[j][i];
        inc(k, 1);
        end;
    end;
{$ENDIF}

// ctrl/cmd + q to close engine and frontend
{$IFDEF DARWIN}
    if ((tkbdn[SDL_SCANCODE_LGUI] = 1) or (tkbdn[SDL_SCANCODE_RGUI] = 1)) then
{$ELSE}
    if ((tkbdn[SDL_SCANCODE_LCTRL] = 1) or (tkbdn[SDL_SCANCODE_RCTRL] = 1)) then
{$ENDIF}
    begin
        if tkbdn[SDL_SCANCODE_Q] = 1 then ParseCommand ('halt', true)
    end;

// now process strokes
for i:= 0 to cKeyMaxIndex do
if CurrentBinds[i][0] <> #0 then
    begin
    if (i > 3) and (tkbdn[i] <> 0) and not ((CurrentBinds[i] = 'put') or (CurrentBinds[i] = 'ammomenu') or (CurrentBinds[i] = '+cur_u') or (CurrentBinds[i] = '+cur_d') or (CurrentBinds[i] = '+cur_l') or (CurrentBinds[i] = '+cur_r')) then hideAmmoMenu:= true;
    if (tkbd[i] = 0) and (tkbdn[i] <> 0) then
        begin
        ParseCommand(CurrentBinds[i], Trusted);
        if (CurrentTeam <> nil) and (not CurrentTeam^.ExtDriven) and (ReadyTimeLeft > 1) then
            ParseCommand('gencmd R', true)
        end
    else if (CurrentBinds[i][1] = '+') and (tkbdn[i] = 0) and (tkbd[i] <> 0) then
        begin
        s:= CurrentBinds[i];
        s[1]:= '-';
        ParseCommand(s, Trusted);
        if (CurrentTeam <> nil) and (not CurrentTeam^.ExtDriven) and (ReadyTimeLeft > 1) then
            ParseCommand('gencmd R', true)
        end;
    tkbd[i]:= tkbdn[i]
    end
end;

procedure ResetKbd;
var j, k, t: LongInt;
    i: LongInt;
    pkbd: PByteArray;
begin

k:= SDL_GetMouseState(nil, nil);
pkbd:=SDL_GetKeyState(@j);

TryDo(j < cKeyMaxIndex, 'SDL keys number is more than expected (' + IntToStr(j) + ')', true);

for i:= 1 to pred(j) do
    tkbdn[i]:= pkbd^[i];

// mouse buttons
{$IFDEF DARWIN}
tkbdn[SDL_SCANCODE_MOUSEL]:= ((k and 1) and not (tkbdn[306] or tkbdn[305]));
tkbdn[SDL_SCANCODE_MOUSER]:= ((k and 1) and (tkbdn[306] or tkbdn[305])) or (k and 4);
{$ELSE}
tkbdn[SDL_SCANCODE_MOUSEL]:= (k and 1);
tkbdn[SDL_SCANCODE_MOUSER]:= ((k shr 2) and 1);
{$ENDIF}
tkbdn[SDL_SCANCODE_MOUSEM]:= ((k shr 1) and 1);

// mouse wheels
tkbdn[SDL_SCANCODE_WHEELDOWN]:= ord(wheelDown);
tkbdn[SDL_SCANCODE_WHEELUP]:= ord(wheelUp);
wheelUp:= false;
wheelDown:= false;

{$IFDEF MOBILE}
setTouchWidgetStates();
{$ENDIF}

{$IFNDEF MOBILE}
// Controller(s)
k:= SDL_SCANCODE_CONTROLLER; // should we test k for hitting the limit? sounds rather unlikely to ever reach it
for j:= 0 to Pred(ControllerNumControllers) do
    begin
    for i:= 0 to Pred(ControllerNumAxes[j]) do
        begin
        if ControllerAxes[j][i] > 20000 then
            tkbdn[k + 0]:= 1
        else
            tkbdn[k + 0]:= 0;
        if ControllerAxes[j][i] < -20000 then
            tkbdn[k + 1]:= 1
        else
            tkbdn[k + 1]:= 0;
        inc(k, 2);
        end;
    for i:= 0 to Pred(ControllerNumHats[j]) do
        begin
        tkbdn[k + 0]:= ControllerHats[j][i] and SDL_HAT_UP;
        tkbdn[k + 1]:= ControllerHats[j][i] and SDL_HAT_RIGHT;
        tkbdn[k + 2]:= ControllerHats[j][i] and SDL_HAT_DOWN;
        tkbdn[k + 3]:= ControllerHats[j][i] and SDL_HAT_LEFT;
        inc(k, 4);
        end;
    for i:= 0 to Pred(ControllerNumButtons[j]) do
        begin
        tkbdn[k]:= ControllerButtons[j][i];
        inc(k, 1);
        end;
    end;
{$ENDIF}

// what is this final loop for?
for t:= 0 to cKeyMaxIndex do
    tkbd[t]:= tkbdn[t]
end;

procedure InitKbdKeyTable;
var i, j, k, t: LongInt;
    s: string[15];
begin
for i:= 0 to cKeyMaxIndex do
    begin
    s:= shortstring(sdl_getkeyname(i));
    //WriteToConsole(IntToStr(i) + ': ' + s);
    if s = 'unknown key' then KeyNames[i]:= ''
    else 
        begin
        for t:= 1 to Length(s) do
            if s[t] = ' ' then
                s[t]:= '_';
        KeyNames[i]:= s
        end;
    end;

KeyNames[SDL_SCANCODE_MOUSEL]:= 'mousel';
KeyNames[SDL_SCANCODE_MOUSEM]:= 'mousem';
KeyNames[SDL_SCANCODE_MOUSER]:= 'mouser';
KeyNames[SDL_SCANCODE_WHEELUP]:= 'wheelup';
KeyNames[SDL_SCANCODE_WHEELDOWN]:= 'wheeldown';
//for i:= 0 to cKeyMaxIndex do writeln(stdout,IntToStr(i) + ': ' + KeyNames[i]);

k:= SDL_SCANCODE_CONTROLLER;
// Controller(s)
for j:= 0 to Pred(ControllerNumControllers) do
    begin
    for i:= 0 to Pred(ControllerNumAxes[j]) do
        begin
        keynames[k + 0]:= 'j' + IntToStr(j) + 'a' + IntToStr(i) + 'u';
        keynames[k + 1]:= 'j' + IntToStr(j) + 'a' + IntToStr(i) + 'd';
        inc(k, 2);
        end;
    for i:= 0 to Pred(ControllerNumHats[j]) do
        begin
        keynames[k + 0]:= 'j' + IntToStr(j) + 'h' + IntToStr(i) + 'u';
        keynames[k + 1]:= 'j' + IntToStr(j) + 'h' + IntToStr(i) + 'r';
        keynames[k + 2]:= 'j' + IntToStr(j) + 'h' + IntToStr(i) + 'd';
        keynames[k + 3]:= 'j' + IntToStr(j) + 'h' + IntToStr(i) + 'l';
        inc(k, 4);
        end;
    for i:= 0 to Pred(ControllerNumButtons[j]) do
        begin
        keynames[k]:= 'j' + IntToStr(j) + 'b' + IntToStr(i);
        inc(k, 1);
        end;
    end;

DefaultBinds[SDL_SCANCODE_ESCAPE]:= 'quit';
DefaultBinds[SDL_SCANCODE_GRAVE]:= 'history';
DefaultBinds[127]:= 'rotmask';

//numpad
//DefaultBinds[265]:= '+volup';
//DefaultBinds[256]:= '+voldown';

DefaultBinds[SDL_SCANCODE_0]:= '+volup';
DefaultBinds[SDL_SCANCODE_9]:= '+voldown';
DefaultBinds[SDL_SCANCODE_C]:= 'capture';
DefaultBinds[SDL_SCANCODE_H]:= 'findhh';
DefaultBinds[SDL_SCANCODE_P]:= 'pause';
DefaultBinds[SDL_SCANCODE_S]:= '+speedup';
DefaultBinds[SDL_SCANCODE_T]:= 'chat';
DefaultBinds[SDL_SCANCODE_Y]:= 'confirm';

DefaultBinds[SDL_SCANCODE_MOUSEM]:= 'zoomreset';
DefaultBinds[SDL_SCANCODE_WHEELUP]:= 'zoomout';
DefaultBinds[SDL_SCANCODE_WHEELDOWN]:= 'zoomin';

DefaultBinds[SDL_SCANCODE_F12]:= 'fullscr';


DefaultBinds[SDL_SCANCODE_MOUSEL]:= '/put';
DefaultBinds[SDL_SCANCODE_MOUSER]:= 'ammomenu';
DefaultBinds[SDL_SCANCODE_BACKSPACE]:= 'hjump';
DefaultBinds[SDL_SCANCODE_TAB]:= 'switch';
DefaultBinds[SDL_SCANCODE_RETURN]:= 'ljump';
DefaultBinds[SDL_SCANCODE_SPACE]:= '+attack';

DefaultBinds[SDL_SCANCODE_UP]:= '+up';
DefaultBinds[SDL_SCANCODE_DOWN]:= '+down';
DefaultBinds[SDL_SCANCODE_LEFT]:= '+left';
DefaultBinds[SDL_SCANCODE_RIGHT]:= '+right';
DefaultBinds[SDL_SCANCODE_LSHIFT]:= '+precise';

DefaultBinds[SDL_SCANCODE_F1]:= 'slot 1';
DefaultBinds[SDL_SCANCODE_F2]:= 'slot 2';
DefaultBinds[SDL_SCANCODE_F3]:= 'slot 3';
DefaultBinds[SDL_SCANCODE_F4]:= 'slot 4';
DefaultBinds[SDL_SCANCODE_F5]:= 'slot 5';
DefaultBinds[SDL_SCANCODE_F6]:= 'slot 6';
DefaultBinds[SDL_SCANCODE_F7]:= 'slot 7';
DefaultBinds[SDL_SCANCODE_F8]:= 'slot 8';
DefaultBinds[SDL_SCANCODE_F9]:= 'slot 9';
DefaultBinds[SDL_SCANCODE_F10]:= 'slot 10';

DefaultBinds[SDL_SCANCODE_1]:= 'timer 1';
DefaultBinds[SDL_SCANCODE_2]:= 'timer 2';
DefaultBinds[SDL_SCANCODE_3]:= 'timer 3';
DefaultBinds[SDL_SCANCODE_4]:= 'timer 4';
DefaultBinds[SDL_SCANCODE_5]:= 'timer 5';

SetDefaultBinds();
end;

procedure SetBinds(var binds: TBinds);
begin
{$IFDEF MOBILE}
    binds:= binds; // avoid hint
    CurrentBinds:= DefaultBinds;
{$ELSE}
    CurrentBinds:= binds;
{$ENDIF}
end;

procedure SetDefaultBinds;
begin
    CurrentBinds:= DefaultBinds;
end;

{$IFDEF MOBILE}
procedure setTouchWidgetStates;
begin
    tkbdn[SDL_SCANCODE_MOUSEL]:= tkbdn[SDL_SCANCODE_MOUSEL] or ord(leftClick);
    tkbdn[SDL_SCANCODE_MOUSEM]:= tkbdn[SDL_SCANCODE_MOUSEM] or ord(middleClick);
    tkbdn[SDL_SCANCODE_MOUSER]:= tkbdn[SDL_SCANCODE_MOUSER] or ord(rightClick);

    tkbdn[SDL_SCANCODE_UP]    := tkbdn[SDL_SCANCODE_UP] or ord(upKey);
    tkbdn[SDL_SCANCODE_DOWN]  := tkbdn[SDL_SCANCODE_DOWN] or ord(downKey);
    tkbdn[SDL_SCANCODE_LEFT]  := tkbdn[SDL_SCANCODE_LEFT] or ord(leftKey);
    tkbdn[SDL_SCANCODE_RIGHT] := tkbdn[SDL_SCANCODE_RIGHT] or ord(rightKey);
    tkbdn[SDL_SCANCODE_LSHIFT]:= tkbdn[SDL_SCANCODE_LSHIFT] or ord(preciseKey);

    tkbdn[SDL_SCANCODE_BACKSPACE]:= tkbdn[SDL_SCANCODE_BACKSPACE] or ord(backspaceKey);
    tkbdn[SDL_SCANCODE_TAB]:= tkbdn[SDL_SCANCODE_TAB] or ord(tabKey);
    tkbdn[SDL_SCANCODE_RETURN]:= ord(enterKey);
    tkbdn[SDL_SCANCODE_SPACE]:= ord(spaceKey);

    tkbdn[SDL_SCANCODE_T]:= tkbdn[SDL_SCANCODE_T] or ord(chatAction);
    tkbdn[SDL_SCANCODE_PAUSE]:= ord(pauseAction);

    // set to false the keys that only need one stoke
    leftClick:= false;
    middleClick:= false;
    rightClick:= false;

    tabKey:= false;
    enterKey:= false;
    backspaceKey:= false;

    chatAction:= false;
    pauseAction:= false;
end;
{$ENDIF}

procedure FreezeEnterKey;
begin
    tkbd[3]:= 1;
    tkbd[13]:= 1;
    tkbd[27]:= 1;
    tkbd[271]:= 1;
end;

var Controller: array [0..5] of PSDL_Joystick;

procedure ControllerInit;
var i, j: Integer;
begin
ControllerEnabled:= 0;
{$IFDEF MOBILE}
exit; // joystick subsystem disabled on iPhone
{$ENDIF}

SDL_InitSubSystem(SDL_INIT_JOYSTICK);
ControllerNumControllers:= SDL_NumJoysticks();

if ControllerNumControllers > 6 then
    ControllerNumControllers:= 6;

WriteLnToConsole('Number of game controllers: ' + IntToStr(ControllerNumControllers));

if ControllerNumControllers > 0 then
    begin
    for j:= 0 to pred(ControllerNumControllers) do
        begin
        WriteLnToConsole('Using game controller: ' + SDL_JoystickName(j));
        Controller[j]:= SDL_JoystickOpen(j);
        if Controller[j] = nil then
            WriteLnToConsole('* Failed to open game controller!')
        else
            begin
            ControllerNumAxes[j]:= SDL_JoystickNumAxes(Controller[j]);
            //ControllerNumBalls[j]:= SDL_JoystickNumBalls(Controller[j]);
            ControllerNumHats[j]:= SDL_JoystickNumHats(Controller[j]);
            ControllerNumButtons[j]:= SDL_JoystickNumButtons(Controller[j]);
            WriteLnToConsole('* Number of axes: ' + IntToStr(ControllerNumAxes[j]));
            //WriteLnToConsole('* Number of balls: ' + IntToStr(ControllerNumBalls[j]));
            WriteLnToConsole('* Number of hats: ' + IntToStr(ControllerNumHats[j]));
            WriteLnToConsole('* Number of buttons: ' + IntToStr(ControllerNumButtons[j]));
            ControllerEnabled:= 1;

            if ControllerNumAxes[j] > 20 then
                ControllerNumAxes[j]:= 20;
            //if ControllerNumBalls[j] > 20 then ControllerNumBalls[j]:= 20;
            
            if ControllerNumHats[j] > 20 then
                ControllerNumHats[j]:= 20;
                
            if ControllerNumButtons[j] > 20 then
                ControllerNumButtons[j]:= 20;

            // reset all buttons/axes
            for i:= 0 to pred(ControllerNumAxes[j]) do
                ControllerAxes[j][i]:= 0;
            (*for i:= 0 to pred(ControllerNumBalls[j]) do
                begin
                ControllerBalls[j][i][0]:= 0;
                ControllerBalls[j][i][1]:= 0;
                end;*)
            for i:= 0 to pred(ControllerNumHats[j]) do
                ControllerHats[j][i]:= SDL_HAT_CENTERED;
            for i:= 0 to pred(ControllerNumButtons[j]) do
                ControllerButtons[j][i]:= 0;
            end;
        end;
    // enable event generation/controller updating
    SDL_JoystickEventState(1);
    end
else
    WriteLnToConsole('Not using any game controller');
end;

procedure ControllerClose;
var j: Integer;
begin
    if ControllerEnabled > 0 then
        for j:= 0 to pred(ControllerNumControllers) do
            SDL_JoystickClose(Controller[j]);
end;

procedure ControllerAxisEvent(joy, axis: Byte; value: Integer);
begin
    ControllerAxes[joy][axis]:= value;
end;

procedure ControllerHatEvent(joy, hat, value: Byte);
begin
    ControllerHats[joy][hat]:= value;
end;

procedure ControllerButtonEvent(joy, button: Byte; pressed: Boolean);
begin
    if pressed then
        ControllerButtons[joy][button]:= 1
    else
        ControllerButtons[joy][button]:= 0;
end;

procedure initModule;
begin
    wheelUp:= false;
    wheelDown:= false;
{$IFDEF HWLIBRARY}
    // this function is called by HW_allKeysUp so be careful

    // mouse emulation
    leftClick:= false;
    middleClick:= false;
    rightClick:= false;

    // arrow key emulation
    upKey:= false;
    downKey:= false;
    rightKey:= false;
    leftKey:= false;
    preciseKey:= false;

    // action key emulation
    backspaceKey:= false;
    spaceKey:= false;
    enterKey:= false;
    tabKey:= false;

    // other key emulation
    chatAction:= false;
    pauseAction:= false;
{$ENDIF}
end;

procedure freeModule;
begin

end;

end.
