module Main where

import Network
import IO
import System.IO
import Control.Concurrent
import Control.Concurrent.STM
import Control.Exception (setUncaughtExceptionHandler, handle, finally)
import Control.Monad (forM, forM_, filterM, liftM)
import Maybe (fromMaybe)
import Data.List
import Miscutils
import HWProto
import Opts

acceptLoop :: Socket -> TChan ClientInfo -> IO ()
acceptLoop servSock acceptChan = do
	(cHandle, host, port) <- accept servSock
	cChan <- atomically newTChan
	forkIO $ clientLoop cHandle cChan
	atomically $ writeTChan acceptChan (ClientInfo cChan cHandle "" 0 "" False)
	hPutStrLn cHandle "CONNECTED\n"
	hFlush cHandle
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
	where clientOff = atomically $ writeTChan chan ["QUIT"] -- if the client disconnects, we perform as if it sent QUIT message


sendAnswers [] _ clients _ = return clients
sendAnswers ((handlesFunc, answer):answers) client clients rooms = do
	let recipients = handlesFunc client clients rooms
	putStrLn ("< " ++ (show answer))

	clHandles' <- forM recipients $
		\ch -> Control.Exception.handle (\e -> putStrLn (show e) >> hClose ch >> return [ch]) $
			if (not $ null answer) && (head answer == "off") then hClose ch >> return [ch] else -- probably client with exception, don't send him anything
			do
			forM_ answer (\str -> hPutStrLn ch str)
			hPutStrLn ch ""
			hFlush ch
			if (not $ null answer) && (head answer == "BYE") then hClose ch >> return [ch] else return []

	let mclients = remove clients $ concat clHandles'

	sendAnswers answers client mclients rooms
	where
		remove list rmClHandles = deleteFirstsBy2t (\ a b -> (Miscutils.handle a) == b) list rmClHandles


mainLoop :: Socket -> TChan ClientInfo -> [ClientInfo] -> [RoomInfo] -> IO ()
mainLoop servSock acceptChan clients rooms = do
	r <- atomically $ (Left `fmap` readTChan acceptChan) `orElse` (Right `fmap` tselect clients)
	case r of
		Left ci -> do
			mainLoop servSock acceptChan (ci:clients) rooms
		Right (cmd, client) -> do
			putStrLn ("> " ++ show cmd)

			let (clientsFunc, roomsFunc, answers) = handleCmd client clients rooms $ cmd
			let mrooms = roomsFunc rooms
			let mclients = (clientsFunc clients)
			let mclient = fromMaybe client $ find (== client) mclients

			clientsIn <- sendAnswers answers mclient mclients mrooms
			
			mainLoop servSock acceptChan clientsIn mrooms


startServer serverSocket = do
	acceptChan <- atomically newTChan
	forkIO $ acceptLoop serverSocket acceptChan
	mainLoop serverSocket acceptChan [] []


main = withSocketsDo $ do
	flags <- opts
	putStrLn $ "Listening on port " ++ show (getPort flags)
	serverSocket <- listenOn $ PortNumber (getPort flags)
	startServer serverSocket `finally` sClose serverSocket
