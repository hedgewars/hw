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

unit uCollisions;
interface
uses uFloat, uTypes;

const cMaxGearArrayInd = 255;

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
function  TestCollisionYwithGear(Gear: PGear; Dir: LongInt): boolean;

function  TestCollisionXKick(Gear: PGear; Dir: LongInt): boolean;
function  TestCollisionYKick(Gear: PGear; Dir: LongInt): boolean;

function  TestCollisionY(Gear: PGear; Dir: LongInt): boolean;

function  TestCollisionXwithXYShift(Gear: PGear; ShiftX: hwFloat; ShiftY: LongInt; Dir: LongInt): boolean;
function  TestCollisionYwithXYShift(Gear: PGear; ShiftX, ShiftY: LongInt; Dir: LongInt): boolean;

function  calcSlopeTangent(Gear: PGear; collisionX, collisionY: LongInt; var outDeltaX, outDeltaY: LongInt; TestWord: LongWord): Boolean;

implementation
uses uConsts, uLandGraphics, uVariables, uIO;

type TCollisionEntry = record
            X, Y, Radius: LongInt;
            cGear: PGear;
            end;

const MAXRECTSINDEX = 511;
var Count: Longword;
    cinfos: array[0..MAXRECTSINDEX] of TCollisionEntry;
    ga: TGearArray;

procedure AddGearCI(Gear: PGear);
begin
if Gear^.CollisionIndex >= 0 then exit;
TryDo(Count <= MAXRECTSINDEX, 'Collision rects array overflow', true);
with cinfos[Count] do
    begin
    X:= hwRound(Gear^.X);
    Y:= hwRound(Gear^.Y);
    Radius:= Gear^.Radius;
    ChangeRoundInLand(X, Y, Radius - 1, true);
    cGear:= Gear
    end;
Gear^.CollisionIndex:= Count;
inc(Count)
end;

procedure DeleteCI(Gear: PGear);
begin
if Gear^.CollisionIndex >= 0 then
    begin
    with cinfos[Gear^.CollisionIndex] do
        ChangeRoundInLand(X, Y, Radius - 1, false);
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
if Count = 0 then exit;
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
if Gear^.IntersectGear <> nil then
   with Gear^ do
        if (hwRound(IntersectGear^.X) + IntersectGear^.Radius < hwRound(X) - Radius) or
           (hwRound(IntersectGear^.X) - IntersectGear^.Radius > hwRound(X) + Radius) then
           begin
           IntersectGear:= nil;
           TestWord:= 0
           end else
           TestWord:= 255
   else TestWord:= 0;

x:= hwRound(Gear^.X);
if Dir < 0 then x:= x - Gear^.Radius
           else x:= x + Gear^.Radius;
if (x and LAND_WIDTH_MASK) = 0 then
   begin
   y:= hwRound(Gear^.Y) - Gear^.Radius + 1;
   i:= y + Gear^.Radius * 2 - 2;
   repeat
     if (y and LAND_HEIGHT_MASK) = 0 then
        if Land[y, x] > TestWord then exit(true);
     inc(y)
   until (y > i);
   end;
TestCollisionXwithGear:= false
end;

function TestCollisionYwithGear(Gear: PGear; Dir: LongInt): boolean;
var x, y, i: LongInt;
    TestWord: LongWord;
begin
if Gear^.IntersectGear <> nil then
   with Gear^ do
        if (hwRound(IntersectGear^.Y) + IntersectGear^.Radius < hwRound(Y) - Radius) or
           (hwRound(IntersectGear^.Y) - IntersectGear^.Radius > hwRound(Y) + Radius) then
           begin
           IntersectGear:= nil;
           TestWord:= 0
           end else
           TestWord:= 255
   else TestWord:= 0;

y:= hwRound(Gear^.Y);
if Dir < 0 then y:= y - Gear^.Radius
           else y:= y + Gear^.Radius;
if (y and LAND_HEIGHT_MASK) = 0 then
   begin
   x:= hwRound(Gear^.X) - Gear^.Radius + 1;
   i:= x + Gear^.Radius * 2 - 2;
   repeat
     if (x and LAND_WIDTH_MASK) = 0 then
        if Land[y, x] > TestWord then exit(true);
     inc(x)
   until (x > i);
   end;
TestCollisionYwithGear:= false
end;

function TestCollisionXKick(Gear: PGear; Dir: LongInt): boolean;
var x, y, mx, my, i: LongInt;
    flag: boolean;
begin
flag:= false;
x:= hwRound(Gear^.X);
if Dir < 0 then x:= x - Gear^.Radius
           else x:= x + Gear^.Radius;
if (x and LAND_WIDTH_MASK) = 0 then
   begin
   y:= hwRound(Gear^.Y) - Gear^.Radius + 1;
   i:= y + Gear^.Radius * 2 - 2;
   repeat
     if (y and LAND_HEIGHT_MASK) = 0 then
           if Land[y, x] > 255 then exit(true)
           else if Land[y, x] <> 0 then flag:= true;
     inc(y)
   until (y > i);
   end;
TestCollisionXKick:= flag;

if flag then
   begin
   if hwAbs(Gear^.dX) < cHHKick then exit;
   if (Gear^.State and gstHHJumping <> 0)
   and (hwAbs(Gear^.dX) < _0_4) then exit;

   mx:= hwRound(Gear^.X);
   my:= hwRound(Gear^.Y);

   for i:= 0 to Pred(Count) do
    with cinfos[i] do
      if (Gear <> cGear) and
         (sqr(mx - x) + sqr(my - y) <= sqr(Radius + Gear^.Radius + 2)) and
         ((mx > x) xor (Dir > 0)) then
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
             exit(false)
             end
   end
end;

function TestCollisionYKick(Gear: PGear; Dir: LongInt): boolean;
var x, y, mx, my, i: LongInt;
    flag: boolean;
begin
flag:= false;
y:= hwRound(Gear^.Y);
if Dir < 0 then y:= y - Gear^.Radius
           else y:= y + Gear^.Radius;
if (y and LAND_HEIGHT_MASK) = 0 then
   begin
   x:= hwRound(Gear^.X) - Gear^.Radius + 1;
   i:= x + Gear^.Radius * 2 - 2;
   repeat
     if (x and LAND_WIDTH_MASK) = 0 then
        if Land[y, x] > 0 then
           if Land[y, x] > 255 then exit(true)
           else if Land[y, x] <> 0 then flag:= true;
     inc(x)
   until (x > i);
   end;
TestCollisionYKick:= flag;

if flag then
   begin
   if hwAbs(Gear^.dY) < cHHKick then exit(true);
   if (Gear^.State and gstHHJumping <> 0)
   and (not Gear^.dY.isNegative)
   and (Gear^.dY < _0_4) then exit;

   mx:= hwRound(Gear^.X);
   my:= hwRound(Gear^.Y);

   for i:= 0 to Pred(Count) do
    with cinfos[i] do
      if (Gear <> cGear) and
         (sqr(mx - x) + sqr(my - y) <= sqr(Radius + Gear^.Radius + 2)) and
         ((my > y) xor (Dir > 0)) then
         if (cGear^.Kind in [gtHedgehog, gtMine, gtExplosives]) and ((Gear^.State and gstNotKickable) = 0) then
             begin
             with cGear^ do
                  begin
                  if (Kind <> gtExplosives) or ((State and gsttmpflag) <> 0) then dX:= Gear^.dX * _0_5;
                  dY:= Gear^.dY;
                  State:= State or gstMoving;
                  Active:= true
                  end;
             DeleteCI(cGear);
             exit(false)
             end
   end
end;

function TestCollisionXwithXYShift(Gear: PGear; ShiftX: hwFloat; ShiftY: LongInt; Dir: LongInt): boolean;
begin
Gear^.X:= Gear^.X + ShiftX;
Gear^.Y:= Gear^.Y + int2hwFloat(ShiftY);
TestCollisionXwithXYShift:= TestCollisionXwithGear(Gear, Dir);
Gear^.X:= Gear^.X - ShiftX;
Gear^.Y:= Gear^.Y - int2hwFloat(ShiftY)
end;

function TestCollisionY(Gear: PGear; Dir: LongInt): boolean;
var x, y, i: LongInt;
begin
y:= hwRound(Gear^.Y);
if Dir < 0 then y:= y - Gear^.Radius
           else y:= y + Gear^.Radius;
if (y and LAND_HEIGHT_MASK) = 0 then
   begin
   x:= hwRound(Gear^.X) - Gear^.Radius + 1;
   i:= x + Gear^.Radius * 2 - 2;
   repeat
     if (x and LAND_WIDTH_MASK) = 0 then
        if Land[y, x] > 255 then exit(true);
     inc(x)
   until (x > i);
   end;
TestCollisionY:= false
end;

function TestCollisionYwithXYShift(Gear: PGear; ShiftX, ShiftY: LongInt; Dir: LongInt): boolean;
begin
Gear^.X:= Gear^.X + int2hwFloat(ShiftX);
Gear^.Y:= Gear^.Y + int2hwFloat(ShiftY);
TestCollisionYwithXYShift:= TestCollisionYwithGear(Gear, Dir);
Gear^.X:= Gear^.X - int2hwFloat(ShiftX);
Gear^.Y:= Gear^.Y - int2hwFloat(ShiftY)
end;


function calcSlopeTangent(Gear: PGear; collisionX, collisionY: LongInt; var outDeltaX, outDeltaY: LongInt; TestWord: LongWord): boolean;
var ldx, ldy, rdx, rdy: LongInt;
    i, j, mx, my, li, ri, jfr, jto, tmpo : ShortInt;
    tmpx, tmpy: LongWord;
    dx, dy, s: hwFloat;
    offset: Array[0..7,0..1] of ShortInt;

begin
    dx:= Gear^.dX;
    dy:= Gear^.dY;

    // we start searching from the direction the gear came from
    if (dx.QWordValue > _0_995.QWordValue )
    or (dy.QWordValue > _0_995.QWordValue ) then
        begin // scale
        s := _1 / Distance(dx,dy);
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

        tmpx:= collisionX + mx;
        tmpy:= collisionY + my;

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

        if i = 7 then break;

        // prepare offset for next check (clockwise)
        if (mx = -1) and (my <> -1) then my:= my - 1
        else if (my = -1) and (mx <> 1) then mx:= mx + 1
        else if (mx = 1) and (my <> 1) then my:= my + 1
        else mx:= mx - 1;

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

        for j:= jfr downto jto do
            begin
            tmpo:= j mod 8;
            tmpx:= ldx + offset[tmpo,0];
            tmpy:= ldy + offset[tmpo,1];
            if (((tmpy) and LAND_HEIGHT_MASK) = 0) and (((tmpx) and LAND_WIDTH_MASK)  = 0)
                and (Land[tmpy,tmpx] > TestWord) then
                    begin
                    ldx:= tmpx;
                    ldy:= tmpy;
                    break;
                    end;
            end;

        jfr:= 8+ri-1;
        jto:= 8+ri+1;

        for j:= jfr to jto do
            begin
            tmpo:= j mod 8;
            tmpx:= rdx + offset[tmpo,0];
            tmpy:= rdy + offset[tmpo,1];
            if (((tmpy) and LAND_HEIGHT_MASK) = 0) and (((tmpx) and LAND_WIDTH_MASK)  = 0)
                and (Land[tmpy,tmpx] > TestWord) then
                    begin
                    rdx:= tmpx;
                    rdy:= tmpy;
                    break;
                    end;
            end;
        end;

    ldx:= rdx - ldx;
    ldy:= rdy - ldy;

    if ((ldx = 0) and (ldy = 0)) then EXIT(false);

outDeltaX:= ldx;
outDeltaY:= ldy;
exit(true);
end;

procedure initModule;
begin
    Count:= 0;
end;

procedure freeModule;
begin

end;

end.
