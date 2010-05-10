module ServerState
    (
    module RoomsAndClients,
    clientRoomA,
    ServerState(..),
    clients
    ) where

import Control.Monad.State
----------------------
import RoomsAndClients
import CoreTypes

data ServerState = ServerState {
        clientIndex :: Maybe ClientIndex,
        serverInfo :: ServerInfo,
        roomsClients :: MRnC
    }


clientRoomA :: StateT ServerState IO RoomIndex
clientRoomA = do
    (Just ci) <- gets clientIndex
    rnc <- gets roomsClients
    liftIO $ clientRoomM rnc ci

clients :: (ClientInfo -> a) -> StateT ServerState IO a
clients f = do
    (Just ci) <- gets clientIndex
    rnc <- gets roomsClients
    liftIO $ clientsM rnc f ci
    