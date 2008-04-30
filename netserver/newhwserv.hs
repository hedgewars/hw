module Main where

import Network
import IO
import System.IO
import Control.Concurrent
import Control.Concurrent.STM
import Control.Exception (finally)
import Control.Monad (forM, filterM, liftM)
import Miscutils

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
		Right (line, clhandle) -> do
			--handleCmd handle line
			clients' <- forM clients $
					\ci -> do
						hPutStrLn (handle ci) line
						hFlush (handle ci)
						return [ci]
					`catch` const (hClose (handle ci) >> return [])
			mainLoop servSock acceptChan (concat clients') rooms

startServer serverSocket = do
	acceptChan <- atomically newTChan
	forkIO $ acceptLoop serverSocket acceptChan
	mainLoop serverSocket acceptChan [] []

main = withSocketsDo $ do
	serverSocket <- listenOn $ Service "hedgewars"
	startServer serverSocket `finally` sClose serverSocket
