module ServerCore where

import Network
import Control.Concurrent
import Control.Concurrent.Chan
import Control.Monad
import qualified Data.IntMap as IntMap
import System.Log.Logger
import Control.Monad.Reader
import Control.Monad.State
import Data.Set as Set
import qualified Data.ByteString.Char8 as B
--------------------------------------
import CoreTypes
import NetRoutines
import HWProtoCore
import Actions
import OfficialServer.DBInteraction
import ServerState


timerLoop :: Int -> Chan CoreMessage -> IO()
timerLoop tick messagesChan = threadDelay (30 * 10^6) >> writeChan messagesChan (TimerAction tick) >> timerLoop (tick + 1) messagesChan


reactCmd :: [B.ByteString] -> StateT ServerState IO ()
reactCmd cmd = do
    (Just ci) <- gets clientIndex
    rnc <- gets roomsClients
    actions <- liftIO $ withRoomsAndClients rnc (\irnc -> runReader (handleCmd cmd) (ci, irnc))
    forM_ actions processAction

mainLoop :: StateT ServerState IO ()
mainLoop = forever $ do
    si <- gets serverInfo
    r <- liftIO $ readChan $ coreChan si

    liftIO $ putStrLn $ "Core msg: " ++ show r
    case r of
        Accept ci -> processAction (AddClient ci)

        ClientMessage (ci, cmd) -> do
            liftIO $ debugM "Clients" $ (show ci) ++ ": " ++ (show cmd)

            removed <- gets removedClients
            when (not $ ci `Set.member` removed) $ do
                modify (\as -> as{clientIndex = Just ci})
                reactCmd cmd

        Remove ci -> do
            liftIO $ debugM "Clients"  $ "DeleteClient: " ++ show ci
            processAction (DeleteClient ci)

                --else
                --do
                --debugM "Clients" "Message from dead client"
                --return (serverInfo, rnc)

        ClientAccountInfo (ci, info) -> do
            --should instead check ci exists and has same nick/hostname
            --removed <- gets removedClients
            --when (not $ ci `Set.member` removed) $ do
            --    modify (\as -> as{clientIndex = Just ci})
            --    processAction (ProcessAccountInfo info)
            return ()
            
        TimerAction tick ->
                mapM_ processAction $
                    PingAll : [StatsAction | even tick]


startServer :: ServerInfo -> Socket -> IO ()
startServer serverInfo serverSocket = do
    putStrLn $ "Listening on port " ++ show (listenPort serverInfo)

    forkIO $
        acceptLoop
            serverSocket
            (coreChan serverInfo)

    return ()

    --forkIO $ timerLoop 0 $ coreChan serverInfo

    startDBConnection serverInfo

    rnc <- newRoomsAndClients newRoom

    forkIO $ evalStateT mainLoop (ServerState Nothing serverInfo Set.empty rnc)

    forever $ threadDelay (60 * 60 * 10^6)
