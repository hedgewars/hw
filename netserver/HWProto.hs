module HWProto where

import IO
import Data.List
import Data.Word
import Miscutils
import Maybe (fromMaybe, fromJust)

-- 'noInfo' clients state command handlers
handleCmd_noInfo :: Handle -> [ClientInfo] -> [RoomInfo] -> [String] -> ([ClientInfo], [RoomInfo], [Handle], [String])

handleCmd_noInfo clhandle clients rooms ("NICK":newNick:[]) =
	if not . null $ nick client then
		(clients, rooms, [clhandle], ["ERROR", "The nick already chosen"])
	else if haveSameNick then
		(clients, rooms, [clhandle], ["WARNING", "Choose another nick"])
	else
		(modifyClient clhandle clients (\cl -> cl{nick = newNick}), rooms, [clhandle], ["NICK", newNick])
	where
		haveSameNick = not . null $ filter (\cl -> newNick == nick cl) clients
		client = clientByHandle clhandle clients

handleCmd_noInfo clhandle clients rooms ("PROTO":protoNum:[]) =
	if protocol client > 0 then
		(clients, rooms, [clhandle], ["ERROR", "Protocol number already known"])
	else if parsedProto == 0 then
		(clients, rooms, [clhandle], ["ERROR", "Bad input"])
	else
		(modifyClient clhandle clients (\cl -> cl{protocol = parsedProto}), rooms, [], [])
	where
		parsedProto = fromMaybe 0 (maybeRead protoNum :: Maybe Word16)
		client = clientByHandle clhandle clients

handleCmd_noInfo clhandle clients rooms _ = (clients, rooms, [clhandle], ["ERROR", "Bad command or incorrect parameter"])


-- 'noRoom' clients state command handlers
handleCmd_noRoom :: Handle -> [ClientInfo] -> [RoomInfo] -> [String] -> ([ClientInfo], [RoomInfo], [Handle], [String])

handleCmd_noRoom clhandle clients rooms ("CREATE":newRoom:roomPassword:[]) =
	if haveSameRoom then
		(clients, rooms, [clhandle], ["WARNING", "There's already a room with that name"])
	else
		(modifyClient clhandle clients (\cl -> cl{room = newRoom, isMaster = True}), (RoomInfo newRoom roomPassword):rooms, [clhandle], ["JOINS", nick client])
	where
		haveSameRoom = not . null $ filter (\room -> newRoom == name room) rooms
		client = clientByHandle clhandle clients

handleCmd_noRoom clhandle clients rooms ("CREATE":newRoom:[]) =
	handleCmd_noRoom clhandle clients rooms ["CREATE", newRoom, ""]

handleCmd_noRoom clhandle clients rooms ("JOIN":roomName:roomPassword:[]) =
	if noSuchRoom then
		(clients, rooms, [clhandle], ["WARNING", "There's no room with that name"])
	else if roomPassword /= password (roomByName roomName rooms) then
		(clients, rooms, [clhandle], ["WARNING", "Wrong password"])
	else
		(modifyClient clhandle clients (\cl -> cl{room = roomName}), rooms, clhandle : (fromRoomHandles roomName clients), ["JOINS", nick client])
	where
		noSuchRoom = null $ filter (\room -> roomName == name room) rooms
		client = clientByHandle clhandle clients

handleCmd_noRoom clhandle clients rooms ("JOIN":roomName:[]) =
	handleCmd_noRoom clhandle clients rooms ["JOIN", roomName, ""]

handleCmd_noRoom clhandle clients rooms _ = (clients, rooms, [clhandle], ["ERROR", "Bad command or incorrect parameter"])

-- 'inRoom' clients state command handlers
handleCmd_inRoom :: Handle -> [ClientInfo] -> [RoomInfo] -> [String] -> ([ClientInfo], [RoomInfo], [Handle], [String])

handleCmd_inRoom clhandle clients rooms _ = (clients, rooms, [clhandle], ["ERROR", "Bad command or incorrect parameter"])

-- state-independent command handlers
handleCmd :: Handle -> [ClientInfo] -> [RoomInfo] -> [String] -> ([ClientInfo], [RoomInfo], [Handle], [String])

handleCmd clhandle clients rooms ("QUIT":xs) =
	if null (room client) then
		(clients, rooms, [clhandle], ["QUIT"])
	else if isMaster client then
		(clients, filter (\rm -> room client /= name rm) rooms, roomMates, ["ROOMABANDONED"]) -- core disconnects clients on ROOMABANDONED command
	else
		(clients, rooms, roomMates, ["QUIT", nick client])
	where
		client = clientByHandle clhandle clients
		roomMates = fromRoomHandles (room client) clients

-- check state and call state-dependent commmand handlers
handleCmd clhandle clients rooms cmd =
	if null (nick client) || protocol client == 0 then
		handleCmd_noInfo clhandle clients rooms cmd
	else if null (room client) then
		handleCmd_noRoom clhandle clients rooms cmd
	else
		handleCmd_inRoom clhandle clients rooms cmd
	where
		client = clientByHandle clhandle clients
