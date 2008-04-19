module Miscutils where

import IO
import System.IO
import Control.Concurrent
import Control.Concurrent.STM
import Control.Exception (finally)

data ClientInfo =
	ClientInfo
	{
		handle :: Handle,
		nick :: String,
		room :: String,
		isMaster :: Bool
	}

data RoomInfo =
	RoomInfo
	{
		name :: String,
		password :: String
	}


sendMsg :: Handle -> String -> IO()
sendMsg clientHandle str = finally (return ()) (hPutStrLn clientHandle str >> hFlush clientHandle) -- catch exception when client tries to send to other

sendAll :: [Handle] -> String -> IO[()]
sendAll clientsList str = mapM (\x -> sendMsg x str) clientsList

sendOthers :: [Handle] -> Handle -> String -> IO[()]
sendOthers clientsList clientHandle str = sendAll (filter (/= clientHandle) clientsList) str

extractCmd :: String -> (String, [String])
extractCmd str = if ws == [] then ("", []) else (head ws, tail ws)
		where ws = words str

manipState :: TVar[a] -> ([a] -> [a]) -> IO()
manipState state op =
	atomically $ do
			ls <- readTVar state
			writeTVar state $ op ls

manipState2 :: TVar[ClientInfo] -> TVar[RoomInfo] -> ([ClientInfo] -> [RoomInfo] -> ([ClientInfo], [RoomInfo])) -> IO()
manipState2 state1 state2 op =
	atomically $ do
			ls1 <- readTVar state1
			ls2 <- readTVar state2
			let (ol1, ol2) = op ls1 ls2
			writeTVar state1 ol1
			writeTVar state2 ol2
	
