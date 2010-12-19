module HWProtoLobbyState where

import qualified Data.Map as Map
import qualified Data.IntMap as IntMap
import qualified Data.IntSet as IntSet
import qualified Data.Foldable as Foldable
import Data.Maybe
import Data.List
import Data.Word
--------------------------------------
import CoreTypes
import Actions
import Utils

answerAllTeams protocol teams = concatMap toAnswer teams
    where
        toAnswer team =
            [AnswerThisClient $ teamToNet protocol team,
            AnswerThisClient ["TEAM_COLOR", teamname team, teamcolor team],
            AnswerThisClient ["HH_NUM", teamname team, show $ hhnum team]]

handleCmd_lobby :: CmdHandler

handleCmd_lobby clID clients rooms ["LIST"] =
    [AnswerThisClient ("ROOMS" : roomsInfoList)]
    where
        roomsInfoList = concatMap roomInfo sameProtoRooms
        sameProtoRooms = filter (\r -> (roomProto r == protocol) && not (isRestrictedJoins r)) roomsList
        roomsList = IntMap.elems rooms
        protocol = clientProto client
        client = clients IntMap.! clID
        roomInfo room
            | clientProto client < 28 = [
                name room,
                show (playersIn room) ++ "(" ++ show (length $ teams room) ++ ")",
                show $ gameinprogress room
                ]
            | otherwise = [
                show $ gameinprogress room,
                name room,
                show $ playersIn room,
                show $ length $ teams room,
                nick $ clients IntMap.! (masterID room),
                head (Map.findWithDefault ["+gen+"] "MAP" (params room)),
                head (Map.findWithDefault ["Default"] "SCHEME" (params room)),
                head (Map.findWithDefault ["Default"] "AMMO" (params room))
                ]

handleCmd_lobby clID clients _ ["CHAT", msg] =
    [AnswerOthersInRoom ["CHAT", clientNick, msg]]
    where
        clientNick = nick $ clients IntMap.! clID


handleCmd_lobby clID clients rooms ["CREATE_ROOM", newRoom, roomPassword]
    | haveSameRoom = [Warning "Room exists"]
    | illegalName newRoom = [Warning "Illegal room name"]
    | otherwise =
        [RoomRemoveThisClient "", -- leave lobby
        AddRoom newRoom roomPassword,
        AnswerThisClient ["NOT_READY", clientNick]
        ]
    where
        clientNick = nick $ clients IntMap.! clID
        haveSameRoom = isJust $ find (\room -> newRoom == name room) $ IntMap.elems rooms


handleCmd_lobby clID clients rooms ["CREATE_ROOM", newRoom] =
    handleCmd_lobby clID clients rooms ["CREATE_ROOM", newRoom, ""]


handleCmd_lobby clID clients rooms ["JOIN_ROOM", roomName, roomPassword]
    | noSuchRoom = [Warning "No such room"]
    | isRestrictedJoins jRoom = [Warning "Joining restricted"]
    | roomPassword /= password jRoom = [Warning "Wrong password"]
    | otherwise =
        [RoomRemoveThisClient "", -- leave lobby
        RoomAddThisClient rID] -- join room
        ++ answerNicks
        ++ answerReady
        ++ [AnswerThisRoom ["NOT_READY", nick client]]
        ++ answerFullConfig
        ++ answerTeams
        ++ watchRound
    where
        noSuchRoom = isNothing mbRoom
        mbRoom = find (\r -> roomName == name r && roomProto r == clientProto client) $ IntMap.elems rooms
        jRoom = fromJust mbRoom
        rID = roomUID jRoom
        client = clients IntMap.! clID
        roomClientsIDs = IntSet.elems $ playersIDs jRoom
        answerNicks =
            [AnswerThisClient $ "JOINED" :
            map (\clID -> nick $ clients IntMap.! clID) roomClientsIDs | playersIn jRoom /= 0]
        answerReady = map
            ((\ c ->
                AnswerThisClient
                [if isReady c then "READY" else "NOT_READY", nick c])
            . (\ clID -> clients IntMap.! clID))
            roomClientsIDs

        toAnswer (paramName, paramStrs) = AnswerThisClient $ "CFG" : paramName : paramStrs
        
        answerFullConfig = map toAnswer (leftConfigPart ++ rightConfigPart)
        (leftConfigPart, rightConfigPart) = partition (\(p, _) -> p /= "MAP") (Map.toList $ params jRoom)

        watchRound = if not $ gameinprogress jRoom then
                    []
                else
                    [AnswerThisClient  ["RUN_GAME"],
                    AnswerThisClient $ "EM" : toEngineMsg "e$spectate 1" : Foldable.toList (roundMsgs jRoom)]

        answerTeams = if gameinprogress jRoom then
                answerAllTeams (clientProto client) (teamsAtStart jRoom)
            else
                answerAllTeams (clientProto client) (teams jRoom)


handleCmd_lobby clID clients rooms ["JOIN_ROOM", roomName] =
    handleCmd_lobby clID clients rooms ["JOIN_ROOM", roomName, ""]
    

handleCmd_lobby clID clients rooms ["FOLLOW", asknick] =
    if noSuchClient || roomID followClient == 0 then
        []
    else
        handleCmd_lobby clID clients rooms ["JOIN_ROOM", roomName]
    where
        maybeClient = Foldable.find (\cl -> asknick == nick cl) clients
        noSuchClient = isNothing maybeClient
        followClient = fromJust maybeClient
        roomName = name $ rooms IntMap.! roomID followClient


    ---------------------------
    -- Administrator's stuff --

handleCmd_lobby clID clients rooms ["KICK", kickNick] =
        [KickClient kickID | isAdministrator client && (not noSuchClient) && kickID /= clID]
    where
        client = clients IntMap.! clID
        maybeClient = Foldable.find (\cl -> kickNick == nick cl) clients
        noSuchClient = isNothing maybeClient
        kickID = clientUID $ fromJust maybeClient


handleCmd_lobby clID clients rooms ["BAN", banNick] =
    if not $ isAdministrator client then
        []
    else
        BanClient banNick : handleCmd_lobby clID clients rooms ["KICK", banNick]
    where
        client = clients IntMap.! clID



handleCmd_lobby clID clients rooms ["SET_SERVER_VAR", "MOTD_NEW", newMessage] =
        [ModifyServerInfo (\si -> si{serverMessage = newMessage}) | isAdministrator client]
    where
        client = clients IntMap.! clID

handleCmd_lobby clID clients rooms ["SET_SERVER_VAR", "MOTD_OLD", newMessage] =
        [ModifyServerInfo (\si -> si{serverMessageForOldVersions = newMessage}) | isAdministrator client]
    where
        client = clients IntMap.! clID

handleCmd_lobby clID clients rooms ["SET_SERVER_VAR", "LATEST_PROTO", protoNum] =
    [ModifyServerInfo (\si -> si{latestReleaseVersion = fromJust readNum}) | isAdministrator client && isJust readNum]
    where
        client = clients IntMap.! clID
        readNum = maybeRead protoNum :: Maybe Word16

handleCmd_lobby clID clients rooms ["GET_SERVER_VAR"] =
    [SendServerVars | isAdministrator client]
    where
        client = clients IntMap.! clID


handleCmd_lobby clID clients rooms ["CLEAR_ACCOUNTS_CACHE"] =
        [ClearAccountsCache | isAdministrator client]
    where
        client = clients IntMap.! clID


handleCmd_lobby clID _ _ _ = [ProtocolError "Incorrect command (state: in lobby)"]
