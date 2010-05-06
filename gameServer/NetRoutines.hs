{-# LANGUAGE ScopedTypeVariables #-}
module NetRoutines where

import Network.Socket
import System.IO
import Control.Concurrent.Chan
import qualified Control.Exception as Exception
import Data.Time
import Control.Monad
-----------------------------
import CoreTypes
import Utils

acceptLoop :: Socket -> Chan CoreMessage -> IO ()
acceptLoop servSock chan = forever $ do
    Exception.handle
        (\(_ :: Exception.IOException) -> putStrLn "exception on connect") $
        do
        (sock, sockAddr) <- Network.Socket.accept servSock

        cHandle <- socketToHandle sock ReadWriteMode
        hSetBuffering cHandle LineBuffering
        clientHost <- sockAddr2String sockAddr

        currentTime <- getCurrentTime

        sendChan' <- newChan

        let newClient =
                (ClientInfo
                    sendChan'
                    cHandle
                    clientHost
                    currentTime
                    ""
                    ""
                    False
                    0
                    0
                    0
                    False
                    False
                    False
                    undefined
                    undefined
                    )

        writeChan chan $ Accept newClient
        return ()
