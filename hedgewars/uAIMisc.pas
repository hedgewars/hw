(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uAIMisc;
interface
uses SDLh, uConsts, uGears, uFloat;
{$INCLUDE options.inc}

type TTarget = record
               Point: TPoint;
               Score: integer;
               end;
     TTargets = record
                Count: Longword;
                ar: array[0..cMaxHHIndex*5] of TTarget;
                end;
     TJumpType = (jmpNone, jmpHJump, jmpLJump);
     TGoInfo = record
               Ticks: Longword;
               FallPix: Longword;
               JumpType: TJumpType;
               end;

procedure FillTargets;
procedure FillBonuses(isAfterAttack: boolean);
procedure AwareOfExplosion(x, y, r: integer);
function RatePlace(Gear: PGear): integer;
function TestColl(x, y, r: integer): boolean;
function RateExplosion(Me: PGear; x, y, r: integer): integer;
function RateShove(Me: PGear; x, y, r, power: integer): integer;
function HHGo(Gear, AltGear: PGear; var GoInfo: TGoInfo): boolean;
//function rndSign(num: integer): integer;

var ThinkingHH: PGear;
    Targets: TTargets;
                       
implementation
uses uTeams, uMisc, uLand, uCollisions;
const KillScore = 200;
      MAXBONUS = 1024;

type TBonus = record
              X, Y: integer;
              Radius: integer;
              Score: integer;
              end;
var bonuses: record
             Count: Longword;
             ar: array[0..Pred(MAXBONUS)] of TBonus;
             end;
    KnownExplosion: record
                    X, Y, Radius: integer
                    end = (X: 0; Y: 0; Radius: 0);

procedure FillTargets;
var t: PTeam;
    i: Longword;
begin
Targets.Count:= 0;
t:= TeamsList;
while t <> nil do
      begin
      for i:= 0 to cMaxHHIndex do
          if (t^.Hedgehogs[i].Gear <> nil)
             and (t^.Hedgehogs[i].Gear <> ThinkingHH) then
             begin
             with Targets.ar[Targets.Count], t^.Hedgehogs[i] do
                  begin
                  Point.X:= hwRound(Gear^.X);
                  Point.Y:= hwRound(Gear^.Y);
                  if t^.Color <> CurrentTeam^.Color then Score:=  Gear^.Health
                                                    else Score:= -Gear^.Health
                  end;
             inc(Targets.Count)
             end;
      t:= t^.Next
      end
end;

procedure FillBonuses(isAfterAttack: boolean);
var Gear: PGear;
    MyColor: Longword;

    procedure AddBonus(x, y: integer; r: Longword; s: integer);
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
MyColor:= PHedgehog(ThinkingHH^.Hedgehog)^.Team^.Color;
Gear:= GearsList;
while Gear <> nil do
      begin
      case Gear^.Kind of
           gtCase: AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 33, 25);
           gtMine: if (Gear^.State and gstAttacking) = 0 then AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 50, -50)
                                                        else AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 100, -50); // mine is on
           gtDynamite: AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 150, -75);
           gtHedgehog: begin
                       if Gear^.Damage >= Gear^.Health then AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 60, -25) else
                          if isAfterAttack and (ThinkingHH^.Hedgehog <> Gear^.Hedgehog) then
                             if (MyColor = PHedgehog(Gear^.Hedgehog)^.Team^.Color) then AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 150, -3) // hedgehog-friend
                                                                                   else AddBonus(hwRound(Gear^.X), hwRound(Gear^.Y), 100, 3)
                       end;
           end;
      Gear:= Gear^.NextGear
      end;
if isAfterAttack and (KnownExplosion.Radius > 0) then
   with KnownExplosion do
        AddBonus(X, Y, Radius + 10, -Radius);
end;

procedure AwareOfExplosion(x, y, r: integer);
begin
KnownExplosion.X:= x;
KnownExplosion.Y:= y;
KnownExplosion.Radius:= r
end;

function RatePlace(Gear: PGear): integer;
var i, r: integer;
    Result: integer;
begin
Result:= 0;
for i:= 0 to Pred(bonuses.Count) do
    with bonuses.ar[i] do
         begin
         r:= hwRound(Distance(Gear^.X - X, Gear^.Y - y));
         if r < Radius then
            inc(Result, Score * (Radius - r))
         end;
    RatePlace:= Result
end;

function TestColl(x, y, r: integer): boolean;
var b: boolean;
begin
b:= (((x-r) and $FFFFF800) = 0)and(((y-r) and $FFFFFC00) = 0) and (Land[y-r, x-r] <> 0);
if b then exit(true);
b:=(((x-r) and $FFFFF800) = 0)and(((y+r) and $FFFFFC00) = 0) and (Land[y+r, x-r] <> 0);
if b then exit(true);
b:=(((x+r) and $FFFFF800) = 0)and(((y-r) and $FFFFFC00) = 0) and (Land[y-r, x+r] <> 0);
if b then exit(true);
TestColl:=(((x+r) and $FFFFF800) = 0)and(((y+r) and $FFFFFC00) = 0) and (Land[y+r, x+r] <> 0)
end;

function RateExplosion(Me: PGear; x, y, r: integer): integer;
var i, dmg, Result: integer;
begin
Result:= 0;
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
         dmg:= r - hwRound(Distance(Point.x - x, Point.y - y));
         if dmg > 0 then
            begin
            dmg:= dmg shr 1;
            if dmg > abs(Score) then
               if Score > 0 then inc(Result, KillScore)
                            else dec(Result, KillScore * 3)
            else
               if Score > 0 then inc(Result, dmg)
                            else dec(Result, dmg * 3)
            end;
         end;
RateExplosion:= Result * 1024
end;

function RateShove(Me: PGear; x, y, r, power: integer): integer;
var i, dmg, Result: integer;
begin
Result:= 0;
for i:= 0 to Targets.Count do
    with Targets.ar[i] do
         begin
         dmg:= r - hwRound(Distance(Point.x - x, Point.y - y));
         if dmg > 0 then
            begin
            if power > abs(Score) then
               if Score > 0 then inc(Result, KillScore)
                            else dec(Result, KillScore * 3)
            else
               if Score > 0 then inc(Result, power)
                            else dec(Result, power * 3)
            end;
         end;
RateShove:= Result * 1024
end;

function HHJump(Gear: PGear; JumpType: TJumpType; var GoInfo: TGoInfo): boolean;
var bX, bY: integer;
    Result: boolean;
begin
Result:= false;
GoInfo.Ticks:= 0;
GoInfo.FallPix:= 0;
GoInfo.JumpType:= jmpNone;
bX:= hwRound(Gear^.X);
bY:= hwRound(Gear^.Y);
case JumpType of
     jmpNone: exit(Result);
    jmpHJump: if not TestCollisionYwithGear(Gear, -1) then
                 begin
                 Gear^.dY:= -_0_2;
                 SetLittle(Gear^.dX);
                 Gear^.State:= Gear^.State or gstFalling or gstHHJumping;
                 end else exit(Result);
    jmpLJump: begin
              if not TestCollisionYwithGear(Gear, -1) then
                 if not TestCollisionXwithXYShift(Gear, 0, -2, hwSign(Gear^.dX)) then Gear^.Y:= Gear^.Y - 2 else
                 if not TestCollisionXwithXYShift(Gear, 0, -1, hwSign(Gear^.dX)) then Gear^.Y:= Gear^.Y - 1;
              if not (TestCollisionXwithGear(Gear, hwSign(Gear^.dX))
                 or   TestCollisionYwithGear(Gear, -1)) then
                 begin
                 Gear^.dY:= _0_15;
                 Gear^.dX:= hwSign(Gear^.dX) * _0_15;
                 Gear^.State:= Gear^.State or gstFalling or gstHHJumping
                 end else exit(Result)
              end
    end;
    
repeat
if not (Gear^.Y + cHHRadius < cWaterLine) then exit(Result);
if (Gear^.State and gstFalling) <> 0 then
   begin
   if (GoInfo.Ticks = 350) then
      if (hwAbs(Gear^.dX) < cLittle + cLittle) and (Gear^.dY < -_0_02) then
         begin
         Gear^.dY:= -_0_25;
         Gear^.dX:= hwSign(Gear^.dX) * _0_02
         end;
   if TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) then SetLittle(Gear^.dX);
   Gear^.X:= Gear^.X + Gear^.dX;
   inc(GoInfo.Ticks);
   Gear^.dY:= Gear^.dY + cGravity;
   if Gear^.dY > _0_4 then exit(Result);
   if (Gear^.dY.isNegative)and TestCollisionYwithGear(Gear, -1) then Gear^.dY:= 0;
   Gear^.Y:= Gear^.Y + Gear^.dY;
   if (not Gear^.dY.isNegative)and TestCollisionYwithGear(Gear, 1) then
      begin
      Gear^.State:= Gear^.State and not (gstFalling or gstHHJumping);
      Gear^.dY:= 0;
      case JumpType of
           jmpHJump: if (bY - Gear^.Y > 5) then
                        begin
                        Result:= true;
                        GoInfo.JumpType:= jmpHJump;
                        inc(GoInfo.Ticks, 300 + 300) // 300 before jump, 300 after
                        end;
           jmpLJump: if hwAbs(bX - Gear^.X) > 30 then
                        begin
                        Result:= true;
                        GoInfo.JumpType:= jmpLJump;
                        inc(GoInfo.Ticks, 300 + 300) // 300 before jump, 300 after
                        end;
           end;
      exit(Result)
      end;
   end;
until false
end;

function HHGo(Gear, AltGear: PGear; var GoInfo: TGoInfo): boolean;
var pX, pY: integer;
    Result: boolean;
begin
Result:= false;
AltGear^:= Gear^;

GoInfo.Ticks:= 0;
GoInfo.FallPix:= 0;
GoInfo.JumpType:= jmpNone;
repeat
pX:= hwRound(Gear^.X);
pY:= hwRound(Gear^.Y);
if pY + cHHRadius >= cWaterLine then exit;
if (Gear^.State and gstFalling) <> 0 then
   begin
   inc(GoInfo.Ticks);
   Gear^.dY:= Gear^.dY + cGravity;
   if Gear^.dY > _0_4 then
      begin
      Goinfo.FallPix:= 0;
      HHJump(AltGear, jmpLJump, GoInfo); // try ljump enstead of fall with damage
      exit(Result)
      end;
   Gear^.Y:= Gear^.Y + Gear^.dY;
   if hwRound(Gear^.Y) > pY then inc(GoInfo.FallPix);
   if TestCollisionYwithGear(Gear, 1) then
      begin
      inc(GoInfo.Ticks, 300);
      Gear^.State:= Gear^.State and not (gstFalling or gstHHJumping);
      Gear^.dY:= 0;
      Result:= true;
      HHJump(AltGear, jmpLJump, GoInfo); // try ljump instead of fall
      exit(Result)
      end;
   continue
   end;
   if (Gear^.Message and gm_Left  )<>0 then Gear^.dX:= -cLittle else
   if (Gear^.Message and gm_Right )<>0 then Gear^.dX:=  cLittle else exit(Result);
   if TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) then
      begin
      if not (TestCollisionXwithXYShift(Gear, 0, -6, hwSign(Gear^.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear^.Y:= Gear^.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -5, hwSign(Gear^.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear^.Y:= Gear^.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -4, hwSign(Gear^.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear^.Y:= Gear^.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -3, hwSign(Gear^.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear^.Y:= Gear^.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -2, hwSign(Gear^.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear^.Y:= Gear^.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -1, hwSign(Gear^.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear^.Y:= Gear^.Y - 1;
      end;

   if not TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) then
      begin
      Gear^.X:= Gear^.X + Gear^.dX;
      inc(GoInfo.Ticks, cHHStepTicks)
      end;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear^.Y:= Gear^.Y + 1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear^.Y:= Gear^.Y + 1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear^.Y:= Gear^.Y + 1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear^.Y:= Gear^.Y + 1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear^.Y:= Gear^.Y + 1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear^.Y:= Gear^.Y + 1;
   if not TestCollisionYwithGear(Gear, 1) then
      begin
      Gear^.Y:= Gear^.Y - 6;
      Gear^.dY:= 0;
      Gear^.State:= Gear^.State or gstFalling
      end
   end
   end
   end
   end
   end
   end;
if (pX <> hwRound(Gear^.X)) and ((Gear^.State and gstFalling) = 0) then
   begin
   Result:= true;
   exit(Result)
   end
until (pX = hwRound(Gear^.X)) and (pY = hwRound(Gear^.Y)) and ((Gear^.State and gstFalling) = 0);
HHJump(AltGear, jmpHJump, GoInfo)
end;

{function rndSign(num: integer): integer;
begin
if random(2) = 0 then Result:=   num
                 else Result:= - num
end;  }

end.
