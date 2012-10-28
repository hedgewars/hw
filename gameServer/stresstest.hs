{-# LANGUAGE CPP #-}

module Main where

import System.IO
import System.IO.Error
import Control.Concurrent
import Network
import Control.OldException
import Control.Monad
import System.Random

#if !defined(mingw32_HOST_OS)
import System.Posix
#endif

session 0 nick room = ["NICK", nick, "", "PROTO", "42", "", "PING", "", "CHAT", "lobby 1", "", "PONG", "", "CREATE_ROOM", room, "", "CHAT", "room 1", "", "QUIT", "creator", ""]
session 1 nick room = ["NICK", nick, "", "PROTO", "42", "", "LIST", "", "JOIN_ROOM", room, "", "PONG", "", "CHAT", "room 2", "", "PART", "", "CHAT", "lobby after part", "", "QUIT", "part-quit", ""]
session 2 nick room = ["NICK", nick, "", "PROTO", "42", "", "LIST", "", "JOIN_ROOM", room, "", "PONG", "", "CHAT", "room 2", "", "QUIT", "quit", ""]
session 3 nick room = ["NICK", nick, "", "PROTO", "42", "", "CHAT", "lobby 1", "", "CREATE_ROOM", room, "", "", "PONG", "CHAT", "room 1", "", "PART", "creator", "", "QUIT", "part-quit", ""]

emulateSession sock s = do
    mapM_ (\x -> hPutStrLn sock x >> hFlush sock >> randomRIO (100000::Int, 600000) >>= threadDelay) s
    hFlush sock
    threadDelay 225000

testing = Control.OldException.handle print $ do
    putStrLn "Start"
    sock <- connectTo "127.0.0.1" (PortNumber 46631)

    num1 <- randomRIO (100000::Int, 101000)
    num2 <- randomRIO (0::Int, 3)
    num3 <- randomRIO (0::Int, 1000)
    let nick1 = 'n' : show num1
    let room1 = 'r' : show num3
    emulateSession sock $ session num2 nick1 room1
    hClose sock
    putStrLn "Finish"

forks = forever $ do
    delays <- randomRIO (0::Int, 2)
    replicateM 200 $
        do
        delay <- randomRIO (delays * 20000::Int, delays * 20000 + 50000)
        threadDelay delay
        forkIO testing

main = withSocketsDo $ do
#if !defined(mingw32_HOST_OS)
    installHandler sigPIPE Ignore Nothing;
#endif
    forks
