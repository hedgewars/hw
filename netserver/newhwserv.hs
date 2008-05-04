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
	where clientOff = atomically $ writeTChan chan "QUIT"

mainLoop :: Socket -> TChan ClientInfo -> [ClientInfo] -> [RoomInfo] -> IO ()
mainLoop servSock acceptChan clients rooms = do
	r <- atomically $ (Left `fmap` readTChan acceptChan) `orElse` (Right `fmap` tselect clients)
	case r of
		Left ci -> do
			mainLoop servSock acceptChan (ci:clients) rooms
		Right (line, clhandle) -> do
			let (mclients, mrooms, recipients, strs) = handleCmd clhandle clients rooms $ words line

			clHandles' <- forM recipients $
					\ch -> do
							forM_ strs (\str -> hPutStrLn ch str)
							hFlush ch
							if (not $ null strs) && (head strs == "ROOMABANDONED") then hClose ch >> return [ch] else return []
					`catch` const (hClose ch >> return [ch])

			clHandle' <- if (not $ null strs) && (head strs == "QUIT") then hClose clhandle >> return [clhandle] else return []

			mainLoop servSock acceptChan (remove (remove mclients (concat clHandles')) clHandle') mrooms
			where
				remove list rmClHandles = deleteFirstsBy2t (\ a b -> (handle a) == b) list rmClHandles

startServer serverSocket = do
	acceptChan <- atomically newTChan
	forkIO $ acceptLoop serverSocket acceptChan
	mainLoop serverSocket acceptChan [] []

main = withSocketsDo $ do
	serverSocket <- listenOn $ Service "hedgewars"
	startServer serverSocket `finally` sClose serverSocket
