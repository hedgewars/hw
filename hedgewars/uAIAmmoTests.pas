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

unit uAIAmmoTests;
interface
uses SDLh, uGears, uConsts, uFloat;

function TestBazooka(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
(*function TestGrenade(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
function TestShotgun(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
function TestDesertEagle(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
function TestBaseballBat(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
function TestFirePunch(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
*)
type TAmmoTestProc = function (Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
const AmmoTests: array[TAmmoType] of TAmmoTestProc =
                 (
{amGrenade}       nil,//TestGrenade,
{amClusterBomb}   nil,
{amBazooka}       @TestBazooka,
{amUFO}           nil,
{amShotgun}       nil,//TestShotgun,
{amPickHammer}    nil,
{amSkip}          nil,
{amRope}          nil,
{amMine}          nil,
{amDEagle}        nil,//TestDesertEagle,
{amDynamite}      nil,
{amFirePunch}     nil,//TestFirePunch,
{amBaseballBat}   nil,//TestBaseballBat,
{amParachute}     nil,
{amAirAttack}     nil,
{amMineStrike}    nil,
{amBlowTorch}     nil
                  );

const BadTurn = Low(LongInt);


implementation
uses uMisc, uAIMisc, uLand;

function Metric(x1, y1, x2, y2: LongInt): LongInt;
begin
Metric:= abs(x1 - x2) + abs(y1 - y2)
end;

function TestBazooka(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
var Vx, Vy, r: hwFloat;
    rTime: hwFloat;
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
    t:= hwRound(rTime);
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
rTime:= 50;
ExplR:= 0;
Result:= BadTurn;
repeat
  rTime:= rTime + 300 + Level * 50 + random(200);
  Vx:= - cWindSpeed * rTime * _0_5 + (Targ.X - hwRound(Me^.X)) / rTime;
  Vy:= cGravity * rTime * _0_5 - (Targ.Y - hwRound(Me^.Y)) / rTime;
  r:= Distance(Vx, Vy);
  if not (r > 1) then
     begin
     Score:= CheckTrace;
     if Result <= Score then
        begin
        Angle:= DxDy2AttackAngle(Vx, Vy) + AIrndSign(random((Level - 1) * 8));
        Power:= hwRound(r * cMaxPower) - random((Level - 1) * 15 + 1);
        ExplR:= 100;
        ExplX:= EX;
        ExplY:= EY;
        Result:= Score
        end;
     end
until (rTime > 4500);
TestBazooka:= Result
end;
{
function TestGrenade(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
const tDelta = 24;
var Vx, Vy, r: hwFloat;
    Score, EX, EY: LongInt;
    TestTime: Longword;

    function CheckTrace: LongInt;
    var x, y, dY: hwFloat;
        t: LongInt;
    begin
    x:= Me.X;
    y:= Me.Y;
    dY:= -Vy;
    t:= TestTime;
    repeat
      x:= x + Vx;
      y:= y + dY;
      dY:= dY + cGravity;
      dec(t)
    until TestColl(round(x), round(y), 5) or (t = 0);
    EX:= round(x);
    EY:= round(y);
    if t < 50 then Result:= RateExplosion(Me, round(x), round(y), 101)
              else Result:= Low(LongInt)
    end;

begin
Result:= BadTurn;
TestTime:= 0;
ExplR:= 0;
repeat
  inc(TestTime, 1000);
  Vx:= (Targ.X - Me.X) / (TestTime + tDelta);
  Vy:= cGravity*((TestTime + tDelta) div 2) - (Targ.Y - Me.Y) / (TestTime + tDelta);
  r:= sqr(Vx) + sqr(Vy);
  if r <= 1 then
     begin
     Score:= CheckTrace;
     if Result < Score then
        begin
        r:= sqrt(r);
        Angle:= DxDy2AttackAngle(Vx, Vy) + rndSign(random(Level));
        Power:= round(r * cMaxPower) + rndSign(random(Level) * 12);
        Time:= TestTime;
        ExplR:= 100;
        ExplX:= EX;
        ExplY:= EY;
        Result:= Score
        end;
     end
until (TestTime = 5000)
end;

function TestShotgun(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
var Vx, Vy, x, y: hwFloat;
begin       
ExplR:= 0;
if Metric(round(Me.X), round(Me.Y), Targ.X, Targ.Y) < 80 then
   begin
   Result:= BadTurn;
   exit
   end;
Time:= 0;
Power:= 1;
Vx:= (Targ.X - Me.X)/1024;
Vy:= (Targ.Y - Me.Y)/1024;
x:= Me.X;
y:= Me.Y;
Angle:= DxDy2AttackAngle(Vx, -Vy);
repeat
  x:= x + vX;
  y:= y + vY;
  if TestColl(round(x), round(y), 2) then
     begin
     Result:= RateShove(Me, round(x), round(y), 25, 25) * 2;
     if Result = 0 then Result:= - Metric(Targ.X, Targ.Y, round(x), round(y)) div 64
                   else dec(Result, Level * 4000);
     exit
     end
until (abs(Targ.X - x) + abs(Targ.Y - y) < 4) or (x < 0) or (y < 0) or (x > 2048) or (y > 1024);
Result:= BadTurn
end;

function TestDesertEagle(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
var Vx, Vy, x, y, t: hwFloat;
    d: Longword;
begin
ExplR:= 0;
if abs(Me.X - Targ.X) + abs(Me.Y - Targ.Y) < 80 then
   begin
   Result:= BadTurn;
   exit
   end;
Time:= 0;
Power:= 1;
t:= sqrt(sqr(Targ.X - Me.X) + sqr(Targ.Y - Me.Y)) * 2;
Vx:= (Targ.X - Me.X) / t;
Vy:= (Targ.Y - Me.Y) / t;
x:= Me.X;
y:= Me.Y;
Angle:= DxDy2AttackAngle(Vx, -Vy);
d:= 0;
repeat
  x:= x + vX;
  y:= y + vY;
  if ((round(x) and $FFFFF800) = 0)and((round(y) and $FFFFFC00) = 0)
     and (Land[round(y), round(x)] <> 0) then inc(d);
until (abs(Targ.X - x) + abs(Targ.Y - y) < 2) or (x < 0) or (y < 0) or (x > 2048) or (y > 1024) or (d > 200);
if abs(Targ.X - x) + abs(Targ.Y - y) < 2 then Result:= max(0, (4 - d div 50) * 7 * 1024)
                                         else Result:= Low(LongInt)
end;

function TestBaseballBat(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
begin
ExplR:= 0;
if (Level > 2) and (abs(Me.X - Targ.X) + abs(Me.Y - Targ.Y) >= 25) then
   begin
   Result:= BadTurn;
   exit
   end;
Time:= 0;
Power:= 1;
Angle:= DxDy2AttackAngle(hwSign(Targ.X - Me.X), 1);
Result:= RateShove(Me, round(Me.X) + 10 * hwSign(Targ.X - Me.X), round(Me.Y), 15, 30);
if Result <= 0 then Result:= BadTurn
end;

function TestFirePunch(Me: PGear; Targ: TPoint; Level: LongInt; var Time: Longword; var Angle, Power: LongInt; var ExplX, ExplY, ExplR: LongInt): LongInt;
var i: LongInt;
begin
ExplR:= 0;
if (abs(Me.X - Targ.X) > 25) or (abs(Me.Y - 50 - Targ.Y) > 50) then
   begin
   Result:= BadTurn;
   exit
   end;
Time:= 0;
Power:= 1;
Angle:= DxDy2AttackAngle(hwSign(Targ.X - Me.X), 1);
Result:= 0;
for i:= 0 to 4 do
    Result:= Result + RateShove(Me, round(Me.X) + 10 * hwSign(Targ.X - Me.X), round(Me.Y) - 20 * i - 5, 10, 30);
if Result <= 0 then Result:= BadTurn
end;
}
end.
