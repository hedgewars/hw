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

unit uRenderUtils;

interface
uses SDLh, uTypes;

procedure flipSurface(Surface: PSDL_Surface; Vertical: Boolean);

procedure copyRotatedSurface(src, dest: PSDL_Surface); // this is necessary since width/height are read only in SDL
procedure copyToXY(src, dest: PSDL_Surface; destX, destY: LongInt); inline;
procedure copyToXYFromRect(src, dest: PSDL_Surface; srcX, srcY, srcW, srcH, destX, destY: LongInt);

procedure DrawSprite2Surf(sprite: TSprite; dest: PSDL_Surface; x,y: LongInt); inline;
procedure DrawSpriteFrame2Surf(sprite: TSprite; dest: PSDL_Surface; x,y: LongInt; frame: LongInt);
procedure DrawLine2Surf(dest: PSDL_Surface; x0,y0,x1,y1:LongInt; r,g,b: byte);
procedure DrawRoundRect(rect: PSDL_Rect; BorderColor, FillColor: Longword; Surface: PSDL_Surface; Clear: boolean);

function  RenderStringTex(s: ansistring; Color: Longword; font: THWFont): PTexture;
function  RenderStringTexLim(s: ansistring; Color: Longword; font: THWFont; maxLength: LongWord): PTexture;
function  RenderSpeechBubbleTex(s: ansistring; SpeechType: Longword; font: THWFont): PTexture;

function IsTooDarkToRead(TextColor: Longword): boolean; inline;

implementation
uses uVariables, uConsts, uTextures, SysUtils, uUtils, uDebug;

procedure DrawRoundRect(rect: PSDL_Rect; BorderColor, FillColor: Longword; Surface: PSDL_Surface; Clear: boolean);
var r: TSDL_Rect;
begin
    r:= rect^;
    if Clear then
        SDL_FillRect(Surface, @r, SDL_MapRGBA(Surface^.format, 0, 0, 0, 0));

    BorderColor:= SDL_MapRGB(Surface^.format, BorderColor shr 16, BorderColor shr 8, BorderColor and $FF);
    FillColor:= SDL_MapRGB(Surface^.format, FillColor shr 16, FillColor shr 8, FillColor and $FF);

    r.y:= rect^.y + cFontBorder div 2;
    r.h:= rect^.h - cFontBorder;
    SDL_FillRect(Surface, @r, BorderColor);
    r.x:= rect^.x + cFontBorder div 2;
    r.w:= rect^.w - cFontBorder;
    r.y:= rect^.y;
    r.h:= rect^.h;
    SDL_FillRect(Surface, @r, BorderColor);
    r.x:= rect^.x + cFontBorder;
    r.y:= rect^.y + cFontBorder div 2;
    r.w:= rect^.w - cFontBorder * 2;
    r.h:= rect^.h - cFontBorder;
    SDL_FillRect(Surface, @r, FillColor);
    r.x:= rect^.x + cFontBorder div 2;
    r.y:= rect^.y + cFontBorder;
    r.w:= rect^.w - cFontBorder;
    r.h:= rect^.h - cFontBorder * 2;
    SDL_FillRect(Surface, @r, FillColor);
end;
(*
function WriteInRoundRect(Surface: PSDL_Surface; X, Y: LongInt; Color: LongWord; Font: THWFont; s: ansistring): TSDL_Rect;
begin
    WriteInRoundRect:= WriteInRoundRect(Surface, X, Y, Color, Font, s, 0);
end;*)

function IsTooDarkToRead(TextColor: LongWord): boolean; inline;
var clr: TSDL_Color;
begin
    clr.r:= (TextColor shr 16) and $FF;
    clr.g:= (TextColor shr 8) and $FF;
    clr.b:= TextColor and $FF;
    IsTooDarkToRead:= not ((clr.r >= cInvertTextColorAt) or (clr.g >= cInvertTextColorAt) or (clr.b >= cInvertTextColorAt));
end;

function WriteInRoundRect(Surface: PSDL_Surface; X, Y: LongInt; Color: LongWord; Font: THWFont; s: ansistring; maxLength: LongWord): TSDL_Rect;
var w, h: Longword;
    tmpsurf: PSDL_Surface;
    finalRect, textRect: TSDL_Rect;
    clr: TSDL_Color;
begin
    TTF_SizeUTF8(Fontz[Font].Handle, PChar(s), @w, @h);
    if (maxLength > 0) and (w > maxLength * HDPIScaleFactor) then w := maxLength * HDPIScaleFactor;
    finalRect.x:= X;
    finalRect.y:= Y;
    finalRect.w:= w + cFontBorder * 2 + cFontPadding * 2;
    finalRect.h:= h + cFontBorder * 2;
    textRect.x:= X;
    textRect.y:= Y;
    textRect.w:= w;
    textRect.h:= h;
    clr.r:= (Color shr 16) and $FF;
    clr.g:= (Color shr 8) and $FF;
    clr.b:= Color and $FF;
    if (not IsTooDarkToRead(Color)) then
        DrawRoundRect(@finalRect, cWhiteColor, cNearBlackColor, Surface, true)
    else
        DrawRoundRect(@finalRect, cNearBlackColor, cWhiteColor, Surface, true);
    tmpsurf:= TTF_RenderUTF8_Blended(Fontz[Font].Handle, PChar(s), clr);
    finalRect.x:= X + cFontBorder + cFontPadding;
    finalRect.y:= Y + cFontBorder;
    if SDLCheck(tmpsurf <> nil, 'TTF_RenderUTF8_Blended', true) then
        exit;
    SDL_UpperBlit(tmpsurf, @textRect, Surface, @finalRect);
    SDL_FreeSurface(tmpsurf);
    finalRect.x:= X;
    finalRect.y:= Y;
    finalRect.w:= w + cFontBorder * 2 + cFontPadding * 2;
    finalRect.h:= h + cFontBorder * 2;
    WriteInRoundRect:= finalRect;
end;

procedure flipSurface(Surface: PSDL_Surface; Vertical: Boolean);
var y, x, i, j: LongInt;
    tmpPixel: Longword;
    pixels: PLongWordArray;
begin
    if checkFails(Surface^.format^.BytesPerPixel = 4, 'flipSurface failed, expecting 32 bit surface', true) then
        exit;
    SDL_LockSurface(Surface);
    pixels:= Surface^.pixels;
    if Vertical then
    for y := 0 to (Surface^.h div 2) - 1 do
        for x := 0 to Surface^.w - 1 do
            begin
            i:= y * Surface^.w + x;
            j:= (Surface^.h - y - 1) * Surface^.w + x;
            tmpPixel:= pixels^[i];
            pixels^[i]:= pixels^[j];
            pixels^[j]:= tmpPixel;
            end
    else
    for x := 0 to (Surface^.w div 2) - 1 do
        for y := 0 to Surface^.h - 1 do
            begin
            i:= y*Surface^.w + x;
            j:= y*Surface^.w + (Surface^.w - x - 1);
            tmpPixel:= pixels^[i];
            pixels^[i]:= pixels^[j];
            pixels^[j]:= tmpPixel;
            end;
    SDL_UnlockSurface(Surface);
end;

procedure copyToXY(src, dest: PSDL_Surface; destX, destY: LongInt); inline;
begin
    // copy from complete src
    copyToXYFromRect(src, dest, 0, 0, src^.w, src^.h, destX, destY);
end;

procedure copyToXYFromRect(src, dest: PSDL_Surface; srcX, srcY, srcW, srcH, destX, destY: LongInt);
var spi, dpi, iX, iY, dX, dY, lX, lY, aT: LongInt;
    srcPixels, destPixels: PLongWordArray;
    rD, gD, bD, aD, rT, gT, bT: Byte;
begin
    SDL_LockSurface(src);
    SDL_LockSurface(dest);

    srcPixels:= src^.pixels;
    destPixels:= dest^.pixels;

    // what's the offset between src and dest coords?
    dX:= destX - srcX;
    dY:= destY - srcY;

    // let's figure out where the rectangle we can actually copy ends
    lX:= min(srcX + srcW, src^.w) - 1;
    if lX + dx >= dest^.w then lX:= dest^.w - dx - 1;
    lY:= min(srcY + srcH, src^.h) - 1;
    if lY + dy >= dest^.h then lY:= dest^.h - dy - 1;

    for iX:= srcX to lX do
    for iY:= srcY to lY do
        begin
        // src pixel index
        spi:= iY * src^.w  + iX;
        // dest pixel index
        dpi:= (iY + dY) * dest^.w + (iX + dX);

        // get src alpha (and set it as target alpha for now)
        aT:= (srcPixels^[spi] and AMask) shr AShift;

        // src pixel opaque?
        if aT = 255 then
            begin
            // just copy full pixel
            destPixels^[dpi]:= srcPixels^[spi];
            continue;
            end;

        // get dst alpha (without shift for now)
        aD:= (destPixels^[dpi] and AMask) shr AShift;

        // dest completely transparent?
        if aD = 0 then
            begin
            // just copy src pixel
            destPixels^[dpi]:= srcPixels^[spi];
            continue;
            end;

        // looks like some blending is necessary

        // set color of target RGB to src for now
        SDL_GetRGB(srcPixels^[spi],  src^.format,  @rT, @gT, @bT);
        SDL_GetRGB(destPixels^[dpi], dest^.format, @rD, @gD, @bD);
        // note: this is not how to correctly blend RGB, just sayin' (R,G,B are not linear...)
        rT:= (rD * (255 - aT) + rT * aT) div 255;
        gT:= (gD * (255 - aT) + gT * aT) div 255;
        bT:= (bD * (255 - aT) + bT * aT) div 255;
        aT:= aD + ((255 - LongInt(aD)) * aT div 255);

        destPixels^[dpi]:= SDL_MapRGBA(dest^.format, rT, gT, bT, Byte(aT));

        end;

    SDL_UnlockSurface(src);
    SDL_UnlockSurface(dest);
end;

procedure DrawSprite2Surf(sprite: TSprite; dest: PSDL_Surface; x,y: LongInt); inline;
begin
   DrawSpriteFrame2Surf(sprite, dest, x, y, 0);
end;

procedure DrawSpriteFrame2Surf(sprite: TSprite; dest: PSDL_Surface; x,y,frame: LongInt);
var numFramesFirstCol, row, col: LongInt;
begin
    numFramesFirstCol:= SpritesData[sprite].imageHeight div SpritesData[sprite].Height;
    row:= Frame mod numFramesFirstCol;
    col:= Frame div numFramesFirstCol;

    copyToXYFromRect(SpritesData[sprite].Surface, dest,
             col*SpritesData[sprite].Width,
             row*SpritesData[sprite].Height,
             SpritesData[sprite].Width,
             spritesData[sprite].Height,
             x,y);
end;

procedure DrawLine2Surf(dest: PSDL_Surface; x0, y0,x1,y1: LongInt; r,g,b: byte);
var
    dx,dy,err,e2,sx,sy: LongInt;
    yMax: LongInt;
    destPixels: PLongwordArray;
begin
    //max:= (dest^.pitch div 4) * dest^.h;
    yMax:= dest^.pitch div 4;

    SDL_LockSurface(dest);

    destPixels:= dest^.pixels;

    dx:= abs(x1-x0);
    dy:= abs(y1-y0);
    if x0 < x1 then sx:= 1 else sx:= -1;
    if y0 < y1 then sy:= 1 else sy:= -1;
    err:= dx-dy;

    while(true) do
        begin
        destPixels^[(y0 * yMax) + x0]:= SDL_MapRGB(dest^.format, r,g,b); //But will it blend? no

        if (x0 = x1) and (y0 = y1) then break;

        e2:= 2*err;
        if e2 > -dy then
            begin
            err:= err - dy;
            x0 := x0 + sx;
            end;

        if e2 < dx then
            begin
            err:= err + dx;
            y0:=y0+sy
            end;
        end;
    SDL_UnlockSurface(dest);
end;

procedure copyRotatedSurface(src, dest: PSDL_Surface); // this is necessary since width/height are read only in SDL, apparently
var y, x, i, j: LongInt;
    srcPixels, destPixels: PLongWordArray;
begin
    checkFails(src^.format^.BytesPerPixel = 4, 'rotateSurface failed, expecting 32 bit surface', true);
    checkFails(dest^.format^.BytesPerPixel = 4, 'rotateSurface failed, expecting 32 bit surface', true);
    if not allOK then exit;

    SDL_LockSurface(src);
    SDL_LockSurface(dest);

    srcPixels:= src^.pixels;
    destPixels:= dest^.pixels;

    j:= 0;
    for x := 0 to src^.w - 1 do
        for y := 0 to src^.h - 1 do
            begin
            i:= (src^.h - 1 - y) * (src^.pitch div 4) + x;
            destPixels^[j]:= srcPixels^[i];
            inc(j)
            end;

    SDL_UnlockSurface(src);
    SDL_UnlockSurface(dest);

end;

function RenderStringTex(s: ansistring; Color: Longword; font: THWFont): PTexture;
begin
    RenderStringTex:= RenderStringTexLim(s, Color, font, 0);
end;

function RenderStringTexLim(s: ansistring; Color: Longword; font: THWFont; maxLength: LongWord): PTexture;
var w, h: Longword;
    finalSurface: PSDL_Surface;
begin
    if cOnlyStats then
        begin
        RenderStringTexLim:= nil;
        end
    else
        begin
        if length(s) = 0 then s:= _S' ';
        font:= CheckCJKFont(s, font);
        w:= 0; h:= 0; // avoid compiler hints
        TTF_SizeUTF8(Fontz[font].Handle, PChar(s), @w, @h);
        if (maxLength > 0) and (w > maxLength * HDPIScaleFactor) then w := maxLength * HDPIScaleFactor;

        finalSurface:= SDL_CreateRGBSurface(SDL_SWSURFACE, w + cFontBorder*2 + cFontPadding*2, h + cFontBorder * 2,
                32, RMask, GMask, BMask, AMask);

        if checkFails(finalSurface <> nil, 'RenderString: fail to create surface', true) then
            exit(nil);

        WriteInRoundRect(finalSurface, 0, 0, Color, font, s, maxLength);

        checkFails(SDL_SetColorKey(finalSurface, SDL_TRUE, 0) = 0, errmsgTransparentSet, false);

        RenderStringTexLim:= Surface2Tex(finalSurface, false);

        SDL_FreeSurface(finalSurface);
        end;
end;

function GetNextSpeechLine(s: ansistring; ldelim: char; var startFrom: LongInt; out substr: ansistring): boolean;
var p, l, m, r: Integer;
    newl, skip: boolean;
    c         : char;
begin
    m:= Length(s);

    substr:= '';

    SetLengthA(substr, m);

    // number of chars read
    r:= 0;

    // number of chars to be written
    l:= 0;

    newl:= true;

    for p:= max(1, startFrom) to m do
        begin

        inc(r);
        // read char from source string
        c:= s[p];

        // strip empty lines, spaces and newlines on beginnings of line
        skip:= ((newl or (p = m)) and ((c = ' ') or (c = ldelim)));

        if (not skip) then
            begin
            newl:= (c = ldelim);
            // stop if we went past the end of the line
            if newl then
                break;

            // copy current char to output substring
            inc(l);
            substr[l]:= c;
            end;

        end;

    inc(startFrom, r);

    SetLengthA(substr, l);

    GetNextSpeechLine:= (l > 0);
end;

function RenderSpeechBubbleTex(s: ansistring; SpeechType: Longword; font: THWFont): PTexture;
var textWidth, textHeight, x, y, w, h, i, j, pos, line, numLines, edgeWidth, edgeHeight, cornerWidth, cornerHeight: LongInt;
    finalSurface, tmpsurf, rotatedEdge: PSDL_Surface;
    rect: TSDL_Rect;
    {$IFNDEF PAS2C}
    chars: set of char = [#9,' ',';',':','?','!',','];
    {$ENDIF}
    substr: ansistring;
    edge, corner, tail: TSPrite;
begin
    if cOnlyStats then exit(nil);

    case SpeechType of
        1: begin
            edge:= sprSpeechEdge;
            corner:= sprSpeechCorner;
            tail:= sprSpeechTail;
            end;
        2: begin
            edge:= sprThoughtEdge;
            corner:= sprThoughtCorner;
            tail:= sprThoughtTail;
            end;
        3: begin
            edge:= sprShoutEdge;
            corner:= sprShoutCorner;
            tail:= sprShoutTail;
            end
        else
            exit(nil)
        end;
    edgeHeight:= SpritesData[edge].Height;
    edgeWidth:= SpritesData[edge].Width;
    cornerWidth:= SpritesData[corner].Width;
    cornerHeight:= SpritesData[corner].Height;
    // This one screws up WrapText
    //s:= 'This is the song that never ends.  ''cause it goes on and on my friends. Some people, started singing it not knowing what it was. And they''ll just go on singing it forever just because... This is the song that never ends...';
    // This one does not
    //s:= 'This is the song that never ends.  cause it goes on and on my friends. Some people, started singing it not knowing what it was. And they will go on singing it forever just because... This is the song that never ends... ';

    numLines:= 0;

    if length(s) = 0 then
        s:= '...';
    font:= CheckCJKFont(s, font);
    w:= 0; h:= 0; // avoid compiler hints
    TTF_SizeUTF8(Fontz[font].Handle, PChar(s), @w, @h);
    if w<8 then
        w:= 8;
    j:= 0;
    if (length(s) > 20) then
        begin
        w:= 0;
        i:= round(Sqrt(length(s)) * 2);
        {$IFNDEF PAS2C}
        s:= WrapText(s, #1, chars, i);
        {$ENDIF}
        pos:= 1; line:= 0;
    // Find the longest line for the purposes of centring the text.  Font dependant.
        while GetNextSpeechLine(s, #1, pos, substr) do
            begin
            inc(numLines);
            i:= 0; j:= 0;
            TTF_SizeUTF8(Fontz[font].Handle, PChar(substr), @i, @j);
            if i > w then
                w:= i;
            end;
        end
    else numLines := 1;

    if numLines < 1 then
        begin
        s:= '...';
        numLines:= 1;
        end;

    textWidth:=((w-(cornerWidth-edgeWidth)*2) div edgeWidth)*edgeWidth+edgeWidth;
    textHeight:=(((numlines * h + 2)-((cornerHeight-edgeWidth)*2)) div edgeWidth)*edgeWidth;

    textHeight:=max(textHeight,edgeWidth);
    //textWidth:=max(textWidth,SpritesData[tail].Width);
    rect.x:= 0;
    rect.y:= 0;
    rect.w:= textWidth + (cornerWidth * 2);
    rect.h:= textHeight + cornerHeight*2 - edgeHeight + SpritesData[tail].Height;
    //s:= inttostr(w) + ' ' + inttostr(numlines) + ' ' + inttostr(rect.x) + ' '+inttostr(rect.y) + ' ' + inttostr(rect.w) + ' ' + inttostr(rect.h);

    finalSurface:= SDL_CreateRGBSurface(SDL_SWSURFACE, rect.w, rect.h, 32, RMask, GMask, BMask, AMask);

    if checkFails(finalSurface <> nil, 'RenderString: fail to create surface', true) then
        exit(nil);

    //////////////////////////////// CORNERS ///////////////////////////////
    copyToXY(SpritesData[corner].Surface, finalSurface, 0, 0); /////////////////// NW

    flipSurface(SpritesData[corner].Surface, true); // store all 4 versions in memory to avoid repeated flips?
    x:= 0;
    y:= textHeight + cornerHeight -1;
    copyToXY(SpritesData[corner].Surface, finalSurface, x, y); /////////////////// SW

    flipSurface(SpritesData[corner].Surface, false);
    x:= rect.w-cornerWidth-1;
    y:= textHeight + cornerHeight -1;
    copyToXY(SpritesData[corner].Surface, finalSurface, x, y); /////////////////// SE

    flipSurface(SpritesData[corner].Surface, true);
    x:= rect.w-cornerWidth-1;
    y:= 0;
    copyToXY(SpritesData[corner].Surface, finalSurface, x, y); /////////////////// NE
    flipSurface(SpritesData[corner].Surface, false); // restore original position
    //////////////////////////////// END CORNERS ///////////////////////////////

    //////////////////////////////// EDGES //////////////////////////////////////
    x:= cornerWidth;
    y:= 0;
    while x < rect.w-cornerWidth-1 do
        begin
        copyToXY(SpritesData[edge].Surface, finalSurface, x, y); ///////////////// top edge
        inc(x,edgeWidth);
        end;
    flipSurface(SpritesData[edge].Surface, true);
    x:= cornerWidth;
    y:= textHeight + cornerHeight*2 - edgeHeight-1;
    while x < rect.w-cornerWidth-1 do
        begin
        copyToXY(SpritesData[edge].Surface, finalSurface, x, y); ///////////////// bottom edge
        inc(x,edgeWidth);
        end;
    flipSurface(SpritesData[edge].Surface, true); // restore original position

    rotatedEdge:= SDL_CreateRGBSurface(SDL_SWSURFACE, edgeHeight, edgeWidth, 32, RMask, GMask, BMask, AMask);
    x:= rect.w - edgeHeight - 1;
    y:= cornerHeight;
    //// initially was going to rotate in place, but the SDL spec claims width/height are read only
    copyRotatedSurface(SpritesData[edge].Surface,rotatedEdge);
    while y < textHeight + cornerHeight do
        begin
        copyToXY(rotatedEdge, finalSurface, x, y);
        inc(y,edgeWidth);
        end;
    flipSurface(rotatedEdge, false); // restore original position
    x:= 0;
    y:= cornerHeight;
    while y < textHeight + cornerHeight do
        begin
        copyToXY(rotatedEdge, finalSurface, x, y);
        inc(y,edgeWidth);
        end;
    //////////////////////////////// END EDGES //////////////////////////////////////

    x:= cornerWidth;
    y:= textHeight + cornerHeight * 2 - edgeHeight - 1;
    copyToXY(SpritesData[tail].Surface, finalSurface, x, y);

    rect.x:= edgeHeight;
    rect.y:= edgeHeight;
    rect.w:= rect.w - edgeHeight * 2;
    rect.h:= textHeight + cornerHeight * 2 - edgeHeight * 2;
    i:= rect.w;
    j:= rect.h;
    SDL_FillRect(finalSurface, @rect, SDL_MapRGB(finalSurface^.format, cWhiteColor shr 16, cWhiteColor shr 8, cWhiteColor and $FF));

    pos:= 1; line:= 0;
    while GetNextSpeechLine(s, #1, pos, substr) do
        begin
        tmpsurf:= TTF_RenderUTF8_Blended(Fontz[Font].Handle, PChar(substr), cNearBlackColorChannels);
        rect.x:= edgeHeight + 1 + ((i - w) div 2);
        // trying to more evenly position the text, vertically
        rect.y:= edgeHeight + ((j-(numLines*h)) div 2) + line * h;
        if not SDLCheck(tmpsurf <> nil, 'TTF_RenderUTF8_Blended', true) then
        begin
            SDL_UpperBlit(tmpsurf, nil, finalSurface, @rect);
            SDL_FreeSurface(tmpsurf);
        end;
        inc(line);
        end;

    RenderSpeechBubbleTex:= Surface2Tex(finalSurface, true);

    SDL_FreeSurface(rotatedEdge);
    SDL_FreeSurface(finalSurface);

end;

end.
