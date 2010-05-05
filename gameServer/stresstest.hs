{-# LANGUAGE CPP #-}

module Main where

import IO
import System.IO
import Control.Concurrent
import Network
import Control.OldException
import Control.Monad
import System.Random

#if !defined(mingw32_HOST_OS)
import System.Posix
#endif

session1 nick room = ["NICK", nick, "", "PROTO", "32", "", "PING", "", "CHAT", "lobby 1", "", "CREATE_ROOM", room, "", "CHAT", "room 1", "", "QUIT", "creator", ""]
session2 nick room = ["NICK", nick, "", "PROTO", "32", "", "LIST", "", "JOIN_ROOM", room, "", "CHAT", "room 2", "", "PART", "", "CHAT", "lobby after part", "", "QUIT", "part-quit", ""]
session3 nick room = ["NICK", nick, "", "PROTO", "32", "", "LIST", "", "JOIN_ROON", room, "", "CHAT", "room 2", "", "QUIT", "quit", ""]

emulateSession sock s = do
    mapM_ (\x -> hPutStrLn sock x >> hFlush sock >> randomRIO (300000::Int, 590000) >>= threadDelay) s
    hFlush sock
    threadDelay 225000

testing = Control.OldException.handle print $ do
    putStrLn "Start"
    sock <- connectTo "127.0.0.1" (PortNumber 46631)

    num1 <- randomRIO (70000::Int, 70100)
    num2 <- randomRIO (0::Int, 2)
    num3 <- randomRIO (0::Int, 5)
    let nick1 = 'n' : show num1
    let room1 = 'r' : show num2
    case num2 of 
        0 -> emulateSession sock $ session1 nick1 room1
        1 -> emulateSession sock $ session2 nick1 room1
        2 -> emulateSession sock $ session3 nick1 room1
    hClose sock
    putStrLn "Finish"

forks = forever $ do
    delay <- randomRIO (300000::Int, 590000)
    threadDelay delay
    forkIO testing

main = withSocketsDo $ do
#if !defined(mingw32_HOST_OS)
    installHandler sigPIPE Ignore Nothing;
#endif
    forks
