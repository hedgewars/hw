(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005-2007 Andrey Korotaev <unC0Rr@gmail.com>
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
procedure ProcessBot(FrameNo: Longword);
procedure FreeActionsList;

implementation
uses uTeams, uConsts, SDLh, uAIMisc, uGears, uAIAmmoTests, uAIActions, uMisc,
     uAIThinkStack, uAmmos;

var BestActions: TActions;
    CanUseAmmo: array [TAmmoType] of boolean;
    AIThinkStart: Longword;
    isThinking: boolean = false;

procedure FreeActionsList;
begin
isThinking:= false;
BestActions.Count:= 0;
BestActions.Pos:= 0
end;

procedure TestAmmos(var Actions: TActions; Me: PGear);
var Time, BotLevel: Longword;
    Angle, Power, Score, ExplX, ExplY, ExplR: LongInt;
    i: LongInt;
    a, aa: TAmmoType;
begin
BotLevel:= PHedgehog(Me^.Hedgehog)^.BotLevel;
for i:= 0 to Pred(Targets.Count) do
    if (Targets.ar[i].Score >= 0) then
       begin
       with CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog] do
            a:= Ammo^[CurSlot, CurAmmo].AmmoType;
       aa:= a;
       repeat
        if CanUseAmmo[a] then
           begin
           Score:= AmmoTests[a](Me, Targets.ar[i].Point, BotLevel, Time, Angle, Power, ExplX, ExplY, ExplR);
           if Actions.Score + Score > BestActions.Score then
              begin
              BestActions:= Actions;
              inc(BestActions.Score, Score);

              AddAction(BestActions, aia_Weapon, Longword(a), 500, 0, 0);
              if Time <> 0 then AddAction(BestActions, aia_Timer, Time div 1000, 400, 0, 0);
              if (Angle > 0) then AddAction(BestActions, aia_LookRight, 0, 200, 0, 0)
              else if (Angle < 0) then AddAction(BestActions, aia_LookLeft, 0, 200, 0, 0);
              if (Ammoz[a].Ammo.Propz and ammoprop_NoCrosshair) = 0 then
                 begin
                 Angle:= LongInt(Me^.Angle) - Abs(Angle);
                 if Angle > 0 then
                    begin
                    AddAction(BestActions, aia_Up, aim_push, 500, 0, 0);
                    AddAction(BestActions, aia_Up, aim_release, Angle, 0, 0)
                    end else if Angle < 0 then
                    begin
                    AddAction(BestActions, aia_Down, aim_push, 500, 0, 0);
                    AddAction(BestActions, aia_Down, aim_release, -Angle, 0, 0)
                    end
                 end;
              AddAction(BestActions, aia_attack, aim_push, 800, 0, 0);
              AddAction(BestActions, aia_attack, aim_release, Power, 0, 0);
              if ExplR > 0 then
                 AddAction(BestActions, aia_AwareExpl, ExplR, 10, ExplX, ExplY);
              end
           end;
        if a = High(TAmmoType) then a:= Low(TAmmoType)
                               else inc(a)
       until (a = aa) or (PHedgehog(Me^.Hedgehog)^.AttacksNum > 0)
       end
end;

procedure Walk(Me: PGear);
const FallPixForBranching = cHHRadius * 2 + 8;
      
var Actions: TActions;
    ticks, maxticks, steps, BotLevel: Longword;
    BaseRate, Rate: LongInt;
    GoInfo: TGoInfo;
    CanGo: boolean;
    AltMe: TGear;
begin
BotLevel:= PHedgehog(Me^.Hedgehog)^.BotLevel;

if (Me^.State and gstAttacked) = 0 then maxticks:= max(0, TurnTimeLeft - 5000 - 4000 * BotLevel)
                                  else maxticks:= TurnTimeLeft;

BaseRate:= RatePlace(Me);

repeat
    if not Pop(ticks, Actions, Me^) then
       begin
       isThinking:= false;
       exit
       end;

    AddAction(Actions, Me^.Message, aim_push, 10, 0, 0);
    if (Me^.Message and gm_Left) <> 0 then AddAction(Actions, aia_WaitXL, hwRound(Me^.X), 0, 0, 0)
                                      else AddAction(Actions, aia_WaitXR, hwRound(Me^.X), 0, 0, 0);
    AddAction(Actions, Me^.Message, aim_release, 0, 0, 0);
    steps:= 0;
    if ((Me^.State and gstAttacked) = 0) then TestAmmos(Actions, Me);

    while not PosInThinkStack(Me) do
       begin
       CanGo:= HHGo(Me, @AltMe, GoInfo);
       inc(ticks, GoInfo.Ticks);
       if ticks > maxticks then break;

       if (BotLevel < 5) and (GoInfo.JumpType = jmpHJump) then // hjump support
          if Push(ticks, Actions, AltMe, Me^.Message) then
             with ThinkStack.States[Pred(ThinkStack.Count)] do
                  begin
                  AddAction(MadeActions, aia_HJump, 0, 305, 0, 0);
                  AddAction(MadeActions, aia_HJump, 0, 350, 0, 0);
                  if (Me^.dX < 0) then AddAction(MadeActions, aia_WaitXL, hwRound(AltMe.X), 0, 0, 0)
                                  else AddAction(MadeActions, aia_WaitXR, hwRound(AltMe.X), 0, 0, 0);
                  end;
       if (BotLevel < 3) and (GoInfo.JumpType = jmpLJump) then // ljump support
          if Push(ticks, Actions, AltMe, Me^.Message) then
             with ThinkStack.States[Pred(ThinkStack.Count)] do
                  begin
                  AddAction(MadeActions, aia_LJump, 0, 305, 0, 0);
                  if (Me^.dX < 0) then AddAction(MadeActions, aia_WaitXL, hwRound(AltMe.X), 0, 0, 0)
                                  else AddAction(MadeActions, aia_WaitXR, hwRound(AltMe.X), 0, 0, 0);
                  end;
       if not CanGo then break;
       inc(steps);
       Actions.actions[Actions.Count - 2].Param:= hwRound(Me^.X);
       Rate:= RatePlace(Me);
       if Rate > BaseRate then
          begin
          BestActions:= Actions;
          BestActions.Score:= 1;
          isThinking:= false;
          exit
          end
       else if Rate < BaseRate then break;
       if GoInfo.FallPix >= FallPixForBranching then
          Push(ticks, Actions, Me^, Me^.Message xor 3); // aia_Left xor 3 = aia_Right

       if ((Me^.State and gstAttacked) = 0)
           and ((steps mod 4) = 0) then
           begin
           TestAmmos(Actions, Me);
           if SDL_GetTicks - AIThinkStart >= Pred(cTimerInterval) then
              begin
              dec(Actions.Count, 3);
              Push(ticks, Actions, Me^, Me^.Message);
              exit
              end
           end
       end;
until false
end;

procedure Think(Me: PGear);
var BackMe, WalkMe: TGear;
begin
AIThinkStart:= SDL_GetTicks;
BackMe:= Me^;
WalkMe:= BackMe;
if (Me^.State and gstAttacked) = 0 then
   if Targets.Count > 0 then
      begin
      Walk(@WalkMe);
      if not isThinking then
         begin
         if BestActions.Score < -1023 then
            begin
            BestActions.Count:= 0;
            AddAction(BestActions, aia_Skip, 0, 250, 0, 0);
            end;
         Me^.State:= Me^.State and not gstHHThinking
         end
      end else
else begin
      FillBonuses(true);
      Walk(@WalkMe);
      AddAction(BestActions, aia_Wait, GameTicks + 100, 100, 0, 0);
      end
end;

procedure StartThink(Me: PGear);
var a: TAmmoType;
    tmp: LongInt;
begin
if ((Me^.State and gstAttacking) <> 0) or isInMultiShoot then exit;
ThinkingHH:= Me;
isThinking:= true;

ClearThinkStack;

Me^.State:= Me^.State or gstHHThinking;
Me^.Message:= 0;
FillTargets;
if Targets.Count = 0 then
   begin
   OutError('AI: no targets!?', false);
   exit
   end;

FillBonuses((Me^.State and gstAttacked) <> 0);

for a:= Low(TAmmoType) to High(TAmmoType) do
    CanUseAmmo[a]:= Assigned(AmmoTests[a]) and HHHasAmmo(PHedgehog(Me^.Hedgehog), a);

BestActions.Count:= 0;
BestActions.Pos:= 0;
BestActions.Score:= 0;
tmp:= random(2) + 1;
Push(0, BestActions, Me^, tmp);
Push(0, BestActions, Me^, tmp xor 3);
BestActions.Score:= Low(LongInt);

Think(Me)
end; 

procedure ProcessBot(FrameNo: Longword);
const LastFrameNo: Longword = 0;
begin
with CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog] do
     if (Gear <> nil)
        and ((Gear^.State and gstHHDriven) <> 0)
        and (TurnTimeLeft < cHedgehogTurnTime - 50) then
        if not isThinking then
           if (BestActions.Pos >= BestActions.Count) then StartThink(Gear)
                                                     else ProcessAction(BestActions, Gear)
        else if FrameNo <> LastFrameNo then
                begin
                LastFrameNo:= FrameNo;
                Think(Gear)
                end;
end;

end.
