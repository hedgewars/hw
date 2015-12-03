unit uFLNetProtocol;
interface

procedure passNetData(p: pointer); cdecl;

procedure sendChatLine(msg: PChar); cdecl;
procedure joinRoom(roomName: PChar); cdecl;
procedure partRoom(msg: PChar); cdecl;

procedure ResetNetState;

implementation
uses uFLNetTypes, uFLTypes, uFLUICallback, uFLNet, uFLGameConfig, uFLUtils;

type
    PHandler = procedure (var t: TCmdData);

var isInRoom: boolean;
    myNickname: shortstring;

var teamIndex: LongInt;
    tmpTeam: TTeam;

const teamFields: array[0..22] of PShortstring = (
    @tmpTeam.teamName
    , @tmpTeam.grave
    , @tmpTeam.fort
    , @tmpTeam.voice
    , @tmpTeam.flag
    , @tmpTeam.owner
    , nil
    , @tmpTeam.hedgehogs[0].name
    , @tmpTeam.hedgehogs[0].hat
    , @tmpTeam.hedgehogs[1].name
    , @tmpTeam.hedgehogs[1].hat
    , @tmpTeam.hedgehogs[2].name
    , @tmpTeam.hedgehogs[2].hat
    , @tmpTeam.hedgehogs[3].name
    , @tmpTeam.hedgehogs[3].hat
    , @tmpTeam.hedgehogs[4].name
    , @tmpTeam.hedgehogs[4].hat
    , @tmpTeam.hedgehogs[5].name
    , @tmpTeam.hedgehogs[5].hat
    , @tmpTeam.hedgehogs[6].name
    , @tmpTeam.hedgehogs[6].hat
    , @tmpTeam.hedgehogs[7].name
    , @tmpTeam.hedgehogs[7].hat
    );
procedure handler_ADD_TEAM(var p: TCmdParam);
begin
    teamIndex:= 0;
    tmpTeam.extDriven:= true;
    tmpTeam.color:= 0
end;

procedure handler_ADD_TEAM_s(var s: TCmdParamS);
begin
    if teamIndex = 6 then
        tmpTeam.botLevel:= strToInt(s.str1)
    else if teamIndex < 23 then
        teamFields[teamIndex]^:= s.str1;

    if teamIndex = 22 then
        netAddTeam(tmpTeam);

    inc(teamIndex);
end;

procedure handler_ASKPASSWORD(var p: TCmdParamS);
begin
end;

procedure handler_BANLIST(var p: TCmdParam);
begin
end;

procedure handler_BANLIST_s(var s: TCmdParamS);
begin
end;

procedure handler_BYE(var p: TCmdParamSL);
begin
    sendUI(mtDisconnected, @p.str2[1], length(p.str2));
end;

procedure handler_CFG_AMMO(var p: TCmdParamSL);
begin
    netSetAmmo(p.str1, p.str2)
end;

procedure handler_CFG_DRAWNMAP(var p: TCmdParamL);
begin
end;

procedure handler_CFG_FEATURE_SIZE(var p: TCmdParami);
begin
    if isInRoom then
    begin
        netSetFeatureSize(p.param1);
        updatePreviewIfNeeded
    end;
end;

var fmcfgIndex: integer;

procedure handler_CFG_FULLMAPCONFIG(var p: TCmdParam);
begin
    fmcfgIndex:= 0;
end;

procedure handler_CFG_FULLMAPCONFIG_s(var s: TCmdParamS);
begin
    if not isInRoom then exit;

    inc(fmcfgIndex);
    case fmcfgIndex of
        1: netSetFeatureSize(strToInt(s.str1));
        2: if s.str1[0] <> '+' then netSetMap(s.str1);
        3: netSetMapGen(strToInt(s.str1));
        4: netSetMazeSize(strToInt(s.str1));
        5: netSetSeed(s.str1);
        6: begin
                netSetTemplate(strToInt(s.str1));
                updatePreviewIfNeeded;
            end;
    end;
end;

procedure handler_CFG_MAP(var p: TCmdParamS);
begin
    if isInRoom then
        netSetMap(p.str1);
end;

procedure handler_CFG_MAPGEN(var p: TCmdParami);
begin
    if isInRoom then
    begin
        netSetMapGen(p.param1);
        updatePreviewIfNeeded
    end
end;

procedure handler_CFG_MAZE_SIZE(var p: TCmdParami);
begin
    if isInRoom then
    begin
        netSetMazeSize(p.param1);
        updatePreviewIfNeeded
    end
end;

var schemeIndex: LongInt;
    tmpScheme: TScheme;

procedure handler_CFG_SCHEME(var p: TCmdParam);
begin
    schemeIndex:= 0
end;

const schemeFields: array[0..43] of pointer = (
      @tmpScheme.schemeName          //  0
    , @tmpScheme.fortsmode           //  1
    , @tmpScheme.divteams            //  2
    , @tmpScheme.solidland           //  3
    , @tmpScheme.border              //  4
    , @tmpScheme.lowgrav             //  5
    , @tmpScheme.laser               //  6
    , @tmpScheme.invulnerability     //  7
    , @tmpScheme.resethealth         //  8
    , @tmpScheme.vampiric            //  9
    , @tmpScheme.karma               // 10
    , @tmpScheme.artillery           // 11
    , @tmpScheme.randomorder         // 12
    , @tmpScheme.king                // 13
    , @tmpScheme.placehog            // 14
    , @tmpScheme.sharedammo          // 15
    , @tmpScheme.disablegirders      // 16
    , @tmpScheme.disablelandobjects  // 17
    , @tmpScheme.aisurvival          // 18
    , @tmpScheme.infattack           // 19
    , @tmpScheme.resetweps           // 20
    , @tmpScheme.perhogammo          // 21
    , @tmpScheme.disablewind         // 22
    , @tmpScheme.morewind            // 23
    , @tmpScheme.tagteam             // 24
    , @tmpScheme.bottomborder        // 25
    , @tmpScheme.damagefactor        // 26
    , @tmpScheme.turntime            // 27
    , @tmpScheme.health              // 28
    , @tmpScheme.suddendeath         // 29
    , @tmpScheme.caseprobability     // 30
    , @tmpScheme.minestime           // 31
    , @tmpScheme.minesnum            // 32
    , @tmpScheme.minedudpct          // 33
    , @tmpScheme.explosives          // 34
    , @tmpScheme.airmines            // 35
    , @tmpScheme.healthprobability   // 36
    , @tmpScheme.healthcaseamount    // 37
    , @tmpScheme.waterrise           // 38
    , @tmpScheme.healthdecrease      // 39
    , @tmpScheme.ropepct             // 40
    , @tmpScheme.getawaytime         // 41
    , @tmpScheme.worldedge           // 42
    , @tmpScheme.scriptparam         // 43
   );

procedure handler_CFG_SCHEME_s(var s: TCmdParamS);
begin
    if(schemeIndex = 0) then
        tmpScheme.schemeName:= s.str1
    else
    if(schemeIndex = 43) then
        tmpScheme.scriptparam:= copy(s.str1, 2, length(s.str1) - 1)
    else
    if(schemeIndex < 26) then
        PBoolean(schemeFields[schemeIndex])^:= s.str1[1] = 't'
    else
    if(schemeIndex < 43) then
        PLongInt(schemeFields[schemeIndex])^:= strToInt(s.str1);

    if(schemeIndex = 43) then
        netSetScheme(tmpScheme);

    inc(schemeIndex);
end;

procedure handler_CFG_SCRIPT(var p: TCmdParamS);
begin
    if isInRoom then
        netSetScript(p.str1)
end;

procedure handler_CFG_SEED(var p: TCmdParamS);
begin
    if isInRoom then
        netSetSeed(p.str1)
end;

procedure handler_CFG_TEMPLATE(var p: TCmdParami);
begin
    if isInRoom then
    begin
        netSetTemplate(p.param1);
        updatePreviewIfNeeded
    end
end;

procedure handler_CFG_THEME(var p: TCmdParamS);
begin
    if isInRoom then
        netSetTheme(p.str1)
end;

procedure handler_CHAT(var p: TCmdParamSL);
var s: string;
begin
    s:= p.str1 + #10 + p.str2;
    if isInRoom then
        sendUI(mtRoomChatLine, @s[1], length(s))
    else
        sendUI(mtLobbyChatLine, @s[1], length(s));
end;

procedure handler_CLIENT_FLAGS(var p: TCmdParamS);
begin
end;

procedure handler_CLIENT_FLAGS_s(var s: TCmdParamS);
begin
end;

procedure handler_CONNECTED(var p: TCmdParami);
begin
    sendUI(mtConnected, nil, 0);
    writeln('Server features version ', p.param1);
    sendNet('PROTO' + #10 + '51');
    sendNet('NICK' + #10 + 'qmlfrontend');
end;

procedure handler_EM(var p: TCmdParam);
begin
end;

procedure handler_EM_s(var s: TCmdParamS);
begin
end;

procedure handler_ERROR(var p: TCmdParamL);
begin
    sendUI(mtError, @p.str1[1], length(p.str1));
end;

procedure handler_HH_NUM(var p: TCmdParamSS);
begin
end;

procedure handler_INFO(var p: TCmdParam);
begin
end;

procedure handler_INFO_s(var s: TCmdParamS);
begin
end;

procedure handler_JOINED(var p: TCmdParam);
begin
end;

procedure handler_JOINED_s(var s: TCmdParamS);
begin
    if s.str1 = myNickname then // we joined a room
    begin
        isInRoom:= true;
        sendUI(mtMoveToRoom, nil, 0);
    end;

    sendUI(mtAddRoomClient, @s.str1[1], length(s.str1));
end;

procedure handler_JOINING(var p: TCmdParamS);
begin
end;

procedure handler_KICKED(var p: TCmdParam);
begin
    isInRoom:= false;
    sendUI(mtMoveToLobby, nil, 0);
end;

procedure handler_LEFT(var p: TCmdParamSL);
begin
    p.str2:= p.str1 + #10 + p.str2;
    sendUI(mtRemoveRoomClient, @p.str2[1], length(p.str2));
end;

procedure handler_LOBBY_JOINED(var p: TCmdParam);
begin
end;

procedure handler_LOBBY_JOINED_s(var s: TCmdParamS);
begin
    if s.str1 = myNickname then
    begin
        sendUI(mtMoveToLobby, nil, 0);
        sendNet('LIST');
    end;

    sendUI(mtAddLobbyClient, @s.str1[1], length(s.str1));
end;

procedure handler_LOBBY_LEFT(var p: TCmdParamSL);
begin
    p.str2:= p.str1 + #10 + p.str2;
    sendUI(mtRemoveLobbyClient, @p.str2[1], length(p.str2));
end;

procedure handler_NICK(var p: TCmdParamS);
begin
    myNickname:= p.str1;
    sendUI(mtNickname, @p.str1[1], length(p.str1));
end;

procedure handler_NOTICE(var p: TCmdParamL);
begin
end;

procedure handler_PING(var p: TCmdParam);
begin
    sendNet('PONG')
end;

procedure handler_PING_s(var s: TCmdParamS);
begin
end;

procedure handler_PROTO(var p: TCmdParami);
begin
    writeln('Protocol ', p.param1)
end;

procedure handler_REMOVE_TEAM(var p: TCmdParamS);
begin
end;

var roomInfo: string;
    roomLinesCount: integer;

procedure handler_ROOMS(var p: TCmdParam);
begin
    roomInfo:= '';
    roomLinesCount:= 0
end;

procedure handler_ROOMS_s(var s: TCmdParamS);
begin
    roomInfo:= roomInfo + s.str1 + #10;

    if roomLinesCount = 8 then
    begin
        sendUI(mtAddRoom, @roomInfo[1], length(roomInfo) - 1);
        roomLinesCount:= 0;
        roomInfo:= ''
    end else inc(roomLinesCount);
end;

procedure handler_ROOM_ADD(var p: TCmdParam);
begin
    roomInfo:= '';
    roomLinesCount:= 0
end;

procedure handler_ROOM_ADD_s(var s: TCmdParamS);
begin
    roomInfo:= roomInfo + s.str1 + #10;
    inc(roomLinesCount);

    if roomLinesCount = 9 then
    begin
        sendUI(mtAddRoom, @roomInfo[1], length(roomInfo) - 1);
        roomInfo:= '';
        roomLinesCount:= 0
    end;
end;

procedure handler_ROOM_DEL(var p: TCmdParamS);
begin
    sendUI(mtRemoveRoom, @p.str1[1], length(p.str1));
end;

procedure handler_ROOM_UPD(var p: TCmdParam);
begin
    roomInfo:= '';
    roomLinesCount:= 0
end;

procedure handler_ROOM_UPD_s(var s: TCmdParamS);
begin
    roomInfo:= roomInfo + s.str1 + #10;
    inc(roomLinesCount);

    if roomLinesCount = 10 then
        sendUI(mtUpdateRoom, @roomInfo[1], length(roomInfo) - 1);
end;

procedure handler_ROUND_FINISHED(var p: TCmdParam);
begin
end;

procedure handler_RUN_GAME(var p: TCmdParam);
begin
end;

procedure handler_SERVER_AUTH(var p: TCmdParamS);
begin
end;

procedure handler_SERVER_MESSAGE(var p: TCmdParamL);
begin
end;

procedure handler_SERVER_VARS(var p: TCmdParamSL);
begin
end;

procedure handler_TEAM_ACCEPTED(var p: TCmdParamS);
begin
end;

procedure handler_TEAM_COLOR(var p: TCmdParamSS);
begin
    netSetTeamColor(p.str1, StrToInt(p.str2));
end;

procedure handler_WARNING(var p: TCmdParamL);
begin
    sendUI(mtWarning, @p.str1[1], length(p.str1));
end;

const handlers: array[TCmdType] of PHandler = (PHandler(@handler_ADD_TEAM),
    PHandler(@handler_ADD_TEAM_s), PHandler(@handler_ASKPASSWORD),
    PHandler(@handler_BANLIST), PHandler(@handler_BANLIST_s),
    PHandler(@handler_BYE), PHandler(@handler_CFG_AMMO),
    PHandler(@handler_CFG_DRAWNMAP), PHandler(@handler_CFG_FEATURE_SIZE),
    PHandler(@handler_CFG_FULLMAPCONFIG), PHandler(@handler_CFG_FULLMAPCONFIG_s),
    PHandler(@handler_CFG_MAP), PHandler(@handler_CFG_MAPGEN),
    PHandler(@handler_CFG_MAZE_SIZE), PHandler(@handler_CFG_SCHEME),
    PHandler(@handler_CFG_SCHEME_s), PHandler(@handler_CFG_SCRIPT),
    PHandler(@handler_CFG_SEED), PHandler(@handler_CFG_TEMPLATE),
    PHandler(@handler_CFG_THEME), PHandler(@handler_CHAT),
    PHandler(@handler_CLIENT_FLAGS), PHandler(@handler_CLIENT_FLAGS_s),
    PHandler(@handler_CONNECTED), PHandler(@handler_EM), PHandler(@handler_EM_s),
    PHandler(@handler_ERROR), PHandler(@handler_HH_NUM), PHandler(@handler_INFO),
    PHandler(@handler_INFO_s), PHandler(@handler_JOINED),
    PHandler(@handler_JOINED_s), PHandler(@handler_JOINING),
    PHandler(@handler_KICKED), PHandler(@handler_LEFT),
    PHandler(@handler_LOBBY_JOINED), PHandler(@handler_LOBBY_JOINED_s),
    PHandler(@handler_LOBBY_LEFT), PHandler(@handler_NICK),
    PHandler(@handler_NOTICE), PHandler(@handler_PING), PHandler(@handler_PING_s),
    PHandler(@handler_PROTO), PHandler(@handler_REMOVE_TEAM),
    PHandler(@handler_ROOMS), PHandler(@handler_ROOMS_s),
    PHandler(@handler_ROOM_ADD), PHandler(@handler_ROOM_ADD_s),
    PHandler(@handler_ROOM_DEL), PHandler(@handler_ROOM_UPD),
    PHandler(@handler_ROOM_UPD_s), PHandler(@handler_ROUND_FINISHED),
    PHandler(@handler_RUN_GAME), PHandler(@handler_SERVER_AUTH),
    PHandler(@handler_SERVER_MESSAGE), PHandler(@handler_SERVER_VARS),
    PHandler(@handler_TEAM_ACCEPTED), PHandler(@handler_TEAM_COLOR),
    PHandler(@handler_WARNING));

procedure passNetData(p: pointer); cdecl;
begin
    handlers[TCmdData(p^).cmd.cmd](TCmdData(p^))
end;

procedure sendChatLine(msg: PChar); cdecl;
begin
    sendNetLn('CHAT');
    sendNet(msg);
end;

procedure joinRoom(roomName: PChar); cdecl;
begin
    sendNetLn('JOIN_ROOM');
    sendNet(roomName);
end;

procedure partRoom(msg: PChar); cdecl;
var s: string;
begin
    if isInRoom then
    begin
        isInRoom:= false;
        s:= 'PART';
        if length(msg) > 0 then
            s:= s + #10 + msg;
        sendNet(s);
        sendUI(mtMoveToLobby, nil, 0);
    end
end;

procedure ResetNetState;
begin
    isInRoom:= false;
end;

end.

