unit uFLNetProtocol;
interface

procedure passNetData(p: pointer); cdecl;

implementation
uses uFLNetTypes, uFLTypes, uFLUICallback, uFLNet;

type
    PHandler = procedure (var t: TCmdData);

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
end;

procedure handler_CHAT(var p: TCmdParamSL);
begin
end;

procedure handler_CLIENT_FLAGS(var p: TCmdParamS);
begin
end;
 
procedure handler_CLIENT_FLAGS_s(var s: TCmdParamS);
begin
end;

procedure handler_CONNECTED(var p: TCmdParami);
begin
    writeln('Connected!!!!! ', p.param1)
end;

procedure handler_EM(var p: TCmdParam);
begin
end;
 
procedure handler_EM_s(var s: TCmdParamS);
begin
end;

procedure handler_ERROR(var p: TCmdParamL);
begin
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
end;

procedure handler_JOINING(var p: TCmdParamS);
begin
end;

procedure handler_KICKED(var p: TCmdParam);
begin
end;

procedure handler_LEFT(var p: TCmdParamS);
begin
end;
 
procedure handler_LEFT_s(var s: TCmdParamS);
begin
end;

procedure handler_LOBBY_JOINED(var p: TCmdParam);
begin
end;
 
procedure handler_LOBBY_JOINED_s(var s: TCmdParamS);
begin
end;

procedure handler_LOBBY_LEFT(var p: TCmdParamSL);
begin
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

procedure handler_ROOMS(var p: TCmdParam);
begin
end;
 
procedure handler_ROOMS_s(var s: TCmdParamS);
begin
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
    PHandler(@handler_ROOMS_s), PHandler(@handler_ROUND_FINISHED),
    PHandler(@handler_RUN_GAME), PHandler(@handler_SERVER_AUTH),
    PHandler(@handler_SERVER_MESSAGE), PHandler(@handler_SERVER_VARS),
    PHandler(@handler_TEAM_ACCEPTED), PHandler(@handler_TEAM_COLOR),
    PHandler(@handler_TEAM_COLOR_s), PHandler(@handler_WARNING));

procedure passNetData(p: pointer); cdecl;
begin
    handlers[TCmdData(p^).cmd.cmd](TCmdData(p^))
end;

end.

