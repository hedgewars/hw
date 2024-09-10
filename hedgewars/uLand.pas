(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *)

{$INCLUDE "options.inc"}

unit uLand;
interface
uses SDLh, uLandTemplates, uConsts, uTypes, uAILandMarks;

procedure initModule;
procedure freeModule;
procedure DrawBottomBorder;
procedure GenMap;
procedure GenPreview(out Preview: TPreview);
procedure GenPreviewAlpha(out Preview: TPreviewAlpha);

implementation
uses uConsole, uStore, uRandom, uLandObjects, uIO, uLandTexture,
     uVariables, uUtils, uCommands, adler32, uDebug, uLandPainted, uTextures,
     uPhysFSLayer, uScript, uLandGenPerlin,
     uLandUtils, uRenderUtils;

var digest: shortstring;
    maskOnly: boolean;

procedure PrettifyLandAlpha();
begin
    if (cReducedQuality and rqBlurryLand) <> 0 then
        PrettifyAlpha2D(LAND_HEIGHT div 2, LAND_WIDTH div 2)
    else
        PrettifyAlpha2D(LAND_HEIGHT, LAND_WIDTH);
end;

procedure DrawBorderFromImage(Surface: PSDL_Surface);
var tmpsurf: PSDL_Surface;
    x, yd, yu: LongInt;
    targetMask: Word;
begin
    tmpsurf:= LoadDataImage(ptCurrTheme, 'Border', ifCritical or ifIgnoreCaps or ifColorKey);

    // if mask only, all land gets filled with landtex and therefore needs borders
    if maskOnly then
        targetMask:= lfLandMask
    else
        targetMask:= lfBasic;

    for x:= 0 to LAND_WIDTH - 1 do
    begin
        yd:= LAND_HEIGHT - 1;
        repeat
            while (yd > 0) and ((LandGet(yd, x) and targetMask) = 0) do dec(yd);

            if (yd < 0) then
                yd:= 0;

            while (yd < LAND_HEIGHT) and ((LandGet(yd, x) and targetMask) <> 0) do
                inc(yd);
            dec(yd);
            yu:= yd;

            while (yu > 0  ) and ((LandGet(yu, x) and targetMask) <> 0) do dec(yu);
            while (yu < yd ) and ((LandGet(yu, x) and targetMask) =  0) do inc(yu);

            if (yd < LAND_HEIGHT - 1) and ((yd - yu) >= 16) then
                copyToXYFromRect(tmpsurf, Surface, x mod tmpsurf^.w, 16, 1, 16, x, yd - 15);
            if (yu > 0) then
                copyToXYFromRect(tmpsurf, Surface, x mod tmpsurf^.w, 0, 1, Min(16, yd - yu + 1), x, yu);
            yd:= yu - 1;
        until yd < 0;
    end;
    SDL_FreeSurface(tmpsurf);
end;


procedure DrawShoppaBorder;
var x, y, s, i: Longword;
    c1, c2, c: Longword;
begin
    c1:= AMask;
    c2:= AMask or RMask or GMask;

    // vertical
    s:= LAND_HEIGHT;

    for x:= 0 to LAND_WIDTH - 1 do
        for y:= 0 to LAND_HEIGHT - 1 do
            if LandGet(y, x) = 0 then
                if s < y then
                    begin
                    for i:= max(s, y - 8) to y - 1 do
                        begin
                        if ((x + i) and 16) = 0 then c:= c1 else c:= c2;

                        if (cReducedQuality and rqBlurryLand) = 0 then
                            LandPixelSet(i, x, c)
                        else
                            LandPixelSet(i div 2, x div 2, c)
                        end;
                    s:= LAND_HEIGHT
                    end
                else
            else
                begin
                if s > y then s:= y;
                if s + 8 > y then
                    begin
                    if ((x + y) and 16) = 0 then c:= c1 else c:= c2;

                    if (cReducedQuality and rqBlurryLand) = 0 then
                        LandPixelSet(y, x, c)
                    else
                        LandPixelSet(y div 2, x div 2, c)
                    end;
                end;

    // horizontal
    s:= LAND_WIDTH;

    for y:= 0 to LAND_HEIGHT - 1 do
        for x:= 0 to LAND_WIDTH - 1 do
            if LandGet(y, x) = 0 then
                if s < x then
                    begin
                    for i:= max(s, x - 8) to x - 1 do
                        begin
                        if ((y + i) and 16) = 0 then c:= c1 else c:= c2;

                        if (cReducedQuality and rqBlurryLand) = 0 then
                            LandPixelSet(y, i, c)
                        else
                            LandPixelSet(y div 2, i div 2, c)
                        end;
                    s:= LAND_WIDTH
                    end
                else
            else
                begin
                if s > x then s:= x;
                if s + 8 > x then
                    begin
                    if ((x + y) and 16) = 0 then c:= c1 else c:= c2;

                    if (cReducedQuality and rqBlurryLand) = 0 then
                        LandPixelSet(y, x, c)
                    else
                        LandPixelSet(y div 2, x div 2, c)
                    end;
                end
end;

procedure ColorizeLandFast(mapsurf: PSDL_Surface);
var ltexsurf: PSDL_Surface;
    i: LongInt;
    ltlnp, srcp, dstp, stopp: Pointer;
    c: SizeInt;
begin
    ltexsurf:= LoadDataImage(ptCurrTheme, 'LandTex', ifCritical or ifIgnoreCaps);

    // pointer to current line of ltexsurf pixels. will be moved from line to line
    ltlnp:= ltexsurf^.pixels;
    // pointer to mapsurf pixels. will jump forward after every move()
    dstp:= mapsurf^.pixels;

    // time to get serious
    SDL_LockSurface(mapsurf);
    SDL_LockSurface(ltexsurf);

    // for now only fill a row with the height of landtex. do vertical copies within mapsurf after

    // do this loop for each line of ltexsurf (unless we run out of map height first)
    for i:= 1 to min(ltexsurf^.h, mapsurf^.h) do
        begin
        // amount of pixels to write in first move()
        c:= ltexsurf^.pitch;

        // protect from odd cases where landtex wider than map
        if c > mapsurf^.pitch then
            c:= mapsurf^.pitch;

        // write line of landtex to mapsurf
        move(ltlnp^, dstp^, c);

        // fill the rest of the line by copying left-to-right until full

        // new src is start of line that we've just written to
        srcp:= dstp;
        // set stop pointer to start of next pixel line of mapsurf
        stopp:= dstp + mapsurf^.pitch;
        // move dst pointer to after what we've just written
        inc(dstp, c);

        // loop until dstp went past end of line
        while dstp < stopp do
            begin
            // copy all from left of dstp to right of it (or just fill the gap if smaller)
            c:= min(dstp-srcp, stopp-dstp);
            move(srcp^, dstp^, c);
            inc(dstp, c);
            end;

        // move to next line in ltexsurf
        inc(ltlnp, ltexsurf^.pitch);
        end;

    // we don't need ltexsurf itself anymore -> cleanup
    ltlnp:= nil;
    SDL_UnlockSurface(ltexsurf);
    SDL_FreeSurface(ltexsurf);
    ltexsurf:= nil;

    // from now on only copy pixels within mapsurf

    // copy all the already written lines at once for that get number of written bytes so far
    // already written pixels are between start and current dstp
    srcp:= mapsurf^.pixels;

    // first byte after end of pixels
    stopp:= srcp + (mapsurf^.pitch * mapsurf^.h);

    while dstp < stopp do
        begin
        // copy all from before dstp to after (or just fill the gap if smaller)
        c:= min(dstp-srcp, stopp-dstp);
        // worried about size of c with humongous maps? don't be:
        //  the OS wouldn't have allowed allocation of object with size > max of SizeInt anyway
        move(srcp^, dstp^, c);
        inc(dstp, c);
        end;

    // cleanup
    srcp:= nil;
    dstp:= nil;
    stopp:= nil;
    SDL_UnlockSurface(mapsurf);

    // freed in freeModule() below
    LandBackSurface:= LoadDataImage(ptCurrTheme, 'LandBackTex', ifIgnoreCaps or ifColorKey);
    if (LandBackSurface <> nil) and GrayScale then Surface2GrayScale(LandBackSurface);
end;

procedure ColorizeLand(Surface: PSDL_Surface);
var tmpsurf: PSDL_Surface;
    r: TSDL_Rect;
    y: LongInt; // stupid SDL 1.2 uses stupid SmallInt for y which limits us to 32767.  But is even worse if LandTex is large, can overflow on 32767 map.
begin
    tmpsurf:= LoadDataImage(ptCurrTheme, 'LandTex', ifCritical or ifIgnoreCaps);
    r.y:= 0;
    y:= 0;
    while y < LAND_HEIGHT do
        begin
        r.x:= 0;
        while r.x < LAND_WIDTH do
            begin
            copyToXY(tmpsurf, Surface, r.x, r.y);
            inc(r.x, tmpsurf^.w)
            end;
        inc(y, tmpsurf^.h);
        r.y:= y
        end;
    SDL_FreeSurface(tmpsurf);

    // freed in freeModule() below
    LandBackSurface:= LoadDataImage(ptCurrTheme, 'LandBackTex', ifIgnoreCaps or ifColorKey);
    if (LandBackSurface <> nil) and GrayScale then Surface2GrayScale(LandBackSurface);
end;


procedure GenDrawnMap;
var lowerX, upperX, lowerY, upperY, lowerFS, upperFS: LongInt;
begin
    if (cFeatureSize <= 6) then
        MaxHedgehogs:= 6 + (cFeatureSize-1) * 2
    else if (cFeatureSize < 11) then
        MaxHedgehogs:= 16 + (cFeatureSize-6) * 4
    else if (cFeatureSize = 11) then
        MaxHedgehogs:= 48
    else if (cFeatureSize = 12) then
        MaxHedgehogs:= 64
    else
        MaxHedgehogs:= cMaxHHs;

    if GameType = gmtLandPreview then
        cFeatureSize:= 1;

    // Calculate map size for drawn map, use cFeatureSize to scale.

    // We have pre-determined map size for cFeatureSize 1, 6, 12 and 25.
    // The other values will be interpolated.
    if cFeatureSize < 6 then
        begin
        // reference size for cFeatureSize 1
        lowerFS:= 1;
        lowerX:= 1024;
        lowerY:= 512;
        upperFS:= 6;
        end
    else if cFeatureSize < 12 then
        begin
        // reference size for cFeatureSize 6
        lowerFS:= 6;
        lowerX:= 2048;
        lowerY:= 1024;
        upperFS:= 12;
        end
    else
        begin
        // reference size for cFeatureSize 12, size of drawn maps in pre-1.0.0 versions
        lowerFS:= 12;
        lowerX:= 4096;
        lowerY:= 2048;
        upperFS:= 25;
        end;

    upperX:= lowerX * 2;
    upperY:= lowerY * 2;

    if cFeatureSize = 25 then
        begin
        // hardcoded size for size level 25
        playWidth:= 8192;
        playHeight:= 4096;
        end
    else
        begin
        // Interpolation formula
        playWidth:= lowerX + ((upperX-lowerX) div (upperFS-lowerFS))*(cFeatureSize-lowerFS);
        playHeight:= lowerY + ((upperY-lowerY) div (upperFS-lowerFS))*(cFeatureSize-lowerFS);
        end;

    if GameType <> gmtLandPreview then
        WriteLnToConsole('Drawn map size: cFeatureSize='+IntToStr(cFeatureSize)+' playWidth='+IntToStr(playWidth)+' playHeight='+IntToStr(playHeight));

    ResizeLand(playWidth, playHeight);

    hasGirders:= true;
    leftX:= ((LAND_WIDTH - playWidth) div 2);
    rightX:= (playWidth + ((LAND_WIDTH - playWidth) div 2)) - 1;
    topY:= LAND_HEIGHT - playHeight;

    uLandPainted.Draw;
end;

function SelectTemplate: shortstring;
var l: LongInt;
begin
    SelectTemplate:= '';
    if (cReducedQuality and rqLowRes) <> 0 then
        SelectTemplate:= 'small'
    else
        begin
        if cTemplateFilter = 0 then
            begin
            l:= getRandom(GroupedTemplatesCount);
            repeat
                inc(cTemplateFilter);
                dec(l, TemplateCounts[cTemplateFilter]);
            until l < 0;
            end
            else getRandom(1);

            case cTemplateFilter of
            0: OutError('Error selecting TemplateFilter. Ask unC0Rr about what you did wrong', true);
            1: SelectTemplate:= 'small';
            2: SelectTemplate:= 'medium';
            3: SelectTemplate:= 'large';
            4: SelectTemplate:= 'cavern';
            5: SelectTemplate:= 'wacky';
    // For lua only!
            6: begin
               SelectTemplate:= 'small';
               GetRandom(2) // burn 1
               end
            end
        end;

    WriteLnToConsole('Using template filter '+SelectTemplate);
end;

procedure LandSurface2LandPixels(Surface: PSDL_Surface);
var x, y: LongInt;
    p: PLongwordArray;
begin
if checkFails(Surface <> nil, 'Assert (LandSurface <> nil) failed', true) then exit;

if SDL_MustLock(Surface) then
    if SDLCheck(SDL_LockSurface(Surface) >= 0, 'SDL_LockSurface', true) then exit;

p:= Surface^.pixels;
for y:= 0 to LAND_HEIGHT - 1 do
    begin
    for x:= 0 to LAND_WIDTH - 1 do
    if LandGet(y, x) <> 0 then
        if (cReducedQuality and rqBlurryLand) = 0 then
            LandPixelSet(y, x, p^[x])// or AMask
        else
            LandPixelSet(y div 2, x div 2, p^[x]);

    p:= PLongwordArray(@(p^[Surface^.pitch div 4]));
    end;

if SDL_MustLock(Surface) then
    SDL_UnlockSurface(Surface);
end;


procedure GenLandSurface;
var tmpsurf: PSDL_Surface;
    x,y: Longword;
begin
    AddProgress();

    tmpsurf:= SDL_CreateRGBSurface(SDL_SWSURFACE, LAND_WIDTH, LAND_HEIGHT, 32, RMask, GMask, BMask, AMask);

    if checkFails(tmpsurf <> nil, 'Error creating pre-land surface', true) then exit;
    ColorizeLandFast(tmpsurf);
    if gameFlags and gfShoppaBorder = 0 then DrawBorderFromImage(tmpsurf);
    AddOnLandObjects(tmpsurf);

    LandSurface2LandPixels(tmpsurf);
    SDL_FreeSurface(tmpsurf);

    if gameFlags and gfShoppaBorder <> 0 then DrawShoppaBorder;

    for x:= LongWord(leftX+2) to LongWord(rightX-2) do
        for y:= LongWord(topY+2) to LAND_HEIGHT-3 do
            if (LandGet(y, x) = 0) and
               (((LandGet(y, x-1) = lfBasic) and ((LandGet(y+1,x) = lfBasic)) or (LandGet(y-1,x) = lfBasic)) or
               ((LandGet(y, x+1) = lfBasic) and ((LandGet(y-1,x) = lfBasic) or (LandGet(y+1,x) = lfBasic)))) then
            begin
                if (cReducedQuality and rqBlurryLand) = 0 then
                    begin
                    if (LandGet(y, x-1) = lfBasic) and (LandPixelGet(y, x-1) and AMask <> 0) then
                        LandPixelSet(y, x, LandPixelGet(y, x-1))

                    else if (LandGet(y, x+1) = lfBasic) and (LandPixelGet(y, x+1) and AMask <> 0) then
                        LandPixelSet(y, x, LandPixelGet(y, x+1))

                    else if (LandGet(y-1, x) = lfBasic) and (LandPixelGet(y-1, x) and AMask <> 0) then
                        LandPixelSet(y, x, LandPixelGet(y-1, x))

                    else if (LandGet(y+1, x) = lfBasic) and (LandPixelGet(y+1, x) and AMask <> 0) then
                        LandPixelSet(y, x, LandPixelGet(y+1, x));

                    if (((LandPixelGet(y,x) and AMask) shr AShift) > 10) then
                        LandPixelSet(y, x, (LandPixelGet(y,x) and (not AMask)) or (128 shl AShift))
                    end;
                LandSet(y, x, lfObject)
            end
            else if (LandGet(y, x) = 0) and
                    (((LandGet(y, x-1) = lfBasic) and (LandGet(y+1,x-1) = lfBasic) and (LandGet(y+2,x) = lfBasic)) or
                    ((LandGet(y, x-1) = lfBasic) and (LandGet(y-1,x-1) = lfBasic) and (LandGet(y-2,x) = lfBasic)) or
                    ((LandGet(y, x+1) = lfBasic) and (LandGet(y+1,x+1) = lfBasic) and (LandGet(y+2,x) = lfBasic)) or
                    ((LandGet(y, x+1) = lfBasic) and (LandGet(y-1,x+1) = lfBasic) and (LandGet(y-2,x) = lfBasic)) or
                    ((LandGet(y+1, x) = lfBasic) and (LandGet(y+1,x+1) = lfBasic) and (LandGet(y,x+2) = lfBasic)) or
                    ((LandGet(y-1, x) = lfBasic) and (LandGet(y-1,x+1) = lfBasic) and (LandGet(y,x+2) = lfBasic)) or
                    ((LandGet(y+1, x) = lfBasic) and (LandGet(y+1,x-1) = lfBasic) and (LandGet(y,x-2) = lfBasic)) or
                    ((LandGet(y-1, x) = lfBasic) and (LandGet(y-1,x-1) = lfBasic) and (LandGet(y,x-2) = lfBasic))) then

                begin

                if (cReducedQuality and rqBlurryLand) = 0 then

                    begin

                    if (LandGet(y, x-1) = lfBasic) and (LandPixelGet(y,x-1) and AMask <> 0) then
                        LandPixelSet(y, x, LandPixelGet(y, x-1))

                    else if (LandGet(y, x+1) = lfBasic) and (LandPixelGet(y,x+1) and AMask <> 0) then
                        LandPixelSet(y, x, LandPixelGet(y, x+1))

                    else if (LandGet(y+1, x) = lfBasic) and (LandPixelGet(y+1,x) and AMask <> 0) then
                        LandPixelSet(y, x, LandPixelGet(y+1, x))

                    else if (LandGet(y-1, x) = lfBasic) and (LandPixelGet(y-1,x) and AMask <> 0) then
                        LandPixelSet(y, x, LandPixelGet(y-1, x));

                    if (((LandPixelGet(y,x) and AMask) shr AShift) > 10) then
                        LandPixelSet(y, x, (LandPixelGet(y,x) and (not AMask)) or (64 shl AShift))
                    end;
                LandSet(y, x, lfObject)
            end;

    AddProgress();
end;

procedure MakeFortsPreview;
var gap: LongInt;
    h1, h2, w1, w2, x, y, lastX, wbm, bmref: LongWord;
const fortHeight = 960;
      fortWidth  = 704;
      bmHeight = 53;
      bmWidth = 64;
begin
ResizeLand(4096,2048);

lastX:= LAND_WIDTH-1;

gap:= (1024 - fortWidth) + 60 + 20 * cFeatureSize;

h2:= LAND_HEIGHT-1;
h1:= h2 - fortHeight;
w2:= (LAND_WIDTH - gap) div 2;
w1:= w2 - fortWidth;
wbm:= h1 + bmHeight;

// generate 2 forts in center
for y:= h1 to h2 do
    for x:= w1 to w2 do
        begin
        if x mod 4 <> 0 then
            begin
            if (y <= wbm) and ((x - w1) mod (bmWidth * 2) >= bmWidth) then
                continue;
            LandSet(y, x, lfBasic);
            LandSet(y, lastX - x, lfBasic);
            end;
        end;

w2:= w1 - gap;
w1:= max(0, w2 - fortWidth);
wbm:= h1 + bmHeight;
bmref:= w2 + bmWidth;

for y:= h1 to h2 do
    for x:= w1 to w2 do
        begin
        if ((y - x) mod 2) = 0 then
            begin
            // align battlement on inner edge, because real outer edge could be offscreen
            if (y <= wbm) and ((LAND_WIDTH + x - bmref) mod (bmWidth * 2) >= bmWidth) then
                continue;
            LandSet(y, x, lfBasic);
            LandSet(y, lastX - x, lfBasic);
            end;
        end;
end;

procedure MakeFortsMap;
var tmpsurf: PSDL_Surface;
    sectionWidth, i, t, p: integer;
    mirror: boolean;
    pc: PClan;
begin

// make the gaps between forts adjustable if fort map was selected
if cMapGen = mgForts then
    sectionWidth:= 1024 + 60 + 20 * cFeatureSize
else
    sectionWidth:= 1024 * 300;

// mix up spawn/fort order of clans
for i:= 0 to ClansCount - 1 do
    begin
    t:= GetRandom(ClansCount);
    p:= GetRandom(ClansCount);
    if t <> p then
        begin
        pc:= SpawnClansArray[t];
        SpawnClansArray[t]:= SpawnClansArray[p];
        SpawnClansArray[p]:= pc;
        end;
    end;

// figure out how much space we need
playWidth:= sectionWidth * ClansCount;

// note: LAND_WIDTH might be bigger than specified below (rounded to next power of 2)
ResizeLand(playWidth, 2048);

// For now, defining a fort is playable area as 3072x1200 - there are no tall forts.  The extra height is to avoid triggering border with current code, also if user turns on a border, it will give a bit more maneuvering room.
playHeight:= 1200;

// center playable area in land array
leftX:= ((LAND_WIDTH - playWidth) div 2);
rightX:= ((playWidth + (LAND_WIDTH - playWidth) div 2) - 1);
topY:= LAND_HEIGHT - playHeight;

WriteLnToConsole('Generating forts land...');

for i := 0 to ClansCount - 1 do
    begin

    // face in random direction
    mirror:= (GetRandom(2) = 0);
    // make first/last fort face inwards
    if (WorldEdge <> weWrap) or (ClansCount = 2) then
        mirror:= (i <> 0) and (mirror or (i = ClansCount - 1));

    if mirror then
        begin
        // not critical because if no R we can fallback to mirrored L
        tmpsurf:= LoadDataImage(ptForts, SpawnClansArray[i]^.Teams[0]^.FortName + 'R', ifAlpha or ifColorKey or ifIgnoreCaps);
        // fallback
        if tmpsurf = nil then
            begin
            tmpsurf:= LoadDataImage(ptForts, SpawnClansArray[i]^.Teams[0]^.FortName + 'L', ifAlpha or ifCritical or ifColorKey or ifIgnoreCaps);
            BlitImageAndGenerateCollisionInfo(leftX + sectionWidth * i + ((sectionWidth - tmpsurf^.w) div 2), LAND_HEIGHT - tmpsurf^.h, tmpsurf^.w, tmpsurf, 0, true);
            end
        else
            BlitImageAndGenerateCollisionInfo(leftX + sectionWidth * i + ((sectionWidth - tmpsurf^.w) div 2), LAND_HEIGHT - tmpsurf^.h, tmpsurf^.w, tmpsurf);
        SDL_FreeSurface(tmpsurf);
        end
    else
        begin
        tmpsurf:= LoadDataImage(ptForts, SpawnClansArray[i]^.Teams[0]^.FortName + 'L', ifAlpha or ifCritical or ifColorKey or ifIgnoreCaps);
        BlitImageAndGenerateCollisionInfo(leftX + sectionWidth * i + ((sectionWidth - tmpsurf^.w) div 2), LAND_HEIGHT - tmpsurf^.h, tmpsurf^.w, tmpsurf);
        SDL_FreeSurface(tmpsurf);
        end;

    end;
end;

procedure LoadMapConfig;
var f: PFSFile;
    s: shortstring;
begin
s:= cPathz[ptMapCurrent] + '/map.cfg';

WriteLnToConsole('Fetching map HH limit');

f:= pfsOpenRead(s);
if f <> nil then
    begin
    pfsReadLn(f, s);
    if not pfsEof(f) then
        begin
        pfsReadLn(f, s);
        val(s, MaxHedgehogs)
        end;

    pfsClose(f)
    end;

if (MaxHedgehogs = 0) then
    MaxHedgehogs:= 18;
end;

// Loads Land[] from an image, allowing overriding standard collision
procedure LoadMask;
var tmpsurf: PSDL_Surface;
    p: PLongwordArray;
    x, y, cpX, cpY: Longword;
    mapName: shortstring;
begin
tmpsurf:= LoadDataImage(ptMapCurrent, 'mask', ifAlpha or ifColorKey or ifIgnoreCaps);
if tmpsurf = nil then
    begin
    mapName:= ExtractFileName(cPathz[ptMapCurrent]);
    tmpsurf:= LoadDataImage(ptMissionMaps, mapName + '/mask', ifAlpha or ifColorKey or ifIgnoreCaps);
    end;


if (tmpsurf <> nil) and (tmpsurf^.format^.BytesPerPixel = 4) then
    begin
    if LAND_WIDTH = 0 then
        begin
        LoadMapConfig;
        ResizeLand(tmpsurf^.w, tmpsurf^.h);
        playHeight:= tmpsurf^.h;
        playWidth:= tmpsurf^.w;
        leftX:= (LAND_WIDTH - playWidth) div 2;
        rightX:= (playWidth + ((LAND_WIDTH - playWidth) div 2)) - 1;
        topY:= LAND_HEIGHT - playHeight;
        end;
    disableLandBack:= true;

    cpX:= (LAND_WIDTH - tmpsurf^.w) div 2;
    cpY:= LAND_HEIGHT - tmpsurf^.h;
    if SDL_MustLock(tmpsurf) then
        SDLCheck(SDL_LockSurface(tmpsurf) >= 0, 'SDL_LockSurface', true);

    if allOK then
    begin
        p:= tmpsurf^.pixels;
        for y:= 0 to Pred(tmpsurf^.h) do
            begin
            for x:= 0 to Pred(tmpsurf^.w) do
                SetLand(cpY + y, cpX + x, p^[x]);
            p:= PLongwordArray(@(p^[tmpsurf^.pitch div 4]));
            end;

        if SDL_MustLock(tmpsurf) then
            SDL_UnlockSurface(tmpsurf);
        if not disableLandBack then
            begin
            // freed in freeModule() below
            LandBackSurface:= LoadDataImage(ptCurrTheme, 'LandBackTex', ifIgnoreCaps or ifColorKey);
            if (LandBackSurface <> nil) and GrayScale then
                Surface2GrayScale(LandBackSurface)
            end;
    end;
end;
if (tmpsurf <> nil) then
    SDL_FreeSurface(tmpsurf);
tmpsurf:= nil;
end;

procedure LoadMap;
var tmpsurf: PSDL_Surface;
    mapName: shortstring = '';
begin
WriteLnToConsole('Loading land from file...');
AddProgress;
tmpsurf:= LoadDataImage(ptMapCurrent, 'map', ifAlpha or ifColorKey or ifIgnoreCaps);
if tmpsurf = nil then
    begin
    mapName:= ExtractFileName(cPathz[ptMapCurrent]);
    tmpsurf:= LoadDataImage(ptMissionMaps, mapName + '/map', ifAlpha or ifCritical or ifColorKey or ifIgnoreCaps);
    if not allOK then exit;
    end;
// (bare) Sanity check. Considering possible LongInt comparisons as well as just how much system memoery it would take
if checkFails((tmpsurf^.w < $40000000) and (tmpsurf^.h < $40000000) and (QWord(tmpsurf^.w) * tmpsurf^.h < 6*1024*1024*1024), 'Map dimensions too big!', true)
        then exit;

ResizeLand(tmpsurf^.w, tmpsurf^.h);
LoadMapConfig;

playHeight:= tmpsurf^.h;
playWidth:= tmpsurf^.w;
leftX:= (LAND_WIDTH - playWidth) div 2;
rightX:= (playWidth + ((LAND_WIDTH - playWidth) div 2)) - 1;
topY:= LAND_HEIGHT - playHeight;

if not checkFails(tmpsurf^.format^.BytesPerPixel = 4, 'Map should be 32bit', true) then
    BlitImageAndGenerateCollisionInfo(
        (LAND_WIDTH - tmpsurf^.w) div 2,
        LAND_HEIGHT - tmpsurf^.h,
        tmpsurf^.w,
        tmpsurf);

SDL_FreeSurface(tmpsurf);

if allOK then LoadMask;
end;

procedure DrawBottomBorder; // broken out from other borders for doing a floor-only map, or possibly updating bottom during SD
var x, w, c, y: Longword;
begin
for w:= 0 to 23 do
    for x:= LongWord(leftX) to LongWord(rightX) do
        begin
        y:= Longword(cWaterLine) - 1 - w;
        LandSet(y, x, lfIndestructible);
        if (x + y) mod 32 < 16 then
            c:= AMask
        else
            c:= AMask or RMask or GMask; // FF00FFFF

        if (cReducedQuality and rqBlurryLand) = 0 then
            LandPixelSet(y, x, c)
        else
            LandPixelSet(y div 2, x div 2, c)
        end
end;

procedure GenMap;
var x, y, w, c, c2: Longword;
    map, mask: shortstring;
begin
    hasBorder:= false;
    maskOnly:= false;

    LoadThemeConfig;

    if cPathz[ptMapCurrent] <> '' then
        begin
        map:= cPathz[ptMapCurrent] + '/map.png';
        mask:= cPathz[ptMapCurrent] + '/mask.png';
        if (not(pfsExists(map)) and pfsExists(mask)) then
            begin
            maskOnly:= true;
            LoadMask;
            GenLandSurface
            end
        else LoadMap;
        end
    else
        begin
        WriteLnToConsole('Generating land...');
        case cMapGen of
            mgRandom: GenerateOutlineTemplatedLand(cFeatureSize, cSeed, SelectTemplate, PathPrefix);
            mgMaze  : GenerateMazeLand(cFeatureSize, cSeed, SelectTemplate, PathPrefix);
            mgPerlin: begin ResizeLand(4096,2048); GenPerlin; end;
            mgDrawn : GenDrawnMap;
            mgForts : begin GameFlags:= (GameFlags or gfDivideTeams); MakeFortsMap(); end;
            mgWfc: GenerateWfcTemplatedLand(cFeatureSize, cSeed, SelectTemplate, PathPrefix);
        else
            OutError('Unknown mapgen', true);
        end;
        if (cMapGen <> mgForts) then
            GenLandSurface
        end;

    AddProgress;

// check for land near top
c:= 0;
if (GameFlags and gfBorder) <> 0 then
    hasBorder:= true
else
    for y:= LongWord(topY) to LongWord(topY + 5) do
        for x:= LongWord(leftX) to LongWord(rightX) do
            if LandGet(y, x) <> 0 then
                begin
                inc(c);
                if c > LongWord((LAND_WIDTH div 2)) then // avoid accidental triggering
                    begin
                    hasBorder:= true;
                    break;
                    end;
                end;

// Indestructible map border (top, left, right)
if hasBorder then
    begin
    // Make land beyond the border indestructible
    if WorldEdge = weNone then
        begin
        for y:= 0 to LAND_HEIGHT - 1 do
            for x:= 0 to LAND_WIDTH - 1 do
                if (y < LongWord(topY)) or (x < LongWord(leftX)) or (x > LongWord(rightX)) then
                    LandSet(y, x, lfIndestructible);
        end
    else if topY > 0 then
        begin
        for y:= 0 to LongWord(topY - 1) do
            for x:= 0 to LAND_WIDTH - 1 do
                LandSet(y, x, lfIndestructible);
        end;
    // Render map border
    for w:= 0 to (cBorderWidth-1) do
        begin
        // Left and right border
        if (WorldEdge <> weBounce) and (WorldEdge <> weWrap) then
            for y:= LongWord(topY) to LAND_HEIGHT - 1 do
                    begin
                    // set land flags
                    LandSet(y, leftX + w, lfIndestructible);
                    LandSet(y, rightX - w, lfIndestructible);

                    // paint black and yellow stripes
                    if (y + leftX + w) mod 32 < 16 then
                        c:= AMask // black
                    else
                        c:= AMask or RMask or GMask; // yellow
                    if (y + rightX - w) mod 32 < 16 then
                        c2:= AMask // black
                    else
                        c2:= AMask or RMask or GMask; // yellow

                    if (cReducedQuality and rqBlurryLand) = 0 then
                        begin
                        LandPixelSet(y, leftX + w, c);
                        LandPixelSet(y, rightX - w, c2);
                        end
                    else
                        begin
                        LandPixelSet(y div 2, (leftX + w) div 2, c);
                        LandPixelSet(y div 2, (rightX - w) div 2, c2);
                        end;
                    end;

        // Top border
        for x:= LongWord(leftX) to LongWord(rightX) do
            begin
            LandSet(topY + w, x, lfIndestructible);
            if (topY + x + w) mod 32 < 16 then
                c:= AMask // black
            else
                c:= AMask or RMask or GMask; // yellow

            if (cReducedQuality and rqBlurryLand) = 0 then
                LandPixelSet(topY + w, x, c)
            else
                LandPixelSet((topY + w) div 2, x div 2, c);
            end;
        end;
    end;

// Bottom border
if (GameFlags and gfBottomBorder) <> 0 then
    DrawBottomBorder;

if (GameFlags and gfDisableGirders) <> 0 then
    hasGirders:= false;

if (cMapGen <> mgForts) and (maskOnly or (cPathz[ptMapCurrent] = '')) then
    AddObjects

else
    AddProgress();

FreeLandObjects;

if not allOK then exit;

if GrayScale then
    begin
    if (cReducedQuality and rqBlurryLand) = 0 then
        for x:= LongWord(leftX) to LongWord(rightX) do
            for y:= LongWord(topY) to LAND_HEIGHT-1 do
                begin
                w:= LandPixelGet(y,x);
                w:= round(((w shr RShift and $FF) * RGB_LUMINANCE_RED +
                      (w shr BShift and $FF) * RGB_LUMINANCE_GREEN +
                      (w shr GShift and $FF) * RGB_LUMINANCE_BLUE));
                if w > 255 then
                    w:= 255;
                w:= (w and $FF shl RShift) or (w and $FF shl BShift) or (w and $FF shl GShift) or (LandPixelGet(y,x) and AMask);
                LandPixelSet(y, x, w or (LandPixelGet(y, x) and AMask))
                end
    else
        for x:= LongWord(leftX div 2) to LongWord(rightX div 2) do
            for y:= LongWord(topY div 2) to LAND_HEIGHT-1 div 2 do
                begin
                w:= LandPixelGet(y div 2,x div 2);
                w:= ((w shr RShift and $FF) +  (w shr BShift and $FF) + (w shr GShift and $FF)) div 3;
                w:= (w and $FF shl RShift) or (w and $FF shl BShift) or (w and $FF shl GShift) or (LandPixelGet(y div 2,x div 2) and AMask);
                LandPixelSet(y, x, w or (LandPixelGet(y div 2, x div 2) and AMask))
                end
    end;

PrettifyLandAlpha();

// adjust world edges for borderless maps
if (WorldEdge <> weNone) and (not hasBorder) then
    InitWorldEdges();

ScriptSetMapGlobals;
end;

procedure GenPreview(out Preview: TPreview);
var rh, rw, ox, oy, x, y, xx, yy, t, bit, cbit, lh, lw: LongInt;
begin
    WriteLnToConsole('Generating preview...');
    case cMapGen of
        mgRandom: GenerateOutlineTemplatedLand(cFeatureSize, cSeed, SelectTemplate, PathPrefix);
        mgMaze: GenerateMazeLand(cFeatureSize, cSeed, SelectTemplate, PathPrefix);
        mgPerlin: begin ResizeLand(4096,2048); GenPerlin; end;
        mgDrawn: begin GenDrawnMap; end;
        mgForts: MakeFortsPreview();
        mgWfc: GenerateWfcTemplatedLand(cFeatureSize, cSeed, SelectTemplate, PathPrefix);
    else
        OutError('Unknown mapgen', true);
    end;

    ScriptSetMapGlobals;

    // strict scaling needed here since preview assumes a rectangle
    if (cMapGen <> mgDrawn) then
        begin
        rh:= max(LAND_HEIGHT, 2048);
        rw:= max(LAND_WIDTH, 4096);
        end
    else
        begin
        rh:= LAND_HEIGHT;
        rw:= LAND_WIDTH
        end;
    ox:= 0;
    if rw < rh*2 then
        begin
        rw:= rh*2;
        end;
    if rh < rw div 2 then rh:= rw * 2;

    ox:= (rw-LAND_WIDTH) div 2;
    oy:= rh-LAND_HEIGHT;

    lh:= rh div 128;
    lw:= rw div 32;
    for y:= 0 to 127 do
        for x:= 0 to 31 do
        begin
            Preview[y, x]:= 0;
            for bit:= 0 to 7 do
            begin
                t:= 0;
                cbit:= bit * 8;
                for yy:= y * lh to y * lh + 7 do
                    for xx:= x * lw + cbit to x * lw + cbit + 7 do
                        if ((yy-oy) and LAND_HEIGHT_MASK = 0) and ((xx-ox) and LAND_WIDTH_MASK = 0)
                           and (LandGet(yy-oy, xx-ox) <> 0) then
                            inc(t);
                if t > 8 then
                    Preview[y, x]:= Preview[y, x] or ($80 shr bit);
            end;
        end;
end;


procedure GenPreviewAlpha(out Preview: TPreviewAlpha);
var rh, rw, ox, oy, x, y, xx, yy, t, lh, lw: LongInt;
begin
    WriteLnToConsole('Generating preview...');
    case cMapGen of
        mgRandom: GenerateOutlineTemplatedLand(cFeatureSize, cSeed, SelectTemplate, PathPrefix);
        mgMaze: GenerateMazeLand(cFeatureSize, cSeed, SelectTemplate, PathPrefix);
        mgPerlin: begin ResizeLand(4096,2048); GenPerlin; end;
        mgDrawn: begin GenDrawnMap; end;
        mgForts: MakeFortsPreview;
        mgWfc: GenerateWfcTemplatedLand(cFeatureSize, cSeed, SelectTemplate, PathPrefix);
    else
        OutError('Unknown mapgen', true);
    end;

    ScriptSetMapGlobals;


    // strict scaling needed here since preview assumes a rectangle
    if (cMapGen <> mgDrawn) then
        begin
        rh:= max(LAND_HEIGHT, 2048);
        rw:= max(LAND_WIDTH, 4096);
        end
    else
        begin
        rh:= LAND_HEIGHT;
        rw:= LAND_WIDTH
        end;

    ox:= 0;
    if rw < rh*2 then
        begin
        rw:= rh*2;
        end;
    if rh < rw div 2 then rh:= rw * 2;

    ox:= (rw-LAND_WIDTH) div 2;
    oy:= rh-LAND_HEIGHT;

    lh:= rh div 128;
    lw:= rw div 256;
    for y:= 0 to 127 do
        for x:= 0 to 255 do
            begin
            t:= 0;

            for yy:= y * lh - oy to y * lh + lh - 1 - oy do
                for xx:= x * lw - ox to x * lw + lw - 1 - ox do
                    if (yy and LAND_HEIGHT_MASK = 0) and (xx and LAND_WIDTH_MASK = 0)
                        and (LandGet(yy, xx) <> 0) then
                        inc(t);

            Preview[y, x]:= t * 255 div (lh * lw);
            end;
end;

procedure chLandCheck(var s: shortstring);
begin
    AddFileLog('CheckLandDigest: ' + s + ' digest : ' + digest);
    if digest = '' then
        digest:= s
    else
        checkFails(s = digest, 'Loaded map or other critical resource does not match across all players', true);
end;

procedure chSendLandDigest(var s: shortstring);
var i: LongInt;
    landPixelDigest  : LongInt;
begin
    landPixelDigest:= 1;
    for i:= 0 to LAND_HEIGHT-1 do
        landPixelDigest:= Adler32Update(landPixelDigest, LandRow(i), LAND_WIDTH*2);
    s:= 'M' + IntToStr(syncedPixelDigest)+'|'+IntToStr(landPixelDigest);

    ScriptSetString('LandDigest',IntToStr(landPixelDigest));

    chLandCheck(s);
    if allOK then SendIPCRaw(@s[0], Length(s) + 1)
end;

procedure initModule;
begin
    RegisterVariable('landcheck', @chLandCheck, false);
    RegisterVariable('sendlanddigest', @chSendLandDigest, false);

    LandBackSurface:= nil;
    digest:= '';
    maskOnly:= false;
    LAND_WIDTH:= 0;
    LAND_HEIGHT:= 0;
end;

procedure freeModule;
begin
    DisposeLand;
    SetLength(LandDirty, 0, 0);
end;

end.
