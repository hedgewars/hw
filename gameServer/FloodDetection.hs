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
    if (not $ null eventInfo) && 0 == (fst $ head eventInfo) then doCheck eventInfo else updateInfo
    where
    einfo LobbyChatMessage = eiLobbyChat
    einfo EngineMessage = eiEM
    einfo RoomJoin = eiJoin
     
    transformField LobbyChatMessage f = \c -> c{eiLobbyChat = f $ eiLobbyChat c}
    transformField EngineMessage f = \c -> c{eiLobbyChat = f $ eiEM c}
    transformField RoomJoin f = \c -> c{eiLobbyChat = f $ eiJoin c}
    
    doCheck ei = do
        liftM Just $ io getCurrentTime
        return []
    updateInfo = return [
        ModifyClient $ transformField e 
            $ \ei -> if null ei then 
                [] 
                else 
                let (h:hs) = ei in first (flip (-) 1) h : hs
        ]
