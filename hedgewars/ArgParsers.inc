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

procedure playReplayFileWithParameters(); forward;

procedure internalSetGameTypeLandPreviewFromParameters();
begin
    if ParamStr(3) = '--stats-only' then
        playReplayFileWithParameters()
    else
        begin
        ipcPort:= StrToInt(ParamStr(2));
        GameType:= gmtLandPreview;
        if ParamStr(3) <> 'landpreview' then
            GameType:= gmtSyntax
        end
end;

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
    if (tmp > 9) and (tmp < 16) then 
        begin
        GrayScale:= true;
        cStereoMode:= TStereoMode(max(0, min(ord(high(TStereoMode)), tmp-9)))
        end
    else if tmp <= 9 then 
        cStereoMode:= TStereoMode(max(0, min(ord(high(TStereoMode)), tmp)))
    else 
        cStereoMode:= TStereoMode(max(0, min(ord(high(TStereoMode)), tmp-6)));
    cLocaleFName:= ParamStr(17);
{$IFDEF USE_VIDEO_RECORDING}
    cVideoFramerateNum:= StrToInt(ParamStr(18));
    cVideoFramerateDen:= StrToInt(ParamStr(19));
{$ENDIF}
end;

{$IFDEF USE_VIDEO_RECORDING}
procedure internalStartVideoRecordingWithParameters();
begin
    internalStartGameWithParameters();
    GameType:= gmtRecord;
    cRecPrefix:= ParamStr(20);
    cAVFormat:= ParamStr(21);
    cVideoCodec:= ParamStr(22);
    cVideoQuality:= StrToInt(ParamStr(23));
    cVideoPreset:= ParamStr(24);
    cAudioCodec:= ParamStr(25);
    cAudioQuality:= StrToInt(ParamStr(26));
end;
{$ENDIF}

procedure setVideo(screenWidth: LongInt; screenHeight: LongInt; bitsStr: LongInt);
begin
    cScreenWidth:= screenWidth;
    cScreenHeight:= screenHeight;
    cBits:= bitsStr
end;

procedure setVideoWithParameters(screenWidthParam: string; screenHeightParam: string; bitsParam: string);
var screenWidthAsInt, screenHeightAsInt, bitsStrAsInt, c: LongInt;
begin
    val(screenWidthParam, screenWidthAsInt, c);
    val(screenHeightParam, screenHeightAsInt, c);
    val(bitsParam, bitsStrAsInt, c);
    setVideo(screenWidthAsInt,screenHeightAsInt,bitsStrAsInt)
end;

procedure setOtherOptions(languageFile: string; fullScreen: boolean);
begin
    cLocaleFName:= languageFile;
    cFullScreen:= fullScreen
end;

procedure setShowFPS(showFPS: boolean);
begin
    cShowFPS:= showFPS
end;

procedure setOtherOptionsWithParameters(languageFileParam: string; fullScreenParam: string; showFPSParam: string);
var fullScreen, showFPS: boolean;
begin
    fullScreen:= fullScreenParam = '1';
    showFPS:= showFPSParam = '1';
    setOtherOptions(languageFileParam,fullScreen);
    setShowFPS(showFPS)
end;

procedure setAudio(initialVolume: LongInt; musicEnabled: boolean; soundEnabled: boolean);
begin
    SetVolume(initialVolume);
    SetMusic(musicEnabled);
    SetSound(soundEnabled);
end;

procedure setAudioWithParameters(initialVolumeParam: string; musicEnabledParam: string; soundEnabledParam: string);
var initialVolumeAsInt, c: LongInt;
    musicEnabled, soundEnabled: boolean;
begin
    val(initialVolumeParam, initialVolumeAsInt, c);
    musicEnabled:= musicEnabledParam = '1';
    soundEnabled:= soundEnabledParam = '1';
    setAudio(initialVolumeAsInt,musicEnabled, soundEnabled)
end;

procedure setMultimediaOptionsWithParameters(screenWidthParam, screenHeightParam, bitsParam: string;
                                             initialVolumeParam, musicEnabledParam, soundEnabledParam: string;
                                             languageFileParam, fullScreenParam: string);
begin
    setVideoWithParameters(screenWidthParam,screenHeightParam, bitsParam);
    setAudioWithParameters(initialVolumeParam,musicEnabledParam,soundEnabledParam);
    setOtherOptions(languageFileParam,fullScreenParam = '1')
end;

procedure setAltDamageTimerValueAndQuality(altDamage: boolean; timeIterval: LongInt; reducedQuality: boolean);
begin
    cAltDamage:= altDamage;
    cTimerInterval:= timeIterval;
    if (reducedQuality) then        //HACK
        cReducedQuality:= $FFFFFFFF xor rqLowRes
end;

procedure setAllOptionsWithParameters(screenWidthParam:string; screenHeightParam:string; bitsParam:string;
                                      initialVolumeParam:string; musicEnabledParam:string; soundEnabledParam:string;
                                      languageFileParam:string; fullScreenParam:string; showFPSParam:string;
                                      altDamageParam:string; timeItervalParam:string; reducedQualityParam: string);
var showFPS, altDamage, reducedQuality: boolean;
    timeIterval, c: LongInt;
begin
    setMultimediaOptionsWithParameters(screenWidthParam,screenHeightParam, bitsParam,
                                       initialVolumeParam,musicEnabledParam,soundEnabledParam,
                                       languageFileParam,fullScreenParam);
    showFPS := showFPSParam = '1';
    setShowFPS(showFPS);

    altDamage:= altDamageParam = '1';
    val(timeItervalParam, timeIterval, c);
    reducedQuality:= reducedQualityParam = '1';
    setAltDamageTimerValueAndQuality(altDamage,timeIterval,reducedQuality);
end;

procedure playReplayFileWithParameters();
var paramIndex: LongInt;
    wrongParameter: boolean;
begin
    UserPathPrefix:= ParamStr(1);
    PathPrefix:= ParamStr(2);
    recordFileName:= ParamStr(3);
    paramIndex:= 4;
    wrongParameter:= false;
    while (paramIndex <= ParamCount) and (not wrongParameter) do
        begin
        if ParamStr(paramIndex) = '--set-video'  then
//--set-video [screen width] [screen height] [color dept]
            begin
            if(ParamCount-paramIndex < 3) then
                begin
                wrongParameter:= true;
                GameType:= gmtSyntax
                end;
            setVideoWithParameters(ParamStr(paramIndex+1), ParamStr(paramIndex+2), ParamStr(paramIndex+3));
            paramIndex:= paramIndex + 4
            end
        else
//--set-audio [volume] [enable music] [enable sounds]
            if ParamStr(paramIndex) = '--set-audio'  then
                begin
                if(ParamCount-paramIndex < 3) then
                    begin
                    wrongParameter := true;
                    GameType:= gmtSyntax
                    end;
                setAudioWithParameters(ParamStr(paramIndex+1),ParamStr(paramIndex+2), ParamStr(paramIndex+3));
                paramIndex:= paramIndex + 4
                end
            else
// --set-other [language file] [full screen] [show FPS]
                if ParamStr(paramIndex) = '--set-other'  then
                    begin
                    if(ParamCount-paramIndex < 3) then
                        begin
                        wrongParameter:= true;
                        GameType:= gmtSyntax
                        end;
                    setOtherOptionsWithParameters(ParamStr(paramIndex+1),ParamStr(paramIndex+2), ParamStr(paramIndex+3));
                    paramIndex:= paramIndex + 4
                    end
                else
//--set-multimedia [screen width] [screen height] [color dept] [volume] [enable music] [enable sounds] [language file] [full screen]
                    if ParamStr(paramIndex) = '--set-multimedia'  then
                        begin
                        if ParamCount-paramIndex < 8  then
                            begin
                            wrongParameter:= true;
                            GameType:= gmtSyntax
                            end;
                        setMultimediaOptionsWithParameters(ParamStr(paramIndex+1),ParamStr(paramIndex+2),ParamStr(paramIndex+3),
                                                           ParamStr(paramIndex+4),ParamStr(paramIndex+5),ParamStr(paramIndex+6),
                                                           ParamStr(paramIndex+7),ParamStr(paramIndex+8));
                        paramIndex:= paramIndex + 9
                        end
                    else
//--set-everything [screen width] [screen height] [color dept] [volume] [enable music] [enable sounds] [language file] [full screen] [show FPS] [alternate damage] [timer value] [reduced quality]
                        if ParamStr(paramIndex) = '--set-everything'  then
                            begin
                            if ParamCount-paramIndex < 12  then
                                begin
                                wrongParameter:= true;
                                GameType:= gmtSyntax
                                end;
                            setAllOptionsWithParameters(ParamStr(paramIndex+1),ParamStr(paramIndex+2),ParamStr(paramIndex+3),
                                                        ParamStr(paramIndex+4),ParamStr(paramIndex+5),ParamStr(paramIndex+6),
                                                        ParamStr(paramIndex+7),ParamStr(paramIndex+8),ParamStr(paramIndex+9),
                                                        ParamStr(paramIndex+10),ParamStr(paramIndex+11),ParamStr(paramIndex+12));
                            paramIndex:= paramIndex + 13
                            end
                        else
                            if ParamStr(paramIndex) = '--stats-only'  then
                                begin
                                cOnlyStats:= true;
                                SetSound(false);
                                SetMusic(false);
                                cReducedQuality:= $FFFFFFFF xor rqLowRes; // HACK
                                paramIndex:= paramIndex + 1
                                end
                            else
                                begin
                                wrongParameter:= true;
                                GameType:= gmtSyntax
                                end
    end
end;

