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

unit uWorld;
interface
uses SDLh, uGears, uConsts, uFloat, uRandom, uTypes, uRenderUtils;

procedure initModule;
procedure freeModule;

procedure InitWorld;
procedure ResetWorldTex;

procedure DrawWorld(Lag: LongInt);
procedure DrawWorldStereo(Lag: LongInt; RM: TRenderMode);
procedure ShowMission(caption, subcaption, text: ansistring; icon, time : LongInt);
procedure ShowMission(caption, subcaption, text: ansistring; icon, time : LongInt; forceDisplay : boolean);
procedure HideMission;
procedure SetAmmoTexts(ammoType: TAmmoType; name: ansistring; caption: ansistring; description: ansistring; autoLabels: boolean);
procedure ShakeCamera(amount: LongInt);
procedure InitCameraBorders;
procedure InitTouchInterface;
procedure SetUtilityWidgetState(ammoType: TAmmoType);
procedure animateWidget(widget: POnScreenWidget; fade, showWidget: boolean);
procedure MoveCamera;
procedure onFocusStateChanged;
procedure updateCursorVisibility;
procedure updateTouchWidgets(ammoType: TAmmoType);

implementation
uses
    uStore
    , uMisc
    , uIO
    , uLocale
    , uSound
    , uAmmos
    , uVisualGears
    , uChat
    , uLandTexture
    , uVariables
    , uUtils
    , uTextures
    , uRender
    , uCaptions
    , uCursor
    , uCommands
    , uTeams
    , uDebug
    , uInputHandler
{$IFDEF USE_VIDEO_RECORDING}
    , uVideoRec
{$ENDIF}
    ;

var AMShiftTargetX, AMShiftTargetY, AMShiftX, AMShiftY, SlotsNum: LongInt;
    AMAnimStartTime, AMState : LongInt;
    AMAnimState: Single;
    tmpSurface: PSDL_Surface;
    fpsTexture: PTexture;
    timeTexture: PTexture;
    FPS: Longword;
    CountTicks: Longword;
    prevPoint{, prevTargetPoint}: TPoint;
    amSel: TAmmoType = amNothing;
    missionTex: PTexture;
    missionTimer: LongInt;
    isFirstFrame: boolean;
    AMAnimType: LongInt;
    recTexture: PTexture;
    AmmoMenuTex     : PTexture;
    HorizontOffset: LongInt;
    cOffsetY: LongInt;
    WorldEnd, WorldFade : array[0..3] of HwColor4f;

const cStereo_Sky           = 0.0500;
      cStereo_Horizon       = 0.0250;
      cStereo_MidDistance   = 0.0175;
      cStereo_Water_distant = 0.0125;
      cStereo_Land          = 0.0075;
      cStereo_Water_near    = 0.0025;
      cStereo_Outside       = -0.0400;

      AMAnimDuration = 200;
      AMHidden    = 0;//AMState values
      AMShowingUp = 1;
      AMShowing   = 2;
      AMHiding    = 3;

      AMTypeMaskX     = $00000001;
      AMTypeMaskY     = $00000002;
      AMTypeMaskAlpha = $00000004;
      //AMTypeMaskSlide = $00000008;

{$IFDEF MOBILE}
      AMSlotSize = 48;
{$ELSE}
      AMSlotSize = 32;
{$ENDIF}
      AMSlotPadding = (AMSlotSize - 32) shr 1;

      cSendCursorPosTime = 50;
      cCursorEdgesDist   = 100;

// helper functions to create the goal/game mode string
function AddGoal(s: ansistring; gf: longword; si: TGoalStrId; i: LongInt): ansistring;
var t: ansistring;
begin
    if (GameFlags and gf) <> 0 then
        begin
        t:= inttostr(i);
        s:= s + FormatA(trgoal[si], t) + '|'
        end;
    AddGoal:= s;
end;

function AddGoal(s: ansistring; gf: longword; si: TGoalStrId): ansistring;
begin
    if (GameFlags and gf) <> 0 then
        s:= s + trgoal[si] + '|';
    AddGoal:= s;
end;

procedure InitWorld;
var i, t: LongInt;
    cp: PClan;
    g: ansistring;
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
            if (LocalClan = t) then
                LocalClan:= 0
            else if (LocalClan = 0) then
                LocalClan:= t
            end;
        end;
    CurrentTeam:= ClansArray[0]^.Teams[0];
    end;

if (GameFlags and gfInvulnerable) <> 0 then
    cTagsMask:= cTagsMask and (not htHealth);

// if special game flags/settings are changed, add them to the game mode notice window and then show it
g:= ''; // no text/things to note yet

// add custom goals from lua script if there are any
if LuaGoals <> ansistring('') then
    g:= LuaGoals + '|';

// check different game flags
g:= AddGoal(g, gfPlaceHog, gidPlaceHog); // placement?
g:= AddGoal(g, gfKing, gidKing); // king?
if ((GameFlags and gfKing) <> 0) and ((GameFlags and gfPlaceHog) = 0) then
    g:= AddGoal(g, gfAny, gidPlaceKing);
g:= AddGoal(g, gfTagTeam, gidTagTeam); // tag team mode?
g:= AddGoal(g, gfSharedAmmo, gidSharedAmmo); // shared ammo?
g:= AddGoal(g, gfPerHogAmmo, gidPerHogAmmo);
g:= AddGoal(g, gfMoreWind, gidMoreWind);
g:= AddGoal(g, gfLowGravity, gidLowGravity); // low gravity?
g:= AddGoal(g, gfSolidLand, gidSolidLand); // solid land?
g:= AddGoal(g, gfArtillery, gidArtillery); // artillery?
g:= AddGoal(g, gfInfAttack, gidInfAttack);
g:= AddGoal(g, gfResetWeps, gidResetWeps);
g:= AddGoal(g, gfResetHealth, gidResetHealth);
g:= AddGoal(g, gfKarma, gidKarma); // karma?
g:= AddGoal(g, gfVampiric, gidVampiric); // vampirism?
g:= AddGoal(g, gfInvulnerable, gidInvulnerable); // invulnerability?
g:= AddGoal(g, gfAISurvival, gidAISurvival);

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
        g:= AddGoal(g, gfAny, gidNoMineTimer)
    else if cMinesTime < 0 then
        g:= AddGoal(g, gfAny, gidRandomMineTimer)
    else
        g:= AddGoal(g, gfAny, gidMineTimer, cMinesTime div 1000);
    end;

// if the string has been set, show it for (default timeframe) seconds
if length(g) > 0 then
    ShowMission(trgoal[gidCaption], trgoal[gidSubCaption], g, 1, 0);

//cWaveWidth:= SpritesData[sprWater].Width;
//cWaveHeight:= SpritesData[sprWater].Height;
cWaveHeight:= 32;

InitCameraBorders();
uCursor.init();
prevPoint.X:= 0;
prevPoint.Y:= cScreenHeight div 2;
//prevTargetPoint.X:= 0;
//prevTargetPoint.Y:= 0;
WorldDx:=  -(LongInt(leftX + (playWidth div 2))); // -(LAND_WIDTH div 2);// + cScreenWidth div 2;
WorldDy:=  -(LAND_HEIGHT - (playHeight div 2)) + (cScreenHeight div 2);

//aligns it to the bottom of the screen, minus the border
SkyOffset:= 0;
HorizontOffset:= 0;

InitTouchInterface();
AMAnimType:= AMTypeMaskX or AMTypeMaskAlpha;
end;

procedure InitCameraBorders;
begin
cGearScrEdgesDist:= min(2 * cScreenHeight div 5, 2 * cScreenWidth div 5);
end;

procedure InitTouchInterface;
begin
{$IFDEF USE_TOUCH_INTERFACE}

//positioning of the buttons
buttonScale:= 1 / cDefaultZoomLevel;


with JumpWidget do
    begin
    show:= true;
    sprite:= sprJumpWidget;
    frame.w:= Round(spritesData[sprite].Texture^.w * buttonScale);
    frame.h:= Round(spritesData[sprite].Texture^.h * buttonScale);
    frame.x:= (cScreenWidth shr 1) - Round(frame.w * 1.2);
    frame.y:= cScreenHeight - frame.h * 2;
    active.x:= frame.x;
    active.y:= frame.y;
    active.w:= frame.w;
    active.h:= frame.h;
    end;

with AMWidget do
    begin
    show:= true;
    sprite:= sprAMWidget;
    frame.w:= Round(spritesData[sprite].Texture^.w * buttonScale);
    frame.h:= Round(spritesData[sprite].Texture^.h * buttonScale);
    frame.x:= (cScreenWidth shr 1) - frame.w * 2;
    frame.y:= cScreenHeight - Round(frame.h * 1.2);
    active.x:= frame.x;
    active.y:= frame.y;
    active.w:= frame.w;
    active.h:= frame.h;
    end;

with arrowLeft do
    begin
    show:= true;
    sprite:= sprArrowLeft;
    frame.w:= Round(spritesData[sprite].Texture^.w * buttonScale);
    frame.h:= Round(spritesData[sprite].Texture^.h * buttonScale);
    frame.x:= -(cScreenWidth shr 1) + Round(frame.w * 0.25);
    frame.y:= cScreenHeight - Round(frame.h * 1.5);
    active.x:= frame.x;
    active.y:= frame.y;
    active.w:= frame.w;
    active.h:= frame.h;
    end;

with arrowRight do
    begin
    show:= true;
    sprite:= sprArrowRight;
    frame.w:= Round(spritesData[sprite].Texture^.w * buttonScale);
    frame.h:= Round(spritesData[sprite].Texture^.h * buttonScale);
    frame.x:= -(cScreenWidth shr 1) + Round(frame.w * 1.5);
    frame.y:= cScreenHeight - Round(frame.h * 1.5);
    active.x:= frame.x;
    active.y:= frame.y;
    active.w:= frame.w;
    active.h:= frame.h;
    end;

with firebutton do
    begin
    show:= true;
    sprite:= sprFireButton;
    frame.w:= Round(spritesData[sprite].Texture^.w * buttonScale);
    frame.h:= Round(spritesData[sprite].Texture^.h * buttonScale);
    frame.x:= arrowRight.frame.x + arrowRight.frame.w;
    frame.y:= arrowRight.frame.y + (arrowRight.frame.w shr 1) - (frame.w shr 1);
    active.x:= frame.x;
    active.y:= frame.y;
    active.w:= frame.w;
    active.h:= frame.h;
    end;

with arrowUp do
    begin
    show:= false;
    sprite:= sprArrowUp;
    frame.w:= Round(spritesData[sprite].Texture^.w * buttonScale);
    frame.h:= Round(spritesData[sprite].Texture^.h * buttonScale);
    frame.x:= (cScreenWidth shr 1) - frame.w * 2;
    frame.y:= jumpWidget.frame.y - Round(frame.h * 1.25);
    active.x:= frame.x;
    active.y:= frame.y;
    active.w:= frame.w;
    active.h:= frame.h;
    with moveAnim do
         begin
         target.x:= frame.x;
         target.y:= frame.y;
         source.x:= frame.x - Round(frame.w * 0.75);
         source.y:= frame.y;
         end;
    end;

with arrowDown do
    begin
    show:= false;
    sprite:= sprArrowDown;
    frame.w:= Round(spritesData[sprite].Texture^.w * buttonScale);
    frame.h:= Round(spritesData[sprite].Texture^.h * buttonScale);
    frame.x:= (cScreenWidth shr 1) - frame.w * 2;
    frame.y:= jumpWidget.frame.y - Round(frame.h * 1.25);
    active.x:= frame.x;
    active.y:= frame.y;
    active.w:= frame.w;
    active.h:= frame.h;
    with moveAnim do
        begin
        target.x:= frame.x;
        target.y:= frame.y;
        source.x:= frame.x + Round(frame.w * 0.75);
        source.y:= frame.y;
        end;
    end;

with pauseButton do
    begin
    show:= true;
    sprite:= sprPauseButton;
    frame.w:= Round(spritesData[sprPauseButton].Texture^.w * buttonScale);
    frame.h:= Round(spritesData[sprPauseButton].Texture^.h * buttonScale);
    frame.x:= cScreenWidth div 2 - frame.w;
    frame.y:= 0;
    active.x:= frame.x;
    active.y:= frame.y;
    active.w:= frame.w;
    active.h:= frame.h;
    end;

with utilityWidget do
    begin
    show:= false;
    sprite:= sprTimerButton;
    frame.w:= Round(spritesData[sprite].Texture^.w * buttonScale);
    frame.h:= Round(spritesData[sprite].Texture^.h * buttonScale);
    frame.x:= arrowLeft.frame.x;
    frame.y:= arrowLeft.frame.y - Round(frame.h * 1.25);
    active.x:= frame.x;
    active.y:= frame.y;
    active.w:= frame.w;
    active.h:= frame.h;
    with moveAnim do
        begin
        target.x:= frame.x;
        target.y:= frame.y;
        source.x:= frame.x;
        source.y:= frame.y;
        end;
    end;

with utilityWidget2 do
    begin
    show:= false;
    sprite:= sprBounceButton;
    frame.w:= Round(spritesData[sprite].Texture^.w * buttonScale);
    frame.h:= Round(spritesData[sprite].Texture^.h * buttonScale);
    frame.x:= utilityWidget.frame.x + Round(frame.w * 1.25);
    frame.y:= arrowLeft.frame.y - Round(frame.h * 1.25);
    active.x:= frame.x;
    active.y:= frame.y;
    active.w:= frame.w;
    active.h:= frame.h;
    with moveAnim do
        begin
        target.x:= frame.x;
        target.y:= frame.y;
        source.x:= frame.x;
        source.y:= frame.y;
        end;
    end;

{$ENDIF}
end;

// for uStore texture resetting
procedure ResetWorldTex;
begin
    FreeAndNilTexture(fpsTexture);
    FreeAndNilTexture(timeTexture);
    FreeAndNilTexture(missionTex);
    FreeAndNilTexture(recTexture);
    FreeAndNilTexture(AmmoMenuTex);
    AmmoMenuInvalidated:= true;
end;

function GetAmmoMenuTexture(Ammo: PHHAmmo): PTexture;
const BORDERSIZE = 2;
var x, y, i, t, SlotsNumY, SlotsNumX, AMFrame: LongInt;
    STurns: LongInt;
    amSurface: PSDL_Surface;
    AMRect: TSDL_Rect;
{$IFDEF USE_AM_NUMCOLUMN}
    tmpsurf: PSDL_Surface;
    usesDefaultSlotKeys: boolean;
{$ENDIF}
begin
    if cOnlyStats then exit(nil);

    SlotsNum:= 0;
    for i:= 0 to cMaxSlotIndex do
        if (i <> cHiddenSlotIndex) and (Ammo^[i, 0].Count > 0) then
            inc(SlotsNum);
{$IFDEF USE_LANDSCAPE_AMMOMENU}
    SlotsNumX:= SlotsNum;
    SlotsNumY:= cMaxSlotAmmoIndex + 2;
    {$IFDEF USE_AM_NUMCOLUMN}
    inc(SlotsNumY);
    {$ENDIF}
{$ELSE}
    SlotsNumX:= cMaxSlotAmmoIndex + 1;
    SlotsNumY:= SlotsNum + 1;
    {$IFDEF USE_AM_NUMCOLUMN}
    inc(SlotsNumX);
    {$ENDIF}
{$ENDIF}


    AmmoRect.w:= (BORDERSIZE*2) + (SlotsNumX * AMSlotSize) + (SlotsNumX-1);
    AmmoRect.h:= (BORDERSIZE*2) + (SlotsNumY * AMSlotSize) + (SlotsNumY-1);
    amSurface := SDL_CreateRGBSurface(SDL_SWSURFACE, AmmoRect.w, AmmoRect.h, 32, RMask, GMask, BMask, AMask);

    AMRect.x:= BORDERSIZE;
    AMRect.y:= BORDERSIZE;
    AMRect.w:= AmmoRect.w - (BORDERSIZE*2);
    AMRect.h:= AmmoRect.h - (BORDERSIZE*2);

    SDL_FillRect(amSurface, @AMRect, SDL_MapRGB(amSurface^.format, 0,0,0));

    x:= AMRect.x;
    y:= AMRect.y;
{$IFDEF USE_AM_NUMCOLUMN}
    usesDefaultSlotKeys:= CheckDefaultSlotKeys;
{$ENDIF USE_AM_NUMCOLUMN}
    for i:= 0 to cMaxSlotIndex do
        if (i <> cHiddenSlotIndex) and (Ammo^[i, 0].Count > 0) then
            begin
{$IFDEF USE_LANDSCAPE_AMMOMENU}
            y:= AMRect.y;
{$ELSE}
            x:= AMRect.x;
{$ENDIF}
{$IFDEF USE_AM_NUMCOLUMN}
            // Ammo slot number column
            if usesDefaultSlotKeys then
                // F1, F2, F3, F4, ...
                tmpsurf:= TTF_RenderUTF8_Blended(Fontz[fnt16].Handle, Str2PChar('F'+IntToStr(i+1)), cWhiteColorChannels)
            else
                // 1, 2, 3, 4, ...
                tmpsurf:= TTF_RenderUTF8_Blended(Fontz[fnt16].Handle, Str2PChar(IntToStr(i+1)), cWhiteColorChannels);
            copyToXY(tmpsurf, amSurface,
                     x + AMSlotPadding + (AMSlotSize shr 1) - (tmpsurf^.w shr 1),
                     y + AMSlotPadding + (AMSlotSize shr 1) - (tmpsurf^.h shr 1));

            SDL_FreeSurface(tmpsurf);
    {$IFDEF USE_LANDSCAPE_AMMOMENU}
            y:= AMRect.y + AMSlotSize + 1;
    {$ELSE}
            x:= AMRect.x + AMSlotSize + 1;
    {$ENDIF}
{$ENDIF}


            for t:=0 to cMaxSlotAmmoIndex do
                begin
                if (Ammo^[i, t].Count > 0)  and (Ammo^[i, t].AmmoType <> amNothing) then
                    begin
                    STurns:= Ammoz[Ammo^[i, t].AmmoType].SkipTurns - CurrentTeam^.Clan^.TurnNumber;
                    AMFrame:= LongInt(Ammo^[i,t].AmmoType) - 1;
                    if STurns >= 0 then //weapon not usable yet, draw grayed out with turns remaining
                        begin
                        DrawSpriteFrame2Surf(sprAMAmmosBW, amSurface, x + AMSlotPadding,
                                                                 y + AMSlotPadding, AMFrame);
                        if STurns < 100 then
                            DrawSpriteFrame2Surf(sprTurnsLeft, amSurface,
                                x + AMSlotSize-16,
                                y + AMSlotSize + 1 - 16, STurns);
                        end
                    else //draw colored version
                        begin
                        DrawSpriteFrame2Surf(sprAMAmmos, amSurface, x + AMSlotPadding,
                                                               y + AMSlotPadding, AMFrame);
                        end;
{$IFDEF USE_LANDSCAPE_AMMOMENU}
        inc(y, AMSlotSize + 1); //the plus one is for the border
{$ELSE}
        inc(x, AMSlotSize + 1);
{$ENDIF}
        end;
    end;
{$IFDEF USE_LANDSCAPE_AMMOMENU}
    inc(x, AMSlotSize + 1);
{$ELSE}
    inc(y, AMSlotSize + 1);
{$ENDIF}
    end;

for i:= 1 to SlotsNumX -1 do
DrawLine2Surf(amSurface, i * (AMSlotSize+1)+1, BORDERSIZE, i * (AMSlotSize+1)+1, AMRect.h + BORDERSIZE - AMSlotSize - 2,160,160,160);
for i:= 1 to SlotsNumY -1 do
DrawLine2Surf(amSurface, BORDERSIZE, i * (AMSlotSize+1)+1, AMRect.w + BORDERSIZE, i * (AMSlotSize+1)+1,160,160,160);

//draw outer border
DrawSpriteFrame2Surf(sprAMCorners, amSurface, 0                    , 0                    , 0);
DrawSpriteFrame2Surf(sprAMCorners, amSurface, AMRect.w + BORDERSIZE, AMRect.y             , 1);
DrawSpriteFrame2Surf(sprAMCorners, amSurface, AMRect.x             , AMRect.h + BORDERSIZE, 2);
DrawSpriteFrame2Surf(sprAMCorners, amSurface, AMRect.w + BORDERSIZE, AMRect.h + BORDERSIZE, 3);

for i:=0 to BORDERSIZE-1 do
begin
DrawLine2Surf(amSurface, BORDERSIZE, i, AMRect.w + BORDERSIZE, i,160,160,160);//top
DrawLine2Surf(amSurface, BORDERSIZE, AMRect.h+BORDERSIZE+i, AMRect.w + BORDERSIZE, AMRect.h+BORDERSIZE+i,160,160,160);//bottom
DrawLine2Surf(amSurface, i, BORDERSIZE, i, AMRect.h + BORDERSIZE,160,160,160);//left
DrawLine2Surf(amSurface, AMRect.w+BORDERSIZE+i, BORDERSIZE, AMRect.w + BORDERSIZE+i, AMRect.h + BORDERSIZE, 160,160,160);//right
end;

GetAmmoMenuTexture:= Surface2Tex(amSurface, false);
if amSurface <> nil then SDL_FreeSurface(amSurface);
end;

procedure ShowAmmoMenu;
const BORDERSIZE = 2;
var Slot, Pos: LongInt;
    Ammo: PHHAmmo;
    c,i,g,t,STurns: LongInt;
begin
if TurnTimeLeft = 0 then bShowAmmoMenu:= false;

// give the assigned ammo to hedgehog
Ammo:= nil;
if (CurrentTeam <> nil) and (CurrentHedgehog <> nil)
and (not CurrentTeam^.ExtDriven) and (CurrentHedgehog^.BotLevel = 0) then
    Ammo:= CurrentHedgehog^.Ammo
else if (LocalAmmo <> -1) then
    Ammo:= GetAmmoByNum(LocalAmmo);
Pos:= -1;
if Ammo = nil then
    begin
    bShowAmmoMenu:= false;
    AMState:= AMHidden;
    exit
    end;

//Init the menu
if(AmmoMenuInvalidated) then
    begin
    AmmoMenuInvalidated:= false;
    FreeAndNilTexture(AmmoMenuTex);
    AmmoMenuTex:= GetAmmoMenuTexture(Ammo);

{$IFDEF USE_LANDSCAPE_AMMOMENU}
    if isPhone() then
        begin
        AmmoRect.x:= -(AmmoRect.w shr 1);
        AmmoRect.y:= (cScreenHeight shr 1) - (AmmoRect.h shr 1);
        end
    else
        begin
        AmmoRect.x:= -(AmmoRect.w shr 1);
        AmmoRect.y:= cScreenHeight - (AmmoRect.h + AMSlotSize);
        end;
{$ELSE}
        AmmoRect.x:= (cScreenWidth shr 1) - AmmoRect.w - AMSlotSize;
        AmmoRect.y:= cScreenHeight - (AmmoRect.h + AMSlotSize);
{$ENDIF}
    if AMState <> AMShowing then
        begin
        AMShiftTargetX:= (cScreenWidth shr 1) - AmmoRect.x;
        AMShiftTargetY:= cScreenHeight        - AmmoRect.y;

        if (AMAnimType and AMTypeMaskX) <> 0 then AMShiftTargetX:= (cScreenWidth shr 1) - AmmoRect.x
        else AMShiftTargetX:= 0;
        if (AMAnimType and AMTypeMaskY) <> 0 then AMShiftTargetY:= cScreenHeight        - AmmoRect.y
        else AMShiftTargetY:= 0;

        AMShiftX:= AMShiftTargetX;
        AMShiftY:= AMShiftTargetY
        end
end;

AMAnimState:= (RealTicks - AMAnimStartTime) / AMAnimDuration;

if AMState = AMShowing then
    begin
    FollowGear:=nil;
    end;

if AMState = AMShowingUp then // show ammo menu
    begin
    // No "appear" animation in low quality or playing with very short turn time.
    if ((cReducedQuality and rqSlowMenu) <> 0) or (cHedgehogTurnTime <= 10000) then
        begin
        AMShiftX:= 0;
        AMShiftY:= 0;
        AMState:= AMShowing;
        end
    // "Appear" animation
    else
        if AMAnimState < 1 then
            begin
            AMShiftX:= Round(AMShiftTargetX * (1 - AMAnimState));
            AMShiftY:= Round(AMShiftTargetY * (1 - AMAnimState));
            if (AMAnimType and AMTypeMaskAlpha) <> 0 then
                Tint($FF, $ff, $ff, Round($ff * AMAnimState));
            end
        else
            begin
            AMShiftX:= 0;
            AMShiftY:= 0;
            CursorPoint.X:= AmmoRect.x + AmmoRect.w;
            CursorPoint.Y:= AmmoRect.y;
            AMState:= AMShowing;
            end;
    end;
if AMState = AMHiding then // hide ammo menu
    begin
    // No "disappear" animation (see above)
    if ((cReducedQuality and rqSlowMenu) <> 0) or (cHedgehogTurnTime <= 10000) then
        begin
        AMShiftX:= AMShiftTargetX;
        AMShiftY:= AMShiftTargetY;
        AMState:= AMHidden;
        end
    // "Disappear" animation
    else
        if AMAnimState < 1 then
            begin
            AMShiftX:= Round(AMShiftTargetX * AMAnimState);
            AMShiftY:= Round(AMShiftTargetY * AMAnimState);
            if (AMAnimType and AMTypeMaskAlpha) <> 0 then
                Tint($FF, $ff, $ff, Round($ff * (1-AMAnimState)));
            end
         else
            begin
            AMShiftX:= AMShiftTargetX;
            AMShiftY:= AMShiftTargetY;
            prevPoint:= CursorPoint;
            //prevTargetPoint:= TargetCursorPoint;
            AMState:= AMHidden;
            end;
    end;

DrawTexture(AmmoRect.x + AMShiftX, AmmoRect.y + AMShiftY, AmmoMenuTex);

if ((AMState = AMHiding) or (AMState = AMShowingUp)) and ((AMAnimType and AMTypeMaskAlpha) <> 0 )then
    untint;

Pos:= -1;
Slot:= -1;
{$IFDEF USE_LANDSCAPE_AMMOMENU}
c:= -1;
    for i:= 0 to cMaxSlotIndex do
        if (i <> cHiddenSlotIndex) and (Ammo^[i, 0].Count > 0) then
            begin
            inc(c);
    {$IFDEF USE_AM_NUMCOLUMN}
            g:= 1;
    {$ELSE}
            g:= 0;
    {$ENDIF}
            for t:=0 to cMaxSlotAmmoIndex do
                if (Ammo^[i, t].Count > 0) and (Ammo^[i, t].AmmoType <> amNothing) then
                    begin
                    if (CursorPoint.Y <= (cScreenHeight - AmmoRect.y) - ( g    * (AMSlotSize+1))) and
                       (CursorPoint.Y >  (cScreenHeight - AmmoRect.y) - ((g+1) * (AMSlotSize+1))) and
                       (CursorPoint.X >  AmmoRect.x                   + ( c    * (AMSlotSize+1))) and
                       (CursorPoint.X <= AmmoRect.x                   + ((c+1) * (AMSlotSize+1))) then
                        begin
                        Slot:= i;
                        Pos:= t;
                        STurns:= Ammoz[Ammo^[i, t].AmmoType].SkipTurns - CurrentTeam^.Clan^.TurnNumber;
                        if (STurns < 0) and (AMShiftX = 0) and (AMShiftY = 0) then
                            DrawSprite(sprAMSlot,
                                       AmmoRect.x + BORDERSIZE + (c * (AMSlotSize+1)) + AMSlotPadding,
                                       AmmoRect.y + BORDERSIZE + (g  * (AMSlotSize+1)) + AMSlotPadding -1, 0);
                        end;
                        inc(g);
                   end;
            end;
{$ELSE}
c:= -1;
    for i:= 0 to cMaxSlotIndex do
        if (i <> cHiddenSlotIndex) and (Ammo^[i, 0].Count > 0) then
            begin
            inc(c);
    {$IFDEF USE_AM_NUMCOLUMN}
            g:= 1;
    {$ELSE}
            g:= 0;
    {$ENDIF}
            for t:=0 to cMaxSlotAmmoIndex do
                if (Ammo^[i, t].Count > 0) and (Ammo^[i, t].AmmoType <> amNothing) then
                    begin
                    if (CursorPoint.Y <= (cScreenHeight - AmmoRect.y) - ( c    * (AMSlotSize+1))) and
                       (CursorPoint.Y >  (cScreenHeight - AmmoRect.y) - ((c+1) * (AMSlotSize+1))) and
                       (CursorPoint.X >  AmmoRect.x                   + ( g    * (AMSlotSize+1))) and
                       (CursorPoint.X <= AmmoRect.x                   + ((g+1) * (AMSlotSize+1))) then
                        begin
                        Slot:= i;
                        Pos:= t;
                        STurns:= Ammoz[Ammo^[i, t].AmmoType].SkipTurns - CurrentTeam^.Clan^.TurnNumber;
                        if (STurns < 0) and (AMShiftX = 0) and (AMShiftY = 0) then
                            DrawSprite(sprAMSlot,
                                       AmmoRect.x + BORDERSIZE + (g * (AMSlotSize+1)) + AMSlotPadding,
                                       AmmoRect.y + BORDERSIZE + (c  * (AMSlotSize+1)) + AMSlotPadding -1, 0);
                        end;
                        inc(g);
                   end;
            end;
{$ENDIF}
    if (Pos >= 0) and (Pos <= cMaxSlotAmmoIndex) and (Slot >= 0) and (Slot <= cMaxSlotIndex) and (Slot <> cHiddenSlotIndex) then
        begin
        if (AMShiftX = 0) and (AMShiftY = 0) then
        if (Ammo^[Slot, Pos].Count > 0) and (Ammo^[Slot, Pos].AmmoType <> amNothing) then
            begin
            if (amSel <> Ammo^[Slot, Pos].AmmoType) or (WeaponTooltipTex = nil) then
                begin
                amSel:= Ammo^[Slot, Pos].AmmoType;
                RenderWeaponTooltip(amSel)
                end;

            DrawTexture(AmmoRect.x + (AMSlotSize shr 1),
                        AmmoRect.y + AmmoRect.h - BORDERSIZE - (AMSlotSize shr 1) - (Ammoz[Ammo^[Slot, Pos].AmmoType].NameTex^.h shr 1),
                        Ammoz[Ammo^[Slot, Pos].AmmoType].NameTex);
            if Ammo^[Slot, Pos].Count < AMMO_INFINITE then
                DrawTexture(AmmoRect.x + AmmoRect.w - 20 - (CountTexz[Ammo^[Slot, Pos].Count]^.w),
                            AmmoRect.y + AmmoRect.h - BORDERSIZE - (AMslotSize shr 1) - (CountTexz[Ammo^[Slot, Pos].Count]^.h shr 1),
                            CountTexz[Ammo^[Slot, Pos].Count]);

            if bSelected and (Ammoz[Ammo^[Slot, Pos].AmmoType].SkipTurns - CurrentTeam^.Clan^.TurnNumber < 0) then
                begin
                bShowAmmoMenu:= false;
                SetWeapon(Ammo^[Slot, Pos].AmmoType);
                bSelected:= false;
                FreeAndNilTexture(WeaponTooltipTex);
                updateTouchWidgets(Ammo^[Slot, Pos].AmmoType);
                exit
                end;
            end
        end
    else
        FreeAndNilTexture(WeaponTooltipTex);

    if (WeaponTooltipTex <> nil) and (AMShiftX = 0) and (AMShiftY = 0) then
{$IFDEF USE_LANDSCAPE_AMMOMENU}
        if (not isPhone()) then
            ShowWeaponTooltip(-WeaponTooltipTex^.w div 2, AmmoRect.y - WeaponTooltipTex^.h - AMSlotSize);
{$ELSE}
        ShowWeaponTooltip(AmmoRect.x - WeaponTooltipTex^.w - 3, Min(AmmoRect.y + 1, cScreenHeight - WeaponTooltipTex^.h - 40));
{$ENDIF}

    bSelected:= false;
{$IFNDEF USE_TOUCH_INTERFACE}
   if (AMShiftX = 0) and (AMShiftY = 0) then
        DrawSprite(sprArrow, CursorPoint.X, cScreenHeight - CursorPoint.Y, (RealTicks shr 6) mod 8);
{$ENDIF}
end;

procedure DrawRepeated(spr, sprL, sprR: TSprite; Shift, OffsetY: LongInt);
var i, w, h, lw, lh, rw, rh, sw: LongInt;
begin
sw:= round(cScreenWidth / cScaleFactor);
if (SpritesData[sprL].Texture = nil) and (SpritesData[spr].Texture <> nil) then
    begin
    w:= SpritesData[spr].Width * SpritesData[spr].Texture^.Scale;
    h:= SpritesData[spr].Height * SpritesData[spr].Texture^.Scale;
    i:= Shift mod w;
    if i > 0 then
        dec(i, w);
    dec(i, w * (sw div w + 1));
    repeat
    DrawTexture(i, WorldDy + LAND_HEIGHT + OffsetY - h, SpritesData[spr].Texture, SpritesData[spr].Texture^.Scale);
    inc(i, w)
    until i > sw
    end
else if SpritesData[spr].Texture <> nil then
    begin
    w:= SpritesData[spr].Width * SpritesData[spr].Texture^.Scale;
    h:= SpritesData[spr].Height * SpritesData[spr].Texture^.Scale;
    lw:= SpritesData[sprL].Width * SpritesData[spr].Texture^.Scale;
    lh:= SpritesData[sprL].Height * SpritesData[spr].Texture^.Scale;
    if SpritesData[sprR].Texture <> nil then
        begin
        rw:= SpritesData[sprR].Width * SpritesData[spr].Texture^.Scale;
        rh:= SpritesData[sprR].Height * SpritesData[spr].Texture^.Scale
        end;
    dec(Shift, w div 2);
    DrawTexture(Shift, WorldDy + LAND_HEIGHT + OffsetY - h, SpritesData[spr].Texture, SpritesData[spr].Texture^.Scale);

    i:= Shift - lw;
    while i >= -sw - lw do
        begin
        DrawTexture(i, WorldDy + LAND_HEIGHT + OffsetY - lh, SpritesData[sprL].Texture, SpritesData[sprL].Texture^.Scale);
        dec(i, lw);
        end;

    i:= Shift + w;
    if SpritesData[sprR].Texture <> nil then
        while i <= sw do
            begin
            DrawTexture(i, WorldDy + LAND_HEIGHT + OffsetY - rh, SpritesData[sprR].Texture, SpritesData[sprR].Texture^.Scale);
            inc(i, rw)
            end
    else
        while i <= sw do
            begin
            DrawTexture(i, WorldDy + LAND_HEIGHT + OffsetY - lh, SpritesData[sprL].Texture, SpritesData[sprL].Texture^.Scale);
            inc(i, lw)
            end
    end
end;


procedure DrawWorld(Lag: LongInt);
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
    else
        ZoomValue:= zoom;

    if (not isPaused) and (not isAFK) and (GameType <> gmtRecord) then
        MoveCamera;

    if cStereoMode = smNone then
        begin
        RenderClear();
        DrawWorldStereo(Lag, rmDefault)
{$IFDEF USE_S3D_RENDERING}
        end
    else
        begin
        // draw frame for left eye
        RenderClear(rmLeftEye);
        DrawWorldStereo(Lag, rmLeftEye);

        // draw frame for right eye
        RenderClear(rmRightEye);
        DrawWorldStereo(0, rmRightEye);
{$ENDIF}
        end;

FinishRender();
end;

procedure RenderWorldEdge;
var
    //VertexBuffer: array [0..3] of TVertex2f;
    tmp, w: LongInt;
    rect: TSDL_Rect;
    //c1, c2: LongWord; // couple of colours for edges
begin
if (WorldEdge <> weNone) and (WorldEdge <> weSea) then
    begin
(* I think for a bounded world, will fill the left and right areas with black or something. Also will probably want various border effects/animations based on border type.  Prob also, say, trigger a border animation timer on an impact. *)

    rect.y:= ViewTopY;
    rect.h:= ViewHeight;
    tmp:= leftX + WorldDx;
    w:= tmp - ViewLeftX;

    if w > 0 then
        begin
        rect.w:= w;
        rect.x:= ViewLeftX;
        DrawRect(rect, $10, $10, $10, $80, true);
        if WorldEdge = weBounce then
            DrawLineOnScreen(tmp - 1, ViewTopY, tmp - 1, ViewBottomY, 2, $54, $54, $FF, $FF);
        end;

    tmp:= rightX + WorldDx;
    w:= ViewRightX - tmp;

    if w > 0 then
        begin
        rect.w:= w;
        rect.x:= tmp;
        DrawRect(rect, $10, $10, $10, $80, true);
        if WorldEdge = weBounce then
            DrawLineOnScreen(tmp - 1, ViewTopY, tmp - 1, ViewBottomY, 2, $54, $54, $FF, $FF);
        end;

    (*
    WARNING: the following render code is outdated and does not work with
             current Render.pas ! - don't just uncomment without fixing it first

    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    if (WorldEdge = weWrap) or (worldEdge = weBounce) then
        glColor4ub($00, $00, $00, $40)
    else
        begin
        glEnableClientState(GL_COLOR_ARRAY);
        glColorPointer(4, GL_UNSIGNED_BYTE, 0, @WorldFade[0]);
        end;

    glPushMatrix;
    glTranslatef(WorldDx, WorldDy, 0);

    VertexBuffer[0].X:= leftX-20;
    VertexBuffer[0].Y:= -3500;
    VertexBuffer[1].X:= leftX-20;
    VertexBuffer[1].Y:= cWaterLine+cVisibleWater;
    VertexBuffer[2].X:= leftX+30;
    VertexBuffer[2].Y:= cWaterLine+cVisibleWater;
    VertexBuffer[3].X:= leftX+30;
    VertexBuffer[3].Y:= -3500;

    glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);
    glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

    VertexBuffer[0].X:= rightX+20;
    VertexBuffer[1].X:= rightX+20;
    VertexBuffer[2].X:= rightX-30;
    VertexBuffer[3].X:= rightX-30;

    glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);
    glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

    glColorPointer(4, GL_UNSIGNED_BYTE, 0, @WorldEnd[0]);

    VertexBuffer[0].X:= -5000;
    VertexBuffer[1].X:= -5000;
    VertexBuffer[2].X:= leftX-20;
    VertexBuffer[3].X:= leftX-20;

    glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);
    glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

    VertexBuffer[0].X:= rightX+5000;
    VertexBuffer[1].X:= rightX+5000;
    VertexBuffer[2].X:= rightX+20;
    VertexBuffer[3].X:= rightX+20;

    glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);
    glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

    glPopMatrix;
    glDisableClientState(GL_COLOR_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);

    glColor4ub($FF, $FF, $FF, $FF); // must not be Tint() as color array seems to stay active and color reset is required
    glEnable(GL_TEXTURE_2D);

    // I'd still like to have things happen to the border when a wrap or bounce just occurred, based on a timer
    if WorldEdge = weBounce then
        begin
        // could maybe alternate order of these on a bounce, or maybe drop the outer ones.
        if LeftImpactTimer mod 2 = 0 then
            begin
            c1:= $5454FFFF; c2:= $FFFFFFFF;
            end
        else begin
            c1:= $FFFFFFFF; c2:= $5454FFFF;
            end;
        DrawLine(leftX, -3000, leftX, cWaterLine+cVisibleWater, 7.0,   c1);
        DrawLine(leftX, -3000, leftX, cWaterLine+cVisibleWater, 5.0,   c2);
        DrawLine(leftX, -3000, leftX, cWaterLine+cVisibleWater, 3.0,   c1);
        DrawLine(leftX, -3000, leftX, cWaterLine+cVisibleWater, 1.0,   c2);
        if RightImpactTimer mod 2 = 0 then
            begin
            c1:= $5454FFFF; c2:= $FFFFFFFF;
            end
        else begin
            c1:= $FFFFFFFF; c2:= $5454FFFF;
            end;
        DrawLine(rightX, -3000, rightX, cWaterLine+cVisibleWater, 7.0, c1);
        DrawLine(rightX, -3000, rightX, cWaterLine+cVisibleWater, 5.0, c2);
        DrawLine(rightX, -3000, rightX, cWaterLine+cVisibleWater, 3.0, c1);
        DrawLine(rightX, -3000, rightX, cWaterLine+cVisibleWater, 1.0, c2)
        end
    else if WorldEdge = weWrap then
        begin
        DrawLine(leftX, -3000, leftX, cWaterLine+cVisibleWater, 5.0, $A0, $30, $60, max(50,255-LeftImpactTimer));
        DrawLine(leftX, -3000, leftX, cWaterLine+cVisibleWater, 2.0, $FF0000FF);
        DrawLine(rightX, -3000, rightX, cWaterLine+cVisibleWater, 5.0, $A0, $30, $60, max(50,255-RightImpactTimer));
        DrawLine(rightX, -3000, rightX, cWaterLine+cVisibleWater, 2.0, $FF0000FF);
        end
    else
        begin
        DrawLine(leftX, -3000, leftX, cWaterLine+cVisibleWater, 5.0, $2E8B5780);
        DrawLine(rightX, -3000, rightX, cWaterLine+cVisibleWater, 5.0, $2E8B5780)
        end;
    if LeftImpactTimer > Lag then dec(LeftImpactTimer,Lag) else LeftImpactTimer:= 0;
    if RightImpactTimer > Lag then dec(RightImpactTimer,Lag) else RightImpactTimer:= 0
    *)
    end;
end;


procedure RenderTeamsHealth;
var t, i, h, v, smallScreenOffset, TeamHealthBarWidth : LongInt;
    r: TSDL_Rect;
    highlight: boolean;
    hasVisibleHog: boolean;
    htex: PTexture;
begin
if VisibleTeamsCount * 20 > Longword(cScreenHeight) div 7 then  // take up less screen on small displays
    begin
    SetScale(1.5);
    smallScreenOffset:= cScreenHeight div 6;
    if VisibleTeamsCount * 100 > Longword(cScreenHeight) then
        Tint($FF,$FF,$FF,$80);
    end
else smallScreenOffset:= 0;
v:= 0; // for updating VisibleTeamsCount
for t:= 0 to Pred(TeamsCount) do
    with TeamsArray[t]^ do
      begin
      hasVisibleHog:= false;
      for i:= 0 to cMaxHHIndex do
          if (Hedgehogs[i].Gear <> nil) then
              hasVisibleHog:= true;
      if (TeamHealth > 0) and hasVisibleHog then
        begin
        // count visible teams
        inc(v);
        highlight:= bShowFinger and (CurrentTeam = TeamsArray[t]) and ((RealTicks mod 1000) < 500);

        if highlight then
            begin
            Tint(Clan^.Color shl 8 or $FF);
            htex:= GenericHealthTexture
            end
        else
            htex:= Clan^.HealthTex;

        // draw owner
        if OwnerTex <> nil then
            DrawTexture(-OwnerTex^.w - NameTagTex^.w - 18, cScreenHeight + DrawHealthY + smallScreenOffset, OwnerTex);

        // draw name
        DrawTexture(-NameTagTex^.w - 16, cScreenHeight + DrawHealthY + smallScreenOffset, NameTagTex);

        // draw flag
        DrawTexture(-14, cScreenHeight + DrawHealthY + smallScreenOffset, FlagTex);

        TeamHealthBarWidth:= cTeamHealthWidth * TeamHealthBarHealth div MaxTeamHealth;

        // draw team health bar
        r.x:= 0;
        r.y:= 0;
        r.w:= 2 + TeamHealthBarWidth;
        r.h:= htex^.h;
        DrawTextureFromRect(14, cScreenHeight + DrawHealthY + smallScreenOffset, @r, htex);

        // draw health bar's right border
        inc(r.x, cTeamHealthWidth + 2);
        r.w:= 3;
        DrawTextureFromRect(TeamHealthBarWidth + 15, cScreenHeight + DrawHealthY + smallScreenOffset, @r, htex);

        // draw hedgehog health separators in team health bar
        h:= 0;
        if not hasGone then
            for i:= 0 to cMaxHHIndex do
                begin
                inc(h, Hedgehogs[i].HealthBarHealth);
                if (h < TeamHealthBarHealth) and (Hedgehogs[i].HealthBarHealth > 0) then
                    if (IsTooDarkToRead(Clan^.Color)) then
                        DrawTexture(15 + h * TeamHealthBarWidth div TeamHealthBarHealth, cScreenHeight + DrawHealthY + smallScreenOffset + 1, SpritesData[sprSlider].Texture)
                    else
                        DrawTexture(15 + h * TeamHealthBarWidth div TeamHealthBarHealth, cScreenHeight + DrawHealthY + smallScreenOffset + 1, SpritesData[sprSliderInverted].Texture);
                end;

        // draw Lua value, if set
        if (hasLuaTeamValue) then
            DrawTexture(TeamHealthBarWidth + 22, cScreenHeight + DrawHealthY + smallScreenOffset, LuaTeamValueTex)
        // otherwise, draw AI kill counter for gfAISurvival
        else if (GameFlags and gfAISurvival) <> 0 then
            DrawTexture(TeamHealthBarWidth + 22, cScreenHeight + DrawHealthY + smallScreenOffset, AIKillsTex);

        // if highlighted, draw flag and other contents again to keep their colors
        // this approach should be faster than drawing all borders one by one tinted or not
        if highlight then
            begin
            if VisibleTeamsCount * 100 > Longword(cScreenHeight) then
                Tint($FF,$FF,$FF,$80)
            else untint;

            // draw name
            r.x:= 2;
            r.y:= 2;
            r.w:= NameTagTex^.w - 4;
            r.h:= NameTagTex^.h - 4;
            DrawTextureFromRect(-NameTagTex^.w - 14, cScreenHeight + DrawHealthY + smallScreenOffset + 2, @r, NameTagTex);

            if OwnerTex <> nil then
                begin
                r.w:= OwnerTex^.w - 4;
                r.h:= OwnerTex^.h - 4;
                DrawTextureFromRect(-OwnerTex^.w - NameTagTex^.w - 16, cScreenHeight + DrawHealthY + smallScreenOffset + 2, @r, OwnerTex)
                end;

            if (hasLuaTeamValue) then
                begin
                r.w:= LuaTeamValueTex^.w - 4;
                r.h:= LuaTeamValueTex^.h - 4;
                DrawTextureFromRect(TeamHealthBarWidth + 24, cScreenHeight + DrawHealthY + smallScreenOffset + 2, @r, LuaTeamValueTex);
                end
            else if (GameFlags and gfAISurvival) <> 0 then
                begin
                r.w:= AIKillsTex^.w - 4;
                r.h:= AIKillsTex^.h - 4;
                DrawTextureFromRect(TeamHealthBarWidth + 24, cScreenHeight + DrawHealthY + smallScreenOffset + 2, @r, AIKillsTex);
                end;

            // draw flag
            r.w:= 22;
            r.h:= 15;
            DrawTextureFromRect(-12, cScreenHeight + DrawHealthY + smallScreenOffset + 2, @r, FlagTex);
            end
        // draw an arrow next to active team
        else if (CurrentTeam = TeamsArray[t]) and (TurnTimeLeft > 0) then
            begin
            h:= -NameTagTex^.w - 24;
            if OwnerTex <> nil then
                h:= h - OwnerTex^.w - 4;
            if (IsTooDarkToRead(TeamsArray[t]^.Clan^.Color)) then
                DrawSpriteRotatedF(sprFingerBackInv, h, cScreenHeight + DrawHealthY + smallScreenOffset + 2 + SpritesData[sprFingerBackInv].Width div 4, 0, 1, -90)
            else
                DrawSpriteRotatedF(sprFingerBack, h, cScreenHeight + DrawHealthY + smallScreenOffset + 2 + SpritesData[sprFingerBack].Width div 4, 0, 1, -90);
            Tint(TeamsArray[t]^.Clan^.Color shl 8 or $FF);
            DrawSpriteRotatedF(sprFinger, h, cScreenHeight + DrawHealthY + smallScreenOffset + 2 + SpritesData[sprFinger].Width div 4, 0, 1, -90);
            untint;
            end;
        end;
      end;
if smallScreenOffset <> 0 then
    begin
    SetScale(cDefaultZoomLevel);
    if VisibleTeamsCount * 20 > Longword(cScreenHeight) div 5 then
        untint;
    end;
VisibleTeamsCount:= v;
end;

procedure RenderAttackBar();
var i: LongInt;
    tdx, tdy: Double;
begin
    if CurrentTeam <> nil then
        case AttackBar of
        2: with CurrentHedgehog^ do
                begin
                tdx:= hwSign(Gear^.dX) * Sin(Gear^.Angle * Pi / cMaxAngle);
                tdy:= - Cos(Gear^.Angle * Pi / cMaxAngle);
                for i:= (Gear^.Power * 24) div cPowerDivisor downto 0 do
                    DrawSprite(sprPower,
                            hwRound(Gear^.X) + GetLaunchX(CurAmmoType, hwSign(Gear^.dX), Gear^.Angle) + LongInt(round(WorldDx + tdx * (24 + i * 2))) - 16,
                            hwRound(Gear^.Y) + GetLaunchY(CurAmmoType, Gear^.Angle) + LongInt(round(WorldDy + tdy * (24 + i * 2))) - 16,
                            i)
                end;
        end;
end;

var preShiftWorldDx: LongInt;

procedure ShiftWorld(Dir: LongInt); inline;
begin
    preShiftWorldDx:= WorldDx;
    WorldDx:= WorldDx + LongInt(Dir * LongInt(playWidth));

end;

procedure UnshiftWorld(); inline;
begin
    WorldDx:= preShiftWorldDx;
end;

procedure DrawWorldStereo(Lag: LongInt; RM: TRenderMode);
var i, t: LongInt;
    spr: TSprite;
    r: TSDL_Rect;
    s: shortstring;
    offsetX, offsetY, screenBottom: LongInt;
    replicateToLeft, replicateToRight, tmp, isNotHiddenByCinematic: boolean;
{$IFDEF USE_VIDEO_RECORDING}
    a: Byte;
{$ENDIF}
begin
if WorldEdge <> weWrap then
    begin
    replicateToLeft := false;
    replicateToRight:= false;
    end
else
    begin
    replicateToLeft := (leftX  + WorldDx > ViewLeftX);
    replicateToRight:= (rightX + WorldDx < ViewRightX);
    end;

ScreenBottom:= (WorldDy - trunc(cScreenHeight/cScaleFactor) - (cScreenHeight div 2) + cWaterLine);

// note: offsetY is negative!
offsetY:= 10 *  Min(0, -145 - ScreenBottom); // TODO limit this in the other direction too

// Sky and horizont
if (cReducedQuality and rqNoBackground) = 0 then
    begin
        // Offsets relative to camera - spare them to wimpier cpus, no bg or flakes for them anyway
        SkyOffset:= offsetY div 35 + cWaveHeight;
        HorizontOffset:= SkyOffset;
        if ScreenBottom > SkyOffset then
            HorizontOffset:= HorizontOffset + ((ScreenBottom-SkyOffset) div 20);

        // background
        ChangeDepth(RM, cStereo_Sky);
        if SuddenDeathDmg then
            Tint(SDTint.r, SDTint.g, SDTint.b, SDTint.a);
        DrawRepeated(sprSky, sprSkyL, sprSkyR, (WorldDx + LAND_WIDTH div 2) * 3 div 8, SkyOffset);
        ChangeDepth(RM, -cStereo_Horizon);
        DrawRepeated(sprHorizont, sprHorizontL, sprHorizontR, (WorldDx + LAND_WIDTH div 2) * 3 div 5, HorizontOffset);
        if SuddenDeathDmg then
            untint;
    end;

DrawVisualGears(0, false);
ChangeDepth(RM, -cStereo_MidDistance);
DrawVisualGears(4, false);

if (cReducedQuality and rq2DWater) = 0 then
    begin
        // Waves
        DrawWater(255, SkyOffset, 0);
        ChangeDepth(RM, -cStereo_Water_distant);
        DrawWaves( 1,  0 - WorldDx div 32, offsetY div 35, -49, 64);
        ChangeDepth(RM, -cStereo_Water_distant);
        DrawWaves( -1,  25 + WorldDx div 25, offsetY div 38, -37, 48);
        ChangeDepth(RM, -cStereo_Water_distant);
        DrawWaves( 1,  75 - WorldDx div 19, offsetY div 45, -23, 32);
        ChangeDepth(RM, -cStereo_Water_distant);
        DrawWaves(-1, 100 + WorldDx div 14, offsetY div 70, -7, 24);
    end
else
    DrawWaves(-1, 100, - cWaveHeight div 2, - cWaveHeight div 2, 0);

ChangeDepth(RM, cStereo_Land);
DrawVisualGears(5, false);
DrawLand(WorldDx, WorldDy);

if replicateToLeft then
    begin
    ShiftWorld(-1);
    DrawLand(WorldDx, WorldDy);
    UnshiftWorld();
    end;

if replicateToRight then
    begin
    ShiftWorld(1);
    DrawLand(WorldDx, WorldDy);
    UnshiftWorld();
    end;

DrawWater(255, 0, 0);

tmp:= bShowFinger;
bShowFinger:= false;

if replicateToLeft then
    begin
    ShiftWorld(-1);
    DrawVisualGears(1, true);
    DrawGears();
    DrawVisualGears(6, true);
    UnshiftWorld();
    end;

if replicateToRight then
    begin
    ShiftWorld(1);
    DrawVisualGears(1, true);
    DrawGears();
    DrawVisualGears(6, true);
    UnshiftWorld();
    end;

bShowFinger:= tmp;

DrawVisualGears(1, false);
DrawGears;
DrawVisualGears(6, false);


if SuddenDeathDmg then
    DrawWater(SDWaterOpacity, 0, 0)
else
    DrawWater(WaterOpacity, 0, 0);

// Waves
ChangeDepth(RM, cStereo_Water_near);
DrawWaves( 1, 25 - WorldDx div 9, 0, 0, 12);

if (cReducedQuality and rq2DWater) = 0 then
    begin
    ChangeDepth(RM, cStereo_Water_near);
    DrawWaves(-1, 50 + WorldDx div 6, - offsetY div 40, 23, 8);
    if SuddenDeathDmg then
        DrawWater(SDWaterOpacity, - offsetY div 20, 23)
    else
        DrawWater(WaterOpacity, - offsetY div 20, 23);
    ChangeDepth(RM, cStereo_Water_near);
    DrawWaves( 1, 75 - WorldDx div 4, - offsetY div 20, 37, 2);
        if SuddenDeathDmg then
            DrawWater(SDWaterOpacity, - offsetY div 10, 47)
        else
            DrawWater(WaterOpacity, - offsetY div 10, 47);
        ChangeDepth(RM, cStereo_Water_near);
        DrawWaves( -1, 25 + WorldDx div 3, - offsetY div 10, 59, 0);
        end
    else
        DrawWaves(-1, 50, cWaveHeight div 2, cWaveHeight div 2, 0);

// line at airplane height for certain airstrike types (when spawning height is important)
with CurrentHedgehog^ do
    if (isCursorVisible) and ((CurAmmoType = amNapalm) or (CurAmmoType = amMineStrike) or (((GameFlags and gfMoreWind) <> 0) and ((CurAmmoType = amDrillStrike) or (CurAmmoType = amAirAttack)))) then
        DrawLine(-3000, topY-300, 7000, topY-300, 3.0, (Team^.Clan^.Color shr 16), (Team^.Clan^.Color shr 8) and $FF, Team^.Clan^.Color and $FF, $FF);

// gear HUD extras (fuel indicator, secondary ammo, etc.)
if replicateToLeft then
    begin
    ShiftWorld(-1);
    DrawGearsGui();
    UnshiftWorld();
    end;

if replicateToRight then
    begin
    ShiftWorld(1);
    DrawGearsGui();
    UnshiftWorld();
    end;

DrawGearsGui();

// everything after this ChangeDepth will be drawn outside the screen
// note: negative parallax gears should last very little for a smooth stereo effect
    ChangeDepth(RM, cStereo_Outside);

    if replicateToLeft then
        begin
        ShiftWorld(-1);
        DrawVisualGears(2, true);
        UnshiftWorld();
        end;

    if replicateToRight then
        begin
        ShiftWorld(1);
        DrawVisualGears(2, true);
        UnshiftWorld();
        end;

    DrawVisualGears(2, false);

// everything after this ResetDepth will be drawn at screen level (depth = 0)
// note: everything that needs to be readable should be on this level
    ResetDepth(RM);

    if replicateToLeft then
        begin
        ShiftWorld(-1);
        DrawVisualGears(3, true);
        UnshiftWorld();
        end;

    if replicateToRight then
        begin
        ShiftWorld(1);
        DrawVisualGears(3, true);
        UnshiftWorld();
        end;

    DrawVisualGears(3, false);

// Target (e.g. air attack, bee, ...)
if (TargetPoint.X <> NoPointX) and (CurrentTeam <> nil) and (CurrentHedgehog <> nil) then
    begin
    with PHedgehog(CurrentHedgehog)^ do
        begin
        if CurAmmoType = amBee then
            spr:= sprTargetBee
        else
            spr:= sprTargetP;
        if replicateToLeft then
            begin
            ShiftWorld(-1);
            if spr = sprTargetP then
                begin
                if IsTooDarkToRead(Team^.Clan^.Color) then
                    DrawSpriteRotatedF(sprTargetPBackInv, TargetPoint.X + WorldDx, TargetPoint.Y + WorldDy, 0, 0, (RealTicks shr 3) mod 360)
                else
                    DrawSpriteRotatedF(sprTargetPBack, TargetPoint.X + WorldDx, TargetPoint.Y + WorldDy, 0, 0, (RealTicks shr 3) mod 360);
                Tint(Team^.Clan^.Color shl 8 or $FF);
                end;
            DrawSpriteRotatedF(spr, TargetPoint.X + WorldDx, TargetPoint.Y + WorldDy, 0, 0, (RealTicks shr 3) mod 360);
            if spr = sprTargetP then
                untint;
            UnshiftWorld();
            end;

        if replicateToRight then
            begin
            ShiftWorld(1);
            if spr = sprTargetP then
                begin
                if IsTooDarkToRead(Team^.Clan^.Color) then
                    DrawSpriteRotatedF(sprTargetPBackInv, TargetPoint.X + WorldDx, TargetPoint.Y + WorldDy, 0, 0, (RealTicks shr 3) mod 360)
                else
                    DrawSpriteRotatedF(sprTargetPBack, TargetPoint.X + WorldDx, TargetPoint.Y + WorldDy, 0, 0, (RealTicks shr 3) mod 360);
                Tint(Team^.Clan^.Color shl 8 or $FF);
                end;
            DrawSpriteRotatedF(spr, TargetPoint.X + WorldDx, TargetPoint.Y + WorldDy, 0, 0, (RealTicks shr 3) mod 360);
            if spr = sprTargetP then
                untint;
            UnshiftWorld();
            end;

        if spr = sprTargetP then
            begin
            if IsTooDarkToRead(Team^.Clan^.Color) then
                DrawSpriteRotatedF(sprTargetPBackInv, TargetPoint.X + WorldDx, TargetPoint.Y + WorldDy, 0, 0, (RealTicks shr 3) mod 360)
            else
                DrawSpriteRotatedF(sprTargetPBack, TargetPoint.X + WorldDx, TargetPoint.Y + WorldDy, 0, 0, (RealTicks shr 3) mod 360);
            Tint(Team^.Clan^.Color shl 8 or $FF);
            end;
        DrawSpriteRotatedF(spr, TargetPoint.X + WorldDx, TargetPoint.Y + WorldDy, 0, 0, (RealTicks shr 3) mod 360);
        if spr = sprTargetP then
            untint;
        end;
    end;

// Attack bar
if replicateToLeft then
    begin
    ShiftWorld(-1);
    RenderAttackBar();
    UnshiftWorld();
    end;

if replicateToRight then
    begin
    ShiftWorld(1);
    RenderAttackBar();
    UnshiftWorld();
    end;

RenderAttackBar();

// World edge
RenderWorldEdge();

// This scale is used to keep the various widgets at the same dimension at all zoom levels
SetScale(cDefaultZoomLevel);

isNotHiddenByCinematic:= true;
// Cinematic Mode: Determine effects and state
if CinematicScript or (InCinematicMode and autoCameraOn
    and ((CurrentHedgehog = nil) or CurrentHedgehog^.Team^.ExtDriven
    or (CurrentHedgehog^.BotLevel <> 0) or (GameType = gmtDemo))) then
    begin
    if CinematicSteps < 300 then
        begin
        inc(CinematicSteps, Lag);
        if CinematicSteps > 300 then
            begin
            CinematicSteps:= 300;
            isNotHiddenByCinematic:= false;
            end;
        end;
    end
else if CinematicSteps > 0 then
    begin
    dec(CinematicSteps, Lag);
    if CinematicSteps < 0 then
        CinematicSteps:= 0;
    end;

// Turn time
if (UIDisplay <> uiNone) and (isNotHiddenByCinematic) then
    begin
{$IFDEF USE_TOUCH_INTERFACE}
    offsetX:= cScreenHeight - 13;
{$ELSE}
    offsetX:= 48;
{$ENDIF}
    offsetY:= cOffsetY;
    if ((TurnTimeLeft <> 0) and (TurnTimeLeft < 999000)) or (ReadyTimeLeft <> 0) then
        begin
        if ReadyTimeLeft <> 0 then
            i:= Succ(Pred(ReadyTimeLeft) div 1000)
        else
            i:= Succ(Pred(TurnTimeLeft) div 1000);

        if i>99 then
            t:= 112
        else if i>9 then
            t:= 96
        else
            t:= 80;
        DrawSprite(sprFrame, -(cScreenWidth shr 1) + t + offsetY, cScreenHeight - offsetX, 1);
        while i > 0 do
            begin
            dec(t, 32);
            if isPaused or (not IsClockRunning()) then
                spr := sprBigDigitGray
            else if (ReadyTimeLeft <> 0) then
                spr := sprBigDigitGreen
            else if IsGetAwayTime then
                spr := sprBigDigitRed
            else
                spr := sprBigDigit;
            DrawSprite(spr, -(cScreenWidth shr 1) + t + offsetY, cScreenHeight - offsetX, i mod 10);
            i:= i div 10
            end;
        DrawSprite(sprFrame, -(cScreenWidth shr 1) + t - 4 + offsetY, cScreenHeight - offsetX, 0);
        end;

    end;

// Team bars
if (UIDisplay = uiAll) and (isNotHiddenByCinematic) then
    RenderTeamsHealth;

// Wind bar
if (UIDisplay <> uiNone) and (isNotHiddenByCinematic) then
    begin
{$IFDEF USE_TOUCH_INTERFACE}
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
        r.x:= 8 - (RealTicks shr 6) mod 9;
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
        r.x:= (Longword(WindBarWidth) + RealTicks shr 6) mod 9;
        {$WARNINGS ON}
        r.y:= 0;
        r.w:= - WindBarWidth;
        r.h:= 13;
        DrawSpriteFromRect(sprWindL, r, (cScreenWidth shr 1) - offsetY + 74 + WindBarWidth, cScreenHeight - offsetX + 2, 13, 0);
        end
    end;

// Indicators for global effects (extra damage, low gravity)
if (UIDisplay <> uiNone) and (isNotHiddenByCinematic) then
    begin
{$IFDEF USE_TOUCH_INTERFACE}
    offsetX:= (cScreenWidth shr 1) - 95;
    offsetY:= cScreenHeight - 21;
{$ELSE}
    offsetX:= 45;
    offsetY:= 51;
{$ENDIF}

    if cDamageModifier = _1_5 then
        begin
            DrawTextureF(ropeIconTex, 1, (cScreenWidth shr 1) - offsetX, cScreenHeight - offsetY, 0, 1, 32, 32);
            DrawTextureF(SpritesData[sprAMAmmos].Texture, 0.90, (cScreenWidth shr 1) - offsetX, cScreenHeight - offsetY, ord(amExtraDamage) - 1, 1, 32, 32);
{$IFDEF USE_TOUCH_INTERFACE}
            offsetX := offsetX - 33
{$ELSE}
            offsetX := offsetX + 33
{$ENDIF}
        end;
    if (cLowGravity) or ((GameFlags and gfLowGravity) <> 0) then
        begin
            DrawTextureF(ropeIconTex, 1, (cScreenWidth shr 1) - offsetX, cScreenHeight - offsetY, 0, 1, 32, 32);
            DrawTextureF(SpritesData[sprAMAmmos].Texture, 0.90, (cScreenWidth shr 1) - offsetX, cScreenHeight - offsetY, ord(amLowGravity) - 1, 1, 32, 32);
        end;
    end;

// Cinematic Mode: Render black bars
if CinematicSteps > 0 then
    begin
    r.x:= ViewLeftX;
    r.w:= ViewWidth;
    r.y:= ViewTopY;
    CinematicBarH:= (ViewHeight * CinematicSteps) div 2048;
    r.h:= CinematicBarH;
    DrawRect(r, 0, 0, 0, $FF, true);
    r.y:= ViewBottomY - r.h;
    DrawRect(r, 0, 0, 0, $FF, true);
    end;

// Touchscreen interface widgets
{$IFDEF USE_TOUCH_INTERFACE}
DrawScreenWidget(@arrowLeft);
DrawScreenWidget(@arrowRight);
DrawScreenWidget(@arrowUp);
DrawScreenWidget(@arrowDown);

DrawScreenWidget(@fireButton);
DrawScreenWidget(@jumpWidget);
DrawScreenWidget(@AMWidget);
DrawScreenWidget(@utilityWidget);
DrawScreenWidget(@utilityWidget2);
DrawScreenWidget(@pauseButton);
{$ENDIF}

// Captions
if UIDisplay <> uiNone then
    DrawCaptions;

// Lag alert
if isInLag then
    DrawSprite(sprLag, 32 - (cScreenWidth shr 1), 32, (RealTicks shr 7) mod 12);

// Chat
DrawChat;


// Mission panel
if not isFirstFrame and (missionTimer <> 0) or isShowMission or isPaused or fastUntilLag or (GameState = gsConfirm) then
    begin
    if (ReadyTimeLeft = 0) and (missionTimer > 0) then
        dec(missionTimer, Lag);
    if missionTimer < 0 then
        missionTimer:= 0; // avoid subtracting below 0
    if missionTex <> nil then
        DrawTextureCentered(0, Min((cScreenHeight shr 1) + 100, cScreenHeight - 48 - missionTex^.h), missionTex);
    end;
if missionTimer = 0 then
    isForceMission := false;

// AmmoMenu
if bShowAmmoMenu and ((AMState = AMHidden) or (AMState = AMHiding)) then
    begin
    if (AMState = AMHidden) then
        AMAnimStartTime:= RealTicks
    else
        AMAnimStartTime:= RealTicks - (AMAnimDuration - (RealTicks - AMAnimStartTime));
    AMState:= AMShowingUp;
    end;
if (not bShowAmmoMenu) and ((AMstate = AMShowing) or (AMState = AMShowingUp)) then
    begin
    if (AMState = AMShowing) then
        AMAnimStartTime:= RealTicks
    else
        AMAnimStartTime:= RealTicks - (AMAnimDuration - (RealTicks - AMAnimStartTime));
    AMState:= AMHiding;
    end;

if bShowAmmoMenu or (AMState = AMHiding) then
    ShowAmmoMenu;

// Centered status/menu messages (synchronizing, auto skip, pause, etc.)
if fastUntilLag then
    DrawTextureCentered(0, (cScreenHeight shr 1), SyncTexture)
else if isAFK then
    DrawTextureCentered(0, (cScreenHeight shr 1), AFKTexture)
else if isPaused then
    DrawTextureCentered(0, (cScreenHeight shr 1), PauseTexture);

// Cursor
if isCursorVisible and bShowAmmoMenu then
    DrawSprite(sprArrow, CursorPoint.X, cScreenHeight - CursorPoint.Y, (RealTicks shr 6) mod 8);

// FPS and demo replay time
{$IFDEF USE_TOUCH_INTERFACE}
offsetX:= pauseButton.frame.y + pauseButton.frame.h + 12;
{$ELSE}
offsetX:= 10;
{$ENDIF}
offsetY:= cOffsetY;
if (RM = rmDefault) or (RM = rmRightEye) then
    begin
    inc(Frames);

    if cShowFPS or (GameType = gmtDemo) then
        inc(CountTicks, Lag);

    // Demo replay time
    if (GameType = gmtDemo) and (CountTicks >= 1000) then
        begin
        i:= GameTicks div 1000;
        t:= i mod 60;
        s:= inttostr(t);
        if t < 10 then
            s:= '0' + s;
        i:= i div 60;
        t:= i mod 60;
        s:= inttostr(t) + ':' + s;
        if t < 10 then
            s:= '0' + s;
        s:= inttostr(i div 60) + ':' + s;


        tmpSurface:= TTF_RenderUTF8_Blended(Fontz[fnt16].Handle, Str2PChar(s), cWhiteColorChannels);
        tmpSurface:= doSurfaceConversion(tmpSurface);
        FreeAndNilTexture(timeTexture);
        timeTexture:= Surface2Tex(tmpSurface, false);
        SDL_FreeSurface(tmpSurface)
        end;

    if timeTexture <> nil then
        DrawTexture((cScreenWidth shr 1) - 20 - timeTexture^.w - offsetY, offsetX + timeTexture^.h+5, timeTexture);

    // FPS counter
    if cShowFPS then
        begin
        if CountTicks >= 1000 then
            begin
            FPS:= Frames;
            Frames:= 0;
            CountTicks:= 0;
            s:= Format(shortstring(trmsg[sidFPS]), inttostr(FPS));
            tmpSurface:= TTF_RenderUTF8_Blended(Fontz[CheckCJKFont(trmsg[sidFPS],fnt16)].Handle, Str2PChar(s), cWhiteColorChannels);
            tmpSurface:= doSurfaceConversion(tmpSurface);
            FreeAndNilTexture(fpsTexture);
            fpsTexture:= Surface2Tex(tmpSurface, false);
            SDL_FreeSurface(tmpSurface)
            end;
        if fpsTexture <> nil then
            DrawTexture((cScreenWidth shr 1) - 20 - fpsTexture^.w - offsetY, offsetX, fpsTexture);
        end;
end;

// Quit Y/N question
if GameState = gsConfirm then
    DrawTextureCentered(0, (cScreenHeight shr 1)-40, ConfirmTexture);

if ScreenFade <> sfNone then
    begin
    if (not isFirstFrame) then
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
        r.x:= ViewLeftX;
        r.y:= ViewTopY;
        r.w:= ViewWidth;
        r.h:= ViewHeight;

        case ScreenFade of
            sfToBlack, sfFromBlack: DrawRect(r, 0, 0, 0, ScreenFadeValue * 255 div 1000, true);
            sfToWhite, sfFromWhite: DrawRect(r, $FF, $FF, $FF, ScreenFadeValue * 255 div 1000, true);
            end;

        if not isFirstFrame and ((ScreenFadeValue = 0) or (ScreenFadeValue = sfMax)) then
            ScreenFade:= sfNone
        end
    end;

{$IFDEF USE_VIDEO_RECORDING}
// During video prerecording draw red blinking circle and text 'rec'
if flagPrerecording then
    begin
    if recTexture = nil then
        begin
        s:= 'rec';
        tmpSurface:= TTF_RenderUTF8_Blended(Fontz[fntBig].Handle, Str2PChar(s), cWhiteColorChannels);
        tmpSurface:= doSurfaceConversion(tmpSurface);
        FreeAndNilTexture(recTexture);
        recTexture:= Surface2Tex(tmpSurface, false);
        SDL_FreeSurface(tmpSurface)
        end;
    DrawTexture( -(cScreenWidth shr 1) + 50, 20, recTexture);

    t:= -255 + ((RealTicks div 2) and 511);
    a:= Byte(min(255, abs(t)));

    // draw red circle
    DrawCircleFilled(-(cScreenWidth shr 1) + 30, 35, 10, $FF, $00, $00, a);
    end;
{$ENDIF}

SetScale(zoom);

// Cursor
if isCursorVisible and (not bShowAmmoMenu) then
    begin
    if not CurrentTeam^.ExtDriven then TargetCursorPoint:= CursorPoint;
    with CurrentHedgehog^ do
        if (Gear <> nil) and ((Gear^.State and gstChooseTarget) <> 0) then
            begin
        i:= GetCurAmmoEntry(CurrentHedgehog^)^.Pos;
        with Ammoz[CurAmmoType] do
            if PosCount > 1 then
                begin
                if (CurAmmoType = amGirder) or (CurAmmoType = amTeleport) then
                    begin
                // pulsating transparency
                    if ((GameTicks div 16) mod $80) >= $40 then
                        Tint($FF, $FF, $FF, $C0 - (GameTicks div 16) mod $40)
                    else
                        Tint($FF, $FF, $FF, $80 + (GameTicks div 16) mod $40);
                    end;
                DrawSprite(PosSprite, TargetCursorPoint.X - (SpritesData[PosSprite].Width shr 1), cScreenHeight - TargetCursorPoint.Y - (SpritesData[PosSprite].Height shr 1),i);
                Untint();
                end;
            end;
    DrawTextureF(SpritesData[sprArrow].Texture, cDefaultZoomLevel / cScaleFactor, TargetCursorPoint.X + round(SpritesData[sprArrow].Width / cScaleFactor), cScreenHeight + round(SpritesData[sprArrow].Height / cScaleFactor) - TargetCursorPoint.Y, (RealTicks shr 6) mod 8, 1, SpritesData[sprArrow].Width, SpritesData[sprArrow].Height);
    end;

// debug stuff
if cViewLimitsDebug then
    begin
    r.x:= ViewLeftX;
    r.y:= ViewTopY;
    r.w:= ViewWidth;
    r.h:= ViewHeight;
    DrawRect(r, 255, 0, 0, 128, false);
    end;

isFirstFrame:= false
end;

var PrevSentPointTime: LongWord = 0;

procedure MoveCamera;
var EdgesDist, wdy, shs,z, amNumOffsetX, amNumOffsetY, dstX: LongInt;
    inbtwnTrgtAttks: Boolean;
begin
{$IFNDEF MOBILE}
if (not (CurrentTeam^.ExtDriven and isCursorVisible and (not bShowAmmoMenu) and autoCameraOn)) and cHasFocus and (GameState <> gsConfirm) then
    uCursor.updatePosition();
{$ENDIF}
z:= round(200/zoom);
inbtwnTrgtAttks := ((GameFlags and gfInfAttack) <> 0) and (CurrentHedgehog <> nil) and ((CurrentHedgehog^.Gear = nil) or (CurrentHedgehog^.Gear <> FollowGear)) and ((Ammoz[CurrentHedgehog^.CurAmmoType].Ammo.Propz and ammoprop_NeedTarget) <> 0);
if autoCameraOn and (not PlacingHogs) and (FollowGear <> nil) and (not isCursorVisible) and (not bShowAmmoMenu) and (not fastUntilLag) and (not inbtwnTrgtAttks) then
    if ((abs(CursorPoint.X - prevPoint.X) + abs(CursorPoint.Y - prevpoint.Y)) > 4) then
        begin
        FollowGear:= nil;
        prevPoint:= CursorPoint;
        exit
        end
    else
        begin
            dstX:= hwRound(FollowGear^.X) + hwSign(FollowGear^.dX) * z + WorldDx;

            if (WorldEdge = weWrap) then
                begin
                    if dstX - prevPoint.X < (leftX - rightX) div 2 then
                        CursorPoint.X:= (prevPoint.X * 7 + dstX - (leftX - rightX)) div 8
                    else if dstX - prevPoint.X > (rightX - leftX) div 2 then
                        CursorPoint.X:= (prevPoint.X * 7 + dstX - (rightX - leftX)) div 8
                    else
                        CursorPoint.X:= (prevPoint.X * 7 + dstX) div 8;
                end
            else // usual camera movement routine
                begin
                    CursorPoint.X:= (prevPoint.X * 7 + dstX) div 8;
                end;

        if isPhone() or (cScreenHeight < 600) or (hwFloat(FollowGear^.dY * z).Round < 10) then
            CursorPoint.Y:= (prevPoint.Y * 7 + cScreenHeight - (hwRound(FollowGear^.Y) + WorldDy)) div 8
        else
            CursorPoint.Y:= (prevPoint.Y * 7 + cScreenHeight - (hwRound(FollowGear^.Y) + hwSign(FollowGear^.dY) * z + WorldDy)) div 8;
        end;

if (WorldEdge = weWrap) then
    begin
        if -WorldDx < leftX then
            WorldDx:= WorldDx - rightX + leftX
        else if -WorldDx > rightX then
            WorldDx:= WorldDx + rightX - leftX;
    end;

wdy:= trunc(cScreenHeight / cScaleFactor) + cScreenHeight div 2 - cWaterLine - (cVisibleWater + trunc(CinematicBarH / (cScaleFactor / 2.0)));
if WorldDy < wdy then
    WorldDy:= wdy;

if ((CursorPoint.X = prevPoint.X) and (CursorPoint.Y = prevpoint.Y)) then
    exit;

if (AMState = AMShowingUp) or (AMState = AMShowing) then
begin
{$IFDEF USE_LANDSCAPE_AMMOMENU}
    amNumOffsetX:= 0;
    {$IFDEF USE_AM_NUMCOLUMN}
    amNumOffsetY:= AMSlotSize;
    {$ELSE}
    amNumOffsetY:= 0;
    {$ENDIF}
{$ELSE}
    amNumOffsetY:= 0;
    {$IFDEF USE_AM_NUMCOLUMN}
    amNumOffsetX:= AMSlotSize;
    {$ELSE}
    amNumOffsetX:= 0;
    {$ENDIF}

{$ENDIF}
    if CursorPoint.X < AmmoRect.x + amNumOffsetX + 3 then//check left
        CursorPoint.X:= AmmoRect.x + amNumOffsetX + 3;
    if CursorPoint.X > AmmoRect.x + AmmoRect.w - 3 then//check right
        CursorPoint.X:= AmmoRect.x + AmmoRect.w - 3;
    if CursorPoint.Y > cScreenHeight - AmmoRect.y -amNumOffsetY - 1 then//check top
        CursorPoint.Y:= cScreenHeight - AmmoRect.y - amNumOffsetY - 1;
    if CursorPoint.Y < cScreenHeight - (AmmoRect.y + AmmoRect.h - AMSlotSize - 5) then//check bottom
        CursorPoint.Y:= cScreenHeight - (AmmoRect.y + AmmoRect.h - AMSlotSize - 5);
    prevPoint:= CursorPoint;
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
if (CurrentTeam^.ExtDriven and isCursorVisible and autoCameraOn) or
   (not CurrentTeam^.ExtDriven and isCursorVisible) or ((FollowGear <> nil) and autoCameraOn) then
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

    shs:= min(cScreenHeight div 2 - trunc(cScreenHeight / cScaleFactor) + EdgesDist, cScreenHeight - EdgesDist);
    if CursorPoint.Y < shs then
        begin
        WorldDy:= WorldDy + CursorPoint.Y - shs;
        CursorPoint.Y:= shs;
        end
    else
        if (CursorPoint.Y > cScreenHeight - EdgesDist) then
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
if WorldDy > LAND_HEIGHT + 1024 then
    WorldDy:= LAND_HEIGHT + 1024;
if WorldDy < wdy then
    WorldDy:= wdy;
if WorldDx < - LAND_WIDTH - 1024 then
    WorldDx:= - LAND_WIDTH - 1024;
if WorldDx > 1024 then
    WorldDx:= 1024;
end;

procedure ShowMission(caption, subcaption, text: ansistring; icon, time : LongInt);
begin
    ShowMission(caption, subcaption, text, icon, time, false);
end;

procedure ShowMission(caption, subcaption, text: ansistring; icon, time : LongInt; forceDisplay : boolean);
var r: TSDL_Rect;
begin
if cOnlyStats then exit;

r.w:= 32;
r.h:= 32;

// If true, then mission panel cannot be hidden by releasing the mission panel key.
// Is in effect until timer runs out, is hidden with HideMission or ShowMission is called with forceDisplay=false.
isForceMission := forceDisplay;

if time = 0 then
    time:= 5000;
missionTimer:= time;
FreeAndNilTexture(missionTex);

if icon > -1 then
    begin
    r.x:= 0;
    r.y:= icon * 32;
    missionTex:= RenderHelpWindow(caption, subcaption, text, ansistring(''), 0, MissionIcons, @r)
    end
else
    begin
    r.x:= ((-icon - 1) shr 4) * 32;
    r.y:= ((-icon - 1) mod 16) * 32;
    missionTex:= RenderHelpWindow(caption, subcaption, text, ansistring(''), 0, SpritesData[sprAMAmmos].Surface, @r)
    end;
end;

procedure HideMission;
begin
    missionTimer:= 0;
    isForceMission:= false;
end;

procedure SetAmmoTexts(ammoType: TAmmoType; name: ansistring; caption: ansistring; description: ansistring; autoLabels: boolean);
var
    ammoStrId: TAmmoStrId;
    ammoStr: ansistring;
    tmpsurf: PSDL_Surface;
begin
    if cOnlyStats then exit;
    
    ammoStrId := Ammoz[ammoType].NameId;

    trluaammo[ammoStrId] := name;
    if length(trluaammo[ammoStrId]) > 0 then
        ammoStr:= trluaammo[ammoStrId]
    else
        ammoStr:= trammo[ammoStrId];

    if checkFails(length(ammoStr) > 0,'No default text/translation found for ammo type #' + intToStr(ord(ammoType)) + '!',true) then exit;

    tmpsurf:= TTF_RenderUTF8_Blended(Fontz[CheckCJKFont(ammoStr,fnt16)].Handle, PChar(ammoStr), cWhiteColorChannels);
    if checkFails(tmpsurf <> nil,'Name-texture creation for ammo type #' + intToStr(ord(ammoType)) + ' failed!',true) then exit;
    tmpsurf:= doSurfaceConversion(tmpsurf);
    FreeAndNilTexture(Ammoz[ammoType].NameTex);
    Ammoz[ammoType].NameTex:= Surface2Tex(tmpsurf, false);
    SDL_FreeSurface(tmpsurf);

    trluaammoc[ammoStrId] := caption;
    trluaammod[ammoStrId] := description;
    trluaammoe[ammoStrId] := autoLabels;
end;

procedure ShakeCamera(amount: LongInt);
begin
if isCursorVisible then
    exit;
amount:= Max(1, round(amount*zoom/2));
WorldDx:= WorldDx - amount + LongInt(random(1 + amount * 2));
WorldDy:= WorldDy - amount + LongInt(random(1 + amount * 2));
//CursorPoint.X:= CursorPoint.X - amount + LongInt(random(1 + amount * 2));
//CursorPoint.Y:= CursorPoint.Y - amount + LongInt(random(1 + amount * 2))
end;


procedure onFocusStateChanged;
begin
{$IFDEF MOBILE}
if (not cHasFocus) and (not isPaused) then
    ParseCommand('pause', true);
// when created SDL receives an exposure event that calls UndampenAudio at full power, muting audio
exit;
{$ENDIF}
if (not cHasFocus) and (GameState <> gsConfirm) then
    ParseCommand('quit', true);

{$IFDEF USE_VIDEO_RECORDING}
// do not change volume during prerecording as it will affect sound in video file
if (not flagPrerecording) then
{$ENDIF}
    begin
    if (not cHasFocus) then DampenAudio()
    else UndampenAudio();
    end;
end;

procedure updateCursorVisibility;
begin
    if isPaused or isAFK or (GameState = gsConfirm) then
        begin
{$IFNDEF USE_TOUCH_INTERFACE}
        SDL_SetRelativeMouseMode(SDL_FALSE);
{$ENDIF}
        if SDL_ShowCursor(SDL_QUERY) = SDL_DISABLE then
            begin
            uCursor.resetPosition;
{$IFNDEF USE_TOUCH_INTERFACE}
            SDL_ShowCursor(SDL_ENABLE);
{$ENDIF}
            end;
        end
    else
        begin
        uCursor.resetPositionDelta;
{$IFNDEF USE_TOUCH_INTERFACE}
        SDL_ShowCursor(SDL_DISABLE);
        SDL_SetRelativeMouseMode(SDL_TRUE);
{$ENDIF}
        end;
end;

procedure updateTouchWidgets(ammoType: TAmmoType);
begin
{$IFDEF USE_TOUCH_INTERFACE}
//show the aiming buttons + animation
if (Ammoz[ammoType].Ammo.Propz and ammoprop_NeedUpDown) <> 0 then
    begin
    if (not arrowUp.show) then
        begin
        animateWidget(@arrowUp, true, true);
        animateWidget(@arrowDown, true, true);
        end;
    end
else
    if arrowUp.show then
        begin
        animateWidget(@arrowUp, true, false);
        animateWidget(@arrowDown, true, false);
        end;
SetUtilityWidgetState(ammoType);
{$ELSE}
ammoType:= ammoType; // avoid hint
{$ENDIF}
end;

procedure SetUtilityWidgetState(ammoType: TAmmoType);
begin
{$IFDEF USE_TOUCH_INTERFACE}
if(ammoType = amNothing)then
    ammoType:= CurrentHedgehog^.CurAmmoType;

if(CurrentHedgehog <> nil)then
    if ((Ammoz[ammoType].Ammo.Propz and ammoprop_Timerable) <> 0) and (ammoType <> amDrillStrike) then
        begin
        utilityWidget.sprite:= sprTimerButton;
        if (not utilityWidget.show) then
            animateWidget(@utilityWidget, true, true);
        end
    else if (Ammoz[ammoType].Ammo.Propz and ammoprop_NeedTarget) <> 0 then
        begin
        utilityWidget.sprite:= sprTargetButton;
        if (not utilityWidget.show) then
            animateWidget(@utilityWidget, true, true);
        end
    else if ammoType = amSwitch then
        begin
        utilityWidget.sprite:= sprSwitchButton;
        if (not utilityWidget.show) then
            animateWidget(@utilityWidget, true, true);
        end
    else if utilityWidget.show then
        animateWidget(@utilityWidget, true, false);

    if ((Ammoz[ammoType].Ammo.Propz and ammoprop_SetBounce) <> 0) then
        begin
        utilityWidget2.sprite:= sprBounceButton;
        if (not utilityWidget2.show) then
            animateWidget(@utilityWidget2, true, true);
        end
    else if utilityWidget2.show then
        animateWidget(@utilityWidget2, true, false);
{$ELSE}
ammoType:= ammoType; // avoid hint
{$ENDIF}
end;

procedure animateWidget(widget: POnScreenWidget; fade, showWidget: boolean);
begin
with widget^ do
    begin
    show:= showWidget;
    if fade then fadeAnimStart:= RealTicks;

    with moveAnim do
        begin
        animate:= true;
        startTime:= RealTicks;
        source.x:= source.x xor target.x; //swap source <-> target
        target.x:= source.x xor target.x;
        source.x:= source.x xor target.x;
        source.y:= source.y xor target.y;
        target.y:= source.y xor target.y;
        source.y:= source.y xor target.y;
        end;
    end;
end;


procedure initModule;
begin
    fpsTexture:= nil;
    recTexture:= nil;
    FollowGear:= nil;
    WindBarWidth:= 0;
    bShowAmmoMenu:= false;
    bSelected:= false;
    bShowFinger:= false;
    Frames:= 0;
    WorldDx:= -512;
    WorldDy:= -256;
    PrevSentPointTime:= 0;

    FPS:= 0;
    CountTicks:= 0;
    SoundTimerTicks:= 0;
    prevPoint.X:= 0;
    prevPoint.Y:= 0;
    missionTimer:= 0;
    missionTex:= nil;
    cOffsetY:= 0;
    AMState:= AMHidden;
    isFirstFrame:= true;

    FillChar(WorldFade, sizeof(WorldFade), 0);
    WorldFade[0].a:= 255;
    WorldFade[1].a:= 255;
    FillChar(WorldEnd, sizeof(WorldEnd), 0);
    WorldEnd[0].a:= 255;
    WorldEnd[1].a:= 255;
    WorldEnd[2].a:= 255;
    WorldEnd[3].a:= 255;

    AmmoMenuTex:= nil;
    AmmoMenuInvalidated:= true
end;

procedure freeModule;
begin
    ResetWorldTex();
end;

end.
