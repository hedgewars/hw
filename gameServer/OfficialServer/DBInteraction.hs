{-# LANGUAGE CPP, ScopedTypeVariables, OverloadedStrings #-}
module OfficialServer.DBInteraction
(
    startDBConnection
) where

import Prelude hiding (catch);
import System.Process
import System.IO
import Control.Concurrent
import qualified Control.Exception as Exception
import Control.Monad
import qualified Data.Map as Map
import Data.Maybe
import System.Log.Logger
import Data.Time
------------------------
import CoreTypes
import Utils

localAddressList = ["127.0.0.1", "0:0:0:0:0:0:0:1", "0:0:0:0:0:ffff:7f00:1"]

fakeDbConnection serverInfo = forever $ do
    q <- readChan $ dbQueries serverInfo
    case q of
        CheckAccount clUid _ clHost -> do
            writeChan (coreChan serverInfo) $ ClientAccountInfo (clUid,
                if clHost `elem` localAddressList then Admin else Guest)
        ClearCache -> return ()
        SendStats {} -> return ()


#if defined(OFFICIAL_SERVER)
pipeDbConnectionLoop queries coreChan hIn hOut accountsCache =
    Exception.handle (\(e :: Exception.IOException) -> warningM "Database" (show e) >> return accountsCache) $
    do
    q <- readChan queries
    updatedCache <- case q of
        CheckAccount clUid clNick _ -> do
            let cacheEntry = clNick `Map.lookup` accountsCache
            currentTime <- getCurrentTime
            if (isNothing cacheEntry) || (currentTime `diffUTCTime` (fst . fromJust) cacheEntry > 2 * 24 * 60 * 60) then
                do
                    hPutStrLn hIn $ show q
                    hFlush hIn

                    (clId, accountInfo) <- hGetLine hOut >>= (maybeException . maybeRead)

                    writeChan coreChan $ ClientAccountInfo (clId, accountInfo)

                    return $ Map.insert clNick (currentTime, accountInfo) accountsCache
                `Exception.onException`
                    (unGetChan queries q)
                else
                do
                    writeChan coreChan $ ClientAccountInfo (clUid, snd $ fromJust cacheEntry)
                    return accountsCache

        ClearCache -> return Map.empty
        SendStats {} -> (
                (hPutStrLn hIn $ show q) >>
                hFlush hIn >>
                return accountsCache)
                `Exception.onException`
                (unGetChan queries q)

    pipeDbConnectionLoop queries coreChan hIn hOut updatedCache
    where
        maybeException (Just a) = return a
        maybeException Nothing = ioError (userError "Can't read")


pipeDbConnection accountsCache serverInfo = do
    updatedCache <-
        Exception.handle (\(e :: Exception.IOException) -> warningM "Database" (show e) >> return accountsCache) $ do
            (Just hIn, Just hOut, _, _) <- createProcess (proc "./OfficialServer/extdbinterface" [])
                    {std_in = CreatePipe,
                    std_out = CreatePipe}
            hSetBuffering hIn LineBuffering
            hSetBuffering hOut LineBuffering

            hPutStrLn hIn $ dbHost serverInfo
            hPutStrLn hIn $ dbLogin serverInfo
            hPutStrLn hIn $ dbPassword serverInfo
            pipeDbConnectionLoop (dbQueries serverInfo) (coreChan serverInfo) hIn hOut accountsCache

    threadDelay (3 * 10^6)
    pipeDbConnection updatedCache serverInfo

dbConnectionLoop serverInfo =
        if (not . null $ dbHost serverInfo) then
            pipeDbConnection Map.empty serverInfo
        else
            fakeDbConnection serverInfo
#else
dbConnectionLoop = fakeDbConnection
#endif

startDBConnection serverInfo =
    forkIO $ dbConnectionLoop serverInfo
