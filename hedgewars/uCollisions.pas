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

unit uCollisions;
interface
uses uFloat, uTypes, uUtils;

const cMaxGearArrayInd = 1023;
const cMaxGearHitOrderInd = 1023;

type PGearArray = ^TGearArray;
    TGearArray = record
        ar: array[0..cMaxGearArrayInd] of PGear;
        cX: array[0..cMaxGearArrayInd] of LongInt;
        cY: array[0..cMaxGearArrayInd] of LongInt;
        Count: Longword
        end;

type PGearHitOrder = ^TGearHitOrder;
    TGearHitOrder = record
        ar: array[0..cMaxGearHitOrderInd] of PGear;
        order: array[0..cMaxGearHitOrderInd] of LongInt;
        Count: Longword
        end;

type TLineCollision = record
        hasCollision: Boolean;
        cX, cY: LongInt; //for visual effects only
        end;

procedure initModule;
procedure freeModule;

procedure AddCI(Gear: PGear);
procedure DeleteCI(Gear: PGear);

function  CheckGearsCollision(Gear: PGear): PGearArray;
function  CheckAllGearsCollision(SourceGear: PGear): PGearArray;

function  CheckGearsLineCollision(Gear: PGear; oX, oY, tX, tY: hwFloat): PGearArray;
function  CheckAllGearsLineCollision(SourceGear: PGear; oX, oY, tX, tY: hwFloat): PGearArray;

function  UpdateHitOrder(Gear: PGear; Order: LongInt): boolean;
procedure ClearHitOrderLeq(MinOrder: LongInt);
procedure ClearHitOrder();

function  TestCollisionXwithGear(Gear: PGear; Dir: LongInt): Word;
function  TestCollisionYwithGear(Gear: PGear; Dir: LongInt): Word;

function  TestCollisionXKick(Gear: PGear; Dir: LongInt): Word;
function  TestCollisionYKick(Gear: PGear; Dir: LongInt): Word;

function  TestCollisionX(Gear: PGear; Dir: LongInt): Word;
function  TestCollisionY(Gear: PGear; Dir: LongInt): Word;

function  TestCollisionXwithXYShift(Gear: PGear; ShiftX: hwFloat; ShiftY: LongInt; Dir: LongInt): Word; inline;
function  TestCollisionXwithXYShift(Gear: PGear; ShiftX: hwFloat; ShiftY: LongInt; Dir: LongInt; withGear: boolean): Word;
function  TestCollisionYwithXYShift(Gear: PGear; ShiftX, ShiftY: LongInt; Dir: LongInt): Word; inline;
function  TestCollisionYwithXYShift(Gear: PGear; ShiftX, ShiftY: LongInt; Dir: LongInt; withGear: boolean): Word;

function  TestRectangleForObstacle(x1, y1, x2, y2: LongInt; landOnly: boolean): boolean;

function  CheckCoordInWater(X, Y: LongInt): boolean; inline;

// returns: negative sign if going downhill to left, value is steepness (noslope/error = _0, 45 = _0_5)
function  CalcSlopeBelowGear(Gear: PGear): hwFloat;
function  CalcSlopeNearGear(Gear: PGear; dirX, dirY: LongInt): hwFloat;
function  CalcSlopeTangent(Gear: PGear; collisionX, collisionY: LongInt; var outDeltaX, outDeltaY: LongInt; TestWord: LongWord): boolean;

implementation
uses uConsts, uLandGraphics, uVariables;

type TCollisionEntry = record
    X, Y, Radius: LongInt;
    cGear: PGear;
    end;

const MAXRECTSINDEX = 1023;
var Count: Longword;
    cinfos: array[0..MAXRECTSINDEX] of TCollisionEntry;
    ga: TGearArray;
    ordera: TGearHitOrder;

procedure AddCI(Gear: PGear);
begin
if (Gear^.CollisionIndex >= 0) or (Count > MAXRECTSINDEX) or
    ((Count > MAXRECTSINDEX-200) and ((Gear^.Kind = gtMine) or (Gear^.Kind = gtSMine) or (Gear^.Kind = gtKnife))) then
    exit;

with cinfos[Count] do
    begin
    X:= hwRound(Gear^.X);
    Y:= hwRound(Gear^.Y);
    Radius:= Gear^.Radius;
    ChangeRoundInLand(X, Y, Radius - 1, true,  ((CurrentHedgehog <> nil) and (Gear = CurrentHedgehog^.Gear)) or ((Gear^.Kind = gtCase) and (Gear^.State and gstFrozen = 0)), Gear^.Kind = gtHedgehog);
    cGear:= Gear
    end;
Gear^.CollisionIndex:= Count;
inc(Count);
end;

procedure DeleteCI(Gear: PGear);
begin
if Gear^.CollisionIndex >= 0 then
    begin
    with cinfos[Gear^.CollisionIndex] do
        ChangeRoundInLand(X, Y, Radius - 1, false, ((CurrentHedgehog <> nil) and (Gear = CurrentHedgehog^.Gear)) or ((Gear^.Kind = gtCase) and (Gear^.State and gstFrozen = 0)), Gear^.Kind = gtHedgehog);
    cinfos[Gear^.CollisionIndex]:= cinfos[Pred(Count)];
    cinfos[Gear^.CollisionIndex].cGear^.CollisionIndex:= Gear^.CollisionIndex;
    Gear^.CollisionIndex:= -1;
    dec(Count)
    end;
end;

function CheckCoordInWater(X, Y: LongInt): boolean; inline;
begin
    CheckCoordInWater:= (Y > cWaterLine)
        or ((WorldEdge = weSea) and ((X < LongInt(leftX)) or (X > LongInt(rightX))));
end;

function CheckGearsCollision(Gear: PGear): PGearArray;
var mx, my, tr: LongInt;
    i: Longword;
begin
CheckGearsCollision:= @ga;
ga.Count:= 0;
if Count = 0 then
    exit;
mx:= hwRound(Gear^.X);
my:= hwRound(Gear^.Y);

tr:= Gear^.Radius + 2;

for i:= 0 to Pred(Count) do
    with cinfos[i] do
        if (Gear <> cGear) and
            (sqr(mx - x) + sqr(my - y) <= sqr(Radius + tr)) then
                begin
                ga.ar[ga.Count]:= cinfos[i].cGear;
                ga.cX[ga.Count]:= hwround(Gear^.X);
                ga.cY[ga.Count]:= hwround(Gear^.Y);
                inc(ga.Count)
                end
end;

function CheckAllGearsCollision(SourceGear: PGear): PGearArray;
var mx, my, tr: LongInt;
    Gear: PGear;
begin
    CheckAllGearsCollision:= @ga;
    ga.Count:= 0;

    mx:= hwRound(SourceGear^.X);
    my:= hwRound(SourceGear^.Y);

    tr:= SourceGear^.Radius + 2;

    Gear:= GearsList;

    while Gear <> nil do
        begin
            if (Gear <> SourceGear) and
               (sqr(mx - hwRound(Gear^.x)) + sqr(my - hwRound(Gear^.y)) <= sqr(Gear^.Radius + tr))then
            begin
                ga.ar[ga.Count]:= Gear;
                ga.cX[ga.Count]:= hwround(SourceGear^.X);
                ga.cY[ga.Count]:= hwround(SourceGear^.Y);
                inc(ga.Count)
            end;

            Gear := Gear^.NextGear
        end;
end;

function LineCollisionTest(oX, oY, dirX, dirY, dirNormSqr, dirNormBound: hwFloat;
        width: LongInt; Gear: PGear):
    TLineCollision; inline;
var toCenterX, toCenterY, r,
    b, bSqr, c, desc, t: hwFloat;
    realT: extended;
begin
    LineCollisionTest.hasCollision:= false;
    toCenterX:= (oX - Gear^.X);
    toCenterY:= (oY - Gear^.Y);
    r:= int2hwFloat(Gear^.Radius + width + 2);
    // Early cull to avoid multiplying large numbers
    if hwAbs(toCenterX) + hwAbs(toCenterY) > dirNormBound + r then
        exit;
    b:= dirX * toCenterX + dirY * toCenterY;
    c:= hwSqr(toCenterX) + hwSqr(toCenterY) - hwSqr(r);
    if (b > _0) and (c > _0) then
        exit;
    bSqr:= hwSqr(b);
    desc:= bSqr - dirNormSqr * c;
    if desc.isNegative then exit;

    t:= -b - hwSqrt(desc);
    if t.isNegative then t:= _0;
    if t < dirNormSqr then
        with LineCollisionTest do
            begin
            hasCollision:= true;
            realT := hwFloat2Float(t) / hwFloat2Float(dirNormSqr);
            cX:= round(hwFloat2Float(oX) + realT * hwFloat2Float(dirX));
            cY:= round(hwFloat2Float(oY) + realT * hwFloat2Float(dirY));
            end;
end;

function CheckGearsLineCollision(Gear: PGear; oX, oY, tX, tY: hwFloat): PGearArray;
var dirX, dirY, dirNormSqr, dirNormBound: hwFloat;
    test: TLineCollision;
    i: Longword;
begin
    CheckGearsLineCollision:= @ga;
    ga.Count:= 0;
    if Count = 0 then
        exit;
    dirX:= (tX - oX);
    dirY:= (tY - oY);
    dirNormBound:= _1_5 * (hwAbs(dirX) + hwAbs(dirY));
    dirNormSqr:= hwSqr(dirX) + hwSqr(dirY);
    if dirNormSqr.isNegative then
        exit;

    for i:= 0 to Pred(Count) do
        with cinfos[i] do if Gear <> cGear then
            begin
            test:= LineCollisionTest(
                oX, oY, dirX, dirY, dirNormSqr, dirNormBound, Gear^.Radius, cGear);
            if test.hasCollision then
                begin
                ga.ar[ga.Count] := cGear;
                ga.cX[ga.Count] := test.cX;
                ga.cY[ga.Count] := test.cY;
                inc(ga.Count)
                end
            end
end;

function CheckAllGearsLineCollision(SourceGear: PGear; oX, oY, tX, tY: hwFloat): PGearArray;
var dirX, dirY, dirNormSqr, dirNormBound: hwFloat;
    test: TLineCollision;
    Gear: PGear;
begin
    CheckAllGearsLineCollision:= @ga;
    ga.Count:= 0;
    dirX:= (tX - oX);
    dirY:= (tY - oY);
    dirNormBound:= _1_5 * (hwAbs(dirX) + hwAbs(dirY));
    dirNormSqr:= hwSqr(dirX) + hwSqr(dirY);
    if dirNormSqr.isNegative then
        exit;

    Gear:= GearsList;
    while Gear <> nil do
    begin
        if SourceGear <> Gear then
            begin
            test:= LineCollisionTest(
                oX, oY, dirX, dirY, dirNormSqr, dirNormBound, SourceGear^.Radius, Gear);
            if test.hasCollision then
                begin
                ga.ar[ga.Count] := Gear;
                ga.cX[ga.Count] := test.cX;
                ga.cY[ga.Count] := test.cY;
                inc(ga.Count)
                end
            end;
        Gear := Gear^.NextGear
    end;
end;

function UpdateHitOrder(Gear: PGear; Order: LongInt): boolean;
var i: LongInt;
begin
UpdateHitOrder:= true;
for i:= 0 to cMaxGearHitOrderInd do
    if ordera.ar[i] = Gear then
        begin
        if Order <= ordera.order[i] then UpdateHitOrder:= false;
        ordera.order[i]:= Max(ordera.order[i], order);
        exit;
        end;

if ordera.Count > cMaxGearHitOrderInd then
    UpdateHitOrder:= false
else
    begin
    ordera.ar[ordera.Count]:= Gear;
    ordera.order[ordera.Count]:= Order;
    Inc(ordera.Count);
    end
end;

procedure ClearHitOrderLeq(MinOrder: LongInt);
var i, freeIndex: LongInt;
begin;
freeIndex:= 0;
i:= 0;

while i < ordera.Count do
    begin
        if ordera.order[i] <= MinOrder then
            Dec(ordera.Count)
        else
            begin
                if freeIndex < i then
                begin
                ordera.ar[freeIndex]:= ordera.ar[i];
                ordera.order[freeIndex]:= ordera.order[i];
                end;
            Inc(freeIndex);
            end;
        Inc(i)
    end
end;

procedure ClearHitOrder();
begin
    ordera.Count:= 0;
end;

function TestCollisionXwithGear(Gear: PGear; Dir: LongInt): Word;
var x, y, i: LongInt;
begin
// Special case to emulate the old intersect gear clearing, but with a bit of slop for pixel overlap
if (Gear^.CollisionMask = lfNotCurrentMask) and (Gear^.Kind <> gtHedgehog) and (Gear^.Hedgehog <> nil) and (Gear^.Hedgehog^.Gear <> nil) and
    ((hwRound(Gear^.Hedgehog^.Gear^.X) + Gear^.Hedgehog^.Gear^.Radius + 16 < hwRound(Gear^.X) - Gear^.Radius) or
     (hwRound(Gear^.Hedgehog^.Gear^.X) - Gear^.Hedgehog^.Gear^.Radius - 16 > hwRound(Gear^.X) + Gear^.Radius)) then
    Gear^.CollisionMask:= $FFFF;

x:= hwRound(Gear^.X);
if Dir < 0 then
    x:= x - Gear^.Radius
else
    x:= x + Gear^.Radius;

if (x and LAND_WIDTH_MASK) = 0 then
    begin
    y:= hwRound(Gear^.Y) - Gear^.Radius + 1;
    i:= y + Gear^.Radius * 2 - 2;
    repeat
        if (y and LAND_HEIGHT_MASK) = 0 then
            if Land[y, x] and Gear^.CollisionMask <> 0 then
                exit(Land[y, x] and Gear^.CollisionMask);
        inc(y)
    until (y > i);
    end;
TestCollisionXwithGear:= 0
end;

function TestCollisionYwithGear(Gear: PGear; Dir: LongInt): Word;
var x, y, i: LongInt;
begin
// Special case to emulate the old intersect gear clearing, but with a bit of slop for pixel overlap
if (Gear^.CollisionMask = lfNotCurrentMask) and (Gear^.Kind <> gtHedgehog) and (Gear^.Hedgehog <> nil) and (Gear^.Hedgehog^.Gear <> nil) and
    ((hwRound(Gear^.Hedgehog^.Gear^.Y) + Gear^.Hedgehog^.Gear^.Radius + 16 < hwRound(Gear^.Y) - Gear^.Radius) or
     (hwRound(Gear^.Hedgehog^.Gear^.Y) - Gear^.Hedgehog^.Gear^.Radius - 16 > hwRound(Gear^.Y) + Gear^.Radius)) then
    Gear^.CollisionMask:= $FFFF;

y:= hwRound(Gear^.Y);
if Dir < 0 then
    y:= y - Gear^.Radius
else
    y:= y + Gear^.Radius;

if (y and LAND_HEIGHT_MASK) = 0 then
    begin
    x:= hwRound(Gear^.X) - Gear^.Radius + 1;
    i:= x + Gear^.Radius * 2 - 2;
    repeat
        if (x and LAND_WIDTH_MASK) = 0 then
            if Land[y, x] and Gear^.CollisionMask <> 0 then
                begin
                exit(Land[y, x] and Gear^.CollisionMask)
                end;
        inc(x)
    until (x > i);
    end;
TestCollisionYwithGear:= 0
end;

function TestCollisionXKick(Gear: PGear; Dir: LongInt): Word;
var x, y, mx, my, i: LongInt;
    pixel: Word;
begin
pixel:= 0;
x:= hwRound(Gear^.X);
if Dir < 0 then
    x:= x - Gear^.Radius
else
    x:= x + Gear^.Radius;

if (x and LAND_WIDTH_MASK) = 0 then
    begin
    y:= hwRound(Gear^.Y) - Gear^.Radius + 1;
    i:= y + Gear^.Radius * 2 - 2;
    repeat
        if (y and LAND_HEIGHT_MASK) = 0 then
            begin
            if Land[y, x] and Gear^.CollisionMask <> 0 then
                begin
                if Land[y, x] and Gear^.CollisionMask > 255 then
                    exit(Land[y, x] and Gear^.CollisionMask)
                else
                    pixel:= Land[y, x] and Gear^.CollisionMask;
                end;
            end;
    inc(y)
    until (y > i);
    end;
TestCollisionXKick:= pixel;

if pixel <> 0 then
    begin
    if hwAbs(Gear^.dX) < cHHKick then
        exit;
    if (Gear^.State and gstHHJumping <> 0)
    and (hwAbs(Gear^.dX) < _0_4) then
        exit;

    mx:= hwRound(Gear^.X);
    my:= hwRound(Gear^.Y);

    for i:= 0 to Pred(Count) do
        with cinfos[i] do
            if  (Gear <> cGear) and
                ((mx > x) xor (Dir > 0)) and
                (
                  ((cGear^.Kind in [gtHedgehog, gtMine, gtKnife]) and ((Gear^.State and gstNotKickable) = 0)) or
                // only apply X kick if the barrel is knocked over
                  ((cGear^.Kind = gtExplosives) and ((cGear^.State and gsttmpflag) <> 0))
                ) and
                (sqr(mx - x) + sqr(my - y) <= sqr(Radius + Gear^.Radius + 2)) then
                    begin
                    with cGear^ do
                        begin
                        dX:= Gear^.dX;
                        dY:= Gear^.dY * _0_5;
                        State:= State or gstMoving;
                        if Kind = gtKnife then State:= State and (not gstCollision);
                        Active:= true
                        end;
                    DeleteCI(cGear);
                    exit(0);
                    end
    end
end;

function TestCollisionYKick(Gear: PGear; Dir: LongInt): Word;
var x, y, mx, my,  myr, i: LongInt;
    pixel: Word;
begin
pixel:= 0;
y:= hwRound(Gear^.Y);
if Dir < 0 then
    y:= y - Gear^.Radius
else
    y:= y + Gear^.Radius;

if (y and LAND_HEIGHT_MASK) = 0 then
    begin
    x:= hwRound(Gear^.X) - Gear^.Radius + 1;
    i:= x + Gear^.Radius * 2 - 2;
    repeat
    if (x and LAND_WIDTH_MASK) = 0 then
        if Land[y, x] > 0 then
            begin
            if Land[y, x] and Gear^.CollisionMask > 255 then
                exit(Land[y, x] and Gear^.CollisionMask)
            else // if Land[y, x] <> 0 then
                pixel:= Land[y, x] and Gear^.CollisionMask;
            end;
    inc(x)
    until (x > i);
    end;
TestCollisionYKick:= pixel;

if pixel <> 0 then
    begin
    if hwAbs(Gear^.dY) < cHHKick then
        exit;
    if (Gear^.State and gstHHJumping <> 0) and (not Gear^.dY.isNegative) and (Gear^.dY < _0_4) then
        exit;

    mx:= hwRound(Gear^.X);
    my:= hwRound(Gear^.Y);
    myr:= my+Gear^.Radius;

    for i:= 0 to Pred(Count) do
        with cinfos[i] do
            if (Gear <> cGear) and
               ((myr > y) xor (Dir > 0)) and
               (Gear^.State and gstNotKickable = 0) and
               (cGear^.Kind in [gtHedgehog, gtMine, gtKnife, gtExplosives]) and
               (sqr(mx - x) + sqr(my - y) <= sqr(Radius + Gear^.Radius + 2)) then
                    begin
                    with cGear^ do
                        begin
                        if (Kind <> gtExplosives) or ((State and gsttmpflag) <> 0) then
                            dX:= Gear^.dX * _0_5;
                        dY:= Gear^.dY;
                        State:= State or gstMoving;
                        if Kind = gtKnife then State:= State and (not gstCollision);
                        Active:= true
                        end;
                    DeleteCI(cGear);
                    exit(0)
                    end
    end
end;

function TestCollisionXwithXYShift(Gear: PGear; ShiftX: hwFloat; ShiftY: LongInt; Dir: LongInt): Word; inline;
begin
    TestCollisionXwithXYShift:= TestCollisionXwithXYShift(Gear, ShiftX, ShiftY, Dir, true);
end;

function TestCollisionXwithXYShift(Gear: PGear; ShiftX: hwFloat; ShiftY: LongInt; Dir: LongInt; withGear: boolean): Word;
begin
Gear^.X:= Gear^.X + ShiftX;
Gear^.Y:= Gear^.Y + int2hwFloat(ShiftY);
if withGear then
    TestCollisionXwithXYShift:= TestCollisionXwithGear(Gear, Dir)
else TestCollisionXwithXYShift:= TestCollisionX(Gear, Dir);
Gear^.X:= Gear^.X - ShiftX;
Gear^.Y:= Gear^.Y - int2hwFloat(ShiftY)
end;

function TestCollisionX(Gear: PGear; Dir: LongInt): Word;
var x, y, i: LongInt;
begin
x:= hwRound(Gear^.X);
if Dir < 0 then
    x:= x - Gear^.Radius
else
    x:= x + Gear^.Radius;

if (x and LAND_WIDTH_MASK) = 0 then
    begin
    y:= hwRound(Gear^.Y) - Gear^.Radius + 1;
    i:= y + Gear^.Radius * 2 - 2;
    repeat
        if (y and LAND_HEIGHT_MASK) = 0 then
            if Land[y, x] and Gear^.CollisionMask > 255 then
                exit(Land[y, x] and Gear^.CollisionMask);
    inc(y)
    until (y > i);
    end;
TestCollisionX:= 0
end;

function TestCollisionY(Gear: PGear; Dir: LongInt): Word;
var x, y, i: LongInt;
begin
y:= hwRound(Gear^.Y);
if Dir < 0 then
    y:= y - Gear^.Radius
else
    y:= y + Gear^.Radius;

if (y and LAND_HEIGHT_MASK) = 0 then
    begin
    x:= hwRound(Gear^.X) - Gear^.Radius + 1;
    i:= x + Gear^.Radius * 2 - 2;
    repeat
        if (x and LAND_WIDTH_MASK) = 0 then
            if Land[y, x] and Gear^.CollisionMask > 255 then
                exit(Land[y, x] and Gear^.CollisionMask);
    inc(x)
    until (x > i);
    end;
TestCollisionY:= 0
end;

function TestCollisionYwithXYShift(Gear: PGear; ShiftX, ShiftY: LongInt; Dir: LongInt): Word; inline;
begin
    TestCollisionYwithXYShift:= TestCollisionYwithXYShift(Gear, ShiftX, ShiftY, Dir, true);
end;

function TestCollisionYwithXYShift(Gear: PGear; ShiftX, ShiftY: LongInt; Dir: LongInt; withGear: boolean): Word;
begin
Gear^.X:= Gear^.X + int2hwFloat(ShiftX);
Gear^.Y:= Gear^.Y + int2hwFloat(ShiftY);

if withGear then
  TestCollisionYwithXYShift:= TestCollisionYwithGear(Gear, Dir)
else
  TestCollisionYwithXYShift:= TestCollisionY(Gear, Dir);

Gear^.X:= Gear^.X - int2hwFloat(ShiftX);
Gear^.Y:= Gear^.Y - int2hwFloat(ShiftY)
end;

function TestRectangleForObstacle(x1, y1, x2, y2: LongInt; landOnly: boolean): boolean;
var x, y: LongInt;
    TestWord: LongWord;
begin
TestRectangleForObstacle:= true;

if landOnly then
    TestWord:= 255
else
    TestWord:= 0;

if x1 > x2 then
begin
    x  := x1;
    x1 := x2;
    x2 := x;
end;

if y1 > y2 then
begin
    y  := y1;
    y1 := y2;
    y2 := y;
end;

if (hasBorder and ((y1 < 0) or (x1 < 0) or (x2 > LAND_WIDTH))) then
    exit;

for y := y1 to y2 do
    for x := x1 to x2 do
        if ((y and LAND_HEIGHT_MASK) = 0) and ((x and LAND_WIDTH_MASK) = 0) and (Land[y, x] > TestWord) then
            exit;

TestRectangleForObstacle:= false
end;

function CalcSlopeTangent(Gear: PGear; collisionX, collisionY: LongInt; var outDeltaX, outDeltaY: LongInt; TestWord: LongWord): boolean;
var ldx, ldy, rdx, rdy: LongInt;
    i, j, k, mx, my, li, ri, jfr, jto, tmpo : ShortInt;
    tmpx, tmpy: LongWord;
    dx, dy, s: hwFloat;
    offset: array[0..7,0..1] of ShortInt;
    isColl: Boolean;

begin
    CalcSlopeTangent:= false;

    dx:= Gear^.dX;
    dy:= Gear^.dY;

    // we start searching from the direction the gear came from
    if (dx.QWordValue > _0_995.QWordValue )
    or (dy.QWordValue > _0_995.QWordValue ) then
        begin // scale
        s := _0_995 / Distance(dx,dy);
        dx := s * dx;
        dy := s * dy;
        end;

    mx:= hwRound(Gear^.X-dx) - hwRound(Gear^.X);
    my:= hwRound(Gear^.Y-dy) - hwRound(Gear^.Y);

    li:= -1;
    ri:= -1;

    // go around collision pixel, checking for first/last collisions
    // this will determinate what angles will be tried to crawl along
    for i:= 0 to 7 do
        begin
        offset[i,0]:= mx;
        offset[i,1]:= my;

        // multiplicator k tries to skip small pixels/gaps when possible
        for k:= 4 downto 1 do
            begin
            tmpx:= collisionX + k * mx;
            tmpy:= collisionY + k * my;

            if (((tmpy) and LAND_HEIGHT_MASK) = 0) and (((tmpx) and LAND_WIDTH_MASK) = 0) then
                if (Land[tmpy,tmpx] > TestWord) then
                    begin
                    // remember the index belonging to the first and last collision (if in 1st half)
                    if (i <> 0) then
                        begin
                        if (ri = -1) then
                            ri:= i
                        else
                            li:= i;
                        end;
                    end;
            end;

        if i = 7 then
            break;

        // prepare offset for next check (clockwise)
        if (mx = -1) and (my <> -1) then
            my:= my - 1
        else if (my = -1) and (mx <> 1) then
            mx:= mx + 1
        else if (mx = 1) and (my <> 1) then
            my:= my + 1
        else
            mx:= mx - 1;

        end;

    ldx:= collisionX;
    ldy:= collisionY;
    rdx:= collisionX;
    rdy:= collisionY;

    // edge-crawl
    for i:= 0 to 8 do
        begin
        // using mx,my as temporary value buffer here

        jfr:= 8+li+1;
        jto:= 8+li-1;

        isColl:= false;
        for j:= jfr downto jto do
            begin
            tmpo:= j mod 8;
            // multiplicator k tries to skip small pixels/gaps when possible
            for k:= 3 downto 1 do
                begin
                tmpx:= ldx + k * offset[tmpo,0];
                tmpy:= ldy + k * offset[tmpo,1];
                if (((tmpy) and LAND_HEIGHT_MASK) = 0) and (((tmpx) and LAND_WIDTH_MASK)  = 0)
                and (Land[tmpy,tmpx] > TestWord) then
                    begin
                    ldx:= tmpx;
                    ldy:= tmpy;
                    isColl:= true;
                    break;
                    end;
                end;
            if isColl then
                break;
            end;

        jfr:= 8+ri-1;
        jto:= 8+ri+1;

        isColl:= false;
        for j:= jfr to jto do
            begin
            tmpo:= j mod 8;
            for k:= 3 downto 1 do
                begin
                tmpx:= rdx + k * offset[tmpo,0];
                tmpy:= rdy + k * offset[tmpo,1];
                if (((tmpy) and LAND_HEIGHT_MASK) = 0) and (((tmpx) and LAND_WIDTH_MASK)  = 0)
                and (Land[tmpy,tmpx] > TestWord) then
                    begin
                    rdx:= tmpx;
                    rdy:= tmpy;
                    isColl:= true;
                    break;
                    end;
                end;
            if isColl then
                break;
            end;
        end;

    ldx:= rdx - ldx;
    ldy:= rdy - ldy;

    if ((ldx = 0) and (ldy = 0)) then
        exit;

outDeltaX:= ldx;
outDeltaY:= ldy;
CalcSlopeTangent:= true;
end;

function CalcSlopeNearGear(Gear: PGear; dirX, dirY: LongInt): hwFloat;
var dx, dy: hwFloat;
    collX, collY, i, y, x, gx, gy, sdx, sdy: LongInt;
    isColl, bSucc: Boolean;
begin

if dirY <> 0 then
    begin
    y:= hwRound(Gear^.Y) + Gear^.Radius * dirY;
    gx:= hwRound(Gear^.X);
    collX := gx;
    isColl:= false;

    if (y and LAND_HEIGHT_MASK) = 0 then
        begin
        x:= hwRound(Gear^.X) - Gear^.Radius + 1;
        i:= x + Gear^.Radius * 2 - 2;
        repeat
        if (x and LAND_WIDTH_MASK) = 0 then
            if Land[y, x] <> 0 then
                if (not isColl) or (abs(x-gx) < abs(collX-gx)) then
                    begin
                    isColl:= true;
                    collX := x;
                    end;
        inc(x)
        until (x > i);
        end;
    end
else
    begin
    x:= hwRound(Gear^.X) + Gear^.Radius * dirX;
    gy:= hwRound(Gear^.Y);
    collY := gy;
    isColl:= false;

    if (x and LAND_WIDTH_MASK) = 0 then
        begin
        y:= hwRound(Gear^.Y) - Gear^.Radius + 1;
        i:= y + Gear^.Radius * 2 - 2;
        repeat
        if (y and LAND_HEIGHT_MASK) = 0 then
            if Land[y, x] <> 0 then
                if (not isColl) or (abs(y-gy) < abs(collY-gy)) then
                    begin
                    isColl:= true;
                    collY := y;
                    end;
        inc(y)
        until (y > i);
        end;
    end;

if isColl then
    begin
    // save original dx/dy
    dx := Gear^.dX;
    dy := Gear^.dY;

    if dirY <> 0 then
        begin
        Gear^.dX.QWordValue:= 0;
        Gear^.dX.isNegative:= (collX >= gx);
        Gear^.dY:= _1*dirY
        end
    else
        begin
        Gear^.dY.QWordValue:= 0;
        Gear^.dY.isNegative:= (collY >= gy);
        Gear^.dX:= _1*dirX
        end;

    sdx:= 0;
    sdy:= 0;
    if dirY <> 0 then
         bSucc := CalcSlopeTangent(Gear, collX, y, sdx, sdy, 0)
    else bSucc := CalcSlopeTangent(Gear, x, collY, sdx, sdy, 0);

    // restore original dx/dy
    Gear^.dX := dx;
    Gear^.dY := dy;

    if bSucc and ((sdx <> 0) or (sdy <> 0)) then
        begin
        dx := int2hwFloat(sdy) / (abs(sdx) + abs(sdy));
        dx.isNegative := (sdx * sdy) < 0;
        exit (dx);
        end
    end;

CalcSlopeNearGear := _0;
end;

function CalcSlopeBelowGear(Gear: PGear): hwFloat;
var dx, dy: hwFloat;
    collX, i, y, x, gx, sdx, sdy: LongInt;
    isColl, bSucc: Boolean;
begin


y:= hwRound(Gear^.Y) + Gear^.Radius;
gx:= hwRound(Gear^.X);
collX := gx;
isColl:= false;

if (y and LAND_HEIGHT_MASK) = 0 then
    begin
    x:= hwRound(Gear^.X) - Gear^.Radius + 1;
    i:= x + Gear^.Radius * 2 - 2;
    repeat
    if (x and LAND_WIDTH_MASK) = 0 then
        if Land[y, x] > 255 then
            if (not isColl) or (abs(x-gx) < abs(collX-gx)) then
                begin
                isColl:= true;
                collX := x;
                end;
    inc(x)
    until (x > i);
    end;

if isColl then
    begin
    // save original dx/dy
    dx := Gear^.dX;
    dy := Gear^.dY;

    Gear^.dX.QWordValue:= 0;
    Gear^.dX.isNegative:= (collX >= gx);
    Gear^.dY:= _1;

    sdx:= 0;
    sdy:= 0;
    bSucc := CalcSlopeTangent(Gear, collX, y, sdx, sdy, 255);

    // restore original dx/dy
    Gear^.dX := dx;
    Gear^.dY := dy;

    if bSucc and (sdx <> 0) and (sdy <> 0) then
    begin
        dx := int2hwFloat(sdy) / (abs(sdx) + abs(sdy));
        dx.isNegative := (sdx * sdy) < 0;
        exit (dx);
    end;
    end;

CalcSlopeBelowGear := _0;
end;

procedure initModule;
begin
    Count:= 0;
end;

procedure freeModule;
begin

end;

end.
