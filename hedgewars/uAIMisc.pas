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

unit uAIMisc;
interface
uses SDLh, uConsts, uFloat, uTypes;

const MAXBONUS = 1024;

      afTrackFall  = $00000001;
      afErasesLand = $00000002;
      afSetSkip    = $00000004;

      BadTurn = Low(LongInt) div 4;

type TTarget = record // starting to look more and more like a gear
    Point: TPoint;
    Score, Radius: LongInt;
    State: LongWord;
    Density: real;
    skip, matters, dead: boolean;
    Kind: TGearType;
    end;
TTargets = record
    Count: Longword;
    ar: array[0..Pred(256)] of TTarget;
    reset: boolean;
    end;
TJumpType = (jmpNone, jmpHJump, jmpLJump);
TGoInfo = record
    Ticks: Longword;
    FallPix: Longword;
    JumpType: TJumpType;
    end;
TBonus = record
    X, Y: LongInt;
    Radius: LongInt;
    Score: LongInt;
     end;

TBonuses = record
          activity: boolean;
          Count : Longword;
          ar    : array[0..Pred(MAXBONUS)] of TBonus;
       end;

Twalkbonuses =  record
        Count: Longword;
        ar: array[0..Pred(MAXBONUS div 8)] of TBonus;  // don't use too many
        end;

procedure initModule;
procedure freeModule;

procedure FillTargets;
procedure ResetTargets; inline;
procedure AddBonus(x, y: LongInt; r: Longword; s: LongInt); inline;
procedure FillBonuses(isAfterAttack: boolean);
procedure AwareOfExplosion(x, y, r: LongInt); inline;

function  RatePlace(Gear: PGear): LongInt;
function  CheckWrap(x: real): real; inline;
function  TestColl(x, y, r: LongInt): boolean; inline;
function  TestCollExcludingObjects(x, y, r: LongInt): boolean; inline;
function  TestCollExcludingMe(Me: PGear; x, y, r: LongInt): boolean; inline;

function  RateExplosion(Me: PGear; x, y, r: LongInt): LongInt; inline;
function  RateExplosion(Me: PGear; x, y, r: LongInt; Flags: LongWord): LongInt; inline;
function  RealRateExplosion(Me: PGear; x, y, r: LongInt; Flags: LongWord): LongInt;
function  RateShove(Me: PGear; x, y, r, power, kick: LongInt; gdX, gdY: real; Flags: LongWord): LongInt;
function  RateShotgun(Me: PGear; gdX, gdY: real; x, y: LongInt): LongInt;
function  RateHammer(Me: PGear): LongInt;

function  HHGo(Gear, AltGear: PGear; var GoInfo: TGoInfo): boolean;
function  AIrndSign(num: LongInt): LongInt;

var ThinkingHH: PGear;
    Targets: TTargets;

    bonuses: TBonuses;

    walkbonuses: Twalkbonuses;

const KillScore = 200;
var friendlyfactor: LongInt = 300;
var dmgMod: real = 1.0;

implementation
uses uCollisions, uVariables, uUtils, uGearsUtils;

var
    KnownExplosion: record
        X, Y, Radius: LongInt
        end = (X: 0; Y: 0; Radius: 0);

procedure ResetTargets; inline;
var i: LongWord;
begin
if Targets.reset then
    for i:= 0 to Targets.Count do
        Targets.ar[i].dead:= false;
Targets.reset:= false;
end;
procedure FillTargets;
var //i, t: Longword;
    f, e: LongInt;
    Gear: PGear;
begin
Targets.Count:= 0;
Targets.reset:= false;
f:= 0;
e:= 0;
Gear:= GearsList;
while Gear <> nil do
    begin
    if  (((Gear^.Kind = gtHedgehog) and
            (Gear <> ThinkingHH) and
            (Gear^.Health > Gear^.Damage) and
            (not Gear^.Hedgehog^.Team^.hasgone)) or
        ((Gear^.Kind = gtExplosives) and
            (Gear^.Health > Gear^.Damage)) or
        ((Gear^.Kind = gtMine) and
            (Gear^.Health = 0) and
             (Gear^.Damage < 35))
             )  and
        (Targets.Count < 256) then
        begin
        with Targets.ar[Targets.Count] do
            begin
            skip:= false;
            dead:= false;
            Kind:= Gear^.Kind;
            Radius:= Gear^.Radius;
            Density:= hwFloat2Float(Gear^.Density)/3;
            State:= Gear^.State;
            matters:= (Gear^.AIHints and aihDoesntMatter) = 0;

            Point.X:= hwRound(Gear^.X);
            Point.Y:= hwRound(Gear^.Y);
            if (Gear^.Kind = gtHedgehog) then
                begin
                if (Gear^.Hedgehog^.Team^.Clan = CurrentTeam^.Clan) then
                    begin
                    Score:= Gear^.Damage - Gear^.Health;
                    inc(f)
                    end
                else
                    begin
                    Score:= Gear^.Health - Gear^.Damage;
                    inc(e)
                    end;
                end
            else if Gear^.Kind = gtExplosives then
                Score:= Gear^.Health - Gear^.Damage
            else if Gear^.Kind = gtMine then
                Score:= max(0,35-Gear^.Damage);
            end;
        inc(Targets.Count)
        end;
    Gear:= Gear^.NextGear
    end;

if e > f then friendlyfactor:= 300 + (e - f) * 30
else friendlyfactor:= max(30, 300 - f * 80 div max(1,e))
end;

procedure AddBonus(x, y: LongInt; r: Longword; s: LongInt); inline;
begin
if(bonuses.Count < MAXBONUS) then
    begin
    bonuses.ar[bonuses.Count].x:= x;
    bonuses.ar[bonuses.Count].y:= y;
    bonuses.ar[bonuses.Count].Radius:= r;
    bonuses.ar[bonuses.Count].Score:= s;
    inc(bonuses.Count);
    end;
end;

procedure AddWalkBonus(x, y: LongInt; r: Longword; s: LongInt); inline;
begin
if(walkbonuses.Count < MAXBONUS div 8) then
    begin
    walkbonuses.ar[walkbonuses.Count].x:= x;
    walkbonuses.ar[walkbonuses.Count].y:= y;
    walkbonuses.ar[walkbonuses.Count].Radius:= r;
    walkbonuses.ar[walkbonuses.Count].Score:= s;
    inc(walkbonuses.Count);
    end;
end;

procedure FillBonuses(isAfterAttack: boolean);
var Gear: PGear;
    MyClan: PClan;
    i: Longint;
begin
bonuses.Count:= 0;
bonuses.activity:= false;
MyClan:= ThinkingHH^.Hedgehog^.Team^.Clan;
Gear:= GearsList;
while Gear <> nil do
    begin
        case Gear^.Kind of
            gtGrenade
            , gtClusterBomb
            , gtGasBomb
            , gtShell
            , gtAirAttack
            , gtMortar
            , gtWatermelon
            , gtDrill
            , gtAirBomb
            , gtCluster
            , gtMelonPiece
            , gtMolotov: bonuses.activity:= true;
            gtCase:
                AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y) + 3, 37, 25);
            gtFlame:
                if (Gear^.State and gsttmpFlag) <> 0 then
                    AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 20, -50);
// avoid mines unless they are very likely to be duds, or are duds. also avoid if they are about to blow
            gtMine: begin
                if (Gear^.State and gstMoving) <> 0 then bonuses.activity:= true;

                if ((Gear^.State and gstAttacking) = 0) and (((cMineDudPercent < 90) and (Gear^.Health <> 0))
                or (isAfterAttack and (Gear^.Health = 0) and (Gear^.Damage > 30))) then
                    AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 50, -50)
                else if (Gear^.State and gstAttacking) <> 0 then
                    AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 100, -50); // mine is on
                end;

            gtExplosives:
                begin
                //if (Gear^.State and gstMoving) <> 0 then bonuses.activity:= true;

                if isAfterAttack then
                    AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 75, -60 + Gear^.Health);
                end;

            gtSMine: begin
                if (Gear^.State and (gstMoving or gstAttacking)) <> 0 then bonuses.activity:= true;

                AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 50, -30);
                end;

            gtDynamite:
                begin
                bonuses.activity:= true;
                AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 150, -75);
                end;

            gtHedgehog:
                begin
                if (ThinkingHH <> Gear)
                    and (((Gear^.State and (gstMoving or gstDrowning or gstHHDeath)) <> 0)
                        or (Gear^.Health = 0)
                        or (Gear^.Damage >= Gear^.Health))
                    then begin
                    bonuses.activity:= true;
                    end;

                if Gear^.Damage >= Gear^.Health then
                    AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 60, -25)
                else
                    if isAfterAttack
                      and (ThinkingHH^.Hedgehog <> Gear^.Hedgehog)
                      and ((hwAbs(Gear^.dX) + hwAbs(Gear^.dY)) < _0_1) then
                        if (ClansCount > 2) or (MyClan = Gear^.Hedgehog^.Team^.Clan) then
                            AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 150, -3) // hedgehog-friend
                        else
                            AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 100, 3)
                end;
            end;
    Gear:= Gear^.NextGear
    end;

if isAfterAttack and (KnownExplosion.Radius > 0) then
    with KnownExplosion do
        AddBonus(X, Y, Radius + 10, -Radius);
if isAfterAttack then
    begin
    for i:= 0 to Pred(walkbonuses.Count) do
        with walkbonuses.ar[i] do
            AddBonus(X, Y, Radius, Score);
    walkbonuses.Count:= 0
    end;
end;

procedure AwareOfExplosion(x, y, r: LongInt); inline;
begin
    KnownExplosion.X:= x;
    KnownExplosion.Y:= y;
    KnownExplosion.Radius:= r
end;

function RatePlace(Gear: PGear): LongInt;
var i, r: LongInt;
    rate: LongInt;
    gX, gY: real;
begin
gX:= hwFloat2Float(Gear^.X);
gY:= hwFloat2Float(Gear^.Y);
rate:= 0;
for i:= 0 to Pred(bonuses.Count) do
    with bonuses.ar[i] do
        begin
        r:= Radius;
        if abs(gX-X)+abs(gY-Y) < Radius then
            r:= trunc(sqrt(sqr(gX - X)+sqr(gY - Y)));
        if r < 20 then
                inc(rate, Score * Radius)
        else if r < Radius then
                inc(rate, Score * (Radius - r))
        end;
    RatePlace:= rate;
end;

function CheckWrap(x: real): real; inline;
begin
    if WorldEdge = weWrap then
        if (x < leftX) then
             x:= x + (rightX - leftX)
        else if x > rightX then    
             x:= x - (rightX - leftX);
    CheckWrap:= x;
end;

function CheckBounds(x, y, r: Longint): boolean; inline;
begin
    CheckBounds := (((x-r) and LAND_WIDTH_MASK) = 0) and
        (((x+r) and LAND_WIDTH_MASK) = 0) and
        (((y-r) and LAND_HEIGHT_MASK) = 0) and
        (((y+r) and LAND_HEIGHT_MASK) = 0);
end;


function TestCollWithEverything(x, y, r: LongInt): boolean; inline;
begin
    if not CheckBounds(x, y, r) then
        exit(false);

    if (Land[y-r, x-r] <> 0) or
       (Land[y+r, x-r] <> 0) or
       (Land[y-r, x+r] <> 0) or
       (Land[y+r, x+r] <> 0) then
       exit(true);

    TestCollWithEverything := false;
end;

function TestCollExcludingObjects(x, y, r: LongInt): boolean; inline;
begin
    if not CheckBounds(x, y, r) then
        exit(false);

    if (Land[y-r, x-r] > lfAllObjMask) or
       (Land[y+r, x-r] > lfAllObjMask) or
       (Land[y-r, x-r] > lfAllObjMask) or
       (Land[y+r, x+r] > lfAllObjMask) then
       exit(true);

    TestCollExcludingObjects:= false;
end;

function TestColl(x, y, r: LongInt): boolean; inline;
begin
    if not CheckBounds(x, y, r) then
        exit(false);

    if (Land[y-r, x-r] and lfNotCurHogCrate <> 0) or
       (Land[y+r, x-r] and lfNotCurHogCrate <> 0) or
       (Land[y+r, x-r] and lfNotCurHogCrate <> 0) or
       (Land[y+r, x+r] and lfNotCurHogCrate <> 0) then
       exit(true);

    TestColl:= false;
end;


// Wrapper to test various approaches.  If it works reasonably, will just replace.
// Right now, converting to hwFloat is a tad inefficient since the x/y were hwFloat to begin with...
function TestCollExcludingMe(Me: PGear; x, y, r: LongInt): boolean; inline;
var MeX, MeY: LongInt;
begin
    if ((x and LAND_WIDTH_MASK) = 0) and ((y and LAND_HEIGHT_MASK) = 0) then
    begin
        MeX:= hwRound(Me^.X);
        MeY:= hwRound(Me^.Y);
        // We are still inside the hog. Skip radius test
        if ((sqr(x-MeX) + sqr(y-MeY)) < 256) and (Land[y, x] and lfObjMask = 0) then
            exit(false);
    end;
    TestCollExcludingMe:= TestCollWithEverything(x, y, r)
end;



function TraceFall(eX, eY: LongInt; var x, y: Real; dX, dY: Real; r: LongWord; Target: TTarget): LongInt;
var skipLandCheck: boolean;
    rCorner, dxdy, odX, odY: real;
    dmg: LongInt;
begin
    odX:= dX;
    odY:= dY;
    skipLandCheck:= true;
    // ok. attempt approximate search for an unbroken trajectory into water.  if it continues far enough, assume out of map
    rCorner:= r * 0.75;
    while true do
        begin
        x:= CheckWrap(x);
        x:= x + dX;
        y:= y + dY;
        dY:= dY + cGravityf;
        skipLandCheck:= skipLandCheck and (r <> 0) and (abs(eX-x) + abs(eY-y) < r) and ((abs(eX-x) < rCorner) or (abs(eY-y) < rCorner));
        if not skipLandCheck and TestCollExcludingObjects(trunc(x), trunc(y), Target.Radius) then
            with Target do
                begin
                if (Kind = gtHedgehog) and (0.4 < dY) then
                    begin
                    dmg := 1 + trunc((dY - 0.4) * 70);
                    exit(dmg)
                    end
                else
                    begin
                    dxdy:= abs(dX)+abs(dY);
                    if ((Kind = gtMine) and (dxdy > 0.35)) or
                       ((Kind = gtExplosives) and
                            (((State and gstTmpFlag <> 0) and (dxdy > 0.35)) or
                             ((State and gstTmpFlag = 0) and
                                ((abs(odX) > 0.15) or ((abs(odY) > 0.15) and
                                (abs(odX) > 0.02))) and (dxdy > 0.35)))) then
                        begin
                        dmg := trunc(dxdy * 25);
                        exit(dmg)
                        end
                    else if (Kind = gtExplosives) and (not(abs(odX) > 0.15) or ((abs(odY) > 0.15) and (abs(odX) > 0.02))) and (dY > 0.2) then
                        begin
                        dmg := trunc(dy * 70);
                        exit(dmg)
                        end
                    end;
            exit(0)
            end;
        if CheckCoordInWater(round(x), round(y)) then exit(-1)
        end
end;

function TraceShoveFall(var x, y: Real; dX, dY: Real; Target: TTarget): LongInt;
var dmg: LongInt;
    dxdy, odX, odY: real;
begin
    odX:= dX;
    odY:= dY;
//v:= random($FFFFFFFF);
    while true do
        begin
        x:= CheckWrap(x);
        x:= x + dX;
        y:= y + dY;
        dY:= dY + cGravityf;

{        if ((trunc(y) and LAND_HEIGHT_MASK) = 0) and ((trunc(x) and LAND_WIDTH_MASK) = 0) then
            begin
            LandPixels[trunc(y), trunc(x)]:= v;
            UpdateLandTexture(trunc(X), 1, trunc(Y), 1, true);
            end;}

        if TestCollExcludingObjects(trunc(x), trunc(y), Target.Radius) then
            with Target do
                begin
                if (Kind = gtHedgehog) and (0.4 < dY) then
                    begin
                    dmg := trunc((dY - 0.4) * 70);
                    exit(dmg);
                    end
                else
                    begin
                    dxdy:= abs(dX)+abs(dY);
                    if ((Kind = gtMine) and (dxdy > 0.4)) or
                       ((Kind = gtExplosives) and
                            (((State and gstTmpFlag <> 0) and (dxdy > 0.4)) or
                             ((State and gstTmpFlag = 0) and
                                ((abs(odX) > 0.15) or ((abs(odY) > 0.15) and
                                (abs(odX) > 0.02))) and (dxdy > 0.35)))) then
                        begin
                        dmg := trunc(dxdy * 50);
                        exit(dmg)
                        end
                    else if (Kind = gtExplosives) and (not(abs(odX) > 0.15) or ((abs(odY) > 0.15) and (abs(odX) > 0.02))) and (dY > 0.2) then
                        begin
                        dmg := trunc(dy * 70);
                        exit(dmg)
                        end
                    end;
            exit(0)
        end;
        if CheckCoordInWater(round(x), round(y)) then
            // returning -1 for drowning so it can be considered in the Rate routine
            exit(-1)
    end;
end;

function RateExplosion(Me: PGear; x, y, r: LongInt): LongInt; inline;
begin
    RateExplosion:= RealRateExplosion(Me, x, y, r, 0);
    ResetTargets;
end;
function RateExplosion(Me: PGear; x, y, r: LongInt; Flags: LongWord): LongInt; inline;
begin
    RateExplosion:= RealRateExplosion(Me, x, y, r, Flags);
    ResetTargets;
end;

function RealRateExplosion(Me: PGear; x, y, r: LongInt; Flags: LongWord): LongInt;
var i, fallDmg, dmg, dmgBase, rate, subrate, erasure: LongInt;
    pX, pY, dX, dY: real;
    hadSkips: boolean;
begin
x:= round(CheckWrap(real(x)));
fallDmg:= 0;
rate:= 0;
// add our virtual position
with Targets.ar[Targets.Count] do
    begin
    Point.x:= hwRound(Me^.X);
    Point.y:= hwRound(Me^.Y);
    skip:= false;
    matters:= true;
    Kind:= gtHedgehog;
    Density:= 1;
    Radius:= cHHRadius;
    Score:= - ThinkingHH^.Health
    end;
// rate explosion

if (Flags and afErasesLand <> 0) and (GameFlags and gfSolidLand = 0) then erasure:= r
else erasure:= 0;

hadSkips:= false;

for i:= 0 to Targets.Count do
    if not Targets.ar[i].dead then
        with Targets.ar[i] do
          if not matters then hadSkips:= true
            else
            begin
            dmg:= 0;
            dmgBase:= r + Radius div 2;
            if abs(Point.x - x) + abs(Point.y - y) < dmgBase then
                dmg:= trunc(dmgMod * min((dmgBase - trunc(sqrt(sqr(Point.x - x)+sqr(Point.y - y)))) div 2, r));

            if dmg > 0 then
                begin
                pX:= Point.x;
                pY:= Point.y;
                fallDmg:= 0;
                dX:= 0;
                if (Flags and afTrackFall <> 0) and (Score > 0) and (dmg < Score) then
                    begin
                    dX:= (0.005 * dmg + 0.01) / Density;
                    dY:= dX;
                    if (Kind = gtExplosives) and (State and gstTmpFlag = 0) and
                       (((abs(dY) >= 0.15) and (abs(dX) < 0.02)) or
                        ((abs(dY) < 0.15) and (abs(dX) < 0.15))) then
                        dX:= 0;

                    if pX - x < 0 then dX:= -dX;
                    if pY - y < 0 then dY:= -dY;

                    if (x and LAND_WIDTH_MASK = 0) and ((y+cHHRadius+2) and LAND_HEIGHT_MASK = 0) and
                       (Land[y+cHHRadius+2, x] and lfIndestructible <> 0) then
                         fallDmg:= trunc(TraceFall(x, y, pX, pY, dX, dY, 0, Targets.ar[i]) * dmgMod)
                    else fallDmg:= trunc(TraceFall(x, y, pX, pY, dX, dY, erasure, Targets.ar[i]) * dmgMod)
                    end;
                if Kind = gtHedgehog then
                    begin
                    if fallDmg < 0 then // drowning. score healthier hogs higher, since their death is more likely to benefit the AI
                        begin
                        if Score > 0 then
                            inc(rate, (KillScore + Score div 10) * 1024)   // Add a bit of a bonus for bigger hog drownings
                        else
                            dec(rate, (KillScore * friendlyfactor div 100 - Score div 10) * 1024) // and more of a punishment for drowning bigger friendly hogs
                        end
                    else if (dmg+fallDmg) >= abs(Score) then
                        begin
                        dead:= true;
                        Targets.reset:= true;
                        if dX < 0.035 then
                            begin
                            subrate:= RealRateExplosion(Me, round(pX), round(pY), 61, afErasesLand or (Flags and afTrackFall));
                            if abs(subrate) > 2000 then inc(Rate,subrate)
                            end;
                        if Score > 0 then
                             inc(rate, KillScore * 1024 + (dmg + fallDmg)) // tiny bonus for dealing more damage than needed to kill
                        else dec(rate, KillScore * friendlyfactor div 100 * 1024)
                        end
                    else
                        begin
                        if Score > 0 then
                             inc(rate, (dmg + fallDmg) * 1024)
                        else dec(rate, (dmg + fallDmg) * friendlyfactor div 100 * 1024)
                        end
                    end
                else if (fallDmg >= 0) and ((dmg+fallDmg) >= Score) then
                    begin
                    dead:= true;
                    Targets.reset:= true;
                    if Kind = gtExplosives then
                         subrate:= RealRateExplosion(Me, round(pX), round(pY), 151, afErasesLand or (Flags and afTrackFall))
                    else subrate:= RealRateExplosion(Me, round(pX), round(pY), 101, afErasesLand or (Flags and afTrackFall));
                    if abs(subrate) > 2000 then inc(Rate,subrate);
                    end
                end
            end;

if hadSkips and (rate <= 0) then
    RealRateExplosion:= BadTurn
else
    RealRateExplosion:= rate;
end;

function RateShove(Me: PGear; x, y, r, power, kick: LongInt; gdX, gdY: real; Flags: LongWord): LongInt;
var i, fallDmg, dmg, rate, subrate: LongInt;
    dX, dY, pX, pY: real;
    hadSkips: boolean;
begin
fallDmg:= 0;
dX:= gdX * 0.01 * kick;
dY:= gdY * 0.01 * kick;
rate:= 0;
hadSkips:= false;
for i:= 0 to Pred(Targets.Count) do
    with Targets.ar[i] do
        if skip then
            begin
            if Flags and afSetSkip = 0 then skip:= false
            end
        else if matters then
            begin
            dmg:= 0;
            if abs(Point.x - x) + abs(Point.y - y) < r then
                dmg:= r - trunc(sqrt(sqr(Point.x - x)+sqr(Point.y - y)));

            if dmg > 0 then
                begin
                pX:= Point.x;
                pY:= Point.y-2;
                fallDmg:= 0;
                if (Flags and afSetSkip <> 0) then skip:= true;
                if (not dead) and (Flags and afTrackFall <> 0) and (Score > 0) and (power < Score) then
                    if (Kind = gtExplosives) and (State and gstTmpFlag = 0) and
                       (((abs(dY) > 0.15) and (abs(dX) < 0.02)) or
                        ((abs(dY) < 0.15) and (abs(dX) < 0.15))) then
                        fallDmg:= trunc(TraceShoveFall(pX, pY, 0, dY, Targets.ar[i]) * dmgMod)
                    else
                        fallDmg:= trunc(TraceShoveFall(pX, pY, dX, dY, Targets.ar[i]) * dmgMod);
                if Kind = gtHedgehog then
                    begin
                    if fallDmg < 0 then // drowning. score healthier hogs higher, since their death is more likely to benefit the AI
                        begin
                        if Score > 0 then
                            inc(rate, KillScore + Score div 10)   // Add a bit of a bonus for bigger hog drownings
                        else
                            dec(rate, KillScore * friendlyfactor div 100 - Score div 10) // and more of a punishment for drowning bigger friendly hogs
                        end
                    else if power+fallDmg >= abs(Score) then
                        begin
                        dead:= true;
                        Targets.reset:= true;
                        if dX < 0.035 then
                            begin
                            subrate:= RealRateExplosion(Me, round(pX), round(pY), 61, afErasesLand or afTrackFall);
                            if abs(subrate) > 2000 then inc(Rate,subrate div 1024)
                            end;
                        if Score > 0 then
                            inc(rate, KillScore)
                        else
                            dec(rate, KillScore * friendlyfactor div 100)
                        end
                    else
                        begin
                        if Score > 0 then
                            inc(rate, power+fallDmg)
                        else
                            dec(rate, (power+fallDmg) * friendlyfactor div 100)
                        end
                    end
                else if (fallDmg >= 0) and ((dmg+fallDmg) >= Score) then
                    begin
                    dead:= true;
                    Targets.reset:= true;
                    if Kind = gtExplosives then
                         subrate:= RealRateExplosion(Me, round(pX), round(pY), 151, afErasesLand or (Flags and afTrackFall))
                    else subrate:= RealRateExplosion(Me, round(pX), round(pY), 101, afErasesLand or (Flags and afTrackFall));
                    if abs(subrate) > 2000 then inc(Rate,subrate div 1024);
                    end
                end
            end
        else
            hadSkips:= true;

if hadSkips and (rate <= 0) then
    RateShove:= BadTurn
else
    RateShove:= rate * 1024;
ResetTargets
end;

function RateShotgun(Me: PGear; gdX, gdY: real; x, y: LongInt): LongInt;
var i, dmg, fallDmg, baseDmg, rate, subrate, erasure: LongInt;
    pX, pY, dX, dY: real;
    hadSkips: boolean;
begin
rate:= 0;
gdX:= gdX * 0.01;
gdY:= gdX * 0.01;
// add our virtual position
with Targets.ar[Targets.Count] do
    begin
    Point.x:= hwRound(Me^.X);
    Point.y:= hwRound(Me^.Y);
    skip:= false;
    matters:= true;
    Kind:= gtHedgehog;
    Density:= 1;
    Radius:= cHHRadius;
    Score:= - ThinkingHH^.Health
    end;
// rate shot
baseDmg:= cHHRadius + cShotgunRadius + 4;

if GameFlags and gfSolidLand = 0 then erasure:= cShotgunRadius
else erasure:= 0;

hadSkips:= false;

for i:= 0 to Targets.Count do
    if not Targets.ar[i].dead then
        with Targets.ar[i] do
          if not matters then hadSkips:= true
            else
            begin
            dmg:= 0;
            if abs(Point.x - x) + abs(Point.y - y) < baseDmg then
                begin
                dmg:= min(baseDmg - trunc(sqrt(sqr(Point.x - x)+sqr(Point.y - y))), 25);
                dmg:= trunc(dmg * dmgMod);
                end;
            if dmg > 0 then
                begin
                fallDmg:= 0;
                pX:= Point.x;
                pY:= Point.y;
                if (not dead) and (Score > 0) and (dmg < Score) then
                    begin
                    dX:= gdX * dmg / Density;
                    dY:= gdY * dmg / Density;
                    if dX < 0 then dX:= dX - 0.01
                    else dX:= dX + 0.01;
                    if (Kind = gtExplosives) and (State and gstTmpFlag = 0) and
                       (((abs(dY) > 0.15) and (abs(dX) < 0.02)) or
                        ((abs(dY) < 0.15) and (abs(dX) < 0.15))) then
                       dX:= 0;
                    if (x and LAND_WIDTH_MASK = 0) and ((y+cHHRadius+2) and LAND_HEIGHT_MASK = 0) and
                       (Land[y+cHHRadius+2, x] and lfIndestructible <> 0) then
                         fallDmg:= trunc(TraceFall(x, y, pX, pY, dX, dY, 0, Targets.ar[i]) * dmgMod)
                    else fallDmg:= trunc(TraceFall(x, y, pX, pY, dX, dY, erasure, Targets.ar[i]) * dmgMod)
                    end;
                if Kind = gtHedgehog then
                    begin
                    if fallDmg < 0 then // drowning. score healthier hogs higher, since their death is more likely to benefit the AI
                        begin
                        if Score > 0 then
                            inc(rate, KillScore + Score div 10)   // Add a bit of a bonus for bigger hog drownings
                        else
                            dec(rate, KillScore * friendlyfactor div 100 - Score div 10) // and more of a punishment for drowning bigger friendly hogs
                        end
                    else if (dmg+fallDmg) >= abs(Score) then
                        begin
                        dead:= true;
                        Targets.reset:= true;
                        if dX < 0.035 then
                            begin
                            subrate:= RealRateExplosion(Me, round(pX), round(pY), 61, afErasesLand or afTrackFall);
                            if abs(subrate) > 2000 then inc(Rate,subrate div 1024)
                            end;
                        if Score > 0 then
                            inc(rate, KillScore)
                        else
                            dec(rate, KillScore * friendlyfactor div 100)
                        end
                    else if Score > 0 then
                         inc(rate, dmg+fallDmg)
                    else dec(rate, (dmg+fallDmg) * friendlyfactor div 100)
                    end
                else if (fallDmg >= 0) and ((dmg+fallDmg) >= Score) then
                    begin
                    dead:= true;
                    Targets.reset:= true;
                    if Kind = gtExplosives then
                         subrate:= RealRateExplosion(Me, round(pX), round(pY), 151, afErasesLand or afTrackFall)
                    else subrate:= RealRateExplosion(Me, round(pX), round(pY), 101, afErasesLand or afTrackFall);
                    if abs(subrate) > 2000 then inc(Rate,subrate div 1024);
                    end
                end
            end;

if hadSkips and (rate <= 0) then
    RateShotgun:= BadTurn
else
    RateShotgun:= rate * 1024;
ResetTargets;
end;

function RateHammer(Me: PGear): LongInt;
var x, y, i, r, rate: LongInt;
    hadSkips: boolean;
begin
// hammer hit shift against attecker hog is 10
x:= hwRound(Me^.X) + hwSign(Me^.dX) * 10;
y:= hwRound(Me^.Y);
rate:= 0;
hadSkips:= false;
for i:= 0 to Pred(Targets.Count) do
    with Targets.ar[i] do
         // hammer hit radius is 8, shift is 10
      if (not matters) then
          hadSkips:= true
      else if matters and (Kind = gtHedgehog) and (abs(Point.x - x) + abs(Point.y - y) < 18) then
            begin
            r:= trunc(sqrt(sqr(Point.x - x)+sqr(Point.y - y)));

            if r <= 18 then
                if Score > 0 then
                    inc(rate, Score div 3)
                else
                    inc(rate, Score div 3 * friendlyfactor div 100)
            end;

if hadSkips and (rate <= 0) then
    RateHammer:= BadTurn
else
    RateHammer:= rate * 1024;
end;

function HHJump(Gear: PGear; JumpType: TJumpType; var GoInfo: TGoInfo): boolean;
var bX, bY: LongInt;
begin
HHJump:= false;
GoInfo.Ticks:= 0;
GoInfo.JumpType:= jmpNone;
bX:= hwRound(Gear^.X);
bY:= hwRound(Gear^.Y);
case JumpType of
    jmpNone: exit(false);

    jmpHJump:
        if TestCollisionYwithGear(Gear, -1) = 0 then
        begin
            Gear^.dY:= -_0_2;
            SetLittle(Gear^.dX);
            Gear^.State:= Gear^.State or gstMoving or gstHHJumping;
        end
    else
        exit(false);

    jmpLJump:
        begin
            if TestCollisionYwithGear(Gear, -1) <> 0 then
                if TestCollisionXwithXYShift(Gear, _0, -2, hwSign(Gear^.dX)) = 0 then
                    Gear^.Y:= Gear^.Y - int2hwFloat(2)
                else
                    if TestCollisionXwithXYShift(Gear, _0, -1, hwSign(Gear^.dX)) = 0 then
                        Gear^.Y:= Gear^.Y - _1;
            if (TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) = 0) and
               (TestCollisionYwithGear(Gear, -1) = 0) then
            begin
                Gear^.dY:= -_0_15;
                Gear^.dX:= SignAs(_0_15, Gear^.dX);
                Gear^.State:= Gear^.State or gstMoving or gstHHJumping
            end
        else
            exit(false)
        end
end;

repeat
        {if ((hwRound(Gear^.Y) and LAND_HEIGHT_MASK) = 0) and ((hwRound(Gear^.X) and LAND_WIDTH_MASK) = 0) then
            begin
            LandPixels[hwRound(Gear^.Y), hwRound(Gear^.X)]:= Gear^.Hedgehog^.Team^.Clan^.Color;
            UpdateLandTexture(hwRound(Gear^.X), 1, hwRound(Gear^.Y), 1, true);
            end;}

    if CheckCoordInWater(hwRound(Gear^.X), hwRound(Gear^.Y) + cHHRadius) then
        exit(false);
    if (Gear^.State and gstMoving) <> 0 then
    begin
        if (GoInfo.Ticks = 350) then
            if (not (hwAbs(Gear^.dX) > cLittle)) and (Gear^.dY < -_0_02) then
            begin
                Gear^.dY:= -_0_25;
                Gear^.dX:= SignAs(_0_02, Gear^.dX)
            end;
        if TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) <> 0 then SetLittle(Gear^.dX);
            Gear^.X:= Gear^.X + Gear^.dX;
        inc(GoInfo.Ticks);
        Gear^.dY:= Gear^.dY + cGravity;
        if Gear^.dY > _0_4 then
            exit(false);
        if (Gear^.dY.isNegative) and (TestCollisionYwithGear(Gear, -1) <> 0) then
            Gear^.dY:= _0;
        Gear^.Y:= Gear^.Y + Gear^.dY;
        if (not Gear^.dY.isNegative) and (TestCollisionYwithGear(Gear, 1) <> 0) then
            begin
            Gear^.State:= Gear^.State and (not (gstMoving or gstHHJumping));
            Gear^.dY:= _0;
            case JumpType of
                jmpHJump:
                    if bY - hwRound(Gear^.Y) > 5 then
                        begin
                        GoInfo.JumpType:= jmpHJump;
                        inc(GoInfo.Ticks, 300 + 300); // 300 before jump, 300 after
                        exit(true)
                        end;
                jmpLJump:
                    if abs(bX - hwRound(Gear^.X)) > 30 then
                        begin
                        GoInfo.JumpType:= jmpLJump;
                        inc(GoInfo.Ticks, 300 + 300); // 300 before jump, 300 after
                        exit(true)
                        end
                end;
            exit(false)
            end;
    end;
until false
end;

function HHGo(Gear, AltGear: PGear; var GoInfo: TGoInfo): boolean;
var pX, pY, tY: LongInt;
begin
HHGo:= false;
Gear^.CollisionMask:= lfNotCurHogCrate;
AltGear^:= Gear^;

GoInfo.Ticks:= 0;
GoInfo.FallPix:= 0;
GoInfo.JumpType:= jmpNone;
tY:= hwRound(Gear^.Y);
repeat
        {if ((hwRound(Gear^.Y) and LAND_HEIGHT_MASK) = 0) and ((hwRound(Gear^.X) and LAND_WIDTH_MASK) = 0) then
            begin
            LandPixels[hwRound(Gear^.Y), hwRound(Gear^.X)]:= random($FFFFFFFF);//Gear^.Hedgehog^.Team^.Clan^.Color;
            UpdateLandTexture(hwRound(Gear^.X), 1, hwRound(Gear^.Y), 1, true);
            end;}

    pX:= hwRound(Gear^.X);
    pY:= hwRound(Gear^.Y);
    if CheckCoordInWater(pX, pY + cHHRadius) then
        begin
        if AltGear^.Hedgehog^.BotLevel < 4 then
            AddWalkBonus(pX, tY, 250, -40);
        exit(false)
        end;

    // hog is falling
    if (Gear^.State and gstMoving) <> 0 then
        begin
        inc(GoInfo.Ticks);
        Gear^.dY:= Gear^.dY + cGravity;
        if Gear^.dY > _0_4 then
            begin
            GoInfo.FallPix:= 0;
            // try ljump instead of fall with damage
            HHJump(AltGear, jmpLJump, GoInfo);
            if AltGear^.Hedgehog^.BotLevel < 4 then
                AddWalkBonus(pX, tY, 175, -20);
            exit(false)
            end;
        Gear^.Y:= Gear^.Y + Gear^.dY;
        if hwRound(Gear^.Y) > pY then
            inc(GoInfo.FallPix);
        if TestCollisionYwithGear(Gear, 1) <> 0 then
            begin
            inc(GoInfo.Ticks, 410);
            Gear^.State:= Gear^.State and (not (gstMoving or gstHHJumping));
            Gear^.dY:= _0;
            // try ljump instead of fall
            HHJump(AltGear, jmpLJump, GoInfo);
            exit(true)
            end;
        continue
        end;

        // usual walk
        if (Gear^.Message and gmLeft) <> 0 then
            Gear^.dX:= -cLittle
        else
            if (Gear^.Message and gmRight) <> 0 then
                Gear^.dX:=  cLittle
            else
                exit(false);

        if MakeHedgehogsStep(Gear) then
            inc(GoInfo.Ticks, cHHStepTicks);

        // we have moved for 1 px
        if (pX <> hwRound(Gear^.X)) and ((Gear^.State and gstMoving) = 0) then
            exit(true)
until (pX = hwRound(Gear^.X)) and (pY = hwRound(Gear^.Y)) and ((Gear^.State and gstMoving) = 0);

HHJump(AltGear, jmpHJump, GoInfo);
end;

function AIrndSign(num: LongInt): LongInt;
begin
if random(2) = 0 then
    AIrndSign:=   num
else
    AIrndSign:= - num
end;

procedure initModule;
begin
    friendlyfactor:= 300;
    KnownExplosion.X:= 0;
    KnownExplosion.Y:= 0;
    KnownExplosion.Radius:= 0;
end;

procedure freeModule;
begin
end;

end.
