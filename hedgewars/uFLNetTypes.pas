unit uFLNetTypes;
interface

type TCmdType = (cmd_ADD_TEAM, cmd_ADD_TEAM_s, cmd_ASKPASSWORD, cmd_BANLIST,
    cmd_BANLIST_s, cmd_BYE, cmd_CFG_AMMO, cmd_CFG_DRAWNMAP, cmd_CFG_FEATURE_SIZE,
    cmd_CFG_FULLMAPCONFIG, cmd_CFG_FULLMAPCONFIG_s, cmd_CFG_MAP, cmd_CFG_MAPGEN,
    cmd_CFG_MAZE_SIZE, cmd_CFG_SCHEME, cmd_CFG_SCHEME_s, cmd_CFG_SCRIPT,
    cmd_CFG_SEED, cmd_CFG_TEMPLATE, cmd_CFG_THEME, cmd_CHAT, cmd_CLIENT_FLAGS,
    cmd_CLIENT_FLAGS_s, cmd_CONNECTED, cmd_EM, cmd_EM_s, cmd_ERROR, cmd_HH_NUM,
    cmd_HH_NUM_s, cmd_INFO, cmd_INFO_s, cmd_JOINED, cmd_JOINED_s, cmd_JOINING,
    cmd_KICKED, cmd_LEFT, cmd_LOBBY_JOINED, cmd_LOBBY_JOINED_s, cmd_LOBBY_LEFT,
    cmd_NICK, cmd_NOTICE, cmd_PING, cmd_PING_s, cmd_PROTO, cmd_REMOVE_TEAM,
    cmd_ROOMS, cmd_ROOMS_s, cmd_ROOM_ADD, cmd_ROOM_ADD_s, cmd_ROOM_DEL,
    cmd_ROOM_UPD, cmd_ROOM_UPD_s, cmd_ROUND_FINISHED, cmd_RUN_GAME, cmd_SERVER_AUTH,
    cmd_SERVER_MESSAGE, cmd_SERVER_VARS, cmd_TEAM_ACCEPTED, cmd_TEAM_COLOR,
    cmd_TEAM_COLOR_s, cmd_WARNING);

    type TCmdParam = packed record
        cmd: TCmdType;
        end;
    type TCmdParamL = packed record
        cmd: TCmdType;
        str1: string;
        end;
    type TCmdParamS = packed record
        cmd: TCmdType;
        str1: shortstring;
        end;
    type TCmdParamSL = packed record
        cmd: TCmdType;
        str1: shortstring;
        str2: string;
        end;
    type TCmdParami = packed record
        cmd: TCmdType;
        param1: LongInt;
        end;

    TCmdData = record
                   case byte of
                       0: (cmd: TCmdParam);
                       1: (cpl: TCmdParamL);
                       2: (cps: TCmdParamS);
                       3: (cpsl: TCmdParamSL);
                       4: (cpi: TCmdParami);
               end;

implementation

end.
