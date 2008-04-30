module HWProto where

import IO
import Miscutils

handleCmd :: ClientInfo -> [ClientInfo] -> [RoomInfo] -> [String] -> ([ClientInfo], [String])

handleCmd client clients _ ("QUIT":xs) =
	if null (room client) then
		([client], ["QUIT"])
	else
		(clients, ["QUIT", nick client])

handleCmd client _ _ _ = ([client], ["Bad command"])
