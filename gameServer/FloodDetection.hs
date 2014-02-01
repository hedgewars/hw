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

    transformField LobbyChatMessage f = \c -> c{eiLobbyChat = f $ eiLobbyChat c}
    transformField EngineMessage f = \c -> c{eiEM = f $ eiEM c}
    transformField RoomJoin f = \c -> c{eiJoin = f $ eiJoin c}

    boundaries :: Event -> (Int, (NominalDiffTime, Int), (NominalDiffTime, Int), ([Action], [Action]))
    boundaries LobbyChatMessage = (3, (10, 2), (30, 3), (chat1, chat2))
    boundaries EngineMessage = (8, (10, 4), (25, 5), (em1, em2))
    boundaries RoomJoin = (2, (10, 2), (35, 3), (join1, join2))

    chat1 = [Warning $ loc "Warning! Chat flood protection activated"]
    chat2 = [ByeClient $ loc "Excess flood"]
    em1 = [Warning $ loc "Game messages flood detected - 1"]
    em2 = [Warning $ loc "Game messages flood detected - 2"]
    join1 = [Warning $ loc "Warning! Joins flood protection activated"]
    join2 = [ByeClient $ loc "Excess flood"]

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

        return $ (ModifyClient . transformField e . const $ (numPerEntry, curTime) : nei) : actions

    updateInfo = return [
        ModifyClient $ transformField e
            $ \(h:hs) -> first (flip (-) 1) h : hs
        ]
