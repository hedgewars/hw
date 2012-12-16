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


procedure internalStartGameWithParameters();
var tmp: LongInt;
begin
    UserPathPrefix:= ParamStr(1);
    cScreenWidth:= StrToInt(ParamStr(2));
    cScreenHeight:= StrToInt(ParamStr(3));
    cBits:= StrToInt(ParamStr(4));
    ipcPort:= StrToInt(ParamStr(5));
    cFullScreen:= ParamStr(6) = '1';
    SetSound(ParamStr(7) = '1');
    SetMusic(ParamStr(8) = '1');
    SetVolume(StrToInt(ParamStr(9)));
    cTimerInterval:= StrToInt(ParamStr(10));
    PathPrefix:= ParamStr(11);
    cShowFPS:= ParamStr(12) = '1';
    cAltDamage:= ParamStr(13) = '1';
    UserNick:= DecodeBase64(ParamStr(14));
    cReducedQuality:= StrToInt(ParamStr(15));
    tmp:= StrToInt(ParamStr(16));
    GrayScale:= false;
{$IFDEF USE_S3D_RENDERING}
    if (tmp > 9) and (tmp < 16) then
        begin
        // set the gray anaglyph rendering
        GrayScale:= true;
        cStereoMode:= TStereoMode(max(0, min(ord(high(TStereoMode)), tmp-9)))
        end
    else if tmp <= 9 then
        // set the fullcolor anaglyph
        cStereoMode:= TStereoMode(max(0, min(ord(high(TStereoMode)), tmp)))
    else
        // any other mode
        cStereoMode:= TStereoMode(max(0, min(ord(high(TStereoMode)), tmp-6)));
{$ELSE}
	cStereoMode:= smNone;
{$ENDIF}
    cLocaleFName:= ParamStr(17);
end;

{$IFDEF USE_VIDEO_RECORDING}
procedure internalStartVideoRecordingWithParameters();
begin
    internalStartGameWithParameters();
    GameType:= gmtRecord;
    cVideoFramerateNum:= StrToInt(ParamStr(18));
    cVideoFramerateDen:= StrToInt(ParamStr(19));
    RecPrefix:= ParamStr(20);
    cAVFormat:= ParamStr(21);
    cVideoCodec:= ParamStr(22);
    cVideoQuality:= StrToInt(ParamStr(23));
    cAudioCodec:= ParamStr(24);
end;
{$ENDIF}

procedure DisplayUsage;
begin
    WriteLn(stdout, 'Usage: hwengine <path to replay file> [options]');
    WriteLn(stdout, '');
    WriteLn(stdout, 'where [options] can be any of the following:');
    WriteLn(stdout, ' --prefix [path to folder]');
    WriteLn(stdout, ' --user-prefix [path to folder]');
    WriteLn(stdout, ' --locale [name of language file]');
    WriteLn(stdout, ' --width [screen width in pixels]');
    WriteLn(stdout, ' --height [screen height in pixels]');
    WriteLn(stdout, ' --volume [sound level]');
    WriteLn(stdout, ' --frame-interval [milliseconds]');
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
const videoArray: Array [1..3] of String = ('--width','--height','--depth');
const audioArray: Array [1..3] of String = ('--volume','--nomusic','--nosound');
const otherArray: Array [1..3] of String = ('--locale','--fullscreen','--showfps');
const mediaArray: Array [1..8] of String = ('--width','--height','--depth','--volume','--nomusic','--nosound','--locale','--fullscreen');
const allArray: Array [1..12] of String = ('--width','--height','--depth','--volume','--nomusic','--nosound','--locale','--fullscreen','--showfps','--altdmg','--time','--lowquality');
const reallyAll: array[0..22] of shortstring = (
                '--prefix', '--user-prefix', '--locale', '--width', '--height', '--frame-interval', '--volume','--nomusic', '--nosound',
                '--fullscreen', '--showfps', '--altdmg', '--low-quality', '--raw-quality',
  {deprecated}  '--depth', '--set-video', '--set-audio', '--set-other', '--set-multimedia', '--set-everything',
                '--stats-only', '--gci', '--help');
var cmdIndex: byte;
begin
    parseParameter:= false;
    cmdIndex:= 0;

    //NOTE: Any update to the list of parameters must be reflected in the case statement below, the reallyAll array above,
    //      the the DisplayUsage() procedure, the HWForm::getDemoArguments() function, and the online wiki

    while (cmdIndex <= High(reallyAll)) and (cmd <> reallyAll[cmdIndex]) do inc(cmdIndex);
    case cmdIndex of
        {--prefix}          0 : PathPrefix     := getStringParameter (arg, paramIndex, parseParameter);
        {--user-prefix}     1 : UserPathPrefix := getStringParameter (arg, paramIndex, parseParameter);
        {--locale}          2 : cLocaleFName   := getStringParameter (arg, paramIndex, parseParameter);
        {--width}           3 : cScreenWidth   := getLongIntParameter(arg, paramIndex, parseParameter);
        {--height}          4 : cScreenHeight  := getLongIntParameter(arg, paramIndex, parseParameter);
        {--frame-interval}  5 : cTimerInterval := getLongIntParameter(arg, paramIndex, parseParameter);
        {--volume}          6 : SetVolume       ( getLongIntParameter(arg, paramIndex, parseParameter) );
        {--nomusic}         7 : SetMusic        ( false );
        {--nosound}         8 : SetSound        ( false );
        {--fullscreen}      9 : cFullScreen    := true;
        {--showfps}        10 : cShowFPS       := true;
        {--altdmg}         11 : cAltDamage     := true;
        {--low-quality}    12 : cReducedQuality:= $FFFFFFFF xor rqLowRes;
        {--raw-quality}    13 : cReducedQuality:= getLongIntParameter(arg, paramIndex, parseParameter);
        {deprecated options}
        {--depth}          14 : cBits          := getLongIntParameter(arg, paramIndex, parseParameter);
        {--set-video}      15 : parseClassicParameter(videoArray,3,paramIndex);
        {--set-audio}      16 : parseClassicParameter(audioArray,3,paramIndex);
        {--set-other}      17 : parseClassicParameter(otherArray,3,paramIndex);
        {--set-multimedia} 18 : parseClassicParameter(mediaArray,8,paramIndex);
        {--set-everything} 19 : parseClassicParameter(allArray,12,paramIndex);
        {anything else}
        {--stats-only}     20 : begin
                                cOnlyStats:= true;
                                cReducedQuality:= $FFFFFFFF xor rqLowRes;
                                SetSound(false);
                                end;
        {--gci}            21 : begin            //     We had to make up all this saved space some how...     \\
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
        {--help}           22 : begin
                                DisplayUsage();
                                GameType:= gmtSyntax;
                                end;
    else
        begin
        //Asusme the first "non parameter" is the replay file, anything else is invalid
        if recordFileName = '' then
            recordFileName := cmd
        else
            begin
            WriteLn(stderr, 'ERROR: '+cmd+' is not a valid argument');
            parseParameter:= true;
            end;
        end;
    end;
end;

procedure parseClassicParameter(cmdArray: Array of String; size:LongInt; var paramIndex:LongInt);
var index, tmpInt: LongInt;
    isBool: Boolean;
begin
    WriteLn(stdout, 'WARNING: you are using a deprecated command, which could be removed in a future version!');
    WriteLn(stdout, '         Consider updating to the latest syntax, which is much more flexible!');
    WriteLn(stdout, '         Run `hwegine --help` to learn it!');
    WriteLn(stdout, '');

    index:= 0;
    tmpInt:= 1;
    while (index < size) do
        begin
        paramIndex:= paramIndex+1;
        // check if the parameter is a boolean one
        isBool:= (cmdArray[index] = '--nomusic')
            or (cmdArray[index] = '--nosound')
            or (cmdArray[index] = '--fullscreen')
            or (cmdArray[index] = '--showfps')
            or (cmdArray[index] = '--altdmg')
            or (cmdArray[index] = '--low-quality');
        if (not isBool) or ((ParamStr(paramIndex)='1') and (cmdArray[index]<>'--nomusic') and (cmdArray[index]<>'--nosound')) then
            parseParameter(cmdArray[index], ParamStr(paramIndex), tmpInt);
        inc(index);
        end;
end;

procedure playReplayFileWithParameters;
var paramIndex: LongInt;
    wrongParameter: boolean;
begin
    paramIndex:= 1;
    wrongParameter:= false;
    while (paramIndex <= ParamCount) do
        begin
        if parseParameter( ParamStr(paramIndex), ParamStr(paramIndex+1), paramIndex) then
            wrongParameter:= true;
        inc(paramIndex);
        end;
    if wrongParameter = true then
        begin
        WriteLn(stderr, 'Please use --help to see possible arguments and their usage');
        GameType:= gmtSyntax;
        end
end;

procedure GetParams;
begin
    (*
    tmpInt:=0;
    while (tmpInt <= ParamCount) do
        begin
        WriteLn(stdout,inttostr(tmpInt) + ': ' + ParamStr(tmpInt));
        inc(tmpInt);
        end;
    *)

    if (ParamCount = 3) and (ParamStr(3) = 'landpreview') then
    begin
        PathPrefix := ParamStr(1);
        ipcPort    := StrToInt(ParamStr(2));
        GameType   := gmtLandPreview;
        exit;
    end;

    //TODO: prepend something so that we can use a cDefaultParamNum of parameters
    if ParamCount = cDefaultParamNum then
    begin
        internalStartGameWithParameters();
        exit;
    end
{$IFDEF USE_VIDEO_RECORDING}
    else if ParamCount = cVideorecParamNum then
    begin
        internalStartVideoRecordingWithParameters();
        exit;
    end
{$ENDIF};

    UserPathPrefix := '.';
    PathPrefix     := cDefaultPathPrefix;
    recordFileName := '';
    playReplayFileWithParameters();

    if (recordFileName = '') then
        begin
        DisplayUsage();
        GameType:= gmtSyntax;
        end;
    (*
    WriteLn(stdout,'PathPrefix:     ' + PathPrefix);
    WriteLn(stdout,'UserPathPrefix: ' + UserPathPrefix);
    WriteLn(stdout,'recordFilename: ' + recordFilename);
    *)
end;


