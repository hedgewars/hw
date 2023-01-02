unit uLandUtils;
interface

procedure ResizeLand(width, height: LongWord);
procedure DisposeLand();
procedure InitWorldEdges();

function  LandGet(y, x: LongInt): Word;
procedure LandSet(y, x: LongInt; value: Word);

procedure FillLand(x, y: LongInt; border, value: Word);

implementation
uses uUtils, uConsts, uVariables, uTypes;

const LibFutureName = 'hwengine_future';
function  create_game_field(width, height: Longword): pointer; cdecl; external LibFutureName;
procedure dispose_game_field(game_field: pointer); cdecl; external LibFutureName;
function  land_get(game_field: pointer; x, y: LongInt): Word; cdecl; external LibFutureName;
procedure land_set(game_field: pointer; x, y: LongInt; value: Word); cdecl; external LibFutureName;
procedure land_fill(game_field: pointer; x, y: LongInt; border, fill: Word); cdecl; external LibFutureName;

var gameField: pointer;

function  LandGet(y, x: LongInt): Word;
begin
    LandGet:= land_get(gameField, x, y)
end;

procedure LandSet(y, x: LongInt; value: Word);
begin
    land_set(gameField, x, y, value)
end;

procedure FillLand(x, y: LongInt; border, value: Word);
begin
    land_fill(gameField, x, y, border, value)
end;

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

    gameField:= create_game_field(LAND_WIDTH, LAND_HEIGHT);
    SetLength(LandDirty, (LAND_HEIGHT div 32), (LAND_WIDTH div 32));
    // 0.5 is already approaching on unplayable
    if (width div 4096 >= 2) or (height div 2048 >= 2) then cMaxZoomLevel:= cMaxZoomLevel/2;
    cMinMaxZoomLevelDelta:= cMaxZoomLevel - cMinZoomLevel
    end;
initScreenSpaceVars();
end;

procedure DisposeLand();
begin
    dispose_game_field(gameField)
end;

procedure InitWorldEdges();
var cy, cx, lx, ly: LongInt;
    found: boolean;
begin
playHeight:= LAND_HEIGHT;
topY:= 0;

lx:= LongInt(LAND_WIDTH) - 1;

// don't change world edges for drawn maps
if (cMapGen = mgDrawn) then
    // edges were adjusted already in GenDrawnMap() in uLand
    EXIT;

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
        if LandGet(cy, cx) <> 0 then
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
        if LandGet(cy, cx) <> 0 then
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
