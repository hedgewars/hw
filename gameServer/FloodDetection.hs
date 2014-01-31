module FloodDetection where

import Control.Monad.State.Strict
import Data.Time
import Control.Arrow
----------------
import ServerState
import CoreTypes

registerEvent :: Event -> StateT ServerState IO [Action]
registerEvent e = do
    eventInfo <- client's $ einfo e
    if (null eventInfo) || 0 == (fst $ head eventInfo) then doCheck eventInfo else updateInfo
    where
    einfo LobbyChatMessage = eiLobbyChat
    einfo EngineMessage = eiEM
    einfo RoomJoin = eiJoin

    transformField LobbyChatMessage f = \c -> c{eiLobbyChat = f $ eiLobbyChat c}
    transformField EngineMessage f = \c -> c{eiLobbyChat = f $ eiEM c}
    transformField RoomJoin f = \c -> c{eiLobbyChat = f $ eiJoin c}

    boundaries :: Event -> (Int, (NominalDiffTime, Int, [Action]), (NominalDiffTime, Int, [Action]))
    boundaries LobbyChatMessage = (3, (10, 2, []), (30, 3, []))
    boundaries EngineMessage = (10, (10, 3, []), (30, 4, undefined))
    boundaries RoomJoin = (2, (10, 2, []), (35, 3, []))

    doCheck ei = do
        curTime <- io getCurrentTime
        let (numPerEntry, (sec1, num1, ac1), (sec2, num2, ac2)) = boundaries e

        let nei2 = takeWhile ((>=) sec2 . diffUTCTime curTime . snd) ei
        let nei1 = takeWhile ((>=) sec1 . diffUTCTime curTime . snd) nei1

        let actions = if length nei2 >= num2 then ac2 else if length nei1 >= num1 then ac1 else []

        return $ (ModifyClient . transformField e . const $ (numPerEntry, curTime) : nei2) : actions

    updateInfo = return [
        ModifyClient $ transformField e
            $ \(h:hs) -> first (flip (-) 1) h : hs
        ]
