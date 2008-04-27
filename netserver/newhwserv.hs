module Main where

import Network
import IO
import System.IO
import Control.Concurrent
import Control.Concurrent.STM
import Control.Exception (finally)
import Control.Monad (forM, filterM, liftM)
import Miscutils

type Client = (TChan String, Handle)

acceptLoop :: Socket -> TChan Client -> IO ()
acceptLoop servSock acceptChan = do
	(cHandle, host, port) <- accept servSock
	cChan <- atomically newTChan
	forkIO $ clientLoop cHandle cChan
	atomically $ writeTChan acceptChan (cChan, cHandle)
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

mainLoop :: Socket -> TChan Client -> [Client] -> IO ()
mainLoop servSock acceptChan clients = do
	r <- atomically $ (Left `fmap` readTChan acceptChan) `orElse` (Right `fmap` tselect clients)
	case r of
		Left (ch, h) -> do
			mainLoop servSock acceptChan $ (ch, h):clients
		Right (line, handle) -> do
			clients' <- forM clients $
					\(ch, h) -> do
						hPutStrLn h line
						hFlush h
						return [(ch,h)]
					`catch` const (hClose h >> return [])
			mainLoop servSock acceptChan $ concat clients'

tselect :: [(TChan a, t)] -> STM (a, t)
tselect = foldl orElse retry . map (\(ch, ty) -> (flip (,) ty) `fmap` readTChan ch)

startServer serverSocket = do
	acceptChan <- atomically newTChan
	forkIO $ acceptLoop serverSocket acceptChan
	mainLoop serverSocket acceptChan []

main = withSocketsDo $ do
	serverSocket <- listenOn $ Service "hedgewars"
	startServer serverSocket `finally` sClose serverSocket
