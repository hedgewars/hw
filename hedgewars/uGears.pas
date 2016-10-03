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

unit uGears;
(*
 * This unit defines the behavior of gears.
 *
 * Gears are "things"/"objects" that may be visible to the player or not,
 * but always have an effect on the course of the game.
 *
 * E.g.: weapons, hedgehogs, etc.
 *
 * Note: The visual appearance of gears is defined in the unit "uGearsRender".
 *
 * Note: Gears that do not have an effect on the game but are just visual
 *       effects are called "Visual Gears" and defined in the respective unit!
 *)
interface
uses uConsts, uFloat, uTypes, uChat, uCollisions;

procedure initModule;
procedure freeModule;
function  SpawnCustomCrateAt(x, y: LongInt; crate: TCrateType; content, cnt: Longword): PGear;
function  SpawnFakeCrateAt(x, y: LongInt; crate: TCrateType; explode: boolean; poison: boolean ): PGear;
procedure ProcessGears;
procedure EndTurnCleanup;
procedure DrawGears;
procedure FreeGearsList;
procedure AddMiscGears;
procedure AssignHHCoords;
function  GearByUID(uid : Longword) : PGear;

implementation
uses uStore, uSound, uTeams, uRandom, uIO, uLandGraphics,
    {$IFDEF USE_TOUCH_INTERFACE}uTouch,{$ENDIF}
    uLocale, uAmmos, uStats, uVisualGears, uScript, uVariables,
    uCommands, uUtils, uTextures, uRenderUtils, uGearsRender, uCaptions, uDebug,
    uGearsHedgehog, uGearsUtils, uGearsList, uGearsHandlersRope
    , uVisualGearsList, uGearsHandlersMess, uAI;

var skipFlag: boolean;

var delay: LongWord;
    delay2: LongWord;
    step: (stDelay, stChDmg, stSweep, stTurnReact,
    stAfterDelay, stChWin, stWater, stChWin2, stHealth,
    stSpawn, stNTurn);
    NewTurnTick: LongWord;
    //SDMusic: shortstring;

function CheckNoDamage: boolean; // returns TRUE in case of no damaged hhs
var Gear: PGear;
    dmg: LongInt;
begin
CheckNoDamage:= true;
Gear:= GearsList;
while Gear <> nil do
    begin
    if (Gear^.Kind = gtHedgehog) and (((GameFlags and gfInfAttack) = 0) or ((Gear^.dX.QWordValue < _0_000004.QWordValue)
    and (Gear^.dY.QWordValue < _0_000004.QWordValue))) then
        begin
        if (not isInMultiShoot) then
            inc(Gear^.Damage, Gear^.Karma);
        if (Gear^.Damage <> 0) and ((Gear^.Hedgehog^.Effects[heInvulnerable] = 0)) then
            begin
            CheckNoDamage:= false;

            dmg:= Gear^.Damage;
            if Gear^.Health < dmg then
                begin
                Gear^.Active:= true;
                Gear^.Health:= 0
                end
            else
                dec(Gear^.Health, dmg);
(*
This doesn't fit well w/ the new loser sprite which is cringing from an attack.
            if (Gear^.Hedgehog^.Team = CurrentTeam) and (Gear^.Damage <> Gear^.Karma)
            and (not Gear^.Hedgehog^.King) and (Gear^.Hedgehog^.Effects[hePoisoned] = 0) and (not SuddenDeathDmg) then
                Gear^.State:= Gear^.State or gstLoser;
*)

            spawnHealthTagForHH(Gear, dmg);

            RenderHealth(Gear^.Hedgehog^);
            RecountTeamHealth(Gear^.Hedgehog^.Team);

            end;
        if (not isInMultiShoot) then
            Gear^.Karma:= 0;
        Gear^.Damage:= 0
        end;
    Gear:= Gear^.NextGear
    end;
end;

procedure HealthMachine;
var Gear: PGear;
    team: PTeam;
    i: LongWord;
    flag: Boolean;
    tmp: LongWord;
begin
    Gear:= GearsList;

    while Gear <> nil do
    begin
        if Gear^.Kind = gtHedgehog then
            begin
            tmp:= 0;
            if (Gear^.Hedgehog^.Effects[hePoisoned] <> 0) and (Gear^.Hedgehog^.Effects[heFrozen] = 0) then
                begin
                inc(tmp, ModifyDamage(Gear^.Hedgehog^.Effects[hePoisoned], Gear));
                if (GameFlags and gfResetHealth) <> 0 then
                    dec(Gear^.Hedgehog^.InitialHealth)  // does not need a minimum check since <= 1 basically disables it
                end;
            if (TotalRounds > cSuddenDTurns - 1) then
                begin
                inc(tmp, cHealthDecrease);
                if (GameFlags and gfResetHealth) <> 0 then
                    dec(Gear^.Hedgehog^.InitialHealth, cHealthDecrease)
                end;
            if Gear^.Hedgehog^.King then
                begin
                flag:= false;
                team:= Gear^.Hedgehog^.Team;
                for i:= 0 to Pred(team^.HedgehogsNumber) do
                    if (team^.Hedgehogs[i].Gear <> nil) and (not team^.Hedgehogs[i].King)
                    and (team^.Hedgehogs[i].Gear^.Health > team^.Hedgehogs[i].Gear^.Damage) then
                        flag:= true;
                if not flag then
                    begin
                    inc(tmp, 5);
                    if (GameFlags and gfResetHealth) <> 0 then
                        dec(Gear^.Hedgehog^.InitialHealth, 5)
                    end
                end;
            if tmp > 0 then
                begin
                inc(Gear^.Damage, min(tmp, max(0,Gear^.Health - 1 - Gear^.Damage)));
                HHHurt(Gear^.Hedgehog, dsPoison);
                end
            end;

        Gear:= Gear^.NextGear
    end;
end;

procedure ProcessGears;
var t: PGear;
    i, AliveCount: LongInt;
    s: ansistring;
    prevtime: LongWord;
    stirFallers: boolean;
begin
stirFallers:= false;
prevtime:= TurnTimeLeft;
ScriptCall('onGameTick');
if GameTicks mod 20 = 0 then ScriptCall('onGameTick20');
if GameTicks = NewTurnTick then
    begin
    ScriptCall('onNewTurn');
{$IFDEF USE_TOUCH_INTERFACE}
    uTouch.NewTurnBeginning();
{$ENDIF}
    end;

PrvInactive:= AllInactive;
AllInactive:= true;

if (StepSoundTimer > 0) and (StepSoundChannel < 0) then
    StepSoundChannel:= LoopSound(sndSteps)
else if (StepSoundTimer = 0) and (StepSoundChannel > -1) then
    begin
    StopSoundChan(StepSoundChannel);
    StepSoundChannel:= -1
    end;

if StepSoundTimer > 0 then
    dec(StepSoundTimer, 1);

t:= GearsList;
while t <> nil do
    begin
    curHandledGear:= t;
    t:= curHandledGear^.NextGear;
    if (GameTicks and $1FFF = 0) and (curHandledGear^.Kind = gtCase) and (curHandledGear^.Pos <> posCaseHealth) then
        stirFallers := true; 

    if curHandledGear^.Message and gmDelete <> 0 then
        DeleteGear(curHandledGear)
    else
        begin
        if curHandledGear^.Message and gmRemoveFromList <> 0 then
            begin
            RemoveGearFromList(curHandledGear);
            // since I can't think of any good reason this would ever be separate from a remove from list, going to keep it inside this block
            if curHandledGear^.Message and gmAddToList <> 0 then InsertGearToList(curHandledGear);
            curHandledGear^.Message:= curHandledGear^.Message and (not (gmRemoveFromList or gmAddToList))
            end;
        if curHandledGear^.Active then
            begin
            if curHandledGear^.RenderTimer and (curHandledGear^.Timer > 500) and ((curHandledGear^.Timer mod 1000) = 0) then
                begin
                FreeAndNilTexture(curHandledGear^.Tex);
                curHandledGear^.Tex:= RenderStringTex(ansistring(inttostr(curHandledGear^.Timer div 1000)), cWhiteColor, fntSmall);
                end;
            curHandledGear^.doStep(curHandledGear);
            // might be useful later
            //ScriptCall('onGearStep', Gear^.uid);
            end
        end
    end;
if stirFallers then
    begin
    t := GearsList;
    while t <> nil do
        begin
        if t^.Kind = gtGenericFaller then
            begin
            t^.Active:= true;
            t^.X:=  int2hwFloat(GetRandom(rightX-leftX)+leftX);
            t^.Y:=  int2hwFloat(GetRandom(LAND_HEIGHT-topY)+topY);
            t^.dX:= _90-(GetRandomf*_360);
            t^.dY:= _90-(GetRandomf*_360)
            end;
        t := t^.NextGear
        end
    end;

curHandledGear:= nil;

if AllInactive then
case step of
    stDelay:
        begin
        if delay = 0 then
            delay:= cInactDelay
        else
            dec(delay);

        if delay = 0 then
            inc(step)
        end;

    stChDmg:
    if CheckNoDamage then
        inc(step)
    else
        step:= stDelay;

    stSweep:
    if SweepDirty then
        begin
        SetAllToActive;
        step:= stChDmg
        end
    else
        inc(step);

    stTurnReact:
        begin
        if (not bBetweenTurns) and (not isInMultiShoot) then
            begin
            uStats.TurnReaction;
            inc(step)
            end
        else
            inc(step, 2);
        end;

    stAfterDelay:
        begin
        if delay = 0 then
            delay:= cInactDelay
        else
            dec(delay);

        if delay = 0 then
            inc(step)
            end;
    stChWin:
        begin
        CheckForWin();
        inc(step)
        end;
    stWater:
    if (not bBetweenTurns) and (not isInMultiShoot) then
        begin
        if TotalRounds = cSuddenDTurns + 1 then
            bWaterRising:= true;
        if bWaterRising and (cWaterRise > 0) then
            AddGear(0, 0, gtWaterUp, 0, _0, _0, 0)^.Tag:= cWaterRise;
        inc(step)
        end
    else // since we are not raising the water, a second win-check isn't needed
        inc(step,2);
    stChWin2:
        begin
        CheckForWin;
        inc(step)
        end;

    stHealth:
        begin
        if (cWaterRise <> 0) or (cHealthDecrease <> 0) then
             begin
            if (TotalRounds = cSuddenDTurns) and (not SuddenDeath) and (not isInMultiShoot) then
                begin
                SuddenDeath:= true;
                if cHealthDecrease <> 0 then
                    begin
                    SuddenDeathDmg:= true;

                    // flash
                    ScreenFade:= sfFromWhite;
                    ScreenFadeValue:= sfMax;
                    ScreenFadeSpeed:= 1;

                    ChangeToSDClouds;
                    ChangeToSDFlakes;
                    SetSkyColor(SDSkyColor.r * (SDTint/255) / 255, SDSkyColor.g * (SDTint/255) / 255, SDSkyColor.b * (SDTint/255) / 255);
                    Ammoz[amTardis].SkipTurns:= 9999;
                    Ammoz[amTardis].Probability:= 0;
                    end;
                AddCaption(trmsg[sidSuddenDeath], cWhiteColor, capgrpGameState);
                ScriptCall('onSuddenDeath');
                playSound(sndSuddenDeath);
                StopMusic;
                if SDMusicFN <> '' then PlayMusic
                end
            else if (TotalRounds < cSuddenDTurns) and (not isInMultiShoot) then
                begin
                i:= cSuddenDTurns - TotalRounds;
                s:= ansistring(inttostr(i));
                if i = 1 then
                    AddCaption(trmsg[sidRoundSD], cWhiteColor, capgrpGameState)
                else if (i = 2) or ((i > 0) and ((i mod 50 = 0) or ((i <= 25) and (i mod 5 = 0)))) then
                    AddCaption(FormatA(trmsg[sidRoundsSD], s), cWhiteColor, capgrpGameState);
                end;
            end;
            if bBetweenTurns
            or isInMultiShoot
            or (TotalRounds = -1) then
                inc(step)
            else
                begin
                bBetweenTurns:= true;
                HealthMachine;
                step:= stChDmg
                end
            end;
    stSpawn:
        begin
        if not isInMultiShoot then
            SpawnBoxOfSmth;
        inc(step)
        end;
    stNTurn:
        begin
        if isInMultiShoot then
            isInMultiShoot:= false
        else
            begin
            // delayed till after 0.9.12
            // reset to default zoom
            //ZoomValue:= ZoomDefault;
            with CurrentHedgehog^ do
                if (Gear <> nil)
                and ((Gear^.State and gstAttacked) = 0)
                and (MultiShootAttacks > 0) then
                    OnUsedAmmo(CurrentHedgehog^);

                EndTurnCleanup;

                FreeActionsList; // could send -left, -right and similar commands, so should be called before /nextturn

                ParseCommand('/nextturn', true);
                SwitchHedgehog;

                AfterSwitchHedgehog;
                bBetweenTurns:= false;
                NewTurnTick:= GameTicks + 1
                end;
            step:= Low(step)
            end;
    end
else if ((GameFlags and gfInfAttack) <> 0) then
    begin
    if delay2 = 0 then
        delay2:= cInactDelay * 50
    else
        begin
        dec(delay2);

        if ((delay2 mod cInactDelay) = 0) and (CurrentHedgehog <> nil) and (CurrentHedgehog^.Gear <> nil)
        and (not CurrentHedgehog^.Unplaced) then
            begin
            if (CurrentHedgehog^.Gear^.State and gstAttacked <> 0)
            and (Ammoz[CurrentHedgehog^.CurAmmoType].Ammo.Propz and ammoprop_NeedTarget <> 0) then
                begin
                CurrentHedgehog^.Gear^.State:= CurrentHedgehog^.Gear^.State or gstChooseTarget;
                isCursorVisible := true
                end;
            CurrentHedgehog^.Gear^.State:= CurrentHedgehog^.Gear^.State and (not gstAttacked);
            end;
        if delay2 = 0 then
            begin
            if (CurrentHedgehog^.Gear <> nil) and (CurrentHedgehog^.Gear^.State and gstAttacked = 0)
            and (CurAmmoGear = nil) then
                SweepDirty;
            if (CurrentHedgehog^.Gear = nil) or (CurrentHedgehog^.Gear^.State and gstHHDriven = 0) or (CurrentHedgehog^.Gear^.Damage = 0) then
                CheckNoDamage;
            AliveCount:= 0; // shorter version of check for win to allow typical step activity to proceed
            for i:= 0 to Pred(ClansCount) do
                if ClansArray[i]^.ClanHealth > 0 then
                    inc(AliveCount);
            if (AliveCount <= 1) and ((GameFlags and gfOneClanMode) = 0) then
                begin
                step:= stChDmg;
                if TagTurnTimeLeft = 0 then
                    TagTurnTimeLeft:= TurnTimeLeft;
                TurnTimeLeft:= 0
                end
            end
        end
    end;

if TurnTimeLeft > 0 then
    if CurrentHedgehog^.Gear <> nil then
        if (((CurrentHedgehog^.Gear^.State and gstAttacking) = 0)
            or (Ammoz[CurrentHedgehog^.CurAmmoType].Ammo.Propz and ammoprop_DoesntStopTimerWhileAttacking <> 0))
            and (not(isInMultiShoot and ((Ammoz[CurrentHedgehog^.CurAmmoType].Ammo.Propz and ammoprop_DoesntStopTimerInMultiShoot) <> 0))) then
            //(CurrentHedgehog^.CurAmmoType in [amShotgun, amDEagle, amSniperRifle])
                begin
                if (TurnTimeLeft = 5000)
                and (cHedgehogTurnTime >= 10000)
                and (not PlacingHogs)
                and (CurrentHedgehog^.Gear <> nil)
                and ((CurrentHedgehog^.Gear^.State and gstAttacked) = 0) then
                    PlaySoundV(sndHurry, CurrentTeam^.voicepack);
            if ReadyTimeLeft > 0 then
                begin
                if (ReadyTimeLeft = 2000) and (LastVoice.snd = sndNone) then
                    AddVoice(sndComeonthen, CurrentTeam^.voicepack);
                dec(ReadyTimeLeft)
                end
            else
                dec(TurnTimeLeft)
            end;

if skipFlag then
    begin
    if TagTurnTimeLeft = 0 then
        TagTurnTimeLeft:= TurnTimeLeft;
    TurnTimeLeft:= 0;
    skipFlag:= false;
    inc(CurrentHedgehog^.Team^.stats.TurnSkips);
    end;

if ((GameTicks and $FFFF) = $FFFF) then
    begin
    if (not CurrentTeam^.ExtDriven) then
        begin
        SendIPC(_S'#');
        AddFileLog('hiTicks increment message sent')
        end;

    if (not CurrentTeam^.ExtDriven) or CurrentTeam^.hasGone then
        begin
        AddFileLog('hiTicks increment (current team is local or gone)');
        inc(hiTicks) // we do not recieve a message for this
        end
    end;
AddRandomness(CheckSum);
TurnClockActive:= prevtime <> TurnTimeLeft;
inc(GameTicks)
end;

//Purpose, to reset all transient attributes toggled by a utility and clean up various gears and effects at end of turn
//If any of these are set as permanent toggles in the frontend, that needs to be checked and skipped here.
procedure EndTurnCleanup;
var  i: LongInt;
     t: PGear;
begin
    SpeechText:= ''; // in case it has not been consumed

    if (GameFlags and gfLowGravity) = 0 then
        begin
        cGravity:= cMaxWindSpeed * 2;
        cGravityf:= 0.00025 * 2
        end;

    if (GameFlags and gfVampiric) = 0 then
        cVampiric:= false;

    cDamageModifier:= _1;

    if (GameFlags and gfLaserSight) = 0 then
        cLaserSighting:= false;

    if (GameFlags and gfArtillery) = 0 then
        cArtillery:= false;
    // have to sweep *all* current team hedgehogs since it is theoretically possible if you have enough invulnerabilities and switch turns to make your entire team invulnerable
    if (CurrentTeam <> nil) then
        with CurrentTeam^ do
            for i:= 0 to cMaxHHIndex do
                with Hedgehogs[i] do
                    begin
(*
                    if (SpeechGear <> nil) then
                        begin
                        DeleteVisualGear(SpeechGear);  // remove to restore persisting beyond end of turn. Tiy says was too much of a gameplay issue
                        SpeechGear:= nil
                        end;
*)

                    if (Gear <> nil) then
                        begin
                        if (GameFlags and gfInvulnerable) = 0 then
                            Gear^.Hedgehog^.Effects[heInvulnerable]:= 0;
                        end;
                    end;
    t:= GearsList;
    while t <> nil do
        begin
        t^.PortalCounter:= 0;
        if ((GameFlags and gfResetHealth) <> 0) and (t^.Kind = gtHedgehog) and (t^.Health < t^.Hedgehog^.InitialHealth) then
            begin
            t^.Health:= t^.Hedgehog^.InitialHealth;
            RenderHealth(t^.Hedgehog^);
            end;
        t:= t^.NextGear
        end;

    if ((GameFlags and gfResetWeps) <> 0) and (not PlacingHogs) then
        ResetWeapons;

    if (GameFlags and gfResetHealth) <> 0 then
        for i:= 0 to Pred(TeamsCount) do
            RecountTeamHealth(TeamsArray[i])
end;

procedure DrawGears;
var Gear: PGear;
    x, y: LongInt;
begin
Gear:= GearsList;
while Gear <> nil do
    begin
    if (Gear^.State and gstInvisible = 0) and (Gear^.Message and gmRemoveFromList = 0) then
        begin
        x:= hwRound(Gear^.X) + WorldDx;
        y:= hwRound(Gear^.Y) + WorldDy;
        RenderGear(Gear, x, y);
        end;
    Gear:= Gear^.NextGear
    end;

if SpeechHogNumber > 0 then
    DrawHHOrder();
end;

procedure FreeGearsList;
var t, tt: PGear;
begin
    tt:= GearsList;
    GearsList:= nil;
    while tt <> nil do
    begin
        t:= tt;
        tt:= tt^.NextGear;
        Dispose(t)
    end;
end;

procedure AddMiscGears;
var p,i,j,t,h,unplaced: Longword;
    rx, ry: LongInt;
    rdx, rdy: hwFloat;
    Gear: PGear;
begin
AddGear(0, 0, gtATStartGame, 0, _0, _0, 2000);

i:= 0;
unplaced:= 0;
while (i < cLandMines) and (unplaced < 4) do
    begin
    Gear:= AddGear(0, 0, gtMine, 0, _0, _0, 0);
    FindPlace(Gear, false, 0, LAND_WIDTH);

    if Gear = nil then
        inc(unplaced)
    else
        unplaced:= 0;

    inc(i)
    end;

i:= 0;
unplaced:= 0;
while (i < cExplosives) and (unplaced < 4) do
    begin
    Gear:= AddGear(0, 0, gtExplosives, 0, _0, _0, 0);
    FindPlace(Gear, false, 0, LAND_WIDTH);

    if Gear = nil then
        inc(unplaced)
    else
        unplaced:= 0;

    inc(i)
    end;

i:= 0;
j:= 0;
p:= 0; // 0 searching, 1 bad position, 2 added.
unplaced:= 0;
if cAirMines > 0 then
    Gear:= AddGear(0, 0, gtAirMine, 0, _0, _0, 0);
while (i < cAirMines) and (j < 1000*cAirMines) do
    begin
    p:= 0;
    if hasBorder then
        begin
        rx:= leftX+GetRandom(rightX-leftX-16)+8;
        ry:= topY+GetRandom(LAND_HEIGHT-topY-16)+8
        end
    else
        begin
        rx:= leftX+GetRandom(rightX-leftX+400)-200;
        ry:= topY+GetRandom(LAND_HEIGHT-topY+400)-200
        end;
    Gear^.X:= int2hwFloat(rx);
    Gear^.Y:= int2hwFloat(ry);
    if CheckLandValue(rx, ry, $FFFF) and
       (TestCollisionYwithGear(Gear,-1) = 0) and
       (TestCollisionXwithGear(Gear, 1) = 0) and
       (TestCollisionXwithGear(Gear,-1) = 0) and
       (TestCollisionYwithGear(Gear, 1) = 0) then
        begin
        t:= 0;
        while (t < TeamsCount) and (p = 0) do
            begin
            h:= 0;
            with TeamsArray[t]^ do
                while (h < cMaxHHIndex) and (p = 0) do
                    begin
                    if (Hedgehogs[h].Gear <> nil) then
                        begin
                        rdx:=Gear^.X-Hedgehogs[h].Gear^.X;
                        rdy:=Gear^.Y-Hedgehogs[h].Gear^.Y;
                        if (Gear^.Angle < $FFFFFFFF) and
                            ((rdx.Round+rdy.Round < Gear^.Angle) and
                            (hwRound(hwSqr(rdx) + hwSqr(rdy)) < sqr(Gear^.Angle))) then
                            begin
// Debug line. Remove later
// AddFileLog('Too Close to Hog @ (' + inttostr(rx) + ',' + inttostr(ry) + ')');

                            p:= 1
                            end
                        end;
                    inc(h)
                    end;
            inc(t)
            end;
        if p = 0 then
            begin
            inc(i);
            AddFileLog('Placed Air Mine @ (' + inttostr(rx) + ',' + inttostr(ry) + ')');
            if i < cAirMines then
                Gear:= AddGear(0, 0, gtAirMine, 0, _0, _0, 0)
            end
        end;
    inc(j)
    end;
if p <> 0 then DeleteGear(Gear);

if (GameFlags and gfLowGravity) <> 0 then
    begin
    cGravity:= cMaxWindSpeed;
    cGravityf:= 0.00025
    end;

if (GameFlags and gfVampiric) <> 0 then
    cVampiric:= true;

Gear:= GearsList;
if (GameFlags and gfInvulnerable) <> 0 then
    for p:= 0 to Pred(ClansCount) do
        with ClansArray[p]^ do
            for j:= 0 to Pred(TeamsNumber) do
                with Teams[j]^ do
                    for i:= 0 to cMaxHHIndex do
                        with Hedgehogs[i] do
                            Effects[heInvulnerable]:= 1;

if (GameFlags and gfLaserSight) <> 0 then
    cLaserSighting:= true;

if (GameFlags and gfArtillery) <> 0 then
    cArtillery:= true;
for i:= (LAND_WIDTH*LAND_HEIGHT) div 524288+2 downto 0 do
    begin
    rx:= GetRandom(rightX-leftX)+leftX;
    ry:= GetRandom(LAND_HEIGHT-topY)+topY;
    rdx:= _90-(GetRandomf*_360);
    rdy:= _90-(GetRandomf*_360);
    AddGear(rx, ry, gtGenericFaller, gstInvisible, rdx, rdy, $FFFFFFFF);
    end;

snowRight:= max(LAND_WIDTH,4096)+512;
snowLeft:= -(snowRight-LAND_WIDTH);

if (not hasBorder) and cSnow then
    for i:= vobCount * Longword(max(LAND_WIDTH,4096)) div 2048 downto 1 do
        begin
        rx:=GetRandom(snowRight - snowLeft);
        ry:=GetRandom(750);
        AddGear(rx + snowLeft, LongInt(LAND_HEIGHT) + ry - 1300, gtFlake, 0, _0, _0, 0)
        end
end;

// sort clans horizontally (bubble-sort, because why not)
procedure SortHHsByClan();
var n, newn, i, j, k, p: LongInt;
    ar, clar: array[0..Pred(cMaxHHs)] of PHedgehog;
    Count, clCount: Longword;
    tmpX, tmpY: hwFloat;
    hh1, hh2: PHedgehog;
begin
Count:= 0;
// add hedgehogs to the array in clan order
for p:= 0 to (ClansCount - 1) do
    with SpawnClansArray[p]^ do
        begin
        // count hogs in this clan
        clCount:= 0;
        for j:= 0 to Pred(TeamsNumber) do
            with Teams[j]^ do
                for i:= 0 to cMaxHHIndex do
                    if Hedgehogs[i].Gear <> nil then
                        begin
                        clar[clCount]:= @Hedgehogs[i];
                        inc(clCount);
                        end;

        // shuffle all hogs of this clan
        for i:= 0 to clCount - 1 do
            begin
            j:= GetRandom(clCount);
            k:= GetRandom(clCount);
            if clar[j] <> clar[k] then
                begin
                hh1:= clar[j];
                clar[j]:= clar[k];
                clar[k]:= hh1;
                end;
            end;

        // add clan's hog to sorting array
        for i:= 0 to clCount - 1 do
            begin
            ar[Count]:= clar[i];
            inc(Count);
            end;
        end;


// bubble-sort hog array
n:= Count - 1;

repeat
    newn:= 0;
    for i:= 1 to n do
        begin
        hh1:= ar[i-1];
        hh2:= ar[i];
        if hwRound(hh1^.Gear^.X) > hwRound(hh2^.Gear^.X) then
            begin
            tmpX:= hh1^.Gear^.X;
            tmpY:= hh1^.Gear^.Y;
            hh1^.Gear^.X:= hh2^.Gear^.X;
            hh1^.Gear^.Y:= hh2^.Gear^.Y;
            hh2^.Gear^.X:= tmpX;
            hh2^.Gear^.Y:= tmpY;
            newn:= i;
            end;
        end;
    n:= newn;
until n = 0;

end;

procedure AssignHHCoords;
var i, t, p, j: LongInt;
    ar: array[0..Pred(cMaxHHs)] of PHedgehog;
    Count: Longword;
    divide, sectionDivide: boolean;
begin
if (GameFlags and gfPlaceHog) <> 0 then
    PlacingHogs:= true;

divide:= ((GameFlags and gfDivideTeams) <> 0);
sectionDivide:= divide and ((GameFlags and gfForts) <> 0);

// TODO: there might be a smarter way to decide if dividing clans into equal-width map sections makes sense
// e.g. by checking if there is enough spawn area in each section
if divide and (not sectionDivide) then
    sectionDivide:= (ClansCount = 2);

// in section-divide mode, divide the map into equal-width sections and put each clan in one of them
if sectionDivide then
    begin
    t:= leftX;
    for p:= 0 to (ClansCount - 1) do
        begin
        with SpawnClansArray[p]^ do
            for j:= 0 to Pred(TeamsNumber) do
                with Teams[j]^ do
                    for i:= 0 to cMaxHHIndex do
                        with Hedgehogs[i] do
                            if (Gear <> nil) and (Gear^.X.QWordValue = 0) then
                                begin
                                if PlacingHogs then
                                    Unplaced:= true
                                else
                                    FindPlace(Gear, false, t, t + playWidth div ClansCount, true);// could make Gear == nil;
                                if Gear <> nil then
                                    begin
                                    Gear^.Pos:= GetRandom(49);
                                    // unless the world is wrapping, make outter teams face to map center
                                    if (WorldEdge <> weWrap) and ((p = 0) or (p = ClansCount - 1)) then
                                        Gear^.dX.isNegative:= (p <> 0)
                                    else
                                        Gear^.dX.isNegative:= (GetRandom(2) = 1);
                                    end
                                end;
        inc(t, playWidth div ClansCount);
        end
    end 
else // mix hedgehogs
    begin
    Count:= 0;
    for p:= 0 to Pred(TeamsCount) do
        with TeamsArray[p]^ do
        begin
        for i:= 0 to cMaxHHIndex do
            with Hedgehogs[i] do
                if (Gear <> nil) and (Gear^.X.QWordValue = 0) then
                    begin
                    ar[Count]:= @Hedgehogs[i];
                    inc(Count)
                    end;
        end;
    while (Count > 0) do
        begin
        i:= GetRandom(Count);
        if PlacingHogs then
            ar[i]^.Unplaced:= true
        else
            FindPlace(ar[i]^.Gear, false, leftX, rightX, true);
        if ar[i]^.Gear <> nil then
            begin
            ar[i]^.Gear^.dX.isNegative:= hwRound(ar[i]^.Gear^.X) > leftX + playWidth div 2;
            ar[i]^.Gear^.Pos:= GetRandom(19)
            end;
        ar[i]:= ar[Count - 1];
        dec(Count)
        end
    end;
for p:= 0 to Pred(TeamsCount) do
    with TeamsArray[p]^ do
        for i:= 0 to cMaxHHIndex do
            with Hedgehogs[i] do
                if (Gear <> nil) and (Gear^.State and gsttmpFlag <> 0) then
                    begin
                    DrawExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 50);
                    AddFileLog('Carved a hole for hog at coordinates (' + inttostr(hwRound(Gear^.X)) + ',' + inttostr(hwRound(Gear^.Y)) + ')')
                    end;
// place flowers after in case holes overlap (we shrink search distance if we are failing to place)
for p:= 0 to Pred(TeamsCount) do
    with TeamsArray[p]^ do
        for i:= 0 to cMaxHHIndex do
            with Hedgehogs[i] do
                if (Gear <> nil) and (Gear^.State and gsttmpFlag <> 0) then
                    begin
                    ForcePlaceOnLand(hwRound(Gear^.X) - SpritesData[sprTargetBee].Width div 2, 
                                     hwRound(Gear^.Y) - SpritesData[sprTargetBee].Height div 2, 
                                     sprTargetBee, 0, lfBasic, $FFFFFFFF, false, false, false);
                    Gear^.Y:= int2hwFloat(hwRound(Gear^.Y) - 16 - Gear^.Radius);
                    Gear^.State:= Gear^.State and (not gsttmpFlag);
                    AddFileLog('Placed flower for hog at coordinates (' + inttostr(hwRound(Gear^.X)) + ',' + inttostr(hwRound(Gear^.Y)) + ')')
                    end;


// divided teams: sort the hedgehogs from left to right by clan and shuffle clan members
if divide and (not sectionDivide) then
    SortHHsByClan();
end;


{procedure AmmoFlameWork(Ammo: PGear);
var t: PGear;
begin
t:= GearsList;
while t <> nil do
    begin
    if (t^.Kind = gtHedgehog) and (t^.Y < Ammo^.Y) then
        if not (hwSqr(Ammo^.X - t^.X) + hwSqr(Ammo^.Y - t^.Y - int2hwFloat(cHHRadius)) * 2 > _2) then
            begin
            ApplyDamage(t, 5);
            t^.dX:= t^.dX + (t^.X - Ammo^.X) * _0_02;
            t^.dY:= - _0_25;
            t^.Active:= true;
            DeleteCI(t);
            FollowGear:= t
            end;
    t:= t^.NextGear
    end;
end;}


function SpawnCustomCrateAt(x, y: LongInt; crate: TCrateType; content, cnt: Longword): PGear;
begin
    FollowGear := AddGear(x, y, gtCase, 0, _0, _0, 0);
    cCaseFactor := 0;

    if (crate <> HealthCrate) and (content > ord(High(TAmmoType))) then
        content := ord(High(TAmmoType));

    FollowGear^.Power:= cnt;

    case crate of
        HealthCrate:
            begin
            FollowGear^.Pos := posCaseHealth;
            // health crate is smaller than the other crates
            FollowGear^.Radius := cCaseHealthRadius;
            FollowGear^.Health := content;
            AddCaption(GetEventString(eidNewHealthPack), cWhiteColor, capgrpAmmoInfo);
            end;
        AmmoCrate:
            begin
            FollowGear^.Pos := posCaseAmmo;
            FollowGear^.AmmoType := TAmmoType(content);
            AddCaption(GetEventString(eidNewAmmoPack), cWhiteColor, capgrpAmmoInfo);
            end;
        UtilityCrate:
            begin
            FollowGear^.Pos := posCaseUtility;
            FollowGear^.AmmoType := TAmmoType(content);
            AddCaption(GetEventString(eidNewUtilityPack), cWhiteColor, capgrpAmmoInfo);
            end;
    end;

    if ( (x = 0) and (y = 0) ) then
        FindPlace(FollowGear, true, 0, LAND_WIDTH);

    SpawnCustomCrateAt := FollowGear;
end;

function SpawnFakeCrateAt(x, y: LongInt; crate: TCrateType; explode: boolean; poison: boolean): PGear;
begin
    FollowGear := AddGear(x, y, gtCase, 0, _0, _0, 0);
    cCaseFactor := 0;
    FollowGear^.Pos := posCaseDummy;

    if explode then
        FollowGear^.Pos := FollowGear^.Pos + posCaseExplode;
    if poison then
        FollowGear^.Pos := FollowGear^.Pos + posCasePoison;

    case crate of
        HealthCrate:
            begin
            FollowGear^.Pos := FollowGear^.Pos + posCaseHealth;
            // health crate is smaller than the other crates
            FollowGear^.Radius := cCaseHealthRadius;
            AddCaption(GetEventString(eidNewHealthPack), cWhiteColor, capgrpAmmoInfo);
            end;
        AmmoCrate:
            begin
            FollowGear^.Pos := FollowGear^.Pos + posCaseAmmo;
            AddCaption(GetEventString(eidNewAmmoPack), cWhiteColor, capgrpAmmoInfo);
            end;
        UtilityCrate:
            begin
            FollowGear^.Pos := FollowGear^.Pos + posCaseUtility;
            AddCaption(GetEventString(eidNewUtilityPack), cWhiteColor, capgrpAmmoInfo);
            end;
    end;

    if ( (x = 0) and (y = 0) ) then
        FindPlace(FollowGear, true, 0, LAND_WIDTH);

    SpawnFakeCrateAt := FollowGear;
end;


function GearByUID(uid : Longword) : PGear;
var gear: PGear;
begin
GearByUID:= nil;
if uid = 0 then exit;
if (lastGearByUID <> nil) and (lastGearByUID^.uid = uid) then
    begin
    GearByUID:= lastGearByUID;
    exit
    end;
gear:= GearsList;
while gear <> nil do
    begin
    if gear^.uid = uid then
        begin
        lastGearByUID:= gear;
        GearByUID:= gear;
        exit
        end;
    gear:= gear^.NextGear
    end
end;


procedure chSkip(var s: shortstring);
begin
s:= s; // avoid compiler hint
if not isExternalSource then
    SendIPC(_S',');
uStats.Skipped;
skipFlag:= true
end;

procedure chHogSay(var s: shortstring);
var Gear: PVisualGear;
    text: shortstring;
    hh: PHedgehog;
    i, x, t, h: byte;
    c, j: LongInt;
begin
    hh:= nil;
    i:= 0;
    t:= 0;
    x:= byte(s[1]);  // speech type
    if x < 4 then
        begin
        t:= byte(s[2]);  // team
        if Length(s) > 2 then
            h:= byte(s[3])  // target hog
        else
            h:= 0
        end;
    // allow targetting a hog by specifying a number as the first portion of the text
    if (x < 4) and (h > byte('0')) and (h < byte('9')) then
        i:= h - 48;
    if i <> 0 then
        text:= copy(s, 4, Length(s) - 1)
    else if x < 4 then
        text:= copy(s, 3, Length(s) - 1)
    else text:= copy(s, 2, Length(s) - 1);

    if text = '' then text:= '...';

    (*
    if CheckNoTeamOrHH then
        begin
        ParseCommand('say ' + text, true);
        exit
        end;
    *)

    if (x < 4) and (TeamsArray[t] <> nil) then
        begin
            // if team matches current hedgehog team, default to current hedgehog
            if (i = 0) and (CurrentHedgehog <> nil) and (CurrentHedgehog^.Team = TeamsArray[t]) then
                hh:= CurrentHedgehog
            else
                begin
            // otherwise use the first living hog or the hog amongs the remaining ones indicated by i
                j:= 0;
                c:= 0;
                while (j <= cMaxHHIndex) and (hh = nil) do
                    begin
                    if (TeamsArray[t]^.Hedgehogs[j].Gear <> nil) then
                        begin
                        inc(c);
                        if (i=0) or (i=c) then
                            hh:= @TeamsArray[t]^.Hedgehogs[j]
                        end;
                    inc(j)
                    end
                end;
        if hh <> nil then
            begin
            Gear:= AddVisualGear(0, 0, vgtSpeechBubble);
            if Gear <> nil then
                begin
                Gear^.Hedgehog:= hh;
                Gear^.Text:= text;
                Gear^.FrameTicks:= x
                end;
            //ParseCommand('/say [' + hh^.Name + '] '+text, true)
            AddChatString(#9+'[' + HH^.Name + '] '+text);
            end
        end
    else if (x >= 4) then
        begin
        SpeechType:= x-3;
        SpeechText:= text
        end;
end;

procedure initModule;
const handlers: array[TGearType] of TGearStepProcedure = (
            @doStepFlame,
            @doStepHedgehog,
            @doStepMine,
            @doStepCase,
            @doStepAirMine,
            @doStepCase,
            @doStepBomb,
            @doStepShell,
            @doStepGrave,
            @doStepBee,
            @doStepShotgunShot,
            @doStepPickHammer,
            @doStepRope,
            @doStepDEagleShot,
            @doStepDynamite,
            @doStepBomb,
            @doStepCluster,
            @doStepShover,
            @doStepFirePunch,
            @doStepActionTimer,
            @doStepActionTimer,
            @doStepParachute,
            @doStepAirAttack,
            @doStepAirBomb,
            @doStepBlowTorch,
            @doStepGirder,
            @doStepTeleport,
            @doStepSwitcher,
            @doStepTarget,
            @doStepMortar,
            @doStepWhip,
            @doStepKamikaze,
            @doStepCake,
            @doStepSeduction,
            @doStepBomb,
            @doStepCluster,
            @doStepBomb,
            @doStepWaterUp,
            @doStepDrill,
            @doStepBallgun,
            @doStepBomb,
            @doStepRCPlane,
            @doStepSniperRifleShot,
            @doStepJetpack,
            @doStepMolotov,
            @doStepBirdy,
            @doStepEggWork,
            @doStepPortalShot,
            @doStepPiano,
            @doStepBomb,
            @doStepSineGunShot,
            @doStepFlamethrower,
            @doStepSMine,
            @doStepPoisonCloud,
            @doStepHammer,
            @doStepHammerHit,
            @doStepResurrector,
            @doStepNapalmBomb,
            @doStepSnowball,
            @doStepSnowflake,
            //@doStepStructure,
            @doStepLandGun,
            @doStepTardis,
            @doStepIceGun,
            @doStepAddAmmo,
            @doStepGenericFaller,
            @doStepKnife);
begin
    doStepHandlers:= handlers;

    RegisterVariable('skip', @chSkip, false);
    RegisterVariable('hogsay', @chHogSay, true );

    CurAmmoGear:= nil;
    GearsList:= nil;
    curHandledGear:= nil;

    KilledHHs:= 0;
    SuddenDeath:= false;
    SuddenDeathDmg:= false;
    SpeechType:= 1;
    skipFlag:= false;

    AllInactive:= false;
    PrvInactive:= false;

    //typed const
    delay:= 0;
    delay2:= 0;
    step:= stDelay;
    upd:= 0;

    //SDMusic:= 'hell.ogg';
    NewTurnTick:= $FFFFFFFF;
end;

procedure freeModule;
begin
    FreeGearsList();
end;

end.
