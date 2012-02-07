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

// TODO: this type should be Int64
// TODO: this type should be named TSDL_FingerId
type SDL_FingerId = LongInt;

type
    PTouch_Finger = ^Touch_Finger;
    Touch_Finger = record
        id                       : SDL_FingerId;
        x,y                      : LongInt;
        dx,dy                    : LongInt;
        historicalX, historicalY : LongInt;
        timeSinceDown            : Longword;
        end;

procedure initModule;

procedure ProcessTouch;
procedure onTouchDown(x,y: Longword; pointerId: SDL_FingerId);
procedure onTouchMotion(x,y: Longword; dx,dy: LongInt; pointerId: SDL_FingerId);
procedure onTouchUp(x,y: Longword; pointerId: SDL_FingerId);
function convertToCursorX(x: LongInt): LongInt;
function convertToCursorY(y: LongInt): LongInt;
function convertToCursorDeltaX(x: LongInt): LongInt;
function convertToCursorDeltaY(y: LongInt): LongInt;
function addFinger(x,y: Longword; id: SDL_FingerId): PTouch_Finger;
function updateFinger(x,y,dx,dy: Longword; id: SDL_FingerId): PTouch_Finger;
procedure deleteFinger(id: SDL_FingerId);
procedure onTouchClick(finger: Touch_Finger);
procedure onTouchDoubleClick(finger: Touch_Finger);

function findFinger(id: SDL_FingerId): PTouch_Finger;
procedure aim(finger: Touch_Finger);
function isOnCrosshair(finger: Touch_Finger): boolean;
function isOnCurrentHog(finger: Touch_Finger): boolean;
procedure convertToWorldCoord(var x,y: hwFloat; finger: Touch_Finger);
procedure convertToFingerCoord(var x,y: hwFloat; oldX, oldY: hwFloat);
function fingerHasMoved(finger: Touch_Finger): boolean;
function calculateDelta(finger1, finger2: Touch_Finger): hwFloat;
function getSecondFinger(finger: Touch_Finger): PTouch_Finger;
function isOnRect(x,y,w,h: LongInt; finger: Touch_Finger): boolean;
procedure printFinger(finger: Touch_Finger);
implementation

const
    clicktime = 200;
    nilFingerId = High(SDL_FingerId);

var
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
    aiming: boolean;
    aimingUp, aimingDown: boolean; 
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

            if isOnCrosshair(finger^) then
            begin
                aiming:= true;
                aim(finger^);
                exit;
            end;

            if isOnRect(fireButtonX, fireButtonY, fireButtonW, fireButtonH, finger^) then
            begin
                stopFiring:= false;
                ParseCommand('+attack', true);
                exit;
            end;
            if isOnRect(arrowLeftX, arrowLeftY, arrowLeftW, arrowLeftH, finger^) then
            begin
                ParseCommand('+left', true);
                walkingLeft := true;
                exit;
            end;
            if isOnRect(arrowRightX, arrowRightY, arrowRightW, arrowRightH, finger^) then
            begin
                ParseCommand('+right', true);
                walkingRight:= true;
                exit;
            end;
            if isOnRect(arrowUpX, arrowUpY, arrowUpW, arrowUpH, finger^) then
            begin
                ParseCommand('+up', true);
                aimingUp:= true;
                exit;
            end;
            if isOnRect(arrowDownX, arrowDownY, arrowUpW, arrowUpH, finger^) then
            begin
                ParseCommand('+down', true);
                aimingDown:= true;
                exit;
            end;

            if isOnRect(backjumpX, backjumpY, backjumpW, backjumpH, finger^) then
            begin
                ParseCommand('hjump', true);
                exit;
            end;
            if isOnRect(forwardjumpX, forwardjumpY, forwardjumpW, forwardjumpH, finger^) then
            begin
                ParseCommand('ljump', true);
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
end;

procedure onTouchMotion(x,y: Longword;dx,dy: LongInt; pointerId: SDL_FingerId);
var
    finger, secondFinger: PTouch_Finger;
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

procedure onTouchUp(x,y: Longword; pointerId: SDL_FingerId);
var
    finger: PTouch_Finger;
begin
x := x;
y := y;
aiming:= false;
stopFiring:= true;
finger:= updateFinger(x,y,0,0,pointerId);
//Check for onTouchClick event
if ((SDL_GetTicks - finger^.timeSinceDown) < clickTime) AND not(fingerHasMoved(finger^)) then
    onTouchClick(finger^);

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

if aimingUp then
    begin
    ParseCommand('-up', true);
    aimingUp:= false;
    end;
if aimingDown then
    begin
    ParseCommand('-down', true);
    aimingDown:= false;
    end;
end;

procedure onTouchDoubleClick(finger: Touch_Finger);
begin
finger := finger;//avoid compiler hint
//ParseCommand('ljump', true);
end;

procedure onTouchClick(finger: Touch_Finger);
begin
if (SDL_GetTicks - timeSinceClick < 300) and (DistanceI(finger.X-xTouchClick, finger.Y-yTouchClick) < _30) then
    begin
    onTouchDoubleClick(finger);
    timeSinceClick:= -1;
    exit; 
    end;

xTouchClick:= finger.x;
yTouchClick:= finger.y;
timeSinceClick:= SDL_GetTicks;

if bShowAmmoMenu then
    begin 
    if isOnRect(AmmoRect.x, AmmoRect.y, AmmoRect.w, AmmoRect.h, finger) then
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

{if finger.y < topButtonBoundary then
    begin
    ParseCommand('hjump', true);
    exit;
    end;}
end;

function addFinger(x,y: Longword; id: SDL_FingerId): PTouch_Finger;
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
    fingers[pointerCount].timeSinceDown:= SDL_GetTicks;
 
    addFinger:= @fingers[pointerCount];
    inc(pointerCount);
end;

function updateFinger(x,y,dx,dy: Longword; id: SDL_FingerId): PTouch_Finger;
begin
   updateFinger:= findFinger(id);

   updateFinger^.x:= convertToCursorX(x);
   updateFinger^.y:= convertToCursorY(y);
   updateFinger^.dx:= convertToCursorDeltaX(dx);
   updateFinger^.dy:= convertToCursorDeltaY(dy);
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
                ParseCommand('-up', true);
                aimingUp:= false;
                end;
            if aimingDown then
                begin
                ParseCommand('-down', true);
                aimingDown:= false;
                end
            end
        else
            begin
            if (deltaAngle < 0) then
                begin
                if aimingUp then
                    begin
                    ParseCommand('-up', true);
                    aimingUp:= false;
                    end;
                ParseCommand('+down', true);
                aimingDown:= true;
                end
            else
                begin
                if aimingDown then
                    begin
                    ParseCommand('-down', true);
                    aimingDown:= false;
                    end;
                ParseCommand('+up', true);
                aimingUp:= true;
                end; 
            end;
        end
    else  
        begin
        if aimingUp then
            begin
            ParseCommand('-up', true);
            aimingUp:= false;
            end;
        if aimingDown then
            begin
            ParseCommand('-down', true);
            aimingDown:= false;
            end;
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

//These 4 convertToCursor functions convert xy coords from the SDL coordinate system to our CursorPoint coor system
// the SDL coordinate system goes from 0 to 32768 on the x axis and 0 to 32768 on the y axis, (0,0) being top left.
// the CursorPoint coordinate system goes from -cScreenWidth/2 to cScreenWidth/2 on the x axis 
//  and 0 to cScreenHeight on the x axis, (-cScreenWidth, cScreenHeight) being top left,
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
    convertToFingerCoord(x,y, CurrentHedgehog^.Gear^.X, CurrentHedgehog^.Gear^.Y);
    isOnCurrentHog := Distance(int2hwFloat(finger.X)-x, int2hwFloat(finger.Y)-y) < _50;
end;

procedure convertToFingerCoord(var x,y : hwFloat; oldX, oldY: hwFloat);
begin
    x := oldX + int2hwFloat(WorldDx);
    y := int2hwFloat(cScreenHeight) - (oldY + int2hwFloat(WorldDy));
end;

procedure convertToWorldCoord(var x,y: hwFloat; finger: Touch_Finger);
begin
//if x <> nil then 
    x := int2hwFloat((finger.x-WorldDx));
//if y <> nil then 
    y := int2hwFloat((cScreenHeight - finger.y)-WorldDy);
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
    if fingers[0].id = finger.id then
        getSecondFinger := @fingers[1]
    else
        getSecondFinger := @fingers[0];
end;

function isOnRect(x,y,w,h: LongInt; finger: Touch_Finger): boolean;
begin
isOnRect:= (finger.x > x)   and
           (finger.x < x+w) and
           (cScreenHeight - finger.y > y)   and
           (cScreenHeight - finger.y < (y+h));
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
    stopFiring:= false;
    walkingLeft := false;
    walkingRight := false;

    setLength(fingers, 4);
    for index := 0 to High(fingers) do 
        fingers[index].id := nilFingerId;
end;

begin
end.
