(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005-2007 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uAIAmmoTests;
interface
uses SDLh, uGears, uConsts, uFloat;

function TestBazooka(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
function TestGrenade(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
function TestShotgun(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
function TestDesertEagle(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
function TestBaseballBat(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
function TestFirePunch(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;

type TAmmoTestProc = function (Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
const AmmoTests: array[TAmmoType] of TAmmoTestProc =
                 (
{amGrenade}       @TestGrenade,
{amClusterBomb}   nil,
{amBazooka}       @TestBazooka,
{amUFO}           nil,
{amShotgun}       @TestShotgun,
{amPickHammer}    nil,
{amSkip}          nil,
{amRope}          nil,
{amMine}          nil,
{amDEagle}        @TestDesertEagle,
{amDynamite}      nil,
{amFirePunch}     @TestFirePunch,
{amBaseballBat}   @TestBaseballBat,
{amParachute}     nil,
{amAirAttack}     nil,
{amMineStrike}    nil,
{amBlowTorch}     nil,
{amGirder}        nil
                  );

const BadTurn = Low(LongInt) div 4;


implementation
uses uMisc, uAIMisc, uLand;

function Metric(x1, y1, x2, y2: LongInt): LongInt;
begin
Metric:= abs(x1 - x2) + abs(y1 - y2)
end;

function TestBazooka(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
var Vx, Vy, r: hwFloat;
    rTime: LongInt;
    Score, EX, EY: LongInt;
    Result: LongInt;

    function CheckTrace: LongInt;
    var x, y, dX, dY: hwFloat;
        t: LongInt;
        Result: LongInt;
    begin
    x:= Me^.X;
    y:= Me^.Y;
    dX:= Vx;
    dY:= -Vy;
    t:= rTime;
    repeat
      x:= x + dX;
      y:= y + dY;
      dX:= dX + cWindSpeed;
      dY:= dY + cGravity;
      dec(t)
    until TestColl(hwRound(x), hwRound(y), 5) or (t <= 0);
    EX:= hwRound(x);
    EY:= hwRound(y);
    Result:= RateExplosion(Me, EX, EY, 101);
    if Result = 0 then Result:= - Metric(Targ.X, Targ.Y, EX, EY) div 64;
    CheckTrace:= Result
    end;

begin
Time:= 0;
rTime:= 350;
ExplR:= 0;
Result:= BadTurn;
repeat
  rTime:= rTime + 300 + Level * 50 + random(300);
  Vx:= - cWindSpeed * rTime * _0_5 + (int2hwFloat(Targ.X) - Me^.X) / int2hwFloat(rTime);
  Vy:= cGravity * rTime * _0_5 - (int2hwFloat(Targ.Y) - Me^.Y) / int2hwFloat(rTime);
  r:= Distance(Vx, Vy);
  if not (r > _1) then
     begin
     Score:= CheckTrace;
     if Result <= Score then
        begin
        Angle:= DxDy2AttackAngle(Vx, Vy) + AIrndSign(random((Level - 1) * 9));
        Power:= hwRound(r * cMaxPower) - random((Level - 1) * 17 + 1);
        ExplR:= 100;
        ExplX:= EX;
        ExplY:= EY;
        Result:= Score
        end;
     end
until (rTime > 4250);
TestBazooka:= Result
end;

function TestGrenade(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
const tDelta = 24;
var Vx, Vy, r: hwFloat;
    Score, EX, EY, Result: LongInt;
    TestTime: Longword;

    function CheckTrace: LongInt;
    var x, y, dY: hwFloat;
        t: LongInt;
    begin
    x:= Me^.X;
    y:= Me^.Y;
    dY:= -Vy;
    t:= TestTime;
    repeat
      x:= x + Vx;
      y:= y + dY;
      dY:= dY + cGravity;
      dec(t)
    until TestColl(hwRound(x), hwRound(y), 5) or (t = 0);
    EX:= hwRound(x);
    EY:= hwRound(y);
    if t < 50 then CheckTrace:= RateExplosion(Me, EX, EY, 101)
              else CheckTrace:= Low(LongInt)
    end;

begin
Result:= BadTurn;
TestTime:= 0;
ExplR:= 0;
repeat
  inc(TestTime, 1000);
  Vx:= (int2hwFloat(Targ.X) - Me^.X) / int2hwFloat(TestTime + tDelta);
  Vy:= cGravity * ((TestTime + tDelta) div 2) - (int2hwFloat(Targ.Y) - Me^.Y) / int2hwFloat(TestTime + tDelta);
  r:= Distance(Vx, Vy);
  if not (r > _1) then
     begin
     Score:= CheckTrace;
     if Result < Score then
        begin
        Angle:= DxDy2AttackAngle(Vx, Vy) + AIrndSign(random(Level));
        Power:= hwRound(r * cMaxPower) + AIrndSign(random(Level) * 15);
        Time:= TestTime;
        ExplR:= 100;
        ExplX:= EX;
        ExplY:= EY;
        Result:= Score
        end;
     end
until (TestTime = 4000);
TestGrenade:= Result
end;

function TestShotgun(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
var Vx, Vy, x, y: hwFloat;
    rx, ry, Result: LongInt;
begin
ExplR:= 0;
Time:= 0;
Power:= 1;
if Metric(hwRound(Me^.X), hwRound(Me^.Y), Targ.X, Targ.Y) < 80 then
   exit(BadTurn);
Vx:= (int2hwFloat(Targ.X) - Me^.X) * _1div1024;
Vy:= (int2hwFloat(Targ.Y) - Me^.Y) * _1div1024;
x:= Me^.X;
y:= Me^.Y;
Angle:= DxDy2AttackAngle(Vx, -Vy);
repeat
  x:= x + vX;
  y:= y + vY;
  rx:= hwRound(x);
  ry:= hwRound(y);
  if TestColl(rx, ry, 2) then
     begin
     x:= x + vX * 8;
     y:= y + vY * 8;
     Result:= RateShotgun(Me, rx, ry) * 2;
     if Result = 0 then Result:= - Metric(Targ.X, Targ.Y, rx, ry) div 64
                   else dec(Result, Level * 4000);
     exit(Result)
     end
until (Abs(Targ.X - hwRound(x)) + Abs(Targ.Y - hwRound(y)) < 4) or (x < _0) or (y < _0) or (x > _2048) or (y > _1024);
TestShotgun:= BadTurn
end;

function TestDesertEagle(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
var Vx, Vy, x, y, t: hwFloat;
    d: Longword;
    Result: LongInt;
begin
ExplR:= 0;
Time:= 0;
Power:= 1;
if Abs(hwRound(Me^.X) - Targ.X) + Abs(hwRound(Me^.Y) - Targ.Y) < 80 then
   exit(BadTurn);
t:= _0_5 / Distance(int2hwFloat(Targ.X) - Me^.X, int2hwFloat(Targ.Y) - Me^.Y);
Vx:= (int2hwFloat(Targ.X) - Me^.X) * t;
Vy:= (int2hwFloat(Targ.Y) - Me^.Y) * t;
x:= Me^.X;
y:= Me^.Y;
Angle:= DxDy2AttackAngle(Vx, -Vy);
d:= 0;
repeat
  x:= x + vX;
  y:= y + vY;
  if ((hwRound(x) and $FFFFF800) = 0)and((hwRound(y) and $FFFFFC00) = 0)
     and (Land[hwRound(y), hwRound(x)] <> 0) then inc(d);
until (Abs(Targ.X - hwRound(x)) + Abs(Targ.Y - hwRound(y)) < 4) or (x < _0) or (y < _0) or (x > _2048) or (y > _1024) or (d > 200);
if Abs(Targ.X - hwRound(x)) + Abs(Targ.Y - hwRound(y)) < 3 then Result:= max(0, (4 - d div 50) * 7 * 1024)
                                                           else Result:= Low(LongInt);
TestDesertEagle:= Result
end;

function TestBaseballBat(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
var Result: LongInt;
begin
ExplR:= 0;
if (Level > 2) and not (Abs(hwRound(Me^.X) - Targ.X) + Abs(hwRound(Me^.Y) - Targ.Y) < 25) then
   exit(BadTurn);

Time:= 0;
Power:= 1;
if (Targ.X) - hwRound(Me^.X) >= 0 then Angle:=   cMaxAngle div 4
                                  else Angle:= - cMaxAngle div 4;
Result:= RateShove(Me, hwRound(Me^.X) + 10 * hwSign(int2hwFloat(Targ.X) - Me^.X), hwRound(Me^.Y), 15, 30);
if Result <= 0 then Result:= BadTurn else inc(Result);
TestBaseballBat:= Result
end;

function TestFirePunch(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
var i, Result: LongInt;
begin
ExplR:= 0;
Time:= 0;
Power:= 1;
Angle:= 0;
if (Abs(hwRound(Me^.X) - Targ.X) > 25) or (Abs(hwRound(Me^.Y) - 50 - Targ.Y) > 50) then
   exit(BadTurn);

Result:= 0;
for i:= 0 to 4 do
    Result:= Result + RateShove(Me, hwRound(Me^.X) + 10 * hwSign(int2hwFloat(Targ.X) - Me^.X),
                                    hwRound(Me^.Y) - 20 * i - 5, 10, 30);
if Result <= 0 then Result:= BadTurn else inc(Result);
TestFirePunch:= Result
end;

end.
