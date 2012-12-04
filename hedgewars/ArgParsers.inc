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
    WriteLn(stdout, 'Usage:');
    WriteLn(stdout, '');
    WriteLn(stdout, '  hwengine [path to user hedgewars folder] <path to global data folder> <path to replay file> [options]');
    WriteLn(stdout, '');
    WriteLn(stdout, 'where [options] are any of the following:');
    WriteLn(stdout, ' --locale [path to language file]');
    WriteLn(stdout, ' --width  [screen width in pixels]');
    WriteLn(stdout, ' --height [screen height in pixels]');
    WriteLn(stdout, ' --depth  [color depth]');
    WriteLn(stdout, ' --volume [sound level]');
    WriteLn(stdout, ' --time   [number of seconds]');
    WriteLn(stdout, ' --nomusic');
    WriteLn(stdout, ' --nosound');
    WriteLn(stdout, ' --fullscreen');
    WriteLn(stdout, ' --showfps');
    WriteLn(stdout, ' --altdmg');
    WriteLn(stdout, ' --lowquality');
    WriteLn(stdout, ' --stats-only');
    WriteLn(stdout, ' --help');
    WriteLn(stdout, '');
    WriteLn(stdout, 'Deprecated options:');
    WriteLn(stdout, ' --set-video [screen width] [screen height] [color dept]');
    WriteLn(stdout, ' --set-audio [volume] [enable music] [enable sounds]');
    WriteLn(stdout, ' --set-other [language file] [full screen] [show FPS]');
    WriteLn(stdout, ' --set-multimedia [screen width] [screen height] [color dept] [volume] [enable music] [enable sounds] [language file] [full screen]');
    WriteLn(stdout, ' --set-everything [screen width] [screen height] [color dept] [volume] [enable music] [enable sounds] [language file] [full screen] [show FPS] [alternate damage] [timer value] [reduced quality]');
    WriteLn(stdout, '');
    WriteLn(stdout, 'For a more detailed help and examples go to:');
    WriteLn(stdout, 'http://code.google.com/p/hedgewars/wiki/CommandLineOptions');
end;

function getLongIntParameter(str:String; var paramIndex:LongInt; var wrongParameter:Boolean): LongInt;
var tmpInt, c: LongInt;
begin
    paramIndex:= paramIndex + 1;
    val(str, tmpInt, c);
    wrongParameter:= c <> 0;
    if wrongParameter then
        WriteLn(stderr, 'ERROR: '+ParamStr(paramIndex-1)+' expects a number, you passed "'+str+'"');
    getLongIntParameter:= tmpInt;
end;

function getStringParameter(str:String; var paramIndex:LongInt): String;
begin
    paramIndex:= paramIndex + 1;
    getStringParameter:= str;
end;

procedure parseClassicParameter(cmdArray: Array of String; size:LongInt; var paramIndex:LongInt); Forward;

function parseParameter(cmd:String; arg:String; var paramIndex:LongInt): Boolean;
const videoArray: Array [1..3] of String = ('--width','--height','--depth');
const audioArray: Array [1..3] of String = ('--volume','--nomusic','--nosound');
const otherArray: Array [1..3] of String = ('--locale','--fullscreen','--showfps');
const mediaArray: Array [1..8] of String = ('--width','--height','--depth','--volume','--nomusic','--nosound','--locale','--fullscreen');
const allArray: Array [1..12] of String = ('--width','--height','--depth','--volume','--nomusic','--nosound','--locale','--fullscreen','--showfps','--altdmg','--time','--lowquality');
const reallyAll: array[0..19] of shortstring = (
            '--locale', '--width', '--height', '--depth', '--time'
            , '--volume', '--nomusic', '--nosound', '--fullscreen', '--showfps'
            , '--altdmg', '--lowquality', '--set-video', '--set-audio', '--set-other'
            , '--set-multimedia', '--set-everything', '--stats-only', '--gci', '--help');
var cmdIndex: byte;
begin
    parseParameter:= false;
    cmdIndex:= 0;
    while (cmdIndex <= High(reallyAll)) and (cmd <> reallyAll[cmdIndex]) do inc(cmdIndex);
    case cmdIndex of
        {--locale}   0 : cLocaleFName   := getStringParameter (arg, paramIndex);
        {--width}    1 : cScreenWidth   := getLongIntParameter(arg, paramIndex, parseParameter);
        {--height}   2 : cScreenHeight  := getLongIntParameter(arg, paramIndex, parseParameter);
        {--depth}    3 : cBits          := getLongIntParameter(arg, paramIndex, parseParameter);
        {--time}     4 : cTimerInterval := getLongIntParameter(arg, paramIndex, parseParameter);
        {--volume}   5 : SetVolume       ( getLongIntParameter(arg, paramIndex, parseParameter) );
        {--nomusic}  6 : SetMusic        ( false );
        {--nosound}  7 : SetSound        ( false );
        {--fullscreen}   8 : cFullScreen    := true;
        {--showfps}      9 : cShowFPS       := true;
        {--altdmg}      10 : cAltDamage     := true;
        {--lowquality}  11 : cReducedQuality:= ($FFFFFFFF * getLongIntParameter(arg, paramIndex, parseParameter)) xor rqLowRes; //HACK!
        {--set-video}   12 : parseClassicParameter(videoArray,3,paramIndex);
        {--set-audio}   13 : parseClassicParameter(audioArray,3,paramIndex);
        {--set-other}   14 : parseClassicParameter(otherArray,3,paramIndex);
        {--set-multimedia}  15 : parseClassicParameter(mediaArray,8,paramIndex);
        {--set-everything}  16 : parseClassicParameter(allArray,12,paramIndex);
        {--stats-only}  17 : begin
                             cOnlyStats:= true;
                             SetSound(false);
                             SetMusic(false);
                             cReducedQuality:= $FFFFFFFF xor rqLowRes;
                             end;
        {--gci}  18 : begin            //     We had to make up all this saved space some how...     \\
                      WriteLn(stdout, '                                                                ');
                      WriteLn(stdout, '      /\\\\\\\\\\\\        /\\\\\\\\\  /\\\\\\\\\\\             ');
                      WriteLn(stdout, '     /\\\//////////      /\\\////////  \/////\\\///             ');
                      WriteLn(stdout, '     /\\\               /\\\/               \/\\\               ');
                      WriteLn(stdout, '     \/\\\    /\\\\\\\  /\\\                 \/\\\              ');
                      WriteLn(stdout, '      \/\\\   \/////\\\ \/\\\                 \/\\\             ');
                      WriteLn(stdout, '       \/\\\       \/\\\ \//\\\                \/\\\            ');
                      WriteLn(stdout, '        \/\\\       \/\\\  \///\\\              \/\\\           ');
                      WriteLn(stdout, '         \//\\\\\\\\\\\\/     \////\\\\\\\\\  /\\\\\\\\\\\      ');
                      WriteLn(stdout, '          \////////////           \/////////  \///////////      ');
                      WriteLn(stdout, '                                                                ');
                      WriteLn(stdout, ' Command Line Parser Implementation by a Google Code-In Student ');
                      WriteLn(stdout, '             ASCII Art easter egg idea by @sheepluva            ');
                      WriteLn(stdout, '                                                                ');
                      end;
        {--help}  19 : begin
                       DisplayUsage();
                       GameType:= gmtSyntax;
                       end;
    else
        begin
        WriteLn(stderr, 'ERROR: '+cmd+' is not a valid argument');
        parseParameter:= true;
        end
    end;
end;

procedure parseClassicParameter(cmdArray: Array of String; size:LongInt; var paramIndex:LongInt);
var index, tmpInt: LongInt;
    isBool: Boolean;
begin
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
            or (cmdArray[index] = '--lowquality');
        if (not isBool) or ((ParamStr(paramIndex)='1') and (cmdArray[index]<>'--nomusic') and (cmdArray[index]<>'--nosound')) then
            parseParameter(cmdArray[index], ParamStr(paramIndex), tmpInt);
        index:= index+1;
        end;
end;

procedure playReplayFileWithParameters(paramIndex: LongInt);
var tmpInt: LongInt;
    wrongParameter: boolean;
begin
    wrongParameter:= false;
    while (paramIndex <= ParamCount) do
        begin
        if parseParameter( ParamStr(paramIndex), ParamStr(paramIndex+1), paramIndex) then
            wrongParameter:= true;
        paramIndex:= paramIndex+1;
        end;
    if wrongParameter = true then
        begin
        WriteLn(stderr, 'Please use --help to see possible arguments and their usage');
        GameType:= gmtSyntax;
        end
end;
