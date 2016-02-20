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
import Data.Either
-----------------------------
import CoreTypes
import Utils


acceptLoop :: Socket -> Chan CoreMessage -> IO ()
acceptLoop servSock chan = E.bracket openHandle closeHandle (forever . f)
    where
    f ch = E.try (Network.Socket.accept servSock) >>= \v -> case v of
      Left (e :: E.IOException) -> return ()
      Right (sock, sockAddr) -> do
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
                    False
                    False
                    Nothing
                    Nothing
                    newEventsInfo
                    newEventsInfo
                    newEventsInfo
                    0
                    []
                    []
                    )

        writeChan chan $ Accept newClient
        return ()
