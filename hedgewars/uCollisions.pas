(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * Distributed under the terms of the BSD-modified licence:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * with the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *)

unit uCollisions;
interface
uses uGears;
{$INCLUDE options.inc}

type TCollisionEntry = record
                       X, Y, HWidth, HHeight: integer;
                       cGear: PGear;
                       end;

procedure AddGearCR(Gear: PGear);
procedure UpdateCR(NewX, NewY: integer; Index: Longword);
procedure DeleteCR(Gear: PGear);
function  CheckGearsCollision(Gear: PGear; Dir: integer; forX: boolean): PGear;
function  HHTestCollisionYwithGear(Gear: PGear; Dir: integer): boolean;
function TestCollisionXwithGear(Gear: PGear; Dir: integer): boolean;
function TestCollisionYwithGear(Gear: PGear; Dir: integer): boolean;
function TestCollisionXwithXYShift(Gear: PGear; ShiftX, ShiftY: integer; Dir: integer): boolean;
function TestCollisionYwithXYShift(Gear: PGear; ShiftX, ShiftY: integer; Dir: integer): boolean;
function TestCollisionY(Gear: PGear; Dir: integer): boolean;

implementation
uses uMisc, uConsts, uLand;

const MAXRECTSINDEX = 255;
var Count: Longword = 0;
    crects: array[0..MAXRECTSINDEX] of TCollisionEntry;

procedure AddGearCR(Gear: PGear);
begin
TryDo(Count <= MAXRECTSINDEX, 'Collision rects array overflow', true);
with crects[Count] do
     begin
     X:= round(Gear.X);
     Y:= round(Gear.Y);
     HWidth:= Gear.HalfWidth;
     HHeight:= Gear.HalfHeight;
     cGear:= Gear
     end;
Gear.CollIndex:= Count;
inc(Count)
end;

procedure UpdateCR(NewX, NewY: integer; Index: Longword);
begin
with crects[Index] do
     begin
     X:= NewX;
     Y:= NewY
     end
end;

procedure DeleteCR(Gear: PGear);
begin
if Gear.CollIndex < Pred(Count) then
   begin
   crects[Gear.CollIndex]:= crects[Pred(Count)];
   crects[Gear.CollIndex].cGear.CollIndex:= Gear.CollIndex
   end;
Gear.CollIndex:= High(Longword);
dec(Count)
end;

function CheckGearsCollision(Gear: PGear; Dir: integer; forX: boolean): PGear;
var x1, x2, y1, y2: integer;
    i: Longword;
begin
Result:= nil;
if Count = 0 then exit;
x1:= round(Gear.X);
y1:= round(Gear.Y);

if forX then
   begin
   x1:= x1 + Dir*Gear.HalfWidth;
   x2:= x1;
   y2:= y1 + Gear.HalfHeight - 1;
   y1:= y1 - Gear.HalfHeight + 1
   end else
   begin
   y1:= y1 + Dir*Gear.HalfHeight;
   y2:= y1;
   x2:= x1 + Gear.HalfWidth - 1;
   x1:= x1 - Gear.HalfWidth + 1
   end;

for i:= 0 to Pred(Count) do
   with crects[i] do
      if  (Gear.CollIndex <> i)
         and (x1 <= X + HWidth)
         and (x2 >= X - HWidth)
         and (y1 <= Y + HHeight)
         and (y2 >= Y - HHeight) then
             begin
             Result:= crects[i].cGear;
             exit
             end;
end;

function HHTestCollisionYwithGear(Gear: PGear; Dir: integer): boolean;
var x, y, i: integer;
begin
Result:= false;
y:= round(Gear.Y);
if Dir < 0 then y:= y - Gear.HalfHeight
           else y:= y + Gear.HalfHeight;
           
if ((y - Dir) and $FFFFFC00) = 0 then
   begin
   x:= round(Gear.X);
   if (((x - Gear.HalfWidth) and $FFFFF800) = 0)and(Land[y - Dir, x - Gear.HalfWidth] <> 0)
    or(((x + Gear.HalfWidth) and $FFFFF800) = 0)and(Land[y - Dir, x + Gear.HalfWidth] <> 0) then
      begin
      Result:= true;
      exit
      end
    end;

if (y and $FFFFFC00) = 0 then
   begin
   x:= round(Gear.X) - Gear.HalfWidth + 1;
   i:= x + Gear.HalfWidth * 2 - 2;
   repeat
     if (x and $FFFFF800) = 0 then Result:= Land[y, x]<>0;
     inc(x)
   until (x > i) or Result;
   if Result then exit;

   Result:= CheckGearsCollision(Gear, Dir, false) <> nil
   end
end;

function TestCollisionXwithGear(Gear: PGear; Dir: integer): boolean;
var x, y, i: integer;
begin
Result:= false;
x:= round(Gear.X);
if Dir < 0 then x:= x - Gear.HalfWidth
           else x:= x + Gear.HalfWidth;
if (x and $FFFFF800) = 0 then
   begin
   y:= round(Gear.Y) - Gear.HalfHeight + 1; {*}
   i:= y + Gear.HalfHeight * 2 - 2;         {*}
   repeat
     if (y and $FFFFFC00) = 0 then Result:= Land[y, x]<>0;
     inc(y)
   until (y > i) or Result;
   if Result then exit;
   Result:= CheckGearsCollision(Gear, Dir, true) <> nil
   end
end;

function TestCollisionXwithXYShift(Gear: PGear; ShiftX, ShiftY: integer; Dir: integer): boolean;
begin
Gear.X:= Gear.X + ShiftX;
Gear.Y:= Gear.Y + ShiftY;
Result:= TestCollisionXwithGear(Gear, Dir);
Gear.X:= Gear.X - ShiftX;
Gear.Y:= Gear.Y - ShiftY
end;

function TestCollisionYwithGear(Gear: PGear; Dir: integer): boolean;
var x, y, i: integer;
begin
Result:= false;
y:= round(Gear.Y);
if Dir < 0 then y:= y - Gear.HalfHeight
           else y:= y + Gear.HalfHeight;
if (y and $FFFFFC00) = 0 then
   begin
   x:= round(Gear.X) - Gear.HalfWidth + 1;    {*}
   i:= x + Gear.HalfWidth * 2 - 2;            {*}
   repeat
     if (x and $FFFFF800) = 0 then Result:= Land[y, x]<>0;
     inc(x)
   until (x > i) or Result;
   if Result then exit;
   Result:= CheckGearsCollision(Gear, Dir, false) <> nil;
   end
end;

function TestCollisionY(Gear: PGear; Dir: integer): boolean;
var x, y, i: integer;
begin
Result:= false;
y:= round(Gear.Y);
if Dir < 0 then y:= y - Gear.HalfHeight
           else y:= y + Gear.HalfHeight;
if (y and $FFFFFC00) = 0 then
   begin
   x:= round(Gear.X) - Gear.HalfWidth + 1;    {*}
   i:= x + Gear.HalfWidth * 2 - 2;            {*}
   repeat
     if (x and $FFFFF800) = 0 then Result:= Land[y, x]<>0;
     inc(x)
   until (x > i) or Result;
   end
end;

function TestCollisionYwithXYShift(Gear: PGear; ShiftX, ShiftY: integer; Dir: integer): boolean;
begin
Gear.X:= Gear.X + ShiftX;
Gear.Y:= Gear.Y + ShiftY;
Result:= TestCollisionYwithGear(Gear, Dir);
Gear.X:= Gear.X - ShiftX;
Gear.Y:= Gear.Y - ShiftY
end;

end.
