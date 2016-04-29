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

{$IFDEF WIN32}
{$R res/hwengine.rc}
{$ENDIF}

{$IFDEF HWLIBRARY}
unit hwengine;
interface
{$ELSE}
program hwengine;
{$ENDIF}

uses {$IFDEF IPHONEOS}cmem, {$ENDIF} SDLh, uMisc, uConsole, uGame, uConsts, uLand, uAmmos, uVisualGears, uGears, uStore, uWorld, uInputHandler
     , uSound, uScript, uTeams, uStats, uIO, uLocale, uChat, uAI, uAIMisc, uAILandMarks, uLandTexture, uCollisions
     , SysUtils, uTypes, uVariables, uCommands, uUtils, uCaptions, uDebug, uCommandHandlers, uLandPainted
     , uPhysFSLayer, uCursor, uRandom, ArgParsers, uVisualGearsHandlers, uTextures, uRender
     {$IFDEF USE_VIDEO_RECORDING}, uVideoRec {$ENDIF}
     {$IFDEF USE_TOUCH_INTERFACE}, uTouch {$ENDIF}
     {$IFDEF ANDROID}, GLUnit{$ENDIF}
     ;

{$IFDEF HWLIBRARY}
function RunEngine(argc: LongInt; argv: PPChar): LongInt; cdecl; export;

procedure preInitEverything();
procedure initEverything(complete:boolean);
procedure freeEverything(complete:boolean);

implementation
{$ELSE}
procedure preInitEverything(); forward;
procedure initEverything(complete:boolean); forward;
procedure freeEverything(complete:boolean); forward;
{$ENDIF}

// TODO localization support
procedure ShowCredits();
var themeCredits, mapCredits: shortstring;
begin
    if Length(cMapName) > 0 then
        begin
        mapCredits:= read1stLn(cPathz[ptMapCurrent] + '/credits.txt');
        if Length(mapCredits) > 0 then
            AddChatString(char(6) + '© Map: ' + mapCredits);
        end;

        themeCredits:= read1stLn(cPathz[ptCurrTheme] + '/credits.txt');
        if Length(themeCredits) > 0 then
            AddChatString(char(8) + '© Theme: ' + themeCredits);
end;

///////////////////////////////////////////////////////////////////////////////
function DoTimer(Lag: LongInt): boolean;
var s: shortstring;
    t: LongWord;
begin
    DoTimer:= false;
    inc(RealTicks, Lag);

    case GameState of
        gsLandGen:
            begin
            GenMap;
            SetLandTexture;
            UpdateLandTexture(0, LAND_WIDTH, 0, LAND_HEIGHT, false);
            setAILandMarks;
            ParseCommand('sendlanddigest', true);
            GameState:= gsStart;
            end;
        gsStart:
            begin
            SetDefaultBinds;
            if HasBorder then
                DisableSomeWeapons;
            // wave "clouds" on underwater theme look weird w/ weSea, esp the blended bottom portion
            if (WorldEdge <> weSea) or (Theme <> 'Underwater') then
                AddClouds;
            AddFlakes;
            SetRandomSeed(cSeed, false);
            StoreLoad(false);
            if not allOK then exit;
            AssignHHCoords;
            AddMiscGears;
            InitWorld;
            ResetKbd;
            if GameType = gmtSave then
                SetSound(false);
            FinishProgress;
            PlayMusic;
            InitZoom(zoom);
            ScriptCall('onGameStart');
            for t:= 0 to Pred(TeamsCount) do
                with TeamsArray[t]^ do
                    MaxTeamHealth:= TeamHealth;
            RecountAllTeamsHealth;
            if not cOnlyStats then ShowCredits;
            GameState:= gsGame;
            end;
        gsConfirm, gsGame, gsChat:
            begin
            // disable screenshot flash effect when about to make another screenshot
            if flagMakeCapture and (ScreenFade = sfFromWhite) then
                ScreenFade:= sfNone;
            if not cOnlyStats then
                // never place between ProcessKbd and DoGameTick - bugs due to /put cmd and isCursorVisible
                DrawWorld(Lag);
            DoGameTick(Lag);
            if not cOnlyStats then ProcessVisualGears(Lag);
            end;
        gsExit:
            begin
            DoTimer:= true;
            end;
        gsSuspend:
            exit(false);
            end;

    if not cOnlyStats then SwapBuffers;

{$IFDEF USE_VIDEO_RECORDING}
    if flagPrerecording then
        SaveCameraPosition;
{$ENDIF}

    if flagMakeCapture then
        begin
        flagMakeCapture:= false;
        if flagDumpLand then
             s:= '/Screenshots/mapdump_'
        else s:= '/Screenshots/hw_';
        {$IFDEF PAS2C}
        s:= s + inttostr(GameTicks);
        {$ELSE}
        s:= s + FormatDateTime('YYYY-MM-DD_HH-mm-ss', Now()) + inttostr(GameTicks);
        {$ENDIF}

        // flash
        playSound(sndShutter);
        ScreenFade:= sfFromWhite;
        ScreenFadeValue:= sfMax;
        ScreenFadeSpeed:= 5;

        if (not flagDumpLand and MakeScreenshot(s, 1, 0)) or
           (flagDumpLand and MakeScreenshot(s, 1, 1) and ((cReducedQuality and rqBlurryLand <> 0) or MakeScreenshot(s, 1, 2))) then
            WriteLnToConsole('Screenshot saved: ' + s)
        else
            begin
            WriteLnToConsole('Screenshot failed.');
            AddChatString(#5 + 'screen capture failed (lack of memory or write permissions)');
            end
        end;
end;

///////////////////////////////////////////////////////////////////////////////
procedure MainLoop;
var event: TSDL_Event;
    PrevTime, CurrTime: LongWord;
    isTerminated: boolean;
    previousGameState: TGameState;
    wheelEvent: boolean;
begin
    isTerminated:= false;
    PrevTime:= SDL_GetTicks;
    while (not isTerminated) and allOK do
    begin
        wheelEvent:= false;
        SDL_PumpEvents();

        while SDL_PeepEvents(@event, 1, SDL_GETEVENT, SDL_FIRSTEVENT, SDL_LASTEVENT) > 0 do
        begin
            case event.type_ of
                SDL_KEYDOWN:
                    if GameState = gsChat then
                        begin
                    // sdl on iphone supports only ashii keyboards and the unicode field is deprecated in sdl 1.3
                        KeyPressChat(event.key.keysym);
                        end
                    else
                        if GameState >= gsGame then ProcessKey(event.key);
                SDL_KEYUP:
                    if (GameState <> gsChat) and (GameState >= gsGame) then
                        ProcessKey(event.key);

                SDL_TEXTINPUT: if GameState = gsChat then uChat.TextInput(event.text);

                SDL_WINDOWEVENT:
                    begin
                    case event.window.event of
                        SDL_WINDOWEVENT_FOCUS_GAINED:
                                begin
                                cHasFocus:= true;
                                onFocusStateChanged();
                                end;
                        SDL_WINDOWEVENT_FOCUS_LOST:
                                begin
                                cHasFocus:= false;
                                onFocusStateChanged();
                                end;
                        SDL_WINDOWEVENT_MINIMIZED:
                                begin
                                previousGameState:= GameState;
                                GameState:= gsSuspend;
                                end;
                        SDL_WINDOWEVENT_RESTORED:
                                begin
                                GameState:= previousGameState;
{$IFDEF ANDROID}
                                //This call is used to reinitialize the glcontext and reload the textures
                                ParseCommand('fullscr '+intToStr(LongInt(cFullScreen)), true);
{$ENDIF}
                                end;
                        SDL_WINDOWEVENT_RESIZED:
                                begin
                                cNewScreenWidth:= max(2 * (event.window.data1 div 2), cMinScreenWidth);
                                cNewScreenHeight:= max(2 * (event.window.data2 div 2), cMinScreenHeight);
                                cScreenResizeDelay:= RealTicks + 500{$IFDEF IPHONEOS}div 2{$ENDIF};
                                end;
                        end; // case closed
                    end;

{$IFDEF USE_TOUCH_INTERFACE}
                SDL_FINGERMOTION:
                    onTouchMotion(event.tfinger.x, event.tfinger.y, event.tfinger.dx, event.tfinger.dy, event.tfinger.fingerId);

                SDL_FINGERDOWN:
                    onTouchDown(event.tfinger.x, event.tfinger.y, event.tfinger.fingerId);

                SDL_FINGERUP:
                    onTouchUp(event.tfinger.x, event.tfinger.y, event.tfinger.fingerId);
{$ELSE}
                SDL_MOUSEBUTTONDOWN:
                    if GameState = gsConfirm then
                        ParseCommand('quit', true)
                    else
                        if (GameState >= gsGame) then ProcessMouse(event.button, true);

                SDL_MOUSEBUTTONUP:
                    if (GameState >= gsGame) then ProcessMouse(event.button, false);

                SDL_MOUSEWHEEL:
                    begin
                    wheelEvent:= true;
                    ProcessMouseWheel(event.wheel.x, event.wheel.y);
                    end;
{$ENDIF}

                SDL_JOYAXISMOTION:
                    ControllerAxisEvent(event.jaxis.which, event.jaxis.axis, event.jaxis.value);
                SDL_JOYHATMOTION:
                    ControllerHatEvent(event.jhat.which, event.jhat.hat, event.jhat.value);
                SDL_JOYBUTTONDOWN:
                    ControllerButtonEvent(event.jbutton.which, event.jbutton.button, true);
                SDL_JOYBUTTONUP:
                    ControllerButtonEvent(event.jbutton.which, event.jbutton.button, false);
                SDL_QUITEV:
                    isTerminated:= true
            end; //end case event.type_ of
        end; //end while SDL_PollEvent(@event) <> 0 do

        if (not wheelEvent) then
            ResetMouseWheel();

        if (CursorMovementX <> 0) or (CursorMovementY <> 0) then
            handlePositionUpdate(CursorMovementX * cameraKeyboardSpeed, CursorMovementY * cameraKeyboardSpeed);

        if (cScreenResizeDelay <> 0) and (cScreenResizeDelay < RealTicks) and
           ((cNewScreenWidth <> cScreenWidth) or (cNewScreenHeight <> cScreenHeight)) then
        begin
            cScreenResizeDelay:= 0;
            cWindowedWidth:= cNewScreenWidth;
            cWindowedHeight:= cNewScreenHeight;
            cScreenWidth:= cWindowedWidth;
            cScreenHeight:= cWindowedHeight;

            ParseCommand('fullscr '+intToStr(LongInt(cFullScreen)), true);
            WriteLnToConsole('window resize: ' + IntToStr(cScreenWidth) + ' x ' + IntToStr(cScreenHeight));
            ScriptOnScreenResize();
            InitCameraBorders();
            InitTouchInterface();
            InitZoom(zoomValue);
            SendIPC('W' + IntToStr(cScreenWidth) + 'x' + IntToStr(cScreenHeight));
        end;

        CurrTime:= SDL_GetTicks();
        if PrevTime + longword(cTimerInterval) <= CurrTime then
        begin
            isTerminated:= isTerminated or DoTimer(CurrTime - PrevTime);
            PrevTime:= CurrTime;
        end
        else SDL_Delay(1);
        IPCCheckSock();

    end;
end;

{$IFDEF USE_VIDEO_RECORDING}
procedure RecorderMainLoop;
var oldGameTicks, oldRealTicks, newGameTicks, newRealTicks: LongInt;
begin
    if not BeginVideoRecording() then
        exit;
    DoTimer(0); // gsLandGen -> gsStart
    DoTimer(0); // gsStart -> gsGame

    if not LoadNextCameraPosition(newRealTicks, newGameTicks) then
        exit;
    fastScrolling:= true;
    DoGameTick(newGameTicks);
    fastScrolling:= false;
    oldRealTicks:= 0;
    oldGameTicks:= newGameTicks;

    while LoadNextCameraPosition(newRealTicks, newGameTicks) do
    begin
        IPCCheckSock();
        DoGameTick(newGameTicks - oldGameTicks);
        if GameState = gsExit then
            break;
        ProcessVisualGears(newRealTicks - oldRealTicks);
        DrawWorld(newRealTicks - oldRealTicks);
        EncodeFrame();
        oldRealTicks:= newRealTicks;
        oldGameTicks:= newGameTicks;
    end;
    StopVideoRecording();
end;
{$ENDIF}

///////////////////////////////////////////////////////////////////////////////
procedure GameRoutine;
//var p: TPathType;
var s: shortstring;
    i: LongInt;
begin
    WriteLnToConsole('Hedgewars engine ' + cVersionString + '-r' + cRevisionString +
                     ' (' + cHashString + ') with protocol #' + inttostr(cNetProtoVersion));
    AddFileLog('Prefix: "' + shortstring(PathPrefix) +'"');
    AddFileLog('UserPrefix: "' + shortstring(UserPathPrefix) +'"');

    for i:= 0 to ParamCount do
        AddFileLog(inttostr(i) + ': ' + ParamStr(i));

    WriteToConsole('Init SDL... ');
    if not cOnlyStats then SDLCheck(SDL_Init(SDL_INIT_VIDEO or SDL_INIT_NOPARACHUTE) >= 0, 'SDL_Init', true);
    WriteLnToConsole(msgOK);
    if not cOnlyStats then
        begin
        WriteToConsole('Init SDL_ttf... ');
        SDLCheck(TTF_Init() <> -1, 'TTF_Init', true);
        WriteLnToConsole(msgOK);
        end;

    if not allOK then exit;
    //SDL_StartTextInput();
    SDL_ShowCursor(0);


{$IFDEF USE_VIDEO_RECORDING}
    if GameType = gmtRecord then
        InitOffscreenOpenGL()
    else
{$ENDIF}
        begin
        // show main window
        if cFullScreen then
            ParseCommand('fullscr 1', true)
        else
            ParseCommand('fullscr 0', true);
        end;

    ControllerInit(); // has to happen before InitKbdKeyTable to map keys
    InitKbdKeyTable();
    AddProgress();
    if not allOK then exit;

    LoadLocale(cPathz[ptLocale] + '/en.txt');  // Do an initial load with english
    if cLocaleFName <> 'en.txt' then
        begin
        // Try two letter locale first before trying specific locale overrides
        if (Length(cLocale) > 3) and (Copy(cLocale, 1, 2) <> 'en') then
            begin
            LoadLocale(cPathz[ptLocale] + '/' + Copy(cLocale, 1, 2) + '.txt')
            end;
        LoadLocale(cPathz[ptLocale] + '/' + cLocaleFName)
        end
    else cLocale := 'en';

    if not allOK then exit;
    WriteLnToConsole(msgGettingConfig);

    if cTestLua then
        begin
        ParseCommand('script ' + cScriptName, true);
        end
    else
        begin
        if recordFileName = '' then
            begin
            InitIPC;
            SendIPCAndWaitReply(_S'C');        // ask for game config
            end
        else
            LoadRecordFromFile(recordFileName);
        end;

    if not allOK then exit;
    ScriptOnGameInit;
    s:= 'eproto ' + inttostr(cNetProtoVersion);
    SendIPCRaw(@s[0], Length(s) + 1); // send proto version

    InitTeams();
    AssignStores();

    if GameType = gmtRecord then
        SetSound(false);

    InitSound();

    isDeveloperMode:= false;
    if checkFails(InitStepsFlags = cifAllInited, 'Some parameters not set (flags = ' + inttostr(InitStepsFlags) + ')', true) then exit;
    //ParseCommand('rotmask', true);
    if not allOK then exit;

{$IFDEF USE_VIDEO_RECORDING}
    if GameType = gmtRecord then
    begin
        RecorderMainLoop();
        freeEverything(true);
        exit;
    end;
{$ENDIF}

    MainLoop;
end;

procedure Game;
begin
    initEverything(true);
    GameRoutine;
    // clean up all the memory allocated
    freeEverything(true);
end;
///////////////////////////////////////////////////////////////////////////////
// preInitEverything - init variables that are going to be ovewritten by arguments
// initEverything - init variables only. Should be coupled by below
// freeEverything - free above. Pay attention to the init/free order!
procedure preInitEverything;
begin
    allOK:= true;
    Randomize();

    uVariables.preInitModule;
    uSound.preInitModule;
end;

procedure initEverything (complete:boolean);
begin
    PathPrefix:= PathPrefix + #0;
    UserPathPrefix:= UserPathPrefix + #0;
    uPhysFSLayer.initModule(@PathPrefix[1], @UserPathPrefix[1]);
    PathPrefix:= copy(PathPrefix, 1, length(PathPrefix) - 1);
    UserPathPrefix:= copy(UserPathPrefix, 1, length(UserPathPrefix) - 1);

    uUtils.initModule(complete);    // opens the debug file, must be the first
    uVariables.initModule;          // inits all global variables
    uCommands.initModule;           // helps below
    uCommandHandlers.initModule;    // registers all messages from frontend

    uLand.initModule;               // computes land
    uLandPainted.initModule;        // computes drawn land
    uIO.initModule;                 // sets up sockets

    uScript.initModule;

    if complete then
    begin
        uTextures.initModule;
{$IFDEF ANDROID}GLUnit.initModule;{$ENDIF}
{$IFDEF USE_TOUCH_INTERFACE}uTouch.initModule;{$ENDIF}
{$IFDEF USE_VIDEO_RECORDING}uVideoRec.initModule;{$ENDIF}
        uAI.initModule;
        uAIMisc.initModule;
        uAILandMarks.initModule;    //stub
        uAmmos.initModule;
        uCaptions.initModule;

        uChat.initModule;
        uCollisions.initModule;
        uGears.initModule;
        uInputHandler.initModule;
        uMisc.initModule;
        uLandTexture.initModule;    //stub
        uSound.initModule;
        uStats.initModule;
        uStore.initModule;
        uRender.initModule;
        uTeams.initModule;
        uVisualGears.initModule;
        uVisualGearsHandlers.initModule;
        uWorld.initModule;
    end;
end;

procedure freeEverything (complete:boolean);
begin
    if complete then
        begin
        WriteLnToConsole('Freeing resources...');
        uAI.freeModule;             // AI things need to be freed first
        uAIMisc.freeModule;         //stub
        uAILandMarks.freeModule;
        uCaptions.freeModule;
        uWorld.freeModule;
        uVisualGears.freeModule;
        uTeams.freeModule;
        uInputHandler.freeModule;
        uStats.freeModule;          //stub
        uSound.freeModule;
        uMisc.freeModule;
        uLandTexture.freeModule;
        uGears.freeModule;
        uCollisions.freeModule;     //stub
        uChat.freeModule;
        uAmmos.freeModule;
        uRender.freeModule;
        uStore.freeModule;          // closes SDL
{$IFDEF USE_VIDEO_RECORDING}uVideoRec.freeModule;{$ENDIF}
{$IFDEF USE_TOUCH_INTERFACE}uTouch.freeModule;{$ENDIF}  //stub
{$IFDEF ANDROID}GLUnit.freeModule;{$ENDIF}
        uTextures.freeModule;
        end;

    uIO.freeModule;
    uLand.freeModule;
    uLandPainted.freeModule;

    uCommandHandlers.freeModule;
    uCommands.freeModule;
    uVariables.freeModule;
    uUtils.freeModule;              // closes debug file
    uPhysFSLayer.freeModule;
    uScript.freeModule;
end;

///////////////////////////////////////////////////////////////////////////////
procedure GenLandPreview;
{$IFDEF MOBILE}
var Preview: TPreview;
{$ELSE}
var Preview: TPreviewAlpha;
{$ENDIF}
begin
    initEverything(false);

    InitIPC;
    if allOK then
    begin
        IPCWaitPongEvent;
        if checkFails(InitStepsFlags = cifRandomize, 'Some parameters not set (flags = ' + inttostr(InitStepsFlags) + ')', true) then exit;

        ScriptOnPreviewInit;
    {$IFDEF MOBILE}
        GenPreview(Preview);
    {$ELSE}
        GenPreviewAlpha(Preview);
    {$ENDIF}
        WriteLnToConsole('Sending preview...');
        SendIPCRaw(@Preview, sizeof(Preview));
        SendIPCRaw(@MaxHedgehogs, sizeof(byte));
        WriteLnToConsole('Preview sent, disconnect');
    end;

    freeEverything(false);
end;

{$IFDEF HWLIBRARY}
function RunEngine(argc: LongInt; argv: PPChar): LongInt; cdecl; export;
begin
    operatingsystem_parameter_argc:= argc;
    operatingsystem_parameter_argv:= argv;
{$ELSE}
begin
{$ENDIF}

///////////////////////////////////////////////////////////////////////////////
/////////////////////////////////// m a i n ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
{$IFDEF PAS2C}
    // workaround for pascal's ParamStr and ParamCount
    init(argc, argv);
{$ENDIF}
    preInitEverything();

    GetParams();

    if GameType = gmtLandPreview then
        GenLandPreview()
    else if GameType <> gmtSyntax then
        Game();

    // return 1 when engine is not called correctly
    if GameType = gmtSyntax then
        {$IFDEF PAS2C}
        exit(HaltUsageError);
        {$ELSE}
        halt(HaltUsageError);
        {$ENDIF}

    if cTestLua then
        begin
        WriteLnToConsole(errmsgLuaTestTerm);
        {$IFDEF PAS2C}
        exit(HaltTestUnexpected);
        {$ELSE}
        halt(HaltTestUnexpected);
        {$ENDIF}
        end;

    {$IFDEF PAS2C}
        exit(HaltNoError);
    {$ELSE}
        {$IFDEF IPHONEOS}
            exit(HaltNoError);
        {$ELSE}
            halt(HaltNoError);
        {$ENDIF}
    {$ENDIF}
{$IFDEF HWLIBRARY}
end;
{$ENDIF}

end.
