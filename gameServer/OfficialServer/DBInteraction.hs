{-# LANGUAGE CPP #-}
module OfficialServer.DBInteraction
(
	startDBConnection
) where

import Prelude hiding (catch);
import System.Process
import System.IO
import Control.Concurrent
import Control.Exception
import Control.Monad
import Monad
import Maybe
import System.Log.Logger
------------------------
import CoreTypes
import Utils

localAddressList = ["127.0.0.1", "0:0:0:0:0:0:0:1", "0:0:0:0:0:ffff:7f00:1"]

fakeDbConnection serverInfo = do
	q <- readChan $ dbQueries serverInfo
	case q of
		CheckAccount clUid _ clHost -> do
			writeChan (coreChan serverInfo) $ ClientAccountInfo (clUid,
				if clHost `elem` localAddressList then Admin else Guest)

	fakeDbConnection serverInfo


#if defined(OFFICIAL_SERVER)
-------------------------------------------------------------------
-- borrowed from base 4.0.0 ---------------------------------------
onException :: IO a -> IO b -> IO a                              --
onException io what = io `catch` \e -> do what                   --
                                          throw (e :: Exception) --
-- to be deleted --------------------------------------------------
-------------------------------------------------------------------


pipeDbConnectionLoop queries coreChan hIn hOut = do
	q <- readChan queries
	do
		hPutStrLn hIn $ show q
		hFlush hIn
	
		response <- hGetLine hOut >>= (maybeException . maybeRead)

		writeChan coreChan $ ClientAccountInfo response
		`onException`
			(unGetChan queries q)
	where
		maybeException (Just a) = return a
		maybeException Nothing = ioError (userError "Can't read")


pipeDbConnection serverInfo = forever $ do
	Control.Exception.handle (\e -> warningM "Database" $ show e) $ do
			(Just hIn, Just hOut, _, _) <-
				createProcess (proc "./OfficialServer/extdbinterface" []) {std_in = CreatePipe, std_out = CreatePipe }

			hSetBuffering hIn LineBuffering
			hSetBuffering hOut LineBuffering

			hPutStrLn hIn $ dbHost serverInfo
			hPutStrLn hIn $ dbLogin serverInfo
			hPutStrLn hIn $ dbPassword serverInfo
			pipeDbConnectionLoop (dbQueries serverInfo) (coreChan serverInfo) hIn hOut

	threadDelay (5 * 10^6)


dbConnectionLoop = pipeDbConnection
#else
dbConnectionLoop = fakeDbConnection
#endif

startDBConnection serverInfo =
	if (not . null $ dbHost serverInfo) then
		forkIO $ dbConnectionLoop serverInfo
		else
		--forkIO $ fakeDbConnection serverInfo
		forkIO $ pipeDbConnection serverInfo
