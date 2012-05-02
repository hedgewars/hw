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

unit uCommands;

interface

var isDeveloperMode: boolean;
type TCommandHandler = procedure (var params: shortstring);

procedure initModule;
procedure freeModule;
procedure RegisterVariable(Name: shortstring; p: TCommandHandler; Trusted: boolean);
procedure ParseCommand(CmdStr: shortstring; TrustedSource: boolean);
procedure ParseTeamCommand(s: shortstring);
procedure StopMessages(Message: Longword);

implementation
uses uConsts, uVariables, uConsole, uUtils, uDebug;

type  PVariable = ^TVariable;
    TVariable = record
        Next: PVariable;
        Name: string[15];
        Handler: TCommandHandler;
        Trusted: boolean;
        end;

var
    Variables: PVariable;

procedure RegisterVariable(Name: shortstring; p: TCommandHandler; Trusted: boolean);
var
    value: PVariable;
begin
New(value);
TryDo(value <> nil, 'RegisterVariable: value = nil', true);
FillChar(value^, sizeof(TVariable), 0);
value^.Name:= Name;
value^.Handler:= p;
value^.Trusted:= Trusted;

if Variables = nil then
    Variables:= value
else
    begin
    value^.Next:= Variables;
    Variables:= value
    end;
end;


procedure ParseCommand(CmdStr: shortstring; TrustedSource: boolean);
var s: shortstring;
    t: PVariable;
    c: char;
begin
//WriteLnToConsole(CmdStr);
if CmdStr[0]=#0 then
    exit;
c:= CmdStr[1];
if (c = '/') or (c = '$') then
    Delete(CmdStr, 1, 1);
s:= '';
SplitBySpace(CmdStr, s);
AddFileLog('[Cmd] ' + CmdStr + ' (' + inttostr(length(s)) + ')');
t:= Variables;
while t <> nil do
    begin
    if t^.Name = CmdStr then
        begin
        if TrustedSource or t^.Trusted then
            t^.Handler(s);
        exit
        end
    else
        t:= t^.Next
    end;
case c of
    '$': WriteLnToConsole(errmsgUnknownVariable + ': "$' + CmdStr + '"')
    else
        WriteLnToConsole(errmsgUnknownCommand  + ': "/' + CmdStr + '"') end
end;

procedure ParseTeamCommand(s: shortstring);
var Trusted: boolean;
begin
Trusted:= (CurrentTeam <> nil)
          and (not CurrentTeam^.ExtDriven)
          and (CurrentHedgehog^.BotLevel = 0);
ParseCommand(s, Trusted);
if (CurrentTeam <> nil) and (not CurrentTeam^.ExtDriven) and (ReadyTimeLeft > 1) then
    ParseCommand('gencmd R', true)
end;



procedure StopMessages(Message: Longword);
begin
if (Message and gmLeft) <> 0 then
    ParseCommand('/-left', true)
else if (Message and gmRight) <> 0 then
    ParseCommand('/-right', true) 
else if (Message and gmUp) <> 0 then
    ParseCommand('/-up', true)
else if (Message and gmDown) <> 0 then
    ParseCommand('/-down', true)
else if (Message and gmAttack) <> 0 then
    ParseCommand('/-attack', true)
end;

procedure initModule;
begin
    Variables:= nil;
    isDeveloperMode:= true;
end;

procedure freeModule;
var t, tt: PVariable;
begin
    tt:= Variables;
    Variables:= nil;
    while tt <> nil do
    begin
        t:= tt;
        tt:= tt^.Next;
        Dispose(t)
    end;
end;

end.
