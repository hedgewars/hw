(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uAI;
interface
{$INCLUDE options.inc}
procedure ProcessBot;
procedure FreeActionsList;

implementation
uses uTeams, uConsts, SDLh, uAIMisc, uGears, uAIAmmoTests, uAIActions, uMisc;

var Targets: TTargets;
    Actions, BestActions: TActions;

procedure FreeActionsList;
begin
BestActions.Count:= 0;
BestActions.Pos:= 0;
end;

procedure TestAmmos(Me: PGear);
var MyPoint: TPoint;
    Time: Longword;
    Angle, Power, Score: integer;
    i: integer;
begin
Mypoint.x:= round(Me.X);
Mypoint.y:= round(Me.Y);
for i:= 0 to Pred(Targets.Count) do
  begin
  Score:= TestBazooka(MyPoint, Targets.ar[i].Point, Time, Angle, Power);
  if Actions.Score + Score + Targets.ar[i].Score > BestActions.Score then
   begin
   BestActions:= Actions;
   inc(BestActions.Score, Score + Targets.ar[i].Score);
   AddAction(BestActions, aia_Weapon, Longword(amBazooka), 500);
   if (Angle > 0) then AddAction(BestActions, aia_LookRight, 0, 200)
   else if (Angle < 0) then AddAction(BestActions, aia_LookLeft, 0, 200);
   Angle:= integer(Me.Angle) - Abs(Angle);
   if Angle > 0 then
      begin
      AddAction(BestActions, aia_Up, aim_push, 500);
      AddAction(BestActions, aia_Up, aim_release, Angle)
      end else if Angle < 0 then
      begin
      AddAction(BestActions, aia_Down, aim_push, 500);
      AddAction(BestActions, aia_Down, aim_release, -Angle)
      end;
   AddAction(BestActions, aia_attack, aim_push, 300);
   AddAction(BestActions, aia_attack, aim_release, Power);
   end
  end
end;

procedure Walk(Me: PGear);
begin
TestAmmos(Me)
end;

procedure Think(Me: PGear);
begin
FillTargets(Targets);
Actions.Score:= 0;
Actions.Count:= 0;
Actions.Pos:= 0;
BestActions.Score:= Low(integer);
if Targets.Count > 0 then
   Walk(Me)
end;

procedure ProcessBot;
var Me: PGear;
begin
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog] do
     if (Gear <> nil)and((Gear.State and gstHHDriven) <> 0) and (TurnTimeLeft < 29990) then
        begin
        Me:= CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear;
        if BestActions.Count = BestActions.Pos then Think(Me);
        ProcessAction(BestActions, Me)
        end
end;

end.
