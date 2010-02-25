module HWProtoNEState where

import qualified Data.IntMap as IntMap
import Maybe
import Data.List
import Data.Word
--------------------------------------
import CoreTypes
import Actions
import Utils

handleCmd_NotEntered :: CmdHandler

handleCmd_NotEntered clID clients _ ["NICK", newNick]
    | not . null $ nick client = [ProtocolError "Nickname already chosen"]
    | haveSameNick = [AnswerThisClient ["WARNING", "Nickname already in use"], ByeClient ""]
    | illegalName newNick = [ByeClient "Illegal nickname"]
    | otherwise =
        ModifyClient (\c -> c{nick = newNick}) :
        AnswerThisClient ["NICK", newNick] :
        [CheckRegistered | clientProto client /= 0]
    where
        client = clients IntMap.! clID
        haveSameNick = isJust $ find (\cl -> newNick == nick cl) $ IntMap.elems clients


handleCmd_NotEntered clID clients _ ["PROTO", protoNum]
    | clientProto client > 0 = [ProtocolError "Protocol already known"]
    | parsedProto == 0 = [ProtocolError "Bad number"]
    | otherwise =
        ModifyClient (\c -> c{clientProto = parsedProto}) :
        AnswerThisClient ["PROTO", show parsedProto] :
        [CheckRegistered | (not . null) (nick client)]
    where
        client = clients IntMap.! clID
        parsedProto = fromMaybe 0 (maybeRead protoNum :: Maybe Word16)


handleCmd_NotEntered clID clients _ ["PASSWORD", passwd] =
    if passwd == webPassword client then
        [ModifyClient (\cl -> cl{logonPassed = True}),
        MoveToLobby] ++ adminNotice
    else
        [ByeClient "Authentication failed"]
    where
        client = clients IntMap.! clID
        adminNotice = [AnswerThisClient ["ADMIN_ACCESS"] | isAdministrator client]


--handleCmd_NotEntered _ _ _ ["DUMP"] =
--	[Dump]


handleCmd_NotEntered clID _ _ _ = [ProtocolError "Incorrect command (state: not entered)"]
