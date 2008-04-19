module Main where

import Network
import IO
import System.IO
import Control.Concurrent
import Control.Concurrent.STM
import Control.Exception (finally)
import Miscutils


handleCmd :: Handle -> TVar[ClientInfo] -> TVar[RoomInfo] -> (String, [String]) -> IO()
handleCmd clientHandle clientsList roomsList ("SAY", param) = do
		ls <- atomically(readTVar clientsList)
		sendOthers (map (\x -> handle x) ls) clientHandle (concat param)
		return ()

handleCmd clientHandle clientsList roomsList ("CREATE", [roomname]) = do
		manipState2 clientsList roomsList (hcCreate)
		sendMsg clientHandle ("JOINED " ++ roomname)
		where
			hcCreate ci ri = if (null $ filter (\ xr -> roomname == name xr) ri) then
				(map
					(\ xc
						-> if (clientHandle == handle xc) then
								xc {isMaster = True, room = roomname}
							else
								xc)
					ci,
					(RoomInfo roomname "") : ri)
				else
					(ci, ri)

handleCmd clientHandle clientsList roomsList ("LIST", []) = do
		rl <- atomically $ readTVar roomsList
		sendMsg clientHandle (unlines $ map (\x -> name x) rl)

handleCmd clientHandle _ _ ("PING", _) = sendMsg clientHandle "PONG"

handleCmd clientHandle _ _ (_, _) = sendMsg clientHandle "Unknown cmd or bad syntax"


clientLoop :: Handle -> TVar[ClientInfo] -> TVar[RoomInfo] -> IO()
clientLoop clientHandle clientsList roomsList = do
		cline <- hGetLine clientHandle
		let (cmd, params) = extractCmd cline
		handleCmd clientHandle clientsList roomsList (cmd, params)
		if cmd /= "QUIT" then clientLoop clientHandle clientsList roomsList else return ()


main = do
	clientsList <- atomically $ newTVar[]
	roomsList <- atomically $ newTVar[]
	bracket
		(listenOn $ Service "hedgewars")
		(sClose)
		(loop clientsList roomsList)
		where
			loop clist rlist sock = accept sock >>= addClient clist rlist >> loop clist rlist sock

			addClient clist rlist (chandle, hostname, port) = do
				putStrLn $ "Client connected: " ++ show hostname
				hSetBuffering chandle LineBuffering
				manipState clist (\x -> (ClientInfo chandle "" "" False):x) -- add client to list
				forkIO $ finally
					(clientLoop chandle clist rlist)
					(do
					manipState clist (\x -> filter (\x -> chandle /= handle x) x) -- remove client from list
					hClose chandle)
