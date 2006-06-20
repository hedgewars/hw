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

var BestActions: TActions;
    ThinkThread: PSDL_Thread = nil;
    StopThinking: boolean;

procedure FreeActionsList;
begin
if ThinkThread <> nil then
   begin
   StopThinking:= true;
   SDL_WaitThread(ThinkThread, nil);
   ThinkThread:= nil
   end;
BestActions.Count:= 0;
BestActions.Pos:= 0
end;

procedure TestAmmos(var Actions: TActions; Me: PGear);
var Time: Longword;
    Angle, Power, Score: integer;
    i: integer;
    a, aa: TAmmoType;
begin
for i:= 0 to Pred(Targets.Count) do
    if Targets.ar[i].Score >= 0 then
       begin
       a:= Low(TAmmoType);
       aa:= a;
       repeat
        if Assigned(AmmoTests[a]) then
           begin
           Score:= AmmoTests[a](Me, Targets.ar[i].Point, Time, Angle, Power);
           if Actions.Score + Score + Targets.ar[i].Score > BestActions.Score then
              begin
              BestActions:= Actions;
              inc(BestActions.Score, Score + Targets.ar[i].Score);
              AddAction(BestActions, aia_Weapon, Longword(a), 500);
              if Time <> 0 then AddAction(BestActions, aia_Timer, Time div 1000, 400);
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
           end;
        if a = High(TAmmoType) then a:= Low(TAmmoType)
                               else inc(a)
       until isInMultiShoot or (a = aa) or (CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].AttacksNum > 0)
       end
end;

procedure Walk(Me: PGear);
var Actions: TActions;
    BackMe: TGear;
    Dir, t, avoidt, steps: integer;
begin
Actions.Score:= 0;
Actions.Count:= 0;
Actions.Pos:= 0;
BackMe:= Me^;
if (Me.State and gstAttacked) = 0 then TestAmmos(Actions, Me);
avoidt:= CheckBonuses(Me);
for Dir:= aia_Left to aia_Right do
    begin
    Me.Message:= Dir;
    steps:= 0;
    while HHGo(Me) do
       begin
       inc(steps);
       Actions.Count:= 0;
       AddAction(Actions, Dir, aim_push, 50);
       AddAction(Actions, aia_WaitX, round(Me.X), 0);
       AddAction(Actions, Dir, aim_release, 0);
       t:= CheckBonuses(Me);
       if t < avoidt then break
       else if (t > 0) or (t > avoidt) then
            begin
            BestActions:= Actions;
            exit
            end;
       if ((Me.State and gstAttacked) = 0)
       and ((steps mod 4) = 0) then TestAmmos(Actions, Me);
       if StopThinking then exit;
       end;
    Me^:= BackMe
    end
end;

procedure Think(Me: PGear); cdecl;
var BackMe: TGear;
    StartTicks: Longword;
begin
{$IFDEF DEBUGFILE}AddFileLog('Enter Think Thread');{$ENDIF}
StartTicks:= GameTicks;
ThinkingHH:= Me;
FillTargets;
FillBonuses;
BestActions.Score:= Low(integer);
if Targets.Count > 0 then
   begin
   BackMe:= Me^;
   Walk(@BackMe);
   end;
if StartTicks > GameTicks - 1000 then SDL_Delay(500);
Me.State:= Me.State and not gstHHThinking;
{$IFDEF DEBUGFILE}AddFileLog('Exit Think Thread');{$ENDIF}
ThinkThread:= nil
end;

procedure StartThink(Me: PGear);
begin
Me.State:= Me.State or gstHHThinking;
StopThinking:= false;
ThinkThread:= SDL_CreateThread(@Think, Me)
end;

procedure ProcessBot;
begin
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog] do
     if (Gear <> nil)
        and ((Gear.State and gstHHDriven) <> 0)
        and (TurnTimeLeft < 29990)
        and ((Gear.State and gstHHThinking) = 0) then
           if (BestActions.Pos = BestActions.Count) then StartThink(Gear)
                                                    else ProcessAction(BestActions, Gear)
end;

end.
