unit uFLGameConfig;
interface
uses uFLTypes;

procedure resetGameConfig; cdecl;
procedure runQuickGame; cdecl;
procedure runLocalGame; cdecl;
procedure getPreview; cdecl;

procedure setSeed(seed: PChar); cdecl;
function  getSeed: PChar; cdecl;
procedure setTheme(themeName: PChar); cdecl;
procedure setScript(scriptName: PChar); cdecl;
procedure setScheme(schemeName: PChar); cdecl;
procedure setAmmo(ammoName: PChar); cdecl;

procedure tryAddTeam(teamName: PChar); cdecl;
procedure tryRemoveTeam(teamName: PChar); cdecl;
procedure changeTeamColor(teamName: PChar; dir: LongInt); cdecl;

procedure netSetSeed(seed: shortstring);
procedure netSetTheme(themeName: shortstring);
procedure netSetScript(scriptName: shortstring);
procedure netSetFeatureSize(fsize: LongInt);
procedure netSetMapGen(mapgen: LongInt);
procedure netSetMap(map: shortstring);
procedure netSetMazeSize(mazesize: LongInt);
procedure netSetTemplate(template: LongInt);
procedure netSetAmmo(name: shortstring; definition: ansistring);
procedure netSetScheme(scheme: TScheme);
procedure netAddTeam(team: TTeam);
procedure netAcceptedTeam(teamName: shortstring);
procedure netSetTeamColor(team: shortstring; color: Longword);
procedure netSetHedgehogsNumber(team: shortstring; hogsNumber: Longword);
procedure netRemoveTeam(teamName: shortstring);
procedure netResetTeams();
procedure updatePreviewIfNeeded;

procedure sendConfig(config: PGameConfig);

implementation
uses uFLIPC, uFLUtils, uFLTeams, uFLThemes, uFLSChemes, uFLAmmo, uFLUICallback, uFLRunQueue, uFLNet;

var
    currentConfig: TGameConfig;
    previewNeedsUpdate: boolean;

function getScriptPath(scriptName: shortstring): shortstring;
begin
    getScriptPath:= '/Scripts/Multiplayer/' + scriptName + '.lua'
end;

procedure sendConfig(config: PGameConfig);
var i: Longword;
begin
with config^ do
begin
    case gameType of
    gtPreview: begin
            if script <> 'Normal' then
                ipcToEngine('escript ' + getScriptPath(script));
            ipcToEngine('eseed ' + seed);
            ipcToEngine('e$mapgen ' + intToStr(mapgen));
            ipcToEngine('e$template_filter ' + intToStr(template));
            ipcToEngine('e$feature_size ' + intToStr(featureSize));
            ipcToEngine('e$maze_size ' + intToStr(mazeSize));
        end;
    gtLocal: begin
            if script <> 'Normal' then
                ipcToEngine('escript ' + getScriptPath(script));
            ipcToEngine('eseed ' + seed);
            ipcToEngine('e$mapgen ' + intToStr(mapgen));
            ipcToEngine('e$template_filter ' + intToStr(template));
            ipcToEngine('e$feature_size ' + intToStr(featureSize));
            ipcToEngine('e$theme ' + theme);
            ipcToEngine('e$maze_size ' + intToStr(mazeSize));

            sendSchemeConfig(scheme);

            i:= 0;
            while (i < 8) and (teams[i].hogsNumber > 0) do
                begin
                    sendTeamConfig(teams[i]);
                    sendAmmoConfig(config^.ammo);
                    inc(i)
                end;
        end;
    end;

    ipcToEngine('!');
end;
end;

procedure resetGameConfig; cdecl;
var i: Longword;
begin
    with currentConfig do
    begin
        script:= 'Normal';

        for i:= 0 to 7 do
            teams[i].hogsNumber:= 0
    end
end;

procedure setSeed(seed: PChar); cdecl;
begin
    sendUI(mtSeed, @seed[1], length(seed));
    currentConfig.seed:= seed
end;

function getSeed: PChar; cdecl;
begin
    getSeed:= str2PChar(currentConfig.seed)
end;

function getUnusedColor: Longword;
var i, c: Longword;
    fColorMatched: boolean;
begin
    c:= 0;
    i:= 0;
    repeat
        repeat
            fColorMatched:= (currentConfig.teams[i].hogsNumber > 0) and (currentConfig.teams[i].color = c);
            inc(i)
        until (i >= 8) or (currentConfig.teams[i].hogsNumber = 0) or fColorMatched;

        if fColorMatched then
        begin
            i:= 0;
            inc(c)
        end;
    until not fColorMatched;

    getUnusedColor:= c
end;

procedure runQuickGame; cdecl;
begin
    with currentConfig do
    begin
        gameType:= gtLocal;
        arguments[0]:= '';
        arguments[1]:= '--internal';
        arguments[2]:= '--nomusic';
        argumentsNumber:= 3;

        teams[0]:= createRandomTeam;
        teams[0].color:= 0;
        teams[1]:= createRandomTeam;
        teams[1].color:= 1;
        teams[1].botLevel:= 3;

        queueExecution(currentConfig);
    end;
end;


procedure getPreview; cdecl;
begin
    previewNeedsUpdate:= false;

    with currentConfig do
    begin
        gameType:= gtPreview;
        arguments[0]:= '';
        arguments[1]:= '--internal';
        arguments[2]:= '--landpreview';
        argumentsNumber:= 3;

        queueExecution(currentConfig);
    end;
end;

procedure runLocalGame; cdecl;
begin
    with currentConfig do
    begin
        gameType:= gtLocal;
        arguments[0]:= '';
        arguments[1]:= '--internal';
        arguments[2]:= '--nomusic';
        argumentsNumber:= 3;

        queueExecution(currentConfig);
    end;
end;

procedure tryAddTeam(teamName: PChar); cdecl;
var msg: ansistring;
    i, hn, hedgehogsNumber: Longword;
    team: PTeam;
    c: Longword;
begin
    team:= teamByName(teamName);
    if team = nil then exit;

    if isConnected then
        sendTeam(team^)
    else
    with currentConfig do
    begin
        hedgehogsNumber:= 0;
        i:= 0;

        while (i < 8) and (teams[i].hogsNumber > 0) do
        begin
            inc(i);
            inc(hedgehogsNumber, teams[i].hogsNumber)
        end;

        // no free space for a team or reached hogs number maximum
        if (i > 7) or (hedgehogsNumber >= 48) then exit;

        c:= getUnusedColor;

        teams[i]:= team^;

        if i = 0 then hn:= 4 else hn:= teams[i - 1].hogsNumber;
        if hn > 48 - hedgehogsNumber then hn:= 48 - hedgehogsNumber;
        teams[i].hogsNumber:= hn;

        teams[i].color:= c;

        msg:= '0' + #10 + teamName;
        sendUI(mtAddPlayingTeam, @msg[1], length(msg));

        msg:= teamName + #10 + colorsSet[teams[i].color];
        sendUI(mtTeamColor, @msg[1], length(msg));

        msg:= teamName + #10 + IntToStr(hn);
        sendUI(mtHedgehogsNumber, @msg[1], length(msg));

        msg:= teamName;
        sendUI(mtRemoveTeam, @msg[1], length(msg))
    end
end;


procedure tryRemoveTeam(teamName: PChar); cdecl;
var msg: shortstring;
    i: Longword;
    tn: shortstring;
begin
    with currentConfig do
    begin
        i:= 0;
        tn:= teamName;
        while (i < 8) and (teams[i].teamName <> tn) do
            inc(i);

        // team not found???
        if (i > 7) then exit;

        while (i < 7) and (teams[i + 1].hogsNumber > 0) do
        begin
            teams[i]:= teams[i + 1];
            inc(i)
        end;

        teams[i].hogsNumber:= 0
    end;

    msg:= teamName;

    sendUI(mtRemovePlayingTeam, @msg[1], length(msg));
    sendUI(mtAddTeam, @msg[1], length(msg))
end;


procedure changeTeamColor(teamName: PChar; dir: LongInt); cdecl;
var i, dc: Longword;
    tn: shortstring;
    msg: ansistring;
begin
    with currentConfig do
    begin
        i:= 0;
        tn:= teamName;
        while (i < 8) and (teams[i].teamName <> tn) do
            inc(i);
        // team not found???
        if (i > 7) then exit;

        if dir >= 0 then dc:= 1 else dc:= 8;
        teams[i].color:= (teams[i].color + dc) mod 9;

        msg:= tn + #10 + colorsSet[teams[i].color];
        sendUI(mtTeamColor, @msg[1], length(msg))
    end
end;

procedure setTheme(themeName: PChar); cdecl;
begin
    currentConfig.theme:= themeName
end;

procedure setScript(scriptName: PChar); cdecl;
begin
    currentConfig.script:= scriptName
end;

procedure setScheme(schemeName: PChar); cdecl;
var scheme: PScheme;
begin
    scheme:= schemeByName(schemeName);

    if scheme <> nil then
        currentConfig.scheme:= scheme^
end;

procedure setAmmo(ammoName: PChar); cdecl;
var ammo: PAmmo;
begin
    ammo:= ammoByName(ammoName);

    if ammo <> nil then
        currentConfig.ammo:= ammo^
end;

procedure netSetSeed(seed: shortstring);
begin
    if seed <> currentConfig.seed then
    begin
        currentConfig.seed:= seed;
        sendUI(mtSeed, @seed[1], length(seed));

        getPreview()
    end
end;

procedure netSetTheme(themeName: shortstring);
begin
    if themeName <> currentConfig.theme then
    begin
        currentConfig.theme:= themeName;
        sendUI(mtTheme, @themeName[1], length(themeName))
    end
end;

procedure netSetScript(scriptName: shortstring);
begin
    if scriptName <> currentConfig.script then
    begin
        previewNeedsUpdate:= true;
        currentConfig.script:= scriptName;
        sendUI(mtScript, @scriptName[1], length(scriptName))
    end
end;

procedure netSetFeatureSize(fsize: LongInt);
var s: shortstring;
begin
    if fsize <> currentConfig.featureSize then
    begin
        previewNeedsUpdate:= true;
        currentConfig.featureSize:= fsize;
        s:= IntToStr(fsize);
        sendUI(mtFeatureSize, @s[1], length(s))
    end
end;

procedure netSetMapGen(mapgen: LongInt);
var s: shortstring;
begin
    if mapgen <> currentConfig.mapgen then
    begin
        previewNeedsUpdate:= true;
        currentConfig.mapgen:= mapgen;
        s:= IntToStr(mapgen);
        sendUI(mtMapGen, @s[1], length(s))
    end
end;

procedure netSetMap(map: shortstring);
begin
    sendUI(mtMap, @map[1], length(map))
end;

procedure netSetMazeSize(mazesize: LongInt);
var s: shortstring;
begin
    if mazesize <> currentConfig.mazesize then
    begin
        previewNeedsUpdate:= true;
        currentConfig.mazesize:= mazesize;
        s:= IntToStr(mazesize);
        sendUI(mtMazeSize, @s[1], length(s))
    end
end;

procedure netSetTemplate(template: LongInt);
var s: shortstring;
begin
    if template <> currentConfig.template then
    begin
        previewNeedsUpdate:= true;
        currentConfig.template:= template;
        s:= IntToStr(template);
        sendUI(mtTemplate, @s[1], length(s))
    end
end;

procedure updatePreviewIfNeeded;
begin
    if previewNeedsUpdate then
        getPreview
end;

procedure netSetAmmo(name: shortstring; definition: ansistring);
var ammo: TAmmo;
    i: LongInt;
begin
    ammo.ammoName:= name;
    i:= length(definition) div 4;
    ammo.a:= copy(definition, 1, i);
    ammo.b:= copy(definition, i + 1, i);
    ammo.c:= copy(definition, i * 2 + 1, i);
    ammo.d:= copy(definition, i * 3 + 1, i);

    currentConfig.ammo:= ammo;
    sendUI(mtAmmo, @name[1], length(name))
end;

procedure netSetScheme(scheme: TScheme);
begin
    currentConfig.scheme:= scheme;
    sendUI(mtScheme, @scheme.schemeName[1], length(scheme.schemeName))
end;

procedure netAddTeam(team: TTeam);
var msg: ansistring;
    i, hn, hedgehogsNumber: Longword;
    c: Longword;
begin
    with currentConfig do
    begin
        hedgehogsNumber:= 0;
        i:= 0;

        while (i < 8) and (teams[i].hogsNumber > 0) do
        begin
            inc(i);
            inc(hedgehogsNumber, teams[i].hogsNumber)
        end;

        // no free space for a team - server bug???
        if (i > 7) or (hedgehogsNumber >= 48) then exit;

        c:= getUnusedColor;

        teams[i]:= team;
        teams[i].extDriven:= true;

        if i = 0 then hn:= 4 else hn:= teams[i - 1].hogsNumber;
        if hn > 48 - hedgehogsNumber then hn:= 48 - hedgehogsNumber;
        teams[i].hogsNumber:= hn;

        teams[i].color:= c;

        msg:= '0' + #10 + team.teamName;
        sendUI(mtAddPlayingTeam, @msg[1], length(msg));

        msg:= team.teamName + #10 + colorsSet[teams[i].color];
        sendUI(mtTeamColor, @msg[1], length(msg));
    end
end;

procedure netAcceptedTeam(teamName: shortstring);
var msg: ansistring;
    i, hn, hedgehogsNumber: Longword;
    c: Longword;
    team: PTeam;
begin
    with currentConfig do
    begin
        team:= teamByName(teamName);
        // no such team???
        if team = nil then exit;

        hedgehogsNumber:= 0;
        i:= 0;

        while (i < 8) and (teams[i].hogsNumber > 0) do
        begin
            inc(i);
            inc(hedgehogsNumber, teams[i].hogsNumber)
        end;

        // no free space for a team - server bug???
        if (i > 7) or (hedgehogsNumber >= 48) then exit;

        c:= getUnusedColor;

        teams[i]:= team^;
        teams[i].extDriven:= false;

        if i = 0 then hn:= 4 else hn:= teams[i - 1].hogsNumber;
        if hn > 48 - hedgehogsNumber then hn:= 48 - hedgehogsNumber;
        teams[i].hogsNumber:= hn;

        teams[i].color:= c;

        msg:= '0' + #10 + teamName;
        sendUI(mtAddPlayingTeam, @msg[1], length(msg));

        msg:= teamName + #10 + colorsSet[teams[i].color];
        sendUI(mtTeamColor, @msg[1], length(msg));

        msg:= teamName;
        sendUI(mtRemoveTeam, @msg[1], length(msg))        
    end
end;

procedure netRemoveTeam(teamName: shortstring);
var msg: shortstring;
    i: Longword;
    tn: shortstring;
    isLocal: boolean;
begin
    with currentConfig do
    begin
        i:= 0;
        tn:= teamName;
        while (i < 8) and (teams[i].teamName <> tn) do
            inc(i);

        // team not found???
        if (i > 7) then exit;

        isLocal:= not teams[i].extDriven;

        while (i < 7) and (teams[i + 1].hogsNumber > 0) do
        begin
            teams[i]:= teams[i + 1];
            inc(i)
        end;

        teams[i].hogsNumber:= 0
    end;

    msg:= teamName;

    sendUI(mtRemovePlayingTeam, @msg[1], length(msg));
    if isLocal then
        sendUI(mtAddTeam, @msg[1], length(msg))
end;

procedure netSetTeamColor(team: shortstring; color: Longword);
var i: Longword;
    msg: ansistring;
begin
    with currentConfig do
    begin
        i:= 0;

        while (i < 8) and (teams[i].teamName <> team) do
            inc(i);
        // team not found???
        if (i > 7) then exit;

        teams[i].color:= color mod 9;

        msg:= team + #10 + colorsSet[teams[i].color];
        sendUI(mtTeamColor, @msg[1], length(msg))
    end
end;

procedure netSetHedgehogsNumber(team: shortstring; hogsNumber: Longword);
var i: Longword;
    msg: ansistring;
begin
    if hogsNumber > 8 then exit;

    with currentConfig do
    begin
        i:= 0;

        while (i < 8) and (teams[i].teamName <> team) do
            inc(i);
        // team not found???
        if (i > 7) then exit;

        teams[i].hogsNumber:= hogsNumber;

        msg:= team + #10 + IntToStr(hogsNumber);
        sendUI(mtHedgehogsNumber, @msg[1], length(msg))
    end
end;

procedure netResetTeams();
var msg: shortstring;
    i: Longword;
begin
    with currentConfig do
    begin
        i:= 0;

        while (i < 8) and (teams[i].hogsNumber > 0) do
        begin
            msg:= teams[i].teamName;

            sendUI(mtRemovePlayingTeam, @msg[1], length(msg));
            if not teams[i].extDriven then 
                sendUI(mtAddTeam, @msg[1], length(msg));

            teams[i].hogsNumber:= 0;
            inc(i)
        end;

    end;
end;

end.
