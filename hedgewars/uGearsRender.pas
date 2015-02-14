(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2014 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uGearsRender;

interface
uses uTypes, uConsts, GLunit, uFloat, SDLh;

type
   Tar = record
            X, Y: hwFloat;
            dLen: hwFloat;
            b : boolean;
         end;
   TRopePoints = record
            Count     : Longword;
            HookAngle : GLfloat;
            ar        : array[0..MAXROPEPOINTS] of Tar;
            rounded   : array[0..MAXROPEPOINTS + 2] of TVertex2f;
         end;
procedure RenderGear(Gear: PGear; x, y: LongInt);

var RopePoints: record
                Count: Longword;
                HookAngle: GLfloat;
                ar: array[0..MAXROPEPOINTS] of record
                                X, Y: hwFloat;
                                dLen: hwFloat;
                                b: boolean;
                                sx, sy, sb: boolean;
                                end;
                rounded: array[0..MAXROPEPOINTS + 2] of TVertex2f;
                end;

implementation
uses uRender, uUtils, uVariables, uAmmos, Math, uVisualGearsList;

procedure DrawRopeLinesRQ(Gear: PGear);
var n: LongInt;
begin
with RopePoints do
    begin
    rounded[Count].X:= hwRound(Gear^.X);
    rounded[Count].Y:= hwRound(Gear^.Y);
    rounded[Count + 1].X:= hwRound(Gear^.Hedgehog^.Gear^.X);
    rounded[Count + 1].Y:= hwRound(Gear^.Hedgehog^.Gear^.Y);
    end;

if (RopePoints.Count > 0) or (Gear^.Elasticity.QWordValue > 0) then
    begin
    EnableTexture(false);
    //glEnable(GL_LINE_SMOOTH);

    Tint($70, $70, $70, $FF);

    n:= RopePoints.Count + 2;

    SetVertexPointer(@RopePoints.rounded[0], n);

    openglPushMatrix();
    openglTranslatef(WorldDx, WorldDy, 0);

    glLineWidth(3.0 * cScaleFactor);
    glDrawArrays(GL_LINE_STRIP, 0, n);
    Tint($D8, $D8, $D8, $FF);
    glLineWidth(2.0 * cScaleFactor);
    glDrawArrays(GL_LINE_STRIP, 0, n);

    untint;

    openglPopMatrix();

    EnableTexture(true);
    //glDisable(GL_LINE_SMOOTH)
    end
end;


function DrawRopeLine(X1, Y1, X2, Y2, roplen: LongInt): LongInt;
var  eX, eY, dX, dY: LongInt;
    i, sX, sY, x, y, d: LongInt;
    b: boolean;
begin
    if (X1 = X2) and (Y1 = Y2) then
        begin
        //OutError('WARNING: zero length rope line!', false);
        DrawRopeLine:= 0;
        exit
        end;
    eX:= 0;
    eY:= 0;
    dX:= X2 - X1;
    dY:= Y2 - Y1;

    if (dX > 0) then
        sX:= 1
    else
        if (dX < 0) then
            begin
            sX:= -1;
            dX:= -dX
            end
        else sX:= dX;

    if (dY > 0) then
        sY:= 1
    else
        if (dY < 0) then
            begin
            sY:= -1;
            dY:= -dY
            end
        else
            sY:= dY;

    if (dX > dY) then
        d:= dX
    else
        d:= dY;

    x:= X1;
    y:= Y1;

    for i:= 0 to d do
        begin
        inc(eX, dX);
        inc(eY, dY);
        b:= false;
        if (eX > d) then
            begin
            dec(eX, d);
            inc(x, sX);
            b:= true
            end;
        if (eY > d) then
            begin
            dec(eY, d);
            inc(y, sY);
            b:= true
            end;
        if b then
            begin
            inc(roplen);
            if (roplen mod 4) = 0 then
                DrawSprite(sprRopeNode, x - 2, y - 2, 0)
            end
    end;
    DrawRopeLine:= roplen;
end;

procedure DrawRope(Gear: PGear);
var roplen, i: LongInt;
begin
    if Gear^.Hedgehog^.Gear = nil then exit;
    if (cReducedQuality and rqSimpleRope) <> 0 then
        DrawRopeLinesRQ(Gear)
    else
        begin
        roplen:= 0;
        if RopePoints.Count > 0 then
            begin
            i:= 0;
            while i < Pred(RopePoints.Count) do
                    begin
                    roplen:= DrawRopeLine(hwRound(RopePoints.ar[i].X) + WorldDx, hwRound(RopePoints.ar[i].Y) + WorldDy,
                                hwRound(RopePoints.ar[Succ(i)].X) + WorldDx, hwRound(RopePoints.ar[Succ(i)].Y) + WorldDy, roplen);
                    inc(i)
                    end;
            roplen:= DrawRopeLine(hwRound(RopePoints.ar[i].X) + WorldDx, hwRound(RopePoints.ar[i].Y) + WorldDy,
                        hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, roplen);
            roplen:= DrawRopeLine(hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy,
                        hwRound(Gear^.Hedgehog^.Gear^.X) + WorldDx, hwRound(Gear^.Hedgehog^.Gear^.Y) + WorldDy, roplen);
            end
        else
            if Gear^.Elasticity.QWordValue > 0 then
            roplen:= DrawRopeLine(hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy,
                        hwRound(Gear^.Hedgehog^.Gear^.X) + WorldDx, hwRound(Gear^.Hedgehog^.Gear^.Y) + WorldDy, roplen);
        end;


if RopePoints.Count > 0 then
    DrawSpriteRotated(sprRopeHook, hwRound(RopePoints.ar[0].X) + WorldDx, hwRound(RopePoints.ar[0].Y) + WorldDy, 1, RopePoints.HookAngle)
else
    if Gear^.Elasticity.QWordValue > 0 then
        DrawSpriteRotated(sprRopeHook, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, DxDy2Angle(Gear^.dY, Gear^.dX));
end;


procedure DrawAltWeapon(Gear: PGear; sx, sy: LongInt);
begin
with Gear^.Hedgehog^ do
    begin
    if not (((Ammoz[CurAmmoType].Ammo.Propz and ammoprop_AltUse) <> 0) and ((Gear^.State and gstAttacked) = 0)) then
        exit;
    DrawTexture(sx + 16, sy + 16, ropeIconTex);
    DrawTextureF(SpritesData[sprAMAmmos].Texture, 0.75, sx + 30, sy + 30, ord(CurAmmoType) - 1, 1, 32, 32);
    end;
end;


procedure DrawHH(Gear: PGear; ox, oy: LongInt);
var i, t: LongInt;
    amt: TAmmoType;
    sign, hx, hy, tx, ty, sx, sy, m: LongInt;  // hedgehog, crosshair, temp, sprite, direction
    dx, dy, ax, ay, aAngle, dAngle, hAngle, lx, ly: real;  // laser, change
    defaultPos, HatVisible: boolean;
    HH: PHedgehog;
    CurWeapon: PAmmo;
    iceOffset:Longint;
    r:TSDL_Rect;
    curhat: PTexture;
begin
    HH:= Gear^.Hedgehog;
    if HH^.Unplaced then
        exit;
    if (HH^.CurAmmoType = amKnife) and (HH = CurrentHedgehog) then
         curhat:= ChefHatTexture
    else curhat:= HH^.HatTex;
    m:= 1;
    if ((Gear^.State and gstHHHJump) <> 0) and (not cArtillery) then
        m:= -1;
    sx:= ox + 1; // this offset is very common
    sy:= oy - 3;
    sign:= hwSign(Gear^.dX);

    if (Gear^.State and gstHHDeath) <> 0 then
        begin
        DrawSprite(sprHHDeath, ox - 16, oy - 26, Gear^.Pos);
        Tint(HH^.Team^.Clan^.Color shl 8 or $FF);
        DrawSprite(sprHHDeath, ox - 16, oy - 26, Gear^.Pos + 8);
        untint;
        exit
        end
    else if (Gear^.State and gstHHGone) <> 0 then
        begin
        DrawSpriteRotatedF(sprTeleport, sx, sy, Gear^.Pos, sign, 0);
        exit
        end;

    defaultPos:= true;
    HatVisible:= false;

    if HH^.Effects[heFrozen] > 0 then
        if HH^.Effects[heFrozen] < 150000 then
            begin
            DrawHedgehog(sx, sy,
                    sign,
                    0,
                    0,
                    0);
            defaultPos:= false;
            if HH^.Effects[heFrozen] < 256 then
                 HatVisible:= true
            else HatVisible:= false
            end
        else
            begin
            DrawHedgehog(sx, sy,
                    sign,
                    2,
                    4,
                    0);
            defaultPos:= false;
            HatVisible:= false
            end;


    if HH^.Effects[hePoisoned] <> 0 then
        begin
        Tint($00, $FF, $40, $40);
        DrawTextureRotatedF(SpritesData[sprSmokeWhite].texture, 2, 0, 0, sx, sy, 0, 1, 22, 22, (RealTicks shr 4) mod 360);
        untint
        end;


    if ((Gear^.State and gstWinner) <> 0) and
    ((CurAmmoGear = nil) or (CurAmmoGear^.Kind <> gtPickHammer)) then
        begin
        DrawHedgehog(sx, sy,
                sign,
                2,
                0,
                0);
        defaultPos:= false
        end;
    if (Gear^.State and gstDrowning) <> 0 then
        begin
        DrawHedgehog(sx, sy,
                sign,
                1,
                7,
                0);
        defaultPos:= false
        end else
    if (Gear^.State and gstLoser) <> 0 then
        begin
        DrawHedgehog(sx, sy,
                sign,
                2,
                3,
                0);
        defaultPos:= false
        end else

    if (Gear^.State and gstHHDriven) <> 0 then
        begin
        if ((Gear^.State and (gstHHThinking or gstAnimation)) = 0) and
/// If current ammo is active, and current ammo has alt attack and uses a crosshair  (rope, basically, right now, with no crosshair for parachute/saucer
            (((CurAmmoGear <> nil) and //((Ammoz[CurAmmoGear^.AmmoType].Ammo.Propz and ammoprop_AltAttack) <> 0) and
            // don't render crosshair/laser during kamikaze
            ((CurAmmoGear^.AmmoType <> amKamikaze) or ((Gear^.State and gstAttacking) = 0)) and
             ((Ammoz[CurAmmoGear^.AmmoType].Ammo.Propz and ammoprop_NoCrossHair) = 0)) or
/// If no current ammo is active, and the selected ammo uses a crosshair
            ((CurAmmoGear = nil) and ((Ammoz[HH^.CurAmmoType].Ammo.Propz and ammoprop_NoCrosshair) = 0) and ((Gear^.State and gstAttacked) = 0))) then
            begin
    (* These calculations are a little complex for a few reasons:
    1: I need to draw the laser from weapon origin to nearest land
    2: I need to start the beam outside the hedgie for attractiveness.
    3: I need to extend the beam beyond land.
    This routine perhaps should be pushed into uStore or somesuch instead of continuuing the increase in size of this function.
    *)
            dx:= sign * m * Sin(Gear^.Angle * pi / cMaxAngle);
            dy:= -Cos(Gear^.Angle * pi / cMaxAngle);
            if cLaserSighting then
                begin
                lx:= GetLaunchX(HH^.CurAmmoType, sign * m, Gear^.Angle);
                ly:= GetLaunchY(HH^.CurAmmoType, Gear^.Angle);

                // ensure we start outside the hedgehog (he's solid after all)
                while abs(lx * lx + ly * ly) < (Gear^.radius * Gear^.radius) do
                    begin
                    lx:= lx + dx;
                    ly:= ly + dy
                    end;

                // add hog's position
                lx:= lx + ox - WorldDx;
                ly:= ly + oy - WorldDy;

                // decrease number of iterations required
                ax:= dx * 4;
                ay:= dy * 4;

                tx:= round(lx);
                ty:= round(ly);
                hx:= tx;
                hy:= ty;
                while ((ty and LAND_HEIGHT_MASK) = 0) and
                    ((tx and LAND_WIDTH_MASK) = 0) and
                    (Land[ty, tx] = 0) do // TODO: check for constant variable instead
                    begin
                    lx:= lx + ax;
                    ly:= ly + ay;
                    tx:= round(lx);
                    ty:= round(ly)
                    end;
                // reached edge of land. assume infinite beam. Extend it way out past camera
                if ((ty and LAND_HEIGHT_MASK) <> 0) or ((tx and LAND_WIDTH_MASK) <> 0) then
                    begin
                    tx:= round(lx + ax * (max(LAND_WIDTH,4096) div 2));
                    ty:= round(ly + ay * (max(LAND_WIDTH,4096) div 2));
                    end;

                //if (abs(lx-tx)>8) or (abs(ly-ty)>8) then
                    begin
                    DrawLine(hx, hy, tx, ty, 1.0, $FF, $00, $00, $C0);
                    end;
                end;
            // draw crosshair
            CrosshairX := Round(hwRound(Gear^.X) + dx * 80 + GetLaunchX(HH^.CurAmmoType, sign * m, Gear^.Angle));
            CrosshairY := Round(hwRound(Gear^.Y) + dy * 80 + GetLaunchY(HH^.CurAmmoType, Gear^.Angle));

            setTintAdd(true);
            Tint(HH^.Team^.Clan^.Color shl 8 or $FF);
            DrawTextureRotated(CrosshairTexture,
                    12, 12, CrosshairX + WorldDx, CrosshairY + WorldDy, 0,
                    sign * m * (Gear^.Angle * 180.0) / cMaxAngle);
            untint;
            setTintAdd(false);
            end;

        hx:= ox + 8 * sign;
        hy:= oy - 2;
        aangle:= Gear^.Angle * 180 / cMaxAngle - 90;
        if (CurAmmoGear <> nil) and (CurAmmoGear^.Kind <> gtTardis) then
        begin
            case CurAmmoGear^.Kind of
                gtShotgunShot: begin
                        if (CurAmmoGear^.State and gstAnimation <> 0) then
                            DrawSpriteRotated(sprShotgun, hx, hy, sign, aangle)
                        else
                            DrawSpriteRotated(sprHandShotgun, hx, hy, sign, aangle);
                    end;
                gtDEagleShot: DrawSpriteRotated(sprDEagle, hx, hy, sign, aangle);
                gtSniperRifleShot: begin
                        if (CurAmmoGear^.State and gstAnimation <> 0) then
                            DrawSpriteRotatedF(sprSniperRifle, hx, hy, 1, sign, aangle)
                        else
                            DrawSpriteRotatedF(sprSniperRifle, hx, hy, 0, sign, aangle)
                    end;
                gtBallgun: DrawSpriteRotated(sprHandBallgun, hx, hy, sign, aangle);
                gtRCPlane: begin
                    DrawSpriteRotated(sprHandPlane, hx, hy, sign, 0);
                    defaultPos:= false
                    end;
                gtRope: begin
                    if Gear^.X < CurAmmoGear^.X then
                        begin
                        dAngle:= 0;
                        hAngle:= 180;
                        i:= 1
                        end
                    else
                        begin
                        dAngle:= 180;
                        hAngle:= 0;
                        i:= -1
                        end;
                    if ((Gear^.State and gstWinner) = 0) then
                        begin
                        DrawHedgehog(ox, oy,
                                i,
                                1,
                                0,
                                DxDy2Angle(CurAmmoGear^.dY, CurAmmoGear^.dX) + dAngle);
                        with HH^ do
                            if (curhat <> nil) then
                                begin
                                DrawTextureRotatedF(curhat, 1.0, -1.0, -6.0, ox, oy, 0, i, 32, 32,
                                    i*DxDy2Angle(CurAmmoGear^.dY, CurAmmoGear^.dX) + hAngle);
                                if curhat^.w > 64 then
                                    begin
                                    Tint(HH^.Team^.Clan^.Color shl 8 or $FF);
                                    DrawTextureRotatedF(curhat, 1.0, -1.0, -6.0, ox, oy, 32, i, 32, 32,
                                        i*DxDy2Angle(CurAmmoGear^.dY, CurAmmoGear^.dX) + hAngle);
                                    untint
                                    end
                                end
                    end;
                    DrawAltWeapon(Gear, ox, oy);
                    defaultPos:= false
                    end;
                gtBlowTorch:
                    begin
                    DrawSpriteRotated(sprBlowTorch, hx, hy, sign, aangle);
                    DrawHedgehog(sx, sy,
                            sign,
                            3,
                            HH^.visStepPos div 2,
                            0);
                    with HH^ do
                        if (curhat <> nil) then
                            begin
                            DrawTextureF(curhat,
                                1,
                                sx,
                                sy - 5,
                                0,
                                sign,
                                32,
                                32);
                            if curhat^.w > 64 then
                                begin
                                Tint(HH^.Team^.Clan^.Color shl 8 or $FF);
                                DrawTextureF(curhat,
                                    1,
                                    sx,
                                    sy - 5,
                                    32,
                                    sign,
                                    32,
                                    32);
                                untint
                                end
                            end;
                    defaultPos:= false
                    end;
                gtShover: DrawSpriteRotated(sprHandBaseball, hx, hy, sign, aangle + 180);
                gtFirePunch:
                    begin
                    DrawHedgehog(sx, sy,
                            sign,
                            1,
                            4,
                            0);
                    defaultPos:= false
                    end;
                gtPickHammer:
                    begin
                    defaultPos:= false;
                    dec(sy,20);
                    end;
                gtTeleport: defaultPos:= false;
                gtWhip:
                    begin
                    DrawSpriteRotatedF(sprWhip,
                            sx,
                            sy,
                            1,
                            sign,
                            0);
                    defaultPos:= false
                    end;
                gtHammer:
                    begin
                    DrawSpriteRotatedF(sprHammer,
                            sx,
                            sy,
                            1,
                            sign,
                            0);
                    defaultPos:= false
                    end;
                gtResurrector:
                    begin
                    DrawSpriteRotated(sprHandResurrector, sx, sy, 0, 0);
                    defaultPos:= false
                    end;
                gtKamikaze:
                    begin
                    if CurAmmoGear^.Pos = 0 then
                        DrawHedgehog(sx, sy,
                                sign,
                                1,
                                6,
                                0)
                    else
                        DrawSpriteRotatedF(sprKamikaze,
                                ox, oy,
                                CurAmmoGear^.Pos - 1,
                                sign,
                                aangle);
                    defaultPos:= false
                    end;
                gtSeduction:
                    begin
                    if CurAmmoGear^.Pos >= 6 then
                        DrawHedgehog(sx, sy,
                                sign,
                                2,
                                2,
                                0)
                    else
                        begin
                        DrawSpriteRotatedF(sprDress,
                                ox, oy,
                                CurAmmoGear^.Pos,
                                sign,
                                0);
                        DrawSprite(sprCensored, ox - 32, oy - 20, 0)
                        end;
                    defaultPos:= false
                    end;
                gtFlamethrower:
                    begin
                    DrawSpriteRotatedF(sprHandFlamethrower, hx, hy, (RealTicks div 125) mod 4, sign, aangle);
                    if CurAmmoGear^.Tex <> nil then
                        DrawTextureCentered(sx, sy - 40, CurAmmoGear^.Tex)
                    end;
                gtLandGun:
                    begin DrawSpriteRotated(sprHandBallgun, hx, hy, sign, aangle);
                    if CurAmmoGear^.Tex <> nil then
                        DrawTextureCentered(sx, sy - 40, CurAmmoGear^.Tex)
                    end;
                gtIceGun:
                    begin DrawSpriteRotated(sprIceGun, hx, hy, sign, aangle);
                    if CurAmmoGear^.Tex <> nil then
                        DrawTextureCentered(sx, sy - 40, CurAmmoGear^.Tex)
                    end;
            end;

            case CurAmmoGear^.Kind of
                gtShotgunShot,
                gtDEagleShot,
                gtSniperRifleShot,
                gtShover:
                    begin
                    DrawHedgehog(sx, sy, sign, 0, 4, 0);
                    defaultPos:= false;
                    HatVisible:= true
                end
            end
        end else

        if ((Gear^.State and gstHHJumping) <> 0) then
        begin
        DrawHedgehog(sx, sy,
            sign*m,
            1,
            1,
            0);
        HatVisible:= true;
        defaultPos:= false
        end else

        if (Gear^.Message and (gmLeft or gmRight) <> 0) and (not isCursorVisible) then
            begin
            DrawHedgehog(sx, sy,
                sign,
                0,
                HH^.visStepPos div 2,
                0);
            defaultPos:= false;
            HatVisible:= true
            end
        else

        if ((Gear^.State and gstAnimation) <> 0) then
            begin
            if (Gear^.Tag < LongInt(ord(Low(TWave)))) or (Gear^.Tag > LongInt(ord(High(TWave)))) then
                begin
                Gear^.State:= Gear^.State and (not gstAnimation);
                end
            else
                begin
                DrawSpriteRotatedF(Wavez[TWave(Gear^.Tag)].Sprite,
                        sx,
                        sy,
                        Gear^.Pos,
                        sign,
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
                if aangle <= 90 then
                    aangle:= aangle+360;
                if Gear^.dX > _0 then
                    aangle:= aangle-((aangle-240)*HH^.Timer/10)
                else
                    aangle:= aangle+((240-aangle)*HH^.Timer/10);
                dec(HH^.Timer)
                end;
            amt:= CurrentHedgehog^.CurAmmoType;
            CurWeapon:= GetCurAmmoEntry(HH^);
            case amt of
                amBazooka: DrawSpriteRotated(sprHandBazooka, hx, hy, sign, aangle);
                amSnowball: DrawSpriteRotated(sprHandSnowball, hx, hy, sign, aangle);
                amMortar: DrawSpriteRotated(sprHandMortar, hx, hy, sign, aangle);
                amMolotov: DrawSpriteRotated(sprHandMolotov, hx, hy, sign, aangle);
                amBallgun: DrawSpriteRotated(sprHandBallgun, hx, hy, sign, aangle);
                amDrill: DrawSpriteRotated(sprHandDrill, hx, hy, sign, aangle);
                amRope: DrawSpriteRotated(sprHandRope, hx, hy, sign, aangle);
                amShotgun: DrawSpriteRotated(sprHandShotgun, hx, hy, sign, aangle);
                amDEagle: DrawSpriteRotated(sprHandDEagle, hx, hy, sign, aangle);
                amSineGun: DrawSpriteRotatedF(sprHandSinegun, hx, hy, 73 + (sign * LongInt(RealTicks div 73)) mod 8, sign, aangle);

                amPortalGun:
                    if (CurWeapon^.Timer and 2) <> 0 then // Add a new Hedgehog value instead of abusing timer?
                        DrawSpriteRotatedF(sprPortalGun, hx, hy, 0, sign, aangle)
                    else
                        DrawSpriteRotatedF(sprPortalGun, hx, hy, 1+CurWeapon^.Pos, sign, aangle);

                amSniperRifle: DrawSpriteRotatedF(sprSniperRifle, hx, hy, 0, sign, aangle);
                amBlowTorch: DrawSpriteRotated(sprHandBlowTorch, hx, hy, sign, aangle);
                amCake: DrawSpriteRotated(sprHandCake, hx, hy, sign, aangle);
                amGrenade: DrawSpriteRotated(sprHandGrenade, hx, hy, sign, aangle);
                amWatermelon: DrawSpriteRotated(sprHandMelon, hx, hy, sign, aangle);
                amSkip: DrawSpriteRotated(sprHandSkip, hx, hy, sign, aangle);
                amClusterBomb: DrawSpriteRotated(sprHandCluster, hx, hy, sign, aangle);
                amDynamite: DrawSpriteRotated(sprHandDynamite, hx, hy, sign, aangle);
                amHellishBomb: DrawSpriteRotated(sprHandHellish, hx, hy, sign, aangle);
                amGasBomb: DrawSpriteRotated(sprHandCheese, hx, hy, sign, aangle);
                amMine: DrawSpriteRotated(sprHandMine, hx, hy, sign, aangle);
                amAirMine: DrawSpriteRotated(sprHandMine, hx, hy, sign, aangle);
                amSMine: DrawSpriteRotated(sprHandSMine, hx, hy, sign, aangle);
                amKnife: DrawSpriteRotatedF(sprHandKnife, hx, hy, 0, sign, aangle);
                amSeduction: begin
                             DrawSpriteRotated(sprHandSeduction, hx, hy, sign, aangle);
                             DrawCircle(ox, oy, 248, 4, $FF, $00, $00, $AA);
                             //Tint($FF, $0, $0, $AA);
                             //DrawTexture(ox - 240, oy - 240, SpritesData[sprVampiric].Texture, 10);
                             //untint;
                             end;
                amVampiric: DrawSpriteRotatedF(sprHandVamp, hx, hy, (RealTicks div 125) mod 4, sign, aangle);
                amRCPlane: begin
                    DrawSpriteRotated(sprHandPlane, hx, hy, sign, 0);
                    defaultPos:= false
                    end;
                amRubber,
                amGirder: begin
                    DrawSpriteRotated(sprHandConstruction, hx, hy, sign, aangle);
                    if WorldEdge = weWrap then
                        begin
                        if hwRound(Gear^.X) < LongInt(leftX) + 256 then
                            DrawSpriteClipped(sprGirder,
                                            rightX+(ox-leftX)-256,
                                            oy-256,
                                            LongInt(topY)+WorldDy,
                                            LongInt(rightX)+WorldDx,
                                            cWaterLine+WorldDy,
                                            LongInt(leftX)+WorldDx);
                        if hwRound(Gear^.X) > LongInt(rightX) - 256 then
                            DrawSpriteClipped(sprGirder,
                                            leftX-(rightX-ox)-256,
                                            oy-256,
                                            LongInt(topY)+WorldDy,
                                            LongInt(rightX)+WorldDx,
                                            cWaterLine+WorldDy,
                                            LongInt(leftX)+WorldDx)
                        end;
                    DrawSpriteClipped(sprGirder,
                                    ox-256,
                                    oy-256,
                                    LongInt(topY)+WorldDy,
                                    LongInt(rightX)+WorldDx,
                                    cWaterLine+WorldDy,
                                    LongInt(leftX)+WorldDx)
                    end;
                amBee: DrawSpriteRotatedF(sprHandBee, hx, hy, (RealTicks div 125) mod 4, sign, aangle);
                amFlamethrower: DrawSpriteRotatedF(sprHandFlamethrower, hx, hy, (RealTicks div 125) mod 4, sign, aangle);
                amLandGun: DrawSpriteRotated(sprHandBallgun, hx, hy, sign, aangle);
                amIceGun: DrawSpriteRotated(sprIceGun, hx, hy, sign, aangle);
                amResurrector: DrawCircle(ox, oy, 98, 4, $F5, $DB, $35, $AA); // I'd rather not like to hardcode 100 here
            end;

            case amt of
                amAirAttack,
                amMineStrike,
                amDrillStrike: DrawSpriteRotated(sprHandAirAttack, sx, oy, sign, 0);
                amPickHammer: DrawHedgehog(sx, sy,
                            sign,
                            1,
                            2,
                            0);
                amTeleport: DrawSpriteRotatedF(sprTeleport, sx, sy, 0, sign, 0);
                amKamikaze: DrawHedgehog(sx, sy,
                            sign,
                            1,
                            5,
                            0);
                amWhip: DrawSpriteRotatedF(sprWhip,
                            sx,
                            sy,
                            0,
                            sign,
                            0);
                amHammer: DrawSpriteRotatedF(sprHammer,
                            sx,
                            sy,
                            0,
                            sign,
                            0);
            else
                DrawHedgehog(sx, sy,
                    sign,
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
                            sy - 5,
                            0,
                            sign,
                            32,
                            32); *)
            end;

            case amt of
                amBaseballBat: DrawSpriteRotated(sprHandBaseball,
                        sx - 4 * sign,
                        sy + 9, sign, aangle);
            end;

            defaultPos:= false
        end;

    end else // not gstHHDriven
        begin
        if (Gear^.Damage > 0) and (HH^.Effects[heFrozen] = 0)
        and (hwSqr(Gear^.dX) + hwSqr(Gear^.dY) > _0_003) then
            begin
            defaultPos:= false;
                DrawHedgehog(sx, sy,
                    sign,
                    2,
                    1,
                    Gear^.DirAngle);
            if AprilOne and (curhat <> nil) then
                DrawTextureRotatedF(curhat, 1.0, -1.0, 0, sx, sy, 18, sign, 32, 32,
                    sign*Gear^.DirAngle)
            end;


        if ((Gear^.State and gstHHJumping) <> 0) then
            begin
            DrawHedgehog(sx, sy,
                sign*m,
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
            if HH^.Team^.hasGone then Tint($FFFFFF80);
            DrawSpriteRotatedF(sprHHIdle,
                sx,
                sy,
                (RealTicks div 128 + Gear^.Pos) mod 19,
                sign,
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

        if (curhat <> nil)
        and (HatVisibility > 0) then
            if DefaultPos then
                begin
                DrawTextureF(curhat,
                    HatVisibility,
                    sx,
                    sy - 5,
                    (RealTicks div 128 + Gear^.Pos) mod 19,
                    sign,
                    32,
                    32);
                if curhat^.w > 64 then
                    begin
                    Tint(HH^.Team^.Clan^.Color shl 8 or $FF);
                    DrawTextureF(curhat,
                        HatVisibility,
                        sx,
                        sy - 5,
                        (RealTicks div 128 + Gear^.Pos) mod 19 + 32,
                        sign,
                        32,
                        32);
                    untint
                    end;
                if HH^.Team^.hasGone then untint
                end
            else
                begin
                DrawTextureF(curhat,
                    HatVisibility,
                    sx,
                    sy - 5,
                    0,
                    sign*m,
                    32,
                    32);
                if curhat^.w > 64 then
                    begin
                    Tint(HH^.Team^.Clan^.Color shl 8 or $FF);
                    DrawTextureF(curhat,
                        HatVisibility,
                        sx,
                        sy - 5,
                        32,
                        sign*m,
                        32,
                        32);
                    untint
                    end
                end
        end;
    if (Gear^.State and gstHHDriven) <> 0 then
        begin
    (*    if (CurAmmoGear = nil) then
            begin
            amt:= CurrentHedgehog^.CurAmmoType;
            case amt of
                amJetpack: DrawSprite(sprJetpack, sx-32, sy-32, 0);
                end
            end; *)
        if CurAmmoGear <> nil then
            begin
            case CurAmmoGear^.Kind of
                gtJetpack: begin
                        DrawSprite(sprJetpack, sx-32, sy-32, 0);
                        if cWaterLine > hwRound(Gear^.Y) + Gear^.Radius then
                            begin
                            if (CurAmmoGear^.MsgParam and gmUp) <> 0 then
                                DrawSprite(sprJetpack, sx-32, sy-28, 1);
                            if (CurAmmoGear^.MsgParam and gmLeft) <> 0 then
                                DrawSprite(sprJetpack, sx-28, sy-28, 2);
                            if (CurAmmoGear^.MsgParam and gmRight) <> 0 then
                                DrawSprite(sprJetpack, sx-36, sy-28, 3)
                            end;
                        if CurAmmoGear^.Tex <> nil then
                            DrawTextureCentered(sx, sy - 40, CurAmmoGear^.Tex);
                        DrawAltWeapon(Gear, sx, sy)
                        end;
                end;
            end
        end;

    with HH^ do
        begin
        if ((Gear^.State and (not gstWinner)) = 0)
            or ((Gear^.State = gstWait) and (Gear^.dY.QWordValue = 0))
            or (bShowFinger and ((Gear^.State and gstHHDriven) <> 0)) then
            begin
            t:= sy - cHHRadius - 9;
            if (cTagsMask and htTransparent) <> 0 then
                Tint($FF, $FF, $FF, $80);
            if ((cTagsMask and htHealth) <> 0) then
                begin
                dec(t, HealthTagTex^.h + 2);
                DrawTextureCentered(ox, t, HealthTagTex)
                end;
            if (cTagsMask and htName) <> 0 then
                begin
                dec(t, NameTagTex^.h + 2);
                DrawTextureCentered(ox, t, NameTagTex)
                end;
            if (cTagsMask and htTeamName) <> 0 then
                begin
                dec(t, Team^.NameTagTex^.h + 2);
                DrawTextureCentered(ox, t, Team^.NameTagTex)
                end;
            if (cTagsMask and htTransparent) <> 0 then
                untint
            end;
        if (Gear^.State and gstHHDriven) <> 0 then // Current hedgehog
            begin
            if (CurAmmoGear <> nil) and (CurAmmoGear^.Kind = gtResurrector) then
                DrawTextureCentered(ox, sy - cHHRadius - 7 - HealthTagTex^.h, HealthTagTex);

            if bShowFinger and ((Gear^.State and gstHHDriven) <> 0) then
                begin
                ty := oy - 32;
                // move finger higher up if tags are above hog
                if (cTagsMask and htTeamName) <> 0 then
                    ty := ty - Team^.NameTagTex^.h - 2;
                if (cTagsMask and htName) <> 0 then
                    ty := ty - NameTagTex^.h - 2;
                if (cTagsMask and htHealth) <> 0 then
                    ty := ty - HealthTagTex^.h - 2;
                tx := ox;

                // don't go offscreen
                //tx := round(max(((-cScreenWidth + 16) / cScaleFactor) + SpritesData[sprFinger].Width div 2, min(((cScreenWidth - 16) / cScaleFactor) - SpritesData[sprFinger].Width div 2, tx)));
                //ty := round(max(cScreenHeight div 2 - ((cScreenHeight - 16) / cScaleFactor) + SpritesData[sprFinger].Height div 2, min(cScreenHeight div 2 - ((-cScreenHeight + SpritesData[sprFinger].Height) / (cScaleFactor)) - SpritesData[sprFinger].Width div 2 - 96, ty)));
                t:= 32;//trunc((SpritesData[sprFinger].Width + t) / cScaleFactor);
                tx := min(max(tx, ViewLeftX + t), ViewRightX  - t);
                t:= 32;//trunc((SpritesData[sprFinger].Height + t) / cScaleFactor);
                ty := min(ty, ViewBottomY - 96);
                // don't overlap with HH or HH tags
                if ty < ViewTopY + t then
                    begin
                    if abs(tx - ox) < abs(ty - oy)  then
                        ty:= max(ViewTopY + t, oy + t)
                    else
                        ty:= max(ViewTopY + t, ty);
                    end;

                dAngle := DxDy2Angle(int2hwfloat(ty - oy), int2hwfloat(tx - ox)) + 90;

                DrawSpriteRotatedF(sprFinger, tx, ty, RealTicks div 32 mod 16, 1, dAngle);
                end;


            if (Gear^.State and gstDrowning) = 0 then
                if (Gear^.State and gstHHThinking) <> 0 then
                    DrawSprite(sprQuestion, ox - 10, oy - cHHRadius - 34, (RealTicks shr 9) mod 8)
            end
        end;

    if HH^.Effects[hePoisoned] <> 0 then
        begin
        Tint($00, $FF, $40, $80);
        DrawTextureRotatedF(SpritesData[sprSmokeWhite].texture, 1.5, 0, 0, sx, sy, 0, 1, 22, 22, 360 - (RealTicks shr 5) mod 360);
        end;
    if HH^.Effects[heResurrected] <> 0 then
        begin
        Tint($f5, $db, $35, $20);
        DrawSprite(sprVampiric, sx - 24, sy - 24, 0);
        end;

    if (Gear^.Hedgehog^.Effects[heInvulnerable] <> 0) then
        begin
        Tint($FF, $FF, $FF, max($40, round($FF * abs(1 - ((RealTicks div 2 + Gear^.uid * 491) mod 1500) / 750))));
        DrawSprite(sprInvulnerable, sx - 24, sy - 24, 0);
        end;

    if HH^.Effects[heFrozen] < 150000 then
        begin
        if HH^.Effects[heFrozen] < 150000 then
            Tint($FF, $FF, $FF, min(255,127+HH^.Effects[heFrozen] div 800));

        iceOffset:= min(32, HH^.Effects[heFrozen] div 8);
        r.x := 128;
        r.y := 96 - iceOffset;
        r.w := 32;
        r.h := iceOffset;
        DrawTextureFromRectDir(sx - 16 + sign*2, sy + 16 - iceoffset, r.w, r.h, @r, HHTexture, sign);


        if HH^.Effects[heFrozen] < 150000 then
            untint;
        end;


    if cVampiric and
    (CurrentHedgehog^.Gear <> nil) and
    (CurrentHedgehog^.Gear = Gear) then
        begin
        Tint($FF, 0, 0, max($40, round($FF * abs(1 - (RealTicks mod 1500) / 750))));
        DrawSprite(sprVampiric, sx - 24, sy - 24, 0);
        end;
        untint
end;


procedure RenderGear(Gear: PGear; x, y: LongInt);
var
    HHGear: PGear;
    vg: PVisualGear;
    i: Longword;
    aAngle: real;
    startX, endX, startY, endY: LongInt;
begin
    if Gear^.State and gstFrozen <> 0 then Tint($A0, $A0, $FF, $FF);
    //if Gear^.State and gstFrozen <> 0 then Tint(IceColor or $FF);
    if Gear^.Target.X <> NoPointX then
        if Gear^.AmmoType = amBee then
            DrawSpriteRotatedF(sprTargetBee, Gear^.Target.X + WorldDx, Gear^.Target.Y + WorldDy, 0, 0, (RealTicks shr 3) mod 360)
    else if Gear^.AmmoType = amIceGun then
        //DrawSprite(sprSnowDust, Gear^.Target.X + WorldDx, Gear^.Target.Y + WorldDy, (RealTicks shr 2) mod 8)
        //DrawTextureRotatedF(SpritesData[sprSnowDust].Texture, 1, 0, 0, Gear^.Target.X + WorldDx, Gear^.Target.Y + WorldDy, (RealTicks shr 2) mod 8, 1, 22, 22, (RealTicks shr 3) mod 360)
        DrawTextureRotatedF(SpritesData[sprSnowDust].Texture, 1/(1+(RealTicks shr 8) mod 5), 0, 0, Gear^.Target.X + WorldDx, Gear^.Target.Y + WorldDy, (RealTicks shr 2) mod 8, 1, 22, 22, (RealTicks shr 3) mod 360)
    else
        DrawSpriteRotatedF(sprTargetP, Gear^.Target.X + WorldDx, Gear^.Target.Y + WorldDy, 0, 0, (RealTicks shr 3) mod 360);

    case Gear^.Kind of
          gtGrenade: DrawSpriteRotated(sprBomb, x, y, 0, Gear^.DirAngle);
      gtSnowball: DrawSpriteRotated(sprSnowball, x, y, 0, Gear^.DirAngle);
       gtGasBomb: DrawSpriteRotated(sprCheese, x, y, 0, Gear^.DirAngle);

       gtMolotov: if (Gear^.State and gstDrowning) = 0 then
                       DrawSpriteRotatedF(sprMolotov, x, y, (RealTicks div 125) mod 8, hwSign(Gear^.dX), Gear^.DirAngle * hwSign(Gear^.dX))
                  else DrawSprite(sprMolotov, x, y, 8);

       gtRCPlane: begin
                  aangle:= Gear^.Angle * 360 / 4096;
                  if Gear^.Tag < 0 then aangle:= 360-aangle;
                  Tint(Gear^.Tint);
                  DrawSpriteRotatedF(sprPlane, x, y, 0, Gear^.Tag, aangle - 90);
                  untint;
                  DrawSpriteRotatedF(sprPlane, x, y, 1, Gear^.Tag, aangle - 90)
                  end;
       gtBall: DrawSpriteRotatedF(sprBalls, x, y, Gear^.Tag,0, Gear^.DirAngle);

       gtPortal: if ((Gear^.Tag and 1) = 0) // still moving?
                 or (Gear^.LinkedGear = nil) or (Gear^.LinkedGear^.LinkedGear <> Gear) // not linked&backlinked?
                 or ((Gear^.LinkedGear^.Tag and 1) = 0) then // linked portal still moving?
                      DrawSpriteRotatedF(sprPortal, x, y, Gear^.Tag, hwSign(Gear^.dX), Gear^.DirAngle)
                 else DrawSpriteRotatedF(sprPortal, x, y, 4 + Gear^.Tag div 2, hwSign(Gear^.dX), Gear^.DirAngle);

           gtDrill: if (Gear^.State and gsttmpFlag) <> 0 then
                        DrawSpriteRotated(sprAirDrill, x, y, 0, DxDy2Angle(Gear^.dY, Gear^.dX))
                    else
                        DrawSpriteRotated(sprDrill, x, y, 0, DxDy2Angle(Gear^.dY, Gear^.dX));

        gtHedgehog: DrawHH(Gear, x, y);

           gtShell: DrawSpriteRotated(sprBazookaShell, x, y, 0, DxDy2Angle(Gear^.dY, Gear^.dX));

           gtGrave: begin
                    DrawTextureF(Gear^.Hedgehog^.Team^.GraveTex, 1, x, y, (GameTicks shr 7+Gear^.uid) and 7, 1, 32, 32);
                    if Gear^.Health > 0 then
                        begin
                        //Tint($33, $33, $FF, max($40, round($FF * abs(1 - (GameTicks mod (6000 div Gear^.Health)) / 750))));
                        Tint($f5, $db, $35, max($40, round($FF * abs(1 - (GameTicks mod 1500) / (750 + Gear^.Health)))));
                        //Tint($FF, $FF, $FF, max($40, round($FF * abs(1 - (RealTicks mod 1500) / 750))));
                        DrawSprite(sprVampiric, x - 24, y - 24, 0);
                        untint
                        end
                    end;
             gtBee: DrawSpriteRotatedF(sprBee, x, y, (GameTicks shr 5) mod 2, 0, DxDy2Angle(Gear^.dY, Gear^.dX));
      gtPickHammer: DrawSprite(sprPHammer, x - 16, y - 50 + LongInt(((GameTicks shr 5) and 1) * 2), 0);
            gtRope: DrawRope(Gear);

            gtMine: begin
                    if (((Gear^.State and gstAttacking) = 0)or((Gear^.Timer and $3FF) < 420)) and (Gear^.Health <> 0) then
                           DrawSpriteRotated(sprMineOff, x, y, 0, Gear^.DirAngle)
                    else if Gear^.Health <> 0 then
                       DrawSpriteRotated(sprMineOn, x, y, 0, Gear^.DirAngle)
                    else DrawSpriteRotated(sprMineDead, x, y, 0, Gear^.DirAngle);
                    end;
         gtAirMine: if Gear^.State and gstTmpFlag = 0 then                // mine is inactive
                        begin
                        Tint(150,150,150,255);
                        DrawSprite(sprAirMine, x-16, y-16, 15);
                        untint
                        end
                    else if (Gear^.Hedgehog <> nil) and (Gear^.Hedgehog^.Gear <> nil) then  // mine is chasing a hog
                         DrawSprite(sprAirMine, x-16, y-16, (RealTicks div 25) mod 16)
                    else if Gear^.State and gstChooseTarget <> 0 then   // mine is seeking for hogs
                         DrawSprite(sprAirMine, x-16, y-16, (RealTicks div 125) mod 16)
                    else
                         DrawSprite(sprAirMine, x-16, y-16, 4);           // mine is active but not seeking

           gtSMine: if (((Gear^.State and gstAttacking) = 0)or((Gear^.Timer and $3FF) < 420)) and (Gear^.Health <> 0) then
                           DrawSpriteRotated(sprSMineOff, x, y, 0, Gear^.DirAngle)
                       else if Gear^.Health <> 0 then
                           DrawSpriteRotated(sprSMineOn, x, y, 0, Gear^.DirAngle)
                       else DrawSpriteRotated(sprMineDead, x, y, 0, Gear^.DirAngle);
           gtKnife: DrawSpriteRotatedF(sprKnife, x, y, 0, hwSign(Gear^.dX), Gear^.DirAngle);

            gtCase: begin
                    if Gear^.Timer > 1000 then
                        begin
                        if ((Gear^.Pos and posCaseAmmo) <> 0) then
                            begin
                            if Gear^.State and gstFrozen <> 0 then
                                DrawSprite(sprCase, x - 24, y - 28, 0)
                            else
                                begin
                                i:= (GameTicks shr 6) mod 64;
                                if i > 18 then i:= 0;
                                DrawSprite(sprCase, x - 24, y - 24, i)
                                end
                            end
                        else if ((Gear^.Pos and posCaseHealth) <> 0) then
                            begin
                            if Gear^.State and gstFrozen <> 0 then
                                DrawSprite(sprFAid, x - 24, y - 28, 0)
                            else
                                begin
                                i:= ((GameTicks shr 6) + 38) mod 64;
                                if i > 13 then i:= 0;
                                DrawSprite(sprFAid, x - 24, y - 24, i)
                                end
                            end
                        else if ((Gear^.Pos and posCaseUtility) <> 0) then
                            begin
                            if Gear^.State and gstFrozen <> 0 then
                                DrawSprite(sprUtility, x - 24, y - 28, 0)
                            else
                                begin
                                i:= (GameTicks shr 6) mod 70;
                                if i > 23 then i:= 0;
                                i:= i mod 12;
                                DrawSprite(sprUtility, x - 24, y - 24, i)
                                end
                            end
                        end;
                    if Gear^.Timer < 1833 then
                        begin
                        DrawTextureRotatedF(SpritesData[sprPortal].texture, MinD(abs(1.25 - (Gear^.Timer mod 1333) / 400), 1.25), 0, 0,
                                            x, LongInt(Gear^.Angle) + WorldDy - 16, 4 + Gear^.Tag, 1, 32, 32, 270);
                        end
                    end;
      gtExplosives: begin
                    if ((Gear^.State and gstDrowning) <> 0) then
                        DrawSprite(sprExplosivesRoll, x - 24, y - 24, 0)
                    else if Gear^.State and gstAnimation = 0 then
                        begin
                        i:= (GameTicks shr 6 + Gear^.uid*3) mod 64;
                        if i > 18 then
                            i:= 0;
                        DrawSprite(sprExplosives, x - 24, y - 24, i)
                        end
                    else if Gear^.State and gsttmpFlag = 0 then
                        DrawSpriteRotatedF(sprExplosivesRoll, x, y + 4, 0, 0, Gear^.DirAngle)
                    else
                        DrawSpriteRotatedF(sprExplosivesRoll, x, y + 4, 1, 0, Gear^.DirAngle)
                    end;
        gtDynamite: DrawSprite(sprDynamite, x - 16, y - 25, Gear^.Tag and 1, Gear^.Tag shr 1);
     gtClusterBomb: DrawSpriteRotated(sprClusterBomb, x, y, 0, Gear^.DirAngle);
         gtCluster: DrawSprite(sprClusterParticle, x - 8, y - 8, 0);
           gtFlame: if Gear^.Tag and 1 = 0 then
                         DrawTextureF(SpritesData[sprFlame].Texture, 2 / (Gear^.Tag mod 3 + 2), x, y, (GameTicks shr 7 + LongWord(Gear^.Tag)) mod 8, 1, 16, 16)
                    else DrawTextureF(SpritesData[sprFlame].Texture, 2 / (Gear^.Tag mod 3 + 2), x, y, (GameTicks shr 7 + LongWord(Gear^.Tag)) mod 8, -1, 16, 16);
       gtParachute: begin
                    DrawSprite(sprParachute, x - 24, y - 48, 0);
                    DrawAltWeapon(Gear, x + 1, y - 3)
                    end;
       gtAirAttack: begin
                    Tint(Gear^.Tint);
                    DrawSpriteRotatedF(sprAirplane, x, y, 0, Gear^.Tag, 0);
                    untint;
                    DrawSpriteRotatedF(sprAirplane, x, y, 1, Gear^.Tag, 0);
                    end;
         gtAirBomb: DrawSpriteRotated(sprAirBomb, x, y, 0, DxDy2Angle(Gear^.dY, Gear^.dX));
        gtTeleport: begin
                    HHGear:= Gear^.Hedgehog^.Gear;
                    if HHGear <> nil then
                        begin
                        if ((Gear^.State and gstAnimation) <> 0) then
                            DrawSpriteRotatedF(sprTeleport, x + 1, y - 3, Gear^.Pos, hwSign(Gear^.dX), 0);
                        DrawSpriteRotatedF(sprTeleport, hwRound(HHGear^.X) + 1 + WorldDx, hwRound(HHGear^.Y) - 3 + WorldDy, 11 - Gear^.Pos, hwSign(HHGear^.dX), 0)
                        end
                    end;
        gtSwitcher: DrawSprite(sprSwitch, x - 16, y - 56, (GameTicks shr 6) mod 12);
          gtTarget: begin
                    Tint($FF, $FF, $FF, round($FF * Gear^.Timer / 1000));
                    DrawSprite(sprTarget, x - 16, y - 16, 0);
                    untint;
                    end;
          gtMortar: DrawSpriteRotated(sprMortar, x, y, 0, DxDy2Angle(Gear^.dY, Gear^.dX));
          gtCake: if Gear^.Pos = 6 then
                     DrawSpriteRotatedF(sprCakeWalk, x, y, (GameTicks div 40) mod 6, hwSign(Gear^.dX), Gear^.DirAngle * hwSign(Gear^.dX) + 90)
                  else
                     DrawSpriteRotatedF(sprCakeDown, x, y, 5 - Gear^.Pos, hwSign(Gear^.dX), Gear^.DirAngle * hwSign(Gear^.dX) + 90);
       gtSeduction: if Gear^.Pos >= 14 then
           DrawSprite(sprSeduction, x - 16, y - 16, 0);

      gtWatermelon: DrawSpriteRotatedF(sprWatermelon, x, y, 0, 0, Gear^.DirAngle);
      gtMelonPiece: DrawSpriteRotatedF(sprWatermelon, x, y, 1, 0, Gear^.DirAngle);
     gtHellishBomb: DrawSpriteRotated(sprHellishBomb, x, y, 0, Gear^.DirAngle);
           gtBirdy: begin
                    if Gear^.State and gstAnimation = gstAnimation then
                        begin
                        if Gear^.State and gstTmpFlag = 0 then // Appearing
                            begin
                            endX:= x - WorldDx;
                            endY:= y - WorldDy;
                            if Gear^.Tag < 0 then
                                startX:= max(max(LAND_WIDTH,4096) + 1024, endX + 2048)
                            else
                                startX:= max(-max(LAND_WIDTH,4096) - 1024, endX - 2048);
                            startY:= endY - 1024;
                            DrawTextureF(SpritesData[sprBirdy].Texture, min(Gear^.Timer/750,1), startX + WorldDx + LongInt(round((endX - startX) * (-power(2, -10 * LongInt(Gear^.Timer)/2000) + 1))), startY + WorldDy + LongInt(round((endY - startY) * sqrt(1 - power((LongInt(Gear^.Timer)/2000)-1, 2)))), ((Gear^.Pos shr 6) or (RealTicks shr 8)) mod 2, Gear^.Tag, 75, 75);
                            end
                        else // Disappearing
                            begin
                            startX:= x - WorldDx;
                            startY:= y - WorldDy;
                            if Gear^.Tag > 0 then
                                endX:= max(max(LAND_WIDTH,4096) + 1024, startX + 2048)
                            else
                                endX:= max(-max(LAND_WIDTH,4096) - 1024, startX - 2048);
                            endY:= startY + 1024;
                            DrawTextureF(SpritesData[sprBirdy].Texture, min((2000-Gear^.Timer)/750,1), startX + WorldDx + LongInt(round((endX - startX) * power(2, 10 * (LongInt(Gear^.Timer)/2000 - 1)))) + hwRound(Gear^.dX * Gear^.Timer), startY + WorldDy + LongInt(round((endY - startY) * cos(LongInt(Gear^.Timer)/2000 * (Pi/2)) - (endY - startY))) + hwRound(Gear^.dY * Gear^.Timer), ((Gear^.Pos shr 6) or (RealTicks shr 8)) mod 2, Gear^.Tag, 75, 75);
                            end;
                        end
                    else
                        begin
                        if Gear^.Health < 250 then
                            DrawTextureF(SpritesData[sprBirdy].Texture, 1, x, y, ((Gear^.Pos shr 6) or (RealTicks shr 7)) mod 2, Gear^.Tag, 75, 75)
                        else
                            DrawTextureF(SpritesData[sprBirdy].Texture, 1, x, y, ((Gear^.Pos shr 6) or (RealTicks shr 8)) mod 2, Gear^.Tag, 75, 75);
                        end;
                    end;
             gtEgg: DrawTextureRotatedF(SpritesData[sprEgg].Texture, 1, 0, 0, x, y, 0, 1, 16, 16, Gear^.DirAngle);
           gtPiano: begin
                    if (Gear^.State and gstDrowning) = 0 then
                        begin
                        Tint($FF, $FF, $FF, $10);
                        for i:= 8 downto 1 do
                            DrawTextureF(SpritesData[sprPiano].Texture, 1, x, y - hwRound(Gear^.dY * 4 * i), 0, 1, 128, 128);
                        untint
                        end;
                    DrawTextureF(SpritesData[sprPiano].Texture, 1, x, y, 0, 1, 128, 128);
                    end;
     gtPoisonCloud: begin
                    if Gear^.Timer < 1020 then
                        Tint(Gear^.Tint and $FFFFFF00 or Gear^.Timer div 8)
                    else if Gear^.Timer > 3980 then
                        Tint(Gear^.Tint and $FFFFFF00 or (5000 - Gear^.Timer) div 8)
                    else
                        Tint(Gear^.Tint);
                    DrawTextureRotatedF(SpritesData[sprSmokeWhite].texture, 3, 0, 0, x, y, 0, 1, 22, 22, (RealTicks shr 4 + Gear^.UID * 100) mod 360);
                    untint
                    end;
     gtResurrector: begin
                    DrawSpriteRotated(sprCross, x, y, 0, 0);
                    Tint(Gear^.Tint and $FFFFFF00 or max($00, round($C0 * abs(1 - (GameTicks mod 6000) / 3000))));
                    DrawTexture(x - 108, y - 108, SpritesData[sprVampiric].Texture, 4.5);
                    untint;
                    end;
      gtNapalmBomb: DrawSpriteRotated(sprNapalmBomb, x, y, 0, DxDy2Angle(Gear^.dY, Gear^.dX));
           gtFlake: if Gear^.State and (gstDrowning or gstTmpFlag) <> 0  then
                        begin
                        Tint(Gear^.Tint);
                        // Needs a nicer white texture to tint
                        DrawTextureRotatedF(SpritesData[sprSnowDust].Texture, 1, 0, 0, x, y, 0, 1, 8, 8, Gear^.DirAngle);
                        //DrawSpriteRotated(sprSnowDust, x, y, 0, Gear^.DirAngle);
                        //DrawTexture(x, y, SpritesData[sprVampiric].Texture, 0.1);
                        untint;
                        end
                    else //if not isInLag then
                        begin
                        if isInLag and (Gear^.FlightTime < 256) then
                            inc(Gear^.FlightTime, 8)
                        else if (not isInLag) and (Gear^.FlightTime > 0) then
                            dec(Gear^.FlightTime, 8);
                        if Gear^.FlightTime > 0 then
                            Tint($FF, $FF, $FF, $FF-min(255,Gear^.FlightTime));
                        if vobVelocity = 0 then
                            DrawSprite(sprFlake, x, y, Gear^.Timer)
                        else
                            DrawSpriteRotatedF(sprFlake, x, y, Gear^.Timer, 1, Gear^.DirAngle);
//DrawSprite(sprFlake, x-SpritesData[sprFlake].Width div 2, y-SpritesData[sprFlake].Height div 2, Gear^.Timer)
//DrawSpriteRotatedF(sprFlake, x-SpritesData[sprFlake].Width div 2, y-SpritesData[sprFlake].Height div 2, Gear^.Timer, 1, Gear^.DirAngle);
                        if Gear^.FlightTime > 0 then
                            untint;
                        end;
       //gtStructure: DrawSprite(sprTarget, x - 16, y - 16, 0);
          gtTardis: if Gear^.Pos <> 4 then
                        begin
                        if Gear^.Pos = 2 then
                            Tint(Gear^.Hedgehog^.Team^.Clan^.Color shl 8 or $FF)
                        else
                            Tint(Gear^.Hedgehog^.Team^.Clan^.Color shl 8 or max($00, round(Gear^.Power * (1-abs(0.5 - (GameTicks mod 2000) / 2000)))));
                        DrawSprite(sprTardis, x-24, y-63,0);
                        if Gear^.Pos = 2 then
                            untint
                        else
                            Tint($FF,$FF,$FF,max($00, round(Gear^.Power * (1-abs(0.5 - (GameTicks mod 2000) / 2000)))));
                        DrawSprite(sprTardis, x-24, y-63,1);
                        if Gear^.Pos <> 2 then
                            untint
(*
                        Tint(Gear^.Hedgehog^.Team^.Clan^.Color shl 8 or max($00, round(Gear^.Power * abs(1 - (RealTicks mod 500) / 250))));
                        DrawTexture(x-6, y-70, SpritesData[sprVampiric].Texture, 0.25);
                        untint
*)
                        end;
            gtIceGun: begin
                      HHGear := Gear^.Hedgehog^.Gear;
                      if HHGear <> nil then
                          begin
                          i:= hwRound(hwSqr(Gear^.X - HHGear^.X) + hwSqr(Gear^.Y - HHGear^.Y));
                          if RealTicks mod max(1,50 - (round(sqrt(i)) div 4)) = 0 then // experiment in "intensifying" might not get used
                            begin
                            vg:= AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtDust, 1);
                            if vg <> nil then
                                begin
                                i:= random(100) + 155;
                                vg^.Tint:= i shl 24 or i shl 16 or $FF shl 8 or Longword(random(200) + 55);
                                vg^.Angle:= random(360);
                                vg^.dx:= 0.001 * random(80);
                                vg^.dy:= 0.001 * random(80)
                                end
                            end;
                          if RealTicks mod 2 = 0 then
                                begin
                                i:= random(100)+100;
                                if Gear^.Target.X <> NoPointX then
                                    begin
                                    DrawLine(Gear^.Target.X, Gear^.Target.Y, hwRound(HHGear^.X), hwRound(HHGear^.Y), 4.0, i, i, $FF, $40);
                                    end
                                else
                                    begin
                                    DrawLine(hwRound(HHGear^.X), hwRound(HHGear^.Y), hwRound(Gear^.X), hwRound(Gear^.Y), 4.0, i, i, $FF, $40);
                                    end;
                                end
                          end
                      end;
            gtGenericFaller: DrawCircle(x, y, 3, 3, $FF, $00, $00, $FF);  // debug
         end;
      if Gear^.RenderTimer and (Gear^.Tex <> nil) then
          DrawTextureCentered(x + 8, y + 8, Gear^.Tex);
    if Gear^.State and gstFrozen <> 0 then untint
end;

end.
