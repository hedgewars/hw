module OfficialServer.DBInteraction
(
	startDBConnection
) where

import Prelude hiding (catch);
import Database.HDBC
import Database.HDBC.MySQL
import System.IO
import Control.Concurrent
import Control.Exception
import Monad
import Maybe
import System.Log.Logger
------------------------
import CoreTypes


-------------------------------------------------------------------
-- borrowed from base 4.0.0 ---------------------------------------
onException :: IO a -> IO b -> IO a                              --
onException io what = io `catch` \e -> do what                   --
                                          throw (e :: Exception) --
-- to be deleted --------------------------------------------------
-------------------------------------------------------------------

dbQueryString =
	"SELECT users.pass, users_roles.rid FROM `users`, users_roles "
	++ "WHERE users.name = ? AND users_roles.uid = users.uid"

dbInteractionLoop queries coreChan dbConn = do
	q <- readChan queries
	case q of
		CheckAccount clID name -> do
				statement <- prepare dbConn dbQueryString
				execute statement [SqlString name]
				passAndRole <- fetchRow statement
				finish statement
				if isJust passAndRole then
					writeChan coreChan $
							ClientAccountInfo clID $
								HasAccount
									(fromSql $ head $ fromJust $ passAndRole)
									((fromSql $ last $ fromJust $ passAndRole) == (3 :: Int))
					else
					writeChan coreChan $ ClientAccountInfo clID Guest
			`onException`
				(unGetChan queries $ CheckAccount clID name)

	dbInteractionLoop queries coreChan dbConn

dbConnectionLoop serverInfo = do
	Control.Exception.handle (\e -> infoM "Database" $ show e) $ handleSqlError $
		bracket
			(connectMySQL defaultMySQLConnectInfo {mysqlHost = dbHost serverInfo, mysqlDatabase = "hedge_main", mysqlUser = dbLogin serverInfo, mysqlPassword = dbPassword serverInfo })
			(disconnect)
			(dbInteractionLoop (dbQueries serverInfo) (coreChan serverInfo))

	threadDelay (5 * 10^6)
	dbConnectionLoop serverInfo

startDBConnection serverInfo =
	when (not . null $ dbHost serverInfo) ((forkIO $ dbConnectionLoop serverInfo) >> return ())
