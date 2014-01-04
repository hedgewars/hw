{-# LANGUAGE ScopedTypeVariables, OverloadedStrings #-}

module Main where

import Prelude hiding (catch)
import Control.Monad
import Control.Exception
import System.IO
import Data.Maybe
import Database.HDBC
import Database.HDBC.MySQL
import Data.List (lookup)
import qualified Data.ByteString.Char8 as B
import Data.Word
--------------------------
import CoreTypes
import Utils


dbQueryAccount =
    "SELECT users.pass, \ 
    \ (SELECT COUNT(users_roles.rid) FROM users_roles WHERE users.uid = users_roles.uid AND users_roles.rid = 3), \
    \ (SELECT COUNT(users_roles.rid) FROM users_roles WHERE users.uid = users_roles.uid AND users_roles.rid = 13) \
    \ FROM users WHERE users.name = ?"

dbQueryStats =
    "INSERT INTO gameserver_stats (players, rooms, last_update) VALUES (?, ?, UNIX_TIMESTAMP())"

dbQueryAchievement =
    "INSERT INTO achievements (time, typeid, userid, value, filename, location, protocol) \
    \ VALUES (?, (SELECT id FROM achievement_types WHERE name = ?), (SELECT uid FROM users WHERE name = ?), \
    \ ?, ?, ?, ?)"

dbQueryReplayFilename = "SELECT filename FROM achievements WHERE id = ?"


dbInteractionLoop dbConn = forever $ do
    q <- liftM read getLine
    hPutStrLn stderr $ show q

    case q of
        CheckAccount clId clUid clNick _ -> do
                statement <- prepare dbConn dbQueryAccount
                execute statement [SqlByteString clNick]
                result <- fetchRow statement
                finish statement
                let response =
                        if isJust result then let [pass, adm, contr] = fromJust result in
                        (
                            clId,
                            clUid,
                            HasAccount
                                (fromSql pass)
                                (fromSql adm == Just (1 :: Int))
                                (fromSql contr == Just (1 :: Int))
                        )
                        else
                        (clId, clUid, Guest)
                print response
                hFlush stdout

        GetReplayName clId clUid fileId -> do
                statement <- prepare dbConn dbQueryReplayFilename
                execute statement [SqlByteString fileId]
                result <- fetchRow statement
                finish statement
                let fn = if (isJust result) then fromJust . fromSql . head . fromJust $ result else ""
                print (clId, clUid, ReplayName fn)
                hFlush stdout

        SendStats clients rooms ->
                run dbConn dbQueryStats [SqlInt32 $ fromIntegral clients, SqlInt32 $ fromIntegral rooms] >> return ()
--StoreAchievements (B.pack fileName) (map toPair teams) info
        StoreAchievements p fileName teams info -> 
            mapM_ (run dbConn dbQueryAchievement) $ (parseStats p fileName teams) info


readTime = read . B.unpack . B.take 19 . B.drop 8


parseStats :: Word16 -> B.ByteString -> [(B.ByteString, B.ByteString)] -> [B.ByteString] -> [[SqlValue]]
parseStats p fileName teams = ps
    where
    time = readTime fileName
    ps [] = []
    ps ("DRAW" : bs) = ps bs
    ps ("WINNERS" : n : bs) = ps $ drop (readInt_ n) bs
    ps ("ACHIEVEMENT" : typ : teamname : location : value : bs) =
        [ SqlUTCTime time
        , SqlByteString typ
        , SqlByteString $ fromMaybe "" (lookup teamname teams)
        , SqlInt32 (readInt_ value)
        , SqlByteString fileName
        , SqlByteString location
        , SqlInt32 $ fromIntegral p
        ] : ps bs
    ps (b:bs) = ps bs


dbConnectionLoop mySQLConnectionInfo =
    Control.Exception.handle (\(e :: IOException) -> hPutStrLn stderr $ show e) $ handleSqlError $
        bracket
            (connectMySQL mySQLConnectionInfo)
            disconnect
            dbInteractionLoop


--processRequest :: DBQuery -> IO String
--processRequest (CheckAccount clId clUid clNick clHost) = return $ show (clclId, clUid, Guest)

main = do
        dbHost <- getLine
        dbName <- getLine
        dbLogin <- getLine
        dbPassword <- getLine

        let mySQLConnectInfo = defaultMySQLConnectInfo {mysqlHost = dbHost, mysqlDatabase = dbName, mysqlUser = dbLogin, mysqlPassword = dbPassword}

        dbConnectionLoop mySQLConnectInfo
