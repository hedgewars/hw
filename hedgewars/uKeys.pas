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
uses uConsts;
{$INCLUDE options.inc}

type TBinds = array[0..cKeyMaxIndex] of shortstring;

function KeyNameToCode(name: string): word;
procedure ProcessKbd;
procedure ResetKbd;
procedure FreezeEnterKey;
procedure InitKbdKeyTable;

procedure SetBinds(var binds: TBinds);
procedure SetDefaultBinds;

var KbdKeyPressed: boolean;
	wheelUp: boolean = false;
	wheelDown: boolean = false;

implementation
uses SDLh, uTeams, uConsole, uMisc, uStore;
const KeyNumber = 1024;
type TKeyboardState = array[0..cKeyMaxIndex] of Byte;

var tkbd: TKeyboardState;
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
var  i: LongInt;
     s: shortstring;
     pkbd: PByteArray;
     Trusted: boolean;
begin
KbdKeyPressed:= false;
Trusted:= (CurrentTeam <> nil)
          and (not CurrentTeam^.ExtDriven)
          and (CurrentHedgehog^.BotLevel = 0);

{$IFDEF SDL13}
pkbd := SDL_GetKeyboardState(nil);
i    := SDL_GetMouseState(0, nil, nil);
{$ELSE}
pkbd := SDL_GetKeyState(nil);
i    := SDL_GetMouseState(nil, nil);
{$ENDIF}

// mouse buttons
{$IFDEF DARWIN}
pkbd^[1]:= ((i and 1) and not (pkbd^[306] or pkbd^[305]));
pkbd^[3]:= ((i and 1) and (pkbd^[306] or pkbd^[305])) or (i and 4);
{$ELSE}
pkbd^[1]:= (i and 1);
pkbd^[3]:= ((i shr 2) and 1);
{$ENDIF}
pkbd^[2]:= ((i shr 1) and 1);

// mouse wheels (see event loop in project file)
pkbd^[4]:= ord(wheelDown);
pkbd^[5]:= ord(wheelUp);
wheelUp:= false;
wheelDown:= false;

// now process strokes
for i:= 1 to cKeyMaxIndex do
if CurrentBinds[i][0] <> #0 then
	begin
	if (i > 3) and (pkbd^[i] <> 0) then KbdKeyPressed:= true;
	if (tkbd[i] = 0) and (pkbd^[i] <> 0) then ParseCommand(CurrentBinds[i], Trusted)
	else if (CurrentBinds[i][1] = '+')
			and (pkbd^[i] = 0)
			and (tkbd[i] <> 0) then
			begin
			s:= CurrentBinds[i];
			s[1]:= '-';
			ParseCommand(s, Trusted)
			end;
	tkbd[i]:= pkbd^[i]
	end
end;

procedure ResetKbd;
var i, t: LongInt;
    pkbd: PByteArray;
begin

{$IFDEF SDL13}
pkbd:= PByteArray(SDL_GetKeyboardState(@i));
{$ELSE}
pkbd:= PByteArray(SDL_GetKeyState(@i));
{$ENDIF}
TryDo(i < cKeyMaxIndex, 'SDL keys number is more than expected (' + inttostr(i) + ')', true);

for t:= 0 to Pred(i) do
    tkbd[i]:= pkbd^[i]
end;

procedure InitKbdKeyTable;
var i, t: LongInt;
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
	//addfilelog(inttostr(i) + ' ' + s);
    if s = 'unknown key' then KeyNames[i]:= ''
       else begin
       for t:= 1 to Length(s) do
           if s[t] = ' ' then s[t]:= '_';
       KeyNames[i]:= s
       end;
    end;

DefaultBinds[ 27]:= 'quit';
DefaultBinds[ 96]:= 'history';
DefaultBinds[127]:= 'rotmask';

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
CurrentBinds:= binds
end;

procedure SetDefaultBinds;
begin
CurrentBinds:= DefaultBinds
end;

procedure FreezeEnterKey;
begin
tkbd[13]:= 1;
tkbd[271]:= 1
end;

initialization

end.
