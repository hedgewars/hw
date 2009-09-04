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

handleCmd_NotEntered clID clients _ ["NICK", newNick] =
	if not . null $ nick client then
		[ProtocolError "Nickname already chosen"]
	else if haveSameNick then
		[AnswerThisClient ["WARNING", "Nickname collision"]]
		++ [ByeClient ""]
	else if illegalName newNick then
		[ByeClient "Illegal nickname"]
	else
		[ModifyClient (\c -> c{nick = newNick}),
		AnswerThisClient ["NICK", newNick]]
		++ checkPassword
	where
		client = clients IntMap.! clID
		haveSameNick = isJust $ find (\cl -> newNick == nick cl) $ IntMap.elems clients
		checkPassword = [CheckRegistered | clientProto client /= 0]


handleCmd_NotEntered clID clients _ ["PROTO", protoNum]
	| clientProto client > 0 = [ProtocolError "Protocol already known"]
	| parsedProto == 0 = [ProtocolError "Bad number"]
	| otherwise =
		[ModifyClient (\ c -> c{clientProto = parsedProto}),
		AnswerThisClient ["PROTO", show parsedProto]]
		++ checkPassword
	where
		client = clients IntMap.! clID
		parsedProto = fromMaybe 0 (maybeRead protoNum :: Maybe Word16)
		checkPassword = [CheckRegistered | (not . null) (nick client)]


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
