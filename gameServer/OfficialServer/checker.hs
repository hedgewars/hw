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
import Network.Socket hiding (recv)
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

data Message = Packet [B.ByteString]
             | CheckFailed B.ByteString
             | CheckSuccess [B.ByteString]
    deriving Show

serverAddress = "netserver.hedgewars.org"
protocolNumber = "43"

getLines :: Handle -> IO [String]
getLines h = g
    where
        g = do
            l <- liftM Just (hGetLine h) `Exception.catch` (\(_ :: Exception.IOException) -> return Nothing)
            if isNothing l then
                return []
                else
                do
                lst <- g
                return $ fromJust l : lst


engineListener :: Chan Message -> Handle -> IO ()
engineListener coreChan h = do
    output <- getLines h
    debugM "Engine" $ show output
    if isNothing $ L.find start output then
        writeChan coreChan $ CheckFailed "No stats msg"
        else
        writeChan coreChan $ CheckSuccess []
    where
        start = flip L.elem ["WINNERS", "DRAW"]


checkReplay :: Chan Message -> [B.ByteString] -> IO ()
checkReplay coreChan msgs = do
    tempDir <- getTemporaryDirectory
    (fileName, h) <- openBinaryTempFile tempDir "checker-demo"
    B.hPut h . BW.pack . concat . map (fromJust . Base64.decode . B.unpack) $ msgs
    hFlush h
    hClose h

    (_, Just hOut, _, _) <- createProcess (proc "/usr/home/unC0Rr/Sources/Hedgewars/Releases/0.9.18/bin/hwengine"
                ["/usr/home/unC0Rr/.hedgewars"
                , "/usr/home/unC0Rr/Sources/Hedgewars/Releases/0.9.18/share/hedgewars/Data"
                , fileName
                , "--set-audio"
                , "0"
                , "0"
                , "0"
                ])
            {std_out = CreatePipe}
    hSetBuffering hOut LineBuffering
    void $ forkIO $ engineListener coreChan hOut


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


session :: B.ByteString -> B.ByteString -> Socket -> IO ()
session l p s = do
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
        answer ["READY"]
    onPacket _ ["PING"] = answer ["PONG"]
    onPacket chan ("REPLAY":msgs) = do
        checkReplay chan msgs
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
    updateGlobalLogger "Network" (setLevel DEBUG)
    updateGlobalLogger "Check" (setLevel DEBUG)
    updateGlobalLogger "Engine" (setLevel DEBUG)

    Right (login, password) <- runErrorT $ do
        d <- liftIO $ getHomeDirectory
        conf <- join . liftIO . CF.readfile CF.emptyCP $ d ++ "/.hedgewars/hedgewars.ini"
        l <- CF.get conf "net" "nick"
        p <- CF.get conf "net" "passwordhash"
        return (B.pack l, B.pack p)


    Exception.bracket
        setupConnection
        (\s -> noticeM "Core" "Shutting down" >> sClose s)
        (session login password)
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
