(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uLand;
interface
uses SDLh, uLandTemplates, uFloat, uConsts, GLunit, uTypes, uAILandMarks;

procedure initModule;
procedure freeModule;
procedure DrawBottomBorder;
procedure GenMap;
procedure GenPreview(out Preview: TPreview);

implementation
uses uConsole, uStore, uRandom, uLandObjects, uIO, uLandTexture, SysUtils,
     uVariables, uUtils, uCommands, adler32, uDebug, uLandPainted, uTextures,
     uLandGenMaze, uLandOutline;

var digest: shortstring;

procedure ResizeLand(width, height: LongWord);
var potW, potH: LongWord;
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
    end;
end;

procedure ColorizeLand(Surface: PSDL_Surface);
var tmpsurf: PSDL_Surface;
    r, rr: TSDL_Rect;
    x, yd, yu: LongInt;
begin
    tmpsurf:= LoadDataImage(ptCurrTheme, 'LandTex', ifCritical or ifIgnoreCaps);
    r.y:= 0;
    while r.y < LAND_HEIGHT do
    begin
        r.x:= 0;
        while r.x < LAND_WIDTH do
        begin
            SDL_UpperBlit(tmpsurf, nil, Surface, @r);
            inc(r.x, tmpsurf^.w)
        end;
        inc(r.y, tmpsurf^.h)
    end;
    SDL_FreeSurface(tmpsurf);

    // freed in freeModule() below
    LandBackSurface:= LoadDataImage(ptCurrTheme, 'LandBackTex', ifIgnoreCaps or ifTransparent);
    if (LandBackSurface <> nil) and GrayScale then Surface2GrayScale(LandBackSurface);

    tmpsurf:= LoadDataImage(ptCurrTheme, 'Border', ifCritical or ifIgnoreCaps or ifTransparent);
    for x:= 0 to LAND_WIDTH - 1 do
    begin
        yd:= LAND_HEIGHT - 1;
        repeat
            while (yd > 0) and (Land[yd, x] =  0) do dec(yd);

            if (yd < 0) then
                yd:= 0;

            while (yd < LAND_HEIGHT) and (Land[yd, x] <> 0) do
                inc(yd);
            dec(yd);
            yu:= yd;

            while (yu > 0  ) and (Land[yu, x] <> 0) do dec(yu);
            while (yu < yd ) and (Land[yu, x] =  0) do inc(yu);

            if (yd < LAND_HEIGHT - 1) and ((yd - yu) >= 16) then
                begin
                rr.x:= x;
                rr.y:= yd - 15;
                r.x:= x mod tmpsurf^.w;
                r.y:= 16;
                r.w:= 1;
                r.h:= 16;
                SDL_UpperBlit(tmpsurf, @r, Surface, @rr);
                end;
            if (yu > 0) then
                begin
                rr.x:= x;
                rr.y:= yu;
                r.x:= x mod tmpsurf^.w;
                r.y:= 0;
                r.w:= 1;
                r.h:= Min(16, yd - yu + 1);
                SDL_UpperBlit(tmpsurf, @r, Surface, @rr);
                end;
            yd:= yu - 1;
        until yd < 0;
    end;
    SDL_FreeSurface(tmpsurf);
end;

procedure SetPoints(var Template: TEdgeTemplate; var pa: TPixAr; fps: PPointArray);
var i: LongInt;
begin
with Template do
    begin
    pa.Count:= BasePointsCount;
    for i:= 0 to pred(pa.Count) do
        begin
        pa.ar[i].x:= BasePoints^[i].x + LongInt(GetRandom(BasePoints^[i].w));
        if pa.ar[i].x <> NTPX then
           pa.ar[i].x:= pa.ar[i].x + ((LAND_WIDTH - Template.TemplateWidth) div 2);
        pa.ar[i].y:= BasePoints^[i].y + LongInt(GetRandom(BasePoints^[i].h)) + LAND_HEIGHT - LongInt(Template.TemplateHeight)
        end;

    if canMirror then
        if getrandom(2) = 0 then
            begin
            for i:= 0 to pred(BasePointsCount) do
               if pa.ar[i].x <> NTPX then
                   pa.ar[i].x:= LAND_WIDTH - 1 - pa.ar[i].x;
            for i:= 0 to pred(FillPointsCount) do
                fps^[i].x:= LAND_WIDTH - 1 - fps^[i].x;
            end;

(*  Experiment in making this option more useful
     if ((not isNegative) and (cTemplateFilter = 4)) or
        (canFlip and (getrandom(2) = 0)) then
           begin
           for i:= 0 to pred(BasePointsCount) do
               begin
               pa.ar[i].y:= LAND_HEIGHT - 1 - pa.ar[i].y + (LAND_HEIGHT - TemplateHeight) * 2;
               if pa.ar[i].y > LAND_HEIGHT - 1 then
                   pa.ar[i].y:= LAND_HEIGHT - 1;
               end;
           for i:= 0 to pred(FillPointsCount) do
               begin
               FillPoints^[i].y:= LAND_HEIGHT - 1 - FillPoints^[i].y + (LAND_HEIGHT - TemplateHeight) * 2;
               if FillPoints^[i].y > LAND_HEIGHT - 1 then
                   FillPoints^[i].y:= LAND_HEIGHT - 1;
               end;
           end;
     end
*)
// template recycling.  Pull these off the floor a bit
    if (not isNegative) and (cTemplateFilter = 4) then
        begin
        for i:= 0 to pred(BasePointsCount) do
            begin
            dec(pa.ar[i].y, 100);
            if pa.ar[i].y < 0 then
                pa.ar[i].y:= 0;
            end;
        for i:= 0 to pred(FillPointsCount) do
            begin
            dec(fps^[i].y, 100);
            if fps^[i].y < 0 then
                fps^[i].y:= 0;
            end;
        end;

    if (canFlip and (getrandom(2) = 0)) then
        begin
        for i:= 0 to pred(BasePointsCount) do
            pa.ar[i].y:= LAND_HEIGHT - 1 - pa.ar[i].y;
        for i:= 0 to pred(FillPointsCount) do
            fps^[i].y:= LAND_HEIGHT - 1 - fps^[i].y;
        end;
    end
end;


procedure GenBlank(var Template: TEdgeTemplate);
var pa: TPixAr;
    i: Longword;
    y, x: Longword;
    fps: TPointArray;
begin
    fps:=Template.FillPoints^;
    ResizeLand(Template.TemplateWidth, Template.TemplateHeight);
    for y:= 0 to LAND_HEIGHT - 1 do
        for x:= 0 to LAND_WIDTH - 1 do
            Land[y, x]:= lfBasic;
    {$HINTS OFF}
    SetPoints(Template, pa, @fps);
    {$HINTS ON}
    for i:= 1 to Template.BezierizeCount do
        begin
        BezierizeEdge(pa, _0_5);
        RandomizePoints(pa);
        RandomizePoints(pa)
        end;
    for i:= 1 to Template.RandPassesCount do
        RandomizePoints(pa);
    BezierizeEdge(pa, _0_1);


    DrawEdge(pa, 0);

    with Template do
        for i:= 0 to pred(FillPointsCount) do
            with fps[i] do
                FillLand(x, y);

    DrawEdge(pa, lfBasic);

    MaxHedgehogs:= Template.MaxHedgehogs;
    hasGirders:= Template.hasGirders;
    playHeight:= Template.TemplateHeight;
    playWidth:= Template.TemplateWidth;
    leftX:= ((LAND_WIDTH - playWidth) div 2);
    rightX:= (playWidth + ((LAND_WIDTH - playWidth) div 2)) - 1;
    topY:= LAND_HEIGHT - playHeight;

    // HACK: force to only cavern even if a cavern map is invertable if cTemplateFilter = 4 ?
    if (cTemplateFilter = 4)
    or (Template.canInvert and (getrandom(2) = 0))
    or (not Template.canInvert and Template.isNegative) then
        begin
        hasBorder:= true;
        for y:= 0 to LAND_HEIGHT - 1 do
            for x:= 0 to LAND_WIDTH - 1 do
                if (y < topY) or (x < leftX) or (x > rightX) then
                    Land[y, x]:= 0
                else
                    begin
                    if Land[y, x] = 0 then
                        Land[y, x]:= lfBasic
                    else if Land[y, x] = lfBasic then
                        Land[y, x]:= 0;
                    end;
        end;
end;

procedure GenDrawnMap;
begin
    ResizeLand(4096, 2048);
    uLandPainted.Draw;

    MaxHedgehogs:= 48;
    hasGirders:= true;
    playHeight:= 2048;
    playWidth:= 4096;
    leftX:= ((LAND_WIDTH - playWidth) div 2);
    rightX:= (playWidth + ((LAND_WIDTH - playWidth) div 2)) - 1;
    topY:= LAND_HEIGHT - playHeight;
end;

function SelectTemplate: LongInt;
begin
    if (cReducedQuality and rqLowRes) <> 0 then
        SelectTemplate:= SmallTemplates[getrandom(Succ(High(SmallTemplates)))]
    else
        case cTemplateFilter of
        0: SelectTemplate:= getrandom(Succ(High(EdgeTemplates)));
        1: SelectTemplate:= SmallTemplates[getrandom(Succ(High(SmallTemplates)))];
        2: SelectTemplate:= MediumTemplates[getrandom(Succ(High(MediumTemplates)))];
        3: SelectTemplate:= LargeTemplates[getrandom(Succ(High(LargeTemplates)))];
        4: SelectTemplate:= CavernTemplates[getrandom(Succ(High(CavernTemplates)))];
        5: SelectTemplate:= WackyTemplates[getrandom(Succ(High(WackyTemplates)))];
// For lua only!
        6: begin
           SelectTemplate:= min(LuaTemplateNumber,High(EdgeTemplates));
           GetRandom(2) // burn 1
           end;
    end;

    WriteLnToConsole('Selected template #'+inttostr(SelectTemplate)+' using filter #'+inttostr(cTemplateFilter));
end;

procedure LandSurface2LandPixels(Surface: PSDL_Surface);
var x, y: LongInt;
    p: PLongwordArray;
begin
TryDo(Surface <> nil, 'Assert (LandSurface <> nil) failed', true);

if SDL_MustLock(Surface) then
    SDLTry(SDL_LockSurface(Surface) >= 0, true);

p:= Surface^.pixels;
for y:= 0 to LAND_HEIGHT - 1 do
    begin
    for x:= 0 to LAND_WIDTH - 1 do
    if Land[y, x] <> 0 then
        if (cReducedQuality and rqBlurryLand) = 0 then
            LandPixels[y, x]:= p^[x] or AMask
        else
            LandPixels[y div 2, x div 2]:= p^[x] or AMask;

    p:= @(p^[Surface^.pitch div 4]);
    end;

if SDL_MustLock(Surface) then
    SDL_UnlockSurface(Surface);
end;


procedure GenLandSurface;
var tmpsurf: PSDL_Surface;
    x,y: Longword;
begin
    WriteLnToConsole('Generating land...');
    case cMapGen of
        0: GenBlank(EdgeTemplates[SelectTemplate]);
        1: begin ResizeLand(4096,2048); GenMaze; end;
        2: GenDrawnMap;
    else
        OutError('Unknown mapgen', true);
    end;
    AddProgress();

    tmpsurf:= SDL_CreateRGBSurface(SDL_SWSURFACE, LAND_WIDTH, LAND_HEIGHT, 32, RMask, GMask, BMask, 0);

    TryDo(tmpsurf <> nil, 'Error creating pre-land surface', true);
    ColorizeLand(tmpsurf);
    AddOnLandObjects(tmpsurf);

    LandSurface2LandPixels(tmpsurf);
    SDL_FreeSurface(tmpsurf);
    for x:= leftX+2 to rightX-2 do
        for y:= topY+2 to LAND_HEIGHT-3 do
            if (Land[y, x] = 0) and 
               (((Land[y, x-1] = lfBasic) and ((Land[y+1,x] = lfBasic)) or (Land[y-1,x] = lfBasic)) or
               ((Land[y, x+1] = lfBasic) and ((Land[y-1,x] = lfBasic) or (Land[y+1,x] = lfBasic)))) then
            begin
                if (cReducedQuality and rqBlurryLand) = 0 then
                    begin
                    if (Land[y, x-1] = lfBasic) and (LandPixels[y, x-1] and AMask <> 0) then
                        LandPixels[y, x]:= LandPixels[y, x-1]
                        
                    else if (Land[y, x+1] = lfBasic) and (LandPixels[y, x+1] and AMask <> 0) then
                        LandPixels[y, x]:= LandPixels[y, x+1]
                        
                    else if (Land[y-1, x] = lfBasic) and (LandPixels[y-1, x] and AMask <> 0) then
                        LandPixels[y, x]:= LandPixels[y-1, x]
                        
                    else if (Land[y+1, x] = lfBasic) and (LandPixels[y+1, x] and AMask <> 0) then
                        LandPixels[y, x]:= LandPixels[y+1, x];
                        
                    if (((LandPixels[y,x] and AMask) shr AShift) > 10) then
                        LandPixels[y,x]:= (LandPixels[y,x] and (not AMask)) or (128 shl AShift)
                    end;
                Land[y,x]:= lfObject
            end
            else if (Land[y, x] = 0) and
                    (((Land[y, x-1] = lfBasic) and (Land[y+1,x-1] = lfBasic) and (Land[y+2,x] = lfBasic)) or
                    ((Land[y, x-1] = lfBasic) and (Land[y-1,x-1] = lfBasic) and (Land[y-2,x] = lfBasic)) or
                    ((Land[y, x+1] = lfBasic) and (Land[y+1,x+1] = lfBasic) and (Land[y+2,x] = lfBasic)) or
                    ((Land[y, x+1] = lfBasic) and (Land[y-1,x+1] = lfBasic) and (Land[y-2,x] = lfBasic)) or
                    ((Land[y+1, x] = lfBasic) and (Land[y+1,x+1] = lfBasic) and (Land[y,x+2] = lfBasic)) or
                    ((Land[y-1, x] = lfBasic) and (Land[y-1,x+1] = lfBasic) and (Land[y,x+2] = lfBasic)) or
                    ((Land[y+1, x] = lfBasic) and (Land[y+1,x-1] = lfBasic) and (Land[y,x-2] = lfBasic)) or
                    ((Land[y-1, x] = lfBasic) and (Land[y-1,x-1] = lfBasic) and (Land[y,x-2] = lfBasic))) then
                    
                begin
                
                if (cReducedQuality and rqBlurryLand) = 0 then
                
                    begin
                    
                    if (Land[y, x-1] = lfBasic) and (LandPixels[y,x-1] and AMask <> 0) then
                        LandPixels[y, x]:= LandPixels[y, x-1]
                        
                    else if (Land[y, x+1] = lfBasic) and (LandPixels[y,x+1] and AMask <> 0) then
                        LandPixels[y, x]:= LandPixels[y, x+1]
                        
                    else if (Land[y+1, x] = lfBasic) and (LandPixels[y+1,x] and AMask <> 0) then
                        LandPixels[y, x]:= LandPixels[y+1, x]
                        
                    else if (Land[y-1, x] = lfBasic) and (LandPixels[y-1,x] and AMask <> 0) then
                        LandPixels[y, x]:= LandPixels[y-1, x];
                        
                    if (((LandPixels[y,x] and AMask) shr AShift) > 10) then
                        LandPixels[y,x]:= (LandPixels[y,x] and (not AMask)) or (64 shl AShift)
                    end;
                Land[y,x]:= lfObject
            end;

    AddProgress();
end;

procedure MakeFortsMap;
var tmpsurf: PSDL_Surface;
begin
ResizeLand(4096,2048);
MaxHedgehogs:= 32;
// For now, defining a fort is playable area as 3072x1200 - there are no tall forts.  The extra height is to avoid triggering border with current code, also if user turns on a border, it will give a bit more maneuvering room.
playHeight:= 1200;
playWidth:= 2560;
leftX:= (LAND_WIDTH - playWidth) div 2;
rightX:= ((playWidth + (LAND_WIDTH - playWidth) div 2) - 1);
topY:= LAND_HEIGHT - playHeight;

WriteLnToConsole('Generating forts land...');

tmpsurf:= LoadDataImage(ptForts, ClansArray[0]^.Teams[0]^.FortName + 'L', ifAlpha or ifCritical or ifTransparent or ifIgnoreCaps);
BlitImageAndGenerateCollisionInfo(leftX+150, LAND_HEIGHT - tmpsurf^.h, tmpsurf^.w, tmpsurf);
SDL_FreeSurface(tmpsurf);

tmpsurf:= LoadDataImage(ptForts, ClansArray[1]^.Teams[0]^.FortName + 'R', ifAlpha or ifCritical or ifTransparent or ifIgnoreCaps);
BlitImageAndGenerateCollisionInfo(rightX - 150 - tmpsurf^.w, LAND_HEIGHT - tmpsurf^.h, tmpsurf^.w, tmpsurf);
SDL_FreeSurface(tmpsurf);
end;

// Loads Land[] from an image, allowing overriding standard collision
procedure LoadMask(mapName: shortstring);
var tmpsurf: PSDL_Surface;
    p: PLongwordArray;
    x, y, cpX, cpY: Longword;
begin
tmpsurf:= LoadDataImage(ptMapCurrent, 'mask', ifAlpha or ifTransparent or ifIgnoreCaps);
if tmpsurf = nil then
    begin
    mapName:= ExtractFileName(Pathz[ptMapCurrent]);
    tmpsurf:= LoadDataImage(ptMissionMaps, mapName + '/mask', ifAlpha or ifTransparent or ifIgnoreCaps);
    end;


if (tmpsurf <> nil) and (tmpsurf^.w <= LAND_WIDTH) and (tmpsurf^.h <= LAND_HEIGHT) and (tmpsurf^.format^.BytesPerPixel = 4) then
    begin
    disableLandBack:= true;

    cpX:= (LAND_WIDTH - tmpsurf^.w) div 2;
    cpY:= LAND_HEIGHT - tmpsurf^.h;
    if SDL_MustLock(tmpsurf) then
        SDLTry(SDL_LockSurface(tmpsurf) >= 0, true);

        p:= tmpsurf^.pixels;
        for y:= 0 to Pred(tmpsurf^.h) do
        begin
            for x:= 0 to Pred(tmpsurf^.w) do
            begin
                // this an if instead of masking colours to avoid confusing map creators
                if ((AMask and p^[x]) = 0) then 
                    Land[cpY + y, cpX + x]:= 0
                else if p^[x] = $FFFFFFFF then                  // white
                    Land[cpY + y, cpX + x]:= lfObject
                else if p^[x] = AMask then                      // black
                    begin
                    Land[cpY + y, cpX + x]:= lfBasic;
                    disableLandBack:= false
                    end
                else if p^[x] = (AMask or RMask) then           // red
                    Land[cpY + y, cpX + x]:= lfIndestructible
                else if p^[x] = (AMask or BMask) then           // blue
                    Land[cpY + y, cpX + x]:= lfObject or lfIce
                else if p^[x] = (AMask or GMask) then           // green
                    Land[cpY + y, cpX + x]:= lfObject or lfBouncy
            end;
            p:= @(p^[tmpsurf^.pitch div 4]);
        end;

    if SDL_MustLock(tmpsurf) then
        SDL_UnlockSurface(tmpsurf);
    if not disableLandBack then
        begin
        // freed in freeModule() below
        LandBackSurface:= LoadDataImage(ptCurrTheme, 'LandBackTex', ifIgnoreCaps or ifTransparent);
        if (LandBackSurface <> nil) and GrayScale then
            Surface2GrayScale(LandBackSurface)
        end;
end;
if (tmpsurf <> nil) then
    SDL_FreeSurface(tmpsurf);
tmpsurf:= nil;
end;

procedure LoadMap;
var tmpsurf: PSDL_Surface;
    s: shortstring;
    f: textfile;
    mapName: shortstring = '';
begin
WriteLnToConsole('Loading land from file...');
AddProgress;
tmpsurf:= LoadDataImage(ptMapCurrent, 'map', ifAlpha or ifTransparent or ifIgnoreCaps);
if tmpsurf = nil then
    begin
    mapName:= ExtractFileName(Pathz[ptMapCurrent]);
    tmpsurf:= LoadDataImage(ptMissionMaps, mapName + '/map', ifAlpha or ifCritical or ifTransparent or ifIgnoreCaps);
    end;
// (bare) Sanity check. Considering possible LongInt comparisons as well as just how much system memoery it would take
TryDo((tmpsurf^.w < $40000000) and (tmpsurf^.h < $40000000) and (tmpsurf^.w * tmpsurf^.h < 6*1024*1024*1024), 'Map dimensions too big!', true);

ResizeLand(tmpsurf^.w, tmpsurf^.h);

// unC0Rr - should this be passed from the GUI? I am not sure which layer does what
s:= UserPathz[ptMapCurrent] + '/map.cfg';
if not FileExists(s) then
    s:= Pathz[ptMapCurrent] + '/map.cfg';
WriteLnToConsole('Fetching map HH limit');
{$I-}
Assign(f, s);
filemode:= 0; // readonly
Reset(f);
if IOResult <> 0 then
    begin
    s:= Pathz[ptMissionMaps] + '/' + mapName + '/map.cfg';
    Assign(f, s);
    Reset(f);
    end;
Readln(f);
if not eof(f) then
    Readln(f, MaxHedgehogs);
{$I+}
if (MaxHedgehogs = 0) then
    MaxHedgehogs:= 18;

playHeight:= tmpsurf^.h;
playWidth:= tmpsurf^.w;
leftX:= (LAND_WIDTH - playWidth) div 2;
rightX:= (playWidth + ((LAND_WIDTH - playWidth) div 2)) - 1;
topY:= LAND_HEIGHT - playHeight;

TryDo(tmpsurf^.format^.BytesPerPixel = 4, 'Map should be 32bit', true);

BlitImageAndGenerateCollisionInfo(
    (LAND_WIDTH - tmpsurf^.w) div 2,
    LAND_HEIGHT - tmpsurf^.h,
    tmpsurf^.w,
    tmpsurf);
SDL_FreeSurface(tmpsurf);

LoadMask(mapname);
end;

procedure DrawBottomBorder; // broken out from other borders for doing a floor-only map, or possibly updating bottom during SD
var x, w, c: Longword;
begin
for w:= 0 to 23 do
    for x:= leftX to rightX do
        begin
        Land[Longword(cWaterLine) - 1 - w, x]:= lfIndestructible;
        if (x + w) mod 32 < 16 then
            c:= AMask
        else
            c:= AMask or RMask or GMask; // FF00FFFF

        if (cReducedQuality and rqBlurryLand) = 0 then
            LandPixels[Longword(cWaterLine) - 1 - w, x]:= c
        else
            LandPixels[(Longword(cWaterLine) - 1 - w) div 2, x div 2]:= c
        end
end;

procedure GenMap;
var x, y, w, c: Longword;
begin
    hasBorder:= false;

    LoadThemeConfig;

    // is this not needed any more? lets hope setlength sets also 0s
    //if ((GameFlags and gfForts) <> 0) or (Pathz[ptMapCurrent] <> '') then
    //    FillChar(Land,SizeOf(TCollisionArray),0);*)

    if (GameFlags and gfForts) = 0 then
        if Pathz[ptMapCurrent] <> '' then
            LoadMap
        else
            GenLandSurface
    else
        MakeFortsMap;

    AddProgress;

// check for land near top
c:= 0;
if (GameFlags and gfBorder) <> 0 then
    hasBorder:= true
else
    for y:= topY to topY + 5 do
        for x:= leftX to rightX do
            if Land[y, x] <> 0 then
                begin
                inc(c);
                if c > 1000 then // avoid accidental triggering
                    begin
                    hasBorder:= true;
                    break;
                    end;
                end;

if hasBorder then
    begin
    for y:= 0 to LAND_HEIGHT - 1 do
        for x:= 0 to LAND_WIDTH - 1 do
            if (y < topY) or (x < leftX) or (x > rightX) then
                Land[y, x]:= lfIndestructible;
    // experiment hardcoding cave
    // also try basing cave dimensions on map/template dimensions, if they exist
    for w:= 0 to 5 do // width of 3 allowed hogs to be knocked through with grenade
        begin
        for y:= topY to LAND_HEIGHT - 1 do
                begin
                Land[y, leftX + w]:= lfIndestructible;
                Land[y, rightX - w]:= lfIndestructible;
                if (y + w) mod 32 < 16 then
                    c:= AMask
                else
                    c:= AMask or RMask or GMask; // FF00FFFF

                if (cReducedQuality and rqBlurryLand) = 0 then
                    begin
                    LandPixels[y, leftX + w]:= c;
                    LandPixels[y, rightX - w]:= c;
                    end
                else
                    begin
                    LandPixels[y div 2, (leftX + w) div 2]:= c;
                    LandPixels[y div 2, (rightX - w) div 2]:= c;
                    end;
                end;

        for x:= leftX to rightX do
            begin
            Land[topY + w, x]:= lfIndestructible;
            if (x + w) mod 32 < 16 then
                c:= AMask
            else
                c:= AMask or RMask or GMask; // FF00FFFF

            if (cReducedQuality and rqBlurryLand) = 0 then
                LandPixels[topY + w, x]:= c
            else
                LandPixels[(topY + w) div 2, x div 2]:= c;
            end;
        end;
    end;

if (GameFlags and gfBottomBorder) <> 0 then
    DrawBottomBorder;

if (GameFlags and gfDisableGirders) <> 0 then
    hasGirders:= false;

if ((GameFlags and gfForts) = 0) and (Pathz[ptMapCurrent] = '') then
    AddObjects
    
else
    AddProgress();

FreeLandObjects;

if GrayScale then
    begin
    if (cReducedQuality and rqBlurryLand) = 0 then
        for x:= leftX to rightX do
            for y:= topY to LAND_HEIGHT-1 do
                begin
                w:= LandPixels[y,x];
                w:= round(((w shr RShift and $FF) * RGB_LUMINANCE_RED +
                      (w shr BShift and $FF) * RGB_LUMINANCE_GREEN +
                      (w shr GShift and $FF) * RGB_LUMINANCE_BLUE));
                if w > 255 then
                    w:= 255;
                w:= (w and $FF shl RShift) or (w and $FF shl BShift) or (w and $FF shl GShift) or (LandPixels[y,x] and AMask);
                LandPixels[y,x]:= w or (LandPixels[y, x] and AMask)
                end
    else
        for x:= leftX div 2 to rightX div 2 do
            for y:= topY div 2 to LAND_HEIGHT-1 div 2 do
                begin
                w:= LandPixels[y div 2,x div 2];
                w:= ((w shr RShift and $FF) +  (w shr BShift and $FF) + (w shr GShift and $FF)) div 3;
                if w > 255 then
                    w:= 255;
                w:= (w and $FF shl RShift) or (w and $FF shl BShift) or (w and $FF shl GShift) or (LandPixels[y div 2,x div 2] and AMask);
                LandPixels[y,x]:= w or (LandPixels[y div 2, x div 2] and AMask)
                end
    end;
end;

procedure GenPreview(out Preview: TPreview);
var rh, rw, ox, oy, x, y, xx, yy, t, bit, cbit, lh, lw: LongInt;
begin
    WriteLnToConsole('Generating preview...');
    case cMapGen of
        0: GenBlank(EdgeTemplates[SelectTemplate]);
        1: begin ResizeLand(4096,2048); GenMaze; end;
        2: GenDrawnMap;
    else
        OutError('Unknown mapgen', true);
    end;

    // strict scaling needed here since preview assumes a rectangle
    rh:= max(LAND_HEIGHT,2048);
    rw:= max(LAND_WIDTH,4096);
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
                           and (Land[yy-oy, xx-ox] <> 0) then
                            inc(t);
                if t > 8 then
                    Preview[y, x]:= Preview[y, x] or ($80 shr bit);
            end;
        end;
end;


procedure chLandCheck(var s: shortstring);
begin
    AddFileLog('CheckLandDigest: ' + s + ' digest : ' + digest);
    if digest = '' then
        digest:= s
    else
        TryDo(s = digest, 'Different maps generated, sorry', true);
end;

procedure chSendLandDigest(var s: shortstring);
var adler, i: LongInt;
begin
    adler:= 1;
    for i:= 0 to LAND_HEIGHT-1 do
        adler:= Adler32Update(adler, @Land[i,0], LAND_WIDTH);
    s:= 'M' + IntToStr(adler) + cScriptName;

    chLandCheck(s);
    SendIPCRaw(@s[0], Length(s) + 1)
end;

procedure initModule;
begin
    RegisterVariable('landcheck', @chLandCheck, false);
    RegisterVariable('sendlanddigest', @chSendLandDigest, false);

    LandBackSurface:= nil;
    digest:= '';
    LAND_WIDTH:= 0;
    LAND_HEIGHT:= 0;
(*
    if (cReducedQuality and rqBlurryLand) = 0 then
        SetLength(LandPixels, LAND_HEIGHT, LAND_WIDTH)
    else
        SetLength(LandPixels, LAND_HEIGHT div 2, LAND_WIDTH div 2);

    SetLength(Land, LAND_HEIGHT, LAND_WIDTH);
    SetLength(LandDirty, (LAND_HEIGHT div 32), (LAND_WIDTH div 32));
*)
end;

procedure freeModule;
begin
    SetLength(Land, 0, 0);
    SetLength(LandPixels, 0, 0);
    SetLength(LandDirty, 0, 0);
end;

end.
