(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004-2007 Andrey Korotaev <unC0Rr@gmail.com>
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
if cWaterLine < hwRound(Gear^.Y) + Gear^.Radius then
   begin
   CheckGearDrowning:= true;
   Gear^.State:= gstDrowning;
   Gear^.doStep:= @doStepDrowningGear;
   PlaySound(sndSplash, false)
   end else
   CheckGearDrowning:= false
end;

procedure CheckCollision(Gear: PGear);
begin
if TestCollisionXwithGear(Gear, hwSign(Gear^.X)) or TestCollisionYwithGear(Gear, hwSign(Gear^.Y))
   then Gear^.State:= Gear^.State or      gstCollision
   else Gear^.State:= Gear^.State and not gstCollision
end;

procedure CheckHHDamage(Gear: PGear);
var dmg: Longword;
begin
if _0_4 < Gear^.dY then
   begin
   dmg:= 1 + hwRound((hwAbs(Gear^.dY) - _0_4) * 70);
   inc(Gear^.Damage, dmg);
   AddDamageTag(hwRound(Gear^.X), hwRound(Gear^.Y) + cHHRadius, dmg, Gear);
   end
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
procedure CalcRotationDirAngle(Gear: PGear);
var dAngle: hwFloat;
begin
dAngle:= (hwAbs(Gear^.dX) + hwAbs(Gear^.dY)) * _0_1;
if not Gear^.dX.isNegative then Gear^.DirAngle:= Gear^.DirAngle + dAngle
                else Gear^.DirAngle:= Gear^.DirAngle - dAngle;
if Gear^.DirAngle.isNegative then Gear^.DirAngle:= Gear^.DirAngle + _16
else if _16 < Gear^.DirAngle then Gear^.DirAngle:= Gear^.DirAngle - _16
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepDrowningGear(Gear: PGear);
begin
AllInactive:= false;
Gear^.Y:= Gear^.Y + cDrownSpeed;
if hwRound(Gear^.Y) > Gear^.Radius + cWaterLine + cVisibleWater then DeleteGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFallingGear(Gear: PGear);
var isFalling: boolean;
begin
Gear^.State:= Gear^.State and not gstCollision;

if Gear^.dY.isNegative then
   begin
   isFalling:= true;
   if TestCollisionYwithGear(Gear, -1) then
      begin
      Gear^.dX:=   Gear^.dX * Gear^.Friction;
      Gear^.dY:= - Gear^.dY * Gear^.Elasticity;
      Gear^.State:= Gear^.State or gstCollision
      end
   end else
   if TestCollisionYwithGear(Gear, 1) then
      begin
      isFalling:= false;
      Gear^.dX:=   Gear^.dX * Gear^.Friction;
      Gear^.dY:= - Gear^.dY * Gear^.Elasticity;
      Gear^.State:= Gear^.State or gstCollision
      end else isFalling:= true;

if TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) then
   begin
   Gear^.dX:= - Gear^.dX * Gear^.Elasticity;
   Gear^.State:= Gear^.State or gstCollision
   end;

if isFalling then Gear^.dY:= Gear^.dY + cGravity;

Gear^.X:= Gear^.X + Gear^.dX;
Gear^.Y:= Gear^.Y + Gear^.dY;
CheckGearDrowning(Gear);
if (hwSqr(Gear^.dX) + hwSqr(Gear^.dY) < _0_0002) and
   (not isFalling) then Gear^.State:= Gear^.State and not gstMoving
                   else Gear^.State:= Gear^.State or      gstMoving
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepCloud(Gear: PGear);
begin
Gear^.X:= Gear^.X + cWindSpeed * 200 + Gear^.dX;
if hwRound(Gear^.Y) > -160 then Gear^.dY:= Gear^.dY - _1div50000
                           else Gear^.dY:= Gear^.dY + _1div50000;
Gear^.Y:= Gear^.Y + Gear^.dY;
if hwRound(Gear^.X) < -cScreenWidth - 256 then Gear^.X:= int2hwFloat(cScreenWidth + 2048) else
if hwRound(Gear^.X) > cScreenWidth + 2048 then Gear^.X:= int2hwFloat(-cScreenWidth - 256)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBomb(Gear: PGear);
var i: LongInt;
begin
AllInactive:= false;
doStepFallingGear(Gear);
dec(Gear^.Timer);
if Gear^.Timer = 0 then
   begin
   case Gear^.Kind of
        gtAmmo_Bomb: doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 50, EXPLAutoSound);
      gtClusterBomb: begin
                     doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 30, EXPLAutoSound);
                     for i:= 0 to 4 do
                         AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtCluster, 0, (getrandom - _0_5) * _0_2, (getrandom - _3) * _0_08, 0);
                     end
        end;
   DeleteGear(Gear);
   exit
   end;
CalcRotationDirAngle(Gear);
if (Gear^.State and (gstCollision or gstMoving)) = (gstCollision or gstMoving) then PlaySound(sndGrenadeImpact, false)
end;

procedure doStepCluster(Gear: PGear);
begin
AllInactive:= false;
doStepFallingGear(Gear);
if (Gear^.State and gstCollision) <> 0 then
   begin
   doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 20, EXPLAutoSound);
   DeleteGear(Gear);
   exit
   end;
if (GameTicks and $1F) = 0 then
   AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtSmokeTrace, 0, _0, _0, 0)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepGrenade(Gear: PGear);
begin
AllInactive:= false;
Gear^.dX:= Gear^.dX + cWindSpeed;
doStepFallingGear(Gear);
if (Gear^.State and gstCollision) <> 0 then
   begin
   doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 50, EXPLAutoSound);
   DeleteGear(Gear);
   exit
   end;
if (GameTicks and $3F) = 0 then
   AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtSmokeTrace, 0, _0, _0, 0)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepHealthTagWork(Gear: PGear);
begin
if Gear^.Kind = gtHealthTag then
   AllInactive:= false;
dec(Gear^.Timer);
Gear^.Y:= Gear^.Y + Gear^.dY;
if Gear^.Timer = 0 then
   begin
   if Gear^.Kind = gtHealthTag then
      PHedgehog(Gear^.Hedgehog)^.Gear^.Active:= true; // to let current hh die
   DeleteGear(Gear)
   end
end;

procedure doStepHealthTagWorkUnderWater(Gear: PGear);
begin
AllInactive:= false;
Gear^.Y:= Gear^.Y - _0_08;
if hwRound(Gear^.Y) < cWaterLine + 10 then
   DeleteGear(Gear)
end;

procedure doStepHealthTag(Gear: PGear);
var s: shortstring;
    font: THWFont;
begin
AllInactive:= false;
if Gear^.Kind = gtHealthTag then
   begin
   font:= fnt16;
   Gear^.dY:= -_0_08
   end else
   begin
   font:= fntSmall;
   Gear^.dY:= -_0_02
   end;

str(Gear^.State, s);
Gear^.Surf:= RenderString(s, PHedgehog(Gear^.Hedgehog)^.Team^.Color, font);
if hwRound(Gear^.Y) < cWaterLine then Gear^.doStep:= @doStepHealthTagWork
                                 else Gear^.doStep:= @doStepHealthTagWorkUnderWater;
Gear^.Y:= Gear^.Y - int2hwFloat(Gear^.Surf^.h)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepGrave(Gear: PGear);
begin
AllInactive:= false;
if Gear^.dY.isNegative then
   if TestCollisionY(Gear, -1) then Gear^.dY:= _0;

if not Gear^.dY.isNegative then
   if TestCollisionY(Gear, 1) then
      begin
      Gear^.dY:= - Gear^.dY * Gear^.Elasticity;
      if Gear^.dY > - _1div1024 then
         begin
         Gear^.Active:= false;
         exit
         end else if Gear^.dY < - _0_03 then PlaySound(sndGraveImpact, false)
      end;
Gear^.Y:= Gear^.Y + Gear^.dY;
CheckGearDrowning(Gear);
Gear^.dY:= Gear^.dY + cGravity
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepUFOWork(Gear: PGear);
var t: hwFloat;
    y: LongInt;
begin
AllInactive:= false;
t:= Distance(Gear^.dX, Gear^.dY);
Gear^.dX:= Gear^.Elasticity * (Gear^.dX + _0_000004 * (TargetPoint.X - hwRound(Gear^.X)));
Gear^.dY:= Gear^.Elasticity * (Gear^.dY + _0_000004 * (TargetPoint.Y - hwRound(Gear^.Y)));
t:= t / Distance(Gear^.dX, Gear^.dY);
Gear^.dX:= Gear^.dX * t;
Gear^.dY:= Gear^.dY * t;
Gear^.X:= Gear^.X + Gear^.dX;
Gear^.Y:= Gear^.Y + Gear^.dY;

if (GameTicks and $3F) = 0 then
   begin
   y:= hwRound(Gear^.Y);
   if y + Gear^.Radius < cWaterLine then
      AddGear(hwRound(Gear^.X), y, gtSmokeTrace, 0, _0, _0, 0);
   end;

CheckCollision(Gear);
dec(Gear^.Timer);
if ((Gear^.State and gstCollision) <> 0) or (Gear^.Timer = 0) then
   begin
   doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 50, EXPLAutoSound);
   DeleteGear(Gear);
   end;
end;

procedure doStepUFO(Gear: PGear);
begin
AllInactive:= false;
Gear^.X:= Gear^.X + Gear^.dX;
Gear^.Y:= Gear^.Y + Gear^.dY;
Gear^.dY:= Gear^.dY + cGravity;
CheckCollision(Gear);
if (Gear^.State and gstCollision) <> 0 then
   begin
   doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 50, EXPLAutoSound);
   DeleteGear(Gear);
   exit
   end;
dec(Gear^.Timer);
if Gear^.Timer = 0 then
   begin
   Gear^.Timer:= 5000;
   Gear^.doStep:= @doStepUFOWork
   end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepShotgunShot(Gear: PGear);
var i: LongWord;
begin
AllInactive:= false;
if Gear^.Timer > 0 then
   begin
   dec(Gear^.Timer);
   if Gear^.Timer = 0 then PlaySound(sndShotgunFire, false);
   exit
   end;
i:= 200;
repeat
Gear^.X:= Gear^.X + Gear^.dX;
Gear^.Y:= Gear^.Y + Gear^.dY;
CheckCollision(Gear);
if (Gear^.State and gstCollision) <> 0 then
   begin
   Gear^.X:= Gear^.X + Gear^.dX * 8;
   Gear^.Y:= Gear^.Y + Gear^.dY * 8;
   ShotgunShot(Gear);
   DeleteGear(Gear);
   AfterAttack;
   exit
   end;
dec(i)
until i = 0;
if (Gear^.X < _0) or (Gear^.Y < _0) or (Gear^.X > _2048) or (Gear^.Y > _1024) then
   begin
   DeleteGear(Gear);
   AfterAttack
   end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepDEagleShot(Gear: PGear);
var i, x, y: LongWord;
    oX, oY: hwFloat;
begin
AllInactive:= false;
i:= 80;
oX:= Gear^.X;
oY:= Gear^.Y;
repeat
  Gear^.X:= Gear^.X + Gear^.dX;
  Gear^.Y:= Gear^.Y + Gear^.dY;
  x:= hwRound(Gear^.X);
  y:= hwRound(Gear^.Y);
  if ((y and $FFFFFC00) = 0) and ((x and $FFFFF800) = 0)
     and (Land[y, x] <> 0) then inc(Gear^.Damage);
  if Gear^.Damage > 5 then AmmoShove(Gear, 7, 20);
  dec(i)
until (i = 0) or (Gear^.Damage > Gear^.Health);
if Gear^.Damage > 0 then
   begin
   DrawTunnel(oX, oY, Gear^.dX, Gear^.dY, 82 - i, 1);
   dec(Gear^.Health, Gear^.Damage);
   Gear^.Damage:= 0
   end;
if (Gear^.Health <= 0) or (Gear^.X < _0) or (Gear^.Y < _0) or (Gear^.X > _2048) or (Gear^.Y > _1024) then
   DeleteGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepActionTimer(Gear: PGear);
begin
dec(Gear^.Timer);
case Gear^.Kind of
    gtATStartGame: begin
                   AllInactive:= false;
                   if Gear^.Timer = 0 then
                      AddCaption(trmsg[sidStartFight], $FFFFFF, capgrpGameState);
                   end;
 gtATSmoothWindCh: begin
                   if Gear^.Timer = 0 then
                      begin
                      if WindBarWidth < Gear^.Tag then inc(WindBarWidth)
                         else if WindBarWidth > Gear^.Tag then dec(WindBarWidth);
                      if WindBarWidth <> Gear^.Tag then Gear^.Timer:= 10;
                      end
                   end;
   gtATFinishGame: begin
                   AllInactive:= false;
                   if Gear^.Timer = 0 then
                      begin
                      SendIPC('N');
                      SendIPC('q');
                      GameState:= gsExit
                      end
                   end;
     end;
if Gear^.Timer = 0 then DeleteGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepPickHammerWork(Gear: PGear);
var i, ei: LongInt;
    HHGear: PGear;
begin
AllInactive:= false;
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
dec(Gear^.Timer);
if (Gear^.Timer = 0)or((Gear^.Message and gm_Destroy) <> 0)or((HHGear^.State and gstHHDriven) = 0) then
   begin
   StopSound(sndPickhammer);
   DeleteGear(Gear);
   AfterAttack;
   exit
   end;
   
if (Gear^.Timer mod 33) = 0 then
   doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y) + 6, 6, EXPLDontDraw);

if (Gear^.Timer mod 47) = 0 then
   begin
   i:= hwRound(Gear^.X) - Gear^.Radius - LongInt(GetRandom(2));
   ei:= hwRound(Gear^.X) + Gear^.Radius + LongInt(GetRandom(2));
   while i <= ei do
         begin
         DrawExplosion(i, hwRound(Gear^.Y) + 3, 3);
         inc(i, 1)
         end;
   Gear^.X:= Gear^.X + Gear^.dX;
   Gear^.Y:= Gear^.Y + _1_9;
   SetAllHHToActive;
   end;
if TestCollisionYwithGear(Gear, 1) then
   begin
   Gear^.dY:= _0;
   SetLittle(HHGear^.dX);
   HHGear^.dY:= _0;
   end else
   begin
   Gear^.dY:= Gear^.dY + cGravity;
   Gear^.Y:= Gear^.Y + Gear^.dY;
   if Gear^.Y > _1024 then Gear^.Timer:= 1
   end;

Gear^.X:= Gear^.X + HHGear^.dX;
HHGear^.X:= Gear^.X;
HHGear^.Y:= Gear^.Y - int2hwFloat(cHHRadius);

if (Gear^.Message and gm_Attack) <> 0 then
   if (Gear^.State and gsttmpFlag) <> 0 then Gear^.Timer:= 1 else else
   if (Gear^.State and gsttmpFlag) = 0 then Gear^.State:= Gear^.State or gsttmpFlag;
if ((Gear^.Message and gm_Left) <> 0) then Gear^.dX:= - _0_3 else
   if ((Gear^.Message and gm_Right) <> 0) then Gear^.dX:= _0_3
                                          else Gear^.dX:= _0;
end;

procedure doStepPickHammer(Gear: PGear);
var i, y: LongInt;
    ar: TRangeArray;
begin
i:= 0;
y:= hwRound(Gear^.Y) - cHHRadius * 2;
while y < hwRound(Gear^.Y) do
   begin
   ar[i].Left := hwRound(Gear^.X) - Gear^.Radius - LongInt(GetRandom(2));
   ar[i].Right:= hwRound(Gear^.X) + Gear^.Radius + LongInt(GetRandom(2));
   inc(y, 2);
   inc(i)
   end;
DrawHLinesExplosions(@ar, 3, hwRound(Gear^.Y) - cHHRadius * 2, 2, Pred(i));
Gear^.dY:= PHedgehog(Gear^.Hedgehog)^.Gear^.dY;
PlaySound(sndPickhammer, true);
doStepPickHammerWork(Gear);
Gear^.doStep:= @doStepPickHammerWork
end;

////////////////////////////////////////////////////////////////////////////////
var BTPrevAngle, BTSteps: LongInt;

procedure doStepBlowTorchWork(Gear: PGear);
var HHGear: PGear;
    b: boolean;
begin
AllInactive:= false;
dec(Gear^.Timer);
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;

HedgehogChAngle(HHGear);

b:= false;

if abs(LongInt(HHGear^.Angle) - BTPrevAngle) > 7  then
   begin
   Gear^.dX:= SignAs(AngleSin(HHGear^.Angle) * _0_5, HHGear^.dX);
   Gear^.dY:= AngleCos(HHGear^.Angle) * ( - _0_5);
   BTPrevAngle:= HHGear^.Angle;
   b:= true
   end;

if Gear^.Timer mod cHHStepTicks = 0 then
   begin
   b:= true;
   if Gear^.dX.isNegative then HHGear^.Message:= (HHGear^.Message or gm_Left) and not gm_Right
                          else HHGear^.Message:= (HHGear^.Message or gm_Right) and not gm_Left;

   HHGear^.State:= HHGear^.State and not gstAttacking;
   HedgehogStep(HHGear);
   HHGear^.State:= HHGear^.State or gstAttacking;

   inc(BTSteps);
   if BTSteps = 7 then
      begin
      BTSteps:= 0;
      Gear^.X:= HHGear^.X + Gear^.dX * (cHHRadius + cBlowTorchC);
      Gear^.Y:= HHGear^.Y + Gear^.dY * (cHHRadius + cBlowTorchC);
      HHGear^.State:= HHGear^.State or gstNoDamage;
      AmmoShove(Gear, 2, 14);
      HHGear^.State:= HHGear^.State and not gstNoDamage
      end;

   if (HHGear^.State and gstMoving) <> 0 then Gear^.Timer:= 0
   end;

if b then
   DrawTunnel(HHGear^.X - Gear^.dX * cHHRadius, HHGear^.Y - _4 - Gear^.dY * cHHRadius + hwAbs(Gear^.dY) * 7,
              Gear^.dX, Gear^.dY,
              cHHRadius * 5, cHHRadius * 2 + 6);

if (Gear^.Timer = 0) or ((HHGear^.Message and gm_Attack) <> 0) then
   begin
   HHGear^.Message:= 0;
   DeleteGear(Gear);
   AfterAttack
   end
end;

procedure doStepBlowTorch(Gear: PGear);
var HHGear: PGear;
begin
BTPrevAngle:= High(LongInt);
BTSteps:= 0;
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
HHGear^.Message:= 0;
Gear^.doStep:= @doStepBlowTorchWork
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepRopeWork(Gear: PGear);
const flCheck: boolean = false;
var HHGear: PGear;
    len, cs, cc, tx, ty: hwFloat;
    lx, ly: LongInt;

    procedure DeleteMe;
    begin
      with HHGear^ do
           begin
           Message:= Message and not gm_Attack;
           State:= State or gstMoving;
           end;
      DeleteGear(Gear);
      OnUsedAmmo(PHedgehog(HHGear^.Hedgehog)^);
      ApplyAmmoChanges(PHedgehog(HHGear^.Hedgehog)^)
    end;

begin
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;

if ((HHGear^.State and gstHHDriven) = 0)
   or (CheckGearDrowning(HHGear)) then
   begin
   DeleteMe;
   exit
   end;
Gear^.dX:= HHGear^.X - Gear^.X;
Gear^.dY:= HHGear^.Y - Gear^.Y;

if (Gear^.Message and gm_Left  <> 0) then HHGear^.dX:= HHGear^.dX - _0_0002 else
if (Gear^.Message and gm_Right <> 0) then HHGear^.dX:= HHGear^.dX + _0_0002;

if not TestCollisionYwithGear(HHGear, 1) then HHGear^.dY:= HHGear^.dY + cGravity;

cs:= Gear^.dY + HHGear^.dY;
cc:= Gear^.dX + HHGear^.dX;
len:= _1 / Distance(cc, cs);
cc:= cc * len;
cs:= cs * len;

flCheck:= not flCheck;
if flCheck then  // check whether rope needs dividing
   begin
   len:= Gear^.Elasticity - _20;
   while len > _5 do
         begin
         tx:= cc*len;
         ty:= cs*len;
         lx:= hwRound(Gear^.X + tx) + hwSign(HHGear^.dX);
         ly:= hwRound(Gear^.Y + ty) + hwSign(HHGear^.dY);
         if ((ly and $FFFFFC00) = 0) and ((lx and $FFFFF800) = 0)and (Land[ly, lx] <> 0) then
           begin
           with RopePoints.ar[RopePoints.Count] do
                begin
                X:= Gear^.X;
                Y:= Gear^.Y;
                if RopePoints.Count = 0 then RopePoints.HookAngle:= DxDy2Angle32(Gear^.dY, Gear^.dX);
                b:= (cc * HHGear^.dY) > (cs * HHGear^.dX);
                dLen:= len
                end;
           Gear^.X:= Gear^.X + tx;
           Gear^.Y:= Gear^.Y + ty;
           inc(RopePoints.Count);
           Gear^.Elasticity:= Gear^.Elasticity - len;
           Gear^.Friction:= Gear^.Friction - len;
           break
           end;
         len:= len - _3
         end;
   end else
   if RopePoints.Count > 0 then // check whether the last dividing point could be removed
      begin
      tx:= RopePoints.ar[Pred(RopePoints.Count)].X;
      ty:= RopePoints.ar[Pred(RopePoints.Count)].Y;
      if RopePoints.ar[Pred(RopePoints.Count)].b xor ((tx - Gear^.X) * (ty - HHGear^.Y) > (tx - HHGear^.X) * (ty - Gear^.Y)) then
         begin
         dec(RopePoints.Count);
         Gear^.X:=RopePoints.ar[RopePoints.Count].X;
         Gear^.Y:=RopePoints.ar[RopePoints.Count].Y;
         Gear^.Elasticity:= Gear^.Elasticity + RopePoints.ar[RopePoints.Count].dLen;
         Gear^.Friction:= Gear^.Friction + RopePoints.ar[RopePoints.Count].dLen
         end
      end;

Gear^.dX:= HHGear^.X - Gear^.X;
Gear^.dY:= HHGear^.Y - Gear^.Y;

cs:= Gear^.dY + HHGear^.dY;
cc:= Gear^.dX + HHGear^.dX;
len:= _1 / Distance(cc, cs);
cc:= cc * len;
cs:= cs * len;

HHGear^.dX:= HHGear^.X;
HHGear^.dY:= HHGear^.Y;

if ((Gear^.Message and gm_Down) <> 0) and (Gear^.Elasticity < Gear^.Friction) then
   if not (TestCollisionXwithGear(HHGear, hwSign(Gear^.dX))
        or TestCollisionYwithGear(HHGear, hwSign(Gear^.dY))) then Gear^.Elasticity:= Gear^.Elasticity + _0_3;

if ((Gear^.Message and gm_Up) <> 0) and (Gear^.Elasticity > _30) then
   if not (TestCollisionXwithGear(HHGear, -hwSign(Gear^.dX))
        or TestCollisionYwithGear(HHGear, -hwSign(Gear^.dY))) then Gear^.Elasticity:= Gear^.Elasticity - _0_3;

HHGear^.X:= Gear^.X + cc*Gear^.Elasticity;
HHGear^.Y:= Gear^.Y + cs*Gear^.Elasticity;

HHGear^.dX:= HHGear^.X - HHGear^.dX;
HHGear^.dY:= HHGear^.Y - HHGear^.dY;

if TestCollisionXwithGear(HHGear, hwSign(HHGear^.dX)) then
   HHGear^.dX:= -_0_6 * HHGear^.dX;
if TestCollisionYwithGear(HHGear, hwSign(HHGear^.dY)) then
   HHGear^.dY:= -_0_6 * HHGear^.dY;

if (Gear^.Message and gm_Attack) <> 0 then
   if (Gear^.State and gsttmpFlag) <> 0 then DeleteMe else
else if (Gear^.State and gsttmpFlag) = 0 then Gear^.State:= Gear^.State or gsttmpFlag;
end;


procedure doStepRopeAttach(Gear: PGear);
var HHGear: PGear;
    tx, ty, tt: hwFloat;
begin
Gear^.X:= Gear^.X - Gear^.dX;
Gear^.Y:= Gear^.Y - Gear^.dY;
Gear^.Elasticity:= Gear^.Elasticity + _1;
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
DeleteCI(HHGear);
if (HHGear^.State and gstMoving) <> 0 then
   if TestCollisionYwithGear(HHGear, 1) then
      begin
      HHGear^.dY:= _0;
      CheckHHDamage(HHGear);
      HHGear^.State:= HHGear^.State and not (gstMoving or gstHHJumping);
      end else
      begin
      if TestCollisionXwithGear(HHGear, hwSign(HHGear^.dX)) then SetLittle(HHGear^.dX);
      HHGear^.X:= HHGear^.X + HHGear^.dX;
      HHGear^.Y:= HHGear^.Y + HHGear^.dY;
      Gear^.X:= Gear^.X + HHGear^.dX;
      Gear^.Y:= Gear^.Y + HHGear^.dY;
      HHGear^.dY:= HHGear^.dY + cGravity;
      tt:= Gear^.Elasticity;
      tx:= _0;
      ty:= _0;
      while tt > _20 do
            begin
            if  TestCollisionXwithXYShift(Gear, tx, hwRound(ty), -hwSign(Gear^.dX))
             or TestCollisionYwithXYShift(Gear, hwRound(tx), hwRound(ty), -hwSign(Gear^.dY)) then
                begin
                Gear^.X:= Gear^.X + tx;
                Gear^.Y:= Gear^.Y + ty;
                Gear^.Elasticity:= tt;
                Gear^.doStep:= @doStepRopeWork;
                with HHGear^ do State:= State and not gstAttacking;
                tt:= _0
                end;
            tx:= tx + Gear^.dX + Gear^.dX;
            ty:= ty + Gear^.dY + Gear^.dY;
            tt:= tt - _2;
            end;
      end;
CheckCollision(Gear);
if (Gear^.State and gstCollision) <> 0 then
   begin
   Gear^.doStep:= @doStepRopeWork;
   with HHGear^ do State:= State and not gstAttacking;
   if Gear^.Elasticity < _10 then
      Gear^.Elasticity:= _10000;
   end;

if (Gear^.Elasticity > Gear^.Friction) or ((Gear^.Message and gm_Attack) = 0) then
   begin
   with PHedgehog(Gear^.Hedgehog)^.Gear^ do
        begin
        State:= State and not gstAttacking;
        Message:= Message and not gm_Attack
        end;
   DeleteGear(Gear)
   end
end;

procedure doStepRope(Gear: PGear);
begin
Gear^.dX:= - Gear^.dX;
Gear^.dY:= - Gear^.dY;
Gear^.doStep:= @doStepRopeAttach
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSmokeTrace(Gear: PGear);
begin
inc(Gear^.Timer);
if Gear^.Timer > 64 then
   begin
   Gear^.Timer:= 0;
   dec(Gear^.State)
   end;
Gear^.dX:= Gear^.dX + cWindSpeed;
Gear^.X:= Gear^.X + Gear^.dX;
if Gear^.State = 0 then DeleteGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepExplosion(Gear: PGear);
begin
inc(Gear^.Timer);
if Gear^.Timer > 75 then
   begin
   inc(Gear^.State);
   Gear^.Timer:= 0;
   if Gear^.State > 5 then DeleteGear(Gear)
   end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepMine(Gear: PGear);
begin
if (Gear^.State and gstMoving) <> 0 then
   begin
   DeleteCI(Gear);
   doStepFallingGear(Gear);
   if (Gear^.State and gstMoving) = 0 then
      begin
      AddGearCI(Gear);
      Gear^.dX:= _0;
      Gear^.dY:= _0
      end;
   CalcRotationDirAngle(Gear);
   AllInactive:= false
   end;

if ((Gear^.State and gsttmpFlag) <> 0) then
   if ((Gear^.State and gstAttacking) = 0) then
      begin
      if ((GameTicks and $F) = 0) then
         if CheckGearNear(Gear, gtHedgehog, 46, 32) <> nil then Gear^.State:= Gear^.State or gstAttacking
      end else // gstAttacking <> 0
      begin
      AllInactive:= false;
      if (Gear^.Timer and $FF) = 0 then PlaySound(sndMineTick, false);
      if Gear^.Timer = 0 then
         begin
         doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 50, EXPLAutoSound);
         DeleteGear(Gear);
         exit
         end;
      dec(Gear^.Timer);
      end else // gsttmpFlag = 0
   if TurnTimeLeft = 0 then Gear^.State:= Gear^.State or gsttmpFlag;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepDynamite(Gear: PGear);
begin
doStepFallingGear(Gear);
AllInactive:= false;
if Gear^.Timer mod 166 = 0 then inc(Gear^.Tag);
if Gear^.Timer = 0 then
   begin
   doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 75, EXPLAutoSound);
   DeleteGear(Gear);
   exit
   end;
dec(Gear^.Timer);
end;

///////////////////////////////////////////////////////////////////////////////
procedure doStepCase(Gear: PGear);
var i, x, y: LongInt;
begin
if (Gear^.Message and gm_Destroy) > 0 then
   begin
   DeleteGear(Gear);
   FreeActionsList;
   with CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog] do
     if Gear <> nil then Gear^.Message:= Gear^.Message and not (gm_LJump or gm_HJump);
   exit
   end;

if Gear^.Damage > 0 then
   begin
   x:= hwRound(Gear^.X);
   y:= hwRound(Gear^.Y);
   DeleteGear(Gear);
   doMakeExplosion(x, y, 25, EXPLAutoSound);
   for i:= 0 to 63 do
       AddGear(x, y, gtFlame, 0, _0, _0, 0);
   exit
   end;

if (Gear^.dY.QWordValue <> 0) or (not TestCollisionYwithGear(Gear, 1)) then
   begin
   AllInactive:= false;
   Gear^.dY:= Gear^.dY + cGravity;
   Gear^.Y:= Gear^.Y + Gear^.dY;
   if (Gear^.dY.isNegative) and TestCollisionYwithGear(Gear, -1) then Gear^.dY:= _0 else
   if (not Gear^.dY.isNegative) and TestCollisionYwithGear(Gear, 1) then
      begin
      Gear^.dY:= - Gear^.dY * Gear^.Elasticity;
      if Gear^.dY > - _0_001 then Gear^.dY:= _0
         else if Gear^.dY < - _0_03 then PlaySound(sndGraveImpact, false);
      end;
   CheckGearDrowning(Gear);
   end;

if (Gear^.dY.QWordValue = 0) then AddGearCI(Gear)
   else if (Gear^.dY.QWordValue <> 0) then DeleteCI(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
var thexchar: array[0..5] of record
                             oy, ny: LongInt;
                             team: PTeam;
                             end;
    thexchcnt: Longword;
    currsorter: PGear;

procedure doStepTeamHealthSorterWork(Gear: PGear);
var i: LongInt;
begin
AllInactive:= false;
dec(Gear^.Timer);
if (Gear^.Timer and 15) = 0 then
   for i:= 0 to Pred(thexchcnt) do
       with thexchar[i] do
            {$WARNINGS OFF}
            team^.DrawHealthY:= ny + (oy - ny) * Gear^.Timer div 640;
            {$WARNINGS ON}
if (Gear^.Timer = 0) or (currsorter <> Gear) then
   begin
   if currsorter = Gear then currsorter:= nil;
   DeleteGear(Gear)
   end
end;

procedure doStepTeamHealthSorter(Gear: PGear);
var i, t: Longword;
begin
AllInactive:= false;
i:= 0;
for t:= 0 to Pred(TeamsCount) do
   with TeamsArray[t]^ do
      begin
      thexchar[i].oy:= DrawHealthY;
      thexchar[i].team:= TeamsArray[t];
      inc(i);
      end;

thexchcnt:= i;
for i:= 1 to thexchcnt do
    for t:= 0 to thexchcnt - 2 do
        if thexchar[t].team^.TeamHealthBarWidth > thexchar[Succ(t)].team^.TeamHealthBarWidth then
           begin
           thexchar[5]:= thexchar[t];
           thexchar[t]:= thexchar[Succ(t)];
           thexchar[Succ(t)]:= thexchar[5]
           end;
           
t:= cScreenHeight - 4;
for i:= 0 to Pred(thexchcnt) do
    with thexchar[i] do
         begin
         dec(t, team^.HealthRect.h + 2);
         ny:= t
         end;
         
Gear^.Timer:= 640;
Gear^.doStep:= @doStepTeamHealthSorterWork;
currsorter:= Gear
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepShover(Gear: PGear);
var HHGear: PGear;
begin
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
HHGear^.State:= HHGear^.State or gstNoDamage;
AmmoShove(Gear, 30, 115);
HHGear^.State:= HHGear^.State and not gstNoDamage;
DeleteGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFlame(Gear: PGear);
begin
AllInactive:= false;
if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear^.dX:= Gear^.dX + cWindSpeed;
   Gear^.dY:= Gear^.dY + cGravity;
   if hwAbs(Gear^.dX) > _0_1 then Gear^.dX:= Gear^.dX * _0_5;
   if Gear^.dY > _0_1 then Gear^.dY:= Gear^.dY * _0_995;
   Gear^.X:= Gear^.X + Gear^.dX;
   Gear^.Y:= Gear^.Y + Gear^.dY;
   if not (Gear^.Y < _1024) then
      begin
      DeleteGear(Gear);
      exit
      end
   end else begin
   if Gear^.Timer > 0 then dec(Gear^.Timer)
      else begin
//      doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 2, 0);
      dec(Gear^.Health);
      Gear^.Timer:= 1250 - Gear^.Angle * 12
      end
   end;

if (((GameTicks div 8) mod 64) = Gear^.Angle) then
   AmmoFlameWork(Gear);

if Gear^.Health = 0 then
   DeleteGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFirePunchWork(Gear: PGear);
var HHGear: PGear;
begin
AllInactive:= false;
if ((Gear^.Message and gm_Destroy) <> 0) then
   begin
   DeleteGear(Gear);
   AfterAttack;
   exit
   end;

HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
if hwRound(HHGear^.Y) <= Gear^.Tag - 2 then
   begin
   Gear^.Tag:= hwRound(HHGear^.Y);
   DrawTunnel(HHGear^.X - int2hwFloat(cHHRadius), HHGear^.Y - _1, _0_5, _0, cHHRadius * 4, 2);
   HHGear^.State:= HHGear^.State or gstNoDamage;
   Gear^.Y:= HHGear^.Y;
   AmmoShove(Gear, 30, 40);
   HHGear^.State:= HHGear^.State and not gstNoDamage
   end;

HHGear^.dY:= HHGear^.dY + cGravity;
if not (HHGear^.dY.isNegative) then
   begin
   HHGear^.State:= HHGear^.State or gstMoving;
   DeleteGear(Gear);
   AfterAttack;
   exit
   end;
HHGear^.Y:= HHGear^.Y + HHGear^.dY
end;

procedure doStepFirePunch(Gear: PGear);
var HHGear: PGear;
begin
AllInactive:= false;
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
DeleteCI(HHGear);
HHGear^.X:= int2hwFloat(hwRound(HHGear^.X)) - _0_5;
SetLittle(HHGear^.dX);
HHGear^.dY:= - _0_3;

Gear^.X:= HHGear^.X;
Gear^.dX:= SignAs(_0_45, HHGear^.dX);
Gear^.dY:= - _0_9;
Gear^.doStep:= @doStepFirePunchWork;
DrawTunnel(HHGear^.X - int2hwFloat(cHHRadius), HHGear^.Y + _1, _0_5, _0, cHHRadius * 4, 5);
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepParachute(Gear: PGear);
var HHGear: PGear;
begin
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
HHGear^.State:= HHGear^.State and not gstAttacking;
DeleteCI(HHGear);

inc(Gear^.Timer);

if TestCollisionYwithGear(HHGear, 1)
   or ((HHGear^.State and gstHHDriven) = 0)
   or CheckGearDrowning(HHGear) then
   begin
   with HHGear^ do
        begin
        Message:= 0;
        SetLittle(dx);
        dY:= _0;
        State:= State and not (gstAttacking or gstAttacked);
        State:= State or gstMoving;
        end;
   DeleteGear(Gear);
   if Gear^.Timer > 10 then
      begin
      OnUsedAmmo(PHedgehog(HHGear^.Hedgehog)^);
      ApplyAmmoChanges(PHedgehog(HHGear^.Hedgehog)^)
      end;
   exit
   end;

if not TestCollisionXwithGear(HHGear, hwSign(HHGear^.dX)) then
   HHGear^.X:= HHGear^.X + cWindSpeed * 200;

if (Gear^.Message and gm_Left) <> 0 then HHGear^.X:= HHGear^.X - cMaxWindSpeed * 40
else if (Gear^.Message and gm_Right) <> 0 then HHGear^.X:= HHGear^.X + cMaxWindSpeed * 40;
if (Gear^.Message and gm_Up) <> 0 then HHGear^.Y:= HHGear^.Y - cGravity * 40
else if (Gear^.Message and gm_Down) <> 0 then HHGear^.Y:= HHGear^.Y + cGravity * 40;

HHGear^.Y:= HHGear^.Y + cGravity * 100;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepAirAttackWork(Gear: PGear);
begin
AllInactive:= false;
Gear^.X:= Gear^.X + cAirPlaneSpeed * Gear^.Tag;
if (Gear^.Health > 0)and(not (Gear^.X < Gear^.dX))and(Gear^.X < Gear^.dX + cAirPlaneSpeed) then
   begin
   dec(Gear^.Health);
   case Gear^.State of
        0: FollowGear:= AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtAirBomb, 0, cBombsSpeed * Gear^.Tag, _0, 0);
        1: FollowGear:= AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtMine,    0, cBombsSpeed * Gear^.Tag, _0, 0);
        end;
   Gear^.dX:= Gear^.dX + int2hwFloat(30 * Gear^.Tag)
   end;
if (hwRound(Gear^.X) > 3072) or (hwRound(Gear^.X) < -1024) then DeleteGear(Gear)
end;

procedure doStepAirAttack(Gear: PGear);
begin
AllInactive:= false;

if Gear^.X.QWordValue = 0 then Gear^.Tag:=  1
                          else Gear^.Tag:= -1;
Gear^.X:= _1024 - _2048 * Gear^.Tag;
Gear^.Y:= -_128;
Gear^.dX:= int2hwFloat(TargetPoint.X - 5 * Gear^.Tag * 15);

if int2hwFloat(TargetPoint.Y) - Gear^.Y > _0 then
   Gear^.dX:= Gear^.dX - cBombsSpeed * hwSqrt((int2hwFloat(TargetPoint.Y) - Gear^.Y) * 2 / cGravity) * Gear^.Tag;
addfilelog('attack: x = '+floattostr(gear^.dx));

Gear^.Health:= 6;
Gear^.doStep:= @doStepAirAttackWork
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepAirBomb(Gear: PGear);
begin
AllInactive:= false;
doStepFallingGear(Gear);
if (Gear^.State and gstCollision) <> 0 then
   begin
   doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 30, EXPLAutoSound);
   DeleteGear(Gear);
   exit
   end;
if (GameTicks and $3F) = 0 then
   AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtSmokeTrace, 0, _0, _0, 0)
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepGirder(Gear: PGear);
var HHGear: PGear;
begin
AllInactive:= false;

HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
if not TryPlaceOnLand(TargetPoint.X - SpritesData[sprAmGirder].Width div 2,
                      TargetPoint.Y - SpritesData[sprAmGirder].Height div 2,
                      sprAmGirder, Gear^.State, true) then
        begin
        HHGear^.Message:= HHGear^.Message and not gm_Attack;
        HHGear^.State:= HHGear^.State and not gstAttacking;
        HHGear^.State:= HHGear^.State or gstHHChooseTarget;
        DeleteGear(Gear);
        isCursorVisible:= true
        end
   else begin
        DeleteGear(Gear);
        AfterAttack
        end;
TargetPoint.X:= NoPointX
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepTeleportAfter(Gear: PGear);
var HHGear: PGear;
begin
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
HHGear^.Y:= HHGear^.Y + HHGear^.dY;
HHGear^.dY:= HHGear^.dY + cGravity;
if TestCollisionYwithGear(HHGear, 1) then
   begin
   DeleteGear(Gear);
   AfterAttack
   end
end;

procedure doStepTeleport(Gear: PGear);
var HHGear: PGear;
begin
AllInactive:= false;

HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
if not TryPlaceOnLand(TargetPoint.X - SpritesData[sprHHTelepMask].Width div 2,
                      TargetPoint.Y - SpritesData[sprHHTelepMask].Height div 2,
                      sprHHTelepMask, 0, false) then
        begin
        HHGear^.Message:= HHGear^.Message and not gm_Attack;
        HHGear^.State:= HHGear^.State and not gstAttacking;
        HHGear^.State:= HHGear^.State or gstHHChooseTarget;
        DeleteGear(Gear);
        isCursorVisible:= true
        end
   else begin
        DeleteCI(HHGear);
        Gear^.doStep:= @doStepTeleportAfter;
        HHGear^.X:= int2hwFloat(TargetPoint.X);
        HHGear^.Y:= int2hwFloat(TargetPoint.Y);
        HHGear^.State:= HHGear^.State or gstMoving
        end;
TargetPoint.X:= NoPointX
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSwitcherWork(Gear: PGear);
var HHGear: PGear;
    th: LongInt;
    Msg, State: Longword;
begin
AllInactive:= false;

if ((Gear^.Message and not gm_Switch) <> 0) or (TurnTimeLeft = 0) then
   begin
   HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
   Msg:= Gear^.Message and not gm_Switch;
   DeleteGear(Gear);
   OnUsedAmmo(PHedgehog(HHGear^.Hedgehog)^);
   ApplyAmmoChanges(PHedgehog(HHGear^.Hedgehog)^);

   HHGear:= CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear;
   ApplyAmmoChanges(PHedgehog(HHGear^.Hedgehog)^);
   HHGear^.Message:= Msg;
   exit
   end;

if (Gear^.Message and gm_Switch) <> 0 then
   begin
   HHGear:= CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear;
   HHGear^.Message:= HHGear^.Message and not gm_Switch;
   State:= HHGear^.State;
   HHGear^.State:= 0;
   HHGear^.Active:= false;
   HHGear^.Z:= cHHZ;
   RemoveGearFromList(HHGear);
   InsertGearToList(HHGear);

   th:= CurrentTeam^.CurrHedgehog;
   repeat
     CurrentTeam^.CurrHedgehog:= Succ(CurrentTeam^.CurrHedgehog) mod (cMaxHHIndex + 1);
   until (CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear <> nil) or (CurrentTeam^.CurrHedgehog = th);

   HHGear:= CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear;
   HHGear^.State:= State;
   HHGear^.Active:= true;
   FollowGear:= HHGear;
   HHGear^.Z:= cCurrHHZ;
   RemoveGearFromList(HHGear);
   InsertGearToList(HHGear);
   Gear^.X:= HHGear^.X;
   Gear^.Y:= HHGear^.Y
   end;
end;

procedure doStepSwitcher(Gear: PGear);
var HHGear: PGear;
begin
Gear^.doStep:= @doStepSwitcherWork;

HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
with HHGear^ do
     begin
     State:= State and not gstAttacking;
     Message:= Message and not gm_Attack
     end
end;
