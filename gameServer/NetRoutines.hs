{-# LANGUAGE ScopedTypeVariables, OverloadedStrings #-}
module NetRoutines where

import Network.Socket
import Control.Concurrent.Chan
import Data.Time
import Control.Monad
import Data.Unique
import qualified Codec.Binary.Base64 as Base64
import qualified Data.ByteString as BW
import qualified Data.ByteString.Char8 as B
import qualified Control.Exception as E
import System.Entropy
-----------------------------
import CoreTypes
import Utils


acceptLoop :: Socket -> Chan CoreMessage -> IO ()
acceptLoop servSock chan = E.bracket openHandle closeHandle f
    where
    f ch = forever $
        do
        (sock, sockAddr) <- Network.Socket.accept servSock

        clientHost <- sockAddr2String sockAddr

        currentTime <- getCurrentTime

        sendChan' <- newChan

        uid <- newUnique
        salt <- liftM (B.pack . Base64.encode . BW.unpack) $ hGetEntropy ch 18

        let newClient =
                (ClientInfo
                    uid
                    sendChan'
                    sock
                    clientHost
                    currentTime
                    ""
                    ""
                    salt
                    False
                    False
                    0
                    0
                    False
                    False
                    False
                    False
                    False
                    False
                    False
                    False
                    Nothing
                    Nothing
                    newEventsInfo
                    newEventsInfo
                    newEventsInfo
                    0
                    )

        writeChan chan $ Accept newClient
        return ()
