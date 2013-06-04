{-# LANGUAGE OverloadedStrings #-}
module HWProtoLobbyState where

import qualified Data.Map as Map
import Data.Maybe
import Data.List
import Control.Monad.Reader
--------------------------------------
import CoreTypes
import Actions
import Utils
import HandlerUtils
import RoomsAndClients
import EngineInteraction


answerAllTeams :: ClientInfo -> [TeamInfo] -> [Action]
answerAllTeams cl = concatMap toAnswer
    where
        clChan = sendChan cl
        toAnswer team =
            [AnswerClients [clChan] $ teamToNet team,
            AnswerClients [clChan] ["TEAM_COLOR", teamname team, teamcolor team],
            AnswerClients [clChan] ["HH_NUM", teamname team, showB $ hhnum team]]


handleCmd_lobby :: CmdHandler


handleCmd_lobby ["LIST"] = do
    (ci, irnc) <- ask
    let cl = irnc `client` ci
    rooms <- allRoomInfos
    let roomsInfoList = concatMap (\r -> roomInfo (nick $ irnc `client` masterID r) r) . filter (\r -> (roomProto r == clientProto cl))
    return [AnswerClients [sendChan cl] ("ROOMS" : roomsInfoList rooms)]


handleCmd_lobby ["CHAT", msg] = do
    n <- clientNick
    s <- roomOthersChans
    return [AnswerClients s ["CHAT", n, msg]]

handleCmd_lobby ["CREATE_ROOM", rName, roomPassword]
    | illegalName rName = return [Warning $ loc "Illegal room name"]
    | otherwise = do
        rs <- allRoomInfos
        cl <- thisClient
        return $ if isJust $ find (\r -> rName == name r) rs then
            [Warning "Room exists"]
            else
            [
                AddRoom rName roomPassword
                , AnswerClients [sendChan cl] ["CLIENT_FLAGS", "+hr", nick cl]
                , ModifyClient (\c -> c{isMaster = True, isReady = True})
                , ModifyRoom (\r -> r{readyPlayers = 1})
            ]


handleCmd_lobby ["CREATE_ROOM", rName] =
    handleCmd_lobby ["CREATE_ROOM", rName, ""]


handleCmd_lobby ["JOIN_ROOM", roomName, roomPassword] = do
    (_, irnc) <- ask
    let ris = allRooms irnc
    cl <- thisClient
    let maybeRI = find (\ri -> roomName == name (irnc `room` ri)) ris
    let jRI = fromJust maybeRI
    let jRoom = irnc `room` jRI
    let sameProto = clientProto cl == roomProto jRoom
    let jRoomClients = map (client irnc) $ roomClients irnc jRI
    let nicks = map nick jRoomClients
    let ownerNick = nick . fromJust $ find isMaster jRoomClients
    let chans = map sendChan (cl : jRoomClients)
    let isBanned = host cl `elem` roomBansList jRoom
    return $
        if isNothing maybeRI || not sameProto then
            [Warning $ loc "No such room"]
            else if isRestrictedJoins jRoom then
            [Warning $ loc "Joining restricted"]
            else if isRegisteredOnly jRoom then
            [Warning $ loc "Registered users only"]
            else if isBanned then
            [Warning $ loc "You are banned in this room"]
            else if roomPassword /= password jRoom then
            [NoticeMessage WrongPassword]
            else
            [
                MoveToRoom jRI
                , AnswerClients [sendChan cl] $ "JOINED" : nicks
                , AnswerClients chans ["CLIENT_FLAGS", "-r", nick cl]
                , AnswerClients [sendChan cl] $ ["CLIENT_FLAGS", "+h", ownerNick]
            ]
            ++ (if clientProto cl < 38 then map (readynessMessage cl) jRoomClients else [sendStateFlags cl jRoomClients])
            ++ answerFullConfig cl (mapParams jRoom) (params jRoom)
            ++ answerTeams cl jRoom
            ++ watchRound cl jRoom chans

        where
        readynessMessage cl c = AnswerClients [sendChan cl] [if isReady c then "READY" else "NOT_READY", nick c]
        sendStateFlags cl clients = AnswerClients [sendChan cl] . concat . intersperse [""] . filter (not . null) . concat $
                [f "+r" ready, f "-r" unready, f "+g" ingame, f "-g" inroomlobby]
            where
            (ready, unready) = partition isReady clients
            (ingame, inroomlobby) = partition isInGame clients
            f fl lst = ["CLIENT_FLAGS" : fl : map nick lst | not $ null lst]

        toAnswer cl (paramName, paramStrs) = AnswerClients [sendChan cl] $ "CFG" : paramName : paramStrs

        answerFullConfig cl mpr pr
            | clientProto cl < 38 = map (toAnswer cl) $
                 (reverse . map (\(a, b) -> (a, [b])) $ Map.toList mpr)
                 ++ (("SCHEME", pr Map.! "SCHEME")
                 : (filter (\(p, _) -> p /= "SCHEME") $ Map.toList pr))

            | otherwise = map (toAnswer cl) $
                 ("FULLMAPCONFIG", Map.elems mpr)
                 : ("SCHEME", pr Map.! "SCHEME")
                 : (filter (\(p, _) -> p /= "SCHEME") $ Map.toList pr)

        answerTeams cl jRoom = let f = if isJust $ gameInfo jRoom then teamsAtStart . fromJust . gameInfo else teams in answerAllTeams cl $ f jRoom

        watchRound cl jRoom chans = if isNothing $ gameInfo jRoom then
                    []
                else
                    [AnswerClients [sendChan cl]  ["RUN_GAME"]
                    , AnswerClients chans ["CLIENT_FLAGS", "+g", nick cl]
                    , ModifyClient (\c -> c{isInGame = True})
                    , AnswerClients [sendChan cl] $ "EM" : toEngineMsg "e$spectate 1" : (reverse . roundMsgs . fromJust . gameInfo $ jRoom)]


handleCmd_lobby ["JOIN_ROOM", roomName] =
    handleCmd_lobby ["JOIN_ROOM", roomName, ""]


handleCmd_lobby ["FOLLOW", asknick] = do
    (_, rnc) <- ask
    clChan <- liftM sendChan thisClient
    ci <- clientByNick asknick
    let ri = clientRoom rnc $ fromJust ci
    let roomName = name $ room rnc ri
    if isNothing ci || ri == lobbyId then
        return []
        else
        liftM ((:) (AnswerClients [clChan] ["JOINING", roomName])) $ handleCmd_lobby ["JOIN_ROOM", roomName]


handleCmd_lobby ("RND":rs) = do
    c <- liftM sendChan thisClient
    return [Random [c] rs]

    ---------------------------
    -- Administrator's stuff --

handleCmd_lobby ["KICK", kickNick] = do
    (ci, _) <- ask
    cl <- thisClient
    kickId <- clientByNick kickNick
    return [KickClient $ fromJust kickId | isAdministrator cl && isJust kickId && fromJust kickId /= ci]


handleCmd_lobby ["BAN", banNick, reason, duration] = do
    (ci, _) <- ask
    cl <- thisClient
    banId <- clientByNick banNick
    return [BanClient (readInt_ duration) reason (fromJust banId) | isAdministrator cl && isJust banId && fromJust banId /= ci]

handleCmd_lobby ["BANIP", ip, reason, duration] = do
    cl <- thisClient
    return [BanIP ip (readInt_ duration) reason | isAdministrator cl]

handleCmd_lobby ["BANNICK", n, reason, duration] = do
    cl <- thisClient
    return [BanNick n (readInt_ duration) reason | isAdministrator cl]

handleCmd_lobby ["BANLIST"] = do
    cl <- thisClient
    return [BanList | isAdministrator cl]


handleCmd_lobby ["UNBAN", entry] = do
    cl <- thisClient
    return [Unban entry | isAdministrator cl]


handleCmd_lobby ["SET_SERVER_VAR", "MOTD_NEW", newMessage] = do
    cl <- thisClient
    return [ModifyServerInfo (\si -> si{serverMessage = newMessage}) | isAdministrator cl]

handleCmd_lobby ["SET_SERVER_VAR", "MOTD_OLD", newMessage] = do
    cl <- thisClient
    return [ModifyServerInfo (\si -> si{serverMessageForOldVersions = newMessage}) | isAdministrator cl]

handleCmd_lobby ["SET_SERVER_VAR", "LATEST_PROTO", protoNum] = do
    cl <- thisClient
    return [ModifyServerInfo (\si -> si{latestReleaseVersion = readNum}) | isAdministrator cl && readNum > 0]
    where
        readNum = readInt_ protoNum

handleCmd_lobby ["GET_SERVER_VAR"] = do
    cl <- thisClient
    return [SendServerVars | isAdministrator cl]

handleCmd_lobby ["CLEAR_ACCOUNTS_CACHE"] = do
    cl <- thisClient
    return [ClearAccountsCache | isAdministrator cl]

handleCmd_lobby ["RESTART_SERVER"] = do
    cl <- thisClient
    return [RestartServer | isAdministrator cl]

handleCmd_lobby ["STATS"] = do
    cl <- thisClient
    return [Stats | isAdministrator cl]

handleCmd_lobby _ = return [ProtocolError "Incorrect command (state: in lobby)"]
