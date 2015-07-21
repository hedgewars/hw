unit uFLNetTypes;
interface

type TCmdType = (cmd___UNKNOWN__, cmd_WARNING, cmd_TEAM_COLOR, cmd_TEAM_ACCEPTED, cmd_SERVER_VARS, cmd_SERVER_MESSAGE, cmd_SERVER_AUTH, cmd_RUN_GAME, cmd_ROUND_FINISHED, cmd_ROOMS, cmd_PROTO, cmd_PING, cmd_NOTICE, cmd_NICK, cmd_LOBBY_LEFT, cmd_LOBBY_JOINED, cmd_LEFT, cmd_KICKED, cmd_JOINING, cmd_JOINED, cmd_INFO, cmd_HH_NUM, cmd_EM, cmd_CONNECTED, cmd_CLIENT_FLAGS, cmd_CHAT, cmd_BYE, cmd_BANLIST, cmd_ASKPASSWORD);
    TCmdConnectedData = record
                        cmd: TCmdType;
                        protocolNumber: Longword
                    end;
    TCmdData = record
                   case byte of
                       0: (cmdConnected: TCmdConnectedData)
               end;

implementation

end.
