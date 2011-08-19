{$INCLUDE "options.inc"}

unit uTouch;

interface

uses sysutils, math, uConsole, uVariables, SDLh, uTypes, uFloat, uConsts, uIO, uCommands, GLUnit, uCommandHandlers;

procedure initModule;


procedure ProcessTouch;
procedure onTouchDown(x,y: Longword; pointerId: SDL_FingerId);
procedure onTouchMotion(x,y: Longword; dx,dy: LongInt; pointerId: SDL_FingerId);
procedure onTouchUp(x,y: Longword; pointerId: SDL_FingerId);
function convertToCursor(scale: LongInt; xy: LongInt): LongInt;
procedure addFinger(x,y: Longword; id: SDL_FingerId);
procedure deleteFinger(id: SDL_FingerId);
procedure onTouchClick(x,y: Longword; pointerId: SDL_FingerId);

procedure aim(id: SDL_FingerId);
function isOnCurrentHog(id: SDL_FingerId): boolean;
function isOnFireButton(id: SDL_FingerId): boolean;
procedure convertToWorldCoord(var x,y: hwFloat; id: SDL_FingerId);
function fingerHasMoved(id: SDL_FingerId): boolean;
function calculateDelta(id1, id2: SDL_FingerId): hwFloat;
function getSecondPointer(id: SDL_FingerId): SDL_FingerId;
implementation

const
    clicktime = 200;
var
    leftButtonBoundary  : LongInt;
    rightButtonBoundary : LongInt;
    topButtonBoundary   : LongInt;
    
    pointerCount : Longword;
    xyCoord : array of LongInt;
    pointerIds : array of SDL_FingerId;
    timeSinceDown: array of Longword;
    historicalXY : array of LongInt;

    moveCursor : boolean;

    //Pinch to zoom 
    pinchSize : hwFloat;
    baseZoomValue: GLFloat;

    invertCursor : boolean;

    //aiming
    aiming, movingCrosshair: boolean; 
    crosshairCommand: ShortString;
    aimingPointerId: SDL_FingerId;
    targetAngle: LongInt;

    stopFiring: boolean;

    //moving
    stopLeft, stopRight, walkingLeft, walkingRight :  boolean;

procedure onTouchDown(x,y: Longword; pointerId: SDL_FingerId);
begin
    addFinger(x,y,pointerId);
    xyCoord[pointerId*2] := convertToCursor(cScreenWidth,x);
    xyCoord[pointerId*2+1] := convertToCursor(cScreenHeight,y);
    
   
    case pointerCount of
        1:
        begin
            moveCursor:= false;
            if bShowAmmoMenu then
            begin
                moveCursor := true;
                exit;
            end;

            if isOnCurrentHog(pointerId) then
            begin
                aiming:= true;
                exit;
            end;

            if isOnFireButton(pointerId) then
            begin
                stopFiring:= false;
                ParseCommand('+attack', true);
                exit;
            end;
            if xyCoord[pointerId*2] < leftButtonBoundary then
            begin
                ParseCommand('+left', true);
                walkingLeft := true;
                exit;
            end;
            if xyCoord[pointerId*2] > rightButtonBoundary then
            begin
                ParseCommand('+right', true);
                walkingRight:= true;
                exit;
            end;
            WriteToConsole(Format('%d, %d', [xyCoord[pointerId*2+1], topButtonBoundary]));    
            if xyCoord[pointerId*2+1] < topButtonBoundary then
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
            
            pinchSize := calculateDelta(pointerId, getSecondPointer(pointerId));
            baseZoomValue := ZoomValue
        end;
    end;//end case pointerCount of
end;

procedure onTouchMotion(x,y: Longword;dx,dy: LongInt; pointerId: SDL_FingerId);
var
    secondId : SDL_FingerId;
    currentPinchDelta, zoom : hwFloat;
begin
    xyCoord[pointerId*2] := convertToCursor(cScreenWidth, x);
    xyCoord[pointerId*2+1] := convertToCursor(cScreenHeight, y);
    
    case pointerCount of
       1:
           begin
               if aiming then 
               begin
                   aim(pointerId);
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
               secondId := getSecondPointer(pointerId);
               currentPinchDelta := calculateDelta(pointerId, secondId) - pinchSize;
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
    pointerCount := pointerCount-1;
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

procedure onTouchClick(x,y: Longword; pointerId: SDL_FingerId);
begin
    if bShowAmmoMenu then 
    begin
        doPut(CursorPoint.X, CursorPoint.Y, false); 
        exit
    end;

    if isOnCurrentHog(pointerId) then
    begin
        bShowAmmoMenu := true;
        exit;
    end;

    if xyCoord[pointerId*2+1] < topButtonBoundary then
    begin
        ParseCommand('hjump', true);
        exit;
    end;
end;

procedure addFinger(x,y: Longword; id: SDL_FingerId);
var 
    index, tmp: Longword;
begin
    pointerCount := pointerCount + 1;

    //Check array sizes
    if length(pointerIds) < pointerCount then setLength(pointerIds, length(pointerIds)*2);
    if length(xyCoord) < id*2+1 then 
    begin 
        setLength(xyCoord, id*2+1);
        setLength(historicalXY, id*2+1);
    end;
    if length(timeSinceDown) < id then setLength(timeSinceDown, id); 
    for index := 0 to pointerCount do //place the pointer ids as far back to the left as possible
    begin
        if pointerIds[index] = -1 then 
           begin
               pointerIds[index] := id;
               break;
           end;
    end;
    //set timestamp
    timeSinceDown[id] := SDL_GetTicks;
    historicalXY[id*2] := convertToCursor(cScreenWidth,x);
    historicalXY[id*2+1] := convertToCursor(cScreenHeight,y);
end;

procedure deleteFinger(id: SDL_FingerId);
var
    index, i : Longint;
begin
    index := 0;
    for index := 0 to pointerCount do
    begin
         if pointerIds[index] = id then
         begin
             pointerIds[index] := -1;
             break;
         end;
    end;
    //put the last pointerId into the stop of the id to be removed, so that all pointerIds are to the far left
    for i := pointerCount downto index do
    begin
        if pointerIds[i] <> -1 then
        begin
            pointerIds[index] := pointerIds[i];
            break;
        end;
    end;
    if ((SDL_GetTicks - timeSinceDown[id]) < clickTime) AND  not(fingerHasMoved(id)) then onTouchClick(xyCoord[id*2], xyCoord[id*2+1], id);
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

procedure aim(id: SDL_FingerId);
var 
    hogX, hogY, touchX, touchY, deltaX, deltaY, tmpAngle: hwFloat;
    tmp: ShortString;
begin
    if CurrentHedgehog^.Gear <> nil then
    begin
        hogX := CurrentHedgehog^.Gear^.X;
        hogY := CurrentHedgehog^.Gear^.Y;

        convertToWorldCoord(touchX, touchY, id);
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

function isOnFireButton(id: SDL_FingerId): boolean;
begin
    isOnFireButton:= (xyCoord[id*2] < 150) and (xyCoord[id*2+1] > 390);
end;

function isOnCurrentHog(id: SDL_FingerId): boolean;
var
    x,y, fingerX, fingerY : hwFloat;
begin
    x := CurrentHedgehog^.Gear^.X;
    y := CurrentHedgehog^.Gear^.Y;

    convertToWorldCoord(fingerX, fingerY, id);
    isOnCurrentHog := Distance(fingerX-x, fingerY-y) < _20;
end;

procedure convertToWorldCoord(var x,y: hwFloat; id: SDL_FingerId);
begin
//if x <> nil then 
    x := int2hwFloat((xyCoord[id*2]-WorldDx) - (cScreenWidth div 2));
//if y <> nil then 
    y := int2hwFloat(xyCoord[id*2+1]-WorldDy);
end;

//Method to calculate the distance this finger has moved since the downEvent
function fingerHasMoved(id: SDL_FingerId): boolean;
begin
//    fingerHasMoved := hwAbs(DistanceI(xyCoord[id*2]-historicalXY[id*2], xyCoord[id*2+1]-historicalXY[id*2+1])) > int2hwFloat(2000); // is 1% movement
    fingerHasMoved := trunc(sqrt(Power(xyCoord[id*2]-historicalXY[id*2],2) + Power(xyCoord[id*2+1]-historicalXY[id*2+1], 2))) > 330;
end;

function calculateDelta(id1, id2: SDL_FingerId): hwFloat;
begin
//    calculateDelta := Distance(xyCoord[id2*2] - xyCoord[id1*2], xyCoord[id2*2+1] - xyCoord[id1*2+1]);
    calculateDelta := int2hwFloat(trunc(sqrt(Power(xyCoord[id2*2]-xyCoord[id1*2],2) + Power(xyCoord[id2*2+1]-xyCoord[id1*2+1], 2))));
end;

// Under the premise that all pointer ids in pointerIds:SDL_FingerId are pack to the far left.
// If the pointer to be ignored is not pointerIds[0] the second must be there
function getSecondPointer(id: SDL_FingerId): SDL_FingerId;
begin
    if pointerIds[0] = id then getSecondPointer := pointerIds[1]
    else getSecondPointer := pointerIds[0];
end;

procedure initModule;
var
    index: Longword;
begin
    setLength(xyCoord, 10);
    setLength(pointerIds, 5);
    setLength(timeSinceDown, 5);
    setLength(historicalXY, 10);    
    for index := Low(xyCoord) to High(xyCoord) do xyCoord[index] := -1;
    for index := Low(pointerIds) to High(pointerIds) do pointerIds[index] := -1;
    movingCrosshair := false;
    stopFiring:= false;
    walkingLeft := false;
    walkingRight := false;

    leftButtonBoundary := cScreenWidth div 4;
    rightButtonBoundary := cScreenWidth div 4*3;
    topButtonBoundary := cScreenHeight div 6;
   
end;

begin
end.
