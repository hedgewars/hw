{-# LANGUAGE CPP, ScopedTypeVariables, PatternSignatures #-}

module Main where

import qualified Network
import Network.Socket
import IO
import System.IO
import Control.Concurrent
import Control.Concurrent.STM
import Control.Exception (handle, finally, Exception, IOException)
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

acceptLoop :: Socket -> TChan ClientInfo -> IO ()
acceptLoop servSock acceptChan =
	Control.Exception.handle (\(_ :: Exception) -> putStrLn "exception on connect" >> acceptLoop servSock acceptChan) $
	do
	(cHandle, host, _) <- Network.accept servSock
	
	currentTime <- getCurrentTime
	putStrLn $ (show currentTime) ++ " new client: " ++ host
	
	cChan <- atomically newTChan
	sendChan <- atomically newTChan
	forkIO $ clientRecvLoop cHandle cChan
	forkIO $ clientSendLoop cHandle cChan sendChan
	
	atomically $ writeTChan acceptChan
			(ClientInfo
				cChan
				sendChan
				cHandle
				host
				currentTime
				""
				0
				""
				False
				False
				False
				False)

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


clientRecvLoop :: Handle -> TChan [String] -> IO ()
clientRecvLoop handle chan =
	listenLoop handle [] chan
		`catch` (\e -> (clientOff $ show e) >> return ())
	where clientOff msg = atomically $ writeTChan chan ["QUIT", msg] -- if the client disconnects, we perform as if it sent QUIT message

clientSendLoop :: Handle -> TChan[String] -> TChan[String] -> IO()
clientSendLoop handle clChan chan = do
	answer <- atomically $ readTChan chan
	doClose <- Control.Exception.handle
		(\(e :: Exception) -> if isQuit answer then return True else sendQuit e >> return False) $ do
		forM_ answer (\str -> hPutStrLn handle str)
		hPutStrLn handle ""
		hFlush handle
		return $ isQuit answer

	if doClose then
		Control.Exception.handle (\(_ :: Exception) -> putStrLn "error on hClose") $ hClose handle
		else
		clientSendLoop handle clChan chan

	where
		sendQuit e = atomically $ writeTChan clChan ["QUIT", show e]
		isQuit answer = head answer == "BYE"

sendAnswers  [] _ clients _ = return clients
sendAnswers ((handlesFunc, answer):answers) client clients rooms = do
	let recipients = handlesFunc client clients rooms
	--unless (null recipients) $ putStrLn ("< " ++ (show answer))
	when (head answer == "NICK") $ putStrLn (show answer)

	clHandles' <- forM recipients $
		\ch ->
			do
			atomically $ writeTChan (sendChan ch) answer
			if head answer == "BYE" then return [ch] else return []

	let outHandles = concat clHandles'
	unless (null outHandles) $ putStrLn ((show $ length outHandles) ++ " / " ++ (show $ length clients) ++ " : " ++ (show answer))

	let mclients = clients \\ outHandles

	sendAnswers answers client mclients rooms


reactCmd :: ServerInfo -> [String] -> ClientInfo -> [ClientInfo] -> [RoomInfo] -> IO ([ClientInfo], [RoomInfo])
reactCmd serverInfo cmd client clients rooms = do
	--putStrLn ("> " ++ show cmd)

	let (clientsFunc, roomsFunc, answerFuncs) = handleCmd client clients rooms $ cmd
	let mrooms = roomsFunc rooms
	let mclients = (clientsFunc clients)
	let mclient = fromMaybe client $ find (== client) mclients
	let answers = map (\x -> x serverInfo) answerFuncs

	clientsIn <- sendAnswers answers mclient mclients mrooms
	mapM_ (\cl -> atomically $ writeTChan (chan cl) ["QUIT", "Kicked"]) $ filter forceQuit $ clientsIn

	let clientsFinal = map (\cl -> if partRoom cl then cl{room = [], partRoom = False} else cl) clientsIn
	return (clientsFinal, mrooms)


mainLoop :: ServerInfo -> TChan ClientInfo -> TChan [String] -> [ClientInfo] -> [RoomInfo] -> IO ()
mainLoop serverInfo acceptChan messagesChan clients rooms = do
	r <- atomically $
		(Accept `fmap` readTChan acceptChan) `orElse`
		(ClientMessage `fmap` tselect clients) `orElse`
		(CoreMessage `fmap` readTChan messagesChan)
	
	case r of
		Accept ci -> do
			let sameHostClients = filter (\cl -> host ci == host cl) clients
			let haveJustConnected = not $ null $ filter (\cl -> connectTime ci `diffUTCTime` connectTime cl <= 25) sameHostClients
			
			when haveJustConnected $ do
				atomically $ do
					writeTChan (chan ci) ["QUIT", "Reconnected too fast"]

			currentTime <- getCurrentTime
			let newServerInfo = serverInfo{
					loginsNumber = loginsNumber serverInfo + 1,
					lastHourUsers = currentTime : lastHourUsers serverInfo
					}
			mainLoop newServerInfo acceptChan messagesChan (clients ++ [ci]) rooms
			
		ClientMessage (cmd, client) -> do
			(clientsIn, mrooms) <- reactCmd serverInfo cmd client clients rooms
			
			let hadRooms = (not $ null rooms) && (null mrooms)
				in unless ((not $ isDedicated serverInfo) && ((null clientsIn) || hadRooms)) $
					mainLoop serverInfo acceptChan messagesChan clientsIn mrooms
		
		CoreMessage msg -> case msg of
			["PING"] ->
				if not $ null $ clients then
					do
					let client = head clients -- don't care
					(clientsIn, mrooms) <- reactCmd serverInfo msg client clients rooms
					mainLoop serverInfo acceptChan messagesChan clientsIn mrooms
				else
					mainLoop serverInfo acceptChan messagesChan clients rooms
			["MINUTELY"] -> do
				currentTime <- getCurrentTime
				let newServerInfo = serverInfo{
						lastHourUsers = filter (\t -> currentTime `diffUTCTime` t < 3600) $ lastHourUsers serverInfo
						}
				atomically $ swapTMVar
					(stats serverInfo)
					(StatisticsInfo
						(length clients)
						(length rooms)
					)
				mainLoop newServerInfo acceptChan messagesChan clients rooms

startServer :: ServerInfo -> Socket -> IO()
startServer serverInfo serverSocket = do
	acceptChan <- atomically newTChan
	forkIO $ acceptLoop serverSocket acceptChan
	
	messagesChan <- atomically newTChan
	forkIO $ messagesLoop messagesChan
	forkIO $ timerLoop messagesChan

	mainLoop serverInfo acceptChan messagesChan [] []

socketEcho :: Socket -> TMVar StatisticsInfo -> IO ()
socketEcho sock stats = do
	(msg, recv_count, client) <- recvFrom sock 128
	currStats <- atomically $ readTMVar stats
	send_count <- sendTo sock (statsMsg1 currStats) client
	socketEcho sock stats
	where
		statsMsg1 currStats = (show $ playersNumber currStats) ++ "," ++ (show $ roomsNumber currStats)

startUDPserver :: TMVar StatisticsInfo -> IO ThreadId
startUDPserver stats = do
	sock <- socket AF_INET Datagram 0
	bindSocket sock (SockAddrInet 46632 iNADDR_ANY)
	forkIO $ socketEcho sock stats

main = withSocketsDo $ do
#if !defined(mingw32_HOST_OS)
	installHandler sigPIPE Ignore Nothing;
#endif

	stats <- atomically $ newTMVar (StatisticsInfo 0 0)
	serverInfo <- getOpts $ newServerInfo stats
	
	putStrLn $ "Listening on port " ++ show (listenPort serverInfo)
	serverSocket <- Network.listenOn $ Network.PortNumber (listenPort serverInfo)

	startUDPserver stats
	startServer serverInfo serverSocket `finally` sClose serverSocket
