unit uFLTypes;
interface

type
    TMessageType = (mtPreview, mtAddPlayingTeam, mtRemovePlayingTeam, mtAddTeam, mtRemoveTeam
                    , mtTeamColor, mtNetData, mtConnected, mtDisconnected, mtAddLobbyClient
                    , mtRemoveLobbyClient, mtLobbyChatLine, mtAddRoom, mtUpdateRoom
                    , mtRemoveRoom);

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

implementation

end.
