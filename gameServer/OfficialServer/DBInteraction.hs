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

dbConnectionLoop :: forall b. ServerInfo -> IO b
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
        flushRequests si

pipeDbConnectionLoop :: Chan DBQuery -> Chan CoreMessage -> Handle -> Handle -> Map.Map ByteString (UTCTime, AccountInfo) -> IO (Map.Map ByteString (UTCTime, AccountInfo))
pipeDbConnectionLoop queries cChan hIn hOut accountsCache =
    Exception.handle (\(e :: Exception.IOException) -> warningM "Database" (show e) >> return accountsCache) $
    do
    q <- readChan queries
    updatedCache <- case q of
        CheckAccount clId clUid clNick _ -> do
            let cacheEntry = clNick `Map.lookup` accountsCache
            currentTime <- getCurrentTime
            if (isNothing cacheEntry) || (currentTime `diffUTCTime` (fst . fromJust) cacheEntry > 2 * 24 * 60 * 60) then
                do
                    SIO.hPutStrLn hIn $ show q
                    hFlush hIn

                    (clId', clUid', accountInfo) <- SIO.hGetLine hOut >>= (maybeException . maybeRead)

                    writeChan cChan $ ClientAccountInfo clId' clUid' accountInfo

                    return $ Map.insert clNick (currentTime, accountInfo) accountsCache
                `Exception.onException`
                    (unGetChan queries q
                    >> writeChan cChan (ClientAccountInfo clId clUid Guest)
                    )
                else
                do
                    writeChan cChan $ ClientAccountInfo clId clUid (snd $ fromJust cacheEntry)
                    return accountsCache

        ClearCache -> return Map.empty
        SendStats {} -> (
                (SIO.hPutStrLn hIn $ show q) >>
                hFlush hIn >>
                return accountsCache)
                `Exception.onException`
                (unGetChan queries q)

    pipeDbConnectionLoop queries cChan hIn hOut updatedCache
    where
        maybeException (Just a) = return a
        maybeException Nothing = ioError (userError "Can't read")

pipeDbConnection :: forall b. Map.Map ByteString (UTCTime, AccountInfo) -> ServerInfo -> Int -> IO b
pipeDbConnection accountsCache si errNum = do
    (updatedCache, newErrNum) <-
        Exception.handle (\(e :: Exception.IOException) -> warningM "Database" (show e) >> return (accountsCache, errNum + 1)) $ do
            (Just hIn, Just hOut, _, _) <- createProcess (proc "./OfficialServer/extdbinterface" [])
                    {std_in = CreatePipe,
                    std_out = CreatePipe}
            hSetBuffering hIn LineBuffering
            hSetBuffering hOut LineBuffering

            B.hPutStrLn hIn $ dbHost si
            B.hPutStrLn hIn $ dbLogin si
            B.hPutStrLn hIn $ dbPassword si
            c <- pipeDbConnectionLoop (dbQueries si) (coreChan si) hIn hOut accountsCache
            return (c, 0)

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
