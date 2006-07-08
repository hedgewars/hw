(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
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
uses SDLh, uConsts, uGears;

type TTarget = record
               Point: TPoint;
               Score: integer;
               end;
     TTargets = record
                Count: Longword;
                ar: array[0..cMaxHHIndex*5] of TTarget;
                end;

procedure FillTargets;
procedure FillBonuses(isAfterAttack: boolean);
procedure AwareOfExplosion(x, y, r: integer);
function RatePlace(Gear: PGear): integer;
function DxDy2AttackAngle(const _dY, _dX: Extended): integer;
function TestColl(x, y, r: integer): boolean;
function RateExplosion(Me: PGear; x, y, r: integer): integer;
function HHGo(Gear: PGear): boolean;

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
          if (t.Hedgehogs[i].Gear <> nil)
             and (t.Hedgehogs[i].Gear <> ThinkingHH) then
             begin
             with Targets.ar[Targets.Count], t.Hedgehogs[i] do
                  begin
                  Point.X:= Round(Gear.X);
                  Point.Y:= Round(Gear.Y);
                  if t.Color <> CurrentTeam.Color then Score:=  Gear.Health
                                                  else Score:= -Gear.Health
                  end;
             inc(Targets.Count)
             end;
      t:= t.Next
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
MyColor:= PHedgehog(ThinkingHH.Hedgehog).Team.Color;
Gear:= GearsList;
while Gear <> nil do
      begin
      case Gear.Kind of
           gtCase: AddBonus(round(Gear.X), round(Gear.Y), 33, 25);
           gtMine: if (Gear.State and gstAttacking) = 0 then AddBonus(round(Gear.X), round(Gear.Y), 50, -50)
                                                        else AddBonus(round(Gear.X), round(Gear.Y), 100, -50); // mine is on
           gtDynamite: AddBonus(round(Gear.X), round(Gear.Y), 150, -75);
           gtHedgehog: begin
                       if Gear.Damage >= Gear.Health then AddBonus(round(Gear.X), round(Gear.Y), 60, -25) else
                          if isAfterAttack and (ThinkingHH.Hedgehog <> Gear.Hedgehog) then
                             if (MyColor = PHedgehog(Gear.Hedgehog).Team.Color) then AddBonus(round(Gear.X), round(Gear.Y), 150, -3) // hedgehog-friend
                                                                                else AddBonus(round(Gear.X), round(Gear.Y), 100, 3)
                       end;
           end;
      Gear:= Gear.NextGear
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
begin
Result:= 0;
for i:= 0 to Pred(bonuses.Count) do
    with bonuses.ar[i] do
         begin
         r:= round(sqrt(sqr(Gear.X - X) + sqr(Gear.Y - y)));
         if r < Radius then
            inc(Result, Score * (Radius - r))
         end;
end;

function DxDy2AttackAngle(const _dY, _dX: Extended): integer;
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

function RateExplosion(Me: PGear; x, y, r: integer): integer;
var i, dmg: integer;
begin
Result:= 0;
// add our virtual position
with Targets.ar[Targets.Count] do
     begin
     Point.x:= round(Me.X);
     Point.y:= round(Me.Y);
     Score:= - ThinkingHH.Health
     end;
// rate explosion
for i:= 0 to Targets.Count do
    with Targets.ar[i] do
         begin
         dmg:= r - Round(sqrt(sqr(Point.x - x) + sqr(Point.y - y)));
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
Result:= Result * 1024
end;

function HHGo(Gear: PGear): boolean;
var pX, pY: integer;
begin
Result:= false;
repeat
pX:= round(Gear.X);
pY:= round(Gear.Y);
if pY + cHHRadius >= cWaterLine then exit;
if (Gear.State and gstFalling) <> 0 then
   begin
   Gear.dY:= Gear.dY + cGravity;
   if Gear.dY > 0.40 then exit;
   Gear.Y:= Gear.Y + Gear.dY;
   if TestCollisionYwithGear(Gear, 1) then
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
         or TestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -5, Sign(Gear.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -4, Sign(Gear.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -3, Sign(Gear.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -2, Sign(Gear.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -1, Sign(Gear.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      end;

   if not TestCollisionXwithGear(Gear, Sign(Gear.dX)) then Gear.X:= Gear.X + Gear.dX;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear.Y:= Gear.Y + 1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear.Y:= Gear.Y + 1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear.Y:= Gear.Y + 1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear.Y:= Gear.Y + 1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear.Y:= Gear.Y + 1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear.Y:= Gear.Y + 1;
   if not TestCollisionYwithGear(Gear, 1) then
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
