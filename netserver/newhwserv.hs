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
	atomically $ writeTChan acceptChan (ClientInfo cChan cHandle "" "" False)
	acceptLoop servSock acceptChan

listenLoop :: Handle -> TChan String -> IO ()
listenLoop handle chan = do
	str <- hGetLine handle
	atomically $ writeTChan chan str
	listenLoop handle chan

clientLoop :: Handle -> TChan String -> IO ()
clientLoop handle chan =
	listenLoop handle chan
		`catch` (const $ clientOff >> return ())
		`finally` hClose handle
	where clientOff = atomically $ writeTChan chan "QUIT"

mainLoop :: Socket -> TChan ClientInfo -> [ClientInfo] -> [RoomInfo] -> IO ()
mainLoop servSock acceptChan clients rooms = do
	r <- atomically $ (Left `fmap` readTChan acceptChan) `orElse` (Right `fmap` tselect clients)
	case r of
		Left ci -> do
			mainLoop servSock acceptChan (ci:clients) rooms
		Right (line, client) -> do
			let (doQuit, toMe, strs) = handleCmd client sameRoom rooms line

			clients' <- forM sameRoom $
					\ci -> do
						if (handle ci /= handle client) || toMe then do
							forM_ strs (\str -> hPutStrLn (handle ci) str)
							hFlush (handle ci)
							return []
							else if doQuit then return [ci] else return []
					`catch` const (hClose (handle ci) >> return [ci])

			mainLoop servSock acceptChan (deleteFirstsBy (\ a b -> handle a == handle b) clients (concat clients')) rooms
			where
				sameRoom = filter (\cl -> room cl == room client) clients

startServer serverSocket = do
	acceptChan <- atomically newTChan
	forkIO $ acceptLoop serverSocket acceptChan
	mainLoop serverSocket acceptChan [] []

main = withSocketsDo $ do
	serverSocket <- listenOn $ Service "hedgewars"
	startServer serverSocket `finally` sClose serverSocket
