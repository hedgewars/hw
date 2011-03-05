{-# LANGUAGE ScopedTypeVariables, OverloadedStrings #-}
module NetRoutines where

import Network.Socket
import Control.Concurrent.Chan
import qualified Control.Exception as Exception
import Data.Time
import Control.Monad
import Data.Unique
-----------------------------
import CoreTypes
import Utils
import RoomsAndClients

acceptLoop :: Socket -> Chan CoreMessage -> IO ()
acceptLoop servSock chan = forever $
    Exception.handle
        (\(_ :: Exception.IOException) -> putStrLn "exception on connect") $
        do
        (sock, sockAddr) <- Network.Socket.accept servSock

        clientHost <- sockAddr2String sockAddr

        currentTime <- getCurrentTime

        sendChan' <- newChan

        uid <- newUnique

        let newClient =
                (ClientInfo
                    uid
                    sendChan'
                    sock
                    clientHost
                    currentTime
                    ""
                    ""
                    False
                    0
                    lobbyId
                    0
                    False
                    False
                    False
                    Nothing
                    0
                    )

        writeChan chan $ Accept newClient
        return ()
