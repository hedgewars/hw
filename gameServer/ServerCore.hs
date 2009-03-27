module ServerCore where

import Network
import Control.Concurrent
import Control.Concurrent.STM
import Control.Concurrent.Chan
import Control.Monad
import qualified Data.IntMap as IntMap
import System.Log.Logger
--------------------------------------
import CoreTypes
import NetRoutines
import Utils
import HWProtoCore
import Actions
import OfficialServer.DBInteraction


timerLoop :: Chan CoreMessage -> IO()
timerLoop messagesChan = forever $ do
	threadDelay (30 * 10^6) -- 30 seconds
	writeChan messagesChan TimerAction

firstAway (_, a, b, c) = (a, b, c)

reactCmd :: ServerInfo -> Int -> [String] -> Clients -> Rooms -> IO (ServerInfo, Clients, Rooms)
reactCmd serverInfo clID cmd clients rooms =
	liftM firstAway $ foldM processAction (clID, serverInfo, clients, rooms) $ handleCmd clID clients rooms cmd

mainLoop :: ServerInfo -> Clients -> Rooms -> IO ()
mainLoop serverInfo clients rooms = do
	r <- readChan $ coreChan serverInfo
	
	(newServerInfo, mClients, mRooms) <-
		case r of
			Accept ci -> do
				liftM firstAway $ processAction
					(clientUID ci, serverInfo, clients, rooms) (AddClient ci)

			ClientMessage (clID, cmd) -> do
				debugM "Clients" $ (show clID) ++ ": " ++ (show cmd)
				if clID `IntMap.member` clients then
					reactCmd serverInfo clID cmd clients rooms
					else
					do
					debugM "Clients" "Message from dead client"
					return (serverInfo, clients, rooms)

			ClientAccountInfo clID info ->
				if clID `IntMap.member` clients then
					liftM firstAway $ processAction
						(clID, serverInfo, clients, rooms)
						(ProcessAccountInfo info)
					else
					do
					debugM "Clients" "Got info for dead client"
					return (serverInfo, clients, rooms)

			TimerAction ->
				liftM firstAway $ processAction
						(0, serverInfo, clients, rooms)
						PingAll
			

	{-			let hadRooms = (not $ null rooms) && (null mrooms)
					in unless ((not $ isDedicated serverInfo) && ((null clientsIn) || hadRooms)) $
						mainLoop serverInfo acceptChan messagesChan clientsIn mrooms -}

	mainLoop newServerInfo mClients mRooms

startServer :: ServerInfo -> Socket -> IO ()
startServer serverInfo serverSocket = do
	putStrLn $ "Listening on port " ++ show (listenPort serverInfo)

	forkIO $
		acceptLoop
			serverSocket
			(coreChan serverInfo)
			0

	return ()
	
	forkIO $ timerLoop $ coreChan serverInfo

	startDBConnection $ serverInfo

	mainLoop serverInfo IntMap.empty (IntMap.singleton 0 newRoom)
