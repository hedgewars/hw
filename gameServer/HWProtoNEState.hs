module HWProtoNEState where

import qualified Data.IntMap as IntMap
import Maybe
import Data.List
import Data.Word
import Control.Monad.Reader
--------------------------------------
import CoreTypes
import Actions
import Utils
import RoomsAndClients

handleCmd_NotEntered :: CmdHandler

handleCmd_NotEntered ["NICK", newNick] = do
    (ci, irnc) <- ask
    let cl = irnc `client` ci
    if not . null $ nick cl then return [ProtocolError "Nickname already chosen"]
        else
        if haveSameNick irnc then return [AnswerClients [sendChan cl] ["WARNING", "Nickname already in use"], ByeClient ""]
            else 
            if illegalName newNick then return [ByeClient "Illegal nickname"]
                else
                return $
                    ModifyClient (\c -> c{nick = newNick}) :
                    AnswerClients [sendChan cl] ["NICK", newNick] :
                    [CheckRegistered | clientProto cl /= 0]
    where
        haveSameNick irnc = False --isJust $ find (\cl -> newNick == nick cl) $ IntMap.elems clients

handleCmd_NotEntered ["PROTO", protoNum] = do
    (ci, irnc) <- ask
    let cl = irnc `client` ci
    if clientProto cl > 0 then return [ProtocolError "Protocol already known"]
        else 
        if parsedProto == 0 then return [ProtocolError "Bad number"]
            else 
            return $
                ModifyClient (\c -> c{clientProto = parsedProto}) :
                AnswerClients [sendChan cl] ["PROTO", show parsedProto] :
                [CheckRegistered | (not . null) (nick cl)]
    where
        parsedProto = fromMaybe 0 (maybeRead protoNum :: Maybe Word16)

{-

handleCmd_NotEntered clID clients _ ["PASSWORD", passwd] =
    if passwd == webPassword client then
        [ModifyClient (\cl -> cl{logonPassed = True}),
        MoveToLobby] ++ adminNotice
    else
        [ByeClient "Authentication failed"]
    where
        client = clients IntMap.! clID
        adminNotice = [AnswerThisClient ["ADMIN_ACCESS"] | isAdministrator client]


handleCmd_NotEntered clID clients _ ["DUMP"] =
    if isAdministrator (clients IntMap.! clID) then [Dump] else []
-}

handleCmd_NotEntered _ = return [ProtocolError "Incorrect command (state: not entered)"]
