{$INCLUDE "options.inc"}
unit uRenderUtils;

interface
uses SDLh, uTypes;

procedure flipSurface(Surface: PSDL_Surface; Vertical: Boolean);
procedure copyRotatedSurface(src, dest: PSDL_Surface); // this is necessary since width/height are read only in SDL
procedure copyToXY(src, dest: PSDL_Surface; destX, destY: LongInt);
function  RenderStringTex(s: ansistring; Color: Longword; font: THWFont): PTexture;
function  RenderSpeechBubbleTex(s: ansistring; SpeechType: Longword; font: THWFont): PTexture;
procedure DrawRoundRect(rect: PSDL_Rect; BorderColor, FillColor: Longword; Surface: PSDL_Surface; Clear: boolean);

implementation
uses uUtils, uVariables, uConsts, uTextures, sysutils, uDebug;

procedure DrawRoundRect(rect: PSDL_Rect; BorderColor, FillColor: Longword; Surface: PSDL_Surface; Clear: boolean);
var r: TSDL_Rect;
begin
    r:= rect^;
    if Clear then SDL_FillRect(Surface, @r, 0);

    BorderColor:= SDL_MapRGB(Surface^.format, BorderColor shr 16, BorderColor shr 8, BorderColor and $FF);
    FillColor:= SDL_MapRGB(Surface^.format, FillColor shr 16, FillColor shr 8, FillColor and $FF);

    r.y:= rect^.y + 1;
    r.h:= rect^.h - 2;
    SDL_FillRect(Surface, @r, BorderColor);
    r.x:= rect^.x + 1;
    r.w:= rect^.w - 2;
    r.y:= rect^.y;
    r.h:= rect^.h;
    SDL_FillRect(Surface, @r, BorderColor);
    r.x:= rect^.x + 2;
    r.y:= rect^.y + 1;
    r.w:= rect^.w - 4;
    r.h:= rect^.h - 2;
    SDL_FillRect(Surface, @r, FillColor);
    r.x:= rect^.x + 1;
    r.y:= rect^.y + 2;
    r.w:= rect^.w - 2;
    r.h:= rect^.h - 4;
    SDL_FillRect(Surface, @r, FillColor)
end;

function WriteInRoundRect(Surface: PSDL_Surface; X, Y: LongInt; Color: LongWord; Font: THWFont; s: ansistring): TSDL_Rect;
var w, h: LongInt;
    tmpsurf: PSDL_Surface;
    clr: TSDL_Color;
    finalRect: TSDL_Rect;
begin
    TTF_SizeUTF8(Fontz[Font].Handle, Str2PChar(s), w, h);
    finalRect.x:= X;
    finalRect.y:= Y;
    finalRect.w:= w + FontBorder * 2 + 4;
    finalRect.h:= h + FontBorder * 2;
    DrawRoundRect(@finalRect, cWhiteColor, endian(cNearBlackColorChannels.value), Surface, true);
    clr.r:= (Color shr 16) and $FF;
    clr.g:= (Color shr 8) and $FF;
    clr.b:= Color and $FF;
    tmpsurf:= TTF_RenderUTF8_Blended(Fontz[Font].Handle, Str2PChar(s), clr);
    finalRect.x:= X + FontBorder + 2;
    finalRect.y:= Y + FontBorder;
    SDLTry(tmpsurf <> nil, true);
    SDL_UpperBlit(tmpsurf, nil, Surface, @finalRect);
    SDL_FreeSurface(tmpsurf);
    finalRect.x:= X;
    finalRect.y:= Y;
    finalRect.w:= w + FontBorder * 2 + 4;
    finalRect.h:= h + FontBorder * 2;
    WriteInRoundRect:= finalRect;
end;

procedure flipSurface(Surface: PSDL_Surface; Vertical: Boolean);
var y, x, i, j: LongInt;
    tmpPixel: Longword;
    pixels: PLongWordArray;
begin
    TryDo(Surface^.format^.BytesPerPixel = 4, 'flipSurface failed, expecting 32 bit surface', true);
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
        for y := 0 to Surface^.h -1 do
            begin
            i:= y*Surface^.w + x;
            j:= y*Surface^.w + (Surface^.w - x - 1);
            tmpPixel:= pixels^[i];
            pixels^[i]:= pixels^[j];
            pixels^[j]:= tmpPixel;
            end;
end;

procedure copyToXY(src, dest: PSDL_Surface; destX, destY: LongInt);
var srcX, srcY, i, j, maxDest: LongInt;
    srcPixels, destPixels: PLongWordArray;
    r0, g0, b0, a0, r1, g1, b1, a1: Byte;
begin
    maxDest:= (dest^.pitch div 4) * dest^.h;
    srcPixels:= src^.pixels;
    destPixels:= dest^.pixels;

    for srcX:= 0 to src^.w - 1 do
    for srcY:= 0 to src^.h - 1 do
        begin
        i:= (destY + srcY) * (dest^.pitch div 4) + destX + srcX;
        j:= srcY * (src^.pitch div 4) + srcX;
        if (i < maxDest) and (srcPixels^[j] and AMask <> 0) then
            begin
            SDL_GetRGBA(destPixels^[i], dest^.format, @r0, @g0, @b0, @a0);
            SDL_GetRGBA(srcPixels^[j], src^.format, @r1, @g1, @b1, @a1);
            r0:= (r0 * (255 - LongInt(a1)) + r1 * LongInt(a1)) div 255;
            g0:= (g0 * (255 - LongInt(a1)) + g1 * LongInt(a1)) div 255;
            b0:= (b0 * (255 - LongInt(a1)) + b1 * LongInt(a1)) div 255;
            a0:= (a0 * (255 - LongInt(a1)) + a1 * LongInt(a1)) div 255;
            destPixels^[i]:= SDL_MapRGBA(dest^.format, r0, g0, b0, a0);
            end;
        end;
end;

procedure copyRotatedSurface(src, dest: PSDL_Surface); // this is necessary since width/height are read only in SDL, apparently
var y, x, i, j: LongInt;
    srcPixels, destPixels: PLongWordArray;
begin
    TryDo(src^.format^.BytesPerPixel = 4, 'rotateSurface failed, expecting 32 bit surface', true);
    TryDo(dest^.format^.BytesPerPixel = 4, 'rotateSurface failed, expecting 32 bit surface', true);

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
end;

function  RenderStringTex(s: ansistring; Color: Longword; font: THWFont): PTexture;
var w, h: LongInt;
    finalSurface: PSDL_Surface;
begin
    if length(s) = 0 then s:= ' ';
    font:= CheckCJKFont(s, font);
    w:= 0; h:= 0; // avoid compiler hints
    TTF_SizeUTF8(Fontz[font].Handle, Str2PChar(s), w, h);

    finalSurface:= SDL_CreateRGBSurface(SDL_SWSURFACE, w + FontBorder * 2 + 4, h + FontBorder * 2,
            32, RMask, GMask, BMask, AMask);

    TryDo(finalSurface <> nil, 'RenderString: fail to create surface', true);

    WriteInRoundRect(finalSurface, 0, 0, Color, font, s);

    TryDo(SDL_SetColorKey(finalSurface, SDL_SRCCOLORKEY, 0) = 0, errmsgTransparentSet, true);

    RenderStringTex:= Surface2Tex(finalSurface, false);

    SDL_FreeSurface(finalSurface);
end;


function RenderSpeechBubbleTex(s: ansistring; SpeechType: Longword; font: THWFont): PTexture;
var textWidth, textHeight, x, y, w, h, i, j, pos, prevpos, line, numLines, edgeWidth, edgeHeight, cornerWidth, cornerHeight: LongInt;
    finalSurface, tmpsurf, rotatedEdge: PSDL_Surface;
    rect: TSDL_Rect;
    chars: set of char = [#9,' ',';',':','?','!',','];
    substr: shortstring;
    edge, corner, tail: TSPrite;
begin
    case SpeechType of
        1: begin;
        edge:= sprSpeechEdge;
        corner:= sprSpeechCorner;
        tail:= sprSpeechTail;
        end;
        2: begin;
        edge:= sprThoughtEdge;
        corner:= sprThoughtCorner;
        tail:= sprThoughtTail;
        end;
        3: begin;
        edge:= sprShoutEdge;
        corner:= sprShoutCorner;
        tail:= sprShoutTail;
        end;
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

    if length(s) = 0 then s:= '...';
    font:= CheckCJKFont(s, font);
    w:= 0; h:= 0; // avoid compiler hints
    TTF_SizeUTF8(Fontz[font].Handle, Str2PChar(s), w, h);
    if w<8 then w:= 8;
    j:= 0;
    if (length(s) > 20) then
        begin
        w:= 0;
        i:= round(Sqrt(length(s)) * 2);
        s:= WrapText(s, #1, chars, i);
        pos:= 1; prevpos:= 0; line:= 0;
    // Find the longest line for the purposes of centring the text.  Font dependant.
        while pos <= length(s) do
            begin
            if (s[pos] = #1) or (pos = length(s)) then
                begin
                inc(numlines);
                if s[pos] <> #1 then inc(pos);
                while s[prevpos+1] = ' ' do inc(prevpos);
                substr:= copy(s, prevpos+1, pos-prevpos-1);
                i:= 0; j:= 0;
                TTF_SizeUTF8(Fontz[font].Handle, Str2PChar(substr), i, j);
                if i > w then w:= i;
                prevpos:= pos;
                end;
            inc(pos);
            end;
        end
    else numLines := 1;

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

    TryDo(finalSurface <> nil, 'RenderString: fail to create surface', true);

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
    SDL_FillRect(finalSurface, @rect, cWhiteColor);

    pos:= 1; prevpos:= 0; line:= 0;
    while pos <= length(s) do
        begin
        if (s[pos] = #1) or (pos = length(s)) then
            begin
            if s[pos] <> #1 then inc(pos);
            while s[prevpos+1] = ' 'do inc(prevpos);
            substr:= copy(s, prevpos+1, pos-prevpos-1);
            if Length(substr) <> 0 then
            begin
            tmpsurf:= TTF_RenderUTF8_Blended(Fontz[Font].Handle, Str2PChar(substr), cNearBlackColorChannels);
            rect.x:= edgeHeight + 1 + ((i - w) div 2);
            // trying to more evenly position the text, vertically
            rect.y:= edgeHeight + ((j-(numLines*h)) div 2) + line * h;
            SDLTry(tmpsurf <> nil, true);
            SDL_UpperBlit(tmpsurf, nil, finalSurface, @rect);
            SDL_FreeSurface(tmpsurf);
            inc(line);
            prevpos:= pos;
            end;
            end;
        inc(pos);
        end;

    RenderSpeechBubbleTex:= Surface2Tex(finalSurface, true);

    SDL_FreeSurface(rotatedEdge);
    SDL_FreeSurface(finalSurface);
end;

end.
