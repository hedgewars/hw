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
{$IF GLunit = GL}{$DEFINE GLunit:=GL,GLext}{$ENDIF}

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
procedure HideMission;
procedure ShakeCamera(amount: LongInt);
procedure InitCameraBorders;
procedure InitTouchInterface;
procedure SetUtilityWidgetState(ammoType: TAmmoType);
procedure animateWidget(widget: POnScreenWidget; fade, showWidget: boolean);
procedure MoveCamera;
procedure onFocusStateChanged;

implementation
uses
    uStore,
    uMisc,
    uIO,
    uLocale,
    uSound,
    uAmmos,
    uVisualGears,
    uChat,
    uLandTexture,
    GLunit,
    uVariables,
    uUtils,
    uTextures,
    uRender,
    uCaptions,
    uCursor,
    uCommands,
    uMobile
    ;

var cWaveWidth, cWaveHeight: LongInt;
    AMShiftTargetX, AMShiftTargetY, AMShiftX, AMShiftY, SlotsNum: LongInt;
    AMAnimStartTime, AMState : LongInt;
    AMAnimState: Single;
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
    isFirstFrame: boolean;
    AMAnimType: LongInt;

const cStereo_Sky           = 0.0500;
      cStereo_Horizon       = 0.0250;
      cStereo_MidDistance   = 0.0175;
      cStereo_Water_distant = 0.0125;
      cStereo_Land          = 0.0075;
      cStereo_Water_near    = 0.0025;
      cStereo_Outside       = -0.0400;

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

// if special game flags/settings are changed, add them to the game mode notice window and then show it
g:= ''; // no text/things to note yet

// add custom goals from lua script if there are any
if LuaGoals <> '' then
    g:= LuaGoals + '|';

// check different game flags (goals/game modes first for now)
g:= AddGoal(g, gfKing, gidKing); // king?
g:= AddGoal(g, gfTagTeam, gidTagTeam); // tag team mode?

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
if g <> '' then
    ShowMission(trgoal[gidCaption], trgoal[gidSubCaption], g, 1, 0);

cWaveWidth:= SpritesData[sprWater].Width;
//cWaveHeight:= SpritesData[sprWater].Height;
cWaveHeight:= 32;

InitCameraBorders();
uCursor.init();
prevPoint.X:= 0;
prevPoint.Y:= cScreenHeight div 2;
WorldDx:=  -(LAND_WIDTH div 2) + cScreenWidth div 2;
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
{$IFDEF ANDROID}
buttonScale:= Android_JNI_getDensity()/cDefaultZoomLevel;
{$ELSE}
buttonScale:= 1.5/cDefaultZoomLevel;
{$ENDIF}


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
{$ENDIF}
end;

// for uStore texture resetting
procedure ResetWorldTex;
begin
    FreeTexture(fpsTexture);
    fpsTexture:= nil;
    FreeTexture(timeTexture);
    timeTexture:= nil;
    FreeTexture(missionTex);
    missionTex:= nil;
end;

function GetAmmoMenuTexture(Ammo: PHHAmmo): PTexture;
const BORDERSIZE = 2;
var x, y, i, t, SlotsNumY, SlotsNumX, AMFrame: LongInt;
    STurns: LongInt;
    amSurface: PSDL_Surface;
    AMRect: TSDL_Rect;
{$IFDEF USE_AM_NUMCOLUMN}tmpsurf: PSDL_Surface;{$ENDIF}
begin
    SlotsNum:= 0;
    for i:= 0 to cMaxSlotIndex do
        if((i = 0) and (Ammo^[i,1].Count > 0)) or ((i <> 0) and (Ammo^[i,0].Count > 0)) then
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
    for i:= 0 to cMaxSlotIndex do
        if ((i = 0) and (Ammo^[i, 1].Count > 0)) or ((i <> 0) and (Ammo^[i, 0].Count > 0)) then
            begin
{$IFDEF USE_LANDSCAPE_AMMOMENU}
            y:= AMRect.y;
{$ELSE}
            x:= AMRect.x;
{$ENDIF}
{$IFDEF USE_AM_NUMCOLUMN}
            tmpsurf:= TTF_RenderUTF8_Blended(Fontz[fnt16].Handle, Str2PChar('F' + IntToStr(i+1)), cWhiteColorChannels);
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
if (TurnTimeLeft = 0) or (not CurrentTeam^.ExtDriven and (((CurAmmoGear = nil)
or ((Ammoz[CurAmmoGear^.AmmoType].Ammo.Propz and ammoprop_AltAttack) = 0)) and hideAmmoMenu)) then
    bShowAmmoMenu:= false;

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
    FreeTexture(AmmoMenuTex);
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
    AMShiftTargetX:= (cScreenWidth shr 1) - AmmoRect.x;
    AMShiftTargetY:= cScreenHeight        - AmmoRect.y;

    if (AMAnimType and AMTypeMaskX) <> 0 then AMShiftTargetX:= (cScreenWidth shr 1) - AmmoRect.x
    else AMShiftTargetX:= 0;
    if (AMAnimType and AMTypeMaskY) <> 0 then AMShiftTargetY:= cScreenHeight        - AmmoRect.y
    else AMShiftTargetY:= 0;

    AMShiftX:= AMShiftTargetX;
    AMShiftY:= AMShiftTargetY;
end;

AMAnimState:= (RealTicks - AMAnimStartTime) / AMAnimDuration;

if AMState = AMShowing then
    begin
    FollowGear:=nil;
    end;

if AMState = AMShowingUp then // show ammo menu
    begin
    if (cReducedQuality and rqSlowMenu) <> 0 then
        begin
        AMShiftX:= 0;
        AMShiftY:= 0;
        AMState:= AMShowing;
        end
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
    if (cReducedQuality and rqSlowMenu) <> 0 then
        begin
        AMShiftX:= AMShiftTargetX;
        AMShiftY:= AMShiftTargetY;
        AMState:= AMHidden;
        end
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
            AMState:= AMHidden;
            end;
    end;
    
DrawTexture(AmmoRect.x + AMShiftX, AmmoRect.y + AMShiftY, AmmoMenuTex);

if ((AMState = AMHiding) or (AMState = AMShowingUp)) and ((AMAnimType and AMTypeMaskAlpha) <> 0 )then 
    Tint($FF, $ff, $ff, $ff);

Pos:= -1;
Slot:= -1;
{$IFDEF USE_LANDSCAPE_AMMOMENU}
    {$IFDEF USE_AM_NUMCOLUMN}
c:= 0;
    {$ELSE}
c:= -1;
    {$ENDIF}
    for i:= 0 to cMaxSlotIndex do
        if ((i = 0) and (Ammo^[i, 1].Count > 0)) or ((i <> 0) and (Ammo^[i, 0].Count > 0)) then
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
                       (CursorPoint.Y >= (cScreenHeight - AmmoRect.y) - ((g+1) * (AMSlotSize+1))) and
                       (CursorPoint.X >= AmmoRect.x                   + ( c    * (AMSlotSize+1))) and 
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
    {$IFDEF USE_AM_NUMCOLUMN}
c:= -1;
    {$ELSE}
c:= 0;
    {$ENDIF}
    for i:= 0 to cMaxSlotIndex do
        if ((i = 0) and (Ammo^[i, 1].Count > 0)) or ((i <> 0) and (Ammo^[i, 0].Count > 0)) then
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
                       (CursorPoint.Y >= (cScreenHeight - AmmoRect.y) - ((c+1) * (AMSlotSize+1))) and
                       (CursorPoint.X >= AmmoRect.x                   + ( g    * (AMSlotSize+1))) and 
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
    if (Pos >= 0) and (Pos <= cMaxSlotAmmoIndex) and (Slot >= 0) and (Slot <= cMaxSlotIndex)then
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
                            AmmoRect.y + AmmoRect.h - BORDERSIZE - (AMslotSize shr 1) - (CountTexz[Ammo^[Slot, Pos].Count]^.w shr 1),
                            CountTexz[Ammo^[Slot, Pos].Count]);

            if bSelected and (Ammoz[Ammo^[Slot, Pos].AmmoType].SkipTurns - CurrentTeam^.Clan^.TurnNumber < 0) then
                begin
                bShowAmmoMenu:= false;
                SetWeapon(Ammo^[Slot, Pos].AmmoType);
                bSelected:= false;
                FreeWeaponTooltip;
{$IFDEF USE_TOUCH_INTERFACE}//show the aiming buttons + animation
                if (Ammo^[Slot, Pos].Propz and ammoprop_NeedUpDown) <> 0 then
                    begin
                    if not(arrowUp.show) then
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
                SetUtilityWidgetState(Ammo^[Slot, Pos].AmmoType);
{$ENDIF}
                exit
                end;
            end
        end
    else
        FreeWeaponTooltip;

    if (WeaponTooltipTex <> nil) and (AMShiftX = 0) and (AMShiftY = 0) then
{$IFDEF USE_LANDSCAPE_AMMOMENU}
        if not isPhone() then
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

procedure DrawWater(Alpha: byte; OffsetY: LongInt);
var VertexBuffer: array [0..3] of TVertex2f;
    r: TSDL_Rect;
    lw, lh: GLfloat;
begin
if SuddenDeathDmg then
    begin
    SDWaterColorArray[0].a := Alpha;
    SDWaterColorArray[1].a := Alpha;
    SDWaterColorArray[2].a := Alpha;
    SDWaterColorArray[3].a := Alpha
    end
else
    begin
    WaterColorArray[0].a := Alpha;
    WaterColorArray[1].a := Alpha;
    WaterColorArray[2].a := Alpha;
    WaterColorArray[3].a := Alpha
    end;

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

        BeginWater;        
        if SuddenDeathDmg then
            SetColorPointer(@SDWaterColorArray[0])
        else
            SetColorPointer(@WaterColorArray[0]);

        SetVertexPointer(@VertexBuffer[0]);

        glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

        EndWater;
        {$IFNDEF GL2}
        glColor4ub($FF, $FF, $FF, $FF); // must not be Tint() as color array seems to stay active and color reset is required
        {$ENDIF}
        glEnable(GL_TEXTURE_2D);
    end;
end;

procedure DrawWaves(Dir, dX, dY: LongInt; tnt: Byte);
var VertexBuffer, TextureBuffer: array [0..3] of TVertex2f;
    lw, waves: GLfloat;
    sprite: TSprite;
    r: TSDL_Rect;
begin
if SuddenDeathDmg then
    sprite:= sprSDWater
else
    sprite:= sprWater;

cWaveWidth:= SpritesData[sprite].Width;

lw:= cScreenWidth / cScaleFactor;

if SuddenDeathDmg then
    Tint(LongInt(tnt) * SDWaterColorArray[2].r div 255 + 255 - tnt,
         LongInt(tnt) * SDWaterColorArray[2].g div 255 + 255 - tnt,
         LongInt(tnt) * SDWaterColorArray[2].b div 255 + 255 - tnt,
         255
    )
else
    Tint(LongInt(tnt) * WaterColorArray[2].r div 255 + 255 - tnt,
         LongInt(tnt) * WaterColorArray[2].g div 255 + 255 - tnt,
         LongInt(tnt) * WaterColorArray[2].b div 255 + 255 - tnt,
         255
    );

glBindTexture(GL_TEXTURE_2D, SpritesData[sprite].Texture^.atlas^.id);

VertexBuffer[0].X:= -lw;
VertexBuffer[0].Y:= cWaterLine + WorldDy + dY;
VertexBuffer[1].X:= lw;
VertexBuffer[1].Y:= VertexBuffer[0].Y;
VertexBuffer[2].X:= lw;
VertexBuffer[2].Y:= VertexBuffer[0].Y + SpritesData[sprite].Height;
VertexBuffer[3].X:= -lw;
VertexBuffer[3].Y:= VertexBuffer[2].Y;

// this uses texture repeat mode, when using an atlas rect we need to split to several quads here!
r.x := -Trunc(lw) + (( - WorldDx + LongInt(RealTicks shr 6) * Dir + dX) mod cWaveWidth);
r.y:= 0;
r.w:= Trunc(lw + lw);
r.h:= SpritesData[sprite].Texture^.h;
ComputeTexcoords(SpritesData[sprite].Texture, @r, @TextureBuffer);


SetVertexPointer(@VertexBuffer[0]);
SetTexCoordPointer(@TextureBuffer[0]);
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
{$IFNDEF S3D_DISABLED}
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
{$ENDIF}
end;

procedure ChangeDepth(rm: TRenderMode; d: GLfloat);
begin
    d:= d / 5;
    if rm = rmLeftEye then
        d:= -d;
    cStereoDepth:= cStereoDepth + d;
    UpdateProjection;
end;
 
procedure ResetDepth(rm: TRenderMode);
begin
    cStereoDepth:= 0;
    UpdateProjection;
end;
 
procedure DrawWorldStereo(Lag: LongInt; RM: TRenderMode);
var i, t, h: LongInt;
    r: TSDL_Rect;
    tdx, tdy: Double;
    s: shortstring;
    highlight: Boolean;
    smallScreenOffset, offsetX, offsetY, screenBottom: LongInt;
    VertexBuffer: array [0..3] of TVertex2f;
begin
if (cReducedQuality and rqNoBackground) = 0 then
    begin
        // Offsets relative to camera - spare them to wimpier cpus, no bg or flakes for them anyway
        ScreenBottom:= (WorldDy - trunc(cScreenHeight/cScaleFactor) - (cScreenHeight div 2) + cWaterLine);
        offsetY:= 10 * Min(0, -145 - ScreenBottom);
        SkyOffset:= offsetY div 35 + cWaveHeight;
        HorizontOffset:= SkyOffset;
        if ScreenBottom > SkyOffset then
            HorizontOffset:= HorizontOffset + ((ScreenBottom-SkyOffset) div 20);

        // background
        ChangeDepth(RM, cStereo_Sky);
        if SuddenDeathDmg then
            Tint(SDTint, SDTint, SDTint, $FF);
        DrawRepeated(sprSky, sprSkyL, sprSkyR, (WorldDx + LAND_WIDTH div 2) * 3 div 8, SkyOffset);
        ChangeDepth(RM, -cStereo_Horizon);
        DrawRepeated(sprHorizont, sprHorizontL, sprHorizontR, (WorldDx + LAND_WIDTH div 2) * 3 div 5, HorizontOffset);
        if SuddenDeathDmg then
            Tint($FF, $FF, $FF, $FF);
    end;

DrawVisualGears(0);
ChangeDepth(RM, -cStereo_MidDistance);
DrawVisualGears(4);

if (cReducedQuality and rq2DWater) = 0 then
    begin
        // Waves
        DrawWater(255, SkyOffset); 
        ChangeDepth(RM, -cStereo_Water_distant);
        DrawWaves( 1,  0 - WorldDx div 32, - cWaveHeight + offsetY div 35, 64);
        ChangeDepth(RM, -cStereo_Water_distant);
        DrawWaves( -1,  25 + WorldDx div 25, - cWaveHeight + offsetY div 38, 48);
        ChangeDepth(RM, -cStereo_Water_distant);
        DrawWaves( 1,  75 - WorldDx div 19, - cWaveHeight + offsetY div 45, 32);
        ChangeDepth(RM, -cStereo_Water_distant);
        DrawWaves(-1, 100 + WorldDx div 14, - cWaveHeight + offsetY div 70, 24);
    end
else
        DrawWaves(-1, 100, - (cWaveHeight + (cWaveHeight shr 1)), 0);

    changeDepth(RM, cStereo_Land);
    DrawVisualGears(5);
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
DrawVisualGears(6);

if SuddenDeathDmg then
    DrawWater(SDWaterOpacity, 0)
else
    DrawWater(WaterOpacity, 0);

    // Waves
ChangeDepth(RM, cStereo_Water_near);
DrawWaves( 1, 25 - WorldDx div 9, - cWaveHeight, 12);

if (cReducedQuality and rq2DWater) = 0 then
    begin
    //DrawWater(WaterOpacity, - offsetY div 40);
    ChangeDepth(RM, cStereo_Water_near);
    DrawWaves(-1, 50 + WorldDx div 6, - cWaveHeight - offsetY div 40, 8);
    if SuddenDeathDmg then
        DrawWater(SDWaterOpacity, - offsetY div 20)
    else
        DrawWater(WaterOpacity, - offsetY div 20);
    ChangeDepth(RM, cStereo_Water_near);
    DrawWaves( 1, 75 - WorldDx div 4, - cWaveHeight - offsetY div 20, 2);
        if SuddenDeathDmg then
            DrawWater(SDWaterOpacity, - offsetY div 10)
        else
            DrawWater(WaterOpacity, - offsetY div 10);
        ChangeDepth(RM, cStereo_Water_near);
        DrawWaves( -1, 25 + WorldDx div 3, - cWaveHeight - offsetY div 10, 0);
        end
    else
        DrawWaves(-1, 50, - (cWaveHeight shr 1), 0);

// everything after this ChangeDepth will be drawn outside the screen
// note: negative parallax gears should last very little for a smooth stereo effect
    ChangeDepth(RM, cStereo_Outside);
    DrawVisualGears(2);

// everything after this ResetDepth will be drawn at screen level (depth = 0)
// note: everything that needs to be readable should be on this level
    ResetDepth(RM);
    DrawVisualGears(3);

{$WARNINGS OFF}
// Target
if (TargetPoint.X <> NoPointX) and (CurrentTeam <> nil) and (CurrentHedgehog <> nil) then
    begin
    with PHedgehog(CurrentHedgehog)^ do
        begin
        if CurAmmoType = amBee then
            DrawSpriteRotatedF(sprTargetBee, TargetPoint.X + WorldDx, TargetPoint.Y + WorldDy, 0, 0, (RealTicks shr 3) mod 360)
        else
            DrawSpriteRotatedF(sprTargetP, TargetPoint.X + WorldDx, TargetPoint.Y + WorldDy, 0, 0, (RealTicks shr 3) mod 360)
        end
    end;
{$WARNINGS ON}

// this scale is used to keep the various widgets at the same dimension at all zoom levels
SetScale(cDefaultZoomLevel);

// Turn time
{$IFDEF USE_TOUCH_INTERFACE}
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
        DrawSprite(sprBigDigit, -(cScreenWidth shr 1) + t + offsetY, cScreenHeight - offsetX, i mod 10);
        i:= i div 10
        end;
    DrawSprite(sprFrame, -(cScreenWidth shr 1) + t - 4 + offsetY, cScreenHeight - offsetX, 0);
    end;

// Captions
DrawCaptions;

{$IFDEF USE_TOUCH_INTERFACE}
// Draw buttons Related to the Touch interface
DrawScreenWidget(@arrowLeft);
DrawScreenWidget(@arrowRight);
DrawScreenWidget(@arrowUp);
DrawScreenWidget(@arrowDown);

DrawScreenWidget(@fireButton);
DrawScreenWidget(@jumpWidget);
DrawScreenWidget(@AMWidget);
DrawScreenWidget(@pauseButton);
DrawScreenWidget(@utilityWidget);
{$ENDIF}

// Teams Healths
if TeamsCount * 20 > Longword(cScreenHeight) div 7 then  // take up less screen on small displays
    begin
    SetScale(1.5);
    smallScreenOffset:= cScreenHeight div 6;
    if TeamsCount * 20 > Longword(cScreenHeight) div 5 then
        Tint($FF,$FF,$FF,$80);
    end
else smallScreenOffset:= 0;
for t:= 0 to Pred(TeamsCount) do
    with TeamsArray[t]^ do
        begin
        h:= 0;
        highlight:= bShowFinger and (CurrentTeam = TeamsArray[t]) and ((RealTicks mod 1000) < 500);

        if highlight then
            Tint(Clan^.Color shl 8 or $FF);

         // draw name
        DrawTexture(-NameTagTex^.w - 16, cScreenHeight + DrawHealthY + smallScreenOffset, NameTagTex);

        // draw flag
        DrawTexture(-14, cScreenHeight + DrawHealthY + smallScreenOffset, FlagTex);

        // draw health bar
        r.x:= 0;
        r.y:= 0;
        r.w:= 2 + TeamHealthBarWidth;
        r.h:= HealthTex^.h;
        DrawTextureFromRect(14, cScreenHeight + DrawHealthY + smallScreenOffset, @r, HealthTex);

        // draw health bars right border
        inc(r.x, cTeamHealthWidth + 2);
        if TeamHealth = 0 then inc(r.x);
        r.w:= 3;
        DrawTextureFromRect(TeamHealthBarWidth + 16, cScreenHeight + DrawHealthY + smallScreenOffset, @r, HealthTex);

        if not highlight and not hasGone and (TeamHealth > 1) then
            for i:= 0 to cMaxHHIndex do
                if Hedgehogs[i].Gear <> nil then
                    begin
                    inc(h,Hedgehogs[i].Gear^.Health);
                    if h < TeamHealth then DrawTexture(15 + h*TeamHealthBarWidth div TeamHealth, cScreenHeight + DrawHealthY + smallScreenOffset + 1, SpritesData[sprSlider].Texture);
                    end;

        // draw ai kill counter for gfAISurvival
        if (GameFlags and gfAISurvival) <> 0 then
            begin
            DrawTexture(TeamHealthBarWidth + 22, cScreenHeight + DrawHealthY + smallScreenOffset, AIKillsTex);
            end;

        // if highlighted, draw flag and other contents again to keep their colors
        // this approach should be faster than drawing all borders one by one tinted or not
        if highlight then
            begin
            if TeamsCount * 20 > Longword(cScreenHeight) div 5 then
                Tint($FF,$FF,$FF,$80)
            else Tint($FF, $FF, $FF, $FF);

            // draw name
            r.x:= 2;
            r.y:= 2;
            r.w:= NameTagTex^.w - 4;
            r.h:= NameTagTex^.h - 4;
            DrawTextureFromRect(-NameTagTex^.w - 14, cScreenHeight + DrawHealthY + smallScreenOffset + 2, @r, NameTagTex);
            // draw flag
            r.w:= 22;
            r.h:= 15;
            DrawTextureFromRect(-12, cScreenHeight + DrawHealthY + smallScreenOffset + 2, @r, FlagTex);
            // draw health bar
            r.w:= TeamHealthBarWidth + 1;
            r.h:= HealthTex^.h - 4;
            DrawTextureFromRect(16, cScreenHeight + DrawHealthY + smallScreenOffset + 2, @r, HealthTex);
            end;
        end;
if smallScreenOffset <> 0 then
    begin
    SetScale(cDefaultZoomLevel);
    if TeamsCount * 20 > Longword(cScreenHeight) div 5 then
        Tint($FF,$FF,$FF,$FF);
    end;

// Lag alert
if isInLag then
    DrawSprite(sprLag, 32 - (cScreenWidth shr 1), 32, (RealTicks shr 7) mod 12);

// Wind bar
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
if bShowAmmoMenu and ((AMState = AMHidden) or (AMState = AMHiding)) then
    begin
    if (AMState = AMHidden) then
        AMAnimStartTime:= RealTicks
    else
        AMAnimStartTime:= RealTicks - (AMAnimDuration - (RealTicks - AMAnimStartTime));
    AMState:= AMShowingUp;
    end;
if not(bShowAmmoMenu) and ((AMstate = AMShowing) or (AMState = AMShowingUp)) then
    begin
    if (AMState = AMShowing) then
        AMAnimStartTime:= RealTicks
    else
        AMAnimStartTime:= RealTicks - (AMAnimDuration - (RealTicks - AMAnimStartTime));
    AMState:= AMHiding;
    end; 

if bShowAmmoMenu or (AMState = AMHiding) then
    ShowAmmoMenu;

// Cursor
if isCursorVisible and bShowAmmoMenu then
    DrawSprite(sprArrow, CursorPoint.X, cScreenHeight - CursorPoint.Y, (RealTicks shr 6) mod 8);

// Chat
DrawChat;

// various captions
if fastUntilLag then
    DrawTextureCentered(0, (cScreenHeight shr 1), SyncTexture);
if isPaused then
    DrawTextureCentered(0, (cScreenHeight shr 1), PauseTexture);
if not isFirstFrame and (missionTimer <> 0) or isPaused or fastUntilLag or (GameState = gsConfirm) then
    begin
    if (ReadyTimeLeft = 0) and (missionTimer > 0) then
        dec(missionTimer, Lag);
    if missionTimer < 0 then
        missionTimer:= 0; // avoid subtracting below 0
    if missionTex <> nil then
        DrawTextureCentered(0, Min((cScreenHeight shr 1) + 100, cScreenHeight - 48 - missionTex^.h), missionTex);
    end;

// fps
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
        FreeTexture(timeTexture);
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
            tmpSurface:= TTF_RenderUTF8_Blended(Fontz[fnt16].Handle, Str2PChar(s), cWhiteColorChannels);
            tmpSurface:= doSurfaceConversion(tmpSurface);
            FreeTexture(fpsTexture);
            fpsTexture:= Surface2Tex(tmpSurface, false);
            SDL_FreeSurface(tmpSurface)
            end;
        if fpsTexture <> nil then
            DrawTexture((cScreenWidth shr 1) - 60 - offsetY, offsetX, fpsTexture);
        end;

    if CountTicks >= 1000 then
        CountTicks:= 0;

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
    DrawTextureCentered(0, (cScreenHeight shr 1), ConfirmTexture);

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

        SetVertexPointer(@VertexBuffer[0]);
        glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

        glEnable(GL_TEXTURE_2D);
        Tint($FF, $FF, $FF, $FF);
        if not isFirstFrame and ((ScreenFadeValue = 0) or (ScreenFadeValue = sfMax)) then
            ScreenFade:= sfNone
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
            if (CurAmmoType = amNapalm) or (CurAmmoType = amMineStrike) then
                DrawLine(-3000, topY-300, 7000, topY-300, 3.0, (Team^.Clan^.Color shr 16), (Team^.Clan^.Color shr 8) and $FF, Team^.Clan^.Color and $FF, $FF);
            i:= GetCurAmmoEntry(CurrentHedgehog^)^.Pos;
            with Ammoz[CurAmmoType] do
                if PosCount > 1 then
                    DrawSprite(PosSprite, CursorPoint.X - (SpritesData[PosSprite].Width shr 1), cScreenHeight - CursorPoint.Y - (SpritesData[PosSprite].Height shr 1),i);
                end;
        DrawSprite(sprArrow, CursorPoint.X, cScreenHeight - CursorPoint.Y, (RealTicks shr 6) mod 8)
        end
    end;
isFirstFrame:= false
end;

procedure MoveCamera;
var EdgesDist, wdy, shs,z: LongInt;
    PrevSentPointTime: LongWord = 0;
begin
{$IFNDEF MOBILE}
if (not (CurrentTeam^.ExtDriven and isCursorVisible and (not bShowAmmoMenu))) and cHasFocus and (GameState <> gsConfirm) then
    uCursor.updatePosition();
{$ENDIF}
z:= round(200/zoom);
if not PlacingHogs and (FollowGear <> nil) and (not isCursorVisible) and (not bShowAmmoMenu) and (not fastUntilLag) then
    if (not autoCameraOn) or ((abs(CursorPoint.X - prevPoint.X) + abs(CursorPoint.Y - prevpoint.Y)) > 4) then
        begin
        FollowGear:= nil;
        prevPoint:= CursorPoint;
        exit
        end
    else
        begin
        CursorPoint.X:= (prevPoint.X * 7 + hwRound(FollowGear^.X) + hwSign(FollowGear^.dX) * z + WorldDx) div 8;
        if isPhone() or (cScreenHeight < 600) or ((hwSign(FollowGear^.dY) * z) < 10)  then
            CursorPoint.Y:= (prevPoint.Y * 7 + cScreenHeight - (hwRound(FollowGear^.Y) + WorldDy)) div 8
        else
            CursorPoint.Y:= (prevPoint.Y * 7 + cScreenHeight - (hwRound(FollowGear^.Y) + hwSign(FollowGear^.dY) * z + WorldDy)) div 8;
        end;

wdy:= trunc(cScreenHeight / cScaleFactor) + cScreenHeight div 2 - cWaterLine - cVisibleWater;
if WorldDy < wdy then
    WorldDy:= wdy;

if ((CursorPoint.X = prevPoint.X) and (CursorPoint.Y = prevpoint.Y)) then
    exit;

if (AMState = AMShowingUp) or (AMState = AMShowing) then
begin
    if CursorPoint.X < AmmoRect.x then//check left 
        CursorPoint.X:= AmmoRect.x;
    if CursorPoint.X > AmmoRect.x + AmmoRect.w then//check right
        CursorPoint.X:= AmmoRect.x + AmmoRect.w;
    if CursorPoint.Y > cScreenHeight - AmmoRect.y then//check top
        CursorPoint.Y:= cScreenHeight - AmmoRect.y;
    if CursorPoint.Y < cScreenHeight - (AmmoRect.y + AmmoRect.h - AMSlotSize - 2) then//check bottom
        CursorPoint.Y:= cScreenHeight - (AmmoRect.y + AmmoRect.h - AMSlotSize - 2);
    prevPoint:= CursorPoint;
    //if cHasFocus then SDL_WarpMouse(CursorPoint.X + cScreenWidth div 2, cScreenHeight - CursorPoint.Y);
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
//if cHasFocus then SDL_WarpMouse(CursorPoint.X + (cScreenWidth shr 1), cScreenHeight - CursorPoint.Y);
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
var r: TSDL_Rect;
begin
r.w:= 32;
r.h:= 32;

if time = 0 then
    time:= 5000;
missionTimer:= time;
FreeTexture(missionTex);

if icon > -1 then
    begin
    r.x:= 0;
    r.y:= icon * 32;
    missionTex:= RenderHelpWindow(caption, subcaption, text, '', 0, MissionIcons, @r)
    end
else
    begin
    r.x:= ((-icon - 1) shr 4) * 32;
    r.y:= ((-icon - 1) mod 16) * 32;
    missionTex:= RenderHelpWindow(caption, subcaption, text, '', 0, SpritesData[sprAMAmmos].Surface, @r)
    end;
end;

procedure HideMission;
begin
    missionTimer:= 0;
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
if (not cHasFocus) and (GameState <> gsConfirm) then
    ParseCommand('quit', true);

if not cHasFocus then DampenAudio()
else UndampenAudio();
end;

procedure SetUtilityWidgetState(ammoType: TAmmoType);
begin
{$IFDEF USE_TOUCH_INTERFACE}
if(ammoType = amNothing)then
    ammoType:= CurrentHedgehog^.CurAmmoType;

if(CurrentHedgehog <> nil)then
    if (Ammoz[ammoType].Ammo.Propz and ammoprop_Timerable) <> 0 then
        begin
        utilityWidget.sprite:= sprTimerButton;
        animateWidget(@utilityWidget, true, true);
        end 
    else if (Ammoz[ammoType].Ammo.Propz and ammoprop_NeedTarget) <> 0 then
        begin
        utilityWidget.sprite:= sprTargetButton;
        animateWidget(@utilityWidget, true, true);
        end
    else if ammoType = amSwitch then
        begin
        utilityWidget.sprite:= sprTargetButton;
        animateWidget(@utilityWidget, true, true);
        end
    else if utilityWidget.show then
        animateWidget(@utilityWidget, true, false);
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
    cStereoDepth:= 0;
    AMState:= AMHidden;
    isFirstFrame:= true;
end;

procedure freeModule;
begin
    FreeTexture(fpsTexture);
    fpsTexture:= nil;
    FreeTexture(timeTexture);
    timeTexture:= nil;
    FreeTexture(missionTex);
    missionTex:= nil
end;

end.
