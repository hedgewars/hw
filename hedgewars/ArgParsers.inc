
procedure internalSetGameTypeLandPreviewFromParameters();
begin
    val(ParamStr(2), ipcPort);
    GameType:= gmtLandPreview;
    if ParamStr(3) <> 'landpreview' then
        GameType:= gmtSyntax;
end;

procedure internalStartGameWithParameters();
begin
    val(ParamStr(2), cScreenWidth);
    val(ParamStr(3), cScreenHeight);
    cBitsStr:= ParamStr(4);
    val(cBitsStr, cBits);
    val(ParamStr(5), ipcPort);
    cFullScreen:= ParamStr(6) = '1';
    isSoundEnabled:= ParamStr(7) = '1';
    //cVSyncInUse:= ParamStr(8) = '1';      //merged with rqFlags
    //cWeaponTooltips:= ParamStr(9) = '1';  //merged with rqFlags
    cLocaleFName:= ParamStr(10);
    val(ParamStr(11), cInitVolume);
    val(ParamStr(12), cTimerInterval);
    PathPrefix:= ParamStr(13);
    cShowFPS:= ParamStr(14) = '1';
    cAltDamage:= ParamStr(15) = '1';
    UserNick:= DecodeBase64(ParamStr(16));
    isMusicEnabled:= ParamStr(17) = '1';

    if (ParamStr(18) = '1') then        //HACK - always disable rqLowRes as it is a game breaker
        cReducedQuality:= $FFFFFFFF xor rqLowRes
    else
        val(ParamStr(18), cReducedQuality);
    
    if (ParamStr(8) = '0') then         //HACK - ifcVSyncInUse not true, disable it
        cReducedQuality:= cReducedQuality xor rqDesyncVBlank;
    if (ParamStr(9) = '0') then         //HACK - if cWeaponTooltips not true, disable it
        cReducedQuality:= cReducedQuality xor rqTooltipsOff;
end;

procedure setVideo(screenWidth: LongInt; screenHeight: LongInt; bitsStr: LongInt);
begin
    cScreenWidth:= screenWidth;
    cScreenHeight:= screenHeight;
    cBits:= bitsStr;
end;

procedure setVideoWithParameters(screenWidthParam: string; screenHeightParam: string; bitsParam: string);
var screenWidthAsInt, screenHeightAsInt, bitsStrAsInt: LongInt;
begin
    val(screenWidthParam, screenWidthAsInt);
    val(screenHeightParam, screenHeightAsInt);
    cBitsStr:= bitsParam;
    val(cBitsStr, bitsStrAsInt);
    setVideo(screenWidthAsInt,screenHeightAsInt,bitsStrAsInt);
end;

procedure setOtherOptions(languageFile: string; fullScreen: boolean);
begin
    cLocaleFName:= languageFile;
    cFullScreen:= fullScreen;
end;

procedure setShowFPS(showFPS: boolean);
begin
    cShowFPS:= showFPS;
end;

procedure setOtherOptionsWithParameters(languageFileParam: string; fullScreenParam: string; showFPSParam: string);
var fullScreen, showFPS: boolean;
begin
    fullScreen:= fullScreenParam = '1';
    showFPS:= showFPSParam = '1';
    setOtherOptions(languageFileParam,fullScreen);
    setShowFPS(showFPS);
end;

procedure setAudio(initialVolume: LongInt; musicEnabled: boolean; soundEnabled: boolean);
begin
    cInitVolume:= initialVolume;
    isMusicEnabled:= musicEnabled;
    isSoundEnabled:= soundEnabled; 
end;

procedure setAudioWithParameters(initialVolumeParam: string; musicEnabledParam: string; soundEnabledParam: string);
var initialVolumeAsInt: LongInt;
    musicEnabled, soundEnabled: boolean;
begin
    val(initialVolumeParam, initialVolumeAsInt);
    musicEnabled:= musicEnabledParam = '1';
    soundEnabled:= soundEnabledParam = '1';
    setAudio(initialVolumeAsInt,musicEnabled, soundEnabled);
end;

procedure setMultimediaOptionsWithParameters(screenWidthParam, screenHeightParam, bitsParam: string;
                                             initialVolumeParam, musicEnabledParam, soundEnabledParam: string;
                                             languageFileParam, fullScreenParam: string);
begin
    setVideoWithParameters(screenWidthParam,screenHeightParam, bitsParam);
    setAudioWithParameters(initialVolumeParam,musicEnabledParam,soundEnabledParam);
    setOtherOptions(languageFileParam,fullScreenParam = '1');
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
    timeIterval: LongInt;
begin
    setMultimediaOptionsWithParameters(screenWidthParam,screenHeightParam, bitsParam,
                                       initialVolumeParam,musicEnabledParam,soundEnabledParam,
                                       languageFileParam,fullScreenParam);                       
    showFPS := showFPSParam = '1';
    setShowFPS(showFPS);
    
    altDamage:= altDamageParam = '1';
    val(timeItervalParam, timeIterval);
    reducedQuality:= reducedQualityParam = '1';
    setAltDamageTimerValueAndQuality(altDamage,timeIterval,reducedQuality);    
end;

procedure playReplayFileWithParameters();
var paramIndex: LongInt;
    wrongParameter: boolean;
begin
    PathPrefix:= ParamStr(1);
    recordFileName:= ParamStr(2);
    paramIndex:= 3;
    wrongParameter:= false;
    while (paramIndex <= ParamCount) and not wrongParameter do
    begin
        //--set-video [screen width] [screen height] [color dept]
        if(ParamStr(paramIndex) = '--set-video') then
        begin
	    if(ParamCount-paramIndex < 3) then
	    begin
	        wrongParameter:= true;
	        GameType:= gmtSyntax;
	    end;
	    setVideoWithParameters(ParamStr(paramIndex+1), ParamStr(paramIndex+2), ParamStr(paramIndex+3));
	    paramIndex:= paramIndex + 4;
        end 
        else 
        //--set-audio [volume] [enable music] [enable sounds]
        if(ParamStr(paramIndex) = '--set-audio') then
        begin
    	    if(ParamCount-paramIndex < 3) then
	    begin
	        wrongParameter := true;
	        GameType:= gmtSyntax;
	    end;
	    setAudioWithParameters(ParamStr(paramIndex+1),ParamStr(paramIndex+2), ParamStr(paramIndex+3));
	    paramIndex:= paramIndex + 4;
        end 
        else 
        // --set-other [language file] [full screen] [show FPS]
        if(ParamStr(paramIndex) = '--set-other') then
        begin
            if(ParamCount-paramIndex < 3) then
            begin
                wrongParameter:= true;
                GameType:= gmtSyntax;
	    end;
	    setOtherOptionsWithParameters(ParamStr(paramIndex+1),ParamStr(paramIndex+2), ParamStr(paramIndex+3));
	    paramIndex:= paramIndex + 4;
	end 
	else 
	//--set-multimedia [screen width] [screen height] [color dept] [volume] [enable music] [enable sounds] [language file] [full screen]
	if(ParamStr(paramIndex) = '--set-multimedia') then
	begin
	    if(ParamCount-paramIndex < 8) then
	    begin
	        wrongParameter:= true;
	        GameType:= gmtSyntax;
	    end;
	    setMultimediaOptionsWithParameters(ParamStr(paramIndex+1),ParamStr(paramIndex+2),ParamStr(paramIndex+3),
		   			       ParamStr(paramIndex+4),ParamStr(paramIndex+5),ParamStr(paramIndex+6),
					       ParamStr(paramIndex+7),ParamStr(paramIndex+8));
	    paramIndex:= paramIndex + 9;
        end 
        else
        //--set-everything [screen width] [screen height] [color dept] [volume] [enable music] [enable sounds] [language file] [full screen] [show FPS] [alternate damage] [timer value] [reduced quality]
        if(ParamStr(paramIndex) = '--set-everything') then
        begin
	    if(ParamCount-paramIndex < 12) then
	    begin
	        wrongParameter:= true;
	        GameType:= gmtSyntax;
	    end;
	    setAllOptionsWithParameters(ParamStr(paramIndex+1),ParamStr(paramIndex+2),ParamStr(paramIndex+3),
				        ParamStr(paramIndex+4),ParamStr(paramIndex+5),ParamStr(paramIndex+6),
				        ParamStr(paramIndex+7),ParamStr(paramIndex+8),ParamStr(paramIndex+9),
				        ParamStr(paramIndex+10),ParamStr(paramIndex+11),ParamStr(paramIndex+12));
	    paramIndex:= paramIndex + 13;
        end 
        else
        begin
	    wrongParameter:= true;
	    GameType:= gmtSyntax;
        end;
    end;
end;

