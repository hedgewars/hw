(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
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
    uAmmos, uTypes,
    uVariables, uCommands, uUtils, uDebug, uAILandMarks,
    uGearsUtils;

var BestActions: TActions;
    CanUseAmmo: array [TAmmoType] of boolean;
    StopThinking: boolean;
    StartTicks: Longword;
    ThinkThread: PSDL_Thread;
    ThreadLock: PSDL_Mutex;

procedure FreeActionsList;
begin
    AddFileLog('FreeActionsList called');
    if (ThinkThread <> nil) then
        begin
        StopThinking:= true;
        SDL_WaitThread(ThinkThread, nil);
        end;
    SDL_LockMutex(ThreadLock);
    ThinkThread:= nil;
    SDL_UnlockMutex(ThreadLock);

    if CurrentHedgehog <> nil then
        with CurrentHedgehog^ do
            if Gear <> nil then
                if BotLevel <> 0 then
                    StopMessages(Gear^.Message);

    BestActions.Count:= 0;
    BestActions.Pos:= 0
end;


const cBranchStackSize = 12;
type TStackEntry = record
                   MadeActions: TActions;
                   Hedgehog: TGear;
                   end;

var Stack: record
           Count: Longword;
           States: array[0..Pred(cBranchStackSize)] of TStackEntry;
           end;

function Push(const Actions: TActions; const Me: TGear; Dir: integer): boolean;
var bRes: boolean;
begin
    bRes:= (Stack.Count < cBranchStackSize) and (Actions.Count < MAXACTIONS - 5);
    if bRes then
        with Stack.States[Stack.Count] do
            begin
            MadeActions:= Actions;
            Hedgehog:= Me;
            Hedgehog.Message:= Dir;
            inc(Stack.Count)
            end;
    Push:= bRes
end;

procedure Pop(var Actions: TActions; var Me: TGear);
begin
    dec(Stack.Count);
    with Stack.States[Stack.Count] do
        begin
        Actions:= MadeActions;
        Me:= Hedgehog
        end
end;



procedure TestAmmos(var Actions: TActions; Me: PGear; rareChecks: boolean);
var BotLevel: Byte;
    ap: TAttackParams;
    Score, i, t, n, dAngle: LongInt;
    a, aa: TAmmoType;
    useThisActions: boolean;
begin
BotLevel:= Me^.Hedgehog^.BotLevel;
windSpeed:= hwFloat2Float(cWindSpeed);
useThisActions:= false;

for i:= 0 to Pred(Targets.Count) do
    if (Targets.ar[i].Score >= 0) and (not StopThinking) then
        begin
        with Me^.Hedgehog^ do
            a:= CurAmmoType;
        aa:= a;
        SDL_delay(0); // hint to let the context switch run
        repeat
        if (CanUseAmmo[a])
            and ((not rareChecks) or ((AmmoTests[a].flags and amtest_Rare) = 0))
            and ((i = 0) or ((AmmoTests[a].flags and amtest_NoTarget) = 0))
            then
            begin
{$HINTS OFF}
            Score:= AmmoTests[a].proc(Me, Targets.ar[i], BotLevel, ap);
{$HINTS ON}
            if (Score > BadTurn) and (Actions.Score + Score > BestActions.Score) then
                if (BestActions.Score < 0) or (Actions.Score + Score > BestActions.Score + Byte(BotLevel - 1) * 2048) then
                    begin
                    if useThisActions then
                        begin
                        BestActions.Count:= Actions.Count
                        end
                    else
                        begin
                        BestActions:= Actions;
                        BestActions.isWalkingToABetterPlace:= false;
                        useThisActions:= true
                        end;

                    BestActions.Score:= Actions.Score + Score;

                    // if not between shots, activate invulnerability/vampirism if available
                    if CurrentHedgehog^.MultiShootAttacks = 0 then
                        begin
                        if (HHHasAmmo(Me^.Hedgehog^, amInvulnerable) > 0) and (Me^.Hedgehog^.Effects[heInvulnerable] = 0) then
                            begin
                            AddAction(BestActions, aia_Weapon, Longword(amInvulnerable), 80, 0, 0);
                            AddAction(BestActions, aia_attack, aim_push, 10, 0, 0);
                            AddAction(BestActions, aia_attack, aim_release, 10, 0, 0);
                            end;

                        if (HHHasAmmo(Me^.Hedgehog^, amExtraDamage) > 0) and (cDamageModifier <> _1_5) then
                            begin
                            AddAction(BestActions, aia_Weapon, Longword(amExtraDamage), 80, 0, 0);
                            AddAction(BestActions, aia_attack, aim_push, 10, 0, 0);
                            AddAction(BestActions, aia_attack, aim_release, 10, 0, 0);
                            end;
                        if (HHHasAmmo(Me^.Hedgehog^, amVampiric) > 0) and (not cVampiric) then
                            begin
                            AddAction(BestActions, aia_Weapon, Longword(amVampiric), 80, 0, 0);
                            AddAction(BestActions, aia_attack, aim_push, 10, 0, 0);
                            AddAction(BestActions, aia_attack, aim_release, 10, 0, 0);
                            end;
                        end;

                    AddAction(BestActions, aia_Weapon, Longword(a), 300 + random(400), 0, 0);

                    if (Ammoz[a].Ammo.Propz and ammoprop_NeedTarget) <> 0 then
                        begin
                        AddAction(BestActions, aia_Put, 0, 8, ap.AttackPutX, ap.AttackPutY)
                        end;

                    if (ap.Angle > 0) then
                        AddAction(BestActions, aia_LookRight, 0, 200, 0, 0)
                    else if (ap.Angle < 0) then
                        AddAction(BestActions, aia_LookLeft, 0, 200, 0, 0);

                    if (Ammoz[a].Ammo.Propz and ammoprop_Timerable) <> 0 then
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

                    if (Ammoz[a].Ammo.Propz and ammoprop_OscAim) <> 0 then
                        begin
                        AddAction(BestActions, aia_attack, aim_push, 350 + random(200), 0, 0);
                        AddAction(BestActions, aia_attack, aim_release, 1, 0, 0);

                        if abs(ap.Angle) > 32 then
                           begin
                           AddAction(BestActions, aia_Down, aim_push, 100 + random(150), 0, 0);
                           AddAction(BestActions, aia_Down, aim_release, 32, 0, 0);
                           end;

                        AddAction(BestActions, aia_waitAngle, ap.Angle, 250, 0, 0);
                        AddAction(BestActions, aia_attack, aim_push, 1, 0, 0);
                        AddAction(BestActions, aia_attack, aim_release, 1, 0, 0);
                        end else
                        if (Ammoz[a].Ammo.Propz and ammoprop_AttackingPut) = 0 then
                            begin
                            if (AmmoTests[a].flags and amtest_MultipleAttacks) = 0 then
                                n:= 1 else n:= ap.AttacksNum;

                            AddAction(BestActions, aia_attack, aim_push, 650 + random(300), 0, 0);
                            for t:= 2 to n do
                                begin
                                AddAction(BestActions, aia_attack, aim_push, 150, 0, 0);
                                AddAction(BestActions, aia_attack, aim_release, ap.Power, 0, 0);
                                end;
                            AddAction(BestActions, aia_attack, aim_release, ap.Power, 0, 0);
                            end;

                    if (Ammoz[a].Ammo.Propz and ammoprop_Track) <> 0 then
                        begin
                        AddAction(BestActions, aia_waitAmmoXY, 0, 12, ap.ExplX, ap.ExplY);
                        AddAction(BestActions, aia_attack, aim_push, 1, 0, 0);
                        AddAction(BestActions, aia_attack, aim_release, 7, 0, 0);
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
const FallPixForBranching = cHHRadius;
var
    maxticks, oldticks, steps, tmp: Longword;
    BaseRate, BestRate, Rate: LongInt;
    GoInfo: TGoInfo;
    CanGo: boolean;
    AltMe: TGear;
    BotLevel: Byte;
    a: TAmmoType;
    isAfterAttack: boolean;
begin
Actions.ticks:= 0;
oldticks:= 0; // avoid compiler hint
Stack.Count:= 0;

clearAllMarks;

for a:= Low(TAmmoType) to High(TAmmoType) do
    CanUseAmmo[a]:= Assigned(AmmoTests[a].proc) and (HHHasAmmo(Me^.Hedgehog^, a) > 0);

BotLevel:= Me^.Hedgehog^.BotLevel;

isAfterAttack:= ((Me^.State and gstAttacked) <> 0) and ((GameFlags and gfInfAttack) = 0);
if isAfterAttack then
    maxticks:= Max(0, TurnTimeLeft - 500)
else
    maxticks:= Max(0, TurnTimeLeft - 5000 - LongWord(4000 * BotLevel));

if not isAfterAttack then
    TestAmmos(Actions, Me, false);

BestRate:= RatePlace(Me);
BaseRate:= Max(BestRate, 0);

// switch to 'skip' if we cannot move because of mouse cursor being shown
if (Ammoz[Me^.Hedgehog^.CurAmmoType].Ammo.Propz and ammoprop_NeedTarget) <> 0 then
    AddAction(Actions, aia_Weapon, Longword(amSkip), 100 + random(200), 0, 0);

if ((CurrentHedgehog^.MultiShootAttacks = 0) or ((Ammoz[Me^.Hedgehog^.CurAmmoType].Ammo.Propz and ammoprop_NoMoveAfter) = 0))
    and (CurrentHedgehog^.Effects[heArtillery] = 0) and (cGravityf <> 0) then
    begin
    tmp:= random(2) + 1;
    Push(Actions, Me^, tmp);
    Push(Actions, Me^, tmp xor 3);

    while (Stack.Count > 0) and (not StopThinking) do
        begin
        Pop(Actions, Me^);

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
            oldticks:= Actions.ticks;
            inc(Actions.ticks, GoInfo.Ticks);
            if (Actions.ticks > maxticks) or (TurnTimeLeft < BestActions.ticks + 5000) then
            begin
                if (BotLevel < 5)
                        and (not isAfterAttack)
                        and (BestActions.Score > 0) // we have a good move
                        and (TurnTimeLeft < BestActions.ticks + 5000) // we won't have a lot of time after attack
                        and (HHHasAmmo(Me^.Hedgehog^, amExtraTime) > 0) // but can use extra time
                then
                begin
                    BestActions.Count:= 0;
                    AddAction(BestActions, aia_Weapon, Longword(amExtraTime), 80, 0, 0);
                    AddAction(BestActions, aia_attack, aim_push, 10, 0, 0);
                    AddAction(BestActions, aia_attack, aim_release, 10, 0, 0);
                end;

                break;
            end;

            if (BotLevel < 5)
                and (GoInfo.JumpType = jmpHJump)
                and (not checkMark(hwRound(Me^.X), hwRound(Me^.Y), markHJumped))
                then // hjump support
                begin
                // check if we could go backwards and maybe ljump over a gap after this hjump
                addMark(hwRound(Me^.X), hwRound(Me^.Y), markHJumped);
                if Push(Actions, AltMe, Me^.Message xor 3) then
                    begin
                    with Stack.States[Pred(Stack.Count)] do
                        begin
                        if (Me^.Message and gmLeft) <> 0 then
                            AddAction(MadeActions, aia_LookRight, 0, 200, 0, 0)
                        else
                            AddAction(MadeActions, aia_LookLeft, 0, 200, 0, 0);

                        AddAction(MadeActions, aia_HJump, 0, 305 + random(50), 0, 0);
                        AddAction(MadeActions, aia_HJump, 0, 350, 0, 0);
                        end;
                    // but first check walking forward
                    Push(Stack.States[Pred(Stack.Count)].MadeActions, AltMe, Me^.Message)
                    end;
                end;
            if (BotLevel < 3)
                and (GoInfo.JumpType = jmpLJump)
                and (not checkMark(hwRound(Me^.X), hwRound(Me^.Y), markLJumped))
                then // ljump support
                begin
                addMark(hwRound(Me^.X), hwRound(Me^.Y), markLJumped);
                // at final check where we go after jump walking backward
                if Push(Actions, AltMe, Me^.Message xor 3) then
                    with Stack.States[Pred(Stack.Count)] do
                        begin
                        if (Me^.Message and gmLeft) <> 0 then
                            AddAction(MadeActions, aia_LookLeft, 0, 200, 0, 0)
                        else
                            AddAction(MadeActions, aia_LookRight, 0, 200, 0, 0);

                        AddAction(MadeActions, aia_LJump, 0, 305 + random(50), 0, 0);
                        end;

                // push current position so we proceed from it after checking jump+forward walk opportunities
                if CanGo then Push(Actions, Me^, Me^.Message);

                // first check where we go after jump walking forward
                if Push(Actions, AltMe, Me^.Message) then
                    with Stack.States[Pred(Stack.Count)] do
                        AddAction(MadeActions, aia_LJump, 0, 305 + random(50), 0, 0);

                break
                end;

            // 'not CanGO' means we cannot go straight, possible jumps are checked above
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
                isAfterAttack:= true // we have better place, go there and do not use ammo
                end
            else if Rate < BestRate then
                break;

            if (not isAfterAttack) and ((steps mod 4) = 0) then
                begin
                if (steps > 4) and checkMark(hwRound(Me^.X), hwRound(Me^.Y), markWalkedHere) then
                    break;
                addMark(hwRound(Me^.X), hwRound(Me^.Y), markWalkedHere);

                TestAmmos(Actions, Me, Actions.ticks shr 12 = oldticks shr 12);
                end;

            if GoInfo.FallPix >= FallPixForBranching then
                Push(Actions, Me^, Me^.Message xor 3); // aia_Left xor 3 = aia_Right
            end {while};

        if BestRate > BaseRate then
            exit
        end {while}
    end {if}
end;

function Think(Me: PGear): LongInt; cdecl; export;
var BackMe, WalkMe: TGear;
    switchCount: LongInt;
    currHedgehogIndex, itHedgehog, switchesNum, i: Longword;
    switchImmediatelyAvailable: boolean;
    Actions: TActions;
begin
dmgMod:= 0.01 * hwFloat2Float(cDamageModifier) * cDamagePercent;
StartTicks:= GameTicks;

currHedgehogIndex:= CurrentTeam^.CurrHedgehog;
itHedgehog:= currHedgehogIndex;
switchesNum:= 0;

switchImmediatelyAvailable:= (CurAmmoGear <> nil) and (CurAmmoGear^.Kind = gtSwitcher);
if Me^.Hedgehog^.BotLevel <> 5 then
    switchCount:= HHHasAmmo(PGear(Me)^.Hedgehog^, amSwitch)
else switchCount:= 0;

if ((Me^.State and gstAttacked) = 0) or isInMultiShoot or bonuses.activity then
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
                if (not switchImmediatelyAvailable)  then
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
            until (itHedgehog = currHedgehogIndex) or ((CurrentTeam^.Hedgehogs[itHedgehog].Gear <> nil) and (CurrentTeam^.Hedgehogs[itHedgehog].Effects[heFrozen]=0));

            inc(switchesNum);
        until (not (switchImmediatelyAvailable or (switchCount > 0)))
            or StopThinking
            or (itHedgehog = currHedgehogIndex)
            or BestActions.isWalkingToABetterPlace;

        if (StartTicks > GameTicks - 1500) and (not StopThinking) then
            SDL_Delay(700);

        if (BestActions.Score < -1023) and (not BestActions.isWalkingToABetterPlace) then
            begin
            BestActions.Count:= 0;

            FillBonuses(false);

            // Hog has no idea what to do. Use tardis or skip
            if not bonuses.activity then
                if (((GameFlags and gfInfAttack) <> 0) or (not isInMultiShoot)) and ((HHHasAmmo(Me^.Hedgehog^, amTardis) > 0)) and (CanUseTardis(Me^.Hedgehog^.Gear)) and (random(4) < 3) then
                    // Tardis brings hog to a random place. Perfect for clueless AI
                    begin
                    AddAction(BestActions, aia_Weapon, Longword(amTardis), 80, 0, 0);
                    AddAction(BestActions, aia_attack, aim_push, 10, 0, 0);
                    AddAction(BestActions, aia_attack, aim_release, 10, 0, 0);
                    end
                else
                    AddAction(BestActions, aia_Skip, 0, 250, 0, 0);
            end;

        end else SDL_Delay(100)
else
    begin
    BackMe:= Me^;
    i:= 4;
    while (not StopThinking) and (BestActions.Count = 0) and (i > 0) do
        begin

(*
        // Maybe this would get a bit of movement out of them? Hopefully not *toward* water. Need to check how often he'd choose that strategy
        if SuddenDeathDmg and ((hwRound(BackMe.Y)+cWaterRise*2) > cWaterLine) then
            AddBonus(hwRound(BackMe.X), hwRound(BackMe.Y), 250, -40);
*)

        FillBonuses(true);
        WalkMe:= BackMe;
        Actions.Count:= 0;
        Actions.Pos:= 0;
        Actions.Score:= 0;
        Walk(@WalkMe, Actions);
        if not bonuses.activity then dec(i);
        if not StopThinking then
            SDL_Delay(100)
        end
    end;

Me^.State:= Me^.State and (not gstHHThinking);
SDL_LockMutex(ThreadLock);
ThinkThread:= nil;
SDL_UnlockMutex(ThreadLock);
Think:= 0;
end;

procedure StartThink(Me: PGear);
begin
if ((Me^.State and (gstAttacking or gstHHJumping or gstMoving)) <> 0)
or isInMultiShoot then
    exit;

//DeleteCI(Me); // this will break demo/netplay

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

FillBonuses(((Me^.State and gstAttacked) <> 0) and (not isInMultiShoot) and ((GameFlags and gfInfAttack) = 0));

SDL_LockMutex(ThreadLock);
ThinkThread:= SDL_CreateThread(@Think, PChar('think'), Me);
SDL_UnlockMutex(ThreadLock);
end;

{$IFDEF DEBUGAI}
var scoreShown: boolean = false;
{$ENDIF}

procedure ProcessBot;
const cStopThinkTime = 40;
begin
with CurrentHedgehog^ do
    if (Gear <> nil)
    and ((Gear^.State and gstHHDriven) <> 0)
    and ((TurnTimeLeft < cHedgehogTurnTime - 50) or (TurnTimeLeft > cHedgehogTurnTime)) then
        if ((Gear^.State and gstHHThinking) = 0) then
            if (BestActions.Pos >= BestActions.Count)
            and (TurnTimeLeft > cStopThinkTime) then
                begin
                if Gear^.Message <> 0 then
                    begin
                    StopMessages(Gear^.Message);
                    if checkFails((Gear^.Message and gmAllStoppable) = 0, 'Engine bug: AI may break demos playing', true) then exit;
                    end;

                if Gear^.Message <> 0 then
                    exit;

{$IFDEF DEBUGAI}
                scoreShown:= false;
{$ENDIF}
                StartThink(Gear);
                StartTicks:= GameTicks

            end else
                begin
{$IFDEF DEBUGAI}
                if not scoreShown then
                    begin
                    if BestActions.Score > 0 then ParseCommand('/say Expected score = ' + inttostr(BestActions.Score div 1024), true);
                    scoreShown:= true
                    end;
{$ENDIF}
                ProcessAction(BestActions, Gear)
                end
        else if ((GameTicks - StartTicks) > cMaxAIThinkTime)
            or (TurnTimeLeft <= cStopThinkTime) then
                StopThinking:= true
end;

procedure initModule;
begin
    StartTicks:= 0;
    ThinkThread:= nil;
    ThreadLock:= SDL_CreateMutex();
end;

procedure freeModule;
begin
    FreeActionsList();
    SDL_DestroyMutex(ThreadLock);
end;

end.
