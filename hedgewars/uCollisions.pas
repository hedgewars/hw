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

unit uCollisions;
interface
uses uGears, uFloat;
{$INCLUDE options.inc}
const cMaxGearArrayInd = 255;

type PGearArray = ^TGearArray;
     TGearArray = record
                  ar: array[0..cMaxGearArrayInd] of PGear;
                  Count: Longword
                  end;

procedure AddGearCI(Gear: PGear);
procedure DeleteCI(Gear: PGear);
function CheckGearsCollision(Gear: PGear): PGearArray;
function TestCollisionXwithGear(Gear: PGear; Dir: integer): boolean;
function TestCollisionYwithGear(Gear: PGear; Dir: integer): boolean;
function TestCollisionY(Gear: PGear; Dir: integer): boolean;
function TestCollisionXwithXYShift(Gear: PGear; ShiftX, ShiftY: hwFloat; Dir: integer): boolean;
function TestCollisionYwithXYShift(Gear: PGear; ShiftX, ShiftY: integer; Dir: integer): boolean;

implementation
uses uMisc, uConsts, uLand, uLandGraphics;

type TCollisionEntry = record
                       X, Y, Radius: integer;
                       cGear: PGear;
                       end;

const MAXRECTSINDEX = 255;
var Count: Longword = 0;
    cinfos: array[0..MAXRECTSINDEX] of TCollisionEntry;
    ga: TGearArray;

procedure AddGearCI(Gear: PGear);
begin
if Gear^.CollIndex < High(Longword) then exit;
TryDo(Count <= MAXRECTSINDEX, 'Collision rects array overflow', true);
with cinfos[Count] do
     begin
     X:= hwRound(Gear^.X);
     Y:= hwRound(Gear^.Y);
     Radius:= Gear^.Radius;
     FillRoundInLand(X, Y, Radius-1, $FF);
     cGear:= Gear
     end;
Gear^.CollIndex:= Count;
inc(Count)
end;

procedure DeleteCI(Gear: PGear);
begin
if Gear^.CollIndex < Count then
   begin
   with cinfos[Gear^.CollIndex] do FillRoundInLand(X, Y, Radius-1, 0);
   cinfos[Gear^.CollIndex]:= cinfos[Pred(Count)];
   cinfos[Gear^.CollIndex].cGear^.CollIndex:= Gear^.CollIndex;
   Gear^.CollIndex:= High(Longword);
   dec(Count)
   end;
end;

function CheckGearsCollision(Gear: PGear): PGearArray;
var mx, my: integer;
    i: Longword;
    Result: PGearArray;
begin
Result:= @ga;
ga.Count:= 0;
if Count = 0 then exit;
mx:= hwRound(Gear^.X);
my:= hwRound(Gear^.Y);

for i:= 0 to Pred(Count) do
   with cinfos[i] do
      if (Gear <> cGear) and
         (sqrt(sqr(mx - x) + sqr(my - y)) <= Radius + Gear^.Radius) then
             begin
             ga.ar[ga.Count]:= cinfos[i].cGear;
             inc(ga.Count)
             end;
CheckGearsCollision:= Result
end;

function TestCollisionXwithGear(Gear: PGear; Dir: integer): boolean;
var x, y, i: integer;
begin
x:= hwRound(Gear^.X);
if Dir < 0 then x:= x - Gear^.Radius
           else x:= x + Gear^.Radius;
if (x and $FFFFF800) = 0 then
   begin
   y:= hwRound(Gear^.Y) - Gear^.Radius + 1;
   i:= y + Gear^.Radius * 2 - 2;
   repeat
     if (y and $FFFFFC00) = 0 then
        if Land[y, x] <> 0 then exit(true);
     inc(y)
   until (y > i);
   end;
TestCollisionXwithGear:= false
end;

function TestCollisionXwithXYShift(Gear: PGear; ShiftX, ShiftY: hwFloat; Dir: integer): boolean;
begin
Gear^.X:= Gear^.X + ShiftX;
Gear^.Y:= Gear^.Y + ShiftY;
TestCollisionXwithXYShift:= TestCollisionXwithGear(Gear, Dir);
Gear^.X:= Gear^.X - ShiftX;
Gear^.Y:= Gear^.Y - ShiftY
end;

function TestCollisionYwithGear(Gear: PGear; Dir: integer): boolean;
var x, y, i: integer;
begin
y:= hwRound(Gear^.Y);
if Dir < 0 then y:= y - Gear^.Radius
           else y:= y + Gear^.Radius;
if (y and $FFFFFC00) = 0 then
   begin
   x:= hwRound(Gear^.X) - Gear^.Radius + 1;
   i:= x + Gear^.Radius * 2 - 2;
   repeat
     if (x and $FFFFF800) = 0 then
        if Land[y, x] <> 0 then exit(true);
     inc(x)
   until (x > i);
   end;
TestCollisionYwithGear:= false
end;

function TestCollisionY(Gear: PGear; Dir: integer): boolean;
var x, y, i: integer;
begin
y:= hwRound(Gear^.Y);
if Dir < 0 then y:= y - Gear^.Radius
           else y:= y + Gear^.Radius;
if (y and $FFFFFC00) = 0 then
   begin
   x:= hwRound(Gear^.X) - Gear^.Radius + 1;
   i:= x + Gear^.Radius * 2 - 2;
   repeat
     if (x and $FFFFF800) = 0 then
        if Land[y, x] = COLOR_LAND then exit(true);
     inc(x)
   until (x > i);
   end;
TestCollisionY:= false
end;

function TestCollisionYwithXYShift(Gear: PGear; ShiftX, ShiftY: integer; Dir: integer): boolean;
begin
Gear^.X:= Gear^.X + ShiftX;
Gear^.Y:= Gear^.Y + ShiftY;
TestCollisionYwithXYShift:= TestCollisionYwithGear(Gear, Dir);
Gear^.X:= Gear^.X - ShiftX;
Gear^.Y:= Gear^.Y - ShiftY
end;

end.
