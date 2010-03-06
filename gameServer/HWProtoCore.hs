module HWProtoCore where

import qualified Data.IntMap as IntMap
import Data.Foldable
import Maybe
--------------------------------------
import CoreTypes
import Actions
import Utils
import HWProtoNEState
import HWProtoLobbyState
import HWProtoInRoomState

handleCmd, handleCmd_loggedin :: CmdHandler

handleCmd clID _ _ ["PING"] = [AnswerThisClient ["PONG"]]

handleCmd clID clients rooms ("QUIT" : xs) =
    [ByeClient msg]
    where
        msg = if not $ null xs then head xs else ""


handleCmd clID clients _ ["PONG"] =
    if pingsQueue client == 0 then
        [ProtocolError "Protocol violation"]
    else
        [ModifyClient (\cl -> cl{pingsQueue = pingsQueue cl - 1})]
    where
        client = clients IntMap.! clID


handleCmd clID clients rooms cmd =
    if not $ logonPassed client then
        handleCmd_NotEntered clID clients rooms cmd
    else
        handleCmd_loggedin clID clients rooms cmd
    where
        client = clients IntMap.! clID


handleCmd_loggedin clID clients rooms ["INFO", asknick] =
    if noSuchClient then
        []
    else
        [AnswerThisClient
            ["INFO",
            nick client,
            "[" ++ host client ++ "]",
            protoNumber2ver $ clientProto client,
            "[" ++ roomInfo ++ "]" ++ roomStatus]]
    where
        maybeClient = find (\cl -> asknick == nick cl) clients
        noSuchClient = isNothing maybeClient
        client = fromJust maybeClient
        room = rooms IntMap.! roomID client
        roomInfo = if roomID client /= 0 then roomMasterSign ++ "room " ++ (name room) else adminSign ++ "lobby"
        roomMasterSign = if isMaster client then "@" else ""
        adminSign = if isAdministrator client then "@" else ""
        roomStatus =
            if gameinprogress room
            then if teamsInGame client > 0 then "(playing)" else "(spectating)"
            else ""


handleCmd_loggedin clID clients rooms cmd =
    if roomID client == 0 then
        handleCmd_lobby clID clients rooms cmd
    else
        handleCmd_inRoom clID clients rooms cmd
    where
        client = clients IntMap.! clID
