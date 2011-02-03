{-# LANGUAGE OverloadedStrings #-}
module HWProtoLobbyState where

import qualified Data.Map as Map
import qualified Data.IntSet as IntSet
import qualified Data.Foldable as Foldable
import Data.Maybe
import Data.List
import Data.Word
import Control.Monad.Reader
import qualified Data.ByteString.Char8 as B
import Control.DeepSeq
--------------------------------------
import CoreTypes
import Actions
import Utils
import HandlerUtils
import RoomsAndClients

answerAllTeams cl = concatMap toAnswer
    where
        clChan = sendChan cl
        toAnswer team =
            [AnswerClients [clChan] $ teamToNet team,
            AnswerClients [clChan] ["TEAM_COLOR", teamname team, teamcolor team],
            AnswerClients [clChan] ["HH_NUM", teamname team, B.pack . show $ hhnum team]]

handleCmd_lobby :: CmdHandler


handleCmd_lobby ["LIST"] = do
    (ci, irnc) <- ask
    let cl = irnc `client` ci
    rooms <- allRoomInfos
    let roomsInfoList = concatMap (roomInfo irnc) . filter (\r -> (roomProto r == clientProto cl) && not (isRestrictedJoins r))
    return [AnswerClients [sendChan cl] ("ROOMS" : roomsInfoList rooms)]
    where
        roomInfo irnc room = [
                showB $ gameinprogress room,
                name room,
                showB $ playersIn room,
                showB $ length $ teams room,
                nick $ irnc `client` masterID room,
                head (Map.findWithDefault ["+gen+"] "MAP" (params room)),
                head (Map.findWithDefault ["Default"] "SCHEME" (params room)),
                head (Map.findWithDefault ["Default"] "AMMO" (params room))
                ]


handleCmd_lobby ["CHAT", msg] = do
    n <- clientNick
    s <- roomOthersChans
    return [AnswerClients s ["CHAT", n, msg]]

handleCmd_lobby ["CREATE_ROOM", newRoom, roomPassword]
    | illegalName newRoom = return [Warning "Illegal room name"]
    | otherwise = do
        rs <- allRoomInfos
        cl <- thisClient
        return $ if isJust $ find (\room -> newRoom == name room) rs then 
            [Warning "Room exists"]
            else
            [
                AddRoom newRoom roomPassword,
                AnswerClients [sendChan cl] ["NOT_READY", nick cl]
            ]


handleCmd_lobby ["CREATE_ROOM", newRoom] =
    handleCmd_lobby ["CREATE_ROOM", newRoom, ""]


handleCmd_lobby ["JOIN_ROOM", roomName, roomPassword] = do
    (ci, irnc) <- ask
    let ris = allRooms irnc
    cl <- thisClient
    let maybeRI = find (\ri -> roomName == name (irnc `room` ri)) ris
    let jRI = fromJust maybeRI
    let jRoom = irnc `room` jRI
    let jRoomClients = map (client irnc) $ roomClients irnc jRI
    let nicks = map nick jRoomClients
    let chans = map sendChan (cl : jRoomClients)
    return $
        if isNothing maybeRI then 
            [Warning "No such rooms"]
            else if isRestrictedJoins jRoom then
            [Warning "Joining restricted"]
            else if roomPassword /= password jRoom then
            [Warning "Wrong password"]
            else
            [
                MoveToRoom jRI,
                AnswerClients [sendChan cl] $ "JOINED" : nicks,
                AnswerClients chans ["NOT_READY", nick cl]
            ]
            ++ (map (readynessMessage cl) jRoomClients)
            ++ (answerFullConfig cl $ params jRoom)
            ++ (answerTeams cl jRoom)
            ++ (watchRound cl jRoom)

        where
        readynessMessage cl c = AnswerClients [sendChan cl] [if isReady c then "READY" else "NOT_READY", nick c]

        toAnswer cl (paramName, paramStrs) = AnswerClients [sendChan cl] $ "CFG" : paramName : paramStrs

        answerFullConfig cl params = map (toAnswer cl) (leftConfigPart ++ rightConfigPart)
            where
            (leftConfigPart, rightConfigPart) = partition (\(p, _) -> p /= "MAP") $ Map.toList params

        answerTeams cl jRoom = let f = if gameinprogress jRoom then teamsAtStart else teams in answerAllTeams cl $ f jRoom

        watchRound cl jRoom = if not $ gameinprogress jRoom then
                    []
                else
                    [AnswerClients [sendChan cl]  ["RUN_GAME"],
                    AnswerClients [sendChan cl] $ "EM" : toEngineMsg "e$spectate 1" : Foldable.toList (roundMsgs jRoom)]


handleCmd_lobby ["JOIN_ROOM", roomName] =
    handleCmd_lobby ["JOIN_ROOM", roomName, ""]


handleCmd_lobby ["FOLLOW", asknick] = do
    (_, rnc) <- ask
    ci <- clientByNick asknick
    let ri = clientRoom rnc $ fromJust ci
    let clRoom = room rnc ri
    if isNothing ci || ri == lobbyId then
        return []
        else
        handleCmd_lobby ["JOIN_ROOM", name clRoom]

    ---------------------------
    -- Administrator's stuff --

handleCmd_lobby ["KICK", kickNick] = do
    (ci, _) <- ask
    cl <- thisClient
    kickId <- clientByNick kickNick
    return [KickClient $ fromJust kickId | isAdministrator cl && isJust kickId && fromJust kickId /= ci]


handleCmd_lobby ["BAN", banNick, reason] = do
    (ci, _) <- ask
    cl <- thisClient
    banId <- clientByNick banNick
    return [BanClient 60 reason (fromJust banId) | isAdministrator cl && isJust banId && fromJust banId /= ci]


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
        readNum = case B.readInt protoNum of
                       Just (i, t) | B.null t -> fromIntegral i
                       otherwise -> 0

handleCmd_lobby ["GET_SERVER_VAR"] = do
    cl <- thisClient
    return [SendServerVars | isAdministrator cl]

handleCmd_lobby ["CLEAR_ACCOUNTS_CACHE"] = do
    cl <- thisClient
    return [ClearAccountsCache | isAdministrator cl]

handleCmd_lobby ["RESTART_SERVER", restartType] = do
    cl <- thisClient
    return [RestartServer f | let f = restartType == "FORCE", isAdministrator cl]


handleCmd_lobby _ = return [ProtocolError "Incorrect command (state: in lobby)"]
