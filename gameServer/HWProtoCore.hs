{-# LANGUAGE OverloadedStrings #-}
module HWProtoCore where

import qualified Data.IntMap as IntMap
import Data.Foldable
import Maybe
import Control.Monad.Reader
--------------------------------------
import CoreTypes
import Actions
import Utils
import HWProtoNEState
import HWProtoLobbyState
import HWProtoInRoomState
import HandlerUtils
import RoomsAndClients

handleCmd, handleCmd_loggedin :: CmdHandler


handleCmd ["PING"] = answerClient ["PONG"]


handleCmd ("QUIT" : xs) = return [ByeClient msg]
    where
        msg = if not $ null xs then head xs else ""

{-
handleCmd ["PONG"] =
    if pingsQueue client == 0 then
        [ProtocolError "Protocol violation"]
    else
        [ModifyClient (\cl -> cl{pingsQueue = pingsQueue cl - 1})]
    where
        client = clients IntMap.! clID
-}

handleCmd cmd = do
    (ci, irnc) <- ask
    if logonPassed (irnc `client` ci) then
        handleCmd_loggedin cmd
        else
        handleCmd_NotEntered cmd

{-
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

-}


handleCmd_loggedin cmd = do
    (ci, rnc) <- ask
    if clientRoom rnc ci == lobbyId then
        handleCmd_lobby cmd
        else
        handleCmd_inRoom cmd
