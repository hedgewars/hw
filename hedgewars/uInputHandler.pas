(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uInputHandler;
interface
uses SDLh, uTypes;

procedure initModule;
procedure freeModule;

function  KeyNameToCode(name: shortstring): LongInt; inline;
function  KeyNameToCode(name: shortstring; Modifier: shortstring): LongInt;

function  KeyBindToCode(bind: shortstring): LongInt;
function  KeyBindToName(bind: shortstring): shortstring;
//procedure MaskModifier(var code: LongInt; modifier: LongWord);
procedure MaskModifier(Modifier: shortstring; var code: LongInt);
procedure ProcessMouse(event: TSDL_MouseButtonEvent; ButtonDown: boolean);
//procedure ProcessMouseWheel(x, y: LongInt);
procedure ProcessMouseWheel(y: LongInt);
procedure ProcessKey(event: TSDL_KeyboardEvent); inline;
procedure ProcessKey(code: LongInt; KeyDown: boolean);

procedure ResetKbd;
procedure ResetMouseWheel;
procedure FreezeEnterKey;
procedure InitKbdKeyTable;

procedure SetBinds(var binds: TBinds);
procedure SetDefaultBinds;
procedure chDefaultBind(var id: shortstring);
procedure loadBinds(cmd, s: shortstring);
procedure addBind(var binds: TBinds; var id: shortstring);

procedure ControllerInit;
procedure ControllerAxisEvent(joy, axis: Byte; value: Integer);
procedure ControllerHatEvent(joy, hat, value: Byte);
procedure ControllerButtonEvent(joy, button: Byte; pressed: Boolean);

implementation
uses uConsole, uCommands, uVariables, uConsts, uUtils, uDebug, uPhysFSLayer;

const
    LSHIFT = $0200;
    RSHIFT = $0400;
    LALT   = $0800;
    RALT   = $1000;
    LCTRL  = $2000;
    RCTRL  = $4000;

var tkbd: array[0..cKbdMaxIndex] of boolean;
    KeyNames: array [0..cKeyMaxIndex] of string[15];
    CurrentBinds: TBinds;
    ControllerNumControllers: Integer;
    ControllerEnabled: Integer;
    ControllerNumAxes: array[0..5] of Integer;
    //ControllerNumBalls: array[0..5] of Integer;
    ControllerNumHats: array[0..5] of Integer;
    ControllerNumButtons: array[0..5] of Integer;
    //ControllerAxes: array[0..5] of array[0..19] of Integer;
    //ControllerBalls: array[0..5] of array[0..19] of array[0..1] of Integer;
    //ControllerHats: array[0..5] of array[0..19] of Byte;
    //ControllerButtons: array[0..5] of array[0..19] of Byte;

function  KeyNameToCode(name: shortstring): LongInt; inline;
begin
    KeyNameToCode:= KeyNameToCode(name, '');
end;

function KeyNameToCode(name: shortstring; Modifier: shortstring): LongInt;
var code: LongInt;
begin
    name:= LowerCase(name);
    code:= 0;
    while (code <= cKeyMaxIndex) and (KeyNames[code] <> name) do inc(code);

    MaskModifier(Modifier, code);
    KeyNameToCode:= code;
end;

// Takes a control name (e.g. 'quit') and returns the corresponding key code,
// if it has been bound.
// Returns -1 if the control has not been bound.
function KeyBindToCode(bind: shortstring): LongInt;
var code, index: LongInt;
begin
    index:= 0;
    while (index <= High(CurrentBinds.binds)) and (CurrentBinds.binds[index] <> bind) do inc(index);
    if index > High(CurrentBinds.binds) then
        // Return error
        KeyBindToCode:= -1
    else begin
        code:= 0;
        while (code <= High(CurrentBinds.indices)) and (CurrentBinds.indices[code] <> index) do inc(code);
        checkFails(code <= High(CurrentBinds.indices), 'Inconsistency in key binding registry', True);
        KeyBindToCode:= code;
    end;
end;

// Takes a control name (e.g. 'quit') and returns the corresponding
// human-readable key name from SDL.
// FIXME: Does not work 100% for all keys yet, but at least it no
//        longer hardcodes any key name.
// TODO: Localize
function KeyBindToName(bind: shortstring): shortstring;
var code: LongInt;
    name: shortstring;
begin
    code:= KeyBindToCode(bind);
    if code = -1 then
        KeyBindToName:= trmsg[sidUnknownKey]
    else
        begin
        name:= SDL_GetKeyName(SDL_GetKeyFromScancode(code));
        if (name = 'Escape') then
            // Let's shorten the name “Escape” for the quit menu
            KeyBindToName:= 'Esc'
        else if (length(name) <> 0) then
            KeyBindToName:= name
        else
            begin
            WriteLnToConsole('Error: KeyBindToName('+bind+') failed to find SDL key name!');
            KeyBindToName:= trmsg[sidUnknownKey];
            end;
        end;
end;

(*
procedure MaskModifier(var code: LongInt; Modifier: LongWord);
begin
    if(Modifier and KMOD_LSHIFT) <> 0 then code:= code or LSHIFT;
    if(Modifier and KMOD_RSHIFT) <> 0 then code:= code or LSHIFT;
    if(Modifier and KMOD_LALT) <> 0 then code:= code or LALT;
    if(Modifier and KMOD_RALT) <> 0 then code:= code or LALT;
    if(Modifier and KMOD_LCTRL) <> 0 then code:= code or LCTRL;
    if(Modifier and KMOD_RCTRL) <> 0 then code:= code or LCTRL;
end;
*)
procedure MaskModifier(Modifier: shortstring; var code: LongInt);
var mod_ : shortstring = '';
    ModifierCount, i: LongInt;
begin
if Modifier = '' then exit;
ModifierCount:= 0;

for i:= 1 to Length(Modifier) do
    if(Modifier[i] = ':') then inc(ModifierCount);

SplitByChar(Modifier, mod_, ':');//remove the first mod: part
Modifier:= mod_;
for i:= 0 to ModifierCount do
    begin
    mod_:= '';
    SplitByChar(Modifier, mod_, ':');
    if (Modifier = 'lshift')                    then code:= code or LSHIFT;
    if (Modifier = 'rshift')                    then code:= code or RSHIFT;
    if (Modifier = 'lalt')                      then code:= code or LALT;
    if (Modifier = 'ralt')                      then code:= code or RALT;
    if (Modifier = 'lctrl') or (mod_ = 'lmeta') then code:= code or LCTRL;
    if (Modifier = 'rctrl') or (mod_ = 'rmeta') then code:= code or RCTRL;
    Modifier:= mod_;
    end;
end;

procedure ProcessKey(code: LongInt; KeyDown: boolean);
var
    Trusted: boolean;
    s      : string;
begin
if not(tkbd[code] xor KeyDown) then exit;
tkbd[code]:= KeyDown;

Trusted:= (CurrentTeam <> nil)
          and (not CurrentTeam^.ExtDriven)
          and (CurrentHedgehog^.BotLevel = 0);
// REVIEW OR FIXME
// ctrl/cmd + q to close engine and frontend - this seems like a bad idea, since we let people set arbitrary binds, and don't warn them of this.
// There's no confirmation at all
// ctrl/cmd + q to close engine and frontend
if(KeyDown and (code = SDLK_q)) then
    begin
{$IFDEF DARWIN}
    if tkbd[KeyNameToCode('left_meta')] or tkbd[KeyNameToCode('right_meta')] then
{$ELSE}
    if tkbd[KeyNameToCode('left_ctrl')] or tkbd[KeyNameToCode('right_ctrl')] then
{$ENDIF}
        ParseCommand('halt', true);
    end;

// ctrl/cmd + w to close engine
if(KeyDown and (code = SDLK_w)) then
    begin
{$IFDEF DARWIN}
    // on OS X it this is expected behaviour
    if tkbd[KeyNameToCode('left_meta')] or tkbd[KeyNameToCode('right_meta')] then
{$ELSE}
    // on other systems use this shortcut only if the keys are not bound to any command
    if tkbd[KeyNameToCode('left_ctrl')] or tkbd[KeyNameToCode('right_ctrl')] then
        if ((CurrentBinds.indices[KeyNameToCode('left_ctrl')] = 0) or
            (CurrentBinds.indices[KeyNameToCode('right_ctrl')] = 0)) and
            (CurrentBinds.indices[SDLK_w] = 0) then
{$ENDIF}
        ParseCommand('forcequit', true);
    end;

if CurrentBinds.indices[code] > 0 then
    begin
    if (code < cKeyMaxIndex - 2) // means not mouse buttons
        and KeyDown
        and (not ((CurrentBinds.binds[CurrentBinds.indices[code]] = 'put') 
                  or (CurrentBinds.binds[CurrentBinds.indices[code]] = 'ammomenu') 
                  or (CurrentBinds.binds[CurrentBinds.indices[code]] = '+cur_u') 
                  or (CurrentBinds.binds[CurrentBinds.indices[code]] = '+cur_d') 
                  or (CurrentBinds.binds[CurrentBinds.indices[code]] = '+cur_l') 
                  or (CurrentBinds.binds[CurrentBinds.indices[code]] = '+cur_r')))
        and (CurrentTeam <> nil) 
        and (not CurrentTeam^.ExtDriven) 
        then bShowAmmoMenu:= false;

    if KeyDown then
        begin
        Trusted:= Trusted and (not isPaused); //releasing keys during pause should be allowed on the other hand

        if CurrentBinds.binds[CurrentBinds.indices[code]] = 'switch' then
            LocalMessage:= LocalMessage or gmSwitch
        else if CurrentBinds.binds[CurrentBinds.indices[code]] = '+precise' then
            LocalMessage:= LocalMessage or gmPrecise;

        ParseCommand(CurrentBinds.binds[CurrentBinds.indices[code]], Trusted);
        if (CurrentTeam <> nil) and (not CurrentTeam^.ExtDriven) and (ReadyTimeLeft > 1) then
            ParseCommand('gencmd R', true)
        end
    else if (CurrentBinds.binds[CurrentBinds.indices[code]][1] = '+') then
        begin
        if CurrentBinds.binds[CurrentBinds.indices[code]] = '+precise' then
            LocalMessage:= LocalMessage and (not gmPrecise);
        s:= CurrentBinds.binds[CurrentBinds.indices[code]];
        s[1]:= '-';
        ParseCommand(s, Trusted);
        if (CurrentTeam <> nil) and (not CurrentTeam^.ExtDriven) and (ReadyTimeLeft > 1) then
            ParseCommand('gencmd R', true)
        end
    else
        begin
        if CurrentBinds.binds[CurrentBinds.indices[code]] = 'switch' then
            LocalMessage:= LocalMessage and (not gmSwitch)
        end
    end
end;

procedure ProcessKey(event: TSDL_KeyboardEvent); inline;
var code: LongInt;
begin
    // TODO
    code:= LongInt(event.keysym.scancode);
    //writelntoconsole('[KEY] '+inttostr(code)+ ' -> ''' +KeyNames[code] + ''', type = '+inttostr(event.type_));
    ProcessKey(code, event.type_ = SDL_KEYDOWN);
end;

procedure ProcessMouse(event: TSDL_MouseButtonEvent; ButtonDown: boolean);
begin
    //writelntoconsole('[MOUSE] '+inttostr(event.button));
    case event.button of
        SDL_BUTTON_LEFT:
            ProcessKey(KeyNameToCode('mousel'), ButtonDown);
        SDL_BUTTON_MIDDLE:
            ProcessKey(KeyNameToCode('mousem'), ButtonDown);
        SDL_BUTTON_RIGHT:
            ProcessKey(KeyNameToCode('mouser'), ButtonDown);
        end;
end;

var mwheelupCode, mwheeldownCode: Integer;

//procedure ProcessMouseWheel(x, y: LongInt);
procedure ProcessMouseWheel(y: LongInt);
begin
    // we don't use 
    //writelntoconsole('[MOUSEWHEEL] '+inttostr(x)+', '+inttostr(y));
    if y > 0 then
        begin
        // reset other direction
        if tkbd[mwheeldownCode] then
            ProcessKey(mwheeldownCode, false);
        // trigger "button down" event
        if (not tkbd[mwheelupCode]) then
            ProcessKey(mwheelupCode, true);
        end
    else if y < 0 then
        begin
        // reset other direction
        if tkbd[mwheelupCode] then
            ProcessKey(mwheelupCode, false);
        // trigger "button down" event
        if (not tkbd[mwheeldownCode]) then
            ProcessKey(mwheeldownCode, true);
        end;
end;

procedure ResetMouseWheel();
begin
    if tkbd[mwheelupCode] then
        ProcessKey(mwheelupCode, false);
    if tkbd[mwheeldownCode] then
        ProcessKey(mwheeldownCode, false);
end;

procedure ResetKbd;
var t: LongInt;
begin
for t:= 0 to cKbdMaxIndex do
    if tkbd[t] then
        ProcessKey(t, False);
end;

procedure RegisterBind(var binds: TBinds; key, value: shortstring);
var code: LongInt;
begin
    checkFails(binds.lastIndex < 255, 'Too many key bindings', true);

    code:= KeyNameToCode(key);

    checkFails(code >= 0, 'unknown key', true);

    if binds.indices[code] > 0 then
    begin
        binds.binds[binds.indices[code]]:= value
    end
    else begin
        inc(binds.lastIndex);
        binds.indices[code]:= binds.lastIndex;
        binds.binds[binds.indices[code]]:= value
    end;
end;

procedure InitDefaultBinds;
var i: Longword;
begin
    RegisterBind(DefaultBinds, 'escape', 'quit');
    RegisterBind(DefaultBinds, _S'`', 'history');
    RegisterBind(DefaultBinds, 'delete', 'rotmask');
    RegisterBind(DefaultBinds, 'home', 'rottags');
    RegisterBind(DefaultBinds, 'm', '+mission');

    //numpad
    //DefaultBinds[265]:= '+volup';
    //DefaultBinds[256]:= '+voldown';

    RegisterBind(DefaultBinds, _S'0', '+volup');
    RegisterBind(DefaultBinds, _S'9', '+voldown');
    RegisterBind(DefaultBinds, _S'8', 'mute');
    RegisterBind(DefaultBinds, _S'c', 'capture');
    RegisterBind(DefaultBinds, _S'r', 'record');
    RegisterBind(DefaultBinds, _S'h', 'findhh');
    RegisterBind(DefaultBinds, _S'p', 'pause');
    RegisterBind(DefaultBinds, _S's', '+speedup');
    RegisterBind(DefaultBinds, _S't', 'chat');
    RegisterBind(DefaultBinds, _S'y', 'confirm');

    RegisterBind(DefaultBinds, 'mousem', 'zoomreset');
    RegisterBind(DefaultBinds, 'wheelup', 'zoomin');
    RegisterBind(DefaultBinds, 'wheeldown', 'zoomout');

    RegisterBind(DefaultBinds, 'f12', 'fullscr');

    for i:= 1 to 10 do RegisterBind(DefaultBinds, 'f'+IntToStr(i), 'slot '+char(48+i));
    for i:= 1 to 5  do RegisterBind(DefaultBinds, IntToStr(i), 'timer '+IntToStr(i));
    RegisterBind(DefaultBinds, 'n', 'timer_u');

    RegisterBind(DefaultBinds, 'mousel', '/put');
    RegisterBind(DefaultBinds, 'mouser', 'ammomenu');
    RegisterBind(DefaultBinds, 'backspace', 'hjump');
    RegisterBind(DefaultBinds, 'tab', 'switch');
    RegisterBind(DefaultBinds, 'return', 'ljump');
    RegisterBind(DefaultBinds, 'space', '+attack');
    RegisterBind(DefaultBinds, 'up', '+up');
    RegisterBind(DefaultBinds, 'down', '+down');
    RegisterBind(DefaultBinds, 'left', '+left');
    RegisterBind(DefaultBinds, 'right', '+right');
    RegisterBind(DefaultBinds, 'left_shift', '+precise');

    // Default controls for first connected controller
    { NOTE: This is provided for convenience so players
    don't have to set-up the controller entirely in a new install.
    It's not ideal, so players are still encourages to
    set up things manually. }
    // Essential controls
    RegisterBind(DefaultBinds, 'j0h0r', '+right');
    RegisterBind(DefaultBinds, 'j0h0l', '+left');
    RegisterBind(DefaultBinds, 'j0h0u', '+up');
    RegisterBind(DefaultBinds, 'j0h0d', '+down');
    RegisterBind(DefaultBinds, 'j0b0', 'ljump');
    RegisterBind(DefaultBinds, 'j0b1', 'hjump');
    RegisterBind(DefaultBinds, 'j0b2', '+attack');
    RegisterBind(DefaultBinds, 'j0b3', 'ammomenu');
    RegisterBind(DefaultBinds, 'j0b4', '+precise');
    RegisterBind(DefaultBinds, 'j0b5', 'put');
    RegisterBind(DefaultBinds, 'j0b6', 'switch');
    RegisterBind(DefaultBinds, 'j0b7', 'timer_u');

    // Cursor movement (also essential)
    RegisterBind(DefaultBinds, 'j0h1r', '+cur_r');
    RegisterBind(DefaultBinds, 'j0h1l', '+cur_l');
    RegisterBind(DefaultBinds, 'j0h1d', '+cur_d');
    RegisterBind(DefaultBinds, 'j0h1u', '+cur_u');

    RegisterBind(DefaultBinds, 'j0a0u', '+cur_r');
    RegisterBind(DefaultBinds, 'j0a0d', '+cur_l');
    RegisterBind(DefaultBinds, 'j0a1u', '+cur_d');
    RegisterBind(DefaultBinds, 'j0a1d', '+cur_u');

    // Additional controls
    RegisterBind(DefaultBinds, 'j0b8', 'findhh');
    RegisterBind(DefaultBinds, 'j0b9', '+mission');

    loadBinds('dbind', cPathz[ptConfig] + '/settings.ini');
end;


procedure InitKbdKeyTable;
var i, j, k, t: LongInt;
    s: string[15];
begin
    KeyNames[cKeyMaxIndex    ]:= 'mousel';
    KeyNames[cKeyMaxIndex - 1]:= 'mousem';
    KeyNames[cKeyMaxIndex - 2]:= 'mouser';
    mwheelupCode:= cKeyMaxIndex - 3;
    KeyNames[mwheelupCode]:= 'wheelup';
    mwheeldownCode:= cKeyMaxIndex - 4;
    KeyNames[mwheeldownCode]:= 'wheeldown';

    for i:= 0 to cKeyMaxIndex - 5 do
        begin
        s:= shortstring(SDL_GetScancodeName(TSDL_Scancode(i)));

        for t:= 1 to Length(s) do
            if s[t] = ' ' then
                s[t]:= '_';
        KeyNames[i]:= LowerCase(s)
        end;


    // get the size of keyboard array
    SDL_GetKeyboardState(@k);

    // Controller(s)
    for j:= 0 to Pred(ControllerNumControllers) do
        begin
        for i:= 0 to Pred(ControllerNumAxes[j]) do
            begin
            KeyNames[k + 0]:= 'j' + IntToStr(j) + 'a' + IntToStr(i) + 'u';
            KeyNames[k + 1]:= 'j' + IntToStr(j) + 'a' + IntToStr(i) + 'd';
            inc(k, 2);
            end;
        for i:= 0 to Pred(ControllerNumHats[j]) do
            begin
            KeyNames[k + 0]:= 'j' + IntToStr(j) + 'h' + IntToStr(i) + 'u';
            KeyNames[k + 1]:= 'j' + IntToStr(j) + 'h' + IntToStr(i) + 'r';
            KeyNames[k + 2]:= 'j' + IntToStr(j) + 'h' + IntToStr(i) + 'd';
            KeyNames[k + 3]:= 'j' + IntToStr(j) + 'h' + IntToStr(i) + 'l';
            inc(k, 4);
            end;
        for i:= 0 to Pred(ControllerNumButtons[j]) do
            begin
            KeyNames[k]:= 'j' + IntToStr(j) + 'b' + IntToStr(i);
            inc(k, 1);
            end;
        end;

        InitDefaultBinds
end;



{$IFNDEF MOBILE}
procedure SetBinds(var binds: TBinds);
var
    t: LongInt;
begin
    for t:= 0 to cKbdMaxIndex do
        if (CurrentBinds.binds[CurrentBinds.indices[t]] <> binds.binds[binds.indices[t]]) and tkbd[t] then
            ProcessKey(t, False);

    CurrentBinds:= binds;
end;
{$ELSE}
procedure SetBinds(var binds: TBinds);
begin
    binds:= binds; // avoid hint
    CurrentBinds:= DefaultBinds;
end;
{$ENDIF}

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
var j: Integer;
begin
ControllerEnabled:= 0;
{$IFDEF IPHONEOS}
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
        WriteLnToConsole('Game controller no. ' + IntToStr(j) + ', name "' + shortstring(SDL_JoystickNameForIndex(j)) + '":');
        Controller[j]:= SDL_JoystickOpen(j);
        if Controller[j] = nil then
            WriteLnToConsole('* Failed to open game controller no. ' + IntToStr(j) + '!')
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

            (*// reset all buttons/axes
            for i:= 0 to pred(ControllerNumAxes[j]) do
                ControllerAxes[j][i]:= 0;
            for i:= 0 to pred(ControllerNumBalls[j]) do
                begin
                ControllerBalls[j][i][0]:= 0;
                ControllerBalls[j][i][1]:= 0;
                end;
            for i:= 0 to pred(ControllerNumHats[j]) do
                ControllerHats[j][i]:= SDL_HAT_CENTERED;
            for i:= 0 to pred(ControllerNumButtons[j]) do
                ControllerButtons[j][i]:= 0;*)
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
    SDL_GetKeyboardState(@k);
    k:= k + joy * (ControllerNumAxes[joy]*2 + ControllerNumHats[joy]*4 + ControllerNumButtons[joy]*2);
    ProcessKey(k +  axis*2, value > 20000);
    ProcessKey(k + (axis*2)+1, value < -20000);
end;

procedure ControllerHatEvent(joy, hat, value: Byte);
var
    k: LongInt;
begin
    SDL_GetKeyboardState(@k);
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
    SDL_GetKeyboardState(@k);
    k:= k + joy * (ControllerNumAxes[joy]*2 + ControllerNumHats[joy]*4 + ControllerNumButtons[joy]*2);
    ProcessKey(k +  ControllerNumAxes[joy]*2 + ControllerNumHats[joy]*4 + button, pressed);
end;

procedure loadBinds(cmd, s: shortstring);
var i: LongInt;
    f: PFSFile;
    p, l: shortstring;
    b: byte;
begin
    if cOnlyStats then exit;

    AddFileLog('[BINDS] Loading binds from: ' + s);

    l:= '';
    if pfsExists(s) then
        begin
        f:= pfsOpenRead(s);
        while (not pfsEOF(f)) and (l <> '[Binds]') do
            pfsReadLn(f, l);

        while (not pfsEOF(f)) and (l <> '') do
            begin
            pfsReadLn(f, l);

            p:= '';
            i:= 1;
            while (i <= length(l)) and (l[i] <> '=') do
                begin
                if l[i] = '%' then
                    begin
                    l[i]:= '$';
                    val(copy(l, i, 3), b);
                    p:= p + char(b);
                    inc(i, 3)
                    end
                else
                    begin
                    p:= p + l[i];
                    inc(i)
                    end;
                end;

            if i < length(l) then
                begin
                l:= copy(l, i + 1, length(l) - i);
                if l <> 'default' then
                    begin
                    if (length(l) = 2) and (l[1] = '\') then
                        l:= l[1] + ''
                    else if (l[1] = '"') and (l[length(l)] = '"') then
                        l:= copy(l, 2, length(l) - 2);

                    p:= cmd + ' ' + l + ' ' + p;
                    ParseCommand(p, true)
                    end
                end
            end;

        pfsClose(f)
        end
        else
            AddFileLog('[BINDS] file not found');
end;


procedure addBind(var binds: TBinds; var id: shortstring);
var KeyName, Modifier, tmp: shortstring;
    i, newCode, code, b: LongInt;
begin
    KeyName:= '';
    Modifier:= '';

    if(Pos('mod:', id) <> 0)then
        begin
        tmp:= '';
        SplitBySpace(id, tmp);
        Modifier:= id;
        id:= tmp;
        end;

    SplitBySpace(id, KeyName);
    if KeyName[1]='"' then
        Delete(KeyName, 1, 1);
    if KeyName[byte(KeyName[0])]='"' then
        Delete(KeyName, byte(KeyName[0]), 1);
    b:= KeyNameToCode(id, Modifier);
    if b = 0 then
        OutError(errmsgUnknownVariable + ' "' + id + '"', false)
    else
    begin
        // add bind: first check if this cmd is already bound, and remove old bind
        i:= Low(binds.binds);
        while (i <= High(binds.binds)) and (binds.binds[i] <> KeyName) do
            inc(i);

        if (i <= High(binds.binds)) then
        begin
            code:= Low(binds.indices);
            while (code <= High(binds.indices)) and (binds.indices[code] <> i) do
                inc(code);

            checkFails(code <= High(binds.indices), 'binds registry inconsistency', true);

            binds.indices[code]:= 0;
            binds.binds[i]:= ''
        end;

        if binds.indices[b] > 0 then
            newCode:= binds.indices[b]
        else if i >= High(binds.binds) then
            begin
                inc(binds.lastIndex);
                checkFails(binds.lastIndex < High(binds.binds), 'too many binds', true);
                newCode:= binds.lastIndex
            end else
                newCode:= i;


    binds.indices[b]:= newCode;
    binds.binds[binds.indices[b]]:= KeyName
    end
end;

// Bind that isn't a team bind, but overrides defaultbinds.
procedure chDefaultBind(var id: shortstring);
begin
    addBind(DefaultBinds, id)
end;

procedure initModule;
begin
    // assign 0 until InitKbdKeyTable is called
    mwheelupCode:= 0;
    mwheeldownCode:= 0;

    RegisterVariable('dbind', @chDefaultBind, true );
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
