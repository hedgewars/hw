{-# LANGUAGE ScopedTypeVariables, OverloadedStrings #-}
module ClientIO where

import qualified Control.Exception as Exception
import Control.Concurrent.Chan
import Control.Concurrent
import Control.Monad
import Network
import Network.Socket.ByteString
import qualified Data.ByteString.Char8 as B
----------------
import CoreTypes
import RoomsAndClients
import Utils


pDelim :: B.ByteString
pDelim = B.pack "\n\n"

bs2Packets :: B.ByteString -> ([[B.ByteString]], B.ByteString)
bs2Packets = unfoldrE extractPackets
    where
    extractPackets :: B.ByteString -> Either B.ByteString ([B.ByteString], B.ByteString)
    extractPackets buf =
        let buf' = until (not . B.isPrefixOf pDelim) (B.drop 2) buf in
            let (bsPacket, bufTail) = B.breakSubstring pDelim buf' in
                if B.null bufTail then
                    Left bsPacket
                    else
                    if B.null bsPacket then 
                        Left bufTail
                        else
                        Right (B.splitWith (== '\n') bsPacket, bufTail)


listenLoop :: Socket -> Chan CoreMessage -> ClientIndex -> IO ()
listenLoop sock chan ci = recieveWithBufferLoop B.empty
    where
        recieveWithBufferLoop recvBuf = do
            recvBS <- recv sock 4096
            unless (B.null recvBS) $ do
                let (packets, newrecvBuf) = bs2Packets $ B.append recvBuf recvBS
                forM_ packets sendPacket
                recieveWithBufferLoop newrecvBuf

        sendPacket packet = writeChan chan $ ClientMessage (ci, packet)

clientRecvLoop :: Socket -> Chan CoreMessage -> ClientIndex -> IO ()
clientRecvLoop s chan ci = Exception.block $
        ((Exception.unblock $ listenLoop s chan ci >> return "Connection closed") `catch` (return . B.pack . show) >>= clientOff)
    `Exception.finally`
        remove
    where
        clientOff msg = writeChan chan $ ClientMessage (ci, ["QUIT", msg])
        remove = writeChan chan $ Remove ci



clientSendLoop :: Socket -> ThreadId -> Chan CoreMessage -> Chan [B.ByteString] -> ClientIndex -> IO ()
clientSendLoop s tId cChan chan ci = do
    answer <- readChan chan
    Exception.handle
        (\(e :: Exception.IOException) -> unless (isQuit answer) . killReciever $ show e) $
            sendAll s $ B.unlines answer `B.append` B.singleton '\n'

    if isQuit answer then
        do
        Exception.handle (\(_ :: Exception.IOException) -> putStrLn "error on sClose") $ sClose s
        killReciever "Connection closed"
        else
        clientSendLoop s tId cChan chan ci

    where
        killReciever = Exception.throwTo tId . ShutdownThreadException
        isQuit ("BYE":_) = True
        isQuit _ = False
