unit uLandUtils;
interface

procedure ResizeLand(width, height: LongWord);
procedure InitWorldEdges();

implementation
uses uUtils, uConsts, uVariables, uTypes;

procedure ResizeLand(width, height: LongWord);
var potW, potH: LongInt;
begin
potW:= toPowerOf2(width);
potH:= toPowerOf2(height);
if (potW <> LAND_WIDTH) or (potH <> LAND_HEIGHT) then
    begin
    LAND_WIDTH:= potW;
    LAND_HEIGHT:= potH;
    LAND_WIDTH_MASK:= not(LAND_WIDTH-1);
    LAND_HEIGHT_MASK:= not(LAND_HEIGHT-1);
    cWaterLine:= LAND_HEIGHT;
    if (cReducedQuality and rqBlurryLand) = 0 then
        SetLength(LandPixels, LAND_HEIGHT, LAND_WIDTH)
    else
        SetLength(LandPixels, LAND_HEIGHT div 2, LAND_WIDTH div 2);

    SetLength(Land, LAND_HEIGHT, LAND_WIDTH);
    SetLength(LandDirty, (LAND_HEIGHT div 32), (LAND_WIDTH div 32));
    // 0.5 is already approaching on unplayable
    if (width div 4096 >= 2) or (height div 2048 >= 2) then cMaxZoomLevel:= cMaxZoomLevel/2;
    cMinMaxZoomLevelDelta:= cMaxZoomLevel - cMinZoomLevel
    end;
initScreenSpaceVars();
end;

procedure InitWorldEdges();
var cy, cx, lx, ly: LongInt;
    found: boolean;
begin
playHeight:= LAND_HEIGHT;
topY:= 0;

lx:= LongInt(LAND_WIDTH) - 1;

// use maximum available map width if there is no special world edge
if WorldEdge = weNone then
    begin
    playWidth:= LAND_WIDTH;
    leftX := 0;
    rightX:= lx;
    EXIT;
    end;

// keep fort distance consistent if we're in wrap mode on fort map
if (cMapGen = mgForts) and (WorldEdge = weWrap) then
    begin
    // edges were adjusted already in MakeFortsMap() in uLand
    EXIT;
    end;

ly:= LongInt(LAND_HEIGHT) - 1;

// find most left land pixels and set leftX accordingly
found:= false;
for cx:= 0 to lx do
    begin
    for cy:= ly downto 0 do
        if Land[cy, cx] <> 0 then
            begin
            leftX:= max(0, cx - cWorldEdgeDist);
            // break out of both loops
            found:= true;
            break;
            end;
    if found then break;
    end;

// find most right land pixels and set rightX accordingly
found:= false;
for cx:= lx downto 0 do
    begin
    for cy:= ly downto 0 do
        if Land[cy, cx] <> 0 then
            begin
            rightX:= min(lx, cx + cWorldEdgeDist);
            // break out of both loops
            found:= true;
            break;
            end;
    if found then break;
    end;

playWidth := rightX + 1 - leftX;
end;

end.
