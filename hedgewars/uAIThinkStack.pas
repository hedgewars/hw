(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uAIThinkStack;
interface
uses uAIActions, uGears, uFloat;
{$INCLUDE options.inc}
const cBranchStackSize = 12;
type TStackEntry = record
                   WastedTicks: Longword;
                   MadeActions: TActions;
                   Hedgehog: TGear;
                   end;

var ThinkStack: record
                Count: Longword;
                States: array[0..Pred(cBranchStackSize)] of TStackEntry;
                end;

function  Push(Ticks: Longword; const Actions: TActions; const Me: TGear; Dir: integer): boolean;
function  Pop(var Ticks: Longword; var Actions: TActions; var Me: TGear): boolean;
function  PosInThinkStack(Me: PGear): boolean;
procedure ClearThinkStack;

implementation

function Push(Ticks: Longword; const Actions: TActions; const Me: TGear; Dir: integer): boolean;
var Result: boolean;
begin
Result:= (ThinkStack.Count < cBranchStackSize) and (Actions.Count < MAXACTIONS - 5);
if Result then
   with ThinkStack.States[ThinkStack.Count] do
        begin
        WastedTicks:= Ticks;
        MadeActions:= Actions;
        Hedgehog:= Me;
        Hedgehog.Message:= Dir;
        inc(ThinkStack.Count)
        end;
Push:= Result
end;

function  Pop(var Ticks: Longword; var Actions: TActions; var Me: TGear): boolean;
var Result: boolean;
begin
Result:= ThinkStack.Count > 0;
if Result then
   begin
   dec(ThinkStack.Count);
   with ThinkStack.States[ThinkStack.Count] do
        begin
        Ticks:= WastedTicks;
        Actions:= MadeActions;
        Me:= Hedgehog
        end
   end;
Pop:= Result
end;

function PosInThinkStack(Me: PGear): boolean;
var i: Longword;
begin
i:= 0;
while (i < ThinkStack.Count) do
      begin
      if (not (2 < hwAbs(ThinkStack.States[i].Hedgehog.X - Me^.X) +
                   hwAbs(ThinkStack.States[i].Hedgehog.Y - Me^.Y)))
          and (ThinkStack.States[i].Hedgehog.Message = Me^.Message) then exit(true);
      inc(i)
      end;
PosInThinkStack:= false
end;

procedure ClearThinkStack;
begin
ThinkStack.Count:= 0
end;

end.
