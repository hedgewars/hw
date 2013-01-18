{-# LANGUAGE OverloadedStrings #-}
module HWProtoCore where

import Control.Monad.Reader
import Data.Maybe
import qualified Data.ByteString.Char8 as B
import qualified Data.List as L
--------------------------------------
import CoreTypes
import Actions
import HWProtoNEState
import HWProtoLobbyState
import HWProtoInRoomState
import HandlerUtils
import RoomsAndClients
import Utils

handleCmd, handleCmd_loggedin :: CmdHandler


handleCmd ["PING"] = answerClient ["PONG"]


handleCmd ("QUIT" : xs) = return [ByeClient msg]
    where
        msg = if not $ null xs then head xs else loc "bye"


handleCmd ["PONG"] = do
    cl <- thisClient
    if pingsQueue cl == 0 then
        return [ProtocolError "Protocol violation"]
        else
        return [ModifyClient (\c -> c{pingsQueue = pingsQueue c - 1})]

handleCmd ("CMD" : params) =
    let c = concatMap B.words params in
        if not $ null c then
            h $ (upperCase . head $ c) : tail c
            else
            return []
    where
        h ["DELEGATE", n] = handleCmd ["DELEGATE", n]
        h c = return [Warning . B.concat . L.intersperse " " $ "Unknown cmd" : c]

handleCmd cmd = do
    (ci, irnc) <- ask
    if logonPassed (irnc `client` ci) then
        handleCmd_loggedin cmd
        else
        handleCmd_NotEntered cmd


handleCmd_loggedin ["INFO", asknick] = do
    (_, rnc) <- ask
    maybeClientId <- clientByNick asknick
    isAdminAsking <- liftM isAdministrator thisClient
    let noSuchClient = isNothing maybeClientId
    let clientId = fromJust maybeClientId
    let cl = rnc `client` fromJust maybeClientId
    let roomId = clientRoom rnc clientId
    let clRoom = room rnc roomId
    let roomMasterSign = if isMaster cl then "@" else ""
    let adminSign = if isAdministrator cl then "@" else ""
    let rInfo = if roomId /= lobbyId then B.concat [roomMasterSign, "room ", name clRoom] else adminSign `B.append` "lobby"
    let roomStatus = if isJust $ gameInfo clRoom then
            if teamsInGame cl > 0 then "(playing)" else "(spectating)"
            else
            ""
    let hostStr = if isAdminAsking then host cl else cutHost $ host cl
    if noSuchClient then
        return []
        else
        answerClient [
            "INFO",
            nick cl,
            B.concat ["[", hostStr, "]"],
            protoNumber2ver $ clientProto cl,
            B.concat ["[", rInfo, "]", roomStatus]
            ]


handleCmd_loggedin cmd = do
    (ci, rnc) <- ask
    if clientRoom rnc ci == lobbyId then
        handleCmd_lobby cmd
        else
        handleCmd_inRoom cmd
