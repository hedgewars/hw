module ServerCore where

import Network
import Control.Concurrent
import Control.Monad
import System.Log.Logger
import Control.Monad.Reader
import Control.Monad.State.Strict
import Data.Set as Set
import qualified Data.ByteString.Char8 as B
import Control.DeepSeq
import Data.Unique
--------------------------------------
import CoreTypes
import NetRoutines
import HWProtoCore
import Actions
import OfficialServer.DBInteraction
import ServerState


timerLoop :: Int -> Chan CoreMessage -> IO ()
timerLoop tick messagesChan = threadDelay 30000000 >> writeChan messagesChan (TimerAction tick) >> timerLoop (tick + 1) messagesChan


reactCmd :: [B.ByteString] -> StateT ServerState IO ()
reactCmd cmd = do
    (Just ci) <- gets clientIndex
    rnc <- gets roomsClients
    actions <- liftIO $ withRoomsAndClients rnc (\irnc -> runReader (handleCmd cmd) (ci, irnc))
    forM_ (actions `deepseq` actions) processAction

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
                as <- get
                put $! as{clientIndex = Just ci}
                reactCmd cmd

        Remove ci ->
            processAction (DeleteClient ci)

        ClientAccountInfo ci uid info -> do
            rnc <- gets roomsClients
            exists <- liftIO $ clientExists rnc ci
            when exists $ do
                as <- get
                put $! as{clientIndex = Just ci}
                uid' <- client's clUID
                when (uid == hashUnique uid') $ processAction (ProcessAccountInfo info)
                return ()

        TimerAction tick ->
                mapM_ processAction $
                    PingAll : [StatsAction | even tick]


startServer :: ServerInfo -> Socket -> IO ()
startServer si serverSocket = do
    putStrLn $ "Listening on port " ++ show (listenPort si)

    _ <- forkIO $
        acceptLoop
            serverSocket
            (coreChan si)

    return ()

    _ <- forkIO $ timerLoop 0 $ coreChan si

    startDBConnection si

    rnc <- newRoomsAndClients newRoom

    evalStateT mainLoop (ServerState Nothing si Set.empty rnc)
