module OfficialServer.DBInteraction
(
	startDBConnection,
	DBQuery(HasRegistered, CheckPassword)
) where

import Database.HDBC
import Database.HDBC.MySQL

import System.IO
import Control.Concurrent
import Control.Concurrent.STM
import Control.Exception

data DBQuery =
	HasRegistered String
	| CheckPassword String

dbInteractionLoop queries dbConn = do
	q <- atomically $ readTChan queries
	case q of
		HasRegistered queryStr -> putStrLn queryStr
		CheckPassword queryStr -> putStrLn queryStr

	dbInteractionLoop queries dbConn

dbConnectionLoop queries = do
	Control.Exception.handle (\e -> print e) $ handleSqlError $
		bracket
			(connectMySQL defaultMySQLConnectInfo { mysqlHost = "192.168.50.5", mysqlDatabase = "glpi" })
			(disconnect)
			(dbInteractionLoop queries)

	threadDelay (15 * 10^6)
	dbConnectionLoop queries

startDBConnection queries = forkIO $ dbConnectionLoop queries
