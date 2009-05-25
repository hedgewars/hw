module Main where

import Prelude hiding (catch);
import Control.Monad
import Control.Exception
import System.IO
import Maybe
import Database.HDBC
import Database.HDBC.MySQL
--------------------------
import CoreTypes


dbQueryString =
	"select users.pass, users_roles.rid from users left join users_roles on users.uid = users_roles.uid where users.name = ?"

dbInteractionLoop dbConn = forever $ do
	q <- (getLine >>= return . read)
	
	response <- case q of
		CheckAccount clUid clNick _ -> do
				statement <- prepare dbConn dbQueryString
				execute statement [SqlString $ clNick]
				passAndRole <- fetchRow statement
				finish statement
				if isJust passAndRole then
					return $ (
								clUid,
								HasAccount
									(fromSql $ head $ fromJust $ passAndRole)
									((fromSql $ last $ fromJust $ passAndRole) == (Just (3 :: Int)))
							)
					else
					return $ (clUid, Guest)

	putStrLn (show response)
	hFlush stdout

dbConnectionLoop mySQLConnectionInfo =
	Control.Exception.handle (\e -> return ()) $ handleSqlError $
		bracket
			(connectMySQL mySQLConnectionInfo)
			(disconnect)
			(dbInteractionLoop)


processRequest :: DBQuery -> IO String
processRequest (CheckAccount clUid clNick clHost) = return $ show (clUid, Guest)

main = do
		dbHost <- getLine
		dbLogin <- getLine
		dbPassword <- getLine

		let mySQLConnectInfo = defaultMySQLConnectInfo {mysqlHost = dbHost, mysqlDatabase = "hedge_main", mysqlUser = dbLogin, mysqlPassword = dbPassword}

		dbConnectionLoop mySQLConnectInfo
