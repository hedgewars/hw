unit uFLTypes;
interface

const
    MAXARGS = 32;

type
    TMessageType = (mtRenderingPreview, mtPreview, mtAddPlayingTeam, mtRemovePlayingTeam, mtAddTeam, mtRemoveTeam
                    , mtTeamColor, mtNetData, mtFlibEvent, mtConnected, mtDisconnected, mtAddLobbyClient
                    , mtRemoveLobbyClient, mtLobbyChatLine, mtAddRoomClient
                    , mtRemoveRoomClient, mtRoomChatLine, mtAddRoom, mtUpdateRoom
                    , mtRemoveRoom, mtError, mtWarning, mtMoveToLobby, mtMoveToRoom
                    , mtNickname, mtSeed, mtTheme, mtScript, mtFeatureSize, mtMapGen
                    , mtMap, mtMazeSize, mtTemplate);

    TFLIBEvent = (flibGameFinished);

    TIPCMessage = record
                   str: shortstring;
                   len: Longword;
                   buf: Pointer
               end;

    TIPCCallback = procedure (p: pointer; msg: PChar; len: Longword);
    TUICallback = procedure (p: pointer; msgType: TMessageType; msg: PChar; len: Longword); cdecl;

    TGameType = (gtPreview, gtLocal);
    THedgehog = record
            name: shortstring;
            hat: shortstring;
            end;
    TTeam = record
            teamName: shortstring;
            flag: shortstring;
            graveName: shortstring;
            fortName: shortstring;
            owner: shortstring;
            color: Longword;
            extDriven: boolean;
            botLevel: Longword;
            hedgehogs: array[0..7] of THedgehog;
            hogsNumber: Longword;
        end;
    PTeam = ^TTeam;

    TScheme = record
            schemeName
            , scriptparam : shortstring;
            fortsmode
            , divteams
            , solidland
            , border
            , lowgrav
            , laser
            , invulnerability
            , mines
            , vampiric
            , karma
            , artillery
            , randomorder
            , king
            , placehog
            , sharedammo
            , disablegirders
            , disablewind
            , morewind
            , tagteam
            , bottomborder: boolean;
            damagefactor
            , turntime
            , health
            , suddendeath
            , caseprobability
            , minestime
            , landadds
            , minedudpct
            , explosives
            , minesnum
            , healthprobability
            , healthcaseamount
            , waterrise
            , healthdecrease
            , ropepct
            , getawaytime
            , worldedge: LongInt
        end;
    PScheme = ^TScheme;
    TAmmo = record
            ammoName: shortstring;
            a, b, c, d: shortstring;
        end;
    PAmmo = ^TAmmo;

    PGameConfig = ^TGameConfig;
    TGameConfig = record
            seed: shortstring;
            theme: shortstring;
            script: shortstring;
            map: shortstring;
            scheme: TScheme;
            ammo: TAmmo;
            mapgen: LongInt;
            featureSize: LongInt;
            mazesize: LongInt;
            template: LongInt;
            gameType: TGameType;
            teams: array[0..7] of TTeam;
            arguments: array[0..Pred(MAXARGS)] of shortstring;
            argv: array[0..Pred(MAXARGS)] of PChar;
            argumentsNumber: Longword;
            nextConfig: PGameConfig;
            end;

implementation

end.
