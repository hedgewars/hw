unit uFLNetProtocol;
interface

procedure passNetData(p: pointer); cdecl;

procedure sendChatLine(msg: PChar); cdecl;
procedure joinRoom(roomName: PChar); cdecl;
procedure partRoom(msg: PChar); cdecl;

procedure ResetNetState;

implementation
uses uFLNetTypes, uFLTypes, uFLUICallback, uFLNet;

type
    PHandler = procedure (var t: TCmdData);

var isInRoom: boolean;

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

procedure handler_HH_NUM(var p: TCmdParam);
begin
end;

procedure handler_HH_NUM_s(var s: TCmdParamS);
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
    if s.str1 = 'qmlfrontend' then // we joined a room
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

procedure handler_LEFT(var p: TCmdParamS);
begin
    sendUI(mtRemoveLobbyClient, @p.str1[1], length(p.str1));
end;

procedure handler_LEFT_s(var s: TCmdParamS);
begin
end;

procedure handler_LOBBY_JOINED(var p: TCmdParam);
begin
end;

procedure handler_LOBBY_JOINED_s(var s: TCmdParamS);
begin
    if s.str1 = 'qmlfrontend' then
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
end;

var roomInfo: string;
    roomLinesCount: integer;

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

procedure handler_TEAM_COLOR(var p: TCmdParam);
begin
end;

procedure handler_TEAM_COLOR_s(var s: TCmdParamS);
begin
end;

procedure handler_WARNING(var p: TCmdParamL);
begin
    sendUI(mtWarning, @p.str1[1], length(p.str1));
end;

const handlers: array[TCmdType] of PHandler = (PHandler(@handler_ASKPASSWORD),
    PHandler(@handler_BANLIST), PHandler(@handler_BANLIST_s),
    PHandler(@handler_BYE), PHandler(@handler_CHAT),
    PHandler(@handler_CLIENT_FLAGS), PHandler(@handler_CLIENT_FLAGS_s),
    PHandler(@handler_CONNECTED), PHandler(@handler_EM), PHandler(@handler_EM_s),
    PHandler(@handler_ERROR), PHandler(@handler_HH_NUM),
    PHandler(@handler_HH_NUM_s), PHandler(@handler_INFO), PHandler(@handler_INFO_s),
    PHandler(@handler_JOINED), PHandler(@handler_JOINED_s),
    PHandler(@handler_JOINING), PHandler(@handler_KICKED), PHandler(@handler_LEFT),
    PHandler(@handler_LEFT_s), PHandler(@handler_LOBBY_JOINED),
    PHandler(@handler_LOBBY_JOINED_s), PHandler(@handler_LOBBY_LEFT),
    PHandler(@handler_NICK), PHandler(@handler_NOTICE), PHandler(@handler_PING),
    PHandler(@handler_PING_s), PHandler(@handler_PROTO), PHandler(@handler_ROOMS),
    PHandler(@handler_ROOMS_s), PHandler(@handler_ROOM_ADD),
    PHandler(@handler_ROOM_ADD_s), PHandler(@handler_ROOM_DEL),
    PHandler(@handler_ROOM_UPD), PHandler(@handler_ROOM_UPD_s),
    PHandler(@handler_ROUND_FINISHED), PHandler(@handler_RUN_GAME),
    PHandler(@handler_SERVER_AUTH), PHandler(@handler_SERVER_MESSAGE),
    PHandler(@handler_SERVER_VARS), PHandler(@handler_TEAM_ACCEPTED),
    PHandler(@handler_TEAM_COLOR), PHandler(@handler_TEAM_COLOR_s),
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

