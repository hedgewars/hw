{-
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 \-}

{-# LANGUAGE OverloadedStrings #-}
module HWProtoCore where

import Control.Monad.Reader
import Data.Maybe
import qualified Data.ByteString.Char8 as B
--------------------------------------
import CoreTypes
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
        -- "User quit: " is a special string parsed by frontend, do not localize.
        -- It denotes when the /quit command has been used with message parameter.
        -- "bye" is also a special string.
        msg = if not $ null xs then "User quit: " `B.append` (head xs) else "bye"


handleCmd ["PONG"] = do
    cl <- thisClient
    if pingsQueue cl == 0 then
        return [ProtocolError "Protocol violation"]
        else
        return [ModifyClient (\c -> c{pingsQueue = pingsQueue c - 1})]

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


handleCmd_loggedin ["CMD", parameters] = uncurry h $ extractParameters parameters
    where
        h "DELEGATE" n | not $ B.null n = handleCmd ["DELEGATE", n]
        h "SAVEROOM" n | not $ B.null n = handleCmd ["SAVEROOM", n]
        h "LOADROOM" n | not $ B.null n = handleCmd ["LOADROOM", n]
        h "SAVE" n | not $ B.null n = let (sn, ln) = B.break (== ' ') n in if B.null ln then return [] else handleCmd ["SAVE", sn, B.tail ln]
        h "DELETE" n | not $ B.null n = handleCmd ["DELETE", n]
        h "STATS" _ = handleCmd ["STATS"]
        h "PART" m | not $ B.null m = handleCmd ["PART", m]
                   | otherwise = handleCmd ["PART"]
        h "QUIT" m | not $ B.null m = handleCmd ["QUIT", m]
                   | otherwise = handleCmd ["QUIT"]
        h "RND" p = handleCmd ("RND" : B.words p)
        h "GLOBAL" p = serverAdminOnly $ do
            rnc <- liftM snd ask
            let chans = map (sendChan . client rnc) $ allClients rnc
            return [AnswerClients chans ["CHAT", "[global notice]", p]]
        h "WATCH" f = return [QueryReplay f]
        h "FIX" _ = handleCmd ["FIX"]
        h "UNFIX" _ = handleCmd ["UNFIX"]
        h "GREETING" msg | not $ B.null msg = handleCmd ["GREETING", msg]
        h "CALLVOTE" msg | B.null msg = handleCmd ["CALLVOTE"]
                         | otherwise = let (c, p) = extractParameters msg in
                                           if B.null p then handleCmd ["CALLVOTE", c] else handleCmd ["CALLVOTE", c, p]
        h "VOTE" msg | not $ B.null msg = handleCmd ["VOTE", upperCase msg]
                     | otherwise = handleCmd ["VOTE", ""]
        h "FORCE" msg | not $ B.null msg = handleCmd ["VOTE", upperCase msg, "FORCE"]
                      | otherwise = handleCmd ["VOTE", "", "FORCE"]
        h "VOTE" msg | not $ B.null msg = handleCmd ["VOTE", upperCase msg]
        h "FORCE" msg | not $ B.null msg = handleCmd ["VOTE", upperCase msg, "FORCE"]
        h "MAXTEAMS" n | not $ B.null n = handleCmd ["MAXTEAMS", n]
        h "INFO" n | not $ B.null n = handleCmd ["INFO", n]
        h "HELP" _ = handleCmd ["HELP"]
        h "RESTART_SERVER" "YES" = handleCmd ["RESTART_SERVER"]
        h "REGISTERED_ONLY" _ = serverAdminOnly $ do
            cl <- thisClient
            return
                [ModifyServerInfo(\s -> s{isRegisteredUsersOnly = not $ isRegisteredUsersOnly s})
                , AnswerClients [sendChan cl] ["CHAT", "[server]", "'Registered only' state toggled"]
                ]
        h "SUPER_POWER" _ = serverAdminOnly $ return [ModifyClient (\c -> c{hasSuperPower = True})]
        h c p = return [Warning $ B.concat [ loc "Unknown command:", " /", c, " ", p, "<br/>", loc "Say '/help' in chat for a list of commands" ]]


        extractParameters p = let (a, b) = B.break (== ' ') p in (upperCase a, B.dropWhile (== ' ') b)

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
    let rInfo = if roomId /= lobbyId then B.concat [adminSign, roomMasterSign, loc "room", " ", name clRoom] else adminSign `B.append` (loc "lobby")
    let roomStatus = if isJust $ gameInfo clRoom then
            if teamsInGame cl > 0 then (loc "(playing)") else (loc "(spectating)")
            else
            ""
    let hostStr = if isAdminAsking then host cl else B.empty
    if noSuchClient then
        answerClient [ "CHAT", "[server]", loc "Player is not online." ]
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
