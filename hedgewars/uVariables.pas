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

unit uVariables;
interface

uses SDLh, uTypes, uFloat, GLunit, uConsts, Math, uUtils{$IFDEF GL2}, uMatrix{$ENDIF};

procedure initScreenSpaceVars();

var
/////// init flags ///////
    cMinScreenWidth    : LongInt;
    cMinScreenHeight   : LongInt;
    cFullscreenWidth   : LongInt;
    cFullscreenHeight  : LongInt;
    cWindowedWidth     : LongInt;
    cWindowedHeight    : LongInt;
    cScreenWidth       : LongInt;
    cScreenHeight      : LongInt;
    cNewScreenWidth    : LongInt;
    cNewScreenHeight   : LongInt;
    cScreenResizeDelay : LongWord;
    ipcPort            : Word;
    AprilOne           : boolean;
    cFullScreen        : boolean;
    cLocaleFName       : shortstring;
    cLocale            : shortstring;
    cTimerInterval     : LongInt;
    PathPrefix         : ansistring;
    UserPathPrefix     : ansistring;
    cShowFPS           : boolean;
    cFlattenFlakes     : boolean;
    cFlattenClouds     : boolean;
    cIce               : boolean;
    cSnow              : boolean;
    isInChatMode       : boolean;

    cAltDamage         : boolean;
    cReducedQuality    : LongWord;
    UserNick           : shortstring;
    recordFileName     : shortstring;
    cReadyDelay        : Longword;
    cStereoMode        : TStereoMode;
    cOnlyStats         : boolean;
{$IFDEF USE_VIDEO_RECORDING}
    RecPrefix          : shortstring;
    cAVFormat          : shortstring;
    cVideoCodec        : shortstring;
    cVideoFramerateNum : LongInt;
    cVideoFramerateDen : LongInt;
    cVideoQuality      : LongInt;
    cAudioCodec        : shortstring;
{$ENDIF}
//////////////////////////
    cMapName           : shortstring;
    syncedPixelDigest  : LongInt;
    isCursorVisible : boolean;
    isInLag         : boolean;
    isPaused        : boolean;
    isInMultiShoot  : boolean;
    isSpeed         : boolean;
    isAFK           : boolean;
    isShowMission   : boolean;
    isForceMission  : boolean;
    SpeedStart      : LongWord;

    fastUntilLag    : boolean;
    fastScrolling   : boolean;
    autoCameraOn    : boolean;

    CheckSum        : LongWord;
    CampaignVariable: shortstring;
    GameTicks       : LongWord;
    OuchTauntTimer  : LongWord; // Timer which blocks sndOuch from being played too often and fast
    GameState       : TGameState;
    GameType        : TGameType;
    InputMask       : LongWord;
    GameFlags       : Longword;
    WorldEdge       : TWorldEdge;
    LeftImpactTimer : LongWord;
    RightImpactTimer: LongWord;
    TurnTimeLeft    : Longword;
    TurnClockActive : boolean;
    TagTurnTimeLeft : Longword;
    ReadyTimeLeft   : Longword;
    IsGetAwayTime   : boolean;
    GameOver        : boolean;
    cSuddenDTurns   : LongInt;
    cDamagePercent  : LongInt;
    cMineDudPercent : LongWord;
    cTemplateFilter : LongInt;
    cFeatureSize    : LongInt;
    cMapGen         : TMapGen;
    cRopePercent    : LongWord;
    cGetAwayTime    : LongWord;

    cAdvancedMapGenMode: boolean;

    cHedgehogTurnTime: Longword;
    cMinesTime       : LongInt;
    cMaxAIThinkTime  : Longword;

    cHealthCaseProb  : LongInt;
    cHealthCaseAmount: LongInt;
    cWaterRise       : LongInt;
    cHealthDecrease  : LongInt;

    cCloudsNumber    : LongWord;
    cSDCloudsNumber  : LongWord;

    cTagsMask        : byte;
    cPrevTagsMask    : byte;
    zoom             : GLfloat;
    ZoomValue        : GLfloat;

    cWaterLine       : LongInt;
    cGearScrEdgesDist: LongInt;
    isAudioMuted     : boolean;

    // originally typed consts
    ExplosionBorderColorR,
    ExplosionBorderColorG,
    ExplosionBorderColorB,
    ExplosionBorderColorNoA,
    ExplosionBorderColor:  LongWord;
    IceColor            : LongWord;
    IceEdgeColor        : LongWord;
    WaterOpacity: byte;
    SDWaterOpacity: byte;
    GrayScale: Boolean;

    CountTexz: array[0..Pred(AMMO_INFINITE)] of PTexture;
    LAND_WIDTH       : LongInt;
    LAND_HEIGHT      : LongInt;
    LAND_WIDTH_MASK  : LongWord;
    LAND_HEIGHT_MASK : LongWord;

    ChefHatTexture : PTexture;
    CrosshairTexture : PTexture;
    GenericHealthTexture : PTexture;

    cLeftScreenBorder     : LongInt;
    cRightScreenBorder    : LongInt;
    cScreenSpace          : Longword;

    cCaseFactor     : Longword;
    cMaxCaseDrops   : Longword; // Max. number of crates which can be in the game when dropping
    cLandMines      : Longword;
    cAirMines       : Longword;
    cExplosives     : Longword;

    cScriptName     : shortstring;
    cScriptParam    : shortstring;
    cSeed           : shortstring;
    cIsSoundEnabled : boolean; // If the sound system is enabled
    cVolumeDelta    : LongInt;
    cMuteToggle     : boolean; // Mute toggle requested
    cHasFocus       : boolean;
    cInactDelay     : Longword;

    bBetweenTurns   : boolean;
    bWaterRising    : boolean;
    bDuringWaterRise: boolean;

    CrosshairX      : LongInt;
    CrosshairY      : LongInt;
    CursorMovementX : LongInt;
    CursorMovementY : LongInt;
    cWaveHeight     : LongInt;
    cDrownSpeed     : hwFloat;
    cDrownSpeedf    : real;
    cMaxWindSpeed   : hwFloat;
    cWindSpeed      : hwFloat;
    cWindSpeedf     : real;
    cElastic        : hwFloat;
    cGravity        : hwFloat;
    cGravityf       : real;
    cLowGravity     : boolean;
    cBuildMaxDist   : LongInt;
    cDamageModifier : hwFloat;
    cLaserSighting  : boolean;
    cLaserSightingSniper : boolean;
    cVampiric       : boolean;
    WeaponTooltipTex: PTexture;
    AmmoMenuInvalidated: boolean;
    AmmoRect        : TSDL_Rect;
    HHTexture       : PTexture;
    cMaxZoomLevel   : real;
    cMinZoomLevel   : real;
    cZoomDelta      : real;
    cMinMaxZoomLevelDelta : real;


    flagMakeCapture : boolean;
    flagDumpLand    : boolean;

    InitStepsFlags  : Longword;
    RealTicks       : Longword;
    AttackBar       : LongInt;

    WaterColorArray : array[0..7] of HwColor4f;
    SDWaterColorArray : array[0..7] of HwColor4f;
    ClanColorArray : array[0..Pred(cClanColors)] of Longword;

    TargetCursorPoint     : TPoint;
    CursorPoint           : TPoint;
    TargetPoint           : TPoint;

    ScreenFade      : TScreenFade;
    ScreenFadeValue : LongInt;
    ScreenFadeSpeed : LongInt;
    InCinematicMode : boolean;
    CinematicSteps  : LongInt;
    CinematicBarH   : LongInt;
    CinematicScript : boolean;

    UIDisplay       : TUIDisplay;
    LocalMessage    : LongWord;

    Theme           : shortstring;
    disableLandBack : boolean;

    WorldDx: LongInt;
    WorldDy: LongInt;

    SpeechHogNumber: LongInt;

    // for tracking the limits of the visible grid based on cScaleFactor
    ViewLeftX, ViewRightX, ViewBottomY, ViewTopY, ViewWidth, ViewHeight: LongInt;

    // for debugging the view limits visually
    cViewLimitsDebug: boolean;

    dirtyLandTexCount: LongInt;

    hiTicks: Word;

    LuaGoals        : ansistring;

    LuaTemplateNumber : LongWord;

    // for EndTurn Lua call
    LuaEndTurnRequested: boolean;
    LuaNoEndTurnTaunts: boolean;

    MaskedSounds : array[TSound] of boolean;

    LastVoice : TVoice;

    mobileRecord: TMobileRecord;

    MaxTextureSize: LongInt;

    SDLwindow: PSDL_Window;
    SDLGLcontext: PSDL_GLContext;
  
/////////////////////////////////////
//Buttons
{$IFDEF USE_TOUCH_INTERFACE}
    buttonScale: GLFloat;

    arrowUp, arrowDown, arrowLeft, arrowRight : TOnScreenWidget;
    firebutton, jumpWidget, AMWidget          : TOnScreenWidget;
    pauseButton, utilityWidget                : TOnScreenWidget;
{$ENDIF}


var
    // these consts are here because they would cause circular dependencies in uConsts/uTypes
    cPathz: array[TPathType] of shortstring;

const
    cPathzInit: array[TPathType] of shortstring = (
        '',                              // ptNone
        '//',                            // ptData
        '/Graphics',                     // ptGraphics
        '/Themes',                       // ptThemes
        '/Themes/Bamboo',                // ptCurrTheme
        '/Config',                       // ptConfig
        '/Config/Teams',                 // ptTeams
        '/Maps',                         // ptMaps
        '',                              // ptMapCurrent
        '/Demos',                        // ptDemos
        '/Sounds',                       // ptSounds
        '/Graphics/Graves',              // ptGraves
        '/Fonts',                        // ptFonts
        '/Forts',                        // ptForts
        '/Locale',                       // ptLocale
        '/Graphics/AmmoMenu',            // ptAmmoMenu
        '/Graphics/Hedgehog',            // ptHedgehog
        '/Sounds/voices',                // ptVoices
        '/Graphics/Hats',                // ptHats
        '/Graphics/Flags',               // ptFlags
        '/Missions/Maps',                // ptMissionMaps
        '/Graphics/SuddenDeath',         // ptSuddenDeath
        '/Graphics/Buttons',             // ptButton
        '/Shaders'                       // ptShaders
    );

var
    Fontz: array[THWFont] of THHFont;

const
    FontzInit: array[THWFont] of THHFont = (
            (Handle: nil;
            Height: 12*HDPIScaleFactor;
            style: TTF_STYLE_NORMAL;
            Name: 'DejaVuSans-Bold.ttf'),
            (Handle: nil;
            Height: 24*HDPIScaleFactor;
            style: TTF_STYLE_NORMAL;
            Name: 'DejaVuSans-Bold.ttf'),
            (Handle: nil;
            Height: 10*HDPIScaleFactor;
            style: TTF_STYLE_NORMAL;
            Name: 'DejaVuSans-Bold.ttf')
            {$IFNDEF MOBILE}, // remove chinese fonts for now
            (Handle: nil;
            Height: 12*HDPIScaleFactor;
            style: TTF_STYLE_NORMAL;
            Name: 'wqy-zenhei.ttc'),
            (Handle: nil;
            Height: 24*HDPIScaleFactor;
            style: TTF_STYLE_NORMAL;
            Name: 'wqy-zenhei.ttc'),
            (Handle: nil;
            Height: 10*HDPIScaleFactor;
            style: TTF_STYLE_NORMAL;
            Name: 'wqy-zenhei.ttc')
            {$ENDIF}
            );

var
    SpritesData: array[TSprite] of TSpriteData;

const
    SpritesDataInit: array[TSprite] of TSpriteData = (
            (FileName:  'BlueWater'; Path: ptCurrTheme;AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width:   0; Height:  -1; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: true; getImageDimensions: true),// sprWater
            (FileName:     'Clouds'; Path: ptCurrTheme;AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width: 256; Height:128; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprCloud
            (FileName:       'Bomb'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   8; Height:  8; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprBomb
            (FileName:  'BigDigits'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprBigDigit
            (FileName: 'BigDigitsGray'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprBigDigitGray
            (FileName: 'BigDigitsGreen'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprBigDigitGreen
            (FileName: 'BigDigitsRed'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprBigDigitRed
            (FileName:      'Frame'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   4; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprFrame
            (FileName:        'Lag'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  65; Height: 65; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprLag
            (FileName:      'Arrow'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprCursor
            (FileName:'BazookaShell'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprBazookaShell
            (FileName:    'Targetp'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprTargetP
            (FileName:        'Bee'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprBee
            (FileName: 'SmokeTrace'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprSmokeTrace
            (FileName:   'RopeHook'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprRopeHook
            (FileName:     'Expl50'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprExplosion50
            (FileName:    'MineOff'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   8; Height:  8; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprMineOff
            (FileName:     'MineOn'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   8; Height:  8; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprMineOn
            (FileName:     'MineDead'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   8; Height:  8; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprMineDead
            (FileName:       'Case'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  48; Height: 48; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprCase
            (FileName:   'FirstAid'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  48; Height: 48; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprFAid
            (FileName:   'dynamite'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprDynamite
            (FileName:      'Power'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprPower
            (FileName:     'ClBomb'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprClusterBomb
            (FileName: 'ClParticle'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprClusterParticle
            (FileName:      'Flame'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprFlame
            (FileName:   'horizont'; Path: ptCurrTheme;AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   0; Height:  0; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: false; checkSum: false; priority: tpHigh; getDimensions: true; getImageDimensions: true),// sprHorizont
            (FileName:  'horizontL'; Path: ptCurrTheme;AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   0; Height:  0; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: false; checkSum: false; priority: tpHigh; getDimensions: true; getImageDimensions: true),// sprHorizontL
            (FileName:  'horizontR'; Path: ptCurrTheme;AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   0; Height:  0; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: false; checkSum: false; priority: tpHigh; getDimensions: true; getImageDimensions: true),// sprHorizontR
            (FileName:        'Sky'; Path: ptCurrTheme;AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   0; Height:  0; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: false; checkSum: false; priority: tpHigh; getDimensions: true; getImageDimensions: true),// sprSky
            (FileName:       'SkyL'; Path: ptCurrTheme;AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   0; Height:  0; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: false; checkSum: false; priority: tpHigh; getDimensions: true; getImageDimensions: true),// sprSkyL
            (FileName:       'SkyR'; Path: ptCurrTheme;AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   0; Height:  0; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: false; checkSum: false; priority: tpHigh; getDimensions: true; getImageDimensions: true),// sprSkyR
            (FileName:   'Slot'; Path: ptAmmoMenu; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprAMSlot
            (FileName:      'Ammos_base'; Path: ptAmmoMenu; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprAMAmmos
            (FileName:   'Ammos_bw_base'; Path: ptAmmoMenu; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprAMAmmosBW
            (FileName:   'SlotKeys'; Path: ptAmmoMenu; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprAMSlotKeys
            (FileName:  'Corners'; Path: ptAmmoMenu; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  2; Height: 2; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprAMCorners
            (FileName:     'Finger'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 48; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprFinger
            (FileName:    'AirBomb'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprAirBomb
            (FileName:   'Airplane'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 256; Height: 128; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprAirplane
            (FileName: 'amAirplane'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprAmAirplane
            (FileName:   'amGirder'; Path: ptCurrTheme; AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width: 160; Height:160; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: true; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprAmGirder
            (FileName:     'hhMask'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: true; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHHTelepMask
            (FileName:     'Switch'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprSwitch
            (FileName:  'Parachute'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  48; Height: 48; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprParachute
            (FileName:     'Target'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprTarget
            (FileName:   'RopeNode'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   6; Height:  6; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprRopeNode
            (FileName:   'thinking'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprQuestion
            (FileName:   'PowerBar'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 256; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprPowerBar
            (FileName:    'WindBar'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 151; Height: 17; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprWindBar
            (FileName:      'WindL'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  80; Height: 13; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprWindL
            (FileName:      'WindR'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  80; Height: 13; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprWindR
{$IFDEF USE_TOUCH_INTERFACE}
            (FileName: 'firebutton'; Path: ptButtons; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 128; Height: 128; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true), // sprFireButton
            (FileName: 'arrowup'; Path: ptButtons; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 100; Height: 100; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true), // sprArrowUp
            (FileName: 'arrowdown'; Path: ptButtons; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 100; Height: 100; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true), // sprArrowDown
            (FileName: 'arrowleft'; Path: ptButtons; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 100; Height: 100; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true), // sprArrowLeft
            (FileName: 'arrowright'; Path: ptButtons; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 100; Height: 100; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true), // sprArrowRight
            (FileName: 'forwardjump'; Path: ptButtons; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 128; Height: 128; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true), // sprAMWidget
            (FileName: 'backjump'; Path: ptButtons; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 128; Height: 128; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true), // sprJumpWidget
            (FileName: 'pause'; Path: ptButtons; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 120; Height: 100; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true), // sprPauseButton
            (FileName: 'timerbutton'; Path: ptButtons; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 128; Height: 128; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true), // sprTimerButton
            (FileName: 'targetbutton'; Path: ptButtons; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 128; Height: 128; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true), // sprTargetButton
            (FileName: 'switchbutton'; Path: ptButtons; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 128; Height: 128; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true), // sprSwitchButton
{$ENDIF}
            (FileName:      'Flake'; Path:ptCurrTheme; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprFlake
            (FileName:     'amRope'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandRope
            (FileName:  'amBazooka'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandBazooka
            (FileName:  'amShotgun'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandShotgun
            (FileName:   'amDEagle'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandDEagle
            (FileName:'amAirAttack'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandAirAttack
            (FileName: 'amBaseball'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandBaseball
            (FileName:     'Hammer'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprPHammer
            (FileName: 'amBTorch_i'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandBlowTorch
            (FileName: 'amBTorch_w'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprBlowTorch
            (FileName:   'Teleport'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprTeleport
            (FileName:    'HHDeath'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprHHDeath
            (FileName:'amShotgun_w'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprShotgun
            (FileName: 'amDEagle_w'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprDEagle
            (FileName:       'Idle'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprHHIdle
            (FileName:     'Mortar'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprMortar
            (FileName:  'TurnsLeft'; Path: ptAmmoMenu; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprTurnsLeft
            (FileName: 'amKamikaze'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 128; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprKamikaze
            (FileName:     'amWhip'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 128; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprWhip
            (FileName:     'Kowtow'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprKowtow
            (FileName:        'Sad'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprSad
            (FileName:       'Wave'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprWave
            (FileName:     'Hurrah'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprHurrah
            (FileName:'ILoveLemonade';Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 128; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprLemonade
            (FileName:      'Shrug'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 32;  Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprShrug
            (FileName:     'Juggle'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 32;  Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprJuggle
            (FileName:   'ExplPart'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprExplPart
            (FileName:  'ExplPart2'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprExplPart2
            (FileName:  'Cake_walk'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprCakeWalk
            (FileName:  'Cake_down'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprCakeDown
            (FileName: 'Watermelon'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprWatermelon
            (FileName:  'EvilTrace'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprEvilTrace
            (FileName:'HellishBomb'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHellishBomb
            (FileName:  'Seduction'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprSeduction
            (FileName:    'HHDress'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprDress
            (FileName:   'Censored'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprCensored
            (FileName:      'Drill'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprDrill
            (FileName:    'amDrill'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandDrill
            (FileName:  'amBallgun'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandBallgun
            (FileName:      'Balls'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 20; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprBalls
            (FileName:    'RCPlane'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprPlane
            (FileName:  'amRCPlane'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandPlane
            (FileName:    'Utility'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  48; Height: 48; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprUtility
            (FileName:'Invulnerable';Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  48; Height: 48; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprInvulnerable
            (FileName:   'Vampiric'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  48; Height: 48; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprVampiric
            (FileName:   'amGirder'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 512; Height:512; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprGirder
            (FileName:'SpeechCorner';Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  12; Height: 9; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprSpeechCorner
            (FileName: 'SpeechEdge'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  25; Height: 9; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprSpeechEdge
            (FileName: 'SpeechTail'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  25; Height: 26; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprSpeechTail
            (FileName:'ThoughtCorner';Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  49; Height: 37; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprThoughtCorner
            (FileName:'ThoughtEdge'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  23; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprThoughtEdge
            (FileName:'ThoughtTail'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  45; Height: 65; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprThoughtTail
            (FileName:'ShoutCorner'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  34; Height: 23; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprShoutCorner
            (FileName:  'ShoutEdge'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  30; Height: 20; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprShoutEdge
            (FileName:  'ShoutTail'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  30; Height: 37; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprShoutTail
            (FileName:'amSniperRifle';Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 128; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprSniperRifle
            (FileName:    'Bubbles'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprBubbles
            (FileName:  'amJetpack'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprJetpack
            (FileName:  'Health'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprHealth
            (FileName:  'amMolotov'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),//sprHandMolotov
            (FileName:  'Molotov'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprMolotov
            (FileName: 'Smoke'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  22; Height: 22; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprSmoke
            (FileName: 'SmokeWhite'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  22; Height: 22; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprSmokeWhite
            (FileName: 'Shells'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  8; Height: 8; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpLow; getDimensions: false; getImageDimensions: true),// sprShell
            (FileName: 'Dust'; Path: ptCurrTheme; AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width:  22; Height: 22; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprDust
            (FileName: 'SnowDust'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  22; Height: 22; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprSnowDust
            (FileName: 'Explosives'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  48; Height: 48; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprExplosives
            (FileName: 'ExplosivesRoll'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  48; Height: 48; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprExplosivesRoll
            (FileName: 'amTeleport'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprAmTeleport
            (FileName: 'Splash'; Path: ptCurrTheme; AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width:  80; Height: 50; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprSplash
            (FileName: 'Droplet'; Path: ptCurrTheme; AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprDroplet
            (FileName: 'Birdy'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  75; Height: 75; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprBirdy
            (FileName:  'amCake'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandCake
            (FileName:  'amConstruction'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandConstruction
            (FileName:  'amGrenade'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandGrenade
            (FileName:  'amMelon'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandMelon
            (FileName:  'amMortar'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandMortar
            (FileName:  'amSkip'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandSkip
            (FileName:  'amCluster'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandCluster
            (FileName:  'amDynamite'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandDynamite
            (FileName:  'amHellish'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandHellish
            (FileName:  'amMine'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandMine
            (FileName:  'amSeduction'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandSeduction
            (FileName:  'amVamp'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  128; Height: 128; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandVamp
            (FileName:  'BigExplosion'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  385; Height: 385; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprBigExplosion
            (FileName:  'SmokeRing'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  200; Height: 200; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprSmokeRing
            (FileName:  'BeeTrace'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprBeeTrace
            (FileName:  'Egg'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprEgg
            (FileName:  'TargetBee'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: true; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprTargetBee
            (FileName:  'amBee'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  128; Height: 128; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandBee
            (FileName:  'Feather'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  15; Height: 25; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprFeather
            (FileName:  'Piano'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  128; Height: 128; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprPiano
            (FileName:  'amSineGun'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  128; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandSineGun
            (FileName:  'amPortalGun'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 128; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprPortalGun
            (FileName:  'Portal'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprPortal
            (FileName:  'cheese'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprCheese
            (FileName:  'amCheese'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandCheese
            (FileName:  'amFlamethrower'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  128; Height: 128; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandFlamethrower
            (FileName:  'Chunk'; Path: ptCurrTheme; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: false; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprChunk
            (FileName:  'Note'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprNote
            (FileName:   'SMineOff'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   8; Height:  8; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprSMineOff
            (FileName:    'SMineOn'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   8; Height:  8; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprSMineOn
            (FileName:   'amSMine'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandSMine
            (FileName:  'amHammer'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 128; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true), // sprHammer
            (FileName: 'amResurrector'; Path: ptHedgehog; AltPath: ptNone;
                Texture: nil; Surface: nil; Width: 32; Height: 32;
                imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority:
                tpMedium; getDimensions: false; getImageDimensions: true),
            //sprHandResurrector
            (FileName: 'Cross'; Path: ptGraphics; AltPath: ptNone;
                Texture: nil; Surface: nil; Width: 108; Height: 138;
                imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority:
                tpMedium; getDimensions: false; getImageDimensions: true),
            //sprCross
            (FileName:  'AirDrill'; Path: ptGraphics; AltPath: ptNone;
                Texture: nil; Surface: nil; Width:  16; Height: 16;
                imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority:
                tpMedium; getDimensions: false; getImageDimensions: true),
            // sprAirDrill
            (FileName:  'NapalmBomb'; Path: ptGraphics; AltPath: ptNone;
                Texture: nil; Surface: nil; Width:  16; Height: 16;
                imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority:
                tpMedium; getDimensions: false; getImageDimensions: true),
            // sprNapalmBomb
            (FileName:  'BulletHit'; Path: ptGraphics; AltPath: ptNone;
                Texture: nil; Surface: nil; Width:  32; Height: 32;
                imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority:
                tpMedium; getDimensions: false; getImageDimensions: true),
            // sprBulletHit
            (FileName:  'Snowball'; Path: ptCurrTheme; AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprSnowball
            (FileName:  'amSnowball'; Path: ptCurrTheme; AltPath: ptHedgehog; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandSnowball
            (FileName:  'Snow'; Path: ptCurrTheme; AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width:  4; Height: 4; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: true; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprSnow
            (FileName:    'SDFlake'; Path: ptCurrTheme; AltPath: ptSuddenDeath; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprSDFlake
            (FileName:    'SDWater'; Path: ptCurrTheme; AltPath: ptSuddenDeath; Texture: nil; Surface: nil;
            Width:   0; Height:  -2; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: true; getImageDimensions: true),// sprSDWater
            (FileName:   'SDClouds'; Path: ptCurrTheme; AltPath: ptSuddenDeath; Texture: nil; Surface: nil;
            Width: 256; Height:128; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprSDCloud
            (FileName:   'SDSplash'; Path: ptCurrTheme; AltPath: ptSuddenDeath; Texture: nil; Surface: nil;
            Width:  80; Height: 50; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprSDSplash
            (FileName:  'SDDroplet'; Path: ptCurrTheme; AltPath: ptSuddenDeath; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprSDDroplet
            (FileName:  'Timebox'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  50; Height: 81; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprTardis
            (FileName:  'slider'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 3; Height: 17; imageWidth: 3; imageHeight: 17; saveSurf: false; critical: true; checkSum: false; priority: tpLow; getDimensions: false; getImageDimensions: false), // sprSlider
            (FileName:  'botlevels'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 22; Height: 15; imageWidth: 22; imageHeight: 15; saveSurf: true; critical: true; checkSum: false; priority: tpLow; getDimensions: false; getImageDimensions: false), // sprBotlevels
            (FileName:  'amCleaver'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 64; imageHeight: 64; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: false),// sprHandKnife
            (FileName:  'cleaver'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 64; Height: 64; imageWidth: 64; imageHeight: 128; saveSurf: false; critical: true; checkSum: false; priority: tpLow; getDimensions: false; getImageDimensions: false), // sprKnife
            (FileName:  'star'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 12; Height: 12; imageWidth: 12; imageHeight: 12; saveSurf: false; critical: true; checkSum: false; priority: tpLow; getDimensions: false; getImageDimensions: false), // sprStar
            (FileName:  'icetexture'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 128; Height: 128; imageWidth: 128; imageHeight: 128; saveSurf: true; critical: true; checkSum: false; priority: tpLow; getDimensions: false; getImageDimensions: true), // sprIceTexture
            (FileName:  'amIceGun'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 32; Height: 32; imageWidth: 32; imageHeight: 32; saveSurf: false; critical: true; checkSum: false; priority: tpLow; getDimensions: false; getImageDimensions: false), // sprIceGun
            (FileName:  'amFrozenHog'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 64; Height: 64; imageWidth: 64; imageHeight: 64; saveSurf: false; critical: true; checkSum: false; priority: tpLow; getDimensions: false; getImageDimensions: false), // sprFrozenHog
            (FileName:   'amRubber'; Path: ptCurrTheme; AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width: 160; Height:160; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: true; priority: tpMedium; getDimensions: false; getImageDimensions: true), // sprAmRubber
            (FileName:  'boing'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 101; Height: 97; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpLow; getDimensions: false; getImageDimensions: false), // sprBoing
            (FileName:       'custom1'; Path: ptCurrTheme;AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width:   0; Height:  0; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: true; priority: tpLow; getDimensions: true; getImageDimensions: true), // sprCustom1
            (FileName:       'custom2'; Path: ptCurrTheme;AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width:   0; Height:  0; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: true; priority: tpLow; getDimensions: true; getImageDimensions: true), // sprCustom2
            (FileName:       'custom3'; Path: ptCurrTheme;AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width:   0; Height:  0; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: true; priority: tpLow; getDimensions: true; getImageDimensions: true), // sprCustom3
            (FileName:       'custom4'; Path: ptCurrTheme;AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width:   0; Height:  0; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: true; priority: tpLow; getDimensions: true; getImageDimensions: true), // sprCustom4
            (FileName:       'custom5'; Path: ptCurrTheme;AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width:   0; Height:  0; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: true; priority: tpLow; getDimensions: true; getImageDimensions: true), // sprCustom5
            (FileName:       'custom6'; Path: ptCurrTheme;AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width:   0; Height:  0; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: true; priority: tpLow; getDimensions: true; getImageDimensions: true), // sprCustom6
            (FileName:       'custom7'; Path: ptCurrTheme;AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width:   0; Height:  0; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: true; priority: tpLow; getDimensions: true; getImageDimensions: true), // sprCustom7
            (FileName:       'custom8'; Path: ptCurrTheme;AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width:   0; Height:  0; imageWidth: 0; imageHeight: 0; saveSurf: true; critical: true; checkSum: true; priority: tpLow; getDimensions: true; getImageDimensions: true), // sprCustom8
            (FileName:      'FrozenAirMine'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 32; imageHeight: 32; saveSurf: true; critical: true; checkSum: true; priority: tpHighest; getDimensions: false; getImageDimensions: true), // sprFrozenAirMine
            (FileName:      'AirMine'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpHighest; getDimensions: false; getImageDimensions: true), // sprAirMine
            (FileName:  'amAirMine'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true), // sprHandAirMine
            (FileName:      'FlakeL'; Path:ptCurrTheme; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: false; checkSum: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprFlakeL
            (FileName:    'SDFlakeL'; Path: ptCurrTheme; AltPath: ptSuddenDeath; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: false; checkSum: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprSDFlakeL
            (FileName:     'CloudsL'; Path: ptCurrTheme;AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width: 256; Height:128; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: false; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprCloudL
            (FileName:     'SDCloudsL'; Path: ptCurrTheme;AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width: 256; Height:128; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: false; checkSum: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprSDCloudL
            // TODO: Rename creeper image
            (FileName:     'Duck'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprCreeper
            // TODO: Rename creeper hand image
            (FileName:    'amDuck'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true), // sprHandCreeper
            (FileName: 'amMinigun'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; critical: true; checkSum: false; priority: tpMedium; getDimensions: false; getImageDimensions: true) // sprMinigun
            );

const
    Wavez: array [TWave] of record
            Sprite: TSprite;
            FramesCount: Longword;
            Interval: Longword;
            cmd: string[31];
            Voice: TSound;
            VoiceDelay: LongWord;
            end = (
            (Sprite:   sprKowtow; FramesCount: 12; Interval: 125; cmd: '/rollup'; Voice: sndNone; VoiceDelay: 0),
            (Sprite:      sprSad; FramesCount: 14; Interval: 125; cmd: '/sad'; Voice: sndNone; VoiceDelay: 0),
            (Sprite:     sprWave; FramesCount: 16; Interval: 125; cmd: '/wave'; Voice: sndHello; VoiceDelay: 5),
            (Sprite:   sprHurrah; FramesCount: 14; Interval: 125; cmd: '/hurrah'; Voice: sndNone; VoiceDelay: 0),
            (Sprite: sprLemonade; FramesCount: 24; Interval: 125; cmd: '/ilovelotsoflemonade'; Voice: sndNone; VoiceDelay: 0),
            (Sprite:    sprShrug; FramesCount: 24; Interval: 125; cmd: '/shrug'; Voice: sndNone; VoiceDelay: 0),
            (Sprite:   sprJuggle; FramesCount: 49; Interval:  38; cmd: '/juggle'; Voice: sndNone; VoiceDelay: 0)
            );

type
    TAmmozRec = record
            NameId: TAmmoStrId;
            NameTex: PTexture;
            Probability, NumberInCase: Longword;
            Ammo: TAmmo;
            Slot: 0..cMaxSlotIndex;
            TimeAfterTurn: Longword;
            minAngle, maxAngle: Longword;
            isDamaging: boolean;
            SkipTurns: LongWord;
            PosCount: Longword;
            PosSprite: TSprite;
            ejectX, ejectY: Longint;
            end;
    TAmmoCounts = array[TAmmoType] of Longword;

var
    Ammoz: array [TAmmoType] of TAmmozRec;
    InitialAmmoCounts: TAmmoCounts;

const
    AmmozInit: array [TAmmoType] of TAmmozRec = (
            (NameId: sidNothing;
            NameTex: nil;
            Probability: 0;
            NumberInCase: 0;
            Ammo: (Propz: ammoprop_NoCrosshair or ammoprop_DontHold or ammoprop_Effect;
                Count: AMMO_INFINITE;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amNothing;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: cHiddenSlotIndex;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: false;
            SkipTurns: 9999;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Grenade
            (NameId: sidGrenade;
            NameTex: nil;
            Probability: 0;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_Timerable or
                          ammoprop_Power or
                          ammoprop_AltUse or
                          ammoprop_SetBounce or
                          ammoprop_NeedUpDown;
                Count: AMMO_INFINITE;
                NumPerTurn: 0;
                Timer: 3000;
                Pos: 0;
                AmmoType: amGrenade;
                AttackVoice: sndCover;
                Bounciness: defaultBounciness);
            Slot: 1;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// ClusterBomb
            (NameId: sidClusterBomb;
            NameTex: nil;
            Probability: 100;
            NumberInCase: 3;
            Ammo: (Propz: ammoprop_Timerable or
                          ammoprop_Power or
                          ammoprop_AltUse or
                          ammoprop_SetBounce or
                          ammoprop_NeedUpDown;
                Count: 5;
                NumPerTurn: 0;
                Timer: 3000;
                Pos: 0;
                AmmoType: amClusterBomb;
                AttackVoice: sndCover;
                Bounciness: defaultBounciness);
            Slot: 1;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Bazooka
            (NameId: sidBazooka;
            NameTex: nil;
            Probability: 0;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_Power or
                          ammoprop_AltUse or
                          ammoprop_NeedUpDown;
                Count: AMMO_INFINITE;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amBazooka;
                AttackVoice: sndFire;
                Bounciness: defaultBounciness);
            Slot: 0;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0; //20;
            ejectY: -6),

// Bee
            (NameId: sidBee;
            NameTex: nil;
            Probability: 100;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_Power or
                          ammoprop_NeedTarget or
                          ammoprop_NoTargetAfter or
                          ammoprop_DontHold or
                          ammoprop_NeedUpDown;
                Count: 2;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amBee;
                AttackVoice: sndFire;
                Bounciness: defaultBounciness);
            Slot: 0;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 2;
            PosSprite: sprTargetBee;
            ejectX: 0; //16;
            ejectY: 0),

// Shotgun
            (NameId: sidShotgun;
            NameTex: nil;
            Probability: 0;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_ForwMsgs or
                          ammoprop_NeedUpDown or
                          ammoprop_DoesntStopTimerInMultiShoot;
                Count: AMMO_INFINITE;
                NumPerTurn: 1;
                Timer: 0;
                Pos: 0;
                AmmoType: amShotgun;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 2;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0; //26;
            ejectY: -6),

// PickHammer
            (NameId: sidPickHammer;
            NameTex: nil;
            Probability: 0;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_ForwMsgs or
                          ammoprop_AttackInMove or
                          ammoprop_NoCrosshair or
                          ammoprop_DontHold or
                          ammoprop_DoesntStopTimerWhileAttackingInInfAttackMode;
                Count: 2;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amPickHammer;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 6;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: false;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Skip
            (NameId: sidSkip;
            NameTex: nil;
            Probability: 0;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoCrosshair or
                          ammoprop_AttackInMove or
                          ammoprop_DontHold or
                          ammoprop_ForceTurnEnd;
                Count: AMMO_INFINITE;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amSkip;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 9;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: false;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Rope
            (NameId: sidRope;
            NameTex: nil;
            Probability: 100;
            NumberInCase: 3;
            Ammo: (Propz: ammoprop_NoRoundEnd or
                          ammoprop_ForwMsgs or
                          ammoprop_AttackInMove or
                          ammoprop_Utility or
                          ammoprop_AltAttack or
                          ammoprop_NeedUpDown or
                          ammoprop_DoesntStopTimerWhileAttacking;
                    Count: 5;
                    NumPerTurn: 0;
                    Timer: 0;
                    Pos: 0;
                    AmmoType: amRope;
                    AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 7;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: cMaxAngle div 2;
            isDamaging: false;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Mine
            (NameId: sidMine;
            NameTex: nil;
            Probability: 100;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoCrosshair or
                          ammoprop_AttackInMove or
                          ammoprop_DontHold or
                          ammoprop_AltUse or
                          ammoprop_SetBounce;
                Count: 2;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amMine;
                AttackVoice: sndLaugh;
                Bounciness: defaultBounciness);
            Slot: 4;
            TimeAfterTurn: 5000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// DEagle
            (NameId: sidDEagle;
            NameTex: nil;
            Probability: 20;
            NumberInCase: 2;
            Ammo: (Propz: ammoprop_NeedUpDown or ammoprop_DoesntStopTimerInMultiShoot;
                Count: 3;
                NumPerTurn: 3;
                Timer: 0;
                Pos: 0;
                AmmoType: amDEagle;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 2;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0; //23;
            ejectY: -6),

// Dynamite
            (NameId: sidDynamite;
            NameTex: nil;
            Probability: 100;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoCrosshair or
                          ammoprop_AttackInMove or
                          ammoprop_DontHold or
                          ammoprop_AltUse;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amDynamite;
                AttackVoice: sndLaugh;
                Bounciness: defaultBounciness);
            Slot: 4;
            TimeAfterTurn: 5000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// FirePunch
            (NameId: sidFirePunch;
            NameTex: nil;
            Probability: 0;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoCrosshair or
                          ammoprop_ForwMsgs or
                          ammoprop_AttackInMove;
                Count: AMMO_INFINITE;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amFirePunch;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 3;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Whip
            (NameId: sidWhip;
            NameTex: nil;
            Probability: 0;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoCrosshair;
                Count: AMMO_INFINITE;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amWhip;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 3;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// BaseballBat
            (NameId: sidBaseballBat;
            NameTex: nil;
            Probability: 100;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_DontHold or
                          ammoprop_NeedUpDown;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amBaseballBat;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 3;
            TimeAfterTurn: 5000;
            minAngle: 0;
            maxAngle: cMaxAngle div 2;
            isDamaging: true;
            SkipTurns: 2;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Parachute
            (NameId: sidParachute;
            NameTex: nil;
            Probability: 100;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoRoundEnd or
                          ammoprop_ForwMsgs or
                          ammoprop_AttackInMove or
                          ammoprop_NoCrosshair or
                          ammoprop_DontHold or
                          ammoprop_Utility or
                          ammoprop_AltAttack or
                          ammoprop_NeedUpDown;
                Count: 2;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amParachute;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 7;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: false;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// AirAttack
            (NameId: sidAirAttack;
            NameTex: nil;
            Probability: 100;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoCrosshair or
                          ammoprop_NeedTarget or
                          ammoprop_AttackingPut or
                          ammoprop_DontHold or
                          ammoprop_NotBorder;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amAirAttack;
                AttackVoice: sndIncoming;
                Bounciness: defaultBounciness);
            Slot: 5;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 5;
            PosCount: 2;
            PosSprite: sprAmAirplane;
            ejectX: 0;
            ejectY: 0),

// MineStrike
            (NameId: sidMineStrike;
            NameTex: nil;
            Probability: 200;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoCrosshair or
                          ammoprop_NeedTarget or
                          ammoprop_AttackingPut or
                          ammoprop_DontHold or
                          ammoprop_NotBorder;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amMineStrike;
                AttackVoice: sndIncoming;
                Bounciness: defaultBounciness);
            Slot: 5;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 5;
            PosCount: 2;
            PosSprite: sprAmAirplane;
            ejectX: 0;
            ejectY: 0),

// BlowTorch
            (NameId: sidBlowTorch;
            NameTex: nil;
            Probability: 100;
            NumberInCase: 2;
            Ammo: (Propz: ammoprop_ForwMsgs or
                          ammoprop_NeedUpDown or
                          ammoprop_DoesntStopTimerWhileAttackingInInfAttackMode;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amBlowTorch;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 6;
            TimeAfterTurn: 3000;
            minAngle: 804;
            maxAngle: 1327;
            isDamaging: false;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Girder
            (NameId: sidGirder;
            NameTex: nil;
            Probability: 150;
            NumberInCase: 3;
            Ammo: (Propz: ammoprop_NoRoundEnd or
                          ammoprop_NoCrosshair or
                          ammoprop_NeedTarget or
                          ammoprop_Utility or
                          ammoprop_AttackingPut;
                    Count: 1;
                    NumPerTurn: 0;
                    Timer: 0;
                    Pos: 0;
                    AmmoType: amGirder;
                    AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 6;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: false;
            SkipTurns: 0;
            PosCount: 8;
            PosSprite: sprAmGirder;
            ejectX: 0;
            ejectY: 0),

// Teleport
            (NameId: sidTeleport;
            NameTex: nil;
            Probability: 200;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_ForwMsgs or
                          ammoprop_NoCrosshair or
                          ammoprop_NeedTarget or
                          ammoprop_AttackingPut or
                          ammoprop_Utility or
                          ammoprop_DontHold;
                Count: 2;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amTeleport;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 7;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: false;
            SkipTurns: 0;
            PosCount: 2;
            PosSprite: sprAmTeleport;
            ejectX: 0;
            ejectY: 0),

// Switch
            (NameId: sidSwitch;
            NameTex: nil;
            Probability: 100;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoRoundEnd or
                          ammoprop_ForwMsgs or
                          ammoprop_NoCrosshair or
                          ammoprop_Utility or
                          ammoprop_DontHold;
                    Count: 3;
                    NumPerTurn: 0;
                    Timer: 0;
                    Pos: 0;
                    AmmoType: amSwitch;
                    AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 9;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: false;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Mortar
            (NameId: sidMortar;
            NameTex: nil;
            Probability: 100;
            NumberInCase: 4;
            Ammo: (Propz: ammoprop_NeedUpDown;
                Count: 4;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amMortar;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 0;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0; //20;
            ejectY: -6),

// Kamikaze
            (NameId: sidKamikaze;
            NameTex: nil;
            Probability: 100;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_ForwMsgs or
                          ammoprop_DontHold or
                          ammoprop_NeedUpDown or
                          ammoprop_AttackInMove or
                          ammoprop_ForceTurnEnd;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amKamikaze;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 3;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Cake
            (NameId: sidCake;
            NameTex: nil;
            Probability: 100;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_ForwMsgs or
                          ammoprop_NoCrosshair or
                          ammoprop_DontHold or
                          ammoprop_Track;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amCake;
                AttackVoice: sndLaugh;
                Bounciness: defaultBounciness);
            Slot: 4;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 4;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Seduction
            (NameId: sidSeduction;
            NameTex: nil;
            Probability: 100;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_ForwMsgs or
                          ammoprop_DontHold or
                          ammoprop_NoCrosshair;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amSeduction;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 3;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: false;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Watermelon
            (NameId: sidWatermelon;
            NameTex: nil;
            Probability: 400;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_Timerable or
                          ammoprop_Power or
                          ammoprop_NeedUpDown or
                          ammoprop_AltUse;
                Count: 0;
                NumPerTurn: 0;
                Timer: 3000;
                Pos: 0;
                AmmoType: amWatermelon;
                AttackVoice: sndMelon;
                Bounciness: defaultBounciness);
            Slot: 1;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// HellishBomb ("Hellish Hand-Grenade")
            (NameId: sidHellishBomb;
            NameTex: nil;
            Probability: 400;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_Power or
                          ammoprop_NeedUpDown or
                          ammoprop_AltUse;
                Count: 0;
                NumPerTurn: 0;
                Timer: 5000;
                Pos: 0;
                AmmoType: amHellishBomb;
                AttackVoice: sndWatchThis;
                Bounciness: defaultBounciness);
            Slot: 1;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Napalm
            (NameId: sidNapalm;
            NameTex: nil;
            Probability: 100;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoCrosshair or
                          ammoprop_NeedTarget or
                          ammoprop_AttackingPut or
                          ammoprop_DontHold or
                          ammoprop_NotBorder;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amNapalm;
                AttackVoice: sndIncoming;
                Bounciness: defaultBounciness);
            Slot: 5;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 7;
            PosCount: 2;
            PosSprite: sprAmAirplane;
            ejectX: 0;
            ejectY: 0),

// Drill ("Drill Rocket")
            (NameId: sidDrill;
            NameTex: nil;
            Probability: 300;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_Power or
                          ammoprop_NeedUpDown or
                          ammoprop_AltUse;
                Count: AMMO_INFINITE;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amDrill;
                AttackVoice: sndFire;
                Bounciness: defaultBounciness);
            Slot: 0;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprDrill;
            ejectX: 0; //20;
            ejectY: -6),

// Ballgun
            (NameId: sidBallgun;
            NameTex: nil;
            Probability: 400;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_ForwMsgs or
                          ammoprop_NeedUpDown or
                          ammoprop_DontHold;
                Count: AMMO_INFINITE;
                NumPerTurn: 0;
                Timer: 5001;
                Pos: 0;
                AmmoType: amBallgun;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 4;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0; //20;
            ejectY: -3),

// RC-Plane
            (NameId: sidRCPlane;
            NameTex: nil;
            Probability: 200;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_ForwMsgs or
                          ammoprop_NeedUpDown{ or
                          ammoprop_DontHold or
                          ammoprop_AltAttack};
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amRCPlane;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 4;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 4;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// LowGravity
            (NameId: sidLowGravity;
            NameTex: nil;
            Probability: 20;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoRoundEnd or
                          ammoprop_NoCrosshair or
                          ammoprop_DontHold or
                          ammoprop_AltUse or
                          ammoprop_Utility or
                          ammoprop_Effect;
                    Count: 1;
                    NumPerTurn: 0;
                    Timer: 0;
                    Pos: 0;
                    AmmoType: amLowGravity;
                    AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 9;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: false;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// ExtraDamage
            (NameId: sidExtraDamage;
            NameTex: nil;
            Probability: 15;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoRoundEnd or
                          ammoprop_NoCrosshair or
                          ammoprop_DontHold or
                          ammoprop_AltUse or
                          ammoprop_Utility or
                          ammoprop_Effect;
                    Count: 1;
                    NumPerTurn: 0;
                    Timer: 0;
                    Pos: 0;
                    AmmoType: amExtraDamage;
                    AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 9;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: false;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Invulnerable
            (NameId: sidInvulnerable;
            NameTex: nil;
            Probability: 20;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoRoundEnd or
                          ammoprop_NoCrosshair or
                          ammoprop_DontHold or
                          ammoprop_AltUse or
                          ammoprop_Utility or
                          ammoprop_Effect;
                    Count: 1;
                    NumPerTurn: 0;
                    Timer: 0;
                    Pos: 0;
                    AmmoType: amInvulnerable;
                    AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 8;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: false;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// ExtraTime
            (NameId: sidExtraTime;
            NameTex: nil;
            Probability: 30;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoRoundEnd or
                          ammoprop_NoCrosshair or
                          ammoprop_DontHold or
                          ammoprop_AltUse or
                          ammoprop_Utility or
                          ammoprop_Effect;
                    Count: 1;
                    NumPerTurn: 0;
                    Timer: 0;
                    Pos: 0;
                    AmmoType: amExtraTime;
                    AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 9;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: false;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// LaserSight
            (NameId: sidLaserSight;
            NameTex: nil;
            Probability: 15;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoRoundEnd or
                          ammoprop_NoCrosshair or
                          ammoprop_DontHold or
                          ammoprop_AltUse or
                          ammoprop_Utility or
                          ammoprop_NeedUpDown or
                          ammoprop_Effect;
                    Count: 1;
                    NumPerTurn: 0;
                    Timer: 0;
                    Pos: 0;
                    AmmoType: amLaserSight;
                    AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 8;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: false;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Vampiric
            (NameId: sidVampiric;
            NameTex: nil;
            Probability: 15;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoRoundEnd or
                          ammoprop_NoCrosshair or
                          ammoprop_DontHold or
                          ammoprop_AltUse or
                          ammoprop_Utility or
                          ammoprop_Effect;
                    Count: 1;
                    NumPerTurn: 0;
                    Timer: 0;
                    Pos: 0;
                    AmmoType: amVampiric;
                    AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 8;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: false;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// SniperRifle
            (NameId: sidSniperRifle;
            NameTex: nil;
            Probability: 20;
            NumberInCase: 2;
            Ammo: (Propz: ammoprop_NeedUpDown or
                    ammoprop_OscAim or
                    ammoprop_NoMoveAfter or
                    ammoprop_DoesntStopTimerInMultiShoot;
                Count: 2;
                NumPerTurn: 1;
                Timer: 0;
                Pos: 0;
                AmmoType: amSniperRifle;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 2;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0; //40;
            ejectY: -5),

// Jetpack ("Flying Saucer")
            (NameId: sidJetpack;
            NameTex: nil;
            Probability: 20;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoRoundEnd or
                          ammoprop_ForwMsgs or
                          ammoprop_AttackInMove or
                          ammoprop_DontHold or
                          ammoprop_Utility or
                          ammoprop_NeedUpDown or
                          ammoprop_AltAttack;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amJetpack;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 7;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: false;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Molotov
            (NameId: sidMolotov;
            NameTex: nil;
            Probability: 0;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_Power or
                          ammoprop_NeedUpDown or
                          ammoprop_AltUse;
                Count: AMMO_INFINITE;
                NumPerTurn: 0;
                Timer: 3000;
                Pos: 0;
                AmmoType: amMolotov;
                AttackVoice: sndWatchThis;
                Bounciness: defaultBounciness);
            Slot: 1;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Birdy
            (NameId: sidBirdy;
            NameTex: nil;
            Probability: 20;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_ForwMsgs or
                          ammoprop_NoCrosshair or
                          ammoprop_NeedUpDown or
                          ammoprop_DontHold;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amBirdy;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 7;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// PortalGun
            (NameId: sidPortalGun;
            NameTex: nil;
            Probability: 20;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoRoundEnd or
                          ammoprop_AttackInMove or
                          ammoprop_DontHold or
                          ammoprop_NeedUpDown or
                          ammoprop_Utility;
                Count: 1;
                NumPerTurn: 3;
                Timer: 0;
                Pos: 0;
                AmmoType: amPortalGun;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 7;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: false;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: -5; //29;
            ejectY: -7),

// Piano
            (NameId: sidPiano;
            NameTex: nil;
            Probability: 100;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoCrosshair or
                            ammoprop_NeedTarget or
                            ammoprop_NoTargetAfter or
                            ammoprop_AttackingPut or
                            ammoprop_DontHold or
                            ammoprop_NotBorder or
                            ammoprop_ForceTurnEnd;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amPiano;
                AttackVoice: sndIncoming;
                Bounciness: defaultBounciness);
            Slot: 5;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 7;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// GasBomb
            (NameId: sidGasBomb;
            NameTex: nil;
            Probability: 0;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_Timerable or
                          ammoprop_Power or
                          ammoprop_AltUse or
                          ammoprop_NeedUpDown or
                          ammoprop_SetBounce;
                Count: AMMO_INFINITE;
                NumPerTurn: 0;
                Timer: 3000;
                Pos: 0;
                AmmoType: amGasBomb;
                AttackVoice: sndCover;
                Bounciness: defaultBounciness);
            Slot: 1;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// SineGun
            (NameId: sidSineGun;
            NameTex: nil;
            Probability: 20;
            NumberInCase: 2;
            Ammo: (Propz: ammoprop_AttackInMove or
                          ammoprop_NeedUpDown;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amSineGun;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 2;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Flamethrower
            (NameId: sidFlamethrower;
            NameTex: nil;
            Probability: 20;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_ForwMsgs or
                          ammoprop_NeedUpDown or
                          ammoprop_DontHold;
                Count: 1;
                NumPerTurn: 0;
                Timer: 5001;
                Pos: 0;
                AmmoType: amFlamethrower;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 2;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0; //20;
            ejectY: -3),

// Sticky Mine
            (NameId: sidSMine;
            NameTex: nil;
            Probability: 100;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_Power or
                          ammoprop_AltUse or
                          ammoprop_NeedUpDown;
                Count: 1;
                NumPerTurn: 1;
                Timer: 0;
                Pos: 0;
                AmmoType: amSMine;
                AttackVoice: sndLaugh;
                Bounciness: defaultBounciness);
            Slot: 4;
            TimeAfterTurn: 5000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Hammer
            (NameId: sidHammer;
            NameTex: nil;
            Probability: 0;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoCrosshair;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amHammer;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 3;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Resurrector
        (NameId: sidResurrector;
            NameTex: nil;
            Probability: 0;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoCrosshair or
                          ammoprop_Utility or
                          ammoprop_NoRoundEnd or
                          ammoprop_DoesntStopTimerWhileAttacking;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amResurrector;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 8;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// DrillStrike
            (NameId: sidDrillStrike;
            NameTex: nil;
            Probability: 200;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoCrosshair or
                            ammoprop_NeedTarget or
                            ammoprop_AttackingPut or
                            ammoprop_DontHold or
                            ammoprop_Timerable or
                            ammoprop_NotBorder;
                Count: 1;
                NumPerTurn: 0;
                Timer: 5000;
                Pos: 0;
                AmmoType: amDrillStrike;
                AttackVoice: sndIncoming;
                Bounciness: defaultBounciness);
            Slot: 5;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 6;
            PosCount: 2;
            PosSprite: sprAmAirplane;
            ejectX: 0;
            ejectY: 0),

// Snowball/Mudball
            (NameId: sidSnowball;
            NameTex: nil;
            Probability: 0;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_Power or
                          ammoprop_AltUse or
                          ammoprop_NeedUpDown or
                          ammoprop_NoRoundEnd;
                Count: 2;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amSnowball;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 0;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: false;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Tardis
            (NameId: sidTardis;
            NameTex: nil;
            Probability: 200;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_ForwMsgs or
                          ammoprop_NoCrosshair or
                          ammoprop_Utility or
                          ammoprop_DontHold or
                          ammoprop_ForceTurnEnd;
                Count: 2;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amTardis;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 8;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: false;
            SkipTurns: 0;
            PosCount: 2;
            PosSprite: sprAmTeleport;
            ejectX: 0;
            ejectY: 0),

// Land Gun
            (NameId: sidLandGun;
            NameTex: nil;
            Probability: 20;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoRoundEnd or
                          ammoprop_NeedUpDown or
                          ammoprop_Utility;
                Count: 1;
                NumPerTurn: 0;
                Timer: 5001;
                Pos: 0;
                AmmoType: amLandGun;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 6;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0; //20;
            ejectY: -3),
// Freezer
            (NameId: sidIceGun;
            NameTex: nil;
            Probability: 20;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_ForwMsgs or
                          ammoprop_NeedUpDown or
                          ammoprop_DontHold;
                Count: 1;
                NumPerTurn: 0;
                Timer: 5001;
                Pos: 0;
                AmmoType: amIceGun;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 2;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: false;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0; //20;
            ejectY: -3),
// Knife
            (NameId: sidKnife;
            NameTex: nil;
            Probability: 100;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_Power or
                          ammoprop_AltUse or
                          ammoprop_NeedUpDown;
                Count: 1;
                NumPerTurn: 1;
                Timer: 0;
                Pos: 0;
                AmmoType: amKnife;
                AttackVoice: sndWatchThis;
                Bounciness: defaultBounciness);
            Slot: 6;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),
// Rubber
            (NameId: sidRubber;
            NameTex: nil;
            Probability: 150;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoRoundEnd or
                          ammoprop_NoCrosshair or
                          ammoprop_NeedTarget or
                          ammoprop_Utility or
                          ammoprop_AttackingPut;
                    Count: 1;
                    NumPerTurn: 0;
                    Timer: 0;
                    Pos: 0;
                    AmmoType: amRubber;
                    AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 6;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: false;
            SkipTurns: 0;
            PosCount: 4;
            PosSprite: sprAmRubber;
            ejectX: 0;
            ejectY: 0),
// Air Mine
            (NameId: sidAirMine;
            NameTex: nil;
            Probability: 100;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_Power or
                          ammoprop_AltUse or
                          ammoprop_NeedUpDown;
                Count: 2;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amAirMine;
                AttackVoice: sndLaugh;
                Bounciness: defaultBounciness);
            Slot: 5;
            TimeAfterTurn: 5000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),
// Creeper
            (NameId: sidCreeper;
            NameTex: nil;
            Probability: 100;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoCrosshair or
                          ammoprop_AttackInMove or
                          ammoprop_DontHold or
                          ammoprop_AltUse;
                Count: 2;
                NumPerTurn: 0;
                Timer: 15000;
                Pos: 0;
                AmmoType: amCreeper;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 0;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 15;
            ejectY: -7),
// Minigun
            (NameId: sidMinigun;
            NameTex: nil;
            Probability: 100;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NeedUpDown;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amMinigun;
                AttackVoice: sndNone;
                Bounciness: defaultBounciness);
            Slot: 2;
            TimeAfterTurn: 3000;
            minAngle: cMaxAngle div 6;
            maxAngle: 5 * cMaxAngle div 6;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0; //23;
            ejectY: 0) //-6;
        );

var
    Land: TCollisionArray;
    LandPixels: TLandArray;
    LandDirty: TDirtyTag;
    hasBorder: boolean;
    hasGirders: boolean;
    playHeight, playWidth, leftX, rightX, topY, MaxHedgehogs: Longword;  // idea is that a template can specify height/width.  Or, a map, a height/width by the dimensions of the image.  If the map has pixels near top of image, it triggers border.
    LandBackSurface: PSDL_Surface;
    CurAmmoGear: PGear;
    lastGearByUID: PGear;
    GearsList: PGear;
    AllInactive: boolean;
    PrvInactive: boolean;
    KilledHHs: Longword;
    SuddenDeath: Boolean; // If the Sudden Death check has been made
    SuddenDeathActive: Boolean; // Is in Sudden Death with any gameplay effect
    SuddenDeathDmg: Boolean; // Is in Sudden Death with damage
    SpeechType: Longword;
    SpeechText: shortstring;
    PlacingHogs: boolean; // a convenience flag to indicate placement of hogs is still in progress
    StepSoundTimer: LongInt;
    StepSoundChannel: LongInt;

    CurrentTeam: PTeam;
    PreviousTeam: PTeam;
    CurrentHedgehog: PHedgehog;
    TeamsArray: array[0..Pred(cMaxTeams)] of PTeam;
    TeamsCount: Longword; // number of teams on game start
    VisibleTeamsCount: Longword; // number of teams visible in team bar
    ClansArray, SpawnClansArray: TClansArray;
    ClansCount: Longword;
    LocalClan: LongInt;  // last non-bot, non-extdriven clan
    LocalTeam: LongInt;  // last non-bot, non-extdriven clan first team
    LocalAmmo: LongInt;  // last non-bot, non-extdriven clan's first team's ammo index, updated to next upcoming hog for per-hog-ammo
    CurMinAngle, CurMaxAngle: Longword;

    FollowGear: PGear;
    WindBarWidth: LongInt;
    bShowAmmoMenu: boolean;
    bSelected: boolean;
    bShowFinger: boolean;
    Frames: Longword;
    WaterColor, DeepWaterColor: TSDL_Color;
    SDTint, SkyColor, RQSkyColor, SDSkyColor: TSDL_Color;
    SkyOffset: LongInt;
{$IFDEF COUNTTICKS}
    cntTicks: LongWord;
{$ENDIF}


    PauseTexture,
    AFKTexture,
    SyncTexture,
    ConfirmTexture: PTexture;
    cScaleFactor: GLfloat;
    cStereoDepth: GLfloat;
    SupportNPOTT: Boolean;
    Step: LongInt;
    MissionIcons: PSDL_Surface;
    ropeIconTex: PTexture;

    // stereoscopic framebuffer and textures
    framel, framer, depthl, depthr: GLuint;
    texl, texr: GLuint;

    // video recorder framebuffer and texture
    defaultFrame, depthv: GLuint;
    texv: GLuint;

    lastVisualGearByUID: PVisualGear;
    vobFrameTicks, vobFramesCount, vobCount: Longword;
    vobVelocity, vobFallSpeed: LongInt;
    vobSDFrameTicks, vobSDFramesCount, vobSDCount: Longword;
    vobSDVelocity, vobSDFallSpeed: LongInt;
    watFrames, watFrameTicks: Longword;
    watMove: LongInt;
    watSDFrames, watSDFrameTicks: Longword;
    watSDMove: LongInt;

    DefaultBinds : TBinds;

    lastTurnChecksum : Longword;

    mModelview: TMatrix4x4f;
    mProjection: TMatrix4x4f;
    vBuffer: GLuint; // vertex buffer
    tBuffer: GLuint; // texture coords buffer
    cBuffer: GLuint; // color buffer

    uCurrentMVPLocation: GLint;

    uMainMVPLocation: GLint;
    uMainTintLocation: GLint;

    uWaterMVPLocation: GLint;

    aVertex: GLint;
    aTexCoord: GLint;
    aColor: GLint;

var trammo:  array[TAmmoStrId] of ansistring;   // name of the weapon
    trammoc: array[TAmmoStrId] of ansistring;   // caption of the weapon
    trammod: array[TAmmoStrId] of ansistring;   // description of the weapon
    trluaammo: array[TAmmoStrId] of ansistring; // name of the weapon (Lua overwrite)
    trluaammoc: array[TAmmoStrId] of ansistring; // caption of the weapon (Lua overwrite)
    trluaammod: array[TAmmoStrId] of ansistring;  // description of the weapon (Lua overwrite)
    trluaammoa: array[TAmmoStrId] of ansistring; // description appendix of the weapon (Lua only)
    trluaammoe: array[TAmmoStrId] of boolean;   // whether to render extra text (Lua overwrite)
    trmsg:   array[TMsgStrId]  of ansistring;   // message of the event
    trgoal:  array[TGoalStrId] of ansistring;   // message of the goal
    trcmd:   array[TCmdHelpStrId] of ansistring; // chat command help
    cTestLua : Boolean;

procedure preInitModule;
procedure initModule;
procedure freeModule;

implementation

procedure preInitModule;
begin
    // initialisation flags - they are going to be overwritten by program args

    cFullscreenWidth  := 0;
    cFullscreenHeight := 0;
    cWindowedWidth    := 1024;
    cWindowedHeight   := 768;
    cScreenWidth      := cWindowedWidth;
    cScreenHeight     := cWindowedHeight;

    cShowFPS        := false;
    cAltDamage      := false;
    cTimerInterval  := 8;
    cReducedQuality := rqNone;
    cLocaleFName    := 'en.txt';
    cFullScreen     := false;

    UserPathPrefix  := '';
    ipcPort         := 0;
    recordFileName  := '';
    UserNick        := '';
    cStereoMode     := smNone;
    GrayScale       := false;
    PathPrefix      := './';
    GameType        := gmtLocal;
    cOnlyStats      := False;
    cScriptName     := '';
    cScriptParam    := '';
    cTestLua        := False;

{$IFDEF USE_VIDEO_RECORDING}
    RecPrefix          := '';
    cAVFormat          := '';
    cVideoCodec        := '';
    cVideoFramerateNum := 0;
    cVideoFramerateDen := 0;
    cVideoQuality      := 0;
    cAudioCodec        := '';
{$ENDIF}

    cTagsMask:= htTeamName or htName or htHealth;
    cPrevTagsMask:= cTagsMask;
end;

procedure initScreenSpaceVars();
begin
    // those values still are not perfect
    cLeftScreenBorder:= round(-cMinZoomLevel * cScreenWidth);
    cRightScreenBorder:= round(cMinZoomLevel * cScreenWidth + LAND_WIDTH);
    cScreenSpace:= cRightScreenBorder - cLeftScreenBorder;
end;

procedure initModule;
var s: shortstring;
    i: integer;
    t: TSound;
    a: TAmmoStrId;
begin
    // init LastVoice
    LastVoice.snd:= sndNone;
    LastVoice.voicepack:= nil;

    // init arrays
    Move(cPathzInit, cPathz, sizeof(cPathz));
    Move(FontzInit, Fontz, sizeof(Fontz));
    Move(SpritesDataInit, SpritesData, sizeof(SpritesData));
    Move(AmmozInit, Ammoz, sizeof(Ammoz));


    cLocale:= cLocaleFName;
    SplitByChar(cLocale, s, '.');

    cFlattenFlakes      := false;
    cFlattenClouds      := false;
    cIce                := false;
    cSnow               := false;
    lastVisualGearByUID := nil;
    lastGearByUID       := nil;
    cReadyDelay         := 5000;
    isInChatMode        := false;

        {*  REFERENCE
      4096 -> $FFFFF000
      2048 -> $FFFFF800
      1024 -> $FFFFFC00
       512 -> $FFFFFE00  *}
    if (cReducedQuality and rqLowRes) <> 0 then
        begin
        LAND_WIDTH:= 2048;
        LAND_HEIGHT:= 1024;
        LAND_WIDTH_MASK:= $FFFFF800;
        LAND_HEIGHT_MASK:= $FFFFFC00;
        end
    else
        begin
        LAND_WIDTH:= 4096;
        LAND_HEIGHT:= 2048;
        LAND_WIDTH_MASK:= $FFFFF000;
        LAND_HEIGHT_MASK:= $FFFFF800
        end;

    // default water
    WaterColorArray[0].r := 52;
    WaterColorArray[0].g := 60;
    WaterColorArray[0].b := 125;
    WaterColorArray[0].a := 255;
    WaterColorArray[2]:= WaterColorArray[0];
    WaterColorArray[4]:= WaterColorArray[0];
    WaterColorArray[6]:= WaterColorArray[0];
    // water surface
    WaterColorArray[1].r := 84;
    WaterColorArray[1].g := 92;
    WaterColorArray[1].b := 157;
    WaterColorArray[1].a := 255;
    WaterColorArray[3]:= WaterColorArray[1];
    WaterColorArray[5]:= WaterColorArray[1];
    WaterColorArray[7]:= WaterColorArray[1];

    WaterOpacity:= $80;

    // default clan colors
    // always keep in sync with QTfrontend/hwconsts.h

    ClanColorArray[0] := $ffff0204;
    ClanColorArray[1] := $ff4980c1;
    ClanColorArray[2] := $ff1de6ba;
    ClanColorArray[3] := $ffb541ef;
    ClanColorArray[4] := $ffe55bb0;
    ClanColorArray[5] := $ff20bf00;
    ClanColorArray[6] := $fffe8b0e;
    ClanColorArray[7] := $ff8f5902;
    ClanColorArray[8] := $ffffff01;

    // default sudden death water

    // deep water
    SDWaterColorArray[0].r := 150;
    SDWaterColorArray[0].g := 112;
    SDWaterColorArray[0].b := 169;
    SDWaterColorArray[0].a := 255;
    SDWaterColorArray[2]:= SDWaterColorArray[0];
    SDWaterColorArray[4]:= SDWaterColorArray[0];
    SDWaterColorArray[6]:= SDWaterColorArray[0];
    // water surface
    SDWaterColorArray[1].r := 182;
    SDWaterColorArray[1].g := 144;
    SDWaterColorArray[1].b := 201;
    SDWaterColorArray[1].a := 255;
    SDWaterColorArray[3]:= SDWaterColorArray[1];
    SDWaterColorArray[5]:= SDWaterColorArray[1];
    SDWaterColorArray[7]:= SDWaterColorArray[1];

    SDWaterOpacity:= $80;

    SDTint.r := $80;
    SDTint.g := $80;
    SDTint.b := $80;
    SDTint.a := $FF;

    ExplosionBorderColorR:= 80;
    ExplosionBorderColorG:= 80;
    ExplosionBorderColorB:= 80;
    ExplosionBorderColor:= $FF808080;
    ExplosionBorderColorNoA:= ExplosionBorderColor and (not AMask);
    IceColor:= ($44 shl RShift) or ($97 shl GShift) or ($A9 shl BShift) or ($A0 shl AShift);
    IceEdgeColor:= ($8A shl RShift) or ($AF shl GShift) or ($B2 shl BShift) or ($FF shl AShift);

    WaterOpacity:= $80;

    cWaveHeight             := 32;
    cDrownSpeed.QWordValue  := 257698038;   // 0.06
    cDrownSpeedf            := 0.06;
    cMaxWindSpeed.QWordValue:= 1073742;     // 0.00025
    cWindSpeed.QWordValue   := 0;           // 0.0
    cWindSpeedf             := 0.0;
    cElastic                := _0_9;
    cGravity                := cMaxWindSpeed * 2;
    cGravityf               := 0.00025 * 2;
    cLowGravity             := false;
    cBuildMaxDist           := cDefaultBuildMaxDist;
    cDamageModifier         := _1;
    TargetPoint             := cTargetPointRef;

{$IFDEF MOBILE}
    cMaxZoomLevel:= 0.5;
    cMinZoomLevel:= 3.5;
    cZoomDelta:= 0.20;
{$ELSE}
    cMaxZoomLevel:= 1.0;
    cMinZoomLevel:= 3.0;
    cZoomDelta:= 0.25;
    {$ENDIF}

    aVertex:= 0;
    aTexCoord:= 1;
    aColor:= 2;


    cMinMaxZoomLevelDelta:= cMaxZoomLevel - cMinZoomLevel;

    // int, longint longword and byte
    CursorMovementX     := 0;
    CursorMovementY     := 0;
    GameTicks           := 0;
    OuchTauntTimer      := 0;
    CheckSum            := 0;
    cWaterLine          := LAND_HEIGHT;
    cGearScrEdgesDist   := 240;

    InputMask           := $FFFFFFFF;
    GameFlags           := 0;
    WorldEdge           := weNone;
    LeftImpactTimer     := 0;
    RightImpactTimer    := 0;
    TurnTimeLeft        := 0;
    IsGetAwayTime       := false;
    GameOver            := false;
    TurnClockActive     := true;
    TagTurnTimeLeft     := 0;
    cSuddenDTurns       := 15;
    cDamagePercent      := 100;
    cRopePercent        := 100;
    cGetAwayTime        := 100;
    cMineDudPercent     := 0;
    cTemplateFilter     := 0;
    cFeatureSize        := 50;
    cMapGen             := mgRandom;
    cHedgehogTurnTime   := 45000;
    cMinesTime          := 3000;
    cMaxAIThinkTime     := 9000;
    cCloudsNumber       := 9;
    cSDCloudsNumber     := 9;
    cHealthCaseProb     := 35;
    cHealthCaseAmount   := 25;
    cWaterRise          := 47;
    cHealthDecrease     := 5;
    cAdvancedMapGenMode := false;

    InitStepsFlags  := 0;
    RealTicks       := 0;
    AttackBar       := 0; // 0 - none, 1 - just bar at the right-down corner, 2 - from weapon
    cCaseFactor     := 5;  {0..9}
    cMaxCaseDrops   := 5;
    cLandMines      := 4;
    cAirMines       := 0;
    cExplosives     := 2;

    GameState       := Low(TGameState);
    zoom            := cDefaultZoomLevel;
    ZoomValue       := cDefaultZoomLevel;
    WeaponTooltipTex:= nil;
    cLaserSighting  := false;
    cLaserSightingSniper := false;
    cVampiric       := false;
    flagMakeCapture := false;
    flagDumpLand    := false;
    bBetweenTurns   := false;
    bWaterRising    := false;
    bDuringWaterRise:= false;
    isCursorVisible := false;
    isInLag         := false;
    isPaused        := false;
    isInMultiShoot  := false;
    isSpeed         := false;
    isAFK           := false;
    isShowMission   := false;
    isForceMission  := false;
    SpeedStart      := 0;
    fastUntilLag    := false;
    fastScrolling   := false;
    autoCameraOn    := true;
    cSeed           := '';
    cIsSoundEnabled := false;
    cVolumeDelta    := 0;
    cMuteToggle     := false;
    cHasFocus       := true;
    cInactDelay     := 100;
    ReadyTimeLeft   := 0;

    disableLandBack := false;
    ScreenFade      := sfNone;
    InCinematicMode := false;
    CinematicSteps  := 0;
    CinematicBarH   := 0;
    CinematicScript := false;

    initScreenSpaceVars();

    dirtyLandTexCount:= 0;

    vobFrameTicks:= 0;
    vobFramesCount:= 4;
    vobCount:= 0;
    vobVelocity:= 10;
    vobFallSpeed:= 100;
    watFrames:= 1;
    watFrameTicks:= 0;
    watMove:= 100;

    vobSDFrameTicks:= 0;
    vobSDFramesCount:= 4;
    vobSDCount:= 30 * cScreenSpace div LAND_WIDTH;
    vobSDVelocity:= 15;
    vobSDFallSpeed:= 250;
    watSDFrames:= 1;
    watSDFrameTicks:= 0;
    watSDMove:= 100;

{$IFDEF MOBILE}
    cMinScreenWidth  := min(cScreenWidth, 480);
    cMinScreenHeight := min(cScreenHeight, 320);
{$ELSE}
    cMinScreenWidth  := min(cScreenWidth, 640);
    cMinScreenHeight := min(cScreenHeight, 480);
{$ENDIF}

    cNewScreenWidth    := cScreenWidth;
    cNewScreenHeight   := cScreenHeight;
    cScreenResizeDelay := 0;

    // make sure fullscreen resolution is always initialised somehow
    if cFullscreenWidth = 0 then
        cFullscreenWidth:= min(cWindowedWidth, 640);
    if cFullscreenHeight = 0 then
        cFullscreenHeight:= min(cWindowedHeight, 480);

    SpeechHogNumber:= -1;

    LuaGoals:= '';
    cMapName:= '';
    syncedPixelDigest:= 1;

    LuaTemplateNumber:= 0;

    LuaEndTurnRequested:= false;
    LuaNoEndTurnTaunts:= false;

    for t:= Low(TSound) to High(TSound) do
        MaskedSounds[t]:= false;

    for a:= Low(TAmmoStrId) to High(TAmmoStrId) do
        trluaammoe[a]:= true;

    UIDisplay:= uiAll;
    LocalMessage:= 0;

    cStereoDepth:= 0;
    cViewLimitsDebug:= false;
    AprilOne := false;

    // initialize pointers to nil
    // (don't rely on implicit init of fpc, because that one only happens ONCE when used as lib)
    CurAmmoGear:= nil;
    lastGearByUID:= nil;
    GearsList:= nil;
    CurrentTeam:= nil;
    PreviousTeam:= nil;
    CurrentHedgehog:= nil;
    FollowGear:= nil;
    lastVisualGearByUID:= nil;

    ChefHatTexture:= nil;
    CrosshairTexture:= nil;
    GenericHealthTexture:= nil;
    WeaponTooltipTex:= nil;
    HHTexture:= nil;
    LandBackSurface:= nil;
    ConfirmTexture:= nil;
    MissionIcons:= nil;
    ropeIconTex:= nil;

    SDLWindow:= nil;
    SDLGLContext:= nil;

    for i:= Low(ClansArray) to High(ClansArray) do
        begin
        ClansArray[i]:= nil;
        end;

    SpawnClansArray:= ClansArray;

    for i:= Low(TeamsArray) to High(TeamsArray) do
        begin
        TeamsArray[i]:= nil;
        end;

    for i:= Low(CountTexz) to High(CountTexz) do
        begin
        CountTexz[i]:= nil;
        end;

end;

procedure freeModule;
begin
end;

end.
