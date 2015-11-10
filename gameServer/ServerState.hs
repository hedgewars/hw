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

module ServerState
    (
    module RoomsAndClients,
    module JoinsMonitor,
    clientRoomA,
    ServerState(..),
    client's,
    allClientsS,
    allRoomsS,
    roomClientsS,
    sameProtoClientsS,
    io
    ) where

import Control.Monad.State.Strict
import Data.Set as Set(Set)
import Data.Word
----------------------
import RoomsAndClients
import CoreTypes
import JoinsMonitor

data ServerState = ServerState {
        clientIndex :: !(Maybe ClientIndex),
        serverInfo :: !ServerInfo,
        removedClients :: !(Set.Set ClientIndex),
        roomsClients :: !MRnC,
        joinsMonitor :: !JoinsMonitor
    }


clientRoomA :: StateT ServerState IO RoomIndex
clientRoomA = do
    (Just ci) <- gets clientIndex
    rnc <- gets roomsClients
    io $ clientRoomM rnc ci

client's :: (ClientInfo -> a) -> StateT ServerState IO a
client's f = do
    (Just ci) <- gets clientIndex
    rnc <- gets roomsClients
    io $ client'sM rnc f ci

allClientsS :: StateT ServerState IO [ClientInfo]
allClientsS = gets roomsClients >>= liftIO . clientsM

allRoomsS :: StateT ServerState IO [RoomInfo]
allRoomsS = gets roomsClients >>= liftIO . roomsM

roomClientsS :: RoomIndex -> StateT ServerState IO [ClientInfo]
roomClientsS ri = do
    rnc <- gets roomsClients
    io $ roomClientsM rnc ri

sameProtoClientsS :: Word16 -> StateT ServerState IO [ClientInfo]
sameProtoClientsS p = liftM f allClientsS
    where
        f = filter (\c -> clientProto c == p)

io :: IO a -> StateT ServerState IO a
io = liftIO
