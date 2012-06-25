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

unit uAI;
interface
uses uFloat;

procedure initModule;
procedure freeModule;

procedure ProcessBot;
procedure FreeActionsList;

implementation
uses uConsts, SDLh, uAIMisc, uAIAmmoTests, uAIActions,
    uAmmos, SysUtils{$IFNDEF USE_SDLTHREADS} {$IFDEF UNIX}, cthreads{$ENDIF} {$ENDIF}, uTypes,
    uVariables, uCommands, uUtils, uDebug;

var BestActions: TActions;
    CanUseAmmo: array [TAmmoType] of boolean;
    StopThinking: boolean;
{$IFDEF USE_SDLTHREADS} 
    ThinkThread: PSDL_Thread = nil;
{$ELSE}
    ThinkThread: TThreadID;
{$ENDIF}
    hasThread: LongInt;
    StartTicks: Longword;

procedure FreeActionsList;
begin
    AddFileLog('FreeActionsList called');
    if hasThread <> 0 then
    begin
        AddFileLog('Waiting AI thread to finish');
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



const cBranchStackSize = 12;
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
var bRes: boolean;
begin
    bRes:= (Stack.Count < cBranchStackSize) and (Actions.Count < MAXACTIONS - 5);
    if bRes then
        with Stack.States[Stack.Count] do
            begin
            WastedTicks:= Ticks;
            MadeActions:= Actions;
            Hedgehog:= Me;
            Hedgehog.Message:= Dir;
            inc(Stack.Count)
            end;
    Push:= bRes
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



procedure TestAmmos(var Actions: TActions; Me: PGear; isMoved: boolean);
var BotLevel: Byte;
    ap: TAttackParams;
    Score, i, dAngle: LongInt;
    a, aa: TAmmoType;
begin
BotLevel:= Me^.Hedgehog^.BotLevel;
windSpeed:= hwFloat2Float(cWindSpeed);

for i:= 0 to Pred(Targets.Count) do
    if (Targets.ar[i].Score >= 0) and (not StopThinking) then
        begin
        with Me^.Hedgehog^ do
            a:= CurAmmoType;
        aa:= a;
{$IFDEF USE_SDLTHREADS}
        SDL_delay(0);    //ThreadSwitch was only a hint
{$ELSE}
        ThreadSwitch();
{$ENDIF}       
        repeat
        if (CanUseAmmo[a]) 
            and ((not isMoved) or ((AmmoTests[a].flags and amtest_OnTurn) = 0)) 
            and ((i = 0) or ((AmmoTests[a].flags and amtest_NoTarget) = 0)) 
            then
            begin
{$HINTS OFF}
            Score:= AmmoTests[a].proc(Me, Targets.ar[i].Point, BotLevel, ap);
{$HINTS ON}
            if Actions.Score + Score > BestActions.Score then
                if (BestActions.Score < 0) or (Actions.Score + Score > BestActions.Score + Byte(BotLevel) * 2048) then
                    begin
                    BestActions:= Actions;
                    inc(BestActions.Score, Score);
                    BestActions.isWalkingToABetterPlace:= false;

                    AddAction(BestActions, aia_Weapon, Longword(a), 300 + random(400), 0, 0);

                    if (ap.Angle > 0) then
                        AddAction(BestActions, aia_LookRight, 0, 200, 0, 0)
                    else if (ap.Angle < 0) then
                        AddAction(BestActions, aia_LookLeft, 0, 200, 0, 0);
                    
                    if (ap.Time <> 0) then
                        AddAction(BestActions, aia_Timer, ap.Time div 1000, 400, 0, 0);
                        
                    if (Ammoz[a].Ammo.Propz and ammoprop_NoCrosshair) = 0 then
                        begin
                        dAngle:= LongInt(Me^.Angle) - Abs(ap.Angle);
                        if dAngle > 0 then
                            begin
                            AddAction(BestActions, aia_Up, aim_push, 300 + random(250), 0, 0);
                            AddAction(BestActions, aia_Up, aim_release, dAngle, 0, 0)
                            end
                        else if dAngle < 0 then
                            begin
                            AddAction(BestActions, aia_Down, aim_push, 300 + random(250), 0, 0);
                            AddAction(BestActions, aia_Down, aim_release, -dAngle, 0, 0)
                            end
                        end;
                        
                    if (Ammoz[a].Ammo.Propz and ammoprop_NeedTarget) <> 0 then
                        begin
                        AddAction(BestActions, aia_Put, 0, 1, ap.AttackPutX, ap.AttackPutY)
                        end;
                        
                    if (Ammoz[a].Ammo.Propz and ammoprop_OscAim) <> 0 then
                        begin
                        AddAction(BestActions, aia_attack, aim_push, 350 + random(200), 0, 0);
                        AddAction(BestActions, aia_attack, aim_release, 1, 0, 0);
                                                
                        AddAction(BestActions, aia_Down, aim_push, 100 + random(150), 0, 0);
                        AddAction(BestActions, aia_Down, aim_release, 32, 0, 0);
                        
                        AddAction(BestActions, aia_waitAngle, ap.Angle, 250, 0, 0);
                        AddAction(BestActions, aia_attack, aim_push, 1, 0, 0);
                        AddAction(BestActions, aia_attack, aim_release, 1, 0, 0);
                        end else
                        if (Ammoz[a].Ammo.Propz and ammoprop_AttackingPut) = 0 then
                            begin
                            AddAction(BestActions, aia_attack, aim_push, 650 + random(300), 0, 0);
                            AddAction(BestActions, aia_attack, aim_release, ap.Power, 0, 0);
                            end;
                            
                    if ap.ExplR > 0 then
                        AddAction(BestActions, aia_AwareExpl, ap.ExplR, 10, ap.ExplX, ap.ExplY);
                    end
            end;
        if a = High(TAmmoType) then
            a:= Low(TAmmoType)
        else inc(a)
        until (a = aa) or (CurrentHedgehog^.MultiShootAttacks > 0) {shooting same weapon}
            or StopThinking
        end
end;

procedure Walk(Me: PGear; var Actions: TActions);
const FallPixForBranching = cHHRadius * 2 + 8;
var
    ticks, maxticks, steps, tmp: Longword;
    BaseRate, BestRate, Rate: integer;
    GoInfo: TGoInfo;
    CanGo: boolean;
    AltMe: TGear;
    BotLevel: Byte;
    a: TAmmoType;
begin
ticks:= 0; // avoid compiler hint
Stack.Count:= 0;

for a:= Low(TAmmoType) to High(TAmmoType) do
    CanUseAmmo[a]:= Assigned(AmmoTests[a].proc) and (HHHasAmmo(Me^.Hedgehog^, a) > 0);

BotLevel:= Me^.Hedgehog^.BotLevel;

if (Me^.State and gstAttacked) = 0 then
    maxticks:= Max(0, TurnTimeLeft - 5000 - LongWord(4000 * BotLevel))
else
    maxticks:= TurnTimeLeft;

if (Me^.State and gstAttacked) = 0 then
    TestAmmos(Actions, Me, false);
    
BestRate:= RatePlace(Me);
BaseRate:= Max(BestRate, 0);

// switch to 'skip' if we can't move because of mouse cursor being shown
if (Ammoz[Me^.Hedgehog^.CurAmmoType].Ammo.Propz and ammoprop_NeedTarget) <> 0 then
    AddAction(Actions, aia_Weapon, Longword(amSkip), 100 + random(200), 0, 0);
    
if ((CurrentHedgehog^.MultiShootAttacks = 0) or ((Ammoz[Me^.Hedgehog^.CurAmmoType].Ammo.Propz and ammoprop_NoMoveAfter) = 0)) 
    and (GameFlags and gfArtillery = 0) then
    begin
    tmp:= random(2) + 1;
    Push(0, Actions, Me^, tmp);
    Push(0, Actions, Me^, tmp xor 3);
    
    while (Stack.Count > 0) and (not StopThinking) do
        begin
        Pop(ticks, Actions, Me^);

        AddAction(Actions, Me^.Message, aim_push, 250, 0, 0);
        if (Me^.Message and gmLeft) <> 0 then
            AddAction(Actions, aia_WaitXL, hwRound(Me^.X), 0, 0, 0)
        else
            AddAction(Actions, aia_WaitXR, hwRound(Me^.X), 0, 0, 0);
        
        steps:= 0;

        while (not StopThinking) do
            begin
    {$HINTS OFF}
            CanGo:= HHGo(Me, @AltMe, GoInfo);
    {$HINTS ON}
            inc(ticks, GoInfo.Ticks);
            if ticks > maxticks then
                break;

            if (BotLevel < 5) and (GoInfo.JumpType = jmpHJump) then // hjump support
                if Push(ticks, Actions, AltMe, Me^.Message) then
                    with Stack.States[Pred(Stack.Count)] do
                        begin
                        if Me^.dX.isNegative then
                            AddAction(MadeActions, aia_LookRight, 0, 200, 0, 0)
                        else
                            AddAction(MadeActions, aia_LookLeft, 0, 200, 0, 0);
                            
                        AddAction(MadeActions, aia_HJump, 0, 305 + random(50), 0, 0);
                        AddAction(MadeActions, aia_HJump, 0, 350, 0, 0);
                        
                        if Me^.dX.isNegative then
                            AddAction(MadeActions, aia_LookLeft, 0, 200, 0, 0)
                        else
                            AddAction(MadeActions, aia_LookRight, 0, 200, 0, 0);
                        end;
            if (BotLevel < 3) and (GoInfo.JumpType = jmpLJump) then // ljump support
                begin
                // push current position so we proceed from it after checking jump opportunities
                if CanGo then Push(ticks, Actions, Me^, Me^.Message);
                // first check where we go after jump
                if Push(ticks, Actions, AltMe, Me^.Message) then
                    with Stack.States[Pred(Stack.Count)] do
                        AddAction(MadeActions, aia_LJump, 0, 305 + random(50), 0, 0);
                break
                end;

            // 'not CanGO' means we can't go straight, possible jumps are checked above
            if not CanGo then
                break;
            
             inc(steps);
             Actions.actions[Pred(Actions.Count)].Param:= hwRound(Me^.X);
             Rate:= RatePlace(Me);
             if Rate > BestRate then
                begin
                BestActions:= Actions;
                BestActions.isWalkingToABetterPlace:= true;
                BestRate:= Rate;
                Me^.State:= Me^.State or gstAttacked // we have better place, go there and do not use ammo
                end
            else if Rate < BestRate then
                break;
            if ((Me^.State and gstAttacked) = 0) and ((steps mod 4) = 0) then
                TestAmmos(Actions, Me, true);
            if GoInfo.FallPix >= FallPixForBranching then
                Push(ticks, Actions, Me^, Me^.Message xor 3); // aia_Left xor 3 = aia_Right
            end {while};

        if BestRate > BaseRate then
            exit
        end {while}
    end {if}
end;

function Think(Me: Pointer): ptrint;
var BackMe, WalkMe: TGear;
    switchCount: LongInt;
    StartTicks, currHedgehogIndex, itHedgehog, switchesNum, i: Longword;
    switchImmediatelyAvailable: boolean;
    Actions: TActions;
begin
InterlockedIncrement(hasThread);
StartTicks:= GameTicks;
currHedgehogIndex:= CurrentTeam^.CurrHedgehog;
itHedgehog:= currHedgehogIndex;
switchesNum:= 0;

switchImmediatelyAvailable:= (CurAmmoGear <> nil) and (CurAmmoGear^.Kind = gtSwitcher);
switchCount:= HHHasAmmo(PGear(Me)^.Hedgehog^, amSwitch);

if (PGear(Me)^.State and gstAttacked) = 0 then
    if Targets.Count > 0 then
        begin
        // iterate over current team hedgehogs
        repeat
            WalkMe:= CurrentTeam^.Hedgehogs[itHedgehog].Gear^;

            Actions.Count:= 0;
            Actions.Pos:= 0;
            Actions.Score:= 0;
            if switchesNum > 0 then
                begin
                if not switchImmediatelyAvailable  then
                    begin
                    // when AI has to use switcher, make it cost smth unless they have a lot of switches
                    if (switchCount < 10) then Actions.Score:= (-27+switchCount*3)*4000;
                    AddAction(Actions, aia_Weapon, Longword(amSwitch), 300 + random(200), 0, 0);                    
                    AddAction(Actions, aia_attack, aim_push, 300 + random(300), 0, 0);
                    AddAction(Actions, aia_attack, aim_release, 1, 0, 0);
                    end;
                for i:= 1 to switchesNum do
                    AddAction(Actions, aia_Switch, 0, 300 + random(200), 0, 0);
                end;
            Walk(@WalkMe, Actions);

            // find another hog in team
            repeat
                itHedgehog:= Succ(itHedgehog) mod CurrentTeam^.HedgehogsNumber;
            until (itHedgehog = currHedgehogIndex) or (CurrentTeam^.Hedgehogs[itHedgehog].Gear <> nil);


            inc(switchesNum);
        until (not (switchImmediatelyAvailable or (switchCount > 0)))
            or StopThinking 
            or (itHedgehog = currHedgehogIndex)
            or BestActions.isWalkingToABetterPlace;

        if (StartTicks > GameTicks - 1500) and (not StopThinking) then
            SDL_Delay(1000);

        if (BestActions.Score < -1023) and (not BestActions.isWalkingToABetterPlace) then
            begin
            BestActions.Count:= 0;
            AddAction(BestActions, aia_Skip, 0, 250, 0, 0);
            end;

        end else
else
    begin
    BackMe:= PGear(Me)^;
    while (not StopThinking) and (BestActions.Count = 0) do
        begin
        FillBonuses(true);
        WalkMe:= BackMe;
        Actions.Count:= 0;
        Actions.Pos:= 0;
        Actions.Score:= 0;
        Walk(@WalkMe, Actions);
        if not StopThinking then
            SDL_Delay(100)
        end
    end;

PGear(Me)^.State:= PGear(Me)^.State and not gstHHThinking;
Think:= 0;
InterlockedDecrement(hasThread)
end;

procedure StartThink(Me: PGear);
begin
if ((Me^.State and (gstAttacking or gstHHJumping or gstMoving)) <> 0)
or isInMultiShoot then
    exit;

//DeleteCI(Me); // this might break demo
Me^.State:= Me^.State or gstHHThinking;
Me^.Message:= 0;

BestActions.Count:= 0;
BestActions.Pos:= 0;
BestActions.Score:= Low(LongInt);
BestActions.isWalkingToABetterPlace:= false;

StopThinking:= false;
ThinkingHH:= Me;

FillTargets;
if Targets.Count = 0 then
    begin
    OutError('AI: no targets!?', false);
    exit
    end;

FillBonuses((Me^.State and gstAttacked) <> 0);
AddFileLog('Enter Think Thread');
{$IFDEF USE_SDLTHREADS}
ThinkThread := SDL_CreateThread(@Think{$IFDEF SDL13}, nil{$ENDIF}, Me);
{$ELSE}
BeginThread(@Think, Me, ThinkThread);
{$ENDIF}
AddFileLog('Thread started');
end;

//var scoreShown: boolean = false;

procedure ProcessBot;
const cStopThinkTime = 40;
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
                    
                if Gear^.Message <> 0 then
                    exit;
                    
                //scoreShown:= false;   
                StartThink(Gear);
                StartTicks:= GameTicks
                
            end else
                begin
                (*
                if not scoreShown then
                    begin
                    if BestActions.Score > 0 then ParseCommand('/say Expected score = ' + inttostr(BestActions.Score div 1024), true);
                    scoreShown:= true
                    end;*)
                ProcessAction(BestActions, Gear)
                end
        else if ((GameTicks - StartTicks) > cMaxAIThinkTime)
            or (TurnTimeLeft <= cStopThinkTime) then
                StopThinking:= true
end;

procedure initModule;
begin
    hasThread:= 0;
    StartTicks:= 0;
    ThinkThread:= ThinkThread;
end;

procedure freeModule;
begin
    FreeActionsList();
end;

end.
