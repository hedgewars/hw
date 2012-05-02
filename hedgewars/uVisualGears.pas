(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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
(*
 * This unit defines the behavior and the appearance of visual gears.
 *
 * Visual gears are "things"/"objects" in the game that do not need to be
 * perfectly synchronized over all clients since their effect is only
 * of visual nature.
 *
 * E.g.: background flakes, visual effects: explosion, smoke trails, etc.
 *)
interface
uses uConsts, uFloat, GLunit, uTypes, uWorld;

procedure initModule;
procedure freeModule;

function  AddVisualGear(X, Y: LongInt; Kind: TVisualGearType): PVisualGear; inline;
function  AddVisualGear(X, Y: LongInt; Kind: TVisualGearType; State: LongWord): PVisualGear; inline;
function  AddVisualGear(X, Y: LongInt; Kind: TVisualGearType; State: LongWord; Critical: Boolean): PVisualGear;

procedure ProcessVisualGears(Steps: Longword);
procedure DrawVisualGears(Layer: LongWord);
procedure DeleteVisualGear(Gear: PVisualGear);
function  VisualGearByUID(uid : Longword) : PVisualGear;

procedure AddClouds;
procedure AddFlakes;
procedure AddDamageTag(X, Y, Damage, Color: LongWord);

procedure ChangeToSDClouds;
procedure ChangeToSDFlakes;

procedure KickFlakes(Radius, X, Y: LongInt);

implementation
uses uSound, uMobile, uVariables, uTextures, uRender, Math, uRenderUtils, uStore, uUtils;

const cExplFrameTicks = 110;

// For better maintainability the step handlers of visual gears are stored
// in a separate file.
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
            @doStepCircle,
            @doStepSmoothWindBar,
            @doStepStraightShot
        );

function AddVisualGear(X, Y: LongInt; Kind: TVisualGearType): PVisualGear; inline;
begin
    AddVisualGear:= AddVisualGear(X, Y, Kind, 0, false);
end;

function  AddVisualGear(X, Y: LongInt; Kind: TVisualGearType; State: LongWord): PVisualGear; inline;
begin
    AddVisualGear:= AddVisualGear(X, Y, Kind, State, false);
end;

function AddVisualGear(X, Y: LongInt; Kind: TVisualGearType; State: LongWord; Critical: Boolean): PVisualGear;
var gear: PVisualGear;
    t: Longword;
    sp: real;
begin
AddVisualGear:= nil;
if ((GameType = gmtSave) or (fastUntilLag and (GameType = gmtNet))) and // we are scrolling now
   ((Kind <> vgtCloud) and (not Critical)) then
       exit;

if ((cReducedQuality and rqAntiBoom) <> 0) and
   (not Critical) and
   (not (Kind in
   [vgtTeamHealthSorter,
    vgtSmallDamageTag,
    vgtSpeechBubble,
    vgtHealthTag,
    vgtExplosion,
    vgtSmokeTrace,
    vgtEvilTrace,
    vgtNote,
    vgtSmoothWindBar])) then
    
        exit;

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
gear^.Layer:= 0;

with gear^ do
    case Kind of
    vgtFlake:
                begin
                Timer:= 0;
                tdX:= 0;
                tdY:= 0;
                Scale:= 1.0;
                if SuddenDeathDmg then
                    begin
                    FrameTicks:= random(vobSDFrameTicks);
                    Frame:= random(vobSDFramesCount);
                    end
                else
                    begin
                    FrameTicks:= random(vobFrameTicks);
                    Frame:= random(vobFramesCount);
                    end;
                Angle:= random * 360;
                dx:= 0.0000038654705 * random(10000);
                dy:= 0.000003506096 * random(7000);
                if random(2) = 0 then
                    dx := -dx;
                if SuddenDeathDmg then
                    dAngle:= (random(2) * 2 - 1) * (1 + random) * vobSDVelocity / 1000
                else
                    dAngle:= (random(2) * 2 - 1) * (1 + random) * vobVelocity / 1000
                end;
    vgtCloud:
                begin
                Frame:= random(4);
                dx:= 0.5 + 0.1 * random(5); // how much the cloud will be affected by wind
                timer:= random(4096);
                Scale:= 1.0
                end;
    vgtExplPart,
    vgtExplPart2:
                begin
                t:= random(1024);
                sp:= 0.001 * (random(95) + 70);
                dx:= hwFloat2Float(AngleSin(t)) * sp;
                dy:= hwFloat2Float(AngleCos(t)) * sp;
                if random(2) = 0 then
                    dx := -dx;
                if random(2) = 0 then
                    dy := -dy;
                Frame:= 7 - random(3);
                FrameTicks:= cExplFrameTicks
                end;
        vgtFire:
                begin
                t:= random(1024);
                sp:= 0.001 * (random(85) + 95);
                dx:= hwFloat2Float(AngleSin(t)) * sp;
                dy:= hwFloat2Float(AngleCos(t)) * sp;
                if random(2) = 0 then
                    dx := -dx;
                if random(2) = 0 then
                    dy := -dy;
                FrameTicks:= 650 + random(250);
                Frame:= random(8)
                end;
         vgtEgg:
                begin
                t:= random(1024);
                sp:= 0.001 * (random(85) + 95);
                dx:= hwFloat2Float(AngleSin(t)) * sp;
                dy:= hwFloat2Float(AngleCos(t)) * sp;
                if random(2) = 0 then
                    dx := -dx;
                if random(2) = 0 then
                    dy := -dy;
                FrameTicks:= 650 + random(250);
                Frame:= 1
                end;
        vgtShell: FrameTicks:= 500;
    vgtSmallDamageTag:
                begin
                gear^.FrameTicks:= 1100
                end;
    vgtBubble:
                begin
                dx:= 0.0000038654705 * random(10000);
                dy:= 0;
                if random(2) = 0 then
                    dx := -dx;
                FrameTicks:= 250 + random(1751);
                Frame:= random(5)
                end;
    vgtSteam:
                begin
                dx:= 0.0000038654705 * random(10000);
                dy:= 0.001 * (random(85) + 95);
                if random(2) = 0 then
                    dx := -dx;
                Frame:= 7 - random(3);
                FrameTicks:= cExplFrameTicks * 2;
                end;
    vgtAmmo:
                begin
                alpha:= 1.0;
                scale:= 1.0
                end;
  vgtSmokeWhite,
  vgtSmoke:
                begin
                Scale:= 1.0;
                dx:= 0.0002 * (random(45) + 10);
                dy:= 0.0002 * (random(45) + 10);
                if random(2) = 0 then
                    dx := -dx;
                Frame:= 7 - random(2);
                FrameTicks:= cExplFrameTicks * 2;
                end;
  vgtDust:
                begin
                dx:= 0.005 * (random(15) + 10);
                dy:= 0.001 * (random(40) + 20);
                if random(2) = 0 then
                    dx := -dx;
                Frame:= 7 - random(2);
                FrameTicks:= random(20) + 15;
                end;
  vgtSplash:
                begin
                dx:= 0;
                dy:= 0;
                FrameTicks:= 740;
                Frame:= 19;
                end;
    vgtDroplet:
                begin
                dx:= 0.001 * (random(75) + 15);
                dy:= -0.001 * (random(80) + 120);
                if random(2) = 0 then
                    dx := -dx;
                FrameTicks:= 250 + random(1751);
                Frame:= random(3)
                end;
   vgtBeeTrace:
                begin
                FrameTicks:= 1000;
                Frame:= random(16);
                end;
    vgtSmokeRing:
                begin
                dx:= 0;
                dy:= 0;
                FrameTicks:= 600;
                Timer:= 0;
                Frame:= 0;
                scale:= 0.6;
                alpha:= 1;
                angle:= random(360);
                end;
     vgtFeather:
                begin
                t:= random(1024);
                sp:= 0.001 * (random(85) + 95);
                dx:= hwFloat2Float(AngleSin(t)) * sp;
                dy:= hwFloat2Float(AngleCos(t)) * sp;
                if random(2) = 0 then
                    dx := -dx;
                if random(2) = 0 then
                    dy := -dy;
                FrameTicks:= 650 + random(250);
                Frame:= 1
                end;
  vgtHealthTag:
                begin
                Frame:= 0;
                Timer:= 1500;
                dY:= -0.08;
                dX:= 0;
                //gear^.Z:= 2002;
                end;
  vgtSmokeTrace,
  vgtEvilTrace:
                begin
                gear^.X:= gear^.X - 16;
                gear^.Y:= gear^.Y - 16;
                gear^.State:= 8;
                //gear^.Z:= cSmokeZ
                end;
vgtBigExplosion:
                begin
                gear^.Angle:= random(360);
                end;
      vgtChunk:
                begin
                gear^.Frame:= random(4);
                t:= random(1024);
                sp:= 0.001 * (random(85) + 47);
                dx:= hwFloat2Float(AngleSin(t)) * sp;
                dy:= hwFloat2Float(AngleCos(t)) * sp * -2;
                if random(2) = 0 then
                    dx := -dx;
                end;
      vgtNote: 
                begin
                dx:= 0.005 * (random(15) + 10);
                dy:= -0.001 * (random(40) + 20);
                if random(2) = 0 then
                    dx := -dx;
                Frame:= random(4);
                FrameTicks:= random(2000) + 1500;
                end;
  vgtBulletHit:
                begin
                dx:= 0;
                dy:= 0;
                FrameTicks:= 350;
                Frame:= 7;
                Angle:= 0;
                end;
vgtSmoothWindBar: 
                begin
                Angle:= hwFloat2Float(cMaxWindSpeed)*2 / 1440; // seems rate below is supposed to change wind bar at 1px per 10ms. Max time, 1440ms. This tries to match the rate of change
                Tag:= hwRound(cWindSpeed * 72 / cMaxWindSpeed);
                end;
 vgtStraightShot:
                begin
                Angle:= 0;
                Scale:= 1.0;
                dx:= 0.001 * random(45);
                dy:= 0.001 * (random(20) + 25);
                State:= ord(sprHealth);
                if random(2) = 0 then
                    dx := -dx;
                Frame:= 0;
                FrameTicks:= random(750) + 1250;
                State:= ord(sprSnowDust);
                end;
        end;

if State <> 0 then
    gear^.State:= State;

case Gear^.Kind of
    vgtFlake: if cFlattenFlakes then
        gear^.Layer:= 0
              else if random(3) = 0 then 
                  begin
                  gear^.Scale:= 0.5;
                  gear^.Layer:= 0   // 33% - far back
                  end
              else if random(3) = 0 then
                  begin
                  gear^.Scale:= 0.8;
                  gear^.Layer:= 4   // 22% - mid-distance
                  end
              else if random(3) <> 0 then
                  gear^.Layer:= 5  // 30% - just behind land
              else if random(2) = 0 then
                  gear^.Layer:= 6   // 7% - just in front of land
              else
                  begin
                  gear^.Scale:= 1.5;
                  gear^.Layer:= 2;  // 7% - close up
                  end;

    vgtCloud: if cFlattenClouds then gear^.Layer:= 5
              else if random(3) = 0 then
                  begin
                  gear^.Scale:= 0.25;
                  gear^.Layer:= 0
                  end
              else if random(2) = 0 then
                  gear^.Layer:= 5
              else
                  begin
                  gear^.Scale:= 0.4;
                  gear^.Layer:= 4
                  end;

    // 0: this layer is very distant in the background when in stereo
    vgtTeamHealthSorter,
    vgtSmoothWindBar: gear^.Layer:= 0;


    // 1: this layer is on the land level (which is close but behind the screen plane) when stereo
    vgtSmokeTrace,
    vgtEvilTrace,
    vgtLineTrail,
    vgtSmoke,
    vgtSmokeWhite,
    vgtDust,
    vgtFire,
    vgtSplash,
    vgtDroplet,
    vgtBubble: gear^.Layer:= 1;

    // 3: this layer is on the screen plane (depth = 0) when stereo
    vgtSpeechBubble,
    vgtSmallDamageTag,
    vgtHealthTag,
    vgtStraightShot,
    vgtChunk: gear^.Layer:= 3;

    // 2: this layer is outside the screen when stereo
    vgtExplosion,
    vgtBigExplosion,
    vgtExplPart,
    vgtExplPart2,
    vgtSteam,
    vgtAmmo,
    vgtShell,
    vgtFeather,
    vgtEgg,
    vgtBeeTrace,
    vgtSmokeRing,
    vgtNote,
    vgtBulletHit,
    vgtCircle: gear^.Layer:= 2
end;

if VisualGearLayers[gear^.Layer] <> nil then
    begin
    VisualGearLayers[gear^.Layer]^.PrevGear:= gear;
    gear^.NextGear:= VisualGearLayers[gear^.Layer]
    end;
VisualGearLayers[gear^.Layer]:= gear;

AddVisualGear:= gear;
end;

procedure DeleteVisualGear(Gear: PVisualGear);
begin
    FreeTexture(Gear^.Tex);
    Gear^.Tex:= nil;

    if Gear^.NextGear <> nil then
        Gear^.NextGear^.PrevGear:= Gear^.PrevGear;
    if Gear^.PrevGear <> nil then
        Gear^.PrevGear^.NextGear:= Gear^.NextGear
    else
        VisualGearLayers[Gear^.Layer]:= Gear^.NextGear;

    if lastVisualGearByUID = Gear then
        lastVisualGearByUID:= nil;

    Dispose(Gear);
end;

procedure ProcessVisualGears(Steps: Longword);
var Gear, t: PVisualGear;
    i: LongWord;
begin
if Steps = 0 then
    exit;

for i:= 0 to 6 do
    begin
    t:= VisualGearLayers[i];
    while t <> nil do
        begin
        Gear:= t;
        t:= Gear^.NextGear;
        Gear^.doStep(Gear, Steps)
        end;
    end
end;

procedure KickFlakes(Radius, X, Y: LongInt);
var Gear, t: PVisualGear;
    dmg, i: LongInt;
begin
if (vobCount = 0) or (vobCount > 200) then
    exit;
for i:= 2 to 6 do
    if i <> 3 then
        begin
        t:= VisualGearLayers[i];
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
                    if Gear^.X - X < 0 then
                        Gear^.tdX := -Gear^.tdX;
                    Gear^.tdY:= 0.02 * dmg + 0.01;
                    if Gear^.Y - Y < 0 then
                        Gear^.tdY := -Gear^.tdY;
                    Gear^.Timer:= 200
                    end
                end;
            t:= Gear^.NextGear
            end
        end
end;

procedure DrawVisualGears(Layer: LongWord);
var Gear: PVisualGear;
    tinted: boolean;
    tmp: real;
    i: LongInt;
begin
case Layer of
    // this layer is very distant in the background when stereo
    0: begin
        Gear:= VisualGearLayers[0];
        while Gear <> nil do
            begin
            if Gear^.Tint <> $FFFFFFFF then Tint(Gear^.Tint);
            case Gear^.Kind of
              vgtCloud: if SuddenDeathDmg then
                             DrawTextureF(SpritesData[sprSDCloud].Texture, Gear^.Scale, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 2, SpritesData[sprCloud].Width, SpritesData[sprCloud].Height)
                         else
                            DrawTextureF(SpritesData[sprCloud].Texture, Gear^.Scale, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 2, SpritesData[sprCloud].Width, SpritesData[sprCloud].Height);
               vgtFlake: if cFlattenFlakes then
                             begin
                             if SuddenDeathDmg then
                                 if vobSDVelocity = 0 then
                                     DrawSprite(sprSDFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame)
                                 else
                                     DrawSpriteRotatedF(sprSDFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, Gear^.Angle)
                             else
                                 if vobVelocity = 0 then
                                     DrawSprite(sprFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame)
                                 else
                                     DrawSpriteRotatedF(sprFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, Gear^.Angle)
                             end
                         else
                             begin
                             if SuddenDeathDmg then
                                 if vobSDVelocity = 0 then
                                     DrawTextureF(SpritesData[sprSDFlake].Texture, Gear^.Scale, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, SpritesData[sprFlake].Width, SpritesData[sprFlake].Height)
                                 else
                                     DrawTextureRotatedF(SpritesData[sprSDFlake].Texture, Gear^.Scale, 0, 0, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, SpritesData[sprFlake].Width, SpritesData[sprFlake].Height, Gear^.Angle)
                             else
                                 if vobVelocity = 0 then
                                     DrawTextureF(SpritesData[sprFlake].Texture, Gear^.Scale, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, SpritesData[sprFlake].Width, SpritesData[sprFlake].Height)
                                 else
                                     DrawTextureRotatedF(SpritesData[sprFlake].Texture, Gear^.Scale, 0, 0, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, SpritesData[sprFlake].Width, SpritesData[sprFlake].Height, Gear^.Angle)
                             end;
               end;
           if Gear^.Tint <> $FFFFFFFF then
               Tint($FF,$FF,$FF,$FF);
           Gear:= Gear^.NextGear
           end
       end;
    // this layer is on the land level (which is close but behind the screen plane) when stereo
    1: begin
       Gear:= VisualGearLayers[1];
       while Gear <> nil do
          begin
          //tinted:= false;
          if Gear^.Tint <> $FFFFFFFF then
              Tint(Gear^.Tint);
          case Gear^.Kind of
              vgtFlake: if SuddenDeathDmg then
                             if vobSDVelocity = 0 then
                                 DrawSprite(sprSDFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame)
                             else
                                 DrawSpriteRotatedF(sprSDFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, Gear^.Angle)
                         else
                             if vobVelocity = 0 then
                                 DrawSprite(sprFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame)
                             else
                                 DrawSpriteRotatedF(sprFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, Gear^.Angle);
              vgtSmokeTrace: if Gear^.State < 8 then
                  DrawSprite(sprSmokeTrace, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.State);
              vgtEvilTrace: if Gear^.State < 8 then
                  DrawSprite(sprEvilTrace, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.State);
              vgtLineTrail: DrawLine(Gear^.X, Gear^.Y, Gear^.dX, Gear^.dY, 1.0, $FF, min(Gear^.Timer, $C0), min(Gear^.Timer, $80), min(Gear^.Timer, $FF));
          end;
          if (cReducedQuality and rqAntiBoom) = 0 then
              case Gear^.Kind of
                  vgtSmoke: DrawTextureF(SpritesData[sprSmoke].Texture, Gear^.scale, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, 7 - Gear^.Frame, 1, SpritesData[sprSmoke].Width, SpritesData[sprSmoke].Height);
                  vgtSmokeWhite: DrawSprite(sprSmokeWhite, round(Gear^.X) + WorldDx - 11, round(Gear^.Y) + WorldDy - 11, 7 - Gear^.Frame);
                  vgtDust: if Gear^.State = 1 then
                               DrawSprite(sprSnowDust, round(Gear^.X) + WorldDx - 11, round(Gear^.Y) + WorldDy - 11, 7 - Gear^.Frame)
                           else
                               DrawSprite(sprDust, round(Gear^.X) + WorldDx - 11, round(Gear^.Y) + WorldDy - 11, 7 - Gear^.Frame);
                  vgtFire: if (Gear^.State and gstTmpFlag) = 0 then
                               DrawSprite(sprFlame, round(Gear^.X) + WorldDx - 8, round(Gear^.Y) + WorldDy, (RealTicks shr 6 + Gear^.Frame) mod 8)
                           else
                               DrawTextureF(SpritesData[sprFlame].Texture, Gear^.FrameTicks / 900, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, (RealTicks shr 7 + Gear^.Frame) mod 8, 1, 16, 16);
                  vgtSplash: if SuddenDeathDmg then
                                 //DrawSprite(sprSDSplash, round(Gear^.X) + WorldDx - 40, round(Gear^.Y) + WorldDy - 58, 19 - (Gear^.FrameTicks div 37))
                                 DrawTextureF(SpritesData[sprSDSplash].Texture, Gear^.scale, round(Gear^.X + WorldDx), round(Gear^.Y + WorldDy - ((SpritesData[sprSDSplash].Height+8)*Gear^.Scale)/2), 19 - (Gear^.FrameTicks div 37), 1, SpritesData[sprSDSplash].Width, SpritesData[sprSDSplash].Height)
                             else
                                 //DrawSprite(sprSplash, round(Gear^.X) + WorldDx - 40, round(Gear^.Y) + WorldDy - 58, 19 - (Gear^.FrameTicks div 37));
                                 DrawTextureF(SpritesData[sprSplash].Texture, Gear^.scale, round(Gear^.X + WorldDx), round(Gear^.Y + WorldDy - ((SpritesData[sprSplash].Height+8)*Gear^.Scale)/2), 19 - (Gear^.FrameTicks div 37), 1, SpritesData[sprSplash].Width, SpritesData[sprSplash].Height);
                  vgtDroplet: if SuddenDeathDmg then
                                  DrawSprite(sprSDDroplet, round(Gear^.X) + WorldDx - 8, round(Gear^.Y) + WorldDy - 8, Gear^.Frame)
                              else
                                  DrawSprite(sprDroplet, round(Gear^.X) + WorldDx - 8, round(Gear^.Y) + WorldDy - 8, Gear^.Frame);
                  vgtBubble: DrawSprite(sprBubbles, round(Gear^.X) + WorldDx - 8, round(Gear^.Y) + WorldDy - 8, Gear^.Frame);//(RealTicks div 64 + Gear^.Frame) mod 8);
              end;
          //if (Gear^.Tint <> $FFFFFFFF) or tinted then Tint($FF,$FF,$FF,$FF);
          if (Gear^.Tint <> $FFFFFFFF) then
              Tint($FF,$FF,$FF,$FF);
          Gear:= Gear^.NextGear
          end
       end;
    // this layer is on the screen plane (depth = 0) when stereo
    3: begin
       Gear:= VisualGearLayers[3];
       while Gear <> nil do
           begin
           tinted:= false;
           if Gear^.Tint <> $FFFFFFFF then
               Tint(Gear^.Tint);
           case Gear^.Kind of
(*
              vgtFlake: if SuddenDeathDmg then
                             if vobSDVelocity = 0 then
                                 DrawSprite(sprSDFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame)
                             else
                                 DrawSpriteRotatedF(sprSDFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, Gear^.Angle)
                         else
                             if vobVelocity = 0 then
                                 DrawSprite(sprFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame)
                             else
                                 DrawSpriteRotatedF(sprFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, Gear^.Angle);*)
               vgtSpeechBubble: begin
                                if (Gear^.Tex <> nil) and (((Gear^.State = 0) and (Gear^.Hedgehog^.Team <> CurrentTeam)) or (Gear^.State = 1)) then
                                    begin
                                    tinted:= true;
                                    Tint($FF, $FF, $FF,  $66);
                                    DrawTextureCentered(round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Tex)
                                    end
                                else if (Gear^.Tex <> nil) and (((Gear^.State = 0) and (Gear^.Hedgehog^.Team = CurrentTeam)) or (Gear^.State = 2)) then
                                    DrawTextureCentered(round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Tex);
                                end;
               vgtSmallDamageTag: DrawTextureCentered(round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Tex);
               vgtHealthTag: if Gear^.Tex <> nil then 
                               begin
                               if Gear^.Frame = 0 then 
                                   DrawTextureCentered(round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Tex)
                               else
                                   begin
                                   SetScale(cDefaultZoomLevel);
                                   if Gear^.Angle = 0 then
                                       DrawTexture(round(Gear^.X), round(Gear^.Y), Gear^.Tex)
                                   else
                                       DrawTexture(round(Gear^.X), round(Gear^.Y), Gear^.Tex, Gear^.Angle); 
                                   SetScale(zoom)
                                   end
                               end;
               vgtStraightShot: begin 
                                if Gear^.dX < 0 then
                                    i:= -1
                                else
                                    i:= 1;
                                DrawTextureRotatedF(SpritesData[TSprite(Gear^.State)].Texture, Gear^.Scale, 0, 0, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Frame, i, SpritesData[TSprite(Gear^.State)].Width, SpritesData[TSprite(Gear^.State)].Height, Gear^.Angle);
                                end;
           end;
           if (cReducedQuality and rqAntiBoom) = 0 then
               case Gear^.Kind of
                   vgtChunk: DrawSpriteRotatedF(sprChunk, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Frame, 1, Gear^.Angle);
               end;
           if (Gear^.Tint <> $FFFFFFFF) or tinted then
               Tint($FF,$FF,$FF,$FF);
           Gear:= Gear^.NextGear
           end
       end;
    // this layer is outside the screen when stereo
    2: begin
       Gear:= VisualGearLayers[2];
       while Gear <> nil do
           begin
           tinted:= false;
           if Gear^.Tint <> $FFFFFFFF then
               Tint(Gear^.Tint);
           case Gear^.Kind of
               vgtExplosion: DrawSprite(sprExplosion50, round(Gear^.X) - 32 + WorldDx, round(Gear^.Y) - 32 + WorldDy, Gear^.State);
               vgtBigExplosion: begin
                                tinted:= true;
                                Tint($FF, $FF, $FF, round($FF * (1 - power(Gear^.Timer / 250, 4))));
                                DrawTextureRotatedF(SpritesData[sprBigExplosion].Texture, 0.85 * (-power(2, -10 * Int(Gear^.Timer)/250) + 1) + 0.4, 0, 0, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, 0, 1, 385, 385, Gear^.Angle);
                                end;
           end;
           if (cReducedQuality and rqAntiBoom) = 0 then
               case Gear^.Kind of
                   vgtExplPart: DrawSprite(sprExplPart, round(Gear^.X) + WorldDx - 16, round(Gear^.Y) + WorldDy - 16, 7 - Gear^.Frame);
                   vgtExplPart2: DrawSprite(sprExplPart2, round(Gear^.X) + WorldDx - 16, round(Gear^.Y) + WorldDy - 16, 7 - Gear^.Frame);
                   vgtSteam: DrawSprite(sprSmokeWhite, round(Gear^.X) + WorldDx - 11, round(Gear^.Y) + WorldDy - 11, 7 - Gear^.Frame);
                   vgtAmmo: begin
                            tinted:= true;
                            Tint($FF, $FF, $FF, round(Gear^.alpha * $FF));
                            DrawTextureF(ropeIconTex, Gear^.scale, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, 0, 1, 32, 32);
                            DrawTextureF(SpritesData[sprAMAmmos].Texture, Gear^.scale * 0.90, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Frame - 1, 1, 32, 32);
                            end;
                   vgtShell: begin
                             if Gear^.FrameTicks < $FF then
                                 begin
                                 Tint($FF, $FF, $FF, Gear^.FrameTicks);
                                 tinted:= true
                                 end;
                             DrawSpriteRotatedF(sprShell, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Frame, 1, Gear^.Angle);
                             end;
                   vgtFeather: begin
                               if Gear^.FrameTicks < 255 then
                                   begin
                                   Tint($FF, $FF, $FF, Gear^.FrameTicks);
                                   tinted:= true
                                   end;
                               DrawSpriteRotatedF(sprFeather, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Frame, 1, Gear^.Angle);
                             end;
                   vgtEgg: DrawSpriteRotatedF(sprEgg, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Frame, 1, Gear^.Angle);
                   vgtBeeTrace: begin
                                if Gear^.FrameTicks < $FF then
                                    Tint($FF, $FF, $FF, Gear^.FrameTicks div 2)
                                else
                                    Tint($FF, $FF, $FF, $80);
                                tinted:= true;
                                DrawSpriteRotatedF(sprBeeTrace, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Frame, 1, (RealTicks shr 4) mod cMaxAngle);
                                end;
                   vgtSmokeRing: begin
                                 tinted:= true;
                                 Tint($FF, $FF, $FF, round(Gear^.alpha * $FF));
                                 DrawTextureRotatedF(SpritesData[sprSmokeRing].Texture, Gear^.scale, 0, 0, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, 0, 1, 200, 200, Gear^.Angle);
                                 end;
                   vgtNote: DrawSpriteRotatedF(sprNote, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Frame, 1, Gear^.Angle);
                   vgtBulletHit: DrawSpriteRotatedF(sprBulletHit, round(Gear^.X) + WorldDx - 0, round(Gear^.Y) + WorldDy - 0, 7 - (Gear^.FrameTicks div 50), 1, Gear^.Angle);
               end;
           case Gear^.Kind of
               vgtFlake: if SuddenDeathDmg then
                             if vobSDVelocity = 0 then
                                 DrawTextureF(SpritesData[sprSDFlake].Texture, Gear^.Scale, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, SpritesData[sprFlake].Width, SpritesData[sprFlake].Height)
                             else
                                 DrawTextureRotatedF(SpritesData[sprSDFlake].Texture, Gear^.Scale, 0, 0, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, SpritesData[sprFlake].Width, SpritesData[sprFlake].Height, Gear^.Angle)
                         else
                             if vobVelocity = 0 then
                                 DrawTextureF(SpritesData[sprFlake].Texture, Gear^.Scale, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, SpritesData[sprFlake].Width, SpritesData[sprFlake].Height)
                             else
                                 DrawTextureRotatedF(SpritesData[sprFlake].Texture, Gear^.Scale, 0, 0, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, SpritesData[sprFlake].Width, SpritesData[sprFlake].Height, Gear^.Angle);
               vgtCircle: if gear^.Angle = 1 then
                              begin
                              tmp:= Gear^.State / 100;
                              DrawTexture(round(Gear^.X-24*tmp) + WorldDx, round(Gear^.Y-24*tmp) + WorldDy, SpritesData[sprVampiric].Texture, tmp)
                              end
                          else
                              DrawCircle(round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.State, Gear^.Timer);
           end;
           if (Gear^.Tint <> $FFFFFFFF) or tinted then
               Tint($FF,$FF,$FF,$FF);
           Gear:= Gear^.NextGear
           end
       end;
     // this layer is half-way between the screen plane (depth = 0) when in stereo, and the land
     4: begin
        Gear:= VisualGearLayers[4];
        while Gear <> nil do
            begin
            if Gear^.Tint <> $FFFFFFFF then
                Tint(Gear^.Tint);
            case Gear^.Kind of
               vgtCloud: if SuddenDeathDmg then
                            DrawTextureF(SpritesData[sprSDCloud].Texture, Gear^.Scale, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 2, SpritesData[sprCloud].Width, SpritesData[sprCloud].Height)
                        else
                            DrawTextureF(SpritesData[sprCloud].Texture, Gear^.Scale, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 2, SpritesData[sprCloud].Width, SpritesData[sprCloud].Height);
              vgtFlake: if SuddenDeathDmg then
                            if vobSDVelocity = 0 then
                                DrawTextureF(SpritesData[sprSDFlake].Texture, Gear^.Scale, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, SpritesData[sprFlake].Width, SpritesData[sprFlake].Height)
                            else
                                DrawTextureRotatedF(SpritesData[sprSDFlake].Texture, Gear^.Scale, 0, 0, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, SpritesData[sprFlake].Width, SpritesData[sprFlake].Height, Gear^.Angle)
                        else
                            if vobVelocity = 0 then
                                DrawTextureF(SpritesData[sprFlake].Texture, Gear^.Scale, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, SpritesData[sprFlake].Width, SpritesData[sprFlake].Height)
                            else
                                DrawTextureRotatedF(SpritesData[sprFlake].Texture, Gear^.Scale, 0, 0, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, SpritesData[sprFlake].Width, SpritesData[sprFlake].Height, Gear^.Angle);
            end;
            if (Gear^.Tint <> $FFFFFFFF) then
                Tint($FF,$FF,$FF,$FF);
            Gear:= Gear^.NextGear
            end
        end;
     // this layer is on the screen plane (depth = 0) when stereo, but just behind the land
     5: begin
        Gear:= VisualGearLayers[5];
        while Gear <> nil do
            begin
            if Gear^.Tint <> $FFFFFFFF then
                Tint(Gear^.Tint);
            case Gear^.Kind of
                vgtCloud: if SuddenDeathDmg then
                            DrawSprite(sprSDCloud, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame)
                          else
                            DrawSprite(sprCloud, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame);
              vgtFlake: if SuddenDeathDmg then
                            if vobSDVelocity = 0 then
                                DrawSprite(sprSDFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame)
                            else
                                DrawSpriteRotatedF(sprSDFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, Gear^.Angle)
                          else
                            if vobVelocity = 0 then
                                DrawSprite(sprFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame)
                            else
                                DrawSpriteRotatedF(sprFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, Gear^.Angle);
                end;
            if (Gear^.Tint <> $FFFFFFFF) then
                Tint($FF,$FF,$FF,$FF);
            Gear:= Gear^.NextGear
            end
        end;
     // this layer is on the screen plane (depth = 0) when stereo, but just in front of the land
    6: begin
        Gear:= VisualGearLayers[6];
        while Gear <> nil do
            begin
            if Gear^.Tint <> $FFFFFFFF then
                Tint(Gear^.Tint);
            case Gear^.Kind of
                vgtFlake: if SuddenDeathDmg then
                            if vobSDVelocity = 0 then
                                DrawSprite(sprSDFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame)
                            else
                                DrawSpriteRotatedF(sprSDFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, Gear^.Angle)
                          else
                            if vobVelocity = 0 then
                                DrawSprite(sprFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame)
                            else
                                DrawSpriteRotatedF(sprFlake, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, Gear^.Angle);
                end;
            if (Gear^.Tint <> $FFFFFFFF) then
                Tint($FF,$FF,$FF,$FF);
            Gear:= Gear^.NextGear
            end
        end;
    end;
end;

function  VisualGearByUID(uid : Longword) : PVisualGear;
var vg: PVisualGear;
    i: LongWord;
begin
VisualGearByUID:= nil;
if uid = 0 then
    exit;
if (lastVisualGearByUID <> nil) and (lastVisualGearByUID^.uid = uid) then
    begin
    VisualGearByUID:= lastVisualGearByUID;
    exit
    end;
// search in an order that is more likely to return layers they actually use.  Could perhaps track statistically AddVisualGear in uScript, since that is most likely the ones they want
for i:= 2 to 5 do
    begin
    vg:= VisualGearLayers[i mod 4];
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
    end
end;

procedure AddClouds;
var i: LongInt;
begin
for i:= 0 to cCloudsNumber - 1 do
    AddVisualGear(cLeftScreenBorder + i * LongInt(cScreenSpace div (cCloudsNumber + 1)), LAND_HEIGHT-1184, vgtCloud)
end;

procedure ChangeToSDClouds;
var       i: LongInt;
    vg, tmp: PVisualGear;
begin
if cCloudsNumber = cSDCloudsNumber then
    exit;
vg:= VisualGearLayers[0];
while vg <> nil do
    if vg^.Kind = vgtCloud then
        begin
        tmp:= vg^.NextGear;
        DeleteVisualGear(vg);
        vg:= tmp
        end
    else vg:= vg^.NextGear;
for i:= 0 to cSDCloudsNumber - 1 do
    AddVisualGear(cLeftScreenBorder + i * LongInt(cScreenSpace div (cSDCloudsNumber + 1)), LAND_HEIGHT-1184, vgtCloud)
end;

procedure AddFlakes;
var i: LongInt;
begin
if (cReducedQuality and rqKillFlakes) <> 0 then
    exit;

if hasBorder or ((Theme <> 'Snow') and (Theme <> 'Christmas')) then
    for i:= 0 to Pred(vobCount * cScreenSpace div LAND_WIDTH) do
        AddVisualGear(cLeftScreenBorder + random(cScreenSpace), random(1024+200) - 100 + LAND_HEIGHT, vgtFlake)
else
    for i:= 0 to Pred((vobCount * cScreenSpace div LAND_WIDTH) div 3) do
        AddVisualGear(cLeftScreenBorder + random(cScreenSpace), random(1024+200) - 100 + LAND_HEIGHT, vgtFlake);
end;

procedure ChangeToSDFlakes;
var       i: LongInt;
    vg, tmp: PVisualGear;
begin
if (cReducedQuality and rqKillFlakes) <> 0 then
    exit;
if vobCount = vobSDCount then
    exit;
for i:= 0 to 6 do
    begin
    vg:= VisualGearLayers[i];
    while vg <> nil do
        if vg^.Kind = vgtFlake then
        begin
        tmp:= vg^.NextGear;
        DeleteVisualGear(vg);
        vg:= tmp
        end
        else vg:= vg^.NextGear;
    end;
if ((GameFlags and gfBorder) <> 0) or ((Theme <> 'Snow') and (Theme <> 'Christmas')) then
    for i:= 0 to Pred(vobSDCount * cScreenSpace div LAND_WIDTH) do
        AddVisualGear(cLeftScreenBorder + random(cScreenSpace), random(1024+200) - 100 + LAND_HEIGHT, vgtFlake)
else
    for i:= 0 to Pred((vobSDCount * cScreenSpace div LAND_WIDTH) div 3) do
        AddVisualGear(cLeftScreenBorder + random(cScreenSpace), random(1024+200) - 100 + LAND_HEIGHT, vgtFlake);
end;

procedure initModule;
var i: LongWord;
begin
VGCounter:= 0;
for i:= 0 to 6 do
    VisualGearLayers[i]:= nil;
end;

procedure freeModule;
var i: LongWord;
begin
VGCounter:= 0;
for i:= 0 to 6 do
    while VisualGearLayers[i] <> nil do DeleteVisualGear(VisualGearLayers[i]);
end;

end.
