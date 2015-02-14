{-
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2014 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 \-}

{-# LANGUAGE CPP, ScopedTypeVariables, OverloadedStrings #-}

module Main where

import Network.Socket
import Network.BSD
import Control.Concurrent.Chan
import qualified Control.Exception as E
import System.Log.Logger
-----------------------------------
import Opts
import CoreTypes
import ServerCore
#if defined(OFFICIAL_SERVER)
import ConfigFile
#endif

#if !defined(mingw32_HOST_OS)
import System.Posix
#endif


setupLoggers :: IO ()
setupLoggers = do
    updateGlobalLogger "Clients" (setLevel DEBUG)
    updateGlobalLogger "Core" (setLevel NOTICE)
    updateGlobalLogger "REPLAYS" (setLevel NOTICE)


server :: ServerInfo -> IO ()
server si = do
    proto <- getProtocolNumber "tcp"
    E.bracket
        (socket AF_INET Stream proto)
        sClose
        (\sock -> do
            setSocketOption sock ReuseAddr 1
            bindSocket sock (SockAddrInet (listenPort si) iNADDR_ANY)
            listen sock maxListenQueue
            startServer si{serverSocket = Just sock}
        )

handleRestart :: ShutdownException -> IO ()
handleRestart ShutdownException = do
    noticeM "Core" "Shutting down"
    return ()

main :: IO ()
main = withSocketsDo $ do
#if !defined(mingw32_HOST_OS)
    _ <- installHandler sigPIPE Ignore Nothing
    _ <- installHandler sigCHLD Ignore Nothing
#endif

    setupLoggers

    dbQueriesChan <- newChan
    coreChan' <- newChan
    serverInfo' <- getOpts $ newServerInfo coreChan' dbQueriesChan Nothing Nothing

#if defined(OFFICIAL_SERVER)
    si <- readServerConfig serverInfo'
#else
    let si = serverInfo'
#endif

    (server si) `E.catch` handleRestart
