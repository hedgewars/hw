(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2005-2010 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uAIMisc;
interface
uses SDLh, uConsts, uFloat, uTypes;

const MAXBONUS = 1024;

type TTarget = record
               Point: TPoint;
               Score: LongInt;
               end;
     TTargets = record
                Count: Longword;
                ar: array[0..Pred(cMaxHHs)] of TTarget;
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

procedure initModule;
procedure freeModule;

procedure FillTargets;
procedure FillBonuses(isAfterAttack: boolean; filter: TGearsType = []);
procedure AwareOfExplosion(x, y, r: LongInt);
function RatePlace(Gear: PGear): LongInt;
function TestCollExcludingMe(Me: PGear; x, y, r: LongInt): boolean;
function TestColl(x, y, r: LongInt): boolean;
function RateExplosion(Me: PGear; x, y, r: LongInt): LongInt;
function RateShove(Me: PGear; x, y, r, power: LongInt): LongInt;
function RateShotgun(Me: PGear; x, y: LongInt): LongInt;
function HHGo(Gear, AltGear: PGear; var GoInfo: TGoInfo): boolean;
function AIrndSign(num: LongInt): LongInt;

var ThinkingHH: PGear;
    Targets: TTargets;

    bonuses: record
             Count: Longword;
             ar: array[0..Pred(MAXBONUS)] of TBonus;
             end;

implementation
uses uCollisions, uVariables, uUtils, uDebug;

const KillScore = 200;

var friendlyfactor: LongInt = 300;
    KnownExplosion: record
                    X, Y, Radius: LongInt
                    end = (X: 0; Y: 0; Radius: 0);

procedure FillTargets;
var i, t: Longword;
    f, e: Longword;
begin
Targets.Count:= 0;
f:= 0;
e:= 0;
for t:= 0 to Pred(TeamsCount) do
    with TeamsArray[t]^ do
        if not hasGone then
            begin
            for i:= 0 to cMaxHHIndex do
                if (Hedgehogs[i].Gear <> nil)
                and (Hedgehogs[i].Gear <> ThinkingHH) then
                    begin
                    with Targets.ar[Targets.Count], Hedgehogs[i] do
                        begin
                        Point.X:= hwRound(Gear^.X);
                        Point.Y:= hwRound(Gear^.Y);
                        if Clan <> CurrentTeam^.Clan then
                            begin
                            Score:=  Gear^.Health;
                            inc(e)
                            end else
                            begin
                            Score:= -Gear^.Health;
                            inc(f)
                            end
                        end;
                    inc(Targets.Count)
                    end;
            end;

if e > f then friendlyfactor:= 300 + (e - f) * 30
else friendlyfactor:= max(30, 300 - f * 80 div e)
end;

procedure FillBonuses(isAfterAttack: boolean; filter: TGearsType);
var Gear: PGear;
    MyClan: PClan;

    procedure AddBonus(x, y: LongInt; r: Longword; s: LongInt);
    begin
    bonuses.ar[bonuses.Count].x:= x;
    bonuses.ar[bonuses.Count].y:= y;
    bonuses.ar[bonuses.Count].Radius:= r;
    bonuses.ar[bonuses.Count].Score:= s;
    inc(bonuses.Count);
    TryDo(bonuses.Count <= MAXBONUS, 'Bonuses overflow', true)
    end;

begin
bonuses.Count:= 0;
MyClan:= ThinkingHH^.Hedgehog^.Team^.Clan;
Gear:= GearsList;
while Gear <> nil do
    begin
	if (filter = []) or (Gear^.Kind in filter) then
      case Gear^.Kind of
          gtCase: AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 33, 25);
          gtFlame: if (Gear^.State and gsttmpFlag) <> 0 then
                  AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 20, -50);
          gtMine: if (Gear^.State and gstAttacking) = 0 then
                  AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 50, -50)
              else
                  AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 100, -50); // mine is on
          gtDynamite: AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 150, -75);
          gtHedgehog: begin
                      if Gear^.Damage >= Gear^.Health then
                          AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 60, -25)
                      else
                          if isAfterAttack and (ThinkingHH^.Hedgehog <> Gear^.Hedgehog) then
                              if (MyClan = Gear^.Hedgehog^.Team^.Clan) then
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
end;

procedure AwareOfExplosion(x, y, r: LongInt);
begin
KnownExplosion.X:= x;
KnownExplosion.Y:= y;
KnownExplosion.Radius:= r
end;

function RatePlace(Gear: PGear): LongInt;
var i, r: LongInt;
    rate: LongInt;
begin
rate:= 0;
for i:= 0 to Pred(bonuses.Count) do
    with bonuses.ar[i] do
        begin
        r:= hwRound(Distance(Gear^.X - int2hwFloat(X), Gear^.Y - int2hwFloat(Y)));
        if r < Radius then
            inc(rate, Score * (Radius - r))
        end;
    RatePlace:= rate;
end;

// Wrapper to test various approaches.  If it works reasonably, will just replace.
// Right now, converting to hwFloat is a tad inefficient since the x/y were hwFloat to begin with...
function TestCollExcludingMe(Me: PGear; x, y, r: LongInt): boolean;
var MeX, MeY: LongInt;
begin
    if ((x and LAND_WIDTH_MASK) = 0) and ((y and LAND_HEIGHT_MASK) = 0) then
        begin
        MeX:= hwRound(Me^.X);
        MeY:= hwRound(Me^.Y);
        // We are still inside the hog. Skip radius test
        if ((((x-MeX)*(x-MeX)) + ((y-MeY)*(y-MeY))) < 256) and
           ((Land[y, x] and $FF00) = 0) then exit(false);
        end;
    exit(TestColl(x, y, r))
end;

function TestColl(x, y, r: LongInt): boolean;
var b: boolean;
begin
b:= (((x-r) and LAND_WIDTH_MASK) = 0)and(((y-r) and LAND_HEIGHT_MASK) = 0) and (Land[y-r, x-r] <> 0);
if b then exit(true);
b:=(((x-r) and LAND_WIDTH_MASK) = 0)and(((y+r) and LAND_HEIGHT_MASK) = 0) and (Land[y+r, x-r] <> 0);
if b then exit(true);
b:=(((x+r) and LAND_WIDTH_MASK) = 0)and(((y-r) and LAND_HEIGHT_MASK) = 0) and (Land[y-r, x+r] <> 0);
if b then exit(true);
TestColl:=(((x+r) and LAND_WIDTH_MASK) = 0)and(((y+r) and LAND_HEIGHT_MASK) = 0) and (Land[y+r, x+r] <> 0)
end;

function RateExplosion(Me: PGear; x, y, r: LongInt): LongInt;
var i, dmg, rate: LongInt;
begin
rate:= 0;
// add our virtual position
with Targets.ar[Targets.Count] do
     begin
     Point.x:= hwRound(Me^.X);
     Point.y:= hwRound(Me^.Y);
     Score:= - ThinkingHH^.Health
     end;
// rate explosion
for i:= 0 to Targets.Count do
    with Targets.ar[i] do
         begin
         dmg:= r + cHHRadius div 2 - hwRound(DistanceI(Point.x - x, Point.y - y));
         if dmg > 0 then
            begin
            dmg:= min(dmg div 2, r);
            if dmg >= abs(Score) then
               if Score > 0 then inc(rate, KillScore)
                            else dec(rate, KillScore * friendlyfactor div 100)
            else
               if Score > 0 then inc(rate, dmg)
                            else dec(rate, dmg * friendlyfactor div 100)
            end;
         end;
RateExplosion:= rate * 1024;
end;

function RateShove(Me: PGear; x, y, r, power: LongInt): LongInt;
var i, dmg, rate: LongInt;
begin
Me:= Me; // avoid compiler hint
rate:= 0;
for i:= 0 to Pred(Targets.Count) do
    with Targets.ar[i] do
         begin
         dmg:= r - hwRound(DistanceI(Point.x - x, Point.y - y));
         if dmg > 0 then
            begin
            if power >= abs(Score) then
               if Score > 0 then inc(rate, KillScore)
                            else dec(rate, KillScore * friendlyfactor div 100)
            else
               if Score > 0 then inc(rate, power)
                            else dec(rate, power * friendlyfactor div 100)
            end;
         end;
RateShove:= rate * 1024
end;

function RateShotgun(Me: PGear; x, y: LongInt): LongInt;
const
  REUSE_BONUS = 1.35;
var i, dmg, rate: LongInt;
begin
rate:= 0;
// add our virtual position
with Targets.ar[Targets.Count] do
     begin
     Point.x:= hwRound(Me^.X);
     Point.y:= hwRound(Me^.Y);
     Score:= - ThinkingHH^.Health
     end;
// rate shot
for i:= 0 to Targets.Count do
    with Targets.ar[i] do
         begin
         dmg:= min(cHHRadius + cShotgunRadius - hwRound(DistanceI(Point.x - x, Point.y - y)), 25);
         dmg := round(dmg * REUSE_BONUS);
         if dmg > 0 then
            begin
                if dmg >= abs(Score) then dmg := KillScore;
                if Score > 0 then inc(rate, dmg)
                else dec(rate, dmg * friendlyfactor div 100);
            end;
         end;
RateShotgun:= rate * 1024;
end;

function HHJump(Gear: PGear; JumpType: TJumpType; var GoInfo: TGoInfo): boolean;
var bX, bY: LongInt;
    bRes: boolean;
begin
bRes:= false;
GoInfo.Ticks:= 0;
GoInfo.FallPix:= 0;
GoInfo.JumpType:= jmpNone;
bX:= hwRound(Gear^.X);
bY:= hwRound(Gear^.Y);
case JumpType of
     jmpNone: exit(bRes);
    jmpHJump: if not TestCollisionYwithGear(Gear, -1) then
                 begin
                 Gear^.dY:= -_0_2;
                 SetLittle(Gear^.dX);
                 Gear^.State:= Gear^.State or gstMoving or gstHHJumping;
                 end else exit(bRes);
    jmpLJump: begin
              if not TestCollisionYwithGear(Gear, -1) then
                 if not TestCollisionXwithXYShift(Gear, _0, -2, hwSign(Gear^.dX)) then Gear^.Y:= Gear^.Y - int2hwFloat(2) else
                 if not TestCollisionXwithXYShift(Gear, _0, -1, hwSign(Gear^.dX)) then Gear^.Y:= Gear^.Y - _1;
              if not (TestCollisionXwithGear(Gear, hwSign(Gear^.dX))
                 or   TestCollisionYwithGear(Gear, -1)) then
                 begin
                 Gear^.dY:= -_0_15;
                 Gear^.dX:= SignAs(_0_15, Gear^.dX);
                 Gear^.State:= Gear^.State or gstMoving or gstHHJumping
                 end else exit(bRes)
              end
    end;

repeat
if not (hwRound(Gear^.Y) + cHHRadius < cWaterLine) then exit(bRes);
if (Gear^.State and gstMoving) <> 0 then
   begin
   if (GoInfo.Ticks = 350) then
      if (not (hwAbs(Gear^.dX) > cLittle)) and (Gear^.dY < -_0_02) then
         begin
         Gear^.dY:= -_0_25;
         Gear^.dX:= SignAs(_0_02, Gear^.dX)
         end;
   if TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) then SetLittle(Gear^.dX);
   Gear^.X:= Gear^.X + Gear^.dX;
   inc(GoInfo.Ticks);
   Gear^.dY:= Gear^.dY + cGravity;
   if Gear^.dY > _0_4 then exit(bRes);
   if (Gear^.dY.isNegative)and TestCollisionYwithGear(Gear, -1) then Gear^.dY:= _0;
   Gear^.Y:= Gear^.Y + Gear^.dY;
   if (not Gear^.dY.isNegative)and TestCollisionYwithGear(Gear, 1) then
      begin
      Gear^.State:= Gear^.State and not (gstMoving or gstHHJumping);
      Gear^.dY:= _0;
      case JumpType of
           jmpHJump: if bY - hwRound(Gear^.Y) > 5 then
                        begin
                        bRes:= true;
                        GoInfo.JumpType:= jmpHJump;
                        inc(GoInfo.Ticks, 300 + 300) // 300 before jump, 300 after
                        end;
           jmpLJump: if abs(bX - hwRound(Gear^.X)) > 30 then
                        begin
                        bRes:= true;
                        GoInfo.JumpType:= jmpLJump;
                        inc(GoInfo.Ticks, 300 + 300) // 300 before jump, 300 after
                        end;
           end;
      exit(bRes)
      end;
   end;
until false
end;

function HHGo(Gear, AltGear: PGear; var GoInfo: TGoInfo): boolean;
var pX, pY: LongInt;
    bRes: boolean;
begin
bRes:= false;
AltGear^:= Gear^;

GoInfo.Ticks:= 0;
GoInfo.FallPix:= 0;
GoInfo.JumpType:= jmpNone;
repeat
pX:= hwRound(Gear^.X);
pY:= hwRound(Gear^.Y);
if pY + cHHRadius >= cWaterLine then exit(false);
if (Gear^.State and gstMoving) <> 0 then
   begin
   inc(GoInfo.Ticks);
   Gear^.dY:= Gear^.dY + cGravity;
   if Gear^.dY > _0_4 then
      begin
      Goinfo.FallPix:= 0;
      HHJump(AltGear, jmpLJump, GoInfo); // try ljump instead of fall with damage
      exit(bRes)
      end;
   Gear^.Y:= Gear^.Y + Gear^.dY;
   if hwRound(Gear^.Y) > pY then inc(GoInfo.FallPix);
   if TestCollisionYwithGear(Gear, 1) then
      begin
      inc(GoInfo.Ticks, 410);
      Gear^.State:= Gear^.State and not (gstMoving or gstHHJumping);
      Gear^.dY:= _0;
      bRes:= true;
      HHJump(AltGear, jmpLJump, GoInfo); // try ljump instead of fall
      exit(bRes)
      end;
   continue
   end;
   if (Gear^.Message and gmLeft  )<>0 then Gear^.dX:= -cLittle else
   if (Gear^.Message and gmRight )<>0 then Gear^.dX:=  cLittle else exit(bRes);
   if TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) then
      begin
      if not (TestCollisionXwithXYShift(Gear, _0, -6, hwSign(Gear^.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear^.Y:= Gear^.Y - _1;
      if not (TestCollisionXwithXYShift(Gear, _0, -5, hwSign(Gear^.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear^.Y:= Gear^.Y - _1;
      if not (TestCollisionXwithXYShift(Gear, _0, -4, hwSign(Gear^.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear^.Y:= Gear^.Y - _1;
      if not (TestCollisionXwithXYShift(Gear, _0, -3, hwSign(Gear^.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear^.Y:= Gear^.Y - _1;
      if not (TestCollisionXwithXYShift(Gear, _0, -2, hwSign(Gear^.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear^.Y:= Gear^.Y - _1;
      if not (TestCollisionXwithXYShift(Gear, _0, -1, hwSign(Gear^.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear^.Y:= Gear^.Y - _1;
      end;

   if not TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) then
      begin
      Gear^.X:= Gear^.X + int2hwFloat(hwSign(Gear^.dX));
      inc(GoInfo.Ticks, cHHStepTicks)
      end;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear^.Y:= Gear^.Y + _1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear^.Y:= Gear^.Y + _1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear^.Y:= Gear^.Y + _1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear^.Y:= Gear^.Y + _1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear^.Y:= Gear^.Y + _1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear^.Y:= Gear^.Y + _1;
   if not TestCollisionYwithGear(Gear, 1) then
      begin
      Gear^.Y:= Gear^.Y - _6;
      Gear^.dY:= _0;
      Gear^.State:= Gear^.State or gstMoving
      end
   end
   end
   end
   end
   end
   end;
if (pX <> hwRound(Gear^.X)) and ((Gear^.State and gstMoving) = 0) then
   exit(true);
until (pX = hwRound(Gear^.X)) and (pY = hwRound(Gear^.Y)) and ((Gear^.State and gstMoving) = 0);
HHJump(AltGear, jmpHJump, GoInfo);
HHGo:= bRes;
end;

function AIrndSign(num: LongInt): LongInt;
begin
if random(2) = 0 then AIrndSign:=   num
                 else AIrndSign:= - num
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
