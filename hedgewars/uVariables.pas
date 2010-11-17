{$INCLUDE options.inc}

unit uVariables;
interface

uses SDLh, uTypes, uFloat, GLunit, uConsts, Math, uMobile, uGlobalStructs;

var
/////// init flags ///////
    cScreenWidth    : LongInt     = 1024;
    cScreenHeight   : LongInt     = 768;
    cBits           : LongInt     = 32;
    //ipcPort is in uIO
    cFullScreen     : boolean     = false;
    isSoundEnabled  : boolean     = true;
    isMusicEnabled  : boolean     = false;
    cLocaleFName    : shortstring = 'en.txt';
    cInitVolume     : LongInt     = 100;
    cTimerInterval  : LongInt     = 8;
    PathPrefix      : shortstring = './';
    cShowFPS        : boolean     = false;
    cAltDamage      : boolean     = true;
    cReducedQuality : LongWord    = rqNone;
    //userNick is in uChat
    recordFileName  : shortstring = '';
    cReadyDelay     : Longword    = 0;
    cLogfileBase    : shortstring = 'debug';
//////////////////////////
    
    isCursorVisible : boolean;
    isTerminated    : boolean;
    isInLag         : boolean;
    isPaused        : boolean;

    isSEBackup      : boolean;
    isInMultiShoot  : boolean;
    isSpeed         : boolean;
    isFirstFrame    : boolean;

    fastUntilLag    : boolean;

    GameState       : TGameState;
    GameType        : TGameType;
    GameFlags       : Longword;
    TrainingFlags   : Longword;
    TurnTimeLeft    : Longword;
    ReadyTimeLeft   : Longword;
    cSuddenDTurns   : LongInt;
    cDamagePercent  : LongInt;
    cMineDudPercent : LongWord;
    cTemplateFilter : LongInt;
    cMapGen         : LongInt;
    cMazeSize       : LongInt;

    cHedgehogTurnTime: Longword;
    cMinesTime       : LongInt;
    cMaxAIThinkTime  : Longword;

    cHealthCaseProb  : LongInt;
    cHealthCaseAmount: LongInt;
    cWaterRise       : LongInt;
    cHealthDecrease  : LongInt;

    cCloudsNumber    : LongInt;

    cTagsMask        : byte;
    zoom             : GLfloat;
    ZoomValue        : GLfloat;

    cWaterLine       : LongInt;
    cGearScrEdgesDist: LongInt;

    GameTicks   : LongWord;
    TrainingTimeInc : Longword;
    TrainingTimeInD : Longword;
    TrainingTimeInM : Longword;
    TrainingTimeMax : Longword;

    TimeTrialStartTime: Longword;
    TimeTrialStopTime : Longword;

    // originally from uConsts
    Pathz: array[TPathType] of shortstring;
    CountTexz: array[1..Pred(AMMO_INFINITE)] of PTexture;
    LAND_WIDTH       : LongInt;
    LAND_HEIGHT      : LongInt;
    LAND_WIDTH_MASK  : LongWord;
    LAND_HEIGHT_MASK : LongWord;
    cMaxCaptions     : LongInt;

    cLeftScreenBorder     : LongInt;
    cRightScreenBorder    : LongInt;
    cScreenSpace          : LongInt;

    cCaseFactor     : Longword;
    cLandMines      : Longword;
    cExplosives     : Longword;

    cSeed           : shortstring;
    cVolumeDelta    : LongInt;
    cHasFocus       : boolean;
    cInactDelay     : Longword;

    bBetweenTurns   : boolean;
    bWaterRising    : boolean;

    ShowCrosshair   : boolean;
    CursorMovementX : LongInt;
    CursorMovementY : LongInt;
    cDrownSpeed     : hwFloat;
    cDrownSpeedf    : float;
    cMaxWindSpeed   : hwFloat;
    cWindSpeed      : hwFloat;
    cWindSpeedf     : float;
    cGravity        : hwFloat;
    cGravityf       : float;
    cDamageModifier : hwFloat;
    cLaserSighting  : boolean;
    cVampiric       : boolean;
    cArtillery      : boolean;
    WeaponTooltipTex : PTexture;

    flagMakeCapture : boolean;

    InitStepsFlags  : Longword;
    RealTicks       : Longword;
    AttackBar       : LongInt;

    WaterColorArray : array[0..3] of HwColor4f;

    CursorPoint     : TPoint;
    TargetPoint     : TPoint;

    TextureList     : PTexture;

    ScreenFade      : TScreenFade;
    ScreenFadeValue : LongInt;
    ScreenFadeSpeed : LongInt;

{$IFDEF SDL13}
    SDLwindow       : PSDL_Window;
{$ENDIF}


const
    cHHFileName = 'Hedgehog';
    cCHFileName = 'Crosshair';
    cThemeCFGFilename = 'theme.cfg';

    FontBorder = 2;
    cPathz: array[TPathType] of shortstring = (
        '',                              // ptNone
        '',                              // ptData
        'Graphics',                      // ptGraphics
        'Themes',                        // ptThemes
        'Themes/avematan',               // ptCurrTheme
        'Teams',                         // ptTeams
        'Maps',                          // ptMaps
        '',                              // ptMapCurrent
        'Demos',                         // ptDemos
        'Sounds',                        // ptSounds
        'Graphics/Graves',               // ptGraves
        'Fonts',                         // ptFonts
        'Forts',                         // ptForts
        'Locale',                        // ptLocale
        'Graphics/AmmoMenu',             // ptAmmoMenu
        'Graphics/Hedgehog',             // ptHedgehog
        'Sounds/voices',                 // ptVoices
        'Graphics/Hats',                 // ptHats
        'Graphics/Flags',                // ptFlags
        'Missions/Maps'                  // ptMissionMaps
    );

    cTagsMasks : array[0..15] of byte = (7, 0, 0, 0, 15, 6, 4, 5, 0, 0, 0, 0, 0, 14, 12, 13);
    cTagsMasksNoHealth: array[0..15] of byte = (3, 2, 11, 1, 0, 0, 0, 0, 0, 10, 0, 9, 0, 0, 0, 0);

    Fontz: array[THWFont] of THHFont = (
            (Handle: nil;
            Height: 12;
            style: TTF_STYLE_NORMAL;
            Name: 'DejaVuSans-Bold.ttf'),
            (Handle: nil;
            Height: 24;
            style: TTF_STYLE_NORMAL;
            Name: 'DejaVuSans-Bold.ttf'),
            (Handle: nil;
            Height: 10;
            style: TTF_STYLE_NORMAL;
            Name: 'DejaVuSans-Bold.ttf')
            {$IFNDEF IPHONEOS}, // remove chinese fonts for now
            (Handle: nil;
            Height: 12;
            style: TTF_STYLE_NORMAL;
            Name: 'wqy-zenhei.ttc'),
            (Handle: nil;
            Height: 24;
            style: TTF_STYLE_NORMAL;
            Name: 'wqy-zenhei.ttc'),
            (Handle: nil;
            Height: 10;
            style: TTF_STYLE_NORMAL;
            Name: 'wqy-zenhei.ttc')
            {$ENDIF}
            );

    SpritesData: array[TSprite] of record
            FileName: String[16];
            Path, AltPath: TPathType;
            Texture: PTexture;
            Surface: PSDL_Surface;
            Width, Height, imageWidth, imageHeight: LongInt;
            saveSurf: boolean;
            priority: GLfloat;
            getDimensions, getImageDimensions: boolean;
            end = (
            (FileName:  'BlueWater'; Path: ptCurrTheme;AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width:   0; Height:  0; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: true; getImageDimensions: true),// sprWater
            (FileName:     'Clouds'; Path: ptCurrTheme;AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width: 256; Height:128; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprCloud
            (FileName:       'Bomb'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   8; Height:  8; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprBomb
            (FileName:  'BigDigits'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprBigDigit
            (FileName:      'Frame'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   4; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprFrame
            (FileName:        'Lag'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  65; Height: 65; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprLag
            (FileName:      'Arrow'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprCursor
            (FileName:'BazookaShell'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprBazookaShell
            (FileName:    'Targetp'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprTargetP
            (FileName:        'Bee'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprBee
            (FileName: 'SmokeTrace'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprSmokeTrace
            (FileName:   'RopeHook'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprRopeHook
            (FileName:     'Expl50'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprExplosion50
            (FileName:    'MineOff'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   8; Height:  8; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprMineOff
            (FileName:     'MineOn'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   8; Height:  8; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprMineOn
            (FileName:     'MineDead'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   8; Height:  8; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprMineDead
            (FileName:       'Case'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  48; Height: 48; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprCase
            (FileName:   'FirstAid'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  48; Height: 48; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprFAid
            (FileName:   'dynamite'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprDynamite
            (FileName:      'Power'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprPower
            (FileName:     'ClBomb'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprClusterBomb
            (FileName: 'ClParticle'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprClusterParticle
            (FileName:      'Flame'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprFlame
            (FileName:   'horizont'; Path: ptCurrTheme;AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   0; Height:  0; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: true; getImageDimensions: true),// sprHorizont
            (FileName:  'horizontL'; Path: ptCurrTheme;AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   0; Height:  0; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: true; getImageDimensions: true),// sprHorizont
            (FileName:  'horizontR'; Path: ptCurrTheme;AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   0; Height:  0; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: true; getImageDimensions: true),// sprHorizont
            (FileName:        'Sky'; Path: ptCurrTheme;AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   0; Height:  0; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: true; getImageDimensions: true),// sprSky
            (FileName:       'SkyL'; Path: ptCurrTheme;AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   0; Height:  0; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: true; getImageDimensions: true),// sprSky
            (FileName:       'SkyR'; Path: ptCurrTheme;AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   0; Height:  0; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: true; getImageDimensions: true),// sprSky
            (FileName:  'BorderHorizontal'; Path: ptAmmoMenu; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 33; Height:  2; imageWidth: 0; imageHeight: 0; saveSurf: true; priority: tpLow; getDimensions: false; getImageDimensions: true),// sprAMBorderHorizontal
            (FileName:  'BorderVertical'; Path: ptAmmoMenu; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 2; Height: 33; imageWidth: 0; imageHeight: 0; saveSurf: true; priority: tpLow; getDimensions: false; getImageDimensions: true),// sprAMBorderVertical
            (FileName:   'Slot'; Path: ptAmmoMenu; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 33; Height: 33; imageWidth: 0; imageHeight: 0; saveSurf: true; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprAMSlot
            (FileName:      'Ammos'; Path: ptAmmoMenu; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: true; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprAMAmmos
            (FileName:   'SlotKeys'; Path: ptAmmoMenu; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprAMSlotKeys
            (FileName:  'Corners'; Path: ptAmmoMenu; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  2; Height: 2; imageWidth: 0; imageHeight: 0; saveSurf: true; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprAMCorners
            (FileName:     'Finger'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 48; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprFinger
            (FileName:    'AirBomb'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprAirBomb
            (FileName:   'Airplane'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 254; Height: 101; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprAirplane
            (FileName: 'amAirplane'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprAmAirplane
            (FileName:   'amGirder'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 160; Height:160; imageWidth: 0; imageHeight: 0; saveSurf:  true; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprAmGirder
            (FileName:     'hhMask'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf:  true; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHHTelepMask
            (FileName:     'Switch'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprSwitch
            (FileName:  'Parachute'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  48; Height: 48; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprParachute
            (FileName:     'Target'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprTarget
            (FileName:   'RopeNode'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   6; Height:  6; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprRopeNode
            (FileName:   'thinking'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprQuestion
            (FileName:   'PowerBar'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 256; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprPowerBar
            (FileName:    'WindBar'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 151; Height: 17; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprWindBar
            (FileName:      'WindL'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  80; Height: 13; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprWindL
            (FileName:      'WindR'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  80; Height: 13; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprWindR
            (FileName:      'Flake'; Path:ptCurrTheme; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprFlake
            (FileName:     'amRope'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandRope
            (FileName:  'amBazooka'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandBazooka
            (FileName:  'amShotgun'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandShotgun
            (FileName:   'amDEagle'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandDEagle
            (FileName:'amAirAttack'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandAirAttack
            (FileName: 'amBaseball'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandBaseball
            (FileName:     'Hammer'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprPHammer
            (FileName: 'amBTorch_i'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandBlowTorch
            (FileName: 'amBTorch_w'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprBlowTorch
            (FileName:   'Teleport'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprTeleport
            (FileName:    'HHDeath'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprHHDeath
            (FileName:'amShotgun_w'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprShotgun
            (FileName: 'amDEagle_w'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprDEagle
            (FileName:       'Idle'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprHHIdle
            (FileName:     'Mortar'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprMortar
            (FileName:  'TurnsLeft'; Path: ptAmmoMenu; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprTurnsLeft
            (FileName: 'amKamikaze'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 256; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprKamikaze
            (FileName:     'amWhip'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 128; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprWhip
            (FileName:     'Kowtow'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprKowtow
            (FileName:        'Sad'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprSad
            (FileName:       'Wave'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprWave
            (FileName:     'Hurrah'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprHurrah
            (FileName:'ILoveLemonade';Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 128; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprLemonade
            (FileName:      'Shrug'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 32;  Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprShrug
            (FileName:     'Juggle'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 32;  Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprJuggle
            (FileName:   'ExplPart'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprExplPart
            (FileName:  'ExplPart2'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprExplPart2
            (FileName:  'Cake_walk'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprCakeWalk
            (FileName:  'Cake_down'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprCakeDown
            (FileName:   'Ammos_bw'; Path: ptAmmoMenu; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprAMAmmosBW
            (FileName: 'Watermelon'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprWatermelon
            (FileName:  'EvilTrace'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprEvilTrace
            (FileName:'HellishBomb'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHellishBomb
            (FileName:  'Seduction'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprSeduction
            (FileName:    'HHDress'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprDress
            (FileName:   'Censored'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprCensored
            (FileName:      'Drill'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprDrill
            (FileName:    'amDrill'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandDrill
            (FileName:  'amBallgun'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandBallgun
            (FileName:      'Balls'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 20; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprBalls
            (FileName:    'RCPlane'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprPlane
            (FileName:  'amRCPlane'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandPlane
            (FileName:    'Utility'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  48; Height: 48; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprUtility
            (FileName:'Invulnerable';Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  48; Height: 48; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprInvulnerable
            (FileName:   'Vampiric'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  48; Height: 48; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprVampiric
            (FileName:   'amGirder'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 512; Height:512; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprGirder
            (FileName:'SpeechCorner';Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  12; Height: 9; imageWidth: 0; imageHeight: 0; saveSurf:  true; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprSpeechCorner
            (FileName: 'SpeechEdge'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  25; Height: 9; imageWidth: 0; imageHeight: 0; saveSurf:  true; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprSpeechEdge
            (FileName: 'SpeechTail'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  25; Height: 26; imageWidth: 0; imageHeight: 0; saveSurf: true; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprSpeechTail
            (FileName:'ThoughtCorner';Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  49; Height: 37; imageWidth: 0; imageHeight: 0; saveSurf: true; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprThoughtCorner
            (FileName:'ThoughtEdge'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  23; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: true; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprThoughtEdge
            (FileName:'ThoughtTail'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  45; Height: 65; imageWidth: 0; imageHeight: 0; saveSurf: true; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprThoughtTail
            (FileName:'ShoutCorner'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  34; Height: 23; imageWidth: 0; imageHeight: 0; saveSurf: true; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprShoutCorner
            (FileName:  'ShoutEdge'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  30; Height: 20; imageWidth: 0; imageHeight: 0; saveSurf: true; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprShoutEdge
            (FileName:  'ShoutTail'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  30; Height: 37; imageWidth: 0; imageHeight: 0; saveSurf: true; priority: tpLowest; getDimensions: false; getImageDimensions: true),// sprShoutTail
            (FileName:'amSniperRifle';Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 128; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprSniperRifle
            (FileName:    'Bubbles'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprBubbles
            (FileName:  'amJetpack'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprJetpack
            (FileName:  'Health'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprHealth
            (FileName:  'amMolotov'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),//sprHandMolotov
            (FileName:  'Molotov'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprMolotov
            (FileName: 'Smoke'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  22; Height: 22; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprSmoke
            (FileName: 'SmokeWhite'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  22; Height: 22; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprSmokeWhite
            (FileName: 'Shells'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  8; Height: 8; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpLow; getDimensions: false; getImageDimensions: true),// sprShell
            (FileName: 'Dust'; Path: ptCurrTheme; AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width:  22; Height: 22; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprDust
            (FileName: 'Explosives'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  48; Height: 48; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprExplosives
            (FileName: 'ExplosivesRoll'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  48; Height: 48; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprExplosivesRoll
            (FileName: 'amTeleport'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprAmTeleport
            (FileName: 'Splash'; Path: ptCurrTheme; AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width:  80; Height: 50; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprSplash
            (FileName: 'Droplet'; Path: ptCurrTheme; AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprDroplet
            (FileName: 'Birdy'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  75; Height: 75; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprBirdy
            (FileName:  'amCake'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandCake
            (FileName:  'amConstruction'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandConstruction
            (FileName:  'amGrenade'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandGrenade
            (FileName:  'amMelon'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandMelon
            (FileName:  'amMortar'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandMortar
            (FileName:  'amSkip'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandSkip
            (FileName:  'amCluster'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandCluster
            (FileName:  'amDynamite'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandDynamite
            (FileName:  'amHellish'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandHellish
            (FileName:  'amMine'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandMine
            (FileName:  'amSeduction'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandSeduction
            (FileName:  'amVamp'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  128; Height: 128; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandVamp
            (FileName:  'BigExplosion'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  385; Height: 385; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprBigExplosion
            (FileName:  'SmokeRing'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  200; Height: 200; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprSmokeRing
            (FileName:  'BeeTrace'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHigh; getDimensions: false; getImageDimensions: true),// sprBeeTrace
            (FileName:  'Egg'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprEgg
            (FileName:  'TargetBee'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprTargetBee
            (FileName:  'amBee'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  128; Height: 128; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandBee
            (FileName:  'Feather'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  15; Height: 25; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpHighest; getDimensions: false; getImageDimensions: true),// sprFeather
            (FileName:  'Piano'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  128; Height: 128; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprPiano
            (FileName:  'amSineGun'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandSineGun
            (FileName:  'amPortalGun'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 128; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprPortalGun
            (FileName:  'Portal'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprPortal
            (FileName:  'cheese'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  16; Height: 16; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprCheese
            (FileName:  'amCheese'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandCheese
            (FileName:  'amFlamethrower'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  128; Height: 128; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandFlamethrower
            (FileName:  'Chunk'; Path: ptCurrTheme; AltPath: ptGraphics; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprChunk
            (FileName:  'Note'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  32; Height: 32; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprNote
            (FileName:   'SMineOff'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   8; Height:  8; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprSMineOff
            (FileName:    'SMineOn'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:   8; Height:  8; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprSMineOn
            (FileName:   'amSMine'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width:  64; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true),// sprHandSMine
            (FileName:  'amHammer'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
            Width: 128; Height: 64; imageWidth: 0; imageHeight: 0; saveSurf: false; priority: tpMedium; getDimensions: false; getImageDimensions: true), // sprWhip
            (FileName: 'amResurrector'; Path: ptHedgehog; AltPath: ptNone;
                Texture: nil; Surface: nil; Width: 32; Height: 32;
                imageWidth: 0; imageHeight: 0; saveSurf: false; priority:
                tpMedium; getDimensions: false; getImageDimensions: true),
            //sprHandResurrector
            (FileName: 'Cross'; Path: ptGraphics; altPath: ptNone;
                Texture: nil; Surface: nil; Width: 108; Height: 138;
                imageWidth: 0; imageHeight: 0; saveSurf: false; priority:
                tpMedium; getDimensions: false; getImageDimensions: true),
            //sprCross
            (FileName:  'AirDrill'; Path: ptGraphics; AltPath: ptNone;
                Texture: nil; Surface: nil; Width:  16; Height: 16;
                imageWidth: 0; imageHeight: 0; saveSurf: false; priority:
                tpMedium; getDimensions: false; getImageDimensions: true),
            // sprAirDrill
            (FileName:  'NapalmBomb'; Path: ptGraphics; AltPath: ptNone;
                Texture: nil; Surface: nil; Width:  16; Height: 16;
                imageWidth: 0; imageHeight: 0; saveSurf: false; priority:
                tpMedium; getDimensions: false; getImageDimensions: true),
            // sprNapalmBomb
            (FileName:  'BulletHit'; Path: ptGraphics; AltPath: ptNone;
                Texture: nil; Surface: nil; Width:  32; Height: 32;
                imageWidth: 0; imageHeight: 0; saveSurf: false; priority:
                tpMedium; getDimensions: false; getImageDimensions: true)
            // sprNapalmBomb
            );


    Wavez: array [TWave] of record
            Sprite: TSprite;
            FramesCount: Longword;
            Interval: Longword;
            cmd: String[20];
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

    Soundz: array[TSound] of record
            FileName: String[25];
            Path    : TPathType;
            end = (
            (FileName:                         ''; Path: ptNone  ),// sndNone
            (FileName:        'grenadeimpact.ogg'; Path: ptSounds),// sndGrenadeImpact
            (FileName:            'explosion.ogg'; Path: ptSounds),// sndExplosion
            (FileName:         'throwpowerup.ogg'; Path: ptSounds),// sndThrowPowerUp
            (FileName:         'throwrelease.ogg'; Path: ptSounds),// sndThrowRelease
            (FileName:               'splash.ogg'; Path: ptSounds),// sndSplash
            (FileName:        'shotgunreload.ogg'; Path: ptSounds),// sndShotgunReload
            (FileName:          'shotgunfire.ogg'; Path: ptSounds),// sndShotgunFire
            (FileName:          'graveimpact.ogg'; Path: ptSounds),// sndGraveImpact
            (FileName:             'minetick.ogg'; Path: ptSounds),// sndMineTicks
            (FileName:           'pickhammer.ogg'; Path: ptSounds),// sndPickhammer
            (FileName:                  'gun.ogg'; Path: ptSounds),// sndGun
            (FileName:                  'bee.ogg'; Path: ptSounds),// sndBee
            (FileName:                'Jump1.ogg'; Path: ptVoices),// sndJump1
            (FileName:                'Jump2.ogg'; Path: ptVoices),// sndJump2
            (FileName:                'Jump3.ogg'; Path: ptVoices),// sndJump3
            (FileName:               'Yessir.ogg'; Path: ptVoices),// sndYesSir
            (FileName:                'Laugh.ogg'; Path: ptVoices),// sndLaugh
            (FileName:            'Illgetyou.ogg'; Path: ptVoices),// sndIllGetYou
            (FileName:             'Incoming.ogg'; Path: ptVoices),// sndIncoming
            (FileName:               'Missed.ogg'; Path: ptVoices),// sndMissed
            (FileName:               'Stupid.ogg'; Path: ptVoices),// sndStupid
            (FileName:           'Firstblood.ogg'; Path: ptVoices),// sndFirstBlood
            (FileName:               'Boring.ogg'; Path: ptVoices),// sndBoring
            (FileName:               'Byebye.ogg'; Path: ptVoices),// sndByeBye
            (FileName:             'Sameteam.ogg'; Path: ptVoices),// sndSameTeam
            (FileName:               'Nutter.ogg'; Path: ptVoices),// sndNutter
            (FileName:       'Reinforcements.ogg'; Path: ptVoices),// sndReinforce
            (FileName:              'Traitor.ogg'; Path: ptVoices),// sndTraitor
            (FileName:      'Youllregretthat.ogg'; Path: ptVoices),// sndRegret
            (FileName:            'Enemydown.ogg'; Path: ptVoices),// sndEnemyDown
            (FileName:               'Coward.ogg'; Path: ptVoices),// sndCoward
            (FileName:                'Hurry.ogg'; Path: ptVoices),// sndHurry
            (FileName:              'Watchit.ogg'; Path: ptVoices),// sndWatchIt
            (FileName:             'Kamikaze.ogg'; Path: ptVoices),// sndKamikaze
            (FileName:                'cake2.ogg'; Path: ptSounds),// sndCake
            (FileName:                  'Ow1.ogg'; Path: ptVoices),// sndOw1
            (FileName:                  'Ow2.ogg'; Path: ptVoices),// sndOw2
            (FileName:                  'Ow3.ogg'; Path: ptVoices),// sndOw3
            (FileName:                  'Ow4.ogg'; Path: ptVoices),// sndOw4
            (FileName:           'Firepunch1.ogg'; Path: ptVoices),// sndFirepunch1
            (FileName:           'Firepunch2.ogg'; Path: ptVoices),// sndFirepunch2
            (FileName:           'Firepunch3.ogg'; Path: ptVoices),// sndFirepunch3
            (FileName:           'Firepunch4.ogg'; Path: ptVoices),// sndFirepunch4
            (FileName:           'Firepunch5.ogg'; Path: ptVoices),// sndFirepunch5
            (FileName:           'Firepunch6.ogg'; Path: ptVoices),// sndFirepunch6
            (FileName:                'Melon.ogg'; Path: ptVoices),// sndMelon
            (FileName:              'Hellish.ogg'; Path: ptSounds),// sndHellish
            (FileName:               'Yoohoo.ogg'; Path: ptSounds),// sndYoohoo
            (FileName:              'rcplane.ogg'; Path: ptSounds),// sndRCPlane
            (FileName:            'whipcrack.ogg'; Path: ptSounds),// sndWhipCrack
            (FileName:'ride_of_the_valkyries.ogg'; Path: ptSounds),// sndRideOfTheValkyries
            (FileName:               'denied.ogg'; Path: ptSounds),// sndDenied
            (FileName:               'placed.ogg'; Path: ptSounds),// sndPlaced
            (FileName:          'baseballbat.ogg'; Path: ptSounds),// sndBaseballBat
            (FileName:                'steam.ogg'; Path: ptSounds),// sndVaporize
            (FileName:                 'warp.ogg'; Path: ptSounds),// sndWarp
            (FileName:          'suddendeath.ogg'; Path: ptSounds),// sndSuddenDeath
            (FileName:               'mortar.ogg'; Path: ptSounds),// sndMortar
            (FileName:         'shutterclick.ogg'; Path: ptSounds),// sndShutter
            (FileName:              'homerun.ogg'; Path: ptSounds),// sndHomerun
            (FileName:              'molotov.ogg'; Path: ptSounds),// sndMolotov
            (FileName:            'Takecover.ogg'; Path: ptVoices),// sndCover
            (FileName:                'Uh-oh.ogg'; Path: ptVoices),// sndUhOh
            (FileName:                 'Oops.ogg'; Path: ptVoices),// sndOops
            (FileName:                 'Nooo.ogg'; Path: ptVoices),// sndNooo
            (FileName:                'Hello.ogg'; Path: ptVoices),// sndHello
            (FileName:             'ropeshot.ogg'; Path: ptSounds),// sndRopeShot
            (FileName:           'ropeattach.ogg'; Path: ptSounds),// sndRopeAttach
            (FileName:          'roperelease.ogg'; Path: ptSounds),// sndRopeRelease
            (FileName:            'switchhog.ogg'; Path: ptSounds),// sndSwitchHog
            (FileName:              'victory.ogg'; Path: ptVoices),// sndVictory
            (FileName:         'sniperreload.ogg'; Path: ptSounds),// sndSniperReload
            (FileName:                'steps.ogg'; Path: ptSounds),// sndSteps
            (FileName:           'lowgravity.ogg'; Path: ptSounds),// sndLowGravity
            (FileName:           'hell_growl.ogg'; Path: ptSounds),// sndHellishImpact1
            (FileName:            'hell_ooff.ogg'; Path: ptSounds),// sndHellishImpact2
            (FileName:              'hell_ow.ogg'; Path: ptSounds),// sndHellishImpact3
            (FileName:             'hell_ugh.ogg'; Path: ptSounds),// sndHellishImpact4
            (FileName:          'melonimpact.ogg'; Path: ptSounds),// sndMelonImpact
            (FileName:             'Droplet1.ogg'; Path: ptSounds),// sndDroplet1
            (FileName:             'Droplet2.ogg'; Path: ptSounds),// sndDroplet2
            (FileName:             'Droplet3.ogg'; Path: ptSounds),// sndDroplet3
            (FileName:                  'egg.ogg'; Path: ptSounds),// sndEggBreak
            (FileName:             'drillgun.ogg'; Path: ptSounds),// sndDrillRocket
            (FileName:          'PoisonCough.ogg'; Path: ptVoices),// sndPoisonCough
            (FileName:           'PoisonMoan.ogg'; Path: ptVoices),// sndPoisonMoan
            (FileName:             'BirdyLay.ogg'; Path: ptSounds),// sndBirdyLay
            (FileName:              'Whistle.ogg'; Path: ptSounds),// sndWhistle
            (FileName:             'beewater.ogg'; Path: ptSounds),// sndBeeWater
            (FileName:                   '1C.ogg'; Path: ptSounds),// sndPiano0
            (FileName:                   '2D.ogg'; Path: ptSounds),// sndPiano1
            (FileName:                   '3E.ogg'; Path: ptSounds),// sndPiano2
            (FileName:                   '4F.ogg'; Path: ptSounds),// sndPiano3
            (FileName:                   '5G.ogg'; Path: ptSounds),// sndPiano4
            (FileName:                   '6A.ogg'; Path: ptSounds),// sndPiano5
            (FileName:                   '7B.ogg'; Path: ptSounds),// sndPiano6
            (FileName:                   '8C.ogg'; Path: ptSounds),// sndPiano7
            (FileName:                   '9D.ogg'; Path: ptSounds),// sndPiano8
            (FileName:                 'skip.ogg'; Path: ptSounds),// sndSkip
            (FileName:          'shotgunfire.ogg'; Path: ptSounds),// sndSineGun
            (FileName:                'Ooff1.ogg'; Path: ptVoices),// sndOoff1
            (FileName:                'Ooff2.ogg'; Path: ptVoices),// sndOoff2
            (FileName:                'Ooff3.ogg'; Path: ptVoices),// sndOoff3
            (FileName:            'whipcrack.ogg'; Path: ptSounds),// sndWhack
            (FileName:           'Comeonthen.ogg'; Path: ptVoices),// sndComeonthen
            (FileName:            'parachute.ogg'; Path: ptSounds),// sndParachute
            (FileName:                 'bump.ogg'; Path: ptSounds),// sndBump
            (FileName: 'hogchant3.ogg'; Path: ptSounds) // sndResurrector
            );

    Ammoz: array [TAmmoType] of record
            NameId: TAmmoStrId;
            NameTex: PTexture;
            Probability, NumberInCase: Longword;
            Ammo: TAmmo;
            Slot: 0..cMaxSlotIndex;
            TimeAfterTurn: Longword;
            minAngle, maxAngle: Longword;
            isDamaging: boolean;
            SkipTurns: Longword;
            PosCount: Longword;
            PosSprite: TSprite;
            ejectX, ejectY: Longint;
            end = (
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
                AttackVoice: sndNone);
            Slot: 0;
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
            Ammo: (Propz: ammoprop_Timerable or ammoprop_Power or ammoprop_AltUse;
                Count: AMMO_INFINITE;
                NumPerTurn: 0;
                Timer: 3000;
                Pos: 0;
                AmmoType: amGrenade;
                AttackVoice: sndCover);
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
            Ammo: (Propz: ammoprop_Timerable or ammoprop_Power or ammoprop_AltUse;
                Count: 5;
                NumPerTurn: 0;
                Timer: 3000;
                Pos: 0;
                AmmoType: amClusterBomb;
                AttackVoice: sndCover);
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
            Ammo: (Propz: ammoprop_Power or ammoprop_AltUse;
                Count: AMMO_INFINITE;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amBazooka;
                AttackVoice: sndNone);
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
            Ammo: (Propz: ammoprop_Power or ammoprop_NeedTarget or ammoprop_DontHold;
                Count: 2;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amBee;
                AttackVoice: sndNone);
            Slot: 0;
            TimeAfterTurn: 3000;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0; //16;
            ejectY: 0),

// Shotgun
            (NameId: sidShotgun;
            NameTex: nil;
            Probability: 0;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_ForwMsgs;
                Count: AMMO_INFINITE;
                NumPerTurn: 1;
                Timer: 0;
                Pos: 0;
                AmmoType: amShotgun;
                AttackVoice: sndNone);
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
            Ammo: (Propz: ammoprop_ForwMsgs or ammoprop_AttackInMove or ammoprop_NoCrosshair or ammoprop_DontHold;
                Count: 2;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amPickHammer;
                AttackVoice: sndNone);
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
            Ammo: (Propz: ammoprop_NoCrosshair or ammoprop_DontHold;
                Count: AMMO_INFINITE;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amSkip;
                AttackVoice: sndNone);
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
                          ammoprop_AltAttack;
                    Count: 5;
                    NumPerTurn: 0;
                    Timer: 0;
                    Pos: 0;
                    AmmoType: amRope;
                    AttackVoice: sndNone);
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
            Ammo: (Propz: ammoprop_NoCrosshair or ammoprop_AttackInMove or ammoprop_DontHold or ammoprop_AltUse;
                Count: 2;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amMine;
                AttackVoice: sndLaugh);
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
            Ammo: (Propz: 0;
                Count: 3;
                NumPerTurn: 3;
                Timer: 0;
                Pos: 0;
                AmmoType: amDEagle;
                AttackVoice: sndNone);
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
            Ammo: (Propz: ammoprop_NoCrosshair or ammoprop_AttackInMove or ammoprop_DontHold or ammoprop_AltUse;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amDynamite;
                AttackVoice: sndLaugh);
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
            Ammo: (Propz: ammoprop_NoCrosshair or ammoprop_ForwMsgs or ammoprop_AttackInMove;
                Count: AMMO_INFINITE;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amFirePunch;
                AttackVoice: sndNone);
            Slot: 3;
            TimeAfterTurn: 3000;
            MinAngle: 0;
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
                AttackVoice: sndNone);
            Slot: 3;
            TimeAfterTurn: 3000;
            MinAngle: 0;
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
            Ammo: (Propz: ammoprop_DontHold;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amBaseballBat;
                AttackVoice: sndNone);
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
                          ammoprop_AltAttack;
                Count: 2;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amParachute;
                AttackVoice: sndNone);
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
                AttackVoice: sndIncoming);
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
                AttackVoice: sndIncoming);
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
            Ammo: (Propz: ammoprop_ForwMsgs;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amBlowTorch;
                AttackVoice: sndNone);
            Slot: 6;
            TimeAfterTurn: 3000;
            minAngle: 768;
            maxAngle: 1280;
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
                    AttackVoice: sndNone);
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
                AttackVoice: sndNone);
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
                    AttackVoice: sndNone);
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
            Ammo: (Propz: 0;
                Count: 4;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amMortar;
                AttackVoice: sndNone);
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
            Ammo: (Propz: ammoprop_ForwMsgs or ammoprop_DontHold or ammoprop_AttackInMove;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amKamikaze;
                AttackVoice: sndNone);
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
            Ammo: (Propz: ammoprop_ForwMsgs or ammoprop_NoCrosshair or ammoprop_DontHold;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amCake;
                AttackVoice: sndLaugh);
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
            Ammo: (Propz: ammoprop_ForwMsgs or ammoprop_DontHold;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amSeduction;
                AttackVoice: sndNone);
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
            Ammo: (Propz: ammoprop_Timerable or ammoprop_Power or ammoprop_AltUse;
                Count: 0;
                NumPerTurn: 0;
                Timer: 3000;
                Pos: 0;
                AmmoType: amWatermelon;
                AttackVoice: sndMelon);
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
            Ammo: (Propz:  ammoprop_Power or ammoprop_AltUse;
                Count: 0;
                NumPerTurn: 0;
                Timer: 5000;
                Pos: 0;
                AmmoType: amHellishBomb;
                AttackVoice: sndNone);
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
                AttackVoice: sndIncoming);
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
            Ammo: (Propz: ammoprop_Power or ammoprop_AltUse;
                Count: AMMO_INFINITE;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amDrill;
                AttackVoice: sndNone);
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
            Ammo: (Propz:  ammoprop_ForwMsgs or ammoprop_DontHold;
                Count: AMMO_INFINITE;
                NumPerTurn: 0;
                Timer: 5001;
                Pos: 0;
                AmmoType: amBallgun;
                AttackVoice: sndNone);
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
            Ammo: (Propz: ammoprop_ForwMsgs{ or
                            ammoprop_DontHold or
                            ammoprop_AltAttack};
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amRCPlane;
                AttackVoice: sndNone);
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
                    AttackVoice: sndNone);
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
                    AttackVoice: sndNone);
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
                    AttackVoice: sndNone);
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
                    AttackVoice: sndNone);
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
                          ammoprop_Effect;
                    Count: 1;
                    NumPerTurn: 0;
                    Timer: 0;
                    Pos: 0;
                    AmmoType: amLaserSight;
                    AttackVoice: sndNone);
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
                    AttackVoice: sndNone);
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
            Ammo: (Propz: 0;
                Count: 2;
                NumPerTurn: 1;
                Timer: 0;
                Pos: 0;
                AmmoType: amSniperRifle;
                AttackVoice: sndNone);
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
                          ammoprop_NoCrosshair or
                          ammoprop_DontHold or
                          ammoprop_Utility or
                          ammoprop_AltAttack;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amJetpack;
                AttackVoice: sndNone);
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
            Ammo: (Propz: ammoprop_Power or ammoprop_AltUse;
                Count: AMMO_INFINITE;
                NumPerTurn: 0;
                Timer: 3000;
                Pos: 0;
                AmmoType: amMolotov;
                AttackVoice: sndNone);
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
                          ammoprop_DontHold;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amBirdy;
                AttackVoice: sndNone);
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
                          ammoprop_Utility;
                Count: 1;
                NumPerTurn: 3;
                Timer: 0;
                Pos: 0;
                AmmoType: amPortalGun;
                AttackVoice: sndNone);
            Slot: 6;
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
                            ammoprop_AttackingPut or
                            ammoprop_DontHold or
                            ammoprop_NotBorder;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amPiano;
                AttackVoice: sndIncoming);
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
            Ammo: (Propz: ammoprop_Timerable or ammoprop_Power or ammoprop_AltUse;
                Count: AMMO_INFINITE;
                NumPerTurn: 0;
                Timer: 3000;
                Pos: 0;
                AmmoType: amGasBomb;
                AttackVoice: sndCover);
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
            Ammo: (Propz: ammoprop_AttackInMove;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amSineGun;
                AttackVoice: sndNone);
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
            Ammo: (Propz:  ammoprop_ForwMsgs or ammoprop_DontHold;
                Count: 1;
                NumPerTurn: 0;
                Timer: 5001;
                Pos: 0;
                AmmoType: amFlamethrower;
                AttackVoice: sndNone);
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
            Ammo: (Propz: ammoprop_Power; //FIXME: enable multishoot at altuse, until then removed ammoprop_AltUse
                Count: 1;
                NumPerTurn: 1;
                Timer: 0;
                Pos: 0;
                AmmoType: amSMine;
                AttackVoice: sndLaugh);
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
                AttackVoice: sndNone);
            Slot: 3;
            TimeAfterTurn: 1000;
            MinAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 0;
            PosCount: 1;
            PosSprite: sprWater;
            ejectX: 0;
            ejectY: 0),

// Ressurrector
        (NameId: sidResurrector;
            NameTex: nil;
            Probability: 0;
            NumberInCase: 1;
            Ammo: (Propz: ammoprop_NoCrosshair or
                          ammoprop_Utility or
                          ammoprop_NoRoundEnd;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amResurrector;
                AttackVoice: sndNone);
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
                            ammoprop_NotBorder;
                Count: 1;
                NumPerTurn: 0;
                Timer: 0;
                Pos: 0;
                AmmoType: amDrillStrike;
                AttackVoice: sndIncoming);
            Slot: 5;
            TimeAfterTurn: 0;
            minAngle: 0;
            maxAngle: 0;
            isDamaging: true;
            SkipTurns: 6;
            PosCount: 2;
            PosSprite: sprAmAirplane;
            ejectX: 0;
            ejectY: 0)
        );



    conversionFormat: TSDL_PixelFormat = (
        palette: nil;
        BitsPerPixel : 32;
        BytesPerPixel: 4;
        Rloss : 0;
        Gloss : 0;
        Bloss : 0;
        Aloss : 0;
{$IFDEF ENDIAN_LITTLE}
        Rshift: 0;
        Gshift: 8;
        Bshift: 16;
        Ashift: 24;
{$ELSE}
        Rshift: 24;
        Gshift: 16;
        Bshift: 8;
        Ashift: 0;
{$ENDIF}
        RMask : RMask;
        GMask : GMask;
        BMask : BMask;
        AMask : AMask;
        colorkey: 0;
        alpha : 255
    );

procedure initModule;
procedure freeModule;

implementation


procedure initModule;
begin
    Pathz:= cPathz;
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

    cDrownSpeed.QWordValue  := 257698038;       // 0.06
    cDrownSpeedf            := 0.06;
    cMaxWindSpeed.QWordValue:= 1073742;     // 0.00025
    cWindSpeed.QWordValue   := 429496;      // 0.0001
    cWindSpeedf             := 0.0001;
    cGravity                := cMaxWindSpeed * 2;
    cGravityf               := 0.00025 * 2;
    cDamageModifier         := _1;
    TargetPoint             := cTargetPointRef;
    TextureList             := nil;

    // int, longint longword and byte
    CursorMovementX     := 0;
    CursorMovementY     := 0;
    GameTicks           := 0;
    TrainingTimeInc     := 10000;
    TrainingTimeInD     := 500;
    TrainingTimeInM     := 5000;
    TrainingTimeMax     := 60000;
    TimeTrialStartTime  := 0;
    TimeTrialStopTime   := 0;
    cWaterLine          := LAND_HEIGHT;
    cGearScrEdgesDist   := 240;

    GameFlags           := 0;
    TrainingFlags       := 0;
    TurnTimeLeft        := 0;
    cSuddenDTurns       := 15;
    cDamagePercent      := 100;
    cMineDudPercent     := 0;
    cTemplateFilter     := 0;
    cMapGen             := 0;   // MAPGEN_REGULAR
    cMazeSize           := 0;
    cHedgehogTurnTime   := 45000;
    cMinesTime          := 3;
    cMaxAIThinkTime     := 9000;
    cCloudsNumber       := 9;
    cHealthCaseProb     := 35;
    cHealthCaseAmount   := 25;
    cWaterRise          := 47;
    cHealthDecrease     := 5;

    cTagsMask       := 0;
    InitStepsFlags  := 0;
    RealTicks       := 0;
    AttackBar       := 0; // 0 - none, 1 - just bar at the right-down corner, 2 - from weapon
    cCaseFactor     := 5;  {0..9}
    cLandMines      := 4;
    cExplosives     := 2;

    GameState       := Low(TGameState);
    GameType        := gmtLocal;
    zoom            := cDefaultZoomLevel;
    ZoomValue       := cDefaultZoomLevel;
    WeaponTooltipTex:= nil;
    cLaserSighting  := false;
    cVampiric       := false;
    cArtillery      := false;
    flagMakeCapture := false;
    bBetweenTurns   := false;
    bWaterRising    := false;
    isCursorVisible := false;
    isTerminated    := false;
    isInLag         := false;
    isPaused        := false;
    isInMultiShoot  := false;
    isSpeed         := false;
    fastUntilLag    := false;
    isFirstFrame    := true;
    isSEBackup      := true;
    cSeed           := '';
    cVolumeDelta    := 0;
    cHasFocus       := true;
    cInactDelay     := 1250;
    ReadyTimeLeft   := 0;

    ScreenFade      := sfNone;

{$IFDEF SDL13}
    SDLwindow       := nil;
{$ENDIF}

    // those values still aren't perfect
    cLeftScreenBorder:= round(-cMinZoomLevel * cScreenWidth);
    cRightScreenBorder:= round(cMinZoomLevel * cScreenWidth + LAND_WIDTH);
    cScreenSpace:= cRightScreenBorder - cLeftScreenBorder;

    if isPhone() then
        cMaxCaptions:= 3
    else
        cMaxCaptions:= 4;
end;

procedure freeModule;
begin
    // re-init flags so they will always contain safe values
    cScreenWidth    := 1024;
    cScreenHeight   := 768;
    cBits           := 32;
    //ipcPort is in uIO
    cFullScreen     := false;
    isSoundEnabled  := true;
    isMusicEnabled  := false;
    cLocaleFName    := 'en.txt';
    cInitVolume     := 100;
    cTimerInterval  := 8;
    PathPrefix := './';
    cShowFPS        := false;
    cAltDamage      := true;
    cReducedQuality := rqNone;
    //userNick is in uChat
    recordFileName  := '';
    cReadyDelay     := 0;
end;

end.