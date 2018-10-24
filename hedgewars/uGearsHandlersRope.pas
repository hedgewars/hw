(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *)

{$INCLUDE "options.inc"}
unit uGearsHandlersRope;
interface

uses uTypes;

procedure doStepRope(Gear: PGear);

implementation
uses uConsts, uFloat, uCollisions, uVariables, uGearsList, uSound, uGearsUtils,
    uAmmos, uDebug, uUtils, uGearsHedgehog, uGearsRender;

const
    IsNilHHFatal = false;

procedure doStepRopeAfterAttack(Gear: PGear);
var
    HHGear: PGear;
    tX:     hwFloat;
begin
    HHGear := Gear^.Hedgehog^.Gear;
    if HHGear = nil then
        begin
        OutError('ERROR: doStepRopeAfterAttack called while HHGear = nil', IsNilHHFatal);
        DeleteGear(Gear);
        exit()
        end
    else if not CurrentTeam^.ExtDriven and (FollowGear <> nil) then FollowGear := HHGear;

    tX:= HHGear^.X;
    if WorldWrap(HHGear) and (WorldEdge = weWrap) and
       ((TestCollisionXwithGear(HHGear, 1) <> 0) or (TestCollisionXwithGear(HHGear, -1) <> 0))  then
        begin
        HHGear^.X:= tX;
        HHGear^.dX.isNegative:= hwRound(tX) > LongInt(leftX) + HHGear^.Radius * 2
        end;

    if (HHGear^.Hedgehog^.CurAmmoType = amParachute) and (HHGear^.dY > _0_39) then
        begin
        DeleteGear(Gear);
        ApplyAmmoChanges(HHGear^.Hedgehog^);
        HHGear^.Message:= HHGear^.Message or gmLJump;
        exit
        end;

    if ((HHGear^.State and gstHHDriven) = 0)
    or (CheckGearDrowning(HHGear))
    or (TestCollisionYwithGear(HHGear, 1) <> 0) then
        begin
        DeleteGear(Gear);
        if (TestCollisionYwithGear(HHGear, 1) <> 0) and (GetAmmoEntry(HHGear^.Hedgehog^, amRope)^.Count >= 1) and ((Ammoz[HHGear^.Hedgehog^.CurAmmoType].Ammo.Propz and ammoprop_AltUse) <> 0) and (HHGear^.Hedgehog^.MultiShootAttacks = 0) then
            HHGear^.Hedgehog^.CurAmmoType:= amRope;
        isCursorVisible := false;
        ApplyAmmoChanges(HHGear^.Hedgehog^);
        exit
        end;

    HedgehogChAngle(HHGear);

    if TestCollisionXwithGear(HHGear, hwSign(HHGear^.dX)) <> 0 then
        SetLittle(HHGear^.dX);

    if HHGear^.dY.isNegative and (TestCollisionYwithGear(HHGear, -1) <> 0) then
        HHGear^.dY := _0;
    HHGear^.X := HHGear^.X + HHGear^.dX;
    HHGear^.Y := HHGear^.Y + HHGear^.dY;
    HHGear^.dY := HHGear^.dY + cGravity;

    if (GameFlags and gfMoreWind) <> 0 then
        HHGear^.dX := HHGear^.dX + cWindSpeed / HHGear^.Density;

    if (Gear^.Message and gmAttack) <> 0 then
        begin
        Gear^.X := HHGear^.X;
        Gear^.Y := HHGear^.Y;

        ApplyAngleBounds(Gear^.Hedgehog^, amRope);

        Gear^.dX := SignAs(AngleSin(HHGear^.Angle), HHGear^.dX);
        Gear^.dY := -AngleCos(HHGear^.Angle);
        Gear^.Friction := _4_5 * cRopePercent;
        Gear^.Elasticity := _0;
        Gear^.State := Gear^.State and (not gsttmpflag);
        Gear^.doStep := @doStepRope;
        end
end;

procedure RopeDeleteMe(Gear, HHGear: PGear);
begin
    with HHGear^ do
        begin
        Message := Message and (not gmAttack);
        State := (State or gstMoving) and (not gstWinner);
        end;
    DeleteGear(Gear)
end;

procedure RopeWaitCollision(Gear, HHGear: PGear);
begin
    with HHGear^ do
        begin
        Message := Message and (not gmAttack);
        State := State or gstMoving;
        end;
    RopePoints.Count := 0;
    Gear^.Elasticity := _0;
    Gear^.doStep := @doStepRopeAfterAttack
end;

procedure doStepRopeWork(Gear: PGear);
var
    HHGear: PGear;
    len, tx, ty, nx, ny, ropeDx, ropeDy, mdX, mdY: hwFloat;
    lx, ly, cd: LongInt;
    haveCollision,
    haveDivided: boolean;
    wrongSide: boolean;
begin
    HHGear := Gear^.Hedgehog^.Gear;
    if HHGear = nil then
        begin
        OutError('ERROR: doStepRopeWork called while HHGear = nil', IsNilHHFatal);
        DeleteGear(Gear);
        exit()
        end
    else if not CurrentTeam^.ExtDriven and (FollowGear <> nil) then FollowGear := HHGear;

    if ((HHGear^.State and gstHHDriven) = 0) or
        (CheckGearDrowning(HHGear)) or (Gear^.PortalCounter <> 0) then
        begin
        PlaySound(sndRopeRelease);
        RopeDeleteMe(Gear, HHGear);
        exit
        end;

    if GameTicks mod 4 <> 0 then exit;

    tX:= HHGear^.X;
    if WorldWrap(HHGear) and (WorldEdge = weWrap) and
       ((TestCollisionXwithGear(HHGear, 1) <> 0) or (TestCollisionXwithGear(HHGear, -1) <> 0))  then
        begin
        PlaySound(sndRopeRelease);
        RopeDeleteMe(Gear, HHGear);
        HHGear^.X:= tX;
        HHGear^.dX.isNegative:= hwRound(tX) > LongInt(leftX) + HHGear^.Radius * 2;
        exit
        end;

    tX:= HHGear^.X;
    HHGear^.dX.QWordValue:= HHGear^.dX.QWordValue shl 2;
    HHGear^.dY.QWordValue:= HHGear^.dY.QWordValue shl 2;
    if (Gear^.Message and gmLeft  <> 0) and (TestCollisionXwithGear(HHGear, -1) = 0) then
        HHGear^.dX := HHGear^.dX - _0_0032;

    if (Gear^.Message and gmRight <> 0) and (TestCollisionXwithGear(HHGear,  1) = 0) then
        HHGear^.dX := HHGear^.dX + _0_0032;

    // vector between hedgehog and rope attaching point
    ropeDx := HHGear^.X - Gear^.X;
    ropeDy := HHGear^.Y - Gear^.Y;

    if TestCollisionYwithXYShift(HHGear, 0, 1, 1) = 0 then
        begin

        // depending on the rope vector we know which X-side to check for collision
        // in order to find out if the hog can still be moved by gravity
        if ropeDx.isNegative = RopeDy.IsNegative then
            cd:= -1
        else
            cd:= 1;

        // apply gravity if there is no obstacle
        if TestCollisionXwithXYShift(HHGear, _2*cd, 0, cd, true) = 0 then
            HHGear^.dY := HHGear^.dY + cGravity * 16;

        if (GameFlags and gfMoreWind) <> 0 then
            // apply wind if there's no obstacle
            if TestCollisionXwithGear(HHGear, hwSign(cWindSpeed)) = 0 then
                HHGear^.dX := HHGear^.dX + cWindSpeed * 16 / HHGear^.Density;
        end;

    mdX := ropeDx + HHGear^.dX;
    mdY := ropeDy + HHGear^.dY;
    len := _1 / Distance(mdX, mdY);
    // rope vector plus hedgehog direction vector normalized
    mdX := mdX * len;
    mdY := mdY * len;

    // for visual purposes only
    Gear^.dX := mdX;
    Gear^.dY := mdY;

    /////
    tx := HHGear^.X;
    ty := HHGear^.Y;

    if ((Gear^.Message and gmDown) <> 0) and (Gear^.Elasticity < Gear^.Friction) then
        if not ((TestCollisionXwithXYShift(HHGear, _2*hwSign(ropeDx), 0, hwSign(ropeDx), true) <> 0)
        or ((ropeDy.QWordValue <> 0) and (TestCollisionYwithXYShift(HHGear, 0, 1*hwSign(ropeDy), hwSign(ropeDy)) <> 0))) then
            Gear^.Elasticity := Gear^.Elasticity + _1_2;

    if ((Gear^.Message and gmUp) <> 0) and (Gear^.Elasticity > _30) then
        if not ((TestCollisionXwithXYShift(HHGear, -_2*hwSign(ropeDx), 0, -hwSign(ropeDx), true) <> 0)
        or ((ropeDy.QWordValue <> 0) and (TestCollisionYwithXYShift(HHGear, 0, 1*-hwSign(ropeDy), -hwSign(ropeDy)) <> 0))) then
            Gear^.Elasticity := Gear^.Elasticity - _1_2;

    HHGear^.X := Gear^.X + mdX * Gear^.Elasticity;
    HHGear^.Y := Gear^.Y + mdY * Gear^.Elasticity;

    HHGear^.dX := HHGear^.X - tx;
    HHGear^.dY := HHGear^.Y - ty;
    ////


    haveDivided := false;
    // check whether rope needs dividing

    len := Gear^.Elasticity - _5;
    nx := Gear^.X + mdX * len;
    ny := Gear^.Y + mdY * len;
    tx := mdX * _1_2; // should be the same as increase step
    ty := mdY * _1_2;

    while len > _3 do
        begin
        lx := hwRound(nx);
        ly := hwRound(ny);
        if ((ly and LAND_HEIGHT_MASK) = 0) and ((lx and LAND_WIDTH_MASK) = 0) and (Land[ly, lx] > lfAllObjMask) then
            begin
            tx := _1 / Distance(ropeDx, ropeDy);
            // old rope pos
            nx := ropeDx * tx;
            ny := ropeDy * tx;

            with RopePoints.ar[RopePoints.Count] do
                begin
                X := Gear^.X;
                Y := Gear^.Y;
                if RopePoints.Count = 0 then
                    RopePoints.HookAngle := DxDy2Angle(Gear^.dY, Gear^.dX);
                b := (nx * HHGear^.dY) > (ny * HHGear^.dX);
                sx:= Gear^.dX.isNegative;
                sy:= Gear^.dY.isNegative;
                sb:= Gear^.dX.QWordValue < Gear^.dY.QWordValue;
                dLen := len
                end;

            with RopePoints.rounded[RopePoints.Count] do
                begin
                X := hwRound(Gear^.X);
                Y := hwRound(Gear^.Y);
                end;

            Gear^.X := Gear^.X + nx * len;
            Gear^.Y := Gear^.Y + ny * len;
            inc(RopePoints.Count);
            if checkFails(RopePoints.Count <= MAXROPEPOINTS, 'Rope points overflow', true) then exit;
            Gear^.Elasticity := Gear^.Elasticity - len;
            Gear^.Friction := Gear^.Friction - len;
            haveDivided := true;
            break
            end;
        nx := nx - tx;
        ny := ny - ty;

        // len := len - _1_2 // should be the same as increase step
        len.QWordValue := len.QWordValue - _1_2.QWordValue;
        end;

    if not haveDivided then
        if RopePoints.Count > 0 then // check whether the last dividing point could be removed
            begin
            tx := RopePoints.ar[Pred(RopePoints.Count)].X;
            ty := RopePoints.ar[Pred(RopePoints.Count)].Y;
            mdX := tx - Gear^.X;
            mdY := ty - Gear^.Y;
            ropeDx:= tx - HHGear^.X;
            ropeDy:= ty - HHGear^.Y;
            if RopePoints.ar[Pred(RopePoints.Count)].b xor (mdX * ropeDy > ropeDx * mdY) then
                begin
                dec(RopePoints.Count);
                Gear^.X := tx;
                Gear^.Y := ty;

                // oops, opposite quadrant, don't restore hog position in such case, just remove the point
                wrongSide:= (ropeDx.isNegative = RopePoints.ar[RopePoints.Count].sx)
                    and (ropeDy.isNegative = RopePoints.ar[RopePoints.Count].sy);

                // previous check could be inaccurate in vertical/horizontal rope positions,
                // so perform this check also, even though odds are 1 to 415927 to hit this
                if (not wrongSide)
                    and ((ropeDx.isNegative = RopePoints.ar[RopePoints.Count].sx)
                      <> (ropeDy.isNegative = RopePoints.ar[RopePoints.Count].sy)) then
                    if RopePoints.ar[RopePoints.Count].sb then
                        wrongSide:= ropeDy.isNegative = RopePoints.ar[RopePoints.Count].sy
                        else
                        wrongSide:= ropeDx.isNegative = RopePoints.ar[RopePoints.Count].sx;

                if wrongSide then
                    begin
                    Gear^.Elasticity := Gear^.Elasticity - RopePoints.ar[RopePoints.Count].dLen;
                    Gear^.Friction := Gear^.Friction - RopePoints.ar[RopePoints.Count].dLen;
                    end else
                    begin
                    Gear^.Elasticity := Gear^.Elasticity + RopePoints.ar[RopePoints.Count].dLen;
                    Gear^.Friction := Gear^.Friction + RopePoints.ar[RopePoints.Count].dLen;

                    // restore hog position
                    len := _1 / Distance(mdX, mdY);
                    mdX := mdX * len;
                    mdY := mdY * len;

                    HHGear^.X := Gear^.X - mdX * Gear^.Elasticity;
                    HHGear^.Y := Gear^.Y - mdY * Gear^.Elasticity;
                    end;
                end
            end;

    haveCollision := false;
    if TestCollisionXwithXYShift(HHGear, _2*hwSign(HHGear^.dX), 0, hwSign(HHGear^.dX), true) <> 0 then
        begin
        HHGear^.dX := -_0_6 * HHGear^.dX;
        haveCollision := true
        end;
    if TestCollisionYwithXYShift(HHGear, 0, 1*hwSign(HHGear^.dY), hwSign(HHGear^.dY)) <> 0 then
        begin
        HHGear^.dY := -_0_6 * HHGear^.dY;
        haveCollision := true
        end;

    if haveCollision and (Gear^.Message and (gmLeft or gmRight) <> 0) and (Gear^.Message and (gmUp or gmDown) <> 0) then
        begin
        HHGear^.dX := SignAs(hwAbs(HHGear^.dX) + _0_8, HHGear^.dX);
        HHGear^.dY := SignAs(hwAbs(HHGear^.dY) + _0_8, HHGear^.dY)
        end;

    len := hwSqr(HHGear^.dX) + hwSqr(HHGear^.dY);
    if len > _10 then
        begin
        len := _3_2 / hwSqrt(len);
        HHGear^.dX := HHGear^.dX * len;
        HHGear^.dY := HHGear^.dY * len;
        end;

    haveCollision:= ((hwRound(Gear^.Y) and LAND_HEIGHT_MASK) = 0) and ((hwRound(Gear^.X) and LAND_WIDTH_MASK) = 0) and ((Land[hwRound(Gear^.Y), hwRound(Gear^.X)]) <> 0);

    if not haveCollision then
        begin
        // backup gear location
        tx:= Gear^.X;
        ty:= Gear^.Y;

        if RopePoints.Count > 0 then
            begin
            // set gear location to the remote end of the rope, the attachment point
            Gear^.X:= RopePoints.ar[0].X;
            Gear^.Y:= RopePoints.ar[0].Y;
            end;

        CheckCollision(Gear);
        // if we haven't found any collision yet then check the other side too
        if (Gear^.State and gstCollision) = 0 then
            begin
            Gear^.dX.isNegative:= not Gear^.dX.isNegative;
            Gear^.dY.isNegative:= not Gear^.dY.isNegative;
            CheckCollision(Gear);
            Gear^.dX.isNegative:= not Gear^.dX.isNegative;
            Gear^.dY.isNegative:= not Gear^.dY.isNegative;
            end;

        haveCollision:= (Gear^.State and gstCollision) <> 0;

        // restore gear location
        Gear^.X:= tx;
        Gear^.Y:= ty;
        end;

    // if the attack key is pressed, lose rope contact as well
    if (Gear^.Message and gmAttack) <> 0 then
        haveCollision:= false;

    HHGear^.dX.QWordValue:= HHGear^.dX.QWordValue shr 2;
    HHGear^.dY.QWordValue:= HHGear^.dY.QWordValue shr 2;
    if (not haveCollision) and ((Gear^.State and gsttmpFlag) <> 0) then
        begin
            begin
            PlaySound(sndRopeRelease);
            if Gear^.Hedgehog^.CurAmmoType <> amParachute then
                RopeWaitCollision(Gear, HHGear)
            else
                RopeDeleteMe(Gear, HHGear)
            end
        end
    else
        if (Gear^.State and gsttmpFlag) = 0 then
            Gear^.State := Gear^.State or gsttmpFlag;
end;

procedure RopeRemoveFromAmmo(Gear, HHGear: PGear);
begin
    if (Gear^.State and gstAttacked) = 0 then
        begin
        OnUsedAmmo(HHGear^.Hedgehog^);
        Gear^.State := Gear^.State or gstAttacked
        end;
    ApplyAmmoChanges(HHGear^.Hedgehog^)
end;

procedure doStepRopeAttach(Gear: PGear);
var
    HHGear: PGear;
    tx, ty, tt: hwFloat;
begin
    
    Gear^.X := Gear^.X - Gear^.dX;
    Gear^.Y := Gear^.Y - Gear^.dY;
    Gear^.Elasticity := Gear^.Elasticity + _1;

    HHGear := Gear^.Hedgehog^.Gear;
    if HHGear = nil then
        begin
        OutError('ERROR: doStepRopeAttach called while HHGear = nil', IsNilHHFatal);
        DeleteGear(Gear);
        exit()
        end
    else if not CurrentTeam^.ExtDriven and (FollowGear <> nil) then FollowGear := HHGear;

    // Destroy rope if it touched bouncy or world wrap world edge.
    // TODO: Allow to shoot rope through the world wrap edge and rope normally.
    if (WorldWrap(Gear) and (WorldEdge = weWrap)) or
       ((WorldEdge = weBounce) and ((hwRound(Gear^.X) <= LeftX) or (hwRound(Gear^.X) >= RightX))) then
        begin
        HHGear^.State := HHGear^.State and (not (gstAttacking or gstHHJumping or gstHHHJump));
        HHGear^.Message := HHGear^.Message and (not gmAttack);
        DeleteGear(Gear);
        if (GetAmmoEntry(HHGear^.Hedgehog^, amRope)^.Count >= 1) and ((Ammoz[HHGear^.Hedgehog^.CurAmmoType].Ammo.Propz and ammoprop_AltUse) <> 0) and (HHGear^.Hedgehog^.MultiShootAttacks = 0) then
            HHGear^.Hedgehog^.CurAmmoType:= amRope;
        isCursorVisible := false;
        ApplyAmmoChanges(HHGear^.Hedgehog^);
        exit()
        end;

    DeleteCI(HHGear);

    if (HHGear^.State and gstMoving) <> 0 then
        begin
        doStepHedgehogMoving(HHGear);
        Gear^.X := Gear^.X + HHGear^.dX;
        Gear^.Y := Gear^.Y + HHGear^.dY;


        tt := Gear^.Elasticity;
        tx := _0;
        ty := _0;
        while tt > _20 do
            begin
            if ((hwRound(Gear^.Y+ty) and LAND_HEIGHT_MASK) = 0) and ((hwRound(Gear^.X+tx) and LAND_WIDTH_MASK) = 0) and (Land[hwRound(Gear^.Y+ty), hwRound(Gear^.X+tx)] > lfAllObjMask) then
                begin
                Gear^.X := Gear^.X + tx;
                Gear^.Y := Gear^.Y + ty;
                Gear^.Elasticity := tt;
                Gear^.doStep := @doStepRopeWork;
                PlaySound(sndRopeAttach);
                with HHGear^ do
                    begin
                    State := State and (not (gstAttacking or gstHHJumping or gstHHHJump));
                    Message := Message and (not gmAttack)
                    end;

                RopeRemoveFromAmmo(Gear, HHGear);

                tt := _0;
                exit
                end;
            tx := tx + Gear^.dX + Gear^.dX;
            ty := ty + Gear^.dY + Gear^.dY;
            tt := tt - _2;
            end;
        end;

    if Gear^.Elasticity < _20 then Gear^.CollisionMask:= lfLandMask
    else Gear^.CollisionMask:= lfNotCurHogCrate; //lfNotObjMask or lfNotHHObjMask;
    CheckCollision(Gear);

    if (Gear^.State and gstCollision) <> 0 then
        if Gear^.Elasticity < _10 then
            Gear^.Elasticity := _10000
    else
        begin
        Gear^.doStep := @doStepRopeWork;
        PlaySound(sndRopeAttach);
        with HHGear^ do
            begin
            State := State and (not (gstAttacking or gstHHJumping or gstHHHJump));
            Message := Message and (not gmAttack)
            end;

        RopeRemoveFromAmmo(Gear, HHGear);

        exit
        end;

    if (Gear^.Elasticity > Gear^.Friction)
        or ((Gear^.Message and gmAttack) = 0)
        or ((HHGear^.State and gstHHDriven) = 0)
        or (HHGear^.Damage > 0) then
            begin
            with Gear^.Hedgehog^.Gear^ do
                begin
                State := State and (not gstAttacking);
                Message := Message and (not gmAttack)
                end;
        DeleteGear(Gear);
        if (GetAmmoEntry(HHGear^.Hedgehog^, amRope)^.Count >= 1) and ((Ammoz[HHGear^.Hedgehog^.CurAmmoType].Ammo.Propz and ammoprop_AltUse) <> 0) and (HHGear^.Hedgehog^.MultiShootAttacks = 0) then
            HHGear^.Hedgehog^.CurAmmoType:= amRope;
        isCursorVisible := false;
        ApplyAmmoChanges(HHGear^.Hedgehog^);
        exit;
        end;
    if CheckGearDrowning(HHGear) then DeleteGear(Gear)
end;

procedure doStepRope(Gear: PGear);
begin
    Gear^.dX := - Gear^.dX;
    Gear^.dY := - Gear^.dY;
    Gear^.doStep := @doStepRopeAttach;
    PlaySound(sndRopeShot)
end;

end.
