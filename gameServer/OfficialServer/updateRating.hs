{-# LANGUAGE ScopedTypeVariables, OverloadedStrings #-}
module Main where

import Data.Maybe
import Data.TConfig
import qualified Data.ByteString.Char8 as B
import Database.MySQL.Simple
import Database.MySQL.Simple.QueryResults
import Database.MySQL.Simple.Result
import Control.Monad
import Control.Exception
import System.IO
import qualified  Data.Map as Map
------
import OfficialServer.Glicko2


queryEpochDates = "SELECT epoch, todatetime, todatetime + INTERVAL 1 week FROM rating_epochs WHERE epoch = (SELECT MAX(epoch) FROM rating_epochs)"
queryPreviousRatings = "SELECT v.userid, v.rating, v.rd, v.volatility FROM rating_values as v WHERE (v.epoch = (SELECT MAX(epoch) FROM rating_epochs))"
queryGameResults =
        "SELECT \
        \     p.userid \
        \     , p.place \
        \     , o.userid \
        \     , o.place \
        \     , COALESCE(vp.rating, 1500) \
        \     , COALESCE(vp.rd, 350) \
        \     , COALESCE(vp.volatility, 0.06) \
        \     , COALESCE(vo.rating, 1500) \
        \     , COALESCE(vo.rd, 350) \
        \     , COALESCE(vo.volatility, 0.06) \
        \ FROM \
        \     (SELECT epoch, todatetime FROM rating_epochs WHERE epoch = (SELECT MAX(epoch) FROM rating_epochs)) as e \
        \     JOIN rating_games as g ON (g.time BETWEEN e.todatetime AND e.todatetime + INTERVAL 1 WEEK - INTERVAL 1 SECOND) \
        \     JOIN rating_players as p ON (p.gameid = g.id) \
        \     JOIN rating_players as o ON (p.gameid = o.gameid AND p.userid <> o.userid AND (p.place = 0 OR (p.place <> o.place))) \
        \     LEFT OUTER JOIN rating_values as vp ON (vp.epoch = e.epoch AND vp.userid = p.userid) \
        \     LEFT OUTER JOIN rating_values as vo ON (vo.epoch = e.epoch AND vo.userid = o.userid) \
        \ GROUP BY p.userid, p.gameid, p.place \
        \ ORDER BY p.userid"

--Map Int (RatingData, [GameData])
calculateRatings dbConn = do
    initRatingData <- (Map.fromList . map fromDBrating) `fmap` query_ dbConn queryPreviousRatings
    return ()

    where
        fromDBrating (a, b, c, d) = (a, (RatingData b c d, []))



data DBConnectInfo = DBConnectInfo {
    dbHost
    , dbName
    , dbLogin
    , dbPassword :: B.ByteString
    }

cfgFileName :: String
cfgFileName = "hedgewars-server.ini"


readServerConfig :: ConnectInfo -> IO ConnectInfo
readServerConfig ci = do
    cfg <- readConfig cfgFileName
    return $ ci{
        connectHost = value "dbHost" cfg
        , connectDatabase = value "dbName" cfg
        , connectUser = value "dbLogin" cfg
        , connectPassword = value "dbPassword" cfg
    }
    where
        value n c = fromJust2 n $ getValue n c
        fromJust2 n Nothing = error $ "Missing config entry " ++ n
        fromJust2 _ (Just a) = a

dbConnectionLoop mySQLConnectionInfo =
    Control.Exception.handle (\(e :: SomeException) -> hPutStrLn stderr $ show e) $
        bracket
            (connect mySQLConnectionInfo)
            close
            calculateRatings

main = readServerConfig defaultConnectInfo >>= dbConnectionLoop
