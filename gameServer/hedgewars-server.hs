{-# LANGUAGE CPP, ScopedTypeVariables #-}

module Main where

import Network.Socket
import qualified Network
import Control.Concurrent.STM
import Control.Concurrent.Chan
#if defined(NEW_EXCEPTIONS)
import qualified Control.OldException as Exception
#else
import qualified Control.Exception as Exception
#endif
import System.Log.Logger
-----------------------------------
import Opts
import CoreTypes
import OfficialServer.DBInteraction
import ServerCore
import Utils


#if !defined(mingw32_HOST_OS)
import System.Posix
#endif


setupLoggers =
    updateGlobalLogger "Clients"
        (setLevel INFO)

main = withSocketsDo $ do
#if !defined(mingw32_HOST_OS)
    installHandler sigPIPE Ignore Nothing;
    installHandler sigCHLD Ignore Nothing;
#endif

    setupLoggers

    stats <- atomically $ newTMVar (StatisticsInfo 0 0)
    dbQueriesChan <- newChan
    coreChan <- newChan
    serverInfo' <- getOpts $ newServerInfo stats coreChan dbQueriesChan
    
#if defined(OFFICIAL_SERVER)
    dbHost' <- askFromConsole "DB host: "
    dbLogin' <- askFromConsole "login: "
    dbPassword' <- askFromConsole "password: "
    let serverInfo = serverInfo'{dbHost = dbHost', dbLogin = dbLogin', dbPassword = dbPassword'}
#else
    let serverInfo = serverInfo'
#endif

    Exception.bracket
        (Network.listenOn $ Network.PortNumber $ listenPort serverInfo)
        sClose
        (startServer serverInfo)
