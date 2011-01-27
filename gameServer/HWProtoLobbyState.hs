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

{-
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
-}


handleCmd_lobby _ = return [ProtocolError "Incorrect command (state: in lobby)"]
