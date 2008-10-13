module HWProto where

import IO
import Data.List
import Data.Word
import Miscutils
import Maybe
import qualified Data.Map as Map

teamToNet team = ["ADD_TEAM", teamname team, teamgrave team, teamfort team, show $ difficulty team] ++ hhsInfo
	where
		hhsInfo = concatMap (\(HedgehogInfo name hat) -> [name, hat]) $ hedgehogs team

answerBadCmd = [(clientOnly, ["ERROR", "Bad command, state or incorrect parameter"])]
answerNotMaster = [(clientOnly, ["ERROR", "You cannot configure room parameters"])]
answerBadParam = [(clientOnly, ["ERROR", "Bad parameter"])]
answerQuit = [(clientOnly, ["off"])]
answerAbandoned = [(othersInRoom, ["BYE"])]
answerQuitInform nick = [(othersInRoom, ["LEFT", nick])]
answerNickChosen = [(clientOnly, ["ERROR", "The nick already chosen"])]
answerNickChooseAnother = [(clientOnly, ["WARNING", "Choose another nick"])]
answerNick nick = [(clientOnly, ["NICK", nick])]
answerProtocolKnown = [(clientOnly, ["ERROR", "Protocol number already known"])]
answerBadInput = [(clientOnly, ["ERROR", "Bad input"])]
answerProto protoNum = [(clientOnly, ["PROTO", show protoNum])]
answerRoomsList list = [(clientOnly, ["ROOMS"] ++ list)]
answerRoomExists = [(clientOnly, ["WARNING", "There's already a room with that name"])]
answerJoined nick = [(sameRoom, ["JOINED", nick])]
answerNoRoom = [(clientOnly, ["WARNING", "There's no room with that name"])]
answerWrongPassword = [(clientOnly, ["WARNING", "Wrong password"])]
answerChatString nick msg = [(othersInRoom, ["CHAT_STRING", nick, msg])]
answerConfigParam paramName paramStrs = [(othersInRoom, "CONFIG_PARAM" : paramName : paramStrs)]
answerFullConfig room = map toAnswer (Map.toList $ params room) ++ [(clientOnly, ["MAP", gamemap room])]
	where
		toAnswer (paramName, paramStrs) =
			(clientOnly, "CONFIG_PARAM" : paramName : paramStrs)
answerCantAdd = [(clientOnly, ["WARNING", "Too many teams or hedgehogs, or same name team"])]
answerTeamAccepted team = [(clientOnly, ["TEAM_ACCEPTED", teamname team])]
answerAddTeam team = [(othersInRoom, teamToNet team)]
answerHHNum teamName hhNumber = [(othersInRoom, ["HH_NUM", teamName, show hhNumber])]
answerRemoveTeam teamName = [(othersInRoom, ["REMOVE_TEAM", teamName])]
answerNotOwner = [(clientOnly, ["ERROR", "You do not own this team"])]
answerTeamColor teamName newColor = [(othersInRoom, ["TEAM_COLOR", teamName, newColor])]
answerAllTeams room = concatMap toAnswer (teams room)
	where
		toAnswer team =
			[(clientOnly, teamToNet team),
			(clientOnly, ["TEAM_COLOR", teamname team, teamcolor team]),
			(clientOnly, ["HH_NUM", teamname team, show $ hhnum team])]
answerMap mapName = [(othersInRoom, ["MAP", mapName])]
answerRunGame = [(sameRoom, ["RUN_GAME"])]

-- Main state-independent cmd handler
handleCmd :: CmdHandler
handleCmd client _ rooms ("QUIT":xs) =
	if null (room client) then
		(noChangeClients, noChangeRooms, answerQuit)
	else if isMaster client then
		(noChangeClients, removeRoom (room client), answerQuit ++ answerAbandoned) -- core disconnects clients on ROOMABANDONED answer
	else
		(noChangeClients, modifyRoom clRoom{teams = othersTeams}, answerQuit ++ (answerQuitInform $ nick client) ++ answerRemoveClientTeams ++ answerLostTeams)
	where
		clRoom = roomByName (room client) rooms
		answerRemoveClientTeams = map (\tn -> (othersInRoom, ["REMOVE_TEAM", teamname tn])) clientTeams
		(clientTeams, othersTeams) = partition (\t -> teamowner t == nick client) $ teams clRoom
		answerLostTeams = if gameinprogress clRoom then answerInGameLostTeams clientTeams else []
		answerInGameLostTeams teams = []



-- check state and call state-dependent commmand handlers
handleCmd client clients rooms cmd =
	if null (nick client) || protocol client == 0 then
		handleCmd_noInfo client clients rooms cmd
	else if null (room client) then
		handleCmd_noRoom client clients rooms cmd
	else
		handleCmd_inRoom client clients rooms cmd


-- 'no info' state - need to get protocol number and nickname
handleCmd_noInfo :: CmdHandler
handleCmd_noInfo client clients _ ["NICK", newNick] =
	if not . null $ nick client then
		(noChangeClients, noChangeRooms, answerNickChosen)
	else if haveSameNick then
		(noChangeClients, noChangeRooms, answerNickChooseAnother)
	else
		(modifyClient client{nick = newNick}, noChangeRooms, answerNick newNick)
	where
		haveSameNick = isJust $ find (\cl -> newNick == nick cl) clients

handleCmd_noInfo client _ _ ["PROTO", protoNum] =
	if protocol client > 0 then
		(noChangeClients, noChangeRooms, answerProtocolKnown)
	else if parsedProto == 0 then
		(noChangeClients, noChangeRooms, answerBadInput)
	else
		(modifyClient client{protocol = parsedProto}, noChangeRooms, answerProto parsedProto)
	where
		parsedProto = fromMaybe 0 (maybeRead protoNum :: Maybe Word16)

handleCmd_noInfo _ _ _ _ = (noChangeClients, noChangeRooms, answerBadCmd)


-- 'noRoom' clients state command handlers
handleCmd_noRoom :: CmdHandler
handleCmd_noRoom client _ rooms ["LIST"] =
		(noChangeClients, noChangeRooms, answerRoomsList $ map name rooms)

handleCmd_noRoom client _ rooms ["CREATE", newRoom, roomPassword] =
	if haveSameRoom then
		(noChangeClients, noChangeRooms, answerRoomExists)
	else
		(modifyClient client{room = newRoom, isMaster = True}, addRoom createRoom{name = newRoom, password = roomPassword, roomProto = (protocol client)}, answerJoined $ nick client)
	where
		haveSameRoom = isJust $ find (\room -> newRoom == name room) rooms

handleCmd_noRoom client clients rooms ["CREATE", newRoom] =
	handleCmd_noRoom client clients rooms ["CREATE", newRoom, ""]
	
handleCmd_noRoom client clients rooms ["JOIN", roomName, roomPassword] =
	if noSuchRoom then
		(noChangeClients, noChangeRooms, answerNoRoom)
	else if roomPassword /= password clRoom then
		(noChangeClients, noChangeRooms, answerWrongPassword)
	else
		(modifyClient client{room = roomName}, noChangeRooms, (answerJoined $ nick client) ++ answerNicks ++ answerFullConfig clRoom ++ answerAllTeams clRoom)
	where
		noSuchRoom = isNothing $ find (\room -> roomName == name room) rooms
		answerNicks = [(clientOnly, ["JOINED"] ++ (map nick $ filter (\ci -> room ci == roomName) clients))]
		clRoom = roomByName roomName rooms

handleCmd_noRoom client clients rooms ["JOIN", roomName] =
	handleCmd_noRoom client clients rooms ["JOIN", roomName, ""]

handleCmd_noRoom _ _ _ _ = (noChangeClients, noChangeRooms, answerBadCmd)


-- 'inRoom' clients state command handlers
handleCmd_inRoom :: CmdHandler
handleCmd_inRoom client _ _ ["CHAT_STRING", msg] =
	(noChangeClients, noChangeRooms, answerChatString (nick client) msg)

handleCmd_inRoom client _ rooms ("CONFIG_PARAM" : paramName : paramStrs) =
	if isMaster client then
		(noChangeClients, modifyRoom clRoom{params = Map.insert paramName paramStrs (params clRoom)}, answerConfigParam paramName paramStrs)
	else
		(noChangeClients, noChangeRooms, answerNotMaster)
	where
		clRoom = roomByName (room client) rooms

handleCmd_inRoom client _ rooms ["MAP", mapName] =
	if isMaster client then
		(noChangeClients, modifyRoom clRoom{gamemap = mapName}, answerMap mapName)
	else
		(noChangeClients, noChangeRooms, answerNotMaster)
	where
		clRoom = roomByName (room client) rooms

handleCmd_inRoom client _ rooms ("ADD_TEAM" : name : color : grave : fort : difStr : hhsInfo)
	| length hhsInfo == 16 =
	if length (teams clRoom) == 6 || canAddNumber <= 0 || isJust findTeam then
		(noChangeClients, noChangeRooms, answerCantAdd)
	else
		(noChangeClients, modifyRoom clRoom{teams = teams clRoom ++ [newTeam]}, answerTeamAccepted newTeam ++ answerAddTeam newTeam ++ answerTeamColor name color)
	where
		clRoom = roomByName (room client) rooms
		newTeam = (TeamInfo (nick client) name color grave fort difficulty newTeamHHNum (hhsList hhsInfo))
		findTeam = find (\t -> name == teamname t) $ teams clRoom
		difficulty = fromMaybe 0 (maybeRead difStr :: Maybe Int)
		hhsList [] = []
		hhsList (n:h:hhs) = HedgehogInfo n h : hhsList hhs
		canAddNumber = 18 - (sum . map hhnum $ teams clRoom)
		newTeamHHNum = min 4 canAddNumber

handleCmd_inRoom client _ rooms ["HH_NUM", teamName, numberStr] =
	if not $ isMaster client then
		(noChangeClients, noChangeRooms, answerNotMaster)
	else
		if hhNumber < 1 || hhNumber > 8 || noSuchTeam || hhNumber > (canAddNumber + (hhnum team)) then
			(noChangeClients, noChangeRooms, answerBadParam)
		else
			(noChangeClients, modifyRoom $ modifyTeam clRoom team{hhnum = hhNumber}, answerHHNum teamName hhNumber)
	where
		hhNumber = fromMaybe 0 (maybeRead numberStr :: Maybe Int)
		noSuchTeam = isNothing findTeam
		team = fromJust findTeam
		findTeam = find (\t -> teamName == teamname t) $ teams clRoom
		clRoom = roomByName (room client) rooms
		canAddNumber = 18 - (sum . map hhnum $ teams clRoom)

handleCmd_inRoom client _ rooms ["TEAM_COLOR", teamName, newColor] =
	if not $ isMaster client then
		(noChangeClients, noChangeRooms, answerNotMaster)
	else
		(noChangeClients, modifyRoom $ modifyTeam clRoom team{teamcolor = newColor}, answerTeamColor teamName newColor)
	where
		noSuchTeam = isNothing findTeam
		team = fromJust findTeam
		findTeam = find (\t -> teamName == teamname t) $ teams clRoom
		clRoom = roomByName (room client) rooms

handleCmd_inRoom client _ rooms ["REMOVE_TEAM", teamName] =
	if noSuchTeam then
		(noChangeClients, noChangeRooms, answerBadParam)
	else
		if not $ nick client == teamowner team then
			(noChangeClients, noChangeRooms, answerNotOwner)
		else
			(noChangeClients, modifyRoom clRoom{teams = filter (\t -> teamName /= teamname t) $ teams clRoom}, answerRemoveTeam teamName)
	where
		noSuchTeam = isNothing findTeam
		team = fromJust findTeam
		findTeam = find (\t -> teamName == teamname t) $ teams clRoom
		clRoom = roomByName (room client) rooms

handleCmd_inRoom client _ rooms ["READY"] =
	if not $ isMaster client then
		(noChangeClients, noChangeRooms, answerNotMaster)
	else
		(noChangeClients, modifyRoom clRoom{gameinprogress = True}, answerRunGame)
	where
		clRoom = roomByName (room client) rooms

handleCmd_inRoom client _ rooms ["ROUNDFINISHED"] =
	if isMaster client then
		(noChangeClients, modifyRoom clRoom{teams = [], gameinprogress = False}, [])
	else
		(noChangeClients, noChangeRooms, [])
	where
		clRoom = roomByName (room client) rooms

handleCmd_inRoom client _ _ ["GAMEMSG", msg] =
	(noChangeClients, noChangeRooms, [(othersInRoom, ["GAMEMSG", msg])])

handleCmd_inRoom _ _ _ _ = (noChangeClients, noChangeRooms, answerBadCmd)
