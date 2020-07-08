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

unit uAIAmmoTests;
interface
uses uConsts, uFloat, uTypes, uAIMisc;
const
    amtest_Rare            = $00000001; // check only several positions
    amtest_NoTarget        = $00000002; // each pos, but no targetting
    amtest_MultipleAttacks = $00000004; // test could result in multiple attacks, set AttacksNum
    amtest_NoTrackFall     = $00000008; // skip fall tracing.  
    amtest_LaserSight      = $00000010; // supports laser sighting
    amtest_NoVampiric      = $00000020; // don't use vampirism with this ammo
    amtest_NoInvulnerable  = $00000040; // don't use invulnerable with this with ammo
    amtest_NoLowGravity    = $00000080; // don't use low gravity with this with ammo

var aiWindSpeed: real;
    aiGravity: hwFloat;
    aiGravityf: real;
    aiLaserSighting: boolean;

type TAttackParams = record
        Time, Bounce, AttacksNum: Longword;
        Angle, Power: LongInt;
        ExplX, ExplY, ExplR: LongInt;
        AttackPutX, AttackPutY: LongInt;
        end;

function TestBazooka(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestBee(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestSnowball(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestGrenade(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestMolotov(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestClusterBomb(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestWatermelon(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestDrillRocket(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestRCPlane(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestMortar(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestShotgun(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestDesertEagle(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestSniperRifle(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestBaseballBat(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestFirePunch(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestWhip(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestKamikaze(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestAirAttack(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestDrillStrike(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestMineStrike(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestSMine(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestPiano(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestTeleport(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestHammer(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestResurrector(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestCake(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestSeduction(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestDynamite(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestMine(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestKnife(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestAirMine(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
function TestMinigun(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;

type TAmmoTestProc = function (Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
    TAmmoTest = record
            proc: TAmmoTestProc;
            flags: Longword;
            end;

const AmmoTests: array[TAmmoType] of TAmmoTest =
            (
            (proc: nil;              flags: 0), // amNothing
            (proc: @TestGrenade;     flags: 0), // amGrenade
            (proc: @TestClusterBomb; flags: 0), // amClusterBomb
            (proc: @TestBazooka;     flags: 0), // amBazooka
            (proc: @TestBee;         flags: amtest_Rare), // amBee
            (proc: @TestShotgun;     flags: amtest_LaserSight), // amShotgun
            (proc: nil;              flags: 0), // amPickHammer
            (proc: nil;              flags: 0), // amSkip
            (proc: nil;              flags: 0), // amRope
            (proc: @TestMine;        flags: amtest_NoTarget), // amMine
            (proc: @TestDesertEagle; flags: amtest_MultipleAttacks or amtest_LaserSight), // amDEagle
            (proc: @TestDynamite;    flags: amtest_NoTarget), // amDynamite
            (proc: @TestFirePunch;   flags: amtest_NoTarget), // amFirePunch
            (proc: @TestWhip;        flags: amtest_NoTarget or amtest_NoInvulnerable), // amWhip
            (proc: @TestBaseballBat; flags: amtest_NoTarget or amtest_NoInvulnerable), // amBaseballBat
            (proc: nil;              flags: 0), // amParachute
            (proc: @TestAirAttack;   flags: amtest_Rare), // amAirAttack
            (proc: @TestMineStrike;  flags: amtest_Rare), // amMineStrike
            (proc: nil;              flags: 0), // amBlowTorch
            (proc: nil;              flags: 0), // amGirder
            (proc: nil;              flags: 0), // amTeleport
            //(proc: @TestTeleport;    flags: amtest_OnTurn), // amTeleport
            (proc: nil;              flags: 0), // amSwitch
            (proc: @TestMortar;      flags: 0), // amMortar
            (proc: @TestKamikaze;    flags: amtest_LaserSight or amtest_NoInvulnerable or amtest_NoVampiric), // amKamikaze
            (proc: @TestCake;        flags: amtest_Rare or amtest_NoTarget), // amCake
            (proc: @TestSeduction;   flags: amtest_NoTarget), // amSeduction
            (proc: @TestWatermelon;  flags: 0), // amWatermelon
            (proc: nil;              flags: 0), // amHellishBomb
            (proc: nil;              flags: 0), // amNapalm
            (proc: @TestDrillRocket; flags: 0), // amDrill
            (proc: nil;              flags: 0), // amBallgun
            (proc: @TestRCPlane;     flags: amtest_LaserSight), // amRCPlane
            (proc: nil;              flags: 0), // amLowGravity
            (proc: nil;              flags: 0), // amExtraDamage
            (proc: nil;              flags: 0), // amInvulnerable
            (proc: nil;              flags: 0), // amExtraTime
            (proc: nil;              flags: 0), // amLaserSight
            (proc: nil;              flags: 0), // amVampiric
            (proc: @TestSniperRifle; flags: 0), // amSniperRifle
            (proc: nil;              flags: 0), // amJetpack
            (proc: @TestMolotov;     flags: 0), // amMolotov
            (proc: nil;              flags: 0), // amBirdy
            (proc: nil;              flags: 0), // amPortalGun
            (proc: @TestPiano;       flags: amtest_Rare or amtest_NoInvulnerable or amtest_NoVampiric), // amPiano
            (proc: @TestGrenade;     flags: amtest_NoTrackFall), // amGasBomb
            (proc: @TestShotgun;     flags: 0), // amSineGun
            (proc: nil;              flags: 0), // amFlamethrower
            (proc: @TestSMine;       flags: 0), // amSMine
            (proc: @TestHammer;      flags: amtest_NoTarget or amtest_NoInvulnerable), // amHammer
            (proc: @TestResurrector; flags: amtest_NoTarget or amtest_NoInvulnerable or amtest_NoVampiric or amtest_NoLowGravity), // amResurrector
            (proc: @TestDrillStrike; flags: amtest_Rare), // amDrillStrike
            (proc: @TestSnowball;    flags: amtest_NoInvulnerable or amtest_NoVampiric), // amSnowball
            (proc: nil;              flags: 0), // amTardis
            (proc: nil;              flags: 0), // amLandGun
            (proc: nil;              flags: 0), // amIceGun
            (proc: @TestKnife;       flags: 0), // amKnife
            (proc: nil;              flags: 0), // amRubber
            (proc: @TestAirMine;     flags: amtest_LaserSight), // amAirMine
            (proc: nil;              flags: 0), // amCreeper
            (proc: @TestMinigun;     flags: amtest_LaserSight),  // amMinigun
            (proc: nil;              flags: 0)  // amSentry
            );

implementation
uses uVariables, uUtils, uGearsHandlers;

function Metric(x1, y1, x2, y2: LongInt): LongInt; inline;
begin
Metric:= abs(x1 - x2) + abs(y1 - y2)
end;

function TestBazooka(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
const cExtraTime = 300;
var Vx, Vy, r, mX, mY: real;
    rTime: LongInt;
    EX, EY: LongInt;
    valueResult: LongInt;
    targXWrap, x, y, dX, dY: real;
    t: LongInt;
    value: LongInt;
begin
Flags:= Flags; // avoid compiler hint
mX:= hwFloat2Float(Me^.X);
mY:= hwFloat2Float(Me^.Y);
ap.Time:= 0;
rTime:= 350;
ap.ExplR:= 0;
if (WorldEdge = weWrap) then
    if (Targ.Point.X < mX) then
         targXWrap:= Targ.Point.X + (RightX-LeftX)
    else targXWrap:= Targ.Point.X - (RightX-LeftX);
valueResult:= BadTurn;
repeat
    rTime:= rTime + 300 + Level * 50 + random(300);
    if (WorldEdge = weWrap) and (random(2)=0) then
         Vx:= - aiWindSpeed * rTime * 0.5 + (targXWrap + AIrndSign(2) + AIrndOffset(Targ, Level) - mX) / rTime
    else Vx:= - aiWindSpeed * rTime * 0.5 + (Targ.Point.X + AIrndSign(2) + AIrndOffset(Targ, Level) - mX) / rTime;
    Vy:= aiGravityf * rTime * 0.5 - (Targ.Point.Y + 1 - mY) / rTime;
    r:= sqr(Vx) + sqr(Vy);
    if not (r > 1) then
        begin
        x:= mX;
        y:= mY;
        dX:= Vx;
        dY:= -Vy;
        t:= rTime;
        repeat
            x:= CheckWrap(x);
            x:= x + dX;

            y:= y + dY;
            dX:= dX + aiWindSpeed;
            //dX:= CheckBounce(x,dX);
            dY:= dY + aiGravityf;
            dec(t)
        until (((Me = CurrentHedgehog^.Gear) and TestColl(trunc(x), trunc(y), 5)) or
               ((Me <> CurrentHedgehog^.Gear) and TestCollExcludingMe(Me^.Hedgehog^.Gear, trunc(x), trunc(y), 5))) or (t < -cExtraTime);

        EX:= trunc(x);
        EY:= trunc(y);
        if t >= -cExtraTime then
            begin
                if Level = 1 then
                    value:= RateExplosion(Me, EX, EY, 101, afTrackFall or afErasesLand)
                else
                    value:= RateExplosion(Me, EX, EY, 101);
            end else
                value:= BadTurn;

        if (value = 0) and (Targ.Kind = gtHedgehog) and (Targ.Score > 0) then
            if GameFlags and gfSolidLand = 0 then
                 value := 1024 - Metric(Targ.Point.X, Targ.Point.Y, EX, EY) div 64
            else value := BadTurn;

        if (valueResult < value) or ((valueResult = value) and (Level < 3)) then
            begin
            ap.Angle:= DxDy2AttackAnglef(Vx, Vy) + AIrndSign(random((Level - 1) * 9));
            ap.Power:= trunc(sqrt(r) * cMaxPower) - random((Level - 1) * 17 + 1);
            ap.ExplR:= 100;
            ap.ExplX:= EX;
            ap.ExplY:= EY;
            valueResult:= value
            end;
        end
until rTime > 5050 - Level * 800;
TestBazooka:= valueResult
end;

function calcBeeFlight(Me: PGear; x, y, dx, dy, tX, tY: real; var eX, eY: LongInt): LongInt;
var t: Longword;
    f: boolean;
    speed, d: real;
begin
    // parabola flight before activation
    t:= 500;
    repeat
        x:= x + dx;
        y:= y + dy;
        dy:= dy + aiGravityf;
        f:= ((Me = CurrentHedgehog^.Gear) and TestColl(trunc(x), trunc(y), 5)) or
           ((Me <> CurrentHedgehog^.Gear) and TestCollExcludingMe(Me^.Hedgehog^.Gear, trunc(x), trunc(y), 5));
        dec(t)
    until (t = 0) or (y >= cWaterLine) or f;

    if f then
    begin
        eX:= trunc(x);
        eY:= trunc(y);
        exit(RateExplosion(Me, eX, eY, 101, afTrackFall or afErasesLand));
    end;


    // activated
    t:= 5000;
    speed:= sqrt(sqr(dx) + sqr(dy));

    repeat
        if (t and $F) = 0 then
        begin
            dx:= dx + 0.000064 * (tX - x);
            dy:= dy + 0.000064 * (tY - y);
            d := speed / sqrt(sqr(dx) + sqr(dy));
            dx:= dx * d;
            dy:= dy * d;
        end;

        x:= x + dx;
        y:= y + dy;
        f:= ((Me = CurrentHedgehog^.Gear) and TestColl(trunc(x), trunc(y), 5)) or
           ((Me <> CurrentHedgehog^.Gear) and TestCollExcludingMe(Me^.Hedgehog^.Gear, trunc(x), trunc(y), 5));
        dec(t)
    until (t = 0) or f;

    if f then
    begin
        eX:= trunc(x);
        eY:= trunc(y);
        exit(RateExplosion(Me, eX, eY, 101, afTrackFall or afErasesLand));
    end
    else
        calcBeeFlight:= BadTurn
end;

function TestBee(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
var i, j: LongInt;
    valueResult, v, a, p: LongInt;
    mX, mY: real;
    eX, eY: LongInt;
begin
Flags:= Flags; // avoid compiler hint
    if Level > 1 then
        exit(BadTurn);

    eX:= 0;
    eY:= 0;
    mX:= hwFloat2Float(Me^.X);
    mY:= hwFloat2Float(Me^.Y);
    valueResult:= BadTurn;
    for i:= 0 to 8 do
        for j:= 0 to 1 do
            begin
            a:= i * 120;
            p:= random(cMaxPower - 200) + 180;

            if j = 0 then
                a:= -a;

            v:= calcBeeFlight(Me
                    , mX
                    , mY
                    , sin(a * pi / 2048) * p / cPowerDivisor
                    , -cos(a * pi / 2048) * p / cPowerDivisor
                    , Targ.Point.X
                    , Targ.Point.Y
                    , eX
                    , eY);

            if v > valueResult then
                begin
                ap.ExplR:= 100;
                ap.ExplX:= eX;
                ap.ExplY:= eY;
                ap.Angle:= a;
                ap.Power:= p;
                valueResult:= v
                end
            end;

    ap.AttackPutX:= Targ.Point.X;
    ap.AttackPutY:= Targ.Point.Y;

    if valueResult > 0 then
        TestBee:= valueResult - 5000
    else
        TestBee:= BadTurn // no digging
end;

function TestDrillRocket(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
var Vx, Vy, r, mX, mY: real;
    rTime: LongInt;
    EX, EY: LongInt;
    valueResult: LongInt;
    targXWrap, x, y, dX, dY: real;
    t: LongInt;
    value: LongInt;
    t2: real;
    timer: Longint;
begin
Flags:= Flags; // avoid compiler hint
    if (Level > 3) then exit(BadTurn);

    mX:= hwFloat2Float(Me^.X);
    mY:= hwFloat2Float(Me^.Y);
    ap.Time:= 0;
    rTime:= 350;
    ap.ExplR:= 0;
    valueResult:= BadTurn;
    if (WorldEdge = weWrap) then
        if (Targ.Point.X < mX) then
             targXWrap:= Targ.Point.X + (RightX-LeftX)
        else targXWrap:= Targ.Point.X - (RightX-LeftX);
    timer:= 0;
    repeat
        rTime:= rTime + 300 + Level * 50 + random(300);
        if (WorldEdge = weWrap) and (random(2)=0) then
             Vx:= - aiWindSpeed * rTime * 0.5 + (targXWrap + AIrndSign(2) - mX) / rTime
        else Vx:= - aiWindSpeed * rTime * 0.5 + (Targ.Point.X + AIrndSign(2) - mX) / rTime;
        Vy:= aiGravityf * rTime * 0.5 - (Targ.Point.Y - 35 - mY) / rTime;
        r:= sqr(Vx) + sqr(Vy);
        if not (r > 1) then
            begin
            x:= mX;
            y:= mY;
            dX:= Vx;
            dY:= -Vy;
            t:= rTime;
            repeat
                x:= CheckWrap(x);
                x:= x + dX;
                y:= y + dY;
                dX:= dX + aiWindSpeed;
                dY:= dY + aiGravityf;
                dec(t)
            until (((Me = CurrentHedgehog^.Gear) and TestColl(trunc(x), trunc(y), 5)) or
                   ((Me <> CurrentHedgehog^.Gear) and TestCollExcludingMe(Me^.Hedgehog^.Gear, trunc(x), trunc(y), 5))) or (y > cWaterLine);

            if TestCollExcludingObjects(trunc(x), trunc(y), 5) and (Abs(Targ.Point.X - trunc(x)) + Abs(Targ.Point.Y - trunc(y)) > 21) then
                begin
                timer := 500;
                t2 := 0.5 / sqrt(sqr(dX) + sqr(dY));
                dX := dX * t2;
                dY := dY * t2;
                repeat
                    x:= x + dX;
                    y:= y + dY;
                    dec(timer);
                until (Abs(Targ.Point.X - trunc(x)) + Abs(Targ.Point.Y - trunc(y)) < 22)
                    or (x < 0)
                    or (y < 0)
                    or (trunc(x) > LAND_WIDTH)
                    or (trunc(y) > LAND_HEIGHT)
                    or (not TestCollExcludingObjects(trunc(x), trunc(y), 5))
                    or (timer = 0)
                end;
            EX:= trunc(x);
            EY:= trunc(y);
            // Try to prevent AI from thinking firing into water will cause a drowning
            if (EY < cWaterLine-5) and (timer > 0) and (Abs(Targ.Point.X - trunc(x)) + Abs(Targ.Point.Y - trunc(y)) > 21) then exit(BadTurn);
            if Level = 1 then
                value:= RateExplosion(Me, EX, EY, 101, afTrackFall or afErasesLand)
            else value:= RateExplosion(Me, EX, EY, 101);
            if valueResult <= value then
                begin
                ap.Angle:= DxDy2AttackAnglef(Vx, Vy) + AIrndSign(random((Level - 1) * 9));
                ap.Power:= trunc(sqrt(r) * cMaxPower) - random((Level - 1) * 17 + 1);
                ap.ExplR:= 100;
                ap.ExplX:= EX;
                ap.ExplY:= EY;
                valueResult:= value-2500 // trying to make it slightly less attractive than a bazooka, to prevent waste.  AI could use awareness of weapon count
                end;
            end
    until rTime > 5050 - Level * 800;
    TestDrillRocket:= valueResult
end;

function TestRCPlane(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
const
    MIN_RANGE =  200;
var Vx, Vy, meX, meY, x, y: real;
    rx, ry, valueResult: LongInt;
    range, maxRange: integer;
begin
// This is a very simple test to let a RC plane fly in a straight line, without dropping any bombs
// TODO: Teach AI how to steer
// TODO: Teach AI how to drop bombs
// TODO: Teach AI how to predict fire behavior
Flags:= Flags; // avoid compiler hint
if Level = 5 then
    exit(BadTurn)
else if Level = 4 then
    maxRange:= 2200
else if Level = 3 then
    maxRange:= 2900
else if Level = 2 then
    maxRange:= 3500
else
    maxRange:= 3900;
TestRCPlane:= BadTurn;
ap.ExplR:= 0;
ap.Time:= 0;
ap.Power:= 1;
meX:= hwFloat2Float(Me^.X);
meY:= hwFloat2Float(Me^.Y);
x:= meX;
y:= meY;
range:= Metric(trunc(x), trunc(y), Targ.Point.X, Targ.Point.Y);
if ( range < MIN_RANGE ) or ( range > maxRange) then
    exit(BadTurn);

Vx:= (Targ.Point.X - x) * 1 / 1024;
Vy:= (Targ.Point.Y - y) * 1 / 1024;
ap.Angle:= DxDy2AttackAnglef(Vx, -Vy);
repeat
    x:= x + vX;
    y:= y + vY;
    rx:= trunc(x);
    ry:= trunc(y);
    if ((Me = CurrentHedgehog^.Gear) and TestColl(rx, ry, 8)) or
        ((Me <> CurrentHedgehog^.Gear) and TestCollExcludingMe(Me^.Hedgehog^.Gear, rx, ry, 8)) then
        begin
        x:= x + vX * 8;
        y:= y + vY * 8;

        // Intentionally low rating to discourage use
        if Level = 1 then
            valueResult:= RateExplosion(Me, rx, ry, 26, afTrackFall or afErasesLand)
        else
            valueResult:= RateExplosion(Me, rx, ry, 26);

        // Check range again in case the plane collided before target
        range:= Metric(trunc(meX), trunc(meY), rx, ry);
        if ( range < MIN_RANGE ) or ( range > maxRange) then
            exit(BadTurn);

        // If impact location is close, above us and wind blows in our direction,
        // there's a risk of fire flying towards us, so fail in this case.
        if (Level < 3) and (range <= 600) and (meY >= ry) and
            (((ap.Angle < 0) and (aiWindSpeed > 0)) or ((ap.Angle > 0) and (aiWindSpeed < 0))) then
            exit(BadTurn);

        // Apply inaccuracy
        if (not aiLaserSighting) then
            inc(ap.Angle, AIrndSign(random((Level - 1) * 9)));

        if (valueResult <= 0) then
            valueResult:= BadTurn;
        exit(valueResult)
        end
until (Abs(Targ.Point.X - trunc(x)) + Abs(Targ.Point.Y - trunc(y)) < 4)
    or (x < 0)
    or (y < 0)
    or (trunc(x) > LAND_WIDTH)
    or (trunc(y) > LAND_HEIGHT);

TestRCPlane:= BadTurn
end;

function TestSnowball(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
const timeLimit = 5000;
      Density : real = 0.5;
var Vx, Vy, r: real;
    rTime: LongInt;
    EX, EY: LongInt;
    valueResult: LongInt;
    targXWrap, x, y, dX, dY, meX, meY: real;
    t: LongInt;
    value: LongInt;

begin
Flags:= Flags; // avoid compiler hint
meX:= hwFloat2Float(Me^.X);
meY:= hwFloat2Float(Me^.Y);
ap.Time:= 0;
rTime:= 350;
ap.ExplR:= 0;
valueResult:= BadTurn;
if (WorldEdge = weWrap) then
    if (Targ.Point.X < meX) then
         targXWrap:= Targ.Point.X + (RightX-LeftX)
    else
         targXWrap:= Targ.Point.X - (RightX-LeftX);
repeat
    rTime:= rTime + 300 + Level * 50 + random(300);
    if (WorldEdge = weWrap) and (random(2)=0) then
         Vx:= (targXWrap - meX) / rTime
    else
         Vx:= (Targ.Point.X - meX) / rTime;
    if (GameFlags and gfMoreWind) <> 0 then
         Vx:= -(aiWindSpeed / Density) * rTime * 0.5 + Vx
    else
         Vx:= -aiWindSpeed * rTime * 0.5 + Vx;
    Vy:= aiGravityf * rTime * 0.5 - (Targ.Point.Y - meY) / rTime;
    r:= sqr(Vx) + sqr(Vy);

    if not (r > 1) then
        begin
        x:= meX;
        y:= meY;
        dX:= Vx;
        dY:= -Vy;
        t:= rTime;
        repeat
            x:= CheckWrap(x);
            x:= x + dX;
            if (GameFlags and gfMoreWind) <> 0 then
                dX:= dX + aiWindSpeed / Density
            else
                dX:= dX + aiWindSpeed;

            y:= y + dY;
            dY:= dY + aiGravityf;
            dec(t)
        until (((Me = CurrentHedgehog^.Gear) and TestColl(trunc(x), trunc(y), 4)) or
               ((Me <> CurrentHedgehog^.Gear) and TestCollExcludingMe(Me^.Hedgehog^.Gear, trunc(x), trunc(y), 4))) or (trunc(y) > cWaterLine) or (t < -timeLimit);

        EX:= trunc(x);
        EY:= trunc(y);

        // Sanity check: Make sure we're not too close to impact location
        if (Metric(trunc(meX), trunc(meY), EX, EY) <= 40) then
            value:= BadTurn
        // Rate attack
        else if (t >= -timeLimit) and (EY <= cWaterLine) then
            // radius intentionally set to 16 for shove because lower values don't work reliably
            value:= RateShove(Me, EX, EY, 16, 0, trunc((abs(dX)+abs(dY))*20), dX, dY, afTrackFall)
        else
            value:= BadTurn;

        if (value = 0) and (Targ.Kind = gtHedgehog) and (Targ.Score > 0) then
            value := BadTurn;

        if (valueResult < value) or ((valueResult = value) and (Level = 1)) then
            begin
            ap.Angle:= DxDy2AttackAnglef(Vx, Vy) + AIrndSign(random((Level - 1) * 12));
            ap.Power:= trunc(sqrt(r) * cMaxPower) - random((Level - 1) * 22 + 1);
            ap.ExplX:= EX;
            ap.ExplY:= EY;
            valueResult:= value
            end;
        end
until rTime > 5050 - Level * 800;
TestSnowball:= valueResult
end;

function TestMolotov(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
const timeLimit = 50;
      Density : real = 2.0;
var Vx, Vy, r, meX, meY: real;
    rTime: LongInt;
    EX, EY: LongInt;
    valueResult: LongInt;
    targXWrap, x, y, dX, dY: real;
    t: LongInt;
    value, range: LongInt;
begin
Flags:= Flags; // avoid compiler hint
meX:= hwFloat2Float(Me^.X);
meY:= hwFloat2Float(Me^.Y);
ap.Time:= 0;
rTime:= 350;
ap.ExplR:= 0;
if (WorldEdge = weWrap) then
    if (Targ.Point.X < meX) then
         targXWrap:= Targ.Point.X + (RightX-LeftX)
    else targXWrap:= Targ.Point.X - (RightX-LeftX);
valueResult:= BadTurn;
repeat
    rTime:= rTime + 300 + Level * 50 + random(300);
    if (WorldEdge = weWrap) and (random(2)=0) then
         Vx:= (targXWrap + AIrndSign(2) + AIrndOffset(Targ, Level) - meX) / rTime
    else
         Vx:= (Targ.Point.X + AIrndSign(2) + AIrndOffset(Targ, Level) - meX) / rTime;
    if (GameFlags and gfMoreWind) <> 0 then
         Vx:= -(aiWindSpeed / Density) * rTime * 0.5 + Vx;
    Vy:= aiGravityf * rTime * 0.5 - (Targ.Point.Y + 1 - meY) / rTime;
    r:= sqr(Vx) + sqr(Vy);

    if not (r > 1) then
        begin
        x:= meX;
        y:= meY;
        dX:= Vx;
        dY:= -Vy;
        t:= rTime;
        repeat
            x:= CheckWrap(x);
            x:= x + dX;
            if (GameFlags and gfMoreWind) <> 0 then
                dX:= dX + aiWindSpeed / Density;

            y:= y + dY;
            dY:= dY + aiGravityf;
            dec(t)
        until (((Me = CurrentHedgehog^.Gear) and TestColl(trunc(x), trunc(y), 5)) or
               ((Me <> CurrentHedgehog^.Gear) and TestCollExcludingMe(Me^.Hedgehog^.Gear, trunc(x), trunc(y), 5))) or (t < -timeLimit);

        EX:= trunc(x);
        EY:= trunc(y);

        // Sanity check 1: Make sure we're not too close to impact location
        range:= Metric(trunc(meX), trunc(meY), EX, EY);
        if (range < 150) and (Level < 5) then
            exit(BadTurn);

        // Sanity check 2: If impact location is close, above us and wind blows
        // towards us, there's a risk of fire flying towards us, so fail in this case.
        if (Level < 3) and (range <= 600) and (trunc(meY) >= EX) and
            (((ap.Angle < 0) and (aiWindSpeed > 0)) or ((ap.Angle > 0) and (aiWindSpeed < 0))) then
            exit(BadTurn);

        if t >= -timeLimit then
            value:= RateExplosion(Me, EX, EY, 97) // average of 17 attempts, most good, but some failing spectacularly
        else
            value:= BadTurn;

        if (value = 0) and (Targ.Kind = gtHedgehog) and (Targ.Score > 0) then
            value := BadTurn;

        if (valueResult < value) or ((valueResult = value) and (Level < 3)) then
            begin
            ap.Angle:= DxDy2AttackAnglef(Vx, Vy) + AIrndSign(random((Level - 1) * 9));
            ap.Power:= trunc(sqrt(r) * cMaxPower) - random((Level - 1) * 17 + 1);
            ap.ExplR:= 100;
            ap.ExplX:= EX;
            ap.ExplY:= EY;
            valueResult:= value
            end;
        end
until rTime > 5050 - Level * 800;
TestMolotov:= valueResult
end;

function TestGrenade(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
const tDelta = 24;
      Density : real = 1.5;
var Vx, Vy, r: real;
    Score, EX, EY, valueResult: LongInt;
    TestTime: LongInt;
    targXWrap, x, y, meX, meY, dX, dY: real;
    t: LongInt;
begin
valueResult:= BadTurn;
TestTime:= 0;
ap.Bounce:= 0;
ap.ExplR:= 0;
meX:= hwFloat2Float(Me^.X);
meY:= hwFloat2Float(Me^.Y);
if (WorldEdge = weWrap) then
    if (Targ.Point.X < meX) then
         targXWrap:= Targ.Point.X + (RightX-LeftX)
    else targXWrap:= Targ.Point.X - (RightX-LeftX);
repeat
    inc(TestTime, 1000);
    if (WorldEdge = weWrap) and (random(2)=0) then
         Vx:= (targXWrap + AIrndOffset(Targ, Level) - meX) / (TestTime + tDelta)
    else
         Vx:= (Targ.Point.X + AIrndOffset(Targ, Level) - meX) / (TestTime + tDelta);
    if (GameFlags and gfMoreWind) <> 0 then
         Vx:= -(aiWindSpeed / Density) * (TestTime + tDelta) * 0.5 + Vx;
    Vy:= aiGravityf * ((TestTime + tDelta) div 2) - (Targ.Point.Y - meY) / (TestTime + tDelta);
    r:= sqr(Vx) + sqr(Vy);
    if not (r > 1) then
        begin
        x:= meX;
        y:= meY;
        dX:= Vx;
        dY:= -Vy;
        t:= TestTime;
        repeat
            x:= CheckWrap(x);
            x:= x + dX;
            if (GameFlags and gfMoreWind) <> 0 then
                dX:= dX + aiWindSpeed / Density;
            y:= y + dY;
            dY:= dY + aiGravityf;
            dec(t)
        until (((Me = CurrentHedgehog^.Gear) and TestColl(trunc(x), trunc(y), 5)) or
               ((Me <> CurrentHedgehog^.Gear) and TestCollExcludingMe(Me^.Hedgehog^.Gear, trunc(x), trunc(y), 5))) or (t = 0);
    EX:= trunc(x);
    EY:= trunc(y);
    if t < 50 then
        if (Level = 1) and (Flags and amtest_NoTrackFall = 0) then
            Score:= RateExplosion(Me, EX, EY, 101, afTrackFall or afErasesLand)
        else Score:= RateExplosion(Me, EX, EY, 101)
    else
        Score:= BadTurn;

    if (valueResult < Score) and (Score > 0) then
        begin
        ap.Angle:= DxDy2AttackAnglef(Vx, Vy) + AIrndSign(random(Level * 3));
        ap.Power:= trunc(sqrt(r) * cMaxPower) + AIrndSign(random(Level) * 20);
        ap.Time:= TestTime;
        ap.ExplR:= 100;
        ap.ExplX:= EX;
        ap.ExplY:= EY;
        valueResult:= Score
        end;
    end
//until (Score > 204800) or (TestTime > 4000);
until TestTime > 4500 - Level * 512;
TestGrenade:= valueResult
end;

function TestClusterBomb(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
const tDelta = 24;
      Density : real = 1.5;
var Vx, Vy, r: real;
    Score, EX, EY, valueResult: LongInt;
    TestTime: Longword;
    x, y, dX, dY, meX, meY: real;
    t: LongInt;
begin
Flags:= Flags; // avoid compiler hint
valueResult:= BadTurn;
TestTime:= 500;
ap.Bounce:= 0;
ap.ExplR:= 0;
meX:= hwFloat2Float(Me^.X);
meY:= hwFloat2Float(Me^.Y);
repeat
    inc(TestTime, 900);
    if (GameFlags and gfMoreWind) <> 0 then
        Vx:= (-(aiWindSpeed / Density) * (TestTime + tDelta) * 0.5) + ((Targ.Point.X - meX) / (TestTime + tDelta))
    // Try to overshoot slightly, seems to pay slightly better dividends in terms of hitting cluster
    else if meX<Targ.Point.X then
        Vx:= ((Targ.Point.X+10) - meX) / (TestTime + tDelta)
    else
        Vx:= ((Targ.Point.X-10) - meX) / (TestTime + tDelta);
    Vy:= aiGravityf * ((TestTime + tDelta) div 2) - ((Targ.Point.Y-50) - meY) / (TestTime + tDelta);
    r:= sqr(Vx)+sqr(Vy);
    if not (r > 1) then
        begin
        x:= meX;
        dX:= Vx;
        y:= meY;
        dY:= -Vy;
        t:= TestTime;
    repeat
        x:= x + dX;
        if (GameFlags and gfMoreWind) <> 0 then
            dX:= dX + aiWindSpeed / Density;
        y:= y + dY;
        dY:= dY + aiGravityf;
        dec(t)
    until (((Me = CurrentHedgehog^.Gear) and TestColl(trunc(x), trunc(y), 5)) or
           ((Me <> CurrentHedgehog^.Gear) and TestCollExcludingMe(Me^.Hedgehog^.Gear, trunc(x), trunc(y), 5))) or (t = 0);
    EX:= trunc(x);
    EY:= trunc(y);
    if t < 50 then
        Score:= RateExplosion(Me, EX, EY, 41)
    else
        Score:= BadTurn;

     if Score > 0 then
        begin
        ap.Angle:= DxDy2AttackAnglef(Vx, Vy) + AIrndSign(random(Level * 2));
        ap.Power:= trunc(sqrt(r) * cMaxPower) + AIrndSign(random(Level) * 15);
        ap.Time:= TestTime div 1000 * 1000;
        ap.ExplR:= 90;
        ap.ExplX:= EX;
        ap.ExplY:= EY;
        valueResult:= Score
        end;
     end
until (TestTime = 4100);
TestClusterBomb:= valueResult
end;

function TestWatermelon(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
const tDelta = 24;
      Density : real = 2.0;
var Vx, Vy, r: real;
    Score, EX, EY, valueResult: LongInt;
    TestTime: Longword;
    targXWrap, x, y, dX, dY, meX, meY: real;
    t: LongInt;
begin
Flags:= Flags; // avoid compiler hint
valueResult:= BadTurn;
TestTime:= 500;
ap.ExplR:= 0;
meX:= hwFloat2Float(Me^.X);
meY:= hwFloat2Float(Me^.Y);
if (WorldEdge = weWrap) then
    if (Targ.Point.X < meX) then
         targXWrap:= Targ.Point.X + (RightX-LeftX)
    else targXWrap:= Targ.Point.X - (RightX-LeftX);
repeat
    inc(TestTime, 900);
    if (WorldEdge = weWrap) and (random(2)=0) then
        Vx:= (targXWrap - meX) / (TestTime + tDelta)
    else
        Vx:= (Targ.Point.X - meX) / (TestTime + tDelta);
    if (GameFlags and gfMoreWind) <> 0 then
        Vx:= -(aiWindSpeed / Density) * (TestTime + tDelta) * 0.5 + Vx;

    Vy:= aiGravityf * ((TestTime + tDelta) div 2) - ((Targ.Point.Y-50) - meY) / (TestTime + tDelta);
    r:= sqr(Vx)+sqr(Vy);
    if not (r > 1) then
        begin
        x:= meX;
        dX:= Vx;
        y:= meY;
        dY:= -Vy;
        t:= TestTime;
        repeat
            x:= CheckWrap(x);
            x:= x + dX;
            if (GameFlags and gfMoreWind) <> 0 then
                 dX:= dX + aiWindSpeed / Density;
            y:= y + dY;
            dY:= dY + aiGravityf;
            dec(t)
       until (((Me = CurrentHedgehog^.Gear) and TestColl(trunc(x), trunc(y), 6)) or
               ((Me <> CurrentHedgehog^.Gear) and TestCollExcludingMe(Me^.Hedgehog^.Gear, trunc(x), trunc(y), 6))) or (t = 0);

        EX:= trunc(x);
        EY:= trunc(y);
        if t < 50 then
            Score:= RateExplosion(Me, EX, EY, 200) + RateExplosion(Me, EX, EY + 120, 200)
        else
            Score:= BadTurn;

        if valueResult < Score then
            begin
            ap.Angle:= DxDy2AttackAnglef(Vx, Vy) + AIrndSign(random(Level));
            ap.Power:= trunc(sqrt(r) * cMaxPower) + AIrndSign(random(Level) * 15);
            ap.Time:= TestTime div 1000 * 1000;
            ap.ExplR:= 300;
            ap.ExplX:= EX;
            ap.ExplY:= EY;
            valueResult:= Score
            end;
        end
until (TestTime = 4100);
TestWatermelon:= valueResult
end;


    function Solve(TX, TY, MX, MY: LongInt): LongWord;
    var A, B, D, T: real;
        C: LongInt;
    begin
        A:= sqr(aiGravityf);
        B:= - aiGravityf * (TY - MY) - 1;
        C:= sqr(TY - MY) + sqr(TX - MX);
        D:= sqr(B) - A * C;
        if D >= 0 then
            begin
            D:= sqrt(D) - B;
            if D >= 0 then
                T:= sqrt(D * 2 / A)
            else
                T:= 0;
            Solve:= trunc(T)
            end
            else
                Solve:= 0
    end;

function TestMortar(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
const Density : real = 1.0;
var Vx, Vy: real;
    Score, EX, EY: LongInt;
    TestTime: Longword;
    x, y, dX, dY, meX, meY: real;
begin
Flags:= Flags; // avoid compiler hint
    TestMortar:= BadTurn;
    ap.ExplR:= 0;

    meX:= hwFloat2Float(Me^.X);
    meY:= hwFloat2Float(Me^.Y);

    if (Level > 2) then
        exit(BadTurn);

    TestTime:= Solve(Targ.Point.X, Targ.Point.Y, trunc(meX), trunc(meY));

    if TestTime = 0 then
        exit(BadTurn);

    Vx:= (Targ.Point.X - meX) / TestTime;
    if (GameFlags and gfMoreWind) <> 0 then
        Vx:= -(aiWindSpeed / Density) * TestTime * 0.5 + Vx;
    Vy:= aiGravityf * (TestTime div 2) - (Targ.Point.Y - meY) / TestTime;

    x:= meX;
    dX:= Vx;
    y:= meY;
    dY:= -Vy;

    repeat
        x:= x + dX;
        if (GameFlags and gfMoreWind) <> 0 then
            dX:= dX + aiWindSpeed / Density;
        y:= y + dY;
        dY:= dY + aiGravityf;
        EX:= trunc(x);
        EY:= trunc(y);
    until (((Me = CurrentHedgehog^.Gear) and TestColl(EX, EY, 4)) or
           ((Me <> CurrentHedgehog^.Gear) and TestCollExcludingMe(Me^.Hedgehog^.Gear, EX, EY, 4))) or (EY > cWaterLine);

    if (EY < cWaterLine) and (dY >= 0) then
        begin
        Score:= RateExplosion(Me, EX, EY, 91);
        if (Score = 0) then
            if (dY > 0.15) and (Targ.Kind = gtHedgehog) and (Targ.Score > 0) then
                Score:= - abs(Targ.Point.Y - EY) div 32
            else
                Score:= BadTurn
        else if (Score < 0) then
            Score:= BadTurn
        end
    else
        Score:= BadTurn;

    if Score > 0 then
        begin
        ap.Angle:= DxDy2AttackAnglef(Vx, Vy) + AIrndSign(random(Level));
        ap.Power:= 1;
        ap.ExplR:= 100;
        ap.ExplX:= EX;
        ap.ExplY:= EY;
        TestMortar:= Score
        end;
end;

function TestShotgun(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
const
    MIN_RANGE =  80;
    MAX_RANGE = 400;
var Vx, Vy, x, y: real;
    rx, ry, valueResult: LongInt;
    range: integer;
begin
Flags:= Flags; // avoid compiler hint
TestShotgun:= BadTurn;
ap.ExplR:= 0;
ap.Time:= 0;
ap.Power:= 1;
x:= hwFloat2Float(Me^.X);
y:= hwFloat2Float(Me^.Y);
range:= Metric(trunc(x), trunc(y), Targ.Point.X, Targ.Point.Y);
if ( range < MIN_RANGE ) or ( range > MAX_RANGE ) then
    exit(BadTurn);

Vx:= (Targ.Point.X - x) * 1 / 1024;
Vy:= (Targ.Point.Y - y) * 1 / 1024;
ap.Angle:= DxDy2AttackAnglef(Vx, -Vy);
// Apply inaccuracy
if (not aiLaserSighting) then
    inc(ap.Angle, AIrndSign(random((Level - 1) * 10)));
repeat
    x:= x + vX;
    y:= y + vY;
    rx:= trunc(x);
    ry:= trunc(y);
    if ((Me = CurrentHedgehog^.Gear) and TestColl(rx, ry, 2)) or
        ((Me <> CurrentHedgehog^.Gear) and TestCollExcludingMe(Me^.Hedgehog^.Gear, rx, ry, 2)) then
    begin
        x:= x + vX * 8;
        y:= y + vY * 8;
        valueResult:= RateShotgun(Me, vX, vY, rx, ry);

        if (valueResult = 0) and (Targ.Kind = gtHedgehog) and (Targ.Score > 0) then
            begin
            if GameFlags and gfSolidLand = 0 then
                 valueResult:= 1024 - Metric(Targ.Point.X, Targ.Point.Y, rx, ry) div 64
            else valueResult := BadTurn
            end
        else
            dec(valueResult, Level * 4000);
        // 27/20 is reuse bonus
        exit(valueResult * 27 div 20)
    end
until (Abs(Targ.Point.X - trunc(x)) + Abs(Targ.Point.Y - trunc(y)) < 4)
    or (x < 0)
    or (y < 0)
    or (trunc(x) > LAND_WIDTH)
    or (trunc(y) > LAND_HEIGHT);

TestShotgun:= BadTurn
end;

function TestDesertEagle(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
var Vx, Vy, x, y, t: real;
    d: Longword;
    ix, iy, valueResult: LongInt;
begin
Flags:= Flags; // avoid compiler hint
if (Level > 4) or (Targ.Score < 0) or (Targ.Kind <> gtHedgehog) then exit(BadTurn);
Level:= Level; // avoid compiler hint
ap.ExplR:= 1;
ap.Time:= 0;
ap.Power:= 1;

x:= hwFloat2Float(Me^.X);
y:= hwFloat2Float(Me^.Y);

if Abs(trunc(x) - Targ.Point.X) + Abs(trunc(y) - Targ.Point.Y) < 20 then
    exit(BadTurn);

t:= 2 / sqrt(sqr(Targ.Point.X - x)+sqr(Targ.Point.Y-y));
Vx:= (Targ.Point.X - x) * t;
Vy:= (Targ.Point.Y - y) * t;
ap.Angle:= DxDy2AttackAnglef(Vx, -Vy);
// Apply inaccuracy
if (not aiLaserSighting) then
    inc(ap.Angle, AIrndSign(random((Level - 1) * 10)));
d:= 0;

ix:= trunc(x);
iy:= trunc(y);

if ((ix and LAND_WIDTH_MASK) = 0) and ((iy and LAND_HEIGHT_MASK) = 0) then
    repeat
        if Land[iy, ix] <> 0 then
            inc(d);
        x:= x + vX;
        y:= y + vY;
        ix:= trunc(x);
        iy:= trunc(y);
    until (Abs(Targ.Point.X - ix) + Abs(Targ.Point.Y - iy) < 5)
        or (x < 0)
        or (y < 0)
        or (ix >= LAND_WIDTH)
        or (iy >= LAND_HEIGHT)
        or (d > 48);

if Abs(Targ.Point.X - ix) + Abs(Targ.Point.Y - iy) < 5 then
    begin
    ap.AttacksNum:= 1 + (d + 8) div 12;
    valueResult:= RateShove(Me, Targ.Point.X, Targ.Point.Y, 1, 7, 20, vX*0.125, vY*0.125, afTrackFall) - ap.AttacksNum
    end
else
    valueResult:= BadTurn;

TestDesertEagle:= valueResult
end;


function TestSniperRifle(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
var Vx, Vy, x, y, t, dmg: real;
    d: Longword;
    //fallDmg: LongInt;
begin
Flags:= Flags; // avoid compiler hint
if (Level > 3) or (Targ.Score < 0) or (Targ.Kind <> gtHedgehog) then exit(BadTurn);
Level:= Level; // avoid compiler hint
ap.ExplR:= 0;
ap.Time:= 0;
ap.Power:= 1;
x:= hwFloat2Float(Me^.X);
y:= hwFloat2Float(Me^.Y);
if Abs(trunc(x) - Targ.Point.X) + Abs(trunc(y) - Targ.Point.Y) < 40 then
    exit(BadTurn);

dmg:= sqrt(sqr(Targ.Point.X - x)+sqr(Targ.Point.Y-y));
t:= 1.5 / dmg;
dmg:= dmg * 0.025; // div 40
Vx:= (Targ.Point.X - x) * t;
Vy:= (Targ.Point.Y - y) * t;
ap.Angle:= DxDy2AttackAnglef(Vx, -Vy);
// Apply inaccuracy
inc(ap.Angle, AIrndSign(random((Level - 1) * 5)));

d:= 0;

repeat
    x:= x + vX;
    y:= y + vY;
    if ((trunc(x) and LAND_WIDTH_MASK) = 0)and((trunc(y) and LAND_HEIGHT_MASK) = 0)
    and (Land[trunc(y), trunc(x)] <> 0) then
        inc(d);
until (Abs(Targ.Point.X - trunc(x)) + Abs(Targ.Point.Y - trunc(y)) < 4)
    or (x < 0)
    or (y < 0)
    or (trunc(x) > LAND_WIDTH)
    or (trunc(y) > LAND_HEIGHT)
    or (d > 22);

if Abs(Targ.Point.X - trunc(x)) + Abs(Targ.Point.Y - trunc(y)) < 4 then
     TestSniperRifle:= RateShove(Me, Targ.Point.X, Targ.Point.Y, 1, trunc(dmg), 20, vX*0.166, vY*0.166, afTrackFall)
else TestSniperRifle:= BadTurn;
end;


function TestBaseballBat(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
var valueResult, a, v1, v2: LongInt;
    x, y, trackFall: LongInt;
    dx, dy: real;
begin
Flags:= Flags; // avoid compiler hint
    Targ:= Targ; // avoid compiler hint

    if Level < 3 then trackFall:= afTrackFall
        else trackFall:= 0;

    ap.ExplR:= 0;
    ap.Time:= 0;
    ap.Power:= 1;
    x:= hwRound(Me^.X);
    y:= hwRound(Me^.Y);

    a:= cMaxAngle div 2;
    valueResult:= 0;

    while a >= 0 do
        begin
        dx:= sin(a / cMaxAngle * pi) * 0.5;
        dy:= cos(a / cMaxAngle * pi) * 0.5;

        v1:= RateShove(Me, x - 10, y + 2
                , 32, 30, 115
                , -dx, -dy, trackFall);
        v2:= RateShove(Me, x + 10, y + 2
                , 32, 30, 115
                , dx, -dy, trackFall);
        if (v1 > valueResult) or (v2 > valueResult) then
            if (v2 > v1)
                or {don't encourage turning for no gain}((v2 = v1) and (not Me^.dX.isNegative)) then
                begin
                ap.Angle:= a;
                valueResult:= v2
                end
            else
                begin
                ap.Angle:= -a;
                valueResult:= v1
                end;

        a:= a - 15 - random(cMaxAngle div 16)
        end;

    if valueResult <= 0 then
        valueResult:= BadTurn;

    TestBaseballBat:= valueResult;
end;

function TestFirePunch(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
var valueResult, v1, v2, i: LongInt;
    x, y, trackFall: LongInt;
begin
Flags:= Flags; // avoid compiler hint
    Targ:= Targ; // avoid compiler hint

    if Level = 1 then trackFall:= afTrackFall
    else trackFall:= 0;

    ap.ExplR:= 0;
    ap.Time:= 0;
    ap.Power:= 1;
    x:= hwRound(Me^.X);
    y:= hwRound(Me^.Y) + 4;

    v1:= 0;
    for i:= 0 to 8 do
        begin
        v1:= v1 + RateShove(Me, x - 5, y - 10 * i
                , 19, 30, 40
                , -0.45, -0.9, trackFall or afSetSkip);
        end;
    v1:= v1 + RateShove(Me, x - 5, y - 90
            , 19, 30, 40
            , -0.45, -0.9, trackFall);


    // now try opposite direction
    v2:= 0;
    for i:= 0 to 8 do
        begin
        v2:= v2 + RateShove(Me, x + 5, y - 10 * i
                , 19, 30, 40
                , 0.45, -0.9, trackFall or afSetSkip);
        end;
    v2:= v2 + RateShove(Me, x + 5, y - 90
            , 19, 30, 40
            , 0.45, -0.9, trackFall);

    if (v2 > v1)
        or {don't encourage turning for no gain}((v2 = v1) and (not Me^.dX.isNegative)) then
        begin
        ap.Angle:= 1;
        valueResult:= v2
        end
    else
        begin
        ap.Angle:= -1;
        valueResult:= v1
        end;

    if valueResult <= 0 then
        valueResult:= BadTurn;

    TestFirePunch:= valueResult;
end;


function TestWhip(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
var valueResult, v1, v2: LongInt;
    x, y, trackFall: LongInt;
begin
Flags:= Flags; // avoid compiler hint
    Targ:= Targ; // avoid compiler hint

    if Level = 1 then trackFall:= afTrackFall
    else trackFall:= 0;

    ap.ExplR:= 0;
    ap.Time:= 0;
    ap.Power:= 1;
    x:= hwRound(Me^.X);
    y:= hwRound(Me^.Y);

    // check left direction
    {first RateShove checks farthermost of two whip's AmmoShove attacks
    to encourage distant attacks (damaged hog is excluded from view of second
    RateShove call)}
    v1:= RateShove(Me, x - 13, y
            , 30, 30, 25
            , -1, -0.8, trackFall or afSetSkip);
    v1:= v1 +
        RateShove(Me, x - 2, y
            , 30, 30, 25
            , -1, -0.8, trackFall);
    // now try opposite direction
    v2:= RateShove(Me, x + 13, y
            , 30, 30, 25
            , 1, -0.8, trackFall or afSetSkip);
    v2:= v2 +
        RateShove(Me, x + 2, y
            , 30, 30, 25
            , 1, -0.8, trackFall);

    if (v2 > v1)
        or {don't encourage turning for no gain}((v2 = v1) and (not Me^.dX.isNegative)) then
        begin
        ap.Angle:= 1;
        valueResult:= v2
        end
    else
        begin
        ap.Angle:= -1;
        valueResult:= v1
        end;

    if valueResult <= 0 then
        valueResult:= BadTurn
    else
        inc(valueResult);

    TestWhip:= valueResult;
end;

function TestKamikaze(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
const step = 8;
var valueResult, i, v, tx: LongInt;
    trackFall: LongInt;
    t, d, x, y, dx, dy, cx: real;
begin
Flags:= Flags; // avoid compiler hint
    ap.ExplR:= 0;
    ap.Time:= 0;
    ap.Power:= 1;

    if Level = 1 then
        trackFall:= afTrackFall
    else if Level = 2 then
        trackFall:= 0
    else
        exit(BadTurn);

    valueResult:= 0;
    v:= 0;

    x:= hwFloat2Float(Me^.X);
    y:= hwFloat2Float(Me^.Y);
    d:= sqrt(sqr(Targ.Point.X - x) + sqr(Targ.Point.Y - y));
    if d < 10 then
        begin
        dx:= 0;
        dy:= step;
        ap.Angle:= 2048
        end
    else
        begin
        t:= step / d;
        dx:= (Targ.Point.X - x) * t;
        dy:= (Targ.Point.Y - y) * t;

        ap.Angle:= DxDy2AttackAnglef(dx, -dy);
        // Apply inaccuracy
        if (not aiLaserSighting) then
            inc(ap.Angle, AIrndSign(random((Level - 1) * 10)));
        end;

    if dx >= 0 then cx:= 0.45 else cx:= -0.45;

    for i:= 1 to 512 div step - 2 do
        begin
        x:= x + dx;
        y:= y + dy;

        valueResult:= valueResult +
            RateShove(Me, trunc(x), trunc(y)
                , 30, 30, 25
                , cx, -0.9, trackFall or afSetSkip or afIgnoreMe);
        end;

    if (d < 10) and (dx = 0) then
        begin
        x:= hwFloat2Float(Me^.X);
        y:= hwFloat2Float(Me^.Y);
        tx:= trunc(x);
        v:= RateShove(Me, tx, trunc(y)
                , 30, 30, 25
                , -cx, -0.9, trackFall or afIgnoreMe);
        for i:= 1 to 512 div step - 2 do
            begin
            y:= y + dy;
            v:= v +
                RateShove(Me, tx, trunc(y)
                    , 30, 30, 25
                    , -cx, -0.9, trackFall or afSetSkip or afIgnoreMe);
            end
        end;

    if v > valueResult then
    begin
        cx:= -cx;
        ap.Angle:= -2048;
        valueResult:= v
        end;

    v:= RateShove(Me, trunc(x), trunc(y)
            , 30, 30, 25
            , cx, -0.9, trackFall or afIgnoreMe);
    valueResult:= valueResult + v - KillScore * friendlyfactor div 100 * 1024;

    if v < 65536 then
        inc(valueResult, RateExplosion(Me, trunc(x), trunc(y), 30, afIgnoreMe));

    TestKamikaze:= valueResult;
end;

function TestHammer(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
var rate: LongInt;
begin
Flags:= Flags; // avoid compiler hint
Level:= Level; // avoid compiler hint
Targ:= Targ;

ap.ExplR:= 0;
ap.Time:= 0;
ap.Power:= 1;
ap.Angle:= 0;

rate:= RateHammer(Me);
if rate = 0 then
    rate:= BadTurn;
TestHammer:= rate;
end;

function TestAirAttack(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
const cShift = 4;
      Density : real = 2.0;
var bombsSpeed, X, Y, dX, dY: real;
    b: array[0..9] of boolean;
    dmg: array[0..9] of LongInt;
    fexit, firstHit: boolean;
    i, t, valueResult, targetY: LongInt;
begin
Flags:= Flags; // avoid compiler hint
ap.ExplR:= 0;
ap.Time:= 0;
if (Level > 3) or (aiGravityf = 0) then
    exit(BadTurn);

ap.Angle:= 0;
ap.AttackPutX:= Targ.Point.X;
ap.AttackPutY:= Targ.Point.Y;

bombsSpeed:= hwFloat2Float(cBombsSpeed);
X:= Targ.Point.X - 135 - cShift; // hh center - cShift
X:= X - bombsSpeed * sqrt(((Targ.Point.Y + 128) * 2) / aiGravityf);
Y:= topY - 300;

dX:= bombsSpeed;
dY:= 0;

for i:= 0 to 9 do
    begin
    b[i]:= true;
    dmg[i]:= 0
    end;
valueResult:= 0;
firstHit:= false;

repeat
    X:= X + dX;
    if (GameFlags and gfMoreWind) <> 0 then
        dX:= dX + aiWindSpeed / Density;
    Y:= Y + dY;
    dY:= dY + aiGravityf;
    fexit:= true;

    for i:= 0 to 9 do
        if b[i] then
            begin
            fexit:= false;
            if TestColl(trunc(X) + LongWord(i * 30), trunc(Y), 4) then
                begin
                b[i]:= false;
                if Level = 1 then
                    dmg[i]:= RateExplosion(Me, trunc(X) + LongWord(i * 30), trunc(Y), 58, afTrackFall or afErasesLand)
                else
                    dmg[i]:= RateExplosion(Me, trunc(X) + LongWord(i * 30), trunc(Y), 58);
                // 58 (instead of 60) for better prediction (hh moves after explosion of one of the rockets)
                if (not firstHit) then
                    begin
                    firstHit:= true;
                    // remember Y of first hit, used for target pos
                    targetY:= trunc(Y);
                    end;
                end
            end;
until fexit or (Y > cWaterLine);

for i:= 0 to 5 do
    if dmg[i] <> BadTurn then
        inc(valueResult, dmg[i]);
t:= valueResult;
ap.AttackPutX:= Targ.Point.X - 60;
if firstHit then
    // this is not strictly neccessry, it's just to make sure
    // the X is on the height of the first hit
    ap.AttackPutY:= targetY;

for i:= 0 to 3 do
    if dmg[i] <> BadTurn then
        begin
        dec(t, dmg[i]);
        inc(t, dmg[i + 6]);
        if t > valueResult then
            begin
            valueResult:= t;
            ap.AttackPutX:= Targ.Point.X - 30 - cShift + i * 30
            end
        end;

if valueResult <= 0 then
    valueResult:= BadTurn;
TestAirAttack:= valueResult;
end;

function TestResurrector(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
var rate, heal: LongInt;
begin
Flags:= Flags; // avoid compiler hint
Targ:= Targ;

if (Level = 5) then
    exit(BadTurn);

if (Me^.Health <= 1) then
    exit(BadTurn);

if (Level <= 2) and (Me^.Hedgehog^.Effects[hePoisoned] > 0) then
    // Sacrifice almost all health if poisoned
    heal:= Me^.Health - 1
else
    // Sacrifice up to 10% of own health
    heal:= (Me^.Health div 10);

ap.ExplR:= 0;
ap.Time:= 0;
if (Level >= 4) then
    // slow resurrect
    ap.Power:= max(512 * heal - 512, 10)
else
    // fast resurrect
    ap.Power:= max(16 * heal - 16, 10);

// Time limit
ap.Power:= min(ap.Power, 5000);

ap.Angle:= 0;

rate:= RateResurrector(Me);
if rate <= 0 then
    rate:= BadTurn;
TestResurrector:= rate;
end;

function TestDrillStrike(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
const cShift = 4;
      Density : real = 1.0;
var bombsSpeed, X, Y, dX, dY, drillX, drillY: real;
    t2: real;
    dmg: array[0..9] of LongInt;
    collided, drilling, timerRuns, firstHit: boolean;
    i, t, value, valueResult, attackTime, drillTimer, targetX, targetY: LongInt;
begin
Flags:= Flags; // avoid compiler hint
ap.ExplR:= 0;
if (Level > 3) or (aiGravityf = 0) then
    exit(BadTurn);

ap.Angle:= 0;
targetX:= Targ.Point.X;
ap.AttackPutY:= Targ.Point.Y;

bombsSpeed:= hwFloat2Float(cBombsSpeed);
X:= Targ.Point.X - 135 - cShift; // hh center - cShift
X:= X - bombsSpeed * sqrt(((Targ.Point.Y + 128) * 2) / aiGravityf);
Y:= topY - 300;

valueResult:= 0;

attackTime:= 6000;
while attackTime >= 0 do
    begin
    dec(attackTime, 1000);
    value:= 0;
    firstHit:= false;
    for i:= 0 to 9 do
        begin
        dmg[i]:= 0;
        drillX:= trunc(X) + LongWord(i * 30);
        drillY:= trunc(Y);
        dX:= bombsSpeed;
        dY:= 0;
        collided:= false;
        drilling:= false;
        timerRuns:= false;
        drillTimer := attackTime;

        repeat
            // Simulate in-air movement
            drillX:= drillX + dX;
            drillY:= drillY + dY;
            if (GameFlags and gfMoreWind) <> 0 then
                dX:= dX + aiWindSpeed / Density;
            dY:= dY + aiGravityf;

            if timerRuns then
                dec(drillTimer);

            // Collided with land ... simulate drilling
            if (drillTimer > 0) and TestCollExcludingObjects(trunc(drillX), trunc(drillY), 4) and
                (Abs(Targ.Point.X - trunc(drillX)) + Abs(Targ.Point.Y - trunc(drillY)) > 21) then
                begin
                drilling := true;
                timerRuns := true;
                t2 := 0.5 / sqrt(sqr(dX) + sqr(dY));
                dX := dX * t2;
                dY := dY * t2;
                repeat
                    drillX:= drillX + dX;
                    drillY:= drillY + dY;
                    dec(drillTimer, 10);
                    if (Abs(Targ.Point.X - drillX) + Abs(Targ.Point.Y - drillY) < 22)
                        or (drillX < -32)
                        or (drillY < -32)
                        or (trunc(drillX) > LAND_WIDTH + 32)
                        or (trunc(drillY) > cWaterLine)
                        or (drillTimer <= 0) then
                        collided:= true
                    else if not TestCollExcludingObjects(trunc(drillX), trunc(drillY), 4) then
                        drilling:= false;
                until (collided or (not drilling));
                end
            // Collided with something else ... record collision
            else if (drillTimer <= 0) or TestColl(trunc(drillX), trunc(drillY), 4) then
                collided:= true;

            // Simulate explosion
            if collided then
                begin
                if Level = 1 then
                    dmg[i]:= RateExplosion(Me, trunc(drillX), trunc(drillY), 58, afTrackFall or afErasesLand)
                else
                    dmg[i]:= RateExplosion(Me, trunc(drillX), trunc(drillY), 58);
                // 58 (instead of 60) for better prediction (hh moves after explosion of one of the rockets)
                if not firstHit then
                    begin
                    targetY:= trunc(drillY);
                    firstHit:= true;
                    end;
                end;
        until collided or (drillY > cWaterLine);
        end;

    // calculate score
    for i:= 0 to 5 do
        if dmg[i] <> BadTurn then
            inc(value, dmg[i]);
    t:= value;
    targetX:= Targ.Point.X - 60;

    for i:= 0 to 3 do
        if dmg[i] <> BadTurn then
            begin
            dec(t, dmg[i]);
            inc(t, dmg[i + 6]);
            if t > value then
                begin
                value:= t;
                targetX:= Targ.Point.X - 30 - cShift + i * 30
                end
            end;

    if value > valueResult then
        begin
        valueResult:= value;
        ap.AttackPutX:= targetX;
        if firstHit then
            ap.AttackPutY:= targetY;
        ap.Time:= attackTime;
        end;
end;

if valueResult <= 0 then
    valueResult:= BadTurn
else
    begin
    // Weaker AI has chance to get the time wrong by 1-3 seconds
    if Level = 5 then
        // +/- 3 seconds
        ap.Time:= ap.Time + (3 - random(7)) * 1000
    else if Level = 4 then
        // +/- 2 seconds
        ap.Time:= ap.Time + (2 - random(5)) * 1000
    else if Level = 3 then
        // +/- 1 second
        if (random(2) = 0) then
            ap.Time:= ap.Time + (1 - random(3)) * 1000
    else if Level = 2 then
        // 50% chance for +/- 1 second
        if (random(2) = 0) then
            ap.Time:= ap.Time + (1 - random(3)) * 1000;
    ap.Time:= Min(5000, Max(1000, ap.Time));
    end;

TestDrillStrike:= valueResult;
end;

function TestMineStrike(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
const cShift = 4;
      Density : real = 1.0;
var minesSpeed, X, Y, dX, dY: real;
    b: array[0..9] of boolean;
    dmg: array[0..9] of LongInt;
    fexit, firstHit: boolean;
    i, t, valueResult, targetY: LongInt;
begin
Flags:= Flags; // avoid compiler hint
ap.ExplR:= 0;
ap.Time:= 0;

// AI currently only supports cMinesTime = 0 because it's the most
// predictable.
// Other cMinesTime values are risky because of bouncy mines;
// so they are unsupported.
// TODO: Implement mine strike for other values of MineTime
// TODO: Teach AI to avoid hitting their own with mines
if (Level > 3) or (aiGravityf = 0) or (cMinesTime <> 0) then
    exit(BadTurn);

ap.Angle:= 0;
ap.AttackPutX:= Targ.Point.X;
ap.AttackPutY:= Targ.Point.Y;

minesSpeed:= hwFloat2Float(cBombsSpeed);
X:= Targ.Point.X - 135 - cShift; // hh center - cShift
X:= X - minesSpeed * sqrt(((Targ.Point.Y + 128) * 2) / aiGravityf);
Y:= topY - 300;
dX:= minesSpeed;
dY:= 0;

for i:= 0 to 9 do
    begin
    b[i]:= true;
    dmg[i]:= 0
    end;
valueResult:= 0;
firstHit:= false;

repeat
    X:= X + dX;
    if (GameFlags and (gfMoreWind or gfInfAttack)) <> 0 then
        dX:= dX + aiWindSpeed / Density;
    Y:= Y + dY;
    dY:= dY + aiGravityf;
    fexit:= true;

    for i:= 0 to 9 do
        if b[i] then
            begin
            fexit:= false;
            if TestColl(trunc(X) + LongWord(i * 30), trunc(Y), 4) then
                begin
                b[i]:= false;
                if Level = 1 then
                    dmg[i]:= RateExplosion(Me, trunc(X) + LongWord(i * 30), trunc(Y), 96, afTrackFall or afErasesLand)
                else
                    dmg[i]:= RateExplosion(Me, trunc(X) + LongWord(i * 30), trunc(Y), 96);

                if (not firstHit) then
                    begin
                    targetY:= trunc(Y);
                    firstHit:= true;
                    end;
                end
            end;
until fexit or (Y > cWaterLine);

for i:= 0 to 5 do
    if dmg[i] <> BadTurn then
        inc(valueResult, dmg[i]);
t:= valueResult;
ap.AttackPutX:= Targ.Point.X - 60;
if firstHit then
    ap.AttackPutY:= targetY;

for i:= 0 to 3 do
    if dmg[i] <> BadTurn then
        begin
        dec(t, dmg[i]);
        inc(t, dmg[i + 6]);
        if t > valueResult then
            begin
            valueResult:= t;
            ap.AttackPutX:= Targ.Point.X - 30 - cShift + i * 30
            end
        end;

if valueResult <= 0 then
    valueResult:= BadTurn;
TestMineStrike:= valueResult;
end;

function TestSMine(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
const timeLimit = 50;
      Density : real = 1.6;
var Vx, Vy, r, meX, meY: real;
    rTime: LongInt;
    EX, EY: LongInt;
    valueResult: LongInt;
    targXWrap, x, y, dX, dY: real;
    t: LongInt;
    value: LongInt;
begin
Flags:= Flags; // avoid compiler hint
meX:= hwFloat2Float(Me^.X);
meY:= hwFloat2Float(Me^.Y);
ap.Time:= 0;
rTime:= 350;
ap.ExplR:= 0;
if (WorldEdge = weWrap) then
    if (Targ.Point.X < meX) then
         targXWrap:= Targ.Point.X + (RightX-LeftX)
    else targXWrap:= Targ.Point.X - (RightX-LeftX);
valueResult:= BadTurn;
repeat
    rTime:= rTime + 300 + Level * 50 + random(300);
    if (WorldEdge = weWrap) and (random(2)=0) then
         Vx:= (targXWrap + AIrndSign(2) + AIrndOffset(Targ, Level) - meX) / rTime
    else
         Vx:= (Targ.Point.X + AIrndSign(2) + AIrndOffset(Targ, Level) - meX) / rTime;
    if (GameFlags and gfMoreWind) <> 0 then
         Vx:= -(aiWindSpeed / Density) * rTime * 0.5 + Vx;
    Vy:= aiGravityf * rTime * 0.5 - (Targ.Point.Y + 1 - meY) / rTime;
    r:= sqr(Vx) + sqr(Vy);

    if not (r > 1) then
        begin
        x:= meX;
        y:= meY;
        dX:= Vx;
        dY:= -Vy;
        t:= rTime;
        repeat
            x:= CheckWrap(x);
            x:= x + dX;
            if (GameFlags and gfMoreWind) <> 0 then
                dX:= dX + aiWindSpeed / Density;

            y:= y + dY;
            dY:= dY + aiGravityf;
            dec(t)
        until (((Me = CurrentHedgehog^.Gear) and TestColl(trunc(x), trunc(y), 2)) or
               ((Me <> CurrentHedgehog^.Gear) and TestCollExcludingMe(Me^.Hedgehog^.Gear, trunc(x), trunc(y), 2))) or (t < -timeLimit);

        EX:= trunc(x);
        EY:= trunc(y);

        if t >= -timeLimit then
            if (Level = 1) and (Flags and amtest_NoTrackFall = 0) then
                value:= RateExplosion(Me, EX, EY, 61, afTrackFall)
            else
                value:= RateExplosion(Me, EX, EY, 61);

        if (value = 0) and (Targ.Kind = gtHedgehog) and (Targ.Score > 0) then
            value := BadTurn;

        if (valueResult < value) or ((valueResult = value) and (Level < 3)) then
            begin
            ap.Angle:= DxDy2AttackAnglef(Vx, Vy) + AIrndSign(random((Level - 1) * 9));
            ap.Power:= trunc(sqrt(r) * cMaxPower) - random((Level - 1) * 17 + 1);
            ap.ExplR:= 60;
            ap.ExplX:= EX;
            ap.ExplY:= EY;
            valueResult:= value
            end;
        end
until rTime > 5050 - Level * 800;
TestSMine:= valueResult
end;

function TestPiano(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
const BOUNCES = 5;
var X, Y: real;
    dmg: array[0..BOUNCES-1] of LongInt;
    i, e, rate, valueResult, targetY: LongInt;
    firstHit, solidBounce: boolean;
begin
Flags:= Flags; // avoid compiler hint
ap.ExplR:= 0;
ap.Time:= 0;
if (aiGravityf <= 0) then
    exit(BadTurn);

if (Level > 2) then
    exit(BadTurn);

ap.Angle:= 0;
ap.AttackPutX:= Targ.Point.X;
ap.AttackPutY:= Targ.Point.Y;

X:= Targ.Point.X;
Y:= -1024;

for i:= 0 to BOUNCES-1 do
    dmg[i]:= 0;

i:= 1;
firstHit:= false;
solidBounce:= false;
repeat
    // Piano goes down
    if (not solidBounce) then
        Y:= Y + 11;
    if solidBounce or TestCollExcludingMe(Me^.Hedgehog^.Gear, trunc(X), trunc(Y), 32) then
        begin
        if (not firstHit) then
            targetY:= trunc(Y);
        firstHit:= true;
        if (GameFlags and gfSolidLand) <> 0 then
            // Don't change Y when indestructible land was hit
            solidBounce:= true;

        for e:= -1 to 1 do
            begin
            rate:= RateExplosion(Me, trunc(X) + 30*e, trunc(Y)+40, 161, afIgnoreMe);
            if rate <> BadTurn then
                dmg[i]:= dmg[i] + rate;
            end;

        if (i > 1) and (dmg[i] > 0) then
            dmg[i]:= dmg[i] div 2;
        inc(i);
        if (not solidBounce) then
            // Skip past the blast hole
            Y:= Y + 41
        end;
until (i > BOUNCES) or (Y > cWaterLine);

if (i = 0) and (Y > cWaterLine) then
    exit(BadTurn);

valueResult:= 0;
for i:= 0 to BOUNCES do
    if dmg[i] <= BadTurn then
        begin
        valueResult:= BadTurn;
        break;
        end
    else
        inc(valueResult, dmg[i]);
ap.AttackPutX:= Targ.Point.X;
if firstHit then
    ap.AttackPutY:= targetY;

valueResult:= valueResult - KillScore * friendlyfactor div 100 * 1024;

if valueResult <= 0 then
    valueResult:= BadTurn;
TestPiano:= valueResult;
end;

function TestTeleport(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
var
    i, failNum: longword;
    maxTop: longword;
begin
Flags:= Flags; // avoid compiler hint
    TestTeleport := BadTurn;
    exit(BadTurn);
    Level:= Level; // avoid compiler hint
    //FillBonuses(true, [gtCase]);
    if bonuses.Count = 0 then
        begin
        if Me^.Health <= 100  then
            begin
            maxTop := Targ.Point.Y - cHHRadius * 2;

            while not TestColl(Targ.Point.X, maxTop, cHHRadius) and (maxTop > topY + cHHRadius * 2 + 1) do
                dec(maxTop, cHHRadius*2);
            if not TestColl(Targ.Point.X, maxTop + cHHRadius, cHHRadius) then
                begin
                ap.AttackPutX := Targ.Point.X;
                ap.AttackPutY := maxTop + cHHRadius;
                TestTeleport := Targ.Point.Y - maxTop;
                end;
            end;
        end
    else
        begin
        failNum := 0;
        repeat
            i := random(bonuses.Count);
            inc(failNum);
        until not TestColl(bonuses.ar[i].X, bonuses.ar[i].Y - cHHRadius - bonuses.ar[i].Radius, cHHRadius)
        or (failNum = bonuses.Count*2);

        if failNum < bonuses.Count*2 then
            begin
            ap.AttackPutX := bonuses.ar[i].X;
            ap.AttackPutY := bonuses.ar[i].Y - cHHRadius - bonuses.ar[i].Radius;
            TestTeleport := 0;
            end;
        end;
end;


procedure checkCakeWalk(Me, Gear: PGear; var ap: TAttackParams);
var i: Longword;
    v: LongInt;
begin
while (not TestColl(hwRound(Gear^.X), hwRound(Gear^.Y), 6)) and (Gear^.Y.Round < LongWord(LAND_HEIGHT)) do
    Gear^.Y:= Gear^.Y + _1;

for i:= 0 to 2040 do
    begin
    cakeStep(Gear);
    v:= RateExplosion(Me, hwRound(Gear^.X), hwRound(Gear^.Y), cakeDmg * 2, afTrackFall);
    if v > ap.Power then
        begin
        ap.ExplX:= hwRound(Gear^.X);
        ap.ExplY:= hwRound(Gear^.Y);
        ap.Power:= v
        end
    end;
end;

function TestCake(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
var valueResult, v1, v2: LongInt;
    cake: TGear;
begin
Flags:= Flags; // avoid compiler hint
    Targ:= Targ; // avoid compiler hint

    if (Level > 2) then
        exit(BadTurn);

    ap.ExplR:= 0;
    ap.Time:= 0;
    ap.Power:= BadTurn; // use it as max score value in checkCakeWalk

    //FillChar(cake, sizeof(cake), 0);
    cake.Radius:= 7;
    cake.CollisionMask:= lfNotCurHogCrate;
    cake.Hedgehog:= Me^.Hedgehog;
    cake.Kind:= gtCake;

    // check left direction
    cake.Angle:= 3;
    cake.dX.isNegative:= true;
    cake.dX.QWordValue:= 0;
    cake.dY:= _0;
    cake.X:= Me^.X - _3;
    cake.Y:= Me^.Y;
    checkCakeWalk(Me, @cake, ap);
    v1:= ap.Power;

    // now try opposite direction
    cake.Angle:= 1;
    cake.dX.isNegative:= false;
    cake.X:= Me^.X + _3;
    cake.Y:= Me^.Y;
    checkCakeWalk(Me, @cake, ap);
    v2:= ap.Power;

    ap.Power:= 1;

    if (v2 > v1) then
        begin
        ap.Angle:= 1;
        valueResult:= v2
        end
    else
        begin
        ap.Angle:= -1;
        valueResult:= v1
        end;

    if valueResult <= 0 then
        valueResult:= BadTurn;

    TestCake:= valueResult;
end;

function TestSeduction(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
var rate: LongInt;
begin
Flags:= Flags; // avoid compiler hint
Level:= Level; // avoid compiler hint
Targ:= Targ;

if (Level = 5) then
    exit(BadTurn);

ap.ExplR:= 0;
ap.Time:= 0;
ap.Power:= 1;
ap.Angle:= 0;

rate:= RateSeduction(Me);
if rate <= 0 then
    rate:= BadTurn;
TestSeduction:= rate;
end;

function TestDynamite(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
const Density : real = 2.0;
var valueResult: LongInt;
    x, y, dx, dy: real;
    EX, EY, t: LongInt;
begin
Flags:= Flags; // avoid compiler hint
Targ:= Targ; // avoid compiler hint

x:= hwFloat2Float(Me^.X) + hwSign(Me^.dX) * 7;
y:= hwFloat2Float(Me^.Y);
dx:= hwSign(Me^.dX) * 0.03;
if (GameFlags and gfMoreWind) <> 0 then
    dx:= -(aiWindSpeed / Density) + dx;
dy:= 0;
t:= 5000;
repeat
    dec(t);
    if (GameFlags and gfMoreWind) <> 0 then
        dx:= dx + aiWindSpeed / Density;
    x:= x + dx;
    dy:= dy + aiGravityf;
    y:= y + dy;

    if TestColl(trunc(x), trunc(y), 3) then
        t:= 0;
until t = 0;

EX:= trunc(x);
EY:= trunc(y);

if Level = 1 then
    valueResult:= RateExplosion(Me, EX, EY, 76, afTrackFall or afErasesLand)
else
    valueResult:= RateExplosion(Me, EX, EY, 76);

if (valueResult > 0) then
    begin
    ap.Angle:= 0;
    ap.Power:= 1;
    ap.Time:= 0;
    ap.ExplR:= 150;
    ap.ExplX:= EX;
    ap.ExplY:= EY
    end else
    valueResult:= BadTurn;

TestDynamite:= valueResult
end;

function TestMine(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
const Density : real = 1.0;
var valueResult: LongInt;
    x, y, dx, dy: real;
    EX, EY, t: LongInt;
begin
Flags:= Flags; // avoid compiler hint
Targ:= Targ; // avoid compiler hint

x:= hwFloat2Float(Me^.X) + hwSign(Me^.dX) * 7;
y:= hwFloat2Float(Me^.Y);
dx:= hwSign(Me^.dX) * 0.02;
if (GameFlags and gfMoreWind) <> 0 then
    dx:= -(aiWindSpeed / Density) + dx;
dy:= 0;
t:= 10000;
repeat
    dec(t);
    if (GameFlags and gfMoreWind) <> 0 then
         dx:= dx + aiWindSpeed / Density;
    x:= x + dx;
    dy:= dy + aiGravityf;
    y:= y + dy;
    if ((Me = CurrentHedgehog^.Gear) and TestColl(trunc(x), trunc(y), 2)) or
        ((Me <> CurrentHedgehog^.Gear) and TestCollExcludingMe(Me^.Hedgehog^.Gear, trunc(x), trunc(y), 2)) then
        t:= 0;
until t = 0;

EX:= trunc(x);
EY:= trunc(y);

if Level = 1 then
    valueResult:= RateExplosion(Me, EX, EY, 51, afTrackFall or afErasesLand)
else
    valueResult:= RateExplosion(Me, EX, EY, 51);

if (valueResult > 0) then
    begin
    ap.Angle:= 0;
    ap.Power:= 1;
    ap.Time:= 0;
    if (Level < 5) then
        // Set minimum mine bounciness for improved aim
        ap.Bounce:= 1
    else
        ap.Bounce:= 0;
    ap.ExplR:= 100;
    ap.ExplX:= EX;
    ap.ExplY:= EY
    end else
    valueResult:= BadTurn;

TestMine:= valueResult
end;

function TestKnife(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
const timeLimit = 300;
      Density : real = 4.0;
var Vx, Vy, r, meX, meY: real;
    rTime: LongInt;
    EX, EY: LongInt;
    valueResult: LongInt;
    targXWrap, x, y, dX, dY: real;
    t: LongInt;
    value, range: LongInt;
begin
Flags:= Flags; // avoid compiler hint
meX:= hwFloat2Float(Me^.X);
meY:= hwFloat2Float(Me^.Y);
ap.Time:= 0;
rTime:= 350;
ap.ExplR:= 0;
if (WorldEdge = weWrap) then
    if (Targ.Point.X < meX) then
         targXWrap:= Targ.Point.X + (RightX-LeftX)
    else
         targXWrap:= Targ.Point.X - (RightX-LeftX);
valueResult:= BadTurn;
repeat
    rTime:= rTime + 300 + Level * 50 + random(300);
    if (WorldEdge = weWrap) and (random(2)=0) then
         Vx:= (targXWrap - meX) / rTime
    else
         Vx:= (Targ.Point.X - meX) / rTime;
    if (GameFlags and gfMoreWind) <> 0 then
         Vx:= -(aiWindSpeed / Density) * rTime * 0.5 + Vx;
    Vy:= aiGravityf * rTime * 0.5 - (Targ.Point.Y + 1 - meY) / rTime;
    r:= sqr(Vx) + sqr(Vy);

    if not (r > 1) then
        begin
        x:= meX;
        y:= meY;
        dX:= Vx;
        dY:= -Vy;
        t:= rTime;
        repeat
            x:= CheckWrap(x);
            x:= x + dX;
            if (GameFlags and gfMoreWind) <> 0 then
                dX:= dX + aiWindSpeed / Density;

            y:= y + dY;
            dY:= dY + aiGravityf;
            dec(t)
        until (((Me = CurrentHedgehog^.Gear) and TestColl(trunc(x), trunc(y), 7)) or
               ((Me <> CurrentHedgehog^.Gear) and TestCollExcludingMe(Me^.Hedgehog^.Gear, trunc(x), trunc(y), 7))) or (t < -timeLimit);

        EX:= trunc(x);
        EY:= trunc(y);

        // Sanity check: Make sure we're not too close to impact location
        range:= Metric(trunc(meX), trunc(meY), EX, EY);
        if (range <= 40) then
            exit(BadTurn);

        if t >= -timeLimit then
            value:= RateShove(Me, EX, EY, 16, trunc(sqr((abs(dY)+abs(dX))*40000/10000)), 0, dX, dY, 0)
        else
            value:= BadTurn;

        if (value = 0) and (Targ.Kind = gtHedgehog) and (Targ.Score > 0) then
            value := BadTurn;

        if (valueResult < value) or ((valueResult = value) and (Level = 1)) then
            begin
            ap.Angle:= DxDy2AttackAnglef(Vx, Vy) + AIrndSign(random((Level - 1) * 12));
            ap.Power:= trunc(sqrt(r) * cMaxPower) - random((Level - 1) * 22 + 1);
            valueResult:= value
            end;
        end
until rTime > 5050 - Level * 800;
TestKnife:= valueResult
end;

function TestAirMine(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
const
    MIN_RANGE = 160;
    MAX_RANGE = 2612;
var Vx, Vy, meX, meY, x, y, r: real;
    rx, ry, valueResult: LongInt;
    range, maxRange: integer;
begin
Flags:= Flags; // avoid compiler hint
maxRange:= MAX_RANGE - ((Level - 1) * 300);
TestAirMine:= BadTurn;
ap.ExplR:= 60;
ap.Time:= 0;
meX:= hwFloat2Float(Me^.X);
meY:= hwFloat2Float(Me^.Y);
x:= meX;
y:= meY;

// Rough first range check
range:= Metric(trunc(x), trunc(y), Targ.Point.X, Targ.Point.Y);
if ( range < MIN_RANGE ) or ( range > maxRange ) then
    exit(BadTurn);

Vx:= (Targ.Point.X - x) * 1 / 1024;
Vy:= (Targ.Point.Y - y) * 1 / 1024;
ap.Angle:= DxDy2AttackAnglef(Vx, -Vy);
repeat
    x:= x + vX;
    y:= y + vY;
    rx:= trunc(x);
    ry:= trunc(y);
    if ((Me = CurrentHedgehog^.Gear) and TestColl(rx, ry, 8)) or
        ((Me <> CurrentHedgehog^.Gear) and TestCollExcludingMe(Me^.Hedgehog^.Gear, rx, ry, 8)) then
        begin
        x:= x + vX * 8;
        y:= y + vY * 8;

        if Level = 1 then
            valueResult:= RateExplosion(Me, rx, ry, 61, afTrackFall)
        else
            valueResult:= RateExplosion(Me, rx, ry, 61);

        // Precise range calculation required to calculate power;
        // The air mine is very sensitive to small changes in power.
        r:= sqr(meX - rx) + sqr(meY - ry);
        range:= trunc(sqrt(r));

        if ( range < MIN_RANGE ) or ( range > maxRange ) then
            exit(BadTurn);
        ap.Power:= ((range + cHHRadius*2) * cMaxPower) div MAX_RANGE;

        // Apply inaccuracy
        inc(ap.Power, (random(93*(Level-1)) - 31*(Level-1))); // Level 1 spread: -124 .. 248
        if (not aiLaserSighting) then
            inc(ap.Angle, AIrndSign(random((Level - 1) * 10)));

        if (valueResult <= 0) then
            valueResult:= BadTurn;
        exit(valueResult)
        end
until (abs(Targ.Point.X - trunc(x)) + abs(Targ.Point.Y - trunc(y)) < 4)
    or (x < 0)
    or (y < 0)
    or (trunc(x) > LAND_WIDTH)
    or (trunc(y) > LAND_HEIGHT);

TestAirMine := BadTurn
end;

function TestMinigun(Me: PGear; Targ: TTarget; Level: LongInt; var ap: TAttackParams; Flags: LongWord): LongInt;
const
    MAX_RANGE = 400;
var Vx, Vy, x, y: real;
    rx, ry, valueResult: LongInt;
    range: integer;
begin
// This code is still very similar to TestShotgun,
// but it's a good simple estimate.
// TODO: Simulate random bullets
// TODO: Replace RateShotgun with something else
// TODO: Teach AI to move aim during shooting
Flags:= Flags; // avoid compiler hint
TestMinigun:= BadTurn;
ap.ExplR:= 0;
ap.Time:= 0;
ap.Power:= 1;
x:= hwFloat2Float(Me^.X);
y:= hwFloat2Float(Me^.Y);
range:= Metric(trunc(x), trunc(y), Targ.Point.X, Targ.Point.Y);
if ( range > MAX_RANGE ) then
    exit(BadTurn);

Vx:= (Targ.Point.X - x) * 1 / 1024;
Vy:= (Targ.Point.Y - y) * 1 / 1024;
ap.Angle:= DxDy2AttackAnglef(Vx, -Vy);
// Minigun angle is limited
if (ap.Angle < Ammoz[amMinigun].minAngle) or (ap.Angle > Ammoz[amMinigun].maxAngle) then
    exit(BadTurn);

// Apply inaccuracy
if (not aiLaserSighting) then
    inc(ap.Angle, AIrndSign(random((Level - 1) * 10)));
repeat
    x:= x + vX;
    y:= y + vY;
    rx:= trunc(x);
    ry:= trunc(y);
    if ((Me = CurrentHedgehog^.Gear) and TestColl(rx, ry, 1)) or
        ((Me <> CurrentHedgehog^.Gear) and TestCollExcludingMe(Me^.Hedgehog^.Gear, rx, ry, 1)) then
    begin
        x:= x + vX * 8;
        y:= y + vY * 8;
        // TODO: Use different rating function
        valueResult:= RateShotgun(Me, vX, vY, rx, ry);

        if (valueResult = 0) and (Targ.Kind = gtHedgehog) and (Targ.Score > 0) then
            begin
            if GameFlags and gfSolidLand = 0 then
                 valueResult:= 1024 - Metric(Targ.Point.X, Targ.Point.Y, rx, ry) div 64
            else valueResult := BadTurn
            end
        else
            dec(valueResult, Level * 4000);
        exit(valueResult)
    end
until (Abs(Targ.Point.X - trunc(x)) + Abs(Targ.Point.Y - trunc(y)) < 4)
    or (x < 0)
    or (y < 0)
    or (trunc(x) > LAND_WIDTH)
    or (trunc(y) > LAND_HEIGHT);

TestMinigun:= BadTurn
end;

end.
