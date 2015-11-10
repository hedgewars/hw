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

{-# LANGUAGE CPP, ScopedTypeVariables, OverloadedStrings #-}
module OfficialServer.DBInteraction
(
    startDBConnection
) where

import Prelude hiding (catch);
import Control.Concurrent
import Control.Monad
import Data.List as L
import Data.ByteString.Char8 as B
#if defined(OFFICIAL_SERVER)
import System.Process
import System.IO as SIO
import qualified Control.Exception as Exception
import qualified Data.Map as Map
import Data.Maybe
import Data.Time
import System.Log.Logger
#endif
------------------------
import CoreTypes
#if defined(OFFICIAL_SERVER)
import Utils
#endif

localAddressList :: [B.ByteString]
localAddressList = ["127.0.0.1", "0:0:0:0:0:0:0:1", "0:0:0:0:0:ffff:7f00:1"]

fakeDbConnection :: forall b. ServerInfo -> IO b
fakeDbConnection si = forever $ do
    q <- readChan $ dbQueries si
    case q of
        CheckAccount clId clUid _ clHost ->
            writeChan (coreChan si) $ ClientAccountInfo clId clUid (if clHost `L.elem` localAddressList then Admin else Guest)
        ClearCache -> return ()
        SendStats {} -> return ()

dbConnectionLoop :: ServerInfo -> IO ()

#if defined(OFFICIAL_SERVER)
flushRequests :: ServerInfo -> IO ()
flushRequests si = do
    e <- isEmptyChan $ dbQueries si
    unless e $ do
        q <- readChan $ dbQueries si
        case q of
            CheckAccount clId clUid _ clHost ->
                writeChan (coreChan si) $ ClientAccountInfo clId clUid (if clHost `L.elem` localAddressList then Admin else Guest)
            ClearCache -> return ()
            SendStats {} -> return ()
            GetReplayName {} -> return ()
            StoreAchievements {} -> return ()
        flushRequests si

pipeDbConnectionLoop :: Chan DBQuery -> Chan CoreMessage -> Handle -> Handle -> Map.Map ByteString (UTCTime, AccountInfo) -> Int -> IO (Map.Map ByteString (UTCTime, AccountInfo), Int)
pipeDbConnectionLoop queries cChan hIn hOut accountsCache req =
    Exception.handle (\(e :: Exception.IOException) -> warningM "Database" (show e) >> return (accountsCache, req)) $
    do
    q <- readChan queries
    (updatedCache, newReq) <- case q of
        CheckAccount clId clUid clNick _ -> do
            let cacheEntry = clNick `Map.lookup` accountsCache
            currentTime <- getCurrentTime
            if (isNothing cacheEntry) || (currentTime `diffUTCTime` (fst . fromJust) cacheEntry > 10 * 60) then
                do
                    SIO.hPutStrLn hIn $ show q
                    hFlush hIn

                    (clId', clUid', accountInfo) <- SIO.hGetLine hOut >>= (maybeException . maybeRead)

                    writeChan cChan $ ClientAccountInfo clId' clUid' accountInfo

                    return $ (Map.insert clNick (currentTime, accountInfo) accountsCache, req + 1)
                `Exception.onException`
                    (unGetChan queries q)
                else
                do
                    writeChan cChan $ ClientAccountInfo clId clUid (snd $ fromJust cacheEntry)
                    return (accountsCache, req)

        GetReplayName {} -> do
            SIO.hPutStrLn hIn $ show q
            hFlush hIn

            (clId', clUid', accountInfo) <- SIO.hGetLine hOut >>= (maybeException . maybeRead)

            writeChan cChan $ ClientAccountInfo clId' clUid' accountInfo
            return (accountsCache, req)

        ClearCache -> return (Map.empty, req)
        StoreAchievements {} -> (
                (SIO.hPutStrLn hIn $ show q) >>
                hFlush hIn >>
                return (accountsCache, req))
                `Exception.onException`
                (unGetChan queries q)
        SendStats {} -> (
                (SIO.hPutStrLn hIn $ show q) >>
                hFlush hIn >>
                return (accountsCache, req))
                `Exception.onException`
                (unGetChan queries q)

    pipeDbConnectionLoop queries cChan hIn hOut updatedCache newReq
    where
        maybeException (Just a) = return a
        maybeException Nothing = ioError (userError "Can't read")

pipeDbConnection ::
        Map.Map ByteString (UTCTime, AccountInfo)
        -> ServerInfo
        -> Int
        -> IO ()

pipeDbConnection accountsCache si errNum = do
    (updatedCache, newErrNum) <-
        Exception.handle (\(e :: Exception.IOException) -> warningM "Database" (show e) >> return (accountsCache, errNum + 1)) $ do
            (Just hIn, Just hOut, _, _) <- createProcess (proc "./OfficialServer/extdbinterface" [])
                    {std_in = CreatePipe,
                    std_out = CreatePipe}
            hSetBuffering hIn LineBuffering
            hSetBuffering hOut LineBuffering

            B.hPutStrLn hIn $ dbHost si
            B.hPutStrLn hIn $ dbName si
            B.hPutStrLn hIn $ dbLogin si
            B.hPutStrLn hIn $ dbPassword si
            (c, r) <- pipeDbConnectionLoop (dbQueries si) (coreChan si) hIn hOut accountsCache 0
            return (c, if r > 0 then 0 else errNum + 1)

    when (newErrNum > 1) $ flushRequests si
    threadDelay (3000000)
    pipeDbConnection updatedCache si newErrNum

dbConnectionLoop si =
        if (not . B.null $ dbHost si) then
            pipeDbConnection Map.empty si 0
        else
            fakeDbConnection si
#else
dbConnectionLoop = fakeDbConnection
#endif

startDBConnection :: ServerInfo -> IO ()
startDBConnection serverInfo =
    forkIO (dbConnectionLoop serverInfo) >> return ()
