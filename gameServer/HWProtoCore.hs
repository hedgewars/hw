{-# LANGUAGE OverloadedStrings #-}
module HWProtoCore where

import Control.Monad.Reader
import Data.Maybe
import qualified Data.ByteString.Char8 as B
--------------------------------------
import CoreTypes
import Actions
import HWProtoNEState
import HWProtoLobbyState
import HWProtoInRoomState
import HandlerUtils
import RoomsAndClients
import Utils

handleCmd, handleCmd_loggedin :: CmdHandler c


handleCmd ["PING"] = answerClient ["PONG"]


handleCmd ("QUIT" : xs) = return [ByeClient msg]
    where
        msg = if not $ null xs then head xs else "bye"


handleCmd ["PONG"] = do
    cl <- thisClient
    if pingsQueue cl == 0 then
        return [ProtocolError "Protocol violation"]
        else
        return [ModifyClient (\c -> c{pingsQueue = pingsQueue c - 1})]

handleCmd cmd = do
    (ci, irnc) <- ask
    if logonPassed (irnc `client` ci) then
        handleCmd_loggedin cmd
        else
        handleCmd_NotEntered cmd


handleCmd_loggedin ["INFO", asknick] = do
    (_, rnc) <- ask
    maybeClientId <- clientByNick asknick
    let noSuchClient = isNothing maybeClientId
    let clientId = fromJust maybeClientId
    let cl = rnc `client` fromJust maybeClientId
    let roomId = clientRoom rnc clientId
    let clRoom = room rnc roomId
    let roomMasterSign = if isMaster cl then "@" else ""
    let adminSign = if isAdministrator cl then "@" else ""
    let roomInfo = if roomId /= lobbyId then roomMasterSign `B.append` "room " `B.append` name clRoom else adminSign `B.append` "lobby"
    let roomStatus = if gameinprogress clRoom then
            if teamsInGame cl > 0 then "(playing)" else "(spectating)"
            else
            ""
    if noSuchClient then
        return []
        else
        answerClient [
            "INFO",
            nick cl,
            "[" `B.append` host cl `B.append` "]",
            protoNumber2ver $ clientProto cl,
            "[" `B.append` roomInfo `B.append` "]" `B.append` roomStatus
            ]


handleCmd_loggedin cmd = do
    (ci, rnc) <- ask
    if clientRoom rnc ci == lobbyId then
        handleCmd_lobby cmd
        else
        handleCmd_inRoom cmd
