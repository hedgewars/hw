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

{-# LANGUAGE BangPatterns #-}

module JoinsMonitor(
    JoinsMonitor
    , newJoinMonitor
    , cleanup
    , joinsSentry
    ) where

import qualified Data.Map as Map
import Data.Time
import Data.IORef
import qualified Data.ByteString as B
import Data.Maybe
import Control.Monad

newtype JoinsMonitor = JoinsMonitor (IORef (Map.Map B.ByteString [UTCTime]))


newJoinMonitor :: IO JoinsMonitor
newJoinMonitor = do
    ioref <- newIORef Map.empty
    return (JoinsMonitor ioref)


cleanup :: JoinsMonitor -> UTCTime -> IO ()
cleanup (JoinsMonitor ref) time = modifyIORef ref f
    where
        f = Map.mapMaybe (\v -> let v' = takeWhile (\t -> diffUTCTime time t < 60*60) v in if null v' then Nothing else Just v')


joinsSentry :: JoinsMonitor -> B.ByteString -> UTCTime -> IO Bool
joinsSentry (JoinsMonitor ref) host time = do
    m <- readIORef ref
    let lastJoins = map (diffUTCTime time) $ Map.findWithDefault [] host m
    let last30sec = length $ takeWhile (< 30) lastJoins
    let last2min = length $ takeWhile (< 120) lastJoins
    let last10min = length $ takeWhile (< 600) lastJoins
    let pass = last30sec < 2 && last2min < 3 && last10min < 5

    when pass $ writeIORef ref $ Map.alter (Just . (:) time . fromMaybe []) host m

    return pass
