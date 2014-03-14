unit uLandUtils;
interface

procedure ResizeLand(width, height: LongWord);

implementation
uses uUtils, uConsts, uVariables;

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
    if (width div 4096 >= 2) or (height div 2048 >= 2) then cMaxZoomLevel:= 0.5;
    cMinMaxZoomLevelDelta:= cMaxZoomLevel - cMinZoomLevel
    end;
end;

end.
