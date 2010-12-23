{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import Prelude hiding (catch)
import Control.Monad
import Control.Exception
import System.IO
import Maybe
import Database.HDBC
import Database.HDBC.MySQL
--------------------------
import CoreTypes


dbQueryAccount =
    "SELECT users.pass, users_roles.rid FROM users LEFT JOIN users_roles ON users.uid = users_roles.uid WHERE users.name = ?"

dbQueryStats =
    "UPDATE gameserver_stats SET players = ?, rooms = ?, last_update = UNIX_TIMESTAMP()"

dbInteractionLoop dbConn = forever $ do
    q <- (getLine >>= return . read)
    hPutStrLn stderr $ show q
    
    case q of
        CheckAccount clUid clNick _ -> do
                statement <- prepare dbConn dbQueryAccount
                execute statement [SqlString $ clNick]
                passAndRole <- fetchRow statement
                finish statement
                let response = 
                        if isJust passAndRole then
                        (
                            clUid,
                            HasAccount
                                (fromSql $ head $ fromJust $ passAndRole)
                                ((fromSql $ last $ fromJust $ passAndRole) == (Just (3 :: Int)))
                        )
                        else
                        (clUid, Guest)
                putStrLn (show response)
                hFlush stdout

        SendStats clients rooms ->
                run dbConn dbQueryStats [SqlInt32 $ fromIntegral clients, SqlInt32 $ fromIntegral rooms] >> return ()


dbConnectionLoop mySQLConnectionInfo =
    Control.Exception.handle (\(_ :: IOException) -> return ()) $ handleSqlError $
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
