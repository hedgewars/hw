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

handleCmd clID clients rooms ("QUIT" : xs) =
	(if isMaster client then [RemoveRoom] else removeClientTeams)
	++ [ByeClient msg]
	where
		client = clients IntMap.! clID
		clientNick = nick client
		msg = if not $ null xs then head xs else ""
		room = rooms IntMap.! (roomID client)
		clientTeams = filter (\t -> teamowner t == nick client) $ teams room
		removeClientTeams = map (RemoveTeam . teamname) clientTeams

handleCmd clID clients rooms cmd =
	if null (nick client) || clientProto client == 0 then
		handleCmd_NotEntered clID clients rooms cmd
	else if roomID client == 0 then
		handleCmd_lobby clID clients rooms cmd
	else
		handleCmd_inRoom clID clients rooms cmd
	where
		client = clients IntMap.! clID

