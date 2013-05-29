(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2013 Andrey Korotaev <unC0Rr@gmail.com>
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
    WriteLn(stdout, '             ASCII Art easter egg idea by @sheepluva            ');
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
    WriteLn(stdout, ' --stats-only');
    WriteLn(stdout, ' --help');
    WriteLn(stdout, '');
    WriteLn(stdout, 'For more detailed help and examples go to:');
    WriteLn(stdout, 'http://code.google.com/p/hedgewars/wiki/CommandLineOptions');
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

function parseNick(nick: String): String;
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
end;

function getLongIntParameter(str:String; var paramIndex:LongInt; var wrongParameter:Boolean): LongInt;
var tmpInt, c: LongInt;
begin
    inc(paramIndex);
    val(str, tmpInt, c);
    wrongParameter:= c <> 0;
    if wrongParameter then
        WriteLn(stderr, 'ERROR: '+ParamStr(paramIndex-1)+' expects a number, you passed "'+str+'"');
    getLongIntParameter:= tmpInt;
end;

function getStringParameter(str:String; var paramIndex:LongInt; var wrongParameter:Boolean): String;
begin
    inc(paramIndex);
    wrongParameter:= (str='') or (Copy(str,1,2) = '--');
    if wrongParameter then
         WriteLn(stderr, 'ERROR: '+ParamStr(paramIndex-1)+' expects a string, you passed "'+str+'"');
    getStringParameter:= str;
end;


procedure parseClassicParameter(cmdArray: Array of String; size:LongInt; var paramIndex:LongInt); Forward;

function parseParameter(cmd:String; arg:String; var paramIndex:LongInt): Boolean;
const videoArray: Array [1..5] of String = ('--fullscreen-width','--fullscreen-height', '--width', '--height', '--depth');
      audioArray: Array [1..3] of String = ('--volume','--nomusic','--nosound');
      otherArray: Array [1..3] of String = ('--locale','--fullscreen','--showfps');
      mediaArray: Array [1..10] of String = ('--fullscreen-width', '--fullscreen-height', '--width', '--height', '--depth', '--volume','--nomusic','--nosound','--locale','--fullscreen');
      allArray: Array [1..14] of String = ('--fullscreen-width','--fullscreen-height', '--width', '--height', '--depth','--volume','--nomusic','--nosound','--locale','--fullscreen','--showfps','--altdmg','--frame-interval','--low-quality');
      reallyAll: array[0..30] of shortstring = (
                '--prefix', '--user-prefix', '--locale', '--fullscreen-width', '--fullscreen-height', '--width',
                '--height', '--frame-interval', '--volume','--nomusic', '--nosound',
                '--fullscreen', '--showfps', '--altdmg', '--low-quality', '--raw-quality', '--stereo', '--nick',
  {deprecated}  '--depth', '--set-video', '--set-audio', '--set-other', '--set-multimedia', '--set-everything',
  {internal}    '--internal', '--port', '--recorder', '--landpreview',
  {misc}        '--stats-only', '--gci', '--help');
var cmdIndex: byte;
begin
    parseParameter:= false;
    cmdIndex:= 0;

    //NOTE: Any update to the list of parameters must be reflected in the case statement below, the reallyAll array above,
    //      the the DisplayUsage() procedure, the HWForm::getDemoArguments() function, and the online wiki

    while (cmdIndex <= High(reallyAll)) and (cmd <> reallyAll[cmdIndex]) do inc(cmdIndex);
    case cmdIndex of
        {--prefix}               0 : PathPrefix        := getStringParameter (arg, paramIndex, parseParameter);
        {--user-prefix}          1 : UserPathPrefix    := getStringParameter (arg, paramIndex, parseParameter);
        {--locale}               2 : cLocaleFName      := getStringParameter (arg, paramIndex, parseParameter);
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
        {--nick}                17 : UserNick          := parseNick( getStringParameter(arg, paramIndex, parseParameter) );
        {deprecated options}
        {--depth}               18 : setDepth(paramIndex);
        {--set-video}           19 : parseClassicParameter(videoArray,5,paramIndex);
        {--set-audio}           20 : parseClassicParameter(audioArray,3,paramIndex);
        {--set-other}           21 : parseClassicParameter(otherArray,3,paramIndex);
        {--set-multimedia}      22 : parseClassicParameter(mediaArray,10,paramIndex);
        {--set-everything}      23 : parseClassicParameter(allArray,14,paramIndex);
        {"internal" options}
        {--internal}            24 : {$IFDEF HWLIBRARY}isInternal:= true{$ENDIF};
        {--port}                25 : setIpcPort( getLongIntParameter(arg, paramIndex, parseParameter), parseParameter );
        {--recorder}            26 : startVideoRecording(paramIndex);
        {--landpreview}         27 : GameType := gmtLandPreview;
        {anything else}
        {--stats-only}          28 : statsOnlyGame();
        {--gci}                 29 : GciEasterEgg();
        {--help}                30 : DisplayUsage();
    else
        begin
        //Asusme the first "non parameter" is the replay file, anything else is invalid
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

procedure parseClassicParameter(cmdArray: Array of String; size:LongInt; var paramIndex:LongInt);
var index, tmpInt: LongInt;
    isBool, isValid: Boolean;
    cmd, arg, newSyntax: String;
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
        cmd:= cmdArray[index];
        arg:= ParamStr(paramIndex);
        isValid:= (cmd<>'--depth');

        // check if the parameter is a boolean one
        isBool:= (cmd = '--nomusic') or (cmd = '--nosound') or (cmd = '--fullscreen') or (cmd = '--showfps') or (cmd = '--altdmg');
        if isBool and (arg='0') then
            isValid:= false;
        if (cmd='--nomusic') or (cmd='--nosound') then
            isValid:= not isValid;

        if isValid then
            begin
            parseParameter(cmd, arg, tmpInt);
            newSyntax := newSyntax + cmd + ' ';
            if not isBool then
                newSyntax := newSyntax + arg + ' ';
            end;
        inc(index);
        end;

    WriteLn(stdout, 'Attempted to automatically convert to the new syntax:');
    WriteLn(stdout, newSyntax);
    WriteLn(stdout, '');
end;

procedure parseCommandLine{$IFDEF HWLIBRARY}(argc: LongInt; argv: PPChar){$ENDIF};
var paramIndex: LongInt;
    paramTotal: LongInt;
    index, nextIndex: LongInt;
    wrongParameter: boolean;
//var tmpInt: LongInt;
begin
    paramIndex:= {$IFDEF HWLIBRARY}0{$ELSE}1{$ENDIF};
    paramTotal:= {$IFDEF HWLIBRARY}argc-1{$ELSE}ParamCount{$ENDIF}; //-1 because pascal enumeration is inclusive
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
        {$IFDEF HWLIBRARY}
        wrongParameter:= parseParameter( argv[index], argv[nextIndex], paramIndex);
        {$ELSE}
        wrongParameter:= parseParameter( ParamStr(index), ParamStr(nextIndex), paramIndex);
        {$ENDIF}
        inc(paramIndex);
        end;
    if wrongParameter = true then
        GameType:= gmtSyntax;
end;

{$IFNDEF HWLIBRARY}
procedure GetParams;
begin
    isInternal:= (ParamStr(1) = '--internal');

    UserPathPrefix := '.';
    PathPrefix     := cDefaultPathPrefix;
    recordFileName := '';
    parseCommandLine();

    if (isInternal) and (ParamCount<=1) then
        begin
        WriteLn(stderr, '--internal should not be manually used');
        GameType := gmtSyntax;
        end;

    if (not isInternal) and (recordFileName = '') then
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
{$ENDIF}

