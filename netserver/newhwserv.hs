module Main where

import Network
import IO
import System.IO
import Control.Concurrent
import Control.Concurrent.STM
import Control.Exception (finally)
import Control.Monad (forM, forM_, filterM, liftM)
import Data.List
import Miscutils
import HWProto

acceptLoop :: Socket -> TChan ClientInfo -> IO ()
acceptLoop servSock acceptChan = do
	(cHandle, host, port) <- accept servSock
	cChan <- atomically newTChan
	forkIO $ clientLoop cHandle cChan
	atomically $ writeTChan acceptChan (ClientInfo cChan cHandle "" 0 "" False)
	hPutStrLn cHandle "CONNECTED\n"
	acceptLoop servSock acceptChan

listenLoop :: Handle -> [String] -> TChan [String] -> IO ()
listenLoop handle buf chan = do
	str <- hGetLine handle
	if str == "" then do
		atomically $ writeTChan chan buf
		listenLoop handle [] chan
		else
		listenLoop handle (buf ++ [str]) chan

clientLoop :: Handle -> TChan [String] -> IO ()
clientLoop handle chan =
	listenLoop handle [] chan
		`catch` (const $ clientOff >> return ())
	where clientOff = atomically $ writeTChan chan ["QUIT"] -- если клиент отключается, то делаем вид, что от него пришла команда QUIT

mainLoop :: Socket -> TChan ClientInfo -> [ClientInfo] -> [RoomInfo] -> IO ()
mainLoop servSock acceptChan clients rooms = do
	r <- atomically $ (Left `fmap` readTChan acceptChan) `orElse` (Right `fmap` tselect clients)
	case r of
		Left ci -> do
			mainLoop servSock acceptChan (ci:clients) rooms
		Right (cmd, client) -> do
			putStrLn ("> " ++ show cmd)
			let (clientsFunc, roomsFunc, answers) = handleCmd client clients rooms $ cmd

			let mclients = clientsFunc clients
			let mrooms = roomsFunc rooms

			clHandles' <- forM answers $
				\(handlesFunc, answer) -> do
					putStrLn ("< " ++ show answer)
					let recipients = handlesFunc client mclients mrooms
					forM recipients $
						\ch -> do
							forM_ answer (\str -> hPutStrLn ch str)
							hPutStrLn ch ""
							hFlush ch
							if (not $ null answer) && (head answer == "BYE") then hClose ch >> return [ch] else return []
						`catch` const (hClose ch >> return [ch])

			mainLoop servSock acceptChan (remove mclients (concat $ concat clHandles')) mrooms
			where
				remove list rmClHandles = deleteFirstsBy2t (\ a b -> (handle a) == b) list rmClHandles

startServer serverSocket = do
	acceptChan <- atomically newTChan
	forkIO $ acceptLoop serverSocket acceptChan
	mainLoop serverSocket acceptChan [] []

main = withSocketsDo $ do
	serverSocket <- listenOn $ Service "hedgewars"
	startServer serverSocket `finally` sClose serverSocket
