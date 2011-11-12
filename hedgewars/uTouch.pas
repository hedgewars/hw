(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2011 Richard Deurwaarder <xeli@xelification.com>
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

unit uTouch;

interface

uses sysutils, math, uConsole, uVariables, SDLh, uTypes, uFloat, uConsts, uIO, uCommands, GLUnit;

type
    PTouch_Finger = ^Touch_Finger;
    Touch_Finger = record
        id                       : SDL_FingerId;
        x,y                      : LongInt;
        historicalX, historicalY : LongInt;
        timeSinceDown            : Longword;
        end;

procedure initModule;

procedure ProcessTouch;
procedure onTouchDown(x,y: Longword; pointerId: SDL_FingerId);
procedure onTouchMotion(x,y: Longword; dx,dy: LongInt; pointerId: SDL_FingerId);
procedure onTouchUp(x,y: Longword; pointerId: SDL_FingerId);
function convertToCursor(scale: LongInt; xy: LongInt): LongInt;
function addFinger(x,y: Longword; id: SDL_FingerId): PTouch_Finger;
procedure deleteFinger(id: SDL_FingerId);
procedure onTouchClick(finger: Touch_Finger);
procedure onTouchDoubleClick(finger: Touch_Finger);

function findFinger(id: SDL_FingerId): PTouch_Finger;
procedure aim(finger: Touch_Finger);
function isOnCrosshair(finger: Touch_Finger): boolean;
function isOnCurrentHog(finger: Touch_Finger): boolean;
function isOnFireButton(finger: Touch_Finger): boolean;
procedure convertToWorldCoord(var x,y: hwFloat; finger: Touch_Finger);
procedure convertToFingerCoord(var x,y: hwFloat; oldX, oldY: hwFloat);
function fingerHasMoved(finger: Touch_Finger): boolean;
function calculateDelta(finger1, finger2: Touch_Finger): hwFloat;
function getSecondFinger(finger: Touch_Finger): PTouch_Finger;
procedure printFinger(finger: Touch_Finger);
implementation

const
    clicktime = 200;
    nilFingerId = High(SDL_FingerId);

var
    fireButtonLeft, fireButtonRight, fireButtonTop, fireButtonBottom : LongInt;
        


    leftButtonBoundary  : LongInt;
    rightButtonBoundary : LongInt;
    topButtonBoundary   : LongInt;
    
    pointerCount : Longword;
    fingers: array of Touch_Finger;
    moveCursor : boolean;
    invertCursor : boolean;

    xTouchClick,yTouchClick : LongInt;
    timeSinceClick : Longword;

    //Pinch to zoom 
    pinchSize : hwFloat;
    baseZoomValue: GLFloat;


    //aiming
    aiming, movingCrosshair: boolean; 
    crosshairCommand: ShortString;
    targetAngle: LongInt;
    stopFiring: boolean;

    //moving
    stopLeft, stopRight, walkingLeft, walkingRight :  boolean;


procedure onTouchDown(x,y: Longword; pointerId: SDL_FingerId);
var 
    finger: PTouch_Finger;
begin
    finger := addFinger(x,y,pointerId);
    case pointerCount of
        1:
        begin
            moveCursor:= false;
            if bShowAmmoMenu then
            begin
                moveCursor := true;
                exit;
            end;

            if isOnCrosshair(finger^) then
            begin
                aiming:= true;
                exit;
            end;

            if isOnFireButton(finger^) then
            begin
                stopFiring:= false;
                ParseCommand('+attack', true);
                exit;
            end;
            if (finger^.x < leftButtonBoundary) and (finger^.y < 390) then
            begin
                ParseCommand('+left', true);
                walkingLeft := true;
                exit;
            end;
            if finger^.x > rightButtonBoundary then
            begin
                ParseCommand('+right', true);
                walkingRight:= true;
                exit;
            end;
            if finger^.y < topButtonBoundary then
            begin
                ParseCommand('hjump', true);
                exit;
            end;
            moveCursor:= true; 
        end;
        2:
        begin
            aiming:= false;
            stopFiring:= true;
            moveCursor:= false;
            pinchSize := calculateDelta(finger^, getSecondFinger(finger^)^);
            baseZoomValue := ZoomValue
        end;
    end;//end case pointerCount of
end;

procedure onTouchMotion(x,y: Longword;dx,dy: LongInt; pointerId: SDL_FingerId);
var
    finger, secondFinger: PTouch_Finger;
    currentPinchDelta, zoom : hwFloat;
    tmpX, tmpY: LongInt;
begin
    x := x;
    y := y;
    dx := dx;
    dy := dy;
    finger:= findFinger(pointerId);
    tmpX := convertToCursor(cScreenWidth, x);
    tmpY := convertToCursor(cScreenHeight, y);

    if moveCursor then
    begin
        if invertCursor then
        begin
            CursorPoint.X := CursorPoint.X + (finger^.x - tmpX);
            CursorPoint.Y := CursorPoint.Y - (finger^.y - tmpY);
        end
        else
        begin
            CursorPoint.X := CursorPoint.X - (finger^.x - tmpX);
            CursorPoint.Y := CursorPoint.Y + (finger^.y - tmpY);
        end;
        finger^.x := tmpX;
        finger^.y := tmpY;
        exit //todo change into switch rather than ugly ifs
    end;
    
    finger^.x := tmpX;
    finger^.y := tmpY;
    
    if aiming then 
    begin
        aim(finger^);
        exit
    end;
    if pointerCount = 2 then
    begin
       secondFinger := getSecondFinger(finger^);
       currentPinchDelta := calculateDelta(finger^, secondFinger^) - pinchSize;
       zoom := currentPinchDelta/cScreenWidth;
       ZoomValue := baseZoomValue - ((hwFloat2Float(zoom) * cMinMaxZoomLevelDelta));
       if ZoomValue < cMaxZoomLevel then ZoomValue := cMaxZoomLevel;
       if ZoomValue > cMinZoomLevel then ZoomValue := cMinZoomLevel;
    end;
end;

procedure onTouchUp(x,y: Longword; pointerId: SDL_FingerId);
begin
    x := x;
    y := y;
    aiming:= false;
    stopFiring:= true;
    deleteFinger(pointerId);

    if walkingLeft then
    begin
        ParseCommand('-left', true);
        walkingLeft := false;
    end;

    if walkingRight then
    begin
        ParseCommand('-right', true);
        walkingRight := false;
    end;
end;

procedure onTouchDoubleClick(finger: Touch_Finger);
begin
    finger := finger;//avoid compiler hint
    ParseCommand('ljump', true);
end;

procedure onTouchClick(finger: Touch_Finger);
begin
    if (SDL_GetTicks - timeSinceClick < 300) and (DistanceI(finger.X-xTouchClick, finger.Y-yTouchClick) < _30) then
    begin
    onTouchDoubleClick(finger);
    exit; 
    end
    else
    begin
        xTouchClick := finger.x;
        yTouchClick := finger.y;
        timeSinceClick := SDL_GetTicks;
    end;

    if bShowAmmoMenu then 
    begin
        doPut(CursorPoint.X, CursorPoint.Y, false); 
        exit
    end;

    if isOnCurrentHog(finger) then
    begin
        bShowAmmoMenu := true;
        exit;
    end;

    if finger.y < topButtonBoundary then
    begin
        ParseCommand('hjump', true);
        exit;
    end;
end;

function addFinger(x,y: Longword; id: SDL_FingerId): PTouch_Finger;
var 
    xCursor, yCursor, index : LongInt;
begin
    //Check array sizes
    if length(fingers) < Integer(pointerCount) then 
    begin
        setLength(fingers, length(fingers)*2);
        for index := length(fingers) div 2 to length(fingers) do fingers[index].id := nilFingerId;
    end;
    
    
    xCursor := convertToCursor(cScreenWidth, x);
    yCursor := convertToCursor(cScreenHeight, y);
    
    //on removing fingers, all fingers are moved to the left
    //with dynamic arrays being zero based, the new position of the finger is the old pointerCount
    fingers[pointerCount].id := id;
    fingers[pointerCount].historicalX := xCursor;
    fingers[pointerCount].historicalY := yCursor;
    fingers[pointerCount].x := xCursor;
    fingers[pointerCount].y := yCursor;
    fingers[pointerCount].timeSinceDown:= SDL_GetTicks;
 
    addFinger:= @fingers[pointerCount];
    inc(pointerCount);
end;

procedure deleteFinger(id: SDL_FingerId);
var
    index : Longword;
begin
    
    dec(pointerCount);
    for index := 0 to pointerCount do
    begin
         if fingers[index].id = id then
         begin
             //Check for onTouchClick event
             if ((SDL_GetTicks - fingers[index].timeSinceDown) < clickTime) AND  
                 not(fingerHasMoved(fingers[index])) then onTouchClick(fingers[index]);

             //put the last finger into the spot of the finger to be removed, 
             //so that all fingers are packed to the far left
             if  pointerCount <> index then
             begin
                fingers[index].id := fingers[pointerCount].id;    
                fingers[index].x := fingers[pointerCount].x;    
                fingers[index].y := fingers[pointerCount].y;    
                fingers[index].historicalX := fingers[pointerCount].historicalX;    
                fingers[index].historicalY := fingers[pointerCount].historicalY;    
                fingers[index].timeSinceDown := fingers[pointerCount].timeSinceDown;

                fingers[pointerCount].id := nilFingerId;
             end
             else fingers[index].id := nilFingerId;
             break;
         end;
    end;

end;

procedure ProcessTouch;
var
    deltaAngle: LongInt;
begin
    invertCursor := not(bShowAmmoMenu);
    if aiming then
    begin
        if CurrentHedgehog^.Gear <> nil then
        begin
            deltaAngle:= CurrentHedgehog^.Gear^.Angle - targetAngle;
            if (deltaAngle <> 0) and not(movingCrosshair) then 
            begin
                ParseCommand('+' + crosshairCommand, true);
                movingCrosshair := true;
            end
            else 
                if movingCrosshair then 
                begin
                    ParseCommand('-' + crosshairCommand, true);
                    movingCrosshair:= false;
                end;
        end;
    end
    else if movingCrosshair then 
    begin
        ParseCommand('-' + crosshairCommand, true);
        movingCrosshair := false;
    end;

    if stopFiring then 
    begin
        ParseCommand('-attack', true);
        stopFiring:= false;
    end;
    
    if stopRight then
    begin
        stopRight := false;
        ParseCommand('-right', true);
    end;
 
    if stopLeft then
    begin
        stopLeft := false;
        ParseCommand('-left', true);
    end;
    
end;

function findFinger(id: SDL_FingerId): PTouch_Finger;
var
    index: LongWord;
begin
   for index := 0 to High(fingers) do
       if fingers[index].id = id then 
       begin
           findFinger := @fingers[index];
           break;
       end;
end;

procedure aim(finger: Touch_Finger);
var 
    hogX, hogY, touchX, touchY, deltaX, deltaY, tmpAngle: hwFloat;
    tmp: ShortString;
begin
    if CurrentHedgehog^.Gear <> nil then
    begin
        touchX := _0;//avoid compiler hint
        touchY := _0;
        hogX := CurrentHedgehog^.Gear^.X;
        hogY := CurrentHedgehog^.Gear^.Y;

        convertToWorldCoord(touchX, touchY, finger);
        deltaX := hwAbs(TouchX-HogX);
        deltaY := (TouchY-HogY);
        
        tmpAngle:= DeltaY / Distance(deltaX, deltaY) *_2048;
        targetAngle:= (hwRound(tmpAngle) + 2048) div 2;

        tmp := crosshairCommand;
        if CurrentHedgehog^.Gear^.Angle - targetAngle < 0 then crosshairCommand := 'down'
        else crosshairCommand:= 'up';
        if movingCrosshair and (tmp <> crosshairCommand) then 
        begin
            ParseCommand('-' + tmp, true);
            movingCrosshair := false;
        end;

    end; //if CurrentHedgehog^.Gear <> nil
end;

function convertToCursor(scale: LongInt; xy: LongInt): LongInt;
begin
    convertToCursor := round(xy/32768*scale)
end;

function isOnFireButton(finger: Touch_Finger): boolean;
begin
    isOnFireButton:= (finger.x <= fireButtonRight) and (finger.x >= fireButtonLeft) and (finger.y <= fireButtonBottom) and (finger.y >= fireButtonTop);
end;

function isOnCrosshair(finger: Touch_Finger): boolean;
var
    x,y : hwFloat;
begin
    x := _0;//avoid compiler hint
    y := _0;
    convertToFingerCoord(x, y, int2hwFloat(CrosshairX), int2hwFloat(CrosshairY));
    isOnCrosshair:= Distance(int2hwFloat(finger.x)-x, int2hwFloat(finger.y)-y) < _50;
end;

function isOnCurrentHog(finger: Touch_Finger): boolean;
var
    x,y : hwFloat;
begin
    x := _0;
    y := _0;
    convertToFingerCoord(x, y, CurrentHedgehog^.Gear^.X, CurrentHedgehog^.Gear^.Y);
    isOnCurrentHog := Distance(int2hwFloat(finger.X)-x, int2hwFloat(finger.Y)-y) < _50;
end;

procedure convertToFingerCoord(var x,y : hwFloat; oldX, oldY: hwFloat);
begin
    x := oldX + int2hwFloat(WorldDx + (cScreenWidth div 2));
    y := oldY + int2hwFloat(WorldDy);
end;

procedure convertToWorldCoord(var x,y: hwFloat; finger: Touch_Finger);
begin
//if x <> nil then 
    x := int2hwFloat((finger.x-WorldDx) - (cScreenWidth div 2));
//if y <> nil then 
    y := int2hwFloat(finger.y-WorldDy);
end;

//Method to calculate the distance this finger has moved since the downEvent
function fingerHasMoved(finger: Touch_Finger): boolean;
begin
    fingerHasMoved := trunc(sqrt(Power(finger.X-finger.historicalX,2) + Power(finger.y-finger.historicalY, 2))) > 330;
end;

function calculateDelta(finger1, finger2: Touch_Finger): hwFloat; inline;
begin
    calculateDelta := DistanceI(finger2.x-finger1.x, finger2.y-finger1.y);
end;

// Under the premise that all pointer ids in pointerIds:SDL_FingerId are packed to the far left.
// If the pointer to be ignored is not pointerIds[0] the second must be there
function getSecondFinger(finger: Touch_Finger): PTouch_Finger;
begin
    if fingers[0].id = finger.id then getSecondFinger := @fingers[1]
    else getSecondFinger := @fingers[0];
end;

procedure printFinger(finger: Touch_Finger);
begin
    WriteToConsole(Format('id:%d, (%d,%d), (%d,%d), time: %d', [finger.id, finger.x, finger.y, finger.historicalX, finger.historicalY, finger.timeSinceDown]));
end;

procedure initModule;
var
    index: Longword;
    //uRenderCoordScaleX, uRenderCoordScaleY: Longword;
begin
    movingCrosshair := false;
    stopFiring:= false;
    walkingLeft := false;
    walkingRight := false;

    leftButtonBoundary := cScreenWidth div 4;
    rightButtonBoundary := cScreenWidth div 4*3;
    topButtonBoundary := cScreenHeight div 6;
    
    setLength(fingers, 4);
    for index := 0 to High(fingers) do 
        fingers[index].id := nilFingerId;


    //uRenderCoordScaleX := Round(cScreenWidth/0.8 * 2);
    fireButtonLeft := Round(cScreenWidth*0.01);
    fireButtonRight := Round(fireButtonLeft + (spritesData[sprFireButton].Width*0.4));
    fireButtonBottom := Round(cScreenHeight*0.99);
    fireButtonTop := fireButtonBottom - Round(spritesData[sprFireButton].Height*0.4);
end;

begin
end.
