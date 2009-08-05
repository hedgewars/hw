{-# LANGUAGE CPP, PatternSignatures #-}
module NetRoutines where

import Network
import Network.Socket
import System.IO
import Control.Concurrent
import Control.Concurrent.Chan
import Control.Concurrent.STM
#if defined(NEW_EXCEPTIONS)
import qualified Control.OldException as Exception
#else
import qualified Control.Exception as Exception
#endif
import Data.Time
-----------------------------
import CoreTypes
import ClientIO
import Utils

acceptLoop :: Socket -> Chan CoreMessage -> Int -> IO ()
acceptLoop servSock coreChan clientCounter = do
	Exception.handle
		(\(_ :: Exception.Exception) -> putStrLn "exception on connect") $
		do
		(socket, sockAddr) <- Network.Socket.accept servSock

		cHandle <- socketToHandle socket ReadWriteMode
		hSetBuffering cHandle LineBuffering
		clientHost <- sockAddr2String sockAddr

		currentTime <- getCurrentTime
		
		sendChan <- newChan

		let newClient =
				(ClientInfo
					nextID
					sendChan
					cHandle
					clientHost
					currentTime
					""
					""
					False
					0
					0
					0
					False
					False
					False
					undefined
					)

		writeChan coreChan $ Accept newClient

		forkIO $ clientRecvLoop cHandle coreChan nextID
		forkIO $ clientSendLoop cHandle coreChan sendChan nextID
		return ()

	acceptLoop servSock coreChan nextID
	where
		nextID = clientCounter + 1
