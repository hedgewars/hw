(*
* Hedgewars, a free turn based strategy game
* Copyright (c) 2004-2010 Andrey Korotaev <unC0Rr@gmail.com>
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

uses SDLh, uMisc, uConsole, uGame, uConsts, uLand, uAmmos, uVisualGears, uGears, uStore, uWorld, uKeys, uSound,
     uScript, uTeams, uStats, uIO, uLocale, uChat, uAI, uAIMisc, uRandom, uLandTexture, uCollisions, uMobile,
     sysutils, uTypes, uVariables, uCommands, uUtils, uCaptions;

var isTerminated: boolean = false;
    alsoShutdownFrontend: boolean = false;

{$IFDEF HWLIBRARY}
procedure initEverything(complete:boolean);
procedure freeEverything(complete:boolean);

implementation
{$ELSE}
procedure OnDestroy; forward;
procedure initEverything(complete:boolean); forward;
procedure freeEverything(complete:boolean); forward;
{$ENDIF}

////////////////////////////////
procedure DoTimer(Lag: LongInt);
var s: shortstring;
begin
    if not isPaused then inc(RealTicks, Lag);

    case GameState of
        gsLandGen: begin
                GenMap;
                ParseCommand('sendlanddigest', true);
                GameState:= gsStart;
                end;
        gsStart: begin
                if HasBorder then DisableSomeWeapons;
                AddClouds;
                AssignHHCoords;
                AddMiscGears;
                StoreLoad;
                InitWorld;
                ResetKbd;
                SoundLoad;
                if GameType = gmtSave then
                    begin
                    isSEBackup:= isSoundEnabled;
                    isSoundEnabled:= false
                    end;
                FinishProgress;
                PlayMusic;
                SetScale(zoom);
                ScriptCall('onGameStart');
                GameState:= gsGame;
                end;
        gsConfirm,
        gsGame: begin
                DrawWorld(Lag); // never place between ProcessKbd and DoGameTick - bugs due to /put cmd and isCursorVisible
                ProcessKbd;
                if not isPaused then
                    begin
                    DoGameTick(Lag);
                    ProcessVisualGears(Lag);
                    end;
                end;
        gsChat: begin
                DrawWorld(Lag);
                if not isPaused then
                    begin
                    DoGameTick(Lag);
                    ProcessVisualGears(Lag);
                    end;
                end;
        gsExit: begin
                isTerminated:= true;
                end;
        end;

{$IFDEF SDL13}
    SDL_RenderPresent();
{$ELSE}
    SDL_GL_SwapBuffers();
{$ENDIF}
    // not going to make captures on the iPhone
    if flagMakeCapture then
    begin
        flagMakeCapture:= false;
        s:= 'hw_' + FormatDateTime('YYYY-MM-DD_HH-mm-ss', Now()) + inttostr(GameTicks);
        WriteLnToConsole('Saving ' + s + '...');
        playSound(sndShutter);
        MakeScreenshot(s);
        //SDL_SaveBMP_RW(SDLPrimSurface, SDL_RWFromFile(Str2PChar(s), 'wb'), 1)
    end;
end;

////////////////////
procedure OnDestroy;
begin
    WriteLnToConsole('Freeing resources...');
    FreeActionsList();
    StoreRelease();
    ControllerClose();
    CloseIPC();
    TTF_Quit();
{$IFDEF SDL13}
    SDL_DestroyRenderer(SDLwindow);
    SDL_DestroyWindow(SDLwindow);
{$ENDIF}
    SDL_Quit();
    isTerminated:= false;
end;

///////////////////
procedure MainLoop;
var PrevTime, CurrTime: Longword;
    event: TSDL_Event;
begin
    PrevTime:= SDL_GetTicks;
    while isTerminated = false do
    begin

        while SDL_PollEvent(@event) <> 0 do
        begin
            case event.type_ of
                SDL_KEYDOWN: if GameState = gsChat then
{$IFDEF IPHONEOS}
                    // sdl on iphone supports only ashii keyboards and the unicode field is deprecated in sdl 1.3
                    KeyPressChat(event.key.keysym.sym);
{$ELSE}
                    KeyPressChat(event.key.keysym.unicode);
                SDL_MOUSEBUTTONDOWN: if event.button.button = SDL_BUTTON_WHEELDOWN then uKeys.wheelDown:= true;
                SDL_MOUSEBUTTONUP: if event.button.button = SDL_BUTTON_WHEELUP then uKeys.wheelUp:= true;
{$ENDIF}
{$IFDEF SDL13}
                SDL_WINDOWEVENT:
                    if event.wevent.event = SDL_WINDOWEVENT_SHOWN then
                        cHasFocus:= true;
{$ELSE}
                SDL_ACTIVEEVENT:
                    if (event.active.state and SDL_APPINPUTFOCUS) <> 0 then
                        cHasFocus:= event.active.gain = 1;
{$ENDIF}
                SDL_JOYAXISMOTION: ControllerAxisEvent(event.jaxis.which, event.jaxis.axis, event.jaxis.value);
                SDL_JOYHATMOTION: ControllerHatEvent(event.jhat.which, event.jhat.hat, event.jhat.value);
                SDL_JOYBUTTONDOWN: ControllerButtonEvent(event.jbutton.which, event.jbutton.button, true);
                SDL_JOYBUTTONUP: ControllerButtonEvent(event.jbutton.which, event.jbutton.button, false);
                SDL_QUITEV: isTerminated:= true
            end; // end case event.type_
        end; // end while SDL_PollEvent(@event) <> 0

        if isTerminated = false then
        begin
            CurrTime:= SDL_GetTicks;
            if PrevTime + longword(cTimerInterval) <= CurrTime then
            begin
                DoTimer(CurrTime - PrevTime);
                PrevTime:= CurrTime
            end
            else SDL_Delay(1);
            IPCCheckSock();
        end;
    end;
end;

/////////////////////////
procedure ShowMainWindow;
begin
    if cFullScreen then ParseCommand('fullscr 1', true)
    else ParseCommand('fullscr 0', true);
    SDL_ShowCursor(0)
end;

///////////////
{$IFDEF HWLIBRARY}
procedure Game(gameArgs: PPChar); cdecl; export;
{$ELSE}
procedure Game;
{$ENDIF}
var p: TPathType;
    s: shortstring;
{$IFDEF DEBUGFILE}
    i: LongInt;
{$ENDIF}
begin
{$IFDEF HWLIBRARY}
    cBits:= 32;
    cFullScreen:= false;
    cTimerInterval:= 8;
    PathPrefix:= 'Data';
{$IFDEF DEBUGFILE}
    cShowFPS:= true;
{$ELSE}
    cShowFPS:= false;
{$ENDIF}
    val(gameArgs[0], ipcPort);
    val(gameArgs[1], cScreenWidth);
    val(gameArgs[2], cScreenHeight);
    val(gameArgs[3], cReducedQuality);
    cLocaleFName:= gameArgs[4];
    UserNick:= gameArgs[5];
    isSoundEnabled:= gameArgs[6] = '1';
    isMusicEnabled:= gameArgs[7] = '1';
    cAltDamage:= gameArgs[8] = '1';
    val(gameArgs[9], rotationQt);
    recordFileName:= gameArgs[10];
{$ENDIF}

    cLogfileBase:= 'game';
    initEverything(true);
    WriteLnToConsole('Hedgewars ' + cVersionString + ' engine (network protocol: ' + inttostr(cNetProtoVersion) + ')');
{$IFDEF DEBUGFILE}
    AddFileLog('Prefix: "' + PathPrefix +'"');
    for i:= 0 to ParamCount do
        AddFileLog(inttostr(i) + ': ' + ParamStr(i));
{$ENDIF}

    for p:= Succ(Low(TPathType)) to High(TPathType) do
        if p <> ptMapCurrent then Pathz[p]:= PathPrefix + '/' + Pathz[p];

    WriteToConsole('Init SDL... ');
    SDLTry(SDL_Init(SDL_INIT_VIDEO) >= 0, true);
    WriteLnToConsole(msgOK);

    SDL_EnableUNICODE(1);

    WriteToConsole('Init SDL_ttf... ');
    SDLTry(TTF_Init() <> -1, true);
    WriteLnToConsole(msgOK);

{$IFDEF WIN32}
    s:= SDL_getenv('SDL_VIDEO_CENTERED');
    SDL_putenv('SDL_VIDEO_CENTERED=1');
    ShowMainWindow();
    SDL_putenv(str2pchar('SDL_VIDEO_CENTERED=' + s));
{$ELSE}
    ShowMainWindow();
{$ENDIF}

    AddProgress();

    ControllerInit(); // has to happen before InitKbdKeyTable to map keys
    InitKbdKeyTable();

    LoadLocale(Pathz[ptLocale] + '/en.txt');  // Do an initial load with english
    if cLocaleFName <> 'en.txt' then
        begin
        // Try two letter locale first before trying specific locale overrides
        if (Length(cLocaleFName) > 6) and (Copy(cLocaleFName,1,2)+'.txt' <> 'en.txt') then
            LoadLocale(Pathz[ptLocale] + '/' + Copy(cLocaleFName,1,2)+'.txt');
        LoadLocale(Pathz[ptLocale] + '/' + cLocaleFName);
        end;

    WriteLnToConsole(msgGettingConfig);

    if recordFileName = '' then
        begin
        InitIPC;
        SendIPCAndWaitReply('C');        // ask for game config
        end
    else
        begin
        LoadRecordFromFile(recordFileName);
        perfExt_SaveBeganSynching();
        end;

    ScriptOnGameInit;

    s:= 'eproto ' + inttostr(cNetProtoVersion);
    SendIPCRaw(@s[0], Length(s) + 1); // send proto version

    InitTeams();
    AssignStores();

    if isSoundEnabled then
        InitSound();

    isDeveloperMode:= false;

    TryDo(InitStepsFlags = cifAllInited, 'Some parameters not set (flags = ' + inttostr(InitStepsFlags) + ')', true);

    ParseCommand('rotmask', true);

    MainLoop();
    // clean up SDL and GL context
    OnDestroy();
    // clean up all the other memory allocated
    freeEverything(true);
    if alsoShutdownFrontend then halt;
end;

procedure initEverything (complete:boolean);
begin
    Randomize();

    // uConsts does not need initialization as they are all consts
    uUtils.initModule;
    uMisc.initModule;
    uVariables.initModule;
    uConsole.initModule;    // MUST happen after uMisc
    uCommands.initModule;

    uLand.initModule;
    uIO.initModule;

    if complete then
    begin
        uAI.initModule;
        //uAIActions does not need initialization
        //uAIAmmoTests does not need initialization
        uAIMisc.initModule;
        uAmmos.initModule;
        uChat.initModule;
        uCollisions.initModule;
        //uFloat does not need initialization
        //uGame does not need initialization
        uGears.initModule;
        uKeys.initModule;
        //uLandGraphics does not need initialization
        //uLandObjects does not need initialization
        //uLandTemplates does not need initialization
        uLandTexture.initModule;
        //uLocale does not need initialization
        uRandom.initModule;
        uScript.initModule;
        uSound.initModule;
        uStats.initModule;
        uStore.initModule;
        uTeams.initModule;
        uVisualGears.initModule;
        uWorld.initModule;
        uCaptions.initModule;
    end;
end;

procedure freeEverything (complete:boolean);
begin
    if complete then
    begin
        uCaptions.freeModule;
        uWorld.freeModule;
        uVisualGears.freeModule;
        uTeams.freeModule;
        uStore.freeModule;          //stub
        uStats.freeModule;          //stub
        uSound.freeModule;
        uScript.freeModule;
        uRandom.freeModule;         //stub
        //uLocale does not need to be freed
        //uLandTemplates does not need to be freed
        uLandTexture.freeModule;
        //uLandObjects does not need to be freed
        //uLandGraphics does not need to be freed
        uKeys.freeModule;           //stub
        uGears.freeModule;
        //uGame does not need to be freed
        //uFloat does not need to be freed
        uCollisions.freeModule;     //stub
        uChat.freeModule;           //stub
        uAmmos.freeModule;
        uAIMisc.freeModule;         //stub
        //uAIAmmoTests does not need to be freed
        //uAIActions does not need to be freed
        uAI.freeModule;             //stub
    end;

    uIO.freeModule;             //stub
    uLand.freeModule;

    uCommands.freeModule;
    uConsole.freeModule;
    uVariables.freeModule;
    uUtils.freeModule;
    uMisc.freeModule;           // uMisc closes the debug log.
end;

/////////////////////////
procedure GenLandPreview{$IFDEF HWLIBRARY}(port: LongInt); cdecl; export{$ENDIF};
var Preview: TPreview;
begin
    cLogfileBase:= 'preview';
    initEverything(false);
{$IFDEF HWLIBRARY}
    WriteLnToConsole('Preview connecting on port ' + inttostr(port));
    ipcPort:= port;
{$ENDIF}
    InitIPC;
    IPCWaitPongEvent;
    TryDo(InitStepsFlags = cifRandomize, 'Some parameters not set (flags = ' + inttostr(InitStepsFlags) + ')', true);

    Preview:= GenPreview();
    WriteLnToConsole('Sending preview...');
    SendIPCRaw(@Preview, sizeof(Preview));
    SendIPCRaw(@MaxHedgehogs, sizeof(byte));
    WriteLnToConsole('Preview sent, disconnect');
    CloseIPC();
    freeEverything(false);
end;

{$IFNDEF HWLIBRARY}
/////////////////////
procedure DisplayUsage;
var i: LongInt;
begin
    WriteLn('Wrong argument format: correct configurations is');
    WriteLn();
    WriteLn('  hwengine <path to data folder> <path to replay file> [options]');
    WriteLn();
    WriteLn('where [options] must be specified either as:');
    WriteLn(' --set-video [screen width] [screen height] [color dept]');
    WriteLn(' --set-audio [volume] [enable music] [enable sounds]');
    WriteLn(' --set-other [language file] [full screen] [show FPS]');
    WriteLn(' --set-multimedia [screen width] [screen height] [color dept] [volume] [enable music] [enable sounds] [language file] [full screen]');
    WriteLn(' --set-everything [screen width] [screen height] [color dept] [volume] [enable music] [enable sounds] [language file] [full screen] [show FPS] [alternate damage] [timer value] [reduced quality]');
    WriteLn();
    WriteLn('Read documentation online at http://code.google.com/p/hedgewars/wiki/CommandLineOptions for more information');
    WriteLn();
    Write('PARSED COMMAND: ');
    for i:=0 to ParamCount do
        Write(ParamStr(i) + ' ');
    WriteLn();
end;

////////////////////
{$INCLUDE "ArgParsers.inc"}

procedure GetParams;
begin
    if (ParamCount < 2) then
        GameType:= gmtSyntax
    else
        if (ParamCount = 3) then
            internalSetGameTypeLandPreviewFromParameters()
        else
            if (ParamCount = cDefaultParamNum) then
                internalStartGameWithParameters()
            else
                playReplayFileWithParameters();
end;

////////////////////////////////////////////////////////////////////////////////
/////////////////////////////// m a i n ////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
begin
    GetParams();

    if GameType = gmtLandPreview then GenLandPreview()
    else if GameType = gmtSyntax then DisplayUsage()
    else Game();

    if GameType = gmtSyntax then
        ExitCode:= 1
    else
        ExitCode:= 0;
{$ENDIF}
end.
