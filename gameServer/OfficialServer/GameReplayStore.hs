{-# LANGUAGE ScopedTypeVariables #-}
module OfficialServer.GameReplayStore where

import CoreTypes
import Data.Time
import Control.Exception as E
import qualified Data.Map as Map
import Data.Sequence()
import System.Log.Logger
import Data.Maybe

saveReplay :: RoomInfo -> IO ()
saveReplay r = do
    time <- getCurrentTime
    let fileName = "replays/" ++ show time
    let gi = fromJust $ gameInfo r
    let replayInfo = (teamsAtStart gi, Map.toList $ mapParams r, Map.toList $ params r, roundMsgs gi)
    E.catch
        (writeFile fileName (show replayInfo))
        (\(e :: IOException) -> warningM "REPLAYS" $ "Couldn't write to " ++ fileName ++ ": " ++ show e)
                   