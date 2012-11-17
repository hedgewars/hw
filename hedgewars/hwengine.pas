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

{$IFDEF WIN32}
{$R hwengine.rc}
{$ENDIF}

{$IFDEF HWLIBRARY}
unit hwengine;
interface
{$ELSE}
program hwengine;
{$ENDIF}

uses SDLh, uMisc, uConsole, uGame, uConsts, uLand, uAmmos, uVisualGears, uGears, uStore, uWorld, uInputHandler
     , uSound, uScript, uTeams, uStats, uIO, uLocale, uChat, uAI, uAIMisc, uAILandMarks, uLandTexture, uCollisions
     , SysUtils, uTypes, uVariables, uCommands, uUtils, uCaptions, uDebug, uCommandHandlers, uLandPainted
     , uPhysFSLayer
     {$IFDEF USE_VIDEO_RECORDING}, uVideoRec {$ENDIF}
     {$IFDEF USE_TOUCH_INTERFACE}, uTouch {$ENDIF}
     {$IFDEF ANDROID}, GLUnit{$ENDIF}
     ;


{$IFDEF HWLIBRARY}
procedure preInitEverything();
procedure initEverything(complete:boolean);
procedure freeEverything(complete:boolean);
procedure Game(gameArgs: PPChar); cdecl; export;
procedure GenLandPreview(port: Longint); cdecl; export;

implementation
{$ELSE}
procedure preInitEverything(); forward;
procedure initEverything(complete:boolean); forward;
procedure freeEverything(complete:boolean); forward;
{$ENDIF}

///////////////////////////////////////////////////////////////////////////////
function DoTimer(Lag: LongInt): boolean;
var s: shortstring;
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
            if HasBorder then
                DisableSomeWeapons;
            AddClouds;
            AddFlakes;
            AssignHHCoords;
            AddMiscGears;
            StoreLoad(false);
            InitWorld;
            ResetKbd;
            if GameType = gmtSave then
                SetSound(false);
            FinishProgress;
            PlayMusic;
            SetScale(zoom);
            ScriptCall('onGameStart');
            GameState:= gsGame;
            end;
        gsConfirm, gsGame:
            begin
            if not cOnlyStats then DrawWorld(Lag);
            DoGameTick(Lag);
            if not cOnlyStats then ProcessVisualGears(Lag);
            end;
        gsChat:
            begin
            if not cOnlyStats then DrawWorld(Lag);
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
        {$IFDEF PAS2C}
        s:= '/Screenshots/hw';
        {$ELSE}
        s:= '/Screenshots/hw_' + FormatDateTime('YYYY-MM-DD_HH-mm-ss', Now()) + inttostr(GameTicks);
        {$ENDIF}

        // flash
        playSound(sndShutter);
        ScreenFade:= sfFromWhite;
        ScreenFadeValue:= sfMax;
        ScreenFadeSpeed:= 5;

        if MakeScreenshot(s, 1) then
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
    PrevTime, CurrTime: Longword;
    isTerminated: boolean;
{$IFDEF SDL13}
    previousGameState: TGameState;
{$ELSE}
    prevFocusState: boolean;
{$ENDIF}
begin
    isTerminated:= false;
    PrevTime:= SDL_GetTicks;
    while isTerminated = false do
    begin
        SDL_PumpEvents();
 
        while SDL_PeepEvents(@event, 1, SDL_GETEVENT, {$IFDEF SDL13}SDL_FIRSTEVENT, SDL_LASTEVENT{$ELSE}SDL_ALLEVENTS{$ENDIF}) > 0 do
        begin
            case event.type_ of
{$IFDEF SDL13}
                SDL_KEYDOWN:
                    if GameState = gsChat then
                    // sdl on iphone supports only ashii keyboards and the unicode field is deprecated in sdl 1.3
                        KeyPressChat(SDL_GetKeyFromScancode(event.key.keysym.sym))//TODO correct for keymodifiers
                    else
                        ProcessKey(event.key);
                SDL_KEYUP:
                    if GameState <> gsChat then
                        ProcessKey(event.key);
                    
                SDL_WINDOWEVENT:
                    if event.window.event = SDL_WINDOWEVENT_SHOWN then
                    begin
                        cHasFocus:= true;
                        onFocusStateChanged()
                    end
                    else if event.window.event = SDL_WINDOWEVENT_MINIMIZED then
                    begin
                        previousGameState:= GameState;
                        GameState:= gsSuspend;
                    end
                    else if event.window.event = SDL_WINDOWEVENT_RESTORED then
                    begin
                        GameState:= previousGameState;
{$IFDEF ANDROID}
                        //This call is used to reinitialize the glcontext and reload the textures
                        ParseCommand('fullscr '+intToStr(LongInt(cFullScreen)), true);
{$ENDIF}
                    end
                    else if event.window.event = SDL_WINDOWEVENT_RESIZED then
                    begin
                        cNewScreenWidth:= max(2 * (event.window.data1 div 2), cMinScreenWidth);
                        cNewScreenHeight:= max(2 * (event.window.data2 div 2), cMinScreenHeight);
                        cScreenResizeDelay:= RealTicks + 500{$IFDEF IPHONEOS}div 2{$ENDIF};
                    end;
                        
                SDL_FINGERMOTION:
                    onTouchMotion(event.tfinger.x, event.tfinger.y,event.tfinger.dx, event.tfinger.dy, event.tfinger.fingerId);
                
                SDL_FINGERDOWN:
                    onTouchDown(event.tfinger.x, event.tfinger.y, event.tfinger.fingerId);
                
                SDL_FINGERUP:
                    onTouchUp(event.tfinger.x, event.tfinger.y, event.tfinger.fingerId);
{$ELSE}
                SDL_KEYDOWN:
                    if GameState = gsChat then
                        KeyPressChat(event.key.keysym.unicode)
                    else
                        ProcessKey(event.key);
                SDL_KEYUP:
                    if GameState <> gsChat then
                        ProcessKey(event.key);
                    
                SDL_MOUSEBUTTONDOWN:
                    ProcessMouse(event.button, true);
                    
                SDL_MOUSEBUTTONUP:
                    ProcessMouse(event.button, false); 
                    
                SDL_ACTIVEEVENT:
                    if (event.active.state and SDL_APPINPUTFOCUS) <> 0 then
                    begin
                        prevFocusState:= cHasFocus;
                        cHasFocus:= event.active.gain = 1;
                        if prevFocusState xor cHasFocus then
                            onFocusStateChanged()
                    end;
                        
                SDL_VIDEORESIZE:
                begin
                    // using lower values than cMinScreenWidth or cMinScreenHeight causes widget overlap and off-screen widget parts
                    // Change by sheepluva:
                    // Let's only use even numbers for custom width/height since I ran into scaling issues with odd width values.
                    // Maybe just fixes the symptom not the actual cause(?), I'm too tired to find out :P
                    cNewScreenWidth:= max(2 * (event.resize.w div 2), cMinScreenWidth);
                    cNewScreenHeight:= max(2 * (event.resize.h div 2), cMinScreenHeight);
                    cScreenResizeDelay:= RealTicks+500;
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

        if (cScreenResizeDelay <> 0) and (cScreenResizeDelay < RealTicks) and
           ((cNewScreenWidth <> cScreenWidth) or (cNewScreenHeight <> cScreenHeight)) then
        begin
            cScreenResizeDelay:= 0;
            cScreenWidth:= cNewScreenWidth;
            cScreenHeight:= cNewScreenHeight;

            ParseCommand('fullscr '+intToStr(LongInt(cFullScreen)), true);
            WriteLnToConsole('window resize: ' + IntToStr(cScreenWidth) + ' x ' + IntToStr(cScreenHeight));
            ScriptOnScreenResize();
            InitCameraBorders();
            InitTouchInterface();
        end;

        CurrTime:= SDL_GetTicks();
        if PrevTime + longword(cTimerInterval) <= CurrTime then
        begin
            isTerminated := isTerminated or DoTimer(CurrTime - PrevTime);
            PrevTime:= CurrTime
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
procedure Game{$IFDEF HWLIBRARY}(gameArgs: PPChar); cdecl; export{$ENDIF};
var p: TPathType;
    s: shortstring;
    i: LongInt;
begin
{$IFDEF HWLIBRARY}
    preInitEverything();
    cShowFPS:= {$IFDEF DEBUGFILE}true{$ELSE}false{$ENDIF};
    ipcPort:= StrToInt(gameArgs[0]);
    cScreenWidth:= StrToInt(gameArgs[1]);
    cScreenHeight:= StrToInt(gameArgs[2]);
    cReducedQuality:= StrToInt(gameArgs[3]);
    cLocaleFName:= gameArgs[4];
    UserNick:= gameArgs[5];
    SetSound(gameArgs[6] = '1');
    SetMusic(gameArgs[7] = '1');
    cAltDamage:= gameArgs[8] = '1';
    PathPrefix:= gameArgs[9];
    UserPathPrefix:= '../Documents';
    recordFileName:= gameArgs[10];
{$ENDIF}
    initEverything(true);

    WriteLnToConsole('Hedgewars ' + cVersionString + ' engine (network protocol: ' + inttostr(cNetProtoVersion) + ')');
    AddFileLog('Prefix: "' + PathPrefix +'"');
    AddFileLog('UserPrefix: "' + UserPathPrefix +'"');
    
    for i:= 0 to ParamCount do
        AddFileLog(inttostr(i) + ': ' + ParamStr(i));

    WriteToConsole('Init SDL... ');
    if not cOnlyStats then SDLTry(SDL_Init(SDL_INIT_VIDEO or SDL_INIT_NOPARACHUTE) >= 0, true);
    WriteLnToConsole(msgOK);

    SDL_EnableUNICODE(1);
    SDL_ShowCursor(0);

    WriteToConsole('Init SDL_ttf... ');
    SDLTry(TTF_Init() <> -1, true);
    WriteLnToConsole(msgOK);

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

    WriteLnToConsole(msgGettingConfig);

    if recordFileName = '' then
        begin
        InitIPC;
        SendIPCAndWaitReply(_S'C');        // ask for game config
        end
    else
        LoadRecordFromFile(recordFileName);

    ScriptOnGameInit;
    s:= 'eproto ' + inttostr(cNetProtoVersion);
    SendIPCRaw(@s[0], Length(s) + 1); // send proto version

    InitTeams();
    AssignStores();

    if GameType = gmtRecord then
        SetSound(false);

    InitSound();

    isDeveloperMode:= false;
    TryDo(InitStepsFlags = cifAllInited, 'Some parameters not set (flags = ' + inttostr(InitStepsFlags) + ')', true);
    ParseCommand('rotmask', true);

{$IFDEF USE_VIDEO_RECORDING}
    if GameType = gmtRecord then
        RecorderMainLoop()
    else
{$ENDIF}
        MainLoop();

    // clean up all the memory allocated
    freeEverything(true);
end;

///////////////////////////////////////////////////////////////////////////////
// preInitEverything - init variables that are going to be ovewritten by arguments
// initEverything - init variables only. Should be coupled by below
// freeEverything - free above. Pay attention to the init/free order!
procedure preInitEverything;
begin
    Randomize();

    uVariables.preInitModule;
    uSound.preInitModule;
end;

procedure initEverything (complete:boolean);
begin
    uUtils.initModule(complete);    // opens the debug file, must be the first
    uVariables.initModule;          // inits all global variables
    uConsole.initModule;            // opens stdout
    uCommands.initModule;           // helps below
    uCommandHandlers.initModule;    // registers all messages from frontend

    uLand.initModule;               // computes land
    uLandPainted.initModule;        // computes drawn land
    uIO.initModule;                 // sets up sockets

    if complete then
    begin
        uPhysFSLayer.initModule;
{$IFDEF ANDROID}GLUnit.initModule;{$ENDIF}
{$IFDEF USE_TOUCH_INTERFACE}uTouch.initModule;{$ENDIF}
{$IFDEF USE_VIDEO_RECORDING}uVideoRec.initModule;{$ENDIF}   //stub
        uAI.initModule;
        uAIMisc.initModule;
        uAILandMarks.initModule;    //stub
        uAmmos.initModule;
        uCaptions.initModule;

        uChat.initModule;
        uCollisions.initModule;
        uGears.initModule;
        uInputHandler.initModule;   //stub
        uMisc.initModule;
        uLandTexture.initModule;    //stub
        uScript.initModule;
        uSound.initModule;
        uStats.initModule;
        uStore.initModule;
        uTeams.initModule;
        uVisualGears.initModule;
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
        uScript.freeModule;
        uMisc.freeModule;
        uLandTexture.freeModule;
        uGears.freeModule;
        uCollisions.freeModule;     //stub
        uChat.freeModule;
        uAmmos.freeModule;
        uStore.freeModule;          // closes SDL
{$IFDEF USE_VIDEO_RECORDING}uVideoRec.freeModule;{$ENDIF}
{$IFDEF USE_TOUCH_INTERFACE}uTouch.freeModule;{$ENDIF}  //stub
{$IFDEF ANDROID}GLUnit.freeModule;{$ENDIF}
        uPhysFSLayer.freeModule;
    end;

    uIO.freeModule;
    uLand.freeModule;
    uLandPainted.freeModule;

    uCommandHandlers.freeModule;
    uCommands.freeModule;
    uConsole.freeModule;            // closes stdout
    uVariables.freeModule;
    uUtils.freeModule;              // closes debug file
end;

///////////////////////////////////////////////////////////////////////////////
procedure GenLandPreview{$IFDEF HWLIBRARY}(port: LongInt); cdecl; export{$ENDIF};
var Preview: TPreview;
begin
    initEverything(false);
{$IFDEF HWLIBRARY}
    WriteLnToConsole('Preview connecting on port ' + inttostr(port));
    ipcPort:= port;
    InitStepsFlags:= cifRandomize;
{$ENDIF}
    InitIPC;
    IPCWaitPongEvent;
    TryDo(InitStepsFlags = cifRandomize, 'Some parameters not set (flags = ' + inttostr(InitStepsFlags) + ')', true);

    GenPreview(Preview);
    WriteLnToConsole('Sending preview...');
    SendIPCRaw(@Preview, sizeof(Preview));
    SendIPCRaw(@MaxHedgehogs, sizeof(byte));
    WriteLnToConsole('Preview sent, disconnect');
    freeEverything(false);
end;

{$IFNDEF HWLIBRARY}
///////////////////////////////////////////////////////////////////////////////
procedure DisplayUsage;
var i: LongInt;
begin
    WriteLn(stdout, 'Wrong argument format: correct configurations is');
    WriteLn(stdout, '');
    WriteLn(stdout, '  hwengine <path to user hedgewars folder> <path to global data folder> <path to replay file> [options]');
    WriteLn(stdout, '');
    WriteLn(stdout, 'where [options] must be specified either as:');
    WriteLn(stdout, ' --set-video [screen width] [screen height] [color dept]');
    WriteLn(stdout, ' --set-audio [volume] [enable music] [enable sounds]');
    WriteLn(stdout, ' --set-other [language file] [full screen] [show FPS]');
    WriteLn(stdout, ' --set-multimedia [screen width] [screen height] [color dept] [volume] [enable music] [enable sounds] [language file] [full screen]');
    WriteLn(stdout, ' --set-everything [screen width] [screen height] [color dept] [volume] [enable music] [enable sounds] [language file] [full screen] [show FPS] [alternate damage] [timer value] [reduced quality]');
    WriteLn(stdout, ' --stats-only');
    WriteLn(stdout, '');
    WriteLn(stdout, 'Read documentation online at http://code.google.com/p/hedgewars/wiki/CommandLineOptions for more information');
    WriteLn(stdout, '');
    Write(stdout, 'PARSED COMMAND: ');
    
    for i:=0 to ParamCount do
        Write(stdout, ParamStr(i) + ' ');
        
    WriteLn(stdout, '');
end;

///////////////////////////////////////////////////////////////////////////////
{$INCLUDE "ArgParsers.inc"}

procedure GetParams;
begin
    if (ParamCount < 3) then
        GameType:= gmtSyntax
    else
        if (ParamCount = 3) and (ParamStr(3) = 'landpreview') then
            begin
            ipcPort:= StrToInt(ParamStr(2));
            GameType:= gmtLandPreview;
            end
        else
            begin
            if (ParamCount = 3) and (ParamStr(3) = '--stats-only') then
                playReplayFileWithParameters()
            else
                if ParamCount = cDefaultParamNum then
                    internalStartGameWithParameters()
{$IFDEF USE_VIDEO_RECORDING}
                else if ParamCount = cVideorecParamNum then
                    internalStartVideoRecordingWithParameters()
{$ENDIF}
                else
                    playReplayFileWithParameters();
            end
end;

///////////////////////////////////////////////////////////////////////////////
/////////////////////////////////// m a i n ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
begin
    preInitEverything();
    GetParams();

    if GameType = gmtLandPreview then
        GenLandPreview()
    else if GameType = gmtSyntax then
        DisplayUsage()
    else Game();

    // return 1 when engine is not called correctly
    halt(LongInt(GameType = gmtSyntax));
{$ENDIF}
end.
