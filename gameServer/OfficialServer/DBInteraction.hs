{-# LANGUAGE CPP #-}
module OfficialServer.DBInteraction
(
	startDBConnection
) where

#if defined(OFFICIAL_SERVER)
import Database.HDBC
import Database.HDBC.MySQL
#endif

import Prelude hiding (catch);
import System.IO
import Control.Concurrent
import Control.Exception
import Monad
import Maybe
import System.Log.Logger
------------------------
import CoreTypes

localAddressList = ["127.0.0.1", "0:0:0:0:0:0:0:1", "0:0:0:0:0:ffff:7f00:1"]

fakeDbConnection serverInfo = do
	q <- readChan $ dbQueries serverInfo
	case q of
		CheckAccount client -> do
			writeChan (coreChan serverInfo) $ ClientAccountInfo (clientUID client) $
				if host client `elem` localAddressList then Admin else Guest

	fakeDbConnection serverInfo


-------------------------------------------------------------------
-- borrowed from base 4.0.0 ---------------------------------------
onException :: IO a -> IO b -> IO a                              --
onException io what = io `catch` \e -> do what                   --
                                          throw (e :: Exception) --
-- to be deleted --------------------------------------------------
-------------------------------------------------------------------

#if defined(OFFICIAL_SERVER)
dbQueryString =
	"select users.pass, users_roles.rid from users left join users_roles on users.uid = users_roles.uid where users.name = ?"

dbInteractionLoop queries coreChan dbConn = do
	q <- readChan queries
	case q of
		CheckAccount client -> do
				statement <- prepare dbConn dbQueryString
				execute statement [SqlString $ nick client]
				passAndRole <- fetchRow statement
				finish statement
				if isJust passAndRole then
					writeChan coreChan $
							ClientAccountInfo (clientUID client) $
								HasAccount
									(fromSql $ head $ fromJust $ passAndRole)
									((fromSql $ last $ fromJust $ passAndRole) == (Just (3 :: Int)))
					else
					writeChan coreChan $ ClientAccountInfo (clientUID client) Guest
			`onException`
				(unGetChan queries q)

	dbInteractionLoop queries coreChan dbConn

dbConnectionLoop serverInfo = do
	Control.Exception.handle (\e -> infoM "Database" $ show e) $ handleSqlError $
		bracket
			(connectMySQL defaultMySQLConnectInfo {mysqlHost = dbHost serverInfo, mysqlDatabase = "hedge_main", mysqlUser = dbLogin serverInfo, mysqlPassword = dbPassword serverInfo })
			(disconnect)
			(dbInteractionLoop (dbQueries serverInfo) (coreChan serverInfo))

	threadDelay (5 * 10^6)
	dbConnectionLoop serverInfo
#else
dbConnectionLoop = fakeDbConnection
#endif

startDBConnection serverInfo =
	if (not . null $ dbHost serverInfo) then
		forkIO $ dbConnectionLoop serverInfo
		else
		forkIO $ fakeDbConnection serverInfo
