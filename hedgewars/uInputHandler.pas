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

unit uInputHandler;
interface
uses SDLh, uTypes;

procedure initModule;
procedure freeModule;

function  KeyNameToCode(name: shortstring): word;
procedure ProcessMouse(event: TSDL_MouseButtonEvent; ButtonDown: boolean);
procedure ProcessKey(event: TSDL_KeyboardEvent); inline;
procedure ProcessKey(code: LongInt; KeyDown: boolean);

procedure ResetKbd;
procedure FreezeEnterKey;
procedure InitKbdKeyTable;

procedure SetBinds(var binds: TBinds);
procedure SetDefaultBinds;

procedure ControllerInit;
procedure ControllerAxisEvent(joy, axis: Byte; value: Integer);
procedure ControllerHatEvent(joy, hat, value: Byte);
procedure ControllerButtonEvent(joy, button: Byte; pressed: Boolean);

implementation
uses uConsole, uCommands, uMisc, uVariables, uConsts, uUtils, uDebug;

var tkbd: array[0..cKeyMaxIndex] of boolean;
    quitKeyCode: Byte;
    KeyNames: array [0..cKeyMaxIndex] of string[15];
    CurrentBinds: TBinds;

function KeyNameToCode(name: shortstring): word;
var code: Word;
begin
    name:= LowerCase(name);
    code:= cKeyMaxIndex;
    while (code > 0) and (KeyNames[code] <> name) do dec(code);
    KeyNameToCode:= code;
end;

procedure ProcessKey(code: LongInt; KeyDown: boolean);
var
    Trusted: boolean;
    s      : string;
begin

if not(tkbd[code] xor KeyDown) then exit;
tkbd[code]:= KeyDown;


hideAmmoMenu:= false;
Trusted:= (CurrentTeam <> nil)
          and (not CurrentTeam^.ExtDriven)
          and (CurrentHedgehog^.BotLevel = 0);



// ctrl/cmd + q to close engine and frontend
if(KeyDown and (code = quitKeyCode)) then
    begin
{$IFDEF DARWIN}
    if tkbd[KeyNameToCode('left_meta')] or tkbd[KeyNameToCode('right_meta')] then
{$ELSE}
    if tkbd[KeyNameToCode('left_ctrl')] or tkbd[KeyNameToCode('right_ctrl')] then
{$ENDIF}
        ParseCommand('halt', true);    
    end;

if CurrentBinds[code][0] <> #0 then
    begin
    if (code > 3) and KeyDown and not ((CurrentBinds[code] = 'put') or (CurrentBinds[code] = 'ammomenu') or (CurrentBinds[code] = '+cur_u') or (CurrentBinds[code] = '+cur_d') or (CurrentBinds[code] = '+cur_l') or (CurrentBinds[code] = '+cur_r')) then hideAmmoMenu:= true;

    if KeyDown then
        begin
        ParseCommand(CurrentBinds[code], Trusted);
        if (CurrentTeam <> nil) and (not CurrentTeam^.ExtDriven) and (ReadyTimeLeft > 1) then
            ParseCommand('gencmd R', true)
        end
    else if (CurrentBinds[code][1] = '+') then
        begin
        s:= CurrentBinds[code];
        s[1]:= '-';
        ParseCommand(s, Trusted);
        if (CurrentTeam <> nil) and (not CurrentTeam^.ExtDriven) and (ReadyTimeLeft > 1) then
            ParseCommand('gencmd R', true)
        end;
    end
end;

procedure ProcessKey(event: TSDL_KeyboardEvent); inline;
begin
    ProcessKey(event.keysym.sym, event.type_ = SDL_KEYDOWN);
end;

procedure ProcessMouse(event: TSDL_MouseButtonEvent; ButtonDown: boolean);
begin
case event.button of
    SDL_BUTTON_LEFT:
        ProcessKey(KeyNameToCode('mousel'), ButtonDown);
    SDL_BUTTON_MIDDLE:
        ProcessKey(KeyNameToCode('mousem'), ButtonDown);
    SDL_BUTTON_RIGHT:
        ProcessKey(KeyNameToCode('mouser'), ButtonDown);
    SDL_BUTTON_WHEELDOWN:
        ProcessKey(KeyNameToCode('wheeldown'), ButtonDown);
    SDL_BUTTON_WHEELUP:
        ProcessKey(KeyNameToCode('wheelup'), ButtonDown);
    end;
end;

procedure ResetKbd;
var t: LongInt;
begin
for t:= 0 to cKeyMaxIndex do
    if tkbd[t] then
        ProcessKey(t, False);
end;

procedure InitKbdKeyTable;
var i, j, k, t: LongInt;
    s: string[15];
begin
//TODO in sdl13 this overrides some values (A and B) change indices to some other values at the back perhaps?
KeyNames[1]:= 'mousel';
KeyNames[2]:= 'mousem';
KeyNames[3]:= 'mouser';
KeyNames[4]:= 'wheelup';
KeyNames[5]:= 'wheeldown';

for i:= 6 to cKeyMaxIndex do
    begin
    s:= shortstring(sdl_getkeyname(i));
    //WriteLnToConsole(IntToStr(i) + ': ' + s + ' ' + IntToStr(cKeyMaxIndex));
    if s = 'unknown key' then KeyNames[i]:= ''
    else 
        begin
        for t:= 1 to Length(s) do
            if s[t] = ' ' then
                s[t]:= '_';
        KeyNames[i]:= LowerCase(s)
        end;
    end;

quitKeyCode:= KeyNameToCode(_S'q');

// get the size of keyboard array
SDL_GetKeyState(@k);

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

DefaultBinds[KeyNameToCode('escape')]:= 'quit';
DefaultBinds[KeyNameToCode('grave')]:= 'history';
DefaultBinds[KeyNameToCode('delete')]:= 'rotmask';

//numpad
//DefaultBinds[265]:= '+volup';
//DefaultBinds[256]:= '+voldown';

DefaultBinds[KeyNameToCode(_S'0')]:= '+volup';
DefaultBinds[KeyNameToCode(_S'9')]:= '+voldown';
DefaultBinds[KeyNameToCode(_S'c')]:= 'capture';
DefaultBinds[KeyNameToCode(_S'h')]:= 'findhh';
DefaultBinds[KeyNameToCode(_S'p')]:= 'pause';
DefaultBinds[KeyNameToCode(_S's')]:= '+speedup';
DefaultBinds[KeyNameToCode(_S't')]:= 'chat';
DefaultBinds[KeyNameToCode(_S'y')]:= 'confirm';

DefaultBinds[KeyNameToCode('mousem')]:= 'zoomreset';
DefaultBinds[KeyNameToCode('wheelup')]:= 'zoomin';
DefaultBinds[KeyNameToCode('wheeldown')]:= 'zoomout';

DefaultBinds[KeyNameToCode('f12')]:= 'fullscr';


DefaultBinds[KeyNameToCode('mousel')]:= '/put';
DefaultBinds[KeyNameToCode('mouser')]:= 'ammomenu';
DefaultBinds[KeyNameToCode('backspace')]:= 'hjump';
DefaultBinds[KeyNameToCode('tab')]:= 'switch';
DefaultBinds[KeyNameToCode('return')]:= 'ljump';
DefaultBinds[KeyNameToCode('space')]:= '+attack';
DefaultBinds[KeyNameToCode('up')]:= '+up';
DefaultBinds[KeyNameToCode('down')]:= '+down';
DefaultBinds[KeyNameToCode('left')]:= '+left';
DefaultBinds[KeyNameToCode('right')]:= '+right';
DefaultBinds[KeyNameToCode('left_shift')]:= '+precise';


DefaultBinds[KeyNameToCode('j0a0u')]:= '+left';
DefaultBinds[KeyNameToCode('j0a0d')]:= '+right';
DefaultBinds[KeyNameToCode('j0a1u')]:= '+up';
DefaultBinds[KeyNameToCode('j0a1d')]:= '+down';
for i:= 1 to 10 do DefaultBinds[KeyNameToCode('f'+IntToStr(i))]:= 'slot '+IntToStr(i);
for i:= 1 to 5  do DefaultBinds[KeyNameToCode(IntToStr(i))]:= 'timer '+IntToStr(i);

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

procedure FreezeEnterKey;
begin
    tkbd[3]:= True;
    tkbd[13]:= True;
    tkbd[27]:= True;
    tkbd[271]:= True;
end;

var Controller: array [0..5] of PSDL_Joystick;

procedure ControllerInit;
var i, j: Integer;
begin
ControllerEnabled:= 0;
{$IFDEF IPHONE}
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

procedure ControllerAxisEvent(joy, axis: Byte; value: Integer);
var
    k: LongInt;
begin
    SDL_GetKeyState(@k);
    k:= k + joy * (ControllerNumAxes[joy]*2 + ControllerNumHats[joy]*4 + ControllerNumButtons[joy]*2);
    ProcessKey(k +  axis*2, value > 20000);
    ProcessKey(k + (axis*2)+1, value < -20000);
end;

procedure ControllerHatEvent(joy, hat, value: Byte);
var
    k: LongInt;
begin
    SDL_GetKeyState(@k);
    k:= k + joy * (ControllerNumAxes[joy]*2 + ControllerNumHats[joy]*4 + ControllerNumButtons[joy]*2);
    ProcessKey(k +  ControllerNumAxes[joy]*2 + hat*4 + 0, (value and SDL_HAT_UP)   <> 0);
    ProcessKey(k +  ControllerNumAxes[joy]*2 + hat*4 + 1, (value and SDL_HAT_RIGHT)<> 0);
    ProcessKey(k +  ControllerNumAxes[joy]*2 + hat*4 + 2, (value and SDL_HAT_DOWN) <> 0);
    ProcessKey(k +  ControllerNumAxes[joy]*2 + hat*4 + 3, (value and SDL_HAT_LEFT) <> 0);
end;

procedure ControllerButtonEvent(joy, button: Byte; pressed: Boolean);
var
    k: LongInt;
begin
    SDL_GetKeyState(@k);
    k:= k + joy * (ControllerNumAxes[joy]*2 + ControllerNumHats[joy]*4 + ControllerNumButtons[joy]*2);
    ProcessKey(k +  ControllerNumAxes[joy]*2 + ControllerNumHats[joy]*4 + button, pressed);
end;

procedure initModule;
begin
    wheelUp:= false;
    wheelDown:= false;
end;

procedure freeModule;
var j: LongInt;
begin
    // close gamepad controllers
    if ControllerEnabled > 0 then
        for j:= 0 to pred(ControllerNumControllers) do
            SDL_JoystickClose(Controller[j]);
end;

end.
