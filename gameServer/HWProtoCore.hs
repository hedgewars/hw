module HWProtoCore where

import qualified Data.IntMap as IntMap
--------------------------------------
import CoreTypes
import Actions
import Utils
import HWProtoNEState
import HWProtoLobbyState
import HWProtoInRoomState

handleCmd:: CmdHandler

handleCmd clID _ _ ["PING"] = [AnswerThisClient ["PONG"]]

handleCmd clID clients _ ("QUIT" : xs) =
	(if isMaster client then [RemoveRoom] else [])
	++ [ByeClient msg]
	where
		client = clients IntMap.! clID
		clientNick = nick client
		msg = if not $ null xs then head xs else ""


handleCmd clID clients rooms cmd =
	if null (nick client) || clientProto client == 0 then
		handleCmd_NotEntered clID clients rooms cmd
	else if roomID client == 0 then
		handleCmd_lobby clID clients rooms cmd
	else
		handleCmd_inRoom clID clients rooms cmd
	where
		client = clients IntMap.! clID

