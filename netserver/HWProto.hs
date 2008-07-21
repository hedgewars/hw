module HWProto where

import IO
import Data.List
import Data.Word
import Miscutils
import Maybe (fromMaybe, fromJust)

-- Main state-independent cmd handler
handleCmd :: CmdHandler
handleCmd client _ rooms ("QUIT":xs) =
	if null (room client) then
		(noChangeClients, noChangeRooms, clientOnly, ["QUIT"])
	else if isMaster client then
		(noChangeClients, removeRoom (room client), sameRoom, ["ROOMABANDONED"]) -- core disconnects clients on ROOMABANDONED command
	else
		(noChangeClients, noChangeRooms, sameRoom, ["QUIT", nick client])

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
		(noChangeClients, noChangeRooms, clientOnly, ["ERROR", "The nick already chosen"])
	else if haveSameNick then
		(noChangeClients, noChangeRooms, clientOnly, ["WARNING", "Choose another nick"])
	else
		(modifyClient client{nick = newNick}, noChangeRooms, clientOnly, ["NICK", newNick])
	where
		haveSameNick = not . null $ filter (\cl -> newNick == nick cl) clients

handleCmd_noInfo client _ _ ["PROTO", protoNum] =
	if protocol client > 0 then
		(noChangeClients, noChangeRooms, clientOnly, ["ERROR", "Protocol number already known"])
	else if parsedProto == 0 then
		(noChangeClients, noChangeRooms, clientOnly, ["ERROR", "Bad input"])
	else
		(modifyClient client{protocol = parsedProto}, noChangeRooms, clientOnly, ["PROTO", show parsedProto])
	where
		parsedProto = fromMaybe 0 (maybeRead protoNum :: Maybe Word16)

handleCmd_noInfo _ _ _ _ = (noChangeClients, noChangeRooms, clientOnly, badCmd)

-- 'noRoom' clients state command handlers
handleCmd_noRoom :: CmdHandler
handleCmd_noRoom client _ rooms ["LIST"] =
		(noChangeClients, noChangeRooms, clientOnly, ["ROOMS"] ++ map name rooms)

handleCmd_noRoom client _ rooms ["CREATE", newRoom, roomPassword] =
	if haveSameRoom then
		(noChangeClients, noChangeRooms, clientOnly, ["WARNING", "There's already a room with that name"])
	else
		(modifyClient client{room = newRoom, isMaster = True}, addRoom (RoomInfo newRoom roomPassword []), clientOnly, ["JOINED", nick client])
	where
		haveSameRoom = not . null $ filter (\room -> newRoom == name room) rooms

handleCmd_noRoom client clients rooms ["CREATE", newRoom] =
	handleCmd_noRoom client clients rooms ["CREATE", newRoom, ""]
	
handleCmd_noRoom client _ rooms ["JOIN", roomName, roomPassword] =
	if noSuchRoom then
		(noChangeClients, noChangeRooms, clientOnly, ["WARNING", "There's no room with that name"])
	else if roomPassword /= password (roomByName roomName rooms) then
		(noChangeClients, noChangeRooms, clientOnly, ["WARNING", "Wrong password"])
	else
		(modifyClient client{room = roomName}, noChangeRooms, fromRoom roomName, ["JOINED", nick client])
	where
		noSuchRoom = null $ filter (\room -> roomName == name room) rooms

handleCmd_noRoom client clients rooms ["JOIN", roomName] =
	handleCmd_noRoom client clients rooms ["JOIN", roomName, ""]

handleCmd_noRoom _ _ _ _ = (noChangeClients, noChangeRooms, clientOnly, badCmd)

-- 'inRoom' clients state command handlers
handleCmd_inRoom :: CmdHandler

handleCmd_inRoom client _ _ ["CHAT_STRING", _, msg] = (noChangeClients, noChangeRooms, othersInRoom, ["CHAT_STRING", nick client, msg])

handleCmd_inRoom client clients rooms ["CONFIG_PARAM", paramName, value] =
	(noChangeClients, noChangeRooms, othersInRoom, ["CONFIG_PARAM", paramName, value])

handleCmd_inRoom client clients rooms ["CONFIG_PARAM", paramName, value1, value2] =
	(noChangeClients, noChangeRooms, othersInRoom, ["CONFIG_PARAM", paramName, value1, value2])

handleCmd_inRoom client clients rooms ["ADDTEAM:", teamName, teamColor, graveName, fortName, teamLevel, hh0, hh1, hh2, hh3, hh4, hh5, hh6, hh7] =
	(noChangeClients, noChangeRooms, othersInRoom, ["TEAM_ACCEPTED", "1", teamName])

handleCmd_inRoom _ _ _ _ = (noChangeClients, noChangeRooms, clientOnly, badCmd)
