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

unit ArgParsers;
interface

procedure GetParams;
{$IFDEF HWLIBRARY}
var operatingsystem_parameter_argc: LongInt = 0; {$IFNDEF PAS2C}{$IFNDEF IPHONEOS}cdecl;{$ENDIF} export;{$ENDIF}
    operatingsystem_parameter_argv: pointer = nil; {$IFNDEF PAS2C}{$IFNDEF IPHONEOS}cdecl;{$ENDIF} export;{$ENDIF}
    operatingsystem_parameter_envp: pointer = nil; {$IFNDEF PAS2C}{$IFNDEF IPHONEOS}cdecl;{$ENDIF} export;{$ENDIF}

function ParamCount: LongInt;
function ParamStr(i: LongInt): shortstring;
{$ENDIF}

implementation
uses uVariables, uTypes, uUtils, uSound, uConsts;
var isInternal: Boolean;
    helpCommandUsed: Boolean;

{$IFDEF HWLIBRARY}

type PCharArray = array[0..255] of PChar;
     PPCharArray = ^PCharArray;

function ParamCount: LongInt;
begin
    ParamCount:= operatingsystem_parameter_argc - 1
end;

function ParamStr(i: LongInt): shortstring;
begin
    ParamStr:= StrPas(PPCharArray(operatingsystem_parameter_argv)^[i])
end;

{$ENDIF}

procedure GciEasterEgg;
begin
    WriteLn(stdout, '                                                                ');
    WriteLn(stdout, '      /\\\\\\\\\\\\        /\\\\\\\\\  /\\\\\\\\\\\             ');
    WriteLn(stdout, '     /\\\//////////      /\\\////////  \/////\\\///             ');
    WriteLn(stdout, '     /\\\               /\\\/               \/\\\               ');
    WriteLn(stdout, '     \/\\\    /\\\\\\\  /\\\                 \/\\\              ');
    WriteLn(stdout, '      \/\\\   \/////\\\ \/\\\                 \/\\\             ');
    WriteLn(stdout, '       \/\\\       \/\\\ \//\\\                \/\\\            ');
    WriteLn(stdout, '        \/\\\       \/\\\  \///\\\              \/\\\           ');
    WriteLn(stdout, '         \/\\\\\\\\\\\\\/     \////\\\\\\\\\  /\\\\\\\\\\\      ');
    WriteLn(stdout, '          \/////////////          \/////////  \///////////      ');
    WriteLn(stdout, '                                                                ');
    WriteLn(stdout, ' Command Line Parser Implementation by a Google Code-In Student ');
    WriteLn(stdout, '                                                                ');
end;

procedure DisplayUsage;
begin
    WriteLn(stdout, 'This is the Hedgewars Engine (hwengine), used to play Hedgewars games and demos.');
    WriteLn(stdout, 'Use the command-line arguments to play a demo.');
    WriteLn(stdout, '');
    WriteLn(stdout, 'Usage: hwengine <path to demo file> [options]');
    WriteLn(stdout, '');
    WriteLn(stdout, 'where [options] can be any of the following:');
    WriteLn(stdout, '');
    WriteLn(stdout, 'File locations:');
    WriteLn(stdout, '  --prefix <path to folder>: Set the path to the system game data folder');
    WriteLn(stdout, '  --user-prefix <path to folder>: Set the path to the custom data folder to find game content');
    WriteLn(stdout, '  --locale <name of file>: Set the game language (en.txt for example)');
    WriteLn(stdout, '');
    WriteLn(stdout, 'Graphics:');
    WriteLn(stdout, '  --width <width in pixels>: Set game window width');
    WriteLn(stdout, '  --height <height in pixels>: Set game window height');
    WriteLn(stdout, '  --maximized: Start in maximized window');
    WriteLn(stdout, '  --fullscreen: Start in fullscreen');
    WriteLn(stdout, '  --fullscreen-width <width in pixels>: Set fullscreen width');
    WriteLn(stdout, '  --fullscreen-height <height in pixels>: Set fullscreen height');
    WriteLn(stdout, '  --low-quality: Lowers the game quality');
    WriteLn(stdout, '  --zoom <percent>: Start with custom zoom level');
    WriteLn(stdout, '');
    WriteLn(stdout, 'Audio:');
    WriteLn(stdout, '  --volume <sound level>: Set volume between 0 and 100');
    WriteLn(stdout, '  --nomusic: Disable music');
    WriteLn(stdout, '  --nosound: Disable sound effects');
    WriteLn(stdout, '  --nodampen: Don''t dampen sound volume when game application loses focus');
    WriteLn(stdout, '');
    WriteLn(stdout, 'HUD:');
    WriteLn(stdout, '  --altdmg: Show alternative damage');
    WriteLn(stdout, '  --no-teamtag: Disable team name tags');
    WriteLn(stdout, '  --no-hogtag: Disable hedgehog name tags');
    WriteLn(stdout, '  --no-healthtag: Disable hedgehog health tags');
    WriteLn(stdout, '  --translucent-tags: Enable translucent name and health tags');
    WriteLn(stdout, '  --chat-size [default chat size in percent]');
    WriteLn(stdout, '  --showfps: Show frames per second');
    WriteLn(stdout, '');
    WriteLn(stdout, 'Miscellaneous:');
    WriteLn(stdout, '  --nick <name>: Set user nickname');
    WriteLn(stdout, '  --help: Show a list of command-line options and exit');
    WriteLn(stdout, '  --protocol: Display protocol number and exit');
    WriteLn(stdout, '');
    Writeln(stdout, 'Advanced options:');
    Writeln(stdout, '  --stereo <value>: Set stereoscopic rendering (1 to 14)');
    WriteLn(stdout, '  --frame-interval <milliseconds>: Set minimum interval (in ms) between each frame. Eg, 40 would make the game run at most 25 fps');
    WriteLn(stdout, '  --raw-quality <flags>: Manually specify the reduced quality flags');
    WriteLn(stdout, '  --stats-only: Write the round information to console without launching the game, useful for statistics only');
    WriteLn(stdout, '  --lua-test <path to script>: Run a Lua test script');
    GameType:= gmtSyntaxHelp;
    helpCommandUsed:= true;
end;

procedure DisplayProtocol;
begin
    WriteLn(stdout, IntToStr(cNetProtoVersion));
    GameType:= gmtSyntaxHelp;
    helpCommandUsed:= true;
end;

procedure statsOnlyGame;
begin
    cOnlyStats:= true;
    cReducedQuality:= $FFFFFFFF xor rqLowRes;
    SetSound(false);
    SetMusic(false);
    SetVolume(0);
end;

procedure setIpcPort(port: LongInt; var wrongParameter:Boolean);
begin
    if isInternal then
        ipcPort := port
    else
        begin
        WriteLn(stderr, 'ERROR: use of --port is not allowed!');
        wrongParameter := true;
        end
end;

function parseNick(nick: shortstring): shortstring;
begin
    if isInternal then
        parseNick:= DecodeBase64(nick)
    else
        parseNick:= nick;
end;

procedure setStereoMode(tmp: LongInt);
begin
    GrayScale:= false;
{$IFDEF USE_S3D_RENDERING}
    if (tmp > 6) and (tmp < 13) then
        begin
        // set the gray anaglyph rendering
        GrayScale:= true;
        cStereoMode:= TStereoMode(max(0, min(ord(high(TStereoMode)), tmp-6)))
        end
    else if tmp <= 6 then
        // set the fullcolor anaglyph
        cStereoMode:= TStereoMode(max(0, min(ord(high(TStereoMode)), tmp)))
    else
        // any other mode
        cStereoMode:= TStereoMode(max(0, min(ord(high(TStereoMode)), tmp-6)));
{$ELSE}
    tmp:= tmp;
    cStereoMode:= smNone;
{$ENDIF}
end;

procedure startVideoRecording(var paramIndex: LongInt);
begin
    // Silence the hint that appears when USE_VIDEO_RECORDING is not defined
    paramIndex:= paramIndex;
{$IFDEF USE_VIDEO_RECORDING}
{$IFNDEF HWLIBRARY}
    GameType:= gmtRecord;
    inc(paramIndex);
    cVideoFramerateNum:= StrToInt(ParamStr(paramIndex)); inc(paramIndex);
    cVideoFramerateDen:= StrToInt(ParamStr(paramIndex)); inc(paramIndex);
    RecPrefix:= ParamStr(paramIndex);                    inc(paramIndex);
    cAVFormat:= ParamStr(paramIndex);                    inc(paramIndex);
    cVideoCodec:= ParamStr(paramIndex);                  inc(paramIndex);
    cVideoQuality:= StrToInt(ParamStr(paramIndex));      inc(paramIndex);
    cAudioCodec:= ParamStr(paramIndex);                  inc(paramIndex);
{$ENDIF}
{$ENDIF}
end;

function getLongIntParameter(str:shortstring; var paramIndex:LongInt; var wrongParameter:Boolean): LongInt;
var tmpInt, c: LongInt;
begin
    inc(paramIndex);
{$IFDEF PAS2C OR HWLIBRARY}
    val(str, tmpInt);
{$ELSE}
    val(str, tmpInt, c);
    wrongParameter:= c <> 0;
    if wrongParameter then
        WriteLn(stderr, 'ERROR: '+ParamStr(paramIndex-1)+' expects a number, you passed "'+str+'"!');
{$ENDIF}
    getLongIntParameter:= tmpInt;
end;

function getstringParameter(str:shortstring; var paramIndex:LongInt; var wrongParameter:Boolean): shortstring;
begin
    inc(paramIndex);
    wrongParameter:= (str='') or (Copy(str,1,2) = '--');
    {$IFNDEF HWLIBRARY}
    if wrongParameter then
        WriteLn(stderr, 'ERROR: '+ParamStr(paramIndex-1)+' expects a string, you passed "'+str+'"!');
    {$ENDIF}
    getstringParameter:= str;
end;

procedure setZoom(str:shortstring; var paramIndex:LongInt; var wrongParameter:Boolean);
var param: LongInt;
begin
    param:= getLongIntParameter(str, paramIndex, wrongParameter);

    if param = 100 then
        exit;
    UserZoom:= (param/100.0) * cDefaultZoomLevel;

    if UserZoom < cMaxZoomLevel then
        UserZoom:= cMaxZoomLevel;
    if UserZoom > cMinZoomLevel then
        UserZoom:= cMinZoomLevel;
    zoom:= UserZoom;
    ZoomValue:= UserZoom;
end;

function parseParameter(cmd:string; arg:string; var paramIndex:LongInt): Boolean;
const reallyAll: array[0..37] of shortstring = (
                '--prefix', '--user-prefix', '--locale', '--fullscreen-width', '--fullscreen-height', '--width',
                '--height', '--maximized', '--frame-interval', '--volume','--nomusic', '--nosound', '--nodampen',
                '--fullscreen', '--showfps', '--altdmg', '--low-quality', '--raw-quality', '--stereo', '--nick',
                '--zoom',
  {internal}    '--internal', '--port', '--recorder', '--landpreview',
  {misc}        '--stats-only', '--gci', '--help','--protocol', '--no-teamtag','--no-hogtag','--no-healthtag','--translucent-tags','--lua-test','--no-holiday-silliness','--chat-size', '--prefix64', '--user-prefix64');
var cmdIndex: byte;
begin
    parseParameter:= false;
    cmdIndex:= 0;

    //NOTE: Any update to the list of parameters must be reflected in the case statement below, the reallyAll array above,
    //      the the DisplayUsage() procedure, the HWForm::getDemoArguments() function, and the online wiki

    while (cmdIndex <= High(reallyAll)) and (cmd <> reallyAll[cmdIndex]) do inc(cmdIndex);
    case cmdIndex of
        {--prefix}               0 : PathPrefix        := getstringParameter (arg, paramIndex, parseParameter);
        {--user-prefix}          1 : UserPathPrefix    := getstringParameter (arg, paramIndex, parseParameter);
        {--locale}               2 : cLanguageFName    := getstringParameter (arg, paramIndex, parseParameter);
        {--fullscreen-width}     3 : cFullscreenWidth  := max(getLongIntParameter(arg, paramIndex, parseParameter), cMinScreenWidth);
        {--fullscreen-height}    4 : cFullscreenHeight := max(getLongIntParameter(arg, paramIndex, parseParameter), cMinScreenHeight);
        {--width}                5 : cWindowedWidth    := max(2 * (getLongIntParameter(arg, paramIndex, parseParameter) div 2), cMinScreenWidth);
        {--height}               6 : cWindowedHeight   := max(2 * (getLongIntParameter(arg, paramIndex, parseParameter) div 2), cMinScreenHeight);
        {--maximized}            7 : cWindowedMaximized:= true;
        {--frame-interval}       8 : cTimerInterval    := getLongIntParameter(arg, paramIndex, parseParameter);
        {--volume}               9 : SetVolume          ( max(getLongIntParameter(arg, paramIndex, parseParameter), 0) );
        {--nomusic}             10 : SetMusic           ( false );
        {--nosound}             11 : SetSound           ( false );
        {--nodampen}            12 : SetAudioDampen     ( false );
        {--fullscreen}          13 : cFullScreen       := true;
        {--showfps}             14 : cShowFPS          := true;
        {--altdmg}              15 : cAltDamage        := true;
        {--low-quality}         16 : cReducedQuality   := $FFFFFFFF xor rqLowRes;
        {--raw-quality}         17 : cReducedQuality   := getLongIntParameter(arg, paramIndex, parseParameter);
        {--stereo}              18 : setStereoMode      ( getLongIntParameter(arg, paramIndex, parseParameter) );
        {--nick}                19 : UserNick          := parseNick( getstringParameter(arg, paramIndex, parseParameter) );
        {--zoom}                20 : setZoom(arg, paramIndex, parseParameter);
        {"internal" options}
        {--internal}            21 : {$IFDEF HWLIBRARY}isInternal:= true{$ENDIF};
        {--port}                22 : setIpcPort( getLongIntParameter(arg, paramIndex, parseParameter), parseParameter );
        {--recorder}            23 : startVideoRecording(paramIndex);
        {--landpreview}         24 : GameType := gmtLandPreview;
        {anything else}
        {--stats-only}          25 : statsOnlyGame();
        {--gci}                 26 : GciEasterEgg();
        {--help}                27 : DisplayUsage();
        {--protocol}            28 : DisplayProtocol();
        {--no-teamtag}          29 : cTagsMask := cTagsMask and (not htTeamName);
        {--no-hogtag}           30 : cTagsMask := cTagsMask and (not htName);
        {--no-healthtag}        31 : cTagsMask := cTagsMask and (not htHealth);
        {--translucent-tags}    32 : cTagsMask := cTagsMask or htTransparent;
        {--lua-test}            33 : begin cTestLua := true; SetSound(false); cScriptName := getstringParameter(arg, paramIndex, parseParameter); WriteLn(stdout, 'Lua test file specified: ' + cScriptName);end;
        {--no-holiday-silliness} 34 : cHolidaySilliness:= false;
        {--chat-size}           35 : cDefaultChatScale := 1.0 * getLongIntParameter(arg, paramIndex, parseParameter) / 100;
        {--prefix64}            36: PathPrefix := DecodeBase64(getstringParameter(arg, paramIndex, parseParameter));
        {--user-prefix64}       37: UserPathPrefix := DecodeBase64(getstringParameter(arg, paramIndex, parseParameter));
    else
        begin
        //Assume the first "non parameter" is the demo file, anything else is invalid
        if (recordFileName = '') and (Copy(cmd,1,2) <> '--') then
            recordFileName := cmd
        else
            begin
            WriteLn(stderr, '"'+cmd+'" is not a valid option.');
            parseParameter:= true;
            end;
        end;
    end;
end;

procedure parseCommandLine;
var paramIndex: LongInt;
    paramTotal: LongInt;
    index, nextIndex: LongInt;
    wrongParameter: boolean;
//var tmpInt: LongInt;
begin

    paramIndex:= {$IFDEF HWLIBRARY}0{$ELSE}1{$ENDIF};
    paramTotal:= ParamCount; //-1 because pascal enumeration is inclusive
    wrongParameter:= false;
    while (paramIndex <= paramTotal) do
        begin
        // avoid going past the number of paramTotal (esp. w/ library)
        index:= paramIndex;
        if index = paramTotal then nextIndex:= index
        else nextIndex:= index+1;
        wrongParameter:= parseParameter( ParamStr(index), ParamStr(nextIndex), paramIndex);
        inc(paramIndex);
        end;
    if wrongParameter = true then
        GameType:= gmtBadSyntax;
end;

procedure GetParams;
begin
    isInternal:= (ParamStr(1) = '--internal');
    helpCommandUsed:= false;

    UserPathPrefix := _S'.';
    PathPrefix     := cDefaultPathPrefix;
    recordFileName := '';
    parseCommandLine();

    if (isInternal) and (ParamCount<=1) then
        begin
        WriteLn(stderr, 'The "--internal" option should not be manually used!');
        GameType := gmtBadSyntax;
        end;

    if (not helpCommandUsed) then
        if (not cTestLua) and (not isInternal) and (recordFileName = '') then
            begin
            WriteLn(stderr, 'You must specify a demo file.');
            GameType := gmtBadSyntax;
            end
        else if (recordFileName <> '') then
            WriteLn(stdout, 'Attempting to play demo file "' + recordFilename + '".');

    if (GameType = gmtBadSyntax) then
        WriteLn(stderr, 'Please use --help to see possible arguments and their usage.');

end;

end.

