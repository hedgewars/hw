(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2005-2008 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uAI;
interface
uses uFloat;
{$INCLUDE options.inc}
procedure ProcessBot;
procedure FreeActionsList;

implementation
uses uTeams, uConsts, SDLh, uAIMisc, uGears, uAIAmmoTests, uAIActions, uMisc,
     uAmmos, uConsole, uCollisions, SysUtils{$IFDEF UNIX}, cthreads{$ENDIF};

var BestActions: TActions;
    CanUseAmmo: array [TAmmoType] of boolean;
    StopThinking: boolean;
    ThinkThread: TThreadID;
    hasThread: LongInt = 0;

procedure FreeActionsList;
begin
{$IFDEF DEBUGFILE}AddFileLog('FreeActionsList called');{$ENDIF}
if hasThread <> 0 then
   begin
   {$IFDEF DEBUGFILE}AddFileLog('Waiting AI thread to finish');{$ENDIF}
   StopThinking:= true;
   repeat
     SDL_Delay(10)
   until hasThread = 0
   end;

with CurrentHedgehog^ do
     if Gear <> nil then
        if BotLevel <> 0 then
           StopMessages(Gear^.Message);

BestActions.Count:= 0;
BestActions.Pos:= 0
end;

procedure TestAmmos(var Actions: TActions; Me: PGear; isMoved: boolean);
var BotLevel: Longword;
    ap: TAttackParams;
    Score, i: LongInt;
    a, aa: TAmmoType;
begin
BotLevel:= PHedgehog(Me^.Hedgehog)^.BotLevel;

for i:= 0 to Pred(Targets.Count) do
    if (Targets.ar[i].Score >= 0) and (not StopThinking) then
       begin
       with CurrentHedgehog^ do
            a:= Ammo^[CurSlot, CurAmmo].AmmoType;
       aa:= a;
       repeat
        if (CanUseAmmo[a]) and
           ((not isMoved) or ((AmmoTests[a].flags and amtest_OnTurn) = 0)) then
           begin
           Score:= AmmoTests[a].proc(Me, Targets.ar[i].Point, BotLevel, ap);
           if Actions.Score + Score > BestActions.Score then
            if (BestActions.Score < 0) or (Actions.Score + Score > BestActions.Score + LongInt(BotLevel) * 2048) then
              begin
              BestActions:= Actions;
              inc(BestActions.Score, Score);

              AddAction(BestActions, aia_Weapon, Longword(a), 300 + random(400), 0, 0);
              if (ap.Time <> 0) then AddAction(BestActions, aia_Timer, ap.Time div 1000, 400, 0, 0);
              if (ap.Angle > 0) then AddAction(BestActions, aia_LookRight, 0, 200, 0, 0)
              else if (ap.Angle < 0) then AddAction(BestActions, aia_LookLeft, 0, 200, 0, 0);
              if (Ammoz[a].Ammo.Propz and ammoprop_NoCrosshair) = 0 then
                 begin
                 ap.Angle:= LongInt(Me^.Angle) - Abs(ap.Angle);
                 if ap.Angle > 0 then
                    begin
                    AddAction(BestActions, aia_Up, aim_push, 300 + random(250), 0, 0);
                    AddAction(BestActions, aia_Up, aim_release, ap.Angle, 0, 0)
                    end else if ap.Angle < 0 then
                    begin
                    AddAction(BestActions, aia_Down, aim_push, 300 + random(250), 0, 0);
                    AddAction(BestActions, aia_Down, aim_release, -ap.Angle, 0, 0)
                    end
                 end;
              if (Ammoz[a].Ammo.Propz and ammoprop_NeedTarget) <> 0 then
                 begin
                 AddAction(BestActions, aia_Put, 0, 1, ap.AttackPutX, ap.AttackPutY)
                 end;
              if (Ammoz[a].Ammo.Propz and ammoprop_AttackingPut) = 0 then
                 begin
                 AddAction(BestActions, aia_attack, aim_push, 650 + random(300), 0, 0);
                 AddAction(BestActions, aia_attack, aim_release, ap.Power, 0, 0);
                 end;
              if ap.ExplR > 0 then
                 AddAction(BestActions, aia_AwareExpl, ap.ExplR, 10, ap.ExplX, ap.ExplY);
              end
           end;
        if a = High(TAmmoType) then a:= Low(TAmmoType)
                               else inc(a)
       until (a = aa) or
             (CurrentHedgehog^.AttacksNum > 0) or
             StopThinking
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
    var Result: boolean;
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
            end;
    Push:= Result
    end;

    procedure Pop(var Ticks: Longword; var Actions: TActions; var Me: TGear);
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
    while (i < Stack.Count) do
          begin
          if(not(hwAbs(Stack.States[i].Hedgehog.X - Me^.X) +
                 hwAbs(Stack.States[i].Hedgehog.Y - Me^.Y) > _2)) and
              (Stack.States[i].Hedgehog.Message = Me^.Message) then exit(true);
          inc(i)
          end;
    PosInThinkStack:= false
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
BotLevel:= PHedgehog(Me^.Hedgehog)^.BotLevel;

tmp:= random(2) + 1;
Push(0, Actions, Me^, tmp);
Push(0, Actions, Me^, tmp xor 3);

if (Me^.State and gstAttacked) = 0 then maxticks:= max(0, TurnTimeLeft - 5000 - 4000 * BotLevel)
                                   else maxticks:= TurnTimeLeft;

if (Me^.State and gstAttacked) = 0 then TestAmmos(Actions, Me, false);
BestRate:= RatePlace(Me);
BaseRate:= max(BestRate, 0);

while (Stack.Count > 0) and not StopThinking do
    begin
    Pop(ticks, Actions, Me^);

    AddAction(Actions, Me^.Message, aim_push, 250, 0, 0);
    if (Me^.Message and gm_Left) <> 0 then AddAction(Actions, aia_WaitXL, hwRound(Me^.X), 0, 0, 0)
                                      else AddAction(Actions, aia_WaitXR, hwRound(Me^.X), 0, 0, 0);
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
                  if Me^.dX.isNegative then AddAction(MadeActions, aia_LookRight, 0, 200, 0, 0)
                                       else AddAction(MadeActions, aia_LookLeft, 0, 200, 0, 0);
                  AddAction(MadeActions, aia_HJump, 0, 305 + random(50), 0, 0);
                  AddAction(MadeActions, aia_HJump, 0, 350, 0, 0);
                  if Me^.dX.isNegative then AddAction(MadeActions, aia_LookLeft, 0, 200, 0, 0)
                                       else AddAction(MadeActions, aia_LookRight, 0, 200, 0, 0);
                  end;
       if (BotLevel < 3) and (GoInfo.JumpType = jmpLJump) then // ljump support
          if Push(ticks, Actions, AltMe, Me^.Message) then
             with Stack.States[Pred(Stack.Count)] do
                  AddAction(MadeActions, aia_LJump, 0, 305 + random(50), 0, 0);

       if not CanGo then break;
       inc(steps);
       Actions.actions[Pred(Actions.Count)].Param:= hwRound(Me^.X);
       Rate:= RatePlace(Me);
       if Rate > BestRate then
          begin
          BestActions:= Actions;
          BestRate:= Rate;
          Me^.State:= Me^.State or gstAttacked // we have better place, go there and do not use ammo
          end
       else if Rate < BestRate then break;
       if ((Me^.State and gstAttacked) = 0)
           and ((steps mod 4) = 0) then TestAmmos(Actions, Me, true);
       if GoInfo.FallPix >= FallPixForBranching then
          Push(ticks, Actions, Me^, Me^.Message xor 3); // aia_Left xor 3 = aia_Right
       end;

    if BestRate > BaseRate then exit
    end
end;

function Think(Me: Pointer): ptrint;
var BackMe, WalkMe: TGear;
    StartTicks: Longword;
begin
InterlockedIncrement(hasThread);
StartTicks:= GameTicks;
BackMe:= PGear(Me)^;

if (PGear(Me)^.State and gstAttacked) = 0 then
   if Targets.Count > 0 then
      begin
      WalkMe:= BackMe;
      Walk(@WalkMe);
      if (StartTicks > GameTicks - 1500) and not StopThinking then SDL_Delay(2000);
      if BestActions.Score < -1023 then
         begin
         BestActions.Count:= 0;
         AddAction(BestActions, aia_Skip, 0, 250, 0, 0);
         end;
      end else
else begin
      while (not StopThinking) and (BestActions.Count = 0) do
            begin
            FillBonuses(true);
            WalkMe:= BackMe;
            Walk(@WalkMe);
            if not StopThinking then SDL_Delay(100)
            end
      end;
PGear(Me)^.State:= PGear(Me)^.State and not gstHHThinking;
Think:= 0;
InterlockedDecrement(hasThread)
end;

procedure StartThink(Me: PGear);
var a: TAmmoType;
begin
if ((Me^.State and (gstAttacking or gstHHJumping or gstMoving)) <> 0)
   or isInMultiShoot then exit;

//DeleteCI(Me); // this might break demo
Me^.State:= Me^.State or gstHHThinking;
Me^.Message:= 0;

BestActions.Count:= 0;
BestActions.Pos:= 0;
BestActions.Score:= Low(integer);

StopThinking:= false;
ThinkingHH:= Me;

FillTargets;
if Targets.Count = 0 then
   begin
   OutError('AI: no targets!?', false);
   exit
   end;

FillBonuses((Me^.State and gstAttacked) <> 0);
for a:= Low(TAmmoType) to High(TAmmoType) do
    CanUseAmmo[a]:= Assigned(AmmoTests[a].proc) and HHHasAmmo(PHedgehog(Me^.Hedgehog)^, a);
{$IFDEF DEBUGFILE}AddFileLog('Enter Think Thread');{$ENDIF}
BeginThread(@Think, Me, ThinkThread)
end;

procedure ProcessBot;
const StartTicks: Longword = 0;
      cStopThinkTime = 40;
begin
with CurrentHedgehog^ do
     if (Gear <> nil)
        and ((Gear^.State and gstHHDriven) <> 0)
        and (TurnTimeLeft < cHedgehogTurnTime - 50) then
        if ((Gear^.State and gstHHThinking) = 0) then
           if (BestActions.Pos >= BestActions.Count)
              and (TurnTimeLeft > cStopThinkTime) then
              begin
              if Gear^.Message <> 0 then
                 begin
                 StopMessages(Gear^.Message);
                 TryDo((Gear^.Message and gmAllStoppable) = 0, 'Engine bug: AI may break demos playing', true);
                 end;
              if Gear^.Message <> 0 then exit;
              StartThink(Gear);
              StartTicks:= GameTicks
              end else ProcessAction(BestActions, Gear)
        else if ((GameTicks - StartTicks) > cMaxAIThinkTime)
                or (TurnTimeLeft <= cStopThinkTime) then StopThinking:= true
end;

end.
