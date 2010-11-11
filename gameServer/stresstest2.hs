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

testing = Control.Exception.handle print $ do
    delay <- randomRIO (100::Int, 300)
    threadDelay delay
    sock <- connectTo "127.0.0.1" (PortNumber 46631)
    hClose sock

forks i = do
    delay <- randomRIO (50::Int, 190)
    if i `mod` 10 == 0 then putStr (show i) else putStr "."
    hFlush stdout
    threadDelay delay
    forkIO testing
    forks (i + 1)

main = withSocketsDo $ do
#if !defined(mingw32_HOST_OS)
    installHandler sigPIPE Ignore Nothing;
#endif
    forks 1
