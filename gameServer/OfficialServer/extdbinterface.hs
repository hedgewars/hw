{-
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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
import Control.Monad.State
import System.IO
import Data.Maybe
import Database.MySQL.Simple
import Database.MySQL.Simple.QueryResults
import Database.MySQL.Simple.Result
import Data.List (lookup, elem)
import qualified Data.ByteString.Char8 as B
import Data.Word
import Data.Int
--------------------------
import CoreTypes
import Utils

io = liftIO

dbQueryAccount =
    "SELECT CASE WHEN users.status = 1 THEN users.pass ELSE '' END, \
    \ (SELECT COUNT(users_roles.rid) FROM users_roles WHERE users.uid = users_roles.uid AND users_roles.rid = 3), \
    \ (SELECT COUNT(users_roles.rid) FROM users_roles WHERE users.uid = users_roles.uid AND users_roles.rid = 13) \
    \ FROM users WHERE users.name = ?"

dbQueryStats =
    "INSERT INTO gameserver_stats (players, rooms, last_update) VALUES (?, ?, UNIX_TIMESTAMP())"

dbQueryAchievement =
    "INSERT INTO achievements (time, typeid, userid, value, filename, location, protocol) \
    \ VALUES (?, (SELECT id FROM achievement_types WHERE name = ?), (SELECT uid FROM users WHERE name = ?), \
    \ ?, ?, ?, ?)"

dbQueryGamesHistory =
    "INSERT INTO rating_games (script, protocol, filename, time, vamp, ropes, infattacks) \
    \ VALUES (?, ?, ?, ?, ?, ?, ?)"

dbQueryGameId = "SELECT LAST_INSERT_ID()"

dbQueryGamesHistoryPlaces = "INSERT INTO rating_players (userid, gameid, place) \
    \ VALUES ((SELECT uid FROM users WHERE name = ?), ?, ?)"

dbQueryReplayFilename = "SELECT filename FROM achievements WHERE id = ?"

dbQueryBestTime = "SELECT MIN(value) FROM achievements WHERE location = ?"

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
        StoreAchievements p fileName teams g info ->
            parseStats dbConn p fileName teams g info


--readTime = read . B.unpack . B.take 19 . B.drop 8
readTime = B.take 19 . B.drop 8

parseStats :: 
    Connection
    -> Word16 
    -> B.ByteString 
    -> [(B.ByteString, B.ByteString)] 
    -> GameDetails
    -> [B.ByteString]
    -> IO ()
parseStats dbConn p fileName teams (GameDetails script infRopes vamp infAttacks) d = evalStateT (ps d) ("", maxBound)
    where
    time = readTime fileName
    ps :: [B.ByteString] -> StateT (B.ByteString, Int) IO ()
    ps [] = return ()
    ps ("DRAW" : bs) = do
        io $ execute dbConn dbQueryGamesHistory (script, (fromIntegral p) :: Int, fileName, time, vamp, infRopes, infAttacks)
        io $ places (map drawParams teams)
        ps bs
    ps ("WINNERS" : n : bs) = do
        let winNum = readInt_ n
        io $ execute dbConn dbQueryGamesHistory (script, (fromIntegral p) :: Int, fileName, time, vamp, infRopes, infAttacks)
        io $ places (map (placeParams (take winNum bs)) teams)
        ps (drop winNum bs)
    ps ("ACHIEVEMENT" : typ : teamname : location : value : bs) = do
        let result = readInt_ value
        io $ execute dbConn dbQueryAchievement
            ( time
            , typ
            , fromMaybe "" (lookup teamname teams)
            , result
            , fileName
            , location
            , (fromIntegral p) :: Int
            )
        modify $ \st@(l, s) -> if result < s then (location, result) else st
        ps bs
    ps ("GHOST_POINTS" : n : bs) = do
        let pointsNum = readInt_ n
        (location, time) <- get
        res <- io $ query dbConn dbQueryBestTime $ Only location
        let bestTime = case res of
                [Only a] -> a
                _ -> maxBound :: Int
        when (time < bestTime) $ do
            io $ writeFile (B.unpack $ "ghosts/" `B.append` sanitizeName location) $ show (map readInt_ $ take (2 * pointsNum) bs)
            return ()
        ps (drop (2 * pointsNum) bs)
    ps (b:bs) = ps bs

    drawParams t = (snd t, 0 :: Int)
    placeParams winners t = (snd t, if (fst t) `elem` winners then 1 else 2 :: Int)
    places :: [(B.ByteString, Int)] -> IO Int64
    places params = do
        res <- query_ dbConn dbQueryGameId
        let gameId = case res of
                [Only a] -> a
                _ -> 0
        mapM_ (execute dbConn dbQueryGamesHistoryPlaces . midInsert gameId) params
        return 0
    midInsert :: Int -> (a, b) -> (a, Int, b)
    midInsert g (a, b) = (a, g, b)

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
