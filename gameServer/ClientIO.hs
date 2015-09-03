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

{-# LANGUAGE ScopedTypeVariables, OverloadedStrings, Rank2Types #-}
module ClientIO where

import qualified Control.Exception as Exception
import Control.Monad.State
import Control.Concurrent.Chan
import Control.Concurrent
import Network
import Network.Socket.ByteString
import qualified Data.ByteString.Char8 as B
----------------
import CoreTypes
import RoomsAndClients


pDelim :: B.ByteString
pDelim = "\n\n"

bs2Packets :: B.ByteString -> ([[B.ByteString]], B.ByteString)
bs2Packets = runState takePacks

takePacks :: State B.ByteString [[B.ByteString]]
takePacks
  = do modify (until (not . B.isPrefixOf pDelim) (B.drop 2))
       packet <- state $ B.breakSubstring pDelim
       buf <- get
       if B.null buf then put packet >> return [] else
        if B.null packet then  return [] else
         do packets <- takePacks
            return (B.splitWith (== '\n') packet : packets)

listenLoop :: Socket -> Chan CoreMessage -> ClientIndex -> IO ()
listenLoop sock chan ci = receiveWithBufferLoop B.empty
    where
        receiveWithBufferLoop recvBuf = do
            recvBS <- recv sock 4096
            unless (B.null recvBS) $ do
                let (packets, newrecvBuf) = bs2Packets $ B.append recvBuf recvBS
                forM_ packets sendPacket
                when (B.length newrecvBuf > 128 * 1024) $ sendPacket ["QUIT", "Protocol violation"]
                receiveWithBufferLoop $ B.copy newrecvBuf

        sendPacket packet = writeChan chan $ ClientMessage (ci, packet)

clientRecvLoop :: Socket -> Chan CoreMessage -> Chan [B.ByteString] -> ClientIndex -> (forall a. IO a -> IO a) -> IO ()
clientRecvLoop s chan clChan ci restore =
    (myThreadId >>=
      (\t -> (restore $ forkIO (clientSendLoop s t clChan ci) >>
        listenLoop s chan ci >> return "Connection closed")
        `Exception.catch` (\(e :: ShutdownThreadException) -> return . B.pack . show $ e)
        `Exception.catch` (\(e :: Exception.IOException) -> return . B.pack . show $ e)
        `Exception.catch` (\(e :: Exception.SomeException) -> return . B.pack . show $ e)
      )
        >>= clientOff) `Exception.finally` remove
    where
        clientOff msg = writeChan chan $ ClientMessage (ci, ["QUIT", msg])
        remove = do
            clientOff "Client is in some weird state"
            writeChan chan $ Remove ci



clientSendLoop :: Socket -> ThreadId -> Chan [B.ByteString] -> ClientIndex -> IO ()
clientSendLoop s tId chan ci = do
    answer <- readChan chan

    when (isQuit answer) $
        killReciever . B.unpack $ quitMessage answer

    Exception.handle
        (\(e :: Exception.SomeException) -> unless (isQuit answer) . killReciever $ show e) $
            sendAll s $ B.unlines answer `B.snoc` '\n'

    if isQuit answer then
        sClose s
        else
        clientSendLoop s tId chan ci

    where
        killReciever = Exception.throwTo tId . ShutdownThreadException
        quitMessage ["BYE"] = "bye"
        quitMessage ("BYE":msg:_) = msg
        quitMessage _ = error "quitMessage"
        isQuit ("BYE":_) = True
        isQuit _ = False
