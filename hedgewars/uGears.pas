(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2010 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uGears;
interface
uses SDLh, uConsts, uFloat, uTypes;

procedure initModule;
procedure freeModule;
function  AddGear(X, Y: LongInt; Kind: TGearType; State: Longword; dX, dY: hwFloat; Timer: LongWord): PGear;
function SpawnCustomCrateAt(x, y: LongInt; crate: TCrateType; content: Longword ): PGear;
procedure ResurrectHedgehog(gear: PGear);
procedure ProcessGears;
procedure EndTurnCleanup;
procedure ApplyDamage(Gear: PGear; Damage: Longword; Source: TDamageSource);
procedure SetAllToActive;
procedure SetAllHHToActive;
procedure DrawGears;
procedure FreeGearsList;
procedure AddMiscGears;
procedure AssignHHCoords;
function  GearByUID(uid : Longword) : PGear;
procedure InsertGearToList(Gear: PGear);
procedure RemoveGearFromList(Gear: PGear);
function  ModifyDamage(dmg: Longword; Gear: PGear): Longword;
procedure FindPlace(var Gear: PGear; withFall: boolean; Left, Right: LongInt; skipProximity: boolean = false);
procedure DeleteGear(Gear: PGear); 


implementation
uses uStore, uSound, uTeams, uRandom, uCollisions, uIO, uLandGraphics,
     uAIMisc, uLocale, uAI, uAmmos, uStats, uVisualGears, uScript, GLunit, uMobile, uVariables,
     uCommands, uUtils, uTextures, uRenderUtils, uGearsRender, uCaptions, uDebug, uLandTexture;


procedure doMakeExplosion(X, Y, Radius: LongInt; Mask: LongWord); forward;
procedure doMakeExplosion(X, Y, Radius: LongInt; Mask, Tint: LongWord); forward;
procedure AmmoShove(Ammo: PGear; Damage, Power: LongInt); forward;
//procedure AmmoFlameWork(Ammo: PGear); forward;
function  GearsNear(X, Y: hwFloat; Kind: TGearType; r: LongInt): TPGearArray; forward;
function  CheckGearNear(Gear: PGear; Kind: TGearType; rX, rY: LongInt): PGear; forward;
procedure SpawnBoxOfSmth; forward;
procedure AfterAttack; forward;
procedure HedgehogStep(Gear: PGear); forward;
procedure doStepHedgehogMoving(Gear: PGear); forward;
procedure HedgehogChAngle(Gear: PGear); forward;
procedure ShotgunShot(Gear: PGear); forward;
procedure PickUp(HH, Gear: PGear); forward;
procedure HHSetWeapon(Gear: PGear); forward;
procedure doStepCase(Gear: PGear); forward;

{$INCLUDE "GSHandlers.inc"}
{$INCLUDE "HHHandlers.inc"}

const doStepHandlers: array[TGearType] of TGearStepProcedure = (
            @doStepBomb,
            @doStepHedgehog,
            @doStepShell,
            @doStepGrave,
            @doStepBee,
            @doStepShotgunShot,
            @doStepPickHammer,
            @doStepRope,
            @doStepMine,
            @doStepCase,
            @doStepDEagleShot,
            @doStepDynamite,
            @doStepBomb,
            @doStepCluster,
            @doStepShover,
            @doStepFlame,
            @doStepFirePunch,
            @doStepActionTimer,
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
            @doStepWatermelon,
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
            @doStepCase,
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
            @doStepSnowflake
            );

procedure InsertGearToList(Gear: PGear);
var tmp, ptmp: PGear;
begin
    tmp:= GearsList;
    ptmp:= GearsList;
    while (tmp <> nil) and (tmp^.Z <= Gear^.Z) do
        begin
        ptmp:= tmp;
        tmp:= tmp^.NextGear
        end;

    if ptmp <> tmp then
        begin
        Gear^.NextGear:= ptmp^.NextGear;
        Gear^.PrevGear:= ptmp;
        if ptmp^.NextGear <> nil then ptmp^.NextGear^.PrevGear:= Gear;
        ptmp^.NextGear:= Gear
        end
    else
        begin
        Gear^.NextGear:= GearsList;
        if Gear^.NextGear <> nil then Gear^.NextGear^.PrevGear:= Gear;
        GearsList:= Gear;
        end;
end;

procedure RemoveGearFromList(Gear: PGear);
begin
if Gear^.NextGear <> nil then Gear^.NextGear^.PrevGear:= Gear^.PrevGear;
if Gear^.PrevGear <> nil then
    Gear^.PrevGear^.NextGear:= Gear^.NextGear
else
    GearsList:= Gear^.NextGear
end;

procedure spawnHealthTagForHH(HHGear: PGear; dmg: Longword);
var tag: PVisualGear;
begin
tag:= AddVisualGear(hwRound(HHGear^.X), hwRound(HHGear^.Y), vgtHealthTag, dmg);
if (tag <> nil) then
    tag^.Hedgehog:= HHGear^.Hedgehog; // the tag needs the tag to determine the text color
AllInactive:= false;
HHGear^.Active:= true;
end;

function AddGear(X, Y: LongInt; Kind: TGearType; State: Longword; dX, dY: hwFloat; Timer: LongWord): PGear;
const Counter: Longword = 0;
var gear: PGear;
begin
inc(Counter);
{$IFDEF DEBUGFILE}
AddFileLog('AddGear: #' + inttostr(Counter) + ' (' + inttostr(x) + ',' + inttostr(y) + '), d(' + floattostr(dX) + ',' + floattostr(dY) + ') type = ' + EnumToStr(Kind));
{$ENDIF}

New(gear);
FillChar(gear^, sizeof(TGear), 0);
gear^.X:= int2hwFloat(X);
gear^.Y:= int2hwFloat(Y);
gear^.Kind := Kind;
gear^.State:= State;
gear^.Active:= true;
gear^.dX:= dX;
gear^.dY:= dY;
gear^.doStep:= doStepHandlers[Kind];
gear^.CollisionIndex:= -1;
gear^.Timer:= Timer;
gear^.Z:= cUsualZ;
gear^.FlightTime:= 0;
gear^.uid:= Counter;
gear^.SoundChannel:= -1;
gear^.ImpactSound:= sndNone;
gear^.nImpactSounds:= 0;

if CurrentTeam <> nil then
    begin
    gear^.Hedgehog:= CurrentHedgehog;
    gear^.IntersectGear:= CurrentHedgehog^.Gear
    end;

case Kind of
     gtBomb,
     gtClusterBomb,
     gtGasBomb: begin
                gear^.ImpactSound:= sndGrenadeImpact;
                gear^.nImpactSounds:= 1;
                gear^.AdvBounce:= 1;
                gear^.Radius:= 5;
                gear^.Elasticity:= _0_8;
                gear^.Friction:= _0_8;
                gear^.Density:= _1_5;
                gear^.RenderTimer:= true;
                if gear^.Timer = 0 then gear^.Timer:= 3000
                end;
  gtWatermelon: begin
                gear^.ImpactSound:= sndMelonImpact;
                gear^.nImpactSounds:= 1;
                gear^.AdvBounce:= 1;
                gear^.Radius:= 6;
                gear^.Elasticity:= _0_8;
                gear^.Friction:= _0_995;
                gear^.Density:= _2;
                gear^.RenderTimer:= true;
                if gear^.Timer = 0 then gear^.Timer:= 3000
                end;
  gtMelonPiece: begin
                gear^.Density:= _2;
                end;
    gtHedgehog: begin
                gear^.AdvBounce:= 1;
                gear^.Radius:= cHHRadius;
                gear^.Elasticity:= _0_35;
                gear^.Friction:= _0_999;
                gear^.Angle:= cMaxAngle div 2;
                gear^.Density:= _3;
                gear^.Z:= cHHZ;
                if (GameFlags and gfAISurvival) <> 0 then
                    if gear^.Hedgehog^.BotLevel > 0 then
                        gear^.Hedgehog^.Effects[heResurrectable] := true;
                end;
       gtShell: begin
                gear^.Radius:= 4;
                gear^.Density:= _1;
                end;
       gtSnowball: begin
                gear^.Radius:= 4;
                gear^.Elasticity:= _1;
                gear^.Friction:= _1;
                gear^.Density:= _0_5;
                end;

     gtFlake: begin
                with Gear^ do
                    begin
                    DirAngle:= random * 360;
                    dx.isNegative:= GetRandom(2) = 0;
                    dx.QWordValue:= GetRandom(100000000);
                    dy.isNegative:= false;
                    dy.QWordValue:= GetRandom(70000000);
                    if GetRandom(2) = 0 then dx := -dx;
                    Health:= random(vobFrameTicks);
                    Timer:= random(vobFramesCount);
                    Angle:= (random(2) * 2 - 1) * (1 + random(10000)) * vobVelocity
                    end
                end;
       gtGrave: begin
                gear^.ImpactSound:= sndGraveImpact;
                gear^.nImpactSounds:= 1;
                gear^.Radius:= 10;
                gear^.Elasticity:= _0_6;
                end;
         gtBee: begin
                gear^.Radius:= 5;
                gear^.Timer:= 500;
                gear^.RenderTimer:= true;
                gear^.Elasticity:= _0_9;
                gear^.Tag:= getRandom(32);
                end;
 gtShotgunShot: begin
                gear^.Timer:= 900;
                gear^.Radius:= 2
                end;
  gtPickHammer: begin
                gear^.Radius:= 10;
                gear^.Timer:= 4000
                end;
   gtHammerHit: begin
                gear^.Radius:= 8;
                gear^.Timer:= 125
                end;
        gtRope: begin
                gear^.Radius:= 3;
                gear^.Friction:= _450 * _0_01 * cRopePercent;
                RopePoints.Count:= 0;
                end;
        gtMine: begin
                gear^.Health:= 10;
                gear^.State:= gear^.State or gstMoving;
                gear^.Radius:= 2;
                gear^.Elasticity:= _0_55;
                gear^.Friction:= _0_995;
                gear^.Density:= _0_9;
                if cMinesTime < 0 then
                    gear^.Timer:= getrandom(51)*100
                else
                    gear^.Timer:= cMinesTime;
                end;
       gtSMine: begin
                gear^.Health:= 10;
                gear^.State:= gear^.State or gstMoving;
                gear^.Radius:= 2;
                gear^.Elasticity:= _0_55;
                gear^.Friction:= _0_995;
                gear^.Density:= _0_9;
                gear^.Timer:= 500;
                end;
        gtCase: begin
                gear^.ImpactSound:= sndGraveImpact;
                gear^.nImpactSounds:= 1;
                gear^.Radius:= 16;
                gear^.Elasticity:= _0_3
                end;
  gtExplosives: begin
                gear^.ImpactSound:= sndGrenadeImpact;
                gear^.nImpactSounds:= 1;
                gear^.Radius:= 16;
                gear^.Elasticity:= _0_4;
                gear^.Friction:= _0_995;
                gear^.Density:= _6;
                gear^.Health:= cBarrelHealth
                end;
  gtDEagleShot: begin
                gear^.Radius:= 1;
                gear^.Health:= 50
                end;
  gtSniperRifleShot: begin
                gear^.Radius:= 1;
                gear^.Health:= 50
                end;
    gtDynamite: begin
                gear^.Radius:= 3;
                gear^.Elasticity:= _0_55;
                gear^.Friction:= _0_03;
                gear^.Density:= _2;
                gear^.Timer:= 5000;
                end;
     gtCluster: begin
                gear^.Radius:= 2;
                gear^.Density:= _1_5;
                gear^.RenderTimer:= true
                end;
      gtShover: gear^.Radius:= 20;
       gtFlame: begin
                gear^.Tag:= GetRandom(32);
                gear^.Radius:= 1;
                gear^.Health:= 5;
                gear^.Density:= _1;
                if (gear^.dY.QWordValue = 0) and (gear^.dX.QWordValue = 0) then
                    begin
                    gear^.dY:= (getrandom - _0_8) * _0_03;
                    gear^.dX:= (getrandom - _0_5) * _0_4
                    end
                end;
   gtFirePunch: begin
                gear^.Radius:= 15;
                gear^.Tag:= Y
                end;
     gtAirBomb: begin
                gear^.Radius:= 5;
                gear^.Density:= _2;
                end;
   gtBlowTorch: begin
                gear^.Radius:= cHHRadius + cBlowTorchC;
                gear^.Timer:= 7500
                end;
    gtSwitcher: begin
                gear^.Z:= cCurrHHZ
                end;
      gtTarget: begin
                gear^.ImpactSound:= sndGrenadeImpact;
                gear^.nImpactSounds:= 1;
                gear^.Radius:= 10;
                gear^.Elasticity:= _0_3;
                gear^.Timer:= 0
                end;
      gtMortar: begin
                gear^.Radius:= 4;
                gear^.Elasticity:= _0_2;
                gear^.Friction:= _0_08;
                gear^.Density:= _1;
                end;
        gtWhip: gear^.Radius:= 20;
      gtHammer: gear^.Radius:= 20;
    gtKamikaze: begin
                gear^.Health:= 2048;
                gear^.Radius:= 20
                end;
        gtCake: begin
                gear^.Health:= 2048;
                gear^.Radius:= 7;
                gear^.Z:= cOnHHZ;
                gear^.RenderTimer:= true;
                gear^.DirAngle:= -90 * hwSign(Gear^.dX);
                if not dX.isNegative then gear^.Angle:= 1 else gear^.Angle:= 3
                end;
 gtHellishBomb: begin
                gear^.ImpactSound:= sndHellishImpact1;
                gear^.nImpactSounds:= 4;
                gear^.AdvBounce:= 1;
                gear^.Radius:= 4;
                gear^.Elasticity:= _0_5;
                gear^.Friction:= _0_96;
                gear^.Density:= _1_5;
                gear^.RenderTimer:= true;
                gear^.Timer:= 5000
                end;
       gtDrill: begin
                gear^.Timer:= 5000;
                gear^.Radius:= 4;
                gear^.Density:= _1;
                end;
        gtBall: begin
                gear^.ImpactSound:= sndGrenadeImpact;
                gear^.nImpactSounds:= 1;
                gear^.AdvBounce:= 1;
                gear^.Radius:= 5;
                gear^.Tag:= random(8);
                gear^.Timer:= 5000;
                gear^.Elasticity:= _0_7;
                gear^.Friction:= _0_995;
                gear^.Density:= _1_5;
                end;
     gtBallgun: begin
                gear^.Timer:= 5001;
                end;
     gtRCPlane: begin
                gear^.Timer:= 15000;
                gear^.Health:= 3;
                gear^.Radius:= 8
                end;
     gtJetpack: begin
                gear^.Health:= 2000;
                gear^.Damage:= 100
                end;
     gtMolotov: begin
                gear^.Radius:= 6;
                gear^.Density:= _2;
                end;
       gtBirdy: begin
                gear^.Radius:= 16; // todo: check
                gear^.Timer:= 0;
                gear^.Health := 2000;
                gear^.FlightTime := 2;
                end;
         gtEgg: begin
                gear^.Radius:= 4;
                gear^.Elasticity:= _0_6;
                gear^.Friction:= _0_96;
                gear^.Density:= _1;
                if gear^.Timer = 0 then gear^.Timer:= 3000
                end;
      gtPortal: begin
                gear^.ImpactSound:= sndMelonImpact;
                gear^.nImpactSounds:= 1;
                gear^.AdvBounce:= 0;
                gear^.Radius:= 16;
                gear^.Tag:= 0;
                gear^.Timer:= 15000;
                gear^.RenderTimer:= false;
                gear^.Health:= 100;
                end;
       gtPiano: begin
                gear^.Radius:= 32;
                gear^.Density:= _50;
                end;
 gtSineGunShot: begin
                gear^.Radius:= 5;
                gear^.Health:= 6000;
                end;
gtFlamethrower: begin
                gear^.Tag:= 10;
                gear^.Timer:= 10;
                gear^.Health:= 500;
                gear^.Damage:= 100;
                end;
 gtPoisonCloud: begin
                gear^.Timer:= 5000;
                gear^.dY:= int2hwfloat(-4 + longint(getRandom(8))) / 1000;
                end;
 gtResurrector: begin
                gear^.Radius := 100;
                gear^.Tag := 0
                end;
     gtWaterUp: begin
                gear^.Tag := 47;
                end;
  gtNapalmBomb: begin
                gear^.Timer:= 1000;
                gear^.Radius:= 5;
                gear^.Density:= _1_5;
                end;
    end;

InsertGearToList(gear);
AddGear:= gear;

ScriptCall('onGearAdd', gear^.uid);
end;

procedure DeleteGear(Gear: PGear);
var team: PTeam;
    t,i: Longword;
    k: boolean;
begin

ScriptCall('onGearDelete', gear^.uid);

DeleteCI(Gear);

if Gear^.Tex <> nil then
    begin
    FreeTexture(Gear^.Tex);
    Gear^.Tex:= nil
    end;

// make sure that portals have their link removed before deletion
if (Gear^.Kind = gtPortal) then
    begin
    if (Gear^.IntersectGear <> nil) then
        if (Gear^.IntersectGear^.IntersectGear = Gear) then
            Gear^.IntersectGear^.IntersectGear:= nil;
    end
else if Gear^.Kind = gtHedgehog then
    if (CurAmmoGear <> nil) and (CurrentHedgehog^.Gear = Gear) then
        begin
        Gear^.Message:= gmDestroy;
        CurAmmoGear^.Message:= gmDestroy;
        exit
        end
    else
        begin
        if (hwRound(Gear^.Y) >= cWaterLine) then
            begin
            t:= max(Gear^.Damage, Gear^.Health);
            Gear^.Damage:= t;
            if (cWaterOpacity < $FF) and (hwRound(Gear^.Y) < cWaterLine + 256) then
                spawnHealthTagForHH(Gear, t);
            uStats.HedgehogDamaged(Gear)
            end;

        team:= Gear^.Hedgehog^.Team;
        if CurrentHedgehog^.Gear = Gear then
            FreeActionsList; // to avoid ThinkThread on drawned gear

        Gear^.Hedgehog^.Gear:= nil;
        if Gear^.Hedgehog^.King then
            begin
            // are there any other kings left? Just doing nil check.  Presumably a mortally wounded king will get reaped soon enough
            k:= false;
            for i:= 0 to Pred(team^.Clan^.TeamsNumber) do
                if (team^.Clan^.Teams[i]^.Hedgehogs[0].Gear <> nil) then k:= true;
            if not k then
                for i:= 0 to Pred(team^.Clan^.TeamsNumber) do
                    begin
                    team^.Clan^.Teams[i]^.hasGone:= true;
                    TeamGoneEffect(team^.Clan^.Teams[i]^)
                    end
            end;
        inc(KilledHHs);
        RecountTeamHealth(team);
        if (CurrentHedgehog <> nil) and CurrentHedgehog^.Effects[heResurrectable] and not Gear^.Hedgehog^.Effects[heResurrectable] then
            with CurrentHedgehog^ do 
                begin
                inc(Team^.stats.AIKills);
                if Team^.AIKillsTex <> nil then FreeTexture(Team^.AIKillsTex);
                Team^.AIKillsTex := RenderStringTex(inttostr(Team^.stats.AIKills), Team^.Clan^.Color, fnt16);
                end
        end;
{$IFDEF DEBUGFILE}
with Gear^ do AddFileLog('Delete: #' + inttostr(uid) + ' (' + inttostr(hwRound(x)) + ',' + inttostr(hwRound(y)) + '), d(' + floattostr(dX) + ',' + floattostr(dY) + ') type = ' + EnumToStr(Kind));
{$ENDIF}

if CurAmmoGear = Gear then CurAmmoGear:= nil;
if FollowGear = Gear then FollowGear:= nil;
RemoveGearFromList(Gear);
Dispose(Gear)
end;

function CheckNoDamage: boolean; // returns TRUE in case of no damaged hhs
var Gear: PGear;
    dmg: LongInt;
begin
CheckNoDamage:= true;
Gear:= GearsList;
while Gear <> nil do
    begin
    if (Gear^.Kind = gtHedgehog) and (((GameFlags and gfInfAttack) = 0) or ((Gear^.dX.QWordValue < _0_000004.QWordValue) and (Gear^.dY.QWordValue < _0_000004.QWordValue))) then
        begin
        if (not isInMultiShoot) then inc(Gear^.Damage, Gear^.Karma);
        if (Gear^.Damage <> 0) and
        (not Gear^.Invulnerable) then
            begin
            CheckNoDamage:= false;
            uStats.HedgehogDamaged(Gear);
            dmg:= Gear^.Damage;
            if Gear^.Health < dmg then
                begin
                Gear^.Active:= true;
                Gear^.Health:= 0
                end
            else
                dec(Gear^.Health, dmg);

            if (Gear^.Hedgehog^.Team = CurrentTeam) and
               (Gear^.Damage <> Gear^.Karma) and
                not Gear^.Hedgehog^.King and
                not Gear^.Hedgehog^.Effects[hePoisoned] and
                not SuddenDeathDmg then
                Gear^.State:= Gear^.State or gstLoser;

            spawnHealthTagForHH(Gear, dmg);

            RenderHealth(Gear^.Hedgehog^);
            RecountTeamHealth(Gear^.Hedgehog^.Team);

            end;
        if (not isInMultiShoot) then Gear^.Karma:= 0;
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
            if Gear^.Hedgehog^.Effects[hePoisoned] then
                begin
                inc(tmp, ModifyDamage(5, Gear));
                if (GameFlags and gfResetHealth) <> 0 then dec(Gear^.Hedgehog^.InitialHealth)  // does not need a minimum check since <= 1 basically disables it
                end;
            if (TotalRounds > cSuddenDTurns - 1) then
                begin
                inc(tmp, cHealthDecrease);
                if (GameFlags and gfResetHealth) <> 0 then dec(Gear^.Hedgehog^.InitialHealth, cHealthDecrease)
                end;
            if Gear^.Hedgehog^.King then
                begin
                flag:= false;
                team:= Gear^.Hedgehog^.Team;
                for i:= 0 to Pred(team^.HedgehogsNumber) do
                    if (team^.Hedgehogs[i].Gear <> nil) and
                        (not team^.Hedgehogs[i].King) and
                        (team^.Hedgehogs[i].Gear^.Health > team^.Hedgehogs[i].Gear^.Damage)
                    then flag:= true;
                if not flag then
                    begin
                    inc(tmp, 5);
                    if (GameFlags and gfResetHealth) <> 0 then dec(Gear^.Hedgehog^.InitialHealth, 5)
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
const delay: LongWord = 0;
      delay2: LongWord = 0;
    step: (stDelay, stChDmg, stSweep, stTurnReact,
            stAfterDelay, stChWin, stWater, stChWin2, stHealth,
            stSpawn, stNTurn) = stDelay;
var Gear, t: PGear;
    i, AliveCount: LongInt;
    s: shortstring;
begin
PrvInactive:= AllInactive;
AllInactive:= true;

if (StepSoundTimer > 0) and (StepSoundChannel < 0) then
    StepSoundChannel:= LoopSound(sndSteps)
else if (StepSoundTimer = 0) and (StepSoundChannel > -1) then
    begin
    StopSound(StepSoundChannel);
    StepSoundChannel:= -1
    end;

if StepSoundTimer > 0 then
    dec(StepSoundTimer, 1);

t:= GearsList;
while t <> nil do
    begin
    Gear:= t;
    t:= Gear^.NextGear;

    if Gear^.Active then
        begin
        if Gear^.RenderTimer and (Gear^.Timer > 500) and ((Gear^.Timer mod 1000) = 0) then
            begin
            if Gear^.Tex <> nil then FreeTexture(Gear^.Tex);
            Gear^.Tex:= RenderStringTex(inttostr(Gear^.Timer div 1000), cWhiteColor, fntSmall);
            end;
        Gear^.doStep(Gear);
        // might be useful later
        //ScriptCall('onGearStep', Gear^.uid);
        end
    end;

if AllInactive then
case step of
    stDelay: begin
        if delay = 0 then
            delay:= cInactDelay
        else
            dec(delay);

        if delay = 0 then
            inc(step)
        end;
    stChDmg: if CheckNoDamage then inc(step) else step:= stDelay;
    stSweep: if SweepDirty then
                begin
                SetAllToActive;
                step:= stChDmg
                end else inc(step);
    stTurnReact: begin
        if (not bBetweenTurns) and (not isInMultiShoot) then
            begin
            uStats.TurnReaction;
            inc(step)
        end else
            inc(step, 2);
        end;
    stAfterDelay: begin
        if delay = 0 then
            delay:= cInactDelay
        else
            dec(delay);

        if delay = 0 then
        inc(step)
        end;
    stChWin: begin
            CheckForWin;
            inc(step)
            end;
    stWater: if (not bBetweenTurns) and (not isInMultiShoot) then
                begin
                if TotalRounds = cSuddenDTurns + 1 then bWaterRising:= true;

                if bWaterRising and (cWaterRise > 0) then
                    AddGear(0, 0, gtWaterUp, 0, _0, _0, 0)^.Tag:= cWaterRise;

                inc(step)
                end else inc(step);
    stChWin2: begin
            CheckForWin;
            inc(step)
            end;
    stHealth: begin
            if (cWaterRise <> 0) or (cHealthDecrease <> 0) then
                begin
                if (TotalRounds = cSuddenDTurns) and not SuddenDeathDmg and not isInMultiShoot then
                    begin
                    SuddenDeathDmg:= true;
                    AddCaption(trmsg[sidSuddenDeath], cWhiteColor, capgrpGameState);
                    playSound(sndSuddenDeath)
                    end
                else if (TotalRounds < cSuddenDTurns) and not isInMultiShoot then
                    begin
                    i:= cSuddenDTurns - TotalRounds;
                    s:= inttostr(i);
                    if i = 1 then
                        AddCaption(trmsg[sidRoundSD], cWhiteColor, capgrpGameState)
                    else if i in [2, 5, 10, 15, 20, 25, 50, 100] then
                        AddCaption(Format(trmsg[sidRoundsSD], s), cWhiteColor, capgrpGameState);
                    end;
                end;
            if bBetweenTurns
                or isInMultiShoot
                or (TotalRounds = -1) then inc(step)
            else begin
                bBetweenTurns:= true;
                HealthMachine;
                step:= stChDmg
                end
            end;
    stSpawn: begin
            if not isInMultiShoot then SpawnBoxOfSmth;
            inc(step)
            end;
    stNTurn: begin
            if isInMultiShoot then
                isInMultiShoot:= false
            else begin
                // delayed till after 0.9.12
                // reset to default zoom
                //ZoomValue:= ZoomDefault;
                with CurrentHedgehog^ do
                    if (Gear <> nil)
                        and ((Gear^.State and gstAttacked) = 0)
                        and (MultiShootAttacks > 0) then OnUsedAmmo(CurrentHedgehog^);

                EndTurnCleanup;

                FreeActionsList; // could send -left, -right and similar commands, so should be called before /nextturn

                ParseCommand('/nextturn', true);
                SwitchHedgehog;

                AfterSwitchHedgehog;
                bBetweenTurns:= false
                end;
            step:= Low(step)
            end;
    end
else if ((GameFlags and gfInfAttack) <> 0) then
    begin
    if delay2 = 0 then
        delay2:= cInactDelay * 4
    else
        begin
        dec(delay2);

        if ((delay2 mod cInactDelay) = 0) and (CurrentHedgehog <> nil) and (CurrentHedgehog^.Gear <> nil) then 
            CurrentHedgehog^.Gear^.State:= CurrentHedgehog^.Gear^.State and not gstAttacked;
        if delay2 = 0 then
            begin
            SweepDirty;
            CheckNoDamage;
            AliveCount:= 0; // shorter version of check for win to allow typical step activity to proceed
            for i:= 0 to Pred(ClansCount) do
                if ClansArray[i]^.ClanHealth > 0 then inc(AliveCount);
            if (AliveCount <= 1) and ((GameFlags and gfOneClanMode) = 0) then
                begin
                step:= stChDmg;
                TurnTimeLeft:= 0
                end
            end
        end
    end;

if TurnTimeLeft > 0 then
        if CurrentHedgehog^.Gear <> nil then
            if ((CurrentHedgehog^.Gear^.State and gstAttacking) = 0)
                and not isInMultiShoot then
                begin
                if (TurnTimeLeft = 5000)
                    and (cHedgehogTurnTime >= 10000)
                    and (not PlacingHogs)
                    and (CurrentHedgehog^.Gear <> nil)
                    and ((CurrentHedgehog^.Gear^.State and gstAttacked) = 0) then
                        PlaySound(sndHurry, CurrentTeam^.voicepack);
                if ReadyTimeLeft > 0 then
                    begin
                    if ReadyTimeLeft = 2000 then
                        PlaySound(sndComeonthen, CurrentTeam^.voicepack);
                    dec(ReadyTimeLeft)
                    end
                else
                    dec(TurnTimeLeft)
                end;

if skipFlag then
    begin
    TurnTimeLeft:= 0;
    skipFlag:= false;
    inc(CurrentHedgehog^.Team^.stats.TurnSkips);
    end;

if ((GameTicks and $FFFF) = $FFFF) then
    begin
    if (not CurrentTeam^.ExtDriven) then
        SendIPCTimeInc;

    if (not CurrentTeam^.ExtDriven) or CurrentTeam^.hasGone then
        inc(hiTicks) // we do not recieve a message for this
    end;

ScriptCall('onGameTick');
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
                            Gear^.Invulnerable:= false;
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
   
    if ((GameFlags and gfResetWeps) <> 0) and not PlacingHogs then
        ResetWeapons;

    if (GameFlags and gfResetHealth) <> 0 then
        for i:= 0 to Pred(TeamsCount) do
            RecountTeamHealth(TeamsArray[i])
end;

procedure ApplyDamage(Gear: PGear; Damage: Longword; Source: TDamageSource);
var s: shortstring;
    vampDmg, tmpDmg, i: Longword;
    vg: PVisualGear;
begin
    if (Gear^.Kind = gtHedgehog) and (Damage>=1) then
    begin
    HHHurt(Gear^.Hedgehog, Source);
    AddDamageTag(hwRound(Gear^.X), hwRound(Gear^.Y), Damage, Gear^.Hedgehog^.Team^.Clan^.Color);
    tmpDmg:= min(Damage, max(0,Gear^.Health-Gear^.Damage));
    if (Gear <> CurrentHedgehog^.Gear) and (CurrentHedgehog^.Gear <> nil) and (tmpDmg >= 1) then
        begin
        if cVampiric then
            begin
            vampDmg:= hwRound(int2hwFloat(tmpDmg)*_0_8);
            if vampDmg >= 1 then
                begin
                // was considering pulsing on attack, Tiy thinks it should be permanent while in play
                //CurrentHedgehog^.Gear^.State:= CurrentHedgehog^.Gear^.State or gstVampiric;
                inc(CurrentHedgehog^.Gear^.Health,vampDmg);
                str(vampDmg, s);
                s:= '+' + s;
                AddCaption(s, CurrentHedgehog^.Team^.Clan^.Color, capgrpAmmoinfo);
                RenderHealth(CurrentHedgehog^);
                RecountTeamHealth(CurrentHedgehog^.Team);
                i:= 0;
                while i < vampDmg do
                    begin
                    vg:= AddVisualGear(hwRound(CurrentHedgehog^.Gear^.X), hwRound(CurrentHedgehog^.Gear^.Y), vgtHealth);
                    if vg <> nil then vg^.Frame:= 10;
                    inc(i, 5);
                    end;
                end
            end;
        if ((GameFlags and gfKarma) <> 0) and
           ((GameFlags and gfInvulnerable) = 0) and
           not CurrentHedgehog^.Gear^.Invulnerable then
           begin // this cannot just use Damage or it interrupts shotgun and gets you called stupid
           inc(CurrentHedgehog^.Gear^.Karma, tmpDmg);
           spawnHealthTagForHH(CurrentHedgehog^.Gear, tmpDmg);
           end;
        end;
    end;
    inc(Gear^.Damage, Damage);
    ScriptCall('onGearDamage', Gear^.UID, Damage);
end;

procedure SetAllToActive;
var t: PGear;
begin
AllInactive:= false;
t:= GearsList;
while t <> nil do
    begin
    t^.Active:= true;
    t:= t^.NextGear
    end
end;

procedure SetAllHHToActive;
var t: PGear;
begin
AllInactive:= false;
t:= GearsList;
while t <> nil do
    begin
    if t^.Kind = gtHedgehog then t^.Active:= true;
    t:= t^.NextGear
    end
end;


procedure DrawGears;
var Gear: PGear;
    x, y: LongInt;
begin
Gear:= GearsList;
while Gear <> nil do
    begin
    x:= hwRound(Gear^.X) + WorldDx;
    y:= hwRound(Gear^.Y) + WorldDy;
    RenderGear(Gear, x, y);
    Gear:= Gear^.NextGear
    end;
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
var i: LongInt;
    Gear: PGear;
begin
AddGear(0, 0, gtATStartGame, 0, _0, _0, 2000);

if (TrainingFlags and tfSpawnTargets) <> 0 then
    begin
    TrainingTargetGear:= AddGear(0, 0, gtTarget, 0, _0, _0, 0);
    FindPlace(TrainingTargetGear, false, 0, LAND_WIDTH);
    end;

for i:= 0 to Pred(cLandMines) do
    begin
    Gear:= AddGear(0, 0, gtMine, 0, _0, _0, 0);
    FindPlace(Gear, false, 0, LAND_WIDTH);
    end;
for i:= 0 to Pred(cExplosives) do
    begin
    Gear:= AddGear(0, 0, gtExplosives, 0, _0, _0, 0);
    FindPlace(Gear, false, 0, LAND_WIDTH);
    end;

if (GameFlags and gfLowGravity) <> 0 then
    begin
    cGravity:= cMaxWindSpeed;
    cGravityf:= 0.00025
    end;

if (GameFlags and gfVampiric) <> 0 then
    cVampiric:= true;

Gear:= GearsList;
if (GameFlags and gfInvulnerable) <> 0 then
   while Gear <> nil do
       begin
       Gear^.Invulnerable:= true;  // this is only checked on hogs right now, so no need for gear type check
       Gear:= Gear^.NextGear
       end;

if (GameFlags and gfLaserSight) <> 0 then
    cLaserSighting:= true;

if (GameFlags and gfArtillery) <> 0 then
    cArtillery:= true;

if not hasBorder and ((Theme = 'Snow') or (Theme = 'Christmas')) then
    for i:= 0 to Pred(vobCount*2) do
        AddGear(GetRandom(LAND_WIDTH+1024)-512, LAND_HEIGHT - GetRandom(1024), gtFlake, 0, _0, _0, 0);
end;

procedure doMakeExplosion(X, Y, Radius: LongInt; Mask: LongWord);
begin
doMakeExplosion(X, Y, Radius, Mask, $FFFFFFFF);
end;

procedure doMakeExplosion(X, Y, Radius: LongInt; Mask, Tint: LongWord);
var Gear: PGear;
    dmg, dmgRadius, dmgBase: LongInt;
    fX, fY: hwFloat;
    vg: PVisualGear;
    i, cnt: LongInt;
begin
TargetPoint.X:= NoPointX;
{$IFDEF DEBUGFILE}if Radius > 4 then AddFileLog('Explosion: at (' + inttostr(x) + ',' + inttostr(y) + ')');{$ENDIF}
if Radius > 25 then KickFlakes(Radius, X, Y);

if ((Mask and EXPLNoGfx) = 0) then
    begin
    vg:= nil;
    if Radius > 50 then vg:= AddVisualGear(X, Y, vgtBigExplosion)
    else if Radius > 10 then vg:= AddVisualGear(X, Y, vgtExplosion);
    if vg <> nil then
        vg^.Tint:= Tint;
    end;
if (Mask and EXPLAutoSound) <> 0 then PlaySound(sndExplosion);

if (Mask and EXPLAllDamageInRadius) = 0 then
    dmgRadius:= Radius shl 1
else
    dmgRadius:= Radius;
dmgBase:= dmgRadius + cHHRadius div 2;
fX:= int2hwFloat(X);
fY:= int2hwFloat(Y);
Gear:= GearsList;
while Gear <> nil do
    begin
    dmg:= 0;
    //dmg:= dmgRadius  + cHHRadius div 2 - hwRound(Distance(Gear^.X - int2hwFloat(X), Gear^.Y - int2hwFloat(Y)));
    //if (dmg > 1) and
    if (Gear^.State and gstNoDamage) = 0 then
        begin
        case Gear^.Kind of
            gtHedgehog,
                gtMine,
                gtSMine,
                gtCase,
                gtTarget,
                gtFlame,
                gtExplosives: begin
// Run the calcs only once we know we have a type that will need damage
                        if hwRound(hwAbs(Gear^.X-fX)+hwAbs(Gear^.Y-fY)) < dmgBase then
                            dmg:= dmgBase - hwRound(Distance(Gear^.X - fX, Gear^.Y - fY));
                        if dmg > 1 then
                            begin
                            dmg:= ModifyDamage(min(dmg div 2, Radius), Gear);
                            //{$IFDEF DEBUGFILE}AddFileLog('Damage: ' + inttostr(dmg));{$ENDIF}
                            if (Mask and EXPLNoDamage) = 0 then
                                begin
                                if not Gear^.Invulnerable then
                                    ApplyDamage(Gear, dmg, dsExplosion)
                                else
                                    Gear^.State:= Gear^.State or gstWinner;
                                end;
                            if ((Mask and EXPLDoNotTouchAny) = 0) and (((Mask and EXPLDoNotTouchHH) = 0) or (Gear^.Kind <> gtHedgehog)) then
                                begin
                                DeleteCI(Gear);
                                Gear^.dX:= Gear^.dX + SignAs(_0_005 * dmg + cHHKick, Gear^.X - fX);
                                Gear^.dY:= Gear^.dY + SignAs(_0_005 * dmg + cHHKick, Gear^.Y - fY);
                                Gear^.State:= (Gear^.State or gstMoving) and (not gstLoser);
                                if not Gear^.Invulnerable then
                                    Gear^.State:= (Gear^.State or gstMoving) and (not gstWinner);
                                Gear^.Active:= true;
                                if Gear^.Kind <> gtFlame then FollowGear:= Gear
                                end;
                            if ((Mask and EXPLPoisoned) <> 0) and (Gear^.Kind = gtHedgehog) then
                                Gear^.Hedgehog^.Effects[hePoisoned] := true;
                            end;

                        end;
                gtGrave: begin
// Run the calcs only once we know we have a type that will need damage
                        if hwRound(hwAbs(Gear^.X-fX)+hwAbs(Gear^.Y-fY)) < dmgBase then
                            dmg:= dmgBase - hwRound(Distance(Gear^.X - fX, Gear^.Y - fY));
                        if dmg > 1 then
                            begin
                            dmg:= ModifyDamage(min(dmg div 2, Radius), Gear);
                            Gear^.dY:= - _0_004 * dmg;
                            Gear^.Active:= true
                            end
                        end;
            end;
        end;
    Gear:= Gear^.NextGear
    end;

if (Mask and EXPLDontDraw) = 0 then
    if (GameFlags and gfSolidLand) = 0 then
        begin
        cnt:= DrawExplosion(X, Y, Radius) div 1608; // approx 2 16x16 circles to erase per chunk
        if cnt > 0 then
            for i:= 0 to cnt do
                AddVisualGear(X, Y, vgtChunk)
        end;

uAIMisc.AwareOfExplosion(0, 0, 0)
end;

procedure ShotgunShot(Gear: PGear);
var t: PGear;
    dmg: LongInt;
begin
Gear^.Radius:= cShotgunRadius;
t:= GearsList;
while t <> nil do
    begin
    dmg:= ModifyDamage(min(Gear^.Radius + t^.Radius - hwRound(Distance(Gear^.X - t^.X, Gear^.Y - t^.Y)), 25), t);
    if dmg > 0 then
    case t^.Kind of
        gtHedgehog,
            gtMine,
            gtSMine,
            gtCase,
            gtTarget,
            gtExplosives: begin
                    if (not t^.Invulnerable) then
                        ApplyDamage(t, dmg, dsBullet)
                    else
                        Gear^.State:= Gear^.State or gstWinner;

                    DeleteCI(t);
                    t^.dX:= t^.dX + Gear^.dX * dmg * _0_01 + SignAs(cHHKick, Gear^.dX);
                    t^.dY:= t^.dY + Gear^.dY * dmg * _0_01;
                    t^.State:= t^.State or gstMoving;
                    t^.Active:= true;
                    FollowGear:= t
                    end;
            gtGrave: begin
                    t^.dY:= - _0_1;
                    t^.Active:= true
                    end;
        end;
    t:= t^.NextGear
    end;
if (GameFlags and gfSolidLand) = 0 then DrawExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), cShotgunRadius)
end;

procedure AmmoShove(Ammo: PGear; Damage, Power: LongInt);
var t: PGearArray;
    Gear: PGear;
    i, tmpDmg: LongInt;
    VGear: PVisualGear;
begin
t:= CheckGearsCollision(Ammo);
// Just to avoid hogs on rope dodging fire.
if (CurAmmoGear <> nil) and (CurAmmoGear^.Kind = gtRope) and
   (CurrentHedgehog^.Gear <> nil) and (CurrentHedgehog^.Gear^.CollisionIndex = -1) and
   (sqr(hwRound(Ammo^.X) - hwRound(CurrentHedgehog^.Gear^.X)) + sqr(hwRound(Ammo^.Y) - hwRound(CurrentHedgehog^.Gear^.Y)) <= sqr(cHHRadius + Ammo^.Radius)) then
    begin
    t^.ar[t^.Count]:= CurrentHedgehog^.Gear;
    inc(t^.Count)
    end;

i:= t^.Count;

if (Ammo^.Kind = gtFlame) and (i > 0) then Ammo^.Health:= 0;
while i > 0 do
    begin
    dec(i);
    Gear:= t^.ar[i];
    tmpDmg:= ModifyDamage(Damage, Gear);
    if (Gear^.State and gstNoDamage) = 0 then
        begin
        
        if (Ammo^.Kind = gtDEagleShot) or (Ammo^.Kind = gtSniperRifleShot) then 
            begin
            VGear := AddVisualGear(hwround(Ammo^.X), hwround(Ammo^.Y), vgtBulletHit);
            if VGear <> nil then VGear^.Angle := DxDy2Angle(-Ammo^.dX, Ammo^.dY);
            end;
        
        if (Gear^.Kind = gtHedgehog) and (Ammo^.State and gsttmpFlag <> 0) and (Ammo^.Kind = gtShover) then Gear^.FlightTime:= 1;

        case Gear^.Kind of
            gtHedgehog,
            gtMine,
            gtSMine,
            gtTarget,
            gtCase,
            gtExplosives: begin
                    if (Ammo^.Kind = gtDrill) then begin Ammo^.Timer:= 0; exit; end;
                    if (not Gear^.Invulnerable) then
                        ApplyDamage(Gear, tmpDmg, dsShove)
                    else
                        Gear^.State:= Gear^.State or gstWinner;
                    if (Gear^.Kind = gtExplosives) and (Ammo^.Kind = gtBlowtorch) then ApplyDamage(Gear, tmpDmg * 100, dsUnknown); // crank up damage for explosives + blowtorch

                    DeleteCI(Gear);
                    if (Gear^.Kind = gtHedgehog) and Gear^.Hedgehog^.King then
                        begin
                        Gear^.dX:= Ammo^.dX * Power * _0_005;
                        Gear^.dY:= Ammo^.dY * Power * _0_005
                        end
                    else
                        begin
                        Gear^.dX:= Ammo^.dX * Power * _0_01;
                        Gear^.dY:= Ammo^.dY * Power * _0_01
                        end;

                    Gear^.Active:= true;
                    Gear^.State:= Gear^.State or gstMoving;

                    if TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) then
                        begin
                        if not (TestCollisionXwithXYShift(Gear, _0, -3, hwSign(Gear^.dX))
                            or TestCollisionYwithGear(Gear, -1)) then Gear^.Y:= Gear^.Y - _1;
                        if not (TestCollisionXwithXYShift(Gear, _0, -2, hwSign(Gear^.dX))
                            or TestCollisionYwithGear(Gear, -1)) then Gear^.Y:= Gear^.Y - _1;
                        if not (TestCollisionXwithXYShift(Gear, _0, -1, hwSign(Gear^.dX))
                            or TestCollisionYwithGear(Gear, -1)) then Gear^.Y:= Gear^.Y - _1;
                        end;

                    if (Ammo^.Kind <> gtFlame) or ((Ammo^.State and gsttmpFlag) = 0) then FollowGear:= Gear
                    end;
        end
        end;
    end;
if i <> 0 then SetAllToActive
end;

procedure AssignHHCoords;
var i, t, p, j: LongInt;
    ar: array[0..Pred(cMaxHHs)] of PHedgehog;
    Count: Longword;
begin
if (GameFlags and gfPlaceHog) <> 0 then PlacingHogs:= true;
if (GameFlags and gfDivideTeams) <> 0 then
    begin
    t:= 0;
    TryDo(ClansCount = 2, 'More or less than 2 clans on map in divided teams mode!', true);
    for p:= 0 to 1 do
        begin
        with ClansArray[p]^ do
            for j:= 0 to Pred(TeamsNumber) do
                with Teams[j]^ do
                    for i:= 0 to cMaxHHIndex do
                        with Hedgehogs[i] do
                            if (Gear <> nil) and (Gear^.X.QWordValue = 0) then
                                begin
                                if PlacingHogs then Unplaced:= true
                                else FindPlace(Gear, false, t, t + LAND_WIDTH div 2);// could make Gear == nil;
                                if Gear <> nil then
                                    begin
                                    Gear^.Pos:= GetRandom(49);
                                    Gear^.dX.isNegative:= p = 1;
                                    end
                                end;
        t:= LAND_WIDTH div 2
        end
    end else // mix hedgehogs
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
    // unC0Rr, while it is true user can watch value on map screen, IMO this (and check above) should be enforced in UI
    // - is there a good place to put values for the different widgets to check?  Right now they are kind of disconnected.
    //it would be nice if divide teams, forts mode and hh per map could all be checked by the team widget, or maybe disable start button
    TryDo(Count <= MaxHedgehogs, 'Too many hedgehogs for this map! (max # is ' + inttostr(MaxHedgehogs) + ')', true);
    while (Count > 0) do
        begin
        i:= GetRandom(Count);
        if PlacingHogs then ar[i]^.Unplaced:= true
        else FindPlace(ar[i]^.Gear, false, 0, LAND_WIDTH);
        if ar[i]^.Gear <> nil then
            begin
            ar[i]^.Gear^.dX.isNegative:= hwRound(ar[i]^.Gear^.X) > LAND_WIDTH div 2;
            ar[i]^.Gear^.Pos:= GetRandom(19)
            end;
        ar[i]:= ar[Count - 1];
        dec(Count)
        end
    end
end;

function GearsNear(X, Y: hwFloat; Kind: TGearType; r: LongInt): TPGearArray;
var
    t: PGear;
begin
    GearsNear := nil;
    t := GearsList;
    while t <> nil do begin
        if (t^.Kind = Kind) then begin
            if (X - t^.X)*(X - t^.X) + (Y - t^.Y)*(Y-t^.Y) <
                int2hwFloat(r)*int2hwFloat(r) then
            begin
                SetLength(GearsNear, Length(GearsNear)+1);
                GearsNear[High(GearsNear)] := t;
            end;
        end;
        t := t^.NextGear;
    end;
end;

function CheckGearNear(Gear: PGear; Kind: TGearType; rX, rY: LongInt): PGear;
var t: PGear;
begin
t:= GearsList;
rX:= sqr(rX);
rY:= sqr(rY);

while t <> nil do
    begin
    if (t <> Gear) and (t^.Kind = Kind) then
        if not((hwSqr(Gear^.X - t^.X) / rX + hwSqr(Gear^.Y - t^.Y) / rY) > _1) then
        exit(t);
    t:= t^.NextGear
    end;

CheckGearNear:= nil
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

function CheckGearsNear(mX, mY: LongInt; Kind: TGearsType; rX, rY: LongInt): PGear;
var t: PGear;
begin
t:= GearsList;
rX:= sqr(rX);
rY:= sqr(rY);
while t <> nil do
    begin
    if t^.Kind in Kind then
        if not (hwSqr(int2hwFloat(mX) - t^.X) / rX + hwSqr(int2hwFloat(mY) - t^.Y) / rY > _1) then
            exit(t);
    t:= t^.NextGear
    end;
CheckGearsNear:= nil
end;

function CountGears(Kind: TGearType): Longword;
var t: PGear;
    count: Longword = 0;
begin

t:= GearsList;
while t <> nil do
    begin
    if t^.Kind = Kind then inc(count);
    t:= t^.NextGear
    end;
CountGears:= count;
end;

procedure ResurrectHedgehog(gear: PGear);
var tempTeam : PTeam;
begin
    gear^.dX := _0;
    gear^.dY := _0;
    gear^.State := gstWait;
    uStats.HedgehogDamaged(gear);
    gear^.Damage := 0;
    gear^.Health := gear^.Hedgehog^.InitialHealth;
    gear^.Hedgehog^.Effects[hePoisoned] := false;
    if not CurrentHedgehog^.Effects[heResurrectable] then
        with CurrentHedgehog^ do 
            begin
            inc(Team^.stats.AIKills);
            if Team^.AIKillsTex <> nil then FreeTexture(Team^.AIKillsTex);
            Team^.AIKillsTex := RenderStringTex(inttostr(Team^.stats.AIKills), Team^.Clan^.Color, fnt16);
            end;
    tempTeam := gear^.Hedgehog^.Team;
    DeleteCI(gear);
    FindPlace(gear, false, 0, LAND_WIDTH, true); 
    if gear <> nil then begin
        RenderHealth(gear^.Hedgehog^);
        ScriptCall('onGearResurrect', gear^.uid);
    end;
    RecountTeamHealth(tempTeam);
end;

function SpawnCustomCrateAt(x, y: LongInt; crate: TCrateType; content: Longword): PGear;
begin
    FollowGear := AddGear(x, y, gtCase, 0, _0, _0, 0);
    cCaseFactor := 0;

    if (content > ord(High(TAmmoType))) then content := ord(High(TAmmoType));

    case crate of
        HealthCrate: begin
            FollowGear^.Health := cHealthCaseAmount;
            FollowGear^.Pos := posCaseHealth;
            AddCaption(GetEventString(eidNewHealthPack), cWhiteColor, capgrpAmmoInfo);
            end;
        AmmoCrate: begin
            FollowGear^.Pos := posCaseAmmo;
            FollowGear^.AmmoType := TAmmoType(content);
            AddCaption(GetEventString(eidNewAmmoPack), cWhiteColor, capgrpAmmoInfo);
            end;
        UtilityCrate: begin
            FollowGear^.Pos := posCaseUtility;
            FollowGear^.AmmoType := TAmmoType(content);
            AddCaption(GetEventString(eidNewUtilityPack), cWhiteColor, capgrpAmmoInfo);
            end;
    end;

    if ( (x = 0) and (y = 0) ) then FindPlace(FollowGear, true, 0, LAND_WIDTH);

    SpawnCustomCrateAt := FollowGear;
end;

procedure SpawnBoxOfSmth;
var t, aTot, uTot, a, h: LongInt;
    i: TAmmoType;
begin
if (PlacingHogs) or
   (cCaseFactor = 0) or
   (CountGears(gtCase) >= 5) or
   (GetRandom(cCaseFactor) <> 0) then exit;

FollowGear:= nil;
aTot:= 0;
uTot:= 0;
for i:= Low(TAmmoType) to High(TAmmoType) do
    if (Ammoz[i].Ammo.Propz and ammoprop_Utility) = 0 then
        inc(aTot, Ammoz[i].Probability)
    else
        inc(uTot, Ammoz[i].Probability);

t:=0;
a:=aTot;
h:= 1;

if (aTot+uTot) <> 0 then
    if ((GameFlags and gfInvulnerable) = 0) then
        begin
        h:= cHealthCaseProb * 100;
        t:= GetRandom(10000);
        a:= (10000-h)*aTot div (aTot+uTot)
        end
    else
        begin
        t:= GetRandom(aTot+uTot);
        h:= 0
        end;


if t<h then
    begin
    FollowGear:= AddGear(0, 0, gtCase, 0, _0, _0, 0);
    FollowGear^.Health:= cHealthCaseAmount;
    FollowGear^.Pos:= posCaseHealth;
    AddCaption(GetEventString(eidNewHealthPack), cWhiteColor, capgrpAmmoInfo);
    end
else if (t<a+h) then
    begin
    t:= aTot;
    if (t > 0) then
        begin
        FollowGear:= AddGear(0, 0, gtCase, 0, _0, _0, 0);
        t:= GetRandom(t);
        i:= Low(TAmmoType);
        while t >= 0 do
          begin
          inc(i);
          if (Ammoz[i].Ammo.Propz and ammoprop_Utility) = 0 then
              dec(t, Ammoz[i].Probability)
          end;
        FollowGear^.Pos:= posCaseAmmo;
        FollowGear^.AmmoType:= i;
        AddCaption(GetEventString(eidNewAmmoPack), cWhiteColor, capgrpAmmoInfo);
        end
    end
else
    begin
    t:= uTot;
    if (t > 0) then
        begin
        FollowGear:= AddGear(0, 0, gtCase, 0, _0, _0, 0);
        t:= GetRandom(t);
        i:= Low(TAmmoType);
        while t >= 0 do
          begin
          inc(i);
          if (Ammoz[i].Ammo.Propz and ammoprop_Utility) <> 0 then
              dec(t, Ammoz[i].Probability)
          end;
        FollowGear^.Pos:= posCaseUtility;
        FollowGear^.AmmoType:= i;
        AddCaption(GetEventString(eidNewUtilityPack), cWhiteColor, capgrpAmmoInfo);
        end
    end;

// handles case of no ammo or utility crates - considered also placing booleans in uAmmos and altering probabilities
if (FollowGear <> nil) then
    begin
    FindPlace(FollowGear, true, 0, LAND_WIDTH);

    if (FollowGear <> nil) then
        PlaySound(sndReinforce, CurrentTeam^.voicepack)
    end
end;

procedure FindPlace(var Gear: PGear; withFall: boolean; Left, Right: LongInt; skipProximity: boolean = false);

    function CountNonZeroz(x, y, r, c: LongInt): LongInt;
    var i: LongInt;
        count: LongInt = 0;
    begin
    if (y and LAND_HEIGHT_MASK) = 0 then
        for i:= max(x - r, 0) to min(x + r, LAND_WIDTH - 4) do
            if Land[y, i] <> 0 then
               begin
               inc(count);
               if count = c then exit(count)
               end;
    CountNonZeroz:= count;
    end;

var x: LongInt;
    y, sy: LongInt;
    ar: array[0..511] of TPoint;
    ar2: array[0..1023] of TPoint;
    cnt, cnt2: Longword;
    delta: LongInt;
    reallySkip, tryAgain: boolean;
begin
reallySkip:= false; // try not skipping proximity at first
tryAgain:= true;
while tryAgain do
    begin
    delta:= 250;
    cnt2:= 0;
    repeat
        x:= Left + LongInt(GetRandom(Delta));
        repeat
            inc(x, Delta);
            cnt:= 0;
            y:= min(1024, topY) - 2 * Gear^.Radius;
            while y < cWaterLine do
                begin
                repeat
                    inc(y, 2);
                until (y >= cWaterLine) or (CountNonZeroz(x, y, Gear^.Radius - 1, 1) = 0);

                sy:= y;

                repeat
                    inc(y);
                until (y >= cWaterLine) or (CountNonZeroz(x, y, Gear^.Radius - 1, 1) <> 0);

                if (y - sy > Gear^.Radius * 2) and
                   (((Gear^.Kind = gtExplosives)
                       and (y < cWaterLine)
                       and (reallySkip or (CheckGearsNear(x, y - Gear^.Radius, [gtFlame, gtHedgehog, gtMine, gtCase, gtExplosives], 60, 60) = nil))
                       and (CountNonZeroz(x, y+1, Gear^.Radius - 1, Gear^.Radius+1) > Gear^.Radius))
                   or
                     ((Gear^.Kind <> gtExplosives)
                       and (y < cWaterLine)
                       and (reallySkip or (CheckGearsNear(x, y - Gear^.Radius, [gtFlame, gtHedgehog, gtMine, gtCase, gtExplosives], 110, 110) = nil)))) then
                    begin
                    ar[cnt].X:= x;
                    if withFall then ar[cnt].Y:= sy + Gear^.Radius
                                else ar[cnt].Y:= y - Gear^.Radius;
                    inc(cnt)
                    end;

                inc(y, 45)
                end;

            if cnt > 0 then
                with ar[GetRandom(cnt)] do
                    begin
                    ar2[cnt2].x:= x;
                    ar2[cnt2].y:= y;
                    inc(cnt2)
                    end
        until (x + Delta > Right);

        dec(Delta, 60)
    until (cnt2 > 0) or (Delta < 70);
    if (cnt2 = 0) and skipProximity and not reallySkip then tryAgain:= true
    else tryAgain:= false;
    reallySkip:= true;
    end;

if cnt2 > 0 then
    with ar2[GetRandom(cnt2)] do
        begin
        Gear^.X:= int2hwFloat(x);
        Gear^.Y:= int2hwFloat(y);
        {$IFDEF DEBUGFILE}
        AddFileLog('Assigned Gear coordinates (' + inttostr(x) + ',' + inttostr(y) + ')');
        {$ENDIF}
        end
    else
    begin
    OutError('Can''t find place for Gear', false);
    if Gear^.Kind = gtHedgehog then Gear^.Hedgehog^.Effects[heResurrectable] := false;
    DeleteGear(Gear);
    Gear:= nil
    end
end;

function ModifyDamage(dmg: Longword; Gear: PGear): Longword;
var i: hwFloat;
begin
(* Invulnerability cannot be placed in here due to still needing kicks
   Not without a new damage machine.
   King check should be in here instead of ApplyDamage since Tiy wants them kicked less
*)
i:= _1;
if (CurrentHedgehog <> nil) and CurrentHedgehog^.King then i:= _1_5;
if (Gear^.Hedgehog <> nil) and (Gear^.Hedgehog^.King) then
   ModifyDamage:= hwRound(_0_01 * cDamageModifier * dmg * i * cDamagePercent * _0_5)
else
   ModifyDamage:= hwRound(_0_01 * cDamageModifier * dmg * i * cDamagePercent)
end;

function GearByUID(uid : Longword) : PGear;
var gear: PGear;
begin
GearByUID:= nil;
gear:= GearsList;
while gear <> nil do
    begin
    if gear^.uid = uid then
        begin
            GearByUID:= gear;
            exit
        end;
    gear:= gear^.NextGear
    end
end;


procedure chSkip(var s: shortstring);
begin
s:= s; // avoid compiler hint
if not CurrentTeam^.ExtDriven then SendIPC(',');
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
        if Length(s) > 2 then h:= byte(s[3])  // target hog
        end;
    // allow targetting a hog by specifying a number as the first portion of the text
    if (x < 4) and (h > byte('0')) and (h < byte('9')) then i:= h - 48;
    if i <> 0 then text:= copy(s, 4, Length(s) - 1)
    else if x < 4 then text:= copy(s, 3, Length(s) - 1)
    else text:= copy(s, 2, Length(s) - 1);

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
            if (i = 0) and (CurrentHedgehog^.Team = TeamsArray[t]) then hh:= CurrentHedgehog
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
        if hh <> nil then Gear:= AddVisualGear(0, 0, vgtSpeechBubble);
        if Gear <> nil then
            begin
            Gear^.Hedgehog:= hh;
            Gear^.Text:= text;
            Gear^.FrameTicks:= x
            end
        else ParseCommand('say ' + text, true)
        end
    else if (x >= 4) then
        begin
        SpeechType:= x-3;
        SpeechText:= text
        end;
end;

procedure initModule;
begin
    RegisterVariable('skip', vtCommand, @chSkip, false);
    RegisterVariable('hogsay', vtCommand, @chHogSay, true );

    CurAmmoGear:= nil;
    GearsList:= nil;
    KilledHHs:= 0;
    SuddenDeathDmg:= false;
    SpeechType:= 1;
    TrainingTargetGear:= nil;
    skipFlag:= false;

    AllInactive:= false;
    PrvInactive:= false;
end;

procedure freeModule;
begin
    FreeGearsList();
end;

end.
