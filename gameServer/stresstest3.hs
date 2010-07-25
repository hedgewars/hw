{-# LANGUAGE CPP #-}

module Main where

import IO
import System.IO
import Control.Concurrent
import Network
import Control.OldException
import Control.Monad
import System.Random
import Control.Monad.State
import Data.List

#if !defined(mingw32_HOST_OS)
import System.Posix
#endif

type SState = Handle
io = liftIO

readPacket :: StateT SState IO [String]
readPacket = do
    h <- get
    p <- io $ hGetPacket h []
    return p
    where
    hGetPacket h buf = do
        l <- hGetLine h
        if (not $ null l) then hGetPacket h (buf ++ [l]) else return buf

waitPacket :: String -> StateT SState IO Bool
waitPacket s = do
    p <- readPacket
    return $ head p == s

sendPacket :: [String] -> StateT SState IO ()
sendPacket s = do
    h <- get
    io $ do
        mapM_ (hPutStrLn h) s
        hPutStrLn h ""
        hFlush h

emulateSession :: StateT SState IO ()
emulateSession = do
    n <- io $ randomRIO (100000::Int, 100000)
    waitPacket "CONNECTED"
    sendPacket ["NICK", "test" ++ (show n)]
    waitPacket "NICK"
    sendPacket ["PROTO", "31"]
    waitPacket "PROTO"
    b <- waitPacket "LOBBY:JOINED"
    --io $ print b
    return ()

testing = Control.OldException.handle print $ do
    putStr "+"
    sock <- connectTo "127.0.0.1" (PortNumber 46631)
    evalStateT emulateSession sock
    --hClose sock
    putStr "-"
    hFlush stdout

forks = forever $ do
    delay <- randomRIO (20000::Int, 40000)
    threadDelay delay
    forkIO testing

main = withSocketsDo $ do
#if !defined(mingw32_HOST_OS)
    installHandler sigPIPE Ignore Nothing;
#endif
    forks
