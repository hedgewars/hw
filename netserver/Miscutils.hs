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
		chan :: TChan String,
		handle :: Handle,
		nick :: String,
		protocol :: Word16,
		room :: String,
		isMaster :: Bool
	}

data RoomInfo =
	RoomInfo
	{
		name :: String,
		password :: String
	}

clientByHandle :: Handle -> [ClientInfo] -> ClientInfo
clientByHandle clhandle clients = fromJust $ find (\ci -> handle ci == clhandle) clients

fromRoomHandles :: String -> [ClientInfo] -> [Handle]
fromRoomHandles roomName clients = map (\ci -> handle ci) $ filter (\ci -> room ci == roomName) clients

modifyClient :: Handle -> [ClientInfo] -> (ClientInfo -> ClientInfo) -> [ClientInfo]
modifyClient clhandle (cl:cls) func =
	if handle cl == clhandle then
		(func cl) : cls
	else
		cl : (modifyClient clhandle cls func)

tselect :: [ClientInfo] -> STM (String, Handle)
tselect = foldl orElse retry . map (\ci -> (flip (,) $ handle ci) `fmap` readTChan (chan ci))

maybeRead :: Read a => String -> Maybe a
maybeRead s = case reads s of
	[(x, rest)] | all isSpace rest -> Just x
	_         -> Nothing

deleteBy2t :: (a -> b -> Bool) -> b -> [a] -> [a]
deleteBy2t _  _ [] = []
deleteBy2t eq x (y:ys) = if y `eq` x then ys else y : deleteBy2t eq x ys

deleteFirstsBy2t :: (a -> b -> Bool) -> [a] -> [b] -> [a]
deleteFirstsBy2t eq =  foldl (flip (deleteBy2t eq))
