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

{-# LANGUAGE OverloadedStrings, BangPatterns #-}
module FloodDetection where

import Control.Monad.State.Strict
import Data.Time
import Control.Arrow
----------------
import ServerState
import CoreTypes
import Utils

registerEvent :: Event -> StateT ServerState IO [Action]
registerEvent e = do
    eventInfo <- client's $ einfo e
    if (null eventInfo) || 0 == (fst $ head eventInfo) then doCheck eventInfo else updateInfo

    where
    einfo LobbyChatMessage = eiLobbyChat
    einfo EngineMessage = eiEM
    einfo RoomJoin = eiJoin
    einfo RoomNameUpdate = eiLobbyChat

    transformField LobbyChatMessage f = \c -> c{eiLobbyChat = f $ eiLobbyChat c}
    transformField EngineMessage f = \c -> c{eiEM = f $ eiEM c}
    transformField RoomJoin f = \c -> c{eiJoin = f $ eiJoin c}
    transformField RoomNameUpdate f = transformField LobbyChatMessage f
    

    boundaries :: Event -> (Int, (NominalDiffTime, Int), (NominalDiffTime, Int), ([Action], [Action]))
    boundaries LobbyChatMessage = (3, (10, 2), (30, 3), (chat1, chat2))
    boundaries EngineMessage = (8, (10, 4), (25, 5), (em1, em2))
    boundaries RoomJoin = (2, (10, 2), (35, 3), (join1, join2))
    boundaries RoomNameUpdate = (\(a, b, c, _) -> (a, b, c, (roomName1, roomName2))) $ boundaries LobbyChatMessage

    chat1 = [Warning $ loc "Warning! Chat flood protection activated"]
    chat2 = [ByeClient $ loc "Excess flood"]
    em1 = [Warning $ loc "Game messages flood detected - 1"]
    em2 = [ByeClient $ loc "Excess flood"]
    join1 = [Warning $ loc "Warning! Joins flood protection activated"]
    join2 = [ByeClient $ loc "Excess flood"]
    roomName1 = [Warning $ loc "Warning! Room name change flood protection activated"]
    roomName2 = [ByeClient $ loc "Excess flood"]

    doCheck ei = do
        curTime <- io getCurrentTime
        let (numPerEntry, (sec1, num1), (sec2, num2), (ac1, ac2)) = boundaries e

        let nei = takeWhile ((>=) sec2 . diffUTCTime curTime . snd) ei
        let l2 = length nei
        let l1 = length $ takeWhile ((>=) sec1 . diffUTCTime curTime . snd) nei

        let actions = if l2 >= num2 + 1 || l1 >= num1 + 1 then 
                ac2
                else
                if l1 >= num1 || l2 >= num2 then 
                    ac1
                    else
                    []

        return $ [ModifyClient . transformField e . const $ (numPerEntry, curTime) : nei
                , ModifyClient (\c -> c{pendingActions = actions}) -- append? prepend? just replacing for now
            ]

    updateInfo = return [
        ModifyClient $ transformField e
            $ \(h:hs) -> first (flip (-) 1) h : hs
        ]
