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
uses uAIActions, uGears;
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
function  Pop(out Ticks: Longword; out Actions: TActions; out Me: TGear): boolean;
function  PosInThinkStack(Me: PGear): boolean;
procedure ClearThinkStack;

implementation

function Push(Ticks: Longword; const Actions: TActions; const Me: TGear; Dir: integer): boolean;
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
        end
end;

function Pop(out Ticks: Longword; out Actions: TActions; out Me: TGear): boolean;
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
   end
end;

function PosInThinkStack(Me: PGear): boolean;
var i: Longword;
begin
i:= 0;
Result:= false;
while (i < ThinkStack.Count) and not Result do
      begin
      Result:= (abs(ThinkStack.States[i].Hedgehog.X - Me.X) +
                abs(ThinkStack.States[i].Hedgehog.Y - Me.Y) <= 2)
                and (ThinkStack.States[i].Hedgehog.Message = Me.Message);
      inc(i)
      end
end;

procedure ClearThinkStack;
begin
ThinkStack.Count:= 0
end;

end.
