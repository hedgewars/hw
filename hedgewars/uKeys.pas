(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2008 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uKeys;
interface
uses uConsts, SDLh;
{$INCLUDE "options.inc"}

type TBinds = array[0..cKeyMaxIndex] of shortstring;
type TKeyboardState = array[0..cKeyMaxIndex] of Byte;

function  KeyNameToCode(name: string): word;
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

var	hideAmmoMenu: boolean;
	wheelUp: boolean = false;
	wheelDown: boolean = false;
{$IFDEF TOUCHINPUT}
        leftClick: boolean = false;
        middleClick: boolean = false;
        rightClick: boolean = false;

	upKey: boolean = false;
	downKey: boolean = false;
	rightKey: boolean = false;
	leftKey: boolean = false;

	backspaceKey: boolean = false;
	spaceKey: boolean = false;
	enterKey: boolean = false;
	tabKey: boolean = false;

	isAttacking: boolean = false;
	isWalking: boolean = false;
{$ENDIF}
{$IFDEF IPHONEOS}
	theJoystick: PSDL_Joystick;
{$ENDIF}
	ControllerNumControllers: Integer;
	ControllerEnabled: Integer;
	ControllerNumAxes: array[0..5] of Integer;
	//ControllerNumBalls: array[0..5] of Integer;
	ControllerNumHats: array[0..5] of Integer;
	ControllerNumButtons: array[0..5] of Integer;
	ControllerAxes: array[0..5] of array[0..19] of Integer;
	//ControllerBalls: array[0..5] of array[0..19] of array[0..1] of Integer;
	ControllerHats: array[0..5] of array[0..19] of Byte;
	ControllerButtons: array[0..5] of array[0..19] of Byte;

implementation
uses uTeams, uConsole, uMisc, uStore;
const KeyNumber = 1024;

var tkbd, tkbdn: TKeyboardState;
    KeyNames: array [0..cKeyMaxIndex] of string[15];
    DefaultBinds, CurrentBinds: TBinds;

function KeyNameToCode(name: string): word;
var Result: Word;
begin
Result:= cKeyMaxIndex;
while (Result > 0) and (KeyNames[Result] <> name) do dec(Result);
KeyNameToCode:= Result
end;

procedure ProcessKbd;
var  i, j, k: LongInt;
     s: shortstring;
     pkbd: PByteArray;
     Trusted: boolean;
begin
hideAmmoMenu:= false;
Trusted:= (CurrentTeam <> nil)
          and (not CurrentTeam^.ExtDriven)
          and (CurrentHedgehog^.BotLevel = 0);

// move cursor/camera
// TODO: Scale on screen dimensions and/or axis value (game controller)?
movecursor(5 * CursorMovementX, 5 * CursorMovementY);
		  
{$IFDEF SDL13}
pkbd := SDL_GetKeyboardState(@j);
k    := SDL_GetMouseState(0, nil, nil);
{$ELSE}
pkbd := SDL_GetKeyState(@j);
k    := SDL_GetMouseState(nil, nil);
{$ENDIF}

{$IFNDEF IPHONEOS}
for i:= 6 to pred(j) do // first 6 will be overwritten
	tkbdn[i]:= pkbd^[i];
{$ENDIF}

// mouse buttons
{$IFDEF DARWIN}
tkbdn[1]:= ((k and 1) and not (tkbdn[306] or tkbdn[305]));
tkbdn[3]:= ((k and 1) and (tkbdn[306] or tkbdn[305])) or (k and 4);
{$ELSE}
tkbdn[1]:= (k and 1);
tkbdn[3]:= ((k shr 2) and 1);
{$ENDIF}
tkbdn[2]:= ((k shr 1) and 1);

// mouse wheels (see event loop in project file)
tkbdn[4]:= ord(wheelDown);
tkbdn[5]:= ord(wheelUp);
wheelUp:= false;
wheelDown:= false;
{$IFDEF TOUCHINPUT}
tkbdn[1]:= ord(leftClick);
tkbdn[2]:= ord(middleClick);
tkbdn[3]:= ord(rightClick);
leftClick:= false;
middleClick:= false;
rightClick:= false;

tkbdn[23]:= ord(upKey);
tkbdn[24]:= ord(downKey);
tkbdn[25]:= ord(leftKey);
tkbdn[26]:= ord(rightKey);

tkbdn[ 8]:= ord(backspaceKey);
tkbdn[ 9]:= ord(tabKey);
tkbdn[13]:= ord(enterKey);
tkbdn[32]:= ord(spaceKey);

upKey:= false;
downKey:= false;
if isWalking = false then rightKey:= false;
if isWalking = false then leftKey:= false;

if isAttacking = false then spaceKey:= false;
tabKey:= false;
enterKey:= false;
backspaceKey:= false;

{$ENDIF}

// Controller(s)
k:= j; // should we test k for hitting the limit? sounds rather unlikely to ever reach it
for j:= 0 to Pred(ControllerNumControllers) do
	begin
	for i:= 0 to Pred(ControllerNumAxes[j]) do
		begin
		if ControllerAxes[j][i] > 20000 then tkbdn[k + 0]:= 1 else tkbdn[k + 0]:= 0;
		if ControllerAxes[j][i] < -20000 then tkbdn[k + 1]:= 1 else tkbdn[k + 1]:= 0;
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

// now process strokes
for i:= 0 to cKeyMaxIndex do
if CurrentBinds[i][0] <> #0 then
	begin
	if (i > 3) and (tkbdn[i] <> 0) and not ((CurrentBinds[i] = 'put') or (CurrentBinds[i] = 'ammomenu') or (CurrentBinds[i] = '+cur_u') or (CurrentBinds[i] = '+cur_d') or (CurrentBinds[i] = '+cur_l') or (CurrentBinds[i] = '+cur_r')) then hideAmmoMenu:= true;
	if (tkbd[i] = 0) and (tkbdn[i] <> 0) then ParseCommand(CurrentBinds[i], Trusted)
	else if (CurrentBinds[i][1] = '+')
			and (tkbdn[i] = 0)
			and (tkbd[i] <> 0) then
			begin
			s:= CurrentBinds[i];
			s[1]:= '-';
			ParseCommand(s, Trusted)
			end;
	tkbd[i]:= tkbdn[i]
	end
end;

procedure ResetKbd;
var i, j, k, t: LongInt;
    pkbd: PByteArray;
begin

{$IFDEF SDL13}
pkbd:= SDL_GetKeyboardState(@j);
k:= SDL_GetMouseState(0, nil, nil);
{$ELSE}
pkbd:= SDL_GetKeyState(@j);
k:= SDL_GetMouseState(nil, nil);
{$ENDIF}
TryDo(j < cKeyMaxIndex, 'SDL keys number is more than expected (' + inttostr(j) + ')', true);

{$IFNDEF IPHONEOS}
for i:= 1 to pred(j) do
	tkbdn[i]:= pkbd^[i];
{$ENDIF}

// mouse buttons
{$IFDEF DARWIN}
tkbdn[1]:= ((k and 1) and not (tkbdn[306] or tkbdn[305]));
tkbdn[3]:= ((k and 1) and (tkbdn[306] or tkbdn[305])) or (k and 4);
{$ELSE}
tkbdn[1]:= (k and 1);
tkbdn[3]:= ((k shr 2) and 1);
{$ENDIF}
tkbdn[2]:= ((k shr 1) and 1);

// mouse wheels (see event loop in project file)
tkbdn[4]:= ord(wheelDown);
tkbdn[5]:= ord(wheelUp);
wheelUp:= false;
wheelDown:= false;
{$IFDEF IPHONEOS}
tkbdn[1]:= ord(leftClick);
tkbdn[2]:= ord(middleClick);
tkbdn[3]:= ord(rightClick);
leftClick:= false;
middleClick:= false;
rightClick:= false;

tkbdn[23]:= ord(upKey);
tkbdn[24]:= ord(downKey);
tkbdn[25]:= ord(leftKey);
tkbdn[26]:= ord(rightKey);

tkbdn[ 8]:= ord(backspaceKey);
tkbdn[ 9]:= ord(tabKey);
tkbdn[13]:= ord(enterKey);
tkbdn[32]:= ord(spaceKey);

upKey:= false;
downKey:= false;
tabKey:= false;
if isWalking = false then rightKey:= false;
if isWalking = false then leftKey:= false;

if isAttacking = false then spaceKey:= false;
enterKey:= false;
backspaceKey:= false;
{$ENDIF}

// Controller(s)
k:= j; // should we test k for hitting the limit? sounds rather unlikely to ever reach it
for j:= 0 to Pred(ControllerNumControllers) do
	begin
	for i:= 0 to Pred(ControllerNumAxes[j]) do
		begin
		if ControllerAxes[j][i] > 20000 then tkbdn[k + 0]:= 1 else tkbdn[k + 0]:= 0;
		if ControllerAxes[j][i] < -20000 then tkbdn[k + 1]:= 1 else tkbdn[k + 1]:= 0;
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
	
for t:= 0 to cKeyMaxIndex do
    tkbd[i]:= tkbdn[i]
end;

procedure InitKbdKeyTable;
var i, j, k, t: LongInt;
    s: string[15];
begin
KeyNames[1]:= 'mousel';
KeyNames[2]:= 'mousem';
KeyNames[3]:= 'mouser';
KeyNames[4]:= 'wheelup';
KeyNames[5]:= 'wheeldown';

for i:= 6 to cKeyMaxIndex do
    begin
    s:= SDL_GetKeyName(i);
//	addfilelog(inttostr(i) + ' ' + s);
    if s = 'unknown key' then KeyNames[i]:= ''
       else begin
       for t:= 1 to Length(s) do
           if s[t] = ' ' then s[t]:= '_';
       KeyNames[i]:= s
       end;
    end;

{$IFDEF SDL13}
PByteArray(SDL_GetKeyboardState(@i));
{$ELSE}
SDL_GetKeyState(@i);
{$ENDIF}

// Controller(s)
k:= i;
for j:= 0 to Pred(ControllerNumControllers) do
	begin
	for i:= 0 to Pred(ControllerNumAxes[j]) do
		begin
		keynames[k + 0]:= 'j' + inttostr(j) + 'a' + inttostr(i) + 'u';
		keynames[k + 1]:= 'j' + inttostr(j) + 'a' + inttostr(i) + 'd';
		inc(k, 2);
		end;
	for i:= 0 to Pred(ControllerNumHats[j]) do
		begin
		keynames[k + 0]:= 'j' + inttostr(j) + 'h' + inttostr(i) + 'u';
		keynames[k + 1]:= 'j' + inttostr(j) + 'h' + inttostr(i) + 'r';
		keynames[k + 2]:= 'j' + inttostr(j) + 'h' + inttostr(i) + 'd';
		keynames[k + 3]:= 'j' + inttostr(j) + 'h' + inttostr(i) + 'l';
		inc(k, 4);
		end;
	for i:= 0 to Pred(ControllerNumButtons[j]) do
		begin
		keynames[k]:= 'j' + inttostr(j) + 'b' + inttostr(i);
		inc(k, 1);
		end;
	end;

{$IFDEF TOUCHINPUT}
DefaultBinds[  1]:= '/put';
DefaultBinds[  3]:= 'ammomenu';
DefaultBinds[  8]:= 'hjump';
DefaultBinds[  9]:= 'switch';
DefaultBinds[ 13]:= 'ljump';
DefaultBinds[ 23]:= '+up';
DefaultBinds[ 24]:= '+down';
DefaultBinds[ 25]:= '+left';
DefaultBinds[ 26]:= '+right';
DefaultBinds[ 32]:= '+attack';
{$ENDIF}
	
DefaultBinds[ 27]:= 'quit';
DefaultBinds[ 96]:= 'history';
DefaultBinds[127]:= 'rotmask';

//numpad
//DefaultBinds[265]:= '+volup';
//DefaultBinds[256]:= '+voldown';

DefaultBinds[KeyNameToCode('0')]:= '+volup';
DefaultBinds[KeyNameToCode('9')]:= '+voldown';
DefaultBinds[KeyNameToCode('c')]:= 'capture';
DefaultBinds[KeyNameToCode('h')]:= 'findhh';
DefaultBinds[KeyNameToCode('p')]:= 'pause';
DefaultBinds[KeyNameToCode('s')]:= '+speedup';
DefaultBinds[KeyNameToCode('t')]:= 'chat';
DefaultBinds[KeyNameToCode('y')]:= 'confirm';

DefaultBinds[KeyNameToCode('mousem')]:= 'zoomreset';
DefaultBinds[KeyNameToCode('wheelup')]:= 'zoomout';
DefaultBinds[KeyNameToCode('wheeldown')]:= 'zoomin';

DefaultBinds[KeyNameToCode('f12')]:= 'fullscr';

SetDefaultBinds
end;

procedure SetBinds(var binds: TBinds);
begin
CurrentBinds:= binds;
end;

procedure SetDefaultBinds;
begin
CurrentBinds:= DefaultBinds
end;

procedure FreezeEnterKey;
begin
tkbd[13]:= 1;
tkbd[271]:= 1;
end;

var Controller: array [0..5] of PSDL_Joystick;
	
procedure ControllerInit;
var i, j: Integer;
begin
ControllerEnabled:= 0;
ControllerNumControllers:= SDL_NumJoysticks;

if ControllerNumControllers > 6 then ControllerNumControllers:= 6;

WriteLnToConsole('Number of game controllers: ' + inttostr(ControllerNumControllers));

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
			WriteLnToConsole('* Number of axes: ' + inttostr(ControllerNumAxes[j]));
			//WriteLnToConsole('* Number of balls: ' + inttostr(ControllerNumBalls[j]));
			WriteLnToConsole('* Number of hats: ' + inttostr(ControllerNumHats[j]));
			WriteLnToConsole('* Number of buttons: ' + inttostr(ControllerNumButtons[j]));
			ControllerEnabled:= 1;
			
			if ControllerNumAxes[j] > 20 then ControllerNumAxes[j]:= 20;
			//if ControllerNumBalls[j] > 20 then ControllerNumBalls[j]:= 20;
			if ControllerNumHats[j] > 20 then ControllerNumHats[j]:= 20;
			if ControllerNumButtons[j] > 20 then ControllerNumButtons[j]:= 20;
			
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
{$IFDEF IPHONEOS}
theJoystick:= Controller[0];
{$ENDIF}
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
	if pressed then ControllerButtons[joy][button]:= 1 else ControllerButtons[joy][button]:= 0;
end;

initialization

end.
