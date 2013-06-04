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
import HWProtoChecker
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

handleCmd ["CMD", parameters] = do
        let (cmd, plist) = B.break (== ' ') parameters
        let param = B.dropWhile (== ' ') plist
        h (upperCase cmd) param
    where
        h "DELEGATE" n | not $ B.null n = handleCmd ["DELEGATE", n]
        h "STATS" _ = handleCmd ["STATS"]
        h "PART" m | not $ B.null m = handleCmd ["PART", m]
                   | otherwise = handleCmd ["PART"]
        h "QUIT" m | not $ B.null m = handleCmd ["QUIT", m]
                   | otherwise = handleCmd ["QUIT"]
        h "RND" p = handleCmd ("RND" : B.words p)
        h "GLOBAL" p = do
            cl <- thisClient
            rnc <- liftM snd ask
            let chans = map (sendChan . client rnc) $ allClients rnc
            return [AnswerClients chans ["CHAT", "[global notice]", p] | isAdministrator cl]
        h c p = return [Warning $ B.concat ["Unknown cmd: /", c, p]]

handleCmd cmd = do
    (ci, irnc) <- ask
    let cl = irnc `client` ci
    if logonPassed cl then
        if isChecker cl then
            handleCmd_checker cmd
            else
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
    let roomMasterSign = if isMaster cl then "+" else ""
    let adminSign = if isAdministrator cl then "@" else ""
    let rInfo = if roomId /= lobbyId then B.concat [adminSign, roomMasterSign, "room ", name clRoom] else adminSign `B.append` "lobby"
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
