module HWProto where

import IO
import Data.List
import Data.Word
import Miscutils
import Maybe (fromMaybe, fromJust)

answerBadCmd = [(clientOnly, ["ERROR", "Bad command, state or incorrect parameter"])]
answerQuit = [(clientOnly, ["QUIT"])]
answerAbandoned = [(sameRoom, ["ROOMABANDONED"])]
answerQuitInform nick = [(sameRoom, ["QUIT", nick])]
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

-- Main state-independent cmd handler
handleCmd :: CmdHandler
handleCmd client _ rooms ("QUIT":xs) =
	if null (room client) then
		(noChangeClients, noChangeRooms, answerQuit)
	else if isMaster client then
		(noChangeClients, removeRoom (room client), (answerQuitInform $ nick client) ++ answerAbandoned) -- core disconnects clients on ROOMABANDONED answer
	else
		(noChangeClients, noChangeRooms, answerQuitInform $ nick client)

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
		haveSameNick = not . null $ filter (\cl -> newNick == nick cl) clients

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
		(modifyClient client{room = newRoom, isMaster = True}, addRoom (RoomInfo newRoom roomPassword []), answerJoined $ nick client)
	where
		haveSameRoom = not . null $ filter (\room -> newRoom == name room) rooms

handleCmd_noRoom client clients rooms ["CREATE", newRoom] =
	handleCmd_noRoom client clients rooms ["CREATE", newRoom, ""]
	
handleCmd_noRoom client _ rooms ["JOIN", roomName, roomPassword] =
	if noSuchRoom then
		(noChangeClients, noChangeRooms, answerNoRoom)
	else if roomPassword /= password (roomByName roomName rooms) then
		(noChangeClients, noChangeRooms, answerWrongPassword)
	else
		(modifyClient client{room = roomName}, noChangeRooms, answerJoined $ nick client)
	where
		noSuchRoom = null $ filter (\room -> roomName == name room) rooms

handleCmd_noRoom client clients rooms ["JOIN", roomName] =
	handleCmd_noRoom client clients rooms ["JOIN", roomName, ""]

handleCmd_noRoom _ _ _ _ = (noChangeClients, noChangeRooms, answerBadCmd)

-- 'inRoom' clients state command handlers
handleCmd_inRoom :: CmdHandler

handleCmd_inRoom client _ _ ["CHAT_STRING", _, msg] = (noChangeClients, noChangeRooms, answerChatString (nick client) msg)

handleCmd_inRoom _ _ _ _ = (noChangeClients, noChangeRooms, answerBadCmd)
