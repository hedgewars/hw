module ServerCore where

import Network
import Control.Concurrent
import Control.Concurrent.Chan
import Control.Monad
import qualified Data.IntMap as IntMap
import System.Log.Logger
import Control.Monad.Reader
--------------------------------------
import CoreTypes
import NetRoutines
import HWProtoCore
import Actions
import OfficialServer.DBInteraction
import RoomsAndClients


timerLoop :: Int -> Chan CoreMessage -> IO()
timerLoop tick messagesChan = threadDelay (30 * 10^6) >> writeChan messagesChan (TimerAction tick) >> timerLoop (tick + 1) messagesChan


reactCmd :: ServerInfo -> ClientIndex -> [String] -> MRnC -> IO ()
reactCmd sInfo ci cmd rnc = do
    actions <- withRoomsAndClients rnc (\irnc -> runReader (handleCmd cmd) (ci, irnc))
    forM_ actions (processAction (ci, sInfo, rnc))

mainLoop :: ServerInfo -> MRnC -> IO ()
mainLoop serverInfo rnc = forever $ do
    r <- readChan $ coreChan serverInfo

    case r of
        Accept ci -> do
            processAction
                (undefined, serverInfo, rnc) (AddClient ci)
            return ()

        ClientMessage (clID, cmd) -> do
            debugM "Clients" $ (show clID) ++ ": " ++ (show cmd)
            --if clID `IntMap.member` clients then
            reactCmd serverInfo clID cmd rnc
            return ()
                --else
                --do
                --debugM "Clients" "Message from dead client"
                --return (serverInfo, rnc)

        ClientAccountInfo (clID, info) -> do
            --if clID `IntMap.member` clients then
            processAction
                (clID, serverInfo, rnc)
                (ProcessAccountInfo info)
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

    forkIO $ mainLoop serverInfo rnc

    forever $ threadDelay (60 * 60 * 10^6) >> putStrLn "***"
