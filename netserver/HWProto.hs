module HWProto where

import IO
import Data.List
import Data.Word
import Miscutils
import Maybe
import qualified Data.Map as Map

answerBadCmd = [(clientOnly, ["ERROR", "Bad command, state or incorrect parameter"])]
answerNotMaster = [(clientOnly, ["ERROR", "You cannot configure room parameters"])]
answerQuit = [(clientOnly, ["off"])]
answerAbandoned = [(sameRoom, ["BYE"])]
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
answerFullConfig room = map toAnswer (Map.toList $ params room)
	where
		toAnswer (paramName, paramStrs) =
			(clientOnly, "CONFIG_PARAM" : paramName : paramStrs)
answerCantAdd = [(clientOnly, ["WARNING", "Too many teams"])]

-- Main state-independent cmd handler
handleCmd :: CmdHandler
handleCmd client _ rooms ("QUIT":xs) =
	if null (room client) then
		(noChangeClients, noChangeRooms, answerQuit)
	else if isMaster client then
		(noChangeClients, removeRoom (room client), answerAbandoned) -- core disconnects clients on ROOMABANDONED answer
	else
		(noChangeClients, noChangeRooms, answerQuit ++ (answerQuitInform $ nick client))


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
		(modifyClient client{room = newRoom, isMaster = True}, addRoom (RoomInfo newRoom roomPassword (protocol client) [] Map.empty), answerJoined $ nick client)
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
		(modifyClient client{room = roomName}, noChangeRooms, (answerJoined $ nick client) ++ answerNicks ++ answerFullConfig clRoom)
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

handleCmd_inRoom client _ rooms ("CONFIG_PARAM":paramName:paramStrs) =
	if isMaster client then
		(noChangeClients, modifyRoom clRoom{params = Map.insert paramName paramStrs (params clRoom)}, answerConfigParam paramName paramStrs)
	else
		(noChangeClients, noChangeRooms, answerNotMaster)
	where
		clRoom = roomByName (room client) rooms

handleCmd_inRoom client _ rooms ("ADDTEAM" : name : color : grave : fort : difStr : hhsInfo)
	| length hhsInfo == 16 =
	if length (teams clRoom) == 6 then
		(noChangeClients, noChangeRooms, answerCantAdd)
	else
		(noChangeClients, modifyRoom clRoom{teams = newTeam : teams clRoom}, [])
	where
		clRoom = roomByName (room client) rooms
		newTeam = (TeamInfo name color grave fort difficulty (hhsList hhsInfo))
		difficulty = fromMaybe 0 (maybeRead difStr :: Maybe Int)
		hhsList (n:h:hhs) = HedgehogInfo n h : hhsList hhs


handleCmd_inRoom _ _ _ _ = (noChangeClients, noChangeRooms, answerBadCmd)
