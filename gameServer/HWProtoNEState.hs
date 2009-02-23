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

onLoginFinished :: Int -> String -> Word16 -> Clients -> [Action]
onLoginFinished clID clientNick clProto clients =
	if (null $ clientNick) || (clProto == 0) then
		[]
	else
		(RoomAddThisClient 0)
		: CheckRegistered
		: answerLobbyNicks
		-- ++ (answerServerMessage client clients)
	where
		lobbyNicks = filter (\n -> (not (null n))) $ map nick $ IntMap.elems clients
		answerLobbyNicks = if not $ null lobbyNicks then
					[AnswerThisClient (["LOBBY:JOINED"] ++ lobbyNicks)]
				else
					[]


handleCmd_NotEntered clID clients _ ["NICK", newNick] =
	if not . null $ nick client then
		[ProtocolError "Nick already chosen"]
	else if haveSameNick then
		[AnswerThisClient ["WARNING", "Nick collision"]]
		++ [ByeClient ""]
	else
		[ModifyClient (\c -> c{nick = newNick}),
		AnswerThisClient ["NICK", newNick]]
		++ (onLoginFinished clID newNick (clientProto client) clients)
	where
		client = clients IntMap.! clID
		haveSameNick = isJust $ find (\cl -> newNick == nick cl) $ IntMap.elems clients


handleCmd_NotEntered clID clients _ ["PROTO", protoNum] =
	if clientProto client > 0 then
		[ProtocolError "Protocol already known"]
	else if parsedProto == 0 then
		[ProtocolError "Bad number"]
	else
		[ModifyClient (\c -> c{clientProto = parsedProto}),
		AnswerThisClient ["PROTO", show parsedProto]]
		++ (onLoginFinished clID (nick client) parsedProto clients)
	where
		client = clients IntMap.! clID
		parsedProto = fromMaybe 0 (maybeRead protoNum :: Maybe Word16)


handleCmd_NotEntered _ _ _ ["DUMP"] =
	[Dump]


handleCmd_NotEntered clID _ _ _ = [ProtocolError "Incorrect command (state: not entered)"]
