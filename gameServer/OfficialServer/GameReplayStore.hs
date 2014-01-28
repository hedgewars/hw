{-# LANGUAGE ScopedTypeVariables #-}
module OfficialServer.GameReplayStore where

import Data.Time
import Control.Exception as E
import qualified Data.Map as Map
import Data.Sequence()
import System.Log.Logger
import Data.Maybe
import Data.Unique
import Control.Monad
import Data.List
import qualified Data.ByteString as B
import System.Directory
import Control.DeepSeq
---------------
import CoreTypes
import EngineInteraction


pickReplayFile :: Int -> [String] -> IO String
pickReplayFile p blackList = do
    files <- liftM (filter (\f -> sameProto f && notBlacklisted f)) $ getDirectoryContents "replays"
    if (not $ null files) then
        return $ "replays/" ++ head files
        else
        return ""
    where
        sameProto = (isSuffixOf ('.' : show p))
        notBlacklisted = flip notElem blackList

saveReplay :: RoomInfo -> IO ()
saveReplay r = do
    let gi = fromJust $ gameInfo r
    when (allPlayersHaveRegisteredAccounts gi) $ do
        time <- getCurrentTime
        u <- liftM hashUnique newUnique
        let fileName = "replays/" ++ show time ++ "-" ++ show u ++ "." ++ show (roomProto r)
        let replayInfo = (teamsAtStart gi, Map.toList $ mapParams r, Map.toList $ params r, roundMsgs gi)
        E.catch
            (writeFile fileName (show replayInfo))
            (\(e :: IOException) -> warningM "REPLAYS" $ "Couldn't write to " ++ fileName ++ ": " ++ show e)


loadReplay :: Int -> [String] -> IO (Maybe CheckInfo, [B.ByteString])
loadReplay p blackList = E.handle (\(e :: SomeException) -> warningM "REPLAYS" "Problems reading replay" >> return (Nothing, [])) $ do
    fileName <- pickReplayFile p blackList
    if (not $ null fileName) then
        loadFile fileName
        else
        return (Nothing, [])
    where
        loadFile :: String -> IO (Maybe CheckInfo, [B.ByteString])
        loadFile fileName = E.handle (\(e :: SomeException) ->
                    warningM "REPLAYS" ("Problems reading " ++ fileName ++ ": " ++ show e) >> return (Just $ CheckInfo fileName [], [])) $ do
            (teams, params1, params2, roundMsgs) <- liftM read $ readFile fileName
            return $ (
                Just (CheckInfo fileName teams)
                , let d = replayToDemo teams (Map.fromList params1) (Map.fromList params2) (reverse roundMsgs) in d `deepseq` d
                )

moveFailedRecord :: String -> IO ()
moveFailedRecord fn = E.handle (\(e :: SomeException) -> warningM "REPLAYS" $ show e) $
    renameFile fn ("failed/" ++ drop 8 fn)


moveCheckedRecord :: String -> IO ()
moveCheckedRecord fn = E.handle (\(e :: SomeException) -> warningM "REPLAYS" $ show e) $
    renameFile fn ("checked/" ++ drop 8 fn)
