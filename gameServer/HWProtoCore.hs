module HWProtoCore where

import qualified Data.IntMap as IntMap
import Data.Foldable
import Maybe
--------------------------------------
import CoreTypes
import Actions
import Utils
import HWProtoNEState
import HWProtoLobbyState
import HWProtoInRoomState

handleCmd, handleCmd_loggedin :: CmdHandler

handleCmd clID _ _ ["PING"] = [AnswerThisClient ["PONG"]]

handleCmd clID clients rooms ("QUIT" : xs) =
	(if isMaster client then [RemoveRoom] else [RemoveClientTeams clID])
	++ [ByeClient msg]
	where
		client = clients IntMap.! clID
		clientNick = nick client
		msg = if not $ null xs then head xs else ""


handleCmd clID clients rooms cmd =
	if not $ logonPassed client then
		handleCmd_NotEntered clID clients rooms cmd
	else
		handleCmd_loggedin clID clients rooms cmd
	where
		client = clients IntMap.! clID


handleCmd_loggedin clID clients rooms ["INFO", asknick] =
	if noSuchClient then
		[]
	else
		[AnswerThisClient
			["INFO",
			nick client,
			"[" ++ host client ++ "]",
			protoNumber2ver $ clientProto client,
			roomInfo]]
	where
		maybeClient = find (\cl -> asknick == nick cl) clients
		noSuchClient = isNothing maybeClient
		client = fromJust maybeClient
		room = rooms IntMap.! roomID client
		roomInfo = if roomID client /= 0 then "room " ++ (name room) else "lobby"


handleCmd_loggedin clID clients rooms cmd =
	if roomID client == 0 then
		handleCmd_lobby clID clients rooms cmd
	else
		handleCmd_inRoom clID clients rooms cmd
	where
		client = clients IntMap.! clID
