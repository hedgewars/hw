module HWProto where

import IO
import Miscutils

handleCmd :: ClientInfo -> [ClientInfo] -> [RoomInfo] -> String -> (Bool, Bool, [String])
handleCmd _ _ _ ('Q':'U':'I':'T':xs) = (True, False, [])
