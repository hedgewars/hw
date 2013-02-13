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
---------------
import CoreTypes
import EngineInteraction


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


loadReplay :: Int -> IO [B.ByteString]
loadReplay p = E.handle (\(e :: SomeException) -> warningM "REPLAYS" "Problems reading replay" >> return []) $ do
    files <- liftM (filter (isSuffixOf ('.' : show p))) $ getDirectoryContents "replays"
    if (not $ null files) then
        loadFile $ "replays/" ++ head files
        else
        return []
    where
        loadFile :: String -> IO [B.ByteString]
        loadFile fileName = E.handle (\(e :: SomeException) -> warningM "REPLAYS" ("Problems reading " ++ fileName ++ ": " ++ show e) >> return []) $ do
            (teams, params1, params2, roundMsgs) <- liftM read $ readFile fileName
            return $ replayToDemo teams (Map.fromList params1) (Map.fromList params2) (reverse roundMsgs)
