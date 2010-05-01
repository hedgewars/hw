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
uses SDLh, uConsts, uFloat, Math;

    
type
    PGear = ^TGear;
    TGearStepProcedure = procedure (Gear: PGear);
    TGear = record
            NextGear, PrevGear: PGear;
            Active: Boolean;
            AdvBounce: Longword;
            Invulnerable: Boolean;
            RenderTimer: Boolean;
            Ammo : PAmmo;
            AmmoType : TAmmoType;  // Used to track AmmoType at time of Gear creation, since Ammo can be reassigned
            State : Longword;
            X : hwFloat;
            Y : hwFloat;
            dX: hwFloat;
            dY: hwFloat;
            Kind: TGearType;
            Pos: Longword;
            doStep: TGearStepProcedure;
            Radius: LongInt;
            Angle, Power : Longword;
            DirAngle: real;
            Timer : LongWord;
            Elasticity: hwFloat;
            Friction  : hwFloat;
            Message, MsgParam : Longword;
            Hedgehog: pointer;
            Health, Damage, Karma: LongInt;
            CollisionIndex: LongInt;
            Tag: LongInt;
            Tex: PTexture;
            Z: Longword;
            IntersectGear: PGear;
            FlightTime: Longword;
            uid: Longword;
            ImpactSound: TSound; // first sound, others have to be after it in the sounds def.
            nImpactSounds: Word; // count of ImpactSounds
            SoundChannel: LongInt
        end;

var AllInactive: boolean;
    PrvInactive: boolean;
    CurAmmoGear: PGear;
    GearsList: PGear;
    KilledHHs: Longword;
    SuddenDeathDmg: Boolean;
    SpeechType: Longword;
    SpeechText: shortstring;
    TrainingTargetGear: PGear;
    skipFlag: boolean;
    PlacingHogs: boolean; // a convenience flag to indicate placement of hogs is still in progress
    StepSoundTimer: LongInt;
    StepSoundChannel: LongInt;
    
procedure initModule;
procedure freeModule;
function  AddGear(X, Y: LongInt; Kind: TGearType; State: Longword; dX, dY: hwFloat; Timer: LongWord): PGear;
procedure ProcessGears;
procedure ResetUtilities;
procedure ApplyDamage(Gear: PGear; Damage: Longword);
procedure SetAllToActive;
procedure SetAllHHToActive;
procedure DrawGears;
procedure FreeGearsList;
procedure AddMiscGears;
procedure AssignHHCoords;
function GearByUID(uid : Longword) : PGear;
procedure InsertGearToList(Gear: PGear);
procedure RemoveGearFromList(Gear: PGear);
function ModifyDamage(dmg: Longword; Gear: PGear): Longword;
procedure FindPlace(var Gear: PGear; withFall: boolean; Left, Right: LongInt);

implementation
uses uWorld, uMisc, uStore, uConsole, uSound, uTeams, uRandom, uCollisions, uLand, uIO, uLandGraphics,
    uAIMisc, uLocale, uAI, uAmmos, uStats, uVisualGears, uScript, GLunit;

const MAXROPEPOINTS = 384;
var RopePoints: record
                Count: Longword;
                HookAngle: GLfloat;
                ar: array[0..MAXROPEPOINTS] of record
                                  X, Y: hwFloat;
                                  dLen: hwFloat;
                                  b: boolean;
                                  end;
                rounded: array[0..MAXROPEPOINTS + 2] of TVertex2f;
                end;
 
procedure DeleteGear(Gear: PGear); forward;
procedure doMakeExplosion(X, Y, Radius: LongInt; Mask: LongWord); forward;
procedure AmmoShove(Ammo: PGear; Damage, Power: LongInt); forward;
//procedure AmmoFlameWork(Ammo: PGear); forward;
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
            @doStepGrenade,
            @doStepHealthTag,
            @doStepGrave,
            @doStepBee,
            @doStepShotgunShot,
            @doStepPickHammer,
            @doStepRope,
            @doStepSmokeTrace,
            @doStepExplosion,
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
            @doStepSmokeTrace,
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
            @doStepBigExplosion,
            @doStepEggWork,
            @doStepPortal,
            @doStepPortalGun,
            @doStepPiano,
            @doStepBomb,
            @doStepSineGunShot
            );

procedure InsertGearToList(Gear: PGear);
var tmp, ptmp: PGear;
begin
if GearsList = nil then
    GearsList:= Gear
    else begin
    tmp:= GearsList;
    ptmp:= GearsList;
    while (tmp <> nil) and (tmp^.Z <= Gear^.Z) do
        begin
        ptmp:= tmp;
        tmp:= tmp^.NextGear
        end;

    if ptmp <> nil then
        begin
        Gear^.NextGear:= ptmp^.NextGear;
        Gear^.PrevGear:= ptmp;
        if ptmp^.NextGear <> nil then ptmp^.NextGear^.PrevGear:= Gear;
        ptmp^.NextGear:= Gear
        end
    else GearsList:= Gear
    end
end;

procedure RemoveGearFromList(Gear: PGear);
begin
if Gear^.NextGear <> nil then Gear^.NextGear^.PrevGear:= Gear^.PrevGear;
if Gear^.PrevGear <> nil then
    Gear^.PrevGear^.NextGear:= Gear^.NextGear
else
    GearsList:= Gear^.NextGear
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
     gtAmmo_Bomb,
     gtClusterBomb,
     gtGasBomb: begin
                gear^.ImpactSound:= sndGrenadeImpact;
                gear^.nImpactSounds:= 1;
                gear^.AdvBounce:= 1;
                gear^.Radius:= 4;
                gear^.Elasticity:= _0_6;
                gear^.Friction:= _0_96;
                gear^.RenderTimer:= true;
                if gear^.Timer = 0 then gear^.Timer:= 3000
                end;
  gtWatermelon: begin
                gear^.ImpactSound:= sndMelonImpact;
                gear^.nImpactSounds:= 1;
                gear^.AdvBounce:= 1;
                gear^.Radius:= 4;
                gear^.Elasticity:= _0_8;
                gear^.Friction:= _0_995;
                gear^.RenderTimer:= true;
                if gear^.Timer = 0 then gear^.Timer:= 3000
                end;
    gtHedgehog: begin
                gear^.AdvBounce:= 1;
                gear^.Radius:= cHHRadius;
                gear^.Elasticity:= _0_35;
                gear^.Friction:= _0_999;
                gear^.Angle:= cMaxAngle div 2;
                gear^.Z:= cHHZ;
                end;
gtAmmo_Grenade: begin // bazooka
                gear^.Radius:= 4;
                end;
   gtHealthTag: begin
                gear^.Timer:= 1500;
                gear^.Z:= 2002;
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
  gtSmokeTrace,
   gtEvilTrace: begin
                gear^.X:= gear^.X - _16;
                gear^.Y:= gear^.Y - _16;
                gear^.State:= 8;
                gear^.Z:= cSmokeZ
                end;
        gtRope: begin
                gear^.Radius:= 3;
                gear^.Friction:= _450;
                RopePoints.Count:= 0;
                end;
        gtMine: begin
                gear^.Health:= 10;
                gear^.State:= gear^.State or gstMoving;
                gear^.Radius:= 2;
                gear^.Elasticity:= _0_55;
                gear^.Friction:= _0_995;
                if cMinesTime < 0 then
                    gear^.Timer:= getrandom(4)*1000
                else
                    gear^.Timer:= cMinesTime*1;
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
                gear^.Timer:= 5000;
                end;
     gtCluster: begin
                gear^.Radius:= 2;
                gear^.RenderTimer:= true
                end;
      gtShover: gear^.Radius:= 20;
       gtFlame: begin
                gear^.Tag:= GetRandom(32);
                gear^.Radius:= 1;
                gear^.Health:= 5;
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
                gear^.Friction:= _0_08
                end;
        gtWhip: gear^.Radius:= 20;
    gtKamikaze: begin
                gear^.Health:= 2048;
                gear^.Radius:= 20
                end;
        gtCake: begin
                gear^.Health:= 2048;
                gear^.Radius:= 7;
                gear^.Z:= cOnHHZ;
                gear^.RenderTimer:= true;
                if not dX.isNegative then gear^.Angle:= 1 else gear^.Angle:= 3
                end;
 gtHellishBomb: begin
                gear^.ImpactSound:= sndHellishImpact1;
                gear^.nImpactSounds:= 4;
                gear^.AdvBounce:= 1;
                gear^.Radius:= 4;
                gear^.Elasticity:= _0_5;
                gear^.Friction:= _0_96;
                gear^.RenderTimer:= true;
                gear^.Timer:= 5000
                end;
       gtDrill: begin
                gear^.Timer:= 5000;
                gear^.Radius:= 4
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
                end;
     gtMolotov: begin 
                gear^.Radius:= 6;
                end;
       gtBirdy: begin
                gear^.Radius:= 16; // todo: check
                gear^.Timer:= 0;
                gear^.Health := 2000;
                gear^.FlightTime := 2;
                end;
gtBigExplosion: begin
                gear^.Angle:= random(360);
                end;
         gtEgg: begin 
                gear^.Radius:= 4;
                gear^.Elasticity:= _0_6;
                gear^.Friction:= _0_96;
                if gear^.Timer = 0 then gear^.Timer:= 3000
                end;
      gtPortal: begin
                gear^.ImpactSound:= sndMelonImpact;
                gear^.nImpactSounds:= 1;
                gear^.AdvBounce:= 0;
                gear^.Radius:= 16;
                end;
       gtPiano: begin
                gear^.Radius:= 32
                end;
 gtSineGunShot: begin
                gear^.Radius:= 5;
                gear^.Health:= 6000;
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

if Gear^.Kind = gtHedgehog then
    if (CurAmmoGear <> nil) and (CurrentHedgehog^.Gear = Gear) then
        begin
        Gear^.Message:= gm_Destroy;
        CurAmmoGear^.Message:= gm_Destroy;
        exit
        end
    else
        begin
        if (hwRound(Gear^.Y) >= cWaterLine) then
            begin
            t:= max(Gear^.Damage, Gear^.Health);
            Gear^.Damage:= t;
            if cWaterOpacity < $FF then
                AddGear(hwRound(Gear^.X), min(hwRound(Gear^.Y),cWaterLine+cVisibleWater+32), gtHealthTag, t, _0, _0, 0)^.Hedgehog:= Gear^.Hedgehog;
            uStats.HedgehogDamaged(Gear)
            end;

        team:= PHedgehog(Gear^.Hedgehog)^.Team;
        if CurrentHedgehog^.Gear = Gear then
            FreeActionsList; // to avoid ThinkThread on drawned gear

        PHedgehog(Gear^.Hedgehog)^.Gear:= nil;
        if PHedgehog(Gear^.Hedgehog)^.King then
            begin
            // are there any other kings left? Just doing nil check.  Presumably a mortally wounded king will get reaped soon enough
            k:= false;
            for i:= 0 to Pred(team^.Clan^.TeamsNumber) do
                if (team^.Clan^.Teams[i]^.Hedgehogs[0].Gear <> nil) then k:= true;
            if not k then
                for i:= 0 to Pred(team^.Clan^.TeamsNumber) do
                    TeamGoneEffect(team^.Clan^.Teams[i]^)
            end;
        inc(KilledHHs);
        RecountTeamHealth(team)
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
    if Gear^.Kind = gtHedgehog then
        begin
        if (not isInMultiShoot) then inc(Gear^.Damage, Gear^.Karma);
        if (Gear^.Damage <> 0) and
        (not Gear^.Invulnerable) then
            begin
            CheckNoDamage:= false;
            uStats.HedgehogDamaged(Gear);
            dmg:= Gear^.Damage;
            if Gear^.Health < dmg then
                Gear^.Health:= 0
            else
                dec(Gear^.Health, dmg);

            if (PHedgehog(Gear^.Hedgehog)^.Team = CurrentTeam) and
               (Gear^.Damage <> Gear^.Karma) and
                not PHedgehog(Gear^.Hedgehog)^.King and
                not PHedgehog(Gear^.Hedgehog)^.Effects[hePoisoned] and
                not SuddenDeathDmg then
                Gear^.State:= Gear^.State or gstLoser;

            AddGear(hwRound(Gear^.X), hwRound(Gear^.Y) - cHHRadius - 12,
                    gtHealthTag, dmg, _0, _0, 0)^.Hedgehog:= Gear^.Hedgehog;

            RenderHealth(PHedgehog(Gear^.Hedgehog)^);
            RecountTeamHealth(PHedgehog(Gear^.Hedgehog)^.Team);

            end;
        if (not isInMultiShoot) then Gear^.Karma:= 0;
        Gear^.Damage:= 0
        end;
    Gear:= Gear^.NextGear
    end;
SuddenDeathDmg:= false;
end;

procedure HealthMachine;
var Gear: PGear;
    team: PTeam;
       i: LongWord;
    flag: Boolean;
begin
	Gear:= GearsList;

	while Gear <> nil do
	begin
		if Gear^.Kind = gtHedgehog then
			begin
            if PHedgehog(Gear^.Hedgehog)^.Effects[hePoisoned] then
                begin
                inc(Gear^.Damage, min(ModifyDamage(5,Gear), max(0,Gear^.Health - 1 - Gear^.Damage)));
                if getRandom(2) = 0 then
                    PlaySound(sndPoisonCough, PHedgehog(Gear^.Hedgehog)^.Team^.voicepack)
                else
                    PlaySound(sndPoisonMoan, PHedgehog(Gear^.Hedgehog)^.Team^.voicepack);
                end;
            inc(Gear^.Damage, min(cHealthDecrease, max(0,Gear^.Health - 1 - Gear^.Damage)));
            if PHedgehog(Gear^.Hedgehog)^.King then
                begin
                flag:= false;
                team:= PHedgehog(Gear^.Hedgehog)^.Team;
                for i:= 0 to Pred(team^.HedgehogsNumber) do
                    if (team^.Hedgehogs[i].Gear <> nil) and 
                        (not team^.Hedgehogs[i].King) and 
                        (team^.Hedgehogs[i].Gear^.Health > team^.Hedgehogs[i].Gear^.Damage) 
                    then flag:= true;
                if not flag then inc(Gear^.Damage, min(5, max(0,Gear^.Health - 1 - Gear^.Damage)))
                end;
			end;

		Gear:= Gear^.NextGear
	end;
end;

procedure ProcessGears;
const delay: LongWord = 0;
    step: (stDelay, stChDmg, stSweep, stTurnReact,
            stAfterDelay, stChWin, stWater, stChWin2, stHealth,
            stSpawn, stNTurn) = stDelay;
var Gear, t: PGear;
    i: LongInt;
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

                if bWaterRising then
                AddGear(0, 0, gtWaterUp, 0, _0, _0, 0);

                inc(step)
                end else inc(step);
    stChWin2: begin
            CheckForWin;
            inc(step)
            end;
    stHealth: begin
            if (TotalRounds = cSuddenDTurns - 1) and (cHealthDecrease = 0) then
                begin
                cHealthDecrease:= 5;
                AddCaption(trmsg[sidSuddenDeath], cWhiteColor, capgrpGameState);
                playSound(sndSuddenDeath)
                end
            else if (TotalRounds < cSuddenDTurns - 1) then
                begin
                i:= cSuddenDTurns - TotalRounds - 1;
                s:= inttostr(i);
                if i = 1 then
                    AddCaption(trmsg[sidRoundSD], cWhiteColor, capgrpGameState)
                else if i in [2, 5, 10, 15, 20, 25, 50, 100] then
                    AddCaption(Format(trmsg[sidRoundsSD], s), cWhiteColor, capgrpGameState);
                end;
            if bBetweenTurns
                or isInMultiShoot
                or (TotalRounds = -1) then inc(step)
            else begin
                bBetweenTurns:= true;
                HealthMachine;
                if cHealthDecrease > 0 then SuddenDeathDmg:= true;
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
                
                ResetUtilities;

                FreeActionsList; // could send -left, -right and similar commands, so should be called before /nextturn

                ParseCommand('/nextturn', true);
                SwitchHedgehog;

                AfterSwitchHedgehog;
                bBetweenTurns:= false
                end;
            step:= Low(step)
            end;
    end;

if TurnTimeLeft > 0 then
        if CurrentHedgehog^.Gear <> nil then
            if ((CurrentHedgehog^.Gear^.State and gstAttacking) = 0)
                and not isInMultiShoot then
                begin
                if (TurnTimeLeft = 5000)
                    and (not PlacingHogs)
                    and (CurrentHedgehog^.Gear <> nil)
                    and ((CurrentHedgehog^.Gear^.State and gstAttacked) = 0) then
                        PlaySound(sndHurry, CurrentTeam^.voicepack);
                dec(TurnTimeLeft)
                end;

if skipFlag then
    begin
    TurnTimeLeft:= 0;
    skipFlag:= false
    end;

if ((GameTicks and $FFFF) = $FFFF) then
    begin
    if (not CurrentTeam^.ExtDriven) then
        SendIPCTimeInc;

    if (not CurrentTeam^.ExtDriven) or CurrentTeam^.hasGone then
        inc(hiTicks) // we do not recieve a message for this
    end;

inc(GameTicks)
end;

//Purpose, to reset all transient attributes toggled by a utility.
//If any of these are set as permanent toggles in the frontend, that needs to be checked and skipped here.
procedure ResetUtilities;
var  i: LongInt;
begin
    SpeechText:= ''; // in case it has not been consumed

    if (GameFlags and gfLowGravity) = 0 then
        cGravity:= cMaxWindSpeed * 2;

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
                  if (SpeechGear <> nil) then
                     begin
                     DeleteVisualGear(SpeechGear);  // remove to restore persisting beyond end of turn. Tiy says was too much of a gameplay issue
                     SpeechGear:= nil
                     end;

                  if (Gear <> nil) then
                     if (GameFlags and gfInvulnerable) = 0 then
                        Gear^.Invulnerable:= false;
                  end;
end;

procedure ApplyDamage(Gear: PGear; Damage: Longword);
var s: shortstring;
    vampDmg, tmpDmg, i: Longword;
    vg: PVisualGear;
begin
    if (Gear^.Kind = gtHedgehog) and (Damage>=1) then
    begin
    AddDamageTag(hwRound(Gear^.X), hwRound(Gear^.Y), Damage, PHedgehog(Gear^.Hedgehog)^.Team^.Clan^.Color);
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
           AddGear(hwRound(CurrentHedgehog^.Gear^.X),
                   hwRound(CurrentHedgehog^.Gear^.Y),
                   gtHealthTag, tmpDmg, _0, _0, 0)^.Hedgehog:= CurrentHedgehog;
           end;
        end;
    end;
    inc(Gear^.Damage, Damage);
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

procedure DrawAltWeapon(Gear: PGear; sx, sy: LongInt);
begin
with PHedgehog(Gear^.Hedgehog)^ do
    begin
    if not (((Ammoz[Ammo^[CurSlot, CurAmmo].AmmoType].Ammo.Propz and ammoprop_AltUse) <> 0) and ((Gear^.State and gstAttacked) = 0)) then
        exit;
    DrawTexture(round(sx + 16), round(sy + 16), ropeIconTex);
    DrawTextureF(SpritesData[sprAMAmmos].Texture, 0.75, round(sx + 30), round(sy + 30), ord(Ammo^[CurSlot, CurAmmo].AmmoType) - 1, 1, 32, 32);
    end;
end;

procedure DrawHH(Gear: PGear);
var i, t: LongInt;
    amt: TAmmoType;
    hx, hy, cx, cy, tx, ty, sx, sy, m: LongInt;  // hedgehog, crosshair, temp, sprite, direction
    lx, ly, dx, dy, ax, ay, aAngle, dAngle, hAngle: real;  // laser, change
    defaultPos, HatVisible: boolean;
    VertexBuffer: array [0..1] of TVertex2f;
    HH: PHedgehog;
begin
HH:= PHedgehog(Gear^.Hedgehog);
if HH^.Unplaced then exit;
m:= 1;
if ((Gear^.State and gstHHHJump) <> 0) and not cArtillery then m:= -1;
if (Gear^.State and gstHHDeath) <> 0 then
    begin
    DrawSprite(sprHHDeath, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 26 + WorldDy, Gear^.Pos);
    exit
    end
else if (Gear^.State and gstHHGone) <> 0 then
    begin
    DrawRotatedF(sprTeleport, hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy, Gear^.Pos, hwSign(Gear^.dX), 0);
    exit
    end;

defaultPos:= true;
HatVisible:= false;

sx:= hwRound(Gear^.X) + 1 + WorldDx;
sy:= hwRound(Gear^.Y) - 3 + WorldDy;

if HH^.Effects[hePoisoned] then
    begin
    Tint($4040FF00);
    DrawRotatedTextureF(SpritesData[sprSmokeWhite].texture, 2, 0, 0, sx, sy, 0, 1, 22, 22, (RealTicks shr 36) mod 360);
    Tint($FFFFFFFF)
    end;

if ((Gear^.State and gstWinner) <> 0) and
   ((CurAmmoGear = nil) or (CurAmmoGear^.Kind <> gtPickHammer)) then
    begin
    DrawHedgehog(sx, sy,
            hwSign(Gear^.dX),
            2,
            0,
            0);
    defaultPos:= false
    end;
if (Gear^.State and gstDrowning) <> 0 then
    begin
    DrawHedgehog(sx, sy,
            hwSign(Gear^.dX),
            1,
            7,
            0);
    defaultPos:= false
    end else
if (Gear^.State and gstLoser) <> 0 then
    begin
    DrawHedgehog(sx, sy,
            hwSign(Gear^.dX),
            2,
            3,
            0);
    defaultPos:= false
    end else

if (Gear^.State and gstHHDriven) <> 0 then
    begin
    if ((Gear^.State and gstHHThinking) = 0) and
       (ShowCrosshair  or ((CurAmmoGear <> nil) and (CurAmmoGear^.Kind = gtRope))) and
       ((Gear^.State and (gstAttacked or gstAnimation)) = 0) then
        begin
(* These calculations are a little complex for a few reasons:
   1: I need to draw the laser from weapon origin to nearest land
   2: I need to start the beam outside the hedgie for attractiveness.
   3: I need to extend the beam beyond land.
   This routine perhaps should be pushed into uStore or somesuch instead of continuuing the increase in size of this function.
*)
        dx:= hwSign(Gear^.dX) * m * Sin(Gear^.Angle * pi / cMaxAngle);
        dy:= - Cos(Gear^.Angle * pi / cMaxAngle);
        if cLaserSighting then
            begin
            lx:= hwRound(Gear^.X);
            ly:= hwRound(Gear^.Y);
            lx:= lx + dx * 16;
            ly:= ly + dy * 16;

            ax:= dx * 4;
            ay:= dy * 4;

            tx:= round(lx);
            ty:= round(ly);
            hx:= tx;
            hy:= ty;
            while ((ty and LAND_HEIGHT_MASK) = 0) and
                ((tx and LAND_WIDTH_MASK) = 0) and
                (Land[ty, tx] = 0) do
                begin
                lx:= lx + ax;
                ly:= ly + ay;
                tx:= round(lx);
                ty:= round(ly)
                end;
            // reached edge of land. assume infinite beam. Extend it way out past camera
            if ((ty and LAND_HEIGHT_MASK) <> 0) or ((tx and LAND_WIDTH_MASK) <> 0) then
                begin
                tx:= round(lx + ax * (LAND_WIDTH div 4));
                ty:= round(ly + ay * (LAND_WIDTH div 4));
                end;

            //if (abs(lx-tx)>8) or (abs(ly-ty)>8) then
                begin
                glDisable(GL_TEXTURE_2D);
                glEnable(GL_LINE_SMOOTH);

                glLineWidth(1.0);

                Tint($C0FF0000);
                VertexBuffer[0].X:= hx + WorldDx;
                VertexBuffer[0].Y:= hy + WorldDy;
                VertexBuffer[1].X:= tx + WorldDx;
                VertexBuffer[1].Y:= ty + WorldDy;

                glEnableClientState(GL_VERTEX_ARRAY);
                glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);
                glDrawArrays(GL_LINES, 0, Length(VertexBuffer));
                Tint($FFFFFFFF);
                glEnable(GL_TEXTURE_2D);
                glDisable(GL_LINE_SMOOTH);
                end;
            end;
        // draw crosshair
        cx:= Round(hwRound(Gear^.X) + dx * 80);
        cy:= Round(hwRound(Gear^.Y) + dy * 80);
        DrawRotatedTex(HH^.Team^.CrosshairTex,
                12, 12, cx + WorldDx, cy + WorldDy, 0,
                hwSign(Gear^.dX) * (Gear^.Angle * 180.0) / cMaxAngle);
        end;
    hx:= hwRound(Gear^.X) + 1 + 8 * hwSign(Gear^.dX) + WorldDx;
    hy:= hwRound(Gear^.Y) - 2 + WorldDy;
    aangle:= Gear^.Angle * 180 / cMaxAngle - 90;

    if CurAmmoGear <> nil then
    begin
        case CurAmmoGear^.Kind of
            gtShotgunShot: begin
                    if (CurAmmoGear^.State and gstAnimation <> 0) then
                        DrawRotated(sprShotgun, hx, hy, hwSign(Gear^.dX), aangle)
                    else
                        DrawRotated(sprHandShotgun, hx, hy, hwSign(Gear^.dX), aangle);
                end;
            gtDEagleShot: DrawRotated(sprDEagle, hx, hy, hwSign(Gear^.dX), aangle);
            gtSniperRifleShot: begin
                    if (CurAmmoGear^.State and gstAnimation <> 0) then
                        DrawRotatedF(sprSniperRifle, hx, hy, 1, hwSign(Gear^.dX), aangle)
                    else
                        DrawRotatedF(sprSniperRifle, hx, hy, 0, hwSign(Gear^.dX), aangle)
                end;
            gtBallgun: DrawRotated(sprHandBallgun, hx, hy, hwSign(Gear^.dX), aangle);
            gtRCPlane: begin
                DrawRotated(sprHandPlane, hx, hy, hwSign(Gear^.dX), 0);
                defaultPos:= false
                end;
            gtRope: begin
                if Gear^.X < CurAmmoGear^.X then
                    begin
                    dAngle:= 0;
                    hAngle:= 180;
                    i:= 1
                    end else
                    begin
                    dAngle:= 180;
                    hAngle:= 0;
                    i:= -1
                    end;
                sx:= hwRound(Gear^.X) + WorldDx;
                sy:= hwRound(Gear^.Y) + WorldDy;
               if ((Gear^.State and gstWinner) = 0) then
                   begin
                   DrawHedgehog(sx, sy,
                           i,
                           1,
                           0,
                           DxDy2Angle(CurAmmoGear^.dY, CurAmmoGear^.dX) + dAngle);
                   with HH^ do
                       if (HatTex <> nil) then
                           DrawRotatedTextureF(HatTex, 1.0, -1.0, -6.0, sx, sy, 0, i, 32, 32,
                               i*DxDy2Angle(CurAmmoGear^.dY, CurAmmoGear^.dX) + hAngle);
                   end;
                DrawAltWeapon(Gear, sx, sy);
                defaultPos:= false
                end;
            gtBlowTorch: begin
                DrawRotated(sprBlowTorch, hx, hy, hwSign(Gear^.dX), aangle);
                DrawHedgehog(sx, sy,
                        hwSign(Gear^.dX),
                        3,
                        HH^.visStepPos div 2,
                        0);
                with HH^ do
                    if (HatTex <> nil) then
                       DrawTextureF(HatTex,
                           1,
                           sx,
                           hwRound(Gear^.Y) - 8 + WorldDy,
                           0,
                           hwSign(Gear^.dX),
                           32,
                           32);
                defaultPos:= false
                end;
            gtShover: DrawRotated(sprHandBaseball, hx, hy, hwSign(Gear^.dX), aangle + 180);
            gtFirePunch: begin
                DrawHedgehog(sx, sy,
                        hwSign(Gear^.dX),
                        1,
                        4,
                        0);
                defaultPos:= false
                end;
            gtPickHammer: begin
                defaultPos:= false;
                dec(sy,20);
                end;
            gtTeleport: defaultPos:= false;
            gtWhip: begin
                DrawRotatedF(sprWhip,
                        sx,
                        sy,
                        1,
                        hwSign(Gear^.dX),
                        0);
                defaultPos:= false
                end;
            gtKamikaze: begin
                if CurAmmoGear^.Pos = 0 then
                    DrawHedgehog(sx, sy,
                            hwSign(Gear^.dX),
                            1,
                            6,
                            0)
                else
                    DrawRotatedF(sprKamikaze,
                            hwRound(Gear^.X) + WorldDx,
                            hwRound(Gear^.Y) + WorldDy,
                            CurAmmoGear^.Pos - 1,
                            hwSign(Gear^.dX),
                            aangle);
                defaultPos:= false
                end;
            gtSeduction: begin
                if CurAmmoGear^.Pos >= 6 then
                    DrawHedgehog(sx, sy,
                            hwSign(Gear^.dX),
                            2,
                            2,
                            0)
                else
                    begin
                    DrawRotatedF(sprDress,
                            hwRound(Gear^.X) + WorldDx,
                            hwRound(Gear^.Y) + WorldDy,
                            CurAmmoGear^.Pos,
                            hwSign(Gear^.dX),
                            0);
                    DrawSprite(sprCensored, hwRound(Gear^.X) - 32 + WorldDx, hwRound(Gear^.Y) - 20 + WorldDy, 0)
                    end;
                defaultPos:= false
                end;
        end;

        case CurAmmoGear^.Kind of
            gtShotgunShot,
            gtDEagleShot,
            gtSniperRifleShot,
            gtShover: begin
                DrawHedgehog(sx, sy,
                        hwSign(Gear^.dX),
                        0,
                        4,
                        0);
                defaultPos:= false;
                HatVisible:= true
            end
        end
    end else

    if ((Gear^.State and gstHHJumping) <> 0) then
    begin
    DrawHedgehog(sx, sy,
        hwSign(Gear^.dX)*m,
        1,
        1,
        0);
    HatVisible:= true;
    defaultPos:= false
    end else

    if (Gear^.Message and (gm_Left or gm_Right) <> 0) and (not isCursorVisible) then
        begin
        DrawHedgehog(sx, sy,
            hwSign(Gear^.dX),
            0,
            HH^.visStepPos div 2,
            0);
        defaultPos:= false;
        HatVisible:= true
        end
    else

    if ((Gear^.State and gstAnimation) <> 0) then
        begin
        if (TWave(Gear^.Tag) < Low(TWave)) or (TWave(Gear^.Tag) > High(TWave)) then
            begin
            Gear^.State:= Gear^.State and not gstAnimation;
            end
        else
            begin
            DrawRotatedF(Wavez[TWave(Gear^.Tag)].Sprite,
                    sx,
                    sy,
                    Gear^.Pos,
                    hwSign(Gear^.dX),
                    0.0);
            defaultPos:= false
            end
        end
    else
    if ((Gear^.State and gstAttacked) = 0) then
        begin
        if HH^.Timer > 0 then
            begin
            // There must be a tidier way to do this. Anyone?
            if aangle <= 90 then aangle:= aangle+360;
            if Gear^.dX > _0 then aangle:= aangle-((aangle-240)*HH^.Timer/10)
            else aangle:= aangle+((240-aangle)*HH^.Timer/10);
            dec(HH^.Timer)
            end;
        amt:= CurrentHedgehog^.Ammo^[CurrentHedgehog^.CurSlot, CurrentHedgehog^.CurAmmo].AmmoType;
        case amt of
            amBazooka: DrawRotated(sprHandBazooka, hx, hy, hwSign(Gear^.dX), aangle);
            amMortar: DrawRotated(sprHandMortar, hx, hy, hwSign(Gear^.dX), aangle);
            amMolotov: DrawRotated(sprHandMolotov, hx, hy, hwSign(Gear^.dX), aangle);
            amBallgun: DrawRotated(sprHandBallgun, hx, hy, hwSign(Gear^.dX), aangle);
            amDrill: DrawRotated(sprHandDrill, hx, hy, hwSign(Gear^.dX), aangle);
            amRope: DrawRotated(sprHandRope, hx, hy, hwSign(Gear^.dX), aangle);
            amShotgun: DrawRotated(sprHandShotgun, hx, hy, hwSign(Gear^.dX), aangle);
            amDEagle: DrawRotated(sprHandDEagle, hx, hy, hwSign(Gear^.dX), aangle);
            amSineGun: DrawRotated(sprHandShotgun, hx, hy, hwSign(Gear^.dX), aangle);
            amSniperRifle: DrawRotatedF(sprSniperRifle, hx, hy, 0, hwSign(Gear^.dX), aangle);
            amBlowTorch: DrawRotated(sprHandBlowTorch, hx, hy, hwSign(Gear^.dX), aangle);
            amCake: DrawRotated(sprHandCake, hx, hy, hwSign(Gear^.dX), aangle);
            amGrenade: DrawRotated(sprHandGrenade, hx, hy, hwSign(Gear^.dX), aangle);
            amWatermelon: DrawRotated(sprHandMelon, hx, hy, hwSign(Gear^.dX), aangle);
            amSkip: DrawRotated(sprHandSkip, hx, hy, hwSign(Gear^.dX), aangle);
            amClusterBomb: DrawRotated(sprHandCluster, hx, hy, hwSign(Gear^.dX), aangle);
            amDynamite: DrawRotated(sprHandDynamite, hx, hy, hwSign(Gear^.dX), aangle);
            amHellishBomb: DrawRotated(sprHandHellish, hx, hy, hwSign(Gear^.dX), aangle);
            amMine: DrawRotated(sprHandMine, hx, hy, hwSign(Gear^.dX), aangle);
            amSeduction: DrawRotated(sprHandSeduction, hx, hy, hwSign(Gear^.dX), aangle);
            amVampiric: DrawRotated(sprHandVamp, hx, hy, hwSign(Gear^.dX), aangle);
            amRCPlane: begin
                DrawRotated(sprHandPlane, hx, hy, hwSign(Gear^.dX), 0);
                defaultPos:= false
                end;
            amGirder: begin
                DrawRotated(sprHandConstruction, hx, hy, hwSign(Gear^.dX), aangle);
                DrawSpriteClipped(sprGirder,
                                  sx-256,
                                  sy-256,
                                  LongInt(topY)+WorldDy,
                                  LongInt(rightX)+WorldDx,
                                  cWaterLine+WorldDy,
                                  LongInt(leftX)+WorldDx)
                end;
            amBee: DrawRotatedF(sprHandBee, hx, hy, (RealTicks div 125) mod 4, hwSign(Gear^.dX), aangle);
        end;

        case amt of
            amAirAttack,
            amMineStrike: DrawRotated(sprHandAirAttack, sx, hwRound(Gear^.Y) + WorldDy, hwSign(Gear^.dX), 0);
            amPickHammer: DrawHedgehog(sx, sy,
                        hwSign(Gear^.dX),
                        1,
                        2,
                        0);
            amTeleport: DrawRotatedF(sprTeleport, sx, sy, 0, hwSign(Gear^.dX), 0);
            amKamikaze: DrawHedgehog(sx, sy,
                        hwSign(Gear^.dX),
                        1,
                        5,
                        0);
            amWhip: DrawRotatedF(sprWhip,
                        sx,
                        sy,
                        0,
                        hwSign(Gear^.dX),
                        0);
        else
            DrawHedgehog(sx, sy,
                hwSign(Gear^.dX),
                0,
                4,
                0);

            HatVisible:= true;
            (* with HH^ do
                if (HatTex <> nil)
                and (HatVisibility > 0) then
                    DrawTextureF(HatTex,
                        HatVisibility,
                        sx,
                        hwRound(Gear^.Y) - 8 + WorldDy,
                        0,
                        hwSign(Gear^.dX),
                        32,
                        32); *)
        end;

        case amt of
            amBaseballBat: DrawRotated(sprHandBaseball,
                    hwRound(Gear^.X) + 1 - 4 * hwSign(Gear^.dX) + WorldDx,
                    hwRound(Gear^.Y) + 6 + WorldDy, hwSign(Gear^.dX), aangle);
        end;

        defaultPos:= false
    end;

end else // not gstHHDriven
    begin
    if (Gear^.Damage > 0)
    and (hwSqr(Gear^.dX) + hwSqr(Gear^.dY) > _0_003) then
        begin
        DrawHedgehog(sx, sy,
            hwSign(Gear^.dX),
            2,
            1,
            Gear^.DirAngle);
        defaultPos:= false
        end else

    if ((Gear^.State and gstHHJumping) <> 0) then
        begin
        DrawHedgehog(sx, sy,
            hwSign(Gear^.dX)*m,
            1,
            1,
            0);
        defaultPos:= false
        end;
    end;

with HH^ do
    begin
    if defaultPos then
        begin
        DrawRotatedF(sprHHIdle,
            sx,
            sy,
            (RealTicks div 128 + Gear^.Pos) mod 19,
            hwSign(Gear^.dX),
            0);
        HatVisible:= true;
        end;

    if HatVisible then
        if HatVisibility < 1.0 then
            HatVisibility:= HatVisibility + 0.2
        else
    else
        if HatVisibility > 0.0 then
            HatVisibility:= HatVisibility - 0.2;

    if (HatTex <> nil)
    and (HatVisibility > 0) then
        if DefaultPos then
            DrawTextureF(HatTex,
                HatVisibility,
                sx,
                hwRound(Gear^.Y) - 8 + WorldDy,
                (RealTicks div 128 + Gear^.Pos) mod 19,
                hwSign(Gear^.dX),
                32,
                32)
        else
            DrawTextureF(HatTex,
                HatVisibility,
                sx,
                hwRound(Gear^.Y) - 8 + WorldDy,
                0,
                hwSign(Gear^.dX)*m,
                32,
                32);
    end;
if (Gear^.State and gstHHDriven) <> 0 then
    begin
(*    if (CurAmmoGear = nil) then
        begin
        amt:= CurrentHedgehog^.Ammo^[CurrentHedgehog^.CurSlot, CurrentHedgehog^.CurAmmo].AmmoType;
        case amt of
            amJetpack: DrawSprite(sprJetpack, sx-32, sy-32, 0);
            end
        end; *)
    if CurAmmoGear <> nil then
        begin
        case CurAmmoGear^.Kind of
            gtJetpack: begin
                       DrawSprite(sprJetpack, sx-32, sy-32, 0);
                       if (CurAmmoGear^.MsgParam and gm_Up) <> 0 then DrawSprite(sprJetpack, sx-32, sy-32, 1);
                       if (CurAmmoGear^.MsgParam and gm_Left) <> 0 then DrawSprite(sprJetpack, sx-32, sy-32, 2);
                       if (CurAmmoGear^.MsgParam and gm_Right) <> 0 then DrawSprite(sprJetpack, sx-32, sy-32, 3);
                       if CurAmmoGear^.Tex <> nil then DrawCentered(sx, sy - 40, CurAmmoGear^.Tex);
                       DrawAltWeapon(Gear, sx, sy)
                       end;
            end;
        end
    end;

with HH^ do
    begin
    if ((Gear^.State and not gstWinner) = 0)
        or (bShowFinger and ((Gear^.State and gstHHDriven) <> 0)) then
        begin
        t:= hwRound(Gear^.Y) - cHHRadius - 12 + WorldDy;
        if (cTagsMask and htTransparent) <> 0 then
            Tint($80FFFFFF);
        if ((cTagsMask and htHealth) <> 0) then
            begin
            dec(t, HealthTagTex^.h + 2);
            DrawCentered(hwRound(Gear^.X) + WorldDx, t, HealthTagTex)
            end;
        if (cTagsMask and htName) <> 0 then
            begin
            dec(t, NameTagTex^.h + 2);
            DrawCentered(hwRound(Gear^.X) + WorldDx, t, NameTagTex)
            end;
        if (cTagsMask and htTeamName) <> 0 then
            begin
            dec(t, Team^.NameTagTex^.h + 2);
            DrawCentered(hwRound(Gear^.X) + WorldDx, t, Team^.NameTagTex)
            end;
        if (cTagsMask and htTransparent) <> 0 then
            Tint($FFFFFFFF)
        end;
    if (Gear^.State and gstHHDriven) <> 0 then // Current hedgehog
        begin
        if bShowFinger and ((Gear^.State and gstHHDriven) <> 0) then
            DrawSprite(sprFinger, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 64 + WorldDy,
                        GameTicks div 32 mod 16);

        if (Gear^.State and gstDrowning) = 0 then
            if (Gear^.State and gstHHThinking) <> 0 then
                DrawSprite(sprQuestion, hwRound(Gear^.X) - 10 + WorldDx, hwRound(Gear^.Y) - cHHRadius - 34 + WorldDy, (RealTicks shr 9) mod 8)
        end
    end;

if HH^.Effects[hePoisoned] then
    begin
    Tint($8040FF00);
    DrawRotatedTextureF(SpritesData[sprSmokeWhite].texture, 1.5, 0, 0, sx, sy, 0, 1, 22, 22, 360 - (RealTicks shr 37) mod 360);
    end;

if Gear^.Invulnerable then
    begin
    Tint($FF, $FF, $FF, max($40, floor($FF * abs(1 - ((RealTicks div 2 + Gear^.uid * 491) mod 1500) / 750))));
    DrawSprite(sprInvulnerable, sx - 24, sy - 24, 0);
    end;
if cVampiric and
   (CurrentHedgehog^.Gear <> nil) and
   (CurrentHedgehog^.Gear = Gear) then
    begin
    Tint($FF, $FF, $FF, max($40, floor($FF * abs(1 - (RealTicks mod 1500) / 750))));
    DrawSprite(sprVampiric, sx - 24, sy - 24, 0);
    end;
    Tint($FFFFFFFF)
end;

procedure DrawRopeLinesRQ(Gear: PGear);
begin
with RopePoints do
    begin
    rounded[Count].X:= hwRound(Gear^.X);
    rounded[Count].Y:= hwRound(Gear^.Y);
    rounded[Count + 1].X:= hwRound(PHedgehog(Gear^.Hedgehog)^.Gear^.X);
    rounded[Count + 1].Y:= hwRound(PHedgehog(Gear^.Hedgehog)^.Gear^.Y);
    end;

if (RopePoints.Count > 0) or (Gear^.Elasticity.QWordValue > 0) then
    begin
    glDisable(GL_TEXTURE_2D);
    //glEnable(GL_LINE_SMOOTH);

    glPushMatrix;

    glTranslatef(WorldDx, WorldDy, 0);

    glLineWidth(4.0);

    Tint($FFC0C0C0);

    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, @RopePoints.rounded[0]);
    glDrawArrays(GL_LINE_STRIP, 0, RopePoints.Count + 2);
    Tint($FFFFFFFF);

    glPopMatrix;

    glEnable(GL_TEXTURE_2D);
    //glDisable(GL_LINE_SMOOTH)
    end
end;

procedure DrawRope(Gear: PGear);
var roplen: LongInt;
    i: Longword;

    procedure DrawRopeLine(X1, Y1, X2, Y2: LongInt);
    var  eX, eY, dX, dY: LongInt;
        i, sX, sY, x, y, d: LongInt;
        b: boolean;
    begin
    if (X1 = X2) and (Y1 = Y2) then
    begin
    //OutError('WARNING: zero length rope line!', false);
    exit
    end;
    eX:= 0;
    eY:= 0;
    dX:= X2 - X1;
    dY:= Y2 - Y1;

    if (dX > 0) then sX:= 1
    else
    if (dX < 0) then
        begin
        sX:= -1;
        dX:= -dX
        end else sX:= dX;

    if (dY > 0) then sY:= 1
    else
    if (dY < 0) then
        begin
        sY:= -1;
        dY:= -dY
        end else sY:= dY;

        if (dX > dY) then d:= dX
                    else d:= dY;

        x:= X1;
        y:= Y1;

        for i:= 0 to d do
            begin
            inc(eX, dX);
            inc(eY, dY);
            b:= false;
            if (eX > d) then
                begin
                dec(eX, d);
                inc(x, sX);
                b:= true
                end;
            if (eY > d) then
                begin
                dec(eY, d);
                inc(y, sY);
                b:= true
                end;
            if b then
                begin
                inc(roplen);
                if (roplen mod 4) = 0 then DrawSprite(sprRopeNode, x - 2, y - 2, 0)
                end
        end
    end;
begin
    if cReducedQuality then
        DrawRopeLinesRQ(Gear)
    else
        begin
        roplen:= 0;
        if RopePoints.Count > 0 then
            begin
            i:= 0;
            while i < Pred(RopePoints.Count) do
                    begin
                    DrawRopeLine(hwRound(RopePoints.ar[i].X) + WorldDx, hwRound(RopePoints.ar[i].Y) + WorldDy,
                                hwRound(RopePoints.ar[Succ(i)].X) + WorldDx, hwRound(RopePoints.ar[Succ(i)].Y) + WorldDy);
                    inc(i)
                    end;
            DrawRopeLine(hwRound(RopePoints.ar[i].X) + WorldDx, hwRound(RopePoints.ar[i].Y) + WorldDy,
                        hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy);
            DrawRopeLine(hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy,
                        hwRound(PHedgehog(Gear^.Hedgehog)^.Gear^.X) + WorldDx, hwRound(PHedgehog(Gear^.Hedgehog)^.Gear^.Y) + WorldDy);
            end else
            if Gear^.Elasticity.QWordValue > 0 then
            DrawRopeLine(hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy,
                        hwRound(PHedgehog(Gear^.Hedgehog)^.Gear^.X) + WorldDx, hwRound(PHedgehog(Gear^.Hedgehog)^.Gear^.Y) + WorldDy);
        end;


if RopePoints.Count > 0 then
    DrawRotated(sprRopeHook, hwRound(RopePoints.ar[0].X) + WorldDx, hwRound(RopePoints.ar[0].Y) + WorldDy, 1, RopePoints.HookAngle)
    else
    if Gear^.Elasticity.QWordValue > 0 then
        DrawRotated(sprRopeHook, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, DxDy2Angle(Gear^.dY, Gear^.dX));
end;

procedure DrawGears;
var Gear, HHGear: PGear;
    i: Longword;
    startX, endX, startY, endY: LongInt;
begin
Gear:= GearsList;
while Gear<>nil do
    begin
    case Gear^.Kind of
       gtAmmo_Bomb: DrawRotated(sprBomb, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, Gear^.DirAngle);
       gtGasBomb: DrawRotated(sprBomb, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, Gear^.DirAngle);
    gtMolotov: DrawRotated(sprMolotov, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, Gear^.DirAngle);

       gtRCPlane: begin
                  if (Gear^.Tag = -1) then
                     DrawRotated(sprPlane, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, -1,  DxDy2Angle(Gear^.dX, Gear^.dY) + 90)
                  else
                     DrawRotated(sprPlane, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy,0,DxDy2Angle(Gear^.dY, Gear^.dX));
                  if ((TrainingFlags and tfRCPlane) <> 0) and (TrainingTargetGear <> nil) and ((Gear^.State and gstDrowning) = 0) then
                     DrawRotatedf(sprFinger, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, GameTicks div 32 mod 16, 0, DxDy2Angle(Gear^.X - TrainingTargetGear^.X, TrainingTargetGear^.Y - Gear^.Y));
                  end;
       gtBall: DrawRotatedf(sprBalls, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.Tag,0, Gear^.DirAngle);

       gtDrill: DrawRotated(sprDrill, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, DxDy2Angle(Gear^.dY, Gear^.dX));

        gtHedgehog: DrawHH(Gear);

    gtAmmo_Grenade: DrawRotated(sprGrenade, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, DxDy2Angle(Gear^.dY, Gear^.dX));

       gtHealthTag: if Gear^.Tex <> nil then DrawCentered(hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.Tex);

           gtGrave: DrawTextureF(PHedgehog(Gear^.Hedgehog)^.Team^.GraveTex, 1, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, (GameTicks shr 7+Gear^.uid) and 7, 1, 32, 32);

             gtBee: DrawRotatedF(sprBee, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, (GameTicks shr 5) mod 2, 0, DxDy2Angle(Gear^.dY, Gear^.dX));

      gtPickHammer: DrawSprite(sprPHammer, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 50 + LongInt(((GameTicks shr 5) and 1) * 2) + WorldDy, 0);
            gtRope: DrawRope(Gear);
      gtSmokeTrace: if Gear^.State < 8 then DrawSprite(sprSmokeTrace, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.State);
       gtExplosion: DrawSprite(sprExplosion50, hwRound(Gear^.X) - 32 + WorldDx, hwRound(Gear^.Y) - 32 + WorldDy, Gear^.State);
            gtMine: if (((Gear^.State and gstAttacking) = 0)or((Gear^.Timer and $3FF) < 420)) and (Gear^.Health <> 0) then
                           DrawRotated(sprMineOff, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, Gear^.DirAngle)
                       else if Gear^.Health <> 0 then DrawRotated(sprMineOn, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, Gear^.DirAngle)
                       else DrawRotated(sprMineDead, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, Gear^.DirAngle);
            gtCase: case Gear^.Pos of
                         posCaseAmmo  : begin
                                        i:= (GameTicks shr 6) mod 64;
                                        if i > 18 then i:= 0;
                                        DrawSprite(sprCase, hwRound(Gear^.X) - 24 + WorldDx, hwRound(Gear^.Y) - 24 + WorldDy, i);
                                        end;
                         posCaseHealth: begin
                                        i:= ((GameTicks shr 6) + 38) mod 64;
                                        if i > 13 then i:= 0;
                                        DrawSprite(sprFAid, hwRound(Gear^.X) - 24 + WorldDx, hwRound(Gear^.Y) - 24 + WorldDy, i);
                                        end;
                         posCaseUtility: begin
                                        i:= (GameTicks shr 6) mod 70;
                                        if i > 23 then i:= 0;
                                        i:= i mod 12;
                                        DrawSprite(sprUtility, hwRound(Gear^.X) - 24 + WorldDx, hwRound(Gear^.Y) - 24 + WorldDy, i);
                                        end;
                         end;
      gtExplosives: begin
                    if ((Gear^.State and gstDrowning) <> 0) then
                        DrawSprite(sprExplosivesRoll, hwRound(Gear^.X) - 24 + WorldDx, hwRound(Gear^.Y) - 24 + WorldDy, 0)
                    else if Gear^.State and gstAnimation = 0 then
                        begin
                        i:= (GameTicks shr 6 + Gear^.uid*3) mod 64;
                        if i > 18 then i:= 0;
                        DrawSprite(sprExplosives, hwRound(Gear^.X) - 24 + WorldDx, hwRound(Gear^.Y) - 24 + WorldDy, i)
                        end
                    else if Gear^.State and gsttmpFlag = 0 then
                        DrawRotatedF(sprExplosivesRoll, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) +4 + WorldDy, 0, 0, Gear^.DirAngle)
                    else
                        DrawRotatedF(sprExplosivesRoll, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) +4 + WorldDy, 1, 0, Gear^.DirAngle);
                    end;
        gtDynamite: DrawSprite2(sprDynamite, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 25 + WorldDy, Gear^.Tag and 1, Gear^.Tag shr 1);
     gtClusterBomb: DrawRotated(sprClusterBomb, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, Gear^.DirAngle);
         gtCluster: DrawSprite(sprClusterParticle, hwRound(Gear^.X) - 8 + WorldDx, hwRound(Gear^.Y) - 8 + WorldDy, 0);
           gtFlame: DrawTextureF(SpritesData[sprFlame].Texture, 2 / (Gear^.Tag mod 3 + 2), hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, (GameTicks div 128 + LongWord(Gear^.Tag)) mod 8, 1, 16, 16);
       gtParachute: begin
                    DrawSprite(sprParachute, hwRound(Gear^.X) - 24 + WorldDx, hwRound(Gear^.Y) - 48 + WorldDy, 0);
                    DrawAltWeapon(Gear, hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy)
                    end;
       gtAirAttack: if Gear^.Tag > 0 then DrawSprite(sprAirplane, hwRound(Gear^.X) - SpritesData[sprAirplane].Width div 2 + WorldDx, hwRound(Gear^.Y) - SpritesData[sprAirplane].Height div 2 + WorldDy, 0)
                                     else DrawSprite(sprAirplane, hwRound(Gear^.X) - SpritesData[sprAirplane].Width div 2 + WorldDx, hwRound(Gear^.Y) - SpritesData[sprAirplane].Height div 2 + WorldDy, 1);
         gtAirBomb: DrawRotated(sprAirBomb, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, DxDy2Angle(Gear^.dY, Gear^.dX));
        gtTeleport: begin
                    HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
                    if not PHedgehog(Gear^.Hedgehog)^.Unplaced then DrawRotatedF(sprTeleport, hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy, Gear^.Pos, hwSign(Gear^.dX), 0);
                    DrawRotatedF(sprTeleport, hwRound(HHGear^.X) + 1 + WorldDx, hwRound(HHGear^.Y) - 3 + WorldDy, 11 - Gear^.Pos, hwSign(HHGear^.dX), 0);
                    end;
        gtSwitcher: DrawSprite(sprSwitch, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 56 + WorldDy, (GameTicks shr 6) mod 12);
          gtTarget: begin
                    Tint($FF, $FF, $FF, floor($FF * Gear^.Timer / 1000));
                    DrawSprite(sprTarget, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 16 + WorldDy, 0);
                    Tint($FFFFFFFF);
                    end;
          gtMortar: DrawRotated(sprMortar, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, DxDy2Angle(Gear^.dY, Gear^.dX));
          gtCake: if Gear^.Pos = 6 then
                     DrawRotatedf(sprCakeWalk, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, (GameTicks div 40) mod 6, hwSign(Gear^.dX), Gear^.DirAngle * hwSign(Gear^.dX) + 90)
                  else
                     DrawRotatedf(sprCakeDown, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 5 - Gear^.Pos, hwSign(Gear^.dX), 0);
       gtSeduction: if Gear^.Pos >= 14 then DrawSprite(sprSeduction, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 16 + WorldDy, 0);
      gtWatermelon: DrawRotatedf(sprWatermelon, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, 0, Gear^.DirAngle);
      gtMelonPiece: DrawRotatedf(sprWatermelon, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 1, 0, Gear^.DirAngle);
     gtHellishBomb: DrawRotated(sprHellishBomb, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, Gear^.DirAngle);
      gtEvilTrace: if Gear^.State < 8 then DrawSprite(sprEvilTrace, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.State);
           gtBirdy: begin
                    if Gear^.State and gstAnimation = gstAnimation then
                        begin
                        if Gear^.State and gstTmpFlag = 0 then // Appearing
                            begin
                            endX:= hwRound(Gear^.X);
                            endY:= hwRound(Gear^.Y);
                            if Gear^.Tag < 0 then
                                startX:= max(LAND_WIDTH + 1024, endX + 2048)
                            else
                                startX:= max(-LAND_WIDTH - 1024, endX - 2048);
                            startY:= endY - 256;
                            DrawTextureF(SpritesData[sprBirdy].Texture, 1, startX + WorldDx + trunc((endX - startX) * (-power(2, -10 * LongInt(Gear^.Timer)/2000) + 1)), startY + WorldDy + trunc((endY - startY) * sqrt(1 - power((LongInt(Gear^.Timer)/2000)-1, 2))), ((Gear^.Pos shr 6) or (RealTicks shr 8)) mod 2, Gear^.Tag, 75, 75);
                            end
                        else // Disappearing
                            begin
                            startX:= hwRound(Gear^.X);
                            startY:= hwRound(Gear^.Y);
                            if Gear^.Tag > 0 then
                                endX:= max(LAND_WIDTH + 1024, startX + 2048)
                            else
                                endX:= max(-LAND_WIDTH - 1024, startX - 2048);
                            endY:= startY + 256;
                            DrawTextureF(SpritesData[sprBirdy].Texture, 1, startX + WorldDx + trunc((endX - startX) * power(2, 10 * (LongInt(Gear^.Timer)/2000 - 1))) + hwRound(Gear^.dX * Gear^.Timer), startY + WorldDy + trunc((endY - startY) * cos(LongInt(Gear^.Timer)/2000 * (Pi/2)) - (endY - startY)) + hwRound(Gear^.dY * Gear^.Timer), ((Gear^.Pos shr 6) or (RealTicks shr 8)) mod 2, Gear^.Tag, 75, 75);
                            end;
                        end
                    else
                        DrawTextureF(SpritesData[sprBirdy].Texture, 1, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, ((Gear^.Pos shr 6) or (RealTicks shr 8)) mod 2, Gear^.Tag, 75, 75);
                    end;
    gtBigExplosion: begin
                    Tint($FF, $FF, $FF, floor($FF * (1 - power(Gear^.Timer / 250, 4))));
                    DrawRotatedTextureF(SpritesData[sprBigExplosion].Texture, 0.85 * (-power(2, -10 * Int(Gear^.Timer)/250) + 1) + 0.4, 0, 0, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, 1, 385, 385, Gear^.Angle);
                    Tint($FFFFFFFF);
                    end;
             gtEgg: DrawRotatedTextureF(SpritesData[sprEgg].Texture, 1, 0, 0, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, 1, 16, 16, Gear^.DirAngle);
           gtPiano: begin
                    if (Gear^.State and gstDrowning) = 0 then
                        begin
                        Tint($10FFFFFF);
                        for i:= 8 downto 1 do
                            DrawRotatedTextureF(SpritesData[sprPiano].Texture, 1, 0, 0, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy - hwRound(Gear^.dY * 4 * i), 0, 1, 128, 128, 0);
                        Tint($FFFFFFFF)
                        end;
                    DrawRotatedTextureF(SpritesData[sprPiano].Texture, 1, 0, 0, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, 1, 128, 128, 0);
                    end;
         end;
      if Gear^.RenderTimer and (Gear^.Tex <> nil) then DrawCentered(hwRound(Gear^.X) + 8 + WorldDx, hwRound(Gear^.Y) + 8 + WorldDy, Gear^.Tex);
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

if ((GameFlags and gfForts) = 0) then
    begin
    // TODO: exclude each other or allow both, mines and explosives, on same map?
    if ((GameFlags and gfMines) <> 0) then
        for i:= 0 to Pred(cLandAdditions) do
            begin
            Gear:= AddGear(0, 0, gtMine, 0, _0, _0, 0);
            FindPlace(Gear, false, 0, LAND_WIDTH);
            end;
//  No game flag for this for now
//  if ((GameFlags and gfExplosives) <> 0) then
        for i:= 0 to Pred(cExplosives) do
            begin
            Gear:= AddGear(0, 0, gtExplosives, 0, _0, _0, 0);
            FindPlace(Gear, false, 0, LAND_WIDTH);
            end;
    end;

if (GameFlags and gfLowGravity) <> 0 then
    cGravity:= cMaxWindSpeed;

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
    cArtillery:= true
end;

procedure doMakeExplosion(X, Y, Radius: LongInt; Mask: LongWord);
var Gear: PGear;
    dmg, dmgRadius, dmgBase: LongInt;
    fX, fY: hwFloat;
begin
TargetPoint.X:= NoPointX;
{$IFDEF DEBUGFILE}if Radius > 4 then AddFileLog('Explosion: at (' + inttostr(x) + ',' + inttostr(y) + ')');{$ENDIF}
if Radius > 25 then KickFlakes(Radius, X, Y);

if ((Mask and EXPLNoGfx) = 0) then
    begin
    if Radius > 50 then AddGear(X, Y, gtBigExplosion, 0, _0, _0, 0)
    else if Radius > 10 then AddGear(X, Y, gtExplosion, 0, _0, _0, 0);
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
                                    ApplyDamage(Gear, dmg)
                                else
                                    Gear^.State:= Gear^.State or gstWinner;
                                end;
                            if ((Mask and EXPLDoNotTouchHH) = 0) or (Gear^.Kind <> gtHedgehog) then
                                begin
                                DeleteCI(Gear);
                                Gear^.dX:= Gear^.dX + SignAs(_0_005 * dmg + cHHKick, Gear^.X - fX);
                                Gear^.dY:= Gear^.dY + SignAs(_0_005 * dmg + cHHKick, Gear^.Y - fY);
                                Gear^.State:= (Gear^.State or gstMoving) and (not gstLoser);
                                if not Gear^.Invulnerable then
                                    Gear^.State:= (Gear^.State or gstMoving) and (not gstWinner);
                                Gear^.Active:= true;
                                FollowGear:= Gear
                                end;
                            if ((Mask and EXPLPoisoned) <> 0) and (Gear^.Kind = gtHedgehog) then
                                PHedgehog(Gear^.Hedgehog)^.Effects[hePoisoned] := true;
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
    if (GameFlags and gfSolidLand) = 0 then DrawExplosion(X, Y, Radius);

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
            gtCase,
            gtTarget,
            gtExplosives: begin
                    if (not t^.Invulnerable) then
                        ApplyDamage(t, dmg)
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
        if (Gear^.Kind = gtHedgehog) and (Ammo^.State and gsttmpFlag <> 0) and (Ammo^.Kind = gtShover) then Gear^.FlightTime:= 1;
        
        case Gear^.Kind of
            gtHedgehog,
            gtMine,
            gtTarget,
            gtCase,
            gtExplosives: begin
                    if (Ammo^.Kind = gtDrill) then begin Ammo^.Timer:= 0; exit; end;
                    if (not Gear^.Invulnerable) then
                        ApplyDamage(Gear, tmpDmg)
                    else
                        Gear^.State:= Gear^.State or gstWinner;
                    if (Gear^.Kind = gtExplosives) and (Ammo^.Kind = gtBlowtorch) then ApplyDamage(Gear, tmpDmg * 100); // crank up damage for explosives + blowtorch

                    DeleteCI(Gear);
                    if (Gear^.Kind = gtHedgehog) and PHedgehog(Gear^.Hedgehog)^.King then
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
if (GameFlags and (gfForts or gfDivideTeams)) <> 0 then
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
// FIXME - shoppa is TEMPORARY REMOVE WHEN CRATE PROBABILITY ALLOWS DISABLING OF HEALTH CRATES
// Preserving health crate distribution of 35% until that happens
if (aTot+uTot) <> 0 then
    if not shoppa and ((GameFlags and gfInvulnerable) = 0) then 
        begin
        h:= 3500;
        t:= GetRandom(10000);
        a:= 6500*aTot div (aTot+uTot)
        end
    else 
        begin
        t:= GetRandom(aTot+uTot);
        h:= 0
        end;

    
if t<h then
    begin
    FollowGear:= AddGear(0, 0, gtCase, 0, _0, _0, 0);
    FollowGear^.Health:= 25;
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
        if (Ammoz[i].Ammo.Propz and ammoprop_Utility) = 0 then
            dec(t, Ammoz[i].Probability);
        while t >= 0 do
          begin
          inc(i);
          if (Ammoz[i].Ammo.Propz and ammoprop_Utility) = 0 then
              dec(t, Ammoz[i].Probability)
          end;
        FollowGear^.Pos:= posCaseAmmo;
        FollowGear^.State:= Longword(i);
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
        if (Ammoz[i].Ammo.Propz and ammoprop_Utility) <> 0 then
            dec(t, Ammoz[i].Probability);
        while t >= 0 do
          begin
          inc(i);
          if (Ammoz[i].Ammo.Propz and ammoprop_Utility) <> 0 then
              dec(t, Ammoz[i].Probability)
          end;
        FollowGear^.Pos:= posCaseUtility;
        FollowGear^.State:= Longword(i);
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

procedure FindPlace(var Gear: PGear; withFall: boolean; Left, Right: LongInt);

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
begin
delta:= 250;
cnt2:= 0;
repeat
    x:= Left + LongInt(GetRandom(Delta));
    repeat
        inc(x, Delta);
        cnt:= 0;
        if topY > 1024 then
            y:= 1024-Gear^.Radius * 2
        else
            y:= topY-Gear^.Radius * 2;
        while y < LAND_HEIGHT do
            begin
            repeat
                inc(y, 2);
            until (y >= LAND_HEIGHT) or (CountNonZeroz(x, y, Gear^.Radius - 1, 1) = 0);

            sy:= y;

            repeat
                inc(y);
            until (y >= LAND_HEIGHT) or (CountNonZeroz(x, y, Gear^.Radius - 1, 1) <> 0);
            
            if (y - sy > Gear^.Radius * 2) and
               (((Gear^.Kind = gtExplosives)
                   and (y < LAND_HEIGHT-1)
                   and (CheckGearsNear(x, y - Gear^.Radius, [gtFlame, gtHedgehog, gtMine, gtCase, gtExplosives], 60, 60) = nil)
                   and (CountNonZeroz(x, y+1, Gear^.Radius - 1, Gear^.Radius+1) > Gear^.Radius)) 
               or
                 ((Gear^.Kind <> gtExplosives)
                   and (y < LAND_HEIGHT)
                   and (CheckGearsNear(x, y - Gear^.Radius, [gtFlame, gtHedgehog, gtMine, gtCase, gtExplosives], 110, 110) = nil))) then
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
if (Gear^.Hedgehog <> nil) and (PHedgehog(Gear^.Hedgehog)^.King) then
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

procedure initModule;
begin
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

end;

end.
