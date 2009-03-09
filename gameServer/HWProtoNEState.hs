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
		[ProtocolError "Nick already chosen"]
	else if haveSameNick then
		[AnswerThisClient ["WARNING", "Nick collision"]]
		++ [ByeClient ""]
	else
		[ModifyClient (\c -> c{nick = newNick}),
		AnswerThisClient ["NICK", newNick]]
		++ checkPassword
	where
		client = clients IntMap.! clID
		haveSameNick = isJust $ find (\cl -> newNick == nick cl) $ IntMap.elems clients
		checkPassword = if clientProto client /= 0 then [CheckRegistered] else []


handleCmd_NotEntered clID clients _ ["PROTO", protoNum] =
	if clientProto client > 0 then
		[ProtocolError "Protocol already known"]
	else if parsedProto == 0 then
		[ProtocolError "Bad number"]
	else
		[ModifyClient (\c -> c{clientProto = parsedProto}),
		AnswerThisClient ["PROTO", show parsedProto]]
		++ checkPassword
	where
		client = clients IntMap.! clID
		parsedProto = fromMaybe 0 (maybeRead protoNum :: Maybe Word16)
		checkPassword = if (not . null) (nick client) then [CheckRegistered] else []


handleCmd_NotEntered clID clients _ ["PASSWORD", passwd] =
	if passwd == webPassword client then
		[ModifyClient (\cl -> cl{logonPassed = True}),
		MoveToLobby] ++ adminNotice
	else
		[ByeClient "Authentication failed"]
	where
		client = clients IntMap.! clID
		adminNotice = if isAdministrator client then [AnswerThisClient ["ADMIN_ACCESS"]] else []


handleCmd_NotEntered _ _ _ ["DUMP"] =
	[Dump]


handleCmd_NotEntered clID _ _ _ = [ProtocolError "Incorrect command (state: not entered)"]
