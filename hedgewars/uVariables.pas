{$INCLUDE options.inc}

unit uVariables;
interface

uses SDLh, uTypes, uFloat, GLunit, uConsts, Math, uMobile;

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