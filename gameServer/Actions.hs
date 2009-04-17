module Actions where

import Control.Concurrent.STM
import Control.Concurrent.Chan
import Data.IntMap
import qualified Data.IntSet as IntSet
import qualified Data.Sequence as Seq
import System.Log.Logger
import Monad
import Data.Time
import Maybe
-----------------------------
import CoreTypes
import Utils

data Action =
	AnswerThisClient [String]
	| AnswerAll [String]
	| AnswerAllOthers [String]
	| AnswerThisRoom [String]
	| AnswerOthersInRoom [String]
	| AnswerLobby [String]
	| SendServerMessage
	| RoomAddThisClient Int -- roomID
	| RoomRemoveThisClient
	| RemoveTeam String
	| RemoveRoom
	| UnreadyRoomClients
	| MoveToLobby
	| ProtocolError String
	| Warning String
	| ByeClient String
	| KickClient Int -- clID
	| KickRoomClient Int -- clID
	| BanClient String -- nick
	| RemoveClientTeams Int -- clID
	| ModifyClient (ClientInfo -> ClientInfo)
	| ModifyRoom (RoomInfo -> RoomInfo)
	| ModifyServerInfo (ServerInfo -> ServerInfo)
	| AddRoom String String
	| CheckRegistered
	| ProcessAccountInfo AccountInfo
	| Dump
	| AddClient ClientInfo
	| PingAll

type CmdHandler = Int -> Clients -> Rooms -> [String] -> [Action]

replaceID a (b, c, d, e) = (a, c, d, e)

processAction :: (Int, ServerInfo, Clients, Rooms) -> Action -> IO (Int, ServerInfo, Clients, Rooms)


processAction (clID, serverInfo, clients, rooms) (AnswerThisClient msg) = do
	writeChan (sendChan $ clients ! clID) msg
	return (clID, serverInfo, clients, rooms)


processAction (clID, serverInfo, clients, rooms) (AnswerAll msg) = do
	mapM_ (\cl -> writeChan (sendChan cl) msg) (elems clients)
	return (clID, serverInfo, clients, rooms)


processAction (clID, serverInfo, clients, rooms) (AnswerAllOthers msg) = do
	mapM_ (\id -> writeChan (sendChan $ clients ! id) msg) $
		Prelude.filter (\id' -> (id' /= clID) && (logonPassed $ clients ! id')) (keys clients)
	return (clID, serverInfo, clients, rooms)


processAction (clID, serverInfo, clients, rooms) (AnswerThisRoom msg) = do
	mapM_ (\id -> writeChan (sendChan $ clients ! id) msg) roomClients
	return (clID, serverInfo, clients, rooms)
	where
		roomClients = IntSet.elems $ playersIDs room
		room = rooms ! rID
		rID = roomID client
		client = clients ! clID


processAction (clID, serverInfo, clients, rooms) (AnswerOthersInRoom msg) = do
	mapM_ (\id -> writeChan (sendChan $ clients ! id) msg) $ Prelude.filter (/= clID) roomClients
	return (clID, serverInfo, clients, rooms)
	where
		roomClients = IntSet.elems $ playersIDs room
		room = rooms ! rID
		rID = roomID client
		client = clients ! clID


processAction (clID, serverInfo, clients, rooms) (AnswerLobby msg) = do
	mapM_ (\id -> writeChan (sendChan $ clients ! id) msg) roomClients
	return (clID, serverInfo, clients, rooms)
	where
		roomClients = IntSet.elems $ playersIDs room
		room = rooms ! 0


processAction (clID, serverInfo, clients, rooms) SendServerMessage = do
	writeChan (sendChan $ clients ! clID) $ ["SERVER_MESSAGE", message serverInfo]
	return (clID, serverInfo, clients, rooms)
	where
		client = clients ! clID
		message = if clientProto client < 25 then
			serverMessageForOldVersions
			else
			serverMessage


processAction (clID, serverInfo, clients, rooms) (ProtocolError msg) = do
	writeChan (sendChan $ clients ! clID) ["ERROR", msg]
	return (clID, serverInfo, clients, rooms)


processAction (clID, serverInfo, clients, rooms) (Warning msg) = do
	writeChan (sendChan $ clients ! clID) ["WARNING", msg]
	return (clID, serverInfo, clients, rooms)


processAction (clID, serverInfo, clients, rooms) (ByeClient msg) = do
	infoM "Clients" ((show $ clientUID client) ++ " quits: " ++ msg)
	(_, _, newClients, newRooms) <-
			if roomID client /= 0 then
				processAction  (clID, serverInfo, clients, rooms)
					(if isMaster client then RemoveRoom else RemoveClientTeams clID)
				else
					return (clID, serverInfo, clients, rooms)

	mapM_ (processAction (clID, serverInfo, newClients, newRooms)) $ answerOthersQuit ++ answerInformRoom
	writeChan (sendChan $ clients ! clID) ["BYE", msg]
	return (
			0,
			serverInfo,
			delete clID newClients,
			adjust (\r -> r{
					playersIDs = IntSet.delete clID (playersIDs r),
					playersIn = (playersIn r) - 1,
					readyPlayers = if isReady client then readyPlayers r - 1 else readyPlayers r
					}) (roomID $ newClients ! clID) newRooms
			)
	where
		client = clients ! clID
		clientNick = nick client
		answerInformRoom =
			if roomID client /= 0 then
				if not $ Prelude.null msg then
					[AnswerThisRoom ["LEFT", clientNick, msg]]
				else
					[AnswerThisRoom ["LEFT", clientNick]]
			else
				[]
		answerOthersQuit =
			if logonPassed client then
				if not $ Prelude.null msg then
					[AnswerAll ["LOBBY:LEFT", clientNick, msg]]
				else
					[AnswerAll ["LOBBY:LEFT", clientNick]]
			else
				[]


processAction (clID, serverInfo, clients, rooms) (ModifyClient func) = do
	return (clID, serverInfo, adjust func clID clients, rooms)


processAction (clID, serverInfo, clients, rooms) (ModifyRoom func) = do
	return (clID, serverInfo, clients, adjust func rID rooms)
	where
		rID = roomID $ clients ! clID


processAction (clID, serverInfo, clients, rooms) (ModifyServerInfo func) = do
	return (clID, func serverInfo, clients, rooms)


processAction (clID, serverInfo, clients, rooms) (RoomAddThisClient rID) = do
	processAction (
		clID,
		serverInfo,
		adjust (\cl -> cl{roomID = rID}) clID clients,
		adjust (\r -> r{playersIDs = IntSet.insert clID (playersIDs r), playersIn = (playersIn r) + 1}) rID $
			adjust (\r -> r{playersIDs = IntSet.delete clID (playersIDs r)}) 0 rooms
		) joinMsg
	where
		client = clients ! clID
		joinMsg = if rID == 0 then
				AnswerAllOthers ["LOBBY:JOINED", nick client]
			else
				AnswerThisRoom ["JOINED", nick client]


processAction (clID, serverInfo, clients, rooms) (RoomRemoveThisClient) = do
	(_, _, newClients, newRooms) <-
			if roomID client /= 0 then
				foldM
					processAction
						(clID, serverInfo, clients, rooms)
						[AnswerOthersInRoom ["LEFT", nick client, "part"],
						RemoveClientTeams clID]
				else
					return (clID, serverInfo, clients, rooms)
	
	return (
		clID,
		serverInfo,
		adjust (\cl -> cl{roomID = 0, isMaster = False, isReady = False}) clID newClients,
		adjust (\r -> r{
				playersIDs = IntSet.delete clID (playersIDs r),
				playersIn = (playersIn r) - 1,
				readyPlayers = if isReady client then (readyPlayers r) - 1 else readyPlayers r
				}) rID $
			adjust (\r -> r{playersIDs = IntSet.insert clID (playersIDs r)}) 0 newRooms
		)
	where
		rID = roomID client
		client = clients ! clID


processAction (clID, serverInfo, clients, rooms) (AddRoom roomName roomPassword) = do
	let newServerInfo = serverInfo {nextRoomID = newID}
	let room = newRoom{
			roomUID = newID,
			name = roomName,
			password = roomPassword,
			roomProto = (clientProto client)
			}

	processAction (clID, serverInfo, clients, rooms) $ AnswerLobby ["ROOM", "ADD", roomName]

	processAction (
		clID,
		newServerInfo,
		adjust (\cl -> cl{isMaster = True}) clID clients,
		insert newID room rooms
		) $ RoomAddThisClient newID
	where
		newID = (nextRoomID serverInfo) - 1
		client = clients ! clID


processAction (clID, serverInfo, clients, rooms) (RemoveRoom) = do
	processAction (clID, serverInfo, clients, rooms) $ AnswerLobby ["ROOM", "DEL", name room]
	processAction (clID, serverInfo, clients, rooms) $ AnswerOthersInRoom ["ROOMABANDONED", name room]
	return (clID,
		serverInfo,
		Data.IntMap.map (\cl -> if roomID cl == rID then cl{roomID = 0, isMaster = False, isReady = False} else cl) clients,
		delete rID $ adjust (\r -> r{playersIDs = IntSet.union (playersIDs room) (playersIDs r)}) 0 rooms
		)
	where
		room = rooms ! rID
		rID = roomID client
		client = clients ! clID


processAction (clID, serverInfo, clients, rooms) (UnreadyRoomClients) = do
	processAction (clID, serverInfo, clients, rooms) $ AnswerThisRoom ("NOT_READY" : roomPlayers)
	return (clID,
		serverInfo,
		Data.IntMap.map (\cl -> if roomID cl == rID then cl{isReady = False} else cl) clients,
		adjust (\r -> r{readyPlayers = 0}) rID rooms)
	where
		room = rooms ! rID
		rID = roomID client
		client = clients ! clID
		roomPlayers = Prelude.map (nick . (clients !)) roomPlayersIDs
		roomPlayersIDs = IntSet.elems $ playersIDs room


processAction (clID, serverInfo, clients, rooms) (RemoveTeam teamName) = do
	newRooms <-	if not $ gameinprogress room then
			do
			processAction (clID, serverInfo, clients, rooms) $ AnswerOthersInRoom ["REMOVE_TEAM", teamName]
			return $
				adjust (\r -> r{teams = Prelude.filter (\t -> teamName /= teamname t) $ teams r}) rID rooms
		else
			do
			processAction (clID, serverInfo, clients, rooms) $ AnswerOthersInRoom ["EM", rmTeamMsg]
			return $
				adjust (\r -> r{
				teams = Prelude.filter (\t -> teamName /= teamname t) $ teams r,
				leftTeams = teamName : leftTeams r,
				roundMsgs = roundMsgs r Seq.|> rmTeamMsg
				}) rID rooms
	return (clID, serverInfo, clients, newRooms)
	where
		room = rooms ! rID
		rID = roomID client
		client = clients ! clID
		rmTeamMsg = toEngineMsg $ 'F' : teamName


processAction (clID, serverInfo, clients, rooms) (CheckRegistered) = do
	writeChan (dbQueries serverInfo) $ CheckAccount client
	return (clID, serverInfo, clients, rooms)
	where
		client = clients ! clID


processAction (clID, serverInfo, clients, rooms) (Dump) = do
	writeChan (sendChan $ clients ! clID) ["DUMP", show serverInfo, showTree clients, showTree rooms]
	return (clID, serverInfo, clients, rooms)


processAction (clID, serverInfo, clients, rooms) (ProcessAccountInfo info) = do
	processAction (clID, serverInfo, clients, rooms) SendServerMessage
	case info of
		HasAccount passwd isAdmin -> do
			infoM "Clients" $ show clID ++ " has account"
			writeChan (sendChan $ clients ! clID) ["ASKPASSWORD"]
			return (clID, serverInfo, adjust (\cl -> cl{webPassword = passwd, isAdministrator = isAdmin}) clID clients, rooms)
		Guest -> do
			infoM "Clients" $ show clID ++ " is guest"
			processAction (clID, serverInfo, adjust (\cl -> cl{logonPassed = True}) clID clients, rooms) MoveToLobby
		Admin -> do
			infoM "Clients" $ show clID ++ " is admin"
			foldM processAction (clID, serverInfo, adjust (\cl -> cl{logonPassed = True, isAdministrator = True}) clID clients, rooms) [MoveToLobby, AnswerThisClient ["ADMIN_ACCESS"]]


processAction (clID, serverInfo, clients, rooms) (MoveToLobby) = do
	foldM processAction (clID, serverInfo, clients, rooms) $
		(RoomAddThisClient 0)
		: answerLobbyNicks
		-- ++ (answerServerMessage client clients)
	where
		lobbyNicks = Prelude.map nick $ Prelude.filter logonPassed $ elems clients
		answerLobbyNicks = if not $ Prelude.null lobbyNicks then
					[AnswerThisClient (["LOBBY:JOINED"] ++ lobbyNicks)]
				else
					[]


processAction (clID, serverInfo, clients, rooms) (KickClient kickID) = do
	liftM2 replaceID (return clID) (processAction (kickID, serverInfo, clients, rooms) $ ByeClient "Kicked")


processAction (clID, serverInfo, clients, rooms) (BanClient banNick) = do
	return (clID, serverInfo, clients, rooms)


processAction (clID, serverInfo, clients, rooms) (KickRoomClient kickID) = do
	writeChan (sendChan $ clients ! kickID) ["KICKED"]
	liftM2 replaceID (return clID) (processAction (kickID, serverInfo, clients, rooms) $ RoomRemoveThisClient)


processAction (clID, serverInfo, clients, rooms) (RemoveClientTeams teamsClID) = do
	liftM2 replaceID (return clID) $
		foldM processAction (teamsClID, serverInfo, clients, rooms) $ removeTeamsActions
	where
		client = clients ! teamsClID
		room = rooms ! (roomID client)
		teamsToRemove = Prelude.filter (\t -> teamowner t == nick client) $ teams room
		removeTeamsActions = Prelude.map (RemoveTeam . teamname) teamsToRemove


processAction (clID, serverInfo, clients, rooms) (AddClient client) = do
	let updatedClients = insert (clientUID client) client clients
	infoM "Clients" ((show $ clientUID client) ++ ": New client. Time: " ++ (show $ connectTime client))
	writeChan (sendChan $ client) ["CONNECTED", "Hedgewars server http://www.hedgewars.org/"]

	let newLogins = takeWhile (\(_ , time) -> (connectTime client) `diffUTCTime` time <= 11) $ lastLogins serverInfo

	if isJust $ host client `Prelude.lookup` newLogins then
		processAction (clID, serverInfo{lastLogins = newLogins}, updatedClients, rooms) $ ByeClient "Reconnected too fast"
		else
		return (clID, serverInfo{lastLogins = (host client, connectTime client) : newLogins}, updatedClients, rooms)


processAction (clID, serverInfo, clients, rooms) PingAll = do
	(_, _, newClients, newRooms) <- foldM kickTimeouted (clID, serverInfo, clients, rooms) $ elems clients
	processAction (clID,
		serverInfo,
		Data.IntMap.map (\cl -> cl{pingsQueue = pingsQueue cl + 1}) newClients,
		newRooms) $ AnswerAll ["PING"]
	where
		kickTimeouted (clID, serverInfo, clients, rooms) client =
			if pingsQueue client > 0 then
				processAction (clientUID client, serverInfo, clients, rooms) $ ByeClient "Ping timeout"
				else
				return (clID, serverInfo, clients, rooms)
