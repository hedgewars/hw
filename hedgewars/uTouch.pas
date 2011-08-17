{$INCLUDE "options.inc"}

unit uTouch;

interface

uses sysutils, math, uConsole, uVariables, SDLh, uTypes, uFloat, uConsts, GLUnit;

procedure initModule;

procedure onTouchDown(x,y: Longword; pointerId: SDL_FingerId);
procedure onTouchMotion(x,y: Longword; dx,dy: LongInt; pointerId: SDL_FingerId);
procedure onTouchUp(x,y: Longword; pointerId: SDL_FingerId);
function convertToCursor(scale: LongInt; xy: LongInt): LongInt;
procedure addFinger(id: SDL_FingerId);
procedure deleteFinger(id: SDL_FingerId);
procedure onTouchClick(x,y: Longword; pointerId: SDL_FingerId);

function calculateDelta(id1, id2: SDL_FingerId): hwFloat;
function getSecondPointer(id: SDL_FingerId): SDL_FingerId;
implementation

const
    clicktime = 200;

var
    pointerCount : Longword;
    xyCoord : array of LongInt;
    pointerIds : array of SDL_FingerId;
    timeSinceDown: array of Longword;
     
    //Pinch to zoom 
    pinchSize : hwFloat;
    baseZoomValue: GLFloat;

procedure onTouchDown(x,y: Longword; pointerId: SDL_FingerId);
begin
    WriteToConsole('down'); 
    addFinger(pointerId);
    xyCoord[pointerId*2] := convertToCursor(cScreenWidth,x);
    xyCoord[pointerId*2+1] := convertToCursor(cScreenHeight,y);
   
    case pointerCount of
        2:
        begin
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
               CursorPoint.X := CursorPoint.X - convertToCursor(cScreenWidth,dx);
               CursorPoint.Y := CursorPoint.Y + convertToCursor(cScreenWidth,dy);
           end;
       2:
           begin
               secondId := getSecondPointer(pointerId);
               currentPinchDelta := calculateDelta(pointerId, secondId) - pinchSize;
               zoom := currentPinchDelta/cScreenWidth;
               ZoomValue := baseZoomValue - ((hwFloat2Float(zoom) * cMinMaxZoomLevelDelta));
               //WriteToConsole(Format('Zoom in/out. ZoomValue = %f', [ZoomValue]));
//              if ZoomValue > cMaxZoomLevel then ZoomValue := cMaxZoomLevel;
//               if ZoomValue < cMinZoomLevel then ZoomValue := cMinZoomLevel;
            end;
    end; //end case pointerCount of
end;

procedure onTouchUp(x,y: Longword; pointerId: SDL_FingerId);
begin
    pointerCount := pointerCount-1;
    deleteFinger(pointerId);
end;

procedure onTouchClick(x,y: Longword; pointerId: SDL_FingerId);
begin
    WriteToConsole(Format('clicker %d', [SDL_GetTicks]));
    bShowAmmoMenu := not(bShowAmmoMenu);
end;

function convertToCursor(scale: LongInt; xy: LongInt): LongInt;
begin
    convertToCursor := round(xy/32768*scale)
end;

procedure addFinger(id: SDL_FingerId);
var 
    index, tmp: Longword;
begin
    pointerCount := pointerCount + 1;

    //Check array sizes
    if length(pointerIds) < pointerCount then setLength(pointerIds, length(pointerIds)*2);
    if length(xyCoord) < pointerCount*2+1 then setLength(xyCoord, length(xyCoord)*2);
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
    timeSinceDown[id] := SDL_GetTicks
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
    if (SDL_GetTicks - timeSinceDown[id]) < clickTime then onTouchClick(xyCoord[id*2], xyCoord[id*2+1], id);
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
    for index := Low(xyCoord) to High(xyCoord) do xyCoord[index] := -1;
    for index := Low(pointerIds) to High(pointerIds) do pointerIds[index] := -1;

end;

begin
end.
