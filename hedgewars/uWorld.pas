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
    AFRToggle: Boolean;
    WaterColor, DeepWaterColor: TSDL_Color;
    WorldDx: LongInt;
    WorldDy: LongInt;
    SkyOffset: LongInt;
    HorizontOffset: LongInt;
    bAFRRight: Boolean;
{$IFDEF COUNTTICKS}
    cntTicks: LongWord;
{$ENDIF}
    cOffsetY: LongInt;

procedure initModule;
procedure freeModule;

procedure InitWorld;
procedure DrawWorld(Lag: LongInt);
procedure DrawWorldStereo(Lag: LongInt; RM: TRenderMode);
procedure AddCaption(s: shortstring; Color: Longword; Group: TCapGroup);
procedure ShowMission(caption, subcaption, text: ansistring; icon, time : LongInt);
procedure HideMission;
procedure ShakeCamera(amount: LongWord);
procedure MoveCamera;

implementation
uses    uStore, uMisc, uTeams, uIO, uKeys, uLocale, uSound, uAmmos, uVisualGears, uChat, uLandTexture, uLand, GLunit;

type TCaptionStr = record
                   Tex: PTexture;
                   EndTime: LongWord;
                   end;

var cWaveWidth, cWaveHeight: LongInt;
    Captions: array[TCapGroup] of TCaptionStr;
    AMSlotSize, AMxOffset, AMyOffset, AMWidth, AMxShift, SlotsNum: LongInt;
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
    stereoDepth: GLfloat = 0;

const cStereo_Sky     = 0.0500;
      cStereo_Horizon = 0.0250;
      cStereo_Water   = 0.0125;

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
g:= AddGoal(g, gfResetHealth, gidResetHealth);
g:= AddGoal(g, gfAISurvival, gidAISurvival);
g:= AddGoal(g, gfInfAttack, gidInfAttack);
g:= AddGoal(g, gfResetWeps, gidResetWeps);
g:= AddGoal(g, gfPerHogAmmo, gidPerHogAmmo);

// modified damage modificator?
if cDamagePercent <> 100 then
    g:= AddGoal(g, gfAny, gidDamageModifier, cDamagePercent);

// fade in
ScreenFade:= sfFromBlack;
ScreenFadeValue:= sfMax;
ScreenFadeSpeed:= 1;

// modified mine timers?
if cMinesTime <> 3 then
    begin
    if cMinesTime = 0 then
        g:= AddGoal(g, gfAny, gidNoMineTimer)
    else if cMinesTime < 0 then
        g:= AddGoal(g, gfAny, gidRandomMineTimer)
    else
        g:= AddGoal(g, gfAny, gidMineTimer, cMinesTime);
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
AMSlotSize:= 33;
{$IFDEF IPHONEOS}
AMxOffset:= 10;
AMyOffset:= 10 + 123;   // moved downwards
AMWidth:= (cMaxSlotAmmoIndex + 1) * AMSlotSize + AMxOffset;
{$ELSE}
AMxOffset:= 10;
AMyOffset:= 60;
AMWidth:= (cMaxSlotAmmoIndex + 2) * AMSlotSize + AMxOffset;
{$ENDIF}
AMxShift:= AMWidth;
SkyOffset:= 0;
HorizontOffset:= 0;
end;


procedure ShowAmmoMenu;
const MENUSPEED = 15;
const BORDERSIZE = 2;
var x, y, i, t, g: LongInt;
    Slot, Pos, STurns: LongInt;
    Ammo: PHHAmmo;
begin
if (TurnTimeLeft = 0) or (not CurrentTeam^.ExtDriven and (((CurAmmoGear = nil) or ((Ammoz[CurAmmoGear^.AmmoType].Ammo.Propz and ammoprop_AltAttack) = 0)) and hideAmmoMenu)) then
    bShowAmmoMenu:= false;
if bShowAmmoMenu then
   begin
   FollowGear:= nil;
   if AMxShift = AMWidth then prevPoint.X:= 0;
   if (cReducedQuality and rqSlowMenu) <> 0 then
       AMxShift:= 0
   else
       if AMxShift > MENUSPEED then
      	   dec(AMxShift, MENUSPEED)
       else
           AMxShift:= 0;
   end else
   begin
   if AMxShift = 0 then
      begin
      CursorPoint.X:= cScreenWidth shr 1;
      CursorPoint.Y:= cScreenHeight shr 1;
      prevPoint:= CursorPoint;
      SDL_WarpMouse(CursorPoint.X  + cScreenWidth div 2, cScreenHeight - CursorPoint.Y)
      end;
   if (cReducedQuality and rqSlowMenu) <> 0 then
       AMxShift:= AMWidth
   else
       if AMxShift < (AMWidth - MENUSPEED) then
           inc(AMxShift, MENUSPEED)
       else
           AMxShift:= AMWidth;
   end;
Ammo:= nil;
if (CurrentTeam <> nil) and (CurrentHedgehog <> nil) and (not CurrentTeam^.ExtDriven) and (CurrentHedgehog^.BotLevel = 0) then
   Ammo:= CurrentHedgehog^.Ammo
else if (LocalAmmo <> -1) then
   Ammo:= GetAmmoByNum(LocalAmmo);
Pos:= -1;
if Ammo = nil then
    begin
    bShowAmmoMenu:= false;
    exit
    end;
SlotsNum:= 0;
x:= (cScreenWidth shr 1) - AMWidth + AMxShift;

{$IFDEF IPHONEOS}
Slot:= cMaxSlotIndex;
x:= x - cOffsetY;
y:= AMyOffset;
dec(y, BORDERSIZE);
DrawSprite(sprAMCorners, x - BORDERSIZE, y, 0);
for i:= 0 to cMaxSlotAmmoIndex do
	DrawSprite(sprAMBorderHorizontal, x + i * AMSlotSize, y, 0);
DrawSprite(sprAMCorners, x + AMWidth - AMxOffset, y, 1);
inc(y, BORDERSIZE);

for i:= 0 to cMaxSlotIndex do
    if ((i = 0) and (Ammo^[i, 1].Count > 0)) or ((i <> 0) and (Ammo^[i, 0].Count > 0)) then
        begin
        if (cScreenHeight - CursorPoint.Y >= y) and (cScreenHeight - CursorPoint.Y <= y + AMSlotSize) then Slot:= i;
        inc(SlotsNum);
        DrawSprite(sprAMBorderVertical, x - BORDERSIZE, y, 0);
        t:= 0;
        g:= 0;
        while (t <= cMaxSlotAmmoIndex) and (Ammo^[i, t].Count > 0) do
            begin
            DrawSprite(sprAMSlot, x + g * AMSlotSize, y, 1);
            if (Ammo^[i, t].AmmoType <> amNothing) then
                begin
                STurns:= Ammoz[Ammo^[i, t].AmmoType].SkipTurns - CurrentTeam^.Clan^.TurnNumber;

                if STurns >= 0 then
                    begin
                    DrawSprite(sprAMAmmosBW, x + g * AMSlotSize, y + 1, LongInt(Ammo^[i, t].AmmoType)-1);
                    if STurns < 100 then DrawSprite(sprTurnsLeft, x + (g + 1) * AMSlotSize - 16, y + AMSlotSize - 16, STurns);
                    end else
                    DrawSprite(sprAMAmmos, x + g * AMSlotSize, y + 1, LongInt(Ammo^[i, t].AmmoType)-1);
                if (Slot = i)
                and (CursorPoint.X >= x + g * AMSlotSize)
                and (CursorPoint.X <= x + (g + 1) * AMSlotSize) then
                    begin
                    if (STurns < 0) then DrawSprite(sprAMSlot, x + g * AMSlotSize, y, 0);
                    Pos:= t;
                    end;
                inc(g)
                end;
                inc(t)
            end;
        for g:= g to cMaxSlotAmmoIndex do
            DrawSprite(sprAMSlot, x + g * AMSlotSize, y, 1);
        DrawSprite(sprAMBorderVertical, x + AMWidth - AMxOffset, y, 1);
        inc(y, AMSlotSize);
        end;

DrawSprite(sprAMCorners, x - BORDERSIZE, y, 2);
for i:= 0 to cMaxSlotAmmoIndex do
	DrawSprite(sprAMBorderHorizontal, x + i * AMSlotSize, y, 1);
DrawSprite(sprAMCorners, x + AMWidth - AMxOffset, y, 3);
{$ELSE}
Slot:= 0;
y:= cScreenHeight - AMyOffset;
DrawSprite(sprAMCorners, x - BORDERSIZE, y, 2);
for i:= 0 to cMaxSlotAmmoIndex + 1 do
	DrawSprite(sprAMBorderHorizontal, x + i * AMSlotSize, y, 1);
DrawSprite(sprAMCorners, x + AMWidth - AMxOffset, y, 3);
dec(y, AMSlotSize);
DrawSprite(sprAMBorderVertical, x - BORDERSIZE, y, 0);
for i:= 0 to cMaxSlotAmmoIndex do
	DrawSprite(sprAMSlot, x + i * AMSlotSize, y, 2);
DrawSprite(sprAMSlot, x + (cMaxSlotAmmoIndex + 1) * AMSlotSize, y, 1);
DrawSprite(sprAMBorderVertical, x + AMWidth - AMxOffset, y, 1);

for i:= cMaxSlotIndex downto 0 do
    if ((i = 0) and (Ammo^[i, 1].Count > 0)) or ((i <> 0) and (Ammo^[i, 0].Count > 0)) then
        begin
        if (cScreenHeight - CursorPoint.Y >= y - AMSlotSize) and (cScreenHeight - CursorPoint.Y <= y) then Slot:= i;
        dec(y, AMSlotSize);
        inc(SlotsNum);
        DrawSprite(sprAMBorderVertical, x - BORDERSIZE, y, 0);
        DrawSprite(sprAMSlot, x, y, 1);
        DrawSprite(sprAMSlotKeys, x, y + 1, i);
        t:= 0;
        g:= 1;
        while (t <= cMaxSlotAmmoIndex) and (Ammo^[i, t].Count > 0) do
            begin
            DrawSprite(sprAMSlot, x + g * AMSlotSize, y, 1);
            if (Ammo^[i, t].AmmoType <> amNothing) then
                begin
                STurns:= Ammoz[Ammo^[i, t].AmmoType].SkipTurns - CurrentTeam^.Clan^.TurnNumber;

                if STurns >= 0 then
                    begin
                    DrawSprite(sprAMAmmosBW, x + g * AMSlotSize, y + 1, LongInt(Ammo^[i, t].AmmoType)-1);
                    if STurns < 100 then DrawSprite(sprTurnsLeft, x + (g + 1) * AMSlotSize - 16, y + AMSlotSize - 16, STurns);
                    end else
                    DrawSprite(sprAMAmmos, x + g * AMSlotSize, y + 1, LongInt(Ammo^[i, t].AmmoType)-1);
                if (Slot = i)
                and (CursorPoint.X >= x + g * AMSlotSize)
                and (CursorPoint.X <= x + (g + 1) * AMSlotSize) then
                    begin
                    if (STurns < 0) then DrawSprite(sprAMSlot, x + g * AMSlotSize, y, 0);
                    Pos:= t;
                    end;
                inc(g)
                end;
                inc(t)
            end;
        for g:= g to cMaxSlotAmmoIndex + 1 do
            DrawSprite(sprAMSlot, x + g * AMSlotSize, y, 1);
        DrawSprite(sprAMBorderVertical, x + AMWidth - AMxOffset, y, 1);
        end;

dec(y, BORDERSIZE);
DrawSprite(sprAMCorners, x - BORDERSIZE, y, 0);
for i:= 0 to cMaxSlotAmmoIndex + 1 do
	DrawSprite(sprAMBorderHorizontal, x + i * AMSlotSize, y, 0);
DrawSprite(sprAMCorners, x + AMWidth - AMxOffset, y, 1);
{$ENDIF}

if (Pos >= 0) then
    begin
    if (Ammo^[Slot, Pos].Count > 0) and (Ammo^[Slot, Pos].AmmoType <> amNothing) then
        begin
        if (amSel <> Ammo^[Slot, Pos].AmmoType) or (WeaponTooltipTex = nil) then
            begin
            amSel:= Ammo^[Slot, Pos].AmmoType;
            RenderWeaponTooltip(amSel)
            end;

{$IFDEF IPHONEOS}
        DrawTexture(cScreenWidth div 2 - (AMWidth - 10) + AMxShift, AMyOffset - 25, Ammoz[Ammo^[Slot, Pos].AmmoType].NameTex);

        if Ammo^[Slot, Pos].Count < AMMO_INFINITE then
            DrawTexture(cScreenWidth div 2 + AMxOffset - 45, AMyOffset - 25, CountTexz[Ammo^[Slot, Pos].Count]);
{$ELSE}
        DrawTexture(cScreenWidth div 2 - (AMWidth - 10) + AMxShift, cScreenHeight - AMyOffset - 25, Ammoz[Ammo^[Slot, Pos].AmmoType].NameTex);
        if Ammo^[Slot, Pos].Count < AMMO_INFINITE then
            DrawTexture(cScreenWidth div 2 + AMxOffset - 45, cScreenHeight - AMyOffset - 25, CountTexz[Ammo^[Slot, Pos].Count]);
{$ENDIF}

        if bSelected and (Ammoz[Ammo^[Slot, Pos].AmmoType].SkipTurns - CurrentTeam^.Clan^.TurnNumber < 0) then
            begin
            bShowAmmoMenu:= false;
            SetWeapon(Ammo^[Slot, Pos].AmmoType);
            bSelected:= false;
            FreeWeaponTooltip;
            exit
            end;
       end
    end
else
    FreeWeaponTooltip;
if (WeaponTooltipTex <> nil) and (AMxShift = 0) then
{$IFDEF IPHONEOS}
    ShowWeaponTooltip(x - WeaponTooltipTex^.w - 3, AMyOffset - 1);
{$ELSE}
    ShowWeaponTooltip(x - WeaponTooltipTex^.w - 3, min(y + 1, cScreenHeight - WeaponTooltipTex^.h - 40));
{$ENDIF}

bSelected:= false;
if AMxShift = 0 then DrawSprite(sprArrow, CursorPoint.X, cScreenHeight - CursorPoint.Y, (RealTicks shr 6) mod 8)
end;

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
        if r.y < 0 then
            r.y:= 0;

        glDisable(GL_TEXTURE_2D);
        VertexBuffer[0].X:= -lw;
        VertexBuffer[0].Y:= r.y;
        VertexBuffer[1].X:= lw;
        VertexBuffer[1].Y:= r.y;
        VertexBuffer[2].X:= lw;
        VertexBuffer[2].Y:= lh;
        VertexBuffer[3].X:= -lw;
        VertexBuffer[3].Y:= lh;

        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        glEnableClientState(GL_COLOR_ARRAY);
        glColorPointer(4, GL_UNSIGNED_BYTE, 0, @WaterColorArray[0]);

        glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);

        glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

        glDisableClientState(GL_COLOR_ARRAY);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glColor4ub($FF, $FF, $FF, $FF); // must not be Tint() as color array seems to stay active and color reset is required
        glEnable(GL_TEXTURE_2D);
    end;
end;

procedure DrawWaves(Dir, dX, dY: LongInt; tnt: Byte);
var VertexBuffer, TextureBuffer: array [0..3] of TVertex2f;
    lw, waves, shift: GLfloat;
begin
lw:= cScreenWidth / cScaleFactor;
waves:= lw * 2 / cWaveWidth;

Tint(LongInt(tnt) * WaterColorArray[2].r div 255 + 255 - tnt,
     LongInt(tnt) * WaterColorArray[2].g div 255 + 255 - tnt,
     LongInt(tnt) * WaterColorArray[2].b div 255 + 255 - tnt,
     255
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


glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);
glTexCoordPointer(2, GL_FLOAT, 0, @TextureBuffer[0]);
glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

Tint($FF, $FF, $FF, $FF);

{for i:= -1 to cWaterSprCount do
    DrawSprite(sprWater,
        i * cWaveWidth + ((WorldDx + (RealTicks shr 6) * Dir + dX) mod cWaveWidth) - (cScreenWidth div 2),
        cWaterLine + WorldDy + dY,
        0)}
end;

procedure DrawRepeated(spr, sprL, sprR: TSprite; Shift, OffsetY: LongInt);
var i, w, h, lw, lh, rw, rh, sw: LongInt;
begin
    sw:= round(cScreenWidth / cScaleFactor);
    if (SpritesData[sprL].Texture = nil) or (SpritesData[sprR].Texture = nil) then
    begin
        w:= SpritesData[spr].Width * SpritesData[spr].Texture^.Scale;
        h:= SpritesData[spr].Height * SpritesData[spr].Texture^.Scale;
        i:= Shift mod w;
        if i > 0 then dec(i, w);
        dec(i, w * (sw div w + 1));
        repeat
            DrawTexture(i, WorldDy + LAND_HEIGHT + OffsetY - h, SpritesData[spr].Texture, SpritesData[spr].Texture^.Scale);
            inc(i, w)
        until i > sw
    end
    else
    begin
        w:= SpritesData[spr].Width * SpritesData[spr].Texture^.Scale;
        h:= SpritesData[spr].Height * SpritesData[spr].Texture^.Scale;
        lw:= SpritesData[sprL].Width * SpritesData[spr].Texture^.Scale;
        lh:= SpritesData[sprL].Height * SpritesData[spr].Texture^.Scale;
        rw:= SpritesData[sprR].Width * SpritesData[spr].Texture^.Scale;
        rh:= SpritesData[sprR].Height * SpritesData[spr].Texture^.Scale;
        dec(Shift, w div 2);
        DrawTexture(Shift, WorldDy + LAND_HEIGHT + OffsetY - h, SpritesData[spr].Texture, SpritesData[spr].Texture^.Scale);

        i:= Shift - lw;
        while i >= -sw - lw do
        begin
            DrawTexture(i, WorldDy + LAND_HEIGHT + OffsetY - lh, SpritesData[sprL].Texture, SpritesData[sprL].Texture^.Scale);
            dec(i, lw);
        end;

        i:= Shift + w;
        while i <= sw do
        begin
            DrawTexture(i, WorldDy + LAND_HEIGHT + OffsetY - rh, SpritesData[sprR].Texture, SpritesData[sprR].Texture^.Scale);
            inc(i, rw)
        end
    end
end;


procedure DrawWorld(Lag: LongInt);
begin
    if not isPaused then
    begin
        if ZoomValue < zoom then
        begin
            zoom:= zoom - 0.002 * Lag;
            if ZoomValue > zoom then
                zoom:= ZoomValue
        end
        else
        if ZoomValue > zoom then
        begin
            zoom:= zoom + 0.002 * Lag;
            if ZoomValue < zoom then
                zoom:= ZoomValue
            end
        end
    else
        ZoomValue:= zoom;

    // Sky
    glClear(GL_COLOR_BUFFER_BIT);
    //glPushMatrix;
    //glScalef(1.0, 1.0, 1.0);

    if not isPaused then
        MoveCamera;

    if cStereoMode = smNone then
        begin
        glClear(GL_COLOR_BUFFER_BIT);
        DrawWorldStereo(Lag, rmDefault)
        end
    else if (cStereoMode = smAFR) then
        begin
        AFRToggle:= not AFRToggle;
        glClear(GL_COLOR_BUFFER_BIT);
        if AFRToggle then
            DrawWorldStereo(Lag, rmLeftEye)
        else
            DrawWorldStereo(Lag, rmRightEye)
        end
    else if (cStereoMode = smHorizontal) or (cStereoMode = smVertical) then
        begin
        // create left fb
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, framel);
        glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
        DrawWorldStereo(Lag, rmLeftEye);

        // create right fb
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, framer);
        glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
        DrawWorldStereo(0, rmRightEye);

        // detatch drawing from fbs
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
        glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
        SetScale(cDefaultZoomLevel);

        // draw left frame
        glBindTexture(GL_TEXTURE_2D, texl);
        glBegin(GL_QUADS);
            if cStereoMode = smHorizontal then
                begin
                glTexCoord2f(0.0, 0.0);
                glVertex2d(cScreenWidth / -2, cScreenHeight);
                glTexCoord2f(1.0, 0.0);
                glVertex2d(0, cScreenHeight);
                glTexCoord2f(1.0, 1.0);
                glVertex2d(0, 0);
                glTexCoord2f(0.0, 1.0);
                glVertex2d(cScreenWidth / -2, 0);
                end
            else
                begin
                glTexCoord2f(0.0, 0.0);
                glVertex2d(cScreenWidth / -2, cScreenHeight / 2);
                glTexCoord2f(1.0, 0.0);
                glVertex2d(cScreenWidth / 2, cScreenHeight / 2);
                glTexCoord2f(1.0, 1.0);
                glVertex2d(cScreenWidth / 2, 0);
                glTexCoord2f(0.0, 1.0);
                glVertex2d(cScreenWidth / -2, 0);
                end;
        glEnd();

        // draw right frame
        glBindTexture(GL_TEXTURE_2D, texr);
        glBegin(GL_QUADS);
            if cStereoMode = smHorizontal then
                begin
                glTexCoord2f(0.0, 0.0);
                glVertex2d(0, cScreenHeight);
                glTexCoord2f(1.0, 0.0);
                glVertex2d(cScreenWidth / 2, cScreenHeight);
                glTexCoord2f(1.0, 1.0);
                glVertex2d(cScreenWidth / 2, 0);
                glTexCoord2f(0.0, 1.0);
                glVertex2d(0, 0);
                end
            else
                begin
                glTexCoord2f(0.0, 0.0);
                glVertex2d(cScreenWidth / -2, cScreenHeight);
                glTexCoord2f(1.0, 0.0);
                glVertex2d(cScreenWidth / 2, cScreenHeight);
                glTexCoord2f(1.0, 1.0);
                glVertex2d(cScreenWidth / 2, cScreenHeight / 2);
                glTexCoord2f(0.0, 1.0);
                glVertex2d(cScreenWidth / -2, cScreenHeight / 2);
                end;
        glEnd();
        SetScale(zoom);
        end
    else
        begin
        // clear scene
        glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
        glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
        // draw left eye in red channel only
        if cStereoMode = smGreenRed then
            glColorMask(GL_FALSE, GL_TRUE, GL_FALSE, GL_TRUE)
        else if cStereoMode = smBlueRed then
            glColorMask(GL_FALSE, GL_FALSE, GL_TRUE, GL_TRUE)
        else if cStereoMode = smCyanRed then
            glColorMask(GL_FALSE, GL_TRUE, GL_TRUE, GL_TRUE)
        else
            glColorMask(GL_TRUE, GL_FALSE, GL_FALSE, GL_TRUE);
        DrawWorldStereo(Lag, rmLeftEye);
        // draw right eye in selected channel(s) only
        if cStereoMode = smRedGreen then
            glColorMask(GL_FALSE, GL_TRUE, GL_FALSE, GL_TRUE)
        else if cStereoMode = smRedBlue then
            glColorMask(GL_FALSE, GL_FALSE, GL_TRUE, GL_TRUE)
        else if cStereoMode = smRedCyan then
            glColorMask(GL_FALSE, GL_TRUE, GL_TRUE, GL_TRUE)
        else
            glColorMask(GL_TRUE, GL_FALSE, GL_FALSE, GL_TRUE);
        DrawWorldStereo(Lag, rmRightEye);
        end
end;

procedure ChangeDepth(rm: TRenderMode; d: GLfloat);
begin
    d:= d / 5;
    if rm = rmDefault then exit
    else if rm = rmLeftEye then d:= -d;
    stereoDepth:= stereoDepth + d;
    glMatrixMode(GL_PROJECTION);
    glTranslatef(d, 0, 0);
    glMatrixMode(GL_MODELVIEW)
end;
 
procedure ResetDepth(rm: TRenderMode);
begin
    if rm = rmDefault then exit;
    glMatrixMode(GL_PROJECTION);
    glTranslatef(-stereoDepth, 0, 0);
    glMatrixMode(GL_MODELVIEW);
    stereoDepth:= 0;
end;
 
procedure DrawWorldStereo(Lag: LongInt; RM: TRenderMode);
var i, t: LongInt;
    r: TSDL_Rect;
    tdx, tdy: Double;
    grp: TCapGroup;
    s: string[15];
    highlight: Boolean;
    offset, offsetX, offsetY, screenBottom: LongInt;
    VertexBuffer: array [0..3] of TVertex2f;
begin
    if (cReducedQuality and rqNoBackground) = 0 then
    begin
        // Offsets relative to camera - spare them to wimpier cpus, no bg or flakes for them anyway
        ScreenBottom:= (WorldDy - trunc(cScreenHeight/cScaleFactor) - (cScreenHeight div 2) + cWaterLine);
        offsetY:= 10 * min(0, -145 - ScreenBottom);
        SkyOffset:= offsetY div 35 + cWaveHeight;
        HorizontOffset:= SkyOffset;
        if ScreenBottom > SkyOffset then
            HorizontOffset:= HorizontOffset + ((ScreenBottom-SkyOffset) div 20);

        // background
        ChangeDepth(RM, cStereo_Sky);
        DrawRepeated(sprSky, sprSkyL, sprSkyR, (WorldDx + LAND_WIDTH div 2) * 3 div 8, SkyOffset);
        ChangeDepth(RM, -cStereo_Horizon);
        DrawRepeated(sprHorizont, sprHorizontL, sprHorizontR, (WorldDx + LAND_WIDTH div 2) * 3 div 5, HorizontOffset);
    end;

    DrawVisualGears(0);

    if (cReducedQuality and rq2DWater) = 0 then
    begin
        // Waves
        DrawWater(255, SkyOffset); 
        ChangeDepth(RM, -cStereo_Water);
        DrawWaves( 1,  0 - WorldDx div 32, - cWaveHeight + offsetY div 35, 64);
        ChangeDepth(RM, -cStereo_Water);
        DrawWaves( -1,  25 + WorldDx div 25, - cWaveHeight + offsetY div 38, 48);
        ChangeDepth(RM, -cStereo_Water);
        DrawWaves( 1,  75 - WorldDx div 19, - cWaveHeight + offsetY div 45, 32);
        ChangeDepth(RM, -cStereo_Water);
        DrawWaves(-1, 100 + WorldDx div 14, - cWaveHeight + offsetY div 70, 24);
        ResetDepth(RM);
    end
    else
        DrawWaves(-1, 100, - (cWaveHeight + (cWaveHeight shr 1)), 0);

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
                            hwRound(Gear^.X) + GetLaunchX(CurAmmoType, hwSign(Gear^.dX), Gear^.Angle) + LongInt(round(WorldDx + tdx * (24 + i * 2))) - 16,
                            hwRound(Gear^.Y) + GetLaunchY(CurAmmoType, Gear^.Angle) + LongInt(round(WorldDy + tdy * (24 + i * 2))) - 16,
                            i)
                end
        end;

    DrawVisualGears(1);

    DrawGears;

    DrawVisualGears(2);

    DrawWater(cWaterOpacity, 0);

    // Waves
    ChangeDepth(RM, cStereo_Water);
    DrawWaves( 1, 25 - WorldDx div 9, - cWaveHeight, 12);

    if (cReducedQuality and rq2DWater) = 0 then
    begin
        //DrawWater(cWaterOpacity, - offsetY div 40);
        ChangeDepth(RM, cStereo_Water);
        DrawWaves(-1, 50 + WorldDx div 6, - cWaveHeight - offsetY div 40, 8);
        DrawWater(cWaterOpacity, - offsetY div 20);
        ChangeDepth(RM, cStereo_Water);
        DrawWaves( 1, 75 - WorldDx div 4, - cWaveHeight - offsetY div 20, 2);
        DrawWater(cWaterOpacity, - offsetY div 10);
        ChangeDepth(RM, cStereo_Water);
        DrawWaves( -1, 25 + WorldDx div 3, - cWaveHeight - offsetY div 10, 0);
        ResetDepth(RM);
    end
    else
        DrawWaves(-1, 50, - (cWaveHeight shr 1), 0);


{$WARNINGS OFF}
// Target
if (TargetPoint.X <> NoPointX) and (CurrentTeam <> nil) and (CurrentHedgehog <> nil) then
    begin
    with PHedgehog(CurrentHedgehog)^ do
        begin
        if (CurAmmoType = amBee) then
            DrawRotatedF(sprTargetBee, TargetPoint.X + WorldDx, TargetPoint.Y + WorldDy, 0, 0, (RealTicks shr 3) mod 360)
        else
            DrawRotatedF(sprTargetP, TargetPoint.X + WorldDx, TargetPoint.Y + WorldDy, 0, 0, (RealTicks shr 3) mod 360);
        end;
    end;
{$WARNINGS ON}

// this scale is used to keep the various widgets at the same dimension at all zoom levels
SetScale(cDefaultZoomLevel);


// Turn time
{$IFDEF IPHONEOS}
offsetX:= cScreenHeight - 13;
{$ELSE}
offsetX:= 48;
{$ENDIF}
offsetY:= cOffsetY;
if ((TurnTimeLeft <> 0) and (TurnTimeLeft < 1000000)) or (ReadyTimeLeft <> 0) then
    begin
    if ReadyTimeLeft <> 0 then
        i:= Succ(Pred(ReadyTimeLeft) div 1000)
    else
        i:= Succ(Pred(TurnTimeLeft) div 1000);
   
   if i>99 then t:= 112
      else if i>9 then t:= 96
                  else t:= 80;
   DrawSprite(sprFrame, -(cScreenWidth shr 1) + t + offsetY, cScreenHeight - offsetX, 1);
   while i > 0 do
         begin
         dec(t, 32);
         DrawSprite(sprBigDigit, -(cScreenWidth shr 1) + t + offsetY, cScreenHeight - offsetX, i mod 10);
         i:= i div 10
         end;
   DrawSprite(sprFrame, -(cScreenWidth shr 1) + t - 4 + offsetY, cScreenHeight - offsetX, 0);
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
         Tint(Clan^.Color);

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

      // draw ai kill counter for gfAISurvival
      if (GameFlags and gfAISurvival) <> 0 then begin
          DrawTexture(TeamHealthBarWidth + 22, cScreenHeight + DrawHealthY,
              AIKillsTex);
      end;

      // if highlighted, draw flag and other contents again to keep their colors
      // this approach should be faster than drawing all borders one by one tinted or not
      if highlight then
         begin
         Tint($FF, $FF, $FF, $FF);

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
    end
    else
        if WindBarWidth < 0 then
        begin
            {$WARNINGS OFF}
            r.x:= (Longword(WindBarWidth) + RealTicks shr 6) mod 8;
            {$WARNINGS ON}
            r.y:= 0;
            r.w:= - WindBarWidth;
            r.h:= 13;
            DrawSpriteFromRect(sprWindL, r, (cScreenWidth shr 1) - offsetY + 74 + WindBarWidth, cScreenHeight - offsetX + 2, 13, 0);
        end;

// AmmoMenu
if (AMxShift < AMWidth) or bShowAmmoMenu then ShowAmmoMenu;

// Cursor
if isCursorVisible and bShowAmmoMenu then
   DrawSprite(sprArrow, CursorPoint.X, cScreenHeight - CursorPoint.Y, (RealTicks shr 6) mod 8);

DrawChat;

if fastUntilLag then DrawCentered(0, (cScreenHeight shr 1), SyncTexture);
if isPaused then DrawCentered(0, (cScreenHeight shr 1), PauseTexture);
if not isFirstFrame and (missionTimer <> 0) or isPaused or fastUntilLag or (GameState = gsConfirm) then
    begin
    if (ReadyTimeLeft = 0) and (missionTimer > 0) then dec(missionTimer, Lag);
    if missionTimer < 0 then missionTimer:= 0; // avoid subtracting below 0
    if missionTex <> nil then
        DrawCentered(0, min((cScreenHeight shr 1) + 100, cScreenHeight - 48 - missionTex^.h), missionTex);
    end;

// fps
{$IFDEF IPHONEOS}
offsetX:= 8;
{$ELSE}
offsetX:= 10;
{$ENDIF}
offsetY:= cOffsetY;
if (RM = rmDefault) or (RM = rmRightEye) then
begin
    inc(Frames);

    if cShowFPS or (GameType = gmtDemo) then
        inc(CountTicks, Lag);
    if (GameType = gmtDemo) and (CountTicks >= 1000) then
    begin
        i:=GameTicks div 1000;
        t:= i mod 60;
        s:= inttostr(t);
        if t < 10 then s:= '0' + s;
        i:= i div 60;
        t:= i mod 60;
        s:= inttostr(t) + ':' + s;
        if t < 10 then s:= '0' + s;
        s:= inttostr(i div 60) + ':' + s;
   
        if timeTexture <> nil then
            FreeTexture(timeTexture);
        timeTexture:= nil;
    
        tmpSurface:= TTF_RenderUTF8_Blended(Fontz[fnt16].Handle, Str2PChar(s), cWhiteColorChannels);
        tmpSurface:= doSurfaceConversion(tmpSurface);
        timeTexture:= Surface2Tex(tmpSurface, false);
        SDL_FreeSurface(tmpSurface)
    end;

    if timeTexture <> nil then
        DrawTexture((cScreenWidth shr 1) - 20 - timeTexture^.w - offsetY, offsetX + timeTexture^.h+5, timeTexture);

    if cShowFPS then
    begin
        if CountTicks >= 1000 then
        begin
            FPS:= Frames;
            Frames:= 0;
            CountTicks:= 0;
            s:= inttostr(FPS) + ' fps';
            if fpsTexture <> nil then
                FreeTexture(fpsTexture);
            fpsTexture:= nil;
            tmpSurface:= TTF_RenderUTF8_Blended(Fontz[fnt16].Handle, Str2PChar(s), cWhiteColorChannels);
            tmpSurface:= doSurfaceConversion(tmpSurface);
            fpsTexture:= Surface2Tex(tmpSurface, false);
            SDL_FreeSurface(tmpSurface)
        end;
        if fpsTexture <> nil then
            DrawTexture((cScreenWidth shr 1) - 60 - offsetY, offsetX, fpsTexture);
    end;

    if CountTicks >= 1000 then CountTicks:= 0;

    // lag warning (?)
    inc(SoundTimerTicks, Lag);
end;

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

if ScreenFade <> sfNone then
    begin
    if not isFirstFrame then
        case ScreenFade of
            sfToBlack, sfToWhite:     if ScreenFadeValue + Lag * ScreenFadeSpeed < sfMax then
                                          inc(ScreenFadeValue, Lag * ScreenFadeSpeed)
                                      else
                                          ScreenFadeValue:= sfMax;
            sfFromBlack, sfFromWhite: if ScreenFadeValue - Lag * ScreenFadeSpeed > 0 then
                                          dec(ScreenFadeValue, Lag * ScreenFadeSpeed)
                                      else
                                          ScreenFadeValue:= 0;
            end;
    if ScreenFade <> sfNone then
        begin
        case ScreenFade of
            sfToBlack, sfFromBlack: Tint(0, 0, 0, ScreenFadeValue * 255 div 1000);
            sfToWhite, sfFromWhite: Tint($FF, $FF, $FF, ScreenFadeValue * 255 div 1000);
            end;

        VertexBuffer[0].X:= -cScreenWidth;
        VertexBuffer[0].Y:= cScreenHeight;
        VertexBuffer[1].X:= -cScreenWidth;
        VertexBuffer[1].Y:= 0;
        VertexBuffer[2].X:= cScreenWidth;
        VertexBuffer[2].Y:= 0;
        VertexBuffer[3].X:= cScreenWidth;
        VertexBuffer[3].Y:= cScreenHeight;

        glDisable(GL_TEXTURE_2D);

        glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);
        glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

        glEnable(GL_TEXTURE_2D);
        Tint($FF, $FF, $FF, $FF);
        if not isFirstFrame and ((ScreenFadeValue = 0) or (ScreenFadeValue = sfMax)) then ScreenFade:= sfNone
        end
    end;

SetScale(zoom);

// Cursor
if isCursorVisible then
   begin
   if not bShowAmmoMenu then
     begin
     with CurrentHedgehog^ do
       if (Gear <> nil) and ((Gear^.State and gstHHChooseTarget) <> 0) then
         begin
         i:= GetAmmoEntry(CurrentHedgehog^)^.Pos;
         with Ammoz[CurAmmoType] do
           if PosCount > 1 then
             DrawSprite(PosSprite, CursorPoint.X - (SpritesData[PosSprite].Width shr 1), cScreenHeight - CursorPoint.Y - (SpritesData[PosSprite].Height shr 1),i);
         end;
     DrawSprite(sprArrow, CursorPoint.X, cScreenHeight - CursorPoint.Y, (RealTicks shr 6) mod 8)
     end
   end;
isFirstFrame:= false
end;

procedure AddCaption(s: shortstring; Color: Longword; Group: TCapGroup);
begin
//if Group in [capgrpGameState] then WriteLnToConsole(s);
    if Captions[Group].Tex <> nil then
        FreeTexture(Captions[Group].Tex);
    Captions[Group].Tex:= nil;

    Captions[Group].Tex:= RenderStringTex(s, Color, fntBig);

    case Group of
        capgrpGameState: Captions[Group].EndTime:= RealTicks + 2200
    else
        Captions[Group].EndTime:= RealTicks + 1400 + LongWord(Captions[Group].Tex^.w) * 3;
    end;
end;

procedure MoveCamera;
var EdgesDist,  wdy: LongInt;
    PrevSentPointTime: LongWord = 0;
begin
{$IFNDEF IPHONEOS}
if (not (CurrentTeam^.ExtDriven and isCursorVisible and not bShowAmmoMenu)) and cHasFocus then
begin
    SDL_GetMouseState(@CursorPoint.X, @CursorPoint.Y);
    CursorPoint.X:= CursorPoint.X - (cScreenWidth shr 1);
    CursorPoint.Y:= cScreenHeight - CursorPoint.Y;
end;
{$ENDIF}

if (not PlacingHogs) and (FollowGear <> nil) and (not isCursorVisible) and (not fastUntilLag) then
    if abs(CursorPoint.X - prevPoint.X) + abs(CursorPoint.Y - prevpoint.Y) > 4 then
    begin
        FollowGear:= nil;
        prevPoint:= CursorPoint;
        exit
    end
    else
    begin
        CursorPoint.X:= (prevPoint.X * 7 + hwRound(FollowGear^.X) + hwSign(FollowGear^.dX) * 100 + WorldDx) div 8;
        CursorPoint.Y:= (prevPoint.Y * 7 + cScreenHeight - (hwRound(FollowGear^.Y) + WorldDy)) div 8;
    end;

wdy:= trunc(cScreenHeight / cScaleFactor) + cScreenHeight div 2 - cWaterLine - cVisibleWater;
if WorldDy < wdy then WorldDy:= wdy;

if ((CursorPoint.X = prevPoint.X) and (CursorPoint.Y = prevpoint.Y)) then exit;

if AMxShift < AMWidth then
begin
{$IFDEF IPHONEOS}
    if CursorPoint.X < cScreenWidth div 2 + AMxShift - AMWidth then CursorPoint.X:= cScreenWidth div 2 + AMxShift - AMWidth;
    if CursorPoint.X > cScreenWidth div 2 + AMxShift - AMxOffset then CursorPoint.X:= cScreenWidth div 2 + AMxShift - AMxOffset;
    if CursorPoint.Y < cScreenHeight - AMyOffset - SlotsNum * AMSlotSize then CursorPoint.Y:= cScreenHeight - AMyOffset - SlotsNum * AMSlotSize;
    if CursorPoint.Y > cScreenHeight - AMyOffset then CursorPoint.Y:= cScreenHeight - AMyOffset;
{$ELSE}
    if CursorPoint.X < cScreenWidth div 2 + AMxShift - AMWidth + AMSlotSize then CursorPoint.X:= cScreenWidth div 2 + AMxShift - AMWidth + AMSlotSize;
    if CursorPoint.X > cScreenWidth div 2 + AMxShift - AMxOffset then CursorPoint.X:= cScreenWidth div 2 + AMxShift - AMxOffset;
    if CursorPoint.Y > AMyOffset + (SlotsNum + 1) * AMSlotSize then CursorPoint.Y:= AMyOffset + (SlotsNum + 1) * AMSlotSize;
    if CursorPoint.Y < AMyOffset + AMSlotSize then CursorPoint.Y:= AMyOffset + AMSlotSize;
{$ENDIF}
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
    EdgesDist:= cCursorEdgesDist
end
else
    EdgesDist:= cGearScrEdgesDist;

// this generates the border around the screen that moves the camera when cursor is near it
if isCursorVisible or (FollowGear <> nil) then
begin
    if CursorPoint.X < - cScreenWidth div 2 + EdgesDist then
    begin
        WorldDx:= WorldDx - CursorPoint.X - cScreenWidth div 2 + EdgesDist;
        CursorPoint.X:= - cScreenWidth div 2 + EdgesDist
    end
    else
        if CursorPoint.X > cScreenWidth div 2 - EdgesDist then
        begin
            WorldDx:= WorldDx - CursorPoint.X + cScreenWidth div 2 - EdgesDist;
            CursorPoint.X:= cScreenWidth div 2 - EdgesDist
        end;
    if CursorPoint.Y < EdgesDist then
    begin
        WorldDy:= WorldDy + CursorPoint.Y - EdgesDist;
        CursorPoint.Y:= EdgesDist
    end
    else
        if CursorPoint.Y > cScreenHeight - EdgesDist then
        begin
           WorldDy:= WorldDy + CursorPoint.Y - cScreenHeight + EdgesDist;
           CursorPoint.Y:= cScreenHeight - EdgesDist
        end;
end
else
    if cHasFocus then
    begin
        WorldDx:= WorldDx - CursorPoint.X + prevPoint.X;
        WorldDy:= WorldDy + CursorPoint.Y - prevPoint.Y;
        CursorPoint.X:= 0;
        CursorPoint.Y:= cScreenHeight div 2;
    end;

// this moves the camera according to CursorPoint X and Y
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
if missionTex <> nil then
    FreeTexture(missionTex);
missionTex:= nil;

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
    missionTex:= nil;
    cOffsetY:= 0;

    FillChar(Captions, sizeof(Captions), 0)
end;

procedure freeModule;
begin
end;

end.
