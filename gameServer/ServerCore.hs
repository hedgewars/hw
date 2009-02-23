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

reactCmd :: ServerInfo -> Int -> [String] -> Clients -> Rooms -> IO (ServerInfo, Clients, Rooms)
reactCmd serverInfo clID cmd clients rooms = do
	(_ , serverInfo, clients, rooms) <-
		foldM processAction (clID, serverInfo, clients, rooms) $ handleCmd clID clients rooms cmd
	return (serverInfo, clients, rooms)

mainLoop :: Chan CoreMessage -> ServerInfo -> Clients -> Rooms -> IO ()
mainLoop coreChan serverInfo clients rooms = do
	r <- readChan coreChan
	
	(newServerInfo, mClients, mRooms) <-
		case r of
			Accept ci -> do
				let updatedClients = IntMap.insert (clientUID ci) ci clients
				--infoM "Clients" ("New client: id " ++ (show $ clientUID ci))
				processAction
					(clientUID ci, serverInfo, updatedClients, rooms)
					(AnswerThisClient ["CONNECTED", "Hedgewars server http://www.hedgewars.org/"])
				return (serverInfo, updatedClients, rooms)

			ClientMessage (clID, cmd) -> do
				debugM "Clients" $ (show clID) ++ ": " ++ (show cmd)
				if clID `IntMap.member` clients then
					reactCmd serverInfo clID cmd clients rooms
					else
					do
					debugM "Clients" "Message from dead client"
					return (serverInfo, clients, rooms)

	{-			let hadRooms = (not $ null rooms) && (null mrooms)
					in unless ((not $ isDedicated serverInfo) && ((null clientsIn) || hadRooms)) $
						mainLoop serverInfo acceptChan messagesChan clientsIn mrooms -}

	mainLoop coreChan newServerInfo mClients mRooms

startServer :: ServerInfo -> Chan CoreMessage -> Socket -> IO ()
startServer serverInfo coreChan serverSocket = do
	putStrLn $ "Listening on port " ++ show (listenPort serverInfo)

	forkIO $
		acceptLoop
			serverSocket
			coreChan
			0

	return ()
	
{-	forkIO $ messagesLoop messagesChan
	forkIO $ timerLoop messagesChan-}

	startDBConnection $ serverInfo

	mainLoop coreChan serverInfo IntMap.empty (IntMap.singleton 0 newRoom)



