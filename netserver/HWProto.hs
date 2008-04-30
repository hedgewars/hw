module HWProto where

import IO
import Miscutils

handleCmd :: ClientInfo -> [ClientInfo] -> [RoomInfo] -> [String] -> (ClientInfo, [RoomInfo], [ClientInfo], [String])


handleCmd client clients rooms ("QUIT":xs) =
	if null (room client) then
		(client, rooms, [client], ["QUIT"])
	else
		(client, rooms, clients, ["QUIT", nick client])


handleCmd client clients rooms ("NICK":newNick:[]) =
	if not . null $ nick client then
		(client, rooms, [client], ["ERROR", "The nick already chosen"])
	else if haveSameNick then
		(client, rooms, [client], ["ERROR", "Choose another nick"])
	else
		(client{nick = newNick}, rooms, [client], ["NICK", newNick])
	where
		haveSameNick = not . null $ filter (\cl -> newNick == nick cl) clients


handleCmd client _ rooms _ = (client, rooms, [client], ["ERROR", "Bad command"])
