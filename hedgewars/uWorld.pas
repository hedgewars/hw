(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2009 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uWorld;
interface
uses SDLh, uGears, uConsts, uFloat, uRandom;


var FollowGear: PGear;
    WindBarWidth: LongInt;
    bShowAmmoMenu: boolean;
    bSelected: boolean;
    bShowFinger: boolean;
    Frames: Longword;
    WaterColor, DeepWaterColor: TSDL_Color;
    WorldDx: LongInt;
    WorldDy: LongInt;
{$IFDEF COUNTTICKS}
    cntTicks: LongWord;
{$ENDIF}

procedure initModule;
procedure freeModule;

procedure InitWorld;
procedure DrawWorld(Lag: LongInt);
procedure AddCaption(s: shortstring; Color: Longword; Group: TCapGroup);
procedure ShowMission(caption, subcaption, text: ansistring; icon, time : LongInt);
procedure HideMission;
procedure ShakeCamera(amount: LongWord);

implementation
uses    uStore, uMisc, uTeams, uIO, uConsole, uKeys, uLocale, uSound, uAmmos, uVisualGears, uChat, uLandTexture, uLand,
{$IFDEF GLES11}
    gles11;
{$ELSE}
    GL;
{$ENDIF}

type TCaptionStr = record
                   Tex: PTexture;
                   EndTime: LongWord;
                   end;

var cWaveWidth, cWaveHeight: LongInt;
    Captions: array[TCapGroup] of TCaptionStr;
    AMxShift, SlotsNum: LongInt;
    tmpSurface: PSDL_Surface;
    fpsTexture: PTexture;
    timeTexture: PTexture;
    FPS: Longword;
    CountTicks: Longword;
    SoundTimerTicks: Longword;
    prevPoint: TPoint;
    amSel: TAmmoType = amNothing;
    missionTex: PTexture;
    missionTimer: LongInt;

procedure InitWorld;
var i, t: LongInt;
    cp: PClan;
    g: ansistring;

    // helper functions to create the goal/game mode string
    function AddGoal(s: ansistring; gf: longword; si: TGoalStrId; i: LongInt): ansistring;
    var t: ansistring;
    begin
        if (GameFlags and gf) <> 0 then
            begin
            t:= inttostr(i);
            s:= s + format(trgoal[si], t) + '|'
            end;
        AddGoal:= s;
    end;

    function AddGoal(s: ansistring; gf: longword; si: TGoalStrId): ansistring;
    begin
        if (GameFlags and gf) <> 0 then
            s:= s + trgoal[si] + '|';
        AddGoal:= s;
    end;
begin
missionTimer:= 0;

if (GameFlags and gfRandomOrder) <> 0 then  // shuffle them up a bit
   begin
   for i:= 0 to ClansCount * 4 do
      begin
      t:= GetRandom(ClansCount);
      if t <> 0 then
         begin
         cp:= ClansArray[0];
         ClansArray[0]:= ClansArray[t];
         ClansArray[t]:= cp;
         ClansArray[t]^.ClanIndex:= t;
         ClansArray[0]^.ClanIndex:= 0;
         if (LocalClan = t) then LocalClan:= 0
         else if (LocalClan = 0) then LocalClan:= t
         end;
      end;
   CurrentTeam:= ClansArray[0]^.Teams[0];
   end;

// if special game flags/settings are changed, add them to the game mode notice window and then show it
g:= ''; // no text/things to note yet

// check different game flags (goals/game modes first for now)
g:= AddGoal(g, gfKing, gidKing); // king?

// other important flags
g:= AddGoal(g, gfForts, gidForts); // forts?
g:= AddGoal(g, gfLowGravity, gidLowGravity); // low gravity?
g:= AddGoal(g, gfInvulnerable, gidInvulnerable); // invulnerability?
g:= AddGoal(g, gfVampiric, gidVampiric); // vampirism?
g:= AddGoal(g, gfKarma, gidKarma); // karma?
g:= AddGoal(g, gfPlaceHog, gidPlaceHog); // placement?
g:= AddGoal(g, gfArtillery, gidArtillery); // artillery?
g:= AddGoal(g, gfSolidLand, gidSolidLand); // solid land?
g:= AddGoal(g, gfSharedAmmo, gidSharedAmmo); // shared ammo?

// modified damage modificator?
if cDamagePercent <> 100 then
    g:= AddGoal(g, gfAny, gidDamageModifier, cDamagePercent);

// fade in
ScreenFade:= sfFromBlack;
ScreenFadeValue:= sfMax;
ScreenFadeSpeed:= 1;

// modified mine timers?
if cMinesTime <> 3000 then
    begin
    if cMinesTime = 0 then
        g:= AddGoal(g, gfMines, gidNoMineTimer)
    else if cMinesTime < 0 then
        g:= AddGoal(g, gfMines, gidRandomMineTimer)
    else
        g:= AddGoal(g, gfMines, gidMineTimer, cMinesTime div 1000);
    end;

// if the string has been set, show it for (default timeframe) seconds
if g <> '' then ShowMission(trgoal[gidCaption], trgoal[gidSubCaption], g, 1, 0);

cWaveWidth:= SpritesData[sprWater].Width;
//cWaveHeight:= SpritesData[sprWater].Height;
cWaveHeight:= 32;

cGearScrEdgesDist:= Min(cScreenWidth div 2 - 100, cScreenHeight div 2 - 50);
SDL_WarpMouse(cScreenWidth div 2, cScreenHeight div 2);
prevPoint.X:= 0;
prevPoint.Y:= cScreenHeight div 2;
WorldDx:=  - (LAND_WIDTH div 2) + cScreenWidth div 2;
WorldDy:=  - (LAND_HEIGHT - (playHeight div 2)) + (cScreenHeight div 2);
AMxShift:= 210;
end;

procedure ShowAmmoMenu;
const MENUSPEED = 15;
var x, y, i, t, l, g: LongInt;
    Slot, Pos: LongInt;
    Ammo: PHHAmmo;
begin
if  (TurnTimeLeft = 0) or (not CurrentTeam^.ExtDriven and (((CurAmmoGear = nil) or ((CurAmmoGear^.Ammo^.Propz and ammoprop_AltAttack) = 0)) and hideAmmoMenu)) then bShowAmmoMenu:= false;
if bShowAmmoMenu then
   begin
   FollowGear:= nil;
   if AMxShift = 210 then prevPoint.X:= 0;
   if cReducedQuality then
       AMxShift:= 0
   else
       if AMxShift > 0 then dec(AMxShift, MENUSPEED);
   end else
   begin
   if AMxShift = 0 then
      begin
      CursorPoint.X:= cScreenWidth shr 1;
      CursorPoint.Y:= cScreenHeight shr 1;
      prevPoint:= CursorPoint;
      SDL_WarpMouse(CursorPoint.X  + cScreenWidth div 2, cScreenHeight - CursorPoint.Y)
      end;
   if cReducedQuality then
       AMxShift:= 210
   else
       if AMxShift < 210 then inc(AMxShift, MENUSPEED);
   end;
Ammo:= nil;
if (CurrentTeam <> nil) and (CurrentHedgehog <> nil) and (not CurrentTeam^.ExtDriven) and (CurrentHedgehog^.BotLevel = 0) then
   Ammo:= CurrentHedgehog^.Ammo
else if (LocalAmmo <> -1) then
   Ammo:= GetAmmoByNum(LocalAmmo);
Slot:= 0;
Pos:= -1;
if Ammo = nil then
    begin
    bShowAmmoMenu:= false;
    exit
    end;
SlotsNum:= 0;
x:= (cScreenWidth shr 1) - 210 + AMxShift;
y:= cScreenHeight - 40;
dec(y);
DrawSprite(sprAMBorders, x, y, 0);
dec(y);
DrawSprite(sprAMBorders, x, y, 1);
dec(y, 33);
DrawSprite(sprAMSlotName, x, y, 0);
for i:= cMaxSlotIndex downto 0 do
    if ((i = 0) and (Ammo^[i, 1].Count > 0)) or ((i <> 0) and (Ammo^[i, 0].Count > 0)) then
        begin
        if (cScreenHeight - CursorPoint.Y >= y - 33) and (cScreenHeight - CursorPoint.Y < y) then Slot:= i;
        dec(y, 33);
        inc(SlotsNum);
        DrawSprite(sprAMSlot, x, y, 0);
        DrawSprite(sprAMSlotKeys, x + 2, y + 1, i);
        t:= 0;
                    g:= 0;
        while (t <= cMaxSlotAmmoIndex) and (Ammo^[i, t].Count > 0) do
            begin
            if (Ammo^[i, t].AmmoType <> amNothing) then
                begin
                l:= Ammoz[Ammo^[i, t].AmmoType].SkipTurns - CurrentTeam^.Clan^.TurnNumber;

                if l >= 0 then
                    begin
                    DrawSprite(sprAMAmmosBW, x + g * 33 + 35, y + 1, LongInt(Ammo^[i, t].AmmoType)-1);
                    if l < 100 then DrawSprite(sprTurnsLeft, x + g * 33 + 51, y + 17, l);
                    end else
                    DrawSprite(sprAMAmmos, x + g * 33 + 35, y + 1, LongInt(Ammo^[i, t].AmmoType)-1);
                if (Slot = i)
                and (CursorPoint.X >= x + g * 33 + 35)
                and (CursorPoint.X < x + g * 33 + 68) then
                    begin
                    if (l < 0) then DrawSprite(sprAMSelection, x + g * 33 + 35, y + 1, 0);
                    Pos:= t;
                    end;
                inc(g)
                end;
                inc(t)
            end
        end;
dec(y, 1);
DrawSprite(sprAMBorders, x, y, 0);

if (Pos >= 0) then
    begin
    if (Ammo^[Slot, Pos].Count > 0) and (Ammo^[Slot, Pos].AmmoType <> amNothing) then
        if (amSel <> Ammo^[Slot, Pos].AmmoType) or (WeaponTooltipTex = nil) then
            begin
            amSel:= Ammo^[Slot, Pos].AmmoType;
            RenderWeaponTooltip(amSel)
            end;
        
        DrawTexture(cScreenWidth div 2 - 200 + AMxShift, cScreenHeight - 68, Ammoz[Ammo^[Slot, Pos].AmmoType].NameTex);

        if Ammo^[Slot, Pos].Count < AMMO_INFINITE then
            DrawTexture(cScreenWidth div 2 + AMxShift - 35, cScreenHeight - 68, CountTexz[Ammo^[Slot, Pos].Count]);

        if bSelected and (Ammoz[Ammo^[Slot, Pos].AmmoType].SkipTurns - CurrentTeam^.Clan^.TurnNumber < 0) then
            begin
            bShowAmmoMenu:= false;
            SetWeapon(Ammo^[Slot, Pos].AmmoType);
            bSelected:= false;
            FreeWeaponTooltip;
            exit
            end;
    end
else
    FreeWeaponTooltip;

if (WeaponTooltipTex <> nil) and (AMxShift = 0) then
    ShowWeaponTooltip(x - WeaponTooltipTex^.w - 3, min(y, cScreenHeight - WeaponTooltipTex^.h - 40));

bSelected:= false;
if AMxShift = 0 then DrawSprite(sprArrow, CursorPoint.X, cScreenHeight - CursorPoint.Y, (RealTicks shr 6) mod 8)
end;

procedure MoveCamera; forward;

procedure DrawWater(Alpha: byte; OffsetY: LongInt);
var VertexBuffer: array [0..3] of TVertex2f;
    r: TSDL_Rect;
    lw, lh: GLfloat;
begin
WaterColorArray[0].a := Alpha;
WaterColorArray[1].a := Alpha;
WaterColorArray[2].a := Alpha;
WaterColorArray[3].a := Alpha;

lw:= cScreenWidth / cScaleFactor;
lh:= trunc(cScreenHeight / cScaleFactor) + cScreenHeight div 2 + 16;
// Water
r.y:= OffsetY + WorldDy + cWaterLine;
if WorldDy < trunc(cScreenHeight / cScaleFactor) + cScreenHeight div 2 - cWaterLine then
    begin
    if r.y < 0 then r.y:= 0;

    glDisable(GL_TEXTURE_2D);
    VertexBuffer[0].X:= -lw;
    VertexBuffer[0].Y:= r.y;
    VertexBuffer[1].X:= lw;
    VertexBuffer[1].Y:= r.y;
    VertexBuffer[2].X:= lw;
    VertexBuffer[2].Y:= lh;
    VertexBuffer[3].X:= -lw;
    VertexBuffer[3].Y:= lh;

    glEnableClientState (GL_COLOR_ARRAY);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, @WaterColorArray[0]);

    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);

    glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);

    glColor4f(1, 1, 1, 1); // disable coloring
    glEnable(GL_TEXTURE_2D)
    end
end;

procedure DrawWaves(Dir, dX, dY: LongInt; Tint: GLfloat);
var VertexBuffer, TextureBuffer: array [0..3] of TVertex2f;
    lw, waves, shift: GLfloat;
begin
lw:= cScreenWidth / cScaleFactor;
waves:= lw * 2 / cWaveWidth;

glColor4f(
      (Tint * WaterColorArray[2].r / 255) + (1-Tint)
    , (Tint * WaterColorArray[2].g / 255) + (1-Tint)
    , (Tint * WaterColorArray[2].b / 255) + (1-Tint)
    , 1
);

glBindTexture(GL_TEXTURE_2D, SpritesData[sprWater].Texture^.id);

VertexBuffer[0].X:= -lw;
VertexBuffer[0].Y:= cWaterLine + WorldDy + dY;
VertexBuffer[1].X:= lw;
VertexBuffer[1].Y:= VertexBuffer[0].Y;
VertexBuffer[2].X:= lw;
VertexBuffer[2].Y:= VertexBuffer[0].Y + SpritesData[sprWater].Height;
VertexBuffer[3].X:= -lw;
VertexBuffer[3].Y:= VertexBuffer[2].Y;

shift:= - lw / cWaveWidth;
TextureBuffer[0].X:= shift + (( - WorldDx + LongInt(RealTicks shr 6) * Dir + dX) mod cWaveWidth) / (cWaveWidth - 1);
TextureBuffer[0].Y:= 0;
TextureBuffer[1].X:= TextureBuffer[0].X + waves;
TextureBuffer[1].Y:= TextureBuffer[0].Y;
TextureBuffer[2].X:= TextureBuffer[1].X;
TextureBuffer[2].Y:= SpritesData[sprWater].Texture^.ry;
TextureBuffer[3].X:= TextureBuffer[0].X;
TextureBuffer[3].Y:= TextureBuffer[2].Y;

glEnableClientState(GL_VERTEX_ARRAY);
glEnableClientState(GL_TEXTURE_COORD_ARRAY);

glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);
glTexCoordPointer(2, GL_FLOAT, 0, @TextureBuffer[0]);
glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

glDisableClientState(GL_TEXTURE_COORD_ARRAY);
glDisableClientState(GL_VERTEX_ARRAY);
glColor4f(1, 1, 1, 1);


{for i:= -1 to cWaterSprCount do
    DrawSprite(sprWater,
        i * cWaveWidth + ((WorldDx + (RealTicks shr 6) * Dir + dX) mod cWaveWidth) - (cScreenWidth div 2),
        cWaterLine + WorldDy + dY,
        0)}
end;

procedure DrawRepeated(spr, sprL, sprR: TSprite; Shift, OffsetY: LongInt);
var i, w, sw: LongInt;
begin
sw:= round(cScreenWidth / cScaleFactor);
if (SpritesData[sprL].Texture = nil) or (SpritesData[sprR].Texture = nil) then
    begin
    w:= SpritesData[spr].Width;
    i:= Shift mod w;
    if i > 0 then dec(i, w);
    dec(i, w * (sw div w + 1));
    repeat
        DrawSprite(spr, i, WorldDy + LAND_HEIGHT - SpritesData[spr].Height - OffsetY, 0);
        inc(i, w)
    until i > sw
    end else
    begin
    w:= SpritesData[spr].Width;
    dec(Shift, w div 2);
    DrawSprite(spr, Shift, WorldDy + LAND_HEIGHT - SpritesData[spr].Height - OffsetY, 0);

    sw:= round(cScreenWidth / cScaleFactor);
    
    i:= Shift - SpritesData[sprL].Width;
    while i >= -sw - SpritesData[sprL].Width do
        begin
        DrawSprite(sprL, i, WorldDy + LAND_HEIGHT - SpritesData[sprL].Height - OffsetY, 0);
        dec(i, SpritesData[sprL].Width);
        end;
        
    i:= Shift + w;
    while i <= sw do
        begin
        DrawSprite(sprR, i, WorldDy + LAND_HEIGHT - SpritesData[sprR].Height - OffsetY, 0);
        inc(i, SpritesData[sprR].Width)
        end
    end
end;


procedure DrawWorld(Lag: LongInt);
var i, t: LongInt;
    r: TSDL_Rect;
    tdx, tdy: Double;
    grp: TCapGroup;
    s: string[15];
    highlight: Boolean;
    offset, offsetX, offsetY, screenBottom: LongInt;
    scale: GLfloat;
begin
if ZoomValue < zoom then
    begin
    zoom:= zoom - 0.002 * Lag;
    if ZoomValue > zoom then zoom:= ZoomValue
    end else
if ZoomValue > zoom then
    begin
    zoom:= zoom + 0.002 * Lag;
    if ZoomValue < zoom then zoom:= ZoomValue
    end;

screenBottom:= WorldDy - trunc(cScreenHeight/cScaleFactor) - (cScreenHeight div 2) + cWaterLine;

// Sky
glClear(GL_COLOR_BUFFER_BIT);
glEnable(GL_BLEND);
glEnable(GL_TEXTURE_2D);
//glPushMatrix;
//glScalef(1.0, 1.0, 1.0);

if not isPaused then MoveCamera;

if not cReducedQuality then
    begin
    // background
    DrawRepeated(sprSky, sprSkyL, sprSkyR, (WorldDx + LAND_WIDTH div 2) * 3 div 8, 0);
    DrawRepeated(sprHorizont, sprHorizontL, sprHorizontR, (WorldDx + LAND_WIDTH div 2) * 3 div 5,  - cWaveHeight - screenBottom div 10);

    DrawVisualGears(0);
    end;

// Waves
offsetY:= 10 * min(0, -145 - screenBottom);
DrawWater(255, offsetY div 35);
DrawWaves( 1,  0 - WorldDx div 32, - cWaveHeight + offsetY div 35, 0.25);
DrawWaves( -1,  25 + WorldDx div 25, - cWaveHeight + offsetY div 38, 0.19);
DrawWaves( 1,  75 - WorldDx div 19, - cWaveHeight + offsetY div 45, 0.14);
DrawWaves(-1, 100 + WorldDx div 14, - cWaveHeight + offsetY div 70, 0.09);


DrawLand(WorldDx, WorldDy);

DrawWater(255, 0);

// Attack bar
if CurrentTeam <> nil then
    case AttackBar of
(*        1: begin
        r:= StuffPoz[sPowerBar];
        {$WARNINGS OFF}
        r.w:= (CurrentHedgehog^.Gear^.Power * 256) div cPowerDivisor;
        {$WARNINGS ON}
        DrawSpriteFromRect(r, cScreenWidth - 272, cScreenHeight - 48, 16, 0, Surface);
        end;*)
        2: with CurrentHedgehog^ do
                begin
                tdx:= hwSign(Gear^.dX) * Sin(Gear^.Angle * Pi / cMaxAngle);
                tdy:= - Cos(Gear^.Angle * Pi / cMaxAngle);
                for i:= (Gear^.Power * 24) div cPowerDivisor downto 0 do
                    DrawSprite(sprPower,
                            hwRound(Gear^.X) + round(WorldDx + tdx * (24 + i * 2)) - 16,
                            hwRound(Gear^.Y) + round(WorldDy + tdy * (24 + i * 2)) - 12,
                            i)
                end
        end;

DrawVisualGears(1);

DrawGears;

DrawVisualGears(2);

DrawWater(cWaterOpacity, 0);

// Waves
DrawWaves( 1, 25 - WorldDx div 9, - cWaveHeight, 0.05);
//DrawWater(cWaterOpacity, - offsetY div 40);
DrawWaves(-1, 50 + WorldDx div 6, - cWaveHeight - offsetY div 40, 0.03);
DrawWater(cWaterOpacity, - offsetY div 20);
DrawWaves( 1, 75 - WorldDx div 4, - cWaveHeight - offsetY div 20, 0.01);
DrawWater(cWaterOpacity, - offsetY div 10);
DrawWaves( -1, 25 + WorldDx div 3, - cWaveHeight - offsetY div 10, 0);


{$WARNINGS OFF}
// Target
if (TargetPoint.X <> NoPointX) and (CurrentTeam <> nil) and (CurrentHedgehog <> nil) then
    begin
    with PHedgehog(CurrentHedgehog)^ do
        begin
        if (Ammo^[CurSlot, CurAmmo].AmmoType = amBee) then
            DrawRotatedF(sprTargetBee, TargetPoint.X + WorldDx, TargetPoint.Y + WorldDy, 0, 0, (RealTicks shr 3) mod 360)
        else
            DrawRotatedF(sprTargetP, TargetPoint.X + WorldDx, TargetPoint.Y + WorldDy, 0, 0, (RealTicks shr 3) mod 360);
        end;
    end;
{$WARNINGS ON}

{$IFDEF IPHONEOS}
scale:= 1.5;
{$ELSE}
scale:= 2.0;
{$ENDIF}
SetScale(scale);


// Turn time
{$IFDEF IPHONEOS}
offsetX:= cScreenHeight - 13;
{$ELSE}
offsetX:= 48;
{$ENDIF}
if TurnTimeLeft <> 0 then
   begin
   i:= Succ(Pred(TurnTimeLeft) div 1000);
   if i>99 then t:= 112
      else if i>9 then t:= 96
                  else t:= 80;
   DrawSprite(sprFrame, -(cScreenWidth shr 1) + t, cScreenHeight - offsetX, 1);
   while i > 0 do
         begin
         dec(t, 32);
         DrawSprite(sprBigDigit, -(cScreenWidth shr 1) + t, cScreenHeight - offsetX, i mod 10);
         i:= i div 10
         end;
   DrawSprite(sprFrame, -(cScreenWidth shr 1) + t - 4, cScreenHeight - offsetX, 0);
   end;

{$IFNDEF IPHONEOS}
// Timetrial
if ((TrainingFlags and tfTimeTrial) <> 0) and (TimeTrialStartTime > 0) then
    begin
    if TimeTrialStopTime = 0 then i:= RealTicks - TimeTrialStartTime else i:= TimeTrialStopTime - TimeTrialStartTime;
    t:= 272;
    // right frame
    DrawSprite(sprFrame, -cScreenWidth div 2 + t, 8, 1);
    dec(t, 32);
    // 1 ms
    DrawSprite(sprBigDigit, -cScreenWidth div 2 + t, 8, i mod 10); 
    dec(t, 32);
    i:= i div 10;
    // 10 ms
    DrawSprite(sprBigDigit, -cScreenWidth div 2 + t, 8, i mod 10);
    dec(t, 32);
    i:= i div 10;
    // 100 ms
    DrawSprite(sprBigDigit, -cScreenWidth div 2 + t, 8, i mod 10);
    dec(t, 16);
    // Point
    DrawSprite(sprBigDigit, -cScreenWidth div 2 + t, 8, 11);
    dec(t, 32);
    i:= i div 10;
    // 1 s
    DrawSprite(sprBigDigit, -cScreenWidth div 2 + t, 8, i mod 10);
    dec(t, 32);
    i:= i div 10;
    // 10s
    DrawSprite(sprBigDigit, -cScreenWidth div 2 + t, 8, i mod 6);
    dec(t, 16);
    // Point
    DrawSprite(sprBigDigit, -cScreenWidth div 2 + t, 8, 10);
    dec(t, 32);
    i:= i div 6;
    // 1 m
    DrawSprite(sprBigDigit, -cScreenWidth div 2 + t, 8, i mod 10);
    dec(t, 32);
    i:= i div 10;
    // 10 m
    DrawSprite(sprBigDigit, -cScreenWidth div 2 + t, 8, i mod 10);
    // left frame
    DrawSprite(sprFrame, -cScreenWidth div 2 + t - 4, 8, 0);
    end;
{$ENDIF}

// Captions
{$IFDEF IPHONEOS}
offset:= 40;
{$ELSE}
if ((TrainingFlags and tfTimeTrial) <> 0) and (TimeTrialStartTime > 0) then offset:= 48
else offset:= 8;
{$ENDIF}

    for grp:= Low(TCapGroup) to High(TCapGroup) do
        with Captions[grp] do
            if Tex <> nil then
            begin
                DrawCentered(0, offset, Tex);
                inc(offset, Tex^.h + 2);
                if EndTime <= RealTicks then
                begin
                    FreeTexture(Tex);
                    Tex:= nil;
                    EndTime:= 0
                end;
            end;

// Teams Healths
for t:= 0 to Pred(TeamsCount) do
   with TeamsArray[t]^ do
      begin
      highlight:= bShowFinger and (CurrentTeam = TeamsArray[t]) and ((RealTicks mod 1000) < 500);
      
      if highlight then
         glColor4f(((Clan^.Color shr 16) and $ff) / $ff, ((Clan^.Color shr 8) and $ff) / $ff, (Clan^.Color and $ff) / $ff, 1);

      // draw name
      DrawTexture(-NameTagTex^.w - 16, cScreenHeight + DrawHealthY, NameTagTex);
      
      // draw flag
      DrawTexture(-14, cScreenHeight + DrawHealthY, FlagTex);
      
      // draw health bar
      r.x:= 0;
      r.y:= 0;
      r.w:= 2 + TeamHealthBarWidth;
      r.h:= HealthTex^.h;
      DrawFromRect(14, cScreenHeight + DrawHealthY, @r, HealthTex);

      // draw health bar's right border
      inc(r.x, cTeamHealthWidth + 2);
      r.w:= 3;
      DrawFromRect(TeamHealthBarWidth + 16, cScreenHeight + DrawHealthY, @r, HealthTex);
      // if highlighted, draw flag and other contents again to keep their colors
      // this approach should be faster than drawing all borders one by one tinted or not
      if highlight then
         begin
         glColor4f(1, 1, 1, 1);

         // draw name
         r.x:= 2;
         r.y:= 2;
         r.w:= NameTagTex^.w - 4;
         r.h:= NameTagTex^.h - 4;
         DrawFromRect(-NameTagTex^.w - 14, cScreenHeight + DrawHealthY + 2, @r, NameTagTex);
         // draw flag
         r.w:= 22;
         r.h:= 15;
         DrawFromRect(-12, cScreenHeight + DrawHealthY + 2, @r, FlagTex);
         // draw health bar
         r.w:= TeamHealthBarWidth + 1;
         r.h:= HealthTex^.h - 4;
         DrawFromRect(16, cScreenHeight + DrawHealthY + 2, @r, HealthTex);
         end;
      end;

// Lag alert
if isInLag then DrawSprite(sprLag, 32 - (cScreenWidth shr 1), 32, (RealTicks shr 7) mod 12);

// Wind bar
{$IFDEF IPHONEOS}
offsetX:= cScreenHeight - 13;
offsetY:= (cScreenWidth shr 1) + 74;
{$ELSE}
offsetX:= 30;
offsetY:= 180;
{$ENDIF}
DrawSprite(sprWindBar, (cScreenWidth shr 1) - offsetY, cScreenHeight - offsetX, 0);
if WindBarWidth > 0 then
   begin
   {$WARNINGS OFF}
   r.x:= 8 - (RealTicks shr 6) mod 8;
   {$WARNINGS ON}
   r.y:= 0;
   r.w:= WindBarWidth;
   r.h:= 13;
   DrawSpriteFromRect(sprWindR, r, (cScreenWidth shr 1) - offsetY + 77, cScreenHeight - offsetX + 2, 13, 0);
   end else
 if WindBarWidth < 0 then
   begin
   {$WARNINGS OFF}
   r.x:= (WindBarWidth + RealTicks shr 6) mod 8;
   {$WARNINGS ON}
   r.y:= 0;
   r.w:= - WindBarWidth;
   r.h:= 13;
   DrawSpriteFromRect(sprWindL, r, (cScreenWidth shr 1) - offsetY + 74 + WindBarWidth, cScreenHeight - offsetX + 2, 13, 0);
   end;

// AmmoMenu
if (AMxShift < 210) or bShowAmmoMenu then ShowAmmoMenu;

// Cursor
if isCursorVisible and bShowAmmoMenu then
   DrawSprite(sprArrow, CursorPoint.X, cScreenHeight - CursorPoint.Y, (RealTicks shr 6) mod 8);

DrawChat;

if fastUntilLag then DrawCentered(0, (cScreenHeight shr 1), SyncTexture);
if isPaused then DrawCentered(0, (cScreenHeight shr 1), PauseTexture);

if not isFirstFrame and (missionTimer <> 0) then
    begin
    if missionTimer > 0 then dec(missionTimer, Lag);
    if missionTimer < 0 then missionTimer:= 0; // avoid subtracting below 0
    if missionTex <> nil then
        DrawCentered(0, min((cScreenHeight shr 1) + 100, cScreenHeight - 48 - missionTex^.h), missionTex);
    end;

// fps
{$IFDEF IPHONEOS}
offset:= 8;
{$ELSE}
offset:= 10;
{$ENDIF}
inc(Frames);

if cShowFPS or (GameType = gmtDemo) then inc(CountTicks, Lag);
if (GameType = gmtDemo) and (CountTicks >= 1000) then
   begin
   i:=GameTicks div 60000;
   t:=(GameTicks-(i*60000)) div 1000;
   s:='';
   if i<10 then s:='0';
   s:= s+inttostr(i)+':';
   if t<10 then s:=s+'0';
   s:= s+inttostr(t);
   if timeTexture <> nil then FreeTexture(timeTexture);
   tmpSurface:= TTF_RenderUTF8_Blended(Fontz[fnt16].Handle, Str2PChar(s), cWhiteColorChannels);
   tmpSurface:= doSurfaceConversion(tmpSurface);
   timeTexture:= Surface2Tex(tmpSurface, false);
   SDL_FreeSurface(tmpSurface)
   end;

if timeTexture <> nil then
   DrawTexture((cScreenWidth shr 1) - 10 - timeTexture^.w, offset + timeTexture^.h+5, timeTexture);

if cShowFPS then
   begin
   if CountTicks >= 1000 then
      begin
      FPS:= Frames;
      Frames:= 0;
      CountTicks:= 0;
      s:= inttostr(FPS) + ' fps';
      if fpsTexture <> nil then FreeTexture(fpsTexture);
      tmpSurface:= TTF_RenderUTF8_Blended(Fontz[fnt16].Handle, Str2PChar(s), cWhiteColorChannels);
      tmpSurface:= doSurfaceConversion(tmpSurface);
      fpsTexture:= Surface2Tex(tmpSurface, false);
      SDL_FreeSurface(tmpSurface)
      end;
   if fpsTexture <> nil then
      DrawTexture((cScreenWidth shr 1) - 50, offset, fpsTexture);
   end;

if CountTicks >= 1000 then CountTicks:= 0;

// lag warning (?)
inc(SoundTimerTicks, Lag);
if SoundTimerTicks >= 50 then
   begin
   SoundTimerTicks:= 0;
   if cVolumeDelta <> 0 then
      begin
      str(ChangeVolume(cVolumeDelta), s);
      AddCaption(Format(trmsg[sidVolume], s), cWhiteColor, capgrpVolume)
      end
   end;

if GameState = gsConfirm then
    DrawCentered(0, (cScreenHeight shr 1), ConfirmTexture);

SetScale(zoom);

// Cursor
if isCursorVisible then
   begin
   if not bShowAmmoMenu then
     with CurrentHedgehog^ do
       if (Gear^.State and gstHHChooseTarget) <> 0 then
         begin
         i:= Ammo^[CurSlot, CurAmmo].Pos;
         with Ammoz[Ammo^[CurSlot, CurAmmo].AmmoType] do
           if PosCount > 1 then
              DrawSprite(PosSprite, CursorPoint.X - (SpritesData[PosSprite].Width shr 1),
                                    cScreenHeight - CursorPoint.Y - (SpritesData[PosSprite].Height shr 1),
                                    i);
         end;
   DrawSprite(sprArrow, CursorPoint.X, cScreenHeight - CursorPoint.Y, (RealTicks shr 6) mod 8)
   end;

glDisable(GL_TEXTURE_2D);

if ScreenFade <> sfNone then
    begin
    if not isFirstFrame then
        case ScreenFade of
            sfToBlack, sfToWhite:     if ScreenFadeValue + Lag * ScreenFadeSpeed < sfMax then
                                          inc(ScreenFadeValue, Lag * ScreenFadeSpeed)
                                      else
                                          ScreenFade:= sfNone;
            sfFromBlack, sfFromWhite: if ScreenFadeValue - Lag * ScreenFadeSpeed > 0 then
                                          dec(ScreenFadeValue, Lag * ScreenFadeSpeed)
                                      else
                                          ScreenFade:= sfNone;
            end;
    if ScreenFade <> sfNone then
        begin
        case ScreenFade of
            sfToBlack, sfFromBlack: glColor4f(0, 0, 0, ScreenFadeValue / 1000);
            sfToWhite, sfFromWhite: glColor4f(1, 1, 1, ScreenFadeValue / 1000);
            end;
        glBegin(GL_TRIANGLE_FAN);
        glVertex3f(-cScreenWidth, cScreenHeight, 0);
        glVertex3f(-cScreenWidth, 0, 0);
        glVertex3f(cScreenWidth, 0, 0);
        glVertex3f(cScreenWidth, cScreenHeight, 0);
        glEnd;
        glColor4f(1, 1, 1, 1)
        end
    end;

glDisable(GL_BLEND);
isFirstFrame:= false
end;

procedure AddCaption(s: shortstring; Color: Longword; Group: TCapGroup);
begin
//if Group in [capgrpGameState] then WriteLnToConsole(s);
if Captions[Group].Tex <> nil then FreeTexture(Captions[Group].Tex);

Captions[Group].Tex:= RenderStringTex(s, Color, fntBig);

case Group of
    capgrpGameState: Captions[Group].EndTime:= RealTicks + 2200
    else
    Captions[Group].EndTime:= RealTicks + 1400 + LongWord(Captions[Group].Tex^.w) * 3;
    end;
end;

procedure MoveCamera;
const PrevSentPointTime: LongWord = 0;
var EdgesDist,  wdy: LongInt;
begin
if (not (CurrentTeam^.ExtDriven and isCursorVisible and not bShowAmmoMenu)) and cHasFocus then
    begin
    SDL_GetMouseState(@CursorPoint.X, @CursorPoint.Y);
    CursorPoint.X:= CursorPoint.X - (cScreenWidth shr 1);
    CursorPoint.Y:= cScreenHeight - CursorPoint.Y;
    end;

if (not PlacingHogs) and (FollowGear <> nil) and (not isCursorVisible) and (not fastUntilLag) then
    if abs(CursorPoint.X - prevPoint.X) + abs(CursorPoint.Y - prevpoint.Y) > 4 then
        begin
        FollowGear:= nil;
        prevPoint:= CursorPoint;
        exit
        end
        else begin
        CursorPoint.X:= (prevPoint.X * 7 + hwRound(FollowGear^.X) + hwSign(FollowGear^.dX) * 100 + WorldDx) div 8;
        CursorPoint.Y:= (prevPoint.Y * 7 + cScreenHeight - (hwRound(FollowGear^.Y) + WorldDy)) div 8;
        end;

wdy:= trunc(cScreenHeight / cScaleFactor) + cScreenHeight div 2 - cWaterLine - cVisibleWater;
if WorldDy < wdy then WorldDy:= wdy;

if ((CursorPoint.X = prevPoint.X) and (CursorPoint.Y = prevpoint.Y)) then exit;

if AMxShift < 210 then
    begin
    if CursorPoint.X < cScreenWidth div 2 + AMxShift - 175 then CursorPoint.X:= cScreenWidth div 2 + AMxShift - 175;
    if CursorPoint.X > cScreenWidth div 2 + AMxShift - 10 then CursorPoint.X:= cScreenWidth div 2 + AMxShift - 10;
    if CursorPoint.Y > 75 + SlotsNum * 33 then CursorPoint.Y:= 75 + SlotsNum * 33;
    if CursorPoint.Y < 76 then CursorPoint.Y:= 76;
    prevPoint:= CursorPoint;
    if cHasFocus then SDL_WarpMouse(CursorPoint.X + cScreenWidth div 2, cScreenHeight - CursorPoint.Y);
    exit
    end;

if isCursorVisible then
    begin
    if (not CurrentTeam^.ExtDriven) and (GameTicks >= PrevSentPointTime + cSendCursorPosTime) then
        begin
        SendIPCXY('P', CursorPoint.X - WorldDx, cScreenHeight - CursorPoint.Y - WorldDy);
        PrevSentPointTime:= GameTicks
        end;
    end;

if isCursorVisible or (FollowGear <> nil) then
   begin
   if isCursorVisible then EdgesDist:= cCursorEdgesDist
                      else EdgesDist:= cGearScrEdgesDist;
   if CursorPoint.X < - cScreenWidth div 2 + EdgesDist then
         begin
         WorldDx:= WorldDx - CursorPoint.X - cScreenWidth div 2 + EdgesDist;
         CursorPoint.X:= - cScreenWidth div 2 + EdgesDist
         end else
      if CursorPoint.X > cScreenWidth div 2 - EdgesDist then
         begin
         WorldDx:= WorldDx - CursorPoint.X + cScreenWidth div 2 - EdgesDist;
         CursorPoint.X:= cScreenWidth div 2 - EdgesDist
         end;
      if CursorPoint.Y < EdgesDist then
         begin
         WorldDy:= WorldDy + CursorPoint.Y - EdgesDist;
         CursorPoint.Y:= EdgesDist
         end else
      if CursorPoint.Y > cScreenHeight - EdgesDist then
         begin
         WorldDy:= WorldDy + CursorPoint.Y - cScreenHeight + EdgesDist;
         CursorPoint.Y:= cScreenHeight - EdgesDist
         end;
   end else
   if cHasFocus then
      begin
      WorldDx:= WorldDx - CursorPoint.X + prevPoint.X;
      WorldDy:= WorldDy + CursorPoint.Y - prevPoint.Y;
      CursorPoint.X:= 0;
      CursorPoint.Y:= cScreenHeight div 2;
      end;

prevPoint:= CursorPoint;
if cHasFocus then SDL_WarpMouse(CursorPoint.X + (cScreenWidth shr 1), cScreenHeight - CursorPoint.Y);
if WorldDy > LAND_HEIGHT + 1024 then WorldDy:= LAND_HEIGHT + 1024;
if WorldDy < wdy then WorldDy:= wdy;
if WorldDx < - LAND_WIDTH - 1024 then WorldDx:= - LAND_WIDTH - 1024;
if WorldDx > 1024 then WorldDx:= 1024;
end;

procedure ShowMission(caption, subcaption, text: ansistring; icon, time : LongInt);
var r: TSDL_Rect;
begin
r.w:= 32;
r.h:= 32;

if time = 0 then time:= 5000;
missionTimer:= time;
if missionTex <> nil then FreeTexture(missionTex);

if icon > -1 then
    begin
    r.x:= 0;
    r.y:= icon * 32;
    missionTex:= RenderHelpWindow(caption, subcaption, text, '', 0, MissionIcons, @r)
    end
else
    begin
    r.x:= ((-icon - 1) shr 5) * 32;
    r.y:= ((-icon - 1) mod 32) * 32;
    missionTex:= RenderHelpWindow(caption, subcaption, text, '', 0, SpritesData[sprAMAmmos].Surface, @r)
    end;
end;

procedure HideMission;
begin
    missionTimer:= 0;
    if missionTex <> nil then FreeTexture(missionTex);
end;

procedure ShakeCamera(amount: LongWord);
begin
    amount:= max(1, amount);
    WorldDx:= WorldDx - amount + LongInt(getRandom(1 + amount * 2));
    WorldDy:= WorldDy - amount + LongInt(getRandom(1 + amount * 2));
end;

procedure initModule;
begin
    fpsTexture:= nil;
    FollowGear:= nil;
    WindBarWidth:= 0;
    bShowAmmoMenu:= false;
    bSelected:= false;
    bShowFinger:= false;
    Frames:= 0;
    WorldDx:= -512;
    WorldDy:= -256;
    
    FPS:= 0;
    CountTicks:= 0;
    SoundTimerTicks:= 0;
    prevPoint.X:= 0;
    prevPoint.Y:= 0;
    missionTimer:= 0;
    
    FillChar(Captions, sizeof(Captions), 0)
end;

procedure freeModule;
begin
end;

end.
