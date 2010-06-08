module ServerState
    (
    module RoomsAndClients,
    clientRoomA,
    ServerState(..),
    client's,
    allClientsS,
    roomClientsS
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

client's :: (ClientInfo -> a) -> StateT ServerState IO a
client's f = do
    (Just ci) <- gets clientIndex
    rnc <- gets roomsClients
    liftIO $ client'sM rnc f ci
    
allClientsS :: StateT ServerState IO [ClientInfo]
allClientsS = gets roomsClients >>= liftIO . clientsM

roomClientsS :: RoomIndex -> StateT ServerState IO [ClientInfo]
roomClientsS ri = do
    rnc <- gets roomsClients
    liftIO $ roomClientsM rnc ri
    