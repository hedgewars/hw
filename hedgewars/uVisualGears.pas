(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2008 Andrey Korotaev <unC0Rr@gmail.com>
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

{$INCLUDE "options.inc"}

unit uVisualGears;
interface
uses uConsts, uFloat, GLunit, uTypes;

procedure initModule;
procedure freeModule;

function  AddVisualGear(X, Y: LongInt; Kind: TVisualGearType; State: LongWord = 0; Critical: Boolean = false): PVisualGear;
procedure ProcessVisualGears(Steps: Longword);
procedure KickFlakes(Radius, X, Y: LongInt);
procedure DrawVisualGears(Layer: LongWord);
procedure DeleteVisualGear(Gear: PVisualGear);
function  VisualGearByUID(uid : Longword) : PVisualGear;
procedure AddClouds;
procedure AddDamageTag(X, Y, Damage, Color: LongWord);

implementation
uses uSound, uMobile, uVariables, uTextures, uRender, Math, uRenderUtils;

const cExplFrameTicks = 110;

{$INCLUDE "VGSHandlers.inc"}

procedure AddDamageTag(X, Y, Damage, Color: LongWord);
var s: shortstring;
    Gear: PVisualGear;
begin
if cAltDamage then
    begin
    Gear:= AddVisualGear(X, Y, vgtSmallDamageTag);
    if Gear <> nil then
        with Gear^ do
            begin
            str(Damage, s);
            Tex:= RenderStringTex(s, Color, fntSmall);
            end
    end
end;


// ==================================================================

// ==================================================================
const doStepHandlers: array[TVisualGearType] of TVGearStepProcedure =
        (
            @doStepFlake,
            @doStepCloud,
            @doStepExpl,
            @doStepExpl,
            @doStepFire,
            @doStepSmallDamage,
            @doStepTeamHealthSorter,
            @doStepSpeechBubble,
            @doStepBubble,
            @doStepSteam,
            @doStepAmmo,
            @doStepSmoke,
            @doStepSmoke,
            @doStepHealth,
            @doStepShell,
            @doStepDust,
            @doStepSplash,
            @doStepDroplet,
            @doStepSmokeRing,
            @doStepBeeTrace,
            @doStepEgg,
            @doStepFeather,
            @doStepHealthTag,
            @doStepSmokeTrace,
            @doStepSmokeTrace,
            @doStepExplosion,
            @doStepBigExplosion,
            @doStepChunk,
            @doStepNote,
            @doStepLineTrail,
            @doStepBulletHit,
            @doStepCircle
        );

function  AddVisualGear(X, Y: LongInt; Kind: TVisualGearType; State: LongWord = 0; Critical: Boolean = false): PVisualGear;
const VGCounter: Longword = 0;
var gear: PVisualGear;
    t: Longword;
    sp: real;
begin
if (GameType = gmtSave) or (fastUntilLag and (GameType = gmtNet)) then // we are scrolling now
    if (Kind <> vgtCloud) and not Critical then
        begin
        AddVisualGear:= nil;
        exit
        end;

if ((cReducedQuality and rqFancyBoom) <> 0) and
   not Critical and
   not (Kind in
   [vgtTeamHealthSorter,
    vgtSmallDamageTag,
    vgtSpeechBubble,
    vgtHealthTag,
    vgtExplosion,
    vgtSmokeTrace,
    vgtEvilTrace,
    vgtNote]) then
    begin
      AddVisualGear:= nil;
      exit
    end;

inc(VGCounter);
New(gear);
FillChar(gear^, sizeof(TVisualGear), 0);
gear^.X:= real(X);
gear^.Y:= real(Y);
gear^.Kind := Kind;
gear^.doStep:= doStepHandlers[Kind];
gear^.State:= 0;
gear^.Tint:= $FFFFFFFF;
gear^.uid:= VGCounter;

with gear^ do
    case Kind of
    vgtFlake: begin
                Timer:= 0;
                tdX:= 0;
                tdY:= 0;
                FrameTicks:= random(vobFrameTicks);
                Frame:= random(vobFramesCount);
                Angle:= random * 360;
                dx:= 0.0000038654705 * random(10000);
                dy:= 0.000003506096 * random(7000);
                if random(2) = 0 then dx := -dx;
                dAngle:= (random(2) * 2 - 1) * (1 + random) * vobVelocity / 1000
                end;
    vgtCloud: begin
                Frame:= random(4);
                dx:= 0.5 + 0.1 * random(5); // how much the cloud will be affected by wind
                timer:= random(4096);
                end;
    vgtExplPart,
    vgtExplPart2: begin
                t:= random(1024);
                sp:= 0.001 * (random(95) + 70);
                dx:= AngleSin(t).QWordValue/4294967296 * sp;
                dy:= AngleCos(t).QWordValue/4294967296 * sp;
                if random(2) = 0 then dx := -dx;
                if random(2) = 0 then dy := -dy;
                Frame:= 7 - random(3);
                FrameTicks:= cExplFrameTicks
                end;
        vgtFire: begin
                t:= random(1024);
                sp:= 0.001 * (random(85) + 95);
                dx:= AngleSin(t).QWordValue/4294967296 * sp;
                dy:= AngleCos(t).QWordValue/4294967296 * sp;
                if random(2) = 0 then dx := -dx;
                if random(2) = 0 then dy := -dy;
                FrameTicks:= 650 + random(250);
                Frame:= random(8)
                end;
         vgtEgg: begin
                t:= random(1024);
                sp:= 0.001 * (random(85) + 95);
                dx:= AngleSin(t).QWordValue/4294967296 * sp;
                dy:= AngleCos(t).QWordValue/4294967296 * sp;
                if random(2) = 0 then dx := -dx;
                if random(2) = 0 then dy := -dy;
                FrameTicks:= 650 + random(250);
                Frame:= 1
                end;
        vgtShell: FrameTicks:= 500;
    vgtSmallDamageTag: begin
                gear^.FrameTicks:= 1100
                end;
    vgtBubble: begin
                dx:= 0.0000038654705 * random(10000);
                dy:= 0;
                if random(2) = 0 then dx := -dx;
                FrameTicks:= 250 + random(1751);
                Frame:= random(5)
                end;
    vgtSteam: begin
                dx:= 0.0000038654705 * random(10000);
                dy:= 0.001 * (random(85) + 95);
                if random(2) = 0 then dx := -dx;
                Frame:= 7 - random(3);
                FrameTicks:= cExplFrameTicks * 2;
                end;
    vgtAmmo: begin
                alpha:= 1.0;
                scale:= 1.0
                end;
  vgtSmokeWhite,
  vgtSmoke: begin
                dx:= 0.0002 * (random(45) + 10);
                dy:= 0.0002 * (random(45) + 10);
                if random(2) = 0 then dx := -dx;
                Frame:= 7 - random(2);
                FrameTicks:= cExplFrameTicks * 2;
                end;
    vgtHealth: begin
                dx:= 0.001 * random(45);
                dy:= 0.001 * (random(20) + 25);
                if random(2) = 0 then dx := -dx;
                Frame:= 0;
                FrameTicks:= random(750) + 1250;
                end;
  vgtDust: begin
                dx:= 0.005 * (random(15) + 10);
                dy:= 0.001 * (random(40) + 20);
                if random(2) = 0 then dx := -dx;
                Frame:= 7 - random(2);
                FrameTicks:= random(20) + 15;
                end;
  vgtSplash: begin
                dx:= 0;
                dy:= 0;
                FrameTicks:= 740;
                Frame:= 19;
                end;
    vgtDroplet: begin
                dx:= 0.001 * (random(75) + 15);
                dy:= -0.001 * (random(80) + 120);
                if random(2) = 0 then dx := -dx;
                FrameTicks:= 250 + random(1751);
                Frame:= random(3)
                end;
   vgtBeeTrace: begin
                FrameTicks:= 1000;
                Frame:= random(16);
                end;
    vgtSmokeRing: begin
                dx:= 0;
                dy:= 0;
                FrameTicks:= 600;
                Timer:= 0;
                Frame:= 0;
                scale:= 0.6;
                alpha:= 1;
                angle:= random(360);
                end;
     vgtFeather: begin
                t:= random(1024);
                sp:= 0.001 * (random(85) + 95);
                dx:= AngleSin(t).QWordValue/4294967296 * sp;
                dy:= AngleCos(t).QWordValue/4294967296 * sp;
                if random(2) = 0 then dx := -dx;
                if random(2) = 0 then dy := -dy;
                FrameTicks:= 650 + random(250);
                Frame:= 1
                end;
  vgtHealthTag: begin
                gear^.Timer:= 1500;
                //gear^.Z:= 2002;
                end;
  vgtSmokeTrace,
  vgtEvilTrace: begin
                gear^.X:= gear^.X - 16;
                gear^.Y:= gear^.Y - 16;
                gear^.State:= 8;
                //gear^.Z:= cSmokeZ
                end;
vgtBigExplosion: begin
                gear^.Angle:= random(360);
                end;
      vgtChunk: begin
                gear^.Frame:= random(4);
                t:= random(1024);
                sp:= 0.001 * (random(85) + 47);
                dx:= AngleSin(t).QWordValue/4294967296 * sp;
                dy:= AngleCos(t).QWordValue/4294967296 * sp * -2;
                if random(2) = 0 then dx := -dx;
                end;
      vgtNote: begin
                dx:= 0.005 * (random(15) + 10);
                dy:= -0.001 * (random(40) + 20);
                if random(2) = 0 then dx := -dx;
                Frame:= random(4);
                FrameTicks:= random(2000) + 1500;
                end;
  vgtBulletHit: begin
                dx:= 0;
                dy:= 0;
                FrameTicks:= 350;
                Frame:= 7;
                Angle := 0;
                end;
        end;

if State <> 0 then gear^.State:= State;

if VisualGearsList <> nil then
    begin
    VisualGearsList^.PrevGear:= gear;
    gear^.NextGear:= VisualGearsList
    end;
VisualGearsList:= gear;

AddVisualGear:= gear;
end;

procedure DeleteVisualGear(Gear: PVisualGear);
begin
    if Gear^.Tex <> nil then
        FreeTexture(Gear^.Tex);
    Gear^.Tex:= nil;

    if Gear^.NextGear <> nil then Gear^.NextGear^.PrevGear:= Gear^.PrevGear;
    if Gear^.PrevGear <> nil then Gear^.PrevGear^.NextGear:= Gear^.NextGear
    else VisualGearsList:= Gear^.NextGear;

    if lastVisualGearByUID = Gear then lastVisualGearByUID:= nil;

    Dispose(Gear);
end;

procedure ProcessVisualGears(Steps: Longword);
var Gear, t: PVisualGear;
begin
if Steps = 0 then exit;

t:= VisualGearsList;
while t <> nil do
      begin
      Gear:= t;
      t:= Gear^.NextGear;
      Gear^.doStep(Gear, Steps)
      end
end;

procedure KickFlakes(Radius, X, Y: LongInt);
var Gear, t: PVisualGear;
    dmg: LongInt;
begin
if (vobCount = 0) or (vobCount > 200) then exit;
t:= VisualGearsList;
while t <> nil do
      begin
      Gear:= t;
      if Gear^.Kind = vgtFlake then
          begin
          // Damage calc from doMakeExplosion
          dmg:= Min(101, Radius + cHHRadius div 2 - LongInt(abs(round(Gear^.X) - X) + abs(round(Gear^.Y) - Y)) div 5);
          if dmg > 1 then
              begin
              Gear^.tdX:= 0.02 * dmg + 0.01;
              if Gear^.X - X < 0 then Gear^.tdX := -Gear^.tdX;
              Gear^.tdY:= 0.02 * dmg + 0.01;
              if Gear^.Y - Y < 0 then Gear^.tdY := -Gear^.tdY;
              Gear^.Timer:= 200
              end
          end;
      t:= Gear^.NextGear
      end
end;

procedure DrawVisualGears(Layer: LongWord);
var Gear: PVisualGear;
    tinted: boolean;
    tmp: real;
begin
Gear:= VisualGearsList;
case Layer of
    0: while Gear <> nil do
        begin
        if Gear^.Tint <> $FFFFFFFF then Tint(Gear^.Tint);
        case Gear^.Kind of
            vgtFlake: if vobVelocity = 0 then
                        if SuddenDeathDmg then
                            DrawSprite(sprSDFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame)
                        else
                            DrawSprite(sprFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame)
                      else
                        if SuddenDeathDmg then
                            DrawRotatedF(sprSDFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, Gear^.Angle)
                        else
                            DrawRotatedF(sprFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, Gear^.Angle);
            vgtCloud: if SuddenDeathDmg then
                          DrawSprite(sprSDCloud, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame)
                      else
                          DrawSprite(sprCloud, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame);
            end;
        if Gear^.Tint <> $FFFFFFFF then Tint($FF,$FF,$FF,$FF);
        Gear:= Gear^.NextGear
        end;
    1: while Gear <> nil do
        begin
        tinted:= false;
        if Gear^.Tint <> $FFFFFFFF then Tint(Gear^.Tint);
        case Gear^.Kind of
            vgtSmokeTrace: if Gear^.State < 8 then DrawSprite(sprSmokeTrace, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.State);
            vgtEvilTrace: if Gear^.State < 8 then DrawSprite(sprEvilTrace, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.State);
            vgtLineTrail: DrawLine(Gear^.X, Gear^.Y, Gear^.dX, Gear^.dY, 1.0, $FF, min(Gear^.Timer, $C0), min(Gear^.Timer, $80), min(Gear^.Timer, $FF));
            vgtSpeechBubble: if (Gear^.Tex <> nil) and (((Gear^.State = 0) and (Gear^.Hedgehog^.Team <> CurrentTeam)) or (Gear^.State = 1)) then 
                    begin
                    tinted:= true;
                    Tint($FF, $FF, $FF,  $66);
                    DrawCentered(round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Tex)
                    end
        end;
            if (cReducedQuality and rqFancyBoom) = 0 then
                case Gear^.Kind of
                    vgtSmoke: DrawSprite(sprSmoke, round(Gear^.X) + WorldDx - 11, round(Gear^.Y) + WorldDy - 11, 7 - Gear^.Frame);
                    vgtSmokeWhite: DrawSprite(sprSmokeWhite, round(Gear^.X) + WorldDx - 11, round(Gear^.Y) + WorldDy - 11, 7 - Gear^.Frame);
                    vgtDust: DrawSprite(sprDust, round(Gear^.X) + WorldDx - 11, round(Gear^.Y) + WorldDy - 11, 7 - Gear^.Frame);
                    vgtFeather: begin
                            if Gear^.FrameTicks < 255 then
                                begin
                                Tint($FF, $FF, $FF, Gear^.FrameTicks);
                                tinted:= true
                                end;
                            DrawRotatedF(sprFeather, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Frame, 1, Gear^.Angle);
                            end;
                 end;
        if (Gear^.Tint <> $FFFFFFFF) or tinted then Tint($FF,$FF,$FF,$FF);
        Gear:= Gear^.NextGear
        end;
    2: while Gear <> nil do
        begin
        tinted:= false;
        if Gear^.Tint <> $FFFFFFFF then Tint(Gear^.Tint);
        case Gear^.Kind of
            vgtExplosion: DrawSprite(sprExplosion50, round(Gear^.X) - 32 + WorldDx, round(Gear^.Y) - 32 + WorldDy, Gear^.State);
            vgtBigExplosion: begin
                             tinted:= true;
                             Tint($FF, $FF, $FF, round($FF * (1 - power(Gear^.Timer / 250, 4))));
                             DrawRotatedTextureF(SpritesData[sprBigExplosion].Texture, 0.85 * (-power(2, -10 * Int(Gear^.Timer)/250) + 1) + 0.4, 0, 0, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, 0, 1, 385, 385, Gear^.Angle);
                             end;
            end;
        if (cReducedQuality and rqFancyBoom) = 0 then
            case Gear^.Kind of
                vgtExplPart: DrawSprite(sprExplPart, round(Gear^.X) + WorldDx - 16, round(Gear^.Y) + WorldDy - 16, 7 - Gear^.Frame);
                vgtExplPart2: DrawSprite(sprExplPart2, round(Gear^.X) + WorldDx - 16, round(Gear^.Y) + WorldDy - 16, 7 - Gear^.Frame);
                vgtFire: if (Gear^.State and gstTmpFlag) = 0 then
                             DrawSprite(sprFlame, round(Gear^.X) + WorldDx - 8, round(Gear^.Y) + WorldDy, (RealTicks shr 6 + Gear^.Frame) mod 8)
                         else
                             DrawTextureF(SpritesData[sprFlame].Texture, Gear^.FrameTicks / 900, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, (RealTicks shr 7 + Gear^.Frame) mod 8, 1, 16, 16);
                vgtBubble: DrawSprite(sprBubbles, round(Gear^.X) + WorldDx - 8, round(Gear^.Y) + WorldDy - 8, Gear^.Frame);//(RealTicks div 64 + Gear^.Frame) mod 8);
                vgtSteam: DrawSprite(sprSmokeWhite, round(Gear^.X) + WorldDx - 11, round(Gear^.Y) + WorldDy - 11, 7 - Gear^.Frame);
                vgtAmmo: begin
                        tinted:= true;
                        Tint($FF, $FF, $FF, round(Gear^.alpha * $FF));
                        DrawTextureF(ropeIconTex, Gear^.scale, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, 0, 1, 32, 32);
                        DrawTextureF(SpritesData[sprAMAmmos].Texture, Gear^.scale * 0.90, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Frame - 1, 1, 32, 32);
                        end;
                vgtHealth:  begin
                            tinted:= true;
                            case Gear^.Frame div 10 of
                                0:Tint(0, $FF, 0, round(Gear^.FrameTicks * $FF / 1000));
                                1:Tint($FF, 0, 0, round(Gear^.FrameTicks * $FF / 1000));
                            end;
                            DrawSprite(sprHealth, round(Gear^.X) + WorldDx - 8, round(Gear^.Y) + WorldDy - 8, 0);
                            end;
                vgtShell: begin
                            if Gear^.FrameTicks < $FF then
                                begin
                                Tint($FF, $FF, $FF, Gear^.FrameTicks);
                                tinted:= true
                                end;
                            DrawRotatedF(sprShell, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Frame, 1, Gear^.Angle);
                            end;
                  vgtEgg: begin
                            if Gear^.FrameTicks < $FF then
                                begin
                                Tint($FF, $FF, $FF, Gear^.FrameTicks);
                                tinted:= true
                                end;
                            DrawRotatedF(sprEgg, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Frame, 1, Gear^.Angle);
                            end;
                vgtSplash: DrawSprite(sprSplash, round(Gear^.X) + WorldDx - 40, round(Gear^.Y) + WorldDy - 58, 19 - (Gear^.FrameTicks div 37));
                vgtDroplet: DrawSprite(sprDroplet, round(Gear^.X) + WorldDx - 8, round(Gear^.Y) + WorldDy - 8, Gear^.Frame);
               vgtBeeTrace: begin
                            if Gear^.FrameTicks < $FF then
                                Tint($FF, $FF, $FF, Gear^.FrameTicks div 2)
                            else
                                Tint($FF, $FF, $FF, $80);
                            tinted:= true;
                            DrawRotatedF(sprBeeTrace, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Frame, 1, (RealTicks shr 4) mod cMaxAngle);
                            end;
                vgtSmokeRing: begin
                            tinted:= true;
                            Tint($FF, $FF, $FF, round(Gear^.alpha * $FF));
                            DrawRotatedTextureF(SpritesData[sprSmokeRing].Texture, Gear^.scale, 0, 0, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, 0, 1, 200, 200, Gear^.Angle);
                            end;
                vgtChunk: DrawRotatedF(sprChunk, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Frame, 1, Gear^.Angle);
                 vgtNote: DrawRotatedF(sprNote, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Frame, 1, Gear^.Angle);
                vgtBulletHit: DrawRotatedF(sprBulletHit, round(Gear^.X) + WorldDx - 0, round(Gear^.Y) + WorldDy - 0, 7 - (Gear^.FrameTicks div 50), 1, Gear^.Angle);
            end;
        case Gear^.Kind of
            vgtSmallDamageTag: DrawCentered(round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Tex);
            vgtSpeechBubble: if (Gear^.Tex <> nil) and (((Gear^.State = 0) and (Gear^.Hedgehog^.Team = CurrentTeam)) or (Gear^.State = 2)) then DrawCentered(round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Tex);
            vgtHealthTag: if Gear^.Tex <> nil then DrawCentered(round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Tex);
            vgtCircle:  if gear^.Angle = 1 then 
                            begin
                            tmp:= Gear^.State / 100;
                            DrawTexture(round(Gear^.X-24*tmp) + WorldDx, round(Gear^.Y-24*tmp) + WorldDy, SpritesData[sprVampiric].Texture, tmp)
                            end
                        else DrawCircle(round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.State, Gear^.Timer);
        end;
        if (Gear^.Tint <> $FFFFFFFF) or tinted then Tint($FF,$FF,$FF,$FF);
        Gear:= Gear^.NextGear
        end
    end;
end;

function  VisualGearByUID(uid : Longword) : PVisualGear;
var vg: PVisualGear;
begin
VisualGearByUID:= nil;
if uid = 0 then exit;
if (lastVisualGearByUID <> nil) and (lastVisualGearByUID^.uid = uid) then
    begin
    VisualGearByUID:= lastVisualGearByUID;
    exit
    end;
vg:= VisualGearsList;
while vg <> nil do
    begin
    if vg^.uid = uid then
        begin
        lastVisualGearByUID:= vg;
        VisualGearByUID:= vg;
        exit
        end;
    vg:= vg^.NextGear
    end
end;

procedure AddClouds;
var i: LongInt;
begin
for i:= 0 to cCloudsNumber - 1 do
    AddVisualGear(cLeftScreenBorder + i * cScreenSpace div (cCloudsNumber + 1), LAND_HEIGHT-1184, vgtCloud)
end;

procedure initModule;
begin
    VisualGearsList:= nil;
end;

procedure freeModule;
begin
    while VisualGearsList <> nil do DeleteVisualGear(VisualGearsList);
end;

end.
