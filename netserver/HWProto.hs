module HWProto where

import IO
import Data.Word
import Miscutils
import Maybe (fromMaybe)

handleCmd :: ClientInfo -> [ClientInfo] -> [RoomInfo] -> [String] -> (ClientInfo, [RoomInfo], [ClientInfo], [String])
handleCmd_noInfo :: ClientInfo -> [ClientInfo] -> [RoomInfo] -> [String] -> (ClientInfo, [RoomInfo], [ClientInfo], [String])
handleCmd_noRoom :: ClientInfo -> [ClientInfo] -> [RoomInfo] -> [String] -> (ClientInfo, [RoomInfo], [ClientInfo], [String])

-- 'noInfo' clients state command handlers
handleCmd_noInfo client clients rooms ("NICK":newNick:[]) =
	if not . null $ nick client then
		(client, rooms, [client], ["ERROR", "The nick already chosen"])
	else if haveSameNick then
		(client, rooms, [client], ["WARNING", "Choose another nick"])
	else
		(client{nick = newNick}, rooms, [client], ["NICK", newNick])
	where
		haveSameNick = not . null $ filter (\cl -> newNick == nick cl) clients

handleCmd_noInfo client clients rooms ("PROTO":protoNum:[]) =
	if protocol client > 0 then
		(client, rooms, [client], ["ERROR", "Protocol number already known"])
	else if parsedProto == 0 then
		(client, rooms, [client], ["ERROR", "Bad input"])
	else
		(client{protocol = parsedProto}, rooms, [], [])
	where
		parsedProto = fromMaybe 0 (maybeRead protoNum :: Maybe Word16)


handleCmd_noInfo client _ rooms _ = (client, rooms, [client], ["ERROR", "Bad command or incorrect parameter"])


-- 'noRoom' clients state command handlers
--handleCmd_noRoom client clients rooms ("CREATE":newRoom:[]) =

handleCmd_noRoom client _ rooms _ = (client, rooms, [client], ["ERROR", "Bad command or incorrect parameter"])
	

handleCmd client clients rooms ("QUIT":xs) =
	if null (room client) then
		(client, rooms, [client], ["QUIT"])
	else
		(client, rooms, clients, ["QUIT", nick client])


handleCmd client clients rooms cmd =
	if null (nick client) || protocol client == 0 then
		handleCmd_noInfo client clients rooms cmd
	else
		handleCmd_noRoom client clients rooms cmd
