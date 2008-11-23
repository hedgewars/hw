{-# LANGUAGE CPP #-}
module Main where

import Network
import IO
import System.IO
import Control.Concurrent
import Control.Concurrent.STM
import Control.Exception (handle, finally)
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
	| TimerTick

messagesLoop :: TChan [String] -> IO()
messagesLoop messagesChan = forever $ do
	threadDelay (25 * 10^6) -- 25 seconds
	atomically $ writeTChan messagesChan ["PING"]

timerLoop :: TChan [String] -> IO()
timerLoop messagesChan = forever $ do
	threadDelay (60 * 10^6) -- 60 seconds
	atomically $ writeTChan messagesChan ["MINUTELY"]

socketCloseLoop :: TChan Handle -> IO()
socketCloseLoop closingChan = forever $ do
	h <- atomically $ readTChan closingChan
	Control.Exception.handle (const $ putStrLn "error on hClose") $ hClose h

acceptLoop :: Socket -> TChan ClientInfo -> IO ()
acceptLoop servSock acceptChan =
	Control.Exception.handle (const $ putStrLn "exception on connect" >> acceptLoop servSock acceptChan) $
	do
	(cHandle, host, _) <- accept servSock
	
	currentTime <- getCurrentTime
	putStrLn $ (show currentTime) ++ " new client: " ++ host
	
	cChan <- atomically newTChan
	forkIO $ clientLoop cHandle cChan
	
	atomically $ writeTChan acceptChan (ClientInfo cChan cHandle host currentTime "" 0 "" False False False)
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


sendAnswers _ [] _ clients _ = return clients
sendAnswers closingChan ((handlesFunc, answer):answers) client clients rooms = do
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

	-- strange, but this seems to be a bad idea to manually close these handles as it causes hangs
	mapM_ (\ch -> atomically $ writeTChan closingChan ch) outHandles
	let mclients = remove clients outHandles

	sendAnswers closingChan answers client mclients rooms
	where
		remove list rmClHandles = deleteFirstsBy2t (\ a b -> (Miscutils.handle a) == b) list rmClHandles


reactCmd :: ServerInfo -> TChan Handle -> [String] -> ClientInfo -> [ClientInfo] -> [RoomInfo] -> IO ([ClientInfo], [RoomInfo])
reactCmd serverInfo closingChan cmd client clients rooms = do
	--putStrLn ("> " ++ show cmd)

	let (clientsFunc, roomsFunc, answerFuncs) = handleCmd client clients rooms $ cmd
	let mrooms = roomsFunc rooms
	let mclients = (clientsFunc clients)
	let mclient = fromMaybe client $ find (== client) mclients
	let answers = map (\x -> x serverInfo) answerFuncs

	clientsIn <- sendAnswers closingChan answers mclient mclients mrooms
	mapM_ (\cl -> atomically $ writeTChan (chan cl) ["QUIT", "Kicked"]) $ filter forceQuit $ clientsIn
	
	return (clientsIn, mrooms)


mainLoop :: ServerInfo -> TChan ClientInfo -> TChan [String] -> TChan Handle -> [ClientInfo] -> [RoomInfo] -> IO ()
mainLoop serverInfo acceptChan messagesChan closingChan clients rooms = do
	r <- atomically $
		(Accept `fmap` readTChan acceptChan) `orElse`
		(ClientMessage `fmap` tselect clients) `orElse`
		(CoreMessage `fmap` readTChan messagesChan)
	
	case r of
		Accept ci -> do
			let sameHostClients = filter (\cl -> host ci == host cl) clients
			let haveJustConnected = False--not $ null $ filter (\cl -> connectTime ci `diffUTCTime` connectTime cl <= 25) sameHostClients
			
			when haveJustConnected $ do
				atomically $ do
					--writeTChan (chan ci) ["ERROR", "Reconnected too fast"]
					writeTChan (chan ci) ["QUIT", "Reconnected too fast"]

			currentTime <- getCurrentTime
			let newServerInfo = serverInfo{
					loginsNumber = loginsNumber serverInfo + 1,
					lastHourUsers = currentTime : lastHourUsers serverInfo
					}
			mainLoop newServerInfo acceptChan messagesChan closingChan (clients ++ [ci]) rooms
			
		ClientMessage (cmd, client) -> do
			(clientsIn, mrooms) <- reactCmd serverInfo closingChan cmd client clients rooms
			
			let hadRooms = (not $ null rooms) && (null mrooms)
				in unless ((not $ isDedicated serverInfo) && ((null clientsIn) || hadRooms)) $
					mainLoop serverInfo acceptChan messagesChan closingChan clientsIn mrooms
		
		CoreMessage msg -> case msg of
			["PING"] ->
				if not $ null $ clients then
					do
					let client = head clients -- don't care
					(clientsIn, mrooms) <- reactCmd serverInfo closingChan msg client clients rooms
					mainLoop serverInfo acceptChan messagesChan closingChan clientsIn mrooms
				else
					mainLoop serverInfo acceptChan messagesChan closingChan clients rooms
			["MINUTELY"] -> do
				currentTime <- getCurrentTime
				let newServerInfo = serverInfo{
						lastHourUsers = filter (\t -> currentTime `diffUTCTime` t < 3600) $ lastHourUsers serverInfo
						}
				mainLoop newServerInfo acceptChan messagesChan closingChan clients rooms

startServer :: ServerInfo -> Socket -> IO()
startServer serverInfo serverSocket = do
	acceptChan <- atomically newTChan
	forkIO $ acceptLoop serverSocket acceptChan
	
	messagesChan <- atomically newTChan
	forkIO $ messagesLoop messagesChan
	forkIO $ timerLoop messagesChan

	closingChan <- atomically newTChan
	forkIO $ socketCloseLoop closingChan

	mainLoop serverInfo acceptChan messagesChan closingChan [] []


main = withSocketsDo $ do
#if !defined(mingw32_HOST_OS)
	installHandler sigPIPE Ignore Nothing;
#endif
	serverInfo <- getOpts $ newServerInfo
	
	putStrLn $ "Listening on port " ++ show (listenPort serverInfo)
	serverSocket <- listenOn $ PortNumber (listenPort serverInfo)
	
	startServer serverInfo serverSocket `finally` sClose serverSocket
