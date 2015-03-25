(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2014 Andrey Korotaev <unC0Rr@gmail.com>
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
unit uGearsList;

interface
uses uFloat, uTypes, SDLh;

function  AddGear(X, Y: LongInt; Kind: TGearType; State: Longword; dX, dY: hwFloat; Timer: LongWord): PGear;
procedure DeleteGear(Gear: PGear);
procedure InsertGearToList(Gear: PGear);
procedure RemoveGearFromList(Gear: PGear);

var curHandledGear: PGear;

implementation

uses uRandom, uUtils, uConsts, uVariables, uAmmos, uTeams, uStats,
    uTextures, uScript, uRenderUtils, uAI, uCollisions,
    uGearsRender, uGearsUtils, uDebug;

const
    GearKindAmmoTypeMap : array [TGearType] of TAmmoType = (
(*          gtFlame *)   amNothing
(*       gtHedgehog *) , amNothing
(*           gtMine *) , amMine
(*           gtCase *) , amNothing
(*        gtAirMine *) , amAirMine
(*     gtExplosives *) , amNothing
(*        gtGrenade *) , amGrenade
(*          gtShell *) , amBazooka
(*          gtGrave *) , amNothing
(*            gtBee *) , amBee
(*    gtShotgunShot *) , amShotgun
(*     gtPickHammer *) , amPickHammer
(*           gtRope *) , amRope
(*     gtDEagleShot *) , amDEagle
(*       gtDynamite *) , amDynamite
(*    gtClusterBomb *) , amClusterBomb
(*        gtCluster *) , amClusterBomb
(*         gtShover *) , amBaseballBat  // Shover is only used for baseball bat right now
(*      gtFirePunch *) , amFirePunch
(*    gtATStartGame *) , amNothing
(*   gtATFinishGame *) , amNothing
(*      gtParachute *) , amParachute
(*      gtAirAttack *) , amAirAttack
(*        gtAirBomb *) , amAirAttack
(*      gtBlowTorch *) , amBlowTorch
(*         gtGirder *) , amGirder
(*       gtTeleport *) , amTeleport
(*       gtSwitcher *) , amSwitch
(*         gtTarget *) , amNothing
(*         gtMortar *) , amMortar
(*           gtWhip *) , amWhip
(*       gtKamikaze *) , amKamikaze
(*           gtCake *) , amCake
(*      gtSeduction *) , amSeduction
(*     gtWatermelon *) , amWatermelon
(*     gtMelonPiece *) , amWatermelon
(*    gtHellishBomb *) , amHellishBomb
(*        gtWaterUp *) , amNothing
(*          gtDrill *) , amDrill
(*        gtBallGun *) , amBallgun
(*           gtBall *) , amBallgun
(*        gtRCPlane *) , amRCPlane
(*gtSniperRifleShot *) , amSniperRifle
(*        gtJetpack *) , amJetpack
(*        gtMolotov *) , amMolotov
(*          gtBirdy *) , amBirdy
(*            gtEgg *) , amBirdy
(*         gtPortal *) , amPortalGun
(*          gtPiano *) , amPiano
(*        gtGasBomb *) , amGasBomb
(*    gtSineGunShot *) , amSineGun
(*   gtFlamethrower *) , amFlamethrower
(*          gtSMine *) , amSMine
(*    gtPoisonCloud *) , amNothing
(*         gtHammer *) , amHammer
(*      gtHammerHit *) , amHammer
(*    gtResurrector *) , amResurrector
(*    gtPoisonCloud *) , amNothing
(*       gtSnowball *) , amSnowball
(*          gtFlake *) , amNothing
//(*      gtStructure *) , amStructure  // TODO - This will undoubtedly change once there is more than one structure
(*        gtLandGun *) , amLandGun
(*         gtTardis *) , amTardis
(*         gtIceGun *) , amIceGun
(*        gtAddAmmo *) , amNothing
(*  gtGenericFaller *) , amNothing
(*          gtKnife *) , amKnife
    );


var GCounter: LongWord = 0; // this does not get re-initialized, but should be harmless

const
    cUsualZ = 500;
    cOnHHZ = 2000;

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
if (Gear <> GearsList) and (Gear <> nil) and (Gear^.NextGear = nil) and (Gear^.PrevGear = nil) then
    begin
    AddFileLog('Attempted to remove Gear #'+inttostr(Gear^.uid)+' from the list twice.');
    exit
    end;
TryDo((Gear = nil) or (curHandledGear = nil) or (Gear = curHandledGear), 'You''re doing it wrong', true);

if Gear^.NextGear <> nil then
    Gear^.NextGear^.PrevGear:= Gear^.PrevGear;
if Gear^.PrevGear <> nil then
    Gear^.PrevGear^.NextGear:= Gear^.NextGear
else 
    GearsList:= Gear^.NextGear;

Gear^.NextGear:= nil;
Gear^.PrevGear:= nil
end;


function AddGear(X, Y: LongInt; Kind: TGearType; State: Longword; dX, dY: hwFloat; Timer: LongWord): PGear;
var gear: PGear;
    //c: byte;
    cakeData: PCakeData;
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
gear^.Tint:= $FFFFFFFF;
gear^.Data:= nil;

if CurrentHedgehog <> nil then
    begin
    gear^.Hedgehog:= CurrentHedgehog;
    if (CurrentHedgehog^.Gear <> nil) and (hwRound(CurrentHedgehog^.Gear^.X) = X) and (hwRound(CurrentHedgehog^.Gear^.Y) = Y) then
        gear^.CollisionMask:= lfNotCurrentMask
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
                gear^.AdvBounce:= 1;
                gear^.Density:= _2
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
                // this would presumably be set in the frontend
                // if we weren't going to do that yet, would need to reinit GetRandom
                // oh, and, randomising slightly R and B might be nice too.
                //gear^.Tint:= $fa00efff or ((random(80)+128) shl 16)
                //gear^.Tint:= $faa4efff
                //gear^.Tint:= (($e0+random(32)) shl 24) or
                //             ((random(80)+128) shl 16) or
                //             (($d5+random(32)) shl 8) or $ff
                {c:= GetRandom(32);
                gear^.Tint:= (($e0+c) shl 24) or
                             ((GetRandom(90)+128) shl 16) or
                             (($d5+c) shl 8) or $ff}
                end;
       gtShell: begin
                gear^.Elasticity:= _0_8;
                gear^.Friction:= _0_8;
                gear^.Radius:= 4;
                gear^.Density:= _1;
                gear^.AdvBounce:= 1;
                end;
       gtSnowball: begin
                gear^.ImpactSound:= sndMudballImpact;
                gear^.nImpactSounds:= 1;
                gear^.Radius:= 4;
                gear^.Density:= _0_5;
                gear^.AdvBounce:= 1;
                gear^.Elasticity:= _0_8;
                gear^.Friction:= _0_8;
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
                        dx.QWordValue:= QWord($40DA) * GetRandom(10000) * 8;
                        dy.isNegative:= false;
                        dy.QWordValue:= QWord($3AD3) * GetRandom(7000) * 8;
                        if GetRandom(2) = 0 then
                            dx := -dx;
                        Tint:= $FFFFFFFF
                        end
                    else
                        Tint:= (ExplosionBorderColor shr RShift and $FF shl 24) or
                               (ExplosionBorderColor shr GShift and $FF shl 16) or
                               (ExplosionBorderColor shr BShift and $FF shl 8) or $FF;
                    State:= State or gstInvisible;
                    // use health field to store current frameticks
                    if vobFrameTicks > 0 then
                        Health:= random(vobFrameTicks)
                    else
                        Health:= 0;
                    // use timer to store currently displayed frame index
                    if gear^.Timer = 0 then Timer:= random(vobFramesCount);
                    Damage:= (random(2) * 2 - 1) * (vobVelocity + random(vobVelocity)) * 8
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
                if gear^.Timer = 0 then gear^.Timer:= 500;
                gear^.RenderTimer:= true;
                gear^.Elasticity:= _0_9;
                gear^.Tag:= 0;
                gear^.State:= Gear^.State or gstSubmersible
                end;
   gtSeduction: begin
                gear^.Radius:= 250;
                end;
 gtShotgunShot: begin
                if gear^.Timer = 0 then gear^.Timer:= 900;
                gear^.Radius:= 2
                end;
  gtPickHammer: begin
                gear^.Radius:= 10;
                if gear^.Timer = 0 then gear^.Timer:= 4000
                end;
   gtHammerHit: begin
                gear^.Radius:= 8;
                if gear^.Timer = 0 then gear^.Timer:= 125
                end;
        gtRope: begin
                gear^.Radius:= 3;
                gear^.Friction:= _450 * _0_01 * cRopePercent;
                RopePoints.Count:= 0;
                gear^.Tint:= $D8D8D8FF;
                gear^.Tag:= 0; // normal rope render
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
                if gear^.Timer = 0 then
                    begin
                    if cMinesTime < 0 then
                        gear^.Timer:= getrandom(51)*100
                    else
                        gear^.Timer:= cMinesTime
                    end
                end;
     gtAirMine: begin
                gear^.ImpactSound:= sndDenied;
                gear^.nImpactSounds:= 1;
                gear^.Health:= 30;
                gear^.State:= gear^.State or gstMoving or gstNoGravity or gstSubmersible;
                gear^.Radius:= 8;
                gear^.Elasticity:= _0_55;
                gear^.Friction:= _0_995;
                gear^.Density:= _1;
                gear^.Angle:= 175; // Radius at which air bombs will start "seeking". $FFFFFFFF = unlimited. check is skipped.
                gear^.Power:= cMaxWindSpeed.QWordValue div 2; // hwFloat converted. 1/2 g default. defines the "seek" speed when a gear is in range.
                gear^.Pos:= cMaxWindSpeed.QWordValue * 3 div 2; // air friction. slows it down when not hitting stuff
                gear^.Karma:= 30; // damage
                if gear^.Timer = 0 then
                    begin
                    if cMinesTime < 0 then
                        gear^.Timer:= getrandom(13)*100
                    else
                        gear^.Timer:= cMinesTime div 4
                    end;
                gear^.WDTimer:= gear^.Timer
                end;
       gtSMine: begin
                gear^.Health:= 10;
                gear^.State:= gear^.State or gstMoving;
                gear^.Radius:= 2;
                gear^.Elasticity:= _0_55;
                gear^.Friction:= _0_995;
                gear^.Density:= _1_6;
                gear^.AdvBounce:= 1;
                if gear^.Timer = 0 then gear^.Timer:= 500;
                end;
       gtKnife: begin
                gear^.AdvBounce:= 1;
                gear^.Elasticity:= _0_8;
                gear^.Friction:= _0_8;
                gear^.Density:= _4;
                gear^.Radius:= 7
                end;
        gtCase: begin
                gear^.ImpactSound:= sndGraveImpact;
                gear^.nImpactSounds:= 1;
                gear^.Radius:= 16;
                gear^.Elasticity:= _0_3;
                if gear^.Timer = 0 then gear^.Timer:= 500
                end;
  gtExplosives: begin
                gear^.AdvBounce:= 1;
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
                if gear^.Timer = 0 then gear^.Timer:= 5000;
                end;
     gtCluster: begin
                gear^.AdvBounce:= 1;
                gear^.Elasticity:= _0_8;
                gear^.Friction:= _0_8;
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
                gear^.FlightTime:= 9999999; // determines whether in-air flames do damage. disabled by default
                if (gear^.dY.QWordValue = 0) and (gear^.dX.QWordValue = 0) then
                    begin
                    gear^.dY:= (getrandomf - _0_8) * _0_03;
                    gear^.dX:= (getrandomf - _0_5) * _0_4
                    end
                end;
   gtFirePunch: begin
                if gear^.Timer = 0 then gear^.Timer:= 3000;
                gear^.Radius:= 15;
                gear^.Tag:= Y
                end;
   gtAirAttack: begin
                gear^.Z:= cHHZ+2;
                gear^.Tint:= gear^.Hedgehog^.Team^.Clan^.Color shl 8 or $FF
                end;
     gtAirBomb: begin
                gear^.Radius:= 5;
                gear^.Density:= _2;
                end;
   gtBlowTorch: begin
                gear^.Radius:= cHHRadius + cBlowTorchC;
                if gear^.Timer = 0 then gear^.Timer:= 7500
                end;
    gtSwitcher: begin
                gear^.Z:= cCurrHHZ
                end;
      gtTarget: begin
                gear^.ImpactSound:= sndGrenadeImpact;
                gear^.nImpactSounds:= 1;
                gear^.Radius:= 10;
                gear^.Elasticity:= _0_3;
                end;
      gtTardis: begin
                gear^.Pos:= 1;
                gear^.Z:= cCurrHHZ+1;
                end;
      gtMortar: begin
                gear^.AdvBounce:= 1;
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
                    gear^.Angle:= 3;
                New(cakeData);
                gear^.Data:= Pointer(cakeData);
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
                if gear^.Timer = 0 then gear^.Timer:= 5000
                end;
       gtDrill: begin
                gear^.AdvBounce:= 1;
                gear^.Elasticity:= _0_8;
                gear^.Friction:= _0_8;
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
                if gear^.Timer = 0 then gear^.Timer:= 5000;
                gear^.Elasticity:= _0_7;
                gear^.Friction:= _0_995;
                gear^.Density:= _1_5;
                end;
     gtBallgun: begin
                if gear^.Timer = 0 then gear^.Timer:= 5001;
                end;
     gtRCPlane: begin
                if gear^.Timer = 0 then gear^.Timer:= 15000;
                gear^.Health:= 3;
                gear^.Radius:= 8;
                gear^.Tint:= gear^.Hedgehog^.Team^.Clan^.Color shl 8 or $FF
                end;
     gtJetpack: begin
                gear^.Health:= 2000;
                gear^.Damage:= 100;
                gear^.State:= Gear^.State or gstSubmersible
                end;
     gtMolotov: begin
                gear^.AdvBounce:= 1;
                gear^.Radius:= 6;
                gear^.Density:= _2
                end;
       gtBirdy: begin
                gear^.Radius:= 16; // todo: check
                gear^.Health := 2000;
                gear^.FlightTime := 2
                end;
         gtEgg: begin
                gear^.AdvBounce:= 1;
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
                if gear^.Timer = 0 then gear^.Timer:= 10;
                gear^.Health:= 500;
                gear^.Damage:= 100;
                end;
     gtLandGun: begin
                gear^.Tag:= 10;
                if gear^.Timer = 0 then gear^.Timer:= 10;
                gear^.Health:= 1000;
                gear^.Damage:= 100;
                end;
 gtPoisonCloud: begin
                if gear^.Timer = 0 then gear^.Timer:= 5000;
                gear^.dY:= int2hwfloat(-4 + longint(getRandom(8))) / 1000;
                gear^.Tint:= $C0C000C0
                end;
 gtResurrector: begin
                gear^.Radius := 100;
                gear^.Tag := 0;
                gear^.Tint:= $F5DB35FF
                end;
     gtWaterUp: begin
                gear^.Tag := 47;
                end;
  gtNapalmBomb: begin
                gear^.Elasticity:= _0_8;
                gear^.Friction:= _0_8;
                if gear^.Timer = 0 then gear^.Timer:= 1000;
                gear^.Radius:= 5;
                gear^.Density:= _1_5;
                end;
{
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
}
      gtIceGun: begin
                gear^.Health:= 1000;
                gear^.Radius:= 8;
                end;
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
    cakeData: PCakeData;
begin

ScriptCall('onGearDelete', gear^.uid);

DeleteCI(Gear);

FreeAndNilTexture(Gear^.Tex);

// make sure that portals have their link removed before deletion
if (Gear^.Kind = gtPortal) then
    begin
    if (Gear^.LinkedGear <> nil) then
        if (Gear^.LinkedGear^.LinkedGear = Gear) then
            Gear^.LinkedGear^.LinkedGear:= nil;
    end
else if Gear^.Kind = gtCake then
    begin
        cakeData:= PCakeData(Gear^.Data);
        Dispose(cakeData);
        cakeData:= nil;
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
        if ((CurrentHedgehog = nil) or (Gear <> CurrentHedgehog^.Gear)) or (CurAmmoGear = nil) or (CurAmmoGear^.Kind <> gtKamikaze) then
            Gear^.Hedgehog^.Team^.Clan^.Flawless:= false;
        if CheckCoordInWater(hwRound(Gear^.X), hwRound(Gear^.Y)) then
            begin
            t:= max(Gear^.Damage, Gear^.Health);
            Gear^.Damage:= t;
            if (((not SuddenDeathDmg) and (WaterOpacity < $FF)) or (SuddenDeathDmg and (SDWaterOpacity < $FF))) then
                spawnHealthTagForHH(Gear, t);
            end;

        team:= Gear^.Hedgehog^.Team;
        if (CurrentHedgehog <> nil) and (CurrentHedgehog^.Gear = Gear) then
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
        if (Gear^.LastDamage <> nil) and (CurrentHedgehog <> nil) then
            uStats.HedgehogDamaged(Gear, Gear^.LastDamage, 0, true)
        else if CurrentHedgehog <> nil then
            uStats.HedgehogDamaged(Gear, CurrentHedgehog, 0, true);

        inc(KilledHHs);
        RecountTeamHealth(team);
        if (CurrentHedgehog <> nil) and (CurrentHedgehog^.Effects[heResurrectable] <> 0)  and
        //(Gear^.Hedgehog^.Effects[heResurrectable] = 0) then
        (Gear^.Hedgehog^.Team^.Clan <> CurrentHedgehog^.Team^.Clan) then
            with CurrentHedgehog^ do
                begin
                inc(Team^.stats.AIKills);
                FreeAndNilTexture(Team^.AIKillsTex);
                Team^.AIKillsTex := RenderStringTex(ansistring(inttostr(Team^.stats.AIKills)), Team^.Clan^.Color, fnt16);
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
if (Gear^.Hedgehog = nil) or (Gear^.Hedgehog^.GearHidden <> Gear) then // hidden hedgehogs shouldn't be in the list
     RemoveGearFromList(Gear)
else Gear^.Hedgehog^.GearHidden:= nil;

Dispose(Gear)
end;

end.
