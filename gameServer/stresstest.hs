{-# LANGUAGE CPP #-}

module Main where

import IO
import System.IO
import Control.Concurrent
import Network
import Control.Exception
import Control.Monad
import System.Random

#if !defined(mingw32_HOST_OS)
import System.Posix
#endif

session1 nick room = ["NICK", nick, "", "PROTO", "24", "", "CHAT", "lobby 1", "", "CREATE", room, "", "CHAT", "room 1", "", "QUIT", "bye-bye", ""]
session2 nick room = ["NICK", nick, "", "PROTO", "24", "", "LIST", "", "JOIN", room, "", "CHAT", "room 2", "", "PART", "", "CHAT", "lobby after part", "", "QUIT", "bye-bye", ""]
session3 nick room = ["NICK", nick, "", "PROTO", "24", "", "LIST", "", "JOIN", room, "", "CHAT", "room 2", "", "QUIT", "bye-bye", ""]

emulateSession sock s = do
    mapM_ (\x -> hPutStrLn sock x >> hFlush sock >> randomRIO (50000::Int, 90000) >>= threadDelay) s
    hFlush sock
    threadDelay 225000

testing = Control.Exception.handle print $ do
    putStrLn "Start"
    sock <- connectTo "127.0.0.1" (PortNumber 46631)

    num1 <- randomRIO (70000::Int, 70100)
    num2 <- randomRIO (0::Int, 2)
    num3 <- randomRIO (0::Int, 5)
    let nick1 = show num1
    let room1 = show num2
    case num2 of 
        0 -> emulateSession sock $ session1 nick1 room1
        1 -> emulateSession sock $ session2 nick1 room1
        2 -> emulateSession sock $ session3 nick1 room1
    hClose sock
    putStrLn "Finish"

forks = forever $ do
    delay <- randomRIO (10000::Int, 19000)
    threadDelay delay
    forkIO testing

main = withSocketsDo $ do
#if !defined(mingw32_HOST_OS)
    installHandler sigPIPE Ignore Nothing;
#endif
    forks
