(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004, 2005 Andrey Korotaev <unC0Rr@gmail.com>
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

procedure doStepDrowningGear(Gear: PGear); forward;

function CheckGearDrowning(Gear: PGear): boolean;
begin
Result:= Gear.Y + Gear.HalfHeight >= cWaterLine;
if Result then
   begin
   Gear.State:= gstDrowning;
   Gear.doStep:= doStepDrowningGear;
   PlaySound(sndSplash)
   end
end;

procedure CheckCollision(Gear: PGear);
begin
if TestCollisionXwithGear(Gear, Sign(Gear.X)) or TestCollisionYwithGear(Gear, Sign(Gear.Y))
   then Gear.State:= Gear.State or      gstCollision
   else Gear.State:= Gear.State and not gstCollision
end;

procedure CheckHHDamage(Gear: PGear);
begin
if Gear.dY > 0.35 then Gear.Damage:= Gear.Damage + round(75 * (abs(Gear.dY) - 0.35));
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
procedure CalcRotationDirAngle(Gear: PGear);
var dAngle: real;
begin
dAngle:= (abs(Gear.dX) + abs(Gear.dY))*0.1;
if Gear.dX >= 0 then Gear.DirAngle:= Gear.DirAngle + dAngle
                else Gear.DirAngle:= Gear.DirAngle - dAngle;
if Gear.DirAngle < 0 then Gear.DirAngle:= Gear.DirAngle + 16
else if Gear.DirAngle >= 16 then Gear.DirAngle:= Gear.DirAngle - 16
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepDrowningGear(Gear: PGear);
begin
AllInactive:= false;
Gear.Y:= Gear.Y + cDrownSpeed;
if round(Gear.Y) > Gear.HalfHeight + cWaterLine + 48 + cVisibleWater then DeleteGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFallingGear(Gear: PGear);
var b: boolean;
begin
if TestCollisionYwithGear(Gear, Sign(Gear.dY)) then
   begin
   Gear.dX:=   Gear.dX * Gear.Friction;
   Gear.dY:= - Gear.dY * Gear.Elasticity;
   b:= false
   end else b:= true;
if TestCollisionXwithGear(Gear, Sign(Gear.dX)) then
   begin
   Gear.dX:= - Gear.dX * Gear.Elasticity;
//   Gear.dY:=   Gear.dY;
   b:= false
   end;
if b then
   begin
   Gear.dY:= Gear.dY + cGravity;
   Gear.State:= Gear.State and not gstCollision
   end else
   begin
   if sqr(Gear.dX) + sqr(Gear.dY) < 0.00001 then
      if (Gear.Timer = 0) then Gear.Active:= false
                          else begin
                          Gear.dX:= 0;
                          Gear.dY:= 0
                          end;
   Gear.State:= Gear.State or gstCollision
   end;
Gear.X:= Gear.X + Gear.dX;
Gear.Y:= Gear.Y + Gear.dY;
CheckGearDrowning(Gear);
if (sqr(Gear.dX) + sqr(Gear.dY) < 0.003) then Gear.State:= Gear.State and not gstMoving
                                         else Gear.State:= Gear.State or      gstMoving
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepCloud(Gear: PGear);
begin
Gear.X:= Gear.X + cWindSpeed * 200 + Gear.dX;
if Gear.X < -cScreenWidth-256 then Gear.X:= cScreenWidth + 2048 else
if Gear.X > cScreenWidth + 2048 then Gear.X:= -cScreenWidth - 256
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBomb(Gear: PGear);
begin
AllInactive:= false;
doStepFallingGear(Gear);
dec(Gear.Timer);
if Gear.Timer = 0 then
   begin
   doMakeExplosion(round(Gear.X), round(Gear.Y), 50, EXPLAutoSound);
   DeleteGear(Gear);
   exit
   end;
CalcRotationDirAngle(Gear);
if (Gear.State and (gstCollision or gstMoving)) = (gstCollision or gstMoving) then PlaySound(sndGrenadeImpact)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepGrenade(Gear: PGear);
begin
AllInactive:= false;
Gear.dX:= Gear.dX + cWindSpeed;
doStepFallingGear(Gear);
if (Gear.State and gstCollision) <> 0 then
   begin
   doMakeExplosion(round(Gear.X), round(Gear.Y), 50, EXPLAutoSound);
   DeleteGear(Gear);
   exit
   end;
if (GameTicks and $3F) = 0 then
   AddGear(round(Gear.X), round(Gear.Y), gtSmokeTrace, 0)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepHealthTag(Gear: PGear);
begin
AllInactive:= false;
dec(Gear.Timer);
Gear.Y:= Gear.Y - 0.07;
if Gear.Timer = 0 then
   begin
   PHedgehog(Gear.Hedgehog).Gear.Active:= true;
   DeleteGear(Gear)
   end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepGrave(Gear: PGear);
begin
AllInactive:= false;
if Gear.dY < 0 then
   if TestCollisionY(Gear, -1) then Gear.dY:= 0;

if Gear.dY >=0 then
   if TestCollisionY(Gear, 1) then
      begin
      Gear.dY:= - Gear.dY * Gear.Elasticity;
      if Gear.dY > - 0.001 then
         begin
         Gear.Active:= false;
         exit
         end else if Gear.dY < - 0.03 then PlaySound(sndGraveImpact)
      end;
Gear.Y:= Gear.Y + Gear.dY;
CheckGearDrowning(Gear);
Gear.dY:= Gear.dY + cGravity
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepUFOWork(Gear: PGear);
var t: real;
begin
AllInactive:= false;
t:= sqrt(sqr(Gear.dX) + sqr(Gear.dY));
Gear.dX:= Gear.Elasticity * (Gear.dX + 0.000004 * (TargetPoint.X - trunc(Gear.X)));
Gear.dY:= Gear.Elasticity * (Gear.dY + 0.000004 * (TargetPoint.Y - trunc(Gear.Y)));
t:= t / (sqrt(sqr(Gear.dX) + sqr(Gear.dY)));
Gear.dX:= Gear.dX * t;
Gear.dY:= Gear.dY * t;
Gear.X:= Gear.X + Gear.dX;
Gear.Y:= Gear.Y + Gear.dY;
CheckCollision(Gear);
dec(Gear.Timer);
if ((Gear.State and gstCollision) <> 0) or (Gear.Timer = 0) then
   begin
   doMakeExplosion(round(Gear.X), round(Gear.Y), 50, EXPLAutoSound);
   DeleteGear(Gear);
   end;
end;

procedure doStepUFO(Gear: PGear);
begin
AllInactive:= false;
Gear.X:= Gear.X + Gear.dX;
Gear.Y:= Gear.Y + Gear.dY;
Gear.dY:= Gear.dY + cGravity;
CheckCollision(Gear);
if (Gear.State and gstCollision) <> 0 then
   begin
   doMakeExplosion(round(Gear.X), round(Gear.Y), 50, EXPLAutoSound);
   DeleteGear(Gear);
   exit
   end;
dec(Gear.Timer);
if Gear.Timer = 0 then
   begin
   Gear.Timer:= 5000;
   Gear.doStep:= doStepUFOWork
   end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepShotgunShot(Gear: PGear);
var i: LongWord;
    t: PGear;
begin
AllInactive:= false;
if Gear.Timer > 0 then
   begin
   dec(Gear.Timer);
   if Gear.Timer = 1 then PlaySound(sndShotgunFire);
   exit
   end;
i:= 200;
repeat
Gear.X:= Gear.X + Gear.dX;
Gear.Y:= Gear.Y + Gear.dY;
CheckCollision(Gear);
if (Gear.State and gstCollision) <> 0 then
   begin
   t:= CheckGearsCollision(Gear, Sign(Gear.dX), true);
   if t = nil then t:= CheckGearsCollision(Gear, Sign(Gear.dY), false);
   if t <> nil then
      AmmoShove(Gear, t, 25);
   doMakeExplosion(round(Gear.X), round(Gear.Y), 25, EXPLNoDamage or EXPLDoNotTouchHH);
   DeleteGear(Gear);
   exit
   end;
dec(i)
until i = 0;
if (Gear.X < 0) or (Gear.Y < 0) or (Gear.X > 2048) or (Gear.Y > 1024) then
   DeleteGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepDEagleShot(Gear: PGear);
var i, x, y: LongWord;
    oX, oY: real;
    t: PGear;
begin
AllInactive:= false;
i:= 80;
oX:= Gear.X;
oY:= Gear.Y;
repeat
  Gear.X:= Gear.X + Gear.dX;
  Gear.Y:= Gear.Y + Gear.dY;
  x:= round(Gear.X);
  y:= round(Gear.Y);
  if ((y and $FFFFFC00) = 0) and ((x and $FFFFF800) = 0)
     and (Land[y, x] <> 0) then inc(Gear.Damage);
  t:= CheckGearsCollision(Gear, Sign(Gear.dX), true);
  if t = nil then t:= CheckGearsCollision(Gear, Sign(Gear.dY), false);
  if t <> nil then
     begin
     AmmoShove(Gear, t, 12);
     inc(Gear.Damage, 10);
     if t.CollIndex < High(Longword) then DeleteCR(t)
     end;
  dec(i)
until (i = 0) or (Gear.Damage > Gear.Health);
if Gear.Damage > 0 then
   begin
   DrawTunnel(oX, oY, Gear.dX, Gear.dY, 82 - i, 1);
   dec(Gear.Health, Gear.Damage);
   Gear.Damage:= 0
   end;
if (Gear.Health <= 0) or (Gear.X < 0) or (Gear.Y < 0) or (Gear.X > 2048) or (Gear.Y > 1024) then
   DeleteGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepActionTimer(Gear: PGear);
begin
case Gear.State of
     gtsStartGame: begin
                   dec(Gear.Timer);
                   AllInactive:= false;
                   if Gear.Timer > 0 then exit;
                   AddCaption('Let''s fight!', $FFFFFF, capgrpStartGame);
                   DeleteGear(Gear)
                   end;
  gtsSmoothWindCh: begin
                   if Gear.Timer = 0 then
                      begin
                      Gear.Timer:= 10;
                      if WindBarWidth < Gear.Tag then inc(WindBarWidth)
                         else if WindBarWidth > Gear.Tag then dec(WindBarWidth)
                         else DeleteGear(Gear)
                      end else dec(Gear.Timer)
                   end;
     end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepPickHammerWork(Gear: PGear);
var i, ei: integer;
    HHGear: PGear;
begin
Allinactive:= false;
dec(Gear.Timer);
if (Gear.Timer = 0)or((Gear.Message and gm_Destroy) <> 0) then
   begin
   DeleteGear(Gear);
   AfterAttack;
   exit
   end;
HHGear:= PHedgehog(Gear.Hedgehog).Gear;
if (Gear.Timer and $3F) = 0 then
   begin
   i:= round(Gear.X) - Gear.HalfWidth  - GetRandom(2);
   ei:= round(Gear.X) + Gear.HalfWidth + GetRandom(2);
   while i <= ei do
         begin
         doMakeExplosion(i, round(Gear.Y) + 3, 3, 0);
         inc(i, 1)
         end;
   Gear.X:= Gear.X + Gear.dX;
   Gear.Y:= Gear.Y + 1.9;
   SetAllHHToActive;
   end;
if TestCollisionYwithGear(Gear, 1) then
   begin
   Gear.dY:= 0;
   HHGear.dX:= 0.0000001 * Sign(PGear(Gear.Hedgehog).dX);
   HHGear.dY:= 0;
   end else
   begin
   Gear.dY:= Gear.dY + cGravity;
   Gear.Y:= Gear.Y + Gear.dY;
   if Gear.Y > 1024 then Gear.Timer:= 1
   end;

Gear.X:= Gear.X + HHGear.dX;
HHGear.X:= Gear.X;
HHGear.Y:= Gear.Y - cHHHalfHeight;

if (Gear.Message and gm_Attack) <> 0 then
   if (Gear.State and gsttmpFlag) <> 0 then Gear.Timer:= 1 else else
   if (Gear.State and gsttmpFlag) = 0 then Gear.State:= Gear.State or gsttmpFlag;
if ((Gear.Message and gm_Left) <> 0) then Gear.dX:= -0.3 else
   if ((Gear.Message and gm_Right) <> 0) then Gear.dX:= 0.3
                                         else Gear.dX:= 0;
end;

procedure doStepPickHammer(Gear: PGear);
var i, y: integer;
    ar: TRangeArray;
begin
i:= 0;
y:= round(Gear.Y) - cHHHalfHeight*2;
while y < round(Gear.Y) do
   begin
   ar[i].Left := round(Gear.X) - Gear.HalfWidth - GetRandom(2);
   ar[i].Right:= round(Gear.X) + Gear.HalfWidth + GetRandom(2);
   inc(y, 2);
   inc(i)
   end;
DrawHLinesExplosions(@ar, 3, round(Gear.Y) - cHHHalfHeight*2, 2, Pred(i));
Gear.dY:= PHedgehog(Gear.Hedgehog).Gear.dY;
doStepPickHammerWork(Gear);
Gear.doStep:= doStepPickHammerWork
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepRopeWork(Gear: PGear);
const pidiv2: real = pi/2;
      flCheck: boolean = false;
var HHGear: PGear;
    len, cs, cc, tx, ty: real;
    lx, ly: integer;

    procedure DeleteMe;
    begin
      with HHGear^ do
           begin
           Message:= Message and not gm_Attack;
           State:= State or gstFalling;
           end;
      DeleteGear(Gear);
      OnUsedAmmo(PHedgehog(Gear.Hedgehog)^.Ammo);
      ApplyAmmoChanges(PHedgehog(Gear.Hedgehog))
    end;

begin
HHGear:= PHedgehog(Gear.Hedgehog).Gear;
if (HHGear.State and gstHHDriven) = 0 then
   begin
   DeleteMe;
   exit
   end;
Gear.dX:= HHGear.X - Gear.X;
Gear.dY:= HHGear.Y - Gear.Y;

if (Gear.Message and gm_Left  <> 0) then HHGear.dX:= HHGear.dX - 0.0002 else
if (Gear.Message and gm_Right <> 0) then HHGear.dX:= HHGear.dX + 0.0002;

if not TestCollisionYwithGear(HHGear, 1) then HHGear.dY:= HHGear.dY + cGravity;

HHGear.DirAngle:= arctan(Gear.dY + HHGear.dY, Gear.dX + HHGear.dX);
cs:= sin(HHGear.DirAngle);
cc:= cos(HHGear.DirAngle);

flCheck:= not flCheck;
if flCheck then  // check whether rope needs dividing
   begin
   len:= Gear.Elasticity - 20;
   while len > 5 do
         begin
         tx:= cc*len;
         ty:= cs*len;
         lx:= round(Gear.X + tx) + sign(HHGear.dX);
         ly:= round(Gear.Y + ty) + sign(HHGear.dY);
         if ((ly and $FFFFFC00) = 0) and ((lx and $FFFFF800) = 0)and (Land[ly, lx] <> 0) then
           begin
           with RopePoints.ar[RopePoints.Count] do
                begin
                X:= Gear.X;
                Y:= Gear.Y;
                if RopePoints.Count = 0 then RopePoints.HookAngle:= DxDy2Angle32(Gear.dY, Gear.dX);
                b:= (cc * HHGear.dY) > (cs * HHGear.dX);
                dLen:= len
                end;
           Gear.X:= Gear.X + tx;
           Gear.Y:= Gear.Y + ty;
           inc(RopePoints.Count);
           Gear.Elasticity:= Gear.Elasticity - len;
           Gear.Friction:= Gear.Friction - len;
           break
           end;
         len:= len - 3
         end;
   end else
   if RopePoints.Count > 0 then // check whether the last dividing point could be removed
      begin
      tx:= RopePoints.ar[Pred(RopePoints.Count)].X;
      ty:= RopePoints.ar[Pred(RopePoints.Count)].Y;
      if RopePoints.ar[Pred(RopePoints.Count)].b xor ((tx - Gear.X) * (ty - HHGear.Y) > (tx - HHGear.X) * (ty - Gear.Y)) then
         begin
         dec(RopePoints.Count);
         Gear.X:=RopePoints.ar[RopePoints.Count].X;
         Gear.Y:=RopePoints.ar[RopePoints.Count].Y;
         Gear.Elasticity:= Gear.Elasticity + RopePoints.ar[RopePoints.Count].dLen;
         Gear.Friction:= Gear.Friction + RopePoints.ar[RopePoints.Count].dLen
         end
      end;

Gear.dX:= HHGear.X - Gear.X;
Gear.dY:= HHGear.Y - Gear.Y;
HHGear.DirAngle:= arctan(Gear.dY + HHGear.dY, Gear.dX + HHGear.dX);
cs:= sin(HHGear.DirAngle);
cc:= cos(HHGear.DirAngle);

HHGear.dX:= HHGear.X;
HHGear.dY:= HHGear.Y;

if ((Gear.Message and gm_Down) <> 0) and (Gear.Elasticity < Gear.Friction) then
   if not (TestCollisionXwithGear(HHGear, Sign(Gear.dX))
        or TestCollisionYwithGear(HHGear, Sign(Gear.dY))) then Gear.Elasticity:= Gear.Elasticity + 0.3;

if ((Gear.Message and gm_Up) <> 0) and (Gear.Elasticity > 30) then
   if not (TestCollisionXwithGear(HHGear, -Sign(Gear.dX))
        or TestCollisionYwithGear(HHGear, -Sign(Gear.dY))) then Gear.Elasticity:= Gear.Elasticity - 0.3;

HHGear.X:= Gear.X + cc*Gear.Elasticity;
HHGear.Y:= Gear.Y + cs*Gear.Elasticity;

HHGear.dX:= HHGear.X - HHGear.dX;
HHGear.dY:= HHGear.Y - HHGear.dY;

if TestCollisionXwithGear(HHGear, Sign(HHGear.dX)) then
   HHGear.dX:= -0.9 * HHGear.dX;
if TestCollisionYwithGear(HHGear, Sign(HHGear.dY)) then
   HHGear.dY:= -0.9 * HHGear.dY;

if (Gear.Message and gm_Attack) <> 0 then
   if (Gear.State and gsttmpFlag) <> 0 then DeleteMe else
else if (Gear.State and gsttmpFlag) = 0 then Gear.State:= Gear.State or gsttmpFlag;
end;


procedure doStepRopeAttach(Gear: PGear);
var HHGear: PGear;
    tx, ty, tt: real;
begin
Gear.X:= Gear.X + Gear.dX;
Gear.Y:= Gear.Y + Gear.dY;
Gear.Elasticity:= Gear.Elasticity + 1.0;
HHGear:= PHedgehog(Gear.Hedgehog)^.Gear;
if (HHGear.State and gstFalling) <> 0 then
   if HHTestCollisionYwithGear(HHGear, 1) then
      begin
      HHGear.dY:= 0;
      CheckHHDamage(HHGear);
      HHGear.State:= HHGear.State and not (gstFalling or gstHHJumping);
      end else
      begin
      if TestCollisionXwithGear(HHGear, Sign(HHGear.dX)) then HHGear.dX:= 0.0000001 * Sign(HHGear.dX);
      HHGear.X:= HHGear.X + HHGear.dX;
      HHGear.Y:= HHGear.Y + HHGear.dY;
      Gear.X:= Gear.X + HHGear.dX;
      Gear.Y:= Gear.Y + HHGear.dY;
      HHGear.dY:= HHGear.dY + cGravity;
      tt:= Gear.Elasticity;
      tx:= 0;
      ty:= 0;
      while tt > 20 do
            begin
            if  TestCollisionXwithXYShift(Gear, round(tx), round(ty), Sign(Gear.dX))
             or TestCollisionYwithXYShift(Gear, round(tx), round(ty), Sign(Gear.dY)) then
                begin
                Gear.X:= Gear.X + tx;
                Gear.Y:= Gear.Y + ty;
                Gear.Elasticity:= tt;
                Gear.doStep:= doStepRopeWork;
                with HHGear^ do State:= State and not gstAttacking;
                tt:= 0
                end;
            tx:= tx - Gear.dX - Gear.dX;
            ty:= ty - Gear.dY - Gear.dY;
            tt:= tt - 2.0;
            end;
      end;
CheckCollision(Gear);
if (Gear.State and gstCollision) <> 0 then
   begin
   Gear.doStep:= doStepRopeWork;
   with HHGear^ do State:= State and not gstAttacking;
   if Gear.Elasticity < 10 then
      Gear.Elasticity:= 10000;
   end;

if (Gear.Elasticity >= Gear.Friction) or ((Gear.Message and gm_Attack) = 0) then
   begin
   with PHedgehog(Gear.Hedgehog).Gear^ do
        begin
        State:= State and not gstAttacking;
        Message:= Message and not gm_Attack
        end;
   DeleteGear(Gear)
   end
end;

procedure doStepRope(Gear: PGear);
begin
Gear.doStep:= doStepRopeAttach
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSmokeTrace(Gear: PGear);
begin
inc(Gear.Timer);
if Gear.Timer > 64 then
   begin
   Gear.Timer:= 0;
   dec(Gear.State)
   end;
Gear.dX:= Gear.dX + cWindSpeed;
Gear.X:= Gear.X + Gear.dX;
if Gear.State = 0 then DeleteGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepExplosion(Gear: PGear);
begin
inc(Gear.Timer);
if Gear.Timer > 75 then
   begin
   inc(Gear.State);
   Gear.Timer:= 0;
   if Gear.State > 5 then DeleteGear(Gear)
   end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepMine(Gear: PGear);
begin
if (Gear.dX <> 0) or (Gear.dY <> 0) then
   begin
   if Gear.CollIndex < High(Longword) then DeleteCR(Gear);
   doStepFallingGear(Gear);
   if Gear.Active = false then
      begin
      if Gear.CollIndex = High(Longword) then AddGearCR(Gear);
      Gear.dX:= 0;
      Gear.dY:= 0
      end;
   CalcRotationDirAngle(Gear);
   AllInactive:= false
   end;
   
if ((Gear.State and gsttmpFlag) <> 0) then
   if ((Gear.State and gstAttacking) = 0) then
      begin
      if ((GameTicks and $F) = 0) then
         if CheckGearNear(Gear, gtHedgehog, 46, 32) <> nil then Gear.State:= Gear.State or gstAttacking
      end else // gstAttacking <> 0
      begin
      AllInactive:= false;
      if (Gear.Timer and $FF) = 0 then PlaySound(sndMineTick);
      if Gear.Timer = 0 then
         begin
         doMakeExplosion(round(Gear.X), round(Gear.Y), 50, EXPLAutoSound);
         DeleteGear(Gear)
         end;
      dec(Gear.Timer);
      end else // gsttmpFlag = 0
   if TurnTimeLeft = 0 then Gear.State:= Gear.State or gsttmpFlag;
end;
////////////////////////////////////////////////////////////////////////////////
procedure doStepDynamite(Gear: PGear);
begin
if (Gear.dX <> 0) or (Gear.dY <> 0) {or not TestCollisionY(Gear, 1)} then
   begin
   doStepFallingGear(Gear);
   if Gear.Active = false then
      begin
      Gear.dX:= 0;
      Gear.dY:= 0
      end;
//   CalcRotationDirAngle(Gear);
   AllInactive:= false
   end;
//if ((Gear.State and gsttmpFlag) <> 0) then
//   if ((Gear.State  and gstAttacking) = 0) then
      begin
  //    AllInactive:= true;
      if (Gear.Timer and $FF) = 0 then PlaySound(sndMineTick);
      if Gear.Timer = 0 then
         begin
         doMakeExplosion(round(Gear.X), round(Gear.Y), 85, EXPLAutoSound);
         DeleteGear(Gear)
         end;
      dec(Gear.Timer);
      end;{ else // gsttmpFlag = 0
   if TurnTimeLeft = 0 then Gear.State:= Gear.State or gsttmpFlag;}
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepCase(Gear: PGear);
begin
if (Gear.Message and gm_Destroy) > 0 then
   begin
   DeleteGear(Gear);
   exit
   end;

if (Gear.dY <> 0) or (not TestCollisionY(Gear, 1)) then
   begin
   AllInactive:= false;
   Gear.dY:= Gear.dY + cGravity;
   Gear.Y:= Gear.Y + Gear.dY;
   if (Gear.dY < 0) and TestCollisionY(Gear, -1) then Gear.dY:= 0 else
   if (Gear.dY >= 0) and TestCollisionY(Gear, 1) then
      begin
      Gear.dY:= - Gear.dY * Gear.Elasticity;
      if Gear.dY > - 0.001 then Gear.dY:= 0
         else if Gear.dY < - 0.03 then PlaySound(sndGraveImpact);
      end;
   CheckGearDrowning(Gear);
   end;

if (Gear.CollIndex = High(Longword)) and (Gear.dY = 0) then AddGearCR(Gear)
   else if (Gear.CollIndex < High(Longword)) and (Gear.dY <> 0) then DeleteCR(Gear);

if Gear.Damage > 0 then
   begin
   DeleteGear(Gear);
   doMakeExplosion(round(Gear.X), round(Gear.Y), 20, EXPLAutoSound)
   end
end;
