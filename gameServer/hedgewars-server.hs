{-# LANGUAGE CPP, ScopedTypeVariables #-}

module Main where

import Network.Socket
import Network.BSD
import Control.Concurrent.STM
import Control.Concurrent.Chan
import qualified Control.Exception as Exception
import System.Log.Logger
-----------------------------------
import Opts
import CoreTypes
import ServerCore


#if !defined(mingw32_HOST_OS)
import System.Posix
#endif


setupLoggers :: IO ()
setupLoggers =
    updateGlobalLogger "Clients"
        (setLevel INFO)

main :: IO ()
main = withSocketsDo $ do
#if !defined(mingw32_HOST_OS)
    installHandler sigPIPE Ignore Nothing;
    installHandler sigCHLD Ignore Nothing;
#endif

    setupLoggers

    stats' <- atomically $ newTMVar (StatisticsInfo 0 0)
    dbQueriesChan <- newChan
    coreChan' <- newChan
    serverInfo' <- getOpts $ newServerInfo stats' coreChan' dbQueriesChan

#if defined(OFFICIAL_SERVER)
    dbHost' <- askFromConsole "DB host: "
    dbLogin' <- askFromConsole "login: "
    dbPassword' <- askFromConsole "password: "
    let serverInfo = serverInfo'{dbHost = dbHost', dbLogin = dbLogin', dbPassword = dbPassword'}
#else
    let serverInfo = serverInfo'
#endif


    proto <- getProtocolNumber "tcp"
    Exception.bracket
        (socket AF_INET Stream proto)
        sClose
        (\sock -> do
            setSocketOption sock ReuseAddr 1
            bindSocket sock (SockAddrInet (listenPort serverInfo) iNADDR_ANY)
            listen sock maxListenQueue
            startServer serverInfo sock
        )
