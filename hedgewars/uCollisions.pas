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
uses uGears, uFloat;

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

function  calcSlopeNormal(Gear: PGear; collisionX, collisionY: LongInt; var deltaX, deltaY: LongInt; TestWord: LongWord): Boolean;

implementation
uses uMisc, uConsts, uLand, uLandGraphics, uConsole;

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
var mx, my: LongInt;
    i: Longword;
begin
CheckGearsCollision:= @ga;
ga.Count:= 0;
if Count = 0 then exit;
mx:= hwRound(Gear^.X);
my:= hwRound(Gear^.Y);

for i:= 0 to Pred(Count) do
    with cinfos[i] do
        if (Gear <> cGear) and
            (sqr(mx - x) + sqr(my - y) <= sqr(Radius + Gear^.Radius)) then
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
         if (cGear^.Kind in [gtHedgehog, gtMine]) and ((Gear^.State and gstNotKickable) = 0) then
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
         if (cGear^.Kind in [gtHedgehog, gtMine]) and ((Gear^.State and gstNotKickable) = 0) then
             begin
             with cGear^ do
                  begin
                  dX:= Gear^.dX * _0_5;
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


function calcSlopeNormal(Gear: PGear; collisionX, collisionY: LongInt; var deltaX, deltaY: LongInt; TestWord: LongWord): boolean;
var sx, sy, ldx, ldy, rdx, rdy: LongInt;
    i, j, mx, my : ShortInt;
    tmpx, tmpy: LongWord;
    dx, dy, rx, ry: hwFloat;
    leftsteps:  Array[0..4,0..1] of ShortInt;
    rightsteps: Array[0..4,0..1] of ShortInt;

begin
    dx:= Gear^.dX;
    dy:= Gear^.dY;
    
    if Gear^.AdvBounce > 0 then
        begin
        rx:= _0_5 + Int2hwFloat(collisionX) - Gear^.X;
        ry:= _0_5 + Int2hwFloat(collisionY) - Gear^.Y;
        end
    else
        begin
        rx:= dx;
        ry:= dy;
        end;

    sx:= hwSign(rx);
    sy:= hwSign(ry);

    if rx.QWordValue > ry.QWordValue then
        begin
        if (ry/rx).QWordValue < _0_5.QWordValue then sy:= 0;
        end
    else
        begin
        if (rx/ry).QWordValue < _0_5.QWordValue then sx:= 0;
        end;

    mx:= -sx;
    my:= -sy;

    for i:= 0 to 4 do
        begin
        if (mx = -1) and (my <>  1) then my:= my + 1
        else if (my = 1) and (mx <> 1) then mx:= mx + 1
        else if (mx = 1) and (my <> -1) then my:= my - 1
        else mx:= mx - 1;

        leftsteps[i,0]:= mx;
        leftsteps[i,1]:= my;
        end;

    mx:= -sx;
    my:= -sy;

    for i:= 0 to 4 do
        begin
        if (mx = -1) and (my <> -1) then my:= my - 1
        else if (my = -1) and (mx <> 1) then mx:= mx + 1
        else if (mx = 1) and (my <> 1) then my:= my + 1
        else mx:= mx - 1;

        rightsteps[i,0]:= mx;
        rightsteps[i,1]:= my;
        end;

    ldx:= collisionX;
    ldy:= collisionY;
    rdx:= collisionX;
    rdy:= collisionY;

    for i:= 0 to 4 do
        begin
        tmpx:= collisionX + leftsteps[i,0];
        tmpy:= collisionY + leftsteps[i,1];
        if (((tmpy) and LAND_HEIGHT_MASK) = 0) and (((tmpx) and LAND_WIDTH_MASK)  = 0) then
            if (Land[tmpy,tmpx] > TestWord) then
                begin
                if i <> 0 then
                    for j:= 0 to 2 do
                        begin
                        leftsteps[j,0]:= leftsteps[i+j,0];
                        leftsteps[j,1]:= leftsteps[i+j,1];
                        end;
                ldx:= tmpx;
                ldy:= tmpy;
                break;
                end;
        end;

    for i:= 0 to 4 do
        begin
        tmpx:= collisionX + rightsteps[i,0];
        tmpy:= collisionY + rightsteps[i,1];
        if (((tmpy) and LAND_HEIGHT_MASK) = 0) and (((tmpx) and LAND_WIDTH_MASK)  = 0) then
            if (Land[tmpy,tmpx] > TestWord) then
                begin
                if i <> 0 then
                    for j:= 0 to 2 do
                        begin
                        rightsteps[j,0]:= rightsteps[i+j-1,0];
                        rightsteps[j,1]:= rightsteps[i+j-1,1];
                        end;
                rdx:= tmpx;
                rdy:= tmpy;
                break;
                end;
        end;

    // TODO: avoid redundant checks
    for i:= 0 to 4 do
        begin
        for j:= 0 to 2 do
            begin
            tmpx:= ldx + leftsteps[j,0];
            tmpy:= ldy + leftsteps[j,1];
            if (((tmpy) and LAND_HEIGHT_MASK) = 0) and (((tmpx) and LAND_WIDTH_MASK)  = 0) then
                if (Land[tmpy,tmpx] > TestWord) then
                    begin
                    ldx:= tmpx;
                    ldy:= tmpy;
                    break;
                    end;
            end;
        end;

    for i:= 0 to 4 do
        begin
        for j:= 0 to 2 do
            begin
            tmpx:= rdx + rightsteps[j,0];
            tmpy:= rdy + rightsteps[j,1];
            if (((tmpy) and LAND_HEIGHT_MASK) = 0) and (((tmpx) and LAND_WIDTH_MASK)  = 0) then
                if (Land[tmpy,tmpx] > TestWord) then
                    begin
                    rdx:= tmpx;
                    rdy:= tmpy;
                    break;
                    end;
            end;
        end;

    ldx:= rdx - ldx;
    ldy:= rdy - ldy;

    // rotate vector by 90°
    rdx:= -ldy;
    ldy:= ldx;
    ldx:= rdx;
    
    if (ldy <> 0) then tmpy := collisionY + ldy div abs(ldy) else tmpy:= collisionY;
    if (ldx <> 0) then tmpx := collisionX + ldx div abs(ldx) else tmpx:= collisionX;
    if ((ldx = 0) and (ldy = 0)) then EXIT(false);
    
    if ((((tmpy) and LAND_HEIGHT_MASK) = 0) and (((tmpx) and LAND_WIDTH_MASK)  = 0) 
        and (Land[tmpy,tmpx] > TestWord)) then
            begin
            if (ldy <> 0) then
                begin
                ldy:= -ldy;
                tmpy := collisionY + ldy div abs(ldy);
                end;
            if (ldx <> 0) then
                begin
                ldx:= -ldx;
                tmpx := collisionX + ldx div abs(ldx);
                end;
            
            if ((((tmpy) and LAND_HEIGHT_MASK) = 0) and (((tmpx) and LAND_WIDTH_MASK)  = 0) 
                and (Land[tmpy,tmpx] > TestWord)) then
                    EXIT(false);
            end;

        
    if (dx*ldx + dy*ldy).isNegative then
        begin
        deltaX:= ldx;
        deltaY:= ldy;
        EXIT(true);
        end;
exit(false);
end;

procedure initModule;
begin
    Count:= 0;
end;

procedure freeModule;
begin

end;

end.
