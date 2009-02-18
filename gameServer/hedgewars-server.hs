{-# LANGUAGE CPP, ScopedTypeVariables, PatternSignatures #-}

module Main where

import Network.Socket
import qualified Network
import Control.Concurrent.STM
import Control.Concurrent.Chan
import Control.Exception
import System.Log.Logger
-----------------------------------
import Opts
import CoreTypes
import OfficialServer.DBInteraction
import ServerCore


#if !defined(mingw32_HOST_OS)
import System.Posix
#endif


{-data Messages =
	Accept ClientInfo
	| ClientMessage ([String], ClientInfo)
	| CoreMessage [String]
	| TimerTick

messagesLoop :: TChan String -> IO()
messagesLoop messagesChan = forever $ do
	threadDelay (25 * 10^6) -- 25 seconds
	atomically $ writeTChan messagesChan "PING"

timerLoop :: TChan String -> IO()
timerLoop messagesChan = forever $ do
	threadDelay (60 * 10^6) -- 60 seconds
	atomically $ writeTChan messagesChan "MINUTELY"-}

setupLoggers =
	updateGlobalLogger "Clients"
		(setLevel DEBUG)

main = withSocketsDo $ do
#if !defined(mingw32_HOST_OS)
	installHandler sigPIPE Ignore Nothing;
#endif

	setupLoggers

	stats <- atomically $ newTMVar (StatisticsInfo 0 0)
	--dbQueriesChan <- atomically newTChan
	coreChan <- newChan
	serverInfo <- getOpts $ newServerInfo stats -- dbQueriesChan
	
	bracket
		(Network.listenOn $ Network.PortNumber $ listenPort serverInfo)
		(sClose)
		(startServer serverInfo coreChan)
