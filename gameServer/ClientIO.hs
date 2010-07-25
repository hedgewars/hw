{-# LANGUAGE ScopedTypeVariables, OverloadedStrings #-}
module ClientIO where

import qualified Control.Exception as Exception
import Control.Concurrent.Chan
import Control.Concurrent
import Control.Monad
import System.IO
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
bs2Packets buf = unfoldrE extractPackets buf
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
--            putStrLn $ show sock ++ " got smth: " ++ (show $ B.length recvBS)
            unless (B.null recvBS) $ do
                let (packets, newrecvBuf) = bs2Packets $ B.append recvBuf recvBS
                forM_ packets sendPacket
                recieveWithBufferLoop newrecvBuf

        sendPacket packet = writeChan chan $ ClientMessage (ci, packet)


clientRecvLoop :: Socket -> Chan CoreMessage -> ClientIndex -> IO ()
clientRecvLoop s chan ci = do
    msg <- (listenLoop s chan ci >> return "Connection closed") `catch` (return . B.pack . show)
    clientOff msg
    where 
        clientOff msg = mapM_ (writeChan chan) [ClientMessage (ci, ["QUIT", msg]), Remove ci]



clientSendLoop :: Socket -> Chan CoreMessage -> Chan [B.ByteString] -> ClientIndex -> IO()
clientSendLoop s coreChan chan ci = do
    answer <- readChan chan
    doClose <- Exception.handle
        (\(e :: Exception.IOException) -> if isQuit answer then return True else sendQuit e >> return True) $ do
            sendAll s $ (B.unlines answer) `B.append` (B.singleton '\n')
            return $ isQuit answer

    if doClose then
        Exception.handle (\(_ :: Exception.IOException) -> putStrLn "error on sClose") $ sClose s
        else
        clientSendLoop s coreChan chan ci

    where
        sendQuit e = writeChan coreChan $ ClientMessage (ci, ["QUIT", B.pack $ show e])
        isQuit ("BYE":xs) = True
        isQuit _ = False
