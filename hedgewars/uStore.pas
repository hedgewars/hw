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
{$IF GLunit = GL}{$DEFINE GLunit:=GL,GLext}{$ENDIF}

unit uStore;
interface
uses sysutils, uConsts, SDLh, GLunit, uTypes, uLandTexture, uCaptions, uChat;

procedure initModule;
procedure freeModule;

procedure StoreLoad(reload: boolean);
procedure StoreRelease(reload: boolean);
procedure RenderHealth(var Hedgehog: THedgehog);
procedure AddProgress;
procedure FinishProgress;
function  LoadImage(const filename: shortstring; imageFlags: LongInt): PSDL_Surface;
procedure LoadHedgehogHat(HHGear: PGear; newHat: shortstring);
procedure SetupOpenGL;
procedure SetScale(f: GLfloat);
function  RenderHelpWindow(caption, subcaption, description, extra: ansistring; extracolor: LongInt; iconsurf: PSDL_Surface; iconrect: PSDL_Rect): PTexture;
procedure RenderWeaponTooltip(atype: TAmmoType);
procedure ShowWeaponTooltip(x, y: LongInt);
procedure FreeWeaponTooltip;
procedure MakeCrossHairs;

implementation
uses uMisc, uConsole, uMobile, uVariables, uUtils, uTextures, uRender, uRenderUtils, uCommands, uDebug, uWorld;

//type TGPUVendor = (gvUnknown, gvNVIDIA, gvATI, gvIntel, gvApple);

var MaxTextureSize: LongInt;
//    cGPUVendor: TGPUVendor;

function WriteInRect(Surface: PSDL_Surface; X, Y: LongInt; Color: LongWord; Font: THWFont; s: ansistring): TSDL_Rect;
var w, h: LongInt;
    tmpsurf: PSDL_Surface;
    clr: TSDL_Color;
    finalRect: TSDL_Rect;
begin
w:= 0; h:= 0; // avoid compiler hints
TTF_SizeUTF8(Fontz[Font].Handle, Str2PChar(s), @w, @h);
finalRect.x:= X + cFontBorder + 2;
finalRect.y:= Y + cFontBorder;
finalRect.w:= w + cFontBorder * 2 + 4;
finalRect.h:= h + cFontBorder * 2;
clr.r:= Color shr 16;
clr.g:= (Color shr 8) and $FF;
clr.b:= Color and $FF;
tmpsurf:= TTF_RenderUTF8_Blended(Fontz[Font].Handle, Str2PChar(s), clr);
tmpsurf:= doSurfaceConversion(tmpsurf);
SDLTry(tmpsurf <> nil, true);
SDL_UpperBlit(tmpsurf, nil, Surface, @finalRect);
SDL_FreeSurface(tmpsurf);
finalRect.x:= X;
finalRect.y:= Y;
finalRect.w:= w + cFontBorder * 2 + 4;
finalRect.h:= h + cFontBorder * 2;
WriteInRect:= finalRect
end;

procedure MakeCrossHairs;
var t: LongInt;
    tmpsurf, texsurf: PSDL_Surface;
    Color, i: Longword;
    s: shortstring;
begin
s:= UserPathz[ptGraphics] + '/' + cCHFileName;
if not FileExists(s+'.png') then s:= Pathz[ptGraphics] + '/' + cCHFileName;
tmpsurf:= LoadImage(s, ifAlpha or ifCritical);

for t:= 0 to Pred(TeamsCount) do
    with TeamsArray[t]^ do
    begin
    texsurf:= SDL_CreateRGBSurface(SDL_SWSURFACE, tmpsurf^.w, tmpsurf^.h, 32, RMask, GMask, BMask, AMask);
    TryDo(texsurf <> nil, errmsgCreateSurface, true);

    Color:= Clan^.Color;
    Color:= SDL_MapRGB(texsurf^.format, Color shr 16, Color shr 8, Color and $FF);
    SDL_FillRect(texsurf, nil, Color);

    SDL_UpperBlit(tmpsurf, nil, texsurf, nil);

    TryDo(tmpsurf^.format^.BytesPerPixel = 4, 'Ooops', true);

    if SDL_MustLock(texsurf) then
        SDLTry(SDL_LockSurface(texsurf) >= 0, true);

    // make black pixel be alpha-transparent
    for i:= 0 to texsurf^.w * texsurf^.h - 1 do
        if PLongwordArray(texsurf^.pixels)^[i] = AMask then
            PLongwordArray(texsurf^.pixels)^[i]:= (RMask or GMask or BMask) and Color;

    if SDL_MustLock(texsurf) then
        SDL_UnlockSurface(texsurf);

    FreeTexture(CrosshairTex);
    CrosshairTex:= Surface2Tex(texsurf, false);
    SDL_FreeSurface(texsurf)
    end;

SDL_FreeSurface(tmpsurf)
end;


procedure WriteNames(Font: THWFont);
var t: LongInt;
    i: LongInt;
    r, rr: TSDL_Rect;
    drY: LongInt;
    texsurf, flagsurf, iconsurf: PSDL_Surface;
begin
r.x:= 0;
r.y:= 0;
drY:= - 4;
for t:= 0 to Pred(TeamsCount) do
    with TeamsArray[t]^ do
        begin
        NameTagTex:= RenderStringTexLim(TeamName, Clan^.Color, Font, cTeamHealthWidth);

        r.w:= cTeamHealthWidth + 5;
        r.h:= NameTagTex^.h;

        texsurf:= SDL_CreateRGBSurface(SDL_SWSURFACE, r.w, r.h, 32, RMask, GMask, BMask, AMask);
        TryDo(texsurf <> nil, errmsgCreateSurface, true);
        TryDo(SDL_SetColorKey(texsurf, SDL_SRCCOLORKEY, 0) = 0, errmsgTransparentSet, true);

        DrawRoundRect(@r, cWhiteColor, cNearBlackColorChannels.value, texsurf, true);
        rr:= r;
        inc(rr.x, 2); dec(rr.w, 4); inc(rr.y, 2); dec(rr.h, 4);
        DrawRoundRect(@rr, Clan^.Color, Clan^.Color, texsurf, false);
        HealthTex:= Surface2Tex(texsurf, false);
        SDL_FreeSurface(texsurf);

        r.x:= 0;
        r.y:= 0;
        r.w:= 32;
        r.h:= 32;
        texsurf:= SDL_CreateRGBSurface(SDL_SWSURFACE, r.w, r.h, 32, RMask, GMask, BMask, AMask);
        TryDo(texsurf <> nil, errmsgCreateSurface, true);
        TryDo(SDL_SetColorKey(texsurf, SDL_SRCCOLORKEY, 0) = 0, errmsgTransparentSet, true);

        r.w:= 26;
        r.h:= 19;

        DrawRoundRect(@r, cWhiteColor, cNearBlackColor, texsurf, true);

        // overwrite flag for cpu teams and keep players from using it
        if (Hedgehogs[0].Gear <> nil) and (Hedgehogs[0].BotLevel > 0) then
            if Flag = 'hedgewars' then
                Flag:= 'cpu'
        else if Flag = 'cpu' then
            Flag:= 'hedgewars';

        flagsurf:= LoadImage(UserPathz[ptFlags] + '/' + Flag, ifNone);
        if flagsurf = nil then
            flagsurf:= LoadImage(Pathz[ptFlags] + '/' + Flag, ifNone);
        if flagsurf = nil then
            flagsurf:= LoadImage(UserPathz[ptFlags] + '/hedgewars', ifNone);
        if flagsurf = nil then
            flagsurf:= LoadImage(Pathz[ptFlags] + '/hedgewars', ifNone);
        TryDo(flagsurf <> nil, 'Failed to load flag "' + Flag + '" as well as the default flag', true);
        copyToXY(flagsurf, texsurf, 2, 2);
        SDL_FreeSurface(flagsurf);
        flagsurf:= nil;

        // restore black border pixels inside the flag
        PLongwordArray(texsurf^.pixels)^[32 * 2 +  2]:= cNearBlackColor;
        PLongwordArray(texsurf^.pixels)^[32 * 2 + 23]:= cNearBlackColor;
        PLongwordArray(texsurf^.pixels)^[32 * 16 +  2]:= cNearBlackColor;
        PLongwordArray(texsurf^.pixels)^[32 * 16 + 23]:= cNearBlackColor;

        FlagTex:= Surface2Tex(texsurf, false);
        SDL_FreeSurface(texsurf);
        texsurf:= nil;

        AIKillsTex := RenderStringTex(inttostr(stats.AIKills), Clan^.Color, fnt16);

        dec(drY, r.h + 2);
        DrawHealthY:= drY;
        for i:= 0 to 7 do
            with Hedgehogs[i] do
                if Gear <> nil then
                    begin
                    NameTagTex:= RenderStringTexLim(Name, Clan^.Color, fnt16, cTeamHealthWidth);
                    if Hat <> 'NoHat' then
                        begin
                        if (Length(Hat) > 39) and (Copy(Hat,1,8) = 'Reserved') and (Copy(Hat,9,32) = PlayerHash) then
                            LoadHedgehogHat(Gear, 'Reserved/' + Copy(Hat,9,Length(Hat)-8))
                        else
                            LoadHedgehogHat(Gear, Hat);
                        end
                    end;
        end;
    MissionIcons:= LoadImage(UserPathz[ptGraphics] + '/missions', ifNone);
    if MissionIcons = nil then
        MissionIcons:= LoadImage(Pathz[ptGraphics] + '/missions', ifCritical);
    iconsurf:= SDL_CreateRGBSurface(SDL_SWSURFACE, 28, 28, 32, RMask, GMask, BMask, AMask);
    if iconsurf <> nil then
        begin
        r.x:= 0;
        r.y:= 0;
        r.w:= 28;
        r.h:= 28;
        DrawRoundRect(@r, cWhiteColor, cNearBlackColor, iconsurf, true);
        ropeIconTex:= Surface2Tex(iconsurf, false);
        SDL_FreeSurface(iconsurf);
        iconsurf:= nil;
        end;
end;

procedure InitHealth;
var i, t: LongInt;
begin
for t:= 0 to Pred(TeamsCount) do
    if TeamsArray[t] <> nil then
        with TeamsArray[t]^ do
            begin
            for i:= 0 to cMaxHHIndex do
                if Hedgehogs[i].Gear <> nil then
                    RenderHealth(Hedgehogs[i]);
            end
end;

procedure LoadGraves;
var t: LongInt;
    texsurf: PSDL_Surface;
begin
for t:= 0 to Pred(TeamsCount) do
    if TeamsArray[t] <> nil then
        with TeamsArray[t]^ do
            begin
            if GraveName = '' then
                GraveName:= 'Statue';
            texsurf:= LoadImage(UserPathz[ptGraves] + '/' + GraveName, ifTransparent);
            if texsurf = nil then
                texsurf:= LoadImage(Pathz[ptGraves] + '/' + GraveName, ifTransparent);
            if texsurf = nil then
                texsurf:= LoadImage(UserPathz[ptGraves] + '/Statue', ifTransparent);
            if texsurf = nil then
                texsurf:= LoadImage(Pathz[ptGraves] + '/Statue', ifCritical or ifTransparent);
            GraveTex:= Surface2Tex(texsurf, false);
            SDL_FreeSurface(texsurf)
            end
end;

procedure StoreLoad(reload: boolean);
var s: shortstring;
    ii: TSprite;
    fi: THWFont;
    ai: TAmmoType;
    tmpsurf: PSDL_Surface;
    i: LongInt;
begin
AddFileLog('StoreLoad()');

if not reload then
    for fi:= Low(THWFont) to High(THWFont) do
        with Fontz[fi] do
            begin
            s:= UserPathz[ptFonts] + '/' + Name;
            if not FileExists(s) then
                s:= Pathz[ptFonts] + '/' + Name;
            WriteToConsole(msgLoading + s + ' (' + inttostr(Height) + 'pt)... ');
            Handle:= TTF_OpenFont(Str2PChar(s), Height);
            SDLTry(Handle <> nil, true);
            TTF_SetFontStyle(Handle, style);
            WriteLnToConsole(msgOK)
            end;

WriteNames(fnt16);
MakeCrossHairs;
LoadGraves;
if not reload then
    AddProgress;

for ii:= Low(TSprite) to High(TSprite) do
    with SpritesData[ii] do
        // FIXME - add a sprite attribute to match on rq flags?
        if (((cReducedQuality and (rqNoBackground or rqLowRes)) = 0) or   // why rqLowRes?
                (not (ii in [sprSky, sprSkyL, sprSkyR, sprHorizont, sprHorizontL, sprHorizontR]))) and
           (((cReducedQuality and rqPlainSplash) = 0) or ((not (ii in [sprSplash, sprDroplet, sprSDSplash, sprSDDroplet])))) and
           (((cReducedQuality and rqKillFlakes) = 0) or (Theme = 'Snow') or (Theme = 'Christmas') or ((not (ii in [sprFlake, sprSDFlake])))) and
           ((cCloudsNumber > 0) or (ii <> sprCloud)) and
           ((vobCount > 0) or (ii <> sprFlake)) then
            begin
            if AltPath = ptNone then
                if ii in [sprHorizont, sprHorizontL, sprHorizontR, sprSky, sprSkyL, sprSkyR, sprChunk] then // FIXME: hack
                    begin
                    if not reload then
                        begin
                        tmpsurf:= LoadImage(UserPathz[Path] + '/' + FileName, ifAlpha or ifTransparent);
                        if tmpsurf = nil then
                           tmpsurf:= LoadImage(Pathz[Path] + '/' + FileName, ifAlpha or ifTransparent)
                        end
                    else
                           tmpsurf:= Surface
                    end
                else
                    begin
                    if not reload then
                        begin
                           tmpsurf:= LoadImage(UserPathz[Path] + '/' + FileName, ifAlpha or ifTransparent);
                        if tmpsurf = nil then
                           tmpsurf:= LoadImage(Pathz[Path] + '/' + FileName, ifAlpha or ifTransparent or ifCritical)
                        end
                    else
                           tmpsurf:= Surface
                    end
            else
                begin
                if not reload then
                    begin
                    tmpsurf:= LoadImage(UserPathz[Path] + '/' + FileName, ifAlpha or ifTransparent);
                    if tmpsurf = nil then
                        tmpsurf:= LoadImage(Pathz[Path] + '/' + FileName, ifAlpha or ifTransparent);
                    if tmpsurf = nil then
                        tmpsurf:= LoadImage(UserPathz[AltPath] + '/' + FileName, ifAlpha or ifTransparent);
                    if tmpsurf = nil then
                        tmpsurf:= LoadImage(Pathz[AltPath] + '/' + FileName, ifAlpha or ifCritical or ifTransparent)
                    end
                else
                        tmpsurf:= Surface
                end;

            if tmpsurf <> nil then
                begin
                if getImageDimensions then
                    begin
                    imageWidth:= tmpsurf^.w;
                    imageHeight:= tmpsurf^.h
                    end;
                if getDimensions then
                    begin
                    Width:= tmpsurf^.w;
                    Height:= tmpsurf^.h
                    end;
                if (ii in [sprSky, sprSkyL, sprSkyR, sprHorizont, sprHorizontL, sprHorizontR]) then
                    begin
                    Texture:= Surface2Tex(tmpsurf, true);
                    Texture^.Scale:= 2
                    end
                else
                    begin
                    Texture:= Surface2Tex(tmpsurf, false);
                    // HACK: We should include some sprite attribute to define the texture wrap directions
                    if ((ii = sprWater) or (ii = sprSDWater)) and ((cReducedQuality and (rq2DWater or rqClampLess)) = 0) then
                        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                    end;
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_PRIORITY, priority);
// This should maybe be flagged. It wastes quite a bit of memory.
                if not reload then
                    begin
{$IFDEF USE_CONTEXT_RESTORE}
                    Surface:= tmpsurf 
{$ELSE}
                    if saveSurf then
                        Surface:= tmpsurf
                    else
                        SDL_FreeSurface(tmpsurf)
{$ENDIF}
                    end
                end
            else
                Surface:= nil
        end;

if not reload then
    AddProgress;

    tmpsurf:= LoadImage(UserPathz[ptGraphics] + '/' + cHHFileName, ifAlpha or ifTransparent);
if tmpsurf = nil then
    tmpsurf:= LoadImage(Pathz[ptGraphics] + '/' + cHHFileName, ifAlpha or ifCritical or ifTransparent);
    
HHTexture:= Surface2Tex(tmpsurf, false);
SDL_FreeSurface(tmpsurf);

InitHealth;

PauseTexture:= RenderStringTex(trmsg[sidPaused], cYellowColor, fntBig);
ConfirmTexture:= RenderStringTex(trmsg[sidConfirm], cYellowColor, fntBig);
SyncTexture:= RenderStringTex(trmsg[sidSync], cYellowColor, fntBig);

if not reload then
    AddProgress;

// name of weapons in ammo menu
for ai:= Low(TAmmoType) to High(TAmmoType) do
    with Ammoz[ai] do
        begin
        TryDo(trAmmo[NameId] <> '','No default text/translation found for ammo type #' + intToStr(ord(ai)) + '!',true);
        tmpsurf:= TTF_RenderUTF8_Blended(Fontz[CheckCJKFont(trAmmo[NameId],fnt16)].Handle, Str2PChar(trAmmo[NameId]), cWhiteColorChannels);
        TryDo(tmpsurf <> nil,'Name-texture creation for ammo type #' + intToStr(ord(ai)) + ' failed!',true);
        tmpsurf:= doSurfaceConversion(tmpsurf);
        FreeTexture(NameTex);
        NameTex:= Surface2Tex(tmpsurf, false);
        SDL_FreeSurface(tmpsurf)
        end;

// number of weapons in ammo menu
for i:= Low(CountTexz) to High(CountTexz) do
    begin
    tmpsurf:= TTF_RenderUTF8_Blended(Fontz[fnt16].Handle, Str2PChar(IntToStr(i) + 'x'), cWhiteColorChannels);
    tmpsurf:= doSurfaceConversion(tmpsurf);
    FreeTexture(CountTexz[i]);
    CountTexz[i]:= Surface2Tex(tmpsurf, false);
    SDL_FreeSurface(tmpsurf)
    end;

if not reload then
    AddProgress;
IMG_Quit();
end;

procedure StoreRelease(reload: boolean);
var ii: TSprite;
    ai: TAmmoType;
    i, t: LongInt;
begin
for ii:= Low(TSprite) to High(TSprite) do
    begin
    FreeTexture(SpritesData[ii].Texture);
    SpritesData[ii].Texture:= nil;
    if (SpritesData[ii].Surface <> nil) and (not reload) then
        begin
        SDL_FreeSurface(SpritesData[ii].Surface);
        SpritesData[ii].Surface:= nil
        end
    end;
SDL_FreeSurface(MissionIcons);

// free the textures declared in uVariables
FreeTexture(WeaponTooltipTex);
WeaponTooltipTex:= nil;
FreeTexture(PauseTexture);
PauseTexture:= nil;
FreeTexture(SyncTexture);
SyncTexture:= nil;
FreeTexture(ConfirmTexture);
ConfirmTexture:= nil;
FreeTexture(ropeIconTex);
ropeIconTex:= nil;
FreeTexture(HHTexture);
HHTexture:= nil;

// free all ammo name textures
for ai:= Low(TAmmoType) to High(TAmmoType) do
    begin
    FreeTexture(Ammoz[ai].NameTex);
    Ammoz[ai].NameTex:= nil
    end;

// free all count textures
for i:= Low(CountTexz) to High(CountTexz) do
    begin
    FreeTexture(CountTexz[i]);
    CountTexz[i]:= nil
    end;

    // free all team and hedgehog textures
    for t:= 0 to Pred(TeamsCount) do
        begin
        if TeamsArray[t] <> nil then
            begin
            FreeTexture(TeamsArray[t]^.NameTagTex);
            TeamsArray[t]^.NameTagTex:= nil;
            FreeTexture(TeamsArray[t]^.CrosshairTex);
            TeamsArray[t]^.CrosshairTex:= nil;
            FreeTexture(TeamsArray[t]^.GraveTex);
            TeamsArray[t]^.GraveTex:= nil;
            FreeTexture(TeamsArray[t]^.HealthTex);
            TeamsArray[t]^.HealthTex:= nil;
            FreeTexture(TeamsArray[t]^.AIKillsTex);
            TeamsArray[t]^.AIKillsTex:= nil;
            FreeTexture(TeamsArray[t]^.FlagTex);
            TeamsArray[t]^.FlagTex:= nil;
            for i:= 0 to cMaxHHIndex do
                begin
                FreeTexture(TeamsArray[t]^.Hedgehogs[i].NameTagTex);
                TeamsArray[t]^.Hedgehogs[i].NameTagTex:= nil;
                FreeTexture(TeamsArray[t]^.Hedgehogs[i].HealthTagTex);
                TeamsArray[t]^.Hedgehogs[i].HealthTagTex:= nil;
                FreeTexture(TeamsArray[t]^.Hedgehogs[i].HatTex);
                TeamsArray[t]^.Hedgehogs[i].HatTex:= nil;
                end;
            end;
        end;
{$IFNDEF S3D_DISABLED}
    if (cStereoMode = smHorizontal) or (cStereoMode = smVertical) or (cStereoMode = smAFR) then
        begin
        glDeleteTextures(1, @texl);
        glDeleteRenderbuffersEXT(1, @depthl);
        glDeleteFramebuffersEXT(1, @framel);
        glDeleteTextures(1, @texr);
        glDeleteRenderbuffersEXT(1, @depthr);
        glDeleteFramebuffersEXT(1, @framer)
        end
{$ENDIF}
end;


procedure RenderHealth(var Hedgehog: THedgehog);
var s: shortstring;
begin
str(Hedgehog.Gear^.Health, s);
FreeTexture(Hedgehog.HealthTagTex);
Hedgehog.HealthTagTex:= RenderStringTex(s, Hedgehog.Team^.Clan^.Color, fnt16)
end;

function LoadImage(const filename: shortstring; imageFlags: LongInt): PSDL_Surface;
var tmpsurf: PSDL_Surface;
    s: shortstring;
begin
    LoadImage:= nil;
    WriteToConsole(msgLoading + filename + '.png [flags: ' + inttostr(imageFlags) + '] ');

    s:= filename + '.png';
    tmpsurf:= IMG_Load(Str2PChar(s));

    if tmpsurf = nil then
    begin
        OutError(msgFailed, (imageFlags and ifCritical) <> 0);
        exit;
    end;

    if ((imageFlags and ifIgnoreCaps) = 0) and ((tmpsurf^.w > MaxTextureSize) or (tmpsurf^.h > MaxTextureSize)) then
    begin
        SDL_FreeSurface(tmpsurf);
        OutError(msgFailedSize, (imageFlags and ifCritical) <> 0);
        // dummy surface to replace non-critical textures that failed to load due to their size
        LoadImage:= SDL_CreateRGBSurface(SDL_SWSURFACE, 2, 2, 32, RMask, GMask, BMask, AMask);
        exit;
    end;

    tmpsurf:= doSurfaceConversion(tmpsurf);

    if (imageFlags and ifTransparent) <> 0 then
        TryDo(SDL_SetColorKey(tmpsurf, SDL_SRCCOLORKEY, 0) = 0, errmsgTransparentSet, true);

    WriteLnToConsole(msgOK + ' (' + inttostr(tmpsurf^.w) + 'x' + inttostr(tmpsurf^.h) + ')');

    LoadImage:= tmpsurf //Result
end;

procedure LoadHedgehogHat(HHGear: PGear; newHat: shortstring);
var texsurf: PSDL_Surface;
begin
texsurf:= LoadImage(UserPathz[ptHats] + '/' + newHat, ifNone);
    if texsurf = nil then
        texsurf:= LoadImage(Pathz[ptHats] + '/' + newHat, ifNone);

    // only do something if the hat could be loaded
    if texsurf <> nil then
        begin
        // free the mem of any previously assigned texture
        FreeTexture(HHGear^.Hedgehog^.HatTex);

        // assign new hat to hedgehog
        HHGear^.Hedgehog^.HatTex:= Surface2Tex(texsurf, true);

        // cleanup: free temporary surface mem
        SDL_FreeSurface(texsurf)
        end;
end;

function glLoadExtension(extension : shortstring) : boolean;
begin
{$IF GLunit = gles11}
    // FreePascal doesnt come with OpenGL ES 1.1 Extension headers
    extension:= extension; // avoid hint
    glLoadExtension:= false;
    AddFileLog('OpenGL - "' + extension + '" skipped')
{$ELSE}
    glLoadExtension:= glext_LoadExtension(extension);
    if glLoadExtension then
        AddFileLog('OpenGL - "' + extension + '" loaded')
    else
        AddFileLog('OpenGL - "' + extension + '" failed to load');
{$ENDIF}
end;

procedure SetupOpenGLAttributes;
begin
{$IFDEF IPHONEOS}
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 0);
    SDL_GL_SetAttribute(SDL_GL_RETAINED_BACKING, 1);
{$ELSE}
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
{$IFNDEF SDL13} // vsync is default in 1.3
    SDL_GL_SetAttribute(SDL_GL_SWAP_CONTROL, LongInt((cReducedQuality and rqDesyncVBlank) = 0));
{$ENDIF}
{$ENDIF}
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 0); // no depth buffer
    SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 5);
    SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 6);
    SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 5);
    SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE, 0); // no alpha channel required
    SDL_GL_SetAttribute(SDL_GL_BUFFER_SIZE, 16); // buffer has to be 16 bit only
    SDL_GL_SetAttribute(SDL_GL_ACCELERATED_VISUAL, 1); // try to prefer hardware rendering
end;

procedure SetupOpenGL;
//var vendor: shortstring = '';
var buf: array[byte] of char;
begin
    buf[0]:= char(0); // avoid compiler hint
    AddFileLog('Setting up OpenGL (using driver: ' + shortstring(SDL_VideoDriverName(buf, sizeof(buf))) + ')');

{$IFDEF SDL13}
    // this function creates an opengles1.1 context by default on mobile devices
    // unless you un-comment this two attributes
    //SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
    //SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
    if SDLGLcontext = nil then
        SDLGLcontext:= SDL_GL_CreateContext(SDLwindow);
    SDLTry(SDLGLcontext <> nil, true);
    SDL_GL_SetSwapInterval(1);
{$ENDIF}

    // get the max (horizontal and vertical) size for textures that the gpu can support
    glGetIntegerv(GL_MAX_TEXTURE_SIZE, @MaxTextureSize);
    if MaxTextureSize <= 0 then
        begin
        MaxTextureSize:= 1024;
        AddFileLog('OpenGL Warning - driver didn''t provide any valid max texture size; assuming 1024');
        end
    else if (MaxTextureSize < 1024) and (MaxTextureSize >= 512) then
        begin
        cReducedQuality := cReducedQuality or rqNoBackground;  
        AddFileLog('Texture size too small for backgrounds, disabling.');
        end;

(*  // find out which gpu we are using (for extension compatibility maybe?)
{$IFDEF IPHONEOS}
    vendor:= vendor; // avoid hint
    cGPUVendor:= gvApple;
{$ELSE}
    vendor:= LowerCase(shortstring(pchar(glGetString(GL_VENDOR))));
    if StrPos(Str2PChar(vendor), Str2PChar('nvidia')) <> nil then
        cGPUVendor:= gvNVIDIA
    else if StrPos(Str2PChar(vendor), Str2PChar('intel')) <> nil then
        cGPUVendor:= gvATI
    else if StrPos(Str2PChar(vendor), Str2PChar('ati')) <> nil then
        cGPUVendor:= gvIntel
    else
        AddFileLog('OpenGL Warning - unknown hardware vendor; please report');
{$ENDIF}
//SupportNPOTT:= glLoadExtension('GL_ARB_texture_non_power_of_two');
*)

    // everyone love debugging
    AddFileLog('OpenGL-- Renderer: ' + shortstring(pchar(glGetString(GL_RENDERER))));
    AddFileLog('  |----- Vendor: ' + shortstring(pchar(glGetString(GL_VENDOR))));
    AddFileLog('  |----- Version: ' + shortstring(pchar(glGetString(GL_VERSION))));
    AddFileLog('  |----- Texture Size: ' + inttostr(MaxTextureSize));
    AddFileLog('  \----- Extensions: ' + shortstring(pchar(glGetString(GL_EXTENSIONS))));
    //TODO: don't have the Extensions line trimmed but slipt it into multiple lines

{$IFNDEF S3D_DISABLED}
    if (cStereoMode = smHorizontal) or (cStereoMode = smVertical) or (cStereoMode = smAFR) then
    begin
        // prepare left and right frame buffers and associated textures
        if glLoadExtension('GL_EXT_framebuffer_object') then
            begin
            // left
            glGenFramebuffersEXT(1, @framel);
            glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, framel);
            glGenRenderbuffersEXT(1, @depthl);
            glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, depthl);
            glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT, cScreenWidth, cScreenHeight);
            glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, depthl);
            glGenTextures(1, @texl);
            glBindTexture(GL_TEXTURE_2D, texl);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8,  cScreenWidth, cScreenHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, texl, 0);

            // right
            glGenFramebuffersEXT(1, @framer);
            glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, framer);
            glGenRenderbuffersEXT(1, @depthr);
            glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, depthr);
            glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT, cScreenWidth, cScreenHeight);
            glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, depthr);
            glGenTextures(1, @texr);
            glBindTexture(GL_TEXTURE_2D, texr);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8,  cScreenWidth, cScreenHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, texr, 0);

            // reset
            glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0)
            end
        else
            cStereoMode:= smNone;
    end;
{$ENDIF}

    // set view port to whole window
    glViewport(0, 0, cScreenWidth, cScreenHeight);

    glMatrixMode(GL_MODELVIEW);
    // prepare default translation/scaling
    glLoadIdentity();
    glScalef(2.0 / cScreenWidth, -2.0 / cScreenHeight, 1.0);
    glTranslatef(0, -cScreenHeight / 2, 0);

    // enable alpha blending
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    // disable/lower perspective correction (will not need it anyway)
    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_FASTEST);
    // disable dithering
    glDisable(GL_DITHER);
    // enable common states by default as they save a lot
    glEnable(GL_TEXTURE_2D);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
end;

procedure SetScale(f: GLfloat);
begin
// leave immediately if scale factor did not change
    if f = cScaleFactor then
        exit;

    if f = cDefaultZoomLevel then
        glPopMatrix         // "return" to default scaling
    else                    // other scaling
        begin
        glPushMatrix;       // save default scaling
        glLoadIdentity;
        glScalef(f / cScreenWidth, -f / cScreenHeight, 1.0);
        glTranslatef(0, -cScreenHeight / 2, 0);
        end;

    cScaleFactor:= f;
end;

////////////////////////////////////////////////////////////////////////////////
procedure AddProgress;
var r: TSDL_Rect;
    texsurf: PSDL_Surface;
begin
    if Step = 0 then
    begin
        WriteToConsole(msgLoading + 'progress sprite: ');
        texsurf:= LoadImage(UserPathz[ptGraphics] + '/Progress', ifTransparent);
        if texsurf = nil then
            texsurf:= LoadImage(Pathz[ptGraphics] + '/Progress', ifCritical or ifTransparent);

        ProgrTex:= Surface2Tex(texsurf, false);

        squaresize:= texsurf^.w shr 1;
        numsquares:= texsurf^.h div squaresize;
        SDL_FreeSurface(texsurf);

        uMobile.GameLoading();
        end;

    TryDo(ProgrTex <> nil, 'Error - Progress Texure is nil!', true);

    glClear(GL_COLOR_BUFFER_BIT);
    if Step < numsquares then
        r.x:= 0
    else
        r.x:= squaresize;

    r.y:= (Step mod numsquares) * squaresize;
    r.w:= squaresize;
    r.h:= squaresize;

    DrawTextureFromRect( -squaresize div 2, (cScreenHeight - squaresize) shr 1, @r, ProgrTex);

{$IFDEF SDL13}
    SDL_GL_SwapWindow(SDLwindow);
{$ELSE}
    SDL_GL_SwapBuffers();
{$ENDIF}
    inc(Step);
end;

procedure FinishProgress;
begin
    uMobile.GameLoaded();
    WriteLnToConsole('Freeing progress surface... ');
    FreeTexture(ProgrTex);
    ProgrTex:= nil;
    Step:= 0
end;

function RenderHelpWindow(caption, subcaption, description, extra: ansistring; extracolor: LongInt; iconsurf: PSDL_Surface; iconrect: PSDL_Rect): PTexture;
var tmpsurf: PSDL_SURFACE;
    w, h, i, j: LongInt;
    font: THWFont;
    r, r2: TSDL_Rect;
    wa, ha: LongInt;
    tmpline, tmpline2, tmpdesc: ansistring;
begin
// make sure there is a caption as well as a sub caption - description is optional
if caption = '' then
    caption:= '???';
if subcaption = '' then
    subcaption:= ' ';

font:= CheckCJKFont(caption,fnt16);
font:= CheckCJKFont(subcaption,font);
font:= CheckCJKFont(description,font);
font:= CheckCJKFont(extra,font);

w:= 0;
h:= 0;
wa:= cFontBorder * 2 + 4;
ha:= cFontBorder * 2;

i:= 0; j:= 0; // avoid compiler hints

// TODO: Recheck height/position calculation

// get caption's dimensions
TTF_SizeUTF8(Fontz[font].Handle, Str2PChar(caption), @i, @j);
// width adds 36 px (image + space)
w:= i + 36 + wa;
h:= j + ha;

// get sub caption's dimensions
TTF_SizeUTF8(Fontz[font].Handle, Str2PChar(subcaption), @i, @j);
// width adds 36 px (image + space)
if w < (i + 36 + wa) then
    w:= i + 36 + wa;
inc(h, j + ha);

// get description's dimensions
tmpdesc:= description;
while tmpdesc <> '' do
    begin
    tmpline:= tmpdesc;
    SplitByChar(tmpline, tmpdesc, '|');
    if tmpline <> '' then
        begin
        TTF_SizeUTF8(Fontz[font].Handle, Str2PChar(tmpline), @i, @j);
        if w < (i + wa) then
            w:= i + wa;
        inc(h, j + ha)
        end
    end;

if extra <> '' then
    begin
    // get extra label's dimensions
    TTF_SizeUTF8(Fontz[font].Handle, Str2PChar(extra), @i, @j);
    if w < (i + wa) then
        w:= i + wa;
    inc(h, j + ha);
    end;

// add borders space
inc(w, wa);
inc(h, ha + 8);

tmpsurf:= SDL_CreateRGBSurface(SDL_SWSURFACE, w, h, 32, RMask, GMask, BMask, AMask);
TryDo(tmpsurf <> nil, 'RenderHelpWindow: fail to create surface', true);

// render border and background
r.x:= 0;
r.y:= 0;
r.w:= w;
r.h:= h;
DrawRoundRect(@r, cWhiteColor, cNearBlackColor, tmpsurf, true);

// render caption
r:= WriteInRect(tmpsurf, 36 + cFontBorder + 2, ha, $ffffffff, font, caption);
// render sub caption
r:= WriteInRect(tmpsurf, 36 + cFontBorder + 2, r.y + r.h, $ffc7c7c7, font, subcaption);

// render all description lines
tmpdesc:= description;
while tmpdesc <> '' do
    begin
    tmpline:= tmpdesc;
    SplitByChar(tmpline, tmpdesc, '|');
    r2:= r;
    if tmpline <> '' then
        begin
        r:= WriteInRect(tmpsurf, cFontBorder + 2, r.y + r.h, $ff707070, font, tmpline);

        // render highlighted caption (if there is a ':')
        tmpline2:= '';
        SplitByChar(tmpline, tmpline2, ':');
        if tmpline2 <> '' then
            WriteInRect(tmpsurf, cFontBorder + 2, r2.y + r2.h, $ffc7c7c7, font, tmpline + ':');
        end
    end;

if extra <> '' then
    r:= WriteInRect(tmpsurf, cFontBorder + 2, r.y + r.h, extracolor, font, extra);

r.x:= cFontBorder + 6;
r.y:= cFontBorder + 4;
r.w:= 32;
r.h:= 32;
SDL_FillRect(tmpsurf, @r, $ffffffff);
SDL_UpperBlit(iconsurf, iconrect, tmpsurf, @r);

RenderHelpWindow:=  Surface2Tex(tmpsurf, true);
SDL_FreeSurface(tmpsurf)
end;

procedure RenderWeaponTooltip(atype: TAmmoType);
var r: TSDL_Rect;
    i: LongInt;
    extra: ansistring;
    extracolor: LongInt;
begin
// don't do anything if the window shouldn't be shown
    if (cReducedQuality and rqTooltipsOff) <> 0 then
        begin
        WeaponTooltipTex:= nil;
        exit
        end;

// free old texture
FreeWeaponTooltip;

// image region
i:= LongInt(atype) - 1;
r.x:= (i shr 4) * 32;
r.y:= (i mod 16) * 32;
r.w:= 32;
r.h:= 32;

// default (no extra text)
extra:= '';
extracolor:= 0;

if (CurrentTeam <> nil) and (Ammoz[atype].SkipTurns >= CurrentTeam^.Clan^.TurnNumber) then // weapon or utility is not yet available
    begin
    extra:= trmsg[sidNotYetAvailable];
    extracolor:= LongInt($ffc77070);
    end
else if (Ammoz[atype].Ammo.Propz and ammoprop_NoRoundEnd) <> 0 then // weapon or utility will not end your turn
    begin
    extra:= trmsg[sidNoEndTurn];
    extracolor:= LongInt($ff70c770);
    end
else
    begin
    extra:= '';
    extracolor:= 0;
    end;

// render window and return the texture
WeaponTooltipTex:= RenderHelpWindow(trammo[Ammoz[atype].NameId], trammoc[Ammoz[atype].NameId], trammod[Ammoz[atype].NameId], extra, extracolor, SpritesData[sprAMAmmos].Surface, @r)
end;

procedure ShowWeaponTooltip(x, y: LongInt);
begin
// draw the texture if it exists
if WeaponTooltipTex <> nil then
    DrawTexture(x, y, WeaponTooltipTex)
end;

procedure FreeWeaponTooltip;
begin
// free the existing texture (if there is any)
FreeTexture(WeaponTooltipTex);
WeaponTooltipTex:= nil
end;

procedure chFullScr(var s: shortstring);
var flags: Longword = 0;
    reinit: boolean = false;
    {$IFNDEF DARWIN}ico: PSDL_Surface;{$ENDIF}
    {$IFDEF SDL13}x, y: LongInt;{$ENDIF}
begin
    if Length(s) = 0 then
        cFullScreen:= (not cFullScreen)
    else
        cFullScreen:= s = '1';

    AddFileLog('Preparing to change video parameters...');
{$IFDEF SDL13}
    if SDLwindow = nil then
{$ELSE}
    if SDLPrimSurface = nil then
{$ENDIF}
        begin
        // set window title
        {$IFNDEF SDL13}SDL_WM_SetCaption('Hedgewars', nil);{$ENDIF}
        WriteToConsole('Init SDL_image... ');
        SDLTry(IMG_Init(IMG_INIT_PNG) <> 0, true);
        WriteLnToConsole(msgOK);
        // load engine icon
    {$IFNDEF DARWIN}
        ico:= LoadImage(UserPathz[ptGraphics] + '/hwengine', ifIgnoreCaps);
        if ico = nil then
            ico:= LoadImage(Pathz[ptGraphics] + '/hwengine', ifIgnoreCaps);
        if ico <> nil then
            begin
            SDL_WM_SetIcon(ico, 0);
            SDL_FreeSurface(ico)
            end;
    {$ENDIF}
        end
    else
        begin
        AmmoMenuInvalidated:= true;
{$IFDEF IPHONEOS}
        // chFullScr is called when there is a rotation event and needs the SetScale and SetupOpenGL to set up the new resolution
        // this 6 gl functions are the relevant ones and are hacked together here for optimisation
        glMatrixMode(GL_MODELVIEW);
        glPopMatrix;
        glLoadIdentity();
        glScalef(2.0 / cScreenWidth, -2.0 / cScreenHeight, 1.0);
        glTranslatef(0, -cScreenHeight / 2, 0);
        glViewport(0, 0, cScreenWidth, cScreenHeight);
        exit;
{$ELSE}
        SetScale(cDefaultZoomLevel);
     {$IFDEF USE_CONTEXT_RESTORE}
        reinit:= true;
        StoreRelease(true);
        ResetLand;
        ResetWorldTex;
        //uTextures.freeModule; //DEBUG ONLY
    {$ENDIF}
        AddFileLog('Freeing old primary surface...');
        SDL_FreeSurface(SDLPrimSurface);
        SDLPrimSurface:= nil;
{$ENDIF}
        end;

    // these attributes must be set up before creating the sdl window
{$IFNDEF WIN32}
(* On a large number of testers machines, SDL default to software rendering when opengl attributes were set.
   These attributes were "set" after CreateWindow in .15, which probably did nothing.
   IMO we should rely on the gl_config defaults from SDL, and use SDL_GL_GetAttribute to possibly post warnings if any
   bad values are set.  *)
    SetupOpenGLAttributes();
{$ENDIF}
{$IFDEF SDL13}
    // these values in x and y make the window appear in the center
    x:= SDL_WINDOWPOS_CENTERED_MASK;
    y:= SDL_WINDOWPOS_CENTERED_MASK;
    // SDL_WINDOW_RESIZABLE makes the window respond to rotation events on mobile devices
    flags:= SDL_WINDOW_OPENGL or SDL_WINDOW_SHOWN or SDL_WINDOW_RESIZABLE;

    {$IFDEF MOBILE}
    if isPhone() then
        SDL_SetHint('SDL_IOS_ORIENTATIONS','LandscapeLeft LandscapeRight');
    // no need for borders on mobile devices
    flags:= flags or SDL_WINDOW_BORDERLESS;
    {$ENDIF}

    if SDLwindow = nil then
        if cFullScreen then
            SDLwindow:= SDL_CreateWindow('Hedgewars', x, y, cOrigScreenWidth, cOrigScreenHeight, flags or SDL_WINDOW_FULLSCREEN)
        else
            SDLwindow:= SDL_CreateWindow('Hedgewars', x, y, cScreenWidth, cScreenHeight, flags);
    SDLTry(SDLwindow <> nil, true);
{$ELSE}
    flags:= SDL_OPENGL or SDL_RESIZABLE;
    if cFullScreen then
        flags:= flags or SDL_FULLSCREEN;

    if not cOnlyStats then
        begin
    {$IFDEF WIN32}
        s:= SDL_getenv('SDL_VIDEO_CENTERED');
        SDL_putenv('SDL_VIDEO_CENTERED=1');
    {$ENDIF}
        SDLPrimSurface:= SDL_SetVideoMode(cScreenWidth, cScreenHeight, cBits, flags);
        SDLTry(SDLPrimSurface <> nil, true);
    {$IFDEF WIN32}SDL_putenv(str2pchar('SDL_VIDEO_CENTERED=' + s));{$ENDIF}
        end;
{$ENDIF}

    SetupOpenGL();
    if reinit then
        begin
        // clean the window from any previous content
        glClear(GL_COLOR_BUFFER_BIT);
        if SuddenDeathDmg then
            glClearColor(SDSkyColor.r * (SDTint/255) / 255, SDSkyColor.g * (SDTint/255) / 255, SDSkyColor.b * (SDTint/255) / 255, 0.99)
        else if ((cReducedQuality and rqNoBackground) = 0) then 
            glClearColor(SkyColor.r / 255, SkyColor.g / 255, SkyColor.b / 255, 0.99)
        else
            glClearColor(RQSkyColor.r / 255, RQSkyColor.g / 255, RQSkyColor.b / 255, 0.99);

        // reload everything we had before
        ReloadCaptions(false);
        ReloadLines;
        StoreLoad(true);
        // redraw all land
        UpdateLandTexture(0, LAND_WIDTH, 0, LAND_HEIGHT);
        end;
end;

procedure initModule;
var ai: TAmmoType;
    i: LongInt;
begin
    RegisterVariable('fullscr', @chFullScr, true);

    SDLPrimSurface:= nil;

    cScaleFactor:= 2.0;
    Step:= 0;
    ProgrTex:= nil;
    SupportNPOTT:= false;
//    cGPUVendor:= gvUnknown;

    // init all ammo name texture pointers
    for ai:= Low(TAmmoType) to High(TAmmoType) do
    begin
        Ammoz[ai].NameTex := nil;
    end;
    // init all count texture pointers
    for i:= Low(CountTexz) to High(CountTexz) do
        CountTexz[i] := nil;
end;

procedure freeModule;
begin
    StoreRelease(false);
    TTF_Quit();
{$IFDEF SDL13}
    SDL_GL_DeleteContext(SDLGLcontext);
    SDL_DestroyWindow(SDLwindow);
{$ENDIF}
    SDL_Quit();
end;

end.
