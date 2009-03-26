module Utils where

import Control.Concurrent
import Control.Concurrent.STM
import Data.Char
import Data.Word
import qualified Data.Map as Map
import qualified Data.IntMap as IntMap
import Numeric
import Network.Socket
import qualified Data.List as List
-------------------------------------------------
import qualified Codec.Binary.Base64 as Base64
import qualified Codec.Binary.UTF8.String as UTF8
import CoreTypes


sockAddr2String :: SockAddr -> IO String
sockAddr2String (SockAddrInet _ hostAddr) = inet_ntoa hostAddr
sockAddr2String (SockAddrInet6 _ _ (a, b, c, d) _) =
	return $ (foldr1 (.)
		$ List.intersperse (\a -> ':':a)
		$ concatMap (\n -> (\(a, b) -> [showHex a, showHex b]) $ divMod n 65536) [a, b, c, d]) []

toEngineMsg :: String -> String
toEngineMsg msg = Base64.encode (fromIntegral (length msg) : (UTF8.encode msg))

--tselect :: [ClientInfo] -> STM ([String], ClientInfo)
--tselect = foldl orElse retry . map (\ci -> (flip (,) ci) `fmap` readTChan (chan ci))

maybeRead :: Read a => String -> Maybe a
maybeRead s = case reads s of
	[(x, rest)] | all isSpace rest -> Just x
	_         -> Nothing

teamToNet team = [
		"ADD_TEAM",
		teamname team,
		teamgrave team,
		teamfort team,
		teamvoicepack team,
		teamowner team,
		show $ difficulty team
		]
		++ hhsInfo
	where
		hhsInfo = concatMap (\(HedgehogInfo name hat) -> [name, hat]) $ hedgehogs team

modifyTeam :: TeamInfo -> RoomInfo -> RoomInfo
modifyTeam team room = room{teams = replaceTeam team $ teams room}
	where
	replaceTeam _ [] = error "modifyTeam: no such team"
	replaceTeam team (t:teams) =
		if teamname team == teamname t then
			team : teams
		else
			t : replaceTeam team teams

protoNumber2ver :: Word16 -> String
protoNumber2ver 17 = "0.9.7-dev"
protoNumber2ver 19 = "0.9.7"
protoNumber2ver 20 = "0.9.8-dev"
protoNumber2ver 21 = "0.9.8"
protoNumber2ver 22 = "0.9.9-dev"
protoNumber2ver 23 = "0.9.9"
protoNumber2ver 24 = "0.9.10-dev"
protoNumber2ver 25 = "0.9.10"
protoNumber2ver _ = "Unknown"

