(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004, 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
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

procedure doStepDrowningGear(Gear: PGear); forward;

function CheckGearDrowning(Gear: PGear): boolean;
begin
Result:= Gear.Y + Gear.Radius >= cWaterLine;
if Result then
   begin
   Gear.State:= gstDrowning;
   Gear.doStep:= doStepDrowningGear;
   PlaySound(sndSplash)
   end
end;

procedure CheckCollision(Gear: PGear);
begin
if TestCollisionXwithGear(Gear, hwSign(Gear.X)) or TestCollisionYwithGear(Gear, hwSign(Gear.Y))
   then Gear.State:= Gear.State or      gstCollision
   else Gear.State:= Gear.State and not gstCollision
end;

procedure CheckHHDamage(Gear: PGear);
begin
if Gear.dY > 0.40 then Gear.Damage:= Gear.Damage + 1 + round(70 * (abs(Gear.dY) - 0.40));
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
procedure CalcRotationDirAngle(Gear: PGear);
var dAngle: Double;
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
if round(Gear.Y) > Gear.Radius + cWaterLine + cVisibleWater then DeleteGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFallingGear(Gear: PGear);
var b: boolean;
begin
if TestCollisionYwithGear(Gear, hwSign(Gear.dY)) then
   begin
   Gear.dX:=   Gear.dX * Gear.Friction;
   Gear.dY:= - Gear.dY * Gear.Elasticity;
   b:= false
   end else b:= true;
if TestCollisionXwithGear(Gear, hwSign(Gear.dX)) then
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
if Gear.Y > -160 then Gear.dY:= Gear.dY - 0.00002
                 else Gear.dY:= Gear.dY + 0.00002;
Gear.Y:= Gear.Y + Gear.dY;
if Gear.X < -cScreenWidth - 256 then Gear.X:= cScreenWidth + 2048 else
if Gear.X > cScreenWidth + 2048 then Gear.X:= -cScreenWidth - 256
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBomb(Gear: PGear);
var i: integer;
begin
AllInactive:= false;
doStepFallingGear(Gear);
dec(Gear.Timer);
if Gear.Timer = 0 then
   begin
   case Gear.Kind of
        gtAmmo_Bomb: doMakeExplosion(round(Gear.X), round(Gear.Y), 50, EXPLAutoSound);
      gtClusterBomb: begin
                     doMakeExplosion(round(Gear.X), round(Gear.Y), 30, EXPLAutoSound);
                     for i:= 0 to 4 do
                         AddGear(round(Gear.X), round(Gear.Y), gtCluster, 0, (getrandom - 0.5)*0.2, (getrandom - 3) * 0.08);
                     end
        end;
   DeleteGear(Gear);
   exit
   end;
CalcRotationDirAngle(Gear);
if (Gear.State and (gstCollision or gstMoving)) = (gstCollision or gstMoving) then PlaySound(sndGrenadeImpact)
end;

procedure doStepCluster(Gear: PGear);
begin
AllInactive:= false;
doStepFallingGear(Gear);
if (Gear.State and gstCollision) <> 0 then
   begin
   doMakeExplosion(round(Gear.X), round(Gear.Y), 20, EXPLAutoSound);
   DeleteGear(Gear);
   exit
   end;
if (GameTicks and $1F) = 0 then
   AddGear(round(Gear.X), round(Gear.Y), gtSmokeTrace, 0)
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
procedure doStepHealthTagWork(Gear: PGear);
begin
AllInactive:= false;
dec(Gear.Timer);
Gear.Y:= Gear.Y - 0.07;
if Gear.Timer = 0 then
   begin
   PHedgehog(Gear.Hedgehog).Gear.Active:= true; // to let current hh die
   DeleteGear(Gear)
   end
end;

procedure doStepHealthTagWorkUnderWater(Gear: PGear);
begin
AllInactive:= false;
Gear.Y:= Gear.Y - 0.07;
if Gear.Y <= cWaterLine + 10 then
   DeleteGear(Gear)
end;

procedure doStepHealthTag(Gear: PGear);
var s: shortstring;
begin
AllInactive:= false;
str(Gear.State, s);
Gear.Surf:= RenderString(s, PHedgehog(Gear.Hedgehog).Team.Color, fnt16);
if Gear.Y < cWaterLine then Gear.doStep:= doStepHealthTagWork
                       else Gear.doStep:= doStepHealthTagWorkUnderWater
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
var t: Double;
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
begin
AllInactive:= false;
if Gear.Timer > 0 then
   begin
   dec(Gear.Timer);
   if Gear.Timer = 0 then PlaySound(sndShotgunFire);
   exit
   end;
i:= 200;
repeat
Gear.X:= Gear.X + Gear.dX;
Gear.Y:= Gear.Y + Gear.dY;
CheckCollision(Gear);
if (Gear.State and gstCollision) <> 0 then
   begin
   AmmoShove(Gear, 25, 25);
   doMakeExplosion(round(Gear.X), round(Gear.Y), 25, EXPLNoDamage or EXPLDoNotTouchHH);
   DeleteGear(Gear);
   AfterAttack;
   exit
   end;
dec(i)
until i = 0;
if (Gear.X < 0) or (Gear.Y < 0) or (Gear.X > 2048) or (Gear.Y > 1024) then
   begin
   DeleteGear(Gear);
   AfterAttack
   end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepDEagleShot(Gear: PGear);
var i, x, y: LongWord;
    oX, oY: Double;
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
  AmmoShove(Gear, 7, 20);
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
dec(Gear.Timer);
case Gear.Kind of
    gtATStartGame: begin
                   AllInactive:= false;
                   if Gear.Timer = 0 then
                      AddCaption(trmsg[sidStartFight], $FFFFFF, capgrpGameState);
                   end;
 gtATSmoothWindCh: begin
                   if Gear.Timer = 0 then
                      begin
                      if WindBarWidth < Gear.Tag then inc(WindBarWidth)
                         else if WindBarWidth > Gear.Tag then dec(WindBarWidth);
                      if WindBarWidth <> Gear.Tag then Gear.Timer:= 10;
                      end
                   end;
   gtATFinishGame: begin
                   AllInactive:= false;
                   if Gear.Timer = 0 then
                      begin
                      SendIPC('N');
                      SendIPC('q');
                      GameState:= gsExit
                      end
                   end;
     end;
if Gear.Timer = 0 then DeleteGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepPickHammerWork(Gear: PGear);
var i, ei: integer;
    HHGear: PGear;
begin
AllInactive:= false;
HHGear:= PHedgehog(Gear.Hedgehog).Gear;
dec(Gear.Timer);
if (Gear.Timer = 0)or((Gear.Message and gm_Destroy) <> 0)or((HHGear.State and gstHHDriven) = 0) then
   begin
   StopSound(sndPickhammer);
   DeleteGear(Gear);
   AfterAttack;
   exit
   end;
if (Gear.Timer and $3F) = 0 then
   begin
   i:= round(Gear.X) - Gear.Radius  - GetRandom(2);
   ei:= round(Gear.X) + Gear.Radius + GetRandom(2);
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
   SetLittle(HHGear.dX);
   HHGear.dY:= 0;
   end else
   begin
   Gear.dY:= Gear.dY + cGravity;
   Gear.Y:= Gear.Y + Gear.dY;
   if Gear.Y > 1024 then Gear.Timer:= 1
   end;

Gear.X:= Gear.X + HHGear.dX;
HHGear.X:= Gear.X;
HHGear.Y:= Gear.Y - cHHRadius;

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
y:= round(Gear.Y) - cHHRadius*2;
while y < round(Gear.Y) do
   begin
   ar[i].Left := round(Gear.X) - Gear.Radius - GetRandom(2);
   ar[i].Right:= round(Gear.X) + Gear.Radius + GetRandom(2);
   inc(y, 2);
   inc(i)
   end;
DrawHLinesExplosions(@ar, 3, round(Gear.Y) - cHHRadius*2, 2, Pred(i));
Gear.dY:= PHedgehog(Gear.Hedgehog).Gear.dY;
PlaySound(sndPickhammer, true);
doStepPickHammerWork(Gear);
Gear.doStep:= doStepPickHammerWork
end;

////////////////////////////////////////////////////////////////////////////////
var BTPrevAngle, BTSteps: Longword;

procedure doStepBlowTorchWork(Gear: PGear);
var HHGear: PGear;
    b: boolean;
begin
AllInactive:= false;
dec(Gear.Timer);
HHGear:= PHedgehog(Gear.Hedgehog).Gear;

HedgehogChAngle(HHGear);

b:= false;

if (HHGear.Angle <> BTPrevAngle) then
   begin
   Gear.dX:= hwSign(HHGear.dX) * Sin(HHGear.Angle * pi / cMaxAngle) * 0.5;
   Gear.dY:= Cos(HHGear.Angle * pi / cMaxAngle) * (-0.5);
   BTPrevAngle:= HHGear.Angle;
   b:= true
   end;

if Gear.Timer mod cHHStepTicks = 0 then
   begin
   b:= true;
   if Gear.dX < 0 then HHGear.Message:= (HHGear.Message or gm_Left) and not gm_Right
                  else HHGear.Message:= (HHGear.Message or gm_Right) and not gm_Left;
   HedgehogStep(HHGear);

   inc(BTSteps);
   if BTSteps = 11 then
      begin
      BTSteps:= 0;
      Gear.X:= HHGear.X + Gear.dX * cHHRadius * 2;
      Gear.Y:= HHGear.Y + Gear.dY * cHHRadius * 2;
      HHGear.State:= HHGear.State or gstNoDamage;
      AmmoShove(Gear, 3, 14);
      HHGear.State:= HHGear.State and not gstNoDamage
      end;

   if (HHGear.State and gstFalling) <> 0 then Gear.Timer:= 0
   end;

if b then
   DrawTunnel(HHGear.X - Gear.dX * cHHRadius, HHGear.Y - 4 - Gear.dY * cHHRadius + abs(Gear.dY) * 7,
              Gear.dX, Gear.dY,
              cHHRadius * 5, cHHRadius * 2 + 6);

if (Gear.Timer = 0) or ((HHGear.Message and gm_Attack) <> 0) then
   begin
   HHGear.Message:= 0;
   DeleteGear(Gear);
   AfterAttack
   end
end;

procedure doStepBlowTorch(Gear: PGear);
var HHGear: PGear;
begin
BTPrevAngle:= High(Longword);
BTSteps:= 0;
HHGear:= PHedgehog(Gear.Hedgehog).Gear;
HHGear.State:= HHGear.State and not gstAttacking;
HHGear.Message:= 0;
Gear.doStep:= doStepBlowTorchWork
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepRopeWork(Gear: PGear);
const flCheck: boolean = false;
var HHGear: PGear;
    len, cs, cc, tx, ty: Double;
    lx, ly: LongInt;

    procedure DeleteMe;
    begin
      with HHGear^ do
           begin
           Message:= Message and not gm_Attack;
           State:= State or gstFalling;
           end;
      DeleteGear(Gear);
      OnUsedAmmo(PHedgehog(HHGear.Hedgehog)^.Ammo);
      ApplyAmmoChanges(PHedgehog(HHGear.Hedgehog)^)
    end;

begin
HHGear:= PHedgehog(Gear.Hedgehog).Gear;

if ((HHGear.State and gstHHDriven) = 0)
   or (CheckGearDrowning(HHGear)) then
   begin
   DeleteMe;
   exit
   end;
Gear.dX:= HHGear.X - Gear.X;
Gear.dY:= HHGear.Y - Gear.Y;

if (Gear.Message and gm_Left  <> 0) then HHGear.dX:= HHGear.dX - 0.0002 else
if (Gear.Message and gm_Right <> 0) then HHGear.dX:= HHGear.dX + 0.0002;

if not TestCollisionYwithGear(HHGear, 1) then HHGear.dY:= HHGear.dY + cGravity;

cs:= Gear.dY + HHGear.dY;
cc:= Gear.dX + HHGear.dX;
len:= 1 / sqrt(sqr(cc)+sqr(cs));
cc:= cc * len;
cs:= cs * len;

flCheck:= not flCheck;
if flCheck then  // check whether rope needs dividing
   begin
   len:= Gear.Elasticity - 20;
   while len > 5 do
         begin
         tx:= cc*len;
         ty:= cs*len;
         lx:= round(Gear.X + tx) + hwSign(HHGear.dX);
         ly:= round(Gear.Y + ty) + hwSign(HHGear.dY);
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
      if GameTicks = 189245 then
         begin
         AddFileLog('tx = ' + floattostr(tx) + ' ty = ' + floattostr(ty));
         AddFileLog('Gear.X = ' + floattostr(Gear.X) + ' Gear.Y = ' + floattostr(Gear.Y));
         AddFileLog('HHGear.X = ' + floattostr(HHGear.X) + ' HHGear.Y = ' + floattostr(HHGear.Y));
         end;
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

cs:= Gear.dY + HHGear.dY;
cc:= Gear.dX + HHGear.dX;
len:= 1 / sqrt(sqr(cc)+sqr(cs));
cc:= cc * len;
cs:= cs * len;

HHGear.dX:= HHGear.X;
HHGear.dY:= HHGear.Y;

if ((Gear.Message and gm_Down) <> 0) and (Gear.Elasticity < Gear.Friction) then
   if not (TestCollisionXwithGear(HHGear, hwSign(Gear.dX))
        or TestCollisionYwithGear(HHGear, hwSign(Gear.dY))) then Gear.Elasticity:= Gear.Elasticity + 0.3;

if ((Gear.Message and gm_Up) <> 0) and (Gear.Elasticity > 30) then
   if not (TestCollisionXwithGear(HHGear, -hwSign(Gear.dX))
        or TestCollisionYwithGear(HHGear, -hwSign(Gear.dY))) then Gear.Elasticity:= Gear.Elasticity - 0.3;

HHGear.X:= Gear.X + cc*Gear.Elasticity;
HHGear.Y:= Gear.Y + cs*Gear.Elasticity;

HHGear.dX:= HHGear.X - HHGear.dX;
HHGear.dY:= HHGear.Y - HHGear.dY;

if TestCollisionXwithGear(HHGear, hwSign(HHGear.dX)) then
   HHGear.dX:= -0.6 * HHGear.dX;
if TestCollisionYwithGear(HHGear, hwSign(HHGear.dY)) then
   HHGear.dY:= -0.6 * HHGear.dY;

if (Gear.Message and gm_Attack) <> 0 then
   if (Gear.State and gsttmpFlag) <> 0 then DeleteMe else
else if (Gear.State and gsttmpFlag) = 0 then Gear.State:= Gear.State or gsttmpFlag;
end;


procedure doStepRopeAttach(Gear: PGear);
var HHGear: PGear;
    tx, ty, tt: Double;
begin
Gear.X:= Gear.X - Gear.dX;
Gear.Y:= Gear.Y - Gear.dY;
Gear.Elasticity:= Gear.Elasticity + 1.0;
HHGear:= PHedgehog(Gear.Hedgehog)^.Gear;
if (HHGear.State and gstFalling) <> 0 then
   if TestCollisionYwithGear(HHGear, 1) then
      begin
      HHGear.dY:= 0;
      CheckHHDamage(HHGear);
      HHGear.State:= HHGear.State and not (gstFalling or gstHHJumping);
      end else
      begin
      if TestCollisionXwithGear(HHGear, hwSign(HHGear.dX)) then HHGear.dX:= 0.0000001 * hwSign(HHGear.dX);
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
            if  TestCollisionXwithXYShift(Gear, round(tx), round(ty), hwSign(Gear.dX))
             or TestCollisionYwithXYShift(Gear, round(tx), round(ty), hwSign(Gear.dY)) then
                begin
                Gear.X:= Gear.X + tx;
                Gear.Y:= Gear.Y + ty;
                Gear.Elasticity:= tt;
                Gear.doStep:= doStepRopeWork;
                with HHGear^ do State:= State and not gstAttacking;
                tt:= 0
                end;
            tx:= tx + Gear.dX - Gear.dX;
            ty:= ty + Gear.dY - Gear.dY;
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
Gear.dX:= - Gear.dX;
Gear.dY:= - Gear.dY;
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
   if Gear.CollIndex < High(Longword) then DeleteCI(Gear);
   doStepFallingGear(Gear);
   if Gear.Active = false then
      begin
      if Gear.CollIndex = High(Longword) then AddGearCI(Gear);
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
doStepFallingGear(Gear);
AllInactive:= false;
if Gear.Timer mod 166 = 0 then inc(Gear.Tag);
if Gear.Timer = 0 then
   begin
   doMakeExplosion(round(Gear.X), round(Gear.Y), 75, EXPLAutoSound);
   DeleteGear(Gear);
   exit
   end;
dec(Gear.Timer);
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepCase(Gear: PGear);
var i, x, y: integer;
begin
if (Gear.Message and gm_Destroy) > 0 then
   begin
   DeleteGear(Gear);
   exit
   end;

if Gear.Damage > 0 then
   begin
   x:= round(Gear.X);
   y:= round(Gear.Y);
   DeleteGear(Gear);
   doMakeExplosion(x, y, 25, EXPLAutoSound);
   for i:= 0 to 63 do
       AddGear(x, y, gtFlame, 0);
   exit
   end;

if (Gear.dY <> 0) or (not TestCollisionYwithGear(Gear, 1)) then
   begin
   AllInactive:= false;
   Gear.dY:= Gear.dY + cGravity;
   Gear.Y:= Gear.Y + Gear.dY;
   if (Gear.dY < 0) and TestCollisionYwithGear(Gear, -1) then Gear.dY:= 0 else
   if (Gear.dY >= 0) and TestCollisionYwithGear(Gear, 1) then
      begin
      Gear.dY:= - Gear.dY * Gear.Elasticity;
      if Gear.dY > - 0.001 then Gear.dY:= 0
         else if Gear.dY < - 0.03 then PlaySound(sndGraveImpact);
      end;
   CheckGearDrowning(Gear);
   end;

if (Gear.CollIndex = High(Longword)) and (Gear.dY = 0) then AddGearCI(Gear)
   else if (Gear.CollIndex < High(Longword)) and (Gear.dY <> 0) then DeleteCI(Gear);
end;

////////////////////////////////////////////////////////////////////////////////
var thexchar: array[0..5] of record
                             oy, ny: integer;
                             team: PTeam;
                             end;
    thexchcnt: Longword;
    currsorter: PGear;

procedure doStepTeamHealthSorterWork(Gear: PGear);
var i: integer;
begin
AllInactive:= false;
dec(Gear.Timer);
if (Gear.Timer and 15) = 0 then
   for i:= 0 to Pred(thexchcnt) do
       with thexchar[i] do
            {$WARNINGS OFF}
            team.DrawHealthY:= ny + (oy - ny) * Gear.Timer div 640;
            {$WARNINGS ON}
if (Gear.Timer = 0) or (currsorter <> Gear) then
   begin
   if currsorter = Gear then currsorter:= nil;
   DeleteGear(Gear)
   end
end;

procedure doStepTeamHealthSorter(Gear: PGear);
var team: PTeam;
    i, t: Longword;
begin
AllInactive:= false;
team:= TeamsList;
i:= 0;
while team <> nil do
      begin
      thexchar[i].oy:= team.DrawHealthY;
      thexchar[i].team:= team;
      inc(i);
      team:= team.Next
      end;
thexchcnt:= i;
for i:= 1 to thexchcnt do
    for t:= 0 to thexchcnt - 2 do
        if thexchar[t].team.TeamHealthBarWidth > thexchar[Succ(t)].team.TeamHealthBarWidth then
           begin
           thexchar[5]:= thexchar[t];
           thexchar[t]:= thexchar[Succ(t)];
           thexchar[Succ(t)]:= thexchar[5]
           end;
t:= cScreenHeight - 4;
for i:= 0 to Pred(thexchcnt) do
    with thexchar[i] do
         begin
         dec(t, team.HealthRect.h + 2);
         ny:= t
         end;
Gear.Timer:= 640;
Gear.doStep:= doStepTeamHealthSorterWork;
currsorter:= Gear
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepShover(Gear: PGear);
var HHGear: PGear;
begin
HHGear:= PHedgehog(Gear.Hedgehog)^.Gear;
HHGear.State:= HHGear.State or gstNoDamage;
AmmoShove(Gear, 30, 115);
HHGear.State:= HHGear.State and not gstNoDamage;
DeleteGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFlame(Gear: PGear);
begin
AllInactive:= false;
if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear.dX:= Gear.dX + cWindSpeed;
   Gear.dY:= Gear.dY + cGravity;
   if abs(Gear.dX) > 0.12 then Gear.dX:= Gear.dX * 0.5;
   if Gear.dY > 0.12 then Gear.dY:= Gear.dY * 0.995;
   Gear.X:= Gear.X + Gear.dX;
   Gear.Y:= Gear.Y + Gear.dY;
   if Gear.Y > 1023 then
      begin
      DeleteGear(Gear);
      exit
      end
   end else begin
   if Gear.Timer > 0 then dec(Gear.Timer)
      else begin
      doMakeExplosion(round(Gear.X), round(Gear.Y), 2, 0);
      dec(Gear.Health);
      Gear.Timer:= 1250 - Gear.Angle * 12
      end
   end;

if (((GameTicks div 8) mod 64) = Gear.Angle) then
   AmmoFlameWork(Gear);

if Gear.Health = 0 then
   DeleteGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFirePunchWork(Gear: PGear);
var HHGear: PGear;
begin
AllInactive:= false;
if ((Gear.Message and gm_Destroy) <> 0) then
   begin
   DeleteGear(Gear);
   AfterAttack;
   exit
   end;

HHGear:= PHedgehog(Gear.Hedgehog).Gear;
if round(HHGear.Y) <= Gear.Tag - 2 then
   begin
   Gear.Tag:= round(HHGear.Y);
   DrawTunnel(HHGear.X - cHHRadius, HHGear.Y - 1, 0.5, 0.0, cHHRadius * 4, 2);
   HHGear.State:= HHGear.State or gstNoDamage;
   Gear.Y:= HHGear.Y;
   AmmoShove(Gear, 30, 40);
   HHGear.State:= HHGear.State and not gstNoDamage
   end;
   
HHGear.dY:= HHGear.dY + cGravity;
if HHGear.dY >= 0 then
   begin
   HHGear.State:= HHGear.State or gstFalling;
   DeleteGear(Gear);
   AfterAttack;
   exit
   end;
HHGear.Y:= HHGear.Y + HHGear.dY
end;

procedure doStepFirePunch(Gear: PGear);
var HHGear: PGear;
begin
AllInactive:= false;
HHGear:= PHedgehog(Gear.Hedgehog).Gear;
HHGear.X:= round(HHGear.X) - 0.5;
HHGear.dX:= 0.0000001 * hwSign(HHGear.dX);
HHGear.dY:= -0.30;

Gear.X:= HHGear.X;
Gear.dX:= hwSign(HHGear.dX)* 0.45;
Gear.dY:= -0.9;
Gear.doStep:= doStepFirePunchWork;
DrawTunnel(HHGear.X - cHHRadius, HHGear.Y + 1, 0.5, 0.0, cHHRadius * 4, 5);
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepParachute(Gear: PGear);
var HHGear: PGear;
begin
HHGear:= PHedgehog(Gear.Hedgehog).Gear;
HHGear.State:= HHGear.State and not gstAttacking;

if TestCollisionYwithGear(HHGear, 1)
   or ((HHGear.State and gstHHDriven) = 0)
   or CheckGearDrowning(HHGear) then
   begin
   with HHGear^ do
        begin
        Message:= 0;
        dx:= 0.0000001 * hwSign(dX);
        dY:= 0;
        State:= State and not (gstAttacking or gstAttacked);
        State:= State or gstFalling;
        end;
   DeleteGear(Gear);
   OnUsedAmmo(PHedgehog(HHGear.Hedgehog)^.Ammo);
   ApplyAmmoChanges(PHedgehog(HHGear.Hedgehog)^);
   exit
   end;

if not TestCollisionXwithGear(HHGear, hwSign(HHGear.dX)) then
   HHGear.X:= HHGear.X + cWindSpeed * 200;

if (Gear.Message and gm_Left) <> 0 then HHGear.X:= HHGear.X - cMaxWindSpeed * 40
else if (Gear.Message and gm_Right) <> 0 then HHGear.X:= HHGear.X + cMaxWindSpeed * 40;
if (Gear.Message and gm_Up) <> 0 then HHGear.Y:= HHGear.Y - cGravity * 40
else if (Gear.Message and gm_Down) <> 0 then HHGear.Y:= HHGear.Y + cGravity * 40;

HHGear.Y:= HHGear.Y + cGravity * 100;
end;

////////////////////////////////////////////////////////////////////////////////
const cAirPlaneSpeed = 1.4;
      cBombsDistance = 30;
      cBombsSpeed = 0.1;

procedure doStepAirAttackWork(Gear: PGear);
begin
AllInactive:= false;
Gear.X:= Gear.X + cAirPlaneSpeed;
if (Gear.Health > 0)and(Gear.X >= Gear.dX)and(Gear.X < Gear.dX + cAirPlaneSpeed) then
   begin
   dec(Gear.Health);
   case Gear.State of
        0: AddGear(round(Gear.X), round(Gear.Y), gtAirBomb, 0, cBombsSpeed, 0.0);
        1: AddGear(round(Gear.X), round(Gear.Y), gtMine, 0, cBombsSpeed, 0.0);
        end;
   Gear.dX:= Gear.dX + cBombsDistance
   end;
if Gear.X > 3072 then DeleteGear(Gear)
end;

procedure doStepAirAttack(Gear: PGear);
begin
AllInactive:= false;
Gear.X:= -1024;
Gear.Y:= -128;
Gear.dX:= TargetPoint.X -
          cBombsDistance * 5 / 2 - 
          cBombsSpeed * sqrt(2 * (TargetPoint.Y - Gear.Y) / cGravity);
Gear.Health:= 6;
Gear.doStep:= doStepAirAttackWork
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepAirBomb(Gear: PGear);
begin
AllInactive:= false;
doStepFallingGear(Gear);
if (Gear.State and gstCollision) <> 0 then
   begin
   doMakeExplosion(round(Gear.X), round(Gear.Y), 30, EXPLAutoSound);
   DeleteGear(Gear);
   exit
   end;
if (GameTicks and $3F) = 0 then
   AddGear(round(Gear.X), round(Gear.Y), gtSmokeTrace, 0)
end;


