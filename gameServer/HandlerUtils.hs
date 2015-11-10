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

module HandlerUtils where

import Control.Monad.Reader
import qualified Data.ByteString.Char8 as B
import Data.List

import RoomsAndClients
import CoreTypes


type CmdHandler = [B.ByteString] -> Reader (ClientIndex, IRnC) [Action]

thisClient :: Reader (ClientIndex, IRnC) ClientInfo
thisClient = do
    (ci, rnc) <- ask
    return $ rnc `client` ci

thisRoom :: Reader (ClientIndex, IRnC) RoomInfo
thisRoom = do
    (ci, rnc) <- ask
    let ri = clientRoom rnc ci
    return $ rnc `room` ri

clientNick :: Reader (ClientIndex, IRnC) B.ByteString
clientNick = liftM nick thisClient

roomOthersChans :: Reader (ClientIndex, IRnC) [ClientChan]
roomOthersChans = do
    (ci, rnc) <- ask
    let ri = clientRoom rnc ci
    return $ map (sendChan . client rnc) $ filter (/= ci) (roomClients rnc ri)

roomSameClanChans :: Reader (ClientIndex, IRnC) [ClientChan]
roomSameClanChans = do
    (ci, rnc) <- ask
    let ri = clientRoom rnc ci
    let otherRoomClients = map (client rnc) . filter (/= ci) $ roomClients rnc ri
    let cl = rnc `client` ci
    let sameClanClients = Prelude.filter (\c -> clientClan c == clientClan cl) otherRoomClients
    return $ map sendChan sameClanClients

roomClientsChans :: Reader (ClientIndex, IRnC) [ClientChan]
roomClientsChans = do
    (ci, rnc) <- ask
    let ri = clientRoom rnc ci
    return $ map (sendChan . client rnc) (roomClients rnc ri)

thisClientChans :: Reader (ClientIndex, IRnC) [ClientChan]
thisClientChans = do
    (ci, rnc) <- ask
    return [sendChan (rnc `client` ci)]

sameProtoChans :: Reader (ClientIndex, IRnC) [ClientChan]
sameProtoChans = do
    (ci, rnc) <- ask
    let p = clientProto (rnc `client` ci)
    return . map sendChan . filter (\c -> clientProto c == p) . map (client rnc) $ allClients rnc

answerClient :: [B.ByteString] -> Reader (ClientIndex, IRnC) [Action]
answerClient msg = liftM ((: []) . flip AnswerClients msg) thisClientChans

allRoomInfos :: Reader (a, IRnC) [RoomInfo]
allRoomInfos = liftM ((\irnc -> map (room irnc) $ allRooms irnc) . snd) ask

clientByNick :: B.ByteString -> Reader (ClientIndex, IRnC) (Maybe ClientIndex)
clientByNick n = do
    (_, rnc) <- ask
    let allClientIDs = allClients rnc
    return $ find (\clId -> let cl = client rnc clId in n == nick cl && not (isChecker cl)) allClientIDs


roomAdminOnly :: Reader (ClientIndex, IRnC) [Action] -> Reader (ClientIndex, IRnC) [Action]
roomAdminOnly h = thisClient >>= \cl -> if isMaster cl then h else return []


serverAdminOnly :: Reader (ClientIndex, IRnC) [Action] -> Reader (ClientIndex, IRnC) [Action]
serverAdminOnly h = thisClient >>= \cl -> if isAdministrator cl then h else return []
