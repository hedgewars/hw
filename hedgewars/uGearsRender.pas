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
procedure RenderGearTimer(Gear: PGear; x, y: LongInt);
procedure RenderGearHealth(Gear: PGear; x, y: LongInt);
procedure RenderHHGuiExtras(Gear: PGear; ox, oy: LongInt);
procedure DrawHHOrder();

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
uses uRender, uRenderUtils, uGearsUtils, uUtils, uVariables, uAmmos, Math, uVisualGearsList;

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
    
    Tint(Gear^.Tint shr 24 div 3, Gear^.Tint shr 16 and $FF div 3, Gear^.Tint shr 8 and $FF div 3, Gear^.Tint and $FF);

    n:= RopePoints.Count + 2;

    SetVertexPointer(@RopePoints.rounded[0], n);

    openglPushMatrix();
    openglTranslatef(WorldDx, WorldDy, 0);

    glLineWidth(3.0 * cScaleFactor);
    glDrawArrays(GL_LINE_STRIP, 0, n);
    Tint(Gear^.Tint);
    glLineWidth(2.0 * cScaleFactor);
    glDrawArrays(GL_LINE_STRIP, 0, n);

    untint;

    openglPopMatrix();

    EnableTexture(true);
    end
end;


procedure DrawRopeLine(X1, Y1, X2, Y2: Real; LayerIndex: Longword; var linesLength, ropeLength: Real);
var dX, dY, angle, length: Real;
    FrameIndex: LongWord;
begin
    if (X1 = X2) and (Y1 = Y2) then
        exit;

    dX:= X2 - X1;
    dY:= Y2 - Y1;
    length:= sqrt(sqr(dX) + sqr(dY));
    angle:= arctan2(dY, dX) * 180 / PI - 90;

    dX:= dX / length;
    dY:= dY / length;

    while (ropeLength - linesLength) <= length do
    begin
        FrameIndex:= round(ropeLength / cRopeNodeStep);
        if (FrameIndex mod cRopeLayers) = LayerIndex then
            DrawSpriteRotatedFReal(sprRopeNode,
                X1 + (ropeLength - linesLength) * dX,
                Y1 + (ropeLength - linesLength) * dY,
                FrameIndex, 1, angle);
        ropeLength:= ropeLength + cRopeNodeStep;
    end;
    linesLength:= linesLength + length
end;

procedure DrawRopeLayer(Gear: PGear; LayerIndex: LongWord);
var i: LongInt;
    linesLength, ropeLength: Real;
begin
    linesLength:= 0;
    ropeLength:= cRopeNodeStep;
    if RopePoints.Count > 0 then
    begin
        i:= 0;
        while i < Pred(RopePoints.Count) do
        begin
            DrawRopeLine(hwFloat2Float(RopePoints.ar[i].X) + WorldDx, hwFloat2Float(RopePoints.ar[i].Y) + WorldDy,
                         hwFloat2Float(RopePoints.ar[Succ(i)].X) + WorldDx, hwFloat2Float(RopePoints.ar[Succ(i)].Y) + WorldDy,
                         LayerIndex, linesLength, ropeLength);
            inc(i)
        end;

        DrawRopeLine(hwFloat2Float(RopePoints.ar[i].X) + WorldDx, hwFloat2Float(RopePoints.ar[i].Y) + WorldDy,
                     hwFloat2Float(Gear^.X) + WorldDx, hwFloat2Float(Gear^.Y) + WorldDy,
                     LayerIndex, linesLength, ropeLength);

        DrawRopeLine(hwFloat2Float(Gear^.X) + WorldDx, hwFloat2Float(Gear^.Y) + WorldDy,
                     hwFloat2Float(Gear^.Hedgehog^.Gear^.X) + WorldDx, hwFloat2Float(Gear^.Hedgehog^.Gear^.Y) + WorldDy,
                     LayerIndex, linesLength, ropeLength);
    end
    else
        if Gear^.Elasticity.QWordValue > 0 then
            DrawRopeLine(hwFloat2Float(Gear^.X) + WorldDx, hwFloat2Float(Gear^.Y) + WorldDy,
                         hwFloat2Float(Gear^.Hedgehog^.Gear^.X) + WorldDx, hwFloat2Float(Gear^.Hedgehog^.Gear^.Y) + WorldDy,
                         LayerIndex, linesLength, ropeLength);
end;

procedure DrawRope(Gear: PGear);
var i: LongInt;
begin
    if Gear^.Hedgehog^.Gear = nil then exit;
    if (Gear^.Tag = 1) or ((cReducedQuality and rqSimpleRope) <> 0) then
        DrawRopeLinesRQ(Gear)
    else
        for i := 0 to cRopeLayers - 1 do
            DrawRopeLayer(Gear, i);

if RopePoints.Count > 0 then
    DrawSpriteRotated(sprRopeHook, hwRound(RopePoints.ar[0].X) + WorldDx, hwRound(RopePoints.ar[0].Y) + WorldDy, 1, RopePoints.HookAngle)
else
    if Gear^.Elasticity.QWordValue > 0 then
        DrawSpriteRotated(sprRopeHook, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, DxDy2Angle(Gear^.dY, Gear^.dX));
end;


procedure DrawSelectedWeapon(Gear: PGear; sx, sy: LongInt; isAltWeapon: boolean);
begin
with Gear^.Hedgehog^ do
    begin
    if ((Gear^.State and gstAttacked) <> 0) then
        exit;
    if (isAltWeapon and ((Ammoz[CurAmmoType].Ammo.Propz and ammoprop_AltUse) = 0)) then
        exit;
    if (not isAltWeapon) and (((Ammoz[CurAmmoType].Ammo.Propz and ammoprop_ShowSelIcon) = 0) or (
            (((Ammoz[CurAmmoType].Ammo.Propz and ammoprop_AttackInMove) = 0) and ((Gear^.State and gstMoving) <> 0)))) then
        exit;
    if (not isAltWeapon) then
        begin
        sy:= sy - 64;
        if (IsHogFacingLeft(Gear)) then
            sx:= sx - 61;
        end;
    DrawTexture(sx + 16, sy + 16, ropeIconTex);
    DrawTextureF(SpritesData[sprAMAmmos].Texture, 0.75, sx + 30, sy + 30, ord(CurAmmoType) - 1, 1, 32, 32);
    end;
end;

procedure DrawHHOrder();
var HHGear: PGear;
    hh: PHedgehog;
    c, i, t, x, y, sprH, sprW, fSprOff: LongInt;
begin
t:= LocalTeam;

if not CurrentTeam^.ExtDriven then
    for i:= 0 to Pred(TeamsCount) do
        if (TeamsArray[i] = CurrentTeam) then
            t:= i;

if t < 0 then
    exit;

if TeamsArray[t] <> nil then
    begin
    sprH:= SpritesData[sprBigDigit].Height;
    sprW:= SpritesData[sprBigDigit].Width;
    fSprOff:= sprW div 4 + SpritesData[sprFrame].Width div 4 - 1; // - 1 for overlap to avoid artifacts
    i:= 0;
    c:= 0;
        repeat
        hh:= @TeamsArray[t]^.Hedgehogs[i];
        inc(i);
        if (hh <> nil) and (hh^.Gear <> nil) and (not hh^.Unplaced) then
            begin
            inc(c);
            HHGear:= hh^.Gear;
            x:= hwRound(HHGear^.X) + WorldDx;
            y:= hwRound(HHGear^.Y) + WorldDy - 2;
            DrawTextureF(SpritesData[sprFrame].Texture, 0.5, x - fSprOff, y, 0, 1, SpritesData[sprFrame].Width, SpritesData[sprFrame].Height);
            DrawTextureF(SpritesData[sprFrame].Texture, 0.5, x + fSprOff, y, 1, 1, SpritesData[sprFrame].Width, SpritesData[sprFrame].Height);
            DrawTextureF(SpritesData[sprBigDigit].Texture, 0.5, x, y, c, 1, sprW, sprH);
            if SpeechHogNumber = c then
                DrawCircle(x, y, 20, 3, 0, $FF, $FF, $80);
            end;
        until (i > cMaxHHIndex);
    end

end;

// Render some informational GUI next to hedgehog, like fuel and alternate weapon
procedure RenderHHGuiExtras(Gear: PGear; ox, oy: LongInt);
var HH: PHedgehog;
    sx, sy, tx, ty, t, hogLR: LongInt;
    dAngle: real;
begin
    HH:= Gear^.Hedgehog;
    sx:= ox + 1; // this offset is very common
    sy:= oy - 3;
    if HH^.Unplaced then
        exit;
    if (Gear^.State and gstHHDeath) <> 0 then
        exit;
    if (Gear^.State and gstHHGone) <> 0 then
        exit;
    if (CinematicScript) then
        exit;

    // render finger (pointing arrow)
    if bShowFinger and ((Gear^.State and gstHHDriven) <> 0) then
        begin
        ty := oy - 32;
        // move finger higher up if tags are above hog
        if (cTagsMask and htTeamName) <> 0 then
            ty := ty - HH^.Team^.NameTagTex^.h - 2;
        if (cTagsMask and htName) <> 0 then
            ty := ty - HH^.NameTagTex^.h - 2;
        if (cTagsMask and htHealth) <> 0 then
            ty := ty - HH^.HealthTagTex^.h - 2;
        tx := ox;

        // don't go offscreen
        t:= 32;
        tx := min(max(tx, ViewLeftX + t), ViewRightX - t);
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

        if (IsTooDarkToRead(HH^.Team^.Clan^.Color)) then
            DrawSpriteRotatedF(sprFingerBackInv, tx, ty, RealTicks div 32 mod 16, 1, dAngle)
        else
            DrawSpriteRotatedF(sprFingerBack, tx, ty, RealTicks div 32 mod 16, 1, dAngle);
        Tint(HH^.Team^.Clan^.Color shl 8 or $FF);
        DrawSpriteRotatedF(sprFinger, tx, ty, RealTicks div 32 mod 16, 1, dAngle);
        untint;
        end;

    // render crosshair
    if (CrosshairGear <> nil) and (Gear = CrosshairGear) then
        begin
        hogLR:= 1;
        if IsHogFacingLeft(Gear) then
            hogLR:= -1;
        setTintAdd(true);
        Tint(HH^.Team^.Clan^.Color shl 8 or $FF);
        DrawTextureRotated(CrosshairTexture,
                12, 12, CrosshairX + WorldDx, CrosshairY + WorldDy, 0,
                hogLR * (Gear^.Angle * 180.0) / cMaxAngle);
        untint;
        setTintAdd(false);
        end;

    // render gear-related extras: alt weapon, fuel, other
    if ((Gear^.State and gstHHDriven) <> 0) and (CurAmmoGear <> nil) then
        begin
        case CurAmmoGear^.Kind of
            gtJetpack:      begin
                            // render jetpack contour if underwater
                            if (((not SuddenDeathDmg) and (WaterOpacity > 179)) or (SuddenDeathDmg and (SDWaterOpacity > 179))) and
                                    ((cWaterLine < (hwRound(Gear^.Y) + Gear^.Radius - 16)) or
                                    ((WorldEdge = weSea) and ((hwRound(Gear^.X) < LeftX) or (hwRound(Gear^.X) > RightX)))) then
                                DrawSprite(sprJetpack, sx-32, sy-32, 4);
                            if CurAmmoGear^.Tex <> nil then
                                DrawTextureCentered(sx, sy - 40, CurAmmoGear^.Tex);
                            DrawSelectedWeapon(Gear, sx, sy, true);
                            end;
            gtRope:         DrawSelectedWeapon(Gear, sx, sy, true);
            gtParachute:    DrawSelectedWeapon(Gear, sx, sy, true);
            gtLandGun:      if CurAmmoGear^.Tex <> nil then
                                DrawTextureCentered(sx, sy - 40, CurAmmoGear^.Tex);
            gtFlamethrower: if CurAmmoGear^.Tex <> nil then
                                DrawTextureCentered(sx, sy - 40, CurAmmoGear^.Tex);
            gtIceGun:       if CurAmmoGear^.Tex <> nil then
                                DrawTextureCentered(sx, sy - 40, CurAmmoGear^.Tex);
        end;
        end
    else if ((Gear^.State and gstHHDriven) <> 0) then
        begin
        DrawSelectedWeapon(Gear, sx, sy, false);
        end
end;

procedure DrawHH(Gear: PGear; ox, oy: LongInt);
var i, t: LongInt;
    amt: TAmmoType;
    sign, hx, hy, tx, ty, sx, sy, hogLR: LongInt;  // hedgehog, crosshair, temp, sprite, direction
    dx, dy, ax, ay, aAngle, dAngle, hAngle, lx, ly: real;  // laser, change
    wraps: LongWord; // numbe of wraps for laser in world wrap
    defaultPos, HatVisible, inWorldBounds: boolean;
    HH: PHedgehog;
    CurWeapon: PAmmo;
    iceOffset:Longint;
    r:TSDL_Rect;
    curhat: PTexture;
begin
    HH:= Gear^.Hedgehog;
    CrosshairGear:= nil;
    if HH^.Unplaced then
        exit;
    if (HH^.CurAmmoType = amKnife) and (HH = CurrentHedgehog) then
         curhat:= ChefHatTexture
    else curhat:= HH^.HatTex;
    sx:= ox + 1; // this offset is very common
    sy:= oy - 3;
    sign:= hwSign(Gear^.dX);
    if IsHogFacingLeft(Gear) then
        hogLR:= -1
    else
        hogLR:= 1;

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
            (((CurAmmoGear <> nil) and
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
            dx:= hogLR * Sin(Gear^.Angle * pi / cMaxAngle);
            dy:= -Cos(Gear^.Angle * pi / cMaxAngle);
            if cLaserSighting or cLaserSightingSniper then
                begin
                lx:= GetLaunchX(HH^.CurAmmoType, hogLR, Gear^.Angle);
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
                wraps:= 0;
                inWorldBounds := ((ty and LAND_HEIGHT_MASK) or (tx and LAND_WIDTH_MASK)) = 0;
                while (inWorldBounds and ((Land[ty, tx] and lfAll) = 0)) or (not inWorldBounds) do
                    begin
                    if wraps > cMaxLaserSightWraps then
                        break;
                    lx:= lx + ax;
                    ly:= ly + ay;
                    tx:= round(lx);
                    ty:= round(ly);
                    // reached edge of land.
                    if ((ty and LAND_HEIGHT_MASK) <> 0) and (((ty < LAND_HEIGHT) and (ay < 0)) or ((ty >= TopY) and (ay > 0))) then
                        begin
                        // assume infinite beam. Extend it way out past camera
                        tx:= round(lx + ax * (max(LAND_WIDTH,4096) div 2));
                        ty:= round(ly + ay * (max(LAND_WIDTH,4096) div 2));
                        break;
                        end;

                    if ((hogLR < 0) and (tx < LeftX)) or ((hogLR > 0) and (tx >= RightX)) then
                        if (WorldEdge = weWrap) then
                            // wrap beam
                            begin
                            if hogLR < 0 then
                                lx:= RightX - (ax - (lx - LeftX))
                            else
                                lx:= LeftX + (ax - (RightX - lx));
                            tx:= round(lx);
                            inc(wraps);
                            end
                        else if (WorldEdge = weBounce) then
                            // just stop
                            break;

                    if ((tx and LAND_WIDTH_MASK) <> 0) and (((ax > 0) and (tx >= RightX)) or ((ax < 0) and (tx <= LeftX))) then
                        begin
                        if (WorldEdge <> weWrap) and (WorldEdge <> weBounce) then
                            // assume infinite beam. Extend it way out past camera
                            begin
                            tx:= round(lx + ax * (max(LAND_WIDTH,4096) div 2));
                            ty:= round(ly + ay * (max(LAND_WIDTH,4096) div 2));
                            end;
                        break;
                        end;
                    inWorldBounds := ((ty and LAND_HEIGHT_MASK) or (tx and LAND_WIDTH_MASK)) = 0;
                    end;

                DrawLineWrapped(hx, hy, tx, ty, 1.0, hogLR < 0, wraps, $FF, $00, $00, $C0);
                end;

            // calculate crosshair position
            CrosshairX := Round(hwRound(Gear^.X) + dx * 80 + GetLaunchX(HH^.CurAmmoType, hogLR, Gear^.Angle));
            CrosshairY := Round(hwRound(Gear^.Y) + dy * 80 + GetLaunchY(HH^.CurAmmoType, Gear^.Angle));
            // crosshair will be rendered in RenderHHGuiExtras
            CrosshairGear := Gear;
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
                                if (curhat^.w > 64) or ((curhat^.w = 64) and (curhat^.h = 32)) then
                                    begin
                                    if ((curhat^.w = 64) and (curhat^.h = 32)) then
                                        tx := 1
                                    else
                                        tx := 32;
                                    Tint(HH^.Team^.Clan^.Color shl 8 or $FF);
                                    DrawTextureRotatedF(curhat, 1.0, -1.0, -6.0, ox, oy, tx, i, 32, 32,
                                        i*DxDy2Angle(CurAmmoGear^.dY, CurAmmoGear^.dX) + hAngle);
                                    untint
                                    end
                                end
                    end;
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
                            if (curhat^.w > 64) or ((curhat^.w = 64) and (curhat^.h = 32)) then
                                begin
                                if ((curhat^.w = 64) and (curhat^.h = 32)) then
                                    tx := 1
                                else
                                    tx := 32;
                                Tint(HH^.Team^.Clan^.Color shl 8 or $FF);
                                DrawTextureF(curhat,
                                    1,
                                    sx,
                                    sy - 5,
                                    tx,
                                    sign,
                                    32,
                                    32);
                                untint
                                end
                            end;
                    defaultPos:= false
                    end;
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
                        // sprCensored contains English text, so only show it for English locales
                        // TODO: Make text translatable. But how?
                        if Copy(cLanguage, 1, 2) = 'en' then
                            DrawSprite(sprCensored, ox - 32, oy - 20, 0);
                        end;
                    defaultPos:= false
                    end;
                gtFlamethrower: DrawSpriteRotatedF(sprHandFlamethrower, hx, hy, (RealTicks div 125) mod 4, sign, aangle);
                gtLandGun: DrawSpriteRotated(sprHandLandGun, hx, hy, sign, aangle);
                gtIceGun: DrawSpriteRotated(sprIceGun, hx, hy, sign, aangle);
            end;

            case CurAmmoGear^.Kind of
                gtShotgunShot,
                gtDEagleShot,
                gtSniperRifleShot:
                    begin
                    DrawHedgehog(sx, sy, sign, 0, 4, 0);
                    defaultPos:= false;
                    HatVisible:= true
                    end;
                gtShover, gtMinigun:
                    begin
                    DrawHedgehog(sx, sy, sign, 0, 5, 0);
                    defaultPos:= false;
                    HatVisible:= true
                    end
            end
        end else

        if ((Gear^.State and gstHHJumping) <> 0) then
        begin
        DrawHedgehog(sx, sy,
            hogLR,
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
                amCreeper: DrawSpriteRotatedF(sprHandCreeper, hx, hy, 0, sign, aangle);
                amHellishBomb: DrawSpriteRotated(sprHandHellish, hx, hy, sign, aangle);
                amGasBomb: DrawSpriteRotated(sprHandCheese, hx, hy, sign, aangle);
                amMine: DrawSpriteRotated(sprHandMine, hx, hy, sign, aangle);
                amAirMine: DrawSpriteRotated(sprHandAirMine, hx, hy, sign, aangle);
                amSMine: DrawSpriteRotated(sprHandSMine, hx, hy, sign, aangle);
                amKnife: DrawSpriteRotatedF(sprHandKnife, hx, hy, 0, sign, aangle);
                amSeduction: begin
                             DrawSpriteRotated(sprHandSeduction, hx, hy, sign, aangle);
                             DrawCircle(ox, oy, 248, 4, $FF, $00, $00, $AA);
                             end;
                amVampiric: DrawSpriteRotatedF(sprHandVamp, hx, hy, (RealTicks div 125) mod 4, sign, aangle);
                amRCPlane: begin
                    DrawSpriteRotated(sprHandPlane, hx, hy, sign, 0);
                    defaultPos:= false
                    end;
                amRubber,
                amGirder: begin
                    DrawSpriteRotated(sprHandConstruction, hx, hy, sign, aangle);
                    if cBuildMaxDist = cDefaultBuildMaxDist then
                        begin
                        if WorldEdge = weWrap then
                            begin
                            if hwRound(Gear^.X) < leftX + 256 then
                                DrawSpriteClipped(sprGirder,
                                                rightX+(ox-leftX)-256,
                                                oy-256,
                                                topY+WorldDy,
                                                rightX+WorldDx,
                                                cWaterLine+WorldDy,
                                                leftX+WorldDx);
                            if hwRound(Gear^.X) > rightX - 256 then
                                DrawSpriteClipped(sprGirder,
                                                leftX-(rightX-ox)-256,
                                                oy-256,
                                                topY+WorldDy,
                                                rightX+WorldDx,
                                                cWaterLine+WorldDy,
                                                leftX+WorldDx)
                            end;
                        DrawSpriteClipped(sprGirder,
                                        ox-256,
                                        oy-256,
                                        topY+WorldDy,
                                        rightX+WorldDx,
                                        cWaterLine+WorldDy,
                                        leftX+WorldDx)
                        end
                    else if cBuildMaxDist > 0 then
                        begin
                            DrawCircle(hx, hy, cBuildMaxDist, 3, $FF, 0, 0, $80);
                        end;
                    end;
                amBee: DrawSpriteRotatedF(sprHandBee, hx, hy, (RealTicks div 125) mod 4, sign, aangle);
                amFlamethrower: DrawSpriteRotatedF(sprHandFlamethrower, hx, hy, (RealTicks div 125) mod 4, sign, aangle);
                amLandGun: DrawSpriteRotated(sprHandLandGun, hx, hy, sign, aangle);
                amIceGun: DrawSpriteRotated(sprIceGun, hx, hy, sign, aangle);
                amResurrector: DrawCircle(ox, oy, 98, 4, $F5, $DB, $35, $AA); // I'd rather not like to hardcode 100 here
            end;

            case amt of
                amAirAttack,
                amNapalm,
                amMineStrike,
                amDrillStrike: DrawSpriteRotated(sprHandAirAttack, sx, oy, sign, 0);
                amPickHammer: DrawHedgehog(sx, sy,
                            sign,
                            1,
                            2,
                            0);
                amTeleport,
                amPiano: DrawSpriteRotatedF(sprTeleport, sx, sy, 0, sign, 0);
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
                amBaseballBat, amMinigun:
                    begin
                    HatVisible:= true;
                    DrawHedgehog(sx, sy,
                            sign,
                            0,
                            5,
                            0);
                    end
            else
                DrawHedgehog(sx, sy,
                    sign,
                    0,
                    4,
                    0);

                HatVisible:= true;
            end;

            defaultPos:= false
        end;

    end else // not gstHHDriven
        begin
        // check if hedgehog is sliding/rolling
        if (Gear^.Damage > 0) and (HH^.Effects[heFrozen] = 0)
        and (hwSqr(Gear^.dX) + hwSqr(Gear^.dY) > _0_003) then
            begin
            defaultPos:= false;
                DrawHedgehog(sx, sy,
                    sign,
                    2,
                    1,
                    Gear^.DirAngle);

            // dust effect
            // TODO fix: this gives different results based on framerate
            if (sx mod 8) = 0 then
                begin
                if Gear^.dX.isNegative then
                    tx := hwRound(Gear^.X) + cHHRadius
                else
                    tx := hwRound(Gear^.X) - cHHRadius;
                ty:= hwRound(Gear^.Y) + cHHRadius + 2;
                if ((tx and LAND_WIDTH_MASK) = 0) and
                    ((ty and LAND_HEIGHT_MASK) = 0) and
                        (Land[ty, tx] <> 0) then
                            AddVisualGear(tx - 2 + Random(4), ty - 8, vgtDust);
                end;

            // draw april's fool hat
            if AprilOne and (curhat <> nil) then
                DrawTextureRotatedF(curhat, 1.0, -1.0, 0, sx, sy, 18, sign, 32, 32,
                    sign*Gear^.DirAngle)
            end;


        if ((Gear^.State and gstHHJumping) <> 0) then
            begin
            DrawHedgehog(sx, sy,
                hogLR,
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
                // Simple hat with automatic offset
                if (curhat^.h = 32) and ((curhat^.w = 32) or (curhat^.w = 64)) then
                    begin
                    // Frame
                    tx := (RealTicks div 128 + Gear^.Pos) mod 19;
                    // Hat offset
                    ty := 0;
                    if (tx = 2) or (tx = 7) or (tx = 12) then
                        ty := 1
                    else if tx = 16 then
                        ty := -1;
                    // First frame: No tint
                    DrawTextureF(curhat,
                        HatVisibility,
                        sx,
                        sy - 5 + ty,
                        0,
                        sign,
                        32,
                        32);
                    // Second frame: Clan tint (if present)
                    if (curhat^.w = 64) then
                        begin
                        Tint(HH^.Team^.Clan^.Color shl 8 or $FF);
                        DrawTextureF(curhat,
                            HatVisibility,
                            sx,
                            sy - 5 + ty,
                            1,
                            sign,
                            32,
                            32);
                        untint
                        end
                    end
                else
                    // Classic animated hat (all frames drawn manually)
                    begin
                    DrawTextureF(curhat,
                        HatVisibility,
                        sx,
                        sy - 5,
                        (RealTicks div 128 + Gear^.Pos) mod 19,
                        sign,
                        32,
                        32);
                    // Apply clan tint
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
                        end
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
                    hogLR,
                    32,
                    32);
                if (curhat^.w > 64) or ((curhat^.w = 64) and (curhat^.h = 32)) then
                    begin
                    if ((curhat^.w = 64) and (curhat^.h = 32)) then
                        tx := 1
                    else
                        tx := 32;
                    Tint(HH^.Team^.Clan^.Color shl 8 or $FF);
                    DrawTextureF(curhat,
                        HatVisibility,
                        sx,
                        sy - 5,
                        tx,
                        hogLR,
                        32,
                        32);
                    untint
                    end
                end
        end;

    if (Gear^.State and gstHHDriven) <> 0 then
        begin
        if (CurAmmoGear = nil) then
            begin
                if ((Gear^.State and (gstAttacked or gstAnimation or gstHHJumping)) = 0)
                and (Gear^.Message and (gmLeft or gmRight) = 0) then
                begin
                amt:= CurrentHedgehog^.CurAmmoType;
                    case amt of
                        amBaseballBat: DrawSpritePivotedF(sprHandBaseball,
                            sx + 9 * sign, sy + 2, 0, sign, -8, 1, aangle);
                        amMinigun: DrawSpritePivotedF(sprMinigun,
                            sx + 20 * sign, sy + 4, 0, sign, -18, -2, aangle);
                    end;
                end;
            end
        else
            begin
            aangle:= Gear^.Angle * 180 / cMaxAngle - 90;
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
                        end;
                gtShover: DrawSpritePivotedF(sprHandBaseball,
                    sx + 9 * sign, sy + 2, CurAmmoGear^.Tag, sign, -8, 1, aangle);
                gtMinigun: DrawSpritePivotedF(sprMinigun,
                    sx + 20 * sign, sy + 4, CurAmmoGear^.Tag, sign, -18, -2, aangle);
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

            if (Gear^.State and gstDrowning) = 0 then
                if ((Gear^.State and gstHHThinking) <> 0) and (not CinematicScript) then
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
    // airmine has its own sprite
    if (Gear^.State and gstFrozen <> 0) and (Gear^.Kind <> gtAirMine) then Tint($A0, $A0, $FF, $FF);
    if Gear^.Target.X <> NoPointX then
        if Gear^.AmmoType = amBee then
            DrawSpriteRotatedF(sprTargetBee, Gear^.Target.X + WorldDx, Gear^.Target.Y + WorldDy, 0, 0, (RealTicks shr 3) mod 360)
    else if Gear^.AmmoType = amIceGun then
        DrawTextureRotatedF(SpritesData[sprSnowDust].Texture, 1/(1+(RealTicks shr 8) mod 5), 0, 0, Gear^.Target.X + WorldDx, Gear^.Target.Y + WorldDy, (RealTicks shr 2) mod 8, 1, 22, 22, (RealTicks shr 3) mod 360)
    else
        begin
        if CurrentHedgehog <> nil then
            begin
            if (IsTooDarkToRead(CurrentHedgehog^.Team^.Clan^.Color)) then
                DrawSpriteRotatedF(sprTargetPBackInv, Gear^.Target.X + WorldDx, Gear^.Target.Y + WorldDy, 0, 0, (RealTicks shr 3) mod 360)
            else
                DrawSpriteRotatedF(sprTargetPBack, Gear^.Target.X + WorldDx, Gear^.Target.Y + WorldDy, 0, 0, (RealTicks shr 3) mod 360);
            Tint(CurrentHedgehog^.Team^.Clan^.Color shl 8 or $FF);
            end;
        DrawSpriteRotatedF(sprTargetP, Gear^.Target.X + WorldDx, Gear^.Target.Y + WorldDy, 0, 0, (RealTicks shr 3) mod 360);
        if CurrentHedgehog <> nil then
            untint;
        end;

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

       gtPortal: begin
                 if ((Gear^.Tag and 1) = 0) // still moving?
                 or (Gear^.LinkedGear = nil) or (Gear^.LinkedGear^.LinkedGear <> Gear) // not linked&backlinked?
                 or ((Gear^.LinkedGear^.Tag and 1) = 0) then // linked portal still moving?
                     DrawSpriteRotatedF(sprPortal, x, y, Gear^.Tag, hwSign(Gear^.dX), Gear^.DirAngle)
                 else
                     DrawSpriteRotatedF(sprPortal, x, y, 4 + Gear^.Tag div 2, hwSign(Gear^.dX), Gear^.DirAngle);

                 // Portal ball trace effects
                 if ((Gear^.Tag and 1) = 0) and ((GameTicks mod 4) = 0) and (not isPaused) then
                     begin
                     vg:= AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtDust, 1);
                     if vg <> nil then
                         if Gear^.Tag = 0 then
                             vg^.Tint:= $fab02ab0
                         else if Gear^.Tag = 2 then
                             vg^.Tint:= $364df7b0;
                     end;
                 end;

           gtDrill: if (Gear^.State and gsttmpFlag) <> 0 then
                        DrawSpriteRotated(sprAirDrill, x, y, 0, DxDy2Angle(Gear^.dY, Gear^.dX))
                    else
                        DrawSpriteRotated(sprDrill, x, y, 0, DxDy2Angle(Gear^.dY, Gear^.dX));

        gtHedgehog: DrawHH(Gear, x, y);

           gtShell: DrawSpriteRotated(sprBazookaShell, x, y, 0, DxDy2Angle(Gear^.dY, Gear^.dX));

           gtGrave: begin
                    DrawTextureF(Gear^.Hedgehog^.Team^.GraveTex, 1, x, y, (RealTicks shr 7+Gear^.uid) and 15, 1, 32, 32);
                    if Gear^.Health > 0 then
                        begin
                        Tint($f5, $db, $35, max($40, round($FF * abs(1 - (RealTicks mod 1500) / (750 + Gear^.Health)))));
                        DrawSprite(sprVampiric, x - 24, y - 24, 0);
                        untint
                        end
                    end;
             gtBee: DrawSpriteRotatedF(sprBee, x, y, (RealTicks shr 5) mod 2, 0, DxDy2Angle(Gear^.dY, Gear^.dX));
      gtPickHammer: DrawSprite(sprPHammer, x - 16, y - 50 + LongInt(((GameTicks shr 5) and 1) * 2), 0);
            gtRope: DrawRope(Gear);

            gtMine: begin
                    if (((Gear^.State and gstAttacking) = 0)or((Gear^.Timer and $3FF) < 420)) and (Gear^.Health <> 0) then
                           DrawSpriteRotated(sprMineOff, x, y, 0, Gear^.DirAngle)
                    else if Gear^.Health <> 0 then
                       DrawSpriteRotated(sprMineOn, x, y, 0, Gear^.DirAngle)
                    else DrawSpriteRotated(sprMineDead, x, y, 0, Gear^.DirAngle);
                    end;
         gtAirMine: 
					if (Gear^.State and gstFrozen <> 0) then
                        DrawSprite(sprFrozenAirMine, x-16, y-16, 0)
					else if (Gear^.Tag <> 0) then
                        DrawSprite(sprAirMine, x-16, y-16, 16 + ((RealTicks div 50 + Gear^.Uid) mod 16))
					else if (Gear^.State and gstTmpFlag = 0) then                // mine is inactive
                        begin
						if (Gear^.State and gstTmpFlag = 0) then Tint(150,150,150,255);
                        DrawSprite(sprAirMine, x-16, y-16, 15);
                        untint
                        end
                    else if (Gear^.Hedgehog <> nil) and (Gear^.Hedgehog^.Gear <> nil) then  // mine is chasing a hog
                         DrawSprite(sprAirMine, x-16, y-16, (RealTicks div 25 + Gear^.Uid) mod 16)
                    else if Gear^.State and gstChooseTarget <> 0 then   // mine is seeking for hogs
                         DrawSprite(sprAirMine, x-16, y-16, (RealTicks div 125 + Gear^.Uid) mod 16)
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
                                i:= (RealTicks shr 6) mod 64;
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
                                i:= ((RealTicks shr 6) + 38) mod 64;
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
                                i:= (RealTicks shr 6) mod 70;
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
                        i:= (RealTicks shr 6 + Gear^.uid*3) mod 64;
                        if i > 18 then
                            i:= 0;
                        DrawSprite(sprExplosives, x - 24, y - 24, i)
                        end
                    else if Gear^.State and gsttmpFlag = 0 then
                        DrawSpriteRotatedF(sprExplosivesRoll, x, y + 4, 0, 0, Gear^.DirAngle)
                    else
                        DrawSpriteRotatedF(sprExplosivesRoll, x, y + 4, 1, 0, Gear^.DirAngle)
                    end;
        gtDynamite: begin
                    DrawSprite(sprDynamite, x - 16, y - 25, Gear^.Tag and 1, Gear^.Tag shr 1);
                    if (random(3) = 0) and ((Gear^.State and gstDrowning) = 0) then
                        begin
                        vg:= AddVisualGear(hwRound(Gear^.X)+12-(Gear^.Tag shr 1), hwRound(Gear^.Y)-16, vgtStraightShot);
                        if vg <> nil then
                            with vg^ do
                                begin
                                Tint:= $FFCC00FF;
                                Angle:= random(360);
                                dx:= 0.0005 * (random(200));
                                dy:= 0.0005 * (random(200));
                                if random(2) = 0 then
                                    dx := -dx;
                                if random(2) = 0 then
                                    dy := -dy;
                                FrameTicks:= 100+random(300);
                                Scale:= 0.1+1/(random(3)+3);
                                State:= ord(sprStar)
                                end
                        end;

                    end;
     gtClusterBomb: DrawSpriteRotated(sprClusterBomb, x, y, 0, Gear^.DirAngle);
         gtCluster: DrawSprite(sprClusterParticle, x - 8, y - 8, 0);
           gtFlame: if Gear^.Tag and 1 = 0 then
                         DrawTextureF(SpritesData[sprFlame].Texture, 2 / (Gear^.Tag mod 3 + 2), x, y, (RealTicks shr 7 + LongWord(Gear^.Tag)) mod 8, 1, 16, 16)
                    else DrawTextureF(SpritesData[sprFlame].Texture, 2 / (Gear^.Tag mod 3 + 2), x, y, (RealTicks shr 7 + LongWord(Gear^.Tag)) mod 8, -1, 16, 16);
       gtParachute: begin
                    DrawSprite(sprParachute, x - 24, y - 48, 0);
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
        gtSwitcher: begin
                    setTintAdd(true);
                    Tint(Gear^.Hedgehog^.Team^.Clan^.Color shl 8 or $FF);
                    DrawSprite(sprSwitch, x - 16, y - 56, (RealTicks shr 6) mod 12);
                    untint;
                    setTintAdd(false);
                    end;
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
                        if Gear^.FlightTime > 0 then
                            untint;
                        end;
          gtTardis: if Gear^.Pos <> 4 then
                        begin
                        if Gear^.Pos = 2 then
                            Tint(Gear^.Hedgehog^.Team^.Clan^.Color shl 8 or $FF)
                        else
                            Tint(Gear^.Hedgehog^.Team^.Clan^.Color shl 8 or max($00, round(Gear^.Power * (1-abs(0.5 - (GameTicks mod 2000) / 2000)))));
                        DrawSprite(sprTardis, x-25, y-64,0);
                        if Gear^.Pos = 2 then
                            untint
                        else
                            Tint($FF,$FF,$FF,max($00, round(Gear^.Power * (1-abs(0.5 - (GameTicks mod 2000) / 2000)))));
                        DrawSprite(sprTardis, x-25, y-64,1);
                        if Gear^.Pos <> 2 then
                            untint
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
                                    DrawLineWrapped(hwRound(HHGear^.X), hwRound(HHGear^.Y), Gear^.Target.X, Gear^.Target.Y, 4.0, hwSign(HHGear^.dX) < 0, Gear^.FlightTime, i, i, $FF, $40);
                                    end
                                else
                                    begin
                                    DrawLineWrapped(hwRound(HHGear^.X), hwRound(HHGear^.Y), hwRound(Gear^.X), hwRound(Gear^.Y), 4.0, hwSign(HHGear^.dX) < 0, Gear^.FlightTime, i, i, $FF, $40);
                                    end;
                                end
                          end
                      end;
            gtCreeper: if (Gear^.Hedgehog <> nil) and (Gear^.Hedgehog^.Gear <> nil) then
					     DrawSpriteRotatedF(sprCreeper, x, y, 1, hwRound(SignAs(_1,Gear^.Hedgehog^.Gear^.X-Gear^.X)), 0)
					else DrawSpriteRotatedF(sprCreeper, x, y, 1, hwRound(SignAs(_1,Gear^.dX)), 0);

            gtGenericFaller: begin
                             // DEBUG: draw gtGenericFaller
                             if Gear^.Tag <> 0 then
                                 DrawCircle(x, y, max(3, Gear^.Radius), 3, $FF, $00, $00, $FF)
                             else
                                 DrawCircle(x, y, max(3, Gear^.Radius), 3, $80, $FF, $80, $8F);
                             end;
         end;
    if Gear^.State and gstFrozen <> 0 then untint
end;

procedure RenderGearTimer(Gear: PGear; x, y: LongInt);
begin
if Gear^.RenderTimer and (Gear^.Tex <> nil) and (isShowGearInfo or (not (Gear^.Kind in [gtMine, gtSMine, gtAirMine]))) then
    DrawTextureCentered(x + 8, y + 8, Gear^.Tex);
end;

procedure RenderGearHealth(Gear: PGear; x, y: LongInt);
begin
if isShowGearInfo and (Gear^.RenderHealth) and (Gear^.Tex <> nil) then
    begin
    if (Gear^.Kind = gtCase) and ((Gear^.Pos and posCaseHealth) <> 0) then
        DrawTextureCentered(x, y - 38, Gear^.Tex);
    if (Gear^.Kind = gtExplosives) then
        DrawTextureCentered(x, y - 38, Gear^.Tex);
    end;
end;

end.
