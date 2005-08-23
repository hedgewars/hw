(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004, 2005 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * Distributed under the terms of the BSD-modified licence:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * with the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *)

unit uKeys;
interface
{$INCLUDE options.inc}

function KeyNameToCode(name: string): word;
procedure ProcessKbd;
procedure ResetKbd;
procedure ProcessKbdDemo;
procedure InitKbdKeyTable;

implementation
uses SDLh, uTeams, uConsole, uConsts, uMisc;

type TKeyboardState = array[0..322] of Byte;
var tkbd: TKeyboardState;
    KeyNames: array [0..cKeyMaxIndex] of string[15];

function KeyNameToCode(name: string): word;
begin
Result:= cKeyMaxIndex;
while (Result>0)and(KeyNames[Result]<>name) do dec(Result)
end;

procedure ProcessKbd;
var  i: integer;
     s: shortstring;
     pkbd: PByteArray;
begin
if (CurrentTeam = nil)
   or (CurrentTeam.ExtDriven)
   or (CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].BotLevel <> 0) then exit;
pkbd:= SDL_GetKeyState(nil);
i:= SDL_GetMouseState(nil, nil);
pkbd^[1]:= (i and 1);
pkbd^[2]:= ((i shl 1) and 1);
pkbd^[3]:= ((i shl 2) and 1);
for i:= 1 to cKeyMaxIndex do
    if CurrentTeam.Aliases[i][0]<>#0 then
       begin
       if CurrentTeam.Aliases[i][1]='+' then
          begin
          if (pkbd^[i] <> 0)and(tkbd[i]  = 0) then ParseCommand(CurrentTeam.Aliases[i]) else
          if (pkbd^[i] =  0)and(tkbd[i] <> 0) then
             begin
             s:= CurrentTeam.Aliases[i];
             s[1]:= '-';
             ParseCommand(s)
             end;
          end else
          if (tkbd[i] = 0) and (pkbd^[i] <> 0) then ParseCommand(CurrentTeam.Aliases[i]);
       tkbd[i]:= pkbd^[i]
       end
end;

procedure ProcessKbdDemo;
var pkbd: PByteArray;
begin
pkbd:= PByteArray(SDL_GetKeyState(nil));
if pkbd^[27] <> 0 then
   begin
   ParseCommand('/quit');
   end;
end;

procedure ResetKbd;
var i, t: integer;
    pkbd: PByteArray;
begin
pkbd:= PByteArray(SDL_GetKeyState(@i));
for t:= 0 to Pred(i) do
    tkbd[i]:= pkbd^[i]
end;

procedure InitKbdKeyTable;
var i, t: integer;
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
    end
end;

initialization

end.
