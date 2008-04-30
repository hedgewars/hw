module HWProto where

import IO
import Miscutils

handleCmd :: ClientInfo -> [ClientInfo] -> [RoomInfo] -> [String] -> (Bool, [ClientInfo], [String])

handleCmd client clients _ ("QUIT":xs) =
	if null (room client) then
		(True, [client], ["QUIT"])
	else
		(True, clients, ["QUIT " ++ nick client])

handleCmd client _ _ _ = (False, [client], ["Bad command"])
