(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2010 Andrey Korotaev <unC0Rr@gmail.com>
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

procedure doStepPerPixel(Gear: PGear; step: TGearStepProcedure; onlyCheckIfChanged: boolean);
var
    dX, dY, sX, sY: hwFloat;
    i, steps: LongWord;
    caller: TGearStepProcedure;
begin
    dX:= Gear^.dX;
    dY:= Gear^.dY;
    steps:= max(abs(hwRound(Gear^.X+dX)-hwRound(Gear^.X)), abs(hwRound(Gear^.Y+dY)-hwRound(Gear^.Y)));

    // Gear is still on the same Pixel it was before
    if steps < 1 then
        begin
        if onlyCheckIfChanged then
            begin
            Gear^.X := Gear^.X + dX;
            Gear^.Y := Gear^.Y + dY;
            EXIT;
            end
        else
            steps := 1;
        end;

    if steps > 1 then
        begin
        sX:= dX / steps;
        sY:= dY / steps;
        end
    else
        begin
        sX:= dX;
        sY:= dY;
        end;

    caller:= Gear^.doStep;

    for i:= 1 to steps do
        begin
        Gear^.X := Gear^.X + sX;
        Gear^.Y := Gear^.Y + sY;
        step(Gear);
        if (Gear^.doStep <> caller)
        or ((Gear^.State and gstCollision) <> 0)
        or ((Gear^.State and gstMoving) = 0) then
            break;
        end;
end;

procedure makeHogsWorry(x, y: hwFloat; r: LongInt);
var 
    gi: PGear;
    d: LongInt;
begin
    gi := GearsList;
    while gi <> nil do
        begin
        if (gi^.Kind = gtHedgehog) then
            begin
            d := r - hwRound(Distance(gi^.X - x, gi^.Y - y));
            if (d > 1) and not gi^.Invulnerable and (GetRandom(2) = 0) then
                begin
                if (CurrentHedgehog^.Gear = gi) then
                    PlaySound(sndOops, gi^.Hedgehog^.Team^.voicepack)
                else
                    begin
                    if (gi^.State and gstMoving) = 0 then
                        gi^.State := gi^.State or gstLoser;
                    if d > r div 2 then
                        PlaySound(sndNooo, gi^.Hedgehog^.Team^.voicepack)
                    else
                        PlaySound(sndUhOh, gi^.Hedgehog^.Team^.voicepack);
                    end;
                end;
            end;
        gi := gi^.NextGear
        end;
end;
////////////////////////////////////////////////////////////////////////////////
procedure doStepDrowningGear(Gear: PGear);
forward;

function CheckGearDrowning(Gear: PGear): boolean;
var 
    skipSpeed, skipAngle, skipDecay: hwFloat;
    i, maxDrops: LongInt;
    particle: PVisualGear;
    isSubmersible: boolean;
begin
    isSubmersible:= (Gear = CurrentHedgehog^.Gear) and (CurAmmoGear <> nil) and (CurAmmoGear^.AmmoType = amJetpack);
    // probably needs tweaking. might need to be in a case statement based upon gear type
    if cWaterLine < hwRound(Gear^.Y) + Gear^.Radius then
        begin
        skipSpeed := _0_25;
        skipAngle := _1_9;
        skipDecay := _0_87;
        // this could perhaps be a tiny bit higher.
        if  (hwSqr(Gear^.dX) + hwSqr(Gear^.dY) > skipSpeed) and
           (hwAbs(Gear^.dX) > skipAngle * hwAbs(Gear^.dY)) then
            begin
            Gear^.dY.isNegative := true;
            Gear^.dY := Gear^.dY * skipDecay;
            Gear^.dX := Gear^.dX * skipDecay;
            CheckGearDrowning := false;
            PlaySound(sndSkip)
            end
        else
            begin
            if not isSubmersible then
                begin
                CheckGearDrowning := true;
                Gear^.State := gstDrowning;
                Gear^.RenderTimer := false;
                if (Gear^.Kind <> gtSniperRifleShot) and (Gear^.Kind <> gtShotgunShot) and 
                   (Gear^.Kind <> gtDEagleShot) and (Gear^.Kind <> gtSineGunShot) then
                    if Gear^.Kind = gtHedgehog then 
                        begin
                        if Gear^.Hedgehog^.Effects[heResurrectable] then
                            ResurrectHedgehog(Gear)
                        else
                            begin
                            Gear^.doStep := @doStepDrowningGear;
                            Gear^.State := Gear^.State and (not gstHHDriven);
                            AddCaption(Format(GetEventString(eidDrowned), Gear^.Hedgehog^.Name), cWhiteColor, capgrpMessage);
                            end
                        end
                    else
                        Gear^.doStep := @doStepDrowningGear
            end;
            if ((not isSubmersible) and (hwRound(Gear^.Y) < cWaterLine + 64 + Gear^.Radius)) or
               (isSubmersible and (hwRound(Gear^.Y) < cWaterLine + 2 + Gear^.Radius) and ((CurAmmoGear^.Pos = 0) and (CurAmmoGear^.dY < _0_01))) then
                // don't play splash if they are already way past the surface
                PlaySound(sndSplash)
        end;

        if ((cReducedQuality and rqPlainSplash) = 0) and 
           (((not isSubmersible) and (hwRound(Gear^.Y) < cWaterLine + 64 + Gear^.Radius)) or
             (isSubmersible and (hwRound(Gear^.Y) < cWaterLine + 2 + Gear^.Radius) and ((CurAmmoGear^.Pos = 0) and (CurAmmoGear^.dY < _0_01)))) then
            begin
            AddVisualGear(hwRound(Gear^.X), cWaterLine, vgtSplash);

            maxDrops := (Gear^.Radius div 2) + hwRound(Gear^.dX * Gear^.Radius * 2) + hwRound(Gear^.
                        dY * Gear^.Radius * 2);
            for i:= max(maxDrops div 3, min(32, Random(maxDrops))) downto 0 do
                begin
                particle := AddVisualGear(hwRound(Gear^.X) - 3 + Random(6), cWaterLine, vgtDroplet);
                if particle <> nil then
                    begin
                    particle^.dX := particle^.dX - (Gear^.dX.QWordValue / 42949672960);
                    particle^.dY := particle^.dY - (Gear^.dY.QWordValue / 21474836480)
                    end
                end
            end;
        if isSubmersible and (CurAmmoGear^.Pos = 0) then CurAmmoGear^.Pos := 1000
    end
    else
        CheckGearDrowning := false;
end;

procedure CheckCollision(Gear: PGear); inline;
begin
    if TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) or TestCollisionYwithGear(Gear, hwSign(Gear^.dY)
       )
        then Gear^.State := Gear^.State or      gstCollision
    else Gear^.State := Gear^.State and not gstCollision
end;

procedure CheckCollisionWithLand(Gear: PGear); inline;
begin
    if TestCollisionX(Gear, hwSign(Gear^.dX)) or TestCollisionY(Gear, hwSign(Gear^.dY)
       )
        then Gear^.State := Gear^.State or      gstCollision
    else Gear^.State := Gear^.State and not gstCollision
end;

procedure CheckHHDamage(Gear: PGear);
var 
    dmg: Longword;
    i: LongInt;
    particle: PVisualGear;
begin
    if _0_4 < Gear^.dY then
        begin
        dmg := ModifyDamage(1 + hwRound((hwAbs(Gear^.dY) - _0_4) * 70), Gear);
        PlaySound(sndBump);
        if dmg < 1 then exit;

        for i:= min(12, (3 + dmg div 10)) downto 0 do
            begin
            particle := AddVisualGear(hwRound(Gear^.X) - 5 + Random(10), hwRound(Gear^.Y) + 12, vgtDust);
            if particle <> nil then particle^.dX := particle^.dX + (Gear^.dX.QWordValue / 21474836480);
            end;

        if (Gear^.Invulnerable) then exit;

        //if _0_6 < Gear^.dY then
        //    PlaySound(sndOw4, Gear^.Hedgehog^.Team^.voicepack)
        //else
        //    PlaySound(sndOw1, Gear^.Hedgehog^.Team^.voicepack);

        ApplyDamage(Gear, CurrentHedgehog, dmg, dsFall);
    end
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
procedure CalcRotationDirAngle(Gear: PGear);
var 
    dAngle: real;
begin
    dAngle := (Gear^.dX.QWordValue + Gear^.dY.QWordValue) / $80000000;
    if not Gear^.dX.isNegative then
        Gear^.DirAngle := Gear^.DirAngle + dAngle
    else
        Gear^.DirAngle := Gear^.DirAngle - dAngle;

    if Gear^.DirAngle < 0 then Gear^.DirAngle := Gear^.DirAngle + 360
    else if 360 < Gear^.DirAngle then Gear^.DirAngle := Gear^.DirAngle - 360
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepDrowningGear(Gear: PGear);
begin
    AllInactive := false;
    Gear^.Y := Gear^.Y + cDrownSpeed;
    Gear^.X := Gear^.X + Gear^.dX * cDrownSpeed;
    if (not SuddenDeathDmg and (cWaterOpacity > $FE)) or (SuddenDeathDmg and (cSDWaterOpacity > $FE)) or (hwRound(Gear^.Y) > Gear^.Radius + cWaterLine + cVisibleWater) then
        DeleteGear(Gear);
    // Create some bubbles (0.5% might be better but causes too few bubbles sometimes)
    if ((not SuddenDeathDmg and (cWaterOpacity < $FF)) or (SuddenDeathDmg and (cSDWaterOpacity < $FF))) and ((GameTicks and $1F) = 0) then
        if (Gear^.Kind = gtHedgehog) and (Random(4) = 0) then
            AddVisualGear(hwRound(Gear^.X) - Gear^.Radius, hwRound(Gear^.Y) - Gear^.Radius,
            vgtBubble)
    else if Random(12) = 0 then
             AddVisualGear(hwRound(Gear^.X) - Gear^.Radius, hwRound(Gear^.Y) - Gear^.Radius,
             vgtBubble)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFallingGear(Gear: PGear);
var 
    isFalling: boolean;
    //tmp: QWord;
    tdX, tdY: hwFloat;
    collV, collH: LongInt;
begin
    // clip velocity at 1.9 - over 1 per pixel, but really shouldn't cause many actual problems.
    if Gear^.dX.QWordValue > 8160437862 then Gear^.dX.QWordValue:= 8160437862;
    if Gear^.dY.QWordValue > 8160437862 then Gear^.dY.QWordValue:= 8160437862;
    Gear^.State := Gear^.State and not gstCollision;
    collV := 0;
    collH := 0;
    tdX := Gear^.dX;
    tdY := Gear^.dY;


// might need some testing/adjustments - just to avoid projectiles to fly forever (accelerated by wind/skips)
    if (hwRound(Gear^.X) < LAND_WIDTH div -2) or (hwRound(Gear^.X) > LAND_WIDTH * 3 div 2) then Gear^.State := Gear^.State or gstCollision;

    if Gear^.dY.isNegative then
        begin
        isFalling := true;
        if TestCollisionYwithGear(Gear, -1) then
            begin
            collV := -1;
            Gear^.dX :=   Gear^.dX * Gear^.Friction;
            Gear^.dY := - Gear^.dY * Gear^.Elasticity;
            Gear^.State := Gear^.State or gstCollision
            end
        else if (Gear^.AdvBounce=1) and TestCollisionYwithGear(Gear, 1) then collV := 1;
        end
    else if TestCollisionYwithGear(Gear, 1) then
        begin
        collV := 1;
        isFalling := false;
        Gear^.dX :=   Gear^.dX * Gear^.Friction;
        Gear^.dY := - Gear^.dY * Gear^.Elasticity;
        Gear^.State := Gear^.State or gstCollision
        end
    else
        begin
        isFalling := true;
        if (Gear^.AdvBounce=1) and not Gear^.dY.isNegative and TestCollisionYwithGear(Gear, -1) then
            collV := -1;
        end;


    if TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) then
        begin
        collH := hwSign(Gear^.dX);
        Gear^.dX := - Gear^.dX * Gear^.Elasticity;
        Gear^.dY :=   Gear^.dY * Gear^.Elasticity;
        Gear^.State := Gear^.State or gstCollision
        end
    else if (Gear^.AdvBounce=1) and TestCollisionXwithGear(Gear, -hwSign(Gear^.dX)) then 
        collH := -hwSign(Gear^.dX); 
    //if Gear^.AdvBounce and (collV <>0) and (collH <> 0) and (hwSqr(tdX) + hwSqr(tdY) > _0_08) then
    if (Gear^.AdvBounce=1) and (collV <>0) and (collH <> 0) and ((collV=-1) or ((tdX.QWordValue +
       tdY.QWordValue) > _0_2.QWordValue)) then
        begin
        Gear^.dX := tdY*Gear^.Elasticity*Gear^.Friction;
        Gear^.dY := tdX*Gear^.Elasticity;
        //*Gear^.Friction;
        Gear^.dY.isNegative := not tdY.isNegative;
        isFalling := false;
        Gear^.AdvBounce := 10;
        end;

    if Gear^.AdvBounce > 1 then dec(Gear^.AdvBounce);

    if isFalling then 
        begin
        Gear^.dY := Gear^.dY + cGravity;
        if (GameFlags and gfMoreWind) <> 0 then Gear^.dX := Gear^.dX + cWindSpeed / Gear^.Density
        end;

    Gear^.X := Gear^.X + Gear^.dX;
    Gear^.Y := Gear^.Y + Gear^.dY;
    CheckGearDrowning(Gear);
    //if (hwSqr(Gear^.dX) + hwSqr(Gear^.dY) < _0_0002) and
    if ((Gear^.dX.QWordValue + Gear^.dY.QWordValue) < _0_02.QWordValue) and
       (not isFalling) then
        Gear^.State := Gear^.State and not gstMoving
    else
        Gear^.State := Gear^.State or      gstMoving;

    if (Gear^.nImpactSounds > 0) then
        if ((Gear^.Damage <> 0) or ((Gear^.State and (gstCollision or gstMoving)) = (gstCollision or
           gstMoving))) and
           ((Gear^.dX.QWordValue > _0_1.QWordValue) or (Gear^.dY.QWordValue > _0_1.QWordValue)) then
            PlaySound(TSound(ord(Gear^.ImpactSound) + LongInt(GetRandom(Gear^.nImpactSounds))), true
            );
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBomb(Gear: PGear);
var 
    i, x, y: LongInt;
    dX, dY: hwFloat;
    Fire: PGear;
    vg: PVisualGear;
begin
    AllInactive := false;

    doStepFallingGear(Gear);

    dec(Gear^.Timer);
    if Gear^.Timer = 1000 then // might need adjustments
        case Gear^.Kind of 
            gtBomb: makeHogsWorry(Gear^.X, Gear^.Y, 50);
            gtClusterBomb: makeHogsWorry(Gear^.X, Gear^.Y, 20);
            gtWatermelon: makeHogsWorry(Gear^.X, Gear^.Y, 75);
            gtHellishBomb: makeHogsWorry(Gear^.X, Gear^.Y, 90);
            gtGasBomb: makeHogsWorry(Gear^.X, Gear^.Y, 50);
        end;

    if (Gear^.Kind = gtBall) and ((Gear^.State and gstTmpFlag) <> 0) then
    begin
        CheckCollision(Gear);
        if (Gear^.State and gstCollision) <> 0 then
            doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 20, Gear^.Hedgehog, EXPLDontDraw or EXPLNoGfx);
    end;

    if (Gear^.Kind = gtGasBomb) and ((GameTicks mod 200) = 0) then
    begin
        vg:= AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtSmokeWhite);
        if vg <> nil then
            vg^.Tint:= $FFC0C000;
    end;

    if Gear^.Timer = 0 then
    begin
        case Gear^.Kind of 
            gtBomb: doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 50, Gear^.Hedgehog, EXPLAutoSound);
            gtBall: doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 40, Gear^.Hedgehog, EXPLAutoSound);
            gtClusterBomb: 
                begin
                    x := hwRound(Gear^.X);
                    y := hwRound(Gear^.Y);
                    doMakeExplosion(x, y, 20, Gear^.Hedgehog, EXPLAutoSound);
                    for i:= 0 to 4 do
                        begin
                        dX := rndSign(GetRandom * _0_1) + Gear^.dX / 5;
                        dY := (GetRandom - _3) * _0_08;
                        AddGear(x, y, gtCluster, 0, dX, dY, 25);
                        end
                end;
            gtWatermelon: 
                begin
                x := hwRound(Gear^.X);
                y := hwRound(Gear^.Y);
                doMakeExplosion(x, y, 75, Gear^.Hedgehog, EXPLAutoSound);
                for i:= 0 to 5 do
                    begin
                    dX := rndSign(GetRandom * _0_1) + Gear^.dX / 5;
                    dY := (GetRandom - _1_5) * _0_3;
                    AddGear(x, y, gtMelonPiece, 0, dX, dY, 75)^.DirAngle := i * 60;
                    end
                end;
            gtHellishBomb: 
                begin
                x := hwRound(Gear^.X);
                y := hwRound(Gear^.Y);
                doMakeExplosion(x, y, 90, Gear^.Hedgehog, EXPLAutoSound);

                for i:= 0 to 127 do
                    begin
                    dX := AngleCos(i * 16) * _0_5 * (GetRandom + _1);
                    dY := AngleSin(i * 16) * _0_5 * (GetRandom + _1);
                    Fire := AddGear(x, y, gtFlame, 0, dX, dY, 0);
                    if i mod 2 = 0 then Fire^.State := Fire^.State or gsttmpFlag;
                    Fire := AddGear(x, y, gtFlame, 0, dX, -dY, 0);
                    if i mod 2 <> 0 then Fire^.State := Fire^.State or gsttmpFlag;
                    end
                end;
            gtGasBomb:
                begin
                doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 20, Gear^.Hedgehog, EXPLAutoSound);
                for i:= 0 to 2 do
                    begin
                    x:= GetRandom(60);
                    y:= GetRandom(40);
                    AddGear(hwRound(Gear^.X) - 30 + x, hwRound(Gear^.Y) - 20 + y, gtPoisonCloud, 0, _0, _0, 0);
                    end
                end;
        end;
    DeleteGear(Gear);
    exit
end;

CalcRotationDirAngle(Gear);

if Gear^.Kind = gtHellishBomb then
begin

    if Gear^.Timer = 3000 then
    begin
        Gear^.nImpactSounds := 0;
        PlaySound(sndHellish);
    end;

    if (GameTicks and $3F) = 0 then
        if (Gear^.State and gstCollision) = 0 then
            AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtEvilTrace);
end;
end;
////////////////////////////////////////////////////////////////////////////////
procedure doStepMolotov(Gear: PGear);
var 
    i, gX, gY: LongInt;
    dX, dY: hwFloat;
    Fire: PGear;
begin
    AllInactive := false;

    doStepFallingGear(Gear);
    CalcRotationDirAngle(Gear);

    if (Gear^.State and gstCollision) <> 0 then
    begin
        PlaySound(sndMolotov);
        gX := hwRound(Gear^.X);
        gY := hwRound(Gear^.Y);
        //doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 5, EXPLAutoSound);
        for i:= 0 to 20 do
        begin
            dX := AngleCos(i * 2) * ((_0_1*(i div 5))) * (GetRandom + _1);
            dY := AngleSin(i * 8) * _0_5 * (GetRandom + _1);
            Fire := AddGear(gX, gY, gtFlame, 0, dX, dY, 0);
            Fire^.State := Fire^.State or gsttmpFlag;
            Fire := AddGear(gX, gY, gtFlame, 0, dX, -dY, 0);
            Fire^.State := Fire^.State or gsttmpFlag;
            Fire := AddGear(gX, gY, gtFlame, 0, -dX, dY, 0);
            Fire^.State := Fire^.State or gsttmpFlag;
            Fire := AddGear(gX, gY, gtFlame, 0, -dX, -dY, 0);
            Fire^.State := Fire^.State or gsttmpFlag;
        end;
        DeleteGear(Gear);
        exit
    end;
end;

procedure doStepWatermelon(Gear: PGear);
begin
    AllInactive := false;
    Gear^.doStep := @doStepBomb
end;

procedure doStepCluster(Gear: PGear);
begin
    AllInactive := false;
    doStepFallingGear(Gear);
    if (Gear^.State and gstCollision) <> 0 then
    begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Timer, Gear^.Hedgehog, EXPLAutoSound);
        DeleteGear(Gear);
        exit
    end;

    if (Gear^.Kind = gtMelonPiece) or (Gear^.Kind = gtBall) then
        CalcRotationDirAngle(Gear)
    else if (GameTicks and $1F) = 0 then
        AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtSmokeTrace)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepShell(Gear: PGear);
begin
    AllInactive := false;
    if (GameFlags and gfMoreWind) = 0 then Gear^.dX := Gear^.dX + cWindSpeed;
    doStepFallingGear(Gear);
    if (Gear^.State and gstCollision) <> 0 then
        begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 50, Gear^.Hedgehog, EXPLAutoSound);
        DeleteGear(Gear);
        exit
        end;
    if (GameTicks and $3F) = 0 then
        AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtSmokeTrace);
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSnowball(Gear: PGear);
var kick, i: LongInt;
    particle: PVisualGear;
begin
    AllInactive := false;
    if (GameFlags and gfMoreWind) = 0 then Gear^.dX := Gear^.dX + cWindSpeed;
    doStepFallingGear(Gear);
    CalcRotationDirAngle(Gear);
    if (Gear^.State and gstCollision) <> 0 then
        begin
        kick:= hwRound((hwAbs(Gear^.dX)+hwAbs(Gear^.dY)) * _20);
        Gear^.dY.isNegative:= not Gear^.dY.isNegative;
        Gear^.dX.isNegative:= not Gear^.dX.isNegative;
        AmmoShove(Gear, 1, kick);
        for i:= 15 + kick div 10 downto 0 do
            begin
            particle := AddVisualGear(hwRound(Gear^.X) + Random(25), hwRound(Gear^.Y) + Random(25), vgtDust);
            if particle <> nil then particle^.dX := particle^.dX + (Gear^.dX.QWordValue / 21474836480)
            end;
        DeleteGear(Gear);
        exit
        end;
    if ((GameTicks and $1F) = 0) and (Random(3) = 0) then
        begin
        particle:= AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtDust);
        if particle <> nil then particle^.dX := particle^.dX + (Gear^.dX.QWordValue / 21474836480)
        end
end;

procedure doStepSnowflake(Gear: PGear);
var xx, yy, px, py, i: LongInt;
    move, allpx: Boolean;
    s: PSDL_Surface;
    p: PLongwordArray;
    oAlpha, nAlpha: byte;
begin
if GameTicks and $7 = 0 then
    begin
    with Gear^ do
        begin
        X:= X + cWindSpeed * 1600 + dX;
        Y:= Y + dY + cGravity * vobFallSpeed * 8;  // using same value as flakes to try and get similar results
        xx:= hwRound(X);
        yy:= hwRound(Y);
        if vobVelocity <> 0 then
            begin
            DirAngle := DirAngle + (Angle / 1250000000);
            if DirAngle < 0 then DirAngle := DirAngle + 360
            else if 360 < DirAngle then DirAngle := DirAngle - 360;
            end;

        inc(Health, 8);
        if Health > vobFrameTicks then
            begin
            dec(Health, vobFrameTicks);
            inc(Timer);
            if Timer = vobFramesCount then Timer:= 0
            end;

        move:= false;
    // move back to cloud layer
        if yy > cWaterLine then move:= true
        else if ((yy and LAND_HEIGHT_MASK) <> 0) or ((xx and LAND_WIDTH_MASK) <> 0) then move:=true
        // Solid pixel encountered
        else if (Land[yy, xx] <> 0) then
            begin
            // If there's room below keep falling
            if (((yy-1) and LAND_HEIGHT_MASK) = 0) and (Land[yy-1, xx] = 0) then
                begin
                X:= X - cWindSpeed * 1600 - dX;
                end
            // If there's room below, on the sides, fill the gaps
            else if (((yy-1) and LAND_HEIGHT_MASK) = 0) and (((xx-(1*hwSign(cWindSpeed))) and LAND_WIDTH_MASK) = 0) and (Land[yy-1, (xx-(1*hwSign(cWindSpeed)))] = 0) then
                begin
                X:= X - _0_8 * hwSign(cWindSpeed);
                Y:= Y - dY - cGravity * vobFallSpeed * 8;
                end
            else if (((yy-1) and LAND_HEIGHT_MASK) = 0) and (((xx-(2*hwSign(cWindSpeed))) and LAND_WIDTH_MASK) = 0) and (Land[yy-1, (xx-(2*hwSign(cWindSpeed)))] = 0) then
                begin
                X:= X - _0_8 * 2 * hwSign(cWindSpeed);
                Y:= Y - dY - cGravity * vobFallSpeed * 8;
                end
            else if (((yy-1) and LAND_HEIGHT_MASK) = 0) and (((xx+(1*hwSign(cWindSpeed))) and LAND_WIDTH_MASK) = 0) and (Land[yy-1, (xx+(1*hwSign(cWindSpeed)))] = 0) then
                begin
                X:= X + _0_8 * hwSign(cWindSpeed);
                Y:= Y - dY - cGravity * vobFallSpeed * 8;
                end
            else if (((yy-1) and LAND_HEIGHT_MASK) = 0) and (((xx+(2*hwSign(cWindSpeed))) and LAND_WIDTH_MASK) = 0) and (Land[yy-1, (xx+(2*hwSign(cWindSpeed)))] = 0) then
                begin
                X:= X + _0_8 * 2 * hwSign(cWindSpeed);
                Y:= Y - dY - cGravity * vobFallSpeed * 8;
                end
            // if there's an hog/object below do nothing
            else if ((((yy+1) and LAND_HEIGHT_MASK) = 0) and ((Land[yy+1, xx] and $FF) <> 0))
                then move:=true
            else
                begin
                // we've collided with land. draw some stuff and get back into the clouds
                move:= true;
                if (CurAmmoGear = nil) or (CurAmmoGear^.Kind <> gtRope) then
                    begin
    ////////////////////////////////// TODO - ASK UNC0RR FOR A GOOD HOME FOR THIS ////////////////////////////////////
                    dec(yy,3);
                    dec(xx,1);
                    s:= SpritesData[sprSnow].Surface;
                    p:= s^.pixels;
                    allpx:= true;
                    for py:= 0 to Pred(s^.h) do
                        begin
                        for px:= 0 to Pred(s^.w) do
                            if ((((yy + py) and LAND_HEIGHT_MASK) = 0) and (((xx + px) and LAND_WIDTH_MASK) = 0)) and ((Land[yy + py, xx + px] and $FF) = 0) then
                                begin
                                Land[yy + py, xx + px]:= Land[yy + py, xx + px] or lfObject;
                                if (cReducedQuality and rqBlurryLand) = 0 then
                                    begin
                                    LandPixels[yy + py, xx + px]:= addBgColor(LandPixels[yy + py, xx + px], p^[px]);
                                    end
                                else
                                    begin
                                    LandPixels[(yy + py) div 2, (xx + px) div 2]:= addBgColor(LandPixels[(yy + py) div 2, (xx + px) div 2], p^[px]);
                                    end;
                                end
                            else allpx:= false;
                        p:= @(p^[s^.pitch shr 2])
                        end;
                    
                    
                    Land[py, px+1]:= lfBasic;
                    
                    if allpx then UpdateLandTexture(xx, Pred(s^.h), yy, Pred(s^.w))
                    else
                        begin
                        UpdateLandTexture(
                            max(0, min(LAND_WIDTH, xx)),
                            min(LAND_WIDTH - xx, Pred(s^.w)),
                            max(0, min(LAND_WIDTH, yy)),
                            min(LAND_HEIGHT - yy, Pred(s^.h))
                        );
                        end;
    ////////////////////////////////// TODO - ASK UNC0RR FOR A GOOD HOME FOR THIS ////////////////////////////////////
                    end
                end;
            end;
        if move then
            begin
            X:= int2hwFloat(GetRandom(LAND_WIDTH+1024)-512);
            Y:= int2hwFloat(750+(GetRandom(50)-25))
            end
        end
    end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepGrave(Gear: PGear);
begin
    AllInactive := false;
    if Gear^.dY.isNegative then
        if TestCollisionY(Gear, -1) then Gear^.dY := _0;

    if not Gear^.dY.isNegative then
        if TestCollisionY(Gear, 1) then
        begin
            Gear^.dY := - Gear^.dY * Gear^.Elasticity;
            if Gear^.dY > - _1div1024 then
            begin
                Gear^.Active := false;
                exit
            end
            else if Gear^.dY < - _0_03 then PlaySound(Gear^.ImpactSound)
        end;

    Gear^.Y := Gear^.Y + Gear^.dY;
    CheckGearDrowning(Gear);
    Gear^.dY := Gear^.dY + cGravity
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBeeWork(Gear: PGear);
var 
    t: hwFloat;
    gX,gY: LongInt;
    nuw: boolean;

const uw: boolean =   false;
begin
    AllInactive := false;
    gX := hwRound(Gear^.X);
    gY := hwRound(Gear^.Y);
    nuw := (cWaterLine < gy + Gear^.Radius);
    if nuw and not uw then
    begin
        AddVisualGear(gX, cWaterLine, vgtSplash);
        AddVisualGear(gX - 3 + Random(6), cWaterLine, vgtDroplet);
        AddVisualGear(gX - 3 + Random(6), cWaterLine, vgtDroplet);
        AddVisualGear(gX - 3 + Random(6), cWaterLine, vgtDroplet);
        AddVisualGear(gX - 3 + Random(6), cWaterLine, vgtDroplet);
        StopSound(Gear^.SoundChannel);
        Gear^.SoundChannel := LoopSound(sndBeeWater);
        uw := nuw
    end
    else if not nuw and uw then
        begin
            AddVisualGear(gX, cWaterLine, vgtSplash);
            StopSound(Gear^.SoundChannel);
            Gear^.SoundChannel := LoopSound(sndBee);
            uw := nuw
        end;


    if (GameTicks and $F) = 0 then
    begin
        if (GameTicks and $30) = 0 then
            AddVisualGear(gX, gY, vgtBeeTrace);
        Gear^.dX := Gear^.Elasticity * (Gear^.dX + _0_000064 * (TargetPoint.X - gX));
        Gear^.dY := Gear^.Elasticity * (Gear^.dY + _0_000064 * (TargetPoint.Y - gY));
        // make sure new speed isn't higher than original one (which we stored in Friction variable)
        t := Gear^.Friction / Distance(Gear^.dX, Gear^.dY);
        Gear^.dX := Gear^.dX * t;
        Gear^.dY := Gear^.dY * t;
    end;

    Gear^.X := Gear^.X + Gear^.dX;
    Gear^.Y := Gear^.Y + Gear^.dY;

    CheckCollision(Gear);
    dec(Gear^.Timer);
    if ((Gear^.State and gstCollision) <> 0) or (Gear^.Timer = 0) then
    begin
        StopSound(Gear^.SoundChannel);
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 50, Gear^.Hedgehog, EXPLAutoSound);
        DeleteGear(Gear);
    end;
end;

procedure doStepBee(Gear: PGear);
begin
    AllInactive := false;
    Gear^.X := Gear^.X + Gear^.dX;
    Gear^.Y := Gear^.Y + Gear^.dY;
    Gear^.dY := Gear^.dY + cGravity;
    CheckCollision(Gear);
    if (Gear^.State and gstCollision) <> 0 then
    begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 50, Gear^.Hedgehog, EXPLAutoSound);
        DeleteGear(Gear);
        exit
    end;
    dec(Gear^.Timer);
    if Gear^.Timer = 0 then
    begin
        Gear^.Hedgehog^.Gear^.Message:= Gear^.Hedgehog^.Gear^.Message and not gmAttack;
        Gear^.Hedgehog^.Gear^.State:= Gear^.Hedgehog^.Gear^.State and not gstAttacking;
        AttackBar:= 0;
        
        Gear^.SoundChannel := LoopSound(sndBee);
        Gear^.Timer := 5000;
        // save initial speed in otherwise unused Friction variable
        Gear^.Friction := Distance(Gear^.dX, Gear^.dY);
        Gear^.doStep := @doStepBeeWork
    end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepShotIdle(Gear: PGear);
begin
    AllInactive := false;
    inc(Gear^.Timer);
    if Gear^.Timer > 75 then
    begin
        DeleteGear(Gear);
        AfterAttack
    end
end;

procedure doStepShotgunShot(Gear: PGear);
var 
    i: LongWord;
    shell: PVisualGear;
begin
    AllInactive := false;

    if ((Gear^.State and gstAnimation) = 0) then
    begin
        dec(Gear^.Timer);
        if Gear^.Timer = 0 then
        begin
            PlaySound(sndShotgunFire);
            shell := AddVisualGear(hwRound(Gear^.x), hwRound(Gear^.y), vgtShell);
            if shell <> nil then
            begin
                shell^.dX := gear^.dX.QWordValue / -17179869184;
                shell^.dY := gear^.dY.QWordValue / -17179869184;
                shell^.Frame := 0
            end;
            Gear^.State := Gear^.State or gstAnimation
        end;
        exit
    end
    else inc(Gear^.Timer);

    i := 200;
    repeat
        Gear^.X := Gear^.X + Gear^.dX;
        Gear^.Y := Gear^.Y + Gear^.dY;
        CheckCollision(Gear);
        if (Gear^.State and gstCollision) <> 0 then
        begin
            Gear^.X := Gear^.X + Gear^.dX * 8;
            Gear^.Y := Gear^.Y + Gear^.dY * 8;
            ShotgunShot(Gear);
            Gear^.doStep := @doStepShotIdle;
            exit
        end;

        CheckGearDrowning(Gear);
        if (Gear^.State and gstDrowning) <> 0 then
        begin
            Gear^.doStep := @doStepShotIdle;
            exit
        end;
        dec(i)
    until i = 0;
    if (hwRound(Gear^.X) and LAND_WIDTH_MASK <> 0) or (hwRound(Gear^.Y) and LAND_HEIGHT_MASK <> 0)
        then
        Gear^.doStep := @doStepShotIdle
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBulletWork(Gear: PGear);
var 
    i, x, y: LongWord;
    oX, oY: hwFloat;
    VGear: PVisualGear;
begin
    AllInactive := false;
    inc(Gear^.Timer);
    i := 80;
    oX := Gear^.X;
    oY := Gear^.Y;
    repeat
        Gear^.X := Gear^.X + Gear^.dX;
        Gear^.Y := Gear^.Y + Gear^.dY;
        x := hwRound(Gear^.X);
        y := hwRound(Gear^.Y);
        if ((y and LAND_HEIGHT_MASK) = 0) and ((x and LAND_WIDTH_MASK) = 0)
           and (Land[y, x] <> 0) then inc(Gear^.Damage);
        if Gear^.Damage > 5 then
            if Gear^.AmmoType = amDEagle then
                AmmoShove(Gear, 7, 20)
        else
            AmmoShove(Gear, Gear^.Timer, 20);
        CheckGearDrowning(Gear);
        dec(i)
    until (i = 0) or (Gear^.Damage > Gear^.Health) or ((Gear^.State and gstDrowning) <> 0);
    if Gear^.Damage > 0 then
    begin
        DrawTunnel(oX, oY, Gear^.dX, Gear^.dY, 82 - i, 1);
        dec(Gear^.Health, Gear^.Damage);
        Gear^.Damage := 0
    end;
    if ((Gear^.State and gstDrowning) <> 0) and (Gear^.Damage < Gear^.Health) and ((not SuddenDeathDmg and (cWaterOpacity < $FF)) or (SuddenDeathDmg and (cSDWaterOpacity < $FF))) then
    begin
        for i:=(Gear^.Health - Gear^.Damage) * 4 downto 0 do
        begin
            if Random(6) = 0 then
                AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtBubble);
            Gear^.X := Gear^.X + Gear^.dX;
            Gear^.Y := Gear^.Y + Gear^.dY;
        end;
    end;

    if (Gear^.Health <= 0)
       or (hwRound(Gear^.X) and LAND_WIDTH_MASK <> 0)
       or (hwRound(Gear^.Y) and LAND_HEIGHT_MASK <> 0) then
    begin
        if (Gear^.Kind = gtSniperRifleShot) and ((GameFlags and gfLaserSight) = 0) then
            cLaserSighting := false;
        if (Ammoz[Gear^.AmmoType].Ammo.NumPerTurn <= CurrentHedgehog^.MultiShootAttacks) and
           ((GameFlags and gfArtillery) = 0) then cArtillery := false;
        
        // Bullet Hit
        if (hwRound(Gear^.X) and LAND_WIDTH_MASK = 0) 
            and (hwRound(Gear^.Y) and LAND_HEIGHT_MASK = 0) then
        begin
            VGear := AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtBulletHit);
            if VGear <> nil then
            begin
                VGear^.Angle := DxDy2Angle(-Gear^.dX, Gear^.dY);
            end;
        end;
        
        // Bullet trail
        VGear := AddVisualGear(
            hwround(CurrentHedgehog^.Gear^.X) + GetLaunchX(CurrentHedgehog^.CurAmmoType, hwSign(CurrentHedgehog^.Gear^.dX), CurrentHedgehog^.Gear^.Angle), 
            hwround(CurrentHedgehog^.Gear^.Y) + GetLaunchY(CurrentHedgehog^.CurAmmoType, CurrentHedgehog^.Gear^.Angle),
            vgtLineTrail
        );
        if VGear <> nil then
        begin
            // http://mantis.freepascal.org/view.php?id=17714 hits again
            VGear^.dX := Gear^.X.QWordValue / SignAs(_1,_1).QWordValue;
            VGear^.dY := Gear^.Y.QWordValue / SignAs(_1,_1).QWordValue;
            
            // reached edge of land. assume infinite beam. Extend it way out past camera
            if (hwRound(Gear^.X) and LAND_WIDTH_MASK <> 0) 
                or (hwRound(Gear^.Y) and LAND_HEIGHT_MASK <> 0) then
            begin
                VGear^.dX := VGear^.dX + (CurrentHedgehog^.Gear^.dX * LAND_WIDTH).QWordValue / SignAs(_1,_1).QWordValue;
                VGear^.dY := VGear^.dY + (CurrentHedgehog^.Gear^.dY * LAND_WIDTH).QWordValue / SignAs(_1,_1).QWordValue;
            end;
            
            VGear^.Timer := 200;
        end;
        
        Gear^.doStep := @doStepShotIdle
    end;
end;

procedure doStepDEagleShot(Gear: PGear);
begin
    PlaySound(sndGun);
    // add an initial step to avoid problem with ammoshove related to calculation of radius + 1 radius as gear widths
    Gear^.X := Gear^.X + Gear^.dX;  
    Gear^.Y := Gear^.Y + Gear^.dY;
    Gear^.doStep := @doStepBulletWork
end;

procedure doStepSniperRifleShot(Gear: PGear);
var 
    HHGear: PGear;
    shell: PVisualGear;
begin
    cArtillery := true;
    HHGear := Gear^.Hedgehog^.Gear;
    HHGear^.State := HHGear^.State or gstNotKickable;
    HedgehogChAngle(HHGear);
    if not cLaserSighting then
        // game does not have default laser sight. turn it on and give them a chance to aim
    begin
        cLaserSighting := true;
        HHGear^.Message := 0;
        if (HHGear^.Angle - 32 >= 0) then dec(HHGear^.Angle,32)
    end;

    if (HHGear^.Message and gmAttack) <> 0 then
    begin
        shell := AddVisualGear(hwRound(Gear^.x), hwRound(Gear^.y), vgtShell);
        if shell <> nil then
        begin
            shell^.dX := gear^.dX.QWordValue / -8589934592;
            shell^.dY := gear^.dY.QWordValue / -8589934592;
            shell^.Frame := 1
        end;
        Gear^.State := Gear^.State or gstAnimation;
        Gear^.dX := SignAs(AngleSin(HHGear^.Angle), HHGear^.dX) * _0_5;
        Gear^.dY := -AngleCos(HHGear^.Angle) * _0_5;
        PlaySound(sndGun);
        // add an initial step to avoid problem with ammoshove related to calculation of radius + 1 radius as gear widths
        Gear^.X := Gear^.X + Gear^.dX;  
        Gear^.Y := Gear^.Y + Gear^.dY;
        Gear^.doStep := @doStepBulletWork;
    end
    else
        if (GameTicks mod 32) = 0 then
            if (GameTicks mod 4096) < 2048 then
            begin
                if (HHGear^.Angle + 1 <= cMaxAngle) then inc(HHGear^.Angle)
            end
    else
        if (HHGear^.Angle - 1 >= 0) then dec(HHGear^.Angle);

    if (TurnTimeLeft > 0) then
        dec(TurnTimeLeft)
    else
    begin
        DeleteGear(Gear);
        AfterAttack
    end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepActionTimer(Gear: PGear);
begin
    dec(Gear^.Timer);
    case Gear^.Kind of 
        gtATStartGame: 
    begin
        AllInactive := false;
        if Gear^.Timer = 0 then
        begin
            AddCaption(trmsg[sidStartFight], cWhiteColor, capgrpGameState);
        end
    end;
    gtATSmoothWindCh: 
begin
    if Gear^.Timer = 0 then
    begin
        if WindBarWidth < Gear^.Tag then inc(WindBarWidth)
        else if WindBarWidth > Gear^.Tag then dec(WindBarWidth);
        if WindBarWidth <> Gear^.Tag then Gear^.Timer := 10;
    end
end;
gtATFinishGame: 
begin
    AllInactive := false;
    if Gear^.Timer = 1000 then
    begin
        ScreenFade := sfToBlack;
        ScreenFadeValue := 0;
        ScreenFadeSpeed := 1;
    end;
    if Gear^.Timer = 0 then
    begin
        SendIPC('N');
        SendIPC('q');
        GameState := gsExit
    end
end;
end;
if Gear^.Timer = 0 then DeleteGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepPickHammerWork(Gear: PGear);
var 
    i, ei, x, y: LongInt;
    HHGear: PGear;
begin
    AllInactive := false;
    HHGear := Gear^.Hedgehog^.Gear;
    dec(Gear^.Timer);
    if (Gear^.Timer = 0)or((Gear^.Message and gmDestroy) <> 0)or((HHGear^.State and gstHHDriven) =
       0) then
        begin
        StopSound(Gear^.SoundChannel);
        DeleteGear(Gear);
        AfterAttack;
        doStepHedgehogMoving(HHGear);  // for gfInfAttack
        exit
        end;

    x:= hwRound(Gear^.X);
    y:= hwRound(Gear^.Y);
    if (Gear^.Timer mod 33) = 0 then
        begin
        HHGear^.State := HHGear^.State or gstNoDamage;
        doMakeExplosion(x, y + 7, 6, Gear^.Hedgehog, EXPLDontDraw);
        HHGear^.State := HHGear^.State and not gstNoDamage
        end;

    if (Gear^.Timer mod 47) = 0 then
        begin
        // ok. this was an attempt to turn off dust if not actually drilling land.  I have no idea why it isn't working as expected
        if (( (y + 12) and LAND_HEIGHT_MASK) = 0) and ((x and LAND_WIDTH_MASK) = 0) and (Land[y + 12, x] > 255) then 
            for i:= 0 to 1 do
                AddVisualGear(x - 5 + Random(10), y + 12, vgtDust);

        i := x - Gear^.Radius - LongInt(GetRandom(2));
        ei := x + Gear^.Radius + LongInt(GetRandom(2));
        while i <= ei do
            begin
            DrawExplosion(i, y + 3, 3);
            inc(i, 1)
            end;

        if CheckLandValue(hwRound(Gear^.X + Gear^.dX + SignAs(_6,Gear^.dX)), hwRound(Gear^.Y + _1_9)
           , lfIndestructible) then
            begin
            Gear^.X := Gear^.X + Gear^.dX;
            Gear^.Y := Gear^.Y + _1_9;
            end;
        SetAllHHToActive;
        end;
    if TestCollisionYwithGear(Gear, 1) then
        begin
        Gear^.dY := _0;
        SetLittle(HHGear^.dX);
        HHGear^.dY := _0;
        end
    else
        begin
        Gear^.dY := Gear^.dY + cGravity;
        Gear^.Y := Gear^.Y + Gear^.dY;
        if hwRound(Gear^.Y) > cWaterLine then Gear^.Timer := 1
        end;

    Gear^.X := Gear^.X + HHGear^.dX;
    HHGear^.X := Gear^.X;
    HHGear^.Y := Gear^.Y - int2hwFloat(cHHRadius);

    if (Gear^.Message and gmAttack) <> 0 then
        if (Gear^.State and gsttmpFlag) <> 0 then Gear^.Timer := 1
    else
    else
        if (Gear^.State and gsttmpFlag) = 0 then Gear^.State := Gear^.State or gsttmpFlag;
    if ((Gear^.Message and gmLeft) <> 0) then Gear^.dX := - _0_3
    else
        if ((Gear^.Message and gmRight) <> 0) then Gear^.dX := _0_3
    else Gear^.dX := _0;
end;

procedure doStepPickHammer(Gear: PGear);
var 
    i, y: LongInt;
    ar: TRangeArray;
    HHGear: PGear;
begin
    i := 0;
    HHGear := Gear^.Hedgehog^.Gear;

    y := hwRound(Gear^.Y) - cHHRadius * 2;
    while y < hwRound(Gear^.Y) do
    begin
        ar[i].Left := hwRound(Gear^.X) - Gear^.Radius - LongInt(GetRandom(2));
        ar[i].Right := hwRound(Gear^.X) + Gear^.Radius + LongInt(GetRandom(2));
        inc(y, 2);
        inc(i)
    end;

    DrawHLinesExplosions(@ar, 3, hwRound(Gear^.Y) - cHHRadius * 2, 2, Pred(i));
    Gear^.dY := HHGear^.dY;
    DeleteCI(HHGear);

    Gear^.SoundChannel := LoopSound(sndPickhammer);
    doStepPickHammerWork(Gear);
    Gear^.doStep := @doStepPickHammerWork
end;

////////////////////////////////////////////////////////////////////////////////
var 
    BTPrevAngle, BTSteps: LongInt;

procedure doStepBlowTorchWork(Gear: PGear);
var 
    HHGear: PGear;
    b: boolean;
    prevX: LongInt;
begin
    AllInactive := false;
    dec(Gear^.Timer);
    HHGear := Gear^.Hedgehog^.Gear;

    HedgehogChAngle(HHGear);

    b := false;

    if abs(LongInt(HHGear^.Angle) - BTPrevAngle) > 7  then
    begin
        Gear^.dX := SignAs(AngleSin(HHGear^.Angle) * _0_5, HHGear^.dX);
        Gear^.dY := AngleCos(HHGear^.Angle) * ( - _0_5);
        BTPrevAngle := HHGear^.Angle;
        b := true
    end;

    if ((HHGear^.State and gstMoving) <> 0) then
    begin
        doStepHedgehogMoving(HHGear);
        if (HHGear^.State and gstHHDriven) = 0 then Gear^.Timer := 0
    end;

    if Gear^.Timer mod cHHStepTicks = 0 then
    begin
        b := true;
        if Gear^.dX.isNegative then
            HHGear^.Message := (HHGear^.Message and (gmAttack or gmUp or gmDown)) or gmLeft
        else
            HHGear^.Message := (HHGear^.Message and (gmAttack or gmUp or gmDown)) or gmRight;

        if ((HHGear^.State and gstMoving) = 0) then
        begin
            HHGear^.State := HHGear^.State and not gstAttacking;
            prevX := hwRound(HHGear^.X);

            // why the call to HedgehogStep then a further increment of X?
            if (prevX = hwRound(HHGear^.X)) and
               CheckLandValue(hwRound(HHGear^.X + SignAs(_6, HHGear^.dX)), hwRound(HHGear^.Y),
               lfIndestructible) then HedgehogStep(HHGear);

            if (prevX = hwRound(HHGear^.X)) and
               CheckLandValue(hwRound(HHGear^.X + SignAs(_6, HHGear^.dX)), hwRound(HHGear^.Y),
               lfIndestructible) then HHGear^.X := HHGear^.X + SignAs(_1, HHGear^.dX);
            HHGear^.State := HHGear^.State or gstAttacking
        end;

        inc(BTSteps);
        if BTSteps = 7 then
        begin
            BTSteps := 0;
            if CheckLandValue(hwRound(HHGear^.X + Gear^.dX * (cHHRadius + cBlowTorchC) + SignAs(_6,
               Gear^.dX)), hwRound(HHGear^.Y + Gear^.dY * (cHHRadius + cBlowTorchC)),
               lfIndestructible) then
            begin
                Gear^.X := HHGear^.X + Gear^.dX * (cHHRadius + cBlowTorchC);
                Gear^.Y := HHGear^.Y + Gear^.dY * (cHHRadius + cBlowTorchC);
            end;
            HHGear^.State := HHGear^.State or gstNoDamage;
            AmmoShove(Gear, 2, 15);
            HHGear^.State := HHGear^.State and not gstNoDamage
        end;
    end;

    if b then
        DrawTunnel(HHGear^.X - Gear^.dX * cHHRadius, HHGear^.Y - _4 - Gear^.dY * cHHRadius + hwAbs(
                   Gear^.dY) * 7,
        Gear^.dX, Gear^.dY,
        cHHRadius * 5, cHHRadius * 2 + 7);

    if (Gear^.Timer = 0) or ((HHGear^.Message and gmAttack) <> 0) then
    begin
        HHGear^.Message := 0;
        HHGear^.State := HHGear^.State and (not gstNotKickable);
        DeleteGear(Gear);
        AfterAttack
    end
end;

procedure doStepBlowTorch(Gear: PGear);
var 
    HHGear: PGear;
begin
    BTPrevAngle := High(LongInt);
    BTSteps := 0;
    HHGear := Gear^.Hedgehog^.Gear;
    HHGear^.Message := 0;
    HHGear^.State := HHGear^.State or gstNotKickable;
    Gear^.doStep := @doStepBlowTorchWork
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepRope(Gear: PGear);
forward;

procedure doStepRopeAfterAttack(Gear: PGear);
var 
    HHGear: PGear;
begin
    HHGear := Gear^.Hedgehog^.Gear;
    if ((HHGear^.State and gstHHDriven) = 0)
       or (CheckGearDrowning(HHGear))
       or TestCollisionYwithGear(HHGear, 1) then
    begin
        DeleteGear(Gear);
        isCursorVisible := false;
        ApplyAmmoChanges(HHGear^.Hedgehog^);
        exit
    end;

    HedgehogChAngle(HHGear);

    if TestCollisionXwithGear(HHGear, hwSign(HHGear^.dX)) then SetLittle(HHGear^.dX);

    if HHGear^.dY.isNegative and TestCollisionYwithGear(HHGear, -1) then HHGear^.dY := _0;
    HHGear^.X := HHGear^.X + HHGear^.dX;
    HHGear^.Y := HHGear^.Y + HHGear^.dY;
    HHGear^.dY := HHGear^.dY + cGravity;
    if (GameFlags and gfMoreWind) <> 0 then HHGear^.dX := HHGear^.dX + cWindSpeed / HHGear^.Density;

    if (Gear^.Message and gmAttack) <> 0 then
    begin
        Gear^.X := HHGear^.X;
        Gear^.Y := HHGear^.Y;

        ApplyAngleBounds(Gear^.Hedgehog^, amRope);

        Gear^.dX := SignAs(AngleSin(HHGear^.Angle), HHGear^.dX);
        Gear^.dY := -AngleCos(HHGear^.Angle);
        Gear^.Friction := _450 * _0_01 * cRopePercent;
        Gear^.Elasticity := _0;
        Gear^.State := Gear^.State and not gsttmpflag;
        Gear^.doStep := @doStepRope;
    end
end;

procedure doStepRopeWork(Gear: PGear);
var 
    HHGear: PGear;
    len, tx, ty, nx, ny, ropeDx, ropeDy, mdX, mdY: hwFloat;
    lx, ly: LongInt;
    haveCollision,
    haveDivided: boolean;

procedure DeleteMe;
begin
    with HHGear^ do
    begin
        Message := Message and not gmAttack;
        State := (State or gstMoving) and not gstWinner;
    end;
    DeleteGear(Gear)
end;

procedure WaitCollision;
begin
    with HHGear^ do
    begin
        Message := Message and not gmAttack;
        State := State or gstMoving;
    end;
    RopePoints.Count := 0;
    Gear^.Elasticity := _0;
    Gear^.doStep := @doStepRopeAfterAttack
end;

begin
    HHGear := Gear^.Hedgehog^.Gear;

    if ((HHGear^.State and gstHHDriven) = 0)
       or (CheckGearDrowning(HHGear)) then
        begin
        PlaySound(sndRopeRelease);
        DeleteMe;
        exit
        end;

    if (Gear^.Message and gmLeft  <> 0) then HHGear^.dX := HHGear^.dX - _0_0002
    else
        if (Gear^.Message and gmRight <> 0) then HHGear^.dX := HHGear^.dX + _0_0002;

    if not TestCollisionYwithGear(HHGear, 1) then
        begin
        HHGear^.dY := HHGear^.dY + cGravity;
        if (GameFlags and gfMoreWind) <> 0 then HHGear^.dX := HHGear^.dX + cWindSpeed / HHGear^.Density;
        end;

    // vector between hedgehog and rope attaching point
    ropeDx := HHGear^.X - Gear^.X;
    ropeDy := HHGear^.Y - Gear^.Y;

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
        if not (TestCollisionXwithGear(HHGear, hwSign(ropeDx))
           or TestCollisionYwithGear(HHGear, hwSign(ropeDy))) then
            Gear^.Elasticity := Gear^.Elasticity + _0_3;

    if ((Gear^.Message and gmUp) <> 0) and (Gear^.Elasticity > _30) then
        if not (TestCollisionXwithGear(HHGear, -hwSign(ropeDx))
           or TestCollisionYwithGear(HHGear, -hwSign(ropeDy))) then
            Gear^.Elasticity := Gear^.Elasticity - _0_3;

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
    tx := mdX * _0_3; // should be the same as increase step
    ty := mdY * _0_3;

    while len > _3 do
        begin
        lx := hwRound(nx);
        ly := hwRound(ny);
        if ((ly and LAND_HEIGHT_MASK) = 0) and ((lx and LAND_WIDTH_MASK) = 0) and ((Land[ly, lx] and $FF00) <> 0) then
            begin
            ny := _1 / Distance(ropeDx, ropeDy);
            // old rope pos
            nx := ropeDx * ny;
            ny := ropeDy * ny;

            with RopePoints.ar[RopePoints.Count] do
                begin
                X := Gear^.X;
                Y := Gear^.Y;
                if RopePoints.Count = 0 then RopePoints.HookAngle := DxDy2Angle(Gear^.dY, Gear^.dX);
                b := (nx * HHGear^.dY) > (ny * HHGear^.dX);
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
            TryDo(RopePoints.Count <= MAXROPEPOINTS, 'Rope points overflow', true);
            Gear^.Elasticity := Gear^.Elasticity - len;
            Gear^.Friction := Gear^.Friction - len;
            haveDivided := true;
            break
            end;
        nx := nx - tx;
        ny := ny - ty;

        // len := len - _0_3 // should be the same as increase step
        len.QWordValue := len.QWordValue - _0_3.QWordValue;
        end;

    if not haveDivided then
        if RopePoints.Count > 0 then // check whether the last dividing point could be removed
            begin
            tx := RopePoints.ar[Pred(RopePoints.Count)].X;
            ty := RopePoints.ar[Pred(RopePoints.Count)].Y;
            mdX := tx - Gear^.X;
            mdY := ty - Gear^.Y;
            if RopePoints.ar[Pred(RopePoints.Count)].b xor (mdX * (ty - HHGear^.Y) > (tx - HHGear^.X) * mdY) then
                begin
                dec(RopePoints.Count);
                Gear^.X := RopePoints.ar[RopePoints.Count].X;
                Gear^.Y := RopePoints.ar[RopePoints.Count].Y;
                Gear^.Elasticity := Gear^.Elasticity + RopePoints.ar[RopePoints.Count].dLen;
                Gear^.Friction := Gear^.Friction + RopePoints.ar[RopePoints.Count].dLen;

                // restore hog position
                len := _1 / Distance(mdX, mdY);
                mdX := mdX * len;
                mdY := mdY * len;

                HHGear^.X := Gear^.X - mdX * Gear^.Elasticity;
                HHGear^.Y := Gear^.Y - mdY * Gear^.Elasticity;
                end
            end;

    haveCollision := false;
    if TestCollisionXwithGear(HHGear, hwSign(HHGear^.dX)) then
        begin
        HHGear^.dX := -_0_6 * HHGear^.dX;
        haveCollision := true
        end;
    if TestCollisionYwithGear(HHGear, hwSign(HHGear^.dY)) then
        begin
        HHGear^.dY := -_0_6 * HHGear^.dY;
        haveCollision := true
        end;

    if haveCollision
       and (Gear^.Message and (gmLeft or gmRight) <> 0)
       and (Gear^.Message and (gmUp or gmDown) <> 0) then
        begin
        HHGear^.dX := SignAs(hwAbs(HHGear^.dX) + _0_2, HHGear^.dX);
        HHGear^.dY := SignAs(hwAbs(HHGear^.dY) + _0_2, HHGear^.dY)
        end;

    len := hwSqr(HHGear^.dX) + hwSqr(HHGear^.dY);
    if len > _0_64 then
        begin
        len := _0_8 / hwSqrt(len);
        HHGear^.dX := HHGear^.dX * len;
        HHGear^.dY := HHGear^.dY * len;
        end;

    haveCollision:= ((hwRound(Gear^.Y) and LAND_HEIGHT_MASK) = 0) and ((hwRound(Gear^.X) and LAND_WIDTH_MASK) = 0) and ((Land[hwRound(Gear^.Y), hwRound(Gear^.X)] and $FF00) <> 0);

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

        CheckCollisionWithLand(Gear);
        // if we haven't found any collision yet then check the otheer side too
        if (Gear^.State and gstCollision) = 0 then
            begin
            Gear^.dX.isNegative:= not Gear^.dX.isNegative;
            Gear^.dY.isNegative:= not Gear^.dY.isNegative;
            CheckCollisionWithLand(Gear);
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

    if not haveCollision then
        begin
        if (Gear^.State and gsttmpFlag) <> 0 then
            with Gear^.Hedgehog^ do
                begin
                PlaySound(sndRopeRelease);
                if CurAmmoType <> amParachute then
                    WaitCollision
                else
                    DeleteMe
                end
        end
    else
        if (Gear^.State and gsttmpFlag) = 0 then
            Gear^.State := Gear^.State or gsttmpFlag;

end;

procedure doStepRopeAttach(Gear: PGear);
var 
    HHGear: PGear;
    tx, ty, tt: hwFloat;

procedure RemoveFromAmmo;
begin
    if (Gear^.State and gstAttacked) = 0 then
    begin
        OnUsedAmmo(HHGear^.Hedgehog^);
        Gear^.State := Gear^.State or gstAttacked
    end;
    ApplyAmmoChanges(HHGear^.Hedgehog^)
end;

begin
    Gear^.X := Gear^.X - Gear^.dX;
    Gear^.Y := Gear^.Y - Gear^.dY;
    Gear^.Elasticity := Gear^.Elasticity + _1;

    HHGear := Gear^.Hedgehog^.Gear;
    DeleteCI(HHGear);

    if (HHGear^.State and gstMoving) <> 0 then
        begin
        if TestCollisionXwithGear(HHGear, hwSign(HHGear^.dX)) then SetLittle(HHGear^.dX);
        if HHGear^.dY.isNegative and TestCollisionYwithGear(HHGear, -1) then HHGear^.dY := _0;

        HHGear^.X := HHGear^.X + HHGear^.dX;
        Gear^.X := Gear^.X + HHGear^.dX;

        if TestCollisionYwithGear(HHGear, 1) then
            begin
            CheckHHDamage(HHGear);
            HHGear^.dY := _0
            //HHGear^.State:= HHGear^.State and not (gstHHJumping or gstHHHJump);
            end
        else
            begin
            HHGear^.Y := HHGear^.Y + HHGear^.dY;
            Gear^.Y := Gear^.Y + HHGear^.dY;
            HHGear^.dY := HHGear^.dY + cGravity;
            if (GameFlags and gfMoreWind) <> 0 then HHGear^.dX := HHGear^.dX + cWindSpeed / HHGear^.Density
            end;

        tt := Gear^.Elasticity;
        tx := _0;
        ty := _0;
        while tt > _20 do
            begin
            if ((hwRound(Gear^.Y+ty) and LAND_HEIGHT_MASK) = 0) and ((hwRound(Gear^.X+tx) and LAND_WIDTH_MASK) = 0) and ((Land[hwRound(Gear^.Y+ty), hwRound(Gear^.X+tx)] and $FF00) <> 0) then
                begin
                Gear^.X := Gear^.X + tx;
                Gear^.Y := Gear^.Y + ty;
                Gear^.Elasticity := tt;
                Gear^.doStep := @doStepRopeWork;
                PlaySound(sndRopeAttach);
                with HHGear^ do
                    begin
                    State := State and not (gstAttacking or gstHHJumping or gstHHHJump);
                    Message := Message and not gmAttack
                    end;

                RemoveFromAmmo;

                tt := _0;
                exit
                end;
            tx := tx + Gear^.dX + Gear^.dX;
            ty := ty + Gear^.dY + Gear^.dY;
            tt := tt - _2;
            end;
        end;

    CheckCollisionWithLand(Gear);

    if (Gear^.State and gstCollision) <> 0 then
        if Gear^.Elasticity < _10 then
            Gear^.Elasticity := _10000
    else
        begin
        Gear^.doStep := @doStepRopeWork;
        PlaySound(sndRopeAttach);
        with HHGear^ do
            begin
            State := State and not (gstAttacking or gstHHJumping or gstHHHJump);
            Message := Message and not gmAttack
            end;

        RemoveFromAmmo;

        exit
        end;

    if (Gear^.Elasticity > Gear^.Friction)
       or ((Gear^.Message and gmAttack) = 0)
       or ((HHGear^.State and gstHHDriven) = 0)
       or (HHGear^.Damage > 0) then
        begin
        with Gear^.Hedgehog^.Gear^ do
            begin
            State := State and not gstAttacking;
            Message := Message and not gmAttack
            end;
        DeleteGear(Gear)
        end
end;

procedure doStepRope(Gear: PGear);
begin
    Gear^.dX := - Gear^.dX;
    Gear^.dY := - Gear^.dY;
    Gear^.doStep := @doStepRopeAttach;
    PlaySound(sndRopeShot)
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
            Gear^.dX := _0;
            Gear^.dY := _0
        end;
        CalcRotationDirAngle(Gear);
        AllInactive := false
    end
    else
        if ((GameTicks and $3F) = 25) then
            doStepFallingGear(Gear);

    if ((Gear^.State and gsttmpFlag) <> 0) and (Gear^.Health <> 0) then
        if ((Gear^.State and gstAttacking) = 0) then
            begin
            if ((GameTicks and $1F) = 0) then
                if CheckGearNear(Gear, gtHedgehog, 46, 32) <> nil then Gear^.State := Gear^.State or
                                                                                      gstAttacking
            end
        else // gstAttacking <> 0
            begin
            AllInactive := false;
            if (Gear^.Timer and $FF) = 0 then PlaySound(sndMineTick);
            if Gear^.Timer = 0 then
                begin
                if ((Gear^.State and gstWait) <> 0) or
                   (cMineDudPercent = 0) or
                   (getRandom(100) > cMineDudPercent) then
                    begin
                    doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 50, Gear^.Hedgehog, EXPLAutoSound);
                    DeleteGear(Gear)
                    end
                else
                    begin
                    AddVisualGear(hwRound(Gear^.X) - 4  + Random(8), hwRound(Gear^.Y) - 4 - Random(4),
                    vgtSmoke);
                    PlaySound(sndVaporize);
                    Gear^.Health := 0;
                    end;
                exit
                end;
            dec(Gear^.Timer);
            end
    else // gsttmpFlag = 0
        if (TurnTimeLeft = 0) or ((GameFlags and gfInfAttack) <> 0) then Gear^.State := Gear^.State or gsttmpFlag;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSMine(Gear: PGear);
begin
    DeleteCI(Gear);
    // TODO: do real calculation?
    if TestCollisionXwithGear(Gear, 2) or TestCollisionYwithGear(Gear, -2) or TestCollisionXwithGear(Gear, -2) or TestCollisionYwithGear(Gear, 2) then
    begin
        if (hwAbs(Gear^.dX) > _0) or (hwAbs(Gear^.dY) > _0) then
            PlaySound(sndRopeAttach);
        Gear^.dX:= _0;
        Gear^.dY:= _0;
    end
    else
    begin
        doStepFallingGear(Gear);
        AllInactive := false;
        CalcRotationDirAngle(Gear);
    end;
    AddGearCI(Gear);

    if ((Gear^.State and gsttmpFlag) <> 0) and (Gear^.Health <> 0) then
        if ((Gear^.State and gstAttacking) = 0) then
        begin
            if ((GameTicks and $1F) = 0) then
                if CheckGearNear(Gear, gtHedgehog, 46, 32) <> nil then Gear^.State := Gear^.State or
                                                                                      gstAttacking
        end
    else // gstAttacking <> 0
    begin
        AllInactive := false;
        if (Gear^.Timer and $FF) = 0 then PlaySound(sndMineTick);
        if Gear^.Timer = 0 then
        begin
            doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 30, Gear^.Hedgehog, EXPLAutoSound);
            DeleteGear(Gear);
            exit
        end;
        dec(Gear^.Timer);
    end
    else // gsttmpFlag = 0
        if TurnTimeLeft = 0 then Gear^.State := Gear^.State or gsttmpFlag;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepDynamite(Gear: PGear);
begin
    doStepFallingGear(Gear);
    AllInactive := false;
    if Gear^.Timer mod 166 = 0 then inc(Gear^.Tag);
    if Gear^.Timer = 1000 then // might need better timing
        makeHogsWorry(Gear^.X, Gear^.Y, 75);
    if Gear^.Timer = 0 then
    begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 75, Gear^.Hedgehog, EXPLAutoSound);
        DeleteGear(Gear);
        exit
    end;
    dec(Gear^.Timer);
end;

///////////////////////////////////////////////////////////////////////////////

(*
TODO
Increase damage as barrel smokes?
Try tweaking friction some more
*)
procedure doStepRollingBarrel(Gear: PGear);
var 
    i: LongInt;
    particle: PVisualGear;
begin
    Gear^.State := Gear^.State or gstAnimation;
    if ((Gear^.dX.QWordValue <> 0) or (Gear^.dY.QWordValue <> 0))  then
    begin
        DeleteCI(Gear);
        AllInactive := false;
        if not Gear^.dY.isNegative and (Gear^.dY > _0_2) and TestCollisionYwithGear(Gear, 1) then
        begin
            Gear^.State := Gear^.State or gsttmpFlag;
            inc(Gear^.Damage, hwRound(Gear^.dY * _70));
            for i:= min(12, hwRound(Gear^.dY*_10)) downto 0 do
            begin
                particle := AddVisualGear(hwRound(Gear^.X) - 5 + Random(10), hwRound(Gear^.Y) + 12,
                            vgtDust);
                if particle <> nil then particle^.dX := particle^.dX + (Gear^.dX.QWordValue / 21474836480)
            end
        end
        else if not Gear^.dX.isNegative and (Gear^.dX > _0_2) and TestCollisionXwithGear(Gear, 1)
                 then
                 inc(Gear^.Damage, hwRound(Gear^.dX * _70))
        else if Gear^.dY.isNegative and (Gear^.dY < -_0_2) and TestCollisionYwithGear(Gear, -1)
                 then
                 inc(Gear^.Damage, hwRound(Gear^.dY * -_70))
        else if Gear^.dX.isNegative and (Gear^.dX < -_0_2) and TestCollisionXwithGear(Gear, -1)
                 then
                 inc(Gear^.Damage, hwRound(Gear^.dX * -_70));

        doStepFallingGear(Gear);
        CalcRotationDirAngle(Gear);
        //CheckGearDrowning(Gear)
    end
    else
    begin
        Gear^.State := Gear^.State or gsttmpFlag;
        AddGearCI(Gear)
    end;

(*
Attempt to make a barrel knock itself over an edge.  Would need more checks to avoid issues like burn damage
    begin
    x:= hwRound(Gear^.X);
    y:= hwRound(Gear^.Y);
    if (((y+1) and LAND_HEIGHT_MASK) = 0) and ((x and LAND_WIDTH_MASK) = 0) then
        if (Land[y+1, x] = 0) then
            begin
            if (((y+1) and LAND_HEIGHT_MASK) = 0) and (((x+Gear^.Radius-2) and LAND_WIDTH_MASK) = 0) and (Land[y+1, x+Gear^.Radius-2] = 0) then
                Gear^.dX:= -_0_08
            else if (((y+1 and LAND_HEIGHT_MASK)) = 0) and (((x-(Gear^.Radius-2)) and LAND_WIDTH_MASK) = 0) and (Land[y+1, x-(Gear^.Radius-2)] = 0) then
                Gear^.dX:= _0_08;
            end;
    if Gear^.dX.QWordValue = 0 then AddGearCI(Gear)
    end; *)

    if not Gear^.dY.isNegative and (Gear^.dY < _0_001) and TestCollisionYwithGear(Gear, 1) then Gear
        ^.dY := _0;
    if hwAbs(Gear^.dX) < _0_001 then Gear^.dX := _0;

    if ((Gear^.Health * 100 div cBarrelHealth) < random(90)) and ((GameTicks and $FF) = 0) then
        if (cBarrelHealth div Gear^.Health) > 2 then
            AddVisualGear(hwRound(Gear^.X) - 16 + Random(32), hwRound(Gear^.Y) - 2, vgtSmoke)
    else
        AddVisualGear(hwRound(Gear^.X) - 16 + Random(32), hwRound(Gear^.Y) - 2, vgtSmokeWhite);
    dec(Gear^.Health, Gear^.Damage);
    Gear^.Damage := 0;
    if Gear^.Health <= 0 then Gear^.doStep := @doStepCase;
    // Hand off to doStepCase for the explosion

end;

procedure doStepCase(Gear: PGear);
var 
    i, x, y: LongInt;
    k: TGearType;
    exBoom: boolean;
    dX, dY: HWFloat;
    hog: PHedgehog;
begin
    k := Gear^.Kind;
    exBoom := false;

    if (Gear^.Message and gmDestroy) > 0 then
    begin
        DeleteGear(Gear);
        FreeActionsList;
        SetAllToActive;
        // something (hh, mine, etc...) could be on top of the case
        with CurrentHedgehog^ do
            if Gear <> nil then Gear^.Message := Gear^.Message and not (gmLJump or gmHJump);
        exit
    end;

    if k = gtExplosives then
    begin
        //if V > _0_03 then Gear^.State:= Gear^.State or gstAnimation;
        if (hwAbs(Gear^.dX) > _0_15) or ((hwAbs(Gear^.dY) > _0_15) and (hwAbs(Gear^.dX) > _0_02))
            then Gear^.doStep := @doStepRollingBarrel;

        if ((Gear^.Health * 100 div cBarrelHealth) < random(90)) and ((GameTicks and $FF) = 0) then
            if (cBarrelHealth div Gear^.Health) > 2 then
                AddVisualGear(hwRound(Gear^.X) - 16 + Random(32), hwRound(Gear^.Y) - 2, vgtSmoke)
        else
            AddVisualGear(hwRound(Gear^.X) - 16 + Random(32), hwRound(Gear^.Y) - 2, vgtSmokeWhite);
        dec(Gear^.Health, Gear^.Damage);
        Gear^.Damage := 0;
        if Gear^.Health <= 0 then
            exBoom := true;
    end;

    if (Gear^.Damage > 0) or exBoom then
    begin
        x := hwRound(Gear^.X);
        y := hwRound(Gear^.Y);
        hog:= Gear^.Hedgehog;

        DeleteGear(Gear);
        // <-- delete gear!

        if k = gtCase then
        begin
            doMakeExplosion(x, y, 25, hog, EXPLAutoSound);
            for i:= 0 to 63 do
                AddGear(x, y, gtFlame, 0, _0, _0, 0);
        end
        else if k = gtExplosives then
            begin
                doMakeExplosion(x, y, 75, hog, EXPLAutoSound);
                for i:= 0 to 31 do
                begin
                    dX := AngleCos(i * 64) * _0_5 * (getrandom + _1);
                    dY := AngleSin(i * 64) * _0_5 * (getrandom + _1);
                    AddGear(x, y, gtFlame, 0, dX, dY, 0);
                    AddGear(x, y, gtFlame, 0, -dX, -dY, 0)^.State := gsttmpFlag;
                end
            end;
        exit
    end;

    if (Gear^.dY.QWordValue <> 0) or (not TestCollisionYwithGear(Gear, 1)) then
    begin
        AllInactive := false;
        Gear^.dY := Gear^.dY + cGravity;
        Gear^.Y := Gear^.Y + Gear^.dY;
        if (not Gear^.dY.isNegative) and (Gear^.dY > _0_001) then SetAllHHToActive;
        if (Gear^.dY.isNegative) and TestCollisionYwithGear(Gear, -1) then Gear^.dY := _0;
        if (not Gear^.dY.isNegative) and TestCollisionYwithGear(Gear, 1) then
        begin
            if (Gear^.dY > _0_2) and (k = gtExplosives) then
                inc(Gear^.Damage, hwRound(Gear^.dY * _70));

            if Gear^.dY > _0_2 then
                for i:= min(12, hwRound(Gear^.dY*_10)) downto 0 do
                    AddVisualGear(hwRound(Gear^.X) - 5 + Random(10), hwRound(Gear^.Y) + 12, vgtDust)
            ;
            Gear^.dY := - Gear^.dY * Gear^.Elasticity;
            if Gear^.dY > - _0_001 then Gear^.dY := _0
            else if Gear^.dY < - _0_03 then
                     PlaySound(Gear^.ImpactSound);
        end;
        //if Gear^.dY > - _0_001 then Gear^.dY:= _0
        CheckGearDrowning(Gear);
    end;

    if (Gear^.dY.QWordValue = 0) then AddGearCI(Gear)
    else if (Gear^.dY.QWordValue <> 0) then DeleteCI(Gear)
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepTarget(Gear: PGear);
begin
    if (Gear^.Timer = 0) and (Gear^.Tag = 0) then
        PlaySound(sndWarp);

    if (Gear^.Tag = 0) and (Gear^.Timer < 1000) then
        inc(Gear^.Timer)
    else if Gear^.Tag = 1 then
        Gear^.Tag := 2
    else if Gear^.Tag = 2 then
             if Gear^.Timer > 0 then
                 dec(Gear^.Timer)
    else
    begin
        DeleteGear(Gear);
        exit;
    end;

    doStepCase(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepIdle(Gear: PGear);
begin
    AllInactive := false;
    dec(Gear^.Timer);
    if Gear^.Timer = 0 then
    begin
        DeleteGear(Gear);
        AfterAttack
    end
end;

procedure doStepShover(Gear: PGear);
var 
    HHGear: PGear;
begin
    HHGear := Gear^.Hedgehog^.Gear;
    HHGear^.State := HHGear^.State or gstNoDamage;
    DeleteCI(HHGear);

    AmmoShove(Gear, 30, 115);

    HHGear^.State := (HHGear^.State and (not gstNoDamage)) or gstMoving;
    Gear^.Timer := 250;
    Gear^.doStep := @doStepIdle
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepWhip(Gear: PGear);
var 
    HHGear: PGear;
    i: LongInt;
begin
    HHGear := Gear^.Hedgehog^.Gear;
    HHGear^.State := HHGear^.State or gstNoDamage;
    DeleteCI(HHGear);

    for i:= 0 to 3 do
        begin
        AmmoShove(Gear, 30, 25);
        Gear^.X := Gear^.X + Gear^.dX * 5
        end;

    HHGear^.State := (HHGear^.State and (not gstNoDamage)) or gstMoving;

    Gear^.Timer := 250;
    Gear^.doStep := @doStepIdle
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFlame(Gear: PGear);
var 
    gX,gY,i: LongInt;
    sticky: Boolean;
    vgt: PVisualGear;
begin
    sticky:= (Gear^.State and gsttmpFlag) <> 0;
    if not sticky then AllInactive := false;

    if not TestCollisionYwithGear(Gear, 1) then
    begin
        AllInactive := false;

        if ((GameTicks mod 100) = 0) then
            begin
            vgt:= AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtFire, gstTmpFlag);
            if vgt <> nil then
                begin
                vgt^.dx:= 0;
                vgt^.dy:= 0;
                vgt^.FrameTicks:= 1800 div (Gear^.Tag mod 3 + 2);
                end;
            end;


        if Gear^.dX.QWordValue > _0_01.QWordValue then
            Gear^.dX := Gear^.dX * _0_995;
        Gear^.dY := Gear^.dY + cGravity;
        // if sticky then Gear^.dY := Gear^.dY + cGravity;
        if Gear^.dY.QWordValue > _0_2.QWordValue then Gear^.dY := Gear^.dY * _0_995;

        //if sticky then Gear^.X := Gear^.X + Gear^.dX else
        Gear^.X := Gear^.X + Gear^.dX + cWindSpeed * 640;
        Gear^.Y := Gear^.Y + Gear^.dY;

        if (hwRound(Gear^.Y) > cWaterLine) then
        begin
            gX := hwRound(Gear^.X);
            for i:= 0 to 3 do
                AddVisualGear(gX - 16 + Random(32), cWaterLine - 16 + Random(16), vgtSteam);
            PlaySound(sndVaporize);
            DeleteGear(Gear);
            exit
        end
    end
    else
    begin
        if sticky then
        begin
            Gear^.Radius := 7;
            AmmoShove(Gear, 2, 30);
            Gear^.Radius := 1
        end;
        if Gear^.Timer > 0 then
        begin
            dec(Gear^.Timer);
            inc(Gear^.Damage)
        end
        else
        begin
            gX := hwRound(Gear^.X);
            gY := hwRound(Gear^.Y);
            // Standard fire
            if not sticky then
            begin
                if ((GameTicks and $1) = 0) then
                    begin
                    Gear^.Radius := 7;
                    AmmoShove(Gear, 4, 150);
                    Gear^.Radius := 1;
                    end
                else if ((GameTicks and $3) = 3) then doMakeExplosion(gX, gY, 6, Gear^.Hedgehog, 0);//, EXPLNoDamage); 
                //DrawExplosion(gX, gY, 4);
                if ((GameTicks and $7) = 0) and (Random(2) = 0) then
                    for i:= 1 to Random(2)+1 do
                        AddVisualGear(gX - 3 + Random(6), gY - 2, vgtSmoke);
                if Gear^.Health > 0 then dec(Gear^.Health);
                Gear^.Timer := 450 - Gear^.Tag * 8
            end
            else
            begin
                // Modified fire
                if ((GameTicks and $7FF) = 0) and ((GameFlags and gfSolidLand) = 0) then
                begin
                    DrawExplosion(gX, gY, 4);

                    for i:= 0 to Random(3) do
                        AddVisualGear(gX - 3 + Random(6), gY - 2, vgtSmoke);
                end;

// This one is interesting.  I think I understand the purpose, but I wonder if a bit more fuzzy of kicking could be done with getrandom.
                Gear^.Timer := 100 - Gear^.Tag * 3;
                if (Gear^.Damage > 3000+Gear^.Tag*1500) then Gear^.Health := 0
            end
        end
    end;
    if Gear^.Health = 0 then
    begin
        gX := hwRound(Gear^.X);
        gY := hwRound(Gear^.Y);
        if not sticky then
        begin
            if ((GameTicks and $3) = 0) and (Random(1) = 0) then
            begin
                for i:= 1 to Random(2)+1 do
                begin
                    AddVisualGear(gX - 3 + Random(6), gY - 2, vgtSmoke);
                end;
            end;
        end
        else
        begin
            for i:= 0 to Random(3) do
            begin
                AddVisualGear(gX - 3 + Random(6), gY - 2, vgtSmoke);
            end;
        end;

        DeleteGear(Gear)
    end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFirePunchWork(Gear: PGear);
var 
    HHGear: PGear;
begin
    AllInactive := false;
    if ((Gear^.Message and gmDestroy) <> 0) then
    begin
        DeleteGear(Gear);
        AfterAttack;
        exit
    end;

    HHGear := Gear^.Hedgehog^.Gear;
    if hwRound(HHGear^.Y) <= Gear^.Tag - 2 then
    begin
        Gear^.Tag := hwRound(HHGear^.Y);
        DrawTunnel(HHGear^.X - int2hwFloat(cHHRadius), HHGear^.Y - _1, _0_5, _0, cHHRadius * 4, 2);
        HHGear^.State := HHGear^.State or gstNoDamage;
        Gear^.Y := HHGear^.Y;
        AmmoShove(Gear, 30, 40);
        HHGear^.State := HHGear^.State and not gstNoDamage
    end;

    HHGear^.dY := HHGear^.dY + cGravity;
    if not (HHGear^.dY.isNegative) then
    begin
        HHGear^.State := HHGear^.State or gstMoving;
        DeleteGear(Gear);
        AfterAttack;
        exit
    end;

    if CheckLandValue(hwRound(HHGear^.X), hwRound(HHGear^.Y + HHGear^.dY + SignAs(_6,Gear^.dY)),
       lfIndestructible) then
        HHGear^.Y := HHGear^.Y + HHGear^.dY
end;

procedure doStepFirePunch(Gear: PGear);
var 
    HHGear: PGear;
begin
    AllInactive := false;
    HHGear := Gear^.Hedgehog^.Gear;
    DeleteCI(HHGear);
    HHGear^.X := int2hwFloat(hwRound(HHGear^.X)) - _0_5;
    HHGear^.dX := SignAs(cLittle, Gear^.dX);

    HHGear^.dY := - _0_3;

    Gear^.X := HHGear^.X;
    Gear^.dX := SignAs(_0_45, Gear^.dX);
    Gear^.dY := - _0_9;
    Gear^.doStep := @doStepFirePunchWork;
    DrawTunnel(HHGear^.X - int2hwFloat(cHHRadius), HHGear^.Y + _1, _0_5, _0, cHHRadius * 4, 5);

    PlaySound(TSound(ord(sndFirePunch1) + GetRandom(6)), HHGear^.Hedgehog^.Team^.
    voicepack)
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepParachuteWork(Gear: PGear);
var 
    HHGear: PGear;
begin
    HHGear := Gear^.Hedgehog^.Gear;

    inc(Gear^.Timer);

    if TestCollisionYwithGear(HHGear, 1)
       or ((HHGear^.State and gstHHDriven) = 0)
       or CheckGearDrowning(HHGear)
       or ((Gear^.Message and gmAttack) <> 0) then
    begin
        with HHGear^ do
        begin
            Message := 0;
            SetLittle(dX);
            dY := _0;
            State := State or gstMoving;
        end;
        DeleteGear(Gear);
        isCursorVisible := false;
        ApplyAmmoChanges(HHGear^.Hedgehog^);
        exit
    end;

    HHGear^.X := HHGear^.X + cWindSpeed * 200;

    if (Gear^.Message and gmLeft) <> 0 then HHGear^.X := HHGear^.X - cMaxWindSpeed * 80
    else if (Gear^.Message and gmRight) <> 0 then HHGear^.X := HHGear^.X + cMaxWindSpeed * 80;
    if (Gear^.Message and gmUp) <> 0 then HHGear^.Y := HHGear^.Y - cGravity * 40
    else if (Gear^.Message and gmDown) <> 0 then HHGear^.Y := HHGear^.Y + cGravity * 40;

    // don't drift into obstacles
    if TestCollisionXwithGear(HHGear, hwSign(HHGear^.dX)) then
        HHGear^.X := HHGear^.X - int2hwFloat(hwSign(HHGear^.dX));
    HHGear^.Y := HHGear^.Y + cGravity * 100;
    Gear^.X := HHGear^.X;
    Gear^.Y := HHGear^.Y
end;

procedure doStepParachute(Gear: PGear);
var 
    HHGear: PGear;
begin
    HHGear := Gear^.Hedgehog^.Gear;

    DeleteCI(HHGear);

    AfterAttack;

    HHGear^.State := HHGear^.State and not (gstAttacking or gstAttacked or gstMoving);
    HHGear^.Message := HHGear^.Message and not gmAttack;

    Gear^.doStep := @doStepParachuteWork;

    Gear^.Message := HHGear^.Message;
    doStepParachuteWork(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepAirAttackWork(Gear: PGear);
begin
    AllInactive := false;
    Gear^.X := Gear^.X + cAirPlaneSpeed * Gear^.Tag;

    if (Gear^.Health > 0)and(not (Gear^.X < Gear^.dX))and(Gear^.X < Gear^.dX + cAirPlaneSpeed) then
    begin
        dec(Gear^.Health);
        case Gear^.State of 
            0: FollowGear := AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtAirBomb, 0, cBombsSpeed *
                             Gear^.Tag, _0, 0);
            1: FollowGear := AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtMine,    0, cBombsSpeed *
                             Gear^.Tag, _0, 0);
            2: FollowGear := AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtNapalmBomb, 0, cBombsSpeed *
                             Gear^.Tag, _0, 0);
            3: FollowGear := AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtDrill, gsttmpFlag, cBombsSpeed *
                             Gear^.Tag, _0, 0);
            //4: FollowGear := AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtWaterMelon, 0, cBombsSpeed *
            //                 Gear^.Tag, _0, 5000);
        end;
        Gear^.dX := Gear^.dX + int2hwFloat(30 * Gear^.Tag)
    end;

    if (GameTicks and $3F) = 0 then
        AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtSmokeTrace);

    if (hwRound(Gear^.X) > (LAND_WIDTH+1024)) or (hwRound(Gear^.X) < -1024) then DeleteGear(Gear)
end;

procedure doStepAirAttack(Gear: PGear);
begin
    AllInactive := false;

    if Gear^.X.QWordValue = 0 then
    begin
        Gear^.Tag :=  1;
        Gear^.X := -_1024;
    end
    else
    begin
        Gear^.Tag := -1;
        Gear^.X := int2hwFloat(LAND_WIDTH + 1024);
    end;

    Gear^.Y := int2hwFloat(topY-300);
    Gear^.dX := int2hwFloat(TargetPoint.X - 5 * Gear^.Tag * 15);

    // calcs for Napalm Strike, so that it will hit the target (without wind at least :P)
    if (Gear^.State = 2) then
        Gear^.dX := Gear^.dX - cBombsSpeed * Gear^.Tag * 1000 // ^.Timer of gtNapalmBomb, make it a constant var if you prefer that :P
    // calcs for regular falling gears
    else if (int2hwFloat(TargetPoint.Y) - Gear^.Y > _0) then
            Gear^.dX := Gear^.dX - cBombsSpeed * hwSqrt((int2hwFloat(TargetPoint.Y) - Gear^.Y) * 2 /
                cGravity) * Gear^.Tag;

    Gear^.Health := 6;
    Gear^.doStep := @doStepAirAttackWork;
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepAirBomb(Gear: PGear);
begin
    AllInactive := false;
    doStepFallingGear(Gear);
    if (Gear^.State and gstCollision) <> 0 then
    begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 30, Gear^.Hedgehog, EXPLAutoSound);
        DeleteGear(Gear);
        performRumble();
        exit
    end;
    if (GameTicks and $3F) = 0 then
        AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtSmokeTrace)
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepGirder(Gear: PGear);
var 
    HHGear: PGear;
    x, y, tx, ty: hwFloat;
begin
    AllInactive := false;

    HHGear := Gear^.Hedgehog^.Gear;
    tx := int2hwFloat(TargetPoint.X);
    ty := int2hwFloat(TargetPoint.Y);
    x := HHGear^.X;
    y := HHGear^.Y;

    if (Distance(tx - x, ty - y) > _256) or
       not TryPlaceOnLand(TargetPoint.X - SpritesData[sprAmGirder].Width div 2,
       TargetPoint.Y - SpritesData[sprAmGirder].Height div 2,
       sprAmGirder, Gear^.State, true) then
    begin
        PlaySound(sndDenied);
        HHGear^.Message := HHGear^.Message and not gmAttack;
        HHGear^.State := HHGear^.State and not gstAttacking;
        HHGear^.State := HHGear^.State or gstHHChooseTarget;
        isCursorVisible := true;
        DeleteGear(Gear)
    end
    else 
    begin
        PlaySound(sndPlaced);
        DeleteGear(Gear);
        AfterAttack;
    end;

    HHGear^.State := HHGear^.State and not (gstAttacking or gstAttacked);
    HHGear^.Message := HHGear^.Message and not gmAttack;
    TargetPoint.X := NoPointX
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepTeleportAfter(Gear: PGear);
var 
    HHGear: PGear;
begin
    Gear^.Hedgehog^.Unplaced := false;
    HHGear := Gear^.Hedgehog^.Gear;
    HHGear^.Y := HHGear^.Y + HHGear^.dY;
    // hedgehog falling to collect cases
    HHGear^.dY := HHGear^.dY + cGravity;
    if TestCollisionYwithGear(HHGear, 1)
       or CheckGearDrowning(HHGear) then
    begin
        DeleteGear(Gear);
        AfterAttack
    end
end;

procedure doStepTeleportAnim(Gear: PGear);
begin
    inc(Gear^.Timer);
    if Gear^.Timer = 65 then
    begin
        Gear^.Timer := 0;
        inc(Gear^.Pos);
        if Gear^.Pos = 11 then
            Gear^.doStep := @doStepTeleportAfter
    end;
end;

procedure doStepTeleport(Gear: PGear);
var 
    HHGear: PGear;
begin
    AllInactive := false;

    HHGear := Gear^.Hedgehog^.Gear;
    if not TryPlaceOnLand(TargetPoint.X - SpritesData[sprHHTelepMask].Width div 2,
       TargetPoint.Y - SpritesData[sprHHTelepMask].Height div 2,
       sprHHTelepMask, 0, false) then
    begin
        HHGear^.Message := HHGear^.Message and not gmAttack;
        HHGear^.State := HHGear^.State and not gstAttacking;
        HHGear^.State := HHGear^.State or gstHHChooseTarget;
        DeleteGear(Gear);
        isCursorVisible := true;
        PlaySound(sndDenied)
    end
    else
    begin
        DeleteCI(HHGear);
        SetAllHHToActive;
        Gear^.doStep := @doStepTeleportAnim;

  // copy old HH position and direction to Gear (because we need them for drawing the vanishing hog)
        Gear^.dX := HHGear^.dX;
        // retrieve the cursor direction (it was previously copied to X so it doesn't get lost)
        HHGear^.dX.isNegative := (Gear^.X.QWordValue <> 0);
        Gear^.X := HHGear^.X;
        Gear^.Y := HHGear^.Y;
        HHGear^.X := int2hwFloat(TargetPoint.X);
        HHGear^.Y := int2hwFloat(TargetPoint.Y);
        HHGear^.State := HHGear^.State or gstMoving;
        playSound(sndWarp)
    end;
    TargetPoint.X := NoPointX;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSwitcherWork(Gear: PGear);
var 
    HHGear: PGear;
    Msg, State: Longword;
begin
    AllInactive := false;

    if ((Gear^.Message and not gmSwitch) <> 0) or (TurnTimeLeft = 0) then
    begin
        HHGear := Gear^.Hedgehog^.Gear;
        Msg := Gear^.Message and not gmSwitch;
        DeleteGear(Gear);
        OnUsedAmmo(HHGear^.Hedgehog^);
        ApplyAmmoChanges(HHGear^.Hedgehog^);

        HHGear := CurrentHedgehog^.Gear;
        ApplyAmmoChanges(HHGear^.Hedgehog^);
        HHGear^.Message := Msg;
        exit
    end;

    if (Gear^.Message and gmSwitch) <> 0 then
    begin
        HHGear := CurrentHedgehog^.Gear;
        HHGear^.Message := HHGear^.Message and not gmSwitch;
        Gear^.Message := Gear^.Message and not gmSwitch;
        State := HHGear^.State;
        HHGear^.State := 0;
        HHGear^.Active := false;
        HHGear^.Z := cHHZ;
        RemoveGearFromList(HHGear);
        InsertGearToList(HHGear);

        PlaySound(sndSwitchHog);

        repeat
            CurrentTeam^.CurrHedgehog := Succ(CurrentTeam^.CurrHedgehog) mod (CurrentTeam^.
                                         HedgehogsNumber);
        until (CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear <> nil);

        CurrentHedgehog := @CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog];

        HHGear := CurrentHedgehog^.Gear;
        HHGear^.State := State;
        HHGear^.Active := true;
        FollowGear := HHGear;
        HHGear^.Z := cCurrHHZ;
        RemoveGearFromList(HHGear);
        InsertGearToList(HHGear);
        Gear^.X := HHGear^.X;
        Gear^.Y := HHGear^.Y
    end;
end;

procedure doStepSwitcher(Gear: PGear);
var 
    HHGear: PGear;
begin
    Gear^.doStep := @doStepSwitcherWork;

    HHGear := Gear^.Hedgehog^.Gear;
    with HHGear^ do
    begin
        State := State and not gstAttacking;
        Message := Message and not gmAttack
    end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepMortar(Gear: PGear);
var 
    dX, dY: hwFloat;
    i: LongInt;
    dxn, dyn: boolean;
begin
    AllInactive := false;
    dxn := Gear^.dX.isNegative;
    dyn := Gear^.dY.isNegative;

    doStepFallingGear(Gear);
    if (Gear^.State and gstCollision) <> 0 then
    begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 20, Gear^.Hedgehog, EXPLAutoSound);

        Gear^.dX.isNegative := not dxn;
        Gear^.dY.isNegative := not dyn;
        for i:= 0 to 4 do
        begin
            dX := Gear^.dX + (GetRandom - _0_5) * _0_03;
            dY := Gear^.dY + (GetRandom - _0_5) * _0_03;
            AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtCluster, 0, dX, dY, 25);
        end;

        DeleteGear(Gear);
        exit
    end;

    if (GameTicks and $3F) = 0 then
        AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtSmokeTrace)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepKamikazeWork(Gear: PGear);

const upd: Longword =   0;
var 
    i: LongWord;
    HHGear: PGear;
begin
    AllInactive := false;

    HHGear := Gear^.Hedgehog^.Gear;
    HHGear^.State := HHGear^.State or gstNoDamage;
    DeleteCI(HHGear);

    Gear^.X := HHGear^.X;
    Gear^.Y := HHGear^.Y;

    i := 2;
    repeat
        Gear^.X := Gear^.X + HHGear^.dX;
        Gear^.Y := Gear^.Y + HHGear^.dY;
        HHGear^.X := Gear^.X;
        HHGear^.Y := Gear^.Y;

        inc(Gear^.Damage, 2);

        //  if TestCollisionXwithGear(HHGear, hwSign(Gear^.dX))
        //      or TestCollisionYwithGear(HHGear, hwSign(Gear^.dY)) then inc(Gear^.Damage, 3);

        dec(i)
    until (i = 0) or (Gear^.Damage > Gear^.Health);

    inc(upd);
    if upd > 3 then
    begin
        if Gear^.Health < 1500 then Gear^.Pos := 2;

        AmmoShove(Gear, 30, 40);

        DrawTunnel(HHGear^.X - HHGear^.dX * 10,
                   HHGear^.Y - _2 - HHGear^.dY * 10 + hwAbs(HHGear^.dY) * 2,
        HHGear^.dX,
        HHGear^.dY,
        20 + cHHRadius * 2,
        cHHRadius * 2 + 6);

        upd := 0
    end;

    if Gear^.Health < Gear^.Damage then
    begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 30, Gear^.Hedgehog, EXPLAutoSound);
        AfterAttack;
        DeleteGear(Gear);
        DeleteGear(HHGear);
    end
    else
    begin
        dec(Gear^.Health, Gear^.Damage);
        Gear^.Damage := 0
    end
end;

procedure doStepKamikazeIdle(Gear: PGear);
begin
    AllInactive := false;
    dec(Gear^.Timer);
    if Gear^.Timer = 0 then
    begin
        Gear^.Pos := 1;
        PlaySound(sndKamikaze, Gear^.Hedgehog^.Team^.voicepack);
        Gear^.doStep := @doStepKamikazeWork
    end
end;

procedure doStepKamikaze(Gear: PGear);
var 
    HHGear: PGear;
begin
    AllInactive := false;

    HHGear := Gear^.Hedgehog^.Gear;

    HHGear^.dX := Gear^.dX;
    HHGear^.dY := Gear^.dY;

    Gear^.dX := SignAs(_0_45, Gear^.dX);
    Gear^.dY := - _0_9;

    Gear^.Timer := 550;

    Gear^.doStep := @doStepKamikazeIdle
end;

////////////////////////////////////////////////////////////////////////////////

const cakeh =   27;
    cakeDmg =   75;
var 
    CakePoints: array[0..Pred(cakeh)] of record
        x, y: hwFloat;
    end;
    CakeI: Longword;

procedure doStepCakeExpl(Gear: PGear);
begin
    AllInactive := false;

    inc(Gear^.Tag);
    if Gear^.Tag < 2250 then exit;

    doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), cakeDmg, Gear^.Hedgehog, EXPLAutoSound);
    AfterAttack;
    DeleteGear(Gear)
end;

procedure doStepCakeDown(Gear: PGear);
var 
    gi: PGear;
    dmg: LongInt;
begin
    AllInactive := false;

    inc(Gear^.Tag);
    if Gear^.Tag < 100 then exit;
    Gear^.Tag := 0;

    if Gear^.Pos = 0 then
    begin
        gi := GearsList;
        while gi <> nil do
        begin
            dmg := cakeDmg * 2 - hwRound(Distance(gi^.X - Gear^.X, gi^.Y - Gear^.Y));
            if (dmg > 1) and (gi^.Kind = gtHedgehog) then
                if (CurrentHedgehog^.Gear = gi) and (not gi^.Invulnerable) then
                    gi^.State := gi^.State or gstLoser
            else
                gi^.State := gi^.State or gstWinner;
            gi := gi^.NextGear
        end;
        Gear^.doStep := @doStepCakeExpl;
        PlaySound(sndCake)
    end
    else dec(Gear^.Pos)
end;


procedure doStepCakeWork(Gear: PGear);

const dirs: array[0..3] of TPoint =   ((x: 0; y: -1), (x: 1; y: 0),(x: 0; y: 1),(x: -1; y: 0));
var 
    xx, yy, xxn, yyn: LongInt;
    da: LongInt;
    tdx, tdy: hwFloat;

procedure PrevAngle;
begin
    Gear^.Angle := (LongInt(Gear^.Angle) + 4 - dA) mod 4
end;

procedure NextAngle;
begin
    Gear^.Angle := (LongInt(Gear^.Angle) + 4 + dA) mod 4
end;

begin
    AllInactive := false;

    inc(Gear^.Tag);
    if Gear^.Tag < 7 then exit;

    dA := hwSign(Gear^.dX);
    xx := dirs[Gear^.Angle].x;
    yy := dirs[Gear^.Angle].y;
    xxn := dirs[(LongInt(Gear^.Angle) + 4 + dA) mod 4].x;
    yyn := dirs[(LongInt(Gear^.Angle) + 4 + dA) mod 4].y;

    if (xx = 0) then
        if TestCollisionYwithGear(Gear, yy) then
            PrevAngle
    else
    begin
        Gear^.Tag := 0;
        Gear^.Y := Gear^.Y + int2hwFloat(yy);
        if not TestCollisionXwithGear(Gear, xxn) then
        begin
            Gear^.X := Gear^.X + int2hwFloat(xxn);
            NextAngle
        end;
    end;

    if (yy = 0) then
        if TestCollisionXwithGear(Gear, xx) then
            PrevAngle
    else
    begin
        Gear^.Tag := 0;
        Gear^.X := Gear^.X + int2hwFloat(xx);
        if not TestCollisionY(Gear, yyn) then
        begin
            Gear^.Y := Gear^.Y + int2hwFloat(yyn);
            NextAngle
        end;
    end;

    if Gear^.Tag = 0 then
    begin
        CakeI := (CakeI + 1) mod cakeh;
        tdx := CakePoints[CakeI].x - Gear^.X;
        tdy := - CakePoints[CakeI].y + Gear^.Y;
        CakePoints[CakeI].x := Gear^.X;
        CakePoints[CakeI].y := Gear^.Y;
        Gear^.DirAngle := DxDy2Angle(tdx, tdy);
    end;

    dec(Gear^.Health);
    Gear^.Timer := Gear^.Health*10;
    Gear^.PortalCounter:= 0;
    // This is not seconds, but at least it is *some* feedback
    if (Gear^.Health = 0) or ((Gear^.Message and gmAttack) <> 0) then
    begin
        FollowGear := Gear;
        Gear^.RenderTimer := false;
        Gear^.doStep := @doStepCakeDown
    end
end;

procedure doStepCakeUp(Gear: PGear);
var 
    i: Longword;
begin
    AllInactive := false;

    inc(Gear^.Tag);
    if Gear^.Tag < 100 then exit;
    Gear^.Tag := 0;

    if Gear^.Pos = 6 then
    begin
        for i:= 0 to Pred(cakeh) do
        begin
            CakePoints[i].x := Gear^.X;
            CakePoints[i].y := Gear^.Y
        end;
        CakeI := 0;
        Gear^.doStep := @doStepCakeWork
    end
    else inc(Gear^.Pos)
end;

procedure doStepCakeFall(Gear: PGear);
begin
    AllInactive := false;

    Gear^.dY := Gear^.dY + cGravity;
    if TestCollisionYwithGear(Gear, 1) then
        Gear^.doStep := @doStepCakeUp
    else
    begin
        Gear^.Y := Gear^.Y + Gear^.dY;
        if CheckGearDrowning(Gear) then AfterAttack
    end
end;

procedure doStepCake(Gear: PGear);
var 
    HHGear: PGear;
begin
    AllInactive := false;

    HHGear := Gear^.Hedgehog^.Gear;
    HHGear^.Message := HHGear^.Message and (not gmAttack);
    DeleteCI(HHGear);
    Gear^.IntersectGear:= nil;

    FollowGear := Gear;

    Gear^.doStep := @doStepCakeFall
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSeductionWork(Gear: PGear);
var 
    x, y: LongInt;
begin
    AllInactive := false;

    Gear^.X := Gear^.X + Gear^.dX;
    Gear^.Y := Gear^.Y + Gear^.dY;
    x := hwRound(Gear^.X);
    y := hwRound(Gear^.Y);

    if ((y and LAND_HEIGHT_MASK) = 0) and ((x and LAND_WIDTH_MASK) = 0) then
        if (Land[y, x] <> 0) then
            begin
            Gear^.dX.isNegative := not Gear^.dX.isNegative;
            Gear^.dY.isNegative := not Gear^.dY.isNegative;
            Gear^.dX := Gear^.dX * _1_5;
            Gear^.dY := Gear^.dY * _1_5 - _0_3;
            AmmoShove(Gear, 0, 40);
            AfterAttack;
            DeleteGear(Gear)
            end
        else
    else
        begin
        AfterAttack;
        DeleteGear(Gear)
        end
end;

procedure doStepSeductionWear(Gear: PGear);
begin
    AllInactive := false;
    inc(Gear^.Timer);
    if Gear^.Timer > 250 then
    begin
        Gear^.Timer := 0;
        inc(Gear^.Pos);
        if Gear^.Pos = 5 then
            PlaySound(sndYoohoo, Gear^.Hedgehog^.Team^.voicepack)
    end;

    if Gear^.Pos = 14 then
        Gear^.doStep := @doStepSeductionWork
end;

procedure doStepSeduction(Gear: PGear);
begin
    AllInactive := false;
    DeleteCI(Gear^.Hedgehog^.Gear);
    Gear^.doStep := @doStepSeductionWear
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepWaterUp(Gear: PGear);
var 
    i: LongWord;
begin
    if (Gear^.Tag = 0) or (cWaterLine = 0) then
        begin
            DeleteGear(Gear);
            exit
        end;

    AllInactive := false;

    inc(Gear^.Timer);
    if Gear^.Timer = 17 then
        Gear^.Timer := 0
    else
        exit;

    if cWaterLine > 0 then
    begin
        dec(cWaterLine);
        for i:= 0 to LAND_WIDTH - 1 do
            Land[cWaterLine, i] := 0;
        SetAllToActive
    end;

    dec(Gear^.Tag);
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepDrill(Gear: PGear);
forward;

procedure doStepDrillDrilling(Gear: PGear);
var 
    t: PGearArray;
    ox, oy: hwFloat;
begin
    AllInactive := false;

    if (Gear^.Timer > 0) and ((Gear^.Timer mod 10) = 0) then
    begin
        ox := Gear^.X;
        oy := Gear^.Y;
        Gear^.X := Gear^.X + Gear^.dX;
        Gear^.Y := Gear^.Y + Gear^.dY;
        DrawTunnel(oX, oY, Gear^.dX, Gear^.dY, 2, 6);
        if (Gear^.Timer mod 30) = 0 then
            AddVisualGear(hwRound(Gear^.X + _20 * Gear^.dX), hwRound(Gear^.Y + _20 * Gear^.dY), vgtDust);
        if (CheckGearDrowning(Gear)) then
        begin
            StopSound(Gear^.SoundChannel);
            exit
        end
    end;

    t := CheckGearsCollision(Gear);
    //fixes drill not exploding when touching HH bug
    if (Gear^.Timer = 0)
       or (t^.Count <> 0)
       or (not TestCollisionYWithGear(Gear, hwSign(Gear^.dY))
       and not TestCollisionXWithGear(Gear, hwSign(Gear^.dX))
       and ((Gear^.State and gsttmpFlag) = 0)) 
// CheckLandValue returns true if the type isn't matched
       or not CheckLandValue(hwRound(Gear^.X), hwRound(Gear^.Y), lfIndestructible) then
        begin
        //out of time or exited ground
        StopSound(Gear^.SoundChannel);
        if (Gear^.State and gsttmpFlag) <> 0 then
            doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 30, Gear^.Hedgehog, EXPLAutoSound)
        else
            doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 50, Gear^.Hedgehog, EXPLAutoSound);
        DeleteGear(Gear);
        exit
        end
    else if not TestCollisionYWithGear(Gear, hwSign(Gear^.dY)) and not TestCollisionXWithGear(Gear, hwSign(Gear^.dX)) then
        begin
        StopSound(Gear^.SoundChannel);
        Gear^.doStep := @doStepDrill
        end;

    dec(Gear^.Timer);
end;

procedure doStepDrill(Gear: PGear);
var 
    t: PGearArray;
    oldDx, oldDy: hwFloat;
    t2: hwFloat;
begin
    AllInactive := false;

    if (Gear^.State and gsttmpFlag) = 0 then
        Gear^.dX := Gear^.dX + cWindSpeed;

    oldDx := Gear^.dX;
    oldDy := Gear^.dY;

    doStepFallingGear(Gear);

    if (GameTicks and $3F) = 0 then
        AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtSmokeTrace);

    if ((Gear^.State and gstCollision) <> 0) then
    begin
        //hit
        Gear^.dX := oldDx;
        Gear^.dY := oldDy;

        t := CheckGearsCollision(Gear);
        if (t^.Count = 0) then
        begin
            //hit the ground not the HH
            t2 := _0_5 / Distance(Gear^.dX, Gear^.dY);
            Gear^.dX := Gear^.dX * t2;
            Gear^.dY := Gear^.dY * t2;
        end
        else
        begin
            //explode right on contact with HH
            if (Gear^.State and gsttmpFlag) <> 0 then
                doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 30, Gear^.Hedgehog, EXPLAutoSound)
            else
                doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 50, Gear^.Hedgehog, EXPLAutoSound);
            DeleteGear(Gear);
            exit;
        end;

        Gear^.SoundChannel := LoopSound(sndDrillRocket);
        Gear^.doStep := @doStepDrillDrilling;
        dec(Gear^.Timer)
    end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBallgunWork(Gear: PGear);
var 
    HHGear: PGear;
    rx, ry: hwFloat;
    gX, gY: LongInt;
begin
    AllInactive := false;
    dec(Gear^.Timer);
    HHGear := Gear^.Hedgehog^.Gear;
    HedgehogChAngle(HHGear);
    gX := hwRound(Gear^.X) + GetLaunchX(amBallgun, hwSign(HHGear^.dX), HHGear^.Angle);
    gY := hwRound(Gear^.Y) + GetLaunchY(amBallgun, HHGear^.Angle);
    if (Gear^.Timer mod 100) = 0 then
    begin
        rx := rndSign(getRandom * _0_1);
        ry := rndSign(getRandom * _0_1);

        AddGear(gx, gy, gtBall, 0,
                SignAs(AngleSin(HHGear^.Angle) * _0_8, HHGear^.dX) + rx,
        AngleCos(HHGear^.Angle) * ( - _0_8) + ry,
        0);

        PlaySound(sndGun);
    end;

    if (Gear^.Timer = 0) or (HHGear^.Damage <> 0) then
    begin
        DeleteGear(Gear);
        AfterAttack
    end
end;

procedure doStepBallgun(Gear: PGear);
var 
    HHGear: PGear;
begin
    HHGear := Gear^.Hedgehog^.Gear;
    HHGear^.Message := HHGear^.Message and not (gmUp or gmDown);
    HHGear^.State := HHGear^.State or gstNotKickable;
    Gear^.doStep := @doStepBallgunWork
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepRCPlaneWork(Gear: PGear);

const cAngleSpeed =   3;
var 
    HHGear: PGear;
    i: LongInt;
    dX, dY: hwFloat;
    fChanged: boolean;
    trueAngle: Longword;
    t: PGear;
begin
    AllInactive := false;

    HHGear := Gear^.Hedgehog^.Gear;
    FollowGear := Gear;

    fChanged := false;
    if ((HHGear^.State and gstHHDriven) = 0) or (Gear^.Timer = 0) then
    begin
        fChanged := true;
        if Gear^.Angle > 2048 then dec(Gear^.Angle)
        else
            if Gear^.Angle < 2048 then inc(Gear^.Angle)
        else fChanged := false
    end
    else
    begin
        if ((Gear^.Message and gmLeft) <> 0) then
        begin
            fChanged := true;
            Gear^.Angle := (Gear^.Angle + (4096 - cAngleSpeed)) mod 4096
        end;

        if ((Gear^.Message and gmRight) <> 0) then
        begin
            fChanged := true;
            Gear^.Angle := (Gear^.Angle + cAngleSpeed) mod 4096
        end
    end;

    if fChanged then
    begin
        Gear^.dX.isNegative := (Gear^.Angle > 2048);
        if Gear^.dX.isNegative then
            trueAngle := 4096 - Gear^.Angle
        else
            trueAngle := Gear^.Angle;

        Gear^.dX := SignAs(AngleSin(trueAngle), Gear^.dX) * _0_25;
        Gear^.dY := AngleCos(trueAngle) * -_0_25;
    end;

    Gear^.X := Gear^.X + Gear^.dX;
    Gear^.Y := Gear^.Y + Gear^.dY;

    if (GameTicks and $FF) = 0 then
        if Gear^.Timer < 3500 then
            AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtEvilTrace)
    else
        AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtSmokeTrace);

    if ((HHGear^.Message and gmAttack) <> 0) and (Gear^.Health <> 0) then
    begin
        HHGear^.Message := HHGear^.Message and not gmAttack;
        AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtAirBomb, 0, Gear^.dX * _0_5, Gear^.dY *
        _0_5, 0);
        dec(Gear^.Health)
    end;

    if ((HHGear^.Message and gmLJump) <> 0)
       and ((Gear^.State and gsttmpFlag) = 0) then
    begin
        Gear^.State := Gear^.State or gsttmpFlag;
        PauseMusic;
        playSound(sndRideOfTheValkyries);
    end;

    // pickup bonuses
    t := CheckGearNear(Gear, gtCase, 36, 36);
    if t <> nil then
        PickUp(HHGear, t);

    CheckCollision(Gear);

    if ((Gear^.State and gstCollision) <> 0) or CheckGearDrowning(Gear) then
    begin
        StopSound(Gear^.SoundChannel);
        StopSound(sndRideOfTheValkyries);
        ResumeMusic;

        if ((Gear^.State and gstCollision) <> 0) then
        begin
            doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 25, Gear^.Hedgehog, EXPLAutoSound);
            for i:= 0 to 32 do
            begin
                dX := AngleCos(i * 64) * _0_5 * (GetRandom + _1);
                dY := AngleSin(i * 64) * _0_5 * (GetRandom + _1);
                AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtFlame, 0, dX, dY, 0);
                AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtFlame, 0, dX, -dY, 0);
            end;
            DeleteGear(Gear)
        end;

        AfterAttack;
        CurAmmoGear := nil;
        if (GameFlags and gfInfAttack) = 0 then TurnTimeLeft := 14 * 125;

        HHGear^.Message := 0;
        ParseCommand('/taunt '#1, true)
    end
end;

procedure doStepRCPlane(Gear: PGear);
var 
    HHGear: PGear;
begin
    HHGear := Gear^.Hedgehog^.Gear;
    HHGear^.Message := 0;
    HHGear^.State := HHGear^.State or gstNotKickable;
    Gear^.Angle := HHGear^.Angle;
    Gear^.Tag := hwSign(HHGear^.dX);
    if HHGear^.dX.isNegative then Gear^.Angle := 4096 - Gear^.Angle;
    Gear^.doStep := @doStepRCPlaneWork
end;

procedure doStepJetpackWork(Gear: PGear);
var 
    HHGear: PGear;
    fuel, i: LongInt;
    move: hwFloat;
    isUnderwater: Boolean;
    bubble: PVisualGear;
begin
    isUnderwater:= cWaterLine < hwRound(Gear^.Y) + Gear^.Radius;
    if Gear^.Pos > 0 then dec(Gear^.Pos);
    AllInactive := false;
    HHGear := Gear^.Hedgehog^.Gear;
    //dec(Gear^.Timer);
    move := _0_2;
    fuel := 50;
(*if (HHGear^.Message and gmPrecise) <> 0 then
    begin
    move:= _0_02;
    fuel:= 5;
    end;*)

    if Gear^.Health > 0 then
        begin
        if (HHGear^.Message and gmUp) <> 0 then
            begin
            if (not HHGear^.dY.isNegative) or (HHGear^.Y > -_256) then
                begin
                if isUnderwater then
                    begin
                    HHGear^.dY := HHGear^.dY - (move * _0_7);
                    for i:= random(10)+10 downto 0 do
                        begin
                        bubble := AddVisualGear(hwRound(HHGear^.X) - 8 + random(16), hwRound(HHGear^.Y) + 16 + random(8), vgtBubble);
                        if bubble <> nil then bubble^.dY:= random(20)/10+0.1;
                        end
                    end
                else HHGear^.dY := HHGear^.dY - move;
                end;
            dec(Gear^.Health, fuel);
            Gear^.MsgParam := Gear^.MsgParam or gmUp;
            Gear^.Timer := GameTicks
            end;
        move.isNegative := (HHGear^.Message and gmLeft) <> 0;
        if (HHGear^.Message and (gmLeft or gmRight)) <> 0 then
            begin
            HHGear^.dX := HHGear^.dX + (move * _0_1);
            if isUnderwater then
                begin
                for i:= random(5)+5 downto 0 do
                    begin
                    bubble := AddVisualGear(hwRound(HHGear^.X)+random(8), hwRound(HHGear^.Y) - 8 + random(16), vgtBubble);
                    if bubble <> nil then 
                        begin
                        bubble^.dX:= (random(10)/10 + 0.02) * -1;
                        if (move.isNegative) then
                            begin
                            bubble^.X := bubble^.X + 28;
                            bubble^.dX:= bubble^.dX * (-1)
                            end
                        else bubble^.X := bubble^.X - 28;
                        end;
                    end
                end;
            dec(Gear^.Health, fuel div 5);
            Gear^.MsgParam := Gear^.MsgParam or (HHGear^.Message and (gmLeft or gmRight));
            Gear^.Timer := GameTicks
            end
        end;

    // erases them all at once :-/
    if (Gear^.Timer <> 0) and (GameTicks - Gear^.Timer > 250) then
        begin
        Gear^.Timer := 0;
        Gear^.MsgParam := 0
        end;

    if Gear^.Health < 0 then Gear^.Health := 0;
    i:= Gear^.Health div 20;
    if (i <> Gear^.Damage) and ((GameTicks and $3F) = 0) then
        begin
        Gear^.Damage:= i;
        //AddCaption('Fuel: '+inttostr(round(Gear^.Health/20))+'%', cWhiteColor, capgrpAmmostate);
        if Gear^.Tex <> nil then FreeTexture(Gear^.Tex);
        Gear^.Tex := RenderStringTex(trmsg[sidFuel] + ': ' + inttostr(i) +
                     '%', cWhiteColor, fntSmall)
        end;

    if HHGear^.Message and (gmAttack or gmUp or gmPrecise or gmLeft or gmRight) <> 0 then Gear^
        .State := Gear^.State and not gsttmpFlag;
    HHGear^.Message := HHGear^.Message and not (gmUp or gmPrecise or gmLeft or gmRight);
    HHGear^.State := HHGear^.State or gstMoving;

    Gear^.X := HHGear^.X;
    Gear^.Y := HHGear^.Y;
    // For some reason I need to reapply followgear here, something else grabs it otherwise.
    if not bShowAmmoMenu and not CurrentTeam^.ExtDriven then FollowGear := HHGear;

    if not isUnderWater and hasBorder and ((HHGear^.X < _0) or (hwRound(HHGear^.X) > LAND_WIDTH)) then HHGear^.dY.isNegative:= false;
    if ((Gear^.State and gsttmpFlag) = 0) or (HHGear^.dY < _0) then doStepHedgehogMoving(HHGear);

    if // (Gear^.Health = 0)
        (HHGear^.Damage <> 0)
        //or CheckGearDrowning(HHGear)
        or (cWaterLine + 512 < hwRound(HHGear^.Y))
        or (TurnTimeLeft = 0)
        // allow brief ground touches - to be fair on this, might need another counter
        or (((GameTicks and $1FF) = 0) and (not HHGear^.dY.isNegative) and TestCollisionYwithGear(
        HHGear, 1))
        or ((Gear^.Message and gmAttack) <> 0) then
        begin
        with HHGear^ do
            begin
            Message := 0;
            Active := true;
            State := State or gstMoving
            end;
        DeleteGear(Gear);
        isCursorVisible := false;
        ApplyAmmoChanges(HHGear^.Hedgehog^);
        //    if Gear^.Tex <> nil then FreeTexture(Gear^.Tex);

//    Gear^.Tex:= RenderStringTex(trmsg[sidFuel] + ': ' + inttostr(round(Gear^.Health / 20)) + '%', cWhiteColor, fntSmall)

//AddCaption(trmsg[sidFuel]+': '+inttostr(round(Gear^.Health/20))+'%', cWhiteColor, capgrpAmmostate);
        end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepJetpack(Gear: PGear);
var 
    HHGear: PGear;
begin
    Gear^.Pos:= 0;
    Gear^.doStep := @doStepJetpackWork;

    HHGear := Gear^.Hedgehog^.Gear;
    FollowGear := HHGear;
    AfterAttack;
    with HHGear^ do
    begin
        State := State and not gstAttacking;
        Message := Message and not (gmAttack or gmUp or gmPrecise or gmLeft or gmRight);
        if (dY < _0_1) and (dY > -_0_1) then
        begin
            Gear^.State := Gear^.State or gsttmpFlag;
            dY := dY - _0_2
        end
    end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBirdyDisappear(Gear: PGear);
begin
    AllInactive := false;
    Gear^.Pos := 0;
    if Gear^.Timer < 2000 then
        inc(Gear^.Timer, 1)
    else
    begin
        DeleteGear(Gear);
    end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBirdyFly(Gear: PGear);
var 
    HHGear: PGear;
    fuel, i: LongInt;
    move: hwFloat;
begin
    HHGear := CurrentHedgehog^.Gear;

    move := _0_2;
    fuel := 50;

    if Gear^.Pos > 0 then
        dec(Gear^.Pos, 1)
    else if (HHGear^.Message and (gmLeft or gmRight or gmUp)) <> 0 then
             Gear^.Pos := 500;

    if HHGear^.dX.isNegative then
        Gear^.Tag := -1
    else
        Gear^.Tag := 1;

    if (HHGear^.Message and gmUp) <> 0 then
        begin
        if (not HHGear^.dY.isNegative) or (HHGear^.Y > -_256) then
            HHGear^.dY := HHGear^.dY - move;
        dec(Gear^.Health, fuel);
        Gear^.MsgParam := Gear^.MsgParam or gmUp;
        end;
    if (HHGear^.Message and gmLeft) <> 0 then move.isNegative := true;
    if (HHGear^.Message and (gmLeft or gmRight)) <> 0 then
        begin
        HHGear^.dX := HHGear^.dX + (move * _0_1);
        dec(Gear^.Health, fuel div 5);
        Gear^.MsgParam := Gear^.MsgParam or (HHGear^.Message and (gmLeft or gmRight));
        end;

    if Gear^.Health < 0 then Gear^.Health := 0;
    if ((GameTicks and $FF) = 0) and (Gear^.Health < 500) then
        for i:= ((500-Gear^.Health) div 250) downto 0 do
            AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtFeather);

    if (HHGear^.Message and gmAttack <> 0) then
        begin
        HHGear^.Message := HHGear^.Message and not gmAttack;
        if Gear^.FlightTime > 0 then
            begin
            AddGear(hwRound(Gear^.X), hwRound(Gear^.Y) + 32, gtEgg, 0, Gear^.dX * _0_5, Gear^.dY, 0);
            PlaySound(sndBirdyLay);
            dec(Gear^.FlightTime)
            end;
        end;

    if HHGear^.Message and (gmUp or gmPrecise or gmLeft or gmRight) <> 0 then 
        Gear^.State := Gear^.State and not gsttmpFlag;
    HHGear^.Message := HHGear^.Message and not (gmUp or gmPrecise or gmLeft or gmRight);
    HHGear^.State := HHGear^.State or gstMoving;

    Gear^.X := HHGear^.X;
    Gear^.Y := HHGear^.Y - int2hwFloat(32);
    // For some reason I need to reapply followgear here, something else grabs it otherwise.
    if not bShowAmmoMenu then FollowGear := HHGear;

    if ((Gear^.State and gsttmpFlag) = 0) or (HHGear^.dY < _0) then doStepHedgehogMoving(HHGear);

    if  (Gear^.Health = 0)
       or (HHGear^.Damage <> 0)
       or CheckGearDrowning(HHGear)
       or (TurnTimeLeft = 0)
       // allow brief ground touches - to be fair on this, might need another counter
       or (((GameTicks and $1FF) = 0) and (not HHGear^.dY.isNegative) and TestCollisionYwithGear(
       HHGear, 1))
       or ((Gear^.Message and gmAttack) <> 0) then
        begin
        with HHGear^ do
            begin
            Message := 0;
            Active := true;
            State := State or gstMoving
            end;
        Gear^.State := Gear^.State or gstAnimation or gstTmpFlag;
        if HHGear^.dY < _0 then
            begin
            Gear^.dX := HHGear^.dX;
            Gear^.dY := HHGear^.dY;
            end;
        Gear^.Timer := 0;
        Gear^.doStep := @doStepBirdyDisappear;
        CurAmmoGear := nil;
        isCursorVisible := false;
        AfterAttack;
        end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBirdyDescend(Gear: PGear);
var 
    HHGear: PGear;
begin
    if Gear^.Timer > 0 then
        dec(Gear^.Timer, 1)
    else if CurrentHedgehog = nil then
        begin
            DeleteGear(Gear);
            AfterAttack;
            exit
        end;
    HHGear := CurrentHedgehog^.Gear;
    HHGear^.Message := HHGear^.Message and not (gmUp or gmPrecise or gmLeft or gmRight);
    if abs(hwRound(HHGear^.Y - Gear^.Y)) > 32 then
    begin
        if Gear^.Timer = 0 then
            Gear^.Y := Gear^.Y + _0_1
    end
    else if Gear^.Timer = 0 then
        begin
            Gear^.doStep := @doStepBirdyFly;
            HHGear^.dY := -_0_2
        end
end;

procedure doStepBirdyAppear(Gear: PGear);
begin
    Gear^.Pos := 0;
    if Gear^.Timer < 2000 then
        inc(Gear^.Timer, 1)
    else
    begin
        Gear^.Timer := 500;
        Gear^.dX := _0;
        Gear^.dY := _0;
        Gear^.State :=  Gear^.State and not gstAnimation;
        Gear^.doStep := @doStepBirdyDescend;
    end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBirdy(Gear: PGear);
var 
    HHGear: PGear;
begin
    gear^.State :=  gear^.State or gstAnimation and not gstTmpFlag;
    Gear^.doStep := @doStepBirdyAppear;
    if CurrentHedgehog = nil then
    begin
        DeleteGear(Gear);
        exit
    end;

    HHGear := CurrentHedgehog^.Gear;

    if HHGear^.dX.isNegative then
        Gear^.Tag := -1
    else
        Gear^.Tag := 1;
    Gear^.Pos := 0;
    AllInactive := false;
    FollowGear := HHGear;
    with HHGear^ do
    begin
        State := State and not gstAttacking;
        Message := Message and not (gmAttack or gmUp or gmPrecise or gmLeft or gmRight)
    end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepEggWork(Gear: PGear);
var 
    vg: PVisualGear;
    i: LongInt;
begin
    AllInactive := false;
    Gear^.dX := Gear^.dX;
    doStepFallingGear(Gear);
    //    CheckGearDrowning(Gear); // already checked for in doStepFallingGear
    CalcRotationDirAngle(Gear);

    if (Gear^.State and gstCollision) <> 0 then
    begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 10, Gear^.Hedgehog, EXPLPoisoned, $C0E0FFE0);
        PlaySound(sndEggBreak);
        AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtEgg);
        vg := AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtEgg);
        if vg <> nil then vg^.Frame := 2;

        for i:= 10 downto 0 do
        begin
            vg := AddVisualGear(hwRound(Gear^.X) - 3 + Random(6), hwRound(Gear^.Y) - 3 + Random(6),
                  vgtDust);
            if vg <> nil then vg^.dX := vg^.dX + (Gear^.dX.QWordValue / 21474836480);
        end;

        DeleteGear(Gear);
        exit
    end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doPortalColorSwitch();
var CurWeapon: PAmmo;
begin
    if (CurrentHedgehog <> nil)
       and (CurrentHedgehog^.Gear <> nil)
       and ((CurrentHedgehog^.Gear^.Message and gmSwitch) <> 0) then
        With CurrentHedgehog^ do
            if (CurAmmoType = amPortalGun) then
            begin
                CurrentHedgehog^.Gear^.Message := CurrentHedgehog^.Gear^.Message and not gmSwitch;
                
                CurWeapon:= GetAmmoEntry(CurrentHedgehog^);
                if CurWeapon^.Pos <> 0 then
                    CurWeapon^.Pos := 0
                else
                    CurWeapon^.Pos := 1;
            end;
end;

procedure doStepPortal(Gear: PGear);
var 
    iterator, conPortal: PGear;
    s, r, nx, ny, ox, oy, poffs, noffs, pspeed, nspeed: hwFloat;
    hasdxy, isbullet, iscake: Boolean;
begin
    doPortalColorSwitch();

    // destroy portal if ground it was attached too is gone
    if ((Land[hwRound(Gear^.Y), hwRound(Gear^.X)] and $FF00) = 0)
       or (Gear^.Timer < 1)
       or (Gear^.Hedgehog <> CurrentHedgehog)
       or (hwRound(Gear^.Y) > cWaterLine) then
    begin
        deleteGear(Gear);
        EXIT;
    end;

    if (TurnTimeLeft < 1)
       or (Gear^.Health < 1) then
        dec(Gear^.Timer);

    if Gear^.Timer < 10000 then
        gear^.RenderTimer := true;

    // abort if there is no other portal connected to this one
    if (Gear^.IntersectGear = nil) then
        exit;
    if ((Gear^.IntersectGear^.Tag and 1) = 0) then // or if it's still moving;
        exit;

    conPortal := Gear^.IntersectGear;

    // check all gears for stuff to port through
    iterator := nil;
    while true do
    begin

        // iterate through GearsList
        if iterator = nil then
            iterator := GearsList
        else
            iterator := iterator^.NextGear;

        // end of list?
        if iterator = nil then
            break;

        // don't port portals or other gear that wouldn't make sense
        if (iterator^.Kind in [gtPortal, gtRope, gtRCPlane])
            or (iterator^.PortalCounter > 32) then
             continue;

        // don't port hogs on rope
        // TODO: this will also prevent hogs while falling after rope use from
        //       falling through portals... fix that!
        if (CurrentHedgehog <> nil) and (CurrentHedgehog^.Gear <> nil)
           and (iterator = CurrentHedgehog^.Gear) and (CurAmmoGear <> nil) and (CurAmmoGear^.Kind =
           gtRope) then
            continue;

        // check if gear fits through portal
        if (iterator^.Radius > Gear^.Radius) then
            continue;

        // this is the max range we accept incoming gears in
        r := Int2hwFloat(iterator^.Radius+Gear^.Radius);

        // too far away?
        if (iterator^.X < Gear^.X - r)
           or (iterator^.X > Gear^.X + r)
           or (iterator^.Y < Gear^.Y - r)
           or (iterator^.Y > Gear^.Y + r) then
            continue;

        hasdxy := (((iterator^.dX.QWordValue <> 0) or (iterator^.dY.QWordValue <> 0))
                    or ((iterator^.State or gstMoving) = 0));

        // in case the object is not moving, let's asume it's falling towards the portal
        if not hasdxy then
        begin
            if Gear^.Y < iterator^.Y then
                continue;
            ox:= Gear^.X - iterator^.X;
            oy:= Gear^.Y - iterator^.Y;
        end
        else
        begin
            ox:= iterator^.dX;
            oy:= iterator^.dY;
        end;

        // cake will need extra treatment... it's so delicious and moist!
        iscake:= (iterator^.Kind = gtCake);

        // won't port stuff that does not move towards the front/portal entrance
        if iscake then
        begin
            if not ((iterator^.X - Gear^.X)*ox + (iterator^.Y - Gear^.Y)*oy).isNegative then
                continue;
        end
        else
            if not (Gear^.dX*ox + Gear^.dY*oy).isNegative then
                continue;

        isbullet:= (iterator^.Kind in [gtShotgunShot, gtDEagleShot, gtSniperRifleShot, gtSineGunShot]);

        r:= int2hwFloat(iterator^.Radius);

        if not (isbullet or iscake) then
        begin
            // wow! good candidate there, let's see if the distance and direction is okay!
            if hasdxy then
            begin
                s := r / Distance(iterator^.dX, iterator^.dY);
                ox:= iterator^.X + s * iterator^.dX;
                oy:= iterator^.Y + s * iterator^.dY;
            end
            else
            begin
                ox:= iterator^.X;
                oy:= iterator^.Y + r;
            end;

            if (hwRound(Distance(Gear^.X-ox,Gear^.Y-oy)) > Gear^.Radius + 1 ) then
                continue;
        end;

        // calc gear offset in portal vector direction
        ox := (iterator^.X - Gear^.X);
        oy := (iterator^.Y - Gear^.Y);
        poffs:= (Gear^.dX * ox + Gear^.dY * oy);

        if poffs < _0 then
            continue;

        //
        // gears that make it till here will definately be ported
        //

        // create a normal of the portal vector, but ...
        nx := Gear^.dY;
        ny := Gear^.dX;
        // ... decide where the top is based on the hog's direction when firing the portal
        if Gear^.Elasticity.isNegative then
            nx.isNegative := not nx.isNegative
        else
            ny.isNegative := not ny.isNegative;

        // calc gear offset in portal normal vector direction
        noffs:= (nx * ox + ny * oy);

        // avoid gravity related loops of not really moving gear
        if not iscake and (Gear^.dY.isNegative) and (conPortal^.dY.isNegative)
            and ((iterator^.dX.QWordValue + iterator^.dY.QWordValue) < _0_08.QWordValue)
            and (iterator^.PortalCounter > 0) then
             continue;

        // Until loops are reliably broken
        inc(iterator^.PortalCounter);

        // calc gear speed along to the vector and the normal vector of the portal
        if hasdxy then
        begin
            pspeed:= (Gear^.dX * iterator^.dX + Gear^.dY * iterator^.dY);
            nspeed:= (nx * iterator^.dX + ny * iterator^.dY);
        end
        else
        begin
            pspeed:= hwAbs(cGravity * oy);
            nspeed:= _0;
        end;

        // creating normal vector of connected (exit) portal
        nx := conPortal^.dY;
        ny := conPortal^.dX;
        if conPortal^.Elasticity.isNegative then
            nx.isNegative := not nx.isNegative
        else
            ny.isNegative := not ny.isNegative;

        // inverse cake's normal movement direction,
        // as if it just walked through a hole
        if iscake then
            nspeed.isNegative:= not nspeed.isNegative;

//AddFileLog('poffs:'+cstr(poffs)+' noffs:'+cstr(noffs)+' pspeed:'+cstr(pspeed)+' nspeed:'+cstr(nspeed));
        iterator^.dX := -pspeed * conPortal^.dX + nspeed * nx;
        iterator^.dY := -pspeed * conPortal^.dY + nspeed * ny;

        // make the gear's exit position close to the portal while
        // still respecting the movement direction

         // determine the distance (in exit vector direction)
         // that we want the gear at
         if iscake then
             ox:= (r - _0_7)
         else
             ox:= (r + _1_9);
         s:= ox / poffs;
         poffs:= ox;
         if (nspeed.QWordValue <> 0) and (pspeed > _0) then
             noffs:= noffs * s * (nspeed / pspeed);

        // move stuff with high normal offset closer to the portal's center
        if not isbullet then
        begin
            s := hwAbs(noffs) + r - int2hwFloat(Gear^.Radius);
            if s > _0 then
                noffs:= noffs - SignAs(s,noffs)
        end;

        iterator^.X := conPortal^.X + poffs * conPortal^.dX + noffs * nx;
        iterator^.Y := conPortal^.Y + poffs * conPortal^.dY + noffs * ny;

        if not hasdxy and not (conPortal^.dY.isNegative) then
        begin
            iterator^.dY:= iterator^.dY + hwAbs(cGravity * (iterator^.Y - conPortal^.Y))
        end;

        if not isbullet and (iterator^.Kind <> gtFlake) then
            FollowGear := iterator;
//AddFileLog('portal''d');

{
        s := _0_2 + _0_008 * Gear^.Health;
        iterator^.dX := s * iterator^.dX;
        iterator^.dY := s * iterator^.dY;
}
        // This jiggles gears, to ensure a portal connection just placed under a gear takes effect.
        iterator:= GearsList;
        while iterator <> nil do
            begin
            if iterator^.Kind <> gtPortal then
                begin
                iterator^.Active:= true;
                if iterator^.dY.QWordValue = _0.QWordValue then iterator^.dY.isNegative:= false;
                iterator^.State:= iterator^.State or gstMoving;
                DeleteCI(iterator);
                //inc(iterator^.dY.QWordValue,10);
                end;
            iterator:= iterator^.NextGear
            end;

        if Gear^.Health > 1 then dec(Gear^.Health);

{        // breaks (some) loops
        if Distance(iterator^.dX, iterator^.dY) > _0_96 then
            begin
            iterator^.dX := iterator^.dX + signAs(cGravity * getRandom(1000),iterator^.dX);
            iterator^.dY := iterator^.dY + signAs(cGravity * getRandom(1000),iterator^.dY);
            s := _0_96 / Distance(iterator^.dX, iterator^.dY);
            iterator^.dX := s * iterator^.dX;
            iterator^.dY := s * iterator^.dX;
            end;
}
    end;
end;

procedure doStepMovingPortal_real(Gear: PGear);
var 
    x, y, tx, ty: LongInt;
    s: hwFloat;

procedure loadNewPortalBall(oldPortal: PGear; destroyGear: Boolean);
var
    CurWeapon: PAmmo;
begin
    if CurrentHedgehog <> nil then
        with CurrentHedgehog^ do
            begin
            CurWeapon:= GetAmmoEntry(CurrentHedgehog^);
            if (CurAmmoType = amPortalGun) then
                begin
                if not destroyGear then
                    begin
                    // switch color of ball to opposite of oldPortal
                    if (oldPortal^.Tag and 2) = 0 then
                        CurWeapon^.Pos:= 1
                    else
                        CurWeapon^.Pos:= 0;
                    end;

                // make the ball visible
                CurWeapon^.Timer := 0;
                end
            end;
    if destroyGear then oldPortal^.Timer:= 0;
end;

begin
    x := hwRound(Gear^.X);
    y := hwRound(Gear^.Y);
    tx := 0;
    ty := 0;
    // avoid compiler hints

    if ((y and LAND_HEIGHT_MASK) = 0) and ((x and LAND_WIDTH_MASK) = 0) and (Land[y, x] > 255) then
    begin
        Gear^.State := Gear^.State or gstCollision;
        Gear^.State := Gear^.State and not gstMoving;
        if not calcSlopeTangent(Gear, x, y, tx, ty, 255)
           or (DistanceI(tx,ty) < _12) then // reject shots at too irregular terrain
        begin
            loadNewPortalBall(Gear, true);
            EXIT;
        end;

        // making a normalized normal vector
        s := _1/DistanceI(tx,ty);
        Gear^.dX :=  s * ty;
        Gear^.dY := -s * tx;

        Gear^.DirAngle := DxDy2Angle(-Gear^.dY,Gear^.dX);
        if not Gear^.dX.isNegative then Gear^.DirAngle := 180-Gear^.DirAngle;

        if ((Gear^.IntersectGear = nil)
           or (hwRound(Distance(Gear^.X - Gear^.IntersectGear^.X,Gear^.Y-Gear^.IntersectGear^.Y)) >=
           Gear^.Radius*2))
            then
        begin
            loadNewPortalBall(Gear, false);
            inc(Gear^.Tag);
            Gear^.doStep := @doStepPortal;
        end
        else
            loadNewPortalBall(Gear, true);
    end
    else if (y > cWaterLine) or (y < -LAND_WIDTH)
            or (x > 2*LAND_WIDTH) or (x < -LAND_WIDTH) then
             loadNewPortalBall(Gear, true);
end;

procedure doStepMovingPortal(Gear: PGear);
begin
    doPortalColorSwitch();
    doStepPerPixel(Gear, @doStepMovingPortal_real, true);
    if (Gear^.Timer < 1)
       or (Gear^.Hedgehog <> CurrentHedgehog) then
            deleteGear(Gear);
end;

procedure doStepPortalShot(newPortal: PGear);
var 
    iterator: PGear;
    s: hwFloat;
    CurWeapon: PAmmo;
begin
    s:= Distance (newPortal^.dX, newPortal^.dY);

    // Adds the hog speed (only that part in/directly against shot direction)
    // to the shot speed (which we triple previously btw)
    // (This is done my projecting the hog movement vector onto the shot movement vector and then adding the resulting length
    // to the scaler)
    s := (_2 * s + (newPortal^.dX * CurrentHedgehog^.Gear^.dX + newPortal^.dY * CurrentHedgehog^.Gear^.dY ) / s) / s;
    newPortal^.dX := newPortal^.dX * s;
    newPortal^.dY := newPortal^.dY * s;

    newPortal^.IntersectGear := nil;

    if CurrentHedgehog <> nil then
        With CurrentHedgehog^ do
        begin
            CurWeapon:= GetAmmoEntry(CurrentHedgehog^);
            // let's save the HH's dX's direction so we can decide where the "top" of the portal hole
            newPortal^.Elasticity.isNegative := CurrentHedgehog^.Gear^.dX.isNegative;
            // when doing a backjump the dx is the opposite of the facing direction
            if ((Gear^.State and gstHHHJump) <> 0) and not cArtillery then
                newPortal^.Elasticity.isNegative := not newPortal^.Elasticity.isNegative;

            // make portal gun look unloaded
            if (CurWeapon <> nil) and (CurAmmoType = amPortalGun) then
                CurWeapon^.Timer := CurWeapon^.Timer or 2;

            iterator := GearsList;
            while iterator <> nil do
            begin
                if (iterator^.Kind = gtPortal) then
                    if (iterator <> newPortal) and (iterator^.Timer > 0) then
                    begin
                        if (iterator^.Tag and 2) = (newPortal^.Tag and 2) then
                        begin
                            iterator^.Timer:= 0;
                        end
                        else
                        begin
                            // link portals with each other
                            newPortal^.IntersectGear := iterator;
                            iterator^.IntersectGear := newPortal;
                            iterator^.Health := newPortal^.Health;
                        end;
                    end;
                iterator^.PortalCounter:= 0;
                iterator := iterator^.NextGear
            end;
        end;
    newPortal^.State := newPortal^.State and not gstCollision;
    newPortal^.State := newPortal^.State or gstMoving;
    newPortal^.doStep := @doStepMovingPortal;
end;

procedure doStepPiano(Gear: PGear);
var 
    r0, r1: LongInt;
    odY: hwFloat;
begin
    AllInactive := false;
    if (CurrentHedgehog <> nil) and (CurrentHedgehog^.Gear <> nil) and ((CurrentHedgehog^.Gear^.
       Message and gmSlot) <> 0) then
    begin
        case CurrentHedgehog^.Gear^.MsgParam of 
            0: PlaySound(sndPiano0);
            1: PlaySound(sndPiano1);
            2: PlaySound(sndPiano2);
            3: PlaySound(sndPiano3);
            4: PlaySound(sndPiano4);
            5: PlaySound(sndPiano5);
            6: PlaySound(sndPiano6);
            7: PlaySound(sndPiano7);
            else PlaySound(sndPiano8);
        end;
        AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtNote);
        CurrentHedgehog^.Gear^.MsgParam := 0;
        CurrentHedgehog^.Gear^.Message := CurrentHedgehog^.Gear^.Message and not gmSlot;
    end;

    if (*((Gear^.Pos = 3) and ((GameFlags and gfSolidLand) <> 0)) or*) (Gear^.Pos = 5) then
        // bounce up to 10 times (3 times on gameflagged solid land) before dropping past landscape
    begin
        Gear^.dY := Gear^.dY + cGravity * 2;
        Gear^.Y := Gear^.Y + Gear^.dY;
        CheckGearDrowning(Gear);
        if (Gear^.State and gstDrowning) <> 0 then
        begin
            if CurrentHedgehog^.Gear <> nil then
            begin
                // Drown the hedgehog.  Could also just delete it, but hey, this gets a caption
                CurrentHedgehog^.Gear^.Active := true;
                CurrentHedgehog^.Gear^.X := Gear^.X;
                CurrentHedgehog^.Gear^.Y := int2hwFloat(cWaterLine+cVisibleWater)+_128;
                CurrentHedgehog^.Unplaced := false;
                TurnTimeLeft:= 0
            end;
            ResumeMusic
        end;
        exit
    end;

    odY:= Gear^.dY;
    doStepFallingGear(Gear);

    if (Gear^.State and gstDrowning) <> 0 then
    begin
        if CurrentHedgehog^.Gear <> nil then
        begin
            // Drown the hedgehog.  Could also just delete it, but hey, this gets a caption
            CurrentHedgehog^.Gear^.Active := true;
            CurrentHedgehog^.Gear^.X := Gear^.X;
            CurrentHedgehog^.Gear^.Y := int2hwFloat(cWaterLine+cVisibleWater)+_128;
            CurrentHedgehog^.Unplaced := false;
            TurnTimeLeft:= 0
        end;
        ResumeMusic
    end
    else if (Gear^.State and gstCollision) <> 0 then
        begin
            r0 := GetRandom(21);
            r1 := GetRandom(21);
            doMakeExplosion(hwRound(Gear^.X) - 30 - r0, hwRound(Gear^.Y) + 40, 40 + r1, Gear^.Hedgehog, 0);
            doMakeExplosion(hwRound(Gear^.X) + 30 + r1, hwRound(Gear^.Y) + 40, 40 + r0, Gear^.Hedgehog, 0);
            doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 80 + r0, Gear^.Hedgehog, EXPLAutoSound);
            for r0:= 0 to 4 do
                AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtNote);
            Gear^.dY := odY * -1 + cGravity * 2;
            Gear^.Pos := Gear^.Pos + 1;
        end
    else
        Gear^.dY := Gear^.dY + cGravity * 2;
    // let it fall faster so itdoesn't take too long for the whole attack
end;


////////////////////////////////////////////////////////////////////////////////
procedure doStepSineGunShotWork(Gear: PGear);
var 
    x, y, rX, rY, t, tmp, initHealth: LongInt;
    oX, oY, ldX, ldY, sdX, sdY, sine, lx, ly, amp: hwFloat;
    justCollided: boolean;
begin
    AllInactive := false;
    initHealth := Gear^.Health;
    lX := Gear^.X;
    lY := Gear^.Y;
    ldX := Gear^.dX;
    ldY := Gear^.dY;
    sdy := _0_5/Distance(Gear^.dX,Gear^.dY);
    ldX := ldX * sdy;
    ldY := ldY * sdy;
    sdY := hwAbs(ldX) + hwAbs(ldY);
    sdX := _1 - hwAbs(ldX/sdY);
    sdY := _1 - hwAbs(ldY/sdY);
    if (ldX.isNegative = ldY.isNegative) then sdY := -sdY;

    // initial angle depends on current GameTicks
    t := GameTicks mod 4096;


    // used for a work-around detection of area that is within land array, but outside borders
    justCollided := false;

    repeat
        lX := lX + ldX;
        lY := lY + ldY;
        oX := Gear^.X;
        oY := Gear^.Y;
        rX := hwRound(oX);
        rY := hwRound(oY);
        tmp := t mod 4096;
        amp := _128 * (_1 - hwSqr(int2hwFloat(Gear^.Health)/initHealth));
        sine := amp * AngleSin(tmp mod 2048);
        sine.isNegative := (tmp < 2048);
        inc(t,Gear^.Health div 313);
        Gear^.X := lX + (sine * sdX);
        Gear^.Y := ly + (sine * sdY);
        Gear^.dX := Gear^.X - oX;
        Gear^.dY := Gear^.Y - oY;

        x := hwRound(Gear^.X);
        y := hwRound(Gear^.Y);

        // if borders are on, stop outside land array
        if hasBorder and (((x and LAND_WIDTH_MASK) <> 0) or ((y and LAND_HEIGHT_MASK) <> 0)) then
        begin
            Gear^.Damage := 0;
            Gear^.Health := 0;
        end
        else
        begin
            if (rY <= cWaterLine) or (y <= cWaterLine) then
            begin
                if ((y and LAND_HEIGHT_MASK) = 0) and ((x and LAND_WIDTH_MASK) = 0)
                   and (Land[y, x] <> 0) then
                begin
                    if justCollided then
                    begin
                        Gear^.Damage := 0;
                        Gear^.Health := 0;
                    end
                    else
                    begin
                        inc(Gear^.Damage,3);
                        justCollided := true;
                    end;
                end
                else
                    justCollided := false;

                // kick nearby hogs, dig tunnel and add some fire
                // if at least 5 collisions occured
                if Gear^.Damage > 0 then
                begin
                    DrawExplosion(rX,rY,Gear^.Radius);

                    // kick nearby hogs
                    AmmoShove(Gear, 35, 50);

                    dec(Gear^.Health, Gear^.Damage);
                    Gear^.Damage := 0;

                    // add some fire to the tunnel
                    if getRandom(6) = 0 then
                        AddGear(x - Gear^.Radius + LongInt(getRandom(2 * Gear^.Radius)), y -
                        getRandom(Gear^.Radius + 1), gtFlame, gsttmpFlag, _0, _0, 0);
                end;

                if getRandom(100) = 0 then
                    AddVisualGear(x, y, vgtSmokeTrace); 
            end
            else dec(Gear^.Health, 5); // if underwater get additional damage
        end;

        dec(Gear^.Health);

        // decrease bullet size towards the end
        if (Gear^.Radius > 4) then begin
            if (Gear^.Health <= (initHealth div 3)) then dec(Gear^.Radius) end
        else if (Gear^.Radius > 3) then begin
            if (Gear^.Health <= (initHealth div 4)) then dec(Gear^.Radius) end
        else if (Gear^.Radius > 2) then begin
            if (Gear^.Health <= (initHealth div 5)) then dec(Gear^.Radius) end
        else if (Gear^.Radius > 1) then begin
            if (Gear^.Health <= (initHealth div 6)) then dec(Gear^.Radius) end;

    until (Gear^.Health <= 0);

    DeleteGear(Gear);
    AfterAttack;
end;

procedure doStepSineGunShot(Gear: PGear);
var 
    HHGear: PGear;
begin
    PlaySound(sndSineGun); 

    // push the shooting Hedgehog back
    HHGear := CurrentHedgehog^.Gear;
    Gear^.dX.isNegative := not Gear^.dX.isNegative;
    Gear^.dY.isNegative := not Gear^.dY.isNegative;
    HHGear^.dX := Gear^.dX;
    HHGear^.dY := Gear^.dY;
    AmmoShove(Gear, 0, 80);
    Gear^.dX.isNegative := not Gear^.dX.isNegative;
    Gear^.dY.isNegative := not Gear^.dY.isNegative;

    Gear^.doStep := @doStepSineGunShotWork;
    performRumble();
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFlamethrowerWork(Gear: PGear);
var 
    HHGear: PGear;
    rx, ry, speed: hwFloat;
    i, gX, gY: LongInt;
    Fire: PGear;
begin
    AllInactive := false;
    HHGear := Gear^.Hedgehog^.Gear;
    HedgehogChAngle(HHGear);
    gX := hwRound(Gear^.X) + GetLaunchX(amBallgun, hwSign(HHGear^.dX), HHGear^.Angle);
    gY := hwRound(Gear^.Y) + GetLaunchY(amBallgun, HHGear^.Angle);
    
    if (GameTicks and $FF) = 0 then
        begin
        if (HHGear^.Message and gmRight) <> 0 then
            begin
            if HHGear^.dX.isNegative and (Gear^.Tag < 20) then inc(Gear^.Tag)
            else if Gear^.Tag > 5 then dec(Gear^.Tag);
            end
        else if (HHGear^.Message and gmLeft) <> 0 then
            begin
            if HHGear^.dX.isNegative and (Gear^.Tag > 5) then dec(Gear^.Tag)
            else if Gear^.Tag < 20 then inc(Gear^.Tag);
            end
        end;
    
    dec(Gear^.Timer);
    if Gear^.Timer = 0 then
        begin
        dec(Gear^.Health);
        if (Gear^.Health mod 10) = 0 then
            begin
            rx := rndSign(getRandom * _0_1);
            ry := rndSign(getRandom * _0_1);
            speed := _0_8 * (_10 / Gear^.Tag);
    
            Fire := AddGear(gx, gy, gtFlame, 0,
                        SignAs(AngleSin(HHGear^.Angle) * speed, HHGear^.dX) + rx,
                AngleCos(HHGear^.Angle) * ( - speed) + ry, 0);
            Fire^.State := Fire^.State or gsttmpFlag;
            
            if (Gear^.Health mod 20) = 0 then 
                Fire := AddGear(gx, gy, gtFlame, 0,
                            SignAs(AngleSin(HHGear^.Angle) * speed, HHGear^.dX) + rx,
                    AngleCos(HHGear^.Angle) * ( - speed) + ry, 0);
            end;
        Gear^.Timer:= Gear^.Tag
        end;

    if (Gear^.Health = 0) or (HHGear^.Damage <> 0) then
        begin
        DeleteGear(Gear);
        AfterAttack
        end
    else
        begin
        i:= Gear^.Health div 5;
        if (i <> Gear^.Damage) and ((GameTicks and $3F) = 0) then
            begin
            Gear^.Damage:= i;
            if Gear^.Tex <> nil then FreeTexture(Gear^.Tex);
            Gear^.Tex := RenderStringTex(trmsg[sidFuel] + ': ' + inttostr(i) +
                         '%', cWhiteColor, fntSmall)
            end
        end
end;

procedure doStepFlamethrower(Gear: PGear);
var 
    HHGear: PGear;
begin
    HHGear := Gear^.Hedgehog^.Gear;
    HHGear^.Message := HHGear^.Message and not (gmUp or gmDown or gmLeft or gmRight);
    HHGear^.State := HHGear^.State or gstNotKickable;
    Gear^.doStep := @doStepFlamethrowerWork
end;

procedure doStepPoisonCloud(Gear: PGear);
begin
    if Gear^.Timer = 0 then
    begin
        DeleteGear(Gear);
        exit
    end;
    dec(Gear^.Timer);
    Gear^.X:= Gear^.X + Gear^.dX;
    Gear^.Y:= Gear^.Y + Gear^.dY;
    Gear^.dX := Gear^.dX + cWindSpeed / 4;
    Gear^.dY := Gear^.dY + cGravity / 100;
    if (GameTicks mod 250) = 0 then
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 20, Gear^.Hedgehog, EXPLDontDraw or EXPLNoGfx or EXPLNoDamage or EXPLDoNotTouchAny or EXPLPoisoned);
    AllInactive:= false;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepHammer(Gear: PGear);
var HHGear, tmp, tmp2: PGear;
         t: PGearArray;
         i: LongInt;
begin
HHGear:= Gear^.Hedgehog^.Gear;
HHGear^.State:= HHGear^.State or gstNoDamage;
DeleteCI(HHGear);

t:= CheckGearsCollision(Gear);

for i:= 5 downto 0 do
    AddVisualGear(hwRound(Gear^.X) - 5 + Random(10), hwRound(Gear^.Y) + 12, vgtDust);

i:= t^.Count;
while i > 0 do
    begin
    dec(i);
    tmp:= t^.ar[i];
    if (tmp^.State and gstNoDamage) = 0 then
        if (tmp^.Kind = gtHedgehog) then
            begin
            //tmp^.State:= tmp^.State or gstFlatened;
            ApplyDamage(tmp, CurrentHedgehog, tmp^.Health div 3, dsUnknown);
            //DrawTunnel(tmp^.X, tmp^.Y - _1, _0, _0_5, cHHRadius * 6, cHHRadius * 3);
            tmp2:= AddGear(hwRound(tmp^.X), hwRound(tmp^.Y), gtHammerHit, 0, _0, _0, 0);
            tmp2^.Hedgehog:= tmp^.Hedgehog;
            SetAllToActive
            end
        else
            begin
            end
    end;

HHGear^.State:= HHGear^.State and not gstNoDamage;
Gear^.Timer:= 250;
Gear^.doStep:= @doStepIdle
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepHammerHitWork(Gear: PGear);
var 
    i, ei: LongInt;
    HHGear: PGear;
begin
    AllInactive := false;
    HHGear := Gear^.Hedgehog^.Gear;
    dec(Gear^.Timer);
    if (HHGear = nil) or (Gear^.Timer = 0) or ((Gear^.Message and gmDestroy) <> 0) then
    begin
        DeleteGear(Gear);
        exit
    end;

    if (Gear^.Timer mod 5) = 0 then
    begin
        AddVisualGear(hwRound(Gear^.X) - 5 + Random(10), hwRound(Gear^.Y) + 12, vgtDust);

        i := hwRound(Gear^.X) - Gear^.Radius - LongInt(GetRandom(2));
        ei := hwRound(Gear^.X) + Gear^.Radius + LongInt(GetRandom(2));
        while i <= ei do
        begin
            DrawExplosion(i, hwRound(Gear^.Y) + 3, 3);
            inc(i, 1)
        end;

        if CheckLandValue(hwRound(Gear^.X + Gear^.dX + SignAs(_6,Gear^.dX)), hwRound(Gear^.Y + _1_9)
           , lfIndestructible) then
        begin
            Gear^.X := Gear^.X + Gear^.dX;
            Gear^.Y := Gear^.Y + _1_9;
        end;
        SetAllHHToActive;
    end;
    if TestCollisionYwithGear(Gear, 1) then
    begin
        Gear^.dY := _0;
        SetLittle(HHGear^.dX);
        HHGear^.dY := _0;
    end
    else
    begin
        Gear^.dY := Gear^.dY + cGravity;
        Gear^.Y := Gear^.Y + Gear^.dY;
        if hwRound(Gear^.Y) > cWaterLine then Gear^.Timer := 1
    end;

    Gear^.X := Gear^.X + HHGear^.dX;
    HHGear^.X := Gear^.X;
    HHGear^.Y := Gear^.Y - int2hwFloat(cHHRadius);
end;

procedure doStepHammerHit(Gear: PGear);
var 
    i, y: LongInt;
    ar: TRangeArray;
    HHGear: PGear;
begin
    i := 0;
    HHGear := Gear^.Hedgehog^.Gear;

    y := hwRound(Gear^.Y) - cHHRadius * 2;
    while y < hwRound(Gear^.Y) do
    begin
        ar[i].Left := hwRound(Gear^.X) - Gear^.Radius - LongInt(GetRandom(2));
        ar[i].Right := hwRound(Gear^.X) + Gear^.Radius + LongInt(GetRandom(2));
        inc(y, 2);
        inc(i)
    end;

    DrawHLinesExplosions(@ar, 3, hwRound(Gear^.Y) - cHHRadius * 2, 2, Pred(i));
    Gear^.dY := HHGear^.dY;
    DeleteCI(HHGear);

    doStepHammerHitWork(Gear);
    Gear^.doStep := @doStepHammerHitWork
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepResurrectorWork(Gear: PGear);
var
    graves: TPGearArray;
    resgear: PGear;
    hh: PHedgehog;
    i: LongInt;
begin
    if (TurnTimeLeft > 0) then
        dec(TurnTimeLeft);

    AllInactive := false;
    hh := Gear^.Hedgehog;

    // no, you can't do that here
    {DrawCentered(hwRound(hh^.Gear^.X) + WorldDx, hwRound(hh^.Gear^.Y) + WorldDy -
            cHHRadius - 14 - hh^.HealthTagTex^.h, hh^.HealthTagTex);
    }
    (*DrawCircle(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Radius, 1.5, 0, 0, $FF,
            $FF);*)

    if ((Gear^.Message and gmUp) <> 0) then 
        begin
        if (GameTicks and $F) <> 0 then exit;
        end 
    else if (GameTicks and $1FF) <> 0 then exit;

    if Gear^.Power < 45 then 
        begin
        inc(Gear^.Power);
        if not TestCollisionYwithGear(hh^.Gear, -1) then hh^.Gear^.Y := hh^.Gear^.Y - _1;
        end;

    graves := GearsNear(Gear^.X, Gear^.Y, gtGrave, Gear^.Radius);

    if Length(graves) = 0 then 
        begin
        StopSound(Gear^.SoundChannel);
        Gear^.Timer := 250;
        Gear^.doStep := @doStepIdle;
        exit;
        end;

    if ((Gear^.Message and gmAttack) <> 0) and (hh^.Gear^.Health > 0) and (TurnTimeLeft > 0) then 
        begin
        if Length(graves) <= Gear^.Tag then Gear^.Tag:= 0;
        dec(hh^.Gear^.Health);
        if (hh^.Gear^.Health = 0) and (hh^.Gear^.Damage = 0) then
            hh^.Gear^.Damage:= 1;
        RenderHealth(hh^);
        inc(graves[Gear^.Tag]^.Health);
        inc(Gear^.Tag)
{-for i:= 0 to High(graves) do begin
            if hh^.Gear^.Health > 0 then begin
                dec(hh^.Gear^.Health);
                inc(graves[i]^.Health);
            end;
        end; -}
        end 
    else 
        begin
        // now really resurrect the hogs with the hp saved in the graves
        for i:= 0 to High(graves) do
            if graves[i]^.Health > 0 then
                begin
                resgear := AddGear(hwRound(graves[i]^.X), hwRound(graves[i]^.Y),
                        gtHedgehog, gstWait, _0, _0, 0);
                resgear^.Hedgehog := graves[i]^.Hedgehog;
                resgear^.Health := graves[i]^.Health;
                PHedgehog(graves[i]^.Hedgehog)^.Gear := resgear;
                DeleteGear(graves[i]);
                RenderHealth(resgear^.Hedgehog^);
                RecountTeamHealth(resgear^.Hedgehog^.Team);
                resgear^.Hedgehog^.Effects[heResurrected]:= true;
                if resgear^.Hedgehog^.Hat = 'NoHat' then
                    begin
                    FreeTexture(resgear^.Hedgehog^.HatTex);
                    resgear^.Hedgehog^.HatTex := Surface2Tex(
                        LoadImage(Pathz[ptHats] + '/Reserved/Zombie', ifNone),
                        True)
                    end
                end;

        hh^.Gear^.dY := _0;
        hh^.Gear^.dX := _0;
        doStepHedgehogMoving(hh^.Gear);
        StopSound(Gear^.SoundChannel);
        Gear^.Timer := 250;
        Gear^.doStep := @doStepIdle;
        end
    //if hh^.Gear^.Health = 0 then doStepHedgehogFree(hh^.Gear);
end;

procedure doStepResurrector(Gear: PGear);
var
    graves: TPGearArray;
    i: LongInt;
begin
    AllInactive := false;
    graves := GearsNear(Gear^.X, Gear^.Y, gtGrave, Gear^.Radius);

    if Length(graves) > 0 then
        begin
        for i:= 0 to High(graves) do
            begin
            PHedgehog(graves[i]^.Hedgehog)^.Gear := nil;
            graves[i]^.Health := 0;
            end;
        Gear^.doStep := @doStepResurrectorWork;
        end 
    else 
        begin
        StopSound(Gear^.SoundChannel);
        Gear^.Timer := 250;
        Gear^.doStep := @doStepIdle;
        end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepNapalmBomb(Gear: PGear);
var
    i, gX, gY: LongInt;
    dX, dY: hwFloat;
begin
    AllInactive := false;
    doStepFallingGear(Gear);
    if (Gear^.Timer > 0) and ((Gear^.State and gstCollision) <> 0) then
    begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 10, Gear^.Hedgehog, EXPLAutoSound);
        gX := hwRound(Gear^.X);
        gY := hwRound(Gear^.Y); 
        for i:= 0 to 10 do
        begin
            dX := AngleCos(i * 2) * ((_0_1*(i div 5))) * (GetRandom + _1);
            dY := AngleSin(i * 8) * _0_5 * (GetRandom + _1);
            AddGear(gX, gY, gtFlame, 0, dX, dY, 0);
            AddGear(gX, gY, gtFlame, 0, dX, -dY, 0);
            AddGear(gX, gY, gtFlame, 0, -dX, dY, 0);
            AddGear(gX, gY, gtFlame, 0, -dX, -dY, 0);
        end;
        DeleteGear(Gear);
        exit
    end;
    if (Gear^.Timer = 0) then
    begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 10, Gear^.Hedgehog, EXPLAutoSound);
        for i:= -19 to 19 do
           FollowGear := AddGear(hwRound(Gear^.X) + i div 3, hwRound(Gear^.Y), gtFlame, 0, _0_001 * i, _0, 0);
        DeleteGear(Gear);
        exit
    end;
    if (GameTicks and $3F) = 0 then
        AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtSmokeTrace);
    dec(Gear^.Timer)
end;

////////////////////////////////////////////////////////////////////////////////

