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

unit uVisualGearsList;
interface
uses uTypes;

function  AddVisualGear(X, Y: LongInt; Kind: TVisualGearType): PVisualGear; inline;
function  AddVisualGear(X, Y: LongInt; Kind: TVisualGearType; State: LongWord): PVisualGear; inline;
function  AddVisualGear(X, Y: LongInt; Kind: TVisualGearType; State: LongWord; Critical: Boolean): PVisualGear; inline;
function  AddVisualGear(X, Y: LongInt; Kind: TVisualGearType; State: LongWord; Critical: Boolean; Layer: LongInt): PVisualGear;
procedure DeleteVisualGear(Gear: PVisualGear);
function  VisualGearByUID(uid : Longword) : PVisualGear;

const
    cExplFrameTicks = 110;

var VGCounter: LongWord;
    VisualGearLayers: array[0..6] of PVisualGear;

implementation
uses uCollisions, uFloat, uVariables, uConsts, uTextures, uVisualGearsHandlers;

function AddVisualGear(X, Y: LongInt; Kind: TVisualGearType): PVisualGear; inline;
begin
    // adjust some visual gear types if underwater
    if CheckCoordInWater(X, Y) and ((Kind = vgtBeeTrace) or (Kind = vgtSmokeTrace) or (Kind = vgtEvilTrace)) then
        Kind:= vgtBubble;

    AddVisualGear:= AddVisualGear(X, Y, Kind, 0, false, -1);
end;

function  AddVisualGear(X, Y: LongInt; Kind: TVisualGearType; State: LongWord): PVisualGear; inline;
begin
    AddVisualGear:= AddVisualGear(X, Y, Kind, State, false, -1);
end;

function  AddVisualGear(X, Y: LongInt; Kind: TVisualGearType; State: LongWord; Critical: Boolean): PVisualGear; inline;
begin
    AddVisualGear:= AddVisualGear(X, Y, Kind, State, Critical, -1);
end;

function  AddVisualGear(X, Y: LongInt; Kind: TVisualGearType; State: LongWord; Critical: Boolean; Layer: LongInt): PVisualGear;
var gear: PVisualGear;
    t: Longword;
    sp: real;
begin
AddVisualGear:= nil;
if ((GameType = gmtSave) or (fastUntilLag and (GameType = gmtNet)) or fastScrolling) and // we are scrolling now
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
    vgtFeather,
    vgtSmoothWindBar])) then

        exit;

inc(VGCounter);
New(gear);
FillChar(gear^, sizeof(TVisualGear), 0);
gear^.X:= real(X);
gear^.Y:= real(Y);
gear^.Kind := Kind;
gear^.doStep:= doStepVGHandlers[Kind];
gear^.Tint:= $FFFFFFFF;
gear^.uid:= VGCounter;

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
                    if vobSDFrameTicks > 0 then
                        FrameTicks:= random(vobSDFrameTicks);
                    Frame:= random(vobSDFramesCount);
                    end
                else
                    begin
                    if vobFrameTicks > 0 then
                        FrameTicks:= random(vobFrameTicks);
                    Frame:= random(vobFramesCount);
                    end;
                Angle:= random(360);
                dx:= 0.0000038654705 * random(10000);
                dy:= 0.000003506096 * random(7000);
                if random(2) = 0 then
                    dx := -dx;
                if SuddenDeathDmg then
                    dAngle:= (random(2) * 2 - 1) * (vobSDVelocity + random(vobSDVelocity)) / 1000
                else
                    dAngle:= (random(2) * 2 - 1) * (vobVelocity + random(vobVelocity)) / 1000
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
                if random(2) = 0 then dx := -dx;
                if random(2) = 0 then Tag:= 1
                else Tag:= -1;
                Frame:= 7 - random(2);
                FrameTicks:= random(20) + 15;
                end;
  vgtSplash:
                begin
                dx:= 0;
                dy:= 0;
                FrameTicks:= 740;
                Frame:= 19;
                Scale:= 0.75;
                Timer:= 1;
                end;
    vgtDroplet:
                begin
                dx:= 0.001 * (random(180) - 90);
                dy:= -0.001 * (random(160) + 40);
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
  vgtNoPlaceWarn:
                begin
                FrameTicks:= 2000;
                Tint:= $FF0000FF;
                Scale:= 1.0;
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
    vgtNoPlaceWarn: gear^.Layer:= 6;

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
    vgtFeather,
    vgtChunk: gear^.Layer:= 3;

    // 2: this layer is outside the screen when stereo
    vgtExplosion,
    vgtBigExplosion,
    vgtExplPart,
    vgtExplPart2,
    vgtSteam,
    vgtAmmo,
    vgtShell,
    vgtEgg,
    vgtBeeTrace,
    vgtSmokeRing,
    vgtNote,
    vgtBulletHit,
    vgtCircle: gear^.Layer:= 2
end;

if Layer <> -1 then gear^.Layer:= Layer;

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
    FreeAndNilTexture(Gear^.Tex);

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


end.
