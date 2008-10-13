module Miscutils where

import IO
import Control.Concurrent.STM
import Data.Word
import Data.Char
import Data.List
import Maybe (fromJust)
import qualified Data.Map as Map

data ClientInfo =
 ClientInfo
	{
		chan :: TChan [String],
		handle :: Handle,
		nick :: String,
		protocol :: Word16,
		room :: String,
		isMaster :: Bool
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
		params :: Map.Map String [String]
	}
createRoom = (RoomInfo "" "" 0 [] "+rnd+" False Map.empty)

type ClientsTransform = [ClientInfo] -> [ClientInfo]
type RoomsTransform = [RoomInfo] -> [RoomInfo]
type HandlesSelector = ClientInfo -> [ClientInfo] -> [RoomInfo] -> [Handle]
type CmdHandler = ClientInfo -> [ClientInfo] -> [RoomInfo] -> [String] -> (ClientsTransform, RoomsTransform, [(HandlesSelector, [String])])


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

sameRoom :: HandlesSelector
sameRoom client clients rooms = map handle $ filter (\ci -> room ci == room client) clients

othersInRoom :: HandlesSelector
othersInRoom client clients rooms = map handle $ filter (client /=) $ filter (\ci -> room ci == room client) clients

fromRoom :: String -> HandlesSelector
fromRoom roomName _ clients _ = map handle $ filter (\ci -> room ci == roomName) clients

clientOnly :: HandlesSelector
clientOnly client _ _ = [handle client]

noChangeClients :: ClientsTransform
noChangeClients a = a

modifyClient :: ClientInfo -> ClientsTransform
modifyClient _ [] = error "modifyClient: no such client"
modifyClient client (cl:cls) =
	if cl == client then
		client : cls
	else
		cl : (modifyClient client cls)

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
		room : modifyRoom room rms

modifyTeam :: RoomInfo -> TeamInfo -> RoomInfo
modifyTeam room team = room{teams = replaceTeam team $ teams room}
	where
	replaceTeam _ [] = error "modifyTeam: no such team"
	replaceTeam team (t:teams) =
		if teamname team == teamname t then
			team : teams
		else
			t : replaceTeam team teams
