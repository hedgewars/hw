{-
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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

module ServerCore where

import Control.Concurrent
import Control.Monad
import System.Log.Logger
import Control.Monad.Reader
import Control.Monad.State.Strict
import Data.Set as Set
import Data.Unique
import Data.Maybe
--------------------------------------
import CoreTypes
import NetRoutines
import Actions
import OfficialServer.DBInteraction
import ServerState


timerLoop :: Int -> Chan CoreMessage -> IO ()
timerLoop tick messagesChan = threadDelay 30000000 >> writeChan messagesChan (TimerAction tick) >> timerLoop (tick + 1) messagesChan


mainLoop :: StateT ServerState IO ()
mainLoop = forever $ do
    -- get >>= \s -> put $! s

    si <- gets serverInfo
    r <- liftIO $ readChan $ coreChan si

    case r of
        Accept ci -> processAction (AddClient ci)

        ClientMessage (ci, cmd) -> do
            liftIO $ debugM "Clients" $ show ci ++ ": " ++ show cmd

            removed <- gets removedClients
            unless (ci `Set.member` removed) $ do
                modify (\s -> s{clientIndex = Just ci})
                processAction $ ReactCmd cmd

        Remove ci ->
            processAction (DeleteClient ci)

        ClientAccountInfo ci uid info -> do
            rnc <- gets roomsClients
            exists <- liftIO $ clientExists rnc ci
            when exists $ do
                modify (\s -> s{clientIndex = Just ci})
                uid' <- client's clUID
                when (uid == hashUnique uid') $ processAction (ProcessAccountInfo info)
                return ()

        TimerAction tick ->
                mapM_ processAction $
                    PingAll
                    : CheckVotes
                    : [StatsAction | even tick]
                    ++ [Cleanup | tick `mod` 100 == 0]


startServer :: ServerInfo -> IO ()
startServer si = do
    noticeM "Core" $ "Listening on port " ++ show (listenPort si)

    _ <- forkIO $
        acceptLoop
            (fromJust $ serverSocket si)
            (coreChan si)

    _ <- forkIO $ timerLoop 0 $ coreChan si

    startDBConnection si

    rnc <- newRoomsAndClients newRoom
    jm <- newJoinMonitor

    evalStateT mainLoop (ServerState Nothing si Set.empty rnc jm)
