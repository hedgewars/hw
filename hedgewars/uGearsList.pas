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
unit uGearsList;

interface
uses uFloat, uTypes;

function  AddGear(X, Y: LongInt; Kind: TGearType; State: Longword; dX, dY: hwFloat; Timer: LongWord): PGear;
procedure DeleteGear(Gear: PGear);
procedure InsertGearToList(Gear: PGear);
procedure RemoveGearFromList(Gear: PGear);

var curHandledGear: PGear;

implementation

uses uRandom, uUtils, uConsts, uVariables, uAmmos, uTeams, uStats,
    uTextures, uScript, uRenderUtils, uAI, uCollisions,
    uGearsRender, uGearsUtils, uDebug;

var GCounter: LongWord = 0; // this does not get re-initialized, but should be harmless

procedure InsertGearToList(Gear: PGear);
var tmp, ptmp: PGear;
begin
    tmp:= GearsList;
    ptmp:= GearsList;
    while (tmp <> nil) and (tmp^.Z < Gear^.Z) do
        begin
        ptmp:= tmp;
        tmp:= tmp^.NextGear
        end;

    if ptmp <> tmp then
        begin
        Gear^.NextGear:= ptmp^.NextGear;
        Gear^.PrevGear:= ptmp;
        if ptmp^.NextGear <> nil then
            ptmp^.NextGear^.PrevGear:= Gear;
        ptmp^.NextGear:= Gear
        end
    else
        begin
        Gear^.NextGear:= GearsList;
        if Gear^.NextGear <> nil then
            Gear^.NextGear^.PrevGear:= Gear;
        GearsList:= Gear;
        end;
end;


procedure RemoveGearFromList(Gear: PGear);
begin
TryDo((curHandledGear = nil) or (Gear = curHandledGear), 'You''re doing it wrong', true);

if Gear^.NextGear <> nil then
    Gear^.NextGear^.PrevGear:= Gear^.PrevGear;
if Gear^.PrevGear <> nil then
    Gear^.PrevGear^.NextGear:= Gear^.NextGear
else
    GearsList:= Gear^.NextGear
end;


function AddGear(X, Y: LongInt; Kind: TGearType; State: Longword; dX, dY: hwFloat; Timer: LongWord): PGear;
var gear: PGear;
begin
inc(GCounter);
AddFileLog('AddGear: #' + inttostr(GCounter) + ' (' + inttostr(x) + ',' + inttostr(y) + '), d(' + floattostr(dX) + ',' + floattostr(dY) + ') type = ' + EnumToStr(Kind));

New(gear);
FillChar(gear^, sizeof(TGear), 0);
gear^.X:= int2hwFloat(X);
gear^.Y:= int2hwFloat(Y);
gear^.Target.X:= NoPointX;
gear^.Kind := Kind;
gear^.State:= State;
gear^.Active:= true;
gear^.dX:= dX;
gear^.dY:= dY;
gear^.doStep:= doStepHandlers[Kind];
gear^.CollisionIndex:= -1;
gear^.Timer:= Timer;
gear^.uid:= GCounter;
gear^.SoundChannel:= -1;
gear^.ImpactSound:= sndNone;
gear^.Density:= _1;
// Define ammo association, if any.
gear^.AmmoType:= GearKindAmmoTypeMap[Kind];
gear^.CollisionMask:= $FFFF;

if CurrentHedgehog <> nil then 
    begin
    gear^.Hedgehog:= CurrentHedgehog;
    if (CurrentHedgehog^.Gear <> nil) and (hwRound(CurrentHedgehog^.Gear^.X) = X) and (hwRound(CurrentHedgehog^.Gear^.Y) = Y) then
        gear^.CollisionMask:= $FF7F
    end;

if (Ammoz[Gear^.AmmoType].Ammo.Propz and ammoprop_NeedTarget <> 0) then
    gear^.Z:= cHHZ+1
else gear^.Z:= cUsualZ;

    
case Kind of
     gtGrenade,
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
                if gear^.Timer = 0 then
                    gear^.Timer:= 3000
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
                if gear^.Timer = 0 then
                    gear^.Timer:= 3000
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
                        gear^.Hedgehog^.Effects[heResurrectable] := 1;
                end;
       gtShell: begin
                gear^.Radius:= 4;
                gear^.Density:= _1;
                end;
       gtSnowball: begin
                gear^.ImpactSound:= sndMudballImpact;
                gear^.nImpactSounds:= 1;
                gear^.Radius:= 4;
                gear^.Elasticity:= _1;
                gear^.Friction:= _1;
                gear^.Density:= _0_5;
                end;

     gtFlake: begin
                with Gear^ do
                    begin
                    Pos:= 0;
                    Radius:= 1;
                    DirAngle:= random(360);
                    if State and gstTmpFlag = 0 then
                        begin
                        dx.isNegative:= GetRandom(2) = 0;
                        dx.QWordValue:= $40DA * GetRandom(10000) * 8;
                        dy.isNegative:= false;
                        dy.QWordValue:= $3AD3 * GetRandom(7000) * 8;
                        if GetRandom(2) = 0 then
                            dx := -dx
                        end;
                    State:= State or gstInvisible;
                    Health:= random(vobFrameTicks);
                    Timer:= random(vobFramesCount);
                    Damage:= (random(2) * 2 - 1) * (vobVelocity + random(vobVelocity)) * 8;
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
                gear^.Tag:= 0;
                end;
   gtSeduction: begin
                gear^.Radius:= 250;
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
                gear^.ImpactSound:= sndMineImpact;
                gear^.nImpactSounds:= 1;
                gear^.Health:= 10;
                gear^.State:= gear^.State or gstMoving;
                gear^.Radius:= 2;
                gear^.Elasticity:= _0_55;
                gear^.Friction:= _0_995;
                gear^.Density:= _1;
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
                gear^.Density:= _1_6;
                gear^.Timer:= 500;
                end;
       gtKnife: gear^.Radius:= 5;
        gtCase: begin
                gear^.ImpactSound:= sndGraveImpact;
                gear^.nImpactSounds:= 1;
                gear^.Radius:= 16;
                gear^.Elasticity:= _0_3;
                gear^.Timer:= 500
                end;
  gtExplosives: begin
                gear^.ImpactSound:= sndGrenadeImpact;
                gear^.nImpactSounds:= 1;
                gear^.Radius:= 16;
                gear^.Elasticity:= _0_4;
                gear^.Friction:= _0_995;
                gear^.Density:= _6;
                gear^.Health:= cBarrelHealth;
                gear^.Z:= cHHZ-1
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
                    gear^.dY:= (getrandomf - _0_8) * _0_03;
                    gear^.dX:= (getrandomf - _0_5) * _0_4
                    end
                end;
   gtFirePunch: begin
                gear^.Radius:= 15;
                gear^.Tag:= Y
                end;
   gtAirAttack: gear^.Z:= cHHZ+2;
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
      gtTardis: begin
                gear^.Timer:= 0;
                gear^.Pos:= 1;
                gear^.Z:= cCurrHHZ+1;
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
                if not dX.isNegative then
                    gear^.Angle:= 1
                else
                    gear^.Angle:= 3
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
                if gear^.Timer = 0 then
                    gear^.Timer:= 5000;
                // Tag for drill strike. if 1 then first impact occured already
                gear^.Tag := 0;
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
                if gear^.Timer = 0 then
                    gear^.Timer:= 3000
                end;
      gtPortal: begin
                gear^.ImpactSound:= sndMelonImpact;
                gear^.nImpactSounds:= 1;
                gear^.AdvBounce:= 0;
                gear^.Radius:= 17;
                // set color
                gear^.Tag:= 2 * gear^.Timer;
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
     gtLandGun: begin
                gear^.Tag:= 10;
                gear^.Timer:= 10;
                gear^.Health:= 1000;
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
   gtStructure: begin
                gear^.Elasticity:= _0_55;
                gear^.Friction:= _0_995;
                gear^.Density:= _0_9;
                gear^.Radius:= 13;
                gear^.Health:= 200;
                gear^.Timer:= 0;
                gear^.Tag:= TotalRounds + 3;
                gear^.Pos:= 1;
                end;
      gtIceGun: gear^.Health:= 1000;
gtGenericFaller:begin
                gear^.AdvBounce:= 1;
                gear^.Radius:= 1;
                gear^.Elasticity:= _0_9;
                gear^.Friction:= _0_995;
                gear^.Density:= _1;
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

FreeTexture(Gear^.Tex);
Gear^.Tex:= nil;

// make sure that portals have their link removed before deletion
if (Gear^.Kind = gtPortal) then
    begin
    if (Gear^.LinkedGear <> nil) then
        if (Gear^.LinkedGear^.LinkedGear = Gear) then
            Gear^.LinkedGear^.LinkedGear:= nil;
    end
else if Gear^.Kind = gtHedgehog then
    (*
    This behaviour dates back to revision 4, and I accidentally encountered it with TARDIS.  I don't think it must apply to any modern weapon, since if it was actually hit, the best the gear could do would be to destroy itself immediately, and you'd still end up with two graves.  I believe it should be removed
     if (CurAmmoGear <> nil) and (CurrentHedgehog^.Gear = Gear) then
        begin
        AttackBar:= 0;
        Gear^.Message:= gmDestroy;
        CurAmmoGear^.Message:= gmDestroy;
        exit
        end
    else*)
        begin
        if (Gear <> CurrentHedgehog^.Gear) or (CurAmmoGear = nil) or (CurAmmoGear^.Kind <> gtKamikaze) then
            Gear^.Hedgehog^.Team^.Clan^.Flawless:= false;
        if (hwRound(Gear^.Y) >= cWaterLine) then
            begin
            t:= max(Gear^.Damage, Gear^.Health);
            Gear^.Damage:= t;
            if ((not SuddenDeathDmg and (WaterOpacity < $FF)) or (SuddenDeathDmg and (WaterOpacity < $FF)))
            and (hwRound(Gear^.Y) < cWaterLine + 256) then
                spawnHealthTagForHH(Gear, t);
            end;

        team:= Gear^.Hedgehog^.Team;
        if CurrentHedgehog^.Gear = Gear then
            begin
            AttackBar:= 0;
            FreeActionsList; // to avoid ThinkThread on drawned gear
            if ((Ammoz[CurrentHedgehog^.CurAmmoType].Ammo.Propz and ammoprop_NoRoundEnd) <> 0)
            and (CurrentHedgehog^.MultiShootAttacks > 0) then
                OnUsedAmmo(CurrentHedgehog^);
            end;

        Gear^.Hedgehog^.Gear:= nil;
        if Gear^.Hedgehog^.King then
            begin
            // are there any other kings left? Just doing nil check.  Presumably a mortally wounded king will get reaped soon enough
            k:= false;
            for i:= 0 to Pred(team^.Clan^.TeamsNumber) do
                if (team^.Clan^.Teams[i]^.Hedgehogs[0].Gear <> nil) then
                    k:= true;
            if not k then
                for i:= 0 to Pred(team^.Clan^.TeamsNumber) do
                    begin
                    team^.Clan^.Teams[i]^.hasGone:= true;
                    TeamGoneEffect(team^.Clan^.Teams[i]^)
                    end
            end;

        // should be not CurrentHedgehog, but hedgehog of the last gear which caused damage to this hog
        // same stand for CheckHHDamage
        if (Gear^.LastDamage <> nil) then
            uStats.HedgehogDamaged(Gear, Gear^.LastDamage, 0, true)
        else
            uStats.HedgehogDamaged(Gear, CurrentHedgehog, 0, true);

        inc(KilledHHs);
        RecountTeamHealth(team);
        if (CurrentHedgehog <> nil) and (CurrentHedgehog^.Effects[heResurrectable] <> 0)  and
        //(Gear^.Hedgehog^.Effects[heResurrectable] = 0) then
        (Gear^.Hedgehog^.Team^.Clan <> CurrentHedgehog^.Team^.Clan) then
            with CurrentHedgehog^ do 
                begin
                inc(Team^.stats.AIKills);
                FreeTexture(Team^.AIKillsTex);
                Team^.AIKillsTex := RenderStringTex(inttostr(Team^.stats.AIKills), Team^.Clan^.Color, fnt16);
                end
        end;
with Gear^ do
    begin
    AddFileLog('Delete: #' + inttostr(uid) + ' (' + inttostr(hwRound(x)) + ',' + inttostr(hwRound(y)) + '), d(' + floattostr(dX) + ',' + floattostr(dY) + ') type = ' + EnumToStr(Kind));
    AddRandomness(X.round xor X.frac xor dX.round xor dX.frac xor Y.round xor Y.frac xor dY.round xor dY.frac)
    end;
if CurAmmoGear = Gear then
    CurAmmoGear:= nil;
if FollowGear = Gear then
    FollowGear:= nil;
if lastGearByUID = Gear then
    lastGearByUID := nil;
RemoveGearFromList(Gear);
Dispose(Gear)
end;

end.
