module Main where

import Network
import IO
import System.IO
import Control.Concurrent
import Control.Concurrent.STM
import Control.Exception (setUncaughtExceptionHandler, handle, finally)
import Control.Monad (forM, forM_, filterM, liftM, when, unless)
import Maybe (fromMaybe, isJust, fromJust)
import Data.List
import Miscutils
import HWProto
import Opts
import System.Posix

acceptLoop :: Socket -> TChan ClientInfo -> IO ()
acceptLoop servSock acceptChan = do
	(cHandle, host, port) <- accept servSock
	hPutStrLn cHandle "CONNECTED\n"
	hFlush cHandle
	cChan <- atomically newTChan
	forkIO $ clientLoop cHandle cChan
	atomically $ writeTChan acceptChan (ClientInfo cChan cHandle "" 0 "" False False)
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
	unless (null recipients) $ putStrLn ("< " ++ (show answer))

	clHandles' <- forM recipients $
		\ch -> Control.Exception.handle (\e -> putStrLn ("handle exception: " ++ show e) >> if head answer == "BYE" then return [ch] else return []) $ -- cannot just remove
			do
			forM_ answer (\str -> hPutStrLn ch str)
			hPutStrLn ch ""
			hFlush ch
			if head answer == "BYE" then hClose ch >> return [ch] else return []

	let mclients = remove clients $ concat clHandles'

	sendAnswers answers client mclients rooms
	where
		remove list rmClHandles = deleteFirstsBy2t (\ a b -> (Miscutils.handle a) == b) list rmClHandles


reactCmd :: [String] -> ClientInfo -> [ClientInfo] -> [RoomInfo] -> IO ([ClientInfo], [RoomInfo])
reactCmd cmd client clients rooms = do
	putStrLn ("> " ++ show cmd)

	let (clientsFunc, roomsFunc, answers) = handleCmd client clients rooms $ cmd
	let mrooms = roomsFunc rooms
	let mclients = (clientsFunc clients)
	let mclient = fromMaybe client $ find (== client) mclients

	clientsIn <- sendAnswers answers mclient mclients mrooms
	let quitClient = find forceQuit $ clientsIn
	if isJust quitClient then reactCmd ["QUIT"] (fromJust quitClient) clientsIn mrooms else return (clientsIn, mrooms)


mainLoop :: Socket -> TChan ClientInfo -> [ClientInfo] -> [RoomInfo] -> IO ()
mainLoop servSock acceptChan clients rooms = do
	r <- atomically $ (Left `fmap` readTChan acceptChan) `orElse` (Right `fmap` tselect clients)
	case r of
		Left ci -> do
			mainLoop servSock acceptChan (clients ++ [ci]) rooms
		Right (cmd, client) -> do
			(clientsIn, mrooms) <- reactCmd cmd client clients rooms
			
			let hadRooms = (not $ null rooms) && (null mrooms)
				in unless ((not $ isDedicated globalOptions) && ((null clientsIn) || hadRooms)) $
					mainLoop servSock acceptChan clientsIn mrooms


startServer serverSocket = do
	acceptChan <- atomically newTChan
	forkIO $ acceptLoop serverSocket acceptChan
	mainLoop serverSocket acceptChan [] []


main = withSocketsDo $ do
	installHandler sigPIPE Ignore Nothing;
	putStrLn $ "Listening on port " ++ show (listenPort globalOptions)
	serverSocket <- listenOn $ PortNumber (listenPort globalOptions)
	startServer serverSocket `finally` sClose serverSocket
