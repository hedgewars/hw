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
    CanUseAmmo: array [TAmmoType] of boolean;

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
var Time, BotLevel: Longword;
    Angle, Power, Score, ExplX, ExplY, ExplR: integer;
    i: integer;
    a, aa: TAmmoType;
begin
BotLevel:= PHedgehog(Me.Hedgehog).BotLevel;

for i:= 0 to Pred(Targets.Count) do
    if (Targets.ar[i].Score >= 0) then
       begin
       with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog] do
            a:= Ammo[CurSlot, CurAmmo].AmmoType;
       aa:= a;
       repeat
        if CanUseAmmo[a] then
           begin
           Score:= AmmoTests[a](Me, Targets.ar[i].Point, BotLevel, Time, Angle, Power, ExplX, ExplY, ExplR);
           if Actions.Score + Score > BestActions.Score then
              begin
              BestActions:= Actions;
              inc(BestActions.Score, Score);
              
              AddAction(BestActions, aia_Weapon, Longword(a), 500);
              if Time <> 0 then AddAction(BestActions, aia_Timer, Time div 1000, 400);
              if (Angle > 0) then AddAction(BestActions, aia_LookRight, 0, 200)
              else if (Angle < 0) then AddAction(BestActions, aia_LookLeft, 0, 200);
              if (Ammoz[a].Ammo.Propz and ammoprop_NoCrosshair) = 0 then
                 begin
                 Angle:= integer(Me.Angle) - Abs(Angle);
                 if Angle > 0 then
                    begin
                    AddAction(BestActions, aia_Up, aim_push, 500);
                    AddAction(BestActions, aia_Up, aim_release, Angle)
                    end else if Angle < 0 then
                    begin
                    AddAction(BestActions, aia_Down, aim_push, 500);
                    AddAction(BestActions, aia_Down, aim_release, -Angle)
                    end
                 end;
              AddAction(BestActions, aia_attack, aim_push, 800);
              AddAction(BestActions, aia_attack, aim_release, Power);
              if ExplR > 0 then
                 AddAction(BestActions, aia_AwareExpl, ExplR, 10, ExplX, ExplY);
              end
           end;
        if a = High(TAmmoType) then a:= Low(TAmmoType)
                               else inc(a)
       until (a = aa) or (CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].AttacksNum > 0)
       end
end;

procedure Walk(Me: PGear);
const FallPixForBranching = cHHRadius * 2 + 8;
      cBranchStackSize = 12;
      
type TStackEntry = record
                   WastedTicks: Longword;
                   MadeActions: TActions;
                   Hedgehog: TGear;
                   end;
                   
var Stack: record
           Count: Longword;
           States: array[0..Pred(cBranchStackSize)] of TStackEntry;
           end;

    function Push(Ticks: Longword; const Actions: TActions; const Me: TGear; Dir: integer): boolean;
    begin
    Result:= (Stack.Count < cBranchStackSize) and (Actions.Count < MAXACTIONS - 5);
    if Result then
       with Stack.States[Stack.Count] do
            begin
            WastedTicks:= Ticks;
            MadeActions:= Actions;
            Hedgehog:= Me;
            Hedgehog.Message:= Dir;
            inc(Stack.Count)
            end
    end;

    procedure Pop(out Ticks: Longword; out Actions: TActions; out Me: TGear);
    begin
    dec(Stack.Count);
    with Stack.States[Stack.Count] do
         begin
         Ticks:= WastedTicks;
         Actions:= MadeActions;
         Me:= Hedgehog
         end
    end;

    function PosInThinkStack(Me: PGear): boolean;
    var i: Longword;
    begin
    i:= 0;
    Result:= false;
    while (i < Stack.Count) and not Result do
          begin
          Result:= (abs(Stack.States[i].Hedgehog.X - Me.X) +
                    abs(Stack.States[i].Hedgehog.Y - Me.Y) <= 2)
                    and (Stack.States[i].Hedgehog.Message = Me.Message);
          inc(i)
          end
    end;


var Actions: TActions;
    ticks, maxticks, steps, BotLevel, tmp: Longword;
    BaseRate, BestRate, Rate: integer;
    GoInfo: TGoInfo;
    CanGo: boolean;
    AltMe: TGear;
begin
Actions.Count:= 0;
Actions.Pos:= 0;
Actions.Score:= 0;
Stack.Count:= 0;
BotLevel:= PHedgehog(Me.Hedgehog).BotLevel;

tmp:= random(2) + 1;
Push(0, Actions, Me^, tmp);
Push(0, Actions, Me^, tmp xor 3);

if (Me.State and gstAttacked) = 0 then maxticks:= max(0, TurnTimeLeft - 5000 - 4000 * BotLevel)
                                  else maxticks:= TurnTimeLeft;

if (Me.State and gstAttacked) = 0 then TestAmmos(Actions, Me);
BestRate:= RatePlace(Me);
BaseRate:= max(BestRate, 0);

while (Stack.Count > 0) and not StopThinking do
    begin
    Pop(ticks, Actions, Me^);

    AddAction(Actions, Me.Message, aim_push, 250);
    AddAction(Actions, aia_WaitX, round(Me.X), 0);
    AddAction(Actions, Me.Message, aim_release, 0);
    steps:= 0;

    while (not StopThinking) and (not PosInThinkStack(Me)) do
       begin
       CanGo:= HHGo(Me, @AltMe, GoInfo);
       inc(ticks, GoInfo.Ticks);
       if ticks > maxticks then break;
       
       if (BotLevel < 5) and (GoInfo.JumpType = jmpHJump) then // hjump support
          if Push(ticks, Actions, AltMe, Me^.Message) then
             with Stack.States[Pred(Stack.Count)] do
                  begin
                  AddAction(MadeActions, aia_HJump, 0, 305);
                  AddAction(MadeActions, aia_HJump, 0, 350);
                  end;
       if (BotLevel < 3) and (GoInfo.JumpType = jmpLJump) then // ljump support
          if Push(ticks, Actions, AltMe, Me^.Message) then
             with Stack.States[Pred(Stack.Count)] do
                  AddAction(MadeActions, aia_LJump, 0, 305);

       if not CanGo then break;
       inc(steps);
       Actions.actions[Actions.Count - 2].Param:= round(Me.X);
       Rate:= RatePlace(Me);
       if Rate > BestRate then
          begin
          BestActions:= Actions;
          BestRate:= Rate;
          Me.State:= Me.State or gstAttacked // we have better place, go there and don't use ammo
          end
       else if Rate < BestRate then break;
       if ((Me.State and gstAttacked) = 0)
           and ((steps mod 4) = 0) then TestAmmos(Actions, Me);
       if GoInfo.FallPix >= FallPixForBranching then
          Push(ticks, Actions, Me^, Me^.Message xor 3); // aia_Left xor 3 = aia_Right
       end;

    if BestRate > BaseRate then exit
    end
end;

procedure Think(Me: PGear); cdecl;
var BackMe, WalkMe: TGear;
    StartTicks: Longword;
begin
StartTicks:= GameTicks;
BestActions.Count:= 0;
BestActions.Pos:= 0;
BestActions.Score:= Low(integer);
BackMe:= Me^;
WalkMe:= BackMe;
if (Me.State and gstAttacked) = 0 then
   if Targets.Count > 0 then
      begin
      Walk(@WalkMe);
      if (StartTicks > GameTicks - 1500) and not StopThinking then SDL_Delay(2000);
      if BestActions.Score < -1023 then
         begin
         BestActions.Count:= 0;
         AddAction(BestActions, aia_Skip, 0, 250);
         end;
      end else
else begin
      Walk(@WalkMe);
      while (not StopThinking) and (BestActions.Count = 0) do
            begin
            SDL_Delay(100);
            FillBonuses(true);
            WalkMe:= BackMe;
            Walk(@WalkMe)
            end
      end;
Me.State:= Me.State and not gstHHThinking
end;

procedure StartThink(Me: PGear);
var a: TAmmoType;
begin
if ((Me.State and gstAttacking) <> 0) or isInMultiShoot then exit;
Me.State:= Me.State or gstHHThinking;
Me.Message:= 0;
StopThinking:= false;
ThinkingHH:= Me;
FillTargets;
if Targets.Count = 0 then
   begin
   OutError('AI: no targets!?');
   exit
   end;
FillBonuses((Me.State and gstAttacked) <> 0);
for a:= Low(TAmmoType) to High(TAmmoType) do
    CanUseAmmo[a]:= Assigned(AmmoTests[a]) and HHHasAmmo(PHedgehog(Me.Hedgehog), a);
{$IFDEF DEBUGFILE}AddFileLog('Enter Think Thread');{$ENDIF}
ThinkThread:= SDL_CreateThread(@Think, Me)
end;

procedure ProcessBot;
const StartTicks: Longword = 0;
begin
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog] do
     if (Gear <> nil)
        and ((Gear.State and gstHHDriven) <> 0)
        and (TurnTimeLeft < cHedgehogTurnTime - 50) then
        if ((Gear.State and gstHHThinking) = 0) then
           if (BestActions.Pos >= BestActions.Count) then
              begin
              StartThink(Gear);
              StartTicks:= GameTicks
              end else ProcessAction(BestActions, Gear)
        else if (GameTicks - StartTicks) > cMaxAIThinkTime then StopThinking:= true
end;

end.
