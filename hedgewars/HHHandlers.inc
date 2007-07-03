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

////////////////////////////////////////////////////////////////////////////////
procedure Attack(Gear: PGear);
var xx, yy: hwFloat;
begin
with Gear^,
     PHedgehog(Gear^.Hedgehog)^ do
     begin
     if ((State and gstHHDriven) <> 0)and
        ((State and (gstAttacked or gstHHChooseTarget)) = 0)and
        (((State and gstMoving) = 0)or((Ammo^[CurSlot, CurAmmo].Propz and ammoprop_AttackInMove) <> 0))and
          ((TargetPoint.X <> NoPointX) or ((Ammo^[CurSlot, CurAmmo].Propz and ammoprop_NeedTarget) = 0)) then
        begin
        State:= State or gstAttacking;
        if Power = cMaxPower then Message:= Message and not gm_Attack
        else if (Ammo^[CurSlot, CurAmmo].Propz and ammoprop_Power) = 0 then Message:= Message and not gm_Attack
        else begin
             if Power = 0 then
                begin
                AttackBar:= CurrentTeam^.AttackBar;
                PlaySound(sndThrowPowerUp, false)
                end;
             inc(Power)
             end;
        if ((Message and gm_Attack) <> 0) then exit;

        if (Ammo^[CurSlot, CurAmmo].Propz and ammoprop_Power) <> 0 then
           begin
           StopSound(sndThrowPowerUp);
           PlaySound(sndThrowRelease, false);
           end;
        xx:= SignAs(AngleSin(Angle), dX);
        yy:= -AngleCos(Angle); 
             case Ammo^[CurSlot, CurAmmo].AmmoType of
                      amGrenade: FollowGear:= AddGear(hwRound(X), hwRound(Y), gtAmmo_Bomb,    0, xx*Power/cPowerDivisor, yy*Power/cPowerDivisor, Ammo^[CurSlot, CurAmmo].Timer);
                  amClusterBomb: FollowGear:= AddGear(hwRound(X), hwRound(Y), gtClusterBomb,  0, xx*Power/cPowerDivisor, yy*Power/cPowerDivisor, Ammo^[CurSlot, CurAmmo].Timer);
                      amBazooka: FollowGear:= AddGear(hwRound(X), hwRound(Y), gtAmmo_Grenade, 0, xx*Power/cPowerDivisor, yy*Power/cPowerDivisor, 0);
                          amUFO: FollowGear:= AddGear(hwRound(X), hwRound(Y), gtUFO,          0, xx*Power/cPowerDivisor, yy*Power/cPowerDivisor, 0);
                      amShotgun: begin
                                 PlaySound(sndShotgunReload, false);
                                 CurAmmoGear:= AddGear(hwRound(X), hwRound(Y), gtShotgunShot,  0, xx * _0_5, yy * _0_5, 0);
                                 end;
                   amPickHammer: CurAmmoGear:= AddGear(hwRound(Gear^.X), hwRound(Gear^.Y) + cHHRadius, gtPickHammer, 0, _0, _0, 0);
                         amSkip: TurnTimeLeft:= 0;
                         amRope: CurAmmoGear:= AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtRope, 0, xx, yy, 0);
                         amMine: AddGear(hwRound(X) + hwSign(dX) * 7, hwRound(Y), gtMine, 0, SignAs(_0_02, dX), _0, 3000);
                       amDEagle: AddGear(hwRound(X + xx * cHHRadius), hwRound(Y + yy * cHHRadius), gtDEagleShot, 0, xx * _0_5, yy * _0_5, 0);
                     amDynamite: AddGear(hwRound(X) + hwSign(dX) * 7, hwRound(Y), gtDynamite, 0, SignAs(_0_03, dX), _0, 5000);
                  amBaseballBat: AddGear(hwRound(X) + hwSign(dX) * 10, hwRound(Y), gtShover, 0, xx * _0_5, yy * _0_5, 0)^.Radius:= 20;
                    amFirePunch: CurAmmoGear:= AddGear(hwRound(X) + hwSign(dX) * 10, hwRound(Y), gtFirePunch, 0, _0, _0, 0);
                    amParachute: CurAmmoGear:= AddGear(hwRound(X), hwRound(Y), gtParachute, 0, _0, _0, 0);
                    amAirAttack: AddGear(Ammo^[CurSlot, CurAmmo].Pos, 0, gtAirAttack, 0, _0, _0, 0);
                   amMineStrike: AddGear(Ammo^[CurSlot, CurAmmo].Pos, 0, gtAirAttack, 1, _0, _0, 0);
                    amBlowTorch: CurAmmoGear:= AddGear(hwRound(X), hwRound(Y), gtBlowTorch, 0, SignAs(_0_5, dX), _0, 0);
                       amGirder: CurAmmoGear:= AddGear(0, 0, gtGirder, Ammo^[CurSlot, CurAmmo].Pos, _0, _0, 0);
                     amTeleport: CurAmmoGear:= AddGear(0, 0, gtTeleport, 0, _0, _0, 0);
                       amSwitch: CurAmmoGear:= AddGear(hwRound(X), hwRound(Y), gtSwitcher, 0, _0, _0, 0);
                  end;
        Power:= 0;
        if CurAmmoGear <> nil then
           begin
           Message:= Message or gm_Attack;
           CurAmmoGear^.Message:= Message
           end else begin
           if not CurrentTeam^.ExtDriven and
             ((Ammo^[CurSlot, CurAmmo].Propz and ammoprop_Power) <> 0) then SendIPC('a');
           AfterAttack
           end
        end else Message:= Message and not gm_Attack
     end
end;

procedure AfterAttack;
begin
with CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear^,
     CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog] do
     begin
        Inc(AttacksNum);
        State:= State and not gstAttacking;
        if Ammo^[CurSlot, CurAmmo].NumPerTurn >= AttacksNum then isInMultiShoot:= true
           else begin
           TurnTimeLeft:= Ammoz[Ammo^[CurSlot, CurAmmo].AmmoType].TimeAfterTurn;
           State:= State or gstAttacked;
           OnUsedAmmo(CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog])
           end;
     AttackBar:= 0;
     end
end;

////////////////////////////////////////////////////////////////////////////////
procedure PickUp(HH, Gear: PGear);
var s: shortstring;
    a: TAmmoType;
begin
Gear^.Message:= gm_Destroy;
case Gear^.Pos of
       posCaseAmmo: begin
                    a:= TAmmoType(Gear^.State);
                    AddAmmo(PHedgehog(HH^.Hedgehog), a);
                    s:= trammo[Ammoz[a].NameId] + '(+' + IntToStr(Ammoz[a].NumberInCase) + ')';
                    AddCaption(s, PHedgehog(HH^.Hedgehog)^.Team^.Clan^.Color, capgrpAmmoinfo);
                    end;
     posCaseHealth: begin
                    inc(HH^.Health, Gear^.Health);
                    str(Gear^.Health, s);
                    s:= '+' + s;
                    AddCaption(s, PHedgehog(HH^.Hedgehog)^.Team^.Clan^.Color, capgrpAmmoinfo);
                    RenderHealth(PHedgehog(HH^.Hedgehog)^);
                    RecountTeamHealth(PHedgehog(HH^.Hedgehog)^.Team)
                    end;
     end
end;

const StepTicks: LongWord = 0;

procedure HedgehogStep(Gear: PGear);
var PrevdX: LongInt;
begin
if ((Gear^.State and (gstAttacking or gstMoving)) = 0) then
   begin
   if isCursorVisible then
      with PHedgehog(Gear^.Hedgehog)^ do
        with Ammo^[CurSlot, CurAmmo] do
          begin
          if (Gear^.Message and gm_Left  ) <> 0 then
             Pos:= (Pos + Ammoz[AmmoType].PosCount - 1) mod Ammoz[AmmoType].PosCount
          else
          if (Gear^.Message and gm_Right ) <> 0 then
             Pos:= (Pos + 1) mod Ammoz[AmmoType].PosCount
          else exit;
          StepTicks:= 200;
          exit
          end;

   if ((Gear^.Message and gm_LJump ) <> 0) then
      begin
      Gear^.Message:= Gear^.Message and not gm_LJump;
      DeleteCI(Gear);
      if not TestCollisionYwithGear(Gear, -1) then
         if not TestCollisionXwithXYShift(Gear, _0, -2, hwSign(Gear^.dX)) then Gear^.Y:= Gear^.Y - _2 else
         if not TestCollisionXwithXYShift(Gear, _0, -1, hwSign(Gear^.dX)) then Gear^.Y:= Gear^.Y - _1;
      if not (TestCollisionXwithGear(Gear, hwSign(Gear^.dX))
         or   TestCollisionYwithGear(Gear, -1)) then
         begin
         Gear^.dY:= -_0_15;
         Gear^.dX:= SignAs(_0_15, Gear^.dX);
         Gear^.State:= Gear^.State or gstMoving or gstHHJumping;
         exit
         end;
      end;

   if ((Gear^.Message and gm_HJump ) <> 0) then
      begin
      DeleteCI(Gear);
      Gear^.Message:= Gear^.Message and not gm_HJump;
      if not TestCollisionYwithGear(Gear, -1) then
         begin
         Gear^.dY:= -_0_2;
         SetLittle(Gear^.dX);
         Gear^.State:= Gear^.State or gstMoving or gstHHJumping;
         exit
         end;
      end;

   PrevdX:= hwSign(Gear^.dX);
   if (Gear^.Message and gm_Left  )<>0 then Gear^.dX:= -cLittle else
   if (Gear^.Message and gm_Right )<>0 then Gear^.dX:=  cLittle else exit;

   StepTicks:= cHHStepTicks;
   if PrevdX <> hwSign(Gear^.dX) then exit;
   DeleteCI(Gear); // after exit!!    ^^^^
   
   PHedgehog(Gear^.Hedgehog)^.visStepPos:= (PHedgehog(Gear^.Hedgehog)^.visStepPos + 1) and 7;
   if TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) then
      begin
      if not (TestCollisionXwithXYShift(Gear, _0, -6, hwSign(Gear^.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear^.Y:= Gear^.Y - _1;
      if not (TestCollisionXwithXYShift(Gear, _0, -5, hwSign(Gear^.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear^.Y:= Gear^.Y - _1;
      if not (TestCollisionXwithXYShift(Gear, _0, -4, hwSign(Gear^.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear^.Y:= Gear^.Y - _1;
      if not (TestCollisionXwithXYShift(Gear, _0, -3, hwSign(Gear^.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear^.Y:= Gear^.Y - _1;
      if not (TestCollisionXwithXYShift(Gear, _0, -2, hwSign(Gear^.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear^.Y:= Gear^.Y - _1;
      if not (TestCollisionXwithXYShift(Gear, _0, -1, hwSign(Gear^.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear^.Y:= Gear^.Y - _1;
      end;
   if not TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) then Gear^.X:= Gear^.X + SignAs(_1, Gear^.dX);

   SetAllHHToActive;

   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear^.Y:= Gear^.Y + _1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear^.Y:= Gear^.Y + _1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear^.Y:= Gear^.Y + _1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear^.Y:= Gear^.Y + _1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear^.Y:= Gear^.Y + _1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear^.Y:= Gear^.Y + _1;
   if not TestCollisionYwithGear(Gear, 1) then
      begin
      Gear^.Y:= Gear^.Y - _6;
      Gear^.dY:= _0;
      Gear^.State:= Gear^.State or gstMoving;
      exit
      end;
   end
   end
   end
   end
   end
   end;
   AddGearCI(Gear)
   end
end;

procedure HedgehogChAngle(Gear: PGear);
begin
if ((Gear^.State and gstMoving) = 0) then
   if (Gear^.Message and gm_Up    )<>0 then if Gear^.Angle > CurMinAngle then dec(Gear^.Angle)
   else else
   if (Gear^.Message and gm_Down  )<>0 then if Gear^.Angle < CurMaxAngle then inc(Gear^.Angle);
end;

procedure doStepHedgehog(Gear: PGear); forward;
////////////////////////////////////////////////////////////////////////////////
procedure doStepHedgehogMoving(Gear: PGear);
var isFalling: boolean;
begin
isFalling:= not TestCollisionYKick(Gear, 1);
if isFalling then
   begin
   if (Gear^.dY.isNegative) and TestCollisionYKick(Gear, -1) then Gear^.dY:= _0;
   Gear^.State:= Gear^.State or gstMoving;
   Gear^.dY:= Gear^.dY + cGravity
   end else
   begin
   if ((hwAbs(Gear^.dX) + hwAbs(Gear^.dY)) < _0_55)
      and ((Gear^.State and gstHHJumping) <> 0) then SetLittle(Gear^.dX);

   if not Gear^.dY.isNegative then
      begin
      CheckHHDamage(Gear);
      Gear^.State:= Gear^.State and not (gstHHJumping or gstHHHJump);
      Gear^.dY:= _0;
      end else Gear^.dY:= Gear^.dY + cGravity;

   if ((Gear^.State and gstMoving) <> 0) then Gear^.dX:= Gear^.dX * Gear^.Friction
   end;

if (Gear^.State <> 0) then DeleteCI(Gear);
                
if (Gear^.State and gstMoving) <> 0 then
   if TestCollisionXKick(Gear, hwSign(Gear^.dX)) then
      if not isFalling then
         if hwAbs(Gear^.dX) > _0_01 then
            if not TestCollisionXwithXYShift(Gear, int2hwFloat(hwSign(Gear^.dX)) - Gear^.dX, -1, hwSign(Gear^.dX)) then begin Gear^.X:= Gear^.X + Gear^.dX; Gear^.dX:= Gear^.dX * _0_96; Gear^.Y:= Gear^.Y - _1 end else
            if not TestCollisionXwithXYShift(Gear, int2hwFloat(hwSign(Gear^.dX)) - Gear^.dX, -2, hwSign(Gear^.dX)) then begin Gear^.X:= Gear^.X + Gear^.dX; Gear^.dX:= Gear^.dX * _0_93; Gear^.Y:= Gear^.Y - _2 end else
            if not TestCollisionXwithXYShift(Gear, int2hwFloat(hwSign(Gear^.dX)) - Gear^.dX, -3, hwSign(Gear^.dX)) then begin Gear^.X:= Gear^.X + Gear^.dX; Gear^.dX:= Gear^.dX * _0_9 ; Gear^.Y:= Gear^.Y - _3 end else
            if not TestCollisionXwithXYShift(Gear, int2hwFloat(hwSign(Gear^.dX)) - Gear^.dX, -4, hwSign(Gear^.dX)) then begin Gear^.X:= Gear^.X + Gear^.dX; Gear^.dX:= Gear^.dX * _0_87; Gear^.Y:= Gear^.Y - _4 end else
            if not TestCollisionXwithXYShift(Gear, int2hwFloat(hwSign(Gear^.dX)) - Gear^.dX, -5, hwSign(Gear^.dX)) then begin Gear^.X:= Gear^.X + Gear^.dX; Gear^.dX:= Gear^.dX * _0_84; Gear^.Y:= Gear^.Y - _5 end else
            if hwAbs(Gear^.dX) > _0_02 then Gear^.dX:= -Gear^.Elasticity * Gear^.dX
                                   else begin
                                        Gear^.State:= Gear^.State and not gstMoving;
                                        SetLittle(Gear^.dX)
                                        end
            else begin
                 Gear^.State:= Gear^.State and not gstMoving;
                 SetLittle(Gear^.dX)
                 end
         else if hwAbs(Gear^.dX) > cLittle then Gear^.dX:= -Gear^.Elasticity * Gear^.dX
                                           else SetLittle(Gear^.dX);

if (not isFalling) and
   (hwAbs(Gear^.dX) + hwAbs(Gear^.dY) < _0_03) then
   begin
   Gear^.State:= Gear^.State and not gstMoving;
   SetLittle(Gear^.dX);
   Gear^.dY:= _0
   end else Gear^.State:= Gear^.State or gstMoving;

if (Gear^.State and gstMoving) <> 0 then
   begin
   Gear^.State:= Gear^.State and not gstAnimation;
   Gear^.X:= Gear^.X + Gear^.dX;
   Gear^.Y:= Gear^.Y + Gear^.dY;
   if (not Gear^.dY.isNegative) and
      (not TestCollisionYKick(Gear, 1)) and
       TestCollisionYwithXYShift(Gear, 0, 1, 1) then
      begin
      CheckHHDamage(Gear);
      Gear^.dY:= _0;
      Gear^.Y:= Gear^.Y + _1
      end;
   CheckGearDrowning(Gear)
   end
end;

procedure doStepHedgehogDriven(Gear: PGear);
var t: PGear;
begin
if isInMultiShoot and (Gear^.Damage = 0) then
   begin
   exit
   end;
AllInactive:= false;

if (TurnTimeLeft = 0) or (Gear^.Damage > 0) then
   begin
   TurnTimeLeft:= 0;
   Gear^.State:= Gear^.State and not gstHHDriven;
   if Gear^.Damage > 0 then
      Gear^.State:= Gear^.State and not (gstHHJumping or gstHHHJump);
   exit
   end;

if ((Gear^.State and gstMoving) <> 0)
   or (StepTicks = cHHStepTicks)
   or (CurAmmoGear <> nil) then // we're moving
   begin
   // check for case with ammo
   t:= CheckGearNear(Gear, gtCase, 36, 36);
   if t <> nil then
      PickUp(Gear, t)
   end;

if CurAmmoGear <> nil then
   begin
   CurAmmoGear^.Message:= Gear^.Message;
   exit
   end;

if ((Gear^.Message and gm_Attack) <> 0) or
   ((Gear^.State and gstAttacking) <> 0) then Attack(Gear);

if (Gear^.State and gstMoving) <> 0 then
   begin
   if ((Gear^.Message and gm_HJump) <> 0) and
      ((Gear^.State and gstHHJumping) <> 0) and
      ((Gear^.State and gstHHHJump) = 0) then
      if (not (hwAbs(Gear^.dX) > cLittle)) and (Gear^.dY < -_0_02) then
         begin
         Gear^.State:= Gear^.State or gstHHHJump or gstMoving;
         Gear^.dY:= -_0_25;
         Gear^.dX:= SignAs(_0_02, Gear^.dX)
         end;
   Gear^.Message:= Gear^.Message and not (gm_LJump or gm_HJump);

   if ((Gear^.State and gstHHJumping) <> 0) and
      TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) then SetLittle(Gear^.dX);

   doStepHedgehogMoving(Gear);

   if (Gear^.State and gstMoving) = 0 then
      begin
      AddGearCI(Gear);
      StepTicks:= 350
      end;
   exit
   end;

   HedgehogChAngle(Gear);
   if StepTicks > 0 then dec(StepTicks);
   if (StepTicks = 0) then HedgehogStep(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepHedgehogFree(Gear: PGear);
var prevState: Longword;
begin
prevState:= Gear^.State;

doStepHedgehogMoving(Gear);

if (Gear^.State and gstMoving) = 0 then
   if Gear^.Health = 0 then
      begin
      if AllInactive then
         begin
         Gear^.State:= Gear^.State or gstNoDamage;
         doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 30, EXPLAutoSound);
         AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtGrave, 0, _0, _0, 0)^.Hedgehog:= Gear^.Hedgehog;
         DeleteGear(Gear);
         SetAllToActive
         end;
      AllInactive:= false;
      exit
      end;

AllInactive:= false;

if ((Gear^.State and gstMoving) = 0) then
   if ((Gear^.State and gstAnimation) = 0) and
      (prevState <> Gear^.State) then
      begin
      Gear^.State:= gstAnimation;
      Gear^.Timer:= 150
      end else
      begin
      if Gear^.Timer = 0 then
         begin
         Gear^.State:= 0;
         Gear^.Active:= false;
         AddGearCI(Gear);
         exit
         end else dec(Gear^.Timer)
      end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepHedgehog(Gear: PGear);
begin
if (Gear^.Message and gm_Destroy) <> 0 then
   begin
   DeleteGear(Gear);
   exit
   end;
if (Gear^.State and gstHHDriven) = 0 then doStepHedgehogFree(Gear)
                                     else doStepHedgehogDriven(Gear)
end;
