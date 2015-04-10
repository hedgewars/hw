{-
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2014 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 \-}

{-# LANGUAGE ScopedTypeVariables, OverloadedStrings #-}

module Main where

import Prelude hiding (catch)
import Control.Monad
import Control.Exception
import System.IO
import Data.Maybe
import Database.MySQL.Simple
import Database.MySQL.Simple.QueryResults
import Database.MySQL.Simple.Result
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
                results <- query dbConn dbQueryAccount $ Only clNick
                let response = case results of
                        [(pass, adm, contr)] ->
                            (
                                clId,
                                clUid,
                                HasAccount
                                    (pass)
                                    (adm == Just (1 :: Int))
                                    (contr == Just (1 :: Int))
                            )
                        _ ->
                            (clId, clUid, Guest)
                print response
                hFlush stdout

        GetReplayName clId clUid fileId -> do
                results <- query dbConn dbQueryReplayFilename $ Only fileId
                let fn = if null results then "" else fromOnly $ head results
                print (clId, clUid, ReplayName fn)
                hFlush stdout

        SendStats clients rooms ->
                void $ execute dbConn dbQueryStats (clients, rooms)
--StoreAchievements (B.pack fileName) (map toPair teams) info
        StoreAchievements p fileName teams info ->
            void $ executeMany dbConn dbQueryAchievement $ (parseStats p fileName teams) info


readTime = read . B.unpack . B.take 19 . B.drop 8


parseStats :: 
    Word16 
    -> B.ByteString 
    -> [(B.ByteString, B.ByteString)] 
    -> [B.ByteString] 
    -> [(B.ByteString, B.ByteString, B.ByteString, Int, B.ByteString, B.ByteString, Int)]
parseStats p fileName teams = ps
    where
    time = readTime fileName
    ps [] = []
    ps ("DRAW" : bs) = ps bs
    ps ("WINNERS" : n : bs) = ps $ drop (readInt_ n) bs
    ps ("ACHIEVEMENT" : typ : teamname : location : value : bs) =
        ( time
        , typ
        , fromMaybe "" (lookup teamname teams)
        , readInt_ value
        , fileName
        , location
        , fromIntegral p
        ) : ps bs
    ps (b:bs) = ps bs


dbConnectionLoop mySQLConnectionInfo =
    Control.Exception.handle (\(e :: SomeException) -> hPutStrLn stderr $ show e) $
        bracket
            (connect mySQLConnectionInfo)
            close
            dbInteractionLoop


--processRequest :: DBQuery -> IO String
--processRequest (CheckAccount clId clUid clNick clHost) = return $ show (clclId, clUid, Guest)

main = do
        dbHost <- getLine
        dbName <- getLine
        dbLogin <- getLine
        dbPassword <- getLine

        let mySQLConnectInfo = defaultConnectInfo {
            connectHost = dbHost
            , connectDatabase = dbName
            , connectUser = dbLogin
            , connectPassword = dbPassword
            }

        dbConnectionLoop mySQLConnectInfo
