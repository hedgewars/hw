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

{-# LANGUAGE CPP, ScopedTypeVariables, OverloadedStrings #-}
module Main where

import qualified Control.Exception as Exception
import System.IO
import System.Log.Logger
import qualified Data.ConfigFile as CF
import Control.Monad.Error
import System.Directory
import Control.Monad.State
import Control.Concurrent.Chan
import Control.Concurrent
import Network
import Network.BSD
import Network.Socket hiding (recv, sClose)
import Network.Socket.ByteString
import qualified Data.ByteString.Char8 as B
import qualified Data.ByteString as BW
import qualified Codec.Binary.Base64 as Base64
import System.Process
import Data.Maybe
import qualified Data.List as L
#if !defined(mingw32_HOST_OS)
import System.Posix
#endif

readInt_ :: (Num a) => B.ByteString -> a
readInt_ str =
  case B.readInt str of
       Just (i, t) | B.null t -> fromIntegral i
       _                      -> 0

data Message = Packet [B.ByteString]
             | CheckFailed B.ByteString
             | CheckSuccess [B.ByteString]
    deriving Show

serverAddress = "netserver.hedgewars.org"
protocolNumber = "49"

getLines :: Handle -> IO [B.ByteString]
getLines h = g
    where
        g = do
            l <- liftM Just (B.hGetLine h) `Exception.catch` (\(_ :: Exception.IOException) -> return Nothing)
            if isNothing l then
                return []
                else
                do
                lst <- g
                return $ fromJust l : lst


engineListener :: Chan Message -> Handle -> String -> IO ()
engineListener coreChan h fileName = do
    stats <- liftM (ps . L.dropWhile (not . start)) $ getLines h
    debugM "Engine" $ show stats
    if null stats then
        writeChan coreChan $ CheckFailed "No stats msg"
        else
        writeChan coreChan $ CheckSuccess stats

    removeFile fileName
    where
        start = flip L.elem ["WINNERS", "DRAW"]
        ps ("DRAW" : bs) = "DRAW" : ps bs
        ps ("WINNERS" : n : bs) = let c = readInt_ n in "WINNERS" : n : take c bs ++ (ps $ drop c bs)
        ps ("ACHIEVEMENT" : typ : teamname : location : value : bs) =
            "ACHIEVEMENT" : typ : teamname : location : value : ps bs
        ps _ = []

checkReplay :: String -> String -> String -> Chan Message -> [B.ByteString] -> IO ()
checkReplay home exe prefix coreChan msgs = do
    tempDir <- getTemporaryDirectory
    (fileName, h) <- openBinaryTempFile tempDir "checker-demo"
    B.hPut h . BW.pack . concat . map (fromMaybe [] . Base64.decode . B.unpack) $ msgs
    hFlush h
    hClose h

    (_, _, Just hOut, _) <- createProcess (proc exe
                [fileName
                , "--user-prefix", home
                , "--prefix", prefix
                , "--nomusic"
                , "--nosound"
                , "--stats-only"
                ])
            {std_err = CreatePipe}
    hSetBuffering hOut LineBuffering
    void $ forkIO $ engineListener coreChan hOut fileName


takePacks :: State B.ByteString [[B.ByteString]]
takePacks = do
    modify (until (not . B.isPrefixOf pDelim) (B.drop 2))
    packet <- state $ B.breakSubstring pDelim
    buf <- get
    if B.null buf then put packet >> return [] else
        if B.null packet then return [] else do
            packets <- takePacks
            return (B.splitWith (== '\n') packet : packets)
    where
    pDelim = "\n\n"


recvLoop :: Socket -> Chan Message -> IO ()
recvLoop s chan =
        ((receiveWithBufferLoop B.empty >> return "Connection closed")
            `Exception.catch` (\(e :: Exception.SomeException) -> return . B.pack . show $ e)
        )
        >>= disconnected
    where
        disconnected msg = writeChan chan $ Packet ["BYE", msg]
        receiveWithBufferLoop recvBuf = do
            recvBS <- recv s 4096
            unless (B.null recvBS) $ do
                let (packets, newrecvBuf) = runState takePacks $ B.append recvBuf recvBS
                forM_ packets sendPacket
                receiveWithBufferLoop $ B.copy newrecvBuf

        sendPacket packet = writeChan chan $ Packet packet


session :: B.ByteString -> B.ByteString -> String -> String -> String -> Socket -> IO ()
session l p home exe prefix s = do
    noticeM "Core" "Connected"
    coreChan <- newChan
    forkIO $ recvLoop s coreChan
    forever $ do
        p <- readChan coreChan
        case p of
            Packet p -> do
                debugM "Network" $ "Recv: " ++ show p
                onPacket coreChan p
            CheckFailed msg -> do
                warningM "Check" "Check failed"
                answer ["CHECKED", "FAIL", msg]
                answer ["READY"]
            CheckSuccess msgs -> do
                warningM "Check" "Check succeeded"
                answer ("CHECKED" : "OK" : msgs)
                answer ["READY"]
    where
    answer :: [B.ByteString] -> IO ()
    answer p = do
        debugM "Network" $ "Send: " ++ show p
        sendAll s $ B.unlines p `B.snoc` '\n'
    onPacket :: Chan Message -> [B.ByteString] -> IO ()
    onPacket _ ("CONNECTED":_) = do
        answer ["CHECKER", protocolNumber, l, p]
    onPacket _ ["PING"] = answer ["PONG"]
    onPacket _ ["LOGONPASSED"] = answer ["READY"]
    onPacket chan ("REPLAY":msgs) = do
        checkReplay home exe prefix chan msgs
        warningM "Check" "Started check"
    onPacket _ ("BYE" : xs) = error $ show xs
    onPacket _ _ = return ()


main :: IO ()
main = withSocketsDo $ do
#if !defined(mingw32_HOST_OS)
    installHandler sigPIPE Ignore Nothing
    installHandler sigCHLD Ignore Nothing
#endif

    updateGlobalLogger "Core" (setLevel DEBUG)
    updateGlobalLogger "Network" (setLevel WARNING)
    updateGlobalLogger "Check" (setLevel DEBUG)
    updateGlobalLogger "Engine" (setLevel DEBUG)

    d <- getHomeDirectory
    Right (login, password) <- runErrorT $ do
        conf <- join . liftIO . CF.readfile CF.emptyCP $ d ++ "/.hedgewars/settings.ini"
        l <- CF.get conf "net" "nick"
        p <- CF.get conf "net" "passwordhash"
        return (B.pack l, B.pack p)

    Right (exeFullname, dataPrefix) <- runErrorT $ do
        conf <- join . liftIO . CF.readfile CF.emptyCP $ d ++ "/.hedgewars/checker.ini"
        l <- CF.get conf "engine" "exe"
        p <- CF.get conf "engine" "prefix"
        return (l, p)


    Exception.bracket
        setupConnection
        (\s -> noticeM "Core" "Shutting down" >> sClose s)
        (session login password (d ++ "/.hedgewars") exeFullname dataPrefix)
    where
        setupConnection = do
            noticeM "Core" "Connecting to the server..."

            proto <- getProtocolNumber "tcp"
            let hints = defaultHints { addrFlags = [AI_ADDRCONFIG, AI_CANONNAME] }
            (addr:_) <- getAddrInfo (Just hints) (Just serverAddress) Nothing
            let (SockAddrInet _ host) = addrAddress addr
            sock <- socket AF_INET Stream proto
            connect sock (SockAddrInet 46631 host)
            return sock
