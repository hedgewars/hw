module Miscutils where

import IO
import Control.Concurrent.STM
import Data.Word
import Data.Char
import Data.List
import Maybe (fromJust)
import qualified Data.Map as Map
import Data.Time
import Network

data ClientInfo =
 ClientInfo
	{
		chan :: TChan [String],
		sendChan :: TChan [String],
		handle :: Handle,
		host :: String,
		connectTime :: UTCTime,
		nick :: String,
		protocol :: Word16,
		room :: String,
		isMaster :: Bool,
		isReady :: Bool,
		forceQuit :: Bool
	}

instance Eq ClientInfo where
	a1 == a2 = handle a1 == handle a2

data HedgehogInfo =
	HedgehogInfo String String

data TeamInfo =
	TeamInfo
	{
		teamowner :: String,
		teamname :: String,
		teamcolor :: String,
		teamgrave :: String,
		teamfort :: String,
		difficulty :: Int,
		hhnum :: Int,
		hedgehogs :: [HedgehogInfo]
	}

data RoomInfo =
	RoomInfo
	{
		name :: String,
		password :: String,
		roomProto :: Word16,
		teams :: [TeamInfo],
		gamemap :: String,
		gameinprogress :: Bool,
		playersIn :: Int,
		readyPlayers :: Int,
		isRestrictedJoins :: Bool,
		isRestrictedTeams :: Bool,
		roundMsgs :: [String],
		params :: Map.Map String [String]
	}
createRoom = (
	RoomInfo
		""
		""
		0
		[]
		"+rnd+"
		False
		1
		0
		False
		False
		[]
		Map.empty
	)

data ServerInfo =
	ServerInfo
	{
		isDedicated :: Bool,
		serverMessage :: String,
		listenPort :: PortNumber,
		loginsNumber :: Int,
		lastHourUsers :: [UTCTime]
	}
newServerInfo = (
	ServerInfo
		True
		"<h2><p align=center><a href=\"http://www.hedgewars.org/\">http://www.hedgewars.org/</a></p></h2>"
		46631
		0
		[]
	)

type ClientsTransform = [ClientInfo] -> [ClientInfo]
type RoomsTransform = [RoomInfo] -> [RoomInfo]
type HandlesSelector = ClientInfo -> [ClientInfo] -> [RoomInfo] -> [ClientInfo]
type Answer = ServerInfo -> (HandlesSelector, [String])
type CmdHandler = ClientInfo -> [ClientInfo] -> [RoomInfo] -> [String] -> (ClientsTransform, RoomsTransform, [Answer])


roomByName :: String -> [RoomInfo] -> RoomInfo
roomByName roomName rooms = fromJust $ find (\room -> roomName == name room) rooms

tselect :: [ClientInfo] -> STM ([String], ClientInfo)
tselect = foldl orElse retry . map (\ci -> (flip (,) ci) `fmap` readTChan (chan ci))

maybeRead :: Read a => String -> Maybe a
maybeRead s = case reads s of
	[(x, rest)] | all isSpace rest -> Just x
	_         -> Nothing

deleteBy2t :: (a -> b -> Bool) -> b -> [a] -> [a]
deleteBy2t _  _ [] = []
deleteBy2t eq x (y:ys) = if y `eq` x then ys else y : deleteBy2t eq x ys

deleteFirstsBy2t :: (a -> b -> Bool) -> [a] -> [b] -> [a]
deleteFirstsBy2t eq =  foldl (flip (deleteBy2t eq))

--clientByHandle :: Handle -> [ClientInfo] -> Maybe ClientInfo
--clientByHandle chandle clients = find (\c -> handle c == chandle) clients

sameRoom :: HandlesSelector
sameRoom client clients rooms = filter (\ci -> room ci == room client) clients

noRoomSameProto :: HandlesSelector
noRoomSameProto client clients _ = filter (null . room) $ filter (\ci -> protocol client == protocol ci) clients

othersInRoom :: HandlesSelector
othersInRoom client clients rooms = filter (client /=) $ filter (\ci -> room ci == room client) clients

fromRoom :: String -> HandlesSelector
fromRoom roomName _ clients _ = filter (\ci -> room ci == roomName) clients

allClients :: HandlesSelector
allClients _ clients _ = clients

clientOnly :: HandlesSelector
clientOnly client _ _ = [client]

noChangeClients :: ClientsTransform
noChangeClients a = a

modifyClient :: ClientInfo -> ClientsTransform
modifyClient _ [] = error "modifyClient: no such client"
modifyClient client (cl:cls) =
	if cl == client then
		client : cls
	else
		cl : (modifyClient client cls)

modifyRoomClients :: RoomInfo -> (ClientInfo -> ClientInfo) -> ClientsTransform
modifyRoomClients clientsroom clientMod clients = map (\c -> if name clientsroom == room c then clientMod c else c) clients

noChangeRooms :: RoomsTransform
noChangeRooms a = a

addRoom :: RoomInfo -> RoomsTransform
addRoom room rooms = room:rooms

removeRoom :: String -> RoomsTransform
removeRoom roomname rooms = filter (\rm -> roomname /= name rm) rooms

modifyRoom :: RoomInfo -> RoomsTransform
modifyRoom _ [] = error "changeRoomConfig: no such room"
modifyRoom room (rm:rms) =
	if name room == name rm then
		room : rms
	else
		rm : modifyRoom room rms

modifyTeam :: RoomInfo -> TeamInfo -> RoomInfo
modifyTeam room team = room{teams = replaceTeam team $ teams room}
	where
	replaceTeam _ [] = error "modifyTeam: no such team"
	replaceTeam team (t:teams) =
		if teamname team == teamname t then
			team : teams
		else
			t : replaceTeam team teams

proto2ver :: Word16 -> String
proto2ver 17 = "0.9.7-dev"
proto2ver 19 = "0.9.7"
proto2ver 20 = "0.9.8-dev"
proto2ver _ = "Unknown"