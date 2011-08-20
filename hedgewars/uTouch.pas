{$INCLUDE "options.inc"}

unit uTouch;

interface

uses sysutils, math, uConsole, uVariables, SDLh, uTypes, uFloat, uConsts, uIO, uCommands, GLUnit, uCommandHandlers;

type
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
function addFinger(x,y: Longword; id: SDL_FingerId): Touch_Finger;
procedure deleteFinger(id: SDL_FingerId);
procedure onTouchClick(finger: Touch_Finger);
procedure onTouchDoubleClick(finger: Touch_Finger);

function findFinger(id: SDL_FingerId): Touch_Finger;
procedure aim(finger: Touch_Finger);
function isOnCrosshair(finger: Touch_Finger): boolean;
function isOnCurrentHog(finger: Touch_Finger): boolean;
function isOnFireButton(finger: Touch_Finger): boolean;
procedure convertToWorldCoord(var x,y: hwFloat; finger: Touch_Finger);
function fingerHasMoved(finger: Touch_Finger): boolean;
function calculateDelta(finger1, finger2: Touch_Finger): hwFloat;
function getSecondFinger(finger: Touch_Finger): Touch_Finger;
implementation

const
    clicktime = 200;
var
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
procedure printFinger(finger: Touch_Finger);
begin
    WriteToConsole(Format('id:%d, (%d,%d), (%d,%d), time: %d', [finger.id, finger.x, finger.y, finger.historicalX, finger.historicalY, finger.timeSinceDown]));
end;


procedure onTouchDown(x,y: Longword; pointerId: SDL_FingerId);
var 
    finger: Touch_Finger;
begin
    finger:= addFinger(x,y,pointerId);
    finger.x := convertToCursor(cScreenWidth,x);
    finger.y := convertToCursor(cScreenHeight,y);
    
    printFinger(finger); 
    case pointerCount of
        1:
        begin
            moveCursor:= false;
            if bShowAmmoMenu then
            begin
                moveCursor := true;
                exit;
            end;

            if isOnCrosshair(finger) then
            begin
                aiming:= true;
                exit;
            end;

            if isOnFireButton(finger) then
            begin
                stopFiring:= false;
                ParseCommand('+attack', true);
                exit;
            end;
            if finger.x < leftButtonBoundary then
            begin
                ParseCommand('+left', true);
                walkingLeft := true;
                exit;
            end;
            if finger.x > rightButtonBoundary then
            begin
                ParseCommand('+right', true);
                walkingRight:= true;
                exit;
            end;
            if finger.y < topButtonBoundary then
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
            
            pinchSize := calculateDelta(finger, getSecondFinger(finger));
            baseZoomValue := ZoomValue
        end;
    end;//end case pointerCount of
end;

procedure onTouchMotion(x,y: Longword;dx,dy: LongInt; pointerId: SDL_FingerId);
var
    finger, secondFinger: Touch_Finger;
    currentPinchDelta, zoom : hwFloat;
begin
    finger:= findFinger(pointerId);
    finger.x := convertToCursor(cScreenWidth, x);
    finger.y := convertToCursor(cScreenHeight, y);
    
    case pointerCount of
       1:
           begin
               if aiming then 
               begin
                   aim(finger);
                   exit
               end;
               if moveCursor then
                   if invertCursor then
                   begin
                       CursorPoint.X := CursorPoint.X - convertToCursor(cScreenWidth,dx);
                       CursorPoint.Y := CursorPoint.Y + convertToCursor(cScreenWidth,dy);
                   end
                   else
                   begin
                       CursorPoint.X := CursorPoint.X + convertToCursor(cScreenWidth,dx);
                       CursorPoint.Y := CursorPoint.Y - convertToCursor(cScreenWidth,dy);
                   end;
           end;
       2:
           begin
               secondFinger := getSecondFinger(finger);
               currentPinchDelta := calculateDelta(finger, secondFinger)- pinchSize;
               zoom := currentPinchDelta/cScreenWidth;
               ZoomValue := baseZoomValue - ((hwFloat2Float(zoom) * cMinMaxZoomLevelDelta));
               if ZoomValue < cMaxZoomLevel then ZoomValue := cMaxZoomLevel;
               if ZoomValue > cMinZoomLevel then ZoomValue := cMinZoomLevel;
            end;
    end; //end case pointerCount of
end;

procedure onTouchUp(x,y: Longword; pointerId: SDL_FingerId);
begin
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

function addFinger(x,y: Longword; id: SDL_FingerId): Touch_Finger;
var 
    xCursor, yCursor, index : LongInt;
begin
    //Check array sizes
    if length(fingers) < pointerCount then 
    begin
        setLength(fingers, length(fingers)*2);
        for index := length(fingers) div 2 to length(fingers) do fingers[index].id := -1;
    end;
    
    
    xCursor := convertToCursor(cScreenWidth, x);
    yCursor := convertToCursor(cScreenHeight, y);
    
    //on removing fingers all fingers are moved to the left, thus new fingers will be to the far right
    //with dynamic arrays being zero based, 'far right' is the old pointerCount    
    fingers[pointerCount].id := id;
    fingers[pointerCount].historicalX := xCursor;
    fingers[pointerCount].historicalY := yCursor;
    fingers[pointerCount].x := xCursor;
    fingers[pointerCount].y := yCursor;
    fingers[pointerCount].timeSinceDown:= SDL_GetTicks;
 
    inc(pointerCount);
    addFinger:= fingers[pointerCount];
end;

procedure deleteFinger(id: SDL_FingerId);
var
    index : Longint;
begin
    
    dec(pointerCount);
    for index := 0 to pointerCount do
    begin
         if fingers[index].id = id then
         begin
             //Check for onTouchevent
             if ((SDL_GetTicks - fingers[index].timeSinceDown) < clickTime) AND  not(fingerHasMoved(fingers[index])) then 
                 onTouchClick(fingers[index]);
             fingers[index].id := -1;
             break;
         end;
    end;
    //put the last finger into the spot of the finger to be removed, so that all fingers are packed to the far left
    if fingers[pointerCount].id = -1 then
    begin
        fingers[index] := fingers[pointerCount];    
        fingers[pointerCount].id := -1;
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

function findFinger(id: SDL_FingerId): Touch_Finger;
begin
   for findFinger in fingers do
       if (findFinger.id = -1) and (findFinger.id = id) then break;
end;

procedure aim(finger: Touch_Finger);
var 
    hogX, hogY, touchX, touchY, deltaX, deltaY, tmpAngle: hwFloat;
    tmp: ShortString;
begin
    if CurrentHedgehog^.Gear <> nil then
    begin
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
    isOnFireButton:= (finger.x < 150) and (finger.y > 390);
end;

function isOnCrosshair(finger: Touch_Finger): boolean;
var
    x,y,fingerX, fingerY : hwFloat;
begin
    x := int2hwFloat(CrosshairX);
    y := int2hwFloat(CrosshairY);

    convertToWorldCoord(fingerX, fingerY, finger);
    isOnCrosshair:= Distance(fingerX-x, fingerY-y) < _20;
end;

function isOnCurrentHog(finger: Touch_Finger): boolean;
var
    x,y, fingerX, fingerY : hwFloat;
begin
    x := CurrentHedgehog^.Gear^.X;
    y := CurrentHedgehog^.Gear^.Y;

    convertToWorldCoord(fingerX, fingerY, finger);
    isOnCurrentHog := Distance(fingerX-x, fingerY-y) < _20;
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

function calculateDelta(finger1, finger2: Touch_Finger): hwFloat;
begin
//    calculateDelta := Distance(xyCoord[id2*2] - xyCoord[id1*2], xyCoord[id2*2+1] - xyCoord[id1*2+1]);
    calculateDelta := int2hwFloat(trunc(sqrt(Power(finger2.x-finger1.x, 2) + Power(finger2.y-finger1.y, 2))));
end;

// Under the premise that all pointer ids in pointerIds:SDL_FingerId are pack to the far left.
// If the pointer to be ignored is not pointerIds[0] the second must be there
function getSecondFinger(finger: Touch_Finger): Touch_Finger;
begin
    if fingers[0].id = finger.id then getSecondFinger := fingers[0]
    else getSecondFinger := fingers[1];
end;

procedure initModule;
var
    finger: Touch_Finger;
begin
    movingCrosshair := false;
    stopFiring:= false;
    walkingLeft := false;
    walkingRight := false;

    leftButtonBoundary := cScreenWidth div 4;
    rightButtonBoundary := cScreenWidth div 4*3;
    topButtonBoundary := cScreenHeight div 6;
    
    setLength(fingers, 5);
    for finger in fingers do finger.id := -1;
end;

begin
end.
