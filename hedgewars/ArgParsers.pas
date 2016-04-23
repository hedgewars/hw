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
var operatingsystem_parameter_argc: LongInt = 0; {$IFNDEF PAS2C}cdecl; export;{$ENDIF}
    operatingsystem_parameter_argv: pointer = nil; {$IFNDEF PAS2C}cdecl; export;{$ENDIF}
    operatingsystem_parameter_envp: pointer = nil; {$IFNDEF PAS2C}cdecl; export;{$ENDIF}

function ParamCount: LongInt;
function ParamStr(i: LongInt): shortstring;
{$ENDIF}

implementation
uses uVariables, uTypes, uUtils, uSound, uConsts;
var isInternal: Boolean;

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
    WriteLn(stdout, 'Usage: hwengine <path to replay file> [options]');
    WriteLn(stdout, '');
    WriteLn(stdout, 'where [options] can be any of the following:');
    WriteLn(stdout, ' --prefix [path to folder]');
    WriteLn(stdout, ' --user-prefix [path to folder]');
    WriteLn(stdout, ' --locale [name of language file]');
    WriteLn(stdout, ' --nick [string]');
    WriteLn(stdout, ' --fullscreen-width [fullscreen width in pixels]');
    WriteLn(stdout, ' --fullscreen-height [fullscreen height in pixels]');
    WriteLn(stdout, ' --width [window width in pixels]');
    WriteLn(stdout, ' --height [window height in pixels]');
    WriteLn(stdout, ' --volume [sound level]');
    WriteLn(stdout, ' --frame-interval [milliseconds]');
    Writeln(stdout, ' --stereo [value]');
    WriteLn(stdout, ' --raw-quality [flags]');
    WriteLn(stdout, ' --low-quality');
    WriteLn(stdout, ' --nomusic');
    WriteLn(stdout, ' --nosound');
    WriteLn(stdout, ' --fullscreen');
    WriteLn(stdout, ' --showfps');
    WriteLn(stdout, ' --altdmg');
    WriteLn(stdout, ' --no-teamtag');
    WriteLn(stdout, ' --no-hogtag');
    WriteLn(stdout, ' --no-healthtag');
    WriteLn(stdout, ' --translucent-tags');
    WriteLn(stdout, ' --stats-only');
    WriteLn(stdout, ' --help');
    WriteLn(stdout, '');
    WriteLn(stdout, 'For more detailed help and examples go to:');
    WriteLn(stdout, 'http://hedgewars.org/kb/CommandLineOptions');
    GameType:= gmtSyntax;
end;

procedure setDepth(var paramIndex: LongInt);
begin
    WriteLn(stdout, 'WARNING: --depth is a deprecated command, which could be removed in a future version!');
    WriteLn(stdout, '         This option no longer does anything, please consider removing it');
    WriteLn(stdout, '');
   inc(ParamIndex);
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
        WriteLn(stderr, 'ERROR: use of --port is not allowed');
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
        WriteLn(stderr, 'ERROR: '+ParamStr(paramIndex-1)+' expects a number, you passed "'+str+'"');
{$ENDIF}
    getLongIntParameter:= tmpInt;
end;

function getstringParameter(str:shortstring; var paramIndex:LongInt; var wrongParameter:Boolean): shortstring;
begin
    inc(paramIndex);
    wrongParameter:= (str='') or (Copy(str,1,2) = '--');
    {$IFNDEF HWLIBRARY}
    if wrongParameter then
        WriteLn(stderr, 'ERROR: '+ParamStr(paramIndex-1)+' expects a string, you passed "'+str+'"');
    {$ENDIF}
    getstringParameter:= str;
end;

procedure parseClassicParameter(cmdarray: array of string; size:LongInt; var paramIndex:LongInt); forward;

function parseParameter(cmd:string; arg:string; var paramIndex:LongInt): Boolean;
const videoarray: array [0..4] of string = ('--fullscreen-width','--fullscreen-height', '--width', '--height', '--depth');
      audioarray: array [0..2] of string = ('--volume','--nomusic','--nosound');
      otherarray: array [0..2] of string = ('--locale','--fullscreen','--showfps');
      mediaarray: array [0..9] of string = ('--fullscreen-width', '--fullscreen-height', '--width', '--height', '--depth', '--volume','--nomusic','--nosound','--locale','--fullscreen');
      allarray: array [0..17] of string = ('--fullscreen-width','--fullscreen-height', '--width', '--height', '--depth','--volume','--nomusic','--nosound','--locale','--fullscreen','--showfps','--altdmg','--frame-interval','--low-quality','--no-teamtag','--no-hogtag','--no-healthtag','--translucent-tags');
      reallyAll: array[0..35] of shortstring = (
                '--prefix', '--user-prefix', '--locale', '--fullscreen-width', '--fullscreen-height', '--width',
                '--height', '--frame-interval', '--volume','--nomusic', '--nosound',
                '--fullscreen', '--showfps', '--altdmg', '--low-quality', '--raw-quality', '--stereo', '--nick',
  {deprecated}  '--depth', '--set-video', '--set-audio', '--set-other', '--set-multimedia', '--set-everything',
  {internal}    '--internal', '--port', '--recorder', '--landpreview',
  {misc}        '--stats-only', '--gci', '--help','--no-teamtag','--no-hogtag','--no-healthtag','--translucent-tags','--lua-test');
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
        {--locale}               2 : cLocaleFName      := getstringParameter (arg, paramIndex, parseParameter);
        {--fullscreen-width}     3 : cFullscreenWidth  := max(getLongIntParameter(arg, paramIndex, parseParameter), cMinScreenWidth);
        {--fullscreen-height}    4 : cFullscreenHeight := max(getLongIntParameter(arg, paramIndex, parseParameter), cMinScreenHeight);
        {--width}                5 : cWindowedWidth    := max(2 * (getLongIntParameter(arg, paramIndex, parseParameter) div 2), cMinScreenWidth);
        {--height}               6 : cWindowedHeight   := max(2 * (getLongIntParameter(arg, paramIndex, parseParameter) div 2), cMinScreenHeight);
        {--frame-interval}       7 : cTimerInterval    := getLongIntParameter(arg, paramIndex, parseParameter);
        {--volume}               8 : SetVolume          ( max(getLongIntParameter(arg, paramIndex, parseParameter), 0) );
        {--nomusic}              9 : SetMusic           ( false );
        {--nosound}             10 : SetSound           ( false );
        {--fullscreen}          11 : cFullScreen       := true;
        {--showfps}             12 : cShowFPS          := true;
        {--altdmg}              13 : cAltDamage        := true;
        {--low-quality}         14 : cReducedQuality   := $FFFFFFFF xor rqLowRes;
        {--raw-quality}         15 : cReducedQuality   := getLongIntParameter(arg, paramIndex, parseParameter);
        {--stereo}              16 : setStereoMode      ( getLongIntParameter(arg, paramIndex, parseParameter) );
        {--nick}                17 : UserNick          := parseNick( getstringParameter(arg, paramIndex, parseParameter) );
        {deprecated options}
        {--depth}               18 : setDepth(paramIndex);
        {--set-video}           19 : parseClassicParameter(videoarray,5,paramIndex);
        {--set-audio}           20 : parseClassicParameter(audioarray,3,paramIndex);
        {--set-other}           21 : parseClassicParameter(otherarray,3,paramIndex);
        {--set-multimedia}      22 : parseClassicParameter(mediaarray,10,paramIndex);
        {--set-everything}      23 : parseClassicParameter(allarray,14,paramIndex);
        {"internal" options}
        {--internal}            24 : {$IFDEF HWLIBRARY}isInternal:= true{$ENDIF};
        {--port}                25 : setIpcPort( getLongIntParameter(arg, paramIndex, parseParameter), parseParameter );
        {--recorder}            26 : startVideoRecording(paramIndex);
        {--landpreview}         27 : GameType := gmtLandPreview;
        {anything else}
        {--stats-only}          28 : statsOnlyGame();
        {--gci}                 29 : GciEasterEgg();
        {--help}                30 : DisplayUsage();
        {--no-teamtag}          31 : cTagsMask := cTagsMask and (not htTeamName);
        {--no-hogtag}           32 : cTagsMask := cTagsMask and (not htName);
        {--no-healthtag}        33 : cTagsMask := cTagsMask and (not htHealth);
        {--translucent-tags}    34 : cTagsMask := cTagsMask or htTransparent;
        {--lua-test}            35 : begin cTestLua := true; SetSound(false); cScriptName := getstringParameter(arg, paramIndex, parseParameter); WriteLn(stdout, 'Lua test file specified: ' + cScriptName);end;
    else
        begin
        //Assume the first "non parameter" is the replay file, anything else is invalid
        if (recordFileName = '') and (Copy(cmd,1,2) <> '--') then
            recordFileName := cmd
        else
            begin
            WriteLn(stderr, '"'+cmd+'" is not a valid option');
            parseParameter:= true;
            end;
        end;
    end;
end;

procedure parseClassicParameter(cmdarray: array of string; size:LongInt; var paramIndex:LongInt);
var index, tmpInt: LongInt;
    isBool, isValid: Boolean;
    cmd, arg, newSyntax: string;
begin
    WriteLn(stdout, 'WARNING: you are using a deprecated command, which could be removed in a future version!');
    WriteLn(stdout, '         Consider updating to the latest syntax, which is much more flexible!');
    WriteLn(stdout, '         Run `hwegine --help` to learn it!');
    WriteLn(stdout, '');

    index:= 0;
    tmpInt:= 1;
    while (index < size) do
        begin
        newSyntax:= '';
        inc(paramIndex);
        cmd:= cmdarray[index];
        arg:= cmdarray[paramIndex];
        isValid:= (cmd<>'--depth');

        // check if the parameter is a boolean one
        isBool:= (cmd = '--nomusic') or (cmd = '--nosound') or (cmd = '--fullscreen') or (cmd = '--showfps') or (cmd = '--altdmg') or (cmd = '--no-teamtag') or (cmd = '--no-hogtag') or (cmd = '--no-healthtag') or (cmd = '--translucent-tags');
        if isBool and (arg='0') then
            isValid:= false;
        if (cmd='--nomusic') or (cmd='--nosound') then
            isValid:= not isValid;

        if isValid then
            begin
            parseParameter(cmd, arg, tmpInt);
            newSyntax:= newSyntax + cmd + ' ';
            if not isBool then
                newSyntax:= newSyntax + arg + ' ';
            end;
        inc(index);
        end;

    WriteLn(stdout, 'Attempted to automatically convert to the new syntax:');
    WriteLn(stdout, newSyntax);
    WriteLn(stdout, '');
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
    (*
    WriteLn(stdout, 'total parameters: ' + inttostr(paramTotal));
    tmpInt:= 0;
    while (tmpInt <= paramTotal) do
        begin
        WriteLn(stdout, inttostr(tmpInt) + ': ' + {$IFDEF HWLIBRARY}argv[tmpInt]{$ELSE}paramCount(tmpInt){$ENDIF});
        inc(tmpInt);
        end;
    *)
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
        GameType:= gmtSyntax;
end;

procedure GetParams;
begin
    isInternal:= (ParamStr(1) = '--internal');

    UserPathPrefix := _S'.';
    PathPrefix     := cDefaultPathPrefix;
    recordFileName := '';
    parseCommandLine();

    if (isInternal) and (ParamCount<=1) then
        begin
        WriteLn(stderr, '--internal should not be manually used');
        GameType := gmtSyntax;
        end;

    if (not cTestLua) and (not isInternal) and (recordFileName = '') then
        begin
        WriteLn(stderr, 'You must specify a replay file');
        GameType := gmtSyntax;
        end
    else if (recordFileName <> '') then
        WriteLn(stdout, 'Attempting to play demo file "' + recordFilename + '"');

    if (GameType = gmtSyntax) then
        WriteLn(stderr, 'Please use --help to see possible arguments and their usage');

    (*
    WriteLn(stdout,'PathPrefix:     ' + PathPrefix);
    WriteLn(stdout,'UserPathPrefix: ' + UserPathPrefix);
    *)
end;

end.

