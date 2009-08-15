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
i	 := SDL_GetMouseState(0, nil, nil);
{$ELSE}
pkbd := SDL_GetKeyState(nil);
i	 := SDL_GetMouseState(nil, nil);
{$ENDIF}

pkbd^[1]:= (i and 1);
pkbd^[2]:= ((i shr 1) and 1);

{$IFDEF DARWIN}
//    normal right click     ||      ctrl (left/right) + left click	  
pkbd^[3]:= ((i shr 2) and 1) or ((i and 1) and (pkbd^[306] or pkbd^[305]));
{$ELSE}
pkbd^[3]:= ((i shr 2) and 1);
{$ENDIF}

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
for i:= 4 to cKeyMaxIndex do
    begin
    s:= SDL_GetKeyName(i);
    if s = 'unknown key' then KeyNames[i]:= ''
       else begin
       for t:= 1 to Length(s) do
           if s[t] = ' ' then s[t]:= '_';
       KeyNames[i]:= s
       end;
    end;

DefaultBinds[ 27]:= 'quit';
DefaultBinds[ 48]:= '+volup';
DefaultBinds[ 57]:= '+voldown';
DefaultBinds[ 44]:= 'history';	// , instead of `
DefaultBinds[ 96]:= 'history';
DefaultBinds[ 99]:= 'capture';
DefaultBinds[104]:= 'findhh';
DefaultBinds[112]:= 'pause';
DefaultBinds[115]:= '+speedup';
DefaultBinds[116]:= 'chat';
DefaultBinds[121]:= 'confirm';
DefaultBinds[127]:= 'rotmask';

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
