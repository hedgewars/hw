{-# LANGUAGE CPP #-}

module Main where

import System.IO
import System.IO.Error
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
    io $ hGetPacket h []
    where
    hGetPacket h buf = do
        l <- hGetLine h
        if not $ null l then hGetPacket h (buf ++ [l]) else return buf

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
    n <- io $ randomRIO (100000::Int, 100100)
    waitPacket "CONNECTED"
    sendPacket ["NICK", "test" ++ show n]
    waitPacket "NICK"
    sendPacket ["PROTO", "31"]
    waitPacket "PROTO"
    b <- waitPacket "LOBBY:JOINED"
    --io $ print b
    sendPacket ["QUIT", "BYE"]
    return ()

testing = Control.OldException.handle print $ do
    putStr "+"
    sock <- connectTo "127.0.0.1" (PortNumber 46631)
    evalStateT emulateSession sock
    --hClose sock
    putStr "-"
    hFlush stdout

forks = forM_ [1..100] $ const $ do
    delay <- randomRIO (10000::Int, 30000)
    threadDelay delay
    forkIO testing

main = withSocketsDo $ do
#if !defined(mingw32_HOST_OS)
    installHandler sigPIPE Ignore Nothing;
#endif
    forks
