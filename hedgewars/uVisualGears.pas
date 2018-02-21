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
uses uConsts, GLunit, uTypes;

procedure initModule;
procedure freeModule;

procedure ProcessVisualGears(Steps: Longword);
procedure DrawVisualGears(Layer: LongWord);

procedure AddClouds;
procedure AddFlakes;
procedure AddDamageTag(X, Y, Damage, Color: LongWord);

procedure ChangeToSDClouds;
procedure ChangeToSDFlakes;

procedure KickFlakes(Radius, X, Y: LongInt);

implementation
uses uVariables, uRender, Math, uRenderUtils, uUtils
    , uVisualGearsList;

procedure AddDamageTag(X, Y, Damage, Color: LongWord);
var Gear: PVisualGear;
begin
if cAltDamage then
    begin
    Gear:= AddVisualGear(X, Y, vgtSmallDamageTag);
    if Gear <> nil then
        with Gear^ do
            Tex:= RenderStringTex(ansistring(inttostr(Damage)), Color, fntSmall);
    end
end;


// ==================================================================

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

function GetSprite(sprite, SDsprite: TSprite): TSprite; inline;
begin
    if SuddenDeathDmg then
        exit(SDsprite)
    else
        exit(sprite);
end;

function GetSpriteByWind(sprite, Lsprite: TSprite): TSprite; inline;
begin
    if (SpritesData[Lsprite].Texture <> nil) and (cWindSpeedf<0) then
        exit(Lsprite)
    else
        exit(sprite);
end;

function GetSpriteData(sprite, SDsprite: TSprite): PSpriteData; inline;
begin
    exit(@SpritesData[GetSprite(sprite, SDsprite)]);
end;

procedure DrawVisualGears(Layer: LongWord);
var Gear: PVisualGear;
    tinted, speedlessFlakes: boolean;
    tmp: real;
    i: LongInt;
    sprite: TSprite;
    spriteData: PSpriteData;
begin
if SuddenDeathDmg then
    speedlessFlakes:= (vobSDVelocity = 0)
else
    speedlessFlakes:= (vobVelocity = 0);

case Layer of
    // this layer is very distant in the background when stereo
    0: begin
        Gear:= VisualGearLayers[0];
        while Gear <> nil do
            begin
            if Gear^.Tint <> $FFFFFFFF then Tint(Gear^.Tint);
            case Gear^.Kind of
              vgtCloud: begin
                        spriteData:= GetSpriteData(GetSpriteByWind(sprCloud, sprCloudL), GetSpriteByWind(sprSDCloud, sprSDCloudL));
                        DrawTextureF(spriteData^.Texture, Gear^.Scale, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, spriteData^.Width, spriteData^.Height)
                        end;
               vgtFlake: begin
                         sprite:= GetSpriteByWind(GetSprite(sprFlake, sprSDFlake), GetSprite(sprFlakeL, sprSDFlakeL));
                         if cFlattenFlakes then
                             begin
                             if speedlessFlakes then
                                 DrawSprite(sprite, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame)
                             else
                                 DrawSpriteRotatedF(sprite, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, Gear^.Angle);
                             end
                         else
                             begin
                             if speedlessFlakes then
                                 DrawTextureF(SpritesData[sprite].Texture, Gear^.Scale, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, SpritesData[sprFlake].Width, SpritesData[sprFlake].Height)
                             else
                                 DrawTextureRotatedF(SpritesData[sprite].Texture, Gear^.Scale, 0, 0, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, SpritesData[sprFlake].Width, SpritesData[sprFlake].Height, Gear^.Angle);
                             end;
                         end;
               end;
           if Gear^.Tint <> $FFFFFFFF then
               untint;
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
              vgtFlake: begin
                         sprite:= GetSpriteByWind(GetSprite(sprFlake, sprSDFlake), GetSprite(sprFlakeL, sprSDFlakeL));
                         if speedlessFlakes then
                             DrawSprite(sprite, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame)
                         else
                             DrawSpriteRotatedF(sprite, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, Gear^.Angle);
                        end;
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
                               DrawSpriteRotatedF(sprSnowDust, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, 7 - Gear^.Frame, Gear^.Tag, Gear^.Angle)
                           else
                               DrawSpriteRotatedF(sprDust, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, 7 - Gear^.Frame, Gear^.Tag, Gear^.Angle);
                  vgtFire: if (Gear^.State and gstTmpFlag) = 0 then
                               DrawSprite(sprFlame, round(Gear^.X) + WorldDx - 8, round(Gear^.Y) + WorldDy, (RealTicks shr 6 + Gear^.Frame) mod 8)
                           else
                               DrawTextureF(SpritesData[sprFlame].Texture, Gear^.FrameTicks / 900, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, (RealTicks shr 7 + Gear^.Frame) mod 8, 1, 16, 16);
                  vgtSplash: begin
                             spriteData:= GetSpriteData(sprSplash, sprSDSplash);
                             if Gear^.Angle <> 0 then
                                DrawTextureRotatedF(spriteData^.Texture, Gear^.scale, 0, 0, round(Gear^.X + WorldDx + (((spriteData^.Height+8)*Gear^.Scale)/2) * (Gear^.Angle / abs(Gear^.Angle))), round(Gear^.Y + WorldDy), 19 - (Gear^.FrameTicks div Gear^.Timer div 37), 1, spriteData^.Width, spriteData^.Height, Gear^.Angle)
                             else
                                //DrawSprite(sprite, round(Gear^.X) + WorldDx - 40, round(Gear^.Y) + WorldDy - 58, 19 - (Gear^.FrameTicks div 37))
                                DrawTextureF(spriteData^.Texture, Gear^.scale, round(Gear^.X + WorldDx), round(Gear^.Y + WorldDy - ((spriteData^.Height+8)*Gear^.Scale)/2), 19 - (Gear^.FrameTicks div Gear^.Timer div 37), 1, spriteData^.Width, spriteData^.Height);
                             end;
                  vgtDroplet: begin
                              sprite:= GetSprite(sprDroplet, sprSDDroplet);
                              DrawSprite(sprite, round(Gear^.X) + WorldDx - 8, round(Gear^.Y) + WorldDy - 8, Gear^.Frame);
                              end;
                  vgtBubble: DrawSprite(sprBubbles, round(Gear^.X) + WorldDx - 8, round(Gear^.Y) + WorldDy - 8, Gear^.Frame);//(RealTicks div 64 + Gear^.Frame) mod 8);
               vgtStraightShot: begin
                                if Gear^.dX < 0 then
                                    i:= -1
                                else
                                    i:= 1;
                                DrawTextureRotatedF(SpritesData[TSprite(Gear^.State)].Texture, Gear^.Scale, 0, 0, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Frame, i, SpritesData[TSprite(Gear^.State)].Width, SpritesData[TSprite(Gear^.State)].Height, Gear^.Angle);
                                end;
              end;
          //if (Gear^.Tint <> $FFFFFFFF) or tinted then untint;
          if (Gear^.Tint <> $FFFFFFFF) then
              untint;
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
              vgtFlake: begin
                        sprite:= GetSprite(sprFlake, sprSDFlake);
                        if speedlessFlakes then
                            DrawSprite(sprite, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame)
                        else
                            DrawSpriteRotatedF(sprite, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, Gear^.Angle)
                        end;*)
               vgtSpeechBubble: begin
                                if (Gear^.Tex <> nil) and (((Gear^.State = 0) and (Gear^.Hedgehog <> nil) and (Gear^.Hedgehog^.Team <> CurrentTeam)) or (Gear^.State = 1)) then
                                    begin
                                    tinted:= true;
                                    Tint($FF, $FF, $FF,  $66);
                                    DrawTextureCentered(round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Tex)
                                    end
                                else if (Gear^.Tex <> nil) and (((Gear^.State = 0) and ((Gear^.Hedgehog = nil) or (Gear^.Hedgehog^.Team = CurrentTeam))) or (Gear^.State = 2)) then
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
                   vgtFeather: begin
                               if Gear^.FrameTicks < 255 then
                                   begin
                                   Tint($FF, $FF, $FF, Gear^.FrameTicks);
                                   tinted:= true
                                   end;
                               DrawSpriteRotatedF(sprFeather, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Frame, 1, Gear^.Angle);
                             end;
           end;
           if (cReducedQuality and rqAntiBoom) = 0 then
               case Gear^.Kind of
                   vgtChunk: DrawSpriteRotatedF(sprChunk, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.Frame, 1, Gear^.Angle);
               end;
           if (Gear^.Tint <> $FFFFFFFF) or tinted then
               untint;
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
                            if Gear^.Frame <> ord(amNothing) then
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
               vgtFlake: begin
                         spriteData:= GetSpriteData(GetSpriteByWind(sprFlake, sprFlakeL), GetSpriteByWind(sprSDFlake, sprSDFlakeL));
                         if speedlessFlakes then
                             DrawTextureF(spriteData^.Texture, Gear^.Scale, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, spriteData^.Width, spriteData^.Height)
                         else
                             DrawTextureRotatedF(spriteData^.Texture, Gear^.Scale, 0, 0, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, spriteData^.Width, spriteData^.Height, Gear^.Angle);
                         end;
               vgtCircle: if gear^.Angle = 1 then
                              begin
                              tmp:= Gear^.State / 100;
                              DrawTexture(round(Gear^.X-24*tmp) + WorldDx, round(Gear^.Y-24*tmp) + WorldDy, SpritesData[sprVampiric].Texture, tmp)
                              end
                          else
                              DrawCircle(round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy, Gear^.State, Gear^.Timer);
           end;
           if (Gear^.Tint <> $FFFFFFFF) or tinted then
               untint;
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
               vgtCloud: begin
                         spriteData:= GetSpriteData(GetSpriteByWind(sprCloud, sprCloudL), GetSpriteByWind(sprSDCloud, sprSDCloudL));
                         DrawTextureF(spriteData^.Texture, Gear^.Scale, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, spriteData^.Width, spriteData^.Height);
                         end;
              vgtFlake: begin
                        spriteData:= GetSpriteData(GetSpriteByWind(sprFlake, sprFlakeL), GetSpriteByWind(sprSDFlake, sprSDFlakeL));
                        if speedlessFlakes then
                            DrawTextureF(spriteData^.Texture, Gear^.Scale, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, spriteData^.Width, spriteData^.Height)
                        else
                            DrawTextureRotatedF(spriteData^.Texture, Gear^.Scale, 0, 0, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, spriteData^.Width, spriteData^.Height, Gear^.Angle);
                        end;
            end;
            if (Gear^.Tint <> $FFFFFFFF) then
                untint;
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
                vgtCloud: begin
                        sprite:= GetSpriteByWind(GetSprite(sprCloud, sprSDCloud), GetSprite(sprCloudL, sprSDCloudL));
                          DrawSprite(sprite, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame);
                          end;
              vgtFlake: begin
                        sprite:= GetSpriteByWind(GetSprite(sprFlake, sprSDFlake), GetSprite(sprFlakeL, sprSDFlakeL));
                        if speedlessFlakes then
                            DrawSprite(sprite, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame)
                        else
                            DrawSpriteRotatedF(sprite, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, Gear^.Angle);
                        end;
                end;
            if (Gear^.Tint <> $FFFFFFFF) then
                untint;
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
                vgtFlake: begin
                         sprite:= GetSpriteByWind(GetSprite(sprFlake, sprSDFlake), GetSprite(sprFlakeL, sprSDFlakeL));
                          if speedlessFlakes then
                              DrawSprite(sprite, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame)
                          else
                              DrawSpriteRotatedF(sprite, round(Gear^.X) + WorldDx, round(Gear^.Y) + WorldDy + SkyOffset, Gear^.Frame, 1, Gear^.Angle)
                          end;
                vgtNoPlaceWarn:
                            DrawTexture(round(Gear^.X) + WorldDx - round(Gear^.Tex^.w * Gear^.Scale) div 2, round(Gear^.Y) + WorldDy - round(Gear^.Tex^.h * Gear^.Scale) div 2, Gear^.Tex, Gear^.Scale);
                end;
            if (Gear^.Tint <> $FFFFFFFF) then
                untint;
            Gear:= Gear^.NextGear
            end
        end;
    end;
end;

procedure AddClouds;
var i: LongInt;
begin
for i:= 0 to cCloudsNumber - 1 do
    AddVisualGear(cLeftScreenBorder + i * LongInt(cScreenSpace div (cCloudsNumber + 1)), LAND_HEIGHT-1184, vgtCloud)
end;

procedure ChangeToSDClouds;
var       i, j: LongInt;
    vg, tmp: PVisualGear;
begin
if cCloudsNumber = cSDCloudsNumber then
    exit;
for i:= 0 to 6 do
    begin
    vg:= VisualGearLayers[i];
    while vg <> nil do
        if vg^.Kind = vgtCloud then
            begin
            tmp:= vg^.NextGear;
            DeleteVisualGear(vg);
            vg:= tmp
            end
        else vg:= vg^.NextGear;
    for j:= 0 to cSDCloudsNumber - 1 do
        AddVisualGear(cLeftScreenBorder + j * LongInt(cScreenSpace div (cSDCloudsNumber + 1)), LAND_HEIGHT-1184, vgtCloud)
    end;
end;

procedure AddFlakes;
var i: LongInt;
begin
if (cReducedQuality and rqKillFlakes) <> 0 then
    exit;

if hasBorder or (not cSnow) then
    for i:= 0 to Pred(vobCount * cScreenSpace div 4096) do
        AddVisualGear(cLeftScreenBorder + random(cScreenSpace), random(1024+200) - 100 + LAND_HEIGHT, vgtFlake)
else
    for i:= 0 to Pred((vobCount * cScreenSpace div 4096) div 3) do
        AddVisualGear(cLeftScreenBorder + random(cScreenSpace), random(1024+200) - 100 + LAND_HEIGHT, vgtFlake);
end;

procedure ChangeToSDFlakes;
var       i: LongInt;
    vg, tmp: PVisualGear;
begin
if (cReducedQuality and rqKillFlakes) <> 0 then
    exit;
if (vobCount = vobSDCount) and (vobFrameTicks = vobSDFrameTicks) and
        (vobFramesCount = vobSDFramesCount) and (vobVelocity = vobSDVelocity) and
        (vobFallSpeed = vobSDFallSpeed) then
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
if hasBorder or (not cSnow) then
    for i:= 0 to Pred(vobSDCount * cScreenSpace div 4096) do
        AddVisualGear(cLeftScreenBorder + random(cScreenSpace), random(1024+200) - 100 + LAND_HEIGHT, vgtFlake)
else
    for i:= 0 to Pred((vobSDCount * cScreenSpace div 4096) div 3) do
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
