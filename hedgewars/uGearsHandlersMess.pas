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

(*
 * This file contains the step handlers for gears.
 *
 * Important: Since gears change the course of the game, calculations that
 *            lead to different results for different clients/players/machines
 *            should NOT occur!
 *            Use safe functions and data types! (e.g. GetRandom() and hwFloat)
 *)

 {$INCLUDE "options.inc"}

unit uGearsHandlersMess;
interface
uses uTypes, uFloat;

procedure doStepPerPixel(Gear: PGear; step: TGearStepProcedure; onlyCheckIfChanged: boolean);
procedure makeHogsWorry(x, y: hwFloat; r: LongInt);
procedure HideHog(HH: PHedgehog);
procedure doStepDrowningGear(Gear: PGear);
procedure doStepFallingGear(Gear: PGear);
procedure doStepBomb(Gear: PGear);
procedure doStepMolotov(Gear: PGear);
procedure doStepCluster(Gear: PGear);
procedure doStepShell(Gear: PGear);
procedure doStepSnowball(Gear: PGear);
procedure doStepSnowflake(Gear: PGear);
procedure doStepGrave(Gear: PGear);
procedure doStepBeeWork(Gear: PGear);
procedure doStepBee(Gear: PGear);
procedure doStepShotIdle(Gear: PGear);
procedure doStepShotgunShot(Gear: PGear);
procedure spawnBulletTrail(Bullet: PGear; bulletX, bulletY: hwFloat);
procedure doStepBulletWork(Gear: PGear);
procedure doStepDEagleShot(Gear: PGear);
procedure doStepSniperRifleShot(Gear: PGear);
procedure doStepActionTimer(Gear: PGear);
procedure doStepPickHammerWork(Gear: PGear);
procedure doStepPickHammer(Gear: PGear);
procedure doStepBlowTorchWork(Gear: PGear);
procedure doStepBlowTorch(Gear: PGear);
procedure doStepMine(Gear: PGear);
procedure doStepAirMine(Gear: PGear);
procedure doStepSMine(Gear: PGear);
procedure doStepDynamite(Gear: PGear);
procedure doStepRollingBarrel(Gear: PGear);
procedure doStepCase(Gear: PGear);
procedure doStepTarget(Gear: PGear);
procedure doStepIdle(Gear: PGear);
procedure doStepShover(Gear: PGear);
procedure doStepWhip(Gear: PGear);
procedure doStepFlame(Gear: PGear);
procedure doStepFirePunchWork(Gear: PGear);
procedure doStepFirePunch(Gear: PGear);
procedure doStepParachuteWork(Gear: PGear);
procedure doStepParachute(Gear: PGear);
procedure doStepAirAttackWork(Gear: PGear);
procedure doStepAirAttack(Gear: PGear);
procedure doStepAirBomb(Gear: PGear);
procedure doStepGirder(Gear: PGear);
procedure doStepTeleportAfter(Gear: PGear);
procedure doStepTeleportAnim(Gear: PGear);
procedure doStepTeleport(Gear: PGear);
procedure doStepSwitcherWork(Gear: PGear);
procedure doStepSwitcher(Gear: PGear);
procedure doStepMortar(Gear: PGear);
procedure doStepKamikazeWork(Gear: PGear);
procedure doStepKamikazeIdle(Gear: PGear);
procedure doStepKamikaze(Gear: PGear);
procedure doStepCakeExpl(Gear: PGear);
procedure doStepCakeDown(Gear: PGear);
procedure doStepCakeWalk(Gear: PGear);
procedure doStepCakeUp(Gear: PGear);
procedure doStepCakeFall(Gear: PGear);
procedure doStepCake(Gear: PGear);
procedure doStepSeductionWork(Gear: PGear);
procedure doStepSeductionWear(Gear: PGear);
procedure doStepSeduction(Gear: PGear);
procedure doStepWaterUp(Gear: PGear);
procedure doStepDrillDrilling(Gear: PGear);
procedure doStepDrill(Gear: PGear);
procedure doStepBallgunWork(Gear: PGear);
procedure doStepBallgun(Gear: PGear);
procedure doStepRCPlaneWork(Gear: PGear);
procedure doStepRCPlane(Gear: PGear);
procedure doStepJetpackWork(Gear: PGear);
procedure doStepJetpack(Gear: PGear);
procedure doStepBirdyDisappear(Gear: PGear);
procedure doStepBirdyFly(Gear: PGear);
procedure doStepBirdyDescend(Gear: PGear);
procedure doStepBirdyAppear(Gear: PGear);
procedure doStepBirdy(Gear: PGear);
procedure doStepEggWork(Gear: PGear);
procedure doPortalColorSwitch();
procedure doStepPortal(Gear: PGear);
procedure loadNewPortalBall(oldPortal: PGear; destroyGear: Boolean);
procedure doStepMovingPortal_real(Gear: PGear);
procedure doStepMovingPortal(Gear: PGear);
procedure doStepPortalShot(newPortal: PGear);
procedure doStepPiano(Gear: PGear);
procedure doStepSineGunShotWork(Gear: PGear);
procedure doStepSineGunShot(Gear: PGear);
procedure doStepFlamethrowerWork(Gear: PGear);
procedure doStepFlamethrower(Gear: PGear);
procedure doStepLandGunWork(Gear: PGear);
procedure doStepLandGun(Gear: PGear);
procedure doStepPoisonCloud(Gear: PGear);
procedure doStepHammer(Gear: PGear);
procedure doStepHammerHitWork(Gear: PGear);
procedure doStepHammerHit(Gear: PGear);
procedure doStepResurrectorWork(Gear: PGear);
procedure doStepResurrector(Gear: PGear);
procedure doStepNapalmBomb(Gear: PGear);
//procedure doStepStructure(Gear: PGear);
procedure doStepTardisWarp(Gear: PGear);
procedure doStepTardis(Gear: PGear);
procedure updateFuel(Gear: PGear);
procedure updateTarget(Gear:PGear; newX, newY:HWFloat);
procedure doStepIceGun(Gear: PGear);
procedure doStepAddAmmo(Gear: PGear);
procedure doStepGenericFaller(Gear: PGear);
//procedure doStepCreeper(Gear: PGear);
procedure doStepKnife(Gear: PGear);
procedure doStepDuck(Gear: PGear);

var
    upd: Longword;
    snowLeft,snowRight: LongInt;

implementation
uses uConsts, uVariables, uVisualGearsList, uRandom, uCollisions, uGearsList, uUtils, uSound
    , SDLh, uScript, uGearsHedgehog, uGearsUtils, uIO, uCaptions, uLandGraphics
    , uGearsHandlers, uTextures, uRenderUtils, uAmmos, uTeams, uLandTexture, uCommands
    , uStore, uAI, uStats, uLocale;

procedure doStepPerPixel(Gear: PGear; step: TGearStepProcedure; onlyCheckIfChanged: boolean);
var
    dX, dY, sX, sY: hwFloat;
    i, steps: LongWord;
    caller: TGearStepProcedure;
begin
    dX:= Gear^.dX;
    dY:= Gear^.dY;
    steps:= max(abs(hwRound(Gear^.X+dX)-hwRound(Gear^.X)), abs(hwRound(Gear^.Y+dY)-hwRound(Gear^.Y)));

    // Gear is still on the same Pixel it was before
    if steps < 1 then
        begin
        if onlyCheckIfChanged then
            begin
            Gear^.X := Gear^.X + dX;
            Gear^.Y := Gear^.Y + dY;
            EXIT;
            end
        else
            steps := 1;
        end;

    if steps > 1 then
        begin
        sX:= dX / steps;
        sY:= dY / steps;
        end

    else
        begin
        sX:= dX;
        sY:= dY;
        end;

    caller:= Gear^.doStep;

    for i:= 1 to steps do
        begin
        Gear^.X := Gear^.X + sX;
        Gear^.Y := Gear^.Y + sY;
        step(Gear);
        if (Gear^.doStep <> caller)
        or ((Gear^.State and gstCollision) <> 0)
        or ((Gear^.State and gstMoving) = 0) then
            break;
        end;
end;

procedure makeHogsWorry(x, y: hwFloat; r: LongInt);
var
    gi: PGear;
    d: LongInt;
begin
    gi := GearsList;
    while gi <> nil do
        begin
        if (gi^.Kind = gtHedgehog) then
            begin
            d := r - hwRound(Distance(gi^.X - x, gi^.Y - y));
            if (d > 1) and (gi^.Hedgehog^.Effects[heInvulnerable] = 0) and (GetRandom(2) = 0) then
                begin
                if (CurrentHedgehog^.Gear = gi) then
                    PlaySoundV(sndOops, gi^.Hedgehog^.Team^.voicepack)

                else
                    begin
                    if ((gi^.State and gstMoving) = 0) and (gi^.Hedgehog^.Effects[heFrozen] = 0) then
                        begin
                        gi^.dX.isNegative:= X<gi^.X;
                        gi^.State := gi^.State or gstLoser;
                        end;

                    if d > r div 2 then
                        PlaySoundV(sndNooo, gi^.Hedgehog^.Team^.voicepack)
                    else
                        PlaySoundV(sndUhOh, gi^.Hedgehog^.Team^.voicepack);
                    end;
                end;
            end;

        gi := gi^.NextGear
        end;
end;

procedure HideHog(HH: PHedgehog);
begin
    ScriptCall('onHogHide', HH^.Gear^.Uid);
    DeleteCI(HH^.Gear);
    if FollowGear = HH^.Gear then
        FollowGear:= nil;

    if lastGearByUID = HH^.Gear then
        lastGearByUID := nil;

    HH^.Gear^.Message:= HH^.Gear^.Message or gmRemoveFromList;
    with HH^.Gear^ do
        begin
        Z := cHHZ;
        HH^.Gear^.Active:= false;
        State:= State and (not (gstHHDriven or gstAttacking or gstAttacked));
        Message := Message and (not gmAttack);
    end;
    HH^.GearHidden:= HH^.Gear;
    HH^.Gear:= nil
end;


////////////////////////////////////////////////////////////////////////////////
procedure doStepDrowningGear(Gear: PGear);
var i, d: LongInt;
    bubble: PVisualGear;
begin
if Gear^.Timer = 0 then
    begin
    d:= 2 * Gear^.Radius;
    for i:= (Gear^.Radius * Gear^.Radius) div 4 downto 0 do
        begin
        bubble := AddVisualGear(hwRound(Gear^.X) - Gear^.Radius + random(d), hwRound(Gear^.Y) - Gear^.Radius + random(d), vgtBubble);
        if bubble <> nil then
            bubble^.dY:= 0.1 + random(20)/10;
        end;
    DeleteGear(Gear);
    exit;
    end;

AllInactive := false;
dec(Gear^.Timer);

Gear^.Y := Gear^.Y + cDrownSpeed;

if cWaterLine > hwRound(Gear^.Y) + Gear^.Radius then
    begin
    if LongInt(leftX) + Gear^.Radius > hwRound(Gear^.X) then
        Gear^.X := Gear^.X - cDrownSpeed
    else
        Gear^.X := Gear^.X + cDrownSpeed;
    end
else
    Gear^.X := Gear^.X + Gear^.dX * cDrownSpeed;

// Create some bubbles (0.5% might be better but causes too few bubbles sometimes)
if ((not SuddenDeathDmg and (WaterOpacity < $FF))
or (SuddenDeathDmg and (SDWaterOpacity < $FF))) and ((GameTicks and $1F) = 0) then
    if (Gear^.Kind = gtHedgehog) and (Random(4) = 0) then
        AddVisualGear(hwRound(Gear^.X) - Gear^.Radius, hwRound(Gear^.Y) - Gear^.Radius, vgtBubble)
else if Random(12) = 0 then
         AddVisualGear(hwRound(Gear^.X) - Gear^.Radius, hwRound(Gear^.Y) - Gear^.Radius, vgtBubble);
if (not SuddenDeathDmg and (WaterOpacity > $FE))
or (SuddenDeathDmg and (SDWaterOpacity > $FE))
or (hwRound(Gear^.Y) > Gear^.Radius + cWaterLine + cVisibleWater) then
    DeleteGear(Gear);
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFallingGear(Gear: PGear);
var
    isFalling: boolean;
    //tmp: QWord;
    tX, tdX, tdY: hwFloat;
    collV, collH, gX, gY: LongInt;
    land, xland: word;
begin
    tX:= Gear^.X;
    gX:= hwRound(Gear^.X);
    gY:= hwRound(Gear^.Y);
    if (Gear^.Kind <> gtGenericFaller) and WorldWrap(Gear) and (WorldEdge = weWrap) and (Gear^.AdvBounce <> 0) and
      ((TestCollisionXwithGear(Gear, 1) <> 0) or (TestCollisionXwithGear(Gear, -1) <> 0))  then
        begin
        Gear^.X:= tX;
        Gear^.dX.isNegative:= (gX > LongInt(leftX) + Gear^.Radius*2)
        end;

    // clip velocity at 2 - over 1 per pixel, but really shouldn't cause many actual problems.
    if Gear^.dX.Round > 1 then
        Gear^.dX.QWordValue:= 8589934592;
    if Gear^.dY.Round > 1 then
        Gear^.dY.QWordValue:= 8589934592;

    if (Gear^.State and gstSubmersible <> 0) and CheckCoordInWater(gX, gY) then
        begin
        Gear^.dX:= Gear^.dX * _0_999;
        Gear^.dY:= Gear^.dY * _0_999
        end;

    Gear^.State := Gear^.State and (not gstCollision);
    collV := 0;
    collH := 0;
    tdX := Gear^.dX;
    tdY := Gear^.dY;

// might need some testing/adjustments - just to avoid projectiles to fly forever (accelerated by wind/skips)
    if (gX < min(LAND_WIDTH div -2, -2048))
    or (gX > max(LAND_WIDTH * 3 div 2, 6144)) then
        Gear^.Message := Gear^.Message or gmDestroy;

    if Gear^.dY.isNegative then
        begin
        land:= TestCollisionYwithGear(Gear, -1);
        isFalling := land = 0;
        if land <> 0 then
            begin
            collV := -1;
            if land and lfIce <> 0 then
                 Gear^.dX := Gear^.dX * (_0_9 + Gear^.Friction * _0_1)
            else Gear^.dX := Gear^.dX * Gear^.Friction;
            if (Gear^.AdvBounce = 0) or (land and lfBouncy = 0) then
                 begin
                 Gear^.dY := - Gear^.dY * Gear^.Elasticity;
                 Gear^.State := Gear^.State or gstCollision
                 end
            else Gear^.dY := - Gear^.dY * cElastic
            end
        else if Gear^.AdvBounce = 1 then
            begin
            land:= TestCollisionYwithGear(Gear, 1);
            if land <> 0 then collV := 1
            end
        end
    else
        begin // Gear^.dY.isNegative is false
        land:= TestCollisionYwithGear(Gear, 1);
        if land <> 0 then
            begin
            collV := 1;
            isFalling := false;
            if land and lfIce <> 0 then
                Gear^.dX := Gear^.dX * (_0_9 + Gear^.Friction * _0_1)
            else
                Gear^.dX := Gear^.dX * Gear^.Friction;

            if (Gear^.AdvBounce = 0) or (land and lfBouncy = 0) then
                 begin
                 Gear^.dY := - Gear^.dY * Gear^.Elasticity;
                 Gear^.State := Gear^.State or gstCollision
                 end
            else Gear^.dY := - Gear^.dY * cElastic
            end
        else
            begin
            isFalling := true;
            if Gear^.AdvBounce = 1 then
                begin
                land:= TestCollisionYwithGear(Gear, -1);
                if land <> 0 then collV := -1
                end
            end
        end;


    xland:= TestCollisionXwithGear(Gear, hwSign(Gear^.dX));
    if xland <> 0 then
        begin
        collH := hwSign(Gear^.dX);
        if (Gear^.AdvBounce = 0) or (xland and lfBouncy = 0) then
            begin
            Gear^.dX := - Gear^.dX * Gear^.Elasticity;
            Gear^.dY :=   Gear^.dY * Gear^.Elasticity;
            Gear^.State := Gear^.State or gstCollision
            end
        else
            begin
            Gear^.dX := - Gear^.dX * cElastic;
            Gear^.dY :=   Gear^.dY * cElastic
            end
        end
    else if Gear^.AdvBounce = 1 then
        begin
        xland:= TestCollisionXwithGear(Gear, -hwSign(Gear^.dX));
        if xland <> 0 then collH := -hwSign(Gear^.dX)
        end;
    //if Gear^.AdvBounce and (collV <>0) and (collH <> 0) and (hwSqr(tdX) + hwSqr(tdY) > _0_08) then
    if (collV <> 0) and (collH <> 0) and
       (((Gear^.AdvBounce=1) and ((collV=-1) or ((tdX.QWordValue + tdY.QWordValue) > _0_2.QWordValue)))) then
 //or ((xland or land) and lfBouncy <> 0)) then
        begin
        if (xland or land) and lfBouncy = 0 then
            begin
            Gear^.dX := tdY*Gear^.Elasticity*Gear^.Friction;
            Gear^.dY := tdX*Gear^.Elasticity;
            Gear^.State := Gear^.State or gstCollision
            end
        else
            begin
            Gear^.dX := tdY*cElastic*Gear^.Friction;
            Gear^.dY := tdX*cElastic
            end;

        Gear^.dX.isNegative:= tdX.isNegative;
        Gear^.dY.isNegative:= tdY.isNegative;
        if (collV > 0) and (collH > 0) and (not tdX.isNegative) and (not tdY.isNegative) then
            begin
            Gear^.dX.isNegative := true;
            Gear^.dY.isNegative := true
            end
        else if (collV > 0) and (collH < 0) and (tdX.isNegative or tdY.isNegative) then
            begin
            Gear^.dY.isNegative := not tdY.isNegative;
            if not tdY.isNegative then Gear^.dX.isNegative := false
            end
        else if (collV < 0) and (collH > 0) and (not tdX.isNegative) then
            begin
            Gear^.dX.isNegative := true;
            Gear^.dY.isNegative := false
            end
        else if (collV < 0) and (collH < 0) and tdX.isNegative and tdY.isNegative then
            Gear^.dX.isNegative := false;
       
        isFalling := false;
        Gear^.AdvBounce := 10;
        end;

    if Gear^.AdvBounce > 1 then
        dec(Gear^.AdvBounce);

    if isFalling and (Gear^.State and gstNoGravity = 0) then
        begin
        Gear^.dY := Gear^.dY + cGravity;
        if (GameFlags and gfMoreWind <> 0) and 
           ((xland or land) = 0) and
           ((Gear^.dX.QWordValue + Gear^.dY.QWordValue) > _0_02.QWordValue) then
            Gear^.dX := Gear^.dX + cWindSpeed / Gear^.Density
        end;

    Gear^.X := Gear^.X + Gear^.dX;
    Gear^.Y := Gear^.Y + Gear^.dY;
    CheckGearDrowning(Gear);
    //if (hwSqr(Gear^.dX) + hwSqr(Gear^.dY) < _0_0002) and
    if (not isFalling) and ((Gear^.dX.QWordValue + Gear^.dY.QWordValue) < _0_02.QWordValue) then
        Gear^.State := Gear^.State and (not gstMoving)
    else
        Gear^.State := Gear^.State or gstMoving;

    if ((xland or land) and lfBouncy <> 0) and (Gear^.dX.QWordValue < _0_15.QWordValue) and (Gear^.dY.QWordValue < _0_15.QWordValue) then
        Gear^.State := Gear^.State or gstCollision;

    if ((xland or land) and lfBouncy <> 0) and (Gear^.Radius >= 3) and
       ((Gear^.dX.QWordValue > _0_15.QWordValue) or (Gear^.dY.QWordValue > _0_15.QWordValue)) then
        begin
        AddBounceEffectForGear(Gear);
        end
    else if (Gear^.nImpactSounds > 0) and
        (Gear^.State and gstCollision <> 0) and
        (((Gear^.Kind <> gtMine) and (Gear^.Damage <> 0)) or (Gear^.State and gstMoving <> 0)) and
        (((Gear^.Radius < 3) and (Gear^.dY < -_0_1)) or
            ((Gear^.Radius >= 3) and
                ((Gear^.dX.QWordValue > _0_1.QWordValue) or (Gear^.dY.QWordValue > _0_1.QWordValue)))) then
        PlaySound(TSound(ord(Gear^.ImpactSound) + LongInt(GetRandom(Gear^.nImpactSounds))), true);
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBomb(Gear: PGear);
var
    i, x, y: LongInt;
    dX, dY, gdX: hwFloat;
    vg: PVisualGear;
begin
    AllInactive := false;

    doStepFallingGear(Gear);

    dec(Gear^.Timer);
    if Gear^.Timer = 1000 then // might need adjustments
        case Gear^.Kind of
            gtGrenade,
            gtClusterBomb,
            gtWatermelon,
            gtHellishBomb: makeHogsWorry(Gear^.X, Gear^.Y, Gear^.Boom);
            gtGasBomb: makeHogsWorry(Gear^.X, Gear^.Y, 50);
        end;

    if (Gear^.Kind = gtBall) and ((Gear^.State and gstTmpFlag) <> 0) then
        begin
        CheckCollision(Gear);
        if (Gear^.State and gstCollision) <> 0 then
            doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLDontDraw or EXPLNoGfx);
        end;

    if (Gear^.Kind = gtGasBomb) and ((GameTicks mod 200) = 0) then
        begin
        vg:= AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtSmokeWhite);
        if vg <> nil then
            vg^.Tint:= $FFC0C000;
        end;

    if Gear^.Timer = 0 then
        begin
        case Gear^.Kind of
            gtGrenade: doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
            gtBall: doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
            gtClusterBomb:
                begin
                x := hwRound(Gear^.X);
                y := hwRound(Gear^.Y);
                gdX:= Gear^.dX;
                doMakeExplosion(x, y, Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
                for i:= 0 to 4 do
                    begin
                    dX := rndSign(GetRandomf * _0_1) + gdX / 5;
                    dY := (GetRandomf - _3) * _0_08;
                    FollowGear := AddGear(x, y, gtCluster, 0, dX, dY, 25)
                    end
                end;
            gtWatermelon:
                begin
                x := hwRound(Gear^.X);
                y := hwRound(Gear^.Y);
                gdX:= Gear^.dX;
                doMakeExplosion(x, y, Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
                for i:= 0 to 5 do
                    begin
                    dX := rndSign(GetRandomf * _0_1) + gdX / 5;
                    dY := (GetRandomf - _1_5) * _0_3;
                    FollowGear:= AddGear(x, y, gtMelonPiece, 0, dX, dY, 75);
                    FollowGear^.DirAngle := i * 60
                    end
                end;
            gtHellishBomb:
                begin
                x := hwRound(Gear^.X);
                y := hwRound(Gear^.Y);
                doMakeExplosion(x, y, Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);

                for i:= 0 to 127 do
                    begin
                    dX := AngleCos(i * 16) * _0_5 * (GetRandomf + _1);
                    dY := AngleSin(i * 16) * _0_5 * (GetRandomf + _1);
                    if i mod 2 = 0 then
                        begin
                        AddGear(x, y, gtFlame, gstTmpFlag, dX, dY, 0);
                        AddGear(x, y, gtFlame, 0, dX, -dY, 0)
                        end
                    else
                        begin
                        AddGear(x, y, gtFlame, 0, dX, dY, 0);
                        AddGear(x, y, gtFlame, gstTmpFlag, dX, -dY, 0)
                        end;
                    end
                end;
            gtGasBomb:
                begin
                doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
                for i:= 0 to 2 do
                    begin
                    x:= GetRandom(60);
                    y:= GetRandom(40);
                    FollowGear:= AddGear(hwRound(Gear^.X) - 30 + x, hwRound(Gear^.Y) - 20 + y, gtPoisonCloud, 0, _0, _0, 0);
                    end
                end;
            end;
        DeleteGear(Gear);
        exit
        end;

    CalcRotationDirAngle(Gear);

    if Gear^.Kind = gtHellishBomb then
        begin

        if Gear^.Timer = 3000 then
            begin
            Gear^.nImpactSounds := 0;
            PlaySound(sndHellish);
            end;

        if (GameTicks and $3F) = 0 then
            if (Gear^.State and gstCollision) = 0 then
                AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtEvilTrace);
        end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepMolotov(Gear: PGear);
var
    s: Longword;
    i, gX, gY: LongInt;
    dX, dY: hwFloat;
    smoke, glass: PVisualGear;
begin
    AllInactive := false;

    doStepFallingGear(Gear);
    CalcRotationDirAngle(Gear);

    // let's add some smoke depending on speed
    s:= max(32,152 - round((abs(hwFloat2FLoat(Gear^.dX))+abs(hwFloat2Float(Gear^.dY)))*120))+random(10);
    if (GameTicks mod s) = 0 then
        begin
        // adjust angle to match the texture
        if Gear^.dX.isNegative then
             i:= 130
        else i:= 50;

        smoke:= AddVisualGear(hwRound(Gear^.X)-round(cos((Gear^.DirAngle+i) * pi / 180)*20), hwRound(Gear^.Y)-round(sin((Gear^.DirAngle+i) * pi / 180)*20), vgtSmoke);
        if smoke <> nil then
            smoke^.Scale:= 0.75;
        end;

    if (Gear^.State and gstCollision) <> 0 then
        begin
        PlaySound(sndMolotov);
        gX := hwRound(Gear^.X);
        gY := hwRound(Gear^.Y);
        for i:= 0 to 4 do
            begin
            (*glass:= AddVisualGear(gx+random(7)-3, gy+random(5)-2, vgtEgg);
            if glass <> nil then
                begin
                glass^.Frame:= 2;
                glass^.Tint:= $41B83ED0 - i * $10081000;
                glass^.dX:= 1/(10*(random(11)-5));
                glass^.dY:= -1/(random(4)+5);
                end;*)
            glass:= AddVisualGear(gx+random(7)-3, gy+random(7)-3, vgtStraightShot);
            if glass <> nil then
                with glass^ do
                    begin
                    Frame:= 2;
                    Tint:= $41B83ED0 - i * $10081000;
                    Angle:= random(360);
                    dx:= 0.0000001;
                    dy:= 0;
                    if random(2) = 0 then
                        dx := -dx;
                    FrameTicks:= 750;
                    State:= ord(sprEgg)
                    end;
            end;
        for i:= 0 to 24 do
            begin
            dX := AngleCos(i * 2) * ((_0_15*(i div 5))) * (GetRandomf + _1);
            dY := AngleSin(i * 8) * _0_5 * (GetRandomf + _1);
            AddGear(gX, gY, gtFlame, gstTmpFlag, dX, dY, 0);
            AddGear(gX, gY, gtFlame, gstTmpFlag, dX,-dY, 0);
            AddGear(gX, gY, gtFlame, gstTmpFlag,-dX, dY, 0);
            AddGear(gX, gY, gtFlame, gstTmpFlag,-dX,-dY, 0);
            end;
        DeleteGear(Gear);
        exit
        end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepCluster(Gear: PGear);
begin
    AllInactive := false;
    doStepFallingGear(Gear);
    if (Gear^.State and gstCollision) <> 0 then
        begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
        DeleteGear(Gear);
        exit
    end;

    if (Gear^.Kind = gtMelonPiece) then
        CalcRotationDirAngle(Gear)
    else if (GameTicks and $1F) = 0 then
        AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtSmokeTrace);
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepShell(Gear: PGear);
begin
    AllInactive := false;
    if (GameFlags and gfMoreWind) = 0 then
        Gear^.dX := Gear^.dX + cWindSpeed;
    doStepFallingGear(Gear);
    if (Gear^.State and gstCollision) <> 0 then
        begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
        DeleteGear(Gear);
        exit
        end;
    if (GameTicks and $3F) = 0 then
        AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtSmokeTrace);
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSnowball(Gear: PGear);
var kick, i: LongInt;
    particle: PVisualGear;
    gdX, gdY: hwFloat;
begin
    AllInactive := false;
    if (GameFlags and gfMoreWind) = 0 then
        Gear^.dX := Gear^.dX + cWindSpeed;
    gdX := Gear^.dX;
    gdY := Gear^.dY;
    doStepFallingGear(Gear);
    CalcRotationDirAngle(Gear);
    if (Gear^.State and gstCollision) <> 0 then
        begin
        kick:= hwRound((hwAbs(gdX)+hwAbs(gdY)) * Gear^.Boom / 10000);
        Gear^.dX:= gdX;
        Gear^.dY:= gdY;
        AmmoShove(Gear, 0, kick);
        for i:= 15 + kick div 10 downto 0 do
            begin
            particle := AddVisualGear(hwRound(Gear^.X) + Random(25), hwRound(Gear^.Y) + Random(25), vgtDust);
            if particle <> nil then
                particle^.dX := particle^.dX + (Gear^.dX.QWordValue / 21474836480)
            end;
        DeleteGear(Gear);
        exit
        end;
    if ((GameTicks and $1F) = 0) and (Random(3) = 0) then
        begin
        particle:= AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtDust);
        if particle <> nil then
            particle^.dX := particle^.dX + (Gear^.dX.QWordValue / 21474836480)
        end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSnowflake(Gear: PGear);
var xx, yy, px, py, rx, ry, lx, ly: LongInt;
    move, draw, allpx, gun: Boolean;
    s: PSDL_Surface;
    p: PLongwordArray;
    lf: LongWord;
begin
inc(Gear^.Pos);
gun:= (Gear^.State and gstTmpFlag) <> 0;
move:= false;
draw:= false;
if gun then
    begin
    Gear^.State:= Gear^.State and (not gstInvisible);
    doStepFallingGear(Gear);
    CheckCollision(Gear);
    if ((Gear^.State and gstCollision) <> 0) or ((Gear^.State and gstMoving) = 0) then
        draw:= true;
    xx:= hwRound(Gear^.X);
    yy:= hwRound(Gear^.Y);
    if draw and (WorldEdge = weWrap) and ((xx < LongInt(leftX) + 3) or (xx > LongInt(rightX) - 3)) then
        begin
        if xx < LongInt(leftX) + 3 then
             xx:= rightX-3
        else xx:= leftX+3;
        Gear^.X:= int2hwFloat(xx)
        end
    end
else if GameTicks and $7 = 0 then
    begin
    with Gear^ do
        begin
        State:= State and (not gstInvisible);
        X:= X + cWindSpeed * 3200 + dX;
        Y:= Y + dY + cGravity * vobFallSpeed * 8;  // using same value as flakes to try and get similar results
        xx:= hwRound(X);
        yy:= hwRound(Y);
        if vobVelocity <> 0 then
            begin
            DirAngle := DirAngle + (Damage / 1000);
            if DirAngle < 0 then
                DirAngle := DirAngle + 360
            else if 360 < DirAngle then
                DirAngle := DirAngle - 360;
            end;
(*
We aren't using frametick right now, so just a waste of cycles.
        inc(Health, 8);
        if longword(Health) > vobFrameTicks then
            begin
            dec(Health, vobFrameTicks);
            inc(Timer);
            if Timer = vobFramesCount then
                Timer:= 0
            end;
*)
    // move back to cloud layer
        if CheckCoordInWater(xx, yy) then
            move:= true
        else if (xx > snowRight) or (xx < snowLeft) then
            move:=true
        else if (cGravity < _0) and (yy < LAND_HEIGHT-1200) then
            move:=true
        // Solid pixel encountered
        else if ((yy and LAND_HEIGHT_MASK) = 0) and ((xx and LAND_WIDTH_MASK) = 0) and (Land[yy, xx] <> 0) then
            begin
            lf:= Land[yy, xx] and (lfObject or lfBasic or lfIndestructible);
            if lf = 0 then lf:= lfObject;
            // If there's room below keep falling
            if (((yy-1) and LAND_HEIGHT_MASK) = 0) and (Land[yy-1, xx] = 0) then
                begin
                X:= X - cWindSpeed * 1600 - dX;
                end
            // If there's room below, on the sides, fill the gaps
            else if (((yy-1) and LAND_HEIGHT_MASK) = 0) and (((xx-(1*hwSign(cWindSpeed))) and LAND_WIDTH_MASK) = 0) and (Land[yy-1, (xx-(1*hwSign(cWindSpeed)))] = 0) then
                begin
                X:= X - _0_8 * hwSign(cWindSpeed);
                Y:= Y - dY - cGravity * vobFallSpeed * 8;
                end
            else if (((yy-1) and LAND_HEIGHT_MASK) = 0) and (((xx-(2*hwSign(cWindSpeed))) and LAND_WIDTH_MASK) = 0) and (Land[yy-1, (xx-(2*hwSign(cWindSpeed)))] = 0) then
                begin
                X:= X - _0_8 * 2 * hwSign(cWindSpeed);
                Y:= Y - dY - cGravity * vobFallSpeed * 8;
                end
            else if (((yy-1) and LAND_HEIGHT_MASK) = 0) and (((xx+(1*hwSign(cWindSpeed))) and LAND_WIDTH_MASK) = 0) and (Land[yy-1, (xx+(1*hwSign(cWindSpeed)))] = 0) then
                begin
                X:= X + _0_8 * hwSign(cWindSpeed);
                Y:= Y - dY - cGravity * vobFallSpeed * 8;
                end
            else if (((yy-1) and LAND_HEIGHT_MASK) = 0) and (((xx+(2*hwSign(cWindSpeed))) and LAND_WIDTH_MASK) = 0) and (Land[yy-1, (xx+(2*hwSign(cWindSpeed)))] = 0) then
                begin
                X:= X + _0_8 * 2 * hwSign(cWindSpeed);
                Y:= Y - dY - cGravity * vobFallSpeed * 8;
                end
            // if there's an hog/object below do nothing
            else if ((((yy+1) and LAND_HEIGHT_MASK) = 0) and ((Land[yy+1, xx] and $FF) <> 0))
                then move:=true
            else draw:= true
            end
        end
    end;
if draw then
    with Gear^ do
        begin
        // we've collided with land. draw some stuff and get back into the clouds
        move:= true;
        if (Pos > 20) and ((CurAmmoGear = nil)
        or (CurAmmoGear^.Kind <> gtRope)) then
            begin
////////////////////////////////// TODO - ASK UNC0RR FOR A GOOD HOME FOR THIS ////////////////////////////////////
            if not gun then
                begin
                dec(yy,3);
                dec(xx,1)
                end;
            s:= SpritesData[sprSnow].Surface;
            p:= s^.pixels;
            allpx:= true;
            for py:= 0 to Pred(s^.h) do
                begin
                for px:= 0 to Pred(s^.w) do
                    begin
                    lx:=xx + px; ly:=yy + py;
                    if (ly and LAND_HEIGHT_MASK = 0) and (lx and LAND_WIDTH_MASK = 0) and (Land[ly, lx] and $FF = 0) then
                        begin
                        rx:= lx;
                        ry:= ly;
                        if cReducedQuality and rqBlurryLand <> 0 then
                            begin
                            rx:= rx div 2;ry:= ry div 2;
                            end;
                        if Land[yy + py, xx + px] <= lfAllObjMask then
                            if gun then
                                begin
                                LandDirty[yy div 32, xx div 32]:= 1;
                                if LandPixels[ry, rx] = 0 then
                                    Land[ly, lx]:=  lfDamaged or lfObject
                                else Land[ly, lx]:=  lfDamaged or lfBasic
                                end
                            else Land[ly, lx]:= lf;
                        if gun then
                             LandPixels[ry, rx]:= (Gear^.Tint shr 24         shl RShift) or 
                                                  (Gear^.Tint shr 16 and $FF shl GShift) or 
                                                  (Gear^.Tint shr  8 and $FF shl BShift) or 
                                                  (p^[px] and AMask)
                        else LandPixels[ry, rx]:= addBgColor(LandPixels[ry, rx], p^[px]);
                        end
                    else allpx:= false
                    end;
                p:= PLongWordArray(@(p^[s^.pitch shr 2]))
                end;

            // Why is this here.  For one thing, there's no test on +1 being safe.
            //Land[py, px+1]:= lfBasic;

            if allpx then
                UpdateLandTexture(xx, Pred(s^.h), yy, Pred(s^.w), true)
            else
                begin
                UpdateLandTexture(
                    max(0, min(LAND_WIDTH, xx)),
                    min(LAND_WIDTH - xx, Pred(s^.w)),
                    max(0, min(LAND_WIDTH, yy)),
                    min(LAND_HEIGHT - yy, Pred(s^.h)), false // could this be true without unnecessarily creating blanks?
                );
                end;
////////////////////////////////// TODO - ASK UNC0RR FOR A GOOD HOME FOR THIS ////////////////////////////////////
            end
        end;

if move then
    begin
    if gun then
        begin
        DeleteGear(Gear);
        exit
        end;
    Gear^.Pos:= 0;
    Gear^.X:= int2hwFloat(LongInt(GetRandom(snowRight - snowLeft)) + snowLeft);
    if (cGravity < _0) and (yy < LAND_HEIGHT-1200) then
         Gear^.Y:= int2hwFloat(LAND_HEIGHT - 50 - LongInt(GetRandom(50)))
    else Gear^.Y:= int2hwFloat(LAND_HEIGHT + LongInt(GetRandom(50)) - 1250);
    Gear^.State:= Gear^.State or gstInvisible;
    end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepGrave(Gear: PGear);
begin
    if (Gear^.Message and gmDestroy) <> 0 then
        begin
        DeleteGear(Gear);
        exit
        end;

    AllInactive := false;

    if Gear^.dY.isNegative then
        if TestCollisionY(Gear, -1) <> 0 then
            Gear^.dY := _0;

    if not Gear^.dY.isNegative then
        if TestCollisionY(Gear, 1) <> 0 then
            begin
            Gear^.dY := - Gear^.dY * Gear^.Elasticity;
            if Gear^.dY > - _1div1024 then
                begin
                Gear^.Active := false;
                exit
                end
            else if Gear^.dY < - _0_03 then
                PlaySound(Gear^.ImpactSound)
            end;

    Gear^.Y := Gear^.Y + Gear^.dY;
    CheckGearDrowning(Gear);
    Gear^.dY := Gear^.dY + cGravity
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBeeWork(Gear: PGear);
var
    t: hwFloat;
    gX,gY,i: LongInt;
    uw, nuw: boolean;
    flower: PVisualGear;

begin
    WorldWrap(Gear);
    AllInactive := false;
    gX := hwRound(Gear^.X);
    gY := hwRound(Gear^.Y);
    uw := (Gear^.Tag <> 0); // was bee underwater last tick?
    nuw := CheckCoordInWater(gx, gy + Gear^.Radius); // is bee underwater now?

    // if water entered or left
    if nuw <> uw then
        begin
        if Gear^.Timer <> 5000 then
            AddSplashForGear(Gear, false);
        StopSoundChan(Gear^.SoundChannel);
        if nuw then
            begin
            Gear^.SoundChannel := LoopSound(sndBeeWater);
            Gear^.Tag := 1;
        end
        else
            begin
            Gear^.SoundChannel := LoopSound(sndBee);
            Gear^.Tag := 0;
            end;
        end;


    if Gear^.Timer = 0 then
        begin
        // no "fuel"? just fall
        doStepFallingGear(Gear);
        // if drowning, stop bee sound
        if (Gear^.State and gstDrowning) <> 0 then
            StopSoundChan(Gear^.SoundChannel);
        end
    else
        begin
        if (Gear^.Timer and $F) = 0 then
            begin
            if (Gear^.Timer and $3F) = 0 then
                AddVisualGear(gX, gY, vgtBeeTrace);

            Gear^.dX := Gear^.dX + _0_000064 * (Gear^.Target.X - gX);
            Gear^.dY := Gear^.dY + _0_000064 * (Gear^.Target.Y - gY);
            // make sure new speed isn't higher than original one (which we stored in Friction variable)
            t := Gear^.Friction / Distance(Gear^.dX, Gear^.dY);
            Gear^.dX := Gear^.dX * t;
            Gear^.dY := Gear^.dY * t;
            end;

        Gear^.X := Gear^.X + Gear^.dX;
        Gear^.Y := Gear^.Y + Gear^.dY;

        end;


    CheckCollision(Gear);
    if ((Gear^.State and gstCollision) <> 0) then
        begin
        StopSoundChan(Gear^.SoundChannel);
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
        for i:= 0 to 31 do
            begin
            flower:= AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtStraightShot);
            if flower <> nil then
                with flower^ do
                    begin
                    Scale:= 0.75;
                    dx:= 0.001 * (random(200));
                    dy:= 0.001 * (random(200));
                    if random(2) = 0 then
                        dx := -dx;
                    if random(2) = 0 then
                        dy := -dy;
                    FrameTicks:= random(250) + 250;
                    State:= ord(sprTargetBee);
                    end;
            end;
        DeleteGear(Gear);
        exit;
    end;

    if (Gear^.Timer > 0) then
        begin
        dec(Gear^.Timer);
        if Gear^.Timer = 0 then
            begin
            // no need to display remaining time anymore
            Gear^.RenderTimer:= false;
            // bee can drown when timer reached 0
            Gear^.State:= Gear^.State and (not gstSubmersible);
            end;
        end;
end;

procedure doStepBee(Gear: PGear);
begin
    AllInactive := false;
    Gear^.X := Gear^.X + Gear^.dX;
    Gear^.Y := Gear^.Y + Gear^.dY;
    WorldWrap(Gear);
    Gear^.dY := Gear^.dY + cGravity;
    CheckGearDrowning(Gear);
    CheckCollision(Gear);
    if (Gear^.State and gstCollision) <> 0 then
        begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
        DeleteGear(Gear);
        exit
    end;
    dec(Gear^.Timer);
    if Gear^.Timer = 0 then
        begin
        Gear^.Hedgehog^.Gear^.Message:= Gear^.Hedgehog^.Gear^.Message and (not gmAttack);
        Gear^.Hedgehog^.Gear^.State:= Gear^.Hedgehog^.Gear^.State and (not gstAttacking);
        AttackBar:= 0;

        Gear^.SoundChannel := LoopSound(sndBee);
        Gear^.Timer := 5000;
        // save initial speed in otherwise unused Friction variable
        Gear^.Friction := Distance(Gear^.dX, Gear^.dY);
        Gear^.doStep := @doStepBeeWork
        end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepShotIdle(Gear: PGear);
begin
    AllInactive := false;
    inc(Gear^.Timer);
    if Gear^.Timer > 75 then
        begin
        DeleteGear(Gear);
        AfterAttack
        end
end;

procedure doStepShotgunShot(Gear: PGear);
var
    i: LongWord;
    shell: PVisualGear;
begin
    AllInactive := false;

    if ((Gear^.State and gstAnimation) = 0) then
        begin
        dec(Gear^.Timer);
        if Gear^.Timer = 0 then
            begin
            PlaySound(sndShotgunFire);
            shell := AddVisualGear(hwRound(Gear^.x), hwRound(Gear^.y), vgtShell);
            if shell <> nil then
                begin
                shell^.dX := gear^.dX.QWordValue / -17179869184;
                shell^.dY := gear^.dY.QWordValue / -17179869184;
                shell^.Frame := 0
                end;
            Gear^.State := Gear^.State or gstAnimation
            end;
            exit
        end else
        if(Gear^.Hedgehog^.Gear = nil) or ((Gear^.Hedgehog^.Gear^.State and gstMoving) <> 0) then
            begin
            DeleteGear(Gear);
            AfterAttack;
            exit
            end
    else
        inc(Gear^.Timer);

        i := 200;
    repeat
        Gear^.X := Gear^.X + Gear^.dX;
        Gear^.Y := Gear^.Y + Gear^.dY;
        WorldWrap(Gear);
        CheckCollision(Gear);
        if (Gear^.State and gstCollision) <> 0 then
            begin
            Gear^.X := Gear^.X + Gear^.dX * 8;
            Gear^.Y := Gear^.Y + Gear^.dY * 8;
            ShotgunShot(Gear);
            Gear^.doStep := @doStepShotIdle;
            exit
            end;

        CheckGearDrowning(Gear);
        if (Gear^.State and gstDrowning) <> 0 then
            begin
            Gear^.doStep := @doStepShotIdle;
            exit
            end;
        dec(i)
    until i = 0;
    if (hwRound(Gear^.X) and LAND_WIDTH_MASK <> 0) or (hwRound(Gear^.Y) and LAND_HEIGHT_MASK <> 0) then
        Gear^.doStep := @doStepShotIdle
end;

////////////////////////////////////////////////////////////////////////////////
procedure spawnBulletTrail(Bullet: PGear; bulletX, bulletY: hwFloat);
var oX, oY: hwFloat;
    VGear: PVisualGear;
begin
    if Bullet^.PortalCounter = 0 then
        begin
        ox:= CurrentHedgehog^.Gear^.X + Int2hwFloat(GetLaunchX(CurrentHedgehog^.CurAmmoType, hwSign(CurrentHedgehog^.Gear^.dX), CurrentHedgehog^.Gear^.Angle));
        oy:= CurrentHedgehog^.Gear^.Y + Int2hwFloat(GetLaunchY(CurrentHedgehog^.CurAmmoType, CurrentHedgehog^.Gear^.Angle));
        end
    else
        begin
        ox:= Bullet^.Elasticity;
        oy:= Bullet^.Friction;
        end;

        // Bullet trail
        VGear := AddVisualGear(hwRound(ox), hwRound(oy), vgtLineTrail);

        if VGear <> nil then
            begin
            VGear^.X:= hwFloat2Float(ox);
            VGear^.Y:= hwFloat2Float(oy);
            VGear^.dX:= hwFloat2Float(bulletX);
            VGear^.dY:= hwFloat2Float(bulletY);

            // reached edge of land. assume infinite beam. Extend it way out past camera
            if (hwRound(bulletX) and LAND_WIDTH_MASK <> 0)
            or (hwRound(bulletY) and LAND_HEIGHT_MASK <> 0) then
                    // only extend if not under water
                    if not CheckCoordInWater(hwRound(bulletX), hwRound(bulletY)) then
                        begin
                        VGear^.dX := VGear^.dX + max(LAND_WIDTH,4096) * (VGear^.dX - VGear^.X);
                        VGear^.dY := VGear^.dY + max(LAND_WIDTH,4096) * (VGear^.dY - VGear^.Y);
                        end;

            VGear^.Timer := 200;
            end;
end;

procedure doStepBulletWork(Gear: PGear);
var
    i, x, y, iInit: LongWord;
    oX, oY, tX, tY, tDx, tDy: hwFloat;
    VGear: PVisualGear;
begin
    AllInactive := false;
    inc(Gear^.Timer);
    iInit := 80;
    i := iInit;
    oX := Gear^.X;
    oY := Gear^.Y;
    repeat
        Gear^.X := Gear^.X + Gear^.dX;
        Gear^.Y := Gear^.Y + Gear^.dY;
        tX:= Gear^.X;
        tY:= Gear^.Y;
        tDx:= Gear^.dX;
        tDy:= Gear^.dY;
        if (Gear^.PortalCounter < 30) and WorldWrap(Gear) then
            begin
            DrawTunnel(oX, oY, tDx, tDy, iInit + 2 - i, 1);
            SpawnBulletTrail(Gear, tX, tY);
            iInit:= i;
            oX:= Gear^.X;
            oY:= Gear^.Y;
            inc(Gear^.PortalCounter);
            Gear^.Elasticity:= Gear^.X;
            Gear^.Friction:= Gear^.Y;
            SpawnBulletTrail(Gear, Gear^.X, Gear^.Y);
            end;
        x := hwRound(Gear^.X);
        y := hwRound(Gear^.Y);

        if ((y and LAND_HEIGHT_MASK) = 0) and ((x and LAND_WIDTH_MASK) = 0) and (Land[y, x] <> 0) then
            inc(Gear^.Damage);
        // let's interrupt before a collision to give portals a chance to catch the bullet
        if (Gear^.Damage = 1) and (Gear^.Tag = 0) and (not CheckLandValue(x, y, lfLandMask)) then
            begin
            Gear^.Tag := 1;
            Gear^.Damage := 0;
            Gear^.X := Gear^.X - Gear^.dX;
            Gear^.Y := Gear^.Y - Gear^.dY;
            CheckGearDrowning(Gear);
            break;
            end
        else
            Gear^.Tag := 0;

        if Gear^.Damage > 5 then
            begin
            if Gear^.AmmoType = amDEagle then
                AmmoShove(Gear, Gear^.Boom, 20)
            else
                AmmoShove(Gear, Gear^.Timer * Gear^.Boom div 100000, 20);
            end;
        CheckGearDrowning(Gear);
        dec(i)
    until (i = 0) or (Gear^.Damage > Gear^.Health) or ((Gear^.State and gstDrowning) <> 0);

    if Gear^.Damage > 0 then
        begin
        DrawTunnel(oX, oY, Gear^.dX, Gear^.dY, iInit + 2 - i, 1);
        dec(Gear^.Health, Gear^.Damage);
        Gear^.Damage := 0
        end;

    if ((Gear^.State and gstDrowning) <> 0) and (Gear^.Health > 0) then
        begin
        // draw bubbles
        if (not SuddenDeathDmg and (WaterOpacity < $FF)) or (SuddenDeathDmg and (SDWaterOpacity < $FF)) then
            begin
            for i:=(Gear^.Health * 4) downto 0 do
                begin
                if Random(6) = 0 then
                    AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtBubble);
                Gear^.X := Gear^.X + Gear^.dX;
                Gear^.Y := Gear^.Y + Gear^.dY;
                end;
            end;
        // bullet dies underwater
        Gear^.Health:= 0;
        end;

    if (Gear^.Health <= 0)
        or (hwRound(Gear^.X) and LAND_WIDTH_MASK <> 0)
        or (hwRound(Gear^.Y) and LAND_HEIGHT_MASK <> 0) then
            begin
            if (Gear^.Kind = gtSniperRifleShot) then
                cLaserSightingSniper := false;
            if (Ammoz[Gear^.AmmoType].Ammo.NumPerTurn <= CurrentHedgehog^.MultiShootAttacks) and ((GameFlags and gfArtillery) = 0) then
                cArtillery := false;

        // Bullet Hit
            if ((Gear^.State and gstDrowning) = 0) and (hwRound(Gear^.X) and LAND_WIDTH_MASK = 0) and (hwRound(Gear^.Y) and LAND_HEIGHT_MASK = 0) then
                begin
                VGear := AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtBulletHit);
                if VGear <> nil then
                    begin
                    VGear^.Angle := DxDy2Angle(-Gear^.dX, Gear^.dY);
                    end;
                end;

            spawnBulletTrail(Gear, Gear^.X, Gear^.Y);
            Gear^.doStep := @doStepShotIdle
            end;
end;

procedure doStepDEagleShot(Gear: PGear);
begin
    Gear^.Data:= nil;
    // remember who fired this
    if (Gear^.Hedgehog <> nil) and (Gear^.Hedgehog^.Gear <> nil) then
        Gear^.Data:= Pointer(Gear^.Hedgehog^.Gear);

    PlaySound(sndGun);
    // add 2 initial steps to avoid problem with ammoshove related to calculation of radius + 1 radius as gear widths, and also just plain old weird angles
    Gear^.X := Gear^.X + Gear^.dX * 2;
    Gear^.Y := Gear^.Y + Gear^.dY * 2;
    Gear^.doStep := @doStepBulletWork
end;

procedure doStepSniperRifleShot(Gear: PGear);
var
    HHGear: PGear;
    shell: PVisualGear;
begin

    cArtillery := true;
    HHGear := Gear^.Hedgehog^.Gear;

    if HHGear = nil then
        begin
        DeleteGear(gear);
        exit
        end;

    // remember who fired this
    Gear^.Data:= Pointer(Gear^.Hedgehog^.Gear);

    HHGear^.State := HHGear^.State or gstNotKickable;
    HedgehogChAngle(HHGear);
    if cLaserSightingSniper = false then
        // Turn sniper's laser sight on and give it a chance to aim
        begin
        cLaserSightingSniper := true;
        HHGear^.Message := 0;
        if (HHGear^.Angle >= 32) then
            dec(HHGear^.Angle,32)
        end;

    if (HHGear^.Message and gmAttack) <> 0 then
        begin
        shell := AddVisualGear(hwRound(Gear^.x), hwRound(Gear^.y), vgtShell);
        if shell <> nil then
            begin
            shell^.dX := gear^.dX.QWordValue / -8589934592;
            shell^.dY := gear^.dY.QWordValue / -8589934592;
            shell^.Frame := 1
            end;
        Gear^.State := Gear^.State or gstAnimation;
        Gear^.dX := SignAs(AngleSin(HHGear^.Angle), HHGear^.dX) * _0_5;
        Gear^.dY := -AngleCos(HHGear^.Angle) * _0_5;
        PlaySound(sndGun);
        // add 2 initial steps to avoid problem with ammoshove related to calculation of radius + 1 radius as gear widths, and also just weird angles
        Gear^.X := Gear^.X + Gear^.dX * 2;
        Gear^.Y := Gear^.Y + Gear^.dY * 2;
        Gear^.doStep := @doStepBulletWork;
        end
    else
        if (GameTicks mod 32) = 0 then
            if (GameTicks mod 4096) < 2048 then
                begin
                if (HHGear^.Angle + 1 <= cMaxAngle) then
                    inc(HHGear^.Angle)
                end
    else
        if (HHGear^.Angle >= 1) then
            dec(HHGear^.Angle);

    if (TurnTimeLeft = 0) then
        begin
        HHGear^.State := HHGear^.State and (not gstNotKickable);
        DeleteGear(Gear);
        AfterAttack
        end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepActionTimer(Gear: PGear);
begin
dec(Gear^.Timer);
case Gear^.Kind of
    gtATStartGame:
        begin
        AllInactive := false;
        if Gear^.Timer = 0 then
            begin
            AddCaption(GetEventString(eidRoundStart), cWhiteColor, capgrpGameState);
            end
        end;
    gtATFinishGame:
        begin
        AllInactive := false;
        if Gear^.Timer = 1000 then
            begin
            ScreenFade := sfToBlack;
            ScreenFadeValue := 0;
            ScreenFadeSpeed := 1;
            end;
        if Gear^.Timer = 0 then
            begin
            SendIPC(_S'N');
            SendIPC(_S'q');
            GameState := gsExit
            end
        end;
    end;
if Gear^.Timer = 0 then
    DeleteGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepPickHammerWork(Gear: PGear);
var
    i, ei, x, y: LongInt;
    HHGear: PGear;
begin
    AllInactive := false;
    WorldWrap(Gear);
    HHGear := Gear^.Hedgehog^.Gear;
    dec(Gear^.Timer);
    if (TurnTimeLeft = 0) or (Gear^.Timer = 0)
    or((Gear^.Message and gmDestroy) <> 0)
    or((HHGear^.State and gstHHDriven) =0) then
        begin
        StopSoundChan(Gear^.SoundChannel);
        DeleteGear(Gear);
        AfterAttack;
        doStepHedgehogMoving(HHGear);  // for gfInfAttack
        exit
        end;

    x:= hwRound(Gear^.X);
    y:= hwRound(Gear^.Y);
    if (Gear^.Timer mod 33) = 0 then
        begin
        HHGear^.State := HHGear^.State or gstNoDamage;
        doMakeExplosion(x, y + 7, Gear^.Boom, Gear^.Hedgehog, EXPLDontDraw);
        HHGear^.State := HHGear^.State and (not gstNoDamage)
        end;

    if (Gear^.Timer mod 47) = 0 then
        begin
        // ok. this was an attempt to turn off dust if not actually drilling land.  I have no idea why it isn't working as expected
        if (( (y + 12) and LAND_HEIGHT_MASK) = 0) and ((x and LAND_WIDTH_MASK) = 0) and (Land[y + 12, x] > 255) then
            for i:= 0 to 1 do
                AddVisualGear(x - 5 + Random(10), y + 12, vgtDust);

        i := x - Gear^.Radius - LongInt(GetRandom(2));
        ei := x + Gear^.Radius + LongInt(GetRandom(2));
        while i <= ei do
            begin
            DrawExplosion(i, y + 3, 3);
            inc(i, 1)
            end;

        if CheckLandValue(hwRound(Gear^.X + Gear^.dX + SignAs(_6,Gear^.dX)), hwRound(Gear^.Y + _1_9), lfIndestructible) then
            begin
            Gear^.X := Gear^.X + Gear^.dX;
            Gear^.Y := Gear^.Y + _1_9;
            end;
        SetAllHHToActive;
        end;
    if TestCollisionYwithGear(Gear, 1) <> 0 then
        begin
        Gear^.dY := _0;
        SetLittle(HHGear^.dX);
        HHGear^.dY := _0;
        end
    else if Gear^.dY.isNegative and (TestCollisionYwithGear(HHGear, -1) <> 0) then
        begin
        Gear^.dY := cGravity;
        HHGear^.dY := cGravity;
        end
    else
        begin
        if CheckLandValue(hwRound(Gear^.X), hwRound(Gear^.Y + Gear^.dY + cGravity), lfLandMask) then
            begin
            Gear^.dY := Gear^.dY + cGravity;
            Gear^.Y := Gear^.Y + Gear^.dY
            end;
        if hwRound(Gear^.Y) > cWaterLine then
            Gear^.Timer := 1
        end;

    Gear^.X := Gear^.X + HHGear^.dX;
    if CheckLandValue(hwRound(Gear^.X), hwRound(Gear^.Y)-cHHRadius, lfLandMask) then
        begin
        HHGear^.X := Gear^.X;
        HHGear^.Y := Gear^.Y - int2hwFloat(cHHRadius)
        end;

    if (Gear^.Message and gmAttack) <> 0 then
        if (Gear^.State and gsttmpFlag) <> 0 then
            Gear^.Timer := 1
    else //there would be a mistake.
    else
        if (Gear^.State and gsttmpFlag) = 0 then
            Gear^.State := Gear^.State or gsttmpFlag;
    if ((Gear^.Message and gmLeft) <> 0) then
        Gear^.dX := - _0_3
    else
        if ((Gear^.Message and gmRight) <> 0) then
            Gear^.dX := _0_3
    else Gear^.dX := _0;
end;

procedure doStepPickHammer(Gear: PGear);
var
    i, y: LongInt;
    ar: TRangeArray;
    HHGear: PGear;
begin
    i := 0;
    HHGear := Gear^.Hedgehog^.Gear;

    y := hwRound(Gear^.Y) - cHHRadius * 2;
    while y < hwRound(Gear^.Y) do
        begin
        ar[i].Left := hwRound(Gear^.X) - Gear^.Radius - LongInt(GetRandom(2));
        ar[i].Right := hwRound(Gear^.X) + Gear^.Radius + LongInt(GetRandom(2));
        inc(y, 2);
        inc(i)
        end;

    DrawHLinesExplosions(@ar, 3, hwRound(Gear^.Y) - cHHRadius * 2, 2, Pred(i));
    Gear^.dY := HHGear^.dY;
    DeleteCI(HHGear);

    Gear^.SoundChannel := LoopSound(sndPickhammer);
    doStepPickHammerWork(Gear);
    Gear^.doStep := @doStepPickHammerWork
end;

////////////////////////////////////////////////////////////////////////////////
var
    BTPrevAngle, BTSteps: LongInt;

procedure doStepBlowTorchWork(Gear: PGear);
var
    HHGear: PGear;
    b: boolean;
    prevX: LongInt;
begin
    AllInactive := false;
    WorldWrap(Gear);
    dec(Gear^.Timer);

    if Gear^.Hedgehog^.Gear = nil then
        begin
        StopSoundChan(Gear^.SoundChannel);
        DeleteGear(Gear);
        AfterAttack;
        exit
        end;

    HHGear := Gear^.Hedgehog^.Gear;

    HedgehogChAngle(HHGear);

    b := false;

    if abs(LongInt(HHGear^.Angle) - BTPrevAngle) > 7  then
        begin
        Gear^.dX := SignAs(AngleSin(HHGear^.Angle) * _0_5, Gear^.dX);
        Gear^.dY := AngleCos(HHGear^.Angle) * ( - _0_5);
        BTPrevAngle := HHGear^.Angle;
        b := true
        end;

    if ((HHGear^.State and gstMoving) <> 0) then
        begin
        doStepHedgehogMoving(HHGear);
        if (HHGear^.State and gstHHDriven) = 0 then
            Gear^.Timer := 0
        end;

    if Gear^.Timer mod cHHStepTicks = 0 then
        begin
        b := true;
        if Gear^.dX.isNegative then
            HHGear^.Message := (HHGear^.Message and (gmAttack or gmUp or gmDown)) or gmLeft
        else
            HHGear^.Message := (HHGear^.Message and (gmAttack or gmUp or gmDown)) or gmRight;

        if ((HHGear^.State and gstMoving) = 0) then
            begin
            HHGear^.State := HHGear^.State and (not gstAttacking);
            prevX := hwRound(HHGear^.X);

            // why the call to HedgehogStep then a further increment of X?
            if (prevX = hwRound(HHGear^.X)) and
               CheckLandValue(hwRound(HHGear^.X + SignAs(_6, HHGear^.dX)), hwRound(HHGear^.Y),
               lfIndestructible) then HedgehogStep(HHGear);

            if (prevX = hwRound(HHGear^.X)) and
               CheckLandValue(hwRound(HHGear^.X + SignAs(_6, HHGear^.dX)), hwRound(HHGear^.Y),
               lfIndestructible) then HHGear^.X := HHGear^.X + SignAs(_1, HHGear^.dX);
            HHGear^.State := HHGear^.State or gstAttacking
            end;

        inc(BTSteps);
        if BTSteps = 7 then
            begin
            BTSteps := 0;
            if CheckLandValue(hwRound(HHGear^.X + Gear^.dX * (cHHRadius + cBlowTorchC) + SignAs(_6,Gear^.dX)), hwRound(HHGear^.Y + Gear^.dY * (cHHRadius + cBlowTorchC)),lfIndestructible) then
                begin
                Gear^.X := HHGear^.X + Gear^.dX * (cHHRadius + cBlowTorchC);
                Gear^.Y := HHGear^.Y + Gear^.dY * (cHHRadius + cBlowTorchC);
                end;
            HHGear^.State := HHGear^.State or gstNoDamage;
            AmmoShove(Gear, Gear^.Boom, 15);
            HHGear^.State := HHGear^.State and (not gstNoDamage)
            end;
        end;

    if b then
        begin
        DrawTunnel(HHGear^.X + Gear^.dX * cHHRadius,
        HHGear^.Y + Gear^.dY * cHHRadius - _1 -
        ((hwAbs(Gear^.dX) / (hwAbs(Gear^.dX) + hwAbs(Gear^.dY))) * _0_5 * 7),
        Gear^.dX, Gear^.dY,
        cHHStepTicks, cHHRadius * 2 + 7);
        end;

    if (TurnTimeLeft = 0) or (Gear^.Timer = 0)
    or ((HHGear^.Message and gmAttack) <> 0) then
        begin
        StopSoundChan(Gear^.SoundChannel);
        HHGear^.Message := 0;
        HHGear^.State := HHGear^.State and (not gstNotKickable);
        DeleteGear(Gear);
        AfterAttack
        end
end;

procedure doStepBlowTorch(Gear: PGear);
var
    HHGear: PGear;
begin
    BTPrevAngle := High(LongInt);
    BTSteps := 0;
    HHGear := Gear^.Hedgehog^.Gear;
    HedgehogChAngle(HHGear);
    Gear^.dX := SignAs(AngleSin(HHGear^.Angle) * _0_5, Gear^.dX);
    Gear^.dY := AngleCos(HHGear^.Angle) * ( - _0_5);
    DrawTunnel(HHGear^.X,
        HHGear^.Y + Gear^.dY * cHHRadius - _1 -
        ((hwAbs(Gear^.dX) / (hwAbs(Gear^.dX) + hwAbs(Gear^.dY))) * _0_5 * 7),
        Gear^.dX, Gear^.dY,
        cHHStepTicks, cHHRadius * 2 + 7);
    HHGear^.Message := 0;
    HHGear^.State := HHGear^.State or gstNotKickable;
    Gear^.SoundChannel := LoopSound(sndBlowTorch);
    Gear^.doStep := @doStepBlowTorchWork
end;


////////////////////////////////////////////////////////////////////////////////
procedure doStepMine(Gear: PGear);
var vg: PVisualGear;
    dxdy: hwFloat;
    dmg: LongWord;
begin
    if Gear^.Health = 0 then dxdy:= hwAbs(Gear^.dX)+hwAbs(Gear^.dY);
    if (Gear^.State and gstMoving) <> 0 then
        begin
        DeleteCI(Gear);
        doStepFallingGear(Gear);
        if (Gear^.State and gstMoving) = 0 then
            begin
            AddCI(Gear);
            Gear^.dX := _0;
            Gear^.dY := _0
            end;
        CalcRotationDirAngle(Gear);
        AllInactive := false
        end
    else if (GameTicks and $3F) = 25 then
        doStepFallingGear(Gear);
    if (Gear^.Health = 0) then
        begin
        if (dxdy > _0_4) and (Gear^.State and gstCollision <> 0) then
            begin
            dmg:= hwRound(dxdy * _50);
            inc(Gear^.Damage, dmg);
            ScriptCall('onGearDamage', Gear^.UID, dmg)
            end;

        if ((GameTicks and $FF) = 0) and (Gear^.Damage > random(30)) then
            begin
            vg:= AddVisualGear(hwRound(Gear^.X) - 4  + Random(8), hwRound(Gear^.Y) - 4 - Random(4), vgtSmoke);
            if vg <> nil then
                vg^.Scale:= 0.5
            end;

        if (Gear^.Damage > 35) then
            begin
            doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
            DeleteGear(Gear);
            exit
            end
        end;

    if ((Gear^.State and gsttmpFlag) <> 0) and (Gear^.Health <> 0) then
        if ((Gear^.State and gstAttacking) = 0) then
            begin
            if ((GameTicks and $1F) = 0) then
                if CheckGearNear(Gear, gtHedgehog, 46, 32) <> nil then
                    Gear^.State := Gear^.State or gstAttacking
            end
        else // gstAttacking <> 0
            begin
            AllInactive := false;
            // tag of 1 means this mine has a random timer
            if (Gear^.Tag = 1) and (Gear^.Timer = 0) then
                begin
                if (GameTicks mod 2 = 0) then GetRandom(2);
                if (GameTicks mod 3 = 0) then GetRandom(2);
                Gear^.Timer:= GetRandom(51) * 100;
                Gear^.Tag:= 0;
                end;
            if (Gear^.Timer and $FF) = 0 then
                PlaySound(sndMineTick);
            if Gear^.Timer = 0 then
                begin
                if ((Gear^.State and gstWait) <> 0)
                or (cMineDudPercent = 0)
                or (getRandom(100) > cMineDudPercent) then
                    begin
                    doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
                    DeleteGear(Gear)
                    end
                else
                    begin
                    vg:= AddVisualGear(hwRound(Gear^.X) - 4  + Random(8), hwRound(Gear^.Y) - 4 - Random(4), vgtSmoke);
                    if vg <> nil then
                        vg^.Scale:= 0.5;
                    PlaySound(sndVaporize);
                    Gear^.Health := 0;
                    Gear^.Damage := 0;
                    Gear^.State := Gear^.State and (not gstAttacking)
                    end;
                exit
                end;
            dec(Gear^.Timer);
            end
    else // gsttmpFlag = 0
        if (TurnTimeLeft = 0)
        or ((GameFlags and gfInfAttack <> 0) and (GameTicks > Gear^.FlightTime))
        or (Gear^.Hedgehog^.Gear = nil) then
            Gear^.State := Gear^.State or gsttmpFlag;
end;

procedure doStepAirMine(Gear: PGear);
var i,t,targDist,tmpDist: LongWord;
    targ, tmpG: PGear;
    trackSpeed, airFriction, tX, tY: hwFloat;
    isUnderwater: Boolean;
begin
    isUnderwater:= CheckCoordInWater(hwRound(Gear^.X), hwRound(Gear^.Y) + Gear^.Radius);
    if Gear^.Pos > 0 then
        begin
        airFriction:= _1;
        if isUnderwater then
            dec(airFriction.QWordValue,Gear^.Pos*2)
        else
            dec(airFriction.QWordValue,Gear^.Pos);
        Gear^.dX:= Gear^.dX*airFriction;
        Gear^.dY:= Gear^.dY*airFriction
        end;
    doStepFallingGear(Gear);
    if (TurnTimeLeft = 0) and ((Gear^.dX.QWordValue + Gear^.dY.QWordValue) > _0_02.QWordValue) then
        AllInactive := false;

    if (TurnTimeLeft = 0) or (Gear^.Angle = 0) or (Gear^.Hedgehog = nil) or (Gear^.Hedgehog^.Gear = nil) then
        begin
        Gear^.Hedgehog:= nil;
        targ:= nil;
        end
    else if Gear^.Hedgehog <> nil then
        targ:= Gear^.Hedgehog^.Gear;
    if targ <> nil then
        begin
        tX:=Gear^.X-targ^.X;
        tY:=Gear^.Y-targ^.Y;
        // allow escaping - should maybe flag this too
        if (GameTicks > Gear^.FlightTime+10000) or 
            ((tX.Round+tY.Round > Gear^.Angle*6) and
            (hwRound(hwSqr(tX) + hwSqr(tY)) > sqr(Gear^.Angle*6))) then
            targ:= nil
        end;

    // If in ready timer, or after turn, or in first 5 seconds of turn (really a window due to extra time utility)
    // or mine is inactive due to lack of gsttmpflag or hunting is disabled due to seek radius of 0
    // then we aren't hunting
    if (ReadyTimeLeft > 0) or (TurnTimeLeft = 0) or 
        ((TurnTimeLeft < cHedgehogTurnTime) and (cHedgehogTurnTime-TurnTimeLeft < 5000)) or
        (Gear^.State and gsttmpFlag = 0) or
        (Gear^.Angle = 0) then
        gear^.State:= gear^.State and (not gstChooseTarget)
    else if
    // todo, allow not finding new target, set timeout on target retention
        (Gear^.State and gstAttacking = 0) and
        ((GameTicks and $FF) = 17) and
        (GameTicks > Gear^.FlightTime) then // recheck hunted hog
        begin
        gear^.State:= gear^.State or gstChooseTarget;
        if targ <> nil then
             targDist:= Distance(Gear^.X-targ^.X,Gear^.Y-targ^.Y).Round
        else targDist:= 0;
        for t:= 0 to Pred(TeamsCount) do
            with TeamsArray[t]^ do
                for i:= 0 to cMaxHHIndex do
                    if Hedgehogs[i].Gear <> nil then
                        begin
                        tmpG:= Hedgehogs[i].Gear;
                        tX:=Gear^.X-tmpG^.X;
                        tY:=Gear^.Y-tmpG^.Y;
                        if (Gear^.Angle = $FFFFFFFF) or
                            ((tX.Round+tY.Round < Gear^.Angle) and
                            (hwRound(hwSqr(tX) + hwSqr(tY)) < sqr(Gear^.Angle))) then
                            begin
                            if targ <> nil then tmpDist:= Distance(tX,tY).Round;
                            if (targ = nil) or (tmpDist < targDist) then
                                begin
                                if targ = nil then targDist:= Distance(tX,tY).Round
                                else targDist:= tmpDist;
                                Gear^.Hedgehog:= @Hedgehogs[i];
                                targ:= tmpG;
                                end
                            end
                        end;
        if targ <> nil then Gear^.FlightTime:= GameTicks + 5000
        end;
    if targ <> nil then
        begin
        trackSpeed:= _0;
        if isUnderwater then
            trackSpeed.QWordValue:= Gear^.Power div 2
        else
            trackSpeed.QWordValue:= Gear^.Power;
        if (Gear^.X < targ^.X) and (Gear^.dX < _0_1)  then
             Gear^.dX:= Gear^.dX+trackSpeed // please leave as an add.  I like the effect
        else if (Gear^.X > targ^.X) and (Gear^.dX > -_0_1) then
            Gear^.dX:= Gear^.dX-trackSpeed;
        if (Gear^.Y < targ^.Y) and (Gear^.dY < _0_1)  then
             Gear^.dY:= Gear^.dY+trackSpeed
        else if (Gear^.Y > targ^.Y) and (Gear^.dY > -_0_1) then
            Gear^.dY:= Gear^.dY-trackSpeed
        end
    else Gear^.Hedgehog:= nil;

    if ((Gear^.State and gsttmpFlag) <> 0) and (Gear^.Health <> 0) then
        begin
        if ((Gear^.State and gstAttacking) = 0) then
            begin
            if ((GameTicks and $1F) = 0) then
                begin
                if targ <> nil then
                    begin
                    tX:=Gear^.X-targ^.X;
                    tY:=Gear^.Y-targ^.Y;
                    if (tX.Round+tY.Round < Gear^.Karma) and
                       (hwRound(hwSqr(tX) + hwSqr(tY)) < sqr(Gear^.Karma)) then
                    Gear^.State := Gear^.State or gstAttacking
                    end
                else if (Gear^.Angle > 0) and (CheckGearNear(Gear, gtHedgehog, Gear^.Karma, Gear^.Karma) <> nil) then
                    Gear^.State := Gear^.State or gstAttacking
                end
            end
        else // gstAttacking <> 0
            begin
            AllInactive := false;
            if (Gear^.Timer and $FF) = 0 then
                PlaySound(sndMineTick);
            if Gear^.Timer = 0 then
                begin
                // recheck
                if targ <> nil then
                    begin
                    tX:=Gear^.X-targ^.X;
                    tY:=Gear^.Y-targ^.Y;
                    if (tX.Round+tY.Round < Gear^.Karma) and
                       (hwRound(hwSqr(tX) + hwSqr(tY)) < sqr(Gear^.Karma)) then
                        begin
                        Gear^.Hedgehog:= CurrentHedgehog;
                        tmpG:= FollowGear;
                        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Karma, Gear^.Hedgehog, EXPLAutoSound);
                        FollowGear:= tmpG;
                        DeleteGear(Gear);
                        exit
                        end
                    end
                else if (Gear^.Angle > 0) and (CheckGearNear(Gear, gtHedgehog, Gear^.Karma, Gear^.Karma) <> nil) then
                    begin
                    Gear^.Hedgehog:= CurrentHedgehog;
                    doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Karma, Gear^.Hedgehog, EXPLAutoSound);
                    DeleteGear(Gear);
                    exit
                    end;
                Gear^.State:= Gear^.State and (not gstAttacking);
                Gear^.Timer:= Gear^.WDTimer
                end;
            if Gear^.Timer > 0 then
                dec(Gear^.Timer);
            end
        end
    else // gsttmpFlag = 0
        if (TurnTimeLeft = 0)
        or ((GameFlags and gfInfAttack <> 0) and (GameTicks > Gear^.FlightTime))
        or (CurrentHedgehog^.Gear = nil) then
        begin
        Gear^.FlightTime:= GameTicks;
        Gear^.State := Gear^.State or gsttmpFlag
        end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSMine(Gear: PGear);
    var land: Word;
begin
    // TODO: do real calculation?
    land:= TestCollisionXwithGear(Gear, 2);
    if land = 0 then land:= TestCollisionYwithGear(Gear,-2);
    if land = 0 then land:= TestCollisionXwithGear(Gear,-2);
    if land = 0 then land:= TestCollisionYwithGear(Gear, 2);
    if (land <> 0) and ((land and lfBouncy = 0) or ((Gear^.State and gstMoving) = 0)) then
        begin
        if ((Gear^.State and gstMoving) <> 0) or (not isZero(Gear^.dX)) or (not isZero(Gear^.dY)) then
            begin
            PlaySound(sndRopeAttach);
            Gear^.dX:= _0;
            Gear^.dY:= _0;
            Gear^.State:= Gear^.State and (not gstMoving);
            AddCI(Gear);
            end;
        end
    else
        begin
        Gear^.State:= Gear^.State or gstMoving;
        DeleteCI(Gear);
        doStepFallingGear(Gear);
        AllInactive := false;
        CalcRotationDirAngle(Gear);
        end;

    if ((Gear^.State and gsttmpFlag) <> 0) and (Gear^.Health <> 0) then
        begin
        if ((Gear^.State and gstAttacking) = 0) and ((Gear^.State and gstFrozen) = 0) then
            begin
            if ((GameTicks and $1F) = 0) then
// FIXME - values taken from mine.  use a gear val and set both to same
               if CheckGearNear(Gear, gtHedgehog, 46, 32) <> nil then
                    Gear^.State := Gear^.State or gstAttacking
            end
        else if (Gear^.State and gstFrozen) = 0 then // gstAttacking <> 0
            begin
            AllInactive := false;
            if Gear^.Timer = 0 then
                begin
                doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
                DeleteGear(Gear);
                exit
                end
            else
                if (Gear^.Timer and $FF) = 0 then
                    PlaySound(sndMineTick);
                dec(Gear^.Timer);
                end
            end
    else // gsttmpFlag = 0
        if ((GameFlags and gfInfAttack = 0) and ((TurnTimeLeft = 0) or (Gear^.Hedgehog^.Gear = nil)))
        or ((GameFlags and gfInfAttack <> 0) and (GameTicks > Gear^.FlightTime)) then
            Gear^.State := Gear^.State or gsttmpFlag;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepDynamite(Gear: PGear);
begin
    doStepFallingGear(Gear);
    AllInactive := false;

    if Gear^.Timer mod 166 = 0 then
        inc(Gear^.Tag);
    if Gear^.Timer = 1000 then // might need better timing
        makeHogsWorry(Gear^.X, Gear^.Y, 75);
    if Gear^.Timer = 0 then
        begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
        DeleteGear(Gear);
        exit
        end;
    dec(Gear^.Timer);
end;

///////////////////////////////////////////////////////////////////////////////

procedure doStepRollingBarrel(Gear: PGear);
var
    i, dmg: LongInt;
    particle: PVisualGear;
    dxdy: hwFloat;
begin
    if (Gear^.dX.QWordValue = 0) and (Gear^.dY.QWordValue = 0) and (TestCollisionYwithGear(Gear, 1) = 0) then
        SetLittle(Gear^.dY);
    Gear^.State := Gear^.State or gstAnimation;
    if Gear^.Health < cBarrelHealth then Gear^.State:= Gear^.State and (not gstFrozen);

    if ((Gear^.dX.QWordValue <> 0)
    or (Gear^.dY.QWordValue <> 0))  then
        begin
        DeleteCI(Gear);
        AllInactive := false;
        dxdy:= hwAbs(Gear^.dX)+hwAbs(Gear^.dY);
        doStepFallingGear(Gear);
        if (Gear^.State and gstCollision <> 0) and(dxdy > _0_4) then
            begin
            if (TestCollisionYwithGear(Gear, 1) <> 0) then
                begin
                Gear^.State := Gear^.State or gsttmpFlag;
                for i:= min(12, hwRound(dxdy*_10)) downto 0 do
                    begin
                    particle := AddVisualGear(hwRound(Gear^.X) - 5 + Random(10), hwRound(Gear^.Y) + 12,vgtDust);
                    if particle <> nil then
                        particle^.dX := particle^.dX + (Gear^.dX.QWordValue / 21474836480)
                    end
                end;
            dmg:= hwRound(dxdy * _50);
            inc(Gear^.Damage, dmg);
            ScriptCall('onGearDamage', Gear^.UID, dmg)
            end;
        CalcRotationDirAngle(Gear);
        //CheckGearDrowning(Gear)
        end
    else
        begin
        Gear^.State := Gear^.State or gsttmpFlag;
        AddCI(Gear)
        end;

(*
Attempt to make a barrel knock itself over an edge.  Would need more checks to avoid issues like burn damage
    begin
    x:= hwRound(Gear^.X);
    y:= hwRound(Gear^.Y);
    if (((y+1) and LAND_HEIGHT_MASK) = 0) and ((x and LAND_WIDTH_MASK) = 0) then
        if (Land[y+1, x] = 0) then
            begin
            if (((y+1) and LAND_HEIGHT_MASK) = 0) and (((x+Gear^.Radius-2) and LAND_WIDTH_MASK) = 0) and (Land[y+1, x+Gear^.Radius-2] = 0) then
                Gear^.dX:= -_0_08
            else if (((y+1 and LAND_HEIGHT_MASK)) = 0) and (((x-(Gear^.Radius-2)) and LAND_WIDTH_MASK) = 0) and (Land[y+1, x-(Gear^.Radius-2)] = 0) then
                Gear^.dX:= _0_08;
            end;
    if Gear^.dX.QWordValue = 0 then AddCI(Gear)
    end; *)

    if not Gear^.dY.isNegative and (Gear^.dY < _0_001) and (TestCollisionYwithGear(Gear, 1) <> 0) then
        Gear^.dY := _0;
    if hwAbs(Gear^.dX) < _0_001 then
        Gear^.dX := _0;

    if (Gear^.Health > 0) and ((Gear^.Health * 100 div cBarrelHealth) < random(90)) and ((GameTicks and $FF) = 0) then
        if (cBarrelHealth div Gear^.Health) > 2 then
            AddVisualGear(hwRound(Gear^.X) - 16 + Random(32), hwRound(Gear^.Y) - 2, vgtSmoke)
    else
        AddVisualGear(hwRound(Gear^.X) - 16 + Random(32), hwRound(Gear^.Y) - 2, vgtSmokeWhite);
    dec(Gear^.Health, Gear^.Damage);
    Gear^.Damage := 0;
    if Gear^.Health <= 0 then
        doStepCase(Gear);
end;

procedure doStepCase(Gear: PGear);
var
    i, x, y: LongInt;
    k: TGearType;
    dX, dY: HWFloat;
    hog: PHedgehog;
    sparkles: PVisualGear;
begin
    k := Gear^.Kind;

    if (Gear^.Message and gmDestroy) > 0 then
        begin
        DeleteGear(Gear);
        FreeActionsList;
        SetAllToActive;
        // something (hh, mine, etc...) could be on top of the case
        with CurrentHedgehog^ do
            if Gear <> nil then
                Gear^.Message := Gear^.Message and (not (gmLJump or gmHJump));
        exit
        end;
    if (k = gtExplosives) and (Gear^.Health < cBarrelHealth) then Gear^.State:= Gear^.State and (not gstFrozen);

    if ((k <> gtExplosives) and (Gear^.Damage > 0)) or ((k = gtExplosives) and (Gear^.Health<=0)) then
        begin
        x := hwRound(Gear^.X);
        y := hwRound(Gear^.Y);
        hog:= Gear^.Hedgehog;

        DeleteGear(Gear);
        // <-- delete gear!

        if k = gtCase then
            begin
            doMakeExplosion(x, y, Gear^.Boom, hog, EXPLAutoSound);
            for i:= 0 to 63 do
                AddGear(x, y, gtFlame, 0, _0, _0, 0);
            end
        else if k = gtTarget then
            uStats.TargetHit()
        else if k = gtExplosives then
                begin
                doMakeExplosion(x, y, Gear^.Boom, hog, EXPLAutoSound);
                for i:= 0 to 31 do
                    begin
                    dX := AngleCos(i * 64) * _0_5 * (getrandomf + _1);
                    dY := AngleSin(i * 64) * _0_5 * (getrandomf + _1);
                    AddGear(x, y, gtFlame, 0, dX, dY, 0);
                    AddGear(x, y, gtFlame, gstTmpFlag, -dX, -dY, 0);
                    end
                end;
            exit
        end;

    if k = gtExplosives then
        begin
        //if V > _0_03 then Gear^.State:= Gear^.State or gstAnimation;
        if (hwAbs(Gear^.dX) > _0_15) or ((hwAbs(Gear^.dY) > _0_15) and (hwAbs(Gear^.dX) > _0_02)) then
            begin
            Gear^.doStep := @doStepRollingBarrel;
            exit;
            end
        else Gear^.dX:= _0;

        if ((Gear^.Health * 100 div cBarrelHealth) < random(90)) and ((GameTicks and $FF) = 0) then
            if (cBarrelHealth div Gear^.Health) > 2 then
                AddVisualGear(hwRound(Gear^.X) - 16 + Random(32), hwRound(Gear^.Y) - 2, vgtSmoke)
            else
                AddVisualGear(hwRound(Gear^.X) - 16 + Random(32), hwRound(Gear^.Y) - 2, vgtSmokeWhite);
        dec(Gear^.Health, Gear^.Damage);
        Gear^.Damage := 0;
        end
    else
        begin
        if Gear^.Timer = 500 then
            begin
(* Can't make sparkles team coloured without working out what the next team is going to be. This should be solved, really, since it also screws up
   voices. Reinforcements voices is heard for active team, not team-to-be.  Either that or change crate spawn from end of turn to start, although that
   has its own complexities. *)
            // Abuse a couple of gear values to track origin
            Gear^.Angle:= hwRound(Gear^.Y);
            Gear^.Tag:= random(2);
            inc(Gear^.Timer)
            end;
        if Gear^.Timer < 1833 then inc(Gear^.Timer);
        if Gear^.Timer = 1000 then
            begin
            sparkles:= AddVisualGear(hwRound(Gear^.X), Gear^.Angle, vgtDust, 1);
            if sparkles <> nil then
                begin
                sparkles^.dX:= 0;
                sparkles^.dY:= 0;
                sparkles^.Angle:= 270;
                if Gear^.Tag = 1 then
                    sparkles^.Tint:= $3744D7FF
                else sparkles^.Tint:= $FAB22CFF
                end;
            end;
        if Gear^.Timer < 1000 then
            begin
            AllInactive:= false;
            exit
            end
        end;


    if (Gear^.dY.QWordValue <> 0)
    or (TestCollisionYwithGear(Gear, 1) = 0) then
        begin
        AllInactive := false;

        Gear^.dY := Gear^.dY + cGravity;

        if ((not Gear^.dY.isNegative) and (TestCollisionYwithGear(Gear, 1) <> 0)) or
           (Gear^.dY.isNegative and (TestCollisionYwithGear(Gear, -1) <> 0)) then
             Gear^.dY := _0
        else Gear^.Y := Gear^.Y + Gear^.dY;

        if (not Gear^.dY.isNegative) and (Gear^.dY > _0_001) then
            SetAllHHToActive(false);

        if (not Gear^.dY.isNegative) and (TestCollisionYwithGear(Gear, 1) <> 0) then
            begin
            if (Gear^.dY > _0_2) and (k = gtExplosives) then
                inc(Gear^.Damage, hwRound(Gear^.dY * _70));

            if Gear^.dY > _0_2 then
                for i:= min(12, hwRound(Gear^.dY*_10)) downto 0 do
                    AddVisualGear(hwRound(Gear^.X) - 5 + Random(10), hwRound(Gear^.Y) + 12, vgtDust);

            Gear^.dY := - Gear^.dY * Gear^.Elasticity;
            if Gear^.dY > - _0_001 then
                Gear^.dY := _0
            else if Gear^.dY < - _0_03 then
                PlaySound(Gear^.ImpactSound);
            end;
        //if Gear^.dY > - _0_001 then Gear^.dY:= _0
        CheckGearDrowning(Gear);
        end;

    if (Gear^.dY.QWordValue = 0) then
        AddCI(Gear)
    else if (Gear^.dY.QWordValue <> 0) then
        DeleteCI(Gear)
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepTarget(Gear: PGear);
begin
    if (Gear^.Timer = 0) and (Gear^.Tag = 0) then
        begin
        PlaySound(sndWarp);
        // workaround: save spawn Y for doStepCase (which is a mess atm)
        Gear^.Angle:= hwRound(Gear^.Y);
        end;

    if (Gear^.Tag = 0) and (Gear^.Timer < 1000) then
        inc(Gear^.Timer)
    else if Gear^.Tag = 1 then
        Gear^.Tag := 2
    else if Gear^.Tag = 2 then
            if Gear^.Timer > 0 then
                dec(Gear^.Timer)
    else
        begin
        DeleteGear(Gear);
        exit;
        end;

    doStepCase(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepIdle(Gear: PGear);
begin
    AllInactive := false;
    dec(Gear^.Timer);
    if Gear^.Timer = 0 then
        begin
        DeleteGear(Gear);
        AfterAttack
        end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepShover(Gear: PGear);
var
    HHGear: PGear;
begin
    dec(Gear^.Timer);
    if Gear^.Timer = 0 then
        begin
        inc(Gear^.Tag);
        Gear^.Timer := 100
        end;

    if Gear^.Tag = 4 then
        begin
        HHGear := Gear^.Hedgehog^.Gear;
        HHGear^.State := HHGear^.State or gstNoDamage;
        DeleteCI(HHGear);

        AmmoShove(Gear, Gear^.Boom, 115);

        HHGear^.State := (HHGear^.State and (not gstNoDamage)) or gstMoving;
        Gear^.Timer := 250;
        Gear^.doStep := @doStepIdle
        end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepWhip(Gear: PGear);
var
    HHGear: PGear;
    i: LongInt;
begin
    HHGear := Gear^.Hedgehog^.Gear;
    HHGear^.State := HHGear^.State or gstNoDamage;
    DeleteCI(HHGear);

    for i:= 0 to 3 do
        begin
        AddVisualGear(hwRound(Gear^.X) + hwSign(Gear^.dX) * (10 + 6 * i), hwRound(Gear^.Y) + 12 + Random(6), vgtDust);
        AmmoShove(Gear, Gear^.Boom, 25);
        Gear^.X := Gear^.X + Gear^.dX * 5
        end;

    HHGear^.State := (HHGear^.State and (not gstNoDamage)) or gstMoving;

    Gear^.Timer := 250;
    Gear^.doStep := @doStepIdle
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFlame(Gear: PGear);
var
    gX,gY,i: LongInt;
    sticky: Boolean;
    vgt: PVisualGear;
    tdX,tdY, f: HWFloat;
    landPixel: Word;
begin
    WorldWrap(Gear);
    if Gear^.FlightTime > 0 then dec(Gear^.FlightTime);
    sticky:= (Gear^.State and gsttmpFlag) <> 0;
    if not sticky then AllInactive := false;

    landPixel:= TestCollisionYwithGear(Gear, 1);
    if landPixel = 0 then
        begin
        AllInactive := false;

        if (GameTicks and $F = 0) and (Gear^.FlightTime = 0) then
            begin
            Gear^.Radius := 7;
            tdX:= Gear^.dX;
            tdY:= Gear^.dY;
            Gear^.dX.QWordValue:= 120000000;
            Gear^.dY.QWordValue:= 429496730;
            Gear^.dX.isNegative:= getrandom(2)<>1;
            Gear^.dY.isNegative:= true;
            AmmoShove(Gear, Gear^.Boom, 125);
            Gear^.dX:= tdX;
            Gear^.dY:= tdY;
            Gear^.Radius := 1
	    end;

        if ((GameTicks mod 100) = 0) then
            begin
            vgt:= AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtFire, gstTmpFlag);
            if vgt <> nil then
                begin
                vgt^.dx:= 0;
                vgt^.dy:= 0;
                vgt^.FrameTicks:= 1800 div (Gear^.Tag mod 3 + 2);
                end;
            end;

        if (Gear^.dX.QWordValue > _2.QWordValue)
            or (Gear^.dY.QWordValue > _2.QWordValue)
        then
        begin
            // norm speed vector to length of 2 for fire particles to keep flying in the same direction
            f:= _1_9 / Distance(Gear^.dX, Gear^.dY);
            Gear^.dX:= Gear^.dX * f;
            Gear^.dY:= Gear^.dY * f;
        end
        else begin
            if Gear^.dX.QWordValue > _0_01.QWordValue then
                    Gear^.dX := Gear^.dX * _0_995;

            Gear^.dY := Gear^.dY + cGravity;
            // if sticky then Gear^.dY := Gear^.dY + cGravity;

            if Gear^.dY.QWordValue > _0_2.QWordValue then
                Gear^.dY := Gear^.dY * _0_995;

            //if sticky then Gear^.X := Gear^.X + Gear^.dX else
            Gear^.X := Gear^.X + Gear^.dX + cWindSpeed * 640;
            Gear^.Y := Gear^.Y + Gear^.dY;
        end;

        gX := hwRound(Gear^.X);
        gY := hwRound(Gear^.Y);

        if CheckCoordInWater(gX, gY) then
            begin
            for i:= 0 to 3 do
                AddVisualGear(gX - 8 + Random(16), gY - 8 + Random(16), vgtSteam);
            PlaySound(sndVaporize);
            DeleteGear(Gear);
            exit
            end
        end
    else
        begin
        if (Gear^.Timer = 1) and (GameTicks and $3 = 0) then
            begin
            Gear^.Y:= Gear^.Y+_6;
            if (landPixel and lfIce <> 0) or (TestCollisionYwithGear(Gear, 1) and lfIce <> 0) then
                begin
                gX := hwRound(Gear^.X);
                gY := hwRound(Gear^.Y) - 6;
                DrawExplosion(gX, gY, 4);
                PlaySound(sndVaporize);
                AddVisualGear(gX - 3 + Random(6), gY - 2, vgtSteam);
                DeleteGear(Gear);
                exit
                end;
            Gear^.Y:= Gear^.Y-_6
            end;
        if sticky and (GameTicks and $F = 0) then
            begin
            Gear^.Radius := 7;
            tdX:= Gear^.dX;
            tdY:= Gear^.dY;
            Gear^.dX.QWordValue:= 120000000;
            Gear^.dY.QWordValue:= 429496730;
            Gear^.dX.isNegative:= getrandom(2)<>1;
            Gear^.dY.isNegative:= true;
            AmmoShove(Gear, Gear^.Boom, 125);
            Gear^.dX:= tdX;
            Gear^.dY:= tdY;
            Gear^.Radius := 1
            end;
        if Gear^.Timer > 0 then
            begin
            dec(Gear^.Timer);
            inc(Gear^.Damage)
            end
        else
            begin
            gX := hwRound(Gear^.X);
            gY := hwRound(Gear^.Y);
            // Standard fire
            if not sticky then
                begin
                if ((GameTicks and $1) = 0) then
                    begin
                    Gear^.Radius := 7;
                    tdX:= Gear^.dX;
                    tdY:= Gear^.dY;
                    Gear^.dX.QWordValue:= 214748365;
                    Gear^.dY.QWordValue:= 429496730;
                    Gear^.dX.isNegative:= getrandom(2)<>1;
                    Gear^.dY.isNegative:= true;
                    AmmoShove(Gear, Gear^.Boom * 3, 100);
                    Gear^.dX:= tdX;
                    Gear^.dY:= tdY;
                    Gear^.Radius := 1;
                    end
                else if ((GameTicks and $3) = 3) then
                    doMakeExplosion(gX, gY, Gear^.Boom * 4, Gear^.Hedgehog, 0);//, EXPLNoDamage);
                //DrawExplosion(gX, gY, 4);

                if ((GameTicks and $7) = 0) and (Random(2) = 0) then
                    for i:= Random(2) downto 0 do
                        AddVisualGear(gX - 3 + Random(6), gY - 2, vgtSmoke);

                if Gear^.Health > 0 then
                    dec(Gear^.Health);
                Gear^.Timer := 450 - Gear^.Tag * 8 + LongInt(GetRandom(2))
                end
            else
                begin
                // Modified fire
                if ((GameTicks and $7FF) = 0) and ((GameFlags and gfSolidLand) = 0) then
                    begin
                    DrawExplosion(gX, gY, 4);

                    for i:= Random(3) downto 0 do
                        AddVisualGear(gX - 3 + Random(6), gY - 2, vgtSmoke);
                    end;

// This one is interesting.  I think I understand the purpose, but I wonder if a bit more fuzzy of kicking could be done with getrandom.
                Gear^.Timer := 100 - Gear^.Tag * 3 + LongInt(GetRandom(2));
                if (Gear^.Damage > 3000+Gear^.Tag*1500) then
                    Gear^.Health := 0
                end
            end
        end;
    if Gear^.Health = 0 then
        begin
        gX := hwRound(Gear^.X);
        gY := hwRound(Gear^.Y);
        if not sticky then
            begin
            if ((GameTicks and $3) = 0) and (Random(1) = 0) then
                for i:= Random(2) downto 0 do
                    AddVisualGear(gX - 3 + Random(6), gY - 2, vgtSmoke);
            end
        else
            for i:= Random(3) downto 0 do
                AddVisualGear(gX - 3 + Random(6), gY - 2, vgtSmoke);

        DeleteGear(Gear)
        end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFirePunchWork(Gear: PGear);
var
    HHGear: PGear;
begin
    AllInactive := false;
    if ((Gear^.Message and gmDestroy) <> 0) then
        begin
        DeleteGear(Gear);
        AfterAttack;
        exit
        end;

    HHGear := Gear^.Hedgehog^.Gear;
    if hwRound(HHGear^.Y) <= Gear^.Tag - 2 then
        begin
        Gear^.Tag := hwRound(HHGear^.Y);
        DrawTunnel(HHGear^.X - int2hwFloat(cHHRadius), HHGear^.Y - _1, _0_5, _0, cHHRadius * 4+2, 2);
        HHGear^.State := HHGear^.State or gstNoDamage;
        Gear^.Y := HHGear^.Y;
        AmmoShove(Gear, Gear^.Boom, 40);
        HHGear^.State := HHGear^.State and (not gstNoDamage)
        end;

    HHGear^.dY := HHGear^.dY + cGravity;
    if Gear^.Timer > 0 then dec(Gear^.Timer);
    if not (HHGear^.dY.isNegative) or (Gear^.Timer = 0) then
        begin
        HHGear^.State := HHGear^.State or gstMoving;
        DeleteGear(Gear);
        AfterAttack;
        exit
        end;

    if CheckLandValue(hwRound(HHGear^.X), hwRound(HHGear^.Y + HHGear^.dY + SignAs(_6,Gear^.dY)),
        lfIndestructible) then
            HHGear^.Y := HHGear^.Y + HHGear^.dY
end;

procedure doStepFirePunch(Gear: PGear);
var
    HHGear: PGear;
begin
    AllInactive := false;
    HHGear := Gear^.Hedgehog^.Gear;
    DeleteCI(HHGear);
    //HHGear^.X := int2hwFloat(hwRound(HHGear^.X)) - _0_5; WTF?
    HHGear^.dX := SignAs(cLittle, Gear^.dX);

    HHGear^.dY := - _0_3;

    Gear^.X := HHGear^.X;
    Gear^.dX := SignAs(_0_45, Gear^.dX);
    Gear^.dY := - _0_9;
    Gear^.doStep := @doStepFirePunchWork;
    DrawTunnel(HHGear^.X - int2hwFloat(cHHRadius), HHGear^.Y + _1, _0_5, _0, cHHRadius * 4, 5);

    PlaySoundV(TSound(ord(sndFirePunch1) + GetRandom(6)), HHGear^.Hedgehog^.Team^.voicepack)
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepParachuteWork(Gear: PGear);
var
    HHGear: PGear;
begin
    HHGear := Gear^.Hedgehog^.Gear;

    inc(Gear^.Timer);

    if (TestCollisionYwithGear(HHGear, 1) <> 0)
    or ((HHGear^.State and gstHHDriven) = 0)
    or CheckGearDrowning(HHGear)
    or ((Gear^.Message and gmAttack) <> 0) then
        begin
        with HHGear^ do
            begin
            Message := 0;
            SetLittle(dX);
            dY := _0;
            State := State or gstMoving;
            end;
        DeleteGear(Gear);
        isCursorVisible := false;
        ApplyAmmoChanges(HHGear^.Hedgehog^);
        exit
        end;

    HHGear^.X := HHGear^.X + cWindSpeed * 200;

    if (Gear^.Message and gmLeft) <> 0 then
        HHGear^.X := HHGear^.X - cMaxWindSpeed * 80

    else if (Gear^.Message and gmRight) <> 0 then
        HHGear^.X := HHGear^.X + cMaxWindSpeed * 80;

    if (Gear^.Message and gmUp) <> 0 then
        HHGear^.Y := HHGear^.Y - cGravity * 40

    else if (Gear^.Message and gmDown) <> 0 then
        HHGear^.Y := HHGear^.Y + cGravity * 40;

    // don't drift into obstacles
    if TestCollisionXwithGear(HHGear, hwSign(HHGear^.dX)) <> 0 then
        HHGear^.X := HHGear^.X - int2hwFloat(hwSign(HHGear^.dX));
    HHGear^.Y := HHGear^.Y + cGravity * 100;
    Gear^.X := HHGear^.X;
    Gear^.Y := HHGear^.Y
end;

procedure doStepParachute(Gear: PGear);
var
    HHGear: PGear;
begin
    HHGear := Gear^.Hedgehog^.Gear;

    DeleteCI(HHGear);

    AfterAttack;

    // make sure hog doesn't end up facing in wrong direction due to high jump
    if (HHGear^.State and gstHHHJump) <> 0 then
        HHGear^.dX.isNegative := (not HHGear^.dX.isNegative);

    HHGear^.State := HHGear^.State and (not (gstAttacking or gstAttacked or gstMoving or gstHHJumping or gstHHHJump));
    HHGear^.Message := HHGear^.Message and (not gmAttack);

    Gear^.doStep := @doStepParachuteWork;

    Gear^.Message := HHGear^.Message;
    doStepParachuteWork(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepAirAttackWork(Gear: PGear);
begin
    AllInactive := false;
    Gear^.X := Gear^.X + cAirPlaneSpeed * Gear^.Tag;

    if (Gear^.Health > 0) and (not (Gear^.X < Gear^.dX)) and (Gear^.X < Gear^.dX + cAirPlaneSpeed) then
        begin
        dec(Gear^.Health);
            case Gear^.State of
                0: FollowGear := AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtAirBomb, 0, cBombsSpeed * Gear^.Tag, _0, 0);
                1: FollowGear := AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtMine,    0, cBombsSpeed * Gear^.Tag, _0, 0);
                2: FollowGear := AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtNapalmBomb, 0, cBombsSpeed * Gear^.Tag, _0, 0);
                3: FollowGear := AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtDrill, gsttmpFlag, cBombsSpeed * Gear^.Tag, _0, Gear^.Timer + 1);
            //4: FollowGear := AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtWaterMelon, 0, cBombsSpeed *
            //                 Gear^.Tag, _0, 5000);
            end;
        Gear^.dX := Gear^.dX + int2hwFloat(Gear^.Damage * Gear^.Tag);
        if CheckCoordInWater(hwRound(Gear^.X), hwRound(Gear^.Y)) then
            FollowGear^.State:= FollowGear^.State or gstSubmersible;
        StopSoundChan(Gear^.SoundChannel, 4000);
        end;

    if (GameTicks and $3F) = 0 then
        AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtSmokeTrace);

    if (hwRound(Gear^.X) > (max(LAND_WIDTH,4096)+2048)) or (hwRound(Gear^.X) < -2048) then
        begin
        // avoid to play forever (is this necessary?)
        StopSoundChan(Gear^.SoundChannel);
        DeleteGear(Gear)
        end;
end;

procedure doStepAirAttack(Gear: PGear);
begin
    AllInactive := false;

    if Gear^.X.QWordValue = 0 then
        begin
        Gear^.Tag :=  1;
        Gear^.X := -_2048;
        end
    else
        begin
        Gear^.Tag := -1;
        Gear^.X := int2hwFloat(max(LAND_WIDTH,4096) + 2048);
        end;

    Gear^.Y := int2hwFloat(topY-300);
    Gear^.dX := int2hwFloat(Gear^.Target.X) - int2hwFloat(Gear^.Tag * (Gear^.Health-1) * Gear^.Damage) / 2;

    // calcs for Napalm Strike, so that it will hit the target (without wind at least :P)
    if (Gear^.State = 2) then
        Gear^.dX := Gear^.dX - cBombsSpeed * Gear^.Tag * 900
    // calcs for regular falling gears
    else if (int2hwFloat(Gear^.Target.Y) - Gear^.Y > _0) then
            Gear^.dX := Gear^.dX - cBombsSpeed * hwSqrt((int2hwFloat(Gear^.Target.Y) - Gear^.Y) * 2 /
                cGravity) * Gear^.Tag;

    Gear^.doStep := @doStepAirAttackWork;
    Gear^.SoundChannel := LoopSound(sndPlane, 4000);

end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepAirBomb(Gear: PGear);
begin
    AllInactive := false;
    doStepFallingGear(Gear);
    if (Gear^.State and gstCollision) <> 0 then
        begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
        DeleteGear(Gear);
        {$IFNDEF PAS2C}
        with mobileRecord do
            if (performRumble <> nil) and (not fastUntilLag) then
                performRumble(kSystemSoundID_Vibrate);
        {$ENDIF}
        exit
        end;
    if (GameTicks and $3F) = 0 then
        AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtSmokeTrace)
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepGirder(Gear: PGear);
var
    HHGear: PGear;
    x, y, tx, ty: hwFloat;
    rx: LongInt;
    LandFlags: Word;
    warn: PVisualGear;
    distFail: boolean;
begin
    AllInactive := false;

    HHGear := Gear^.Hedgehog^.Gear;
    tx := int2hwFloat(Gear^.Target.X);
    ty := int2hwFloat(Gear^.Target.Y);
    x := HHGear^.X;
    y := HHGear^.Y;
    rx:= hwRound(x);

    LandFlags:= 0;
    if Gear^.AmmoType = amRubber then LandFlags:= lfBouncy
    else if cIce then LandFlags:= lfIce;

    distFail:= (cBuildMaxDist > 0) and ((hwRound(Distance(tx - x, ty - y)) > cBuildMaxDist) and ((WorldEdge <> weWrap) or
            (
            (hwRound(Distance(tx - int2hwFloat(rightX+(rx-leftX)), ty - y)) > cBuildMaxDist) and
            (hwRound(Distance(tx - int2hwFloat(leftX-(rightX-rx)), ty - y)) > cBuildMaxDist)
            )));
    if distFail
    or (not TryPlaceOnLand(Gear^.Target.X - SpritesData[Ammoz[Gear^.AmmoType].PosSprite].Width div 2, Gear^.Target.Y - SpritesData[Ammoz[Gear^.AmmoType].PosSprite].Height div 2, Ammoz[Gear^.AmmoType].PosSprite, Gear^.State, true, LandFlags)) then
        begin
        PlaySound(sndDenied);
        if not distFail then
            begin
            warn:= AddVisualGear(Gear^.Target.X, Gear^.Target.Y, vgtNoPlaceWarn, 0, true);
            if warn <> nil then
                warn^.Tex := GetPlaceCollisionTex(Gear^.Target.X - SpritesData[Ammoz[Gear^.AmmoType].PosSprite].Width div 2, Gear^.Target.Y - SpritesData[Ammoz[Gear^.AmmoType].PosSprite].Height div 2, Ammoz[Gear^.AmmoType].PosSprite, Gear^.State);
            end;
        HHGear^.Message := HHGear^.Message and (not gmAttack);
        HHGear^.State := HHGear^.State and (not gstAttacking);
        HHGear^.State := HHGear^.State or gstChooseTarget;
        isCursorVisible := true;
        DeleteGear(Gear)
        end
    else
        begin
        PlaySound(sndPlaced);
        DeleteGear(Gear);
        AfterAttack;
        end;

    HHGear^.State := HHGear^.State and (not (gstAttacking or gstAttacked));
    HHGear^.Message := HHGear^.Message and (not gmAttack);
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepTeleportAfter(Gear: PGear);
var
    HHGear: PGear;
begin
    HHGear := Gear^.Hedgehog^.Gear;
    if HHGear <> nil then doStepHedgehogMoving(HHGear);
    // if not infattack mode wait for hedgehog finish falling to collect cases
    if ((GameFlags and gfInfAttack) <> 0)
    or (HHGear = nil)
    or ((HHGear^.State and gstMoving) = 0)
    or (HHGear^.Damage > 0)
    or ((HHGear^.State and gstDrowning) = 1) then
        begin
        DeleteGear(Gear);
        AfterAttack
        end
end;

procedure doStepTeleportAnim(Gear: PGear);
begin
    if (Gear^.Hedgehog^.Gear = nil) or (Gear^.Hedgehog^.Gear^.Damage > 0) then
        begin
        DeleteGear(Gear);
        AfterAttack;
        end;
    inc(Gear^.Timer);
    if Gear^.Timer = 65 then
        begin
        Gear^.Timer := 0;
        inc(Gear^.Pos);
        if Gear^.Pos = 11 then
            Gear^.doStep := @doStepTeleportAfter
        end;
end;

procedure doStepTeleport(Gear: PGear);
var
    lx, ty, y, oy: LongInt;
    HHGear       : PGear;
    valid        : Boolean;
    warn         : PVisualGear;
const
    ytol = cHHRadius;
begin
    AllInactive := false;

    HHGear := Gear^.Hedgehog^.Gear;
    if HHGear = nil then
    begin
        DeleteGear(Gear);
        exit
    end; 

    valid:= false;

    lx:= Gear^.Target.X - SpritesData[sprHHTelepMask].Width  div 2; // left
    lx:= CalcWorldWrap(lx, SpritesData[sprHHTelepMask].Width); // Take world edge into account
    ty:= Gear^.Target.Y - SpritesData[sprHHTelepMask].Height div 2; // top

    // remember original target location
    oy:= Gear^.Target.Y;

    for y:= ty downto ty - ytol do
        begin
        if TryPlaceOnLand(lx, y, sprHHTelepMask, 0, false, not hasBorder, false, false, false, false, 0, $FFFFFFFF) then
            begin
            valid:= true;
            break;
            end;
        dec(Gear^.Target.Y);
        end;

    if not valid then
        begin
        HHGear^.Message := HHGear^.Message and (not gmAttack);
        HHGear^.State := HHGear^.State and (not gstAttacking);
        HHGear^.State := HHGear^.State or gstChooseTarget;
        isCursorVisible := true;
        warn:= AddVisualGear(Gear^.Target.X, oy, vgtNoPlaceWarn, 0, true);
        if warn <> nil then
            warn^.Tex := GetPlaceCollisionTex(lx, ty, sprHHTelepMask, 0);
        DeleteGear(Gear);
        PlaySound(sndDenied);
        exit
        end
    else
        begin
        DeleteCI(HHGear);
        SetAllHHToActive;
        Gear^.doStep := @doStepTeleportAnim;

  // copy old HH position and direction to Gear (because we need them for drawing the vanishing hog)
        Gear^.dX := HHGear^.dX;
        // retrieve the cursor direction (it was previously copied to X so it doesn't get lost)
        HHGear^.dX.isNegative := (Gear^.X.QWordValue <> 0);
        Gear^.X := HHGear^.X;
        Gear^.Y := HHGear^.Y;
        HHGear^.X := int2hwFloat(Gear^.Target.X);
        HHGear^.Y := int2hwFloat(Gear^.Target.Y);
        HHGear^.State := HHGear^.State or gstMoving;
        if not Gear^.Hedgehog^.Unplaced then
            Gear^.State:= Gear^.State or gstAnimation;
        Gear^.Hedgehog^.Unplaced := false;
        isCursorVisible := false;
        playSound(sndWarp)
        end;
    Gear^.Target.X:= NoPointX
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSwitcherWork(Gear: PGear);
var
    HHGear: PGear;
    hedgehog: PHedgehog;
    State: Longword;
    switchDir: Longword;
begin
    AllInactive := false;

    if ((Gear^.Message and (not (gmSwitch or gmPrecise))) <> 0) or (TurnTimeLeft = 0) then
        begin
        hedgehog := Gear^.Hedgehog;
        //Msg := Gear^.Message and (not gmSwitch);
        DeleteGear(Gear);
        ApplyAmmoChanges(hedgehog^);

        HHGear := CurrentHedgehog^.Gear;
        ApplyAmmoChanges(HHGear^.Hedgehog^);
        //HHGear^.Message := Msg;
        exit
        end;

    if (Gear^.Message and gmSwitch) <> 0 then
        begin
        HHGear := CurrentHedgehog^.Gear;
        HHGear^.Message := HHGear^.Message and (not gmSwitch);
        Gear^.Message := Gear^.Message and (not gmSwitch);

        // switching in reverse direction
        if (Gear^.Message and gmPrecise) <> 0 then
            begin
            HHGear^.Message := HHGear^.Message and (not gmPrecise);
            switchDir:= CurrentTeam^.HedgehogsNumber - 1;
            end
        else
            switchDir:=  1;

        State := HHGear^.State;
        HHGear^.State := 0;
        HHGear^.Z := cHHZ;
        HHGear^.Active := false;
        HHGear^.Message:= HHGear^.Message or gmRemoveFromList or gmAddToList;

        PlaySound(sndSwitchHog);

        repeat
            CurrentTeam^.CurrHedgehog := (CurrentTeam^.CurrHedgehog + switchDir) mod CurrentTeam^.HedgehogsNumber;
        until (CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear <> nil) and
              (CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear^.Damage = 0) and
              (CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Effects[heFrozen]=0);

        SwitchCurrentHedgehog(@CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog]);
        AmmoMenuInvalidated:= true;

        HHGear := CurrentHedgehog^.Gear;
        HHGear^.State := State;
        HHGear^.Active := true;
        FollowGear := HHGear;
        HHGear^.Z := cCurrHHZ;
        // restore precise key
        if (switchDir <> 1) then
            HHGear^.Message:= HHGear^.Message or gmPrecise;
        HHGear^.Message:= HHGear^.Message or gmRemoveFromList or gmAddToList;
        Gear^.X := HHGear^.X;
        Gear^.Y := HHGear^.Y
        end;
end;

procedure doStepSwitcher(Gear: PGear);
var
    HHGear: PGear;
begin
    Gear^.doStep := @doStepSwitcherWork;

    HHGear := Gear^.Hedgehog^.Gear;
    OnUsedAmmo(HHGear^.Hedgehog^);
    with HHGear^ do
        begin
        State := State and (not gstAttacking);
        Message := Message and (not gmAttack)
        end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepMortar(Gear: PGear);
var
    dX, dY, gdX, gdY: hwFloat;
    i: LongInt;
begin
    AllInactive := false;
    gdX := Gear^.dX;
    gdY := Gear^.dY;

    doStepFallingGear(Gear);
    if (Gear^.State and gstCollision) <> 0 then
        begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
        gdX.isNegative := not gdX.isNegative;
        gdY.isNegative := not gdY.isNegative;
        gdX:= gdX*_0_2;
        gdY:= gdY*_0_2;

        for i:= 0 to 4 do
            begin
            dX := gdX + rndSign(GetRandomf) * _0_03;
            dY := gdY + rndSign(GetRandomf) * _0_03;
            AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtCluster, 0, dX, dY, 25);
            end;

        DeleteGear(Gear);
        exit
        end;

    if (GameTicks and $3F) = 0 then
        AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtSmokeTrace);
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepKamikazeWork(Gear: PGear);
var
    i: LongWord;
    HHGear: PGear;
    sparkles: PVisualGear;
    hasWishes: boolean;
    s: ansistring;
begin
    AllInactive := false;
    hasWishes:= ((Gear^.Message and (gmPrecise or gmSwitch)) = (gmPrecise or gmSwitch));
    if hasWishes then
        Gear^.AdvBounce:= 1;

    HHGear := Gear^.Hedgehog^.Gear;
    if HHGear = nil then
        begin
        DeleteGear(Gear);
        exit
        end;

    HHGear^.State := HHGear^.State or gstNoDamage;
    DeleteCI(HHGear);

    Gear^.X := HHGear^.X;
    Gear^.Y := HHGear^.Y;
    if (GameTicks mod 2 = 0) and hasWishes then
        begin
        sparkles:= AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtDust, 1);
        if sparkles <> nil then
            begin
            sparkles^.Tint:= ((random(210)+45) shl 24) or ((random(210)+45) shl 16) or ((random(210)+45) shl 8) or $FF;
            sparkles^.Angle:= random(360);
            end
        end;

    i := 2;
    repeat

        Gear^.X := Gear^.X + HHGear^.dX;
        Gear^.Y := Gear^.Y + HHGear^.dY;
        HHGear^.X := Gear^.X;
        HHGear^.Y := Gear^.Y;

        // check for drowning
        if CheckGearDrowning(HHGear) then
            begin
            AfterAttack;
            DeleteGear(Gear);
            exit;
            end;

        inc(Gear^.Damage, 2);

        //  if TestCollisionXwithGear(HHGear, hwSign(Gear^.dX))
        //      or TestCollisionYwithGear(HHGear, hwSign(Gear^.dY)) then inc(Gear^.Damage, 3);

        dec(i)
    until (i = 0)
    or (Gear^.Damage > Gear^.Health);

    inc(upd);
    if upd > 3 then
        begin
        if Gear^.Health < 1500 then
            begin
            if Gear^.AdvBounce <> 0 then
                Gear^.Pos := 3
            else
                Gear^.Pos := 2;
            end;

        AmmoShove(Gear, Gear^.Boom, 40);

        DrawTunnel(HHGear^.X - HHGear^.dX * 10,
                    HHGear^.Y - _2 - HHGear^.dY * 10 + hwAbs(HHGear^.dY) * 2,
        HHGear^.dX,
        HHGear^.dY,
        20 + cHHRadius * 2,
        cHHRadius * 2 + 7);

        upd := 0
        end;

    if Gear^.Health < Gear^.Damage then
        begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
        if hasWishes then
            for i:= 0 to 31 do
                begin
                sparkles:= AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtStraightShot);
                if sparkles <> nil then
                    with sparkles^ do
                        begin
                        Tint:= ((random(210)+45) shl 24) or ((random(210)+45) shl 16) or ((random(210)+45) shl 8) or $FF;
                        Angle:= random(360);
                        dx:= 0.001 * (random(200));
                        dy:= 0.001 * (random(200));
                        if random(2) = 0 then
                            dx := -dx;
                        if random(2) = 0 then
                            dy := -dy;
                        FrameTicks:= random(400) + 250
                        end
                end;
        s:= ansistring(Gear^.Hedgehog^.Name);
        AddCaption(FormatA(GetEventString(eidKamikaze), s), cWhiteColor, capgrpMessage);
        uStats.HedgehogSacrificed(Gear^.Hedgehog);
        AfterAttack;
        HHGear^.Message:= HHGear^.Message or gmDestroy;
        DeleteGear(Gear);
    end
    else
        begin
        dec(Gear^.Health, Gear^.Damage);
        Gear^.Damage := 0
        end
end;

procedure doStepKamikazeIdle(Gear: PGear);
begin
    AllInactive := false;
    dec(Gear^.Timer);
    if Gear^.Timer = 0 then
        begin
        Gear^.Pos := 1;
        PlaySoundV(sndKamikaze, Gear^.Hedgehog^.Team^.voicepack);
        Gear^.doStep := @doStepKamikazeWork
        end
end;

procedure doStepKamikaze(Gear: PGear);
var
    HHGear: PGear;
begin
    AllInactive := false;

    HHGear := Gear^.Hedgehog^.Gear;

    HHGear^.dX := Gear^.dX;
    HHGear^.dY := Gear^.dY;

    Gear^.dX := SignAs(_0_45, Gear^.dX);
    Gear^.dY := - _0_9;

    Gear^.Timer := 550;

    Gear^.doStep := @doStepKamikazeIdle
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepCakeExpl(Gear: PGear);
begin
    AllInactive := false;

    inc(Gear^.Tag);
    if Gear^.Tag < 2250 then
        exit;

    InCinematicMode:= false;
    doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
    AfterAttack;
    DeleteGear(Gear)
end;

procedure doStepCakeDown(Gear: PGear);
var
    gi: PGear;
    dmg, dmgBase, partyEpicness, i: LongInt;
    fX, fY, tdX, tdY: hwFloat;
    sparkles: PVisualGear;
begin
    AllInactive := false;

    inc(Gear^.Tag);
    if Gear^.Tag < 100 then
        exit;
    Gear^.Tag := 0;

    if Gear^.Pos = 0 then
        begin
///////////// adapted from doMakeExplosion ///////////////////////////
        //fX:= Gear^.X;
        //fY:= Gear^.Y;
        //fX.QWordValue:= fX.QWordValue and $FFFFFFFF00000000;
        //fY.QWordValue:= fY.QWordValue and $FFFFFFFF00000000;
        fX:= int2hwFloat(hwRound(Gear^.X));
        fY:= int2hwFloat(hwRound(Gear^.Y));
        dmgBase:= cakeDmg shl 1 + cHHRadius div 2;
        partyEpicness:= 0;
        gi := GearsList;
        while gi <> nil do
            begin
            if gi^.Kind = gtHedgehog then
                begin
                dmg:= 0;
                tdX:= gi^.X-fX;
                tdY:= gi^.Y-fY;
                if hwRound(hwAbs(tdX)+hwAbs(tdY)) < dmgBase then
                    dmg:= dmgBase - max(hwRound(Distance(tdX, tdY)),gi^.Radius);
                if (dmg > 1) then dmg:= ModifyDamage(min(dmg div 2, cakeDmg), gi);
                if (dmg > 1) then
                    if (CurrentHedgehog^.Gear = gi) and (gi^.Hedgehog^.Effects[heInvulnerable] = 0) then
                        begin
                        gi^.State := gi^.State or gstLoser;
                        // probably not too epic if hitting self too...
                        dec(partyEpicness, 45);
                        end
                    else
                        begin
                        gi^.State := gi^.State or gstWinner;
                        if CurrentHedgehog^.Gear = gi then
                            dec(partyEpicness, 45)
                        else
                            inc(partyEpicness);
                        end;
                end;
            gi := gi^.NextGear
            end;
//////////////////////////////////////////////////////////////////////
        Gear^.doStep := @doStepCakeExpl;
        if (partyEpicness > 6) and (abs(90 - abs(trunc(Gear^.DirAngle))) < 20) then
            begin
            for i := 0 to (2 * partyEpicness) do
                begin
                sparkles:= AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtEgg, 1);
                if sparkles <> nil then
                    begin
                    sparkles^.dX:= 0.008 * (random(100) - 50);
                    sparkles^.dY:= -0.3 + 0.002 * (random(100) - 50);
                    sparkles^.Tint:= ((random(210)+45) shl 24) or ((random(210)+45) shl 16) or ((random(210)+45) shl 8) or $FF;
                    sparkles^.Angle:= random(360);
                    end
                end;
            InCinematicMode:= true;
            end;
        PlaySound(sndCake)
        end
    else dec(Gear^.Pos)
end;


procedure doStepCakeWalk(Gear: PGear);
var
    tdx, tdy: hwFloat;
    cakeData: PCakeData;
begin
    AllInactive := false;

    inc(Gear^.Tag);
    if Gear^.Tag < 7 then
        exit;

    dec(Gear^.Health);
    Gear^.Timer := Gear^.Health*10;
    if Gear^.Health mod 100 = 0 then
        Gear^.PortalCounter:= 0;
    // This is not seconds, but at least it is *some* feedback
    if (Gear^.Health <= 0) or ((Gear^.Message and gmAttack) <> 0) then
        begin
        FollowGear := Gear;
        Gear^.RenderTimer := false;
        Gear^.doStep := @doStepCakeDown;
        exit
        end
    else if Gear^.Timer < 6000 then
        Gear^.RenderTimer:= true;

    if not cakeStep(Gear) then Gear^.doStep:= @doStepCakeFall;

    if Gear^.Tag = 0 then
        begin
        cakeData:= PCakeData(Gear^.Data);
        with cakeData^ do
            begin
            CakeI := (CakeI + 1) mod cakeh;
            tdx := CakePoints[CakeI].x - Gear^.X;
            tdy := - CakePoints[CakeI].y + Gear^.Y;
            CakePoints[CakeI].x := Gear^.X;
            CakePoints[CakeI].y := Gear^.Y;
            Gear^.DirAngle := DxDy2Angle(tdx, tdy);
            end;
        end;
end;

procedure doStepCakeUp(Gear: PGear);
var
    i: Longword;
    cakeData: PCakeData;
begin
    AllInactive := false;

    inc(Gear^.Tag);
    // Animation delay. Skipped if cake only dropped a very short distance.
    if (Gear^.Tag < 100) and (Gear^.FlightTime > 1) then
        exit;
    Gear^.Tag := 0;

    if (Gear^.Pos = 6) or (Gear^.FlightTime <= 1) then
        begin
        Gear^.Pos := 6;
        cakeData:= PCakeData(Gear^.Data);
        with cakeData^ do
            begin
            for i:= 0 to Pred(cakeh) do
                begin
                CakePoints[i].x := Gear^.X;
                CakePoints[i].y := Gear^.Y
                end;
            CakeI := 0;
            end;
        (* This is called frequently if the cake is completely stuck.
           With this a stuck cake takes equally long to explode then
           a normal cake. Removing this code just makes the cake walking
           for a few seconds longer. *)
        if (Gear^.FlightTime <= 1) and (Gear^.Health > 2) then
            dec(Gear^.Health);
        Gear^.FlightTime := 0;
        Gear^.doStep := @doStepCakeWalk
        end
    else
        inc(Gear^.Pos)
end;

procedure doStepCakeFall(Gear: PGear);
begin
    AllInactive := false;

    Gear^.dY := Gear^.dY + cGravity;
    // FlightTime remembers the drop time
    inc(Gear^.FlightTime);
    if TestCollisionYwithGear(Gear, 1) <> 0 then
        Gear^.doStep := @doStepCakeUp
    else
        begin
        Gear^.Y := Gear^.Y + Gear^.dY;
        if CheckGearDrowning(Gear) then
            AfterAttack
        end
end;

procedure doStepCake(Gear: PGear);
begin
    AllInactive := false;

    Gear^.CollisionMask:= lfNotCurrentMask;

    Gear^.dY:= cMaxWindSpeed * 100;

    Gear^.doStep := @doStepCakeFall
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSeductionWork(Gear: PGear);
var i: LongInt;
    hogs: PGearArrayS;
begin
    AllInactive := false;
    hogs := GearsNear(Gear^.X, Gear^.Y, gtHedgehog, Gear^.Radius);
    if hogs.size > 0 then
        begin
        for i:= 0 to hogs.size - 1 do
            with hogs.ar^[i]^ do
                if (hogs.ar^[i] <> CurrentHedgehog^.Gear) and (Hedgehog^.Effects[heFrozen] = 0)  then
                    begin
                    dX:= _50 * cGravity * (Gear^.X - X) / _25;
                    dY:= -_450 * cGravity;
                    Active:= true;
                    end
                else if Hedgehog^.Effects[heFrozen] > 255 then
                    Hedgehog^.Effects[heFrozen]:= 255
        end ;
        AfterAttack;
        DeleteGear(Gear);
(*
    Gear^.X := Gear^.X + Gear^.dX;
    Gear^.Y := Gear^.Y + Gear^.dY;
    x := hwRound(Gear^.X);
    y := hwRound(Gear^.Y);

    if ((y and LAND_HEIGHT_MASK) = 0) and ((x and LAND_WIDTH_MASK) = 0) then
        if (Land[y, x] <> 0) then
            begin
            Gear^.dX.isNegative := not Gear^.dX.isNegative;
            Gear^.dY.isNegative := not Gear^.dY.isNegative;
            Gear^.dX := Gear^.dX * _1_5;
            Gear^.dY := Gear^.dY * _1_5 - _0_3;
            AmmoShove(Gear, 0, 40);
            AfterAttack;
            DeleteGear(Gear)
            end
        else
    else
        begin
        AfterAttack;
        DeleteGear(Gear)
        end*)
end;

procedure doStepSeductionWear(Gear: PGear);
var heart: PVisualGear;
begin
    AllInactive := false;
    inc(Gear^.Timer);
    if Gear^.Timer > 250 then
        begin
        Gear^.Timer := 0;
        inc(Gear^.Pos);
        if Gear^.Pos = 5 then
            PlaySound(sndYoohoo);
        end;


    // note: use GameTicks, not RealTicks, otherwise amount can vary greatly
    if (Gear^.Pos = 14) and (GameTicks and $1 = 0) then
        begin
        heart:= AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtStraightShot);
        if heart <> nil then
            with heart^ do
                begin
                { // old calcs
                dx:= 0.001 * (random(200));
                dy:= 0.001 * (random(200));
                if random(2) = 0 then
                    dx := -dx;
                if random(2) = 0 then
                    dy := -dy;
                }

                // randomize speed in both directions
                dx:= 0.001 * (random(201));
                dy:= 0.001 * (random(201));

                // half of hearts go down
                if random(2) = 0 then
                    begin
                    // create a pointy shape
                    if 0.2 < dx + dy then
                        begin
                        dy:= 0.2 - dy;
                        dx:= 0.2 - dx;
                        end;
                    // sin bulge it out a little to avoid corners on the side
                    dx:= dx + (dx/0.2) * ((0.2 * sin(pi * ((0.2 - dy) / 0.4))) - (0.2 - dy));
                    // change sign
                    dy:= -dy;
                    end
                else // shape hearts on top into 2 arcs
                    dy:= dy * (0.3 + 0.7 * sin(pi * dx / 0.2));

                // half of the hearts go left
                if random(2) = 0 then
                    dx := -dx;
                FrameTicks:= random(750) + 1000;
                State:= ord(sprSeduction)
                end;
        end;

    if Gear^.Pos = 15 then
        Gear^.doStep := @doStepSeductionWork
end;

procedure doStepSeduction(Gear: PGear);
begin
    AllInactive := false;
    //DeleteCI(Gear^.Hedgehog^.Gear);
    Gear^.doStep := @doStepSeductionWear
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepWaterUp(Gear: PGear);
var
    i: LongWord;
begin
    if (Gear^.Tag = 0)
    or (cWaterLine = 0) then
        begin
        DeleteGear(Gear);
        exit
        end;

    AllInactive := false;

    inc(Gear^.Timer);
    if Gear^.Timer = 17 then
        Gear^.Timer := 0
    else
        exit;

    if (WorldEdge = weSea) and (playWidth > cMinPlayWidth) then
        begin
        inc(leftX);
        dec(rightX);
        dec(playWidth, 2);
        for i:= 0 to LAND_HEIGHT - 1 do
            begin
            Land[i, leftX] := 0;
            Land[i, rightX] := 0;
            end;
        end;

    if cWaterLine > 0 then
        begin
        dec(cWaterLine);
        for i:= 0 to LAND_WIDTH - 1 do
            Land[cWaterLine, i] := 0;
        SetAllToActive
        end;

    dec(Gear^.Tag);
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepDrillDrilling(Gear: PGear);
var
    t: PGearArray;
    tempColl: Word;
begin
    AllInactive := false;
    if (Gear^.Timer > 0) and (Gear^.Timer mod 10 <> 0) then
        begin
        dec(Gear^.Timer);
        exit;
        end;

    DrawTunnel(Gear^.X, Gear^.Y, Gear^.dX, Gear^.dY, 2, 6);
    Gear^.X := Gear^.X + Gear^.dX;
    Gear^.Y := Gear^.Y + Gear^.dY;
    if (Gear^.Timer mod 30) = 0 then
        AddVisualGear(hwRound(Gear^.X + _20 * Gear^.dX), hwRound(Gear^.Y + _20 * Gear^.dY), vgtDust);
    if (CheckGearDrowning(Gear)) then
        begin
        StopSoundChan(Gear^.SoundChannel);
        exit
    end;

    tempColl:= Gear^.CollisionMask;
    Gear^.CollisionMask:= $007F;
    if (TestCollisionYWithGear(Gear, hwSign(Gear^.dY)) <> 0) or (TestCollisionXWithGear(Gear, hwSign(Gear^.dX)) <> 0) or (GameTicks > Gear^.FlightTime) then
        t := CheckGearsCollision(Gear)
    else t := nil;
    Gear^.CollisionMask:= tempColl;
    //fixes drill not exploding when touching HH bug

    if (Gear^.Timer = 0) or ((t <> nil) and (t^.Count <> 0))
    or ( ((Gear^.State and gsttmpFlag) = 0) and (TestCollisionYWithGear(Gear, hwSign(Gear^.dY)) = 0) and (TestCollisionXWithGear(Gear, hwSign(Gear^.dX)) = 0))
// CheckLandValue returns true if the type isn't matched
    or (not CheckLandValue(hwRound(Gear^.X), hwRound(Gear^.Y), lfIndestructible)) then
        begin
        //out of time or exited ground
        StopSoundChan(Gear^.SoundChannel);
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
        DeleteGear(Gear);
        exit
        end

    else if (TestCollisionYWithGear(Gear, hwSign(Gear^.dY)) = 0) and (TestCollisionXWithGear(Gear, hwSign(Gear^.dX)) = 0) then
        begin
        StopSoundChan(Gear^.SoundChannel);
        Gear^.Tag := 1;
        Gear^.AdvBounce:= 50;
        Gear^.doStep := @doStepDrill
        end;

    dec(Gear^.Timer);
end;

procedure doStepDrill(Gear: PGear);
var
    t: PGearArray;
    oldX, oldY, oldDx, oldDy: hwFloat;
    t2: hwFloat;
begin
    AllInactive := false;

    if (Gear^.State and gsttmpFlag = 0) and (GameFlags and gfMoreWind = 0) then
        Gear^.dX := Gear^.dX + cWindSpeed;

    oldDx := Gear^.dX;
    oldDy := Gear^.dY;
    oldX := Gear^.X;
    oldY := Gear^.Y;

    doStepFallingGear(Gear);

    if (GameTicks and $3F) = 0 then
        AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtSmokeTrace);

    if ((Gear^.State and gstCollision) <> 0) then
        begin
        //hit
        Gear^.dX := oldDx;
        Gear^.dY := oldDy;
        Gear^.X := oldX;
        Gear^.Y := oldY;

        if GameTicks > Gear^.FlightTime then
            t := CheckGearsCollision(Gear)
        else
            t := nil;
        if (t = nil) or (t^.Count = 0) then
            begin
            //hit the ground not the HH
            t2 := _0_5 / Distance(Gear^.dX, Gear^.dY);
            Gear^.dX := Gear^.dX * t2;
            Gear^.dY := Gear^.dY * t2;
            end

        else if (t <> nil) then
            begin
            //explode right on contact with HH
            doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
            DeleteGear(Gear);
            exit;
            end;

        Gear^.X:= Gear^.X+Gear^.dX*4;
        Gear^.Y:= Gear^.Y+Gear^.dY*4;
        Gear^.SoundChannel := LoopSound(sndDrillRocket);
        Gear^.doStep := @doStepDrillDrilling;

        if (Gear^.State and gsttmpFlag) <> 0 then
            gear^.RenderTimer:= true;
        if Gear^.Timer > 0 then dec(Gear^.Timer)
        end
    else if ((Gear^.State and gsttmpFlag) <> 0) and (Gear^.Tag <> 0) then
        begin
        if Gear^.Timer > 0 then
            dec(Gear^.Timer)
        else
            begin
            doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
            DeleteGear(Gear);
            end
        end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBallgunWork(Gear: PGear);
var
    HHGear, ball: PGear;
    rx, ry: hwFloat;
    gX, gY: LongInt;
begin
    AllInactive := false;
    dec(Gear^.Timer);
    HHGear := Gear^.Hedgehog^.Gear;
    if HHGear = nil then
        begin
        DeleteGear(gear);
        exit
        end;
    HedgehogChAngle(HHGear);
    gX := hwRound(Gear^.X) + GetLaunchX(amBallgun, hwSign(HHGear^.dX), HHGear^.Angle);
    gY := hwRound(Gear^.Y) + GetLaunchY(amBallgun, HHGear^.Angle);
    if (Gear^.Timer mod 100) = 0 then
        begin
        rx := rndSign(getRandomf * _0_1);
        ry := rndSign(getRandomf * _0_1);

        ball:= AddGear(gx, gy, gtBall, 0, SignAs(AngleSin(HHGear^.Angle) * _0_8, HHGear^.dX) + rx, AngleCos(HHGear^.Angle) * ( - _0_8) + ry, 0);
        ball^.CollisionMask:= lfNotCurrentMask;

        PlaySound(sndGun);
        end;

    if (Gear^.Timer = 0) or ((HHGear^.State and gstHHDriven) = 0) then
        begin
        HHGear^.State := HHGear^.State and (not gstNotKickable);
        DeleteGear(Gear);
        AfterAttack
        end
end;

procedure doStepBallgun(Gear: PGear);
var
    HHGear: PGear;
begin
    HHGear := Gear^.Hedgehog^.Gear;
    HHGear^.Message := HHGear^.Message and (not (gmUp or gmDown));
    HHGear^.State := HHGear^.State or gstNotKickable;
    Gear^.doStep := @doStepBallgunWork
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepRCPlaneWork(Gear: PGear);

const cAngleSpeed =   3;
var
    HHGear: PGear;
    i: LongInt;
    dX, dY : hwFloat;
    fChanged: boolean;
    trueAngle: Longword;
    t: PGear;
begin
    if WorldWrap(Gear) then
        begin
        if (WorldEdge = weBounce) then // mirror
            Gear^.Angle:= 4096 - Gear^.Angle
        else if (WorldEdge = weSea) then // rotate 90 degree
            begin
            // sea-wrapped gears move upwards, so let's mirror angle if needed
            if Gear^.Angle < 2048 then
                Gear^.Angle:= 4096 - Gear^.Angle;
            Gear^.Angle:= (Gear^.Angle + 1024) mod 4096;
            end;
        end;
    AllInactive := false;

    HHGear := Gear^.Hedgehog^.Gear;
    FollowGear := Gear;

    if Gear^.Timer > 0 then
        begin
        if Gear^.Timer = 1 then
            begin
            StopSoundChan(Gear^.SoundChannel);
            Gear^.SoundChannel:= -1;
            end;
        dec(Gear^.Timer);
        end;

    fChanged := false;
    if (HHGear = nil) or ((HHGear^.State and gstHHDriven) = 0) or (Gear^.Timer = 0) then
        begin
        fChanged := true;
        if Gear^.Angle > 2048 then
            dec(Gear^.Angle)
        else if Gear^.Angle < 2048 then
            inc(Gear^.Angle)
        else fChanged := false
        end
    else
        begin
        if ((Gear^.Message and gmLeft) <> 0) then
            begin
            fChanged := true;
            Gear^.Angle := (Gear^.Angle + (4096 - cAngleSpeed)) mod 4096
            end;

        if ((Gear^.Message and gmRight) <> 0) then
            begin
            fChanged := true;
            Gear^.Angle := (Gear^.Angle + cAngleSpeed) mod 4096
            end
        end;

    if fChanged then
        begin
        Gear^.dX.isNegative := (Gear^.Angle > 2048);
        if Gear^.dX.isNegative then
            trueAngle := 4096 - Gear^.Angle
        else
            trueAngle := Gear^.Angle;

        Gear^.dX := SignAs(AngleSin(trueAngle), Gear^.dX) * _0_25;
        Gear^.dY := AngleCos(trueAngle) * -_0_25;
        end;

    Gear^.X := Gear^.X + Gear^.dX;
    Gear^.Y := Gear^.Y + Gear^.dY;

    if (GameTicks and $FF) = 0 then
        if Gear^.Timer < 3500 then
            AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtEvilTrace)
    else
        AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtSmokeTrace);

    if (HHGear <> nil) and ((HHGear^.Message and gmAttack) <> 0) and (Gear^.Health <> 0) then
        begin
        HHGear^.Message := HHGear^.Message and (not gmAttack);
        AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtAirBomb, 0, Gear^.dX * _0_5, Gear^.dY *
        _0_5, 0);
        dec(Gear^.Health)
        end;

    if (HHGear <> nil) and ((HHGear^.Message and gmLJump) <> 0) and ((Gear^.State and gsttmpFlag) = 0) then
        begin
        Gear^.State := Gear^.State or gsttmpFlag;
        PauseMusic;
        playSound(sndRideOfTheValkyries);
        inCinematicMode:= true;
        end;

    // pickup bonuses
    t := CheckGearNear(Gear, gtCase, 36, 36);
    if (t <> nil) and (HHGear <> nil) then
        PickUp(HHGear, t);

    CheckCollision(Gear);

    if ((Gear^.State and gstCollision) <> 0) or CheckGearDrowning(Gear) then
        begin
        inCinematicMode:= false;
        StopSoundChan(Gear^.SoundChannel);
        StopSound(sndRideOfTheValkyries);
        ResumeMusic;

        if ((Gear^.State and gstCollision) <> 0) then
            begin
            doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
            for i:= 0 to 15 do
                begin
                dX := AngleCos(i * 64) * _0_5 * (GetRandomf + _1);
                dY := AngleSin(i * 64) * _0_5 * (GetRandomf + _1);
                AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtFlame, 0, dX, dY, 0);
                AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtFlame, 0, dX, -dY, 0);
                end;
            if HHGear <> nil then HHGear^.State := HHGear^.State and (not gstNotKickable);
            DeleteGear(Gear)
            end;

        AfterAttack;
        CurAmmoGear := nil;
        if (GameFlags and gfInfAttack) = 0 then
            begin
            if TagTurnTimeLeft = 0 then
                TagTurnTimeLeft:= TurnTimeLeft;

            TurnTimeLeft:= 14 * 125;
            end;

        if HHGear <> nil then
            HHGear^.Message := 0;
        ParseCommand('/taunt ' + #1, true)
        end
end;

procedure doStepRCPlane(Gear: PGear);
var
    HHGear: PGear;
begin
    HHGear := Gear^.Hedgehog^.Gear;
    HHGear^.Message := 0;
    HHGear^.State := HHGear^.State or gstNotKickable;
    Gear^.Angle := HHGear^.Angle;
    Gear^.Tag := hwSign(HHGear^.dX);

    if HHGear^.dX.isNegative then
        Gear^.Angle := 4096 - Gear^.Angle;
    Gear^.doStep := @doStepRCPlaneWork
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepJetpackWork(Gear: PGear);
var
    HHGear: PGear;
    fuel, i: LongInt;
    move: hwFloat;
    isUnderwater: Boolean;
    bubble: PVisualGear;
begin
    isUnderwater:= CheckCoordInWater(hwRound(Gear^.X), hwRound(Gear^.Y) + Gear^.Radius);
    if Gear^.Pos > 0 then
        dec(Gear^.Pos);
    AllInactive := false;
    HHGear := Gear^.Hedgehog^.Gear;
    //dec(Gear^.Timer);
    move := _0_2;
    fuel := 50;
(*if (HHGear^.Message and gmPrecise) <> 0 then
    begin
    move:= _0_02;
    fuel:= 5;
    end;*)
    if HHGear^.Message and gmPrecise <> 0 then
        HedgehogChAngle(HHGear)
    else if Gear^.Health > 0 then
        begin
        if HHGear^.Message and gmUp <> 0 then
            begin
            if (not HHGear^.dY.isNegative) or (HHGear^.Y > -_256) then
                begin
                if isUnderwater then
                    begin
                    HHGear^.dY := HHGear^.dY - (move * _0_7);
                    for i:= random(10)+10 downto 0 do
                        begin
                        bubble := AddVisualGear(hwRound(HHGear^.X) - 8 + random(16), hwRound(HHGear^.Y) + 16 + random(8), vgtBubble);
                        if bubble <> nil then
                            bubble^.dY:= random(20)/10+0.1;
                        end
                    end
                else
                    begin
                    PlaySound(sndJetpackBoost);
                    HHGear^.dY := HHGear^.dY - move;
                    end
                end;
            dec(Gear^.Health, fuel);
            Gear^.MsgParam := Gear^.MsgParam or gmUp;
            Gear^.Timer := GameTicks
            end;
        move.isNegative := (HHGear^.Message and gmLeft) <> 0;
        if (HHGear^.Message and (gmLeft or gmRight)) <> 0 then
            begin
            HHGear^.dX := HHGear^.dX + (move * _0_1);
            if isUnderwater then
                begin
                for i:= random(5)+5 downto 0 do
                    begin
                    bubble := AddVisualGear(hwRound(HHGear^.X)+random(8), hwRound(HHGear^.Y) - 8 + random(16), vgtBubble);
                    if bubble <> nil then
                        begin
                        bubble^.dX:= (random(10)/10 + 0.02) * -1;
                        if (move.isNegative) then
                            begin
                            bubble^.X := bubble^.X + 28;
                            bubble^.dX:= bubble^.dX * (-1)
                            end
                        else bubble^.X := bubble^.X - 28;
                        end;
                    end
                end
            else PlaySound(sndJetpackBoost);
            dec(Gear^.Health, fuel div 5);
            Gear^.MsgParam := Gear^.MsgParam or (HHGear^.Message and (gmLeft or gmRight));
            Gear^.Timer := GameTicks
            end
        end;

    // erases them all at once :-/
    if (Gear^.Timer <> 0) and (GameTicks - Gear^.Timer > 250) then
        begin
        Gear^.Timer := 0;
        Gear^.MsgParam := 0
        end;

    if Gear^.Health < 0 then
        Gear^.Health := 0;

    i:= Gear^.Health div 20;

    if (i <> Gear^.Damage) and ((GameTicks and $3F) = 0) then
        begin
        Gear^.Damage:= i;
        //AddCaption('Fuel: '+inttostr(round(Gear^.Health/20))+'%', cWhiteColor, capgrpAmmostate);
        FreeAndNilTexture(Gear^.Tex);
        Gear^.Tex := RenderStringTex(trmsg[sidFuel] + ansistring(': ' + inttostr(i) + '%'), cWhiteColor, fntSmall)
        end;

    if (HHGear^.Message and (gmAttack or gmUp or gmLeft or gmRight) <> 0) and
       (HHGear^.Message and gmPrecise = 0) then
        Gear^.State := Gear^.State and (not gsttmpFlag);

    if HHGear^.Message and gmPrecise = 0 then
        HHGear^.Message := HHGear^.Message and (not (gmUp or gmLeft or gmRight));
    HHGear^.State := HHGear^.State or gstMoving;

    Gear^.X := HHGear^.X;
    Gear^.Y := HHGear^.Y;

    if not isUnderWater and hasBorder and ((HHGear^.X < _0)
    or (hwRound(HHGear^.X) > LAND_WIDTH)) then
        HHGear^.dY.isNegative:= false;

    if ((Gear^.State and gsttmpFlag) = 0)
    or (HHGear^.dY < _0) then
        doStepHedgehogMoving(HHGear);

    if // (Gear^.Health = 0)
        (HHGear^.Damage <> 0)
        //or CheckGearDrowning(HHGear)
        // drown if too deep under water
        or (cWaterLine + cVisibleWater * 4 < hwRound(HHGear^.Y))
        or (TurnTimeLeft = 0)
        // allow brief ground touches - to be fair on this, might need another counter
        or (((GameTicks and $1FF) = 0) and (not HHGear^.dY.isNegative) and (TestCollisionYwithGear(HHGear, 1) <> 0))
        or ((Gear^.Message and gmAttack) <> 0) then
            begin
            with HHGear^ do
                begin
                Message := 0;
                Active := true;
                State := State or gstMoving
                end;
            DeleteGear(Gear);
            isCursorVisible := false;
            ApplyAmmoChanges(HHGear^.Hedgehog^);
        //    if Gear^.Tex <> nil then FreeTexture(Gear^.Tex);

//    Gear^.Tex:= RenderStringTex(trmsg[sidFuel] + ': ' + inttostr(round(Gear^.Health / 20)) + '%', cWhiteColor, fntSmall)

//AddCaption(trmsg[sidFuel]+': '+inttostr(round(Gear^.Health/20))+'%', cWhiteColor, capgrpAmmostate);
            end
end;

procedure doStepJetpack(Gear: PGear);
var
    HHGear: PGear;
begin
    Gear^.Pos:= 0;
    Gear^.doStep := @doStepJetpackWork;

    HHGear := Gear^.Hedgehog^.Gear;

    PlaySound(sndJetpackLaunch);
    FollowGear := HHGear;
    AfterAttack;
    with HHGear^ do
        begin
        State := State and (not gstAttacking);
        Message := Message and (not (gmAttack or gmUp or gmPrecise or gmLeft or gmRight));

        if (dY < _0_1) and (dY > -_0_1) then
            begin
            Gear^.State := Gear^.State or gsttmpFlag;
            dY := dY - _0_2
            end
        end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBirdyDisappear(Gear: PGear);
begin
    AllInactive := false;
    Gear^.Pos := 0;
    if Gear^.Timer < 2000 then
        inc(Gear^.Timer, 1)
    else
        begin
        DeleteGear(Gear);
        end;
end;

procedure doStepBirdyFly(Gear: PGear);
var
    HHGear: PGear;
    fuel, i: LongInt;
    move: hwFloat;
begin
    HHGear := Gear^.Hedgehog^.Gear;
    if HHGear = nil then
        begin
        Gear^.Timer := 0;
        Gear^.State := Gear^.State or gstAnimation or gstTmpFlag;
        Gear^.Timer := 0;
        Gear^.doStep := @doStepBirdyDisappear;
        CurAmmoGear := nil;
        isCursorVisible := false;
        AfterAttack;
        exit
        end;

    move := _0_2;
    fuel := 50;

    if Gear^.Pos > 0 then
        dec(Gear^.Pos, 1)
    else if (HHGear^.Message and (gmLeft or gmRight or gmUp)) <> 0 then
            Gear^.Pos := 500;

    if HHGear^.dX.isNegative then
        Gear^.Tag := -1
    else
        Gear^.Tag := 1;

    if (HHGear^.Message and gmUp) <> 0 then
        begin
        if (not HHGear^.dY.isNegative)
        or (HHGear^.Y > -_256) then
            HHGear^.dY := HHGear^.dY - move;

        dec(Gear^.Health, fuel);
        Gear^.MsgParam := Gear^.MsgParam or gmUp;
        end;

    if (HHGear^.Message and gmLeft) <> 0 then move.isNegative := true;
    if (HHGear^.Message and (gmLeft or gmRight)) <> 0 then
        begin
        HHGear^.dX := HHGear^.dX + (move * _0_1);
        dec(Gear^.Health, fuel div 5);
        Gear^.MsgParam := Gear^.MsgParam or (HHGear^.Message and (gmLeft or gmRight));
        end;

    if Gear^.Health < 0 then
        Gear^.Health := 0;

    if ((GameTicks and $FF) = 0) and (Gear^.Health < 500) then
        for i:= ((500-Gear^.Health) div 250) downto 0 do
            AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtFeather);

    if (HHGear^.Message and gmAttack <> 0) then
        begin
        HHGear^.Message := HHGear^.Message and (not gmAttack);
        if Gear^.FlightTime > 0 then
            begin
            AddGear(hwRound(Gear^.X), hwRound(Gear^.Y) + 32, gtEgg, 0, Gear^.dX * _0_5, Gear^.dY, 0);
            PlaySound(sndBirdyLay);
            dec(Gear^.FlightTime)
            end;
        end;

    if HHGear^.Message and (gmUp or gmPrecise or gmLeft or gmRight) <> 0 then
        Gear^.State := Gear^.State and (not gsttmpFlag);

    HHGear^.Message := HHGear^.Message and (not (gmUp or gmPrecise or gmLeft or gmRight));
    HHGear^.State := HHGear^.State or gstMoving;

    Gear^.X := HHGear^.X;
    Gear^.Y := HHGear^.Y - int2hwFloat(32);
    // For some reason I need to reapply followgear here, something else grabs it otherwise.
    // this is probably not needed anymore
    if not CurrentTeam^.ExtDriven then FollowGear := HHGear;

    if ((Gear^.State and gsttmpFlag) = 0)
    or (HHGear^.dY < _0) then
        doStepHedgehogMoving(HHGear);

    if  (Gear^.Health = 0)
        or (HHGear^.Damage <> 0)
        or CheckGearDrowning(HHGear)
        or (TurnTimeLeft = 0)
        // allow brief ground touches - to be fair on this, might need another counter
        or (((GameTicks and $1FF) = 0) and (not HHGear^.dY.isNegative) and (TestCollisionYwithGear(HHGear, 1) <> 0))
        or ((Gear^.Message and gmAttack) <> 0) then
            begin
            with HHGear^ do
                begin
                Message := 0;
                Active := true;
                State := State or gstMoving
                end;
            Gear^.State := Gear^.State or gstAnimation or gstTmpFlag;
            if HHGear^.dY < _0 then
                begin
                Gear^.dX := HHGear^.dX;
                Gear^.dY := HHGear^.dY;
                end;
            Gear^.Timer := 0;
            Gear^.doStep := @doStepBirdyDisappear;
            CurAmmoGear := nil;
            isCursorVisible := false;
            AfterAttack;
            end
end;

procedure doStepBirdyDescend(Gear: PGear);
var
    HHGear: PGear;
begin
    if Gear^.Timer > 0 then
        dec(Gear^.Timer, 1);

    HHGear := Gear^.Hedgehog^.Gear;
    if (HHGear = nil) or ((HHGear^.State and gstHHDriven) = 0) then
        begin
        Gear^.Hedgehog := nil;
        Gear^.Timer := 0;
        Gear^.State := Gear^.State or gstAnimation or gstTmpFlag;
        Gear^.Timer := 0;
        Gear^.doStep := @doStepBirdyDisappear;
        CurAmmoGear := nil;
        isCursorVisible := false;
        AfterAttack;
        exit
        end;

    HHGear^.Message := HHGear^.Message and (not (gmUp or gmPrecise or gmLeft or gmRight));
    if abs(hwRound(HHGear^.Y - Gear^.Y)) > 32 then
        begin
        if Gear^.Timer = 0 then
            Gear^.Y := Gear^.Y + _0_1
        end
    else if Gear^.Timer = 0 then
        begin
        Gear^.doStep := @doStepBirdyFly;
        HHGear^.dY := -_0_2
        end
end;

procedure doStepBirdyAppear(Gear: PGear);
begin
    Gear^.Pos := 0;
    if Gear^.Timer < 2000 then
        inc(Gear^.Timer, 1)
    else
        begin
        Gear^.Timer := 500;
        Gear^.dX := _0;
        Gear^.dY := _0;
        Gear^.State :=  Gear^.State and (not gstAnimation);
        Gear^.doStep := @doStepBirdyDescend;
        end
end;

procedure doStepBirdy(Gear: PGear);
var
    HHGear: PGear;
begin
    gear^.State :=  gear^.State or gstAnimation and (not gstTmpFlag);
    Gear^.doStep := @doStepBirdyAppear;

    if CurrentHedgehog = nil then
        begin
        DeleteGear(Gear);
        exit
        end;

    HHGear := CurrentHedgehog^.Gear;

    if HHGear^.dX.isNegative then
        Gear^.Tag := -1
    else
        Gear^.Tag := 1;
    Gear^.Pos := 0;
    AllInactive := false;
    FollowGear := HHGear;
    with HHGear^ do
        begin
        State := State and (not gstAttacking);
        Message := Message and (not (gmAttack or gmUp or gmPrecise or gmLeft or gmRight))
        end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepEggWork(Gear: PGear);
var
    vg: PVisualGear;
    i: LongInt;
begin
    AllInactive := false;
    Gear^.dX := Gear^.dX;
    doStepFallingGear(Gear);
    //    CheckGearDrowning(Gear); // already checked for in doStepFallingGear
    CalcRotationDirAngle(Gear);

    if (Gear^.State and gstCollision) <> 0 then
        begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLPoisoned, $C0E0FFE0);
        PlaySound(sndEggBreak);
        AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtEgg);
        vg := AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtEgg);
        if vg <> nil then
            vg^.Frame := 2;

        for i:= 10 downto 0 do
            begin
            vg := AddVisualGear(hwRound(Gear^.X) - 3 + Random(6), hwRound(Gear^.Y) - 3 + Random(6),
                  vgtDust);
            if vg <> nil then
                vg^.dX := vg^.dX + (Gear^.dX.QWordValue / 21474836480);
            end;

        DeleteGear(Gear);
        exit
        end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doPortalColorSwitch();
var CurWeapon: PAmmo;
begin
    if (CurrentHedgehog <> nil) and (CurrentHedgehog^.Gear <> nil) and ((CurrentHedgehog^.Gear^.Message and gmSwitch) <> 0) then
            with CurrentHedgehog^ do
                if (CurAmmoType = amPortalGun) then
                    begin
                    PlaySound(sndPortalSwitch);
                    CurrentHedgehog^.Gear^.Message := CurrentHedgehog^.Gear^.Message and (not gmSwitch);

                    CurWeapon:= GetCurAmmoEntry(CurrentHedgehog^);
                    if CurWeapon^.Pos <> 0 then
                        CurWeapon^.Pos := 0

                    else
                    CurWeapon^.Pos := 1;
                    end;
end;

procedure doStepPortal(Gear: PGear);
var
    iterator, conPortal: PGear;
    s, r, nx, ny, ox, oy, poffs, noffs, pspeed, nspeed,
    resetx, resety, resetdx, resetdy: hwFloat;
    sx, sy, rh, resetr: LongInt;
    hasdxy, isbullet, iscake, isCollision: Boolean;
begin
    doPortalColorSwitch();

    // destroy portal if ground it was attached too is gone
    if (Land[hwRound(Gear^.Y), hwRound(Gear^.X)] <= lfAllObjMask)
    or (Land[hwRound(Gear^.Y), hwRound(Gear^.X)] and lfBouncy <> 0)
    or (Gear^.Timer < 1)
    or (Gear^.Hedgehog^.Team <> CurrentHedgehog^.Team)
    or CheckCoordInWater(hwRound(Gear^.X), hwRound(Gear^.Y)) then
        begin
        deleteGear(Gear);
        EXIT;
        end;

    if (TurnTimeLeft < 1)
    or (Gear^.Health < 1) then
        dec(Gear^.Timer);

    if Gear^.Timer < 10000 then
        gear^.RenderTimer := true;

    // abort if there is no other portal connected to this one
    if (Gear^.LinkedGear = nil) then
        exit;
    if ((Gear^.LinkedGear^.Tag and 1) = 0) then // or if it's still moving;
        exit;

    conPortal := Gear^.LinkedGear;

    // check all gears for stuff to port through
    iterator := nil;
    while true do
    begin

        // iterate through GearsList
        if iterator = nil then
            iterator := GearsList
        else
            iterator := iterator^.NextGear;

        // end of list?
        if iterator = nil then
            break;

        // don't port portals or other gear that wouldn't make sense
        if (iterator^.Kind in [gtPortal, gtRope, gtAirAttack, gtIceGun])
        or (iterator^.PortalCounter > 32) then
            continue;

        // don't port hogs on rope
        // TODO: this will also prevent hogs while falling after rope use from
        //       falling through portals... fix that!

        // check if gear fits through portal
        if (iterator^.Radius > Gear^.Radius) then
            continue;

        // this is the max range we accept incoming gears in
        r := Int2hwFloat(iterator^.Radius+Gear^.Radius);

        // too far away?
        if (iterator^.X < Gear^.X - r)
        or (iterator^.X > Gear^.X + r)
        or (iterator^.Y < Gear^.Y - r)
        or (iterator^.Y > Gear^.Y + r) then
            continue;

        hasdxy := (((iterator^.dX.QWordValue <> 0) or (iterator^.dY.QWordValue <> 0)) or ((iterator^.State and gstMoving) = 0));

        // in case the object is not moving, let's asume it's falling towards the portal
        if not hasdxy then
            begin
            if Gear^.Y < iterator^.Y then
                continue;
            ox:= Gear^.X - iterator^.X;
            oy:= Gear^.Y - iterator^.Y;
            end
        else
            begin
            ox:= iterator^.dX;
            oy:= iterator^.dY;
            end;

        // cake will need extra treatment... it's so delicious and moist!
        iscake:= (iterator^.Kind = gtCake);

        // won't port stuff that does not move towards the front/portal entrance
        if iscake then
            begin
            if not (((iterator^.X - Gear^.X)*ox + (iterator^.Y - Gear^.Y)*oy).isNegative) then
                continue;
            end
        else
            if not ((Gear^.dX*ox + Gear^.dY*oy).isNegative) then
                continue;

        if iterator^.Kind = gtDuck then
            // Make duck go into “falling” mode again
            iterator^.Pos:= 0;

        isbullet:= (iterator^.Kind in [gtShotgunShot, gtDEagleShot, gtSniperRifleShot, gtSineGunShot]);

        r:= int2hwFloat(iterator^.Radius);

        if not (isbullet or iscake) then
            begin
            // wow! good candidate there, let's see if the distance and direction is okay!
            if hasdxy then
                begin
                s := Distance(iterator^.dX, iterator^.dY);
                // if the resulting distance is 0 skip this gear
                if s.QWordValue = 0 then
                    continue;
                s := r / s;
                ox:= iterator^.X + s * iterator^.dX;
                oy:= iterator^.Y + s * iterator^.dY;
                end
            else
                begin
                ox:= iterator^.X;
                oy:= iterator^.Y + r;
                end;

            if (hwRound(Distance(Gear^.X-ox,Gear^.Y-oy)) > Gear^.Radius + 1 ) then
                continue;
            end;

        if (iterator^.Kind = gtDEagleShot) or (iterator^.Kind = gtSniperRifleShot) then
            begin
            // draw bullet trail
            spawnBulletTrail(iterator, iterator^.X, iterator^.Y);
            // the bullet can now hurt the hog that fired it
            iterator^.Data:= nil;
            end;

        // calc gear offset in portal vector direction
        ox := (iterator^.X - Gear^.X);
        oy := (iterator^.Y - Gear^.Y);
        poffs:= (Gear^.dX * ox + Gear^.dY * oy);

        if not isBullet and poffs.isNegative then
            continue;

        // only port bullets close to the portal
        if isBullet and (not (hwAbs(poffs) < _3)) then
            continue;

        //
        // gears that make it till here will definately be ported
        //
        // (but old position/movement vector might be restored in case there's
        // not enough space on the other side)
        //

        resetr  := iterator^.Radius;
        resetx  := iterator^.X;
        resety  := iterator^.Y;
        resetdx := iterator^.dX;
        resetdy := iterator^.dY;

        // create a normal of the portal vector, but ...
        nx := Gear^.dY;
        ny := Gear^.dX;
        // ... decide where the top is based on the hog's direction when firing the portal
        if Gear^.Elasticity.isNegative then
            nx.isNegative := (not nx.isNegative)
        else
            ny.isNegative := not ny.isNegative;

        // calc gear offset in portal normal vector direction
        noffs:= (nx * ox + ny * oy);

        if isBullet and (noffs.Round >= Longword(Gear^.Radius)) then
            continue;

        // avoid gravity related loops of not really moving gear
        if not (iscake or isbullet)
        and (Gear^.dY.isNegative)
        and (conPortal^.dY.isNegative)
        and ((iterator^.dX.QWordValue + iterator^.dY.QWordValue) < _0_08.QWordValue)
        and (iterator^.PortalCounter > 0) then
            continue;

        // calc gear speed along to the vector and the normal vector of the portal
        if hasdxy then
            begin
            pspeed:= (Gear^.dX * iterator^.dX + Gear^.dY * iterator^.dY);
            nspeed:= (nx * iterator^.dX + ny * iterator^.dY);
            end
        else
            begin
            pspeed:= hwAbs(cGravity * oy);
            nspeed:= _0;
            end;

        // creating normal vector of connected (exit) portal
        nx := conPortal^.dY;
        ny := conPortal^.dX;
        if conPortal^.Elasticity.isNegative then
            nx.isNegative := (not nx.isNegative)
        else
            ny.isNegative := not ny.isNegative;

        // inverse cake's normal movement direction,
        // as if it just walked through a hole
        //if iscake then nspeed.isNegative:= not nspeed.isNegative;

//AddFileLog('poffs:'+cstr(poffs)+' noffs:'+cstr(noffs)+' pspeed:'+cstr(pspeed)+' nspeed:'+cstr(nspeed));
        iterator^.dX := -pspeed * conPortal^.dX + nspeed * nx;
        iterator^.dY := -pspeed * conPortal^.dY + nspeed * ny;

        // make the gear's exit position close to the portal while
        // still respecting the movement direction

        // determine the distance (in exit vector direction)
        // that we want the gear at
        if iscake then
            ox:= (r - _0_7)
        else
            ox:= (r * _1_5);
        s:= ox / poffs;
        poffs:= ox;
        if (nspeed.QWordValue <> 0)
        and (pspeed > _0) then
            noffs:= noffs * s * (nspeed / pspeed);

        // move stuff with high normal offset closer to the portal's center
        if not isbullet then
            begin
            s := hwAbs(noffs) + r - int2hwFloat(Gear^.Radius);
            if s > _0 then
                noffs:= noffs - SignAs(s,noffs)
            end;

        iterator^.X := conPortal^.X + poffs * conPortal^.dX + noffs * nx;
        iterator^.Y := conPortal^.Y + poffs * conPortal^.dY + noffs * ny;

        if not hasdxy and (not (conPortal^.dY.isNegative)) then
            begin
            iterator^.dY:= iterator^.dY + hwAbs(cGravity * (iterator^.Y - conPortal^.Y))
            end;

        // see if the space on the exit side actually is enough

        if not (isBullet or isCake) then
            begin
            // TestCollisionXwithXYShift requires a hwFloat for xShift
            ox.QWordValue := _1.QWordValue;
            ox.isNegative := not iterator^.dX.isNegative;

            sx := hwSign(iterator^.dX);
            sy := hwSign(iterator^.dY);

            if iterator^.Radius > 1 then
                iterator^.Radius := iterator^.Radius - 1;

            // check front
            isCollision := (TestCollisionY(iterator, sy) <> 0) or (TestCollisionX(iterator, sx) <> 0);

            if not isCollision then
                begin
                // check center area (with half the radius so that the
                // the square check won't check more pixels than we want to)
                iterator^.Radius := 1 + resetr div 2;
                rh := resetr div 4;
                isCollision := (TestCollisionYwithXYShift(iterator,       0, -sy * rh, sy, false) <> 0)
                            or (TestCollisionXwithXYShift(iterator, ox * rh,        0, sx, false) <> 0);
                end;

            iterator^.Radius := resetr;

            if isCollision then
                begin
                // collision! oh crap! go back!
                iterator^.X  := resetx;
                iterator^.Y  := resety;
                iterator^.dX := resetdx;
                iterator^.dY := resetdy;
                continue;
                end;
            end;

        //
        // You're now officially portaled!
        //

        // Until loops are reliably broken
        if iscake then
            iterator^.PortalCounter:= 33
        else
            begin
            inc(iterator^.PortalCounter);
            iterator^.Active:= true;
            iterator^.State:= iterator^.State and (not gstHHHJump) or gstMoving;
            end;

        // is it worth adding an arcsin table?  Just how often would we end up doing something like this?
        // SYNCED ANGLE UPDATE
        if iterator^.Kind = gtRCPlane then
            iterator^.Angle:= (1024 + vector2Angle(iterator^.dX, iterator^.dY) mod 4096)
        // VISUAL USE OF ANGLE ONLY
        else if (CurAmmoGear <> nil) and (CurAmmoGear^.Kind = gtKamikaze) and (CurAmmoGear^.Hedgehog = iterator^.Hedgehog) then
            begin
            iterator^.Angle:= DxDy2AttackAngle(iterator^.dX, iterator^.dY);
            iterator^.Angle:= 2048-iterator^.Angle;
            if iterator^.dX.isNegative then iterator^.Angle:= 4096-iterator^.Angle;
            end;

        if (CurrentHedgehog <> nil) and (CurrentHedgehog^.Gear <> nil)
        and (iterator = CurrentHedgehog^.Gear)
        and (CurAmmoGear <> nil)
        and (CurAmmoGear^.Kind = gtRope)
        and (CurAmmoGear^.Elasticity <> _0) then
               CurAmmoGear^.PortalCounter:= 1;

        if not isbullet and (iterator^.State and gstInvisible = 0)
        and (iterator^.Kind <> gtFlake) then
            FollowGear := iterator;

        // store X/Y values of exit for net bullet trail
        if isbullet then
            begin
            iterator^.Elasticity:= iterator^.X;
            iterator^.Friction  := iterator^.Y;
            end;

        if Gear^.Health > 1 then
            dec(Gear^.Health);
    end;
end;



procedure loadNewPortalBall(oldPortal: PGear; destroyGear: Boolean);
var
    CurWeapon: PAmmo;
begin
    if CurrentHedgehog <> nil then
        with CurrentHedgehog^ do
            begin
            CurWeapon:= GetCurAmmoEntry(CurrentHedgehog^);
            if (CurAmmoType = amPortalGun) then
                begin
                if not destroyGear then
                    begin
                    // switch color of ball to opposite of oldPortal
                    if (oldPortal^.Tag and 2) = 0 then
                        CurWeapon^.Pos:= 1
                    else
                        CurWeapon^.Pos:= 0;
                    end;

                // make the ball visible
                CurWeapon^.Timer := 0;
                end
            end;
    if destroyGear then
        oldPortal^.Timer:= 0;
end;

procedure doStepMovingPortal_real(Gear: PGear);
var
    x, y, tx, ty: LongInt;
    s: hwFloat;
begin
    WorldWrap(Gear);
    x := hwRound(Gear^.X);
    y := hwRound(Gear^.Y);
    tx := 0;
    ty := 0;
    // avoid compiler hints

    if ((y and LAND_HEIGHT_MASK) = 0) and ((x and LAND_WIDTH_MASK) = 0) and (Land[y, x] > 255) then
        begin
        Gear^.State := Gear^.State or gstCollision;
        Gear^.State := Gear^.State and (not gstMoving);

        if (Land[y, x] and lfBouncy <> 0)
        or (not CalcSlopeTangent(Gear, x, y, tx, ty, 255))
        or (DistanceI(tx,ty) < _12) then // reject shots at too irregular terrain
            begin
            loadNewPortalBall(Gear, true);
            EXIT;
            end;

        // making a normalized normal vector
        s := _1/DistanceI(tx,ty);
        Gear^.dX :=  s * ty;
        Gear^.dY := -s * tx;

        Gear^.DirAngle := DxDy2Angle(-Gear^.dY,Gear^.dX);
        if not Gear^.dX.isNegative then
            Gear^.DirAngle := 180-Gear^.DirAngle;

        if ((Gear^.LinkedGear = nil)
        or (hwRound(Distance(Gear^.X - Gear^.LinkedGear^.X,Gear^.Y-Gear^.LinkedGear^.Y)) >=Gear^.Radius*2)) then
            begin
            PlaySound(sndPortalOpen);
            loadNewPortalBall(Gear, false);
            inc(Gear^.Tag);
            Gear^.doStep := @doStepPortal;
        end
        else
            loadNewPortalBall(Gear, true);
    end

    else if CheckCoordInWater(x, y)
    or (y < -max(LAND_WIDTH,4096))
    or (x > 2*max(LAND_WIDTH,4096))
    or (x < -max(LAND_WIDTH,4096)) then
        loadNewPortalBall(Gear, true);
end;

procedure doStepMovingPortal(Gear: PGear);
begin
    doPortalColorSwitch();
    doStepPerPixel(Gear, @doStepMovingPortal_real, true);
    if (Gear^.Timer < 1)
    or (Gear^.Hedgehog^.Team <> CurrentHedgehog^.Team) then
        deleteGear(Gear);
end;

procedure doStepPortalShot(newPortal: PGear);
var
    iterator: PGear;
    s: hwFloat;
    CurWeapon: PAmmo;
begin
    s:= Distance (newPortal^.dX, newPortal^.dY);

    // Adds the hog speed (only that part in/directly against shot direction)
    // to the shot speed (which we triple previously btw)
    // (This is done my projecting the hog movement vector onto the shot movement vector and then adding the resulting length
    // to the scaler)
    s := (_2 * s + (newPortal^.dX * CurrentHedgehog^.Gear^.dX + newPortal^.dY * CurrentHedgehog^.Gear^.dY ) / s) / s;
    newPortal^.dX := newPortal^.dX * s;
    newPortal^.dY := newPortal^.dY * s;

    newPortal^.LinkedGear := nil;

    PlaySound(sndPortalShot);

    if CurrentHedgehog <> nil then
        with CurrentHedgehog^ do
            begin
            CurWeapon:= GetCurAmmoEntry(CurrentHedgehog^);
            // let's save the HH's dX's direction so we can decide where the "top" of the portal hole
            newPortal^.Elasticity.isNegative := CurrentHedgehog^.Gear^.dX.isNegative;
            // when doing a backjump the dx is the opposite of the facing direction
            if ((Gear^.State and gstHHHJump) <> 0) and (not cArtillery) then
                newPortal^.Elasticity.isNegative := not newPortal^.Elasticity.isNegative;

            // make portal gun look unloaded
            if (CurWeapon <> nil) and (CurAmmoType = amPortalGun) then
                CurWeapon^.Timer := CurWeapon^.Timer or 2;

            iterator := GearsList;
            while iterator <> nil do
                begin
                if (iterator^.Kind = gtPortal) then
                    if (iterator <> newPortal) and (iterator^.Timer > 0) and (iterator^.Hedgehog = CurrentHedgehog) then
                        begin
                        if ((iterator^.Tag and 2) = (newPortal^.Tag and 2)) then
                            begin
                            iterator^.Timer:= 0;
                            end
                        else
                            begin
                            // link portals with each other
                            newPortal^.LinkedGear := iterator;
                            iterator^.LinkedGear := newPortal;
                            iterator^.Health := newPortal^.Health;
                            end;
                        end;
                iterator^.PortalCounter:= 0;
                iterator := iterator^.NextGear
                end;

            if newPortal^.LinkedGear <> nil then
                begin
                // This jiggles gears, to ensure a portal connection just placed under a gear takes effect.
                iterator:= GearsList;
                while iterator <> nil do
                    begin
                    if not (iterator^.Kind in [gtPortal, gtAirAttack, gtKnife, gtSMine]) and ((iterator^.Hedgehog <> CurrentHedgehog)
                    or ((iterator^.Message and gmAllStoppable) = 0)) then
                            begin
                            iterator^.Active:= true;
                            if iterator^.dY.QWordValue = 0 then
                                iterator^.dY.isNegative:= false;
                            iterator^.State:= iterator^.State or gstMoving;
                            DeleteCI(iterator);
                        //inc(iterator^.dY.QWordValue,10);
                            end;
                    iterator:= iterator^.NextGear
                    end
                end
            end;
    newPortal^.State := newPortal^.State and (not gstCollision);
    newPortal^.State := newPortal^.State or gstMoving;
    newPortal^.doStep := @doStepMovingPortal;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepPiano(Gear: PGear);
var
    r0, r1: LongInt;
    odY: hwFloat;
begin
    AllInactive := false;
    if (CurrentHedgehog <> nil) and (CurrentHedgehog^.Gear <> nil) and
        ((CurrentHedgehog^.Gear^.Message and gmSlot) <> 0) then
            begin
                case CurrentHedgehog^.Gear^.MsgParam of
                0: PlaySound(sndPiano0);
                1: PlaySound(sndPiano1);
                2: PlaySound(sndPiano2);
                3: PlaySound(sndPiano3);
                4: PlaySound(sndPiano4);
                5: PlaySound(sndPiano5);
                6: PlaySound(sndPiano6);
                7: PlaySound(sndPiano7);
                else PlaySound(sndPiano8);
            end;
        AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtNote);
        CurrentHedgehog^.Gear^.MsgParam := 0;
        CurrentHedgehog^.Gear^.Message := CurrentHedgehog^.Gear^.Message and (not gmSlot);
        end;

    if (*((Gear^.Pos = 3) and ((GameFlags and gfSolidLand) <> 0)) or*) (Gear^.Pos = 5) then
        begin
        Gear^.dY := Gear^.dY + cGravity * 2;
        Gear^.Y := Gear^.Y + Gear^.dY;
        if CheckGearDrowning(Gear) then
            begin
            Gear^.Y:= Gear^.Y + _50;
            OnUsedAmmo(CurrentHedgehog^);
            uStats.HedgehogSacrificed(CurrentHedgehog);
            if CurrentHedgehog^.Gear <> nil then
                begin
                // Drown the hedgehog.  Could also just delete it, but hey, this gets a caption
                CurrentHedgehog^.Gear^.Active := true;
                CurrentHedgehog^.Gear^.X := Gear^.X;
                CurrentHedgehog^.Gear^.Y := int2hwFloat(cWaterLine+cVisibleWater)+_128;
                CurrentHedgehog^.Unplaced := false;
                if TagTurnTimeLeft = 0 then
                    TagTurnTimeLeft:= TurnTimeLeft;
                TurnTimeLeft:= 0
                end;
            ResumeMusic
            end;
        exit
        end;

    odY:= Gear^.dY;
    doStepFallingGear(Gear);

    if (Gear^.State and gstDrowning) <> 0 then
        begin
        Gear^.Y:= Gear^.Y + _50;
        OnUsedAmmo(CurrentHedgehog^);
        uStats.HedgehogSacrificed(CurrentHedgehog);
        if CurrentHedgehog^.Gear <> nil then
            begin
            // Drown the hedgehog.  Could also just delete it, but hey, this gets a caption
            CurrentHedgehog^.Gear^.Active := true;
            CurrentHedgehog^.Gear^.X := Gear^.X;
            CurrentHedgehog^.Gear^.Y := int2hwFloat(cWaterLine+cVisibleWater)+_128;
            CurrentHedgehog^.Unplaced := false;
            if TagTurnTimeLeft = 0 then
                TagTurnTimeLeft:= TurnTimeLeft;
            TurnTimeLeft:= 0
            end;
        ResumeMusic
        end
    else if (Gear^.State and gstCollision) <> 0 then
        begin
        r0 := GetRandom(Gear^.Boom div 4 + 1);
        r1 := GetRandom(Gear^.Boom div 4 + 1);
        doMakeExplosion(hwRound(Gear^.X) - 30 - r0, hwRound(Gear^.Y) + 40, Gear^.Boom div 2 + r1, Gear^.Hedgehog, 0);
        doMakeExplosion(hwRound(Gear^.X) + 30 + r1, hwRound(Gear^.Y) + 40, Gear^.Boom div 2 + r0, Gear^.Hedgehog, 0);
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom + r0, Gear^.Hedgehog, EXPLAutoSound);
        for r0:= 0 to 4 do
            AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtNote);
        Gear^.dY := cGravity * 2 - odY;
        Gear^.Pos := Gear^.Pos + 1;
        end
    else
        Gear^.dY := Gear^.dY + cGravity * 2;
    // let it fall faster so itdoesn't take too long for the whole attack
end;


////////////////////////////////////////////////////////////////////////////////
procedure doStepSineGunShotWork(Gear: PGear);
var
    x, y, rX, rY, t, tmp, initHealth: LongInt;
    oX, oY, ldX, ldY, sdX, sdY, sine, lx, ly, amp: hwFloat;
    justCollided, justBounced: boolean;
begin
    AllInactive := false;
    initHealth := Gear^.Health;
    lX := Gear^.X;
    lY := Gear^.Y;
    ldX := Gear^.dX;
    ldY := Gear^.dY;
    sdy := _0_5/Distance(Gear^.dX,Gear^.dY);
    ldX := ldX * sdy;
    ldY := ldY * sdy;
    sdY := hwAbs(ldX) + hwAbs(ldY);
    sdX := _1 - hwAbs(ldX/sdY);
    sdY := _1 - hwAbs(ldY/sdY);
    if (ldX.isNegative = ldY.isNegative) then
        sdY := -sdY;

    // initial angle depends on current GameTicks
    t := getRandom(4096);


    // used for a work-around detection of area that is within land array, but outside borders
    justCollided := false;
    // this variable is just to ensure we don't run in infinite loop due to precision errors
    justBounced:= false;

    repeat
        lX := lX + ldX;
        lY := lY + ldY;
        oX := Gear^.X;
        oY := Gear^.Y;
        rX := hwRound(oX);
        rY := hwRound(oY);
        tmp := t mod 4096;
        amp := _128 * (_1 - hwSqr(int2hwFloat(Gear^.Health)/initHealth));
        sine := amp * AngleSin(tmp mod 2048);
        sine.isNegative := (tmp < 2048);
        Gear^.X := lX + (sine * sdX);
        Gear^.Y := ly + (sine * sdY);
        Gear^.dX := Gear^.X - oX;
        Gear^.dY := Gear^.Y - oY;

        x := hwRound(Gear^.X);
        y := hwRound(Gear^.Y);

        if WorldEdge = weWrap then
            begin
            if x > LongInt(rightX) then
                repeat
                    dec(x,  playWidth);
                    dec(rx, playWidth);
                until x <= LongInt(rightX)
            else if x < LongInt(leftX) then
                repeat
                    inc(x,  playWidth);
                    inc(rx, playWidth);
                until x >= LongInt(leftX);
            end
        else if (WorldEdge = weBounce) then
            begin
            if (not justBounced) and ((x > LongInt(rightX)) or (x < LongInt(leftX))) then
                begin
                // reflect
                lX:= lX - ldX + ((oX - lX) * 2);
                lY:= lY - ldY;
                Gear^.X:= oX;
                Gear^.Y:= oY;
                ldX.isNegative:= (not ldX.isNegative);
                sdX.isNegative:= (not sdX.isNegative);
                justBounced:= true;
                continue;
                end
            else
                justBounced:= false;
            end;


        inc(t,Gear^.Health div 313);

        // if borders are on, stop outside land array
        if hasBorder and (((x and LAND_WIDTH_MASK) <> 0) or ((y and LAND_HEIGHT_MASK) <> 0)) then
            begin
            Gear^.Damage := 0;
            Gear^.Health := 0;
            end
        else
            begin
            if (not CheckCoordInWater(rX, rY)) or (not CheckCoordInWater(x, y)) then
                begin
                if ((y and LAND_HEIGHT_MASK) = 0) and ((x and LAND_WIDTH_MASK) = 0)
                    and (Land[y, x] <> 0) then
                        begin
                        if ((GameFlags and gfSolidLand) <> 0) and (Land[y, x] > 255) then
                            Gear^.Damage := initHealth
                        else if justCollided then
                            begin
                            Gear^.Damage := initHealth;
                            end
                        else
                            begin
                            inc(Gear^.Damage,3);
                            justCollided := true;
                            end;
                        end
                else
                    justCollided := false;

                // kick nearby hogs, dig tunnel and add some fire
                // if at least 5 collisions occured
                if Gear^.Damage > 0 then
                    begin
                    if ((GameFlags and gfSolidLand) = 0) then
                        begin
                        DrawExplosion(rX,rY,Gear^.Radius);
                        end;

                    // kick nearby hogs
                    AmmoShove(Gear, Gear^.Boom, 50);

                    dec(Gear^.Health, Gear^.Damage);

                    // explode when impacting on solid land/borders
                    if Gear^.Damage >= initHealth then
                        begin
                        // add some random offset to angles
                        tmp := getRandom(256);
                        // spawn some flames
                        for t:= 0 to 3 do
                            begin
                            if not isZero(Gear^.dX) then rX := rx - hwSign(Gear^.dX);
                            if not isZero(Gear^.dY) then rY := ry - hwSign(Gear^.dY);
                            lX := AngleCos(tmp + t * 512) * _0_25 * (GetRandomf + _1);
                            lY := AngleSin(tmp + t * 512) * _0_25 * (GetRandomf + _1);
                            AddGear(rX, rY, gtFlame, 0, lX,  lY, 0);
                            AddGear(rX, rY, gtFlame, 0, lX, -lY, 0);
                            end;
                        end
                    // add some fire to the tunnel
                    else if getRandom(6) = 0 then
                        begin
                        tmp:= GetRandom(2 * Gear^.Radius);
                        AddGear(x - Gear^.Radius + tmp, y - GetRandom(Gear^.Radius + 1), gtFlame, gsttmpFlag, _0, _0, 0)
                        end;
                    end;

                Gear^.Damage := 0;

                if random(100) = 0 then
                    AddVisualGear(x, y, vgtSmokeTrace);
                end
                else dec(Gear^.Health, 5);
            end;

        dec(Gear^.Health);

        // decrease bullet size towards the end
        if (Gear^.Radius > 4) then
            begin
            if (Gear^.Health <= (initHealth div 3)) then
                dec(Gear^.Radius)
            end
        else if (Gear^.Radius > 3) then
            begin
            if (Gear^.Health <= (initHealth div 4)) then
                dec(Gear^.Radius)
            end
        else if (Gear^.Radius > 2) then begin
            if (Gear^.Health <= (initHealth div 5)) then
                dec(Gear^.Radius)
            end
        else if (Gear^.Radius > 1) then
            begin
            if (Gear^.Health <= (initHealth div 6)) then
                dec(Gear^.Radius)
            end;
    until (Gear^.Health <= 0);

    DeleteGear(Gear);
    AfterAttack;
end;

procedure doStepSineGunShot(Gear: PGear);
var
    HHGear: PGear;
begin
    PlaySound(sndSineGun);

    if (Gear^.Hedgehog <> nil) and (Gear^.Hedgehog^.Gear <> nil) then
        begin
        HHGear := Gear^.Hedgehog^.Gear;
        // push the shooting Hedgehog back
        Gear^.dX.isNegative := not Gear^.dX.isNegative;
        Gear^.dY.isNegative := not Gear^.dY.isNegative;
        HHGear^.dX := Gear^.dX;
        HHGear^.dY := Gear^.dY;
        AmmoShove(Gear, 0, 80);
        Gear^.dX.isNegative := not Gear^.dX.isNegative;
        Gear^.dY.isNegative := not Gear^.dY.isNegative;
        end;

    Gear^.doStep := @doStepSineGunShotWork;
    {$IFNDEF PAS2C}
    with mobileRecord do
        if (performRumble <> nil) and (not fastUntilLag) then
            performRumble(kSystemSoundID_Vibrate);
    {$ENDIF}
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFlamethrowerWork(Gear: PGear);
var
    HHGear, flame: PGear;
    rx, ry, speed: hwFloat;
    i, gX, gY: LongInt;
begin
    AllInactive := false;
    HHGear := Gear^.Hedgehog^.Gear;
    if HHGear = nil then
        begin
        DeleteGear(gear);
        exit
        end;
    HedgehogChAngle(HHGear);
    gX := hwRound(Gear^.X) + GetLaunchX(amBallgun, hwSign(HHGear^.dX), HHGear^.Angle);
    gY := hwRound(Gear^.Y) + GetLaunchY(amBallgun, HHGear^.Angle);

    if (GameTicks and $FF) = 0 then
        begin
        if (HHGear^.Message and gmRight) <> 0 then
            begin
            if HHGear^.dX.isNegative and (Gear^.Tag < 20) then
                inc(Gear^.Tag)
            else if Gear^.Tag > 5 then
                dec(Gear^.Tag);
            end
        else if (HHGear^.Message and gmLeft) <> 0 then
            begin
            if HHGear^.dX.isNegative and (Gear^.Tag > 5) then
                dec(Gear^.Tag)
            else if Gear^.Tag < 20 then
                inc(Gear^.Tag);
            end
        end;

    dec(Gear^.Timer);
    if Gear^.Timer = 0 then
        begin
        dec(Gear^.Health);
        if (Gear^.Health mod 5) = 0 then
            begin
            rx := rndSign(getRandomf * _0_1);
            ry := rndSign(getRandomf * _0_1);
            speed := _0_5 * (_10 / Gear^.Tag);

            flame:= AddGear(gx, gy, gtFlame, gstTmpFlag,
                    SignAs(AngleSin(HHGear^.Angle) * speed, HHGear^.dX) + rx,
                    AngleCos(HHGear^.Angle) * ( - speed) + ry, 0);
            flame^.CollisionMask:= lfNotCurrentMask;
            //flame^.FlightTime:= 500;  use the default huge value to avoid sticky flame suddenly being damaging as opposed to other flames

            if (Gear^.Health mod 30) = 0 then
                begin
                flame:= AddGear(gx, gy, gtFlame, 0,
                        SignAs(AngleSin(HHGear^.Angle) * speed, HHGear^.dX) + rx,
                        AngleCos(HHGear^.Angle) * ( - speed) + ry, 0);
                flame^.CollisionMask:= lfNotCurrentMask;
		//flame^.FlightTime:= 500;
                end
            end;
        Gear^.Timer:= Gear^.Tag
        end;

    if (Gear^.Health = 0) or ((HHGear^.State and gstHHDriven) = 0) then
        begin
        HHGear^.State := HHGear^.State and (not gstNotKickable);
        DeleteGear(Gear);
        AfterAttack
        end
    else
        begin
        i:= Gear^.Health div 5;
        if (i <> Gear^.Damage) and ((GameTicks and $3F) = 0) then
            begin
            Gear^.Damage:= i;
            FreeAndNilTexture(Gear^.Tex);
            Gear^.Tex := RenderStringTex(trmsg[sidFuel] + ansistring(': ' + inttostr(i) +
                         '%'), cWhiteColor, fntSmall)
            end
        end
end;

procedure doStepFlamethrower(Gear: PGear);
var
    HHGear: PGear;
begin
    HHGear := Gear^.Hedgehog^.Gear;
    HHGear^.Message := HHGear^.Message and (not (gmUp or gmDown or gmLeft or gmRight));
    HHGear^.State := HHGear^.State or gstNotKickable;
    Gear^.doStep := @doStepFlamethrowerWork
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepLandGunWork(Gear: PGear);
var
    HHGear, land: PGear;
    rx, ry, speed: hwFloat;
    i, gX, gY: LongInt;
begin
    AllInactive := false;
    HHGear := Gear^.Hedgehog^.Gear;
    if HHGear = nil then
        begin
        DeleteGear(gear);
        exit
        end;
    HedgehogChAngle(HHGear);
    gX := hwRound(Gear^.X) + GetLaunchX(amBallgun, hwSign(HHGear^.dX), HHGear^.Angle);
    gY := hwRound(Gear^.Y) + GetLaunchY(amBallgun, HHGear^.Angle);

    if (GameTicks and $FF) = 0 then
        begin
        if (HHGear^.Message and gmRight) <> 0 then
            begin
            if HHGear^.dX.isNegative and (Gear^.Tag < 20) then
                inc(Gear^.Tag)
            else if Gear^.Tag > 5 then
                dec(Gear^.Tag);
            end
        else if (HHGear^.Message and gmLeft) <> 0 then
            begin
            if HHGear^.dX.isNegative and (Gear^.Tag > 5) then
                dec(Gear^.Tag)
            else if Gear^.Tag < 20 then
                inc(Gear^.Tag);
            end
        end;

    dec(Gear^.Timer);
    if Gear^.Timer = 0 then
        begin
        dec(Gear^.Health);

        rx := rndSign(getRandomf * _0_1);
        ry := rndSign(getRandomf * _0_1);
        speed := (_3 / Gear^.Tag);

        land:= AddGear(gx, gy, gtFlake, gstTmpFlag,
                SignAs(AngleSin(HHGear^.Angle) * speed, HHGear^.dX) + rx,
                AngleCos(HHGear^.Angle) * ( - speed) + ry, 0);
        land^.CollisionMask:= lfNotCurrentMask;

        Gear^.Timer:= Gear^.Tag
        end;

    if (Gear^.Health = 0) or ((HHGear^.State and gstHHDriven) = 0) or ((HHGear^.Message and gmAttack) <> 0) then
        begin
        HHGear^.Message:= HHGear^.Message and (not gmAttack);
        HHGear^.State := HHGear^.State and (not gstNotKickable);
        DeleteGear(Gear);
        AfterAttack
        end
    else
        begin
        i:= Gear^.Health div 10;
        if (i <> Gear^.Damage) and ((GameTicks and $3F) = 0) then
            begin
            Gear^.Damage:= i;
            FreeAndNilTexture(Gear^.Tex);
            Gear^.Tex := RenderStringTex(trmsg[sidFuel] + ansistring(': ' + inttostr(i) +
                         '%'), cWhiteColor, fntSmall)
            end
        end
end;

procedure doStepLandGun(Gear: PGear);
var
    HHGear: PGear;
begin
    HHGear := Gear^.Hedgehog^.Gear;
    HHGear^.Message := HHGear^.Message and (not (gmUp or gmDown or gmLeft or gmRight or gmAttack));
    HHGear^.State := HHGear^.State or gstNotKickable;
    Gear^.doStep := @doStepLandGunWork
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepPoisonCloud(Gear: PGear);
begin
    // don't bounce
    if WorldEdge <> weBounce then
        WorldWrap(Gear);
    if Gear^.Timer = 0 then
        begin
        DeleteGear(Gear);
        exit
        end;
    dec(Gear^.Timer);
    Gear^.X:= Gear^.X + Gear^.dX;
    Gear^.Y:= Gear^.Y + Gear^.dY;
    Gear^.dX := Gear^.dX + cWindSpeed / 4;
    Gear^.dY := Gear^.dY + cGravity / 100;
    if (GameTicks and $FF) = 0 then
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLDontDraw or EXPLNoGfx or EXPLNoDamage or EXPLDoNotTouchAny or EXPLPoisoned);
    if Gear^.State and gstTmpFlag = 0 then
        AllInactive:= false;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepHammer(Gear: PGear);
var HHGear, tmp, tmp2: PGear;
         t: PGearArray;
    i, dmg: LongInt;
begin
HHGear:= Gear^.Hedgehog^.Gear;
HHGear^.State:= HHGear^.State or gstNoDamage;
DeleteCI(HHGear);
SetLittle(HHGear^.dY);
HHGear^.dY.IsNegative:= true;
HHGear^.State:= HHGear^.State or gstMoving;

t:= CheckGearsCollision(Gear);

for i:= 5 downto 0 do
    AddVisualGear(hwRound(Gear^.X) - 5 + Random(10), hwRound(Gear^.Y) + 12, vgtDust);

i:= t^.Count;
while i > 0 do
    begin
    dec(i);
    tmp:= t^.ar[i];
    if (tmp^.State and gstNoDamage) = 0 then
        if (tmp^.Kind = gtHedgehog) or (tmp^.Kind = gtMine) or (tmp^.Kind = gtExplosives) then
            begin
            dmg:= 0;
            //tmp^.State:= tmp^.State or gstFlatened;
            if (tmp^.Kind <> gtHedgehog) or (tmp^.Hedgehog^.Effects[heInvulnerable] = 0) then
                begin
                // base damage on remaining health
                dmg:= (tmp^.Health - tmp^.Damage);
                if dmg > 0 then
                    begin
                    // always rounding down
                    dmg:= dmg div Gear^.Boom;

                    if dmg > 0 then
                        ApplyDamage(tmp, CurrentHedgehog, dmg, dsUnknown);
                    end;
		tmp^.dY:= _0_03 * Gear^.Boom
                end;

            if (tmp^.Kind <> gtHedgehog) or (dmg > 0) or (tmp^.Health > tmp^.Damage) then
                begin
                //DrawTunnel(tmp^.X, tmp^.Y - _1, _0, _0_5, cHHRadius * 6, cHHRadius * 3);
                tmp2:= AddGear(hwRound(tmp^.X), hwRound(tmp^.Y), gtHammerHit, 0, _0, _0, 0);
                tmp2^.LinkedGear:= tmp;
                SetAllToActive
                end;
            end;
    end;

HHGear^.State:= HHGear^.State and (not gstNoDamage);
Gear^.Timer:= 250;
Gear^.doStep:= @doStepIdle
end;

procedure doStepHammerHitWork(Gear: PGear);
var
    i, j, ei: LongInt;
    HitGear: PGear;
begin
    AllInactive := false;
    HitGear := Gear^.LinkedGear;
    dec(Gear^.Timer);
    if (HitGear = nil) or (Gear^.Timer = 0) or ((Gear^.Message and gmDestroy) <> 0) then
        begin
        DeleteGear(Gear);
        exit
        end;

    if (Gear^.Timer mod 5) = 0 then
        begin
        AddVisualGear(hwRound(Gear^.X) - 5 + Random(10), hwRound(Gear^.Y) + 12, vgtDust);

        i := hwRound(Gear^.X) - HitGear^.Radius + 2;
        ei := hwRound(Gear^.X) + HitGear^.Radius - 2;
        for j := 1 to 4 do DrawExplosion(i - GetRandom(5), hwRound(Gear^.Y) + 6*j, 3);
        for j := 1 to 4 do DrawExplosion(ei + LongInt(GetRandom(5)), hwRound(Gear^.Y) + 6*j, 3);
        while i <= ei do
            begin
            for j := 1 to 11 do DrawExplosion(i, hwRound(Gear^.Y) + 3*j, 3);
            inc(i, 1)
            end;

        if CheckLandValue(hwRound(Gear^.X + Gear^.dX + SignAs(_6,Gear^.dX)), hwRound(Gear^.Y + _1_9)
           , lfIndestructible) then
            begin
            //Gear^.X := Gear^.X + Gear^.dX;
            Gear^.Y := Gear^.Y + _1_9
            end;
        end;
    if TestCollisionYwithGear(Gear, 1) <> 0 then
        begin
        Gear^.dY := _0;
        SetLittle(HitGear^.dX);
        HitGear^.dY := _0;
        end
    else
        begin
        //Gear^.dY := Gear^.dY + cGravity;
        //Gear^.Y := Gear^.Y + Gear^.dY;
        if CheckCoordInWater(hwRound(Gear^.X), hwRound(Gear^.Y)) then
            Gear^.Timer := 1
        end;

    //Gear^.X := Gear^.X + HitGear^.dX;
    HitGear^.X := Gear^.X;
    HitGear^.Y := Gear^.Y;
    SetLittle(HitGear^.dY);
    HitGear^.Active:= true;
end;

procedure doStepHammerHit(Gear: PGear);
var
    i, y: LongInt;
    ar: TRangeArray;
    HHGear: PGear;
begin
    i := 0;
    HHGear := Gear^.Hedgehog^.Gear;

    y := hwRound(Gear^.Y) - cHHRadius * 2;
    while y < hwRound(Gear^.Y) do
        begin
        ar[i].Left := hwRound(Gear^.X) - Gear^.Radius - LongInt(GetRandom(2));
        ar[i].Right := hwRound(Gear^.X) + Gear^.Radius + LongInt(GetRandom(2));
        inc(y, 2);
        inc(i)
        end;

    DrawHLinesExplosions(@ar, 3, hwRound(Gear^.Y) - cHHRadius * 2, 2, Pred(i));
    Gear^.dY := HHGear^.dY;
    DeleteCI(HHGear);

    doStepHammerHitWork(Gear);
    Gear^.doStep := @doStepHammerHitWork
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepResurrectorWork(Gear: PGear);
var
    graves: PGearArrayS;
    resgear: PGear;
    hh: PHedgehog;
    i: LongInt;
    s: ansistring;
begin
    if (TurnTimeLeft > 0) then
        dec(TurnTimeLeft);

    AllInactive := false;
    hh := Gear^.Hedgehog;

    // no, you can't do that here
    {DrawCentered(hwRound(hh^.Gear^.X) + WorldDx, hwRound(hh^.Gear^.Y) + WorldDy -
            cHHRadius - 14 - hh^.HealthTagTex^.h, hh^.HealthTagTex);
    }
    (*DrawCircle(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Radius, 1.5, 0, 0, $FF,
            $FF);*)

    if ((Gear^.Message and gmUp) <> 0) then
        begin
        if (GameTicks and $F) <> 0 then
        exit;
        end
    else if (GameTicks and $1FF) <> 0 then
        exit;

    if Gear^.Power < 45 then
        begin
        inc(Gear^.Power);
        if TestCollisionYwithGear(hh^.Gear, -1) = 0 then
            hh^.Gear^.Y := hh^.Gear^.Y - _1;
        end;

    graves := GearsNear(Gear^.X, Gear^.Y, gtGrave, Gear^.Radius);

    if graves.size = 0 then
        begin
        StopSoundChan(Gear^.SoundChannel);
        Gear^.Timer := 250;
        Gear^.doStep := @doStepIdle;
        exit;
        end;

    if ((Gear^.Message and gmAttack) <> 0) and (hh^.Gear^.Health > 0) and (TurnTimeLeft > 0) then
        begin
        if LongInt(graves.size) <= Gear^.Tag then Gear^.Tag:= 0;
        dec(hh^.Gear^.Health);
        if (hh^.Gear^.Health = 0) and (hh^.Gear^.Damage = 0) then
            hh^.Gear^.Damage:= 1;
        RenderHealth(hh^);
        RecountTeamHealth(hh^.Team);
        inc(graves.ar^[Gear^.Tag]^.Health);
        inc(Gear^.Tag)
{-for i:= 0 to High(graves) do begin
            if hh^.Gear^.Health > 0 then begin
                dec(hh^.Gear^.Health);
                inc(graves[i]^.Health);
            end;
        end; -}
        end
    else
        begin
        // now really resurrect the hogs with the hp saved in the graves
        for i:= 0 to graves.size - 1 do
            if graves.ar^[i]^.Health > 0 then
                begin
                resgear := AddGear(hwRound(graves.ar^[i]^.X), hwRound(graves.ar^[i]^.Y), gtHedgehog, gstWait, _0, _0, 0,graves.ar^[i]^.Pos);
                resgear^.Hedgehog := graves.ar^[i]^.Hedgehog;
                resgear^.Health := graves.ar^[i]^.Health;
                PHedgehog(graves.ar^[i]^.Hedgehog)^.Gear := resgear;
                graves.ar^[i]^.Message:= graves.ar^[i]^.Message or gmDestroy;
                graves.ar^[i]^.Active:= true;
                RenderHealth(resgear^.Hedgehog^);
                RecountTeamHealth(resgear^.Hedgehog^.Team);
                resgear^.Hedgehog^.Effects[heResurrected]:= 1;
                s:= ansistring(resgear^.Hedgehog^.Name);
                AddCaption(FormatA(GetEventString(eidResurrected), s), cWhiteColor, capgrpMessage);
                // only make hat-less hedgehogs look like zombies, preserve existing hats

                if resgear^.Hedgehog^.Hat = 'NoHat' then
                    LoadHedgehogHat(resgear^.Hedgehog^, 'Reserved/Zombie');
                end;

        hh^.Gear^.dY := _0;
        hh^.Gear^.dX := _0;
        doStepHedgehogMoving(hh^.Gear);
        StopSoundChan(Gear^.SoundChannel);
        Gear^.Timer := 250;
        Gear^.doStep := @doStepIdle;
        end
    //if hh^.Gear^.Health = 0 then doStepHedgehogFree(hh^.Gear);
end;

procedure doStepResurrector(Gear: PGear);
var
    graves: PGearArrayS;
    hh: PHedgehog;
    i: LongInt;
begin
    AllInactive := false;
    graves := GearsNear(Gear^.X, Gear^.Y, gtGrave, Gear^.Radius);

    if graves.size > 0 then
        begin
        hh := Gear^.Hedgehog;
        for i:= 0 to graves.size - 1 do
            begin
            PHedgehog(graves.ar^[i]^.Hedgehog)^.Gear := nil;
            graves.ar^[i]^.Health := 0;
            end;
        Gear^.doStep := @doStepResurrectorWork;
        if ((Gear^.Message and gmAttack) <> 0) and (hh^.Gear^.Health > 0) and (TurnTimeLeft > 0) then
            begin
            if LongInt(graves.size) <= Gear^.Tag then Gear^.Tag:= 0;
            dec(hh^.Gear^.Health);
            if (hh^.Gear^.Health = 0) and (hh^.Gear^.Damage = 0) then
                hh^.Gear^.Damage:= 1;
            RenderHealth(hh^);
            RecountTeamHealth(hh^.Team);
            inc(graves.ar^[Gear^.Tag]^.Health);
            inc(Gear^.Tag)
            end
        end
    else
        begin
        StopSoundChan(Gear^.SoundChannel);
        Gear^.Timer := 250;
        Gear^.doStep := @doStepIdle;
        end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepNapalmBomb(Gear: PGear);
var
    i, gX, gY: LongInt;
    dX, dY: hwFloat;
begin
    AllInactive := false;
    doStepFallingGear(Gear);
    if (Gear^.Timer > 0) and ((Gear^.State and gstCollision) <> 0) then
    begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 10, Gear^.Hedgehog, EXPLAutoSound);
        gX := hwRound(Gear^.X);
        gY := hwRound(Gear^.Y);
        for i:= 0 to 10 do
        begin
            dX := AngleCos(i * 2) * ((_0_1*(i div 5))) * (GetRandomf + _1);
            dY := AngleSin(i * 8) * _0_5 * (GetRandomf + _1);
            AddGear(gX, gY, gtFlame, 0, dX, dY, 0);
            AddGear(gX, gY, gtFlame, 0, dX, -dY, 0);
            AddGear(gX, gY, gtFlame, 0, -dX, dY, 0);
            AddGear(gX, gY, gtFlame, 0, -dX, -dY, 0);
        end;
        DeleteGear(Gear);
        exit
    end;
    if (Gear^.Timer = 0) then
        begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 10, Gear^.Hedgehog, EXPLAutoSound);
        for i:= -19 to 19 do
           FollowGear := AddGear(hwRound(Gear^.X) + i div 3, hwRound(Gear^.Y), gtFlame, 0, _0_001 * i, _0, 0);
        DeleteGear(Gear);
        exit
        end;
    if (GameTicks and $3F) = 0 then
        AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtSmokeTrace);
    dec(Gear^.Timer)
end;

(*
////////////////////////////////////////////////////////////////////////////////
procedure doStepStructure(Gear: PGear);
var
    x, y: LongInt;
    HH: PHedgehog;
    t: PGear;
begin
    HH:= Gear^.Hedgehog;

    if (Gear^.State and gstMoving) <> 0 then
        begin
        AddCI(Gear);
        Gear^.dX:= _0;
        Gear^.dY:= _0;
        Gear^.State:= Gear^.State and (not gstMoving);
        end;

    dec(Gear^.Health, Gear^.Damage);
    Gear^.Damage:= 0;

    if Gear^.Pos = 1 then
        begin
        AddCI(Gear);
        AfterAttack;
        if Gear = CurAmmoGear then
            CurAmmoGear:= nil;
        if HH^.Gear <> nil then
            HideHog(HH);
        Gear^.Pos:= 2
        end;

    if Gear^.Pos = 2 then
        begin
        if ((GameTicks mod 100) = 0) and (Gear^.Timer < 1000) then
            begin
            if (Gear^.Timer mod 10) = 0 then
                begin
                DeleteCI(Gear);
                Gear^.Y:= Gear^.Y - _0_5;
                AddCI(Gear);
                end;
            inc(Gear^.Timer);
            end;
        if Gear^.Tag <= TotalRounds then
            Gear^.Pos:= 3;
        end;

    if Gear^.Pos = 3 then
        if Gear^.Timer < 1000 then
            begin
            if (Gear^.Timer mod 10) = 0 then
                begin
                DeleteCI(Gear);
                Gear^.Y:= Gear^.Y - _0_5;
                AddCI(Gear);
                end;
            inc(Gear^.Timer);
            end
        else
            begin
            if HH^.GearHidden <> nil then
                RestoreHog(HH);
            Gear^.Pos:= 4;
            end;

    if Gear^.Pos = 4 then
        if ((GameTicks mod 1000) = 0) and ((GameFlags and gfInvulnerable) = 0) then
            begin
            t:= GearsList;
            while t <> nil do
                begin
                if (t^.Kind = gtHedgehog) and (t^.Hedgehog^.Team^.Clan = HH^.Team^.Clan) then
                    t^.Hedgehog^.Effects[heInvulnerable]:= 1;
                t:= t^.NextGear;
                end;
            end;

    if Gear^.Health <= 0 then
        begin
        if HH^.GearHidden <> nil then
            RestoreHog(HH);

        x := hwRound(Gear^.X);
        y := hwRound(Gear^.Y);

        DeleteCI(Gear);
        DeleteGear(Gear);

        doMakeExplosion(x, y, 50, CurrentHedgehog, EXPLAutoSound);
        end;
end;
*)

////////////////////////////////////////////////////////////////////////////////
(*
 TARDIS needs
 Warp in.  Pos = 1
 Pause.    Pos = 2
 Hide gear  (TARDIS hedgehog was nil)
 Warp out. Pos = 3
 ... idle active for some time period ...  Pos = 4
 Warp in.  Pos = 1
 Pause.    Pos = 2
 Restore gear  (TARDIS hedgehog was not nil)
 Warp out. Pos = 3
*)

procedure doStepTardisWarp(Gear: PGear);
var HH: PHedgehog;
    i,j,cnt: LongWord;
    s: ansistring;
begin
HH:= Gear^.Hedgehog;
if Gear^.Pos = 2 then
    begin
    StopSoundChan(Gear^.SoundChannel);
    Gear^.SoundChannel:= -1;
    if (Gear^.Timer = 0) then
        begin
        if (HH^.Gear <> nil) and (HH^.Gear^.State and gstInvisible = 0) then
            begin
            AfterAttack;
            if Gear = CurAmmoGear then CurAmmoGear := nil;
            if (HH^.Gear^.Damage = 0) and  (HH^.Gear^.Health > 0) and
            ((Gear^.State and (gstMoving or gstHHDeath or gstHHGone)) = 0) then
                HideHog(HH)
            end
        //else if (HH^.Gear <> nil) and (HH^.Gear^.State and gstInvisible <> 0) then
        else if (HH^.GearHidden <> nil) then// and (HH^.Gear^.State and gstInvisible <> 0) then
            begin
            RestoreHog(HH);
            s:= ansistring(HH^.Name);
            AddCaption(FormatA(GetEventString(eidTimeTravelEnd), s), cWhiteColor, capgrpMessage)
            end
        end;

    inc(Gear^.Timer);
    if (Gear^.Timer > 2000) and ((GameTicks mod 2000) = 1000) then
        begin
        Gear^.SoundChannel := LoopSound(sndTardis);
        Gear^.Pos:= 3
        end
    end;

if (Gear^.Pos = 1) and (GameTicks and $1F = 0) and (Gear^.Power < 255) then
    begin
    inc(Gear^.Power);
    if (Gear^.Power = 172) and (HH^.Gear <> nil) and
        (HH^.Gear^.Damage = 0) and (HH^.Gear^.Health > 0) and
        ((HH^.Gear^.State and (gstMoving or gstHHDeath or gstHHGone)) = 0) then
            with HH^.Gear^ do
                begin
                State:= State or gstAnimation;
                Tag:= 2;
                Timer:= 0;
                Pos:= 0
                end
    end;
if (Gear^.Pos = 3) and (GameTicks and $1F = 0) and (Gear^.Power > 0) then
    dec(Gear^.Power);
if (Gear^.Pos = 1) and (Gear^.Power = 255) and ((GameTicks mod 2000) = 1000) then
    Gear^.Pos:= 2;
if (Gear^.Pos = 3) and (Gear^.Power = 0) then
    begin
    StopSoundChan(Gear^.SoundChannel);
    Gear^.SoundChannel:= -1;
    if HH^.GearHidden = nil then
        begin
        DeleteGear(Gear);
        exit
        end;
    Gear^.Pos:= 4;
    // This condition might need tweaking
    Gear^.Timer:= GetRandom(cHedgehogTurnTime*TeamsCount)+cHedgehogTurnTime
    end;

if (Gear^.Pos = 4) then
    begin
    cnt:= 0;
    for j:= 0 to Pred(HH^.Team^.Clan^.TeamsNumber) do
        with HH^.Team^.Clan^.Teams[j]^ do
            for i:= 0 to Pred(HedgehogsNumber) do
                if (Hedgehogs[i].Gear <> nil)
                and ((Hedgehogs[i].Gear^.State and gstDrowning) = 0)
                and (Hedgehogs[i].Gear^.Health > Hedgehogs[i].Gear^.Damage) then
                    inc(cnt);
    if (cnt = 0) or SuddenDeathDmg or (Gear^.Timer = 0) then
        begin
        if HH^.GearHidden <> nil then
            FindPlace(HH^.GearHidden, false, 0, LAND_WIDTH,true);

        if HH^.GearHidden <> nil then
            begin
            Gear^.X:= HH^.GearHidden^.X;
            Gear^.Y:= HH^.GearHidden^.Y;
            end;
        Gear^.Timer:= 0;

        if (HH^.GearHidden <> nil) and (cnt = 0) then // do an emergency jump back in this case. the team needs you!
            begin
            AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtExplosion);
            Gear^.Pos:= 2;
            Gear^.Power:= 255;
            end
        else begin
            Gear^.SoundChannel := LoopSound(sndTardis);
            Gear^.Pos:= 1;
            Gear^.Power:= 0;
            end
        end
    else if (CurrentHedgehog^.Team^.Clan = Gear^.Hedgehog^.Team^.Clan) then dec(Gear^.Timer)
    end;

end;

procedure doStepTardis(Gear: PGear);
var i,j,cnt: LongWord;
    HH: PHedgehog;
begin
(*
    Conditions for not activating.
    1. Hog is last of his clan
    2. Sudden Death is in play
    3. Hog is a king
*)
    HH:= Gear^.Hedgehog;
    if HH^.Gear <> nil then
    if (HH^.Gear = nil) or (HH^.King) or (SuddenDeathDmg) then
        begin
        if HH^.Gear <> nil then
            begin
            HH^.Gear^.Message := HH^.Gear^.Message and (not gmAttack);
            HH^.Gear^.State:= HH^.Gear^.State and (not gstAttacking);
            end;
        PlaySound(sndDenied);
        DeleteGear(gear);
        exit
        end;
    cnt:= 0;
    for j:= 0 to Pred(HH^.Team^.Clan^.TeamsNumber) do
        for i:= 0 to Pred(HH^.Team^.Clan^.Teams[j]^.HedgehogsNumber) do
            if (HH^.Team^.Clan^.Teams[j]^.Hedgehogs[i].Gear <> nil)
            and ((HH^.Team^.Clan^.Teams[j]^.Hedgehogs[i].Gear^.State and gstDrowning) = 0)
            and (HH^.Team^.Clan^.Teams[j]^.Hedgehogs[i].Gear^.Health > HH^.Team^.Clan^.Teams[j]^.Hedgehogs[i].Gear^.Damage) then
                inc(cnt);
    if cnt < 2 then
        begin
        if HH^.Gear <> nil then
            begin
            HH^.Gear^.Message := HH^.Gear^.Message and (not gmAttack);
            HH^.Gear^.State:= HH^.Gear^.State and (not gstAttacking);
            end;
            PlaySound(sndDenied);
            DeleteGear(gear);
            exit
        end;
    Gear^.SoundChannel := LoopSound(sndTardis);
    Gear^.doStep:= @doStepTardisWarp
end;

////////////////////////////////////////////////////////////////////////////////

(*
WIP. The ice gun will have the following effects.  It has been proposed by sheepluva that it take the appearance of a large freezer
spewing ice cubes.  The cubes will be visual gears only.  The scatter from them and the impact snow dust should help hide imprecisions in things like the GearsNear effect.
For now we assume a "ray" like a deagle projected out from the gun.
All these effects assume the ray's angle is not changed and that the target type was unchanged over a number of ticks.  This is a simplifying assumption for "gun was applying freezing effect to the same target".
  * When fired at water a layer of ice textured land is added above the water.
  * When fired at non-ice land (land and lfLandMask and not lfIce) the land is overlaid with a thin layer of ice textured land around that point (say, 1 or 2px into land, 1px above). For attractiveness, a slope would probably be needed.
  * When fired at a hog (land and $00FF <> 0), while the hog is targetted, the hog's state is set to frozen.
    As long as the gun is on the hog, a frozen hog sprite creeps up from the feet to the head.
    If the effect is interrupted before reaching the top, the freezing state is cleared.
A frozen hog will animate differently.
    To be decided, but possibly in a similar fashion to a grave when it comes to explosions.
    The hog might (possibly) not be damaged by explosions.
    This might make freezing potentially useful for friendlies in a bad position.
    It might be better to allow damage though.
A frozen hog stays frozen for a certain number of turns.
    Each turn the frozen overlay becomes fainter, until it fades and the hog animates normally again.
*)


procedure updateFuel(Gear: PGear);
var
  t:LongInt;
begin
    t:= Gear^.Health div 10;
    if (t <> Gear^.Damage) and ((GameTicks and $3F) = 0) then
    begin
    Gear^.Damage:= t;
    FreeAndNilTexture(Gear^.Tex);
    Gear^.Tex := RenderStringTex(trmsg[sidFuel] + ansistring(': ' + inttostr(t) +
              '%'), cWhiteColor, fntSmall)
    end;
    if Gear^.Message and (gmUp or gmDown) <> 0 then
        begin
        StopSoundChan(Gear^.SoundChannel);
        Gear^.SoundChannel:= -1;
        if GameTicks mod 40 = 0 then dec(Gear^.Health)
        end
    else
        begin
        if Gear^.SoundChannel = -1 then
            Gear^.SoundChannel := LoopSound(sndIceBeam);
        if GameTicks mod 10 = 0 then dec(Gear^.Health)
        end
end;


procedure updateTarget(Gear:PGear; newX, newY:HWFloat);
//    var
//    iter:PGear;
begin
  with Gear^ do
  begin
    dX:= newX;
    dY:= newY;
    Pos:= 0;
    Target.X:= NoPointX;
    LastDamage:= nil;
    X:= Hedgehog^.Gear^.X;
    Y:= Hedgehog^.Gear^.Y;
  end;
end;

procedure doStepIceGun(Gear: PGear);
const iceWaitCollision = 0;
const iceCollideWithGround = 1;
//const iceWaitNextTarget:Longint = 2;
//const iceCollideWithHog:Longint = 4;
const iceCollideWithWater = 5;
//const waterFreezingTime:Longint = 500;
const groundFreezingTime = 1000;
const iceRadius = 32;
const iceHeight = 40;
var
    HHGear, iter: PGear;
    landRect: TSDL_Rect;
    ndX, ndY: hwFloat;
    i, t, gX, gY: LongInt;
    hogs: PGearArrayS;
    vg: PVisualGear;
begin
    HHGear := Gear^.Hedgehog^.Gear;
    if (Gear^.Message and gmAttack <> 0) or (Gear^.Health = 0) or (HHGear = nil) or ((HHGear^.State and gstHHDriven) = 0) or (HHGear^.dX.QWordValue > 4294967)  then
        begin
        StopSoundChan(Gear^.SoundChannel);
        DeleteGear(Gear);
        AfterAttack;
        exit
        end;
    updateFuel(Gear);

    with Gear^ do
        begin
        HedgehogChAngle(HHGear);
        ndX:= SignAs(AngleSin(HHGear^.Angle), HHGear^.dX) * _4;
        ndY:= -AngleCos(HHGear^.Angle) * _4;
        if (ndX <> dX) or (ndY <> dY) or
           ((Target.X <> NoPointX) and (Target.X and LAND_WIDTH_MASK = 0) and
             (Target.Y and LAND_HEIGHT_MASK = 0) and ((Land[Target.Y, Target.X] = 0)) and
             (not CheckCoordInWater(Target.X, Target.Y))) then
            begin
            updateTarget(Gear, ndX, ndY);
            Timer := iceWaitCollision;
            end
        else
            begin
            X:= X + dX;
            Y:= Y + dY;
            gX:= hwRound(X);
            gY:= hwRound(Y);
            if Target.X = NoPointX then t:= hwRound(hwSqr(X-HHGear^.X)+hwSqr(Y-HHGear^.Y));

            if Target.X <> NoPointX then
                begin
                CheckCollision(Gear);
                if (State and gstCollision) <> 0 then
                    begin
                    if Timer = iceWaitCollision then
                        begin
                        Timer := iceCollideWithGround;
                        Power := GameTicks;
                        end
                    end
                else if CheckCoordInWater(Target.X, Target.Y) or
                        ((Target.X and LAND_WIDTH_MASK  = 0) and
                         (Target.Y and LAND_HEIGHT_MASK = 0) and
                         (Land[Target.Y, Target.X] = lfIce) and
                         ((Target.Y+iceHeight+5 > cWaterLine) or
                          ((WorldEdge = weSea) and
                           ((Target.X+iceHeight+5 > LongInt(rightX)) or
                            (Target.X-iceHeight-5 < LongInt(leftX)))))
                         ) then
                    begin
                    if Timer = iceWaitCollision then
                        begin
                        Timer := iceCollideWithWater;
                        Power := GameTicks;
                        end;
                    end;

                if (abs(gX-Target.X) < 2) and (abs(gY-Target.Y) < 2) then
                    begin
                    X:= HHGear^.X;
                    Y:= HHGear^.Y
                    end;

                if (Timer = iceCollideWithGround) and ((GameTicks - Power) > groundFreezingTime) then
                    begin
                    FillRoundInLandFT(target.x, target.y, iceRadius, icePixel);
                    landRect.x := min(max(target.x - iceRadius, 0), LAND_WIDTH - 1);
                    landRect.y := min(max(target.y - iceRadius, 0), LAND_HEIGHT - 1);
                    landRect.w := min(2*iceRadius, LAND_WIDTH - landRect.x - 1);
                    landRect.h := min(2*iceRadius, LAND_HEIGHT - landRect.y - 1);
                    UpdateLandTexture(landRect.x, landRect.w, landRect.y, landRect.h, true);

                    // Freeze nearby mines/explosives/cases too
                    iter := GearsList;
                    while iter <> nil do
                        begin
                        if (iter^.State and gstFrozen = 0) and
                           ((iter^.Kind = gtExplosives) or (iter^.Kind = gtCase) or (iter^.Kind = gtMine) or (iter^.Kind = gtSMine)) and
                           (abs(LongInt(iter^.X.Round) - target.x) + abs(LongInt(iter^.Y.Round) - target.y) + 2 < 2 * iceRadius)
                           and (Distance(iter^.X - int2hwFloat(target.x), iter^.Y - int2hwFloat(target.y)) < int2hwFloat(iceRadius * 2)) then
                            begin
                            for t:= 0 to 5 do
                                begin
                                vg:= AddVisualGear(hwRound(iter^.X)+random(4)-8, hwRound(iter^.Y)+random(8), vgtDust, 1);
                                if vg <> nil then
                                    begin
                                    i:= random(100) + 155;
                                    vg^.Tint:= (i shl 24) or (i shl 16) or ($FF shl 8) or (random(200) + 55);
                                    vg^.Angle:= random(360);
                                    vg^.dx:= 0.001 * random(80);
                                    vg^.dy:= 0.001 * random(80)
                                    end
                                end;
                            PlaySound(sndHogFreeze);
                            if iter^.Kind = gtMine then // dud mine block
                                begin
                                iter^.State:= iter^.State or gstFrozen;
                                vg:= AddVisualGear(hwRound(iter^.X) - 4  + Random(8), hwRound(iter^.Y) - 4 - Random(4), vgtSmoke);
                                if vg <> nil then
                                    vg^.Scale:= 0.5;
                                PlaySound(sndVaporize);
                                iter^.Health := 0;
                                iter^.Damage := 0;
                                iter^.State := iter^.State and (not gstAttacking)
                                end
                            else if iter^.Kind = gtSMine then // disabe sticky mine and drop it into the water
                                begin
                                iter^.State:= iter^.State or gstFrozen;
                                iter^.CollisionMask:= 0;
                                vg:= AddVisualGear(hwRound(iter^.X) - 2  + Random(4), hwRound(iter^.Y) - 2 - Random(2), vgtSmoke);
                                if vg <> nil then
                                    vg^.Scale:= 0.4;
                                PlaySound(sndVaporize);
                                iter^.State := iter^.State and (not gstAttacking)
                                end
                            else if iter^.Kind = gtCase then
                                begin
                                DeleteCI(iter);
                                iter^.State:= iter^.State or gstFrozen;
                                AddCI(iter)
                                end
                            else // gtExplosives
                                begin
                                iter^.State:= iter^.State or gstFrozen;
                                iter^.Health:= iter^.Health + cBarrelHealth
                                end
                            end;
                        iter:= iter^.NextGear
                        end;

                    // FillRoundInLandWithIce(Target.X, Target.Y, iceRadius);
                    SetAllHHToActive;
                    Timer := iceWaitCollision;
                    end;

                if (Timer = iceCollideWithWater) and ((GameTicks - Power) > groundFreezingTime div 2) then
                    begin
                    PlaySound(sndHogFreeze);
                    if CheckCoordInWater(Target.X, Target.Y) then
                        DrawIceBreak(Target.X, Target.Y, iceRadius, iceHeight)
                    else if Target.Y+iceHeight+5 > cWaterLine then
                        DrawIceBreak(Target.X, Target.Y+iceHeight+5, iceRadius, iceHeight)
                    else if Target.X+iceHeight+5 > LongInt(rightX) then
                        DrawIceBreak(Target.X+iceHeight+5, Target.Y, iceRadius, iceHeight)
                    else
                        DrawIceBreak(Target.X-iceHeight-5, Target.Y, iceRadius, iceHeight);
                    SetAllHHToActive;
                    Timer := iceWaitCollision;
                    end;
(*
 Any ideas for something that would look good here?
                if (Target.X <> NoPointX) and ((Timer = iceCollideWithGround) or (Timer = iceCollideWithWater)) and (GameTicks mod max((groundFreezingTime-((GameTicks - Power)*2)),2) = 0) then //and CheckLandValue(Target.X, Target.Y, lfIce) then
                    begin
                        vg:= AddVisualGear(Target.X+random(20)-10, Target.Y+random(40)-10, vgtDust, 1);
                        if vg <> nil then
                            begin
                            i:= random(100) + 155;
                            vg^.Tint:= IceColor or $FF;
                            vg^.Angle:= random(360);
                            vg^.dx:= 0.001 * random(80);
                            vg^.dy:= 0.001 * random(80)
                            end
                    end;
*)

// freeze nearby hogs
                hogs := GearsNear(int2hwFloat(Target.X), int2hwFloat(Target.Y), gtHedgehog, Gear^.Radius*2);
                if hogs.size > 0 then
                    for i:= 0 to hogs.size - 1 do
                        if hogs.ar^[i] <> HHGear then
                            if GameTicks mod 5 = 0 then
                                begin
                                hogs.ar^[i]^.Active:= true;
                                if hogs.ar^[i]^.Hedgehog^.Effects[heFrozen] < 256 then
                                    hogs.ar^[i]^.Hedgehog^.Effects[heFrozen] := hogs.ar^[i]^.Hedgehog^.Effects[heFrozen] + 1
                                else if hogs.ar^[i]^.Hedgehog^.Effects[heFrozen] = 256 then
                                    begin
                                    hogs.ar^[i]^.Hedgehog^.Effects[heFrozen]:= 200000-1;//cHedgehogTurnTime + cReadyDelay
                                    PlaySound(sndHogFreeze);
                                    end;
                                end;
                inc(Pos)
                end
            else if (t > 400) and (CheckCoordInWater(gX, gY) or
                    (((gX and LAND_WIDTH_MASK = 0) and (gY and LAND_HEIGHT_MASK = 0))
                        and (Land[gY, gX] <> 0))) then
                begin
                Target.X:= gX;
                Target.Y:= gY;
                X:= HHGear^.X;
                Y:= HHGear^.Y
                end;
            if (gX > max(LAND_WIDTH,4096)*2) or
                    (gX < -max(LAND_WIDTH,4096)) or
                    (gY < -max(LAND_HEIGHT,4096)) or
                    (gY > max(LAND_HEIGHT,4096)+512) then
                begin
                //X:= HHGear^.X;
                //Y:= HHGear^.Y
                Target.X:= gX;
                Target.Y:= gY;
                end
        end
    end;
end;

procedure doStepAddAmmo(Gear: PGear);
var a: TAmmoType;
    gi: PGear;
begin
if Gear^.Timer > 0 then dec(Gear^.Timer)
else
    begin
    if Gear^.Pos = posCaseUtility then
        a:= GetUtility(Gear^.Hedgehog)
    else
        a:= GetAmmo(Gear^.Hedgehog);
    CheckSum:= CheckSum xor GameTicks;
    gi := GearsList;
    while gi <> nil do
        begin
        with gi^ do CheckSum:= CheckSum xor X.round xor X.frac xor dX.round xor dX.frac xor Y.round xor Y.frac xor dY.round xor dY.frac;
        AddRandomness(CheckSum);
        if gi^.Kind = gtGenericFaller then gi^.State:= gi^.State and (not gstTmpFlag);
        gi := gi^.NextGear
        end;
    AddPickup(Gear^.Hedgehog^, a, Gear^.Power, hwRound(Gear^.X), hwRound(Gear^.Y));
    DeleteGear(Gear)
    end;
end;

procedure doStepGenericFaller(Gear: PGear);
begin
if Gear^.Timer < $FFFFFFFF then
    if Gear^.Timer > 0 then
        dec(Gear^.Timer)
    else
        begin
        DeleteGear(Gear);
        exit
        end;
if (Gear^.State and gstTmpFlag <> 0) or (GameTicks and $7 = 0) then
    begin
    doStepFallingGear(Gear);
    if (Gear^.State and gstInvisible <> 0) and (GameTicks and $FF = 0) and (hwRound(Gear^.X) < LongInt(leftX)) or (hwRound(Gear^.X) > LongInt(rightX)) or (hwRound(Gear^.Y) < LongInt(topY)) then
        begin
        Gear^.X:= int2hwFloat(GetRandom(rightX-leftX)+leftX);
        Gear^.Y:= int2hwFloat(GetRandom(LAND_HEIGHT-topY)+topY);
        Gear^.dX:= _90-(GetRandomf*_360);
        Gear^.dY:= _90-(GetRandomf*_360)
        end;
    end
end;
(*
procedure doStepCreeper(Gear: PGear);
var hogs: PGearArrayS;
    HHGear: PGear;
    tdX: hwFloat;
    dir: LongInt;
begin
doStepFallingGear(Gear);
if Gear^.Timer > 0 then dec(Gear^.Timer);
// creeper sleep phase
if (Gear^.Hedgehog = nil) and (Gear^.Timer > 0) then exit;

if Gear^.Hedgehog <> nil then HHGear:= Gear^.Hedgehog^.Gear
else HHGear:= nil;

// creeper boom phase
if (Gear^.State and gstTmpFlag <> 0) then
    begin
    if (Gear^.Timer = 0) then
        begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 300, CurrentHedgehog, EXPLAutoSound);
        DeleteGear(Gear)
        end;
    // ssssss he essssscaped
    if (Gear^.Timer > 250) and ((HHGear = nil) or
            (((abs(HHGear^.X.Round-Gear^.X.Round) + abs(HHGear^.Y.Round-Gear^.Y.Round) + 2) >  180) and
            (Distance(HHGear^.X-Gear^.X,HHGear^.Y-Gear^.Y) > _180))) then
        begin
        Gear^.State:= Gear^.State and (not gstTmpFlag);
        Gear^.Timer:= 0
        end;
    exit
    end;

// Search out a new target, as target seek time has expired, target is dead, target is out of range, or we did not have a target
if (HHGear = nil) or (Gear^.Timer = 0) or
   (((abs(HHGear^.X.Round-Gear^.X.Round) + abs(HHGear^.Y.Round-Gear^.Y.Round) + 2) >  Gear^.Angle) and
        (Distance(HHGear^.X-Gear^.X,HHGear^.Y-Gear^.Y) > int2hwFloat(Gear^.Angle)))
    then
    begin
    hogs := GearsNear(Gear^.X, Gear^.Y, gtHedgehog, Gear^.Angle);
    if hogs.size > 1 then
        Gear^.Hedgehog:= hogs.ar^[GetRandom(hogs.size)]^.Hedgehog
    else if hogs.size = 1 then Gear^.Hedgehog:= hogs.ar^[0]^.Hedgehog
    else Gear^.Hedgehog:= nil;
    if Gear^.Hedgehog <> nil then Gear^.Timer:= 5000;
    exit
    end;

// we have a target. move the creeper.
if HHGear <> nil then
    begin
    // GOTCHA
    if ((abs(HHGear^.X.Round-Gear^.X.Round) + abs(HHGear^.Y.Round-Gear^.Y.Round) + 2) <  50) and
         (Distance(HHGear^.X-Gear^.X,HHGear^.Y-Gear^.Y) < _50) then
        begin
        // hisssssssssss
        Gear^.State:= Gear^.State or gstTmpFlag;
        Gear^.Timer:= 1500;
        exit
        end;
    if (Gear^.State and gstMoving <> 0) then
        begin
        Gear^.dY:= _0;
        Gear^.dX:= _0;
        end
    else if (GameTicks and $FF = 0) then
        begin
        tdX:= HHGear^.X-Gear^.X;
        dir:= hwSign(tdX);
        if TestCollisionX(Gear, dir) = 0 then
            Gear^.X:= Gear^.X + signAs(_1,tdX);
        if TestCollisionXwithXYShift(Gear, signAs(_10,tdX), 0, dir) <> 0 then
            begin
            Gear^.dX:= SignAs(_0_15, tdX);
            Gear^.dY:= -_0_3;
            Gear^.State:= Gear^.State or gstMoving
            end
        end;
    end;
end;
*)
////////////////////////////////////////////////////////////////////////////////
procedure doStepKnife(Gear: PGear);
//var ox, oy: LongInt;
//    la: hwFloat;
var   a: real;
begin
    // Gear is shrunk so it can actually escape the hog without carving into the terrain
    if (Gear^.Radius = 4) and (Gear^.CollisionMask = $FFFF) then Gear^.Radius:= 7;
    if Gear^.Damage > 100 then Gear^.CollisionMask:= 0
    else if Gear^.Damage > 30 then
        if GetRandom(max(4,18-Gear^.Damage div 10)) < 3 then Gear^.CollisionMask:= 0;
    Gear^.Damage:= 0;
    if Gear^.Timer > 0 then dec(Gear^.Timer);
    if (Gear^.State and gstMoving <> 0) and (Gear^.State and gstCollision = 0) then
        begin
        DeleteCI(Gear);
        Gear^.Radius:= 7;
        // used for damage and impact calc. needs balancing I think
        Gear^.Health:= hwRound(hwSqr((hwAbs(Gear^.dY)+hwAbs(Gear^.dX))*Gear^.Boom/10000));
        doStepFallingGear(Gear);
        AllInactive := false;
        a:= Gear^.DirAngle;
        CalcRotationDirAngle(Gear);
        Gear^.DirAngle:= a+(Gear^.DirAngle-a)*2*hwSign(Gear^.dX) // double rotation
        end
    else if (Gear^.CollisionIndex = -1) and (Gear^.Timer = 0) then
        begin
        (*ox:= 0; oy:= 0;
        if TestCollisionYwithGear(Gear, -1) <> 0 then oy:= -1;
        if TestCollisionXwithGear(Gear, 1)  <> 0 then ox:=  1;
        if TestCollisionXwithGear(Gear, -1) <> 0 then ox:= -1;
        if TestCollisionYwithGear(Gear, 1)  <> 0 then oy:=  1;

        la:= _10000;
        if (ox <> 0) or (oy <> 0) then
            la:= CalcSlopeNearGear(Gear, ox, oy);
        if la = _10000 then
            begin
            // debug for when we couldn't get an angle
            //AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtSmokeWhite);
*)
        if Gear^.Health > 0 then
            PlaySound(Gear^.ImpactSound);

            Gear^.DirAngle:= DxDy2Angle(Gear^.dX, Gear^.dY) + (random(30)-15);
            if (Gear^.dX.isNegative and Gear^.dY.isNegative) or
             ((not Gear^.dX.isNegative) and (not Gear^.dY.isNegative)) then Gear^.DirAngle:= Gear^.DirAngle-90;
 //           end
 //       else Gear^.DirAngle:= hwFloat2Float(la)*90; // sheepluva's comment claims 45deg = 0.5 - yet orientation doesn't seem consistent?
 //       AddFileLog('la: '+floattostr(la)+' DirAngle: '+inttostr(round(Gear^.DirAngle)));
        Gear^.dX:= _0;
        Gear^.dY:= _0;
        Gear^.State:= Gear^.State and (not gstMoving) or gstCollision;
        Gear^.Radius:= 16;
        if Gear^.Health > 0 then AmmoShove(Gear, Gear^.Health, 0);
        Gear^.Health:= 0;
        Gear^.Timer:= 500;
        AddCI(Gear)
        end
    else if GameTicks and $3F = 0 then
        begin
        if  (TestCollisionYwithGear(Gear,-1) = 0)
        and (TestCollisionXwithGear(Gear, 1) = 0)
        and (TestCollisionXwithGear(Gear,-1) = 0)
        and (TestCollisionYwithGear(Gear, 1) = 0) then Gear^.State:= Gear^.State and (not gstCollision) or gstMoving;
        end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepDuck(Gear: PGear);
begin
    // Mirror duck on bounce world edge, even turn around later
    if WorldWrap(Gear) and (WorldEdge = weBounce) then
        begin
        Gear^.Tag:= Gear^.Tag * -1;
        if Gear^.Pos = 2 then
            Gear^.Pos:= 1
        else if Gear^.Pos = 1 then
            Gear^.Pos:= 2
        else if Gear^.Pos = 5 then
            Gear^.Pos:= 6
        else if Gear^.Pos = 5 then
            Gear^.Pos:= 5;
        end;

    AllInactive := false;

    // Duck falls (Pos = 0)
    if Gear^.Pos = 0 then
        doStepFallingGear(Gear);

    (* Check if duck is near water surface
           (Karma is distance from water) *)
    if (Gear^.Pos <> 1) and (Gear^.Pos <> 2) and (cWaterLine <= hwRound(Gear^.Y) + Gear^.Karma) then
        begin
        if cWaterLine = hwRound(Gear^.Y) + Gear^.Karma then
            begin
            // Let's make that duck swim!
            // Does the duck come FROM the Sea edge? (left or right)
            if (((Gear^.Pos = 3) or (Gear^.Pos = 7)) and (cWindSpeed > _0)) or (((Gear^.Pos = 4) or (Gear^.Pos = 8)) and (cWindSpeed < _0)) then
                begin
                PlaySound(sndDuckWater);
                Gear^.Angle:= 0;
                Gear^.Pos:= 1;
                Gear^.dY:= _0;
                end;

            // Duck comes either falling (usual case) or was rising from below
            if (Gear^.Pos = 0) or (Gear^.Pos = 5) or (Gear^.Pos = 6) then
                begin
                PlaySound(sndDroplet2);
                if Gear^.dY > _0_4 then
                    PlaySound(sndDuckWater);
                Gear^.Pos:= 1;
                Gear^.dY:= _0;
                end;
            end
        else if Gear^.Pos = 0 then
            Gear^.Pos:= 5;
        end;

    // Manual speed handling when duck is on water
    if Gear^.Pos <> 0 then
        begin
        Gear^.X:= Gear^.X + Gear^.dX;
        Gear^.Y:= Gear^.Y + Gear^.dY;
        end;

    // Handle speed
    // 1-4: On water: Let's swim!
    if Gear^.Pos = 1 then
        // On water (normal)
        Gear^.dX:= cWindSpeed * Gear^.Damage
    else if Gear^.Pos = 2 then
        // On water, mirrored (after bounce edge bounce)
        Gear^.dX:= -cWindSpeed * Gear^.Damage
    else if Gear^.Pos = 3 then
        // On left Sea edge
        Gear^.dY:= cWindSpeed * Gear^.Damage
    else if Gear^.Pos = 4 then
        // On right Sea edge
        Gear^.dY:= -cWindSpeed * Gear^.Damage
    // 5-8: Underwater: Slowly rise to the surface and slightly follow wind
    else if Gear^.Pos = 5 then
        // Underwater (normal)
        begin
        Gear^.dX:= (cWindSpeed / 4) * Gear^.Damage;
        Gear^.dY:= -_0_07;
        end
    else if Gear^.Pos = 6 then
        // Underwater, mirrored duck (after bounce edge bounce)
        begin
        Gear^.dX:= -(cWindSpeed / 4) * Gear^.Damage;
        Gear^.dY:= -_0_07;
        end
    else if Gear^.Pos = 7 then
        // Inside left Sea edge
        begin
        Gear^.dX:= _0_07;
        Gear^.dY:= (cWindSpeed / 4) * Gear^.Damage;
        end
    else if Gear^.Pos = 8 then
        // Inside right Sea edge
        begin
        Gear^.dX:= -_0_07;
        Gear^.dY:= -(cWindSpeed / 4) * Gear^.Damage;
        end;
 
    
    // Rotate duck and change direction when reaching Sea world edge (Pos 3 or 4)
    if (WorldEdge = weSea) and (Gear^.Pos <> 3) and (Gear^.Pos <> 4) then
        // Swimming TOWARDS left edge
        if (LeftX >= hwRound(Gear^.X) - Gear^.Karma) and ((cWindSpeed < _0) or ((Gear^.Pos = 0) or (Gear^.Pos = 7))) then
            begin
            // Turn duck when reaching edge the first time
            if (Gear^.Pos <> 3) and (Gear^.Pos <> 7) then
                begin
                if Gear^.Tag = 1 then
                    Gear^.Angle:= 90 
                else
                    Gear^.Angle:= 270;
                end;

            // Reaching the edge surface
            if (LeftX = hwRound(Gear^.X) - Gear^.Karma) and (Gear^.Pos <> 3) then
                // We are coming from the horizontal side
                begin
                PlaySound(sndDuckWater);
                Gear^.dX:= _0;
                Gear^.Pos:= 3;
                end
            else 
                // We are coming from inside the Sea, go into “surfacing” mode
                Gear^.Pos:= 7;

            end

        // Swimming TOWARDS right edge (similar to left edge)
        else if (RightX <= hwRound(Gear^.X) + Gear^.Karma) and ((cWindSpeed > _0) or ((Gear^.Pos = 0) or (Gear^.Pos = 8))) then
            begin
            if (Gear^.Pos <> 4) and (Gear^.Pos <> 8) then
                begin
                if Gear^.Tag = 1 then
                    Gear^.Angle:= 270 
                else
                    Gear^.Angle:= 90;
                end;

            if (RightX = hwRound(Gear^.X) + Gear^.Karma) and (Gear^.Pos <> 4) then
                begin
                PlaySound(sndDuckWater);
                Gear^.dX:= _0;
                Gear^.Pos:= 4;
                end
            else 
                Gear^.Pos:= 8;

            end;


    if Gear^.Pos <> 0 then
        // Manual collision check required because we don't use onStepFallingGear in this case
        CheckCollision(Gear);
    if (Gear^.Timer = 0) or ((Gear^.State and gstCollision) <> 0) then
        // Explode duck
        begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Boom, Gear^.Hedgehog, EXPLAutoSound);
        PlaySound(sndDuckDie);
        DeleteGear(Gear);
        exit;
        end;

    // Update timer stuff
    if Gear^.Timer < 6000 then
        Gear^.RenderTimer:= true
    else
        Gear^.RenderTimer:= false;

    dec(Gear^.Timer);
end;

(*
 This didn't end up getting used, but, who knows, might be reasonable for javellin or something
// Make the knife initial angle based on the hog attack angle, or is that too hard?
procedure doStepKnife(Gear: PGear);
var t,
    gx, gy, ga,  // gear x,y,angle
    lx, ly, la, // land x,y,angle
    ox, oy, // x,y offset
    w, h,   // wXh of clip area
    tx, ty  // tip position in sprite
    : LongInt;
    surf: PSDL_Surface;
    s: hwFloat;

begin
    Gear^.dY := Gear^.dY + cGravity;
    if (GameFlags and gfMoreWind) <> 0 then
        Gear^.dX := Gear^.dX + cWindSpeed / Gear^.Density;
    Gear^.X := Gear^.X + Gear^.dX;
    Gear^.Y := Gear^.Y + Gear^.dY;
    CheckGearDrowning(Gear);
    gx:= hwRound(Gear^.X);
    gy:= hwRound(Gear^.Y);
    if Gear^.State and gstDrowning <> 0 then exit;
    with Gear^ do
        begin
        if CheckLandValue(gx, gy, lfLandMask) then
            begin
            t:= Angle + hwRound((hwAbs(dX)+hwAbs(dY)) * _10);

            if t < 0 then inc(t, 4096)
            else if 4095 < t then dec(t, 4096);
            Angle:= t;

            DirAngle:= Angle / 4096 * 360
            end
        else
            begin
//This is the set of postions for the knife.
//Using FlipSurface and copyToXY the knife can be written to the LandPixels at 32 positions, and an appropriate line drawn in Land.
            t:= Angle mod 1024;
            case t div 128 of
                0:  begin
                    ox:=   2; oy:= 5;
                    w :=  25;  h:= 5;
                    tx:=   0; ty:= 2
                    end;
                1:  begin
                    ox:=   2; oy:= 15;
                     w:=  24;  h:=  8;
                    tx:=   0; ty:=  7
                    end;
                2:  begin
                    ox:=   2; oy:= 27;
                     w:=  23;  h:= 12;
                    tx:= -12; ty:= -5
                    end;
                3:  begin
                    ox:=   2; oy:= 43;
                     w:=  21;  h:= 15;
                    tx:=   0; ty:= 14
                    end;
                4:  begin
                    ox:= 29; oy:=  8;
                     w:= 19;  h:= 19;
                    tx:=  0; ty:= 17
                    end;
                5:  begin
                    ox:= 29; oy:=  32;
                     w:= 15;  h:=  21;
                    tx:=  0; ty:=  20
                    end;
                6:  begin
                    ox:= 51; oy:=   3;
                     w:= 11;  h:=  23;
                    tx:=  0; ty:=  22
                    end;
                7:  begin
                    ox:= 51; oy:=  34;
                     w:=  7;  h:=  24;
                    tx:=  0; ty:=  23
                    end
                end;

            surf:= SDL_CreateRGBSurface(SDL_SWSURFACE, w, h, 32, RMask, GMask, BMask, AMask);
            copyToXYFromRect(SpritesData[sprKnife].Surface, surf, ox, oy, w, h, 0, 0);
            // try to make the knife hit point first
            lx := 0;
            ly := 0;
            if CalcSlopeTangent(Gear, gx, gy, lx, ly, 255) then
                begin
                la:= vector2Angle(int2hwFloat(lx), int2hwFloat(ly));
                ga:= vector2Angle(dX, dY);
                AddFileLog('la: '+inttostr(la)+' ga: '+inttostr(ga)+' Angle: '+inttostr(Angle));
                // change  to 0 to 4096 forced by LongWord in Gear
                if la < 0 then la:= 4096+la;
                if ga < 0 then ga:= 4096+ga;
                if ((Angle > ga) and (Angle < la)) or ((Angle < ga) and (Angle > la)) then
                    begin
                    if Angle >= 2048 then dec(Angle, 2048)
                    else if Angle < 2048 then inc(Angle, 2048)
                    end;
                AddFileLog('la: '+inttostr(la)+' ga: '+inttostr(ga)+' Angle: '+inttostr(Angle))
                end;
            case Angle div 1024 of
                0:  begin
                    flipSurface(surf, true);
                    flipSurface(surf, true);
                    BlitImageAndGenerateCollisionInfo(gx-(w-tx), gy-(h-ty), w, surf)
                    end;
                1:  begin
                    flipSurface(surf, false);
                    BlitImageAndGenerateCollisionInfo(gx-(w-tx), gy-ty, w, surf)
                    end;
                2:  begin // knife was actually drawn facing this way...
                    BlitImageAndGenerateCollisionInfo(gx-tx, gy-ty, w, surf)
                    end;
                3:  begin
                    flipSurface(surf, true);
                    BlitImageAndGenerateCollisionInfo(gx-tx, gy-(h-ty), w, surf)
                    end
                end;
            SDL_FreeSurface(surf);
            // this needs to calculate actual width/height + land clipping since update texture doesn't.
            // i.e. this will crash if you fire near sides of map, but until I get the blit right, not going to put real values
            UpdateLandTexture(hwRound(X)-32, 64, hwRound(Y)-32, 64, true);
            DeleteGear(Gear);
            exit
            end
        end;
end;
*)

end.
