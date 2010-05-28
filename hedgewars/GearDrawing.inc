procedure DrawHH(Gear: PGear);
var i, t: LongInt;
    amt: TAmmoType;
    hx, hy, cx, cy, tx, ty, sx, sy, m: LongInt;  // hedgehog, crosshair, temp, sprite, direction
    lx, ly, dx, dy, ax, ay, aAngle, dAngle, hAngle: real;  // laser, change
    defaultPos, HatVisible: boolean;
    VertexBuffer: array [0..1] of TVertex2f;
    HH: PHedgehog;
begin
HH:= PHedgehog(Gear^.Hedgehog);
if HH^.Unplaced then exit;
m:= 1;
if ((Gear^.State and gstHHHJump) <> 0) and not cArtillery then m:= -1;
if (Gear^.State and gstHHDeath) <> 0 then
    begin
    DrawSprite(sprHHDeath, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 26 + WorldDy, Gear^.Pos);
    exit
    end
else if (Gear^.State and gstHHGone) <> 0 then
    begin
    DrawRotatedF(sprTeleport, hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy, Gear^.Pos, hwSign(Gear^.dX), 0);
    exit
    end;

defaultPos:= true;
HatVisible:= false;

sx:= hwRound(Gear^.X) + 1 + WorldDx;
sy:= hwRound(Gear^.Y) - 3 + WorldDy;

if HH^.Effects[hePoisoned] then
    begin
    Tint($00, $FF, $40, $40);
    DrawRotatedTextureF(SpritesData[sprSmokeWhite].texture, 2, 0, 0, sx, sy, 0, 1, 22, 22, (RealTicks shr 36) mod 360);
    Tint($FF, $FF, $FF, $FF)
    end;

if ((Gear^.State and gstWinner) <> 0) and
   ((CurAmmoGear = nil) or (CurAmmoGear^.Kind <> gtPickHammer)) then
    begin
    DrawHedgehog(sx, sy,
            hwSign(Gear^.dX),
            2,
            0,
            0);
    defaultPos:= false
    end;
if (Gear^.State and gstDrowning) <> 0 then
    begin
    DrawHedgehog(sx, sy,
            hwSign(Gear^.dX),
            1,
            7,
            0);
    defaultPos:= false
    end else
if (Gear^.State and gstLoser) <> 0 then
    begin
    DrawHedgehog(sx, sy,
            hwSign(Gear^.dX),
            2,
            3,
            0);
    defaultPos:= false
    end else

if (Gear^.State and gstHHDriven) <> 0 then
    begin
    if ((Gear^.State and gstHHThinking) = 0) and
       (ShowCrosshair  or ((CurAmmoGear <> nil) and (CurAmmoGear^.Kind = gtRope))) and
       ((Gear^.State and (gstAttacked or gstAnimation)) = 0) then
        begin
(* These calculations are a little complex for a few reasons:
   1: I need to draw the laser from weapon origin to nearest land
   2: I need to start the beam outside the hedgie for attractiveness.
   3: I need to extend the beam beyond land.
   This routine perhaps should be pushed into uStore or somesuch instead of continuuing the increase in size of this function.
*)
        dx:= hwSign(Gear^.dX) * m * Sin(Gear^.Angle * pi / cMaxAngle);
        dy:= - Cos(Gear^.Angle * pi / cMaxAngle);
        if cLaserSighting then
            begin
            lx:= hwRound(Gear^.X);
            ly:= hwRound(Gear^.Y);
            lx:= lx + dx * 16;
            ly:= ly + dy * 16;

            ax:= dx * 4;
            ay:= dy * 4;

            tx:= round(lx);
            ty:= round(ly);
            hx:= tx;
            hy:= ty;
            while ((ty and LAND_HEIGHT_MASK) = 0) and
                ((tx and LAND_WIDTH_MASK) = 0) and
                (Land[ty, tx] = 0) do
                begin
                lx:= lx + ax;
                ly:= ly + ay;
                tx:= round(lx);
                ty:= round(ly)
                end;
            // reached edge of land. assume infinite beam. Extend it way out past camera
            if ((ty and LAND_HEIGHT_MASK) <> 0) or ((tx and LAND_WIDTH_MASK) <> 0) then
                begin
                tx:= round(lx + ax * (LAND_WIDTH div 4));
                ty:= round(ly + ay * (LAND_WIDTH div 4));
                end;

            //if (abs(lx-tx)>8) or (abs(ly-ty)>8) then
                begin
                glDisable(GL_TEXTURE_2D);
                glEnable(GL_LINE_SMOOTH);

                glLineWidth(1.0);

                Tint($FF, $00, $00, $C0);
                VertexBuffer[0].X:= hx + WorldDx;
                VertexBuffer[0].Y:= hy + WorldDy;
                VertexBuffer[1].X:= tx + WorldDx;
                VertexBuffer[1].Y:= ty + WorldDy;

                glEnableClientState(GL_VERTEX_ARRAY);
                glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);
                glDrawArrays(GL_LINES, 0, Length(VertexBuffer));
                Tint($FF, $FF, $FF, $FF);
                glEnable(GL_TEXTURE_2D);
                glDisable(GL_LINE_SMOOTH);
                end;
            end;
        // draw crosshair
        cx:= Round(hwRound(Gear^.X) + dx * 80);
        cy:= Round(hwRound(Gear^.Y) + dy * 80);
        DrawRotatedTex(HH^.Team^.CrosshairTex,
                12, 12, cx + WorldDx, cy + WorldDy, 0,
                hwSign(Gear^.dX) * (Gear^.Angle * 180.0) / cMaxAngle);
        end;
    hx:= hwRound(Gear^.X) + 1 + 8 * hwSign(Gear^.dX) + WorldDx;
    hy:= hwRound(Gear^.Y) - 2 + WorldDy;
    aangle:= Gear^.Angle * 180 / cMaxAngle - 90;

    if CurAmmoGear <> nil then
    begin
        case CurAmmoGear^.Kind of
            gtShotgunShot: begin
                    if (CurAmmoGear^.State and gstAnimation <> 0) then
                        DrawRotated(sprShotgun, hx, hy, hwSign(Gear^.dX), aangle)
                    else
                        DrawRotated(sprHandShotgun, hx, hy, hwSign(Gear^.dX), aangle);
                end;
            gtDEagleShot: DrawRotated(sprDEagle, hx, hy, hwSign(Gear^.dX), aangle);
            gtSniperRifleShot: begin
                    if (CurAmmoGear^.State and gstAnimation <> 0) then
                        DrawRotatedF(sprSniperRifle, hx, hy, 1, hwSign(Gear^.dX), aangle)
                    else
                        DrawRotatedF(sprSniperRifle, hx, hy, 0, hwSign(Gear^.dX), aangle)
                end;
            gtBallgun: DrawRotated(sprHandBallgun, hx, hy, hwSign(Gear^.dX), aangle);
            gtRCPlane: begin
                DrawRotated(sprHandPlane, hx, hy, hwSign(Gear^.dX), 0);
                defaultPos:= false
                end;
            gtRope: begin
                if Gear^.X < CurAmmoGear^.X then
                    begin
                    dAngle:= 0;
                    hAngle:= 180;
                    i:= 1
                    end else
                    begin
                    dAngle:= 180;
                    hAngle:= 0;
                    i:= -1
                    end;
                sx:= hwRound(Gear^.X) + WorldDx;
                sy:= hwRound(Gear^.Y) + WorldDy;
               if ((Gear^.State and gstWinner) = 0) then
                   begin
                   DrawHedgehog(sx, sy,
                           i,
                           1,
                           0,
                           DxDy2Angle(CurAmmoGear^.dY, CurAmmoGear^.dX) + dAngle);
                   with HH^ do
                       if (HatTex <> nil) then
                           begin
                           DrawRotatedTextureF(HatTex, 1.0, -1.0, -6.0, sx, sy, 0, i, 32, 32,
                               i*DxDy2Angle(CurAmmoGear^.dY, CurAmmoGear^.dX) + hAngle);
                           if HatTex^.w > 32 then
                               begin
                               Tint(HH^.Team^.Clan^.Color);
                               DrawRotatedTextureF(HatTex, 1.0, -1.0, -6.0, sx, sy, 32, i, 32, 32,
                                   i*DxDy2Angle(CurAmmoGear^.dY, CurAmmoGear^.dX) + hAngle);
                               Tint($FF, $FF, $FF, $FF)
                               end
                           end
                   end;
                DrawAltWeapon(Gear, sx, sy);
                defaultPos:= false
                end;
            gtBlowTorch: begin
                DrawRotated(sprBlowTorch, hx, hy, hwSign(Gear^.dX), aangle);
                DrawHedgehog(sx, sy,
                        hwSign(Gear^.dX),
                        3,
                        HH^.visStepPos div 2,
                        0);
                with HH^ do
                    if (HatTex <> nil) then
                        begin
                        DrawTextureF(HatTex,
                            1,
                            sx,
                            hwRound(Gear^.Y) - 8 + WorldDy,
                            0,
                            hwSign(Gear^.dX),
                            32,
                            32);
                        if HatTex^.w > 32 then
                            begin
                            Tint(HH^.Team^.Clan^.Color);
                            DrawTextureF(HatTex,
                                1,
                                sx,
                                hwRound(Gear^.Y) - 8 + WorldDy,
                                32,
                                hwSign(Gear^.dX),
                                32,
                                32);
                            Tint($FF, $FF, $FF, $FF)
                            end
                        end;
                defaultPos:= false
                end;
            gtShover: DrawRotated(sprHandBaseball, hx, hy, hwSign(Gear^.dX), aangle + 180);
            gtFirePunch: begin
                DrawHedgehog(sx, sy,
                        hwSign(Gear^.dX),
                        1,
                        4,
                        0);
                defaultPos:= false
                end;
            gtPickHammer: begin
                defaultPos:= false;
                dec(sy,20);
                end;
            gtTeleport: defaultPos:= false;
            gtWhip: begin
                DrawRotatedF(sprWhip,
                        sx,
                        sy,
                        1,
                        hwSign(Gear^.dX),
                        0);
                defaultPos:= false
                end;
            gtKamikaze: begin
                if CurAmmoGear^.Pos = 0 then
                    DrawHedgehog(sx, sy,
                            hwSign(Gear^.dX),
                            1,
                            6,
                            0)
                else
                    DrawRotatedF(sprKamikaze,
                            hwRound(Gear^.X) + WorldDx,
                            hwRound(Gear^.Y) + WorldDy,
                            CurAmmoGear^.Pos - 1,
                            hwSign(Gear^.dX),
                            aangle);
                defaultPos:= false
                end;
            gtSeduction: begin
                if CurAmmoGear^.Pos >= 6 then
                    DrawHedgehog(sx, sy,
                            hwSign(Gear^.dX),
                            2,
                            2,
                            0)
                else
                    begin
                    DrawRotatedF(sprDress,
                            hwRound(Gear^.X) + WorldDx,
                            hwRound(Gear^.Y) + WorldDy,
                            CurAmmoGear^.Pos,
                            hwSign(Gear^.dX),
                            0);
                    DrawSprite(sprCensored, hwRound(Gear^.X) - 32 + WorldDx, hwRound(Gear^.Y) - 20 + WorldDy, 0)
                    end;
                defaultPos:= false
                end;
            gtFlamethrower: DrawRotatedF(sprHandFlamethrower, hx, hy, (RealTicks div 125) mod 4, hwSign(Gear^.dX), aangle);
        end;

        case CurAmmoGear^.Kind of
            gtShotgunShot,
            gtDEagleShot,
            gtSniperRifleShot,
            gtShover: begin
                DrawHedgehog(sx, sy,
                        hwSign(Gear^.dX),
                        0,
                        4,
                        0);
                defaultPos:= false;
                HatVisible:= true
            end
        end
    end else

    if ((Gear^.State and gstHHJumping) <> 0) then
    begin
    DrawHedgehog(sx, sy,
        hwSign(Gear^.dX)*m,
        1,
        1,
        0);
    HatVisible:= true;
    defaultPos:= false
    end else

    if (Gear^.Message and (gm_Left or gm_Right) <> 0) and (not isCursorVisible) then
        begin
        DrawHedgehog(sx, sy,
            hwSign(Gear^.dX),
            0,
            HH^.visStepPos div 2,
            0);
        defaultPos:= false;
        HatVisible:= true
        end
    else

    if ((Gear^.State and gstAnimation) <> 0) then
        begin
        if (TWave(Gear^.Tag) < Low(TWave)) or (TWave(Gear^.Tag) > High(TWave)) then
            begin
            Gear^.State:= Gear^.State and not gstAnimation;
            end
        else
            begin
            DrawRotatedF(Wavez[TWave(Gear^.Tag)].Sprite,
                    sx,
                    sy,
                    Gear^.Pos,
                    hwSign(Gear^.dX),
                    0.0);
            defaultPos:= false
            end
        end
    else
    if ((Gear^.State and gstAttacked) = 0) then
        begin
        if HH^.Timer > 0 then
            begin
            // There must be a tidier way to do this. Anyone?
            if aangle <= 90 then aangle:= aangle+360;
            if Gear^.dX > _0 then aangle:= aangle-((aangle-240)*HH^.Timer/10)
            else aangle:= aangle+((240-aangle)*HH^.Timer/10);
            dec(HH^.Timer)
            end;
        amt:= CurrentHedgehog^.Ammo^[CurrentHedgehog^.CurSlot, CurrentHedgehog^.CurAmmo].AmmoType;
        case amt of
            amBazooka: DrawRotated(sprHandBazooka, hx, hy, hwSign(Gear^.dX), aangle);
            amMortar: DrawRotated(sprHandMortar, hx, hy, hwSign(Gear^.dX), aangle);
            amMolotov: DrawRotated(sprHandMolotov, hx, hy, hwSign(Gear^.dX), aangle);
            amBallgun: DrawRotated(sprHandBallgun, hx, hy, hwSign(Gear^.dX), aangle);
            amDrill: DrawRotated(sprHandDrill, hx, hy, hwSign(Gear^.dX), aangle);
            amRope: DrawRotated(sprHandRope, hx, hy, hwSign(Gear^.dX), aangle);
            amShotgun: DrawRotated(sprHandShotgun, hx, hy, hwSign(Gear^.dX), aangle);
            amDEagle: DrawRotated(sprHandDEagle, hx, hy, hwSign(Gear^.dX), aangle);
            amSineGun: DrawRotated(sprHandShotgun, hx, hy, hwSign(Gear^.dX), aangle);
            amPortalGun: if (HH^.Ammo^[HH^.CurSlot, HH^.CurAmmo].Timer and 2) <> 0 then // Add a new Hedgehog value instead of abusing timer?
                            DrawRotatedF(sprPortalGun, hx, hy, 0, hwSign(Gear^.dX), aangle)
                      else
                            DrawRotatedF(sprPortalGun, hx, hy, 1+(HH^.Ammo^[HH^.CurSlot, HH^.CurAmmo].Timer and 1), hwSign(Gear^.dX), aangle);
            amSniperRifle: DrawRotatedF(sprSniperRifle, hx, hy, 0, hwSign(Gear^.dX), aangle);
            amBlowTorch: DrawRotated(sprHandBlowTorch, hx, hy, hwSign(Gear^.dX), aangle);
            amCake: DrawRotated(sprHandCake, hx, hy, hwSign(Gear^.dX), aangle);
            amGrenade: DrawRotated(sprHandGrenade, hx, hy, hwSign(Gear^.dX), aangle);
            amWatermelon: DrawRotated(sprHandMelon, hx, hy, hwSign(Gear^.dX), aangle);
            amSkip: DrawRotated(sprHandSkip, hx, hy, hwSign(Gear^.dX), aangle);
            amClusterBomb: DrawRotated(sprHandCluster, hx, hy, hwSign(Gear^.dX), aangle);
            amDynamite: DrawRotated(sprHandDynamite, hx, hy, hwSign(Gear^.dX), aangle);
            amHellishBomb: DrawRotated(sprHandHellish, hx, hy, hwSign(Gear^.dX), aangle);
            amGasBomb: DrawRotated(sprHandCheese, hx, hy, hwSign(Gear^.dX), aangle);
            amMine: DrawRotated(sprHandMine, hx, hy, hwSign(Gear^.dX), aangle);
            amSeduction: DrawRotated(sprHandSeduction, hx, hy, hwSign(Gear^.dX), aangle);
            amVampiric: DrawRotatedF(sprHandVamp, hx, hy, (RealTicks div 125) mod 4, hwSign(Gear^.dX), aangle);
            amRCPlane: begin
                DrawRotated(sprHandPlane, hx, hy, hwSign(Gear^.dX), 0);
                defaultPos:= false
                end;
            amGirder: begin
                DrawRotated(sprHandConstruction, hx, hy, hwSign(Gear^.dX), aangle);
                DrawSpriteClipped(sprGirder,
                                  sx-256,
                                  sy-256,
                                  LongInt(topY)+WorldDy,
                                  LongInt(rightX)+WorldDx,
                                  cWaterLine+WorldDy,
                                  LongInt(leftX)+WorldDx)
                end;
            amBee: DrawRotatedF(sprHandBee, hx, hy, (RealTicks div 125) mod 4, hwSign(Gear^.dX), aangle);
            amFlamethrower: DrawRotatedF(sprHandFlamethrower, hx, hy, (RealTicks div 125) mod 4, hwSign(Gear^.dX), aangle);
        end;

        case amt of
            amAirAttack,
            amMineStrike: DrawRotated(sprHandAirAttack, sx, hwRound(Gear^.Y) + WorldDy, hwSign(Gear^.dX), 0);
            amPickHammer: DrawHedgehog(sx, sy,
                        hwSign(Gear^.dX),
                        1,
                        2,
                        0);
            amTeleport: DrawRotatedF(sprTeleport, sx, sy, 0, hwSign(Gear^.dX), 0);
            amKamikaze: DrawHedgehog(sx, sy,
                        hwSign(Gear^.dX),
                        1,
                        5,
                        0);
            amWhip: DrawRotatedF(sprWhip,
                        sx,
                        sy,
                        0,
                        hwSign(Gear^.dX),
                        0);
        else
            DrawHedgehog(sx, sy,
                hwSign(Gear^.dX),
                0,
                4,
                0);

            HatVisible:= true;
            (* with HH^ do
                if (HatTex <> nil)
                and (HatVisibility > 0) then
                    DrawTextureF(HatTex,
                        HatVisibility,
                        sx,
                        hwRound(Gear^.Y) - 8 + WorldDy,
                        0,
                        hwSign(Gear^.dX),
                        32,
                        32); *)
        end;

        case amt of
            amBaseballBat: DrawRotated(sprHandBaseball,
                    hwRound(Gear^.X) + 1 - 4 * hwSign(Gear^.dX) + WorldDx,
                    hwRound(Gear^.Y) + 6 + WorldDy, hwSign(Gear^.dX), aangle);
        end;

        defaultPos:= false
    end;

end else // not gstHHDriven
    begin
    if (Gear^.Damage > 0)
    and (hwSqr(Gear^.dX) + hwSqr(Gear^.dY) > _0_003) then
        begin
        DrawHedgehog(sx, sy,
            hwSign(Gear^.dX),
            2,
            1,
            Gear^.DirAngle);
        defaultPos:= false
        end else

    if ((Gear^.State and gstHHJumping) <> 0) then
        begin
        DrawHedgehog(sx, sy,
            hwSign(Gear^.dX)*m,
            1,
            1,
            0);
        defaultPos:= false
        end;
    end;

with HH^ do
    begin
    if defaultPos then
        begin
        DrawRotatedF(sprHHIdle,
            sx,
            sy,
            (RealTicks div 128 + Gear^.Pos) mod 19,
            hwSign(Gear^.dX),
            0);
        HatVisible:= true;
        end;

    if HatVisible then
        if HatVisibility < 1.0 then
            HatVisibility:= HatVisibility + 0.2
        else
    else
        if HatVisibility > 0.0 then
            HatVisibility:= HatVisibility - 0.2;

    if (HatTex <> nil)
    and (HatVisibility > 0) then
        if DefaultPos then
            begin
            DrawTextureF(HatTex,
                HatVisibility,
                sx,
                hwRound(Gear^.Y) - 8 + WorldDy,
                (RealTicks div 128 + Gear^.Pos) mod 19,
                hwSign(Gear^.dX),
                32,
                32);
            if HatTex^.w > 32 then
                begin
                Tint(HH^.Team^.Clan^.Color);
                DrawTextureF(HatTex,
                    HatVisibility,
                    sx,
                    hwRound(Gear^.Y) - 8 + WorldDy,
                    (RealTicks div 128 + Gear^.Pos) mod 19 + 32,
                    hwSign(Gear^.dX),
                    32,
                    32);
                Tint($FF, $FF, $FF, $FF)
                end
            end
        else
            begin
            DrawTextureF(HatTex,
                HatVisibility,
                sx,
                hwRound(Gear^.Y) - 8 + WorldDy,
                0,
                hwSign(Gear^.dX)*m,
                32,
                32);
            if HatTex^.w > 32 then
                begin
                Tint(HH^.Team^.Clan^.Color);
                DrawTextureF(HatTex,
                    HatVisibility,
                    sx,
                    hwRound(Gear^.Y) - 8 + WorldDy,
                    32,
                    hwSign(Gear^.dX)*m,
                    32,
                    32);
                Tint($FF, $FF, $FF, $FF)
                end
            end
    end;
if (Gear^.State and gstHHDriven) <> 0 then
    begin
(*    if (CurAmmoGear = nil) then
        begin
        amt:= CurrentHedgehog^.Ammo^[CurrentHedgehog^.CurSlot, CurrentHedgehog^.CurAmmo].AmmoType;
        case amt of
            amJetpack: DrawSprite(sprJetpack, sx-32, sy-32, 0);
            end
        end; *)
    if CurAmmoGear <> nil then
        begin
        case CurAmmoGear^.Kind of
            gtJetpack: begin
                       DrawSprite(sprJetpack, sx-32, sy-32, 0);
                       if (CurAmmoGear^.MsgParam and gm_Up) <> 0 then DrawSprite(sprJetpack, sx-32, sy-32, 1);
                       if (CurAmmoGear^.MsgParam and gm_Left) <> 0 then DrawSprite(sprJetpack, sx-32, sy-32, 2);
                       if (CurAmmoGear^.MsgParam and gm_Right) <> 0 then DrawSprite(sprJetpack, sx-32, sy-32, 3);
                       if CurAmmoGear^.Tex <> nil then DrawCentered(sx, sy - 40, CurAmmoGear^.Tex);
                       DrawAltWeapon(Gear, sx, sy)
                       end;
            end;
        end
    end;

with HH^ do
    begin
    if ((Gear^.State and not gstWinner) = 0)
        or (bShowFinger and ((Gear^.State and gstHHDriven) <> 0)) then
        begin
        t:= hwRound(Gear^.Y) - cHHRadius - 12 + WorldDy;
        if (cTagsMask and htTransparent) <> 0 then
            Tint($FF, $FF, $FF, $80);
        if ((cTagsMask and htHealth) <> 0) then
            begin
            dec(t, HealthTagTex^.h + 2);
            DrawCentered(hwRound(Gear^.X) + WorldDx, t, HealthTagTex)
            end;
        if (cTagsMask and htName) <> 0 then
            begin
            dec(t, NameTagTex^.h + 2);
            DrawCentered(hwRound(Gear^.X) + WorldDx, t, NameTagTex)
            end;
        if (cTagsMask and htTeamName) <> 0 then
            begin
            dec(t, Team^.NameTagTex^.h + 2);
            DrawCentered(hwRound(Gear^.X) + WorldDx, t, Team^.NameTagTex)
            end;
        if (cTagsMask and htTransparent) <> 0 then
            Tint($FF, $FF, $FF, $FF)
        end;
    if (Gear^.State and gstHHDriven) <> 0 then // Current hedgehog
        begin
        if bShowFinger and ((Gear^.State and gstHHDriven) <> 0) then
            DrawSprite(sprFinger, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 64 + WorldDy,
                        GameTicks div 32 mod 16);

        if (Gear^.State and gstDrowning) = 0 then
            if (Gear^.State and gstHHThinking) <> 0 then
                DrawSprite(sprQuestion, hwRound(Gear^.X) - 10 + WorldDx, hwRound(Gear^.Y) - cHHRadius - 34 + WorldDy, (RealTicks shr 9) mod 8)
        end
    end;

if HH^.Effects[hePoisoned] then
    begin
    Tint($00, $FF, $40, $80);
    DrawRotatedTextureF(SpritesData[sprSmokeWhite].texture, 1.5, 0, 0, sx, sy, 0, 1, 22, 22, 360 - (RealTicks shr 37) mod 360);
    end;

if Gear^.Invulnerable then
    begin
    Tint($FF, $FF, $FF, max($40, floor($FF * abs(1 - ((RealTicks div 2 + Gear^.uid * 491) mod 1500) / 750))));
    DrawSprite(sprInvulnerable, sx - 24, sy - 24, 0);
    end;
if cVampiric and
   (CurrentHedgehog^.Gear <> nil) and
   (CurrentHedgehog^.Gear = Gear) then
    begin
    Tint($FF, $FF, $FF, max($40, floor($FF * abs(1 - (RealTicks mod 1500) / 750))));
    DrawSprite(sprVampiric, sx - 24, sy - 24, 0);
    end;
    Tint($FF, $FF, $FF, $FF)
end;

procedure DrawGears;
var Gear, HHGear: PGear;
    i: Longword;
    startX, endX, startY, endY: LongInt;
begin
Gear:= GearsList;
while Gear<>nil do
    begin
    case Gear^.Kind of
       gtAmmo_Bomb: DrawRotated(sprBomb, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, Gear^.DirAngle);
       gtGasBomb: DrawRotated(sprCheese, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, Gear^.DirAngle);
       gtMolotov: DrawRotated(sprMolotov, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, Gear^.DirAngle);

       gtRCPlane: begin
                  if (Gear^.Tag = -1) then
                     DrawRotated(sprPlane, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, -1,  DxDy2Angle(Gear^.dX, Gear^.dY) + 90)
                  else
                     DrawRotated(sprPlane, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy,0,DxDy2Angle(Gear^.dY, Gear^.dX));
                  if ((TrainingFlags and tfRCPlane) <> 0) and (TrainingTargetGear <> nil) and ((Gear^.State and gstDrowning) = 0) then
                     DrawRotatedf(sprFinger, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, GameTicks div 32 mod 16, 0, DxDy2Angle(Gear^.X - TrainingTargetGear^.X, TrainingTargetGear^.Y - Gear^.Y));
                  end;
       gtBall: DrawRotatedf(sprBalls, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.Tag,0, Gear^.DirAngle);

       gtPortal: if ((Gear^.Tag and 1) = 0) // still moving?
                 or (Gear^.IntersectGear = nil) or (Gear^.IntersectGear^.IntersectGear <> Gear) // not linked&backlinked?
                 or ((Gear^.IntersectGear^.Tag and 1) = 0) then // linked portal still moving?
                      DrawRotatedf(sprPortal, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.Tag, hwSign(Gear^.dX), Gear^.DirAngle)
                 else DrawRotatedf(sprPortal, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 4 + Gear^.Tag div 2, hwSign(Gear^.dX), Gear^.DirAngle);

       gtDrill: DrawRotated(sprDrill, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, DxDy2Angle(Gear^.dY, Gear^.dX));

        gtHedgehog: DrawHH(Gear);

    gtAmmo_Grenade: DrawRotated(sprGrenade, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, DxDy2Angle(Gear^.dY, Gear^.dX));

           gtGrave: DrawTextureF(PHedgehog(Gear^.Hedgehog)^.Team^.GraveTex, 1, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, (GameTicks shr 7+Gear^.uid) and 7, 1, 32, 32);

             gtBee: DrawRotatedF(sprBee, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, (GameTicks shr 5) mod 2, 0, DxDy2Angle(Gear^.dY, Gear^.dX));

      gtPickHammer: DrawSprite(sprPHammer, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 50 + LongInt(((GameTicks shr 5) and 1) * 2) + WorldDy, 0);
            gtRope: DrawRope(Gear);
            gtMine: if (((Gear^.State and gstAttacking) = 0)or((Gear^.Timer and $3FF) < 420)) and (Gear^.Health <> 0) then
                           DrawRotated(sprMineOff, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, Gear^.DirAngle)
                       else if Gear^.Health <> 0 then DrawRotated(sprMineOn, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, Gear^.DirAngle)
                       else DrawRotated(sprMineDead, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, Gear^.DirAngle);
            gtCase: case Gear^.Pos of
                         posCaseAmmo  : begin
                                        i:= (GameTicks shr 6) mod 64;
                                        if i > 18 then i:= 0;
                                        DrawSprite(sprCase, hwRound(Gear^.X) - 24 + WorldDx, hwRound(Gear^.Y) - 24 + WorldDy, i);
                                        end;
                         posCaseHealth: begin
                                        i:= ((GameTicks shr 6) + 38) mod 64;
                                        if i > 13 then i:= 0;
                                        DrawSprite(sprFAid, hwRound(Gear^.X) - 24 + WorldDx, hwRound(Gear^.Y) - 24 + WorldDy, i);
                                        end;
                         posCaseUtility: begin
                                        i:= (GameTicks shr 6) mod 70;
                                        if i > 23 then i:= 0;
                                        i:= i mod 12;
                                        DrawSprite(sprUtility, hwRound(Gear^.X) - 24 + WorldDx, hwRound(Gear^.Y) - 24 + WorldDy, i);
                                        end;
                         end;
      gtExplosives: begin
                    if ((Gear^.State and gstDrowning) <> 0) then
                        DrawSprite(sprExplosivesRoll, hwRound(Gear^.X) - 24 + WorldDx, hwRound(Gear^.Y) - 24 + WorldDy, 0)
                    else if Gear^.State and gstAnimation = 0 then
                        begin
                        i:= (GameTicks shr 6 + Gear^.uid*3) mod 64;
                        if i > 18 then i:= 0;
                        DrawSprite(sprExplosives, hwRound(Gear^.X) - 24 + WorldDx, hwRound(Gear^.Y) - 24 + WorldDy, i)
                        end
                    else if Gear^.State and gsttmpFlag = 0 then
                        DrawRotatedF(sprExplosivesRoll, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) +4 + WorldDy, 0, 0, Gear^.DirAngle)
                    else
                        DrawRotatedF(sprExplosivesRoll, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) +4 + WorldDy, 1, 0, Gear^.DirAngle);
                    end;
        gtDynamite: DrawSprite2(sprDynamite, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 25 + WorldDy, Gear^.Tag and 1, Gear^.Tag shr 1);
     gtClusterBomb: DrawRotated(sprClusterBomb, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, Gear^.DirAngle);
         gtCluster: DrawSprite(sprClusterParticle, hwRound(Gear^.X) - 8 + WorldDx, hwRound(Gear^.Y) - 8 + WorldDy, 0);
           gtFlame: DrawTextureF(SpritesData[sprFlame].Texture, 2 / (Gear^.Tag mod 3 + 2), hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, (GameTicks div 128 + LongWord(Gear^.Tag)) mod 8, 1, 16, 16);
       gtParachute: begin
                    DrawSprite(sprParachute, hwRound(Gear^.X) - 24 + WorldDx, hwRound(Gear^.Y) - 48 + WorldDy, 0);
                    DrawAltWeapon(Gear, hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy)
                    end;
       gtAirAttack: if Gear^.Tag > 0 then DrawSprite(sprAirplane, hwRound(Gear^.X) - SpritesData[sprAirplane].Width div 2 + WorldDx, hwRound(Gear^.Y) - SpritesData[sprAirplane].Height div 2 + WorldDy, 0)
                                     else DrawSprite(sprAirplane, hwRound(Gear^.X) - SpritesData[sprAirplane].Width div 2 + WorldDx, hwRound(Gear^.Y) - SpritesData[sprAirplane].Height div 2 + WorldDy, 1);
         gtAirBomb: DrawRotated(sprAirBomb, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, DxDy2Angle(Gear^.dY, Gear^.dX));
        gtTeleport: begin
                    HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
                    if not PHedgehog(Gear^.Hedgehog)^.Unplaced then DrawRotatedF(sprTeleport, hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy, Gear^.Pos, hwSign(Gear^.dX), 0);
                    DrawRotatedF(sprTeleport, hwRound(HHGear^.X) + 1 + WorldDx, hwRound(HHGear^.Y) - 3 + WorldDy, 11 - Gear^.Pos, hwSign(HHGear^.dX), 0);
                    end;
        gtSwitcher: DrawSprite(sprSwitch, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 56 + WorldDy, (GameTicks shr 6) mod 12);
          gtTarget: begin
                    Tint($FF, $FF, $FF, floor($FF * Gear^.Timer / 1000));
                    DrawSprite(sprTarget, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 16 + WorldDy, 0);
                    Tint($FF, $FF, $FF, $FF);
                    end;
          gtMortar: DrawRotated(sprMortar, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, DxDy2Angle(Gear^.dY, Gear^.dX));
          gtCake: if Gear^.Pos = 6 then
                     DrawRotatedf(sprCakeWalk, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, (GameTicks div 40) mod 6, hwSign(Gear^.dX), Gear^.DirAngle * hwSign(Gear^.dX) + 90)
                  else
                     DrawRotatedf(sprCakeDown, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 5 - Gear^.Pos, hwSign(Gear^.dX), 0);
       gtSeduction: if Gear^.Pos >= 14 then DrawSprite(sprSeduction, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 16 + WorldDy, 0);
      gtWatermelon: DrawRotatedf(sprWatermelon, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, 0, Gear^.DirAngle);
      gtMelonPiece: DrawRotatedf(sprWatermelon, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 1, 0, Gear^.DirAngle);
     gtHellishBomb: DrawRotated(sprHellishBomb, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, Gear^.DirAngle);
           gtBirdy: begin
                    if Gear^.State and gstAnimation = gstAnimation then
                        begin
                        if Gear^.State and gstTmpFlag = 0 then // Appearing
                            begin
                            endX:= hwRound(Gear^.X);
                            endY:= hwRound(Gear^.Y);
                            if Gear^.Tag < 0 then
                                startX:= max(LAND_WIDTH + 1024, endX + 2048)
                            else
                                startX:= max(-LAND_WIDTH - 1024, endX - 2048);
                            startY:= endY - 256;
                            DrawTextureF(SpritesData[sprBirdy].Texture, 1, startX + WorldDx + floor((endX - startX) * (-power(2, -10 * LongInt(Gear^.Timer)/2000) + 1)), startY + WorldDy + floor((endY - startY) * sqrt(1 - power((LongInt(Gear^.Timer)/2000)-1, 2))), ((Gear^.Pos shr 6) or (RealTicks shr 8)) mod 2, Gear^.Tag, 75, 75);
                            end
                        else // Disappearing
                            begin
                            startX:= hwRound(Gear^.X);
                            startY:= hwRound(Gear^.Y);
                            if Gear^.Tag > 0 then
                                endX:= max(LAND_WIDTH + 1024, startX + 2048)
                            else
                                endX:= max(-LAND_WIDTH - 1024, startX - 2048);
                            endY:= startY + 256;
                            DrawTextureF(SpritesData[sprBirdy].Texture, 1, startX + WorldDx + floor((endX - startX) * power(2, 10 * (LongInt(Gear^.Timer)/2000 - 1))) + hwRound(Gear^.dX * Gear^.Timer), startY + WorldDy + floor((endY - startY) * cos(LongInt(Gear^.Timer)/2000 * (Pi/2)) - (endY - startY)) + hwRound(Gear^.dY * Gear^.Timer), ((Gear^.Pos shr 6) or (RealTicks shr 8)) mod 2, Gear^.Tag, 75, 75);
                            end;
                        end
                    else
                        DrawTextureF(SpritesData[sprBirdy].Texture, 1, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, ((Gear^.Pos shr 6) or (RealTicks shr 8)) mod 2, Gear^.Tag, 75, 75);
                    end;
             gtEgg: DrawRotatedTextureF(SpritesData[sprEgg].Texture, 1, 0, 0, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, 1, 16, 16, Gear^.DirAngle);
           gtPiano: begin
                    if (Gear^.State and gstDrowning) = 0 then
                        begin
                        Tint($FF, $FF, $FF, $10);
                        for i:= 8 downto 1 do
                            DrawRotatedTextureF(SpritesData[sprPiano].Texture, 1, 0, 0, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy - hwRound(Gear^.dY * 4 * i), 0, 1, 128, 128, 0);
                        Tint($FF, $FF, $FF, $FF)
                        end;
                    DrawRotatedTextureF(SpritesData[sprPiano].Texture, 1, 0, 0, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, 1, 128, 128, 0);
                    end;
         end;
      if Gear^.RenderTimer and (Gear^.Tex <> nil) then DrawCentered(hwRound(Gear^.X) + 8 + WorldDx, hwRound(Gear^.Y) + 8 + WorldDy, Gear^.Tex);
      Gear:= Gear^.NextGear
      end;
end;
