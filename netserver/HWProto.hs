module HWProto
(
	handleCmd
) where

import IO
import Data.List
import Data.Word
import Miscutils
import Maybe
import qualified Data.Map as Map
import Opts

teamToNet team = ["ADD_TEAM", teamname team, teamgrave team, teamfort team, show $ difficulty team] ++ hhsInfo
	where
		hhsInfo = concatMap (\(HedgehogInfo name hat) -> [name, hat]) $ hedgehogs team

makeAnswer :: HandlesSelector -> [String] -> [Answer]
makeAnswer func msg = [\_ -> (func, msg)]
answerClientOnly, answerOthersRoom, answerSameRoom :: [String] -> [Answer]
answerClientOnly  = makeAnswer clientOnly
answerOthersRoom  = makeAnswer othersInRoom
answerSameRoom    = makeAnswer sameRoom
answerSameProtoLobby = makeAnswer sameProtoLobbyClients
answerAll         = makeAnswer allClients

answerBadCmd            = answerClientOnly ["ERROR", "Bad command, state or incorrect parameter"]
answerNotMaster         = answerClientOnly ["ERROR", "You cannot configure room parameters"]
answerBadParam          = answerClientOnly ["ERROR", "Bad parameter"]
answerErrorMsg msg      = answerClientOnly ["ERROR", msg]
answerQuit msg          = answerClientOnly ["BYE", msg]
answerNickChosen        = answerClientOnly ["ERROR", "The nick already chosen"]
answerNickChooseAnother = answerClientOnly ["WARNING", "Choose another nick"]
answerNick nick         = answerClientOnly ["NICK", nick]
answerProtocolKnown     = answerClientOnly ["ERROR", "Protocol number already known"]
answerBadInput          = answerClientOnly ["ERROR", "Bad input"]
answerProto protoNum    = answerClientOnly ["PROTO", show protoNum]
answerRoomsList list    = answerClientOnly $ "ROOMS" : list
answerRoomExists        = answerClientOnly ["WARNING", "There's already a room with that name"]
answerNoRoom            = answerClientOnly ["WARNING", "There's no room with that name"]
answerWrongPassword     = answerClientOnly ["WARNING", "Wrong password"]
answerCantAdd reason    = answerClientOnly ["WARNING", "Cannot add team: " ++ reason]
answerTeamAccepted team = answerClientOnly ["TEAM_ACCEPTED", teamname team]
answerTooFewClans       = answerClientOnly ["ERROR", "Too few clans in game"]
answerRestricted        = answerClientOnly ["WARNING", "Room joining restricted"]
answerConnected         = answerClientOnly ["CONNECTED", "Hedgewars server http://www.hedgewars.org/"]
answerNotOwner          = answerClientOnly ["ERROR", "You do not own this team"]
answerCannotCreateRoom  = answerClientOnly ["WARNING", "Cannot create more rooms"]
answerInfo client       = answerClientOnly ["INFO", nick client, host client, proto2ver $ protocol client, roomInfo]
	where
	roomInfo = if not $ null $ room client then "room " ++ (room client) else "lobby"

answerAbandoned protocol  =
	if protocol < 20 then
		answerOthersRoom ["BYE", "Room abandoned"]
	else
		answerOthersRoom ["ROOMABANDONED"]

answerChatString nick msg = answerOthersRoom ["CHAT_STRING", nick, msg]
answerAddTeam team        = answerOthersRoom $ teamToNet team
answerRemoveTeam teamName = answerOthersRoom ["REMOVE_TEAM", teamName]
answerMap mapName         = answerOthersRoom ["MAP", mapName]
answerHHNum teamName hhNumber = answerOthersRoom ["HH_NUM", teamName, show hhNumber]
answerTeamColor teamName newColor = answerOthersRoom ["TEAM_COLOR", teamName, newColor]
answerConfigParam paramName paramStrs = answerOthersRoom $ "CONFIG_PARAM" : paramName : paramStrs
answerQuitInform nick msg =
	if not $ null msg then
		answerOthersRoom ["LEFT", nick, msg]
		else
		answerOthersRoom ["LEFT", nick]

answerPartInform nick = answerOthersRoom ["LEFT", nick, "bye room"]
answerQuitLobby nick msg =
	if not $ null nick then
		if not $ null msg then
			answerAll ["LOBBY:LEFT", nick, msg]
		else
			answerAll ["LOBBY:LEFT", nick]
	else
		[]

answerJoined nick   = answerSameRoom ["JOINED", nick]
answerRunGame       = answerSameRoom ["RUN_GAME"]
answerIsReady nick  = answerSameRoom ["READY", nick]
answerNotReady nick = answerSameRoom ["NOT_READY", nick]

answerRoomAdded name    = answerSameProtoLobby ["ROOM", "ADD", name]
answerRoomDeleted name  = answerSameProtoLobby ["ROOM", "DEL", name]

answerFullConfig room = concatMap toAnswer (Map.toList $ params room) ++ (answerClientOnly ["MAP", gamemap room])
	where
		toAnswer (paramName, paramStrs) =
			answerClientOnly $ "CONFIG_PARAM" : paramName : paramStrs

answerAllTeams room = concatMap toAnswer (teams room)
	where
		toAnswer team =
			(answerClientOnly $ teamToNet team) ++
			(answerClientOnly ["TEAM_COLOR", teamname team, teamcolor team]) ++
			(answerClientOnly ["HH_NUM", teamname team, show $ hhnum team])

answerServerMessage client clients = [\serverInfo -> (clientOnly, "SERVER_MESSAGE" :
		[(mainbody serverInfo) ++ clientsIn ++ (lastHour serverInfo)])]
	where
		mainbody serverInfo = serverMessage serverInfo ++
			if isDedicated serverInfo then
				"<p align=center>Dedicated server</p>"
				else
				"<p align=center>Private server</p>"
		
		clientsIn = if protocol client < 20 then "<p align=left>" ++ (show $ length nicks) ++ " clients in: " ++ clientslist ++ "</p>" else []
		clientslist = if not $ null nicks then foldr1 (\a b -> a  ++ ", " ++ b) nicks else ""
		lastHour serverInfo =
			if isDedicated serverInfo then
				"<p align=left>" ++ (show $ length $ lastHourUsers serverInfo) ++ " user logins in last hour</p>"
				else
				""
		nicks = filter (not . null) $ map nick clients

answerPing = makeAnswer allClients ["PING"]

-- Main state-independent cmd handler
handleCmd :: CmdHandler
handleCmd client _ rooms ("QUIT" : xs) =
	if null (room client) then
		(noChangeClients, noChangeRooms, answerQuit msg ++ (answerQuitLobby (nick client) msg) )
	else if isMaster client then
		(modifyRoomClients clRoom (\cl -> cl{room = [], isReady = False}), removeRoom (room client), (answerQuit msg) ++ (answerQuitLobby (nick client) msg) ++ (answerAbandoned $ protocol client) ++ (answerRoomDeleted $ room client)) -- core disconnects clients on ROOMABANDONED answer
	else
		(noChangeClients, modifyRoom clRoom{teams = othersTeams, playersIn = (playersIn clRoom) - 1, readyPlayers = newReadyPlayers}, (answerQuit msg) ++ (answerQuitInform (nick client) msg) ++ (answerQuitLobby (nick client) msg) ++ answerRemoveClientTeams)
	where
		clRoom = roomByName (room client) rooms
		answerRemoveClientTeams = concatMap (\tn -> answerOthersRoom ["REMOVE_TEAM", teamname tn]) clientTeams
		(clientTeams, othersTeams) = partition (\t -> teamowner t == nick client) $ teams clRoom
		newReadyPlayers = if isReady client then (readyPlayers clRoom) - 1 else readyPlayers clRoom
		msg = if not $ null xs then head xs else ""

handleCmd _ _ _ ["PING"] = -- core requsted
	(noChangeClients, noChangeRooms, answerPing)

handleCmd _ _ _ ["ASKME"] = -- core requsted
	(noChangeClients, noChangeRooms, answerConnected)

handleCmd _ _ _ ["PONG"] =
	(noChangeClients, noChangeRooms, [])

handleCmd _ _ _ ["ERROR", msg] =
	(noChangeClients, noChangeRooms, answerErrorMsg msg)

handleCmd _ clients _ ["INFO", asknick] =
	if noSuchClient then
		(noChangeClients, noChangeRooms, [])
	else
		(noChangeClients, noChangeRooms, answerInfo client)
	where
		maybeClient = find (\cl -> asknick == nick cl) clients
		noSuchClient = isNothing maybeClient
		client = fromJust maybeClient


-- check state and call state-dependent commmand handlers
handleCmd client clients rooms cmd =
	if null (nick client) || protocol client == 0 then
		handleCmd_noInfo client clients rooms cmd
	else if null (room client) then
		handleCmd_noRoom client clients rooms cmd
	else
		handleCmd_inRoom client clients rooms cmd


-- 'no info' state - need to get protocol number and nickname
onLoginFinished client clients =
	if (null $ nick client) || (protocol client == 0) then
		[]
	else
		(answerClientOnly $ ["LOBBY:JOINED"] ++ (map nick $ clients)) ++
		(answerOthersRoom ["LOBBY:JOINED", nick client]) ++
		(answerServerMessage client clients)

handleCmd_noInfo :: CmdHandler
handleCmd_noInfo client clients _ ["NICK", newNick] =
	if not . null $ nick client then
		(noChangeClients, noChangeRooms, answerNickChosen)
	else if haveSameNick then
		(noChangeClients, noChangeRooms, answerNickChooseAnother)
	else
		(modifyClient client{nick = newNick}, noChangeRooms, answerNick newNick ++ (onLoginFinished client{nick = newNick} clients))
	where
		haveSameNick = isJust $ find (\cl -> newNick == nick cl) clients

handleCmd_noInfo client clients _ ["PROTO", protoNum] =
	if protocol client > 0 then
		(noChangeClients, noChangeRooms, answerProtocolKnown)
	else if parsedProto == 0 then
		(noChangeClients, noChangeRooms, answerBadInput)
	else
		(modifyClient client{protocol = parsedProto}, noChangeRooms, answerProto parsedProto ++ (onLoginFinished client{protocol = parsedProto} clients))
	where
		parsedProto = fromMaybe 0 (maybeRead protoNum :: Maybe Word16)

handleCmd_noInfo _ _ _ _ = (noChangeClients, noChangeRooms, answerBadCmd)


-- 'noRoom' clients state command handlers
handleCmd_noRoom :: CmdHandler
handleCmd_noRoom client clients rooms ["LIST"] =
		(noChangeClients, noChangeRooms, (answerRoomsList $ concatMap roomInfo $ sameProtoRooms))
		where
			roomInfo room = [
					name room,
					(show $ playersIn room) ++ "(" ++ (show $ length $ teams room) ++ ")",
					show $ gameinprogress room
					]
			sameProtoRooms = filter (\r -> (roomProto r == protocol client) && (not $ isRestrictedJoins r)) rooms

handleCmd_noRoom client _ rooms ["CREATE", newRoom, roomPassword] =
	if haveSameRoom then
		(noChangeClients, noChangeRooms, answerRoomExists)
	else
		(modifyClient client{room = newRoom, isMaster = True}, addRoom createRoom{name = newRoom, password = roomPassword, roomProto = (protocol client)}, (answerJoined $ nick client) ++ (answerNotReady $ nick client) ++ (answerRoomAdded newRoom))
	where
		haveSameRoom = isJust $ find (\room -> newRoom == name room) rooms

handleCmd_noRoom client clients rooms ["CREATE", newRoom] =
	handleCmd_noRoom client clients rooms ["CREATE", newRoom, ""]
	
handleCmd_noRoom client clients rooms ["JOIN", roomName, roomPassword] =
	if noSuchRoom then
		(noChangeClients, noChangeRooms, answerNoRoom)
	else if roomPassword /= password clRoom then
		(noChangeClients, noChangeRooms, answerWrongPassword)
	else if isRestrictedJoins clRoom then
		(noChangeClients, noChangeRooms, answerRestricted)
	else
		(modifyClient client{room = roomName}, modifyRoom clRoom{playersIn = 1 + playersIn clRoom}, answerNicks ++ answerReady ++ (answerJoined $ nick client) ++ (answerNotReady $ nick client) ++ answerFullConfig clRoom ++ answerAllTeams clRoom ++ watchRound)
	where
		noSuchRoom = isNothing $ find (\room -> roomName == name room && roomProto room == protocol client) rooms
		answerNicks = answerClientOnly $ ["JOINED"] ++ (map nick $ sameRoomClients)
		answerReady = concatMap (\c -> answerClientOnly [if isReady c then "READY" else "NOT_READY", nick c]) sameRoomClients
		sameRoomClients = filter (\ci -> room ci == roomName) clients
		clRoom = roomByName roomName rooms
		watchRound = if (roomProto clRoom < 20) || (not $ gameinprogress clRoom) then
					[]
				else
					(answerClientOnly  ["RUN_GAME"]) ++
					answerClientOnly ("GAMEMSG" : "DGUkc3BlY3RhdGUgMQ==" : roundMsgs clRoom)

handleCmd_noRoom client clients rooms ["JOIN", roomName] =
	handleCmd_noRoom client clients rooms ["JOIN", roomName, ""]

handleCmd_noRoom client _ _ ["CHAT_STRING", msg] =
	(noChangeClients, noChangeRooms, answerChatString (nick client) msg)

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

handleCmd_inRoom client _ rooms ["PART"] =
	if isMaster client then
		(modifyRoomClients clRoom (\cl -> cl{room = [], isReady = False}), removeRoom (room client), (answerAbandoned $ protocol client) ++ (answerRoomDeleted $ room client))
	else
		(modifyClient client{room = [], isReady = False}, modifyRoom clRoom{teams = othersTeams, playersIn = (playersIn clRoom) - 1, readyPlayers = newReadyPlayers}, (answerPartInform (nick client)) ++ answerRemoveClientTeams)
	where
		clRoom = roomByName (room client) rooms
		answerRemoveClientTeams = concatMap (\tn -> answerOthersRoom ["REMOVE_TEAM", teamname tn]) clientTeams
		(clientTeams, othersTeams) = partition (\t -> teamowner t == nick client) $ teams clRoom
		newReadyPlayers = if isReady client then (readyPlayers clRoom) - 1 else readyPlayers clRoom

handleCmd_inRoom client _ rooms ["MAP", mapName] =
	if isMaster client then
		(noChangeClients, modifyRoom clRoom{gamemap = mapName}, answerMap mapName)
	else
		(noChangeClients, noChangeRooms, answerNotMaster)
	where
		clRoom = roomByName (room client) rooms

handleCmd_inRoom client _ rooms ("ADD_TEAM" : name : color : grave : fort : difStr : hhsInfo)
	| length hhsInfo == 16 =
	if length (teams clRoom) == 6 then
		(noChangeClients, noChangeRooms, answerCantAdd "too many teams")
	else if canAddNumber <= 0 then
		(noChangeClients, noChangeRooms, answerCantAdd "too many hedgehogs")
	else if isJust findTeam then
		(noChangeClients, noChangeRooms, answerCantAdd "already has a team with same name")
	else if gameinprogress clRoom then
		(noChangeClients, noChangeRooms, answerCantAdd "round in progress")
	else if isRestrictedTeams clRoom then
		(noChangeClients, noChangeRooms, answerCantAdd "restricted")
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
			(noChangeClients, noChangeRooms, [])
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
		if noSuchTeam then
			(noChangeClients, noChangeRooms, [])
		else
			(noChangeClients, modifyRoom $ modifyTeam clRoom team{teamcolor = newColor}, answerTeamColor teamName newColor)
	where
		noSuchTeam = isNothing findTeam
		team = fromJust findTeam
		findTeam = find (\t -> teamName == teamname t) $ teams clRoom
		clRoom = roomByName (room client) rooms

handleCmd_inRoom client _ rooms ["REMOVE_TEAM", teamName] =
	if noSuchTeam then
		(noChangeClients, noChangeRooms, [])
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

handleCmd_inRoom client _ rooms ["TOGGLE_READY"] =
	if isReady client then
		(modifyClient client{isReady = False}, modifyRoom clRoom{readyPlayers = newReadyPlayers}, answerNotReady $ nick client)
	else
		(modifyClient client{isReady = True}, modifyRoom clRoom{readyPlayers = newReadyPlayers}, answerIsReady $ nick client)
	where
		clRoom = roomByName (room client) rooms
		newReadyPlayers = (readyPlayers clRoom) + if isReady client then -1 else 1

handleCmd_inRoom client _ rooms ["START_GAME"] =
	if isMaster client && (playersIn clRoom == readyPlayers clRoom) && (not $ gameinprogress clRoom) then
		if enoughClans then
			(noChangeClients, modifyRoom clRoom{gameinprogress = True}, answerRunGame)
		else
			(noChangeClients, noChangeRooms, answerTooFewClans)
	else
		(noChangeClients, noChangeRooms, [])
	where
		clRoom = roomByName (room client) rooms
		enoughClans = not $ null $ drop 1 $ group $ map teamcolor $ teams clRoom

handleCmd_inRoom client _ rooms ["TOGGLE_RESTRICT_JOINS"] =
	if isMaster client then
		(noChangeClients, modifyRoom clRoom{isRestrictedJoins = newStatus}, [])
	else
		(noChangeClients, noChangeRooms, answerNotMaster)
	where
		clRoom = roomByName (room client) rooms
		newStatus = not $ isRestrictedJoins clRoom

handleCmd_inRoom client _ rooms ["TOGGLE_RESTRICT_TEAMS"] =
	if isMaster client then
		(noChangeClients, modifyRoom clRoom{isRestrictedTeams = newStatus}, [])
	else
		(noChangeClients, noChangeRooms, answerNotMaster)
	where
		clRoom = roomByName (room client) rooms
		newStatus = not $ isRestrictedTeams clRoom

handleCmd_inRoom client clients rooms ["ROUNDFINISHED"] =
	if isMaster client then
		(modifyRoomClients clRoom (\cl -> cl{isReady = False}), modifyRoom clRoom{gameinprogress = False, readyPlayers = 0, roundMsgs =[]}, answerAllNotReady)
	else
		(noChangeClients, noChangeRooms, [])
	where
		clRoom = roomByName (room client) rooms
		sameRoomClients = filter (\ci -> room ci == name clRoom) clients
		answerAllNotReady = concatMap (\cl -> answerSameRoom ["NOT_READY", nick cl]) sameRoomClients

handleCmd_inRoom client _ rooms ["GAMEMSG", msg] =
	(noChangeClients, addMsg, answerOthersRoom ["GAMEMSG", msg])
	where
		addMsg = if roomProto clRoom < 20 then
					noChangeRooms
				else
					modifyRoom clRoom{roundMsgs = roundMsgs clRoom ++ [msg]}
		clRoom = roomByName (room client) rooms

handleCmd_inRoom client clients rooms ["KICK", kickNick] =
	if isMaster client then
		if noSuchClient || (kickClient == client) then
			(noChangeClients, noChangeRooms, [])
		else
			(modifyClient kickClient{forceQuit = True}, noChangeRooms, [])
	else
		(noChangeClients, noChangeRooms, [])
	where
		clRoom = roomByName (room client) rooms
		noSuchClient = isNothing findClient
		kickClient = fromJust findClient
		findClient = find (\t -> ((room t) == (room client)) && ((nick t) == kickNick)) $ clients

handleCmd_inRoom _ _ _ _ = (noChangeClients, noChangeRooms, answerBadCmd)
