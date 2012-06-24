(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uCollisions;
interface
uses uFloat, uTypes;

const cMaxGearArrayInd = 1023;

type PGearArray = ^TGearArray;
    TGearArray = record
        ar: array[0..cMaxGearArrayInd] of PGear;
        Count: Longword
        end;

procedure initModule;
procedure freeModule;

procedure AddGearCI(Gear: PGear);
procedure DeleteCI(Gear: PGear);

function  CheckGearsCollision(Gear: PGear): PGearArray;

function  TestCollisionXwithGear(Gear: PGear; Dir: LongInt): boolean;
function  TestCollisionYwithGear(Gear: PGear; Dir: LongInt): Word;

function  TestCollisionXKick(Gear: PGear; Dir: LongInt): boolean;
function  TestCollisionYKick(Gear: PGear; Dir: LongInt): boolean;

function  TestCollisionX(Gear: PGear; Dir: LongInt): boolean;
function  TestCollisionY(Gear: PGear; Dir: LongInt): boolean;

function  TestCollisionXwithXYShift(Gear: PGear; ShiftX: hwFloat; ShiftY: LongInt; Dir: LongInt): boolean; inline;
function  TestCollisionXwithXYShift(Gear: PGear; ShiftX: hwFloat; ShiftY: LongInt; Dir: LongInt; withGear: boolean): boolean;
function  TestCollisionYwithXYShift(Gear: PGear; ShiftX, ShiftY: LongInt; Dir: LongInt): boolean; inline;
function  TestCollisionYwithXYShift(Gear: PGear; ShiftX, ShiftY: LongInt; Dir: LongInt; withGear: boolean): boolean;

function  TestRectancleForObstacle(x1, y1, x2, y2: LongInt; landOnly: boolean): boolean;

// returns: negative sign if going downhill to left, value is steepness (noslope/error = _0, 45° = _0_5)
function  CalcSlopeBelowGear(Gear: PGear): hwFloat;
function  CalcSlopeTangent(Gear: PGear; collisionX, collisionY: LongInt; var outDeltaX, outDeltaY: LongInt; TestWord: LongWord): Boolean;

implementation
uses uConsts, uLandGraphics, uVariables, uDebug, uGearsList;

type TCollisionEntry = record
    X, Y, Radius: LongInt;
    cGear: PGear;
    end;

const MAXRECTSINDEX = 1023;
var Count: Longword;
    cinfos: array[0..MAXRECTSINDEX] of TCollisionEntry;
    ga: TGearArray;

procedure AddGearCI(Gear: PGear);
var t: PGear;
begin
if Gear^.CollisionIndex >= 0 then
    exit;
TryDo(Count <= MAXRECTSINDEX, 'Collision rects array overflow', true);
with cinfos[Count] do
    begin
    X:= hwRound(Gear^.X);
    Y:= hwRound(Gear^.Y);
    Radius:= Gear^.Radius;
    ChangeRoundInLand(X, Y, Radius - 1, true, Gear = CurrentHedgehog^.Gear);
    cGear:= Gear
    end;
Gear^.CollisionIndex:= Count;
inc(Count);
// mines are the easiest way to overflow collision
if (Count > (MAXRECTSINDEX-20)) then
    begin
    t:= GearsList;
    while (t <> nil) and (t^.Kind <> gtMine) do 
        t:= t^.NextGear;
    if (t <> nil) then
        DeleteGear(t)
    end;
end;

procedure DeleteCI(Gear: PGear);
begin
if Gear^.CollisionIndex >= 0 then
    begin
    with cinfos[Gear^.CollisionIndex] do
        ChangeRoundInLand(X, Y, Radius - 1, false, Gear = CurrentHedgehog^.Gear);
    cinfos[Gear^.CollisionIndex]:= cinfos[Pred(Count)];
    cinfos[Gear^.CollisionIndex].cGear^.CollisionIndex:= Gear^.CollisionIndex;
    Gear^.CollisionIndex:= -1;
    dec(Count)
    end;
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
                inc(ga.Count)
                end
end;

function TestCollisionXwithGear(Gear: PGear; Dir: LongInt): boolean;
var x, y, i: LongInt;
    TestWord: LongWord;
begin
// Special case to emulate the old intersect gear clearing, but with a bit of slop for pixel overlap
if (Gear^.CollisionMask = $FF7F) and (Gear^.Hedgehog <> nil) and (Gear^.Hedgehog^.Gear <> nil) and
    ((hwRound(Gear^.Hedgehog^.Gear^.X) + Gear^.Hedgehog^.Gear^.Radius + 4 < hwRound(Gear^.X) - Gear^.Radius) or
     (hwRound(Gear^.Hedgehog^.Gear^.X) - Gear^.Hedgehog^.Gear^.Radius - 4 > hwRound(Gear^.X) + Gear^.Radius)) then
    Gear^.CollisionMask:= $FFFF;

x:= hwRound(Gear^.X);
if Dir < 0 then
    x:= x - Gear^.Radius
else
    x:= x + Gear^.Radius;

TestCollisionXwithGear:= true;
if (x and LAND_WIDTH_MASK) = 0 then
    begin
    y:= hwRound(Gear^.Y) - Gear^.Radius + 1;
    i:= y + Gear^.Radius * 2 - 2;
    repeat
        if (y and LAND_HEIGHT_MASK) = 0 then
            if Land[y, x] and Gear^.CollisionMask <> 0 then
                exit;
        inc(y)
    until (y > i);
    end;
TestCollisionXwithGear:= false
end;

function TestCollisionYwithGear(Gear: PGear; Dir: LongInt): Word;
var x, y, i: LongInt;
    TestWord: LongWord;
begin
// Special case to emulate the old intersect gear clearing, but with a bit of slop for pixel overlap
if (Gear^.CollisionMask = $FF7F) and (Gear^.Hedgehog <> nil) and (Gear^.Hedgehog^.Gear <> nil) and
    ((hwRound(Gear^.Hedgehog^.Gear^.Y) + Gear^.Hedgehog^.Gear^.Radius + 4 < hwRound(Gear^.Y) - Gear^.Radius) or
     (hwRound(Gear^.Hedgehog^.Gear^.Y) - Gear^.Hedgehog^.Gear^.Radius - 4 > hwRound(Gear^.Y) + Gear^.Radius)) then
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
                TestCollisionYwithGear:= Land[y, x];
                exit;
                end;
        inc(x)
    until (x > i);
    end;
TestCollisionYwithGear:= 0
end;

function TestCollisionXKick(Gear: PGear; Dir: LongInt): boolean;
var x, y, mx, my, i: LongInt;
    flag: boolean;
begin
flag:= false;
x:= hwRound(Gear^.X);
if Dir < 0 then
    x:= x - Gear^.Radius
else
    x:= x + Gear^.Radius;

TestCollisionXKick:= true;
if (x and LAND_WIDTH_MASK) = 0 then
    begin
    y:= hwRound(Gear^.Y) - Gear^.Radius + 1;
    i:= y + Gear^.Radius * 2 - 2;
    repeat
        if (y and LAND_HEIGHT_MASK) = 0 then
            if Land[y, x] > 255 then
                exit
            else if Land[y, x] <> 0 then
                flag:= true;
    inc(y)
    until (y > i);
    end;
TestCollisionXKick:= flag;

if flag then
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
            if (Gear <> cGear) and (sqr(mx - x) + sqr(my - y) <= sqr(Radius + Gear^.Radius + 2))
            and ((mx > x) xor (Dir > 0)) then
                if ((cGear^.Kind in [gtHedgehog, gtMine]) and ((Gear^.State and gstNotKickable) = 0)) or
                // only apply X kick if the barrel is knocked over
                ((cGear^.Kind = gtExplosives) and ((cGear^.State and gsttmpflag) <> 0)) then
                    begin
                    with cGear^ do
                        begin
                        dX:= Gear^.dX;
                        dY:= Gear^.dY * _0_5;
                        State:= State or gstMoving;
                        Active:= true
                        end;
                    DeleteCI(cGear);
                    TestCollisionXKick:= false;
                    exit;
                    end
    end
end;

function TestCollisionYKick(Gear: PGear; Dir: LongInt): boolean;
var x, y, mx, my, i: LongInt;
    flag: boolean;
begin
flag:= false;
y:= hwRound(Gear^.Y);
if Dir < 0 then
    y:= y - Gear^.Radius
else
    y:= y + Gear^.Radius;

TestCollisionYKick:= true;
if (y and LAND_HEIGHT_MASK) = 0 then
    begin
    x:= hwRound(Gear^.X) - Gear^.Radius + 1;
    i:= x + Gear^.Radius * 2 - 2;
    repeat
    if (x and LAND_WIDTH_MASK) = 0 then
        if Land[y, x] > 0 then
            if Land[y, x] > 255 then
                exit
            else if Land[y, x] <> 0 then
                flag:= true;
    inc(x)
    until (x > i);
    end;
TestCollisionYKick:= flag;

if flag then
    begin
    if hwAbs(Gear^.dY) < cHHKick then
        exit;
    if (Gear^.State and gstHHJumping <> 0) and (not Gear^.dY.isNegative) and (Gear^.dY < _0_4) then
        exit;

    mx:= hwRound(Gear^.X);
    my:= hwRound(Gear^.Y);

    for i:= 0 to Pred(Count) do
        with cinfos[i] do
            if (Gear <> cGear) and (sqr(mx - x) + sqr(my - y) <= sqr(Radius + Gear^.Radius + 2))
            and ((my > y) xor (Dir > 0)) then
                if (cGear^.Kind in [gtHedgehog, gtMine, gtExplosives]) and ((Gear^.State and gstNotKickable) = 0) then
                    begin
                    with cGear^ do
                        begin
                        if (Kind <> gtExplosives) or ((State and gsttmpflag) <> 0) then
                            dX:= Gear^.dX * _0_5;
                        dY:= Gear^.dY;
                        State:= State or gstMoving;
                        Active:= true
                        end;
                    DeleteCI(cGear);
                    TestCollisionYKick:= false;
                    exit
                    end
    end
end;

function TestCollisionXwithXYShift(Gear: PGear; ShiftX: hwFloat; ShiftY: LongInt; Dir: LongInt): boolean; inline;
begin
    TestCollisionXwithXYShift:= TestCollisionXwithXYShift(Gear, ShiftX, ShiftY, Dir, true);
end;

function TestCollisionXwithXYShift(Gear: PGear; ShiftX: hwFloat; ShiftY: LongInt; Dir: LongInt; withGear: boolean): boolean;
begin
Gear^.X:= Gear^.X + ShiftX;
Gear^.Y:= Gear^.Y + int2hwFloat(ShiftY);
if withGear then 
    TestCollisionXwithXYShift:= TestCollisionXwithGear(Gear, Dir)
else TestCollisionXwithXYShift:= TestCollisionX(Gear, Dir);
Gear^.X:= Gear^.X - ShiftX;
Gear^.Y:= Gear^.Y - int2hwFloat(ShiftY)
end;

function TestCollisionX(Gear: PGear; Dir: LongInt): boolean;
var x, y, i: LongInt;
begin
x:= hwRound(Gear^.X);
if Dir < 0 then
    x:= x - Gear^.Radius
else
    x:= x + Gear^.Radius;

TestCollisionX:= true;
if (x and LAND_WIDTH_MASK) = 0 then
    begin
    y:= hwRound(Gear^.Y) - Gear^.Radius + 1;
    i:= y + Gear^.Radius * 2 - 2;
    repeat
        if (y and LAND_HEIGHT_MASK) = 0 then
            if Land[y, x] > 255 then
                exit;
    inc(y)
    until (y > i);
    end;
TestCollisionX:= false
end;

function TestCollisionY(Gear: PGear; Dir: LongInt): boolean;
var x, y, i: LongInt;
begin
y:= hwRound(Gear^.Y);
if Dir < 0 then
    y:= y - Gear^.Radius
else
    y:= y + Gear^.Radius;

TestCollisionY:= true;
if (y and LAND_HEIGHT_MASK) = 0 then
    begin
    x:= hwRound(Gear^.X) - Gear^.Radius + 1;
    i:= x + Gear^.Radius * 2 - 2;
    repeat
        if (x and LAND_WIDTH_MASK) = 0 then
            if Land[y, x] > 255 then
                exit;
    inc(x)
    until (x > i);
    end;
TestCollisionY:= false
end;

function TestCollisionYwithXYShift(Gear: PGear; ShiftX, ShiftY: LongInt; Dir: LongInt): boolean; inline;
begin
    TestCollisionYwithXYShift:= TestCollisionYwithXYShift(Gear, ShiftX, ShiftY, Dir, true);
end;

function TestCollisionYwithXYShift(Gear: PGear; ShiftX, ShiftY: LongInt; Dir: LongInt; withGear: boolean): boolean;
begin
Gear^.X:= Gear^.X + int2hwFloat(ShiftX);
Gear^.Y:= Gear^.Y + int2hwFloat(ShiftY);

if withGear then
  TestCollisionYwithXYShift:= TestCollisionYwithGear(Gear, Dir) <> 0
else
  TestCollisionYwithXYShift:= TestCollisionY(Gear, Dir);
  
Gear^.X:= Gear^.X - int2hwFloat(ShiftX);
Gear^.Y:= Gear^.Y - int2hwFloat(ShiftY)
end;

function TestRectancleForObstacle(x1, y1, x2, y2: LongInt; landOnly: boolean): boolean;
var x, y: LongInt;
    TestWord: LongWord;
begin
TestRectancleForObstacle:= true;

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

TestRectancleForObstacle:= false
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
            if not isColl or (abs(x-gx) < abs(collX-gx)) then
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
