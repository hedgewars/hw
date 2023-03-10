unit uLandUtils;
interface
uses SDLh;

procedure GenerateTemplatedLand(featureSize: Longword; seed, templateType, dataPath: shortstring);
procedure ResizeLand(width, height: LongWord);
procedure DisposeLand();
procedure InitWorldEdges();

function  LandGet(y, x: LongInt): Word;
procedure LandSet(y, x: LongInt; value: Word);
function  LandRow(row: LongInt): PWordArray;

procedure FillLand(x, y: LongInt; border, value: Word);

function  LandPixelGet(y, x: LongInt): Longword;
procedure LandPixelSet(y, x: LongInt; value: Longword);
function  LandPixelRow(row: LongInt): PLongwordArray;

implementation
uses uUtils, uConsts, uVariables, uTypes;

const LibFutureName = 'hwengine_future';

function  create_empty_game_field(width, height: Longword): pointer; cdecl; external LibFutureName;
procedure get_game_field_parameters(game_field: pointer; var width: LongInt; var height: LongInt; var play_width: LongInt; var play_height: LongInt); cdecl; external LibFutureName;
procedure dispose_game_field(game_field: pointer); cdecl; external LibFutureName;

function  land_get(game_field: pointer; x, y: LongInt): Word; cdecl; external LibFutureName;
procedure land_set(game_field: pointer; x, y: LongInt; value: Word); cdecl; external LibFutureName;
function  land_row(game_field: pointer; row: LongInt): PWordArray; cdecl; external LibFutureName;
procedure land_fill(game_field: pointer; x, y: LongInt; border, fill: Word); cdecl; external LibFutureName;

function  land_pixel_get(game_field: pointer; x, y: LongInt): Longword; cdecl; external LibFutureName;
procedure land_pixel_set(game_field: pointer; x, y: LongInt; value: Longword); cdecl; external LibFutureName;
function  land_pixel_row(game_field: pointer; row: LongInt): PLongwordArray; cdecl; external LibFutureName;

function  generate_templated_game_field(feature_size: Longword; seed, template_type, data_path: PChar): pointer; cdecl; external LibFutureName;
procedure apply_theme(game_field: pointer; data_path, theme_name: PChar); cdecl; external LibFutureName;

var gameField: pointer;

function  LandGet(y, x: LongInt): Word;
begin
    LandGet:= land_get(gameField, x, y)
end;

procedure LandSet(y, x: LongInt; value: Word);
begin
    land_set(gameField, x, y, value)
end;

function  LandRow(row: LongInt): PWordArray;
begin
    LandRow:= land_row(gameField, row)
end;

procedure FillLand(x, y: LongInt; border, value: Word);
begin
    land_fill(gameField, x, y, border, value)
end;

function  LandPixelGet(y, x: LongInt): Longword;
begin
    LandPixelGet:= land_pixel_get(gameField, x, y)
end;

procedure LandPixelSet(y, x: LongInt; value: Longword);
begin
    land_pixel_set(gameField, x, y, value)
end;

function  LandPixelRow(row: LongInt): PLongwordArray;
begin
    LandPixelRow:= land_pixel_row(gameField, row)
end;

procedure GenerateTemplatedLand(featureSize: Longword; seed, templateType, dataPath: shortstring);
begin
    seed[byte(seed[0]) + 1]:= #0;
    templateType[byte(templateType[0]) + 1]:= #0;

    gameField:= generate_templated_game_field(featureSize, @seed[1], @templateType[1], Str2PChar(dataPath));
    get_game_field_parameters(gameField, LAND_WIDTH, LAND_HEIGHT, playWidth, playHeight);

    MaxHedgehogs:= 32;
    hasGirders:= true;

    leftX:= (LAND_WIDTH - playWidth) div 2;
    rightX:= Pred(leftX + playWidth);
    topY:= LAND_HEIGHT - playHeight;
    cWaterLine:= LAND_HEIGHT;

    // let's assume those are powers of two
    LAND_WIDTH_MASK:= not(LAND_WIDTH-1);
    LAND_HEIGHT_MASK:= not(LAND_HEIGHT-1);

    SetLength(LandDirty, (LAND_HEIGHT div 32), (LAND_WIDTH div 32));

    initScreenSpaceVars();
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

    gameField:= create_empty_game_field(LAND_WIDTH, LAND_HEIGHT);
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
