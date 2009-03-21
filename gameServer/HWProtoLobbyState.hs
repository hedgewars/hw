module HWProtoLobbyState where

import qualified Data.Map as Map
import qualified Data.IntMap as IntMap
import qualified Data.IntSet as IntSet
import qualified Data.Foldable as Foldable
import Maybe
import Data.List
--------------------------------------
import CoreTypes
import Actions
import Utils

answerAllTeams teams = concatMap toAnswer teams
	where
		toAnswer team =
			[AnswerThisClient $ teamToNet team,
			AnswerThisClient ["TEAM_COLOR", teamname team, teamcolor team],
			AnswerThisClient ["HH_NUM", teamname team, show $ hhnum team]]

handleCmd_lobby :: CmdHandler

handleCmd_lobby clID clients rooms ["LIST"] =
	[AnswerThisClient ("ROOMS" : roomsInfoList)]
	where
		roomsInfoList = concatMap roomInfo $ sameProtoRooms
		sameProtoRooms = filter (\r -> (roomProto r == protocol) && (not $ isRestrictedJoins r)) roomsList
		roomsList = IntMap.elems rooms
		protocol = clientProto client
		client = clients IntMap.! clID
		roomInfo room = [
				name room,
				(show $ playersIn room) ++ "(" ++ (show $ length $ teams room) ++ ")",
				show $ gameinprogress room
				]


handleCmd_lobby clID clients _ ["CHAT", msg] =
	[AnswerOthersInRoom ["CHAT", clientNick, msg]]
	where
		clientNick = nick $ clients IntMap.! clID


handleCmd_lobby clID clients rooms ["CREATE_ROOM", newRoom, roomPassword] =
	if haveSameRoom then
		[Warning "Room exists"]
	else
		[RoomRemoveThisClient, -- leave lobby
		AddRoom newRoom roomPassword,
		AnswerThisClient ["NOT_READY", clientNick]
		]
	where
		clientNick = nick $ clients IntMap.! clID
		haveSameRoom = isJust $ find (\room -> newRoom == name room) $ IntMap.elems rooms


handleCmd_lobby clID clients rooms ["CREATE_ROOM", newRoom] =
	handleCmd_lobby clID clients rooms ["CREATE_ROOM", newRoom, ""]


handleCmd_lobby clID clients rooms ["JOIN_ROOM", roomName, roomPassword] =
	if noSuchRoom then
		[Warning "No such room"]
	else if isRestrictedJoins jRoom then
		[Warning "Joining restricted"]
	else if roomPassword /= password jRoom then
		[Warning "Wrong password"]
	else
		[RoomRemoveThisClient, -- leave lobby
		RoomAddThisClient rID] -- join room
		++ answerNicks
		++ answerReady
		++ [AnswerThisRoom ["NOT_READY", nick client]]
		++ answerFullConfig
		++ answerTeams
		++ watchRound
	where
		noSuchRoom = isNothing mbRoom
		mbRoom = find (\r -> roomName == name r && roomProto r == clientProto client) $ IntMap.elems rooms 
		jRoom = fromJust mbRoom
		rID = roomUID jRoom
		client = clients IntMap.! clID
		roomClientsIDs = IntSet.elems $ playersIDs jRoom
		answerNicks = if playersIn jRoom /= 0 then
					[AnswerThisClient $ ["JOINED"] ++ (map (\clID -> nick $ clients IntMap.! clID) $ roomClientsIDs)]
				else
					[]
		answerReady =
			map (\c -> AnswerThisClient [if isReady c then "READY" else "NOT_READY", nick c]) $
			map (\clID -> clients IntMap.! clID) roomClientsIDs

		toAnswer (paramName, paramStrs) = AnswerThisClient $ "CFG" : paramName : paramStrs
		
		answerFullConfig = map toAnswer (leftConfigPart ++ rightConfigPart)
		(leftConfigPart, rightConfigPart) = partition (\(p, _) -> p /= "MAP") (Map.toList $ params jRoom)

		watchRound = if not $ gameinprogress jRoom then
					[]
				else
					[AnswerThisClient  ["RUN_GAME"],
					AnswerThisClient $ "EM" : toEngineMsg "e$spectate 1" : (Foldable.toList $ roundMsgs jRoom)]

		answerTeams = if gameinprogress jRoom then
				answerAllTeams (teamsAtStart jRoom)
			else
				answerAllTeams (teams jRoom)


handleCmd_lobby clID clients rooms ["JOIN_ROOM", roomName] =
	handleCmd_lobby clID clients rooms ["JOIN_ROOM", roomName, ""]


handleCmd_lobby clID clients rooms ["KICK", kickNick] =
	if not $ isAdministrator client then
		[]
	else
		if noSuchClient then
			[]
		else
			if kickID == clID then
				[]
			else
				[KickClient kickID]
	where
		client = clients IntMap.! clID
		maybeClient = Foldable.find (\cl -> kickNick == nick cl) clients
		noSuchClient = isNothing maybeClient
		kickID = clientUID $ fromJust maybeClient


handleCmd_lobby clID clients rooms ["BAN", banNick] =
	if not $ isAdministrator client then
		[]
	else
		BanClient banNick : handleCmd_lobby clID clients rooms ["KICK", banNick]
	where
		client = clients IntMap.! clID


handleCmd_lobby clID _ _ _ = [ProtocolError "Incorrect command (state: in lobby)"]
