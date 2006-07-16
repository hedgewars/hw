(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004, 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uConsole;
interface
uses SDLh;
{$INCLUDE options.inc}
const isDeveloperMode: boolean = true;
type TVariableType = (vtCommand, vtInteger, vtReal, vtBoolean);
     TCommandHandler = procedure (var params: shortstring);

procedure DrawConsole(Surface: PSDL_Surface);
procedure WriteToConsole(s: shortstring);
procedure WriteLnToConsole(s: shortstring);
procedure KeyPressConsole(Key: Longword);
procedure ParseCommand(CmdStr: shortstring);
function  GetLastConsoleLine: shortstring;

implementation
{$J+}
uses uMisc, uStore, Types, uConsts, uGears, uTeams, uIO, uKeys, uSound, uWorld, uLand, uRandom;
const cLineWidth: integer = 0;
      cLinesCount = 256;
      
type  PVariable = ^TVariable;
      TVariable = record
                     Next: PVariable;
                     Name: string[15];
                    VType: TVariableType;
                  Handler: pointer;
                  end;

var   ConsoleLines: array[byte] of ShortString;
      CurrLine: integer = 0;
      InputStr: shortstring;
      Variables: PVariable = nil;

function RegisterVariable(Name: string; VType: TVariableType; p: pointer): PVariable;
begin
New(Result);
TryDo(Result <> nil, 'RegisterVariable: Result = nil', true);
FillChar(Result^, sizeof(TVariable), 0);
Result.Name:= Name;
Result.VType:= VType;
Result.Handler:= p;
if Variables = nil then Variables:= Result
                   else begin
                        Result.Next:= Variables;
                        Variables:= Result
                        end
end;

procedure FreeVariablesList;
var t, tt: PVariable;
begin
tt:= Variables;
Variables:= nil;
while tt<>nil do
      begin
      t:= tt;
      tt:= tt.Next;
      Dispose(t)
      end;
end;

procedure SplitBySpace(var a, b: shortstring);
var i, t: integer;
begin
i:= Pos(' ', a);
if i>0 then
   begin
   for t:= 1 to Pred(i) do
       if (a[t] >= 'A')and(a[t] <= 'Z') then Inc(a[t], 32);
   b:= copy(a, i + 1, Length(a) - i);
   while (b[0]<>#0) and (b[1]=#32) do Delete(b, 1, 1);
   byte(a[0]):= Pred(i)
   end else b:= '';
end;

procedure DrawConsole(Surface: PSDL_Surface);
var x, y: integer;
    r: TSDL_Rect;
begin
with r do
     begin
     x:= 0;
     y:= cConsoleHeight;
     w:= cScreenWidth;
     h:= 4;
     end;
SDL_FillRect(Surface, @r, cConsoleSplitterColor);
for y:= 0 to cConsoleHeight div 256 + 1 do
    for x:= 0 to cScreenWidth div 256 + 1 do
        DrawGear(sConsoleBG, x * 256, cConsoleHeight - 256 - y * 256, Surface);
for y:= 0 to cConsoleHeight div Fontz[fnt16].Height do
    DXOutText(4, cConsoleHeight - (y + 2) * (Fontz[fnt16].Height + 2), fnt16, ConsoleLines[(CurrLine - 1 - y + cLinesCount) mod cLinesCount], Surface);
DXOutText(4, cConsoleHeight - Fontz[fnt16].Height - 2, fnt16, '> '+InputStr, Surface);
end;

procedure WriteToConsole(s: shortstring);
var Len: integer;
begin
{$IFDEF DEBUGFILE}AddFileLog('Console write: ' + s);{$ENDIF}
Write(s);
repeat
Len:= cLineWidth - Length(ConsoleLines[CurrLine]);
ConsoleLines[CurrLine]:= ConsoleLines[CurrLine] + copy(s, 1, Len);
Delete(s, 1, Len);
if byte(ConsoleLines[CurrLine][0])=cLineWidth then
   begin
   inc(CurrLine);
   if CurrLine = cLinesCount then CurrLine:= 0;
   PLongWord(@ConsoleLines[CurrLine])^:= 0
   end;
until Length(s) = 0
end;

procedure WriteLnToConsole(s: shortstring);
begin
WriteToConsole(s);
WriteLn;
inc(CurrLine);
if CurrLine = cLinesCount then CurrLine:= 0;
PLongWord(@ConsoleLines[CurrLine])^:= 0
end;

procedure InitConsole;
var i: integer;
begin
cLineWidth:= cScreenWidth div 10;
if cLineWidth > 255 then cLineWidth:= 255;
for i:= 0 to Pred(cLinesCount) do PLongWord(@ConsoleLines[i])^:= 0
end;

procedure ParseCommand(CmdStr: shortstring);
type PReal = ^real;
var i, ii: integer;
    s: shortstring;
    t: PVariable;
    c: char;
begin
//WriteLnToConsole(CmdStr);
if CmdStr[0]=#0 then exit;
{$IFDEF DEBUGFILE}AddFileLog('ParseCommand "' + CmdStr + '"');{$ENDIF}
c:= CmdStr[1];
if c in ['/', '$'] then Delete(CmdStr, 1, 1) else c:= '/';
SplitBySpace(CmdStr, s);
t:= Variables;
while t <> nil do
      begin
      if t.Name = CmdStr then
         begin
         case t.VType of
              vtCommand: if c='/' then
                         begin
                         TCommandHandler(t.Handler)(s);
                         end;
              vtInteger: if c='$' then
                         if s[0]=#0 then
                            begin
                            str(PInteger(t.Handler)^, s);
                            WriteLnToConsole('$' + CmdStr + ' is "' + s + '"');
                            end else val(s, PInteger(t.Handler)^, i);
                 vtReal: if c='$' then
                         if s[0]=#0 then
                            begin
                            str(PReal(t.Handler)^:4:6, s);
                            WriteLnToConsole('$' + CmdStr + ' is "' + s + '"');
                            end else val(s, PReal(t.Handler)^   , i);
             vtBoolean: if c='$' then
                         if s[0]=#0 then
                            begin
                            str(ord(boolean(t.Handler^)), s);
                            WriteLnToConsole('$' + CmdStr + ' is "' + s + '"');
                            end else
                            begin
                            val(s, ii, i);
                            boolean(t.Handler^):= not (ii = 0)
                            end;
              end;
         exit
         end else t:= t.Next
      end;
case c of
     '$': WriteLnToConsole(errmsgUnknownVariable + ': "$' + CmdStr + '"')
     else WriteLnToConsole(errmsgUnknownCommand  + ': "/' + CmdStr + '"') end
end;

procedure AutoComplete;
var t: PVariable;
    c: char;
begin
if InputStr[0] = #0 then exit;
c:= InputStr[1];
if c in ['/', '$'] then Delete(InputStr, 1, 1)
                   else c:= #0;
if InputStr[byte(InputStr[0])] = #32 then dec(InputStr[0]);
t:= Variables;
while t <> nil do
      begin
      if (c=#0) or ((t.VType =  vtCommand) and (c='/'))or
                   ((t.VType <> vtCommand) and (c='$'))then
         if copy(t.Name, 1, Length(InputStr)) = InputStr then
            begin
            if t.VType = vtCommand then InputStr:= '/' + t.Name + ' '
                                   else InputStr:= '$' + t.Name + ' ';
            exit
            end;
      t:= t.Next
      end
end;

procedure KeyPressConsole(Key: Longword);
begin
case Key of
      8: if Length(InputStr)>0 then dec(InputStr[0]);
      9: AutoComplete;
 13,271: begin
         if InputStr[1] in ['/', '$'] then
            ParseCommand(InputStr)
         else
            ParseCommand('/say ' + InputStr);
         InputStr:= ''
         end;
     96: begin
         GameState:= gsGame;
         cConsoleYAdd:= 0;
         ResetKbd
         end;
     else InputStr:= InputStr + char(Key)
     end
end;

function GetLastConsoleLine: shortstring;
begin
if CurrLine = 0 then Result:= ConsoleLines[Pred(cLinesCount)]
                else Result:= ConsoleLines[Pred(CurrLine)]
end;

{$INCLUDE CCHandlers.inc}

initialization
InitConsole;
RegisterVariable('quit'    , vtCommand, @chQuit         );
RegisterVariable('capture' , vtCommand, @chCapture      );
RegisterVariable('addteam' , vtCommand, @chAddTeam      );
RegisterVariable('rdriven' , vtCommand, @chTeamLocal    );
RegisterVariable('map'     , vtCommand, @chSetMap       );
RegisterVariable('theme'   , vtCommand, @chSetTheme     );
RegisterVariable('seed'    , vtCommand, @chSetSeed      );
RegisterVariable('c_height', vtInteger, @cConsoleHeight );
RegisterVariable('gmflags' , vtInteger, @GameFlags      );
RegisterVariable('turntime', vtInteger, @cHedgehogTurnTime);
RegisterVariable('name'    , vtCommand, @chName         );
RegisterVariable('fort'    , vtCommand, @chFort         );
RegisterVariable('grave'   , vtCommand, @chGrave        );
RegisterVariable('bind'    , vtCommand, @chBind         );
RegisterVariable('add'     , vtCommand, @chAdd          );
RegisterVariable('skip'    , vtCommand, @chSkip         );
RegisterVariable('say'     , vtCommand, @chSay          );
RegisterVariable('+left'   , vtCommand, @chLeft_p       );
RegisterVariable('-left'   , vtCommand, @chLeft_m       );
RegisterVariable('+right'  , vtCommand, @chRight_p      );
RegisterVariable('-right'  , vtCommand, @chRight_m      );
RegisterVariable('+up'     , vtCommand, @chUp_p         );
RegisterVariable('-up'     , vtCommand, @chUp_m         );
RegisterVariable('+down'   , vtCommand, @chDown_p       );
RegisterVariable('-down'   , vtCommand, @chDown_m       );
RegisterVariable('+attack' , vtCommand, @chAttack_p     );
RegisterVariable('-attack' , vtCommand, @chAttack_m     );
RegisterVariable('color'   , vtCommand, @chColor        );
RegisterVariable('switch'  , vtCommand, @chSwitch       );
RegisterVariable('nextturn', vtCommand, @chNextTurn     );
RegisterVariable('timer'   , vtCommand, @chTimer        );
RegisterVariable('slot'    , vtCommand, @chSlot         );
RegisterVariable('put'     , vtCommand, @chPut          );
RegisterVariable('ljump'   , vtCommand, @chLJump        );
RegisterVariable('hjump'   , vtCommand, @chHJump        );

finalization
FreeVariablesList

end.
