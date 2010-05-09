module ServerCore where

import Network
import Control.Concurrent
import Control.Concurrent.Chan
import Control.Monad
import qualified Data.IntMap as IntMap
import System.Log.Logger
import Control.Monad.Reader
import Control.Monad.State
--------------------------------------
import CoreTypes
import NetRoutines
import HWProtoCore
import Actions
import OfficialServer.DBInteraction
import RoomsAndClients


timerLoop :: Int -> Chan CoreMessage -> IO()
timerLoop tick messagesChan = threadDelay (30 * 10^6) >> writeChan messagesChan (TimerAction tick) >> timerLoop (tick + 1) messagesChan


reactCmd :: [String] -> StateT ActionsState IO ()
reactCmd cmd = do
    (Just ci) <- gets clientIndex
    rnc <- gets roomsClients
    actions <- liftIO $ withRoomsAndClients rnc (\irnc -> runReader (handleCmd cmd) (ci, irnc))
    forM_ actions processAction

mainLoop :: StateT ActionsState IO ()
mainLoop = forever $ do
    si <- gets serverInfo
    r <- liftIO $ readChan $ coreChan si

    case r of
        Accept ci -> do
            processAction (AddClient ci)
            return ()

        ClientMessage (ci, cmd) -> do
            liftIO $ debugM "Clients" $ (show ci) ++ ": " ++ (show cmd)
            modify (\as -> as{clientIndex = Just ci})
            --if clID `IntMap.member` clients then
            reactCmd cmd
            return ()
                --else
                --do
                --debugM "Clients" "Message from dead client"
                --return (serverInfo, rnc)

        ClientAccountInfo (clID, info) -> do
            --if clID `IntMap.member` clients then
            processAction (ProcessAccountInfo info)
            return ()
                --else
                --do
                --debugM "Clients" "Got info for dead client"
                --return (serverInfo, rnc)

        TimerAction tick ->
            return ()
            --liftM snd $
            --    foldM processAction (0, serverInfo, rnc) $
            --        PingAll : [StatsAction | even tick]

startServer :: ServerInfo -> Socket -> IO ()
startServer serverInfo serverSocket = do
    putStrLn $ "Listening on port " ++ show (listenPort serverInfo)

    forkIO $
        acceptLoop
            serverSocket
            (coreChan serverInfo)

    return ()

    forkIO $ timerLoop 0 $ coreChan serverInfo

    startDBConnection serverInfo

    rnc <- newRoomsAndClients newRoom

    forkIO $ evalStateT mainLoop (ActionsState Nothing serverInfo rnc)

    forever $ threadDelay (60 * 60 * 10^6) >> putStrLn "***"
