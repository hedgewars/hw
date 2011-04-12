{-# LANGUAGE ScopedTypeVariables #-}
module OfficialServer.GameReplayStore where

import CoreTypes
import Data.Time
import Control.Exception as E
import qualified Data.Map as Map
import Data.Sequence()
import System.Log.Logger

saveReplay :: RoomInfo -> IO ()
saveReplay r = do
    time <- getCurrentTime
    let fileName = "replays/" ++ show time
    let replayInfo = (teamsAtStart r, Map.toList $ mapParams r, Map.toList $ params r, roundMsgs r)
    E.catch
        (writeFile fileName (show replayInfo))
        (\(e :: IOException) -> warningM "REPLAYS" $ "Couldn't write to " ++ fileName ++ ": " ++ show e)
                   