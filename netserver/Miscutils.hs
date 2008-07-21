module Miscutils where

import IO
import Control.Concurrent.STM
import Data.Word
import Data.Char
import Data.List
import Maybe (fromJust)


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

data RoomInfo =
	RoomInfo
	{
		name :: String,
		password :: String
	}

type ClientsTransform = [ClientInfo] -> [ClientInfo]
type RoomsTransform = [RoomInfo] -> [RoomInfo]
type HandlesSelector = ClientInfo -> [ClientInfo] -> [RoomInfo] -> [Handle]
type CmdHandler = ClientInfo -> [ClientInfo] -> [RoomInfo] -> [String] -> (ClientsTransform, RoomsTransform, HandlesSelector, [String])


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

badCmd :: [String]
badCmd = ["ERROR", "Bad command, state or incorrect parameter"]
