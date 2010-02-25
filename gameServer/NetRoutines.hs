{-# LANGUAGE ScopedTypeVariables #-}
module NetRoutines where

import Network
import Network.Socket
import System.IO
import Control.Concurrent
import Control.Concurrent.Chan
import Control.Concurrent.STM
import qualified Control.Exception as Exception
import Data.Time
-----------------------------
import CoreTypes
import ClientIO
import Utils

acceptLoop :: Socket -> Chan CoreMessage -> Int -> IO ()
acceptLoop servSock coreChan clientCounter = do
    Exception.handle
        (\(_ :: Exception.IOException) -> putStrLn "exception on connect") $
        do
        (socket, sockAddr) <- Network.Socket.accept servSock

        cHandle <- socketToHandle socket ReadWriteMode
        hSetBuffering cHandle LineBuffering
        clientHost <- sockAddr2String sockAddr

        currentTime <- getCurrentTime
        
        sendChan <- newChan

        let newClient =
                (ClientInfo
                    nextID
                    sendChan
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

        writeChan coreChan $ Accept newClient

        forkIO $ clientRecvLoop cHandle coreChan nextID
        forkIO $ clientSendLoop cHandle coreChan sendChan nextID
        return ()

    acceptLoop servSock coreChan nextID
    where
        nextID = clientCounter + 1
