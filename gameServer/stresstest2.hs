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

session1 nick room = ["NICK", nick, "", "PROTO", "32", ""]



testing = Control.OldException.handle print $ do
    putStrLn "Start"
    sock <- connectTo "127.0.0.1" (PortNumber 46631)

    num1 <- randomRIO (70000::Int, 70100)
    num2 <- randomRIO (0::Int, 2)
    num3 <- randomRIO (0::Int, 5)
    let nick1 = 'n' : show num1
    let room1 = 'r' : show num2
    mapM_ (\x -> hPutStrLn sock x >> hFlush sock >> randomRIO (300::Int, 590) >>= threadDelay) $ session1 nick1 room1
    mapM_ (\x -> hPutStrLn sock x >> hFlush sock) $ concatMap (\x -> ["CHAT_MSG", show x, ""]) [1..]
    hClose sock
    putStrLn "Finish"

forks = testing

main = withSocketsDo $ do
#if !defined(mingw32_HOST_OS)
    installHandler sigPIPE Ignore Nothing;
#endif
    forks
