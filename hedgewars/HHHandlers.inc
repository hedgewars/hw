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

////////////////////////////////////////////////////////////////////////////////
procedure Attack(Gear: PGear);
var xx, yy: Double;
begin
with Gear^,
     PHedgehog(Gear.Hedgehog)^ do
     begin
     if ((State and gstHHDriven) <> 0)and
 //       (((State and gstAttacking) <> 0) or ((Message and gm_Attack) <> 0))and
        ((State and (gstAttacked or gstMoving or gstHHChooseTarget)) = 0)and
        (((State and gstFalling  ) = 0)or((Ammo[CurSlot, CurAmmo].Propz and ammoprop_AttackInFall) <> 0))and
        (((State and gstHHJumping) = 0)or((Ammo[CurSlot, CurAmmo].Propz and ammoprop_AttackInJump) <> 0))and
          ((TargetPoint.X <> NoPointX) or((Ammo[CurSlot, CurAmmo].Propz and ammoprop_NeedTarget) = 0)) then
        begin
        State:= State or gstAttacking;
        if Power = cMaxPower then Message:= Message and not gm_Attack
        else if (Ammo[CurSlot, CurAmmo].Propz and ammoprop_Power) = 0 then Message:= Message and not gm_Attack
        else begin
             if Power = 0 then
                begin
                AttackBar:= CurrentTeam.AttackBar;
                PlaySound(sndThrowPowerUp)
                end;
             inc(Power)
             end;
        if ((Message and gm_Attack) <> 0) then exit;
        
        if (Ammo[CurSlot, CurAmmo].Propz and ammoprop_Power) <> 0 then
           begin
           StopSound(sndThrowPowerUp);
           PlaySound(sndThrowRelease);
           end;
        xx:= hwSign(dX)*Sin(Angle*pi/cMaxAngle);
        yy:= -Cos(Angle*pi/cMaxAngle);
             case Ammo[CurSlot, CurAmmo].AmmoType of
                      amGrenade: FollowGear:= AddGear(round(X), round(Y), gtAmmo_Bomb,    0, xx*Power/cPowerDivisor, yy*Power/cPowerDivisor, Ammo[CurSlot, CurAmmo].Timer);
                  amClusterBomb: FollowGear:= AddGear(round(X), round(Y), gtClusterBomb,  0, xx*Power/cPowerDivisor, yy*Power/cPowerDivisor, Ammo[CurSlot, CurAmmo].Timer);
                      amBazooka: FollowGear:= AddGear(round(X), round(Y), gtAmmo_Grenade, 0, xx*Power/cPowerDivisor, yy*Power/cPowerDivisor);
                          amUFO: FollowGear:= AddGear(round(X), round(Y), gtUFO,          0, xx*Power/cPowerDivisor, yy*Power/cPowerDivisor);
                      amShotgun: begin
                                 PlaySound(sndShotgunReload);
                                 CurAmmoGear:= AddGear(round(X), round(Y), gtShotgunShot,  0, xx * 0.5, yy * 0.5);
                                 end;
                   amPickHammer: CurAmmoGear:= AddGear(round(Gear.X), round(Gear.Y) + cHHRadius, gtPickHammer, 0);
                         amSkip: TurnTimeLeft:= 0;
                         amRope: CurAmmoGear:= AddGear(round(Gear.X), round(Gear.Y), gtRope, 0, xx, yy);
                         amMine: AddGear(round(X) + hwSign(dX) * 7, round(Y), gtMine, 0, hwSign(dX) * 0.02, 0, 3000);
                       amDEagle: AddGear(round(X), round(Y), gtDEagleShot, 0, xx * 0.5, yy * 0.5);
                     amDynamite: AddGear(round(X) + hwSign(dX) * 7, round(Y), gtDynamite, 0, hwSign(dX) * 0.035, 0, 5000);
                  amBaseballBat: AddGear(round(X) + hwSign(dX) * 10, round(Y), gtShover, 0, xx * 0.5, yy * 0.5).Radius:= 20;
                    amFirePunch: CurAmmoGear:= AddGear(round(X) + hwSign(dX) * 10, round(Y), gtFirePunch, 0);
                    amParachute: CurAmmoGear:= AddGear(round(X), round(Y), gtParachute, 0);
                    amAirAttack: AddGear(0, 0, gtAirAttack, 0);
                   amMineStrike: AddGear(0, 0, gtAirAttack, 1);
                  end;
        Power:= 0;
        if CurAmmoGear <> nil then
           begin
           Message:= Message or gm_Attack;
           CurAmmoGear.Message:= Message
           end else begin
           if not CurrentTeam.ExtDriven and
             ((Ammo[CurSlot, CurAmmo].Propz and ammoprop_Power) <> 0) then SendIPC('a');
           AfterAttack
           end
        end else Message:= Message and not gm_Attack
     end
end;

procedure AfterAttack;
begin
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear^,
     CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog] do
     begin
        Inc(AttacksNum);
        State:= State and not gstAttacking;
        if Ammo[CurSlot, CurAmmo].NumPerTurn >= AttacksNum then isInMultiShoot:= true
           else begin
           TurnTimeLeft:= Ammoz[Ammo[CurSlot, CurAmmo].AmmoType].TimeAfterTurn;
           State:= State or gstAttacked;
           OnUsedAmmo(Ammo)
           end;
     AttackBar:= 0;
     end
end;

////////////////////////////////////////////////////////////////////////////////
procedure PickUp(HH, Gear: PGear);
var s: shortstring;
    a: TAmmoType;
begin
Gear.Message:= gm_Destroy;
case Gear.Pos of
       posCaseAmmo: begin
                    a:= TAmmoType(Gear.State);
                    AddAmmo(PHedgehog(HH.Hedgehog), a);
                    s:= trammo[Ammoz[a].NameId];
                    AddCaption(s, PHedgehog(HH.Hedgehog).Team.Color, capgrpAmmoinfo);
                    end;
     posCaseHealth: begin
                    inc(HH.Health, Gear.Health);
                    str(Gear.Health, s);
                    s:= '+' + s;
                    AddCaption(s, PHedgehog(HH.Hedgehog).Team.Color, capgrpAmmoinfo);
                    RenderHealth(PHedgehog(HH.Hedgehog)^);
                    RecountTeamHealth(PHedgehog(HH.Hedgehog)^.Team)
                    end;
     end;
end;

procedure doStepHedgehog(Gear: PGear); forward;
////////////////////////////////////////////////////////////////////////////////
procedure doStepHedgehogDriven(Gear: PGear);
const StepTicks: LongWord = 0;
var t: PGear;
    PrevdX: integer;
begin
if isInMultiShoot and (Gear.Damage = 0) then
   begin
   exit
   end;
AllInactive:= false;
DeleteCI(Gear);
if (TurnTimeLeft = 0) or (Gear.Damage > 0) then
   begin
   TurnTimeLeft:= 0;
   if ((Gear.State and (gstMoving or gstFalling)) = 0)
      and (CurAmmoGear = nil) then Gear.dX:= 0.0000001 * hwSign(Gear.dX);
   Gear.State:= Gear.State and not gstHHDriven;
   if Gear.Damage > 0 then
      Gear.State:= Gear.State and not gstHHJumping;
   exit
   end;
if ((Gear.State and gstFalling) <> 0) or (StepTicks = cHHStepTicks)
   or (CurAmmoGear <> nil) then // we're moving
   begin
   // check for case with ammo
   t:= CheckGearNear(Gear, gtCase, 36, 36);
   if t <> nil then
      PickUp(Gear, t)
   end;

if CurAmmoGear <> nil then
   begin
   CurAmmoGear.Message:= Gear.Message;
   exit
   end;

if ((Gear.Message and gm_Attack) <> 0) or
   ((Gear.State and gstAttacking) <> 0)then Attack(Gear);

if (Gear.State and gstFalling) <> 0 then
   begin
   // it could be the source to trick: double-backspace jump -> vertical wall
   // collision - > (abs(Gear.dX) < 0.0000002) -> backspace -> even more high jump
   if ((Gear.Message and gm_HJump) <> 0) and ((Gear.State and gstHHJumping) <> 0) then
      if (abs(Gear.dX) < 0.0000002) and (Gear.dY < -0.02) then
         begin
         Gear.dY:= -0.25;
         Gear.dX:= hwSign(Gear.dX) * 0.02
         end;
   Gear.Message:= Gear.Message and not (gm_LJump or gm_HJump);     
   if TestCollisionXwithGear(Gear, hwSign(Gear.dX)) then Gear.dX:= 0.0000001 * hwSign(Gear.dX);
   Gear.X:= Gear.X + Gear.dX;
   Gear.dY:= Gear.dY + cGravity;
   if (Gear.dY < 0)and TestCollisionYwithGear(Gear, -1) then Gear.dY:= 0;
   Gear.Y:= Gear.Y + Gear.dY;
   if (Gear.dY >= 0)and TestCollisionYwithGear(Gear, 1) then
      begin
      CheckHHDamage(Gear);
      if ((abs(Gear.dX) + abs(Gear.dY)) < 0.55)
         and ((Gear.State and gstHHJumping) <> 0) then Gear.dX:= 0.0000001 * hwSign(Gear.dX);
      Gear.State:= Gear.State and not (gstFalling or gstHHJumping);
      StepTicks:= 300; 
      Gear.dY:= 0
      end;
   CheckGearDrowning(Gear);
   exit
   end ;//else if Gear.CollIndex = High(Longword) then AddIntersectorsCR(Gear);

if StepTicks > 0 then dec(StepTicks);

if ((Gear.State and (gstMoving or gstFalling)) = 0) then
   if (Gear.Message and gm_Up    )<>0 then if Gear.Angle > 0         then dec(Gear.Angle)
      else else
   if (Gear.Message and gm_Down  )<>0 then if Gear.Angle < cMaxAngle then inc(Gear.Angle);

if ((Gear.State and (gstAttacking or gstMoving or gstFalling)) = 0)and(StepTicks = 0) then
   begin
   if ((Gear.Message and gm_LJump ) <> 0) then
      begin
      Gear.Message:= 0;
      if not TestCollisionYwithGear(Gear, -1) then
         if not TestCollisionXwithXYShift(Gear, 0, -2, hwSign(Gear.dX)) then Gear.Y:= Gear.Y - 2 else
         if not TestCollisionXwithXYShift(Gear, 0, -1, hwSign(Gear.dX)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithGear(Gear, hwSign(Gear.dX))
         or   TestCollisionYwithGear(Gear, -1)) then
         begin
         Gear.dY:= -0.15;
         Gear.dX:= hwSign(Gear.dX) * 0.15;
         Gear.State:= Gear.State or gstFalling or gstHHJumping;
         exit
         end;
      end;
   if ((Gear.Message and gm_HJump ) <> 0) then
      begin
      Gear.Message:= 0;
      if not TestCollisionYwithGear(Gear, -1) then
         begin
         Gear.dY:= -0.20;
         Gear.dX:= 0.0000001 * hwSign(Gear.dX);
         Gear.X:= Gear.X - hwSign(Gear.dX)*0.00008; // shift compensation
         Gear.State:= Gear.State or gstFalling or gstHHJumping;
         exit
         end;
      end;
   PrevdX:= hwSign(Gear.dX);
   if (Gear.Message and gm_Left  )<>0 then Gear.dX:= -1.0 else
   if (Gear.Message and gm_Right )<>0 then Gear.dX:=  1.0 else exit;
   StepTicks:= cHHStepTicks;
   if PrevdX <> hwSign(Gear.dX) then exit;
   PHedgehog(Gear.Hedgehog).visStepPos:= (PHedgehog(Gear.Hedgehog).visStepPos + 1) and 7;
   if TestCollisionXwithGear(Gear, hwSign(Gear.dX)) then
      begin
      if not (TestCollisionXwithXYShift(Gear, 0, -6, hwSign(Gear.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -5, hwSign(Gear.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -4, hwSign(Gear.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -3, hwSign(Gear.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -2, hwSign(Gear.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -1, hwSign(Gear.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      end;
   if not TestCollisionXwithGear(Gear, hwSign(Gear.dX)) then Gear.X:= Gear.X + Gear.dX;
   Gear.dX:= 0.0000001 * hwSign(Gear.dX);
   SetAllHHToActive;

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
      Gear.dX:= 0.0000001 * hwSign(Gear.dX);
      Gear.State:= Gear.State or gstFalling
      end;
   end
   end
   end
   end
   end
   end
   end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepHedgehogFree(Gear: PGear);
begin
//DeleteCI(Gear);
if not TestCollisionYwithGear(Gear, 1) then
   begin
   if (Gear.dY < 0) and TestCollisionYwithGear(Gear, -1) then Gear.dY:= 0;
   Gear.State:= Gear.State or gstFalling or gstMoving;
   Gear.dY:= Gear.dY + cGravity
   end else begin
   CheckHHDamage(Gear);
   if ((abs(Gear.dX) + abs(Gear.dY)) < 0.55)
      and ((Gear.State and gstHHJumping) <> 0) then Gear.dX:= 0.0000001 * hwSign(Gear.dX);
   Gear.State:= Gear.State and not (gstFalling or gstHHJumping);
   if Gear.dY > 0 then Gear.dY:= 0;
   if ((Gear.State and gstMoving) <> 0) then Gear.dX:= Gear.dX * Gear.Friction
   end;

if (Gear.State <> 0) then DeleteCI(Gear);

if (Gear.State and gstMoving) <> 0 then
   if TestCollisionXwithGear(Gear, hwSign(Gear.dX)) then
      if ((Gear.State and gstFalling) = 0) then
         if abs(Gear.dX) > 0.01 then
            if not TestCollisionXwithXYShift(Gear, hwSign(Gear.dX) - Gear.dX, -1, hwSign(Gear.dX)) then begin Gear.X:= Gear.X + Gear.dX; Gear.dX:= Gear.dX * 0.96; Gear.Y:= Gear.Y - 1 end else
            if not TestCollisionXwithXYShift(Gear, hwSign(Gear.dX) - Gear.dX, -2, hwSign(Gear.dX)) then begin Gear.X:= Gear.X + Gear.dX; Gear.dX:= Gear.dX * 0.93; Gear.Y:= Gear.Y - 2 end else
            if not TestCollisionXwithXYShift(Gear, hwSign(Gear.dX) - Gear.dX, -3, hwSign(Gear.dX)) then begin Gear.X:= Gear.X + Gear.dX; Gear.dX:= Gear.dX * 0.90; Gear.Y:= Gear.Y - 3 end else
            if not TestCollisionXwithXYShift(Gear, hwSign(Gear.dX) - Gear.dX, -4, hwSign(Gear.dX)) then begin Gear.X:= Gear.X + Gear.dX; Gear.dX:= Gear.dX * 0.87; Gear.Y:= Gear.Y - 4 end else
            if not TestCollisionXwithXYShift(Gear, hwSign(Gear.dX) - Gear.dX, -5, hwSign(Gear.dX)) then begin Gear.X:= Gear.X + Gear.dX; Gear.dX:= Gear.dX * 0.84; Gear.Y:= Gear.Y - 5 end else
            if abs(Gear.dX) > 0.02 then Gear.dX:= -Gear.Elasticity * Gear.dX
                                   else begin
                                        Gear.State:= Gear.State and not gstMoving;
                                        Gear.dX:= 0.0000001 * hwSign(Gear.dX)
                                        end
            else begin
                 Gear.State:= Gear.State and not gstMoving;
                 Gear.dX:= 0.0000001 * hwSign(Gear.dX)
                 end
         else Gear.dX:= -Gear.Elasticity * Gear.dX;

if ((Gear.State and gstFalling) = 0)and
   (sqr(Gear.dX) + sqr(Gear.dY) < 0.0008) then
   begin
   Gear.State:= Gear.State and not gstMoving;
   Gear.dX:= 0.0000001 * hwSign(Gear.dX);
   Gear.dY:= 0
   end else Gear.State:= Gear.State or gstMoving;

if (Gear.State and gstMoving) <> 0 then
   begin
   Gear.X:= Gear.X + Gear.dX;
   Gear.Y:= Gear.Y + Gear.dY;
   if (Gear.dY > 0) and not TestCollisionYwithGear(Gear, 1) and TestCollisionYwithXYShift(Gear, 0, 1, 1) then
      begin
      CheckHHDamage(Gear);
      Gear.dY:= 0;
      Gear.Y:= Gear.Y + 1
      end;
   end else
   if Gear.Health = 0 then
      begin
      if AllInactive then
         begin
         doMakeExplosion(round(Gear.X), round(Gear.Y), 30, EXPLAutoSound);
         AddGear(round(Gear.X), round(Gear.Y), gtGrave, 0).Hedgehog:= Gear.Hedgehog;
         DeleteGear(Gear);
         SetAllToActive
         end;
      AllInactive:= false;  
      exit
      end;

AllInactive:= false;

if (not CheckGearDrowning(Gear)) and
   ((Gear.State and gstMoving) = 0) then
      begin
      Gear.State:= 0;
      Gear.Active:= false;
      AddGearCI(Gear);
      exit
      end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepHedgehog(Gear: PGear);
begin
if (Gear.Message and gm_Destroy) <> 0 then
   begin
   DeleteGear(Gear);
   exit
   end;
if (Gear.State and gstHHDriven) = 0 then doStepHedgehogFree(Gear)
                                    else doStepHedgehogDriven(Gear)
end;
