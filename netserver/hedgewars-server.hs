module Main where

import Network
import IO
import System.IO
import Control.Concurrent
import Control.Concurrent.STM
import Control.Exception (setUncaughtExceptionHandler, handle, finally)
import Control.Monad
import Maybe (fromMaybe, isJust, fromJust)
import Data.List
import Miscutils
import HWProto
import Opts
import Data.Time

#if !defined(mingw32_HOST_OS)
import System.Posix
#endif

data Messages =
	Accept ClientInfo
	| ClientMessage ([String], ClientInfo)
	| CoreMessage [String]

messagesLoop :: TChan [String] -> IO()
messagesLoop messagesChan = forever $ do
	threadDelay (30 * 10^6) -- 30 seconds
	atomically $ writeTChan messagesChan ["PING"]

acceptLoop :: Socket -> TChan ClientInfo -> IO ()
acceptLoop servSock acceptChan = Control.Exception.handle (const $ putStrLn "exception on connect" >> acceptLoop servSock acceptChan) $ do
	(cHandle, host, _) <- accept servSock
	currentTime <- getCurrentTime
	putStrLn $ (show currentTime) ++ " new client: " ++ host
	cChan <- atomically newTChan
	forkIO $ clientLoop cHandle cChan
	atomically $ writeTChan acceptChan (ClientInfo cChan cHandle host currentTime"" 0 "" False False False)
	atomically $ writeTChan cChan ["ASKME"]
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
		`catch` (\e -> (clientOff $ show e) >> return ())
	where clientOff msg = atomically $ writeTChan chan ["QUIT", msg] -- if the client disconnects, we perform as if it sent QUIT message


sendAnswers [] _ clients _ = return clients
sendAnswers ((handlesFunc, answer):answers) client clients rooms = do
	let recipients = handlesFunc client clients rooms
	--unless (null recipients) $ putStrLn ("< " ++ (show answer))
	when (head answer == "NICK") $ putStrLn (show answer)

	clHandles' <- forM recipients $
		\ch -> Control.Exception.handle
			(\e -> if head answer == "BYE" then
					return [ch]
				else
					atomically $ writeTChan (chan $ fromJust $ clientByHandle ch clients) ["QUIT", show e] >> return []  -- cannot just remove
			) $
			do
			forM_ answer (\str -> hPutStrLn ch str)
			hPutStrLn ch ""
			hFlush ch
			if head answer == "BYE" then return [ch] else return []

	let outHandles = concat clHandles'
	unless (null outHandles) $ putStrLn ((show $ length outHandles) ++ " / " ++ (show $ length clients) ++ " : " ++ (show answer))
	mapM_ (\ch -> Control.Exception.handle (const $ putStrLn "error on hClose") (hClose ch)) outHandles
	let mclients = remove clients outHandles

	sendAnswers answers client mclients rooms
	where
		remove list rmClHandles = deleteFirstsBy2t (\ a b -> (Miscutils.handle a) == b) list rmClHandles


reactCmd :: [String] -> ClientInfo -> [ClientInfo] -> [RoomInfo] -> IO ([ClientInfo], [RoomInfo])
reactCmd cmd client clients rooms = do
	--putStrLn ("> " ++ show cmd)

	let (clientsFunc, roomsFunc, answers) = handleCmd client clients rooms $ cmd
	let mrooms = roomsFunc rooms
	let mclients = (clientsFunc clients)
	let mclient = fromMaybe client $ find (== client) mclients

	clientsIn <- sendAnswers answers mclient mclients mrooms
	let quitClient = find forceQuit $ clientsIn
	
	if isJust quitClient then
		reactCmd ["QUIT", "Kicked"] (fromJust quitClient) clientsIn mrooms
		else
		return (clientsIn, mrooms)


mainLoop :: TChan ClientInfo -> TChan [String] -> [ClientInfo] -> [RoomInfo] -> IO ()
mainLoop acceptChan messagesChan clients rooms = do
	r <- atomically $
		(Accept `fmap` readTChan acceptChan) `orElse`
		(ClientMessage `fmap` tselect clients) `orElse`
		(CoreMessage `fmap` readTChan messagesChan)
	case r of
		Accept ci -> do
			let sameHostClients = filter (\cl -> host ci == host cl) clients
			let haveJustConnected = not $ null $ filter (\cl -> connectTime ci `diffUTCTime` connectTime cl <= 5) sameHostClients
			
			when haveJustConnected $ do
				atomically $ writeTChan (chan ci) ["QUIT", "Reconnected too fast"]
				mainLoop acceptChan messagesChan (clients ++ [ci]) rooms
				
			mainLoop acceptChan messagesChan (clients ++ [ci]) rooms
		ClientMessage (cmd, client) -> do
			(clientsIn, mrooms) <- reactCmd cmd client clients rooms
			
			let hadRooms = (not $ null rooms) && (null mrooms)
				in unless ((not $ isDedicated globalOptions) && ((null clientsIn) || hadRooms)) $
					mainLoop acceptChan messagesChan clientsIn mrooms
		CoreMessage msg ->
			if not $ null $ clients then
				do
				let client = head clients -- don't care
				(clientsIn, mrooms) <- reactCmd msg client clients rooms
				mainLoop acceptChan messagesChan clientsIn mrooms
			else
				mainLoop acceptChan messagesChan clients rooms

startServer :: Socket -> IO()
startServer serverSocket = do
	acceptChan <- atomically newTChan
	forkIO $ acceptLoop serverSocket acceptChan
	
	messagesChan <- atomically newTChan
	forkIO $ messagesLoop messagesChan
	
	mainLoop acceptChan messagesChan [] []


main = withSocketsDo $ do
#if !defined(mingw32_HOST_OS)
	installHandler sigPIPE Ignore Nothing;
#endif
	putStrLn $ "Listening on port " ++ show (listenPort globalOptions)
	serverSocket <- listenOn $ PortNumber (listenPort globalOptions)
	startServer serverSocket `finally` sClose serverSocket
