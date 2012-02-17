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

uses sysutils, math, uConsole, uVariables, SDLh, uFloat, uConsts, uIO, GLUnit, uTypes;


procedure initModule;

procedure ProcessTouch;
procedure onTouchDown(x,y: Longword; pointerId: TSDL_FingerId);
procedure onTouchMotion(x,y: Longword; dx,dy: LongInt; pointerId: TSDL_FingerId);
procedure onTouchUp(x,y: Longword; pointerId: TSDL_FingerId);
function convertToCursorX(x: LongInt): LongInt;
function convertToCursorY(y: LongInt): LongInt;
function convertToCursorDeltaX(x: LongInt): LongInt;
function convertToCursorDeltaY(y: LongInt): LongInt;
function addFinger(x,y: Longword; id: TSDL_FingerId): PTouch_Data;
function updateFinger(x,y,dx,dy: Longword; id: TSDL_FingerId): PTouch_Data;
procedure deleteFinger(id: TSDL_FingerId);
procedure onTouchClick(finger: TTouch_Data);
procedure onTouchDoubleClick(finger: TTouch_Data);

function findFinger(id: TSDL_FingerId): PTouch_Data;
procedure aim(finger: TTouch_Data);
function isOnCrosshair(finger: TTouch_Data): boolean;
function isOnCurrentHog(finger: TTouch_Data): boolean;
procedure convertToWorldCoord(var x,y: hwFloat; finger: TTouch_Data);
procedure convertToFingerCoord(var x,y: hwFloat; oldX, oldY: hwFloat);
function fingerHasMoved(finger: TTouch_Data): boolean;
function calculateDelta(finger1, finger2: TTouch_Data): hwFloat;
function getSecondFinger(finger: TTouch_Data): PTouch_Data;
function isOnRect(rect: TSDL_Rect; finger: TTouch_Data): boolean;
procedure printFinger(finger: TTouch_Data);
implementation

const
    clicktime = 200;
    nilFingerId = High(TSDL_FingerId);

var
    pointerCount : Longword;
    fingers: array of TTouch_Data;
    moveCursor : boolean;
    invertCursor : boolean;

    xTouchClick,yTouchClick : LongInt;
    timeSinceClick : Longword;

    //Pinch to zoom 
    pinchSize : hwFloat;
    baseZoomValue: GLFloat;

    //aiming
    aiming: boolean;
    aimingUp, aimingDown: boolean; 
    targetAngle: LongInt;
    stopFiring: boolean;

    //moving
    stopLeft, stopRight, walkingLeft, walkingRight :  boolean;

procedure onTouchDown(x,y: Longword; pointerId: TSDL_FingerId);
var 
    finger: PTouch_Data;
begin
{$IFDEF USE_TOUCH_INTERFACE}
finger := addFinger(x,y,pointerId);
case pointerCount of
        1:
        begin
            moveCursor:= false;

            if isOnCrosshair(finger^) then
            begin
                aiming:= true;
                aim(finger^);
                exit;
            end;

            if isOnRect(fireButton.active, finger^) then
            begin
                stopFiring:= false;
                spaceKey:= true;
                exit;
            end;
            if isOnRect(arrowLeft.active, finger^) then
            begin
                leftKey:= true;
                walkingLeft := true;
                exit;
            end;
            if isOnRect(arrowRight.active, finger^) then
            begin
                rightKey:= true;
                walkingRight:= true;
                exit;
            end;
            if isOnRect(arrowUp.active, finger^) then
            begin
                upKey:= true;
                aimingUp:= true;
                exit;
            end;
            if isOnRect(arrowDown.active, finger^) then
            begin
                downKey:= true;
                aimingDown:= true;
                exit;
            end;

            if isOnRect(backjump.active, finger^) then
            begin
                enterKey:= true;
                exit;
            end;
            if isOnRect(forwardjump.active, finger^) then
            begin
                backspaceKey:= true;
                exit;
            end;
            if isOnRect(pauseButton.active, finger^) then
            begin
                isPaused:= not isPaused;
                exit;
            end;
            moveCursor:= not bShowAmmoMenu;
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
{$ENDIF}
end;

procedure onTouchMotion(x,y: Longword;dx,dy: LongInt; pointerId: TSDL_FingerId);
var
    finger, secondFinger: PTouch_Data;
    currentPinchDelta, zoom : hwFloat;
begin
finger:= updateFinger(x,y,dx,dy,pointerId);

if moveCursor then
    begin
        if invertCursor then
        begin
            CursorPoint.X := CursorPoint.X - finger^.dx;
            CursorPoint.Y := CursorPoint.Y + finger^.dy;
        end
    else
        begin
            CursorPoint.X := CursorPoint.X + finger^.dx;
            CursorPoint.Y := CursorPoint.Y - finger^.dy;
        end;
        exit //todo change into switch rather than ugly ifs
    end;
    
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
       if ZoomValue < cMaxZoomLevel then
           ZoomValue := cMaxZoomLevel;
       if ZoomValue > cMinZoomLevel then
           ZoomValue := cMinZoomLevel;
    end;

end;

procedure onTouchUp(x,y: Longword; pointerId: TSDL_FingerId);
var
    finger: PTouch_Data;
begin
x := x;
y := y;
aiming:= false;
stopFiring:= true;
finger:= updateFinger(x,y,0,0,pointerId);
//Check for onTouchClick event
if ((RealTicks - finger^.timeSinceDown) < clickTime) AND not(fingerHasMoved(finger^)) then
    onTouchClick(finger^);

deleteFinger(pointerId);

if walkingLeft then
    begin
    leftKey:= false;
    walkingLeft := false;
    end;

if walkingRight then
    begin
    rightKey:= false;
    walkingRight := false;
    end;

if aimingUp then
    begin
    upKey:= false;
    aimingUp:= false;
    end;
if aimingDown then
    begin
    downKey:= false;
    aimingDown:= false;
    end;
end;

procedure onTouchDoubleClick(finger: TTouch_Data);
begin
finger := finger;//avoid compiler hint
end;

procedure onTouchClick(finger: TTouch_Data);
begin
if (RealTicks - timeSinceClick < 300) and (DistanceI(finger.X-xTouchClick, finger.Y-yTouchClick) < _30) then
    begin
    onTouchDoubleClick(finger);
    timeSinceClick:= 0;//we make an assumption there won't be an 'click' in the first 300 ticks(milliseconds) 
    exit; 
    end;

xTouchClick:= finger.x;
yTouchClick:= finger.y;
timeSinceClick:= RealTicks;

if bShowAmmoMenu then
    begin 
    if isOnRect(AmmoRect, finger) then
        begin
        CursorPoint.X:= finger.x;
        CursorPoint.Y:= finger.y;
        doPut(CursorPoint.X, CursorPoint.Y, false); 
        end
    else
        bShowAmmoMenu:= false;
    exit;
    end;


if isOnCurrentHog(finger) then
    begin
    bShowAmmoMenu := true;
    exit;
    end;
end;

function addFinger(x,y: Longword; id: TSDL_FingerId): PTouch_Data;
var 
    xCursor, yCursor, index : LongInt;
begin
    //Check array sizes
    if length(fingers) < Integer(pointerCount) then 
    begin
        setLength(fingers, length(fingers)*2);
        for index := length(fingers) div 2 to length(fingers) do
            fingers[index].id := nilFingerId;
    end;
    
    
    xCursor := convertToCursorX(x);
    yCursor := convertToCursorY(y);
    
    //on removing fingers, all fingers are moved to the left
    //with dynamic arrays being zero based, the new position of the finger is the old pointerCount
    fingers[pointerCount].id := id;
    fingers[pointerCount].historicalX := xCursor;
    fingers[pointerCount].historicalY := yCursor;
    fingers[pointerCount].x := xCursor;
    fingers[pointerCount].y := yCursor;
    fingers[pointerCount].dx := 0;
    fingers[pointerCount].dy := 0;
    fingers[pointerCount].timeSinceDown:= RealTicks;
 
    addFinger:= @fingers[pointerCount];
    inc(pointerCount);
end;

function updateFinger(x,y,dx,dy: Longword; id: TSDL_FingerId): PTouch_Data;
begin
   updateFinger:= findFinger(id);

   updateFinger^.x:= convertToCursorX(x);
   updateFinger^.y:= convertToCursorY(y);
   updateFinger^.dx:= convertToCursorDeltaX(dx);
   updateFinger^.dy:= convertToCursorDeltaY(dy);
end;

procedure deleteFinger(id: TSDL_FingerId);
var
    index : Longword;
begin
    
    dec(pointerCount);
    for index := 0 to pointerCount do
    begin
        if fingers[index].id = id then
        begin
 
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
    if CurrentHedgehog^.Gear <> nil then
        begin
        deltaAngle:= CurrentHedgehog^.Gear^.Angle - targetAngle;
        if (deltaAngle = 0) then 
            begin
            if aimingUp then
                begin
                upKey:= false;
                aimingUp:= false;
                end;
            if aimingDown then
                begin
                downKey:= false;
                aimingDown:= false;
                end
            end
        else
            begin
            if (deltaAngle < 0) then
                begin
                if aimingUp then
                    begin
                    upKey:= false;
                    aimingUp:= false;
                    end;
                downKey:= true;
                aimingDown:= true;
                end
            else
                begin
                if aimingDown then
                    begin
                    downKey:= false;
                    aimingDown:= false;
                    end;
                upKey:= true;
                aimingUp:= true;
                end; 
            end;
        end
    else  
        begin
        if aimingUp then
            begin
            upKey:= false;
            aimingUp:= false;
            end;
        if aimingDown then
            begin
            upKey:= false;
            aimingDown:= false;
            end;
        end;
       
if stopFiring then 
    begin
    spaceKey:= false;
    stopFiring:= false;
    end;

if stopRight then
    begin
    stopRight := false;
    rightKey:= false;
    end;
 
if stopLeft then
    begin
    stopLeft := false;
    leftKey:= false;
    end;
    
end;

function findFinger(id: TSDL_FingerId): PTouch_Data;
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

procedure aim(finger: TTouch_Data);
var 
    hogX, hogY, touchX, touchY, deltaX, deltaY, tmpAngle: hwFloat;
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
        end; //if CurrentHedgehog^.Gear <> nil
end;

// These 4 convertToCursor functions convert xy coords from the SDL coordinate system to our CursorPoint coor system:
// - the SDL coordinate system goes from 0 to 32768 on the x axis and 0 to 32768 on the y axis, (0,0) being top left;
// - the CursorPoint coordinate system goes from -cScreenWidth/2 to cScreenWidth/2 on the x axis
//   and 0 to cScreenHeight on the x axis, (-cScreenWidth, cScreenHeight) being top left.
function convertToCursorX(x: LongInt): LongInt;
begin
    convertToCursorX := round((x/32768)*cScreenWidth) - (cScreenWidth shr 1);
end;

function convertToCursorY(y: LongInt): LongInt;
begin
    convertToCursorY := cScreenHeight - round((y/32768)*cScreenHeight)
end;

function convertToCursorDeltaX(x: LongInt): LongInt;
begin
    convertToCursorDeltaX := round(x/32768*cScreenWidth)
end;

function convertToCursorDeltaY(y: LongInt): LongInt;
begin
    convertToCursorDeltaY := round(y/32768*cScreenHeight)
end;

function isOnCrosshair(finger: TTouch_Data): boolean;
var
    x,y : hwFloat;
begin
    x := _0;//avoid compiler hint
    y := _0;
    convertToFingerCoord(x, y, int2hwFloat(CrosshairX), int2hwFloat(CrosshairY));
    isOnCrosshair:= Distance(int2hwFloat(finger.x)-x, int2hwFloat(finger.y)-y) < _50;
end;

function isOnCurrentHog(finger: TTouch_Data): boolean;
var
    x,y : hwFloat;
begin
    x := _0;
    y := _0;
    convertToFingerCoord(x,y, CurrentHedgehog^.Gear^.X, CurrentHedgehog^.Gear^.Y);
    isOnCurrentHog := Distance(int2hwFloat(finger.X)-x, int2hwFloat(finger.Y)-y) < _50;
end;

procedure convertToFingerCoord(var x,y : hwFloat; oldX, oldY: hwFloat);
begin
    x := oldX + int2hwFloat(WorldDx);
    y := int2hwFloat(cScreenHeight) - (oldY + int2hwFloat(WorldDy));
end;

procedure convertToWorldCoord(var x,y: hwFloat; finger: TTouch_Data);
begin
//if x <> nil then 
    x := int2hwFloat((finger.x-WorldDx));
//if y <> nil then 
    y := int2hwFloat((cScreenHeight - finger.y)-WorldDy);
end;

//Method to calculate the distance this finger has moved since the downEvent
function fingerHasMoved(finger: TTouch_Data): boolean;
begin
    fingerHasMoved := trunc(sqrt(Power(finger.X-finger.historicalX,2) + Power(finger.y-finger.historicalY, 2))) > 330;
end;

function calculateDelta(finger1, finger2: TTouch_Data): hwFloat; inline;
begin
    calculateDelta := DistanceI(finger2.x-finger1.x, finger2.y-finger1.y);
end;

// Under the premise that all pointer ids in pointerIds:TSDL_FingerId are packed to the far left.
// If the pointer to be ignored is not pointerIds[0] the second must be there
function getSecondFinger(finger: TTouch_Data): PTouch_Data;
begin
    if fingers[0].id = finger.id then
        getSecondFinger := @fingers[1]
    else
        getSecondFinger := @fingers[0];
end;

function isOnRect(rect: TSDL_Rect; finger: TTouch_Data): boolean;
begin
    isOnRect:= (finger.x > rect.x)   and
               (finger.x < rect.x + rect.w) and
               (cScreenHeight - finger.y > rect.y) and
               (cScreenHeight - finger.y < rect.y + rect.h);
end;

procedure printFinger(finger: TTouch_Data);
begin
    WriteToConsole(Format('id:%d, (%d,%d), (%d,%d), time: %d', [finger.id, finger.x, finger.y, finger.historicalX, finger.historicalY, finger.timeSinceDown]));
end;

procedure initModule;
var
    index: Longword;
    //uRenderCoordScaleX, uRenderCoordScaleY: Longword;
begin
    stopFiring:= false;
    walkingLeft := false;
    walkingRight := false;

    setLength(fingers, 4);
    for index := 0 to High(fingers) do 
        fingers[index].id := nilFingerId;
end;

begin
end.
