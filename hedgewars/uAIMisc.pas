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

unit uAIMisc;
interface
uses uConsts, uGears, SDLh;
{$INCLUDE options.inc}

type TTargets = record
                Count: integer;
                ar: array[0..cMaxHHIndex*5] of TPoint;
                end;
                
procedure FillTargets(var Targets: TTargets);
function DxDy2Angle(const _dY, _dX: Extended): integer;
function TestColl(x, y, r: integer): boolean;
function NoMyHHNear(x, y, r: integer): boolean;
function HHGo(Gear: PGear): boolean;

implementation
uses uTeams, uStore, uMisc, uLand, uCollisions;

procedure FillTargets(var Targets: TTargets);
var t: PTeam;
    i, k: integer;
    r: integer;
    MaxHealth: integer;
    score: array[0..cMaxHHIndex*5] of integer;

  procedure qSort(iLo, iHi: Integer);
  var
    Lo, Hi, Mid, T: Integer;
    P: TPoint;
  begin
    Lo := iLo;
    Hi := iHi;
    Mid := score[(Lo + Hi) div 2];
    repeat
      while score[Lo] > Mid do Inc(Lo);
      while score[Hi] < Mid do Dec(Hi);
      if Lo <= Hi then
      begin
        T := score[Lo];
        score[Lo] := score[Hi];
        score[Hi] := T;
        P := Targets.ar[Lo];
        Targets.ar[Lo] := Targets.ar[Hi];
        Targets.ar[Hi] := P;
        Inc(Lo);
        Dec(Hi)
      end;
    until Lo > Hi;
    if Hi > iLo then qSort(iLo, Hi);
    if Lo < iHi then qSort(Lo, iHi);
  end;

begin
Targets.Count:= 0;
t:= TeamsList;
MaxHealth:= 0;
while t <> nil do
      begin
      if t <> CurrentTeam then
         for i:= 0 to cMaxHHIndex do
             if t.Hedgehogs[i].Gear <> nil then
                begin
                with Targets.ar[Targets.Count], t.Hedgehogs[i] do
                     begin
                     X:= Round(Gear.X);
                     Y:= Round(Gear.Y);
                     if integer(Gear.Health) > MaxHealth then MaxHealth:= Gear.Health;
                     score[Targets.Count]:= random(3) - integer(Gear.Health div 5)
                     end;
                inc(Targets.Count)
                end;
      t:= t.Next
      end;
// выставляем оценку за попадание в ёжика:
//  - если есть соседи-противники, то оценка увеличивается
//  - чем меньше хелса у ёжика, тем больше оценка (код см. выше)
//  - если есть соседи-"свои", то уменьшается
with Targets do
     for i:= 0 to Targets.Count - 1 do
         begin
         for k:= Succ(i) to Pred(Targets.Count) do
             begin
             r:= 100 - round(sqrt(sqr(ar[i].X - ar[k].X) + sqr(ar[i].Y - ar[k].Y)));
             if r > 0 then
                begin
                inc(score[i], r);
                inc(score[k], r)
                end;
             end;
         for k:= 0 to cMaxHHIndex do
             with CurrentTeam.Hedgehogs[k] do
                  if Gear <> nil then
                     begin
                     r:= 100 - round(sqrt(sqr(ar[i].X - round(Gear.X)) + sqr(ar[i].Y - round(Gear.Y))));
                     if r > 0 then dec(score[i], (r * 3) div 2 + MaxHealth + 5 - integer(Gear.Health));
                     end;
         end;
// сортируем по убыванию согласно оценке
if Targets.Count >= 2 then qSort(0, Pred(Targets.Count));
end;

function DxDy2Angle(const _dY, _dX: Extended): integer;
const piDIVMaxAngle: Extended = pi/cMaxAngle;
asm
        fld     _dY
        fld     _dX
        fpatan
        fld     piDIVMaxAngle
        fdiv
        sub     esp, 4
        fistp   dword ptr [esp]
        pop     eax
end;

function TestColl(x, y, r: integer): boolean;
begin
Result:=(((x-r) and $FFFFF800) = 0)and(((y-r) and $FFFFFC00) = 0) and (Land[y-r, x-r] <> 0);
if Result then exit;
Result:=(((x-r) and $FFFFF800) = 0)and(((y+r) and $FFFFFC00) = 0) and (Land[y+r, x-r] <> 0);
if Result then exit;
Result:=(((x+r) and $FFFFF800) = 0)and(((y-r) and $FFFFFC00) = 0) and (Land[y-r, x+r] <> 0);
if Result then exit;
Result:=(((x+r) and $FFFFF800) = 0)and(((y+r) and $FFFFFC00) = 0) and (Land[y+r, x+r] <> 0);
end;

function NoMyHHNear(x, y, r: integer): boolean;
var i: integer;
begin
i:= 0;
r:= sqr(r);
Result:= true;
repeat
  with CurrentTeam.Hedgehogs[i] do
       if Gear <> nil then
          if sqr(Gear.X - x) + sqr(Gear.Y - y) <= r then
             begin
             Result:= false;
             exit
             end;
inc(i)
until i > cMaxHHIndex
end;

function HHGo(Gear: PGear): boolean; // false если нельзя двигаться
var pX, pY: integer;
begin
Result:= false;
repeat
pX:= round(Gear.X);
pY:= round(Gear.Y);
if pY + cHHHalfHeight >= cWaterLine then exit;
if (Gear.State and gstFalling) <> 0 then
   begin
   Gear.dY:= Gear.dY + cGravity;
   if Gear.dY > 0.35 then exit;
   Gear.Y:= Gear.Y + Gear.dY;
   if HHTestCollisionYwithGear(Gear, 1) then
      begin
      Gear.State:= Gear.State and not (gstFalling or gstHHJumping);
      Gear.dY:= 0
      end;
   continue
   end;
   {if ((Gear.Message and gm_LJump )<>0) then
      begin
      Gear.Message:= 0;
      if not HHTestCollisionYwithGear(Gear, -1) then
         if not TestCollisionXwithXYShift(Gear, 0, -2, Sign(Gear.dX)) then Gear.Y:= Gear.Y - 2 else
         if not TestCollisionXwithXYShift(Gear, 0, -1, Sign(Gear.dX)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithGear(Gear, Sign(Gear.dX))
         or   HHTestCollisionYwithGear(Gear, -1)) then
         begin
         Gear.dY:= -0.15;
         Gear.dX:= Sign(Gear.dX) * 0.15;
         Gear.State:= Gear.State or gstFalling or gstHHJumping;
         exit
         end;
      end;}
   if (Gear.Message and gm_Left  )<>0 then Gear.dX:= -1.0 else
   if (Gear.Message and gm_Right )<>0 then Gear.dX:=  1.0 else exit;
   if TestCollisionXwithGear(Gear, Sign(Gear.dX)) then
      begin
      if not (TestCollisionXwithXYShift(Gear, 0, -6, Sign(Gear.dX))
         or HHTestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -5, Sign(Gear.dX))
         or HHTestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -4, Sign(Gear.dX))
         or HHTestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -3, Sign(Gear.dX))
         or HHTestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -2, Sign(Gear.dX))
         or HHTestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -1, Sign(Gear.dX))
         or HHTestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      end;

   if not TestCollisionXwithGear(Gear, Sign(Gear.dX)) then Gear.X:= Gear.X + Gear.dX;
   if not HHTestCollisionYwithGear(Gear, 1) then
   begin
   Gear.Y:= Gear.Y + 1;
   if not HHTestCollisionYwithGear(Gear, 1) then
   begin
   Gear.Y:= Gear.Y + 1;
   if not HHTestCollisionYwithGear(Gear, 1) then
   begin
   Gear.Y:= Gear.Y + 1;
   if not HHTestCollisionYwithGear(Gear, 1) then
   begin
   Gear.Y:= Gear.Y + 1;
   if not HHTestCollisionYwithGear(Gear, 1) then
   begin
   Gear.Y:= Gear.Y + 1;
   if not HHTestCollisionYwithGear(Gear, 1) then
   begin
   Gear.Y:= Gear.Y + 1;
   if not HHTestCollisionYwithGear(Gear, 1) then
      begin
      Gear.Y:= Gear.Y - 6;
      Gear.dY:= 0;
      Gear.dX:= 0.0000001 * Sign(Gear.dX);
      Gear.State:= Gear.State or gstFalling
      end
   end
   end
   end
   end
   end
   end;
if (pX <> round(Gear.X))and ((Gear.State and gstFalling) = 0) then
   begin
   Result:= true;
   exit
   end;
until (pX = round(Gear.X)) and (pY = round(Gear.Y)) and ((Gear.State and gstFalling) = 0);
end;

end.
